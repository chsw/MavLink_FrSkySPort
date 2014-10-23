-- Don't change these
local API_LEVEL_MAJOR = 2
local API_LEVEL_MINOR = 1

local messages = {}
local last_message = nil
global_new_messages = false

local ApmTelem = nil
		
local function init()
	ApmTelem = getApmTelem()
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

--function overrideApmStatusMessage(message)
--  if message.id == 93 then
--	message.message = "New Text"
--	message.soundfile = "apm_autotune_start.wav"
--	message.silent = true
--	message.enabled = true
--  end
--  return message
--end

-- Format a number to a string with 2 digits. 
local function asTimeNumber(number)
	if number < 10
	then
		return "0"..number
	end
	return number
end

-- Takes a time (10 msec resolution) and formats as min:sec
local function formatTimestamp(timestamp)
  local iDiff, fDiff = math.modf((getTime() - timestamp)/100)
  local sec = iDiff%60
  local min = (iDiff-sec)/60
  local ret = asTimeNumber(min)..":"..asTimeNumber(sec)
  return ret
end

-- Looks for new messages and builds a list of messages
local function handleMessage()
  -- Fetch message
  local message = ApmTelem.getActiveStatus()
  if message ~= nil and (last_message == nil or message.timestamp ~= last_message.timestamp)
  then 
	-- If message is marked as silent - don't activte global flag
    if message.silent == false
	then
		global_new_messages = true
	end
	-- Store message as last message
    last_message = message
	-- Search for the next free position
	local i = 1
    while messages[i] ~= nil 
	do
      i = i + 1
	  -- Limit history length
	  if i >= 20
	  then
		break
	  end
    end
	-- Move all stored messages back in array
	for i=i, 2, -1
	do
	  messages[i] = messages[i-1]
	end
	-- Put the last message first
	messages[1] = {text = message.message, timestamp = message.timestamp, severity = message.severity }

  end
end

-- Scan for messages when not visible
local function background()
  if checkVersionVersion() > 0 then
    return
  end
  handleMessage()
end


local function run(event)
  if checkVersionVersion() > 0 then
    return
  end
  
  -- Scan for new messages
  handleMessage()

  -- Reset global flag since we now have shown any new messages
  global_new_messages = false
  
  -- Loop through messages
  local i = 1
  local warnings_received = false
  for i=1, 10, 1
  do
	if messages[i] ~= nil
	then
		lcd.drawPixmap(1, 1+8* (i-1), "/SCRIPTS/BMP/severity" .. messages[i].severity .. ".bmp")
		lcd.drawText(10, 1 + 8* (i-1) , formatTimestamp(messages[i].timestamp).."  "..messages[i].text, 0)
		warnings_received = true
	end
  end
  -- No messages received - show text
  if warnings_received == false
  then
	lcd.drawFilledRectangle(10, 10, 190, 45, GREY_DEFAULT)
	lcd.drawText(40, 30, "No warnings received", 0)
  end
  
end

return { init=init, run=run, background=background}