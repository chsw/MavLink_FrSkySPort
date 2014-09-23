MavLink_FrSkySPort
==================
This is a modified version of the mavlink to frsky s.port code found here:
http://diydrones.com/forum/topics/amp-to-frsky-x8r-sport-converter

It's based on the official 1.3 version.

Changes:

- Acc X/Y/Z reports the average vibrations (difference between max/min) instead of actual accelerometer values.
- Reports gps-speed instead of hud-speed.
- Change how the code responds to tx telemetry requests. This fixes the missing cell/cells in the latest open-tx versions.
- Updated the cell detection to minimize the risk of detecting to many cells (unless the battery is low upon connection) and changing the cell count inflight when the battery voltage drops.
- Changed the averaging for voltage/current to be more accurate to the voltage/current fluctuations. Hoping of increasing the accuracy of the mAh-counter. Use FAS as both voltage/current source.
- Delays sending the voltage/current until the voltage reading through mavlink has stabilized. This should minimize the false low battery-warnings upon model powerup.
- GPS hdop on A2
- Temp2 contains both arming status (armed if the value is uneven) and status message number if the text received through mavlink was recognized.

Lua scripts.

Make sure your transmitter has lua enabled firmware. If you use OpenTX Companion, open Settings->Settings->Radio Profile and make you have lua selected under build options.

Mixer scripts. These scripts need to be activated under the "Custom scripts" page on your transmitter.

ApmTelem:
This script configures A2, A3 and A4 for hdop, roll and pitch. It also exports arming-status as an output. This status can be used to for example control a timer.
It also publishes a set of methods that can be used by other scripts.

ApmSounds:
This script announces (plays a soundfile) the current flightmode reported by the flight controller. Some flightmodes (auto-modes) will be repeated at a given intervall. 


Lua telemetry screens:


DisplayApmStatus, telem1.lua: 
Shows status of different parameters received through mavlink. 
Some of this parameters are current flightmode, gps status, battery status, current consumption and power usage.
It also displays (briefly) any status messages received from ardupilot.

DisplayApmStatus, telem2.lua:
Shows a log with received status messages from ardupilot. 
