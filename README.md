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

Scripts
Arducopter_Status

ApmTelem.lua:
This is a mixer script thats configures A2 for usage as hdop. It also publishes a set of methods used by other scripts.

ApmSounds.lua: 
This is a mixer script that announces changes in flightmode. Some flightmodes (auto-modes) will have be repeated at a given intervall. 


Lua telemetry screens
telem1.lua: 
Shows status of different parameters.

telem2.lua:
Shows a log with received status messages from ardupilot. 
