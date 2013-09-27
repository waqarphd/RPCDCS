/**@file

This library contains function associated the dp function config.
Functions are provided for getting the current settings, deleting the config
and setting the config

@par Creation Date
	29/01/2004

@par Modification History
	None
	
@par Constraints
	Functions are currently designed to work only with the dpe connection type of dp function. 
	The functions do not support the statistical functions of the dp function config.

@par Usage
	Public

@par PVSS managers
	VISION, CTRL

@author 
	Geraldine Thomas, Oliver Holme (IT-CO)
*/

//@{
/** Gets the current configuration of the dp function on the given dp element.

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
*/
_fwDpFunction_prepareSet(string dpe, dyn_string functionParams, dyn_string functionGlobals,
								string functionDefinition, dyn_string &attributes, dyn_anytype &values, dyn_string &exceptionInfo, bool runChecks = TRUE)
{
	bool isOk;
	int configType, i, length;
	string systemOfDpe, tempSystem;
	
	dynClear(attributes);
	dynClear(values);

	if(runChecks)
	{
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
			if(length != dynUnique(functionParams))
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
					fwException_raise(exceptionInfo, "ERROR", "_fwDpFunction_prepareSet(): The item in position "+i+" of the parameter list is from a different system to the data point on which the config should be saved.", "");
					return;			
				}
			}
			else
			{
				//else, add system name of dpe to parameter
				functionParams[i] = systemOfDpe + functionParams[i];
			}
							
			if(!dpExists(functionParams[i]))
			{
				fwException_raise(exceptionInfo, "ERROR", "_fwDpFunction_prepareSet(): The item in position "+i+" of the parameter list does not exist on system \"" + systemOfDpe + "\".", "");
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
					fwException_raise(exceptionInfo, "ERROR", "_fwDpFunction_prepareSet(): The item in position "+i+" of the globals list is from a different system to the data point on which the config should be saved.", "");
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
	
	attributes = makeDynString(dpe + ":_dp_fct.._type", dpe + ":_dp_fct.._global", dpe + ":_dp_fct.._param", dpe + ":_dp_fct.._fct");
	values = makeDynAnytype(DPCONFIG_DP_FUNCTION, functionGlobals, functionParams, functionDefinition);
}


/** Deletes the DP function config for the given data point elements

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
//@}
