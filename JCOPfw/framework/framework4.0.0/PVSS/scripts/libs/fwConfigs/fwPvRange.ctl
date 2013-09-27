/**@file

This library contains function associated with the PV range config.
Functions are provided for getting the current settings, deleting the config
and setting the config

@par Creation Date
	21/08/00

@par Modification History
	10/10/00 - modified savePvRange() function so that pv_range.._type
							is not set if pv_range config already exists.
	01/09/03	Sascha Schmeling: modified _set and _get to allow for floats
	15/01/04	Oliver Holme (IT-CO) Completed overhaul of whole library
	19/07/06	Oliver Holme (IT-CO) Added new object based functions to support new PV range types

@par Constraints
	WARNING: the functions use the dpGet or dpSetWait, problems may occur when using these functions 
          		in a working function called by a PVSS (dpConnect) or in a calling function

@par Usage
	Public

@par PVSS managers
	VISION, CTRL

@author 
	Herve Milcent, Juha Rossi, Oliver Holme (IT-CO)
*/

//@{

const unsigned fwPvRange_MINIMUM_VALUE			= 1;
const unsigned fwPvRange_MAXIMUM_VALUE			= 2;
const unsigned fwPvRange_VALUE_SET 					= 3;
const unsigned fwPvRange_VALUE_PATTERN 			= 4;
const unsigned fwPvRange_NEGATE_RANGE 			= 5;
const unsigned fwPvRange_IGNORE_OUTSIDE			= 6;
const unsigned fwPvRange_INCLUSIVE_MINIMUM	= 7;
const unsigned fwPvRange_INCLUSIVE_MAXIMUM	= 8;
//@}

//@{
/** This functions is used to prepare the necessary values for a dpSet on the necessary attributes of the _pv_range config.
This function assumes that the _type attribute has already been set to the ncessary value

@par Constraints
	None

@par Usage
	Internal

@par PVSS managers
	VISION, CTRL

@param dpe								data point element to which the pv_range config should be written
@param configurationType	value which has been written _type attribute - one of:
														DPCONFIG_NONE
														DPCONFIG_MINMAX_PVSS_RANGECHECK
														DPCONFIG_SET_PVSS_RANGECHECK
														DPCONFIG_MATCH_PVSS_RANGECHECK
@param configData					a list of data to be set to the attributes of the pv_range config.  The order or items in this list
														is based on the global constants which define which attribute is which
@param attributesToSet		a list of the attributes to be written is returned here
@param valuesToSet				a list of values to be passed to the dpSet is returned here		
@param exceptionInfo			details of any errors are returned here
*/
_fwPvRange_buildSettingsLists(string dpe, int configurationType, dyn_anytype configData, dyn_string &attributesToSet, dyn_anytype &valuesToSet, dyn_string &exceptionInfo)
{
	int i, length;
	dyn_int attributeIndex;
		
	_fwPvRange_buildAttributesList(dpe, configurationType, attributesToSet, attributeIndex, exceptionInfo);

	dynClear(valuesToSet);
	
	length = dynlen(attributeIndex);
	for(i=1; i<=length; i++)
	{
		valuesToSet[i] = configData[attributeIndex[i]];
	}
}

/** This function is used to prepare a list of attributes that need to be written to in order to set the pv_range config.
An index is also returned to help identify which attribute is which.

@par Constraints
	None

@par Usage
	Internal

@par PVSS managers
	VISION, CTRL

@param dpe								data point element to which the pv_range config should be written
@param configurationType	value which has been written _type attribute - one of:
														DPCONFIG_NONE
														DPCONFIG_MINMAX_PVSS_RANGECHECK
														DPCONFIG_SET_PVSS_RANGECHECK
														DPCONFIG_MATCH_PVSS_RANGECHECK
@param attributes					a list is returned here containing all the attributes needed to set the pv_range config on the dpe
@param attributeIndex			a list is returned here containing an index to explain which attribute is which.  The list is
														a list of integers that can be compared to the global constants that define which attribute is which		
@param exceptionInfo			details of any errors are returned here
*/
_fwPvRange_buildAttributesList(string dpe, int configurationType, dyn_string &attributes, dyn_int &attributeIndex, dyn_string &exceptionInfo)
{
	dynClear(attributes);

	switch(configurationType)
	{
		case DPCONFIG_MINMAX_PVSS_RANGECHECK:
			attributes = makeDynString(dpe + ":_pv_range.._neg",
											dpe + ":_pv_range.._ignor_inv",
											dpe + ":_pv_range.._incl_min",
											dpe + ":_pv_range.._incl_max",
											dpe + ":_pv_range.._min",
											dpe + ":_pv_range.._max");
			attributeIndex = makeDynInt(fwPvRange_NEGATE_RANGE,
										fwPvRange_IGNORE_OUTSIDE,
										fwPvRange_INCLUSIVE_MINIMUM,
										fwPvRange_INCLUSIVE_MAXIMUM,
										fwPvRange_MINIMUM_VALUE,
										fwPvRange_MAXIMUM_VALUE);
			break;
		case DPCONFIG_SET_PVSS_RANGECHECK:
			attributes = makeDynString(dpe + ":_pv_range.._neg",
											dpe + ":_pv_range.._ignor_inv",
											dpe + ":_pv_range.._set");
			attributeIndex = makeDynInt(fwPvRange_NEGATE_RANGE,
										fwPvRange_IGNORE_OUTSIDE,
										fwPvRange_VALUE_SET);
			break;
		case DPCONFIG_MATCH_PVSS_RANGECHECK:
			attributes = makeDynString(dpe + ":_pv_range.._neg",
											dpe + ":_pv_range.._ignor_inv",
											dpe + ":_pv_range.._match");
			attributeIndex = makeDynInt(fwPvRange_NEGATE_RANGE,
										fwPvRange_IGNORE_OUTSIDE,
										fwPvRange_VALUE_PATTERN);
			break;
		case DPCONFIG_NONE:
			attributes = makeDynString();
			break;
		default:
			fwException_raise(exceptionInfo, "ERROR", "_fwPvRange_buildAttributesList(): PV range type (" + configurationType + ") not suppported", "");
			break;
	}
}


/** This function is checks the consistency of the PV rnage configuration objects before they are written to the dpe.

@par Constraints
	None

@par Usage
	Internal

@par PVSS managers
	VISION, CTRL

@param dpe						the dpe that the configuration is for
@param pvRangeType		types of PV range to set.  The value can be one of:
												DPCONFIG_MINMAX_PVSS_RANGECHECK
												DPCONFIG_SET_PVSS_RANGECHECK
												DPCONFIG_MATCH_PVSS_RANGECHECK
@param configData			configuration object for the dpe is passed here
											Constants are used to identify the data inside the object.											
@param exceptionInfo	details of any errors are returned here
*/
_fwPvRange_checkInputConfiguration(string dpe, int pvRangeType, dyn_anytype configData, dyn_string &exceptionInfo)
{
	if(dynlen(configData) < fwPvRange_IGNORE_OUTSIDE)
	{
		fwException_raise(exceptionInfo, "ERROR", "_fwPvRange_checkInputConfiguration(): The config object does not contain all the required data for " + dpe, "");
		return;
	}

	if((getType(configData[fwPvRange_NEGATE_RANGE]) == ANYTYPE_VAR) || (getType(configData[fwPvRange_IGNORE_OUTSIDE]) == ANYTYPE_VAR))
	{
		fwException_raise(exceptionInfo, "ERROR", "_fwPvRange_checkInputConfiguration(): The negate and ignore options must be defined for " + dpe, "");
		return;
	}

	switch(pvRangeType)
	{
		case DPCONFIG_MINMAX_PVSS_RANGECHECK:
			if(dynlen(configData) < fwPvRange_INCLUSIVE_MAXIMUM)
			{
				fwException_raise(exceptionInfo, "ERROR", "_fwPvRange_checkInputConfiguration(): The config object does not contain all the required data for " + dpe, "");
				return;
			}
		
			if(	(getType(configData[fwPvRange_MINIMUM_VALUE]) == ANYTYPE_VAR) ||
					(getType(configData[fwPvRange_MAXIMUM_VALUE]) == ANYTYPE_VAR))
			{
				fwException_raise(exceptionInfo, "ERROR", "_fwPvRange_checkInputConfiguration(): The min and max values must be defined for " + dpe, "");
				return;
			}

			if(	(getType(configData[fwPvRange_INCLUSIVE_MINIMUM]) == ANYTYPE_VAR) ||
					(getType(configData[fwPvRange_INCLUSIVE_MAXIMUM]) == ANYTYPE_VAR))
			{
				fwException_raise(exceptionInfo, "ERROR", "_fwPvRange_checkInputConfiguration(): The inclusion of the min and max limits must be defined for " + dpe, "");
				return;
			}

			if((float)configData[fwPvRange_MINIMUM_VALUE] >= (float)configData[fwPvRange_MAXIMUM_VALUE])
			{
				fwException_raise(exceptionInfo, "ERROR", "_fwPvRange_checkInputConfiguration(): Minimum value must be less than maximum value for " + dpe, "");
				return;
			}
			break;
		case DPCONFIG_SET_PVSS_RANGECHECK:
			if(getType(configData[fwPvRange_VALUE_SET]) == ANYTYPE_VAR)
			{
				fwException_raise(exceptionInfo, "ERROR", "_fwPvRange_checkInputConfiguration(): The set of values to exclude (or allow) must be defined for " + dpe, "");
				return;
			}
			break;
		case DPCONFIG_MATCH_PVSS_RANGECHECK:
			if(getType(configData[fwPvRange_VALUE_PATTERN]) == ANYTYPE_VAR)
			{
				fwException_raise(exceptionInfo, "ERROR", "_fwPvRange_checkInputConfiguration(): The pattern to match the values with must be defined for " + dpe, "");
				return;
			}
			break;
		default:
			break;
	}
}


/** Sets different PV range configs for the given data point elements

@par Constraints
	None

@par Usage
	Public

@par PVSS managers
	VISION, CTRL

@param dpes						list of data point elements
@param pvRangeTypes		list of types of PV range to set.  The values can be one of:
												DPCONFIG_MINMAX_PVSS_RANGECHECK
												DPCONFIG_SET_PVSS_RANGECHECK
												DPCONFIG_MATCH_PVSS_RANGECHECK
@param configData			configuration object for each dpe is passed here.
											The first dimension of the array defines which dpe the object relate to.
											e.g. configData[1] contains the configuration object for dpes[1]
											Constants are used to identify the data inside the object.											

											For all PV range configurations the configData object must contain values for:
												fwPvRange_NEGATE_RANGE - e.g. configData[1][fwPvRange_NEGATE_RANGE] = TRUE;
												fwPvRange_IGNORE_OUTSIDE

											For min-max PV ranges, the following object fields must also be filled:
												fwPvRange_INCLUSIVE_MINIMUM
												fwPvRange_INCLUSIVE_MAXIMUM
												fwPvRange_MINIMUM_VALUE
												fwPvRange_MAXIMUM_VALUE
												
											For value set PV ranges, the following object fields must also be filled:
												fwPvRange_VALUE_SET

											For min-max PV ranges, the following object fields must also be filled:
												fwPvRange_VALUE_PATTERN
@param exceptionInfo	details of any errors are returned here
*/
fwPvRange_setObjectMany(	dyn_string dpes, dyn_int pvRangeTypes, dyn_dyn_anytype configData, dyn_string &exceptionInfo)
{
	int i, length;
	
	length = dynlen(dpes);
	for(i=length; i>=1; i--)
	{
		_fwPvRange_checkInputConfiguration(dpes[i], pvRangeTypes[i], configData[i], exceptionInfo);
		if(dynlen(exceptionInfo)>0)
		{
			dynRemove(pvRangeTypes, i);
			dynRemove(configData, i);			
		}
	}
	
	_fwPvRange_set(dpes, pvRangeTypes, configData, exceptionInfo);
}


/** Sets different PV range configs for the given data point elements

@par Constraints
	None

@par Usage
	Internal

@par PVSS managers
	VISION, CTRL

@param dpes						list of data point elements
@param pvRangeTypes		list of types of PV range to set.  The value can be one of:
												DPCONFIG_MINMAX_PVSS_RANGECHECK
												DPCONFIG_SET_PVSS_RANGECHECK
												DPCONFIG_MATCH_PVSS_RANGECHECK
@param configData			configuration object for each dpe is passed here.
											The first dimension of the array defines which dpe the object relate to.
											e.g. configData[1] contains the configuration object for dpes[1]
											Constants are used to identify the data inside the object.											
@param exceptionInfo	details of any errors are returned here
*/
_fwPvRange_set(	dyn_string dpes, dyn_int pvRangeTypes, dyn_dyn_anytype configData, dyn_string &exceptionInfo)
{
	int i, length, numberOfSettings;
	dyn_anytype valuesToSet, tempValuesToSet, typeValuesToSet;
	dyn_string attributesToSet, tempAttributesToSet, typeAttributesToSet;
	dyn_errClass errors;
	
	_fwConfigs_setConfigTypeAttribute(dpes, fwConfigs_PVSS_PV_RANGE, pvRangeTypes, exceptionInfo);
	if(dynlen(exceptionInfo)>0)
	{
		if(exceptionInfo[dynlen(exceptionInfo)] == fwConfigs_SET_LOCKED)
		{
			dynClear(exceptionInfo);
			fwException_raise(exceptionInfo, "ERROR", "_fwPvRange_set(): Some of the _pv_range configs were locked", "");
		}
		else
		{
			dynClear(exceptionInfo);
			fwException_raise(exceptionInfo, "ERROR", "_fwPvRange_set():Could not set some of the _pv_range.._type atttibutes", "");
		}
		return;
	}

	length = dynlen(dpes);
	for(i=1; i<=length; i++)
	{
		_fwPvRange_buildSettingsLists(dpes[i], pvRangeTypes[i], configData[i], tempAttributesToSet, tempValuesToSet, exceptionInfo);
		numberOfSettings = dynAppend(attributesToSet, tempAttributesToSet);
		dynAppend(valuesToSet, tempValuesToSet);
			
		if((numberOfSettings > fwConfigs_OPTIMUM_DP_SET_SIZE) || (i == length))
		{
//DebugN("Setting...", attributesToSet, valuesToSet);
			dpSetWait(attributesToSet, valuesToSet);
			errors = getLastError(); 
    		if(dynlen(errors) > 0)
    		{ 
	 			throwError(errors);
	 			fwException_raise(exceptionInfo, "ERROR", "_fwPvRange_set: Could not configure some PV range configs", "");
			}
			
			dynClear(attributesToSet);
			dynClear(valuesToSet);
		}
	}
}


/** Sets the same PV range config for the given data point elements

@par Constraints
	None

@par Usage
	Public

@par PVSS managers
	VISION, CTRL

@param dpes						list of data point elements
@param pvRangeType		types of PV range to set.  The value can be one of:
												DPCONFIG_MINMAX_PVSS_RANGECHECK
												DPCONFIG_SET_PVSS_RANGECHECK
												DPCONFIG_MATCH_PVSS_RANGECHECK
@param configData			configuration object for the dpes is passed here
											Constants are used to identify the data inside the object.											

											For all PV range configurations the configData object must contain values for:
												fwPvRange_NEGATE_RANGE - e.g. configData[fwPvRange_NEGATE_RANGE] = TRUE;
												fwPvRange_IGNORE_OUTSIDE

											For min-max PV ranges, the following object fields must also be filled:
												fwPvRange_INCLUSIVE_MINIMUM
												fwPvRange_INCLUSIVE_MAXIMUM
												fwPvRange_MINIMUM_VALUE
												fwPvRange_MAXIMUM_VALUE
												
											For value set PV ranges, the following object fields must also be filled:
												fwPvRange_VALUE_SET

											For min-max PV ranges, the following object fields must also be filled:
												fwPvRange_VALUE_PATTERN
@param exceptionInfo	details of any errors are returned here
*/
fwPvRange_setObjectMultiple(dyn_string dpes, int pvRangeType, dyn_anytype configData, dyn_string &exceptionInfo)
{
	int i, length;
	dyn_int pvRangeTypes;
	dyn_dyn_anytype listOfConfigData;
	
	_fwPvRange_checkInputConfiguration(dpes[1], pvRangeType, configData, exceptionInfo);
	if(dynlen(exceptionInfo)>0)
		return;

	length = dynlen(dpes);
	for(i=1; i<=length; i++)
	{
		pvRangeTypes[i] = pvRangeType;
		listOfConfigData[i] = configData;
	}
	
	_fwPvRange_set(dpes, pvRangeTypes, listOfConfigData, exceptionInfo);
}


/** Sets the PV range config for the given data point element

@par Constraints
	None

@par Usage
	Public

@par PVSS managers
	VISION, CTRL

@param dpe						data point element
@param pvRangeType		types of PV range to set.  The value can be one of:
												DPCONFIG_MINMAX_PVSS_RANGECHECK
												DPCONFIG_SET_PVSS_RANGECHECK
												DPCONFIG_MATCH_PVSS_RANGECHECK
@param configData			configuration object for the dpe is passed here
											Constants are used to identify the data inside the object.											

											For all PV range configurations the configData object must contain values for:
												fwPvRange_NEGATE_RANGE - e.g. configData[fwPvRange_NEGATE_RANGE] = TRUE;
												fwPvRange_IGNORE_OUTSIDE

											For min-max PV ranges, the following object fields must also be filled:
												fwPvRange_INCLUSIVE_MINIMUM
												fwPvRange_INCLUSIVE_MAXIMUM
												fwPvRange_MINIMUM_VALUE
												fwPvRange_MAXIMUM_VALUE
												
											For value set PV ranges, the following object fields must also be filled:
												fwPvRange_VALUE_SET

											For min-max PV ranges, the following object fields must also be filled:
												fwPvRange_VALUE_PATTERN
@param exceptionInfo	details of any errors are returned here
*/
fwPvRange_setObject(string dpe, int pvRangeType, dyn_anytype configData, dyn_string &exceptionInfo)
{
	dyn_dyn_anytype listOfConfigData;

	_fwPvRange_checkInputConfiguration(dpe, pvRangeType, configData, exceptionInfo);
	if(dynlen(exceptionInfo)>0)
		return;
	
	listOfConfigData[1] = configData;
	_fwPvRange_set(makeDynString(dpe), makeDynInt(pvRangeType), listOfConfigData, exceptionInfo);
}

/** Gets the PV range config from the given data point element

@par Constraints
	None

@par Usage
	Public

@par PVSS managers
	VISION, CTRL

@param dpe						data point element
@param configExists		TRUE if PV Range config exists, else FALSE
@param pvRangeType		types of PV range is returned here.  The value can be one of:
												DPCONFIG_MINMAX_PVSS_RANGECHECK
												DPCONFIG_SET_PVSS_RANGECHECK
												DPCONFIG_MATCH_PVSS_RANGECHECK
@param configData			configuration object for the dpe is returned here
											Constants are used to identify the data inside the object.											

											For all PV range configurations the configData object will contain values for:
												fwPvRange_NEGATE_RANGE - e.g. rangeNegated = configData[fwPvRange_NEGATE_RANGE];
												fwPvRange_IGNORE_OUTSIDE

											For min-max PV ranges, the following object fields will also be filled:
												fwPvRange_INCLUSIVE_MINIMUM
												fwPvRange_INCLUSIVE_MAXIMUM
												fwPvRange_MINIMUM_VALUE
												fwPvRange_MAXIMUM_VALUE
												
											For value set PV ranges, the following object fields will also be filled:
												fwPvRange_VALUE_SET

											For min-max PV ranges, the following object fields will also be filled:
												fwPvRange_VALUE_PATTERN
@param exceptionInfo	details of any errors are returned here
*/
fwPvRange_getObject(	string dpe, bool &configExists, int &pvRangeType, dyn_anytype &configData, dyn_string &exceptionInfo)
{
	dyn_bool dynConfigExists;
	dyn_int dynPvRangeType;
	dyn_dyn_anytype dynConfigData;

	_fwPvRange_get(makeDynString(dpe), dynConfigExists, dynPvRangeType, dynConfigData, exceptionInfo);

	configExists = dynConfigExists[1];
	pvRangeType = dynPvRangeType[1];
	configData = dynConfigData[1];
}


/** Gets the PV range configs for the given data point elements

@par Constraints
	None

@par Usage
	Public

@par PVSS managers
	VISION, CTRL

@param dpes						list of data point elements
@param configExists		list of bools, TRUE if PV Range config exists, else FALSE
@param pvRangeTypes		list of types of PV range is returned here.  The values can be one of:
												DPCONFIG_MINMAX_PVSS_RANGECHECK
												DPCONFIG_SET_PVSS_RANGECHECK
												DPCONFIG_MATCH_PVSS_RANGECHECK
@param configData			configuration object for each of the dpes is returned here
											The first dimension of the array defines which dpe the object relate to.
											e.g. configData[1] contains the configuration object from dpes[1]
											Constants are used to identify the data inside the object.											

											For all PV range configurations the configData object will contain values for:
												fwPvRange_NEGATE_RANGE - e.g. rangeNegated = configData[1][fwPvRange_NEGATE_RANGE];
												fwPvRange_IGNORE_OUTSIDE

											For min-max PV ranges, the following object fields will also be filled:
												fwPvRange_INCLUSIVE_MINIMUM
												fwPvRange_INCLUSIVE_MAXIMUM
												fwPvRange_MINIMUM_VALUE
												fwPvRange_MAXIMUM_VALUE
												
											For value set PV ranges, the following object fields will also be filled:
												fwPvRange_VALUE_SET

											For min-max PV ranges, the following object fields will also be filled:
												fwPvRange_VALUE_PATTERN
@param exceptionInfo	details of any errors are returned here
*/
fwPvRange_getObjectMany(	dyn_string dpes, dyn_bool &configExists, dyn_int &pvRangeTypes,
								dyn_dyn_anytype &configData, dyn_string &exceptionInfo)
{
	_fwPvRange_get(dpes, configExists, pvRangeTypes, configData, exceptionInfo);
}


/** Gets the PV range configs for the given data point elements

@par Constraints
	None

@par Usage
	Internal

@par PVSS managers
	VISION, CTRL

@param dpes						list of data point elements
@param configExists		list of bools, TRUE if PV Range config exists, else FALSE
@param pvRangeTypes		list of types of PV range is returned here.  The values can be one of:
												DPCONFIG_MINMAX_PVSS_RANGECHECK
												DPCONFIG_SET_PVSS_RANGECHECK
												DPCONFIG_MATCH_PVSS_RANGECHECK
@param configData			configuration object for each dpe is returned here.
											The first dimension of the array defines which dpe the object relate to.
											e.g. configData[1] contains the configuration object for dpes[1]
											Constants are used to identify the data inside the object.											
@param exceptionInfo	details of any errors are returned here
*/
_fwPvRange_get(	dyn_string dpes, dyn_bool &configExists, dyn_int &pvRangeTypes,
								dyn_dyn_anytype &configData, dyn_string &exceptionInfo)
{
	//define array indexes for mapping data
	const int NUMBER_OF_ENTRIES = 1;
	const int FIRST_POSITION = 2;

	int i, j, k, length, numberOfReadings, dpNumber = 1;
	dyn_int tempAttributeIndex, attributeIndex;
	dyn_anytype rawData;
	dyn_string attributesToRead, tempAttributesToRead;
	dyn_int dpeInfo;
	mapping dataPositions;

	dynClear(pvRangeTypes);
	dynClear(configData);
	
	length = dynlen(dpes);
	_fwConfigs_getConfigTypeAttribute(dpes, fwConfigs_PVSS_PV_RANGE, pvRangeTypes, exceptionInfo);
	
	for(i=1; i<=length; i++)
	{
		switch(pvRangeTypes[i])
		{
			case DPCONFIG_MINMAX_PVSS_RANGECHECK:
				configExists[i] = TRUE;
				break;
			case DPCONFIG_SET_PVSS_RANGECHECK:
				configExists[i] = TRUE;
				break;
			case DPCONFIG_MATCH_PVSS_RANGECHECK:
				configExists[i] = TRUE;
				break;
			case DPCONFIG_NONE:
				configExists[i] = FALSE;
				break;
			default:
				configExists[i] = FALSE;  //unsupported types shown as not existing
				break;
		}	
	
		_fwPvRange_buildAttributesList(dpes[i], pvRangeTypes[i], tempAttributesToRead, tempAttributeIndex, exceptionInfo);
		dpeInfo[NUMBER_OF_ENTRIES] = dynlen(tempAttributesToRead);
		numberOfReadings = dynAppend(attributesToRead, tempAttributesToRead);
		dpeInfo[FIRST_POSITION] = numberOfReadings - dpeInfo[NUMBER_OF_ENTRIES] + 1;
		dynAppend(attributeIndex, tempAttributeIndex);
		
		dataPositions[i + "::" + dpes[i]] = dpeInfo;
		
		configData[i] = makeDynAnytype();

		if((numberOfReadings > fwConfigs_OPTIMUM_DP_GET_SIZE) || ((i == length) && (numberOfReadings != 0)))
		{
			dpGet(attributesToRead, rawData);
//DebugN("Reading...", attributesToRead, rawData);

			for(j=dpNumber; j<=i; j++)
			{
				dpeInfo = dataPositions[j + "::" + dpes[j]];
//DebugN(j+dpes[j], dpeInfo);
				if(dpeInfo[NUMBER_OF_ENTRIES] != 0)
				{
//DebugN("Has data: ", j + "::" + dpes[j], dpeInfo);
					for(k=dpeInfo[FIRST_POSITION]; k<=dpeInfo[FIRST_POSITION]+dpeInfo[NUMBER_OF_ENTRIES]-1; k++)
						configData[j][attributeIndex[k]] = rawData[k];
				}
			}
			dynClear(attributesToRead);
			dynClear(attributeIndex);
			dpNumber = i+1;
		}
	}
}

/** Deletes the PV range config for the given data point elements

@par Constraints
	None

@par Usage
	Public

@par PVSS managers
	VISION, CTRL

@param dpes						list of data point elements
@param exceptionInfo	details of any errors are returned here
*/
fwPvRange_deleteMultiple(dyn_string dpes, dyn_string &exceptionInfo)
{
	_fwConfigs_delete(dpes, fwConfigs_PVSS_PV_RANGE, exceptionInfo);
}


/** Deletes the PV range config for the given data point elements

@par Constraints
	None

@par Usage
	Public

@par PVSS managers
	VISION, CTRL

@param dpes						list of data point elements
@param exceptionInfo	details of any errors are returned here
*/
fwPvRange_deleteMany(dyn_string dpes, dyn_string &exceptionInfo)
{
	_fwConfigs_delete(dpes, fwConfigs_PVSS_PV_RANGE, exceptionInfo);
}


/** Deletes the PV range config for the given data point element

@par Constraints
	None

@par Usage
	Public

@par PVSS managers
	VISION, CTRL

@param dpe						data point element
@param exceptionInfo	details of any errors are returned here
*/
fwPvRange_delete(string dpe, dyn_string &exceptionInfo)
{
	_fwConfigs_delete(makeDynString(dpe), fwConfigs_PVSS_PV_RANGE, exceptionInfo);
}



//!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
//DEPRECATED functions below this point
//!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

/** DEPRECATED function - use fwPvRange_setObjectMany instead

@par Constraints
	None

@par Usage
	DEPRECATED

@par PVSS managers
	VISION, CTRL

@param dpes						list of data point elements
@param minValue				list of lower limit for the range
@param maxValue				list of upper limit for the range
@param negateRange		list of bools, TRUE for "reverse (negate) value-range handling" 
@param ignoreOutside	list of bools, TRUE when "invalid values should be ignored"
@param inclusiveMin		list of bools, TRUE when "minimum value included in the value range"
@param inclusiveMax		list of bools, TRUE when "maximum value included in the value range"
@param exceptionInfo	details of any errors are returned here
*/
fwPvRange_setMany(	dyn_string dpes, dyn_float minValue, dyn_float maxValue,
						dyn_bool negateRange, 
						dyn_bool ignoreOutside, dyn_bool inclusiveMin, dyn_bool inclusiveMax, dyn_string &exceptionInfo)
{
	int i, length;
	dyn_int pvRangeTypes;
	dyn_dyn_anytype configData;
	
	length = dynlen(dpes);
	for(i=1; i<=length; i++)
	{
		pvRangeTypes[i] = DPCONFIG_MINMAX_PVSS_RANGECHECK;
	
		configData[i][fwPvRange_MINIMUM_VALUE] = minValue[i];	
		configData[i][fwPvRange_MAXIMUM_VALUE] = maxValue[i];	
		configData[i][fwPvRange_NEGATE_RANGE] = negateRange[i];	
		configData[i][fwPvRange_IGNORE_OUTSIDE] = ignoreOutside[i];	
		configData[i][fwPvRange_INCLUSIVE_MINIMUM] = inclusiveMin[i];	
		configData[i][fwPvRange_INCLUSIVE_MAXIMUM] = inclusiveMax[i];	
	}
	
	fwPvRange_setObjectMany(dpes, pvRangeTypes, configData, exceptionInfo); 
}

/** DEPRECATED function - use fwPvRange_setObjectMultiple instead

@par Constraints
	None

@par Usage
	DEPRECATED

@par PVSS managers
	VISION, CTRL

@param dpes						list of data point elements
@param minValue				lower limit for the range
@param maxValue				upper limit for the range
@param negateRange		TRUE for "reverse (negate) value-range handling" 
@param ignoreOutside	TRUE when "invalid values should be ignored"
@param inclusiveMin		TRUE when "minimum value included in the value range"
@param inclusiveMax		TRUE when "maximum value included in the value range"
@param exceptionInfo	details of any errors are returned here
*/
fwPvRange_setMultiple(	dyn_string dpes, float minValue, float maxValue,
						bool negateRange, 
						bool ignoreOutside, bool inclusiveMin, bool inclusiveMax, dyn_string &exceptionInfo)
{
	int i, length;
	dyn_int pvRangeTypes;
	dyn_dyn_anytype configData;
	
	length = dynlen(dpes);
	for(i=1; i<=length; i++)
	{
		pvRangeTypes[i] = DPCONFIG_MINMAX_PVSS_RANGECHECK;
	
		configData[i][fwPvRange_MINIMUM_VALUE] = minValue;	
		configData[i][fwPvRange_MAXIMUM_VALUE] = maxValue;	
		configData[i][fwPvRange_NEGATE_RANGE] = negateRange;	
		configData[i][fwPvRange_IGNORE_OUTSIDE] = ignoreOutside;	
		configData[i][fwPvRange_INCLUSIVE_MINIMUM] = inclusiveMin;	
		configData[i][fwPvRange_INCLUSIVE_MAXIMUM] = inclusiveMax;	
	}
	
	fwPvRange_setObjectMany(dpes, pvRangeTypes, configData, exceptionInfo); 
}

/** DEPRECATED function - use fwPvRange_setObject instead

@par Constraints
	None

@par Usage
	DEPRECATED

@par PVSS managers
	VISION, CTRL

@param dpe						data point element
@param minValue				lower limit for the range
@param maxValue				upper limit for the range
@param negateRange		TRUE for "reverse (negate) value-range handling" 
@param ignoreOutside	TRUE when "invalid values should be ignored"
@param inclusiveMin		TRUE when "minimum value included in the value range"
@param inclusiveMax		TRUE when "maximum value included in the value range"
@param exceptionInfo	details of any errors are returned here
*/
fwPvRange_set(	string dpe, float minValue, float maxValue,
				bool negateRange, bool ignoreOutside, bool inclusiveMin, bool inclusiveMax, dyn_string &exceptionInfo)
{
	int pvRangeType;
	dyn_anytype configData;
	
	pvRangeType = DPCONFIG_MINMAX_PVSS_RANGECHECK;
	
	configData[fwPvRange_MINIMUM_VALUE] = minValue;	
	configData[fwPvRange_MAXIMUM_VALUE] = maxValue;	
	configData[fwPvRange_NEGATE_RANGE] = negateRange;	
	configData[fwPvRange_IGNORE_OUTSIDE] = ignoreOutside;	
	configData[fwPvRange_INCLUSIVE_MINIMUM] = inclusiveMin;	
	configData[fwPvRange_INCLUSIVE_MAXIMUM] = inclusiveMax;	
	
	fwPvRange_setObject(dpe, pvRangeType, configData, exceptionInfo); 
}


/** DEPRECATED function - use fwPvRange_getObject instead

@par Constraints
	None

@par Usage
	DEPRECATED

@par PVSS managers
	VISION, CTRL

@param dpe						data point element
@param configExists		TRUE if PV Range config exists, else FALSE
@param minValue				lower limit for the range
@param maxValue				upper limit for the range
@param negateRange		TRUE for "reverse (negate) value-range handling" 
@param ignoreOutside	TRUE when "invalid values should be ignored"
@param inclusiveMin		TRUE when "minimum value included in the value range"
@param inclusiveMax		TRUE when "maximum value included in the value range"
@param exceptionInfo	details of any errors are returned here
*/
fwPvRange_get(	string dpe, bool &configExists, float &minValue,
			float &maxValue, bool &negateRange, 
			bool &ignoreOutside, bool &inclusiveMin, bool &inclusiveMax, dyn_string &exceptionInfo)
{
	int pvRangeType;
	dyn_anytype configData;
			
	fwPvRange_getObject(dpe, configExists, pvRangeType, configData, exceptionInfo); 

	if(configExists && (pvRangeType == DPCONFIG_MINMAX_PVSS_RANGECHECK))
	{
		minValue = configData[fwPvRange_MINIMUM_VALUE];	
		maxValue = configData[fwPvRange_MAXIMUM_VALUE];	
		negateRange = configData[fwPvRange_NEGATE_RANGE];	
		ignoreOutside = configData[fwPvRange_IGNORE_OUTSIDE];	
		inclusiveMin = configData[fwPvRange_INCLUSIVE_MINIMUM];	
		inclusiveMax = configData[fwPvRange_INCLUSIVE_MAXIMUM];	
	}
	else
	{
		configExists = FALSE;
		minValue = 0;
		maxValue = 0;
		negateRange = FALSE;
		ignoreOutside = FALSE;
		inclusiveMin = FALSE;
		inclusiveMax = FALSE;
	}
}

/** DEPRECATED function - use fwPvRange_getObjectMany instead

@par Constraints
	None

@par Usage
	DEPRECATED

@par PVSS managers
	VISION, CTRL

@param dpes						list of data point elements
@param configExists		list of bools, TRUE if PV Range config exists, else FALSE
@param minValue				list of lower limit for the range
@param maxValue				list of upper limit for the range
@param negateRange		list of bools, TRUE for "reverse (negate) value-range handling" 
@param ignoreOutside	list of bools, TRUE when "invalid values should be ignored"
@param inclusiveMin		list of bools, TRUE when "minimum value included in the value range"
@param inclusiveMax		list of bools, TRUE when "maximum value included in the value range"
@param exceptionInfo	details of any errors are returned here
*/
fwPvRange_getMany(	dyn_string dpes, dyn_bool &configExists, dyn_float &minValue,
			dyn_float &maxValue, dyn_bool &negateRange, 
			dyn_bool &ignoreOutside, dyn_bool &inclusiveMin, dyn_bool &inclusiveMax, dyn_string &exceptionInfo)
{
	int i, length;
	dyn_int dynPvRangeType;
	dyn_dyn_anytype dynConfigData;
			
	fwPvRange_getObjectMany(dpes, configExists, dynPvRangeType, dynConfigData, exceptionInfo); 

	length = dynlen(dpes);
	for(i=1; i<=length; i++)
	{
		if(configExists[i] && (dynPvRangeType[i] == DPCONFIG_MINMAX_PVSS_RANGECHECK))
		{
			minValue[i] = dynConfigData[i][fwPvRange_MINIMUM_VALUE];	
			maxValue[i] = dynConfigData[i][fwPvRange_MAXIMUM_VALUE];	
			negateRange[i] = dynConfigData[i][fwPvRange_NEGATE_RANGE];	
			ignoreOutside[i] = dynConfigData[i][fwPvRange_IGNORE_OUTSIDE];	
			inclusiveMin[i] = dynConfigData[i][fwPvRange_INCLUSIVE_MINIMUM];	
			inclusiveMax[i] = dynConfigData[i][fwPvRange_INCLUSIVE_MAXIMUM];	
		}
		else
		{
			configExists[i] = FALSE;
			minValue[i] = 0;
			maxValue[i] = 0;
			negateRange[i] = FALSE;
			ignoreOutside[i] = FALSE;
			inclusiveMin[i] = FALSE;
			inclusiveMax[i] = FALSE;
		}
	}
}
//@}
