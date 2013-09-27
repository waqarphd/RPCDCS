// CMSfw_CAENOPCConfigurator_Driver.ctl
// CTRL script intended to be used via CTRL manager
//
// Developed by: Georgi Aleksandrov Leshev  ETH Zurich
// CERN CMS Experiment
//


#uses "CMSfw_CAENOPCConfigurator/CMSfw_CAENOPCConfiguratorLib.ctl"

main()
{
  // wait for operation to occur
  dpConnect("inputHandle", 0,getSystemName()+"OPC_Conf_General.regInput.idOperation:_online.._value");  
 
}

string getVersion() {
  bool ok;
  string showVers = "\\\\cern.ch\\dfs\\Users\\c\\cmsdcs\\Public\\CMS_DCS_Repository\\Tools\\Utilities\\ShowVers\\ShowVer.exe" ;
  string caenexe = "C:\\Program Files\\CAEN\\CAENHVOPCServer\\CAENHVOPCServer.exe";
  string cmd = showVers + " \"" + caenexe + "\" | grep \"FileVersion:\"";
  string result = CMSfw_CAENOPCConfigurator_system(cmd, ok);
  strreplace(result,"\n","");
  if (! ok) return "ERROR in executing command";
  else return result;
}




int loadFromDb() {
  dyn_string exc;
  dyn_string crates, ips;
    bool EventEnabled; int VerifyTime; bool LiveInsertRemoval;
    bool applyToConfigFile;
  
  int result =  CMSfwCAENOPCConfiguration_loadFromDb(crates, ips,EventEnabled,VerifyTime,LiveInsertRemoval,applyToConfigFile, exc);

  if (result ==-1) {
      DebugN("Error loading configuration from DB");
      return -1;
  }
  
  dyn_string dynstring_result;
  dynstring_result[1] = EventEnabled;
  dynstring_result[2] = VerifyTime;
  dynstring_result[3] = LiveInsertRemoval;
  dynstring_result[4] = applyToConfigFile;
  dpSetWait("OPC_Conf_General.regOutput.dynstringResult", dynstring_result);
  
  result = CMSfwCAENOPCConfiguration_setConfigurationForSystem(crates, ips)?0:-1;
  return result;
 
}

int saveToDb() {
  dyn_string exc;
  int res = configurationGet();
  if (res == -1) return -1;
  dyn_string crates, ips;
  string dpconf = "OPC_Conf_General";    
  dpGet(dpconf + ".configuration.get.crates", crates,
          dpconf + ".configuration.get.ips", ips);
  
  bool EventEnabled; int VerifyTime; bool LiveInsertRemoval;
 
  res = CMSfwCAENOPCConfiguration_getConfigFileInfo(EventEnabled, VerifyTime, LiveInsertRemoval);
  if (res == -1) {
      VerifyTime = -1; // this means do not write config file info
  }
  
  int res = CMSfwCAENOPCConfiguration_saveToDb(crates, ips,EventEnabled, VerifyTime, LiveInsertRemoval,exc);
  if (dynlen(exc)>0) DebugTN(exc);
  return res;
}


int getConfigFileInfo() {
  
  bool EventEnabled; int VerifyTime; bool LiveInsertRemoval;
  
  int intResult = CMSfwCAENOPCConfiguration_getConfigFileInfo(EventEnabled, VerifyTime, LiveInsertRemoval);
  dyn_string result;
  result[1] = EventEnabled;
  result[2] = VerifyTime;
  result[3] = LiveInsertRemoval;
  
  dpSetWait(getSystemName()+"OPC_Conf_General.regOutput.dynstringResult:_original.._value", result);
  return intResult;
}

int setConfigFileInfo() {
  string parameters;
   dpGet(getSystemName()+"OPC_Conf_General.regInput.nameCrate", parameters);
   dyn_string spl = strsplit(parameters,",");
   if (dynlen(spl) != 4) {
       return -1;
   }
   return CMSfwCAENOPCConfiguration_setConfigFileInfo((bool) spl[1], (int) spl[2], (bool) spl[3], (bool) spl[4]);   
}

inputHandle(string dp, int idOperation)
{
  // Find the path needed for the CAEN Registry operations
  string path = CMSfw_CAENOPCConfigurator_getPath();
  


  // Intermediate variables
  dyn_string Result1;
  int Result2;
  string nameCrate, ipCrate;
  dyn_string exc; string version;
  
  // Check what operation was requested by the user
  switch (idOperation)
  {
    // 0 - means end of some operation 
    case 0:
      return;
    
    // 1 - means retrieve entries from the Registry and give them in the UI    
    case 1:
      Result1 = CMSfw_CAENOPCConfigurator_retrieveEntries(path);
      dpSetWait(getSystemName()+"OPC_Conf_General.regOutput.dynstringResult:_original.._value", Result1);
      dpSetWait(getSystemName()+"OPC_Conf_General.regInput.idOperation:_original.._value", 0);
      
      break;
         
    // 2 - Operation Delete all entries in the Registry
    case 2:
      Result2 = CMSfw_CAENOPCConfigurator_DeleteCAENEntries(path);
      dpSetWait(getSystemName()+"OPC_Conf_General.regOutput.intResult:_original.._value", Result2);
      dpSetWait(getSystemName()+"OPC_Conf_General.regInput.idOperation:_original.._value", 0);
      
      break;
      
    // 3 - Operation Add entry  
    case 3:
      dpGet(getSystemName()+"OPC_Conf_General.regInput.nameCrate:_original.._value", nameCrate);
      dpGet(getSystemName()+"OPC_Conf_General.regInput.ipCrate:_original.._value", ipCrate);
      
      Result2 = CMSfw_CAENOPCConfigurator_AddEntry(path, nameCrate, ipCrate);
      dpSetWait(getSystemName()+"OPC_Conf_General.regOutput.intResult:_original.._value", Result2);
      dpSetWait(getSystemName()+"OPC_Conf_General.regInput.idOperation:_original.._value", 0);
      
      break;  
      
    // 4 - Operation find if the OPC manager in the PVSS project is ON or OFF
    case 4:
      Result2 = CMSfw_CAENOPCConfigurator_statusOPCManager();
      dpSetWait(getSystemName()+"OPC_Conf_General.regOutput.intResult:_original.._value", Result2);
      dpSetWait(getSystemName()+"OPC_Conf_General.regInput.idOperation:_original.._value", 0);
      
      break;    
      
    // 5 - Operation Stop OPC manager   
    case 5:
      Result2 = CMSfw_CAENOPCConfigurator_stopOPCManager();
      dpSetWait(getSystemName()+"OPC_Conf_General.regOutput.intResult:_original.._value", Result2);
      dpSetWait(getSystemName()+"OPC_Conf_General.regInput.idOperation:_original.._value", 0);
      
      break;
    
    // 6 - Operation Start OPC manager 
    case 6:
      Result2 = CMSfw_CAENOPCConfigurator_startOPCManager();
      dpSetWait(getSystemName()+"OPC_Conf_General.regOutput.intResult:_original.._value", Result2);
      dpSetWait(getSystemName()+"OPC_Conf_General.regInput.idOperation:_original.._value", 0);
      break;
    case 7:
      Result2 = CMSfw_CAENOPCConfigurator_RestartServer(path);
      dpSetWait(getSystemName()+"OPC_Conf_General.regOutput.intResult:_original.._value", Result2);
      dpSetWait(getSystemName()+"OPC_Conf_General.regInput.idOperation:_original.._value", 0);
      break;      
    case 8:
      Result2 = CMSfw_CAENOPCConfigurator_configurationGet() ;
      dpSetWait(getSystemName()+"OPC_Conf_General.regOutput.intResult:_original.._value", Result2);
      dpSetWait(getSystemName()+"OPC_Conf_General.regInput.idOperation:_original.._value", 0);
      break;
    case 9:
     Result2 = CMSfw_CAENOPCConfigurator_configurationSet();
     dpSetWait(getSystemName()+"OPC_Conf_General.regOutput.intResult:_original.._value", Result2); 
     dpSetWait(getSystemName()+"OPC_Conf_General.regInput.idOperation:_original.._value", 0);
      break;
    case 10:
      Result2  = loadFromDb();
      dpSetWait(getSystemName()+"OPC_Conf_General.regOutput.intResult:_original.._value", Result2);
      dpSetWait(getSystemName()+"OPC_Conf_General.regInput.idOperation:_original.._value", 0);
      break;
    case 11:
       Result2= saveToDb();
       dpSetWait(getSystemName()+"OPC_Conf_General.regOutput.intResult:_original.._value", Result2);
       dpSetWait(getSystemName()+"OPC_Conf_General.regInput.idOperation:_original.._value", 0);
       break;
    case 12:
       Result2= getConfigFileInfo();
       dpSetWait(getSystemName()+"OPC_Conf_General.regOutput.intResult:_original.._value", Result2);
       dpSetWait(getSystemName()+"OPC_Conf_General.regInput.idOperation:_original.._value", 0);
       break;
    case 13:
       Result2= setConfigFileInfo();
       dpSetWait(getSystemName()+"OPC_Conf_General.regOutput.intResult:_original.._value", Result2);
       dpSetWait(getSystemName()+"OPC_Conf_General.regInput.idOperation:_original.._value", 0);
       break;
    case 14:
        Result2= CMSfw_CAENOPCConfigurator_configureFromFwCaenDps(exc);
        if (dynlen(exc)>0) Result2 = -1;
       dpSetWait(getSystemName()+"OPC_Conf_General.regOutput.intResult:_original.._value", Result2);
       dpSetWait(getSystemName()+"OPC_Conf_General.regInput.idOperation:_original.._value", 0);
        break;      
   case 15:
        CMSfw_CAENOPCConfigurator_copyConfigToFwCaenDps(exc);
        if (dynlen(exc)>0) Result2 = -1; else Result2= 0;
       dpSetWait(getSystemName()+"OPC_Conf_General.regOutput.intResult:_original.._value", Result2);
       dpSetWait(getSystemName()+"OPC_Conf_General.regInput.idOperation:_original.._value", 0);
        break;        
   case 16:
        version = getVersion();
        dpSetWait(getSystemName()+"OPC_Conf_General.regOutput.dynstringResult:_original.._value", makeDynString(version));
        dpSetWait(getSystemName()+"OPC_Conf_General.regOutput.intResult:_original.._value", 0);
        dpSetWait(getSystemName()+"OPC_Conf_General.regInput.idOperation:_original.._value", 0);
        break;        
       
         
  }
}
