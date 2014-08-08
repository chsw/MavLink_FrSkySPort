uint16_t Volt_AverageBuffer[10]; 
uint16_t Current_AverageBuffer[10]; 

#define accBufferSize 5
int32_t accXBuffer[accBufferSize];
int32_t accYBuffer[accBufferSize];
int32_t accZBuffer[accBufferSize];
int nrSamplesX = 0;
int nrSamplesY = 0;
int nrSamplesZ = 0;

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


