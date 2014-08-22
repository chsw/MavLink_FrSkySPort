local soundfile_base = "/SOUNDS/en/fm_"

local apm_active_warning = 0
local apm_active_warning_textnr = 0
local apm_active_warning_timeout = 0

local outputs = {"armd"}

local function init()
	-- Prepare a2 for hdop
	local a1t = model.getTelemetryChannel(1)
	if a1t.unit ~= 3 or a1t.range ~=1024 or a1t.offset ~=0 
	then
		a1t.unit = 3
		a1t.range = 1024
		a1t.offset = 0
		model.setTelemetryChannel(1, a1t)
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
	end
	return ""..textnr
end

function getApmActiveStatusSeverity()
	if apm_active_warning_timeout < getTime()
	then
		apm_active_warning = 0
	end
	return decodeApmWarning(apm_active_warning)
end

function getApmActiveStatusText()
	return decodeApmStatusText(apm_active_warning_textnr)
end

function getApmFlightmodeNumber()
	return getValue("fuel")
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
	return getValue("a2")*10
end 

function getApmGpsSats()
  local telem_t1 = getValue("temp1") -- Temp1
  return (telem_t1 - (telem_t1%10))/10
end

function getApmGpsLock()
  local telem_t1 = getValue("temp1") -- Temp1
  return  telem_t1%10
end

function getApmArmed()
	return getValue("temp2")%256 > 0
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
	local tmp = getApmHeadingHome() - getValue("heading")
	return (tmp +360)%360
end

local function getWarningTimeout()
	-- 2 second timeout
	return getTime() + 100*2
end

local function run_func()
	-- Handle warning messages from mavlink
	local t2 = getValue("temp2")
	local armed = t2%0x02;
	t2 = (t2-armed)/0x02;
	local status_severity = t2%0x10;
	t2 = (t2-status_severity)/0x10;
	local status_textnr = t2%0x400;
	if(status_severity > 0)
	then
		if apm_active_warning ~= status_severity and status_severity ~= 0
		then
			apm_active_warning_timeout = getWarningTimeout()
		end
		apm_active_warning = status_severity
		apm_active_warning_textnr = status_textnr
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