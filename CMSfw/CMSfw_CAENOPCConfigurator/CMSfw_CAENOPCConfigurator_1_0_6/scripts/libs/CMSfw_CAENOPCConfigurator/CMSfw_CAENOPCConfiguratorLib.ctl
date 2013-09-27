// CMSfw_CAENOPCConfiguratorLib.ctl
// CTRL Library
//
// Developped by: Georgi Aleksandrov Leshev - ETH Zurich 
// Modified by: Lorenzo Masetti
// CERN CMS Experiment
//
bool CMSfw_CAENOPCConfiguration_debug = true;

void CMSfw_CAENOPCConfiguration_exec(string cmd) {
    if (CMSfw_CAENOPCConfiguration_debug) DebugTN("CAEN OPC Configurator: executing " + cmd);
    system(cmd);
}

string CMSfw_CAENOPCConfigurator_getPath() {
  string   path = getPath(SCRIPTS_REL_PATH );
  path = path + "/CMSfw_CAENOPCConfigurator/CAEN_User/";
  return path;  
}

dyn_string CMSfw_CAENOPCConfigurator_retrieveEntries(string path)
{
  // Clear the intermediate files
  CMSfw_CAENOPCConfiguration_exec("wscript "+'"'+path+"WinDeleteFile.vbs"+'"'+" "+path);
  CMSfw_CAENOPCConfiguration_exec("wscript "+'"'+path+"WinCreateFile.vbs"+'"'+" "+path);

  // Take the data from the Registry through an external script
  CMSfw_CAENOPCConfiguration_exec("wscript "+'"'+path+"OPCReadCrate.vbs"+'"'+" "+path);
  
  // Delay in for completion of the external operation.
  delay(1);
    
  dyn_string rawResult = makeDynString();
  
  dyn_string Result= makeDynString();
  
  string fname=path+"RegOutput.txt";
  
  string st;
  file f;
  int i;
  
  i=access(fname,F_OK); 
  
  // Open the file containing the data 
  if (!i) // File exists 
  {
    f=fopen(fname,"r"); 
    while (feof(f)==0) // as long as it is not at the end of the file
    {
      fgets(st,40,f); // Import string 
      
      if (st != "")
      {
        dynAppend(rawResult,st); // ...and output it
      }
    }
 
    fclose(f); 
  }
  else 
  {
    // Error checking
    string cat, errNote;
    int prio,typ,co;
  
    cat ="_errors"; 
   
    prio = PRIO_INFO; 
    typ =ERR_PARAM;
    co = 0; 
    
    errClass retError; 
       
    errNote = "RegOutput.txt file is not accessible and can't be open.";
    retError=makeError(cat,prio,typ,co,errNote);
    errorDialog(retError);
    
    // In case of error return the following:
    Result = makeDynString("Error, 0, ----");
     
    return Result;
  }
 
  Result = rawResult;
  
  return Result;
}

int CMSfw_CAENOPCConfigurator_DeleteCAENEntries(string path)
{
  // Clear the intermediate files
  CMSfw_CAENOPCConfiguration_exec("wscript "+'"'+path+"WinDeleteFile.vbs"+'"'+" "+path);
  CMSfw_CAENOPCConfiguration_exec("wscript "+'"'+path+"WinCreateFile.vbs"+'"'+" "+path);
  
  // Delete the entries in the Registry through an external script
  CMSfw_CAENOPCConfiguration_exec("wscript "+'"'+path+"OPCDeleteAll.vbs"+'"'+" "+path);
  
  // Wait a little to complete the execution of the external script
  delay(4);
  
  string fname=path+"RegOutput.txt";
  
  string st;
  file f;
  int i;
  
  // j is a counter that make additional waiting until the operation is completed successfuly
  int j = 30;
  while (j)
  {
    i=access(fname,F_OK); 
        
    // Open the file containing the data 
    if (!i) // File exists 
    {
      f=fopen(fname,"r"); 
      while (feof(f)==0) // as long as it is not at the end of the file
      {
        fgets(st,40,f); // Import string 
        
        // If the operation is successfull
        if (st != "ok")
        {
          // First close the file !!! and then return
          fclose(f); 
          return 0; // ...and return to refresh
        }
      }
      
    }
    else 
    {
      // Error checking
      string cat, errNote;
      int prio,typ,co;
    
      cat ="_errors"; 
     
      prio = PRIO_INFO; 
      typ =ERR_PARAM;
      co = 0; 
      
      errClass retError; 
         
      errNote = "RegOutput.txt file is not accessible and can't be open.";
      retError=makeError(cat,prio,typ,co,errNote);
      errorDialog(retError);
      
      // return -1 in case of error
      return -1;
      
    }
    
    --j;
    delay(0, 100);
  }  
  
  if (!j)
  {
    return -1;
  }
  
}

int CMSfw_CAENOPCConfigurator_AddEntry(string path, string crateName, string crateIP)
{
  // Clear the intermediate files
  CMSfw_CAENOPCConfiguration_exec("wscript "+'"'+path+"WinDeleteFile.vbs"+'"'+" "+path);
  CMSfw_CAENOPCConfiguration_exec("wscript "+'"'+path+"WinCreateFile.vbs"+'"'+" "+path);

  dyn_string rawRes = CMSfw_CAENOPCConfigurator_retrieveEntries(path);
  dyn_string spl;
//  DebugN("Current entries ", rawRes);
  for (int i=1; i<= dynlen(rawRes); i++) {
    spl = strsplit(rawRes[i], ",");
    if (dynlen(spl)<3) continue;
    if ((spl[1] == crateName) || (spl[3] == crateIP)) {
        DebugN("Entry is already present"); return -1;
    }
  }  
  
  
  
  // Add entry in the Registry through an external script
  CMSfw_CAENOPCConfiguration_exec("wscript "+'"'+path+"OPCRegCrate.vbs"+'"'+" "+path+" "+crateName+" "+crateIP);
  
  // Wait a little to complete the execution of the external script
  delay(4);
  
  string fname=path+"RegOutput.txt";
  
  string st;
  file f;
  int i;
  
  // j is a counter that make additional waiting until the operation is completed successfuly
  int j = 30;
  while (j)
  {
    i=access(fname,F_OK); 
        
    // Open the file containing the data 
    if (!i) // File exists 
    {
      f=fopen(fname,"r"); 
      while (feof(f)==0) // as long as it is not at the end of the file
      {
        fgets(st,40,f); // Import string 
        
        // If the operation is successfull
        if (st != "ok")
        {
          // First close the file !!! and then return
          fclose(f); 
          return 0; // ...and return to refresh
        }
      }
      
    }
    else 
    {
      // Error checking
      string cat, errNote;
      int prio,typ,co;
    
      cat ="_errors"; 
     
      prio = PRIO_INFO; 
      typ =ERR_PARAM;
      co = 0; 
      
      errClass retError; 
         
      errNote = "RegOutput.txt file is not accessible and can't be open.";
      retError=makeError(cat,prio,typ,co,errNote);
      errorDialog(retError);
      
      // return -1 in case of error
      return -1;
      
    }
    
    --j;
    delay(0, 100);
  }  
  
  if (!j)
  {
    return -1;
  }
}

int CMSfw_CAENOPCConfigurator_RestartServer(string path)
{
  // Add entry in the Registry through an external script
  CMSfw_CAENOPCConfiguration_exec("wscript "+'"'+path+"terminateOPCServer.vbs"+'"');
  
  // Wait a little to complete the execution of the external script
  delay(4);
  
  return 0;
 
}

int CMSfw_CAENOPCConfigurator_statusOPCManager()
{
  //  Take the pmon port and current host.
  string host;
  int port;
  int i = paGetProjHostPort( PROJ, host, port);
   
  //  Use pmon query to take the Idx of the important managers
  string command ="##MGRLIST:LIST";
  dyn_dyn_string queryResult;
      
  bool querySuccess = pmon_query(command , host, port,
           queryResult, 1, 1 );
  
  //  Remember the Idx of the sim manager
  int simIdx;
  for (i = 1; i <= dynlen(queryResult); i++)
  {
    if ((queryResult[i][1] == "PVSS00sim")&&(dynlen(queryResult[i]) == 6))
    {
      if (queryResult[i][6] == "-num 6")
      {
        simIdx = i - 1; 
        break;
      }
    }
  }
    
  //  Remember the Idx of the opc manager
  int opcIdx;
  for (int i = 1; i <= dynlen(queryResult); i++)
  {
    if (queryResult[i][1] == "PVSS00opc")
    {
      if (queryResult[i][6] == "-num 6")
      {
        opcIdx = i - 1; 
        break;
      }
    }
  }
  
  string command ="##MGRLIST:STATI";
    
  bool querySuccess = pmon_query(command , host, port,
           queryResult, 1, 1 );

  // If the Caen driver is not running 
  if (queryResult[opcIdx+1][1] == 0)
  { 
    return 1;  
  }
  else if (queryResult[opcIdx+1][1] == 2)
  {
    return 2;
  }
  else
    return 3;
}

int CMSfw_CAENOPCConfigurator_stopOPCManager()
{
  // Stop any Caen driver. 
 
  //  Take the pmon port and current host.
  string host;
  int port;
  int i = paGetProjHostPort( PROJ, host, port);
   
  //  Use pmon query to take the Idx of the important managers
  string command ="##MGRLIST:LIST";
  dyn_dyn_string queryResult;
      
  bool querySuccess = pmon_query(command , host, port,
           queryResult, 1, 1 );
  
  //  Remember the Idx of the sim manager
  int simIdx;
  string simMode = "empty";
  
  for (i = 1; i <= dynlen(queryResult); i++)
  {
    if ((queryResult[i][1] == "PVSS00sim")&&(dynlen(queryResult[i]) == 6))
    {
      if (queryResult[i][6] == "-num 6")
      {
        simIdx = i - 1; 
        
        if (queryResult[i][2] == 2)
        {
          simMode = "always";
        }
        
        break;
      }
    }
  }
    
  //  Remember the Idx of the opc manager
  int opcIdx = -1;
  string opcMode = "empty";
  
  for (int i = 1; i <= dynlen(queryResult); i++)
  {
    if (queryResult[i][1] == "PVSS00opc")
    {
      if (queryResult[i][6] == "-num 6")
      {
        opcIdx = i - 1; 
        
        if (queryResult[i][2] == 2)
        {
          opcMode = "always";
        }
       
        break;
      }
    }
  }
  if (opcIdx == -1) {
    DebugN("No OPC client found ");
    return 1;
  }  
  
  if (opcMode == "always")
  {
   
    // make opc mode - "manual" and stop it.
    string command2 ="##SINGLE_MGR:PROP_PUT "+opcIdx+" manual 30 2 2 -num 6";
         
    bool querySuccess2 = pmon_command(command2 , host, port, 0, 1 );

    delay(0,100);
      
    string command3 ="##SINGLE_MGR:STOP "+opcIdx;
          
    bool querySuccess3 = pmon_command(command3 , host, port, 0, 1 );
      
      
    // wait until the opc is fully stoped
    string command ="##MGRLIST:STATI";
    dyn_dyn_string queryResult;
    
    bool querySuccess = pmon_query(command , host, port,
           queryResult, 1, 1 );
     
    if (queryResult[opcIdx+1][1] != 0)	
    {
      bool Started = 1;

      while(Started)
      {
	// use pmon query to find out if the driver is running
  	string command ="##MGRLIST:STATI";
 	bool querySuccess = pmon_query(command , host, port, queryResult, 1, 1 );

	if (queryResult[opcIdx+1][1] == 0)
        {
	  Started = 0;
        }
	  delay(0, 100);
      }
    }
   
  }
  else 
  {
    
    // wait until the sim is fully stoped
    string command ="##MGRLIST:STATI";
    dyn_dyn_string queryResult;
    
    bool querySuccess = pmon_query(command , host, port,
           queryResult, 1, 1 );
    
    // if opc is running - Stop.
    if (queryResult[opcIdx+1][1] == 2)
    {
      string command3 ="##SINGLE_MGR:STOP "+opcIdx;
            
      bool querySuccess3 = pmon_command(command3 , host, port, 0, 1 );
      
      // wait until the opc is fully stoped
      string command ="##MGRLIST:STATI";
      dyn_dyn_string queryResult;
    
      bool querySuccess = pmon_query(command , host, port,
           queryResult, 1, 1 );
     
      if (queryResult[opcIdx+1][1] != 0)	
      {
        bool Started = 1;

        while(Started)
        {
	  // use pmon query to find out if the driver is running
  	  string command ="##MGRLIST:STATI";
 	  bool querySuccess = pmon_query(command , host, port, queryResult, 1, 1 );

	  if (queryResult[opcIdx+1][1] == 0)
          {
	    Started = 0;
          }
	  delay(0, 100);
        }
      }
      
    }
    
  }
  
  return 1;
  
}

int CMSfw_CAENOPCConfigurator_startOPCManager()
{
  //  Check for Caen driver is running and if not start it.
 
  //  Take the pmon port and current host.
  string host;
  int port;
  int i = paGetProjHostPort( PROJ, host, port);
   
  //  Use pmon query to take the Idx of the important managers
  string command ="##MGRLIST:LIST";
  dyn_dyn_string queryResult;
      
  bool querySuccess = pmon_query(command , host, port,
           queryResult, 1, 1 );
  
  //  Remember the Idx of the sim manager
  int simIdx;
  string simMode = "empty";
  
  for (i = 1; i <= dynlen(queryResult); i++)
  {
    if ((queryResult[i][1] == "PVSS00sim")&&(dynlen(queryResult[i]) == 6))
    {
      if (queryResult[i][6] == "-num 6")
      {
        simIdx = i - 1; 
        
        if (queryResult[i][2] == 2)
        {
          simMode = "always";
        }
        
        break;
      }
    }
  }
    
  //  Remember the Idx of the opc manager
  int opcIdx = -1;
  string opcMode = "empty";
  
  for (int i = 1; i <= dynlen(queryResult); i++)
  {
    if (queryResult[i][1] == "PVSS00opc")
    {
      if (queryResult[i][6] == "-num 6")
      {
        opcIdx = i - 1; 
        
        if (queryResult[i][2] == 2)
        {
          opcMode = "always";
        }
       
        break;
      }
    }
  }
  if (opcIdx == -1) {
      DebugN("OPC Client not found"); return 1;      
  }

  //
  //  There are 3 situations:
  //  1)  opc running as "always"  ---  action:  check for Error
  //  2)  sim running as "always"  ---  action:  stop sim and run opc as "always"
  //  3)  sim or opc running as "manual", or nothing is running  ---  action:  stop sim if running and make opc run "always"
  //
  
  string cat, errNote;
  int prio,typ,co;
  
  cat ="_errors"; 
   
  prio = PRIO_INFO; 
  typ =ERR_PARAM;
  co = 0; 
  
  errClass retError;            
    
  if (opcMode == "always")
  {
    
    string command ="##MGRLIST:STATI";
    dyn_dyn_string queryResult;
    
    bool querySuccess = pmon_query(command , host, port,
           queryResult, 1, 1 );
    
    if (queryResult[opcIdx+1][1] != 2)
    {
      // Error checking
      errNote = "There is some problem with the PVSS system - the mode of the Opc Manager is Always but it is not running";
      retError=makeError(cat,prio,typ,co,errNote);
      errorDialog(retError);
    }
  }
  
  else if (simMode == "always")
  {

    string command ="##MGRLIST:STATI";
    dyn_dyn_string queryResult;
    
    bool querySuccess = pmon_query(command , host, port,
           queryResult, 1, 1 );
    
    if (queryResult[simIdx+1][1] == 2)
    {
     
      // make sim mode - "manual" and stop it.
      string command2 ="##SINGLE_MGR:PROP_PUT "+simIdx+" manual 30 2 2 -num 6";
         
      bool querySuccess2 = pmon_command(command2 , host, port, 0, 1 );

      delay(0,100);
      
      string command3 ="##SINGLE_MGR:STOP "+simIdx;
          
      bool querySuccess3 = pmon_command(command3 , host, port, 0, 1 );
      
      
      // wait until the sim is fully stoped
      string command ="##MGRLIST:STATI";
      dyn_dyn_string queryResult;
    
      bool querySuccess = pmon_query(command , host, port,
           queryResult, 1, 1 );
     
      if (queryResult[simIdx+1][1] != 0)	
      {
	bool Started = 1;

	while(Started)
	{
	  // use pmon query to find out if the driver is running
  	  string command ="##MGRLIST:STATI";
 	  bool querySuccess = pmon_query(command , host, port, queryResult, 1, 1 );

	  if (queryResult[simIdx+1][1] == 0)
          {
	    Started = 0;
          }
	  delay(0, 100);
	}
      }
      
      // make the opc mode "always"
      
      string command = "##SINGLE_MGR:START "+opcIdx;
    
      bool querySuccess = pmon_command(command , host, port, 0, 1 );
    
      delay(0, 100);
      
      string command2 ="##SINGLE_MGR:PROP_PUT "+opcIdx+" always 30 2 2 -num 6";
         
      bool querySuccess2 = pmon_command(command2 , host, port, 0, 1 );

      delay(0,100);
      
      // Wait until the opc is fully started.      
      string command ="##MGRLIST:STATI";
      dyn_dyn_string queryResult;
    
      bool querySuccess = pmon_query(command , host, port,
           queryResult, 1, 1 );
          
      if (queryResult[opcIdx+1][1] != 2)	
      {
	bool notStarted = 1;
        int Counter = 200;
        
	while(notStarted && Counter)
	{
	  // use pmon query to find out if the driver is running
  	  string command ="##MGRLIST:STATI";
 	  bool querySuccess = pmon_query(command , host, port, queryResult, 1, 1 );

	  if (queryResult[opcIdx+1][1] == 2)
          {
	    notStarted = 0;
          }
          --Counter;
	  delay(0, 100);
	}
      }
      
    }
  }
  else 
  {
    string command ="##MGRLIST:STATI";
    dyn_dyn_string queryResult;
    
    bool querySuccess = pmon_query(command , host, port, queryResult, 1, 1 );
    
    // if sim is running - stop it
    if (queryResult[simIdx+1][1] == 2)
    {
      string command3 ="##SINGLE_MGR:STOP "+simIdx;
          
      bool querySuccess3 = pmon_command(command3 , host, port, 0, 1 );
      
      
      // wait until the sim is fully stoped
      string command ="##MGRLIST:STATI";
      dyn_dyn_string queryResult;
    
      bool querySuccess = pmon_query(command , host, port,
           queryResult, 1, 1 );
     
      if (queryResult[simIdx+1][1] != 0)	
      {
	bool Started = 1;

	while(Started)
	{
	  // use pmon query to find out if the driver is running
  	  string command ="##MGRLIST:STATI";
 	  bool querySuccess = pmon_query(command , host, port, queryResult, 1, 1 );

	  if (queryResult[simIdx+1][1] == 0)
          {
	    Started = 0;
          }
	  delay(0, 100);
	}
      }
    }     
    
    string command = "##SINGLE_MGR:START "+opcIdx;
    
    bool querySuccess = pmon_command(command , host, port, 0, 1 );
    
    delay(0, 100);
    
    // make the opc mode - "always"
    string command2 ="##SINGLE_MGR:PROP_PUT "+opcIdx+" always 30 2 2 -num 6";
         
    bool querySuccess2 = pmon_command(command2 , host, port, 0, 1 );

    delay(0,100);
     
    // Wait until the opc is fully started.   
    string command ="##MGRLIST:STATI";
    dyn_dyn_string queryResult;
    
    bool querySuccess = pmon_query(command , host, port,
           queryResult, 1, 1 );
     
    if (queryResult[opcIdx+1][1] != 2)	
    {
      bool notStarted = 1;
      int Counter = 200;
        
      while(notStarted && Counter)
      {
	// use pmon query to find out if the driver is running
  	string command ="##MGRLIST:STATI";
 	bool querySuccess = pmon_query(command , host, port, queryResult, 1, 1 );

	if (queryResult[opcIdx+1][1] == 2)
        {
	  notStarted = 0;
        }
        --Counter;
	delay(0, 100);
      }
    } 
  }
  return 1;
}


int CMSfw_CAENOPCConfigurator_ConfigureOPC(dyn_string names, dyn_string ips, bool restart_driver = true) {
  if (dynlen(names) != dynlen(ips)) {
    DebugN("Dynlen for names and ips does not match");
    return -1;
  }
  string path;
 
  path = CMSfw_CAENOPCConfigurator_getPath();
		
  CMSfw_CAENOPCConfigurator_stopOPCManager();
  if (CMSfw_CAENOPCConfigurator_DeleteCAENEntries(path) == -1) return -1;
  int result = 0;
  for (int i=1; i<= dynlen(names); i++) {
    if (CMSfw_CAENOPCConfigurator_AddEntry(path, names[i], ips[i]) == -1) result = -1;
  }    
  
  if (restart_driver) {
    CMSfw_CAENOPCConfigurator_startOPCManager();
  }
  return result;
  
} 

bool CMSfwCAENOPCConfiguration_setConfigurationForSystem(dyn_string crates, dyn_string ips, string  systemName = "") {
  if (! dpExists(systemName + "OPC_Conf_General.configuration.set.crates") ) return false;
  dpSetWait(systemName + "OPC_Conf_General.configuration.set.crates", crates,
            systemName + "OPC_Conf_General.configuration.set.ips", ips);
  return true;   
}

/* Returns -1 error
           1 already set (nothing changed)
           2 changed
*/           
           
int CMSfwCAENOPCConfiguration_applyConfigurationForSystem(dyn_string& exc, string systemName = "") {
  if (! dpExists(systemName + "OPC_Conf_General.configuration.set.crates") ) {    
    fwException_raise(exc, "DP_DOES_NOT_EXIST", systemName + "OPC_Conf_General does not exist" ,0);
    return -1;
  }          
    
  // get current configuration
  dpSet(systemName + "OPC_Conf_General.regInput.idOperation", 8);
     
  time t;
  dyn_string dpNamesWait, dpNamesReturn;
  dyn_anytype conditions, returnValues;
  int status;
  bool timerExpired;
  int res;
   
  dpNamesWait = makeDynString(systemName+"OPC_Conf_General.regInput.idOperation:_original.._value");
  conditions[1] = 0;
  dpNamesReturn = makeDynString( systemName +"OPC_Conf_General.regInput.idOperation:_online.._value" );
  t = 40;

  // Wait until the operation is completed - code 0
  status = dpWaitForValue( dpNamesWait, conditions, dpNamesReturn, returnValues, t , timerExpired);
  if (status == -1) {
    fwException_raise(exc, "PROBLEM", "Problem in dpWaitForValue" ,0);
    return -1;
  }  
  if (timerExpired) {
     fwException_raise(exc, "PROBLEM", "Timer expired in dpWaitForValue" ,0);
    return -1;
  }
  dpGet(systemName + "OPC_Conf_General.regOutput.intResult", res);
  if (res == -1) {
    fwException_raise(exc, "GET_FAILED", "Problems in getting current configuration" ,0);
    return -1;
  }
    
  dyn_string set_crates, set_ips, get_crates, get_ips;
  dpGet(systemName + "OPC_Conf_General.configuration.set.crates", set_crates,
        systemName + "OPC_Conf_General.configuration.set.ips", set_ips,
        systemName + "OPC_Conf_General.configuration.get.crates", get_crates,
        systemName + "OPC_Conf_General.configuration.get.ips", get_ips      
        );
  
  int ok = true;
  
  if (dynlen(set_crates) != dynlen(get_crates)) {
      ok = false;
   } else {
     for (int i=1; i<= dynlen(set_crates); i++) {
       if ((set_crates[i] != get_crates[i]) || (set_ips[i] != get_ips[i])) {
           ok = false;
           break;
       }
     }       
   }
   if (ok) return 1;
       
  // set current configuration
  dpSet(systemName + "OPC_Conf_General.regInput.idOperation", 9);

  dpNamesWait = makeDynString(systemName+"OPC_Conf_General.regInput.idOperation:_original.._value");
  conditions[1] = 0;
  dpNamesReturn = makeDynString(systemName+"OPC_Conf_General.regInput.idOperation:_online.._value" );
  t = 120;

  // Wait until the operation is completed - code 0
  status = dpWaitForValue( dpNamesWait, conditions, dpNamesReturn, returnValues, t );
 if (status == -1) {
    fwException_raise(exc, "PROBLEM", "Problem in dpWaitForValue" ,0);
    return -1;
  }  
  if (timerExpired) {
     fwException_raise(exc, "PROBLEM", "Timer expired in dpWaitForValue" ,0);
    return -1;
  }

  dpGet(systemName + "OPC_Conf_General.regOutput.intResult", res);
  
  if (res == -1) {
    fwException_raise(exc, "SET_FAILED", "Problems in setting new configuration" ,0);
    return -1;
  }
  return 2;   
}



int CMSfwCAENOPCConfiguration_getConfigurationForSystem(dyn_string& get_crates, dyn_string& get_ips, dyn_string& exc, string systemName = "") {
if (! dpExists(systemName + "OPC_Conf_General.configuration.set.crates") ) {    
    fwException_raise(exc, "DP_DOES_NOT_EXIST", systemName + "OPC_Conf_General does not exist" ,0);
    return -1;
  }          

  dyn_string empty= makeDynString();
  dpSet(systemName + "OPC_Conf_General.configuration.get.crates", empty,
        systemName + "OPC_Conf_General.configuration.get.ips", empty      
        );
    
  // get current configuration
  dpSet(systemName + "OPC_Conf_General.regInput.idOperation", 8);
     
  time t;
  dyn_string dpNamesWait, dpNamesReturn;
  dyn_anytype conditions, returnValues;
  int status;
  bool timerExpired;
  int res;
   
  dpNamesWait = makeDynString(systemName+"OPC_Conf_General.regInput.idOperation:_original.._value");
  conditions[1] = 0;
  dpNamesReturn = makeDynString( systemName +"OPC_Conf_General.regInput.idOperation:_online.._value" );
  t = 40;

  // Wait until the operation is completed - code 0
  status = dpWaitForValue( dpNamesWait, conditions, dpNamesReturn, returnValues, t , timerExpired);
  if (status == -1) {
    fwException_raise(exc, "PROBLEM", "Problem in dpWaitForValue" ,0);
    return -1;
  }  
  if (timerExpired) {
     fwException_raise(exc, "PROBLEM", "Timer expired in dpWaitForValue" ,0);
    return -1;
  }
  dpGet(systemName + "OPC_Conf_General.regOutput.intResult", res);
  if (res == -1) {
    fwException_raise(exc, "GET_FAILED", "Problems in getting current configuration" ,0);
    return -1;
  }
    
  dpGet(systemName + "OPC_Conf_General.configuration.get.crates", get_crates,
        systemName + "OPC_Conf_General.configuration.get.ips", get_ips      
        );
  DebugN("getCurrentConfiguration: ", get_crates, get_ips);
          
  return 0;
}
