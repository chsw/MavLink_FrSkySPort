-- Set by user
local capacity_max = 4000

-- Don't change these
local API_LEVEL_MAJOR = 2
local API_LEVEL_MINOR = 1

local ApmTelem = nil
local function init()
    if getApmTelem ~= nil
	then
		ApmTelem = getApmTelem()
	end
end

local function background()

end

local function checkVersionVersion()
  if ApmTelem == nil then
	lcd.drawText(20, 25, "Please install ApmTelem.lua", 0)
	lcd.drawText(20, 35, "on the \"Custom Scripts\" page!", 0)
  elseif ApmTelem.VER_MAJOR > API_LEVEL_MAJOR then
  	lcd.drawText(10, 20, "This telemetry screen is to old for", 0)
	lcd.drawText(10, 30, "the installed version of ApmTelem.lua", 0)
	lcd.drawText(10, 40, "Please upgrade", 0)
  elseif ApmTelem.VER_MAJOR < API_LEVEL_MAJOR or ApmTelem.VER_MINOR < API_LEVEL_MINOR then
  	lcd.drawText(20, 25, "Please upgrade ApmTelem.lua", 0)
	lcd.drawText(20, 35, "on the \"Custom Scripts\" page!", 0)
  else
	return 0
  end
  return 1
end

local function run(event)
  if checkVersionVersion() > 0 then
    return
  end
  
  -- Fetch current status
  local status = ApmTelem.getActiveStatus()
  -- If we have a status - display the message
  if status ~= nil
  then
	lcd.drawText(1, 55, status.message, 0)
  -- Ohterwise show the battery gauge
  else
	  -- Battery gauge
	  local telem_mah = ApmTelem.getValueCached(218)
	  lcd.drawGauge(1, 55, 90, 8, capacity_max - telem_mah, capacity_max)
	  lcd.drawText(90+4, 55, telem_mah.."mAh", 0)
  end
 
-- Model name && status
  lcd.drawText(2,1, model.getInfo().name, MIDSIZE)
  if ApmTelem.isArmed()
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
  local gpsHdop = ApmTelem.getGpsHdop()
  if ApmTelem.getGpsLock() >= 3.0
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
  lcd.drawText(1, 15, ApmTelem.getCurrentFlightmode(), 0);
-- Line 3
  lcd.drawText(1, 25, "Speed: "..getValue("gps-speed").."km/h Heading: "..getValue("heading").."@", 0)
-- Line 4
  lcd.drawText(1, 35, "Power: "..ApmTelem.getValueActive(216).."V ("..ApmTelem.getValueActive(214).."V) "..ApmTelem.getValueActive(217).."A "..ApmTelem.getValueActive(219).."W", 0)
-- Line 5
  lcd.drawText(1, 45, "Peaks: "..ApmTelem.getValueCached(246).."V ("..ApmTelem.getValueCached(244).."V) "..ApmTelem.getValueCached(247).."A "..ApmTelem.getValueCached(248).."W", 0)
-- Right column:


-- Home position
  local relativeHeadingHome = ApmTelem.getRelativeHeadingHome()
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
