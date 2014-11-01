-- Don't change these
local apiMajor = 2
local apiMinor = 1

local amsg = {}
local amsgsize = 0
local lmsg = nil
local i
global_new_messages = false

local dt=lcd.drawText
local ApmTelem = nil
		
local function init()
	ApmTelem = getApmTelem()
end

local function chkVer()
	if ApmTelem == nil then
		dt(20, 25, "Please install ApmTelem.lua", 0)
		dt(20, 35, "on the \"Custom Scripts\" page!", 0)
	elseif ApmTelem.VER_MAJOR > apiMajor then
		dt(10, 20, "This telemetry screen is to old for", 0)
		dt(10, 30, "the installed version of ApmTelem.lua", 0)
		dt(10, 40, "Please upgrade", 0)
	elseif ApmTelem.VER_MAJOR < apiMajor or ApmTelem.VER_MINOR < apiMinor then
		dt(20, 25, "Please upgrade ApmTelem.lua", 0)
		dt(20, 35, "on the \"Custom Scripts\" page!", 0)
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
local function toTwoDigit(number)
	if number < 10
	then
		return "0"..number
	end
	return number
end

-- Takes a time (10 msec resolution) and formats as min:sec
local function fmtTime(timestamp)
	local iDiff, fDiff = math.modf((getTime() - timestamp)/100)
	local sec = iDiff%60
	local min = (iDiff-sec)/60
	local ret = toTwoDigit(min)..":"..toTwoDigit(sec)
	return ret
end

-- Looks for new messages and builds a list of messages
local function scanMsg()
	-- Fetch message
	local m = ApmTelem.getActiveStatus()
	if m ~= nil and (lmsg == nil or m.timestamp ~= lmsg.timestamp)
	then 
		-- If message is marked as silent - don't activte global flag
		if not m.silent
		then
			global_new_messages = true
		end
		-- Store message as last message
		lmsg = m
		amsgsize = math.max(amsgsize+1, 7)
		-- Move all stored messages back in array
		for i=amsgsize, 2, -1
		do
			amsg[i] = amsg[i-1]
		end
		-- Put the last message first
		amsg[1] = {text = m.message, timestamp = m.timestamp, severity = m.severity }
	end
end

-- Scan for messages when not visible
local function background()
	if chkVer() > 0 then return end
	scanMsg()
end

local function run(event)
	if chkVer() > 0 then return end
  
	-- Scan for new messages
	scanMsg()

	-- Reset global flag since we now have shown any new messages
	global_new_messages = false
  
	-- Loop through messages
	if amsgsize > 0 then
		for i=1, 7, 1
		do
			if amsg[i] ~= nil
			then
				lcd.drawPixmap(1, 1+8* (i-1), "/SCRIPTS/BMP/severity" .. amsg[i].severity .. ".bmp")
				dt(10, 1 + 8* (i-1) , fmtTime(amsg[i].timestamp).."  "..amsg[i].text, 0)
				empty = false
			end
		end
	-- No messages received - show text
	else
		lcd.drawFilledRectangle(10, 10, 190, 45, GREY_DEFAULT)
		dt(40, 30, "No warnings received", 0)
	end
end

return { init=init, run=run, background=background}