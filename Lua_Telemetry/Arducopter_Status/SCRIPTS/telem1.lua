-- Set by user
local capacity_max = 4000
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

local function getFlightmodeText(mode)
  if     mode == 0  then return "Stabilize"
  elseif mode == 1  then return  "Acro"
  elseif mode == 2  then return  "Altitude Hold"
  elseif mode == 3  then return  "Auto"
  elseif mode == 4  then return  "Guided"
  elseif mode == 5  then return  "Loiter"
  elseif mode == 6  then return  "Return to launch"
  elseif mode == 7  then return  "Circle"
  elseif mode == 9  then return "Land"
  elseif mode == 10 then return "Optical Flow Loiter"
  elseif mode == 11 then return "Drift"
  elseif mode == 13 then return "Sport"
  elseif mode == 16 then return "Position Hold"
  end
  return "Unknown Flightmode"
end

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

local function background()
  playFlightmode()
end
  
local function run(event)
  playFlightmode()

-- Battery gauge
  local telem_mah = getValue("consumption")
  lcd.drawGauge(1, 55, 90, 8, capacity_max - telem_mah, capacity_max)
  lcd.drawText(90+4, 55, telem_mah.."mAh", 0)

-- Model name && status
  lcd.drawText(2,1, model.getInfo().name, MIDSIZE)
  if getValue("temp2") > 0 
  then
	lcd.drawText(lcd.getLastPos()+3, 1, "ARMED", MIDSIZE)
  else
	lcd.drawText(lcd.getLastPos()+3, 1, "SAFE", MIDSIZE)
  end
  
 -- gps status
  local telem_t1 = getValue("temp1") -- Temp1
  local telem_lock = 0
  local telem_sats = 0
	telem_lock = telem_t1%10
	telem_sats = (telem_t1 - (telem_t1%10))/10
  if telem_lock >= 3.0
  then
	lcd.drawText(lcd.getLastPos()+3, 1, "GPS: 3D", 0)
	lcd.drawText(lcd.getLastPos()+3, 1, "sat", 0)
	lcd.drawText(lcd.getLastPos()+3, 1, telem_sats, 0)
  else
	lcd.drawText(lcd.getLastPos()+3, 1, "No lock(", BLINK)
	lcd.drawText(lcd.getLastPos(), 1, telem_sats, BLINK)
	lcd.drawText(lcd.getLastPos()+2, 1, "sat)", BLINK)
  end
  lcd.drawText(120, 15, "Hdop: ", 0)
  lcd.drawNumber(lcd.getLastPos()+3, 15, getValue("a2")*10, 0+PREC2+LEFT )

-- Line 2
  lcd.drawText(1, 15, getFlightmodeText(getValue("fuel")), 0);
-- Line 3
  lcd.drawText(1, 25, "Speed: "..getValue("speed").."km/h Heading: "..getValue("heading").."@", 0)
-- Line 4
  lcd.drawText(1, 35, "Power: "..getValue("vfas").."V ("..getValue("cell-min").."V) "..getValue("current").."A "..getValue("power").."W", 0)
-- Line 5
  lcd.drawText(1, 45, "Peaks: "..getValue("vfas-min").."V ("..getValue("cell-min-min").."V) "..getValue("current-max").."A "..getValue("power-max").."W", 0)

-- Right column:
-- Timer
  local timer = model.getTimer(0)
  lcd.drawTimer(170,10, timer.value, MIDSIZE)
-- Current altitude  
  lcd.drawText(170,22, getValue("altitude") .. "m", MIDSIZE)
-- Home position
  lcd.drawText(170, 35, "To Home", SMLSIZE)
  lcd.drawText(170, 45, getValue("distance"), 0)
-- TODO heading home  
end

return { init=init, run=run, background=background}