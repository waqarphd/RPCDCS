/**@file

This library is used to convert the given states of a device into the colour which represents this state.
Funcitons are also available for dpConnecting the colour of graphical elements to a device state.

@par Creation Date
	23/01/01

@author 
	Herve Milcent (IT-CO) origin: COMPASS: Oliver Holme (IT-CO)
*/

//@{

/**This function controls the background colour of the cell of a table from within which the function was called.
	The colour is controlled by dpConnecting to the invalid bit of the given data point element, and if it exists,
	the alert active bit and the alert colour are also connected to.
	When the function is called, and any time when the alert state or invalid state changes, a function is called
	which evaluates the current state, selects the relevant colour and sets the background colour of the graphical item.

@par Modification History
	29/03/01 Oliver Holme 	Added functionality for connecting to dpes of type STRUCTURE
							This makes it possible to connect to the state of a summary alert

@par Usage
	Public

@par PVSS managers
	VISION

@param exceptionInfo details of any exceptions are placed in here
*/
fwColourTable_connectCellBackColToStatus(dyn_string &exceptionInfo)
{
	int configType, len, cellPos, i, iResType;
	string dpe;

	len = dynlen(gListOfDpElementToConnect);

	for(i = 1; i <= len; i++) 
	{
		if(!dpExists(gListOfDpElementToConnect[i]))
		{
			fwException_raise(	exceptionInfo, 
								"ERROR",
								"fwColourTable_connectCellBackColToStatus(): The data point element\n\"" + gListOfDpElementToConnect[i] + "\" does not exist",
								"");
			this.cellBackColRC(i - 1, "status", "DpDoesNotExist");
//DebugN("DpDoesNotExist", gListOfDpElementToConnect[i]);
		}
		else
		{
			dpe = gListOfDpElementToConnect[i];

			iResType = dpGet(dpe + ":_alert_hdl.._type", configType);   
			
			switch(configType)
			{
				case DPCONFIG_SUM_ALERT:
					if(dpConnect(	"_fwColourTable_calculateColourWithSummaryAlertCB",
									dpe + ":_alert_hdl.._act_state_color", 
									dpe + ":_alert_hdl.._active") == -1) 
  					{
  						fwException_raise(	exceptionInfo, 
  											"INFO", 
  											"fwColourTable_connectCellBackColToStatus(): Connecting to the status of the data point element\n\"" + dpe + "\" was unsuccessful", 
  											"");
						this.cellBackColRC(i - 1, "status", "DpDoesNotExist");
  					}
  					break;
  				case DPCONFIG_NONE:
  					//DebugN("no alert", gListOfDpElementToConnect[i]);
  					if(dpElementType(dpe) == DPEL_STRUCT)
					{
						//show OK state if dpe has no online value (ie. dpe is of type structure)
						_fwColourTable_calculateColourWithoutAlertCB(dpe, 0);
					}
					else
					{
	   					if(dpConnect(	"_fwColourTable_calculateColourWithoutAlertCB",
	 									dpe + ":_original.._invalid") == -1)
	  					{
	   						fwException_raise(	exceptionInfo, 
	   											"INFO", 
	   											"fwColourTable_connectCellBackColToStatus(): Connecting to the status of the data point element\n\"" + dpe + "\" was unsuccessful", 
	   											"");
							this.cellBackColRC(i - 1, "status", "DpDoesNotExist");
						}
					}
					break;
  				default:
					//DebugN("alert", gListOfDpElementToConnect[i]);
					if(dpConnect(	"_fwColourTable_calculateColourWithAlertCB",
									dpe + ":_alert_hdl.._act_state_color", 
									dpe + ":_alert_hdl.._active",
									dpe + ":_original.._invalid") == -1) 
  					{
  						fwException_raise(	exceptionInfo, 
  											"INFO", 
  											"fwColourTable_connectCellBackColToStatus(): Connecting to the status of the data point element\n\"" + dpe + "\" was unsuccessful", 
  											"");
						this.cellBackColRC(i - 1, "status", "DpDoesNotExist");
  					}
  					break;
			}
		}
	}
}

/**This functions takes the given states of a data point element and calls a function which calcultes the relevant colour.
	The function then set the background colour of graphical item "this" to that colour.

@par Constraints
	This function is designed as a 'work' function and should only be used by giving it as the function name in a dpConnect statement

@par Usage
	Private
	
@par PVSS managers
	VISION

@param dpe1 data point element
@param alertColour a string containing the name of the current alert colour
@param dpe2 data point element
@param alarmActive a bit to represent if alert handling is active or not (TRUE = active, FALSE = inactive)
@param dpe3 data point element
@param dataInvalid a bit to represent if data is invalid or not (TRUE = invalid, FALSE = valid)
*/
_fwColourTable_calculateColourWithAlertCB(	string dpe1, string alertColour, string dpe2, 
											bool alarmActive, string dpe3, bool dataInvalid)
{
	int cellPos;
	string elementColour, dpName;
	dyn_string exceptionInfo;


	dpName = dpSubStr(dpe1, DPSUB_SYS_DP_EL);
	cellPos = dynContains(gListOfDpElementToConnect, dpName);

	fwColour_convertStatusToColour(elementColour, alertColour, !alarmActive, dataInvalid, exceptionInfo);

	if(cellPos >= 1)
		this.cellBackColRC(cellPos - 1, "status", elementColour);
//DebugN("_fwColourTable_calculateColourWithAlertCB",gListOfDpElementToConnect,dpName,dpe1,cellPos, elementColour);
}

/**This functions takes the given states of a data point element and calls a function which calcultes the relevant colour.
	The function then set the background colour of graphical item "this" to that colour.

@par Constraints
	This function is designed as a 'work' function and should only be used by giving it as the function name in a dpConnect statement

@par Usage
	Private

@par PVSS managers
	VISION

@param dpe1 data point element
@param dataInvalid a bit to represent if data is invalid or not (TRUE = invalid, FALSE = valid)
*/
_fwColourTable_calculateColourWithoutAlertCB(string dpe1, bool dataInvalid)
{
	string elementColour, dpName;
	dyn_string exceptionInfo;
	int cellPos;

	dpName = dpSubStr(dpe1, DPSUB_SYS_DP_EL);
	cellPos = dynContains(gListOfDpElementToConnect, dpName);
	
	fwColour_convertStatusToColour(elementColour, "", 0, dataInvalid, exceptionInfo);

	if(cellPos >= 1)
		this.cellBackColRC(cellPos-1, "status", elementColour);
//DebugN("_fwColourTable_calculateColourWithoutAlertCB",gListOfDpElementToConnect, dpName, dpe1,cellPos, elementColour);
}

/**This function controls the background colour of the cell of a table from within which the function was called.
	The colour is controlled by dpConnecting to the invalid bit of the given data point element, and if it exists,
	the alert active bit and the alert colour are also connected to.
	When the function is called, and any time when the alert state or invalid state changes, a function is called
	which evaluates the current state, selects the relevant colour and sets the background colour of the graphical item.

@par Modification History
	29/03/01 Oliver Holme 	Added functionality for connecting to dpes of type STRUCTURE
							This makes it possible to connect to the state of a summary alert

@par Constraints

@par Usage
	Public

@par PVSS managers
	VISION
	
@param exceptionInfo details of any exceptions are placed in here.
*/
fwColourTable_connectCellBackColToValueStatus(dyn_string &exceptionInfo)
{
	int configType, len, cellPos, i, iResType;
	string dpe;

	len = dynlen(gListOfDpElementToConnect);
//DebugN(gListOfDpElementToConnect, len);

	for(i = 1; i <= len; i++) 
	{
		if(!dpExists(gListOfDpElementToConnect[i]))
		{
			fwException_raise(	exceptionInfo, 
								"ERROR", 
								"fwColourTable_connectCellBackColToValueStatus(): The data point element\n\"" + gListOfDpElementToConnect[i] + "\n\" does not exist", 
								"");
			this.cellBackColRC(i - 1, "status", "DpDoesNotExist");
//DebugN("DpDoesNotExist", gListOfDpElementToConnect[i]);
		}
		else 
		{
			dpe = gListOfDpElementToConnect[i];

			iResType = dpGet(dpe + ":_alert_hdl.._type", configType);

//DebugN("res",dpe);
			switch(configType)
			{
				case DPCONFIG_SUM_ALERT:	// summary alert
					if(dpConnect(	"_fwColourTable_calculateColourWithSummaryAlertCB",
									dpe + ":_alert_hdl.._act_state_color", 
									dpe + ":_alert_hdl.._active") == -1) 
					{
						fwException_raise(	exceptionInfo, 
											"INFO", 
											"fwColourTable_connectCellBackColToValueStatus(): Connecting to the status of the data point element\n\"" + dpe + "\" was unsuccessful",
											"");
						this.cellBackColRC(i - 1, "status", "DpDoesNotExist");
					}
					break;
				case DPCONFIG_NONE:		// no alert
				//DebugN("no alertValue", gListOfDpElementToConnect[i]);
					if(dpElementType(dpe) == DPEL_STRUCT)
					{
					//show OK state if dpe has no online value (ie. dpe is of type structure)
						_fwColourTable_calculateColourWithoutAlertCB(dpe, 0);
					}
					else
					{
						if(dpConnect(	"_fwColourTable_calculateColourWithoutAlertCBValue",
										dpe + ":_online.._invalid",
										dpe + ":_online.._value") == -1)
						{
							fwException_raise(	exceptionInfo,
												"INFO", 
												"fwColourTable_connectCellBackColToValueStatus(): Connecting to the status of the data point element\n\"" + dpe + "\" was unsuccessful",
												"");
							this.cellBackColRC(i - 1, "status", "DpDoesNotExist");
						}
					}
					break;
				default:	// any alert apart from summary
					//DebugN("alertValue", gListOfDpElementToConnect[i]);
					if(dpConnect(	"_fwColourTable_calculateColourWithAlertCBValue",
									dpe + ":_alert_hdl.._act_state_color", 
									dpe + ":_alert_hdl.._active",
									dpe + ":_online.._invalid",
									dpe + ":_online.._value") == -1) 
					{
						fwException_raise(	exceptionInfo, 
											"INFO",
											"fwColourTable_connectCellBackColToValueStatus(): Connecting to the status of the data point element\n\"" + dpe + "\" was unsuccessful",
											"");
						this.cellBackColRC(i - 1, "status", "DpDoesNotExist");
					}
					break;
			}
		}
	}
}

/**This functions takes the given states of a data point element and calls a function which calcultes the relevant colour.
	The function then set the background colour of graphical item "this" to that colour.

@par Constraints
	This function is designed as a 'work' function and should only be used by giving it as the function name in a dpConnect statement

@par Usage
	Private

@par PVSS managers
	VISION

@param dpe1 data point element
@param alertColour a string containing the name of the current alert colour
@param dpe2 data point element
@param alarmActive a bit to represent if alert handling is active or not (TRUE = active, FALSE = inactive)
@param dpe3 data point element
@param dataInvalid a bit to represent if data is invalid or not (TRUE = invalid, FALSE = valid)
@param dpe4 data point element with value to display in the cell
@param valText value to display in the cell
*/
_fwColourTable_calculateColourWithAlertCBValue(	string dpe1, string alertColour, string dpe2,
												bool alarmActive, string dpe3, bool dataInvalid,
												string dpe4, string valText)
{
	int cellPos;
	string elementColour, dpName;
	dyn_string exceptionInfo;

	dpName = dpSubStr(dpe1, DPSUB_SYS_DP_EL);
//	DebugN(dpSubStr(dpe1, DPSUB_SYS_DP_EL_CONF), dpSubStr(dpe1, DPSUB_SYS_DP_EL_CONF_DET));
	cellPos = dynContains(gListOfDpElementToConnect, dpName);

	fwColour_convertStatusToColour(elementColour, alertColour, !alarmActive, dataInvalid, exceptionInfo);

	if(cellPos >= 1)
	{
		this.cellBackColRC(cellPos - 1, "status", elementColour);
		this.cellValueRC(cellPos - 1, "status", valText);
	}
//	DebugN("_fwColourTable_calculateColourWithAlertCBValueValue",gListOfDpElementToConnect,dpName,dpe1,cellPos, elementColour, valText);
}


/**This functions takes the given states of a data point element and calls a function which calcultes the relevant colour.
	The function then set the background colour of graphical item "this" to that colour.

@par Constraints
	This function is designed as a 'work' function and should only be used by giving it as the function name in a dpConnect statement

@par Usage
	Private

@par PVSS managers
	VISION

@param dpe1 data point element with quality of the data
@param dataInvalid a bit to represent if data is invalid or not (TRUE = invalid, FALSE = valid)
@param dpe2 data point element with value to display in the cell
@param valText value to display in the cell
*/
_fwColourTable_calculateColourWithoutAlertCBValue(	string dpe1, bool dataInvalid,
													string dpe2, string valText)
{
	int cellPos;
	string elementColour, dpName;
	dyn_string exceptionInfo;

	dpName = dpSubStr(dpe1, DPSUB_SYS_DP_EL);
//	DebugN(dpSubStr(dpe1, DPSUB_SYS_DP_EL_CONF), dpSubStr(dpe1, DPSUB_SYS_DP_EL_CONF_DET));
//	DebugN(dpSubStr(dpe1, DPSUB_SYS_DP_EL));
	cellPos = dynContains(gListOfDpElementToConnect, dpName);
	
	fwColour_convertStatusToColour(elementColour, "", 0, dataInvalid, exceptionInfo);

	if(cellPos >= 1) 
	{
		this.cellBackColRC(cellPos-1, "status", elementColour);
		this.cellValueRC(cellPos-1, "status", valText);
	}
//DebugN("_fwColourTable_calculateColourWithoutAlertCBValue",gListOfDpElementToConnect, dpName, dpe1,cellPos, elementColour, valText);
}


/**This functions takes the given states of a summary alert on a given data point element
	and calls a function which calculates the relevant colour.
	The function then set the background colour of graphical item "this" to that colour.

@par Constraints
	This function is designed as a 'work' function and should only be used by giving it as the function name in a dpConnect statement

@par Usage
	Private
	
@par PVSS managers
	VISION

@param dpe1 data point element
@param alertColour a string containing the name of the current alert colour
@param dpe2 data point element
@param alarmActive a bit to represent if alert handling is active or not (TRUE = active, FALSE = inactive)
*/
_fwColourTable_calculateColourWithSummaryAlertCB(	string dpe1, string alertColour, 
													string dpe2, bool alarmActive)
{
	int cellPos;
	string elementColour, dpName;
	dyn_string exceptionInfo;

	dpName = dpSubStr(dpe1, DPSUB_SYS_DP_EL);
//	DebugN(dpSubStr(dpe1, DPSUB_SYS_DP_EL_CONF), dpSubStr(dpe1, DPSUB_SYS_DP_EL_CONF_DET));
//	DebugN(dpSubStr(dpe1, DPSUB_SYS_DP_EL));
	cellPos = dynContains(gListOfDpElementToConnect, dpName);
	
	fwColour_convertStatusToColour(elementColour, alertColour, !alarmActive, 0, exceptionInfo);

	if(cellPos >= 1)
	{
		this.cellBackColRC(cellPos - 1, "status", elementColour);
		this.cellValueRC(cellPos - 1, "status", "");
	}
//DebugN("_fwColourTable_calculateColourWithoutAlertCBValue",gListOfDpElementToConnect, dpName, dpe1,cellPos, elementColour, valText);
}
//@}

