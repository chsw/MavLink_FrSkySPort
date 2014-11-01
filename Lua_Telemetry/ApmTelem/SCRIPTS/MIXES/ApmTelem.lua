ApmTelem_API_VER = 3

local soundfile_base = "/SOUNDS/en/fm_"

local asm = {severity=nil, id=0, timestamp = 0, message="", enabled=false, silent=true, soundfile=""}
local rpm = {last=0, blades=0, batt=0, throttle=0, roll=0, pitch=0}

local outputs = {"armd"}
local cachedValues = {}

local ApmTexts = nil

local sin=math.sin
local cos=math.cos
local rad=math.rad

local function init_func()
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
	if ApmTexts ~= nil then
		return ApmTexts.decodeSeverity(s)
	end
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

local function newApmStatus(severity, textid)
	asm.severity = severity
	asm.id = textid
	asm.timestamp = getTime()
	local d = nil
	if ApmTexts ~= nil then
		d = ApmTexts.decodeStatusText(asm.id)
	end
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
  
  --if getApmTexts ~= nil then
  if ApmTexts ~= nil then
	--return ApmTexts.decodeStatusText(73)
	return ApmTexts.decodeFlightmode(m)
  end
  return "Flightmode "..m;
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
local function getValueActive(key)
	if isTelemetryActive() == false
	then
		return "--"
	end
	return getValue(key)
end

-- Reads and caches telemetry values from Taranis. If the 
-- telemetry link is down, it returns the cached value insted of 0
local function getValueCached(key)
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
	elseif id == 4 then rpm.throttle = value/10
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
	-- Fetch text-object if its not fetched yet
	if ApmTexts == nil and getApmTexts ~= nil then
		ApmTexts = getApmTexts()
	end

	initCount = initCount+1
	return {
		VER_MAJOR=2,
		VER_MINOR=1,
		getValueCached=getValueCached,
		getValueActive=getValueActive,
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
	if s < 0 then s = nil end
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

return {init=init_func, run=run_func, output=outputs}