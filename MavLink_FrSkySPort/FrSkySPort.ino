#include "FrSkySPort.h"

#define _FrSkySPort_Serial            Serial1
#define _FrSkySPort_C1                UART0_C1
#define _FrSkySPort_C3                UART0_C3
#define _FrSkySPort_S2                UART0_S2
#define _FrSkySPort_BAUD           57600
#define   MAX_ID_COUNT              19

short crc;                         // used for crc calc of frsky-packet
uint8_t lastRx;
uint32_t FR_ID_count = 0;
uint8_t cell_count = 0;
uint8_t latlong_flag = 0;
uint32_t latlong = 0;
uint8_t first=0;
// ***********************************************************************
void FrSkySPort_Init(void)  {
      _FrSkySPort_Serial.begin(_FrSkySPort_BAUD);
      _FrSkySPort_C3 = 0x10;            // Tx invert
      _FrSkySPort_C1= 0xA0;            // Single wire mode
      _FrSkySPort_S2 = 0x10;           // Rx Invert
      
}

// ***********************************************************************
void FrSkySPort_Process(void) {
	uint8_t data = 0;
        uint32_t temp=0;
	uint8_t offset;
        while ( _FrSkySPort_Serial.available()) 
          {
	  data =  _FrSkySPort_Serial.read();
          if (lastRx == START_STOP && ((data == SENSOR_ID1) || (data == SENSOR_ID2) || (data == SENSOR_ID3)  || (data == SENSOR_ID4))) 
            {
             
              switch(FR_ID_count) {
                 case 0:
                   if(ap_fixtype==3) {
                     FrSkySPort_SendPackage(FR_ID_SPEED,ap_groundspeed *20 );  // from GPS converted to km/h
                    }
                   break;
                 case 1:
                   FrSkySPort_SendPackage(FR_ID_RPM,ap_throttle * 2);   //  * 2 if number of blades on Taranis is set to 2
                   break;
                case 2:
                   FrSkySPort_SendPackage(FR_ID_CURRENT,ap_current_battery / 10); 
                   break; 
               case 3:        // Sends the altitude value from barometer, first sent value used as zero altitude
                  FrSkySPort_SendPackage(FR_ID_ALTITUDE,ap_bar_altitude);   // from barometer, 100 = 1m
                  break;       
                case 4:        // Sends the ap_longitude value, setting bit 31 high
                   if(ap_fixtype==3) {
                       if(ap_longitude < 0)
                           latlong=((abs(ap_longitude)/100)*6)  | 0xC0000000;
                           else
                           latlong=((abs(ap_longitude)/100)*6)  | 0x80000000;
                       FrSkySPort_SendPackage(FR_ID_LATLONG,latlong);
                       }
                   break;
                 case 5:        // Sends the ap_latitude value, setting bit 31 low  
                     if(ap_fixtype==3) {
                         if(ap_latitude < 0 )
                             latlong=((abs(ap_latitude)/100)*6) | 0x40000000;
                             else
                             latlong=((abs(ap_latitude)/100)*6);
                         FrSkySPort_SendPackage(FR_ID_LATLONG,latlong);
                         }
                    break;  
                 case 6:        // Sends the compass heading
                   FrSkySPort_SendPackage(FR_ID_HEADING,ap_heading * 100);   // 10000 = 100 deg
                   break;    
                 case 7:        // Sends the analog value from input A0 on Teensy 3.1
                    FrSkySPort_SendPackage(FR_ID_ADC2,adc2);                  
                    break;       
                 case 8:        // First 2 cells
                       temp=((ap_voltage_battery/(ap_cell_count * 2)) & 0xFFF);
                       FrSkySPort_SendPackage(FR_ID_CELLS,(temp << 20) | (temp << 8));          // Battery cell 0,1
                       break;
                  case 9:    // Optional 3 and 4 Cells
                      if(ap_cell_count > 2) {
                          offset = ap_cell_count > 3 ? 0x02: 0x01;
                          temp=((ap_voltage_battery/(ap_cell_count * 2)) & 0xFFF);
                          FrSkySPort_SendPackage(FR_ID_CELLS,(temp << 20) | (temp << 8) | offset);  // Battery cell 2,3
                          }
                      break;
                 case 10:    // Optional 5 and 6 Cells
                      if(ap_cell_count > 4) {
                          offset = ap_cell_count > 5 ? 0x04: 0x03;
                          temp=((ap_voltage_battery/(ap_cell_count * 2)) & 0xFFF);
                          FrSkySPort_SendPackage(FR_ID_CELLS,(temp << 20) | (temp << 8) | offset);  // Battery cell 2,3
                          }
                      break;     
                 case 11:
                   FrSkySPort_SendPackage(FR_ID_ACCX,ap_accX_old - ap_accX);    
                     break;
                case 12:
                   FrSkySPort_SendPackage(FR_ID_ACCY,ap_accY_old - ap_accY); 
                   break; 
                case 13:
                   FrSkySPort_SendPackage(FR_ID_ACCZ,ap_accZ_old - ap_accZ ); 
                   break; 
                case 14:        // Sends voltage as a VFAS value
                   FrSkySPort_SendPackage(FR_ID_VFAS,ap_voltage_battery/10); 
                   break;   
                case 15:
                   FrSkySPort_SendPackage(FR_ID_T1,gps_status); 
                   break; 
                case 16:
                   FrSkySPort_SendPackage(FR_ID_T2,ap_base_mode); 
                   break;
               case 17:
                   FrSkySPort_SendPackage(FR_ID_VARIO,ap_climb_rate );       // 100 = 1m/s        
                   break;
               case 18:
                   //if(ap_fixtype==3) {
                       FrSkySPort_SendPackage(FR_ID_GPS_ALT,ap_gps_altitude / 10);   // from GPS,  100=1m
                     // }
                   break;
               case 19:
                   FrSkySPort_SendPackage(FR_ID_FUEL,ap_custom_mode); 
                   break;      
                   
               }
            FR_ID_count++;
            if(FR_ID_count > MAX_ID_COUNT) FR_ID_count = 0;  
            }
          lastRx=data;
          }
}


// ***********************************************************************
void FrSkySPort_SendByte(uint8_t byte) {
	
       _FrSkySPort_Serial.write(byte);
	
        // CRC update
	crc += byte;         //0-1FF
	crc += crc >> 8;   //0-100
	crc &= 0x00ff;
	crc += crc >> 8;   //0-0FF
	crc &= 0x00ff;
}


// ***********************************************************************
void FrSkySPort_SendCrc() {
	_FrSkySPort_Serial.write(0xFF-crc);
        crc = 0;          // CRC reset
}


// ***********************************************************************
void FrSkySPort_SendPackage(uint16_t id, uint32_t value) {
             
	if(MavLink_Connected) {
            digitalWrite(led,HIGH);
            }
        _FrSkySPort_C3 |= 32;      //  Transmit direction, to S.Port
	FrSkySPort_SendByte(DATA_FRAME);
	uint8_t *bytes = (uint8_t*)&id;
	FrSkySPort_SendByte(bytes[0]);
	FrSkySPort_SendByte(bytes[1]);
	bytes = (uint8_t*)&value;
	FrSkySPort_SendByte(bytes[0]);
	FrSkySPort_SendByte(bytes[1]);
	FrSkySPort_SendByte(bytes[2]);
	FrSkySPort_SendByte(bytes[3]);
	FrSkySPort_SendCrc();
	_FrSkySPort_Serial.flush();
	_FrSkySPort_C3 ^= 32;      // Transmit direction, from S.Port

        digitalWrite(led,LOW);
        
}
