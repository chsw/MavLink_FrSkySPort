ApmTelem_API_VER = 3

local soundfile_base = "/SOUNDS/en/fm_"

local apm_status_message = {severity=nil, id=0, timestamp = 0, message="", enabled=false, silent=true, soundfile=""}

local outputs = {"armd"}
local cachedValues = {}

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
	if     severity == nil then return ""
	elseif severity == 0 then return "Emergency"
	elseif severity == 1 then return "Alert"
	elseif severity == 2 then return "Critical"
	elseif severity == 3 then return "Error"
	elseif severity == 4 then return "Warning"
	elseif severity == 5 then return "Notice"
	elseif severity == 6 then return "Info"
	elseif severity == 7 then return "Debug"
	end
	return "Unknown"
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

local function decodeApmStatusText(textnr)
	-- Default disabled status
	local ret = {enabled=false, silent=false, text="", soundfile=strDefault}

	-- Send nothing for disabled ids
	if textnr == 1  -- "ARMING MOTORS"
	or textnr == 89 -- "DISARMING MOTORS"
	or textnr == 90 -- "Calibrating barometer"
	or textnr == 91 -- "barometer calibration complete"
	or textnr == 92 -- "zero airspeed calibrated"
	or textnr == 94 -- "GROUND START"
	or textnr == 93 -- "Initialising APM..."
	or textnr == 95 -- "<startup_ground> GROUND START"
	or textnr == 96 -- "<startup_ground> With Delay"
	then
		return ret
	end
	-- Set status-message as enabled 
	ret.enabled = true
	-- Check for prearm failures
	if textnr == 2  then ret.text="PreArm: RC not calibrated"
	elseif textnr == 3  then ret.text="PreArm: Baro not healthy"
	elseif textnr == 4  then ret.text="PreArm: Alt disparity"
	elseif textnr == 5  then ret.text="PreArm: Compass not healthy"
	elseif textnr == 6  then ret.text="PreArm: Compass not calibrated"
	elseif textnr == 7  then ret.text="PreArm: Compass offsets too high"
	elseif textnr == 8  then ret.text="PreArm: Check mag field"
	elseif textnr == 9  then ret.text="PreArm: INS not calibrated"
	elseif textnr == 10 then ret.text="PreArm: INS not healthy"
	elseif textnr == 11 then ret.text="PreArm: Check Board Voltage"
	elseif textnr == 12 then ret.text="PreArm: Ch7&Ch8 Opt cannot be same"
	elseif textnr == 13 then ret.text="PreArm: Check FS_THR_VALUE"
	elseif textnr == 14 then ret.text="PreArm: Check ANGLE_MAX"
	elseif textnr == 15 then ret.text="PreArm: ACRO_BAL_ROLL/PITCH"
	elseif textnr == 16 then ret.text="PreArm: GPS Glitch"
	elseif textnr == 17 then ret.text="PreArm: Need 3D Fix"
	elseif textnr == 18 then ret.text="PreArm: Bad Velocity"
	elseif textnr == 19 then ret.text="PreArm: High GPS HDOP"
	elseif textnr == 111 then ret.text="PreArm: Accels inconsistent"
    elseif textnr == 112 then ret.text="PreArm: Accels not healthy"
    elseif textnr == 113 then ret.text="PreArm: Bad GPS Pos"
    elseif textnr == 114 then ret.text="PreArm: Battery failsafe on."
    elseif textnr == 115 then ret.text="PreArm: compasses inconsistent"
    elseif textnr == 116 then ret.text="PreArm: Gyro cal failed"
    elseif textnr == 117 then ret.text="PreArm: Gyros inconsistent"
    elseif textnr == 118 then ret.text="PreArm: Gyros not healthy"
    elseif textnr == 119 then ret.text="PreArm: Radio failsafe on."
	end
	-- If any prearmfailure was found - set the default soundfile and return
	if ret.text ~= "" and ret.soundfile == nil then
		ret.soundfile = "apm_failed_prearm.wav"
		return ret
	end 
	
	-- Check for arm failures
	if textnr == 20 then ret.text="Arm: Alt disparity"; ret.soundfile=strArm
	elseif textnr == 21 then ret.text="Arm: Thr below FS"; ret.soundfile=strArm
	elseif textnr == 22 then ret.text="Arm: Leaning"; ret.soundfile=strArm
	elseif textnr == 23 then ret.text="Arm: Safety Switch"; ret.soundfile=strArm
	elseif textnr == 100 then ret.text="Arm: Mode not armable"; ret.soundfile=strArm
    elseif textnr == 101 then ret.text="Arm: Rotor not spinning"; ret.soundfile=strArm
    elseif textnr == 102 then ret.text="Arm: Thr too high"; ret.soundfile=strArm
	end
	-- If any armfailure was found - set the default soundfile and return
	if ret.text ~= "" and ret.soundfile == nil then
		ret.soundfile = "apm_failed_arm.wav"
		return ret
	end 
	
	-- Check all other statuses
    if textnr == 120 then ret.text="Throttle armed!"
    elseif textnr == 121 then ret.text="Throttle disarmed!"
  
	elseif textnr == 24 then ret.text="AutoTune: Started"; ret.soundfile="apm_autotune_start.wav"
	elseif textnr == 25 then ret.text="AutoTune: Stopped"; ret.soundfile="apm_autotune_stop.wav"
	elseif textnr == 26 then ret.text="AutoTune: Success"; ret.soundfile="apm_autotune_done.wav"
	elseif textnr == 27 then ret.text="AutoTune: Failed"; ret.soundfile="apm_autotune_fail.wav"

	elseif textnr == 28 then ret.text="Crash: Disarming"
	elseif textnr == 29 then ret.text="Parachute: Released!"
	elseif textnr == 30 then ret.text="Parachute: Too Low"
	
	elseif textnr == 31 then ret.text="EKF variance"
	elseif textnr == 125 then ret.text="DCM bad heading"
	
	elseif textnr == 32 then ret.text="Low Battery!"
	elseif textnr == 33 then ret.text="Lost GPS!"
	
	elseif textnr == 34 then ret.text="Trim saved"
	-- Compassmot.pde
	elseif textnr ==  35 then ret.text="compass disabled"
	elseif textnr ==  36 then ret.text="check compass"
	elseif textnr ==  37 then ret.text="RC not calibrated"
	elseif textnr ==  38 then ret.text="thr not zero"
	elseif textnr ==  39 then ret.text="Not landed"
	elseif textnr ==  40 then ret.text="STARTING CALIBRATION"
	elseif textnr ==  41 then ret.text="CURRENT"
	elseif textnr ==  42 then ret.text="THROTTLE"
	elseif textnr ==  43 then ret.text="Calibration Successful!"
	elseif textnr ==  44 then ret.text="Failed!"
  
	elseif textnr ==  45 then ret.text="bad rally point message ID"
	elseif textnr ==  46 then ret.text="bad rally point message count"
	elseif textnr ==  47 then ret.text="error setting rally point"
	elseif textnr ==  48 then ret.text="bad rally point index"
	elseif textnr ==  49 then ret.text="failed to set rally point"
  
	elseif textnr ==  50 then ret.text="Erasing logs"
	elseif textnr ==  51 then ret.text="Log erase complete"

	elseif textnr ==  52 then ret.text="Motor Test: RC not calibrated"
	elseif textnr ==  53 then ret.text="Motor Test: vehicle not landed"
	elseif textnr ==  54 then ret.text="Motor Test: Safety Switch"

	elseif textnr ==  55 then ret.text="No dataflash inserted"
	elseif textnr ==  56 then ret.text="ERASING LOGS"
	elseif textnr ==  57 then ret.text="Waiting for first HIL_STATE message"
	elseif textnr ==  61 then ret.text="Ready to FLY."
	elseif textnr ==  97 then ret.text="Beginning INS calibration; do not move plane"
	elseif textnr ==  62 then ret.text="NO airspeed"
  
	elseif textnr ==  59 then ret.text="command received: "
	elseif textnr ==  60 then ret.text="new HOME received"
	elseif textnr ==  98 then ret.text="Ready to track."
	elseif textnr ==  99 then ret.text="Beginning INS calibration; do not move tracker"

	elseif textnr ==  63 then ret.text="Disable fence failed (autodisable)"
	elseif textnr ==  64 then ret.text="Fence disabled (autodisable)"
	elseif textnr ==  110 then ret.text="FBWA tdrag mode"
  
	elseif textnr ==  65 then ret.text="Demo Servos!"

	elseif textnr ==  66 then ret.text="Resetting prev_WP"
	elseif textnr ==  67 then ret.text="init home"
	elseif textnr ==  68 then ret.text="Fence enabled. (autoenabled)"
	elseif textnr ==  69 then ret.text="verify_nav: LOITER time complete"
	elseif textnr ==  70 then ret.text="verify_nav: LOITER orbits complete"
	elseif textnr ==  71 then ret.text="Reached home"

	elseif textnr ==  72 then ret.text="Failsafe - Short event on, "
	elseif textnr ==  73 then ret.text="Failsafe - Long event on, "
	elseif textnr ==  74 then ret.text="No GCS heartbeat."
	elseif textnr ==  75 then ret.text="Failsafe - Short event off"

	elseif textnr ==  76 then ret.text="command received: "
	elseif textnr ==  77 then ret.text="fencing must be disabled"
	elseif textnr ==  78 then ret.text="bad fence point"

	elseif textnr ==  79 then ret.text="verify_nav: Invalid or no current Nav cmd"
	elseif textnr ==  80 then ret.text="verify_conditon: Invalid or no current Condition cmd"
	elseif textnr ==  81 then ret.text="Enable fence failed (cannot autoenable"
 	elseif textnr ==  124 then ret.text="verify_conditon: Unsupported command"

	elseif textnr ==  82 then ret.text="geo-fence loaded"
	elseif textnr ==  83 then ret.text="geo-fence setup error"
	elseif textnr ==  84 then ret.text="geo-fence OK"
	elseif textnr ==  85 then ret.text="geo-fence triggered"

    elseif textnr == 103 then ret.text="AUTO triggered off"
    elseif textnr == 122 then ret.text="Triggered AUTO with pin"

    elseif textnr == 104 then ret.text="Beginning INS calibration; do not move vehicle"
    elseif textnr == 123 then ret.text="Warming up ADC..."

    elseif textnr == 105 then ret.text="ESC Cal: auto calibration"
    elseif textnr == 106 then ret.text="ESC Cal: passing pilot thr to ESCs"
    elseif textnr == 107 then ret.text="ESC Cal: push safety switch"
    elseif textnr == 108 then ret.text="ESC Cal: restart board"

	elseif textnr == 109 then ret.text="FBWA tdrag off"

	elseif textnr ==  88 then ret.text="Reached Command"; ret.soundfile="apm_cmd_reached.wav"

	elseif textnr ==  86 then ret.text="flight plan update rejected"; ret.soundfile="apm_flightplan_rej.wav"
	elseif textnr ==  87 then ret.text="flight plan received"; ret.soundfile="apm_flightplan_upd.wav"
	else
		return nil;
	end
	return ret
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
 apm_status_message.severity = nil
 apm_status_message.id = 0
 apm_status_message.timestamp = 0
 apm_status_message.message = ""
 apm_status_message.enabled = false
 apm_status_message.silent = true
 apm_status_message.soundfile = ""
end

local function isApmActiveStatus()
	if apm_status_message.timestamp > 0
	then
		return true
	end
	return false
end

local function getApmActiveStatus()
	if isApmActiveStatus() == false or apm_status_message.enabled == false 
	then 
		return nil
	end
	local returnvalue = cloneStatusMessage()
	return returnvalue
end

local function getApmActiveStatusSeverity()
	if isApmActiveStatus() == false
	then 
		return ""
	end
	return decodeApmWarning(apm_status_message.severity)
end



local function getApmFlightmodeNumber()
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

local function getApmGpsHdop()
	return getValue(203)/10 -- A2
end 

local function getApmGpsSats()
  local telem_t1 = getValue(209) -- Temp1
  return (telem_t1 - (telem_t1%10))/10
end

local function getApmGpsLock()
  local telem_t1 = getValue(209) -- Temp1
  return  telem_t1%10
end

local function getApmArmed()
	return getValue(210)%2 > 0 -- Temp2
end

-- The heading to pilot home position - relative to apm position
local function getApmHeadingHome()
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
local function getApmHeadingHomeRelative()
	local tmp = getApmHeadingHome() - getValue(223) -- Heading
	return (tmp +360)%360
end

local function getWarningTimeout()
	-- 2 second timeout
	return getTime() + 100*2
end

local function isTelemetryActive()
	return getValue(200) > 0
end
-- Returns the received telemetry value from Taranis. 
--If the telemetry link is down it returns -- instead of 0
local function getTaranisValueActive(key)
	if isTelemetryActive() == false
	then
		return "--"
	end
	return getValue(key)
end

-- Reads and caches telemetry values from Taranis. If the 
-- telemetry link is down, it returns the cached value insted of 0
local function getTaranisValueCached(key)
	local value = getValue(key)
	if value > 0 or isTelemetryActive()
	then
		cachedValues[key] = value
	end
	value = cachedValues[key]
	if value == nil then
		value = 0
	end
	return value
end

local initCount = 0

function getApmTelem()
	initCount = initCount+1
	return {
		VER_MAJOR=2,
		VER_MINOR=1,
		getValueCached=getTaranisValueCached,
		getValueActive=getTaranisValueActive,
		getGpsHdop=getApmGpsHdop,
		getGpsLock=getApmGpsLock,
		getGpsSatsCount=getApmGpsSats,
		isArmed=getApmArmed,
		getRelativeHeadingHome=getApmHeadingHomeRelative,
		isActiveStatus=isApmActiveStatus,
		getActiveStatus=getApmActiveStatus,
		getCurrentFlightmode=getApmFlightmodeText
	}
end

local function run_func()
	-- Handle warning messages from mavlink
	local t2 = getValue(210) -- Temp2
	local armed = t2%0x02;
	t2 = (t2-armed)/0x02;
	local status_severity = t2%0x10
	t2 = (t2-status_severity)/0x10
	local status_textnr = t2%0x400
	status_severity = status_severity-1
	if status_severity < 0 
	then 
		status_severity = nil
	end
	if status_severity ~= nil
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