ApmTelem_API_VER = 2

local soundfile_base = "/SOUNDS/en/fm_"

local apm_status_message = {severity=0, id=0, timestamp = 0, message="", enabled=false, silent=true, soundfile=""}

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
	
	if     textnr == 1  then return {enabled=false, silent=false, text="ARMING MOTORS", soundfile=""}
	elseif textnr == 2  then return {enabled=true, silent=false, text="PreArm: RC not calibrated", soundfile="apm_prearm.wav"}
	elseif textnr == 3  then return {enabled=true, silent=false, text="PreArm: Baro not healthy", soundfile="apm_prearm.wav"}
	elseif textnr == 4  then return {enabled=true, silent=false, text="PreArm: Alt disparity", soundfile="apm_prearm.wav"}
	elseif textnr == 5  then return {enabled=true, silent=false, text="PreArm: Compass not healthy", soundfile="apm_prearm.wav"}
	elseif textnr == 6  then return {enabled=true, silent=false, text="PreArm: Compass not calibrated", soundfile="apm_prearm.wav"}
	elseif textnr == 7  then return {enabled=true, silent=false, text="PreArm: Compass offsets too high", soundfile="apm_prearm.wav"}
	elseif textnr == 8  then return {enabled=true, silent=false, text="PreArm: Check mag field", soundfile="apm_prearm.wav"}
	elseif textnr == 9  then return {enabled=true, silent=false, text="PreArm: INS not calibrated", soundfile="apm_prearm.wav"}
	elseif textnr == 10 then return {enabled=true, silent=false, text="PreArm: INS not healthy", soundfile="apm_prearm.wav"}
	elseif textnr == 11 then return {enabled=true, silent=false, text="PreArm: Check Board Voltage", soundfile="apm_prearm.wav"}
	elseif textnr == 12 then return {enabled=true, silent=false, text="PreArm: Ch7&Ch8 Opt cannot be same", soundfile="apm_prearm.wav"}
	elseif textnr == 13 then return {enabled=true, silent=false, text="PreArm: Check FS_THR_VALUE", soundfile="apm_prearm.wav"}
	elseif textnr == 14 then return {enabled=true, silent=false, text="PreArm: Check ANGLE_MAX", soundfile="apm_prearm.wav"}
	elseif textnr == 15 then return {enabled=true, silent=false, text="PreArm: ACRO_BAL_ROLL/PITCH", soundfile="apm_prearm.wav"}
	elseif textnr == 16 then return {enabled=true, silent=false, text="PreArm: GPS Glitch", soundfile="apm_prearm.wav"}
	elseif textnr == 17 then return {enabled=true, silent=false, text="PreArm: Need 3D Fix", soundfile="apm_prearm.wav"}
	elseif textnr == 18 then return {enabled=true, silent=false, text="PreArm: Bad Velocity", soundfile="apm_prearm.wav"}
	elseif textnr == 19 then return {enabled=true, silent=false, text="PreArm: High GPS HDOP", soundfile="apm_prearm.wav"}
	
	elseif textnr == 20 then return {enabled=true, silent=false, text="Arm: Alt disparity", soundfile="apm_arm.wav"}
	elseif textnr == 21 then return {enabled=true, silent=false, text="Arm: Thr below FS", soundfile="apm_arm.wav"}
	elseif textnr == 22 then return {enabled=true, silent=false, text="Arm: Leaning", soundfile="apm_arm.wav"}
	elseif textnr == 23 then return {enabled=true, silent=false, text="Arm: Safety Switch", soundfile="apm_arm.wav"}
	elseif textnr == 89 then return {enabled=false, silent=false, text="DISARMING MOTORS", soundfile=""}

	elseif textnr == 90 then return {enabled=false, silent=false, text="Calibrating barometer", soundfile=""}
	elseif textnr == 91 then return {enabled=false, silent=false, text="barometer calibration complete", soundfile=""}
	elseif textnr == 92 then return {enabled=false, silent=false, text="zero airspeed calibrated", soundfile=""}
	
	elseif textnr == 24 then return {enabled=true, silent=false, text="AutoTune: Started", soundfile="apm_autotune_start.wav"}
	elseif textnr == 25 then return {enabled=true, silent=false, text="AutoTune: Stopped", soundfile="apm_autotune_stop.wav"}
	elseif textnr == 26 then return {enabled=true, silent=false, text="AutoTune: Success", soundfile="apm_autotune_done.wav"}
	elseif textnr == 27 then return {enabled=true, silent=false, text="AutoTune: Failed", soundfile="apm_autotune_fail.wav"}

	elseif textnr == 28 then return {enabled=true, silent=false, text="Crash: Disarming", soundfile=""}
	elseif textnr == 29 then return {enabled=true, silent=false, text="Parachute: Released!", soundfile=""}
	elseif textnr == 30 then return {enabled=true, silent=false, text="Parachute: Too Low", soundfile=""}
	
	elseif textnr == 31 then return {enabled=true, silent=false, text="EKF variance", soundfile=""}
	
	elseif textnr == 32 then return {enabled=true, silent=false, text="Low Battery!", soundfile=""}
	elseif textnr == 33 then return {enabled=true, silent=false, text="Lost GPS!", soundfile=""}
	
	elseif textnr == 34 then return {enabled=true, silent=false, text="Trim saved", soundfile=""}
	-- Compassmot.pde
	elseif textnr ==  35 then return {enabled=true, silent=false, text="compass disabled\n", soundfile=""}
	elseif textnr ==  36 then return {enabled=true, silent=false, text="check compass", soundfile=""}
	elseif textnr ==  37 then return {enabled=true, silent=false, text="RC not calibrated", soundfile=""}
	elseif textnr ==  38 then return {enabled=true, silent=false, text="thr not zero", soundfile=""}
	elseif textnr ==  39 then return {enabled=true, silent=false, text="Not landed", soundfile=""}
	elseif textnr ==  40 then return {enabled=true, silent=false, text="STARTING CALIBRATION", soundfile=""}
	elseif textnr ==  41 then return {enabled=true, silent=false, text="CURRENT", soundfile=""}
	elseif textnr ==  42 then return {enabled=true, silent=false, text="THROTTLE", soundfile=""}
	elseif textnr ==  43 then return {enabled=true, silent=false, text="Calibration Successful!", soundfile=""}
	elseif textnr ==  44 then return {enabled=true, silent=false, text="Failed!", soundfile=""}
  
	elseif textnr ==  45 then return {enabled=true, silent=false, text="bad rally point message ID", soundfile=""}
	elseif textnr ==  46 then return {enabled=true, silent=false, text="bad rally point message count", soundfile=""}
	elseif textnr ==  47 then return {enabled=true, silent=false, text="error setting rally point", soundfile=""}
	elseif textnr ==  48 then return {enabled=true, silent=false, text="bad rally point index", soundfile=""}
	elseif textnr ==  49 then return {enabled=true, silent=false, text="failed to set rally point", soundfile=""}
	elseif textnr ==  93 then return {enabled=false, silent=true, text="Initialising APM...", soundfile=""}
  
	elseif textnr ==  50 then return {enabled=true, silent=false, text="Erasing logs", soundfile=""}
	elseif textnr ==  51 then return {enabled=true, silent=false, text="Log erase complete", soundfile=""}
  
	elseif textnr ==  52 then return {enabled=true, silent=false, text="Motor Test: RC not calibrated", soundfile=""}
	elseif textnr ==  53 then return {enabled=true, silent=false, text="Motor Test: vehicle not landed", soundfile=""}
	elseif textnr ==  54 then return {enabled=true, silent=false, text="Motor Test: Safety Switch", soundfile=""}
  
	elseif textnr ==  55 then return {enabled=true, silent=false, text="No dataflash inserted", soundfile=""}
	elseif textnr ==  56 then return {enabled=true, silent=false, text="ERASING LOGS", soundfile=""}
	elseif textnr ==  57 then return {enabled=true, silent=false, text="Waiting for first HIL_STATE message", soundfile=""}
	elseif textnr ==  94 then return {enabled=false, silent=false, text="GROUND START", soundfile=""}
	elseif textnr ==  95 then return {enabled=true, silent=false, text="<startup_ground> GROUND START", soundfile=""}
	elseif textnr ==  96 then return {enabled=true, silent=false, text="<startup_ground> With Delay", soundfile=""}
	elseif textnr ==  61 then return {enabled=true, silent=false, text="Ready to FLY.", soundfile=""}
	elseif textnr ==  97 then return {enabled=true, silent=false, text="Beginning INS calibration; do not move plane", soundfile=""}
	elseif textnr ==  62 then return {enabled=true, silent=false, text="NO airspeed", soundfile=""}
  
	elseif textnr ==  59 then return {enabled=true, silent=false, text="command received: ", soundfile=""}
	elseif textnr ==  60 then return {enabled=true, silent=false, text="new HOME received", soundfile=""}
	
	elseif textnr ==  98 then return {enabled=true, silent=false, text="Ready to track.", soundfile=""}
	elseif textnr ==  99 then return {enabled=true, silent=false, text="Beginning INS calibration; do not move tracker", soundfile=""}

	elseif textnr ==  63 then return {enabled=true, silent=false, text="Disable fence failed (autodisable)", soundfile=""}
	elseif textnr ==  64 then return {enabled=true, silent=false, text="Fence disabled (autodisable)", soundfile=""}
  
	elseif textnr ==  65 then return {enabled=true, silent=false, text="Demo Servos!", soundfile=""}
  
	elseif textnr ==  66 then return {enabled=true, silent=false, text="Resetting prev_WP", soundfile=""}
	elseif textnr ==  67 then return {enabled=true, silent=false, text="init home", soundfile=""}
	elseif textnr ==  68 then return {enabled=true, silent=false, text="Fence enabled. (autoenabled)", soundfile=""}
	elseif textnr ==  69 then return {enabled=true, silent=false, text="verify_nav: LOITER time complete", soundfile=""}
	elseif textnr ==  70 then return {enabled=true, silent=false, text="verify_nav: LOITER orbits complete", soundfile=""}
	elseif textnr ==  71 then return {enabled=true, silent=false, text="Reached home", soundfile=""}
  
	elseif textnr ==  72 then return {enabled=true, silent=false, text="Failsafe - Short event on, ", soundfile=""}
	elseif textnr ==  73 then return {enabled=true, silent=false, text="Failsafe - Long event on, ", soundfile=""}
	elseif textnr ==  74 then return {enabled=true, silent=false, text="No GCS heartbeat.", soundfile=""}
	elseif textnr ==  75 then return {enabled=true, silent=false, text="Failsafe - Short event off", soundfile=""}

	elseif textnr ==  76 then return {enabled=true, silent=false, text="command received: ", soundfile=""}
	elseif textnr ==  77 then return {enabled=true, silent=false, text="fencing must be disabled", soundfile=""}
	elseif textnr ==  78 then return {enabled=true, silent=false, text="bad fence point", soundfile=""}
  
	elseif textnr ==  79 then return {enabled=true, silent=false, text="verify_nav: Invalid or no current Nav cmd", soundfile=""}
	elseif textnr ==  80 then return {enabled=true, silent=false, text="verify_conditon: Invalid or no current Condition cmd", soundfile=""}
	elseif textnr ==  81 then return {enabled=true, silent=false, text="Enable fence failed (cannot autoenable", soundfile=""}
 
	elseif textnr ==  82 then return {enabled=true, silent=false, text="geo-fence loaded", soundfile=""}
	elseif textnr ==  83 then return {enabled=true, silent=false, text="geo-fence setup error", soundfile=""}
	elseif textnr ==  84 then return {enabled=true, silent=false, text="geo-fence OK", soundfile=""}
	elseif textnr ==  85 then return {enabled=true, silent=false, text="geo-fence triggered", soundfile=""}
  
	elseif textnr ==  88 then return {enabled=true, silent=false, text="Reached Command", soundfile="apm_cmd_reached.wav"}
  
	elseif textnr ==  86 then return {enabled=true, silent=false, text="flight plan update rejected", soundfile="apm_flightplan_rej.wav"}
	elseif textnr ==  87 then return {enabled=true, silent=false, text="flight plan received", soundfile="apm_flightplan_upd.wav"}
	end
	return nil
end

local function newApmStatus(severity, textid)
	apm_status_message.severity = severity
	apm_status_message.id = textid
	apm_status_message.timestamp = getTime()
	local decoded = decodeApmStatusText(textid)
	if decoded ~= nil
	then
		apm_status_message.enabled=decoded.enabled
		apm_status_message.silent=decoded.silent
		apm_status_message.message=decoded.text
		apm_status_message.soundfile=decoded.soundfile
	else 
		apm_status_message.enabled=true
		apm_status_message.silent=false
		apm_status_message.message=decodeApmWarning(apm_status_message.severity)..apm_status_message.id
		apm_status_message.soundfile=""
	end
	-- Call override if defined
	if overrideApmStatusMessage ~= nil
	then
		local overridden = overrideApmStatusMessage(cloneStatusMessage(apm_status_message))
		apm_status_message.enabled = overridden.enabled
		apm_status_message.silent = overridden.silent
		apm_status_message.message = overridden.message
		apm_status_message.soundfile = overridden.soundfile
	end
	
	-- If message is enabled and we can play sound - play it
	if apm_status_message.enabled == true and playApmMessage ~= nil
	then
		playApmMessage(apm_status_message)
	end
end

local function clearApmStatus()
 apm_status_message.severity = 0
 apm_status_message.id = 0
 apm_status_message.timestamp = 0
 apm_status_message.message = ""
 apm_status_message.enabled = false
 apm_status_message.silent = true
 apm_status_message.soundfile = ""
end

local function cloneStatusMessage()
	local returnvalue = {
		timestamp = apm_status_message.timestamp, 
		id = apm_status_message.id,
		message = apm_status_message.message, 
		severity = apm_status_message.severity,
		silent = apm_status_message.silent,
		enabled = apm_status_message.enabled,
		soundfile = apm_status_message.soundfile}
	return returnvalue
end

function getApmActiveStatus()
	if isApmActiveStatus() == false
	then 
		return nil
	end
	local returnvalue = cloneStatusMessage()
	return returnvalue
end

function getApmActiveStatusSeverity()
	if isApmActiveStatus() == false
	then 
		return ""
	end
	return decodeApmWarning(apm_status_message.severity)
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
		if status_severity ~= apm_status_message.severity or status_textnr ~= apm_status_message.id
		then
			newApmStatus(status_severity, status_textnr)
		end
	end
	if apm_status_message.timestamp > 0 and (apm_status_message.timestamp + 250) < getTime()
	then
		clearApmStatus()
	end

	-- Calculate return value (armed)
	local armd = 0
	if getApmArmed() == true
	then
		armd = 1024
	else
		armd = 0
	end	
	return armd
end  

return {init=init, run=run_func, output=outputs}