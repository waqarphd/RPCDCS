/**@file

This library contains function associated with generic tasks for all configs.

@par Creation Date
	15/01/2004

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
/** Checks that the config can be read/written on a given list of dpes - for use with smoothing and conversion configs. 
This is dependant on the driver number running that is specified in the _address config of the same dpe. 
If no _address config exists, then there must be a simulation driver 1 running (which is running by default in PVSS projects).

@par Constraints
	All dpes must be from the same system

@par Usage
	Public

@par PVSS managers
	VISION, CTRL

@param dpes							list of data point elements
@param areAccessible		returns TRUE if configs are accessible (because the necessary drivers are running)
												returns FALSE if configs are not accessible (because the necessary drivers are not running)
@param requiredDrivers	if areAccessible = FALSE, a list of the drivers that are needed but not running is returned
@param exceptionInfo		details of any exceptions are returned here
*/
_fwConfigs_checkAreConfigsAccessible(dyn_string dpes, bool &areAccessible, dyn_int &requiredDrivers, dyn_string &exceptionInfo)
{
	int i, position, length, configType;
	dyn_bool areRunning;
	dyn_int tempValues, driverNumbers;
	dyn_string typeAttributes, driverAttributes, systems;

	dynClear(requiredDrivers);
	dynClear(typeAttributes);
	dynClear(driverAttributes);

	length = dynlen(dpes);
	for(i=1; i<=length; i++)
	{
		dynAppend(typeAttributes, dpes[i] + ":_distrib.._type");
		dynAppend(driverAttributes, dpes[i] + ":_distrib.._driver");
		
		if((dynlen(typeAttributes) > fwConfigs_OPTIMUM_DP_GET_SIZE) || (i == length))
		{
			dpGet(typeAttributes, tempValues);
			dynClear(typeAttributes);

			while(dynContains(tempValues, DPCONFIG_NONE) > 0)
			{
				dynAppend(driverNumbers, 1);
				position = dynContains(tempValues, DPCONFIG_NONE);
				dynRemove(tempValues, position);
				dynRemove(driverAttributes, position);
			}
			
			if(dynlen(driverAttributes) > 0)
			{
				dpGet(driverAttributes, tempValues);
				dynAppend(driverNumbers, tempValues);
				dynClear(driverAttributes);
			}
		}
	}

	dynUnique(driverNumbers);
	 
	_fwConfigs_getSystemsInDpeList(dpes, systems, exceptionInfo);		
	if(dynlen(systems) > 1)
	{
		fwException_raise(exceptionInfo, "ERROR", "_fwConfigs_checkAreConfigsAccessible(): All dpes must be from the same system.", "");
		areAccessible = FALSE;
		return;
	}
	else if(dynlen(systems) == 1)
		fwPeriphAddress_checkAreDriversRunning(driverNumbers, areRunning, exceptionInfo, systems[1]);

	if(dynContains(areRunning, FALSE) > 0)
	{
		length = dynlen(areRunning);
		for(i=1; i<=length; i++)
		{
			if(!areRunning[i])
				dynAppend(requiredDrivers, driverNumbers[i]);
		}
		areAccessible = FALSE;
	}
	else
		areAccessible = TRUE;

//DebugN(driverNumbers, areRunning, requiredDrivers);
}


/** This function converts a list of driver numbers (a dyn_int) into a nice human readable string of numbers in the format "1, 2, 3 and 4".

@par Constraints
	None

@par Usage
	Internal

@par PVSS managers
	VISION, CTRL

@param driverNumbers	the list of driver numbers
@param errorMessage		Output - the "nice" string is returned here
@param exceptionInfo	details of any errors are returned here
*/
_fwConfigs_convertDriverNumbersToErrorMessage(dyn_int driverNumbers, string &errorMessage, dyn_string &exceptionInfo)
{
	int i, length;

	errorMessage = "";
	length = dynlen(driverNumbers);
	
	if(length == 1)
	{
		errorMessage = driverNumbers[1];
		return;
	}
	
	for(i=1; i<=length; i++)
	{
		if(i!=length)
			errorMessage += driverNumbers[i] + ", ";
		else
		{
			errorMessage = substr(errorMessage, 0, strlen(errorMessage) - 2);
			errorMessage += " and " + driverNumbers[i];
		}
	}
}


/** Deletes the specified config for the given data point elements

@par Constraints
	All dpes in the list must be from the same system

@par Usage
	Internal

@par PVSS managers
	VISION, CTRL

@param dpes						list of data point elements
@param configType				the type of the config to read
@param exceptionInfo	details of any errors are returned here
@param setWithTime	OPTIONAL PARAMETER - default -1, use dpSetWait
				If value is >= 0 then dpSetTimedWait is used with the given value
				If value is 0, then a dpSetTimedWait with t=0 is used which sometimes avoids data going to the param history
*/
_fwConfigs_delete(dyn_string dpes, string configType, dyn_string &exceptionInfo, float setWithTime = -1)
{
	int i, length;
	dyn_anytype typeValuesToSet;
	dyn_string localException;
		
	length = dynlen(dpes);
	for(i=1; i<=length; i++)
		dynAppend(typeValuesToSet, DPCONFIG_NONE);
	
	_fwConfigs_setConfigTypeAttribute(dpes, configType, typeValuesToSet, localException, ".._type", setWithTime);
	if(dynlen(localException)>0)
	{
		if(localException[dynlen(localException)] == fwConfigs_SET_LOCKED)
			fwException_raise(exceptionInfo, "ERROR", "_fwConfigs_delete(): Some of the " + configType + " configs were locked", "");
		else
			fwException_raise(exceptionInfo, "ERROR", "_fwConfigs_delete(): Could not delete some of the " + configType + " configs", "");
	}
}

/** This functions is used to get the ..type attributes of the given config for a list of dpes
This function uses dpGet grouping to speed up performance compared to simply reading each attribute one by one.

@par Constraints
	All dpes in the list must be from the same system

@par Usage
	Internal

@par PVSS managers
	VISION, CTRL

@param dpes							list of data point elements from which the type attribute should be read
@param configType				the type of the config to read
@param attributeValues	a list containing the results of the dpGet is returned here
@param exceptionInfo		details of any errors are returned here
@param customAttribute	Optional parameter - default value ".._type"
													this can be used to access a different attribute to the default type attribute
													if a value is not passed, the .._type attribute is read
*/
_fwConfigs_getConfigTypeAttribute(dyn_string dpes, string configType, dyn_mixed &attributeValues, dyn_string &exceptionInfo, string customAttribute = ".._type")
{
	int i, length;
	dyn_dyn_mixed rawValues;

	_fwConfigs_getConfigAttributes(dpes, configType, makeDynString(customAttribute), rawValues, exceptionInfo);

	length = dynlen(rawValues);
	for(i=1; i<=length; i++)
		attributeValues[i] = rawValues[i][1];	
}


/** This functions is used to get the values of a list attributes of the given config for a list of dpes.
This function reads the same attributes for each of the given dpes.  If you need to read from different attributes on each dpe, use
	_fwConfigs_getAttributes.
This function uses dpGet grouping to speed up performance compared to simply reading each attribute one by one.

@par Constraints
	All dpes in the list must be from the same system

@par Usage
	Internal

@par PVSS managers
	VISION, CTRL

@param dpes							list of data point elements from which the attributes should be read
@param configType				the type of the config to read
@param attributes				the list of attributes to be read from the config on each dpe (given in form e.g. ".._type")
@param attributeValues	an array containing the results attribute values from each dpe is returned here
													e.g. attributeValues[1][2] = value of attribute read from dpe[1] and attributes[2]
@param exceptionInfo		details of any errors are returned here
*/
_fwConfigs_getConfigAttributes(dyn_string dpes, string configType, dyn_string attributes, dyn_dyn_mixed &attributeValues, dyn_string &exceptionInfo)
{
	int i, j, numberOfDpes, numberOfAttributes;
	dyn_dyn_string configAttributes;
	
	numberOfAttributes = dynlen(attributes);
	
	numberOfDpes = dynlen(dpes);
	for(i=1; i<=numberOfDpes; i++)
	{
		for(j=1; j<=numberOfAttributes; j++)
		{
			configAttributes[i][j] = dpes[i] + ":" + configType + attributes[j];
		}
	}
	
	_fwConfigs_getAttributes(configAttributes, attributeValues, exceptionInfo);
}


/** This functions is used to get the values of defined config attributes for a list of dpes
This function can get different attributes for each dpe.  If you want to read the same attributes for each dpe, use 
	_fwConfigs_getConfigAttributes()
This function uses dpGet grouping to speed up performance compared to simply reading each attribute one by one.

@par Constraints
	All dpes in the list must be from the same system
	There is no checking of the inputs to this function.  It is designed for speed, so any checking is your own responsibility!

@par Usage
	Internal

@par PVSS managers
	VISION, CTRL

@param dpeAttributes		an array of dpe attributes to be read (given in form e.g. "dpe:_config.._attribute")
												The first dimension of the array should be used to divide up the attributes for each dpe
												The second dimension is used to list all the attributes to be read for each dpe
													e.g.	dpeAttributes[1][1] = "dpe1:_alert.._type"
																dpeAttributes[1][2] = "dpe1:_original.._attribute"
																dpeAttributes[1][3] = "dpe1:_smooth.._type"
																dpeAttributes[2][1] = "dpe2:_original.._value"
																dpeAttributes[3][1] = "dpe3:_pv_range.._type"
																dpeAttributes[3][2] = "dpe3:_original.._exp_inv"
@param attributeValues	an array containing the results attribute values from each dpe is returned here
												The array elements correspond to the same cells in which the attribute was put in dpeAttributes
@param exceptionInfo		details of any errors are returned here
*/
_fwConfigs_getAttributes(dyn_dyn_string dpeAttributes, dyn_dyn_mixed &attributeValues, dyn_string &exceptionInfo)
{
  int i, j, length, attributeCount, numberOfDpes, dpeCounter = 1, attributeCounter;
  dyn_int numberOfAttributes;
  dyn_mixed valuesRead, tempValuesRead;
  dyn_string attributesToRead, attributesGivingError, localExceptionInfo;
  mixed tempValueRead;
  int ret;
	
	dynClear(attributeValues);
	
	numberOfDpes = dynlen(dpeAttributes);
	
	for(i=1; i<=numberOfDpes; i++)
	{
		numberOfAttributes[i] = dynlen(dpeAttributes[i]);
		for(j=1; j<=numberOfAttributes[i]; j++)
			attributeCount = dynAppend(attributesToRead, dpeAttributes[i][j]);

		if((attributeCount > fwConfigs_OPTIMUM_DP_GET_SIZE) || ((i == numberOfDpes) && (attributeCount != 0)))
		{
			ret = dpGet(attributesToRead, tempValuesRead);
    localExceptionInfo=getLastError();
    if(ret<0 || dynlen(localExceptionInfo))
    {
      dynClear(exceptionInfo);
	 			fwException_raise(exceptionInfo, "ERROR", "_fwConfigs_getAttributes(): Could not get some of the attributes. See printed list.", fwConfigs_SET_FAILED);      
//          DebugTN("One or some of these attributes gave an error:");       
//          DebugTN(attributesToRead);      
//       DebugTN("_fwConfigs_getAttributes(): Looking for the attribute(s) that caused the error...");
      dynClear(attributesGivingError);
		   for(j=1; j<=dynlen(attributesToRead); j++)
      {
        tempValueRead=0;
//         DebugTN("checking "+attributesToRead[j]);       
        ret = dpGet(attributesToRead[j], tempValueRead);
        exceptionInfo=getLastError();
        if(ret<0 || dynlen(exceptionInfo))
          dynAppend(attributesGivingError,attributesToRead[j]);    
//         else
//            DebugTN(attributesToRead[j]+" ok");            
      }
      dynClear(exceptionInfo);
	 			fwException_raise(exceptionInfo, "INFO", "_fwConfigs_getAttributes(): List of attributes generating error: "+ attributesGivingError, "");      
//       DebugTN("_fwConfigs_getAttributes(): List of attributes generating error:");       
//       DebugTN(attributesGivingError);      
    }
			dynAppend(valuesRead, tempValuesRead);
			dynClear(attributesToRead);      
		}
	}
  exceptionInfo = localExceptionInfo;
	
	attributeCounter = 1;
	length = dynlen(valuesRead);

	for(i=1; i<=length; i++)
	{
		if(i>numberOfAttributes[dpeCounter])
		{
			numberOfAttributes[dpeCounter+1] = numberOfAttributes[dpeCounter] + numberOfAttributes[dpeCounter+1];
			dpeCounter++;
			attributeCounter = 1;
		}
		attributeValues[dpeCounter][attributeCounter++] = valuesRead[i];
	}	
}


/** This functions is used to set the ..type attributes of the given config for a list of dpes
This function uses dpSetWait grouping to speed up performance compared to simply reading each attribute one by one.

@par Constraints
	All dpes in the list must be from the same system

@par Usage
	Internal

@par PVSS managers
	VISION, CTRL

@param dpes							list of data point elements from which the type attribute should be read
@param configType				the type of the config to read
@param attributeValues	a list containing the values to be written to each ..type attribute
@param exceptionInfo		details of any errors are returned here
@param customAttribute	Optional parameter - default value ".._type"
													this can be used to access a different attribute to the default type attribute
													if a value is not passed, the .._type attribute is set
@param setWithTime	OPTIONAL PARAMETER - default -1, use dpSetWait
				If value is >= 0 then dpSetTimedWait is used with the given value
				If value is 0, then a dpSetTimedWait with t=0 is used which sometimes avoids data going to the param history
*/
_fwConfigs_setConfigTypeAttribute(dyn_string dpes, string configType, dyn_anytype attributeValues, dyn_string &exceptionInfo, string customAttribute = ".._type", float setWithTime = -1)
{
	int i, length;
	dyn_dyn_anytype valuesToWrite;

	length = dynlen(attributeValues);
	for(i=1; i<=length; i++)
		valuesToWrite[i][1] = attributeValues[i];

	_fwConfigs_setConfigAttributes(dpes, configType, makeDynString(customAttribute), valuesToWrite, exceptionInfo, setWithTime);
}


/** This functions is used to set the values of a list attributes of the given config for a list of dpes
This function sets the same attributes for each of the given dpes.  If you need to write to different attributes on each dpe, use
	_fwConfigs_setAttributes.
This function uses dpGet grouping to speed up performance compared to simply reading each attribute one by one.

@par Constraints
	All dpes in the list must be from the same system

@par Usage
	Internal

@par PVSS managers
	VISION, CTRL

@param dpes							list of data point elements to which the attributes should be written
@param configType				the type of the config to write to
@param attributes	the list of attributes to be wrriten to the config on each dpe (given in form e.g. ".._type")
@param attributeValues	an array containing the attribute values to write to each dpe
													e.g. attributeValues[3][4] = value of attribute to write to configAttributes[3][4] of dpe[3]
@param exceptionInfo		details of any errors are returned here
@param setWithTime	OPTIONAL PARAMETER - default -1, use dpSetWait
				If value is >= 0 then dpSetTimedWait is used with the given value
				If value is 0, then a dpSetTimedWait with t=0 is used which sometimes avoids data going to the param history
*/
_fwConfigs_setConfigAttributes(dyn_string dpes, string configType, dyn_string attributes, dyn_dyn_anytype attributeValues, dyn_string &exceptionInfo, float setWithTime = -1)
{
	int i, j, numberOfDpes, numberOfAttributes;
	dyn_dyn_string configAttributes;
	
	numberOfAttributes = dynlen(attributes);
	
	numberOfDpes = dynlen(dpes);
	for(i=1; i<=numberOfDpes; i++)
	{
		for(j=1; j<=numberOfAttributes; j++)
		{
			configAttributes[i][j] = dpes[i] + ":" + configType + attributes[j];
		}
	}
	_fwConfigs_setAttributes(configAttributes, attributeValues, exceptionInfo, setWithTime);
}


/** This functions is used to set the values of defined config attributes for a list of dpes
This function can set different attributes for each dpe.  If you want to write to the same attributes for each dpe, use 
	_fwConfigs_setConfigAttributes()
This function uses dpGet grouping to speed up performance compared to simply reading each attribute one by one.

@par Constraints
	All dpes in the list must be from the same system
	There is no checking of the inputs to this function.  It is designed for speed, so any checking is your own responsibility!

@par Usage
	Internal

@par PVSS managers
	VISION, CTRL

@param dpeAttributes		an array of dpe attributes to be write (given in form e.g. "dpe:_config.._attribute")
												The first dimension of the array should be used to divide up the attributes for each dpe
												The second dimension is used to list all the attributes to be read for each dpe
													e.g.	dpeAttributes[1][1] = "dpe1:_alert.._type"
																dpeAttributes[1][2] = "dpe1:_original.._attribute"
																dpeAttributes[1][3] = "dpe1:_smooth.._type"
																dpeAttributes[2][1] = "dpe2:_original.._value"
																dpeAttributes[3][1] = "dpe3:_pv_range.._type"
																dpeAttributes[3][2] = "dpe3:_original.._exp_inv"
@param attributeValues	an array containing the attribute values to write to each dpe
												The array elements correspond to the same cells in which the attribute was put in dpeAttributes
@param exceptionInfo		details of any errors are returned here
@param setWithTime	OPTIONAL PARAMETER - default -1, use dpSetWait
				If value is >= 0 then dpSetTimedWait is used with the given value
				If value is 0, then a dpSetTimedWait with t=0 is used which sometimes avoids data going to the param history
*/
_fwConfigs_setAttributes(dyn_dyn_string dpeAttributes, dyn_dyn_anytype attributeValues, dyn_string &exceptionInfo, float setWithTime = -1)
{
	int i, j, attributeCount, numberOfDpes, numberOfAttributes;
	dyn_anytype setValues;
	dyn_string attributesToWrite;
	dyn_errClass errors;
		
	numberOfDpes = dynlen(dpeAttributes);

	for(i=1; i<=numberOfDpes; i++)
	{
		numberOfAttributes = dynlen(dpeAttributes[i]);
		for(j=1; j<=numberOfAttributes; j++)
		{
			attributeCount = dynAppend(attributesToWrite, dpeAttributes[i][j]);
			setValues[attributeCount] = attributeValues[i][j];
		}
		
		if((attributeCount > fwConfigs_OPTIMUM_DP_SET_SIZE) || (i == numberOfDpes))
		{
//DebugN(attributesToWrite, setValues);
//DebugN(setWithTime, setWithTime < 0);
			if(setWithTime < 0)
				dpSetWait(attributesToWrite, setValues);
			else
				dpSetTimedWait(setWithTime, attributesToWrite, setValues);				

			errors = getLastError(); 
    	if(dynlen(errors) > 0)
    	{ 
	 			throwError(errors);
	 			fwException_raise(exceptionInfo, "ERROR", "_fwConfigs_setAttributes(): Could not set some attributes.", fwConfigs_SET_FAILED);
			}
			dynClear(attributesToWrite);
			dynClear(setValues);
		}
	}
}


/** Checks that all the dpes in the list can be configured with the same type of config
eg. BOOLs and INTs can have different types of config settings for alert handling
So if a list containing a mixture of BOOLs and INTs was passed and config = fwConfigs_PVSS_ALERT_HDL, the function would return FALSE.

@par Constraints
	None

@par Usage
	Internal

@par PVSS managers
	VISION, CTRL

@param dpes						list of data point elements
@param config					the type of config to check consistency for:
												fwConfigs_PVSS_ADDRESS
												fwConfigs_PVSS_ARCHIVE
												fwConfigs_PVSS_ALERT_HDL
												fwConfigs_PVSS_ORIGINAL
												fwConfigs_PVSS_PV_RANGE
												fwConfigs_PVSS_SMOOTH
												fwConfigs_PVSS_MSG_CONV
												fwConfigs_PVSS_CMD_CONV
												fwConfigs_PVSS_COMMON
@param chosenDpeType	the function returns the type of the first valid data point element in the list
@param exceptionInfo	details of any errors are returned here
@param errorString		Output - in case the function returns FALSE, an error message is returned here which can be used to raise an exception
@return	 							BOOLEAN - TRUE is list of dpes can all be configured with the same type of config, else FALSE
*/
bool _fwConfigs_checkDpeList(dyn_string dpes, string config, string &chosenDpeType,
								dyn_string &exceptionInfo, string &errorString)
{
	bool firstCheck = TRUE;
	int i, returnValue = -1, length, configType, previousConfigType;
	dyn_string localException;

	errorString = "";

	length = dynlen(dpes);
	for(i=1; i<=length; i++)
	{
		_fwConfigs_getConfigOptionsForDpe(dpes[i], config, configType, localException);
		if(dynlen(localException)>0)
		{
			if(strpos(localException[dynlen(localException)-1], "does not exist") >= 0)
				errorString = getCatStr("fwConfigs", "ERROR_DPESNOTEXISTING");
			else
			{
				errorString = getCatStr("fwConfigs", "ERROR_BADDPETYPES");
				strreplace(errorString, "<config>", config);
			}
			chosenDpeType = fwConfigs_NOT_SUPPORTED;
			return FALSE;
		}
		else if(returnValue < 0)
		{
			if(firstCheck)
			{
				firstCheck = FALSE;
				previousConfigType = configType;
				chosenDpeType = dpElementType(dpes[i]);
				//DebugN(chosenDpeType);
			}
			
			if(configType == fwConfigs_NOT_SUPPORTED)
			{
				errorString = getCatStr("fwConfigs", "ERROR_BADDPETYPES");
				strreplace(errorString, "<config>", config);
				returnValue = 0;		
			}
			else if(configType != previousConfigType)
			{
				//if archiving or smoothing then if mixture of analog and digital types, give no error but allow only digital types
				if((config == fwConfigs_PVSS_ARCHIVE) || (config == fwConfigs_PVSS_SMOOTH))
				{
					chosenDpeType = DPEL_BOOL;
					returnValue = 1;
				}
				else
				{
					errorString = getCatStr("fwConfigs", "ERROR_MIXEDDPETYPES");
					strreplace(errorString, "<config>", config);
					returnValue = 0;		
				}
			}
			else
			{
				//store latest dpeType, but if we have a float type dpe, then this is overridden by any others.
				switch(chosenDpeType)
				{
					case DPEL_FLOAT:  
					case DPEL_FLOAT_STRUCT:  
					case DPEL_DYN_FLOAT:  
					case DPEL_DYN_FLOAT_STRUCT:  
						break;
					default:
						chosenDpeType = dpElementType(dpes[i]);
						break;
				}
			}
		}
	}
	
	if(returnValue == 0)
		return FALSE;
	else
		return TRUE;
}


/** Checks what kind of config type is supported by the given data point element type
eg.	DPEL_BOOL can support only a BINARY alert handling config 
		DPEL_INT can support only an ANALOG alert handling config

Note:  This function does not check whether the config is supported by PVSS for dpes of the data point element type
		It only offers the most suitable method according to the JCOP FW regardless of PVSS support for such a config.

@par Constraints
	None

@par Usage
	Internal

@par PVSS managers
	VISION, CTRL

@param dpeType				a data point type eg. DPEL_BOOL
@param config					the type of config to check consistency for:
												fwConfigs_PVSS_ADDRESS
												fwConfigs_PVSS_ARCHIVE
												fwConfigs_PVSS_ALERT_HDL
												fwConfigs_PVSS_ORIGINAL
												fwConfigs_PVSS_PV_RANGE
												fwConfigs_PVSS_SMOOTH
												fwConfigs_PVSS_MSG_CONV
												fwConfigs_PVSS_CMD_CONV
												fwConfigs_PVSS_DP_FUNCT
												fwConfigs_PVSS_UNIT
												fwConfigs_PVSS_FORMAT
@param configOptions	the function returns the type of config that is suitable for the given type:
												fwConfigs_GENERAL_OPTIONS
												fwConfigs_BINARY_OPTIONS
												fwConfigs_ANALOG_OPTIONS
												fwConfigs_NOT_SUPPORTED (if a config is not supported by the dpeType)
@param exceptionInfo	details of any errors are returned here
*/
_fwConfigs_getConfigOptionsForDpeType(int dpeType, string config, int &configOptions, dyn_string &exceptionInfo)
{
	if((dpeType == DPEL_DPID) || (dpeType == DPEL_DYN_DPID) || (dpeType == DPEL_DPID_STRUCT) || (dpeType == DPEL_DYN_DPID_STRUCT))
	{
		fwException_raise(exceptionInfo, "ERROR", "The JCOP framework does not support the " + config + " config for DPID data point elements", "");
		configOptions = fwConfigs_NOT_SUPPORTED;
		return;
	}

	if((dpeType == DPEL_STRUCT) && (config != fwConfigs_PVSS_ALERT_HDL))
	{
		fwException_raise(exceptionInfo, "ERROR", "The JCOP framework does not support the " + config + " config for Structure data point elements", "");
		configOptions = fwConfigs_NOT_SUPPORTED;
		return;
	}

	switch(config)
	{
		case fwConfigs_PVSS_UNIT:
			switch(dpeType)
			{
				case DPEL_TIME:  
				case DPEL_DYN_TIME:  
				case DPEL_TIME_STRUCT:  
				case DPEL_DYN_TIME_STRUCT:  
					fwException_raise(exceptionInfo, "ERROR", "The JCOP framework does not support the " + config + " config for TIME data point elements", "");
					configOptions = fwConfigs_NOT_SUPPORTED;
					break;
				default:
					configOptions = fwConfigs_GENERAL_OPTIONS;
					break;
			}
			break;
		case fwConfigs_PVSS_DP_FUNCT:
		case fwConfigs_PVSS_ADDRESS:
			configOptions = fwConfigs_GENERAL_OPTIONS;
			break;
		case fwConfigs_PVSS_PV_RANGE:
			switch(dpeType)
			{
		    case DPEL_CHAR:  
		    case DPEL_INT:
		    case DPEL_CHAR_STRUCT:  
		    case DPEL_INT_STRUCT:
		    case DPEL_FLOAT:
		    case DPEL_FLOAT_STRUCT:
		    	//support min-max and sets
					configOptions = fwConfigs_ANALOG_OPTIONS;
					break;
		    case DPEL_UINT:
		    case DPEL_UINT_STRUCT:
		    	//support min-max, sets and pattern match
					configOptions = fwConfigs_GENERAL_OPTIONS;
					break;
		    case DPEL_BIT32:  
		    case DPEL_STRING:
		    case DPEL_BIT32_STRUCT:  
		    case DPEL_STRING_STRUCT:
		    	//support sets and pattern match
					configOptions = fwConfigs_BINARY_OPTIONS;
					break;
				default:
					configOptions = fwConfigs_NOT_SUPPORTED;
					break;
		  }  
			break;
		case fwConfigs_PVSS_ORIGINAL:
			switch(dpeType)
			{
				case DPEL_BOOL:  
				case DPEL_INT:  
				case DPEL_UINT:  
			  case DPEL_FLOAT:  
				case DPEL_STRING:  
				case DPEL_LANGSTRING:  
					configOptions = fwConfigs_GENERAL_OPTIONS;
			    break;  
				case DPEL_DYN_BOOL:  
				case DPEL_DYN_INT:  
				case DPEL_DYN_UINT:  
		   	case DPEL_DYN_FLOAT:  
				case DPEL_DYN_STRING:  
				case DPEL_DYN_LANGSTRING:  
					configOptions = fwConfigs_ANALOG_OPTIONS;
					break;
				default:
					configOptions = fwConfigs_NOT_SUPPORTED;
					break;
			}
			break;
		case fwConfigs_PVSS_FORMAT:
			switch(dpeType)
			{
				case DPEL_UINT:  
				case DPEL_UINT_STRUCT:  
				case DPEL_DYN_UINT:  
				case DPEL_DYN_UINT_STRUCT:  
				case DPEL_INT:  
				case DPEL_INT_STRUCT:  
				case DPEL_DYN_INT:  
				case DPEL_DYN_INT_STRUCT:  
				case DPEL_BLOB:  
				case DPEL_BLOB_STRUCT:  
				case DPEL_DYN_BLOB:  
				case DPEL_DYN_BLOB_STRUCT:  
				case DPEL_STRING:  
				case DPEL_STRING_STRUCT:  
				case DPEL_DYN_STRING:  
				case DPEL_DYN_STRING_STRUCT:  
				case DPEL_LANGSTRING:  
				case DPEL_LANGSTRING_STRUCT:  
				case DPEL_DYN_LANGSTRING:  
				case DPEL_DYN_LANGSTRING_STRUCT:  
					configOptions = fwConfigs_BINARY_OPTIONS;
			    break;  
			  case DPEL_FLOAT:  
		  	case DPEL_FLOAT_STRUCT:  
		   	case DPEL_DYN_FLOAT:  
		    case DPEL_DYN_FLOAT_STRUCT:  
					configOptions = fwConfigs_ANALOG_OPTIONS;
					break;
				default:
					fwException_raise(exceptionInfo, "ERROR", "The JCOP framework does not support the " + config + " for certain data point elements", "");
					configOptions = fwConfigs_NOT_SUPPORTED;
					break;
			}
			break;
		case fwConfigs_PVSS_ARCHIVE:
		case fwConfigs_PVSS_SMOOTH:
			switch(dpeType)
			{
				case DPEL_CHAR:
				case DPEL_CHAR_STRUCT:
				case DPEL_INT:
				case DPEL_INT_STRUCT:
				case DPEL_UINT:
				case DPEL_UINT_STRUCT:
				case DPEL_FLOAT:
				case DPEL_FLOAT_STRUCT:
					configOptions = fwConfigs_ANALOG_OPTIONS;
					break;
				default:
					configOptions = fwConfigs_GENERAL_OPTIONS;
					break;
			}
			break;
		case fwConfigs_PVSS_MSG_CONV:
		case fwConfigs_PVSS_CMD_CONV:
			switch(dpeType)
			{
				case DPEL_BOOL:
					fwException_raise(exceptionInfo, "ERROR", "The JCOP framework does not support the " + config + " config for BOOLEAN data point elements", "");
					configOptions = fwConfigs_NOT_SUPPORTED;
					break;
				default:
					configOptions = fwConfigs_ANALOG_OPTIONS;
					break;
			}
			break;
		case fwConfigs_PVSS_ALERT_HDL:
			switch(dpeType)
			{
				case DPEL_BOOL:
				case DPEL_DYN_BOOL:
					configOptions = fwConfigs_BINARY_OPTIONS;
					break;
				case DPEL_INT:
				case DPEL_UINT:
				case DPEL_FLOAT:
					configOptions = fwConfigs_ANALOG_OPTIONS;
					break;
				default:
					configOptions = fwConfigs_GENERAL_OPTIONS;
					break;
			}
			break;
		default:
			configOptions = fwConfigs_NOT_SUPPORTED;
			break;
	}
}


/** Checks what kind of config type is supported by the given data point element
eg.	DPEL_BOOL can support only a BINARY alert handling config 
		DPEL_INT can support only an ANALOG alert handling config

Note:  This function implements both the policy of PVSS and the JCOP FW in terms of what dpe type can support what type of config

@par Constraints
	None

@par Usage
	Internal

@par PVSS managers
	VISION, CTRL

@param dpe						a data point element
@param config					the type of config to check consistency for:
												fwConfigs_PVSS_ADDRESS
												fwConfigs_PVSS_ARCHIVE
												fwConfigs_PVSS_ALERT_HDL
												fwConfigs_PVSS_ORIGINAL
												fwConfigs_PVSS_PV_RANGE
												fwConfigs_PVSS_SMOOTH
												fwConfigs_PVSS_MSG_CONV
												fwConfigs_PVSS_CMD_CONV
												fwConfigs_PVSS_UNIT
												fwConfigs_PVSS_FORMAT
@param configOptions	the function returns the type of config that is suitable for the given type:
												fwConfigs_GENERAL_OPTIONS
												fwConfigs_BINARY_OPTIONS
												fwConfigs_ANALOG_OPTIONS
												fwConfigs_NOT_SUPPORTED (if a config is not supported by the dpe)
@param exceptionInfo	details of any errors are returned here
*/
_fwConfigs_getConfigOptionsForDpe(string dpe, string config, int &configOptions, dyn_string &exceptionInfo)
{
	int dpeType;
	dyn_string allPossibleConfigs;
	
	if(!dpExists(dpe))
	{
		fwException_raise(exceptionInfo, "ERROR", "The data point element does not exist", "");
		configOptions = fwConfigs_NOT_SUPPORTED;
		return;		
	}
		
	if((config != fwConfigs_PVSS_UNIT) && (config != fwConfigs_PVSS_FORMAT))
	{
		allPossibleConfigs = dpGetAllConfigs(dpe);
		if(dynContains(allPossibleConfigs, config) <= 0)
		{
			fwException_raise(exceptionInfo, "ERROR", "PVSS does not support the " + config + " config for " + dpe, "");
			configOptions = fwConfigs_NOT_SUPPORTED;
			return;
		}
	}
	
	dpeType = dpElementType(dpe);
	_fwConfigs_getConfigOptionsForDpeType(dpeType, config, configOptions, exceptionInfo);
}

/** Provides a text version of the dpElementType of a given dpe

@par Constraints
	None

@par Usage
	Public

@par PVSS managers
	VISION, CTRL

@param dpe						a data point element
@param dpeTypeName		a text version of the data point element type eg: BOOLEAN (returned value if dpe is of type DPEL_BOOL)
@param exceptionInfo	details of any errors are returned here
*/
fwConfigs_getDpeTypeText(string dpe, string &dpeTypeName, dyn_string &exceptionInfo)
{
  if(dpExists(dpe))
  {
		fwConfigs_getDataTypeText(dpElementType(dpe), dpeTypeName, exceptionInfo);
	}
	else
		dpeTypeName = "Does not exist";
}

/** Provides a text version of a given data type

@par Constraints
	None

@par Usage
	Public

@par PVSS managers
	VISION, CTRL

@param dataType				a data type
@param dataTypeText		a text version of the data type eg: BOOLEAN (returned value if dpe is of type DPEL_BOOL)
@param exceptionInfo	details of any errors are returned here
*/
fwConfigs_getDataTypeText(int dataType, string &dataTypeText, dyn_string &exceptionInfo)
{
	switch(dataType)
	{
		//BIT32 Types
		case DPEL_BIT32:
			dataTypeText = "BIT32";
			break;
		case DPEL_BIT32_STRUCT:
			dataTypeText = "BIT32 Structure";
			break;
		case DPEL_DYN_BIT32:
			dataTypeText = "Dyn BIT32";
			break;
		case DPEL_DYN_BIT32_STRUCT:
			dataTypeText = "Dyn BIT32 Structure";
			break;
		//BLOB Types
		case DPEL_BLOB:
			dataTypeText = "BLOB";
			break;
		case DPEL_BLOB_STRUCT:
			dataTypeText = "BLOB Structure";
			break;
		case DPEL_DYN_BLOB:
			dataTypeText = "Dyn BLOB";
			break;
		case DPEL_DYN_BLOB_STRUCT:
			dataTypeText = "Dyn BLOB Structure";
			break;
		//BOOL Types
		case DPEL_BOOL:
			dataTypeText = "BOOLEAN";
			break;
		case DPEL_BOOL_STRUCT:
			dataTypeText = "BOOLEAN Structure";
			break;
		case DPEL_DYN_BOOL:
			dataTypeText = "Dyn BOOLEAN";
			break;
		case DPEL_DYN_BOOL_STRUCT:
			dataTypeText = "Dyn BOOLEAN Structure";
			break;
		//CHAR Types
		case DPEL_CHAR:
			dataTypeText = "CHAR";
			break;
		case DPEL_CHAR_STRUCT:
			dataTypeText = "CHAR Structure";
			break;
		case DPEL_DYN_CHAR:
			dataTypeText = "Dyn CHAR";
			break;
		case DPEL_DYN_CHAR_STRUCT:
			dataTypeText = "Dyn CHAR Structure";
			break;
		//UINT Types
		case DPEL_UINT:
			dataTypeText = "UNSIGNED";
			break;
		case DPEL_UINT_STRUCT:
			dataTypeText = "UNSIGNED Structure";
			break;
		case DPEL_DYN_UINT:
			dataTypeText = "Dyn UNSIGNED";
			break;
		case DPEL_DYN_UINT_STRUCT:
			dataTypeText = "Dyn UNSIGNED Structure";
			break;
		//INT Types
		case DPEL_INT:
			dataTypeText = "INTEGER";
			break;
		case DPEL_INT_STRUCT:
			dataTypeText = "INTEGER Structure";
			break;
		case DPEL_DYN_INT:
			dataTypeText = "Dyn INTEGER";
			break;
		case DPEL_DYN_INT_STRUCT:
			dataTypeText = "Dyn INTEGER Structure";
			break;
		//FLOAT Types
		case DPEL_FLOAT:
			dataTypeText = "FLOAT";
			break;
		case DPEL_FLOAT_STRUCT:
			dataTypeText = "FLOAT Structure";
			break;
		case DPEL_DYN_FLOAT:
			dataTypeText = "Dyn FLOAT";
			break;
		case DPEL_DYN_FLOAT_STRUCT:
			dataTypeText = "Dyn FLOAT Structure";
			break;
		//STRING Types
			case DPEL_STRING:
			dataTypeText = "STRING";
			break;
		case DPEL_STRING_STRUCT:
			dataTypeText = "STRING Structure";
			break;
		case DPEL_DYN_STRING:
			dataTypeText = "Dyn STRING";
			break;
		case DPEL_DYN_STRING_STRUCT:
			dataTypeText = "Dyn STRING Structure";
			break;
		//LANGSTRING Types
		case DPEL_LANGSTRING:
			dataTypeText = "LANGSTRING";
			break;
		case DPEL_LANGSTRING_STRUCT:
			dataTypeText = "LANGSTRING Structure";
			break;
		case DPEL_DYN_LANGSTRING:
			dataTypeText = "Dyn LANGSTRING";
			break;
		case DPEL_DYN_LANGSTRING_STRUCT:
			dataTypeText = "Dyn LANGSTRING Structure";
			break;
		//TIME Types
		case DPEL_TIME:
			dataTypeText = "TIME";
			break;
		case DPEL_TIME_STRUCT:
			dataTypeText = "TIME Structure";
			break;
		case DPEL_DYN_TIME:
			dataTypeText = "Dyn TIME";
			break;
		case DPEL_DYN_TIME_STRUCT:
			dataTypeText = "Dyn TIME Structure";
			break;
		//DPID Types
		case DPEL_DPID:
			dataTypeText = "DPID";
			break;
		case DPEL_DPID_STRUCT:
			dataTypeText = "DPID Structure";
			break;
		case DPEL_DYN_DPID:
			dataTypeText = "Dyn DPID";
			break;
		case DPEL_DYN_DPID_STRUCT:
			dataTypeText = "Dyn DPID Structure";
			break;
		//STRUCT Type
		case DPEL_STRUCT:
			dataTypeText = "Structure";
			break;
		//TYPEREF Type
		case DPEL_TYPEREF:
			dataTypeText = "Type Reference";
			break;
		default:
			dataTypeText = "Unknown";
			fwException_raise(exceptionInfo, "ERROR", "fwConfigs_getDpeTypeText(): Data point element type not recognised", "");
			break;
	}    	
}

/** Provides a format string that is sufficiently flexible to show all the formats of the dpes given in the list

For more info on format strings, see the PVSS Online Help -> CONTROL -> Control Graphics -> Graphics Objects -> Format string

@par Constraints
	None

@par Usage
	Public

@par PVSS managers
	VISION, CTRL

@param dpes						a list of data point elements
@param formatString		a format which allows display of all the given dpes in the format specified in the common config on each dpe
@param exceptionInfo	details of any errors are returned here
*/
fwConfigs_getBestFormatForDpeList(dyn_string dpes, string &formatString, dyn_string &exceptionInfo)
{
	bool firstRun = TRUE;
	int i, length;
	string oldFormat, newFormat;

	length = dynlen(dpes);
	for(i=1; i<=length; i++)
	{
		if(dpExists(dpes[i]))
		{
			newFormat = dpGetFormat(dpes[i]);
			if(newFormat == "")
				_fwConfigs_getDefaultFormatForDpeType(dpElementType(dpes[i]), newFormat, exceptionInfo);
				
			if(firstRun)
			{
				firstRun = FALSE;
				oldFormat = newFormat;
			}
			
			_fwConfigs_chooseBestFormat(oldFormat, newFormat, oldFormat, exceptionInfo);			
		}
		else
			fwException_raise(exceptionInfo, "ERROR", "fwConfigs_setTextFieldsFormatWithDpeList(): Data point element not found", "");
	}
	
	formatString = oldFormat;
}

/** Provides a format string that is sufficiently flexible to show the required format for a dpe

For more info on format strings, see the PVSS Online Help -> CONTROL -> Control Graphics -> Graphics Objects -> Format string

@par Constraints
	None

@par Usage
	Public

@par PVSS managers
	VISION, CTRL

@param dpe						a data point element
@param formatString		a format which allows display of the given dpe in the format specified in the common config on that dpe
@param exceptionInfo	details of any errors are returned here
*/
fwConfigs_getBestFormatForDpe(string dpe, string &formatString, dyn_string &exceptionInfo)
{
	fwConfigs_getBestFormatForDpeList(makeDynString(dpe), formatString, exceptionInfo);
}

/** Provides a format string that is sufficiently flexible to show the required format for a dpe type

For more info on format strings, see the PVSS Online Help -> CONTROL -> Control Graphics -> Graphics Objects -> Format string

@par Constraints
	None

@par Usage
	Public

@par PVSS managers
	VISION, CTRL

@param dpeType						a data point element type
@param formatString		a format which allows display of the given dpe type in the format best suited to that data type
@param exceptionInfo	details of any errors are returned here
*/
fwConfigs_getBestFormatForDpeType(string dpeType, string &formatString, dyn_string &exceptionInfo)
{
	_fwConfigs_getDefaultFormatForDpeType(dpeType, formatString, exceptionInfo);
}

/** Sets the format attributes of the given list of text fields to the specified format

For more info on format strings, see the PVSS Online Help -> CONTROL -> Control Graphics -> Graphics Objects -> Format string

@par Constraints
	None

@par Usage
	Public

@par PVSS managers
	VISION

@param textFields			a list of text fields to operate on
@param formatString		the format which you wish to apply to the text fields
@param formatOptions	these are the additional options that can be set when the formatting of a text field is defined
												formatOptions[1] is EmptyifZero
												formatOptions[2] is LeadingZeros
												formatOptions[3] is Alignment
												formatOptions[4] is Exponentialrep
@param exceptionInfo	details of any errors are returned here
*/
fwConfigs_setTextFieldsFormat(dyn_string textFields, string formatString, dyn_bool formatOptions, dyn_string &exceptionInfo)
{
	shape shapeToFormat;
	int i, length;
	
	strreplace(formatString, "%", "");
	
	formatString = "[" + formatString;
	
	length = dynlen(formatOptions);
	for(i=1; i<=length; i++)
	{
		formatString += ("," + formatOptions[i]);
	}

	length = dynlen(textFields);
	for(i=1; i<=length; i++)
	{
		if(shapeExists(textFields[i]))
		{
			shapeToFormat = getShape(textFields[i]);
			shapeToFormat.format = formatString;
		}
		else
			fwException_raise(exceptionInfo, "ERROR", "_fwConfigs_setTextFieldsFormat(): Shape \"" + textFields[i] + "\" not found", "");
	}
}

/** Given two formats, this function will identify which is the most flexible for displaying various data and return that format

For more info on format strings, see the PVSS Online Help -> CONTROL -> Control Graphics -> Graphics Objects -> Format string

@par Constraints
	None

@par Usage
	Internal

@par PVSS managers
	VISION, CTRL

@param format1				the first format to consider
@param format2				the second format to consider
@param bestFormat			the most flexible of the two formats is returned here
@param exceptionInfo	details of any errors are returned here
*/
_fwConfigs_chooseBestFormat(string format1, string format2, string &bestFormat, dyn_string &exceptionInfo)
{
	string formatType1, formatType2, resultType, temp;
	dyn_int formatSize1, formatSize2, resultSize;
	int i, length1, length2;
	mapping extraSpaceRequired;
	
	//create a mapping storing info on extra characters required by format types
	//eg	%6.3f requires 6+3 characters plus an extra 1 for the .
	//		%6.3e requires 6+3 characters plus an extra 6 for the . and the exponent
	extraSpaceRequired["s"] = 0;
	extraSpaceRequired["e"] = 6;
	extraSpaceRequired["f"] = 1;
	extraSpaceRequired["d"] = 0;

	//special case - if either format is %s, always return %s
	if((format1 == "%s") || (format2 == "%s"))
	{
		bestFormat = "%s";
		return;
	}
	
	//read the format type, by getting the last character from each format string
	formatType1 = substr(format1, strlen(format1)-1, 1);
	formatType2 = substr(format2, strlen(format2)-1, 1);
	
	//read data between % and the last character
	//then split with a . to get all integers from format string into dyn_ints
	//item 1 is the value before the . for floats and exps, or the only value in case of ints and string
	//item 2 is the value after the . for floats and exps only
	temp = substr(format1, 1, strlen(format1)-2);
	formatSize1 = strsplit(temp, ".");
	temp = substr(format2, 1, strlen(format2)-2);
	formatSize2 = strsplit(temp, ".");
	
	//add extra space to ensure dyn_ints are both of length 2
	while(dynlen(formatSize1)<2)
		dynAppend(formatSize1, 0);
	while(dynlen(formatSize2)<2)
		dynAppend(formatSize2, 0);
	
	//make a 3rd entry based on the sum of the two other entries plus any extra characters required
	//this 3rd entry gives the max length of a string required to hold the data in the specified format
	formatSize1[3] = formatSize1[1] + formatSize1[2] + extraSpaceRequired[formatType1];
	formatSize2[3] = formatSize2[1] + formatSize2[2] + extraSpaceRequired[formatType2];
	
	//find the most universal type of format that can be used
	//if either is a string, we need a string
	if((formatType1 == "s") || (formatType2 == "s"))
		resultType = "s";
	//if either is a exp, we need a exp
	else if((formatType1 == "e") || (formatType2 == "e"))
		resultType = "e";
	//if either is a float, we need a float
	else if((formatType1 == "f") || (formatType2 == "f"))
		resultType = "f";
	//else an int will do
	else
		resultType = "d";

	//for each entry in the format dyn_ints, find the biggest value and store in resultSize
	for(i=1; i<=3; i++)
	{
		if(formatSize1[i] >= formatSize2[i])
			resultSize[i] = formatSize1[i];
		else
			resultSize[i] = formatSize2[i];
	}		
		
	//if required format is string, build format string using resultSize[3] (total size)
	if(resultType == "s")
		bestFormat = "%" + resultSize[3] + resultType;
	//if required format is int, build format string using resultSize[3] (total size)
	else if(resultType == "d")
		bestFormat = "%" + resultSize[3] + resultType;
	//if required format is exp or float, build format string using resultSize[1] (after decimal point) and resultSize[1] (after decimal point)
	else
		bestFormat = "%" + resultSize[1] + "." + resultSize[2] + resultType;
}

/** This function will return the default fromat for a given dpe type
(based on dpGetDefaultFormat in libCTRL.ctl)

For more info on format strings, see the PVSS Online Help -> CONTROL -> Control Graphics -> Graphics Objects -> Format string

@par Constraints
	None

@par Usage
	Internal

@par PVSS managers
	VISION, CTRL

@param dpeType				the dpe type to get the format for
@param format					the default format used for this dpe type
@param exceptionInfo	details of any errors are returned here
*/
_fwConfigs_getDefaultFormatForDpeType(int dpeType, string &format, dyn_string &exceptionInfo)
{
	switch(dpeType)
	{
		case DPEL_UINT:  
		case DPEL_UINT_STRUCT:  
		case DPEL_INT:  
		case DPEL_INT_STRUCT:  
		case DPEL_DYN_UINT:  
		case DPEL_DYN_UINT_STRUCT:  
		case DPEL_DYN_INT:  
		case DPEL_DYN_INT_STRUCT:  
			//choose an integer format which provides plenty of characters for people to enter
			format = "%15d";
			break;
		case DPEL_CHAR:  
		case DPEL_CHAR_STRUCT:  
		case DPEL_DYN_CHAR:  
		case DPEL_DYN_CHAR_STRUCT:  
			format = "%1s";
			break;  
		case DPEL_FLOAT:  
		case DPEL_FLOAT_STRUCT:  
		case DPEL_DYN_FLOAT:  
		case DPEL_DYN_FLOAT_STRUCT:  
			//use string at the moment due to limitations of float format in text field
			format = "%s";
			break;
		case DPEL_BIT32:  
		case DPEL_DYN_BIT32:  
			format = "%32s";
			break;
		case DPEL_TIME:  
		case DPEL_DYN_TIME:  
			format = "%23s";
			break;
		default:  
			//by default, choose string to give flexibility
			format = "%s";
			break;
	}  
}

/** This function checks whether a value as a string (for example as entered in a text field)
is consistent with the default value formatting for a given dpe type

For more info on format strings, see the PVSS Online Help -> CONTROL -> Control Graphics -> Graphics Objects -> Format string

@par Constraints
	None

@par Usage
	Public

@par PVSS managers
	VISION, CTRL

@param value					the value to check (as a string)
@param dpeType				the dpe type to use to verify the formatting of the value (presumably the target dpe for the value to be written to)
@param isOk						returns TRUE if the value is formatted OK for the dpe, else FALSE
@param exceptionInfo	details of any errors are returned here
*/
fwConfigs_checkStringFormat(string value, int dpeType, bool &isOk, dyn_string &exceptionInfo)
{
	string format;

	switch(dpeType)
	{
		case DPEL_UINT:  
		case DPEL_UINT_STRUCT:  
		case DPEL_INT:  
		case DPEL_INT_STRUCT:  
		case DPEL_DYN_UINT:  
		case DPEL_DYN_UINT_STRUCT:  
		case DPEL_DYN_INT:  
		case DPEL_DYN_INT_STRUCT:  
			format = "%50d";
			break;
		case DPEL_CHAR:  
		case DPEL_CHAR_STRUCT:  
		case DPEL_DYN_CHAR:  
		case DPEL_DYN_CHAR_STRUCT:  
			format = "%1s";
			break;  
		case DPEL_FLOAT:  
		case DPEL_FLOAT_STRUCT:  
		case DPEL_DYN_FLOAT:  
		case DPEL_DYN_FLOAT_STRUCT:  
			format = "%50.50e";
			break;
		case DPEL_BIT32:  
		case DPEL_DYN_BIT32:  
			format = "%32s";
			break;
		case DPEL_TIME:  
		case DPEL_DYN_TIME:  
			format = "%23s";
			break;
		default:  
			format = "%s";
			break;
	}  
	
	isOk = checkStringFormat(value, format);
}

/** This functions checks the state of the lock of a given config on a given dpe

@par Constraints
	None

@par Usage
	Public

@par PVSS managers
	VISION, CTRL

@param dpe						the data point in question
@param config					the config to check.  Use the following constants to pick:
												fwConfigs_PVSS_ADDRESS
												fwConfigs_PVSS_ARCHIVE
												fwConfigs_PVSS_ALERT_HDL
												fwConfigs_PVSS_ORIGINAL
												fwConfigs_PVSS_PV_RANGE
												fwConfigs_PVSS_SMOOTH
												fwConfigs_PVSS_MSG_CONV
												fwConfigs_PVSS_CMD_CONV
												fwConfigs_PVSS_COMMON
@param isLocked				returns TRUE if the config is locked, else FALSE
@param lockDetails		if the config is locked, the details of the lock are returned here
												lockDetails[fwConfigs_LOCK_MANAGER_DETAIL]	- The name of the manager that has control of the config
												lockDetails[fwConfigs_LOCK_USER_NAME]				- The name of the user who has control of the config
												lockDetails[fwConfigs_LOCK_MANAGER_TYPE]		- The type of manager that has control of the config
												lockDetails[fwConfigs_LOCK_MANAGER_NUMBER]	- Manager number of manager that has contol of the config
												lockDetails[fwConfigs_LOCK_MANAGER_SYSTEM]	- System name of manager that has contol of the config
												lockDetails[fwConfigs_LOCK_MANAGER_HOST]		- The host of the manager that has control of the config
												lockDetails[fwConfigs_LOCK_USER_ID]					- User ID of user who has control of the config
												lockDetails[fwConfigs_LOCK_TYPE]						- Type of lock on the config
@param exceptionInfo	details of any errors are returned here
*/
fwConfigs_getConfigLock(string dpe, string config, bool &isLocked, dyn_string &lockDetails, dyn_string &exceptionInfo)
{
	string lockAttribute;
	int tempNumber, tempType, tempSystem, manId;

	dynClear(lockDetails);
	lockAttribute = dpe + ":_lock." + config + "._locked";
	if(!dpExists(lockAttribute))
	{
		if(!dpExists(dpe))
			fwException_raise(exceptionInfo, "ERROR", "fwConfigs_getConfigLock(): The data point element does not exist (" + dpe + ")", "");
		else
			fwException_raise(exceptionInfo, "ERROR", "fwConfigs_getConfigLock(): The lock attribute could not be found (" + lockAttribute + ")", "");

		return;
	}
	
	dpGet(lockAttribute, isLocked);
	if(isLocked)
	{
		dpGet(dpe + ":_lock." + config + "._man_id", manId,
				dpe + ":_lock." + config + "._type", lockDetails[fwConfigs_LOCK_TYPE],
				dpe + ":_lock." + config + "._user_id", lockDetails[fwConfigs_LOCK_USER_ID]);
	
		getManIdFromInt(manId, tempType, tempNumber, tempSystem);
		lockDetails[fwConfigs_LOCK_MANAGER_NUMBER] = tempNumber;
		lockDetails[fwConfigs_LOCK_MANAGER_TYPE] = tempType;
		lockDetails[fwConfigs_LOCK_MANAGER_SYSTEM] = getSystemName(tempSystem);
		
		convManIntToName(manId, lockDetails[fwConfigs_LOCK_MANAGER_DETAIL]);
   _fwConfigs_getManagerHostname(manId, lockDetails[fwConfigs_LOCK_MANAGER_HOST], exceptionInfo);
		lockDetails[fwConfigs_LOCK_USER_NAME] = getUserName(lockDetails[fwConfigs_LOCK_USER_ID]);
	}
}

/** This functions checks whether a specified config of a given dpe is available to be written to (i.e. not locked).
To get more details of the lock itself (who etc.) then call fwConfigs_getConfigLock() instead of this function.

@par Constraints
	None

@par Usage
	Public

@par PVSS managers
	VISION, CTRL

@param dpe						the data point in question
@param config					the config to check.  Use the following constants to pick:
												fwConfigs_PVSS_ADDRESS
												fwConfigs_PVSS_ARCHIVE
												fwConfigs_PVSS_ALERT_HDL
												fwConfigs_PVSS_ORIGINAL
												fwConfigs_PVSS_PV_RANGE
												fwConfigs_PVSS_SMOOTH
												fwConfigs_PVSS_MSG_CONV
												fwConfigs_PVSS_CMD_CONV
												fwConfigs_PVSS_COMMON
@param isWriteable		returns TRUE if the config is writeable, else FALSE (implies that the config is locked)
@param exceptionInfo	details of any exceptions are returned here
*/
fwConfigs_checkIsConfigWriteable(string dpe, string config, bool &isWriteable, dyn_string &exceptionInfo)
{
	bool isLocked;
	dyn_string details;
	
	fwConfigs_getConfigLock(dpe, config, isLocked, details, exceptionInfo);
	if(dynlen(exceptionInfo)>0)
		return;
		
	isWriteable = !isLocked;
}

/** This functions creates an object (dyn_dyn_anytype) from the basic attributes of a config.
The basic attributes are the dpe to which it belongs, the _type and active (if supported) of the config.

@par Constraints
	None

@par Usage
	Public

@par PVSS managers
	VISION, CTRL

@param dpeConfigObject	The config object is returned here
@param dpe							The name of the dpe is passed here
@param type							The config type is passed here
@param exceptionInfo		Details of any exceptions are returned here
@param active						Optional parameter - Pass TRUE or FALSE for configs that support the active setting
													Otherwise you can leave it blank and the default (FALSE) will be used
@param dpeType					Optional parameter - Only for optimisation purposes.  Normally you do not need this parameter.
													You may pass the data type of the DPE (if known) here to avoid the function doing a dpElementType() call.
*/
fwConfigs_createDpeConfigObject(dyn_dyn_anytype &dpeConfigObject,
								string dpe,
								int type,
								dyn_string &exceptionInfo, 
								bool active = false,
								int dpeType = -1)
{
	dpeConfigObject[fwConfigs_DPE_OBJECT_DPE_NAME][1]	= dpe;
	dpeConfigObject[fwConfigs_DPE_OBJECT_TYPE][1]		= type;
	dpeConfigObject[fwConfigs_DPE_OBJECT_ACTIVE][1]	= active;
	
	if(dpeType != -1)
	{
		dpeConfigObject[fwConfigs_DPE_OBJECT_DPE_TYPE][1]	= dpeType;
	}
	else
	{
		int localDpeType = dpElementType(dpe);
		if(localDpeType != -1)
		{
			dpeConfigObject[fwConfigs_DPE_OBJECT_DPE_TYPE][1] = dpElementType(dpe);	
		}
		else
		{
			fwException_raise(	exceptionInfo, 
								"ERROR", 
								"fwConfigs_createDpeConfigObject(): could not get type for element " + dpe,
								"");
		}
	}
}

/** Initialises useful mappings like fwConfigs_PVSS, fwConfigs_FW and fwConfigs_FW_PANEL.
This function should be called once per manager before attempting to use one of the mappings.

@par Constraints
	None

@par Usage
	Public

@par PVSS managers
	VISION, CTRL

*/
fwConfigs_init()
{
	// List of PVSS configs used in the Framework. _format and _unit are not real 
	// PVSS configs, but are defined here for convenience.
	fwConfigs_PVSS[fwConfigs_FW_ADDRESS]	= fwConfigs_PVSS_ADDRESS;
	fwConfigs_PVSS[fwConfigs_FW_ALERT_HDL]	= fwConfigs_PVSS_ALERT_HDL;
	fwConfigs_PVSS[fwConfigs_FW_ARCHIVE]	= fwConfigs_PVSS_ARCHIVE;
	fwConfigs_PVSS[fwConfigs_FW_CMD_CONV]	= fwConfigs_PVSS_CMD_CONV;
	fwConfigs_PVSS[fwConfigs_FW_COMMON]	= fwConfigs_PVSS_COMMON;
	fwConfigs_PVSS[fwConfigs_FW_DP_FUNCT]	= fwConfigs_PVSS_DP_FUNCT;
	fwConfigs_PVSS[fwConfigs_FW_MSG_CONV]	= fwConfigs_PVSS_MSG_CONV;
	fwConfigs_PVSS[fwConfigs_FW_ORIGINAL]	= fwConfigs_PVSS_ORIGINAL;
	fwConfigs_PVSS[fwConfigs_FW_PV_RANGE]	= fwConfigs_PVSS_PV_RANGE;
	fwConfigs_PVSS[fwConfigs_FW_SMOOTH]		= fwConfigs_PVSS_SMOOTH;
	fwConfigs_PVSS[fwConfigs_FW_FORMAT]		= fwConfigs_PVSS_FORMAT;
	fwConfigs_PVSS[fwConfigs_FW_UNIT]		= fwConfigs_PVSS_UNIT; 
	
	// Framework names for PVSS configs
	fwConfigs_FW[fwConfigs_PVSS_ADDRESS]	= fwConfigs_FW_ADDRESS;
	fwConfigs_FW[fwConfigs_PVSS_ALERT_HDL]	= fwConfigs_FW_ALERT_HDL;
	fwConfigs_FW[fwConfigs_PVSS_ARCHIVE]	= fwConfigs_FW_ARCHIVE;
	fwConfigs_FW[fwConfigs_PVSS_CMD_CONV]	= fwConfigs_FW_CMD_CONV;
	fwConfigs_FW[fwConfigs_PVSS_COMMON]	= fwConfigs_FW_COMMON;
	fwConfigs_FW[fwConfigs_PVSS_DP_FUNCT]	= fwConfigs_FW_DP_FUNCT;
	fwConfigs_FW[fwConfigs_PVSS_MSG_CONV]	= fwConfigs_FW_MSG_CONV;
	fwConfigs_FW[fwConfigs_PVSS_ORIGINAL]	= fwConfigs_FW_ORIGINAL;
	fwConfigs_FW[fwConfigs_PVSS_PV_RANGE]	= fwConfigs_FW_PV_RANGE;
	fwConfigs_FW[fwConfigs_PVSS_SMOOTH]		= fwConfigs_FW_SMOOTH;
	fwConfigs_FW[fwConfigs_PVSS_FORMAT]		= fwConfigs_FW_FORMAT;
	fwConfigs_FW[fwConfigs_PVSS_UNIT]		= fwConfigs_FW_UNIT;	
	
	// Panels to edit PVSS configs used in the Framework
	fwConfigs_FW_PANEL[fwConfigs_PVSS_ADDRESS]		= "fwConfigs/fwPeriphAddress.pnl";	
	fwConfigs_FW_PANEL[fwConfigs_PVSS_ALERT_HDL]	= "fwConfigs/fwAlertConfig.pnl";	
	fwConfigs_FW_PANEL[fwConfigs_PVSS_ARCHIVE]		= "fwConfigs/fwArchiveConfig.pnl";	
	fwConfigs_FW_PANEL[fwConfigs_PVSS_CMD_CONV]		= "fwConfigs/fwConversionConfig.pnl";
	fwConfigs_FW_PANEL[fwConfigs_PVSS_COMMON]		= ""; //no panel directly associated with common config
	fwConfigs_FW_PANEL[fwConfigs_PVSS_DP_FUNCT]		= "fwConfigs/fwDpFunctionConfig.pnl";
	fwConfigs_FW_PANEL[fwConfigs_PVSS_MSG_CONV]		= "fwConfigs/fwConversionConfig.pnl";
	fwConfigs_FW_PANEL[fwConfigs_PVSS_ORIGINAL]		= "fwConfigs/fwOriginalConfig.pnl";	
	fwConfigs_FW_PANEL[fwConfigs_PVSS_PV_RANGE]		= "fwConfigs/fwPvRangeConfig.pnl";	
	fwConfigs_FW_PANEL[fwConfigs_PVSS_SMOOTH]		= "fwConfigs/fwSmoothingConfig.pnl";	
	fwConfigs_FW_PANEL[fwConfigs_PVSS_FORMAT]		= "fwConfigs/fwFormatConfig.pnl";	
	fwConfigs_FW_PANEL[fwConfigs_PVSS_UNIT]			= "fwConfigs/fwUnitConfig.pnl";	
	
	// Framework names for the PVSS configs	
}

/** This function gives a list of the systems that are referred to in the given list of dpes.

@par Constraints
	None

@par Usage
	Public

@par PVSS managers
	VISION, CTRL

@param dpeList					The list of dpes to search for the systems in
@param systems					The list of all the systems referred to in the dpe list are returned here
@param exceptionInfo		Details of any exceptions are returned here
*/
_fwConfigs_getSystemsInDpeList(dyn_string dpeList, dyn_string &systems, dyn_string &exceptionInfo)
{
	int i, length;
	string localSystem;
	
	localSystem = getSystemName();
	
	length = dynlen(dpeList);
	for(i=1; i<=length; i++)
	{
		fwGeneral_getSystemName(dpeList[i], systems[i], exceptionInfo);
		if(systems[i] == "")
			systems[i] = localSystem;
	}
	dynUnique(systems);
//DebugN(systems);
}


/** This function returns the host name where the given manager is running.  The manager id passed is
the internal PVSS manager ID as used by functions like convManIdToInt().  The function looks in the
internal PVSS _Connections DPs to find this information.

@par Constraints
	Currently only supports CTRL and UI managers (because users can lock configs from these managers)

@par Usage
	Internal

@par PVSS managers
	VISION, CTRL

@param managerId					 The manager ID for which you want to find the host name
@param managerHostname  The hostname is returned here
@param exceptionInfo	   Details of any exceptions are returned here
*/
_fwConfigs_getManagerHostname(int managerId, string &managerHostname, dyn_string &exceptionInfo)
{
  int managerType;
  unsigned manType, manNum, manSystem;
  string systemName, typeName;  
  
  //extract manager type and manager number from composite manager id
  getManIdFromInt(managerId, manType, manNum, manSystem);
  //currently only supporting UI and CTRL managers
  switch(manType)
  {
    case UI_MAN:
      typeName = "Ui";
      break;
    case CTRL_MAN:
      typeName = "Ctrl";
      break;
    default:
      managerHostname = "Unknown";
      return;
      break;
  }
  
  systemName = getSystemName(manSystem);  
  
  //get the internal DP which stores the host of each manager
  dyn_int manNums;
  dyn_string manHosts;
  dpGet(systemName + "_Connections." + typeName + ".ManNums", manNums,
        systemName + "_Connections." + typeName + ".HostNames", manHosts);
  
  int pos;
  pos = dynContains(manNums, manNum);
  if(pos <= 0)
    managerHostname = "Unknown";
  else
    managerHostname = manHosts[pos];
}
//@}

