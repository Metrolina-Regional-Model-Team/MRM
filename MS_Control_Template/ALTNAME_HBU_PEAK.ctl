TITLE				            Metrolina HBU PEAK Mode Choice

PROJECT_DIRECTORY	            ALT_DIR
NUMBER_OF_THREADS	            1													
									
TRIP_TABLE_FILE                 TripTables\HBU_PEAK_TRIPS.mtx		
TRIP_TABLE_FORMAT    			TRANSCAD                    		
SKIM_FILE_1				        AutoSkims\SPMAT_auto.mtx                		//---- Peak SOV, HOV2 and HOV3+ Skims ----
SKIM_FORMAT                     TRANSCAD                                		   
SKIM_FILE_2     		        Skims\TR_NonMotorized.MTX               		// ----Walk/Bike skims ----
SKIM_FORMAT                     TRANSCAD
SKIM_FILE_3     		        Skims\PK_WKTRAN_SKIMS.MTX               		// ----Peak walk access skims ----
SKIM_FORMAT                     TRANSCAD
SKIM_FILE_4     		        Skims\PK_DRVTRAN_SKIMS.MTX              		//---- Peak Drive access skims ----
SKIM_FORMAT                     TRANSCAD                                		   
SKIM_FILE_5						Skims\PK_DROPTRAN_SKIMS.MTX             		//---- Peak DropOff access skims ----
SKIM_FORMAT                     TRANSCAD                                		

ZONE_FILE				        TAZ_ATYPE.ASC									
ZONE_FORMAT           	        TRANSCAD:TEXT
                                
NEW_TRIP_TABLE_FILE			    ModeSplit\HBU_PEAK_MS.mtx
NEW_TRIP_TABLE_FORMAT     	    TRANSCAD
SELECT_TRIP_TABLES              HBU_PEAK						//---- Cores in Trip Tables ----

MODE_CONSTANT_FILE	            ModeSplit\INPUTS\HBU_PEAK_Constant.txt			
MODE_BIAS_FILE	            	ModeSplit\INPUTS\HBU_PEAK_Bias.txt
MODE_CHOICE_SCRIPT	            ModeSplit\INPUTS\Mode_Choice_Script.txt		
                                
SEGMENT_MAP_FILE	            ModeSplit\INPUTS\Controls\Segment_Map.txt	
ORIGIN_MAP_FIELD	            CBD_FLAG
DESTINATION_MAP_FIELD	        CBD_FLAG

####CALIBRATION_TARGET_FILE			ModeSplit\INPUTS\Targets\HBU_Target_PEAK.txt
####CALIBRATION_SCALING_FACTOR		1.0
####MAX_CALIBRATION_ITERATIONS		30
####CALIBRATION_EXIT_RMSE		    0.1
####NEW_MODE_CONSTANT_FILE			ModeSplit\Results\HBU_PEAK_Constant_New.txt						
####NEW_CALIBRATION_DATA_FILE	    ModeSplit\Results\HBU_PEAK_Data.txt							
####ADJUST_FIRST_MODE_CONSTANTS 	FALSE
##REPORT_AFTER_ITERATIONS			3

TRIP_PURPOSE_LABEL	            Home-Based University
TRIP_PURPOSE_NUMBER	            2														//---- HBW = 1, HBU = 2, HBO = 3, NHB = 4 ----
TRIP_TIME_PERIOD	            1														//---- PEAK=1, OFFPEAK=2 ----

##SELECT_ORIGIN_ZONES				10251
##SELECT_DESTINATION_ZONES		10821

PRIMARY_MODE_CHOICE	            AUTO, TRANSIT, WALKBIKE
MODE_CHOICE_NEST_1	            AUTO = SOV, HOV
MODE_CHOICE_NEST_2	            HOV = POOL2, POOL3
MODE_CHOICE_NEST_3	            TRANSIT = WALKTRAN, DRIVETRAN, DROPTRAN  
MODE_CHOICE_NEST_4	            WALKTRAN = WALKPREM, WALKBUS 			
MODE_CHOICE_NEST_5	            DRIVETRAN = DRIVEPREM, DRIVEBUS 		
MODE_CHOICE_NEST_6	            DROPTRAN = DROPPREM, DROPBUS 			
MODE_CHOICE_NEST_7	            WALKBIKE = WALK, BIKE
 					
NESTING_COEFFICIENT_1	       0.655
NESTING_COEFFICIENT_2	       0.458
NESTING_COEFFICIENT_3	       0.655
NESTING_COEFFICIENT_4	       0.458
NESTING_COEFFICIENT_5	       0.458
NESTING_COEFFICIENT_6	       0.458
NESTING_COEFFICIENT_7	       0.655

MODEL_NAMES_1                  HBU_PEAK                             

VEHICLE_TIME_VALUES_1	       -0.02202
WALK_TIME_VALUES_1		       -0.05680
DRIVE_ACCESS_VALUES_1	       -0.02202
WAIT_TIME_VALUES_1		       -0.03303
TRANSFER_TIME_VALUES_1	       -0.04404
PENALTY_TIME_VALUES_1	       -0.02202
COST_VALUES_1                  -0.00329 
USER_VALUES_1                  -0.03290 
DIFFERENCE_VALUES_1	           -0.01542  

MODE_ACCESS_MARKET_1	        SOV, POOL2, POOL3, DRIVEBUS, DRIVEPREM, DROPBUS, DROPPREM, WALKBUS, WALKPREM, WALK, BIKE		
MODE_ACCESS_MARKET_2	        SOV, POOL2, POOL3, DRIVEBUS, DRIVEPREM, DROPBUS, DROPPREM								
MODE_ACCESS_MARKET_3	        SOV, POOL2, POOL3 													

ACCESS_MARKET_NAME_1			Can Walk to Transit at the Origin and Destination
ACCESS_MARKET_NAME_2			Must Drive at the Origin and Can Walk to Transit the Destination
ACCESS_MARKET_NAME_3			Must Drive

NEW_TABLE_MODES_1	            SOV = Drive Alone
NEW_TABLE_MODES_2	            POOL2 = Carpool 2
NEW_TABLE_MODES_3	            POOL3 = Carpool 3
NEW_TABLE_MODES_4	            WALKPREM = Wk-Premium
NEW_TABLE_MODES_5	            WALKBUS = Wk-Bus
NEW_TABLE_MODES_6	            DRIVEPREM = Dr-Premium
NEW_TABLE_MODES_7	            DRIVEBUS = Dr-Bus
NEW_TABLE_MODES_8	            DROPPREM = DropOff-Premium
NEW_TABLE_MODES_9	            DROPBUS = DropOff-Bus
NEW_TABLE_MODES_10				WALK = Walk	
NEW_TABLE_MODES_11				BIKE = Bike	

NEW_MODE_SUMMARY_FILE           ModeSplit\Results\ALTNAME_HBU_PEAK_Summary.txt
NEW_MARKET_SEGMENT_FILE         ModeSplit\Results\ALTNAME_HBU_PEAK_Segment.txt
##NEW_MODE_SEGMENT_FILE           ModeSplit\Results\HBU_Mode_Seg.txt
##NEW_FTA_SUMMIT_FILE		      ModeSplit\Results\HBU_Summit.bin
NEW_PRODUCTION_FILE		        ModeSplit\Results\ALTNAME_HBU_PEAK_Productions.txt
NEW_ATTRACTION_FILE		        ModeSplit\Results\ALTNAME_HBU_PEAK_Attractions.txt
                             
MODECHOICE_REPORT_1   MODE_CHOICE_SCRIPT
MODECHOICE_REPORT_2	MARKET_SEGMENT_REPORT
MODECHOICE_REPORT_3	MODE_SUMMARY_REPORT
##MODECHOICE_REPORT_4	CALIBRATION_REPORT
##MODECHOICE_REPORT_5	TARGET_DATA_REPORT
MODECHOICE_REPORT_6	MODE_VALUE_SUMMARY
MODECHOICE_REPORT_7	SEGMENT_VALUE_SUMMARY
##MODECHOICE_REPORT_8	MODE_CHOICE_STACK
##MODECHOICE_REPORT_9	    ACCESS_MARKET_SUMMARY
##MODECHOICE_REPORT_10     LOST_TRIPS_REPORT 