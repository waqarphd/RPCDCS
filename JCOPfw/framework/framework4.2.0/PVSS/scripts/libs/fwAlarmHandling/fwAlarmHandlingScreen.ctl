/**@file

This library contains functions for the internal workings of the JCOP Alarm Screen.

@par Creation Date
	02/02/2006

@par Modification History

	2010/04/13 Marco
  - Fix for bug #42996: commented out the convertion from * to full list of dist system names.
  
	2010/04/07 Marco
  - Fix for bug #55217: commented out the use of function _fwAlarmHandling_convertSeverityRangeToList.
  
	2010/03/26 Marco
  - Added Local/Global alarm filtering (based on class priority - thanks Oliver Holme).
  - Added possibility to set a maximum number of historical alerts to be displayed 
    (functions fwAlarmHandlingScreen_setHistoricalMaxLines, fwAlarmHandlingScreen_getHistoricalMaxLines).
  - Created function _fwAlarmHandlingScreen_showHideColumns: handles table much more efficiently.
  
@par Constraints

@par Usage
	Internal

@par PVSS managers
	VISION

@author 
	Oliver Holme (IT-CO)
*/

//@{
//constants
const unsigned fwAlarmHandlingScreen_CONFIG_OBJECT_FILTER_DP_NAME 			= 1;
const unsigned fwAlarmHandlingScreen_CONFIG_OBJECT_FILTER_DP_ALIAS 			= 2;
const unsigned fwAlarmHandlingScreen_CONFIG_OBJECT_FILTER_DP_TYPE 			= 3;
const unsigned fwAlarmHandlingScreen_CONFIG_OBJECT_FILTER_DP_LIST 			= 4;
const unsigned fwAlarmHandlingScreen_CONFIG_OBJECT_FILTER_SYSTEM 				= 5;
const unsigned fwAlarmHandlingScreen_CONFIG_OBJECT_FILTER_LOCAL_OR_GLOBAL			= 6;
const unsigned fwAlarmHandlingScreen_CONFIG_OBJECT_FILTER_SEVERITY			= 7;
const unsigned fwAlarmHandlingScreen_CONFIG_OBJECT_FILTER_ALERT_TEXT		= 8;
const unsigned fwAlarmHandlingScreen_CONFIG_OBJECT_FILTER_DESCRIPTION		= 9;
const unsigned fwAlarmHandlingScreen_CONFIG_OBJECT_FILTER_SUMMARIES			= 10;
const unsigned fwAlarmHandlingScreen_CONFIG_OBJECT_FILTER_ALERT_STATE			= 11;

const unsigned fwAlarmHandlingScreen_CONFIG_OBJECT_FILTER_SIZE 					= 10;

const unsigned fwAlarmHandlingScreen_CONFIG_OBJECT_MODE_TYPE 						 = 1;
const unsigned fwAlarmHandlingScreen_CONFIG_OBJECT_MODE_START_TIME 		 = 2;
const unsigned fwAlarmHandlingScreen_CONFIG_OBJECT_MODE_END_TIME 			 = 3;
const unsigned fwAlarmHandlingScreen_CONFIG_OBJECT_MODE_MAX_LINES 			= 4;

const unsigned fwAlarmHandlingScreen_CONFIG_OBJECT_MODE_SIZE 						= 3;

const unsigned fwAlarmHandlingScreen_SEVERITY_FILTER_OBJECT_WARNING			= 1;
const unsigned fwAlarmHandlingScreen_SEVERITY_FILTER_OBJECT_ERROR				= 2;
const unsigned fwAlarmHandlingScreen_SEVERITY_FILTER_OBJECT_FATAL				= 3;

const unsigned fwAlarmHandlingScreen_ACCESS_ACKNOWLEDGE = 1;
const unsigned fwAlarmHandlingScreen_ACCESS_COMMENT = 2;
const unsigned fwAlarmHandlingScreen_ACCESS_RIGHT_CLICK = 3;
const unsigned fwAlarmHandlingScreen_ACCESS_FILTER = 4;
const unsigned fwAlarmHandlingScreen_ACCESS_MANAGE_DISPLAY = 5;

const string fwAlarmHandlingScreen_CONFIG_DP_FILTER_DP_NAME				= ".filter.dpName";
const string fwAlarmHandlingScreen_CONFIG_DP_FILTER_DP_ALIAS			= ".filter.dpAlias";
const string fwAlarmHandlingScreen_CONFIG_DP_FILTER_DP_TYPE				= ".filter.dpType";
const string fwAlarmHandlingScreen_CONFIG_DP_FILTER_SYSTEM				= ".filter.systems";
const string fwAlarmHandlingScreen_CONFIG_DP_FILTER_LOCAL_OR_GLOBAL				= ".filter.severity.localOrGlobal";
const string fwAlarmHandlingScreen_CONFIG_DP_FILTER_WARNING				= ".filter.severity.warning";
const string fwAlarmHandlingScreen_CONFIG_DP_FILTER_ERROR					= ".filter.severity.error";
const string fwAlarmHandlingScreen_CONFIG_DP_FILTER_FATAL					= ".filter.severity.fatal";
const string fwAlarmHandlingScreen_CONFIG_DP_FILTER_ALERT_TEXT		= ".filter.alertText";
const string fwAlarmHandlingScreen_CONFIG_DP_FILTER_DESCRIPTION		= ".filter.description";
const string fwAlarmHandlingScreen_CONFIG_DP_FILTER_SUMMARIES			= ".filter.summaries";
const string fwAlarmHandlingScreen_CONFIG_DP_FILTER_ALERT_STATE			= ".filter.alertState";
const string fwAlarmHandlingScreen_CONFIG_DP_FILTER_QUICK_FILTER			= ".showAsQuickFilter";
const string fwAlarmHandlingScreen_CONFIG_DP_FILTER_ACCESS_RIGHT			= ".quickFilterAccessRight";

const string fwAlarmHandlingScreen_PVSS_DP_FILTER_SHORTCUT				= ".Alerts.Filter.Shortcut";
const string fwAlarmHandlingScreen_PVSS_DP_FILTER_PRIORITY				= ".Alerts.Filter.Prio";
const string fwAlarmHandlingScreen_PVSS_DP_FILTER_DP_LIST					= ".Alerts.Filter.DpList";
const string fwAlarmHandlingScreen_PVSS_DP_FILTER_ALERT_TEXT			= ".Alerts.Filter.AlertText";
const string fwAlarmHandlingScreen_PVSS_DP_FILTER_COMMENT					= ".Alerts.Filter.DpComment";
const string fwAlarmHandlingScreen_PVSS_DP_FILTER_LOGIC						= ".Alerts.Filter.LogicalCombine";
const string fwAlarmHandlingScreen_PVSS_DP_FILTER_SUMMARIES				= ".Alerts.FilterTypes.AlertSummary";
const string fwAlarmHandlingScreen_PVSS_DP_FILTER_SYSTEMS					= ".Both.Systems.Selections";
const string fwAlarmHandlingScreen_PVSS_DP_FILTER_ALL_SYSTEMS			= ".Both.Systems.CheckAllSystems";
const string fwAlarmHandlingScreen_PVSS_DP_FILTER_ALERT_STATE			= ".Alerts.FilterState.State";
const string fwAlarmHandlingScreen_PVSS_DP_FILTER_ONE_ROW			= ".Alerts.FilterState.OneRowPerAlert";

const string fwAlarmHandlingScreen_PVSS_CONFIG_DP = "_AESConfig";
const string fwAlarmHandlingScreen_PVSS_CONFIG_COLUMN_NAMES = ".tables.alertTable.columns.name";
const string fwAlarmHandlingScreen_PVSS_CONFIG_COLUMN_FUNCTIONS = ".tables.alertTable.columns.value.functionName";
const string fwAlarmHandlingScreen_PVSS_CONFIG_COLUMN_BACKCOL = ".tables.alertTable.columns.useAlertClassBackColor";

const string fwAlarmHandlingScreen_FILTER_DP_TYPE = "_FwAesConfig";
const string fwAlarmHandlingScreen_FILTER_DP_PREFIX = "_FwAesConfig_";

const string fwAlarmHandlingScreen_PVSS_PROPERTIES_DP = "fwAES_Alerts";

const string fwAlarmHandlingScreen_HISTORICAL_TIME_FORMAT = "%d/%m/%Y %H:%M:%S";
const string fwAlarmHandlingScreen_ENABLED_BUTTON = "_ButtonShadow";
const string fwAlarmHandlingScreen_DISABLED_BUTTON = "_3DFace";

const string fwAlarmHandlingScreen_COLUMN_DP_NAME = "elementName";
const string fwAlarmHandlingScreen_COLUMN_LOGICAL_NAME = "logicalName";
const string fwAlarmHandlingScreen_COLUMN_DESCRIPTION = "description";
const string fwAlarmHandlingScreen_COLUMN_SHORT_SIGN = "abbreviation";
const string fwAlarmHandlingScreen_COLUMN_PRIORITY = "priority";
const string fwAlarmHandlingScreen_COLUMN_ACKNOWLEDGE = "acknowledge";
const string fwAlarmHandlingScreen_COLUMN_COMMENT = "nofComments";
const string fwAlarmHandlingScreen_COLUMN_ONLINE_VALUE = "onlineValue";
const string fwAlarmHandlingScreen_COLUMN_ALERT_VALUE = "value";
const string fwAlarmHandlingScreen_COLUMN_TIME_STANDARD = "timeStr";
const string fwAlarmHandlingScreen_COLUMN_TIME_CAME = "cameTime";

const string fwAlarmHandlingScreen_DPE_LIST_DIVIDER = ",";
const string fwAlarmHandlingScreen_PANEL_NAME = "fwAlarmHandling/fwAlarmHandlingScreen.pnl";

const int fwAlarmHandling_BEHAVIOUR_DESCRIPTION_ONLY = 0;
const int fwAlarmHandling_BEHAVIOUR_DESCRIPTION_OR_DP_NAME = 1;
const int fwAlarmHandling_BEHAVIOUR_DESCRIPTION_OR_ALIAS_OR_DP_NAME = 2;

const int fwAlarmHandling_BEHAVIOUR_TIME_CAME_WENT = 0;
const int fwAlarmHandling_BEHAVIOUR_TIME_ALWAYS_CAME = 1;

const int fwAlarmHandlingScreen_COLUMN_ID_DP_NAME = 1;
const int fwAlarmHandlingScreen_COLUMN_ID_LOGICAL_NAME = 2;
const int fwAlarmHandlingScreen_COLUMN_ID_DESCRIPTION = 3;
const int fwAlarmHandlingScreen_COLUMN_ID_ALERT_VALUE = 4;
const int fwAlarmHandlingScreen_COLUMN_ID_ONLINE_VALUE = 5;
const int fwAlarmHandlingScreen_COLUMN_ID_TIME_STANDARD = 6;
const int fwAlarmHandlingScreen_COLUMN_ID_TIME_CAME = 7;

const unsigned fwAlarmHandlingScreen_DATA_UPDATE_RATE = 2;
string fwAlarmHandlingScreen_COLOUR_BUTTON_NEEDS_PRESSING = "<{0,255,0},4,_3DFace,4,{0,0,0},0,{0,0,0},0,{0,0,0},0,{0,0,0},0>";
//@}

//@{
/** Reads the filter options from the alarm screen filter graphical objects

@par Constraints
	The function can only be called from within the JCOP FW Alarm Screen

@par Usage
	Public

@par PVSS managers
	VISION

@param aesFilter		The filter object is returned here with the filter as defined in the graphical objects
				Use the fwAlarmHandlingScreen_CONFIG_OBJECT_FILTER_XXX constants to interpret the object
@param exceptionInfo		Details of any exceptions are returned here   
*/
fwAlarmHandlingScreen_readFilter(dyn_dyn_anytype &aesFilter, dyn_string &exceptionInfo)
{
	int i, rows;
	dyn_uint sysIds;
	dyn_string selectedSysNames, sysNames, allDpTypes;

	allDpTypes = dpTypeList.items;
	getSystemNames(sysNames, sysIds);
	
	aesFilter[fwAlarmHandlingScreen_CONFIG_OBJECT_FILTER_DP_TYPE] = allDpTypes[deviceType.selectedPos];
	aesFilter[fwAlarmHandlingScreen_CONFIG_OBJECT_FILTER_ALERT_STATE][1] = alarmState.selectedPos - 1;

	aesFilter[fwAlarmHandlingScreen_CONFIG_OBJECT_FILTER_SYSTEM] = makeDynAnytype();
	rows = deviceSystemTable.lineCount();
	for(i=0; i<rows; i++)
		aesFilter[fwAlarmHandlingScreen_CONFIG_OBJECT_FILTER_SYSTEM][i+1] = deviceSystemTable.cellValueRC(i, "systemName");

  while(dynContains(aesFilter[fwAlarmHandlingScreen_CONFIG_OBJECT_FILTER_SYSTEM], "") > 0)
    dynRemove(aesFilter[fwAlarmHandlingScreen_CONFIG_OBJECT_FILTER_SYSTEM], dynContains(aesFilter[fwAlarmHandlingScreen_CONFIG_OBJECT_FILTER_SYSTEM], ""));
  
	selectedSysNames = aesFilter[fwAlarmHandlingScreen_CONFIG_OBJECT_FILTER_SYSTEM];
	if(selectedSysNames == sysNames)
		aesFilter[fwAlarmHandlingScreen_CONFIG_OBJECT_FILTER_SYSTEM] = "*";
		
	aesFilter[fwAlarmHandlingScreen_CONFIG_OBJECT_FILTER_DP_ALIAS] = (deviceAlias.text == "")?"*":deviceAlias.text;
 	fwGeneral_stringToDynString(aesFilter[fwAlarmHandlingScreen_CONFIG_OBJECT_FILTER_DP_ALIAS],
						aesFilter[fwAlarmHandlingScreen_CONFIG_OBJECT_FILTER_DP_ALIAS], fwGeneral_DYN_STRING_DEFAULT_SEPARATOR, FALSE, TRUE);
	aesFilter[fwAlarmHandlingScreen_CONFIG_OBJECT_FILTER_DESCRIPTION] = (deviceDescription.text == "")?"*":deviceDescription.text;
 	fwGeneral_stringToDynString(aesFilter[fwAlarmHandlingScreen_CONFIG_OBJECT_FILTER_DESCRIPTION],
						aesFilter[fwAlarmHandlingScreen_CONFIG_OBJECT_FILTER_DESCRIPTION], fwGeneral_DYN_STRING_DEFAULT_SEPARATOR, FALSE, TRUE);
	aesFilter[fwAlarmHandlingScreen_CONFIG_OBJECT_FILTER_DP_NAME] = (deviceName.text == "")?"*":deviceName.text;
 	fwGeneral_stringToDynString(aesFilter[fwAlarmHandlingScreen_CONFIG_OBJECT_FILTER_DP_NAME],
						aesFilter[fwAlarmHandlingScreen_CONFIG_OBJECT_FILTER_DP_NAME], fwGeneral_DYN_STRING_DEFAULT_SEPARATOR, FALSE, TRUE);
	aesFilter[fwAlarmHandlingScreen_CONFIG_OBJECT_FILTER_ALERT_TEXT] = (alarmText.text == "")?"*":alarmText.text;
 	fwGeneral_stringToDynString(aesFilter[fwAlarmHandlingScreen_CONFIG_OBJECT_FILTER_ALERT_TEXT],
						aesFilter[fwAlarmHandlingScreen_CONFIG_OBJECT_FILTER_ALERT_TEXT], fwGeneral_DYN_STRING_DEFAULT_SEPARATOR, FALSE, TRUE);

	aesFilter[fwAlarmHandlingScreen_CONFIG_OBJECT_FILTER_SEVERITY][fwAlarmHandlingScreen_SEVERITY_FILTER_OBJECT_WARNING] = showWarnings.toggleState;
	aesFilter[fwAlarmHandlingScreen_CONFIG_OBJECT_FILTER_SEVERITY][fwAlarmHandlingScreen_SEVERITY_FILTER_OBJECT_ERROR] = showErrors.toggleState;
	aesFilter[fwAlarmHandlingScreen_CONFIG_OBJECT_FILTER_SEVERITY][fwAlarmHandlingScreen_SEVERITY_FILTER_OBJECT_FATAL] = showFatals.toggleState;

        aesFilter[fwAlarmHandlingScreen_CONFIG_OBJECT_FILTER_LOCAL_OR_GLOBAL][1] = (showLocalOrGlobal.selectedPos - 1);
//DebugN(aesFilter[fwAlarmHandlingScreen_CONFIG_OBJECT_FILTER_SYSTEM], selectedSysNames);
}

/** Shows the given filter options in the alarm screen filter graphical objects

@par Constraints
	The function can only be called from within the JCOP FW Alarm Screen

@par Usage
	Public

@par PVSS managers
	VISION

@param aesFilter		The filter object with the filter data to display in the graphical objects
				Use the fwAlarmHandlingScreen_CONFIG_OBJECT_FILTER_XXX constants to interpret the object
@param exceptionInfo		Details of any exceptions are returned here   
*/
fwAlarmHandlingScreen_showFilter(dyn_dyn_anytype aesFilter, dyn_string &exceptionInfo)
{
	int pos;
	dyn_uint sysIds;
	dyn_string allDpTypes, sysNames;

	allDpTypes = dpTypeList.items;
	getSystemNames(sysNames, sysIds);

// 	if(aesFilter[fwAlarmHandlingScreen_CONFIG_OBJECT_FILTER_SYSTEM] == "*")
// 		aesFilter[fwAlarmHandlingScreen_CONFIG_OBJECT_FILTER_SYSTEM] = sysNames;

	deviceSystemTable.deleteAllLines();
  if(dynlen(aesFilter[fwAlarmHandlingScreen_CONFIG_OBJECT_FILTER_SYSTEM]) < 4)
    deviceSystemTable.vScrollBarMode = "AlwaysOff";
  else
    deviceSystemTable.vScrollBarMode = "Auto";
  
  while(dynlen(aesFilter[fwAlarmHandlingScreen_CONFIG_OBJECT_FILTER_SYSTEM]) < 4)
    dynAppend(aesFilter[fwAlarmHandlingScreen_CONFIG_OBJECT_FILTER_SYSTEM], "");

	deviceSystemTable.appendLines(dynlen(aesFilter[fwAlarmHandlingScreen_CONFIG_OBJECT_FILTER_SYSTEM]),
						"systemName", aesFilter[fwAlarmHandlingScreen_CONFIG_OBJECT_FILTER_SYSTEM]);
  deviceSystemTable.lineVisible = 0;
  
	deviceAlias.text = aesFilter[fwAlarmHandlingScreen_CONFIG_OBJECT_FILTER_DP_ALIAS];
	deviceDescription.text = aesFilter[fwAlarmHandlingScreen_CONFIG_OBJECT_FILTER_DESCRIPTION];
	deviceName.text = aesFilter[fwAlarmHandlingScreen_CONFIG_OBJECT_FILTER_DP_NAME];
	pos = dynContains(allDpTypes, aesFilter[fwAlarmHandlingScreen_CONFIG_OBJECT_FILTER_DP_TYPE][1]);
	deviceType.selectedPos = pos;
	alarmText.text = aesFilter[fwAlarmHandlingScreen_CONFIG_OBJECT_FILTER_ALERT_TEXT];
	alarmState.selectedPos = (int)aesFilter[fwAlarmHandlingScreen_CONFIG_OBJECT_FILTER_ALERT_STATE][1] + 1;
	
	showWarnings.toggleState = aesFilter[fwAlarmHandlingScreen_CONFIG_OBJECT_FILTER_SEVERITY][fwAlarmHandlingScreen_SEVERITY_FILTER_OBJECT_WARNING];
	showErrors.toggleState = aesFilter[fwAlarmHandlingScreen_CONFIG_OBJECT_FILTER_SEVERITY][fwAlarmHandlingScreen_SEVERITY_FILTER_OBJECT_ERROR];
	showFatals.toggleState = aesFilter[fwAlarmHandlingScreen_CONFIG_OBJECT_FILTER_SEVERITY][fwAlarmHandlingScreen_SEVERITY_FILTER_OBJECT_FATAL];
  showLocalOrGlobal.selectedPos = ((int)aesFilter[fwAlarmHandlingScreen_CONFIG_OBJECT_FILTER_LOCAL_OR_GLOBAL][1] + 1);
}

/** Reads the filter options from the given filter configuration data point

@par Constraints
	Only works with JCOP FW Alarm filter configuration DPs (DPT="fwAlarmHandlingScreen_FILTER_DP_TYPE")

@par Usage
	Public

@par PVSS managers
	VISION, CTRL

@param fwAesConfigDp		The filter configuration data point to read from
@param aesFilter		The filter object with the filter data is returned here
				Use the fwAlarmHandlingScreen_CONFIG_OBJECT_FILTER_XXX constants to interpret the object
@param exceptionInfo		Details of any exceptions are returned here   
*/
fwAlarmHandlingScreen_loadFilter(string fwAesConfigDp, dyn_dyn_anytype &aesFilter, dyn_string &exceptionInfo)
{
	if(!dpExists(fwAesConfigDp))
	{
		fwException_raise(exceptionInfo, "ERROR", "The alarm screen config dp \"" + fwAesConfigDp + "\" does not exist", "");
		return;
	}

	dpGet(	fwAesConfigDp + fwAlarmHandlingScreen_CONFIG_DP_FILTER_DP_NAME, 	aesFilter[fwAlarmHandlingScreen_CONFIG_OBJECT_FILTER_DP_NAME],
		fwAesConfigDp + fwAlarmHandlingScreen_CONFIG_DP_FILTER_DP_ALIAS, 	aesFilter[fwAlarmHandlingScreen_CONFIG_OBJECT_FILTER_DP_ALIAS],
		fwAesConfigDp + fwAlarmHandlingScreen_CONFIG_DP_FILTER_DP_TYPE, 	aesFilter[fwAlarmHandlingScreen_CONFIG_OBJECT_FILTER_DP_TYPE],
		fwAesConfigDp + fwAlarmHandlingScreen_CONFIG_DP_FILTER_SYSTEM, 		aesFilter[fwAlarmHandlingScreen_CONFIG_OBJECT_FILTER_SYSTEM],
		fwAesConfigDp + fwAlarmHandlingScreen_CONFIG_DP_FILTER_LOCAL_OR_GLOBAL, 	aesFilter[fwAlarmHandlingScreen_CONFIG_OBJECT_FILTER_LOCAL_OR_GLOBAL][1],
		fwAesConfigDp + fwAlarmHandlingScreen_CONFIG_DP_FILTER_WARNING, 	aesFilter[fwAlarmHandlingScreen_CONFIG_OBJECT_FILTER_SEVERITY][fwAlarmHandlingScreen_SEVERITY_FILTER_OBJECT_WARNING],
		fwAesConfigDp + fwAlarmHandlingScreen_CONFIG_DP_FILTER_ERROR, 		aesFilter[fwAlarmHandlingScreen_CONFIG_OBJECT_FILTER_SEVERITY][fwAlarmHandlingScreen_SEVERITY_FILTER_OBJECT_ERROR],
		fwAesConfigDp + fwAlarmHandlingScreen_CONFIG_DP_FILTER_FATAL, 		aesFilter[fwAlarmHandlingScreen_CONFIG_OBJECT_FILTER_SEVERITY][fwAlarmHandlingScreen_SEVERITY_FILTER_OBJECT_FATAL],
		fwAesConfigDp + fwAlarmHandlingScreen_CONFIG_DP_FILTER_ALERT_TEXT, 	aesFilter[fwAlarmHandlingScreen_CONFIG_OBJECT_FILTER_ALERT_TEXT],
		fwAesConfigDp + fwAlarmHandlingScreen_CONFIG_DP_FILTER_DESCRIPTION, 	aesFilter[fwAlarmHandlingScreen_CONFIG_OBJECT_FILTER_DESCRIPTION],
		fwAesConfigDp + fwAlarmHandlingScreen_CONFIG_DP_FILTER_SUMMARIES, 	aesFilter[fwAlarmHandlingScreen_CONFIG_OBJECT_FILTER_SUMMARIES],
		fwAesConfigDp + fwAlarmHandlingScreen_CONFIG_DP_FILTER_ALERT_STATE, 	aesFilter[fwAlarmHandlingScreen_CONFIG_OBJECT_FILTER_ALERT_STATE][1]);
}

/** Saves the filter options to the given filter configuration data point

@par Constraints
	Only works with JCOP FW Alarm filter configuration DPs (DPT="fwAlarmHandlingScreen_FILTER_DP_TYPE")

@par Usage
	Public

@par PVSS managers
	VISION, CTRL

@param fwAesConfigDp		The filter configuration data point to write to
@param aesFilter		The filter object with the filter data is passed here
				Use the fwAlarmHandlingScreen_CONFIG_OBJECT_FILTER_XXX constants to interpret the object
@param exceptionInfo		Details of any exceptions are returned here   
*/
fwAlarmHandlingScreen_saveFilter(string fwAesConfigDp, dyn_dyn_anytype aesFilter, dyn_string &exceptionInfo)
{
	dyn_errClass errors;

	if(!dpExists(fwAesConfigDp))
	{
		fwException_raise(exceptionInfo, "ERROR", "The alarm screen config dp \"" + fwAesConfigDp + "\" does not exist", "");
		return;
	}

	dpSetWait(	fwAesConfigDp + fwAlarmHandlingScreen_CONFIG_DP_FILTER_DP_NAME, 	aesFilter[fwAlarmHandlingScreen_CONFIG_OBJECT_FILTER_DP_NAME],
			fwAesConfigDp + fwAlarmHandlingScreen_CONFIG_DP_FILTER_DP_ALIAS, 	aesFilter[fwAlarmHandlingScreen_CONFIG_OBJECT_FILTER_DP_ALIAS],
			fwAesConfigDp + fwAlarmHandlingScreen_CONFIG_DP_FILTER_DP_TYPE, 	aesFilter[fwAlarmHandlingScreen_CONFIG_OBJECT_FILTER_DP_TYPE],
			fwAesConfigDp + fwAlarmHandlingScreen_CONFIG_DP_FILTER_SYSTEM, 		aesFilter[fwAlarmHandlingScreen_CONFIG_OBJECT_FILTER_SYSTEM],
		        fwAesConfigDp + fwAlarmHandlingScreen_CONFIG_DP_FILTER_LOCAL_OR_GLOBAL, 	aesFilter[fwAlarmHandlingScreen_CONFIG_OBJECT_FILTER_LOCAL_OR_GLOBAL][1],
			fwAesConfigDp + fwAlarmHandlingScreen_CONFIG_DP_FILTER_WARNING, 	aesFilter[fwAlarmHandlingScreen_CONFIG_OBJECT_FILTER_SEVERITY][fwAlarmHandlingScreen_SEVERITY_FILTER_OBJECT_WARNING],
			fwAesConfigDp + fwAlarmHandlingScreen_CONFIG_DP_FILTER_ERROR, 		aesFilter[fwAlarmHandlingScreen_CONFIG_OBJECT_FILTER_SEVERITY][fwAlarmHandlingScreen_SEVERITY_FILTER_OBJECT_ERROR],
			fwAesConfigDp + fwAlarmHandlingScreen_CONFIG_DP_FILTER_FATAL, 		aesFilter[fwAlarmHandlingScreen_CONFIG_OBJECT_FILTER_SEVERITY][fwAlarmHandlingScreen_SEVERITY_FILTER_OBJECT_FATAL],
			fwAesConfigDp + fwAlarmHandlingScreen_CONFIG_DP_FILTER_ALERT_TEXT, 	aesFilter[fwAlarmHandlingScreen_CONFIG_OBJECT_FILTER_ALERT_TEXT],
			fwAesConfigDp + fwAlarmHandlingScreen_CONFIG_DP_FILTER_DESCRIPTION, 	aesFilter[fwAlarmHandlingScreen_CONFIG_OBJECT_FILTER_DESCRIPTION],
			fwAesConfigDp + fwAlarmHandlingScreen_CONFIG_DP_FILTER_SUMMARIES, 	2,
			fwAesConfigDp + fwAlarmHandlingScreen_CONFIG_DP_FILTER_ALERT_STATE, 	aesFilter[fwAlarmHandlingScreen_CONFIG_OBJECT_FILTER_ALERT_STATE][1]);

	errors = getLastError(); 
	if(dynlen(errors) > 0)
	{ 
		throwError(errors);
		fwException_raise(exceptionInfo, "ERROR", "fwAlarmHandlingScreen_saveFilter(): Could not save the alarm screen filter.", "");
	}
}

/** Applies the given filter options to the given PVSS runtime properties dp.  The given PVSS runtime dp should be the
one that corresponds to the alarm screen display you want to update.
This can be obtained using "aes_getPropDpName()" and the dp should be of type "_AESProperties".

@par Constraints
	None

@par Usage
	Public

@par PVSS managers
	VISION, CTRL

@param pvssAesPropertiesDp	The PVSS runtime properties dp for the given alarm screen
@param aesFilter		The filter object with the filter data is passed here
				Use the fwAlarmHandlingScreen_CONFIG_OBJECT_FILTER_XXX constants to interpret the object
@param exceptionInfo		Details of any exceptions are returned here   
@param updateAes		OPTIONAL PARAMETER - default value TRUE
					If TRUE, perform aes_doRestart after setting the new filter
					If FALSE, do not perform aes_doRestart   
*/
fwAlarmHandlingScreen_applyFilter(string pvssAesPropertiesDp, dyn_dyn_anytype aesFilter, dyn_string &exceptionInfo, bool updateAes = TRUE)
{
	bool showAllSystems = FALSE;
	string severityFilter;
	dyn_uint sysIds;
	dyn_string sysNames, dpList;
	dyn_errClass errors;

	if(dynContains(aesFilter[fwAlarmHandlingScreen_CONFIG_OBJECT_FILTER_SYSTEM], "*") > 0)
		getSystemNames(sysNames, sysIds);
	else
		sysNames = aesFilter[fwAlarmHandlingScreen_CONFIG_OBJECT_FILTER_SYSTEM];
	
	_fwAlarmHandlingScreen_removeAsteriskFilters(aesFilter[fwAlarmHandlingScreen_CONFIG_OBJECT_FILTER_SYSTEM], exceptionInfo);
	_fwAlarmHandlingScreen_removeAsteriskFilters(aesFilter[fwAlarmHandlingScreen_CONFIG_OBJECT_FILTER_DP_NAME], exceptionInfo);
	_fwAlarmHandlingScreen_removeAsteriskFilters(aesFilter[fwAlarmHandlingScreen_CONFIG_OBJECT_FILTER_DP_ALIAS], exceptionInfo);
	_fwAlarmHandlingScreen_removeAsteriskFilters(aesFilter[fwAlarmHandlingScreen_CONFIG_OBJECT_FILTER_DP_TYPE], exceptionInfo);
	_fwAlarmHandlingScreen_removeAsteriskFilters(aesFilter[fwAlarmHandlingScreen_CONFIG_OBJECT_FILTER_ALERT_TEXT], exceptionInfo);
	_fwAlarmHandlingScreen_removeAsteriskFilters(aesFilter[fwAlarmHandlingScreen_CONFIG_OBJECT_FILTER_DESCRIPTION], exceptionInfo);

	fwAlarmHandlingScreen_evaluateDpFilter(aesFilter, dpList, exceptionInfo);
//DebugN(dpList);
	fwAlarmHandlingScreen_evaluateSeverityFilter(aesFilter, severityFilter, exceptionInfo, aesFilter[fwAlarmHandlingScreen_CONFIG_OBJECT_FILTER_LOCAL_OR_GLOBAL][1]);
		
	dpSetWait(	pvssAesPropertiesDp + ".Settings.Config", 				fwAlarmHandlingScreen_PVSS_PROPERTIES_DP,
			pvssAesPropertiesDp + fwAlarmHandlingScreen_PVSS_DP_FILTER_DP_LIST, 	dpList,
			pvssAesPropertiesDp + fwAlarmHandlingScreen_PVSS_DP_FILTER_ALERT_TEXT, 	aesFilter[fwAlarmHandlingScreen_CONFIG_OBJECT_FILTER_ALERT_TEXT],
			pvssAesPropertiesDp + fwAlarmHandlingScreen_PVSS_DP_FILTER_COMMENT, 	aesFilter[fwAlarmHandlingScreen_CONFIG_OBJECT_FILTER_DESCRIPTION],
			pvssAesPropertiesDp + fwAlarmHandlingScreen_PVSS_DP_FILTER_LOGIC,	1,
			pvssAesPropertiesDp + fwAlarmHandlingScreen_PVSS_DP_FILTER_PRIORITY,	severityFilter,
//			pvssAesPropertiesDp + fwAlarmHandlingScreen_PVSS_DP_FILTER_SUMMARIES,	2,
			pvssAesPropertiesDp + fwAlarmHandlingScreen_PVSS_DP_FILTER_SYSTEMS,	sysNames,
			pvssAesPropertiesDp + fwAlarmHandlingScreen_PVSS_DP_FILTER_ALL_SYSTEMS,	FALSE,
			pvssAesPropertiesDp + fwAlarmHandlingScreen_PVSS_DP_FILTER_ALERT_STATE,	aesFilter[fwAlarmHandlingScreen_CONFIG_OBJECT_FILTER_ALERT_STATE][1]
			);
						
	errors = getLastError(); 
	if(dynlen(errors) > 0)
	{ 
		throwError(errors);
		fwException_raise(exceptionInfo, "ERROR", "fwAlarmHandlingScreen_applyFilter(): Could not apply the alarm screen filter.", "");
	}

	if(updateAes)
		aes_doRestart(pvssAesPropertiesDp, FALSE);
}

/** Calculates from the given filter options, the most compact filter to pass to the PVSS runtime properties dp.
For simple filters, this could involve just the DP name filter - e.g. "CAEN/*".
However, for more complex filters, it will usually be a list of DPs that match all the filter criteria.

@par Constraints
	None

@par Usage
	Public

@par PVSS managers
	VISION, CTRL

@param aesFilter		The filter object with the filter data is passed here
				Use the fwAlarmHandlingScreen_CONFIG_OBJECT_FILTER_XXX constants to interpret the object
@param evaluatedFilter		The most compact form to express the result of the filter is returned here   
@param exceptionInfo		Details of any exceptions are returned here   
*/
fwAlarmHandlingScreen_evaluateDpFilter(dyn_dyn_anytype aesFilter, dyn_string &evaluatedFilter, dyn_string &exceptionInfo)
{
	int dpNameFilters, dpAliasFilters;
		
	dpNameFilters = dynlen(aesFilter[fwAlarmHandlingScreen_CONFIG_OBJECT_FILTER_DP_NAME]);
	dpAliasFilters = dynlen(aesFilter[fwAlarmHandlingScreen_CONFIG_OBJECT_FILTER_DP_ALIAS]);

	if(dynlen(aesFilter[fwAlarmHandlingScreen_CONFIG_OBJECT_FILTER_DP_TYPE]) == 0)
	{
		if((dpNameFilters == 0) && (dpAliasFilters == 0))
			evaluatedFilter = makeDynString();
		else if((dpNameFilters == 1) && (dpAliasFilters == 0))
		{
			evaluatedFilter[1] = aesFilter[fwAlarmHandlingScreen_CONFIG_OBJECT_FILTER_DP_NAME][1];

			if(strpos(evaluatedFilter[1], ":") < 0)
				evaluatedFilter[1] = "*:" + evaluatedFilter[1];
		}
//this next case is removed because the alerts are usually not defined on the same DPE as the alias
//		else if((dpNameFilters == 0) && (dpAliasFilters == 1))
//			evaluatedFilter[1] = "*:@" + aesFilter[fwAlarmHandlingScreen_CONFIG_OBJECT_FILTER_DP_ALIAS][1];
		else
		{
			fwAlarmHandling_getDpsMatchingCriteria(	aesFilter[fwAlarmHandlingScreen_CONFIG_OBJECT_FILTER_SYSTEM],
																		aesFilter[fwAlarmHandlingScreen_CONFIG_OBJECT_FILTER_DP_NAME],
																		aesFilter[fwAlarmHandlingScreen_CONFIG_OBJECT_FILTER_DP_ALIAS],
																		aesFilter[fwAlarmHandlingScreen_CONFIG_OBJECT_FILTER_DP_TYPE],
																		evaluatedFilter, exceptionInfo);
			if(dynlen(evaluatedFilter) == 0)
				evaluatedFilter[1] = "/";
		}
	}
	else
	{
		fwAlarmHandling_getDpsMatchingCriteria(	aesFilter[fwAlarmHandlingScreen_CONFIG_OBJECT_FILTER_SYSTEM],
																	aesFilter[fwAlarmHandlingScreen_CONFIG_OBJECT_FILTER_DP_NAME],
																	aesFilter[fwAlarmHandlingScreen_CONFIG_OBJECT_FILTER_DP_ALIAS],
																	aesFilter[fwAlarmHandlingScreen_CONFIG_OBJECT_FILTER_DP_TYPE],
																	evaluatedFilter, exceptionInfo);
		if(dynlen(evaluatedFilter) == 0)
			evaluatedFilter[1] = "/";
	}
//DebugN(evaluatedFilter);
}

/** Sets any "*" filters to "".  The PVSS alarm screen requires "" instead of "*" to mean ALL for some filtering criteria.
If any other criteria are given as well as a "*", then they are ignored as everything will already meet the "*" criteria.

@par Constraints
	None

@par Usage
	Internal

@par PVSS managers
	VISION, CTRL

@param filter			Input/Output - The filter to reduce and make ready for the PVSS alarm screen
@param exceptionInfo		Details of any exceptions are returned here   
*/
_fwAlarmHandlingScreen_removeAsteriskFilters(dyn_string &filter, dyn_string &exceptionInfo)
{
	if(dynContains(filter, "*") > 0)
		filter = makeDynString();
}

/** Calculates from the given filter options, the priority filter which needs to be passed to the PVSS runtime properties dp.
This function basically converts from FW severity (W,E,F) to PVSS priorities (40-59,60-79,80-255)

@par Constraints
	None

@par Usage
	Public

@par PVSS managers
	VISION, CTRL

@param aesFilter		The filter object with the filter data is passed here
				Use the fwAlarmHandlingScreen_CONFIG_OBJECT_FILTER_XXX constants to interpret the object
@param evaluatedFilter		The priority filter for the PVSS alarm screen is returned here   
@param exceptionInfo		Details of any exceptions are returned here   
@param localOrGlobal            Optional parameter - default value 0
                                If 0, show all alerts in ranges (e.g. 40-59 for WARNING)
                                If 1, show upper part of ranges - assumed to be global alerts (e.g. 50-59 for WARNING)
                                If 2, show lower part of ranges - assumed to be local alerts (e.g. 40-49 for WARNING)
*/
fwAlarmHandlingScreen_evaluateSeverityFilter(dyn_dyn_anytype aesFilter, string &evaluatedFilter, dyn_string &exceptionInfo, int localOrGlobal = 0)
{  
  const int GLOBAL_ONLY = 1, LOCAL_ONLY = 2;
  string filterPart;
  
  evaluatedFilter = "";

  if(aesFilter[fwAlarmHandlingScreen_CONFIG_OBJECT_FILTER_SEVERITY][fwAlarmHandlingScreen_SEVERITY_FILTER_OBJECT_WARNING])
  {
    switch(localOrGlobal)
    {
      case GLOBAL_ONLY:
        filterPart = "1,50-59";
        break;
      case LOCAL_ONLY:
        filterPart = "1,40-49";
        break;
      default:
        filterPart = "1,40-59";
        break;   
    }
//     if(useRDBArchive())
//       _fwAlarmHandling_convertSeverityRangeToList(filterPart, filterPart, exceptionInfo);
    evaluatedFilter += (filterPart + ",");
  }
  if(aesFilter[fwAlarmHandlingScreen_CONFIG_OBJECT_FILTER_SEVERITY][fwAlarmHandlingScreen_SEVERITY_FILTER_OBJECT_ERROR])
  {
    switch(localOrGlobal)
    {
      case GLOBAL_ONLY:
        filterPart = "1,70-79";
        break;
      case LOCAL_ONLY:
        filterPart = "1,60-69";
        break;
      default:
        filterPart = "1,60-79";
        break;   
    }
//     if(useRDBArchive())
//       _fwAlarmHandling_convertSeverityRangeToList(filterPart, filterPart, exceptionInfo);
    evaluatedFilter += (filterPart + ",");
  }
  if(aesFilter[fwAlarmHandlingScreen_CONFIG_OBJECT_FILTER_SEVERITY][fwAlarmHandlingScreen_SEVERITY_FILTER_OBJECT_FATAL])
  {
    switch(localOrGlobal)
    {
      case GLOBAL_ONLY:
        filterPart = "1,90-255";
        break;
      case LOCAL_ONLY:
        filterPart = "1,80-89";
        break;
      default:
        filterPart = "1,80-255";
        break;   
    }
//     if(useRDBArchive())
//       _fwAlarmHandling_convertSeverityRangeToList(filterPart, filterPart, exceptionInfo);
    evaluatedFilter += (filterPart + ",");
  }
		
  if(strlen(evaluatedFilter) == 0)
    evaluatedFilter = 255;
		
  evaluatedFilter = strrtrim(evaluatedFilter, ",");
}

//required to fix problem existing in PVSS 3.8 with queries to RDB not handling priority ranges.
//not needed anymore since patch P041
_fwAlarmHandling_convertSeverityRangeToList(string severityRange, string &severityList, dyn_string &exceptionInfo)
{
  dyn_int rangeLimits;

  severityList = "";

  rangeLimits = strsplit(severityRange, "-");
  if(dynlen(rangeLimits) < 2)
    return;
  
  for(int i=rangeLimits[1]; i<=rangeLimits[2]; i++)
  {
    severityList += (i + ",");
  }
  
  severityList = strrtrim(severityList, ",");
}


/** Gets a filter object configured with the default filter criteria (basically ALL)

@par Constraints
	None

@par Usage
	Internal

@par PVSS managers
	VISION, CTRL

@param aesFilter		The filter object is returned here with the default filter criteria
				Use the fwAlarmHandlingScreen_CONFIG_OBJECT_FILTER_XXX constants to interpret the object
@param exceptionInfo		Details of any exceptions are returned here   
*/
_fwAlarmHandlingScreen_getDefaultFilter(dyn_dyn_anytype &aesFilter, dyn_string &exceptionInfo)
{
  string defaultFilterName;
  
  fwAlarmHandlingScreen_getDefaultFilterName(defaultFilterName, exceptionInfo);
  if(defaultFilterName != "")
  {
    fwAlarmHandlingScreen_loadFilter(defaultFilterName, aesFilter, exceptionInfo);
  }
  else
  {    
  	aesFilter[fwAlarmHandlingScreen_CONFIG_OBJECT_FILTER_SYSTEM] = "*";
		
  	aesFilter[fwAlarmHandlingScreen_CONFIG_OBJECT_FILTER_DP_ALIAS] = "*";
  	aesFilter[fwAlarmHandlingScreen_CONFIG_OBJECT_FILTER_DESCRIPTION] = "*";
  	aesFilter[fwAlarmHandlingScreen_CONFIG_OBJECT_FILTER_DP_NAME] = "*";
  	aesFilter[fwAlarmHandlingScreen_CONFIG_OBJECT_FILTER_DP_TYPE] = "*";
  	aesFilter[fwAlarmHandlingScreen_CONFIG_OBJECT_FILTER_ALERT_TEXT] = "*";
  	aesFilter[fwAlarmHandlingScreen_CONFIG_OBJECT_FILTER_ALERT_STATE][1] = 0;
  	
  	aesFilter[fwAlarmHandlingScreen_CONFIG_OBJECT_FILTER_LOCAL_OR_GLOBAL][1] = 0;
  	aesFilter[fwAlarmHandlingScreen_CONFIG_OBJECT_FILTER_SEVERITY][fwAlarmHandlingScreen_SEVERITY_FILTER_OBJECT_WARNING] = TRUE;
  	aesFilter[fwAlarmHandlingScreen_CONFIG_OBJECT_FILTER_SEVERITY][fwAlarmHandlingScreen_SEVERITY_FILTER_OBJECT_ERROR] = TRUE;
  	aesFilter[fwAlarmHandlingScreen_CONFIG_OBJECT_FILTER_SEVERITY][fwAlarmHandlingScreen_SEVERITY_FILTER_OBJECT_FATAL] = TRUE;
  }
}

/** Gets a mode object configured with the default mode options for the alarm screen

@par Constraints
	None

@par Usage
	Internal

@par PVSS managers
	VISION, CTRL

@param aesMode			The mode object is returned here with the default filter criteria
				Use the fwAlarmHandlingScreen_CONFIG_OBJECT_MODE_XXX constants to interpret the object
@param exceptionInfo		Details of any exceptions are returned here   
*/
_fwAlarmHandlingScreen_getDefaultMode(dyn_anytype &aesMode, dyn_string &exceptionInfo)
{
	aesMode[fwAlarmHandlingScreen_CONFIG_OBJECT_MODE_TYPE] = AES_MODE_CURRENT;
	aesMode[fwAlarmHandlingScreen_CONFIG_OBJECT_MODE_START_TIME] = getCurrentTime() - 3600;
	aesMode[fwAlarmHandlingScreen_CONFIG_OBJECT_MODE_END_TIME] = getCurrentTime();
	aesMode[fwAlarmHandlingScreen_CONFIG_OBJECT_MODE_MAX_LINES] = 0;
}

/** Reads the mode options from the alarm screen mode graphical objects

@par Constraints
	The function can only be called from within the JCOP FW Alarm Screen

@par Usage
	Public

@par PVSS managers
	VISION

@param aesMode			The mode object is returned here with the mode criteria as defined in the graphical objects
				Use the fwAlarmHandlingScreen_CONFIG_OBJECT_MODE_XXX constants to interpret the object
@param exceptionInfo		Details of any exceptions are returned here   
*/
fwAlarmHandlingScreen_readMode(dyn_anytype &aesMode, dyn_string &exceptionInfo)
{
	time startTime, endTime;
	int maxLines;
	startTime = hiddenStartTime.text;
	endTime = hiddenEndTime.text;
  fwAlarmHandlingScreen_getHistoricalMaxLines(maxLines,exceptionInfo);
	if(aesModeSelector.number == 0)
		aesMode[fwAlarmHandlingScreen_CONFIG_OBJECT_MODE_TYPE] = AES_MODE_CURRENT;
	else
		aesMode[fwAlarmHandlingScreen_CONFIG_OBJECT_MODE_TYPE] = AES_MODE_CLOSED;
		
	aesMode[fwAlarmHandlingScreen_CONFIG_OBJECT_MODE_START_TIME] = startTime;
	aesMode[fwAlarmHandlingScreen_CONFIG_OBJECT_MODE_END_TIME] = endTime;
	aesMode[fwAlarmHandlingScreen_CONFIG_OBJECT_MODE_MAX_LINES] = maxLines;  
}

/** Shows the given mode options in the alarm screen mode graphical objects

@par Constraints
	The function can only be called from within the JCOP FW Alarm Screen

@par Usage
	Public

@par PVSS managers
	VISION

@param aesMode			The mode object with the mode data to display in the graphical objects
				Use the fwAlarmHandlingScreen_CONFIG_OBJECT_MODE_XXX constants to interpret the object
@param exceptionInfo		Details of any exceptions are returned here   
*/
fwAlarmHandlingScreen_showMode(dyn_anytype &aesMode, dyn_string &exceptionInfo)
{
	if(aesMode[fwAlarmHandlingScreen_CONFIG_OBJECT_MODE_TYPE] == AES_MODE_CURRENT)
		aesModeSelector.number = 0;
	else
		aesModeSelector.number = 1;
		
	startHistoricalTime.text(formatTime(fwAlarmHandlingScreen_HISTORICAL_TIME_FORMAT, aesMode[fwAlarmHandlingScreen_CONFIG_OBJECT_MODE_START_TIME]));
	endHistoricalTime.text(formatTime(fwAlarmHandlingScreen_HISTORICAL_TIME_FORMAT, aesMode[fwAlarmHandlingScreen_CONFIG_OBJECT_MODE_END_TIME]));
}


/** Applies the given mode options to the given PVSS runtime properties dp.  The given PVSS runtime dp should be the
one that corresponds to the alarm screen display you want to update.
This can be obtained using "aes_getPropDpName()" and the dp should be of type "_AESProperties".

@par Constraints
	None

@par Usage
	Public

@par PVSS managers
	VISION, CTRL

@param pvssAesPropertiesDp	The PVSS runtime properties dp for the given alarm screen
@param aesMode			The mode object with the mode data is passed here
				Use the fwAlarmHandlingScreen_CONFIG_OBJECT_MODE_XXX constants to interpret the object
@param exceptionInfo		Details of any exceptions are returned here   
@param updateAes		OPTIONAL PARAMETER - default value TRUE
					If TRUE, perform aes_doRestart after setting the new mode
					If FALSE, do not perform aes_doRestart   
*/
fwAlarmHandlingScreen_applyMode(string pvssAesPropertiesDp, dyn_anytype aesMode, dyn_string &exceptionInfo, bool updateAes = TRUE)
{
	dyn_errClass errors;
  dyn_string systems;
// 	DebugN("pvssAesPropertiesDp: "+pvssAesPropertiesDp);
   
    //update systems store to reinitiated check of dist systems (if running)
    dpGet(g_sPvssPropertiesDp + ".Both.Systems.Selections", systems);
  
	dpSetWait(	pvssAesPropertiesDp + ".Settings.Config", 		fwAlarmHandlingScreen_PVSS_PROPERTIES_DP,
			pvssAesPropertiesDp + ".Both.Timerange.Type", 		 aesMode[fwAlarmHandlingScreen_CONFIG_OBJECT_MODE_TYPE],
			pvssAesPropertiesDp + ".Both.Timerange.Begin",	   aesMode[fwAlarmHandlingScreen_CONFIG_OBJECT_MODE_START_TIME],
			pvssAesPropertiesDp + ".Both.Timerange.End",      aesMode[fwAlarmHandlingScreen_CONFIG_OBJECT_MODE_END_TIME],
			pvssAesPropertiesDp + ".Both.Timerange.MaxLines", 	aesMode[fwAlarmHandlingScreen_CONFIG_OBJECT_MODE_MAX_LINES],
			pvssAesPropertiesDp + ".Both.Timerange.Selection", 	6,
			pvssAesPropertiesDp + ".Both.Timerange.Shift", 		1,
     pvssAesPropertiesDp + ".Both.Systems.Selections", systems );

	errors = getLastError(); 
	if(dynlen(errors) > 0)
	{ 
		throwError(errors);
		fwException_raise(exceptionInfo, "ERROR", "fwAlarmHandlingScreen_applyMode(): Could not the alarm screen configuration.", "");
	}
	
	if(updateAes)
		aes_doRestart(pvssAesPropertiesDp, FALSE);

}

/** This function converts a filter configuration object into a string value that can be passed as a dollar parameter.
To decode the string back into a filter ibject, use _fwAlarmHandlingScreen_convertDollarToFilter().

@par Constraints
	None

@par Usage
	Internal

@par PVSS managers
	VISION, CTRL

@param aesFilter		The filter object with the filter data is passed here
					Use the fwAlarmHandlingScreen_CONFIG_OBJECT_FILTER_XXX constants to interpret the object
@param dollarValue	The string value to be passed as a dollar parameter is returned here
@param exceptionInfo	Details of any exceptions are returned here   
*/
_fwAlarmHandlingScreen_convertFilterToDollar(dyn_dyn_anytype aesFilter, string &dollarValue, dyn_string &exceptionInfo)
{
	int i, length;
	dyn_string filterEntries;

	length = dynlen(aesFilter);
	for(i=1; i<=length; i++)
		fwGeneral_dynStringToString(aesFilter[i], filterEntries[i], "$");

	fwGeneral_dynStringToString(filterEntries, dollarValue, "|");
}

/** This function converts a string representation of a filter into a filter object.
To decode the string back into a filter object, use _fwAlarmHandlingScreen_convertFilterToDollar().

@par Constraints
	None

@par Usage
	Internal

@par PVSS managers
	VISION, CTRL

@param dollarValue	The string equivalent of the filter object is passed here
@param aesFilter		The filter object with the filter data is returned here
					Use the fwAlarmHandlingScreen_CONFIG_OBJECT_FILTER_XXX constants to interpret the object
@param exceptionInfo	Details of any exceptions are returned here   
*/
_fwAlarmHandlingScreen_convertDollarToFilter(string dollarValue, dyn_dyn_anytype &aesFilter, dyn_string &exceptionInfo)
{
	int i, length;
	dyn_string filterEntries;

	fwGeneral_stringToDynString(dollarValue, filterEntries, "|", FALSE, FALSE);

	length = dynlen(filterEntries);
	for(i=1; i<=length; i++)
		fwGeneral_stringToDynString(filterEntries[i], aesFilter[i], "$");
}

/** Changes the visibility of the named column in the Alarm Screen.  The given PVSS runtime dp should be the
one that corresponds to the alarm screen display you want to update.
This can be obtained using "aes_getPropDpName()" and the dp should be of type "_AESProperties".

@par Constraints
	None

@par Usage
	Internal

@par PVSS managers
	VISION, CTRL

@param pvssAesPropertiesDp	The PVSS runtime properties dp for the given alarm screen
@param columnName			The name of the column to be hidden/shown
@param visible			TRUE to show column, FALSE to hide columns
@param exceptionInfo		Details of any exceptions are returned here   
@param updateAes			OPTIONAL PARAMETER - default value TRUE
						If TRUE, perform aes_doRestart after setting the new filter
						If FALSE, do not perform aes_doRestart   
*/
_fwAlarmHandlingScreen_showHideColumn(string pvssAesPropertiesDp, string columnName, bool visible, dyn_string &exceptionInfo, bool updateAes = FALSE)
{
	int pos;
	dyn_string visibleColumns;

	dpGet(pvssAesPropertiesDp + ".Both.Visible.VisibleColumns", visibleColumns);
	pos = dynContains(visibleColumns, columnName);
	
	if(visible)
	{
		if(pos <= 0)
			dynAppend(visibleColumns, columnName);
	}
	else
	{
		if(pos > 0)
			dynRemove(visibleColumns, pos);	
	}
	
	dpSetWait(pvssAesPropertiesDp + ".Both.Visible.VisibleColumns", visibleColumns);

	if(updateAes)
		aes_doRestart(pvssAesPropertiesDp, FALSE);
}


/** Changes the visibility of the named columns in the Alarm Screen.  The given PVSS runtime dp should be the
one that corresponds to the alarm screen display you want to update.
This can be obtained using "aes_getPropDpName()" and the dp should be of type "_AESProperties".

@par Constraints
	None

@par Usage
	Internal

@par PVSS managers
	VISION, CTRL

@param pvssAesPropertiesDp	The PVSS runtime properties dp for the given alarm screen
@param columnName			The array of names of the columns to be hidden/shown
@param visible			The array of values for the columns: TRUE to show column, FALSE to hide column
@param exceptionInfo		Details of any exceptions are returned here   
@param updateAes			OPTIONAL PARAMETER - default value TRUE
						If TRUE, perform aes_doRestart after setting the new filter
// 						If FALSE, do not perform aes_doRestart   
*/
_fwAlarmHandlingScreen_showHideColumns(string pvssAesPropertiesDp, dyn_string columnName, dyn_bool visible, dyn_string &exceptionInfo, bool updateAes = FALSE)
{
	int pos;
  int i;
	dyn_string visibleColumns;

	dpGet(pvssAesPropertiesDp + ".Both.Visible.VisibleColumns", visibleColumns);
  
  for(i=1 ; i<=dynlen(visible) ; i++)
  {
    	pos = dynContains(visibleColumns, columnName[i]);
	
    	if(visible[i])
    	{
    		if(pos <= 0)
    			dynAppend(visibleColumns, columnName[i]);
    	}
    	else
    	{
    		if(pos > 0)
    			dynRemove(visibleColumns, pos);	
    	}
  }	
	dpSetWait(pvssAesPropertiesDp + ".Both.Visible.VisibleColumns", visibleColumns);

	if(updateAes)
		aes_doRestart(pvssAesPropertiesDp, FALSE);
}


/** Reads the column names, visibility and widths of the alarm screen table in the current panel.

@par Constraints
	None

@par Usage
	Public

@par PVSS managers
	VISION

@param columnsName		The list of names of the columns that are in the current alarm screen table.
@param columnsVisible		The list of BOOLEANs representing the current visible state of each column.
						TRUE to show column, FALSE to hide columns
@param columnsWidth		The list of the current widths of each column.
@param exceptionInfo		Details of any exceptions are returned here   
*/
fwAlarmHandlingScreen_getColumnWidths(dyn_string &columnsName, dyn_bool &columnsVisible, dyn_int &columnsWidth, dyn_string &exceptionInfo)
{
	int i, columns;
	shape aesTable;
	
	aesTable = getShape(g_sTable);
	columns = aesTable.columnCount;
	
	for(i=0; i<columns; i++)
	{
		columnsName[i+1] = aesTable.columnName(i);
		columnsWidth[i+1] = aesTable.columnWidth(i);
		columnsVisible[i+1] = aesTable.columnVisibility(i);
	}
//DebugN(columnsName, columnsWidth, columnsVisible);
}

/** Sets the column visibility and widths of the given columns in the alarm screen table in the current panel.

@par Constraints
	None

@par Usage
	Public

@par PVSS managers
	VISION

@param columnsName		The list of names of the columns to configure.
@param columnsVisible		The list of BOOLEANs representing the desired visible state of each column.
						TRUE to show column, FALSE to hide columns
@param columnsWidth		The list of desired widths of each column.
@param exceptionInfo		Details of any exceptions are returned here   
*/
fwAlarmHandlingScreen_setColumnWidths(dyn_string columnsName, dyn_bool columnsVisible, dyn_int columnsWidth, dyn_string &exceptionInfo)
{
	int i, column, columns;
	shape aesTable;
	
	aesTable = getShape(g_sTable);
	columns = dynlen(columnsName);
	
	for(i=1; i<=columns; i++)
	{
		column = aesTable.nameToColumn(columnsName[i]);
		aesTable.columnWidth(column) = columnsWidth[i];
		aesTable.columnVisibility(column) = columnsVisible[i];
	}
}

/** Sets the behaviour of the description column.  If no description exists on the alarm dpe, or the root dpe of the dp, then either an
empty string or the dpe name can be shown.

@par Constraints
	Must close and reopen the Alarm Screen to see the effect

@par Usage
	Public

@par PVSS managers
	VISION, CTRL

@param columnBehaviour		any of the constants fwAlarmHandling_BEHAVIOUR_...
@param exceptionInfo		Details of any exceptions are returned here   
*/
fwAlarmHandlingScreen_setDescriptionColumnBehaviour(int columnBehaviour, dyn_string &exceptionInfo)
{
	int pos;
	dyn_string columnNames, columnFunctions;
	
	dpGet(fwAlarmHandlingScreen_PVSS_CONFIG_DP + fwAlarmHandlingScreen_PVSS_CONFIG_COLUMN_NAMES, columnNames,
		fwAlarmHandlingScreen_PVSS_CONFIG_DP + fwAlarmHandlingScreen_PVSS_CONFIG_COLUMN_FUNCTIONS, columnFunctions);

	pos = dynContains(columnNames, fwAlarmHandlingScreen_COLUMN_DESCRIPTION);
	if(pos > 0)
	{
		if(columnBehaviour == fwAlarmHandling_BEHAVIOUR_DESCRIPTION_OR_ALIAS_OR_DP_NAME)
			columnFunctions[pos] = "fwAlarmHandling_tabUtilGetDescriptionOrAliasOrDpe";
		else if(columnBehaviour == fwAlarmHandling_BEHAVIOUR_DESCRIPTION_OR_DP_NAME)
			columnFunctions[pos] = "fwAlarmHandling_tabUtilGetDescriptionOrDpe";
		else
			columnFunctions[pos] = "fwAlarmHandling_tabUtilGetDescription";

		dpSetWait(fwAlarmHandlingScreen_PVSS_CONFIG_DP + fwAlarmHandlingScreen_PVSS_CONFIG_COLUMN_FUNCTIONS, columnFunctions);
	}
	else
		fwException_raise(exceptionInfo, "ERROR", "The description column could not be found in the AES Config.", "");
}

/** Sets one line per alarm or one line per event (i.e. one line per CAME, one line per WENT).

@par Constraints
	Must close and reopen the Alarm Screen to see the effect

@par Usage
	Public

@par PVSS managers
	VISION, CTRL

@param oneRowPerAlarm		input, TRUE - one line per alarm. CAM or WENT is shown, with the last timestamp.
					FALSE - one line for CAME, one line for WENT.
@param exceptionInfo		output, Details of any exceptions are returned here   
*/
fwAlarmHandlingScreen_setOneRowPerAlarm(bool oneRowPerAlarm, dyn_string &exceptionInfo)
{
  bool b_currentlyOneRowPerAlarm;
	fwAlarmHandlingScreen_getOneRowPerAlarm(b_currentlyOneRowPerAlarm,exceptionInfo);
  DebugN("dp: "+fwAlarmHandlingScreen_PVSS_CONFIG_DP + fwAlarmHandlingScreen_PVSS_DP_FILTER_ONE_ROW+" oneRowPerAlarm: " +oneRowPerAlarm);
  if(b_currentlyOneRowPerAlarm != oneRowPerAlarm)
	  dpSetWait(fwAlarmHandlingScreen_PVSS_CONFIG_DP + fwAlarmHandlingScreen_PVSS_DP_FILTER_ONE_ROW, oneRowPerAlarm);       
}

/** Gets one line per alarm or one line per event (i.e. one line per CAME, one line per WENT).

@par Constraints
	Must close and reopen the Alarm Screen to see the effect

@par Usage
	Public

@par PVSS managers
	VISION, CTRL

@param oneRowPerAlarm		output, TRUE - one line per alarm. CAM or WENT is shown, with the last timestamp.
					FALSE - one line for CAME, one line for WENT.
@param exceptionInfo		output, Details of any exceptions are returned here   
*/
fwAlarmHandlingScreen_getOneRowPerAlarm(bool &oneRowPerAlarm, dyn_string &exceptionInfo)
{
  bool b_currentlyOneRowPerAlarm;
	
	dpGet(fwAlarmHandlingScreen_PVSS_CONFIG_DP + fwAlarmHandlingScreen_PVSS_DP_FILTER_ONE_ROW, b_currentlyOneRowPerAlarm);
  oneRowPerAlarm = b_currentlyOneRowPerAlarm;
}

/** Gets the current behaviour of the description column.  If no description exists on the alarm dpe, or the root dpe of the dp, then either an
empty string or the dpe name can be shown.

@par Constraints
	Must close and reopen the Alarm Screen to see the effect

@par Usage
	Public

@par PVSS managers
	VISION, CTRL

@param columnBehaviour		any of the constants fwAlarmHandling_BEHAVIOUR_...
@param exceptionInfo		Details of any exceptions are returned here   
*/
fwAlarmHandlingScreen_getDescriptionColumnBehaviour(int &columnBehaviour, dyn_string &exceptionInfo)
{
	int pos;
	dyn_string columnNames, columnFunctions;
	
	dpGet(fwAlarmHandlingScreen_PVSS_CONFIG_DP + fwAlarmHandlingScreen_PVSS_CONFIG_COLUMN_NAMES, columnNames,
		fwAlarmHandlingScreen_PVSS_CONFIG_DP + fwAlarmHandlingScreen_PVSS_CONFIG_COLUMN_FUNCTIONS, columnFunctions);

	pos = dynContains(columnNames, fwAlarmHandlingScreen_COLUMN_DESCRIPTION);
	if(pos > 0)
	{
		if(columnFunctions[pos] == "fwAlarmHandling_tabUtilGetDescriptionOrAliasOrDpe")
			columnBehaviour = fwAlarmHandling_BEHAVIOUR_DESCRIPTION_OR_ALIAS_OR_DP_NAME;
		else if(columnFunctions[pos] == "fwAlarmHandling_tabUtilGetDescriptionOrDpe")
			columnBehaviour = fwAlarmHandling_BEHAVIOUR_DESCRIPTION_OR_DP_NAME;
		else
			columnBehaviour = fwAlarmHandling_BEHAVIOUR_DESCRIPTION_ONLY;
	}
	else
		fwException_raise(exceptionInfo, "ERROR", "The description column could not be found in the AES Config.", "");
}

fwAlarmHandlingScreen_getRowColourBehaviour(bool &colourWholeRow, dyn_string &exceptionInfo)
{
	int pos;
        dyn_bool useAlertClassColour;
	dyn_string columnNames;
	
	dpGet(fwAlarmHandlingScreen_PVSS_CONFIG_DP + fwAlarmHandlingScreen_PVSS_CONFIG_COLUMN_NAMES, columnNames,
		fwAlarmHandlingScreen_PVSS_CONFIG_DP + fwAlarmHandlingScreen_PVSS_CONFIG_COLUMN_BACKCOL, useAlertClassColour);

	pos = dynContains(columnNames, fwAlarmHandlingScreen_COLUMN_DESCRIPTION);
	if(pos > 0)
		colourWholeRow = useAlertClassColour[pos];
	else
		fwException_raise(exceptionInfo, "ERROR", "The description column could not be found in the AES Config.", "");
}

fwAlarmHandlingScreen_setRowColourBehaviour(bool colourWholeRow, dyn_string &exceptionInfo)
{
	int pos;
        dyn_bool useAlertClassColour;
	dyn_string columnNames;
	
	dpGet(fwAlarmHandlingScreen_PVSS_CONFIG_DP + fwAlarmHandlingScreen_PVSS_CONFIG_COLUMN_NAMES, columnNames,
		fwAlarmHandlingScreen_PVSS_CONFIG_DP + fwAlarmHandlingScreen_PVSS_CONFIG_COLUMN_BACKCOL, useAlertClassColour);

        for(int i=1; i<=dynlen(useAlertClassColour); i++)
          useAlertClassColour[i] = colourWholeRow;
        
        pos = dynContains(columnNames, fwAlarmHandlingScreen_COLUMN_SHORT_SIGN);
	if(pos > 0)
		useAlertClassColour[pos] = TRUE;
	else
		fwException_raise(exceptionInfo, "ERROR", "The short sign column could not be found in the AES Config.", "");

	pos = dynContains(columnNames, fwAlarmHandlingScreen_COLUMN_PRIORITY);
	if(pos > 0)
		useAlertClassColour[pos] = TRUE;
	else
		fwException_raise(exceptionInfo, "ERROR", "The priority column could not be found in the AES Config.", "");

	pos = dynContains(columnNames, fwAlarmHandlingScreen_COLUMN_ACKNOWLEDGE);
	if(pos > 0)
		useAlertClassColour[pos] = FALSE;
	else
		fwException_raise(exceptionInfo, "ERROR", "The priority column could not be found in the AES Config.", "");

	dpSetWait(fwAlarmHandlingScreen_PVSS_CONFIG_DP + fwAlarmHandlingScreen_PVSS_CONFIG_COLUMN_BACKCOL, useAlertClassColour);       
}

fwAlarmHandlingScreen_setScrollLockTimeout(int scrollLockTimeout, dyn_string &exceptionInfo)
{
  dpSetWait("_Config.TimeoutJumping", scrollLockTimeout);
}

fwAlarmHandlingScreen_getScrollLockTimeout(int &scrollLockTimeout, dyn_string &exceptionInfo)
{
  dpGet("_Config.TimeoutJumping", scrollLockTimeout);
}

fwAlarmHandlingScreen_setReductionMode(string pvssAesPropertiesDp, int reductionMode, dyn_string &exceptionInfo)
{
  dpSetWait(pvssAesPropertiesDp + ".Alerts.FilterTypes.AlertSummary", reductionMode);
}

fwAlarmHandlingScreen_getReductionMode(string pvssAesPropertiesDp, int &reductionMode, dyn_string &exceptionInfo)
{
  dpGet(pvssAesPropertiesDp + ".Alerts.FilterTypes.AlertSummary", reductionMode);
}

fwAlarmHandlingScreen_setAccessControlOptions(dyn_string accessRights, dyn_string &exceptionInfo)
{
  dpSetWait("_FwAesSetup.accessControl.acknowledge", accessRights[fwAlarmHandlingScreen_ACCESS_ACKNOWLEDGE],
            "_FwAesSetup.accessControl.comment", accessRights[fwAlarmHandlingScreen_ACCESS_COMMENT],
            "_FwAesSetup.accessControl.rightClick", accessRights[fwAlarmHandlingScreen_ACCESS_RIGHT_CLICK],
            "_FwAesSetup.accessControl.filters", accessRights[fwAlarmHandlingScreen_ACCESS_FILTER],
            "_FwAesSetup.accessControl.manageDisplay", accessRights[fwAlarmHandlingScreen_ACCESS_MANAGE_DISPLAY]); 
}
    
fwAlarmHandlingScreen_getAccessControlOptions(dyn_string &accessRights, dyn_string &exceptionInfo)
{
  dpGet("_FwAesSetup.accessControl.acknowledge", accessRights[fwAlarmHandlingScreen_ACCESS_ACKNOWLEDGE],
        "_FwAesSetup.accessControl.comment", accessRights[fwAlarmHandlingScreen_ACCESS_COMMENT],
        "_FwAesSetup.accessControl.rightClick", accessRights[fwAlarmHandlingScreen_ACCESS_RIGHT_CLICK],
        "_FwAesSetup.accessControl.filters", accessRights[fwAlarmHandlingScreen_ACCESS_FILTER],
        "_FwAesSetup.accessControl.manageDisplay", accessRights[fwAlarmHandlingScreen_ACCESS_MANAGE_DISPLAY]); 
}

fwAlarmHandlingScreen_getDefaultFilterName(string &defaultFilter, dyn_string &exceptionInfo)
{
  dpGet("_FwAesSetup.defaultFilter", defaultFilter);
}

fwAlarmHandlingScreen_getRightClickConfig(dyn_string &menuItems, dyn_string &menuFunctions,
                                          dyn_string &menuAlertTypes, dyn_string &exceptionInfo)
{
  dpGet("_FwAesSetup.rightClickMenu.items", menuItems,
        "_FwAesSetup.rightClickMenu.functions", menuFunctions,
        "_FwAesSetup.rightClickMenu.alertTypes", menuAlertTypes);
}


fwAlarmHandlingScreen_setDefaultFilterName(string defaultFilter, dyn_string &exceptionInfo)
{
  if(strlen(defaultFilter) != 0)
  {
    if(strpos(defaultFilter, fwAlarmHandlingScreen_FILTER_DP_PREFIX) != 0)
      defaultFilter = fwAlarmHandlingScreen_FILTER_DP_PREFIX + defaultFilter;
  }
  
  dpSetWait("_FwAesSetup.defaultFilter", defaultFilter);  
}

fwAlarmHandlingScreen_getOnlineValueUpdateRate(float &updateRate, dyn_string &exceptionInfo)
{
  dpGet("_FwAesSetup.onlineValueUpdateRate", updateRate);
}

fwAlarmHandlingScreen_setOnlineValueUpdateRate(float updateRate, dyn_string &exceptionInfo)
{
  dpSetWait("_FwAesSetup.onlineValueUpdateRate", updateRate);  
}

fwAlarmHandlingScreen_getIdleTimeout(int &idleTimeout, dyn_string &exceptionInfo)
{
  dpGet("_FwAesSetup.idleTimeoutMinutes", idleTimeout);
}

fwAlarmHandlingScreen_setIdleTimeout(float idleTimeout, dyn_string &exceptionInfo)
{
  dpSetWait("_FwAesSetup.idleTimeoutMinutes", idleTimeout);  
}

fwAlarmHandlingScreen_setHistoricalMaxLines(int maxLines, dyn_string &exceptionInfo)
{
  dpSetWait("_FwAesSetup.historicalMaxLines", maxLines);  
}

fwAlarmHandlingScreen_getHistoricalMaxLines(int &maxLines, dyn_string &exceptionInfo)
{
  if(dpExists("_FwAesSetup.historicalMaxLines"))
  {
    dpGet("_FwAesSetup.historicalMaxLines", maxLines);  
    if(maxLines==0)
    {
      maxLines=100;
      dpSet("_FwAesSetup.historicalMaxLines", maxLines);  
    }
  }
  else
  {
    maxLines = 0;
    fwException_raise(exceptionInfo, "WARNING", "fwAlarmHandlingScreen.ctl: could not find the dpe _FwAesSetup.historicalMaxLines", "");
  }
}

fwAlarmHandlingScreen_saveQuickFilterOptions(string fwAesConfigDp, bool isQuickFilter, string accessRight, dyn_string &exceptionInfo)
{
  dpSetWait(fwAesConfigDp + fwAlarmHandlingScreen_CONFIG_DP_FILTER_QUICK_FILTER, isQuickFilter,
            fwAesConfigDp + fwAlarmHandlingScreen_CONFIG_DP_FILTER_ACCESS_RIGHT, accessRight);
 
}

fwAlarmHandlingScreen_loadQuickFilterOptions(string fwAesConfigDp, bool &isQuickFilter, string &accessRight, dyn_string &exceptionInfo)
{
  dpGet(fwAesConfigDp + fwAlarmHandlingScreen_CONFIG_DP_FILTER_QUICK_FILTER, isQuickFilter,
        fwAesConfigDp + fwAlarmHandlingScreen_CONFIG_DP_FILTER_ACCESS_RIGHT, accessRight);
 
}

fwAlarmHandlingScreen_getDistSystemDisplayOption(bool &displayDetails, dyn_string &exceptionInfo)
{
  dpGet("_FwAesSetup.displayDistSystemDetails", displayDetails);
}

fwAlarmHandlingScreen_setDistSystemDisplayOption(bool displayDetails, dyn_string &exceptionInfo)
{
  dpSetWait("_FwAesSetup.displayDistSystemDetails", displayDetails);  
}

fwAlarmHandlingScreen_saveColumnWidths(dyn_string columnNames, dyn_int columnWidths, dyn_string &exceptionInfo)
{
  dyn_string actualNames;  
  dyn_int actualWidths;
  
  dpGet("_AESConfig.tables.alertTable.columns.name", actualNames,
        "_AESConfig.tables.alertTable.columns.widthScreen", actualWidths);
  
  for(int i=1; i<=dynlen(columnNames); i++)
  {
    int pos = dynContains(actualNames, columnNames[i]);
    if(pos > 0)
      actualWidths[pos] = columnWidths[i];
  }
  
  dpSetWait("_AESConfig.tables.alertTable.columns.widthScreen", actualWidths);
}

_fwAlarmHandlingScreen_rightClickFunction(const string propDp, const int tabType, const string tableName)
{
  bool isGranted = TRUE;
  unsigned mode;
  int res, row, column, alertType, answer, length;
  string dpId, dpe;
  dyn_string accessRights, menuConfig, menuItems, menuFunctions, menuAlertTypes, exceptionInfo;  
  
  anytype value;
  mapping rowHeaderMapping;
  
  synchronized(g_bTableLineSynchronisation)
  { 
    dyn_anytype alertRow;  
    
    if(isFunctionDefined("fwAccessControl_isGranted"))
    {
      fwAlarmHandlingScreen_getAccessControlOptions(accessRights, exceptionInfo);
      if(accessRights[fwAlarmHandlingScreen_ACCESS_RIGHT_CLICK] != "")
        fwAccessControl_isGranted(accessRights[fwAlarmHandlingScreen_ACCESS_RIGHT_CLICK], isGranted, exceptionInfo);
      else
        isGranted = TRUE;
    }

    setInputFocus( myModuleName(), myPanelName(), tableName);
    getValue( "", "currentCell", row, column );
    value=this.cellValue;

    alertRow = this.getLineN(row);
    length = dynlen(alertRow);
        
    for(int i=1; i<=length; i++)
      rowHeaderMapping[this.columnName(i-1)] = alertRow[i];
  }  
  
  dpId = rowHeaderMapping[_DPID_];
  if(dpId == "")
    return;

  dpe = dpSubStr(dpId, DPSUB_SYS_DP_EL);
  dpGet(dpe + ":_alert_hdl.._type", alertType);
        
  fwAlarmHandlingScreen_getRightClickConfig(menuItems, menuFunctions, menuAlertTypes, exceptionInfo);  
  length = dynlen(menuItems);

  if(length == 0)
    return;  
  
  for(int i=1; i<=length; i++)
  {
    bool enableOption = TRUE;
    if(!isGranted)
      enableOption = FALSE;
    else if((alertType == DPCONFIG_SUM_ALERT) && (menuAlertTypes[i] == "NO_SUMMARY"))
      enableOption = FALSE;
    else if((alertType != DPCONFIG_SUM_ALERT) && (menuAlertTypes[i] == "ONLY_SUMMARY"))
      enableOption = FALSE;
    
    //special option to disable default trending option is trending not installed
    if((menuItems[i] == "Trend") && (getPath(PANELS_REL_PATH, "fwTrending/fwTrendingZoomedWindow.pnl") == ""))
        enableOption = FALSE;
    
    dynAppend(menuConfig, "PUSH_BUTTON," + menuItems[i] + ", " + i + ", " + (int)enableOption);
  }
  
  popupMenu(menuConfig, answer);
  if(answer != 0)
  {
    res = evalScript(exceptionInfo, "main(mapping rowHeaderMapping, int row, string propDp, int tabType, string tableName, dyn_string exInfo)"
												+ "{ "
												+ " " +menuFunctions[answer] + "(rowHeaderMapping, row, propDp, tabType, tableName, exInfo);"
												+ " return exInfo;"
  											+ "}", makeDynString(), rowHeaderMapping, row, propDp, tabType, tableName, exceptionInfo);
  }  
  if(dynlen(exceptionInfo) > 0)
    fwExceptionHandling_display(exceptionInfo);                          
}

_fwAlarmHandling_showHelp(mapping rowHeaderMapping, int row, 
                              string propDp, int tabType, string tableName, dyn_string &exceptionInfo)
{
  string fileName;
  string dpId = rowHeaderMapping[_DPID_];
  string dpe = dpSubStr(dpId, DPSUB_SYS_DP_EL);

  if(isFunctionDefined("fwAlarmScreenUser_showHelp"))
    fwAlarmScreenUser_showHelp(dpId, tableName, row, exceptionInfo);
  else
  {
    fwAlarmHandling_findHelpFile(dpe, fileName, exceptionInfo);
    fwAlarmHandling_openHelpFile(fileName, exceptionInfo);
  }
}

_fwAlarmHandling_showTrend(mapping rowHeaderMapping, int row, 
                              string propDp, int tabType, string tableName, dyn_string &exceptionInfo)
{
  string dpId = rowHeaderMapping[_DPID_];
  string dpe = dpSubStr(dpId, DPSUB_SYS_DP_EL);

  if(isFunctionDefined("fwAlarmScreenUser_showTrend"))
    fwAlarmScreenUser_showTrend(dpId, tableName, row, exceptionInfo);
  else
  {
    ChildPanelOnCentral("fwAlarmHandling/fwAlarmHandlingTrend.pnl", "Trend for " + dpe,
                        makeDynString("$sDpe:" + dpe));
  }
}

_fwAlarmHandling_showDetails(mapping rowHeaderMapping, int row, 
                              string propDp, int tabType, string tableName, dyn_string &exceptionInfo)
{
  string dpId = rowHeaderMapping[_DPID_];
  mapping mTableMultipleRows;
  
  mTableMultipleRows[row] = rowHeaderMapping;

  if(isFunctionDefined("fwAlarmScreenUser_showDetails"))
    fwAlarmScreenUser_showDetails(dpId, tableName, row, exceptionInfo);
  else
    aes_displayDetails(tabType, row, propDp, mTableMultipleRows[row]);
}

_fwAlarmHandling_showFsmPanel(mapping rowHeaderMapping, int row, 
                              string propDp, int tabType, string tableName, dyn_string &exceptionInfo)
{
  string dpId = rowHeaderMapping[_DPID_];
  string dpName, dpSystem, nodeName = "";
  dyn_string parts;
  dyn_dyn_anytype queryResult;

  if(isFunctionDefined("fwAlarmScreenUser_showFsmPanel"))
  {
    fwAlarmScreenUser_showFsmPanel(dpId, tableName, row, exceptionInfo);
    return;
  }

  dpName = dpSubStr(dpId, DPSUB_SYS_DP);
  dpSystem = dpSubStr(dpId, DPSUB_SYS);
  if(dpTypeName(dpName) == "_FwFsmObject")
  {
    parts = strsplit(dpName, "|");
    if(dynlen(parts) > 2)
      nodeName = parts[2] + "::" + parts[3];
    else
      nodeName = parts[2];
  }
  else
  {
    dpQuery("SELECT '_original.._value' FROM '*.tnode' REMOTE '" + dpSystem + "' WHERE '_original.._value' == \""
            + dpName+ "\"", queryResult);
      
    if(dynlen(queryResult) >= 2)
    {
      nodeName = dpSubStr(queryResult[2][1], DPSUB_DP);
      strreplace(nodeName, "|", "::");
    }
  }
  
  if(nodeName != "")
    fwCU_view(nodeName);
  else
    fwException_raise(exceptionInfo, "ERROR", "The corresponding FSM object could not be found", "");
}

//@}
