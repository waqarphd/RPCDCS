/**@file

This library contains function associated with the original value config.
Functions allows to set, get and delete the original config of a dpe or multiple dpes

@par Creation Date
	25/11/2005

@par Modification History

  15/10/12 Marco Boccioli
  - @jira{FWCORE-3099}: fwOriginal_set: error "Assignment to this expression impossible". Added temp vars.
 
  12/08/11 Marco Boccioli
  - @sav{85462}: Functions *_setMany and *_getMany with parameters as reference.
 

@par Constraints
	None

@par Usage
	Public

@par PVSS managers
	VISION, CTRL

@author 
	Oliver Holme (IT-CO)
*/

//@{
/** Get the Original config data from many data point elements

@par Constraints
	None

@par Usage
	Public

@par PVSS managers
	VISION, CTRL

@param dpes						input, list of data point elements to read. Passed as reference only for performance reasons. Not modified.
@param values					input, the list of original values for each dpe are returned here
@param infoBits				input, the list of info bits (active, invalid and user bits) for each dpe are returned here
												Use fwOriginal_DPE_OBJECT_BIT_XXX indexes (see fwConfigConstants.ctl) to retrieve data from each dyn_bool
@param exceptionInfo	output, details of any exceptions are returned here
*/
fwOriginal_getMany(dyn_string &dpes, dyn_mixed &values, dyn_dyn_bool &infoBits, dyn_string &exceptionInfo)
{
	int i, numberOfDpes, numberOfReadings;
	dyn_string attributes;
	dyn_dyn_mixed returnValues;

	attributes[fwOriginal_DPE_OBJECT_BIT_ACTIVE] = ".._active";
	attributes[fwOriginal_DPE_OBJECT_BIT_INVALID] = ".._exp_inv";
	attributes[fwOriginal_DPE_OBJECT_BIT_LASTVAL_ARCHIVE] = ".._last_value_storage_off";

        attributes[fwOriginal_DPE_OBJECT_BIT_USER_1] = ".._userbit1";
	attributes[fwOriginal_DPE_OBJECT_BIT_USER_2] = ".._userbit2";
	attributes[fwOriginal_DPE_OBJECT_BIT_USER_3] = ".._userbit3";
	attributes[fwOriginal_DPE_OBJECT_BIT_USER_4] = ".._userbit4";
	attributes[fwOriginal_DPE_OBJECT_BIT_USER_5] = ".._userbit5";
	attributes[fwOriginal_DPE_OBJECT_BIT_USER_6] = ".._userbit6";
	attributes[fwOriginal_DPE_OBJECT_BIT_USER_7] = ".._userbit7";
	attributes[fwOriginal_DPE_OBJECT_BIT_USER_8] = ".._userbit8";
	dynAppend(attributes, ".._value");

	_fwConfigs_getConfigAttributes(dpes, fwConfigs_PVSS_ORIGINAL, attributes, returnValues, exceptionInfo);

	numberOfDpes = dynlen(dpes);
	numberOfReadings = dynlen(returnValues[1]);
	
	for(i=1; i<=numberOfDpes; i++)
	{
		values[i] = returnValues[i][numberOfReadings];
		dynRemove(returnValues[i], numberOfReadings);
	}
		
	infoBits = returnValues;
}


/** Get the Original config data from many data point elements

@par Constraints
	None

@par Usage
	Public

@par PVSS managers
	VISION, CTRL

@param dpe						input, data point element to read
@param value					input, original value for dpe returned here
@param infoBits				input, info bits (active, invalid and user bits) for dpe returned here
												Use fwOriginal_DPE_OBJECT_BIT_XXX indexes (see fwConfigConstants.ctl) to retrieve data from dyn_bool
@param exceptionInfo	output, details of any exceptions are returned here
*/
fwOriginal_get(dyn_string dpe, anytype &value, dyn_mixed &infoBits, dyn_string &exceptionInfo)
{
	dyn_anytype values;
	dyn_dyn_anytype infoBitArray;
	
	fwOriginal_getMany(makeDynString(dpe), values, infoBitArray, exceptionInfo);
	value = values[1];
	infoBits = infoBitArray[1];
}


/** Set the Original config data to many data point elements

@par Constraints
	None

@par Usage
	Public

@par PVSS managers
	VISION, CTRL

@param dpes						input, list of data point elements to write to. Passed as reference only for performance reasons. Not modified.
@param values					input, the list of original values for each dpe are passed here. Passed as reference only for performance reasons. Not modified.
@param infoBits				input, the list of info bits (active, invalid and user bits) for each dpe are passed here
												Use fwOriginal_DPE_OBJECT_BIT_XXX indexes (see fwConfigConstants.ctl) to put data into each dyn_bool
												 Passed as reference only for performance reasons. Not modified.
@param exceptionInfo	output, details of any exceptions are returned here
@param mode						OPTIONAL PARAMETER: default means value, active, invalid and user bits are all written to original config
												Use fwOriginal_SET_XXX constants (see fwConfigConstants.ctl)
												to choose different modes that set only specific parts of the config 
*/
fwOriginal_setMany(dyn_string &dpes, dyn_anytype &values, dyn_dyn_bool &infoBits, dyn_string &exceptionInfo, string mode = "VALUE_VARIABLE_BITS_USER_BITS")
{
	int i, j, startIndex, endIndex, length, numberOfAttributes;
	dyn_bool activeBits;
	dyn_string attributes;
	dyn_anytype tempValues;
	dyn_dyn_anytype valuesToSet;

	length = dynlen(dpes);
	_fwConfigs_getConfigTypeAttribute(dpes, fwConfigs_PVSS_ORIGINAL, activeBits, exceptionInfo, ".._active");
	
	for(i=1; i<=length; i++)
	{
		if(!activeBits[i] && !infoBits[i][fwOriginal_DPE_OBJECT_BIT_ACTIVE])
		{
			fwException_raise(exceptionInfo, "ERROR", "Some original configs are not active.  You must activate them before you can save these settings.", "");
			return;
		}
	}

        if(strpos(mode, fwOriginal_SET_VARIABLE_BITS) >= 0)
	{
		dynAppend(attributes, ".._active");
		dynAppend(attributes, ".._exp_inv");
		dynAppend(attributes, ".._last_value_storage_off");

		for(i=1; i<=length; i++)
		{
		  dynAppend(valuesToSet[i], infoBits[i][fwOriginal_DPE_OBJECT_BIT_ACTIVE]);
		  dynAppend(valuesToSet[i], infoBits[i][fwOriginal_DPE_OBJECT_BIT_INVALID]);
		  dynAppend(valuesToSet[i], infoBits[i][fwOriginal_DPE_OBJECT_BIT_LASTVAL_ARCHIVE]);
                }
	}
	
	if(strpos(mode, fwOriginal_SET_USER_BITS) >= 0)
	{
		dynAppend(attributes, ".._userbit1");
		dynAppend(attributes, ".._userbit2");
		dynAppend(attributes, ".._userbit3");
		dynAppend(attributes, ".._userbit4");
		dynAppend(attributes, ".._userbit5");
		dynAppend(attributes, ".._userbit6");
		dynAppend(attributes, ".._userbit7");
		dynAppend(attributes, ".._userbit8");

		for(i=1; i<=length; i++)
		{
			for(j=fwOriginal_DPE_OBJECT_BIT_USER_1; j<=fwOriginal_DPE_OBJECT_BIT_USER_8; j++)
				dynAppend(valuesToSet[i], infoBits[i][j]);
		}
	}

	if(strpos(mode, fwOriginal_SET_VALUE) >= 0)
	{
		dynAppend(attributes, ".._value");
		for(i=1; i<=length; i++)
		{
			if(dynlen(valuesToSet) < i)
				numberOfAttributes = 0;
			else
				numberOfAttributes = dynlen(valuesToSet[i]);
			valuesToSet[i][numberOfAttributes+1] = values[i];
		}
	}		

//DebugN(attributes, valuesToSet);
	_fwConfigs_setConfigAttributes(dpes, fwConfigs_PVSS_ORIGINAL, attributes, valuesToSet, exceptionInfo);
}


/** Set the Original config data to a data point element

@par Constraints
	None

@par Usage
	Public

@par PVSS managers
	VISION, CTRL

@param dpe						input, data point element to write to
@param value					input, the original value to be set to dpe is passed here
@param infoBits				input, the info bits (active, invalid and user bits) to be set to dpe are passed here
												Use fwOriginal_DPE_OBJECT_BIT_XXX indexes (see fwConfigConstants.ctl) to put data into each dyn_bool
@param exceptionInfo	output, details of any exceptions are returned here
@param mode						OPTIONAL PARAMETER: default means value, active, invalid and user bits are all written to original config
												Use fwOriginal_SET_XXX constants (see fwConfigConstants.ctl)
												to choose different modes that set only specific parts of the config 
*/
fwOriginal_set(dyn_string dpe, anytype value, dyn_bool infoBits, dyn_string &exceptionInfo, string mode = "VALUE_VARIABLE_BITS_USER_BITS")
{
	dyn_dyn_bool infoBitArray;
	dyn_string dpes = makeDynString(dpe);
	dyn_anytype values = makeDynAnytype(value);	
	
	infoBitArray[1] = infoBits;
	fwOriginal_setMany(dpes, values, infoBitArray, exceptionInfo, mode);
}


/** Set the same Original config data to many data point elements

@par Constraints
	None

@par Usage
	Public

@par PVSS managers
	VISION, CTRL

@param dpes						input, list of data point elements to write to
@param value					input, the original value to be set to every dpe is passed here
@param infoBits				input, the info bits (active, invalid and user bits) to be set to every dpe are passed here
												Use fwOriginal_DPE_OBJECT_BIT_XXX indexes (see fwConfigConstants.ctl) to put data into each dyn_bool
@param exceptionInfo	output, details of any exceptions are returned here
@param mode						OPTIONAL PARAMETER: default means value, active, invalid and user bits are all written to original config
												Use fwOriginal_SET_XXX constants (see fwConfigConstants.ctl)
												to choose different modes that set only specific parts of the config 
*/
fwOriginal_setMultiple(dyn_string dpes, anytype value, dyn_bool infoBits, dyn_string &exceptionInfo, string mode = "VALUE_VARIABLE_BITS_USER_BITS")
{
	int i, length;
	dyn_anytype values;
	dyn_dyn_bool infoBitArray;
	
	length = dynlen(dpes);	
	for(i=1; i<=length; i++)
	{
		values[i] = value;
		infoBitArray[i] = infoBits;
	}

	fwOriginal_setMany(dpes, values, infoBitArray, exceptionInfo, mode);
}
//@}
