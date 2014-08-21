// Frsky Sensor-ID to use. 
// ID of sensor. Must be something that is polled by FrSky RX

/* These were used on v1.3 but can't match any with the current OpenTX sources
	so are being removed

#define SENSOR_ID1         0x1B		// sensor hub data id
#define SENSOR_ID2         0x0D		// sensor hub data id
#define SENSOR_ID3         0x34		// sensor hub data id
#define SENSOR_ID4         0x67		// sensor hub data id

*/

#define DATA_ID_VARIO            0x00 // 0
#define DATA_ID_FLVSS            0xA1 // 1
#define DATA_ID_FAS              0x22 // 2
#define DATA_ID_GPS              0x83 // 3
#define DATA_ID_RPM              0xE4 // 4
#define DATA_ID_SP2UH            0x45 // 5
#define DATA_ID_SP2UR            0xC6 // 6

// Frsky-specific
#define START_STOP         0x7e
#define DATA_FRAME         0x10


//Frsky DATA ID's 
#define FR_ID_SPEED        0x0830 	//GPS_SPEED_FIRST_ID
#define FR_ID_VFAS         0x0210 	//VFAS_FIRST_ID
#define FR_ID_CURRENT      0x0200 	//CURR_FIRST_ID
#define FR_ID_RPM          0x050F 	//RPM_LAST_ID
#define FR_ID_ALTITUDE     0x0100	//ALT_FIRST_ID
#define FR_ID_FUEL         0x0600	//FUEL_FIRST_ID
#define FR_ID_ADC1         0xF102   //ADC1_ID
#define FR_ID_ADC2         0xF103	//ADC2_ID
#define FR_ID_LATLONG      0x0800	//GPS_LONG_LATI_FIRST_ID
#define FR_ID_CAP_USED     0x0600	//Same as FR_ID_FUEL ? 	
#define FR_ID_CAP_USED	   0x060f	//FUEL_LAST_ID 	
#define FR_ID_VARIO        0x0110	//VARIO_FIRST_ID
#define FR_ID_CELLS        0x0300	//CELLS_FIRST_ID
#define FR_ID_CELLS_LAST   0x030F 	//CELLS_LAST_ID
#define FR_ID_HEADING      0x0840	//GPS_COURS_FIRST_ID
#define FR_ID_ACCX         0x0700	//ACCX_FIRST_ID
#define FR_ID_ACCY         0x0710	//ACCY_FIRST_ID
#define FR_ID_ACCZ         0x0720	//ACCZ_FIRST_ID
#define FR_ID_T1           0x0400	//T1_FIRST_ID
#define FR_ID_T2           0x0410	//T2_FIRST_ID
#define FR_ID_GPS_ALT      0x0820	//GPS_ALT_FIRST_ID
#define FR_ID_GPS_TIME_DATE  0x0850 //GPS_TIME_DATE_FIRST_ID
#define	FR_ID_A3		   0x0900 	//A3_FIRST_ID
#define	FR_ID_A4		   0x0910 	//A4_FIRST_ID
#define FR_ID_AIR_SPEED	   0x0a00 	//AIR_SPEED_FIRST_ID



/* The following are defined at frsky_sport.cpp but not used here

#define ALT_LAST_ID             0x010f
#define VARIO_LAST_ID           0x011f
#define CURR_LAST_ID            0x020f
#define VFAS_LAST_ID            0x021f
#define T1_LAST_ID              0x040f
#define T2_LAST_ID              0x041f
#define RPM_FIRST_ID            0x0500
#define RPM_LAST_ID             0x050f
#define ACCX_LAST_ID            0x070f
#define ACCY_LAST_ID            0x071f
#define ACCZ_LAST_ID            0x072f
#define GPS_LONG_LATI_LAST_ID   0x080f
#define GPS_ALT_LAST_ID         0x082f
#define GPS_SPEED_LAST_ID       0x083f
#define GPS_COURS_LAST_ID       0x084f
#define GPS_TIME_DATE_LAST_ID   0x085f
#define A3_LAST_ID              0x090f
#define A4_LAST_ID              0x091f
#define AIR_SPEED_LAST_ID       0x0a0f
#define RSSI_ID                 0xf101 // used by the radio system
#define BATT_ID                 0xf104 // used by the radio system
#define SWR_ID                  0xf105 // used by the radio system

*/