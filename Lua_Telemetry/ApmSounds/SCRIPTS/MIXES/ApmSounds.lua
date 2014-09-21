local soundfile_base = "/SOUNDS/en/fm_"

-- Internal
local last_flight_mode = 0
local last_flight_mode_play = 0
local received_telemetry = false
local first_telemetry = -1

local function nextRepeatFlightmode(mode)
  if last_flight_mode_play < 1 then
	return 0
  end
  -- Auto or guided (every 15 sec)
  if mode == 3 or mode == 4  then
	return last_flight_mode_play + 15*100
  -- Return to launch or land (every 5 sec)
  elseif mode == 6 or mode == 9 then
    return last_flight_mode_play + 5*100
  end
  -- All others (every hour)
   return last_flight_mode_play + 3600*100
end

local function playFlightmode()
  if received_telemetry == false 
  then
    local rssi = getValue("rssi")
    if rssi < 1 
	then
	  return
	end
	if first_telemetry < 0 
	then
		first_telemetry = getTime()
	end
	if (first_telemetry + 150) > getTime()
	then
		return
	end
	received_telemetry = true
  end
  local mode=getValue("fuel")
  if (mode ~= last_flight_mode) or (nextRepeatFlightmode(mode) < getTime()) 
  then
	last_flight_mode_play = getTime()
	playFile(soundfile_base  .. mode .. ".wav")
	last_flight_mode = mode
  end
end

local function run_func()
 playFlightmode()
end  

return {init=init, run=run_func}