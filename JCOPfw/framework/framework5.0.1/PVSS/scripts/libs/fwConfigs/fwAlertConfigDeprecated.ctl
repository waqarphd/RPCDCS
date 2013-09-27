/**@file
fwAlertConfigDeprecated.ctl
This library contains deprecated functions associated with the alert handling config.
Functions are provided for backward compatibility and are not being maintained. 

@par Creation Date
	14/09/2011
	
@par Constraints
	<B>Note:</B> Deprecated functions, kept for backward compatibility only. 
	It is recommended to use the new functions in fwAlertConfig.ctl: 
	fwAlertConfig_objectSet(), fwAlertConfig_objectGet(), fwAlertConfig_objectSetMany(), fwAlertConfig_objectGetMany(). 
	See the functions for use examples.
	
@par Usage
	Public

@par PVSS managers
	VISION, CTRL

@author 
	Marco Boccioli. Functions from Oliver Holme (IT-CO) based on original by Herve Milcent, Niko Karlsson based on libMLDBEH_ANLEGEN.ctl
	
	
/** Returns the details of any alert configuration on a given set of dpes.
This function can handle digital, analog and summary alerts

@deprecated
  This function is deprecated. Use fwAlertConfig_objectGetMany() instead.
  
@par Constraints
	Can only get summary alerts of type dp list (not dp pattern)

@par Usage
	Public

@par PVSS managers
	VISION, CTRL
 */
 
 //@{

/** 
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

@deprecated
  This function is deprecated. Use fwAlertConfig_objectGet() instead.
  
@par Constraints
  None
  
@par Usage
	Public

@par PVSS managers
	VISION, CTRL

@param dpe							Name of data point element to read from
@param configExists			Return TRUE if dpe has an alert config, else FALSE
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
	
	if(strpos(dpe, ".") < 0)
		dpe += ".";
        
  _fwAlertConfig_get(dpe, alertConfigType, alertTexts, alertLimits, alertClasses, summaryDpeList,
                      alertPanel, alertPanelParameters, alertHelp, isActive, exceptionInfo);
  
  if(alertConfigType == DPCONFIG_NONE)
    configExists = FALSE;
  else
    configExists = TRUE;
}


/** Returns the details of any alert configuration on a given dpe.
This function can handle digital, analog and summary alerts

@deprecated
  This function is deprecated. Use fwAlertConfig_objectGet() instead.
  
@par Constraints
  None
  
@par Usage
	Public

@par PVSS managers
	VISION, CTRL

@param dpe							input, Name of data point element to read from
@param configExists			Return TRUE if dpe has a summary alert config, else FALSE
@param alertConfigType	Type of alert on dpe:
													DPCONFIG_ALERT_BINARYSIGNAL if digital alert handling
													DPCONFIG_ALERT_NONBINARYSIGNAL if analog alert handling
													DPCONFIG_SUM_ALERT if summary alert handling
@param alertTexts				Alert texts are returned here for all types of alert
@param alertLimits			Alert limits are returned here for analog alerts
@param alertClasses			Alert classes are returned here for digital and analog alertd
@param alertPanel				Panel to call from the alert screen
@param alertPanelParameters		Parameters to pass to the given alertPanel
@param alertHelp				Help text or path to help file    
@param isActive					TRUE if alert is active else FALSE
@param discrete					TRUE if alert is discrete else FALSE
@param impulse					TRUE if alert is impulse alert else FALSE
@param discreteNegation		for each match values, TRUE if the match is negated (i.e. "!=").
@param stateBits					state bits of the discrete alert
@param stateMatch					state bits of each value match
@param exceptionInfo		Details of any exceptions are returned here   
*/
fwAlertConfig_getDiscrete(	string dpe,
					bool &configExists,
					int &alertConfigType,
					dyn_string &alertTexts,
					dyn_float &alertLimits,
					dyn_string &alertClasses,
					string &alertPanel,
					dyn_string &alertPanelParameters,
					string &alertHelp,
					bool &isActive,
        bool &discrete,
        bool &impulse,
        dyn_bool &discreteNegation,
        string &stateBits,
        dyn_string &stateMatch,
					dyn_string &exceptionInfo)
{
	dyn_string summaryDpeList;
	
	if(strpos(dpe, ".") < 0)
		dpe += ".";
   
  _fwAlertConfig_getDiscrete(dpe, alertConfigType, alertTexts, alertLimits, alertClasses, 
                      alertPanel, alertPanelParameters, alertHelp, isActive, discrete, impulse, 
                      discreteNegation, stateBits, stateMatch, exceptionInfo);
  
  if(alertConfigType == DPCONFIG_NONE)
    configExists = FALSE;
  else
    configExists = TRUE;
}


/** Sets the alert configuration on for a list of dpes.
This function can handle digital, analog and summary alerts

@deprecated
  This function is deprecated. Use fwAlertConfig_objectSetMany() instead.
  
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
@param discrete  Optional Parameter - default = FALSE
        If set to TRUE, the alarm is a Discrete alarm.
@param impulse  Optional Parameter - default = FALSE. Used only if discrete=TRUE, otherwise ignored.
        If set to TRUE, and discrete=TRUE, the alarm is discrete and with impulse.
@param discreteNegation  Optional Parameter - default = FALSE. Used only if discrete=TRUE, otherwise ignored.
        If alarm is Discrete, you can specify one value (TRUE or FALSE) per limit. 
        FALSE = the alarm is triggered when the value matches the limit.
        TRUE = the alarm is triggered when the value does not match the limit.
@param stateBits    Optional Parameter - default = "". Used only if discrete=TRUE, otherwise ignored.
        Alarm State Bits. If alarm is Discrete, you can specify a value (i.e. 000010011000) 
@param stateMatch    Optional Parameter - default = "". Used only if discrete=TRUE, otherwise ignored.   
        Value Match State Bit. If alarm is Discrete, you can specify one State Bits value (i.e. 00xxxxx0100110x) per limit. 
        0 = must be 0; 1 = must be 1; x = can be 0 or 1.          
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
					bool storeInParamHistory = TRUE,
       bool discrete = FALSE,
       bool impulse = FALSE,
       dyn_bool discreteNegation = FALSE,
       string stateBits = "",
       dyn_string stateMatch = "" )
{
	int i, length;
	dyn_int diAlertConfigType;
	dyn_string dsAlertPanel, dsAlertHelp, dsStateBits;
	dyn_dyn_float ddfAlertLimits;
	dyn_dyn_string ddsAlertTexts, ddsAlertClasses, ddsSummaryDpeList, ddsAlertPanelParameters, ddsStateMatch;
  dyn_bool dbDiscrete, dbImpulse;
  dyn_dyn_bool ddbDiscreteNegation;

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
   dbDiscrete[i] = discrete;
   dbImpulse[i] = impulse;
   ddbDiscreteNegation[i] = discreteNegation;
   dsStateBits[i] = stateBits;
   ddsStateMatch[i] = stateMatch;
	}

	fwAlertConfig_setMany(dpes, diAlertConfigType, ddsAlertTexts, ddfAlertLimits, ddsAlertClasses, ddsSummaryDpeList,
												dsAlertPanel, ddsAlertPanelParameters, dsAlertHelp, exceptionInfo,
												modifyOnly, fallBackToSet, addDpeInSummary, storeInParamHistory, 
                  dbDiscrete, dbImpulse, ddbDiscreteNegation, dsStateBits, ddsStateMatch);
}


/** Sets the alert configuration on for a list of dpes.
This function can handle digital, analog, discrete and summary alerts

@deprecated
  This function is deprecated. Use fwAlertConfig_objectSetMany() instead.
  
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
@param discrete  Optional Parameter - default = FALSE
        If set to TRUE, the alarm is a Discrete alarm.
@param impulse  Optional Parameter - default = FALSE. Used only if discrete=TRUE, otherwise ignored.
        If set to TRUE, and discrete=TRUE, the alarm is discrete and with impulse.
@param discreteNegation  Optional Parameter - default = FALSE. Used only if discrete=TRUE, otherwise ignored.
        If alarm is Discrete, you can specify one value (TRUE or FALSE) per limit. 
        FALSE = the alarm is triggered when the value matches the limit.
        TRUE = the alarm is triggered when the value does not match the limit.
@param stateBits    Optional Parameter - default = "". Used only if discrete=TRUE, otherwise ignored.
        Alarm State Bits. If alarm is Discrete, you can specify a value (i.e. 000010011000) 
@param stateMatch    Optional Parameter - default = "". Used only if discrete=TRUE, otherwise ignored.   
        Value Match State Bit. If alarm is Discrete, you can specify one State Bits value (i.e. 00xxxxx0100110x) per limit. 
        0 = must be 0; 1 = must be 1; x = can be 0 or 1.                 
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
					bool storeInParamHistory = TRUE,
       dyn_bool discrete = FALSE,
       dyn_bool impulse = FALSE,
       dyn_dyn_bool discreteNegation = FALSE,
       dyn_string stateBits = "",
       dyn_dyn_string stateMatch = "" )
{
	bool relativeSummaryPath;
	int i, j, k, length, ranges, configOptions, numberOfSettings, minimumPriority = 0, threshold;
	dyn_string localException, attributes, tempAttributes, configsToDeactivate, dpesWithAlerts, dpesWithAnalogAlerts, summaryDpes;
	dyn_mixed values, tempValues;
	dyn_int alertHandlingTypes, currentConfigTypes, summaryConfigTypes; 
	dyn_float hysteresisLimits;   
	dyn_int hysteresisType, currentNumberOfRanges, numberOfRanges;    
	dyn_bool includeLimits, alertActive, alertActiveStates, tempAlertActiveStates; 
	dyn_errClass errors;
  
  dyn_bool discreteAlert, impulseAlert;
  dyn_dyn_bool discreteNegationAlert; 
  dyn_dyn_string ddsStateBits;
  dyn_dyn_string ddsStateMatch; 
  string sDpeTypeName;


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
// 		_fwConfigs_getConfigTypeAttribute(dpesWithAlerts, fwConfigs_PVSS_ALERT_HDL, currentNumberOfRanges, exceptionInfo, ".._num_ranges");
		_fwConfigs_getConfigTypeAttribute(dpesWithAnalogAlerts, fwConfigs_PVSS_ALERT_HDL, currentNumberOfRanges, exceptionInfo, ".._num_ranges");
  //the list currentNumberOfRanges contains the results only for dpesWithAnalogAlerts. Insert 0 for the other dpes.
	for(i=1; i<=length; i++)
	{
    if(!dynContains(dpesWithAnalogAlerts,dpes[i]))
      dynInsertAt(currentNumberOfRanges,0,i);
  }  
      discreteAlert = discrete;
      ddsStateMatch = stateMatch;
      ddsStateBits = stateBits;
      discreteNegationAlert = discreteNegation;
      impulseAlert = impulse;

      //check for consistency at discrete alert parameters
      if(dynlen(discrete)==0 || (dynlen(discrete)==1 && discrete[1]==FALSE))
      {
        for(i=1 ; i<=length ; i++)
        {
          discreteAlert[i] = FALSE;
          impulseAlert[i] = FALSE;
          for(j=1 ; j<=(dynlen(alertLimits[i])+1) ; j++)
          {
            discreteNegationAlert[i][j] = FALSE;
            ddsStateBits[i][j]  = "";
            ddsStateMatch[i][j] = "";
          }
        }
      }
      else //correct optional values
      {
        if(ddsStateMatch[1][1]=="" && dynlen(ddsStateMatch[1])==1)
          for(i=1 ; i<=length ; i++)
          {
            for(j=1 ; j<=(dynlen(alertLimits[i])+1) ; j++)
            {
              ddsStateMatch[i][j] = "";
            }
          }
        if(ddsStateBits[1][1]=="" && dynlen(ddsStateBits)==1)
          for(i=1 ; i<=length ; i++)
          {
            for(j=1 ; j<=(dynlen(alertLimits[i])+1) ; j++)
            {
              ddsStateBits[i][j] = "";
            }
          }
        else
          for(i=1 ; i<=length ; i++)
          {
            for(j=1 ; j<=(dynlen(alertLimits[i])+1) ; j++)
            {
              ddsStateBits[i][j] = stateBits[i];
            }
          }          
        if(discreteNegationAlert[1][1]==FALSE && dynlen(discreteNegationAlert[1])==1)
          for(i=1 ; i<=length ; i++)
          {
            for(j=1 ; j<=(dynlen(alertLimits[i])+1) ; j++)
            {
              discreteNegationAlert[i][j] = FALSE;
            }
          }
        if(impulseAlert[1]==0 && dynlen(impulseAlert)==1)
          for(i=1 ; i<=length ; i++)
          {
              impulseAlert[i] = FALSE;
          }
      }

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

  
  ///////////////////////////////////////////////////////////////////////////////////
  //hijacked to the new fwAlertConfig_objectSetMany
  //begin
  dyn_dyn_mixed ddmParamsObject;
  dyn_dyn_mixed ddmParamsGeneral, ddmParamsLimits;
  for(i=1 ; i<=length ; i++)
  {
//     DebugN("=====================================================================================");
//     DebugN("setting object for dpe " + dpes[i]);
//     DebugN("type: " + alertConfigType[i]);
//     DebugN("alertLimits: " + alertLimits[i]);
//     DebugN("alertClasses: " + alertClasses[i]);
//     DebugN("alertTexts: " + alertTexts[i]);
//     DebugN("");
    ranges = dynlen(alertTexts[i]);
    fwAlertConfig_objectInitialize( ddmParamsObject[i],ranges);
    ddmParamsGeneral = ddmParamsObject[i][1];
    ddmParamsLimits = ddmParamsObject[i][2];
    
    if(alertConfigType[i]!=DPCONFIG_SUM_ALERT)
    {
      if(dynlen(alertLimits[i])==(ranges-1))//correct the amount of limits: e.g.: if 2 limits and 3 textes, then set 3 limits, the first being 0.
        dynInsertAt(alertLimits[i],0.0,1);
      if(dynlen(discreteNegationAlert[i])==(ranges-1))//correct the amount of match negations: e.g.: if 2 limits and 3 textes, then set 3 limits, the first being 0.
        dynInsertAt(discreteNegationAlert[i],0.0,1);
      if(dynlen(ddsStateMatch[i])==(ranges-1))//correct the amount of status bits: e.g.: if 2 limits and 3 textes, then set 3 limits, the first being 0.
        dynInsertAt(ddsStateMatch[i],0.0,1);
    }
    	else
    	{
          if(dynlen(alertClasses[i])==(ranges-1) && dynlen(alertClasses[i])>0)//correct the amount of classes: e.g.: if 1 class and 2 textes, then set 2 classes the first being "".
            dynInsertAt(alertClasses[i],0,1);
    	}
    for(j=1 ; j<=ranges ; j++)
    {
      if(dynlen(alertTexts[i]))    
        ddmParamsLimits[j][fwAlertConfig_ALERT_LIMIT_TEXT] = alertTexts[i][j];  
      if(dynlen(alertClasses[i]))    
        ddmParamsLimits[j][fwAlertConfig_ALERT_LIMIT_CLASS] = alertClasses[i][j];
      if(alertConfigType[i]!=DPCONFIG_SUM_ALERT) 
      {
        if(dynlen(alertLimits[i]))  
      		{
      			ddmParamsLimits[j][fwAlertConfig_ALERT_LIMIT_VALUE] = alertLimits[i][j];
      			ddmParamsLimits[j][fwAlertConfig_ALERT_LIMIT_VALUE_MATCH] = alertLimits[i][j];
      		}
        ddmParamsLimits[j][fwAlertConfig_ALERT_LIMIT_VALUE_INCLUDED] = FALSE;//new option not available from this function
        ddmParamsLimits[j][fwAlertConfig_ALERT_LIMIT_NEGATION] = discreteNegationAlert[i][j];
        ddmParamsLimits[j][fwAlertConfig_ALERT_LIMIT_STATE_BITS] = ddsStateBits[i];
        ddmParamsLimits[j][fwAlertConfig_ALERT_LIMIT_LIMITS_STATE_BITS] = ddsStateMatch[i][j];
        ddmParamsLimits[j][fwAlertConfig_ALERT_LIMIT_TEXT_WENT] = "";//new option not available from this function
      }
    }  
    if(dynlen(alertConfigType))    
      ddmParamsGeneral[fwAlertConfig_ALERT_PARAM_TYPE][1] = alertConfigType[i];
    if(dynlen(summaryDpeList))    
      ddmParamsGeneral[fwAlertConfig_ALERT_PARAM_SUM_DPE_LIST] = summaryDpeList[i];
    ddmParamsGeneral[fwAlertConfig_ALERT_PARAM_ADD_DPE_TO_SUMMARY][1] = addDpeInSummary;
    //If Sum alert, threshold is passed as limit
    if(dynlen(alertLimits) == 0)
        threshold = 0;
    else if(dynlen(alertLimits[i]) == 0)
        threshold = 0;
    else
        threshold = alertLimits[i][1];
    ddmParamsGeneral[fwAlertConfig_ALERT_PARAM_SUM_THRESHOLD][1] = threshold;
    ddmParamsGeneral[fwAlertConfig_ALERT_PARAM_PANEL][1] = alertPanel[i];
    ddmParamsGeneral[fwAlertConfig_ALERT_PARAM_PANEL_PARAMETERS] = alertPanelParameters[i];
    ddmParamsGeneral[fwAlertConfig_ALERT_PARAM_HELP][1] = alertHelp[i];
    ddmParamsGeneral[fwAlertConfig_ALERT_PARAM_DISCRETE][1] = discreteAlert[i];
    ddmParamsGeneral[fwAlertConfig_ALERT_PARAM_IMPULSE][1] = impulseAlert[i];
    ddmParamsGeneral[fwAlertConfig_ALERT_PARAM_MODIFY_ONLY][1] = modifyOnly;
    ddmParamsGeneral[fwAlertConfig_ALERT_PARAM_FALLBACK_TO_SET][1] = fallBackToSet;
    ddmParamsGeneral[fwAlertConfig_ALERT_PARAM_STORE_IN_HISTORY][1] = storeInParamHistory;
    ddmParamsGeneral[fwAlertConfig_ALERT_PARAM_RANGES][1] = ranges;  
//     ddmParamsGeneral[fwAlertConfig_ALERT_PARAM_ACTIVE][1] = alertActive[i];
    ddmParamsObject[i][1] = ddmParamsGeneral;
    ddmParamsObject[i][2] = ddmParamsLimits;
  }  

  fwAlertConfig_objectSetMany(dpes,ddmParamsObject, exceptionInfo);
  return;  
  //hijacked to the new fwAlertConfig_objectSetMany
  //end
  //from here below, the code is the old one not using the params object.
  //it is possible to re-activate it by removing all this code between "hijacked"
  ///////////////////////////////////////////////////////////////////////////////////
 
  
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
        if(discreteAlert[i])
        {
           //prepare the alert type as MATCH for discrete alert
           for(j=1; j<=ranges; j++)
          	{
          		alertHandlingTypes[j] = DPDETAIL_RANGETYPE_MATCH;
          	}            
          _fwAlertConfig_prepareAnalogDiscrete(dpes[i], currentConfigTypes[i], numberOfRanges[i],
  										alertHandlingTypes, alertLimits[i], alertTexts[i], alertClasses[i],
  										minimumPriority, alertPanel[i], alertPanelParameters[i], alertHelp[i], 
                 impulseAlert[i], discreteNegationAlert[i], ddsStateBits[i], ddsStateMatch[i],
                 tempAttributes, tempValues, localException, modifyOnly, fallBackToSet);
        }
        else
        {
      			 	_fwAlertConfig_generateExtraAnalogConfig(ranges, alertLimits[i], alertHandlingTypes, hysteresisLimits, hysteresisType, includeLimits, exceptionInfo);
      				_fwAlertConfig_prepareAnalog(dpes[i], currentConfigTypes[i], numberOfRanges[i],
      										alertHandlingTypes, alertLimits[i], alertTexts[i], alertClasses[i],
      										includeLimits, minimumPriority, alertPanel[i], alertPanelParameters[i], alertHelp[i],
      										hysteresisType, hysteresisLimits, tempAttributes, tempValues,
      										localException, modifyOnly, fallBackToSet);
        }
				break;
			case fwConfigs_BINARY_OPTIONS:
				if(alertConfigType[i] != DPCONFIG_ALERT_BINARYSIGNAL && discreteAlert[i] == FALSE)
				{
			  	fwException_raise(exceptionInfo, "ERROR",
			  								"fwAlertConfig_setMany: Only binary alerts are supported by the given data point element: "+dpes[i], "");
					break;
				}
	
				if(dynlen(alertTexts[i]) != 2 ||
					dynlen(alertClasses[i]) != 2)
				{
			  	fwException_raise(exceptionInfo, "ERROR",
			  								"fwAlertConfig_setMany: You must provide 2 alert classes (including the good range) and 2 alert texts for a binary alert", "");
					break;
				}

      if(discreteAlert[i])
      {
        _fwAlertConfig_prepareDigitalDiscrete(dpes[i], currentConfigTypes[i],
    										alertTexts[i], alertClasses[i],
    										minimumPriority, alertPanel[i], alertPanelParameters[i], alertHelp[i], 
                  impulseAlert[i], ddsStateBits[i],
                  tempAttributes, tempValues, localException, modifyOnly, fallBackToSet);
      }
      else
       	_fwAlertConfig_prepareDigital(dpes[i], DPCONFIG_ALERT_NONBINARYSIGNAL, alertTexts[i], alertClasses[i], minimumPriority,
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
// DebugN("Setting...", storeInParamHistory, attributes, values);
// 			if(storeInParamHistory)
// 				dpSetWait(attributes, values);
// 			else
// 				dpSetTimedWait(0, attributes, values);

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

/** Sets the alert configuration on for a list of dpes.
This function can handle discrete analog and discrete digital alerts

@deprecated
  This function is deprecated. Use fwAlertConfig_objectSet() instead.
  
@par Constraints
  This function can handle only discrete alerts

@par Usage
	Public

@par PVSS managers
	VISION, CTRL

@param dpes							List of data point elements
@param alertConfigType	Type of alert to set:
													DPCONFIG_ALERT_BINARYSIGNAL for digital alert handling
													DPCONFIG_ALERT_NONBINARYSIGNAL for analog alert handling
@param alertTexts				Alert texts are passed here for all types of alert
@param alertLimits			Alert limits are passed here for analog alerts (otherwise ignored)
@param alertClasses			Alert classes are passed here for digital and analog alerts  (otherwise ignored)
@param alertPanel				Panel to call from the alert screen
@param alertPanelParameters		Parameters to pass to the given alertPanel
@param alertHelp				Help text or path to help file    
@param exceptionInfo		Details of any exceptions are returned here   
@param modifyOnly				Optional parameter - Default value FALSE.  Set to TRUE to modify alert without setting "type" attributes.
						This is much quicker, but the alert config must already exist, be an analog alert and have the same number of ranges as you want.
@param fallBackToSet			Optional parameter - Default value FALSE.  Used in combination with modifyOnly.
						If modifyOnly = TRUE and fallBackToSet = FALSE, then if the alert config is not compatible an exception is raised. 
						If modifyOnly = TRUE and fallBackToSet = TRUE, then if the alert config is not compatible, modifyOnly is treated as if it was FALSE. 
@param storeInParamHistory		OPTIONAL PARAMETER - default value = TRUE
					You can specify if the change should be stored in the Paramterisation History of PVSS
@param discrete  Optional Parameter - default = FALSE
        If set to TRUE, the alarm is a Discrete alarm.
@param impulse  Optional Parameter - default = FALSE. Used only if discrete=TRUE, otherwise ignored.
        If set to TRUE, and discrete=TRUE, the alarm is discrete and with impulse.
@param discreteNegation  Optional Parameter - default = FALSE. Used only if discrete=TRUE, otherwise ignored.
        If alarm is Discrete, you can specify one value (TRUE or FALSE) per limit. 
        FALSE = the alarm is triggered when the value matches the limit.
        TRUE = the alarm is triggered when the value does not match the limit.
@param stateBits    Optional Parameter - default = "". Used only if discrete=TRUE, otherwise ignored.
        Alarm State Bits. If alarm is Discrete, you can specify one value (i.e. 000010011000) per alarm. 
@param stateMatch    Optional Parameter - default = "". Used only if discrete=TRUE, otherwise ignored.   
        Value Match State Bit. If alarm is Discrete, you can specify one State Bits value (i.e. 00xxxxx0100110x) per limit. 
        0 = must be 0; 1 = must be 1; x = can be 0 or 1.     
*/
fwAlertConfig_setManyDiscrete(dyn_string dpes,
					dyn_int alertConfigType,
					dyn_dyn_string alertTexts,
					dyn_dyn_float alertLimits,
					dyn_dyn_string alertClasses,
					dyn_string alertPanel,
					dyn_dyn_string alertPanelParameters,
					dyn_string alertHelp,
					dyn_string &exceptionInfo,
					bool modifyOnly = FALSE,
					bool fallBackToSet = FALSE,
					bool storeInParamHistory = TRUE,
       dyn_bool discrete = FALSE,
       dyn_bool impulse = FALSE,
       dyn_dyn_bool discreteNegation = FALSE,
       dyn_string stateBits = "",
       dyn_dyn_string stateMatch = "" )
{
	int i, length;
	dyn_int diAlertConfigType;
	dyn_string dsAlertPanel, dsAlertHelp;
	dyn_dyn_float ddfAlertLimits;
	dyn_dyn_string ddsAlertTexts, ddsAlertClasses, ddsSummaryDpeList, ddsAlertPanelParameters;
  
  dyn_dyn_bool ddbDiscreteNegative;
  dyn_bool dbDiscrete, dbImpulse;
  dyn_string dsStateBits;
  dyn_dyn_string ddsStateMatch;
	string addDpeInSummary;
  
  addDpeInSummary = "";
	diAlertConfigType = alertConfigType;
	ddsAlertTexts = alertTexts;
	ddfAlertLimits = alertLimits;
	ddsAlertClasses = alertClasses;
	ddsSummaryDpeList[1] = makeDynString("");
	dsAlertPanel = alertPanel;
	ddsAlertPanelParameters = alertPanelParameters;
	dsAlertHelp = alertHelp;
  
  ddbDiscreteNegative = discreteNegation;
  dbDiscrete = discrete;
  dbImpulse = impulse;
  dsStateBits = stateBits;
  ddsStateMatch = stateMatch;

	fwAlertConfig_setMany(dpes, diAlertConfigType, ddsAlertTexts, ddfAlertLimits,
                  ddsAlertClasses, ddsSummaryDpeList,
												dsAlertPanel, ddsAlertPanelParameters, dsAlertHelp, exceptionInfo,
												modifyOnly, fallBackToSet, addDpeInSummary, storeInParamHistory, 
                  dbDiscrete, dbImpulse, ddbDiscreteNegative, dsStateBits, ddsStateMatch);
}


/** Sets the alert configuration on a given dpe.
This function can handle digital, analog, discrete and summary alerts. 

@deprecated
  This function is deprecated. Use fwAlertConfig_objectSet() instead.
  
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
@param discrete  Optional Parameter - default = FALSE
        If set to TRUE, the alarm is a Discrete alarm.
@param impulse  Optional Parameter - default = FALSE. Used only if discrete=TRUE, otherwise ignored.
        If set to TRUE, and discrete=TRUE, the alarm is discrete and with impulse.
@param discreteNegation  Optional Parameter - default = FALSE. Used only if discrete=TRUE, otherwise ignored.
        If alarm is Discrete, you can specify one value (TRUE or FALSE) per limit. 
        FALSE = the alarm is triggered when the value matches the limit.
        TRUE = the alarm is triggered when the value does not match the limit.
@param stateBits    Optional Parameter - default = "". Used only if discrete=TRUE, otherwise ignored.
        Alarm State Bits. If alarm is Discrete, you can specify one value (i.e. 000010011000) per alarm. 
@param stateMatch    Optional Parameter - default = "". Used only if discrete=TRUE, otherwise ignored.   
        Value Match State Bit. If alarm is Discrete, you can specify one State Bits value (i.e. 00xxxxx0100110x) per limit. 
        0 = must be 0; 1 = must be 1; x = can be 0 or 1.
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
					bool storeInParamHistory = TRUE,
        bool discrete = FALSE,
        bool impulse = FALSE,
        dyn_bool discreteNegation = FALSE,
        string stateBits = "",
        dyn_string stateMatch=""
          )
{
	int i, length;
	dyn_int diAlertConfigType;
	dyn_string dsAlertPanel, dsAlertHelp;
	dyn_dyn_float ddfAlertLimits;
	dyn_dyn_string ddsAlertTexts, ddsAlertClasses, ddsSummaryDpeList, ddsAlertPanelParameters;
  
  dyn_dyn_bool ddbDiscreteNegative;
  dyn_bool dbDiscrete, dbImpulse;
  dyn_string dsStateBits;
  dyn_dyn_string ddsStateMatch;
	
	diAlertConfigType[1] = alertConfigType;
	ddsAlertTexts[1] = alertTexts;
	ddfAlertLimits[1] = alertLimits;
	ddsAlertClasses[1] = alertClasses;
	ddsSummaryDpeList[1] = summaryDpeList;
	dsAlertPanel[1] = alertPanel;
	ddsAlertPanelParameters[1] = alertPanelParameters;
	dsAlertHelp[1] = alertHelp;
  
  ddbDiscreteNegative[1] = discreteNegation;
  dbDiscrete[1] = discrete;
  dbImpulse[1] = impulse;
  dsStateBits[1] = stateBits;
  ddsStateMatch[1] = stateMatch;
	fwAlertConfig_setMany(makeDynString(dpe), diAlertConfigType, ddsAlertTexts, ddfAlertLimits, ddsAlertClasses, ddsSummaryDpeList,
												dsAlertPanel, ddsAlertPanelParameters, dsAlertHelp, exceptionInfo,
												modifyOnly, fallBackToSet, addDpeInSummary, storeInParamHistory, 
                  dbDiscrete, dbImpulse, ddbDiscreteNegative, dsStateBits, ddsStateMatch);
}



/** Sets the discrete alert configuration on a given dpe.
This function can handle discrete digital and discrete analog alerts

@deprecated
  This function is deprecated. Use fwAlertConfig_objectSet() instead.
  
@par Constraints
  This function can handle only discrete alerts

@par Usage
	Public

@par PVSS managers
	VISION, CTRL

@param dpe							Data point element
@param alertConfigType	Type of alert to set:
													DPCONFIG_ALERT_BINARYSIGNAL for digital alert handling
													DPCONFIG_ALERT_NONBINARYSIGNAL for analog alert handling
@param alertTexts				Alert texts are passed here for all types of alert
@param alertLimits			Alert limits are passed here for analog alerts (otherwise ignored)
@param alertClasses			Alert classes are passed here for digital and analog alerts  (otherwise ignored)
@param alertPanel				Panel to call from the alert screen
@param alertPanelParameters		Parameters to pass to the given alertPanel
@param alertHelp				Help text or path to help file    
@param exceptionInfo		Details of any exceptions are returned here   
@param modifyOnly				Optional parameter - Default value FALSE.  Set to TRUE to modify alert without setting "type" attributes.
						This is much quicker, but the alert config must already exist, be an analog alert and have the same number of ranges as you want.
@param fallBackToSet			Optional parameter - Default value FALSE.  Used in combination with modifyOnly.
						If modifyOnly = TRUE and fallBackToSet = FALSE, then if the alert config is not compatible an exception is raised. 
						If modifyOnly = TRUE and fallBackToSet = TRUE, then if the alert config is not compatible, modifyOnly is treated as if it was FALSE. 
@param storeInParamHistory		OPTIONAL PARAMETER - default value = TRUE
					You can specify if the change should be stored in the Paramterisation History of PVSS
@param discrete  Optional Parameter - default = FALSE
        If set to TRUE, the alarm is a Discrete alarm.
@param impulse  Optional Parameter - default = FALSE. Used only if discrete=TRUE, otherwise ignored.
        If set to TRUE, and discrete=TRUE, the alarm is discrete and with impulse.
@param discreteNegation  Optional Parameter - default = FALSE. Used only if discrete=TRUE, otherwise ignored.
        If alarm is Discrete, you can specify one value (TRUE or FALSE) per limit. 
        FALSE = the alarm is triggered when the value matches the limit.
        TRUE = the alarm is triggered when the value does not match the limit.
@param stateBits    Optional Parameter - default = "". Used only if discrete=TRUE, otherwise ignored.
        Alarm State Bits. If alarm is Discrete, you can specify one value (i.e. 000010011000) per alarm. 
@param stateMatch    Optional Parameter - default = "". Used only if discrete=TRUE, otherwise ignored.   
        Value Match State Bit. If alarm is Discrete, you can specify one State Bits value (i.e. 00xxxxx0100110x) per limit. 
        0 = must be 0; 1 = must be 1; x = can be 0 or 1.
*/
fwAlertConfig_setDiscrete(string dpe,
					int alertConfigType,
					dyn_string alertTexts,
					dyn_float alertLimits,
					dyn_string alertClasses,
					string alertPanel,
					dyn_string alertPanelParameters,
					string alertHelp,
					dyn_string &exceptionInfo,
					bool modifyOnly = FALSE,
					bool fallBackToSet = FALSE,
					bool storeInParamHistory = TRUE,
        bool discrete = FALSE,
        bool impulse = FALSE,
        dyn_bool discreteNegation = FALSE,
        string stateBits = "",
        dyn_string stateMatch="")
{
  int i, length;
  dyn_int diAlertConfigType;
  dyn_string dsAlertPanel, dsAlertHelp;
  dyn_dyn_float ddfAlertLimits;
  dyn_dyn_string ddsAlertTexts, ddsAlertClasses, ddsSummaryDpeList, ddsAlertPanelParameters;
  dyn_dyn_bool ddbDiscreteNegative;
  dyn_bool dbDiscrete, dbImpulse;
  dyn_string dsStateBits;
  dyn_dyn_string ddsStateMatch;
  string addDpeInSummary;

  addDpeInSummary = "";
	diAlertConfigType[1] = alertConfigType;
	ddsAlertTexts[1] = alertTexts;
	ddfAlertLimits[1] = alertLimits;
	ddsAlertClasses[1] = alertClasses;
	ddsSummaryDpeList[1] = makeDynString("");
	dsAlertPanel[1] = alertPanel;
	ddsAlertPanelParameters[1] = alertPanelParameters;
	dsAlertHelp[1] = alertHelp;

  ddbDiscreteNegative[1] = discreteNegation;
  dbDiscrete[1] = discrete;
  dbImpulse[1] = impulse;
  dsStateBits[1] = stateBits;
  ddsStateMatch[1] = stateMatch;

	fwAlertConfig_setMany(makeDynString(dpe), diAlertConfigType, ddsAlertTexts, ddfAlertLimits,
                  ddsAlertClasses, ddsSummaryDpeList,
												dsAlertPanel, ddsAlertPanelParameters, dsAlertHelp, exceptionInfo,
												modifyOnly, fallBackToSet, addDpeInSummary, storeInParamHistory, 
                  dbDiscrete, dbImpulse, ddbDiscreteNegative, dsStateBits, ddsStateMatch);
}


  
/**  DEPRECATED - Modifies an existing analog alert handling with 5 ranges on the given data point element.
The function has similar functionality to _fwAlertConfig_createAnalog5 except that the type of alert
handling for the config are not altered.  This avoids problems which occur when altering the type of
the alert config when something is dpConencted to the config.
@deprecated 
	THIS FUNCTION SHOULD NOT BE USED (see constraints below). Use fwAlertConfig_objectSet() instead.

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

/** DECPRECATED
Creates digital alert handling on the given data point element.
The alert texts, alert class of the bad state and the alert and help panels are set.

@deprecated
  This function is deprecated. Use fwAlertConfig_objectSet() instead.
  
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

/** DEPRECATED
Creates analog alert handling on the given data point element without hysteresis.
The alert texts, alert limits, alert classes and the alert and help panels are set.

@deprecated
  This function is deprecated. Use fwAlertConfig_objectSet() instead.
  
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


/** DEPRECATED
Creates summary alert handling on the given data point element.

@deprecated
  This function is deprecated. Use fwAlertConfig_objectSet() instead.
  
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

@deprecated
  This function is deprecated. Use fwAlertConfig_objectSet() instead.
  
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

@deprecated
  This function is deprecated. Use fwAlertConfig_objectSet() instead.
  
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

@deprecated
  This function is deprecated. Use fwAlertConfig_objectSet() instead.
  
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

@deprecated
  This function is deprecated. Use fwAlertConfig_objectSet() instead.
  
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

@deprecated
  This function is deprecated. Use fwAlertConfig_objectSet() instead.
  
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

@deprecated
  This function is deprecated. Use fwAlertConfig_objectSet() instead.
  

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

@deprecated
  This function is deprecated. Use fwAlertConfig_delete() instead.

@par Usage
	DEPRECATED
*/
fwAlertConfig_deleteSummary( string dpe, dyn_string &exceptionInfo)   
{   
	fwAlertConfig_delete(dpe, exceptionInfo);
}      
  
/** DEPRECATED - Function to delete an analog alert

@deprecated
  This function is deprecated. Use fwAlertConfig_delete() instead.
  
For new function see fwAlertConfig_delete

@par Usage
	DEPRECATED
*/
fwAlertConfig_deleteAnalog( string dpe, dyn_string &exceptionInfo)   
{   
	fwAlertConfig_delete(dpe, exceptionInfo);
}

/** DEPRECATED - Function to delete a digital alert

@deprecated
  This function is deprecated. Use fwAlertConfig_delete() instead.

@par Usage
	DEPRECATED
*/
fwAlertConfig_deleteDigital( string dpe, dyn_string &exceptionInfo)   
{   
	fwAlertConfig_delete(dpe, exceptionInfo);
}

/** DEPRECATED - Returns the details of the summary alert configuration on a given dpe.
	This function raises an exception if the summary alert uses a DP pattern as this is not supported by the FW.

NOTE: THIS FUNCTION SHOULD NOT BE CALLED DIRECTLY

@deprecated
  This function is deprecated. Use fwAlertConfig_objectGet() instead.

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



/** Gets the alert limits for the currently configured alert ranges on the given data point element.

@deprecated
  This function is deprecated. Use fwAlertConfig_objectGet() instead.
  
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

- Example usage:  DEPRECATED

      limitNumbers = {3,4,2}
				limitValues = {30,50,10}
				This will set the limit between Range 2 and 3 to 10
				This will set the limit between Range 3 and 4 to 30
				This will set the limit between Range 4 and 5 to 50

- NOTE: Not all the limits need to be specified in the input parameters
- NOTE: Values in limitNumbers must be between 1 and (number of ranges - 1)

@deprecated
  This function is deprecated. Use fwAlertConfig_objectSet() instead.
  
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

//@}    