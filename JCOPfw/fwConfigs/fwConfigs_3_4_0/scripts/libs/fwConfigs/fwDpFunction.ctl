/**@file

This library contains function associated the dp function config.
Functions are provided for getting the current settings, deleting the config
and setting the config.

@par Creation Date
	29/01/2004

@par Modification History

  23/06/2011 Marco Boccioli
  - ENS-3174 (Support for statistical dpFunctions). 
    Added new functions:
      fwDpFunction_objectCreateDpeConnection()
      fwDpFunction_objectCreateStatistical()
      fwDpFunction_objectExtractDpeConnection()
      fwDpFunction_objectExtractStatistical()
      fwDpFunction_objectExtractType()
      fwDpFunction_objectGet()
      fwDpFunction_objectGetMany()
      fwDpFunction_objectInitialize()
      fwDpFunction_objectSet()
      fwDpFunction_objectSetMany()
      fwDpFunction_objectIsDpeConnection()
      fwDpFunction_objectIsStatistical()
      fwDpFunction_objectExtractType()
    Added documentation to new functions.
    Modified internal function signature:
      _fwDpFunction_prepareSet(): added new optional parameters.
    For an example on how to use the new functions, see fwDpFunction_objectSetMany().

@ingroup fwConfigsDpFunctionsDpeConnection
@ingroup fwConfigsDpFunctionsStat

@par Constraints
	Functions are currently designed to work with dp function of type dpe connection and statistical. 
	The statistical functions support a limited set of parameters (see Variables Documentation).

@par Usage
	Public

@par PVSS managers
	VISION, CTRL

@author 
	Geraldine Thomas, Oliver Holme (IT-CO)
*/

/**
 * @name Configuration object indexes
   Used to access the configuration object attributes (object of type dyn_anytype).
 * @{
*/
/**
@ingroup fwConfigsDpFunctions

  @par Description
The function, using the parameters (will be p1 + p2...).
  @par  Parameter Type
string
  @par Usage
Compulsory. For Dpe Connection and Statistical.
See use example on fwDpFunction_OBJ_objectSet().
**/
const int fwDpFunction_OBJ_FUNCTION = 5;

/**
  @ingroup fwConfigsDpFunctions

  @par Description
List of dpes as parameters to be used for the function (will be p1, p2...).
The # of elements must be = to the # of elements in fwDpFunction_OBJ_STAT_TYPE.
  @par Parameter Type
dyn_string
  @par Usage
  @ingroup GlobalVariables
Compulsory. For Dpe Connection and Statistical.
See use example on fwDpFunction_OBJ_objectSet().
**/
const int fwDpFunction_OBJ_PARAM = 6;

/**
  @ingroup fwConfigsDpFunctions

  @par Description
List of dpes as global parameters to be used for the function (will be g1, g2...).
  @par Parameter Type
dyn_string
  @par Usage
Optional. For Dpe Connection and Statistical.
See use example on fwDpFunction_OBJ_objectSet().
**/
const int fwDpFunction_OBJ_GLOBAL = 7;

/**
  @ingroup fwConfigsDpFunctions

  @par Description
Type of function. Can contain the values: DPCONFIG_DP_FUNCTION, DPCONFIG_STAT_FUNCTION.
  @par Parameter Type
int
  @par Usage
Compulsory. For Dpe Connection and Statistical.
See use example on fwDpFunction_OBJ_objectSet().
**/
const int fwDpFunction_OBJ_TYPE = 8;

/**
  @ingroup fwConfigsDpFunctionsStat

  @par Description
Type of stat function (i.e. min, max... see full list on PVSS help, "_dp_fct.._stat_type").
One per  parameter. The # of elements must be = to the # of elements in fwDpFunction_OBJ_PARAM.
  @par Parameter Type
dyn_int
  @par Usage
For Statistical only. Cumpulsory. Default = SF_MIN
See use example on fwDpFunction_OBJ_objectSet().
**/
const int fwDpFunction_OBJ_STAT_TYPE = 9;

/**
  @ingroup fwConfigsDpFunctionsStat

  @par Description
Time interval of stat function, in seconds
  @par Parameter Type
int
  @par Usage
For Statistical only. Cumpulsory. Default = 1
See use example on fwDpFunction_OBJ_objectSet().
**/
const int fwDpFunction_OBJ_STAT_INTERVAL = 10;

/**
  @ingroup fwConfigsDpFunctionsStat

  @par Description
Time delay of stat function, in seconds
  @par Parameter Type
int
  @par Usage
For Statistical only. Optional. Default = 0
See use example on fwDpFunction_OBJ_objectSet().
**/
const int fwDpFunction_OBJ_STAT_DELAY = 11;

/**
  @ingroup fwConfigsDpFunctionsStat

  @par Description
Read values from archive starting the stat function
  @par Parameter Type
bool
  @par Usage
For Statistical only. Optional. Default = false
See use example on fwDpFunction_OBJ_objectSet().
**/
const int fwDpFunction_OBJ_STAT_READ_ARCHIVE = 12;


//@} // end of Configuration object indexes
  
/**
 * @name Utility functions
   Used to access the configuration object attributes (object of type dyn_anytype).
 * @{
*/

/** Gets the current configuration of the dp function on the given dp element.
@deprecated
  This function is deprecated. Use fwDpFunction_objectGet() instead.

@par Constraints
	This function is designed to work only with the dpe connection type of dp function. 
	It does not support the statistical functions of the dp function config.

@par Usage
	Public

@par PVSS managers
	VISION, CTRL
  
@param dpe									The data point element to query
@param configExists					TRUE if dp function config exists, else FALSE
@param functionParams				The list of dp elements used as parameters in the dp function
@param functionGlobals			The list of dp elements used as globals in the dp function
@param functionDefinition		The dp function is returned here (in terms of p's (parameters) and g's (globals))
@param exceptionInfo				Details of any exceptions are returned here
*/
fwDpFunction_getDpeConnection(string dpe, bool &configExists, dyn_string &functionParams, 
								dyn_string &functionGlobals, string &functionDefinition, dyn_string &exceptionInfo)
{
	int configType;
	
	dpGet(dpe + ":_dp_fct.._type", configType);
	
	switch(configType)
	{
		case DPCONFIG_DP_FUNCTION:
			configExists = TRUE;
			dpGet(	dpe + ":_dp_fct.._fct", functionDefinition,
					dpe + ":_dp_fct.._global", functionGlobals,
					dpe + ":_dp_fct.._param", functionParams);
			break;
			
		case DPCONFIG_NONE:
			configExists = FALSE;	
			functionDefinition = "";
			functionGlobals = makeDynString();
			functionParams = makeDynString();
			break;
			
		default:
			configExists = FALSE;	//unsupported dp function type shown as not existing
			functionDefinition = "";
			functionGlobals = makeDynString();
			functionParams = makeDynString();
			fwException_raise(exceptionInfo, "ERROR", "fwDpFunction_getDpeConnection(): DP function type (" + configType + ") not suppported", "");
			break;
	}
}


/** Gets the current configuration of the dp function on the given list of dp elements.
@deprecated
  This function is deprecated. Use fwDpFunction_objectGetMany() instead.

@par Constraints
	This function is designed to work only with the dpe connection type of dp function. 
	It does not support the statistical functions of the dp function config.

@par Usage
	Public

@par PVSS managers
	VISION, CTRL

@param dpes									The list of data point elements to query
@param configExists					TRUE if dp function config exists, else FALSE
@param functionParams				The list of dp elements used as parameters in the dp function
@param functionGlobals			The list of dp elements used as globals in the dp function
@param functionDefinition		The dp function is returned here (in terms of p's (parameters) and g's (globals))
@param exceptionInfo				Details of any exceptions are returned here
*/
fwDpFunction_getDpeConnectionMany(dyn_string dpes, dyn_bool &configExists, dyn_dyn_string &functionParams, 
								dyn_dyn_string &functionGlobals, dyn_string &functionDefinition, dyn_string &exceptionInfo)
{
	int i, length;
	
	length = dynlen(dpes);
	for(i=1; i<=length; i++)
	{
		fwDpFunction_getDpeConnection(dpes[i], configExists[i], functionParams[i], 
																	functionGlobals[i], functionDefinition[i], exceptionInfo);
	}
}


/** Configures the dp function on the given dp elements.
@deprecated
  This function is deprecated. Use fwDpFunction_objectSetMany() instead, 
  passing an array of settings objects containing only one settings object.

@par Constraints
	This function is designed to work only with the dpe connection type of dp function. 
	It does not support the statistical functions of the dp function config.

@par Usage
	Public

@par PVSS managers
	VISION, CTRL

@param dpes									The list of data point elements
@param functionParams				The list of dp elements to be used as parameters in the dp function
@param functionGlobals			The list of dp elements to be used as globals in the dp function
@param functionDefinition		The dp function is given here (in terms of p's (parameters) and g's (globals))
@param exceptionInfo				Details of any exceptions are returned here
@param runChecks						Optional parameter - default TRUE
															TRUE: Run consistency checks on the input to the function (HIGHLY RECOMMENDED)
															FALSE: Do not run any checks at all - can result in badly configured or non configured dp functions.  Use only for performance reasons.
*/
fwDpFunction_setDpeConnectionMultiple(dyn_string dpes, dyn_string functionParams, dyn_string functionGlobals,
										string functionDefinition, dyn_string &exceptionInfo, bool runChecks = TRUE)
{
	int i, length;
	dyn_string dsFunctionDefinitions;
	dyn_dyn_string ddsFunctionParams, ddsFunctionGlobals;
	
	length = dynlen(dpes);
	for(i=1; i<=length; i++)
	{
		ddsFunctionParams[i] = functionParams;
		ddsFunctionGlobals[i] = functionGlobals;
		dsFunctionDefinitions[i] = functionDefinition;
	}
	
	fwDpFunction_setDpeConnectionMany(dpes, ddsFunctionParams, ddsFunctionGlobals, dsFunctionDefinitions, exceptionInfo, runChecks);
}

/** Configures the dp function on the given dp elements.
@deprecated
  This function is deprecated. Use fwDpFunction_objectSetMany() instead.

@par Constraints
	This function is designed to work only with the dpe connection type of dp function. 
	It does not support the statistical functions of the dp function config.

@par Usage
	Public

@par PVSS managers
	VISION, CTRL

@param dpes									The list of data point elements
@param functionParams				The list of dp elements to be used as parameters in the dp function
@param functionGlobals			The list of dp elements to be used as globals in the dp function
@param functionDefinition		The dp function is given here (in terms of p's (parameters) and g's (globals))
@param exceptionInfo				Details of any exceptions are returned here
@param runChecks						Optional parameter - default TRUE
															TRUE: Run consistency checks on the input to the function (HIGHLY RECOMMENDED)
															FALSE: Do not run any checks at all - can result in badly configured or non configured dp functions.  Use only for performance reasons.
*/
fwDpFunction_setDpeConnectionMany(dyn_string dpes, dyn_dyn_string functionParams, dyn_dyn_string functionGlobals,
										dyn_string functionDefinition, dyn_string &exceptionInfo, bool runChecks = TRUE)
{
	int i, length, numberOfSettings;
	dyn_int typeValues;
	dyn_string dpesToSet, attributes, tempAttributes, localException;
	dyn_mixed values, tempValues;
	dyn_errClass errors;
		
	length = dynlen(dpes);
	for(i=1; i<=length; i++)
	{
		_fwDpFunction_prepareSet(dpes[i], functionParams[i], functionGlobals[i], functionDefinition[i], tempAttributes, tempValues, localException, runChecks);
		if(dynlen(localException) > 0)
		{
			dynAppend(exceptionInfo, localException);
			dynClear(localException);
			continue;
		}

		numberOfSettings = dynAppend(attributes, tempAttributes);
		dynAppend(values, tempValues);
//DebugN("Grouping...", numberOfSettings, tempAttributes, tempValues);
				
		if((numberOfSettings > fwConfigs_OPTIMUM_DP_SET_SIZE) || (i == length))
		{
//DebugN("Setting...", attributes, values);
			dpSetWait(attributes, values);
			errors = getLastError(); 
    	if(dynlen(errors) > 0)
   		{ 
	 			throwError(errors);
	 			fwException_raise(exceptionInfo, "ERROR", "fwDpFunction_setDpeConnectionMany: Could not configure some dp function configs", "");
			}
						
			dynClear(attributes);
			dynClear(values);
		}
	}
}


/** Configures the dp function on the given dp element.
@deprecated
  This function is deprecated. Use fwDpFunction_objectSet() instead.

@par Constraints
	This function is designed to work only with the dpe connection type of dp function. 
	It does not support the statistical functions of the dp function config.

@par Usage
	Public

@par PVSS managers
	VISION, CTRL

@param dpe									The data point element
@param functionParams				The list of dp elements to be used as parameters in the dp function
@param functionGlobals			The list of dp elements to be used as globals in the dp function
@param functionDefinition		The dp function is given here (in terms of p's (parameters) and g's (globals))
@param exceptionInfo				Details of any exceptions are returned here
@param runChecks						Optional parameter - default TRUE
															TRUE: Run consistency checks on the input to the function (HIGHLY RECOMMENDED)
															FALSE: Do not run any checks at all - can result in badly configured or non configured dp functions.  Use only for performance reasons.
*/
fwDpFunction_setDpeConnection(string dpe, dyn_string functionParams, dyn_string functionGlobals,
								string functionDefinition, dyn_string &exceptionInfo, bool runChecks = TRUE)
{
	dyn_string dsFunctionDefinitions;
	dyn_dyn_string ddsFunctionParams, ddsFunctionGlobals;

	ddsFunctionParams[1] = functionParams;
	ddsFunctionGlobals[1] = functionGlobals;
	dsFunctionDefinitions[1] = functionDefinition;

	fwDpFunction_setDpeConnectionMany(makeDynString(dpe), ddsFunctionParams, ddsFunctionGlobals, dsFunctionDefinitions, exceptionInfo, runChecks);
}


/** Prepares a list of attributes and a list of values to be used in a dpSetWait() call to set the config for the given dpe.

@par Constraints
	This function is designed to work only with the dpe connection type of dp function. 
	It does not support the statistical functions of the dp function config.

@par Usage
	Internal

@par PVSS managers
	VISION, CTRL

@param dpe									The data point element
@param functionParams				The list of dp elements to be used as parameters in the dp function
@param functionGlobals			The list of dp elements to be used as globals in the dp function
@param functionDefinition		The dp function is given here (in terms of p's (parameters) and g's (globals))
@param attributes						Output - the list of attributes that need to be set is returned here
@param values								Output - the list of values that need to be set is returned here
@param exceptionInfo				Details of any exceptions are returned here
@param runChecks						Optional parameter - default TRUE
															TRUE: Run consistency checks on the input to the function (HIGHLY RECOMMENDED)
															FALSE: Do not run any checks at all - can result in badly configured or non configured dp functions.  Use only for performance reasons.
@param functionType						Type of dp function (DPCONFIG_DP_FUNCTION or DPCONFIG_STAT_FUNCTION). 
@param statTypes						Type of stat function (i.e. min, max... see full list on PVSS help, "_dp_fct.._stat_type"). 
													One per  parameter. The # of elements must be = to the # of elements in fwDpFunction_OBJ_PARAM.
@param intervalS						Time interval of stat function, in seconds
@param delayS							Time delay of stat function, in seconds
@param readArchive				Read values from archive starting the stat function                                
*/
_fwDpFunction_prepareSet(string dpe, dyn_string functionParams, dyn_string functionGlobals,
								string functionDefinition, dyn_string &attributes, dyn_anytype &values, dyn_string &exceptionInfo, bool runChecks = TRUE,
                int functionType=DPCONFIG_DP_FUNCTION, dyn_int statTypes=makeDynInt(), int intervalS=-1, int delayS=-1, bool readArchive=false)
{
	bool isOk;
	int configType, i, length;
	string systemOfDpe, tempSystem;
  int iStatTypeLen;
  	
	dynClear(attributes);
	dynClear(values);
	if(runChecks)
	{
    if(!dpExists(dpe))
		{
			fwException_raise(exceptionInfo, "ERROR", "_fwDpFunction_prepareSet(): Destination dpe does not exist ("+dpe+").", "");
			return;	
		}
    
		systemOfDpe = dpSubStr(dpe, DPSUB_SYS);	

		//check that some parameters have been given
		if(dynlen(functionParams)<1)
		{
			fwException_raise(exceptionInfo, "ERROR", "_fwDpFunction_prepareSet(): At least one parameter must be given in the parameter list.", "");
			return;	
		}
	
		//check that function contains reference to at least one parameter	
		if((strpos(functionDefinition, "p")<0)  && (strpos(functionDefinition, "g")<0))
		{
			fwException_raise(exceptionInfo, "ERROR", "_fwDpFunction_prepareSet(): The function definition must contain at least one parameter or global eg. p1 or g1", "");
			return;	
		}
	
		length = dynlen(functionParams);
		for(i=1; i<=length; i++)
		{
			//check no parameters are duplicated
			if(functionType==DPCONFIG_DP_FUNCTION && length != dynUnique(functionParams))
			{
				fwException_raise(exceptionInfo, "ERROR", "_fwDpFunction_prepareSet(): There are duplicate items in the parameter list.", "");
				return;			
			}

			if(patternMatch("*:*:*", functionParams[i]))
			{
				//if system name specified, check if it matches that of the dpe to set the config to
				tempSystem = dpSubStr(functionParams[i], DPSUB_SYS);
				if(tempSystem != systemOfDpe)
				{
					fwException_raise(exceptionInfo, "ERROR", "_fwDpFunction_prepareSet(): The item in position "+i+" of the parameter list ("+functionParams[i]+") is from a different system to the data point on which the config should be saved ("+dpe+").", "");
					return;			
				}
			}
			else
			{
				//else, add system name of dpe to parameter
        if(dpSubStr(functionParams[i], DPSUB_SYS)=="")
				  functionParams[i] = systemOfDpe + functionParams[i];
			}
							
			if(!dpExists(functionParams[i]))
			{
				fwException_raise(exceptionInfo, "ERROR", "_fwDpFunction_prepareSet(): The item in position "+i+" of the parameter list ("+functionParams[i]+") does not exist on system \"" + systemOfDpe + "\".", "");
				return;			
			}
	
			if((strpos(functionParams[i],"_offline.._")<0)&&(strpos(functionParams[i],"_original.._")<0)&&(strpos(functionParams[i],"_online.._")<0))
			{
				fwException_raise(exceptionInfo, "ERROR", "_fwDpFunction_prepareSet(): All dpe parameters must be attributes of the offline, original or online dp configs", "");
				return;			
			}
			
			if(strpos(functionParams[i],dpe+":")==0)
			{
				fwException_raise(exceptionInfo, "ERROR", "_fwDpFunction_prepareSet(): The list of dpe parameters contains the dpe to which the config is being saved", "");
				return;			
			}
		}
    
    if(functionType==DPCONFIG_STAT_FUNCTION)//extra checks if stat function
    {
      iStatTypeLen = dynlen(statTypes);
    	if(length != iStatTypeLen)
    			fwException_raise(exceptionInfo, "ERROR", "_fwDpFunction_prepareSet(): the length of function params (" + length + ") is different from the length of stat types (" + iStatTypeLen + ")", "");		
    	if(intervalS<1)
    			fwException_raise(exceptionInfo, "ERROR", "_fwDpFunction_prepareSet(): intervalS must be > 0 seconds (it is currently " + intervalS+ " s)", "");		
    	if(delayS<0)
    			fwException_raise(exceptionInfo, "ERROR", "_fwDpFunction_prepareSet(): delayS must be >= 0 seconds (it is currently " + delayS+ " s)", "");		
    	if(dynlen(exceptionInfo))
    		return;
    }  
     	
		length = dynlen(functionGlobals);
		for(i=1; i<=length; i++)
		{
			//check no globals are duplicated
			if(length != dynUnique(functionGlobals))
			{
				fwException_raise(exceptionInfo, "ERROR", "_fwDpFunction_prepareSet(): There are duplicate items in the globals list.", "");
				return;			
			}
	
			if(patternMatch("*:*:*", functionGlobals[i]))
			{
				//if system name specified, check if it matches that of the dpe to set the config to
				tempSystem = dpSubStr(functionGlobals[i], DPSUB_SYS);
				if(tempSystem != systemOfDpe)
				{
					fwException_raise(exceptionInfo, "ERROR", "_fwDpFunction_prepareSet(): The item in position "+i+" of the globals list ("+functionGlobals[i]+") is from a different system to the data point on which the config should be saved ("+dpe+").", "");
					return;			
				}
			}
			else
			{
				//else, add system name of dpe to global
				functionGlobals[i] = systemOfDpe + functionGlobals[i];
			}
			
			if(!dpExists(functionGlobals[i]))
			{
				fwException_raise(exceptionInfo, "ERROR", "_fwDpFunction_prepareSet(): The item in position "+i+" of the globals list does not exist on system \"" + systemOfDpe + "\".", "");
				return;			
			}
	
			if((strpos(functionGlobals[i],"_offline.._")<0)&&(strpos(functionGlobals[i],"_original.._")<0)&&(strpos(functionGlobals[i],"_online.._")<0))
			{
				fwException_raise(exceptionInfo, "ERROR", "_fwDpFunction_prepareSet(): All global dpes must be attributes of the offline, original or online dp configs", "");
				return;			
			}     
		}
	
		_fwDpFunction_checkFunction(functionDefinition, functionParams, functionGlobals, isOk, exceptionInfo);
		if(!isOk)
			return;
	}
	
  if(functionType==DPCONFIG_STAT_FUNCTION)//params if stat function
  {
    attributes = makeDynString(dpe + ":_dp_fct.._type", dpe + ":_dp_fct.._global", dpe + ":_dp_fct.._param", dpe + ":_dp_fct.._fct",
                               dpe + ":_dp_fct.._stat_type", dpe + ":_dp_fct.._interval", dpe + ":_dp_fct.._delay", dpe + ":_dp_fct.._read_archive");
  	values = makeDynAnytype(DPCONFIG_STAT_FUNCTION, functionGlobals, functionParams, functionDefinition,
                            statTypes, intervalS, delayS, readArchive);
  }
  else//params if dp function
  {
  	attributes = makeDynString(dpe + ":_dp_fct.._type", dpe + ":_dp_fct.._global", dpe + ":_dp_fct.._param", dpe + ":_dp_fct.._fct");
  	values = makeDynAnytype(DPCONFIG_DP_FUNCTION, functionGlobals, functionParams, functionDefinition);
  }
}




/** This function is used to check that the given dp function only uses variables and globals that have been defined in the
lists of available parameters and globals that are provided.  
This function is copied from para.ctl - paDpSetDpFct()

@par Constraints
	None

@par Usage
	Internal

@par PVSS managers
	VISION, CTRL

@param function				the dp function to check
@param parameters			the list of available function parameters
@param globals				the list of available function globals
@param isOk						Output - The value is set to TRUE if all the parameters and globals specified in the function are available
																in the parameter and globals lists.  Else the value is set to FALSE.
@param exceptionInfo	details of any errors are returned here
*/
_fwDpFunction_checkFunction(string function, dyn_string parameters, dyn_string globals, bool &isOk, dyn_string &exceptionInfo)
{
	int i, x;
	string s1, functionToTest;
	
	functionToTest = function;
  while (strlen(functionToTest)>0 && strpos(functionToTest,"p")>=0)  
	{  
		functionToTest = substr(functionToTest,strpos(functionToTest,"p")+1,strlen(functionToTest)-strpos(functionToTest,"p")-1);  
		if (functionToTest[0]>="1" && functionToTest[0]<="9")  
		{  
    	i=0; s1="";x=0;  
      while (i<=strlen(functionToTest) && functionToTest[i]>="0" && functionToTest[i]<="9")  
      {  
        s1+=functionToTest[i]; i++;  
      }  
      sscanf(s1,"%d",x);  
      if (x>dynlen(parameters) || x==0)  
      {  
				fwException_raise(exceptionInfo, "ERROR", "_fwDpFunction_checkFunction(): Paramter p"+x+" is not defined in the parameter list.", "");
        isOk = FALSE;
        return;  
      }    
    }  
  }  

	functionToTest = function;
  while (strlen(functionToTest)>0 && strpos(functionToTest,"g")>=0)  
	{  
		functionToTest = substr(functionToTest,strpos(functionToTest,"g")+1,strlen(functionToTest)-strpos(functionToTest,"g")-1);  
		if (functionToTest[0]>="1" && functionToTest[0]<="9")  
		{  
    	i=0; s1="";x=0;  
      while (i<=strlen(functionToTest) && functionToTest[i]>="0" && functionToTest[i]<="9")  
      {  
        s1+=functionToTest[i]; i++;  
      }  
      sscanf(s1,"%d",x);  
      if (x>dynlen(globals) || x==0)  
      {  
				fwException_raise(exceptionInfo, "ERROR", "_fwDpFunction_checkFunction(): Global g"+x+" is not defined in the global list.", "");
        isOk = FALSE;
        return;  
      }    
    }  
  } 
  
  isOk = TRUE; 
}

/** Configures the dp function object with statistical parameters
  See fwDpFunction_objectSet() for an example.
	For more advanced parametrization, see parameters availability on the Variable Documentation 
	for the availability of the options.

@ingroup fwConfigsDpFunctionsStat

@par Constraints
	It supports only basic parameters for statistical functions.

@par Usage
	Public

@par PVSS managers
	VISION, CTRL

@param functionObject				This object will contain the dp function parameters.
@param functionParams				The list of dp elements to be used as parameters in the dp function. 
														The # of elements must be = to the # of elements in fwDpFunction_OBJ_STAT_TYPE.
@param functionGlobals			The list of dp elements to be used as globals in the dp function
@param functionDefinition		The dp function is given here (in terms of p's (parameters) and g's (globals))
@param statTypes						Type of stat function (i.e. min, max... see full list on PVSS help, "_dp_fct.._stat_type"). 
													One per  parameter. The # of elements must be = to the # of elements in fwDpFunction_OBJ_PARAM.
@param intervalS						Time interval of stat function, in seconds
@param delayS							Time delay of stat function, in seconds
@param readArchive				Read values from archive starting the stat function
@param exceptionInfo				Details of any exceptions are returned here
@param runChecks				  Perform some consistency checks. Optional. Default value = true
@see fwDpFunction_objectSet(), fwDpFunction_objectSetMany()
*/
fwDpFunction_objectCreateStatistical(	dyn_mixed &functionObject, 
															dyn_string functionParams, 
															dyn_string functionGlobals,
															string functionDefinition, 
															dyn_int statTypes,
															int intervalS,
															int delayS,
															bool readArchive,
															dyn_string &exceptionInfo,
                              bool runChecks=true)
{
  int iParamsLen, iStatTypeLen;
  dyn_string localExceptionInfo;
	if(dynlen(functionObject)==0)
		fwDpFunction_objectInitialize(functionObject);
		
	//check for consistency
  if(runChecks)
  {
    iParamsLen = dynlen(functionParams);
    iStatTypeLen = dynlen(statTypes);
  	if(iParamsLen != iStatTypeLen)
  			fwException_raise(localExceptionInfo, "ERROR", "fwDpFunction_objectCreateStatistical(): the length of function params (" + iParamsLen + ") is different from the length of stat types (" + iStatTypeLen + ")", "");		
  	if(iParamsLen<1)
  			fwException_raise(localExceptionInfo, "ERROR", "fwDpFunction_objectCreateStatistical(): function params must be provided", "");		
  	if(intervalS<1)
  			fwException_raise(localExceptionInfo, "ERROR", "fwDpFunction_objectCreateStatistical(): intervalS must be > 1 second (it is currently " + intervalS+ " s)", "");		
  	if(delayS<0)
  			fwException_raise(localExceptionInfo, "ERROR", "fwDpFunction_objectCreateStatistical(): delayS must be > 0 seconds (it is currently " + delayS+ " s)", "");		
  	if((strpos(functionDefinition, "p")<0)  && (strpos(functionDefinition, "g")<0))
  			fwException_raise(localExceptionInfo, "ERROR", "fwDpFunction_objectCreateStatistical(): functionDefinition must contain a function (for example, 'p1')", "");		
  	if(dynlen(localExceptionInfo))
    {
      exceptionInfo = localExceptionInfo;
  		return;
    }
	}
	functionObject[fwDpFunction_OBJ_TYPE] = DPCONFIG_STAT_FUNCTION;
	functionObject[fwDpFunction_OBJ_PARAM] = functionParams;
	functionObject[fwDpFunction_OBJ_FUNCTION] = functionDefinition;
	functionObject[fwDpFunction_OBJ_GLOBAL] = functionGlobals;
	functionObject[fwDpFunction_OBJ_STAT_TYPE] = statTypes;
	functionObject[fwDpFunction_OBJ_STAT_INTERVAL] = intervalS;
	functionObject[fwDpFunction_OBJ_STAT_DELAY] = delayS;
	functionObject[fwDpFunction_OBJ_STAT_READ_ARCHIVE] = readArchive;
}

/** Configures the dp function object with dpe connection parameters
  See fwDpFunction_objectSet() for an example.

@ingroup fwConfigsDpFunctionsDpeConnection

@par Constraints
	It supports only dpe function functions (no statistical).

@par Usage
	Public

@par PVSS managers
	VISION, CTRL

@param functionObject				This object will contain the dp function parameters.
@param functionParams				The list of dp elements to be used as parameters in the dp function. 
														The # of elements must be = to the # of elements in fwDpFunction_OBJ_STAT_TYPE.
@param functionGlobals			The list of dp elements to be used as globals in the dp function
@param functionDefinition		The dp function is given here (in terms of p's (parameters) and g's (globals))
@param exceptionInfo				Details of any exceptions are returned here
@param runChecks				  Perform some consistency checks. Optional. Default value = true (recommended)
@see fwDpFunction_objectSet(), fwDpFunction_objectSetMany(), fwDpFunction_objectCreateStatistical()
*/
fwDpFunction_objectCreateDpeConnection(	dyn_mixed &functionObject, 
															dyn_string functionParams, 
															dyn_string functionGlobals,
															string functionDefinition,
															dyn_string &exceptionInfo,
                              bool runChecks=true)
{  
  int iParamsLen;
  
	if(dynlen(functionObject)==0)
		fwDpFunction_objectInitialize(functionObject);
		
	//check for consistency
  if(runChecks)
  {
    iParamsLen = dynlen(functionParams);
  	if(iParamsLen<1)
  			fwException_raise(exceptionInfo, "ERROR", "fwDpFunction_objectCreateDpeConnection(): function params must be provided", "");		
  	if((strpos(functionDefinition, "p")<0)  && (strpos(functionDefinition, "g")<0))
  			fwException_raise(exceptionInfo, "ERROR", "fwDpFunction_objectCreateDpeConnection(): functionDefinition must contain a function (for example, 'p1')", "");		
  	if(dynlen(exceptionInfo))
  		return;
	}
	functionObject[fwDpFunction_OBJ_TYPE] = DPCONFIG_DP_FUNCTION;
	functionObject[fwDpFunction_OBJ_PARAM] = functionParams;
	functionObject[fwDpFunction_OBJ_FUNCTION] = functionDefinition;
	functionObject[fwDpFunction_OBJ_GLOBAL] = functionGlobals;
}

/** Reads the dp function object

@ingroup fwConfigsDpFunctionsStat

@par Constraints
	It supports only basic parameters for statistical functions. 
	For more advanced parametrization, check the list of constants fwDpFunction_OBJ_STAT_* 
	for the availability of the options.

@par Usage
	Public

@par PVSS managers
	VISION, CTRL

@param functionObject				This object will contain the dp function parameters.
@param functionParams				The list of dp elements to be used as parameters in the dp function. 
@param functionGlobals			The list of dp elements to be used as globals in the dp function
@param functionDefinition		The dp function is given here (in terms of p's (parameters) and g's (globals))
@param statTypes						Type of stat function (i.e. min, max... see full list on PVSS help, "_dp_fct.._stat_type"). 
													One per  parameter (contained in functionParams).
@param intervalS						Time interval of stat function, in seconds
@param delayS							Time delay of stat function, in seconds
@param readArchive				Read values from archive starting the stat function
@param exceptionInfo				Details of any exceptions are returned here
*/
fwDpFunction_objectExtractStatistical(	dyn_mixed functionObject, 
															dyn_string &functionParams, 
															dyn_string &functionGlobals,
															string &functionDefinition, 
															dyn_int &statTypes,
															int &intervalS,
															int &delayS,
															bool &readArchive,
															dyn_string &exceptionInfo)
{
	if(dynlen(functionObject)==0)
		fwDpFunction_objectInitialize(functionObject);
		
	if(functionObject[fwDpFunction_OBJ_TYPE] != DPCONFIG_STAT_FUNCTION)
			fwException_raise(exceptionInfo, "WARNING", "fwDpFunction_objectExctractStatistical(): the object does not contain statistical function (type code found: " + functionObject[fwDpFunction_OBJ_TYPE]  + ")", "");
	
	functionParams = functionObject[fwDpFunction_OBJ_PARAM] ;
	functionDefinition = functionObject[fwDpFunction_OBJ_FUNCTION] ;
	functionGlobals = functionObject[fwDpFunction_OBJ_GLOBAL];
	statTypes = functionObject[fwDpFunction_OBJ_STAT_TYPE];
	intervalS = functionObject[fwDpFunction_OBJ_STAT_INTERVAL];
	delayS = functionObject[fwDpFunction_OBJ_STAT_DELAY];
	readArchive = functionObject[fwDpFunction_OBJ_STAT_READ_ARCHIVE];
}


/** Reads the dp function object

@ingroup fwConfigsDpFunctionsDpeConnection

@par Constraints
	It supports only dpe connection functions. 
	For statistical funcitons see fwDpFunction_objectExtractStatistical()

@par Usage
	Public

@par PVSS managers
	VISION, CTRL

@param functionObject				This object will contain the dp function parameters.
@param functionParams				The list of dp elements to be used as parameters in the dp function. 
@param functionGlobals			The list of dp elements to be used as globals in the dp function
@param functionDefinition		The dp function is given here (in terms of p's (parameters) and g's (globals))
@param exceptionInfo				Details of any exceptions are returned here
*/
fwDpFunction_objectExtractDpeConnection(	dyn_mixed functionObject, 
															dyn_string &functionParams, 
															dyn_string &functionGlobals,
															string &functionDefinition,
															dyn_string &exceptionInfo)
{
	if(dynlen(functionObject)==0)
		fwDpFunction_objectInitialize(functionObject);
		
	if(functionObject[fwDpFunction_OBJ_TYPE] != DPCONFIG_DP_FUNCTION)
			fwException_raise(exceptionInfo, "WARNING", "fwDpFunction_objectExctractDpeConnection(): the object does not contain DPE Connection function (type code found: " + functionObject[fwDpFunction_OBJ_TYPE]  + ")", "");
	
	functionParams = functionObject[fwDpFunction_OBJ_PARAM] ;
	functionDefinition = functionObject[fwDpFunction_OBJ_FUNCTION] ;
	functionGlobals = functionObject[fwDpFunction_OBJ_GLOBAL];
}


/** Initialize the dp function object with default parameters. This function is not needed if using the functions
  fwDpFunction_objectCreateStatistical() or fwDpFunction_objectCreateDpeConnection().
	By default, the object is initialized as no dp function.

@ingroup fwConfigsDpFunctions

@par Constraints
	It supports only basic parameters for statistical functions. 

@par Usage
	Public

@par PVSS managers
	VISION, CTRL

@param functionObject				This object will contain the dp function parameters with default values.
*/
fwDpFunction_objectInitialize(dyn_mixed &functionObject)
{
	functionObject[fwDpFunction_OBJ_TYPE] = DPCONFIG_NONE;
	functionObject[fwDpFunction_OBJ_PARAM] = makeDynString("");
	functionObject[fwDpFunction_OBJ_FUNCTION] = "";
	functionObject[fwDpFunction_OBJ_GLOBAL] = makeDynString("");
	functionObject[fwDpFunction_OBJ_STAT_TYPE] = makeDynInt(SF_MIN);
	functionObject[fwDpFunction_OBJ_STAT_INTERVAL] = 1;
	functionObject[fwDpFunction_OBJ_STAT_DELAY] = 0;
	functionObject[fwDpFunction_OBJ_STAT_READ_ARCHIVE] = false;
}

/** Return the type of dp function stored in the dp function object.

@ingroup fwConfigsDpFunctions

@par Constraints
	None 

@par Usage
	Public

@par PVSS managers
	VISION, CTRL

@param functionObject				This object containing the dp function parameters.
@return the type of dp function: DPCONFIG_NONE, DPCONFIG_DP_FUNCTION or DPCONFIG_STAT_FUNCTION
*/
int fwDpFunction_objectExtractType(dyn_mixed functionObject)
{
  int iType;
  if(dynlen(functionObject))
    iType = functionObject[fwDpFunction_OBJ_TYPE];
  else
    iType = DPCONFIG_NONE;
  return iType;
}

/** Check wether the configuration object contains statistical function.

@ingroup fwConfigsDpFunctionsStat

@par Constraints
	None 

@par Usage
	Public

@par PVSS managers
	VISION, CTRL

@param functionObject				This object containing the dp function parameters.
@return true if statistical dp function, false else.
*/
bool fwDpFunction_objectIsStatistical(dyn_mixed functionObject)
{
  int iType;
  if(dynlen(functionObject))
    return (functionObject[fwDpFunction_OBJ_TYPE] == DPCONFIG_STAT_FUNCTION);
  else
    return false;
}


/** Check wether the configuration object contains dpe connection function.

@ingroup fwConfigsDpFunctionsDpeConnection

@par Constraints
	None 

@par Usage
	Public

@par PVSS managers
	VISION, CTRL

@param functionObject				This object containing the dp function parameters.
@return true if dp function is of type dpe connection, false else.
*/
bool fwDpFunction_objectIsDpeConnection(dyn_mixed functionObject)
{
  int iType;
  if(dynlen(functionObject))
    return (functionObject[fwDpFunction_OBJ_TYPE] == DPCONFIG_DP_FUNCTION);
  else
    return false;
}

//@} // end of Utility functions
  
/**
 * @name Set/Get functions
   Used to set/get the dp function settings to/from the dpe. The settings are stored into the settings object.
 * @{
*/
/**
  

/** Deletes the DP function config for the given data point elements

  @ingroup fwConfigsDpFunctions
@par Constraints
	None

@par Usage
	Public

@par PVSS managers
	VISION, CTRL

@param dpes						list of data point elements
@param exceptionInfo	details of any errors are returned here
*/
fwDpFunction_deleteMultiple(dyn_string dpes, dyn_string &exceptionInfo)
{
	_fwConfigs_delete(dpes, fwConfigs_PVSS_DP_FUNCT, exceptionInfo);
}


/** Deletes the DP function config for the given data point elements

  @ingroup fwConfigsDpFunctions
@par Constraints
	None

@par Usage
	Public

@par PVSS managers
	VISION, CTRL

@param dpes						list of data point elements
@param exceptionInfo	details of any errors are returned here
*/
fwDpFunction_deleteMany(dyn_string dpes, dyn_string &exceptionInfo)
{
	_fwConfigs_delete(dpes, fwConfigs_PVSS_DP_FUNCT, exceptionInfo);
}


/** Deletes the DP function config for the given data point element

  @ingroup fwConfigsDpFunctions
@par Constraints
	None

@par Usage
	Public

@par PVSS managers
	VISION, CTRL

@param dpe						data point element
@param exceptionInfo	details of any errors are returned here
*/
fwDpFunction_delete(string dpe, dyn_string &exceptionInfo)
{
	_fwConfigs_delete(makeDynString(dpe), fwConfigs_PVSS_DP_FUNCT, exceptionInfo);
}

/** Set the dp-function object to the dpe

  - example: create a statistical dp function and set it to a dpe
\code
    dyn_string exc;
    string dpe;
    //func object containing one dpfunc set
    dyn_mixed dpFuncObject;
    //dp func parameters
   	dyn_string functionParams;
  	dyn_string functionGlobals;
  	string functionDefinition;
    dyn_int statTypes;
  	int intervalS;
  	int delayS;
  	bool readArchive;

    //dp function setting:
    
    //parameters p1, p2
    dynClear(functionParams);    
    dynAppend(functionParams,"sys1:dp1.val2:_original.._value");
    dynAppend(functionParams,"sys1:dp1.val3:_original.._value");
    
    //global parameters q1, q2
    dynClear(functionGlobals);
    dynAppend(functionGlobals,"sys1:dp1.val4:_original.._value");
    dynAppend(functionGlobals,"sys1:dp1.val5:_original.._value");
    
    //parameter p1 is a Maximum function, parameter p2 is an Average function
    dynClear(statTypes);
    dynAppend(statTypes,SF_MAX);
    dynAppend(statTypes,SF_AVG);
    
    //the function definition using the parameters
    functionDefinition = "p1+p2+q1+q2";
    
    //time interval
    intervalS = 3;
    
    //delay on first start
    delayS = 4;
    
    //start reading from archive
    readArchive = true;

    //create the func object
    fwDpFunction_objectCreateStatistical( dpFuncObject,  
                                          functionParams, 
                                          functionGlobals,
                                          functionDefinition, 
                                          statTypes,
                                          intervalS,
                                          delayS,
                                          readArchive,
                                          exc);
        
    //dpe where to set the dp function
    dpe = "sys1:dp1.val";

    //set the func object to the dpe
    fwDpFunction_objectSet(dpe, dpFuncObject, exc, true);
\endcode

@ingroup fwConfigsDpFunctions

@par Constraints
	The object must be previously created with one of the functions fwDpFunction_objectCreate*
  
@par Usage
	Public

@par PVSS managers
	VISION, CTRL

@param dpe				dpe to be configured with dpFunction.
@param functionObject				This object contains the dp function parameters. 
@param exceptionInfo				Details of any exceptions are returned here
@param runChecks						Optional parameter - default TRUE
															TRUE: Run consistency checks on the input to the function (HIGHLY RECOMMENDED)
															FALSE: Do not run any checks at all - can result in badly configured or non configured dp functions.  Use only for performance reasons.
*/
fwDpFunction_objectSet(	    string dpe, 
														dyn_mixed functionObject, 
														dyn_string &exceptionInfo,
														bool runChecks = TRUE)
{
  dyn_mixed fos;
  fos[1] = functionObject;
  fwDpFunction_objectSetMany(makeDynString(dpe), fos, exceptionInfo, runChecks);
}

/** Set the dp-function object to the dpes
 - example 1: create 2 stat functions, assign them to 2 dpes:
 \code  
    dyn_string exc, dpe;
    //func object containing one dpfunc set
    dyn_mixed dpFuncObject;
    //this contains all the func objects
    dyn_mixed dpFuncObjects;
    //dp func parameters
   	dyn_string functionParams;
  	dyn_string functionGlobals;
  	string functionDefinition;
    dyn_int statTypes;
  	int intervalS;
  	int delayS;
  	bool readArchive;

    //dp function settings for dpe1:
    
    //parameters p1, p2
    dynClear(functionParams);    
    dynAppend(functionParams,"sys1:dp1.val2:_original.._value");
    dynAppend(functionParams,"sys1:dp1.val3:_original.._value");
    
    //global parameters q1, q2
    dynClear(functionGlobals);
    dynAppend(functionGlobals,"sys1:dp1.val4:_original.._value");
    dynAppend(functionGlobals,"sys1:dp1.val5:_original.._value");
    
    //parameter p1 is a Maximum function, parameter p2 is an Average function
    dynClear(statTypes);
    dynAppend(statTypes,SF_MAX);
    dynAppend(statTypes,SF_AVG);
    
    //the function definition using the parameters
    functionDefinition = "p1+p2+q1+q2";
    
    //time interval
    intervalS = 3;
    
    //delay on first start
    delayS = 4;
    
    //start reading from archive
    readArchive = true;

    //create the func object
    fwDpFunction_objectCreateStatistical( dpFuncObject,  
                                          functionParams, 
                                          functionGlobals,
                                          functionDefinition, 
                                          statTypes,
                                          intervalS,
                                          delayS,
                                          readArchive,
                                          exc);
    
    
    //add the func object to the objects array
    dpFuncObjects[1] = dpFuncObject;

    //dp function settings for dpe2:
    
    //clear temp parameters
    dynClear(functionParams);
    dynClear(functionGlobals);
    dynClear(statTypes);
    
    //parameters p1, p2
    dynClear(functionParams);    
    dynAppend(functionParams,"sys1:dp2.float2:_original.._value");
    dynAppend(functionParams,"sys1:dp2.float3:_original.._value");
    
    //global parameters q1, q2
    dynClear(functionGlobals);
    dynAppend(functionGlobals,"sys1:dp2.float4:_original.._value");
    dynAppend(functionGlobals,"sys1:dp2.int1:_original.._value");
    
    //parameter p1 is a Maximum function, parameter p2 is an Average function
    dynClear(statTypes);
    dynAppend(statTypes,SF_MAX);
    dynAppend(statTypes,SF_AVG);
    
    //the function definition using the parameters
    functionDefinition = "p1+p2/(q1-q2)";
    
    //time interval
    intervalS = 3;
    
    //delay on first start
    delayS = 4;
    
    //start reading from archive
    readArchive = true;

    //create the func object
    fwDpFunction_objectCreateStatistical( dpFuncObject,  
                                          functionParams, 
                                          functionGlobals,
                                          functionDefinition, 
                                          statTypes,
                                          intervalS,
                                          delayS,
                                          readArchive,
                                          exc);
    
    //add the second func object to the objects array
    dpFuncObjects[2] = dpFuncObject;    

    //list of dpes where to set the dp function
    dpe = makeDynString("sys1:dp1.val", "sys1:dp2.val");
    
    //set the func object array to the dpe array
    fwDpFunction_objectSetMany(dpe, dpFuncObjects, exc, true);
\endcode  

@ingroup fwConfigsDpFunctions

@par Constraints
	The object must be previously created with one of the functions fwDpFunction_objectCreate*

@par Usage
	Public

@par PVSS managers
	VISION, CTRL

@param dpes				List of dpes to be configured with dpFunction.
@param functionObjects			List of function parameter objects. Each of this object contains the dp function parameters. 
														The list lenght must be the same length as dpes. Nevertheless, if the length is 1 (i.e. only one configuration),
														the same configuration is applied to all the dpes.
@param exceptionInfo				Details of any exceptions are returned here
@param runChecks						Optional parameter - default TRUE
															TRUE: Run consistency checks on the input to the function (HIGHLY RECOMMENDED)
															FALSE: Do not run any checks at all - can result in badly configured or non configured dp functions.  Use only for performance reasons.                                                                
@see fwDpFunction_objectCreateStatistical(), fwDpFunction_objectCreateDpeConnection(), fwDpFunction_objectGetMany(), fwDpFunction_objectSet()                             
*/
fwDpFunction_objectSetMany(	dyn_string dpes, 
														dyn_mixed functionObjects, 
														dyn_string &exceptionInfo,
														bool runChecks = TRUE)
{
  int iParamsLen, iStatTypeLen, iTotObjects;
  dyn_mixed functionObject;
	int i, length, numberOfSettings;
	dyn_int typeValues;
	dyn_string dpesToSet, attributes, tempAttributes, localException;
	dyn_mixed values, tempValues;
	dyn_errClass errors;
		
  length = dynlen(dpes);
  iTotObjects = dynlen(functionObjects);
  if(runChecks)
  {
  	if(iTotObjects<1)
    {
      fwException_raise(exceptionInfo, "ERROR", "fwDpFunction_objectSetMany(): the configuration object is empty.", "");		
      return;
    }
  	if(iTotObjects>1 && iTotObjects != length)
    {
      fwException_raise(exceptionInfo, "ERROR", "fwDpFunction_objectSetMany(): the amount of configuration object ("+iTotObjects+") must be equal to the amount of dpes ("+length+")", "");		
      return;
    }
  }
	for(i=1; i<=length; i++)
	{
    //if the funstion object is only one, apply the same to all the dpes
    functionObject = iTotObjects>1 ?  functionObjects[i] : functionObjects[1];   
    if(runChecks)
    {
    	if(dynlen(functionObject)<fwDpFunction_OBJ_STAT_READ_ARCHIVE)
      {
        fwException_raise(exceptionInfo, "ERROR", "fwDpFunction_objectSetMany(): the configuration of the object number "+i+" is empty", "");		
        return;
      }    
    }
		_fwDpFunction_prepareSet(dpes[i], functionObject[fwDpFunction_OBJ_PARAM], functionObject[fwDpFunction_OBJ_GLOBAL],
                             functionObject[fwDpFunction_OBJ_FUNCTION], tempAttributes, tempValues, localException, runChecks,
                             functionObject[fwDpFunction_OBJ_TYPE],
                             functionObject[fwDpFunction_OBJ_STAT_TYPE], functionObject[fwDpFunction_OBJ_STAT_INTERVAL],
                             functionObject[fwDpFunction_OBJ_STAT_DELAY], functionObject[fwDpFunction_OBJ_STAT_READ_ARCHIVE]);
		if(dynlen(localException) > 0)
		{
			dynAppend(exceptionInfo, localException);
			dynClear(localException);
			continue;
		}

		numberOfSettings = dynAppend(attributes, tempAttributes);
		dynAppend(values, tempValues);
//DebugN("Grouping...", numberOfSettings, tempAttributes, tempValues);
				
		if((numberOfSettings > fwConfigs_OPTIMUM_DP_SET_SIZE) || (i == length))
		{
//DebugN("Setting...", attributes, values);
			dpSetWait(attributes, values);
			errors = getLastError(); 
    	if(dynlen(errors) > 0)
   		{ 
	 			throwError(errors);
	 			fwException_raise(exceptionInfo, "ERROR", "fwDpFunction_objectSetMany: Could not configure some dp function configs", "");
			}						
			dynClear(attributes);
			dynClear(values);
		}
	}  
}

/**Get the dp function settings from a list of dpes

@ingroup fwConfigsDpFunctions
  
@par Constraints
	None

@par Usage
	Public

@par PVSS managers
	VISION, CTRL

@param dpes				List of dpes from which to extract the dpFunction.
@param configExists         True if dp config exists, false if dp config does not exist
@param functionObjects			List of function parameter objects to be returend. 
@param exceptionInfo				Details of any exceptions are returned here
@see fwDpFunction_objectGet()                              
*/
fwDpFunction_objectGetMany(	dyn_string dpes, 
                            dyn_bool &configExists,
														dyn_mixed &functionObjects, 
														dyn_string &exceptionInfo)  
{
  int i, length;
  length = dynlen(dpes);
  for(i=1 ; i<=length ; i++)
  {
    fwDpFunction_objectGet(dpes[i],configExists[i],functionObjects[i],exceptionInfo);
  }
}


/**Get the dp function settings from a single dpe
  - example 1: get a dp statistical function from a dpe and extract the settings:
\code
    dyn_string exc;
    string dpe; 
    dyn_mixed dpFuncObject;
    dyn_string functionParams;
    dyn_string functionGlobals;
    string functionDefinition;
    dyn_int statTypes;
    int intervalS;
    int delayS;
    bool readArchive;
    bool configExists;

    //dpe containing the dp function
    dpe = "sys1:dpe1.val";
    
    //get the dp function, store it to the dp function settings object
    fwDpFunction_objectGet(dpe, configExists, dpFuncObject, exc);

    //extract the statistical function settings, if it exists
    if(fwDpFunction_objectIsStatistical(dpFuncObject))
      fwDpFunction_objectExtractStatistical(dpFuncObject,  
                                            functionParams, 
                                            functionGlobals,
                                            functionDefinition, 
                                            statTypes,
                                            intervalS,
                                            delayS,
                                            readArchive,
                                            exc);
    
    DebugN( "fwDpFunction_objectGet():",
            functionParams, 
            functionGlobals,
            functionDefinition, 
            statTypes,
            intervalS,
            delayS,
            readArchive,
            exc);  
\endcode

  - example 2: get a dpe connection function from a dpe and extract the settings:
\code
    dyn_string exc;
    string dpe; 
    dyn_mixed dpFuncObject;
    dyn_string functionParams;
    dyn_string functionGlobals;
    string functionDefinition;
    bool configExists;

    //dpe containing the dp function
    dpe = "sys1:dpe1.val";
    
    //get the dp function, store it to the dp function settings object
    fwDpFunction_objectGet(dpe, configExists, dpFuncObject, exc);

    //extract the statistical function settings, if it exists
    if(fwDpFunction_objectIsDpeConnection(dpFuncObject))
      fwDpFunction_objectExtractDpeConnection(dpFuncObject,  
                                            functionParams, 
                                            functionGlobals,
                                            functionDefinition, 
                                            exc);
    
    DebugN( "fwDpFunction_objectGet():",
            functionParams, 
            functionGlobals,
            functionDefinition, 
            exc);  
\endcode

@ingroup fwConfigsDpFunctions

@par Constraints
	None

@par Usage
	Public

@par PVSS managers
	VISION, CTRL

@param dpe				dpe from which to extract dpFunction.
@param configExists         True if dp config exists, false if dp config does not exist
@param functionObject			Function parameter object to be returend. 
@param exceptionInfo				Details of any exceptions are returned here
@see fwDpFunction_objectCreateStatistical(), fwDpFunction_objectSet(), fwDpFunction_objectSetMany()              
*/
fwDpFunction_objectGet(	string dpe, 
                            bool &configExists,
														dyn_mixed &functionObject, 
														dyn_string &exceptionInfo)  
{
	int configType;
  dyn_string functionParams;
  dyn_string functionGlobals;
  string functionDefinition;
  dyn_int statTypes;
  int intervalS;
  int delayS;
  bool readArchive;
  
  fwDpFunction_objectInitialize(functionObject);
	dpGet(dpe + ":_dp_fct.._type", configType);
	
	switch(configType)
	{
		case DPCONFIG_STAT_FUNCTION:
			configExists = TRUE;
      dpGet(	dpe + ":_dp_fct.._param", functionParams, 
              dpe + ":_dp_fct.._global", functionGlobals,
              dpe + ":_dp_fct.._fct", functionDefinition,
              dpe + ":_dp_fct.._stat_type", statTypes,
              dpe + ":_dp_fct.._interval", intervalS,
              dpe + ":_dp_fct.._delay", delayS,
              dpe + ":_dp_fct.._read_archive", readArchive);
      functionObject[fwDpFunction_OBJ_TYPE] = configType;
    	functionObject[fwDpFunction_OBJ_PARAM] = functionParams;
    	functionObject[fwDpFunction_OBJ_FUNCTION] = functionDefinition;
    	functionObject[fwDpFunction_OBJ_GLOBAL] = functionGlobals;
    	functionObject[fwDpFunction_OBJ_STAT_TYPE] = statTypes;
    	functionObject[fwDpFunction_OBJ_STAT_INTERVAL] = intervalS;
    	functionObject[fwDpFunction_OBJ_STAT_DELAY] = delayS;
    	functionObject[fwDpFunction_OBJ_STAT_READ_ARCHIVE] = readArchive;
			break;
			
		case DPCONFIG_DP_FUNCTION:
			configExists = TRUE;
      dpGet(	dpe + ":_dp_fct.._param", functionParams, 
              dpe + ":_dp_fct.._global", functionGlobals,
              dpe + ":_dp_fct.._fct", functionDefinition);
      functionObject[fwDpFunction_OBJ_TYPE] = configType;
    	functionObject[fwDpFunction_OBJ_PARAM] = functionParams;
    	functionObject[fwDpFunction_OBJ_FUNCTION] = functionDefinition;
    	functionObject[fwDpFunction_OBJ_GLOBAL] = functionGlobals;
			break;
			
		case DPCONFIG_NONE:
			configExists = FALSE;	
			break;
			
		default:
			configExists = FALSE;	//unsupported dp function type shown as not existing
			fwException_raise(exceptionInfo, "ERROR", "fwDpFunction_getDpeConnection(): DP function type (" + configType + ") not suppported", "");
			break;
	}
}
//@}
