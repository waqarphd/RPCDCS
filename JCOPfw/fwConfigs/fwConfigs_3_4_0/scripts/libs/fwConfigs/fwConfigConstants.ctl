/**@file

This library contains constants associated with the manipulation of PVSS configs.

@par Creation Date
	20/06/2004

@par Modification History
	None
	
@par Constraints
	None

@par Usage
	Public

@par PVSS managers
	VISION, CTRL

@author 
	Oliver Holme (IT-CO)
*/


//@{
//Constant Definitions

// Config objects: location of data
unsigned fwConfigs_OBJECT_DATA_TYPE = 1;

//dpeAlertConfigObject

// Common indexes to all configs
unsigned fwConfigs_DPE_OBJECT_DPE_NAME	= 1;
unsigned fwConfigs_DPE_OBJECT_DPE_TYPE	= 2;
unsigned fwConfigs_DPE_OBJECT_TYPE		= 3;
unsigned fwConfigs_DPE_OBJECT_ACTIVE	= 4;

// Specific indexes for address
const unsigned fwPeriphAddress_DPE_OBJECT_DRIVER_NUMBER 	= 5;
const unsigned fwPeriphAddress_DPE_OBJECT_REFERENCE				= 6;
const unsigned fwPeriphAddress_DPE_OBJECT_DIRECTION				= 7;
const unsigned fwPeriphAddress_DPE_OBJECT_DATATYPE				= 8;

// OPC address object
const unsigned fwPeriphAddress_DPE_OBJECT_OPC_LOWLEVEL 			= 11;
const unsigned fwPeriphAddress_DPE_OBJECT_OPC_SUBINDEX 			= 12;
const unsigned fwPeriphAddress_DPE_OBJECT_OPC_SERVER_NAME 	= 13;
const unsigned fwPeriphAddress_DPE_OBJECT_OPC_GROUP_IN 			= 14;
const unsigned fwPeriphAddress_DPE_OBJECT_OPC_GROUP_OUT 		= 15;

// DIM address object
const unsigned fwPeriphAddress_DPE_OBJECT_DIM_CONFIG_DP	 			= 11;
const unsigned fwPeriphAddress_DPE_OBJECT_DIM_DEFAULT_VALUE 		= 12;
const unsigned fwPeriphAddress_DPE_OBJECT_DIM_TIMEOUT					= 13;
const unsigned fwPeriphAddress_DPE_OBJECT_DIM_FLAG				 			= 14;
const unsigned fwPeriphAddress_DPE_OBJECT_DIM_IMMEDIATE_UPDATE	= 15;

// Specific indexes for alerts
unsigned fwAlertConfig_DPE_OBJECT_LIMITS			= 5;
unsigned fwAlertConfig_DPE_OBJECT_CLASSES			= 6;
unsigned fwAlertConfig_DPE_OBJECT_TEXTS				= 7;
unsigned fwAlertConfig_DPE_OBJECT_PANEL				= 8;
unsigned fwAlertConfig_DPE_OBJECT_PANEL_PARAMETERS	= 9;
unsigned fwAlertConfig_DPE_OBJECT_HELP				= 10;

const int fwAlertConfig_ALERT_DP_NAME = 1;
const int fwAlertConfig_ALERT_TYPE = 2;
const int fwAlertConfig_ALERT_ACTIVE = 3;
const int fwAlertConfig_ALERT_STATE = 4;
const int fwAlertConfig_ALERT_RANGES = 5;
const int fwAlertConfig_ALERT_SUM_DP_LIST = 6;
const int fwAlertConfig_ALERT_SUM_DP_PATTERN = 7;

// Specific constants for archive
unsigned fwArchive_DPE_OBJECT_PROCEDURE 	= 5;
unsigned fwArchive_DPE_OBJECT_DEADBAND		= 6;
unsigned fwArchive_DPE_OBJECT_TIME_INTERVAL	= 7;
unsigned fwArchive_DPE_OBJECT_CLASS_NAME	= 8;

// Specific constants for DP function
unsigned fwDpFunction_DPE_OBJECT_FUNCTION 	= 5;
unsigned fwDpFunction_DPE_OBJECT_PARAMETERS	= 6;
unsigned fwDpFunction_DPE_OBJECT_GLOBALS	= 7;
				
// Specific indexes for smooth
unsigned fwSmoothing_DPE_OBJECT_PROCEDURE 		= 5;
unsigned fwSmoothing_DPE_OBJECT_DEADBAND		= 6;
unsigned fwSmoothing_DPE_OBJECT_TIME_INTERVAL	= 7;

// Specific indexes for conversion
unsigned fwConversion_DPE_OBJECT_TYPE 			= 5;
unsigned fwConversion_DPE_OBJECT_CONV_TYPE 		= 6;
unsigned fwConversion_DPE_OBJECT_ORDER 			= 7;
unsigned fwConversion_DPE_OBJECT_ARGUMENTS		= 8;

// Specific indexes for Original
const int fwOriginal_DPE_OBJECT_BIT_ACTIVE = 1;
const int fwOriginal_DPE_OBJECT_BIT_INVALID = 2;
const int fwOriginal_DPE_OBJECT_BIT_LASTVAL_ARCHIVE = 3;
const int fwOriginal_DPE_OBJECT_BIT_USER_1 = 4;
const int fwOriginal_DPE_OBJECT_BIT_USER_2 = 5;
const int fwOriginal_DPE_OBJECT_BIT_USER_3 = 6;
const int fwOriginal_DPE_OBJECT_BIT_USER_4 = 7;
const int fwOriginal_DPE_OBJECT_BIT_USER_5 = 8;
const int fwOriginal_DPE_OBJECT_BIT_USER_6 = 9;
const int fwOriginal_DPE_OBJECT_BIT_USER_7 = 10;
const int fwOriginal_DPE_OBJECT_BIT_USER_8 = 11;

//Strings for controlling mode of setting original configs
const string fwOriginal_SET_NONE		 								= "NONE";
const string fwOriginal_SET_ALL		 									= "VALUE_VARIABLE_BITS_USER_BITS";
const string fwOriginal_SET_VALUE 									= "VALUE";
const string fwOriginal_SET_VARIABLE_BITS 					= "VARIABLE_BITS";
const string fwOriginal_SET_USER_BITS 							= "USER_BITS";
const string fwOriginal_SET_VALUE_AND_USER_BITS			= "VALUE_USER_BITS";
const string fwOriginal_SET_VALUE_AND_VARIABLE_BITS = "VALUE_VARIABLE_BITS";
const string fwOriginal_SET_VARIABLE_AND_USER_BITS	= "VARIABLE_BITS_USER_BITS";

// Specific indexes for PV range
unsigned fwPvRange_DPE_OBJECT_MIN_VALUE			= 5;
unsigned fwPvRange_DPE_OBJECT_MAX_VALUE			= 6;
unsigned fwPvRange_DPE_OBJECT_NEGATE_RANGE		= 7;
unsigned fwPvRange_DPE_OBJECT_IGNORE_OUTSIDE	= 8;
unsigned fwPvRange_DPE_OBJECT_INCLUSIVE_MIN		= 9;
unsigned fwPvRange_DPE_OBJECT_INCLUSIVE_MAX		= 10;

// Specific indexes for format
unsigned fwFormat_DPE_OBJECT_FORMAT = 5;

// Specific indexes for unit
unsigned fwUnit_DPE_OBJECT_UNIT = 5;


// List of PVSS configs used in the Framework
global mapping fwConfigs_PVSS;

// Framework names for PVSS configs
global mapping fwConfigs_FW;

// Panels to edit each of the Framework configs
global mapping fwConfigs_FW_PANEL;


dyn_dyn_anytype fwAlertConfig_DPE_OBJECT_INFO;
// missing indexes for alert summary definition

const string fwConfigs_FW_ADDRESS		= "Address";
const string fwConfigs_FW_ALERT_HDL		= "Alarm";
const string fwConfigs_FW_ARCHIVE		= "Archive";
const string fwConfigs_FW_CMD_CONV		= "Command conversion";
const string fwConfigs_FW_COMMON		= "Common";
const string fwConfigs_FW_DP_FUNCT		= "DP function";
const string fwConfigs_FW_MSG_CONV		= "Message conversion";
const string fwConfigs_FW_ORIGINAL	        = "Original value";
const string fwConfigs_FW_PV_RANGE		= "PV range";
const string fwConfigs_FW_SMOOTH		= "Smooth";
const string fwConfigs_FW_FORMAT		= "Format";
const string fwConfigs_FW_UNIT			= "Unit";
const string fwConfigs_FW_GENERAL               = "General";

const string fwConfigs_PVSS_ADDRESS		= "_address";
const string fwConfigs_PVSS_ALERT_HDL	= "_alert_hdl";
const string fwConfigs_PVSS_ARCHIVE		= "_archive";
const string fwConfigs_PVSS_CMD_CONV	= "_cmd_conv";
const string fwConfigs_PVSS_COMMON		= "_common";
const string fwConfigs_PVSS_DP_FUNCT	= "_dp_fct";
const string fwConfigs_PVSS_MSG_CONV	= "_msg_conv";
const string fwConfigs_PVSS_ORIGINAL	= "_original";
const string fwConfigs_PVSS_PV_RANGE	= "_pv_range";
const string fwConfigs_PVSS_SMOOTH		= "_smooth";
const string fwConfigs_PVSS_FORMAT		= "format";
const string fwConfigs_PVSS_UNIT			= "unit";
const string fwConfigs_PVSS_GENERAL     = "_general";

const int fwConfigs_GENERAL_OPTIONS	 = 1;
const int fwConfigs_BINARY_OPTIONS	 = 2;
const int fwConfigs_ANALOG_OPTIONS	 = 3;
const int fwConfigs_NOT_SUPPORTED	 = -1;

const int fwConfigs_LOCK_MANAGER_DETAIL	= 1;
const int fwConfigs_LOCK_USER_NAME		= 2;
const int fwConfigs_LOCK_MANAGER_TYPE	= 3;
const int fwConfigs_LOCK_MANAGER_NUMBER	= 4;
const int fwConfigs_LOCK_MANAGER_SYSTEM = 5;
const int fwConfigs_LOCK_MANAGER_HOST	= 6;
const int fwConfigs_LOCK_USER_ID		= 7;
const int fwConfigs_LOCK_TYPE			= 8;

const unsigned fwConfigs_OPTIMUM_DP_SET_SIZE = 100;
const unsigned fwConfigs_OPTIMUM_DP_GET_SIZE = 100;

const string fwConfigs_SET_FAILED = "SETFAILED";
const string fwConfigs_SET_LOCKED = "SETLOCKED";

const int fwConfigs_ALERT_LIMITS_ABSOLUTE = 0;
const int fwConfigs_ALERT_LIMITS_RELATIVE = 1;
const int fwConfigs_ALERT_LIMITS_RELATIVE_PERCENTAGE = 2;

//@}

//From previous implementation....
/*fwAlertConfig_initializeObjectInfo()
{
	fwAlertConfig_DPE_OBJECT_INFO[fwAlertConfig_DPE_OBJECT_DPE_NAME][fwConfigs_OBJECT_DATA_TYPE]	= STRING_VAR;
	fwAlertConfig_DPE_OBJECT_INFO[fwAlertConfig_DPE_OBJECT_DPE_TYPE][fwConfigs_OBJECT_DATA_TYPE]	= UINT_VAR;
	fwAlertConfig_DPE_OBJECT_INFO[fwAlertConfig_DPE_OBJECT_TYPE][fwConfigs_OBJECT_DATA_TYPE] 		= UINT_VAR;
	fwAlertConfig_DPE_OBJECT_INFO[fwAlertConfig_DPE_OBJECT_ACTIVE][fwConfigs_OBJECT_DATA_TYPE]		= BOOL_VAR;
	fwAlertConfig_DPE_OBJECT_INFO[fwAlertConfig_DPE_OBJECT_LIMITS][fwConfigs_OBJECT_DATA_TYPE]		= DYN_FLOAT_VAR;
	fwAlertConfig_DPE_OBJECT_INFO[fwAlertConfig_DPE_OBJECT_CLASSES][fwConfigs_OBJECT_DATA_TYPE]		= DYN_STRING_VAR;
	fwAlertConfig_DPE_OBJECT_INFO[fwAlertConfig_DPE_OBJECT_TEXTS][fwConfigs_OBJECT_DATA_TYPE]		= DYN_STRING_VAR;
	fwAlertConfig_DPE_OBJECT_INFO[fwAlertConfig_DPE_OBJECT_PANEL][fwConfigs_OBJECT_DATA_TYPE]		= STRING_VAR;
	fwAlertConfig_DPE_OBJECT_INFO[fwAlertConfig_DPE_OBJECT_PANEL_PARAMETERS][fwConfigs_OBJECT_DATA_TYPE]	= DYN_STRING_VAR;
	fwAlertConfig_DPE_OBJECT_INFO[fwAlertConfig_DPE_OBJECT_HELP][fwConfigs_OBJECT_DATA_TYPE]		= STRING_VAR;
	
}
*/
