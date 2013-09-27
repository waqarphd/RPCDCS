#uses "fwSystemOverview/fwSystemOverviewFunc.ctl"

string configFilePath = "";
unsigned refreshRate = 4;
bool isConfigured = FALSE;

main()
{
  bool success = FALSE;

  if(!dpExists( fwSystemOverviewFunc_DPNAME_ARRAY)){
    DebugN("fwSystemOverview_main(): fwSystemOverview configuration file path not present, use fwSystemOverview panel to configure and restart the manager");
    return;
  }
  
  fwSystemOverview_connectToConfigParameters();
  
  while(true){
    if(strlen(configFilePath) > 0)
      success = fwSystemOverviewFunc_readConfigFile(configFilePath);
  
  //   fileToString(filestr, result);
    DebugN("Success ? : " + success, "refreshRate: " + refreshRate);
    if(!success){
      DebugN("fwSystemOverview_main(): fwSystemOverview configuration File Reading Error");
      return;
    }
    
    fwSystemOverviewFunc_resetPollingFlags();
    
    fwSystemOverviewFunc_connectPollProjectDpe();
    delay(2);
    
    while(isConfigured){
      fwSystemOverviewFunc_pollSystems();
      delay(refreshRate, 0);
    }
    isConfigured = TRUE;
    fwSystemOverviewFunc_disconnectPollProjectDpe();
  }
}

fwSystemOverview_connectToConfigParameters()
{
  dyn_errClass err;

  if( !dpExists( fwSystemOverviewFunc_DPNAME_ARRAY + fwSystemOverviewFunc_REFRESH_RATE_STR))
  {
    DebugN("fwSystemOverview_connectToConfigParameters: No dpe present: " 
           + fwSystemOverviewFunc_DPNAME_ARRAY + fwSystemOverviewFunc_REFRESH_RATE_STR);
    return;
  }
  dpConnect("fwSystemOverview_connectToRefreshRateCB",
            fwSystemOverviewFunc_DPNAME_ARRAY + fwSystemOverviewFunc_REFRESH_RATE_STR);
  err = getLastError();
  if (dynlen(err) > 0)
    DebugN("fwSystemOverview_connectToConfigParameters: Could not connect to: " 
           + fwSystemOverviewFunc_DPNAME_ARRAY + fwSystemOverviewFunc_REFRESH_RATE_STR);


  if( !dpExists( fwSystemOverviewFunc_DPNAME_ARRAY + fwSystemOverviewFunc_CONF_FILE_STR))
  {
    DebugN("fwSystemOverview_connectToConfigParameters: No dpe present: " 
           + fwSystemOverviewFunc_DPNAME_ARRAY + fwSystemOverviewFunc_CONF_FILE_STR);
    return;
  }

  dpConnect("fwSystemOverview_connectToConfigPathCB",
            fwSystemOverviewFunc_DPNAME_ARRAY + fwSystemOverviewFunc_CONF_FILE_STR);
  err = getLastError();
  if (dynlen(err) > 0)
    DebugN("fwSystemOverview_connectToConfigParameters: Could not connect to: " 
           + fwSystemOverviewFunc_DPNAME_ARRAY + fwSystemOverviewFunc_CONF_FILE_STR);
}

fwSystemOverview_connectToConfigPathCB(string dp, string strNewValue)
{
  configFilePath = strNewValue;
  isConfigured = FALSE;
}

fwSystemOverview_connectToRefreshRateCB(string dp, unsigned uNewValue)
{
  refreshRate = uNewValue;
}
