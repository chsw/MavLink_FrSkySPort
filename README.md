MavLink_FrSkySPort
==================
This is a modified version of the mavlink to frsky s.port code found here:
http://diydrones.com/forum/topics/amp-to-frsky-x8r-sport-converter

It's based on the official 1.3 version.

Changes:

- Acc X/Y/Z reports the average vibrations (difference between max/min) instead of actual accelerometer values.
- Reports gps-speed instead of hud-speed.
- Change how the code responds to tx telemetry requests. This fixes the missing cell/cells in the latest open-tx versions.
- Updated the cell detection to minimize the risk of detecting to many cells (unless the battery is low upon connection)
  and changing the cell count inflight when the battery voltage drops.
- Changed the averaging for voltage/current to be more accurate to the voltage/current fluctuations. Hoping of increasing the 
  accurasy of the mAh-counter. Use FAS as both voltage/current source.
- Delays sending the voltage/current until the voltage reading through mavlink has stabilized. This should minimize the false 
  low battery-warnings upon model powerup.