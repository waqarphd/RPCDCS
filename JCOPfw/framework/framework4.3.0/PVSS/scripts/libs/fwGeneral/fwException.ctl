/**@file

A library including the necessary functions to raise exceptions

@par Creation Date
	4/12/00	

@author 
	JCOP Framework Team
*/

const string fwException_SETTINGS_DP = "_fwException";

//@{

/** Add the exception to the PVSS log in the form
	[exceptionType][exceptionText][Code: exceptionCode]

    Also the exception details are appended to the dyn_string which is passed to the function
    Three strings are appended to the dyn_string, firstly the exceptionType then the exceptionText
    and finally a code which is associated with the exception (exceptionCode)

@par Usage
	Public

@par PVSS managers
	VISION, CTRL

@param exceptionInfo details of exceptions are returned here
@param exceptionType type of exception
@param exceptionText text associated with exception
@param exceptionCode a code associated with the exception
*/
fwException_raise(dyn_string &exceptionInfo, string exceptionType, string exceptionText, string exceptionCode)
{
  if(!globalExists("g_fwExceptionPriorities"))
    _fwException_initialise();
    
  //DebugN("Exception raised: Type = " + exceptionType + ", Text = " + exceptionText, ", Code = " + exceptionCode);
  dynAppend(exceptionInfo, makeDynString(exceptionType, exceptionText, exceptionCode));
  _fwException_writeToPvssLog(exceptionInfo);
}


_fwException_initialise()
{
  bool logExceptions;
  dyn_int processedLevels;
  dyn_string fwLevels, pvssLevels;
  
  addGlobal("g_fwExceptionPriorities", MAPPING_VAR);
  
  if(dpExists(fwException_SETTINGS_DP))
  {
    dpGet(fwException_SETTINGS_DP + ".priorityMapping.fwLevels", fwLevels,
          fwException_SETTINGS_DP + ".priorityMapping.pvssLevels", pvssLevels,
          fwException_SETTINGS_DP + ".showInPvssLog", logExceptions); 
  }
  else
  {
    fwLevels = makeDynString("FATAL", "ERROR", "WARNING", "INFO", "*");
    pvssLevels = makeDynString("PRIO_FATAL", "PRIO_SEVERE", "PRIO_WARNING", "PRIO_INFO", "PRIO_INFO");
    logExceptions = TRUE;
  }

  for(int i=1; i<=dynlen(pvssLevels); i++)
  {
    if(!logExceptions || pvssLevels[i]=="")
      processedLevels[i] = -1;
    else
      evalScript(processedLevels[i], "int main(){return " + pvssLevels[i] + ";}", makeDynString());

    g_fwExceptionPriorities[fwLevels[i]] = processedLevels[i];
  }
}


_fwException_writeToPvssLog(dyn_string &exceptionInfo)
{
  int i, chosenPriority;
  string exceptionDetails;

  if(dynlen(exceptionInfo)<=0)
    return;

  for(i=1; i<=(dynlen(exceptionInfo)); i+=3)
  {
    bit32 internalBit = 0;
    errClass errors;
  
    if(!mappingHasKey(g_fwExceptionPriorities, exceptionInfo[i]))
    {
      if(!mappingHasKey(g_fwExceptionPriorities, "*"))
        return;
      else
        chosenPriority = g_fwExceptionPriorities["*"];
    }
    else
      chosenPriority = g_fwExceptionPriorities[exceptionInfo[i]];    

    if(chosenPriority == -1)
      return;
    
    errors = makeError(internalBit, chosenPriority, ERR_IMPL, exceptionInfo[i+2], "",
                       convManIdToInt(myManType(), myManNum()), getUserId(), exceptionInfo[i+1]);
    throwError(errors);
  }
}
//@}
