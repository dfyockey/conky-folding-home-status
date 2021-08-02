# conky-FoldingAtHome-status

Lua script for displaying Folding@Home status information in Conky

Retreives and formats status information from a running Folding@Home
client and makes that information available for display in Conky.

### Example

Status information shown in FAHControl...

![Image of FAHClient](https://raw.githubusercontent.com/dfyockey/conky-FoldingAtHome-status/main/.github/images/FAHClient.png)

...can be displayed in Conky as

![Image of conky display](https://raw.githubusercontent.com/dfyockey/conky-FoldingAtHome-status/main/.github/images/conkydisplay.png)

### Usage

Make the following changes to your .conkyrc file:

1. Add `fahqi.lua` to a lua_load line in conky.config (e.g. `lua_load = 'fahqi.lua'`)
    - Include the full path to the file if necessary (e.g. `lua_load = '~/conky_scripts/fahqi.lua'`)
    
    - To use with another Lua script simultaneously, provide a
      space-separated list on the lua_load line
      (e.g. `lua_load = '~/conky_scripts/other.lua ~/conky_scripts/fahqi.lua'`)
      
2. Add the line `${lua load_fah_queue_info}` in conky.text.

3. Following that line, add a number of lines equal to the number of running slots to display the loaded data
    - For example:
        
        ```
        F@H Proj ${lua fah_project 0} ${lua fah_status 0}
        F@H Proj ${lua fah_project 1} ${lua fah_status 1}
          ...
        F@H Proj ${lua fah_project n} ${lua fah_status n}
        ```
        
    - Additional functions `fah_pctdone` and `fah_pctleft` return integer
      percentage values from 0 to 100 with no other formatting. As in the
      preceding examples, each takes a 0-based index as a function
      parameter. They can be used with conky objects `lua_bar` or
      `lua_gauge` to display the values in a bar or gauge, respectively.
