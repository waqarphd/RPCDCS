// fwFMCDB.ctl
// This file contains all functions required to access the FW System Configuration DB
// to recreate the application or to export the current configuration of the project to the DB
//
//@author: Fernando Varela Rodriguez
//         IT/CO BE
//

#uses "fwInstallationDB.ctl"
#uses "fwFMC/fwFMC.ctl"
#uses "fwFMC/fwFMCIpmi.ctl"
#uses "fwFMC/fwFMCLogger.ctl"
#uses "fwFMC/fwFMCTaskManager.ctl"
#uses "fwFMC/fwFMCMonitoring.ctl"

#uses "fwDIM"

int fwFMCDB_setHostProperties(string hostname, dyn_mixed hostInfo)
{
  dyn_mixed record;
  dyn_string exceptionInfo;
  string sql;
  
  string bmcip, bmcuser, bmcpwd;
  int enableIpmi, enableLogger,enableTm,enableMonitoring,enableProcesses,monitoringLevel;
  string winProcsController, ipmiName, ipmiMaster, description, location, fmcOs;
  string archiving;
  int alarms;
  
  dynClear(exceptionInfo);
  dynClear(record);  

  hostname = strtoupper(hostname);
  if(dynlen(hostInfo) >= FW_INSTALLATION_DB_HOST_BMC_IP_IDX)
    bmcip = hostInfo[FW_INSTALLATION_DB_HOST_BMC_IP_IDX];    
  
  if(dynlen(hostInfo) >= FW_INSTALLATION_DB_HOST_BMC_USER_IDX)
    bmcuser = hostInfo[FW_INSTALLATION_DB_HOST_BMC_USER_IDX];    
  
  if(dynlen(hostInfo) >= FW_INSTALLATION_DB_HOST_BMC_PWD_IDX)
    bmcpwd = hostInfo[FW_INSTALLATION_DB_HOST_BMC_PWD_IDX];    
  
  if(dynlen(hostInfo) >= FW_INSTALLATION_DB_HOST_FMC_ENABLE_IPMI_IDX)
    enableIpmi = hostInfo[FW_INSTALLATION_DB_HOST_FMC_ENABLE_IPMI_IDX]; 

  if(dynlen(hostInfo) >= FW_INSTALLATION_DB_HOST_FMC_IPMI_DEVICE_NAME_IDX)
    ipmiName = hostInfo[FW_INSTALLATION_DB_HOST_FMC_IPMI_DEVICE_NAME_IDX]; 

  if(dynlen(hostInfo) >= FW_INSTALLATION_DB_HOST_FMC_ENABLE_MONITORING_IDX)
    enableMonitoring = hostInfo[FW_INSTALLATION_DB_HOST_FMC_ENABLE_MONITORING_IDX]; 

  if(dynlen(hostInfo) >= FW_INSTALLATION_DB_HOST_FMC_MONITORING_LEVEL_IDX)
    monitoringLevel = hostInfo[FW_INSTALLATION_DB_HOST_FMC_MONITORING_LEVEL_IDX]; 

  if(dynlen(hostInfo) >= FW_INSTALLATION_DB_HOST_FMC_ENABLE_TM_IDX)
    enableTm = hostInfo[FW_INSTALLATION_DB_HOST_FMC_ENABLE_TM_IDX]; 

  if(dynlen(hostInfo) >= FW_INSTALLATION_DB_HOST_FMC_ENABLE_LOGGER_IDX)
    enableLogger = hostInfo[FW_INSTALLATION_DB_HOST_FMC_ENABLE_LOGGER_IDX]; 
  
  if(dynlen(hostInfo) >= FW_INSTALLATION_DB_HOST_FMC_ENABLE_PROCESS_IDX)
    enableProcesses = hostInfo[FW_INSTALLATION_DB_HOST_FMC_ENABLE_PROCESS_IDX]; 
  
  if(dynlen(hostInfo) >= FW_INSTALLATION_DB_HOST_FMC_WIN_PROCS_CONTROLLER_IDX)
    winProcsController = hostInfo[FW_INSTALLATION_DB_HOST_FMC_WIN_PROCS_CONTROLLER_IDX]; 
  
  if(dynlen(hostInfo) >= FW_INSTALLATION_DB_HOST_FMC_LOCATION_IDX)
    location = hostInfo[FW_INSTALLATION_DB_HOST_FMC_LOCATION_IDX]; 
  
  if(dynlen(hostInfo) >= FW_INSTALLATION_DB_HOST_DESCRIPTION_IDX)
    description = hostInfo[FW_INSTALLATION_DB_HOST_DESCRIPTION_IDX]; 
  
  if(dynlen(hostInfo) >= FW_INSTALLATION_DB_HOST_FMC_OS_IDX)
    fmcOs = hostInfo[FW_INSTALLATION_DB_HOST_FMC_OS_IDX]; 
  
  if(dynlen(hostInfo) >= FW_INSTALLATION_DB_HOST_FMC_IPMI_MASTER_IDX)
    ipmiMaster = hostInfo[FW_INSTALLATION_DB_HOST_FMC_IPMI_MASTER_IDX]; 
  
  if(dynlen(hostInfo) >= FW_INSTALLATION_DB_HOST_FMC_ALARMS_IDX)
    alarms = hostInfo[FW_INSTALLATION_DB_HOST_FMC_ALARMS_IDX]; 
  
  if(dynlen(hostInfo) >= FW_INSTALLATION_DB_HOST_FMC_ARCHIVING_IDX)
    archiving = hostInfo[FW_INSTALLATION_DB_HOST_FMC_ARCHIVING_IDX]; 

  int hostId = -1;
  
  fwInstallationDB_isPCRegistered(hostId, hostname);
  
  if(hostId == -1) //host not yet registered in the DB. Register it now!
  {
    dyn_mixed hostInfo;
    hostInfo[FW_INSTALLATION_DB_HOST_NAME_IDX] = hostname;
    
    fwInstallationDB_registerPC(hostname, hostInfo);
  }
  
  record[1] = bmcip;
  record[2] = bmcuser;
  record[3] = bmcpwd;
  record[4] = enableIpmi;
  record[5] = enableMonitoring;
  record[6] = enableProcesses;
  record[7] = enableTm;
  record[8] = enableLogger;
  record[9] = monitoringLevel;
  record[10] = ipmiName;
  record[11] = ipmiMaster;
  record[12] = location;
  record[13] = description;
  record[14] = winProcsController;
  record[15] = fmcOs;
  record[16] = alarms;
  record[17] = archiving;
  record[18] = hostname;
  
  sql = "UPDATE fw_sys_stat_computer SET bmc_ip = :1, bmc_user = :2, bmc_pwd = :3, " + 
        "fmc_enable_ipmi = :4, fmc_enable_monitoring = :5, fmc_enable_process_monitoring = :6, fmc_enable_tm = :7, fmc_enable_logger = :8, " + 
        "fmc_monitoring_level = :9, bmc_name = :10, fmc_ipmi_master = :11, location = :12, description = :13, " + 
        "fmc_win_procs_controller = :14, fmc_os = :15, fmc_enable_alarms = :16, fmc_enable_archiving=:17 " + 
        "WHERE hostname = :18 and valid_until is null";
//DebugN(sql, record);     
  if(fwInstallationDB_execute(sql, record)) {fwInstallation_throw("ERROR: fwFMCDB_setHostProperties() -> Could not execute the following SQL: " + sql); return -1;};

  return 0;
}

int fwFMCDB_registerGroups(string host, dyn_string groups)
{
  string sql;
  dyn_mixed record;
  int hostId = -1;

  strreplace(host, " ", "");  
  fwInstallationDB_isPCRegistered(hostId, host);
  
  if(hostId < 1)
  {
    //Host not yet registered, try to register it now:
    fwInstallation_throw("ERROR: fwFMCDB_registerGroups() -> Host: " + host + " not regitered in DB. Failed to register FMC groups."); 
    return -1;
  }
  
  record[1] = hostId;
  for(int i = 1; i <= dynlen(groups); i++)
  {  
    record[2] = groups[i];
    sql = "INSERT INTO FW_SYS_STAT_FMC_GROUP(COMPUTER_ID, NAME) VALUES(:1, :2)";
    if(fwInstallationDB_execute(sql, record)) {fwInstallation_throw("ERROR: fwFMCDB_registerGroups() -> Could not execute the following SQL: " + sql); return -1;};
  }
  
  return 0;
}

int fwFMCDB_getHostGroups(string hostname, dyn_string &groups)
{
  dyn_string exceptionInfo;
  string sql;
  dyn_dyn_mixed aRecords;
  
  dynClear(exceptionInfo);
  dynClear(aRecords);  

  hostname = strtoupper(hostname);

  dyn_mixed var;
  var[1] = hostname;  
  
  sql = "SELECT name FROM FW_SYS_STAT_FMC_GROUP where computer_id = (select id from fw_sys_stat_computer where valid_until is null and hostname = :1)";
       
  if(g_fwInstallationSqlDebug)
    DebugN(sql);

//  if(fwInstallationDB_executeDBQuery(sql, aRecords) != 0)
  if(fwInstallationDB_executeQuery(sql, var, aRecords))
  {
    fwInstallation_throw("ERROR: fwFMCDB_getHostGroups() -> Could not execute the following SQL query: " + sql);
    return -1;
  }
  
  if(dynlen(aRecords) > 0) {   
    groups = aRecords[1];
  }
  
  return 0;
}
int fwFMCDB_unregisterAllGroups(string host, dyn_string groups)
{
  string sql;
  dyn_mixed record;
  record[1] = host;
  
  sql = "DELETE FW_SYS_STAT_FMC_GROUP WHERE COMPUTER_ID = (SELECT ID FROM FW_SYS_STAT_COMPUTER WHERE HOSTNAME = :1 AND VALID_UNTIL IS NULL)";
         
  if(fwInstallationDB_execute(sql, record)) {fwInstallation_throw("ERROR: fwFMCDB_unregisterAllGroups() -> Could not execute the following SQL: " + sql); return -1;};
  
  return 0;    
}

