local function init()

end

local messages = {}
local last_message = ""


local function asTimeNumber(number)
	if number < 10
	then
		return "0"..number
	end
	return number
end

local function formatTimestamp(timestamp)
  local iDiff, fDiff = math.modf((getTime() - timestamp)/100)
  local sec = iDiff%60
  local min = (iDiff-sec)/60
  local ret = asTimeNumber(min)..":"..asTimeNumber(sec)
  return ret
end

local function handleMessage()
  -- Fetch message
  local new_message = getApmActiveWarnings(true)
  -- Check if message is stopped
  if new_message == "" and last_message ~= ""
  then
	last_message = ""
  end
  if last_message ~= new_message and new_message ~= ""
  then
    last_message = new_message
	local i = 1
    while messages[i] ~= nil 
	do
      i = i + 1
    end
	for i=i, 2, -1
	do
	  messages[i] = messages[i-1]
	end
	messages[1] = {text = new_message, timestamp = getTime() }
  end
end


local function background()
  handleMessage()
end


local function run(event)
  handleMessage()
  
  local i = 1
  local warnings_received = false
  for i=1, 10, 1
  do
	if messages[i] ~= nil
	then
		lcd.drawText(1, 1 + 8* (i-1) , formatTimestamp(messages[i].timestamp).."  "..messages[i].text, 0)
		warnings_received = true
	end
  end
  if warnings_received == false
  then
	lcd.drawFilledRectangle(10, 10, 190, 45, GREY_DEFAULT)
	lcd.drawText(40, 30, "No warnings received", 0)
  end
  
end

return { init=init, run=run, background=background}