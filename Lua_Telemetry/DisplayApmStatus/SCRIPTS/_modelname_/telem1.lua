-- Set by user
local capacity_max = 4000

-- Don't change these
local API_LEVEL_NEED = 2
local function init()

end

local function background()

end


local function run(event)
  
  if ApmTelem_API_VER == nil or ApmTelem_API_VER < API_LEVEL_NEED
  then
	if ApmTelem_API_VER == nil 
	then
		lcd.drawText(20, 20, "Please install mixerscript", 0)
	else
		lcd.drawText(20, 20, "Wrong version. Please update", 0)
	end
	lcd.drawText(20, 30, "ApmTelem.lua", 0)
    lcd.drawText(20, 40, "on the \"Custom Scripts\" page!", 0)
	return
  end

  -- Fetch current status
  local status = getApmActiveStatus()
  -- If we have a status - display the message
  if status ~= nil
  then
	lcd.drawText(1, 55, status.message, 0)
  -- Ohterwise show the battery gauge
  else
	  -- Battery gauge
	  local telem_mah = getValue("consumption")
	  lcd.drawGauge(1, 55, 90, 8, capacity_max - telem_mah, capacity_max)
	  lcd.drawText(90+4, 55, telem_mah.."mAh", 0)
  end
 
-- Model name && status
  lcd.drawText(2,1, model.getInfo().name, MIDSIZE)
  if getApmArmed()
  then
	lcd.drawText(lcd.getLastPos()+3, 1, "ARMED", MIDSIZE)
  else
	lcd.drawText(lcd.getLastPos()+3, 1, "SAFE", MIDSIZE)
  end

  -- Timer
  local timer = model.getTimer(0)
  local pos = 155 --lcd.getLastPos()+10
  lcd.drawText(pos, 1, "Timer", SMLSIZE) 
  lcd.drawTimer(pos,7, timer.value, MIDSIZE)  
-- Current altitude  
  lcd.drawText(145, 30, getValue("altitude") .. "m", MIDSIZE)
  
 -- gps status
  local gpsHdop = getApmGpsHdop()
  if getApmGpsLock() >= 3.0
  then
	lcd.drawPixmap(190, 1, "/SCRIPTS/BMP/gps3d.bmp")
  else
	lcd.drawPixmap(190, 1, "/SCRIPTS/BMP/gpsno.bmp")
  end
  if gpsHdop ==  0.0 then
	lcd.drawText(190, 30, "---", BLINK)
  elseif gpsHdop == 10.24 then
	lcd.drawText(190, 30, "HIGH", BLINK)
  elseif gpsHdop <= 2.0
  then
	lcd.drawText(190, 30, gpsHdop, 0)
  else
	lcd.drawText(190, 30,  gpsHdop, BLINK)
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


-- Home position
  local relativeHeadingHome = getApmHeadingHomeRelative()
  local integHead, fracHead = math.modf(relativeHeadingHome/22.5+.5)
  lcd.drawPixmap(190,42,"/SCRIPTS/BMP/arrow"..(integHead%16)..".bmp")
  lcd.drawText(145, 45, "To Home", 0)
  lcd.drawText(145, 55, getValue("distance").."m", 0)

-- Inform if there are unread messages
  if global_new_messages ~= nil and global_new_messages == true
  then
    lcd.drawText(145, 20, "New Msg", BLINK)
  end
end

return { init=init, run=run, background=background}