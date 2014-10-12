Here goes the version 0.1 of my telemetry script for Taranis X9D for APM/PixHawk Flight Controllers.

The interface between the APM/PixHawk and the FrSky X series receiver is a small Teensy 3.1 board running a custom protocol translator from Mavlink to SPort telemetry.

Almost all the parameters on the normal telemetry screens of the Taranis X9D are correct, with some exceptions (RPM and T2), that combine multiple values on a single field.

Cell ( Voltage of Cell=Cells/(Number of cells). [V]) 
Cells ( Voltage from LiPo [V] )
A2 ( HDOP value * 25 - 8 bit resolution)
A3 ( Roll angle from -Pi to +Pi radians, converted to a value between 0 and 1024)
A4 ( Pitch angle from -Pi/2 to +Pi/2 radians, converted to a value between 0 and 1024)
Alt ( Altitude from baro. [m] )
GAlt ( Altitude from GPS [m])
HDG ( Compass heading [deg]) v
Rpm ( Throttle when ARMED [%] *100 + % battery remaining as reported by Mavlink)
VSpd ( Vertical speed [m/s] )
Speed ( Ground speed from GPS, [km/h] )
T1 ( GPS status = ap_sat_visible*10) + ap_fixtype )
T2 ( Armed Status and Mavlink Messages :- 16 bit value: bit 1: armed - bit 2-5: severity +1 (0 means no message - bit 6-15: number representing a specific text)
Vfas ( same as Cells )
Longitud ( Longitud )
Latitud ( Latitud )
Dist ( Will be calculated by FrSky Taranis as the distance from first received lat/long = Home Position )
Fuel ( Current Flight Mode reported by Mavlink )
AccX ( X Axis average vibration m/s?)
AccY ( Y Axis average vibration m/s?)
AccZ ( Z Axis average vibration m/s?)

This telemetry screen tries to report the data received in a easy way. 

Due to the restricted screen space I didn't make descriptive labels on the values but tried to group them on a logical (to me) way.

Also, this script relies heavily on voice alerts and prompts.

I use a two switch combination (SWE and SWF) to change flight modes, that gives me the 6 flight modes. The combination of the 2 switches activate six Logical Switches on the Taranis - The Logical Switches MUST be L1 to L6.

I could not find a way to have the Flight Controller report the settings for some parameters, like which 6 Flight Modes are defined so the script must be updated with the Flight Mode Numbers that correspond to each Logical Switch.

But the screen deserves some explanation, so here goes:

A-Current Flight Mode Active as reported by the Flight Controller. If blinking the vehicle is not Armed.

B-Current Flight Mode Timer. Each Flight Mode has its own timer. The timer stops if the vehicle is not Armed.

C-Radio Transmitter Battery Voltage.

D-RSSI value

E-Estimated Flight Time. 

F-Available Vehicle battery capacity. 

E and F are inter related. When the vehicle is armed, the script checks the voltage and calculates the number of cells and estimates the status of the vehicle battery. This is then combined with the available capacity reported by the flight controller.
E is calculated based on the rate of decay of reported capacity.
These are highly experimental and not to be considered real, but simple estimates.

G-Actual consumed power in mAh

H-Actual power output in Watts (VxA)

I-Reported Flight Battery Voltage

J-Reported Flight Battery Current

K-Vertical Gauge that shows the actual Throttle output (not the Throttle stick position but the actual output reported by the Flight Controller)

L-Vehicle Height

M-Max Height

N-Vertical speed

O-Vertical Speed Indicator (up or down)

P-Heading

Q-Roll angle

R-Armed Time Timer - Starts and stops when the Vehicle is armed/disarmed

S-Speed

T-Pitch Indicator. When over 45 degrees the indicator is replaced by 3 up or 3 down indicators

U-GPS Indicator. Three different graphics dependent on GPS status, 3D, 2D or no status

V-HDop indicator. Blinks when over 2

W-Number of reported satellites

X-Distance to home (Distance to the point the Taranis received a good satellite fix)

Y-Heading to home (Heading to the point the Taranis received a good satellite fix)

When changing flight modes the radio says Flight Mode X engaged when the switch is moved and Flight Mode X active when the Flight Controller reports it. If there is a mismatch or the Flight Controller doesn't not report the Flight Mode as set by the switches you'll be notified.

