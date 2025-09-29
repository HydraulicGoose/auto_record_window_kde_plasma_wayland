#!/usr/bin/env python3

import os
import time
import psutil
import subprocess
from pathlib import Path
import sys


def get_active_window_class():

    try:
        # Get the window ID of the currently active window
        window_id = subprocess.check_output(['xdotool', 'getactivewindow'], stderr=subprocess.DEVNULL).strip()

        # Get the window class (WM_CLASS) using xprop
        wm_class = subprocess.check_output(['xprop', '-id', window_id, 'WM_CLASS'], stderr=subprocess.DEVNULL)

        # Decode and parse the output to extract the class name
        wm_class = wm_class.decode('utf-8')

        # Extract the second string (usually the class) after the comma
        class_name = wm_class.split('=')[1].strip().split(',')[1].strip().strip('"')

        return class_name

    except (subprocess.CalledProcessError, IndexError, ValueError) as e:
        print(f"[WARN] Failed to get active window class: {e}")
        return None


def is_obs_running():
    """Check if any process named 'obs' is running."""

    try:
        for proc in psutil.process_iter(['name']):
            if proc.info['name'] and 'obs' in proc.info['name'].lower():
                return True
    except (psutil.NoSuchProcess, psutil.AccessDenied, psutil.ZombieProcess) as e:
        print(f"[WARN] psutil error: {e}")

    return False


def safe_remove(path):

    try:
        if os.path.exists(path):
            os.remove(path)

    except Exception as e:
        print(f"[WARN] Failed to remove file {path}: {e}")


def main():

    home_dir = os.path.expanduser("~")
    temp_name = "auto_record_window_script.txt"
    temp_path = os.path.join(home_dir, temp_name)

    last_process = ""

    window_check_interval = 0.1  # 100ms
    obs_check_interval = 15      # 15 seconds

    last_obs_check = time.time()

    # Write initial text to file
    try:
        with open(temp_path, 'w') as f:
            f.write("This is a manually created temp file.")

    except Exception as e:
        
        print(f"[ERROR] Failed to write initial file: {e}")
        sys.exit(1)

    while True:

        try:
            # Check if OBS is running every 15 seconds
            if time.time() - last_obs_check >= obs_check_interval:
                if not is_obs_running():

                    print("OBS is not running. Exiting script.")
                    safe_remove(temp_path)
                    sys.exit(0)

                last_obs_check = time.time()

            current_process = get_active_window_class()

            if current_process and current_process != last_process:

                safe_remove(temp_path)

                try:
                    with open(temp_path, 'w') as f:
                        f.write(current_process)

                except Exception as e:
                    print(f"[WARN] Failed to write current process to file: {e}")

                last_process = current_process

            time.sleep(window_check_interval)

        except KeyboardInterrupt:

            print("Script interrupted by user.")
            safe_remove(temp_path)
            sys.exit(0)

        except Exception as e:

            print(f"[ERROR] Unexpected error in main loop: {e}")
            time.sleep(1)  # Delay to avoid crash loops


if __name__ == "__main__":
    main()

