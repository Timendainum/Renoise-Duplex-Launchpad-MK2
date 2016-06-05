
--[[----------------------------------------------------------------------------
-- Duplex.LaunchpadMK2
----------------------------------------------------------------------------]]--

--[[

Inheritance: LaunchpadMK2 > MidiDevice > Device

A device-specific class 

--]]


--==============================================================================

class "LaunchpadMK2" (MidiDevice)

color_reference_12 = {
  {63,0,0}, --RED
  {63,31,0}, --ORANGE 
  {63,63,0}, --YELLOW 
  {31,63,0}, --CHARTREUSE 
  {0,63,0}, --GREEN 
  {0,63,31}, --SPRING 
  {0,63,63}, --CYAN 
  {0,31,63}, --AZURE 
  {0,0,63}, --BLUE 
  {31,0,63}, --VIOLET 
  {63,0,63}, --MAGENTA 
  {63,0,31}, --PURPLE 
}

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

  self:send_cc_message(0,0) 
  MidiDevice.release(self)

end

--------------------------------------------------------------------------------

--- override default Device method
-- @see Device.output_value
function LaunchpadMK2:output_value(pt,xarg,ui_obj)
  TRACE("LaunchpadMK2:output_value(pt,xarg,ui_obj)",pt,xarg,ui_obj)
  
  --if xarg.skip_echo then
    --- parameter only exist in the virtual ui
  --  return Device.output_value(self,pt,xarg,ui_obj)
  --else

    --print("launchpad output value...",rprint(pt.color))
    
    
    local skip_hardware = true
    local rainbow_mode = true --toggle for fun times :D
    --rprint(xarg) 
    
    local sysex_num = nil
    local sysex_color = {}
    sysex_num = self:extract_midi_note(xarg.value)
    if (sysex_num == nil) then
      sysex_num = self:extract_midi_cc(xarg.value)
    end
    
       
    local rslt = 0
          
    for i=1, 3 do
      if rainbow_mode and pt.val and (xarg.group_name == "LargeGrid") then
        
        
        local x = xarg.row or 0 
        local y = xarg.column or 0
        --print(x, y)
        local color_code = (-3 + x + y + ((y % 2) * 6)) % 12 + 1 --> magic number dance
        --print(color_code)
        sysex_color[i] = math.floor(color_reference_12[color_code][i])
        
      else
        sysex_color[i] = math.floor(pt.color[i]/8)
      end
      rslt = rslt * 64 + sysex_color[i]
    end    

    self:send_sysex_message(0x00, 0x20, 0x29, 0x02, 0x18, 0x0B, sysex_num, sysex_color[1], sysex_color[2], sysex_color[3])
  
    return rslt, skip_hardware

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
