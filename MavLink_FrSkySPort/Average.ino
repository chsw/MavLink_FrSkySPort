// Used to calculate an average vibration level using accelerometers
#define accBufferSize 5
int32_t accXBuffer[accBufferSize];
int32_t accYBuffer[accBufferSize];
int32_t accZBuffer[accBufferSize];
int nrSamplesX = 0;
int nrSamplesY = 0;
int nrSamplesZ = 0;

// Used to calculate the average voltage/current between each frksy poll-request.
// A bit overkill since we most of the time only receive one sample from mavlink between each poll.
// voltageMinimum is used to report the lowest value received through mavlink between each poll frsky poll-request.
int32_t currentSum = 0;
uint16_t currentCount = 0;
uint32_t voltageSum = 0;
uint16_t voltageCount = 0;
uint16_t voltageMinimum = 0;

// Don't respond to FAS/FLVSS request until it looks like the voltage received through mavlink as stabilized.
// This is a try to eliminate most of the low voltage alarms recevied upon model power up.
boolean voltageStabilized = false;
uint16_t voltageLast = 0;

// Store a voltage reading received through mavlink
void storeVoltageReading(uint16_t value)
{
  // Try to determine if the voltage has stabilized
  if(voltageStabilized == false)
  {
    // if we have a mavlink voltage, and its less then 0.5V higher then the last sample we got
    if(value > 3000 && (value - voltageLast)<500)
    {
      // The voltage seems to have stabilized
      voltageStabilized = true;
    }
    else
    {
      // Reported voltage seems to still increase. Save this sample
      voltageLast = value; 
    }
    return;
  }

  // Store this reading so we can return the average if we get multiple readings between the polls
  voltageSum += value;
  voltageCount++;
  // Update the minimu voltage if this is lover
  if(voltageMinimum < 1 || value < voltageMinimum)
    voltageMinimum = value;
}

// Store a current reading received through mavlink
void storeCurrentReading(int16_t value)
{
  // Only store if the voltage seems to have stabilized
  if(!voltageStabilized)
    return;
  currentSum += value;
  currentCount++;
}

// Calculates and returns the average voltage value received through mavlink since the last time this function was called.
// After the function is called the average is cleared.
// Return 0 if we have no voltage reading
uint16_t readAndResetAverageVoltage()
{
  if(voltageCount < 1)
    return 0;
    
#ifdef DEBUG_AVERAGE_VOLTAGE
  debugSerial.print(millis());
  debugSerial.print("\tNumber of samples for voltage average: ");
  debugSerial.print(voltageCount);
  debugSerial.println();      
#endif

  uint16_t avg = voltageSum / voltageCount;

  voltageSum = 0;
  voltageCount = 0;

  return avg;
}

// Return the lowest voltage reading received through mavlink since the last time function was called.
// After the function is called the value is cleard.
// Return 0 if we have no new reading
uint16_t readAndResetMinimumVoltage()
{
  uint16_t tmp = voltageMinimum;
  voltageMinimum = 0;
  return tmp;  
}

// Calculates and returns the average current value received through mavlink since the last time this function was called.
// After the function is called the average is cleared.
// Return 0 if we have no voltage reading
uint16_t readAndResetAverageCurrent()
{
  if(currentCount < 1)
    return 0;
  
  uint16_t avg = currentSum >= 0 ? currentSum / currentCount : 0;

  currentSum = 0;
  currentCount = 0;

  return avg;
}

void storeAccX(int32_t value)
{
  if(nrSamplesX < accBufferSize)
  {
    nrSamplesX++;
  }
  uint8_t i;
  for(i=accBufferSize-1;i>0;i--)
  {
    accXBuffer[i]=accXBuffer[i-1];
  }
  accXBuffer[0] = value;
}
void storeAccY(int32_t value)
{
  if(nrSamplesY < accBufferSize)
  {
    nrSamplesY++;
  }
  uint8_t i;
  for(i=accBufferSize-1;i>0;i--)
  {
    accYBuffer[i]=accYBuffer[i-1];
  }
  accYBuffer[0] = value;
}
void storeAccZ(int32_t value)
{
  if(nrSamplesZ < accBufferSize)
  {
    nrSamplesZ++;
  }
  uint8_t i;
  for(i=accBufferSize-1;i>0;i--)
  {
    accZBuffer[i]=accZBuffer[i-1];
  }
  accZBuffer[0] = value;
}

int32_t fetchAccX()
{
  int32_t min=32000;
  int32_t max=-32000;
  for(int i=0; i<nrSamplesX; i++)
  {
    if(accXBuffer[i]<min)
    {
      min = accXBuffer[i];
    }
    if(accXBuffer[i]>max)
    {
      max = accXBuffer[i];
    }
  }
  return max - min;
}

int32_t fetchAccY()
{
  int32_t min=32000;
  int32_t max=-32000;
  for(int i=0; i<nrSamplesY; i++)
  {
    if(accYBuffer[i]<min)
    {
      min = accYBuffer[i];
    }
    if(accYBuffer[i]>max)
    {
      max = accYBuffer[i];
    }
  }
  return max - min;
}

int32_t fetchAccZ()
{
  int32_t min=32000;
  int32_t max=-32000;
  for(int i=0; i<nrSamplesZ; i++)
  {
    if(accZBuffer[i]<min)
    {
      min = accZBuffer[i];
    }
    if(accZBuffer[i]>max)
    {
      max = accZBuffer[i];
    }
  }
  return max - min;
}


void parseStatusText(int32_t severity, String text)
{
  uint16_t textId = 0;
  
  // Texts with textId = 0 will be ignored

  // motors.pde
       if(text == "ARMING MOTORS")                                         textId = 0;
  else if(text == "PreArm: RC not calibrated")                             textId = 2;
  else if(text == "PreArm: Baro not healthy")                              textId = 3;
  else if(text == "PreArm: Alt disparity")                                 textId = 4;
  else if(text == "PreArm: Compass not healthy")                           textId = 5;
  else if(text == "PreArm: Compass not calibrated")                        textId = 6;
  else if(text == "PreArm: Compass offsets too high")                      textId = 7;
  else if(text == "PreArm: Check mag field")                               textId = 8;
  else if(text == "PreArm: INS not calibrated")                            textId = 9;
  else if(text == "PreArm: INS not healthy")                               textId = 10;
  else if(text == "PreArm: Check Board Voltage")                           textId = 11;
  else if(text == "PreArm: Ch7&Ch8 Opt cannot be same")                    textId = 12;
  else if(text == "PreArm: Check FS_THR_VALUE")                            textId = 13;
  else if(text == "PreArm: Check ANGLE_MAX")                               textId = 14;
  else if(text == "PreArm: ACRO_BAL_ROLL/PITCH")                           textId = 15;
  else if(text == "PreArm: GPS Glitch")                                    textId = 16;
  else if(text == "PreArm: Need 3D Fix")                                   textId = 17;
  else if(text == "PreArm: Bad Velocity")                                  textId = 18;
  else if(text == "PreArm: High GPS HDOP")                                 textId = 19;
  else if(text == "Arm: Alt disparity")                                    textId = 20;
  else if(text == "Arm: Thr below FS")                                     textId = 21;
  else if(text == "Arm: Leaning")                                          textId = 22;
  else if(text == "Arm: Safety Switch")                                    textId = 23;
  else if(text == "DISARMING MOTORS")                                      textId = 0;
  
  // plane/copter sensors.pde
  else if(text == "Calibrating barometer")                                 textId = 0;
  else if(text == "barometer calibration complete")                        textId = 0;
  else if(text == "zero airspeed calibrated")                              textId = 0;
  
  // control_autotune.pde
  else if(text == "AutoTune: Started")                                     textId = 24;
  else if(text == "AutoTune: Stopped")                                     textId = 25;
  else if(text == "AutoTune: Success")                                     textId = 26;
  else if(text == "AutoTune: Failed")                                      textId = 27;
  
  // crash_check.pde
  else if(text == "Crash: Disarming")                                      textId = 28;
  else if(text == "Parachute: Released!")                                  textId = 29;
  else if(text == "Parachute: Too Low")                                    textId = 30;

  // efk_check.pde
  else if(text == "EKF variance")                                          textId = 31;

  // events.pde
  else if(text == "Low Battery!")                                          textId = 32;
  else if(text == "Lost GPS!")                                             textId = 33;
  
  // switches.pde
  else if(text == "Trim saved")                                            textId = 34;
  
  // Compassmot.pde
  else if(text == "compass disabled\n")                                    textId = 35;
  else if(text == "check compass")                                         textId = 36;
  else if(text == "RC not calibrated")                                     textId = 37;
  else if(text == "thr not zero")                                          textId = 38;
  else if(text == "Not landed")                                            textId = 39;
  else if(text == "STARTING CALIBRATION")                                  textId = 40;
  else if(text == "CURRENT")                                               textId = 41;
  else if(text == "THROTTLE")                                              textId = 42;
  else if(text == "Calibration Successful!")                               textId = 43;
  else if(text == "Failed!")                                               textId = 44;
  
  // copter/plane GCS_Mavlink.pde  
  else if(text == "bad rally point message ID")                            textId = 45;
  else if(text == "bad rally point message count")                         textId = 46;
  else if(text == "error setting rally point")                             textId = 47;
  else if(text == "bad rally point index")                                 textId = 48;
  else if(text == "failed to set rally point")                             textId = 49;
  else if(text == "Initialising APM...")                                   textId = 0;
  
  // copter/plane Log.pde
  else if(text.startsWith("Erasing logs"))                                 textId = 50;
  else if(text.startsWith("Log erase complete"))                           textId = 51;
  
  // motor_test.pde
  else if(text == "Motor Test: RC not calibrated")                         textId = 52;
  else if(text == "Motor Test: vehicle not landed")                        textId = 53;
  else if(text == "Motor Test: Safety Switch")                             textId = 54;
  
  // plane/copter system.pde
  else if(text == "No dataflash inserted")                                 textId = 55;
  else if(text == "ERASING LOGS")                                          textId = 56;
  else if(text == "Waiting for first HIL_STATE message")                   textId = 57;
  else if(text == "GROUND START")                                          textId = 0;
  else if(text == "<startup_ground> GROUND START")                         textId = 0;
  else if(text == "<startup_ground> With Delay")                           textId = 0;
  else if(text.endsWith("Ready to FLY."))                                  textId = 61;
  else if(text == "Beginning INS calibration; do not move plane")          textId = 0;
  else if(text == "NO airspeed")                                           textId = 62;
  
  // AntennaTracker GCS_Mavnlink.pde
  else if(text == "command received: ")                                    textId = 59;
  else if(text == "new HOME received")                                     textId = 60;

  // AntennaTracker system.pde
  else if(text.endsWith("Ready to track.  "))                              textId = 0;
  else if(text == "Beginning INS calibration; do not move tracker")        textId = 0;
  
  // Arduplane.pde
  else if(text == "Disable fence failed (autodisable)")                    textId = 63;
  else if(text == "Fence disabled (autodisable)")                          textId = 64;
  
  // Arduplane attitude.pde
  else if(text == "Demo Servos!")                                          textId = 65;
  
  // Arduplane commands.pde
  else if(text == "Resetting prev_WP")                                     textId = 66;
  else if(text == "init home")                                             textId = 67;
  else if(text == "Fence enabled. (autoenabled)")                          textId = 68;
  else if(text == "verify_nav: LOITER time complete")                      textId = 69;
  else if(text == "verify_nav: LOITER orbits complete")                    textId = 70;
  else if(text == "Reached home")                                          textId = 71;
  
  // Arduplane events.pde
  else if(text == "Failsafe - Short event on, ")                           textId = 72;
  else if(text == "Failsafe - Long event on, ")                            textId = 73;
  else if(text == "No GCS heartbeat.")                                     textId = 74;
  else if(text == "Failsafe - Short event off")                            textId = 75;

  // Arduplane GCS_Mavlink.pde
  else if(text == "command received: ")                                    textId = 76;
  else if(text == "fencing must be disabled")                              textId = 77;
  else if(text == "bad fence point")                                       textId = 78;
  
  // Arduplane commands_logic.pde
  else if(text == "verify_nav: Invalid or no current Nav cmd")             textId = 79;
  else if(text == "verify_conditon: Invalid or no current Condition cmd")  textId = 80;
  else if(text == "Enable fence failed (cannot autoenable")                textId = 81;
  
  // Arduplane geofence.pde
  else if(text == "geo-fence loaded")                                      textId = 82;
  else if(text == "geo-fence setup error")                                 textId = 83;
  else if(text == "geo-fence OK")                                          textId = 84;
  else if(text == "geo-fence triggered")                                   textId = 85;
  
  // Libraries GCS_Common.cpp
  else if(text == "flight plan update rejected")                           textId = 86;
  else if(text == "flight plan received")                                  textId = 87;
  
  // System version (received when connecting Mission planner)
  else if(text.startsWith("ArduCopter V"))                                 textId = 0;
  else if(text.startsWith("ArduPlane V"))                                  textId = 0;
  else if(text.startsWith("PX4: "))                                        textId = 0;

  // Unknown text (textId = 1023)
  else                                                                     textId = 1023;
    ap_status_text_id = textId;

#ifdef DEBUG_PARSE_STATUS_TEXT
  debugSerial.print(millis());
  debugSerial.print("\tparseStatusText. severity: ");
  debugSerial.print(severity);
  debugSerial.print(", text: \"");
  debugSerial.print(text);
  debugSerial.print("\" textId: ");
  debugSerial.print(textId);
  debugSerial.println();
#endif
}



