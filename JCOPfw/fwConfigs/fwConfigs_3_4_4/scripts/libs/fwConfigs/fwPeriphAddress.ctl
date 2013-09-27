/**@file

This library contains function associated with the address config.
Functions are provided for getting the current settings, deleting the config
and setting the config

@par Creation Date
	28/03/2000

@par Modification History

  12/08/11 Marco Boccioli
  - @sav{85462}: Functions *_setMany and *_getMany with parameters as reference.
  - @sav{85466}: Improve performance for fwPeriphAddress_getMany().
 
	27/04/10	Frederic Bernard (EN-ICE) update Exception management in fwPeriphAddress_setModbus()

	15/01/04	Oliver Holme (IT-CO) Modified library to match functionality of other config libs
	
@par Constraints
	WARNING: the functions use the dpGet or dpSetWait, problems may occur when using these functions 
    		in a working function called by a PVSS (dpConnect) or in a calling function 

@par Usage
	Public

@par PVSS managers
	VISION, CTRL

@author 
	Geraldine Thomas, Oliver Holme (IT-CO)
*/

//@{ 
// constants definition
const string fwPeriphAddress_TYPE_OPC = "OPC";
const string fwPeriphAddress_TYPE_OPCCLIENT = "OPCCLIENT";
const string fwPeriphAddress_TYPE_OPCSERVER = "OPCSERVER";
const string fwPeriphAddress_TYPE_DIM = "DIM";
const string fwPeriphAddress_TYPE_DIMCLIENT = "DIMCLIENT";
const string fwPeriphAddress_TYPE_DIMSERVER = "DIMSERVER";
const string fwPeriphAddress_TYPE_MODBUS = "MODBUS";
const string fwPeriphAddress_TYPE_DIP = "DIP";
const string fwPeriphAddress_TYPE_NONE = "None";

const unsigned fwPeriphAddress_TYPE 			= 1;
const unsigned fwPeriphAddress_DRIVER_NUMBER 	= 2;
const unsigned fwPeriphAddress_REFERENCE		= 3;
const unsigned fwPeriphAddress_DIRECTION		= 4;
const unsigned fwPeriphAddress_DATATYPE			= 5;
const unsigned fwPeriphAddress_ACTIVE 			= 6;

//replace by _REFERENCE but kept for compatibility
const unsigned fwPeriphAddress_ROOT_NAME		= 3;

// Address parameters
const unsigned FW_PARAMETER_FIELD_COMMUNICATION 	= 1;	// Type of communication. ex : "MODBUS"
const unsigned FW_PARAMETER_FIELD_DRIVER 			= 2;	// Driver number
const unsigned FW_PARAMETER_FIELD_ADDRESS 			= 3;	// Address reference
const unsigned FW_PARAMETER_FIELD_MODE 				= 4;	// Mode
const unsigned FW_PARAMETER_FIELD_DATATYPE 			= 5;	// Type of data (see constants below)
const unsigned FW_PARAMETER_FIELD_ACTIVE 			= 6;	// Is address active

const unsigned FW_PARAMETER_FIELD_LOWLEVEL 	= 11;		// Is low level config used
const unsigned FW_PARAMETER_FIELD_SUBINDEX 	= 12;		// Address subindex
const unsigned FW_PARAMETER_FIELD_START 	= 13;		// Starting time
const unsigned FW_PARAMETER_FIELD_INTERVAL 	= 14;		// Interval time
const unsigned FW_PARAMETER_FIELD_NUMBER 	= 15;		// Number of parameters

//MODBUS address object
const unsigned fwPeriphAddress_MODBUS_LOWLEVEL 		= 11;
const unsigned fwPeriphAddress_MODBUS_SUBINDEX 		= 12;
const unsigned fwPeriphAddress_MODBUS_START 		= 13;
const unsigned fwPeriphAddress_MODBUS_INTERVAL 		= 14;
const unsigned fwPeriphAddress_MODBUS_POLL_GROUP	= 15;
const unsigned fwPeriphAddress_MODBUS_OBJECT_SIZE	= 15;

// OPC address object
const unsigned fwPeriphAddress_OPC_LOWLEVEL 	= 11;
const unsigned fwPeriphAddress_OPC_SUBINDEX 	= 12;
const unsigned fwPeriphAddress_OPC_SERVER_NAME 	= 13;
const unsigned fwPeriphAddress_OPC_GROUP_IN 	= 14;
const unsigned fwPeriphAddress_OPC_GROUP_OUT 	= 15;
const unsigned fwPeriphAddress_OPC_OBJECT_SIZE	= 15;

// DIM address object
const unsigned fwPeriphAddress_DIM_CONFIG_DP	 			= 11;
const unsigned fwPeriphAddress_DIM_DEFAULT_VALUE 		= 12;
const unsigned fwPeriphAddress_DIM_TIMEOUT					= 13;
const unsigned fwPeriphAddress_DIM_FLAG				 			= 14;
const unsigned fwPeriphAddress_DIM_IMMEDIATE_UPDATE	= 15;
const unsigned fwPeriphAddress_DIM_OBJECT_SIZE	= 15;

const unsigned fwPeriphAddress_DIM_DRIVER_NUMBER = 1;

// DIP address object
const unsigned fwPeriphAddress_DIP_CONFIG_DP 	= 11;
const unsigned fwPeriphAddress_DIP_BUFFER_TIME 	= 12;

// Misc
const int PVSS_ADDRESS_LOWLEVEL_TO_MODE = 64;

// Mode (existing in PVSS)
//DPATTR_ADDR_MODE_INPUT_SPONT
//DPATTR_ADDR_MODE_OUTPUT_SINGLE

// Data type
const int PVSS_MODBUS_INT16 = 561;
const int PVSS_MODBUS_INT32 = 562;
const int PVSS_MODBUS_UINT16 = 563;
const int PVSS_MODBUS_BOOL = 567;
const int PVSS_MODBUS_FLOAT = 566;

// Unicos address reference
const unsigned UN_ADDRESS_PARAMETER_FIELD_NUMBER = 5;	// Number of parameters
const unsigned UN_ADDRESS_PARAMETER_FIELD_MODE = 1;		// Mode
const unsigned UN_ADDRESS_PARAMETER_FIELD_PLCTYPE = 2;	// PLC type ie "QUANTUM" or "PREMIUM"
const unsigned UN_ADDRESS_PARAMETER_FIELD_PLCNUMBER = 3;// PLC number
const unsigned UN_ADDRESS_PARAMETER_FIELD_EVENT = 4;	// Is event
const unsigned UN_ADDRESS_PARAMETER_FIELD_ADDRESS = 5;	// Address in PLC

const char UN_PREMIUM_INPUT_LETTER_EVENT = "U";
const char UN_PREMIUM_INPUT_LETTER_MISC = "U";
const char UN_QUANTUM_INPUT_LETTER_EVENT = "U";
const char UN_QUANTUM_INPUT_LETTER_MISC = "M";

const int UN_PREMIUM_INPUT_NB_EVENT = 18;
const int UN_PREMIUM_INPUT_NB_MISC = 1;
const int UN_QUANTUM_INPUT_NB_EVENT = 18;
const int UN_QUANTUM_INPUT_NB_MISC = 16;

const int UN_PREMIUM_QUANTUM_OUTPUT_NB_ALL = 16;
const char UN_PREMIUM_QUANTUM_OUTPUT_LETTER_ALL = "M";
//@}

//@{
fwPeriphAddress_setMany(dyn_string &dpes, dyn_dyn_anytype &configParameters, dyn_string& exceptionInfo, bool runDriverCheck = FALSE)
{
	int i, length;
	
	length = dynlen(dpes);
	for(i=1; i<=length; i++)
	{
		fwPeriphAddress_set(dpes[i], configParameters[i], exceptionInfo, runDriverCheck);
	}  
}
    
/** Sets the address config for a given data point element

@par Constraints
	Currently supports S7, MODBUS, OPCCLIENT, DIP and DIMCLIENT address types
  
@par Example

  This example is for S7. It connects the dpe sys_1:testPerAddr.input to the element DB81.DBD0F. 
  The PLC connection is defined on Test_PLC.
\code
  dyn_anytype params;
  dyn_string exc;
  params[fwPeriphAddress_TYPE] = fwPeriphAddress_TYPE_S7;
  params[fwPeriphAddress_DRIVER_NUMBER] = 2;
  //element address on the PLC table:
  //Test_PLC is the S7 connection as defined on PVSS S7 driver parameterization panel
  params[fwPeriphAddress_ROOT_NAME] = "Test_PLC.DB81.DBD0F"; 
  params[fwPeriphAddress_DIRECTION] = DPATTR_ADDR_MODE_INPUT_POLL; //read mode
  params[fwPeriphAddress_DATATYPE] = 700; //default type convertion. see PVSS help on _address for more options
  params[fwPeriphAddress_ACTIVE] = true;
  params[fwPeriphAddress_S7_LOWLEVEL] = false; //or true if you want timestamp to be updated only on value change
  params[fwPeriphAddress_S7_POLL_GROUP] = "_poll_PLC_Test"; //poll group name
  fwPeriphAddress_set("sys_1:testPerAddr.input", params,  exc);
\endcode

@par Usage
	Public

@par PVSS managers
	VISION, CTRL

@param dpe	datapoint element to act on
@param configParameters		Address object is passed here:														\n\n
			configParameters[fwPeriphAddress_TYPE] contains type of addressing:										\n
\t				fwPeriphAddress_TYPE_OPCCLIENT															\n
\t				fwPeriphAddress_TYPE_DIMCLIENT															\n
\t				fwPeriphAddress_TYPE_DIP																\n
\t				fwPeriphAddress_TYPE_MODBUS																\n
\t				fwPeriphAddress_TYPE_S7																	\n
\t				or fwPeriphAddress_TYPE_CMW																\n
			configParameters[fwPeriphAddress_DRIVER_NUMBER] contains driver number										\n
			configParameters[fwPeriphAddress_ROOT_NAME] 	contains address string										\n
			configParameters[fwPeriphAddress_DIRECTION] 	contains direction of address for dpe:							\n
\t				DPATTR_ADDR_MODE_OUTPUT_SINGLE															\n
\t				DPATTR_ADDR_MODE_INPUT_SPONT																\n
\t				or 6 for in/out (no PVSS constant available yet)												\n
			configParameters[fwPeriphAddress_DATATYPE] 		contains the translation datatype							\n
			configParameters[fwPeriphAddress_ACTIVE] 		contains whether or not the address is active						\n
											Note: This active parameter is ignored if using DIM (always active)		\n
\n
			MODBUS Specific entries in address object:														\n
\t				configParameters[fwPeriphAddress_MODBUS_LOWLEVEL] 												\n
\t				configParameters[fwPeriphAddress_MODBUS_SUBINDEX] 												\n
\t				configParameters[fwPeriphAddress_MODBUS_START] 													\n
\t				configParameters[fwPeriphAddress_MODBUS_INTERVAL]												\n
\n
			OPC Specific entries in address object:															\n
\t				configParameters[fwPeriphAddress_OPC_LOWLEVEL] 	contains is lowlevel comparison is enabled (output only)			\n
\t				configParameters[fwPeriphAddress_OPC_SUBINDEX] 	contains subindex if datatype = 'bitstring'					\n
\t				configParameters[fwPeriphAddress_OPC_SERVER_NAME] contains OPC server name								\n
\t				configParameters[fwPeriphAddress_OPC_GROUP_IN] contains OPC group for input address configs only				\n
\t				configParameters[fwPeriphAddress_OPC_GROUP_OUT] contains OPC group for output address configs only				\n
\n
			DIM Client Service Specific entries in address object:												\n
\t				configParameters[fwPeriphAddress_DIM_CONFIG_DP]  the DIM config data point to which the config is saved			\n
\t				configParameters[fwPeriphAddress_DIM_DEFAULT_VALUE] 	default value setting								\n
\t				configParameters[fwPeriphAddress_DIM_TIMEOUT]		timeout setting									\n
\t				configParameters[fwPeriphAddress_DIM_FLAG]			flag setting								\n
\t				configParameters[fwPeriphAddress_DIM_IMMEDIATE_UPDATE] 	immediate update setting						\n
\n
			DIP Client Specific entries in address object:														\n
\t				configParameters[fwPeriphAddress_DIP_CONFIG_DP]  the DIP config data point to which the config is saved			\n
\n
			S7 Specific entries in address object:															\n
\t				configParameters[fwPeriphAddress_S7_LOWLEVEL]													\n
\t				configParameters[fwPeriphAddress_S7_SUBINDEX]													\n
\t				configParameters[fwPeriphAddress_S7_START]													\n
\t				configParameters[fwPeriphAddress_S7_INTERVAL]													\n
\t				configParameters[fwPeriphAddress_S7_POLL_GROUP]													\n
\n
@param exceptionInfo		details of any errors are returned here
@param runDriverCheck		Optional parameter (default value = FALSE) - TRUE to check if driver is running before setting config, else FALSE
												The necessary driver number must be running in order to successfully create config
*/
fwPeriphAddress_set(string dpe, dyn_anytype configParameters, dyn_string& exceptionInfo, bool runDriverCheck = FALSE)
{
	bool isRunning, inputOk = true;
	bool lowLevel;
	int res, oldLength, groupType, direction, result;
	string dipItem, dipTag, dipConfigDp, dimConfigDp, errorString;
	dyn_string configTypeData, systems;
	dyn_errClass err; 
	
	if((configParameters[fwPeriphAddress_TYPE] == fwPeriphAddress_TYPE_DIM) || (configParameters[fwPeriphAddress_TYPE] == fwPeriphAddress_TYPE_DIMCLIENT))
		configParameters[fwPeriphAddress_DRIVER_NUMBER] = fwPeriphAddress_DIM_DRIVER_NUMBER;

  if(runDriverCheck)
  {
		_fwConfigs_getSystemsInDpeList(makeDynString(dpe), systems, exceptionInfo);
		fwPeriphAddress_checkIsDriverRunning(configParameters[fwPeriphAddress_DRIVER_NUMBER], isRunning, exceptionInfo, systems[1]);
		if(!isRunning)
		{
			errorString = getCatStr("fwPeriphAddress", "ERROR_DRIVERNOTRUNNING");
			strreplace(errorString, "<driver>", configParameters[fwPeriphAddress_DRIVER_NUMBER]);
			fwException_raise(exceptionInfo, "ERROR", "fwPeriphAddress_set(): " + errorString, "");
			return;
		}
	}
	
	oldLength = dynlen(exceptionInfo);
	if (dpExists(dpe))
		{
		if (dynlen(configParameters) >= 1)
			{
			switch (configParameters[fwPeriphAddress_TYPE])
				{
				case fwPeriphAddress_TYPE_MODBUS:
					if (dynlen(configParameters) == FW_PARAMETER_FIELD_NUMBER)
						fwPeriphAddress_setModbus(dpe, configParameters, exceptionInfo);
					else
						fwException_raise(exceptionInfo, "ERROR", "fwPeriphAddress_set(): The address configuration data for dpe '"+dpe+"'is not valid: incorrect number of parameters.", "");
					break;
				
				case fwPeriphAddress_TYPE_OPC:
				case fwPeriphAddress_TYPE_OPCCLIENT:
					if(configParameters[fwPeriphAddress_DIRECTION] == DPATTR_ADDR_MODE_OUTPUT_SINGLE)
						groupType = fwPeriphAddress_OPC_GROUP_OUT;
					else
						groupType = fwPeriphAddress_OPC_GROUP_IN;
						
					lowLevel = configParameters[fwPeriphAddress_OPC_LOWLEVEL];
					direction = configParameters[fwPeriphAddress_DIRECTION];
					
					//DebugN(lowLevel, configParameters[fwPeriphAddress_DIRECTION]);
					fwPeriphAddress_setOPC(dpe, configParameters[fwPeriphAddress_OPC_SERVER_NAME],
											configParameters[fwPeriphAddress_DRIVER_NUMBER],
											configParameters[fwPeriphAddress_ROOT_NAME],
											configParameters[groupType],
	                   						configParameters[fwPeriphAddress_DATATYPE],
	                  						direction + (PVSS_ADDRESS_LOWLEVEL_TO_MODE*lowLevel),
	                   						configParameters[fwPeriphAddress_OPC_SUBINDEX],
	                  						exceptionInfo); 

					if (dynlen(exceptionInfo) == oldLength)
					{
						dpSetWait(dpe + ":_address.._active", configParameters[fwPeriphAddress_ACTIVE]);
					}

					err = getLastError();
					if(dynlen(err) > 0) 
					{
						throwError(err);
						fwException_raise(exceptionInfo, "ERROR","fwPeriphAddress_set(): Could not set active attribute for dpe '"+dpe+"'", "");
					}
					break;

				case fwPeriphAddress_TYPE_DIM:
				case fwPeriphAddress_TYPE_DIMCLIENT:
					dpe = dpSubStr(dpe, DPSUB_DP_EL);
					dimConfigDp = dpSubStr(configParameters[fwPeriphAddress_DIM_CONFIG_DP], DPSUB_DP);

					if(dpExists(dimConfigDp))
					{
						if(dpTypeName(dimConfigDp) == "_FwDimConfig")
						{
							configParameters[fwPeriphAddress_DIM_CONFIG_DP] = dimConfigDp;
						}
						else
						{
							fwException_raise(exceptionInfo, "ERROR","fwPeriphAddress_set(): The specified DP ("+dimConfigDp+") is not a DIM config DP", "");
							return;
						}
					}
					else
					{
						fwException_raise(exceptionInfo, "ERROR","fwPeriphAddress_set(): The specified DIM config DP ("+dimConfigDp+") does not exist", "");
						return;
					}

				//temporary code
					dpSetWait(dpe + ":_distrib.._type", DPCONFIG_DISTRIBUTION_INFO,
										dpe + ":_distrib.._driver", fwPeriphAddress_DIM_DRIVER_NUMBER);
					_fwDim_setDpConfig(dpe, configParameters[fwPeriphAddress_DIM_CONFIG_DP]);
				//end of temporary code
				
					switch(configParameters[fwPeriphAddress_DIRECTION])
					{
						case DPATTR_ADDR_MODE_OUTPUT_SINGLE:
							fwDim_subscribeCommand(configParameters[fwPeriphAddress_DIM_CONFIG_DP], configParameters[fwPeriphAddress_ROOT_NAME], dpe, 1);
							break;
						case DPATTR_ADDR_MODE_INPUT_SPONT:
							fwDim_subscribeService(configParameters[fwPeriphAddress_DIM_CONFIG_DP], configParameters[fwPeriphAddress_ROOT_NAME], dpe,
																		configParameters[fwPeriphAddress_DIM_DEFAULT_VALUE], configParameters[fwPeriphAddress_DIM_TIMEOUT],
																		configParameters[fwPeriphAddress_DIM_FLAG], configParameters[fwPeriphAddress_DIM_IMMEDIATE_UPDATE], 1);
							break;
					}
					break;
				case fwPeriphAddress_TYPE_DIP:
					fwInstallation_componentInstalled("fwDIP", "1.0", result);
					if(result > 0)
					{
						dipConfigDp = configParameters[fwPeriphAddress_DIP_CONFIG_DP];

						if(dpExists(dipConfigDp))
						{
							if(dpTypeName(dipConfigDp) == "_FwDipConfig")
							{
								_fwDIP_splitAddress(configParameters[fwPeriphAddress_ROOT_NAME], dipItem, dipTag, exceptionInfo);
								fwDIP_subscribe(dpe, configParameters[fwPeriphAddress_DIP_CONFIG_DP], dipItem, dipTag, exceptionInfo, TRUE);
							}
							else
							{
								fwException_raise(exceptionInfo, "ERROR","fwPeriphAddress_set(): The specified DP ("+dipConfigDp+") is not a DIP config DP", "");
								return;
							}
						}
						else
						{
							fwException_raise(exceptionInfo, "ERROR","fwPeriphAddress_set(): The specified DIP config DP ("+dipConfigDp+") does not exist", "");
							return;
						}

					}
					else
						fwException_raise(exceptionInfo, "ERROR", "fwPeriphAddress_set(): Can not set the DIP config.  The DIP framework component is not installed.", "");
					break;
				default:
					configTypeData = strsplit(configParameters[fwPeriphAddress_TYPE], "/");
					if(isFunctionDefined("_fwPeriphAddress" + configTypeData[1] + "_set"))
					{				
//DebugN("Call external function: fwPeriphAddress" + configTypeData[1] + "_set");			
						res = evalScript(exceptionInfo, "dyn_string main(string dpe, dyn_anytype addressConfig, dyn_string exInfo)"
																+ "{ "
																+ " _fwPeriphAddress" + configTypeData[1] + "_set(dpe, addressConfig, exInfo);"
																+ " return exInfo;"
																+ "}", makeDynString(), dpe, configParameters, exceptionInfo);
//DebugN(exceptionInfo);
					}
					else
						fwException_raise(exceptionInfo,"ERROR","fwPeriphAddress_set: " + getCatStr("fwPeriphAddress","UNKNOWNCOMM"),"");
					break;
				}
			}
		else
			{
			inputOk = false;
			}
		}
	else
		{
		inputOk = false;
		}
	if (!inputOk)
		{
		fwException_raise(exceptionInfo,"ERROR","fwPeriphAddress_set: " + getCatStr("fwPeriphAddress","BADINPUT"),"");
		}
}

/** Add an address config for an OPC Item

@par Constraints
	None

@par Usage
	Public

@par PVSS managers
	VISION, CTRL

@param dpe							data point element 
@param opcServerName		data point name of the OPC Server wihtout system name and "_"
@param driverNum				driver number 
@param OPCItemName			opc item name 
@param OPCGroup					opc group name 
@param datatype					translation datatype for address (0 gives automatic translation) 
@param mode							DPATTR_ADDR_MODE_INPUT_SPONT: spontaneous input
												DPATTR_ADDR_MODE_INPUT_SPONT+64: spontaneous input and old/new comparison
												DPATTR_ADDR_MODE_OUTPUT_SINGLE: output
												DPATTR_ADDR_MODE_OUTPUT_SINGLE+64: output and old/new comparison
@param subindex					used where datatype is set to 'bitstring'.  Subindex gives the position of the desired bit. 
@param exceptionInfo		details of any errors are returned here
*/
fwPeriphAddress_setOPC(	string dpe, string opcServerName, int driverNum, string OPCItemName, string OPCGroup,
                     	int datatype, int mode, unsigned subindex, dyn_string &exceptionInfo) 
{ 
	int dataType;
	string ref, systemName, errorText, opc, group; 
	dyn_errClass err; 
            
  fwGeneral_getSystemName(dpe, systemName, exceptionInfo);
             
	// OPC server
	opc = systemName + "_" + opcServerName;
    if(!dpExists(opc))
	{ 
		errorText = "fwPeriphAddress_setOPC(): OPC Server: " + opcServerName + " not existing"; 
		fwException_raise(exceptionInfo, "ERROR", errorText, "");
		return;
	} 
	
	// OPC group
	group = systemName + "_" + OPCGroup; 
	if (!dpExists(group))
	{
		errorText = "fwPeriphAddress_setOPC(): OPC group " + OPCGroup + " not existing";
		fwException_raise(exceptionInfo, "ERROR", errorText, "");
		return;
	} 
      
	ref = opcServerName + "$" + OPCGroup + "$" + OPCItemName; 

	switch(mode) 
	{
		case DPATTR_ADDR_MODE_OUTPUT_SINGLE:
		case DPATTR_ADDR_MODE_INPUT_SPONT:
		case DPATTR_ADDR_MODE_INPUT_SPONT + 64:
		case DPATTR_ADDR_MODE_OUTPUT_SINGLE + 64:
		case 6: //in/out
		case 6 + 64:
			dpSetWait(	dpe + ":_distrib.._type", DPCONFIG_DISTRIBUTION_INFO,
						dpe + ":_distrib.._driver", driverNum);
			err = getLastError();
			if(dynlen(err) > 0) 
			{
				throwError(err);
				fwException_raise(exceptionInfo, "ERROR","fwPeriphAddress_setOPC(): Error while creating the address config", "");
			}
			
			//fwPeriphAddress_getDataType(dataType, dpe, "OPC");
			//DebugN(dataType);
			
			switch(datatype)
			{
				//for most recognised data types, make sure subindex is set to 0
				case 480:
				case 481:
				case 482:
				case 483:
				case 484:
				case 485:
				case 486:
				case 487:
				case 488:
				case 489:
				case 490:
					subindex = 0;
					break;
				//if bitstring do nothing
				case 491:
					break;
				//if unknown or invalid use 0 (default)
				default:
					subindex = 0;
					datatype = 0;
					break;
			}
						
			dpSetWait(	dpe + ":_address.._type", DPCONFIG_PERIPH_ADDR_MAIN,
						dpe + ":_address.._reference", ref,
						dpe + ":_address.._datatype", datatype,
						dpe + ":_address.._mode", mode,
						dpe + ":_address.._subindex", subindex,
						dpe + ":_address.._drv_ident", "OPCCLIENT");
						
			err = getLastError();
			if(dynlen(err) > 0) 
			{ 
            	throwError(err);
            	fwException_raise(exceptionInfo, "ERROR","fwPeriphAddress_setOPC(): Error while configuring the peripheral address", "");
            } 
			break;
		default:
			errorText = "fwPeriphAddress_setOPC(): the selected mode " + mode + " is unknown";
			fwException_raise(exceptionInfo, "ERROR", errorText, "");
			return;
	} 
} 
 

/** Deletes the address config of the given dp elements

@par Constraints
	None

@par Usage
	Public

@par PVSS managers
	VISION, CTRL

@param dpes						list of data point elements
@param exceptionInfo	details of any errors are returned here
*/
fwPeriphAddress_deleteMultiple(dyn_string dpes, dyn_string &exceptionInfo)
{
	int i, length;
	
	length = dynlen(dpes);
	for(i=1; i<=length; i++)
	{
		fwPeriphAddress_delete(dpes[i], exceptionInfo);
	}
}


/** Deletes the address config of the given dp element

@par Constraints
	None

@par Usage
	Public

@par PVSS managers
	VISION, CTRL

@param dpe						data point element
@param exceptionInfo	details of any errors are returned here
*/
fwPeriphAddress_delete(string dpe, dyn_string &exceptionInfo) 
{ 
	bool isConfigured, isActive, isAccessible;
  int res, addr, dist, result = 1; 
  string configDp, addressType;
  dyn_int requiredDrivers;
  dyn_anytype configData;
  dyn_errClass err; 
  dyn_string localException, configTypeData;
  string errorText, errorString;

	fwPeriphAddress_get(dpe, isConfigured, configData, isActive, localException);
	//if address type was read but some other error occured, continue
	if(dynlen(localException) > 0)
	{
		if(configData[fwPeriphAddress_TYPE] != "")
			dynClear(localException);
		else
		{
		//else return with the exception that was returned
			dynAppend(exceptionInfo, localException);
			return;
		}
	}
	
	if(!isConfigured)
		return;

  if(configData[fwPeriphAddress_TYPE] == fwPeriphAddress_TYPE_DIP)
	{
		fwInstallation_componentInstalled("fwDIP", "1.0", result);
		if(result == 0)
		{
			fwException_raise(exceptionInfo, "ERROR","fwPeriphAddress_delete(): Can not delete the DIP config.  The DIP framework component is not installed.", "");
			return;
		}
	}

	configTypeData = strsplit(configData[fwPeriphAddress_TYPE], "/");
	if(isFunctionDefined("_fwPeriphAddress" + configTypeData[1] + "_delete"))
	{
//DebugN("Call external function: fwPeriphAddress" + configTypeData[1] + "_delete");			
		res = evalScript(exceptionInfo, "dyn_string main(string dpe, dyn_string exInfo)"
												+ "{ "
												+ " _fwPeriphAddress" + configTypeData[1] + "_delete(dpe, exInfo);"
												+ " return exInfo;"
												+ "}", makeDynString(), dpe, exceptionInfo);
//DebugN(exceptionInfo);
	}
	
	dpSetWait( dpe + ":_distrib.._type", DPCONFIG_NONE); 
   	err = getLastError(); 
   	if(dynlen(err) > 0)
   	{ 
         throwError(err); 
         fwException_raise(exceptionInfo, "ERROR","fwPeriphAddress_delete(): Error while deleting the address config", "");
     	 return;
  	} 
    
	dpSetWait( dpe + ":_address.._type", DPCONFIG_NONE); 
   	err = getLastError(); 
   	if(dynlen(err) > 0) 
   	{ 
         throwError(err); 
         fwException_raise(exceptionInfo, "ERROR","fwPeriphAddress_delete(): Error while deleting the address config", ""); 
   	} 
	     

  if((configData[fwPeriphAddress_TYPE] == fwPeriphAddress_TYPE_DIM) || (configData[fwPeriphAddress_TYPE] == fwPeriphAddress_TYPE_DIMCLIENT))
	{
	//temporary code
		dpSetWait(dpe + ":_distrib.._type", DPCONFIG_NONE);
		_fwDim_unSetDpConfig(dpe);
	//end of temporary code

		dpe = dpSubStr(dpe, DPSUB_DP_EL);
		if(configData[fwPeriphAddress_DIRECTION] == DPATTR_ADDR_MODE_OUTPUT_SINGLE)
			fwDim_unSubscribeCommandsByDp(configData[fwPeriphAddress_DIM_CONFIG_DP], dpe, 1);
		else
			fwDim_unSubscribeServicesByDp(configData[fwPeriphAddress_DIM_CONFIG_DP], dpe, 1);
	}
	
	if(configData[fwPeriphAddress_TYPE] == fwPeriphAddress_TYPE_DIP)
		_fwDIP_removeSubscription(makeDynString(dpe), exceptionInfo);
} 


/*this is the old function
fwPeriphAddress_getMany(dyn_string &dpes, dyn_bool &configExists, dyn_dyn_anytype &configParameters, dyn_bool &isActive, dyn_string &exceptionInfo) 
{
	int i, length;
	
	length = dynlen(dpes);
	for(i=1; i<=length; i++)
	{
		fwPeriphAddress_get(dpes[i], configExists[i], configParameters[i], isActive[i], exceptionInfo, runDriverCheck);
	}  
}
*/
    
   
/** Gets the address config of a datapoint element.  
The function checks that the relevant driver is running.  If not it returns an exception saying the config could not be read.


@par Constraints
	Currently only supports MODBUS, OPCCLIENT, DIP and DIMCLIENT address types

@par Usage
	Public

@par PVSS managers
	VISION, CTRL

@see fwPeriphAddress_get()

@param dpe	datapoint element to read from. Passed as reference for performance reasons. Not modified.
@param configExists				TRUE if address config exists, else FALSE
@param config		address object is returned here. See fwPeriphAddress_get() for details on the addess object.
@param isActive				TRUE is address config is active, else FALSE 
@param exceptionInfo	details of any errors are returned here
*/
fwPeriphAddress_getMany(dyn_string &dpes, dyn_bool &configExists, dyn_dyn_anytype &config, dyn_bool &isActive, dyn_string &exceptionInfo) 
{
	bool isRunning;
	int res, configType, datatype, mode, driverNumber, result, position;
	string reference, dpe;
	dyn_string configTypeData, referenceParts;
	dyn_errClass err; 
	dyn_int timeouts, flags, immediateUpdates;
	dyn_string defaultValues, dimList, dpeList, systems;
	dyn_dyn_anytype returnValue;
  
  dyn_string dsDpAttr, dsTypesAttr, dsDriveAttr, dsDriveVal, dsAddressTypeAttr, dsAddressTypeVal, dsAddressAttr, dsDistDriveAttr;
  dyn_int diTypesVal, diTempVal, diDistDriveVal;
  dyn_mixed dsAttrVal, dmTempVal, dsAddressVal;
  int i, j, k, n, o;//yes we need all those indexes...
  int length, iAttrsLen, iTemp;
  int ret;  
  dyn_string dsTempVal;
  dyn_int diDriverNum;

	config = makeDynString();
  length = dynlen(dpes);
// DebugN("len: "+length);  
  
  //get the info on drivers type and number, store them into dsTypesAttr.
  for(i=1 ; i<=length ; i++)
  {
//DebugN("Grouping...", numberOfSettings, tempAttributes, tempValues);
    dynAppend(dsTypesAttr , dpes[i] + ":_distrib.._type");				
		if((dynlen(dsTypesAttr) > fwConfigs_OPTIMUM_DP_SET_SIZE) || (i == length && dynlen(dsTypesAttr)>0))
		{
	    dpGet(dsTypesAttr, diTempVal);
      dynAppend(diTypesVal, diTempVal);
// DebugN("dsTypesAttr: ",dsTypesAttr);
      dynClear(dsTypesAttr);
    }
  }  
// DebugN("dsTypesVal: ",diTypesVal);

  //get the info on drivers type and number, store them into dsTypesAttr.
  for(i=1 ; i<=length ; i++)
  {
//DebugN("Grouping...", numberOfSettings, tempAttributes, tempValues);
    if(diTypesVal[i] != DPCONFIG_NONE)
    {
      dynAppend(dsDistDriveAttr , dpes[i] + ":_distrib.._driver");		
    }		
		if((dynlen(dsDistDriveAttr) > fwConfigs_OPTIMUM_DP_SET_SIZE) || (i == length && dynlen(dsDistDriveAttr)>0))
		{
	    dpGet(dsDistDriveAttr, diTempVal);
      dynAppend(diDistDriveVal, diTempVal);
// DebugN("dsDistDriveAttr: ",dsDistDriveAttr);
      dynClear(dsDistDriveAttr);
    }
  }  
// DebugN("diDistDriveVal: ",diDistDriveVal);

  j=1;//:_distrib.._driver
  for(i=1 ; i<=length ; i++)
  {
    if(diTypesVal[i] != DPCONFIG_NONE)
    {
    	_fwConfigs_getSystemsInDpeList(dpes[i], systems, exceptionInfo);
      config[i][fwPeriphAddress_DRIVER_NUMBER] = diDistDriveVal[j];
      driverNumber = diDistDriveVal[j];
    	fwPeriphAddress_checkIsDriverRunning(driverNumber, isRunning, exceptionInfo, systems[1]);
// DebugN("check driver for: "+ dpes[i],"diDistDriveVal[j]: ", diDistDriveVal[j], "driverNumber: ",driverNumber, "isRunning: ", isRunning, "exceptionInfo:", exceptionInfo, "systems[1]: ",systems[1]);
      if(!isRunning)
      {
        	configExists[i] = TRUE;
      		fwException_raise(exceptionInfo, "ERROR","fwPeriphAddress_getMany(): Could not access address config for dpe '"+dpes[i]+"' (Make sure driver number " + driverNumber + " is running)", driverNumber);				
      		return;
      }
      j++;//:_distrib.._driver
    }
    else
    {
    	configExists[i] = FALSE;
    	isActive[i] = FALSE;
    	config[i][fwPeriphAddress_DIRECTION] = 0;
    	config[i][fwPeriphAddress_DRIVER_NUMBER] = 0;
    }

  }  

  //get the :_address.._type, store all the values into dsAddressTypeAttr
  for(i=1 ; i<=length ; i++)
  {
      dynAppend(dsAddressTypeAttr , dpes[i] + ":_address.._type");				
  		if((dynlen(dsAddressTypeAttr) > fwConfigs_OPTIMUM_DP_SET_SIZE) || (i == length && dynlen(dsAddressTypeAttr)>0))
  		{
  	    dpGet(dsAddressTypeAttr, dsTempVal);
        dynAppend(dsAddressTypeVal, dsTempVal);
// DebugN("dsAddressTypeAttr:",dsAddressTypeAttr);
        dynClear(dsAddressTypeAttr);
      } 
  } 
// DebugN("dsAddressTypeVal:",dsAddressTypeVal);
  
  //get the _address.._drv_ident, store it into dsDriveVal
  for(i=1 ; i<=length ; i++)
  {
    if(dsAddressTypeVal[i] != DPCONFIG_NONE)//check if _address.._type is non-null
		  dynAppend(dsDriveAttr, dpes[i] + ":_address.._drv_ident");
		if((dynlen(dsDriveAttr) > fwConfigs_OPTIMUM_DP_SET_SIZE) || (i == length && dynlen(dsDriveAttr)>0))
		{
	    dpGet(dsDriveAttr, dsTempVal);
      dynAppend(dsDriveVal, dsTempVal);
// DebugN("dsDriveAttr:",dsDriveAttr);
      dynClear(dsDriveAttr);
    } 
  }    
// DebugN("dsDriveVal:",dsDriveVal);
  
  //get all the other attributes, store them into dsAddressVal
  iAttrsLen = dynlen(dsDriveVal);
  o=1;//:_address.._type in dsAddressTypeVal
  n=1;//:_address.._drv_ident in dsDriveVal
  for(i=1 ; i<=length ; i++)
  {
  	if(diTypesVal[i] != DPCONFIG_NONE)
  	{  
// DebugN("dsAddressTypeVal["+o+"] :",dsAddressTypeVal[o] );
    	if(dsAddressTypeVal[o] != DPCONFIG_NONE)
    	{  
        config[i][fwPeriphAddress_TYPE] = dsDriveVal[n];
    		configTypeData = strsplit(config[i][fwPeriphAddress_TYPE], "/");
    		switch(configTypeData[1])
    		{
    			case fwPeriphAddress_TYPE_MODBUS:
            dynAppend(dsAddressAttr, dpes[i]+":_address.._reference");
            dynAppend(dsAddressAttr, dpes[i]+":_address.._subindex");
            dynAppend(dsAddressAttr, dpes[i]+":_address.._start");
            dynAppend(dsAddressAttr, dpes[i]+":_address.._interval");
            dynAppend(dsAddressAttr, dpes[i]+":_address.._datatype");
            dynAppend(dsAddressAttr, dpes[i]+":_address.._direction");
            dynAppend(dsAddressAttr, dpes[i]+":_address.._lowlevel");
            dynAppend(dsAddressAttr, dpes[i]+":_address.._poll_group");
            dynAppend(dsAddressAttr, dpes[i]+":_address.._active");
    			break;		
    			case fwPeriphAddress_TYPE_OPCCLIENT:
            dynAppend(dsAddressAttr, dpes[i]+":_address.._reference");
            dynAppend(dsAddressAttr, dpes[i]+":_address.._datatype");
            dynAppend(dsAddressAttr, dpes[i]+":_address.._subindex");
            dynAppend(dsAddressAttr, dpes[i]+":_address.._direction");
            dynAppend(dsAddressAttr, dpes[i]+":_address.._lowlevel");
            dynAppend(dsAddressAttr, dpes[i]+":_address.._active");
    			break;		
    			case fwPeriphAddress_TYPE_DIM:			
    			case fwPeriphAddress_TYPE_DIMCLIENT:
    			break;
    			default:			
    			break;		
    		}
        n++;
    	}
      o++;
    }
		if((dynlen(dsAddressAttr) > fwConfigs_OPTIMUM_DP_SET_SIZE) || (i == length && dynlen(dsAddressAttr) >0))
		{
	    dpGet(dsAddressAttr, dmTempVal);
      dynAppend(dsAddressVal, dmTempVal);
// DebugN("dsAddressAttr:",dsAddressAttr);
      dynClear(dsAddressAttr);
    }     
  }
  //make type conversion
  for(i=1 ; i<=dynlen(dsAddressVal) ; i++)
  {
    if(dsAddressVal[i]=="" || dsAddressVal[i]=="")
    {
      iTemp = dsAddressVal[i];
      dsAddressVal[i] = iTemp;
    }
  }  
// DebugN("dsAddressVal:",dsAddressVal);
  //arrange attributes values into configuration variables
  k=1;//:_distrib.._type in diTypesVal
  j=1;//:_distrib.._type in dsAddressTypeVal
  n=1;//:_address.._drv_ident in dsDriveVal
  o=1;//:_address.._type in dsAddressVal
  for(i=1 ; i<=length ; i++)
  {
    configExists[i] = FALSE;
    isActive[i] = FALSE;
    config[i][fwPeriphAddress_DIRECTION] = 0;
// DebugN("diTypesVal["+k+"]:",diTypesVal[k]);
    if(diTypesVal[k] != DPCONFIG_NONE)
    {    
// DebugN("dsAddressTypeVal["+j+"]:",dsAddressTypeVal[j]);
    	if(dsAddressTypeVal[j] != DPCONFIG_NONE)
    	{  
        config[i][fwPeriphAddress_TYPE] = dsDriveVal[n];
    		configTypeData = strsplit(config[i][fwPeriphAddress_TYPE], "/");
// DebugN("configTypeData[1]:",configTypeData[1]);
    		switch(configTypeData[1])
    		{
    			case fwPeriphAddress_TYPE_MODBUS:       
    				config[i][fwPeriphAddress_ROOT_NAME] = dsAddressVal[o]; o++; //_address.._reference
    				config[i][fwPeriphAddress_MODBUS_SUBINDEX] = dsAddressVal[o]; o++; //_address.._subindex
    				config[i][fwPeriphAddress_MODBUS_START] = (time)dsAddressVal[o]; o++; //_address.._start
    				config[i][fwPeriphAddress_MODBUS_INTERVAL] = (time)dsAddressVal[o]; o++; //_address.._interval
    				config[i][fwPeriphAddress_DATATYPE] = dsAddressVal[o]; o++; //_address.._datatype
    				config[i][fwPeriphAddress_DIRECTION] = dsAddressVal[o]; o++; //_address.._direction
    				config[i][fwPeriphAddress_MODBUS_LOWLEVEL] = dsAddressVal[o]; o++; //_address.._lowlevel
    				config[i][fwPeriphAddress_MODBUS_POLL_GROUP] = dsAddressVal[o]; o++; //_address.._poll_group
    				config[i][fwPeriphAddress_ACTIVE] = dsAddressVal[o]; o++; //_address.._active
    		 		isActive[i] = config[i][fwPeriphAddress_ACTIVE];
    		    configExists[i] = TRUE;
    			break;		
    			case fwPeriphAddress_TYPE_OPCCLIENT:
    				reference = dsAddressVal[o]; o++; //_address.._reference
    				config[i][fwPeriphAddress_DATATYPE] = dsAddressVal[o]; o++; //_address.._datatype
    				config[i][fwPeriphAddress_OPC_SUBINDEX] = dsAddressVal[o]; o++; //_address.._subindex
    				config[i][fwPeriphAddress_DIRECTION] = dsAddressVal[o]; o++; //_address.._direction
    				config[i][fwPeriphAddress_OPC_LOWLEVEL] = dsAddressVal[o]; o++; //_address.._lowlevel
    				config[i][fwPeriphAddress_ACTIVE] = dsAddressVal[o]; o++; //_address.._active
						
    				referenceParts = strsplit(reference, "$");
    				if(dynlen(referenceParts) != 3)
    				{
    					referenceParts[3] = "";
    		      fwException_raise(exceptionInfo, "ERROR","fwPeriphAddress_getMany(): OPC address ("+reference+") is invalid on dpe '"+dpes[i]+"'", "");				
    				}	
    				config[i][fwPeriphAddress_OPC_SERVER_NAME] = referenceParts[1];
    				config[i][fwPeriphAddress_ROOT_NAME] = referenceParts[3];
				
    				if(config[i][fwPeriphAddress_DIRECTION] == DPATTR_ADDR_MODE_OUTPUT_SINGLE)
    				{
    					config[i][fwPeriphAddress_OPC_GROUP_OUT] = referenceParts[2];
    					config[i][fwPeriphAddress_OPC_GROUP_IN] = "";
    				}
    				else
    				{
    					config[i][fwPeriphAddress_OPC_GROUP_IN] = referenceParts[2];
    					config[i][fwPeriphAddress_OPC_GROUP_OUT] = "";
    				}
    		 		isActive[i] = config[i][fwPeriphAddress_ACTIVE];
    		    configExists[i] = TRUE;
    			break;		
    			case fwPeriphAddress_TYPE_DIM:			
    			case fwPeriphAddress_TYPE_DIMCLIENT:
    				//DIM functions only support local systems so remove sys name	
    				dpe = dpSubStr(dpes[i], DPSUB_DP_EL);
    				config[i][fwPeriphAddress_TYPE] = configTypeData[1];
    				if(dynlen(configTypeData) > 1)
    					config[i][fwPeriphAddress_DIM_CONFIG_DP] = configTypeData[2];	

    				fwDim_getSubscribedCommands(config[i][fwPeriphAddress_DIM_CONFIG_DP], dimList, dpeList, flags);
    				position = dynContains(dpeList, dpe);
    				if(position <= 0)
    				{
    					fwDim_getSubscribedServices(config[i][fwPeriphAddress_DIM_CONFIG_DP], dimList, dpeList,
    																				defaultValues, timeouts, flags, immediateUpdates);
    					position = dynContains(dpeList, dpe);
    					if(position > 0)
    					{
    						configExists[i] = TRUE;
    						isActive[i] = TRUE;
    						config[i][fwPeriphAddress_ACTIVE] = isActive[i];
    						config[i][fwPeriphAddress_DIRECTION] = DPATTR_ADDR_MODE_INPUT_SPONT;
    						config[i][fwPeriphAddress_ROOT_NAME] = dimList[position];
    						config[i][fwPeriphAddress_DIM_DEFAULT_VALUE] = defaultValues[position];
    						config[i][fwPeriphAddress_DIM_TIMEOUT] = timeouts[position];
    						config[i][fwPeriphAddress_DIM_FLAG] = flags[position];
    						config[i][fwPeriphAddress_DIM_IMMEDIATE_UPDATE] = immediateUpdates[position];
    					}
    				}
    				else
    				{
    					configExists[i] = TRUE;
    					isActive[i] = TRUE;
    					config[i][fwPeriphAddress_ACTIVE] = isActive[i];
    					config[i][fwPeriphAddress_DIRECTION] = DPATTR_ADDR_MODE_OUTPUT_SINGLE;
    					config[i][fwPeriphAddress_ROOT_NAME] = dimList[position];
    				}
    				break;		
    			case fwPeriphAddress_TYPE_DIP:
    				fwInstallation_componentInstalled("fwDIP", "1.0", result);
    				if(result > 0)
    					fwDIP_getDpeSubscription(dpes[i], configExists[i], config[i][fwPeriphAddress_DIP_CONFIG_DP], config[i][fwPeriphAddress_ROOT_NAME], exceptionInfo);
    				else
    					fwException_raise(exceptionInfo, "ERROR", "fwPeriphAddress_getMany(): Can not read the DIP config for dpe '"+dpes[i]+"'.  The DIP framework component is not installed.", "");
    				isActive[i] = TRUE;
    			break;		
    			case "0":
    //DebugN("Empty address config case");
    		    configExists[i] = TRUE;
    			break;
    			default:			
    		    config[i] = makeDynAnytype(configTypeData[1]);
    				if(isFunctionDefined("_fwPeriphAddress" + configTypeData[1] + "_get"))
    				{
              dpe = dpes[i];
    //DebugN("Call external function: fwPeriphAddress" + configTypeData[1] + "_get");			
    					res = evalScript(returnValue, "dyn_dyn_anytype main(string dpe, dyn_string exInfo)"
    															+ "{ "
    															+ " bool active;"
    															+ " dyn_anytype addressConfig;"
    															+ " dyn_dyn_anytype returnValue;"
    															+ " _fwPeriphAddress" + configTypeData[1] + "_get(dpe, addressConfig, active, exInfo);"
    															+ " returnValue[1] = addressConfig;"
    															+ " returnValue[2][1] = active;"
    															+ " returnValue[3] = exInfo;"
    															+ " return returnValue;"
    															+ "}", makeDynString(), dpe, exceptionInfo);
    					config[i] = returnValue[1];
    					isActive[i] = returnValue[2][1];
    					exceptionInfo = returnValue[3];
    		    	configExists[i] = TRUE;
    				}
    				else
    				{
    					fwException_raise(exceptionInfo, "ERROR", "fwPeriphAddress_getMany(): Unsupported peripheral address type ("+configTypeData[1]+") for dpe '"+dpes[i]+"'.  Could not retreive full configuration.", "");
    		    	configExists[i] = TRUE;
    				}
    			break;		
    		}
        n++;//:_address.._drv_ident in dsDriveVal
    	}  
      j++;//:_address.._type in dsAddressTypeVal
    }
    k++;//item in diTypesVal is a :_distrib.._type
  }        
// DebugN("configExists:",configExists);  
} 

    
    
/** Gets the address config of a datapoint element.  
The function checks that the relevant driver is running.  If not it returns an exception saying the config could not be read.


@par Constraints
	Currently only supports MODBUS, OPCCLIENT, DIP and DIMCLIENT address types

@par Usage
	Public

@par PVSS managers
	VISION, CTRL

@param dpe	datapoint element to read from
@param configExists				TRUE if address config exists, else FALSE
@param config		Address object is returned here:															\n\n
			configParameters[fwPeriphAddress_TYPE] contains type of addressing:										\n
\t				fwPeriphAddress_TYPE_OPCCLIENT															\n
\t				fwPeriphAddress_TYPE_DIMCLIENT															\n
\t				fwPeriphAddress_TYPE_DIP																\n
\t				fwPeriphAddress_TYPE_MODBUS																\n
\t				fwPeriphAddress_TYPE_S7																	\n
\t				or fwPeriphAddress_TYPE_CMW																\n
			configParameters[fwPeriphAddress_DRIVER_NUMBER] contains driver number										\n
			configParameters[fwPeriphAddress_ROOT_NAME] 	contains address string										\n
			configParameters[fwPeriphAddress_DIRECTION] 	contains direction of address for dpe:							\n
\t				DPATTR_ADDR_MODE_OUTPUT_SINGLE															\n
\t				DPATTR_ADDR_MODE_INPUT_SPONT																\n
\t				or 6 for in/out (no PVSS constant available yet)												\n
			configParameters[fwPeriphAddress_DATATYPE] 		contains the translation datatype							\n
			configParameters[fwPeriphAddress_ACTIVE] 		contains whether or not the address is active						\n
											Note: This active parameter is ignored if using DIM (always active)		\n
\n
			MODBUS Specific entries in address object:														\n
\t				configParameters[fwPeriphAddress_MODBUS_LOWLEVEL] 												\n
\t				configParameters[fwPeriphAddress_MODBUS_SUBINDEX] 												\n
\t				configParameters[fwPeriphAddress_MODBUS_START] 													\n
\t				configParameters[fwPeriphAddress_MODBUS_INTERVAL]												\n
\n
			OPC Specific entries in address object:															\n
\t				configParameters[fwPeriphAddress_OPC_LOWLEVEL] 	contains is lowlevel comparison is enabled (output only)			\n
\t				configParameters[fwPeriphAddress_OPC_SUBINDEX] 	contains subindex if datatype = 'bitstring'					\n
\t				configParameters[fwPeriphAddress_OPC_SERVER_NAME] contains OPC server name								\n
\t				configParameters[fwPeriphAddress_OPC_GROUP_IN] contains OPC group for input address configs only				\n
\t				configParameters[fwPeriphAddress_OPC_GROUP_OUT] contains OPC group for output address configs only				\n
\n
			DIM Client Service Specific entries in address object:												\n
\t				configParameters[fwPeriphAddress_DIM_CONFIG_DP]  the DIM config data point to which the config is saved			\n
\t				configParameters[fwPeriphAddress_DIM_DEFAULT_VALUE] 	default value setting								\n
\t				configParameters[fwPeriphAddress_DIM_TIMEOUT]		timeout setting									\n
\t				configParameters[fwPeriphAddress_DIM_FLAG]			flag setting								\n
\t				configParameters[fwPeriphAddress_DIM_IMMEDIATE_UPDATE] 	immediate update setting						\n
\n
			DIP Client Specific entries in address object:														\n
\t				configParameters[fwPeriphAddress_DIP_CONFIG_DP]  the DIP config data point to which the config is saved			\n
\n
			S7 Specific entries in address object:															\n
\t				configParameters[fwPeriphAddress_S7_LOWLEVEL]													\n
\t				configParameters[fwPeriphAddress_S7_SUBINDEX]													\n
\t				configParameters[fwPeriphAddress_S7_START]													\n
\t				configParameters[fwPeriphAddress_S7_INTERVAL]													\n
\t				configParameters[fwPeriphAddress_S7_POLL_GROUP]													\n
\n
@param isActive				TRUE is address config is active, else FALSE 
@param exceptionInfo	details of any errors are returned here
*/
fwPeriphAddress_get(string dpe, bool &configExists, dyn_anytype &config, bool &isActive, dyn_string &exceptionInfo) 
{
	bool isRunning;
	int res, configType, datatype, mode, driverNumber, result, position;
	string reference;
	dyn_string configTypeData, referenceParts;
	dyn_errClass err; 
	dyn_int timeouts, flags, immediateUpdates;
	dyn_string defaultValues, dimList, dpeList, systems;
	dyn_dyn_anytype returnValue;

	config = makeDynString();
	configExists = FALSE;
	isActive = FALSE;
	config[fwPeriphAddress_DIRECTION] = 0;
	config[fwPeriphAddress_DRIVER_NUMBER] = 0;
    
	dpGet(dpe + ":_distrib.._type", configType,
				dpe + ":_distrib.._driver", driverNumber);
	config[fwPeriphAddress_DRIVER_NUMBER] = driverNumber;
	_fwConfigs_getSystemsInDpeList(makeDynString(dpe), systems, exceptionInfo);
	fwPeriphAddress_checkIsDriverRunning(driverNumber, isRunning, exceptionInfo, systems[1]);
  
// DebugN("configType: ", configType, "driverNumber: ", driverNumber); 

	if(configType == DPCONFIG_NONE)
		return;
	else if(!isRunning)
	{
		configExists = TRUE;
		fwException_raise(exceptionInfo, "ERROR","Could not access address config (Make sure driver number " + driverNumber + " is running)", driverNumber);				
		return;
	}

	dpGet(dpe + ":_address.._type",	configType);
	if(configType != DPCONFIG_NONE)
	{  
		dpGet(dpe + ":_address.._drv_ident",	config[fwPeriphAddress_TYPE]);

		configTypeData = strsplit(config[fwPeriphAddress_TYPE], "/");
		switch(configTypeData[1])
		{
			case fwPeriphAddress_TYPE_MODBUS:
				dpGet(  dpe + ":_address.._reference", 	config[fwPeriphAddress_ROOT_NAME],  
						dpe + ":_address.._subindex", 	config[fwPeriphAddress_MODBUS_SUBINDEX],  
						dpe + ":_address.._start", 		config[fwPeriphAddress_MODBUS_START],  
						dpe + ":_address.._interval", 	config[fwPeriphAddress_MODBUS_INTERVAL],  
						dpe + ":_address.._datatype",	config[fwPeriphAddress_DATATYPE],
						dpe + ":_address.._direction", 	config[fwPeriphAddress_DIRECTION],
						dpe + ":_address.._lowlevel", 	config[fwPeriphAddress_MODBUS_LOWLEVEL],
						dpe + ":_address.._poll_group", config[fwPeriphAddress_MODBUS_POLL_GROUP],
						dpe + ":_address.._active", 	config[fwPeriphAddress_ACTIVE]);

		 		isActive = config[fwPeriphAddress_ACTIVE];
		    	configExists = TRUE;
				break;		
			case fwPeriphAddress_TYPE_OPCCLIENT:
				dpGet(  dpe + ":_address.._reference", 	reference,  
						dpe + ":_address.._datatype",	config[fwPeriphAddress_DATATYPE],
						dpe + ":_address.._subindex", 	config[fwPeriphAddress_OPC_SUBINDEX],  
						dpe + ":_address.._direction", 	config[fwPeriphAddress_DIRECTION],
						dpe + ":_address.._lowlevel", 	config[fwPeriphAddress_OPC_LOWLEVEL],
						dpe + ":_address.._active", 	config[fwPeriphAddress_ACTIVE]);
						
				referenceParts = strsplit(reference, "$");
				if(dynlen(referenceParts) != 3)
				{
					referenceParts[3] = "";
		      fwException_raise(exceptionInfo, "ERROR","fwPeriphAddress_get(): OPC address is invalid", "");				
				}	
				config[fwPeriphAddress_OPC_SERVER_NAME] = referenceParts[1];
				config[fwPeriphAddress_ROOT_NAME] = referenceParts[3];
				
				if(config[fwPeriphAddress_DIRECTION] == DPATTR_ADDR_MODE_OUTPUT_SINGLE)
				{
					config[fwPeriphAddress_OPC_GROUP_OUT] = referenceParts[2];
					config[fwPeriphAddress_OPC_GROUP_IN] = "";
				}
				else
				{
					config[fwPeriphAddress_OPC_GROUP_IN] = referenceParts[2];
					config[fwPeriphAddress_OPC_GROUP_OUT] = "";
				}
		 		isActive = config[fwPeriphAddress_ACTIVE];
		    	configExists = TRUE;
				break;		
			case fwPeriphAddress_TYPE_DIM:			
			case fwPeriphAddress_TYPE_DIMCLIENT:
				//DIM functions only support local systems so remove sys name	
				dpe = dpSubStr(dpe, DPSUB_DP_EL);
				config[fwPeriphAddress_TYPE] = configTypeData[1];
				if(dynlen(configTypeData) > 1)
					config[fwPeriphAddress_DIM_CONFIG_DP] = configTypeData[2];	

				fwDim_getSubscribedCommands(config[fwPeriphAddress_DIM_CONFIG_DP], dimList, dpeList, flags);
				position = dynContains(dpeList, dpe);
				if(position <= 0)
				{
					fwDim_getSubscribedServices(config[fwPeriphAddress_DIM_CONFIG_DP], dimList, dpeList,
																				defaultValues, timeouts, flags, immediateUpdates);
					position = dynContains(dpeList, dpe);
					if(position > 0)
					{
						configExists = TRUE;
						isActive = TRUE;
						config[fwPeriphAddress_ACTIVE] = isActive;
						config[fwPeriphAddress_DIRECTION] = DPATTR_ADDR_MODE_INPUT_SPONT;
						config[fwPeriphAddress_ROOT_NAME] = dimList[position];
						config[fwPeriphAddress_DIM_DEFAULT_VALUE] = defaultValues[position];
						config[fwPeriphAddress_DIM_TIMEOUT] = timeouts[position];
						config[fwPeriphAddress_DIM_FLAG] = flags[position];
						config[fwPeriphAddress_DIM_IMMEDIATE_UPDATE] = immediateUpdates[position];
					}
				}
				else
				{
					configExists = TRUE;
					isActive = TRUE;
					config[fwPeriphAddress_ACTIVE] = isActive;
					config[fwPeriphAddress_DIRECTION] = DPATTR_ADDR_MODE_OUTPUT_SINGLE;
					config[fwPeriphAddress_ROOT_NAME] = dimList[position];
				}
				break;		
			case fwPeriphAddress_TYPE_DIP:
				fwInstallation_componentInstalled("fwDIP", "1.0", result);
				if(result > 0)
					fwDIP_getDpeSubscription(dpe, configExists, config[fwPeriphAddress_DIP_CONFIG_DP], config[fwPeriphAddress_ROOT_NAME], exceptionInfo);
				else
					fwException_raise(exceptionInfo, "ERROR", "fwPeriphAddress_get(): Can not read the DIP config.  The DIP framework component is not installed.", "");
				isActive = TRUE;
				break;		
			case "0":
//DebugN("Empty address config case");
		    configExists = TRUE;
				break;
			default:			
		    config = makeDynAnytype(configTypeData[1]);
				if(isFunctionDefined("_fwPeriphAddress" + configTypeData[1] + "_get"))
				{
//DebugN("Call external function: fwPeriphAddress" + configTypeData[1] + "_get");			
					res = evalScript(returnValue, "dyn_dyn_anytype main(string dpe, dyn_string exInfo)"
															+ "{ "
															+ " bool active;"
															+ " dyn_anytype addressConfig;"
															+ " dyn_dyn_anytype returnValue;"
															+ " _fwPeriphAddress" + configTypeData[1] + "_get(dpe, addressConfig, active, exInfo);"
															+ " returnValue[1] = addressConfig;"
															+ " returnValue[2][1] = active;"
															+ " returnValue[3] = exInfo;"
															+ " return returnValue;"
															+ "}", makeDynString(), dpe, exceptionInfo);
					config = returnValue[1];
					isActive = returnValue[2][1];
					exceptionInfo = returnValue[3];
		    	configExists = TRUE;
//DebugN(isActive, config, exceptionInfo);
				}
				else
				{
					fwException_raise(exceptionInfo, "ERROR", "fwPeriphAddress_get(): Unsupported peripheral address type.  Could not retreive full configuration.", "");
		    	configExists = TRUE;
				}
				break;		
		}
	}
} 


/** Checks the type of a data point element and returns the integer used to represent this data type
	depending on the required type of peripheral address.
	
	NOTE: this function is mostly redundant now as OPC supports the default data transformation now.
	The results for address type DIM are also redundant now.

@par Constraints
	None

@par Usage
	Internal

@par PVSS managers
	VISION, CTRL

@param dataType			The integer representing the data type is returned here (returns -1 if dpe type is unsupported)
@param dpe					The data point element to check
@param addressType	The type of peripheral address (DIM or OPC)
*/
fwPeriphAddress_getDataType(int &dataType, string dpe, string addressType)
{
	switch(dpElementType(dpe))
	{
		case DPEL_BOOL:
			if(addressType == "OPC")
				dataType = 486;
			else
				dataType = 2002;
			break;
		case DPEL_INT:
			if(addressType == "OPC")
				dataType = 481;
			else
				dataType = 2002;
			break;
		case DPEL_STRING:  
 			if(addressType == "OPC")
				dataType = 487;
			else
				dataType = 2001;
			break;
		case DPEL_FLOAT:  
			if(addressType == "OPC")
				dataType = 484;
			else
				dataType = 2003;
			break;
		case DPEL_DYN_BOOL:  
			if(addressType == "OPC")
				dataType = -1;
			else
				dataType = 2004;
			break;
		case DPEL_DYN_FLOAT:  
			if(addressType == "OPC")
				dataType = -1;
			else
				dataType = 2005;
			break;
		default:
			dataType = -1;
			break;
	}
}

/** This function is used to read the address configuration parameters that
can be entered in the panels fwPeriphAddressDIM.pnl and fwPeriphAddressOPC.pnl.
It can be extended to support other address formats.

@par Constraints
	None

@par Usage
	Internal

@par PVSS managers
	VISION

@param referencePanel		the name of the reference panel to read from
@param addressParam			the address parameterization that was entered in the panel
@param exceptionInfo		details of any exceptions are returned here
*/
fwPeriphAddress_readSettings(string referencePanel, dyn_string &addressParam, dyn_string &exceptionInfo)
{
	bool timeStamp, updateOnConnect;
	int driverNumber, timeInterval;
	string addressType, name, server, inGroup, outGroup, defaultValue, dimConfigDp;
	
	getValue(referencePanel + ".addressType", "text", addressType);
		
	// Common parameters
	getValue(referencePanel + ".name", "text", name);
	
	if(strpos(name, " ") >= 0)
	{
		fwException_raise(	exceptionInfo, 
							"ERROR",
							"fwPeriphAddress_readSettings(): The name can not contain the ' ' character",
							"");
		return;
	}
	
	/*if(name == "")
	{
		fwException_raise(	exceptionInfo, 
							"ERROR", 
							"fwPeriphAddress_readSettings(): The name can not be empty",
							"");
		return;
	}*/
	
	// Parameters specific to an address type
	switch(strtoupper(addressType))
	{
		case "OPC":
			getValue(referencePanel + ".driverNumber", "text", driverNumber);
			getValue(referencePanel + ".server", "text", server);
			getValue(referencePanel + ".inGroup", "text", inGroup);
			getValue(referencePanel + ".outGroup", "text", outGroup);

			addressParam[fwDevice_ADDRESS_TYPE]		= fwPeriphAddress_TYPE_OPC;
			addressParam[fwDevice_ADDRESS_DRIVER_NUMBER]	= driverNumber;
			addressParam[fwDevice_ADDRESS_ROOT_NAME]	= name;
			addressParam[fwDevice_ADDRESS_OPC_SERVER_NAME]	= server;
			addressParam[fwDevice_ADDRESS_OPC_GROUP_IN]	= inGroup;
			addressParam[fwDevice_ADDRESS_OPC_GROUP_OUT]	= outGroup;
			break;
		case "DIM":
		
			getValue(referencePanel + ".tStamp", "state", 0, timeStamp);
			getValue(referencePanel + ".dimUpdate", "state", 0, updateOnConnect);			
			getValue(referencePanel + ".dimDefaultValue", "text", defaultValue);			
			getValue(referencePanel + ".dimUpdateInterval", "text", timeInterval);				
			getValue(referencePanel + ".dimConfigDpList", "text", dimConfigDp);				

			addressParam[fwDevice_ADDRESS_TYPE]			= fwPeriphAddress_TYPE_DIM;
			addressParam[fwPeriphAddress_DIM_CONFIG_DP] 		= dimConfigDp;
			addressParam[fwPeriphAddress_DIM_DEFAULT_VALUE] 	= defaultValue;
			addressParam[fwPeriphAddress_DIM_TIMEOUT] 		= timeInterval;
			addressParam[fwPeriphAddress_DIM_FLAG] 			= (int)timeStamp;
			addressParam[fwPeriphAddress_DIM_IMMEDIATE_UPDATE] 	= (int)updateOnConnect;
			addressParam[fwDevice_ADDRESS_ROOT_NAME] 		= name;
			addressParam[fwDevice_ADDRESS_DRIVER_NUMBER] 		= fwPeriphAddress_DIM_DRIVER_NUMBER;
			break;
		default:
			fwException_raise(	exceptionInfo, 
								"ERROR",
								"fwPeriphAddress_readSettings(): " + addressType + " is not a supported address type.", 
								"");
			break;
	}		
}


/** Check if data is Ok to set a MODBUS address

@par Constraints
	None

@par Usage
	Public

@par PVSS managers
	VISION, CTRL

@param dsParameters		parameters used to set the _address config (see constants definition)
@param exceptionInfo	for any error. If a parameter is incorrect, exceptionInfo is not empty !
*/
fwPeriphAddress_checkModbusParameters(dyn_string dsParameters, dyn_string& exceptionInfo)
{
	int driverNum, addressSubindex, mode, intervalTime, dataType, iTemp;
	string active, lowLevel; 
	string addressReference;
	time startingTime;
	dyn_string addressSplit;
	bool badAddress;

	// 1. Length & communication type
	if (dynlen(dsParameters) == FW_PARAMETER_FIELD_NUMBER)
		{
		if (dsParameters[FW_PARAMETER_FIELD_COMMUNICATION] != "MODBUS")
			{
			fwException_raise(exceptionInfo,"ERROR","fwPeriphAddress_checkModbusParameters: " + getCatStr("fwPeriphAddress","MODBUSBADCOMM"),"");
			}
	// 2. Driver number
		if (sscanf(dsParameters[FW_PARAMETER_FIELD_DRIVER], "%d", driverNum) <= 0)
			{
			fwException_raise(exceptionInfo,"ERROR","fwPeriphAddress_checkModbusParameters: " + getCatStr("fwPeriphAddress","MODBUSBADDRIVERNUM"),"");
			}
	// 3. Address reference
		addressReference = dsParameters[FW_PARAMETER_FIELD_ADDRESS];
		addressSplit = strsplit(addressReference, ".");
		badAddress = false;
		if (dynlen(addressSplit) == 4)
			{
			if ((addressSplit[1] != UN_PREMIUM_INPUT_LETTER_EVENT) &&
			    (addressSplit[1] != UN_PREMIUM_INPUT_LETTER_MISC) &&
			    (addressSplit[1] != UN_QUANTUM_INPUT_LETTER_EVENT) &&
			    (addressSplit[1] != UN_QUANTUM_INPUT_LETTER_MISC) &&
			    (addressSplit[1] != UN_PREMIUM_QUANTUM_OUTPUT_LETTER_ALL))	// Letter
				{
				badAddress = true;
				}
			if (sscanf(addressSplit[2], "%d", iTemp) <= 0)	// PLC number
				{
				badAddress = true;
				}
			iTemp = addressSplit[3];
			if ((iTemp != UN_PREMIUM_INPUT_NB_EVENT) &&
			    (iTemp != UN_PREMIUM_INPUT_NB_MISC) &&
			    (iTemp != UN_QUANTUM_INPUT_NB_EVENT) &&
			    (iTemp != UN_QUANTUM_INPUT_NB_MISC) &&
			    (iTemp != UN_PREMIUM_QUANTUM_OUTPUT_NB_ALL))		// Number
				{
				badAddress = true;
				}
			if (sscanf(addressSplit[4], "%d", iTemp) <= 0)	// Address
				{
				badAddress = true;
				}
			}
		else
			{
			badAddress = true;
			}
		if (badAddress)
			{
			fwException_raise(exceptionInfo,"ERROR","fwPeriphAddress_checkModbusParameters: " + getCatStr("fwPeriphAddress","MODBUSBADADDRESS"),"");
			}
		
	// 4. Address subindex
		if (sscanf(dsParameters[FW_PARAMETER_FIELD_SUBINDEX], "%d", addressSubindex) <= 0)
			{
			fwException_raise(exceptionInfo,"ERROR","fwPeriphAddress_checkModbusParameters: " + getCatStr("fwPeriphAddress","MODBUSBADSUBINDEX"),"");
			}
	// 5. Mode
		if (sscanf(dsParameters[FW_PARAMETER_FIELD_MODE], "%d", mode) <= 0)
			{
			fwException_raise(exceptionInfo,"ERROR","fwPeriphAddress_checkModbusParameters: " + getCatStr("fwPeriphAddress","MODBUSBADMODE"),"");
			}
	// 6. Starting time
		//startingTime = dsParameters[FW_PARAMETER_FIELD_START];
	// 7. Interval Time
		if (sscanf(dsParameters[FW_PARAMETER_FIELD_INTERVAL], "%d", intervalTime) <= 0)
			{
			fwException_raise(exceptionInfo,"ERROR","fwPeriphAddress_checkModbusParameters: " + getCatStr("fwPeriphAddress","MODBUSBADINTERVAL"),"");
			}
	// 8. Data type
		if (sscanf(dsParameters[FW_PARAMETER_FIELD_DATATYPE], "%d", dataType) <= 0)
			{
			fwException_raise(exceptionInfo,"ERROR","fwPeriphAddress_checkModbusParameters: " + getCatStr("fwPeriphAddress","MODBUSBADDATATYPE"),"");
			}
	// 9. Address active
		active = dsParameters[FW_PARAMETER_FIELD_ACTIVE];
		if ((active != "FALSE") && (active != "TRUE") && (active != "0") && (active != "1"))
			{
			fwException_raise(exceptionInfo,"ERROR","fwPeriphAddress_checkModbusParameters: " + getCatStr("fwPeriphAddress","MODBUSBADACTIVE"),"");
			}
	// 10. Lowlevel
		lowLevel = dsParameters[FW_PARAMETER_FIELD_LOWLEVEL];
		if ((lowLevel != "FALSE") && (lowLevel != "TRUE") && (lowLevel != "0") && (lowLevel != "1"))
			{
			fwException_raise(exceptionInfo,"ERROR","fwPeriphAddress_checkModbusParameters: " + getCatStr("fwPeriphAddress","MODBUSBADLOWLEVEL"),"");
			}
		}
	else
		{
		fwException_raise(exceptionInfo,"ERROR","fwPeriphAddress_checkModbusParameters: " + getCatStr("fwPeriphAddress","MODBUSBADPARAMNUMBER"),"");
		}
}


/** set MODBUS address

@par Constraints
	. In this function, we suppose that variable dsParameters is well formatted. Before calling this function, it is recommended to 
		check the parameters using the fwPeriphAddress_checkModbusParameters function.
	. In the parameters, the field addressReference could be obtain using fwPeriphAddress_getUnicosAddressReference

@par Usage
	Public

@par PVSS managers
	VISION, CTRL

@param dpe						datapoint element whose address have to be set
@param dsParameters		parameters used to set the _address config (see constants definition)
@param exceptionInfo	for any error...
*/
fwPeriphAddress_setModbus(string dpe, dyn_string dsParameters, dyn_string& exceptionInfo)
{
	int driverNum, addressSubindex, mode, intervalTime, dataType;
	bool active, lowLevel; 
	string addressReference, systemName;
	time startingTime;
	int dir;
	int iRes;
	bool failed = false;
	dyn_errClass error;
	
	// 1. Get input data
	driverNum = dsParameters[FW_PARAMETER_FIELD_DRIVER];
	addressReference = dsParameters[FW_PARAMETER_FIELD_ADDRESS];
	addressSubindex = dsParameters[FW_PARAMETER_FIELD_SUBINDEX];
	mode = dsParameters[FW_PARAMETER_FIELD_MODE];
	startingTime = dsParameters[FW_PARAMETER_FIELD_START];
	intervalTime = dsParameters[FW_PARAMETER_FIELD_INTERVAL];
	dataType = dsParameters[FW_PARAMETER_FIELD_DATATYPE];
	active = dsParameters[FW_PARAMETER_FIELD_ACTIVE];
	lowLevel = dsParameters[FW_PARAMETER_FIELD_LOWLEVEL];
	
	fwGeneral_getSystemName(dpe, systemName, exceptionInfo);
	// 2. Set direction and mode
	dir = mode;

	if(dir == DPATTR_ADDR_MODE_INPUT_POLL)
	{
		if(!dpExists(systemName + dsParameters[fwPeriphAddress_MODBUS_POLL_GROUP]))
		{
			fwException_raise(exceptionInfo, "ERROR", "Polling group does not exist: " + dsParameters[fwPeriphAddress_MODBUS_POLL_GROUP], "");
			return;
		}
	}
	
	if (lowLevel)
		{
		mode = mode + PVSS_ADDRESS_LOWLEVEL_TO_MODE;
		}
	
	// 3. Set _address config
	iRes = dpSetWait(dpe + ":_distrib.._type", DPCONFIG_DISTRIBUTION_INFO,
			 dpe + ":_distrib.._driver", driverNum);
					 
	if (iRes >= 0)
		{
		iRes = -1;
		iRes = dpSetWait(dpe + ":_address.._type", DPCONFIG_PERIPH_ADDR_MAIN,
						 dpe + ":_address.._reference", addressReference,  
						 dpe + ":_address.._subindex", addressSubindex,  
						 dpe + ":_address.._mode", mode,  
						 dpe + ":_address.._start", startingTime,  
						 dpe + ":_address.._interval", intervalTime/1000.0,  
						 dpe + ":_address.._datatype", dataType,  
						 dpe + ":_address.._drv_ident", "MODBUS",
						 dpe + ":_address.._direction", dir,
						 dpe + ":_address.._internal", false,
						 dpe + ":_address.._lowlevel", lowLevel,
						 dpe + ":_address.._poll_group", dsParameters[fwPeriphAddress_MODBUS_POLL_GROUP]);
		error = getLastError();
		if (iRes < 0)
			{
			if (dynlen(error) > 0)
				{
				throwError(error);
				fwException_raise(exceptionInfo,"ERROR","fwPeriphAddress_setModbus: " + getCatStr("fwPeriphAddress","DUPLICATEDADDRESS"),"");
				}				
			}
		else
			{
			if (dynlen(error) > 0)
				{
				throwError(error);
				fwException_raise(exceptionInfo,"ERROR","fwPeriphAddress_setModbus: " + getCatStr("fwPeriphAddress","DUPLICATEDADDRESS"),"");
				}
			else
				{
				iRes = -1;
				iRes = dpSetWait(dpe + ":_address.._active", active);
				if (iRes < 0)
					{
					failed = true;
					}
				}
			}
		}
	else
		{
		failed = true;
		}

	if (failed)
		{
		fwException_raise(exceptionInfo,"ERROR","fwPeriphAddress_setModbus: " + getCatStr("fwPeriphAddress","ERRORSETTINGMODBUS"),"");
		}
}


/** Get formatted address for Unicos using given parameters

@par Constraints
	None

@par Usage
	Public

@par PVSS managers
	VISION, CTRL

@param dsParameters				parameters used to build the address reference (see constants definition)
@param addressReference		address reference (empty string in case of error)
*/
fwPeriphAddress_getUnicosAddressReference(dyn_string dsParameters, string& addressReference)
{
	int mode, iPLCNumber, address;
	string sPLCType;
	bool event;
	bool dataOk = true;
	string temp;
	
	// 1. Check input data
	if (dynlen(dsParameters) == UN_ADDRESS_PARAMETER_FIELD_NUMBER)
		{
		if (sscanf(dsParameters[UN_ADDRESS_PARAMETER_FIELD_MODE], "%d", mode) <= 0)
			{
			dataOk = false;
			}
		sPLCType = dsParameters[UN_ADDRESS_PARAMETER_FIELD_PLCTYPE];
		if ((sPLCType != "QUANTUM") && (sPLCType != "PREMIUM"))
			{
			dataOk = false;
			}
		if (sscanf(dsParameters[UN_ADDRESS_PARAMETER_FIELD_PLCNUMBER], "%d", iPLCNumber) <= 0)
			{
			dataOk = false;
			}
		temp = strtolower(dsParameters[UN_ADDRESS_PARAMETER_FIELD_EVENT]);
		if ((temp != "false") && (temp != "true") && (temp != "0") && (temp != "1"))
			{
			dataOk = false;
			}
		event = dsParameters[UN_ADDRESS_PARAMETER_FIELD_EVENT];
		if (sscanf(dsParameters[UN_ADDRESS_PARAMETER_FIELD_ADDRESS], "%d", address) <= 0)
			{
			dataOk = false;
			}
		}
	else
		{
		dataOk = false;
		}
	
	// 2. Build formatted address
	addressReference = "";
	if (dataOk)
		{
		switch	(mode)
			{
			// Input
			case DPATTR_ADDR_MODE_INPUT_SPONT:
			case DPATTR_ADDR_MODE_INPUT_SQUERY:
			case DPATTR_ADDR_MODE_INPUT_POLL:
				switch (sPLCType)
					{
					case "PREMIUM":
						if (event)
							{
							addressReference = UN_PREMIUM_INPUT_LETTER_EVENT + "." + iPLCNumber + "." + UN_PREMIUM_INPUT_NB_EVENT + "." + address;
							}
						else
							{
							addressReference = UN_PREMIUM_INPUT_LETTER_MISC + "." + iPLCNumber + "." + UN_PREMIUM_INPUT_NB_MISC + "." + address;
							}
						break;
					
					case "QUANTUM":
						if (event)
							{
							addressReference = UN_QUANTUM_INPUT_LETTER_EVENT + "." + iPLCNumber + "." + UN_QUANTUM_INPUT_NB_EVENT + "." + address;
							}
						else
							{
							addressReference = UN_QUANTUM_INPUT_LETTER_MISC + "." + iPLCNumber + "." + UN_QUANTUM_INPUT_NB_MISC + "." + address;
							}
						break;
					
					default:
						break;
					}
				break;
			
			// Output
			case DPATTR_ADDR_MODE_OUTPUT:
			case DPATTR_ADDR_MODE_OUTPUT_SINGLE:
				addressReference = UN_PREMIUM_QUANTUM_OUTPUT_LETTER_ALL + "." +
								   iPLCNumber + "." + 
								   UN_PREMIUM_QUANTUM_OUTPUT_NB_ALL + "." +
								   address;
				break;
			
			// Unknown
			case DPATTR_ADDR_MODE_UNDEFINED:
			default:
				break;
			}
		}
}


/** Checks to see if a given driver manager is running or not

@par Constraints
	None

@par Usage
	Public

@par PVSS managers
	VISION, CTRL

@param driverNumber		the number of the driver to check
@param isRunning			Driver state is returned here - TRUE if manager is running, else FALSE
@param exceptionInfo	if the driver is not running, an exception is returned
@param systemName			OPTIONAL PARAMETER: System name on which to check if the driver is running (e.g. dist_1:).
																					If not passed, the local system is checked.
*/
fwPeriphAddress_checkIsDriverRunning(int driverNumber, bool &isRunning, dyn_string &exceptionInfo, string systemName = "LOCAL")
{
	dyn_bool areRunning;
	
	fwPeriphAddress_checkAreDriversRunning(makeDynInt(driverNumber), areRunning, exceptionInfo, systemName);
	
	isRunning = areRunning[1];
}


/** Checks to see if a given list of driver managers are running or not

@par Constraints
	None

@par Usage
	Public

@par PVSS managers
	VISION, CTRL

@param driverNumbers	the numbers of the drivers to check
@param areRunning			A list of the driver states is returned here - TRUE if manager is running, else FALSE
@param exceptionInfo	if the driver is not running, an exception is returned
@param systemName			OPTIONAL PARAMETER: System name on which to check if the drivers are running (e.g. dist_1:).
																					If not passed, the local system is checked.
*/
fwPeriphAddress_checkAreDriversRunning(dyn_int driverNumbers, dyn_bool &areRunning, dyn_string &exceptionInfo, string systemName = "LOCAL")
{
	int i, length;
	dyn_int manNums, badNums; 
	string errorString;

	if(systemName == "LOCAL")
		systemName = getSystemName();

	dpGet(systemName + "_Connections.Driver.ManNums", manNums);
	
	areRunning = makeDynBool();
	
	if(dynIntersect(manNums, driverNumbers) == driverNumbers) 
	{
		length = dynlen(driverNumbers);
		for(i=1; i<=length; i++)
			areRunning[i] = TRUE;
	}
	else 
	{
		length = dynlen(driverNumbers);
		for(i=1; i<=length; i++)
		{
			if(dynContains(manNums, driverNumbers[i]) > 0)
				areRunning[i] = TRUE;
			else
				areRunning[i] = FALSE;
		}
	}
}


/** Creates the necessary PVSS internal data for a given driver number.
These are "_DriverX" and "_Stat_Configs_driver_X" where X is the driver number.

@par Constraints
	The driver number must be between 1 and 254 (PVSS limitation on driver numbers)

@par Usage
	Public

@par PVSS managers
	VISION, CTRL

@param driverNumber	The driver number for which you wish to create the internal PVSS dps
@param exceptionInfo	Details of any exceptions are returned here
*/
fwPeriphAddress_createPvssInternalDpsForDriver(unsigned driverNumber, dyn_string &exceptionInfo)
{
	string driverCommonDp, driverStatsDp;

	if((driverNumber >= 255) || (driverNumber < 1))
	{
		fwException_raise(exceptionInfo, "ERROR", "The driver number must be between 1 and 254.", "");
		return;
	}
	
	driverCommonDp = "_Driver" + driverNumber;
	driverStatsDp = "_Stat_Configs_driver_" + driverNumber;

	if(!dpExists(driverCommonDp))
		dpCreate(driverCommonDp, "_DriverCommon");
	else if(dpTypeName(driverCommonDp) != "_DriverCommon")
		fwException_raise(exceptionInfo, "ERROR", "The data point \""
																+ driverCommonDp + "\" exists already but is of the wrong data point type", "");
																
	if(!dpExists(driverStatsDp))
		dpCreate(driverStatsDp, "_Statistics_DriverConfigs");
	else if(dpTypeName(driverStatsDp) != "_Statistics_DriverConfigs")
		fwException_raise(exceptionInfo, "ERROR", "The data point \""
																+ driverStatsDp + "\" exists already but is of the wrong data point type", "");
}

/** Changes the OPC group in the address config for the given list of dpes

@par Constraints
	The relevant SIM Manager or Driver must be running to access the address configs

@par Usage
	Public

@par PVSS managers
	VISION, CTRL

@param dpes			The list of dpes to act on
@param newGroupName	The new OPC server group name
@param exceptionInfo	Details of any exceptions are returned here
*/
fwPeriphAddress_changeOpcGroups(dyn_string dpes, string newGroupName, dyn_string &exceptionInfo)
{
	int i, j, numberOfTypes, numberOfDpes;
	dyn_string references, driverTypes, referenceParts, newReference;

	//get the driver types of all the dpes
	_fwConfigs_getConfigTypeAttribute(dpes, fwConfigs_PVSS_ADDRESS, driverTypes, exceptionInfo, ".._drv_ident");

	//if not all OPCCLIENT then give exception
	//also if some addresses do not exist, driverTypes is empty so also give exception
	numberOfTypes = dynUnique(driverTypes);	
	if((numberOfTypes == 1) && (driverTypes[1] == fwPeriphAddress_TYPE_OPCCLIENT))
	{
		//read current OPC address references
		_fwConfigs_getConfigTypeAttribute(dpes, fwConfigs_PVSS_ADDRESS, references, exceptionInfo, ".._reference");
	}
	else
	{
		fwException_raise(exceptionInfo, "ERROR", "Not all the data point elements have accessible OPC addresses. "
																							+ "No change was made to the OPC groups.", "");
	}
	
	if(dynlen(exceptionInfo) > 0)
		return;
	
	//go through all references to changes OPC group
	numberOfDpes = dynlen(references);
	for(i=1; i<=numberOfDpes; i++)
	{
		referenceParts = strsplit(references[i], "$");
		referenceParts[2] = newGroupName;
		
		newReference = "";
		for(j=1; j<dynlen(referenceParts); j++)
			newReference += referenceParts[j] + "$";
		newReference += referenceParts[j];
		
		references[i] = newReference;
	}
	
	//save new OPC groups
	_fwConfigs_setConfigTypeAttribute(dpes, fwConfigs_PVSS_ADDRESS, references, exceptionInfo, ".._reference");
}
//@}


