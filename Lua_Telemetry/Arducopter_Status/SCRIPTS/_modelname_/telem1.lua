-- Set by user
local capacity_max = 4000

local function init()

end

local function background()

end


local function run(event)

  if getApmActiveStatusSeverity() ~= ""
  then
	  lcd.drawText(1, 55, getApmActiveWarnings(false), 0)
  else
	  -- Battery gauge
	  local telem_mah = getValue("consumption")
	  lcd.drawGauge(1, 55, 90, 8, capacity_max - telem_mah, capacity_max)
	  lcd.drawText(90+4, 55, telem_mah.."mAh", 0)
  end
  
    lcd.drawText(150, 55, getValue("distance").."m", 0)


-- Model name && status
  lcd.drawText(2,1, model.getInfo().name, MIDSIZE)
  if getApmArmed()
  then
	lcd.drawText(lcd.getLastPos()+3, 1, "ARMED", MIDSIZE)
  else
	lcd.drawText(lcd.getLastPos()+3, 1, "SAFE", MIDSIZE)
  end
  
 -- gps status
  local gpsString
  if getApmGpsLock() >= 3.0
  then
	gpsString = "3D GPS: "..getApmGpsHdop()
  else
	gpsString = "no GPS: "..getApmGpsHdop()
  end
  if getApmGpsHdop() <= 2.0
  then
	lcd.drawText(lcd.getLastPos()+3, 1, gpsString, 0)
  else
	lcd.drawText(lcd.getLastPos()+3, 1, gpsString, BLINK)
  end

-- Line 2
  lcd.drawText(1, 15, getApmFlightmodeText(), 0);
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
  local relativeHeadingHome = getApmHeadingHomeRelative()
  local integHead, fracHead = math.modf(relativeHeadingHome/22.5+.5)
  lcd.drawPixmap(190,42,"/BMP/arrow"..(integHead%16)..".bmp")
  lcd.drawText(150, 45, "To Home", 0)
end

return { init=init, run=run, background=background}