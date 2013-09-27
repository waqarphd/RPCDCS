// $License: NOLICENSE
/**@file
 *
 * This package contains general functions of the FW Component Installation tool to manipulate managers
 *
 * @author Fernando Varela (EN-ICE)
 * @date   August 2010
 */
#uses "fwInstallation.ctl"

/** Version of this library.
 * Used to determine the coherency of all libraries of the installtion tool
 * @ingroup Constants
*/
const string csFwInstallationManagerLibVersion = "6.2.4";

/**
 * @name fwInstallationManager.ctl: Definition of constants

   The following constants are used by the fwInstallationManager.ctl library

 * @{
 */
const int FW_INSTALLATION_MANAGER_PMON_IDX = 1;
const int FW_INSTALLATION_MANAGER_PMON_USER = 2;
const int FW_INSTALLATION_MANAGER_PMON_PWD = 3;
const int FW_INSTALLATION_MANAGER_PMON_PORT = 4;
const int FW_INSTALLATION_MANAGER_HOST = 5;
const int FW_INSTALLATION_MANAGER_TYPE = 6;
const int FW_INSTALLATION_MANAGER_OPTIONS = 7;
const int FW_INSTALLATION_MANAGER_START_MODE = 8;
const int FW_INSTALLATION_MANAGER_SEC_KILL = 9;
const int FW_INSTALLATION_MANAGER_RESTART_COUNT = 10;
const int FW_INSTALLATION_MANAGER_RESET_MIN = 11;
const int FW_INSTALLATION_MANAGER_DONT_STOP_RESTART = 12;

//@} // end of constants


int fwInstallationManager_stopAll(dyn_dyn_mixed exceptions, 
                                  string host = "", 
                                  int port = 4999, 
                                  string user = "", 
                                  string pwd = "",
                                  bool wait = false)
{
  int error = 0;
  bool failed;
  dyn_int diManPos, diStartMode, diSecKill, diRestartCount, diResetMin;
  dyn_string dsManager, dsCommandLine;
  string str;
  string mode;
  
  if(host == "")
  {
     host = fwInstallation_getHostname(); 
     port = pmonPort();
  }
  if(user == "")
    if(fwInstallation_getPmonInfo(user, pwd) != 0)
    {
      fwInstallation_throw("fwInstallationManager_stopAll: Could not resolve pmon username and password. Action aborted", "error", 1);
      return -1;
    }

  //Stop all scattered managers:
  fwInstallation_throw("Stopping all scattered managers. Please wait...", "INFO", 10);  
  if(fwInstallationManager_stopAllScattered(makeDynString(), wait))
  {
    fwInstallation_throw("fwInstallationManager_stopAll: Failed to stop scattered managers", "error", 1);
    return -1;
  }  
  
  //Now stop all managers of the local pmon 
  fwInstallation_throw("Stopping all local managers via PMON. Please wait...", "INFO", 10);  
  dyn_dyn_mixed managersInfo;
  fwInstallationManager_pmonGetManagers(managersInfo, 
                                        host, 
                                        port, 
                                        user, 
                                        pwd);
  
  diManPos = managersInfo[FW_INSTALLATION_MANAGER_PMON_IDX];
  dsManager = managersInfo[FW_INSTALLATION_MANAGER_TYPE];
  diStartMode = managersInfo[FW_INSTALLATION_MANAGER_START_MODE];
  diSecKill = managersInfo[FW_INSTALLATION_MANAGER_SEC_KILL];
  diRestartCount = managersInfo[FW_INSTALLATION_MANAGER_RESTART_COUNT];
  diResetMin = managersInfo[FW_INSTALLATION_MANAGER_RESET_MIN];
  dsCommandLine = managersInfo[FW_INSTALLATION_MANAGER_OPTIONS];
    
  for(int i = 1; i <= dynlen(dsManager); i++)
  { 
    bool skip = false;
    for(int k = 1; k <= dynlen(exceptions);k++)   
    {
      if(dsManager[i] == exceptions[k][1] &&
         patternMatch(exceptions[k][2], dsCommandLine[i])) //hit one of the protected managers, skip it
      {
        skip = true;
        break;
      }
    }
      
    if(skip)
      continue;
            
    //Check if manager has to be reconfigured:
    if(diStartMode[i] == 2) 
    {
      //Manager has to be reconfigured:
      if(diStartMode[i] == 0)
        mode = "manual";
      else if(diStartMode[i] == 1)
        mode = "once";
      else if(diStartMode[i] == 2)
        mode = "always";
                   
      if(fwInstallationManager_logCurrentConfiguration(dsManager[i], mode, diSecKill[i], 
                                           diRestartCount[i], diResetMin[i], dsCommandLine[i]) !=0)
      {
        fwInstallation_throw("ERROR: fwInstallationManager_stopAll(): Could not log current manager configuration for manager: " + dsManager[i] + " " + dsCommandLine[i] + ". Manager will not be stopped. Please do it manually", "error", 1);
        ++error;
        continue;
      }
          
      if(fwInstallationManager_setMode(dsManager[i], dsCommandLine[i], "manual", host, port, user, pwd) != 0)
      {
        fwInstallation_throw("ERROR: fwInstallationManager_stopAll() -> Cannot change manager properties. Skipping manager: " + dsManager[i] + " " + dsCommandLine[i], "error", 1); 
        ++error;
        continue;
      }      
    }       
    if(fwInstallationManager_command("STOP", dsManager[i], dsCommandLine[i], host, port, user, pwd, wait))
      ++error;   
  }
  
  //Done the work through PMON. Stop now scattered managers if any:
  return 0;
}

/** This function log the current configuration of a manager by writting it into an internal datapoint of the installation tool
  @param manager manager type
  @param startMode {always, once, manual}
  @param secKill seconds before the manager is flag as in the wrong state
  @param restartCount restart counter
  @param resetMin time in min that the manager must be OK before the reset counter is reset
  @return 0 if OK, -1 if error
*/  
int fwInstallationManager_logCurrentConfiguration(string manager, 
                                                  string startMode, 
                                                  int secKill, 
                                                  int restartCount, 
                                                  int resetMin, 
                                                  string commandLine)
{
  bool found  = false;
  
  dyn_string dsManager, dsCommandLine, dsStartMode;
  dyn_int diSecKill, diRestartCount, diResetMin;
    
  fwInstallationManager_getReconfigurationActions(dsManager, dsStartMode, diSecKill, diRestartCount, diResetMin, dsCommandLine);
    
  for(int i = 1; i <= dynlen(dsManager); i++)
  {
    if(manager == dsManager[i] && commandLine == dsCommandLine[i])
    {
      //Found manager. Still pending action.
      dsStartMode[i] = startMode;
      diSecKill[i] = secKill;
      diRestartCount[i] = restartCount;
      diResetMin[i] = resetMin;
      found = true;
      break;
    }
  }

  if(!found)
  {
    dynAppend(dsManager, manager);
    dynAppend(dsStartMode, startMode);
    dynAppend(diSecKill, secKill);
    dynAppend(diRestartCount, restartCount);
    dynAppend(diResetMin, resetMin);
    dynAppend(dsCommandLine, commandLine); 
  } 
       
  return fwInstallationManager_setReconfigurationActions(dsManager, dsStartMode, diSecKill, diRestartCount, diResetMin, dsCommandLine);

}

/** This function retrieves all manager properties for the local project
  @param managersInfo managers' properties as a dyn_dyn_mixed matrix  
  @return 0 if OK, -1 if error
*/  
int fwInstallationManager_getAllInfoFromPvss(dyn_dyn_mixed &managersInfo)
{
  file f;
  string line;
  const string path = getPath(CONFIG_REL_PATH);
  const string filename = "progs";
  dyn_string ds;
  int i = 1;

  if(access(path + filename, R_OK) != 0)
  {
    fwInstallation_throw("ERROR: fwInstallationManagers_getAllInfoFromPvss() -> Could not access file: " + path + filename, "error", 4);
    return -1;
  }
  
  f=fopen(path + "/" + filename,"r+"); 
  
  while (feof(f)==0)
  {
    fgets(line,200,f);
    //check that we are dealing with a pvss manager:
    if(patternMatch("PVSS00*", line) ||
       patternMatch("WCC*", line))
    {    
      ds = strsplit(line, "|");
      //remove blank spaces:
      for(int j = 1; j <= dynlen(ds); j++){
        if(j != FW_INSTALLATION_DB_MANAGER_OPTIONS_IDX)
          strreplace(ds[j], " ", "");
        else
          strreplace(ds[j], "\n", "");
          
      }
      
      managersInfo[i][FW_INSTALLATION_DB_MANAGER_NAME_IDX] = ds[1];
      managersInfo[i][FW_INSTALLATION_DB_MANAGER_START_IDX] = ds[2];
      managersInfo[i][FW_INSTALLATION_DB_MANAGER_SECKILL_IDX] = ds[3];
      managersInfo[i][FW_INSTALLATION_DB_MANAGER_RESTART_IDX] = ds[4];
      managersInfo[i][FW_INSTALLATION_DB_MANAGER_RESETMIN_IDX] = ds[5];
      managersInfo[i][FW_INSTALLATION_DB_MANAGER_OPTIONS_IDX] = ds[6];
      
      if(managersInfo[i][FW_INSTALLATION_DB_MANAGER_START_IDX] == "always")
        managersInfo[i][FW_INSTALLATION_DB_MANAGER_TRIGGERS_ALERTS_IDX] = 1;
      else
        managersInfo[i][FW_INSTALLATION_DB_MANAGER_TRIGGERS_ALERTS_IDX] = 0;
      
      ++i;
    }
  }
  fclose(f); // close file

  return 0; 
}


/** This function allows to insert a manager into a project. It is checked before, if the 
manager already exists.

@param manager				name of the manager
@param startMode			{manual, once, always}
@param secKill				seconds to kill after stop
@param restartCount		number of restarts
@param resetMin				restart counter reset time (minutes)
@param commandLine		commandline for the manager
@param host	hostname
@param port	pmon port
@param user	pmon user
@param pwd		pmon password
@return 1 - manager added, 2 - manager already existing, 3 - manager addition disabled, 0 - manager addition failed
@author F. Varela (original idea by S. Schmeling)
*/
int fwInstallationManager_add(string manager, 
                              string startMode, 
                              int secKill, 
                              int restartCount, 
                              int resetMin,
                              string commandLine, 
                              string host = "", 
                              int port = 4999, 
                              string user = "", 
                              string pwd = "")
{
	bool failed, disabled;
	string str;
  dyn_mixed managerInfo;
  
  if(host == "")
  {
    host = fwInstallation_getHostname(); 
    port = pmonPort();
  }
  
  if(user == "")
  {
    if(fwInstallation_getPmonInfo(user, pwd) != 0)
    {
      fwInstallation_throw("fwInstallationManager_add: Could not resolve pmon username and password. Action aborted", "error", 1);
      return -1;
    }
  }
  bool blockUis = false;
  string dp = fwInstallation_getInstallationDp();
  dpGet(dp + ".addManagersDisabled", disabled,
        dp + ".blockUis", blockUis);
        
  if(blockUis && strtolower(manager) == fwInstallation_getWCCOAExecutable("ui"))
  {
    fwInstallation_throw("WARNING: Addition of UI managers have been disabled. Manager: " + manager + " " + commandLine + " will not be added to the console.", "warning");
    return 0;
  }

	if(disabled)
	{
    return 3; //manager addition disabled
  }  
  
  fwInstallationManager_getProperties(manager, commandLine, managerInfo, host, port, user, pwd);
  if(managerInfo[FW_INSTALLATION_MANAGER_PMON_IDX] != -1)
  {
    return 2; //Manager already in the PVSS console
  }
  str = user + "#" + pwd + "#SINGLE_MGR:INS "+pmonGetCount()+" "+
        manager+" "+startMode+" "+secKill+" "+restartCount+" "+
        resetMin+" "+commandLine;
  
  if(pmon_command(str, host, port, FALSE, TRUE))
  {
    fwInstallation_throw("Failed to insert manager: "  + manager + " " + commandLine + " " + host + " " + port + " "+user);
    return 0;
  } 
  
  return 1;//unfortunately this is not coherent with the convetion followed in the libraries (legacy);
}


/** This function allows to insert a driver and the correspoding simulator in the local project. It is checked before, if the 
manager already exists.

@param defActivated if by the default the manager must be activated (i.e. no selection is done in the popup windows and the timer expires)
@param manTitle Text shown as title
@param manager				name of the manager
@param startMode			{manual, once, always}
@param secKill				seconds to kill after stop
@param restartCount		number of restarts
@param resetMin				restart counter reset time (minutes)
@param commandLine		commandline for the manager
@return 1 - manager added, 2 - manager already existing, 3 - manager addition disabled, 0 - manager addition failed
@author F. Varela (original idea by S. Schmeling)
*/
int fwInstallationManager_appendDriver(string defActivated, 
                                       string manTitle, 
                                       string manager, 
                                       string startMode, 
                                       int secKill, 
                                       int restartCount, 
                                       int resetMin, 
                                       string commandLine,
                                       string host = "",
                                       int port = 4999,
                                       string user = "",
                                       string pwd = "")
{
  int error;
	dyn_float df;
	dyn_string ds;
	
  bool activateManagersDisabled;
  string dp = fwInstallation_getInstallationDp();
        
  if(host == "")
  {
    host = fwInstallation_getHostname(); 
    port = pmonPort();
  }
  
  if(user == "")
    if(fwInstallation_getPmonInfo(user, pwd) != 0)
    {
      fwInstallation_throw("fwInstallationManager_appendDriver: Could not resolve pmon username and password. Action aborted", "error", 1);
      return -1;
    }
  
	dpGet(dp + ".activateManagersDisabled", activateManagersDisabled);
	
	if(startMode == "manual")
	{
		error = fwInstallationManager_add(manager, startMode, secKill, restartCount, resetMin, commandLine, host, port, user, pwd);
		error = fwInstallationManager_add(fwInstallation_getWCCOAExecutable("sim"), startMode, secKill, restartCount, resetMin, commandLine, host, port, user, pwd);
	}	else
		if(myManType() == UI_MAN)
		{
			ChildPanelOnCentralReturn("fwInstallation/fwInstallation_addDriver.pnl", "fwInstallation", 
																makeDynString("$manTitle:"+manTitle), df, ds);
      
			if(ds[1] == "timeout")
				switch(defActivated)
				{
					case "DRIVER":
						error = fwInstallationManager_add(manager, startMode, secKill, restartCount, resetMin, commandLine, host, port, user, pwd);
						error = fwInstallationManager_add(fwInstallation_getWCCOAExecutable("sim"), "manual", secKill, restartCount, resetMin, commandLine, host, port, user, pwd);
						break;
					case "SIM":
						error = fwInstallationManager_add(manager, "manual", secKill, restartCount, resetMin, commandLine, host, port, user, pwd);
						error = fwInstallationManager_add(fwInstallation_getWCCOAExecutable("sim"), startMode, secKill, restartCount, resetMin, commandLine, host, port, user, pwd);
						break;
					case "NONE":
						error = fwInstallationManager_add(manager, "manual", secKill, restartCount, resetMin, commandLine, host, port, user, pwd);
						error = fwInstallationManager_add(fwInstallation_getWCCOAExecutable("sim"), "manual", secKill, restartCount, resetMin, commandLine, host, port, user, pwd);
						break;
				}
			if(ds[1] == "DRIVER")
			{
				error = fwInstallationManager_add(manager, startMode, secKill, restartCount, resetMin, commandLine, host, port, user, pwd);
				error = fwInstallationManager_add(fwInstallation_getWCCOAExecutable("sim"), "manual", secKill, restartCount, resetMin, commandLine, host, port, user, pwd);
			}
			if(ds[1] == "SIM")
			{
				error = fwInstallationManager_add(manager, "manual", secKill, restartCount, resetMin, commandLine, host, port, user, pwd);
				error = fwInstallationManager_add(fwInstallation_getWCCOAExecutable("sim"), startMode, secKill, restartCount, resetMin, commandLine, host, port, user, pwd);
			}
		} else {
			if(!activateManagersDisabled) 	
			{
				switch(defActivated)
				{
					case "DRIVER":
						error = fwInstallationManager_add(manager, startMode, secKill, restartCount, resetMin, commandLine, host, port, user, pwd);
						error = fwInstallationManager_add(fwInstallation_getWCCOAExecutable("sim"), "manual", secKill, restartCount, resetMin, commandLine, host, port, user, pwd);
						break;
					case "SIM":
						error = fwInstallationManager_add(manager, "manual", secKill, restartCount, resetMin, commandLine, host, port, user, pwd);
						error = fwInstallationManager_add(fwInstallation_getWCCOAExecutable("sim"), startMode, secKill, restartCount, resetMin, commandLine, host, port, user, pwd);
						break;
					case "NONE":
						error = fwInstallationManager_add(manager, "manual", secKill, restartCount, resetMin, commandLine, host, port, user, pwd);
						error = fwInstallationManager_add(fwInstallation_getWCCOAExecutable("sim"), "manual", secKill, restartCount, resetMin, commandLine, host, port, user, pwd);
						break;
				}					
			} else {
				error = fwInstallationManager_add(manager, "manual", secKill, restartCount, resetMin, commandLine, host, port, user, pwd);
				error = fwInstallationManager_add(fwInstallation_getWCCOAExecutable("sim"), "manual", secKill, restartCount, resetMin, commandLine, host, port, user, pwd);
			}
      
			if(error == 1)
			{
				error = 3;
				fwInstallation_throw("The installation tool appended a driver to your project. If you want it to start 'always' or 'once', please change the start mode in the console by hand!", "INFO", 10);
			}
		}
	return error;
}

/** This function appends a manager to the console of the local project.

@param defActivated if by the default the manager must be activated (i.e. no selection is done in the popup windows and the timer expires)
@param manTitle Text shown as title
@param manager				name of the manager
@param startMode			{manual, once, always}
@param secKill				seconds to kill after stop
@param restartCount		number of restarts
@param resetMin				restart counter reset time (minutes)
@param commandLine		commandline for the manager
@return 1 - manager added, 2 - manager already existing, 3 - manager addition disabled, 0 - manager addition failed
@author F. Varela (original idea by S. Schmeling)
*/
int fwInstallationManager_append(bool defActivated, 
                                 string manTitle, 
                                 string manager, 
                                 string startMode,
                                 int secKill, 
                                 int restartCount, 
                                 int resetMin, 
                                 string commandLine, 
                                 string host = "", 
                                 int port = 4999, 
                                 string user = "", 
                                 string pwd = "")
{
	int error;
	dyn_float df;
	dyn_string ds;
	
	bool activateManagersDisabled;
 string dp = fwInstallation_getInstallationDp();
        
	dpGet(dp + ".activateManagersDisabled", activateManagersDisabled);
  if(host == "")
  {
    host = fwInstallation_getHostname(); 
    port = pmonPort();
  }  
  
  if(user == "")
    if(fwInstallation_getPmonInfo(user, pwd) != 0)
    {
      fwInstallation_throw("fwInstallationManager_append: Could not resolve pmon username and password. Action aborted", "error", 1);
      return -1;
    }
	
	if(startMode == "manual")
			error = fwInstallationManager_add(manager, startMode, secKill, restartCount, resetMin, commandLine, host, port, user, pwd);
	else
		if(myManType() == UI_MAN)
		{
			ChildPanelOnCentralReturn("fwInstallation/fwInstallation_addManager.pnl", "fwInstallation", 
																makeDynString("$manTitle:"+manTitle), df, ds);

			if((ds[1] == "timeout" && defActivated) || ds[1] == "ALLOW")
				error = fwInstallationManager_add(manager, startMode, secKill, restartCount, resetMin, commandLine, host, port, user, pwd);
			else
				error = fwInstallationManager_add(manager, "manual", secKill, restartCount, resetMin, commandLine, host, port, user, pwd);
		} else {
			if(!activateManagersDisabled)
				error = fwInstallationManager_add(manager, startMode, secKill, restartCount, resetMin, commandLine, host, port, user, pwd);
			else
				error = fwInstallationManager_add(manager, "manual", secKill, restartCount, resetMin, commandLine, host, port, user, pwd);
			if(error ==1)
			{
				fwInstallation_throw("The installation tool appended a manager to your project. If you want it to start 'always' or 'once', please change the start mode in the console by hand!", "INFO", 10);
				error = 3;
			}
		}
	return error;
}  
  
/** This function deletes a manager reconfiguration action

@param manager				name of the manager
@param startMode			{manual, once, always}
@param secKill				seconds to kill after stop
@param restartCount		number of restarts
@param resetMin				restart counter reset time (minutes)
@param commandLine		commandline for the manager
@return 0 if OK, -1 if error
*/
int fwInstallationManager_deleteReconfigurationAction(string manager, string startMode, int secKill, int restartCount, int resetMin, string commandLine)
{  
  dyn_string dsManager, dsCommandLine, dsStartMode;
  dyn_int diSecKill, diRestartCount, diResetMin, diResetCount;
  
  fwInstallationManager_getReconfigurationActions(dsManager, dsStartMode, diSecKill, diRestartCount, diResetMin, dsCommandLine);
  
  for(int i = 1; i <= dynlen(dsManager); i++)
  {
    if(manager == dsManager[i] && commandLine == dsCommandLine[i])
    {
      dynRemove(dsManager, i);
      dynRemove(dsStartMode, i);
      dynRemove(diSecKill, i);
      dynRemove(diRestartCount, i);
      dynRemove(diResetMin, i);
      dynRemove(dsCommandLine, i);
      
      break;
    }
  } 
  
  return fwInstallationManager_setReconfigurationActions(dsManager, dsStartMode, diSecKill, diRestartCount, diResetMin, dsCommandLine);
}


/** This function stores a set of manager reconfiguration action in an internal dp

@param dsManager			names of the managers
@param dsStartMode	array of	{manual, once, always}
@param diSecKill			array of seconds to kill after stop
@param diRestartCount	array of	number of restarts
@param diResetMin				array of restart counter reset time (minutes)
@param dsCommandLine		array of commandline for the manager
@return 0 if OK, -1 if error
*/
int fwInstallationManager_setReconfigurationActions(dyn_string dsManager, 
                                                    dyn_string dsStartMode, 
                                                    dyn_int diSecKill, 
                                                    dyn_int diRestartCount, 
                                                    dyn_int diResetMin, 
                                                    dyn_string dsCommandLine)
{
  int error = 0;
  string dpr = fwInstallation_getAgentRequestsDp();
  
  error = dpSet(dpr+".managerReconfiguration.manager", dsManager,
                dpr+".managerReconfiguration.startMode", dsStartMode,
                dpr+".managerReconfiguration.secKill", diSecKill,
                dpr+".managerReconfiguration.restartCount", diRestartCount,
                dpr+".managerReconfiguration.resetMin", diResetMin,
                dpr+".managerReconfiguration.commandLine", dsCommandLine);
  
  if(error)
    return -1;
  
  return 0;
}

/** This function retrieves from an internal dp, the list of manager reconfiguration actions

@param dsManager			names of the managers
@param dsStartMode	array of	{manual, once, always}
@param diSecKill			array of seconds to kill after stop
@param diRestartCount	array of	number of restarts
@param diResetMin				array of restart counter reset time (minutes)
@param dsCommandLine		array of commandline for the manager
@return 0 if OK, -1 if error
*/

int fwInstallationManager_getReconfigurationActions(dyn_string &dsManager, 
                                                    dyn_string &dsStartMode, 
                                                    dyn_int &diSecKill, 
                                                    dyn_int &diRestartCount, 
                                                    dyn_int &diResetMin, 
                                                    dyn_string &dsCommandLine)
{  
  string dpr = fwInstallation_getAgentRequestsDp();

  return dpGet(dpr+".managerReconfiguration.manager", dsManager,
               dpr+".managerReconfiguration.startMode", dsStartMode,
               dpr+".managerReconfiguration.secKill", diSecKill,
               dpr+".managerReconfiguration.restartCount", diRestartCount,
               dpr+".managerReconfiguration.resetMin", diResetMin,
               dpr+".managerReconfiguration.commandLine", dsCommandLine);
}

/** This function executes a manager reconfiguration action

@param manager				name of the manager
@param startMode			{manual, once, always}
@param secKill				seconds to kill after stop
@param restartCount		number of restarts
@param resetMin				restart counter reset time (minutes)
@param commandLine		commandline for the manager
@param host	hostname
@param port	pmon port
@param user	pmon user
@param pwd		pmon password

@return 0 if OK, -1 if error
*/
int fwInstallationManager_executeReconfigurationAction(string manager, 
                                                       string startMode, 
                                                       int secKill, 
                                                       int restartCount, 
                                                       int resetMin, 
                                                       string commandLine, 
                                                       string host = "", 
                                                       int port = 4999, 
                                                       string user = "", 
                                                       string pwd = "")
{  
  int error = 0;
  bool failed;
  dyn_int diManPos, diStartMode, diSecKill, diRestartCount, diResetMin;
  dyn_string dsManager, dsCommandLine, dsProps;
  string str;
  
  int pos = -1;
  if(host == "")
  {
    host = fwInstallation_getHostname(); 
    port = pmonPort();
  }
  
  if(user == "")
    if(fwInstallation_getPmonInfo(user, pwd) != 0)
    {
      fwInstallation_throw("fwInstallationManager_executeReconfigurationAction: Could not resolve pmon username and password. Action aborted", "error", 1);
      return -1;
    }
  
  dyn_mixed managerInfo;
  fwInstallationManager_getProperties(manager, commandLine, managerInfo, host, port, user, pwd);
  pos = managerInfo[FW_INSTALLATION_MANAGER_PMON_IDX];
  
  if(pos >= 0)
  {    
    if(startMode == "always" || startMode == "once") //start the manager is required. In most of the cases this is redundant but it helps when pmon has given up starting the manager because it's been restarted too many times
        if(fwInstallationManager_command("START", manager, commandLine, host, port, user, pwd))
          fwInstallation_throw("fwInstallationManager_executeReconfigurationAction() -> failed to start the manager explicity: " + manager + " " + commandLine + " " + host + " " + port + " " + user, "WARNING", 14);
    
    str = user + "#" + pwd + "#SINGLE_MGR:PROP_PUT " + (pos) + 
          " " + startMode + " " + fabs(secKill) + " " + 
          fabs(restartCount) + " " + fabs(resetMin) + 
          " " + commandLine;
        
    if(pmon_command(str, host, port, FALSE, TRUE) == 0) return 0; //Everything went OK
    else {fwInstallation_throw("fwInstallationManager_executeReconfigurationAction() -> Could not execute action on manager" + manager + " " + commandLine + " " + host + " " + port + " " + user); return -1;}
  }
  else
    return -1; //manager could not be found.  
  
  return 0; 
}

/** This function executes all manager reconfiguration action

@return 0 if OK, -1 if error
*/

int fwInstallationManager_executeAllReconfigurationActions(bool fromPostInstall = false)
{    
  int error = 0;
  dyn_string dsManager, dsStartMode, dsCommandLine;
  dyn_int diSecKill, diRestartCount, diResetMin;
  
  if(!fromPostInstall)
    return 0;
  
  if(fwInstallationManager_getReconfigurationActions(dsManager, dsStartMode, diSecKill, diRestartCount, diResetMin, dsCommandLine) != 0)
  {
    fwInstallation_throw("ERROR: fwInstallationManager_executeAllReconfigurationActions() -> Could not get list of manager reconfiguration actions");
    return -1;
  }   
  for(int i =1; i <= dynlen(dsManager); i++)
  {
    fwInstallation_throw("Reverting Manager Configuration: " + dsManager[i] + " " + dsCommandLine[i] + " " + dsStartMode[i], "INFO", 10);
    error += fwInstallationManager_executeReconfigurationAction(dsManager[i], dsStartMode[i], diSecKill[i], diRestartCount[i], diResetMin[i], dsCommandLine[i]);
    error += fwInstallationManager_deleteReconfigurationAction(dsManager[i], dsStartMode[i], diSecKill[i], diRestartCount[i], diResetMin[i], dsCommandLine[i]);
  }
	
  if(error)
  {
    fwInstallation_throw("ERROR: fwInstallationManager_executeAllReconfigurationActions() -> There were errors reconfiguring automatically the project managers");
    return -1;
  }
  
  return 0; 
}

/** This function sets the start mode of a manager

@param manager				name of the manager
@param commandLine		commandline for the manager
@param mode			{manual, once, always}
@return 0 if OK, -1 if error
*/
int fwInstallationManager_setMode(string manager, 
                                  string commandLine, 
                                  string mode, 
                                  string host = "", 
                                  int port = 4999, 
                                  string user = "", 
                                  string pwd = "")
{
  dyn_mixed managerInfo;
  if(host == "")
  {
    host = fwInstallation_getHostname(); 
    port = pmonPort();
  }
  
  if(user == "")
    if(fwInstallation_getPmonInfo(user, pwd) != 0)
    {
      fwInstallation_throw("fwInstallationManager_setMode: Could not resolve pmon username and password. Action aborted", "error", 1);
      return -1;
    }
  
  fwInstallationManager_getProperties(manager, commandLine, managerInfo, host, port, user, pwd);
  managerInfo[FW_INSTALLATION_MANAGER_START_MODE] = mode;
  switch(strtolower(mode))
  {
    case "always": managerInfo[FW_INSTALLATION_MANAGER_START_MODE] = 2; break;
    case "manual": managerInfo[FW_INSTALLATION_MANAGER_START_MODE] = 0; break;
    case "once": managerInfo[FW_INSTALLATION_MANAGER_START_MODE] = 1; break;
  } 
  return fwInstallationManager_setProperties(manager, commandLine, managerInfo, host, port, user, pwd);
}

/** This stops all managers of a set of particular types

@param types	types of manager to be stopped, e.g. PVSS00ui or WCCOAui
@param host	hostname
@param port	pmon port
@param user	pmon user
@param pwd		pmon password

@return 0 if OK, -1 if error
*/
int fwInstallationManager_stopAllOfTypes(dyn_string types, 
                                         string host = "", 
                                         int port = 4999, 
                                         string user = "", 
                                         string pwd = "",
                                         bool wait = false,
                                         bool useKill = false)
{
  int error = 0;
  dyn_string protectedManagersArgs = makeDynString("-m gedi", "-f pvss_scripts.lst", "-f fwInstallationAgent.lst", "-p fwInstallation/fwInstallationAgent.pnl", "-p fwInstallation/fwInstallation.pnl");
  
  bool failed;
  dyn_int diManPos, diStartMode, diSecKill, diRestartCount, diResetMin;
  dyn_string dsManager, dsCommandLine;
  string str;
  string mode;
  
  if(host == "")
  {
     host = fwInstallation_getHostname(); 
     port = pmonPort();
  }
  
  if(user == "")
    if(fwInstallation_getPmonInfo(user, pwd) != 0)
    {
      fwInstallation_throw("fwInstallationManager_stopAllOfTypes: Could not resolve pmon username and password. Action aborted", "error", 1);
      return -1;
    }

  dyn_dyn_mixed managersInfo;
  fwInstallationManager_pmonGetManagers(managersInfo, 
                                        host, 
                                        port, 
                                        user, 
                                        pwd);
  diManPos = managersInfo[FW_INSTALLATION_MANAGER_PMON_IDX];
  dsManager = managersInfo[FW_INSTALLATION_MANAGER_TYPE];
  diStartMode = managersInfo[FW_INSTALLATION_MANAGER_START_MODE];
  diSecKill = managersInfo[FW_INSTALLATION_MANAGER_SEC_KILL];
  diRestartCount = managersInfo[FW_INSTALLATION_MANAGER_RESTART_COUNT];
  diResetMin = managersInfo[FW_INSTALLATION_MANAGER_RESET_MIN];
  dsCommandLine = managersInfo[FW_INSTALLATION_MANAGER_OPTIONS];
    
  //Avoid opening the main panel of the instalaltion tool is opened from the Gedi
  for(int i = 1; i <= dynlen(dsManager); i++)
  {    
    if(dynlen(dynPatternMatch(dsManager[i], types)))
    {
      //Stop all managers but the protected ones:
      bool protect = false;
        for(int j = 1; j <= dynlen(protectedManagersArgs); j++)
        {
          if(patternMatch("*" + protectedManagersArgs[j]  + "*", dsCommandLine[i]))
            protect = true; //this manager is in the protected list
        }
      
      if(!protect) //stop it if it is not a protected manager
      {
        //Check if manager has to be reconfigured:
        if(diStartMode[i] == 2) 
        {
          //Manager has to be reconfigured:
          mode = "always"; //Current mode of the manager
          if(fwInstallationManager_logCurrentConfiguration(dsManager[i], mode, diSecKill[i], 
  		                                           diRestartCount[i], diResetMin[i], dsCommandLine[i]) !=0)
          {
            fwInstallation_throw("ERROR: fwInstallation_stopManagers(): Could not log current manager configuration for manager: " + dsManager[i] + " " + dsCommandLine[i] + ". Manager will not be stopped. Please do it manually", "error", 1);
            ++error;
            continue;
          }
          
          if(dsManager[i] == fwInstallation_getWCCOAExecutable("ctrl") && patternMatch("*-f fwScripts.lst*", dsCommandLine[i]))
          {
            mode = "once";
          }
          else
            mode = "manual";
          
          if(fwInstallationManager_setMode(dsManager[i], dsCommandLine[i], mode, host, port, user, pwd) != 0)
          {
            fwInstallation_throw("ERROR: fwInstallation_stopManagers() -> Cannot change manager properties. Skipping manager: " + dsManager[i] + " " + dsCommandLine[i], "error", 1); 
            ++error;
            continue;
          }
          
        }       
        
/*        str = user + "#" + pwd + "#SINGLE_MGR:STOP " + (diManPos[i]-1);
        if(pmon_command(str, host, port, FALSE, TRUE) != 0)
	      {
          ++error;
        }
*/
	  string cmd = "STOP";
        if(useKill)
		cmd = "KILL";
        
//DebugN(types, dsManager[i], dsCommandLine[i], cmd);

        if(fwInstallationManager_command(cmd, dsManager[i], dsCommandLine[i], host, port, user, pwd, wait))
          ++error;   
      }
    }
  }//end of loop over managers
  
  //Done the work through PMON. Stop now scattered UIs if any:
  return fwInstallationManager_stopAllScattered(types, wait);
  
}

int fwInstallationManager_stopAllScattered(dyn_string types = makeDynString(), bool wait = false)
{
  dyn_int pendingManagers;
  dyn_int managerTypes;
  dyn_string internalTypes;
  dyn_string hosts;
  const int tmax = 5;
  bool actionTaken = false;

  if(dynlen(types) <= 0)
  {
    dynAppend(internalTypes, "Ui");
    dynAppend(managerTypes, UI_MAN);
  
    dynAppend(internalTypes, "Ctrl");
    dynAppend(managerTypes, CTRL_MAN);

    dynAppend(internalTypes, "Api");
    dynAppend(managerTypes, API_MAN);
    dynAppend(internalTypes, "Device");
    dynAppend(managerTypes, DEVICE_MAN);

    dynAppend(internalTypes, "Driver");
    dynAppend(managerTypes, DRIVER_MAN);

    dynAppend(internalTypes, "Redu");
    dynAppend(managerTypes, REDU_MAN);

    dynAppend(internalTypes, "Ascii");
    dynAppend(managerTypes, ASCII_MAN);
  }
  else
  {
    if(dynContains(types, fwInstallation_getWCCOAExecutable("ui")) > 0 || dynContains(types, fwInstallation_getWCCOAExecutable("NV")))
    {
      dynAppend(internalTypes, "Ui");
      dynAppend(managerTypes, UI_MAN);
    }
 
    if(dynContains(types, fwInstallation_getWCCOAExecutable("ctrl")))
    {
      dynAppend(internalTypes, "Ctrl");
      dynAppend(managerTypes, CTRL_MAN);
    }
    
    if(dynContains(types, fwInstallation_getWCCOAExecutable("api")))
    {
      dynAppend(internalTypes, "Api");
      dynAppend(managerTypes, API_MAN);
      dynAppend(internalTypes, "Device");
      dynAppend(managerTypes, DEVICE_MAN);
    }

    if(dynContains(types, fwInstallation_getWCCOAExecutable("driver")))
    {
      dynAppend(internalTypes, "Driver");
      dynAppend(managerTypes, DRIVER_MAN);
    }

    if(dynContains(types, fwInstallation_getWCCOAExecutable("redu")))
    {
      dynAppend(internalTypes, "Redu");
      dynAppend(managerTypes, REDU_MAN);
    }
    
    if(dynContains(types, fwInstallation_getWCCOAExecutable("ascii")))
    {
      dynAppend(internalTypes, "Ascii");
      dynAppend(managerTypes, ASCII_MAN);
    }
  }

  for(int i = 1; i <= dynlen(internalTypes); i++)
  {
    dyn_string hosts;
    if(dynlen(fwInstallationManager_getRunningScattered(internalTypes[i], hosts)))
    {  
      if(fwInstallationManager_exitScattered(internalTypes[i], managerTypes[i]))
      {
        fwInstallation_throw("Failed to stop managers of type: " + str);
        return -1;
      }
      actionTaken = true;
    }
  }
    
  bool goOn = false;
  if(wait && actionTaken) //wait for the managers to stop:
  {
    //fwInstallation_throw("fwInstallationManager_stopPendingManagers() -> Waiting for managers to stop...", "INFO", 10);
    int t = 1;
    do
    {
      delay(10);
      dynClear(pendingManagers);
      dynClear(hosts);
      goOn = false;
      for(int i = 1; i <= dynlen(internalTypes); i++)
        if(dynlen(fwInstallationManager_getRunningScattered(internalTypes[i], hosts)))
        {
          fwInstallationManager_exitScattered(internalTypes[i], managerTypes[i]);
          goOn = true; //Managers are still running.         
        }
      ++t;
    } while(goOn && t <= tmax);
  
    if(goOn && t >= tmax)    
    {
      for(int i = 1; i <= dynlen(internalTypes); i++)
      {
        dynClear(pendingManagers);
        pendingManagers = fwInstallationManager_getRunningScattered(internalTypes[i], hosts[i]);
        if(dynlen(pendingManagers))
          fwInstallation_throw("Failed to stop all managers of type: " + internalTypes[i] + ": " + pendingManagers);
      }
      return -1;
    }
  }
  
  return 0;
}

int fwInstallationManager_getScripts(int num, dyn_string &scripts, string systemName ="")
{  
  if(num < 1) //wrong ctrl number
    return -1;
  
  if(systemName == "") systemName = getSystemName();
  
  string dp = systemName+"_CtrlDebug_CTRL_" + num;
  time t0;
  dpSetWait(dp + ".Command", "info scripts");
  dpGet(dp + ".Command:_online.._stime", t0);
  
  dyn_string result;
  time t1;
  int count = 1;
  
  while(t1 < t0 && count <= 10) //wait until the result dp has been updated but not more than 10s.
  {
    dpGet(dp + ".Result:_online.._stime", t1,
          dp + ".Result", result);
    ++count;
    delay(1);
  }
  
  if(count >= 10)
  {
    fwInstallation_throw("Failed to read the scripts run by Ctrl manager number: " + num);
    return -1;
  }
  
  for(int i = 1; i <= dynlen(result); i++)
  {
    dyn_string dsTemp = strsplit(result[i], ";");
    if(dynlen(dsTemp) >= 1)
      dynAppend(scripts, dsTemp[dynlen(dsTemp)]);
  }
  
  return 0;
}

dyn_int fwInstallationManager_getRunningScattered(string type, dyn_string &remoteHosts)
{
  dyn_int di;
  dyn_int pendingManagers;
  dyn_string hosts;
//  dyn_string protectedScripts = makeDynString("fwInstallationFakeScript.ctl", "fwInstallationAgentDBConsistencyChecker.ctl", "archiv_client.ctl", "calculateState.ctl");
  dyn_string protectedScripts = makeDynString("fwInstallationFakeScript.ctl", "fwInstallationAgentDBConsistencyChecker.ctl", "archiv_client.ctl", "calculateState.ctl", "libs/PVSSBootstrapper/PVSSBootstrapper_insider.ctl");
//  dpGet("_Connections." + type + ".ManNums", pendingManagers,
//        "_Connections." + type + ".HostNames", remoteHosts);
  
  dpGet("_Connections." + type + ".ManNums", di,
        "_Connections." + type + ".HostNames", hosts);

  for(int i = 1; i <= dynlen(di); i++)
  {
    //check that if a control manager, it does not run any of the scripts of PVSS and of the Installation tool:
    bool isProtected = false;
    if(type == "Ctrl")
    {
      dyn_string scripts;
      dynClear(scripts);
      if(fwInstallationManager_getScripts(di[i], scripts))
      {
        fwInstallation_throw("Could not resolve the scripts run by CTRL manager " + di[i] + ". This CTRL manager will be skipped.", "WARNING", 10);
        continue;
      }
      for(int j = 1; j <= dynlen(scripts); j++)
      {
        if(dynlen(dynPatternMatch(scripts[j], protectedScripts))> 0)
        {
          isProtected = true;
          break;
        }
      }//end of loop over j
    }
    else if(type = "Ui")
    {
      if(myManType() == UI_MAN && di[i] == myManNum())
        isProtected = true; //avoid stopping the calling UI.
    }
    
    if(!isProtected)
      dynAppend(pendingManagers, di[i]);  
      dynAppend(remoteHosts, hosts[i]);  
  }
/*    if(strtoupper(fwInstallation_getHostname()) != strtoupper(hosts[i]))
    {
      dynAppend(pendingManagers, di[i]);  
      dynAppend(remoteHosts, hosts[i]);  
    }
    else
    {
      fwInstallation_throw("Found an scattered UI running in the local host. It needs to be killed by hand: " + di[i], "WARNING", 10);            
    }
*/    
  return pendingManagers;
}


int fwInstallationManager_exitScattered(dyn_string types, dyn_int pvssManagerTypes)
{
  dyn_int pendingManagers;
  int err = 0;
  dyn_string hosts;
  
  for(int k = 1; k <= dynlen(types); k++)
  {
    dynClear(pendingManagers);
    pendingManagers = fwInstallationManager_getRunningScattered(types[k], hosts);
    
    for(int i = 1; i <= dynlen(pendingManagers); i++)
    {
      fwInstallation_throw("Stopping " + types[k] + ": " +  pendingManagers[i] + " running on host: " + hosts[i], "INFO", 10); 
      if(dpSet("_Managers.Exit", convManIdToInt(pvssManagerTypes[k], pendingManagers[i])))
      {
        fwInstallation_throw("Failed to stop manager: " + types[k] + ": " + pendingManagers[i] + " running on remote host: " + hosts[i]);
        ++err;
      }
    }
  }
  
  if(err)
    return -1;
  
  return 0;
}

/** This function retrieves from an internal dp of the installation tool whether the managers of a particular type
    have to be stopped prior to the installation of a component or not

@param managerType	type of manager, e.g. PVSS00ui
@return 0 if OK, -1 if error
*/
int fwInstallationManager_shallStopManagersOfType(string managerType)
{
  string dp = fwInstallation_getAgentDp();
  int val;
  
  switch(managerType)
  {
   case "PVSS00dist":  dp += ".managers.stopDist";
     break;
   case "WCCILdist":  dp += ".managers.stopDist";
     break;
   case "PVSS00ui":   dp += ".managers.stopUIs";
     break;
   case "WCCOAui":   dp += ".managers.stopUIs";
     break;
   case "PVSS00ctrl":   dp += ".managers.stopCtrl";
     break;
   case "WCCOActrl":   dp += ".managers.stopCtrl";
     break;
   default: fwInstallation_throw("ERROR: fwInstallationManager_shallStopManagersOfType() -> Invalid manager type: " + managerType, "error", 1);
     dp = "";     
  }
  
  if(dpExists(dp))
    dpGet(dp, val);
  else
    val = 0;
  
  return val;  
}

/** This function send a pmon command onto a manager

@param action	 {START, STOP, RESTART}
@param manager manager type
@param commandLine		commandline for the manager
@param host	hostname
@param port	pmon port
@param user	pmon user
@param pwd		pmon password

@return 0 if OK, -1 if error
*/

int fwInstallationManager_command(string action, 
                                  string manager, 
                                  string commandLine, 
                                  string host = "", 
                                  int port = 4999, 
                                  string user = "", 
                                  string pwd = "",
                                  bool wait = false)
{
  int pos = -1;
  string startMode = "";
  dyn_string cmds;
  int err = 0;
  bool desiredState = 0;

  if(host == "")
  {
    host = fwInstallation_getHostname(); 
    port = pmonPort();
  }
  
  if(user == "")
  {
    if(fwInstallation_getPmonInfo(user, pwd) != 0)
    {
      fwInstallation_throw("fwInstallationManager_command: Could not resolve pmon username and password. Action aborted", "error", 1);
      return -1;
    }
  }

  dynClear(cmds);
  dyn_mixed managerInfo;
  fwInstallationManager_getProperties(manager, commandLine, managerInfo, host, port, user, pwd);
  
  pos = managerInfo[FW_INSTALLATION_MANAGER_PMON_IDX];
  if(pos < 0)
  {
    fwInstallation_throw("fwInstallationManager_command() -> Manager not found: " + manager + " " + commandLine);
    return -1;
  }
  
  bool isRunning = true; 
  switch(strtoupper(action))
  {
    case "START": dynAppend(cmds, user + "#" + pwd + "#SINGLE_MGR:START " + pos); 
                  desiredState = 1;
                  break;
    case "STOP":  dynAppend(cmds, user + "#" + pwd + "#SINGLE_MGR:STOP " + pos); 
                  desiredState = 0;
                  break;
    case "KILL":  dynAppend(cmds, user + "#" + pwd + "#SINGLE_MGR:KILL " + pos); 
                  desiredState = 0;
                  break;
    case "RESTART":
                  fwInstallationManager_isRunning(manager, commandLine, isRunning, host, port, user, pwd);
                  if(isRunning)
                    dynAppend(cmds, user + "#" + pwd + "#SINGLE_MGR:KILL " + pos); 
                  
                  dynAppend(cmds, user + "#" + pwd + "#SINGLE_MGR:START " + pos); 
                  desiredState = 1;
                  break;
    default: fwInstallation_throw("ERROR: fwInstallationManager_command() -> Unknown action: " + action + ". Valid actions are: START, STOP, RESTART");
      return -1;
  }
  
  for(int i = 1; i <= dynlen(cmds); i++)
  {
    if(pmon_command(cmds[i], host, port, false, true))
    {
      ++err;
      fwInstallation_throw("ERROR: fwInstallationManager_command() -> Failed to execute command: " + cmds[i]); 
    }
    if(i < dynlen(cmds)) //wait only if necessary
      delay(5);
  }
  
  //commands have been sent. Wait for the desired state if necessary:
  if(wait)
  {
    int runs = 0;
    fwInstallationManager_isRunning(manager, commandLine, runs, host, port, user, pwd);
    
    if(runs == desiredState) //the manager is already in the desired state, notthing to be done.
      return 0;
       
    fwInstallation_throw("Waiting for the manager " + manager + " " + commandLine + " to be: " + (desiredState?"STARTED":"STOPPED"), "INFO", 10);
    bool timeout = false;
    fwInstallationManager_wait(desiredState, manager, commandLine, 30, timeout, host, port, user, pwd);
    if(timeout)
    {
      fwInstallation_throw("Manager: " + manager + " " + commandLine + " is still " + (!desiredState?"STARTED":"STOPPED"));
      return -1;
    }
    else
      fwInstallation_throw("Manager: " + manager + " " + commandLine + " has been successfully " + (desiredState?"STARTED":"STOPPED"), "INFO", 10);
  }  
  
  if(err)
    return -1;
    
  return 0; 
}


/** This function retrieves all managers from pmon

@param managersInfo (out) managers properties
@param host	(in) host name where the project runs
@param port	(in) pmon port
@param user	(in) pmon user
@param pwd		(in) pmon password
@return 0 if OK, -1 if error
@author F. Varela based on an original implmentation done by S. Schmeling
*/
int fwInstallationManager_pmonGetManagers(dyn_dyn_mixed &managersInfo, 
                                          string host = "", 
                                          string port = 4999, 
                                          string user = "", 
                                          string pwd = "")
{ 
	string str;
	dyn_dyn_string dsResult;
	
  if(host == "")
  {
    host = fwInstallation_getHostname(); 
    port = pmonPort();
  }
  
  if(user == "")
  {

    if(fwInstallation_getPmonInfo(user, pwd) != 0)
    {
      fwInstallation_throw("fwInstallationManager_pmonGetManagers: Could not resolve pmon username and password. Action aborted", "error", 1);
      return -1;
    }
  }
	str = user+ "#" + pwd + "#MGRLIST:LIST";
	
	int err = pmon_query(str, host, port, dsResult, FALSE, TRUE);
  if(dynlen(dsResult)>0)
    for(int i=1; i<=dynlen(dsResult); i++)
    {
      managersInfo[FW_INSTALLATION_MANAGER_PMON_IDX][i] = i;
      managersInfo[FW_INSTALLATION_MANAGER_TYPE][i] = dsResult[i][1];
      managersInfo[FW_INSTALLATION_MANAGER_START_MODE][i] = dsResult[i][2];
      managersInfo[FW_INSTALLATION_MANAGER_SEC_KILL][i] = dsResult[i][3];
      managersInfo[FW_INSTALLATION_MANAGER_RESTART_COUNT][i] = dsResult[i][4];
      managersInfo[FW_INSTALLATION_MANAGER_RESET_MIN][i] = dsResult[i][5];
      if(dynlen(dsResult[i]) > 5)
        managersInfo[FW_INSTALLATION_MANAGER_OPTIONS][i] = dsResult[i][6];
      else
        managersInfo[FW_INSTALLATION_MANAGER_OPTIONS][i] = "";
    }
 
  return 0; 
}
	
/** This function switches between the real driver and the simulator.

@param driver	  if set to one the real driver is started, otherwise the simulator
@param name			manager type
@param number		driver number
@param host	hostname
@param port	pmon port
@param user	pmon user
@param pwd		pmon password

@return 0 if OK, -1 if error
*/
bool fwInstallationManager_switch(bool driver, 
                                  string name, 
                                  int number, 
                                  string host = "", 
                                  int port = 4999, 
                                  string user = "", 
                                  string pwd = "") 
{
  string msg = "Switching to " + (driver?"Driver":"Simulation Driver") + " for " + name;

  fwInstallation_throw(msg, "INFO", 10);

  dyn_mixed managerInfo;
  dyn_mixed simInfo;
  
  if(host == "")
  {
    host = fwInstallation_getHostname(); 
    port = pmonPort();
  }

  if(user == "")
    if(fwInstallation_getPmonInfo(user, pwd) != 0)
    {
      fwInstallation_throw("fwInstallationManager_switch: Could not resolve pmon username and password. Action aborted", "error", 1);
      return -1;
    }

  if(driver)
  {
    fwInstallation_throw("Setting simulator: -num " + number + " to " + (!driver?"always":"manual"), "INFO", 10);
    if(fwInstallationManager_setMode(fwInstallation_getWCCOAExecutable("sim"), "-num " + number, "manual", host, port, user, pwd) < 0)
    {
      fwInstallation_throw("fwInstallationManager_switch()-> Could not change simulator" + number + " start mode to manual");
      return -1;
    }
    fwInstallation_throw((!driver?"Sarting":"Stopping") + " simulator: -num " + number, "INFO", 10);
    if(fwInstallationManager_command("STOP", fwInstallation_getWCCOAExecutable("sim"), "-num " + number,  host, port, user, pwd) < 0)
    {
      fwInstallation_throw("fwInstallationManager_switch()-> Could not stop simulator" + number);
      return -1;
    }
    fwInstallationManager_waitForState(false, number);
    fwInstallation_throw("Setting driver: " + name + " -num " + number + " to " + (driver?"always":"manual"), "INFO", 10);
    if(fwInstallationManager_setMode(name, "-num " + number, "always", host, port, user, pwd) < 0)
    {
      fwInstallation_throw("fwInstallationManager_switch()-> Could not change manager: " + name + " -num " + number + " start mode to always");
      return -1;
    }
    fwInstallation_throw((driver?"Sarting":"Stopping") + " driver: " + name + " -num " + number , "INFO", 10);
    if(fwInstallationManager_command("START", name, "-num " + number,  host, port, user, pwd) < 0)
    {
      fwInstallation_throw("fwInstallationManager_switch()-> Could not start manager: " + name + " -num " + number);
      return -1;
    }
  }
  else
  {
    fwInstallation_throw("Setting driver: " + name + " -num " + number + " to " + (driver?"always":"manual"), "INFO", 10);
    if(fwInstallationManager_setMode(name, "-num " + number, "manual", host, port, user, pwd) < 0)
    {
      fwInstallation_throw("fwInstallationManager_switch()-> Could not change manager: " + name + " -num " + number + " start mode to manual");
      return -1;
    }
    fwInstallation_throw((driver?"Sarting":"Stopping") + " driver: " + name + " -num " + number , "INFO", 10);
    if(fwInstallationManager_command("STOP", name, "-num " + number,  host, port, user, pwd) < 0)
    {
      fwInstallation_throw("fwInstallationManager_switch()-> Could not stop manager: " + name + " -num " + number);
      return -1;
    }
    fwInstallationManager_waitForState(false, number);
    fwInstallation_throw("Setting simulator: -num " + number + " to " + (!driver?"always":"manual"), "INFO", 10);
    if(fwInstallationManager_setMode(fwInstallation_getWCCOAExecutable("sim"), "-num " + number, "always", host, port, user, pwd) < 0)
    {
      fwInstallation_throw("fwInstallationManager_switch()-> Could not change simulator" + number + " start mode to always");
      return -1;
    }
    fwInstallation_throw((!driver?"Sarting":"Stopping") + " simulator: -num " + number, "INFO", 10);
    if(fwInstallationManager_command("START", fwInstallation_getWCCOAExecutable("sim"), "-num " + number,  host, port, user, pwd) < 0)
    {
      fwInstallation_throw("fwInstallationManager_switch()-> Could not start simulator" + number);
      return -1;
    }
  }
  
  return 0;
}

/** This function restarts a manager.

@param name			manager type
@param commandLine		commandline for the manager
@param host	hostname
@param port	pmon port
@param user	pmon user
@param pwd		pmon password

@return 0 if OK, -1 if error
*/
int fwInstallationManager_restart(string name, 
                                  string commandLine, 
                                  string host = "", 
                                  int port = 4999, 
                                  string user = "", 
                                  string pwd = "") 
{  
  return fwInstallationManager_command("RESTART", name, commandLine, host, port, user, pwd);
  
 /* 
  int max = 30; //max allowed waiting time 30s
  dyn_mixed info;
  
  if(host == "")
  {
    host = fwInstallation_getHostname(); 
    port = pmonPort();
  }
  
  if(user == "")
    if(fwInstallation_getPmonInfo(user, pwd) != 0)
    {
      fwInstallation_throw("fwInstallationManager_restart: Could not resolve pmon username and password. Action aborted", "error", 1);
      return -1;
    }

  fwInstallationManager_getProperties(name, commandLine, info, host, port, user, pwd);
  bool wasItAlways = false;
  if(strtolower(info[FW_INSTALLATION_MANAGER_START_MODE]) == "always")
    wasItAlways = true;
  
  fwInstallationManager_command("STOP", name, commandLine, host, port, user, pwd);
  //See if it is necessary to start it:  
  if(!wasItAlways)
  {
    //wait for the manager to stop:
    int n = 0;
    bool state = false;
    do
    {
      fwInstallationManager_isRunning(name, commandLine, state, host, port, user, pwd);      
      ++n;
      delay(1);
    }while(n < max && state);
    
    if(n >= max && state) //timeout reached!
    {
      fwInstallation_throw("fwInstallationManager_restart() -> Timeout (" + max + "s) exceeded and manager still running: " + name + " " + commandLine, "WARNING", 10);
      return -1;
    }
    
    fwInstallationManager_command("START", name, commandLine, host, port, user, pwd);
  }
  
  return 0;  
  */
}

/** This function wait for a manager to be in a particular state

@param running	 if set to one the function waits for the manager to be running, otherwise to be stopped
@param number		driver number
@param retries	how many time to retry
@param systemName	name of the pvss system where to check the state of the manager

@return 0 if OK, -1 if error
*/
void fwInstallationManager_waitForState(bool running, int number, int retries=0, string systemName = "") 
{
  dyn_anytype returnValues;
  time t = 60;
  bool timerExpired;
  dyn_anytype condition;
  dyn_int drivers;

  if(systemName == "")
    systemName = getSystemName();

  //Check if the manager is already running:
  dpGet(systemName + "_Connections.Driver.ManNums", drivers);
  if((dynContains(drivers, number) > 0 && running) ||
     (dynContains(drivers, number) <= 0 && !running))
  {
    //Manager already in the desired state, nothing to be done:
    return;
  }
  
  
  fwInstallation_throw("fwInstallationManager_waitForState()->Waiting for manager " + number + " to " + (running?"START":"STOP"), "INFO", 10);
  if (dpWaitForValue(makeDynString(systemName + "_Connections.Driver.ManNums:_original.._value"),condition, 
		     makeDynString(systemName + "_Connections.Driver.ManNums:_original.._value"), returnValues, t, timerExpired) == -1) 
  {
    delay(5);
  }
  
  if (timerExpired)
  {
    fwInstallation_throw("fwInstallationManager_waitForState()->Timer expired. Manager " + number + " has not " + (running?"STARTED":"STOPPED"));
  }
  
  if (fwInstallationManager_isDriverRunning(number, systemName)== running) 
  {
    fwInstallation_throw("fwInstallationManager_waitForState()->Ok, manager " +number + " " + (running?"STARTED":"STOPPED"), "INFO", 10);
    return;
  } 
  else 
  {
    fwInstallation_throw("fwInstallationManager_waitForState()->Manager: " + number +" is still " + (!running?"STARTED":"STOPPED"), "WARNING", 10);
    if (retries==3) 
    {
      fwInstallation_throw("fwInstallationManager_waitForState()->Giving up after three failed attemps");
      return ;
    }  
    else 
    {
      fwInstallationManager_waitForState(running, number,  ++retries, systemName, host, port, user, pwd);
    }
  }
}

/** This function wait for a manager to be in a particular state

@param running		(in)	if true the desired state of the manager is running, 
                 otherwise it is stopped
@param manager		(in)	type of the pvss manager
@param commandLine		(in) manager options
@param timeout	 (int)	how long to wait for in seconds. Default value is 30s
@param timeout	 (in)	if true, the time has expired, otherwise the manager 
                reached the desired state within the timeout time
@param host	(in) hostname
@param port	(in) pmon port
@param user	(in) pmon user
@param pwd		(in) pmon password
*/
void fwInstallationManager_wait(bool running,
                                string manager,
                                string commandLine, 
                                int timeout = 30,
                                bool &expired,
                                string host = "",
                                int port = 4999, 
                                string user = "", 
                                string pwd = "")
{
  time t = 0;
  expired = false;
  bool state = false;

  if(host == "")
  {
    host = fwInstallation_getHostname(); 
    port = pmonPort();
  }
  
  if(user == "")
    if(fwInstallation_getPmonInfo(user, pwd) != 0)
    {
      fwInstallation_throw("fwInstallationManager_wait: Could not resolve pmon username and password. Action aborted", "error", 1);
      return -1;
    }
  
  do
  {
    fwInstallationManager_isRunning(manager, commandLine, state, host, port, user, pwd); 
    ++t;
  }while (state != running || t <= timeout);
  
  if(state != running && t >= timeout)
  {
    expired = true;
    return;
  }
  
  return;
}


/** This function checks if a manager is running or not

@param manager		(in)	type of the pvss manager
@param commandLine		(in) manager options
@param isRunning	 (out)	manager state. If 1 the manager runs, otherwise it is stopped
@param host	(in) hostname
@param port	(in) pmon port
@param user	(in) pmon user
@param pwd		(in) pmon password

@return 0 if OK, -1 if error
*/

int fwInstallationManager_isRunning(string manager,
                                    string commandLine, 
                                    bool &isRunning,
                                    string host = "",
                                    int port = 4999, 
                                    string user = "", 
                                    string pwd = "")
{
  dyn_dyn_string ddsStates;
  
  if(host == "")
  {
    host = fwInstallation_getHostname(); 
    port = pmonPort();
  }
  
  if(user == "")
    if(fwInstallation_getPmonInfo(user, pwd) != 0)
    {
      fwInstallation_throw("fwInstallationManager_isRunning: Could not resolve pmon username and password. Action aborted", "error", 1);
      return -1;
    }

  string str = user + "#" + pwd + "#MGRLIST:STATI";
  isRunning = false;

  dyn_mixed managerInfo;
  fwInstallationManager_getProperties(manager, commandLine, managerInfo, host, port, user, pwd);
  
  if(managerInfo[FW_INSTALLATION_MANAGER_PMON_IDX] < 0 )
  {
//    fwInstallation_throw("WARNING: fwInstallationDBAgent_isManagerRunning() -> Could not check if manager is running: " + manager + " " + commandLine);
    return -1;
  }
  
  if(pmon_query(str, host, port, ddsStates, FALSE, TRUE))
  {
    fwInstallation_throw("WARNING: fwInstallationDBAgent_isManagerRunning() -> failed to execute pmon query");
    return -1;
  }
  
//DebugN(ddsStates, managerInfo, managerInfo[FW_INSTALLATION_MANAGER_PMON_IDX] + 1);

  if(ddsStates[managerInfo[FW_INSTALLATION_MANAGER_PMON_IDX]+1][1] == "2")
  {
    isRunning = 1; 
  }
  
  return 0;
}

/** This function checks if a driver is running.

@param number		driver number
@param systemName	PVSS system where to find the manager
@return true if the driver runs, false otherwise
*/
bool fwInstallationManager_isDriverRunning(int number, string systemName = "") 
{
  dyn_int drivers;
  if(systemName == "")
    systemName = getSystemName();
  
  dpGet(systemName + "_Connections.Driver.ManNums", drivers);
  
  return dynContains(drivers, number);
}


/** This function retrieves the manager properties

@param type	type of manager
@param options	manager options
@param properties manager properties
@param host	hostname
@param port	pmon port
@param user	pmon user
@param pwd		pmon password
@return 0 if OK, -1 if error
*/
int fwInstallationManager_getProperties(string type, 
                                        string options, 
                                        dyn_mixed &properties, 
                                        string host = "", 
                                        int port = 4999, 
                                        string user = "", 
                                        string pwd = "")
{
  if(host == "")
  {
    host = fwInstallation_getHostname(); 
    port = pmonPort();
  }
  
  if(user == "")
    if(fwInstallation_getPmonInfo(user, pwd) != 0)
    {
      fwInstallation_throw("fwInstallationManager_getProperties: Could not resolve pmon username and password. Action aborted", "error", 1);
      return -1;
    }
  
  string cmd = user + "#" + pwd + "#MGRLIST:LIST";
  dyn_dyn_string res;
  bool found = false;
  bool failed = pmon_query(cmd, host, port, res, false, true);
  
  if(failed) 
  {
    fwInstallation_throw("fwInstallationManager_getProperties()-> Could not read manager properties via PMON. Query on host: " + host + " PMON port: " + port);
    dynClear(properties);
    properties[FW_INSTALLATION_MANAGER_PMON_IDX] = -1;
    return -1;
  }    
  
  
  for (int i=1;i <= dynlen(res); i++) 
  {
    if (strtoupper(res[i][1]) == strtoupper(type))
    { 
      if(dynlen(res[i]) >= 5 && (options == "" || 
                                (dynlen(res[i]) >= 6 && ((res[i][6] == options)  || patternMatch("*" + options + "*", res[i][6])))))
      {
        found = true;
        properties[FW_INSTALLATION_MANAGER_PMON_IDX] = i-1;
        properties[FW_INSTALLATION_MANAGER_TYPE] = res[i][1];
        properties[FW_INSTALLATION_MANAGER_START_MODE] = res[i][2];
        properties[FW_INSTALLATION_MANAGER_SEC_KILL] = res[i][3];
        
        if(res[i][3]>=0)
          properties[FW_INSTALLATION_MANAGER_DONT_STOP_RESTART] = 0;
        else
          properties[FW_INSTALLATION_MANAGER_DONT_STOP_RESTART] = 1;
          
        properties[FW_INSTALLATION_MANAGER_RESTART_COUNT] = res[i][4];
        properties[FW_INSTALLATION_MANAGER_RESET_MIN] = res[i][5];
        properties[FW_INSTALLATION_MANAGER_PMON_USER] = user;
        properties[FW_INSTALLATION_MANAGER_PMON_PWD] = pwd;
        properties[FW_INSTALLATION_MANAGER_PMON_PORT] = port;
        properties[FW_INSTALLATION_MANAGER_HOST] = host;
        
        if(dynlen(res[i]) > 5)
          properties[FW_INSTALLATION_MANAGER_OPTIONS] = res[i][6];
        else
          properties[FW_INSTALLATION_MANAGER_OPTIONS] = "";

        break;
      }
    }
  }
  
  if(!found)
  {
    dynClear(properties);
    //fwInstallation_throw("Manager: " + type + ", Options: " + options + ", Host: " + host + ", PMON Port: " + port + " not found in project", "WARNNIG", 1);
    properties[FW_INSTALLATION_MANAGER_PMON_IDX] = -1;    
  }
  
  return 0;
}

/** This function sets the manager properties

@param type	type of manager
@param currentOptions	manager options
@param properties manager properties
@param host	hostname
@param port	pmon port
@param user	pmon user
@param pwd		pmon password
@return 0 if OK, -1 if error
*/
int fwInstallationManager_setProperties(string type, 
                                        string currentOptions, 
                                        dyn_mixed properties, 
                                        string host = "", 
                                        string port = 4999,
                                        string user = "",
                                        string pwd = "")
{
  if(host == "")
  {
    host = fwInstallation_getHostname(); 
    port = pmonPort();
  }
  
  if(user == "")
    if(fwInstallation_getPmonInfo(user, pwd) != 0)
    {
      fwInstallation_throw("fwInstallationManager_setProperties: Could not resolve pmon username and password. Action aborted", "error", 1);
      return -1;
    }
  
  if(dynlen(properties) < FW_INSTALLATION_MANAGER_RESET_MIN)
  {
    fwInstallation_throw("fwInstallationManager_setProperties()-> Invalid number of elemnts in dyn_mixed properties variable passed to the function");
    return -1;
  }

  //Find manager pmon index:
  dyn_mixed oldProperties;
  if(fwInstallationManager_getProperties(type, 
                                      currentOptions, 
                                      oldProperties, 
                                      host, 
                                      port, 
                                      user, 
                                      pwd) != 0)
  {
    fwInstallation_throw("fwInstallationManager_setProperties()-> Failed to find manager: " + type + " Options: " + currentOptions + " on host: "  + host + " Port: " + port);    
    return -1;
  }
  
  int index = oldProperties[FW_INSTALLATION_MANAGER_PMON_IDX];
  if(index == -1)
  {
    fwInstallation_throw("fwInstallationManager_setProperties()-> Could not find manager: " + type + " Options: " + currentOptions + " on host: "  + host + " Port: " + port, "WARNING", 1);    
    return -1;
  }
  
  //Set new properties
  string mode;
  string options = properties[FW_INSTALLATION_MANAGER_OPTIONS];
  int restartCount = properties[FW_INSTALLATION_MANAGER_RESTART_COUNT];
  int resetMin = properties[FW_INSTALLATION_MANAGER_RESET_MIN];
  int sKill = properties[FW_INSTALLATION_MANAGER_SEC_KILL];
  bool noStop = false;
  string command;  
  bool err;
  
  if(dynlen(properties) >= FW_INSTALLATION_MANAGER_DONT_STOP_RESTART)
    noStop = properties[FW_INSTALLATION_MANAGER_DONT_STOP_RESTART];
    
  
  switch(properties[FW_INSTALLATION_MANAGER_START_MODE])
  {
    case 0: mode = "manual"; break;
    case 1: mode = "once"; break;
    case 2: mode = "always"; break;
  } 
  
  command = user + "#" + pwd + "#SINGLE_MGR:PROP_PUT "+ index + " " + 
            mode + " " + (noStop?-sKill:sKill) + " " + restartCount + " " + 
            resetMin + " "+ options;
  
  err = pmon_command(command, host, port, false, true);
  
  if(err)
  {
    fwInstallation_throw("fwInstallationManager_setProperties()-> Could not set manager properties via PMON: " + type + " current options: " + currentOptions +". Command on host: " + host + " PMON port: " + port);
    return -1;
  }
  
  return 0;
}
