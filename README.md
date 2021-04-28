# conky-FoldingAtHome-status

Lua script for displaying Folding@Home status information in Conky

Retrieves current work unit folding status information from a running Folding@Home client and makes formatted values selected from that information available for display in Conky.

**Example:**

- Status information shown in FAHControl as...

![Screenshot_2021-04-28_12-01-25.png](/home/David/tmp/Screenshot_2021-04-28_12-01-25.png)

...is displayed in Conky (with blurring added for emphasis) as...

![Screenshot_2021-04-28_12-02-14.png](/home/David/tmp/Screenshot_2021-04-28_12-02-14.png)

The information shown above for the workunit being processed includes project, slot id, percent done, and time remaining to complete the workunit.

The the suffix `d` is displayed when the remaining time is a day or more. When the remaining time is less than a day, it's shown in hours with an appended `h`. For example...

![Screenshot_2021-04-24_21-00-37](https://user-images.githubusercontent.com/17618397/115976957-fc0afa80-a540-11eb-8f49-fa01b97019cc.png)

If the FAHClient is paused, a status indication will be displayed with the project as...

![Screenshot_2021-04-28_12-36-32.png](/home/David/tmp/Screenshot_2021-04-28_12-36-32.png)

In other situations when infomation is not currently available, other status indicators will be displayed as appropriate.

**Usage:**

- The Folding@Home project packages should be installed and FAHClient
  running, as the script gets information from a running FAHClient
  instance.

- Add `fahqi.lua` to a load_lua line in your .conkyrc file.

- For display of single slot status, add a line such as the following to your .conkyrc file where the status information is to appear:
  
  > ${lua conky_load_fah_queue_info} Folding@Home Proj: ${lua conky_fah_project 00} ${lua_parse conky_fah_status 00}

- To display status for multiple slots, include a single `${lua conky_load_fah_queue_info}` object followed by objects needed to display the desired information for each slot, such as:

`Folding@Home Proj: ${lua conky_fah_project 00} ${lua_parse conky_fah_status 00}`
`             Proj: ${lua conky_fah_project 01} ${lua_parse conky_fah_status 01}`

**Customization:**

See the notes at the beginning of the `fahqi.lua` file for information on making other data values available to display.
