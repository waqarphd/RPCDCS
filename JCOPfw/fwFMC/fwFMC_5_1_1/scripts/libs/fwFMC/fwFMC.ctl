//fwFMC.ctl library
#uses "fwFMC/fwFMCIpmi.ctl"
#uses "fwFMC/fwFMCMonitoring.ctl"
#uses "fwFMC/fwFMCTaskManager.ctl"
#uses "fwFMC/fwFMCLogger.ctl"
#uses "fwFMC/fwFMCProcess.ctl"
#uses "fwFMC/fwFMCPmon.ctl"
#uses "fwFMC/fwFMCDB.ctl"
#uses "fwNode/fwNode.ctl"
#uses "fwDevice/fwDevice.ctl"
#uses "fwSystemOverview/fwSystemOverview.ctl"

#uses "fwDIM"

const string FW_FMC_TOOL_VERSION_DPT = "5.0.1";
const string FW_FMC_LIB_VERSION = "5.1.1";

const string FW_FMC_INSTALLATION_TOOL_VERSION = "5.0.4";
const string FW_FMC_SYSTEM_CONFDB_VERSION = "4.1.3";

const string FW_FMC_NODE_DPT = "FwFMCNode";
const string FW_FMC_IPMI_DPT = "FwFMCIpmi";
const string FW_SYSTEM_OVERVIEW_NODE_DPT = "FwSystemOverviewPC";
const string FW_FMC_MONITORING_DPT = "FwFMCMonitoring";
const string FW_FMC_TASK_MANAGER_DPT = "FwFMCTaskManager";
const string FW_FMC_MONITORING_CPU_BASE = "FwFMCCpuBase";
const string FW_FMC_MONITORING_CPU = "FwFMCCpu";
const string FW_FMC_MONITORING_NETWORK_BASE = "FwFMCNetworkBase";
const string FW_FMC_MONITORING_NETWORK = "FwFMCNetwork";
const string FW_FMC_MONITORING_FS_BASE = "FwFMCFsBase";
const string FW_FMC_MONITORING_FS = "FwFMCFs";
const string FW_FMC_MONITORING_MEMORY = "FwFMCMem";
const string FW_FMC_LOGGER_DPT = "FwFMCLogger";
const string FW_FMC_IPMI_TEMP_SENSOR_DPT = "FwFMCIpmiTempSensor";
const string FW_FMC_IPMI_VOLTAGE_SENSOR_DPT = "FwFMCIpmiVoltageSensor";
const string FW_FMC_IPMI_FAN_SENSOR_DPT = "FwFMCIpmiFanSensor";
const string FW_FMC_IPMI_CURRENT_SENSOR_DPT = "FwFMCIpmiCurrentSensor";

const string FW_FMC_PROCESS_DPT = "FwFMCProcess";
const string FW_FMC_MONITORED_PROCESS_DPT = "FwFMCMonitoredProcess";
const string FW_FMC_MONITORED_SERVICE_DPT = "FwFMCMonitoredService";

const int FMC_MAX_NODES_CONFIG = 20; //Max number of nodes handled by a DIM config and therefore a PVSS00dim manager

//Logical View:
const string FW_FMC_GROUP_EDITOR_PNL = "fwFMC/fwFMC_groupManager";
const string FW_FMC_GROUP_NAVIGATOR_PNL = "fwFMC/fwFMC_groupNavigator";
const string FW_FMC_SYSTEM_LOGICAL_EDITOR_PNL = "fwFMC/fwFMC_systemManagerLogical";
const string FW_FMC_SYSTEM_LOGICAL_NAVIGATOR_PNL = "fwFMC/fwFMC_systemNavigatorLogical";
const string FW_FMC_LOGICAL_VENDOR = "FMC";

//Node states:
const string FW_FMC_ERROR_POWER_STATE = "ERROR";
const string FW_FMC_ON_POWER_STATE = "ON";
const string FW_FMC_OFF_POWER_STATE = "OFF";
const string FW_FMC_MIXED_POWER_STATE = "MIXED";
const string FW_FMC_UNKNOWN_POWER_STATE = "UNKNOWN";

//Reserved DIM API manager numbers:
const int FW_FMC_CONTINUOUS_MONITORING_DIM = 17;
const int FW_FMC_TEMPORARY_MONITORING_DIM = 18;
const int FW_FMC_TM_LOGGER_DIM = 19;
const int FW_FMC_IPMI_DIM = 20;
const int FW_FMC_PROCESS_DIM = 21;

//DIM save_now parameter in subscriptions:
const int FW_FMC_DIM_SAVE_NOW = 0;

//Beginning executable code:
bool fwFMC_isEnabled()
{
  bool enabled = false;
  dpGet("_fwFMCParameterization.enabled", enabled);
  
  return enabled;
}

void fwFMC_updateDbTs(string systemName = "")
{
  if(systemName == "")
    systemName = getSystemName();

  if(dpExists(systemName + "fwSysOverviewParametrization.dbLastUpdate"))
    dpSet(systemName + "fwSysOverviewParametrization.dbLastUpdate", true);  
}

int fwFMC_setPmonReadoutStatuses(dyn_string &ex)
{
  if(!isFunctionDefined("fwSysOverview_getHosts"))
  {
	return 0; //Nothing to be done.
  }
  
  dyn_string hostDps;
  fwSysOverview_getHosts(hostDps);
  int n = dynlen(hostDps);
  for(int i = 1; i <= n; i++)
  {
    dyn_string projectDps = fwSysOverview_getHostProjectDps(hostDps[i]);
    int m = dynlen(projectDps);
    
    int isOk = 0;
    if(m <= 0)
      isOk = 0;
    else
    {
      for(int j = 1; j <= m; j++)
      {
        int status = -1;
        bool monitoringDisabled;
        dpGet(projectDps[j] + ".readings.state", status,
              projectDps[j] + ".readings.disableMonitoring", monitoringDisabled);

        if(!monitoringDisabled)
        { 
          isOk = -1; //We found at least one project to be monitored
          if(status != fwSysOverview_PMON_NO_RESPONSE)
          {
            isOk = 1;
            break;
          }
        }
      }
    }
    string host = "";
    fwSysOverview_getHostDb(hostDps[i], host, ex);
    string fmcHostDp = fwSysOverview_getFMCdpName(host);
    dpSet(fmcHostDp + ".agentCommunicationStatus.pmon", isOk);    
  }
  
  return 0;
}

dyn_string fwSysOverview_getHostProjectDps(string hostDp)
{
  return dpNames(hostDp + "/*", "FwSystemOverviewProject");
}

string fwFMC_getNodeOs(string node, string systemName = "")
{
  string os;
  string procsController = "";
  if(systemName == "")
    systemName = getSystemName();
  
  int status = -1;
  dpGet(fwFMC_getNodeDp(node, systemName) + ".winProcsController" , procsController);
  if(procsController == "")
    os = "LINUX";
  else
    os = "WINDOWS";
  
  return strtoupper(os);  
}


int fwFMC_isCommunicationOK(string node, string module, string systemName = "")
{
  if(systemName == "")
    systemName = getSystemName();
  
  int status = -1;
  dpGet(fwFMC_getNodeDp(node, systemName) + ".agentCommunicationStatus." + module, status);
  
  return status;
}




string fwFMC_getNodeLocation(string node, string systemName)
{
  string location = "";
  if(systemName == "")
    systemName = getSystemName();
  
  string dp = fwFMC_getNodeDp(node, systemName);
  dpGet(dp + ".location", location);
  return location;    
}

dyn_string fwFMC_getAllNodeLocations(string systemName = "")
{
  dyn_string locations;
  if(systemName == "")
    systemName = getSystemName();
  
  dyn_string nodes;
  fwFMC_getNodes(nodes, systemName);
  for(int i = 1; i <= dynlen(nodes); i++)
  {
    string nodeLocation = fwFMC_getNodeLocation(nodes[i], systemName);
    if(nodeLocation != "")
      dynAppend(locations, nodeLocation);
  }
  dynUnique(locations);
  return locations;
}

string fwFMC_getNodeFromFsmDevice(string device)
{
  dyn_string ds = strsplit(device, "/");
  return ds[dynlen(ds)];  
}


bool fwFMC_archivingExists(string node, dyn_string &exception)
{
  string type;
  bool status = false;

  if(dpExists(fwFMC_getNodeDp(node)))
  {  
    dpGet(fwFMC_getNodeDp(node) + ".config.archivingType", type);
    
    if(type == "Standard" ||
       type == "Advanced")
      status = true;
  }
  
  return status;
}

bool fwFMC_alarmsExist(string node, dyn_string &exception)
{
  int type;
  bool status = false;

  if(dpExists(fwFMC_getNodeDp(node)))
  {  
    dpGet(fwFMC_getNodeDp(node) + ".readings.power_status:_alert_hdl.._type", type);
    if(type != DPCONFIG_NONE)
      status = true;
  }
  
  return status;
}

void _fwFMC_getAlarmsSettings(string deviceDpName, dyn_string &dpes, 
                              dyn_string &configTypes, dyn_dyn_string &texts, 
                              dyn_dyn_float &limits, dyn_dyn_string &classes, 
                              dyn_dyn_string &summaryDpeList, dyn_string &alertPanel, 
                              dyn_dyn_string &alertPanelParameters, dyn_string &help, 
                              dyn_string &exceptionInfo) 
{

  dyn_string dpElements;
  dyn_string defClasses; 
  dyn_string defTexts; 
  dyn_string defLimits; 
  dyn_bool defCanHave; 
 
  string deviceDpType = dpTypeName(deviceDpName), definitionDp, class;
   
  fwDevice_getDefinitionDp(makeDynString(deviceDpName), definitionDp, exceptionInfo);
  if(dynlen(exceptionInfo))
    return;
  
  dpGet(definitionDp + fwDevice_ELEMENTS, dpElements,
		     definitionDp + fwDevice_CONFIG_CAN_HAVE[fwDevice_ALERT_INDEX], defCanHave,
		     definitionDp + ".configuration.alert.defaultClasses", defClasses,
		     definitionDp + ".configuration.alert.defaultTexts", defTexts,
		     definitionDp + ".configuration.alert.defaultLimits", defLimits);  

  int j = 1;
  dyn_string ds;
  for(int i = 1; i <= dynlen(dpElements); i++){  
    if(defCanHave[i] == TRUE){  
      dynAppend(dpes, deviceDpName  + dpElements[i]);

      strreplace(defClasses[i], "||", " ");      
      ds = strsplit(defClasses[i], "|");
      for(int k = 1; k <= dynlen(ds); k++)
      {
        ds[k] = strrtrim(ds[k], "");
        ds[k] = strltrim(ds[k], "");
      }
//      if(patternMatch("|*", defClasses[i]))
//        dynInsertAt(ds, "", 1);
      
      if (patternMatch("*|", defClasses[i]))
        dynAppend(ds, "");
      
//DebugN("*********", ds, defClasses[i]);

      classes[j] = ds;
      
      ds = strsplit(defTexts[i], "|");
      for(int k = 1; k <= dynlen(ds); k++)
      {
        ds[k] = strrtrim(ds[k], "");
        ds[k] = strltrim(ds[k], "");
      }
      texts[j] = ds;
      
//      strreplace(defLimits[i], " ", "");
      ds = strsplit(defLimits[i], "|");
      for(int k = 1; k <= dynlen(ds); k++)
      {
        ds[k] = strrtrim(ds[k], "");
        ds[k] = strltrim(ds[k], "");
      }
      
      limits[j] = ds;
      
      summaryDpeList[j] = makeDynString();
      alertPanelParameters[j] = makeDynString();
      dynAppend(alertPanel, "");
      dynAppend(help, "N/A");
      configTypes[j] = DPCONFIG_ALERT_NONBINARYSIGNAL;
      ++j;
    }
  }
}

void fwFMC_setAlarmsIpmiSensors(string node, string type, dyn_string &exceptionInfo, bool active = TRUE)
{
  dyn_string deviceDpNames=makeDynString();

  fwDevice_initialize();  //Make sure all global variables in fwDevice.ctl get initialized!!

  if(fwFMCIpmi_exists(node))
  { 
    dynAppend(deviceDpNames,fwFMCIpmi_getAllSensorDpNames(node, type));
  }   
  
  for(int j = 1; j <= dynlen(deviceDpNames);j++)
  {
    dyn_dyn_string summaryDpeList, alertPanelParameters;
    string  alertPanel, help;
    dyn_string dpes, configTypes;
    dyn_dyn_string classes, texts;
    dyn_bool canHave;
    dyn_dyn_float limits;
    
    _fwFMC_getAlarmsSettings(deviceDpNames[j], dpes, configTypes, texts, limits, classes, summaryDpeList, alertPanel, alertPanelParameters, help, exceptionInfo);
    
     //DebugN(dpes, configTypes, texts, limits, classes);//, summaryDpeList, alertPanel, alertPanelParameters, help, exceptionInfo);
     
    if(active) 
    {   
      fwAlertConfig_setMany(dpes, configTypes, texts, limits, classes, summaryDpeList, alertPanel, alertPanelParameters, help, exceptionInfo);    
      fwAlertConfig_activateMultiple(dpes, exceptionInfo);
    }
    else
      fwAlertConfig_deactivateMultiple(dpes, exceptionInfo);
    
    if(exceptionInfo != "") DebugTN(exceptionInfo);    
    
  }
  
  return;
}

void fwFMC_setDefaultAlarms(string node, dyn_string &exceptionInfo, bool active = TRUE)
{
  dyn_string deviceDpNames=makeDynString();

  fwDevice_initialize();  //Make sure all global variables in fwDevice.ctl get initialized!!

  //Node itself:
  //Initializing the variables
  int val = 0;
  string dp = fwFMC_getNodeDp(node);
  dpGet(dp + ".agentCommunicationStatus.monitoring.memory:_alert_hdl.._type", val);
  if(val == DPCONFIG_NONE)
    dynAppend(deviceDpNames, dp);
  
  if(fwFMCIpmi_exists(node))
  {
    dp = fwFMCIpmi_getDp(node);
    dpGet(dp + ".readings.power_status:_alert_hdl.._type", val);
    if(val == DPCONFIG_NONE)
      dynAppend(deviceDpNames, dp);
  }
  
  if(fwFMCProcess_exists(node))
  { 
    if(dynlen(fwFMCProcess_getMonitoredProcesses(node,exceptionInfo))>0)
    {
      dyn_string procs = fwFMCProcess_getMonitoredProcesses(node,exceptionInfo);
      
      for(int i = 1; i <= dynlen(procs); i++)            
      {
        dp = fwFMCProcess_getDp(node) + "/MonitoredProcesses/" + procs[i];
        dpGet(dp + ".readings.state:_alert_hdl.._type", val);
        if(val == DPCONFIG_NONE)
          dynAppend(deviceDpNames, dp);
      }      
      if(exceptionInfo != "") DebugTN(exceptionInfo);   
    } 
  } 

  if(fwFMCMonitoring_fsExists(node))
  { 
    dyn_string deviceFSDpNames;
    
    fwFMCMonitoring_getFSDps(node,deviceFSDpNames);
    if(exceptionInfo != "") DebugTN(exceptionInfo);

    for(int i = 1; i <= dynlen(deviceFSDpNames); i++)
    {
      dp = deviceFSDpNames[i];
      dpGet(dp + ".readings.user:_alert_hdl.._type", val);
      if(val == DPCONFIG_NONE)
        dynAppend(deviceDpNames, dp);
    }   
  }
  
  for(int j = 1; j <= dynlen(deviceDpNames);j++)
  {
    dyn_dyn_string summaryDpeList, alertPanelParameters;
    dyn_string  alertPanel, help;
    dyn_string dpes, configTypes;
    dyn_dyn_string classes, texts;
    dyn_bool canHave;
    dyn_dyn_float limits;
    
    _fwFMC_getAlarmsSettings(deviceDpNames[j], dpes, configTypes, texts, limits, classes, summaryDpeList, alertPanel, alertPanelParameters, help, exceptionInfo);
    
   //DebugN(dpes, configTypes, texts, limits, classes, summaryDpeList, alertPanel, alertPanelParameters, help, exceptionInfo);
     
    if(active) 
    {   
      fwAlertConfig_setMany(dpes, configTypes, texts, limits, classes, summaryDpeList, alertPanel, alertPanelParameters, help, exceptionInfo);    
      if (fwFMC_isEnabled())
        fwAlertConfig_activateMultiple(dpes, exceptionInfo);
    }
    else
      fwAlertConfig_deactivateMultiple(dpes, exceptionInfo);
    
    if(exceptionInfo != "") DebugTN(exceptionInfo);    
    
  }
  
  return;
}

bool fwFMC_areAlarmsEnabled(string node)    
{
  
  bool status = false;
  string dp = fwFMC_getNodeDp(node);

  if(dpExists(dp))  
    dpGet(dp + ".readings.power_status:_alert_hdl.._active", status);

//DebugN(dp + ".readings.power_status:_alert_hdl.._active", status);  
  
  return status;
}

string fwFMC_isArchivingEnabled(string node)    
{
  string type = "NONE";
  
  if(dpExists(fwFMC_getNodeDp(node)))
    dpGet(fwFMC_getNodeDp(node) + ".config.archivingType", type);
  
/*  
  bool status = false;
  string dp = fwFMC_getNodeDp(node);

  if(dpExists(dp))  
    dpGet(dp + ".readings.power_status:_archive.._archive", status);
    
  if(status == true)
  {
    status = false;
    type = "Standard";
    
    //Find archiving type:
    if(dpExists(dp + "/Monitoring/Memory.readings.free:_archive.._archive"))
      dpGet(dp + "/Monitoring/Memory.readings.free:_archive.._archive", status);
    
    if(status)
      type = "Advanced";
  }
*/  
  return type;
}


    
////Begin Claire:
void _fwFMC_getArchivingSettings(string deviceDpName, dyn_string &dpes, dyn_string &defaultClasses, dyn_float &deadbands, 
            dyn_float &timeIntervals, dyn_int &smoothTypes, dyn_int &smoothProcedures, dyn_bool &canHaveArchive){

  dyn_string exceptionInfo;
  dyn_string dpElements;
  dyn_string defDefaultClasses; 
  dyn_float defDeadbands;
  dyn_float defTimeIntervals; 
  dyn_int defSmoothTypes; 
  dyn_int defSmoothProcedures; 
  dyn_bool defCanHaveArchive;
  
  string deviceDpType = dpTypeName(deviceDpName), definitionDp, class;
   
  fwDevice_getDefinitionDp(makeDynString(deviceDpName), definitionDp, exceptionInfo);
  if(dynlen(exceptionInfo))
    return;
  
    dpGet(definitionDp + fwDevice_ELEMENTS, dpElements,
			     definitionDp + ".configuration.archive.canHave", defCanHaveArchive,
			     definitionDp + ".configuration.archive.defaultClass", defDefaultClasses,
			     definitionDp + ".configuration.archive.smoothType", defSmoothTypes,
			     definitionDp + ".configuration.archive.smoothProcedure", defSmoothProcedures,
			     definitionDp + ".configuration.archive.deadband", defDeadbands,
			     definitionDp + ".configuration.archive.timeInterval", defTimeIntervals);  
//DebugN(deCanHaveArchive);
  for(int i = 1; i <= dynlen(dpElements); i++){  
    if(defCanHaveArchive[i] == TRUE){  
      dynAppend(dpes, deviceDpName  + dpElements[i]);
      dynAppend(defaultClasses, defDefaultClasses[i]);
      dynAppend(deadbands, defDeadbands[i]);
      dynAppend(timeIntervals, defTimeIntervals[i]);
      dynAppend(smoothTypes, defSmoothTypes[i]);
      dynAppend(smoothProcedures, defSmoothProcedures[i]);
      dynAppend(canHaveArchive, defCanHaveArchive[i]);
    }
  }

}

synchronized fwFMC_setDefaultArchive(string node, dyn_string &exceptionInfo, bool active = TRUE, bool advanced = FALSE)
{
  dyn_string archiveClass;  
  dyn_bool canHaveArchive;
  dyn_int archiveType;
  dyn_string archiveClassDps;
  dyn_int smoothTypes, smoothProcedures;
  dyn_float deadbands, timeIntervals;
  dyn_string dpElements, defaultClasses, dpes;
  dyn_string deviceDpNames; 
  fwDevice_initialize();  //Make sure all global variables in fwDevice.ctl get initialized!!

  //Node itself:
  //Initializing the variables
  archiveClass=makeDynString(); 
  archiveClassDps=makeDynString();
  archiveType=makeDynInt("");
  deviceDpNames=makeDynString();
  
//DebugN("set default archived called with ", node, active, advanced);    
  dynAppend(deviceDpNames,fwFMC_getNodeDp(node));
    
  for(int j = 1; j <= dynlen(deviceDpNames);j++)
  {
    smoothTypes=makeDynInt();
    smoothProcedures=makeDynInt();
    deadbands=makeDynFloat();
    timeIntervals=makeDynFloat();
    defaultClasses=makeDynString();
    dpes=makeDynString();
    canHaveArchive=makeDynBool();
  
    _fwFMC_getArchivingSettings(deviceDpNames[j], dpes, defaultClasses, deadbands, 
                timeIntervals, smoothTypes, smoothProcedures, canHaveArchive);
     

//DebugN(">>>>>>>>>>>>>>>>>active = " + active + "  archivingExists = " + fwFMC_archivingExists(node, exceptionInfo));      
    if(active)
      fwArchive_setMany(dpes, defaultClasses, smoothTypes, smoothProcedures, deadbands, timeIntervals, exceptionInfo);    
    else if(fwFMC_archivingExists(node, exceptionInfo))
      fwArchive_stopMultiple(dpes, exceptionInfo);
    
    if(exceptionInfo != "") DebugTN(exceptionInfo);    
  }
  
  
  if(fwFMCIpmi_exists(node))
  { 
    //Initializing the variables
    archiveClass=makeDynString(); 
    archiveClassDps=makeDynString();
    archiveType=makeDynInt("");
    deviceDpNames=makeDynString();
    
    dynAppend(deviceDpNames,fwFMCIpmi_getDp(node));
    dynAppend(deviceDpNames,fwFMCIpmi_getAllSensorDpNames(node,"temp"));
    dynAppend(deviceDpNames,fwFMCIpmi_getAllSensorDpNames(node,"fan"));
    dynAppend(deviceDpNames,fwFMCIpmi_getAllSensorDpNames(node,"voltage"));
    dynAppend(deviceDpNames,fwFMCIpmi_getAllSensorDpNames(node,"current"));
    
    for(int j = 1; j <= dynlen(deviceDpNames);j++){

      smoothTypes=makeDynInt();
      smoothProcedures=makeDynInt();
      deadbands=makeDynFloat();
      timeIntervals=makeDynFloat();
      defaultClasses=makeDynString();
      dpes=makeDynString();
      canHaveArchive=makeDynBool();
    
      _fwFMC_getArchivingSettings(deviceDpNames[j], dpes, defaultClasses, deadbands, 
                  timeIntervals, smoothTypes, smoothProcedures, canHaveArchive);


    if(active)    
      fwArchive_setMany(dpes, 
                        defaultClasses, 
                        smoothTypes, 
                        smoothProcedures, 
                        deadbands, 
                        timeIntervals, 
                        exceptionInfo);    
    else if(fwFMC_archivingExists(node, exceptionInfo))
      fwArchive_stopMultiple(dpes, exceptionInfo);
    
    if(exceptionInfo != "") DebugTN(exceptionInfo);    
    }
  }  

  if(fwFMCProcess_exists(node))
  { 
    //Initializing the variables
    archiveClass=makeDynString(); 
    archiveClassDps=makeDynString();
    archiveType=makeDynInt();
    deviceDpNames=makeDynString();
    smoothTypes=makeDynInt();
    smoothProcedures=makeDynInt();
    deadbands=makeDynFloat();
    timeIntervals=makeDynFloat();
    defaultClasses=makeDynString();
    dpes=makeDynString();
    canHaveArchive=makeDynBool();
    
    if(dynlen(fwFMCProcess_getMonitoredProcesses(node,exceptionInfo))>0){
      dynAppend(deviceDpNames,fwFMCProcess_getDp(node)+"/MonitoredProcesses/"+fwFMCProcess_getMonitoredProcesses(node,exceptionInfo));
      
      if(exceptionInfo != "") DebugTN(exceptionInfo);   
    
      if(dynlen(deviceDpNames)>0){
        for(int j = 1; j <= dynlen(deviceDpNames);j++){
    
          smoothTypes=makeDynInt();
          smoothProcedures=makeDynInt();
          deadbands=makeDynFloat();
          timeIntervals=makeDynFloat();
          defaultClasses=makeDynString();
          canHaveArchive=makeDynBool();
          dpes=makeDynString();
    
          _fwFMC_getArchivingSettings(deviceDpNames[j], dpes, defaultClasses, deadbands, 
                      timeIntervals, smoothTypes, smoothProcedures, canHaveArchive);      
          
      if(active)    
        fwArchive_setMany(dpes, defaultClasses, smoothTypes, smoothProcedures, deadbands, timeIntervals, exceptionInfo);    
      else if(fwFMC_archivingExists(node, exceptionInfo))
        fwArchive_stopMultiple(dpes, exceptionInfo);
    
      if(exceptionInfo != "") DebugTN(exceptionInfo);    
        }
      }
    }
  }
  
  if(fwFMCMonitoring_fsExists(node))
  { 
    //Initializing the variables
    archiveClass=makeDynString(); 
    archiveClassDps=makeDynString();
    archiveType=makeDynInt();
    deviceDpNames=makeDynString();
    smoothTypes=makeDynInt();
    smoothProcedures=makeDynInt();
    deadbands=makeDynFloat();
    timeIntervals=makeDynFloat();
    defaultClasses=makeDynString();
    dpes=makeDynString();
    canHaveArchive=makeDynBool();
    
    fwFMCMonitoring_getFSDps(node,deviceDpNames);
    
    if(exceptionInfo != "") DebugTN(exceptionInfo);   
    
    if(dynlen(deviceDpNames)>0){
      for(int j = 1; j <= dynlen(deviceDpNames);j++){
    
          smoothTypes=makeDynInt();
          smoothProcedures=makeDynInt();
          deadbands=makeDynFloat();
          timeIntervals=makeDynFloat();
          defaultClasses=makeDynString();
          canHaveArchive=makeDynBool();
          dpes=makeDynString();
    
          _fwFMC_getArchivingSettings(deviceDpNames[j], dpes, defaultClasses, deadbands, 
                      timeIntervals, smoothTypes, smoothProcedures, canHaveArchive);  

      if(active)    
        fwArchive_setMany(dpes, defaultClasses, smoothTypes, smoothProcedures, deadbands, timeIntervals, exceptionInfo);    
      else if(fwFMC_archivingExists(node, exceptionInfo))
        fwArchive_stopMultiple(dpes, exceptionInfo);

      if(exceptionInfo != "") DebugTN(exceptionInfo);  
    
      }
    }
  }
  
   if(fwFMCTaskManager_exists(node))
  { 
    //Initializing the variables
    archiveClass=makeDynString(); 
    archiveClassDps=makeDynString();
    archiveType=makeDynInt();
    deviceDpNames=makeDynString();
    smoothTypes=makeDynInt();
    smoothProcedures=makeDynInt();
    deadbands=makeDynFloat();
    timeIntervals=makeDynFloat();
    defaultClasses=makeDynString();
    dpes=makeDynString();
    canHaveArchive=makeDynBool();
    
    dynAppend(deviceDpNames,fwFMCTaskManager_getDp(node));
    
    if(exceptionInfo != "") DebugTN(exceptionInfo);   
    
    if(dynlen(deviceDpNames)>0){
      for(int j = 1; j <= dynlen(deviceDpNames);j++){
    
        smoothTypes=makeDynInt();
        smoothProcedures=makeDynInt();
        deadbands=makeDynFloat();
        timeIntervals=makeDynFloat();
        defaultClasses=makeDynString();
        dpes=makeDynString();
        canHaveArchive=makeDynBool();
    
        _fwFMC_getArchivingSettings(deviceDpNames[j], dpes, defaultClasses, deadbands, 
                    timeIntervals, smoothTypes, smoothProcedures, canHaveArchive);  
      
        if(active)    
          fwArchive_setMany(dpes, defaultClasses, smoothTypes, smoothProcedures, deadbands, timeIntervals, exceptionInfo);    
        else if(fwFMC_archivingExists(node, exceptionInfo))
          fwArchive_stopMultiple(dpes, exceptionInfo);
        
        if(exceptionInfo != "") DebugTN(exceptionInfo);    
      }
    }
  } 

  string archivingType;
  
  if(!active)
    archivingType = "NONE";
  else if(!advanced)
    archivingType = "Standard";
  else
    archivingType = "Advanced";
  
   dpSet(fwFMC_getNodeDp(node) + ".config.archivingType", archivingType);
   
   if(archivingType != "Advanced")
     return; //we are done
   
   if(fwFMCMonitoring_networksExists(node))
   {
    fwFMC_setArchiveNetwork(node, exceptionInfo, advanced);
  }
  
  if(fwFMCMonitoring_cpusExists(node))
  {
    fwFMC_setArchiveCPU(node, exceptionInfo, advanced);
  }
    
  if(fwFMCMonitoring_memoryExists(node))
  {
    fwFMC_setArchiveMemory(node, exceptionInfo, advanced);
  }   
  
  return;
}

synchronized fwFMC_setArchiveIpmiSensors(string node, string type, dyn_string &exceptionInfo, bool active = TRUE)
{
  dyn_string archiveClass;  
  dyn_bool canHaveArchive;
  dyn_int archiveType;
  dyn_string archiveClassDps;
  dyn_int smoothTypes, smoothProcedures;
  dyn_float deadbands, timeIntervals;
  dyn_string dpElements, defaultClasses, dpes;
  dyn_string deviceDpNames; 
  fwDevice_initialize();  //Make sure all global variables in fwDevice.ctl get initialized!!

  //Node itself:
    
  if(fwFMCIpmi_exists(node))
  { 
    //Initializing the variables
    archiveClass=makeDynString(); 
    archiveClassDps=makeDynString();
    archiveType=makeDynInt("");
    deviceDpNames=makeDynString();
    
    dynAppend(deviceDpNames,fwFMCIpmi_getAllSensorDpNames(node, type));
    
    for(int j = 1; j <= dynlen(deviceDpNames);j++){

      smoothTypes=makeDynInt();
      smoothProcedures=makeDynInt();
      deadbands=makeDynFloat();
      timeIntervals=makeDynFloat();
      defaultClasses=makeDynString();
      dpes=makeDynString();
      canHaveArchive=makeDynBool();
    
      _fwFMC_getArchivingSettings(deviceDpNames[j], dpes, defaultClasses, deadbands, 
                  timeIntervals, smoothTypes, smoothProcedures, canHaveArchive);
      
    if(active)    
      fwArchive_setMany(dpes, defaultClasses, smoothTypes, smoothProcedures, deadbands, timeIntervals, exceptionInfo);    
    else
      fwArchive_stopMultiple(dpes, exceptionInfo);
    
    if(exceptionInfo != "") DebugTN(exceptionInfo);    
    }
  }  

  return;
}


synchronized fwFMC_setArchiveNetwork(string node, dyn_string &exceptionInfo, bool active = TRUE)
{
   
  fwDevice_initialize();  //Make sure all global variables in fwDevice.ctl get initialized!!
  
  if(fwFMCMonitoring_networksExists(node))
  { 
    //Initializing the variables
    dyn_string archiveClass;  
    dyn_bool canHaveArchive;
    dyn_int archiveType;
    dyn_string archiveClassDps;
    dyn_int smoothTypes, smoothProcedures;
    dyn_float deadbands, timeIntervals;
    dyn_string dpElements, defaultClasses, dpes;
    dyn_string deviceDpNames; 
    
    fwFMCMonitoring_getNetworkDps(node,deviceDpNames);
    
    for(int j = 1; j <= dynlen(deviceDpNames);j++){
    
      smoothTypes=makeDynInt();
      smoothProcedures=makeDynInt();
      deadbands=makeDynFloat();
      timeIntervals=makeDynFloat();
      defaultClasses=makeDynString();
      canHaveArchive=makeDynBool();
      dpes=makeDynString();
    
      _fwFMC_getArchivingSettings(deviceDpNames[j], dpes, defaultClasses, deadbands, 
                  timeIntervals, smoothTypes, smoothProcedures, canHaveArchive);

      if(active)    
        fwArchive_setMany(dpes, defaultClasses, smoothTypes, smoothProcedures, deadbands, timeIntervals, exceptionInfo);    
      else
        fwArchive_stopMultiple(dpes, exceptionInfo);
    
      if(exceptionInfo != "") DebugTN(exceptionInfo);    
    }
  }  
}


synchronized fwFMC_setArchiveFS(string node, dyn_string &exceptionInfo, bool active = TRUE)
{
   
  fwDevice_initialize();  //Make sure all global variables in fwDevice.ctl get initialized!!
  
  if(fwFMCMonitoring_fsExists(node))
  { 
    //Initializing the variables
    dyn_string archiveClass;  
    dyn_bool canHaveArchive;
    dyn_int archiveType;
    dyn_string archiveClassDps;
    dyn_int smoothTypes, smoothProcedures;
    dyn_float deadbands, timeIntervals;
    dyn_string dpElements, defaultClasses, dpes;
    dyn_string deviceDpNames; 
    
    fwFMCMonitoring_getFSDps(node,deviceDpNames);
    for(int j = 1; j <= dynlen(deviceDpNames);j++){
    
      smoothTypes=makeDynInt();
      smoothProcedures=makeDynInt();
      deadbands=makeDynFloat();
      timeIntervals=makeDynFloat();
      defaultClasses=makeDynString();
      canHaveArchive=makeDynBool();
      dpes=makeDynString();

      //Skip the filesystem dpe if an archiving config already exists as it may not be the default one:
      int archiveExists = 0;
      dpGet(deviceDpNames[j] + ".readings.user:_archive.._type", archiveExists);
      if(archiveExists != DPCONFIG_NONE)
        continue;
        
      _fwFMC_getArchivingSettings(deviceDpNames[j], dpes, defaultClasses, deadbands, 
                  timeIntervals, smoothTypes, smoothProcedures, canHaveArchive);

      if(active)    
        fwArchive_setMany(dpes, defaultClasses, smoothTypes, smoothProcedures, deadbands, timeIntervals, exceptionInfo);    
      else
        fwArchive_stopMultiple(dpes, exceptionInfo);
    
      if(exceptionInfo != "") DebugTN(exceptionInfo);    
    }
  }  
}

synchronized fwFMC_setArchiveCPU(string node, dyn_string &exceptionInfo, bool active = true)
{   
  fwDevice_initialize();  //Make sure all global variables in fwDevice.ctl get initialized!!
  
  if(fwFMCMonitoring_cpusExists(node))
  { 
    //Initializing the variables
    dyn_string archiveClass;  
    dyn_bool canHaveArchive;
    dyn_int archiveType;
    dyn_string archiveClassDps;
    dyn_int smoothTypes, smoothProcedures;
    dyn_float deadbands, timeIntervals;
    dyn_string dpElements, defaultClasses, dpes;
    dyn_string deviceDpNames; 
    
    fwFMCMonitoring_getCpuDps(node,deviceDpNames);
    
    for(int j = 1; j <= dynlen(deviceDpNames);j++){
    
      smoothTypes=makeDynInt();
      smoothProcedures=makeDynInt();
      deadbands=makeDynFloat();
      timeIntervals=makeDynFloat();
      defaultClasses=makeDynString();
      dpes=makeDynString();
      canHaveArchive=makeDynBool();
    
      _fwFMC_getArchivingSettings(deviceDpNames[j], dpes, defaultClasses, deadbands, 
                  timeIntervals, smoothTypes, smoothProcedures, canHaveArchive);  

      if(active)    
        fwArchive_setMany(dpes, defaultClasses, smoothTypes, smoothProcedures, deadbands, timeIntervals, exceptionInfo);    
      else
        fwArchive_stopMultiple(dpes, exceptionInfo);
      
      if(exceptionInfo != "") DebugTN(exceptionInfo);    
    }
  }  
}

synchronized fwFMC_setArchiveMemory(string node, dyn_string &exceptionInfo, bool active = true)
{
   
  fwDevice_initialize();  //Make sure all global variables in fwDevice.ctl get initialized!!
  
  if(fwFMCMonitoring_memoryExists(node))
  { 
    //Initializing the variables
    dyn_string archiveClass;  
    dyn_bool canHaveArchive;
    dyn_int archiveType;
    dyn_string archiveClassDps;
    dyn_int smoothTypes, smoothProcedures;
    dyn_float deadbands, timeIntervals;
    dyn_string dpElements, defaultClasses, dpes;
    dyn_string deviceDpNames; 
    
    dynAppend(deviceDpNames,fwFMCMonitoring_getDp(node)+"/Memory");
    
    for(int j = 1; j <= dynlen(deviceDpNames);j++){
    
      smoothTypes=makeDynInt();
      smoothProcedures=makeDynInt();
      deadbands=makeDynFloat();
      timeIntervals=makeDynFloat();
      defaultClasses=makeDynString();
      dpes=makeDynString();
      canHaveArchive=makeDynBool();
    
      _fwFMC_getArchivingSettings(deviceDpNames[j], dpes, defaultClasses, deadbands, 
                  timeIntervals, smoothTypes, smoothProcedures, canHaveArchive);  

      if(active)    
        fwArchive_setMany(dpes, defaultClasses, smoothTypes, smoothProcedures, deadbands, timeIntervals, exceptionInfo);    
      else
        fwArchive_stopMultiple(dpes, exceptionInfo);
      
      if(exceptionInfo != "") DebugTN(exceptionInfo);    
    }
  }  
}

synchronized fwFMC_setArchiveCpuBase(string node, dyn_string &exceptionInfo, bool active = true)
{
   
  fwDevice_initialize();  //Make sure all global variables in fwDevice.ctl get initialized!!
  
  if(fwFMCMonitoring_exists(node))
  { 
    //Initializing the variables
    dyn_string archiveClass;  
    dyn_bool canHaveArchive;
    dyn_int archiveType;
    dyn_string archiveClassDps;
    dyn_int smoothTypes, smoothProcedures;
    dyn_float deadbands, timeIntervals;
    dyn_string dpElements, defaultClasses, dpes;
    dyn_string deviceDpNames; 
    
    dynAppend(deviceDpNames,fwFMCMonitoring_getDp(node)+"/Cpus");
    
    for(int j = 1; j <= dynlen(deviceDpNames);j++){
    
      smoothTypes=makeDynInt();
      smoothProcedures=makeDynInt();
      deadbands=makeDynFloat();
      timeIntervals=makeDynFloat();
      defaultClasses=makeDynString();
      dpes=makeDynString();
      canHaveArchive=makeDynBool();
    
      _fwFMC_getArchivingSettings(deviceDpNames[j], dpes, defaultClasses, deadbands, 
                  timeIntervals, smoothTypes, smoothProcedures, canHaveArchive);  

      if(active)    
        fwArchive_setMany(dpes, defaultClasses, smoothTypes, smoothProcedures, deadbands, timeIntervals, exceptionInfo);    
      else
        fwArchive_stopMultiple(dpes, exceptionInfo);
      
      if(exceptionInfo != "") DebugTN(exceptionInfo);    
    }
  }  
}

void fwFMC_connectPowerStatusDpe(string node, dyn_string &exception)
{    
  string nodeDp = fwFMC_getNodeDp(node);
 
  fwDpFunction_setDpeConnection(nodeDp + ".readings.power_status", 
                                makeDynString(nodeDp + ".agentCommunicationStatus.monitoring.memory:_online.._value",
                                              nodeDp + ".agentCommunicationStatus.monitoring.cpuinfo:_online.._value",
                                              nodeDp + ".agentCommunicationStatus.monitoring.cpustat:_online.._value",
                                              nodeDp + ".agentCommunicationStatus.monitoring.network:_online.._value",
                                              nodeDp + ".agentCommunicationStatus.monitoring.fs:_online.._value",
                                              nodeDp + ".agentCommunicationStatus.monitoring.os:_online.._value",
                                              nodeDp + ".agentCommunicationStatus.process:_online.._value",
                                              nodeDp + ".agentCommunicationStatus.taskManager:_online.._value",
                                              nodeDp + ".agentCommunicationStatus.logger:_online.._value",
                                              nodeDp + ".agentCommunicationStatus.ipmi:_online.._value",
                                              nodeDp + ".readings.ipmi.power_status:_online.._value",
                                              nodeDp + ".agentCommunicationStatus.pmon:_online.._value"
                                              ),
                                makeDynString(),
                                "p10==1&&p11==1?1:p10==1&&p11==0?0:p1==1||p2==1||p3==1||p4==1||p5==1||p6==1||p7==1||p8==1||p9==1||p12==1?1:(p1==-1||p1==0)&&(p2==-1||p2==0)&&(p3==-1||p3==0)&&(p4==-1||p4==0)&&(p5==-1||p5==0)&&(p6==-1||p6==0)&&(p7==-1||p7==0)&&(p8==-1||p8==0)&&(p9==-1||p9==0)&&(p10==-1||p10==0)&&(p12==-1||p12==0)?-1:(p10 == 1 && (p11 != 0 || p11 != 1))?-2:0",
//                                "p10==1&&p11==1?1:p10==1&&p11==0?0:p1==1||p2==1||p3==1||p4==1||p5==1||p6==1||p7==1||p8==1||p9==1||p12==1?1:(p1==-1||p1==0)&&(p2==-1||p2==0)&&(p3==-1||p3==0)&&(p4==-1||p4==0)&&(p5==-1||p5==0)&&(p6==-1||p6==0)&&(p7==-1||p7==0)&&(p8==-1||p8==0)&&(p9==-1||p9==0)&&(p10==-1||p10==0)&&(p12==-1||p12==0)?-1:0",
//                                "p10==1&&p11==1?1:p10==1&&p11==0?0:p1==1||p2==1||p3==1||p4==1||p5==1||p6==1||p7==1||p8==1||p9==1?1:(p1==-1||p1==0)&&(p2==-1||p2==0)&&(p3==-1||p3==0)&&(p4==-1||p4==0)&&(p5==-1||p5==0)&&(p6==-1||p6==0)&&(p7==-1||p7==0)&&(p8==-1||p8==0)&&(p9==-1||p9==0)&&(p10==-1||p10==0)?-1:0",
                                exception,
                                1);

  return;
}

void fwFMC_connectReadoutStatusDpe(string node, dyn_string &exception)
{    
  string nodeDp = fwFMC_getNodeDp(node);
 
  fwDpFunction_setDpeConnection(nodeDp + ".agentCommunicationStatus.summary", 
                                makeDynString(nodeDp + ".agentCommunicationStatus.monitoring.memory:_online.._value",
                                              nodeDp + ".agentCommunicationStatus.monitoring.cpuinfo:_online.._value",
                                              nodeDp + ".agentCommunicationStatus.monitoring.cpustat:_online.._value",
                                              nodeDp + ".agentCommunicationStatus.monitoring.network:_online.._value",
                                              nodeDp + ".agentCommunicationStatus.monitoring.fs:_online.._value",
                                              nodeDp + ".agentCommunicationStatus.monitoring.os:_online.._value",
                                              nodeDp + ".agentCommunicationStatus.process:_online.._value",
                                              nodeDp + ".agentCommunicationStatus.taskManager:_online.._value",
                                              nodeDp + ".agentCommunicationStatus.logger:_online.._value",
                                              nodeDp + ".agentCommunicationStatus.ipmi:_online.._value",
                                              nodeDp + ".agentCommunicationStatus.pmon:_online.._value",
                                              "_fwFMCParameterization.enabled:_online.._value"
                                              ),
                                makeDynString(),
                                "p12==0?0:p1<=-1||p2<=-1||p3<=-1||p4<=-1||p5<=-1||p6<=-1||p7<=-1||p8<=-1||p9<=-1||p10<=-1||p11<=-1?-1:p1==0&&p2==0&&p3==0&&p4==0&&p5==0&&p6==0&&p7==0&&p8==0&&p9==0&&p10==0&&p11==0?0:1",
//                                "p1<=-1||p2<=-1||p3<=-1||p4<=-1||p5<=-1||p6<=-1||p7<=-1||p8<=-1||p9<=-1||p10<=-1||p11<=-1?-1:p1==0&&p2==0&&p3==0&&p4==0&&p5==0&&p6==0&&p7==0&&p8==0&&p9==0&&p10==0&&p11==0?0:1",
//                                "p1<=-1||p2<=-1||p3<=-1||p4<=-1||p5<=-1||p6<=-1||p7<=-1||p8<=-1||p9<=-1||p10<=-1?-1:p1==0&&p2==0&&p3==0&&p4==0&&p5==0&&p6==0&&p7==0&&p8==0&&p9==0&&p10==0?0:1",
                                exception,
                                1);
  
  return;
}


fwFMC_getNodeGroup(string node, string systemName, string &group, dyn_string &exceptionInfo)
{
  string nodeDp = fwFMC_getNodeDp(node, systemName);
  string alias = dpGetAlias(nodeDp);
  
  if(alias == "")
  {
    group = ""; 
    return;
  }
  
  dyn_string ds = strsplit(alias, "/");
  if(dynlen(ds) <= 0)
  {
    group = "";
    fwException_raise(exceptionInfo, "ERROR", "Invalid alias format. Logical view may be corrupted. Alias: " + alias, -9999);
    DebugN("ERROR: fwFMC_getNodeGroup() -> Invalid alias format. Logical view may be corrupted. Alias: " + alias);
    return;
  }
    
  group = ds[dynlen(ds) - 1];
  
}

fwFMC_getNodeProperties(string node, string systemName, dyn_mixed &nodeInfo, dyn_string &exceptionInfo)
{
  dyn_mixed ipmiInfo, monitoringInfo, tmInfo, loggerInfo, processInfo;
  
  if(!dpExists(fwFMC_getNodeDp(node, systemName)))
  {
    fwException_raise(exceptionInfo, "ERROR", "Node: " + systemName + node + " does not exist.", -9999);
    return; 
  } 
  
  fwFMC_getInfo(node, systemName, "IPMI", ipmiInfo, exceptionInfo);
  nodeInfo[FW_FMC_DB_ENABLE_IPMI] = ipmiInfo[1];
  nodeInfo[FW_FMC_DB_IPMI_DEVICE_NAME] = ipmiInfo[2];
    
  fwFMC_getInfo(node, systemName, "MONITORING", monitoringInfo, exceptionInfo);
  nodeInfo[FW_FMC_DB_ENABLE_MONITORING] = monitoringInfo[1];
  nodeInfo[FW_FMC_DB_MONITORING_LEVEL] = monitoringInfo[2];
  
  fwFMC_getInfo(node, systemName, "TM", tmInfo, exceptionInfo);
  nodeInfo[FW_FMC_DB_ENABLE_TM] = tmInfo[1];
  
  fwFMC_getInfo(node, systemName, "LOGGER", loggerInfo, exceptionInfo);
  nodeInfo[FW_FMC_DB_ENABLE_LOGGER] = loggerInfo[1];
  
  fwFMC_getInfo(node, systemName, "PROCESS", processInfo, exceptionInfo);
  nodeInfo[FW_FMC_DB_ENABLE_PROCESS] = processInfo[1];
}

fwFMC_getInfo(string node, string systemName, string type, dyn_mixed &info, dyn_string &exceptionInfo)
{
  string ipmiName = "";
  int level = 0;
  
  type = strtoupper(type);
  
  switch(type)
  {
    case "IPMI": if(fwFMCIpmi_exists(node, systemName))
                 {
                   info[1] = 1;
                   dpGet(fwFMC_getNodeDp(node, systemName) + ".IPMIDeviceName", ipmiName);
                 }
                 else
                   info[1] = 0;
                 
                 info[2] = ipmiName;
                 break;
                 
    case "MONITORING": if(fwFMCMonitoring_exists(node, systemName))
                 {
                   info[1] = 1;
                   dpGet(fwFMC_getNodeDp(node, systemName) + "/Monitoring.level", level);
                 }
                 else
                   info[1] = 0;
                 
                 info[2] = level;
                 break;
                 
    case "LOGGER": if(fwFMCLogger_exists(node, systemName))
                 {
                   info[1] = 1;
                 }
                 else
                   info[1] = 0;
                 
                 break;
                 
    case "TM": if(fwFMCTaskManager_exists(node, systemName))
                 {
                   info[1] = 1;
                 }
                 else
                   info[1] = 0;
                 break;     
    case "PROCESS": if(fwFMCProcess_exists(node, systemName))
                 {
                   info[1] = 1;
                 }
                 else
                   info[1] = 0;
                 break;
    default: fwException_raise(exceptionInfo, "ERROR", "fwFMC_getInfo() -> Unknown information type: " + type, -9999);
      return;
  }  
}

fwFMC_getGroupPowerStatus(string group, string systemName, string &status, dyn_string &exceptionInfo)
{
  dyn_string nodeStates;
  
  dyn_string nodes;
  
  fwFMC_getGroupNodes(group, nodes, exceptionInfo);

  for(int i = 1; i <= dynlen(nodes); i++)
  {
    nodeStates[i] = fwFMC_getNodePowerStatus(nodes[i], systemName, exceptionInfo);
  }

  dynUnique(nodeStates);
  
  if(dynContains(nodeStates, FW_FMC_ERROR_POWER_STATE) > 0)  
    status = FW_FMC_ERROR_STATE;
  else if(dynContains(nodeStates, FW_FMC_ON_POWER_STATE) && dynContains(nodeStates, FW_FMC_OFF_POWER_STATE))
    status = FW_FMC_MIXED_POWER_STATE;
  else if(dynlen(nodeStates) == 1 && nodeStates[1] == FW_FMC_ON_POWER_STATE)
    status = FW_FMC_ON_POWER_STATE;
  else if(dynlen(nodeStates) == 1 && nodeStates[1] == FW_FMC_OFF_POWER_STATE)
    status = FW_FMC_OFF_POWER_STATE;
  else
    status = FW_FMC_UNKNOWN_POWER_STATE;  
}


fwFMC_setAliasRecursively(string nodeDp, string rootAlias, dyn_string &exceptionInfo)
{
  dyn_string dps;
  string node = fwFMC_getNodeName(nodeDp);
  int err = 0;
  string alias = "";
  
//  string systemName = "";
//  if(patternMatch(":", nodeDp))
//  {
//    dyn_string str = strsplit(nodeDp, ":");
//    systemName = str[1] + ":";
//  }
  
  
  //Do it now for all children
  if(fwFMCIpmi_exists(node))
  {
    if(rootAlias == "")
      alias = "";
    else
      alias = rootAlias + "/" + "Ipmi"; 
    
    dpSetAlias(nodeDp + "/Ipmi.", alias);  
      
    dps = dpNames(nodeDp + "/Ipmi/*");
    for(int i =1 ; i <= dynlen(dps); i++)
    {
      dyn_string ds = strsplit(dps[i], "/");
      
      if(rootAlias == "")
        alias = "";
      else
        alias = rootAlias + "/" + "Ipmi/" + ds[dynlen(ds)]; 
      err += dpSetAlias(dps[i] + ".", alias);
    }
  }
  
  if(fwFMCMonitoring_exists(node))
  {
    if(rootAlias == "")
      alias = "";
    else
      alias = rootAlias + "/" + "Monitoring"; 

    dpSetAlias(nodeDp + "/Monitoring.", alias);    
    //CPUs
    if(dpExists(nodeDp + "/Monitoring/Cpus"))
    {
      if(rootAlias == "")
        alias = "";
      else
        alias = rootAlias + "/" + "Monitoring/Cpus"; 
      
      dpSetAlias(nodeDp + "/Monitoring/Cpus.", alias);    
      dps = dpNames(nodeDp + "/Monitoring/Cpus/*");
      for(int i =1 ; i <= dynlen(dps); i++)
      {
        dyn_string ds = strsplit(dps[i], "/");
      
        if(rootAlias == "")
          alias = "";
        else
          alias = rootAlias + "/" + "Monitoring/Cpus/" + ds[dynlen(ds)]; 
      
        err += dpSetAlias(dps[i] + ".", alias);
      }
    }
    //Memory
    if(dpExists(nodeDp + "/Monitoring/Memory"))
    {
      if(rootAlias == "")
        alias = "";
      else
        alias = rootAlias + "/" + "Monitoring/Memory"; 
      
      dpSetAlias(nodeDp + "/Monitoring/Memory.", alias);    
    }
    //Network
    if(dpExists(nodeDp + "/Monitoring/Network"))
    {
      if(rootAlias == "")
        alias = "";
      else
        alias = rootAlias + "/" + "Monitoring/Network"; 
      
      dpSetAlias(nodeDp + "/Monitoring/Network.", alias);    
      dps = dpNames(nodeDp + "/Monitoring/Network/*");
      
      for(int i =1 ; i <= dynlen(dps); i++)
      {
        dyn_string ds = strsplit(dps[i], "/");
        if(rootAlias == "")
          alias = "";
        else
          alias = rootAlias + "/" + "Monitoring/Network/" + ds[dynlen(ds)]; 
        
        err += dpSetAlias(dps[i] + ".", alias);
      }
    }
      
    //File system
    if(dpExists(nodeDp + "/Monitoring/FS"))
    {
      if(rootAlias == "")
        alias = "";
      else
        alias = rootAlias + "/" + "Monitoring/FS"; 
      
      dpSetAlias(nodeDp + "/Monitoring/FS.", alias);    
      dps = dpNames(nodeDp + "/Monitoring/FS/*");
      for(int i =1 ; i <= dynlen(dps); i++)
      {
        dyn_string ds = strsplit(dps[i], "/");
        
        if(rootAlias == "")
          alias = "";
        else
          alias = rootAlias + "/" + "Monitoring/FS/" + ds[dynlen(ds)]; 
        
        err += dpSetAlias(dps[i] + ".", alias);
      }
    }
  }
  
  if(rootAlias == "")
    alias = "";
  else
    alias = rootAlias + "/" + "TaskManager"; 
  
  if(fwFMCTaskManager_exists(node))
    err += dpSetAlias(nodeDp + "/TaskManager.", alias);    
  
  if(rootAlias == "")
    alias = "";
  else
    alias = rootAlias + "/" + "Logger"; 
  
  if(fwFMCLogger_exists(node))
    err += dpSetAlias(nodeDp + "/Logger.", alias);    
  
  if(err)
    fwException_raise(exceptionInfo, "ERROR", "Could build subhierarchy completely for node: " + node, -9999);
 
}

//This function is to be called from a postInstallation script
fwFMC_createLogicalVendorNode(dyn_string &exceptionInfo)
{
  fwNode_createLogical(FW_FMC_LOGICAL_VENDOR, 
                       "", 
                       makeDynString(FW_FMC_SYSTEM_LOGICAL_EDITOR_PNL), 
                       makeDynString(FW_FMC_SYSTEM_LOGICAL_NAVIGATOR_PNL),
                       exceptionInfo);
  
}

fwFMC_getGroups(dyn_string &groups, dyn_string &exceptionInfo)
{  
  fwDevice_getChildren(FW_FMC_LOGICAL_VENDOR, fwDevice_LOGICAL, groups, exceptionInfo);
  for(int i =1; i <= dynlen(groups); i++)
    fwDevice_getName(groups[i], groups[i], exceptionInfo);
}

fwFMC_getGroupNodes(string group, dyn_string &nodes, dyn_string &exceptionInfo, string systemName = "")
{ 
  if(systemName == "")
    systemName = getSystemName();
  
  if(!patternMatch(systemName + FW_FMC_LOGICAL_VENDOR + fwDevice_HIERARCHY_SEPARATOR + "*", group))
    group = systemName + FW_FMC_LOGICAL_VENDOR + fwDevice_HIERARCHY_SEPARATOR + group;
   
  fwDevice_getChildren(group, fwDevice_LOGICAL, nodes, exceptionInfo);
  
  dynClear(exceptionInfo);
  
  for(int i =1; i <= dynlen(nodes); i++)
    fwDevice_getName(nodes[i], nodes[i], exceptionInfo);
  
}

fwFMC_createGroup(string group, dyn_string &exceptionInfo)
{  

  fwNode_createLogical(group, FW_FMC_LOGICAL_VENDOR, makeDynString(FW_FMC_GROUP_EDITOR_PNL), makeDynString(FW_FMC_GROUP_NAVIGATOR_PNL), exceptionInfo);
}

fwFMC_removeGroup(string group, dyn_string &exceptionInfo)
{
  dyn_string device;
  
  device[fwDevice_DP_ALIAS] = FW_FMC_LOGICAL_VENDOR + fwDevice_HIERARCHY_SEPARATOR +  group;
  fwDevice_removeAliasRecursively(device, exceptionInfo); 
}


fwFMC_addGroupNode(string group, string node, dyn_string &exceptionInfo)
{
  string nodeDp = fwFMC_getNodeDp(node);  
  dyn_string dps;
  int err = 0;
  
  //DebugN(nodeDp + ".", FW_FMC_LOGICAL_VENDOR + fwDevice_HIERARCHY_SEPARATOR + group + fwDevice_HIERARCHY_SEPARATOR + node);  

  if(dpSetAlias(nodeDp + ".", FW_FMC_LOGICAL_VENDOR + fwDevice_HIERARCHY_SEPARATOR + group + fwDevice_HIERARCHY_SEPARATOR + node) != 0)
    fwException_raise(exceptionInfo, "ERROR", "Could not add node " + node + " to group: " + group, -9999);
  
  //set aliases to all children:
  fwFMC_setAliasRecursively(nodeDp, FW_FMC_LOGICAL_VENDOR + fwDevice_HIERARCHY_SEPARATOR + group + fwDevice_HIERARCHY_SEPARATOR + node, exceptionInfo);
   
}

fwFMC_removeGroupNode(string group, string node, dyn_string &exceptionInfo)
{
  dyn_string dps;
  int err = 0;
  string nodeDp = fwFMC_getNodeDp(node);  

  //DebugN(nodeDp + ".");  
  if(dpSetAlias(nodeDp + ".", "") != 0)
    fwException_raise(exceptionInfo, "ERROR", "Could not remove node " + node + " from group: " + group, -9999);
  //Do it now for all children
  fwFMC_setAliasRecursively(nodeDp, "", exceptionInfo);

}



int fwFMC_removeNodes(dyn_string nodes) // this function only works in local system.
{
  int err = 0;
  string configName;
  dyn_dyn_string all_items;
  dyn_string dp_names;
  string nodeDp;
  dyn_string ex;

  for(int i =1; i <= dynlen(nodes); i++)
  {
    nodeDp = fwFMC_getNodeDp(nodes[i]);
    //Unsubscribe DIM services:
    if(fwFMCIpmi_exists(nodes[i]))
      fwFMCIpmi_remove(nodes[i]);
    
    if(fwFMCMonitoring_exists(nodes[i]))
      fwFMCMonitoring_remove(nodes[i]);
    
    if(fwFMCProcess_exists(nodes[i]))
      fwFMCProcess_remove(nodes[i]);
    
    if(fwFMCLogger_exists(nodes[i]))
      fwFMCLogger_remove(nodes[i]);
    
    if(fwFMCTaskManager_exists(nodes[i]))
      fwFMCTaskManager_remove(nodes[i]);
    
    if(fwFMCProcess_exists(nodes[i]))
      fwFMCProcess_remove(nodes[i]);
    
    if(dpExists(nodeDp))
      err += dpDelete(nodeDp);

	if(isFunctionDefined("fwSysOverview_getHostDp"))
	{
		string sysOverviewNodeDp;
		fwSysOverview_getHostDp(nodes[i], sysOverviewNodeDp);
    
		if(dpExists(sysOverviewNodeDp))
		fwSysOverview_deleteHost(nodes[i], ex);    
    }
	
    fwFMC_msg("Node " + nodes[i] + " has been removed.", 2);
  }
  
  if(dynlen(ex))
    DebugN(ex);
  
  if(err || dynlen(ex))
    return -1;
  
  return 0;
}

string fwFMC_getNodePowerStatus(string node, string systemName = "")
{
  int status = -1;
  string str = FW_FMC_UNKNOWN_POWER_STATE;

  string dp = fwFMC_getNodeDp(node, systemName) + ".readings.power_status";
  dyn_int manNums;
  
  if(systemName == "")
    systemName = getSystemName();

  if(dpExists(dp))
    dpGet(dp, status);

  if(status == -1)
    str = FW_FMC_UNKNOWN_POWER_STATE;
  else if(status == 0)
    str = FW_FMC_OFF_POWER_STATE;
  else if(status == 1)
    str = FW_FMC_ON_POWER_STATE;
  else
    str = FW_FMC_ERROR_POWER_STATE;

  return str;
  
  
/*
  dpGet(systemName + "_Connections.Device.ManNums", manNums);
    
  //IPMI:
  if(dynContains(manNums, FW_FMC_IPMI_DIM) > 0) //dim api is running. check now that we talk to all remote servers.
  {
    if(dpExists(fwFMCIpmi_getDp(node, systemName)))
    {
      //Check that the connection status is ok:
      dpGet(fwFMCIpmi_getMasterNodeDp(node, systemName) + ".server_info.success", status);

      if(status == 1)      
      {
        dpGet(fwFMCIpmi_getDp(node, systemName) + ".readings.power_status", status);
        //DebugN("fwFMCIpmi_getDp(node, systemName).readings.power_status, status is ", fwFMCIpmi_getDp(node, systemName) + ".readings.power_status", status);
        if(status == 1)
          return FW_FMC_ON_POWER_STATE;
        else if(status == 0)
          return FW_FMC_OFF_POWER_STATE;
        //else continue checking
      }
    }
  }
  
  //Monitoring:
  if(dynContains(manNums, FW_FMC_CONTINUOUS_MONITORING_DIM) > 0 && 
     dynContains(manNums, FW_FMC_TEMPORARY_MONITORING_DIM) > 0) //dim api is running. check now that we talk to all remote servers.
  {
    if(dpExists(fwFMCMonitoring_getDp(node, systemName)))
    {
      //Check that the connection status is ok:
      dp = fwFMCMonitoring_getDp(node, systemName) + ".OS.server_info.success";
      if(dpExists(dp))
      {
        dpGet(dp, status);
        if(status == 1)
          return FW_FMC_ON_POWER_STATE;
      }
    
      dp = fwFMCMonitoring_getDp(node, systemName) + "/Cpus.server_info.cpustat.success";
      if(dpExists(dp))
      {
        dpGet(dp, status);
        if(status == 1)
          return FW_FMC_ON_POWER_STATE;
      }
    
      dp = fwFMCMonitoring_getDp(node, systemName) + "/Cpus.server_info.cpuinfo.success";
      if(dpExists(dp))
      {
        dpGet(dp, status);
        if(status == 1)
          return FW_FMC_ON_POWER_STATE;
      }
    
      dp = fwFMCMonitoring_getDp(node, systemName) + "/Memory.server_info.success";
      if(dpExists(dp))
      {
        dpGet(dp, status);
        if(status == 1)
          return FW_FMC_ON_POWER_STATE;
      }
    
      dp = fwFMCMonitoring_getDp(node, systemName) + "/Network.server_info.success";
      if(dpExists(dp))
      {
        dpGet(dp, status);
        if(status == 1)
          return FW_FMC_ON_POWER_STATE;
      }
    
      dp = fwFMCMonitoring_getDp(node, systemName) + "/FS.server_info.success";
      if(dpExists(dp))
      {
        dpGet(dp, status);
        if(status == 1)
          return FW_FMC_ON_POWER_STATE;
      }
    }
  }
  
  if(dynContains(manNums, FW_FMC_TM_LOGGER_DIM) > 0)
  {
    dp = fwFMCTaskManager_getDp(node, systemName) + ".server_info.success";
    if(dpExists(dp))
    {
      dpGet(dp, status);
      if(status == 1)
        return FW_FMC_ON_POWER_STATE;
    }
   
    dp = fwFMCLogger_getDp(node, systemName) + ".server_info.success";
    if(dpExists(dp))
    {
      dpGet(dp, status);
      if(status == 1)
        return FW_FMC_ON_POWER_STATE;
    }
  }
  
  if(dynContains(manNums, FW_FMC_PROCESS_DIM) > 0) //dim api is running. check now that we talk to all remote servers.
  {
    dp = fwFMCProcess_getDp(node, systemName) + ".success";
    if(dpExists(dp))
    {
      dpGet(dp , status);
      //DebugN("process status is ", status);
      if(status == 1)
        return FW_FMC_ON_POWER_STATE;
    }
  }
  
  return status;  
  */
}

void fwFMC_dimManagersCB(string connectionsDpe, dyn_int manNums, string fmcParameterizationDP, bool fmcState)
{
  int m = 0;
  int val = 0;
  dyn_string dpes;
  dyn_int states;
  
//  fwFMC_getNodes(nodes, getSystemName());
  
  dyn_string localDpes = dpNames(getSystemName() + "FMC/*.agentCommunicationStatus.process", "FwFMCNode");
  m = dynlen(localDpes);
  
  if(!fmcState)
  {
    for(int i = 1; i <= m; i++)
    {
      dynAppend(states, 0);
    }
  }
  else
  {
    for(int i = 1; i <= m; i++)
    {
      string node = dpSubStr(localDpes[i], DPSUB_DP);
      if(fwFMCProcess_exists(fwFMC_getNodeName(node)))
      {
        if(dynContains(manNums, FW_FMC_PROCESS_DIM) > 0)
        {
          dynAppend(states, 1);
        }
        else
        {
          dynAppend(states, -2);
        }
      }
      else
      {
        dynAppend(states, 0); //functionality not enabled for this node.
      }
    }
  }
  dynAppend(dpes, localDpes);
  
  
  //IPMI
  localDpes = dpNames(getSystemName() + "FMC/*.agentCommunicationStatus.ipmi", "FwFMCNode");
  m = dynlen(localDpes);
  
  if(!fmcState)
  {
    for(int i = 1; i <= m; i++)
    {
      dynAppend(states, 0);
    }
  }
  else
  {
    for(int i = 1; i <= m; i++)
    {
      string node = dpSubStr(localDpes[i], DPSUB_DP);
      if(fwFMCIpmi_exists(fwFMC_getNodeName(node)))
      {
        if(dynContains(manNums, FW_FMC_IPMI_DIM) > 0)
        {
          dynAppend(states, 1);
        }
        else
        {
          dynAppend(states, -2);
        }
      }
      else
      {
        dynAppend(states, 0); //functionality not enabled for this node.
      }
    }
  }  
  dynAppend(dpes, localDpes);
  
  //TM and Logger:
  localDpes = dpNames(getSystemName() + "FMC/*.agentCommunicationStatus.taskManager", "FwFMCNode");
  dynAppend(localDpes, dpNames(getSystemName() + "FMC/*.agentCommunicationStatus.logger", "FwFMCNode"));
  m = dynlen(localDpes);
  
  if(!fmcState)
  {
    for(int i = 1; i <= m; i++)
    {
      dynAppend(states, 0);
    }
  }
  else
  {
    for(int i = 1; i <= m; i++)
    {
      string node = dpSubStr(localDpes[i], DPSUB_DP);
      if(fwFMCLogger_exists(fwFMC_getNodeName(node)))
      {
        if(dynContains(manNums, FW_FMC_TM_LOGGER_DIM) > 0)
        {
          dynAppend(states, 1);
        }
        else
        {
          dynAppend(states, -2);
        }
      }
      else
      {
        dynAppend(states, 0); //functionality not enabled for this node.
      }
    }
  }  
  dynAppend(dpes, localDpes);
  
  //Continuous Monitoring:
  localDpes = dpNames(getSystemName() + "FMC/*.agentCommunicationStatus.monitoring.memory", "FwFMCNode");
  dynAppend(localDpes, dpNames(getSystemName() + "FMC/*.agentCommunicationStatus.monitoring.cpuinfo", "FwFMCNode"));
  dynAppend(localDpes, dpNames(getSystemName() + "FMC/*.agentCommunicationStatus.monitoring.cpustat", "FwFMCNode"));
  m = dynlen(localDpes);
  

  if(!fmcState)
  {
    for(int i = 1; i <= m; i++)
    {
      dynAppend(states, 0);
    }
  }
  else
  {
    for(int i = 1; i <= m; i++)
    {
      string node = dpSubStr(localDpes[i], DPSUB_DP);
      if(fwFMCMonitoring_exists(fwFMC_getNodeName(node)))
      {
        if(dynContains(manNums, FW_FMC_CONTINUOUS_MONITORING_DIM) > 0)
        {
          dynAppend(states, 1);
        }
        else
        {
          dynAppend(states, -2);
        }
      }
      else
      {
        dynAppend(states, 0); //functionality not enabled for this node.
      }
    }
  }  dynAppend(dpes, localDpes);

  //Temporary Monitoring:
  localDpes = dpNames(getSystemName() + "FMC/*.agentCommunicationStatus.monitoring.os", "FwFMCNode");
  dynAppend(localDpes, dpNames(getSystemName() + "FMC/*.agentCommunicationStatus.monitoring.network", "FwFMCNode"));
  dynAppend(localDpes, dpNames(getSystemName() + "FMC/*.agentCommunicationStatus.monitoring.fs", "FwFMCNode"));
  m = dynlen(localDpes);
  
  if(!fmcState)
  {
    for(int i = 1; i <= m; i++)
    {
      dynAppend(states, 0);
    }
  }
  else
  {
    for(int i = 1; i <= m; i++)
    {
      string node = dpSubStr(localDpes[i], DPSUB_DP);
      if(fwFMCMonitoring_exists(fwFMC_getNodeName(node)))
      {
        if(dynContains(manNums, FW_FMC_TEMPORARY_MONITORING_DIM) > 0)
        {
          dynAppend(states, 1);
        }
        else
        {
          dynAppend(states, -2);
        }
      }
      else
      {
        dynAppend(states, 0); //functionality not enabled for this node.
      }
    }
  }
  dynAppend(dpes, localDpes);
  
  
  if(dynlen(dpes))
  { 
    dpSet(dpes, states);
  } 
  return;  
}

string fwFMC_getNodeReadoutStatus(string node, string systemName = "")
{
  int status;
  
  if(systemName == "")
    systemName = getSystemName();
  
  dpGet(fwFMC_getNodeDp(node, systemName) + ".agentCommunicationStatus.summary", status);
  
  if(status == -1)
    return "ERROR";
  
  return "OK";

/*  
//  dyn_string dps = fwFMCProcess_getServerDps();
  dyn_int manNums;
  dpGet(systemName + "_Connections.Device.ManNums", manNums);

  string dp = fwFMC_getNodeDp(node, systemName);
  //Processes  
  if(fwFMCProcess_exists(node, systemName))
  {
    if(dynContains(manNums, FW_FMC_PROCESS_DIM) < 0) //dim api is not running
    {
      return "ERROR";
    }
    dpGet(dp +  ".agentCommunicationStatus.process", status);
    if(status <= 0)
      return "ERROR";  
  }
  
  //IPMI:
  if(dpExists(fwFMCIpmi_getDp(node, systemName)))
  {
    //Check that the connection status is ok:
    dpGet(dp +  ".agentCommunicationStatus.ipmi", status); //if 1 => comm. w/ server OK.

    if(status != 1)      
      return "ERROR";
    
    //Check now that the IPMI communication with this particular node is OK;
    dpGet(fwFMCIpmi_getDp(node, systemName) + ".readings.power_status", status); //if 1 => comm. w/ server OK.
    if(status != 1 && status != 0)      
      return "ERROR";
    
  }
  
  //Monitoring:
  if(dpExists(fwFMCMonitoring_getDp(node, systemName)))
  {
    //Check that the connection status is ok:
    dpGet(dp + ".agentCommunicationStatus.monitoring.os", status);
    if(status != 1)      
      return "ERROR";
    
    dpGet(dp + ".agentCommunicationStatus.monitoring.cpuinfo", status);
    if(status != 1)      
      return "ERROR";
  
    
    dpGet(dp + ".agentCommunicationStatus.monitoring.cpustat", status);
    if(status != 1)      
      return "ERROR";
    
    dpGet(dp + ".agentCommunicationStatus.monitoring.memory", status);
    if(status != 1)      
      return "ERROR";
    
    dpGet(dp + ".agentCommunicationStatus.monitoring.network", status);
    if(status != 1)      
      return "ERROR";
    
    dpGet(dp + ".agentCommunicationStatus.monitoring.fs", status);
    if(status != 1)      
      return "ERROR";
  }
  
  if(dpExists(fwFMCTaskManager_getDp(node, systemName)))
  {
    dpGet(dp + ".agentCommunicationStatus.taskManager", status);
    if(status != 1)      
      return "ERROR";
  }
    
  if(dpExists(fwFMCLogger_getDp(node, systemName)))
  {
    dpGet(dp + ".agentCommunicationStatus.logger", status);
    if(status != 1)      
      return "ERROR";
  }
  return "OK";
*/
}

//**************
//* createNode *
//**************
int fwFMC_createNodeDPT(){

	dyn_dyn_string nameNode;
	dyn_dyn_int typeNode;

	int iNode=1;	

	nameNode[iNode] = makeDynString (FW_FMC_NODE_DPT);
	typeNode[iNode++] = makeDynInt (DPEL_STRUCT);

	nameNode[iNode] = makeDynString ("","configName");
	typeNode[iNode++] = makeDynInt (0, DPEL_STRING);

	nameNode[iNode] = makeDynString ("","physicalNodeName");
	typeNode[iNode++] = makeDynInt (0, DPEL_STRING);

	nameNode[iNode] = makeDynString ("","IPMIDeviceName");
	typeNode[iNode++] = makeDynInt (0, DPEL_STRING);

	nameNode[iNode] = makeDynString ("","subscribedConfigServices");
	typeNode[iNode++] = makeDynInt (0, DPEL_BOOL);

	nameNode[iNode] = makeDynString ("","lastUpdate");
	typeNode[iNode++] = makeDynInt (0, DPEL_TIME);

	return dpTypeChange(nameNode,typeNode);
}

void fwFMC_msg(string text, int num = 0)
{
  DebugN(text, num);
}

int fwFMC_getHostGroups(string node, dyn_string &groups)
{
  string nodeDp = fwFMC_getNodeDp(node);
  
  if(!dpExists(nodeDp + ".groups"))
    return -1;
  
  return dpGet(nodeDp + ".groups", groups);
}

int fwFMC_getHostProperties(string node, dyn_mixed &hostInfo)
{
  string description, location, ipmiName, ipmiMaster, winProcsController;
  
  dynClear(hostInfo);
  
  string nodeDp = fwFMC_getNodeDp(node);
  
  if(!dpExists(nodeDp + ".location"))
    return -1;

  
  dpGet(nodeDp + ".location", location,
        nodeDp + ".description", description,
        nodeDp + ".IPMIDeviceName", ipmiName,
        nodeDp + ".IPMIMaster", ipmiMaster,
        nodeDp + ".winProcsController", winProcsController);  
  
  hostInfo[FW_INSTALLATION_DB_HOST_BMC_IP_IDX] = "N/A";
  hostInfo[FW_INSTALLATION_DB_HOST_BMC_USER_IDX] = "N/A";
  hostInfo[FW_INSTALLATION_DB_HOST_BMC_PWD_IDX] = "N/A";
  hostInfo[FW_INSTALLATION_DB_HOST_FMC_IPMI_DEVICE_NAME_IDX] = ipmiName;
  hostInfo[FW_INSTALLATION_DB_HOST_FMC_ENABLE_IPMI_IDX] = fwFMCIpmi_exists(node);
  hostInfo[FW_INSTALLATION_DB_HOST_FMC_ENABLE_MONITORING_IDX] = fwFMCMonitoring_exists(node);
  hostInfo[FW_INSTALLATION_DB_HOST_FMC_MONITORING_LEVEL_IDX] = 1;
  hostInfo[FW_INSTALLATION_DB_HOST_FMC_ENABLE_TM_IDX] = fwFMCTaskManager_exists(node);
  hostInfo[FW_INSTALLATION_DB_HOST_FMC_ENABLE_LOGGER_IDX] = fwFMCLogger_exists(node);
  hostInfo[FW_INSTALLATION_DB_HOST_FMC_ENABLE_PROCESS_IDX] = fwFMCProcess_exists(node);
  hostInfo[FW_INSTALLATION_DB_HOST_FMC_LOCATION_IDX] = location;
  hostInfo[FW_INSTALLATION_DB_HOST_DESCRIPTION_IDX] = description;
  hostInfo[FW_INSTALLATION_DB_HOST_FMC_IPMI_MASTER_IDX] = ipmiMaster;
  hostInfo[FW_INSTALLATION_DB_HOST_FMC_WIN_PROCS_CONTROLLER_IDX] = winProcsController;
  hostInfo[FW_INSTALLATION_DB_HOST_FMC_ARCHIVING_IDX] = fwFMC_isArchivingEnabled(node);  
  hostInfo[FW_INSTALLATION_DB_HOST_FMC_ALARMS_IDX] = fwFMC_areAlarmsEnabled(node);  
  
  if(winProcsController != "")
    hostInfo[FW_INSTALLATION_DB_HOST_FMC_OS_IDX] = "WINDOWS";
  else
    hostInfo[FW_INSTALLATION_DB_HOST_FMC_OS_IDX] = "LINUX";
  
  return 0;
}

int fwFMC_getNodes(dyn_string &nodes, string systemName = "")
{
  if(systemName == "")
    systemName = getSystemName();

  
  nodes = dpNames(systemName + "FMC/*", FW_FMC_NODE_DPT);
  
  for(int i = 1; i <= dynlen(nodes); i++)
  {
    strreplace(nodes[i], systemName, "");
    strreplace(nodes[i], "FMC/", "");
  }
  
  return 0;
}


int fwFMC_createNode(string node, 
                     string physicalNodeName,
                     bool addIpmi = false, 
                     string ipmiDeviceName = "",
                     string ipmiMasterNode = "",
                     bool addMonitoring = false, 
                     int monitoringLevel = 0,
                     bool addTm = false, 
                     bool addLogger = false,
                     bool addProcess = false,
                     string winProcsController = "",
                     string location = "",
                     string description = "",
                     dyn_string groups = makeDynString(),
                     string archiving = "NONE",
                     bool alarms = false)
{
  dyn_string exception;
  int err = 0;
  string nodeDp = fwFMC_getNodeDp(node);
  
  DebugN("INFO: Setting up node: " + node);
  strreplace(nodeDp, getSystemName(), "");

  if(!dpExists(nodeDp))  
    err += dpCreate(nodeDp, "FwFMCNode");
  {
    if(err < 0)
      return -1;
  }
      
  fwFMC_initializeAgentCommunicationStatusDpes(nodeDp);
  dpSet(nodeDp + ".physicalNodeName", physicalNodeName,
        nodeDp + ".description", description,
        nodeDp + ".location", location,
        nodeDp + ".IPMIMaster", ipmiMasterNode,
        nodeDp + ".IPMIDeviceName", ipmiDeviceName,
        nodeDp + ".groups", groups,
        nodeDp + ".winProcsController", winProcsController);
  
  dyn_string exception;
  fwFMC_connectPowerStatusDpe(node, exception);
  if(dynlen(exception))
  {
    DebugN(exception);
    ++err;
  }  
  
  fwFMC_connectReadoutStatusDpe(node, exception);
  if(dynlen(exception))
  {
    DebugN(exception);
    ++err;
  }  

    if(addIpmi)
    {

      //DebugN("****fwFMC_createNode()-> adding IPMI for: ", node, ipmiDeviceName, ipmiMasterNode);
      
      if(fwFMCIpmi_add(node, ipmiDeviceName, ipmiMasterNode))
      {
        ++err;
        DebugN("ERROR: Could not configure IPMI for node: " + node); 
      }
    }
     
    if(addMonitoring)
      if(fwFMCMonitoring_add(node, monitoringLevel))
      {
        ++err;
        DebugN("ERROR: Could not configure Monitoring for node: " +  node); 
      }
        
    if(addProcess)
    {
      if(winProcsController != "")
      {
        fwFMCProcess_createServer(winProcsController);
      }
        
      if(fwFMCProcess_add(node))
      {
        ++err;
        DebugN("ERROR: Could not configure Process Monitoring for node: " + node); 
      }
    }
    
    if(addTm)
      if(fwFMCTaskManager_add(node))
      {
        ++err;
        DebugN("ERROR: Could not configure Task Manager for node: " + node); 
      } 
         
    if(addLogger)
      if(fwFMCLogger_add(node))
      {
        ++err;
        DebugN("ERROR: Could not configure Logger for node: " + node); 
      }    

    if(archiving == "NONE" && fwFMC_archivingExists(node, exception))
    {
      fwFMC_setDefaultArchive(node, exception, false);          
    }
    else
    {
      bool archive = false;
      bool advanced = false;
      
      if(archiving == "Standard")
      {
        archive = true;
      }
      else if (archiving == "Advanced")
      {
        archive = true;
        advanced = true;
      }
      
      //Debug(archiving, node, exception, archive, advanced);
      fwFMC_setDefaultArchive(node, exception, archive, advanced);    
    }
    
    if(!alarms) //if alarms to be deactivated do it only if the alarms exist
    {
      if(fwFMC_alarmsExist(node, exception))
        fwFMC_setDefaultAlarms(node, exception, alarms);    
    }
    else //create/enable alarms
      fwFMC_setDefaultAlarms(node, exception, alarms);    
    
	if(isFunctionDefined("fwSysOverview_createHost"))
	{
		dyn_mixed projectInfo; //legacy. Not very happy about this.
		projectInfo[fwSysOverview_PROJECT_HOST_IDX] = node;
		fwSysOverview_createHost(projectInfo, exception);
    }
	
	if(dynlen(exception))
		DebugN(exception);
  
  if(err || dynlen(exception))
    return -1;
  else
    return 0;
}

void  fwFMC_initializeAgentCommunicationStatusDpes(string nodeDp)
{
  if(dpExists(nodeDp))
  {
    dpSet(nodeDp + ".agentCommunicationStatus.monitoring.memory", 0,
          nodeDp + ".agentCommunicationStatus.monitoring.cpuinfo", 0,
          nodeDp + ".agentCommunicationStatus.monitoring.cpustat", 0,
          nodeDp + ".agentCommunicationStatus.monitoring.network", 0,
          nodeDp + ".agentCommunicationStatus.monitoring.fs", 0,
          nodeDp + ".agentCommunicationStatus.monitoring.os", 0,
          nodeDp + ".agentCommunicationStatus.process", 0,
          nodeDp + ".agentCommunicationStatus.taskManager", 0,
          nodeDp + ".agentCommunicationStatus.logger", 0,
          nodeDp + ".agentCommunicationStatus.ipmi", 0,
          nodeDp + ".agentCommunicationStatus.pmon", 0);
  }
}

string fwFMC_getNodeDp(string node, string systemName = "")
{
  if(systemName == "")
    systemName = getSystemName();
  
  return systemName + "FMC/" + node;
}

string fwFMC_getDeviceName(string dpName)
{
   dyn_string ds = strsplit(dpName, "/");
   
   return ds[dynlen(ds)];
}


string fwFMC_getNodeName(string dp)
{
  string type = dpTypeName(dp);
  dyn_string ds = strsplit(dp, "/");
  int i = 1;
  
  if(type == FW_FMC_NODE_DPT || type == FW_SYSTEM_OVERVIEW_NODE_DPT)
    i = dynlen(ds);
  else if(type == FW_FMC_IPMI_DPT  || type == FW_FMC_MONITORING_DPT  || type == FW_FMC_TASK_MANAGER_DPT  || type == FW_FMC_LOGGER_DPT || type == FW_FMC_PROCESS_DPT) 
    i = dynlen(ds) - 1;
  else if(type == FW_FMC_MONITORING_CPU_BASE || type == FW_FMC_MONITORING_NETWORK_BASE || type == FW_FMC_MONITORING_FS_BASE || type == FW_FMC_MONITORING_MEMORY)
    i = dynlen(ds) - 2;
  else if (type == FW_FMC_MONITORING_FS || type == FW_FMC_MONITORING_CPU || type == FW_FMC_MONITORING_NETWORK ||type ==FW_FMC_MONITORED_PROCESS_DPT || type == FW_FMC_MONITORED_SERVICE_DPT)
    i = dynlen(ds) - 3;
  return ds[i];  
}

///Node physical name:
string fwFMC_getNodePhysicalName(string node, string systemName = "")
{
  if(systemName == "")
    systemName = getSystemName();
  
  string name;
  
  dpGet(fwFMC_getNodeDp(node, systemName) + ".physicalNodeName", name);
  
  return name;
}

