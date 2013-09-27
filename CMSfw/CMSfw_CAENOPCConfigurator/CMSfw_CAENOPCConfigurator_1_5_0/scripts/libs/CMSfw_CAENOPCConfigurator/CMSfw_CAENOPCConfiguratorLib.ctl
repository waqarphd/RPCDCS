// CMSfw_CAENOPCConfiguratorLib.ctl
// CTRL Library
//
// Developped by: Georgi Aleksandrov Leshev - ETH Zurich 
// Modified by: Lorenzo Masetti
// With contributions by Fernando Lucas Rodriguez - TOTEM
// CERN CMS Experiment
//

#uses "fwInstallationDB.ctl"
#uses "CMSfwInstallUtils/CMSfwInstallUtils.ctl"

bool CMSfw_CAENOPCConfiguration_debug = true;
string CMSfw_CAENOPCConfiguration_scriptPath = "";
string CMSfw_CAENOPCConfigurator_BAT = "";
string CMSfw_CAENOPCConfigurator_CSV = "";

const string CMSfw_CAENOPCConfigurator_resultFile = "CMSfw_CAENOPCConfigurator_result.txt";



void CMSfw_CAENOPCConfiguration_exec(string cmd) {
    if (CMSfw_CAENOPCConfiguration_debug) DebugTN("CAEN OPC Configurator: executing " + cmd);
    system(cmd);
}

string CMSfw_CAENOPCConfigurator_getPath() {
  string   path = getPath(SCRIPTS_REL_PATH );
  path = path + "/CMSfw_CAENOPCConfigurator/CAEN_User/";
  return path;  
}

string CMSfw_CAENOPCConfigurator_getScriptPath() {
  if (strlen(CMSfw_CAENOPCConfiguration_scriptPath)>0) return CMSfw_CAENOPCConfiguration_scriptPath;

  dyn_anytype componentInfo;
  
  int ok = fwInstallation_getComponentInfo("CMSfw_CAENOPCConfigurator", "installationdirectory", componentInfo);
	if (ok == 0)
	{
		CMSfw_CAENOPCConfiguration_scriptPath = componentInfo[1];
	}
	
	CMSfw_CAENOPCConfiguration_scriptPath = CMSfw_CAENOPCConfiguration_scriptPath+"/scripts/CMSfw_CAENOPCConfigurator/CAEN_User/";
  return CMSfw_CAENOPCConfiguration_scriptPath;  
}

int CMSfw_CAENOPCConfigurator_getNumConfigured() {
  string keyPath = "HKEY_USERS\\.DEFAULT\\Software\\CAEN/CERN\\CAENHVOPCServer\\Settings";
  string keyItem = "HVPSNum";

  bool ok;
  string numConfiguredStr = CMSfw_CAENOPCConfigurator_RegistryReadKey(keyPath,keyItem, ok);
  if (! ok) return 0;
  int numConfigured;
  
  sscanf(numConfiguredStr,"%x", numConfigured);
  return numConfigured;

}  
dyn_string CMSfw_CAENOPCConfigurator_retrieveEntries(string path)
{
    dyn_string result = makeDynString();

  string keyPath = "HKEY_USERS\\.DEFAULT\\Software\\CAEN/CERN\\CAENHVOPCServer\\Settings";
  string keyItem ;
  int numConfigured = CMSfw_CAENOPCConfigurator_getNumConfigured();

  string crateEntry;
  dyn_string crateParts;
  bool ok;
  for(int i=0; i<numConfigured; i++)
  {
    keyItem = i;
    
    crateEntry=CMSfw_CAENOPCConfigurator_RegistryReadKey(keyPath,keyItem, ok);
    if (! ok) {
        DebugTN("Error in reading registry");
        break;
    }
    dynAppend(result,crateEntry);
  }

  return result;
}

string CMSfw_CAENOPCConfigurator_getBatFilePath() {
  return  PROJ_PATH + "/" + DATA_REL_PATH + "/configureOPC.bat";
}
int CMSfw_CAENOPCConfigurator_DeleteCAENEntries(string path)
{
  string keyPath = "HKEY_USERS\\.DEFAULT\\Software\\CAEN/CERN\\CAENHVOPCServer\\Settings";
  string keyItem = "HVPSNum";
  string keyType = "REG_DWORD";
  CMSfw_CAENOPCConfigurator_BAT = CMSfw_CAENOPCConfigurator_getBatFilePath();
  CMSfw_CAENOPCConfigurator_CSV = PROJ_PATH + "/" + DATA_REL_PATH + "/CAENOPCSettings.csv";
  remove(CMSfw_CAENOPCConfigurator_BAT);
  remove(CMSfw_CAENOPCConfigurator_CSV);
  CMSfw_CAENOPCConfigurator_append("taskkill /F /IM CAENHVOPCServer.exe"); 
  CMSfw_CAENOPCConfigurator_append("sleep 4"); 
  
 CMSfw_CAENOPCConfigurator_RegistryWriteKey(keyPath, keyItem, keyType, "0");  
 return 0;
  
}

void CMSfw_CAENOPCConfigurator_autodetectServerVersion() {
  
    int size = getFileSize("C:\\Program Files (x86)\\CAEN\\CAENHVOPCServer\\CAENHVOPCServer.exe");
    if (size > 0) {
        //DebugN("size = " + size);
        if (size == 180224) {
            DebugN("Autodetected server version 3");
            CMSfw_CAENOPCConfigurator_setServerVersion(3);
        } else {
            DebugN("Autodetected server version 5");
            CMSfw_CAENOPCConfigurator_setServerVersion(5);
        }
    } else {
        DebugTN("Unable to autodetect version of caen opc server : using version " +  CMSfw_CAENOPCConfigurator_getServerVersion());         
    }
}

int CMSfw_CAENOPCConfigurator_getServerVersion() {
  int version = 3;
  if (dpExists("OPC_Conf_General.server.version")) {
      dpGet("OPC_Conf_General.server.version", version);
  }
  
  return version;    
}

int CMSfw_CAENOPCConfigurator_setServerVersion(int version) {
  if (dpExists("OPC_Conf_General.server.version")) {
      dpSet("OPC_Conf_General.server.version", version);
  } else {
    DebugN("Impossible to set server version. Dp does not exist OPC_Conf_General.server.version");        
  }
  
}
int CMSfw_CAENOPCConfigurator_AddEntry(string path, string crateName, string crateIP, int num = -1, int type = 0)
{
  string keyPath =  "HKEY_USERS\\.DEFAULT\\Software\\CAEN/CERN\\CAENHVOPCServer\\Settings";
  string keyItem = "HVPSNum";
  string keyType = "REG_DWORD";
  
  CMSfw_CAENOPCConfigurator_autodetectServerVersion();  
  int  version = CMSfw_CAENOPCConfigurator_getServerVersion();
  

  

  int numConfigured ;
  if (num ==-1) {
    numConfigured = CMSfw_CAENOPCConfigurator_getNumConfigured();
    numConfigured++;
  } else {
      numConfigured = num;
  }
      
  
  int result = CMSfw_CAENOPCConfigurator_RegistryWriteKey(keyPath, keyItem, keyType, numConfigured);
  if (result != 0) return result;

  keyItem = numConfigured-1;
  keyType = "REG_SZ";
  string value;
  if (version >= 5) {
     value = crateName+"," + type + ",0,"+crateIP;
  } else {
    value = crateName+",0,"+crateIP;
 }
  
  result = CMSfw_CAENOPCConfigurator_RegistryWriteKey(keyPath, keyItem, keyType, value);
  return result;
}

int CMSfw_CAENOPCConfigurator_RestartServer(string path)
{
  CMSfw_CAENOPCConfiguration_exec("taskkill /F /IM CAENHVOPCServer.exe");
  
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
 bool success= CMSfwInstallUtils_switchSimDriver(false, "PVSS00opc",6);
 
 delay(2);
 return success;
 
  
}

int CMSfw_CAENOPCConfigurator_startOPCManager()
{
  bool success=  CMSfwInstallUtils_switchSimDriver(true, "PVSS00opc",6);
  delay(2);
  return success;
}


int CMSfw_CAENOPCConfigurator_ConfigureOPC(dyn_string names, dyn_string ips, dyn_int types, bool restart_driver = true) {
  if (dynlen(names) != dynlen(ips)) {
    DebugN("Dynlen for names and ips does not match");
    return -1;
  }
  string path;
 
  path = CMSfw_CAENOPCConfigurator_getPath();
		
  CMSfw_CAENOPCConfigurator_stopOPCManager();
  // ALSO KILL THE OPC SERVER
  CMSfw_CAENOPCConfigurator_RestartServer(CMSfw_CAENOPCConfigurator_getPath());
  
  if (CMSfw_CAENOPCConfigurator_DeleteCAENEntries(path) == -1) return -1;
  int result = 0;
  string csv = "";
  for (int i=1; i<= dynlen(names); i++) {
    if (CMSfw_CAENOPCConfigurator_AddEntry(path, names[i], ips[i], i, types[i]) == -1) result = -1;
    csv += names[i] + "," + ips[i] + "," + types[i] + "\n";
  }    
  
  file f = fopen(CMSfw_CAENOPCConfigurator_CSV, "w");
  fputs(csv, f);
  fclose(f);
  
  
  if (restart_driver) {
    CMSfw_CAENOPCConfigurator_startOPCManager();
  }
  
  DebugTN("CAEN OPC Configurator --> INFO: a batch file to reconfigure the OPC server has been created in " +CMSfw_CAENOPCConfigurator_BAT);
  return result;
  
} 

int CMSfwCAENOPCConfiguration_getTypeIndex(string type) {
  return (strpos(type,"SY4527")>=0 || strpos(type,"SY5527")>=0)?1:0;;
}

bool CMSfwCAENOPCConfiguration_setConfigurationForSystem(dyn_string crates, dyn_string ips, dyn_string types = makeDynString(), string  systemName = "") {
  if (! dpExists(systemName + "OPC_Conf_General.configuration.set.crates") ) return false;
  dyn_int iTypes;
  if (dynlen(types)==0) {
    for (int i=1; i <= dynlen(crates); i++) {
        iTypes[i] = 0;
    }
  } else {
    for (int i=1; i<= dynlen(crates); i++) {

      iTypes[i] = CMSfwCAENOPCConfiguration_getTypeIndex(types);
    }      
 }
  
  
  dpSetWait(systemName + "OPC_Conf_General.configuration.set.crates", crates,
            systemName + "OPC_Conf_General.configuration.set.ips", ips,
           systemName + "OPC_Conf_General.configuration.set.types", iTypes);
  return true;   
}



/* Returns -1 error
           1 already set (nothing changed)
           2 changed
*/           
           
int CMSfwCAENOPCConfiguration_applyConfigurationForSystem(dyn_string& exc, string systemName = "", bool useDriver=true) {
  if (! dpExists(systemName + "OPC_Conf_General.configuration.set.crates") ) {    
    fwException_raise(exc, "DP_DOES_NOT_EXIST", systemName + "OPC_Conf_General does not exist" ,0);
    return -1;
  }          
  
  // get current configuration to see if already matches
  int res;
  if (useDriver) {
    res=   CMSfwCAENOPCConfiguration_executeOperation(8,50,exc, systemName);
    if (res == -1) {
        DebugN(exc); return -1;
    }
    
    dpGet(systemName + "OPC_Conf_General.regOutput.intResult", res);

  } else {
     res = CMSfw_CAENOPCConfigurator_configurationGet();     
  }
    
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
   if (ok) {
     if (access(CMSfw_CAENOPCConfigurator_getBatFilePath(), R_OK) == 0) {
       return 1;
     } else {
        DebugTN("CAEN Configurator: Configuration already matches but the batch file was not found. Reapplying configuration...");         
     }     
   }
       
   
  // set current configuration
   if (useDriver) {
    res=   CMSfwCAENOPCConfiguration_executeOperation(9,120,exc, systemName);
    if (res == -1) {
        DebugN(exc); return -1;
    }
  
    dpGet(systemName + "OPC_Conf_General.regOutput.intResult", res);
  } else {
      res = CMSfw_CAENOPCConfigurator_configurationSet();      
  }
  
  if (res == -1) {
    fwException_raise(exc, "SET_FAILED", "Problems in setting new configuration" ,0);
    return -1;
  }
  return 2;   
}



int CMSfwCAENOPCConfiguration_getConfigurationForSystem(dyn_string& get_crates, dyn_string& get_ips, dyn_int& get_types, dyn_string& exc, string systemName = "", bool useDriver = true) {
if (! dpExists(systemName + "OPC_Conf_General.configuration.set.crates") ) {    
    fwException_raise(exc, "DP_DOES_NOT_EXIST", systemName + "OPC_Conf_General does not exist" ,0);
    return -1;
  }          

  dyn_string empty= makeDynString();
  dpSet(systemName + "OPC_Conf_General.configuration.get.crates", empty,
        systemName + "OPC_Conf_General.configuration.get.ips", empty      
        );
    
  // get current configuration

  int res;
  
  if (useDriver) {
    res=   CMSfwCAENOPCConfiguration_executeOperation(8,50,exc, systemName);
    if (res == -1) {
        DebugN(exc); return -1;
    }
   
    dpGet(systemName + "OPC_Conf_General.regOutput.intResult", res);
  } else {
    res = CMSfw_CAENOPCConfigurator_configurationGet();      
  }
  if (res == -1) {
    fwException_raise(exc, "GET_FAILED", "Problems in getting current configuration" ,0);
    return -1;
  }
    
  dpGet(systemName + "OPC_Conf_General.configuration.get.crates", get_crates,
        systemName + "OPC_Conf_General.configuration.get.ips", get_ips    ,
        systemName + "OPC_Conf_General.configuration.get.types", get_types
        );
//  DebugN("getCurrentConfiguration: ", get_crates, get_ips);
          
  return 0;
}


                                                         
int CMSfwCAENOPCConfiguration_saveToDb( dyn_string crates, dyn_string ips,bool EventEnabled, int VerifyTime, bool LiveInsertRemoval, dyn_string& exc) {
  
 
   fwInstallationDB_connect();
  int projectId;
  string projectName = PROJ;
  
  string computerName = fwInstallation_getHostname();

  computerName = strtoupper(computerName);
  
   
  if (fwInstallationDB_isProjectRegistered(projectId,projectName,computerName) == -1) {
     fwException_raise(exc,"PROJECT NOT FOUND","Project  " + projectName + "@" + computerName 
                       + " not registered in db", ""); 
     return -1;
  }
  
  string sql = "delete from caen_opc_configurator_mf where project_id=:1";
  dyn_mixed record;
  record[1] = projectId;
  if(fwInstallationDB_execute(sql, record)) {fwInstallation_throw("ERROR: saveCaenToDb() -> Could not execute the following SQL: " + sql); return -1;};
  
  for (int i=1; i<= dynlen(crates); i++) {
      sql = "insert into caen_opc_configurator_mf (project_id, name, ip) values(:1,:2,:3)";
      record[1] = projectId;
      record[2] = crates[i];
      record[3] =  ips[i];
      if(fwInstallationDB_execute(sql, record)) {fwInstallation_throw("ERROR: saveCaenToDb() -> Could not execute the following SQL: " + sql); return -1;};
  }
  
  dynClear(record);
  sql = "delete from caen_opc_configurator_config where project_id=:1";
  record[1] = projectId;
  if(fwInstallationDB_execute(sql, record)) {fwInstallation_throw("ERROR: saveCaenToDb() -> Could not execute the following SQL: " + sql); return -1;};
  
  sql = "insert into caen_opc_configurator_config (project_id, eventenabled, verifytime, liveinsertremoval) values (:1,:2,:3,:4)";
  record[2] = EventEnabled;
  record[3] = VerifyTime;
  record[4] = LiveInsertRemoval;
  if(fwInstallationDB_execute(sql, record)) {fwInstallation_throw("ERROR: saveCaenToDb() -> Could not execute the following SQL: " + sql); return -1;};
  
  return 0;
}


int CMSfwCAENOPCConfiguration_executeOperation(int idOperation, int timeout, dyn_string& exc,string systemName="") {
    

  dpSet(systemName + "OPC_Conf_General.regInput.idOperation", idOperation);
     
  time t;
  dyn_string dpNamesWait, dpNamesReturn;
  dyn_anytype conditions, returnValues;
  int status;
  bool timerExpired;
  int res;
   
  dpNamesWait = makeDynString(systemName+"OPC_Conf_General.regInput.idOperation:_original.._value");
  conditions[1] = 0;
  dpNamesReturn = makeDynString( systemName +"OPC_Conf_General.regInput.idOperation:_online.._value" );
  t = timeout;

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
  
  return 0;
}

int CMSfwCAENOPCConfiguration_getConfigFileInfoRemote(bool& EventEnabled, int& VerifyTime, bool& LiveInsertRemoval, string systemName="") {
  dyn_string exc;
   int res = CMSfwCAENOPCConfiguration_executeOperation(12,20, exc,systemName);
   if (res == -1) {
       DebugN(exc); return -1;
   }
   dyn_string result; int intResult;
   dpGet(systemName + "OPC_Conf_General.regOutput.dynstringResult", result,
         systemName + "OPC_Conf_General.regOutput.intResult", intResult);
   if (intResult == -1) return -1;
   if (dynlen(result)<3) return -1;
   
   EventEnabled = (bool) result[1];
   VerifyTime = (int) result[2];
   LiveInsertRemoval = (bool) result[3];
   return 0;
}


int CMSfwCAENOPCConfiguration_setConfigFileInfoRemote(bool EventEnabled, int VerifyTime, bool LiveInsertRemoval, bool restartDriver = true,string systemName="") {
   
   dpSetWait(systemName + "OPC_Conf_General.regInput.nameCrate", 
             EventEnabled + "," + VerifyTime + "," + LiveInsertRemoval + "," + restartDriver);
   
   dyn_string exc;
   int res = CMSfwCAENOPCConfiguration_executeOperation(13,60, exc,systemName);
   if (res == -1) {
       DebugN(exc); return -1;
   }
   int intResult;
   dpGet( systemName + "OPC_Conf_General.regOutput.intResult", intResult);
   
   return intResult;

}



int CMSfwCAENOPCConfiguration_getConfigFileInfo(bool& EventEnabled, int& VerifyTime, bool& LiveInsertRemoval) {
    string configFile = getenv("WINDIR") + "\\System32\\CAENHVOPCServer.cfg";
    
    file f = fopen(configFile,"r");
    if (f==0) return -1;

     string line;
     
     int res = 0;

     dyn_string key_value;
     while (! feof(f)) {
         fgets(line,1000,f);
         if (substr(line,0,1)==";") continue;
         key_value = strsplit(line,"=");
         if (dynlen(key_value) != 2) continue;
         key_value[1] = strltrim(strrtrim(key_value[1]));
         key_value[2] = strltrim(strrtrim(key_value[2]));
         switch (key_value[1]) {
             case "EventEnabled":
           if ( ((key_value[2] != "true") && (key_value[2] != "false")) ) {
                  res = -1; break;
           }
               EventEnabled = (key_value[2] == "true");
               break;
             case "VerifyTime":
               VerifyTime = (int) key_value[2]; break;
             case "LiveInsertRemoval":
                 if ( ((key_value[2] != "true") && (key_value[2] != "false")) ) {
                  res = -1; break;
                 }
               LiveInsertRemoval = (key_value[2] == "true");                              
         }
     }
     

    fclose(f);
    return res;
  
}

/* Returns -1 error
           1 already set (nothing changed)
           2 changed
*/ 
int CMSfwCAENOPCConfiguration_setConfigFileInfo(bool EventEnabled, int VerifyTime, bool LiveInsertRemoval, bool restartDriver = true) {
    string configFile = getenv("WINDIR") + "\\System32\\CAENHVOPCServer.cfg";
    bool EventEnabledOld; int VerifyTimeOld; bool LiveInsertRemovalOld;
    CMSfwCAENOPCConfiguration_getConfigFileInfo(EventEnabledOld,VerifyTimeOld,LiveInsertRemovalOld);
    if ((EventEnabled == EventEnabledOld) && (VerifyTime == VerifyTimeOld) && (LiveInsertRemoval == LiveInsertRemovalOld)) {
      return 1;
    }
    
    file f = fopen(configFile,"r");
    if (f==0) return -1;

     string line;
     string modifiedContent;
     
     int res = 2;

     dyn_string key_value;
     while (! feof(f)) {
         fgets(line,1000,f);
         if (substr(line,0,1)==";") {
           modifiedContent += line ;
           continue;
         }
         key_value = strsplit(line,"=");
         if (dynlen(key_value) != 2) {
            modifiedContent += line ;
           continue;
         }
         key_value[1] = strltrim(strrtrim(key_value[1]));

         switch (key_value[1]) {
             case "EventEnabled":
               line = "EventEnabled = " + (EventEnabled?"true":"false") + "\n";
          
               break;
             case "VerifyTime":
               line = "VerifyTime = " + VerifyTime + "\n"; 
               break;
             case "LiveInsertRemoval":
               line = "LiveInsertRemoval = " + (LiveInsertRemoval?"true":"false") + "\n";
                break;                
         }
         modifiedContent += line ;
     }
     

    fclose(f);
  //  DebugTN(modifiedContent);
    
    f = fopen(configFile,"w");
    if (f==0) return -1;
    if (fputs(modifiedContent,f)!= 0) res = -1;
    fclose(f);

    if (restartDriver) {
        CMSfw_CAENOPCConfigurator_stopOPCManager();
        delay(2);
        CMSfw_CAENOPCConfigurator_RestartServer(CMSfw_CAENOPCConfigurator_getPath());
        delay(2);
        CMSfw_CAENOPCConfigurator_startOPCManager();
    }
    return res;
}


// FUNCTIONS ADAPTED FROM TOTEM

string CMSfw_CAENOPCConfigurator_FileGetTempFolder() {
    return getPath(DATA_REL_PATH) + "/";
}

string CMSfw_CAENOPCConfigurator_system(string command, bool& ok, string fullname="", bool verbose=true)
{

  ok = (CMSfw_CAENOPCConfigurator_systemexecute(command,fullname,verbose) == 0);
  if (! ok) {
    remove(fullname);
    return"";  
  }
  string result = CMSfw_CAENOPCConfigurator_systemresult(ok,fullname);



  return result;
}
void CMSfw_CAENOPCConfigurator_Log(string msg) {
  DebugTN("CMSfw_CAENOPCConfigurator: " + msg);
}
/**
   @param command                            ?
   @param fullname                           ?
   @return                                   void
*/
int CMSfw_CAENOPCConfigurator_systemexecute(string command, string fullname="", bool verbose=true)
{
  if (fullname=="")
    {
      fullname=CMSfw_CAENOPCConfigurator_FileGetTempFolder()+CMSfw_CAENOPCConfigurator_resultFile;
    }

  command = command + " > " +fullname;
  if (verbose==true) {CMSfw_CAENOPCConfigurator_Log("command: "+command);}
  int result = system(command);
  if (verbose==true) {CMSfw_CAENOPCConfigurator_Log("result: "+result);}
  return result;
}

/**
   @param fullname                           ?
   @return                                   string
*/
string CMSfw_CAENOPCConfigurator_systemresult(bool& ok,string fullname="")
{
  if (fullname=="")
    {
      fullname=CMSfw_CAENOPCConfigurator_FileGetTempFolder()+CMSfw_CAENOPCConfigurator_resultFile;
    }

  string text="";
  ok = fileToString(fullname,text);

  //  file temp = fopen(fullname,"r");
  //  string buffer;
  //  while (feof(temp)==0)
  //  {
  //    fgets(buffer,1024,temp);
  //    text = text + buffer;
  //  }
  //  fscanf(text,1024,temp);
  //  fclose(temp);

  
  return text;
}



// usage: return CMSfw_CAENOPCConfigurator_RegistryReadKey("HKEY_LOCAL_MACHINE\\SYSTEM\\CurrentControlSet\\Services\\awusbsys","IpAddressList");
string CMSfw_CAENOPCConfigurator_RegistryReadKey(string key, string item, bool& ok)
{
  string regCommand = "reg query " + key + " /v " + item;
//  DebugN(regCommand);
  string regOutput = CMSfw_CAENOPCConfigurator_system(regCommand,ok,"",false);

  dyn_string regOutputLines = strsplit(regOutput, "\n");
  if (dynlen(regOutputLines)==0) return "";
  
  string lineGood = regOutputLines[dynlen(regOutputLines) - 1];

  string c; int pos;
  for (int i = strlen(lineGood)-1; i>=0; i--) {
    c = substr(lineGood,i,1);
    if ((c == " ") || (c=="\t")) {
        pos = i; break;
    }
  }
  
  string value = substr(lineGood, pos+1);
  
  //DebugTN("CMSfw_CAENOPCConfigurator_RegistryReadKey ", key, item, " result = ", value);

  return value;
}

void     CMSfw_CAENOPCConfigurator_append(string regCommand) {
  file f = fopen(CMSfw_CAENOPCConfigurator_BAT, "a");
  fputs(regCommand + "\n", f);
  fclose(f);
}

// usage: CMSfw_CAENOPCConfigurator_RegistryWriteKey("HKEY_LOCAL_MACHINE\\SYSTEM\\CurrentControlSet\\Services\\awusbsys", "IpAddressList", "REG_MULTI_SZ", "127.0.0.1");
int CMSfw_CAENOPCConfigurator_RegistryWriteKey(string key, string item, string type, string data)
{
  string regCommand = "reg add "+key+" /v "+item+" /t "+type+" /d "+data+" /f";
//    DebugN(regCommand);
  bool ok;
  CMSfw_CAENOPCConfigurator_system(regCommand,ok, "",false);
    CMSfw_CAENOPCConfigurator_append(regCommand);
  return (ok?0:-1);
} 

/**
@return                                   dyn_dyn_string
*/
dyn_dyn_string CMSfw_CAENOPCConfigurator_CaenOpcGetAll()
{
  dyn_dyn_string result = makeDynString();

  string keyPath = 
"HKEY_USERS\\.DEFAULT\\Software\\CAEN/CERN\\CAENHVOPCServer\\Settings";
  string keyItem = "HVPSNum";

  int numConfigured = CMSfw_CAENOPCConfigurator_RegistryReadKey(keyPath,keyItem, ok);
  if (! ok) {
      DebugTN("Error in reading registry key ");
      return result;
  }
  string crateEntry;
  dyn_string crateParts;
  bool ok;
  for(i=0; i<numConfigured; i++)
  {
    keyItem = i;
    crateEntry=CMSfw_CAENOPCConfigurator_RegistryReadKey(keyPath,keyItem, ok);
    if (! ok) {
        DebugTN("Error reading registry");
        break;
    }
    crateParts=strsplit(crateEntry,",");
    dynAppend(result,makeDynString(crateParts[1],crateParts[2]));
  }

  return result;
}

/**** COMMINICATION WITH FWCAENDPS ****/


void CMSfw_CAENOPCConfigurator_copyConfigToFwCaenDps(dyn_string& exc,string systemName="") {
  dyn_string get_crates, get_ips;
    bool useServer = true;
     if (myManType() == CTRL_MAN) {
         if ((systemName=="") || (systemName==getSystemName()) ) useServer = false;
     }
     
     dyn_int get_types;
     
  int result = CMSfwCAENOPCConfiguration_getConfigurationForSystem(get_crates, get_ips, get_types,exc, systemName, useServer);
  if (dynlen(exc)>0) {
      return;
  }
  string dpe;
  for (int i=1; i<= dynlen(get_crates); i++) {
    dpe = systemName + "CAEN/" + get_crates[i] + ".Communication.IPAddr";
    if (! dpExists(dpe) ) {
      fwException_raise(exc, "DP_NOT_EXISTING", dpe + " does not exist","");
    } else {
      dpSet(dpe, get_ips[i]);        
    }
  }
  bool EventEnabled; int VerifyTime; bool LiveInsertRemoval;
  if (useServer)
    CMSfwCAENOPCConfiguration_getConfigFileInfoRemote(EventEnabled,  VerifyTime, LiveInsertRemoval, systemName);
  else
    CMSfwCAENOPCConfiguration_getConfigFileInfo(EventEnabled,  VerifyTime, LiveInsertRemoval);
    
  dyn_string dps = dpNames(systemName + "CAEN/*", "FwCaenCrateSY1527");
  for (int i=1; i<= dynlen(dps); i++) {       
      dpSet(dps[i] + ".Communication.OPCServerEventMode", EventEnabled,
            dps[i] + ".Communication.OPCServerVerifyTime", VerifyTime,
            dps[i] + ".Communication.OPCServerLiveInsertion", LiveInsertRemoval);      
  }
         
      
}


void CMSfw_CAENOPCConfigurator_getConfigurationFromFwDps(dyn_string& crates, dyn_string& ips, dyn_string& types, string systemName= "")  {
     dyn_string dps = dpNames(systemName + "CAEN/*", "FwCaenCrateSY1527");
     string name; string ip; dyn_string exc;string model;
     dynClear(crates); dynClear(ips); 
     
     for (int i=1; i<= dynlen(dps); i++) {       
         fwDevice_getName(dps[i], name, exc);
         crates[i] = name;
         dpGet(dps[i] +".Communication.IPAddr", ip,
               dps[i] + ".model", model);
         ips[i] = ip;
         types[i] = model;
     }
}


dyn_string CMSfw_CAENOPCConfigurator_appendConfigurationsFromOtherProjects(dyn_string& crates, dyn_string& ips, dyn_string& types) {
    // This is only used in production when there is more than one project that are called ServiceProject1, 2, etc

  dyn_string found_dirs = makeDynString();
  if ((strpos(PROJ,"ServiceProject") == 0) && (strlen(PROJ)>strlen("ServiceProject")) ){
    
     string fn, content;  
     dyn_string rows;
     dyn_string els;
     int index;
      dyn_string dirs = getFileNames(PROJ_PATH + "\\..\\","ServiceProject*", FILTER_DIRS);
      for (int i=1; i<= dynlen(dirs);i++) {

        if (strpos(dirs[i], "_")>-1) {
                  DebugN("Skipping backup dir " + dirs[i]);
            continue; // skip backup dirs
        }
        if (dirs[i] == PROJ) {
        //  DebugN("Skipping my dir " + dirs[i]);
          continue;
        }
       dynAppend(found_dirs, PROJ_PATH + "..\\" + dirs[i] + "\\");
        fn = PROJ_PATH + "..\\" + dirs[i] + "\\"+ DATA_REL_PATH + "CAENOPCSettings.csv";
        DebugN("Checking file " + fn);
        if (access(fn, R_OK) == 0) {
          fileToString(fn,content);
          rows = strsplit(content,"\n");
          for (int j=1; j<= dynlen(rows); j++) {
              els = strsplit(rows[j], ",");
              if (dynlen(els) != 3) {
                  DebugN("Wrong format of file " + fn + " line " + j);
                  continue;
              }
              index = dynContains(crates, els[1]);
              if (index == 0) {
                  dynAppend(crates, els[1]);
                  dynAppend(ips, els[2]);
                  dynAppend(types, els[3]);
               } else {
                 if (ips[index] != els[2] || types[index] != els[3]) {
                      DebugTN("Conflicting configuration for crate " + els[1]);
                 }                   
               }
          }
        }
      }

    
  }
  return found_dirs;
}

/**
  * THIS IS THE MAIN COMMAND TO BE CALLED FROM A POSTINSTALL SCRIPT, AFTER RESTORING THE CAEN DPS WITH THE PROPER 
  * VALUE WRITTEN INTO .Communication.IPAddr
  *
  ***/
int CMSfw_CAENOPCConfigurator_configureFromFwCaenDps(dyn_string& exc, string systemName = "") {
    dyn_string crates, ips, types;
     bool useServer = true;
     if (myManType() == CTRL_MAN) {
         if ((systemName=="") || (systemName==getSystemName()) ) useServer = false;
     }
     if (useServer) {     
            int res=   CMSfwCAENOPCConfiguration_executeOperation(14,240,exc, systemName);
            if (res == -1) {
                DebugN(exc); return -1;
              }
    
              dpGet(systemName + "OPC_Conf_General.regOutput.intResult", res);
              return res;
     }
     
    CMSfw_CAENOPCConfigurator_getConfigurationFromFwDps(crates, ips, types, systemName);
    dyn_string found_dirs = CMSfw_CAENOPCConfigurator_appendConfigurationsFromOtherProjects(crates,ips, types);
    CMSfwCAENOPCConfiguration_setConfigurationForSystem(crates, ips, types, systemName);
    int result = CMSfwCAENOPCConfiguration_applyConfigurationForSystem(exc, systemName, false);
    
    
    string batFile = CMSfw_CAENOPCConfigurator_getBatFilePath();
    bool ok;
    string destFile;

    // copy the bat to the other projects
    if ((result == 2) && (access(batFile, R_OK) == 0)) { // if it has been changed
      for (int i=1; i<= dynlen(found_dirs); i++) {
        ok = destFile = found_dirs[i] + DATA_REL_PATH + "/configureOPC.bat";
        copyFile(batFile, destFile); 
        DebugN("Copying " + batFile + " to " + destFile + " -> " + ((ok)?"OK":"NOT OK"));
      }
    }
   
    /* bool EventEnabled; int VerifyTime; bool LiveInsertRemoval;
    if (CMSfw_CAENOPCConfigurator_getConfigurationFilePropertiesFromFwDps(EventEnabled,VerifyTime,LiveInsertRemoval,systemName)==0) {
      if (useServer)
        CMSfwCAENOPCConfiguration_setConfigFileInfoRemote( EventEnabled,VerifyTime,LiveInsertRemoval,true, systemName); 
      else
        CMSfwCAENOPCConfiguration_setConfigFileInfo( EventEnabled,VerifyTime,LiveInsertRemoval,true); 
    } else {
      fwException_raise(exc,"CONFIG_DP","Unable to get config file parameters from fw dp","");
      return -1;      
    }
     */ 
    return result;
}

int CMSfw_CAENOPCConfigurator_getConfigurationFilePropertiesFromFwDps(bool& EventEnabled, int& VerifyTime, bool& LiveInsertRemoval, string systemName="") {
   dyn_string dps = dpNames(systemName + "CAEN/*", "FwCaenCrateSY1527");

   if (dynlen(dps)==0) return -1;
   
      dpGet(dps[1] + ".Communication.OPCServerEventMode", EventEnabled,
            dps[1] + ".Communication.OPCServerVerifyTime", VerifyTime,
            dps[1] + ".Communication.OPCServerLiveInsertion", LiveInsertRemoval);     
      return 0;
      
}


int CMSfw_CAENOPCConfigurator_configurationGet() {
    dyn_string Result = CMSfw_CAENOPCConfigurator_retrieveEntries(CMSfw_CAENOPCConfigurator_getPath());
    
    dyn_string spl, crates, ips; dyn_int types;int res = 0;
    bool new;
    for (int i=1; i<= dynlen(Result); i++) {
      Result[i] = strrtrim(Result[i],"\n");
      
      spl = strsplit(Result[i],",");

      if (spl[1] == "Error") {
          res = -1; break;
      }
      if (dynlen(spl) == 3) {
        dynAppend(crates, spl[1]);
        dynAppend(ips, spl[3]);
        dynAppend(types,0);
      } else if (dynlen(spl) == 4){ 
        dynAppend(crates, spl[1]);
        dynAppend(types, (int) spl[2]);
        dynAppend(ips, spl[4]);
        new = true;
        
      }
    }
    
  
    string dpconf = "OPC_Conf_General";    
    dpSetWait(dpconf + ".configuration.get.crates", crates,
              dpconf + ".configuration.get.ips", ips,
              dpconf + ".configuration.get.types", types);
    
  return res;
}

int CMSfw_CAENOPCConfigurator_configurationSet() {
    dyn_string crates, ips; dyn_int types;
    dpGet("OPC_Conf_General.configuration.set.crates", crates,
           "OPC_Conf_General.configuration.set.ips", ips,
           "OPC_Conf_General.configuration.set.types", types
           );
     
    int res =  CMSfw_CAENOPCConfigurator_ConfigureOPC(crates, ips, types);
    
  return res;
  
}

