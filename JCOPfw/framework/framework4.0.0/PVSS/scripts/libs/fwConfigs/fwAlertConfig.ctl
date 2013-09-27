/**@file

This library contains function associated with the alert handling config.
Functions are provided for getting the current settings, deleting the config
and for creating or altering the config
Seperate functions for digital, analog and summary type alerts are available

@par Creation Date
	14/03/2000

@par Modification History
	05/05/00 Herve Milcent
				- problem with a summary alert with an empty list of dp, add a 
				dummy dp to avoid it when creating the alert sum: compCreateAlertConfigSum
	15/01/04 Oliver Holme (IT-CO) Completed major overhaul of whole library
	16/01/04 Oliver Holme (IT-CO) Added new functions for activate/deactivate/acknowledge and set/getLimits
	
@par Constraints
	WARNING: the functions use the dpGet or dpSetWait, problems may occur when using these functions 
          		in a working function called by a PVSS (dpConnect) or in a calling function 

@par Usage
	Public

@par PVSS managers
	VISION, CTRL

@author 
	Oliver Holme (IT-CO) based on original by Herve Milcent, Niko Karlsson based on libMLDBEH_ANLEGEN.ctl
*/

//@{
//constants
const string fwAlertConfig_FW_ALERT_CLASS_DPTYPE = "_FwAlertClass";
const string fwAlertConfig_FW_ALERT_CLASS_ALTERNATIVE_PATTERN = "_*_[0123456789][0123456789]*";
const string fwAlertConfig_FW_NULL_PATTERN = "JCOPFW_NULL_PATTERN";
//@}

//@{
/** Gets a list of all the existing archive class dps of type _FwAlertClass.
Lists are also returned containing the acknowledgeType of the class and the priority
The search is performed in the specified systems, and only classes found in ALL of the systems will be returned

@par Constraints
	None

@par Usage
	Public

@par PVSS managers
	VISION, CTRL

@param searchSystems			A list of systems to search in
@param alertClassDps			The list of alert class dps found is returned here (excluding the . at the end and without system name)  
@param acknowledgeTypes		The acknowledge type of each alert class is returned here.  Possible values are:
														DPATTR_ACK_DELETES - acknowledgement deletes
														DPATTR_ACK_NONE - cannot be acknowledged (unacknowledgable)
														DPATTR_ACK_APP - CAME can be acknowledged
														DPATTR_ACK_PAIR - alert pair must be acknowledged
														DPATTR_ACK_APP_AND_DISAPP - CAME and WENT must be acknowledged
@param priorities					The prioritues of each alert class is returned here.
@param exceptionInfo			Details of any exceptions are returned here   
*/
fwAlertConfig_getAlertClasses(dyn_string searchSystems, dyn_string &alertClassDps,
															dyn_int &acknowledgeTypes, dyn_int &priorities, dyn_string &exceptionInfo)
{
	int i, j, pos, numberOfResults, length;
	string query;
	dyn_string parts;
	dyn_dyn_anytype queryResult;
	dyn_dyn_string ddsAlertClasses;
	
	alertClassDps = makeDynString();
	acknowledgeTypes = makeDynInt();
	priorities = makeDynInt();
	
	length = dynlen(searchSystems);
	if(length == 0)
		length = dynAppend(searchSystems, getSystemName());

	for(i=1; i<=length; i++)
	{
		if(strpos(searchSystems[i], ":") != (strlen(searchSystems[i]) - 1))
			searchSystems[i] += ":";
	
		query = "SELECT '_alert_class.._ack_type', '_alert_class.._prior' FROM '*' REMOTE '"
						+ searchSystems[i] + "' WHERE _DPT = \""
						+ fwAlertConfig_FW_ALERT_CLASS_DPTYPE + "\" SORT BY 2 ASC";
						
		dpQuery(query, queryResult);
		
		numberOfResults = dynlen(queryResult);
		for(j=2; j<=numberOfResults; j++)
		{
			if(patternMatch("*:_fw*Nack_*.", queryResult[j][1]) || patternMatch("*:_fw*Ack_*.", queryResult[j][1]))
				continue;
			
//			if(length == 1)
//				pos = dynAppend(ddsAlertClasses[i], dpSubStr(queryResult[j][1], DPSUB_SYS_DP));
//			else
				pos = dynAppend(ddsAlertClasses[i], dpSubStr(queryResult[j][1], DPSUB_DP));
			
			ddsAlertClasses[i][pos] += "|" + queryResult[j][2];
			ddsAlertClasses[i][pos] += "|" + (int)queryResult[j][3];
		}
	}
	
	for(i=2; i<=length; i++)
		ddsAlertClasses[1] = dynIntersect(ddsAlertClasses[1], ddsAlertClasses[i]);

	length = dynlen(ddsAlertClasses[1]);
	for(i=1; i<=length; i++)
	{
		parts = strsplit(ddsAlertClasses[1][i], "|");
		dynAppend(alertClassDps, parts[1]);
		dynAppend(acknowledgeTypes, parts[2]);
		dynAppend(priorities, parts[3]);
	}		
}




/** Prepares a list of attributes and a list of values to be used in a dpSetWait() call to set the config for the given dpe. 

@par Constraints
	The length of the alertTexts and alertClasses dyn_strings must both be 2

@par Usage
	Public

@par PVSS managers
	VISION, CTRL

@param dpe						Name of data point element to act on
@param currentConfigType	The type of the current alert config on the data point element (only considered in case of modifyOnly = TRUE, otherwise value is ignored)
@param alertTexts			Alert texts eg. makeDynString( "Bad Text", "OK")   
@param alertClasses		Alert classes eg. makeDynString( "_fwErrorAck.", "" )
												One of the items of the dyn_string must always be empty to indicate the valid state
												The valid ranges becomes the state with no alert class given (the second in this case).
												Don't forget to add the dot to the alert class names.
@param minimumPriority	Minimum priority of alert (ignore below this value)
@param alertPanel			Panel to call from the alert screen
@param alertPanelParameters		Parameters to pass to panel given in Alert Panel
@param alertHelp			Help text or path to help file    
@param attributes			Output - the list of attributes that need to be set is returned here
@param values					Output - the list of values that need to be set is returned here
@param exceptionInfo	Details of any exceptions are returned here   
@param modifyOnly				Optional parameter - Default value FALSE.  Set to TRUE to modify alert without setting "type" attributes.
						This is much quicker, but the alert config must already exist and must be of type binary alert.
@param fallBackToSet			Optional parameter - Default value FALSE.  Used in combination with modifyOnly.
						If modifyOnly = TRUE and fallBackToSet = FALSE, then if the alert config is not compatible an exception is raised. 
						If modifyOnly = TRUE and fallBackToSet = TRUE, then if the alert config is not compatible, modifyOnly is treated as if it was FALSE. 
*/
_fwAlertConfig_prepareDigital(string dpe,
							int currentConfigType,
							dyn_string alertTexts,
							dyn_string alertClasses,
							int minimumPriority,    
							string alertPanel,
							dyn_string alertPanelParameters,
							string alertHelp,
							dyn_string &attributes,
							dyn_mixed &values, 
							dyn_string &exceptionInfo,
							bool modifyOnly = FALSE,
							bool fallBackToSet = FALSE)
{
	bool alertHelpChanged , okRange, deactivated, isActive = FALSE, modifyExistingConfig;
	int pos, configType, i, length;
	string alertClass, dpeSystem;
	dyn_mixed tempValue;
	
	dynClear(attributes);
	dynClear(values);
	
	configType = DPCONFIG_ALERT_BINARYSIGNAL;
	if(modifyOnly)
	{
		if(currentConfigType != configType)
		{
			if(fallBackToSet)
				modifyExistingConfig = FALSE;
			else
			{
				fwException_raise(exceptionInfo, "ERROR", "fwAlertConfig_prepareDigital: Alert config does not exist on \"" + dpe + "\" so it cannot be modified", "");
				return;
			}
		}
		else
			modifyExistingConfig = TRUE;
	}
	else
		modifyExistingConfig = FALSE;

	if(	dynlen(alertTexts) != 2 ||
		dynlen(alertClasses) != 2)
	{
		fwException_raise(exceptionInfo, "ERROR", "fwAlertConfig_prepareDigital: The alert configuration required for \"" + dpe + "\" is not consistent (Check length of dyn variables)", "");
		return;
	}

	//for the alertClasses, ensure that the same system as the dpe is used.
	length = dynlen(alertClasses);
	for(i=1; i<=length; i++)
	{
		if(alertClasses[i] != "")
		{
			dpeSystem = dpSubStr(dpe, DPSUB_SYS);
			if(strpos(alertClasses[i], dpeSystem) != 0)
				alertClasses[i] = dpeSystem + alertClasses[i];
		}
	}

	pos = dynContains(alertClasses, "");
	if(pos <= 0)
	{
		fwException_raise(exceptionInfo, "ERROR", "fwAlertConfig_prepareDigital: There is no valid range for \"" + dpe + "\".  One range must have alert class equal to \"\"", "");
		return;
	}
	else
	{
		okRange = pos - 1;
		alertClass = alertClasses[!okRange + 1];
	}
	
	attributes = makeDynString(			dpe + ":_alert_hdl.._ok_range",
								dpe + ":_alert_hdl.._text1",
								dpe + ":_alert_hdl.._text0",
								dpe + ":_alert_hdl.._class");
	
	values = makeDynAnytype(okRange, alertTexts[2], alertTexts[1], alertClass);
	
	alertHelpChanged = ((alertPanel != "") || (alertHelp != "") || (alertPanelParameters != makeDynString()));
	if(!modifyExistingConfig || alertHelpChanged)
	{
		//finish list of attributes by adding the remainder to the list
		dynAppend(attributes, dpe + ":_alert_hdl.._help");
		dynAppend(values, alertHelp);
		dynAppend(attributes, dpe + ":_alert_hdl.._panel");
		dynAppend(values, alertPanel);
		dynAppend(attributes, dpe + ":_alert_hdl.._panel_param");
		//alert panel parameters are added in such a way as they stay as a dyn_string when appended
		tempValue = makeDynAnytype(alertPanelParameters);
		dynAppend(values, tempValue);
	}

	if(!modifyExistingConfig)
	{
		dynInsertAt(attributes, dpe + ":_alert_hdl.._type", 1);
		dynInsertAt(values, configType, 1);
		dynAppend(attributes, dpe + ":_alert_hdl.._min_prio");
		dynAppend(values, minimumPriority);
		dynAppend(attributes, dpe + ":_alert_hdl.._orig_hdl");
		dynAppend(values, FALSE);
	}
//DebugN(attributes, values);
}

/** Deletes the alert config for the given data point elements

@par Constraints
	None

@par Usage
	Public

@par PVSS managers
	VISION, CTRL

@param dpes						list of data point elements
@param exceptionInfo	details of any errors are returned here
@param removeDpeInSummary	OPTIONAL PARAMETER - default value = "" (no aciton)
				You can specify the dpe which has a summary alert from which you want to remove the reference to the dpe to delete
@param storeInParamHistory	OPTIONAL PARAMETER - default value = TRUE
				You can specify if the change should be stored in the Paramterisation History of PVSS
*/
fwAlertConfig_deleteMultiple(dyn_string dpes, dyn_string &exceptionInfo, string removeDpeInSummary = "", bool storeInParamHistory = TRUE)
{
	bool relativeSummaryPath;
	int i, length;
	dyn_string summaryDpes;
	dyn_int summaryConfigTypes;
	dyn_errClass errors;

	length = dynlen(dpes);

	fwAlertConfig_deactivateMultiple(dpes, exceptionInfo, TRUE);

	if(dynlen(exceptionInfo) > 0)
		return;
	else if(removeDpeInSummary != "")
	{
		relativeSummaryPath = !dpExists(removeDpeInSummary);
		if(!relativeSummaryPath)
		{
			for(i=1; i<=length; i++)
				summaryDpes[i] = removeDpeInSummary;	
		}
		else
		{
			for(i=1; i<=length; i++)
				summaryDpes[i] = dpSubStr(dpes[i], DPSUB_SYS_DP) + removeDpeInSummary;
		}

		_fwConfigs_getConfigTypeAttribute(summaryDpes, fwConfigs_PVSS_ALERT_HDL, summaryConfigTypes, exceptionInfo);
		errors = getLastError(); 
    		if(dynlen(errors) > 0)
    		{ 
	 			fwException_raise(exceptionInfo, "ERROR", "fwAlertConfig_deleteMultiple: Could not read all summary alerts.", "");
				return;
		}

		for(i=1; i<=length; i++)
		{
			if(summaryConfigTypes[i] == DPCONFIG_SUM_ALERT)
				fwAlertConfig_deleteDpFromAlertSummary(summaryDpes[i], dpSubStr(dpes[i], DPSUB_SYS_DP_EL), exceptionInfo, FALSE);
			else if(summaryConfigTypes[i] != DPCONFIG_NONE)
	 			fwException_raise(exceptionInfo, "ERROR", "fwAlertConfig_deleteMultiple: The alert on \"" + summaryDpes[i] + "\" is not a summary alert as expected.", "");

//DebugN(summaryConfigTypes[i], summaryDpes[i], dpes[i], exceptionInfo);
		}
	}

	_fwConfigs_delete(dpes, fwConfigs_PVSS_ALERT_HDL, exceptionInfo, storeInParamHistory?-1:0);
}


/** Deletes the alert config for the given data point elements

@par Constraints
	None

@par Usage
	Public

@par PVSS managers
	VISION, CTRL

@param dpes						list of data point elements
@param exceptionInfo	details of any errors are returned here
@param removeDpeInSummary	OPTIONAL PARAMETER - default value = "" (no aciton)
				You can specify the dpe which has a summary alert from which you want to remove the reference to the dpe to delete
@param storeInParamHistory	OPTIONAL PARAMETER - default value = TRUE
				You can specify if the change should be stored in the Paramterisation History of PVSS
*/
fwAlertConfig_deleteMany(dyn_string dpes, dyn_string &exceptionInfo, string removeDpeInSummary = "", bool storeInParamHistory = TRUE)
{
	fwAlertConfig_deleteMultiple(dpes, exceptionInfo, removeDpeInSummary, storeInParamHistory);
}


/** Deletes the alert config for the given data point element

@par Constraints
	None

@par Usage
	Public

@par PVSS managers
	VISION, CTRL

@param dpe						data point element
@param exceptionInfo	details of any errors are returned here
@param removeDpeInSummary	OPTIONAL PARAMETER - default value = "" (no aciton)
				You can specify the dpe which has a summary alert from which you want to remove the reference to the dpe to delete
@param storeInParamHistory	OPTIONAL PARAMETER - default value = TRUE
				You can specify if the change should be stored in the Paramterisation History of PVSS
*/
fwAlertConfig_delete(string dpe, dyn_string &exceptionInfo, string removeDpeInSummary = "", bool storeInParamHistory = TRUE)
{
	fwAlertConfig_deleteMultiple(makeDynString(dpe), exceptionInfo, removeDpeInSummary, storeInParamHistory);
}


 


_fwAlertConfig_generateExtraAnalogConfig(int ranges, dyn_float limits, dyn_int &alertHandlingTypes, dyn_float &hysteresisLimits,
																							dyn_bool &hysteresisType, dyn_bool &includeLimits, dyn_string &exceptionInfo)
{
	int i;

	dynClear(alertHandlingTypes);
	dynClear(hysteresisLimits);
	dynClear(hysteresisType);
	dynClear(includeLimits);
	
	for(i=1; i<=ranges; i++)
	{
		hysteresisType[i] = DPATTR_HYST_NONE;
		alertHandlingTypes[i] = DPDETAIL_RANGETYPE_MINMAX;
	}          

 	for(i=1; i<=(ranges-1); i++)
	{
		includeLimits[i] = FALSE;
		hysteresisLimits[((i-1)*2)+1] = limits[i];
		hysteresisLimits[((i-1)*2)+2] = limits[i];
	}          
}


/** Prepares a list of attributes and a list of values to be used in a dpSetWait() call to set the config for the given dpe. 

@par Constraints
	The length of the alertTexts, alertHandlingType, hysteresisType and alertClasses dyn_vars must be equal
			 The length of the limits and includeLimits dyn_vars must be one less than the length of alertTexts

@par Usage
	Internal

@par PVSS managers
	VISION, CTRL

@param dpe							Name of data point element to act on
@param currentConfigType	The type of the current alert config on the data point element (only considered in case of modifyOnly = TRUE, otherwise value is ignored)
@param currentNumberOfRanges	The current number of ranges in the alert config on the data point element (only considered in case of modifyOnly = TRUE, otherwise value is ignored)
@param alertHandlingType	One value in dyn_int for each range to be used. Value should be DPDETAIL_RANGETYPE_MINMAX;
@param limits						The limits of each range given here eg. makeDynFloat( 20, 60 );
@param alertTexts				Alert texts for each range eg. makeDynString( "Bad Text", "OK", "Bad Text")   
@param alertClasses			Alert classes for each range eg. makeDynString( "_fwErrorAck.", "" , "_fwErrorAck.")
													One of the items of the dyn_string must always be empty to indicate the valid state.
													The valid ranges becomes the state with no alert class given (the second in this case).
													Don't forget to add the dot to the alert class names.
@param includeLimits		TRUE to include, else FALSE
@param minimumPriority	Minimum priority of alert (ignore below this value)
@param alertPanel				Panel to call from the alert screen
@param alertPanelParameters		Parameters to pass to panel given in Alert Panel
@param alertHelp				Help text or path to help file    
@param hysteresisType		One value for each range in use:
													DPATTR_HYST_NONE for no hysteresis or
													DPATTR_HYST_VALUE for hysteresis
@param hysteresisLimits	Values for limits of hysteresis (length of dyn_float) should be (ranges-1)*2
@param attributes				Output - the list of attributes that need to be set is returned here
@param values						Output - the list of values that need to be set is returned here
@param exceptionInfo		Details of any exceptions are returned here   
@param modifyOnly				Optional parameter - Default value FALSE.  Set to TRUE to modify alert without setting "type" attributes.
						This is much quicker, but the alert config must already exist, be an analog alert and have the same number of ranges as you want.
@param fallBackToSet			Optional parameter - Default value FALSE.  Used in combination with modifyOnly.
						If modifyOnly = TRUE and fallBackToSet = FALSE, then if the alert config is not compatible an exception is raised. 
						If modifyOnly = TRUE and fallBackToSet = TRUE, then if the alert config is not compatible, modifyOnly is treated as if it was FALSE. 
*/
_fwAlertConfig_prepareAnalog( string dpe,
                          int currentConfigType,
                          int currentNumberOfRanges,
                          dyn_int alertHandlingType,    
                          dyn_float limits,    
                          dyn_string alertTexts,    
                          dyn_string alertClasses,    
                          dyn_bool includeLimits,    
                          int minimumPriority,    
                          string alertPanel,    
                          dyn_string alertPanelParameters,    
                          string alertHelp,    
                          dyn_int hysteresisType,    
                          dyn_float hysteresisLimits,
              dyn_string &attributes,
              dyn_mixed &values,
						  dyn_string &exceptionInfo,
						  bool modifyOnly = FALSE,
						  bool fallBackToSet = FALSE)
{    
	bool deactivated, alertHelpChanged, isActive = FALSE, modifyExistingConfig;
	int configType, currentRanges;  
	int i, j, length, ranges, numberOfAttributes, attributeOffset;
	string attribute, dpeSystem;
	dyn_string attributeTemplates;
	dyn_float upperHystLimits, lowerHystLimits;
	dyn_anytype desiredValues;
	dyn_mixed tempValue;
	dyn_bool notIncludeLimits;

	const string alertHandlingTypeAttribute = ":_alert_hdl.<i>._type";
	const string hysteresisTypeAttribute = ":_alert_hdl.<i>._hyst_type";
	const string upperLimitAttribute = ":_alert_hdl.<i>._u_limit";
	const string lowerLimitAttribute = ":_alert_hdl.<i>._l_limit";
	const string alertTextAttribute = ":_alert_hdl.<i>._text";
	const string alertClassAttribute = ":_alert_hdl.<i>._class";
	const string includeLowerLimitAttribute = ":_alert_hdl.<i>._l_incl";
	const string includeUpperLimitAttribute = ":_alert_hdl.<i>._u_incl";
	const string hysteresisUpperLimitAttribute = ":_alert_hdl.<i>._u_hyst_limit";
	const string hysteresisLowerLimitAttribute = ":_alert_hdl.<i>._l_hyst_limit";

	dynClear(attributes);
	dynClear(values);

	ranges = dynlen(alertTexts);

	configType = DPCONFIG_ALERT_NONBINARYSIGNAL;	
	//if we are set to modifyOnly, we need to look more at the current config
	if(modifyOnly)
	{
		//first, check the config exists
		if(currentConfigType != configType)
		{
			if(fallBackToSet)
				modifyExistingConfig = FALSE;
			else
			{
				fwException_raise(exceptionInfo, "ERROR", "fwAlertConfig_prepareDigital: Alert config does not exist on \"" + dpe + "\" so it cannot be modified", "");
				return;
			}
		}
		//if number of current ranges and desired ranges are different then we can not modify
		else if(ranges != currentNumberOfRanges)
		{
			if(fallBackToSet)
				modifyExistingConfig = FALSE;
			else
			{
				fwException_raise(exceptionInfo, "ERROR", "_fwAlertConfig_prepareAnalog: Cannot modify current alert config on \"" + dpe + "\" because it contains a different number of ranges", "");
				return;
			}
		}
		else
			modifyExistingConfig = TRUE;
	}
	else
		modifyExistingConfig = FALSE;

	//check that all dyn_vars are of a consistent length for the number of ranges
	if(	dynlen(alertTexts) != ranges ||
		dynlen(alertClasses) != ranges ||
		dynlen(limits) != (ranges-1))
	{
		fwException_raise(exceptionInfo, "ERROR", "_fwAlertConfig_prepareAnalog: The alert configuration for \"" + dpe + "\" is not consistent (Check length of dyn variables)", "");
		return;
	}

	if(!modifyExistingConfig)
	{
		if(	dynlen(hysteresisType) != ranges ||
			dynlen(alertHandlingType) != ranges ||
			dynlen(includeLimits) != (ranges-1) ||
			dynlen(hysteresisLimits) != ((ranges-1)*2))
		{
			fwException_raise(exceptionInfo, "ERROR", "_fwAlertConfig_prepareAnalog: The alert configuration for \"" + dpe + "\" is not consistent (Check length of dyn variables)", "");
			return;
		}

		//for the values, start by creating !includeLimits
		length = dynlen(includeLimits);
		for(i=1; i<=length; i++)
		{
			notIncludeLimits[i] = !includeLimits[i];
		}

		//split hysteresis limits into upper and lower limits
		length = dynlen(hysteresisLimits);
		for(i=1; i<=length; i++)
		{
			if(i%2 == 0)
				dynAppend(lowerHystLimits, hysteresisLimits[i]);
			else
				dynAppend(upperHystLimits, hysteresisLimits[i]);
		}
	}

	if(dynContains(alertClasses, "")<=0)
	{
		fwException_raise(exceptionInfo, "ERROR", "_fwAlertConfig_prepareAnalog: There is no valid range for \"" + dpe + "\".  One range must have alert class equal to \"\"", "");
		return;
	}

	//for the alertClasses, ensure that the same system as the dpe is used.
	length = dynlen(alertClasses);
	for(i=1; i<=length; i++)
	{
		if(alertClasses[i] != "")
		{
			dpeSystem = dpSubStr(dpe, DPSUB_SYS);
			if(strpos(alertClasses[i], dpeSystem) != 0)
				alertClasses[i] = dpeSystem + alertClasses[i];
		}
	}

	if(modifyExistingConfig)
	{
		//build list of attribute templates from globals constants          
		attributeTemplates = makeDynString(lowerLimitAttribute, upperLimitAttribute, alertTextAttribute, alertClassAttribute);
			
		//build array of most of the values to be written
		desiredValues = makeDynAnytype(limits, limits, alertTexts, alertClasses);
	}
	else
	{
	    //build list of attribute templates from globals constants          
		attributeTemplates = makeDynString(alertHandlingTypeAttribute, hysteresisTypeAttribute,
											lowerLimitAttribute, upperLimitAttribute, 
											alertTextAttribute, alertClassAttribute,
											includeLowerLimitAttribute, includeUpperLimitAttribute, 
											hysteresisLowerLimitAttribute, hysteresisUpperLimitAttribute);
		
		
		//build array of most of the values to be written
		desiredValues = makeDynAnytype(configType, alertHandlingType, hysteresisType,
											limits, limits, 
											alertTexts, alertClasses,
											TRUE, notIncludeLimits, includeLimits, TRUE,
											lowerHystLimits, upperHystLimits);

		//start building list of attributes
		dynAppend(attributes, dpe + ":_alert_hdl.._type");
	}       
	
	//add range dependant attributes to list
	length = dynlen(attributeTemplates);
	for(i=1; i<=length; i++)
	{
		switch(attributeTemplates[i])
		{
			//for upper limit and hysteresis upper limit attributes start at 1, creating (ranges - 1) attributes
			case upperLimitAttribute:
			case hysteresisUpperLimitAttribute:
				attributeOffset = 0;
				numberOfAttributes = ranges-1;
				break;
			//for lower limit and hysteresis lower limit attributes start at 2, creating (ranges - 1) attributes
			case lowerLimitAttribute:
			case hysteresisLowerLimitAttribute:
				attributeOffset = 1;
				numberOfAttributes = ranges-1;
				break;
			//for all other attributes start at 1, creating (ranges) attributes
			default:
				attributeOffset = 0;
				numberOfAttributes = ranges;
				break;
		}
		
		//replace <i> with ranges number and append to list of attributes to write
		for(j=1; j<=numberOfAttributes; j++)
		{
			attribute = attributeTemplates[i];
			strreplace(attribute, "<i>", j + attributeOffset);
			dynAppend(attributes, dpe + attribute);
		}
	}
	
	//build up a single list of values from the desiredValues array
	length = dynlen(desiredValues);
	for(i=1; i<=length; i++)
	{
		tempValue = desiredValues[i];
		dynAppend(values, tempValue);
	}

	alertHelpChanged = ((alertPanel != "") || (alertHelp != "") || (alertPanelParameters != makeDynString()));
	if(!modifyExistingConfig || alertHelpChanged)
	{
		//finish list of attributes by adding the remainder to the list
		dynAppend(attributes, dpe + ":_alert_hdl.._help");
		dynAppend(values, alertHelp);
		dynAppend(attributes, dpe + ":_alert_hdl.._panel");
		dynAppend(values, alertPanel);
		dynAppend(attributes, dpe + ":_alert_hdl.._panel_param");
		//alert panel parameters are added in such a way as they stay as a dyn_string when appended
		tempValue = makeDynAnytype(alertPanelParameters);
		dynAppend(values, tempValue);
	}

	if(!modifyExistingConfig)
	{
		dynAppend(attributes, dpe + ":_alert_hdl.._min_prio");
		dynAppend(values, minimumPriority);
		dynAppend(attributes, dpe + ":_alert_hdl.._orig_hdl");
		dynAppend(values, FALSE);
	}

//DebugN(attributes, values);
} 


/** Returns the alert handling properties of a analog or digital datapoint
	if the number of alert texts returned is 0, then no alert configuration exists

NOTE: THIS FUNCTION SHOULD NOT BE CALLED DIRECTLY, use fwAlertConfig_get

@par Constraints
	The length of the alertTexts and alertClasses dyn_strings must both be 2

@par Usage
	Internal

@par PVSS managers
	VISION, CTRL

@param dpe							Name of data point element to act on
@param alertTexts				Alert texts for each range  
@param alertLimits			The limits of each range given here
@param alertClass				Alert classes for each range 
													One of the items of the dyn_string must always be empty to indicate the valid state.
													Don't forget to add the dot to the alert class names.
@param alertPanel				Panel to call from the alert screen
@param alertPanelParameters		Parameters to pass to panel given in alertPanel
@param alertHelp				Help text or path to help file    
@param alertActive			whether or not this configuration is active
@param exceptionInfo		Details of any exceptions are returned here   
*/
_fwAlertConfig_get(string dpe, int &alertType, dyn_string &alertTexts, dyn_float &alertLimits,
                   dyn_string &alertClass, dyn_string &summaryDpeList, string &alertPanel,
				  dyn_string &alertPanelParameters, string &alertHelp, bool &alertActive, dyn_string &exceptionInfo)
{
  bool digitalOKRange;
  int alertRanges;
  dyn_int limitNumbers;
  string class, dpePattern;
  dyn_string dpeList;
  float dummyFloat;
  int i;
	
  	//DebugN(dpe +":");
  dynClear(alertTexts);
  dynClear(alertClass);
  dynClear(alertLimits);
  dynClear(summaryDpeList);

  dpGet(dpe+":_alert_hdl.._type",alertType);
  if(alertType == DPCONFIG_NONE)
  {
    alertPanel = "";
    alertPanelParameters = makeDynString();
    alertHelp = "";
    alertActive = FALSE;
    return;
  }
  			
	if(alertType == DPCONFIG_ALERT_BINARYSIGNAL)
	{
		alertRanges = 2;
		dpGet(	dpe+":_alert_hdl.._ok_range",digitalOKRange,
				dpe+":_alert_hdl.._text1",alertTexts[2],
				dpe+":_alert_hdl.._text0",alertTexts[1],
				dpe+":_alert_hdl.._class",class,
      dpe+":_alert_hdl.._active",alertActive,
  			dpe+":_alert_hdl.._help",alertHelp,
  			dpe+":_alert_hdl.._panel",alertPanel,
  			dpe+":_alert_hdl.._panel_param",alertPanelParameters);
				
		if(digitalOKRange == 0)
			alertClass = makeDynString("", class);
		else
			alertClass = makeDynString(class, "");
	}
	else if(alertType == DPCONFIG_ALERT_NONBINARYSIGNAL)
	{
		fwAlertConfig_getLimits(dpe, limitNumbers, alertLimits, exceptionInfo);
		alertRanges = (dynMax(limitNumbers) + 1);
		for(i=1; i<=alertRanges; i++)
		{
			dpGet(	dpe+":_alert_hdl."+i+"._text",alertTexts[i],
        dpe+":_alert_hdl."+i+"._class",alertClass[i]);      
		}
    dpGet(dpe+":_alert_hdl.._active",alertActive,
          dpe+":_alert_hdl.._help",alertHelp,
          dpe+":_alert_hdl.._panel",alertPanel,
          dpe+":_alert_hdl.._panel_param",alertPanelParameters);
	}
  else if(alertType == DPCONFIG_SUM_ALERT)
  {
    
    dpGet(dpe + ":_alert_hdl.._dp_list", dpeList,
          dpe + ":_alert_hdl.._dp_pattern", dpePattern,
          dpe + ":_alert_hdl.._text1", alertTexts[2],       
          dpe + ":_alert_hdl.._text0", alertTexts[1],
          dpe + ":_alert_hdl.._help", alertHelp,
          dpe + ":_alert_hdl.._panel", alertPanel,
          dpe + ":_alert_hdl.._panel_param", alertPanelParameters,
          dpe + ":_alert_hdl.._active", alertActive);

    alertClass[1] = "";
//DebugN(dpeList, dpePattern);    
    if(dynlen(dpeList) > 0)
      summaryDpeList = dpeList;
    else if(dpePattern != fwAlertConfig_FW_NULL_PATTERN)
      summaryDpeList = dpePattern;    
    else
      summaryDpeList = makeDynString();
//DebugN(dpeList, dpePattern);

    if(isAlertFilteringActive())
      dpGet(dpe + ":_alert_hdl.._filter_threshold", alertLimits[1]);
    else
      alertLimits[1] = 0;
  }
//DebugN("Is alert active?", dpe, alertActive);
}
  

/** Adds a new data point element to the dp list of an existing summary alert handling
on the given data point element.

@par Constraints
	None

@par Usage
	Public

@par PVSS managers
	VISION, CTRL

@param dpe						Name of data point element where the summary alert config is
@param dpeToAdd				Name of the data point element to be added to the summary alert
@param exceptionInfo	Details of any exceptions are returned here  
@param errorIfPresent	OPTIONAL PARAMETER - default value TRUE
				If TRUE, an exception is raised if the dpeToAdd is already configured in the summary alert.
				If FALSE, no exception is raised in this case. 
@param storeInParamHistory	OPTIONAL PARAMETER - default value = TRUE
				You can specify if the change should be stored in the Paramterisation History of PVSS
*/
fwAlertConfig_addDpInAlertSummary( string dpe, string dpeToAdd, dyn_string &exceptionInfo, bool errorIfPresent = TRUE, bool storeInParamHistory = TRUE)      
{   
  bool configExists, isActive;
  int position, alertType;
  string alertPanel, alertHelp;
  dyn_float alertLimits;
  dyn_string alertTexts, alertClasses, dpeList, alertPanelParameters;
       
  fwAlertConfig_get(dpe, configExists, alertType, alertTexts, alertLimits, alertClasses, dpeList,
                    alertPanel, alertPanelParameters, alertHelp, isActive, exceptionInfo);
  if(dynlen(exceptionInfo)>0)
    return;

  if(alertType != DPCONFIG_SUM_ALERT)
  {
    fwException_raise(exceptionInfo, "ERROR", "fwAlertConfig_addDpInAlertSummary(): "+dpe+" does not have a summary alert.", "");
    return;
  }

	position = dynContains(dpeList, dpeToAdd);
	if (position <= 0)
	{   
	    	dynAppend(dpeList, dpeToAdd);   

		fwAlertConfig_set(dpe, DPCONFIG_SUM_ALERT, alertTexts, makeDynFloat(), makeDynString(),
					dpeList, alertPanel, alertPanelParameters, alertHelp, exceptionInfo, TRUE, FALSE, "", storeInParamHistory);
	}
	else if(errorIfPresent)
	{
        fwException_raise(exceptionInfo, "ERROR", "fwAlertConfig_addDpInAlertSummary(): " + dpeToAdd + " is already in the summary alert", "");
	}
}   
  
  
/** Removes a data point element from the dp list of an existing summary alert handling
on the given data point element.

@par Constraints
	None

@par Usage
	Public

@par PVSS managers
	VISION, CTRL

@param dpe						Name of data point element where the summary alert config is
@param dpeToDelete		Name of the data point element to be removed from the summary alert
@param exceptionInfo	Details of any exceptions are returned here   
@param errorIfNotPresent	OPTIONAL PARAMETER - default value TRUE
					If TRUE, an exception is raised if the dpeToDelete is not currently configured in the summary alert.
					If FALSE, no exception is raised in this case. 
@param storeInParamHistory	OPTIONAL PARAMETER - default value = TRUE
				You can specify if the change should be stored in the Paramterisation History of PVSS
*/
fwAlertConfig_deleteDpFromAlertSummary( string dpe, string dpeToDelete, dyn_string &exceptionInfo, bool errorIfNotPresent = TRUE, bool storeInParamHistory = TRUE)      
{   
  bool configExists, isActive;
  int position, removed, alertType;
  string alertPanel, alertHelp;
  dyn_float alertLimits;
  dyn_string alertTexts, alertClasses, dpeList, alertPanelParameters;
       
  fwAlertConfig_get(dpe, configExists, alertType, alertTexts, alertLimits, alertClasses, dpeList,
                    alertPanel, alertPanelParameters, alertHelp, isActive, exceptionInfo);
  if(dynlen(exceptionInfo)>0)
    return;
  
  if(alertType != DPCONFIG_SUM_ALERT)
  {
    fwException_raise(exceptionInfo, "ERROR", "fwAlertConfig_deleteDpFromAlertSummary(): "+dpe+" does not have a summary alert.", "");
    return;
  }
   
	position = dynContains(dpeList, dpeToDelete);
	if(position > 0)
	{   
		removed = dynRemove(dpeList, position);   
		if(removed == 0)
		{    
			fwAlertConfig_set(dpe, DPCONFIG_SUM_ALERT, alertTexts, makeDynFloat(), makeDynString(),
						dpeList, alertPanel, alertPanelParameters, alertHelp, exceptionInfo, TRUE, FALSE, "", storeInParamHistory);
		}   
		else
		{   
			fwException_raise(exceptionInfo, "ERROR", "fwAlertConfig_deleteDpFromAlertSummary(): "+dpeToDelete+" was not removed from the summary alert", "");
		}   
	}
	else if(errorIfNotPresent)
	{   
		fwException_raise(exceptionInfo, "ERROR", "fwAlertConfig_deleteDpFromAlertSummary(): "+dpeToDelete+" is not in the summary alert", "");
	}   	
}   


/** Checks for a reference to a given data point element in the dp list of an existing summary alert handling
on the given data point element.

@par Constraints
	None

@par Usage
	Public

@par PVSS managers
	VISION, CTRL

@param dpe						Name of data point element where the summary alert config is
@param dpeToLookFor		Name of the data point element to be searched for in the summary alert
@param dpeFound				Result is returned here.  TRUE if dpe was found in summary alert, else FALSE
@param exceptionInfo	Details of any exceptions are returned here   
*/
fwAlertConfig_checkIsDpInAlertSummary(string dpe, string dpeToLookFor, bool &dpeFound, dyn_string &exceptionInfo)      
{
  bool configExists, isActive;
  int position, alertType;
  string alertPanel, alertHelp;
  dyn_float alertLimits;
  dyn_string alertTexts, alertClasses, dpeList, alertPanelParameters;
       
  dpeFound = FALSE;

  fwAlertConfig_get(dpe, configExists, alertType, alertTexts, alertLimits, alertClasses, dpeList,
                    alertPanel, alertPanelParameters, alertHelp, isActive, exceptionInfo);
  if(dynlen(exceptionInfo)>0)
    return;
  
  if(alertType != DPCONFIG_SUM_ALERT)
  {
    fwException_raise(exceptionInfo, "ERROR", "fwAlertConfig_checkIsDpInAlertSummary(): "+dpe+" does not have a summary alert.", "");
    return;
  }
  
  position = dynContains(dpeList, dpeToLookFor);   
  if(position > 0)
    dpeFound = TRUE;
}


/** Prepares a list of attributes and a list of values to be used in a dpSetWait() call to set the config for the given dpe. 

@par Constraints
	The length of the alertTexts should be 2
	Can only set summary alerts of type dp list (not dp pattern)

@par Usage
	Public

@par PVSS managers
	VISION, CTRL

@param dpe						Name of data point element to act on
@param currentConfigType	The type of the current alert config on the data point element (only considered in case of modifyOnly = TRUE, otherwise value is ignored)
@param alertTexts			Alert texts eg. makeDynString( "OK", "Bad")   
@param dpElementList	List of dpes to include in summary alert
@param minimumPriority	Minimum priority of alert (ignore below this value)
@param alertPanel			Panel to call from the alert screen
@param alertPanelParameters		Parameters to pass to panel given in Alert Panel
@param alertHelp			Help text or path to help file    
@param attributes			Output - the list of attributes that need to be set is returned here
@param values					Output - the list of values that need to be set is returned here
@param exceptionInfo	Details of any exceptions are returned here   
@param modifyOnly				Optional parameter - Default value FALSE.  Set to TRUE to modify alert without setting "type" attributes.
						This is much quicker, but the alert config must already exist and be of type summary alert.
@param fallBackToSet			Optional parameter - Default value FALSE.  Used in combination with modifyOnly.
						If modifyOnly = TRUE and fallBackToSet = FALSE, then if the alert config is not compatible an exception is raised. 
						If modifyOnly = TRUE and fallBackToSet = TRUE, then if the alert config is not compatible, modifyOnly is treated as if it was FALSE. 
*/
_fwAlertConfig_prepareSummary(string dpe,
							int currentConfigType,
							float threshold,    
							dyn_string alertTexts,
							dyn_string dpElementList,      
							int minimumPriority,    
							string alertPanel,
							dyn_string alertPanelParameters,
							string alertHelp,
							dyn_string &attributes,
							dyn_mixed &values,
							dyn_string &exceptionInfo,
							bool modifyOnly = FALSE,
							bool fallBackToSet = FALSE)
{
	bool alertHelpChanged , deactivated, isActive = FALSE, modifyExistingConfig;
	int pos, configType, attributesLength;
	string alertClass;
	dyn_mixed tempValue, extraValues;
	dyn_string extraAttributes;
	
	dynClear(attributes);
	dynClear(values);
	
	configType = DPCONFIG_SUM_ALERT;
	if(modifyOnly)
	{
		if(currentConfigType != configType)
		{
			if(fallBackToSet)
				modifyExistingConfig = FALSE;
			else
			{
				fwException_raise(exceptionInfo, "ERROR", "fwAlertConfig_prepareSummary: Alert config does not exist on \"" + dpe + "\" so it cannot be modified", "");
				return;
			}
		}
		else
			modifyExistingConfig = TRUE;
	}
	else
		modifyExistingConfig = FALSE;

	if(dynlen(alertTexts) != 2)
	{
		fwException_raise(exceptionInfo, "ERROR", "_fwAlertConfig_prepareSummary: The alert configuration required for \"" + dpe + "\" is not consistent (Check length of dyn variables)", "");
		return;
	}
	
  attributes = makeDynString(dpe + ":_alert_hdl.._text1", dpe + ":_alert_hdl.._text0");
  values = makeDynAnytype(alertTexts[2], alertTexts[1]);

  if(isAlertFilteringActive())
  {
    dynAppend(attributes, dpe + ":_alert_hdl.._filter_threshold");
    dynAppend(values, threshold);
  }
        
        attributesLength = dynlen(attributes);
        attributesLength++;
        
        //check to see if DP pattern or DP list was passed
        if(dynlen(dpElementList) > 0)
        {
          if((strpos(dpElementList[1], "*") >= 0) || (strpos(dpElementList[1], "?") >= 0))
          {
            attributes[attributesLength] = dpe + ":_alert_hdl.._dp_pattern";
            values[attributesLength] = dpElementList[1];
          }
          else
          {
            attributes[attributesLength] = dpe + ":_alert_hdl.._dp_list";          
            values[attributesLength] = dpElementList;
          }
        }
        else
        {
           attributes[attributesLength] = dpe + ":_alert_hdl.._dp_pattern";          
           values[attributesLength] = fwAlertConfig_FW_NULL_PATTERN;
        }
        
	alertHelpChanged = ((alertPanel != "") || (alertHelp != "") || (alertPanelParameters != makeDynString()));
	if(!modifyExistingConfig || alertHelpChanged)
	{
		//finish list of attributes by adding the remainder to the list
		dynAppend(attributes, dpe + ":_alert_hdl.._help");
		dynAppend(values, alertHelp);
		dynAppend(attributes, dpe + ":_alert_hdl.._panel");
		dynAppend(values, alertPanel);
		dynAppend(attributes, dpe + ":_alert_hdl.._panel_param");
		//alert panel parameters are added in such a way as they stay as a dyn_string when appended
		tempValue = makeDynAnytype(alertPanelParameters);
		dynAppend(values, tempValue);
	}

	if(!modifyExistingConfig)
	{
		dynInsertAt(attributes, dpe + ":_alert_hdl.._type", 1);
		dynInsertAt(values, configType, 1);

		extraAttributes = makeDynString(	dpe + ":_alert_hdl.._class",       
                 						dpe + ":_alert_hdl.._ack_has_prio",       
								dpe + ":_alert_hdl.._order",       
								dpe + ":_alert_hdl.._dp_pattern",       
								dpe + ":_alert_hdl.._prio_pattern",       
								dpe + ":_alert_hdl.._abbr_pattern",      
								dpe + ":_alert_hdl.._ack_deletes",      
								dpe + ":_alert_hdl.._non_ack",      
								dpe + ":_alert_hdl.._came_ack",     
								dpe + ":_alert_hdl.._pair_ack",    
								dpe + ":_alert_hdl.._both_ack");       

		extraValues = makeDynAnytype("", TRUE, FALSE, "", "", "", TRUE, TRUE, TRUE, TRUE, TRUE);

		dynAppend(attributes, extraAttributes);
		dynAppend(values, extraValues);
	}

//DebugN(attributes, values);
}


/** Returns the details of any alert configuration on a given set of dpes.
This function can handle digital, analog and summary alerts

@par Constraints
	Can only get summary alerts of type dp list (not dp pattern)

@par Usage
	Public

@par PVSS managers
	VISION, CTRL

@param dpes							Name of data point elements to read from
@param configExists			Return TRUE if dpe has a summary alert config, else FALSE
@param alertConfigType	Type of alert on dpe:
													DPCONFIG_ALERT_BINARYSIGNAL if digital alert handling
													DPCONFIG_ALERT_NONBINARYSIGNAL if analog alert handling
													DPCONFIG_SUM_ALERT if summary alert handling
@param alertTexts				Alert texts are returned here for all types of alert
@param alertLimits			Alert limits are returned here for analog alerts
@param alertClasses			Alert classes are returned here for digital and analog alertd
@param summaryDpeList		If Summary alert, the dpeList is returned here  
                                      If a DP pattern was specified, then this will be returned as the first item in this list.
@param alertPanel				Panel to call from the alert screen
@param alertPanelParameters		Parameters to pass to the given alertPanel
@param alertHelp				Help text or path to help file    
@param isActive					TRUE if alert is active else FALSE
@param exceptionInfo		Details of any exceptions are returned here   
*/
fwAlertConfig_getMany(	dyn_string dpes,
					dyn_bool &configExists,
					dyn_int &alertConfigType,
					dyn_dyn_string &alertTexts,
					dyn_dyn_float &alertLimits,
					dyn_dyn_string &alertClasses,
					dyn_dyn_string &summaryDpeList,
					dyn_string &alertPanel,
					dyn_dyn_string &alertPanelParameters,
					dyn_string &alertHelp,
					dyn_bool &isActive,
					dyn_string &exceptionInfo)
{
	int i, length;
	
	length = dynlen(dpes);
	for(i=1; i<=length; i++)
	{
		fwAlertConfig_get(dpes[i], configExists[i], alertConfigType[i], alertTexts[i], alertLimits[i], alertClasses[i], summaryDpeList[i],
											alertPanel[i], alertPanelParameters[i], alertHelp[i], isActive[i], exceptionInfo);
	}
}


/** Returns the details of any alert configuration on a given dpe.
This function can handle digital, analog and summary alerts

@par Constraints
  None
  
@par Usage
	Public

@par PVSS managers
	VISION, CTRL

@param dpe							Name of data point element to read from
@param configExists			Return TRUE if dpe has a summary alert config, else FALSE
@param alertConfigType	Type of alert on dpe:
													DPCONFIG_ALERT_BINARYSIGNAL if digital alert handling
													DPCONFIG_ALERT_NONBINARYSIGNAL if analog alert handling
													DPCONFIG_SUM_ALERT if summary alert handling
@param alertTexts				Alert texts are returned here for all types of alert
@param alertLimits			Alert limits are returned here for analog alerts
@param alertClasses			Alert classes are returned here for digital and analog alertd
@param summaryDpeList		If Summary alert, the dpeList is returned here
                                      If a DP pattern was specified, then this will be returned as the first item in this list.
@param alertPanel				Panel to call from the alert screen
@param alertPanelParameters		Parameters to pass to the given alertPanel
@param alertHelp				Help text or path to help file    
@param isActive					TRUE if alert is active else FALSE
@param exceptionInfo		Details of any exceptions are returned here   
*/
fwAlertConfig_get(	string dpe,
					bool &configExists,
					int &alertConfigType,
					dyn_string &alertTexts,
					dyn_float &alertLimits,
					dyn_string &alertClasses,
					dyn_string &summaryDpeList,
					string &alertPanel,
					dyn_string &alertPanelParameters,
					string &alertHelp,
					bool &isActive,
					dyn_string &exceptionInfo)
{
	dyn_int configTypes;
	dyn_float dummyVariable;
	
	if(strpos(dpe, ".") < 0)
		dpe += ".";
        
  _fwAlertConfig_get(dpe, alertConfigType, alertTexts, alertLimits, alertClasses, summaryDpeList,
                      alertPanel, alertPanelParameters, alertHelp, isActive, exceptionInfo);
  
  if(alertConfigType == DPCONFIG_NONE)
    configExists = FALSE;
  else
    configExists = TRUE;
}


/** Sets the alert configuration on for a list of dpes.
This function can handle digital, analog and summary alerts

@par Constraints
	Can only set summary alerts of type dp list (not dp pattern)

	For digital alerts: The length of the alertTexts and alertClasses dyn_strings must both be 2
	For analog alerts: 	The length of the alertTexts and alertClasses dyn_strings must be equal
				 		The length of the alertLimits dyn_float must be one less than the length of alertTexts
	For summary alerts: The length of the alertTexts dyn_string must be 2

@par Usage
	Public

@par PVSS managers
	VISION, CTRL

@param dpes							List of data point elements
@param alertConfigType	Type of alert to set:
													DPCONFIG_ALERT_BINARYSIGNAL for digital alert handling
													DPCONFIG_ALERT_NONBINARYSIGNAL for analog alert handling
													DPCONFIG_SUM_ALERT for summary alert handling
@param alertTexts				Alert texts are passed here for all types of alert
@param alertLimits			Alert limits are passed here for analog alerts (otherwise ignored)
@param alertClasses			Alert classes are passed here for digital and analog alerts  (otherwise ignored)
@param summaryDpeList		If Summary alert, the dpeList is passed here (otherwise ignored) 
                                      If you want to specify a DP pattern, then this should entered as the first item in this list.
@param alertPanel				Panel to call from the alert screen
@param alertPanelParameters		Parameters to pass to the given alertPanel
@param alertHelp				Help text or path to help file    
@param exceptionInfo		Details of any exceptions are returned here   
@param modifyOnly				Optional parameter - Default value FALSE.  Set to TRUE to modify alert without setting "type" attributes.
						This is much quicker, but the alert config must already exist, be an analog alert and have the same number of ranges as you want.
@param fallBackToSet			Optional parameter - Default value FALSE.  Used in combination with modifyOnly.
						If modifyOnly = TRUE and fallBackToSet = FALSE, then if the alert config is not compatible an exception is raised. 
						If modifyOnly = TRUE and fallBackToSet = TRUE, then if the alert config is not compatible, modifyOnly is treated as if it was FALSE. 
@param addDpeInSummary 			Optional parameter - Default value "".  Used to add the new alert in a summary alert.
						Default value "" means do not add the new alert into a summary.
						You can specify either an absolute DPE name, or a relative path from the DP to which the new alert was saved.
							i.e.
							addDpeInSummary = "." will add the new alert on dpes[i] to the summary on the root of the datapoint to which dpes[i] belongs. 
							addDpeInSummary = "MyDp.summaries" will add the new alert on dpes[i] to the summary on the dpe called "MyDp.summaries". 
						Note: The summary alarms must already exist.  If they does not exist, it WILL NOT be created.
@param storeInParamHistory		OPTIONAL PARAMETER - default value = TRUE
					You can specify if the change should be stored in the Paramterisation History of PVSS
*/
fwAlertConfig_setMultiple(dyn_string dpes,
					int alertConfigType,
					dyn_string alertTexts,
					dyn_float alertLimits,
					dyn_string alertClasses,
					dyn_string summaryDpeList,
					string alertPanel,
					dyn_string alertPanelParameters,
					string alertHelp,
					dyn_string &exceptionInfo,
					bool modifyOnly = FALSE,
					bool fallBackToSet = FALSE,
					string addDpeInSummary = "",
					bool storeInParamHistory = TRUE)
{
	int i, length;
	dyn_int diAlertConfigType;
	dyn_string dsAlertPanel, dsAlertHelp;
	dyn_dyn_float ddfAlertLimits;
	dyn_dyn_string ddsAlertTexts, ddsAlertClasses, ddsSummaryDpeList, ddsAlertPanelParameters;
	
	length = dynlen(dpes);
	for(i=1; i<=length; i++)
	{
		diAlertConfigType[i] = alertConfigType;
		ddsAlertTexts[i] = alertTexts;
		ddfAlertLimits[i] = alertLimits;
		ddsAlertClasses[i] = alertClasses;
		ddsSummaryDpeList[i] = summaryDpeList;
		dsAlertPanel[i] = alertPanel;
		ddsAlertPanelParameters[i] = alertPanelParameters;
		dsAlertHelp[i] = alertHelp;
	}

	fwAlertConfig_setMany(dpes, diAlertConfigType, ddsAlertTexts, ddfAlertLimits, ddsAlertClasses, ddsSummaryDpeList,
												dsAlertPanel, ddsAlertPanelParameters, dsAlertHelp, exceptionInfo,
												modifyOnly, fallBackToSet, addDpeInSummary, storeInParamHistory);
}


/** Sets the alert configuration on for a list of dpes.
This function can handle digital, analog and summary alerts

@par Constraints
	Can only set summary alerts of type dp list (not dp pattern)

	For digital alerts: The length of the alertTexts and alertClasses dyn_strings must both be 2
	For analog alerts: 	The length of the alertTexts and alertClasses dyn_strings must be equal
				 		The length of the alertLimits dyn_float must be one less than the length of alertTexts
	For summary alerts: The length of the alertTexts dyn_string must be 2

@par Usage
	Public

@par PVSS managers
	VISION, CTRL

@param dpes							List of data point elements
@param alertConfigType	Type of alert to set:
													DPCONFIG_ALERT_BINARYSIGNAL for digital alert handling
													DPCONFIG_ALERT_NONBINARYSIGNAL for analog alert handling
													DPCONFIG_SUM_ALERT for summary alert handling
@param alertTexts				Alert texts are passed here for all types of alert
@param alertLimits			Alert limits are passed here for analog alerts (otherwise ignored)
@param alertClasses			Alert classes are passed here for digital and analog alerts  (otherwise ignored)
@param summaryDpeList		If Summary alert, the dpeList is passed here (otherwise ignored)
                                        If you want to specify a DP pattern, then this should entered as the first item in this list.
@param alertPanel				Panel to call from the alert screen
@param alertPanelParameters		Parameters to pass to the given alertPanel
@param alertHelp				Help text or path to help file    
@param exceptionInfo		Details of any exceptions are returned here   
@param modifyOnly				Optional parameter - Default value FALSE.  Set to TRUE to modify alert without setting "type" attributes.
						This is much quicker, but the alert config must already exist, be an analog alert and have the same number of ranges as you want.
@param fallBackToSet			Optional parameter - Default value FALSE.  Used in combination with modifyOnly.
						If modifyOnly = TRUE and fallBackToSet = FALSE, then if the alert config is not compatible an exception is raised. 
						If modifyOnly = TRUE and fallBackToSet = TRUE, then if the alert config is not compatible, modifyOnly is treated as if it was FALSE. 
@param addDpeInSummary 			Optional parameter - Default value "".  Used to add the new alert in a summary alert.
						Default value "" means do not add the new alert into a summary.
						You can specify either an absolute DPE name, or a relative path from the DP to which the new alert was saved.
							i.e.
							addDpeInSummary = "." will add the new alert on dpes[i] to the summary on the root of the datapoint to which dpes[i] belongs. 
							addDpeInSummary = "MyDp.summaries" will add the new alert on dpes[i] to the summary on the dpe called "MyDp.summaries". 
						Note: The summary alarms must already exist.  If they does not exist, it WILL NOT be created.
@param storeInParamHistory		OPTIONAL PARAMETER - default value = TRUE
					You can specify if the change should be stored in the Paramterisation History of PVSS
*/
fwAlertConfig_setMany(dyn_string dpes,
					dyn_int alertConfigType,
					dyn_dyn_string alertTexts,
					dyn_dyn_float alertLimits,
					dyn_dyn_string alertClasses,
					dyn_dyn_string summaryDpeList,
					dyn_string alertPanel,
					dyn_dyn_string alertPanelParameters,
					dyn_string alertHelp,
					dyn_string &exceptionInfo,
					bool modifyOnly = FALSE,
					bool fallBackToSet = FALSE,
					string addDpeInSummary = "",
					bool storeInParamHistory = TRUE)
{
	bool relativeSummaryPath;
	int i, j, k, length, ranges, configOptions, numberOfSettings, minimumPriority = 0;
	dyn_string localException, attributes, tempAttributes, configsToDeactivate, dpesWithAlerts, dpesWithAnalogAlerts, summaryDpes;
	dyn_mixed values, tempValues;
	dyn_int alertHandlingTypes, currentConfigTypes, summaryConfigTypes; 
	dyn_float hysteresisLimits;   
	dyn_int hysteresisType, currentNumberOfRanges, numberOfRanges;    
	dyn_bool includeLimits, alertActive, alertActiveStates, tempAlertActiveStates; 
	dyn_errClass errors;

	length = dynlen(dpes);

	_fwConfigs_getConfigTypeAttribute(dpes, fwConfigs_PVSS_ALERT_HDL, currentConfigTypes, exceptionInfo);
	for(i=1; i<=length; i++)
	{
		if(currentConfigTypes[i] != DPCONFIG_NONE)
			dynAppend(dpesWithAlerts, dpes[i]);
		if(currentConfigTypes[i] == DPCONFIG_ALERT_NONBINARYSIGNAL)
			dynAppend(dpesWithAnalogAlerts, dpes[i]);
	}

	_fwConfigs_getConfigTypeAttribute(dpesWithAlerts, fwConfigs_PVSS_ALERT_HDL, alertActiveStates, exceptionInfo, ".._active");

	if(modifyOnly)
		_fwConfigs_getConfigTypeAttribute(dpesWithAlerts, fwConfigs_PVSS_ALERT_HDL, currentNumberOfRanges, exceptionInfo, ".._num_ranges");

	j = 1;
	k = 1;
	for(i=1; i<=length; i++)
	{
		if(currentConfigTypes[i] != DPCONFIG_NONE)
		{
			alertActive[i] = alertActiveStates[j];
			j++; 
			if(alertActive[i])
				dynAppend(configsToDeactivate, dpes[i]);
		}
		else
			alertActive[i] = FALSE;

		if(modifyOnly && (currentConfigTypes[i] == DPCONFIG_ALERT_NONBINARYSIGNAL))
		{
			numberOfRanges[i] = currentNumberOfRanges[k];
			k++; 
		}
		else
			numberOfRanges[i] = 0;
	}	
		
	fwAlertConfig_deactivateMultiple(configsToDeactivate, exceptionInfo, TRUE, FALSE, FALSE);

	dynClear(attributes);
	dynClear(values);
		
	_fwAlertConfig_checkAlertClasses(alertClasses, exceptionInfo);

	for(i=1; i<=length; i++)
	{
    int threshold;    
    
		_fwConfigs_getConfigOptionsForDpe(dpes[i], fwConfigs_PVSS_ALERT_HDL, configOptions, localException);
		if(dynlen(localException)>0)
		{
			//store exception and then skip to next dpe
			dynAppend(exceptionInfo, localException);
			dynClear(localException);
			continue;
		}

		dynClear(tempAttributes);
		dynClear(tempValues);

		switch(configOptions)
		{
			case fwConfigs_ANALOG_OPTIONS:
				if(alertConfigType[i] != DPCONFIG_ALERT_NONBINARYSIGNAL)
				{
					fwException_raise(exceptionInfo, "ERROR",
											"fwAlertConfig_setMany: Only analog alerts are supported by the given data point element", "");
					break;
				}
				
				if(dynlen(alertTexts[i]) == 0 ||
					dynlen(alertLimits[i]) == 0 ||
					dynlen(alertClasses[i]) == 0)
				{
			  	fwException_raise(exceptionInfo, "ERROR",
			  								"fwAlertConfig_setMany: You must provide alert texts, classes and limits for an analog alert", "");
					break;
				}
    
				ranges = dynlen(alertLimits[i]) + 1;    
			 	_fwAlertConfig_generateExtraAnalogConfig(ranges, alertLimits[i], alertHandlingTypes, hysteresisLimits, hysteresisType, includeLimits, exceptionInfo);
				_fwAlertConfig_prepareAnalog(dpes[i], currentConfigTypes[i], numberOfRanges[i],
										alertHandlingTypes, alertLimits[i], alertTexts[i], alertClasses[i],
										includeLimits, minimumPriority, alertPanel[i], alertPanelParameters[i], alertHelp[i],
										hysteresisType, hysteresisLimits, tempAttributes, tempValues,
										localException, modifyOnly, fallBackToSet);
				break;
			case fwConfigs_BINARY_OPTIONS:
				if(alertConfigType[i] != DPCONFIG_ALERT_BINARYSIGNAL)
				{
			  	fwException_raise(exceptionInfo, "ERROR",
			  								"fwAlertConfig_setMany: Only binary alerts are supported by the given data point element", "");
					break;
				}
	
				if(dynlen(alertTexts[i]) != 2 ||
					dynlen(alertClasses[i]) != 2)
				{
			  	fwException_raise(exceptionInfo, "ERROR",
			  								"fwAlertConfig_setMany: You must provide 2 alert classes (including the good range) and 2 alert texts for a binary alert", "");
					break;
				}
	
				_fwAlertConfig_prepareDigital(dpes[i], currentConfigTypes[i], alertTexts[i], alertClasses[i], minimumPriority,
										alertPanel[i], alertPanelParameters[i], alertHelp[i], tempAttributes, tempValues,
										localException, modifyOnly, fallBackToSet); 			
				break;
			case fwConfigs_GENERAL_OPTIONS:
				if(alertConfigType[i] != DPCONFIG_SUM_ALERT)
				{
			  	fwException_raise(exceptionInfo, "ERROR",
			  								"fwAlertConfig_setMany: Only summary alerts are supported by the given data point element", "");
					break;
				}
				
				if(dynlen(alertTexts[i]) != 2)
				{
			  	fwException_raise(exceptionInfo, "ERROR",
			  								"fwAlertConfig_setMany: You must provide 2 alert texts for a summary alert", "");
					break;
				}

				if(dynlen(summaryDpeList[i]) > 1)
				{
					if((strpos(summaryDpeList[i][1], "*") >= 0) || (strpos(summaryDpeList[i][1], "?") >= 0))
					{
			  			fwException_raise(exceptionInfo, "ERROR",
			  					"fwAlertConfig_setMany: You can not specify at DP list and DP pattern in the same summary alert", "");
						break;
					}
				}

      if(dynlen(alertLimits) == 0)
        threshold = 0;
      else if(dynlen(alertLimits[i]) == 0)
        threshold = 0;
      else
        threshold = alertLimits[i][1];
        
      _fwAlertConfig_prepareSummary(dpes[i], currentConfigTypes[i], threshold, alertTexts[i], summaryDpeList[i], minimumPriority,
								alertPanel[i], alertPanelParameters[i], alertHelp[i], tempAttributes, tempValues,
								localException, modifyOnly, fallBackToSet); 			
				break;
			default:
		  	fwException_raise(exceptionInfo, "ERROR",
		  								"fwAlertConfig_setMany: Data point element type is not supported", "");
				break;
		}
		
		if(dynlen(localException) > 0)
		{
			dynAppend(exceptionInfo, localException);
			dynClear(localException);
			continue;
		}

		numberOfSettings = dynAppend(attributes, tempAttributes);
		dynAppend(values, tempValues);
				
		if((numberOfSettings > fwConfigs_OPTIMUM_DP_SET_SIZE) || (i == length))
		{
//DebugN("Setting...", storeInParamHistory, attributes, values);
			if(storeInParamHistory)
				dpSetWait(attributes, values);
			else
				dpSetTimedWait(0, attributes, values);

			errors = getLastError(); 
    			if(dynlen(errors) > 0)
    			{ 
	 			throwError(errors);
	 			fwException_raise(exceptionInfo, "ERROR", "fwAlertConfig_setMany: Could not configure some alert configs", "");
			}
			
			dynClear(attributes);
			dynClear(values);
		}
	}

	fwAlertConfig_activateMultiple(configsToDeactivate, exceptionInfo, FALSE, FALSE);

	if(dynlen(exceptionInfo)>0)
		return;
	else if(addDpeInSummary != "")
	{
		relativeSummaryPath = !dpExists(addDpeInSummary);
		if(!relativeSummaryPath)
		{
			for(i=1; i<=length; i++)
				summaryDpes[i] = addDpeInSummary;	
		}
		else
		{
			for(i=1; i<=length; i++)
				summaryDpes[i] = dpSubStr(dpes[i], DPSUB_SYS_DP) + addDpeInSummary;
		}

		_fwConfigs_getConfigTypeAttribute(summaryDpes, fwConfigs_PVSS_ALERT_HDL, summaryConfigTypes, exceptionInfo);
		errors = getLastError(); 
    		if(dynlen(errors) > 0)
    		{ 
	 			fwException_raise(exceptionInfo, "ERROR", "fwAlertConfig_setMany: Could not read all summary alerts.", "");
				return;
		}

		for(i=1; i<=length; i++)
		{
			if(summaryConfigTypes[i] == DPCONFIG_SUM_ALERT)
				fwAlertConfig_addDpInAlertSummary(summaryDpes[i], dpSubStr(dpes[i], DPSUB_SYS_DP_EL), exceptionInfo, FALSE, storeInParamHistory);
			else if(summaryConfigTypes[i] != DPCONFIG_NONE)   
	 			fwException_raise(exceptionInfo, "ERROR", "fwAlertConfig_setMany: The alert on \"" + summaryDpes[i] + "\" is not a summary alert as expected.", "");

//DebugN(summaryConfigTypes[i], summaryDpes[i], dpes[i], exceptionInfo);
		}
	}
}


/** Sets the alert configuration on a given dpe.
This function can handle digital, analog and summary alerts

@par Constraints
	Can only get summary alerts of type dp list (not dp pattern)

	For digital alerts: The length of the alertTexts and alertClasses dyn_strings must both be 2
	For analog alerts: 	The length of the alertTexts and alertClasses dyn_strings must be equal
				 		The length of the alertLimits dyn_float must be one less than the length of alertTexts
	For summary alerts: The length of the alertTexts dyn_string must be 2

@par Usage
	Public

@par PVSS managers
	VISION, CTRL

@param dpe							Data point element
@param alertConfigType	Type of alert to set:
													DPCONFIG_ALERT_BINARYSIGNAL for digital alert handling
													DPCONFIG_ALERT_NONBINARYSIGNAL for analog alert handling
													DPCONFIG_SUM_ALERT for summary alert handling
@param alertTexts				Alert texts are passed here for all types of alert
@param alertLimits			Alert limits are passed here for analog alerts (otherwise ignored)
@param alertClasses			Alert classes are passed here for digital and analog alerts  (otherwise ignored)
@param summaryDpeList		If Summary alert, the dpeList is passed here (otherwise ignored).  
                                      If you want to specify a DP pattern, then this should entered as the first item in this list.
@param alertPanel				Panel to call from the alert screen
@param alertPanelParameters		Parameters to pass to the given alertPanel
@param alertHelp				Help text or path to help file    
@param exceptionInfo		Details of any exceptions are returned here   
@param modifyOnly				Optional parameter - Default value FALSE.  Set to TRUE to modify alert without setting "type" attributes.
						This is much quicker, but the alert config must already exist, be an analog alert and have the same number of ranges as you want.
@param fallBackToSet			Optional parameter - Default value FALSE.  Used in combination with modifyOnly.
						If modifyOnly = TRUE and fallBackToSet = FALSE, then if the alert config is not compatible an exception is raised. 
						If modifyOnly = TRUE and fallBackToSet = TRUE, then if the alert config is not compatible, modifyOnly is treated as if it was FALSE. 
@param addDpeInSummary 			Optional parameter - Default value "".  Used to add the new alert in a summary alert.
						Default value "" means do not add the new alert into a summary.
						You can specify either an absolute DPE name, or a relative path from the DP to which the new alert was saved.
							i.e.
							addDpeInSummary = "." will add the new alert on dpes[i] to the summary on the root of the datapoint to which dpes[i] belongs. 
							addDpeInSummary = "MyDp.summaries" will add the new alert on dpes[i] to the summary on the dpe called "MyDp.summaries". 
						Note: The summary alarms must already exist.  If they does not exist, it WILL NOT be created.
@param storeInParamHistory		OPTIONAL PARAMETER - default value = TRUE
					You can specify if the change should be stored in the Paramterisation History of PVSS
*/
fwAlertConfig_set(string dpe,
					int alertConfigType,
					dyn_string alertTexts,
					dyn_float alertLimits,
					dyn_string alertClasses,
					dyn_string summaryDpeList,
					string alertPanel,
					dyn_string alertPanelParameters,
					string alertHelp,
					dyn_string &exceptionInfo,
					bool modifyOnly = FALSE,
					bool fallBackToSet = FALSE,
					string addDpeInSummary = "",
					bool storeInParamHistory = TRUE)
{
	int i, length;
	dyn_int diAlertConfigType;
	dyn_string dsAlertPanel, dsAlertHelp;
	dyn_dyn_float ddfAlertLimits;
	dyn_dyn_string ddsAlertTexts, ddsAlertClasses, ddsSummaryDpeList, ddsAlertPanelParameters;
	
	diAlertConfigType[1] = alertConfigType;
	ddsAlertTexts[1] = alertTexts;
	ddfAlertLimits[1] = alertLimits;
	ddsAlertClasses[1] = alertClasses;
	ddsSummaryDpeList[1] = summaryDpeList;
	dsAlertPanel[1] = alertPanel;
	ddsAlertPanelParameters[1] = alertPanelParameters;
	dsAlertHelp[1] = alertHelp;

	fwAlertConfig_setMany(makeDynString(dpe), diAlertConfigType, ddsAlertTexts, ddfAlertLimits, ddsAlertClasses, ddsSummaryDpeList,
												dsAlertPanel, ddsAlertPanelParameters, dsAlertHelp, exceptionInfo,
												modifyOnly, fallBackToSet, addDpeInSummary, storeInParamHistory);
}


/** Activates the alert handling on the given data point element.

@par Constraints
	Only works on dpes with alert handling already configured

@par Usage
	Public

@par PVSS managers
	VISION, CTRL

@param dpe						Data point element to act on
@param exceptionInfo	Details of any exceptions are returned here   
@param checkIfExists	Optional parameter (Default value - TRUE)
													TRUE - check if alert config exists (avoids errors if it doesn't)   
													FALSE - do not check if alert exists (may cause errors if it does not exist)
@param storeInParamHistory 	Optional parameter (Default value - FALSE)
													TRUE - writing to active bit is stored in alert history   
													FALSE - writing to active bit is not stored in alert history   
*/
fwAlertConfig_activate(string dpe, dyn_string &exceptionInfo, bool checkIfExists = TRUE, bool storeInParamHistory = FALSE)
{
	_fwAlertConfig_activateOrDeactivate(makeDynString(dpe), TRUE, exceptionInfo, FALSE, checkIfExists, storeInParamHistory);
}


/** Activates the alert handling on the given list of data point elements.

@par Constraints
	Only works on dpes with alert handling already configured

@par Usage
	Public

@par PVSS managers
	VISION, CTRL

@param dpes						The list of data point elements to act on
@param exceptionInfo	Details of any exceptions are returned here   
@param checkIfExists	Optional parameter (Default value - TRUE)
													TRUE - check if alert config exists (avoids errors if it doesn't)   
													FALSE - do not check if alert exists (may cause errors if it does not exist)
@param storeInParamHistory 	Optional parameter (Default value - FALSE)
													TRUE - writing to active bit is stored in alert history   
													FALSE - writing to active bit is not stored in alert history   
*/
fwAlertConfig_activateMultiple(dyn_string dpes, dyn_string &exceptionInfo, bool checkIfExists = TRUE, bool storeInParamHistory = FALSE)
{
	_fwAlertConfig_activateOrDeactivate(dpes, TRUE, exceptionInfo, FALSE, checkIfExists, storeInParamHistory);
}


/** Deactivates the alert handling on the given data point element.

@par Constraints
	Only works on dpes with alert handling already configured

@par Usage
	Public

@par PVSS managers
	VISION, CTRL

@param dpe						Data point element to act on
@param exceptionInfo	Details of any exceptions are returned here   
@param acknowledge		Optional parameter (Default value - TRUE)
												TRUE for acknowledge alert when deactivating   
												FALSE to leave alert unacknowledge when deactivated
@param checkIfExists	Optional parameter (Default value - TRUE)
													TRUE - check if alert config exists (avoids errors if it doesn't)   
													FALSE - do not check if alert exists (may cause errors if it does not exist)
@param storeInParamHistory 	Optional parameter (Default value - FALSE)
													TRUE - writing to active bit is stored in alert history   
													FALSE - writing to active bit is not stored in alert history   
*/
fwAlertConfig_deactivate(string dpe, dyn_string &exceptionInfo, bool acknowledge = TRUE, bool checkIfExists = TRUE, bool storeInParamHistory = FALSE)
{
	_fwAlertConfig_activateOrDeactivate(makeDynString(dpe), FALSE, exceptionInfo, acknowledge, checkIfExists, storeInParamHistory);
}


/** Deactivates the alert handling on the given list of data point elements.

@par Constraints
	Only works on dpes with alert handling already configured

@par Usage
	Public

@par PVSS managers
	VISION, CTRL

@param dpes						List of data point elements to act on
@param exceptionInfo	Details of any exceptions are returned here   
@param acknowledge		Optional parameter (Default value - TRUE)
												TRUE for acknowledge alert when deactivating   
												FALSE to leave alert unacknowledge when deactivated
@param checkIfExists	Optional parameter (Default value - TRUE)
													TRUE - check if alert config exists (avoids errors if it doesn't)   
													FALSE - do not check if alert exists (may cause errors if it does not exist)
@param storeInParamHistory 	Optional parameter (Default value - FALSE)
													TRUE - writing to active bit is stored in alert history   
													FALSE - writing to active bit is not stored in alert history   
*/
fwAlertConfig_deactivateMultiple(dyn_string dpes, dyn_string &exceptionInfo, bool acknowledge = TRUE, bool checkIfExists = TRUE, bool storeInParamHistory = FALSE)
{
	_fwAlertConfig_activateOrDeactivate(dpes, FALSE, exceptionInfo, acknowledge, checkIfExists, storeInParamHistory);
}

/** Activates or deactivates the alert handling on the given data point element.

@par Constraints
	If a dpe does not have alert handling defined, the function returns without any exception.
		(The dpe has no active alert handling and is also available to have an alert handling config written to it)

@par Usage
	Internal

@par PVSS managers
	VISION, CTRL

@param dpes						The data point elements to act on
@param activate				Set to TRUE to activate alert
											Set to FALSE to deactivate alert
@param exceptionInfo	Details of any exceptions are returned here   
@param acknowledgeOnDeactivate	Optional parameter (Default value - TRUE) only used when activate is FALSE
																	TRUE for acknowledge alert when deactivating   
																	FALSE to leave alert unacknowledge when deactivated
@param checkIfExists						Optional parameter (Default value - TRUE)
																	TRUE - check if alert config exists (avoids errors if it doesn't)   
																	FALSE - do not check if alert exists (may cause errors if it does not exist)
@param storeInParamHistory 	Optional parameter (Default value - FALSE)
													TRUE - writing to active bit is stored in alert history   
													FALSE - writing to active bit is not stored in alert history   
*/
_fwAlertConfig_activateOrDeactivate(dyn_string dpes, bool activate, dyn_string &exceptionInfo, bool acknowledgeOnDeactivate = TRUE, bool checkIfExists = TRUE, bool storeInParamHistory = FALSE)
{
	bool batchOk;
        dyn_bool ackPossible;
	int i, j, length, attributeCount, maxTries = 2;
	dyn_int alarmTypes;
	dyn_mixed acknowledgeValues, activeValues;
	dyn_string acknowledgeDpes, activeDpes;
	dyn_errClass error;
	
	length = dynlen(dpes);
	if(checkIfExists)
	{
		_fwConfigs_getConfigTypeAttribute(dpes, fwConfigs_PVSS_ALERT_HDL, alarmTypes, exceptionInfo);
		for(j=length; j>0; j--)
		{
			if(alarmTypes[j] == DPCONFIG_NONE)
				dynRemove(dpes, j);
		}
	}
	
        //get new length
	length = dynlen(dpes);
	if(!activate)
	{
		_fwConfigs_getConfigTypeAttribute(dpes, fwConfigs_PVSS_ALERT_HDL, ackPossible, exceptionInfo, ".._ack_possible");
		for(j=1; j<=length; j++)
		{
			if(acknowledgeOnDeactivate && ackPossible[j])
			{
				dynAppend(acknowledgeDpes, dpes[j] + ":" + fwConfigs_PVSS_ALERT_HDL + ".._ack");
				dynAppend(acknowledgeValues, DPATTR_ACKTYPE_SINGLE);
			}					

			attributeCount = dynAppend(activeDpes, dpes[j] + ":" + fwConfigs_PVSS_ALERT_HDL + ".._active");
			dynAppend(activeValues, FALSE);

			if((attributeCount > fwConfigs_OPTIMUM_DP_SET_SIZE) || (j == length))
			{
				//try multiple times in case value change triggers alert between ack and deactivate
				//if this happens more than "maxTries" then bad luck
				for(i=1; i<=maxTries; i++)
				{
//DebugN("ATTEMPT: " + i);
					batchOk = TRUE;
					
					if(acknowledgeOnDeactivate)
					{
//DebugN("ACK'ING", storeInParamHistory);
						if(storeInParamHistory)
							dpSetWait(acknowledgeDpes, acknowledgeValues);
						else
							dpSetTimedWait(0, acknowledgeDpes, acknowledgeValues);

						error = getLastError();
						if(dynlen(error) > 0)
						{
							batchOk = FALSE;
							if(i==maxTries)
								fwException_raise(exceptionInfo, "ERROR", "_fwAlertConfig_activateOrDeactivate(): Could not acknowledge some of the alerts", "");
							throwError(error);
						}
					}					

					if(batchOk)
					{
						if(storeInParamHistory)
							dpSetWait(activeDpes, activeValues);
						else
							dpSetTimedWait(0, activeDpes, activeValues);

						error = getLastError();
						if(dynlen(error) > 0)
						{
							batchOk = FALSE;
							if(i==maxTries)
								fwException_raise(exceptionInfo, "ERROR", "_fwAlertConfig_activateOrDeactivate(): Could not deactivate some of the alerts", "");
							throwError(error);
						}
					}

					if(batchOk)
					{
						dynClear(acknowledgeDpes);
						dynClear(acknowledgeValues);
						dynClear(activeDpes);
						dynClear(activeValues);
						i+=maxTries;  //action was successful so make sure loop does not run again
					}
				}
			}
		}
	}
	else
	{
		for(j=1; j<=length; j++)
		{
			attributeCount = dynAppend(activeDpes, dpes[j] + ":" + fwConfigs_PVSS_ALERT_HDL + ".._active");
			dynAppend(activeValues, TRUE);

			if((attributeCount > fwConfigs_OPTIMUM_DP_SET_SIZE) || (j == length))
			{
				if(storeInParamHistory)
					dpSetWait(activeDpes, activeValues);
				else
					dpSetTimedWait(0, activeDpes, activeValues);

				error = getLastError();
				if(dynlen(error) > 0)
				{
					throwError(error);
					fwException_raise(exceptionInfo, "ERROR", "_fwAlertConfig_activateOrDeactivate(): Could not activate some of the alerts", "");
				}

				dynClear(activeDpes);
				dynClear(activeValues);
			}
		}
	}
}


/** Acknowledges the alert handling on the given data point element.
This function uses the DPATTR_ACKTYPE_SINGLE to acknowledge the alert.

@par Constraints
	Only works on dpes with alert handling already configured

@par Usage
	Public

@par PVSS managers
	VISION, CTRL

@param dpe						Data point element to act on
@param exceptionInfo	Details of any exceptions are returned here   
@param checkIfExists						Optional parameter (Default value - TRUE)
																	TRUE - check if alert config exists (avoids errors if it doesn't)   
																	FALSE - do not check if alert exists (may cause errors if it does not exist)
@param storeInParamHistory	OPTIONAL PARAMETER - default value = TRUE
					You can specify if the change should be stored in the Paramterisation History of PVSS
*/
fwAlertConfig_acknowledge(string dpe, dyn_string &exceptionInfo, bool checkIfExists = TRUE, bool storeInParamHistory = FALSE)
{
	fwAlertConfig_acknowledgeMany(makeDynString(dpe), exceptionInfo, checkIfExists, storeInParamHistory);
}


/** Acknowledges the alert handling on the given data point elements.
If more than one dpe is specified, the DPATTR_ACKTYPE_MULTIPLE value is used to acknowledge, indicating that the alerts were
acknowledged as part of a group acknowledge action.  Otherwise the DPATTR_ACKTYPE_SINGLE value is written.

@par Constraints
	Only works on dpes with alert handling already configured

@par Usage
	Public

@par PVSS managers
	VISION, CTRL

@param dpes						the list of data point elements to act on
@param exceptionInfo	Details of any exceptions are returned here   
@param checkIfExists						Optional parameter (Default value - TRUE)
																	TRUE - only acknowledge alerts which exist (avoids errors if it doesn't)   
																	FALSE - do not check if alert exists (cause exceptions to be raised if they do not exist)
@param storeInParamHistory	OPTIONAL PARAMETER - default value = TRUE
					You can specify if the change should be stored in the Paramterisation History of PVSS
*/
fwAlertConfig_acknowledgeMany(dyn_string dpes, dyn_string &exceptionInfo, bool checkIfExists = TRUE, bool storeInParamHistory = FALSE)
{
	int i, length, acknowledgeValue;
	dyn_int diAcknowledgeValue;
	dyn_string existingDpes, dpesWithAlerts, dpesToAcknowledge, localException;
	dyn_mixed values;

	length = dynlen(dpes);

	if(length == 1)
		acknowledgeValue = DPATTR_ACKTYPE_SINGLE;
	else
		acknowledgeValue = DPATTR_ACKTYPE_MULTIPLE;

	for(i=1; i<=length; i++)
	{
		if(dpExists(dpes[i]))
			dynAppend(existingDpes, dpes[i]);
		else if(!checkIfExists)
			fwException_raise(exceptionInfo, "ERROR", "fwAlertConfig_acknowledgeMany(): The data point element does not exist: \"" + dpes[i] + "\"", "");
	}
	
	_fwConfigs_getConfigTypeAttribute(existingDpes, fwConfigs_PVSS_ALERT_HDL, values, exceptionInfo);
	length = dynlen(existingDpes);
	for(i=1; i<=length; i++)
	{
		if(values[i] != DPCONFIG_NONE)
			dynAppend(dpesWithAlerts, existingDpes[i]);
		else if(!checkIfExists)
			fwException_raise(exceptionInfo, "ERROR", "fwAlertConfig_acknowledgeMany(): No alert config exists on the data point element: \"" + dpes[i] + "\"", "");
	}
		
	_fwConfigs_getConfigTypeAttribute(dpesWithAlerts, fwConfigs_PVSS_ALERT_HDL, values, exceptionInfo, ".._ack_possible");
	length = dynlen(dpesWithAlerts);
	for(i=1; i<=length; i++)
	{
		if(values[i])
		{
			dynAppend(dpesToAcknowledge, dpesWithAlerts[i]);
			dynAppend(diAcknowledgeValue, acknowledgeValue);
		}
	}

	_fwConfigs_setConfigTypeAttribute(dpesToAcknowledge, fwConfigs_PVSS_ALERT_HDL, diAcknowledgeValue, localException, ".._ack", storeInParamHistory?-1:0);
	if(dynlen(localException) > 0)
		fwException_raise(exceptionInfo, "ERROR", "fwAlertConfig_acknowledgeMany(): Could not acknowledge all the alerts.","");
}


/** Gets the alert limits for the currently configured alert ranges on the given data point element.

@par Constraints
	Only works on data points that have an analog alert handling set up.

@par Usage
	Public

@par PVSS managers
	VISION, CTRL

@param dpe						Data point element to read limits from
@param limitNumbers		The numbers of the limits are returned here
												This is always a list of integers starting at 1 up to the number of (ranges - 1)
												e.g. For a 5 range alert the value returned will be {1,2,3,4}
@param limitValues		The values of the limits are returned here
											The limits are always returned is ascending order 
@param exceptionInfo	Details of any exceptions are returned here   
*/
fwAlertConfig_getLimits(string dpe, dyn_int &limitNumbers, dyn_float &limitValues, dyn_string &exceptionInfo)
{
	int i, alertType, alertRanges;
	dyn_string attributes;

	limitNumbers = makeDynInt();
	
	dpGet(dpe + ":_alert_hdl.._type", alertType);
	switch(alertType)
	{
		case DPCONFIG_ALERT_NONBINARYSIGNAL:
			dpGet(dpe + ":_alert_hdl.._num_ranges", alertRanges);
			for(i=1; i<=(alertRanges-1); i++)
			{
				dynAppend(attributes, dpe + ":_alert_hdl." + i + "._u_limit");
				dynAppend(limitNumbers, i);
			}
			
                        if(dynlen(attributes) > 0)
				dpGet(attributes, limitValues);
			break;
		case DPCONFIG_NONE:
			fwException_raise(exceptionInfo, "ERROR", "fwAlertConfig_getLimits(): No alert config exists on this dpe: \"" + dpe + "\"", "");
			break;
		default:
			fwException_raise(exceptionInfo, "ERROR", "fwAlertConfig_getLimits(): The alert config on \"" + dpe + "\" is not of analog alert type.  No limits available.", "");
			break;
	}
}


/** Sets the alert limits for the currently configured alert ranges on the given data point element.
The values in the same position in limitNumbers and limitValues form a pair of values.
The pair consists of the limit number to act on and limit value to set.

Example usage:  limitNumbers = {3,4,2}
				limitValues = {30,50,10}
				This will set the limit between Range 2 and 3 to 10
				This will set the limit between Range 3 and 4 to 30
				This will set the limit between Range 4 and 5 to 50

NOTE: Not all the limits need to be specified in the input parameters
NOTE: Values in limitNumbers must be between 1 and (number of ranges - 1)

@par Constraints
	Only works on data points that have an analog alert handling set up.
				This function can not change the number of ranges defined in the alert config.
				If only some limits are specified, the new limits must be consistent with the old values that will not be modified

@par Usage
	Public

@par PVSS managers
	VISION, CTRL

@param dpe						Data point element to set the limits to
@param limitNumbers		The numbers of the limits to be modified are passed here
@param limitValues		The values of the limits to be modified are passed here
											The values in this list correspond to the limit numbers given in limitNumbers
@param exceptionInfo	Details of any exceptions are returned here   
@param checkBeforeSetting	OPTIONAL PARAMETER - default value FALSE
					If TRUE, the new limit values are compared with the existing limits to check that the final configuration will be consistent
					(i.e. all the range limits are in ascending order with no duplicates).
					In case of inconsistencies, an exception will be raised.
					If FALSE, the new limits are not checked and an error will appear in the log when the dpSetWait is performed and an exception will be raised.
@param storeInParamHistory	OPTIONAL PARAMETER - default value = TRUE
					You can specify if the change should be stored in the Paramterisation History of PVSS
*/
fwAlertConfig_setLimits(string dpe, dyn_int limitNumbers, dyn_float limitValues, dyn_string &exceptionInfo, bool checkBeforeSetting = FALSE, bool storeInParamHistory = TRUE)
{
	bool isAlarmActive, limitsOk;
	int i, length, alarmType, alertRanges;
	float previousValue;
	dyn_int currentLimitNumbers;
	dyn_string dpesToSet;
	dyn_float valuesToSet, currentLimitValues;
	dyn_errClass error;
	
	dpGet(dpe + ":_alert_hdl.._type", alarmType);
	switch(alarmType)
	{
		case DPCONFIG_NONE:
			fwException_raise(exceptionInfo, "ERROR", "fwAlertConfig_setLimits(): No alert config exists on this data point element.", "");
			break;
		case DPCONFIG_ALERT_NONBINARYSIGNAL:
			break;
		default:
			fwException_raise(exceptionInfo, "ERROR", "fwAlertConfig_setLimits(): The alert config is not of analog alert type.  No limits can be set.", "");
			break;
	}
	if(dynlen(exceptionInfo) > 0)
		return;
	
	//check that each range was only specified once in input
	if((dynUnique(limitNumbers) != dynlen(limitValues)) || (dynlen(limitNumbers) <= 0))
	{
		fwException_raise(exceptionInfo,"ERROR","fwAlertConfig_setLimits(): New limit settings are not valid","");
		return;
	}

	if(checkBeforeSetting)
	{
		//get current range info for reference
		fwAlertConfig_getLimits(dpe, currentLimitNumbers, currentLimitValues, exceptionInfo);
		if(dynlen(exceptionInfo) > 0)
			return;
	
		alertRanges = dynMax(currentLimitNumbers);
	}
	else //get only number of ranges
		dpGet(dpe + ":_alert_hdl.._num_ranges", alertRanges);

	//check input range numbers are greater than 0 and <= current number of ranges
	if((dynMin(limitNumbers) <= 0) || (dynMax(limitNumbers) > alertRanges))
	{
		fwException_raise(exceptionInfo,"ERROR","fwAlertConfig_setLimits(): One or more of the given range numbers is not valid.","");
		return;
	}

	if(checkBeforeSetting)
	{
		//compare input with current settings
		for(i=1; i <= dynlen(limitNumbers); i++)
		{
			//if new limit value, store new value for comparison
			if(currentLimitValues[limitNumbers[i]] != limitValues[i])
				currentLimitValues[limitNumbers[i]] = limitValues[i];
			//else remove values from list of changes
			else
			{
				dynRemove(limitNumbers, i);
				dynRemove(limitValues, i);
				i--;
			}
		}
			
		//check that new limit settings are consistent with current settings and that they are are incremental order
		_fwAlertConfig_checkLimits(currentLimitValues, limitsOk, exceptionInfo);
		if(!limitsOk)
			return;
	}
	
	//build lists of attributes and values to set (only setting limits that need to be changed)
	length = dynlen(limitNumbers);
	for(i=1; i <= length; i++)
	{
		dynAppend(dpesToSet, dpe + ":_alert_hdl." + limitNumbers[i] +"._u_limit");
		dynAppend(dpesToSet, dpe + ":_alert_hdl." + (limitNumbers[i] + 1) +"._l_limit");
		dynAppend(valuesToSet, limitValues[i]);
		dynAppend(valuesToSet, limitValues[i]);
	}

	//deactivate alert if it is active
	dpGet(dpe + ":_alert_hdl.._active", isAlarmActive);
	if(isAlarmActive)
		fwAlertConfig_deactivate(dpe, exceptionInfo, TRUE, FALSE, FALSE);

	if(dynlen(exceptionInfo) > 0)
		return;

//DebugN(dpesToSet,valuesToSet);		
	if(storeInParamHistory)
		dpSetWait(dpesToSet, valuesToSet);
	else
		dpSetTimedWait(0, dpesToSet, valuesToSet);

	error = getLastError();
	if(dynlen(error) > 0) 
	{
		throwError(error);
		fwException_raise(exceptionInfo, "ERROR", "fwAlertConfig_setLimits(): Could not set the new limit values.", "");
		return;
	}

	//reactivate alert if it was active before action
	if(isAlarmActive)
		fwAlertConfig_activate(dpe, exceptionInfo, FALSE, FALSE);
}

/** This function check thats the given alert range limits are valid for setting to the alert config.
This means that they should be in ascending order and no limit value should be duplicated.

@par Constraints
	None

@par Usage
	Internal

@par PVSS managers
	VISION, CTRL

@param limitValues		The list of range limit values to be checked
@param limitsOk				Returns TRUE if limits are OK to be set.
											Returns FALSE if limits are bad.
@param exceptionInfo	Details of any exceptions are returned here   
*/
_fwAlertConfig_checkLimits(dyn_float limitValues, bool &limitsOk, dyn_string &exceptionInfo)
{
	int i, length;
	float previousValue;

	length = dynlen(limitValues);
	previousValue = limitValues[1];
	for(i=2; i <= length; i++)
	{
		if(previousValue >= limitValues[i])
		{
			limitsOk = FALSE;
			fwException_raise(exceptionInfo,"ERROR","_fwAlertConfig_checkLimits(): Limit values are not consistent.","");
			return;
		}
		else
			previousValue = limitValues[i];
	}

	limitsOk = TRUE;
}

/** This function checks that the given list of alert classes is appropriate for setting to an alert config.
The priority of each alert class is found and then a check is performed to check that the priorities are in a valid order.
The check is performed as many times as there are systems specified, as priorities may vary on the same class in different systems.
Valid orders are:
	1) Priorities of alert classes in descending order down to 0 (good range) - e.g. 60, 40, 0
	2) Priorities of alert classes in ascending order up from 0 (good range) - e.g. 0, 20, 40, 60 ,80
	3) Priorities of alert classes first descending down to 0 (good range) then ascending after then - e.g. 60, 40, 0, 40, 80

@par Constraints
	This function does not actually check that a good range is passed. It just checks the ordering of priorities.
	It is your responsibility to make sure that one alert class in the list passed to this function is empty (good range).

@par Usage
	Internal

@par PVSS managers
	VISION, CTRL

@param systemsToCheck The list of systems to check the classes on.  An empty list means local system only.
@param alertClasses		The list of alert classes in the order you wish to write them to the alert config.
@param classesOk			Returns TRUE if classes are OK to be set.
											Returns FALSE if classes are bad.
@param exceptionInfo	Details of any exceptions are returned here  
@param useAlternativeClassPriorities	OPTIONAL PARAMETER - default value: FALSE
										If TRUE, the function will try to use similar alert classes of different priorities 
										(fwWarningAck => fwWarningAck_41) in order to resolve problems with the same class being 
										used twice in neighbouring alert ranges.
										If FALSE, no modification is made to the alertClasses as passed to the function. Only the 
										checking of the priorities is carried out - no automatic attempt to correct.
*/
_fwAlertConfig_checkClassPriorities(dyn_string systemsToCheck, dyn_string &alertClasses, bool &classesOk, dyn_string &exceptionInfo, bool useAlternativeClassPriorities = FALSE)
{
        bool classCheck;
	int i, j, k, numberOfRanges, numberOfSystems, goodRange;
        dyn_int startPoints, directions, endPoints;
        dyn_string localAlertClasses;

        localAlertClasses = alertClasses;
        
        //if no system specified, use local
	if(dynlen(systemsToCheck) == 0)
		systemsToCheck[1] = getSystemName();
	
        //while systems list contains empty entries, replace each empty entry with local system name
	while(dynContains(systemsToCheck, ""))
	{
		pos = dynContains(systemsToCheck, "");
		systemsToCheck[pos] = getSystemName();
	}
	
        //find location of good range
        goodRange = dynContains(localAlertClasses, "");
        if(goodRange <= 0)
	{		
		fwException_raise(exceptionInfo,"ERROR","_fwAlertConfig_checkClassPriorities(): No good range was found.","");
		return;
	}
//DebugN(alertClasses);

        dynRemove(localAlertClasses, goodRange);
        if(dynContains(localAlertClasses, "") > 0)
	{		
		fwException_raise(exceptionInfo,"ERROR","_fwAlertConfig_checkClassPriorities(): More than one good range was specified.","");
		return;
	}
//DebugN(alertClasses);
       
        //ensure that all classes contain at least one . in the name, except the OK range which is ""
	numberOfRanges = dynlen(localAlertClasses);
	for(i=1; i<=numberOfRanges; i++)
	{
		if((strpos(localAlertClasses[i], ".") < 0) && (localAlertClasses[i] != ""))
			localAlertClasses[i] += ".";
	}
        
        //set search limits for check on alert classes
        startPoints = makeDynInt(goodRange, goodRange-1);
        endPoints = makeDynInt(numberOfRanges+1, 0);
        directions = makeDynInt(1, -1);

        //loop through list of systems
	numberOfSystems = dynUnique(systemsToCheck);
	for(j=1; j<=numberOfSystems; j++)
	{
          dyn_int priorities;
          dyn_string classesToRead;
          
	  classCheck = TRUE;
//DebugN("Verifying for: " + systemsToCheck[j]);
	  for(i=1; i<=numberOfRanges; i++)
            classesToRead[i] = systemsToCheck[j] + dpSubStr(localAlertClasses[i], DPSUB_DP_EL) + ":_alert_class.._prior";

          //read the priorities
          dpGet(classesToRead, priorities);
//DebugN(classesToRead, priorities);    
      
          //check that as we move away from the good range, the priorities increase
          for(k=1; classCheck && (k<=2); k++)
          {
            float previousPriority = 0;

//DebugN(startPoints[k], endPoints[k], directions[k]);
            for(i=startPoints[k]; i!=endPoints[k]; i+=directions[k])
            {
//DebugN(priorities[i], previousPriority);
              if(priorities[i] > previousPriority)
                previousPriority = priorities[i];
              else
              {
                //priorities do not increase
                if(useAlternativeClassPriorities)
                {
                  string classDpName, classDpElement;
                  //try to fix problem if alternative class priorities can be used
                  classDpName = dpSubStr(alertClasses[i + (directions[k]==1)], DPSUB_DP);
                  classDpElement = dpSubStr(alertClasses[i + (directions[k]==1)], DPSUB_DP_EL);
                  
                  strreplace(classDpElement, classDpName, "");
                  
                  //see if class contains _XX priority suffix => if so, remove it			    
                  if(patternMatch(fwAlertConfig_FW_ALERT_CLASS_ALTERNATIVE_PATTERN, classDpName))
                  {
                    classDpName = strrtrim(classDpName, "1234567890");
                    classDpName = strrtrim(classDpName, "_");
                  }
                  
                  classDpName += "_" + (previousPriority + 1) + classDpElement;
                  if(dpExists(classDpName))
                  {
                     alertClasses[i + (directions[k]==1)] = classDpName;
                     previousPriority += 1;
                  }
                  else
                    classCheck = FALSE;
                }
                else
                  classCheck = FALSE;
                
                if(!classCheck)
                  break;
              }
            }
          }
          
          //if not, then raise an exception
          if(!classCheck)
	  {		
		fwException_raise(exceptionInfo,"ERROR","_fwAlertConfig_checkClassPriorities(): "
                                  + "Alert class priority values taken from system " + systemsToCheck[j] + " are not consistent.","");
                classesOk = FALSE;
		return;
	  }
	}
        
        classesOk = TRUE;
}


/** This function can be used to evaluate relative limits for many dpes and get back the absolute values needed to save to the PVSS configs.
You can specify a different set of limits for each dpe that you pass to the function. 
Types of relative limit can be "Current Value +/- the limit value" or "Current Value +/- a percentage of the current value".
If you use this function with limits of the normal absolute type, the output limits will be equal to the input limits.

@par Constraints
	None

@par Usage
	Public

@par PVSS managers
	VISION, CTRL

@param dpes			The list of data point elements that the limits are intended for
@param limitsType		The type of limits that you are passing to the function.  Must be one of:
					fwConfigs_ALERT_LIMITS_ABSOLUTE
					fwConfigs_ALERT_LIMITS_RELATIVE
					fwConfigs_ALERT_LIMITS_RELATIVE_PERCENTAGE
@param relativeLimits	The list of values of the limits for each dpe in the dpes list.
@param absoluteLimits	The processed limits are returned here. 
				Each limit is found in the same position in the array as the original unprocessed limit in relativeLimits. 
@param exceptionInfo	Details of any exceptions are returned here   
*/
fwAlertConfig_generateAbsoluteLimitsMany(dyn_string dpes, int limitsType, dyn_dyn_mixed relativeLimits,
																			dyn_dyn_mixed &absoluteLimits, dyn_string &exceptionInfo)
{
	int i, j, numberOfDpes, numberOfLimits;
	dyn_mixed currentValues;

	if(limitsType == fwConfigs_ALERT_LIMITS_ABSOLUTE)
	{
		absoluteLimits = relativeLimits;
		return;
	}

	_fwConfigs_getConfigTypeAttribute(dpes, fwConfigs_PVSS_ORIGINAL, currentValues, exceptionInfo, ".._value");
	
	numberOfDpes = dynlen(dpes);
	for(i=1; i<=numberOfDpes; i++)
	{
		if((currentValues[i] == 0) && (limitsType == fwConfigs_ALERT_LIMITS_RELATIVE_PERCENTAGE))
		{		
			fwException_raise(exceptionInfo, "ERROR",
				"fwAlertConfig_generateAbsoluteLimitsMany(): It is not possible to use relative percentage limits when the current original value is 0.","");
			return;
		}

		numberOfLimits = dynlen(relativeLimits[i]);
		for(j=1; j<=numberOfLimits; j++)
		{
			if(limitsType == fwConfigs_ALERT_LIMITS_RELATIVE)
				absoluteLimits[i][j] = currentValues[i] + relativeLimits[i][j];
			else if(limitsType == fwConfigs_ALERT_LIMITS_RELATIVE_PERCENTAGE)
				absoluteLimits[i][j] = currentValues[i] + (currentValues[i]*relativeLimits[i][j]/100);
		}
	}	
	
//	DebugN(relativeLimits, absoluteLimits);
}

/** This function can be used to evaluate relative limits for many dpes and get back the absolute values needed to save to the PVSS configs.
The same set of limits is used for every dpe that you pass to the function. 
Types of relative limit can be "Current Value +/- the limit value" or "Current Value +/- a percentage of the current value".
If you use this function with limits of the normal absolute type, the output limits will be equal to the input limits.

@par Constraints
	None

@par Usage
	Public

@par PVSS managers
	VISION, CTRL

@param dpes			The list of data point elements that the limits are intended for
@param limitsType		The type of limits that you are passing to the function.  Must be one of:
					fwConfigs_ALERT_LIMITS_ABSOLUTE
					fwConfigs_ALERT_LIMITS_RELATIVE
					fwConfigs_ALERT_LIMITS_RELATIVE_PERCENTAGE
@param relativeLimits	The limits to be evaluted for each dpe.
@param absoluteLimits	The processed limits are returned here. 
				The first dimension of the array indicates which dpe the limit value belongs to.
				The second dimension of the array provides all the limits for that particular dpe.
					e.g. absoluteLimits[1][2] returns the second limit value for the dpe in the first position of the dpes list. 
@param exceptionInfo	Details of any exceptions are returned here   
*/
fwAlertConfig_generateAbsoluteLimitsMultiple(dyn_string dpes, int limitsType, dyn_mixed relativeLimits,
																			dyn_dyn_mixed &absoluteLimits, dyn_string &exceptionInfo)
{
	int i, length;
	dyn_dyn_mixed unprocessedLimits;
	
	length = dynlen(dpes);
	for(i=1; i<=length; i++)
		unprocessedLimits[i] = relativeLimits;

	fwAlertConfig_generateAbsoluteLimitsMany(dpes, limitsType, unprocessedLimits, absoluteLimits, exceptionInfo);
}

_fwAlertConfig_checkAlertClasses(dyn_dyn_string &alertClasses, dyn_string &exceptionInfo)
{
	int i, j, width, length;

	width = dynlen(alertClasses);
	for(i=1; i<=width; i++)
	{
		length = dynlen(alertClasses[i]);
		for(j=1; j<=length; j++)
		{
			if((alertClasses[i][j] != "") && (strpos(alertClasses[i][j], ".") < 0))
				alertClasses[i][j] += ".";
		}
	}
}

/////////////////////////////////////////////////////////////////////////////////////////
////below this line are functions that are still under conceptual development
/////////////////////////////////////////////////////////////////////////////////////////

/** Under development - DO NOT USE
*/
_fwAlertConfig_createDpeAlertConfigObject(dyn_dyn_anytype &dpeAlertConfigObject, 
										string dpe,
										int type,
										bool active,
										dyn_float limits,
										dyn_string classes,
										dyn_string texts,
										string panel,
										dyn_string panelParameters,
										string help, 
										dyn_string &exceptionInfo, 
										int dpeType = -1)
{
	// create generic config object
	fwConfigs_createDpeConfigObject(dpeAlertConfigObject, dpe, type, exceptionInfo, active, dpeType);

	// insert alert specific values
	dpeAlertConfigObject[fwAlertConfig_DPE_OBJECT_LIMITS]		= limits;
	dpeAlertConfigObject[fwAlertConfig_DPE_OBJECT_CLASSES]		= classes;
	dpeAlertConfigObject[fwAlertConfig_DPE_OBJECT_TEXTS]		= texts;
	dpeAlertConfigObject[fwAlertConfig_DPE_OBJECT_PANEL][1]	= panel;
	dpeAlertConfigObject[fwAlertConfig_DPE_OBJECT_PANEL_PARAMETERS]	= panelParameters;	
	dpeAlertConfigObject[fwAlertConfig_DPE_OBJECT_HELP][1]		= help;
}

/** Under development - DO NOT USE
*/
_fwAlertConfig_readDpeAlertConfigObject(	dyn_dyn_anytype dpeAlertConfigObject, 
										string &dpe,
										int &type,
										bool &active,
										dyn_float &limits,
										dyn_string &classes,
										dyn_string &texts,
										string &panel,
										dyn_string &panelParameters,
										string &help, 
										dyn_string &exceptionInfo, 
										int &dpeType)
{
	if(dynlen(dpeAlertConfigObject[fwConfigs_DPE_OBJECT_TYPE]) > 0)
		type = dpeAlertConfigObject[fwConfigs_DPE_OBJECT_TYPE][1];
	else
		fwException_raise(	exceptionInfo, 
							"ERROR",
							"fwAlerConfig_readDpeAlertConfigObject(): could not read alert type from object",
							"");
							
	if(dynlen(dpeAlertConfigObject[fwConfigs_DPE_OBJECT_DPE_NAME]) > 0)					
		dpe = dpeAlertConfigObject[fwConfigs_DPE_OBJECT_DPE_NAME][1];

	if(dynlen(dpeAlertConfigObject[fwConfigs_DPE_OBJECT_DPE_TYPE]) > 0)					
		dpeType = dpeAlertConfigObject[fwConfigs_DPE_OBJECT_DPE_TYPE][1];

	if(type != DPCONFIG_NONE)
	{
		active 		= dpeAlertConfigObject[fwConfigs_DPE_OBJECT_ACTIVE][1];
		limits 		= dpeAlertConfigObject[fwAlertConfig_DPE_OBJECT_LIMITS];
		classes 	= dpeAlertConfigObject[fwAlertConfig_DPE_OBJECT_CLASSES];
		texts 		= dpeAlertConfigObject[fwAlertConfig_DPE_OBJECT_TEXTS];
	
		// optional parameters
		if(dynlen(dpeAlertConfigObject[fwAlertConfig_DPE_OBJECT_PANEL]) > 0)
			panel = dpeAlertConfigObject[fwAlertConfig_DPE_OBJECT_PANEL][1];
		else
			panel = "";
			
		if(dynlen(dpeAlertConfigObject[fwAlertConfig_DPE_OBJECT_PANEL_PARAMETERS]) > 0)
			panelParameters = dpeAlertConfigObject[fwAlertConfig_DPE_OBJECT_PANEL_PARAMETERS];	
		else
			panelParameters = makeDynString();
			
		if(dynlen(dpeAlertConfigObject[fwAlertConfig_DPE_OBJECT_HELP]) > 0)
			help = dpeAlertConfigObject[fwAlertConfig_DPE_OBJECT_HELP][1];
		else
			help = "";
			
//		dpeType	= dpeAlertConfigObject[fwConfigs_DPE_OBJECT_DPE_TYPE][1];
	}
	else
	{
		active	= false;
		limits	= makeDynString();
		classes	= makeDynString();
		texts	= makeDynString();
		panel 	= "";
		panelParameters = makeDynString();
		help 	= "";
//		dpeType = 0;
	}		
}

fwAlertConfig_queryAlertsOnSystem(string systemName, dyn_dyn_string &alertData, dyn_string &exceptionInfo)
{
  dyn_dyn_anytype searchResults;

  alertData[fwAlertConfig_ALERT_DP_NAME] = makeDynString();
  alertData[fwAlertConfig_ALERT_TYPE] = makeDynString();
  alertData[fwAlertConfig_ALERT_ACTIVE] = makeDynString();
  alertData[fwAlertConfig_ALERT_STATE] = makeDynString();
  alertData[fwAlertConfig_ALERT_RANGES] = makeDynString();
  alertData[fwAlertConfig_ALERT_SUM_DP_LIST] = makeDynString();
  alertData[fwAlertConfig_ALERT_SUM_DP_PATTERN] = makeDynString();

  dpQuery("SELECT '_alert_hdl.._type', '_alert_hdl.._active', '_alert_hdl.._act_state', "
          + "'_alert_hdl.._num_ranges', '_alert_hdl.._dp_list', '_alert_hdl.._dp_pattern' FROM '*' REMOTE '"
          + systemName + ":' WHERE '_alert_hdl.._type' != 0", searchResults);

  for(int j=2; j<=dynlen(searchResults); j++)
  {
    alertData[fwAlertConfig_ALERT_DP_NAME][j-1]         = searchResults[j][fwAlertConfig_ALERT_DP_NAME];
    alertData[fwAlertConfig_ALERT_TYPE][j-1]            = searchResults[j][fwAlertConfig_ALERT_TYPE];
    alertData[fwAlertConfig_ALERT_ACTIVE][j-1]          = searchResults[j][fwAlertConfig_ALERT_ACTIVE];
    alertData[fwAlertConfig_ALERT_STATE][j-1]           = searchResults[j][fwAlertConfig_ALERT_STATE];
    alertData[fwAlertConfig_ALERT_RANGES][j-1]          = searchResults[j][fwAlertConfig_ALERT_RANGES];
    alertData[fwAlertConfig_ALERT_SUM_DP_LIST][j-1]     = searchResults[j][fwAlertConfig_ALERT_SUM_DP_LIST];
    alertData[fwAlertConfig_ALERT_SUM_DP_PATTERN][j-1]  = searchResults[j][fwAlertConfig_ALERT_SUM_DP_PATTERN];
  } 
}

/////////////////////////////////////////////////////////////////////////////////////////
////below this line provided for backward compatibility
/////////////////////////////////////////////////////////////////////////////////////////

/** DEPRECATED - Modifies an existing analog alert handling with 5 ranges on the given data point element.
The function has similar functionality to _fwAlertConfig_createAnalog5 except that the type of alert
handling for the config are not altered.  This avoids problems which occur when altering the type of
the alert config when something is dpConencted to the config.

NOTE: THIS FUNCTION SHOULD NOT BE USED (see constraints below), use fwAlertConfig_set

@par Constraints
	This is an internal function and should not be called directly
				To modify an analog alert with 5 ranges the function
				fwAlertConfig_set should be used

@par Usage
	DEPRECATED

@par PVSS managers
	VISION, CTRL

@param dpe							Name of data point element to act on
@param alertTexts				Alert texts for each range  
@param limits						The limits of each range given here
@param alertClass				Alert classes for each range 
													One of the items of the dyn_string must always be empty to indicate the valid state.
													Don't forget to add the dot to the alert class names.
@param alertPanel				Panel to call from the alert screen
@param alertPanelParameters		Parameters to pass to panel given in alertPanel
@param help							Help text or path to help file    
@param alertRequest			whether to delete (FALSE) or create/modify (TRUE) the alert config 
@param exceptionInfo		Details of any exceptions are returned here   
*/
fwAlertConfig_setGeneral(string dpe, dyn_string alertTexts, dyn_float limits, dyn_string alertClass, string alertPanel,
						 dyn_string alertPanelParameters, string help, bool alertRequest, dyn_string &exceptionInfo)
{
    int i, elementType, configType, dpConfigType, currentRanges, configOptions;
    string dp;
        
	_fwConfigs_getConfigOptionsForDpe(dpe, fwConfigs_PVSS_ALERT_HDL, configOptions, exceptionInfo);
	if(dynlen(exceptionInfo)>0)
		return;
		
    switch(configOptions)
	{
		case fwConfigs_ANALOG_OPTIONS:
			elementType = 2;
			break;			
		case fwConfigs_BINARY_OPTIONS:
			elementType = 1;
			break;		
		default:
			return;
	}

   	// check whether alert config exists
   	dpGet(dpe + ":_alert_hdl.._type", configType);
   	
	if (alertRequest == 0 && configType != DPCONFIG_NONE)	// delete alert that exists
	{
		if (elementType == 1)	// delete boolean alert config
		{
	        fwAlertConfig_deleteDigital(dpe, exceptionInfo);
   		}
   		else if (elementType == 2)	// delete analog alert config
    	{
			fwAlertConfig_deleteAnalog(dpe, exceptionInfo);   
		}  
   	}    
   	else if (alertRequest == 1)		// create new alert or modify existing alert 
    {   		 	     		        
		if (configType == DPCONFIG_NONE)	// create alert config
		{	    	    	
			if (elementType == 1)	// boolean alert config
				fwAlertConfig_createDigital(dpe, alertTexts, alertClass, alertPanel, alertPanelParameters, help, exceptionInfo);
			else if (elementType == 2)	// analog alert config
				fwAlertConfig_createAnalog(dpe, alertTexts, limits, alertClass, alertPanel, alertPanelParameters, help, exceptionInfo);					
		}
		else 	// modify existing alert config
		{			
			if (elementType == 1)	// boolean alert config
				fwAlertConfig_modifyDigital(dpe, alertTexts, alertClass, alertPanel, alertPanelParameters, help, exceptionInfo);
			else if (elementType == 2)	// analog alert config
			{
				dpGet(dpe + ":_alert_hdl.._num_ranges", currentRanges);
				if (currentRanges != dynlen(alertClass)) 
				{
					fwAlertConfig_deleteAnalog(dpe, exceptionInfo);
					fwAlertConfig_createAnalog(dpe, alertTexts, limits, alertClass, alertPanel, alertPanelParameters, help, exceptionInfo);     
				}
				else
					fwAlertConfig_modifyAnalog(dpe, alertTexts, limits, alertClass, alertPanel, alertPanelParameters, help, exceptionInfo);
			}			
		}		
	}
}

/** DECPRECATED - Please use fwAlertConfig_set instead
Creates digital alert handling on the given data point element.
The alert texts, alert class of the bad state and the alert and help panels are set.

@par Constraints
	The length of the alertTexts and alertClasses dyn_strings must both be 2

@par Usage
	DECPRECATED

@par PVSS managers
	VISION, CTRL

@param dpe						Name of data point element to act on
@param alertTexts			Alert texts eg. makeDynString( "Bad Text", "OK")   
@param alertClasses		Alert classes eg. makeDynString( "_fwErrorAck.", "" )
												One of the items of the dyn_string must always be empty to indicate the valid state
												The valid ranges becomes the state with no alert class given (the second in this case).
												Don't forget to add the dot to the alert class names.
@param alertPanel			Panel to call from the alert screen
@param alertPanelParameters		Parameters to pass to panel given in Alert Panel
@param alertHelp			Help text or path to help file    
@param exceptionInfo	Details of any exceptions are returned here   
@param modifyOnly			Optional parameter - Default value FALSE.  Set to TRUE to modify alert without setting "type" attributes.
												With TRUE this is equal to the functionality provided by fwAlertConfig_modifyDigital   
												With FALSE this is equal to the functionality provided by fwAlertConfig_createDigital   
*/
fwAlertConfig_setDigital(string dpe,
							dyn_string alertTexts,
							dyn_string alertClasses,
							string alertPanel,
							dyn_string alertPanelParameters,
							string alertHelp,
							dyn_string &exceptionInfo,
							bool modifyOnly = FALSE)
{
	fwAlertConfig_set(dpe,
				DPCONFIG_ALERT_BINARYSIGNAL,
				alertTexts,
				makeDynFloat(),
				alertClasses,
				makeDynString(),
				alertPanel,
				alertPanelParameters,
				alertHelp,
				exceptionInfo,
				modifyOnly);
}

/** DEPRECATED - Please use fwAlertConfig_set instead
Creates analog alert handling on the given data point element without hysteresis.
The alert texts, alert limits, alert classes and the alert and help panels are set.

@par Constraints
	The length of the alertTexts and alertClasses dyn_strings must be equal
			 The length of the limits dyn_float must be one less than the length of alertTexts

@par Usage
	DEPRECATED

@par PVSS managers
	VISION, CTRL

@param dpe						Name of data point element to act on
@param alertTexts			Alert texts for each range eg. makeDynString( "Bad Text", "OK", "Bad Text")   
@param limits					The limits of each range given here eg. makeDynFloat( 20, 60 );
@param alertClasses		Alert classes for each range eg. makeDynString( "_fwErrorAck.", "" , "_fwErrorAck.")
												One of the items of the dyn_string must always be empty to indicate the valid state.
												The valid ranges becomes the state with no alert class given (the second in this case).
												Don't forget to add the dot to the alert class names.
@param alertPanel			Panel to call from the alert screen
@param alertPanelParameters		Parameters to pass to panel given in Alert Panel
@param alertHelp			Help text or path to help file    
@param exceptionInfo	Details of any exceptions are returned here   
@param modifyOnly			Optional parameter - Default value FALSE.  Set to TRUE to modify alert without setting "type" attributes.
												With TRUE this is equal to the functionality provided by fwAlertConfig_modifyAnalog   
												With FALSE this is equal to the functionality provided by fwAlertConfig_createAnalog   
*/
fwAlertConfig_setAnalog( string dpe,  
                        dyn_string alertTexts,    
                        dyn_float limits,    
                        dyn_string alertClasses,    
                        string alertPanel,    
                        dyn_string alertPanelParameters,    
                        string alertHelp,
						dyn_string &exceptionInfo,
						bool modifyOnly = FALSE)
{    
	fwAlertConfig_set(dpe,
				DPCONFIG_ALERT_NONBINARYSIGNAL,
				alertTexts,
				limits,
				alertClasses,
				makeDynString(),
				alertPanel,
				alertPanelParameters,
				alertHelp,
				exceptionInfo,
				modifyOnly);
}


/** DEPRECATED - Please use fwAlertConfig_set instead
Creates summary alert handling on the given data point element.

@par Constraints
	The length of the alertTexts should be 2
	Can only set summary alerts of type dp list (not dp pattern)

@par Usage
	DEPRECATED 

@par PVSS managers
	VISION, CTRL

@param dpe						Name of data point element to act on
@param alertTexts			Alert texts eg. makeDynString( "OK", "Bad")   
@param dpElementList	List of dpes to include in summary alert.  
                                    If you want to specify a DP pattern, then this should entered as the first item in this list.
@param alertPanel			Panel to call from the alert screen
@param alertPanelParameters		Parameters to pass to panel given in Alert Panel
@param alertHelp			Help text or path to help file    
@param exceptionInfo	Details of any exceptions are returned here   
@param modifyOnly			Optional parameter - Default value FALSE.  Set to TRUE to modify alert without setting "type" attributes.
												With TRUE this is equal to the functionality provided by fwAlertConfig_modifySummary   
												With FALSE this is equal to the functionality provided by fwAlertConfig_createSummary   
*/
fwAlertConfig_setSummary(string dpe,
							dyn_string alertTexts,
							dyn_string dpElementList,      
							string alertPanel,
							dyn_string alertPanelParameters,
							string alertHelp,
							dyn_string &exceptionInfo,
							bool modifyOnly = FALSE)
{
	fwAlertConfig_set(dpe,
				DPCONFIG_SUM_ALERT,
				alertTexts,
				makeDynFloat(),
				makeDynString(),
				dpElementList,
				alertPanel,
				alertPanelParameters,
				alertHelp,
				exceptionInfo,
				modifyOnly);
}


/** DEPRECATED - Function to create a summary alert

For new function see fwAlertConfig_set

@par Usage
	DEPRECATED
*/
fwAlertConfig_createSummary(string dpe,
							dyn_string alertTexts,
							dyn_string dpelementList,      
							string alertPanel,
							dyn_string alertPanelParameters,
							string alertHelp,
							dyn_string &exceptionInfo)
{
	fwAlertConfig_setSummary(dpe, alertTexts, dpelementList,
								alertPanel, alertPanelParameters, alertHelp, exceptionInfo, FALSE);
}

/** DEPRECATED - Function to modify a summary alert

For new function see fwAlertConfig_set

@par Usage
	DEPRECATED
*/
fwAlertConfig_modifySummary(string dpe,
							dyn_string alertTexts,
							dyn_string dpelementList,      
							string alertPanel,
							dyn_string alertPanelParameters,
							string alertHelp,
							dyn_string &exceptionInfo)
{
	fwAlertConfig_setSummary(dpe, alertTexts, dpelementList,
								alertPanel, alertPanelParameters, alertHelp, exceptionInfo, TRUE);
}

/** DEPRECATED - Function to create a digital alert

For new function see fwAlertConfig_set

@par Usage
	DEPRECATED
*/
fwAlertConfig_createDigital(string dpe,
							dyn_string alertTexts,
							dyn_string alertClasses,
							string alertPanel,
							dyn_string alertPanelParameters,
							string alertHelp,
							dyn_string &exceptionInfo)
{
	fwAlertConfig_setDigital(dpe, alertTexts, alertClasses, alertPanel,
								alertPanelParameters, alertHelp, exceptionInfo, FALSE);
}

/** DEPRECATED - Function to modify a digital alert

For new function see fwAlertConfig_set

@par Usage
	DEPRECATED
*/
fwAlertConfig_modifyDigital(string dpe,
							dyn_string alertTexts,
							dyn_string alertClasses,
							string alertPanel,
							dyn_string alertPanelParameters,
							string alertHelp,
							dyn_string &exceptionInfo)
{
	fwAlertConfig_setDigital(dpe, alertTexts, alertClasses, alertPanel,
								alertPanelParameters, alertHelp, exceptionInfo, TRUE);
}

/** DEPRECATED - Function to create an analog alert

For new function see fwAlertConfig_set

@par Usage
	DEPRECATED
*/
fwAlertConfig_createAnalog( string dpe,  
                        dyn_string alertTexts,    
                        dyn_float limits,    
                        dyn_string alertClasses,    
                        string alertPanel,    
                        dyn_string alertPanelParameters,    
                        string alertHelp,
						dyn_string &exceptionInfo)    
{ 
	fwAlertConfig_setAnalog(dpe, alertTexts, limits, alertClasses, alertPanel,    
                        	alertPanelParameters, alertHelp, exceptionInfo, FALSE);    
}

/** DEPRECATED - Function to modify an analog alert

For new function see fwAlertConfig_set

@par Usage
	DEPRECATED
*/
fwAlertConfig_modifyAnalog( string dpe,  
                        dyn_string alertTexts,    
                        dyn_float limits,    
                        dyn_string alertClasses,    
                        string alertPanel,    
                        dyn_string alertPanelParameters,    
                        string alertHelp,
						dyn_string &exceptionInfo)    
{ 
	fwAlertConfig_setAnalog(dpe, alertTexts, limits, alertClasses, alertPanel,    
                        	alertPanelParameters, alertHelp, exceptionInfo, TRUE);    
}

/** DEPRECATED - Function to delete a summary alert

For new function see fwAlertConfig_delete

@par Usage
	DEPRECATED
*/
fwAlertConfig_deleteSummary( string dpe, dyn_string &exceptionInfo)   
{   
	fwAlertConfig_delete(dpe, exceptionInfo);
}      
  
/** DEPRECATED - Function to delete an analog alert

For new function see fwAlertConfig_delete

@par Usage
	DEPRECATED
*/
fwAlertConfig_deleteAnalog( string dpe, dyn_string &exceptionInfo)   
{   
	fwAlertConfig_delete(dpe, exceptionInfo);
}

/** DEPRECATED - Function to delete a digital alert

For new function see fwAlertConfig_delete

@par Usage
	DEPRECATED
*/
fwAlertConfig_deleteDigital( string dpe, dyn_string &exceptionInfo)   
{   
	fwAlertConfig_delete(dpe, exceptionInfo);
}

/** DEPRECATED - Returns the details of the summary alert configuration on a given dpe.
	This function raises an exception if the summary alert uses a DP pattern as this is not supported by the FW.

NOTE: THIS FUNCTION SHOULD NOT BE CALLED DIRECTLY, use fwAlertConfig_get

@par Constraints
	Can only get summary alerts of type dp list (not dp pattern)

@par Usage
	DEPRECATED

@par PVSS managers
	VISION, CTRL

@param dpe						Name of data point element to read from
@param configExists		Return TRUE if dpe has a summary alert config, else FALSE
@param alertTexts			Two alert texts will be returned if summary alert exists
												(alertText[1] = Good State Text, alertText[2] = Bad State Text)   
@param dpeList				The list of dp elements that are used in the alert summary
                                      If a DP pattern was specified, then this will be returned as the first item in this list.
@param alertPanel			Panel to call from the alert screen
@param alertPanelParameters		Parameters to pass to the given alertPanel
@param alertHelp			Help text or path to help file    
@param isActive				TRUE if alert is active else FALSE
@param exceptionInfo	Details of any exceptions are returned here   
*/
fwAlertConfig_getSummary(	string dpe,
							bool &configExists,
							dyn_string &alertTexts,
							dyn_string &dpeList,
							string &alertPanel,
							dyn_string &alertPanelParameters,
							string &alertHelp,
							bool &isActive,
							dyn_string &exceptionInfo)
{
	int alertType;
	string dpePattern;

	dpGet(dpe+":_alert_hdl.._type", alertType);

	if(alertType == DPCONFIG_SUM_ALERT)
	{
		configExists = TRUE;

		dpGet( dpe + ":_alert_hdl.._text1", alertTexts[2],       
				dpe + ":_alert_hdl.._text0", alertTexts[1],
				dpe + ":_alert_hdl.._dp_list", dpeList,
      dpe + ":_alert_hdl.._dp_pattern", dpePattern,
				dpe + ":_alert_hdl.._panel", alertPanel,
				dpe + ":_alert_hdl.._panel_param", alertPanelParameters,
				dpe + ":_alert_hdl.._help", alertHelp,
				dpe + ":_alert_hdl.._active", isActive);
                
    if(dynlen(dpeList) == 0)
      dpeList = makeDynString(dpePattern);
	}
	else
	{
		configExists = FALSE;
		alertTexts = makeDynString();
		dpeList = makeDynString();
		alertPanel = "";
		alertPanelParameters = makeDynString();
		alertHelp = "";
		isActive = FALSE;
	}
}

//@}    



