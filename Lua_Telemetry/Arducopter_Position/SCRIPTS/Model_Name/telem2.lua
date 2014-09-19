local function init()

	for chn = 1, 3, 1 do 
	local a1t = model.getTelemetryChannel(chn)
	if a1t.unit ~= 3 or a1t.range ~=1024 or a1t.offset ~=0 
	then
		a1t.unit = 3
		a1t.range = 1024
		a1t.offset = 0
		model.setTelemetryChannel(chn, a1t)
	end
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
local altitude = getValue("altitude")
local galtitude= getValue("gps-altitude")
local gspd=getValue("gps-speed")
local vspd= getValue("vertical-speed")
local aspd=getValue("air-speed")
local hdg=getValue("heading")


--Top Screen title bar

local Title =MDL .. "       " .. "TXv:" .. TXV .. "    rssi:" .. RSSI .. "    SWR:" .. SWR

	lcd.drawScreenTitle (Title,0,0)

				lcd.drawPixmap (1, 14, "/SCRIPTS/BMP/p0.bmp")
				lcd.drawPixmap (16, 14, "/SCRIPTS/BMP/t0.bmp")
			
				lcd.drawText (1, 8, "Return to Launch", 0)
				
				


--	for i=0, 9 do
--		local angle2 = math.rad((36*i)-90)
--		local x2 = 26 * math.cos(angle2) + 80 
--		local y2 = 26 * math.sin(angle2) + 32 	
--		lcd.drawNumber(x2+4, y2-4, i, 0+SMLSIZE)
--	end

--Alt layout
	altitude=70
	lcd.drawLine (90, 15, 90, 63, SOLID, 0)
	
	if math.abs(altitude) <= 10 then 
		yinc=1
	elseif math.abs(altitude) <=30 then
		yinc=5
	else
		yinc=10
	end

	for az=3, -3, -1 do
		lcd.drawLine (88, 58-az*48/7-21+3, 92, 58-az*48/7-21+3, SOLID, 0)
		
		if az~=0 then
		
		lcd.drawNumber (75,58-az*48/7-24+3,(((math.ceil(altitude/yinc))*yinc)+az*yinc), LEFT+SMLSIZE)
		
		else
		
		lcd.drawNumber (75,58-az*48/7-24+3,(altitude+az*yinc), LEFT+SMLSIZE+INVERS)

		end
				
	end
	
	if vspd >0 then
		lcd.drawPixmap(93, 38,"/SCRIPTS/BMP/uarrow.bmp")
	else
		lcd.drawPixmap(93, 38,"/SCRIPTS/BMP/darrow.bmp")
	end



--Roll layout

	local rangle=math.rad(-48)

	local rx2=145
	local rx1=100
	local ry1=32-20*math.sin(rangle)
	local ry2=32+20*math.sin(rangle)

	lcd.drawLine (rx1,ry1-1 ,rx2, ry2-1, SOLID, 2)
	lcd.drawLine (rx1,ry1 ,rx2, ry2, SOLID, 2)
	lcd.drawLine (rx1,ry1+1 ,rx2, ry2+1, SOLID, 2)

-- Heading on HUD

	local hdg=270

	lcd.drawNumber(112, 9,hdg,LEFT+MIDSIZE)

--Pitch layout

	local pitch=5

	lcd.drawLine (153, 15, 153, 63, SOLID, 0)

	for w=6, 0, -1 do

		lcd.drawLine (151, 58-w*48/7+3, 155, 58-w*48/7+3, SOLID, 0)
		lcd.drawNumber (156,58-w*48/7, math.abs(w*15-45), LEFT+SMLSIZE)
		
	end

	--ypitch
	
		pitch=-15
	
	if math.abs(pitch)<=45 then
	
		lcd.drawPixmap (146,58-(pitch+45)*42/90,"/SCRIPTS/BMP/rarrow.bmp")
		
	end

--Speed layout

--gspd=100
local vspd=-20

lcd.drawNumber(112, 55,gspd,LEFT+SMLSIZE)

lcd.drawPixmap(lcd.getLastPos()+2, 55,"/SCRIPTS/BMP/rarrow.bmp")

lcd.drawNumber(112, 45,vspd,LEFT+SMLSIZE)

if vspd >0 then
	lcd.drawPixmap(lcd.getLastPos()+2, 45,"/SCRIPTS/BMP/uarrow.bmp")
else
	lcd.drawPixmap(lcd.getLastPos()+2, 45,"/SCRIPTS/BMP/darrow.bmp")
end

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
						

			lcd.drawPixmap(40,16,"/SCRIPTS/BMP/hud00")


end

return { run=run }