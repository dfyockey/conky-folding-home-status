--[[
Folding@Home Queue Information data parser for conky
  - Functionally completed 20 October 2020

Usage:
- The Folding@Home project packages should be installed and FAHClient
  running, as the script gets information from a running FAHClient
  instance via telnet
- Add fahqi.lua to a load_lua line in your .conkyrc file
- Add a line such as the following to your conky configuration file:
    ${lua conky_load_fah_queue_info} Folding@Home Proj: ${lua conky_fah_project} ${lua_parse conky_fah_status}

Note:
  The alchemical symbol for "day" (Unicode UTF-16: 0x260C) is displayed
  when the time remaining in a work unit is a day or more. This symbol
  is not available in all font families; consequently, the script
  outputs display info to conky that changes the font to FreeSerif and
  then back to the default font. The user may wish to change the font,
  font size, and/or symbol to represent "day" to better blend the script
  output with with the particular conky design being used. This is set
  on the line following the comment '-- set symbol for "day"'.
  
Note — To Add Other Data Values:
  1) In a terminal, run `$ { echo "queue-info"; sleep 1; } | telnet localhost 36330`
  2) Examine the output to find the keys for values of interest
  3) Add the keys to the `keys = {...}` sequence
  4) Add a function for each value to be displayed
  5) Add a `${lua <function_name>}` object for each value to be displayed to
     the conky configuration file
  
# MIT License
#
# Copyright 2020 David Yockey
#
# Permission is hereby granted, free of charge, to any person obtaining
# a copy of this software and associated documentation files
# (the "Software"), to deal in the Software without restriction,
# including without limitation the rights to use, copy, modify, merge,
# publish, distribute, sublicense, and/or sell copies of the Software,
# and to permit persons to whom the Software is furnished to do so,
# subject to the following conditions:
#
# The above copyright notice and this permission notice shall be
# included in all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
# IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
# CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
# TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
# SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
--]]

--[[
  Based on code from https://stackoverflow.com/a/326715/8100489 and information
  at https://github.com/FoldingAtHome/fah-control/wiki/3rd-party-FAHClient-API.
--]]
keys = {"project", "percentdone", "state", "eta"}
info = {"0", "0.0", "Loading...", "00:00:00"}
iter = 1
function conky_load_fah_queue_info()
    if conky_window == nil then
        return
    end
    
    if iter == 5 then 

	cmd = '{ echo "queue-info"; sleep 1; } | telnet localhost 36330'

	local f = assert(io.popen(cmd, 'r'))
	local qi = assert(f:read('a'))
	f:close()

	for k = 1, 4 do 
		pattern = '"'..keys[k]..'": [^,]+,'
		keyvalue = string.match(qi, pattern)
		if keyvalue == nil then
			info[k] = "-- no keyvalue --"
		else
			-- Get data value from combined key and value
			-- (need ': ' to avoid picking up '"' at start of key)
			value = string.match(keyvalue, ': "[^"]+"')
						
			if k > 3 then
			    -- Time Info
			    
				-- Time info data are time values or labels

				-- strip off garbage
				value = string.gsub(value, ': ', '')
				value = string.gsub(value, '"', '')
				
				-- append a space to enable final end-of-datum detection
				value = value..' '
				
				-- TEST VALUES
				--value = '16 hours 17 mins '
				--value = '6 mins 17 secs '

				pass = 1
				tt = ''
				dd = '00'
				hh = '00'
				mm = '00'
				ss = '00'
				datum = ''			
				for v in string.gmatch(value, '.') do
					if v ~= ' ' then
						datum = datum..v
					elseif pass == 2 then
						if     datum == "days"  then dd = tt
						elseif datum == "hours" then hh = tt
						elseif datum == "mins"  then mm = tt
						elseif datum == "secs"  then ss = tt
						else   -- nop --
						end
						
						datum = ''
						pass = 1

					else
						-- % in string.match is an escape character, so '%.' is a literal dot
						-- % in each string.format begins a conversion specification, which ends with a converison character (f or d)
						--     (The format string follows the same rules as the ISO C function sprintf)
						if string.match(datum, '%.') then
							tt = string.format('%1.2f', datum)
						else
							tt = string.format('%02d', datum)
						end
						datum = ''
						pass = 2
					end				
				end
				
				value = ''
				if dd ~= "00" then
					-- set symbol for "day"
					value = dd .. "${font FreeSerif:size=11}${color}☌${color grey}${font}"
				else
					--if hh ~= "00" then value = value..hh end
					value = string.format( '%2.2fh', ( ( (hh*3600) + (mm*60) + ss ) / 3600) )
					--value = value..'h'
				
					-- if hh ~= "00" then value = value .. hh .. 'h:' end
					-- if dd == "00" then value = value .. mm .. 'm' end
					-- if hh == "00" and dd == "00" then value = value .. ':' .. ss .. 's' end
				end
			
			elseif k > 2 then
			    -- Text-Only Info
				value = string.match(value, '%a+')
			else
			    -- Numeric-Only Info
				value = string.match(keyvalue, '[%d%.]+')
			end
			
			if value ~= nil then
				info[k] = value
			else
				info[k] = "-- no value --"
			end
		end
	end

	iter = 1
    else
	iter = iter + 1
    end
end


function conky_fah_project()
    if conky_window == nil then
        return
    end

    return string.format("%d", info[1])
end

function conky_fah_status()
    if conky_window == nil then
        return
    end

    if info[3] == "RUNNING" then
	return percentdone()..' '..eta()
    else
        return string.format(" Status: %s", info[3])
    end
end

function percentdone()
    return string.format("%2.2f", info[2]).."%"
end

function eta()
    return string.format("%s", info[4])
end

