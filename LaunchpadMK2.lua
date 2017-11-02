
--[[----------------------------------------------------------------------------
-- Duplex.LaunchpadMK2
----------------------------------------------------------------------------]]--

--[[

Inheritance: LaunchpadMK2 > MidiDevice > Device

A device-specific class 

--]]


--==============================================================================

class "LaunchpadMK2" (MidiDevice)

function LaunchpadMK2:__init(display_name, message_stream, port_in, port_out)
  TRACE("LaunchpadMK2:__init", display_name, message_stream, port_in, port_out)

  self.colorspace = {64,64,64}
  MidiDevice.__init(self, display_name, message_stream, port_in, port_out) 
  
end
 
--------------------------------------------------------------------------------

-- clear display before releasing device:
-- all LEDs are turned off, and the mapping mode, buffer settings, 
-- and duty cycle are reset to defaults

function LaunchpadMK2:release()
  TRACE("LaunchpadMK2:release()")
  
  --clears the display
  self:send_sysex_message(0x00, 0x20, 0x29, 0x02, 0x18, 0x0E, 0x00)
 
  self:send_cc_message(0,0) 
  MidiDevice.release(self)

end


--------------------------------------------------------------------------------

--- override default Device method
-- @see Device.output_value
function LaunchpadMK2:output_boolean(pt,xarg,ui_obj)
  TRACE("LaunchpadMK2:output_boolean(pt,xarg,ui_obj)",pt,xarg,ui_obj)
    
  local skip_hardware = true
  local sysex_num = nil
      
  sysex_num = self:extract_midi_note(xarg.value)
  if (sysex_num == nil) then
    sysex_num = self:extract_midi_cc(xarg.value)
  end
  
  local rslt = 0   
  local sysex_color = {}
  
  if pt.val and xarg.group_name == "LargeGrid" then
    -- add rainbow colors to the keyboard grid
    local note_value = tonumber(pt.text) % 12
                           
    for i = 1, 3 do          
      local note_rad = 2 * math.pi * note_value / 12 
      local color_scale = 0.5 + (math.cos(note_rad * 5) + math.cos(note_rad * 7))/4
      ui_obj.palette.foreground.color[i] = math.floor(255 * color_scale)
      sysex_color[i] = math.floor(63 * color_scale) 
      rslt = rslt * 64 + sysex_color[i]
      note_value = (note_value + 3) % 12 + 1 
    end
  else
    --return the expected color everywhere else
    for i = 1, 3 do
        sysex_color[i] = math.floor(pt.color[i]/8)
        rslt = rslt * 64 + sysex_color[i]
    end
  end
      
  self:send_sysex_message(0x00, 0x20, 0x29, 0x02, 0x18, 0x0B, sysex_num, sysex_color[1], sysex_color[2], sysex_color[3])
  
  return rslt, skip_hardware
end

--------------------------------------------------------------------------------

--- output a string to the grid
-- @param pt (@{Duplex.CanvasPoint})
-- @param xarg (table), control-map parameter
-- @param ui_obj (@{Duplex.UIComponent})
-- @see Device.output_value
-- overrides Device:output_text()

function LaunchpadMK2:output_text(pt,xarg,ui_obj)
  TRACE("LaunchpadMK2:output_text(pt,xarg,ui_obj)",pt,xarg,ui_obj)

  self:send_sysex_message(0, 32, 41, 2, 24, 20, 57, 0, string.byte(pt.val, 1, -1))  

  return pt.val, true

end

--------------------------------------------------------------------------------
-- A couple of sample configurations
--------------------------------------------------------------------------------

-- setup "Mixer" as the only app for this configuration

--[[
duplex_configurations:insert {

  -- configuration properties
  name = "Mixer",
  pinned = false,

  -- device properties
  device = {
    class_name = "Launchpad",
    display_name = "Launchpad",
    device_port_in = "Launchpad",
    device_port_out = "Launchpad",
    control_map = "Controllers/Launchpad/Launchpad.xml",
    thumbnail = "Launchpad.bmp",
    protocol = DEVICE_PROTOCOL.MIDI,
  },

  applications = {
    Mixer = {
      mappings = {
        levels = {
          group_name = "Grid",
        },
        mute = {
          group_name = "Controls",
        },
        master = {
          group_name = "Triggers",
        }
      },
      options = {
        invert_mute = 1
      }
    }
  }
}
]]

--------------------------------------------------------------------------------

-- Here's how to make a second Launchpad show up as a separate device 
-- Notice that the "display name" is different

--[[
duplex_configurations:insert {

  -- configuration properties
  name = "Matrix + Transport",
  pinned = true,
  
  -- device properties
  device = {
    class_name = "Launchpad",
    display_name = "Launchpad (2)",
    device_port_in = "Launchpad (2)",
    device_port_out = "Launchpad (2)",
    control_map = "Controllers/Launchpad/Launchpad.xml",
    thumbnail = "Launchpad.bmp",
    protocol = DEVICE_PROTOCOL.MIDI,
  },

  applications = {
    Matrix = {
      mappings = {
        matrix = {
          group_name = "Grid",
        },
        triggers = {
          group_name = "Triggers",
        },
        sequence = {
          group_name = "Controls",
          index = 1,
        },
        track = {
          group_name = "Controls",
          index = 3,
        }
      },
      options = {
        --switch_mode = 4,
      }
    },
    Transport = {
      mappings = {
        edit_mode = {
          group_name = "Controls",
          index = 5,
        },
        start_playback = {
          group_name = "Controls",
          index = 6,
        },
        loop_pattern = {
          group_name = "Controls",
          index = 7,
        },
        follow_player = {
          group_name= "Controls",
          index = 8,
        },
      },
      options = {
        pattern_play = 3,
      },
    },

  }
}

]]
