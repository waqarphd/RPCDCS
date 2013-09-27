#uses "fwSystemOverview/fwSystemOverview.ctl"

main()
{
  if(fwSysOverview_isUpgradeRequired())
  {
    DebugN("WARNING: DP structure for the FW System Overview needs to be upgrade. Please, run the main graphical interface in order to proceed...");
    return;    
  }
  
  DebugTN("INFO: FW System Overview Tool Ctrl Manager started");  
  fwSysOverview_connectToConfigParameters();
  //Initialize thread heartbits:
  fwSysOverview_initializeThreadHeartbits();  
  dpConnect("fwSysOverview_enableMonitoring",fwSysOverview_PARAMETRIZATION + fwSysOverview_ENABLE_MONITORING);

  //Monitor threads:
  startThread("fwSysOverview_startThreadMonitor");
  
  while(1)
    delay(600);  
}
