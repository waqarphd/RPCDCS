/**@file

This library contains functions for handling JCOP framework alarms.
There are functions for filtering data points which have alarms as well as functions to open the JCOP Alarm Screen

@par Creation Date
	02/02/2006

@par Modification History

  25/06/2012: Marco Boccioli
	- @jira{FWAH-257} Check for current alarm settings: bug in dpGet. 
		In fwAlarmHandling_AESConfig_isForFw(), wAlarmHandling_AESConfig_isForUn(): Removed system name. Added check if dp exists.

  12/06/2012: Marco Boccioli
    - @jira{IS-768} , @jira{FWAH-253} Alarms columns not correct after installing unCore 5.2.4. 
      Avoid clashing of configuration between JCOP Alarm Screen and UNICOS alarm screen written on _AESConfig.
      Added new functions: fwAlarmHandling_AESConfig_useFwConfig(), fwAlarmHandling_AESConfig_useUnConfig(),
      fwAlarmHandling_AESConfig_isForUn(), fwAlarmHandling_AESConfig_isForFw()

  29/06/2011 Marco Boccioli
    - @jira{ENS-3073} (Alarm Screen with predefined quick filter): added new parameters, $iLocalOrGlobal, $sFilterName , new optional variable filterName in fwAlarmHandling_openScreenWithFilter()
	
  2011-07-05 Marco Boccioli
    - @sav{84051} (Sometimes, the alias name in the filter makes the AS crash): modified function: fwAlarmHandling_getDpsMatchingCriteria(). It checks now if the sys name is already specified in the dpe list, before adding it.
    - @sav{83995} (Error when filtering with multiple device name including sys name):  modified function: fwAlarmHandling_getDpsMatchingCriteria(). Removed the dynIntersect call.
  
	
@par Constraints

@par Usage
	Public

@par PVSS managers
	VISION, CTRL

@author 
	Oliver Holme (IT-CO)
*/

//@{
//constants
const int fwAlarmHandling_HELP_DEVICE_ELEMENT        = 1;
const int fwAlarmHandling_HELP_DEVICE                = 2;
const int fwAlarmHandling_HELP_DEVICE_TYPE_ELEMENT   = 3;
const int fwAlarmHandling_HELP_DEVICE_TYPE           = 4;
const int fwAlarmHandling_HELP_DEFAULT               = 5;

const string fwAlarmHandling_HELP_PATH_ROOT                 = "AlarmHelp/";
const string fwAlarmHandling_HELP_PATH_DEVICE_DESCRIPTION_ELEMENT       = "DeviceDescriptionDPE/";
const string fwAlarmHandling_HELP_PATH_DEVICE_DESCRIPTION               = "DeviceDescription/";
const string fwAlarmHandling_HELP_PATH_DEVICE_ALIAS_ELEMENT       = "DeviceDescriptionDPE/";
const string fwAlarmHandling_HELP_PATH_DEVICE_ALIAS               = "DeviceDescription/";
const string fwAlarmHandling_HELP_PATH_DEVICE_ELEMENT       = "DeviceDPE/";
const string fwAlarmHandling_HELP_PATH_DEVICE               = "Device/";
const string fwAlarmHandling_HELP_PATH_DEVICE_TYPE_ELEMENT  = "DeviceTypeDPE/";
const string fwAlarmHandling_HELP_PATH_DEVICE_TYPE          = "DeviceType/";
const string fwAlarmHandling_HELP_FILE_DEFAULT              = "fwAlarmHandlingDefault.xml";

const string fwAlarmHandling_HELP_FORMAT_EXTENSIONS = "_FwAlarmHelpSettings.fileExtensions";
const string fwAlarmHandling_HELP_FORMAT_COMMANDS_WINDOWS = "_FwAlarmHelpSettings.openCommand.windows";
const string fwAlarmHandling_HELP_FORMAT_COMMANDS_LINUX = "_FwAlarmHelpSettings.openCommand.linux";

const string fwAlarmHandling_HELP_LOADER_PANEL		= "fwAlarmHandling/fwAlarmHandlingHelpLoader.pnl";
const string fwAlarmHandling_HELP_PATH_ATTRIBUTE	= ".._string_05";
//@}

//@{
fwAlarmHandling_setCustomHelpFile(string dpe, string helpFilePath, dyn_string &exceptionInfo)
{
  fwAlarmHandling_setManyCustomHelpFile(makeDynString(dpe), makeDynString(helpFilePath), exceptionInfo);
}

fwAlarmHandling_setMultipleCustomHelpFile(dyn_string dpes, string helpFilePath, dyn_string &exceptionInfo)
{
  int length;
  dyn_string helpFilePaths;
  
  length = dynlen(dpes);
  for(int i=1; i<=length; i++)
    helpFilePaths[i] = helpFilePath;
  
  fwAlarmHandling_setManyCustomHelpFile(dpes, helpFilePaths, exceptionInfo);
}

fwAlarmHandling_setManyCustomHelpFile(dyn_string dpes, dyn_string helpFilePaths, dyn_string &exceptionInfo)
{
  int length;
  dyn_string attributes = makeDynString(".._type", fwAlarmHandling_HELP_PATH_ATTRIBUTE);
  dyn_dyn_anytype valuesToSet;
  
  length = dynlen(dpes);
  for(int i=1; i<=length; i++)
  {
    valuesToSet[i][1] = DPCONFIG_GENERAL;
    valuesToSet[i][2] = helpFilePaths[i];    
  }
  _fwConfigs_setConfigAttributes(dpes, fwConfigs_PVSS_GENERAL, attributes, valuesToSet, exceptionInfo);
}

fwAlarmHandling_deleteCustomHelpFile(string dpe, dyn_string &exceptionInfo)
{
  fwAlarmHandling_deleteManyCustomHelpFile(makeDynString(dpe), exceptionInfo);
}


fwAlarmHandling_deleteMultipleCustomHelpFile(dyn_string dpes, dyn_string &exceptionInfo)
{
  fwAlarmHandling_deleteManyCustomHelpFile(dpes, exceptionInfo);  
}

fwAlarmHandling_deleteManyCustomHelpFile(dyn_string dpes, dyn_string &exceptionInfo)
{
  int length;
  dyn_int configTypes;
  dyn_string helpStringsToDelete, emptyStrings;
  dyn_dyn_anytype valuesToSet;
  
  _fwConfigs_getConfigTypeAttribute(dpes, fwConfigs_PVSS_GENERAL, configTypes, exceptionInfo);
  
  length = dynlen(dpes);
  for(int i=1; i<=length; i++)
  {
    if(configTypes[i] != DPCONFIG_NONE)
    {
      dynAppend(emptyStrings, "");
      dynAppend(helpStringsToDelete, dpes[i]);
    }
  }
  if(dynlen(helpStringsToDelete) > 0)
    _fwConfigs_setConfigTypeAttribute(helpStringsToDelete, fwConfigs_PVSS_GENERAL, emptyStrings, exceptionInfo, fwAlarmHandling_HELP_PATH_ATTRIBUTE);
}

bool fwAlarmHandling_getCustomHelpFile(string dpe, string &helpFilePath, dyn_string &exceptionInfo)
{
  dyn_bool result;
  dyn_string helpStrings;
  
  result = fwAlarmHandling_getManyCustomHelpFile(makeDynString(dpe), helpStrings, exceptionInfo);
  helpFilePath = helpStrings[1];
  return result[1];
}

dyn_bool fwAlarmHandling_getManyCustomHelpFile(dyn_string dpes, dyn_string &helpFilePaths, dyn_string &exceptionInfo)
{
  int length, position;
  dyn_bool result;
  dyn_int configTypes;
  dyn_string helpStringsToRead, helpStrings;
  
  _fwConfigs_getConfigTypeAttribute(dpes, fwConfigs_PVSS_GENERAL, configTypes, exceptionInfo);
  
  length = dynlen(dpes);
  for(int i=1; i<=length; i++)
  {
    if(configTypes[i] != DPCONFIG_NONE)
      dynAppend(helpStringsToRead, dpes[i]);
  }
  
  if(dynlen(helpStringsToRead) > 0)
    _fwConfigs_getConfigTypeAttribute(helpStringsToRead, fwConfigs_PVSS_GENERAL, helpStrings, exceptionInfo, fwAlarmHandling_HELP_PATH_ATTRIBUTE);
  
  for(int i=1; i<=length; i++)
  {
    position = dynContains(helpStringsToRead, dpes[i]);
    if(position > 0)
      helpFilePaths[i] = helpStrings[position];
    else
      helpFilePaths[i] = "";
    
    result[i] = (helpFilePaths[i] != "");
  }
  
  return result;
}

fwAlarmHandling_openHelpFile(string fileName, dyn_string &exceptionInfo)
{
	int replaced, position;
	string openCommand, suffix;
        dyn_string fileNameParts, fileExtensions, windowsCommand, linuxCommand;
        
        //check if this is a relative path or absolute path
        if((strpos(fileName, ":") < 0) && (strpos(fileName, "/") != 0) && (strpos(fileName, "\\") != 0))
        {
          fileName = getPath(HELP_REL_PATH, fwAlarmHandling_HELP_PATH_ROOT + fileName);
        }
        
        if(fileName == "")
	{
	  fwException_raise(exceptionInfo, "ERROR", "No valid file name for an alarm help file", "");
	  return;
        }
        
         //if not http then assume it is a file
        if((strpos(fileName, "http://") != 0) && (strpos(fileName, "https://") != 0))
	{
          //check file is accessible
          if(access(fileName, F_OK) != 0)
	  {
	    fwException_raise(exceptionInfo, "ERROR", "The help file could not be found: " + fileName, "");
	    return;
          }
        }

        //find file suffix
        fileNameParts = strsplit(fileName, ".");
        suffix = fileNameParts[dynlen(fileNameParts)];
        
        //find command to use to open the file
        fwAlarmHandling_getHelpFileFormats(fileExtensions, windowsCommand, linuxCommand, exceptionInfo);
        position = dynContains(fileExtensions, "." + suffix);
        if(position > 0)
        {
          if(_WIN32)
            openCommand = windowsCommand[position];
          else
            openCommand = linuxCommand[position];
        }
        if((position <= 0) || (openCommand == ""))
        {        
          if(_WIN32)
		dpGet("fwGeneral.help.helpBrowserCommandWindows", openCommand);
	  else
		dpGet("fwGeneral.help.helpBrowserCommandLinux", openCommand);
        }
        
        replaced = strreplace(openCommand, "$1", fileName);
	if(replaced == 0)
		openCommand = openCommand + " " + fileName;
	system(openCommand);
}

_fwAlarmHandling_convertDpNameToFileName(string dpName, string &fileName, dyn_string &exceptionInfo)
{
	strreplace(dpName, fwDevice_HIERARCHY_SEPARATOR, "_");
	strreplace(dpName, ":", "_");
        fileName = dpName;
}

fwAlarmHandling_findHelpFile(string dpe, string &fileName, dyn_string &exceptionInfo)
{
  dyn_string searchPatterns, searchDirectories, fileSuffix;
  string fileNameToCheck, dpType, dpElement, dpSystem, dpName, dpAlias, dpElementAlias, dpDescription, dpElementDescription;

  dpSystem = dpSubStr(dpe, DPSUB_SYS);

  dpName = dpSubStr(dpe, DPSUB_SYS_DP);
  dpType = dpTypeName(dpName);
  dpAlias = dpGetAlias(dpName);
  dpDescription = dpGetDescription(dpName);
  
  dpElement = dpSubStr(dpe, DPSUB_SYS_DP_EL);
  strreplace(dpElement, dpSubStr(dpe, DPSUB_SYS_DP), "");
  dpElementAlias = dpGetAlias(dpName + dpElement);
  dpElementDescription = dpGetDescription(dpName + dpElement);

  dpGet(fwAlarmHandling_HELP_FORMAT_EXTENSIONS, fileSuffix);
  dynAppend(fileSuffix, "");
  
  searchPatterns = makeDynString(
                              //dp descriptions
                              dpSystem + dpElementDescription + dpElement, dpElementDescription + dpElement,
                              dpSystem + dpDescription + dpElement, dpDescription + dpElement,
                              //dp aliases
                              dpSystem + dpElementAlias + dpElement, dpElementAlias + dpElement,
                              dpSystem + dpAlias + dpElement, dpAlias + dpElement,
                              //dp names
                              dpSubStr(dpe, DPSUB_SYS_DP_EL), dpSubStr(dpe, DPSUB_DP_EL),
                              dpSubStr(dpe, DPSUB_SYS_DP), dpSubStr(dpe, DPSUB_DP),
                              //dp types
                              dpSystem + dpType + dpElement, dpType + dpElement,
                              dpSystem + dpType, dpType);
  searchDirectories = makeDynString(
                              //dp descriptions
                              fwAlarmHandling_HELP_PATH_DEVICE_DESCRIPTION_ELEMENT, fwAlarmHandling_HELP_PATH_DEVICE_DESCRIPTION_ELEMENT,
                              fwAlarmHandling_HELP_PATH_DEVICE_DESCRIPTION, fwAlarmHandling_HELP_PATH_DEVICE_DESCRIPTION,
                              //dp aliases
                              fwAlarmHandling_HELP_PATH_DEVICE_ALIAS_ELEMENT, fwAlarmHandling_HELP_PATH_DEVICE_ALIAS_ELEMENT,
                              fwAlarmHandling_HELP_PATH_DEVICE_ALIAS, fwAlarmHandling_HELP_PATH_DEVICE_ALIAS,
                              //dp names
                              fwAlarmHandling_HELP_PATH_DEVICE_ELEMENT, fwAlarmHandling_HELP_PATH_DEVICE_ELEMENT,
                              fwAlarmHandling_HELP_PATH_DEVICE, fwAlarmHandling_HELP_PATH_DEVICE,
                              //dp types
                              fwAlarmHandling_HELP_PATH_DEVICE_TYPE_ELEMENT, fwAlarmHandling_HELP_PATH_DEVICE_TYPE_ELEMENT,
                              fwAlarmHandling_HELP_PATH_DEVICE_TYPE, fwAlarmHandling_HELP_PATH_DEVICE_TYPE);
  	
  if(fwAlarmHandling_getCustomHelpFile(dpe, fileName, exceptionInfo))
    return;
	
  for(int i=1; i<=dynlen(searchPatterns); i++)
  {
    _fwAlarmHandling_convertDpNameToFileName(searchPatterns[i], fileNameToCheck, exceptionInfo);

    for(int j=1; j<=dynlen(fileSuffix); j++)
    {
      fileName = getPath(HELP_REL_PATH, fwAlarmHandling_HELP_PATH_ROOT + searchDirectories[i] + fileNameToCheck + fileSuffix[j]);
//DebugN(fileName, fwAlarmHandling_HELP_PATH_ROOT + searchDirectories[i] + fileNameToCheck + fileSuffix[j]);
      if(fileName != "")
        return;
    }
  }
 		
  fileName = getPath(HELP_REL_PATH, fwAlarmHandling_HELP_PATH_ROOT + fwAlarmHandling_HELP_FILE_DEFAULT);
//DebugN(fileName, fwAlarmHandling_HELP_PATH_ROOT + fwAlarmHandling_HELP_FILE_DEFAULT);
}

/** Returns a list of data points that match the given criteria.
The result returned is as follows:
result = ((dps that meet ALL DP name filter) && (dps that meet ALL DP alias filters)) of ANY specified type, on ANY specified system

@par Constraints
	None

@par Usage
	Public

@par PVSS managers
	VISION, CTRL

@param systemNameFilters	A list of systems to search in.  The criteria are OR'ed
@param dpNameFilters		A list of criteria to filter on the dp name.  The criteria are AND'ed.  
@param dpAliasFilters		A list of criteria to filter on the dp alias.  The criteria are AND'ed.  
@param dpTypeFilters		A list of data point types to search.  The criteria are ORed.
@param matchingDps		The list of matching dps is returned here.
@param exceptionInfo		Details of any exceptions are returned here   
*/
fwAlarmHandling_getDpsMatchingCriteria(dyn_string systemNameFilters, dyn_string dpNameFilters, dyn_string dpAliasFilters, dyn_string dpTypeFilters,
															dyn_string &matchingDps, dyn_string &exceptionInfo)
{
	int i, j, k, length, numberOfSystems, numberOfTypes, numberOfDpFilters, numberOfAliasFilters;
	dyn_string searchResult, dps, aliases;
  string sDpPattern;
	
// DebugN(systemNameFilters, dpNameFilters, dpAliasFilters, dpTypeFilters);

	if(dynlen(systemNameFilters) == 0)
		systemNameFilters[1] = "*:";
	
	if(dynlen(dpNameFilters) == 0)
		dpNameFilters[1] = "*";

	if(dynlen(dpTypeFilters) == 0)
		dpTypeFilters[1] = "";

	matchingDps = makeDynString();
	numberOfSystems = dynlen(systemNameFilters);
	numberOfTypes = dynlen(dpTypeFilters);
	numberOfDpFilters = dynlen(dpNameFilters);
	numberOfAliasFilters = dynlen(dpAliasFilters);
	
	for(i=1; i<=numberOfSystems; i++)
	{
		if(strpos(systemNameFilters[i], ":") != (strlen(systemNameFilters[i]) - 1))
			systemNameFilters[i] = systemNameFilters[i] += ":";

		for(j=1; j<=numberOfTypes; j++)
		{
			for(k=1; k<=numberOfDpFilters; k++)
			{
        if(dpSubStr(dpNameFilters[k],DPSUB_SYS)=="")
          sDpPattern = systemNameFilters[i] + dpNameFilters[k];
        else
          sDpPattern = dpNameFilters[k];
// DebugN("DP NAME FILTER", sDpPattern, dpTypeFilters[j]);
				searchResult = dpNames(sDpPattern, dpTypeFilters[j]);
// DebugN("DP NAME FILTER RES", sDpPattern, dpTypeFilters[j], searchResult);
				if(k==1)
					dps = searchResult;
				else
          dynAppend(dps, searchResult);
// 					dps = dynIntersect(dps, searchResult);
			}

			for(k=1; k<=numberOfAliasFilters; k++)
			{
				searchResult = dpNames(systemNameFilters[i] + "@" + dpAliasFilters[k], dpTypeFilters[j]);
// DebugN("DP ALIAS FILTER", systemNameFilters[i] + "@" + dpAliasFilters[k], dpTypeFilters[j], searchResult);
				if(k==1)
					aliases = searchResult;
				else
          dynAppend(aliases, searchResult);
// 					aliases = dynIntersect(dps, searchResult);
			}
			length = dynlen(aliases);
			for(k=1; k<=length; k++)
				aliases[k] = strrtrim(aliases[k], ".");
			dynUnique(aliases);

			if(numberOfAliasFilters == 0)
				dynAppend(matchingDps, dps);
			else
				dynAppend(matchingDps, aliases);
// 				dynAppend(matchingDps, dynIntersect(dps, aliases));
		}
	}
  dynUnique(matchingDps);

//DebugN("matchingDps:",matchingDps);    
}

/** Opens a JCOP Alarm Screen with the default filter - filter shows ALL alarms in ALL systems.

@par Constraints
	None

@par Usage
	Public

@par PVSS managers
	VISION, CTRL

@param bAsNewModule		input, should the display be opened in a new module, TRUE = new module, FALSE = child panel
@param bStayOnTopOrModal	input, for a new module - TRUE = stay on top, FALSE = normal behaviour
					for a child panel - TRUE = modal child panel, FALSE = normal behaviour
@param sModuleName		input, the name of the new module (if required)
@param sPanelName		input, the name of the new panel
@param exceptionInfo		Details of any exceptions are returned here 
@param x			input, Optional parameter - default value 0.  X position of the new display
@param y			input, Optional parameter - default value 0.  Y position of the new display
*/
fwAlarmHandling_openScreen(bool bAsNewModule, bool bStayOnTopOrModal, string sModuleName, string sPanelName, dyn_string &exceptionInfo, unsigned x = 0, unsigned y = 0)
{
	dyn_dyn_anytype filter;

	_fwAlarmHandlingScreen_getDefaultFilter(filter, exceptionInfo);
	fwAlarmHandling_openScreenWithFilter(filter, bAsNewModule, bStayOnTopOrModal, sModuleName, sPanelName, exceptionInfo, x, y);
}

/** Opens a JCOP Alarm Screen to monitor a specific list of DPEs.

@par Constraints
	None

@par Usage
	Public

@par PVSS managers
	VISION, CTRL

@param dpeList			input, the list of data points or data point elements that the alarm screen should monitor and display
@param bAsNewModule		input, should the display be opened in a new module, TRUE = new module, FALSE = child panel
@param bStayOnTopOrModal	input, for a new module - TRUE = stay on top, FALSE = normal behaviour
					for a child panel - TRUE = modal child panel, FALSE = normal behaviour
@param sModuleName		input, the name of the new module (if required)
@param sPanelName		input, the name of the new panel
@param exceptionInfo		Details of any exceptions are returned here 
@param x			input, Optional parameter - default value 0.  X position of the new display
@param y			input, Optional parameter - default value 0.  Y position of the new display
*/
fwAlarmHandling_openScreenWithDpeList(dyn_string dpeList, bool bAsNewModule, bool bStayOnTopOrModal, string sModuleName, string sPanelName, dyn_string &exceptionInfo, unsigned x = 0, unsigned y = 0)
{
	int i, length;
	dyn_dyn_anytype filter;

	length = dynlen(dpeList);

	_fwAlarmHandlingScreen_getDefaultFilter(filter, exceptionInfo);

	filter[fwAlarmHandlingScreen_CONFIG_OBJECT_FILTER_DP_NAME] = makeDynAnytype();
	for(i=1; i<=length; i++)
		filter[fwAlarmHandlingScreen_CONFIG_OBJECT_FILTER_DP_NAME][1] += dpeList[i] + fwAlarmHandlingScreen_DPE_LIST_DIVIDER;
	filter[fwAlarmHandlingScreen_CONFIG_OBJECT_FILTER_DP_NAME][1] = strrtrim(filter[fwAlarmHandlingScreen_CONFIG_OBJECT_FILTER_DP_NAME][1], fwAlarmHandlingScreen_DPE_LIST_DIVIDER);

	fwAlarmHandling_openScreenWithFilter(filter, bAsNewModule, bStayOnTopOrModal, sModuleName, sPanelName, exceptionInfo, x, y);
}

/** Opens a JCOP Alarm Screen with the specified pre-saved filter.

@par Constraints
	None

@par Usage
	Public

@par PVSS managers
	VISION, CTRL

@param filterName		input, the name of the pre-saved filter that should be loaded and displayed
@param bAsNewModule		input, should the display be opened in a new module, TRUE = new module, FALSE = child panel
@param bStayOnTopOrModal	input, for a new module - TRUE = stay on top, FALSE = normal behaviour
					for a child panel - TRUE = modal child panel, FALSE = normal behaviour
@param sModuleName		input, the name of the new module (if required)
@param sPanelName		input, the name of the new panel
@param exceptionInfo		Details of any exceptions are returned here 
@param x			input, Optional parameter - default value 0.  X position of the new display
@param y			input, Optional parameter - default value 0.  Y position of the new display
*/
fwAlarmHandling_openScreenWithSavedFilter(string filterName, bool bAsNewModule, bool bStayOnTopOrModal, string sModuleName, string sPanelName, dyn_string &exceptionInfo, unsigned x = 0, unsigned y = 0)
{
	dyn_dyn_anytype filter;

	if(strpos(dpSubStr(filterName, DPSUB_DP), fwAlarmHandlingScreen_FILTER_DP_PREFIX) != 0)
		filterName = fwAlarmHandlingScreen_FILTER_DP_PREFIX + filterName;

	fwAlarmHandlingScreen_loadFilter(filterName, filter, exceptionInfo);
	fwAlarmHandling_openScreenWithFilter(filter, bAsNewModule, bStayOnTopOrModal, sModuleName, sPanelName, exceptionInfo, x, y, filterName);
}

/** Opens a JCOP Alarm Screen with the specified custom filter.

@par Constraints
	None

@par Usage
	Public

@par PVSS managers
	VISION, CTRL

@param filter			input, the filter shoule be passed here,
					check the fwAlarmHandlingScreen_CONFIG_OBJECT_FILTER_XXX constants that define the filter object
@param bAsNewModule		input, should the display be opened in a new module, TRUE = new module, FALSE = child panel
@param bStayOnTopOrModal	input, for a new module - TRUE = stay on top, FALSE = normal behaviour
					for a child panel - TRUE = modal child panel, FALSE = normal behaviour
@param sModuleName		input, the name of the new module (if required)
@param sPanelName		input, the name of the new panel
@param exceptionInfo		Details of any exceptions are returned here 
@param x			input, Optional parameter - default value 0.  X position of the new display
@param y			input, Optional parameter - default value 0.  Y position of the new display
@param sFilterName			input, Optional parameter - default value "".  Filter name to be shown on the Quick Filters box
*/
fwAlarmHandling_openScreenWithFilter(dyn_dyn_anytype filter, bool bAsNewModule, bool bStayOnTopOrModal, string sModuleName, string sPanelName, dyn_string &exceptionInfo, unsigned x = 0, unsigned y = 0, string sFilterName="")
{
	string sPanelFileName = fwAlarmHandlingScreen_PANEL_NAME;
	dyn_string dollarParams;
	
	dollarParams = makeDynString(	"$bShowWarnings:" + (bool)filter[fwAlarmHandlingScreen_CONFIG_OBJECT_FILTER_SEVERITY][fwAlarmHandlingScreen_SEVERITY_FILTER_OBJECT_WARNING],
					"$bShowErrors:" + (bool)filter[fwAlarmHandlingScreen_CONFIG_OBJECT_FILTER_SEVERITY][fwAlarmHandlingScreen_SEVERITY_FILTER_OBJECT_ERROR],
					"$bShowFatals:" + (bool)filter[fwAlarmHandlingScreen_CONFIG_OBJECT_FILTER_SEVERITY][fwAlarmHandlingScreen_SEVERITY_FILTER_OBJECT_FATAL],
					"$dsSystemNames:" + filter[fwAlarmHandlingScreen_CONFIG_OBJECT_FILTER_SYSTEM],
					"$sAlertTextFilter:" + filter[fwAlarmHandlingScreen_CONFIG_OBJECT_FILTER_ALERT_TEXT],
					"$sDeviceAliasFilter:" + filter[fwAlarmHandlingScreen_CONFIG_OBJECT_FILTER_DP_ALIAS],
					"$sDeviceDescriptionFilter:" + filter[fwAlarmHandlingScreen_CONFIG_OBJECT_FILTER_DESCRIPTION],
					"$sDeviceNameFilter:" + filter[fwAlarmHandlingScreen_CONFIG_OBJECT_FILTER_DP_NAME],
					"$sDeviceTypeFilter:" + filter[fwAlarmHandlingScreen_CONFIG_OBJECT_FILTER_DP_TYPE],
					"$iLocalOrGlobal:" + filter[fwAlarmHandlingScreen_CONFIG_OBJECT_FILTER_LOCAL_OR_GLOBAL],
					"$sFilterName:" + sFilterName
					);
	

	if(bAsNewModule)
	{
		ModuleOnWithPanel(sModuleName,
		                   x, y, 0, 0, 0, 0, "",
		                   sPanelFileName,
		                   sPanelName,
		                   dollarParams);
		               		
		stayOnTop(bStayOnTopOrModal, sModuleName);
	}
	else
	{
		if(!bStayOnTopOrModal)
		{
		  ChildPanelOn(sPanelFileName,
							      sPanelName,
							      dollarParams,
							      x, y);
		}
		else
		{
		  ChildPanelOnModal(sPanelFileName,
							      sPanelName,
							      dollarParams,
							      x, y);
		}
	}
}

fwAlarmHandling_getHelpFileFormats(dyn_string &fileExtensions, dyn_string &windowsCommand, dyn_string &linuxCommand, dyn_string &exceptionInfo)
{
  int numberOfExtensions;
  
  dpGet(fwAlarmHandling_HELP_FORMAT_EXTENSIONS, fileExtensions,
        fwAlarmHandling_HELP_FORMAT_COMMANDS_WINDOWS, windowsCommand,
        fwAlarmHandling_HELP_FORMAT_COMMANDS_LINUX, linuxCommand);

  numberOfExtensions = dynlen(fileExtensions);
  if(dynlen(windowsCommand) < numberOfExtensions)
    windowsCommand[numberOfExtensions] = "";
  if(dynlen(linuxCommand) < numberOfExtensions)
    linuxCommand[numberOfExtensions] = "";        
}

fwAlarmHandling_setHelpFileFormats(dyn_string fileExtensions, dyn_string windowsCommand, dyn_string linuxCommand, dyn_string &exceptionInfo)
{
  int numberOfExtensions;
  
  dpSetWait(fwAlarmHandling_HELP_FORMAT_EXTENSIONS, fileExtensions,
            fwAlarmHandling_HELP_FORMAT_COMMANDS_WINDOWS, windowsCommand,
            fwAlarmHandling_HELP_FORMAT_COMMANDS_LINUX, linuxCommand);
}

_fwAlarmHandling_createPlotDp(string plotName)
{
  dyn_string exceptionInfo;
  dyn_dyn_anytype plotData;
  
  if(!isFunctionDefined("fwTrending_createPlot"))
    return;
  
  if(!dpExists(plotName))
  {
    plotData[fwTrending_PLOT_OBJECT_MODEL][1] = fwTrending_YT_PLOT_MODEL;
    plotData[fwTrending_PLOT_OBJECT_TITLE][1] = "Settings for Alarm Screen Plot"; 
    plotData[fwTrending_PLOT_OBJECT_LEGEND_ON][1] = FALSE; 
    plotData[fwTrending_PLOT_OBJECT_BACK_COLOR][1] = "FwTrendingTrendBackground"; 
    plotData[fwTrending_PLOT_OBJECT_FORE_COLOR][1] = "FwTrendingTrendForeground"; 
    plotData[fwTrending_PLOT_OBJECT_DPES] = makeDynString("{dpe1}", "{dpe2}", "{dpe3}", "{dpe4}", "{dpe5}", "{dpe6}", "{dpe7}", "{dpe8}"); 
    plotData[fwTrending_PLOT_OBJECT_DPES_X] = makeDynString(); 
    plotData[fwTrending_PLOT_OBJECT_LEGENDS] = makeDynString("{dpe1}", "{dpe2}", "{dpe3}", "{dpe4}", "{dpe5}", "{dpe6}", "{dpe7}", "{dpe8}"); 
    plotData[fwTrending_PLOT_OBJECT_LEGENDS_X] = makeDynString(); 
    plotData[fwTrending_PLOT_OBJECT_COLORS] = makeDynString("FwTrendingCurve2", "FwTrendingCurve3", "FwTrendingCurve4", "FwTrendingCurve5",
                                                            "FwTrendingCurve7", "FwTrendingCurve1", "FwTrendingCurve6", "FwTrendingCurve8"); 
    plotData[fwTrending_PLOT_OBJECT_AXII] = makeDynBool(TRUE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE); 
    plotData[fwTrending_PLOT_OBJECT_AXII_X] = makeDynBool(); 
    plotData[fwTrending_PLOT_OBJECT_IS_TEMPLATE][1] = FALSE; 
    plotData[fwTrending_PLOT_OBJECT_CURVES_HIDDEN] = makeDynBool(FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE);; 
    plotData[fwTrending_PLOT_OBJECT_RANGES_MIN] = makeDynInt(0,0,0,0,0,0,0,0); 
    plotData[fwTrending_PLOT_OBJECT_RANGES_MAX] = makeDynInt(0,0,0,0,0,0,0,0); 
    plotData[fwTrending_PLOT_OBJECT_RANGES_MIN_X] = makeDynInt(); 
    plotData[fwTrending_PLOT_OBJECT_RANGES_MAX_X] = makeDynInt(); 
    plotData[fwTrending_PLOT_OBJECT_TYPE][1] = fwTrending_PLOT_TYPE_STEPS; 
    plotData[fwTrending_PLOT_OBJECT_TIME_RANGE][1] = 3600; 
    plotData[fwTrending_PLOT_OBJECT_TEMPLATE_NAME][1] = ""; 
    plotData[fwTrending_PLOT_OBJECT_IS_LOGARITHMIC][1] = FALSE; 
    plotData[fwTrending_PLOT_OBJECT_GRID][1] = TRUE; 
    plotData[fwTrending_PLOT_OBJECT_CURVE_TYPES] = makeDynInt(fwTrending_PLOT_TYPE_STEPS, fwTrending_PLOT_TYPE_STEPS,
                                                              fwTrending_PLOT_TYPE_STEPS, fwTrending_PLOT_TYPE_STEPS,
                                                              fwTrending_PLOT_TYPE_STEPS, fwTrending_PLOT_TYPE_STEPS,
                                                              fwTrending_PLOT_TYPE_STEPS, fwTrending_PLOT_TYPE_STEPS);
    plotData[fwTrending_PLOT_OBJECT_MARKER_TYPE][1] = fwTrending_MARKER_TYPE_FILLED_CIRCLE;
    plotData[fwTrending_PLOT_OBJECT_ACCESS_CONTROL_SAVE][1] = "";
    plotData[fwTrending_PLOT_OBJECT_ALARM_LIMITS_SHOW]= makeDynString(1,0,0,0,0,0,0,0);
    plotData[fwTrending_PLOT_OBJECT_CONTROL_BAR_ON][1] = 3;   
    plotData[fwTrending_PLOT_OBJECT_DEFAULT_FONT][1] = fwTrending_DEFAULT_FONT;
    plotData[fwTrending_PLOT_OBJECT_CURVE_STYLE][1] = "[solid,oneColor,JoinMiter,CapButt,2]";
    fwTrending_createPlot(plotName, exceptionInfo);
    if(dynlen(exceptionInfo) == 0)
    {
      while(!dpExists(plotName))
      delay(0,100);
    }
  }
  else
  {
    fwTrending_getPlot(plotName, plotData, exceptionInfo);
    plotData[fwTrending_PLOT_OBJECT_TYPE][1] = fwTrending_PLOT_TYPE_STEPS; 
    plotData[fwTrending_PLOT_OBJECT_CURVE_TYPES] = makeDynInt(fwTrending_PLOT_TYPE_STEPS, fwTrending_PLOT_TYPE_STEPS,
                                                            fwTrending_PLOT_TYPE_STEPS, fwTrending_PLOT_TYPE_STEPS,
                                                            fwTrending_PLOT_TYPE_STEPS, fwTrending_PLOT_TYPE_STEPS,
                                                            fwTrending_PLOT_TYPE_STEPS, fwTrending_PLOT_TYPE_STEPS);
    plotData[fwTrending_PLOT_OBJECT_ALARM_LIMITS_SHOW]= makeDynString(1,0,0,0,0,0,0,0);
    plotData[fwTrending_PLOT_OBJECT_CONTROL_BAR_ON][1] = 3;     
    plotData[fwTrending_PLOT_OBJECT_DEFAULT_FONT][1] = fwTrending_DEFAULT_FONT;
    plotData[fwTrending_PLOT_OBJECT_CURVE_STYLE][1] = "[solid,oneColor,JoinMiter,CapButt,2]";
  }
  fwTrending_setPlot(plotName, plotData, exceptionInfo);
}


/** Checks if the alarm screen configuration stored in _AESConfig is the one for JCOP FW.

@par Constraints
	None

@par Usage
	Public

@par PVSS managers
	VISION, CTRL

@return true if the config is for JCOP fw, false if else (i.e. it can be UNICOS config)
@see fwAlarmHandling_AESConfig_isForUn()
@see fwAlarmHandling_AESConfig_useUnConfig()
@see fwAlarmHandling_AESConfig_useFwConfig()
*/
bool fwAlarmHandling_AESConfig_isForFw()
{
  dyn_string ds_extFunc;  
  string s_aes = "_AESConfig.functions.alerts.extFunc";
  if(!dpExists(s_aes))
	return false;
  dpGet(s_aes, ds_extFunc);
  if(dynlen(ds_extFunc))
  {
    if(patternMatch("fwAlarmHandling*",ds_extFunc[1])) 
      return true;
  }
  return false;
}


/** Checks if the alarm screen configuration stored in _AESConfig is the one for UNICOS.

@par Constraints
	None

@par Usage
	Public

@par PVSS managers
	VISION, CTRL

@return true if the config is for UNICOS, false if else (i.e. it can be JCOP framework config)
@see fwAlarmHandling_AESConfig_isForFw()
@see fwAlarmHandling_AESConfig_useUnConfig()
@see fwAlarmHandling_AESConfig_useFwConfig()
*/
bool fwAlarmHandling_AESConfig_isForUn()
{
  dyn_string ds_extFunc;
  string s_aes = "_AESConfig.functions.alerts.extFunc";
  if(!dpExists(s_aes))
	return false;
  dpGet(s_aes, ds_extFunc);
  if(dynlen(ds_extFunc))
  {
    if(patternMatch("unAS_*",ds_extFunc[1])) 
      return true;
  }
  return false;
}


/** Applies the alarm screen configuration (stored in _AESConfig) for the JCOP FW.

@par Constraints
	None

@par Usage
	Public

@par PVSS managers
	VISION, CTRL

@param exceptionInfo errors returned here
@return true if success
@see fwAlarmHandling_AESConfig_isForUn()
@see fwAlarmHandling_AESConfig_isForFw()
@see fwAlarmHandling_AESConfig_useUnConfig()
*/
bool fwAlarmHandling_AESConfig_useFwConfig(dyn_string exceptionInfo)
{
  dyn_string ds_exceptioninfo;
  bool b_ret;
  string s_dpSource = "_AESConfig_fwAes";
  string s_dpDest = "_AESConfig";
  
  //set alarm panel config
  b_ret = aes_copyDp( s_dpSource, s_dpDest );
  if(!b_ret)
  {
    fwException_raise(ds_exceptioninfo,"fwAlarmHandling_AESConfig_useFwConfig - ERROR in copying the dp from " + s_dpSource + " to " +s_dpDest);
  }
  //set alarm row config
  s_dpSource = "_AESConfigRowRestore";
  s_dpDest = "_AESConfigRow";  
  b_ret = aes_copyDp( s_dpSource, s_dpDest );
  if(!b_ret)
  {
    fwException_raise(ds_exceptioninfo,"fwAlarmHandling_AESConfig_useFwConfig - ERROR in copying the dp from " + s_dpSource + " to " +s_dpDest);
  }
  return b_ret;
}


/** Applies the alarm screen configuration (stored in _AESConfig) for the UNICOS.

@par Constraints
	None

@par Usage
	Public

@par PVSS managers
	VISION, CTRL

@param exceptionInfo errors returned here
@return true if success
@see fwAlarmHandling_AESConfig_isForUn()
@see fwAlarmHandling_AESConfig_isForFw()
@see fwAlarmHandling_AESConfig_useFwConfig()
*/
bool fwAlarmHandling_AESConfig_useUnConfig(dyn_string exceptionInfo)
{
  dyn_string ds_exceptioninfo;
  bool b_ret;
  string s_dpSource = "_AESConfig_unAlertScreen";
  string s_dpDest = "_AESConfig";
  
  //set alarm panel config
  b_ret = aes_copyDp( s_dpSource, s_dpDest );
  if(!b_ret)
  {
    fwException_raise(ds_exceptioninfo,"fwAlarmHandling_AESConfig_useUnConfig - ERROR in copying the dp from " + s_dpSource + " to " +s_dpDest);
  }
  //set alarm row config
  s_dpSource = "_AESConfigRow_unAlertRow";
  s_dpDest = "_AESConfigRow";
  b_ret = aes_copyDp( s_dpSource, s_dpDest );
  if(!b_ret)
  {
    fwException_raise(ds_exceptioninfo,"fwAlarmHandling_AESConfig_useUnConfig - ERROR in copying the dp from " + s_dpSource + " to " +s_dpDest);
  }
  return b_ret;
}


//@}
