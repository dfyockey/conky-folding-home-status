--[[
Folding@Home Queue Information data parser for conky
  - Functionally completed for single slot display on 20 October 2020

Usage:
- The Folding@Home project packages should be installed and FAHClient
  running, as the script gets information from a running FAHClient instance
- Add fahqi.lua to a load_lua line in your .conkyrc file, including the
  full path to the file if necessary (e.g. ~/conky_scripts/fahqi.lua)
- For display of single slot status, add a line such as the following to
  your conky configuration file (where '00' is the default work queue id
  when running only a single slot):
    ${lua load_fah_queue_info} Folding@Home Proj ${lua fah_project 00}: 00 ${lua_parse fah_status 00}
- To display status for multiple slots, include a single ${lua load_fah_queue_info}
  object followed by objects needed to display the desired information for each slot
  (where '00', '01', etc are work queue ids), such as:
		${lua conky_load_fah_queue_info}
		Folding@Home Proj ${lua fah_project 00}: 00 ${lua_parse fah_status 00}
					 Proj ${lua fah_project 01}: 01 ${lua_parse fah_status 01}
					 ...

To Add Other Data Values:
  1) In a terminal, run `FAHClient --send-command queue-info`
  2) Examine the output to find the keys for values of interest
  3) Add the keys to the `keys = {...}` sequence
  4) Modify conky_load_fah_queue_info() to process the value and load it
     into the info table, as needed
  5) Add a conky display function and, if needed, one or more formatting
     utility functions for each value to be displayed
  6) Add a `${lua <function_name> [options]}` object for each value to be
     displayed to the conky configuration file

# MIT License
#
# Copyright 2020-2021 David Yockey
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
info = {}
iter = 1

-- Number of conky iterations between each reload of queue info;
-- use to reduce conky impact on cpu time.
throttle = 5

-- Folding@Home data retreival and info table loading algorithm;
-- call from conky once to load data into the info table before calling
-- the display functions for all Slots' info to be displayed.
function conky_load_fah_queue_info()
    if conky_window == nil then
        return
    end
    
    if iter == throttle then 
		-- The following command, obviating need for use of telnet, was suggested by the post at
		-- https://foldingforum.org/viewtopic.php?f=88&t=25050&p=249988&hilit=conky#p250414
		cmd = 'FAHClient --send-command queue-info'
		
		local f = assert(io.popen(cmd, 'r'))
		local qi = assert(f:read('a'))
		f:close()
		
		for qiWU in string.gmatch(qi,'({[^}]*})') do
			idWU = string.match(qiWU,'"id": "(%d%d)"')
			
			for k = 1, #keys do 
				idxWU = getidx(k,idWU)
				pattern = '"'..keys[k]..'": [^,]+,'
				keyvalue = string.match(qiWU, pattern)
				if keyvalue == nil then
					info[idxWU] = "-- no keyvalue --"
				else
					-- Get data value from combined key and value
					-- (need ': ' to avoid picking up '"' at start of key)
					value = string.match(keyvalue, ': "[^"]+"')
								
					if keys[k] == "eta" then
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
								--
								-- % in each string.format begins a conversion specification, which ends with a converison character (f or d)
								---- The string.format format string follows the same rules as the ISO C sprintf function
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
							value = dd .. "d"
						else
							value = string.format( '%2.2fh', ( ( (hh*3600) + (mm*60) + ss ) / 3600) )
						end
					
					elseif keys[k] == "state" then
						-- Text-Only Info
						value = string.match(value, '%a+')
					else
						-- Numeric-Only Info
						value = string.match(keyvalue, '[%d%.]+')
					end
					
					if value ~= nil then
						info[idxWU] = value
					else
						info[idxWU] = "-- no value --"
					end
				end
			end
		end

		iter = 1
    else
		iter = iter + 1
    end
end

-------
-- utility for calculating an offset index in the global `info` table
--
function getidx(k,id)
	-- k  = index to a key in the global `keys` table to refer to the data value to retrieve
	-- id = ID of Work Unit in the Work Queue for which to retrieve the data value
	return tonumber(k + (#keys * id))
end
-------
-- conky display functions to be called in `${lua}` objects
--
function conky_fah_project(id)
    if conky_window == nil then
        return
    end

    return string.format("%d", info[getidx(1,id)])
end

function conky_fah_status(id)
    if conky_window == nil then
        return
    end

    if info[getidx(3,id)] == "RUNNING" then
		return percentdone(id)..' '..eta(id)
    else
        return string.format(" Status: %s", info[getidx(3,id)])
    end
end

function conky_fah_pctdone(id)
	return string.format("%2f", info[getidx(2,id)])
end

function conky_fah_pctleft(id)
	return string.format("%2f", 100 - info[getidx(2,id)])
end
-------
-- utilities for formatting data values
--
function percentdone(id)
    return string.format("%5.2f", info[getidx(2,id)]).."%"
end

function eta(id)
    return string.format("%s", info[getidx(4,id)])
end
-------
