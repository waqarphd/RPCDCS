
/**@file
********************************************************************************
This library contains function associated with S7 addressing.
Functions are provided to set, get and delete the addressing for a dpe

@par Creation Date
	24/04/2005

@par Modification History

  12/11/2012 Marco Boccioli
	- @jira{FWCORE-3101} : Modified line on _fwPeriphAddressS7_set() : 
	if(strlen(pollGroup) && strpos(pollGroup,"_")!=0) pollGroup = "_"+pollGroup;

  13/09/2011 Marco Boccioli
  - @sav{49981}: Poll groups for S7 driver: inconsistency in poll group name. 
    On _fwPeriphAddressS7_set(), the leading "_" is now added automatically if not specified.
	
@par Constraints
	None	

@par Usage
	Public

@par PVSS managers
	VISION, CTRL

@author 
	Enrique BLANCO (AB-CO)

********************************************************************************
*/

// ================================================================


//@{
//definition of constants
const string fwPeriphAddress_TYPE_S7 = "S7";

const unsigned fwPeriphAddress_S7_LOWLEVEL	= 11;
const unsigned fwPeriphAddress_S7_SUBINDEX = 12; 
const unsigned fwPeriphAddress_S7_START = 13;
const unsigned fwPeriphAddress_S7_INTERVAL = 14;
const unsigned fwPeriphAddress_S7_POLL_GROUP = 15;

const string UN_S7_FORMAT_BIT = "DBX";		// bit format
const string UN_S7_FORMAT_BYTE = "DBB";		// byte format
const string UN_S7_FORMAT_WORD = "DBW";   // word format
const string UN_S7_FORMAT_DOUBLE = "DBD"; // double format 

// Mode (existing in PVSS)
//DPATTR_ADDR_MODE_INPUT_POLL
const unsigned UN_S7_ADDR_MODE_INOUT_TSPP = 6;
const unsigned UN_S7_ADDR_MODE_INOUT_POLL = 7;	// IN/OUT polling
const unsigned UN_S7_ADDR_MODE_INOUT_SQ = 8;

// PLC S7 Communication internal data points
// "_S7_Config" is defined in the UNICOS lib: _S7Config_PLC.ctl
const string S7_PLC_INT_DPTYPE_CONN = "_S7_Conn";

//@}

//@{
/** Set the S7 addressing
Note: This function should not be called directly.  Call the fwPeriphAddress_set instead.

@par Constraints
	None

@par Usage
	Internal

@par PVSS managers
	VISION, CTRL

@param dpe						input, data point element to configure
@param addressConfig	input, object containing address configuration details
@param exceptionInfo	output, details of any exceptions are returned here
*/
_fwPeriphAddressS7_set(string dpe, dyn_anytype addressConfig, dyn_string &exceptionInfo)
{
	dyn_errClass errors;

	int driverNum, addressSubindex, mode, intervalTime, dataType;
	bool active, lowLevel; 
	string addressReference,typeDriver, pollGroup,sSystemName;
	time startingTime;
	int dir;
	int iRes;
	bool failed = false;
	dyn_errClass error;
	
	// DebugN("FUNCTION: _fwPeriphAddressS7_set");
	// DebugN("--------------------------------");
	// DebugN(dpe, addressConfig);
	// DebugN("--------------------------------");
	fwGeneral_getSystemName(dpe, sSystemName, exceptionInfo);
	if(sSystemName == "") sSystemName = getSystemName();
	
	// 1. Get input data
	driverNum = addressConfig[FW_PARAMETER_FIELD_DRIVER];
	addressReference = addressConfig[FW_PARAMETER_FIELD_ADDRESS];
	addressSubindex = addressConfig[FW_PARAMETER_FIELD_SUBINDEX];
	mode = addressConfig[FW_PARAMETER_FIELD_MODE];
	startingTime = addressConfig[FW_PARAMETER_FIELD_START];
	intervalTime = addressConfig[FW_PARAMETER_FIELD_INTERVAL];
	dataType = addressConfig[FW_PARAMETER_FIELD_DATATYPE];
	active = addressConfig[FW_PARAMETER_FIELD_ACTIVE];
	lowLevel = addressConfig[FW_PARAMETER_FIELD_LOWLEVEL];
	typeDriver = addressConfig[fwPeriphAddress_TYPE];
	pollGroup = addressConfig[fwPeriphAddress_S7_POLL_GROUP];
  if(strlen(pollGroup) && strpos(pollGroup,"_")!=0) pollGroup = "_"+pollGroup;
	
	//2. Check contents of addressConfig is consistent/coherent plus any data manipulation
	fwPeriphAddress_checkS7Parameters(addressConfig, exceptionInfo);
	
	dir = mode;
	if ((dir == DPATTR_ADDR_MODE_INPUT_POLL) || 
			(dir == UN_S7_ADDR_MODE_INOUT_POLL))
		{
			if(!dpExists(sSystemName+pollGroup))
			{
				fwException_raise(exceptionInfo, "ERROR", "Polling group does not exist: " + addressConfig[fwPeriphAddress_S7_POLL_GROUP], "");
				return;
			}
		}
	
	if (lowLevel)
		{
		mode = mode + PVSS_ADDRESS_LOWLEVEL_TO_MODE;
		}
	
	//3. Set the distrib config	and driver number
	//The driver will already have been checked to see that it is running, so just dpSetWait
	dpSetWait(dpe + ":_distrib.._type", DPCONFIG_DISTRIBUTION_INFO,
						dpe + ":_distrib.._driver", driverNum);
	errors = getLastError(); 
  if(dynlen(errors) > 0)
  { 
		throwError(errors);
		fwException_raise(exceptionInfo, "ERROR", "Could not create the distrib config.", "");
		return;
	}

	//4. Set the addressConfig data to the config
	dpSetWait(dpe + ":_address.._type", DPCONFIG_PERIPH_ADDR_MAIN,
						 dpe + ":_address.._reference", addressReference, 
						 dpe + ":_address.._subindex", addressSubindex,  
						 dpe + ":_address.._mode", mode,  
						 dpe + ":_address.._start", startingTime,  
						 dpe + ":_address.._interval", intervalTime/1000.0,  
						 dpe + ":_address.._datatype", dataType,  
						 dpe + ":_address.._drv_ident", typeDriver,
						 dpe + ":_address.._direction", dir,
						 dpe + ":_address.._internal", false,
						 dpe + ":_address.._lowlevel", lowLevel,
						 dpe + ":_address.._poll_group", pollGroup,
						 dpe + ":_address.._active", active);  //active
							
						
	errors = getLastError(); 
  if(dynlen(errors) > 0)
  { 
		throwError(errors);
		fwException_raise(exceptionInfo, "ERROR", "Could not set the " + fwPeriphAddress_TYPE_S7 + " address config.", "");
	}
}

/** Check if data is Ok to set a S7 address

@par Constraints
	None

@par Usage
	Public

@par PVSS managers
	VISION, CTRL

@param dsParameters		parameters used to set the _address config (see constants definition)
@param exceptionInfo	for any error. If a parameter is incorrect, exceptionInfo is not empty !
*/

fwPeriphAddress_checkS7Parameters(dyn_string dsParameters, dyn_string &exceptionInfo)
{
	int driverNum, addressSubindex, mode, intervalTime, dataType, iTemp;
	string active, lowLevel; 
	string addressReference;
	time startingTime;
	dyn_string addressSplit;
	bool badAddress;

	int tot_len; 
	string formatS7,lastF;
	string zoneS7,sizeS7;	
	int numberS7;

	// DebugN("FUNCTION: fwPeriphAddress_checkS7Parameters");
	// DebugN("--------------------------------");
	// DebugN(dsParameters);
	// DebugN("--------------------------------");

	// 1. Length & communication type
	if (dynlen(dsParameters) == FW_PARAMETER_FIELD_NUMBER)
		{
		if (dsParameters[FW_PARAMETER_FIELD_COMMUNICATION] != "S7")
			{
			fwException_raise(exceptionInfo,"ERROR","fwPeriphAddress_checkS7Parameters: " + getCatStr("fwPeriphAddressS7","S7BADCOMM"),"");
			}
	
	// 2. Driver number
		if (sscanf(dsParameters[FW_PARAMETER_FIELD_DRIVER], "%d", driverNum) <= 0)
			{
			fwException_raise(exceptionInfo,"ERROR","fwPeriphAddress_checkS7Parameters: " + getCatStr("fwPeriphAddressS7","S7BADDRIVERNUM"),"");
			}
		
	// 3. Address reference
		addressReference = dsParameters[FW_PARAMETER_FIELD_ADDRESS];
		addressSplit = strsplit(addressReference, ".");
		badAddress = false;
		
		// DebugN("addressSplit #= "+dynlen(addressSplit));
		
		switch (dynlen(addressSplit))
		{
			case 4:						// case DBx.DBXy.z  (z=bit; checking bit)
					if (sscanf(addressSplit[4],"%d",iTemp)<=0)
						badAddress=true;
					if (iTemp <0 || iTemp >7)
							{
							badAddress=true;
							// DebugN("case DBx.DBXy.z , z<0 or z>7, z= ",iTemp);
							}
					// third group must be DBXnnnn, therefore at least 4 characters
					tot_len=strlen(addressSplit[3]);
					
					// DebugN("third group length = ",tot_len);
					
					if (tot_len <4)
						badAddress=true;							
					else 
						{
						formatS7=substr(addressSplit[3], 0, 3);
						// DebugN("third group format ="+formatS7);
						if (formatS7 == UN_S7_FORMAT_BIT)
							{
							if(sscanf(substr(addressSplit[3], 3, tot_len-3), "%d", numberS7) <=0)								
								badAddress=true;
							// DebugN("third group address ="+numberS7);
							if ((numberS7 < 0) || (numberS7 > 65535))
								badAddress=true;		
							}
						}
					// second group (it must be DBx where x=[0..65535]
						tot_len=strlen(addressSplit[2]);
						// DebugN("second group length = ",tot_len);
						if (tot_len >=3)
							{
								if (substr(addressSplit[2], 0, 2) !="DB")
										badAddress=true;
								else
										{	
										 if(sscanf(substr(addressSplit[2], 2, tot_len-2), "%d", numberS7) <=0)								
												badAddress=true;
										 // DebugN("second group DB number ="+numberS7);
										 if ((numberS7 < 1) || (numberS7 > 32767))
										 		badAddress=true;
										 }
							}
						else 
							badAddress=true;
					
					break;
					
			case 3:					 // if length >1 then length must be greater than 3
											 // 						 and the 3 first char must be of the type: DBX,DBB,DBW,DBD		
											 //							 the last char could be "F"
						 tot_len=strlen(addressSplit[3]);				// gets third parameter length	
						 
						 // DebugN("third group length = ",tot_len);
						 
						 if (tot_len == 1)							// length =1   (is always a BIT description)			
						 		{
						 			if(sscanf(addressSplit[3],"%d",iTemp) <=0)								
											badAddress=true;
						 			else if (iTemp <0 || iTemp >7)			// is bit correct format?
											badAddress=true;
									else 													// being a bit, in the second parameter must beInput,Output, Memory
											{
											zoneS7=substr(addressSplit[2], 0, 1);
											// DebugN("zoneS7 ="+ zoneS7);
											if ((zoneS7=="I" || zoneS7=="E" || zoneS7 =="Q" || zoneS7 =="A" || zoneS7 =="M") && (strlen(addressSplit[2]) >=2))		// Periphery Input or Output
												{
													if(sscanf(substr(addressSplit[2], 1, strlen(addressSplit[2])-1), "%d", numberS7) <=0)								
														badAddress=true;									
													if ((numberS7 < 0) || (numberS7 > 65535))
														badAddress=true;
														
													// DebugN("numberS7= "+numberS7);
												}
											else 
												badAddress=true;
											}
								  // DebugN("case bit, value= "+iTemp);
								}
						 else	if (tot_len < 10) 				// length >1 and <10   (first 3 char must be of the type: DBX,DBB,DBW,DBD)
						 	{
						 			formatS7=substr(addressSplit[3], 0, 3);
						 			
						 			// DebugN("formatS7 ="+ formatS7);
						 			
						 			if ((formatS7 != UN_S7_FORMAT_BYTE) &&
						 					(formatS7 != UN_S7_FORMAT_WORD) &&
						 					(formatS7 != UN_S7_FORMAT_DOUBLE))
						 				{
						 					// DebugN("format different to"+UN_S7_FORMAT_WORD+","+UN_S7_FORMAT_DOUBLE+"...");
						 					badAddress=true;
						 				}	
						 			else			// Ok with format DBB, DBX, DBW, DBD, DBDyF
						 				{
						 				lastF=substr(addressSplit[3], tot_len-1, 1);		// gets the possible "F" at the end 	
						 				// DebugN("lastF= "+lastF);
						 				if (lastF=="F")
						 					{
						 					if(sscanf(substr(addressSplit[3], 3, tot_len-4), "%d", numberS7) <=0)								
													badAddress=true;
											}
						 				else
						 					{
											if(sscanf(substr(addressSplit[3], 3, tot_len-3), "%d", numberS7) <=0)								
													badAddress=true;									
											}
										if ((numberS7 < 0) || (numberS7 > 65535))
												badAddress=true;
												
										// checking what is in the second group (it must be DBx where x=[0..32767]
										 tot_len=strlen(addressSplit[2]);
										 // DebugN("tot_len= "+tot_len);
										 if (tot_len >=3)
										 		{
										 		if (substr(addressSplit[2], 0, 2) !="DB")
										 				badAddress=true;
										 		else
										 			{	
										 				if(sscanf(substr(addressSplit[2], 2, tot_len-2), "%d", numberS7) <=0)								
																badAddress=true;
														if ((numberS7 < 1) || (numberS7 > 32767))
															badAddress=true;
										 			}
										 		}				
										}
						 	}
						 else																									// length greater than 9 chars
						 			badAddress = true;	 			
				
					break;
					
			case 2:				// ATTENTION: Case SYMBOLIC ADDRESS is not taken into account as valid
			
						zoneS7=substr(addressSplit[2], 0, 1);		// must be M,I,Q,T,Z				
						tot_len=strlen(addressSplit[2]);				// gets second parameter length 
						
						lastF=substr(addressSplit[2], tot_len-1, 1);		// gets the possible "F" at the end 
						sizeS7=substr(addressSplit[2], 1, 1);						// gets the possible "B,W,D" of second char
						
						// DebugN("zoneS7= "+zoneS7+" tot_len= "+tot_len+" lastF= "+lastF+" sizeS7= "+sizeS7);
						
						// ------------------------------------------------------------------
						if (lastF=='F' && tot_len >=4)				//case MDyF where y represents the numberS7
							{
							if (substr(addressSplit[2], 0, 2) !="MD")
								badAddress=true;
							else 
								{
									if(sscanf(substr(addressSplit[2], 2, tot_len-3), "%d", numberS7) <=0)								
											badAddress=true;
									if ((numberS7 < 0) || (numberS7 > 65535))
											badAddress=true;
								}		
							// DebugN("numberS7 (address)= "+numberS7);
							}
						// -------------------------------------------------------------------
						else if ((zoneS7=="T" || zoneS7 =="Z") && (tot_len >=2))	// Timer or Counter
							{
								if(sscanf(substr(addressSplit[2], 1, tot_len-1), "%d", numberS7) <=0)								
									badAddress=true;									
								if ((numberS7 < 0) || (numberS7 > 127))
									badAddress=true;	 
									
							// DebugN("numberS7 (address)= "+numberS7);	
							}
						// --------------------------------------------------------------------
						else if ((zoneS7=="I" || zoneS7 =="Q" || zoneS7=="A" || zoneS7 =="E") && (tot_len >=3))		// Periphery Input or Output
							{
								sizeS7=substr(addressSplit[2], 1, 1);
								if (sizeS7 !="B" && sizeS7 != "W")
									badAddress=true;
								if(sscanf(substr(addressSplit[2], 2, tot_len-1), "%d", numberS7) <=0)								
										badAddress=true;									
								if ((numberS7 < 0) || (numberS7 > 65535))
									badAddress=true;
								
								// DebugN("sizeS7 = "+sizeS7);
								// DebugN("numberS7 (address)= "+numberS7);
							}
						// ---------------------------------------------------------------------
						else if (zoneS7=="M" && tot_len >=2)										// memory (without "F" at the end)
							{					
								// First case MBxxxxx, MWxxxxx,MDxxxxx (where xxxxx can be 0, to 65535)
								if (sizeS7 =="B" || sizeS7 == "W" || sizeS7 =="D")
									{

									if(sscanf(substr(addressSplit[2], 2, tot_len-2), "%d", numberS7) <=0)								
											badAddress=true;
									if ((numberS7 < 0) || (numberS7 > 65535))
											badAddress=true;
									}
								// No other options allowed
								else 
									badAddress=true;

								// DebugN("sizeS7 = "+sizeS7);
								// DebugN("numberS7 (address)= "+numberS7);
								}	
						// ---------------------------------------------------------------------	
						else			// Here the SYMBOL case must be coded   
							{
								// default
								badAddress = true;
								DebugN("Attention: This is the case of a SYMBOL (still now allowed  !!!!");
							}	
					
						break;	
						
			// Bad composition of the reference			 
			default:   	
				badAddress = true;
				// DebugN("default general..");
		}
				
		if (badAddress)
			{
			// DebugN("bad address= "+badAddress+ " fwException_raise ");	
			fwException_raise(exceptionInfo,"ERROR","fwPeriphAddress_checkS7Parameters: " + getCatStr("fwPeriphAddressS7","S7BADADDRESS"),"");
			}
	// 4  Subindex
	
	// 5. Mode
		if (sscanf(dsParameters[FW_PARAMETER_FIELD_MODE], "%d", mode) <= 0)
			{
			fwException_raise(exceptionInfo,"ERROR","fwPeriphAddress_checkS7Parameters: " + getCatStr("fwPeriphAddressS7","S7BADMODE"),"");
			}
	// 6. Starting time
		//startingTime = dsParameters[FW_PARAMETER_FIELD_START];
	// 7. Interval Time
	//	if (sscanf(dsParameters[FW_PARAMETER_FIELD_INTERVAL], "%d", intervalTime) <= 0)
	//		{
	//		fwException_raise(exceptionInfo,"ERROR","fwPeriphAddress_checkS7Parameters: " + getCatStr("fwPeriphAddressS7","S7BADINTERVAL"),"");
	//		}
	// 8. Data type
		if (sscanf(dsParameters[FW_PARAMETER_FIELD_DATATYPE], "%d", dataType) <=0)
			{
			fwException_raise(exceptionInfo,"ERROR","fwPeriphAddress_checkS7Parameters: " + getCatStr("fwPeriphAddressS7","S7BADDATATYPE"),"");
			}
		if (dataType < 700 || dataType > 708)
			{
			fwException_raise(exceptionInfo,"ERROR","fwPeriphAddress_checkS7Parameters: " + getCatStr("fwPeriphAddressS7","S7BADDATATYPE"),"");
			}
	// 9. Address active
		active = dsParameters[FW_PARAMETER_FIELD_ACTIVE];
		if ((active != "FALSE") && (active != "TRUE") && (active != "0") && (active != "1"))
			{
			fwException_raise(exceptionInfo,"ERROR","fwPeriphAddress_checkS7Parameters: " + getCatStr("fwPeriphAddressS7","S7BADACTIVE"),"");
			}
	// 10. Lowlevel
		lowLevel = dsParameters[FW_PARAMETER_FIELD_LOWLEVEL];
		if ((lowLevel != "FALSE") && (lowLevel != "TRUE") && (lowLevel != "0") && (lowLevel != "1"))
			{
			fwException_raise(exceptionInfo,"ERROR","fwPeriphAddress_checkS7Parameters: " + getCatStr("fwPeriphAddressS7","S7BADLOWLEVEL"),"");
			}
		}
	else
		{
		fwException_raise(exceptionInfo,"ERROR","fwPeriphAddress_checkS7Parameters: " + getCatStr("fwPeriphAddressS7","S7BADPARAMNUMBER"),"");
		}
}


/** Get the S7 addressing
Note: This function should not be called directly.  Call the fwPeriphAddress_get instead.

@par Constraints
	None

@par Usage
	Internal

@par PVSS managers
	VISION, CTRL

@param dpe						input, data point element to read
@param addressConfig	output, object containing address configuration details
@param isActive		output, TRUE is addressing is active, else FALSE
@param exceptionInfo	output, details of any exceptions are returned here
*/
_fwPeriphAddressS7_get(string dpe, dyn_anytype &addressConfig, bool &isActive, dyn_string &exceptionInfo)
{
	// DebugN("FUNCTION: _fwPeriphAddressS7_get");
	// DebugN("--------------------------------");
	// DebugN(dpe,addressConfig,isActive); 
	// DebugN("--------------------------------");
	int					iDriver, iDirection;
	
	//1. Get the driver number and address config contents
	//It will already be known that the config exists so you can just do dpGet
	dpGet(		dpe + ":_address.._drv_ident", addressConfig[fwPeriphAddress_TYPE],
						dpe + ":_distrib.._driver", iDriver,
						dpe + ":_address.._reference", addressConfig[fwPeriphAddress_REFERENCE],
						// dpe + ":_address.._mode", addressConfig[fwPeriphAddress_DIRECTION],
						dpe + ":_address.._direction", iDirection,
				 		dpe + ":_address.._start", addressConfig[fwPeriphAddress_S7_START],
				 		dpe + ":_address.._interval",addressConfig[fwPeriphAddress_S7_INTERVAL],
				 		dpe + ":_address.._datatype", addressConfig[fwPeriphAddress_DATATYPE], 
				 		dpe + ":_address.._subindex", addressConfig[fwPeriphAddress_S7_SUBINDEX],
				 		dpe + ":_address.._poll_group", addressConfig[fwPeriphAddress_S7_POLL_GROUP],
						dpe + ":_address.._lowlevel",addressConfig[fwPeriphAddress_S7_LOWLEVEL],
						dpe + ":_address.._active", addressConfig[fwPeriphAddress_ACTIVE]);

	addressConfig[fwPeriphAddress_DRIVER_NUMBER]=iDriver;
	addressConfig[fwPeriphAddress_DIRECTION]=iDirection;
	
	//2. Do any necessary manipulation of the data that was read 				
	// DebugN("_fwPeriphAddressS7_get() ...> addressConfig= ",addressConfig);
	//3. Set the isActive value - by default this will be the same as addressConfig[fwPeriphAddress_ACTIVE]
	isActive = addressConfig[fwPeriphAddress_ACTIVE];
}

/** Delete the S7 addressing
Note: This function should not be called directly.  Call the fwPeriphAddress_delete instead.

@par Constraints
	None

@par Usage
	Internal

@par PVSS managers
	VISION, CTRL

@param dpe						input, data point element to configure
@param exceptionInfo	output, details of any exceptions are returned here
*/
_fwPeriphAddressS7_delete(string dpe, dyn_string &exceptionInfo)
{
	//1. If only the address and distrib config need deleting then do nothing here.
	//NOTE: This function is called BEFORE the address config is deleted.
	// DebugN("FUNCTION: _fwPeriphAddressS7_delete");
	// DebugN("--------------------------------");
	// DebugN(dpe); 
	// DebugN("--------------------------------");
}


/** Initialise the graphics of the address panel symbol.
Note: This function should only be called from fwPeriphAddres.pnl.

@par Constraints
	None

@par Usage
	Internal

@par PVSS managers
	VISION

@param dpe						input, data point element to configure
@param exceptionInfo	output, details of any exceptions are returned here
*/
_fwPeriphAddressS7_initPanel(string dpe, dyn_string &exceptionInfo)
{

	int i;
	
	bool configExists, isActive;
	dyn_anytype addressConfig;

	string transf_ini="default"; 	// transformation mode
	int dirMode_ini=1;	 // directionMode
	int recMode_ini=1;   // receiveMode
	bool active_ini=1;		// active
  bool lowlevel_ini=0;	// lowlevel
	string pollGroup_ini="";
	string reference1_ini;		// only possible ini afterwards
	string reference2_ini="MW0";
	int driverNum_ini=2;
	string sSystemName;
	dyn_string s7Connections; // available S7 connections already defined
	dyn_string dsPlc;
	
	// DebugN("FUNCTION: _fwPeriphAddressS7_initPanel");
	// DebugN("--------------------------------");
	// DebugN(dpe); 
	// DebugN("--------------------------------");
	
	fwGeneral_getSystemName(dpe, sSystemName, exceptionInfo);
	if(sSystemName == "") sSystemName = getSystemName();

	//1. Get the current config
	fwPeriphAddress_get(dpe, configExists, addressConfig, isActive, exceptionInfo);
	if(dynlen(exceptionInfo)>0)
		return;

	dsPlc = dpNames(sSystemName+"*","_PollGroup");
	for ( i = dynlen(dsPlc); i > 0; i-- )
  {
    // don't display redundant datapoints
    if ( i > 1 &&
         strpos(dsPlc[i],"_2") == strlen(dsPlc[i]) - 2 &&
         dsPlc[i] == dsPlc[i-1] + "_2"
       )
    {
      dynRemove(dsPlc, i);
    }

//    if ( dpSubStr(dsPlc[i],DPSUB_SYS) == "System1:" ) // NoCheckWarning
    if ( i <= dynlen(dsPlc) )
    {
      dsPlc[i] = dpSubStr(dsPlc[i],DPSUB_DP);
      if ( dsPlc[i][0] == "_" )
        dsPlc[i] = substr(dsPlc[i], 1, strlen(dsPlc[i])-1);
    }
  }
  cmbPollGroupS7.items = dsPlc;
  
	if(configExists && addressConfig[fwPeriphAddress_TYPE] == fwPeriphAddress_TYPE_S7) 
	{
		//2. If the config exists, and it is of the required addressing type, display the current information
		// DebugN("FUNCTION: CONFIG EXISTS !!!! _fwPeriphAddressS7_initPanel: configtype= "+addressConfig[fwPeriphAddress_TYPE]);
// 		if(addressConfig[fwPeriphAddress_TYPE] == fwPeriphAddress_TYPE_S7)
//			{	
				switch(addressConfig[fwPeriphAddress_DATATYPE])
					{
						case 700: transf_ini="default"; break;
						case 701: transf_ini="int 16"; break; 
      	    case 702: transf_ini="int 32"; break;  
      	    case 703: transf_ini="uint 16"; break;  
      	    case 704: transf_ini="byte"; break;  
      	    case 705: transf_ini="float";   break; 
      	    case 706: transf_ini="boolean";   break; 
      	    case 707: transf_ini="string"; break;
      	    case 708: transf_ini="uint 32"; break;  
      	    default:  transf_ini="default"; 
					 }		
				
				// DebugN("dataType= "+transf_ini);
				switch (addressConfig[fwPeriphAddress_DIRECTION])
					{
						case DPATTR_ADDR_MODE_OUTPUT:	dirMode_ini=0;	
																					break;										
						case DPATTR_ADDR_MODE_INPUT_SPONT: dirMode_ini=1;
																							 recMode_ini=0;
																							 break;
						case DPATTR_ADDR_MODE_INPUT_POLL: 	dirMode_ini=1;
																							 	recMode_ini=1;
																							 	break;																	 
				    case DPATTR_ADDR_MODE_INPUT_SQUERY: dirMode_ini=1;
																							 	recMode_ini=2;
																							 	break;
						case 6: dirMode_ini=2;
										recMode_ini=0;
									  break;
						case 7: dirMode_ini=2;
										recMode_ini=1;
									  break;
						case 8: dirMode_ini=2;
										recMode_ini=2;
									  break;																	 										  
						case DPATTR_ADDR_MODE_UNDEFINED: dirMode_ini=0;
																						 break;
						default: dirMode_ini=0;					
					}
				
				// DebugN("dirMode_ini= "+dirMode_ini+" recMode_ini= "+recMode_ini);
				// Active 	
				// active_ini=addressConfig[fwPeriphAddress_ACTIVE];		
				active_ini=isActive;
				// Lowlevel
				lowlevel_ini=addressConfig[FW_PARAMETER_FIELD_LOWLEVEL];
				
				// DebugN("active_ini= "+active_ini+" lowlevel_ini= "+lowlevel_ini);
				// driver number
				driverNum_ini=addressConfig[fwPeriphAddress_DRIVER_NUMBER];
				// DebugN("--> Driver number (Existing) = "+driverNum_ini);
				
				// poll group 
				pollGroup_ini=addressConfig[fwPeriphAddress_S7_POLL_GROUP];
				if (strlen(pollGroup_ini)>0)
					pollGroup_ini = substr(pollGroup_ini,1, strlen(pollGroup_ini)-1);
//				DebugN("driverNum_ini= "+driverNum_ini+" pollGroup_ini= "+pollGroup_ini);
				
				// Reference:  Format: S7conn.reference  : i.e.: S7_PLC1.DB20.DBW10
				reference1_ini=substr(addressConfig[fwPeriphAddress_REFERENCE],0,strpos(addressConfig[fwPeriphAddress_REFERENCE],"."));
				reference2_ini=substr(addressConfig[fwPeriphAddress_REFERENCE],strpos(addressConfig[fwPeriphAddress_REFERENCE],".")+1);
				// DebugN("reference1_ini= "+reference1_ini);
				// DebugN("reference2_ini= "+reference2_ini);
				
				// Initial values get from provided DPE
        setMultiValue("s7ConnNames","text",reference1_ini,
        							"directionModeS7","number",dirMode_ini,
                    	"receiveMode", "number", recMode_ini,     
                    	"lowlevelS7","state",0,lowlevel_ini,
                    	"addressActiveS7","state",0,active_ini,
                    	"driverNumberSelectorS7","text",driverNum_ini,
                    	"cmbPollGroupS7", "text",pollGroup_ini,
                    	"trans_art","text", transf_ini);
                    	
        setValue("var_name", "text", s7ConnNames.text +"."+reference2_ini);   		  
			  // DebugN("var_name= "+s7ConnNames.text +"."+reference2_ini);
			  
			  
			  
				// just set the S7 values
  			reference2_ini = _fwPeriphAddressS7_setValuesFromRef(reference2_ini,sSystemName);  	
	}
	else
	{
		//3. If the config does not exist, set a clean default for the user to start entering data
		// DebugN("FUNCTION: _fwPeriphAddressS7_initPanel: config type does not exists");
		// look for the defined S7 connections
		s7Connections = dpNames(sSystemName+"*", S7_PLC_INT_DPTYPE_CONN);
    for ( i = dynlen(s7Connections); i > 0; i-- )
      {
        // don't display redundant datapoints
        if ( isReduDp( s7Connections[i] ))
        {
          dynRemove(s7Connections, i);
        }
      }
     if ( dynlen(s7Connections) > 0 )
        for ( i = 1; i <= dynlen(s7Connections); i++ )
        {
          s7Connections[i] = dpSubStr(s7Connections[i], DPSUB_DP);
          s7Connections[i] = substr(s7Connections[i], 1, strlen(s7Connections[i]) - 1);
        }
		else
     	{
        fwException_raise(exceptionInfo,"WARNING","fwPeriphAddress_checkS7Parameters: " + getCatStr("fwPeriphAddressS7","S7NOTDEFCONNS"),"");
        // DebugN("No S7 Connection defined, please define it before....");
      }  
      
    // Set 
		// Initial values get from provided DPE
  	setMultiValue("directionModeS7","number",dirMode_ini,
               		"receiveMode", "number", recMode_ini,     
               		"lowlevelS7","state",0,lowlevel_ini,
               		"addressActiveS7","state",0,active_ini,
               		"driverNumberSelectorS7","text",driverNum_ini,
               		// "s7ConnNames","text",reference1_ini,
               		// "cmbPollGroupS7", "text",pollGroup_ini,
               		"trans_art","text", transf_ini);
    
		setValue("var_name", "text", s7ConnNames.text +"."+reference2_ini);   		
		cmbPollGroupS7.selectedPos=1;
		// just set the S7 values
  	reference2_ini = _fwPeriphAddressS7_setValuesFromRef(reference2_ini,sSystemName);      
	}
  
	//4. It may also be necessary to hide some of the graphical objects in the symbol
	//NOTE: By default, all the graphical objects will be visible before this function is called.
	
	// Polling config visible or not
	_fwPeriphAddressS7_setIOMode(directionModeS7.number,receiveMode.number, sSystemName);
}


// --------------------- SUPPORT FUNCTIONS -------------------------


/** Set S7 panel values 
Note: This function fills the panel fields in funciton of the REFERENCE selected by the user in several fields
			of the fwPeriphAddressS7.pnl
			
@par Constraints
	None

@par Usage
	Internal

@par PVSS managers
	VISION, CTRL

@param reference		input, user introduced reference
@param sSystemName				input, system name
@return			output, encoded S7 address
*/  
string _fwPeriphAddressS7_setValuesFromRef(string reference,string sSystemName)  
{  
  string  typ;     // Bausteintyp  
  int     nr;      // Bausteinnr  
  int     adr;     // Adresse fuer DB  
  string  fmt;     // Datenformat  
  int     i, j;    // ne variable halt  
  string s1,s2,s3, s4;
  int i1, i2, i3; 
  int x,y,z,n;
  string symb;
  string transformation; 

	// DebugN("FUNCTION: _fwPeriphAddressS7_setValuesFromRef(), reference= "+reference);

  transformation = trans_art.text	;

  if (reference == "" || reference == "0")  
    reference = "DB1DW0";  
    
  sscanf(reference, "%[^0-9]%d%[^0-9]%d%[^0-9]%d%[^0-9]", s1, i1, s2, i2, s3, i3, s4);  
  // DebugN("FUNCTION: _fwPeriphAddressS7_setValuesFromRef(), s1= "+s1+" i1= "+i1+" s2= "+s2+" i2= "+i2+" s3= "+s3+" i3= "+i3+" s4= "+s4 );
  
  pa_x.text = 1; pa_x.sbMinimum=1;pa_x.sbMaximum=32767; 
  pa_y.text = 0; pa_y.sbMinimum=0;pa_y.sbMaximum=65535; 
  pa_z.text = 0; pa_z.sbMinimum=0;pa_z.sbMaximum=7; 
  pa_n.text = 0; pa_n.sbMinimum=0;pa_n.sbMaximum=127; 

  if ( s1 == "M" )
  {
     if ( transformation != "boolean" && transformation != "string" && transformation != "default")
        transformation =  "boolean";
        
     y=i1; z= i2;
     
     pa_typ.selectedPos(1);
     pa_x.visible	= FALSE;
     pa_y.visible	= TRUE;
     pa_z.visible = TRUE;
     pa_n.visible = FALSE;
     pa_symb.visible = FALSE;
     directionModeS7.enabled	= TRUE;
     // DebugN("pa_y.text= "+y+ "pa_z.text= "+z); 
     pa_y.text = y;
     pa_z.text = z;
  } 
  else if ( s1 == "DB" && s2 == ".DBX")
  { 
     if ( transformation != "boolean" && transformation != "string"&& transformation != "default")
        transformation =  "boolean";
     x=i1; y= i2; z=i3;
     pa_x.sbMaximum=8191; 
     pa_typ.selectedPos(2);
     pa_x.visible	= TRUE;
     pa_y.visible	= TRUE;
     pa_z.visible = TRUE;
     pa_n.visible = FALSE;
     pa_symb.visible = FALSE;
     directionModeS7.enabled	= TRUE;
     pa_x.text = x;
     pa_y.text = y;
     pa_z.text = z;
  }  
  else if ( s1 == "E" || s1 == "I")
  {
     if ( transformation != "boolean" && transformation != "string"&& transformation != "default")
        transformation ="boolean";
     y=i1; z= i2;
     if (s1 == "E")
       pa_typ.selectedPos(3);
     else
       pa_typ.selectedPos(4);
     pa_x.visible	= FALSE;
     pa_y.visible	= TRUE;
     pa_z.visible = TRUE;
     pa_n.visible = FALSE;
     pa_symb.visible = FALSE;
     directionModeS7.enabled	= FALSE;
     pa_y.text = y;
     pa_z.text = z;
     _fwPeriphAddressS7_setIOMode(1,0,sSystemName);
     
  }  
  else if ( (s1 == "A" || s1 == "Q") && s2 == ".") 
  {
     if ( transformation != "boolean" && transformation != "string"&& transformation != "default")
        transformation =  "boolean";
     y= i2; z=i3;
     if (s1 == "A")
        pa_typ.selectedPos(5);
     else
        pa_typ.selectedPos(6);
     
     pa_x.visible	= FALSE;
     pa_y.visible	= TRUE;
     pa_z.visible = TRUE;
     pa_n.visible = FALSE;
     pa_symb.visible = FALSE;
     directionModeS7.enabled	= TRUE;
     pa_y.text = y;
     pa_z.text = z;
  }  
  else if ( s1 == "MB" && s2 == "")
  {
     if ( transformation != "byte" && transformation != "string"&& transformation != "default"&& transformation != "boolean")
        transformation = "byte";
     y=i1;
     pa_typ.selectedPos(7);
     pa_x.visible	= FALSE;
     pa_y.visible	= TRUE;
     pa_z.visible = FALSE;
     pa_n.visible = FALSE;
     pa_symb.visible = FALSE;
     directionModeS7.enabled	= TRUE;
     pa_y.text = y;
  }  
  else if ( s1 == "DB" && s2 == ".DBB")
  {
     if ( transformation != "byte" && transformation != "string"&& transformation != "default"&& transformation != "boolean")
        transformation =  "byte";
     x=i1; y= i2;
     pa_typ.selectedPos(8);
     pa_x.visible	= TRUE;
     pa_y.visible	= TRUE;
     pa_z.visible = FALSE;
     pa_n.visible = FALSE;
     pa_symb.visible = FALSE;
     directionModeS7.enabled	= TRUE;
     pa_x.text = x;
     pa_y.text = y;
  }  
  else if ( s1 == "EB" || s1 == "IB")
  { 
     if ( transformation != "byte" && transformation != "string"&& transformation != "default"&& transformation != "boolean")
        transformation =  "byte";
     y=i1; 
     if (s1 == "EB")
       pa_typ.selectedPos(9);
     else
       pa_typ.selectedPos(10);

     pa_x.visible	= FALSE;
     pa_y.visible	= TRUE;
     pa_z.visible = FALSE;
     pa_n.visible = FALSE;
     pa_symb.visible = FALSE;
     directionModeS7.enabled	= FALSE;
     pa_y.text = y;
     _fwPeriphAddressS7_setIOMode(1,0,sSystemName);
  }
  else if ( s1 == "AB" || s1 == "QB")
  {
     if ( transformation != "byte" && transformation != "string"&& transformation != "default"&& transformation != "boolean")
        transformation ="byte";
     y=i1;
     if (s1 == "AB")
       pa_typ.selectedPos(11);
     else
       pa_typ.selectedPos(12);

     pa_x.visible	= FALSE;
     pa_y.visible	= TRUE;
     pa_z.visible = FALSE;
     pa_n.visible = FALSE;
     pa_symb.visible = FALSE;
     directionModeS7.enabled	= TRUE;
     pa_y.text = y;
  }
  else if ( s1 == "MW")
  {
     if ( transformation != "int 16"&& transformation != "default")
        transformation ="int 16";
     y=i1; 
     pa_typ.selectedPos(13);
     pa_x.visible	= FALSE;
     pa_y.visible	= TRUE;
     pa_z.visible = FALSE;
     pa_n.visible = FALSE;
     pa_symb.visible = FALSE;
     directionModeS7.enabled	= TRUE;
     pa_y.text = y;
  }  
  else if ( s1 == "DB" && s2 == ".DBW")
  {
     if ( transformation != "int 16"&& transformation != "default")
        transformation = "int 16";
     x=i1; y= i2;
     pa_typ.selectedPos(14);
     pa_x.visible	= TRUE;
     pa_y.visible	= TRUE;
     pa_z.visible = FALSE;
     pa_n.visible = FALSE;
     pa_symb.visible = FALSE;
     directionModeS7.enabled	= TRUE;
     pa_x.text = x;
     pa_y.text = y;
  } 
  else if ( s1 == "EW" || s1 == "IW")
  {
     if ( transformation != "int 16"&& transformation != "default")
        transformation = "int 16";
     y=i1;
     if (s1 == "EW")
       pa_typ.selectedPos(15);
     else
       pa_typ.selectedPos(16);
     pa_x.visible	= FALSE;
     pa_y.visible	= TRUE;
     pa_z.visible = FALSE;
     pa_n.visible = FALSE;
     pa_symb.visible = FALSE;
     directionModeS7.enabled	= FALSE;
     pa_y.text = y;
     _fwPeriphAddressS7_setIOMode(1,0,sSystemName);
  }
  else if ( s1 == "AW" || s1 == "QW")
  {
     if ( transformation != "int 16"&& transformation != "default")
        transformation = "int 16";
     y=i1;
     if (s1 == "E")
       pa_typ.selectedPos(17);
     else
       pa_typ.selectedPos(18);
     pa_x.visible	= FALSE;
     pa_y.visible	= TRUE;
     pa_z.visible = FALSE;
     pa_n.visible = FALSE;
     pa_symb.visible = FALSE;
     directionModeS7.enabled	= TRUE;
     pa_y.text = y;
  }
  else if ( s1 == "MD" && s2 == "")
  {
     if ( transformation != "int 32" && transformation != "default" && transformation != "uint 32")
        transformation = "int 32";
     y=i1;
     pa_typ.selectedPos(19);
     pa_x.visible	= FALSE;
     pa_y.visible	= TRUE;
     pa_z.visible = FALSE;
     pa_n.visible = FALSE;
     pa_symb.visible = FALSE;
     directionModeS7.enabled	= TRUE;
     pa_y.text = y;
  }
  else if ( s1 == "DB" && s2 == ".DBD" && s3 == "")
  {
     if ( transformation != "int 32" && transformation != "default" && transformation != "uint 32")
        transformation = "int 32";
     x=i1; y=i2;
     pa_typ.selectedPos(20);
     pa_x.visible	= TRUE;
     pa_y.visible	= TRUE;
     pa_z.visible = FALSE;
     pa_n.visible = FALSE;
     pa_symb.visible = FALSE;
     directionModeS7.enabled	= TRUE;
     pa_x.text = x;
     pa_y.text = y;
  }
  else if ( s1 == "MD" && s2 == "F")
  {
     if ( transformation != "float"&& transformation != "default")
        transformation = "float";
     y=i1;
     pa_typ.selectedPos(21);
     pa_x.visible	= FALSE;
     pa_y.visible	= TRUE;
     pa_z.visible = FALSE;
     pa_n.visible = FALSE;
     pa_symb.visible = FALSE;
     directionModeS7.enabled	= TRUE;
     pa_y.text = y;
  }
  else if ( s1 == "DB" && s2 == ".DBD" && s3 == "F")
  {
     if ( transformation != "float"&& transformation != "default")
        transformation = "float";
     x=i1; y=i2;
     pa_typ.selectedPos(22);
     pa_x.visible	= TRUE;
     pa_y.visible	= TRUE;
     pa_z.visible = FALSE;
     pa_n.visible = FALSE;
     pa_symb.visible = FALSE;
     directionModeS7.enabled	= TRUE;
     pa_x.text = x;
     pa_y.text = y;
  }  
  else if ( s1 == "T")
  {
     if ( transformation != "uint 16"&& transformation != "default")
        transformation = "uint 16";
     n=i1;
     pa_typ.selectedPos(23);
     pa_x.visible	= FALSE;
     pa_y.visible	= FALSE;
     pa_z.visible = FALSE;
     pa_n.visible = TRUE;
     pa_symb.visible = FALSE;
     directionModeS7.enabled	= TRUE;
     pa_n.text = n;
  }
  else if ( s1 == "Z")
  {
     if ( transformation != "uint 16"&& transformation != "default")
        transformation = "uint 16";
     n=i1;
     pa_typ.selectedPos(24);
     pa_x.visible	= FALSE;
     pa_y.visible	= FALSE;
     pa_z.visible = FALSE;
     pa_n.visible = TRUE;
     pa_symb.visible = FALSE;
     directionModeS7.enabled	= TRUE;
     pa_n.text = n;
  }
  else
  { 
     symb=s1;
     pa_typ.selectedPos(25);
     pa_x.visible	= FALSE;
     pa_y.visible	= FALSE;
     pa_z.visible = FALSE;
     pa_n.visible = FALSE;
     pa_symb.visible = TRUE;
     directionModeS7.enabled	= TRUE;
     pa_symb.text = symb;
  }


  trans_art.text = transformation	;
  txt_x.visible	= pa_x.visible;
  txt_y.visible	= pa_y.visible;
  txt_z.visible	= pa_z.visible;
  txt_n.visible	= pa_n.visible;
  txt_symb.visible	= pa_symb.visible;
  bu_symb.visible	= pa_symb.visible;

  return _fwPeriphAddressS7_encodeAddress();
}

/** Recuperate transformation type
Note: This function recuperates the selected trasnforamtion type selected by the user in several fields
			of the fwPeriphAddressS7.pnl
			
@par Constraints
	None

@par Usage
	Internal

@par PVSS managers
	VISION, CTRL

@return	output, transformation type: i.e.: "701 --> int 16"
*/  
int _fwPeriphAddressS7_getTransfo()  
{  
  string item;  
  
  getValue("trans_art", "text", item);  
  
  if 			(item == "default")       return 700;  
  else if (item == "int 16")       	return 701;  
  else if (item == "int 32")   	  	return 702;  
  else if (item == "uint 16")       return 703;  
  else if (item == "byte")        	return 704;  
  else if (item == "float")        	return 705;  
  else if (item == "boolean")       return 706;  
  else if (item == "string")        return 707;
  else if (item == "uint 32")				return 708;  
  else                              return 700;	// default  
}  

/** Encode the S7 address 
Note: This function encodes the S7 address introduced by the user in several fields
			of the fwPeriphAddressS7.pnl
			
@par Constraints
	None

@par Usage
	Internal

@par PVSS managers
	VISION, CTRL

@return	correct address S7 type. i.e.: "DB100.DBX200.1"
*/
string  _fwPeriphAddressS7_encodeAddress()  
{  
  int    typ,x,y,z,n;  
  string pa, symb;  
  
  getMultiValue("pa_typ", "selectedPos", typ,  
                "pa_x", "text", x,  
                "pa_y", "text", y,
                "pa_z", "text", z,
                "pa_n", "text", n,
                "pa_symb", "text", symb);  
  switch (typ)  
  {  
    case 1 : pa = "M" + y + "." + z;              break;  
    case 2 : pa = "DB"+ x + ".DBX" + y + "." + z; break;  
    case 3 : pa = "E"+ y + "." + z;               break;  
    case 4 : pa = "I"+ y + "." + z;               break;  
    case 5 : pa = "A"+ y + "." + z;               break;  
    case 6 : pa = "Q"+ y + "." + z;               break;  
    case 7 : pa = "MB"+ y ;                       break;  
    case 8 : pa = "DB"+ x + ".DBB" + y ;          break;  
    case 9 : pa = "EB"+ y ;                       break;  
    case 10: pa = "IB"+ y ;                       break;  
    case 11: pa = "AB"+ y ;                       break;  
    case 12: pa = "QB"+ y ;                       break;  
    case 13: pa = "MW"+ y ;                       break;  
    case 14: pa = "DB"+ x + ".DBW" + y ;          break;  
    case 15: pa = "EW"+ y ;                       break;  
	  case 16: pa = "IW"+ y ;                       break;  
    case 17: pa = "AW"+ y ;                       break;  
    case 18: pa = "QW"+ y ;                       break;  
    case 19: pa = "MD"+ y ;                       break;  
    case 20: pa = "DB"+ x + ".DBD" + y;           break;  
    case 21: pa = "MD"+ y +"F";                   break;  
    case 22: pa = "DB"+ x + ".DBD" + y + "F";     break;  
    case 23: pa = "T"+ n;                         break;  
    case 24: pa = "Z"+ n;                         break;  
    case 25: pa = symb;                           break;  
    default: pa = "";  
  } 
  
  return pa;
}  

/** Get the S7 IO mode
Note: This function gets the IO mode from the user selection in the _fwPeriphAddressS7.pnl.
			new constants are defined to the In/out modes
			
@par Constraints
	None

@par Usage
	Internal

@par PVSS managers
	VISION, CTRL

@param directionModeS7			input, direction mode (Output, Input, Input/Output)
@param receiveMode				input, type mode (TSPP, Polling, Single Query)
*/
int _fwPeriphAddressS7_getDir(int directionModeS7, int receiveMode)
{
	int address_mode;

	switch (directionModeS7)
		{
			case 0:		address_mode=DPATTR_ADDR_MODE_OUTPUT; 	break;
			case 1:		if 			(receiveMode==0) address_mode=DPATTR_ADDR_MODE_INPUT_SPONT;
								else if (receiveMode==1) address_mode=DPATTR_ADDR_MODE_INPUT_POLL;
								else if (receiveMode==2) address_mode=DPATTR_ADDR_MODE_INPUT_SQUERY;
								break;
			case 2:		if 			(receiveMode==0) address_mode=UN_S7_ADDR_MODE_INOUT_TSPP;				// In/Out TSPP
								else if (receiveMode==1) address_mode=UN_S7_ADDR_MODE_INOUT_POLL;				// In/Out Polling
								else if (receiveMode==2) address_mode=UN_S7_ADDR_MODE_INOUT_SQ; 				// In/Out SQuery
								break;
			default:  address_mode=DPATTR_ADDR_MODE_UNDEFINED;				
		}
	return address_mode;
}

/** Set the S7 IO mode
Note: This function sets the IO mode from the user selection.
			There is the case "1" which is also used to set up the INPUT mode when
			user introduce an PLC peripherial INPUT from the address field.
			
@par Constraints
	None

@par Usage
	Internal

@par PVSS managers
	VISION, CTRL

@param io				input, direction mode (Output, Input, Input/Output)
@param im				input, type mode (TSPP, Polling, Single Query)
@param sSystemName				input, system name
*/
_fwPeriphAddressS7_setIOMode(int io, int im, string sSystemName)
{
	int i;
	dyn_string dsPlc;
	bool alreadyVisible;
	
	// int  im = receiveMode.number;
  // DebugN("FUNCTION: _fwPeriphAddressS7_setIOMode(io="+io+" im="+im);
  
  if (io == 1)												//	case selected address = input !!
    directionModeS7.number = io;				

	// RadioButton: Should be the input + 1 to get { 1=output, 2= xx, 3 = xxx)
  io++;		
  if ( io == 2 )													// modus IN TSPP
  	{
    	if ( im == 1 ) 				io = 4;				// modus: IN polling
    	else if ( im == 2 ) 	io = 3;				// modus: IN singlequery
  	}
  else if ( io == 3 )	
  	{
    	if ( im == 0 ) 			io = 6;					// modus IN/OUT: TSPP
    	else if ( im == 1 ) io = 7;					// modus IN/OUT: polling
    	else           			io = 8;					// modus IN/OUT: SQ
  	}

	// visibility of certain elements
  setMultiValue("text_rm","visible",(io>1),   
                "border_rm","visible",(io>1),   
                "receiveMode","visible",(io>1),   
                "lowlevelS7","visible",(io>1));
                
  //!!!pollgroup
  if (shapeExists("frmPollGroupS7"))
 		{
 			alreadyVisible = cmbPollGroupS7.visible;
	  	frmPollGroupS7.visible = (io==4 || io==7);
	  	txtPollGroupS7.visible = (io==4 || io==7);
	  	cmbPollGroupS7.visible = (io==4 || io==7);
	  	cmdPollGroupS7.visible = (io==4 || io==7) & (sSystemName == getSystemName());
	  	
	  	if (cmbPollGroupS7.visible)
	  		{
	  			// DebugN("Shape POLLGROUP visible");
	  			// Init the poll group to the first existing one (if ever exists)
	 				dsPlc = dpNames(sSystemName+"*","_PollGroup");

					for ( i = dynlen(dsPlc); i > 0; i-- )
  					{
    					// don't display redundant datapoints
    					if ( i > 1 && strpos(dsPlc[i],"_2") == strlen(dsPlc[i]) - 2 && dsPlc[i] == dsPlc[i-1] + "_2")
      					dynRemove(dsPlc, i);

    					if ( i <= dynlen(dsPlc) )
    						{
      						dsPlc[i] = dpSubStr(dsPlc[i],DPSUB_DP);
      						if ( dsPlc[i][0] == "_" )
        						dsPlc[i] = substr(dsPlc[i], 1, strlen(dsPlc[i])-1);
    						}
  					}
  
  				cmbPollGroupS7.items = dsPlc;
  				if (!alreadyVisible) cmbPollGroupS7.selectedPos =1;
	  		}
  	}
}

//@}
