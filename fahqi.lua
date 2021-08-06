--[[
Folding@Home Queue Information Data Parser for Conky
  - Functionally completed for single slot display on 20 October 2020

Requirements:
- Folding@Home project packages installed and FAHClient running.

Setup in .conkyrc file:
- Add fahqi.lua to a lua_load line in conky.config
    - Include the full path to the file if necessary
      (e.g. lua_load = '~/conky_scripts/fahqi.lua')
    - To use with another Lua script simultaneously, provide a
      space-separated list on the lua_load line
      (e.g. lua_load = '~/conky_scripts/other.lua ~/conky_scripts/fahqi.lua')
- Add the line
        ${lua load_fah_queue_info}
  to conky.text.
- Following that line, add a number of lines equal to the number of
  running slots to display the loaded data; for example:
        F@H Proj ${lua fah_project 0} ${lua fah_status 0}
        F@H Proj ${lua fah_project 1} ${lua fah_status 1}
          ...
        F@H Proj ${lua fah_project n} ${lua fah_status n}

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

keys = {"project", "percentdone", "state", "eta", "id"}

--[[
  Inverse index for quick key-to-index retreival.
  (Note: in table keys, the 'keys' are the values.)
  From https://stackoverflow.com/a/38283667.
--]]
local kindex={}
for k,v in pairs(keys) do
   kindex[v]=k
end

-- Note: While Lua tables are 1-based, table info is used as a 2D array
-- with 0-based rows. The 0-based row index is used by functions getidx
-- and getidx2 to calculate the index to a particular value in table info.
info = {}

iter = 1

-- Number of conky iterations between each reload of queue info;
-- use to reduce conky impact on cpu time.
throttle = 5

-- Folding@Home data retreival and info table loading algorithm;
-- call from conky once to load data into the info table before calling
-- the display functions for all Slots' info to be displayed.
function conky_load_fah_queue_info()
    if iter == throttle then 
        -- The following command, obviating need for use of telnet, was suggested by the post at
        -- https://foldingforum.org/viewtopic.php?f=88&t=25050&p=249988&hilit=conky#p250414
        cmd = 'FAHClient --send-command queue-info'

        --[[
          The following is based on code from https://stackoverflow.com/a/326715.
          I could find no reason for the f:read argument's '*' in the code at the noted site.
        --]]
        local f = assert(io.popen(cmd, 'r'))
        local qi = assert(f:read('a'))
        f:close()

        infoRow = 0     -- Used as an index to the info table so rows are indexed starting at 0 rather than by work unit id.
                        -- Conky objects can then access the info for a number of running slots simply by using 0-based indices.
                        -- Thus, when running only a single slot, data will always be at index 0 regardless of work unit id.

        for qiWU in string.gmatch(qi,'{[^}]*}') do  -- No parentheses needed here...
                                                    -- Lua 5.3 Ref Manual, §6.4, string.gmatch (s, pattern):
                                                    -- "If pattern specifies no captures, then the whole match is produced in each call."

            idWU = string.match(qiWU,'"id": "(%d%d)"')

            for k = 1, #keys do
                idxWU = getidx(k,infoRow)
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
                                    tt = string.format('%5.2f', datum)
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
                            value = string.format( '%5.2fh', ( ( (hh*3600) + (mm*60) + ss ) / 3600) )
                        end

                    elseif keys[k] == "state" then
                        -- Text-Only Info
                        value = string.match(value, '%a+')
                    else
                        -- Numeric-Only Info
                        --      Note that id values and project values are assumed to be two and five digits, respectively.
                        --      This may change in the future. The percentdone values are formatted for output by
                        --      'function percentdone' below, so there's no worries about that.
                        value = string.match(keyvalue, '[%d%.]+')
                    end

                    if value ~= nil then
                        info[idxWU] = value
                    else
                        info[idxWU] = "-- no value --"
                    end
                end
            end

            infoRow = infoRow + 1
        end

        bubblesortInfo("id")
        bubblesortInfo("state")
        iter = 1
    else
        iter = iter + 1
    end
end

-------
-- Utilities
--

-- Functions getidx and getidx2 each calculate the same value:
--      an offset index to a value in the global `info` table.
-- The primary purpose of getidx2 is to
--      eliminate "magic numbers" in the code.
function getidx(k, row)
    -- k   = index to a key in the global `keys` table referring to the data value to retrieve
    -- row = 0-based index to the row in the `info` table from which to retrieve the data value
    return tonumber(k + (#keys * row))
end
--
function getidx2(key, row)
    -- key = a key listed in the global `keys` table referring to the data value to retrieve
    -- row = 0-based index to the row in the `info` table from which to retrieve the data value
    return tonumber(kindex[key] + (#keys * row))
end
--

function swapRows(rowa, rowb)
    local k, temp
    for k = 1, #keys do
        temp = info[getidx(k,rowa)]
        info[getidx(k,rowa)] = info[getidx(k,rowb)]
        info[getidx(k,rowb)] = temp
    end
end

function bubblesortInfo(key)    -- Sort table info rows by Work Queue id
    local i, j
    local n = #info // #keys    -- n = number of rows in table info
    local k = kindex[key]
    
    -- Have to use -2 rather than the -1 in a standard bubblesort since
    -- the loops need to continue while the loop value is less than n-1,
    -- but a Lua 'for' loop just provides a simple stepped count and
    -- lacks an iterative evaluation as in C/C++ and the like.
    for i = 0, n-2 do
        for j = 0, n-i-2 do
            if (key == "id" and info[getidx(k,j)] > info[getidx(k,j+1)]) or (key == "state" and info[getidx(k,j)] ~= "RUNNING" and info[getidx(k,j+1)] == "RUNNING") then
                swapRows(j,j+1)
            end
        end
    end
end

-------
-- conky display functions to be called in `${lua}` objects
--

function conky_fah_project(row)
    return string.format("%d", info[getidx2("project",row)])
end

function conky_fah_status(row)
    if info[getidx2("state",row)] == "RUNNING" then
        return conky_fah_percentdone(row).."% "..conky_fah_eta(row)
    else
        return string.format(" Status: %s", info[getidx2("state",row)])
    end
end

function conky_fah_pctdone(row)  -- useful for ascending bar or gauge
    return string.format("%2f", info[getidx2("percentdone",row)])
end

function conky_fah_pctleft(row)  -- useful for decending bar or gauge
    return string.format("%2f", 100 - info[getidx2("percentdone",row)])
end

function conky_fah_id(row)
    return string.format("%s", info[getidx2("id",row)])
end

-------
-- utilities for formatting data values (could be called in `${lua}` objects)
--

function conky_fah_percentdone(row)
    return string.format("%05.2f", info[getidx2("percentdone",row)])
end

function conky_fah_eta(row)
    return string.format("%s", info[getidx2("eta",row)])
end

-------
