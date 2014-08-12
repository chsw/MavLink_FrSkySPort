
uint16_t Volt_AverageBuffer[10]; 
uint16_t Current_AverageBuffer[10]; 

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
uint32_t currentSum = 0;
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
void storeCurrentReading(uint16_t value)
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
  uint16_t avg = currentSum / currentCount;

  currentSum = 0;
  currentCount = 0;

  return avg;
}

//returns the average of Voltage for the 10 last values  
uint32_t Get_Volt_Average(uint16_t value)  {
  uint8_t i;
  uint32_t sum=0;

  for(i=9;i>0;i--)  {
    Volt_AverageBuffer[i]=Volt_AverageBuffer[i-1];
    sum+=Volt_AverageBuffer[i];
  }
  Volt_AverageBuffer[0]=value;    
  return (sum+=value)/10;
}

//returns the average of Current for the 10 last values  
uint32_t Get_Current_Average(uint16_t value)  {
  uint8_t i;
  uint32_t sum=0;

  for(i=9;i>0;i--)  {
    Current_AverageBuffer[i]=Current_AverageBuffer[i-1];
    sum+=Current_AverageBuffer[i];
  }
  Current_AverageBuffer[0]=value;    
  return (sum+=value)/10;
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





