--Auxiliary files on github under dir BMP and SOUNDS/en
-- https://github.com/lvale/MavLink_FrSkySPort/tree/DisplayAPMPosition/Lua_Telemetry/DisplayApmPosition

-- don't confuse these with Christian's files


--Landing Gear to.do - perhaps move to a Function script to activate LG automatically
--Gimbal position to.do - position reporting only

--User configurable 

			Switches ={}
			for i=1, 6 do
			    Switches[i] = {}
			    Switches[i].LogicalSwitch=99+i
			    Switches[i].FlightNumber=1
			end

			--These must be changed to correspond to what is defined as Flight Modes 1 to 6 on the APM/PixHawk.

			-- I didn't find a way to retrieve these automatically from the FC

			-- These can be set in the future by a function script. TBD

				Switches[1].FlightNumber=1 -- these correspond to the Logical Switches defined on the Radio - L1  is 1 =Stabilize
				Switches[2].FlightNumber=3 -- these correspond to the Logical Switches defined on the Radio - L2  is 3 =Altitude Hold
				Switches[3].FlightNumber=6 -- these correspond to the Logical Switches defined on the Radio - L3  is 6 =Stabilize
				Switches[4].FlightNumber=1 -- these correspond to the Logical Switches defined on the Radio - L4  is 1 =Stabilize
				Switches[5].FlightNumber=17 -- these correspond to the Logical Switches defined on the Radio - L5  is 17 =Position Hold
				Switches[6].FlightNumber=12 -- these correspond to the Logical Switches defined on the Radio - L6  is 12 =Drift





--Init Variables
	local eff=0
	local consumption_max=0
	local cell_nr=0
	local cellv=0
	local cap_est=0
	local battremaining=1
	local zerobattery=0
	local zerocap=1
	local SumFlight=0
  	local repeatplay=0
  	local SwitchFlag=0
	local lastarmed=0
	local apmarmed=0
	local LastSwitchPos=0
	local SwitchPos=0
	local FmodeNr=13 -- This is an invalid flight number when no data available
  	local Engaged=0
	local last_flight_mode = 0
	local last_flight_mode_play = 0

	--Timer 0 is time while vehicle is armed

	model.setTimer(0, {mode=0, start=0, value= 0, countdownBeep=0, minuteBeep=1, persistent=1})

	--Timer 1 is accumulated time per flight mode

	model.setTimer(1, {mode=0, start=0, value= 0, countdownBeep=0, minuteBeep=0, persistent=1})






		--Init Flight Tables
			FlightMode = {}

			for i=1, 17 do
			  
			    FlightMode[i] = {}
			    FlightMode[i].Name=""
			    FlightMode[i].SoundActive1="/SOUNDS/en/AVFM"..(i-1).."A.wav"
			    FlightMode[i].SoundActive2="/SOUNDS/en/ALFM"..(i-1).."A.wav"
			    FlightMode[i].SoundEngaged1="/SOUNDS/en/AVFM"..(i-1).."E.wav"
			    FlightMode[i].SoundEngaged2="/SOUNDS/en/ALFM"..(i-1).."E.wav"
			    FlightMode[i].Repeat=1
			    FlightMode[i].Timer=0

			end
		  
			    FlightMode[1].Name="Stabilize"
			    FlightMode[1].Repeat=300
			    FlightMode[2].Name="Acro"
			    FlightMode[2].Repeat=300
			    FlightMode[3].Name="Altitude Hold"
			    FlightMode[3].Repeat=300
			    FlightMode[4].Name="Auto"
			    FlightMode[4].Repeat=60
			    FlightMode[5].Name="Guided"
			    FlightMode[5].Repeat=60
			    FlightMode[6].Name="Loiter"
			    FlightMode[6].Repeat=300
			    FlightMode[7].Name="Return to launch"
			    FlightMode[7].Repeat=15
			    FlightMode[8].Name="Circle"
			    FlightMode[8].Repeat=300
			    FlightMode[9].Name="Invalid Mode"
			    FlightMode[9].Repeat=15
			    FlightMode[10].Name="Land"
			    FlightMode[10].Repeat=15
			    FlightMode[11].Name="Optical Loiter"
			    FlightMode[11].Repeat=300
			    FlightMode[12].Name="Drift"
			    FlightMode[12].Repeat=300
			    FlightMode[13].Name="Invalid Mode"
			    FlightMode[13].Repeat=15
			    FlightMode[14].Name="Sport"
			    FlightMode[14].Repeat=60
			    FlightMode[15].Name="Flip Mode"
			    FlightMode[15].Repeat=15
			    FlightMode[16].Name="Auto Tune"
			    FlightMode[16].Repeat=30
			    FlightMode[17].Name="Position Hold"
			    FlightMode[17].Repeat=300




		--Init Severity Tables
			Severity={}
					Severity[1]={}
					Severity[1].Name=""

				for i=2,9 do
					Severity[i]={}
					Severity[i].Name=""
					Severity[i].Sound="/SOUNDS/en/ER"..(i-2)..".wav"
				end
					Severity[2].Name="Emergency"
					Severity[3].Name="Alert"
					Severity[4].Name="Critical"
					Severity[5].Name="Error"
					Severity[6].Name="Warning"
					Severity[7].Name="Notice"
					Severity[8].Name="Info"
					Severity[9].Name="Debug"

			local apm_status_message = {severity = 0, textnr = 0, timestamp=0}

--Init A registers
			local A2 = model.getTelemetryChannel(1)
				if A2 .unit ~= 3 or A2 .range ~=1024 or A2 .offset ~=0 
					then
						A2.unit = 3
						A2.range = 1024
						A2.offset = 0
						model.setTelemetryChannel(1, A2)
				end
				
			local A3 = model.getTelemetryChannel(2)
				if A3.unit ~= 3 or A3.range ~=362 or A3.offset ~=-180 
					then
						A3.unit = 3
						A3.range = 362
						A3.offset = -180
						A3.alarm1 = -180
						A3.alarm2 = -180
						model.setTelemetryChannel(2, A3)
				end
			
			local A4 = model.getTelemetryChannel(3)
				if A4.unit ~= 3 or A4.range ~=362 or A4.offset ~=-180 
					then
						A4.unit = 3
						A4.range = 362
						A4.offset = -180
						A4.alarm1 = -180
						A4.alarm2 = -180
						model.setTelemetryChannel(3, A4)
				end

--Aux Display functions and panels

	local function vgauge(vx, vy, vw, vh, value, vmax, look, max, min)  -- look use GREY_DEFAULT+FILL_WHITE
		if value>vmax then
			vmax=value
		end
		local vh1 =(vh * value / vmax)
		local vy1 = (vy + (vh - vh1))
		lcd.drawFilledRectangle(vx, vy1, vw, vh1, look)
		lcd.drawRectangle(vx, vy ,vw, vh,SOLID,2)

		if max~=0 and max<=vmax then
		vh1 =(vh * max / vmax)
		vy1 = (vy + (vh - vh1))	
		lcd.drawPixmap (vx+vw,vy1-3,"/SCRIPTS/BMP/larrow.bmp")
		
		--lcd.drawLine(vx,vy1,vx+vw,vy1,SOLID,2)
		
		end

		if min~=0 then
		local vh1 =(vh * min / vmax)
		vy1 = (vy + (vh - vh1))	
		lcd.drawPixmap (vx+vw,vy1-3,"/SCRIPTS/BMP/larrow.bmp")	
		--lcd.drawLine(vx,vy1,vx+vw,vy1,SOLID,2)
		end
	end

	local function round(num, idp)
		local mult = 10^(idp or 0)
		return math.floor(num * mult + 0.5) / mult
	end

					local function gpspanel()

						telem_t1 = getValue(209) -- Temp1
						telem_lock = 0
						telem_sats = 0
						telem_lock = telem_t1%10
						telem_sats = (telem_t1 - (telem_t1%10))/10


					  	if telem_lock >= 3 then
					  	lcd.drawPixmap (171, 9, "/SCRIPTS/BMP/gps.bmp")
						lcd.drawText (192, 21, telem_sats.."sat", 0)
					 	 
					  	elseif telem_lock>1 then
						lcd.drawPixmap (171, 9, "/SCRIPTS/BMP/gps2.bmp")
						lcd.drawText (192, 21, telem_sats.."sat", 0)
						else
						lcd.drawPixmap (171, 9, "/SCRIPTS/BMP/gps0.bmp")						
						lcd.drawText (192, 21, "----", 0)
						end
					  
					  	hdop=round(getValue(203))
						if hdop <20 then
						lcd.drawNumber (196, 9, hdop, 0+PREC1+LEFT+MIDSIZE )
						else
						lcd.drawNumber (196, 9, hdop, 0+PREC1+LEFT+BLINK+INVERS+MIDSIZE)
						end

								pilotlat = getValue("pilot-latitude")
								pilotlon = getValue("pilot-longitude")
								curlat = getValue("latitude")
								curlon = getValue("longitude")

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
										local integHead=round(headtoh/45)
										lcd.drawPixmap(171,33,"/SCRIPTS/BMP/"..integHead..".bmp")
										
									end
								else
									headfromh = 0
									headtoh = 0

									lcd.drawPixmap(171,33,"/SCRIPTS/BMP/NOGPS.bmp")

								end
									lcd.drawText(180, 29, getValue("distance").."m", 0)
					end

					local function speedpanel()

						lcd.drawTimer(106,42,model.getTimer(0).value,MIDSIZE)

						lcd.drawNumber(132, 53,getValue(211),MIDSIZE)

						lcd.drawPixmap(lcd.getLastPos()+2, 55,"/SCRIPTS/BMP/rarrow.bmp")
					end

					local function pitchpanel()


						lcd.drawLine (153, 15, 153, 63, SOLID, 0)

						for w=6, 0, -1 do

							lcd.drawLine (151, 58-w*48/7+3, 155, 58-w*48/7+3, SOLID, 0)
							lcd.drawNumber (156,58-w*48/7, math.abs(w*15-45), LEFT+SMLSIZE)
							
						end

						--ypitch

						local pitch=getValue(205)*10
						if math.abs(pitch)<=45 then
						
							lcd.drawPixmap (146,58-(pitch+45)*42/90,"/SCRIPTS/BMP/rarrow.bmp")

						elseif pitch<45 then lcd.drawPixmap(144,39,"/SCRIPTS/BMP/darrow3.bmp")
						elseif pitch>45 then lcd.drawPixmap(144,17,"/SCRIPTS/BMP/uarrow3.bmp")


						end
					end

					local function altpanel()

						altitude = getValue(206)
						galtitude= getValue(213)
						aspd=getValue(225)
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
						
						--Alt max
						lcd.drawText(92,10,getValue(237),SMLSIZE)
					end

					local function vspeedpanel()

						vspd= getValue(224)					
						if vspd >0 then
							lcd.drawPixmap(93, 38,"/SCRIPTS/BMP/uarrow.bmp")
						else
							lcd.drawPixmap(93, 38,"/SCRIPTS/BMP/darrow.bmp")
						end

						lcd.drawNumber(94, 30,vspd,LEFT+SMLSIZE)
					end

					local function rollpanel()

						local rangle=math.rad(getValue(204)*10)
						local rx2=145
						local rx1=100
						local ry1=round(32-20*math.sin(rangle))
						local ry2=round(32+20*math.sin(rangle))

						lcd.drawLine (rx1,ry1-1 ,rx2, ry2-1, SOLID, 2)
						lcd.drawLine (rx1,ry1 ,rx2, ry2, SOLID, 2)
						lcd.drawLine (rx1,ry1+1 ,rx2, ry2+1, SOLID, 2)
					end

					local function headingpanel()

						lcd.drawNumber(129, 9,getValue(223),MIDSIZE)
						lcd.drawText(lcd.getLastPos(),9,"\64",MIDSIZE)
					end

					local function toppanel()

						lcd.drawFilledRectangle(0, 0, 212, 9, 0)

						if apmarmed==1 then
							lcd.drawText(1, 0, (FlightMode [FmodeNr].Name), INVERS)
							else
							lcd.drawText(1, 0, (FlightMode [FmodeNr].Name), INVERS+BLINK)
						end
						lcd.drawText(94, 0, " T:", INVERS)
						lcd.drawTimer(lcd.getLastPos(),0,model.getTimer(1).value,INVERS)

						lcd.drawText(134, 0, "TX:"..getValue(189).."v", INVERS)

						lcd.drawText(172, 0, "rssi:" .. getValue(200), INVERS)
					end

	local function powerpanel()
						--Used on power panel -- still to check if all needed

					local power=getValue(207) 
					local battremaining = (power%100)*cap_est/zerocap  --battery % remaining reported adjusted to initial reading
					local throttle = (power-(power%100))/100 --throttle reported
					local tension=getValue(216) --
					local current=getValue(217) ---
					local consumption=getValue(218)--
					local watts=getValue(219) ---
					local tension_min=getValue(246) --
					local current_max=getValue(247) ---
					local watts_max=getValue(248)  ---

					if battremaining~=consumption_max then
					eff=battremaining*model.getTimer(0).value/(zerocap-battremaining)
					consumption_max=battremaining
					end					
					if (eff-model.getTimer(0).value)<0 then
						lcd.drawText(0,9,"calc",MIDSIZE+BLINK)
					else
					lcd.drawTimer(0,9,eff-model.getTimer(0).value,MIDSIZE)
					end
					lcd.drawNumber(lcd.getLastPos()+25,9,round(battremaining),MIDSIZE)
					lcd.drawText(lcd.getLastPos(),9,"%",MIDSIZE)

					lcd.drawNumber(28,21,consumption,MIDSIZE)
					local xposCons=lcd.getLastPos()
					lcd.drawText(xposCons,20,"m",SMLSIZE)
					lcd.drawText(xposCons,26,"Ah",SMLSIZE)

					lcd.drawNumber(57,21,watts,MIDSIZE)
					lcd.drawText(lcd.getLastPos(),22,"W",0)

					lcd.drawNumber(28,32,tension*10,MIDSIZE+PREC1)
					lcd.drawText(lcd.getLastPos(),33,"V",0)

					lcd.drawNumber(57,32,current*10,MIDSIZE+PREC1)
					lcd.drawText(lcd.getLastPos(),33,"A",0)

					vgauge(64,19,8,45,throttle,100,GREY_DEFAULT+FILL_WHITE,0,0)
					lcd.drawText(65,11,"T%",SMLSIZE)
	end

--Battery status

	local function batstatus()
			cell_nr = math.ceil(getValue(216) / 4.2)
			cellv=(getValue(216)/ cell_nr)
			cap_est=0


			if cellv>=4.2 then cap_est=100
				elseif cellv>=4.00 then cap_est=84
				elseif cellv>=3.96 then cap_est=77
				elseif cellv>=3.93 then cap_est=70
				elseif cellv>=3.90 then cap_est=63
				elseif cellv>=3.86 then cap_est=56
				elseif cellv>=3.83 then cap_est=48
				elseif cellv>=3.80 then cap_est=43
				elseif cellv>=3.76 then cap_est=35
				elseif cellv>=3.73 then cap_est=27
				elseif cellv>=3.70 then cap_est=21
				elseif cellv>=3.67 then cap_est=14
					cap_est=0
				end
		return cellv, cell_nr, cap_est
	end
	
--APM Armed and errors		
			local function armed_status()
			
				local t2 = getValue(210)
				apmarmed = t2%0x02;

				if lastarmed~=apmarmed then
					lastarmed=apmarmed
						if apmarmed==1 then
							model.setTimer(0,{ mode=1, start=0, value= SumFlight, countdownBeep=0, minuteBeep=1, persistent=1 })
							model.setTimer(1,{ mode=1, start=0, value= FlightMode[FmodeNr].Timer, countdownBeep=0, minuteBeep=0, persistent=1 })
							playFile("SOUNDS/en/SARM.wav")
							playFile(FlightMode[FmodeNr].SoundActive1)
							
							batstatus()
							playNumber(cell_nr, 0, 0)
							playFile("/SOUNDS/en/battc.wav")
							playFile("/SOUNDS/en/att.wav")
							playNumber(cap_est,8,0)
							zerobattery=cap_est
							zerocap=getValue(207)%100
							
							else
							
							SumFlight = model.getTimer(0).value
							model.setTimer(0,{ mode=0, start=0, value= model.getTimer(0).value, countdownBeep=0, minuteBeep=1, persistent=1 })
							
							FlightMode[FmodeNr].Timer=model.getTimer(1).value
							model.setTimer(1,{ mode=0, start=0, value= FlightMode[FmodeNr].Timer, countdownBeep=0, minuteBeep=0, persistent=1 })

							playFile("SOUNDS/en/SDISAR.wav")
						end
					
				end

				t2 = (t2-apmarmed)/0x02;
				status_severity = t2%0x10;
				
				t2 = (t2-status_severity)/0x10;
				status_textnr = t2%0x400;
				
					if(status_severity > 0)
						then
							if status_severity ~= apm_status_message.severity or status_textnr ~= apm_status_message.textnr then
								apm_status_message.severity = status_severity
								apm_status_message.textnr = status_textnr
								apm_status_message.timestamp = getTime()
							end
					end

					if apm_status_message.timestamp > 0 and (apm_status_message.timestamp + 2*100) < getTime() then
						apm_status_message.severity = 0
						apm_status_message.textnr = 0
						apm_status_message.timestamp = 0
					end
			end

--FlightModes

			local function Flight_modes()
				FmodeNr=getValue(208)+1
				if FmodeNr<1 or FmodeNr>17 then
					FmodeNr=13
				end


				if FmodeNr~=last_flight_mode then

					playFile(FlightMode[FmodeNr].SoundActive1)
					last_flight_mode_play=(100*FlightMode[FmodeNr].Repeat)+getTime()

					if apmarmed==1 then

					FlightMode[last_flight_mode].Timer=model.getTimer(1).value
					model.setTimer(1,{ mode=1, start=0, value= FlightMode[FmodeNr].Timer, countdownBeep=0, minuteBeep=0, persistent=1 })

					else
					model.setTimer(1,{ mode=0, start=0, value= FlightMode[FmodeNr].Timer, countdownBeep=0, minuteBeep=0, persistent=1 })
					end
 					
 					last_flight_mode=FmodeNr


				elseif getTime()>last_flight_mode_play
						then
						playFile(FlightMode[FmodeNr].SoundActive1)
						last_flight_mode_play=(100*FlightMode[FmodeNr].Repeat)+getTime()
				end
			end

--Engaged Flight Mode

			local function Flight_switches()

				for i=1,6 do
					if getValue(i+99)>0 then
						SwitchPos=i+99
						Engaged=Switches[i].FlightNumber
						break
					end
				end

				if SwitchPos~=LastSwitchPos then
					playFile(FlightMode[Engaged].SoundEngaged1)
					LastSwitchPos=SwitchPos

					repeatplay=300+getTime()
					SwitchFlag=5

				elseif FmodeNr~=Engaged and repeatplay<getTime() and SwitchFlag>0 then
					playFile("/SOUNDS/en/FSMM.wav")

					SwitchFlag=SwitchFlag-1
					repeatplay=SwitchFlag*200+getTime()

					
				end
			end
	
--Background
	local function background()

		armed_status()

		Flight_modes()

		Flight_switches()

	end

--Display
		local function run(event)

					--lcd.lock()
					lcd.clear()

					armed_status()

					Flight_modes()

					Flight_switches()

					toppanel()

					powerpanel()

					altpanel()

					vspeedpanel()

					rollpanel()

					headingpanel()

					pitchpanel()

					speedpanel()

					gpspanel()
											
		end

		return {run=run, background=background}