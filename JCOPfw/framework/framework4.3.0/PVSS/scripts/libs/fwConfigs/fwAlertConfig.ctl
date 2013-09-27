//need to guarantee this library is loaded
//aes.ctl is not normally loaded for CTRL managers and we need it for isAlertFileringActive()
#uses "aes.ctl"
//import deprecated functions
#uses "fwConfigs/fwAlertConfigDeprecated.ctl"
/**@file

This library contains function associated with the alert handling config.
Functions are provided for getting the current settings, deleting the config
and for creating or altering the config
Seperate functions for digital, analog and summary type alerts are available.
<B>Note:</B> In order to set/get alarms, it is recommended to use the new functions fwAlertConfig_objectSet(), fwAlertConfig_objectGet(), fwAlertConfig_objectSetMany(), fwAlertConfig_objectGetMany(). See the functions for use examples.

@par Creation Date
	14/03/2000

@par Modification History

  14/09/2011 Marco Boccioli
  - @sav{86729}: fwAlertConfig: move deprecated functions to a separate library fwAlertConfigDeprecated.ctl
  - @sav{86692}: add func to get alert type. Added function fwAlertConfig_objectGetType() 
  - @sav{86693}: improve help documentation. Improved documentation, adding markups for user's manual.
  
  12/08/2011 Marco Boccioli
  - @sav{85462}: Functions *_setMany and *_getMany with parameters as reference.
  
  28/07/2011 Marco Boccioli
  - @sav{84905}: Discrete alarms: alarm not working if range has more than one value. The problem was on the rfact that discrete alarms have 2 types: 
    _SET (for values like "1,3,4") and _MATCH (for values lie "12" or "12-23"). Modified functions: 
    fwAlertConfig_objectGetMany() now needs to make a further scan of dpGet: once to get the type of discrete alarm, once to get the value from attribute _set or _match, according to the type. 
    _fwAlertConfig_prepareAnalogDiscrete() now sets the discrete value to _set or to _match, according to the ype of value (coma-separated or range or single)..
    Such feature is temporarely disabled because of bug on PVSS 3.8.2 (@jira{ETM-826}).
  
  18/07/2011 Marco Boccioli
  - @jira{JCOP-121}: fwAlertConfig_objectGetMany() - strange error returned in exceptionInfo. The way the exception is thrown was corrected.

  24/03/2011 Marco Boccioli
  - fix for @sav{79936} (modifying alert results in deactivating the alert). 
    The object setting parameter fwAlertConfig_ALERT_PARAM_ACTIVE cannot be used any more as setting, otherwise it
    overwrites the active status of the alarm in case of modification of the settings. fwAlertConfig_ALERT_PARAM_ACTIVE
    is now available Read Only.

  16/02/2011 Marco Boccioli
  - fix for @sav{78303} (cannot add decimals to limits).

  09/02/2011 Marco Boccioli
  - fix for @sav{77977} (sum alarm threshold is not applied when using fwAlertConfig_set).

  25/11/2010 Marco Boccioli
  - fix for @jira{JCOP-62} and @sav{75697} (set an alarm with the JCOP fwConfigs function): modified function _fwAlertConfig_prepareAnalog():
    It now checks if the Went text is filled. If not, it does not set at all the attribute _went_text. This avoids
    problems if setting alarm on a dist system running on PVSS 3.6.

  11/10/2010 Marco Boccioli
  - fix for bug @sav{73869}: Error printed when setting binary alerts. 
    The function fwAlertConfig_objectSetMany() was looking for .._num_ranges also for binary alert (that don't have it)

  09/08/2010 Marco Boccioli
  - fix for bug @sav{71138}: the fwAlertConfig_objectSet() was shifting the limits.
    
  12/07/2010 Marco Boccioli
  - fix for bug @sav{48354}: the "went" text can be set using fwAlertConfig_objectSet().
  - fix for bug @sav{68528}: the "included" limits are available if using fwAlertConfig_objectSet().
  - fix for bug @sav{21219}: fwAlertConfig_objectGetMany() is making use of dpGet 3 times, regardless 
    from the amount of dpes. 3 times faster than fwAlertConfig_getMany().
  - improvement for bug @sav{67230}: created new set of functions (fwAlertConfig_object...). 
    Those functions allow setting an alarm by means of an object. 
    The user should: 
    - initialize the object (fwAlertConfig_objectInitialize())
    - populate the object with alarm settings (fwAlertConfig_objectCreate...)
    - apply the object to the dpe(s) (fwAlertConfig_objectSet()).
    In order to read alarm settings:
    - get the settings from dpe(s) (fwAlertConfig_objectGet())
    - extract the settings from the object (fwAlertConfig_objectExtract...)           
    Elements of an object can be accessed directly using the indexes provided below
    ("indexes for alarm limits object" and "indexes for alarm parameters object")
  - fix for bug @sav{67230}: added optional parameters for discrete alarms to fwAlertConfig_set(),
        fwAlertConfig_setMany(), fwAlertConfig_setMultiple().
        For back-compatibility, nothing was added to fwAlertConfig_get() and fwAlertConfig_getMany() 
        (discrete alarms details cannot be retrieved with those functions). 
        In order to get discrete alarms, added functions: fwAlertConfig_getDiscrete().
        For consistency, added also: fwAlertConfig_setDiscrete(). 
        
  05/05/2010 Marco Boccioli
  - fix for bug @sav{66963}: modified the call of fwAlertConfig_set() at fwAlertConfig_deleteDpFromAlertSumma()ry 
    and fwAlertConfig_addDpInAlertSummary().
    
  10/03/2010 Marco Boccioli
  - fix for bug @sav{62428}: On _fwAlertConfig_prepareSummary(), added a few lines:
    now, if the dpElementList is empty, the function removes the _dp_list and cleans the _dp_pattern. 
    
  16/01/2004 Oliver Holme (IT-CO) 
  - Added new functions for activate/deactivate/acknowledge and set/getLimits
  
  15/01/2004 Oliver Holme (IT-CO) 
  - Completed major overhaul of whole library
  
  05/05/2000 Herve Milcent
  - problem with a summary alert with an empty list of dp, add a 
				  dummy dp to avoid it when creating the alert sum: compCreateAlertConfigSum
	
@par Constraints
	WARNING: the functions use the dpGet or dpSetWait, problems may occur when using these functions 
          		in a working function called by a PVSS (dpConnect) or in a calling function 

@ingroup fwConfigsAlert

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
//max ranges supported by PVSS
const int fwAlertConfig_ALERT_MAX_PARAM_RANGES = 20;

/**
 * @name Alarm Settings object indexes
   Used to access directly the alert settings object (object of type dyn_mixed). For advanced use.
 * @{
*/

//indexes for alarm limits object 
/**
  @ingroup fwConfigsAlert
  @par Description
Limit configuration item. Text of the alarm range, shown when the alert is flagged as CAME.
  @par Parameter Type
string
  @par Usage
Compulsory. 
See use example on fwAlertConfig_objectSet().
**/
const int fwAlertConfig_ALERT_LIMIT_TEXT = 1;

/**
  @ingroup fwConfigsAlert
  @par Description
Limit configuration item. Value of the alarm range.
  @par Parameter Type
float
  @par Usage
Compulsory for analog alarms. For analog alarms only.
See use example on fwAlertConfig_objectSet().
**/
const int fwAlertConfig_ALERT_LIMIT_VALUE = 2;

/**
  @ingroup fwConfigsAlert
  @par Description
Limit configuration item. Specify if the value of the alarm range must be included (<=) or not (<). 
True means included.
  @par Parameter Type
bool
  @par Usage
Optional. For analog alarms.  Default value is false.
See use example on fwAlertConfig_objectSet().
**/
const int fwAlertConfig_ALERT_LIMIT_VALUE_INCLUDED = 3;

/**
  @ingroup fwConfigsAlert
  @par Description
Limit configuration item. Class of the alarm range. The ok range must be an empty string "". 
For more info, refer to PVSS help.
  @par Parameter Type
string
  @par Usage
Compulsory. For all types of alarms.
See use example on fwAlertConfig_objectSet().
**/
const int fwAlertConfig_ALERT_LIMIT_CLASS = 4;

/**
  @ingroup fwConfigsAlert
  @par Description
Limit configuration item. Value to match for the alarm range. 
Can be one value (i.e. "3"), a set of values (i.e. "3,5,6"), or a range (i.e. "3-7")
  @par Parameter Type
string
  @par Usage
Compulsory for discrete alarms. For discrete alarms only.
See use example on fwAlertConfig_objectSet().
**/
const int fwAlertConfig_ALERT_LIMIT_VALUE_MATCH = 5;

/**
  @ingroup fwConfigsAlert
  @par Description
Limit configuration item. If true, the value to match for the alarm range is negated (!=).
If false, the value must match (=).
  @par Parameter Type
bool
  @par Usage
Optional. For discrete alarms only. Default value is false.
See use example on fwAlertConfig_objectSet().
**/
const int fwAlertConfig_ALERT_LIMIT_NEGATION = 8;

/**
  @ingroup fwConfigsAlert
  @par Description
Limit configuration item. State bits values that must match. For more detail, see PVSS help.
  @par Parameter Type
string
  @par Usage
Optional. For discrete alarms only. Default value is "". Possible values: 1, 0, X (ex: "11000000000000000000000001010101XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX"). 
0 = must be 0; 1 = must be 1; X = can be 0 or 1. 
Note: all the 64 bits must be given.
See use example on fwAlertConfig_objectSet().
**/
const int fwAlertConfig_ALERT_LIMIT_STATE_BITS = 9;

/**
  @ingroup fwConfigsAlert
  @par Description
Limit configuration item. State bits values that must match for a specific range. For more detail, see PVSS help.
  @par Parameter Type
string
  @par Usage
Optional. For discrete alarms only. Default value is "". Possible values: 1, 0 (ex: "1100000000000000000000000101010100000000000000000000000000000000"). 
0 = must be 0; 1 = must be 1. 
Note: all the 64 bits must be given.
See use example on fwAlertConfig_objectSet().
**/
const int fwAlertConfig_ALERT_LIMIT_LIMITS_STATE_BITS = 10;

/**
  @ingroup fwConfigsAlert
  @par Description
Limit configuration item. Text of the alarm range, shown when the alert is flagged as WENT.
  @par Parameter Type
string
  @par Usage
Optional. For all types of alarms. Default value is "".
See use example on fwAlertConfig_objectSet().
**/
const int fwAlertConfig_ALERT_LIMIT_TEXT_WENT = 11;



//indexes for alarm parameters object 

/**
  @ingroup fwConfigsAlert
  @par Description
General parameter item. Type of alarm. Possible values:
  - DPCONFIG_NONE
  - DPCONFIG_ALERT_BINARYSIGNAL
  - DPCONFIG_ALERT_NONBINARYSIGNAL
  - DPCONFIG_SUM_ALERT
  .
For more info, refer to PVSS help.
  @par Parameter Type
int
  @par Usage
Compulsory. For all types of alarms. See use example on fwAlertConfig_objectSet().
**/
const int fwAlertConfig_ALERT_PARAM_TYPE = 1;

/**
  @ingroup fwConfigsAlert
  @par Description
General parameter item. For summary alert, list of DPEs to be checked for single alarms.
If you want to specify a DP pattern, then this should entered as the first item in this list.
  @par Parameter Type
dyn_string
  @par Usage
Optional. For summary alarms only. Default value is empty. See use example on fwAlertConfig_objectSet().
**/
const int fwAlertConfig_ALERT_PARAM_SUM_DPE_LIST = 2;

/**
  @ingroup fwConfigsAlert
  @par Description
General parameter item. Used to add the new alert in a summary alert.
						Default value "" means do not add the new alert into a summary.
						You can specify either an absolute DPE name, or a relative path from the DP to which the new alert was saved.
							i.e.
						-	addDpeInSummary = "." will add the new alert on dpes[i] to the summary on the root of the datapoint to which dpes[i] belongs. 
						-	addDpeInSummary = "MyDp.summaries" will add the new alert on dpes[i] to the summary on the dpe called "MyDp.summaries". 
						.
Note: The summary alarms must already exist. If they do not exist, it WILL NOT be created.
  @par Parameter Type
string
  @par Usage
Optional. For alarms of type analog, discrete, binary. Default value is "". See use example on fwAlertConfig_objectSet().
**/
const int fwAlertConfig_ALERT_PARAM_ADD_DPE_TO_SUMMARY = 3;

/**
  @ingroup fwConfigsAlert
  @par Description
General parameter item. Threshold filter parameter for the sum alerts. 
It can be used to specify after how many single alarms only the sum alert should be shown. 
If i.e. the threshold 5 is set and there are five single alarms, only the sum alert is shown in the alert screen. 
  @par Parameter Type
int
  @par Usage
Optional. For summary alarms only. Default value is 0. See use example on fwAlertConfig_objectSet().
**/
const int fwAlertConfig_ALERT_PARAM_SUM_THRESHOLD = 4;

/**
  @ingroup fwConfigsAlert
  @par Description
General parameter item. Displays the file path of the panel to be displayed when an alert occurs.
The path is specified relative to the panel directory. 
  @par Parameter Type
string
  @par Usage
Optional. For all alarms. Default value is "". See use example on fwAlertConfig_objectSet().
**/
const int fwAlertConfig_ALERT_PARAM_PANEL = 5;

/**
  @par Description
General parameter item. Here you can enter $-parameters to be passed when calling the panel 
specified on fwAlertConfig_ALERT_PARAM_PANEL.
  @par Parameter Type
dyn_string
  @par Usage
Optional. For all alarms. Default value is empty. See use example on fwAlertConfig_objectSet().
**/
const int fwAlertConfig_ALERT_PARAM_PANEL_PARAMETERS = 6;

/**
  @par Description
General parameter item. Enter a text to assist the user with information concerning the alert. 
This text can either be interpreted as "pure" text in the control script and displayed in the
panel or also used as a file name (e.g. of an HTML file).
  @par Parameter Type
string
  @par Usage
Optional. For all alarms. Default value is "". See use example on fwAlertConfig_objectSet().
**/
const int fwAlertConfig_ALERT_PARAM_HELP = 7;

/**
  @par Description
General parameter item. Set to true if discrete alarm. To false if else.
  @par Parameter Type
bool
  @par Usage
Optional. For discrete alarms only. See use example on fwAlertConfig_objectSet().
**/
const int fwAlertConfig_ALERT_PARAM_DISCRETE = 8;

/**
  @ingroup fwConfigsAlert
  @par Description
General parameter item. true = impulse alarm. For more info, refer to PVSS help.
  @par Parameter Type
bool
  @par Usage
Optional. For discrete alarms only. Default value is false. See use example on fwAlertConfig_objectSet().
**/
const int fwAlertConfig_ALERT_PARAM_IMPULSE = 9;

/**
  @par Description
General parameter item. Set to true to modify alert without setting "type" attributes.
This is much quicker, but the alert config must already exist, 
be an analog alert and have the same number of ranges as you want. 
  @par Parameter Type
bool
  @par Usage
Optional. For all types of alarms. Default value is false. See use example on fwAlertConfig_objectSet().
**/
const int fwAlertConfig_ALERT_PARAM_MODIFY_ONLY = 10;

/**
  @par Description
General parameter item. Used in combination with modifyOnly. Default value: false.
				-	If modifyOnly = TRUE and fallBackToSet = FALSE, then if the alert config is not compatible an exception is raised. 
				-	If modifyOnly = TRUE and fallBackToSet = TRUE, then if the alert config is not compatible, modifyOnly is treated as if it was FALSE. 
  @par Parameter Type
bool
  @par Usage
Optional. For all types of alarms. Default value is false. See use example on fwAlertConfig_objectSet().
**/
const int fwAlertConfig_ALERT_PARAM_FALLBACK_TO_SET = 11;

/**
  @par Description
General parameter item. You can specify if the change should be stored in the Paramterisation History of PVSS.

  @par Parameter Type
bool
  @par Usage
Optional. For all types of alarms. Default value is true. See use example on fwAlertConfig_objectSet().
**/
const int fwAlertConfig_ALERT_PARAM_STORE_IN_HISTORY = 12;

/**
  @ingroup fwConfigsAlert
  @par Description
General parameter item. Number of alarm ranges.
  @par Parameter Type
int
  @par Usage
Compulsory. For analog and discrete alarms. See use example on fwAlertConfig_objectSet().
**/
const int fwAlertConfig_ALERT_PARAM_RANGES = 13;

/**
  @ingroup fwConfigsAlert
  @par Description
General parameter item. If true, the alarm is active.
  @par Parameter Type
bool
  @par Usage
Optional. READ ONLY. For all types of alarms.
**/
const int fwAlertConfig_ALERT_PARAM_ACTIVE = 14;

/**
  @ingroup fwConfigsAlert
  @par Description
General configuration object. The configuration object contains 2 sub-elements:
- ALERT_PARAM, containing elements for general configuration (type... - all fwAlertConfig_ALERT_PARAM_*).
- ALERT_LIMIT, containing elements concerning limits (text, values, class... - all fwAlertConfig_ALERT_LIMIT_*).
  @par Parameter Type
dyn_dyn_anytype
  @par Usage
Compulsory. For all types of alarms. See use example on fwAlertConfig_objectSet().
**/
const int fwAlertConfig_ALERT_PARAM = 1;

/**
  @ingroup fwConfigsAlert
  @par Description
Limits configuration object. The configuration object contains 2 sub-elements:
- ALERT_PARAM, containing elements for general configuration (type... - all fwAlertConfig_ALERT_PARAM_*).
- ALERT_LIMIT, containing elements concerning limits (text, values, class... - all fwAlertConfig_ALERT_LIMIT_*).
  @par Parameter Type
dyn_dyn_anytype
  @par Usage
Compulsory. For all types of alarms. See use example on fwAlertConfig_objectSet().
 **/
const int fwAlertConfig_ALERT_LIMIT = 2;
//@} // end of Utility functions


//@{

/** Set alarm object based on alarm params and limits. Initialize it. 
  For more info, refer to fwAlertConfig_objectSetMany()
  
@par Constraints 
  None
  
@par Usage
	Internal

@par PVSS managers
	VISION, CTRL

@param alarmParams  output, object containing the alarm parameters.
@param alarmLimits  putput, object containing the alarm limits.
@param totalRanges	 input, alarm ranges.
  */
_fwAlertConfig_objectCreateParams(dyn_dyn_anytype &alarmParams, dyn_dyn_anytype &alarmLimits, int totalRanges)
{
  int i;
  
  totalRanges = (totalRanges<1) ? 1 : totalRanges;
  totalRanges = (totalRanges>fwAlertConfig_ALERT_MAX_PARAM_RANGES) ? fwAlertConfig_ALERT_MAX_PARAM_RANGES : totalRanges;
                 
  for(i=1 ; i<=totalRanges ; i++)
  {
    alarmLimits[i][fwAlertConfig_ALERT_LIMIT_TEXT] = "";
    alarmLimits[i][fwAlertConfig_ALERT_LIMIT_VALUE] = 0.0;
    alarmLimits[i][fwAlertConfig_ALERT_LIMIT_VALUE_INCLUDED] = FALSE;
    alarmLimits[i][fwAlertConfig_ALERT_LIMIT_CLASS] = "";
    alarmLimits[i][fwAlertConfig_ALERT_LIMIT_VALUE_MATCH] = "";
    alarmLimits[i][fwAlertConfig_ALERT_LIMIT_NEGATION] = FALSE;
    alarmLimits[i][fwAlertConfig_ALERT_LIMIT_STATE_BITS] = "";
    alarmLimits[i][fwAlertConfig_ALERT_LIMIT_LIMITS_STATE_BITS] = "";    
    alarmLimits[i][fwAlertConfig_ALERT_LIMIT_TEXT_WENT] = "";
  }    
  alarmParams[fwAlertConfig_ALERT_PARAM_TYPE][1] = DPCONFIG_NONE;
  alarmParams[fwAlertConfig_ALERT_PARAM_SUM_DPE_LIST] = makeDynString("");
  alarmParams[fwAlertConfig_ALERT_PARAM_SUM_THRESHOLD][1] = 0;
  alarmParams[fwAlertConfig_ALERT_PARAM_ADD_DPE_TO_SUMMARY][1] = "";
  alarmParams[fwAlertConfig_ALERT_PARAM_PANEL][1] = "";
  alarmParams[fwAlertConfig_ALERT_PARAM_PANEL_PARAMETERS] = makeDynString();
  alarmParams[fwAlertConfig_ALERT_PARAM_HELP][1] = "";
  alarmParams[fwAlertConfig_ALERT_PARAM_DISCRETE][1] = FALSE;
  alarmParams[fwAlertConfig_ALERT_PARAM_IMPULSE][1] = FALSE;
  alarmParams[fwAlertConfig_ALERT_PARAM_MODIFY_ONLY][1] = FALSE;
  alarmParams[fwAlertConfig_ALERT_PARAM_FALLBACK_TO_SET][1] = FALSE;
  alarmParams[fwAlertConfig_ALERT_PARAM_STORE_IN_HISTORY][1] = FALSE;
  alarmParams[fwAlertConfig_ALERT_PARAM_RANGES][1] = totalRanges;  
  alarmParams[fwAlertConfig_ALERT_PARAM_ACTIVE][1] = FALSE;
}
//@}

/**
 * @name Utility functions
   Used to access the configuration object attributes (object of type dyn_mixed).
 * @{
*/

/** Set alarm object based on alarm params and limits. See note on fwAlertConfig_objectSet() for an example

@ingroup fwConfigsAlert

@par Constraints 
  
@par Usage
	Public

@par PVSS managers
	VISION, CTRL

@param paramsObject  object containing the alarm parameters and limits
@param totalRanges	 alarm ranges
*/
fwAlertConfig_objectInitialize(dyn_mixed &paramsObject, int totalRanges)
{
  dyn_dyn_mixed alarmParams, alarmLimits;
  _fwAlertConfig_objectCreateParams(alarmParams, alarmLimits, totalRanges);
  paramsObject[fwAlertConfig_ALERT_PARAM] = alarmParams;
  paramsObject[fwAlertConfig_ALERT_LIMIT] = alarmLimits;
}

/** Check if the paramaters object contains a configuration

@ingroup fwConfigsAlert

@par Constraints
	
@par Usage
	Public

@par PVSS managers
	VISION, CTRL

@param alertConfigObject  Object containing the alarm config parameters
@param configType	 Returns the type of the current alert config in the object
@param exceptionInfo	Details of any exceptions are returned here   
@return TRUE if the configuration is present, FALSE else.
*/
bool fwAlertConfig_objectConfigExists(dyn_mixed alertConfigObject, int &configType, dyn_string &exceptionInfo)
{  
  dyn_dyn_mixed alertParams, alertLimits;
  
  if(dynlen(alertConfigObject)==0)
    return false;
  alertParams = alertConfigObject[fwAlertConfig_ALERT_PARAM];
  alertLimits = alertConfigObject[fwAlertConfig_ALERT_LIMIT];
  if(dynlen(alertParams)==0)
    return false;
  exceptionInfo = getLastError();
  configType = alertParams[fwAlertConfig_ALERT_PARAM_TYPE][1];
  return (alertParams[fwAlertConfig_ALERT_PARAM_TYPE][1] != DPCONFIG_NONE);
}


/** Creates a paramaters object for analog alarm.
  - example: creating an object with an analog alarm with 3 ranges
  \snippet fwAlertConfig_Examples.ctl Example: create Analog with utility function

@ingroup fwConfigsAlert

@par Constraints
	not for discrete alarms

@par Usage
	Public

@par PVSS managers
	VISION, CTRL

@param alertConfigObject  Reference to the object to create
@param alertTexts				Alert texts for each range eg. makeDynString( "Bad Text", "OK", "Bad Text")   
@param alertLimits					The limits of each range given here eg. makeDynFloat( 20, 60 );
@param alertClasses			Alert classes for each range eg. makeDynString( "_fwErrorAck.", "" , "_fwErrorAck.")
													One of the items of the dyn_string must always be empty to indicate the valid state.
													The valid ranges becomes the state with no alert class given (the second in this case).
													Don't forget to add the dot to the alert class names.
@param alertPanel				Panel to call from the alert screen
@param alertPanelParameters		Parameters to pass to panel given in Alert Panel
@param alertHelp				Help text or path to help file    
@param limitsIncluded		TRUE to include the limit (<=), FALSE else (<)
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
@see fwAlertConfig_objectCreateDiscrete(), 
     fwAlertConfig_objectCreateDigital(), fwAlertConfig_objectCreateSummary()
*/
fwAlertConfig_objectCreateAnalog(dyn_mixed &alertConfigObject, 
                  					dyn_string alertTexts,
                  					dyn_float alertLimits,
                  					dyn_string alertClasses,
                  					string alertPanel,
                  					dyn_string alertPanelParameters,
                  					string alertHelp,
                          dyn_bool limitsIncluded,
                  					dyn_string &exceptionInfo,
                  					bool modifyOnly = FALSE,
                  					bool fallBackToSet = FALSE,
                  					string addDpeInSummary = "",
                  					bool storeInParamHistory = TRUE)
{  
  dyn_dyn_mixed ddmAlertParams, ddmAlertLimits;
  dyn_string localExc;
  int iRanges, i, configType;
  
  iRanges = dynlen(alertTexts);
  if(!fwAlertConfig_objectConfigExists(alertConfigObject, configType, exceptionInfo))
    fwAlertConfig_objectInitialize(alertConfigObject, iRanges);
  ddmAlertParams = alertConfigObject[fwAlertConfig_ALERT_PARAM];
  ddmAlertLimits = alertConfigObject[fwAlertConfig_ALERT_LIMIT]; 
  
  ddmAlertParams[fwAlertConfig_ALERT_PARAM_TYPE][1] = DPCONFIG_ALERT_NONBINARYSIGNAL;
  ddmAlertParams[fwAlertConfig_ALERT_PARAM_FALLBACK_TO_SET][1] = fallBackToSet;
  ddmAlertParams[fwAlertConfig_ALERT_PARAM_STORE_IN_HISTORY][1] = storeInParamHistory;
  ddmAlertParams[fwAlertConfig_ALERT_PARAM_MODIFY_ONLY][1] = modifyOnly;
  ddmAlertParams[fwAlertConfig_ALERT_PARAM_RANGES][1] = iRanges;    
  ddmAlertParams[fwAlertConfig_ALERT_PARAM_PANEL][1] = alertPanel;    
  ddmAlertParams[fwAlertConfig_ALERT_PARAM_PANEL_PARAMETERS] = alertPanelParameters;    
  ddmAlertParams[fwAlertConfig_ALERT_PARAM_HELP][1] = alertHelp;    
  ddmAlertParams[fwAlertConfig_ALERT_PARAM_ADD_DPE_TO_SUMMARY][1] = addDpeInSummary;
  
  if(iRanges!=dynlen(alertLimits) ||
     iRanges!=dynlen(limitsIncluded) ||
     iRanges!=dynlen(alertClasses))
  {
			fwException_raise(exceptionInfo, "ERROR", "fwAlertConfig_objectCreateAnalog: The alert configuration is not consistent (Check length of dyn variables)", "");
			return;
  }     
  
  for(i=1 ; i<=iRanges ; i++)
  {
    ddmAlertLimits[i][fwAlertConfig_ALERT_LIMIT_TEXT] = alertTexts[i];
    ddmAlertLimits[i][fwAlertConfig_ALERT_LIMIT_VALUE] = alertLimits[i];
    ddmAlertLimits[i][fwAlertConfig_ALERT_LIMIT_VALUE_INCLUDED] = limitsIncluded[i];
    ddmAlertLimits[i][fwAlertConfig_ALERT_LIMIT_CLASS] = alertClasses[i];
  }
  
  alertConfigObject[fwAlertConfig_ALERT_PARAM] = ddmAlertParams;
  alertConfigObject[fwAlertConfig_ALERT_LIMIT] = ddmAlertLimits;
  exceptionInfo = getLastError();
}


/** Creates a paramaters object for digital alarm. 
The object is set to the alarm using fwAlertConfig_objectSet
  - example: creating an object with a digital alarm with FALSE ("cool") as good range:
  \snippet fwAlertConfig_Examples.ctl Example: create Digital, false=ok, with utility function

@ingroup fwConfigsAlert

@par Constraints
	not for discrete alarms

@par Usage
	Public

@par PVSS managers
	VISION, CTRL

@param alertConfigObject  Reference to the object to create
@param alertTexts				Alert texts for each range eg. makeDynString( "Bad Text", "OK", "Bad Text")   
@param alertClasses			Alert classes for each range eg. makeDynString( "" , "_fwErrorAck.")
													One of the items of the dyn_string must always be empty to indicate the valid state.
                    eg. makeDynString( "" , "_fwErrorAck.") for FALSE to be good state, 
                        makeDynString( "_fwErrorAck." , "") for TRUE to be good state.
													Don't forget to add the dot to the alert class names.
@param alertPanel				Panel to call from the alert screen
@param alertPanelParameters		Parameters to pass to panel given in Alert Panel
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
@see fwAlertConfig_objectCreateAnalog(), fwAlertConfig_objectCreateDiscrete(), 
      fwAlertConfig_objectCreateSummary()
*/
fwAlertConfig_objectCreateDigital(dyn_mixed &alertConfigObject, 
                  					dyn_string alertTexts,
                  					dyn_string alertClasses,
                  					string alertPanel,
                  					dyn_string alertPanelParameters,
                  					string alertHelp,
                  					dyn_string &exceptionInfo,
                  					bool modifyOnly = FALSE,
                  					bool fallBackToSet = FALSE,
                         string addDpeInSummary="",
                  					bool storeInParamHistory = TRUE)
{  
  dyn_dyn_mixed ddmAlertParams, ddmAlertLimits;
  dyn_string localExc;
  int iRanges, i, configType;
  
  iRanges = 2;
  if(!fwAlertConfig_objectConfigExists(alertConfigObject, configType, exceptionInfo))
    fwAlertConfig_objectInitialize(alertConfigObject, iRanges);
  ddmAlertParams = alertConfigObject[fwAlertConfig_ALERT_PARAM];
  ddmAlertLimits = alertConfigObject[fwAlertConfig_ALERT_LIMIT];  
  ddmAlertParams[fwAlertConfig_ALERT_PARAM_TYPE][1] = DPCONFIG_ALERT_BINARYSIGNAL;
  ddmAlertParams[fwAlertConfig_ALERT_PARAM_FALLBACK_TO_SET][1] = fallBackToSet;
  ddmAlertParams[fwAlertConfig_ALERT_PARAM_STORE_IN_HISTORY][1] = storeInParamHistory;
  ddmAlertParams[fwAlertConfig_ALERT_PARAM_MODIFY_ONLY][1] = modifyOnly;
  ddmAlertParams[fwAlertConfig_ALERT_PARAM_RANGES][1] = iRanges;    
  ddmAlertParams[fwAlertConfig_ALERT_PARAM_PANEL][1] = alertPanel;    
  ddmAlertParams[fwAlertConfig_ALERT_PARAM_PANEL_PARAMETERS] = alertPanelParameters;    
  ddmAlertParams[fwAlertConfig_ALERT_PARAM_HELP][1] = alertHelp;    
  ddmAlertParams[fwAlertConfig_ALERT_PARAM_ADD_DPE_TO_SUMMARY][1] = addDpeInSummary;
  
  if(iRanges!=dynlen(alertTexts) ||
     iRanges!=dynlen(alertClasses))
  {
			fwException_raise(exceptionInfo, "ERROR", "fwAlertConfig_objectCreateAnalog: The alert configuration is not consistent (Check length of dyn variables)", "");
			return;
  }  
  
  for(i=1 ; i<=iRanges ; i++)
  {
    ddmAlertLimits[i][fwAlertConfig_ALERT_LIMIT_TEXT] = alertTexts[i];
    ddmAlertLimits[i][fwAlertConfig_ALERT_LIMIT_CLASS] = alertClasses[i];
  }
  
  alertConfigObject[fwAlertConfig_ALERT_PARAM] = ddmAlertParams;
  alertConfigObject[fwAlertConfig_ALERT_LIMIT] = ddmAlertLimits;
  exceptionInfo = getLastError();
}


/** Creates a paramaters object for digital discrete or analog discrete alarm. 
The object is set to the alarm using fwAlertConfig_objectSet
  - example: creating an object with an analog discrete alarm with 3 ranges:
  \snippet fwAlertConfig_Examples.ctl Example: create Discrete with utility function

@ingroup fwConfigsAlert

@par Constraints
	not for discrete alarms

@par Usage
	Public

@par PVSS managers
	VISION, CTRL

@param alertConfigObject  Reference to the object to create
@param alertTexts				Alert texts for each range. the first one is always the good one eg. makeDynString( "Ok", "Bad Text", "Bad Text")   
@param alertMatch				Alert values that must match. Can be one value, a list of values or a range of values. 
                      The first value is always "*"  e.g. makedynString( "*","1,2","5-10")
@param alertClasses			Alert classes for each range eg. makeDynString( "" , "_fwErrorAck.")
													One of the items of the dyn_string must always be empty to indicate the valid state.
                    eg. makeDynString( "" , "_fwErrorAck.") for FALSE to be good state, 
                        makeDynString( "_fwErrorAck." , "") for TRUE to be good state.
													Don't forget to add the dot to the alert class names.
@param alertPanel				Panel to call from the alert screen
@param alertPanelParameters		Parameters to pass to panel given in Alert Panel
@param alertHelp				Help text or path to help file    
@param impulse					TRUE if alert is impulse alert else FALSE
@param discreteNegation		for each match values, TRUE if the match is negated (i.e. "!=").
@param stateBits					state bits of the discrete alert
@param stateMatch					state bits of each value match
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
@see fwAlertConfig_objectCreateAnalog(), 
     fwAlertConfig_objectCreateDigital(), fwAlertConfig_objectCreateSummary()
*/
fwAlertConfig_objectCreateDiscrete(dyn_mixed &alertConfigObject, 
                            					dyn_string alertTexts,
                            					dyn_string alertMatch,
                            					dyn_string alertClasses,
                            					string alertPanel,
                            					dyn_string alertPanelParameters,
                            					string alertHelp,
                                   bool impulse,
                                   dyn_bool discreteNegation,
                                   string stateBits,
                                   dyn_string stateMatch,
                            					dyn_string &exceptionInfo,
                            					bool modifyOnly = FALSE,
                            					bool fallBackToSet = FALSE,
                                   string addDpeInSummary="",
                            					bool storeInParamHistory = TRUE)
{  
  dyn_dyn_mixed ddmAlertParams, ddmAlertLimits;
  dyn_string localExc;
  int iRanges, i, configType;
  
  iRanges = dynlen(alertClasses);
  if(!fwAlertConfig_objectConfigExists(alertConfigObject, configType, exceptionInfo))
    fwAlertConfig_objectInitialize(alertConfigObject, iRanges);
  ddmAlertParams = alertConfigObject[fwAlertConfig_ALERT_PARAM];
  ddmAlertLimits = alertConfigObject[fwAlertConfig_ALERT_LIMIT];  
  
  ddmAlertParams[fwAlertConfig_ALERT_PARAM_TYPE][1] = DPCONFIG_ALERT_NONBINARYSIGNAL;
  ddmAlertParams[fwAlertConfig_ALERT_PARAM_DISCRETE][1] = TRUE;
  ddmAlertParams[fwAlertConfig_ALERT_PARAM_IMPULSE][1] = impulse;
  ddmAlertParams[fwAlertConfig_ALERT_PARAM_FALLBACK_TO_SET][1] = fallBackToSet;
  ddmAlertParams[fwAlertConfig_ALERT_PARAM_STORE_IN_HISTORY][1] = storeInParamHistory;
  ddmAlertParams[fwAlertConfig_ALERT_PARAM_MODIFY_ONLY][1] = modifyOnly;
  ddmAlertParams[fwAlertConfig_ALERT_PARAM_RANGES][1] = iRanges;  
  ddmAlertParams[fwAlertConfig_ALERT_PARAM_PANEL][1] = alertPanel;    
  ddmAlertParams[fwAlertConfig_ALERT_PARAM_PANEL_PARAMETERS] = alertPanelParameters;    
  ddmAlertParams[fwAlertConfig_ALERT_PARAM_HELP][1] = alertHelp;    
  ddmAlertParams[fwAlertConfig_ALERT_PARAM_ADD_DPE_TO_SUMMARY][1] = addDpeInSummary;
 
  for(i=1 ; i<=iRanges ; i++)
  {
    ddmAlertLimits[i][fwAlertConfig_ALERT_LIMIT_TEXT] = alertTexts[i];
    ddmAlertLimits[i][fwAlertConfig_ALERT_LIMIT_VALUE_MATCH] = alertMatch[i];
    ddmAlertLimits[i][fwAlertConfig_ALERT_LIMIT_NEGATION] = discreteNegation[i];
    ddmAlertLimits[i][fwAlertConfig_ALERT_LIMIT_CLASS] = alertClasses[i];
    ddmAlertLimits[i][fwAlertConfig_ALERT_LIMIT_STATE_BITS] = stateBits;
    ddmAlertLimits[i][fwAlertConfig_ALERT_LIMIT_LIMITS_STATE_BITS] = stateMatch[i];
  }  
  
  alertConfigObject[fwAlertConfig_ALERT_PARAM] = ddmAlertParams;
  alertConfigObject[fwAlertConfig_ALERT_LIMIT] = ddmAlertLimits;
  exceptionInfo = getLastError();
}


/** Creates a paramaters object for summary alarm.
   The object is set to the alarm using fwAlertConfig_objectSet().
  - example: creating an object with a summary alarm with a list of 3 dpes, filtering the single alarms if more than 2:
  \snippet fwAlertConfig_Examples.ctl Example: create Summary with utility function

@ingroup fwConfigsAlert

@par Constraints
	although existing in the parameter list, the alert class cannot be set
 not for discrete alarms

@par Usage
	Public

@par PVSS managers
	VISION, CTRL

@param alertConfigObject  Reference to the object to create
@param alertTexts				Alert texts for each range eg. makeDynString( "Bad Text", "OK", "Bad Text")   
@param threshold     How many single alarms must be triggered before they are filtered (i.e. not visible) by the summary alarm.
@param alertClasses		Alert classes for each range eg. makeDynString( "" , "_fwErrorAck.")
													One of the items of the dyn_string must always be empty to indicate the valid state.
                    eg. makeDynString( "" , "_fwErrorAck.") for FALSE to be good state, 
                        makeDynString( "_fwErrorAck." , "") for TRUE to be good state.
													Don't forget to add the dot to the alert class names.
@param summaryDpeList		List of dpes to include in summary alert
@param alertPanel				Panel to call from the alert screen
@param alertPanelParameters		Parameters to pass to panel given in Alert Panel
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
@see fwAlertConfig_objectCreateAnalog(), fwAlertConfig_objectCreateDiscrete(), 
     fwAlertConfig_objectCreateDigital()
*/
fwAlertConfig_objectCreateSummary(dyn_mixed &alertConfigObject, 
                  					dyn_string alertTexts,
                  					int threshold,
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
  dyn_dyn_mixed ddmAlertParams, ddmAlertLimits;
  dyn_string localExc;
  int iRanges, i, configType;
  
  iRanges = 2;
  if(!fwAlertConfig_objectConfigExists(alertConfigObject, configType, exceptionInfo))
    fwAlertConfig_objectInitialize(alertConfigObject, iRanges);
  ddmAlertParams = alertConfigObject[fwAlertConfig_ALERT_PARAM];
  ddmAlertLimits = alertConfigObject[fwAlertConfig_ALERT_LIMIT];  
  
  if(dynlen(summaryDpeList)==0)
	 {
				fwException_raise(exceptionInfo, "ERROR", "fwAlertConfig_objectCreateSummary: Alert summary needs either a dp pattern or a dp list", "");
				return getLastError();
		}
    
  ddmAlertParams[fwAlertConfig_ALERT_PARAM_TYPE][1] = DPCONFIG_SUM_ALERT;
  ddmAlertParams[fwAlertConfig_ALERT_PARAM_SUM_DPE_LIST] = summaryDpeList;
  ddmAlertParams[fwAlertConfig_ALERT_PARAM_SUM_THRESHOLD][1] = threshold;
  ddmAlertParams[fwAlertConfig_ALERT_PARAM_ADD_DPE_TO_SUMMARY][1] = addDpeInSummary;
  ddmAlertParams[fwAlertConfig_ALERT_PARAM_FALLBACK_TO_SET][1] = fallBackToSet;
  ddmAlertParams[fwAlertConfig_ALERT_PARAM_STORE_IN_HISTORY][1] = storeInParamHistory;
  ddmAlertParams[fwAlertConfig_ALERT_PARAM_MODIFY_ONLY][1] = modifyOnly;
  ddmAlertParams[fwAlertConfig_ALERT_PARAM_RANGES][1] = iRanges;  
  ddmAlertParams[fwAlertConfig_ALERT_PARAM_PANEL][1] = alertPanel;    
  ddmAlertParams[fwAlertConfig_ALERT_PARAM_PANEL_PARAMETERS] = alertPanelParameters;    
  ddmAlertParams[fwAlertConfig_ALERT_PARAM_HELP][1] = alertHelp;    
  ddmAlertParams[fwAlertConfig_ALERT_PARAM_ADD_DPE_TO_SUMMARY][1] = addDpeInSummary;
  
  for(i=1 ; i<=iRanges ; i++)
  {
    ddmAlertLimits[i][fwAlertConfig_ALERT_LIMIT_TEXT] = alertTexts[i];
    ddmAlertLimits[i][fwAlertConfig_ALERT_LIMIT_CLASS] = alertClasses[i];
  }

  alertConfigObject[fwAlertConfig_ALERT_PARAM] = ddmAlertParams;
  alertConfigObject[fwAlertConfig_ALERT_LIMIT] = ddmAlertLimits;
  exceptionInfo = getLastError();  
}


/** Returns the details of an analog alert configuration in a parameter object preivously filled.
 - example: get an analog alarm from a dpe
  \snippet fwAlertConfig_Examples.ctl Example: get an analog alarm from a dpe

@ingroup fwConfigsAlert

@par Constraints
  None
  
@par Usage
	Public

@par PVSS managers
	VISION, CTRL

@param alertConfigObject  object from where to extract the parameters
@param alertType	 Type of alert:
													DPCONFIG_ALERT_BINARYSIGNAL if digital alert handling
													DPCONFIG_ALERT_NONBINARYSIGNAL if analog alert handling
													DPCONFIG_SUM_ALERT if summary alert handling
													DPCONFIG_NONE if no alert handling
@param alertTexts				Alert texts are returned here
@param alertLimits			Alert limits are returned here
@param alertClasses			Alert classes are returned here
@param alertPanel				Panel to call from the alert screen
@param alertPanelParameters		Parameters to pass to the given alertPanel
@param alertHelp				Help text or path to help file    
@param limitsIncluded		if the limit is included (<=) or excluded (<)
@param isActive					if alert is active
@param exceptionInfo		Details of any exceptions are returned here   
@see fwAlertConfig_objectExtractDiscrete(), 
     fwAlertConfig_objectExtractDigital(), fwAlertConfig_objectExtractSummary()
*/
fwAlertConfig_objectExtractAnalog(dyn_mixed alertConfigObject, 
                            int &alertType,
                  					dyn_string &alertTexts,
                  					dyn_float &alertLimits,
                  					dyn_string &alertClasses,
                  					string &alertPanel,
                  					dyn_string &alertPanelParameters,
                  					string &alertHelp,
                            dyn_bool &limitsIncluded,
                            bool &isActive,
                  					dyn_string &exceptionInfo)
{  
  dyn_dyn_mixed ddmAlertParams, ddmAlertLimits;
  dyn_string localExc;
  int iRanges, i, configType;
  
  if(!fwAlertConfig_objectConfigExists(alertConfigObject, configType, exceptionInfo))
  {
    alertType = configType;
    alertTexts = makeDynString("");
    alertLimits = makeDynFloat(0);
    alertClasses = makeDynString("");
    alertPanel = "";
    alertPanelParameters = makeDynString("");
    alertHelp = "";
    limitsIncluded = makeDynBool("");
    isActive = FALSE;
    return;
  }
    
  ddmAlertParams = alertConfigObject[fwAlertConfig_ALERT_PARAM];
  ddmAlertLimits = alertConfigObject[fwAlertConfig_ALERT_LIMIT]; 
  
  iRanges = ddmAlertParams[fwAlertConfig_ALERT_PARAM_RANGES][1];
  alertPanel = ddmAlertParams[fwAlertConfig_ALERT_PARAM_PANEL];
  alertPanelParameters = ddmAlertParams[fwAlertConfig_ALERT_PARAM_PANEL_PARAMETERS];
  alertHelp = ddmAlertParams[fwAlertConfig_ALERT_PARAM_HELP];
  alertType =  ddmAlertParams[fwAlertConfig_ALERT_PARAM_TYPE][1];
  isActive =  ddmAlertParams[fwAlertConfig_ALERT_PARAM_ACTIVE][1];
  for(i=1 ; i<=iRanges ; i++)
  {
    alertTexts[i] = ddmAlertLimits[i][fwAlertConfig_ALERT_LIMIT_TEXT];
    alertLimits[i] = ddmAlertLimits[i][fwAlertConfig_ALERT_LIMIT_VALUE];
    limitsIncluded[i] = ddmAlertLimits[i][fwAlertConfig_ALERT_LIMIT_VALUE_INCLUDED];
    alertClasses[i] = ddmAlertLimits[i][fwAlertConfig_ALERT_LIMIT_CLASS];
  }
  exceptionInfo = getLastError();
}


/** Returns the type of alert configuration in a parameter object preivously filled.

@ingroup fwConfigsAlert

@par Constraints
  None
  
@par Usage
	Public

@par PVSS managers
	VISION, CTRL

@param alertConfigObject  object from where to extract the parameters
@param alertType	 Type of alert:
													DPCONFIG_ALERT_BINARYSIGNAL if digital alert handling
													DPCONFIG_ALERT_NONBINARYSIGNAL if analog alert handling
													DPCONFIG_SUM_ALERT if summary alert handling
													DPCONFIG_NONE if no alert handling
@param isActive					if alert is active
@param exceptionInfo		Details of any exceptions are returned here   
@see fwAlertConfig_objectExtractDiscrete(), 
     fwAlertConfig_objectExtractDigital(), fwAlertConfig_objectExtractSummary()
*/
fwAlertConfig_objectExtractType(							
						dyn_mixed alertConfigObject, 
                          int &alertType,
                          bool &isActive,
						  dyn_string &exceptionInfo)
{  
  dyn_dyn_mixed ddmAlertParams;
  int configType;
  
  if(!fwAlertConfig_objectConfigExists(alertConfigObject, configType, exceptionInfo))
  {
    alertType = configType;
    isActive = FALSE;
    return;
  }
    
  ddmAlertParams = alertConfigObject[fwAlertConfig_ALERT_PARAM];
  
  alertType =  ddmAlertParams[fwAlertConfig_ALERT_PARAM_TYPE][1];
  isActive =  ddmAlertParams[fwAlertConfig_ALERT_PARAM_ACTIVE][1];

  exceptionInfo = getLastError();
}


/** Returns the details of a discrete alert configuration in a parameter object preivously filled.

@ingroup fwConfigsAlert

@par Constraints
  None
  
@par Usage
	Public

@par PVSS managers
	VISION, CTRL

@param alertConfigObject  object from where to extract the parameters
@param alertType	 Type of alert:
													DPCONFIG_ALERT_BINARYSIGNAL if digital alert handling
													DPCONFIG_ALERT_NONBINARYSIGNAL if analog alert handling
													DPCONFIG_NONE if no alert handling
@param alertTexts				Alert texts are returned here
@param alertMatches			Alert limits are returned here
@param alertClasses			Alert classes are returned here
@param alertPanel				Panel to call from the alert screen
@param alertPanelParameters		Parameters to pass to the given alertPanel
@param alertHelp				Help text or path to help file    
@param isDiscrete		TRUE if the alert is discrete
@param impulse					TRUE if alert is impulse alert else FALSE
@param discreteNegation		for each match values, TRUE if the match is negated (i.e. "!=").
@param stateBits					state bits of the discrete alert
@param stateMatch					state bits of each value match
@param isActive					if alert is active
@param exceptionInfo		Details of any exceptions are returned here   
@see fwAlertConfig_objectExtractAnalog(), 
     fwAlertConfig_objectExtractDigital(), fwAlertConfig_objectExtractSummary()
*/
fwAlertConfig_objectExtractDiscrete(dyn_mixed alertConfigObject, 
                          int &alertType,
                  					dyn_string &alertTexts,
                  					dyn_string &alertMatches,
                  					dyn_string &alertClasses,
                  					string &alertPanel,
                  					dyn_string &alertPanelParameters,
                  					string &alertHelp,
                         bool &isDiscrete,
                         bool &impulse,
                         dyn_bool &discreteNegation,
                         string &stateBits,
                         dyn_string &stateMatch,
                          bool &isActive,
                  					dyn_string &exceptionInfo)
{  
  dyn_dyn_mixed ddmAlertParams, ddmAlertLimits;
  dyn_string localExc;
  int iRanges, i, configType;
  
  if(!fwAlertConfig_objectConfigExists(alertConfigObject, configType, exceptionInfo))
  {
    alertType = configType;
    alertTexts = makeDynString();
    alertMatches = makeDynString();
    alertClasses = makeDynString();
    alertPanel = "";
    alertPanelParameters = makeDynString();
    alertHelp = "";
    impulse = FALSE;
    discreteNegation = makeDynBool();
    stateBits = "";
    stateMatch = makeDynString();
    isDiscrete = FALSE;
    isActive = FALSE;
    return;
  }
    
  ddmAlertParams = alertConfigObject[fwAlertConfig_ALERT_PARAM];
  ddmAlertLimits = alertConfigObject[fwAlertConfig_ALERT_LIMIT]; 
  
  iRanges = ddmAlertParams[fwAlertConfig_ALERT_PARAM_RANGES][1];
  alertPanel = ddmAlertParams[fwAlertConfig_ALERT_PARAM_PANEL];
  alertPanelParameters = ddmAlertParams[fwAlertConfig_ALERT_PARAM_PANEL_PARAMETERS];
  alertHelp = ddmAlertParams[fwAlertConfig_ALERT_PARAM_HELP];
  alertType =  ddmAlertParams[fwAlertConfig_ALERT_PARAM_TYPE][1];
  isActive =  ddmAlertParams[fwAlertConfig_ALERT_PARAM_ACTIVE][1];
  isDiscrete = ddmAlertParams[fwAlertConfig_ALERT_PARAM_DISCRETE][1];
  impulse = ddmAlertParams[fwAlertConfig_ALERT_PARAM_IMPULSE][1];
  stateBits = ddmAlertLimits[1][fwAlertConfig_ALERT_LIMIT_STATE_BITS];
  
  for(i=1 ; i<=iRanges ; i++)
  {
    alertTexts[i] = ddmAlertLimits[i][fwAlertConfig_ALERT_LIMIT_TEXT];
    alertMatches[i] = ddmAlertLimits[i][fwAlertConfig_ALERT_LIMIT_VALUE_MATCH];
    discreteNegation[i] = ddmAlertLimits[i][fwAlertConfig_ALERT_LIMIT_NEGATION];
    alertClasses[i] = ddmAlertLimits[i][fwAlertConfig_ALERT_LIMIT_CLASS];
    stateMatch[i] = ddmAlertLimits[i][fwAlertConfig_ALERT_LIMIT_LIMITS_STATE_BITS];
  }
  exceptionInfo = getLastError();
}


/** Returns the details of a digital alert configuration in a parameter object preivously filled.

@ingroup fwConfigsAlert

@par Constraints
  None
  
@par Usage
	Public

@par PVSS managers
	VISION, CTRL

@param alertConfigObject  object from where to extract the parameters
@param alertType	 Type of alert:
													DPCONFIG_ALERT_BINARYSIGNAL if digital alert handling
													DPCONFIG_ALERT_NONBINARYSIGNAL if analog alert handling
													DPCONFIG_SUM_ALERT if summary alert handling
													DPCONFIG_NONE if no alert handling
@param alertTexts				Alert texts are returned here
@param alertClasses			Alert classes are returned here
@param alertPanel				Panel to call from the alert screen
@param alertPanelParameters		Parameters to pass to the given alertPanel
@param alertHelp				Help text or path to help file    
@param isActive					if alert is active
@param exceptionInfo		Details of any exceptions are returned here   
@see fwAlertConfig_objectExtractAnalog(), fwAlertConfig_objectExtractDiscrete(), 
      fwAlertConfig_objectExtractSummary()
*/
fwAlertConfig_objectExtractDigital(dyn_mixed alertConfigObject, 
                          int &alertType,
                  					dyn_string &alertTexts,
                  					dyn_string &alertClasses,
                  					string &alertPanel,
                  					dyn_string &alertPanelParameters,
                  					string &alertHelp,
                          bool &isActive,
                  					dyn_string &exceptionInfo)
{  
  dyn_dyn_mixed ddmAlertParams, ddmAlertLimits;
  dyn_string localExc;
  int iRanges, i, configType;

  if(!fwAlertConfig_objectConfigExists(alertConfigObject, configType, exceptionInfo))
  {
    alertType = configType;
    alertTexts = makeDynString("");
    alertClasses = makeDynString("");
    alertPanel = "";
    alertPanelParameters = makeDynString("");
    alertHelp = "";
    isActive = FALSE;
    return;
  }

  ddmAlertParams = alertConfigObject[fwAlertConfig_ALERT_PARAM];
  ddmAlertLimits = alertConfigObject[fwAlertConfig_ALERT_LIMIT]; 
  iRanges = ddmAlertParams[fwAlertConfig_ALERT_PARAM_RANGES][1];
  alertPanel = ddmAlertParams[fwAlertConfig_ALERT_PARAM_PANEL];
  alertPanelParameters = ddmAlertParams[fwAlertConfig_ALERT_PARAM_PANEL_PARAMETERS];
  alertHelp = ddmAlertParams[fwAlertConfig_ALERT_PARAM_HELP];
  alertType =  ddmAlertParams[fwAlertConfig_ALERT_PARAM_TYPE][1];
  isActive =  ddmAlertParams[fwAlertConfig_ALERT_PARAM_ACTIVE][1];
  for(i=1 ; i<=iRanges ; i++)
  {
    alertTexts[i] = ddmAlertLimits[i][fwAlertConfig_ALERT_LIMIT_TEXT];
    alertClasses[i] = ddmAlertLimits[i][fwAlertConfig_ALERT_LIMIT_CLASS];
  }
  exceptionInfo = getLastError();
}



/** Returns the details of a summary alert configuration in a parameter object preivously filled.

@ingroup fwConfigsAlert

@par Constraints
  None
  
@par Usage
	Public

@par PVSS managers
	VISION, CTRL

@param alertConfigObject  object from where to extract the parameters
@param alertType	 Type of alert:
													DPCONFIG_ALERT_BINARYSIGNAL if digital alert handling
													DPCONFIG_ALERT_NONBINARYSIGNAL if analog alert handling
													DPCONFIG_SUM_ALERT if summary alert handling
													DPCONFIG_NONE if no alert handling
@param alertTexts				Alert texts are returned here
@param threshold     How many single alarms must be triggered before they are filtered (i.e. not visible) by the summary alarm.
@param summaryDpeList		List of dpes to include in summary alert
@param alertClass			Alert classes are returned here
@param alertPanel				Panel to call from the alert screen
@param alertPanelParameters		Parameters to pass to the given alertPanel
@param alertHelp				Help text or path to help file    
@param isActive					if alert is active
@param exceptionInfo		Details of any exceptions are returned here   
@see fwAlertConfig_objectExtractAnalog(), fwAlertConfig_objectExtractDiscrete(), 
     fwAlertConfig_objectExtractDigital()
*/
fwAlertConfig_objectExtractSummary( dyn_mixed alertConfigObject, 
                          							int &alertType,
                          							dyn_string &alertTexts,
                          							dyn_string &summaryDpeList,
                                    int &threshold,
                          							string &alertClass,
                          							string &alertPanel,
                          							dyn_string &alertPanelParameters,
                          							string &alertHelp,
                          							bool &isActive,
                          							dyn_string &exceptionInfo)
{  
  dyn_dyn_mixed ddmAlertParams, ddmAlertLimits;
  dyn_string localExc;
  int iRanges, i, configType;

  if(!fwAlertConfig_objectConfigExists(alertConfigObject, configType, exceptionInfo))
  {
    alertType = configType;
    alertTexts = makeDynString("");
    summaryDpeList = makeDynString("");
    threshold = 0;
    alertClass = "";
    alertPanel = "";
    alertPanelParameters = makeDynString("");
    alertHelp = "";
    isActive = FALSE;
    return;
  }
  iRanges = 2;
  ddmAlertParams = alertConfigObject[fwAlertConfig_ALERT_PARAM];
  ddmAlertLimits = alertConfigObject[fwAlertConfig_ALERT_LIMIT]; 
  alertType =  ddmAlertParams[fwAlertConfig_ALERT_PARAM_TYPE][1];
  summaryDpeList =  ddmAlertParams[fwAlertConfig_ALERT_PARAM_SUM_DPE_LIST];
  alertClass = ddmAlertParams[1][fwAlertConfig_ALERT_LIMIT_CLASS];
  alertPanel = ddmAlertParams[fwAlertConfig_ALERT_PARAM_PANEL][1];
  alertPanelParameters = ddmAlertParams[fwAlertConfig_ALERT_PARAM_PANEL_PARAMETERS];
  alertHelp = ddmAlertParams[fwAlertConfig_ALERT_PARAM_HELP][1];
  isActive =  ddmAlertParams[fwAlertConfig_ALERT_PARAM_ACTIVE][1];
  for(i=1 ; i<=iRanges ; i++)
  {
    alertTexts[i] = ddmAlertLimits[i][fwAlertConfig_ALERT_LIMIT_TEXT];
  }
  exceptionInfo = getLastError();    
}

//@} // end of Utility functions

/**
 * @name Set/Get functions
   Used to set/get the alarm settings to/from the dpe. The settings are stored into the settings object.
 * @{
*/

/** Set the alert with the alert parameter object.
  The alert parameter object must be previously filled. 
  The object is a dyn_mixed variable. It is made of two dyn_dyn_mixed sub-variables:
	- limits parameters (index fwAlertConfig_ALERT_LIMIT), contains the parameters per range (classes, values...).
	- general parameters (index fwAlertConfig_ALERT_PARAM), contains the other parameters of the alarm (type, panel...).

  How to fill the parameters object: use one of the functions "fwAlertConfig_objectCreate..."
  or fill it manually as in the examples given here:

 
 - example 1: create an analog alert object (3 ranges) using the utility functions and set it to the dpe
  \snippet fwAlertConfig_Examples.ctl Example: create Analog with utility function
 
 - example 2: create a discrete alert object (3 ranges) using the utility functions and set it to the dpe
  \snippet fwAlertConfig_Examples.ctl Example: create Discrete with utility function

 - example 3: create and set an analog alarm with 3 ranges and the basic parameters
  \snippet fwAlertConfig_Examples.ctl Example: create Analog without utility function
 
 - example 4: create and set a digital alarm with false = ok, true = alarm
  \snippet fwAlertConfig_Examples.ctl Example: create Digital, false=ok, without utility function

 - example 5: create and set a digital alarm with false = alarm, true = ok
  \snippet fwAlertConfig_Examples.ctl Example: create Digital, true=ok, without utility function
 
 - example 6: create a discrete alert object with 3 ranges and the basic parameters
  \snippet fwAlertConfig_Examples.ctl Example: create Discrete without utility function
   
 - example 7: create a summary alert object using utility function and set it to the dpe
  \snippet fwAlertConfig_Examples.ctl Example: create Summary with utility function
 
 - example 8: create a summary alert object and set it to the dpe
  \snippet fwAlertConfig_Examples.ctl Example: create Summary without utility function
 
@ingroup fwConfigsAlert
    
@par Constraints
  The alert parameter object must be previously filled. 
  
@par Usage
	Public

@par PVSS managers
	VISION, CTRL

@param dpe the datapoint element to configure
@param alertConfigObject  object from where to extract the parameters
@param exceptionInfo		Details of any exceptions are returned here   
@see fwAlertConfig_objectGet(), fwAlertConfig_objectSetMany(), fwAlertConfig_objectGetMany()
*/
fwAlertConfig_objectSet(string dpe, dyn_mixed alertConfigObject, dyn_string &exceptionInfo)
{  
  dyn_dyn_mixed alertConfigObjects;
  dyn_string dsDpes;
  
  dsDpes[1] = dpe;
  alertConfigObjects[1] = alertConfigObject;
  fwAlertConfig_objectSetMany(dsDpes, alertConfigObjects, exceptionInfo);
}


/** Set the alert with the alert parameter object alertConfigObject.
  The alert parameter object must be previously filled. 
  How to fill it: fill each elemt of the array alertConfigObject[i] using 
  one of the functions "fwAlertConfig_objectCreate..."
  or fill it manually as in the examples given for fwAlertConfig_objectSet()
  
  One object per dpe must be filled.
  Optionally, one only object (index 1) can be filled and several dpes can be passed. In such case,
  the function sets the same object to all the dpes. In this case, the dpes must all be of the same type.
  
  This function is more efficient that applying the function fwAlertConfig_objectSet() in a loop.
  
 - example 1: create 3-ranges alarms for 2 datapoint elements
  \snippet fwAlertConfig_Examples.ctl Example: set 2 alarms without utility function

 - example 2: create a 3-ranges alarm and set it to 4 datapoint elements. Note: the dpes must all be of the same type.
  \snippet fwAlertConfig_Examples.ctl Example: set 4 alarms without utility function

 - example 3: create 4 alarms and set them to 4 datapoint elements of type bit32.
  \snippet fwAlertConfig_Examples.ctl Example: set 4 alarms bit32 without utility function

@par Constraints
  The alert parameter object must be previously filled. 
  
@par Usage
	Public

@par PVSS managers
	VISION, CTRL

@param dpes list of datapoint elements to configure. It is passed as reference only for performance reasons. It is not modified.
@param alertConfigObjects  list of objects from where to extract the parameters. The amount of  alarm configuration objects must match the amount of dpes.
          Alternatively, if the number of alarm configuration objects is only one, that configuration is then applied to all the dpes in the list.
		   Passed as reference only for performance reasons. Not modified.
@param exceptionInfo		Details of any exceptions are returned here   
@see fwAlertConfig_objectSet(), fwAlertConfig_objectGet(), fwAlertConfig_objectGetMany()
*/
fwAlertConfig_objectSetMany(dyn_string &dpes, dyn_dyn_mixed &alertConfigObjects, dyn_string &exceptionInfo)
{
	bool relativeSummaryPath;
	int i, j, k, length, ranges, configOptions, numberOfSettings, minimumPriority = 0;
	dyn_string localException, attributes, tempAttributes, configsToDeactivate, dpesWithAlerts, dpesWithAnalogAlerts;
	dyn_mixed values, tempValues;
	dyn_int alertHandlingTypes, currentConfigTypes, summaryConfigTypes; 
   
	dyn_int currentNumberOfRanges, numberOfRanges;    
	dyn_bool alertActive, alertActiveStates, tempAlertActiveStates; 
	dyn_errClass errors;

  dyn_int diHysteresisType;
	dyn_dyn_float ddfHysteresisLimits;
  bool bDiscreteAlert, bImpulseAlert, bStoreInParamHistory, bFallBackToSet, bModifyOnly;
  dyn_bool dbIncludeLimits, dbDiscreteNegationAlert; 
  dyn_string dsStateBits, dsStateMatch, dsSummaryDpeList, dsLimitMatch; 
  int iAlertConfigType;    
  dyn_string dsAlertTexts, dsAlertTextsWent, dsAlertClasses, dsAlertPanelParameters, dsSummaryDpes;
  dyn_float dfAlertLimits, dfHysteresisLimits;
  string sAlertPanel, sAlertHelp, sAddDpeInSummary;
  dyn_dyn_mixed ddmAlertParam, ddmAlertLimit;  
  dyn_dyn_string ddsAlertClasses;
  dyn_bool dbIncludeLimitsDummy;
  dyn_mixed alertParams, alertLimits;
  bool bRangesMismatch;
  int iLimitsLen;
  float fThreshold;
  dyn_string dsNonSumAlerts;
  dyn_string currentNumberOfRangesOfNonSumAlerts;
  dyn_string dpesToActivate;
//     DebugN("alertConfigObjects: "+alertConfigObjects);

	length = dynlen(dpes);
//    DebugN("dynlen(alertConfigObjects): "+dynlen(alertConfigObjects));
  if(length>1 && dynlen(alertConfigObjects)==1)//one config for many dpes. clone the same config per each dpe.
    for(i=1 ; i<length ; i++)
      dynAppend(alertConfigObjects,alertConfigObjects[1]);
//    DebugN("dynlen(alertConfigObjects): "+dynlen(alertConfigObjects));
//    DebugN("dynlen(dpes): "+dynlen(dpes));

 if(dynlen(alertConfigObjects)!=length)
  {
  		fwException_raise(exceptionInfo, "ERROR",
  											"fwAlertConfig_objectSetMany: The number of alarms parameters ("+dynlen(alertConfigObjects)+") does not match the number of dpes ("+length+").", "");
     return;
  }
 
 	_fwConfigs_getConfigTypeAttribute(dpes, fwConfigs_PVSS_ALERT_HDL, currentConfigTypes, exceptionInfo);
 if(dynlen(exceptionInfo))
   return;
	for(i=1; i<=length; i++)
	{
		if(currentConfigTypes[i] != DPCONFIG_NONE)
			dynAppend(dpesWithAlerts, dpes[i]);
		if(currentConfigTypes[i] == DPCONFIG_ALERT_NONBINARYSIGNAL)
			dynAppend(dpesWithAnalogAlerts, dpes[i]);
   if(currentConfigTypes[i]!=DPCONFIG_ALERT_BINARYSIGNAL && currentConfigTypes[i]!=DPCONFIG_SUM_ALERT && currentConfigTypes[i]!=DPCONFIG_NONE)
			  dynAppend(dsNonSumAlerts, dpes[i]);//this list contains only alerts having the .._num_ranges defined
	}

	_fwConfigs_getConfigTypeAttribute(dpesWithAlerts, fwConfigs_PVSS_ALERT_HDL, alertActiveStates, exceptionInfo, ".._active");

// 	if(bModifyOnly)
// 		_fwConfigs_getConfigTypeAttribute(dpesWithAlerts, fwConfigs_PVSS_ALERT_HDL, currentNumberOfRanges, exceptionInfo, ".._num_ranges");
  //get number of ranges only for non-summary alarms
		_fwConfigs_getConfigTypeAttribute(dsNonSumAlerts, fwConfigs_PVSS_ALERT_HDL, currentNumberOfRangesOfNonSumAlerts, exceptionInfo, ".._num_ranges");
  //merge the range values of the dpes: for the summary alarms and for the elements without alarms, set number of ranges = 0
  j=1;  
  for(i=1 ; i<=length ; i++)
  {
    if(currentConfigTypes[i]!=DPCONFIG_SUM_ALERT && currentConfigTypes[i]!=DPCONFIG_NONE && dynlen(currentNumberOfRangesOfNonSumAlerts)>=j)
    {
			  dynAppend(currentNumberOfRanges, currentNumberOfRangesOfNonSumAlerts[j]);
       j++;
    }
    else
			  dynAppend(currentNumberOfRanges, 0);    
  }


//  Debug("dpesWithAlerts:",dpesWithAlerts);
//  Debug("currentNumberOfRanges:",currentNumberOfRanges);
//  Debug("bModifyOnly:",bModifyOnly);

  	j = 1;
  	k = 1;
  	for(i=1; i<=length; i++)
  	{
      alertParams[i] = alertConfigObjects[i][fwAlertConfig_ALERT_PARAM];
      alertLimits[i] = alertConfigObjects[i][fwAlertConfig_ALERT_LIMIT];
//     DebugN("alertConfigObjects[i][fwAlertConfig_ALERT_LIMIT]: ",alertConfigObjects[i][fwAlertConfig_ALERT_LIMIT]);
//     DebugN("alertConfigObjects[i][fwAlertConfig_ALERT_PARAM]: ",alertConfigObjects[i][fwAlertConfig_ALERT_PARAM]);
    
  		if(currentConfigTypes[i] != DPCONFIG_NONE)
  		{
  			alertActive[i] = alertActiveStates[j];
  			j++; 
  			if(alertActive[i])
  				dynAppend(configsToDeactivate, dpes[i]);
  		}
  		else
  			alertActive[i] = FALSE;

    ddmAlertParam = alertParams[i];
// DebugN("dpes: ",dpes[i]);
//      DebugN("ddmAlertParam: ",ddmAlertParam);
    bModifyOnly = ddmAlertParam[fwAlertConfig_ALERT_PARAM_MODIFY_ONLY][1];
  		if(bModifyOnly && (currentConfigTypes[i] == DPCONFIG_ALERT_NONBINARYSIGNAL))
  		{
  			numberOfRanges[i] = currentNumberOfRanges[k];
  			k++; 
  		}
  		else
  			numberOfRanges[i] = 0;
  	}
// DebugN("configsToDeactivate:",configsToDeactivate);
	fwAlertConfig_deactivateMultiple(configsToDeactivate, exceptionInfo, TRUE, FALSE, FALSE);
	dynClear(attributes);
	dynClear(values);

  for(i=1; i<=length; i++)
  {
      dynClear(dsStateMatch);
      dynClear(dsStateBits);
      dynClear(dbDiscreteNegationAlert);
      dynClear(dsAlertTexts);
      dynClear(dsAlertTextsWent);
      dynClear(dsAlertClasses);
      dynClear(dfAlertLimits);
      dynClear(dsLimitMatch);
      dynClear(dbIncludeLimits);    
    
    ddmAlertParam = alertParams[i];
    ddmAlertLimit = alertLimits[i];
    ranges = ddmAlertParam[fwAlertConfig_ALERT_PARAM_RANGES][1];
    
//     DebugN("==================");
//     DebugN("dpe: "+dpes[i]);
//     DebugN("ddmAlertParam: "+ddmAlertParam);
//     DebugN("ddmAlertLimit: "+ddmAlertLimit);
//     DebugN("ranges: "+ranges);
//     DebugN("dyneln ddmAlertLimit[1]: "+dynlen(ddmAlertLimit[1]));
//     DebugN("dyneln ddmAlertLimit[2]: "+dynlen(ddmAlertLimit[2]));
//     DebugN("dyneln ddmAlertLimit[3]: "+dynlen(ddmAlertLimit[3]));

    bRangesMismatch = FALSE;
    iLimitsLen = dynlen(ddmAlertLimit[1]);
    for(j=1 ; j<=ranges ; j++)//all the limits parameters must have the same lenght, equal to ranges
    {
      bRangesMismatch = bRangesMismatch || (iLimitsLen!=dynlen(ddmAlertLimit[j]));
    }
    if(dynlen(ddmAlertLimit)!=ranges || bRangesMismatch)
    {
    		fwException_raise(exceptionInfo, "ERROR",
    											"fwAlertConfig_objectSetMany: The amount of limits parameters does not match the declared ranges for dpe: "+dpes[i], "");
      continue;
    }
    iAlertConfigType = ddmAlertParam[fwAlertConfig_ALERT_PARAM_TYPE][1];
    sAlertPanel = ddmAlertParam[fwAlertConfig_ALERT_PARAM_PANEL][1];
    dsAlertPanelParameters = ddmAlertParam[fwAlertConfig_ALERT_PARAM_PANEL_PARAMETERS];
    sAlertHelp = ddmAlertParam[fwAlertConfig_ALERT_PARAM_HELP];
    bImpulseAlert = ddmAlertParam[fwAlertConfig_ALERT_PARAM_IMPULSE][1];
    bDiscreteAlert = ddmAlertParam[fwAlertConfig_ALERT_PARAM_DISCRETE][1];
    dsSummaryDpeList =  ddmAlertParam[fwAlertConfig_ALERT_PARAM_SUM_DPE_LIST];
    sAddDpeInSummary =  ddmAlertParam[fwAlertConfig_ALERT_PARAM_ADD_DPE_TO_SUMMARY];
    fThreshold = ddmAlertParam[fwAlertConfig_ALERT_PARAM_SUM_THRESHOLD][1];
    bStoreInParamHistory = ddmAlertParam[fwAlertConfig_ALERT_PARAM_STORE_IN_HISTORY][1];
    bFallBackToSet = ddmAlertParam[fwAlertConfig_ALERT_PARAM_FALLBACK_TO_SET][1];
    bModifyOnly = ddmAlertParam[fwAlertConfig_ALERT_PARAM_MODIFY_ONLY][1];
//     if(ddmAlertParam[fwAlertConfig_ALERT_PARAM_ACTIVE][1])
//       dynAppend(dpesToActivate,dpes[i]);
    for(j=1 ; j<=ranges ; j++)
    {     
      dsStateMatch[j] = ddmAlertLimit[j][fwAlertConfig_ALERT_LIMIT_LIMITS_STATE_BITS];
      dsStateBits[j] = ddmAlertLimit[j][fwAlertConfig_ALERT_LIMIT_STATE_BITS];
      dbDiscreteNegationAlert[j] = ddmAlertLimit[j][fwAlertConfig_ALERT_LIMIT_NEGATION];
      dsAlertTexts[j] = ddmAlertLimit[j][fwAlertConfig_ALERT_LIMIT_TEXT];
      dsAlertTextsWent[j] = ddmAlertLimit[j][fwAlertConfig_ALERT_LIMIT_TEXT_WENT];
      dsAlertClasses[j] = ddmAlertLimit[j][fwAlertConfig_ALERT_LIMIT_CLASS];
      dfAlertLimits[j] = ddmAlertLimit[j][fwAlertConfig_ALERT_LIMIT_VALUE];
      dsLimitMatch[j] = ddmAlertLimit[j][fwAlertConfig_ALERT_LIMIT_VALUE_MATCH];
      dbIncludeLimits[j] = ddmAlertLimit[j][fwAlertConfig_ALERT_LIMIT_VALUE_INCLUDED];
    }

    ddsAlertClasses[1] = dsAlertClasses;
  	_fwAlertConfig_checkAlertClasses(ddsAlertClasses, exceptionInfo);
    dsAlertClasses = ddsAlertClasses[1];
		_fwConfigs_getConfigOptionsForDpe(dpes[i], fwConfigs_PVSS_ALERT_HDL, configOptions, localException);
//     DebugN("this dpe is for option "+configOptions);
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
				if(iAlertConfigType != DPCONFIG_ALERT_NONBINARYSIGNAL)
				{
					fwException_raise(exceptionInfo, "ERROR",
											"fwAlertConfig_objectSetMany: Only analog alerts are supported by the dpe "+dpes[i], "");
					break;
				}
				
				if(dynlen(dsAlertTexts) == 0 ||
					(dynlen(dfAlertLimits) == 0 && dynlen(dsLimitMatch) == 0) ||
					dynlen(dsAlertClasses) == 0)
				{
			  	fwException_raise(exceptionInfo, "ERROR",
			  								"fwAlertConfig_objectSetMany: You must provide alert texts, classes and limits for an analog alert", "");
					break;
				}
    
      if(bDiscreteAlert)
      {
         //prepare the alert type as MATCH for discrete alert
         for(j=1; j<=ranges; j++)
        	{
        		alertHandlingTypes[j] = DPDETAIL_RANGETYPE_MATCH;
        	}   
//          DebugN("setting analog discrete");
        _fwAlertConfig_prepareAnalogDiscrete(dpes[i], currentConfigTypes[i], numberOfRanges[i],
  										alertHandlingTypes, dsLimitMatch, dsAlertTexts, dsAlertClasses,
  										minimumPriority, sAlertPanel, dsAlertPanelParameters, sAlertHelp, 
                 bImpulseAlert, dbDiscreteNegationAlert, dsStateBits, dsStateMatch,
                 tempAttributes, tempValues, localException, bModifyOnly, bFallBackToSet, dsAlertTextsWent);
      }
      else
      {
//          DebugN("setting analog");
         dynRemove(dfAlertLimits,1);//remove the first element (it is always 0): #limits = #classes-1
    			 	_fwAlertConfig_generateExtraAnalogConfig(ranges, dfAlertLimits, alertHandlingTypes, 
                   dfHysteresisLimits, diHysteresisType, dbIncludeLimitsDummy, exceptionInfo);
//          DebugN("dfHysteresisLimits: "+dfHysteresisLimits);
    				_fwAlertConfig_prepareAnalog(dpes[i], currentConfigTypes[i], numberOfRanges[i],
    										alertHandlingTypes, dfAlertLimits, dsAlertTexts, dsAlertClasses,
    										dbIncludeLimits, minimumPriority, sAlertPanel, dsAlertPanelParameters, sAlertHelp,
    										diHysteresisType, dfHysteresisLimits, tempAttributes, tempValues,
    										localException, bModifyOnly, bFallBackToSet, dsAlertTextsWent);
//          DebugN("tempAttributes: "+tempAttributes);
//          DebugN("tempValues: "+tempValues);
      }
				break;
			case fwConfigs_BINARY_OPTIONS:
 				if(iAlertConfigType != DPCONFIG_ALERT_BINARYSIGNAL && !bDiscreteAlert)
				{
			  	fwException_raise(exceptionInfo, "ERROR",
			  								"fwAlertConfig_objectSetMany: Only binary alerts are supported by the dpe "+dpes[i], "");
					break;
				}
        
// DebugN("dsAlertTexts: "+dsAlertTexts);
// DebugN("dsAlertClasses: "+dsAlertClasses);
				if(dynlen(dsAlertTexts) != 2 ||
					dynlen(dsAlertClasses) != 2)
				{
			  	fwException_raise(exceptionInfo, "ERROR",
			  								"fwAlertConfig_objectSetMany: You must provide 2 alert classes (including the good range) and 2 alert texts for a binary alert", "");
					break;
				}

      if(bDiscreteAlert)
      {
        _fwAlertConfig_prepareDigitalDiscrete(dpes[i], currentConfigTypes[i],
    										dsAlertTexts, dsAlertClasses,
    										minimumPriority, sAlertPanel, dsAlertPanelParameters, sAlertHelp, 
                  bImpulseAlert, dsStateBits,
                  tempAttributes, tempValues, localException, bModifyOnly, bFallBackToSet);
      }
      else		
      {		
        _fwAlertConfig_prepareDigital(dpes[i], currentConfigTypes[i], dsAlertTexts, dsAlertClasses, 
                                      minimumPriority, sAlertPanel, dsAlertPanelParameters, sAlertHelp, 
                                      tempAttributes, tempValues, localException, bModifyOnly, bFallBackToSet);
      }
				break;
			case fwConfigs_GENERAL_OPTIONS:
				if(iAlertConfigType != DPCONFIG_SUM_ALERT)
				{
			  	fwException_raise(exceptionInfo, "ERROR",
			  								"fwAlertConfig_objectSetMany: Only summary alerts are supported by the dpe "+dpes[i], "");
					break;
				}
				
				if(dynlen(dsAlertTexts) != 2)
				{
			  	fwException_raise(exceptionInfo, "ERROR",
			  								"fwAlertConfig_objectSetMany: You must provide 2 alert texts for a summary alert", "");
					break;
				}
//       DebugN("dsSummaryDpeList: "+dsSummaryDpeList);
				if(dynlen(dsSummaryDpeList) > 1)
				{
					if((strpos(dsSummaryDpeList[1], "*") >= 0) || (strpos(dsSummaryDpeList[1], "?") >= 0))
					{
			  			fwException_raise(exceptionInfo, "ERROR",
			  					"fwAlertConfig_objectSetMany: You can not specify at DP list and DP pattern in the same summary alert", "");
						break;
					}
				}
      _fwAlertConfig_prepareSummary(dpes[i], currentConfigTypes[i], fThreshold, dsAlertTexts, dsSummaryDpeList, 
            minimumPriority, sAlertPanel, dsAlertPanelParameters, sAlertHelp, tempAttributes, tempValues,
								localException, bModifyOnly, bFallBackToSet);	
				break;
			default:
		  	fwException_raise(exceptionInfo, "ERROR",
		  								"fwAlertConfig_objectSetMany: Data point element type is not supported", "");
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
//  DebugN("Setting...", bStoreInParamHistory, attributes, values);

			if(bStoreInParamHistory)
				dpSetWait(attributes, values);
			else
				dpSetTimedWait(0, attributes, values);

			errors = getLastError(); 
    if(dynlen(errors) > 0)
    { 
	 			throwError(errors);
	 			fwException_raise(exceptionInfo, "ERROR", "fwAlertConfig_objectSetMany: Could not configure some alert configs", "");
			}
			
			dynClear(attributes);
			dynClear(values);
		}        
  }
    
	fwAlertConfig_activateMultiple(configsToDeactivate, exceptionInfo, FALSE, FALSE);
// DebugN("dpesToActivate:",dpesToActivate);
// 	fwAlertConfig_activateMultiple(dpesToActivate, exceptionInfo, FALSE, FALSE);
	if(dynlen(exceptionInfo)>0)
		return;
	else if(sAddDpeInSummary != "")
	{
		relativeSummaryPath = !dpExists(sAddDpeInSummary);
		if(!relativeSummaryPath)
		{
			for(i=1; i<=length; i++)
				dsSummaryDpes[i] = sAddDpeInSummary;	
		}
		else
		{
			for(i=1; i<=length; i++)
				dsSummaryDpes[i] = dpSubStr(dpes[i], DPSUB_SYS_DP) + sAddDpeInSummary;
		}

		_fwConfigs_getConfigTypeAttribute(dsSummaryDpes, fwConfigs_PVSS_ALERT_HDL, summaryConfigTypes, exceptionInfo);
		errors = getLastError(); 
    		if(dynlen(errors) > 0)
    		{ 
	 			fwException_raise(exceptionInfo, "ERROR", "fwAlertConfig_objectSetMany: Could not read all summary alerts.", "");
				return;
		}

		for(i=1; i<=length; i++)
		{
			if(summaryConfigTypes[i] == DPCONFIG_SUM_ALERT)
				fwAlertConfig_addDpInAlertSummary(dsSummaryDpes[i], dpSubStr(dpes[i], DPSUB_SYS_DP_EL), exceptionInfo, FALSE, bStoreInParamHistory);
			else if(summaryConfigTypes[i] != DPCONFIG_NONE)   
	 			fwException_raise(exceptionInfo, "ERROR", "fwAlertConfig_objectSetMany: The alert on \"" + dsSummaryDpes[i] + "\" is not a summary alert as expected.", "");

//DebugN(summaryConfigTypes[i], summaryDpes[i], dpes[i], exceptionInfo);
		}
	} 
  dynClear(attributes);
  dynClear(values);
  dynClear(tempAttributes);
  dynClear(tempValues); 
}


/** Returns the details of any alert configuration on a given dpe.
This function can handle digital, analog and summary alerts. For more info refer to fwAlertConfig_objectSet()
 - example: get an analog alarm from a dpe
  \snippet fwAlertConfig_Examples.ctl Example: get an analog alarm from a dpe
  
@ingroup fwConfigsAlert

@par Constraints
  None
  
@par Usage
	Public

@par PVSS managers
	VISION, CTRL

@param dpe							Name of data point element to read from
@param alertConfigObject		returns the object containing the parameters and the limits objects of the alarm.
@param exceptionInfo		Details of any exceptions are returned here   
@see fwAlertConfig_objectSet(), fwAlertConfig_objectSetMany(), fwAlertConfig_objectGetMany()
*/
fwAlertConfig_objectGet(string dpe, dyn_mixed &alertConfigObject, dyn_string &exceptionInfo)
{  
  dyn_dyn_mixed ddmAlertConfigObjects;
  dyn_string dsDpe;
  
  dsDpe[1] = dpe;
  fwAlertConfig_objectGetMany(dsDpe, ddmAlertConfigObjects, exceptionInfo);
//   DebugN("dmAlertLimits[1]: "+ddmAlertConfigObjects[1]);
  alertConfigObject = ddmAlertConfigObjects[1];
}


/** Get alarm based on alarm params and limits objects. For further info on how to handle alertConfigObjects, 
refer to the examples in fwAlertConfig_objectSet()
 - example: get analog alerts objects from 2 dpes
  \snippet fwAlertConfig_Examples.ctl Example: get alarms from two dpes
  
@ingroup fwConfigsAlert

@par Constraints
  dpes in list must all belong to one system
  
@par Usage
	Public

@par PVSS managers
	VISION, CTRL

@param dpes	Names of data point elements to read from. It is passed as reference only for performance reasons. It is not modified.
@param alertConfigObjects		returns the objects containing the parameters and the limits objects of the alarm.
@param exceptionInfo		Details of any exceptions are returned here   
@see fwAlertConfig_objectSet(), fwAlertConfig_objectSetMany(), fwAlertConfig_objectGet()
*/
fwAlertConfig_objectGetMany(dyn_string &dpes, dyn_dyn_mixed &alertConfigObjects, dyn_string &exceptionInfo)
{
	int i, j, k, n, indexAlertWithRanges, length, ranges;
	dyn_string dpesWithAlerts, dpesWithAnalogAlerts;
	dyn_int currentConfigTypes; 
   
	dyn_int numberOfRanges;    
	dyn_bool tempAlertActiveStates; 
    
  dyn_dyn_mixed ddmAlertParam, ddmAlertLimit;  
  dyn_string dsDpeAttr, dsSumDpeList;
  dyn_string dsDpeAttrType;
  dyn_mixed dmDpeType, dmDpeAttrVal;
  string sDpe, sClass, sSumDpePattern;
  int iDigitalOKRange;
  dyn_int diLimitNumbers;
  dyn_int diAlertRanges;
  int iDpesWithAlertLen;
  mapping mDiscreteAlerts;
  dyn_string dsDiscreteAttr, dsDiscreteVal;
  int iDiscreteTypeIndex;
  
	length = dynlen(dpes);

	_fwConfigs_getConfigTypeAttribute(dpes, fwConfigs_PVSS_ALERT_HDL, currentConfigTypes, exceptionInfo);
  k=1;
	for(i=1; i<=length; i++)
	{
    fwAlertConfig_objectInitialize(alertConfigObjects[i],1);
    if(currentConfigTypes[i] != DPCONFIG_NONE)
      dynAppend(dpesWithAlerts, dpes[i]);

    if(currentConfigTypes[i] == DPCONFIG_ALERT_NONBINARYSIGNAL)
      dynAppend(dpesWithAnalogAlerts, dpes[i]);
	}
  j = 1;
  k = 1;
  n = 1;
  iDpesWithAlertLen = dynlen(dpesWithAlerts);
  indexAlertWithRanges = iDpesWithAlertLen+1;
  //get the dpe types
//   DebugN("dpesWithAlerts: " +dpesWithAlerts);
  for(i=1; i<=iDpesWithAlertLen; i++)
  {
    sDpe = dpesWithAlerts[i];
    dsDpeAttrType[i] = sDpe+":_alert_hdl.1._type";
  }
  for(i=1; i<=dynlen(dpesWithAnalogAlerts); i++)
  {
    sDpe = dpesWithAnalogAlerts[i];// = strrtrim(dpes[i],".")+".";
    dsDpeAttrType[i+iDpesWithAlertLen] = sDpe+":_alert_hdl.._num_ranges";
  }  
//   DebugN("dsDpeAttrType: " +dsDpeAttrType);
  if(dynlen(dsDpeAttrType)==0)
  {// No alert config found
//     fwException_raise(exceptionInfo, "ERROR", "fwAlertConfig_objectGetMany: No alert config found for the following dpes: "+dpes, "");
    return;    
  }
  
  dpGet(dsDpeAttrType, dmDpeType);
//   DebugN("dmDpeType: " +dmDpeType);
//   DebugN("currentConfigTypes: " +currentConfigTypes);
  
  //depending on type, get dpe alarms info
  for(i=1; i<=length; i++)
  {      
    sDpe = dpes[i];
    switch(currentConfigTypes[i])
    {
      case DPCONFIG_NONE:
        diAlertRanges[i] = 1;
      break;
      case DPCONFIG_ALERT_BINARYSIGNAL:
        diAlertRanges[i] = 2;
        dsDpeAttr[k] = sDpe+":_alert_hdl.._ok_range";
        k++;
        dsDpeAttr[k] = sDpe+":_alert_hdl.._text0";
        k++;
        dsDpeAttr[k] = sDpe+":_alert_hdl.._text1";
        k++;
        dsDpeAttr[k] = sDpe+":_alert_hdl.._class";
        k++;
        dsDpeAttr[k] = sDpe+":_alert_hdl.._active";
        k++;
        dsDpeAttr[k] = sDpe+":_alert_hdl.._help";
        k++;
        dsDpeAttr[k] = sDpe+":_alert_hdl.._panel";
        k++;
        dsDpeAttr[k] = sDpe+":_alert_hdl.._panel_param";
        k++;
        n++; 
      break;
      case DPCONFIG_ALERT_NONBINARYSIGNAL:
         diAlertRanges[i] = dmDpeType[indexAlertWithRanges];//= (dynMax(diLimitNumbers) + 1);
      		for(j=1; j<=diAlertRanges[i]; j++)
      		{
        			dsDpeAttr[k] = sDpe+":_alert_hdl."+j+"._text";
             k++;
        			dsDpeAttr[k] = sDpe+":_alert_hdl."+j+"._went_text";
             k++;
        			dsDpeAttr[k] = sDpe+":_alert_hdl."+j+"._class";
             k++; 
           if(dmDpeType[n]==DPDETAIL_RANGETYPE_MATCH || dmDpeType[n]==DPDETAIL_RANGETYPE_SET)//if alarm is discrete, get some attributes
           {
        			dsDpeAttr[k] = sDpe+":_alert_hdl."+j+"._type";//used to be _match
             mDiscreteAlerts[dsDpeAttr[k]]=k;
             k++;
        			dsDpeAttr[k] = sDpe+":_alert_hdl."+j+"._neg";
             k++;
        			dsDpeAttr[k] = sDpe+":_alert_hdl."+j+"._status64_pattern";
             k++;
        			dsDpeAttr[k] = sDpe+":_alert_hdl."+j+"._status64_match";
             k++;    
           }
           else//if alarm is not discrete, get other attributes
           {
        			dsDpeAttr[k] = sDpe+":_alert_hdl."+j+"._u_limit";
             k++;
        			dsDpeAttr[k] = sDpe+":_alert_hdl."+j+"._u_incl";
             k++;
           }
         }
        dsDpeAttr[k] = sDpe+":_alert_hdl.._active";
        k++;
        dsDpeAttr[k] = sDpe+":_alert_hdl.._discrete_states";
        k++;
        dsDpeAttr[k] = sDpe+":_alert_hdl.._help";
        k++;
        dsDpeAttr[k] = sDpe+":_alert_hdl.._panel";
        k++;
        dsDpeAttr[k] = sDpe+":_alert_hdl.._panel_param";
        k++;
        n++;      
        indexAlertWithRanges++;
      break;     
      case DPCONFIG_SUM_ALERT:
        diAlertRanges[i] = 2;
        dsDpeAttr[k] = sDpe+":_alert_hdl.._dp_list";
        k++;
        dsDpeAttr[k] = sDpe+":_alert_hdl.._dp_pattern";
        k++;
        dsDpeAttr[k] = sDpe+":_alert_hdl.._class";
        k++; 
        dsDpeAttr[k] = sDpe+":_alert_hdl.._text0";
        k++;
        dsDpeAttr[k] = sDpe+":_alert_hdl.._text1";
        k++;
        dsDpeAttr[k] = sDpe+":_alert_hdl.._filter_threshold";
        k++;
        dsDpeAttr[k] = sDpe+":_alert_hdl.._active";
        k++;
        dsDpeAttr[k] = sDpe+":_alert_hdl.._help";
        k++;
        dsDpeAttr[k] = sDpe+":_alert_hdl.._panel";
        k++;
        dsDpeAttr[k] = sDpe+":_alert_hdl.._panel_param";
        k++;
        n++; 
      break;
    }    
  }
// DebugN("dsDpeAttr: ", dsDpeAttr);
  if(dynlen(dsDpeAttr)==0)//no alarms found
  {
//     fwException_raise(exceptionInfo, "ERROR", "fwAlertConfig_objectGetMany: No alert config found for the following dpes: "+dpes, "");
    return;    
  }

  //get all the alarm attributes, BUT the discrete values (for that, we need first more info...)
  dpGet(dsDpeAttr, dmDpeAttrVal);
// DebugN("objectGetMany:",dsDpeAttr, dmDpeAttrVal);
  
  
  //prepare a get for the discrete alerts: if the type is DPDETAIL_RANGETYPE_MATCH, take attribute _match. 
  //if DPDETAIL_RANGETYPE_SET, take attribute _set
  for (i = 1; i <= mappinglen(mDiscreteAlerts); i++) 
  {
    iDiscreteTypeIndex = mappingGetValue(mDiscreteAlerts, i);
//     DebugN("mDiscreteAlerts", i, "is="+iDiscreteTypeIndex, "the type is: "+dmDpeAttrVal[iDiscreteTypeIndex]);
    dsDiscreteAttr[i] = mappingGetKey(mDiscreteAlerts, i);
    if(dmDpeAttrVal[iDiscreteTypeIndex]==DPDETAIL_RANGETYPE_MATCH)
      strreplace(dsDiscreteAttr[i],"._type","._match");
    else
      strreplace(dsDiscreteAttr[i],"._type","._set");
  }
  //if there is any discrete alarm, get the _match or _set of discrete values, depending on their types
//   DebugN("dsDiscreteAttr:", dsDiscreteAttr);
  if(dynlen(dsDiscreteAttr))
    dpGet(dsDiscreteAttr, dsDiscreteVal);
//   DebugN( "dsDiscreteVal:",dsDiscreteVal);
  //insert the discrete values into the result arrays
  for (i = 1; i <= mappinglen(mDiscreteAlerts); i++) 
  {
    iDiscreteTypeIndex = mappingGetValue(mDiscreteAlerts, i);
//     DebugN("mDiscreteAlerts", i, "is="+iDiscreteTypeIndex, "the type is: "+dmDpeAttrVal[iDiscreteTypeIndex],"the value:",(string)dsDiscreteVal[i]);
    dsDpeAttr[iDiscreteTypeIndex] = dsDiscreteAttr[i];
    strreplace(dsDiscreteVal[i]," | ",",");
    dmDpeAttrVal[iDiscreteTypeIndex] = (string)dsDiscreteVal[i];
  }
  
// DebugN("dmDpeAttrVal: ",dsDpeAttr,dmDpeAttrVal);

  if(dynlen(dmDpeAttrVal)==0)
  {
    fwException_raise(exceptionInfo, "ERROR", "fwAlertConfig_objectGetMany: Some config attribute does not exist for some of the following dpes: "+dpes, "");
    return;    
  }

  //store values to the params objects
  k=1;
  n=1;
  for(i=1; i<=length; i++)
  {      
    dynClear(ddmAlertLimit);
    dynClear(ddmAlertParam);
//     DebugN("dmDpeType[i]: "+dmDpeType[i]);
    _fwAlertConfig_objectCreateParams(ddmAlertParam, ddmAlertLimit, diAlertRanges[i]);
    switch(currentConfigTypes[i])
    {
      case DPCONFIG_NONE:
      break;
      case DPCONFIG_ALERT_BINARYSIGNAL:
        ddmAlertParam[fwAlertConfig_ALERT_PARAM_TYPE] = DPCONFIG_ALERT_BINARYSIGNAL;
        iDigitalOKRange = dmDpeAttrVal[k];// = sDpe+":_alert_hdl.._ok_range";
        k++;
        ddmAlertLimit[1][fwAlertConfig_ALERT_LIMIT_TEXT] = dmDpeAttrVal[k];// = sDpe+":_alert_hdl.._text0";
        k++;
        ddmAlertLimit[2][fwAlertConfig_ALERT_LIMIT_TEXT] = dmDpeAttrVal[k];// = sDpe+":_alert_hdl.._text1";
        k++;
        sClass = dmDpeAttrVal[k];// = sDpe+":_alert_hdl.._class";
        ddmAlertLimit[1][fwAlertConfig_ALERT_LIMIT_CLASS] = (iDigitalOKRange == 0) ? "" : sClass;
        ddmAlertLimit[2][fwAlertConfig_ALERT_LIMIT_CLASS] = (iDigitalOKRange == 0) ? sClass : "";       
        k++;
        ddmAlertParam[fwAlertConfig_ALERT_PARAM_ACTIVE][1] = dmDpeAttrVal[k];// = sDpe+":_alert_hdl.._active";
        k++;
        ddmAlertParam[fwAlertConfig_ALERT_PARAM_HELP][1] = dmDpeAttrVal[k];// = sDpe+":_alert_hdl.._help";
        k++;
        ddmAlertParam[fwAlertConfig_ALERT_PARAM_PANEL][1] = dmDpeAttrVal[k];// = sDpe+":_alert_hdl.._panel";
        k++;
        ddmAlertParam[fwAlertConfig_ALERT_PARAM_PANEL_PARAMETERS] = dmDpeAttrVal[k];// = sDpe+":_alert_hdl.._panel_param";
        k++;
      break;
      case DPCONFIG_ALERT_NONBINARYSIGNAL:
        ddmAlertParam[fwAlertConfig_ALERT_PARAM_TYPE] = DPCONFIG_ALERT_NONBINARYSIGNAL;
      	for(j=1; j<=diAlertRanges[i]; j++)
      	{
          ddmAlertLimit[j][fwAlertConfig_ALERT_LIMIT_TEXT] = dmDpeAttrVal[k];// = sDpe+":_alert_hdl.<i>._text";
          k++;
          ddmAlertLimit[j][fwAlertConfig_ALERT_LIMIT_TEXT_WENT] = dmDpeAttrVal[k];// = sDpe+":_alert_hdl.<i>._went_text";
          k++;
          ddmAlertLimit[j][fwAlertConfig_ALERT_LIMIT_CLASS] = dmDpeAttrVal[k];// = sDpe+":_alert_hdl.<i>._class";     
          k++;
          if(dmDpeType[n]==DPDETAIL_RANGETYPE_MATCH || dmDpeType[n]==DPDETAIL_RANGETYPE_SET)//if alarm is discrete, get some attributes
          {          
            ddmAlertLimit[j][fwAlertConfig_ALERT_LIMIT_VALUE_MATCH] = dmDpeAttrVal[k];// if sets (##,##,##): = sDpe+":_alert_hdl.<i>._set";    if single value (##) or range (##-##):  = sDpe+":_alert_hdl.<i>._match";     
            k++;
            ddmAlertLimit[j][fwAlertConfig_ALERT_LIMIT_NEGATION] = dmDpeAttrVal[k];// = sDpe+":_alert_hdl.<i>._neg";     
            k++;
            ddmAlertLimit[j][fwAlertConfig_ALERT_LIMIT_STATE_BITS] = dmDpeAttrVal[k];// = sDpe+":_alert_hdl.<i>._status64_pattern";     
            k++;
            ddmAlertLimit[j][fwAlertConfig_ALERT_LIMIT_LIMITS_STATE_BITS] = dmDpeAttrVal[k];// = sDpe+":_alert_hdl.<i>._status64_match";     
            k++;
          }
          else
          {
            if(j==1)
            {
              ddmAlertLimit[j][fwAlertConfig_ALERT_LIMIT_VALUE] = 0;// first limit is null  (#limits=#classes-1)
              ddmAlertLimit[j][fwAlertConfig_ALERT_LIMIT_VALUE_INCLUDED] = 0;// first limit is null (#limits=#classes-1)    
            } 
            if(j<diAlertRanges[i])        
              ddmAlertLimit[j+1][fwAlertConfig_ALERT_LIMIT_VALUE] = dmDpeAttrVal[k];// = sDpe+":_alert_hdl.<i>._u_limit";     
            k++;
            if(j<diAlertRanges[i])        
              ddmAlertLimit[j+1][fwAlertConfig_ALERT_LIMIT_VALUE_INCLUDED] = dmDpeAttrVal[k];// = sDpe+":_alert_hdl.<i>._u_incl";     
            k++;           
          }
        }
        ddmAlertParam[fwAlertConfig_ALERT_PARAM_ACTIVE][1] = dmDpeAttrVal[k];// = sDpe+":_alert_hdl.._active";
        k++;
        ddmAlertParam[fwAlertConfig_ALERT_PARAM_DISCRETE][1] = dmDpeAttrVal[k];// = sDpe+":_alert_hdl.._discrete_states";
        k++;
        ddmAlertParam[fwAlertConfig_ALERT_PARAM_HELP][1] = dmDpeAttrVal[k];// = sDpe+":_alert_hdl.._help";
        k++;
        ddmAlertParam[fwAlertConfig_ALERT_PARAM_PANEL][1] = dmDpeAttrVal[k];// = sDpe+":_alert_hdl.._panel";
        k++;
        ddmAlertParam[fwAlertConfig_ALERT_PARAM_PANEL_PARAMETERS] = dmDpeAttrVal[k];// = sDpe+":_alert_hdl.._panel_param";
        k++;
        n++;
      break;     
      case DPCONFIG_SUM_ALERT:
        ddmAlertParam[fwAlertConfig_ALERT_PARAM_TYPE] = DPCONFIG_SUM_ALERT;
        dsSumDpeList = dmDpeAttrVal[k];// = sDpe+":_alert_hdl.._dp_list";
        k++;
        sSumDpePattern = dmDpeAttrVal[k];// = sDpe+":_alert_hdl.._dp_pattern";
        if(dynlen(dsSumDpeList) == 0)
        {
          if(sSumDpePattern != fwAlertConfig_FW_NULL_PATTERN)
            dsSumDpeList[1] = sSumDpePattern;    
          else
            dsSumDpeList = makeDynString();
        }
        ddmAlertParam[fwAlertConfig_ALERT_PARAM_SUM_DPE_LIST] = dsSumDpeList;
        k++;
        ddmAlertParam[1][fwAlertConfig_ALERT_LIMIT_CLASS] = dmDpeAttrVal[k];//= sDpe+":_alert_hdl.._class";
        k++;     
        ddmAlertLimit[1][fwAlertConfig_ALERT_LIMIT_TEXT] = dmDpeAttrVal[k];//= sDpe+":_alert_hdl.._text0";
        k++;
        ddmAlertLimit[2][fwAlertConfig_ALERT_LIMIT_TEXT] = dmDpeAttrVal[k];//= sDpe+":_alert_hdl.._text1";
        k++;
        ddmAlertParam[fwAlertConfig_ALERT_PARAM_SUM_THRESHOLD][1] = isAlertFilteringActive() ? dmDpeAttrVal[k] : 0;//= sDpe+":_alert_hdl.._filter_threshold";
        dpExists("");// WORKAROUND: clear the lastError generated by isAlertFilteringActive; see ENS-3480
        k++;
        ddmAlertParam[fwAlertConfig_ALERT_PARAM_ACTIVE][1] = dmDpeAttrVal[k];//= sDpe+":_alert_hdl.._active";
        k++;
        ddmAlertParam[fwAlertConfig_ALERT_PARAM_HELP][1] = dmDpeAttrVal[k];//= sDpe+":_alert_hdl.._help";
        k++;
        ddmAlertParam[fwAlertConfig_ALERT_PARAM_PANEL][1] = dmDpeAttrVal[k];//= sDpe+":_alert_hdl.._panel";
        k++;
        ddmAlertParam[fwAlertConfig_ALERT_PARAM_PANEL_PARAMETERS] = dmDpeAttrVal[k];//= sDpe+":_alert_hdl.._panel_param";
        k++;
        n++;          
      break;      
    }
//     DebugN("ddmAlertParam: "+ddmAlertParam);
//     DebugN("ddmAlertLimit: "+ddmAlertLimit);
    alertConfigObjects[i][fwAlertConfig_ALERT_PARAM] = ddmAlertParam;
    alertConfigObjects[i][fwAlertConfig_ALERT_LIMIT] = ddmAlertLimit;
  }
    
  dyn_errClass err=getLastError();
  if (dynlen(err)) fwException_raise(exceptionInfo,"ERROR","Error in fwAlertConfig_getObjectMany, "+(string)err, "");

  dynClear(ddmAlertParam);
  dynClear(ddmAlertLimit);
  dynClear(dsDpeAttrType);
  dynClear(dmDpeType);
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

@ingroup fwConfigsAlert

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

//@} // end of Get/Set functions


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
	
	values = makeDynMixed(okRange, alertTexts[2], alertTexts[1], alertClass);
	
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
		tempValue = makeDynMixed(alertPanelParameters);
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
@param alertWentTexts				Optional parameter - the list of went texts, one per range.
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
                						  bool fallBackToSet = FALSE,
                          dyn_string alertWentTexts=makeDynString())
{    
	bool deactivated, alertHelpChanged, isActive = FALSE, modifyExistingConfig;
	int configType, currentRanges;  
	int i, j, length, ranges, numberOfAttributes, attributeOffset;
	string attribute, dpeSystem;
	dyn_string attributeTemplates;
	dyn_float upperHystLimits, lowerHystLimits;
	dyn_mixed desiredValues;
	dyn_mixed tempValue;
	dyn_bool notIncludeLimits;
  bool noWentText = TRUE;

	const string alertHandlingTypeAttribute = ":_alert_hdl.<i>._type";
	const string hysteresisTypeAttribute = ":_alert_hdl.<i>._hyst_type";
	const string upperLimitAttribute = ":_alert_hdl.<i>._u_limit";
	const string lowerLimitAttribute = ":_alert_hdl.<i>._l_limit";
	const string alertTextAttribute = ":_alert_hdl.<i>._text";
	const string alertWentTextAttribute = ":_alert_hdl.<i>._went_text";
	const string alertClassAttribute = ":_alert_hdl.<i>._class";
	const string includeLowerLimitAttribute = ":_alert_hdl.<i>._l_incl";
	const string includeUpperLimitAttribute = ":_alert_hdl.<i>._u_incl";
	const string hysteresisUpperLimitAttribute = ":_alert_hdl.<i>._u_hyst_limit";
	const string hysteresisLowerLimitAttribute = ":_alert_hdl.<i>._l_hyst_limit";
  
	dynClear(attributes);
	dynClear(values);

// DebugN("limits: "+limits);
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

  //if no went text was specified, build an empty variable
  if(dynlen(alertWentTexts)<ranges)
    for(i=dynlen(alertWentTexts) ; i<=ranges ; i++)
      dynAppend(alertWentTexts,"");
	//check that all dyn_vars are of a consistent length for the number of ranges
 if(dynlen(limits) == dynlen(alertTexts) && dynlen(limits) > 1)
   dynRemove(limits,1);
 if(dynlen(includeLimits) == dynlen(alertTexts) && dynlen(includeLimits) > 1)
   dynRemove(includeLimits,1);
	if(	dynlen(alertTexts) != ranges ||
		dynlen(alertClasses) != ranges ||
		dynlen(limits) != (ranges-1) ||
   dynlen(alertWentTexts) > ranges)
	{
		fwException_raise(exceptionInfo, "ERROR", "_fwAlertConfig_prepareAnalog: The alert configuration for \"" + dpe + "\" is not consistent (Check length of dyn variables for alarm texts, classes and limits)", "");
		return;
	}
  //check limits values consistency
  for(i=1 ; i< ranges-1 ; i++)
  {
    if(limits[i]>=limits[i+1])
    {
    		fwException_raise(exceptionInfo, "ERROR", "_fwAlertConfig_prepareAnalog: The alert limits for \"" + dpe + "\" are not consistent (Check limits values)", "");
    		return;
    }
  }

	if(!modifyExistingConfig)
	{
		if(	dynlen(hysteresisType) != ranges ||
			dynlen(alertHandlingType) != ranges ||
			dynlen(includeLimits) != (ranges-1) ||
			dynlen(hysteresisLimits) != ((ranges-1)*2))
		{
			fwException_raise(exceptionInfo, "ERROR", "_fwAlertConfig_prepareAnalog: The alert configuration for \"" + dpe + "\" is not consistent (Check length of dyn variables for alarm limits)", "");
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
  //check if the went_text is present. 
  //This to avoid writing this config to prevent back-compatibility problems (went_text not available on 3.6)
	for(i=1; i<=ranges; i++)
	{
    noWentText = noWentText && (alertWentTexts[i]=="");
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
		desiredValues = makeDynMixed(limits, limits, alertTexts, alertClasses);
	}
	else
	{
    if(noWentText)//avoid writing the attribute _went_text (not existing on PVSS 3.6)
    {
	  //build list of attribute templates from globals constants without went_text      
		attributeTemplates = makeDynString(alertHandlingTypeAttribute, hysteresisTypeAttribute,
											lowerLimitAttribute, upperLimitAttribute, 
											alertTextAttribute, alertClassAttribute,
											includeLowerLimitAttribute, includeUpperLimitAttribute, 
											hysteresisLowerLimitAttribute, hysteresisUpperLimitAttribute);
			
		//build array of most of the values to be written
		desiredValues = makeDynMixed(configType, 
                 alertHandlingType, hysteresisType,
											limits, limits, 
											alertTexts, alertClasses,
											TRUE, notIncludeLimits, includeLimits, TRUE,
											lowerHystLimits, upperHystLimits);
  }
  else
  {
	  //build list of attribute templates from globals constants          
		attributeTemplates = makeDynString(alertHandlingTypeAttribute, hysteresisTypeAttribute,
											lowerLimitAttribute, upperLimitAttribute, 
											alertTextAttribute, alertClassAttribute,
											includeLowerLimitAttribute, includeUpperLimitAttribute, 
											hysteresisLowerLimitAttribute, hysteresisUpperLimitAttribute,
                      alertWentTextAttribute);
			
		//build array of most of the values to be written
		desiredValues = makeDynMixed(configType, 
                 alertHandlingType, hysteresisType,
											limits, limits, 
											alertTexts, alertClasses,
											TRUE, notIncludeLimits, includeLimits, TRUE,
											lowerHystLimits, upperHystLimits, alertWentTexts);
  }    
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
		tempValue = makeDynMixed(alertPanelParameters);
		dynAppend(values, tempValue);
	}

	if(!modifyExistingConfig)
	{
		dynAppend(attributes, dpe + ":_alert_hdl.._min_prio");
		dynAppend(values, minimumPriority);
		dynAppend(attributes, dpe + ":_alert_hdl.._orig_hdl");
		dynAppend(values, FALSE);
	}
  dynClear(alertPanelParameters);
  dynClear(desiredValues);
  dynClear(attributeTemplates);

//  DebugN(attributes, values);
} 


/** Prepares a list of attributes and a list of values to be used in a dpSetWait() call to set the discrete config for the given dpe. 

@par Constraints
	The length of the alertTexts, alertHandlingType, hysteresisType , limits and includeLimits alertClasses dyn_vars must be equal

@par Usage
	Internal

@par PVSS managers
	VISION, CTRL

@param dpe							Name of data point element to act on
@param currentConfigType	The type of the current alert config on the data point element (only considered in case of modifyOnly = TRUE, otherwise value is ignored)
@param currentNumberOfRanges	The current number of ranges in the alert config on the data point element (only considered in case of modifyOnly = TRUE, otherwise value is ignored)
@param alertHandlingType	One value in dyn_int for each range to be used. Value should be DPDETAIL_RANGETYPE_MINMAX;
@param limitsMatch						The values match of each range given here eg. makeDynString( "*", "2,4,5", "3", "6-10" ); First element must be *.
@param alertTexts				Alert texts for each range eg. makeDynString( "Bad Text", "OK", "Bad Text")   
@param alertClasses			Alert classes for each range eg. makeDynString( "_fwErrorAck.", "" , "_fwErrorAck.")
													One of the items of the dyn_string must always be empty to indicate the valid state.
													The valid ranges becomes the state with no alert class given (the second in this case).
													Don't forget to add the dot to the alert class names.
@param minimumPriority	Minimum priority of alert (ignore below this value)
@param alertPanel				Panel to call from the alert screen
@param alertPanelParameters		Parameters to pass to panel given in Alert Panel
@param alertHelp				Help text or path to help file    
@param impulse	   If TRUE, the discrete alert reacts to impulses.
@param discreteNegation   One per limit. If FALSE, the alarm is triggered if the value matches that limit. 
                         If TRUE, the alarm is triggered if the value does not match that limit.
@param stateBits    State Bits of the alarm. (i.e. 000010011000).                        
@param stateMatch   State Bits of the limit. One per limit. (i.e. xxx0010x110xxx).                        
@param attributes				Output - the list of attributes that need to be set is returned here
@param values						Output - the list of values that need to be set is returned here
@param exceptionInfo		Details of any exceptions are returned here   
@param modifyOnly				Optional parameter - Default value FALSE.  Set to TRUE to modify alert without setting "type" attributes.
						This is much quicker, but the alert config must already exist, be an analog alert and have the same number of ranges as you want.
@param fallBackToSet			Optional parameter - Default value FALSE.  Used in combination with modifyOnly.
						If modifyOnly = TRUE and fallBackToSet = FALSE, then if the alert config is not compatible an exception is raised. 
						If modifyOnly = TRUE and fallBackToSet = TRUE, then if the alert config is not compatible, modifyOnly is treated as if it was FALSE. 
@param alertWentTexts				Optional parameter - the list of went texts, one per range.
*/
_fwAlertConfig_prepareAnalogDiscrete( string dpe,
                                int currentConfigType,
                                int currentNumberOfRanges,
                                dyn_int alertHandlingType,    
                                dyn_string limitsMatch,    
                                dyn_string alertTexts,    
                                dyn_string alertClasses,    
                                int minimumPriority,    
                                string alertPanel,    
                                dyn_string alertPanelParameters,    
                                string alertHelp,                              
                                 bool impulse,
                                 dyn_bool discreteNegation,
                                 dyn_string stateBits,
                                 dyn_string stateMatch,                           
                                 dyn_string &attributes,
                                 dyn_mixed &values,
                      						   dyn_string &exceptionInfo,
                        						bool modifyOnly = FALSE,
                        						bool fallBackToSet = FALSE,
                                 dyn_string alertWentTexts=makeDynString())
{    
	bool deactivated, alertHelpChanged, isActive = FALSE, modifyExistingConfig;
	int configType, currentRanges;  
	int i, j, length, ranges, numberOfAttributes, attributeOffset;
	string attribute, dpeSystem;
	dyn_string attributeTemplates;
	dyn_mixed desiredValues;
	dyn_mixed tempValue;
	dyn_bool notIncludeLimits;
  dyn_bit64 db64stateBits;
  
  dyn_string dsValuesMatch;
  
	const string alertHandlingTypeAttribute = ":_alert_hdl.<i>._type";
	const string alertTextAttribute = ":_alert_hdl.<i>._text";
	const string alertWentTextAttribute = ":_alert_hdl.<i>._went_text";
	const string alertClassAttribute = ":_alert_hdl.<i>._class";  
	const string alertDiscreteMatchAttribute = ":_alert_hdl.<i>._match";
	const string alertDiscreteNegatedAttribute = ":_alert_hdl.<i>._neg";
	const string alertStateBitsAttribute = ":_alert_hdl.<i>._status64_pattern";
	const string alertStateMatchAttribute = ":_alert_hdl.<i>._status64_match";

	dynClear(attributes);
	dynClear(values);

	ranges = dynlen(alertTexts);
  
  //add default match value limit
  //first limit is always "*" (default value)
  dsValuesMatch = limitsMatch;
  if(dynlen(dsValuesMatch)==(dynlen(alertTexts)-1))
    dynInsertAt(dsValuesMatch,"*",1);
	else if(dsValuesMatch[1]!="*")
	{
		dsValuesMatch[1]="*";
	}
  //if no went text was specified, build an empty variable
  if(dynlen(alertWentTexts)<ranges)
    for(i=dynlen(alertWentTexts) ; i<=ranges ; i++)
      dynAppend(alertWentTexts,"");
  
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
				fwException_raise(exceptionInfo, "ERROR", "_fwAlertConfig_prepareAnalogDiscrete: Alert config does not exist on \"" + dpe + "\" so it cannot be modified", "");
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
				fwException_raise(exceptionInfo, "ERROR", "_fwAlertConfig_prepareAnalogDiscrete: Cannot modify current alert config on \"" + dpe + "\" because it contains a different number of ranges", "");
				return;
			}
		}
		else
			modifyExistingConfig = TRUE;
	}
	else
		modifyExistingConfig = FALSE;
	//check that all dyn_vars are of a consistent length for the number of ranges
//   DebugN(alertTexts);
//   Debug("alertClasses:");DebugN(alertClasses);
//   DebugN(discreteNegation);
//   Debug("dsValuesMatch:");DebugN(dsValuesMatch);  
//   DebugN(alertHandlingType);  
//   DebugN(ranges);
  
	if(	dynlen(alertTexts) != ranges ||
		dynlen(alertClasses) != ranges ||
		(dynlen(discreteNegation) != (ranges-1) && dynlen(discreteNegation) != ranges) ||
		dynlen(dsValuesMatch) != (ranges) ||
   (dynlen(stateMatch) != (ranges-1) && dynlen(stateMatch) != ranges) ||
   dynlen(alertWentTexts) > ranges)
	{
		fwException_raise(exceptionInfo, "ERROR", "_fwAlertConfig_prepareAnalogDiscrete: The alert configuration for \"" + dpe + "\" is not consistent (Check length of dyn variables)", "");
		return;
	}

	if(!modifyExistingConfig)
	{
		if(	dynlen(alertHandlingType) != ranges)
		{
			fwException_raise(exceptionInfo, "ERROR", "_fwAlertConfig_prepareAnalogDiscrete: The alert configuration for \"" + dpe + "\" is not consistent (Check length of dyn variables alertHandlingType)", "");
			return;
		}
	}

	if(dynContains(alertClasses, "")<=0)
	{
		fwException_raise(exceptionInfo, "ERROR", "_fwAlertConfig_prepareAnalogDiscrete: There is no valid range for \"" + dpe + "\".  One range must have alert class equal to \"\"", "");
		return;
	}

	//for the alertClasses, ensure that the same system as the dpe is used.
	length = dynlen(alertClasses);
	for(i=1; i<=length; i++)
	{
		if(alertClasses[i] != "")
		{
      if(dsValuesMatch[i]=="")
      {
      		fwException_raise(exceptionInfo, "ERROR", "_fwAlertConfig_prepareAnalogDiscrete: One or more value match is missing for \"" + dpe + "\".  Each range must have a value to match", "");
      		return;
      }
      if(patternMatch("*[abcdefghijklmnopqrstuvxyz]*",dsValuesMatch[i]))
      {
      		fwException_raise(exceptionInfo, "ERROR", "_fwAlertConfig_prepareAnalogDiscrete: One or more value match contains illegal characters for \"" + dpe + "\".  Allowed characters: numbers, \",\", \"-\", \"*\"", "");
      		return;
      }
      //add system name to alarm class dpe name
  			dpeSystem = dpSubStr(dpe, DPSUB_SYS);
  			if(strpos(alertClasses[i], dpeSystem) != 0)
  				alertClasses[i] = dpeSystem + alertClasses[i];
        
		}
   db64stateBits[i] = stateBits[i];
	}
  
  //discrete negations must be as many as alarm levels
  //and the first value of discrete negation must be FALSE.
  if(dynlen(discreteNegation)==length)
    discreteNegation[1] = FALSE;
  else
    dynInsertAt(discreteNegation,FALSE,1);
  //statematches must be as many as alarm levels
  //the first value of statematch must be empty
  if(dynlen(stateMatch)==length)
    stateMatch[1] = "";
  else
    dynInsertAt(stateMatch,"",1);
  
//    DebugN(stateMatch);
//    DebugN(stateBits);
	if(modifyExistingConfig)
	{
		//build list of attribute templates from globals constants          
		attributeTemplates = makeDynString(alertHandlingTypeAttribute,
                                       alertDiscreteMatchAttribute, 
                                       alertTextAttribute, 
                                       alertClassAttribute);
			
		//build array of most of the values to be written
		desiredValues = makeDynMixed(alertHandlingType, dsValuesMatch, alertTexts, alertClasses);
	}
	else
	{
	  //build list of attribute templates from globals constants          
    //DO NOT CHANGE THE ORDER OF THESE VALUES! Add new attributes at the bottom.
		attributeTemplates = makeDynString(alertHandlingTypeAttribute,
											  alertDiscreteMatchAttribute,
											 alertTextAttribute, alertClassAttribute,
                       alertDiscreteNegatedAttribute, 
                       alertStateBitsAttribute, 
                       alertStateMatchAttribute,
                       alertWentTextAttribute);
				
		//build array of most of the values to be written
		desiredValues = makeDynMixed(configType, alertHandlingType,
                 dsValuesMatch, alertTexts, alertClasses,
											discreteNegation, db64stateBits, stateMatch, alertWentTexts);

		//start building list of attributes
		dynAppend(attributes, dpe + ":_alert_hdl.._type");
	}

	//add range dependant attributes to list
	length = dynlen(attributeTemplates);
	for(i=1; i<=length; i++)
	{
		attributeOffset = 0;
		numberOfAttributes = ranges;
		
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
		dynAppend(attributes, dpe + ":_alert_hdl.._impulse");
		dynAppend(values, impulse);
		dynAppend(attributes, dpe + ":_alert_hdl.._discrete_states");
		dynAppend(values, TRUE);
		dynAppend(attributes, dpe + ":_alert_hdl.._help");
		dynAppend(values, alertHelp);
		dynAppend(attributes, dpe + ":_alert_hdl.._panel");
		dynAppend(values, alertPanel);
		dynAppend(attributes, dpe + ":_alert_hdl.._panel_param");
		//alert panel parameters are added in such a way as they stay as a dyn_string when appended
		tempValue = makeDynMixed(alertPanelParameters);
		dynAppend(values, tempValue);
	}

	if(!modifyExistingConfig)
	{
		dynAppend(attributes, dpe + ":_alert_hdl.._min_prio");
		dynAppend(values, minimumPriority);
		dynAppend(attributes, dpe + ":_alert_hdl.._orig_hdl");
		dynAppend(values, FALSE);
	}

  //if the value is a set of values (i.e. "3,4,5,7"), is must be set into _set as dyn_string and the type of range must be 3.
  //Otherwise, leave it into _match as string and the type of range must be 5.
  //WARNING: this piece of code is tremporarily disabled because of the bug on PVSS 3.8.2, as described on ETM-824
//   for(i=1; i<=dynlen(values); i++)
// 	{
//     if(patternMatch("*._match",attributes[i]) && patternMatch("*,*", values[i]))
//     {     
//       strreplace(attributes[i],"._match","._set");
//       fwGeneral_stringToDynString(values[i], values[i], ",");
//       values[i-ranges] = DPDETAIL_RANGETYPE_SET;//set attribute _type
//     }
//   }
//   DebugN(attributes, values);
} 


/** Prepares a list of attributes and a list of values to be used in a dpSetWait() call to set the discrete config for the given dpe. 

@par Constraints
	The length of the alertTexts, alertHandlingType, hysteresisType , limits and includeLimits alertClasses dyn_vars must be equal

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
@param impulse	   If TRUE, the discrete alert reacts to impulses.
@param stateBits    State Bits of the alarm. (i.e. 000010011000).                        
@param attributes			Output - the list of attributes that need to be set is returned here
@param values					Output - the list of values that need to be set is returned here
@param exceptionInfo	Details of any exceptions are returned here   
@param modifyOnly				Optional parameter - Default value FALSE.  Set to TRUE to modify alert without setting "type" attributes.
						This is much quicker, but the alert config must already exist and must be of type binary alert.
@param fallBackToSet			Optional parameter - Default value FALSE.  Used in combination with modifyOnly.
						If modifyOnly = TRUE and fallBackToSet = FALSE, then if the alert config is not compatible an exception is raised. 
						If modifyOnly = TRUE and fallBackToSet = TRUE, then if the alert config is not compatible, modifyOnly is treated as if it was FALSE. 
*/
_fwAlertConfig_prepareDigitalDiscrete(string dpe,
							int currentConfigType,
							dyn_string alertTexts,
							dyn_string alertClasses,
							int minimumPriority,    
							string alertPanel,
							dyn_string alertPanelParameters,
							string alertHelp,
           bool impulse,
           dyn_string stateBits,                          
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
	
	configType = DPCONFIG_ALERT_NONBINARYSIGNAL;
	if(modifyOnly)
	{
		if(currentConfigType != configType)
		{
			if(fallBackToSet)
				modifyExistingConfig = FALSE;
			else
			{
				fwException_raise(exceptionInfo, "ERROR", "fwAlertConfig_prepareDigitalDiscrete: Alert config does not exist on \"" + dpe + "\" so it cannot be modified", "");
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
		fwException_raise(exceptionInfo, "ERROR", "fwAlertConfig_prepareDigitalDiscrete: The alert configuration required for \"" + dpe + "\" is not consistent (Check length of dyn variables AlertTexts and AlertClasses)", "");
		return;
	}

  //state bits must all be the same for each index. 
		stateBits[2]=stateBits[1];
 
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
		fwException_raise(exceptionInfo, "ERROR", "fwAlertConfig_prepareDigitalDiscrete: There is no valid range for \"" + dpe + "\".  One range must have alert class equal to \"\"", "");
		return;
	}

   for(i=1 ; i<=2 ; i++)
   {
  		dynAppend(values, alertClasses[i]);
  		dynAppend(attributes, dpe + ":_alert_hdl."+i+"._class");
  		dynAppend(values, alertTexts[i]);
  		dynAppend(attributes, dpe + ":_alert_hdl."+i+"._text");
  		dynAppend(values, stateBits[i]);
  		dynAppend(attributes, dpe + ":_alert_hdl."+i+"._status64_pattern");
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
		tempValue = makeDynMixed(alertPanelParameters);
		dynAppend(values, tempValue);
	}

	if(!modifyExistingConfig)
	{
		dynInsertAt(attributes, dpe + ":_alert_hdl.._type", 1);
		dynInsertAt(values, configType, 1);
		dynAppend(attributes, dpe + ":_alert_hdl.._min_prio");
		dynAppend(values, minimumPriority);
		dynAppend(attributes, dpe + ":_alert_hdl.._orig_hdl");
		dynAppend(values, TRUE);
		dynAppend(attributes, dpe + ":_alert_hdl.._impulse");
		dynAppend(values, impulse);
		dynAppend(attributes, dpe + ":_alert_hdl.._discrete_states");
		dynAppend(values, TRUE);
   for(i=1 ; i<=2 ; i++)
   {
  		dynAppend(attributes, dpe + ":_alert_hdl."+i+"._type");
  		dynAppend(values, DPDETAIL_RANGETYPE_MATCH);
  		dynAppend(values, i-1);
  		dynAppend(attributes, dpe + ":_alert_hdl."+i+"._match");
   }
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
@param alertType	Type of alert on dpe:
													DPCONFIG_ALERT_BINARYSIGNAL if digital alert handling
													DPCONFIG_ALERT_NONBINARYSIGNAL if analog alert handling
													DPCONFIG_SUM_ALERT if summary alert handling
@param alertTexts				Alert texts for each range  
@param alertLimits			The limits of each range given here
@param alertClass				Alert classes for each range 
													One of the items of the dyn_string must always be empty to indicate the valid state.
													Don't forget to add the dot to the alert class names.
@param summaryDpeList		If Summary alert, the dpeList is returned here
                                      If a DP pattern was specified, then this will be returned as the first item in this list.
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

/** Returns the discrete alert handling properties of a analog or digital datapoint
	if the number of alert texts returned is 0, then no alert configuration exists

NOTE: THIS FUNCTION SHOULD NOT BE CALLED DIRECTLY, use fwAlertConfig_get

@par Constraints
	The length of the alertTexts and alertClasses dyn_strings must both be 2

@par Usage
	Internal

@par PVSS managers
	VISION, CTRL

@param dpe							Name of data point element to act on
@param alertType	Type of alert on dpe:
													DPCONFIG_ALERT_BINARYSIGNAL if digital alert handling
													DPCONFIG_ALERT_NONBINARYSIGNAL if analog alert handling
													DPCONFIG_SUM_ALERT if summary alert handling
@param alertTexts				Alert texts for each range  
@param alertLimits			The limits of each range given here
@param alertClass				Alert classes for each range 
													One of the items of the dyn_string must always be empty to indicate the valid state.
													Don't forget to add the dot to the alert class names.
@param alertPanel				Panel to call from the alert screen
@param alertPanelParameters		Parameters to pass to panel given in alertPanel
@param alertHelp				Help text or path to help file    
@param alertActive			whether or not this configuration is active
@param discrete  TRUE if discrete
@param impulse  TRUE if impulse
@param discreteNegation  For each limit, if the value must match it, or must not match it (TRUE = must not match it)
@param stateBits  state bits of the alarms
@param stateMatch  for each limit, state bits of the limit
@param exceptionInfo		Details of any exceptions are returned here   
*/
_fwAlertConfig_getDiscrete(string dpe, 
        int &alertType, 
        dyn_string &alertTexts, 
        dyn_float &alertLimits,
        dyn_string &alertClass, 
        string &alertPanel,
				  dyn_string &alertPanelParameters, 
        string &alertHelp, 
        bool &alertActive,         
        bool &discrete,
        bool &impulse,
        dyn_bool &discreteNegation,
        string &stateBits,
        dyn_string &stateMatch, 
        dyn_string &exceptionInfo)
{
  bool digitalOKRange;
  int alertRanges;
  dyn_int limitNumbers;
  string class, dpePattern;
  dyn_string dpeList;
  float dummyFloat;
  int i;
  dyn_string summaryDpeList; 

  //get basic alert info
  _fwAlertConfig_get(dpe, alertType, alertTexts, alertLimits, alertClass, summaryDpeList,
                      alertPanel, alertPanelParameters, alertHelp, alertActive, exceptionInfo);
  //get discrete alert info
   switch(alertType)
   {
     case DPCONFIG_ALERT_BINARYSIGNAL:
    		alertRanges = 2;
     break;
     case DPCONFIG_ALERT_NONBINARYSIGNAL:
    		fwAlertConfig_getLimits(dpe, limitNumbers, alertLimits, exceptionInfo);
//        DebugN("limitNumbers: "+limitNumbers);
    		alertRanges = (dynMax(limitNumbers) + 1);
     break;
     default:
//				fwException_raise(exceptionInfo, "ERROR", "_fwAlertConfig_getDiscrete: Alert config has wrong type on \"" + dpe + "\" so it cannot be retrieved", "");
      return;
     break;
   }		
  for(i=1 ; i<=alertRanges ; i++)
  {
    		dpGet( dpe+":_alert_hdl."+i+"._neg",discreteNegation[i],
              dpe+":_alert_hdl."+i+"._status64_pattern",stateBits,
              dpe+":_alert_hdl."+i+"._match",alertLimits[i],
              dpe+":_alert_hdl."+i+"._status64_match",stateMatch[i]);			
  }
		dpGet( dpe+":_alert_hdl.._discrete_states",discrete,
        dpe+":_alert_hdl.._impulse",impulse);			
    
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

		fwAlertConfig_set(dpe, DPCONFIG_SUM_ALERT, alertTexts, alertLimits, alertClasses,
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
			fwAlertConfig_set(dpe, DPCONFIG_SUM_ALERT, alertTexts, alertLimits, alertClasses,
						dpeList, alertPanel, alertPanelParameters, alertHelp, exceptionInfo, TRUE, FALSE, "", storeInParamHistory);
		}   
		else
		{   
			fwException_raise(exceptionInfo, "ERROR", "fwAlertConfig_deleteDpFromAlertSummary(): "+dpeToDelete+" was not removed from the summary alert", "");
		}   
	}
	else if(errorIfNotPresent && dpeToDelete!= fwAlertConfig_FW_NULL_PATTERN)
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
@param threshold			limit of single alarms to be shown before they are masked (and only the sum alarm is shown).    
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
  values = makeDynMixed(alertTexts[2], alertTexts[1]);

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
     attributesLength++;
     attributes[attributesLength] = dpe + ":_alert_hdl.._dp_list";          
     values[attributesLength] = makeDynString();
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
		tempValue = makeDynMixed(alertPanelParameters);
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

		extraValues = makeDynMixed("", TRUE, FALSE, "", "", "", TRUE, TRUE, TRUE, TRUE, TRUE);

		dynAppend(attributes, extraAttributes);
		dynAppend(values, extraValues);
	}

//DebugN(attributes, values);
}


/**
 * @name Activation functions
   Used to activate, deactivate, acknowledge alarms.
 * @{
*/


/** Acknowledges the alert handling on the given data point element.
This function uses the DPATTR_ACKTYPE_SINGLE to acknowledge the alert.

@ingroup fwConfigsAlert

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

@ingroup fwConfigsAlert

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


/** Activates the alert handling on the given data point element.

@ingroup fwConfigsAlert

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

@ingroup fwConfigsAlert

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

@ingroup fwConfigsAlert

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

@ingroup fwConfigsAlert

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

//@} // end of Activation functions

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

- Example usage:  

      limitNumbers = {3,4,2}
				limitValues = {30,50,10}
				This will set the limit between Range 2 and 3 to 10
				This will set the limit between Range 3 and 4 to 30
				This will set the limit between Range 4 and 5 to 50

- NOTE: Not all the limits need to be specified in the input parameters
- NOTE: Values in limitNumbers must be between 1 and (number of ranges - 1)

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


//@}    



