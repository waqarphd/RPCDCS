/**@file

This library contains function associated with the Unit part of the common config.
Functions allows to set, get and delete the unit of a dpe or multiple dpes

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
/** set the Unit of a single data point element

@par Constraints
	None

@par Usage
	Public

@par PVSS managers
	VISION, CTRL

@param dpe						input, data point element to configure
@param sUnit					input, string Unit to set
@param exceptionInfo	output, details of any exceptions are returned here
*/
fwUnit_set(string dpe, string sUnit, dyn_string &exceptionInfo)	
{
	bool error;
	dyn_errClass err;

	error = dpSetUnit(dpe,sUnit);
    
	err = getLastError(); 
    if((dynlen(err) > 0) || error)
 	   fwException_raise(exceptionInfo, "ERROR", "fwUnit_set(): Could not set the unit for dpe '"+dpe+"'.", "");
}

/** Set the same Unit for several dpes

@par Constraints
	None

@par Usage
	Public

@par PVSS managers
	VISION, CTRL

@param dsDpe					input, data point elements to configure
@param sUnit					input, the Unit to set to all dpes
@param exceptionInfo	output, details of any exceptions are returned here
*/
fwUnit_setMultiple(dyn_string dsDpe, string sUnit, dyn_string &exceptionInfo)	
{
	int i, length;
	
	length = dynlen(dsDpe);
	for(i=1; i<=length; i++)
	{
		fwUnit_set(dsDpe[i], sUnit, exceptionInfo);
	}
}

/** Set differing Units for several dpes

@par Constraints
	None

@par Usage
	Public

@par PVSS managers
	VISION, CTRL

@param dsDpe					input, data point elements to configure. Passed as reference only for performance reasons. Not modified.
@param dsUnit					input, list of Units to set to dpes. Passed as reference only for performance reasons. Not modified.
@param exceptionInfo	output, details of any exceptions are returned here
*/
fwUnit_setMany(dyn_string &dsDpe, dyn_string &dsUnit, dyn_string &exceptionInfo)	
{
	int i, length;
	
	length = dynlen(dsDpe);
	for(i=1; i<=length; i++)
	{
		fwUnit_set(dsDpe[i], dsUnit[i], exceptionInfo);
	}
}

/** Get the Unit of the dpe

@par Constraints
	None

@par Usage
	Public

@par PVSS managers
	VISION, CTRL

@param dpe						data point element to configure
@param bUnitExists		TRUE if unit is set, FALSE if no unit is set
@param sUnit					output, return the Unit of the dpe
@param exceptionInfo	output, details of any exceptions are returned here
*/
fwUnit_get(string dpe, bool &bUnitExists, string &sUnit, dyn_string &exceptionInfo)
{
	dyn_errClass err;

	sUnit = dpGetUnit(dpe);
	
	err = getLastError(); 
    if(dynlen(err) > 0)
 	   fwException_raise(exceptionInfo, "ERROR", "fwUnit_get(): Could not get the unit.", "");

	if (sUnit != "")
		bUnitExists = TRUE;
	else
		bUnitExists = FALSE;
}

/** Get the Unit of several dpes

@par Constraints
	None

@par Usage
	Public

@par PVSS managers
	VISION, CTRL

@param dsDpe					input, data point elements to configure Passed as reference only for performance reasons. Not modified.
@param dbUnitExists		Lists of bools indicating if unit is set - TRUE if unit is set, FALSE if no unit is set
@param dsUnit					output, return the current Unit of the dpes
@param exceptionInfo	output, details of any exceptions are returned here
*/
fwUnit_getMany(dyn_string &dsDpe, dyn_bool &dbUnitExists, dyn_string &dsUnit, dyn_string &exceptionInfo)
{
	int i, length;
	
	length = dynlen(dsDpe);
	for(i=1; i<=length; i++)
	{
		fwUnit_get(dsDpe[i], dbUnitExists[i], dsUnit[i], exceptionInfo);
	}
}

/** Delete the Unit of the dpe.  The unit string is reset to ""

@par Constraints
	None

@par Usage
	Public

@par PVSS managers
	VISION, CTRL

@param dpe						data point element to configure
@param exceptionInfo	output, details of any exceptions are returned here
*/
fwUnit_delete(string dpe, dyn_string &exceptionInfo)
{
	bool error;
	dyn_errClass err;

	error = dpSetUnit(dpe, "");
    
	err = getLastError(); 
    if((dynlen(err) > 0) || error)
 	   fwException_raise(exceptionInfo, "ERROR", "fwUnit_delete(): Could not delete the unit.", "");
}

/** Delete the Unit of several dpes.  The unit string is reset to ""

@par Constraints
	None

@par Usage
	Public

@par PVSS managers
	VISION, CTRL

@param dsDpe					input, data point elements to configure
@param exceptionInfo	output, details of any exceptions are returned here
*/
fwUnit_deleteMultiple(dyn_string dsDpe, dyn_string &exceptionInfo)
{
	fwUnit_deleteMany(dsDpe, exceptionInfo);
}

/** Delete the Unit of several dpes.  The unit string is reset to ""

@par Constraints
	None

@par Usage
	Public

@par PVSS managers
	VISION, CTRL

@param dsDpe					input, data point elements to configure
@param exceptionInfo	output, details of any exceptions are returned here
*/
fwUnit_deleteMany(dyn_string dsDpe, dyn_string &exceptionInfo)
{
	int i, length;
	
	length = dynlen(dsDpe);
	for(i=1; i<=length; i++)
	{
		fwUnit_delete(dsDpe[i], exceptionInfo);
	}
}


/** DEPRECATED - function to get the Unit of several dpes

Function is replaced by fwUnit_getMany
*/
fwUnit_getMultiple(dyn_string dsDpe, dyn_bool &dbUnitExists, dyn_string &dsUnit, dyn_string &exceptionInfo)
{
	fwUnit_getMany(dsDpe, dbUnitExists, dsUnit, exceptionInfo);
}