# OBS Auto Record Window

This is a linux python/lua script that automatically starts/pauses recording when the specified program gains/loses focus. Useful for only recording an application when you're actually using it. Saves space and video length.

# Usage

1. Install Python, do `pip install psutil` in your virtual environment, and pull this repo.
2. In obs `Tools >> Scripts >> +`, import `auto_record_window.lua`.
3. Run `xprop` and click on the window you want to record. Use the second string for Process Name.
4. Reload the script, check `Enable Script`, and run `window_check.py`.

Now OBS will automatically start recording when the specified window gains focus. When it loses focus, OBS will pause the recording.

# Config
### auto_record_window.lua
(in OBS Scripts tab)  
- `Process Name` - The window class of the program you want to run. Get this by running `xprop`, clicking a window, and using the second string.
- `Check Interval (seconds)` `Default: 0.5` - The amount of time in seconds it takes to re-check the currently focused window. Low values (0.1) may cause performance issues due to reading file off of disk many times per second.

### window_check.py
(inside file)  
- `window_check_interval = 0.1` - Checks currently focused window every 0.1ms, and if it's different from last check, write the program window class to file. The python and lua script may not be in sync, so the python script checks frequently to lower the latency. Generally it's a pretty fast operation, but if you are on very slow hardware, you may want to increase the value.
- `obs_check_interval = 15` - Checks if OBS exists every 15 seconds. Closes script if OBS doesn't exist.




