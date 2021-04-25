# conky-FoldingAtHome-status
Lua script for displaying Folding@Home status information in Conky

Retrieves current work unit folding status information from a running Folding@Home client and makes formatted values selected from that information available for display in Conky.

**Example:**

- Status information shown in FAHControl as...

![Screenshot_2021-04-23_21-10-33](https://user-images.githubusercontent.com/17618397/115942754-c18a5a80-a479-11eb-9cf6-ecbb44280e2e.png)

...is displayed in Conky (with blurring added for emphasis) as...

![Screenshot_2021-04-23_21-13-39](https://user-images.githubusercontent.com/17618397/115942795-ea125480-a479-11eb-96a3-86e4c22a0456.png)

The information shown above includes project, percent done, and time remaining. The symbol `☌` (Unicode UTF-16: 0x260C) is the alchemical symbol for "day" and is displayed when the remaining time is a day or more.

When the remaining time is less than a day, it's shown in hours. For example...

![Screenshot_2021-04-24_21-00-37](https://user-images.githubusercontent.com/17618397/115976957-fc0afa80-a540-11eb-8f49-fa01b97019cc.png)

If the FAHClient is paused, a status indication will be displayed with the project as...

![Screenshot_2021-04-23_22-01-33](https://user-images.githubusercontent.com/17618397/115943696-83903500-a47f-11eb-9b6e-757eca8014bd.png)

In other situations when infomation is not currently available, other status indicators will be displayed as appropriate.

**Usage:**

- The Folding@Home project packages should be installed and FAHClient
  running, as the script gets information from a running FAHClient
  instance via telnet.
  
- Add `fahqi.lua` to a load_lua line in your .conkyrc file.

- Add a line such as the following to your .conkyrc file where the status information is to appear:
> ${lua conky_load_fah_queue_info} Folding@Home Proj: ${lua conky_fah_project} ${lua_parse conky_fah_status}
 
**Customization:**

See the notes at the beginning of the `fahqi.lua` file for information on formatting or changing the day symbol `☌` and on adding other data values to the display.
