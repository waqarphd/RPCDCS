// CMSfw_CAENOPCConfigurator_Driver.ctl
// CTRL script intended to be used via CTRL manager
//
// Developped by: Georgi Aleksandrov Leshev  ETH Zurich
// CERN CMS Experiment
//


#uses "CMSfw_CAENOPCConfigurator/CMSfw_CAENOPCConfiguratorLib.ctl"

main()
{
  // wait for operation to occur
  dpConnect("inputHandle", 0,getSystemName()+"OPC_Conf_General.regInput.idOperation:_online.._value");  
 
}


void configurationGet() {
    dyn_string Result = CMSfw_CAENOPCConfigurator_retrieveEntries(CMSfw_CAENOPCConfigurator_getPath());
    
    dyn_string spl, crates, ips; int res = 0;
    for (int i=1; i<= dynlen(Result); i++) {
      Result[i] = strrtrim(Result[i],"\n");
      
      spl = strsplit(Result[i],",");
      if (dynlen(spl)!= 3) continue;
      if (spl[1] == "Error") {
          res = -1; break;
      }
      dynAppend(crates, spl[1]);
      dynAppend(ips, spl[3]);
    }
    
    string dpconf = "OPC_Conf_General";    
    dpSetWait(dpconf + ".configuration.get.crates", crates,
              dpconf + ".configuration.get.ips", ips);
    
    dpSetWait(dpconf+".regOutput.intResult:_original.._value", res);  
}

void configurationSet() {
    dyn_string crates, ips;
    dpGet("OPC_Conf_General.configuration.set.crates", crates,
           "OPC_Conf_General.configuration.set.ips", ips);
     
    int res =  CMSfw_CAENOPCConfigurator_ConfigureOPC(crates, ips);
    
   dpSetWait(getSystemName()+"OPC_Conf_General.regOutput.intResult:_original.._value", res);
  
}

inputHandle(string dp, int idOperation)
{
  // Find the path needed for the CAEN Registry operations
  string path = CMSfw_CAENOPCConfigurator_getPath();
  


  // Intermediate variables
  dyn_string Result1;
  int Result2;
  string nameCrate, ipCrate;
  
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
      configurationGet() ;
      dpSetWait(getSystemName()+"OPC_Conf_General.regInput.idOperation:_original.._value", 0);
      break;
    case 9:
      configurationSet();
     dpSetWait(getSystemName()+"OPC_Conf_General.regInput.idOperation:_original.._value", 0);
      break;
  }
}
