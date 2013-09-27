#uses "fwFMC/fwFMCIpmi.ctl"
#uses "fwFMC/fwFMCMonitoring.ctl"
#uses "fwFMC/fwFMCProcess.ctl"

main()
{
 
  //IPMI  
//  dpQueryConnectSingle("fwFMCIpmi_createTempSensorsCB", 1, "createIpmiTempIdent", "SELECT '_online.._value' FROM '*.info.tempName' WHERE _DPT=\"FwFMCIpmi\"");
//  dpQueryConnectSingle("fwFMCIpmi_createFanSensorsCB", 1, "createIpmiFanIdent", "SELECT '_online.._value' FROM '*.info.fanName' WHERE _DPT=\"FwFMCIpmi\"");
//  dpQueryConnectSingle("fwFMCIpmi_createVoltageSensorsCB", 1, "createIpmiVoltageIdent", "SELECT '_online.._value' FROM '*.info.voltageName' WHERE _DPT=\"FwFMCIpmi\"");
//  dpQueryConnectSingle("fwFMCIpmi_createCurrentSensorsCB", 1, "createIpmiVoltageIdent", "SELECT '_online.._value' FROM '*.info.currentName' WHERE _DPT=\"FwFMCIpmi\"");  
  
  //Monitoring:
  dpQueryConnectSingle("fwFMCMonitoring_createCpuCB", 1, "createMonitoringCPUsIdent", "SELECT '_online.._value' FROM '*.readings.devices' WHERE _DPT=\"FwFMCCpuBase\"");
  dpQueryConnectSingle("fwFMCMonitoring_createFsCB", 1, "createMonitoringFileSystemsIdent", "SELECT '_online.._value' FROM '*.readings.devices' WHERE _DPT=\"FwFMCFsBase\"");
  dpQueryConnectSingle("fwFMCMonitoring_createNicCB", 1, "createMonitoringNetworkInterfacesIdent", "SELECT '_online.._value' FROM '*.readings.devices' WHERE _DPT=\"FwFMCNetworkBase\"");  
  
/*
  if(!dpExists("_fwFMCProcesses"))
  {
    dpCreate("_fwFMCProcesses", "_FwFMCServer");
    fwFMCProcess_dimSubscribeServer($node);
  }
  */  
  //Connect the status of the DIM managers:
  dpConnect("fwFMC_dimManagersCB", getSystemName() + "_Connections.Device.ManNums");  
  
  dyn_string serverDps = dpNames(getSystemName() + "_fwFMCProcess_*.server_info.dim_version", "_FwFMCServer");
  for(int i = 1; i <= dynlen(serverDps); i++)                        
    dpConnect("fwFMCProcess_initCB", serverDps[i]);  
  
  const int wait = 10;
  while(1)
  {
    dyn_string ex;
    fwFMC_setPmonReadoutStatuses(ex);
    
    if(dynlen(ex))
      DebugN("Ex = " + ex);
    
    delay(wait);
  }
  
  
}
