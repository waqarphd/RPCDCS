/**@file

This library contains functions associated with the JCOP Framework System Overview tool. The 
functions read the system configuration data from the DB and build a hierarchy of systems, PCs and . 
The Projects are polled simultaneously via the PMON port at regular intervals to get the list of managers and 
their states and triggers alerts as required.fwSysOverview_startMonitoring

@par Creation Date
	26/06/2007

@par Modification History
	
@par Constraints

@author 
	Francisca Calheiros, Fernando Varela, Pawel Macuda
        EN-ICE-SCD (former IT-CO-BE)
*/

#uses "fwConfigurationDBSystemInformation/fwConfigurationDBSystemInformation.ctl"
#uses "fwConfigs/fwAlertConfig.ctl"
#uses "fwDIM"
#uses "fwFMC/fwFMC.ctl"
#uses "fwSystemOverview/fwSystemOverviewAC.ctl"

const string FW_SYSTEM_OVERVIEW_TOOL_VERSION = "4.3.0";

//fwSystemOverview return OK
const int fwSysOverview_OK = 0;

//fwSystemOverview return ERROR
const int fwSysOverview_ERROR = -1;

//fwSystemOverview maximum number of tcp open connections
const int fwSysOverview_TCP_LIMIT = 16;

// Project State Constants
const int fwSysOverview_STOPPED_NORMAL    = 0;
const int fwSysOverview_INITIALIZE        = 1;
const int fwSysOverview_RUNNING           = 2;
const int fwSysOverview_BLOCKED           = 3;
const int fwSysOverview_MONITORING_STOPPED = 4; // project, for which THIS status will be set, will have their managers' statuses set to  0 - STOPPED
const int fwSysOverview_STOPPED_ABNORMAL  = 10;
const int fwSysOverview_RAPID_RESTART     = 11;
const int fwSysOverview_PROJNAME_MISMATCH = 12;
const int fwSysOverview_PMON_NO_RESPONSE  = 13;
//const int fwSysOverview_PMON_NOT_RUNNING  = 14;

//Datapoint Elements for fwSystemOverview\PC
const string fwSysOverview_PC_HOST_NAME = ".config.host";
const string fwSysOverview_PC_FMC_DP = ".config.fmcDp";


//Datapoint Elements for fwSystemOverview\PC\Project
const string fwSysOverview_PROJECT_PMON_NUMBER = ".config.pmon.portNumber";
const string fwSysOverview_PROJECT_USER_NAME = ".config.pmon.userName";
const string fwSysOverview_PROJECT_USER_PASS = ".config.pmon.userPass";
const string fwSysOverview_PROJECT_SYSTEM = ".config.system";
const string fwSysOverview_PROJECT_NAME = ".config.project";
const string fwSysOverview_PROJECT_POLL = ".config.pollProject";
const string fwSysOverview_PROJECT_IS_POLLING = ".readings.isPolling";
const string fwSysOverview_PROJECT_CURRENT_PROJECT_NAME = ".readings.project";
const string fwSysOverview_PROJECT_DISABLE_MONITORING = ".readings.disableMonitoring";
const string fwSystemOverview_TOTAL_MANAGERS_NUMBER = ".statistics.totalManagers";
const string fwSystemOverview_NUMBER_MANAGERS_BLOCKED = ".statistics.blockedManagers";
const string fwSystemOverview_NUMBER_MANAGERS_ERROR = ".statistics.errManagers";

//Datapoint Elements for fwSystemOverview\System
const string fwSysOverview_SYSTEM_NAME = ".config.system";
const string fwSysOverview_SYSTEM_NUMBER = ".config.sysNumber";
const string fwSysOverview_SYSTEM_PARENT_ID = ".config.sysParentId";
const string fwSysOverview_SYSTEM_PREFIX = "SYSTEM/";

//Datapoint Elements for fwSystemOverview\Project\Managers
const string fwSysOverview_MANAGER_TYPE = ".config.type";
const string fwSysOverview_MANAGER_OPTIONS = ".config.options";
const string fwSysOverview_MANAGER_RESETMIN = ".config.resetMin";
const string fwSysOverview_MANAGER_RESTART = ".config.restart";
const string fwSysOverview_MANAGER_SECKILL = ".config.secKill";
const string fwSysOverview_MANAGER_CONFIG_STARTMODE_VALUE = ".config.startMode";
const string fwSysOverview_MANAGER_READINGS_STARTMODE_VALUE = ".readings.startMode.value";
const string fwSysOverview_MANAGER_READINGS_STARTMODE_ALARM = ".readings.startMode.alarm";
const string fwSysOverview_MANAGER_NUM = ".config.num";
const string fwSysOverview_MANAGER_STARTIME = ".readings.startTime";
const string fwSysOverview_MANAGER_UPDATED = ".readings.lastUpdated";
const string fwSysOverview_MANAGER_STATE = ".readings.state";
const string fwSysOverview_MANAGER_PID = ".readings.pid";
const string fwSysOverview_MANAGER_INDEX = ".readings.index";
const string fwSysOverview_MANAGER_PROJECT = ".config.project";
const string fwSysOverview_MANAGER_HOST = ".config.host"; 
const string fwSysOverview_MANAGER_PREFIX = "/Manager";
const string fwSysOverview_MANAGER_NOT_USED = ".config.notUsed";

const int fwSysOverview_DEFAULT_VALUE_CONFIG_STARTMODE = 9999;

//Datapoint Elements for fwSystemOverview configuration
const string fwSysOverview_STATE = ".readings.state";
const string fwSysOverview_SYSTEM_DP = "SystemOverview/";
const string fwSysOverview_PARAMETRIZATION = "fwSysOverviewParametrization";    
const string fwSysOverview_REFRESH_RATE = ".refreshRate";
const string fwSysOverview_DB_UPDATE = ".dbLastUpdate";
const string fwSysOverview_FORCE_DB_UPDATE = ".forceDBUpdate";
const string fwSysOverview_ACCESS_CONTROL = ".accessControl";
const string fwSysOverview_USE_APP_ACCESS_CONTROL = ".useAppBasedAC";
const string fwSysOverview_ENABLE_MONITORING = ".enableMonitoring";
const string fwSysOverview_ACCESS_DOMAIN = ".ACdomain";
const string fwSysOverview_FMC_SYSTEM = ".fmcSystem";
const string fwSysOverview_ARCHIVE_CLASS = ".archiveClass";
const string fwSysOverview_ENABLE_ARCHIVING = ".enableArchiving";
const string fwSysOverview_ENABLE_DIM_PUBLISHING = ".enableDimPublishing";
const string fwSysOverview_EXPERT_PRIVILEGE = ".expertPrivilege";

global string fwSysOverview_DIM_CONFIG = "fwDimSystemOverview";
const string fwSysOverview_DIM_PREFIX = "FWSO/";

global unsigned fwSysOverview_gRefreshInterval;

//list of the threads ids that trigger the PMON polling for all the projects 
global dyn_int fwSysOverview_gThreadsIds;

//list of the projects for which pmon didn't respond the previous iteration
global dyn_string fwSysOverview_gPmonErrProjects;

//System description when passed as a dyn_mixed:
const int fwSysOverview_MANAGER_TYPE_IDX = 1;
const int fwSysOverview_MANAGER_INDEX_IDX = 2;
const int fwSysOverview_MANAGER_OPTIONS_IDX = 3;
const int fwSysOverview_MANAGER_PID_IDX = 4;
const int fwSysOverview_MANAGER_RESETMIN_IDX = 5;
const int fwSysOverview_MANAGER_RESTART_IDX = 6;
const int fwSysOverview_MANAGER_SECKILL_IDX = 7;
const int fwSysOverview_MANAGER_CONFIG_STARTMODE_VALUE_IDX = 8;
const int fwSysOverview_MANAGER_READINGS_STARTMODE_VALUE_IDX = 8;
const int fwSysOverview_MANAGER_NUM_IDX = 9;
const int fwSysOverview_MANAGER_STATE_IDX = 10;
const int fwSysOverview_MANAGER_STARTIME_IDX = 11;
const int fwSysOverview_MANAGER_UPDATED_IDX = 12;

//Project Access data info
const int fwSysOverview_PROJECT_NAME_IDX = 1;
const int fwSysOverview_PROJECT_PMON_NUM_IDX = 2;
const int fwSysOverview_PROJECT_PMON_USER_IDX = 3;
const int fwSysOverview_PROJECT_PMON_PASS_IDX = 4;
const int fwSysOverview_PROJECT_HOST_IDX = 5;
const int fwSysOverview_PROJECT_SYSTEM_NAME_IDX =6;
const int fwSysOverview_PROJECT_SYSTEM_NUM_IDX = 7;
const int fwSysOverview_PROJECT_DISABLE_MONITORING_IDX = 8;


// Internal Variables
mixed fwSysOverview_mutex;
bool showErrorDialog = true;

const string fwSystemOverview_SMS_DPCONFIG = ".._string_04";
const string fwSystemOverview_MASKED_DPCONFIG = ".._string_03";


mapping fwSysOverview_getAlarmCategories()
{
  mapping m;
  
  m["Al Arch"] = "*_archive_Alarm_*";  
  m["WFIP"] = "*-WFIPSegment-*";  
  m["CMW Srv"] = "*_CMWServer_*";  
  m["CMW Cl"] = "*_CMWClient_*";  
  m["Dist"] = "*_unDistributedControl_*";  
//   m["Distributed Connections"] = "*_unDistributedControl_*";    
  m["FE Comm"] = "*_DS_Comm_*;*_DS_Time_*";  
//   m["Front-End Communication"] = "*_DS_Comm_*;*_DS_Time_*";    
  m["Hosts"] = "*:FMC/*;*:_ArchiveDisk.FreeKB;*:_MemoryCheck.FreeKB";  
  m["Laser"] = "*_Laser_*";  
  m["Logging"] = "*_LHCLogging_*";  
  m["PLCs"] = "*-IcemonPlc-*.ProcessInput.metric*;*_PLC_DS_Error_*;*_import_S7_PLC_*";  
  m["Projects"] = "*:SystemOverview/*;*_backup_check_*";  
  m["PVSS DB"] = "*_PVSSDB_*";  
  m["QPS PM"] = "*_PM_STATE_*";  
//   m["QPS Post Morten Link"] = "*_PM_STATE_*";    
  m["Val Arch"] = "*_ValueArchive_*";  
  
  return m;
}
/*
fwSystemOverview_setMultipleSmsTypes(dyn_string dpes, string smsType, dyn_string &exceptionInfo)
{
  int length;
  dyn_string smsTypes;
  
  length = dynlen(dpes);
  for(int i=1; i<=length; i++)
    smsTypes[i] = smsType;
  
  fwSystemOverview_setManySmsTypes(dpes, smsTypes, exceptionInfo);
}

fwSystemOverview_setManySmsTypes(dyn_string dpes, dyn_string smsTypes, dyn_string &exceptionInfo)
{
  int length;
  dyn_string attributes = makeDynString(".._type", fwSystemOverview_SMS_PATH_ATTRIBUTE);
  dyn_dyn_anytype valuesToSet;
  
  length = dynlen(dpes);
  for(int i=1; i<=length; i++)
  {
    valuesToSet[i][1] = DPCONFIG_GENERAL;
    valuesToSet[i][2] = smsTypes[i];    
  }

  _fwConfigs_setConfigAttributes(dpes, fwConfigs_PVSS_GENERAL, attributes, valuesToSet, exceptionInfo);
}
*/

void fwSysOverview_getApplicationSystems(string application, dyn_string &systems, dyn_int &ids)
{
  dyn_dyn_string dps = fwSysOverviewFsm_getChildrenOfTypeWithDomain(application, "FwSystemOverviewProject", application);   
  for(int i = 1; i <= dynlen(dps); i++)
  {
    string sysDp = "", sys = "";
    int id = -1;
    dyn_string ex;
    fwSysOverview_getProjectSystem(dps[i][1], sysDp, ex);
    fwSysOverview_getSystemDb(sysDp, sys, ex);
    if(dynlen(ex))
      DebugN(ex, dps[i][1], sysDp, sys);
    
    if(dynContains(systems, sys)> 0) //system already found. Skip!
      continue;
    
    dynAppend(systems, sys);
    dpGet(sysDp + ".config.sysNumber", id);
    dynAppend(ids, id);
  }
  return;
}


void fwSysOverview_saveProjectManagersStartMode(string projDp)
{
  dyn_string managerDps = fwSysOverview_getProjectManagerDPs(projDp);
  int n = dynlen(managerDps);

  for(int i = 1; i <= n; i++)
  {
    int startMode = fwSysOverview_DEFAULT_VALUE_CONFIG_STARTMODE;
    dpGet(managerDps[i] + fwSysOverview_MANAGER_READINGS_STARTMODE_VALUE, startMode);
    dpSet(managerDps[i] + fwSysOverview_MANAGER_CONFIG_STARTMODE_VALUE, startMode);
  }
  return;
} 

void fwSystemOverview_connectManagerStartModeDpe(string managerDp,bool handlingActive, dyn_string &exception)
{    
  fwDpFunction_setDpeConnection(managerDp + fwSysOverview_MANAGER_READINGS_STARTMODE_ALARM,
                                makeDynString(managerDp + fwSysOverview_MANAGER_CONFIG_STARTMODE_VALUE + ":_online.._value",
                                              managerDp + fwSysOverview_MANAGER_READINGS_STARTMODE_VALUE + ":_online.._value"
                                              ),
                                makeDynString(),
                                "(p1!="+fwSysOverview_DEFAULT_VALUE_CONFIG_STARTMODE+")&&(p1!=p2)?1:0",
                                exception,
                                1);
  if(dynlen(exception))
  {
    DebugN(exception);
    return;
  }

 //Set the description to the dpe:
  string description;
  dpGetDescription(managerDp, description);
  dpSetDescription(managerDp + fwSysOverview_MANAGER_READINGS_STARTMODE_ALARM, description);
  //set the alarm:
  dyn_mixed alarmObject;
  fwAlertConfig_objectCreateDigital(alarmObject,makeDynString("OK","Manager Misconfiguration"),
                                    makeDynString("","_fwWarningNack."),
                                    "", makeDynString(),
                                    "", exception, false, false, "", false);
  //set the alarm to the dpe                                        
  fwAlertConfig_objectSet(managerDp + fwSysOverview_MANAGER_READINGS_STARTMODE_ALARM, alarmObject, exception);   
  //activate it
  if(handlingActive){fwAlertConfig_activate(managerDp + fwSysOverview_MANAGER_READINGS_STARTMODE_ALARM, exception); if(dynlen(exception)){return;}}

  return;
}



void fwSysOverview_applyDefaultAlertConfig(dyn_string &ex)  
{
  string dbProjectName;
  string dbHostName;
  bool handlingActive = true;
  int manNum = 0;
  string projDp;

  dyn_string projDps = dpNames("SystemOverview/*/*", "FwSystemOverviewProject");
  int n = dynlen(projDps);
  for(int i = 1; i <= n; i++)
  {
    string hostDp = "";
    fwSysOverview_getProjectDb(projDps[i], dbProjectName, ex); if(dynlen(ex)) continue;  
    fwSysOverview_getProjectPc(projDps[i], hostDp, ex); if(dynlen(ex)) continue;  
    fwSysOverview_getHostDb(hostDp, dbHostName, ex); if(dynlen(ex)) continue;  
    fwSysOverview_setProjectAlert(dbProjectName, dbHostName, handlingActive, ex);
    dyn_string managerDps = fwSysOverview_getProjectManagerDPs(projDps[i]);
    int m = dynlen(managerDps);    
    for(int j = 1; j <= m; j++) fwSysOverview_setManagerAlert(managerDps[j], handlingActive, ex);
  }
  return;  
}

void fwSysOverview_upgrade(dyn_string &exceptionInfo)
{
  //Update System DPs if necessary:
  fwSysOverview_checkSystemDpVersion(exceptionInfo);
  //Make sure for each FMC node there is an System Overview Node and the other way around:
  dyn_string fmcNodes, systemOverviewNodeDps;
  fwSysOverview_getHosts(systemOverviewNodeDps);
  fwFMC_getNodes(fmcNodes);
  for(int i = 1; i <= dynlen(fmcNodes); i++)
  {
    //Connect the power and readout statuses
    fwFMC_connectPowerStatusDpe(fmcNodes[i], exceptionInfo);
    fwFMC_connectReadoutStatusDpe(fmcNodes[i], exceptionInfo);
    
    //check if the system overview host exists:
    string hostDpToCheck;
    fwSysOverview_getHostDp(fmcNodes[i], hostDpToCheck);
    hostDpToCheck = getSystemName() + hostDpToCheck;
    if(!dpExists(hostDpToCheck))
    {
      dyn_mixed projectInfo;
      projectInfo[fwSysOverview_PROJECT_HOST_IDX] = fmcNodes[i];
      fwSysOverview_createHost(projectInfo, exceptionInfo);
    }
    else
    {
      dynRemove(systemOverviewNodeDps, dynContains(systemOverviewNodeDps, hostDpToCheck));
    }
  }
  
  for(int i = 1; i <= dynlen(systemOverviewNodeDps); i++)
  {
    string host;
    fwSysOverview_getHostDb(systemOverviewNodeDps[i], host, exceptionInfo);  
    fwFMC_createNode(host, host);
  }
  
  //Update manager Dps:
  dyn_string managerDps = dpNames("SystemOverview/*/*/Manager*", "FwSystemOverviewManager");
  int n = dynlen(managerDps);
  for(int i = 1; i <= n; i++) fwSystemOverview_connectManagerStartModeDpe(managerDps[i], true, exceptionInfo);
  
  return;
}




fwSysOverview_getHostProjects(string host, dyn_dyn_mixed &projectsInfo)
{
  string hostDp;
  fwSysOverview_getHostDp(host, hostDp);
  dyn_string projectDps = fwSysOverview_getHostProjectDps(hostDp);
  dyn_string ex;
  for(int i = 1; i <= dynlen(projectDps); i++)
  {
    dyn_mixed data;
    dynClear(data);
    fwSysOverview_getProjAccessData(projectDps[i], data);
    string project;
    fwSysOverview_getProjectDb(projectDps[i], project, ex);
    
    if(project == "") //crap
      continue;
    
    projectsInfo[i][fwSysOverview_PROJECT_NAME_IDX] = project;
    projectsInfo[i][fwSysOverview_PROJECT_PMON_NUM_IDX] = data[fwSysOverview_PROJECT_PMON_NUM_IDX];
    projectsInfo[i][fwSysOverview_PROJECT_PMON_USER_IDX] = data[fwSysOverview_PROJECT_PMON_USER_IDX];
    projectsInfo[i][fwSysOverview_PROJECT_PMON_PASS_IDX] = data[fwSysOverview_PROJECT_PMON_PASS_IDX];
    projectsInfo[i][fwSysOverview_PROJECT_SYSTEM_NAME_IDX] = data[fwSysOverview_PROJECT_SYSTEM_NAME_IDX];
    dyn_mixed sysData;
    string sysDp;
    dyn_string ex;
    fwSysOverview_getSystemDp(data[fwSysOverview_PROJECT_SYSTEM_NAME_IDX], host, sysDp, ex);
    fwSysOverview_getSystemConfigData(sysDp, sysData);
    projectsInfo[i][fwSysOverview_PROJECT_SYSTEM_NUM_IDX] = sysData[1];
//    projectsInfo[i][fwSysOverview_PROJECT_SYSTEM_NUM_IDX] = data[fwSysOverview_PROJECT_SYSTEM_NUM_IDX];
    projectsInfo[i][fwSysOverview_PROJECT_DISABLE_MONITORING_IDX] = !data[fwSysOverview_PROJECT_DISABLE_MONITORING_IDX];
    projectsInfo[i][fwSysOverview_PROJECT_HOST_IDX] = host;    
  }
  
}

int fwSysOverview_projectCommand(string cmd, string project, string host)
{
  string projectDp;
  dyn_string ex;
  fwSysOverview_getProjectDp(host, project, projectDp, ex);
  if(dynlen(ex)) {DebugN(ex);return -1;}
  
  dyn_mixed data;
  fwSysOverview_getProjAccessData(projectDp, data);
  if(data[fwSysOverview_PROJECT_PMON_USER_IDX] == "N/A")
    data[fwSysOverview_PROJECT_PMON_USER_IDX] = "";
  
  if(data[fwSysOverview_PROJECT_PMON_PASS_IDX] == "N/A")
    data[fwSysOverview_PROJECT_PMON_PASS_IDX] = "";
  
  cmd = data[fwSysOverview_PROJECT_PMON_USER_IDX]+ "#"+ 
        data[fwSysOverview_PROJECT_PMON_PASS_IDX]+"#" +
        strtoupper(cmd) + "_ALL:";

  if(pmon_command(cmd, host, data[fwSysOverview_PROJECT_PMON_NUM_IDX], true, true))
  {
    return -1;
  }

  return 0;
}

int fwSysOverview_projectManagerCommand(string cmd, 
                                        string type = "", 
                                        string options = "", 
                                        string startMode = "always", 
                                        string host = "", 
                                        string port = 4999,
                                        string user = "", 
                                        string pwd = "")
{
  int err = 0;
  dyn_dyn_mixed managersInfo;
  fwInstallationManager_pmonGetManagers(managersInfo, host, port, user, pwd);
  
  if(dynlen(managersInfo))
    for(int i = 1; i <= dynlen(managersInfo[1]); i++)
    {
      string managerStartMode = "";
      if(managersInfo[FW_INSTALLATION_MANAGER_START_MODE][i] == "0")
        managerStartMode = "manual";
      else if(managersInfo[FW_INSTALLATION_MANAGER_START_MODE][i] == "1")
        managerStartMode = "once";
      else if(managersInfo[FW_INSTALLATION_MANAGER_START_MODE][i] == "2")
        managerStartMode = "always";
      
/*      DebugN(managersInfo[FW_INSTALLATION_MANAGER_TYPE][i],  managersInfo[FW_INSTALLATION_MANAGER_OPTIONS][i]); 
      DebugN((type == "" || type == managersInfo[FW_INSTALLATION_MANAGER_TYPE][i]) &&
         (options == "" || patternMatch("*"+options+"*", managersInfo[FW_INSTALLATION_MANAGER_OPTIONS][i])) &&
         (startMode == "" || managerStartMode == strtolower(startMode)));
*/    
      if((type == "" || type == managersInfo[FW_INSTALLATION_MANAGER_TYPE][i]) &&
         (options == "" || patternMatch("*"+options+"*", managersInfo[FW_INSTALLATION_MANAGER_OPTIONS][i])) &&
         (startMode == "" || managerStartMode == strtolower(startMode)))
      {
        DebugN("Sending: ", cmd, managersInfo[FW_INSTALLATION_MANAGER_TYPE][i], managersInfo[FW_INSTALLATION_MANAGER_OPTIONS][i], host, port, user, pwd, false);
        if(fwInstallationManager_command(cmd, managersInfo[FW_INSTALLATION_MANAGER_TYPE][i], managersInfo[FW_INSTALLATION_MANAGER_OPTIONS][i], host, port, user, pwd, false))
        {
          ++err;
          DebugN("Could not " + cmd + "the followig manager: " + managersInfo[FW_INSTALLATION_MANAGER_TYPE][i], managersInfo[FW_INSTALLATION_MANAGER_OPTIONS][i], host, port, user);
        }
      }
    }
    if(err)
    return -1;
  
  return 0;
}

string fwSysOverview_getProjectState(string projectDp)
{
  int state = -1;
  dpGet(projectDp + ".readings.state", state);
  return fwSysOverview_getStrFromState(state);
}

string fwSysOverview_getFmcSystem()
{
  string sys = "";
  dpGet(fwSysOverview_PARAMETRIZATION + fwSysOverview_FMC_SYSTEM, sys);
  
  if(sys == "")  //not defined, assume the local one.
    sys = getSystemName();
  
  if(!patternMatch("*:", sys))
    sys += ":";
 
  return sys; 
}


//read data from DB and create the fwSystemOverview data point structure
int fwSysOverview_readSystemConfigurationDB() // This function became OBSOLETE
{
  dyn_string projectNames;
  dyn_dyn_mixed systemsInfo;
  dyn_string hostnames,ips,macs,ips2, macs2,bmc_ips,bmc_ips2;
  //dyn_mixed projectProperties;
  int i, j, ierr;
  // int projectId;
  string ip, mac, ip2, mac2, bmc_ip, bmc_ip2, hostName, projectName; 
  dyn_string versions, oss;
  string sysName;
  dyn_mixed systemInfo;
  dyn_dyn_mixed projectsInfo;
  dyn_dyn_mixed hierarchyInfo;
  dyn_string hostDps, result,dpsToDelete;
  dyn_string dpList;  
  dyn_anytype values;
  dyn_dyn_mixed childSystems;
  dyn_string listOfChildren, sysProjects;
  string dpFMCname;
  bool fmc;
  string fmcSystem;
  dyn_string exceptionInfo;
  
  //init connection
   if(fwInstallationDB_connect()!= 0)
    {
     if(myManType() == UI_MAN)
       ChildPanelOnCentral("vision/MessageInfo1", "ERROR: DB Connection failed", makeDynString("$1:DB Connection failed.\nPlease check DB connection parameters"));
       else
          DebugN("ERROR: DB Connection failed. Please check DB connection parameters");
     return fwSysOverview_ERROR;
    }   

   //check if fwFMC is installed
   fmcSystem = fwSysOverview_getFmcSystem();
   fmc = dpExists(fmcSystem + "fwInstallation_fwFMC");
   
  // 1. populate pc information from DB into pvss dps

   fwInstallationDB_getHosts(hostnames, ips, macs, ips2, macs2, bmc_ips, bmc_ips2); 
   
  //list of existing pcs stored in PVSS 
   fwSysOverview_getHosts(hostDps);
  
  //Check if there are dps to delete
  result = dynIntersect(hostnames,hostDps);
  
   
   dynClear(versions);
   dynClear(oss);
   
   for(i=1;i<=dynlen(hostnames);i++)   
   { 
     // ATLAS-specific: restrict systems belonging to a subdetector
     //
     if (isFunctionDefined("fwAtlas") && strpos(getSystemName(), "ATLGCSSYS")<0) {
     string subdetId = strtoupper(fwAtlas_getSubdetectorId(getSystemName()));
     if (strpos(hostnames[i], subdetId)<0) {
        DebugTN("Ignoring machine "+hostnames[i]+" since it is not part of subdetector "+subdetId);
         continue;
     }
   }
  
    fwInstallationDB_getHostProperties(hostnames[i], ip, mac,ip2,mac2, bmc_ip, bmc_ip2);
    
    fwInstallationDB_getPvssVersions(hostnames[i], versions, oss);
    dynUnique(versions);
    dynUnique(oss);

    hostName = hostnames[i];
    
    // remove all "."s in pcName 
    strreplace(hostnames[i], ".", "_");    
    
    if(fmc)
      dpFMCname = fwSysOverview_getFMCdpName(hostnames[i]);
    else
      dpFMCname="";
    
    
    dpCreate(fwSysOverview_SYSTEM_DP + hostnames[i],"FwSystemOverviewPC");
  
    //DebugN(hostnames[i],versions,oss);    
    dpList[1] = fwSysOverview_SYSTEM_DP + hostnames[i] + fwSysOverview_PC_IP; values[1]= ip;
    dpList[2] = fwSysOverview_SYSTEM_DP + hostnames[i] + fwSysOverview_PC_PVSSVERSION; values[2]=versions;
    dpList[3] = fwSysOverview_SYSTEM_DP + hostnames[i] + fwSysOverview_PC_OPSYSTEM; values[3]=oss;    
    dpList[4] = fwSysOverview_SYSTEM_DP + hostnames[i] + fwSysOverview_PC_IPMINAME; values[4]=dpFMCname;
    dpList[5] = fwSysOverview_SYSTEM_DP + hostnames[i] + fwSysOverview_ORIGINAL_HOST_NAME; values[5]=hostName;
                
    dpSet(dpList, values); 
 
  // 2. populate projects information from DB into pvss dps 
   
    fwInstallationDB_getPvssProjects(projectNames, hostName);
 
    for(j=1;j<=dynlen(projectNames);j++)
    {
      // ATLAS-specific: restrict systems belonging to a subdetector
      // fwSysOverview_getSystemProjects()->System does not
      if (isFunctionDefined("fwAtlas") && strpos(getSystemName(), "ATLGCSSYS")<0) {
        string subdetId = strtoupper(fwAtlas_getSubdetectorId(getSystemName()));
        if (strpos(sysName, subdetId)<0) {
          DebugTN("Ignoring project "+sysName+" since it is not part of subdetector "+subdetId);
          continue;
        }
      } 
      
    bool createAlerts = TRUE;  
    fwSysOverview_createProjectDP(projectNames[j], hostName, createAlerts, exceptionInfo);
        
    } 
   }  
   
  // 3. populate system information from DB into pvss dps    
  
  fwInstallationDB_getPvssSystems(systemsInfo);
  
//DebugN("**********dynlen(systemsInfo) = " + dynlen(systemsInfo));  
 
  for(i=1;i<=dynlen(systemsInfo);i++)   
  {  
    sysName = systemsInfo[i][1];
    
    strreplace(sysName, ":", "");
    
    dynClear(projectsInfo);  
    dynClear(systemInfo);  
    dynClear(childSystems);  
    
    // projectsInfo: 1.project name | 2. pc name
    fwInstallationDB_getSystemProjects(sysName, projectsInfo);
    
//if(patternMatch("*ATLCICSCS*", sysName))
//  DebugN(">>>", sysName, projectsInfo); 
  
    if(dynlen(projectsInfo) <= 0) //DB problem. We have a system but there is no project pointing to it.
    {
       DebugN("WARNING: DB inconsistency. Found system with no project: " + sysName + ". This system will be ignored.");
       continue;
    }
       
    dynClear(sysProjects);
    
    for(j=1;j<=dynlen(projectsInfo);j++)
    {
      dynAppend(sysProjects,projectsInfo[j][FW_INSTALLATION_DB_PROJECT_HOST]+"/"+projectsInfo[j][FW_INSTALLATION_DB_PROJECT_NAME]);
     }
    
   // fwInstallationDB_getSystemHierarchy(hierarchyInfo);
    
    // systemInfo: 1.sys name | 2.sys number | 3. redu number | 4. data port | 5. event port | 6. dist port | 7. redundant sys ID | 8. parent sys ID
    fwInstallationDB_getPvssSystemProperties(sysName, systemInfo);
    
    fwConfigurationDBSystemInformation_getChildSystems(sysName, childSystems);
    
    dynClear(listOfChildren);
    
    for(j=1;j<=dynlen(childSystems);j++)
    {
     dynAppend(listOfChildren,childSystems[j][1]);
    }
    
    if(systemInfo[8]=="N/A" || systemInfo[8]=="")
       systemInfo[8]="0";
      
    string sysDp = "";
    fwSysOverview_getSystemDp(sysName, sysDp, exceptionInfo);
    if(dynlen(exceptionInfo)){//fwExceptionHandling_display(exceptionInfo); 
      continue;}
    
    dpCreate(sysDp, "FwSystemOverviewSystem");
    
    dpList[1] = sysDp + fwSysOverview_SYSTEM_NUMBER; 
    values[1]=systemInfo[FW_INSTALLATION_DB_SYSTEM_NUMBER];
    
    dpList[2] = sysDp + fwSysOverview_SYSTEM_DATA_PORT;
    values[2]=systemInfo[FW_INSTALLATION_DB_SYSTEM_DATA_PORT];
    
    dpList[3] = sysDp + fwSysOverview_SYSTEM_EV_PORT;
    values[3]=systemInfo[FW_INSTALLATION_DB_SYSTEM_EVENT_PORT];
    
    dpList[4] = sysDp + fwSysOverview_SYSTEM_DIST_PORT;
    values[4]=systemInfo[FW_INSTALLATION_DB_SYSTEM_DIST_PORT];
    
    dpList[5] = sysDp + fwSysOverview_SYSTEM_PARENT_ID;
    values[5]=systemInfo[FW_INSTALLATION_DB_SYSTEM_PARENT_SYS_ID];
    
    dpList[6] = sysDp + fwSysOverview_SYSTEM_HOSTNAME;
    values[6]=projectsInfo[1][FW_INSTALLATION_DB_PROJECT_HOST];
    
    dpList[7] = sysDp + fwSysOverview_SYSTEM_CHILDREN;
    values[7]=listOfChildren;
    
    dpList[8] = sysDp + fwSysOverview_SYSTEM_PROJECTS;
    values[8]=sysProjects;
    
    dpSet(dpList, values); 
   }
   
  if(fwSysOverview_checkDBConsistency() == false)
  {
    ChildPanelOnCentral("fwSystemOverview/fwSystemOverview_DB_Consistency.pnl", "DB Consistency", makeDynString());
  }

  return fwSysOverview_OK;
}

string fwSysOverview_getFMCdpName(string pvssHostName)
{
  string dpFMCname;
  
  dpFMCname = fwSysOverview_getFmcSystem() + "FMC/" + pvssHostName;
  
  if(!dpExists(dpFMCname))  //return empty if the dp does not exist
    dpFMCname="";
  
  return dpFMCname;
  
}
    
int fwSysOverview_getDeviceName(string dpName, string &device)
{
 dyn_string ds;

 ds = strsplit(dpName, "/");
 
 device = ds[dynlen(ds)];

 return fwSysOverview_OK; 
}

void fwSysOverview_getHosts(dyn_string &hostDps)
{
  hostDps = dpNames(getSystemName() + "*","FwSystemOverviewPC");
}

int fwSysOverview_getAllProjects(dyn_string &projDps)
{
  dyn_string dsDps;
 
  dynClear(projDps);
  
  projDps=dpNames(getSystemName() + "*","FwSystemOverviewProject");
  
  if(dynlen(projDps)<=0)
  {
    DebugN("ERROR:fwSysOverview_getAllProjects()-> No projects found."); 
    return fwSysOverview_ERROR;
    }
  
//  if(dynContains(projDps,getSystemName()+"_mp_FwSystemOverviewProject")>0)
//     dynRemove(projDps,dynContains(projDps,getSystemName()+"_mp_FwSystemOverviewProject"));

  return fwSysOverview_OK; 
}

int fwSysOverview_getSystemsDps(dyn_string &systemDpNames)
{
  systemDpNames=dpNames(getSystemName() + "*","FwSystemOverviewSystem");
    
  return fwSysOverview_OK; 
}

/** Gets Access data for polling the project

@param projDp        Project datapoint name
@param projectData   1. pmon number | 2. pmon user name | 3. pmon user password |
                     4. dirpath | 5. system name | 6. host name
*/

int fwSysOverview_getProjAccessData(string projDp, dyn_mixed &projectData)
{
  dyn_string exceptionInfo;
  string hostDpName, dbHostName;
      
  dpGet(projDp + fwSysOverview_PROJECT_PMON_NUMBER,projectData[fwSysOverview_PROJECT_PMON_NUM_IDX], 
        projDp + fwSysOverview_PROJECT_USER_NAME, projectData[fwSysOverview_PROJECT_PMON_USER_IDX], 
        projDp + fwSysOverview_PROJECT_USER_PASS, projectData[fwSysOverview_PROJECT_PMON_PASS_IDX],
//        projDp + fwSysOverview_PROJECT_DIRPATH, projectData[fwSysOverview_PROJ_DIR_IDX], 
        projDp + fwSysOverview_PROJECT_SYSTEM, projectData[fwSysOverview_PROJECT_SYSTEM_NAME_IDX],
//        projDp + fwSysOverview_PROJECT_HOSTNAME, projectData[fwSysOverview_PROJ_HOST_IDX],
        projDp + fwSysOverview_PROJECT_CURRENT_PROJECT_NAME, projectData[fwSysOverview_PROJECT_NAME_IDX]
        ,projDp + fwSysOverview_PROJECT_DISABLE_MONITORING, projectData[fwSysOverview_PROJECT_DISABLE_MONITORING_IDX]
        );
  
  fwSysOverview_getProjectPc(projDp, hostDpName, exceptionInfo);
  if(dynlen(exceptionInfo)){return;}
  fwSysOverview_getHostDb(hostDpName, dbHostName, exceptionInfo);
  if(dynlen(exceptionInfo)){return;}
  projectData[fwSysOverview_PROJECT_HOST_IDX] = dbHostName;
  
}

/** Gets PC config data

@param projDp        Project datapoint name
@param projectData   1. IP | 2. operating systems | 3. PVSS versions

*/

int fwSysOverview_getPcConfigData(string pcDp, dyn_mixed &pcData)
{
  return dpGet(pcDp + fwSysOverview_PC_IP,pcData[1], 
               pcDp + fwSysOverview_PC_OPSYSTEM, pcData[2], 
               pcDp + fwSysOverview_PC_PVSSVERSION, pcData[3]);
}

/** Gets system config data

@param projDp        System datapoint name
@param systemData   1. system number | 2. data port number | 3. event port number
                    4. dist port number | 5. parent ID | 6. pc host name

*/
int fwSysOverview_getSystemConfigData(string systemDp, dyn_mixed &systemData)
{
  return dpGet(systemDp + fwSysOverview_SYSTEM_NUMBER,systemData[1], 
               systemDp + fwSysOverview_SYSTEM_NAME, systemData[2], 
               systemDp + fwSysOverview_SYSTEM_PARENT_ID, systemData[3]);
//               systemDp + fwSysOverview_SYSTEM_EV_PORT, systemData[3],
//               systemDp + fwSysOverview_SYSTEM_DIST_PORT, systemData[4],
//               systemDp + fwSysOverview_SYSTEM_HOSTNAME, systemData[6]);
   
  
}

/** Reset the IsPolling flag DPE for all the projects in all pcs. 
This funcion is to initialise the flag to known state before starting the polling of the PMON

*/
int fwSysOverview_resetPollingFlags()
{
  dyn_string dsDps;
  int i;
  
  dsDps=dpNames(getSystemName() + "*","FwSystemOverviewProject");
  
  if(dynlen(dsDps)>0)
  
  for(i = 1; i <= dynlen(dsDps); i++)
    {
       fwSysOverview_setIsPolling(dsDps[i], FALSE);
    }
}


int fwSysOverview_getRootNodes(dyn_string &rootDPs)
{  
  dyn_string systemDpNames;
  dyn_mixed systemData;
  string parentNode;
  
  fwSysOverview_getSystemsDps(systemDpNames);

  for(int j = 1; j <= dynlen(systemDpNames); j++)
  {
//    fwSysOverview_getSystemConfigData(systemDpNames[j],systemData);
    
//    parentNode = systemData[5];

//    if(parentNode == 0)
//    { 
      dynAppend(rootDPs, fwSysOverview_removeSystemName(systemDpNames[j]));
//    }
  } 
  
  return fwSysOverview_OK;   
}

int fwSysOverview_getChildSystems(string sysDpName, dyn_string &children)
{
   return dpGet( sysDpName + fwSysOverview_SYSTEM_CHILDREN, children);  
  }

/** Get current state of the system
@param deviceDp     Device datapoint name
@param deviceState  Device current state
*/

int fwSysOverview_getDeviceState(string deviceDp, unsigned& deviceState)
{
  dpGet(deviceDp + fwSysOverview_STATE, deviceState);
  return;
}

/** Poll's the PMON port of the project and populate the corresponding manager data in the projDp datapoint.

@param projDp  The datapoint name of the project whose PMON is to be polled.
*/


string fwSysOverview_getHostDpPattern(string dbHost)
{
  string str = dbHost;
  strreplace(str, ".", "_");
  
  return str;  
}

int fwSysOverview_pollProject(string projDp)
{
  bool isPolling = false;
  dyn_mixed projectData;
  string actProjName;
  string pcDp, sysDpName, hostDpName;
  int err=0,i,k,matchCount;
  dyn_dyn_string ddsResult, ddsResultStati;
  
  dyn_bool       pat1, pat2, pat3;
  dyn_string     typeTemp, numTemp;  
  dyn_int        cStat, okStat, pid, num;
  dyn_uint       index, mode, resetMin, restart, secKill;
  dyn_time       startTime;
  dyn_string     type, opt;
  dyn_bool       lastUpdated;  
  dyn_dyn_mixed  managersInfo;
  string fmcDp;
  dyn_string exceptionInfo;
  
  strreplace(projDp, getSystemName(), "");
  
  if (projDp != "")
    fwSysOverview_getProjAccessData(projDp, projectData); 
  else
    return fwSysOverview_ERROR;

  if(projectData[fwSysOverview_PROJECT_DISABLE_MONITORING_IDX] == true) // apply for each manager, of a givenn project, satus 0 (STOPPED)
  {
    dpSet(projDp + fwSysOverview_STATE,fwSysOverview_MONITORING_STOPPED,
          projDp + fwSystemOverview_TOTAL_MANAGERS_NUMBER, 0,
          projDp + fwSystemOverview_NUMBER_MANAGERS_BLOCKED, 0,
          projDp + fwSystemOverview_NUMBER_MANAGERS_ERROR, 0
          );
    
    dyn_string ManagerDps = fwSysOverview_getProjectManagerDPs(projDp);
    
    for(int i=1; i<=dynlen(ManagerDps); i++)
    {
      if(!dpExists(ManagerDps[i]))
        continue;
      
      dpSet(ManagerDps[i] + fwSysOverview_STATE, fwSysOverview_STOPPED_NORMAL);
    }
    
    fwSysOverview_getSystemDp(projectData[fwSysOverview_PROJECT_SYSTEM_NAME_IDX], projectData[fwSysOverview_PROJECT_HOST_IDX], sysDpName, exceptionInfo);
    if(dynlen(exceptionInfo)){//fwExceptionHandling_display(exceptionInfo); 
      return -fwSysOverview_ERROR;}
    
    dpSet(sysDpName + fwSysOverview_STATE, fwSysOverview_MONITORING_STOPPED);
    
    return 0;
  }
 
  string pvssHost;
  fwSysOverview_convertDbName(projectData[fwSysOverview_PROJECT_HOST_IDX], "host", pvssHost , exceptionInfo);
  
  //fill the fmc dp as it may have been created since last update:
  fmcDp = fwSysOverview_getFMCdpName(pvssHost);

  fwSysOverview_getHostDp(projectData[fwSysOverview_PROJECT_HOST_IDX], hostDpName);
  if (hostDpName == "")
    return;
  
  dpSet(hostDpName + fwSysOverview_PC_FMC_DP, fmcDp);
   
  string cmd;
  string user= "", pwd = "";
  
  if(projectData[fwSysOverview_PROJECT_PMON_USER_IDX] != "N/A")
    user = projectData[fwSysOverview_PROJECT_PMON_USER_IDX];
  
  if(projectData[fwSysOverview_PROJECT_PMON_PASS_IDX] != "N/A")
    pwd = projectData[fwSysOverview_PROJECT_PMON_PASS_IDX];
    
  cmd= user+"#"+pwd+"#PROJECT:";
  
  err = pmon_query(cmd, projectData[fwSysOverview_PROJECT_HOST_IDX] ,projectData[fwSysOverview_PROJECT_PMON_NUM_IDX], ddsResult, false, true);
  int idx = dynContains(fwSysOverview_gPmonErrProjects, projDp);
  if(err)  //pmon not responding
  {
      // if this is at least the second time pmon doesn't respond
      if (idx>0)
      {
        fwSysOverview_setProjectStatePmonNotResponse(projDp);
      }
      else
      {
        dynAppend(fwSysOverview_gPmonErrProjects, projDp);
      }
      return fwSysOverview_ERROR;
  }
  else if (idx > 0)
    dynRemove(fwSysOverview_gPmonErrProjects, idx);
  
  if(strlen(ddsResult[1][1]) <= 0)
  {
    fwSysOverview_setProjectStatePmonNotResponse(projDp);
    return -1;
  }        

  actProjName = ddsResult[1][1];

  string project = "";
  dyn_string exceptionInfo;
    
  fwSysOverview_getProjectDb(projDp, project, exceptionInfo);
  if(dynlen(exceptionInfo)){//fwExceptionHandling_display(exceptionInfo); 
    return fwSysOverview_ERROR;}   
    
  if(project != actProjName)
  {
    fwSysOverview_getSystemDp(projectData[fwSysOverview_PROJECT_SYSTEM_NAME_IDX], projectData[fwSysOverview_PROJECT_HOST_IDX], sysDpName, exceptionInfo);
       
    if(dynlen(exceptionInfo)){//fwExceptionHandling_display(exceptionInfo); 
      return fwSysOverview_ERROR;} 
       
    dpSet(projDp + fwSysOverview_STATE,fwSysOverview_PROJNAME_MISMATCH,
          sysDpName + fwSysOverview_STATE, fwSysOverview_PROJNAME_MISMATCH,
          projDp + fwSysOverview_PROJECT_CURRENT_PROJECT_NAME, actProjName);
       
    fwSysOverview_deleteManagers(projDp, exceptionInfo);
    if(dynlen(exceptionInfo)){return ;} 
    dpSet(projDp + fwSystemOverview_TOTAL_MANAGERS_NUMBER, 0,
          projDp + fwSystemOverview_NUMBER_MANAGERS_BLOCKED, 0,
          projDp + fwSystemOverview_NUMBER_MANAGERS_ERROR, 0
          );
    return fwSysOverview_ERROR;
  } 
     
  dynClear(ddsResultStati);
  dynClear(ddsResult);
  
  err = pmon_query(projectData[fwSysOverview_PROJECT_PMON_USER_IDX]+"#"+projectData[fwSysOverview_PROJECT_PMON_PASS_IDX]+"#MGRLIST:LIST", projectData[fwSysOverview_PROJECT_HOST_IDX] , projectData[fwSysOverview_PROJECT_PMON_NUM_IDX], ddsResult, false, true);
     
  if(!err)
    err = pmon_query(projectData[fwSysOverview_PROJECT_PMON_USER_IDX]+"#"+projectData[fwSysOverview_PROJECT_PMON_PASS_IDX]+"#MGRLIST:STATI", projectData[fwSysOverview_PROJECT_HOST_IDX] , projectData[fwSysOverview_PROJECT_PMON_NUM_IDX], ddsResultStati, false, true);
     
  fwSysOverview_setIsPolling(projDp, FALSE);
      
  if(err)
  {
//    fwSysOverview_setProjectStatePmonNotResponse(projDp);
    return fwSysOverview_ERROR;
  }
  
  if(dynlen(ddsResultStati) <= 0)
  {
    fwSysOverview_setProjectStatePmonNotResponse(projDp);
    return fwSysOverview_OK;
  }
    
  fwSysOverview_setManagersData(projDp, actProjName, projectData[fwSysOverview_PROJECT_SYSTEM_NAME_IDX], ddsResult,ddsResultStati); 
  fwSysOverview_setIsPolling(projDp, FALSE);
  
  return 0;
}

/** Check if there is already a callback waiting to receive data from PMON for
project indicated by the projDp datapoint. Checks IsPolling DPE.

@param projDp  Name of the project datapoint for which the check is made.
@param isPolling  The flag indicates whether a previous callback is waiting on PMON port query.
*/
int fwSysOverview_getIsPolling(string projDp, bool& isPolling)
{
  return dpGet(projDp + fwSysOverview_PROJECT_IS_POLLING, isPolling);
}

/** Sets the IsPolling flag to indicate that a function is busy on polling the PMON port
    for the project indicated by projDp

@param projDp  The name of the datapoint for which the polling flag is to be changed
@param isPolling  The input value for the polling flag
*/

int fwSysOverview_setIsPolling(string projDp, bool isPolling)
{
  return dpSet(projDp + fwSysOverview_PROJECT_IS_POLLING, isPolling);
}

/** Connects to the trigger datapoint which is used for invoking polling of PMON port of the projects
    and registers a work function 'fwSysOverview_wfPollProject' to handle the actual polling.
*/

/*
int fwSysOverview_connectPollProjectDpe()
{
  dyn_string projDps;
  int i;
  
  fwSysOverview_getAllProjects(projDps);
  
  for(i = 1; i <= dynlen(projDps); i++){
      dpConnect("fwSysOverview_pollProject", FALSE, projDps[i] + fwSysOverview_PROJECT_POLL);
    }
  
  return fwSysOverview_OK;
}
*/

/** Disconnects the trigger datapoint and deregisters the work function 'fwSysOverview_wfPollProject'
*/
/*
int fwSysOverview_disconnectPollProjectDpe()
{
  dyn_string projDps;
  int i;
  
  fwSysOverview_getAllProjects(projDps);
   
  for(i = 1; i <= dynlen(projDps); i++){
     if(dpDisconnect("fwSysOverview_pollProject", projDps[i] + fwSysOverview_PROJECT_POLL)<0){
       DebugN("ERROR:fwSysOverview_disconnectPollProjectDpe()");
       return fwSysOverview_ERROR;
      }
    }
  
  return fwSysOverview_OK;   
}
*/
void fwSysOverview_initializeThreadHeartbits()
{
  dyn_string heartbitDps = dpNames("*", "_FwSystemOverviewThreadHeartbit");
  for(int i = 1; i <= dynlen(heartbitDps); i++)
    dpSet(heartbitDps[i] + ".used", 0);
}  

void fwSysOverview_startThreadMonitor()
{
  int used = 0;
  time ts, t;
  while(1)
  {
    //has the monitoring been stopped?
    int enabled = 0;
    dpGet(fwSysOverview_PARAMETRIZATION + fwSysOverview_ENABLE_MONITORING, enabled);
//DebugN("Is monitoring enabled? " + enabled);    
    if(enabled == 2)
    {
      delay(fwSysOverview_gRefreshInterval);
      continue;
    }
//DebugN("after continue, enabled =  " + enabled);    
    
    t = getCurrentTime();
    dyn_string heartbitDps = dpNames("*", "_FwSystemOverviewThreadHeartbit");
    for(int i = 1; i <= dynlen(heartbitDps); i++)
    {
      dpGet(heartbitDps[i] + ".used", used,
            heartbitDps[i] + ".aliveness:_online.._stime", ts
            );
      int delta = t-ts;
      if(used && (delta > 4*fwSysOverview_gRefreshInterval))
      {
DebugN("crash thread "+i, delta, ts);        
        DebugN("System Overview ERROR: Monitoring thread " + i + " has died. Trying to restart the Ctrl Manager now");
        dpSet("_Managers.Exit", myManId());
      }
    }
    delay(fwSysOverview_gRefreshInterval);
  }
}  



/** Triggers PMON polling for all the projects in all the systems configured for 
    fwSystemOverview tool and updates the state of the system based on the states 
    of the projects in the system.
*/
  
void fwSysOverview_pollProjects(dyn_string projGroup,int groupN)
{
  dyn_string dpeList;
  dyn_bool valueList;
  time t0,t1;
  int i,totalElapsed;

  fwSystemOverview_startThreadHeartbit(groupN);
  while(true)
  {
    fwSystemOverview_updateThreadHeartbit(groupN);
    for(i = 1; i <= dynlen(projGroup); i++){
       fwSysOverview_pollProject(projGroup[i]);
       delay(2);
    } 
    delay(fwSysOverview_gRefreshInterval);
  }
}

void fwSystemOverview_updateThreadHeartbit(int n)
{
  int alive = 0;
  dpGet("fwSystemOverview_thread" + n + ".aliveness", alive);
  if(alive == 0)
    alive = 1;
  else
    alive = 0;
  dpSet("fwSystemOverview_thread" + n + ".aliveness", alive);
}

void fwSystemOverview_startThreadHeartbit(int n)
{
  dpSet("fwSystemOverview_thread" + n + ".used", 1,
        "fwSystemOverview_thread" + n + ".aliveness", 1);
}

string fwSysOverview_calculateManagerDescription(string systemName, string project, string manType, string options)
{
     string description = systemName + ":" + project + ":" + manType;
     if(options != "") description = description +" "+ options;
     // ATLAS specific description  convention
     if (isFunctionDefined("fwAtlas")) {
       description = fwAtlas_getSubdetectorId(systemName)+" PvssSystem "+systemName + " " + manType + ( (options=="") ? "" : (" "+options) );
     }
     return description;
}


int fwSysOverview_setProjectStatePmonNotResponse(string projDp)
{
  dyn_string exceptionInfo;
  dyn_bool lastUpdate = false;
  dyn_int manState;
  dyn_string ManagerUpdateDpes, ManagerStateDpes;
  dyn_string ManagerDps = dpNames(getSystemName() + projDp +"/*","FwSystemOverviewManager");
  for(int i = 1; i <= dynlen(ManagerDps); i++) 
  {
    ManagerUpdateDpes[i] = ManagerDps[i] + fwSysOverview_MANAGER_UPDATED; 
    lastUpdate[i] = FALSE; 
    ManagerStateDpes[i] = ManagerDps[i] + fwSysOverview_STATE; 
    manState[i] = fwSysOverview_STOPPED_NORMAL;
  } 

  //set system state:
  string sysDpName = "";
  fwSysOverview_getProjectSystem(projDp, sysDpName, exceptionInfo);
  if(dynlen(exceptionInfo)){DebugN(exceptionInfo); return fwSysOverview_ERROR;} 

  dpSet(projDp + fwSysOverview_STATE, fwSysOverview_PMON_NO_RESPONSE,
        sysDpName + fwSysOverview_STATE, fwSysOverview_PMON_NO_RESPONSE);

  if(dynlen(ManagerDps) <= 0)
    return 0;

  dpSetWait(ManagerUpdateDpes, lastUpdate);
  dpSetWait(ManagerStateDpes, manState);
  
  return dpSetWait(projDp + fwSystemOverview_TOTAL_MANAGERS_NUMBER, dynlen(ManagerDps),
                   projDp + fwSystemOverview_NUMBER_MANAGERS_BLOCKED, 0,
                   projDp + fwSystemOverview_NUMBER_MANAGERS_ERROR, 0);
}

string fwSysOverview_findFreeProjectManagerDp(string projDp, dyn_string managerConfig)
{
  dyn_string managerDps = fwSysOverview_getUnusedProjectManagerDps(projDp);
  int value = 0;
  if(dynlen(managerDps) > 0)
  {
    dpSetWait(managerDps[1] + fwSysOverview_MANAGER_CONFIG_STARTMODE_VALUE, fwSysOverview_DEFAULT_VALUE_CONFIG_STARTMODE); //Initialize config value of the config start mode 
    return managerDps[1]; //One of the old dps can be recycled!
  }
  //We have iterated over all dps and we have no one without being in use. Create a new one:
  int i = 1;
  while(1)
  {
    string dp = projDp + "/Manager" + i;
    if(!dpExists(dp))
    {
      bool createAlerts = true;
      dyn_string exceptionInfo;
      fwSysOverview_createManagerDp(i, projDp, createAlerts, exceptionInfo);
      return dp;
    }
    ++i;
  }
}

fwSysOverview_getPVSSProjectManagerDPs(string projDp, dyn_dyn_mixed &pvssManagersInfo)
{
  dyn_string managerDps = fwSysOverview_getProjectManagerDPs(projDp);    
  int n = dynlen(managerDps);
  if(n <= 0) {return;}
  
  dyn_dyn_string dpes;
  dyn_int nums = 0;
  dyn_string options, types;
  dyn_int indexes;
  for(int i = 1; i <= n; i++)
  {
    dpes[1][i] = managerDps[i] + ".config.num";
    dpes[2][i] = managerDps[i] + ".config.type";
    dpes[3][i] = managerDps[i] + ".config.options";
    dpes[4][i] = managerDps[i] + ".readings.index";
  }
  
  dpGet(dpes[1], nums);
  dpGet(dpes[2], types);
  dpGet(dpes[3], options);
  dpGet(dpes[4], indexes);  

  pvssManagersInfo[1] = nums;
  pvssManagersInfo[2] = types;
  pvssManagersInfo[3] = options;
  pvssManagersInfo[4] = indexes;  
  pvssManagersInfo[5] = managerDps;

  return;  
}

int fwSysOverview_managerExists(string projDp, 
                                string managerType, 
                                int managerNum, 
                                string managerOptions,  
                                int managerIndex,
                                string &managerDp)
{
  string dpe = "";
  dyn_dyn_mixed pvssManagersInfo; 
  fwSysOverview_getPVSSProjectManagerDPs(projDp, pvssManagersInfo);
  
  if(dynlen(pvssManagersInfo) <= 0)
    return false;
  
  int n = dynlen(pvssManagersInfo[1]);
  for(int i = 1; i <= n; i++)
  {
     if(isFunctionDefined("fwAtlas")) {dpe = pvssManagersInfo[5][i] + fwSysOverview_STATE;}
     else dpe = pvssManagersInfo[5][i] + ".";
     
    //Check if the manager type and the number+index or options match
    if(managerType == pvssManagersInfo[2][i] &&
       ((managerType == "PVSS00pmon"   ||
        managerType == "PVSS00data"   ||
        managerType == "PVSS00event"  ||
        managerType == "PVSS00dist"   ||
        managerType == "PVSS00rdb"     ) ||
       (managerOptions == "" && managerNum == pvssManagersInfo[1][i] && managerIndex == pvssManagersInfo[4][i]) || //same type, same number, same position in the console
       (managerOptions != "" && patternMatch("*-num " + managerNum + " *", pvssManagersInfo[3][i])) || 
       pvssManagersInfo[3][i] != "" && managerOptions == pvssManagersInfo[3][i]))
    {
      managerDp = pvssManagersInfo[5][i];
      return true;
    }
  }

  managerDp = "";
  return false;
}

int fwSysOverview_updateManagersData(string hostName, string projDp, dyn_dyn_string managerConfig, dyn_dyn_string managerState, string actProjName, string systemName)
{
  int error = 0;
  int k = 1;
  dyn_dyn_string remainingConfigs, remainingStates;
  dyn_string currentManagerState;
  string managerDp;
  //Update first all managers whose datapoints can be found, i.e. fixed either by num or by options
  int n = dynlen(managerConfig);
  for(int i = 1; i <= n; i++)
  {
    int manNum = managerState[i][5];
    string manType = managerConfig[i][1];
    string manOptions = "";
    if(dynlen(managerConfig[i]) > 5)
      manOptions = managerConfig[i][6];
  
    //Set the proper description to the manager dp:
    if(fwSysOverview_managerExists(projDp, manType, manNum, manOptions, (i-1), managerDp))
    {
      string description = fwSysOverview_calculateManagerDescription(systemName, actProjName, manType, manOptions);    
      currentManagerState = managerState[i];
      dynAppend(currentManagerState, (i-1));
      if(fwSysOverview_writeManagerData(managerDp, managerConfig[i], currentManagerState, actProjName, description, hostName)) ++error;
    }
    else
    {
      remainingConfigs[k] = managerConfig[i];
      currentManagerState = managerState[i];
      dynAppend(currentManagerState, (i-1));
      remainingStates[k] = currentManagerState;
      ++k;
    }
  }
  n = dynlen(remainingConfigs);
  //Update now the manager whose dp could not be resolved:
  for(int i = 1; i <= n; i++)
  {
    int manNum = remainingConfigs[i][5];
    
    string manType = remainingConfigs[i][1];
    string manOptions = "";
    if(dynlen(remainingConfigs[i]) > 5)
      manOptions = remainingConfigs[i][6];
      managerDp = fwSysOverview_findFreeProjectManagerDp(projDp, remainingConfigs[i]);
      string description = "";
//       string dpe = "";
//   
//       if(isFunctionDefined("fwAtlas")) {dpe = managerDp + fwSysOverview_STATE;}
//       else dpe = managerDp;
  
      string description = fwSysOverview_calculateManagerDescription(systemName, actProjName, manType, manOptions);    
      if(fwSysOverview_writeManagerData(managerDp, remainingConfigs[i], remainingStates[i], actProjName, description, hostName, true)) ++error;
      
  }
  
  if(error)
    return -1;
  
  return 0;
}  

string fwSysOverview_getManagerDescription(string managerDp, string& managerDescriptionDp)
{
  if(isFunctionDefined("fwAtlas")) 
  {
    managerDescriptionDp = managerDp + fwSysOverview_STATE;
  }
  else 
  {
    managerDescriptionDp = managerDp + ".";
  }
  return dpGetDescription(managerDescriptionDp);
}

int fwSysOverview_writeManagerData(string managerDp, dyn_string managerConfig, dyn_string managerState, string actProjName, string description, string hostName, bool updataStartModeConfig = false)
{
  dyn_string dpNameList;
  dyn_mixed value;
  
  
  //set manager description:
  string dpe;
  string currentDescription = fwSysOverview_getManagerDescription(managerDp, dpe);
  if(currentDescription != description)//set the description only if it is different
  {  
    dpSetDescription(dpe, description);
  }
  
  int k=1;
  strreplace(managerConfig[1], "&", "&&");
  dpNameList[k] = managerDp + fwSysOverview_MANAGER_NUM; value[k] = managerState[5]; k++;   
  dpNameList[k] = managerDp + fwSysOverview_MANAGER_TYPE; value[k] = managerConfig[1]; k++; 
  dpNameList[k] = managerDp + fwSysOverview_MANAGER_READINGS_STARTMODE_VALUE; value[k] = managerState[3]; k++; 
  dpNameList[k] = managerDp + fwSysOverview_MANAGER_OPTIONS; value[k] =(dynlen(managerConfig) > 5)?managerConfig[6]:""; k++; 
  dpNameList[k] = managerDp + fwSysOverview_MANAGER_PID; value[k] = managerState[2]; k++; 
  dpNameList[k] = managerDp + fwSysOverview_MANAGER_RESETMIN; value[k] = managerConfig[4]; k++; 
  dpNameList[k] = managerDp + fwSysOverview_MANAGER_RESTART; value[k] = managerConfig[5]; k++; 
  dpNameList[k] = managerDp + fwSysOverview_MANAGER_SECKILL; value[k] = managerConfig[3]; k++; 
  dpNameList[k] = managerDp + fwSysOverview_MANAGER_STARTIME; value[k] = managerState[4]; k++; 
  dpNameList[k] = managerDp + fwSysOverview_MANAGER_HOST; value[k] = hostName; k++; 
  dpNameList[k] = managerDp + fwSysOverview_MANAGER_PROJECT; value[k] = actProjName; k++; 
  dpNameList[k] = managerDp + fwSysOverview_STATE; value[k] = managerState[1]; k++; 
  dpNameList[k] = managerDp + fwSysOverview_MANAGER_UPDATED; value[k] = TRUE; k++;  
  dpNameList[k] = managerDp + fwSysOverview_MANAGER_NOT_USED; value[k] = 0; k++;  
  if (dynlen(managerState) > 5) 
  {
    int last = dynlen(managerState);
    dpNameList[k] = managerDp + fwSysOverview_MANAGER_INDEX; value[k] = managerState[last]; k++; 
  }

  int configStartMode = fwSysOverview_DEFAULT_VALUE_CONFIG_STARTMODE;
  dpGet(managerDp + fwSysOverview_MANAGER_CONFIG_STARTMODE_VALUE, configStartMode);
  if(configStartMode == fwSysOverview_DEFAULT_VALUE_CONFIG_STARTMODE || 
     (updataStartModeConfig && managerState[3] != configStartMode))
    dpSet(managerDp + fwSysOverview_MANAGER_CONFIG_STARTMODE_VALUE, managerState[3]); //Initialize config value of the config start mode 
  
  return dpSetWait(dpNameList, value);
}

int fwSysOverview_initializeProjectManagers(string projectDp)
{
  dyn_string managerDpes = dpNames(projectDp + "/Manager*" + fwSysOverview_MANAGER_NOT_USED, "FwSystemOverviewManager");
  dyn_int values;
  int n = dynlen(managerDpes);
  for(int i = 1; i <= n; i++)
    values[i] = 1;
  
  return dpSet(managerDpes, values);
}

dyn_string fwSysOverview_getUnusedProjectManagerDps(string projDp)
{
  dyn_string notUsedManagers;
  dyn_string managerDps = dpNames(projDp + "/Manager*", "FwSystemOverviewManager");
  int n = dynlen(managerDps);
  for(int i = 1; i <= n; i++)
  {
    int value = 0;
    dpGet(managerDps[i]+ fwSysOverview_MANAGER_NOT_USED, value);
    if(value == 1) {dynAppend(notUsedManagers, managerDps[i]);}
  }
  return notUsedManagers;    
}
int fwSysOverview_deleteUnusedManagerDps(string projDp)
{
  dyn_string managerDps = fwSysOverview_getUnusedProjectManagerDps(projDp);
  int n = dynlen(managerDps);
  for(int i = 1; i <= n; i++)
  {
    dpDelete(managerDps[i]);
//    DebugN("Deleting manager dp: " + managerDps[i]);  
  }
}


int fwSysOverview_setManagersData(string projDp, 
                                 string actProjName, 
                                 string systemName, 
                                 dyn_dyn_string ddsResult,
                                 dyn_dyn_string ddsResultStati)
{
  int projCStat,sysCStat;
  string sysDpName, hostName;
  string hostDp;
  int ierr;
  int numBlocked = 0;
  int numTotal = 0; 
  int numAbStopped = 0;
  
  dyn_string dpNameList,projNames,ManagerDps;
  dyn_anytype value, lastUpdate;
  dyn_uint states;
  bool createAlerts = TRUE;
  dyn_string projectName;
  dyn_string exceptionInfo;

//calculate project state and create the managers DPs if they don't exist
  dynClear(states);
  
  fwSysOverview_getProjectPc(projDp, hostDp, exceptionInfo);
  if(dynlen(exceptionInfo)){return fwSysOverview_ERROR;} 
  
  fwSysOverview_getHostDb(hostDp, hostName, exceptionInfo);
  if(dynlen(exceptionInfo)){return fwSysOverview_ERROR;} 
  
  strreplace(systemName, ":", "");
  fwSysOverview_getSystemDp(systemName, hostName, sysDpName, exceptionInfo);
  if(dynlen(exceptionInfo)){return fwSysOverview_ERROR;} 

  //if pmon does not respond, no data available, set managers update flag to FALSE
  if(dynlen(ddsResult) <= 0 || dynlen(ddsResultStati) <= 0)  
    fwSysOverview_setProjectStatePmonNotResponse(projDp);
  
  //We have a pmon response.
  //Initialize manager data:
  fwSysOverview_initializeProjectManagers(projDp); 
  //First analysis of the results. 
  //1.- Calculate summary state for project and 
  //2.- check if there is any manager state value that has to be corrected, 
  //    e.g. manager stopped, start mode always, set abnormally stopped state  
  projCStat = 0;        //we assume that the project has been stopped normally
  dyn_int states;
  bool isProjectRunning = false;
  for(int i = 2; i <= dynlen(ddsResult); i++) 
    if(ddsResultStati[i][1] == "2"){isProjectRunning = true; break;}
  
  for(int i = 1; i <= dynlen(ddsResult); i++)
  {
    if(isProjectRunning && ddsResultStati[i][3] == "2" && ddsResultStati[i][1] == "0") //start mode is automatic but the manager is not running: signal a problem
    {        
      ddsResultStati[i][1] = fwSysOverview_STOPPED_ABNORMAL;
      ++numAbStopped;
    }
    else if (isProjectRunning && ddsResultStati[i][1] == "3")
      ++numBlocked;
    // check whether the alarm for this manager is blocked
    if (!fwSysOverview_managerStateAlarmMasked(projDp, ddsResult[i], (i-1)))
      states[i] = ddsResultStati[i][1];
    else
      states[i] = fwSysOverview_RUNNING;
  }
  
  fwSysOverview_updateManagersData(hostName, projDp, ddsResult, ddsResultStati, actProjName, systemName);
  
  numTotal = dynlen(ddsResult);
  
  //Check if it is an scattered system:
  if(isProjectRunning) {projCStat = dynMax(states);}//the project is running. let us recalculate its state according to the states of its managers
  else                 {projCStat = 0;}
 
  fwSysOverview_getSystemProjects(sysDpName, projNames, exceptionInfo);
  if(dynlen(exceptionInfo)) {return fwSysOverview_ERROR;} 
  
  if(dynlen(projNames) == 1) sysCStat = projCStat;
  else // scattered system
  {
    fwSysOverview_getDeviceState(sysDpName, sysCStat);
    if(projCStat > sysCStat)
      sysCStat = projCStat;
  }
  
  // update project and system states    
  fwSysOverview_updateProjectState(projDp, projCStat);
  fwSysOverview_updateSystemState(sysDpName, sysCStat);
  //Update project counters:
  dpNameList[1] = projDp + fwSysOverview_PROJECT_CURRENT_PROJECT_NAME; 
  value[1] = actProjName;
  dpNameList[2] = projDp + fwSystemOverview_TOTAL_MANAGERS_NUMBER; 
  value[2] = numTotal;
  dpNameList[3] = projDp + fwSystemOverview_NUMBER_MANAGERS_BLOCKED; 
  value[3] = numBlocked;
  dpNameList[4] = projDp + fwSystemOverview_NUMBER_MANAGERS_ERROR; 
  value[4] = numAbStopped;
  dpSet(dpNameList, value);
  
  //Remove all unnecessary manager dps
  fwSysOverview_deleteUnusedManagerDps(projDp);

  return 0;  
}

bool fwSysOverview_managerStateAlarmMasked(string projDp, dyn_string managerConfig, int manIndex)
{
  bool masked = false;
  int manNum = managerConfig[5];
  string manType = managerConfig[1];
  string manOptions = "";
  if(dynlen(managerConfig) > 5)
    manOptions = managerConfig[6];

  string managerDp; 
  if(fwSysOverview_managerExists(projDp, manType, manNum, manOptions, manIndex, managerDp))
  {
    string alarmDp = managerDp + fwSysOverview_MANAGER_STATE + ":_alert_hdl.._active";
    bool active;
    if (dpExists(alarmDp))
    {
      dpGet(alarmDp, active);
      masked = !active;
    }
  }
  
  return masked;
}

void fwSysOverview_updateProjectState(string projDp, int projCStat)
{
  dpSet(projDp + fwSysOverview_STATE, projCStat);
  return;
}

void fwSysOverview_updateSystemState(string sysDpName, int sysCStat)
{  
  int previousState = 0;
  dpGet(sysDpName + fwSysOverview_STATE, previousState); 
  
  if(sysCStat != previousState)
    dpSet(sysDpName + fwSysOverview_STATE, sysCStat);

  return;
}

/** Converts state in integer format to a string format. 
    NOTE: By modifying this function one can add additional states
*/

string fwSysOverview_getStrFromState(int stat)
{
  string str;
  
  switch(stat){
    case fwSysOverview_STOPPED_NORMAL:
      str = "STOPPED";
      break;
    case fwSysOverview_INITIALIZE:
      str = "INITIALIZING";
      break;
    case fwSysOverview_RUNNING:
      str = "RUNNING";
      break;
    case fwSysOverview_BLOCKED:
      str = "MAN_BLOCKED";
      break;
    case fwSysOverview_STOPPED_ABNORMAL:
//      str = "MANAGER ABNORMALLY STOPPED";
      str = "MAN_ABN_STOPPED";
      break;
    case fwSysOverview_RAPID_RESTART:
      str = "MAN_ABN_STOPPED";
      break;
    case fwSysOverview_PROJNAME_MISMATCH:
      str = "PROJ_MISMATCH";
      break;
    case fwSysOverview_PMON_NO_RESPONSE:
      str = "PMON_NO_RESPONSE";
      break;
//    case fwSysOverview_PMON_NOT_RUNNING:
//      str = "PMON_NO_RESPONSE";
//      break;
    case fwSysOverview_MONITORING_STOPPED:
      str = "NOT_MONITORED";
      break;
    default:
      str = "UNDEFINED";
      break;
   }  
  return str;
}

/** Sets the projects current state as PMON_NOT_RESPONDING

@param projDp  Project datapoint name

*/
int fwSysOverview_setProjPmonNotResponding(string projDp)
{
  return dpSet(projDp + fwSysOverview_STATE,fwSysOverview_PMON_NO_RESPONSE);
}

/** Removes the system name from a dp-name
 * @param sDpName name of the dp
 * @return dp-name without the system name
 */
string fwSysOverview_removeSystemName(string sDpName)
{
  dyn_string ds;

  ds = strsplit(sDpName, ":");
  if(dynlen(ds) > 1)
    return ds[2];
  else 
    return ds[1];  

}

/** Updates the state of the system based on the states of the projects in the system.
 * @param sysDp  The datapoint name for which the state is to be updated
*/

int fwSysOverview_updateSysState(string sysDp)
{
  dyn_string projectDps;
  int projCStat, sysCStat;
  dyn_string exceptionInfo;

  fwSysOverview_getSystemProjects(sysDp,projectDps, exceptionInfo);

  for(int j = 1; j <= dynlen(projectDps); j++)
  {
    fwSysOverview_getDeviceState(projectDps[j], projCStat);
    if(j == 1)
      sysCStat = projCStat;
     
    else if(projCStat > sysCStat)
      sysCStat = projCStat;
  }
  
  return  dpSet(sysDp + fwSysOverview_STATE, sysCStat); 
}

int fwSysOverview_setProjectsInGroups(dyn_dyn_string &projectGroups)
{
  dyn_string projDps;   
  int err = fwSysOverview_getAllProjects(projDps);
  
  if(err<0)
    return fwSysOverview_ERROR;
  
  int i = 1;
  int n = dynlen(projDps);
  int k = 1;

  while(k <= n)
  {
    for(int j = 1; j <= fwSysOverview_TCP_LIMIT; j++)
    {
      k = j + (fwSysOverview_TCP_LIMIT*(i-1));      
      if(k > n)
        break;
      
      projectGroups[j][i] = projDps[k];
    }
    ++i;
  }
  
//DebugN("resulting projectGroup:", projectGroups);

/*  
DebugN("dynlen(projDps)>fwSysOverview_TCP_LIMIT", dynlen(projDps), fwSysOverview_TCP_LIMIT);  
  if(dynlen(projDps)==0)
  {
    return fwSysOverview_OK;  
  }
  else if(dynlen(projDps)>fwSysOverview_TCP_LIMIT)
  {
    groupN = dynlen(projDps)/fwSysOverview_TCP_LIMIT;
    rest = fmod(dynlen(projDps),fwSysOverview_TCP_LIMIT);
DebugN("groupN, rest", groupN, rest);    
    while(i<=fwSysOverview_TCP_LIMIT && k<=dynlen(projDps))
    {
      for (j=1;j<=floor(groupN);j++)
      {
        projectGroup[i][j]=projDps[k];
        k++;
       }  
     i++;
    }
   
   for(i=1;i<=rest;i++)
    {
     projectGroup[i][ceil(groupN)]=projDps[k];
     k++;
     }    
  } 
  else
     for(i=1;i<=dynlen(projDps);i++)
      {
       projectGroup[i][1]=projDps[k];
       k++;
       } 
*/  
 return fwSysOverview_OK;
}

fwSysOverview_getManagerProjectDp(string managerDp, string& projectDp)
{
  if (dpExists(managerDp) && dpTypeName(dpSubStr(managerDp, DPSUB_DP)) == "FwSystemOverviewManager")
  {
    dyn_string dpArr = strsplit(dpSubStr(managerDp, DPSUB_DP), "/");
    if (dynlen(dpArr) > 2)
    {
      projectDp = dpArr[1] + "/" + dpArr[2] + "/" + dpArr[3];
    }
  }
}

fwSysOverview_getManagerData(string manDp, string &hostName, int &manIdx, int &portNum, string &userName, string &userPass, string &manOptions, dyn_string &exceptionInfo)
{
  string projectName, projDp, manager;
  dyn_string str;
  
  if(!dpExists(manDp))
  {
    fwException_raise(exceptionInfo,"WARNING","DP:\n"+manDp+ "\n"+"does not exists" ,"");
    return;
  }
  
  else
  {
    dpGet(manDp + fwSysOverview_MANAGER_PROJECT, projectName,
          manDp + fwSysOverview_MANAGER_HOST, hostName,
          manDp + fwSysOverview_MANAGER_OPTIONS, manOptions,
          manDp + fwSysOverview_MANAGER_INDEX, manIdx          
          );
    
        str = strsplit(manDp, "/");
        strreplace(str[dynlen(str)], "Manager","");
//         manIdx = str[dynlen(str)];
//         manIdx -=1; 
     
        
        fwSysOverview_getDeviceName(manDp, manager);
        projDp = manDp;
        strreplace(projDp, "/" + manager, "");
        
        dpGet(projDp + fwSysOverview_PROJECT_PMON_NUMBER, portNum,
              projDp + fwSysOverview_PROJECT_USER_NAME, userName,
              projDp + fwSysOverview_PROJECT_USER_PASS,userPass
              );
  
  }
}

fwSysOverview_startManager(string hostName, int portNum, string userName, string userPass, int manIdx, dyn_string &exceptionInfo)
{
  string command;
  
  command = userName + "#" + userPass + "#SINGLE_MGR:START "+(manIdx);   

  pmon_command(command, hostName, portNum, false,true);
}

fwSysOverview_stopManager(string hostName, int portNum, string userName, string userPass, int manIdx, dyn_string &exceptionInfo)
{
  string command;
  
  command = userName + "#" + userPass + "#SINGLE_MGR:STOP "+(manIdx);    

  pmon_command(command, hostName, portNum, false,true);
}

fwSysOverview_killManager(string hostName, int portNum, string userName, string userPass, int manIdx, dyn_string &exceptionInfo)
{
  string command;
  
  command = userName + "#" + userPass + "#SINGLE_MGR:KILL "+(manIdx);    

  pmon_command(command, hostName, portNum, false,true);
}

fwSysOverview_deleteHost(string dbHostName, dyn_string &exceptionInfo) //deletes Host DP and all related Projects DPs
{
  string hostDp, dbProject;
  dyn_string projectDpNames,  resultText;
  dyn_float resultFloat;
  
  fwSysOverview_getHostDp(dbHostName, hostDp);

  if(!dpExists(hostDp))
  {
    fwException_raise(exceptionInfo,"WARNING","Data Point for given PC : " + dbHostName + " does not exist.", "");  
    return;
  }

  fwSysOverview_getPcProjects(hostDp, projectDpNames);
  
  if(dynlen(projectDpNames) > 0)
  {
    ChildPanelOnCentralReturn("vision/MessageWarning2", "WARNING: Confirmation", 
                            makeDynString("$1:There is at least one project releated to given host " + dbHostName + " : \n" + projectDpNames 
                            + "\n"+ "Are you sure you want to delete selected host and related projects?", "$2:YES", "$3:NO"), resultFloat, resultText);
                           
    bool ok=FALSE;
    if(dynlen(resultFloat) > 0 ) 
      ok = resultFloat[1];

  
    if(ok)
    {       
      for(int i=1; i<=dynlen(projectDpNames); i++)
      {
        dpGet(projectDpNames[i] + fwSysOverview_PROJECT_NAME, dbProject);
        
        fwSysOverview_deleteProject(dbHostName, dbProject, exceptionInfo);
        if(dynlen(exceptionInfo)) {//fwExceptionHandling_display(exceptionInfo); 
          return ;}

        if(dynlen(exceptionInfo)){return;}
      }
    }
  }
    
  dpDelete(hostDp);
  
  //Delete FMC host as well:
  fwFMC_removeNodes(makeDynString(dbHostName));
    
  return;
}

void fwSysOverview_deleteProject(string dbHostName, string dbProjectName, dyn_string &exceptionInfo)
{
  string dbSystem;
  string systemDpName, projectDpName;
  dyn_string projectDpNames, resultText;
  dyn_float resultFloat;
  dyn_dyn_anytype results;
  
  fwSysOverview_getProjectDp(dbHostName, dbProjectName, projectDpName, exceptionInfo);
  if(dynlen(exceptionInfo)) {return ;}
      
  fwSysOverview_getProjectSystem(projectDpName, systemDpName, exceptionInfo);
  if(dynlen(exceptionInfo)) {return ;}
  
  dpGet(projectDpName + fwSysOverview_PROJECT_SYSTEM, dbSystem);
    
  dpDelete(projectDpName);
  
  fwSysOverview_deleteManagers(projectDpName, exceptionInfo);
  if(dynlen(exceptionInfo)) {return ;}
  
  fwSysOverview_getSystemProjects(systemDpName, projectDpNames, exceptionInfo);
  if(dynlen(exceptionInfo)) {return ;}
  
  if(dynlen(projectDpNames) == 0)
  {
    dpDelete(systemDpName);
    return;
  }
  
  
  return;                   
}

void fwSysOverview_deleteManagers(string projectDp, dyn_string &exceptionInfo)
{
  dyn_string managerDps = fwSysOverview_getProjectManagerDPs(projectDp);
  
  for(int i=1; i<=dynlen(managerDps); i++)
  {
    if(dpExists(managerDps[i]))
      dpDelete(managerDps[i]);
  }
  

}
  
void fwSysOverview_checkDbConsistency(dyn_dyn_mixed projectInfo, bool &consistent, dyn_string &hostsToBeDeleted, dyn_dyn_string &projectsToBeDeleted, dyn_string &exceptionInfo)
{
  dyn_string dbHosts, dbProjects;
  
  for(int i =1; i<=dynlen(projectInfo); i++)
  {
    dynAppend(dbHosts, projectInfo[i][fwSysOverview_PROJECT_HOST_IDX] );
    dynAppend(dbProjects, projectInfo[i][fwSysOverview_PROJECT_NAME_IDX] );
  }
  
  dynUnique(dbHosts);
  
  fwSysOverview_hostsToBeDeleted(dbHosts, hostsToBeDeleted, exceptionInfo);
  if(dynlen(exceptionInfo)) {//fwExceptionHandling_display(exceptionInfo); 
    return ;}
  
  fwSysOverview_projectsToBeDeleted(dbProjects, projectsToBeDeleted, exceptionInfo);
  if(dynlen(exceptionInfo)) {//fwExceptionHandling_display(exceptionInfo); 
    return ;}
  
  if(dynlen(projectsToBeDeleted) > 0 || dynlen(hostsToBeDeleted) > 0)
    consistent = false;
  
  return;
  
}

void fwSysOverview_hostsToBeDeleted(dyn_string dbHosts, dyn_string &hostsToBeDeleted, dyn_string &exceptionInfo)
{
  dyn_string hostDps;
  string hostFromDpe;

  hostDps = dpNames(getSystemName() + fwSysOverview_SYSTEM_DP +"*", "FwSystemOverviewPC");

  for(int i=1; i<=dynlen(hostDps); i++)
  {
    fwSysOverview_getHostDb(hostDps[i], hostFromDpe, exceptionInfo);
    if(dynlen(exceptionInfo)) {//fwExceptionHandling_display(exceptionInfo); 
      return ;}

    if(!dynContains(dbHosts, hostFromDpe))
      dynAppend(hostsToBeDeleted, hostFromDpe);
  }

  return;
}

void fwSysOverview_projectsToBeDeleted(dyn_string dbProjects, dyn_dyn_string &projectsToBeDeleted, dyn_string &exceptionInfo)
{
  dyn_string projectDps;
  string projectFromDpe;
//  dyn_string exceptionInfo;
  string hostDp, hostFromDpe;
  dyn_string hosts, projects;

  projectDps = dpNames(getSystemName() + fwSysOverview_SYSTEM_DP + "*", "FwSystemOverviewProject");
  
  for(int i=1; i<= dynlen(projectDps); i++)
  {
    fwSysOverview_getProjectDb(projectDps[i], projectFromDpe, exceptionInfo);
    if(dynlen(exceptionInfo)) {//fwExceptionHandling_display(exceptionInfo); 
      return ;}

    if(!dynContains(dbProjects, projectFromDpe))
    {
      fwSysOverview_getProjectPc(projectDps[i], hostDp, exceptionInfo);
//      if(dynlen(exceptionInfo)) {fwExceptionHandling_display(exceptionInfo); return ;}

      fwSysOverview_getHostDb(hostDp, hostFromDpe, exceptionInfo);
//      if(dynlen(exceptionInfo)) {fwExceptionHandling_display(exceptionInfo); return ;}

      dynAppend(hosts, hostFromDpe);
      dynAppend(projects, projectFromDpe);
    }
  }
  
  for(int i=1; i<=dynlen(projects); i++)
  {
    projectsToBeDeleted[i][1] = hosts[i];      
    projectsToBeDeleted[i][2] = projects[i];
  }
//DebugN("projectsToBeDeleted", projectsToBeDeleted);
  return;
}

void fwSysOverview_getLicenseStatus(string systemName, string &license, dyn_string &exceptionInfo)
{
  if(!dpExists(systemName + "_Event.License.RemainingTime:_alert_hdl.._act_text"))
  {
//    fwException_raise(exceptionInfo,"WARNING","DP:\n" + systemName + "_Event.License.RemainingTime:_alert_hdl.._act_text"+ "\n"+"does not exist" ,"");
    license = "N/A: Not Connected";                    
  }
  else
  {
      dpGet(systemName + "_Event.License.RemainingTime:_alert_hdl.._act_text", license);
  }
  return;
}   

fwSysOverview_createManagerDp(string managerNumber, string projDp, bool createAlerts, dyn_string &exceptionInfo)
{
  bool handlingActive = TRUE,
       active = TRUE,
       archActive = FALSE;
  string managerDp;
  string archiveClass = "";
  int enable;
    
  managerDp = projDp + "/" + "Manager" + managerNumber;
  
  dpCreate(managerDp, "FwSystemOverviewManager");
  
  while(!dpExists(managerDp))
    delay(0,100);
  
  dpSetWait(managerDp + fwSysOverview_MANAGER_CONFIG_STARTMODE_VALUE, fwSysOverview_DEFAULT_VALUE_CONFIG_STARTMODE); //Initialize config value of the config start mode 
  if(createAlerts == TRUE)
  {  
    fwSysOverview_setManagerAlert(managerDp, handlingActive, exceptionInfo);
    if(dynlen(exceptionInfo)){return;}
    
    dpGet(projDp + fwSysOverview_STATE + ":_alert_hdl.._active", active);
        
    if (active == false);
    {
      _fwAlertConfig_activateOrDeactivate(managerDp + fwSysOverview_STATE, active, exceptionInfo);
      fwSystemOverview_connectManagerStartModeDpe(managerDp, createAlerts, exceptionInfo);
    }
  }

  fwSysOverview_isArchivingEnabled(enable);
  if(enable !=0)
  {
    fwSysOverview_getAchiveClass(archiveClass);
    if(archiveClass != "")
    {
      fwSysOverview_createArchiveConfig(managerDp + fwSysOverview_STATE, archiveClass, exceptionInfo);
      if(dynlen(exceptionInfo)){return;}
    }
  }
  
}


fwSysOverview_setManagerAlert(string managerDp, bool handlingActive, dyn_string &exceptionInfo)
{    
  dyn_mixed alarmObject;
  string dpe = managerDp + fwSysOverview_STATE;
  //create the alarm object
  fwAlertConfig_objectCreateDiscrete( 
            alarmObject, //the object that will contain the alarm settings
            makeDynString("OK","Manager Blocked","Manager Abnormally Stopped"), //the text for the 3 ranges
            makeDynString("*", fwSysOverview_BLOCKED, fwSysOverview_STOPPED_ABNORMAL), //the 3 ranges must match these values (the 1st must be always the good one - *)
            makeDynString("","_fwWarningNack.","_fwErrorNack."), //classes (the 1st one must always be the good one)
            "", //alarm panel, if necessary
            makeDynString(""), //$-params to pass to the alarm panel, if necessary
            "", //alarm help, if needed
            false, //impulse alarm
            makeDynBool(0,0,0), //negation of the matching (0 means "=", 1 means "!=")
            "", //state bits that must also match for the alarm
            makeDynString("","",""), //state bits that must match for each range
            exceptionInfo,
           false,
           false,
           "",
           false); //exception info returned here
  if(dynlen(exceptionInfo)){ return;}        

  //set the alarm to the dpe                                        
  fwAlertConfig_objectSet(dpe, alarmObject, exceptionInfo);   
  if(dynlen(exceptionInfo)){ return;}    
  
  //activate it
  if(handlingActive){fwAlertConfig_activate(dpe, exceptionInfo); if(dynlen(exceptionInfo)){return;}}
}

dyn_string fwSysOverview_getProjectManagerDPs(string projDP)
{
  dyn_string projManagerDPs;
  
  if(patternMatch("*.", projDP))
    projDP = substr(projDP, 0, (strlen(projDP)-1));
  
  projManagerDPs=dpNames(projDP + "/Manager*","FwSystemOverviewManager");
  dynSortAsc(projManagerDPs);
  return projManagerDPs;          
}

string fwSysOverview_getNodePowerStatus(string node, string fmcSystem)
{
  string powerStatus = "";
//  string fmcSystem = "";
  
  if(fmcSystem == "")
    fmcSystem = fwSysOverview_getFmcSystem();      
   
  if(isFunctionDefined("fwFMC_getNodePowerStatus") && dpExists(fmcSystem + "FMC/"+node))  
    powerStatus = fwFMC_getNodePowerStatus(node, fmcSystem);

  else
  {
    dyn_string projDPs;
    string hostDp;
    int projStatus;
    int counter1 = 0, counter2 = 0;

    fwSysOverview_getHostDp(node, hostDp);
    projDPs = dpNames(hostDp + "/*", "FwSystemOverviewProject");

    for(int i=1; i<=dynlen(projDPs);i++)
    {
      dpGet(projDPs[i] + fwSysOverview_STATE, projStatus);

      if(projStatus != fwSysOverview_PMON_NO_RESPONSE) 
        ++counter1;
      if(projStatus == fwSysOverview_MONITORING_STOPPED)
        ++counter2;
    } 

    if(counter1 > 0 && counter2 != dynlen(projDPs))
      powerStatus = "ON";
    else
      powerStatus = "UNKNOWN";
  }
  return powerStatus; 
}

string fwSysOverview_getNodeReadoutStatus(string node, string fmcSystem)
{
  dyn_string projDPs;
  int projStatus;
  int counter1 = 0, counter2 = 0;
  string commStatus = "";
  string hostDp;
//  string fmcSystem = "";

  if(fmcSystem == "")
    fmcSystem = fwSysOverview_getFmcSystem();
    
  if(isFunctionDefined("fwFMC_getNodeReadoutStatus") && dpExists(fmcSystem + "FMC/"+node))
    commStatus = fwFMC_getNodeReadoutStatus(node, fmcSystem);

  else
  {
    fwSysOverview_getHostDp(node, hostDp);
    projDPs = dpNames(hostDp + "/*", "FwSystemOverviewProject");
  
    if(dynlen(projDPs) >0)
    {                   
      for(int i=1; i<=dynlen(projDPs);i++)
      {
        dpGet(projDPs[i] + fwSysOverview_STATE, projStatus);
        if(projStatus == fwSysOverview_PMON_NO_RESPONSE)       
          ++counter1;
        if(projStatus == fwSysOverview_MONITORING_STOPPED)
          ++counter2;
      }
    }
  
    if(counter1 > 0 || counter2 == dynlen(projDPs))
      commStatus = "ERROR";
    else
      commStatus = "OK";     
  } 
      
  return commStatus;
}

//*************************************************************************************************************************
//*************************************************************************************************************************
//*************************************************************************************************************************
//*************************************************************************************************************************

int fwSysOverview_configure()
{
  dyn_dyn_mixed projectInfo;
  dyn_string exceptionInfo;
  bool createAlerts = true, consistent = true;
  
  dyn_string hostsToBeDeleted;
  dyn_dyn_string projectsToBeDeleted;
  
  if(fwSysOverview_getDBInfo(projectInfo, exceptionInfo) == fwSysOverview_ERROR)
    return;
  
  fwSysOverview_checkDbConsistency(projectInfo, consistent, hostsToBeDeleted, projectsToBeDeleted, exceptionInfo);
  if(dynlen(exceptionInfo)) {return ;}

  if(consistent == false)
  {
    dyn_float resultFloat;
    dyn_string resultText;
    
    ChildPanelOnCentralModalReturn("fwSystemOverview/fwSystemOverview_DB_Consistency.pnl", "DB Consistency", makeDynString(), resultFloat, resultText);
  }
  
  openProgressBar("","","Configuring the System Overview Tool", "","", 2); 
  
  for(int i=1; i<=dynlen(projectInfo); i++)
  {
    showProgressBar("Creating data points.", "", "", (100*i)/dynlen(projectInfo));
    
    if(projectInfo[i][fwSysOverview_PROJECT_NAME_IDX] == "" || projectInfo[i][fwSysOverview_PROJECT_HOST_IDX] == "" || 
       projectInfo[i][fwSysOverview_PROJECT_SYSTEM_NAME_IDX] == "")
      continue;
	
    else
    {
      // ATLAS-specific: restrict systems belonging to a subdetector
     //
/*       if (isFunctionDefined("fwAtlas") && strpos(getSystemName(), "ATLGCSSYS")<0) 
      {
        string subdetId = strtoupper(fwAtlas_getSubdetectorId(getSystemName()));
        if (strpos(projectInfo[i][fwSysOverview_PROJECT_SYSTEM_NAME_IDX], subdetId)<0) 
        {
          DebugN("Ignoring PVSS system " + projectInfo[i][fwSysOverview_PROJECT_SYSTEM_NAME_IDX] +" since it is not part of subdetector " + subdetId);
          continue;
        }
      }
*/
      if(isFunctionDefined("fwAtlas"))
      {
        if(!fwSysOverview_checkSystemSubdetector(projectInfo[i][fwSysOverview_PROJECT_SYSTEM_NAME_IDX]))
          continue;
      }
      
      fwSysOverview_createProject(projectInfo[i], createAlerts, exceptionInfo); 
      if(dynlen(exceptionInfo)) {continue ;} 
    }
  }
  closeProgressBar();
  
  dpSet(fwSysOverview_PARAMETRIZATION + fwSysOverview_DB_UPDATE, true);
  
  return fwSysOverview_OK ;
}

void fwSysOverview_createProject(dyn_mixed projectInfo, bool createAlerts, dyn_string &exceptionInfo) 
{
  string pvssProjectName, pvssHostName;
  bool handlingActive = TRUE;
  string descript;
  int enable;
  string archiveClass = "";
        
  string dbProjectName = projectInfo[fwSysOverview_PROJECT_NAME_IDX];
  string dbHostName = projectInfo[fwSysOverview_PROJECT_HOST_IDX];
  string pmonNum = projectInfo[fwSysOverview_PROJECT_PMON_NUM_IDX];
  string pmonUser = projectInfo[fwSysOverview_PROJECT_PMON_USER_IDX];
  string pmonPass = projectInfo[fwSysOverview_PROJECT_PMON_PASS_IDX];
  string systemName = projectInfo[fwSysOverview_PROJECT_SYSTEM_NAME_IDX];
  string systemNum = projectInfo[fwSysOverview_PROJECT_SYSTEM_NUM_IDX];
  
  string projectDpName;
  
  fwSysOverview_getProjectDp(dbHostName, dbProjectName, projectDpName, exceptionInfo);
  if(dynlen(exceptionInfo)){return;}
  
  bool exists = false;
  fwSysOverview_projectExists(dbProjectName, dbHostName, exists);     
//  if(dynlen(exceptionInfo)){return;}
  

  if(!exists)
  {
    dpCreate(projectDpName , "FwSystemOverviewProject");
    
    while(!dpExists(projectDpName))
      delay(0,100);
    
    if(createAlerts == TRUE)
    {
      fwSysOverview_setProjectAlert(dbProjectName, dbHostName, handlingActive, exceptionInfo);
      if(dynlen(exceptionInfo)){return;}
    }
    
    fwSysOverview_isArchivingEnabled(enable);
    if(enable !=0)
    {
      fwSysOverview_getAchiveClass(archiveClass);
      if(archiveClass != "")
      {
        fwSysOverview_createArchiveConfig(projectDpName + fwSysOverview_STATE, archiveClass, exceptionInfo);
        if(dynlen(exceptionInfo)){return;}
      }
    }    
  }

  dpSetWait(projectDpName + fwSysOverview_PROJECT_NAME, dbProjectName,
            projectDpName + fwSysOverview_PROJECT_PMON_NUMBER, pmonNum,
            projectDpName + fwSysOverview_PROJECT_USER_NAME, pmonUser,
            projectDpName + fwSysOverview_PROJECT_USER_PASS, pmonPass,
            projectDpName + fwSysOverview_PROJECT_SYSTEM, systemName
            );
  
//  descript = "Project:" + pvssProjectName + " Host:" + pvssHostName;
//  dpSetDescription(fwSysOverview_SYSTEM_DP + pvssHostName + "/" + pvssProjectName + ".", descript);   
  
  descript = "Project:" + dbProjectName + " Host:" + dbHostName;
  dpSetDescription(projectDpName + ".", descript);   

  
//  fwSysOverview_createHost(projectInfo, exceptionInfo);
  fwSysOverview_createHostDp(dbHostName, "", exceptionInfo);
      
//  fwSysOverview_createSystem(projectInfo, exceptionInfo);  
  fwSysOverview_createSystemDp(systemName, systemNum, dbHostName, exceptionInfo);  
  
  return;
}
 

void fwSysOverview_createHost(dyn_mixed projectInfo, dyn_string &exceptionInfo) //become obsolete
{
  string dbHostName = projectInfo[fwSysOverview_PROJECT_HOST_IDX];
  bool exists = false;
  string hostDpName = "";
  
  fwSysOverview_hostExists(dbHostName, exists);

  
  fwSysOverview_getHostDp(dbHostName, hostDpName);
    
  if(!exists)
    dpCreate(hostDpName, "FwSystemOverviewPC");

    dpSetWait(hostDpName + fwSysOverview_PC_HOST_NAME, dbHostName
//            ,fwSysOverview_SYSTEM_DP + pvssHostName + fwSysOverview_PC_FMC_DP, 
            );
  return;
  
}

void fwSysOverview_createHostDp(string dbHostName, string fmcDp, dyn_string &exceptionInfo)
{
  string pvssHostName;
  bool exists = false;
  string hostDp = "";
    
  fwSysOverview_hostExists(dbHostName, exists);
  fwSysOverview_getHostDp(dbHostName, hostDp);
    
  if(!exists)
    dpCreate(hostDp, "FwSystemOverviewPC");

    dpSetWait(hostDp + fwSysOverview_PC_HOST_NAME, dbHostName, 
              hostDp + fwSysOverview_PC_FMC_DP, fmcDp); 
  //Create FMC host now if it does not exist:
  if(!dpExists(fwFMC_getNodeDp(dbHostName)))  
    fwFMC_createNode(dbHostName, dbHostName, false, "", "", false, 0, false, false, false, "", "", dbHostName, makeDynString(), "standard", true);  
  
  return;
}

void fwSysOverview_createSystem(dyn_mixed projectInfo, dyn_string &exceptionInfo)
{
  string systemName = projectInfo[fwSysOverview_PROJECT_SYSTEM_NAME_IDX];
  string systemNum = projectInfo[fwSysOverview_PROJECT_SYSTEM_NUM_IDX];
  string hostName = projectInfo[fwSysOverview_PROJECT_HOST_IDX];
  bool exists = false;
  string archiveClass = "";
  int enable;

  string sysDp = "";
  fwSysOverview_getSystemDp(systemName, hostName, sysDp, exceptionInfo);
  if(dynlen(exceptionInfo))
    return;
      
  fwSysOverview_systemExists(systemName, exists, hostName, exceptionInfo); 
  if(dynlen(exceptionInfo)){return;}
  
  if(!exists)
  {  
    dpCreate(sysDp, "FwSystemOverviewSystem");
    
    fwSysOverview_isArchivingEnabled(enable);
    if(enable !=0)
    {
      fwSysOverview_getAchiveClass(archiveClass);
      if(archiveClass != "")
      {
        fwSysOverview_createArchiveConfig(sysDp + fwSysOverview_STATE, archiveClass, exceptionInfo);
        if(dynlen(exceptionInfo)){return;}
      }
    }    
  }
    

  dpSetWait(sysDp + fwSysOverview_SYSTEM_NAME, systemName,
            sysDp + fwSysOverview_SYSTEM_NUMBER, systemNum);
  return;
}

void fwSysOverview_createSystemDp(string systemName, string systemNum, string hostName, dyn_string &exceptionInfo)
{
  bool exists = false;
  string sysDp = "";
  string archiveClass = "";
  int enable;
  
  fwSysOverview_getSystemDp(systemName, hostName, sysDp, exceptionInfo);
  if(dynlen(exceptionInfo))
    return;
      
  fwSysOverview_systemExists(systemName, exists, hostName, exceptionInfo);
  if(dynlen(exceptionInfo)){return;} 
  
  if(!exists)
  {
    dpCreate(sysDp, "FwSystemOverviewSystem");
    fwSysOverview_isArchivingEnabled(enable);
    if(enable !=0)
    {
      fwSysOverview_getAchiveClass(archiveClass);
      if(archiveClass != "")
      {
        fwSysOverview_createArchiveConfig(sysDp + fwSysOverview_STATE, archiveClass, exceptionInfo);
        if(dynlen(exceptionInfo)){return;}
      }
    }
  }    
  
  dpSetWait(sysDp + fwSysOverview_SYSTEM_NAME, systemName,
            sysDp + fwSysOverview_SYSTEM_NUMBER, systemNum);
  return;
}

// converts DB names in order to create proper DPs
void fwSysOverview_convertDbName(string name, string option, string &convertedName, dyn_string &exceptionInfo)
{ 
  option = strtolower(option);
  if(name == "")
  {
    fwException_raise(exceptionInfo,"WARNING","fwSysOverview_convertDbName -> Name value, you wanted to convert, in fwSysOverview_convertDbName function,is empty." ,"");
    return;
  }
  else if(option == "project") // PROJECTS
  {
    strreplace(name, ".", "_");
    convertedName = strtoupper(name);
    return;
  }
  else if(option == "host") // HOSTS
  {
    name = strsplit(name, ".")[1];
    convertedName = strtoupper(name);
    return;
  }
  else if(option == "system") //SYSTEMS
  {
    strreplace(name, ".", "_");
    strreplace(name, ":", "");
    convertedName = strtoupper(name);
    return;
  }
  else
  {
    fwException_raise(exceptionInfo,"WARNING","fwSysOverview_convertDbName -> Option value: " + option + " in fwSystemOverview_convertDBName function was not recognized" ,"");
    DebugTN("fwSysOverview_convertDbName -> Option value: " + option + " in fwSystemOverview_convertDBName function was not recognized");
//    convertedName = ""; 
    return;
  }
}

void fwSysOverview_projectExists(string dbProjectName, string dbHostName, bool &exists)
{
  dyn_dyn_anytype projects;
  string pvssHost;
  dyn_string exceptionInfo;
  
  fwSysOverview_convertDbName(dbHostName, "host", pvssHost, exceptionInfo);
  
  dynClear(projects);

//  dpQuery("SELECT '_original.._value' FROM 'SystemOverview/*" + fwSysOverview_PROJECT_NAME + "' WHERE _DPT=\"FwSystemOverviewProject\" ", projects);
  dpQuery("SELECT '_original.._value' FROM 'SystemOverview/" + pvssHost + "/*" + fwSysOverview_PROJECT_NAME + "' WHERE _DPT=\"FwSystemOverviewProject\" ", projects);
    
  for(int i=1; i<=dynlen(projects); i++)
  {
    if(dynContains(projects[i], dbProjectName))
    {
      exists = true;
//      fwException_raise(exceptionInfo,"WARNING","Data Point for " + dbProjectName + " project already exists." + "\n" + projects[i][1], "");  
//      DebugTN("Data Point for " + dbProjectName + " project already exists." + "\n" + projects[i][1]);
      return;
    }
  }
    return;
}

void fwSysOverview_hostExists(string dbHostName, bool &exists)
{
  dyn_dyn_anytype hosts;
  dynClear(hosts);

  dpQuery("SELECT '_original.._value' FROM 'SystemOverview/*" + fwSysOverview_PC_HOST_NAME + "' WHERE _DPT=\"FwSystemOverviewPC\" ", hosts);
  
  for(int i=1; i<=dynlen(hosts); i++)
  {
    if(dynContains(hosts[i], dbHostName))
    {
      exists = true;
//      fwException_raise(exceptionInfo,"WARNING","Data Point for " + dbHostName + " PC already exists." + "\n" + hosts[i][1], "");  
      return;
    }
  }
  
    return;
}

void fwSysOverview_systemExists(string dbSystemName, bool &exists, string dbHostName, dyn_string &exceptionInfo)
{
  dyn_dyn_anytype systems;
  string pvssHostName;
  dynClear(systems);

  fwSysOverview_convertDbName(dbHostName, "host", pvssHostName, exceptionInfo);
  if(dynlen(exceptionInfo)){return;} 
      
  dpQuery("SELECT '_original.._value' FROM 'SystemOverview/*" + fwSysOverview_SYSTEM_NAME + "/" + pvssHostName + "' WHERE _DPT=\"FwSystemOverviewSystem\" ", systems);
  
  for(int i=1; i<=dynlen(systems); i++)
  {
    if(dynContains(systems[i], dbSystemName))
    {
      exists = true;
//      fwException_raise(exceptionInfo,"WARNING","Data Point for " + dbSystemName + " system already exists." + "\n" + systems[i][1], "");  
      return;
    }
  }
    return;
}

void fwSysOverview_setProjectAlert(string dbProjectName, string dbHostName, bool handlingActive, dyn_string &exceptionInfo)
{    
  dyn_mixed alarmObject;
  string pvssProjectName;
  string pvssHostName;
  string dpe;
  
  //fwSysOverview_convertDbName(dbProjectName, "project", pvssProjectName , exceptionInfo);
  fwSysOverview_getProjectDp(dbHostName, dbProjectName, dpe, exceptionInfo);
  if(dynlen(exceptionInfo)) {return;}
DebugN("dpe: " + dpe);
  dpe = dpe + fwSysOverview_STATE;

  //create the alarm object
  fwAlertConfig_objectCreateDiscrete( 
            alarmObject, //the object that will contain the alarm settings
            makeDynString("OK", "Project Stopped","Managers Blocked", "Managers Abnormally Stopped", "Project Name Mismatch", "Pmon Not Responding"), //the text for the 4 ranges
            makeDynString("*", fwSysOverview_STOPPED_NORMAL, fwSysOverview_BLOCKED,  fwSysOverview_STOPPED_ABNORMAL, fwSysOverview_PROJNAME_MISMATCH, fwSysOverview_PMON_NO_RESPONSE), //the 4 ranges must match these values (the 1st must be always the good one - *)
            makeDynString("","_fwErrorNack.","_fwErrorNack.", "_fwErrorNack.", "_fwErrorNack.", "_fwErrorNack."), //classes (the 1st one must always be the good one)
            "", //alarm panel, if necessary
            makeDynString(""), //$-params to pass to the alarm panel, if necessary
            "", //alarm help, if needed
            false, //impulse alarm
            makeDynBool(0,0,0,0, 0, 0), //negation of the matching (0 means "=", 1 means "!=")
            "", //state bits that must also match for the alarm
            makeDynString("", "", "", "", "", ""), //state bits that must match for each range
            exceptionInfo ); //exception info returned here
  if(dynlen(exceptionInfo)){ return;}        

  //set the alarm to the dpe                                        
  fwAlertConfig_objectSet(dpe, alarmObject, exceptionInfo);   
  if(dynlen(exceptionInfo)){ return;}    
  
  //activate it
  if(handlingActive){fwAlertConfig_activate(dpe, exceptionInfo); if(dynlen(exceptionInfo)){ return;}}
  return;
}


void fwSysOverview_getHostDp(string dbHostName, string &hostDpName)
{
  string pvssHostName;
  dyn_string exceptionInfo; 

  fwSysOverview_convertDbName(dbHostName, "host", pvssHostName, exceptionInfo);
    if(dynlen(exceptionInfo)){return;}
  
  hostDpName = fwSysOverview_SYSTEM_DP + pvssHostName;
  
  return;
}
    
void fwSysOverview_getHostDb(string hostDpName, string &dbHostName, dyn_string &exceptionInfo)
{
  
  if(!dpExists(hostDpName + fwSysOverview_PC_HOST_NAME))
  {
    fwException_raise(exceptionInfo,"WARNING","fwSysOverview_getHostDb -> Data Point: " + hostDpName + " does not exist.", "");  
    return;
  }
  
  else
  {
    dpGet(hostDpName + fwSysOverview_PC_HOST_NAME, dbHostName);
  }
  
  return;
}
    
void fwSysOverview_getProjectDp(string dbHostName, string dbProjectName, string &projectDpName, dyn_string &exceptionInfo)
{
  string pvssHostName, pvssProjectName;
  string hostDpName;
  fwSysOverview_getHostDp(dbHostName, hostDpName);
  
  fwSysOverview_convertDbName(dbProjectName, "project", pvssProjectName, exceptionInfo);
  if(dynlen(exceptionInfo)){return;}
        
  projectDpName = hostDpName + "/" + pvssProjectName;
  
  return;
}
    
void fwSysOverview_getProjectDb(string projectDpName, string &dbProjectName, dyn_string &exceptionInfo)
{
   if(!dpExists(projectDpName + fwSysOverview_PROJECT_NAME))
  {
    fwException_raise(exceptionInfo,"WARNING","fwSysOverview_getProjectDb -> Data Point: " + projectDpName + " does not exist.", "");  
    return;
  }
  
  else
  {
    dpGet(projectDpName + fwSysOverview_PROJECT_NAME, dbProjectName);
  }
  
  return;
}
    
void fwSysOverview_getSystemDp(string dbSystemName, string dbHostName, string &systemDpName, dyn_string &exceptionInfo)
{
  string pvssSystemName;
  string pvssHost;
  
  fwSysOverview_convertDbName(dbHostName, "host", pvssHost, exceptionInfo);
  if(dynlen(exceptionInfo)){return;}
  
  fwSysOverview_convertDbName(dbSystemName, "system", pvssSystemName, exceptionInfo);
  if(dynlen(exceptionInfo)){return;}
  
  systemDpName = fwSysOverview_SYSTEM_DP + fwSysOverview_SYSTEM_PREFIX + pvssHost + "/" + pvssSystemName;
  
  return;  
}
    
void fwSysOverview_getSystemDb(string systemDpName, string &dbSystemName, dyn_string &exceptionInfo)
{
  if(!dpExists(systemDpName + fwSysOverview_SYSTEM_NAME))
  {
    fwException_raise(exceptionInfo,"WARNING","fwSysOverview_getSystemDb -> Data Point: " + systemDpName + " does not exist.", "");  
    return;
  }
  
  else
  {
    dpGet(systemDpName + fwSysOverview_SYSTEM_NAME, dbSystemName);
  }
  
  return;  
}

    
void fwSysOverview_getPcProjects(string hostDpName, dyn_string &projectDpNames) 
{
  string systemName = dpSubStr(hostDpName, DPSUB_SYS);
  string node = fwFMC_getNodeName(hostDpName);
  projectDpNames =  fwFMCPmon_getNodeProjectDps(node, systemName);
  return;
}

void fwSysOverview_getProjectPc(string projectDpName, string &hostDpName, dyn_string &exceptionInfo)
{
  dyn_string str, dps;
  string pvssHost;

  if(projectDpName == "")
  {
    fwException_raise(exceptionInfo,"WARNING","fwSysOverview_getProjectPc -> No project data point was passed in fwSysOverview_getProjectPc function", "");
    return;
  }
  
  str = strsplit(projectDpName, "/"); 

  if (dynlen(str) == 1) // if the string doesn't contain "/"
    return;
 
  pvssHost = str[dynlen(str) - 1];

  dps = dpNames(fwSysOverview_SYSTEM_DP + pvssHost, "FwSystemOverviewPC");
  
  if(dynlen(dps) > 1)
  {
    fwException_raise(exceptionInfo,"WARNING"," fwSysOverview_getProjectPc -> Multiple Data Points were found isnted of one : \n" + dps, "");
    return;
  }
  
  else
    hostDpName = dps;
//    hostDpName = dps[1];
  
  return;
}

void fwSysOverview_getProjectSystem(string projectDpName, string &systemDpName, dyn_string &exceptionInfo)
{
  string dbSystemName, pvssSystemName, hostDpName, dbHostName;
  dyn_string dps;
  
  if(!dpExists(projectDpName + fwSysOverview_PROJECT_SYSTEM))
  {
    fwException_raise(exceptionInfo,"WARNING","fwSysOverview_getProjectSystem -> Data Point: " + projectDpName + " does not exist.", "");  
    return;
  }
  
  else
  {
    dpGet(projectDpName + fwSysOverview_PROJECT_SYSTEM, dbSystemName);
    
    fwSysOverview_getProjectPc(projectDpName, hostDpName, exceptionInfo);
    if(dynlen(exceptionInfo)){return;}
    fwSysOverview_getHostDb(hostDpName, dbHostName, exceptionInfo);
    if(dynlen(exceptionInfo)){return;} 
    fwSysOverview_getSystemDp(dbSystemName, dbHostName, systemDpName, exceptionInfo);
    if(dynlen(exceptionInfo)){return;} 
 
  }
  
  return;
}

// this function is obsolete and it's only necessery for upgrading to 3.0.0 version of the tool.
void fwSysOverview_getSystemProjects_old(string systemDpName, dyn_string &projectDpNames, dyn_string &exceptionInfo)
{
  string dbSystemName, pvssSystemName;
  dyn_dyn_anytype results;
  string str;  
    
  if(!dpExists(systemDpName + fwSysOverview_SYSTEM_NAME))
  {
    fwException_raise(exceptionInfo,"WARNING","fwSysOverview_getSystemProjects - >Data Point: " + systemDpName + " does not exist.", "");  
    return;
  }
  
  else
  {
    dpGet(systemDpName + fwSysOverview_SYSTEM_NAME, dbSystemName);
    
    dpQuery("SELECT '_original.._value' FROM 'SystemOverview/*" + fwSysOverview_PROJECT_NAME + "' WHERE _DPT=\"FwSystemOverviewProject\" AND ('" + fwSysOverview_PROJECT_SYSTEM+ ":_original.._value' == \"" + dbSystemName+ "\")", results);
 
    if(dynlen(results) > 1)
    {
      for(int i=2; i<=dynlen(results); i++)
      {
        str = results[i][1];
        strreplace(str, fwSysOverview_PROJECT_NAME, "");
//        str = dpSubStr(str,DPSUB_DP);
        
        dynAppend(projectDpNames, str);
      }
    }
  }
      
  return;
}

void fwSysOverview_getSystemProjects(string systemDpName, dyn_string &projectDpNames, dyn_string &exceptionInfo)
{
  string dbSystemName, pvssSystemName, hostDp;
  dyn_dyn_anytype results;
  string str;  
    
  if(!dpExists(systemDpName + fwSysOverview_SYSTEM_NAME))
  {
    fwException_raise(exceptionInfo,"WARNING","fwSysOverview_getSystemProjects - >Data Point: " + systemDpName + " does not exist.", "");  
    return;
  }
  
  else
  {
    dpGet(systemDpName + fwSysOverview_SYSTEM_NAME, dbSystemName);
   
    fwSysOverview_getSystemHost(systemDpName, hostDp, exceptionInfo);
    if(dynlen(exceptionInfo)){return;} 
        
    dpQuery("SELECT '_original.._value' FROM 'SystemOverview/*" + fwSysOverview_PROJECT_NAME + "' WHERE _DPT=\"FwSystemOverviewProject\" AND ('" + fwSysOverview_PROJECT_SYSTEM+ ":_original.._value' == \"" + dbSystemName+ "\")", results);
 
    if(dynlen(results) > 1)
    {
      for(int i=2; i<=dynlen(results); i++)
      {
        str = results[i][1];
        strreplace(str, fwSysOverview_PROJECT_NAME, "");
//        str = dpSubStr(str,DPSUB_DP);
        
        
        if(patternMatch("*" + hostDp + "*", str))
          dynAppend(projectDpNames, str);
      }
    }
  }
      
  return;
}

fwSysOverview_connectToConfigParameters()
{
  if( !dpExists(fwSysOverview_PARAMETRIZATION + fwSysOverview_REFRESH_RATE))
  {
    DebugN("ERROR: fwSysOverview_connectToConfigParameters: There is no dpe: " + fwSysOverview_PARAMETRIZATION + fwSysOverview_REFRESH_RATE);
    return;
  }
  
  int currentUpdateInterval = -1;
  dpGet(fwSysOverview_PARAMETRIZATION + fwSysOverview_REFRESH_RATE, currentUpdateInterval);
  if(currentUpdateInterval < 30)
    dpSet(fwSysOverview_PARAMETRIZATION + fwSysOverview_REFRESH_RATE, 30);
  
  dpConnect("fwSysOverview_connectToRefreshRateCB",
           fwSysOverview_PARAMETRIZATION + fwSysOverview_REFRESH_RATE);
}

fwSysOverview_connectToRefreshRateCB(string dp, unsigned uNewValue)
{
  if(uNewValue < 10)
  {
    DebugN("WARNING: Refresh rate cannot be set to less than 10s. The new setting will be overwritten.");
    uNewValue = 10;
  }
  fwSysOverview_gRefreshInterval = uNewValue;
}

void fwSysOverview_setMonitoringDp(int val)
{
    //set callback dp in order to stop refresh in the panels:
    dpSet(fwSysOverview_PARAMETRIZATION + fwSysOverview_ENABLE_MONITORING, val);
}

void fwSysOverview_stopMonitoring()
{
  DebugTN("INFO: Stopping the project monitoring");    
    for(int i = dynlen(fwSysOverview_gThreadsIds);i >= 1; i--)
    {
      
      if(stopThread(fwSysOverview_gThreadsIds[i]) < 0)
      {
        DebugN("ERROR: Could not stop thread with ID: " + fwSysOverview_gThreadsIds[i]);
      }
      else
      {
        dynRemove(fwSysOverview_gThreadsIds, i);
      }    
    }
    
    dynClear(fwSysOverview_gThreadsIds);
    
    return;
}

void fwSysOverview_startMonitoring()
{
 dyn_dyn_string projectGroup;
 int i;
  DebugTN("INFO: Re-starting the project monitoring");    
    fwSysOverview_setProjectsInGroups(projectGroup);
  
    for(i = 1; i <= dynlen(projectGroup);i++)
    {
      dynAppend(fwSysOverview_gThreadsIds, startThread("fwSysOverview_pollProjects",projectGroup[i],i));      
      delay(1);
    }
    
//DebugN("******Threads started: ", fwSysOverview_gThreadsIds);
}

void fwSysOverview_enableMonitoring(string dpe, int value)
{
  fwSysOverview_stopMonitoring();
  
  if(value == 1)
    fwSysOverview_startMonitoring();
}

void fwSysOverview_getACDomain(string &domain, string device = "", string application = "")
{
  bool appFound = false;
  bool useAppBasedAC =  fwSysOverview_getUseApplicationBasedAccessControl();
  if (device != "" && useAppBasedAC)
  {
    string app;
    if (application == "")
    {
      fwSysOverviewNotifications_getApplication(device, app);
    }
    else
      app = application;
    appFound = app!="";
    domain = app;
  }
  else if (application != "" && useAppBasedAC)
  {
    appFound = true;
    domain = application;
  }
  if(!appFound && dpExists(fwSysOverview_PARAMETRIZATION + fwSysOverview_ACCESS_DOMAIN))
    dpGet(fwSysOverview_PARAMETRIZATION + fwSysOverview_ACCESS_DOMAIN, domain);
  return;
  
}

void fwSysOverview_setACDomain(string domain)
{
  if(dpExists(fwSysOverview_PARAMETRIZATION + fwSysOverview_ACCESS_DOMAIN))
    dpSet(fwSysOverview_PARAMETRIZATION + fwSysOverview_ACCESS_DOMAIN, domain);
  
}

void fwSysOverview_isProjectMonitoringDisabled(string projDp, bool &disabled)
{
  disabled = false;
  dpGet(projDp + fwSysOverview_PROJECT_DISABLE_MONITORING, disabled);
  
  return;
}

void fwSysOverview_disableProjectMonitoring(string projDp)
{
  dpSet(projDp + fwSysOverview_PROJECT_DISABLE_MONITORING, true);  
  return;
}

void fwSysOverview_enableProjectMonitoring(string projDp)
{
  dpSet(projDp + fwSysOverview_PROJECT_DISABLE_MONITORING, false);
  return;
}

void fwSysOverview_cleanDps()
{
  //dpSet(fwSysOverview_PARAMETRIZATION + fwSysOverview_ENABLE_MONITORING, false);
  fwSysOverview_setMonitoringDp(0);
  
  dyn_string resultText;
  dyn_float resultFloat;
  
  dyn_string hosts, projects, systems, managers;

  ChildPanelOnCentralModalReturn("vision/MessageInfo1", "WARNING: Old version detected", 
                              makeDynString("$1:Old structure of data points has been detected.\n" + 
                                            "All data points will be deleted."
                                             "\nPlease reconfigure the aplication." )
                              ,resultFloat, resultText
                              );
    
    openProgressBar("","","Preparing to delete all data points.", "","", 2);            
    
    projects= dpNames(fwSysOverview_SYSTEM_DP + "*", "FwSystemOverviewProject");
    hosts= dpNames(fwSysOverview_SYSTEM_DP + "*", "FwSystemOverviewPC");
    systems = dpNames(fwSysOverview_SYSTEM_DP + "*", "FwSystemOverviewSystem");
    managers = dpNames(fwSysOverview_SYSTEM_DP + "*", "FwSystemOverviewManager");
    
    float total = dynlen(projects) + dynlen(hosts) + dynlen(systems) + dynlen(managers);
    
           
    for(int i=1; i<=dynlen(projects); i++)
    {
      showProgressBar("Deleting project data points.", "", "", (100*i)/total );
      dpDelete(projects[i]);
    }
    delay(2);
       
    for(int i=1; i<=dynlen(hosts); i++)
    {
      showProgressBar("Deleting host data points.", "", "",(100*(i+dynlen(projects))/total) );
      dpDelete(hosts[i]);
    }
    delay(2);
    
    for(int i=1; i<=dynlen(systems); i++)
    {
      showProgressBar("Deleting system data points.", "", "", (100*(i+dynlen(projects)+dynlen(hosts))/total));
      dpDelete(systems[i]);
    }
    delay(2);
    
    for(int i=1; i<=dynlen(managers); i++)
    {
      showProgressBar("Deleting manager data points.", "", "", (100*(i+dynlen(projects)+dynlen(hosts)+dynlen(systems))/total));
      dpDelete(managers[i]);
    }
    delay(5);
    
    showProgressBar("Deleting master data points.", "", "", 99);
    if(dpExists("_mp_FwSystemOverviewManager"))
      dpDelete("_mp_FwSystemOverviewManager");    
    
    if(dpExists("_mp_FwSystemOverviewProject"))
      dpDelete("_mp_FwSystemOverviewProject");
    
  showProgressBar("Process complete.", "", "", 100);   
  closeProgressBar();
   
   
  fwSysOverview_setMonitoringDp(1);
}

bool fwSysOverview_isUpgradeRequired()
{ 
  bool required = false;
  if(dpExists("_mp_FwSystemOverviewProject") || dpExists("_mp_FwSystemOverviewManager") || !dpExists("_fwFMCDim_ipmi.alive")) 
    required = true;
  
  return required;
}

void fwSysOverview_checkAlarmConfiguration(bool &requiresUpgrade)
{ 
  dyn_string projectDps = dpNames("SystemOverview/*", "FwSystemOverviewProject");
  for(int i = 1; i <= dynlen(projectDps); i++)
  {
    bool discrete = false;
    if(dpExists(projectDps[i] + ".readings.state:_alert_hdl.._discrete_states"))
      dpGet(projectDps[i] + ".readings.state:_alert_hdl.._discrete_states", discrete);  
    
    if(!discrete)
    {
DebugN("Old alarm configuration for project: " + projectDps[i]);      
      requiresUpgrade = true;
      break;
    }
  }
  return;
}

int fwSysOverview_updateAlarmConfiguration()
{ 
  dyn_string projectDps = dpNames("*", "FwSystemOverviewProject");
  dyn_string ex;
  for(int i = 1; i <= dynlen(projectDps); i++)
  {
    bool discrete = false;
    if(dpExists(projectDps[i] + ".readings.state:_alert_hdl.._discrete_states"))
      dpGet(projectDps[i] + ".readings.state:_alert_hdl.._discrete_states", discrete);  
    
    if(!discrete)
    {
      string project;
      string host, hostDp;
      fwSysOverview_getProjectDb(projectDps[i], project, ex);
      fwSysOverview_getProjectPc(projectDps[i], hostDp, ex);
      fwSysOverview_getHostDb(hostDp, host, ex);
      if(dynlen(ex)){fwExceptionHandling_display(ex);continue;}      
DebugN("Updating alarm information for project: " + project + " in host: " + host);

      fwSysOverview_setProjectAlert(project, host, true, ex);
      if(dynlen(ex)){fwExceptionHandling_display(ex);continue;}      
      dyn_string managerDps = fwSysOverview_getProjectManagerDPs(projectDps[i]);
      for(int j = 1; j <= dynlen(managerDps); j++)
        fwSysOverview_setManagerAlert(managerDps[j], true, ex);
    }
  }
  
  if(dynlen(ex)) return -1;
  
  return 0;
}

void fwSysOverview_activateProjectAlert(string projectDpName, bool activate, dyn_string &exceptionInfo)
{    
  dyn_string managersDps;
 
  _fwAlertConfig_activateOrDeactivate(makeDynString(projectDpName + fwSysOverview_STATE), activate, exceptionInfo);
  if(dynlen(exceptionInfo)){return;}
      
//  managersDps = dpNames(getSystemName() + projectDpName + "/*", "FwSystemOverviewManager");
  
  managersDps = fwSysOverview_getProjectManagerDPs(projectDpName);

  if(dynlen(managersDps) >0)
  {
    for(int i=1; i<=dynlen(managersDps); i++)
    {
      _fwAlertConfig_activateOrDeactivate( managersDps[i] + fwSysOverview_STATE, activate, exceptionInfo);
      _fwAlertConfig_activateOrDeactivate( managersDps[i] + fwSysOverview_MANAGER_READINGS_STARTMODE_ALARM, activate, exceptionInfo);      
      if(dynlen(exceptionInfo)){return;}
    }
  }
  
  return;
}

void fwSysOverview_startArchivingProjectState(string dpProject, string archiveClass, dyn_string &exceptionInfo, bool archiveManagers = true)
{
  dyn_string dpManagers;
  
//  if(fwSysOverview_configExists(dpProject + fwSysOverview_STATE, "archive") == 0)
//  {
//    DebugTN("fwSysOverview_startArchivingProjectState : There is no archive config for " + dpProject + fwSysOverview_STATE);
//    return;
//  }
  
  fwSysOverview_createArchiveConfig(dpProject + fwSysOverview_STATE, archiveClass, exceptionInfo);
  if(dynlen(exceptionInfo)){return;}
  
  if(archiveManagers == true)
  {
    dpManagers = fwSysOverview_getProjectManagerDPs(dpProject);
    
    fwSysOverview_startArchivingManagersState(dpManagers, archiveClass, exceptionInfo);
    if(dynlen(exceptionInfo)){return;}
  }
}

void fwSysOverview_startArchivingManagersState(dyn_string dpManagers, string archiveClass, dyn_string &exceptionInfo)
{
//  fwArchive_startMultiple(dpManagers, exceptionInfo);
//  if(dynlen(exceptionInfo)){return;}  
  for(int i=1; i<=dynlen(dpManagers); i++)
  {
    fwSysOverview_createArchiveConfig(dpManagers[i] + fwSysOverview_STATE, archiveClass, exceptionInfo);
    if(dynlen(exceptionInfo)){continue;}
  }
}

void fwSysOverview_startArchivingSystemState(string dpSystem, string archiveClass, dyn_string &exceptionInfo, bool archiveProjects = true, bool archiveManagers = true)
{
  dyn_string dpProjects, dpManagers;
  
//  if(fwSysOverview_configExists(dpSystem + fwSysOverview_STATE, "archive") == 0)
//  {
//    DebugTN("fwSysOverview_startArchivingSystemState : There is no archive config for " + dpSystem + fwSysOverview_STATE);
//    return;
//  } 

  //  fwArchive_start(dpSystem + fwSysOverview_STATE, exceptionInfo);  
  fwSysOverview_createArchiveConfig(dpSystem + fwSysOverview_STATE, archiveClass, exceptionInfo);
  if(dynlen(exceptionInfo)){return;}
  
  if(archiveProjects == true)
  {
    fwSysOverview_getSystemProjects(dpSystem, dpProjects, exceptionInfo);
    if(dynlen(exceptionInfo)){return;}
    
    for(int i=1; i<=dynlen(dpProjects); i++)
    {
      fwSysOverview_startArchivingProjectState(dpProjects[i], archiveClass, exceptionInfo, archiveManagers);
      if(dynlen(exceptionInfo)){continue;}
    }
  }
}

void fwSysOverview_stopArchivingProjectState(string dpProject, dyn_string &exceptionInfo, bool archiveManagers = true)
{
  dyn_string dpManagers;
  
  if(fwSysOverview_configExists(dpProject + fwSysOverview_STATE, "archive") == false)
  {
    DebugTN("fwSysOverview_stopArchivingProjectState : There is no archive config for " + dpProject + fwSysOverview_STATE);
//    return;
  }
  else
  {
    fwArchive_stop(dpProject + fwSysOverview_STATE, exceptionInfo);
    if(dynlen(exceptionInfo)){return;}
  }
    
  if(archiveManagers == true)
  {
    dpManagers = fwSysOverview_getProjectManagerDPs(dpProject);
    
    fwSysOverview_stopArchivingManagersState(dpManagers, exceptionInfo);
    if(dynlen(exceptionInfo)){return;}
  }
}

void fwSysOverview_stopArchivingManagersState(dyn_string dpManagers, dyn_string &exceptionInfo)
{
  for(int i=1; i<=dynlen(dpManagers); i++)
  {
      dpManagers[i] = dpManagers[i] + fwSysOverview_STATE;
  }
  
  fwArchive_stopMultiple(dpManagers, exceptionInfo);
  if(dynlen(exceptionInfo)){return;}  
}

void fwSysOverview_stopArchivingSystemState(string dpSystem, dyn_string &exceptionInfo, bool archiveProjects = true, bool archiveManagers = true)
{
  dyn_string dpProjects, dpManagers;

  if(fwSysOverview_configExists(dpSystem + fwSysOverview_STATE, "archive") == false)
  {
   DebugTN("fwSysOverview_stopArchivingSystemState : There is no archive config for " + dpSystem + fwSysOverview_STATE);
//    return;
  }
  else
  {    
    fwArchive_stop(dpSystem + fwSysOverview_STATE, exceptionInfo);
    if(dynlen(exceptionInfo)){return;}
  }
  
  if(archiveProjects == true)
  {
    fwSysOverview_getSystemProjects(dpSystem, dpProjects, exceptionInfo);
    if(dynlen(exceptionInfo)){return;}
    
    for(int i=1; i<=dynlen(dpProjects); i++)
    {
      fwSysOverview_stopArchivingProjectState(dpProjects[i], exceptionInfo, archiveManagers);
      if(dynlen(exceptionInfo)){return;}
    }
  }
}

fwSysOverview_createArchiveConfig(string dpe, string archiveClassName,  dyn_string &exceptionInfo)
{
  int archiveType = DPATTR_ARCH_PROC_SIMPLESM;
  int smoothProcedure = DPATTR_COMPARE_OLD_NEW;
  float deadband = 0;
  float timeInterval = 0; 
  bool checkClass = TRUE;

//fwArchive_config(dpe, archiveClassName, archiveType, smoothProcedure, deadband, timeInterval, exceptionInfo); 
  fwArchive_set(dpe, archiveClassName, archiveType, smoothProcedure, deadband, timeInterval, exceptionInfo); 
  if(dynlen(exceptionInfo)){return;}
  
}

bool fwSysOverview_configExists(string dpe, string config)
{
  int type = false;
  
  dpGet(dpe + ":_" + config + ".._type", type);
  if(type == 0)
    return false;
  else
    return true;
}

void fwSysOverview_getAchiveClass(string &archiveClass)
{   
  if(dpExists(fwSysOverview_PARAMETRIZATION + fwSysOverview_ARCHIVE_CLASS))
    dpGet(fwSysOverview_PARAMETRIZATION + fwSysOverview_ARCHIVE_CLASS, archiveClass);
}

void fwSysOverview_isArchivingEnabled(int &enable)
{
  if(dpExists(fwSysOverview_PARAMETRIZATION + fwSysOverview_ENABLE_ARCHIVING))
    dpGet(fwSysOverview_PARAMETRIZATION + fwSysOverview_ENABLE_ARCHIVING, enable);
}

void fwSysOverview_enableDimPublishing()
{
  dyn_string projDps;
  string service_name;
  string projName, hostName, systemName;
  string hostDp;
  dyn_string exceptionInfo;
  
  if(!dpExists(fwSysOverview_DIM_CONFIG))
    fwDim_createConfig(fwSysOverview_DIM_CONFIG);

  fwSysOverview_getAllProjects(projDps);
    
  for(int i=1; i<=dynlen(projDps); i++)
  {
    fwSysOverview_getProjectDb(projDps[i], projName, exceptionInfo);
    if(dynlen(exceptionInfo)){continue;}
    fwSysOverview_getProjectPc(projDps[i], hostDp, exceptionInfo);
    if(dynlen(exceptionInfo)){continue;}
    fwSysOverview_getHostDb(hostDp, hostName, exceptionInfo);
    if(dynlen(exceptionInfo)){continue;}
    
    dpGet(projDps[i] + fwSysOverview_PROJECT_SYSTEM, systemName);
    strreplace(systemName, ":", "");
      
    service_name = fwSysOverview_DIM_PREFIX + hostName + "/" + systemName + "/" + projName;
    projDps[i] += fwSysOverview_STATE;

    fwDim_publishService(fwSysOverview_DIM_CONFIG, service_name, projDps[i], "I"); //, int save_now = 0)
  }
    
  dpSetWait(fwSysOverview_PARAMETRIZATION + fwSysOverview_ENABLE_DIM_PUBLISHING, 1);
}

void fwSysOverview_disableDimPublishing()
{
  dyn_string service_names, dp_names;
  
  fwDim_getPublishedServices(fwSysOverview_DIM_CONFIG, service_names, dp_names);
      
  for(int i=1; i<=dynlen(service_names); i++)    
    fwDim_unPublishServices(fwSysOverview_DIM_CONFIG, service_names[i]); //, int save_now = 0)
  
  dpSetWait(fwSysOverview_PARAMETRIZATION + fwSysOverview_ENABLE_DIM_PUBLISHING, 0);
}

int fwSysOverview_checkSystemSubdetector(string systemName)
{
  if(strpos(getSystemName(), "ATLGCSSYS") < 0) 
  {
    string subdetId = strtoupper(fwAtlas_getSubdetectorId(getSystemName()));
  	 string str = substr(systemName, 3, 3);
  	 if(subdetId != str)
    {
      DebugTN("Ignoring PVSS system " + systemName + " since it is not part of subdetector " + subdetId);
      return -1;
     }
  }
  else
    return -1;
}

void fwSysOverview_upgradeSystemDps(bool upgrade = false, dyn_string &exceptionInfo)
{
  dyn_string systemsDps, ds, hostDps, projectDps;
  string str;
  string hostDp, dbHost, dbSystem; //systemDp,
  string sysNum, sysParentId;
  
  if(upgrade == false)
    return;
  
  fwSysOverview_getSystemsDps(systemsDps);

  for(int i =1; i<=dynlen(systemsDps); i++)
  {
    str = systemsDps[i];
    ds = strsplit(str, "/");
    if(dynlen(ds) <= 3)
    {
      dpGet(systemsDps[i] + fwSysOverview_SYSTEM_NAME, dbSystem,
            systemsDps[i] + fwSysOverview_SYSTEM_NUMBER, sysNum,
            systemsDps[i] + fwSysOverview_SYSTEM_PARENT_ID, sysParentId
            );
      
//      fwSysOverview_getSystemHost(systemsDps[i], hostDp, exceptionInfo);
//      fwSysOverview_getHostDb(hostDp, dbHost, exceptionInfo);      
//      if(dynlen(exceptionInfo)){continue;}
      dynClear(projectDps);
      fwSysOverview_getSystemProjects_old(systemsDps[i], projectDps, exceptionInfo);
      if(dynlen(exceptionInfo)){continue;}

      dynClear(hostDps);
      for(int j=1; j<=dynlen(projectDps); j++)
      {
        fwSysOverview_getProjectPc(projectDps[j], hostDp, exceptionInfo);
        dynAppend(hostDps, hostDp);
      }
      dynUnique(hostDps);
      
      if(dynlen(hostDps) > 1)
      {
        fwException_raise(exceptionInfo,"WARNING","fwSysOverview_upgradeSystemDps -> Unable to upgrade data point for system: " + systemsDps[i] + ". Multiple host dps found:" + hostDps, "");  
        continue;
      }
      
      fwSysOverview_getHostDb(hostDp, dbHost, exceptionInfo);      
      if(dynlen(exceptionInfo)){continue;}
      
      dpDelete(systemsDps[i]);
      
      fwSysOverview_createSystemDp(dbSystem, sysNum, dbHost, exceptionInfo);
      if(dynlen(exceptionInfo)){continue;}
      
    }
  }
  
}

void fwSysOverview_getSystemHost(string systemsDp, string &hostDp, dyn_string &exceptionInfo)
{
  dyn_string ds;
  string pvssHost;
  
  ds = strsplit(systemsDp, "/");
  if(dynlen(ds) > 3)
    pvssHost = ds[3];
  else
  {
    fwException_raise(exceptionInfo,"WARNING","fwSysOverview_getSystemHost -> System Datapoint name: " + systemsDp + " is not up to date.", "");  
    return;
  }
  
  hostDp = fwSysOverview_SYSTEM_DP + pvssHost;
  
}


void fwSysOverview_checkSystemDpVersion(dyn_string &exceptionInfo)
{
  dyn_string systemsDps, ds;
  string str;
  bool upgrade = false;

  fwSysOverview_getSystemsDps(systemsDps);

  for(int i =1; i<=dynlen(systemsDps); i++)
  {
    str = systemsDps[i];
    ds = strsplit(str, "/");
    if(dynlen(ds) <= 3)
      upgrade= true;
  }

  fwSysOverview_upgradeSystemDps(upgrade, exceptionInfo);
}
//level 1 - the right to do anything
//level 2 - anything with their own applicaiton in the tree
//level 3 - limited rights on only one of the fsm trees
string fwSysOverview_getExpertPrivilege(int userLevel=0)
{
  string expertPrivilege;
  if (userLevel > 0 && fwSysOverview_getUseApplicationBasedAccessControl())
  {
    expertPrivilege = fwSysOverviewAC_getPrivilege(userLevel);
  }
  
  if (expertPrivilege == "")
  {
    dpGet(fwSysOverview_PARAMETRIZATION + fwSysOverview_EXPERT_PRIVILEGE, expertPrivilege);
  }
  return expertPrivilege;
}

/* checks whether a system with name - systemName - is connected
   This method is created to overcome the problem in which there is a hardware failure with the host
   and pmon is not responding, but the dist manager still "thinks" it is connected to the system.
   This problem happend with cs-ccr-ciet56 and cs-ccr-q2ds1*/
bool fwSysOverview_isSystemConnected(string systemName)
{
  if (systemName == getSystemName())
    return true;
  bool connected = false;
  int sysId = getSystemId(systemName);
  dyn_string projectDpNames, ex;
  if (sysId > 0)
  {
    dyn_int connectedSystemsIds;
    dpGet("_DistManager.State.SystemNums", connectedSystemsIds);
    if (dynContains(connectedSystemsIds, sysId))
    {
      // check whether the state of the project is different thatn PMON_NO_RESPONSE
      strreplace(systemName, ":", "");
      dyn_string dps = dpNames("*/" + strtoupper(systemName), "FwSystemOverviewSystem");
     
      if(dynlen(dps) > 0)
      {
         fwSysOverview_getSystemProjects(dps[1], projectDpNames, ex);
         if (dynlen(ex) == 0)
         {
           for (int i=1; i <=dynlen(projectDpNames); i++)
           {
              string projectState = fwSysOverview_getProjectState(projectDpNames[i]);
              if (projectState != fwSysOverview_getStrFromState(fwSysOverview_PMON_NO_RESPONSE))
                connected = true;
              else
              {
                DebugN("PMON doesn't respond but the system ID is still in _DistManager.State.SystemNums:" + systemName);
                break;
              }
          }
         }
         else
         {
           DebugN(ex);
           DebugN("Cannot find project dp for system " + systemName + ". Asuming that the content of _DistManager.State.SystemNums is correct and returning that the system is connected!");
           connected = true;
         }
      }
      else
      {
        DebugN("Cannot find project dp for system " + systemName + ". Asuming that the content of _DistManager.State.SystemNums is correct and returning that the system is connected!");
        connected = true;
      }
    }
  }
  return connected;  
} 


bool fwSysOverview_getUseApplicationBasedAccessControl()
{
  bool useAppBasedAC = false;
  if (dpExists(fwSysOverview_PARAMETRIZATION + fwSysOverview_USE_APP_ACCESS_CONTROL))
  {
    dpGet(fwSysOverview_PARAMETRIZATION + fwSysOverview_USE_APP_ACCESS_CONTROL, useAppBasedAC);
  }
  
  return useAppBasedAC;
}

void fwSysOverview_setUseApplicationBasedAccessControl(bool use)
{
  if (dpExists(fwSysOverview_PARAMETRIZATION + fwSysOverview_USE_APP_ACCESS_CONTROL))
  {
    dpSet(fwSysOverview_PARAMETRIZATION + fwSysOverview_USE_APP_ACCESS_CONTROL, use);
  }
}
