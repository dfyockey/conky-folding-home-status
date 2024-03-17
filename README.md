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

### Notes

* To stop conky from inserting a blank line above the first line in **Usage** step 3, you can add `${lua load_fah_queue_info}` in step 2 on the first line in step 3 before any script function calls instead of adding it on its own line.
* To set the frequency of updating the Folding@Home information, you can change the `throttle` value on line 68 of the script in file `fahqi.lua`. The default value is set to `5` so that the Folding@Home information will be updated once for every five conky updates, i.e. every 5th conky update.

### Functions available for use in Conky
(where `index` is a number from 0 thru n referring to a running slot)

<table>
<thead>
<tr><th>Function</th><th>Returns</th></tr>
</thead>
<tbody>
<tr><td>fah_eta (index)</td><td>Eta to completion as a floating-point fraction of days or hours</td></tr>
<tr><td>fah_id (index)</td><td>Work Queue ID of the status information referred to by index</td></tr>
<tr><td>fah_percentdone (index)</td><td>Floating-point percentage-done value</td></tr>
<tr><td>fah_pctdone (index)</td><td>Two-digit percentage-done value useful for an ascending bar or gauge</td></tr>
<tr><td>fah_pctleft (index)</td><td>Two-digit percentage-left value useful for an descending bar or gauge</td></tr>
<tr><td>fah_project (index)</td><td>Project number</td></tr>
<tr><td>fah_status (index)</td><td>Formatted percentage done and eta to completion</td></tr>
</tbody>
</table>
