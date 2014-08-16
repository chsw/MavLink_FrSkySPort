local soundfile_base = "/SOUNDS/en/fm_"

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

local function run_func()
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
	return getValue("temp2") > 0
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

return {init=init, run=run_func}