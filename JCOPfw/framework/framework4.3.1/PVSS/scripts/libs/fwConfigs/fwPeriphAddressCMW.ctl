/**@file

This library contains function associated with CMW addressing.
Functions are provided to set, get and delete the addressing for a dpe

@par Creation Date
	25/04/2005

@par Modification History
  28/05/2008: Herve
    - new function: _fwPeriphAddressCMW_setTransformation identical to fwPeriphAddressCMW_setTransformation without
    reference to a graphical element.
    - fwPeriphAddressCMW_setTransformation call _fwPeriphAddressCMW_setTransformation
	
@par Constraints
	None

@par Usage
	Public

@par PVSS managers
	VISION, CTRL

@author 
	Celine VUILLERMOZ (AB-CO)
*/

//@{
//definition of constants
const string fwPeriphAddress_TYPE_CMW = "CMW";

const int CMW_DEFAULT_DRIVER_NUMBER = 2;
const string CMW_DEFAULT_REFERENCE = "reference$property$tag";
const bool CMW_DEFAULT_ACTIVE = TRUE;
const int CMW_DEFAULT_SUBINDEX = 0;
const bool CMW_DEFAULT_LOWLEVEL = FALSE;
const int CMW_DEFAULT_DIRECTION = 0;
const int CMW_DEFAULT_MODE = 0;
const int CMW_NO_MONITORON = 1000;
const int CMW_TRANS_OFFSET = 1000;

const unsigned fwPeriphAddress_CMW_LOWLEVEL 		= 11;
const unsigned fwPeriphAddress_CMW_SUBINDEX 		= 12;
const unsigned fwPeriphAddress_CMW_START 				= 13;
const unsigned fwPeriphAddress_CMW_INTERVAL 		= 14;
const unsigned fwPeriphAddress_CMW_POLL_GROUP		= 15;
const unsigned fwPeriphAddress_CMW_MODE					= 16;

//other constants for use in addressConfig object
//e.g. const int fwPeriphAddress_CMW_LOWLEVEL = 11;

//@}

//@{

/** Set the CMW addressing
Note: This function should not be called directly.  Call the fwPeriphAddress_set instead.

@par Constraints
	None

@par Usage
	Internal

@par PVSS managers
	VISION, CTRL

@param dpe						input, data point element to configure
@param addressConfig			input, object containing address configuration details
@param exceptionInfo			output, details of any exceptions are returned here
*/

_fwPeriphAddressCMW_set(string dpe, dyn_anytype addressConfig, dyn_string &exceptionInfo)
{
	dyn_errClass errors;
	int iMode, iRes, iDirection,driverNum, addressSubindex, mode, intervalTime, dataType;
	bool active, bLowLevel; 
	string addressReference,typeDriver, pollGroup;
	time startingTime;
string sSystemName;

	driverNum = addressConfig[FW_PARAMETER_FIELD_DRIVER];
	addressReference = addressConfig[fwPeriphAddress_REFERENCE];
	addressSubindex = addressConfig[fwPeriphAddress_CMW_SUBINDEX];
	mode = addressConfig[fwPeriphAddress_CMW_MODE];
	startingTime = addressConfig[fwPeriphAddress_CMW_START];
	intervalTime = addressConfig[fwPeriphAddress_CMW_INTERVAL];
	dataType = addressConfig[fwPeriphAddress_DATATYPE];
	active = addressConfig[fwPeriphAddress_ACTIVE];
	bLowLevel = addressConfig[fwPeriphAddress_CMW_LOWLEVEL];
	typeDriver = addressConfig[fwPeriphAddress_TYPE];
	pollGroup = addressConfig[fwPeriphAddress_CMW_POLL_GROUP];
	
	//DebugN("*******",sSystemName,pollGroup,dpExists(sSystemName+pollGroup), addressConfig);
	//1. Check contents of addressConfig is consistent/coherent plus any data manipulation

	fwPeriphAddressCMW_check(addressConfig, exceptionInfo);

	if (dynlen(exceptionInfo)<=0)
	{
		//2. Set the distrib config	and driver number
		//The driver will already have been checked to see that it is running, so just dpSetWait
		
		if( addressConfig[fwPeriphAddress_DIRECTION] == DPATTR_ADDR_MODE_INPUT_POLL)
		{
			fwGeneral_getSystemName(dpe, sSystemName, exceptionInfo);
			if(sSystemName == "") sSystemName = getSystemName();
			  
			
			if(!dpExists(sSystemName+pollGroup))
			{
				fwException_raise(exceptionInfo, "ERROR", "Polling group does not exist: " + pollGroup, "");
				return;
			}
		}
		iRes = dpSetWait(dpe + ":_distrib.._type", DPCONFIG_DISTRIBUTION_INFO,
							dpe + ":_distrib.._driver", driverNum);

		errors = getLastError(); 
	  if(dynlen(errors) > 0)
	  { 
			throwError(errors);
			fwException_raise(exceptionInfo, "ERROR", "Could not create the distrib config.", "");
			return;
		}
	
		//3. Set the addressConfig data to the config
		dpSetWait(dpe + ":_address.._type", DPCONFIG_PERIPH_ADDR_MAIN,
							dpe + ":_address.._drv_ident", typeDriver,
							dpe + ":_address.._reference", addressReference,  
							dpe + ":_address.._direction",addressConfig[fwPeriphAddress_DIRECTION],
							dpe + ":_address.._datatype", dataType,  
							dpe + ":_address.._active", active,
						  dpe + ":_address.._mode", mode,
						  dpe + ":_address.._internal", false,
						  dpe + ":_address.._lowlevel",bLowLevel,						  
						  dpe + ":_address.._subindex",addressSubindex  ,						  
						  dpe + ":_address.._start",startingTime ,
						  dpe + ":_address.._interval", intervalTime,
						  dpe + ":_address.._poll_group",pollGroup);

		errors = getLastError(); 
	  if(dynlen(errors) > 0)
	  { 
			throwError(errors);
			fwException_raise(exceptionInfo, "ERROR", "Could not set the " + fwPeriphAddress_TYPE_CMW + " address config.", "");
		}
	}
}

/** Get the CMW addressing
Note: This function should not be called directly.  Call the fwPeriphAddress_get instead.

@par Constraints
	None

@par Usage
	Internal

@par PVSS managers
	VISION, CTRL

@param dpe				input, data point element to read
@param addressConfig	output, object containing address configuration details
@param isActive			output, TRUE is addressing is active, else FALSE
@param exceptionInfo	output, details of any exceptions are returned here
*/

_fwPeriphAddressCMW_get(string dpe, dyn_anytype &addressConfig, bool &isActive, dyn_string &exceptionInfo)
{
//int iMode; bool &cmwLowlevel, int iDir, int iMode,
	//1. Get the driver number and address config contents
	//It will already be known that the config exists so you can just do dpGet
	         
	dpGet(		dpe + ":_distrib.._driver", addressConfig[fwPeriphAddress_DRIVER_NUMBER],
						dpe + ":_address.._drv_ident", addressConfig[fwPeriphAddress_TYPE],
						dpe + ":_address.._reference", addressConfig[fwPeriphAddress_REFERENCE],  
						dpe + ":_address.._direction", addressConfig[fwPeriphAddress_DIRECTION],
						dpe + ":_address.._datatype", addressConfig[fwPeriphAddress_DATATYPE],  
						dpe + ":_address.._active", addressConfig[fwPeriphAddress_ACTIVE],
					  dpe+":_address.._lowlevel",  addressConfig[fwPeriphAddress_CMW_LOWLEVEL],
					  dpe+":_address.._subindex",  addressConfig[fwPeriphAddress_CMW_SUBINDEX],
					  dpe + ":_address.._mode", addressConfig[fwPeriphAddress_CMW_MODE],
	          dpe+":_address.._start", addressConfig[fwPeriphAddress_CMW_START],
	          dpe+":_address.._interval",  addressConfig[fwPeriphAddress_CMW_INTERVAL],
					  dpe+":_address.._poll_group",  addressConfig[fwPeriphAddress_CMW_POLL_GROUP]);

	//2. Do any necessary manipulation of the data that was read 				
//	fwPeriphAddressCMW_getTransformation(addressConfig[fwPeriphAddress_DIRECTION],addressConfig[fwPeriphAddress_DATATYPE], dpe, cmwLowlevel, iDir, iMode);
	
	//3. Set the isActive value - by default this will be the same as addressConfig[fwPeriphAddress_ACTIVE]
	isActive = addressConfig[fwPeriphAddress_ACTIVE];
}

/** Delete the CMW addressing
Note: This function should not be called directly.  Call the fwPeriphAddress_delete instead.

@par Constraints
	None

@par Usage
	Internal

@par PVSS managers
	VISION, CTRL

@param dpe						input, data point element to configure
@param exceptionInfo			output, details of any exceptions are returned here
*/

_fwPeriphAddressCMW_delete(string dpe, dyn_string &exceptionInfo)
{
	//1. If only the address and distrib config need deleting then do nothing here.
	//NOTE: This function is called BEFORE the address config is deleted.
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
@param exceptionInfo			output, details of any exceptions are returned here
*/
_fwPeriphAddressCMW_initPanel(string dpe, dyn_string &exceptionInfo)
{
	bool configExists, isActive, bLowLevel;
	dyn_anytype addressConfig;
	int iDirection, iMode, iTransformation, i, j;
  	string sSystemName;
  dyn_string dsPlc, ds;
	string pollgroup;
  
  fwGeneral_getSystemName(dpe, sSystemName, exceptionInfo);
  if(sSystemName == "") sSystemName = getSystemName();
  

  	
  dsPlc = dpNames(sSystemName+"*","_PollGroup");
  
	//1. Get the current config
	
	fwPeriphAddress_get(dpe, configExists, addressConfig, isActive, exceptionInfo);
	if(configExists && (addressConfig[fwPeriphAddress_TYPE]==fwPeriphAddress_TYPE_CMW))
	{
			fwPeriphAddressCMW_getTransformation(addressConfig[fwPeriphAddress_DIRECTION],addressConfig[fwPeriphAddress_DATATYPE], dpe);
			}
	
	if(dynlen(exceptionInfo)>0)
		return;
	for ( i = dynlen(dsPlc); i > 0; i-- )
  {
    if ( i > 1 &&
         strpos(dsPlc[i],"_2") == strlen(dsPlc[i]) - 2 &&
         dsPlc[i] == dsPlc[i-1] + "_2"
       )
    {
      dynRemove(dsPlc, i);
    }

    if ( i <= dynlen(dsPlc) )
    {
      dsPlc[i] = dpSubStr(dsPlc[i],DPSUB_DP);
      if ( dsPlc[i][0] == "_" )
        dsPlc[i] = substr(dsPlc[i], 1, strlen(dsPlc[i])-1);
    }
  }
  
 
  if(dynlen(dsPlc) > 0)
  {
	  PollGroupName_CMW.items = dsPlc;
  }

	getMultiValue("direction_CMW","number",i,"mode_CMW","number",j);
  setValue("lowlevel_CMW","enabled",(i==0));

	if(i!=0)
		{
			mode_CMW.enabled	=false;
			mode_CMW.number = 0;
		}	
		
	if ((i==0)&&(j==2)) 
	{
		PollGroupName_CMW.enabled	=true;
		if(sSystemName == getSystemName())
	  	BtGroup_CMW.enabled	=true;
	  else BtGroup_CMW.enabled	=false;
	
//		string pollgroup = dpe + ":_address.._poll_group";
		  
//		if (dpExists(sSystemName+pollgroup))
//		{
			dpGet(dpe + ":_address.._poll_group",pollgroup);
			
			PollGroupName_CMW.text = substr(pollgroup,1, strlen(pollgroup));
/*		}
		else
		 {
//			PollGroupName_CMW.enabled	=false;
			BtGroup_CMW.enabled	= false;
			PollGroupName_CMW.selectedPos=1;	
		 }       
*/
	}
	else
	 {
		PollGroupName_CMW.enabled	=false;
		BtGroup_CMW.enabled	= false;
		PollGroupName_CMW.selectedPos=1;	
	 }       

	if(configExists && (addressConfig[fwPeriphAddress_TYPE] ==fwPeriphAddress_TYPE_CMW))
	{
			driverNumberSelector_CMW.text = addressConfig[fwPeriphAddress_DRIVER_NUMBER];
			referenceField_CMW.text = addressConfig[fwPeriphAddress_REFERENCE];
			subIndex_CMW.text = addressConfig[fwPeriphAddress_CMW_SUBINDEX];
			PollGroupName_CMW.text = substr(addressConfig[fwPeriphAddress_CMW_POLL_GROUP],1,strlen(addressConfig[fwPeriphAddress_CMW_POLL_GROUP]));
			activeCheckButton_CMW.state(0) = isActive;
	}
	else
	{
		//3. If the config does not exist, set a clean default for the user to start entering data
		driverNumberSelector_CMW.text = CMW_DEFAULT_DRIVER_NUMBER;
		referenceField_CMW.text = CMW_DEFAULT_REFERENCE;
		activeCheckButton_CMW.state(0) = CMW_DEFAULT_ACTIVE;
		subIndex_CMW.text	= CMW_DEFAULT_SUBINDEX;
		lowlevel_CMW.state(0) = CMW_DEFAULT_LOWLEVEL;
		direction_CMW.number	= CMW_DEFAULT_DIRECTION;
		mode_CMW.number	= CMW_DEFAULT_MODE;
	}
	
	//4. It may also be necessary to hide some of the graphical objects in the symbol
	//NOTE: By default, all the graphical objects will be visible before this function is called.
}

/** Check if data is Ok to set a CMW address

@par Constraints
	None

@par Usage
	Public

@par PVSS managers
	VISION, CTRL

@param dsParameters		parameters used to set the _address config (see constants definition)
@param exceptionInfo	for any error. If a parameter is incorrect, exceptionInfo is not empty !
*/

fwPeriphAddressCMW_check(dyn_string dsParameters, dyn_string& exceptionInfo)
{
	int driverNum, addressSubindex, mode, intervalTime, dataType, iTemp;
	string active, lowLevel; 
	string addressReference;
	time startingTime;
	dyn_string addressSplit;
	bool badAddress;

//DebugN(dsParameters);
	// 1. Length & communication type
	if (dynlen(dsParameters) == FW_PARAMETER_FIELD_NUMBER+1)
	{
		if (dsParameters[FW_PARAMETER_FIELD_COMMUNICATION] != fwPeriphAddress_TYPE_CMW)
		{
			fwException_raise(exceptionInfo,"ERROR","fwPeriphAddressCMW_check: " + getCatStr("fwPeriphAddressCMW","CMWBADCOMM"),"");
		}
		// 2. Driver number
		if (sscanf(dsParameters[FW_PARAMETER_FIELD_DRIVER], "%d", driverNum) <= 0)
		{
			fwException_raise(exceptionInfo,"ERROR","fwPeriphAddressCMW_check: " + getCatStr("fwPeriphAddressCMW","CMWBADDRIVERNUM"),"");
		}
		// 3. Address reference
		addressReference = dsParameters[FW_PARAMETER_FIELD_ADDRESS];
		addressSplit = strsplit(addressReference, "$");
		badAddress = false;
		if (dynlen(addressSplit) <=2)	badAddress = true;
			else badAddress = false;
			
		if (badAddress)
		{
			fwException_raise(exceptionInfo,"ERROR","fwPeriphAddressCMW_check: " + getCatStr("fwPeriphAddressCMW","CMWBADADDRESS"),"");
		}
		// 4. Address subindex
		if (sscanf(dsParameters[FW_PARAMETER_FIELD_SUBINDEX], "%d", addressSubindex) <= 0)
		{
			fwException_raise(exceptionInfo,"ERROR","fwPeriphAddressCMW_check: " + getCatStr("fwPeriphAddressCMW","CMWBADSUBINDEX"),"");
		}
		// 5. Mode
		if (sscanf(dsParameters[FW_PARAMETER_FIELD_MODE], "%d", mode) <= 0)
		{
			fwException_raise(exceptionInfo,"ERROR","fwPeriphAddressCMW_check: " + getCatStr("fwPeriphAddressCMW","CMWBADMODE"),"");
		}
		// 6. Starting time
		startingTime = dsParameters[FW_PARAMETER_FIELD_START];
		// 7. Interval Time
		if (sscanf(dsParameters[FW_PARAMETER_FIELD_INTERVAL], "%d", intervalTime) <= 0)
		{
			fwException_raise(exceptionInfo,"ERROR","fwPeriphAddressCMW_check: " + getCatStr("fwPeriphAddressCMW","CMWBADINTERVAL"),"");
		}
		// 8. Data type
		if (sscanf(dsParameters[FW_PARAMETER_FIELD_DATATYPE], "%d", dataType) <= 0)
		{
			fwException_raise(exceptionInfo,"ERROR","fwPeriphAddressCMW_checkParameters: " + getCatStr("fwPeriphAddressCMW","CMWBADDATATYPE"),"");
		}
		// 9. Address active
		active = dsParameters[FW_PARAMETER_FIELD_ACTIVE];
		if ((active != "FALSE") && (active != "TRUE") && (active != "0") && (active != "1"))
		{
			fwException_raise(exceptionInfo,"ERROR","fwPeriphAddressCMW_check: " + getCatStr("fwPeriphAddressCMW","CMWBADACTIVE"),"");
		}
		// 10. Lowlevel
		lowLevel = dsParameters[FW_PARAMETER_FIELD_LOWLEVEL];
		if ((lowLevel != "FALSE") && (lowLevel != "TRUE") && (lowLevel != "0") && (lowLevel != "1"))
		{
			fwException_raise(exceptionInfo,"ERROR","fwPeriphAddressCMW_check: " + getCatStr("fwPeriphAddressCMW","CMWBADLOWLEVEL"),"");
		}
		//11. Poll Group
		if ((dsParameters[fwPeriphAddress_CMW_POLL_GROUP]== "") && (dsParameters[fwPeriphAddress_DIRECTION]==4))
		{
		//DebugN(dsParameters[fwPeriphAddress_DIRECTION], dsParameters[fwPeriphAddress_CMW_POLL_GROUP],"checkbad");
			fwException_raise(exceptionInfo,"ERROR","fwPeriphAddressCMW_check: " + getCatStr("fwPeriphAddressCMW","CMWBADPOLLGROUP"),"");
		}
	}
	else
	{
		fwException_raise(exceptionInfo,"ERROR","fwPeriphAddressCMW_check: " + getCatStr("fwPeriphAddressCMW","CMWBADPARAMNUMBER"),"");
	}
}

/** Calculate the transformation of CMW address

@par Constraints
	None

@par Usage
	Public

@par PVSS managers
	VISION, CTRL

@param cmw_direction	input, value used to know the direction of the driver
@param iCmw_trans		input, driver type tranformation 
@param dpe				input, data point element to configure

*/	

fwPeriphAddressCMW_getTransformation(int cmw_direction, int iCmw_trans, string dpe)
{
int iDir, iMode,x, cmw_trans;
bool cmw_lowlevel, bEnabled=true, bMonitorOn;

		dpGet(dpe+":_address.._lowlevel",cmw_lowlevel);

    		if(iCmw_trans >= (2*CMW_NO_MONITORON)) 
    		{
    			cmw_trans = iCmw_trans - CMW_NO_MONITORON;
    			bMonitorOn = false;
    		}
    		else
    		{
    			cmw_trans = iCmw_trans;
    			bMonitorOn = true;
    		}
//DebugN(bMonitorOn , iCmw_trans , cmw_trans );
		switch(cmw_direction)
		{
		case 1:								//Output group
			iDir = 2; 
			iMode = 0;
		break;
		case 2:								//Input spontaneous
			iDir = 0;
			iMode = 0;
		break;
		case 3:								//Input SQ
			iDir = 0;
			iMode = 1;
		break;
		case 4:								//Input polling
			iDir = 0;
			iMode = 2;					
		break;
		case 5:								//Output single
			iDir = 1;
			iMode = 0;					
		break;
		case 66:							// Input spontaneous + Low level
			iDir = 0;
			iMode = 0;
			cmw_lowlevel = true;
		break; 			
		
		default:							// other case
			iDir = 0;
			iMode = 0;
		break;
		}
		transformation_CMW.selectedPos=cmw_trans-CMW_TRANS_OFFSET;
		direction_CMW.number = iDir;
		mode_CMW.number	=iMode;
		if((iDir == 0) && (iMode == 0)) {
			bEnabled = false;
			bMonitorOn = true;
		}
//DebugN(bMonitorOn , iDir, iMode);
		setMultiValue("monitorOn", "state", 0, bMonitorOn,
	                    "monitorOn", "enabled", bEnabled);
		if(iDir != 0) {
			lowlevel_CMW.enabled	= false;	
		}
		else
			lowlevel_CMW.enabled	= true;	
		lowlevel_CMW.state(0)=cmw_lowlevel;
}


/** Set the transformation of CMW address

@par Constraints
	None

@par Usage
	Public

@par PVSS managers
	VISION, CTRL

@param cmw_direction	output, direction of the driver
@param cmw_mode			output, Receive mode
@param cmw_trans		output, driver type tranformation 
@param cmw_lowlevel		output, is the low level comparison set ?
@param dpe				input, data point element to configure

*/	

fwPeriphAddressCMW_setTransformation(int &cmw_direction, int &cmw_mode, int &cmw_trans, bool &cmw_lowlevel, string dpe)
{
  bool bMonitorOn;
  
  bMonitorOn = monitorOn.state(0);
  _fwPeriphAddressCMW_setTransformation(bMonitorOn, cmw_direction, cmw_mode, cmw_trans, cmw_lowlevel, dpe);
}

/** Set the transformation of CMW address

@par Constraints
	None

@par Usage
	Internal function

@par PVSS managers
	VISION, CTRL

@param bMonitorOn	input, true=monitorOn/false=no monitorOn
@param cmw_direction	output, direction of the driver
@param cmw_mode			output, Receive mode
@param cmw_trans		output, driver type tranformation 
@param cmw_lowlevel		output, is the low level comparison set ?
@param dpe				input, data point element to configure

*/	

_fwPeriphAddressCMW_setTransformation(bool bMonitorOn, int &cmw_direction, int &cmw_mode, int &cmw_trans, bool &cmw_lowlevel, string dpe)
{
int iDir, iMode,x, iTrans;
bool bLowlevel;
int iMonitorOn;


	iDir = cmw_direction;
	bLowlevel = cmw_lowlevel;
	iTrans = cmw_trans;
	iMode = cmw_mode;

		switch(iDir)
		{
		case 0:
			switch(iMode)
			{
				case 0:
					cmw_direction = 2;
					if (bLowlevel) 
					{
						cmw_mode = cmw_direction + 64;
					}
					else cmw_mode =cmw_direction;
				break;
				case 1:
					cmw_direction = 3;
					cmw_mode =cmw_direction;
				break;
				case 2:
					cmw_direction = 4;				
					cmw_mode =cmw_direction;
				break;
			}
		break;
		case 1:
			if (iMode == 0) 
			{
				cmw_direction = 5;
				cmw_mode =cmw_direction;
			}
			else 
			{
				cmw_direction = 99;
				cmw_mode =cmw_direction;
			}
		break;
		case 2:
			if (iMode == 0) 
			{
				cmw_direction = 1;
				cmw_mode =cmw_direction;
			}
			else 
			{
				cmw_direction = 99;
				cmw_mode =cmw_direction;
			}
		break;
		default:
			cmw_direction = 99;
			cmw_mode =cmw_direction;
		break;
		}
		if(!bMonitorOn)
			iMonitorOn = CMW_NO_MONITORON;
		cmw_trans=iTrans+CMW_TRANS_OFFSET+iMonitorOn;
		cmw_lowlevel = bLowlevel;
//		dpSet(dpe+":_address.._lowlevel",bLowlevel);
}
//@}
