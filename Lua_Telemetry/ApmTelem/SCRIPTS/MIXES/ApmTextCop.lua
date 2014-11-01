local msg={}
local sound={}
msg[2]="PreArm: RC not calibrated"
msg[3]="PreArm: Baro not healthy"
msg[4]="PreArm: Alt disparity"
msg[5]="PreArm: Compass not healthy"
msg[6]="PreArm: Compass not calibrated"
msg[7]="PreArm: Compass offsets too high"
msg[8]="PreArm: Check mag field"
msg[9]="PreArm: INS not calibrated"
msg[10]="PreArm: INS not healthy"
msg[11]="PreArm: Check Board Voltage"
msg[12]="PreArm: Ch7&Ch8 Opt cannot be same"
msg[13]="PreArm: Check FS_THR_VALUE"
msg[14]="PreArm: Check ANGLE_MAX"
msg[15]="PreArm: ACRO_BAL_ROLL/PITCH"
msg[16]="PreArm: GPS Glitch"
msg[17]="PreArm: Need 3D Fix"
msg[18]="PreArm: Bad Velocity"
msg[19]="PreArm: High GPS HDOP"
msg[111]="PreArm: Accels inconsistent"
msg[112]="PreArm: Accels not healthy"
msg[113]="PreArm: Bad GPS Pos"
msg[114]="PreArm: Battery failsafe on"
msg[115]="PreArm: compasses inconsistent"
msg[116]="PreArm: Gyro cal failed"
msg[117]="PreArm: Gyros inconsistent"
msg[118]="PreArm: Gyros not healthy"
msg[119]="PreArm: Radio failsafe on"

-- Check for arm failures
msg[20]="Arm: Alt disparity"
msg[21]="Arm: Thr below FS"
msg[22]="Arm: Leaning"
msg[23]="Arm: Safety Switch"
msg[100]="Arm: Mode not armable"
msg[101]="Arm: Rotor not spinning"
msg[102]="Arm: Thr too high"

-- Check all other statuses
msg[120]="Throttle armed!"
msg[121]="Throttle disarmed!"

msg[24]="AutoTune: Started"; sound[24]="apm_autotune_start.wav"
msg[25]="AutoTune: Stopped"; sound[25]="apm_autotune_stop.wav"
msg[26]="AutoTune: Success"; sound[26]="apm_autotune_done.wav"
msg[27]="AutoTune: Failed"; sound[27]="apm_autotune_fail.wav"

msg[28]="Crash: Disarming"
msg[29]="Parachute: Released!"
msg[30]="Parachute: Too Low"

msg[31]="EKF variance"
msg[125]="DCM bad heading"

msg[32]="Low Battery!"
msg[33]="Lost GPS!"

msg[34]="Trim saved"
-- Compassmot.pde
msg[35]="compass disabled"
msg[36]="check compass"
msg[37]="RC not calibrated"
msg[38]="thr not zero"
msg[39]="Not landed"
msg[40]="STARTING CALIBRATION"
msg[41]="CURRENT"
msg[42]="THROTTLE"
msg[43]="Calibration Successful!"
msg[44]="Failed!"

msg[45]="bad rally point message ID"
msg[46]="bad rally point message count"
msg[47]="error setting rally point"
msg[48]="bad rally point index"
msg[49]="failed to set rally point"

msg[50]="Erasing logs"
msg[51]="Log erase complete"

msg[52]="Motor Test: RC not calibrated"
msg[53]="Motor Test: vehicle not landed"
msg[54]="Motor Test: Safety Switch"

msg[55]="No dataflash inserted"
msg[56]="ERASING LOGS"
msg[57]="Waiting for first HIL_STATE message"
msg[61]="Ready to FLY."
msg[97]="Beginning INS calibration; do not move plane"



msg[105]="ESC Cal: auto calibration"
msg[106]="ESC Cal: passing pilot thr to ESCs"
msg[107]="ESC Cal: push safety switch"
msg[108]="ESC Cal: restart board"

msg[88]="Reached Command"; sound[88]="apm_cmd_reached.wav"

msg[86]="flight plan update rejected"; sound[86]="apm_flightplan_rej.wav"
msg[87]="flight plan received"; sound[87]="apm_flightplan_upd.wav" 

local function ds(s)
	local t="Unknown"
	if     s==nil then return ""
	elseif s==0 then t="Emergency"
	elseif s==1 then t="Alert"
	elseif s==2 then t="Critical"
	elseif s==3 then t="Error"
	elseif s==4 then t="Warning"
	elseif s==5 then t="Notice"
	elseif s==6 then t="Info"
	elseif s==7 then t="Debug"
	end
	return t
end
local function decodeText(n)
	-- Default disabled status
	local ret = {enabled=false, silent=false, text="", soundfile=strDefault}
	-- Send nothing for disabled ids
	if n == 1  -- "ARMING MOTORS"
	or n == 89 -- "DISARMING MOTORS"
	or n == 90 -- "Calibrating barometer"
	or n == 91 -- "barometer calibration complete"
	or n == 92 -- "zero airspeed calibrated"
	or n == 94 -- "GROUND START"
	or n == 93 -- "Initialising APM..."
	or n == 95 -- "<startup_ground> GROUND START"
	or n == 96 -- "<startup_ground> With Delay"
	then
		return ret
	end
	-- Set status-message as enabled 
	ret.enabled = true
	ret.text = msg[n]

	if ret.text == nil then return nil end
--	if str.find(ret.text, "Prearm:") ~= nil then ret.sound="apm_failed_prearm.wav"
--	elseif strfind(ret.text, "Arm:") ~= nil then ret.sound="apm_failed_arm.wav"
--	else ret.sound = sound[n]
	--end

	--if true then 	return ""..n end

	return ret
end

local function df(m)
  local t="Flightmode "..m
  if     m==0 then t="Stabilize"
  elseif m==1 then t="Acro"
  elseif m==2 then t="Altitude Hold"
  elseif m==3 then t="Auto"
  elseif m==4 then t="Guided"
  elseif m==5 then t="Loiter"
  elseif m==6 then t="Return to launch"
  elseif m==7 then t="Circle"
  elseif m==9 then t="Land"
  elseif m==10 then t="Optical Flow Loiter"
  elseif m==11 then t="Drift"
  elseif m==13 then t="Sport"
  elseif m==15 then t="Autotune"
  elseif m==16 then t="Position Hold"
  end
  return t
end
local initCount = 0

function getApmTexts()
	initCount = initCount+1
	return {
	decodeStatusText=decodeText,
	decodeFlightmode=df,
	decodeSeverity=ds
	}
end
local function run()
	return 0
end
return {run=run}