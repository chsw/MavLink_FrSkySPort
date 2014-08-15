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

return {init=init, run=run_func}