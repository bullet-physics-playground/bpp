-- demo/basic/27-libremidi-debug.lua
--
-- Debug script for libremidi MIDI input.
-- Prints every incoming MIDI message with decoded meaning and a running count.
--
-- Usage: bpp -f demo/basic/27-libremidi-debug.lua
-- (Requires USE_LIBREMIDI=1 and a MIDI input device enabled in the &MIDI menu)

local midi = { counts = {}, total = 0 }

local function cmdName(status)
   local cmd = math.floor(status / 16)
   local chan = (status % 16) + 1
   local names = {
      [8]  = "Note Off",   [9]  = "Note On",
      [10] = "Poly Aftertouch", [11] = "Control Change",
      [12] = "Program Change", [13] = "Channel Aftertouch",
      [14] = "Pitch Bend",
   }
   if cmd >= 8 and cmd <= 14 then
      return string.format("%s (ch %d)", names[cmd] or "?", chan)
   end
   if status == 0xF0 then return "System Exclusive start" end
   if status == 0xF7 then return "System Exclusive end" end
   if status >= 0xF0 then return string.format("System 0x%02X", status) end
   return string.format("Unknown 0x%02X", status)
end

local function byte_at(data, i)
   if type(data) == "string" then return string.byte(data, i) or 0 end
   if type(data) == "table" then return data[i] or 0 end
   return 0
end

local function data_len(data)
   if type(data) == "string" then return #data end
   if type(data) == "table" then return #data end
   return 0
end

local function hexDump(data)
   local out = ""
   for i = 1, data_len(data) do
      out = out .. string.format("%02X ", byte_at(data, i))
   end
   return out
end

v:onMIDIReceived(function(frame, data)
   midi.total = midi.total + 1
   local first = byte_at(data, 1)
   local name = cmdName(first)
   midi.counts[name] = (midi.counts[name] or 0) + 1
   print(string.format("[frame %d] MIDI %s  bytes: %s",
                       frame, name, hexDump(data)))
   if midi.total % 50 == 0 then
      print(string.format("--- MIDI summary (%d total) ---", midi.total))
      for n, c in pairs(midi.counts) do
         print(string.format("   %-28s %d", n, c))
      end
      print("----------------------------------------")
   end
end)

print("libremidi debug script loaded. Enable a device in the &MIDI menu.")
