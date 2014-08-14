local function init()
	local a1t = model.getTelemetryChannel(1)
	if a1t.unit ~= 3 or a1t.range ~=1024 or a1t.offset ~=0 
	then
		a1t.unit = 3
		a1t.range = 1024
		a1t.offset = 0
		model.setTelemetryChannel(1, a1t)
	end
end

local function run(event)


local TXV = getValue("tx-voltage")
local RSSI = getValue("rssi")
local SWR = getValue("swr")
local MDL = model.getInfo().name
local pilotlat = getValue("pilot-latitude")
local pilotlon = getValue("pilot-longitude")
local curlat = getValue("latitude")
local curlon = getValue("longitude")
local hdop = getValue("a2")

local Title =MDL .. "       " .. "TXv:" .. TXV .. "    rssi:" .. RSSI .. "    SWR:" .. SWR

	lcd.drawScreenTitle (Title,0,0)

-- gps status
  local telem_t1 = getValue("temp1") -- Temp1
  local telem_lock = 0
  local telem_sats = 0
	telem_lock = telem_t1%10
	telem_sats = (telem_t1 - (telem_t1%10))/10

  	if telem_lock >= 3 then
  	lcd.drawPixmap (171, 8, "/SCRIPTS/BMP/gps.bmp")
	lcd.drawText (192, 20, telem_sats.."sat", 0)
 	 
  	elseif telem_lock>1 then
	lcd.drawPixmap (171, 8, "/SCRIPTS/BMP/gps2.bmp")
	lcd.drawText (192, 20, telem_sats.."sat", 0)
	else
	lcd.drawPixmap (171, 8, "/SCRIPTS/BMP/gps0.bmp")
	lcd.drawText (192, 20, "----", 0)
	end
  
	if hdop <2 then
	lcd.drawNumber (196, 8, hdop, 0+PREC1+LEFT+MIDSIZE )
	else
	lcd.drawNumber (196, 8, hdop, 0+PREC1+LEFT+BLINK+INVERS+MIDSIZE)
	end



		if pilotlat~=0 and curlat~=0 and pilotlon~=0 and curlon~=0 then 

			z1 = math.sin(math.rad(curlon) - math.rad(pilotlon)) * math.cos(math.rad(curlat))
			z2 = math.cos(math.rad(pilotlat)) * math.sin(math.rad(curlat)) - math.sin(math.rad(pilotlat)) * math.cos(math.rad(curlat)) * math.cos(math.rad(curlon) - math.rad(pilotlon))
			headfromh = math.deg(math.atan2(z1, z2))
			if headfromh < 0 then
				headfromh=headfromh+360
			end

			headtoh = headfromh-180

			if headtoh < 0 then
				headtoh = headtoh+360				
				local integHead, fracHead = math.modf(headtoh/45+.5)
				lcd.drawPixmap(171,34,"/SCRIPTS/BMP/"..integHead..".bmp")
				
			end
		else
			headfromh = 0
			headtoh = 0

			lcd.drawPixmap(171,34,"/SCRIPTS/BMP/NOGPS.bmp")

		end
			lcd.drawText(180, 28, getValue("distance").."m", 0)
						




end

return { run=run }