ApmTelem_API_VER = 2

local soundfile_base = "/SOUNDS/en/fm_"

local apm_status_message = {severity = 0, textnr = 0, timestamp=0}

local outputs = {"armd"}

local function init()
	ApmTelem_ACTIVE = true
	-- Prepare A2 for hdop
	local A2 = model.getTelemetryChannel(1)
	if A2 .unit ~= 3 or A2 .range ~=1024 or A2 .offset ~=0 
	then
		A2.unit = 3
		A2.range = 1024
		A2.offset = 0
		model.setTelemetryChannel(1, A2)
	end
	-- Prepare A3 and A4 for roll
	local A3 = model.getTelemetryChannel(2)
	if A3.unit ~= 3 or A3.range ~=362 or A3.offset ~=-180 
	then
		A3.unit = 3
		A3.range = 362
		A3.offset = -180
		A3.alarm1 = -180
		A3.alarm2 = -180
		model.setTelemetryChannel(2, A3)
	end
	-- Prepare A3 and A4 for roll
	local A4 = model.getTelemetryChannel(3)
	if A4.unit ~= 3 or A4.range ~=362 or A4.offset ~=-180 
	then
		A4.unit = 3
		A4.range = 362
		A4.offset = -180
		A4.alarm1 = -180
		A4.alarm2 = -180
		model.setTelemetryChannel(3, A4)
	end
end

local function decodeApmWarning(severity)
	-- +10 is added to mavlink-value so 0 represents no warning
	if     severity == 0 then return ""
	elseif severity == 1 then return "Emergency"
	elseif severity == 2 then return "Alert"
	elseif severity == 3 then return "Critical"
	elseif severity == 4 then return "Error"
	elseif severity == 5 then return "Warning"
	elseif severity == 6 then return "Notice"
	elseif severity == 7 then return "Info"
	elseif severity == 8 then return "Debug"
	end
	return "Unknown"
end

local function decodeApmStatusText(textnr)
	if     textnr == 1  then return "PreArm: RC not calibrated"
	elseif textnr == 2  then return "PreArm: RC not calibrated"
	elseif textnr == 3  then return "PreArm: Baro not healthy"
	elseif textnr == 4  then return "PreArm: Alt disparity"
	elseif textnr == 5  then return "PreArm: Compass not healthy"
	elseif textnr == 6  then return "PreArm: Compass not calibrated"
	elseif textnr == 7  then return "PreArm: Compass offsets too high"
	elseif textnr == 8  then return "PreArm: Check mag field"
	elseif textnr == 9  then return "PreArm: INS not calibrated"
	elseif textnr == 10 then return "PreArm: INS not healthy"
	elseif textnr == 11 then return "PreArm: Check Board Voltage"
	elseif textnr == 12 then return "PreArm: Ch7&Ch8 Opt cannot be same"
	elseif textnr == 13 then return "PreArm: Check FS_THR_VALUE"
	elseif textnr == 14 then return "PreArm: Check ANGLE_MAX"
	elseif textnr == 15 then return "PreArm: ACRO_BAL_ROLL/PITCH"
	elseif textnr == 16 then return "PreArm: GPS Glitch"
	elseif textnr == 17 then return "PreArm: Need 3D Fix"
	elseif textnr == 18 then return "PreArm: Bad Velocity"
	elseif textnr == 19 then return "PreArm: High GPS HDOP"
	
	elseif textnr == 20 then return "Arm: Alt disparity"
	elseif textnr == 21 then return "Arm: Thr below FS"
	elseif textnr == 22 then return "Arm: Leaning"
	elseif textnr == 23 then return "Arm: Safety Switch"
	
	elseif textnr == 24 then return "AutoTune: Started"
	elseif textnr == 25 then return "AutoTune: Stopped"
	elseif textnr == 26 then return "AutoTune: Success"
	elseif textnr == 27 then return "AutoTune: Failed"

	elseif textnr == 28 then return "Crash: Disarming"
	elseif textnr == 29 then return "Parachute: Released!"
	elseif textnr == 30 then return "Parachute: Too Low"
	elseif textnr == 31 then return "EKF variance"
	elseif textnr == 32 then return "Low Battery!"
	elseif textnr == 33 then return "Lost GPS!"
	elseif textnr == 34 then return "Trim saved"

	elseif textnr ==  35 then return "compass disabled\n"
	elseif textnr ==  36 then return "check compass"
	elseif textnr ==  37 then return "RC not calibrated"
	elseif textnr ==  38 then return "thr not zero"
	elseif textnr ==  39 then return "Not landed"
	elseif textnr ==  40 then return "STARTING CALIBRATION"
	elseif textnr ==  41 then return "CURRENT"
	elseif textnr ==  42 then return "THROTTLE"
	elseif textnr ==  43 then return "Calibration Successful!"
	elseif textnr ==  44 then return "Failed!"
  
	elseif textnr ==  45 then return "bad rally point message ID"
	elseif textnr ==  46 then return "bad rally point message count"
	elseif textnr ==  47 then return "error setting rally point"
	elseif textnr ==  48 then return "bad rally point index"
	elseif textnr ==  49 then return "failed to set rally point"
  
	elseif textnr ==  50 then return "Erasing logs"
	elseif textnr ==  51 then return "Log erase complete"
  
	elseif textnr ==  52 then return "Motor Test: RC not calibrated"
	elseif textnr ==  53 then return "Motor Test: vehicle not landed"
	elseif textnr ==  54 then return "Motor Test: Safety Switch"
  
	elseif textnr ==  55 then return "No dataflash inserted"
	elseif textnr ==  56 then return "ERASING LOGS"
	elseif textnr ==  57 then return "Waiting for first HIL_STATE message"
	elseif textnr ==  61 then return "Ready to FLY."
	elseif textnr ==  62 then return "NO airspeed"
  
	elseif textnr ==  59 then return "command received: "
	elseif textnr ==  60 then return "new HOME received"

	elseif textnr ==  63 then return "Disable fence failed (autodisable)"
	elseif textnr ==  64 then return "Fence disabled (autodisable)"
  
	elseif textnr ==  65 then return "Demo Servos!"
  
	elseif textnr ==  66 then return "Resetting prev_WP"
	elseif textnr ==  67 then return "init home"
	elseif textnr ==  68 then return "Fence enabled. (autoenabled)"
	elseif textnr ==  69 then return "verify_nav: LOITER time complete"
	elseif textnr ==  70 then return "verify_nav: LOITER orbits complete"
	elseif textnr ==  71 then return "Reached home"
  
	elseif textnr ==  72 then return "Failsafe - Short event on, "
	elseif textnr ==  73 then return "Failsafe - Long event on, "
	elseif textnr ==  74 then return "No GCS heartbeat."
	elseif textnr ==  75 then return "Failsafe - Short event off"

	elseif textnr ==  76 then return "command received: "
	elseif textnr ==  77 then return "fencing must be disabled"
	elseif textnr ==  78 then return "bad fence point"
  
	elseif textnr ==  79 then return "verify_nav: Invalid or no current Nav cmd"
	elseif textnr ==  80 then return "verify_conditon: Invalid or no current Condition cmd"
	elseif textnr ==  81 then return "Enable fence failed (cannot autoenable"
 
	elseif textnr ==  82 then return "geo-fence loaded"
	elseif textnr ==  83 then return "geo-fence setup error"
	elseif textnr ==  84 then return "geo-fence OK"
	elseif textnr ==  85 then return "geo-fence triggered"
  
	elseif textnr ==  86 then return "flight plan update rejected"
	elseif textnr ==  87 then return "flight plan received"
	end
	return ""
end

function getApmActiveStatus()
	if apm_status_message.timestamp == 0
	then 
		return nil
	end
	return {timestamp = apm_status_message.timestamp, message = getApmActiveWarnings(true), severity = apm_status_message.severity}
end

function getApmActiveStatusSeverity()
	if isApmActiveStatus() == false
	then 
		return ""
	end
	return decodeApmWarning(apm_status_message.severity)
end

function getApmActiveStatusText()
	if isApmActiveStatus() == false
	then 
		return ""
	end
	return decodeApmStatusText(apm_status_message.textnr)
end

function getApmActiveWarnings(includeUnknown)
	local severity = getApmActiveStatusSeverity()
	local text = getApmActiveStatusText()
	
	if includeUnknown == false or text ~= "" 
	then 
		return text
	end
	
	if severity == "" 
	then 
		return ""
	end
	
	return severity..apm_status_message.textnr;
end

function isApmActiveStatus()
	if apm_status_message.timestamp > 0
	then
		return true
	end
	return false
end

function getApmFlightmodeNumber()
	return getValue(208) -- Fuel
end

function getApmFlightmodeText()
  local mode = getApmFlightmodeNumber()
  if     mode == 0  then return "Stabilize"
  elseif mode == 1  then return "Acro"
  elseif mode == 2  then return "Altitude Hold"
  elseif mode == 3  then return "Auto"
  elseif mode == 4  then return "Guided"
  elseif mode == 5  then return "Loiter"
  elseif mode == 6  then return "Return to launch"
  elseif mode == 7  then return "Circle"
  elseif mode == 9  then return "Land"
  elseif mode == 10 then return "Optical Flow Loiter"
  elseif mode == 11 then return "Drift"
  elseif mode == 13 then return "Sport"
  elseif mode == 15 then return "Autotune"
  elseif mode == 16 then return "Position Hold"
  end
  return "Unknown Flightmode"
end

function getApmGpsHdop()
	return getValue(203)/10 -- A2
end 

function getApmGpsSats()
  local telem_t1 = getValue(209) -- Temp1
  return (telem_t1 - (telem_t1%10))/10
end

function getApmGpsLock()
  local telem_t1 = getValue(209) -- Temp1
  return  telem_t1%10
end

function getApmArmed()
	return getValue(210)%2 > 0 -- Temp2
end


-- The heading to pilot home position - relative to apm position
function getApmHeadingHome()
  local pilotlat = getValue("pilot-latitude")
  local pilotlon = getValue("pilot-longitude")
  local curlat = getValue("latitude")
  local curlon = getValue("longitude")
  
  if pilotlat~=0 and curlat~=0 and pilotlon~=0 and curlon~=0 
  then 
    local z1 = math.sin(math.rad(curlon) - math.rad(pilotlon)) * math.cos(math.rad(curlat))
    local z2 = math.cos(math.rad(pilotlat)) * math.sin(math.rad(curlat)) - math.sin(math.rad(pilotlat)) * math.cos(math.rad(curlat)) * math.cos(math.rad(curlon) - math.rad(pilotlon))

    local head_from = (math.deg(math.atan2(z1, z2)) + 360)%360
	local head_to = (head_from+180)%360
	return head_to
  end
  return 0
end

-- The heading to pilot home position relative to the current heading.
function getApmHeadingHomeRelative()
	local tmp = getApmHeadingHome() - getValue(223) -- Heading
	return (tmp +360)%360
end

local function getWarningTimeout()
	-- 2 second timeout
	return getTime() + 100*2
end

local function run_func()
	-- Handle warning messages from mavlink
	local t2 = getValue(210) -- Temp2
	local armed = t2%0x02;
	t2 = (t2-armed)/0x02;
	local status_severity = t2%0x10;
	t2 = (t2-status_severity)/0x10;
	local status_textnr = t2%0x400;
	if(status_severity > 0)
	then
		if status_severity ~= apm_status_message.severity or status_textnr ~= apm_status_message.textnr
		then
			apm_status_message.severity = status_severity
			apm_status_message.textnr = status_textnr
			apm_status_message.timestamp = getTime()
		end
	end
	if apm_status_message.timestamp > 0 and (apm_status_message.timestamp + 2*100) < getTime()
	then
		apm_status_message.severity = 0
		apm_status_message.textnr = 0
		apm_status_message.timestamp = 0
	end

	-- Calculate return value (armed)
	local armd = 0
	if(getApmArmed() == true)
	then
		armd = 1024
	else
		armd = 0
	end	
	return armd
end  

return {init=init, run=run_func, output=outputs}