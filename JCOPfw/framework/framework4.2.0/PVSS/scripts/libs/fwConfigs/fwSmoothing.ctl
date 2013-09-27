/**@file

This library contains function associated with the smoothing config.
Functions are provided for getting the current settings, deleting the config
and setting the config 

@par Creation Date
	19/06/2000

@par Modification History
	Oliver:	cases for "combined smoothing and time" and " old/new comparison and time" added ability
							to get/set time interval when available
	15/09/00  Oliver: added error handling to save and delete functions
	15/01/04	Oliver: Completed overhaul of whole library
	21/01/04	Oliver: Added functionality for relative deadband values.
							Seperated out get and set of smoothing parameters (for use by fwArchive and fwSmoothing functions)
	
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
*/
fwSmoothing_setMany(dyn_string dpes, dyn_int smoothProcedure, dyn_float deadband, dyn_float timeInterval, dyn_string &exceptionInfo, bool runDriverCheck = FALSE) 
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

	_fwSmoothing_setParameters(dpes, FALSE, smoothProcedure, deadband, timeInterval, exceptionInfo);
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
*/
fwSmoothing_setMultiple(dyn_string dpes, int smoothProcedure, float deadband, float timeInterval, dyn_string &exceptionInfo, bool runDriverCheck = FALSE) 
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
	
	fwSmoothing_setMany(dpes, diSmoothProcedure, dfDeadband, dfTimeInterval, exceptionInfo, runDriverCheck);
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
						The necessary driver number must be running in order to successfully create config
*/
fwSmoothing_set(string dpe, int smoothProcedure, float deadband, float timeInterval, dyn_string &exceptionInfo, bool runDriverCheck = FALSE) 
{
	fwSmoothing_setMany(makeDynString(dpe), makeDynInt(smoothProcedure), makeDynFloat(deadband),
												makeDynFloat(timeInterval), exceptionInfo, runDriverCheck);
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
			_fwSmoothing_getParameters(dpe, FALSE, smoothProcedure, deadband, timeInterval, exceptionInfo);
			
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


/** Gets the smoothing config from the given list of data point elements. 
The function checks that the relevant driver is running. 
If not it returns an exception saying the config could not be read.

@par Constraints
	None

@par Usage
	Public

@par PVSS managers
	VISION, CTRL

@param dpes						data point elements
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
fwSmoothing_getMany(dyn_string dpes, dyn_bool &configExists, dyn_int &smoothProcedure, dyn_float &deadband, dyn_float &timeInterval, dyn_string &exceptionInfo) 
{
	int i, length;
	
	length = dynlen(dpes);
	for(i=1; i<=length; i++)
	{
		fwSmoothing_get(dpes[i], configExists[i], smoothProcedure[i], deadband[i], timeInterval[i], exceptionInfo);
	}
}


/** Gets the parameters of the smoothing in the archiving or smoothing config of a given dpe.
NOTE: This function does not check if the smoothing config exists nor if the archive config has smoothing configured
(this must be done before using this function)

@par Constraints
	None

@par Usage
	Public

@par PVSS managers
	VISION, CTRL

@param dpe							data point element
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
_fwSmoothing_getParameters(string dpe, bool isArchiveConfig, int &smoothProcedure, float &deadband, float &timeInterval, dyn_string &exceptionInfo)
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
}

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
*/
_fwSmoothing_setParameters(dyn_string dpes, bool isArchiveConfig, dyn_int smoothProcedure, dyn_float deadband, dyn_float timeInterval, dyn_string &exceptionInfo)
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
				fwException_raise(exceptionInfo, "ERROR", "_fwSmoothing_setDetails(): Smoothing procedure (" + smoothProcedure + ") not suppported", "");
				return;
				break;
		}

		if((dynlen(attributesToSet) > fwConfigs_OPTIMUM_DP_SET_SIZE) || (i == length))
		{
			dpSetWait(attributesToSet, valuesToSet);
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
