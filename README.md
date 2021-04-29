# conky-FoldingAtHome-status

Lua script for displaying Folding@Home status information in Conky

Retrieves current work unit folding status information from a running Folding@Home client and makes formatted values selected from that information available for display in Conky.

**Example:**

- Status information shown in FAHControl as...

![Screenshot_2021-04-28_12-01-25](https://user-images.githubusercontent.com/17618397/116442074-146c6500-a820-11eb-967a-da2e12538e7f.png)

...is to available to and can be displayed in Conky; for example (with blurring added for emphasis)...

![Screenshot_2021-04-28_12-02-14](https://user-images.githubusercontent.com/17618397/116442153-2b12bc00-a820-11eb-909e-a60cd786dffd.png)

The information shown above for the work unit being processed includes project, work queue id, percent done, and time remaining to complete the work unit.

The the suffix `d` is appended to the remaining time when it is a day or more. When the remaining time is less than a day, it's shown in hours with an appended `h`. For example...

![Screenshot_2021-04-28_18-12-57](https://user-images.githubusercontent.com/17618397/116479388-8c04b900-a84d-11eb-81f0-db1425593fbb.png)

If the FAHClient is paused, a status indication is provided in place of the numeric stats...

![Screenshot_2021-04-28_12-36-32](https://user-images.githubusercontent.com/17618397/116442189-3534ba80-a820-11eb-96ef-350440247441.png)

In other situations when infomation is not currently available, other status indicators are provided as appropriate.

**Usage:**

- The Folding@Home project packages should be installed and FAHClient
  running, as the script gets information from a running FAHClient
  instance.

- Add `fahqi.lua` to a load_lua line in your .conkyrc file; include the full path to the file if necessary.

- For display of single slot status, add a line such as the following to your .conkyrc file (where '00' is the default work queue id when running only a single slot):

    ```
    ${lua load_fah_queue_info} Folding@Home Proj ${lua fah_project 00} 00 ${lua_parse fah_status 00}
    ```

- To display status for multiple slots, include a single `${lua load_fah_queue_info}` object followed by objects needed to display the desired information for each slot (where '00', '01', etc are work queue ids), such as:

    ```
    ${lua load_fah_queue_info}
    Folding@Home Proj ${lua fah_project 00}: 00 ${lua_parse fah_status 00}
                 Proj ${lua fah_project 01}: 01 ${lua_parse fah_status 01}
                 ...
    ```

- Additional functions `fah_pctdone` and `fah_pctleft` return integer percentage values from 0 to 100 with no other formatting. As in the preceding examples, each takes a work queue id as a function parameter. They can be used with conky objects `lua_bar` or `lua_gauge` to display the values in a bar or gauge, respectively.

**Customization:**

See the notes at the beginning of the `fahqi.lua` file for information on making other data values available to display.
