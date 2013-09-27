/**@file

Set of functions for handling exceptions

@par Creation Date
	4/12/00	
	
@par PVSS managers
	VISION
	
@author 
	JCOP Framework Team
*/

//@{
/** displays any exceptions in the exceptionDisplay panel.

@par Usage
	Public

@par PVSS managers
	VISION

@param exceptionInfo details of any exceptions
*/ 
fwExceptionHandling_display(dyn_string &exceptionInfo)
{
  int number = 1;

  if(!globalExists("g_fwExceptionHandlingDisplay"))
    _fwExceptionHandling_initialise();

  if(!g_fwExceptionHandlingDisplay)
    return;
  
  if(dynlen(exceptionInfo) <= 0)
    return;

  while(isPanelOpen("Exception Details #" + number))
  {
    //DebugN("fwExceptionHandling_display(): Number used " + number);
    number++;
  }

  ChildPanelOnCentralModal("fwGeneral/fwExceptionDisplay.pnl", 
                            "Exception Details #" + number,
                            makeDynString("$asExceptionInfo:" + exceptionInfo, "$iListIndex:1"));

  exceptionInfo = makeDynString();
}

/** Displays any exceptions in the exception log list.

@par Usage
	Public

@par PVSS managers
	VISION

@param exceptionInfo details of any exceptions
@param listName selection list used to display log messages
*/ 
fwExceptionHandling_log(dyn_string &exceptionInfo, string listName)
{
  int i;
  string exceptionDetails;

  if(dynlen(exceptionInfo)<=0)
    return;
  
  for(i=1; i<=(dynlen(exceptionInfo)); i+=3)
  {
    exceptionDetails = exceptionInfo[i] +": " +exceptionInfo[i+1] +", Code: "+exceptionInfo[i+2];
    setValue(listName, "appendItem", exceptionDetails);
  }	
  exceptionInfo = makeDynString();
}

_fwExceptionHandling_initialise()
{
  bool inhibitDisplayExceptions;
  
  addGlobal("g_fwExceptionHandlingDisplay", BOOL_VAR);
  
  if(dpExists(fwException_SETTINGS_DP))
    dpGet(fwException_SETTINGS_DP + ".inhibitDisplayWindow", inhibitDisplayExceptions); 
  else
    inhibitDisplayExceptions = FALSE;

  g_fwExceptionHandlingDisplay = !inhibitDisplayExceptions;
}

//@}

