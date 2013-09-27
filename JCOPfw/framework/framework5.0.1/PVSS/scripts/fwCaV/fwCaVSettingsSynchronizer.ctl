main()
{
  dyn_string plantDps;
DebugTN("fwCaV: Starting settings synchronization script...");
  
  plantDps = dpNames("*", "FwCaVPlant");
  
  for(int i=1; i<=dynlen(plantDps); i++)
  {
    dyn_string loopNames, areaFlowNames, areaTempNames, dpsToConnect;
    string plantStatusDp = plantDps[i] + ".Actual.status";
DebugTN("fwCaV:    Found plant: " + plantDps[i]);
       
    loopNames = dpNames(plantDps[i] + "*", "FwCaVLoop");
    areaFlowNames = dpNames(plantDps[i] + "*", "FwCaVAreaflow");
    areaTempNames = dpNames(plantDps[i] + "*", "FwCaVAreatemp");
        
//    dpConnect("fwCaVKeepSettingsUpdated", TRUE, plantStatusDp, plantDps[i] + ".Actual.status");
    for(int j=1; j<=dynlen(loopNames); j++)
    {
DebugTN("fwCaV:      Found loop: " + loopNames[j]);
      dpConnect("fwCaVKeepSettingsUpdated", TRUE, plantStatusDp, loopNames[j] + ".Actual.status");
    }
    dynAppend(dpsToConnect, plantDps[i]);
    dynAppend(dpsToConnect, loopNames);
    dynAppend(dpsToConnect, areaFlowNames);
    dynAppend(dpsToConnect, areaTempNames);
    for(int j=1; j<=dynlen(dpsToConnect); j++)
    {
      for(int k=1; k<=32; k++)
      {
        string parameter;
        sprintf(parameter, "%02d", k);
//        dpConnect("fwCaVKeepSettingsUpdated", TRUE, plantStatusDp, dpsToConnect[j] + ".ReadBackSettings.Parameters.param" + parameter);
      }
    }
  }
DebugTN("fwCaV: Startup complete - entering monitor mode.");
}


fwCaVKeepSettingsUpdated(string plantStatusDp, int plantStatus, string readbackDpe, anytype readbackValue)
{
  int managerId;
  string settingDpe;
  anytype settingValue;
  
  if(getBit(plantStatus, 8))
  { 
    readbackDpe = dpSubStr(readbackDpe, DPSUB_SYS_DP_EL);
    settingDpe = readbackDpe;
    strreplace(settingDpe, "Actual", "Settings");
    strreplace(settingDpe, "status", "control");
    dpGet(settingDpe, settingValue,
          readbackDpe + ":_online.._manager", managerId);
   
    int maskedSetting = 0, maskedReadback = 0;
//    for(int i=0; i<=4; i++)
//    {
      maskedSetting=settingValue&15;
      maskedReadback=readbackValue&15;
      
//      setBit(maskedSetting, i, getBit(settingValue, i));
//      setBit(maskedReadback, i, getBit(readbackValue, i));
//    }    
DebugN(settingDpe,   settingValue, maskedSetting,readbackValue,maskedReadback);
    if(maskedSetting != maskedReadback)
    {
      char manType, manNum;    
      getManIdFromInt(managerId, manType, manNum);
      if(manType == (char)DRIVER_MAN)
      {
        if(getType(readbackValue) == INT_VAR)
        {
          int iValue = maskedReadback;
DebugTN("fwCaV: Updating DCS control word value (" + settingDpe + ") to: " + iValue);
        dpSetWait(settingDpe, iValue);
        }
      }
      else
      {
DebugTN("fwCaV: Not updating DCS request value (" + settingDpe + ") - readback not set by driver");      
      }
    }
  }
}
