/**@file

This library contains function associated with the smoothing config.
Functions are provided for getting the current settings, deleting the config
and setting the config 

@par Creation Date
	19/06/2000

@par Modification History

  19/09/2011 Marco Boccioli
  - @sav{86857}: _fwSmoothing_getParameters returns timeInterval = 1970.01 instead of 0. The internal variable was changed to dyn_anytype.
	
  05/09/2011 Marco Boccioli
  - @sav{86405}: index out of range if a dpe has archive not fully parametrized. In case an attribute is not readable,
    _fwSmoothing_getParameters() makes a dpGet attribute per attribute. In this way it saves all the other dpes that are readable.
  
  31/08/2011 Marco Boccioli
  - @sav{86236}: Error if dpe has no smoothing configured. added check into _fwSmoothing_getParameters()
  
  12/08/2011 Marco Boccioli
  - @sav{85462}: Functions *_setMany and *_getMany with parameters as reference.
  - @sav{85464}: Improved performance for fwSmoothing_getMany(). It now makes 2 dpGet instead of 2*n.

  26/01/2011  Marco Boccioli
  - @sav{77348}, @jira{ENS-2495} - added option to archive or not the modification of smoothing (parametrization history).
  
  21/01/2004	Oliver
  - Added functionality for relative deadband values. Seperated out get and set of smoothing parameters (for use by fwArchive and fwSmoothing functions)

  15/01/2004	Oliver
  - Completed overhaul of whole library
  
  15/09/2000  Oliver
  - added error handling to save and delete functions
  
	Oliver
  - cases for "combined smoothing and time" and " old/new comparison and time" added ability
							to get/set time interval when available
  
@par Constraints
	WARNING: the functions use the dpGet or dpSetWait, problems may occur when using these functions 
          		in a working function called by a PVSS (dpConnect) or in a calling function

@par Usage
	Public

@par PVSS managers
	VISION, CTRL

@author 
	Herve Milcent, Niko Karlsson, Oliver Holme (IT-CO)
*/

//@{
/** Adds or modifies the smoothing config on the given dpes

@par Constraints
	None

@par Usage
	Public

@par PVSS managers
	VISION, CTRL

@param dpes							list of data point elements. Passed as reference only for performance reasons. Not modified.
@param smoothProcedure		DPATTR_VALUE_SMOOTH            	: value dependent,
													DPATTR_VALUE_REL_SMOOTH        	: relative value dependent,
													DPATTR_TIME_SMOOTH             	: time dependent,
													DPATTR_TIME_AND_VALUE_SMOOTH   	: value AND time dependent,
													DPATTR_TIME_AND_VALUE_REL_SMOOTH   : relative value AND time dependent,
													DPATTR_TIME_OR_VALUE_SMOOTH    	: value OR time dependent,
													DPATTR_TIME_OR_VALUE_REL_SMOOTH    : relative value OR time dependent,
													DPATTR_COMPARE_OLD_NEW         	: old-new comparison,
													DPATTR_OLD_NEW_AND_TIME_SMOOTH 	: old-new comparison AND time,
													DPATTR_OLD_NEW_OR_TIME_SMOOTH  	: old-new comparison OR time.
													 Passed as reference only for performance reasons. Not modified.
@param deadband					deadband value . Passed as reference only for performance reasons. Not modified.
@param timeInterval			time in seconds. Passed as reference only for performance reasons. Not modified.
@param exceptionInfo		details of any errors are returned here
@param runDriverCheck		Optional parameter (default value = FALSE) - TRUE to check if driver is running before setting config, else FALSE
						The necessary driver number must be running in order to successfully create config
@param storeInParamHistory		Optional parameter (default value = TRUE) - TRUE to archive the parameter change, else FALSE
*/
fwSmoothing_setMany(dyn_string &dpes, dyn_int &smoothProcedure, dyn_float &deadband, dyn_float &timeInterval, 
                    dyn_string &exceptionInfo, bool runDriverCheck = FALSE, bool storeInParamHistory = TRUE) 
{
	bool areAccessible;
	int i, length;
	string errorString;
	dyn_int configType, requiredDrivers;

  if(runDriverCheck)
  {
		_fwConfigs_checkAreConfigsAccessible(dpes, areAccessible, requiredDrivers, exceptionInfo);
		if(!areAccessible)
		{
			_fwConfigs_convertDriverNumbersToErrorMessage(requiredDrivers, errorString, exceptionInfo);
			fwException_raise(exceptionInfo, "ERROR", "To set the smoothing config, driver number " + errorString + " must be running.", errorString);
			return;
		}
	}

	length = dynlen(dpes);
	for(i=1; i<=length; i++)
		dynAppend(configType, DPCONFIG_SMOOTH_SIMPLE_MAIN);

	_fwConfigs_setConfigTypeAttribute(dpes, fwConfigs_PVSS_SMOOTH, configType, exceptionInfo);
	if(dynlen(exceptionInfo)>0)
		return;

	_fwSmoothing_setParameters(dpes, FALSE, smoothProcedure, deadband, timeInterval, exceptionInfo, storeInParamHistory);
}


/** Adds or modifies the smoothing config on the given dpes

@par Constraints
	None

@par Usage
	Public

@par PVSS managers
	VISION, CTRL

@param dpes							list of data point elements
@param smoothProcedure		DPATTR_VALUE_SMOOTH            	: value dependent,
													DPATTR_VALUE_REL_SMOOTH        	: relative value dependent,
													DPATTR_TIME_SMOOTH             	: time dependent,
													DPATTR_TIME_AND_VALUE_SMOOTH   	: value AND time dependent,
													DPATTR_TIME_AND_VALUE_REL_SMOOTH   : relative value AND time dependent,
													DPATTR_TIME_OR_VALUE_SMOOTH    	: value OR time dependent,
													DPATTR_TIME_OR_VALUE_REL_SMOOTH    : relative value OR time dependent,
													DPATTR_COMPARE_OLD_NEW         	: old-new comparison,
													DPATTR_OLD_NEW_AND_TIME_SMOOTH 	: old-new comparison AND time,
													DPATTR_OLD_NEW_OR_TIME_SMOOTH  	: old-new comparison OR time
@param deadband					deadband value 
@param timeInterval			time in seconds
@param exceptionInfo		details of any errors are returned here
@param runDriverCheck		Optional parameter (default value = FALSE) - TRUE to check if driver is running before setting config, else FALSE
						The necessary driver number must be running in order to successfully create config
@param storeInParamHistory		Optional parameter (default value = TRUE) - TRUE to archive the parameter change, else FALSE
*/
fwSmoothing_setMultiple(dyn_string dpes, int smoothProcedure, float deadband, float timeInterval, 
                        dyn_string &exceptionInfo, bool runDriverCheck = FALSE, bool storeInParamHistory = TRUE) 
{
	int i, length;
	dyn_int diSmoothProcedure;
	dyn_float dfDeadband, dfTimeInterval;

	length = dynlen(dpes);
	for(i=1; i<=length; i++)
	{
		dynAppend(diSmoothProcedure, smoothProcedure);
		dynAppend(dfDeadband, deadband);
		dynAppend(dfTimeInterval, timeInterval);
	}
	
	fwSmoothing_setMany(dpes, diSmoothProcedure, dfDeadband, dfTimeInterval, exceptionInfo, runDriverCheck, storeInParamHistory);
}

/** Adds or modifies the smoothing config on the given dpes

@par Constraints
	None

@par Usage
	Public

@par PVSS managers
	VISION, CTRL

@param dpe							data point element
@param smoothProcedure		DPATTR_VALUE_SMOOTH            	: value dependent,
													DPATTR_VALUE_REL_SMOOTH        	: relative value dependent,
													DPATTR_TIME_SMOOTH             	: time dependent,
													DPATTR_TIME_AND_VALUE_SMOOTH   	: value AND time dependent,
													DPATTR_TIME_AND_VALUE_REL_SMOOTH   : relative value AND time dependent,
													DPATTR_TIME_OR_VALUE_SMOOTH    	: value OR time dependent,
													DPATTR_TIME_OR_VALUE_REL_SMOOTH    : relative value OR time dependent,
													DPATTR_COMPARE_OLD_NEW         	: old-new comparison,
													DPATTR_OLD_NEW_AND_TIME_SMOOTH 	: old-new comparison AND time,
													DPATTR_OLD_NEW_OR_TIME_SMOOTH  	: old-new comparison OR time
@param deadband					deadband value 
@param timeInterval			time in seconds
@param exceptionInfo		details of any errors are returned here
@param runDriverCheck		Optional parameter (default value = FALSE) - TRUE to check if driver is running before setting config, else FALSE
@param storeInParamHistory		Optional parameter (default value = TRUE) - TRUE to archive the parameter change, else FALSE
						The necessary driver number must be running in order to successfully create config
*/
fwSmoothing_set(string dpe, int smoothProcedure, float deadband, float timeInterval, 
                dyn_string &exceptionInfo, bool runDriverCheck = FALSE, bool storeInParamHistory = TRUE) 
{
  dyn_string dpes;
  dyn_int smoothProcedures;
  dyn_float deadbands, timeIntervals;
  dpes[1]=dpe;
  smoothProcedures[1]=smoothProcedure;
  deadbands[1]=deadband;
  timeIntervals[1]=timeInterval;
	fwSmoothing_setMany(dpes, smoothProcedures, deadbands,
												timeIntervals, exceptionInfo, runDriverCheck, storeInParamHistory);
} 


/** Deletes the smoothing config for the given data point elements

@par Constraints
	None

@par Usage
	Public

@par PVSS managers
	VISION, CTRL

@param dpes						list of data point elements
@param exceptionInfo	details of any errors are returned here
*/
fwSmoothing_deleteMultiple(dyn_string dpes, dyn_string &exceptionInfo)
{
	fwSmoothing_deleteMany(dpes, exceptionInfo);
}


/** Deletes the smoothing config for the given data point elements

@par Constraints
	None

@par Usage
	Public

@par PVSS managers
	VISION, CTRL

@param dpes						list of data point elements
@param exceptionInfo	details of any errors are returned here
*/
fwSmoothing_deleteMany(dyn_string dpes, dyn_string &exceptionInfo)
{
	bool areAccessible;
	string errorString;
	dyn_int requiredDrivers;

	_fwConfigs_checkAreConfigsAccessible(dpes, areAccessible, requiredDrivers, exceptionInfo);
	if(!areAccessible)
	{
		_fwConfigs_convertDriverNumbersToErrorMessage(requiredDrivers, errorString, exceptionInfo);
		fwException_raise(exceptionInfo, "ERROR", "To delete the smoothing config, driver number " + errorString + " must be running.", errorString);
		return;
	}


	_fwConfigs_delete(dpes, fwConfigs_PVSS_SMOOTH, exceptionInfo);
}


/** Deletes the smoothing config for the given data point element

@par Constraints
	None

@par Usage
	Public

@par PVSS managers
	VISION, CTRL

@param dpe						data point element
@param exceptionInfo	details of any errors are returned here
*/
fwSmoothing_delete(string dpe, dyn_string &exceptionInfo)
{
	fwSmoothing_deleteMany(makeDynString(dpe), exceptionInfo);
}


/** Gets the smoothing config from the given data point element. 
The function checks that the relevant driver is running. 
If not it returns an exception saying the config could not be read.

@par Constraints
	None

@par Usage
	Public

@par PVSS managers
	VISION, CTRL

@param dpe						data point element
@param configExists		TRUE if smoothing config exists, else FALSE
@param smoothProcedure	DPATTR_VALUE_SMOOTH            	: value dependent,
												DPATTR_VALUE_REL_SMOOTH        	: relative value dependent,
												DPATTR_TIME_SMOOTH             	: time dependent,
												DPATTR_TIME_AND_VALUE_SMOOTH   	: value AND time dependent,
												DPATTR_TIME_AND_VALUE_REL_SMOOTH   : relative value AND time dependent,
												DPATTR_TIME_OR_VALUE_SMOOTH    	: value OR time dependent,
												DPATTR_TIME_OR_VALUE_REL_SMOOTH    : relative value OR time dependent,
												DPATTR_COMPARE_OLD_NEW         	: old-new comparison,
												DPATTR_OLD_NEW_AND_TIME_SMOOTH 	: old-new comparison AND time,
												DPATTR_OLD_NEW_OR_TIME_SMOOTH  	: old-new comparison OR time
@param deadband				Deadband value
@param timeInterval		Time interval in seconds
@param exceptionInfo	details of any errors are returned here
*/
fwSmoothing_get(string dpe, bool &configExists, int &smoothProcedure, float &deadband, float &timeInterval, dyn_string &exceptionInfo) 
{ 
	bool isAccessible;
	int configType;
	string errorString;
	dyn_int requiredDrivers;
  dyn_int smoothProcedures;
  dyn_float deadbands, timeIntervals;

	configExists = FALSE;
	smoothProcedure = 0;
	deadband = 0;
	timeInterval = 0;

	_fwConfigs_checkAreConfigsAccessible(makeDynString(dpe), isAccessible, requiredDrivers, exceptionInfo);
	if(!isAccessible)
	{
		_fwConfigs_convertDriverNumbersToErrorMessage(requiredDrivers, errorString, exceptionInfo);
		fwException_raise(exceptionInfo, "ERROR", "To access the smoothing config, driver number " + errorString + " must be running.", errorString);
		return;
	}

	dpGet(dpe + ":_smooth.._type", configType);

	switch(configType)
	{
		case DPCONFIG_SMOOTH_SIMPLE_MAIN:
			_fwSmoothing_getParameters(dpe, FALSE, smoothProcedures, deadbands, timeIntervals, exceptionInfo);
			smoothProcedure=smoothProcedures[1];
      deadband=deadbands[1];
      timeInterval=timeIntervals[1];
			if(dynlen(exceptionInfo)>0)
				configExists = FALSE;  //unsupported type shown as not existing
			else
				configExists = TRUE;
			break;
			
		case DPCONFIG_NONE:
			break;
			
		default:
			fwException_raise(exceptionInfo, "ERROR", "fwSmoothing_get(): Smoothing config type (" + configType + ") not suppported", "");
			break;
	}	
} 

/** Gets the smoothing config from the given data point element. 
The function checks that the relevant driver is running. 
If not it returns an exception saying the config could not be read.

@par Constraints
	None

@par Usage
	Public

@par PVSS managers
	VISION, CTRL

@param dpes						data point elements. Passed as reference only for performance reasons. Not modified.
@param configExists		TRUE if smoothing config exists, else FALSE
@param smoothProcedure	DPATTR_VALUE_SMOOTH            	: value dependent,
												DPATTR_VALUE_REL_SMOOTH        	: relative value dependent,
												DPATTR_TIME_SMOOTH             	: time dependent,
												DPATTR_TIME_AND_VALUE_SMOOTH   	: value AND time dependent,
												DPATTR_TIME_AND_VALUE_REL_SMOOTH   : relative value AND time dependent,
												DPATTR_TIME_OR_VALUE_SMOOTH    	: value OR time dependent,
												DPATTR_TIME_OR_VALUE_REL_SMOOTH    : relative value OR time dependent,
												DPATTR_COMPARE_OLD_NEW         	: old-new comparison,
												DPATTR_OLD_NEW_AND_TIME_SMOOTH 	: old-new comparison AND time,
												DPATTR_OLD_NEW_OR_TIME_SMOOTH  	: old-new comparison OR time
@param deadband				Deadband value
@param timeInterval		Time interval in seconds
@param exceptionInfo	details of any errors are returned here
*/
fwSmoothing_getManyWithCheck(dyn_string &dpes, dyn_bool &configExists, dyn_int &smoothProcedure, dyn_float &deadband, dyn_float &timeInterval, dyn_string &exceptionInfo) 
{
	bool isAccessible;
	string errorString, configString;
	dyn_int requiredDrivers;
  dyn_string dsDpAttr, dsAttrVal, dsTypesAttr, dsTypesVal, dsStdTypesAttr, dsStdTypesVal;
  int i, j, k, length;

  configString = ":_smooth..";
  length = dynlen(dpes);

	_fwConfigs_checkAreConfigsAccessible(dpes, isAccessible, requiredDrivers, exceptionInfo);
	if(!isAccessible)
	{
		_fwConfigs_convertDriverNumbersToErrorMessage(requiredDrivers, errorString, exceptionInfo);
		fwException_raise(exceptionInfo, "ERROR", "To access the smoothing config, driver number " + errorString + " must be running.", errorString);
		return;
	}
  
  //get the types of all the dpes:
  for(i=1 ; i<=length ; i++)
    dsTypesAttr[i] = dpes[i] + ":_smooth.._type";
	dpGet(dsTypesAttr, dsTypesVal);
//   DebugN("types:\n",dsTypesAttr, dsTypesVal);
  
  //get the smooothing types of all the configured dpes:
  for(i=1 ; i<=length ; i++)
  {
  	switch(dsTypesVal[i])
  	{
  		case DPCONFIG_SMOOTH_SIMPLE_MAIN:
        dynAppend(dsStdTypesAttr,dpes[i]+configString+"_std_type");
      break;

   		case DPCONFIG_NONE:
  	  break;
        
  		default:
  			fwException_raise(exceptionInfo, "ERROR", "fwSmoothing_get(): Smoothing config type (" + dsTypesVal[i] + " on dpe '"+dpes[i]+"' not suppported", "");
  		break;
    }
  }
  if(dynlen(dsStdTypesAttr)>0)
    dpGet(dsStdTypesAttr, dsStdTypesVal);
//   DebugN("smooth procedure:\n",dsStdTypesAttr, dsStdTypesVal);
  
  //get the parameters of all the configured dpes, according to the smooth pocedure:
  j=1;
  for(i=1 ; i<=length ; i++)
  {
  	switch(dsTypesVal[i])
  	{
  		case DPCONFIG_SMOOTH_SIMPLE_MAIN:
        switch(dsStdTypesVal[j])
      	{
      		case DPATTR_VALUE_SMOOTH:
      		case DPATTR_VALUE_REL_SMOOTH:
            dynAppend(dsDpAttr, dpes[i] + configString + "_std_tol");// deadband
      		break;
      		case DPATTR_TIME_AND_VALUE_SMOOTH:
      		case DPATTR_TIME_OR_VALUE_SMOOTH:
      		case DPATTR_TIME_AND_VALUE_REL_SMOOTH:
      		case DPATTR_TIME_OR_VALUE_REL_SMOOTH:
            dynAppend(dsDpAttr, dpes[i] + configString + "_std_tol");// deadband
            dynAppend(dsDpAttr, dpes[i] + configString + "_std_time");// timeInterval
      		break;
      		case DPATTR_COMPARE_OLD_NEW:
      		break;
      		case DPATTR_TIME_SMOOTH:
      		case DPATTR_OLD_NEW_AND_TIME_SMOOTH:
      		case DPATTR_OLD_NEW_OR_TIME_SMOOTH:
            dynAppend(dsDpAttr, dpes[i] + configString + "_std_time");// timeInterval
      		break;
      		default:
      			fwException_raise(exceptionInfo, "ERROR",
      							"_fwSmoothing_getDetails(): Smoothing procedure " + smoothProcedure + " on dpe '"+dpes[i]+"' not suppported", "");
      		break;      
        }
      j++;
      break;  
      
   		case DPCONFIG_NONE:
        configExists[i] = false;
        smoothProcedure[i] = 0;
        deadband[i] = 0;
        timeInterval[i] = 0;
  	  break;        
     }

  }
  if(dynlen(dsDpAttr)>0)
    dpGet(dsDpAttr, dsAttrVal);
//   DebugN("available params:\n",dsDpAttr, dsAttrVal);
  
  //rearrange the results in the parameters variables
  k=1;
  j=1;
  for(i=1 ; i<=length ; i++)
  {
  	switch(dsTypesVal[i])
  	{
  		case DPCONFIG_SMOOTH_SIMPLE_MAIN:
        switch(dsStdTypesVal[j])
      	{
      		case DPATTR_VALUE_SMOOTH:
      		case DPATTR_VALUE_REL_SMOOTH:
            configExists[i] = true;
            smoothProcedure[i] = dsStdTypesVal[j];
            deadband[i] = dsAttrVal[k]; k++;
            timeInterval[i] = 0;          
      		break;
      		case DPATTR_TIME_AND_VALUE_SMOOTH:
      		case DPATTR_TIME_OR_VALUE_SMOOTH:
      		case DPATTR_TIME_AND_VALUE_REL_SMOOTH:
      		case DPATTR_TIME_OR_VALUE_REL_SMOOTH:
            configExists[i] = true;
            smoothProcedure[i] = dsStdTypesVal[j];
            deadband[i] = dsAttrVal[k]; k++;           
            timeInterval[i] = dsAttrVal[k]; k++;       
      		break;
      		case DPATTR_COMPARE_OLD_NEW:
            configExists[i] = true;
            smoothProcedure[i] = dsStdTypesVal[j];
            deadband[i] = 0;
            timeInterval[i] = 0;
       		break;
      		case DPATTR_TIME_SMOOTH:
      		case DPATTR_OLD_NEW_AND_TIME_SMOOTH:
      		case DPATTR_OLD_NEW_OR_TIME_SMOOTH:
            configExists[i] = true;
            smoothProcedure[i] = dsStdTypesVal[j];
            deadband[i] = 0;            
            timeInterval[i] = dsAttrVal[k]; k++;        
      		break;
      		default:
      			fwException_raise(exceptionInfo, "ERROR",
      							"_fwSmoothing_getDetails(): Smoothing procedure " + smoothProcedure + " on dpe '"+dpes[i]+"' not suppported", "");
      		break;      
        }
        j++;
      break;  
      
   		case DPCONFIG_NONE:
        configExists[i] = false;
        smoothProcedure[i] = 0;
        deadband[i] = 0;
        timeInterval[i] = 0;
  	  break;         
     }
//     DebugN("sorted param for: "+dpes[i], "configExists[i]: "+configExists[i], "smoothProcedure[i]: "+smoothProcedure[i], "deadband[i]: "+deadband[i], "timeInterval[i]: "+ timeInterval[i]);
  } 
}

/** Gets the smoothing config from the given data point element. 
The function checks that the relevant driver is running. 
If not it returns an exception saying the config could not be read.

@par Constraints
	None

@par Usage
	Public

@par PVSS managers
	VISION, CTRL

@param dpes						data point elements. Passed as reference only for performance reasons. Not modified.
@param configExists		TRUE if smoothing config exists, else FALSE
@param smoothProcedure	DPATTR_VALUE_SMOOTH            	: value dependent,
												DPATTR_VALUE_REL_SMOOTH        	: relative value dependent,
												DPATTR_TIME_SMOOTH             	: time dependent,
												DPATTR_TIME_AND_VALUE_SMOOTH   	: value AND time dependent,
												DPATTR_TIME_AND_VALUE_REL_SMOOTH   : relative value AND time dependent,
												DPATTR_TIME_OR_VALUE_SMOOTH    	: value OR time dependent,
												DPATTR_TIME_OR_VALUE_REL_SMOOTH    : relative value OR time dependent,
												DPATTR_COMPARE_OLD_NEW         	: old-new comparison,
												DPATTR_OLD_NEW_AND_TIME_SMOOTH 	: old-new comparison AND time,
												DPATTR_OLD_NEW_OR_TIME_SMOOTH  	: old-new comparison OR time
@param deadband				Deadband value
@param timeInterval		Time interval in seconds
@param exceptionInfo	details of any errors are returned here
*/
fwSmoothing_getMany(dyn_string &dpes, dyn_bool &configExists, dyn_int &smoothProcedure, dyn_float &deadband, dyn_float &timeInterval, dyn_string &exceptionInfo) 
{
	bool isAccessible;
	string errorString, configString;
	dyn_int requiredDrivers, diTmpSmoothProcedure;
  dyn_string dsDpAttr, dsAttrVal, dsTypesAttr, dsTypesVal, dsTempVal, dsDpesWithConfig;
  dyn_float dfTmpDeadband, dfTmpTimeInterval;
  int i, j, k, length;

  configString = ":_smooth..";
  length = dynlen(dpes);

	_fwConfigs_checkAreConfigsAccessible(dpes, isAccessible, requiredDrivers, exceptionInfo);
	if(!isAccessible)
	{
		_fwConfigs_convertDriverNumbersToErrorMessage(requiredDrivers, errorString, exceptionInfo);
		fwException_raise(exceptionInfo, "ERROR", "fwSmoothing_getMany: To access the smoothing config, driver number " + errorString + " must be running.", errorString);
		return;
	}
  
  //get the types of all the dpes:
  for(i=1 ; i<=length ; i++)
  {
    dynAppend(dsTypesAttr, dpes[i] + configString + "_type");
		if(dynlen(dsTypesAttr)>fwConfigs_OPTIMUM_DP_GET_SIZE || (i==length && dynlen(dsTypesAttr)>0))
		{
  	  dpGet(dsTypesAttr, dsTempVal);
      dynAppend(dsTypesVal, dsTempVal);
			dynClear(dsTypesAttr);
    }    
  }  
  //get the types of all the dpes:
  for(i=1 ; i<=length ; i++)
  {
  	if(dsTypesVal[i]== DPCONFIG_SMOOTH_SIMPLE_MAIN)
      dynAppend(dsDpesWithConfig, dpes[i]);  
  }
//   DebugN("types:\n", dsTypesVal);
  if(dynlen(dsDpesWithConfig))
    _fwSmoothing_getParameters(dsDpesWithConfig, false, diTmpSmoothProcedure, 
                               dfTmpDeadband, dfTmpTimeInterval, exceptionInfo);
  k=1;  
  for(i=1 ; i<=length ; i++)
  {
  	switch(dsTypesVal[i])
  	{
  		case DPCONFIG_SMOOTH_SIMPLE_MAIN:  
            configExists[i] = true;
            smoothProcedure[i] = diTmpSmoothProcedure[k]; 
            deadband[i] = dfTmpDeadband[k]; 
            timeInterval[i] = dfTmpTimeInterval[k]; 
            k++;        
      break;  
      
   		case DPCONFIG_NONE:
            configExists[i] = false;
            smoothProcedure[i] = 0;
            deadband[i] = 0;
            timeInterval[i] = 0;  
      break;      
    }
  }
    
   return;
  
  //get the parameters of all the configured dpes, according to the smooth pocedure:
  for(i=1 ; i<=length ; i++)
  {
  	switch(dsTypesVal[i])
  	{
  		case DPCONFIG_SMOOTH_SIMPLE_MAIN:
            dynAppend(dsDpAttr, dpes[i] + configString + "_std_type");// smooth proc
            dynAppend(dsDpAttr, dpes[i] + configString + "_std_tol");// deadband
            dynAppend(dsDpAttr, dpes[i] + configString + "_std_time");// timeInterval
      break;  
      
   		case DPCONFIG_NONE:
        configExists[i] = false;
        smoothProcedure[i] = 0;
        deadband[i] = 0;
        timeInterval[i] = 0;
  	  break;      
      
  		default:
  			fwException_raise(exceptionInfo, "ERROR", "fwSmoothing_getMany(): Smoothing config type (" + dsTypesVal[i] + " on dpe '"+dpes[i]+"' not suppported", "");
  		break;    
    }
		if((dynlen(dsDpAttr)>fwConfigs_OPTIMUM_DP_GET_SIZE) || (dynlen(dsDpAttr)>0 && (i == length)))
		{
//       DebugN("dsDpAttr:",dsDpAttr);
  	  dpGet(dsDpAttr, dsTempVal);
      dynAppend(dsAttrVal, dsTempVal);
			dynClear(dsDpAttr);
    }      
  }
//   DebugN("available params:\n", dsAttrVal);
  
  //get the parameters variables
  k=1;
  for(i=1 ; i<=length ; i++)
  {
  	switch(dsTypesVal[i])
  	{
  		case DPCONFIG_SMOOTH_SIMPLE_MAIN:
        switch(dsAttrVal[k])
      	{
         	case DPATTR_VALUE_SMOOTH:
      		case DPATTR_VALUE_REL_SMOOTH:
      		case DPATTR_TIME_AND_VALUE_SMOOTH:
      		case DPATTR_TIME_OR_VALUE_SMOOTH:
      		case DPATTR_TIME_AND_VALUE_REL_SMOOTH:
      		case DPATTR_TIME_OR_VALUE_REL_SMOOTH:
      		case DPATTR_COMPARE_OLD_NEW:
      		case DPATTR_TIME_SMOOTH:
      		case DPATTR_OLD_NEW_AND_TIME_SMOOTH:
      		case DPATTR_OLD_NEW_OR_TIME_SMOOTH:
            configExists[i] = true;
            smoothProcedure[i] = dsAttrVal[k]; k++;
            deadband[i] = dsAttrVal[k]; k++;
            timeInterval[i] = dsAttrVal[k]; k++;      
      		break;
      		default:
      			fwException_raise(exceptionInfo, "ERROR",
      							"fwSmoothing_getMany(): Smoothing procedure " + dsAttrVal[j] + " on dpe '"+dpes[i]+"' not suppported", "");
      		break;      
        }
      break;  
      
   		case DPCONFIG_NONE:
        configExists[i] = false;
        smoothProcedure[i] = 0;
        deadband[i] = 0;
        timeInterval[i] = 0;
  	  break;         
     }
//     DebugN("sorted param for: "+dpes[i], "configExists[i]: "+configExists[i], "smoothProcedure[i]: "+smoothProcedure[i], "deadband[i]: "+deadband[i], "timeInterval[i]: "+ timeInterval[i]);
  } 
  dynClear(dsDpAttr);
  dynClear(dsAttrVal);
  dynClear(dsTypesVal);
  dynClear(dsTypesAttr);
}



// fwSmoothing_getManyOld(dyn_string &dpes, dyn_bool &configExists, dyn_int &smoothProcedure, dyn_float &deadband, dyn_float &timeInterval, dyn_string &exceptionInfo) 
// {
// 	int i, length;
// 	
// 	length = dynlen(dpes);
// 	for(i=1; i<=length; i++)
// 	{
// 		fwSmoothing_get(dpes[i], configExists[i], smoothProcedure[i], deadband[i], timeInterval[i], exceptionInfo);
// 	}  
// }


/** Gets the parameters of the smoothing in the archiving or smoothing config of a given dpe.
NOTE: This function does not check if the smoothing config exists nor if the archive config has smoothing configured
(this must be done before using this function)

@par Constraints
	None

@par Usage
	Public

@par PVSS managers
	VISION, CTRL

@param dpes							data point element
@param isArchiveConfig	TRUE to read archive config smoothing parameters
												FALSE to read smoothing config smoothing parameters
@param smoothProcedure	DPATTR_VALUE_SMOOTH            	: value dependent,
												DPATTR_VALUE_REL_SMOOTH        	: relative value dependent,
												DPATTR_TIME_SMOOTH             	: time dependent,
												DPATTR_TIME_AND_VALUE_SMOOTH   	: value AND time dependent,
												DPATTR_TIME_AND_VALUE_REL_SMOOTH   : relative value AND time dependent,
												DPATTR_TIME_OR_VALUE_SMOOTH    	: value OR time dependent,
												DPATTR_TIME_OR_VALUE_REL_SMOOTH    : relative value OR time dependent,
												DPATTR_COMPARE_OLD_NEW         	: old-new comparison,
												DPATTR_OLD_NEW_AND_TIME_SMOOTH 	: old-new comparison AND time,
												DPATTR_OLD_NEW_OR_TIME_SMOOTH  	: old-new comparison OR time
@param deadband					deadband value returned here
@param timeInterval			time in seconds returned here
@param exceptionInfo	details of any errors are returned here
*/
_fwSmoothing_getParameters(dyn_string &dpes, bool isArchiveConfig, dyn_int &smoothProcedure, dyn_float &deadband, dyn_float &timeInterval, dyn_string &exceptionInfo)
{
	string configString;
  dyn_string dsDpAttr;
  dyn_anytype daAttrVal, daTempVal;
  int i, j, k, length, iSmoothType;
  int ret;

	if(isArchiveConfig)
		configString = ":_archive.1.";
	else
		configString = ":_smooth..";
  
  length = dynlen(dpes);
  
  //get the parameters of all the configured dpes, according to the smooth pocedure:
    for(i=1 ; i<=length ; i++)
    {
      dynAppend(dsDpAttr, dpes[i] + configString + "_std_type");// smooth proc
      dynAppend(dsDpAttr, dpes[i] + configString + "_std_tol");// deadband
      dynAppend(dsDpAttr, dpes[i] + configString + "_std_time");// timeInterval  

  		if((dynlen(dsDpAttr)>fwConfigs_OPTIMUM_DP_GET_SIZE) || (dynlen(dsDpAttr)>0 && (i == length)))
  		{
//         DebugN("dsDpAttr:",dsDpAttr);
    	  ret = dpGet(dsDpAttr, daTempVal);        
        if(dynlen(daTempVal)<1)
        {
          //a problem occurred: one or more dpes have incomplete smoothing settings
          //as fallback, get the dpes one by one, and report the misconfigured one(s).
          dynClear(daTempVal);
          for(j=1 ; j<=dynlen(dsDpAttr) ; j++)
          {
//             DebugN("##############getting dpe "+j+"/"+dynlen(dsDpAttr)+": ",dsDpAttr[j]);
            daTempVal[j] ="";
            if(dpExists(dsDpAttr[j]))
            {
     	        ret = dpGet(dsDpAttr[j], daTempVal[j]);     
//               DebugN("##############dpe "+j+"/"+dynlen(dsDpAttr)+": ",dsDpAttr[j],"got. Return: ",ret);
            }              
            else
            {
              fwException_raise(exceptionInfo, "WARNING",
      							"_fwSmoothing_getParameters(): Could not get the smoothing setting "+dsDpAttr[j]+". Smoothing setting for the dpe will be flagged as none", "");
            }
            if(ret!=0)
              fwException_raise(exceptionInfo, "WARNING",
      							"_fwSmoothing_getParameters(): Could not get the smoothing setting "+dsDpAttr[j]+". Smoothing setting for the dpe will be flagged as none", "");
          }          
        }
        dynAppend(daAttrVal, daTempVal);
  			dynClear(dsDpAttr);
        if(ret!=0)
        {
      			fwException_raise(exceptionInfo, "ERROR",
      							"_fwSmoothing_getParameters(): Could not get the smoothing procedure for one or more dpes. See dpe list dump.", "");
            DebugTN(exceptionInfo, "_fwSmoothing_getParameters(): Dpe list dump:", dsDpAttr);
            return;
        }        
      }     
    }
    
//   DebugN("attrib len: "+dynlen(daAttrVal)+" Expected: ",3*length);
  //get the parameters variables
  if(dynlen(daAttrVal)>0)
  {  
	  k=1;
	  for(i=1 ; i<=length ; i++)
	  {
//       if(i>1150)DebugN(dpes[i]);
      iSmoothType = daAttrVal[k];
			switch(iSmoothType)
			{
				case DPATTR_VALUE_SMOOTH:
				case DPATTR_VALUE_REL_SMOOTH:
				case DPATTR_TIME_AND_VALUE_SMOOTH:
				case DPATTR_TIME_OR_VALUE_SMOOTH:
				case DPATTR_TIME_AND_VALUE_REL_SMOOTH:
				case DPATTR_TIME_OR_VALUE_REL_SMOOTH:
				case DPATTR_COMPARE_OLD_NEW:
				case DPATTR_TIME_SMOOTH:
				case DPATTR_OLD_NEW_AND_TIME_SMOOTH:
				case DPATTR_OLD_NEW_OR_TIME_SMOOTH:
  				smoothProcedure[i] = daAttrVal[k]; k++;
  				deadband[i] = daAttrVal[k]; k++;
  				timeInterval[i] = daAttrVal[k]; k++;      
				break;
				default:
  				smoothProcedure[i] = 0; k++;
  				deadband[i] = 0; k++;
  				timeInterval[i] = 0; k++;      
  				fwException_raise(exceptionInfo, "ERROR",
  									"_fwSmoothing_getParameters(): Smoothing procedure " + daAttrVal[j] + " on dpe '"+dpes[i]+"' not suppported", "");
				break;      
			}
	//     DebugN("sorted param for: "+dpes[i], "smoothProcedure[i]: "+smoothProcedure[i], "deadband[i]: "+deadband[i], "timeInterval[i]: "+ timeInterval[i]);
	  } 
  }
  dynClear(dsDpAttr);
  dynClear(daAttrVal);
}

//old version
/*_fwSmoothing_getParameters(string dpe, bool isArchiveConfig, int &smoothProcedure, float &deadband, float &timeInterval, dyn_string &exceptionInfo)
{
	string configString;

	if(isArchiveConfig)
		configString = ":_archive.1.";
	else
		configString = ":_smooth..";

	deadband = 0;
	timeInterval = 0;

	dpGet(dpe + configString + "_std_type", smoothProcedure); 

    switch(smoothProcedure)
    {
		case DPATTR_VALUE_SMOOTH:
		case DPATTR_VALUE_REL_SMOOTH:
			dpGet(	dpe + configString + "_std_tol", deadband);
			break;
		case DPATTR_TIME_AND_VALUE_SMOOTH:
		case DPATTR_TIME_OR_VALUE_SMOOTH:
		case DPATTR_TIME_AND_VALUE_REL_SMOOTH:
		case DPATTR_TIME_OR_VALUE_REL_SMOOTH:
			dpGet(	dpe + configString + "_std_tol", deadband,
					dpe + configString + "_std_time", timeInterval);
			break;
		case DPATTR_COMPARE_OLD_NEW:
			break;
		case DPATTR_TIME_SMOOTH:
		case DPATTR_OLD_NEW_AND_TIME_SMOOTH:
		case DPATTR_OLD_NEW_OR_TIME_SMOOTH:
			dpGet(	dpe + configString + "_std_time", timeInterval);
			break;
		default:
			fwException_raise(exceptionInfo, "ERROR",
							"_fwSmoothing_getDetails(): Smoothing procedure (" + smoothProcedure + ") not suppported", "");
			break;
	}
}*/


/** Sets the parameters of the smoothing in the archiving or smoothing config of a given dpe. 
NOTE: This function does not create the smoothing config nor set up smoothing for the archiving config
(this must be done before using this function)

@par Constraints
	None

@par Usage
	Public

@par PVSS managers
	VISION, CTRL

@param dpes							list of data point elements
@param isArchiveConfig	TRUE to read archive config smoothing parameters
												FALSE to read smoothing config smoothing parameters
@param smoothProcedure	DPATTR_VALUE_SMOOTH            	: value dependent,
												DPATTR_VALUE_REL_SMOOTH        	: relative value dependent,
												DPATTR_TIME_SMOOTH             	: time dependent,
												DPATTR_TIME_AND_VALUE_SMOOTH   	: value AND time dependent,
												DPATTR_TIME_AND_VALUE_REL_SMOOTH   : relative value AND time dependent,
												DPATTR_TIME_OR_VALUE_SMOOTH    	: value OR time dependent,
												DPATTR_TIME_OR_VALUE_REL_SMOOTH    : relative value OR time dependent,
												DPATTR_COMPARE_OLD_NEW         	: old-new comparison,
												DPATTR_OLD_NEW_AND_TIME_SMOOTH 	: old-new comparison AND time,
												DPATTR_OLD_NEW_OR_TIME_SMOOTH  	: old-new comparison OR time
@param deadband					deadband value
@param timeInterval			time in seconds
@param exceptionInfo	details of any errors are returned here
@param storeInParamHistory		Optional parameter (default value = TRUE) - TRUE to archive the parameter change, else FALSE
*/
_fwSmoothing_setParameters(dyn_string dpes, bool isArchiveConfig, dyn_int smoothProcedure, 
                           dyn_float deadband, dyn_float timeInterval, dyn_string &exceptionInfo, 
                           bool storeInParamHistory = TRUE)
{
	int i, length;
  dyn_errClass errors;
	string configString;
	dyn_string attributesToSet;
	dyn_anytype valuesToSet;

	if(isArchiveConfig)
		configString = ":_archive.1.";
	else
		configString = ":_smooth..";

	length = dynlen(dpes);
	for(i=1; i<=length; i++)
	{
		switch(smoothProcedure[i])
		{
			case DPATTR_VALUE_SMOOTH:
			case DPATTR_VALUE_REL_SMOOTH:
				dynAppend(attributesToSet, dpes[i] + configString + "_std_type");
				dynAppend(attributesToSet, dpes[i] + configString + "_std_tol");
				dynAppend(valuesToSet, smoothProcedure[i]);
				dynAppend(valuesToSet, deadband[i]);
				break;
			case DPATTR_TIME_AND_VALUE_SMOOTH:
			case DPATTR_TIME_OR_VALUE_SMOOTH:
			case DPATTR_TIME_AND_VALUE_REL_SMOOTH:
			case DPATTR_TIME_OR_VALUE_REL_SMOOTH:
				dynAppend(attributesToSet, dpes[i] + configString + "_std_type");
				dynAppend(attributesToSet, dpes[i] + configString + "_std_tol");
				dynAppend(attributesToSet, dpes[i] + configString + "_std_time");
				dynAppend(valuesToSet, smoothProcedure[i]);
				dynAppend(valuesToSet, deadband[i]);
				dynAppend(valuesToSet, timeInterval[i]);
				break;
			case DPATTR_COMPARE_OLD_NEW:
				dynAppend(attributesToSet, dpes[i] + configString + "_std_type");
				dynAppend(valuesToSet, smoothProcedure[i]);
				break;
			case DPATTR_TIME_SMOOTH:
			case DPATTR_OLD_NEW_AND_TIME_SMOOTH:
			case DPATTR_OLD_NEW_OR_TIME_SMOOTH:
				dynAppend(attributesToSet, dpes[i] + configString + "_std_type");
				dynAppend(attributesToSet, dpes[i] + configString + "_std_time");
				dynAppend(valuesToSet, smoothProcedure[i]);
				dynAppend(valuesToSet, timeInterval[i]);
				break;
			default:
				fwException_raise(exceptionInfo, "ERROR", "_fwSmoothing_setDetails(): Smoothing procedure (" + smoothProcedure + ")  for dpe '"+dpes[i]+"' not suppported", "");
				return;
				break;
		}

		if((dynlen(attributesToSet) > fwConfigs_OPTIMUM_DP_SET_SIZE) || (i == length))
		{
      if(storeInParamHistory)
  			dpSetWait(attributesToSet, valuesToSet);
      else
				dpSetTimedWait(0, attributesToSet, valuesToSet);
			errors = getLastError(); 
    	if(dynlen(errors) > 0)
    	{ 
	 			throwError(errors);
		 		fwException_raise(exceptionInfo, "ERROR", "_fwSmoothing_setDetails(): Could not set smoothing parameters", "");
			}
			dynClear(attributesToSet);
			dynClear(valuesToSet);
		}
	}
}

//@}
