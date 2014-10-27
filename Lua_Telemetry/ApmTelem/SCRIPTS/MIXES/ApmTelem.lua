ApmTelem_API_VER = 3

local soundfile_base = "/SOUNDS/en/fm_"

local asm = {severity=nil, id=0, timestamp = 0, message="", enabled=false, silent=true, soundfile=""}
local rpm = {last=0, blades=0, batt=0, throttle=0, roll=0, pitch=0}

local outputs = {"armd"}
local cachedValues = {}

local sin=math.sin
local cos=math.cos
local rad=math.rad

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
	for i=2,3 do
	local An = model.getTelemetryChannel(i)
		if An.unit ~= 3 or An.range ~=362 or An.offset ~=-180 
		then
			An.unit = 3
			An.range = 362
			An.offset = -180
			An.alarm1 = -180
			An.alarm2 = -180
			model.setTelemetryChannel(i, An)
		end
	end
end

local function decodeSeverity(s)
	local t="Unknown"
	if     s==nil then return ""
	elseif s==0 then t="Emergency"
	elseif s==1 then t="Alert"
	elseif s==2 then t="Critical"
	elseif s==3 then t="Error"
	elseif s==4 then t="Warning"
	elseif s==5 then t="Notice"
	elseif s==6 then t="Info"
	elseif s==7 then t="Debug"
	end
	return t
end

local function cloneAsm()
	local returnvalue = {
		timestamp = asm.timestamp, 
		id = asm.id,
		message = asm.message, 
		severity = asm.severity,
		silent = asm.silent,
		enabled = asm.enabled,
		soundfile = asm.soundfile}
	return returnvalue
end

local function decodeStatusText(n)
	-- Default disabled status
	local ret = {enabled=false, silent=false, text="", soundfile=strDefault}

	-- Send nothing for disabled ids
	if n == 1  -- "ARMING MOTORS"
	or n == 89 -- "DISARMING MOTORS"
	or n == 90 -- "Calibrating barometer"
	or n == 91 -- "barometer calibration complete"
	or n == 92 -- "zero airspeed calibrated"
	or n == 94 -- "GROUND START"
	or n == 93 -- "Initialising APM..."
	or n == 95 -- "<startup_ground> GROUND START"
	or n == 96 -- "<startup_ground> With Delay"
	then
		return ret
	end
	-- Set status-message as enabled 
	ret.enabled = true
	-- Check for prearm failures
	local t = nil
	local s = nil
	if n == 2  then t="PreArm: RC not calibrated"
	elseif n == 3  then t="Baro not healthy"
	elseif n == 4  then t="Alt disparity"
	elseif n == 5  then t="Compass not healthy"
	elseif n == 6  then t="Compass not calibrated"
	elseif n == 7  then t="Compass offsets too high"
	elseif n == 8  then t="Check mag field"
	elseif n == 9  then t="INS not calibrated"
	elseif n == 10 then t="INS not healthy"
	elseif n == 11 then t="Check Board Voltage"
	elseif n == 12 then t="Ch7&Ch8 Opt cannot be same"
	elseif n == 13 then t="Check FS_THR_VALUE"
	elseif n == 14 then t="Check ANGLE_MAX"
	elseif n == 15 then t="ACRO_BAL_ROLL/PITCH"
	elseif n == 16 then t="GPS Glitch"
	elseif n == 17 then t="Need 3D Fix"
	elseif n == 18 then t="Bad Velocity"
	elseif n == 19 then t="High GPS HDOP"
	elseif n == 111 then t="Accels inconsistent"
    elseif n == 112 then t="Accels not healthy"
    elseif n == 113 then t="Bad GPS Pos"
    elseif n == 114 then t="Battery failsafe on"
    elseif n == 115 then t="compasses inconsistent"
    elseif n == 116 then t="Gyro cal failed"
    elseif n == 117 then t="Gyros inconsistent"
    elseif n == 118 then t="Gyros not healthy"
    elseif n == 119 then t="Radio failsafe on"
	end
	-- If any prearmfailure was found - set the default soundfile and return
	if ret.text ~= "" and ret.soundfile == nil then
		ret.text = "PreArm: "..t
		ret.soundfile = "apm_failed_prearm.wav"
		return ret
	end 
	
	-- Check for arm failures
	if n == 20 then t="Alt disparity"
	elseif n == 21 then t="Thr below FS"
	elseif n == 22 then t="Leaning"
	elseif n == 23 then t="Safety Switch"
	elseif n == 100 then t="Mode not armable"
    elseif n == 101 then t="Rotor not spinning"
    elseif n == 102 then t="Thr too high"
	end
	-- If any armfailure was found - set the default soundfile and return
	if t ~= "" and ret.soundfile == nil then
		ret.text = "Arm: "..t
		ret.soundfile = "apm_failed_arm.wav"
		return ret
	end 
	
	-- Check all other statuses
    if n == 120 then t="Throttle armed!"
    elseif n == 121 then t="Throttle disarmed!"
  
	elseif n == 24 then t="AutoTune: Started"; s="apm_autotune_start.wav"
	elseif n == 25 then t="AutoTune: Stopped"; s="apm_autotune_stop.wav"
	elseif n == 26 then t="AutoTune: Success"; s="apm_autotune_done.wav"
	elseif n == 27 then t="AutoTune: Failed"; s="apm_autotune_fail.wav"

	elseif n == 28 then t="Crash: Disarming"
	elseif n == 29 then t="Parachute: Released!"
	elseif n == 30 then t="Parachute: Too Low"
	
	elseif n == 31 then t="EKF variance"
	elseif n == 125 then t="DCM bad heading"
	
	elseif n == 32 then t="Low Battery!"
	elseif n == 33 then t="Lost GPS!"
	
	elseif n == 34 then t="Trim saved"
	-- Compassmot.pde
	elseif n ==  35 then t="compass disabled"
	elseif n ==  36 then t="check compass"
	elseif n ==  37 then t="RC not calibrated"
	elseif n ==  38 then t="thr not zero"
	elseif n ==  39 then t="Not landed"
	elseif n ==  40 then t="STARTING CALIBRATION"
	elseif n ==  41 then t="CURRENT"
	elseif n ==  42 then t="THROTTLE"
	elseif n ==  43 then t="Calibration Successful!"
	elseif n ==  44 then t="Failed!"
  
	elseif n ==  45 then t="bad rally point message ID"
	elseif n ==  46 then t="bad rally point message count"
	elseif n ==  47 then t="error setting rally point"
	elseif n ==  48 then t="bad rally point index"
	elseif n ==  49 then t="failed to set rally point"
  
	elseif n ==  50 then t="Erasing logs"
	elseif n ==  51 then t="Log erase complete"

	elseif n ==  52 then t="Motor Test: RC not calibrated"
	elseif n ==  53 then t="Motor Test: vehicle not landed"
	elseif n ==  54 then t="Motor Test: Safety Switch"

	elseif n ==  55 then t="No dataflash inserted"
	elseif n ==  56 then t="ERASING LOGS"
	elseif n ==  57 then t="Waiting for first HIL_STATE message"
	elseif n ==  61 then t="Ready to FLY."
	elseif n ==  97 then t="Beginning INS calibration; do not move plane"
	elseif n ==  62 then t="NO airspeed"
  
	elseif n ==  59 then t="command received: "
	elseif n ==  60 then t="new HOME received"
	elseif n ==  98 then t="Ready to track."
	elseif n ==  99 then t="Beginning INS calibration; do not move tracker"

	elseif n ==  63 then t="Disable fence failed (autodisable)"
	elseif n ==  64 then t="Fence disabled (autodisable)"
	elseif n ==  110 then t="FBWA tdrag mode"
  
	elseif n ==  65 then t="Demo Servos!"

	elseif n ==  66 then t="Resetting prev_WP"
	elseif n ==  67 then t="init home"
	elseif n ==  68 then t="Fence enabled. (autoenabled)"
	elseif n ==  69 then t="verify_nav: LOITER time complete"
	elseif n ==  70 then t="verify_nav: LOITER orbits complete"
	elseif n ==  71 then t="Reached home"

	elseif n ==  72 then t="Failsafe - Short event on, "
	elseif n ==  73 then t="Failsafe - Long event on, "
	elseif n ==  74 then t="No GCS heartbeat."
	elseif n ==  75 then t="Failsafe - Short event off"

	elseif n ==  76 then t="command received: "
	elseif n ==  77 then t="fencing must be disabled"
	elseif n ==  78 then t="bad fence point"

	elseif n ==  79 then t="verify_nav: Invalid or no current Nav cmd"
	elseif n ==  80 then t="verify_conditon: Invalid or no current Condition cmd"
	elseif n ==  81 then t="Enable fence failed (cannot autoenable"
 	elseif n ==  124 then t="verify_conditon: Unsupported command"

	elseif n ==  82 then t="geo-fence loaded"
	elseif n ==  83 then t="geo-fence setup error"
	elseif n ==  84 then t="geo-fence OK"
	elseif n ==  85 then t="geo-fence triggered"

    elseif n == 103 then t="AUTO triggered off"
    elseif n == 122 then t="Triggered AUTO with pin"

    elseif n == 104 then t="Beginning INS calibration; do not move vehicle"
    elseif n == 123 then t="Warming up ADC..."

    elseif n == 105 then t="ESC Cal: auto calibration"
    elseif n == 106 then t="ESC Cal: passing pilot thr to ESCs"
    elseif n == 107 then t="ESC Cal: push safety switch"
    elseif n == 108 then t="ESC Cal: restart board"

	elseif n == 109 then t="FBWA tdrag off"

	elseif n ==  88 then t="Reached Command"; s="apm_cmd_reached.wav"

	elseif n ==  86 then t="flight plan update rejected"; s="apm_flightplan_rej.wav"
	elseif n ==  87 then t="flight plan received"; s="apm_flightplan_upd.wav"
	else
		return nil;
	end
	ret.text = t
	ret.soundfile = s
	return ret
end

local function newApmStatus(severity, textid)
	asm.severity = severity
	asm.id = textid
	asm.timestamp = getTime()
	local d = decodeStatusText(textid)
	if d ~= nil
	then
		asm.enabled=d.enabled
		asm.silent=d.silent
		asm.message=d.text
		asm.soundfile=d.soundfile
	else 
		asm.enabled=true
		asm.silent=false
		asm.message=decodeSeverity(asm.severity)..asm.id
		asm.soundfile=""
	end
	-- Call override if defined
	if overrideApmStatusMessage ~= nil
	then
		local tmp = overrideApmStatusMessage(cloneAsm(asm))
		asm.enabled = tmp.enabled
		asm.silent = tmp.silent
		asm.message = tmp.message
		asm.soundfile = tmp.soundfile
	end
	
	-- If message is enabled and we can play sound - play it
	if asm.enabled == true and playApmMessage ~= nil
	then
		playApmMessage(asm)
	end
end

local function clearApmStatus()
 asm.severity = nil
 asm.id = 0
 asm.timestamp = 0
 asm.message = ""
 asm.enabled = false
 asm.silent = true
 asm.soundfile = ""
end

local function isApmActiveStatus()
	if asm.timestamp > 0
	then
		return true
	end
	return false
end

local function getApmActiveStatus()
	if isApmActiveStatus() == false or asm.enabled == false 
	then 
		return nil
	end
	local returnvalue = cloneAsm()
	return returnvalue
end

local function getApmActiveStatusSeverity()
	if isApmActiveStatus() == false
	then 
		return ""
	end
	return decodeSeverity(asm.severity)
end



local function getFlightmodeNr()
	return getValue(208) -- Fuel
end

function getFlightmode()
  local m = getFlightmodeNr()
  local t="Unknown Flightmode"
  if     m==0 then t="Stabilize"
  elseif m==1 then t="Acro"
  elseif m==2 then t="Altitude Hold"
  elseif m==3 then t="Auto"
  elseif m==4 then t="Guided"
  elseif m==5 then t="Loiter"
  elseif m==6 then t="Return to launch"
  elseif m==7 then t="Circle"
  elseif m==9 then t="Land"
  elseif m==10 then t="Optical Flow Loiter"
  elseif m==11 then t="Drift"
  elseif m==13 then t="Sport"
  elseif m==15 then t="Autotune"
  elseif m==16 then t="Position Hold"
  end
  return t
end

local function getApmGpsHdop()
	return getValue(203)/10 -- A2
end 

local function getGpsSats()
  local telem_t1 = getValue(209) -- Temp1
  return (telem_t1 - (telem_t1%10))/10
end

local function getGpsLock()
  local telem_t1 = getValue(209) -- Temp1
  return  telem_t1%10
end

local function isArmed()
	return getValue(210)%2 > 0 -- Temp2
end

-- The heading to pilot home position - relative to apm position
local function getApmHeadingHome()
  local pLat = getValue("pilot-latitude")
  local pLon = getValue("pilot-longitude")
  local hLat = getValue("latitude")
  local hLon = getValue("longitude")
  
  if pLat~=0 and hLat~=0 and pLon~=0 and hLon~=0 
  then 
    local z1 = sin(rad(hLon)-rad(pLon))*cos(rad(hLat))
    local z2 = cos(rad(pLat))*sin(rad(hLat))-sin(rad(pLat))*cos(rad(hLat))*cos(rad(hLon)-rad(pLon))
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

local function parseRpm(r)
	rpm.last = r
	local id = r%0x10;

	if id == 0 and r > 0 then
		rpm.blades = 0x200/r
	end

	if id==0 or rpm.blades == 0 then
		return
	end
	
	id = (r*rpm.blades)%0x10
	local value = (r*rpm.blades-id)/0x10
	if id == 2 then rpm.batt = value/10
	elseif id == 4 then rpm.throttle = value/20
	elseif id == 6 then rpm.roll = value/4 -180
	elseif id == 8 then rpm.pitch = value/4 -180
	end
end

local function getBatt()
	return rpm.batt
end

local function getThrottle()
	return rpm.throttle
end

local function getRoll()
	return rpm.roll
end

local function getPitch()
	return rpm.pitch
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
		getGpsLock=getGpsLock,
		getGpsSatsCount=getGpsSats,
		isArmed=isArmed,
		getRelativeHeadingHome=getApmHeadingHomeRelative,
		isActiveStatus=isApmActiveStatus,
		getActiveStatus=getApmActiveStatus,
		getCurrentFlightmode=getFlightmode,
		getBatt=getBatt,
		getThrottle=getThrottle,
		getRoll=getRoll,
		getPitch=getPitch
	}
end

local function run_func()
	-- Handle warning messages from mavlink
	local t2 = getValue(210) -- Temp
	t2 = (t2-(t2%0x02))/0x02;
	local s = t2%0x10
	t2 = (t2-s)/0x10
	local n = t2%0x400
	s = s-1
	if s < 0 
	then 
		s = nil
	end
	if s ~= nil
	then
		if s ~= asm.severity or n ~= asm.id
		then
			newApmStatus(s, n)
		end
	end
	if asm.timestamp > 0 and (asm.timestamp + 250) < getTime()
	then
		clearApmStatus()
	end

	local r = getValue("rpm")
	if r ~= rpm.last then
	  parseRpm(r)
	end
	
	-- Calculate return value (armed)
	local armd = 0
	if isArmed() == true
	then
		armd = 1024
	else
		armd = 0
	end	
	return armd
	
end  

return {init=init, run=run_func, output=outputs}