/**@file

@par Creation Date
	24/03/04

@par Constraints
	None

@author 
	Manuel Gonzalez Berges (IT-CO)
*/

//@{

// Constants
const string fwGeneral_DYN_STRING_DEFAULT_SEPARATOR = "|";
// Date Time Widget constants
const string FW_GENERAL_NATURAL_TIME_FORMAT = "%d/%m/%Y - %H:%M:%S";
const string FW_GENERAL_GENERIC_TIME_FORMAT = "%Y.%m.%d %H:%M:%S";
const string FW_GENERAL_TIMEZONE_UTC = "UTC";
const string FW_GENERAL_TIMEZONE_LOCAL = "LOCAL";
// Note: the default parameter separator in the function fwGeneral_stringToDynString
// should also be changed if this is changed. PVSS doesn't allow to set default
// arguments in functions to constants.

// Global variables

// contains integer values of dynamic dpe types (dyn types, not dyn_dyn) 
// it is initialized by fwGeneral_init
global dyn_int g_fwGeneral_dynDpeTypes;


/** Opens confirmation dialog panel, and returns result
user selection

@par Constraints
	None
	
@par Usage
	Public
	
@par PVSS managers
	VISION

@param dpe name of the datapoint where the command will be applied
@param command short explanation of the action to be confirmed
@param confirmation whether the user confirmed the command or not
@param exceptionInfo returns details of any errors
*/
fwGeneral_commandConfirmation(string dpe, string command, bool &confirmation, dyn_string &exceptionInfo)
{

	dyn_float df;
	dyn_string ds;

	ChildPanelOnCentralModalReturn(	"fwGeneral/fwCommandConfirmation.pnl", 
												"Command confirmation.",
												makeDynString(	"$sDpName:" + dpe,
																	"$sCommand:" + command),
												df, ds);
	if (ds[1] == "TRUE")
	{									
		confirmation = TRUE;
	}
	else
	{
		confirmation = FALSE;
	}
}


/** Returns end date and time selected by the user and performs format check.

@par Constraints
	To be used together with date/time widget (fwGeneralDateTimeWidget.pnl).
  The following UI elements have to be existent:
  - endDateField
  - endTimeField

@par Usage
	Public
	
@par PVSS managers
	VISION, CTRL
  
@param  bOk Output - Returns info whether provided times were in correct format or not. In case of wrong format, current time is given back as return value.
@param  dsException - Input/Output: Carrier for exception message to be shown to user 
@return End date as time value
*/
time fwGeneral_dateTimeWidget_getEndDateTime(bool &bOk, dyn_string &dsException)
{
  string sEndTime;
  time tEndTime;
  
  sEndTime = endDateField.text + " " + endTimeField.text;
  bOk = fwGeneral_hasCorrectFormat(sEndTime);
  
  if(bOk)
  {
    tEndTime = fwGeneral_stringToDate(sEndTime);
  }
  else
  {
    tEndTime = getCurrentTime();
	  dsException = makeDynString("Error", "Indicated date or time values are corrupt.\nPlease correct.", "");
  }
  
  return tEndTime;
}


/** Returns start date and time selected by the user and performs format check.

@par Constraints
	To be used together with date/time widget (fwGeneralDateTimeWidget.pnl).
  The following UI elements have to be existent:
  - startDateField
  - startTimeField

@par Usage
	Public
	
@par PVSS managers
	VISION, CTRL
  
@param  bOk Output - Returns info whether provided times were in correct format or not. In case of wrong format, current time is given back as return value.
@param  dsException - Input/Output: Carrier for exception message to be shown to user 
@return Start date as time value
*/
time fwGeneral_dateTimeWidget_getStartDateTime(bool &bOk, dyn_string &dsException)
{
  string sStartTime;
  time tStartTime;
  
  sStartTime = startDateField.text + " " + startTimeField.text;
  bOk = fwGeneral_hasCorrectFormat(sStartTime);

  if(bOk)
  {
    tStartTime = fwGeneral_stringToDate(sStartTime);
  }
  else
  {
    tStartTime = getCurrentTime();
	  dsException = makeDynString("Error", "Indicated date or time values are corrupt.\nPlease correct.", "");
  }
  
  return tStartTime;
}


/** Returns the time zone used to determine the current time.

@par Constraints
	To be used together with date/time widget (fwGeneralDateTimeWidget.pnl).
  The following UI elements have to be existent:
  - selectedTimeZone

@par Usage
	Public
	
@par PVSS managers
	VISION, CTRL
  
@return Time zone as string
*/
string fwGeneral_dateTimeWidget_getTimeZone()
{
  string sTimeZone;

  sTimeZone = selectedTimeZone.text();
  
  return sTimeZone;
}


/** Checks whether the user has selected a positive time interval in the date/time widget or not.

@par Constraints
	To be used together with date/time widget (fwGeneralDateTimeWidget.pnl).
  The following UI elements have to be existent:
  - startDateField
  - startTimeField
  - endDateField
  - endTimeField

@par Usage
	Public
	
@par PVSS managers
	VISION, CTRL
 
@param  dsException - Input/Output: Carrier for exception message to be shown to user 
@return Boolean value TRUE if positive, FALSE if negative time interval
*/
bool fwGeneral_dateTimeWidget_positivePeriodSelected(dyn_string &dsException)
{
  bool isPositive = FALSE;
  bool bOkStart, bOkEnd;
  time tStartTime, tEndTime;
  string sStartTime, sEndTime;
  
  sStartTime = startDateField.text + " " + startTimeField.text;
  sEndTime = endDateField.text + " " + endTimeField.text;
  
  bOkStart = fwGeneral_hasCorrectFormat(sStartTime);
  bOkEnd = fwGeneral_hasCorrectFormat(sEndTime);
  
  if(bOkStart && bOkEnd)
  {
    tStartTime = fwGeneral_stringToDate(sStartTime);
    tEndTime = fwGeneral_stringToDate(sEndTime);

    if (period(tStartTime) < period(tEndTime))
    {
      isPositive = TRUE;
    }
    else
    {
      dsException = makeDynString("Error", "End date is prior to start date.\nPlease correct.", "");
    }
  }
  else
  {
	  dsException = makeDynString("Error", "Indicated date or time values are corrupt.\nPlease correct.", "");
  }
  
  return isPositive;
}


/** Enables or disables the UI elements of the Date Time Widget.
    !!! Make sure widget is initialised before using this function. !!!
    (If you want to enable/disable upon initialization, use the provided $-parameter)

@par Constraints
	To be used together with date/time widget (fwGeneralDateTimeWidget.pnl).
  The following UI elements have to be existent:
  - startNowButton
  - startDateField
  - startTimeField
  - startTimeSpin
  - startDateChooserButton  
  - startDateButton
  - endNowButton
  - endDateField
  - endTimeField  
  - endTimeSpin  
  - endDateChooserButton 
  - endDateButton

@par Usage
	Public
	
@par PVSS managers
	VISION, CTRL
  
@param bState Input - boolean: state
*/
fwGeneral_dateTimeWidget_setEnabled(bool bState)
{
  startNowButton.enabled(bState);  
  startTimeField.enabled(bState); 
  startTimeSpin.enabled(bState); 
  startDateChooserButton.enabled(bState);  
  startDateField.enabled(bState);  
  startDateButton.enabled(bState);  
  
  endNowButton.enabled(bState);
  endTimeField.enabled(bState);
  endTimeSpin.enabled(bState);
  endDateChooserButton.enabled(bState);
  endDateField.enabled(bState);
  endDateButton.enabled(bState);
}


/** Sets the end date and time in the Date Time Widget.

@par Constraints
	To be used together with date/time widget (fwGeneralDateTimeWidget.pnl).
  The following UI elements have to be existent:
  - endDateField
  - endTimeField

@par Usage
	Public
	
@par PVSS managers
	VISION, CTRL
  
@param Input - time: date and time
*/
fwGeneral_dateTimeWidget_setEndDateTime(time tDateTime)
{
  endDateField.text = formatTime("%d/%m/%Y", tDateTime);
  endTimeField.text = formatTime("%H:%M:%S", tDateTime);
}


/** Sets the start date and time in the Date Time Widget.

@par Constraints
	To be used together with date/time widget (fwGeneralDateTimeWidget.pnl).
  The following UI elements have to be existent:
  - startDateField
  - startTimeField

@par Usage
	Public
	
@par PVSS managers
	VISION, CTRL
  
@param Input - time: date and time
*/
fwGeneral_dateTimeWidget_setStartDateTime(time tDateTime)
{
  startDateField.text = formatTime("%d/%m/%Y", tDateTime);
  startTimeField.text = formatTime("%H:%M:%S", tDateTime);
}


/** Sets the time zone used to determine the current time.

@par Constraints
	To be used together with date/time widget (fwGeneralDateTimeWidget.pnl).
  The following UI elements have to be existent:
  - selectedTimeZone

@par Usage
	Public
	
@par PVSS managers
	VISION, CTRL
  
@param Input - string: time zone (e.g. FW_GENERAL_NATURAL_TIME_FORMAT, FW_GENERAL_GENERIC_TIME_FORMAT)
*/
fwGeneral_dateTimeWidget_setTimeZone(string sTimeZone)
{
  selectedTimeZone.text(sTimeZone);
}


/** Makes the UI elements of the Date Time Widget visible/invisible 
    while still allowing for the different modes (date and time vs. only date; time zone shown).
    !!! Make sure the widget is initialised before using this function. !!!

@par Constraints
	To be used together with date/time widget (fwGeneralDateTimeWidget.pnl).
  The following UI elements have to be existent:
  - startNowButton
  - startDateField
  - startTimeField
  - startTimeSpin
  - startDateChooserButton  
  - startDateButton
  - endNowButton
  - endDateField
  - endTimeField  
  - endTimeSpin  
  - endDateChooserButton 
  - endDateButton
  - startTimeLabel
  - endTimeLabel
  - timeZoneLabel
  - selectedTimeZone
  - dateTimeSeparator
  - dateAndTimeShownField
  - timeZoneShownField

@par Usage
	Public
	
@par PVSS managers
	VISION, CTRL
  
@param bState Input - boolean: state
*/
fwGeneral_dateTimeWidget_setVisible(bool bState)
{
  startTimeLabel.visible(bState);
  endTimeLabel.visible(bState);
  startDateField.visible(bState);  
  endDateField.visible(bState); 
  
  if(dateAndTimeShownField.text)
  {
    dateTimeSeparator.visible(bState);
    startTimeField.visible(bState); 
    startTimeSpin.visible(bState);
    startNowButton.visible(bState);
    startDateChooserButton.visible(bState);  
    endTimeField.visible(bState);
    endTimeSpin.visible(bState);
    endNowButton.visible(bState);
    endDateChooserButton.visible(bState);
  }
  else
  {
    startDateButton.visible(bState); 
    endDateButton.visible(bState);
  }
  
  if(timeZoneShownField.text)
  {
    timeZoneLabel.visible(bState); 
    selectedTimeZone.visible(bState); 
  } 
}


/** Opens the datapoint type selector panel and return the
user selection

@par Constraints
	None
	
@par Usage
	Public
	
@par PVSS maangers
	VISION

@param selectedDpTypes  returns the list of selected DP Types (one or multiple, depending on selectMultiple parameter.
    					If specified as input it can contain the pre-defined selection.
@param disabledDpTypes  list of DP Types that are disabled in the selection list. Specifying empty list means that all
    					items are selectable
@param exceptionInfo	returns details of any errors
@param selectMultiple   determines if the selection list allows for multiple selection, or single selection only.
@param text 			panel title. If an empty string is specified, then "Select Datapoint Types" will be used.
*/
void fwGeneral_DpTypeSelector(	dyn_string &selectedDpTypes, dyn_string disabledDpTypes, dyn_string &exceptionInfo, 
								bool selectMultiple = FALSE, string text = "")
{
    dyn_float df;
    dyn_string ds;
    
    if (text == "") 
    	text = "Select DP Types";
	DebugN(selectedDpTypes);
    ChildPanelOnCentralReturn(	"fwGeneral/fwGeneralDpTypeSelector.pnl", 
    							text,
        						makeDynString(	"$text:" + text,
            									"$selectMultiple:" + selectMultiple,
            									"$disabledItems:" + disabledDpTypes,
            									"$selectedItems:" + selectedDpTypes),
        						df,ds);
//	DebugN(selectedDpTypes);
    selectedDpTypes = ds;
    return;
}


/**Converts a dyn_string to a string with the chosen separator.

@par Constraints
	None

@par Usage
	Public

@par PVSS managers
	VISION, CTRL

@param theDynString dyn_string to be converted
@param theString result of the conversion
@param separator separator used for splitting. The default value should be fwGeneral_DYN_STRING_DEFAULT_SEPARATOR, 
				but PVSS doesn't allow constants in default arguments
*/
fwGeneral_dynStringToString(dyn_string theDynString, string &theString, string separator = "|")
{
	if(dynlen(theDynString) < 1)
	{
		theString = "";
		return;
	}
	
//	DebugN("separator " + separator);
	theString = theDynString[1];
	for(int i = 2; i <= dynlen(theDynString); i++)
	{
		theString = theString + separator + theDynString[i];
	}
}


/** Fills in the a dynamic string with the selected value (null by default)
until it has at least the required length. If the initial length of the 
dynamic string is equal or more than the requested length, then it is not changed.

@par Constraints
	None

@par Usage
	Public

@par PVSS managers
	VISION, CTRL

@param ds the dynamic string to be modified
@param length minimum length required for the dynamic string
@param exceptionInfo returns details of any exceptions
@param value value to be used to fill in the array
*/
fwGeneral_fillDynString(dyn_string &ds, int length, dyn_string &exceptionInfo, string value = "")
{
	int dsLen = dynlen(ds);
	
	if(dsLen >= length)
		return;
	
	for(int i = dsLen + 1; i <= length; i++)
	{
		ds[i] = value;	
	}
}

/** Returns a list with the dpes in a dp or a dp type. The method used is a workaround,
because the function dpTypeGet doesn't return the dpes when there is a reference to 
another type.

@par Constraints
	If a dp type is specified , at least one datapoint of the type has to exist

@par Usage
	Public

@par PVSS managers
	VISION, CTRL
	
@param dp datapoint to get the elements from
@param dpType dp type to get the elements from if no datapoint was specified (dp = "")
@param dpElements returns the list of dp elements
@param dpElementTypes returns the list of types of corresponding to the list of dp elements
@param exceptionInfo returns details of any exceptions
@param excludedTypes excluded dp elements of these types from the list
@param forceDpCreation if there are no dps of the specified type, it is possible to force the
						creation of a dummy dp to be able to get the structure
*/
fwGeneral_getDpElements(string dp, string dpType, dyn_string &dpElements, dyn_string &dpElementTypes, 
						dyn_string &exceptionInfo, dyn_int excludedTypes = "", bool forceDpCreation = false)
{
	int i, dpeType;
	string systemName;
	dyn_string ds, localDpElements;

	dpElements = makeDynString();
	dpElementTypes = makeDynInt();
	
	// if no dp was specified, try to get one
	if(dp == "")
	{
		if(dpType != "")
		{
			ds = dpNames("*", dpType);
			if(dynlen(ds) > 0)
			{
				dp = ds[1];
			}
			else
			{
				if(forceDpCreation == true)
				{
					dpCreate("tmp_" + dpType , dpType);	
					dp = "tmp_" + dpType;
				}
			}
			
			
			if(!dpExists(dp))
			{
				fwException_raise(	exceptionInfo,
									"ERROR",
									"fwGeneral_getDpElements(): there are no dps of the specified type (" + dpType + ")",
									"");
					
				return;
			}
		}
		else
		{
			fwException_raise(	exceptionInfo,
								"ERROR",
								"fwGeneral_getDpElements(): specify either a dp or a dp type.",
								"");
			return;			
		}
	}
	else
	{
		if(!dpExists(dp))
		{
			fwException_raise(	exceptionInfo,
								"ERROR",
								"fwGeneral_getDpElements(): the specified dp does not exist (" + dp + ")",
								"");
			return;			
			
		}	
	}
	
	// Initialize variables
	dpElements = makeDynString();
	dpElementTypes = makeDynInt();
	
//	DebugN("fwGeneral_getDpElements() " + dpElements + " " + dpElementTypes);
	
	localDpElements = dpNames(dp + ".*;");
	dynSortAsc(localDpElements);
	
	// make sure that dp has the system name because the elements have it.
	fwGeneral_getSystemName(dp, systemName, exceptionInfo);
	if(systemName == "")
		dp = getSystemName() + dp;
	
	// remove dp name from elements, we are only interested in the element name
	// exclude dpe if type in list if excluded dpe types
	for(i = 1; i <= dynlen(localDpElements); i++)
	{
		dpeType = dpElementType(localDpElements[i]);
		if(dynContains(excludedTypes, dpeType) < 1)
		{
			dynAppend(dpElementTypes, dpeType);
			strreplace(localDpElements[i], dp, "");
			dynAppend(dpElements, localDpElements[i]);
		}
	}
//	DebugN("fwGeneral_getDpElements() " + dpElements + " " + dpElementTypes);
}


/** Returns the a list of dynamic types for dpes

@par Constraints
	None

@par Usage
	Public

@par PVSS managers
	VISION, CTRL

@param dynTypes list of integer values of dynamic dpe types (does not dyn_anytype or any dyn_dyn)
@param exceptionInfo details of any exceptions
*/
fwGeneral_getDynDpeTypes(dyn_string &dynTypes, dyn_string &exceptionInfo)
{
	dynTypes = makeDynInt(	DPEL_DYN_BIT32,			// dynamic array for bit pattern
							DPEL_DYN_BLOB,			// dynamic blob
							DPEL_DYN_BOOL,			// dynamic bit array
							DPEL_DYN_CHAR,			// dynamic character array
							DPEL_DYN_DPID,			// dynamic DP-Identifier array
							DPEL_DYN_FLOAT,			// dynamic number array for floating decimal point
							DPEL_DYN_INT,			// dynamic integer array
							DPEL_DYN_LANGSTRING,	// multilingual dynamic text array
							DPEL_DYN_STRING,		// dynamic text array
							DPEL_DYN_TIME,			// dynamic time array
							DPEL_DYN_UINT);			// dynamic array of positive whole numbers
}


/** Returns the value of a global variable

@par Constraints
	None

@par Usage
	Public

@par PVSS managers
	VISION, CTRL

@param globalVariable name of the global variable to get the value from
@param value returns the value of the global variable
@param exceptionInfo details of any exceptions
*/
fwGeneral_getGlobalValue(string globalVariable, anytype &value, dyn_string &exceptionInfo)
{	
	evalScript(	value, 
				"anytype main() { return " + globalVariable + ";}",
				makeDynString());
}


/** Removes the system name from the passed name.
name can be a DP name or a DP alias. dpSubStr is
not used because it only works if the dp exists.

@par Constraints
	None

@par Usage
	Public

@par PVSS managers
	VISION, CTRL

@param name name to be processed
@param nameWithoutSN name with system name removed
@param exceptionInfo details of any exceptions
*/
fwGeneral_getNameWithoutSN(string name, string &nameWithoutSN, dyn_string &exceptionInfo)
{
	nameWithoutSN = substr(name, strpos(name, ":") + 1);
}


/** Returns ipAddress and hostName where the PVSS system with
name systemName is running. 

@par Constraints
	Local system not supported.
	The remote system has to be connected at the time the function is called.

@par Usage
	Public

@par PVSS managers
	VISION, CTRL

@param systemName name of the system we are interested in
@param ipAddress ip address of the machine where the PVSS system is running
@param hostName host name of the machine where the PVSS system is running
@param exceptionInfo returns details of any exceptions
*/
fwGeneral_getSystemIpAddress(string systemName, string &ipAddress, string &hostName, dyn_string &exceptionInfo)
{
	int sysId, index;
	string sys;
	dyn_int distManNumbers;
	dyn_string hostNames;
	
	hostName = "";
	ipAddress = "";
	sys = getSystemName();
	
	// make sure that the system name always contains :
	systemName = strrtrim(systemName, ":") + ":";
	
	if(sys == systemName)
	{			
		fwException_raise(	exceptionInfo, 
							"ERROR", 
							"fwGeneral_getSystemIpAddress: local system not supported for the moment",
							"");
	}
	else
	{
		sysId = getSystemId(systemName);
		
		dpGet(	"_DistConnections.Dist.ManNums", distManNumbers,
				"_DistConnections.Dist.HostNames", hostNames);
		//DebugN(distManNumbers, sysId);
		index = dynContains(distManNumbers, sysId);
		if(index > 0)
		{
			hostName = 	hostNames[index];
			ipAddress = getHostByName(hostName);
		}
		else
		{
			fwException_raise(	exceptionInfo, 
								"ERROR", 
								"fwGeneral_getSystemIpAddress: could not retrieve host name and ip address for system " + systemName,
								"");
		}
	}
}


/** Gets the system name from the passed name.
name can be a DP name or a DP alias. dpSubStr is
not used because it only works if the dp exists.

@par Constraints
	None

@par Usage
	Public

@par PVSS managers
	VISION, CTRL

@param name name to be processed (e.g. system1:crate01/board03/channel005)
@param systemName system name extracted from name (e.g. system1:)
@param exceptionInfo details of any exceptions
*/
fwGeneral_getSystemName(string name, string &systemName, dyn_string &exceptionInfo)
{
	systemName = substr(name, 0, strpos(name, ":") + 1);
}


/** Checks the format of a provided date. Checks for following format: dd/mm/yyyy

@par Constraints
  None
  
@par Usage
	Public
	
@par PVSS managers
	VISION, CTRL

@param Input - string: date at question  
@return Boolean value indicating result of check
*/
bool fwGeneral_hasCorrectDateFormat(string sDate)
{
  dyn_string dsSplitDate;
  bool bOk = TRUE;
  
  const string sRegexNumber = "[0123456789]";

  dsSplitDate = strsplit(sDate, "/");

  if (3 != dynlen(dsSplitDate))
  {
    bOk = FALSE;
  }
  else
  {
    if ((!patternMatch(sRegexNumber + sRegexNumber + sRegexNumber + sRegexNumber, dsSplitDate[3])) // Year is 4 digits
      || (!patternMatch(sRegexNumber + sRegexNumber, dsSplitDate[2]))                              // Month is two digits
      || (!patternMatch(sRegexNumber + sRegexNumber, dsSplitDate[1])))                             // Day is two digits
    {
      bOk = FALSE;
    }
  }
  
  return bOk;
}


/** Checks the format of a provided date and time. Checks for following format: dd/mm/yyyy hh:mm:ss

@par Constraints
  None
  
@par Usage
	Public
	
@par PVSS managers
	VISION, CTRL
  
@param Input - string: date and time at question
@return Boolean value indicating result of check
*/
bool fwGeneral_hasCorrectFormat(string sDateTime)
{
  bool bDateOk = FALSE;
  bool bTimeOk = FALSE;
  dyn_string dsDateTimeSplit;
  
  dsDateTimeSplit = strsplit(sDateTime, " ");
  
  if(dynlen(dsDateTimeSplit) == 2)
  {
    bDateOk = fwGeneral_hasCorrectDateFormat(dsDateTimeSplit[1]);
    bTimeOk = fwGeneral_hasCorrectTimeFormat(dsDateTimeSplit[2]);
  } 
  
  return bDateOk && bTimeOk;
}


/** Checks the format of a provided time. Checks for following format: hh:mm:ss

@par Constraints
  None
  
@par Usage
	Public
	
@par PVSS managers
	VISION, CTRL

@param Input - string: time at question  
@return Boolean value indicating result of check
*/
bool fwGeneral_hasCorrectTimeFormat(string sTime)
{
  dyn_string dsSplitTime;
  bool bOk = TRUE;
  
  const string sRegexNumber = "[0123456789]";

  dsSplitTime = strsplit(sTime, ":");

  if (3 != dynlen(dsSplitTime))
  {
    bOk = FALSE;
  }
  else
  {
    // Hour minute and second are 2 digits 
    if ((!patternMatch(sRegexNumber + sRegexNumber, dsSplitTime[1]))
        || (!patternMatch(sRegexNumber + sRegexNumber, dsSplitTime[2])) 
        || (!patternMatch(sRegexNumber + sRegexNumber, dsSplitTime[3])))
    {
      bOk = FALSE;
    }
  }
  
  return bOk;
}


/** Initializes global constants provided by the library

@par Constraints
	None

@par Usage
	Public

@par PVSS managers
	VISION, CTRL

@param exceptionInfo details of any exceptions
*/
fwGeneral_init(dyn_string &exceptionInfo)
{
	fwGeneral_getDynDpeTypes(g_fwGeneral_dynDpeTypes, exceptionInfo);
}


/** Returns whether the dpe type is dyn or not

@par Constraints
	None

@par Usage
	Public

@par PVSS managers
	VISION, CTRL

@param type integer number for dpe type
@param isDyn whether the dpetype is dyn or not
@param exceptionInfo details of any exceptions
*/
fwGeneral_isDpeTypeDyn(int type, bool &isDyn, dyn_string &exceptionInfo)
{
	if(dynContains(g_fwGeneral_dynDpeTypes, type) > 0)
	{
		isDyn = TRUE;
	}
	else
	{
		isDyn = FALSE;
	}
}


/** Opens the details panel for a given datapoint element

@par Constraints
	None

@par Usage
	Public
	
@par PVSS managers
	VISION

@param dpe datapoint element to get the details from
@param exceptionInfo details of any exceptions
*/
fwGeneral_openDetailsPanel(string dpe, dyn_string &exceptionInfo)
{
	bit32	status;

	dpGet(dpe + ":_original.._status", status);

	ChildPanelOnCentralModal ("fwGeneral/fwDetailDpElement.pnl", "Details", makeDynString("$1:" + dpe, "$2:" + status));


/*	if(!isModuleOpen("Detail"))
	{
		ModuleOnWithPanel(	"Detail", -1, -1, 0, 0, 1, 1, "", 
							"para/originalHelp.pnl", "Detail",
							makeDynString("$1:" + dpe, "$2:" + status));
	}
	else
	{
		RootPanelOnModule(	"para/originalHelp.pnl", " ", "Detail",
							makeDynString("$1:" + dpe, "$2:" + status));
	}*/
}


/** Opens a message panel with the specified message. If it is used as a
dialog (onlyInfo = FALSE) it will return whether the user pressed Ok or not. 
If it is used as information panel it will just display the panel and wait
for the user to press Ok.

@par Constraints
	None

@par Usage
	Public

PVSS manager usage
	VISION

@param message the message to be presented in the panel
@param ok returns TRUE if the user pressed the Ok button, FALSE otherwise
@param exceptionInfo details of any exceptions
@param panelBarTitle title for the panel <b>WARNING</b>: deprecated from PVSS 3.6 and higher
@param onlyInfo whether the panel is just for information, or it will also ask for user input
*/
fwGeneral_openMessagePanel(string message, bool &ok, dyn_string &exceptionInfo, string panelBarTitle = "", bool onlyInfo = FALSE)
{
	dyn_float df;
	dyn_string ds;
	
	if(onlyInfo)
	{
		ChildPanelOnCentralModalReturn("vision/MessageInfo1", panelBarTitle,
										makeDynString(message),
										df, ds); 
	}
	else
	{
		ChildPanelOnCentralModalReturn("vision/MessageInfo", panelBarTitle,
										makeDynString(	message,
														"Ok",
														"Cancel"),
										df, ds); 
														
		if(df[1] == 1)
			ok = TRUE;
		else
			ok = FALSE;
	}
}


/** Opens a panel to select one or several of the items in a list

@par Constraints
	None

@par Usage
	Public

@par PVSS managers
	VISION, CTRL

@param list list of strings to select from
@param selection returns the selected items
@param exceptionInfo details of any exceptions
@param multipleSelection whether it is possible to select more than one item or not
@param title title of the pop-up window with the dialog box
*/
fwGeneral_selectFromList(	dyn_string list, dyn_string &selection, dyn_string &exceptionInfo, 
							bool multipleSelection = false, string title = "Select fromt the list")
{
 	dyn_float df;
	dyn_string ds;
	
//	fwGeneral_stringToDynString();
	ChildPanelOnCentralModalReturn(	"fwGeneral/fwGeneralEditDynString.pnl", 
												title,
												makeDynString(	"$sTitle:" + title,
																	"$dsValues:" + list,
																	"$bMultipleSelection:" + multipleSelection),
												df,
												selection);							
}


/** Sets the value of a global variable

@par Constraints
	None

@par Usage
	Public

@par PVSS managers
	VISION, CTRL

@param globalVariable name of the global variable to set the value to
@param value the value to be set to the global variable 
@param exceptionInfo details of any exceptions
*/
fwGeneral_setGlobalValue(string globalVariable, anytype value, dyn_string &exceptionInfo)
{
	int val;
	evalScript(	val, "int main(anytype objectValue) {" + globalVariable + " = objectValue; return 0;}",
							makeDynString(), value);
}

/** Converts a string to a dyn_string with the chosen separator.

@par Constraints
	None

@par Usage
	Public

@par PVSS managers
	VISION, CTRL

@param theString string to be split
@param theDynString result of splitting
@param separator 	separator used for splitting. The default value should be fwGeneral_DYN_STRING_DEFAULT_SEPARATOR, but 
					PVSS doesn't allow constants in default arguments
@param removeSpaces whether to remove spaces in the string before parsing it or not
@param compatibilityMode 	useful to parse strings that are the result of the automatic conversion by PVSS of 
							a dyn_string to a string. In this case, the parts are separated by " | " (space-tube-space). 
							If you want to get the original dyn_string, set this parameter to TRUE. 
*/
fwGeneral_stringToDynString(string theString, dyn_string &theDynString, string separator = "|", bool removeSpaces = true, bool compatibilityMode = false)
{
//	DebugN(separator, removeSpaces, compatibilityMode, fwGeneral_DYN_STRING_DEFAULT_SEPARATOR);
	if(compatibilityMode)
	{
		strreplace(theString, " " + separator + " ", separator);
	}
	
	if(removeSpaces)
	{
		strreplace(theString, " ", "");
	}
	theDynString = strsplit(theString, separator);

	// Add empty element in the end if the original
	// string ended in the separator character
	if(strlen(strrtrim(theString, separator)) != strlen(theString))
		theDynString[dynlen(theDynString) + 1] = "";
}


/** Converts previously checked time string into time value.
  
@par Constraints
	None

@par Usage
	Public

@par WinCC managers
	VISION, CTRL

@param Input - string: date and time to be checked

@return Time value of string including milliseconds (1970.01.01 00:00:00 in case of bad format)
*/
time fwGeneral_stringToDate(string sDateTime)
{  
  dyn_string dsDateTimeSplit, dsDateSplit;
  string sDate;
  time tDateTime = makeTime(1970,1,1,0,0,0);

  // Split in two parts: date and time
  dsDateTimeSplit = strsplit(sDateTime, " ");

  if(dynlen(dsDateTimeSplit) == 2)
  {
    sDate = dsDateTimeSplit[1];
    dsDateSplit = strsplit(sDate, "/");
    
    if(dynlen(dsDateSplit) == 3)
    {
      // Create correct time format for calendar widget
      sDateTime = dsDateSplit[3] + "." + dsDateSplit[2] + "." + dsDateSplit[1] + " " + dsDateTimeSplit[2] + ".000";
      tDateTime = sDateTime;
    }
  }
  
  return tDateTime;  
}


/** Gets an ISO-8859-1 encoded text file and returns the path of a new text file in UTF-8 encoding.

@par Constraints
	None

@par Usage
	Public

@par PVSS managers
	VISION, CTRL

@param fnameToRecode, string, filename+path which needs to be encoded
@return string path+filename of the encoded file.
*/

string fwGeneral_recodeFile(string fnameToRecode)
{
  string tmpfname,file2Str,encFileStr;
  int err;
  tmpfname=tmpnam();
  if(_UNIX)
  {
    err = system("iconv -f ISO-8859-1 -t UTF-8 "+ fnameToRecode +" > "+tmpfname);      
    if (err!=0)
      fwException_raise (	exceptionInfo, 
                          "ERROR",
                          "Error, iconv exit code:"+ err +", command in system(iconv -f ISO-8859-1 -t UTF-8 "+ fnameToRecode +" > "+tmpfname+")",
                          "");
  }
  else
  {
    fileToString(fnameToRecode, file2Str);
    encFileStr = recodeFileName(file2Str);
    file f;
    f=fopen(tmpfname,"w"); 
    err=ferror(f); // export error if exists
    if (err!=0)
      fwException_raise (	exceptionInfo,
                          "ERROR",
                          "fwGeneral_recodeFile() Error No:"+ err +" occurred in fopen(" + tmpfname + ",w)",
                          "");
    fputs(encFileStr,f);
    fclose(f); 
  }
  return tmpfname;  
}
//@}
