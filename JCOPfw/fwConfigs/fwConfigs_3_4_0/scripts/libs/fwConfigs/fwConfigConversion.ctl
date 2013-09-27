/**@file

Library to manage the Message Conversion and Command Conversion configs of PVSS.

@par Creation Date
	24/04/2002

@par Modification History
	15/01/04	Oliver Holme (IT-CO) Updated library to be consistent with other configs
	
@par Constraints
	Currently there can only be one conversion of each type per dpe (Message/Command). 
	Only Polynomial, Base Curve and Invert conversion types are supported. 
	
@par Usage
	Public

@par PVSS managers
	VISION, CTRL

@author 
	Manuel Gonzalez-Berges, Oliver Holme (IT-CO) from fwMsgConv.ctl by Herve Milcent, Niko Karlsson
*/

//@{
/** Creates a conversion config for the given data point elements. 

@par Constraints
	Currently there can only be one conversion of each type per dpe (Message/Command). 
	Only Polynomial and Base Curve conversion types are supported.
	
@par Usage
	Public

@par PVSS managers
	VISION, CTRL

@param dpes							list of data point elements 
@param configType		DPCONFIG_CONVERSION_RAW_TO_ENG_MAIN = message conversion (raw value => engineering value) \n
				DPCONFIG_CONVERSION_ING_TO_RAW_MAIN = command conversion (engineering value => raw value) \n
@param conversionType	DPDETAIL_CONV_POLY    = polynomial conversion \n
				DPDETAIL_CONV_LIN_INT = base curve conversion \n
				DPDETAIL_CONV_INVERT = invert conversion (for boolean DPEs only) \n
@param order						order of polynomial (polynomial conversion) or
												number of supporting points (base curve conversion)
@param arguments				list of arguments \n
													For polynomials, arguments are the coefficients (number of arguments should equal order + 1) \n
													For base curve, the arguments give the points of the curve eg. {x1, y1, x2, y2}. (number of arguments should equal order * 2) \n
@param exceptionInfo		returns details of any errors
@param runDriverCheck		Optional parameter (default value = FALSE) - TRUE to check if driver is running before setting config, else FALSE  \n
													The necessary driver number must be running in order to successfully create config
*/
fwConfigConversion_setMany(dyn_string dpes, dyn_int configType, dyn_int conversionType, 
					   dyn_int order, dyn_dyn_float arguments, dyn_string &exceptionInfo, bool runDriverCheck = FALSE)
{
	bool areAccessible;
	int i, length, numberOfSettings;
	string errorString;
	dyn_int typeValues, requiredDrivers;
	dyn_string dpesToSet, attributes, tempAttributes, localException;
	dyn_mixed values, tempValues;
	dyn_errClass errors;
		
	_fwConfigs_checkAreConfigsAccessible(dpes, areAccessible, requiredDrivers, exceptionInfo);
	if(!areAccessible)
	{
		_fwConfigs_convertDriverNumbersToErrorMessage(requiredDrivers, errorString, exceptionInfo);
		fwException_raise(exceptionInfo, "ERROR", "To set the conversion config, driver number " + errorString + " must be running.", errorString);
		return;
	}

	length = dynlen(dpes);
	for(i=1; i<=length; i++)
	{
		_fwConfigConversion_prepareSet(dpes[i], configType[i], conversionType[i], order[i], arguments[i], tempAttributes, tempValues, localException);
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
	 			fwException_raise(exceptionInfo, "ERROR", "fwConfigConversion_setMany: Could not configure some conversion configs", "");
			}
						
			dynClear(attributes);
			dynClear(values);
		}
	}
}


/** Creates a conversion config for the given data point elements. 

@par Constraints
	Currently there can only be one conversion of each type per dpe (Message/Command). 
	Only Polynomial and Base Curve conversion types are supported.
	
@par Usage
	Public

@par PVSS managers
	VISION, CTRL

@param dpes							list of data point elements 
@param configType		DPCONFIG_CONVERSION_RAW_TO_ENG_MAIN = message conversion (raw value => engineering value) \n
				DPCONFIG_CONVERSION_ING_TO_RAW_MAIN = command conversion (engineering value => raw value) \n
@param conversionType	DPDETAIL_CONV_POLY    = polynomial conversion \n
				DPDETAIL_CONV_LIN_INT = base curve conversion \n
				DPDETAIL_CONV_INVERT = invert conversion (for boolean DPEs only) \n
@param order						order of polynomial (polynomial conversion) or
												number of supporting points (base curve conversion)
@param arguments				list of arguments \n
													For polynomials, arguments are the coefficients (number of arguments should equal order + 1) \n
													For base curve, the arguments give the points of the curve eg. {x1, y1, x2, y2}. (number of arguments should equal order * 2) \n
@param exceptionInfo		returns details of any errors
@param runDriverCheck		Optional parameter (default value = FALSE) - TRUE to check if driver is running before setting config, else FALSE \n
													The necessary driver number must be running in order to successfully create config
*/
fwConfigConversion_setMultiple(dyn_string dpes, int configType, int conversionType, 
					   int order, dyn_float arguments, dyn_string &exceptionInfo, bool runDriverCheck = FALSE)
{
	int i, length;
	dyn_int diConfigType, diConversionType, diOrder;
	dyn_dyn_float ddfArguments;
	
	length = dynlen(dpes);
	for(i=1; i<=length; i++)
	{
		diConfigType[i] = configType;
		diConversionType[i] = conversionType;
		diOrder[i] = order;
		ddfArguments[i] = arguments;
	}
	
	fwConfigConversion_setMany(dpes, diConfigType, diConversionType, diOrder, ddfArguments, exceptionInfo, runDriverCheck);
}


/** Creates a conversion config for a given data point element. 

@par Constraints
	Currently there can only be one conversion of each type per dpe (Message/Command). 
	Only Polynomial and Base Curve conversion types are supported.

@par Usage
	Public

@par PVSS managers
	VISION, CTRL

@param dpe							data point element 
@param configType		DPCONFIG_CONVERSION_RAW_TO_ENG_MAIN = message conversion (raw value => engineering value) \n
				DPCONFIG_CONVERSION_ING_TO_RAW_MAIN = command conversion (engineering value => raw value) \n
@param conversionType	DPDETAIL_CONV_POLY    = polynomial conversion \n
				DPDETAIL_CONV_LIN_INT = base curve conversion \n
				DPDETAIL_CONV_INVERT = invert conversion (for boolean DPEs only) \n
@param order						order of polynomial (polynomial conversion) or
												number of supporting points (base curve conversion)
@param arguments				list of arguments \n
													For polynomials, arguments are the coefficients (number of arguments should equal order + 1) \n
													For base curve, the arguments give the points of the curve eg. {x1, y1, x2, y2}. (number of arguments should equal order * 2) \n
@param exceptionInfo		returns details of any errors
@param runDriverCheck		Optional parameter (default value = FALSE) - TRUE to check if driver is running before setting config, else FALSE \n
													The necessary driver number must be running in order to successfully create config
*/
fwConfigConversion_set(string dpe, int configType, int conversionType, 
					   int order, dyn_float arguments, dyn_string &exceptionInfo, bool runDriverCheck = FALSE)
{
	dyn_int diConfigType, diConversionType, diOrder;
	dyn_dyn_float ddfArguments;
	
	diConfigType[1] = configType;
	diConversionType[1] = conversionType;
	diOrder[1] = order;
	ddfArguments[1] = arguments;
	
	fwConfigConversion_setMany(makeDynString(dpe), diConfigType, diConversionType, diOrder, ddfArguments, exceptionInfo, runDriverCheck);
}


/** Prepares a list of attributes and a list of values to be used in a dpSetWait() call to set the config for the given dpe. 

@par Constraints
	Currently there can only be one conversion of each type per dpe (Message/Command). 
	Only Polynomial and Base Curve conversion types are supported.

@par Usage
	Internal

@par PVSS managers
	VISION, CTRL

@param dpe							data point element 
@param configType		DPCONFIG_CONVERSION_RAW_TO_ENG_MAIN = message conversion (raw value => engineering value) \n
				DPCONFIG_CONVERSION_ING_TO_RAW_MAIN = command conversion (engineering value => raw value) \n
@param conversionType	DPDETAIL_CONV_POLY    = polynomial conversion \n
				DPDETAIL_CONV_LIN_INT = base curve conversion \n
				DPDETAIL_CONV_INVERT = invert conversion (for boolean DPEs only) \n
@param order						order of polynomial (polynomial conversion) or
												number of supporting points (base curve conversion)
@param arguments				list of arguments \n
													For polynomials, arguments are the coefficients (number of arguments should equal order + 1) \n
													For base curve, the arguments give the points of the curve eg. {x1, y1, x2, y2}. (number of arguments should equal order * 2) \n
@param attributes				Output - the list of attributes that need to be set is returned here
@param values						Output - the list of values that need to be set is returned here
@param exceptionInfo		returns details of any errors
*/
_fwConfigConversion_prepareSet(string dpe, int configType, int conversionType, int order, dyn_float arguments,
													dyn_string &attributes, dyn_anytype &values, dyn_string &exceptionInfo)
{
	string config;

  switch(configType) 
  {    	
    	case DPCONFIG_CONVERSION_RAW_TO_ENG_MAIN:  // message conversion
    		config = ":_msg_conv";
    		break;
    	case DPCONFIG_CONVERSION_ING_TO_RAW_MAIN:  // command conversion
    		config = ":_cmd_conv";
    		break;
    	default:
	    	fwException_raise(exceptionInfo, 
       						  "ERROR", 
       						  "_fwConfigConversion_prepareSet(): Config type is not valid", 
       						  "");
    		return;
  }    

	dynAppend(attributes, dpe + config + ".._type");
	dynAppend(values, configType);
		
	switch(conversionType)
	{
// polynomial conversion
		case DPDETAIL_CONV_POLY:  
  		if (order < 4) arguments[5] = 0.0;
  		if (order < 3) arguments[4] = 0.0;
  		if (order < 2) arguments[3] = 0.0;
  		if (order < 1) arguments[2] = 0.0;

 			if (arguments[1] == 0 && arguments[2] == 0 && arguments[3] == 0 && 
				arguments[4] == 0 && arguments[5] == 0)
 			{     
       		fwException_raise(exceptionInfo, 
       						  "ERROR", 
       						  "fwConfigConversion_set(): All coefficients of the polynomial are zero", 
       						  "");
 				return; 
 			}  			
  			// Set conversion type
			dynAppend(attributes, dpe + config + ".1._type");
			dynAppend(values, DPDETAIL_CONV_POLY);

			// Configure conversion
			dynAppend(attributes, dpe + config + ".1._poly_grade");
			dynAppend(attributes, dpe + config + ".1._poly_a");
			dynAppend(attributes, dpe + config + ".1._poly_b");
			dynAppend(attributes, dpe + config + ".1._poly_c");
			dynAppend(attributes, dpe + config + ".1._poly_d");
			dynAppend(attributes, dpe + config + ".1._poly_e");
			dynAppend(values, order);
			dynAppend(values, arguments[1]);
			dynAppend(values, arguments[2]);
			dynAppend(values, arguments[3]);
			dynAppend(values, arguments[4]);
			dynAppend(values, arguments[5]);

   		break;
// base curve conversion
		case DPDETAIL_CONV_LIN_INT:						
			// Set conversion type
			dynAppend(attributes, dpe + config + ".1._type");
			dynAppend(values, DPDETAIL_CONV_LIN_INT);
						
			while(dynlen(arguments) < 10)
				dynAppend(arguments, 0);
						
			// Configure conversion
			dynAppend(attributes, dpe + config + ".1._linint_num");
			dynAppend(attributes, dpe + config + ".1._linint1_x");
			dynAppend(attributes, dpe + config + ".1._linint1_y");
			dynAppend(attributes, dpe + config + ".1._linint2_x");
			dynAppend(attributes, dpe + config + ".1._linint2_y");
			dynAppend(attributes, dpe + config + ".1._linint3_x");
			dynAppend(attributes, dpe + config + ".1._linint3_y");
			dynAppend(attributes, dpe + config + ".1._linint4_x");
			dynAppend(attributes, dpe + config + ".1._linint4_y");
			dynAppend(attributes, dpe + config + ".1._linint5_x");
			dynAppend(attributes, dpe + config + ".1._linint5_y");
			dynAppend(values, order);
			dynAppend(values, arguments[1]);
			dynAppend(values, arguments[2]);
			dynAppend(values, arguments[3]);
			dynAppend(values, arguments[4]);
			dynAppend(values, arguments[5]);
			dynAppend(values, arguments[6]);
			dynAppend(values, arguments[7]);
			dynAppend(values, arguments[8]);
			dynAppend(values, arguments[9]);
			dynAppend(values, arguments[10]);

			break;			
		case DPDETAIL_CONV_INVERT:
			dynAppend(attributes, dpe + config + ".1._type");
			dynAppend(values, DPDETAIL_CONV_INVERT);
			break;			
		default:
			fwException_raise(exceptionInfo, "ERROR", "fwConfigConversion_set(): Invalid conversion type", "");
			return;
			break;
	}		
}

/** Gets the conversion config of a given data point element. 
The function checks that the relevant driver is running.  If not it returns an exception saying the config could not be read.

@par Constraints
	Currently there can only be one conversion of each type per dpe (Message/Command). 
	Only Polynomial and Base Curve conversion types are supported. 

@par Usage
	Public

@par PVSS managers
	VISION, CTRL

@param dpe							data point element 
@param configExists			returns TRUE if message conversion exists or 
				  		  					FALSE if message conversion does not exist
@param configType		DPCONFIG_CONVERSION_RAW_TO_ENG_MAIN = message conversion (raw value => engineering value) \n
				DPCONFIG_CONVERSION_ING_TO_RAW_MAIN = command conversion (engineering value => raw value) \n
@param conversionType	DPDETAIL_CONV_POLY    = polynomial conversion \n
				DPDETAIL_CONV_LIN_INT = base curve conversion \n
				DPDETAIL_CONV_INVERT = invert conversion (for boolean DPEs only) \n
@param order						returns degree of polynomial (polynomial conversion) or 
													number of supporting points (base curve conversion)
@param arguments				returns the list of arguments \n
													For polynomials, arguments are the coefficients (number of arguments should equal order + 1) \n
													For base curve, the arguments give the points of the curve eg. {x1, y1, x2, y2}. (number of arguments should equal order * 2) \n
@param exceptionInfo		returns details of any errors
*/
fwConfigConversion_get(string dpe, bool &configExists, int configType, int &conversionType, int &order,
					   dyn_float &arguments, dyn_string &exceptionInfo)
{	
	bool isAccessible;
	int checkConfigType;
	string config, errorString;
	dyn_int requiredDrivers;

	configExists = FALSE;
	conversionType = 0;
	order = 0;
	arguments = makeDynFloat();

	_fwConfigs_checkAreConfigsAccessible(makeDynString(dpe), isAccessible, requiredDrivers, exceptionInfo);
	if(!isAccessible)
	{
		_fwConfigs_convertDriverNumbersToErrorMessage(requiredDrivers, errorString, exceptionInfo);
		fwException_raise(exceptionInfo, "ERROR", "To access the conversion config, driver number " + errorString + " must be running.", errorString);
		return;
	}
	
    switch(configType) 
    {    	
    	case DPCONFIG_CONVERSION_RAW_TO_ENG_MAIN:  // message conversion
    		config = ":_msg_conv";
    		break;
    	case DPCONFIG_CONVERSION_ING_TO_RAW_MAIN:  // command conversion
    		config = ":_cmd_conv";
    		break;
    	default:
	    	fwException_raise(exceptionInfo, 
       						  "ERROR", 
       						  "fwConfigConversion_get(): Config type is not valid", 
       						  "");
    		return;
    }    

	// Check if conversion config exists
	dpGet(dpe + config + ".._type", checkConfigType);
	
	switch(checkConfigType) 
    {    	
    	case DPCONFIG_CONVERSION_RAW_TO_ENG_MAIN:  // message conversion
    	case DPCONFIG_CONVERSION_ING_TO_RAW_MAIN:  // command conversion    		
    		dpGet(dpe + config + ".1._type", conversionType);
    		
			switch(conversionType)
			{
				// polynomial conversion
				case DPDETAIL_CONV_POLY: 
					configExists = TRUE;
				
					// Get configuration parameters
					dpGet(dpe + config + ".1._poly_grade", order,
						  dpe + config + ".1._poly_a", arguments[1],
						  dpe + config + ".1._poly_b", arguments[2],
						  dpe + config + ".1._poly_c", arguments[3],
						  dpe + config + ".1._poly_d", arguments[4],
						  dpe + config + ".1._poly_e", arguments[5]);
					break;
		
				// base curve conversion
				case DPDETAIL_CONV_LIN_INT:	
					configExists = TRUE;
				
					// Get configuration parameters
					dpGet(dpe + config + ".1._linint_num", order,
						  dpe + config + ".1._linint1_x", arguments[1],
						  dpe + config + ".1._linint1_y", arguments[2],
						  dpe + config + ".1._linint2_x", arguments[3],
						  dpe + config + ".1._linint2_y", arguments[4],
						  dpe + config + ".1._linint3_x", arguments[5],
						  dpe + config + ".1._linint3_y", arguments[6],
						  dpe + config + ".1._linint4_x", arguments[7],
						  dpe + config + ".1._linint4_y", arguments[8],
						  dpe + config + ".1._linint5_x", arguments[9],
						  dpe + config + ".1._linint5_y", arguments[10]);
					break;
				case DPDETAIL_CONV_INVERT:
					configExists = TRUE;
                                        break;	
                                case DPDETAIL_CONV_NONE:
					configExists = FALSE;
                                        break;	
      				default:  // not supported conversion types will appear as not exisiting, is this ok?			
					fwException_raise(exceptionInfo, 
       						  "ERROR", 
       						  "fwConfigConversion_get(): Conversion type (" + conversionType + ") not supported", 
       						  "");
					break;
			}
    		break;   
    		
       	case DPCONFIG_NONE:  // config does not exist
    		break;
    		
    	default:  // in principle, execution should never arrive here
	    	fwException_raise(exceptionInfo, 
       						  "ERROR", 
       						  "fwConfigConversion_get(): Conversion config type (" + checkConfigType + ") not supported", 
       						  "");
    		break;
    }    
}


/** Gets the conversion config of a given list of data point elements. 
The function checks that the relevant driver is running.  If not it returns an exception saying the config could not be read.

@par Constraints
	Currently there can only be one conversion of each type per dpe (Message/Command). 
	Only Polynomial and Base Curve conversion types are supported. 
	
@par Usage
	Public

@par PVSS managers
	VISION, CTRL

@param dpes							data point elements
@param configExists			returns TRUE if message conversion exists or 
				  		  					FALSE if message conversion does not exist
@param configType		DPCONFIG_CONVERSION_RAW_TO_ENG_MAIN = message conversion (raw value => engineering value) \n
				DPCONFIG_CONVERSION_ING_TO_RAW_MAIN = command conversion (engineering value => raw value) \n
@param conversionType	DPDETAIL_CONV_POLY    = polynomial conversion \n
				DPDETAIL_CONV_LIN_INT = base curve conversion \n
				DPDETAIL_CONV_INVERT = invert conversion (for boolean DPEs only) \n
@param order						returns degree of polynomial (polynomial conversion) or 
													number of supporting points (base curve conversion)
@param arguments				returns the list of arguments \n
													For polynomials, arguments are the coefficients (number of arguments should equal order + 1) \n
													For base curve, the arguments give the points of the curve eg. {x1, y1, x2, y2}. (number of arguments should equal order * 2) \n
@param exceptionInfo		returns details of any errors
*/
fwConfigConversion_getMany(dyn_string dpes, dyn_bool &configExists, int configType, dyn_int &conversionType, dyn_int &order,
					   								dyn_dyn_float &arguments, dyn_string &exceptionInfo)
{
	int i, length;
	
	length = dynlen(dpes);
	for(i=1; i<=length; i++)
	{
		fwConfigConversion_get(dpes[i], configExists[i], configType, conversionType[i], order[i], arguments[i], exceptionInfo);
	}
}


/** Deletes the conversion config for the given data point elements

@par Constraints
	None

@par Usage
	Public

@par PVSS managers
	VISION, CTRL

@param dpes						list of data point elements
@param configType		DPCONFIG_CONVERSION_RAW_TO_ENG_MAIN = message conversion (raw value => engineering value) \n
				DPCONFIG_CONVERSION_ING_TO_RAW_MAIN = command conversion (engineering value => raw value) \n
@param exceptionInfo	details of any errors are returned here
*/
fwConfigConversion_deleteMultiple(dyn_string dpes, int configType, dyn_string &exceptionInfo)
{
	fwConfigConversion_deleteMany(dpes, configType, exceptionInfo);
}


/** Deletes the conversion config for the given data point elements

@par Constraints
	None

@par Usage
	Public

@par PVSS managers
	VISION, CTRL

@param dpes						list of data point elements
@param configType		DPCONFIG_CONVERSION_RAW_TO_ENG_MAIN = message conversion (raw value => engineering value) \n
				DPCONFIG_CONVERSION_ING_TO_RAW_MAIN = command conversion (engineering value => raw value) \n
@param exceptionInfo	details of any errors are returned here
*/
fwConfigConversion_deleteMany(dyn_string dpes, int configType, dyn_string &exceptionInfo)
{
	bool areAccessible;
	string config, errorString;
	dyn_int requiredDrivers;

	_fwConfigs_checkAreConfigsAccessible(dpes, areAccessible, requiredDrivers, exceptionInfo);
	if(!areAccessible)
	{
		_fwConfigs_convertDriverNumbersToErrorMessage(requiredDrivers, errorString, exceptionInfo);
		fwException_raise(exceptionInfo, "ERROR", "To delete the conversion config, driver number " + errorString + " must be running.", errorString);
		return;
	}

	switch(configType) 
	{    	
		case DPCONFIG_CONVERSION_RAW_TO_ENG_MAIN:  // message conversion
			config = fwConfigs_PVSS_MSG_CONV;
			break;
		case DPCONFIG_CONVERSION_ING_TO_RAW_MAIN:  // command conversion
			config = fwConfigs_PVSS_CMD_CONV;
			break;
		default:
			fwException_raise(exceptionInfo, 
      		 						  "ERROR", 
      		 						  "fwConfigConversion_delete(): Config type is not valid", 
       								  "");
			return;
			break;
	}    

	_fwConfigs_delete(dpes, config, exceptionInfo);
}


/** Deletes the conversion config for the given data point element

@par Constraints
	None

@par Usage
	Public

@par PVSS managers
	VISION, CTRL

@param dpe						data point element
@param configType		DPCONFIG_CONVERSION_RAW_TO_ENG_MAIN = message conversion (raw value => engineering value) \n
				DPCONFIG_CONVERSION_ING_TO_RAW_MAIN = command conversion (engineering value => raw value) \n
@param exceptionInfo	details of any errors are returned here
*/
fwConfigConversion_delete(string dpe, int configType, dyn_string &exceptionInfo)
{
	fwConfigConversion_deleteMany(makeDynString(dpe), configType, exceptionInfo);
}


/////////////////////////////////////////////////////////////////////////////////////////
////below this line provided for backward compatibility
/////////////////////////////////////////////////////////////////////////////////////////

/** DEPRECATED - Function to set a message conversion config

For new function see fwConfigConversion_set
*/
fwMsgConv_set(string dpe, int conversionType, int order, dyn_float arguments, dyn_string &exceptionInfo)
{
	fwConfigConversion_set(dpe, DPCONFIG_CONVERSION_RAW_TO_ENG_MAIN, conversionType, 
						   order, arguments, exceptionInfo);
}

/** DEPRECATED - Function to get a message conversion config

For new function see fwConfigConversion_get
*/
fwMsgConv_get(string dpe, bool &doesExist, int &conversionType, int &order, dyn_float &arguments, dyn_string &exceptionInfo)
{	
	fwConfigConversion_get(dpe, doesExist, DPCONFIG_CONVERSION_RAW_TO_ENG_MAIN,
							conversionType, order, arguments, exceptionInfo);
}


/** DEPRECATED - Function to delete a message conversion config

For new function see fwConfigConversion_delete
*/
fwMsgConv_delete(string dpe, dyn_string &exceptionInfo)
{
	fwConfigConversion_delete(dpe, DPCONFIG_CONVERSION_RAW_TO_ENG_MAIN, exceptionInfo);
}
//@}


