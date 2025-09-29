local obs = obslua

-- Variables

local enabled = false
local selected_process_name = ""
local check_interval_sec = 1.0
local timer = 0.0
local last_mod_time = 0


-- ---------- OBS functions called on script startup
function script_properties()  -- UI Properties

    local props = obs.obs_properties_create()
    obs.obs_properties_add_text(props, "selected_process_name", "Process Name", obs.OBS_TEXT_DEFAULT)
    obs.obs_properties_add_float(props, "check_interval_sec", "Check Interval (seconds)", 0.1, 1000, 0.1)
	obs.obs_properties_add_bool(props, "enabled", "Enable Script")
    return props
end

function script_update(settings)  -- Updates variables from ui
    
    selected_process_name = obs.obs_data_get_string(settings, "selected_process_name"):lower()
    check_interval_sec = obs.obs_data_get_double(settings, "check_interval_sec")
	enabled = obs.obs_data_get_bool(settings, "enabled")
	
end

function script_defaults(settings) --- Ui default values

    obs.obs_data_set_default_double(settings, "check_interval_sec", 0.5)
    obs.obs_data_set_default_bool(settings, "enabled", false)
    obs.obs_data_set_default_string(settings, "selected_process_name", "program.exe")
end


-- ---------- Code

-- Function to check if file exists
local function file_exists(path)
    local f = io.open(path, "r")
    if f then f:close() return true end
    return false
end


-- Reads temp file to get window title
local function get_active_window_process_name()
	
	local home_path = os.getenv("HOME") or "/home/user" -- Gets the path of the home directory
    local file = io.open(home_path .. "/auto_record_window_script.txt", "r") -- Opens temp file holding focused window exe
	
	-- If file doesn't exist, error and disable script
	if not file then
	    print("Could not read temp file.")
		return
	end	
	
	local result = file:read("*a") -- Reads file
    file:close() -- Closes file
	
    return result
end

-- Toggles recording if the selected process is focused
local function toggle_recording_if_process_focused()
    if not enabled then return end  -- Disables if "enabled" is false

    local process_name = get_active_window_process_name() -- Calls function to get the active window exe
    if not process_name then return end -- Ends function if process name doesn't exist

    local is_process = (process_name:lower() == selected_process_name)
    local recording = obs.obs_frontend_recording_active()
    local paused = obs.obs_frontend_recording_paused()

    if is_process then -- If process is the selected process, record
			
        if paused then -- If paused, then unpause
            obs.obs_frontend_recording_pause(false)
			
        end
		
    elseif recording and not paused then -- If window is not focused, pause recording
        obs.obs_frontend_recording_pause(true)
		
    end
end

-- Tick handler: called periodically with the number of seconds since the last tick
function script_tick(seconds)
    -- Disables script if "enabled" is false
    if not enabled then return end

    -- Increment the timer by the elapsed time
    timer = timer + seconds

    -- If the accumulated time exceeds the check interval, perform the toggle logic
    if timer >= check_interval_sec then
        toggle_recording_if_process_focused()  -- Call the function to handle recording state
        timer = 0  -- Reset the timer after the check
    end
end


-- ---------- Description
function script_description()
    return [[
Automatically starts/pauses recording when specified window is active/inactive.
Useful for only recording when you're using the specified application.

Requires Python.
]]
end
