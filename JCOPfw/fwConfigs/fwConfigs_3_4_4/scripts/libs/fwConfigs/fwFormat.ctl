/**@file

This library contains function associated with the Format part of the common config.
Functions allows to set, get and delete the Format of a dpe or multiple dpes

@par Creation Date
	29/01/2004

@par Modification History

  12/08/11 Marco Boccioli
  - @sav{85462}: Functions *_setMany and *_getMany with parameters as reference.
 

@par Constraints
	None

@par Usage
	Public

@par PVSS managers
	VISION, CTRL

@author 
	Geraldine Thomas, Oliver Holme (IT-CO)
*/

//@{
/** set the Format of a single data point element

@par Constraints
	None

@par Usage
	Public

@par PVSS managers
	VISION, CTRL

@param dpe						input, data point element to configure
@param sFormat				input, string Format to set
@param exceptionInfo	output, details of any exceptions are returned here
*/
fwFormat_set(string dpe, string sFormat, dyn_string &exceptionInfo)	
{
	bool error;
	dyn_errClass err;

	error = dpSetFormat(dpe,sFormat);
    
	err = getLastError(); 
    if((dynlen(err) > 0) || error)
 	   fwException_raise(exceptionInfo, "ERROR", "fwFormat_set(): Could not set the format.", "");
}

/** Set the same Format for several dpes

@par Constraints
	None

@par Usage
	Public

@par PVSS managers
	VISION, CTRL

@param dsDpe					input, data point elements to configure
@param sFormat				input, string Format to set
@param exceptionInfo	output, details of any exceptions are returned here
*/
fwFormat_setMultiple(dyn_string dsDpe, string sFormat, dyn_string &exceptionInfo)	
{
	int i, length;
	
	length = dynlen(dsDpe);
	for(i=1; i<=length; i++)
	{
		fwFormat_set(dsDpe[i], sFormat, exceptionInfo);
	}
}

/** Set differing Formats for several dpes

@par Constraints
	None

@par Usage
	Public

@par PVSS managers
	VISION, CTRL

@param dsDpe					input, data point elements to configure. Passed as reference only for performance reasons. Not modified.
@param dsFormat				input, list of Formats to set to dpes. Passed as reference only for performance reasons. Not modified.
@param exceptionInfo	output, details of any exceptions are returned here
*/
fwFormat_setMany(dyn_string &dsDpe, dyn_string &dsFormat, dyn_string &exceptionInfo)	
{
	int i, length;
	
	length = dynlen(dsDpe);
	for(i=1; i<=length; i++)
	{
		fwFormat_set(dsDpe[i], dsFormat[i], exceptionInfo);
	}
}

/** Get the Format of the dpe

@par Constraints
	None

@par Usage
	Public

@par PVSS managers
	VISION, CTRL

@param dpe						data point element to configure
@param bFormatExists	TRUE if format is set, FALSE if no format is set
@param sFormat				output, return the Format of the dpe
@param exceptionInfo	output, details of any exceptions are returned here
*/
fwFormat_get(string dpe, bool &bFormatExists, string &sFormat, dyn_string &exceptionInfo)
{
	dyn_errClass err;

	sFormat = dpGetFormat(dpe);
	
	err = getLastError(); 
    if(dynlen(err) > 0)
 	   fwException_raise(exceptionInfo, "ERROR", "fwFormat_get(): Could not get the format.", "");

	if (sFormat != "")
		bFormatExists = TRUE;
	else
		bFormatExists = FALSE;
}

/** Get the Format of several dpes

@par Constraints
	None

@par Usage
	Public

@par PVSS managers
	VISION, CTRL

@param dsDpe						input, data point elements to configure. Passed as reference only for performance reasons. Not modified.
@param dbFormatExists		Lists of bools indicating if format is set - TRUE if format is set, FALSE if no format is set
@param dsFormat					output, return the current Format of the dpes
@param exceptionInfo		output, details of any exceptions are returned here
*/
fwFormat_getMany(dyn_string &dsDpe, dyn_bool &dbFormatExists, dyn_string &dsFormat, dyn_string &exceptionInfo)
{
	int i, length;
	
	length = dynlen(dsDpe);
	for(i=1; i<=length; i++)
	{
		fwFormat_get(dsDpe[i], dbFormatExists[i], dsFormat[i], exceptionInfo);
	}
}

/** Delete the Format of the dpe.  The format string is reset to ""

@par Constraints
	None

@par Usage
	Public

@par PVSS managers
	VISION, CTRL

@param dpe						data point element to configure
@param exceptionInfo	output, details of any exceptions are returned here
*/
fwFormat_delete(string dpe, dyn_string &exceptionInfo)
{
	bool error;
	dyn_errClass err;

	error = dpSetFormat(dpe, "");
    
	err = getLastError(); 
    if((dynlen(err) > 0) || error)
 	   fwException_raise(exceptionInfo, "ERROR", "fwFormat_delete(): Could not delete the format.", "");
}


/** Delete the Format of several dpes.  The format strings are reset to ""

@par Constraints
	None

@par Usage
	Public

@par PVSS managers
	VISION, CTRL

@param dsDpe					input, data point elements to configure
@param exceptionInfo	output, details of any exceptions are returned here
*/
fwFormat_deleteMultiple(dyn_string dsDpe, dyn_string &exceptionInfo)
{
	fwFormat_deleteMany(dsDpe, exceptionInfo);
}

/** Delete the Format of several dpes.  The format strings are reset to ""

@par Constraints
	None

@par Usage
	Public

@par PVSS managers
	VISION, CTRL

@param dsDpe					input, data point elements to configure
@param exceptionInfo	output, details of any exceptions are returned here
*/
fwFormat_deleteMany(dyn_string dsDpe, dyn_string &exceptionInfo)
{
	int i, length;
	
	length = dynlen(dsDpe);
	for(i=1; i<=length; i++)
	{
		fwFormat_delete(dsDpe[i], exceptionInfo);
	}
}

/** DEPRECATED - function to get the Format of several dpes

Function is replaced by fwFormat_getMany
*/
fwFormat_getMultiple(dyn_string dsDpe, dyn_bool &dbFormatExists, dyn_string &dsFormat, dyn_string &exceptionInfo)
{
	fwFormat_getMany(dsDpe, dbFormatExists, dsFormat, exceptionInfo);
}

