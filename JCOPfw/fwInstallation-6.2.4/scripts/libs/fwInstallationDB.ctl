// $License: NOLICENSE 
int queries;

/**@file
 *
 * This library contains all functions that serve as interface between the installation tool
 * and a external Oracle DB. The functions in these library are not intended to be called 
 * from user scripts
 *
 * @author Fernando Varela Rodriguez (IT-CO/BE)
 * @version 3.3.10
 * @date   April 2007
 */
#uses "fwInstallation.ctl"
#uses "CtrlRDBAccess"
#uses "fwInstallationDbCache.ctl"

/** Version of this library.
 * Used to determine the coherency of all libraries of the installtion tool
 * @ingroup Constants
*/
const string csFwInstallationDBLibVersion = "6.2.4";

/**
 * @name fwInstallation.ctl: Definition of variables

   The following variables are used by the fwInstallationManager.ctl library

 * @{
 */
//Table and view names used in this version of the DB Schema:
const string FW_INSTALLATION_SCHEMA_TBL = "FW_SYS_STAT_SCHEMA";

// Required schema version:
const string FW_INSTALLATION_DB_REQUIRED_SCHEMA_VERSION = "4.1.6";

//Note: the following indices are not defined as const since 
//      PVSS does not support to pass a const variable to the tree widget.

//System description when passed as a dyn_mixed:
const int FW_INSTALLATION_DB_SYSTEM_NAME = 1;
const int FW_INSTALLATION_DB_SYSTEM_NUMBER = 2;
const int FW_INSTALLATION_DB_SYSTEM_DATA_PORT = 3;
const int FW_INSTALLATION_DB_SYSTEM_EVENT_PORT = 4;
const int FW_INSTALLATION_DB_SYSTEM_DIST_PORT = 5;
const int FW_INSTALLATION_DB_SYSTEM_PARENT_SYS_ID = 6;
const int FW_INSTALLATION_DB_SYSTEM_COMPUTER = 7;
const int FW_INSTALLATION_DB_SYSTEM_REDU_PORT = 8;  
const int FW_INSTALLATION_DB_SYSTEM_SPLIT_PORT = 9;
const int FW_INSTALLATION_DB_SYSTEM_PROJECT = 10;
const int FW_INSTALLATION_DB_SYSTEM_IDX = 11;       
const int FW_INSTALLATION_DB_SYSTEM_REDU_HOST = 12;  
//const int FW_INSTALLATION_DB_SYSTEM_REDU_COMPUTER = 9;

//Hierarchy of PVSS systems  passed as a dyn_dyn_mixed:
int FW_INSTALLATION_DB_SYSTEM_ID_IDX = 3;
int FW_INSTALLATION_DB_SYSTEM_PARENT_ID_IDX = 4;

//Projects info:
const int FW_INSTALLATION_DB_PROJECT_NAME = 1;
const int FW_INSTALLATION_DB_PROJECT_HOST = 2;
const int FW_INSTALLATION_DB_PROJECT_DIR = 3;
const int FW_INSTALLATION_DB_PROJECT_SYSTEM_NAME = 4;
const int FW_INSTALLATION_DB_PROJECT_SYSTEM_NUMBER = 5;
const int FW_INSTALLATION_DB_PROJECT_PMON_PORT = 6;
const int FW_INSTALLATION_DB_PROJECT_PMON_USER = 7;
const int FW_INSTALLATION_DB_PROJECT_PMON_PWD = 8;
const int FW_INSTALLATION_DB_PROJECT_TOOL_VER = 9;
const int FW_INSTALLATION_DB_PROJECT_CENTRALLY_MANAGED = 10;
const int FW_INSTALLATION_DB_PROJECT_PVSS_VER = 11;
const int FW_INSTALLATION_DB_PROJECT_DATA = 12;
const int FW_INSTALLATION_DB_PROJECT_EVENT = 13;
const int FW_INSTALLATION_DB_PROJECT_DIST = 14;
const int FW_INSTALLATION_DB_PROJECT_OS = 15;
const int FW_INSTALLATION_DB_PROJECT_PROJECT_OK = 16;
const int FW_INSTALLATION_DB_PROJECT_PVSS_OK = 17;
const int FW_INSTALLATION_DB_PROJECT_HOST_OK = 18;
const int FW_INSTALLATION_DB_PROJECT_PATH_OK = 19;
const int FW_INSTALLATION_DB_PROJECT_MANAGER_OK = 20;
const int FW_INSTALLATION_DB_PROJECT_GROUP_OK = 21;
const int FW_INSTALLATION_DB_PROJECT_COMPONENT_OK = 22;
const int FW_INSTALLATION_DB_PROJECT_EXT_PROCESS_OK = 23;
const int FW_INSTALLATION_DB_PROJECT_LAST_CHECK = 24;
const int FW_INSTALLATION_DB_PROJECT_SYSTEM_OVERVIEW = 25;
const int FW_INSTALLATION_DB_PROJECT_UPGRADE = 26;
const int FW_INSTALLATION_DB_PROJECT_REDU_HOST = 27;
const int FW_INSTALLATION_DB_PROJECT_SYSTEM_COMPUTER = 28;
const int FW_INSTALLATION_DB_PROJECT_DELETE_FILES = 29;
const int FW_INSTALLATION_DB_PROJECT_TOOL_STATUS = 30;
const int FW_INSTALLATION_DB_PROJECT_REDU_PORT = 31;
const int FW_INSTALLATION_DB_PROJECT_SPLIT_PORT = 32;
 
// Windows - Linux PATH Mapping
const int FW_INSTALLATION_DB_WINDOWS_PATH = 1;
const int FW_INSTALLATION_DB_LINUX_PATH   = 2;

//Debugging options:
global bool g_fwInstallationSqlDebug = false;
global bool g_fwInstallationVerbose = false;
////////////////////////////////////////////////////////////////////////////////////////////

//DB Connection using RDBAccess.ctl
global dbConnection gFwInstallationDBConn;
  
string FW_INSTALLATION_DB_CONNECTION_NAME = "fwInstallationToolConnection";

//Managers info:

const int FW_INSTALLATION_DB_MANAGER_NAME_IDX = 1;
const int FW_INSTALLATION_DB_MANAGER_START_IDX = 2;
const int FW_INSTALLATION_DB_MANAGER_RESTART_IDX = 3;
const int FW_INSTALLATION_DB_MANAGER_RESETMIN_IDX = 4;
const int FW_INSTALLATION_DB_MANAGER_SECKILL_IDX = 5;
const int FW_INSTALLATION_DB_MANAGER_OPTIONS_IDX = 6;
const int FW_INSTALLATION_DB_MANAGER_TRIGGERS_ALERTS_IDX = 7;

//Manager type info:

const int FW_INSTALLATION_DB_MANAGER_TYPE_NAME_IDX = 1;
const int FW_INSTALLATION_DB_MANAGER_TYPE_DESCRIPTION_IDX = 2; 
const int FW_INSTALLATION_DB_MANAGER_TYPE_GROUP_IDX = 3;
////
//Flags handled in the panels and functions to see what has to be exported to the DB:
const int FW_INSTALLATION_DB_COMPUTER_FLAG_IDX = 1;
const int FW_INSTALLATION_DB_PVSS_FLAG_IDX = 2;
const int FW_INSTALLATION_DB_PROJECT_FLAG_IDX = 3;
const int FW_INSTALLATION_DB_MANAGERS_FLAG_IDX = 4;
const int FW_INSTALLATION_DB_FW_COMPONENTS_FLAG_IDX = 5;
const int FW_INSTALLATION_DB_EXTERNAL_PROCESSES_FLAG_IDX = 6;
const int FW_INSTALLATION_DB_DIST_PEERS_FLAG_IDX = 7;

//FW Components
const int FW_INSTALLATION_DB_COMPONENT_NAME_IDX = 1;
const int FW_INSTALLATION_DB_COMPONENT_VERSION_IDX = 2;
const int FW_INSTALLATION_DB_COMPONENT_SUBCOMP_IDX = 3;
const int FW_INSTALLATION_DB_COMPONENT_DESC_FILE_IDX = 4;
const int FW_INSTALLATION_DB_COMPONENT_INSTALLATION_NOT_OK_IDX = 5;
const int FW_INSTALLATION_DB_COMPONENT_DEPENDENCIES_OK_IDX = 6;
const int FW_INSTALLATION_DB_COMPONENT_PENDING_POSTINSTALLS_IDX = 7;
const int FW_INSTALLATION_DB_COMPONENT_RESTART_IDX = 8;

//External Processes info:

const int FW_INSTALLATION_DB_EXT_PROCESS_NAME_IDX = 1;
const int FW_INSTALLATION_DB_EXT_PROCESS_PATH_IDX  = 2;
const int FW_INSTALLATION_DB_EXT_PROCESS_OPTIONS_IDX = 3; 

//projectSystemHostInfo
const int FW_INSTALLATION_DB_PROJ_SYS_HOST_PROJ = 1;
const int FW_INSTALLATION_DB_PROJ_SYS_HOST_SYS_NAME = 2;
const int FW_INSTALLATION_DB_PROJ_SYS_HOST_SYS_NUMBER = 3;
const int FW_INSTALLATION_DB_PROJ_SYS_HOST_DISTPORT = 4;
const int FW_INSTALLATION_DB_PROJ_SYS_HOST_HOST = 5;

//Project components thru a DB view
const int FW_INSTALLATION_DB_PROJ_COMP_NAME_IDX = 1;
const int FW_INSTALLATION_DB_PROJ_COMP_VERSION_IDX = 2;
const int FW_INSTALLATION_DB_PROJ_COMP_IS_SUBCOMP_IDX = 3;
const int FW_INSTALLATION_DB_PROJ_COMP_DESCFILE_IDX = 4;
const int FW_INSTALLATION_DB_PROJ_COMP_OVERWRITE_IDX = 5;
const int FW_INSTALLATION_DB_PROJ_COMP_FORCE_IDX = 6;
const int FW_INSTALLATION_DB_PROJ_COMP_IS_SILENT_IDX = 7;
const int FW_INSTALLATION_DB_PROJ_COMP_IS_PATCH_IDX = 8;
const int FW_INSTALLATION_DB_PROJ_COMP_RESTART_PROJECT_IDX = 9;

//PVSS Info:
const int FW_INSTALLATION_DB_PVSS_INFO_VERSION_IDX = 1;
const int FW_INSTALLATION_DB_PVSS_INFO_OS_IDX = 2;
const int FW_INSTALLATION_DB_PVSS_INFO_PATCHES_IDX = 3;

//Host info:
const int FW_INSTALLATION_DB_HOST_NAME_IDX = 1;
const int FW_INSTALLATION_DB_HOST_IP_1_IDX = 2;
const int FW_INSTALLATION_DB_HOST_MAC_1_IDX = 3;
const int FW_INSTALLATION_DB_HOST_IP_2_IDX = 4;
const int FW_INSTALLATION_DB_HOST_MAC_2_IDX = 5;
const int FW_INSTALLATION_DB_HOST_BMC_IP_IDX = 6;
const int FW_INSTALLATION_DB_HOST_BMC_USER_IDX = 7;
const int FW_INSTALLATION_DB_HOST_BMC_PWD_IDX = 8;
const int FW_INSTALLATION_DB_HOST_FMC_ENABLE_IPMI_IDX = 9;
const int FW_INSTALLATION_DB_HOST_FMC_IPMI_DEVICE_NAME_IDX = 10;
const int FW_INSTALLATION_DB_HOST_FMC_ENABLE_MONITORING_IDX = 11;
const int FW_INSTALLATION_DB_HOST_FMC_MONITORING_LEVEL_IDX = 12;
const int FW_INSTALLATION_DB_HOST_FMC_ENABLE_TM_IDX = 13;
const int FW_INSTALLATION_DB_HOST_FMC_ENABLE_LOGGER_IDX = 14;
const int FW_INSTALLATION_DB_HOST_DB_IDX = 15;
const int FW_INSTALLATION_DB_HOST_FMC_ENABLE_PROCESS_IDX = 16;
const int FW_INSTALLATION_DB_HOST_FMC_WIN_PROCS_CONTROLLER_IDX = 17;
const int FW_INSTALLATION_DB_HOST_FMC_LOCATION_IDX = 18;
const int FW_INSTALLATION_DB_HOST_DESCRIPTION_IDX = 19;
const int FW_INSTALLATION_DB_HOST_FMC_OS_IDX = 20;
const int FW_INSTALLATION_DB_HOST_FMC_IPMI_MASTER_IDX = 21;
const int FW_INSTALLATION_DB_HOST_FMC_ARCHIVING_IDX = 22;
const int FW_INSTALLATION_DB_HOST_FMC_ALARMS_IDX = 23;

//Components incorrectly installed:
const int FW_INSTALLATION_DB_COMP_BAD_HOST = 1;
const int FW_INSTALLATION_DB_COMP_BAD_PROJECT = 2;
const int FW_INSTALLATION_DB_COMP_BAD_NAME = 3;
const int FW_INSTALLATION_DB_COMP_BAD_VERSION = 4;

//CtrlRDBAccess DB Connection timeout:
const int FW_INSTALLATION_DB_CONNECTION_TIMEOUT = 600;

//MAX SIZE OF INSTALLATION LOGS:
const int FW_INSTALLATION_DB_MAX_LOG_SIZE = 1000;

//@} // end of constants

//Configuration of fwInstallationDB
int fwInstallationDB_getProjectPvssInfo(string project, string hostname, dyn_mixed &dbPvssInfo)
{
  dyn_mixed projectInfo;
  int projectId;  
  if(fwInstallationDB_getProjectProperties(project, hostname, projectInfo, projectId))
    return -1;
  
  if(dynlen(projectInfo) > 1)
  {
    dbPvssInfo[1] = projectInfo[FW_INSTALLATION_DB_PROJECT_PVSS_VER];
    dbPvssInfo[2] = projectInfo[FW_INSTALLATION_DB_PROJECT_OS];
  }
  
  return 0;
}


//Cache related interface 
int fwInstallationDB_initializeCache() {
  fwInstallationDBCache_initialize();
  return 0;
}

//@ // end of configuration


///Beginning of executable code:
int fwInstallationDB_storeInstallationLog()
{
  if(dynlen(gFwInstallationLog) == 0)
    return 0;
    
  int projectId;
  if(fwInstallationDB_isProjectRegistered(projectId))
  {
    fwInstallation_throw("fwInstallationDB_storeInstallationLog()->Error retriving the project info from the DB");
    return -1;
  }  
  
  if(projectId == -1) //Project not yet registered in the DB
  {
    return 0;
  }
  
  for(int i=1 ; i <= dynlen(gFwInstallationLog) ; i++) {
    dyn_string log_line = gFwInstallationLog[i];
    string ts = log_line[1];
    string severity = substr(log_line[2], 0, 10);
    string msg = substr(log_line[3], 0, 4000);
    
    dyn_mixed var;
    var[1] = projectId;
    var[2] = ts;
    var[3] = severity;
    var[4] = msg;
    string sql = "INSERT INTO FW_SYS_STAT_PROJ_INST_LOG(ID, PROJECT_ID, TS, SEVERITY, LOG) VALUES(FW_SYS_STAT_PROJ_INST_LOG_SQ.NEXTVAL, :1, TO_TIMESTAMP(:2, 'YYYY.MM.DD HH24:MI:SS.FF3'), :3, :4)";
    if(fwInstallationDB_execute(sql, var, false)) {fwInstallation_throw("fwInstallationDB_storeInstallationLog() -> Could not execute the following SQL: " + sql); DebugN(sql, var); gFwInstallationLog = makeDynString(); return -1;};
  }
  gFwInstallationLog = makeDynString();

  return 0;  
}

int fwInstallationDB_deleteInstallationLog(int hoursAgo=0, string project = "", string host = "")
{
  if(host == "")
    host = strtoupper(fwInstallation_getHostname());  
  
  if(project == "")
    project = PROJ; 
  
  int projectId;
  if(fwInstallationDB_isProjectRegistered(projectId, project, host))
  {
    fwInstallation_throw("fwInstallationDB_deleteInstallationLog()->Error retriving the project info from the DB");
    return -1;
  }  
  
  if(projectId == -1) return 0;  
  
  dyn_mixed var;
  var[1] = projectId;
  var[2] = hoursAgo;
  string sql = "DELETE FW_SYS_STAT_PROJ_INST_LOG WHERE PROJECT_ID = :1 AND TS <= SYSDATE-:2/24";
  if(fwInstallationDB_execute(sql, var, false)) {fwInstallation_throw("fwInstallationDB_deleteInstallationLog() -> Could not execute the following SQL: " + sql); return -1;};

  return 0;  
}

bool fwInstallationDB_maxLogSizeExceeded(string project = "", string host = "")
{
  if(host == "")
    host = strtoupper(fwInstallation_getHostname());  
  
  if(project == "")
    project = PROJ;  
  
  int projectId;
  if(fwInstallationDB_isProjectRegistered(projectId, project, host))
  {
    fwInstallation_throw("fwInstallationDB_maxLogSizeExceeded()->Error retriving the project info from the DB");
    return false;
  } 

  if(projectId == -1) return false;  
  
  dyn_mixed var;
  var[1] = projectId;
  string sql = "SELECT COUNT(*) FROM FW_SYS_STAT_PROJ_INST_LOG WHERE PROJECT_ID = :1";
  dyn_dyn_mixed record;
  if(fwInstallationDB_executeQuery(sql, var, record)) {fwInstallation_throw("fwInstallationDB_maxLogSizeExceeded() -> Could not execute the following SQL: " + sql); return false;};

  if(dynlen(record) && ((int) record[1][1] >= FW_INSTALLATION_DB_MAX_LOG_SIZE))
  {
    return true;
  }
  
  return false;  
}

int fwInstallationDB_getInstallationLog(dyn_dyn_string &logs, string project = "", string host = "")
{
  //GetCache1
  dyn_string parameters = makeDynString(project, host);
  if( fwInstallationDBCache_getCache("_getInstallationLog", parameters, logs) == 0 ) {
  	return 0;
  }
  //EndGetCache1

  if(host == "")
    host = strtoupper(fwInstallation_getHostname());  
  
  if(project == "")
    project = PROJ;  
  
  int projectId;
  if(fwInstallationDB_isProjectRegistered(projectId, project, host))
  {
    fwInstallation_throw("fwInstallationDB_getInstallationLog()->Error retriving the project info from the DB");
    return -1;
  } 

  if(projectId == -1) return 0;  
  
  dyn_mixed var;
  var[1] = projectId;
  string sql = "SELECT TO_CHAR(TS), SEVERITY, LOG FROM FW_SYS_STAT_PROJ_INST_LOG WHERE PROJECT_ID = :1 ORDER BY TS";
  dyn_dyn_mixed record;
  if(fwInstallationDB_executeQuery(sql, var, record)) {fwInstallation_throw("fwInstallationDB_getInstallationLog() -> Could not execute the following SQL: " + sql); return -1;};
  
  if(dynlen(record))
  {
    logs = record;
  }
  
  //SetCache1
  if( fwInstallationDBCache_setCache("_getInstallationLog", parameters, logs) == 0 ) {
  }
  //EndSetCache

  return 0;  
}

/** This function tell if we are correctly connected to the DB or not.
  @return TRUE if connected. FALSE if not connected.
*/
bool fwInstallationDB_isConnected()
{
  mixed retval;
  int state = rdbOption("Inspect", gFwInstallationDBConn, retval);
  
  return (state == 0);
}

/** This function prints the versions of the libraries in the current distribution
  @return 0
*/
int fwInstallationDB_printLibVersions()
{
 DebugN("fwInstallation.ctl v." + csFwInstallationLibVersion); 
 DebugN("fwInstallationDB.ctl v." + csFwInstallationDBLibVersion); 
 DebugN("fwInstallationDBAgent.ctl v." + csFwInstallationDBAgentLibVersion); 
 
 return 0; 
}

/** This function sets the idle DB connection timeout to the default value
  @return 0 if OK, -1 if error
*/
int fwInstallationDB_setConnectionTimeout()
{
  mixed data;
  int val = FW_INSTALLATION_DB_CONNECTION_TIMEOUT;
  int to = 0;

  if(VERSION != "3.6")
  {
    if(rdbOption("GetConnectionTimeout", 0, data))
    {
      fwInstallation_throw("fwInstallationDB_setConnectionTimeout()->Error retriving the current value of the DB connection timeout");
      return -1;
    }
    to = data;
  }
  
  
  if(to == FW_INSTALLATION_DB_CONNECTION_TIMEOUT)
  {
    return 0; //Nothing to be done as the value of the timeout is the desired one
  }
  
  if(rdbOption("SetConnectionTimeout", val, data))
  {
    fwInstallation_throw("fwInstallationDB_setConnectionTimeout()->Failed to set DB connection timeout to " + FW_INSTALLATION_DB_CONNECTION_TIMEOUT);
    return -1;
  }
//  fwInstallation_throw("DB connection timeout successfully set to " + FW_INSTALLATION_DB_CONNECTION_TIMEOUT + "s", "INFO", 10);
  return 0;
}

//Transactions:
/** This function initiates a DB transaction
  @return 0 if OK, -1 if error
*/
int fwInstallationDB_beginTransaction()
{
  string errTxt;

  rdbBeginTransaction(gFwInstallationDBConn);
  if (rdbCheckError(errTxt,gFwInstallationDBConn))
  {
    fwInstallation_throw("DB TRANSACTION ERROR",errTxt);
    return -1;
  }
  return 0;
}

/** This function executes a DB transaction
  (Deprecated? orphan method in fwi6.0.2) 
  @param sql (in) sql sentence to be executed
  @return 0 if OK, -1 if error
*/
int fwInstallationDB_executeTransaction(string sql)
{
  //The command may change things on the database, we will want the cache to be reloaded
//  fwInstallationDBCache_clear();

  string errTxt;

   rdbExecuteSqlStatement (gFwInstallationDBConn, sql);
   if (rdbCheckError(errTxt, gFwInstallationDBConn))
   {
     fwInstallation_throw("DB ERROR",errTxt);
     rdbRollbackTransaction(gFwInstallationDBConn);
     return -1;
   }
   return 0;
}

/** This function rolls back a DB transaction
  @return 0 if OK, -1 if error
*/
int fwInstallationDB_rollbackTransaction()
{
  string errTxt;  
  
  rdbRollbackTransaction(gFwInstallationDBConn);
  if (rdbCheckError(errTxt, gFwInstallationDBConn))
  {
     fwInstallation_throw("DB ERROR", errTxt);
     rdbRollbackTransaction(gFwInstallationDBConn);
     return -1;
  }
  return 0;
}

/** This function commits a DB transaction
  @return 0 if OK, -1 if error
*/
int fwInstallationDB_commitTransaction()
{
  string errTxt;  
  
  rdbCommitTransaction(gFwInstallationDBConn);
  if (rdbCheckError(errTxt, gFwInstallationDBConn))
  {
     fwInstallation_throw("DB TRANSACTION ERROR", errTxt);
     rdbRollbackTransaction(gFwInstallationDBConn);
     return -1;
  }
  return 0;
}

/** This function executes a SQL instruction
  @param sql (in) sql sentence to be executed
  @param record (in) bind variables as a dyn_mixed
  @return 0 if OK, -1 if error
*/
int fwInstallationDB_execute(string sql, dyn_mixed record, bool clearCache = true)
{
 
  dbCommand cmd;
  string errTxt;

  //The command will likely change things on the database, we will want the cache to be reloaded
//  fwInstallationDBCache_clear();
  if(clearCache)
    fwInstallationDBCache_clear();

  rdbStartCommand(FW_INSTALLATION_DB_CONNECTION_NAME, sql, cmd);
  if (rdbCheckError(errTxt,cmd)){fwInstallation_throw("fwInstallationDB_execute() -> DB Error: " + errTxt);return -1;};

  rdbBindParams(cmd, record);
  if (rdbCheckError(errTxt,cmd)){fwInstallation_throw("fwInstallationDB_execute() -> DB Error: " +errTxt);return -1;};

  rdbExecuteCommand(cmd);
  if (rdbCheckError(errTxt,cmd)){fwInstallation_throw("fwInstallationDB_execute() -> DB Error: "+errTxt);return -1;};

  rdbFinishCommand(cmd);
  // note that we do not put the second parameter here!
  if (rdbCheckError(errTxt)){fwInstallation_throw("fwInstallationDB_execute() -> DB Error: "+errTxt);return -1;};
  
  return 0;
}


/** This function executes a SQL query
  @param sql (in) sql sentence to be executed
  @param record (in) bind variables as a dyn_mixed
  @param data (out) result of the query as a dyn_dyn_mixed
  @return 0 if OK, -1 if error
*/
int fwInstallationDB_executeQuery(string sql, dyn_mixed record, dyn_dyn_mixed &data)
{
  dbCommand cmd;
  string errTxt;
  rdbStartCommand(FW_INSTALLATION_DB_CONNECTION_NAME, sql, cmd);
  if (rdbCheckError(errTxt, gFwInstallationDBConn)){fwInstallation_throw("fwInstallationDB_executeQuery() -> DB Error: "+errTxt + + sql); /*rdbFinishCommand(cmd);*/ return -1;};

  rdbBindParams(cmd, record);
  if (rdbCheckError(errTxt, cmd)){fwInstallation_throw("fwInstallationDB_executeQuery() -> DB Error: "+errTxt + +sql); rdbFinishCommand(cmd); return -1;};

  rdbExecuteCommand(cmd);
  if (rdbCheckError(errTxt, cmd)){fwInstallation_throw("fwInstallationDB_executeQuery() -> DB Error: " + errTxt + + sql); rdbFinishCommand(cmd); return -1;};
   
  rdbGetData(cmd, data);
  if (rdbCheckError(errTxt, cmd)){fwInstallation_throw("fwInstallationDB_executeQuery() -> DB ERROR" +errTxt+" "+sql); rdbFinishCommand(cmd); return -1;};
  
  rdbFinishCommand(cmd);
  // note that we do not put the second parameter here!
  if (rdbCheckError(errTxt)){fwInstallation_throw("fwInstallationDB_executeQuery() -> DB Error: "+ errTxt + " " + sql);return -1;};

++queries;  
  return 0;
}

/** This function registers in the database a component for reinstallation in a project
  @param host name of the host where the project runs
  @param project name of the project where the compnent has to be reinstalled
  @param component name of the component to be reinstalled
  @param version version of the component
  @param descFile Component description XML file
  @param restartProject flag indicating whether the project has to be restarted after reinstallation
  @param overwriteFiles flag indicating if the component files have to be restarted
  @return 0 if OK, -1 if error
*/
int fwInstallationDB_registerReinstallation(string host, 
                                              string project, 
                                              string component,
                                              string version, 
                                              string descFile, 
                                              int restartProject, 
                                              int overwriteFiles)
{
  string sql;
  int component_id = -1;
  int project_id = -1;
  int reinstallation_id = -1;
  
  dyn_string exceptionInfo;
  dyn_dyn_mixed aRecords;

  dynClear(exceptionInfo);

  //Check if component is registered:
  if(fwInstallationDB_isComponentRegistered(component, version, component_id) != 0)
  {
    fwInstallation_throw("fwInstallationDB_registerReinstallation() -> Could not check if component: "+component+" v." + version + " is registered in DB. Check DB connection parameters.");
    return -1;
  }
  else if(component_id == -1)
  {
     fwInstallation_throw("Component " + component + " v." + version + " not yet registered in the DB.");
     return -1;  
  }

  //Check if project is registered:
  if(fwInstallationDB_isProjectRegistered(project_id, project, host) != 0)
  {
    fwInstallation_throw("fwInstallationDB_registerReinstallation() -> Could not check if project: " + project + " in host: " + host + " is registered in DB. Check DB connection parameters.");
    return -1;
  }
  else if(project_id == -1)
  {
     fwInstallation_throw("fwInstallationDB_registerReinstallation() -> Project " + project + " in host: " + host + " not yet registered in the DB.");
     return -1;  
  }

  //Check if reinstallation is already registered:
  if(fwInstallationDB_isReinstallationRegistered(project_id, component_id, reinstallation_id) != 0)
  {
    fwInstallation_throw("fwInstallationDB_registerReinstallation() -> Could not check if resintallation of component: " + component + " v." + version + " is registered in DB. Check DB connection parameters.");
    return -1;
  }
  else if(reinstallation_id != -1)
  {
    //reinstallation still pending. Nothing to be done.
     return 0;  
  }
  
  dyn_mixed record;
  record[1] = project_id;
  record[2] = component_id;
  record[3] = descFile;
  record[4] = restartProject;
  record[5] = overwriteFiles;
    
  sql = "INSERT INTO FW_SYS_STAT_FORCE_REINSTALL(ID, PROJECT_ID, COMPONENT_ID, DESC_FILE, RESTART_REQUIRED, OVERWRITE_FILES) " + 
        "VALUES(FW_SYS_STAT_REINSTALL_SQ.NEXTVAL, :1, :2, :3, :4, :5)";
         
  if(fwInstallationDB_execute(sql, record, false)) {fwInstallation_throw("fwInstallationDB_registerReinstallation() -> Could not execute the following SQL: " + sql); return -1;};

  return 0;  
}
/** This function unregisters from the database all component reinstallations for a given project
  @param host name of the host where the project runs
  @param project name of the project
  @return 0 if OK, -1 if error
*/
int fwInstallationDB_unregisterProjectReinstallations(string host, string project)
{
  string sql;
  int project_id = -1;
  
  dyn_string exceptionInfo;
  dyn_dyn_mixed aRecords;

  dynClear(exceptionInfo);

  //Check if project is registered:
  if(fwInstallationDB_isProjectRegistered(project_id, project, host) != 0)
  {
    fwInstallation_throw("fwInstallationDB_unregisterProjectReinstallations() -> Could not check if project: "+project+" in host: " + host + " is registered in DB. Check DB connection parameters.");
    return -1;
  }
  else if(project_id == -1)
  {
     fwInstallation_throw("fwInstallationDB_unregisterProjectReinstallations() -> Project "+project+" in host: " + host + " not yet registered in the DB.");
     return -1;  
  }

  dyn_mixed record;
  record[1] = project_id;
    sql = "UPDATE FW_SYS_STAT_FORCE_REINSTALL SET EXECUTED_ON = SYSDATE WHERE PROJECT_ID = :1";
         
  if(fwInstallationDB_execute(sql, record, false)) {fwInstallation_throw("fwInstallationDB_unregisterProjectReinstallations() -> Could not execute the following SQL: " + sql); return -1;};

  return 0;  
}

int fwInstallationDB_unregisterHostPvssVersion(string host, string version, string os)
{
  string sql = "delete FW_SYS_STAT_PVSS_BASE_VERSION where computer_id = (select id from fw_sys_stat_computer where hostname = :1) and pvss_version_id = (select id from fw_sys_stat_pvss_version where version_name = :2 and os = :3)";
  dyn_mixed record;
  record[1] = host;
  record[2] = version;
  record[3] = os;
  if(fwInstallationDB_execute(sql, record)) 
  {
    fwInstallation_throw("fwInstallationDB_unregisterHostPvssVersion() -> Could not execute the following SQL: " + sql); 
    return -1;
  }

  return 0;  
    
}
/** This function returns the name of the primary and secondary redundant hosts in a redu project
  @param host name of the host to be checked
  @param project name of the PVSS project
  @param primaryHost name of the host the project was initially registered for in the DB
  @param secondaryHost secondary redundant host
  @return 0 if OK, -1 if error
*/
int fwInstallationDB_getProjectReduHosts(string host, string project, string &primaryHost, string &secondaryHost)
{
  //GetCache1
  dyn_string parameters = makeDynString(host, project);
  if( fwInstallationDBCache_getCache("_getProjectReduHosts", parameters, primaryHost, "primaryHost") == 0 
  	&&  fwInstallationDBCache_getCache("_getProjectReduHosts", parameters, secondaryHost, "secondaryHost") == 0 
	) {
  	return 0;
  }
  //EndGetCache1


  dyn_string exceptionInfo;
  dyn_dyn_mixed aRecords;
  string sql;
  string reduHost;

  dynClear(aRecords);
  dyn_mixed var;
  var[1] = project;
  var[2] = host;

  fwInstallationDB_getReduPair(host, project, reduHost);
  if(reduHost == host) //Not a redu project
  {
    primaryHost = host;
    secondaryHost = "";
    return 0;
  }
  
  sql = "select computer_id "+
        "from fw_sys_stat_pvss_project " +
        "where valid_until is null and project_name = :1 and " +
        "computer_id = (select id from fw_sys_stat_computer where valid_until is null and hostname = :2)";  
  
  if(fwInstallationDB_executeQuery(sql, var, aRecords))
  {
    fwInstallation_throw("fwInstallationDB_getProjectReduHosts() -> Could not execute the following SQL query: " + sql);
    return -1;
  }  
  
  if(dynlen(aRecords) > 0) {   
    primaryHost = host;
    secondaryHost = reduHost;
  }
  else{
    primaryHost = reduHost;
    secondaryHost = host;
   
   }

   //SetCache
   dyn_string parameters = makeDynString(host, project);
  if( fwInstallationDBCache_getCache("_getProjectReduHosts", parameters, primaryHost, "primaryHost") == 0 
  	&&  fwInstallationDBCache_getCache("_getProjectReduHosts", parameters, secondaryHost, "secondaryHost") == 0 
	) {
  	return 0;
  }
   //EndSetCache

   return 0;
} 

/** This function checks if a component reinstallation has already been registered in the DB for a given project
  @param project_id DB index of the project
  @param component_id DB index of the component
  @param id DB index of the reinstallation. -1 means that the reinstallation is not yet registered in the DB
  @return 0 if OK, -1 if error
*/
int fwInstallationDB_isReinstallationRegistered(int project_id, int component_id, int &id)
{
  //GetCache1
  dyn_string parameters = makeDynString(project_id, component_id);
  if( fwInstallationDBCache_getCache("_isReinstallationRegistered", parameters, id) == 0 ) {
  	return 0;
  }
  //EndGetCache1


  dyn_string exceptionInfo;
  dyn_dyn_mixed aRecords;
  string sql;

  dynClear(aRecords);
  dyn_mixed var;
  var[1] = component_id;
  var[2] = project_id;
  
  sql = "SELECT id FROM fw_sys_stat_force_reinstall WHERE component_id = :1 AND project_id = :2 AND executed_on IS NULL";
  
  if(fwInstallationDB_executeQuery(sql, var, aRecords))
  {
    fwInstallation_throw("fwInstallationDB_isReinstallationRegistered() -> Could not execute the following SQL query: " + sql);
    return -1;
  }  

  if(dynlen(aRecords) > 0) {   
    id = aRecords[1][1];
  }
  else{
    id = -1;
   
   }

  //SetCache1
  if( fwInstallationDBCache_setCache("_isReinstallationRegistered", parameters, id) == 0 ) {
  }
  //EndSetCache

  return 0;
} 

/** This function retrieves the list of pending reinstalaltions for a given project
  @param host name of the host where the project runs
  @param project name of the project
  @param reinstallationsInfo list of reinstallations
  @return 0 if OK, -1 if error
*/
int fwInstallationDB_getProjectPendingReinstallations(string host, string project, dyn_dyn_mixed &reinstallationsInfo)
{
  //GetCache1
  dyn_string parameters = makeDynString(host, project);
  if( fwInstallationDBCache_getCache("_getProjectPendingReinstallations", parameters, reinstallationsInfo) == 0 ) {
  	return 0;
  }
  //EndGetCache1

  int project_id;
  dyn_string exceptionInfo;
  dyn_dyn_mixed aRecords;
  string sql;

  dynClear(aRecords);
    
  //Check if project is registered:
  if(fwInstallationDB_isProjectRegistered(project_id, project, host) != 0)
  {
    fwInstallation_throw("fwInstallationDB_getProjectPendingReinstallations() -> Could not check if project: "+project+" in host: " + host + " is registered in DB. Check DB connection parameters.");
    return -1;
  }
  else if(project_id == -1)
  {
     fwInstallation_throw("fwInstallationDB_getProjectPendingReinstallations() -> Project "+project+" in host: " + host + " not yet registered in the DB.");
     return -1;  
  }
  
  dyn_mixed var;
  var[1] = project_id;
  
  sql = "select c.component_name, c.component_version, c.is_subcomponent, r.desc_file, r.restart_required, r.overwrite_files " + 
        "from fw_sys_stat_component c, fw_sys_stat_force_reinstall r " + 
        "where r.executed_on is null and c.id = r.component_id and project_id = :1";
  
  if(fwInstallationDB_executeQuery(sql, var, aRecords))
  {
    fwInstallation_throw("fwInstallationDB_isReinstallationRegistered() -> Could not execute the following SQL query: " + sql);
    return -1;
  }  

  reinstallationsInfo = aRecords;
  
  //SetCache1
  if( fwInstallationDBCache_setCache("_getProjectPendingReinstallations", parameters, reinstallationsInfo) == 0 ) {
  }
  //EndSetCache
  
  return 0;
} 

/** This function unregisters a particular component reinstallation for a given project
  @param host name of the host where the project runs
  @param project name of the project
  @param component name of the component
  @param version version of the component
  @return 0 if OK, -1 if error
*/
int fwInstallationDB_unregisterProjectReinstallation(string host, string project, string component, string version)
{
  string sql;
  int component_id = -1;
  int project_id = -1;
  
  dyn_string exceptionInfo;
  dyn_dyn_mixed aRecords;

  dynClear(exceptionInfo);

  //Check if component is registered:
  if(fwInstallationDB_isComponentRegistered(component, version, component_id) != 0)
  {
    fwInstallation_throw("fwInstallationDB_unregisterProjectReinstallation() -> Could not check if component: " + component+" v." + version + " is registered in DB. Check DB connection parameters.");
    return -1;
  }
  else if(component_id == -1)
  {
    fwInstallation_throw("Component "+component+" v." + version + " not yet registered in the DB.");
    return -1;  
  }

  //Check if project is registered:
  if(fwInstallationDB_isProjectRegistered(project_id, project, host) != 0)
  {
    fwInstallation_throw("fwInstallationDB_unregisterProjectReinstallation() -> Could not check if project: " + project + " in host: " + host + " is registered in DB. Check DB connection parameters.");
    return -1;
  }
  else if(project_id == -1)
  {
     fwInstallation_throw("fwInstallationDB_unregisterProjectReinstallation() -> Project " + project + " in host: " + host + " not yet registered in the DB.");
     return -1;  
  }

  dyn_mixed record;
  record[1] = project_id;
  record[2] = component_id;
  
  sql = "UPDATE FW_SYS_STAT_FORCE_REINSTALL SET EXECUTED_ON = SYSDATE WHERE PROJECT_ID = :1 AND COMPONENT_ID = :2 AND EXECUTED_ON IS NULL";
         
  if(fwInstallationDB_execute(sql, record, false)) {fwInstallation_throw("fwInstallationDB_unregisterProjectReinstallation() -> Could not execute the following SQL: " + sql); return -1;};

  return 0;    
}    

/** This function closes the connection to the System Configuration DB
  @return 0 if OK, -1 if error
*/

int fwInstallationDB_closeDBConnection()
{
  return rdbCloseConnection(gFwInstallationDBConn); 
}

/** This function prompts the user to define the DB connection parameters
  @return 0 if OK, -1 if error
*/
int fwInstallationDB_setupConnection()
{
  ChildPanelOnCentral("fwInstallation/fwInstallationDB_connectionSetup.pnl", "FW Installation DB connection",
                             makeDynString(""));

  return 0;
}



/** This function executes a DB command
  (Deprecated? - orphan method in fwi6.0.2)
  @param sql SQL command
  @param data Command data as a dyn_dyn_mixed array
  @return 0 if OK, -1 if error
*/
int fwInstallationDB_executeDBCommand(string sql, dyn_dyn_mixed data)
{
 
  dbCommand cmd;
  int rc = rdbStartCommand(gFwInstallationDBConn, sql, cmd);        
  
  //The command will likely change things on the database, we will want the cache to be reloaded
//  fwInstallationDBCache_clear();

  if(rc) {fwInstallation_throw("fwInstallationDB_executeDBCommand() -> rdbStartCommand failed"); return -1;}
  else rc = rdbBindAndExecute(cmd, data);
  
  if (rc) {
    fwInstallation_throw("ERROR is BindExec:"  + rc);
    int i1,i2,i3;
    string s1,s2;
    rc=rdbGetError(gFwInstallationDBConn, i1,i2,i3, s1,s2);
    DebugN(s1,s2);  
    dyn_errClass err=getLastError();
    DebugN(err);
    return -1;
  }
  
  rc = rdbFinishCommand(cmd);
    
  // error-handling part
  if (rc) {
      fwInstallation_throw("fwInstallationDB_executeDBCommand() -> rdbBindAndExecutefailed");
      int errorCount, errorNumber, errorNative;
      string errorDescription, SQLState;
      
      rdbGetError(gFwInstallationDBConn, errorCount, errorNumber, errorNative, 
                  errorDescription, SQLState);

      fwInstallation_throw("Database error, rc = " + rc + " errorCount = " + errorCount + " errorNumber = " + errorNumber + " errorNative = " + errorNative + " errorDescription = " + errorDescription + "SQLState = " + SQLState);
      return -1;
        
      }
  
    return 0;
}


/** This function executes a DB query
  (Deprecated? - method used only in fwInstallationFSMDB.ctl) 
  @param sql SQL query to be executed
  @param data retrieved data
  @param columnWise defines if the data must be sorted by columns
  @param maxRecords Maximum number of records allowed in the data
  @param columnTypes data types of the retrieved columns
  @return 0 if OK, -1 if error
*/
int fwInstallationDB_executeDBQuery(string sql, 
                                    dyn_dyn_mixed &data, 
                                    bool columnWise=FALSE, 
                                    int maxRecords=0, 
                                    dyn_int columnTypes=0){
  dbCommand cmd;
  int rc=rdbStartCommand(gFwInstallationDBConn, sql, cmd);

  if (rc) {fwInstallation_throw("fwInstallationDB_executeQuery() -> Error in  rdbStartCommand:" + sql); return -1;};
  
  rc=rdbExecuteCommand(cmd);
  if (rc) {fwInstallation_throw("fwInstallationDB_executeQuery() -> Error in  rdbExecuteCommand: " + sql);return -1;};
  rc=rdbGetData(cmd, data, columnWise, maxRecords, columnTypes);
  
  rc=rdbFinishCommand(cmd);
  if (rc) {fwInstallation_throw("fwInstallationDB_executeQuery() -> Error in  rdbEFinishCommand: " + sql);return -1;}; 
  
  return 0;
}

/** This function returns the initialization status of the DB connection
  @return true if the connection is initialized and false otherwise
*/
bool fwInstallationDB_getInitialized()
{
  bool value;
  dpGet("fwInstallation_agentParametrization.db.connection.initialized", value);
  
  return value;
}

/** This function sets the status of the DB connection initialization
  @param value Initialization status
  @return 0 if OK, -1 if error
*/
int fwInstallationDB_setInitialized(bool value)
{
  return dpSet("fwInstallation_agentParametrization.db.connection.initialized", value);
}


/** This function deletes a DB connection
  @return 0 if OK, -1 if error
*/
int fwInstallationDB_deleteConnection()
{
  
  dpSet("fwInstallation_agentParametrization.db.connection.server", "",
        "fwInstallation_agentParametrization.db.connection.username", "",
        "fwInstallation_agentParametrization.db.connection.password", "");

  
  if(fwInstallationDB_setUseDB(FALSE) != 0)
  {
    fwInstallation_throw("fwInstallationDB_deleteConnection() -> Could not delete DB Connection. Sorry about that!");
    return -1;
  }

  return 0;
}

/** This function checks if a DB table exists
  @param tableName name of the table
  @param tableExists true if the table exists, otherwise false
  @return 0 if OK, -1 if error
*/
int fwInstallationDB_tableExists(string tableName, bool &tableExists)
{
  //GetCache1
  dyn_string parameters = makeDynString(tableName);
  if( fwInstallationDBCache_getCache("_tableExists", parameters, tableExists) == 0 ) {
  	return 0;
  }
  //EndGetCache1


  dyn_string exceptionInfo;
  dyn_dyn_mixed aRecords;
  
  dyn_mixed var;
  var[1] = tableName;

  string sql = "SELECT table_name FROM user_tables where table_name = :1";
  
  dynClear(aRecords);
  tableExists = false;
       
  if(fwInstallationDB_executeQuery(sql, var, aRecords))
  {
    fwInstallation_throw("fwInstallation_tableExists() -> Could not execute the following SQL query: " + sql);
    return -1;
  }  

  if(dynlen(data) > 0 && aRecords[1][1] == tableName)
      tableExists = TRUE;
  else
    tableExists = FALSE;
  
  //SetCache1
  if( fwInstallationDBCache_setCache("_tableExists", parameters, tableExists) == 0 ) {
  }
  //EndSetCache
  
  return 0;

}


/** This function checks if a DB view exists
  @param viewName name of the DB view
  @param viewExists true if the view exists, otherwise false
  @return 0 if OK, -1 if error
*/
int fwInstallationDB_viewExists(string viewName, bool &viewExists)
{
  //GetCache1
  dyn_string parameters = makeDynString(viewName);
  if( fwInstallationDBCache_getCache("_viewExists", parameters, viewExists) == 0 ) {
  	return 0;
  }
  //EndGetCache1


  dyn_string exceptionInfo;
  dyn_dyn_mixed aRecords;

  dyn_mixed var;
  var[1] = viewName;

  string sql = "SELECT view_name FROM all_views WHERE view_name = :1";
  
  dynClear(aRecords);
  viewExists = false;
          
  if(fwInstallationDB_executeQuery(sql, var, aRecords))
  {
    fwInstallation_throw("fwInstallation_viewExists() -> Could not execute the following SQL query: " + sql);
    return -1;
  }  

  if(dynlen(aRecords) > 0 && aRecords[1][1] == viewName)
    viewExists = TRUE;
  else
    viewExists = FALSE;
  
  //SetCache1
  if( fwInstallationDBCache_setCache("_viewExists", parameters, viewExists) == 0 ) {
  }
  //EndSetCache
  
  return 0;

}

/** This function retrieves the current DB schema version
  @param version Version of the System Configuration DB schema
  @return 0 if OK, -1 if error
*/
int fwInstallationDB_getSchemaVersion(string &version)
{
  //GetCache1
  dyn_string parameters = makeDynString();
  if( fwInstallationDBCache_getCache("_getSchemaVersion", parameters, version ) == 0 ) {
  	return 0;
  }
  //EndGetCache1

  bool viewExists = false;
  dyn_string exceptionInfo;
  dyn_dyn_mixed aRecords;
  string sql = "SELECT version FROM fw_sys_stat_schema";

  if(fwInstallationDB_viewExists(FW_INSTALLATION_SCHEMA_TBL, viewExists) == 0 && !viewExists)
  {
    fwInstallation_throw("fwInstallationDB_getSchemaVersion() -> Cannot retrieve the schema version since the view " 
            + FW_INSTALLATION_SCHEMA_TBL + " does not exist. DB Schema does not exist");
    return -1;       
  }
  dynClear(aRecords);
  dyn_mixed var;
  if(fwInstallationDB_executeQuery(sql, var, aRecords))
  {
    fwInstallation_throw("fwInstallation_getSchemaVersion() -> Could not execute the following SQL query: " + sql);
    return -1;
  }  
  if(dynlen(aRecords) > 0) {   
    version = aRecords[1][1];
  }
  else{
    version = "";
  }
 
  //SetCache1
  if( fwInstallationDBCache_setCache("_getSchemaVersion", parameters, version ) == 0 ) {
  }
  //EndSetCache
  
  return 0;
}

/** This function compares the current and required DB schema versions
  @return True if the current is equal or newer than the required one, otherwise false
*/
bool fwInstallationDB_compareSchemaVersion()
{
  string dbVersion;

  dyn_string required;
  dyn_string existing;
  int min;
  
  if(fwInstallationDB_getSchemaVersion(dbVersion) != 0){
    fwInstallation_throw("fwInstallationDB_compareSchemaVersion() -> Could not retrieve schema version from the DB. Aborted.");
    return false;
  }
  
  required = strsplit(FW_INSTALLATION_DB_REQUIRED_SCHEMA_VERSION, ".");
  existing = strsplit(dbVersion, ".");
  
  min = (dynlen(required) > dynlen(existing))?dynlen(existing):dynlen(required);
  
  for(int i = 1; i <= min; i++){
    if(required[i] > existing[i]) {
      return false; 
    } 
  } 
     
  return true;  
}


/** This function registers in the DB a Framework component
  @param xmlFile Component description file
  @return 0 if OK, -1 if error
*/
int fwInstallationDB_registerComponentFromXml(string xmlFile)
{
  string componentName;
  string componentVersion;
  string componentDate;
  dyn_string requiredComponents;
  bool isSubComponent;
  dyn_string initScripts;
  dyn_string deleteScripts;
  dyn_string postInstallScripts;
  dyn_string postDeleteScripts;
  dyn_string configFiles;
  dyn_string asciiFiles;
  dyn_string panelFiles;
  dyn_string scriptFiles;
  dyn_string libraryFiles;
  dyn_string otherFiles;
  dyn_string xmlDesc;

  dyn_string ds;
  string defaultPath;
  
  int error = fwInstallationXml_load(xmlFile, componentName, componentVersion, componentDate, 
                         requiredComponents, isSubComponent, initScripts, deleteScripts, 
                         postInstallScripts, postDeleteScripts, configFiles, asciiFiles, 
                         panelFiles, scriptFiles, libraryFiles, otherFiles, xmlDesc);

  if(error != 0)
  {
    fwInstallation_throw("ERROR::fwInstallationDB_registerComponentFromXml() -> Could not load XML file: " + xmlFile + ". Aborted.");
    return -1;  
  }

  //Make path to the XML file to be the default one.
  ds = strsplit(xmlFile, "/");
  for(int i = 1; i <= (dynlen(ds)-1); i++){
    defaultPath += (ds[i] + "/"); 
  }  
  
  return fwInstallationDB_registerComponent(componentName, componentVersion, isSubComponent);

}

/** This function establishes a connection to the System Configuration DB
  @return 0 if OK, -1 if error
*/
synchronized int fwInstallationDB_connect()
{
  string database, username, password, driver = "QOCI8", owner;
  dyn_float df;
  dyn_string ds;
  mixed dbDrivers;// note that the parameter needs to be of type "mixed"!
   
  //is db meant to be used:
  if(!fwInstallationDB_getUseDB())
  {
    //DB is not intended to be used:
    return -1;
  }
  
  //Check that the library CtrlRDBAccess is available:
  if (!isFunctionDefined("rdbOption")) {
     fwInstallation_throw("fwInstallationDB_connect() -> CtrlRDBAccess library is not available. Check your installation and config file", "ERROR", 7);
     return -1;
  }
  //Find out what driver to use:
  dpGet("fwInstallation_agentParametrization.db.connection.driver", driver,
        "fwInstallation_agentParametrization.db.connection.server", database,
        "fwInstallation_agentParametrization.db.connection.username", username,
        "fwInstallation_agentParametrization.db.connection.schemaOwner", owner,
        "fwInstallation_agentParametrization.db.connection.password", password);

  //force driver to have a value different than ""  
  if(driver == "")
    driver = "QOCI8";
  
  driver = strtoupper(driver);
  
  //Check that the driver can be properly loaded, i.e. Oracle instant client was properly installed.
  rdbOption("GetDrivers",0,dbDrivers);
  
  bool found = false;
  for(int i = 1; i <= dynlen(dbDrivers); i++) //Try with the driver defined by the user
  {
    if(patternMatch(driver, dbDrivers[i]))
    {
      found = true;
      break;
    }    
  }

  if(!found && driver != "QOCI8") //The defined driver could not be found fallback on the default one.
  {
    fwInstallation_throw("fwInstallationDB_connect() -> ORACLE Driver: " + driver + " not found. Trying to fallback on the default QOCI8 driver... Please, apply latest patches for PVSS " + VERSION_DISP, "ERROR", 7);
    driver = "QOCI8";
    for(int i = 1; i <= dynlen(dbDrivers); i++)
    {
      if(patternMatch(driver, dbDrivers[i]))
      {
        fwInstallation_throw("fwInstallationDB_connect() -> Default ORACLE Driver found. Trying to establish connection now", "INFO");
        found = true;
        break;
      }    
    }
  }  
  
  //if(dynContains(dbDrivers, driver)<=0)  //Under linux this lines makes the whole UI crash if dbDrivers is empty, e.g. not ORACLE environment set up.
  if(!found)
  {
     fwInstallation_throw("fwInstallationDB_connect() -> Driver: " + driver + " cannot be loaded. You have to install the ORACLE instant client first.", "ERROR", 7);
     return -1;
  }
  
  if(database == "" || username == "" || password == "")
  {     
      if(myManType() == CTRL_MAN){
        fwInstallation_throw("DB Connection not set up.");
        return -1; 
      }

     ChildPanelOnCentralModalReturn("fwInstallation/fwInstallation_messageInfo.pnl", "DB Connection Question", makeDynString("$1:DB Connection not yet set up.\nWould you like to do it now?", "$2:Yes", "$3:No"), df, ds);
     
     if(dynlen(df) && df[1] > 0.){
       
       ChildPanelOnCentralModalReturn("fwInstallation/fwInstallationDB_connectionSetup.pnl", "DB Connection Setup", makeDynString(""), df, ds);
       if(dynlen(df) == 0 || df[1] < 1.){
         return -1;
       }else{
          dpGet("fwInstallation_agentParametrization.db.connection.server", database,
                "fwInstallation_agentParametrization.db.connection.username", username,
                "fwInstallation_agentParametrization.db.connection.schemaOwner", owner,
                "fwInstallation_agentParametrization.db.connection.password", password); 
            
          if(database != "" && username != "" && password != ""){
            return fwInstallationDB_openDBConnection(database, username, password, owner, driver);
          }else{
              return -1;
          }
       }
     }else{
       return -1;
     }
   }else{
     return fwInstallationDB_openDBConnection(database, username, password, owner, driver);
   }
}

/** This function retrieves the schema owner to be used during the db connection
  @return schema owner as string
*/
string fwInstallationDB_getSchemaOwner()
{
  string user = "", owner = "";
  
  dpGet("fwInstallation_agentParametrization.db.connection.username", user,
        "fwInstallation_agentParametrization.db.connection.schemaOwner", owner);
  
  if(owner == "")
    return user;
  
  return owner;
}

/** This function opens a connection to the System Configuration DB
  @param database (in) database server name
  @param username (in) user name
  @param password (in) password
  @param owner (in) schema owner
  @param driver (in) driver to be used. By default "QOCI8".
  @return 0 if OK, -1 if error
*/
synchronized int fwInstallationDB_openDBConnection(string database, 
                                                   string username, 
                                                   string password, 
                                                   string owner, 
                                                   string driver = "QOCI8")
{
  string errTxt;
  string connectionString = "driver="+driver+";database="+database+";uid="+username+";enc_pwd=" + password;
  string sql;
  
  if(fwInstallationDB_setConnectionTimeout() < 0)
  {
    fwInstallation_throw("fwInstallationDB_openDBConnection()->Error setting DB connection timeout");
    return -1;  
  }
  
  int rc=rdbGetConnection(FW_INSTALLATION_DB_CONNECTION_NAME, gFwInstallationDBConn);
  if (rc==-1){
        rdbCheckError(errTxt, gFwInstallationDBConn);
        fwInstallation_throw("fwInstallationDB_openDBConnection()->Error getting the DB connection: " + errTxt);
        return -1;
  }
  else if(rc == 0) //i.e. we alredy have a valid connection.
  {
    return 0;
  }
  
  // means: no connection yet... open on
  fwInstallation_throw("Trying to establish DB connection. DB server:  " +  database + ", Username : " + username + ", Schema Owner account: " + owner, "INFO");
  int rc=rdbOpenConnection(connectionString, gFwInstallationDBConn, FW_INSTALLATION_DB_CONNECTION_NAME);
  if (rdbCheckError(errTxt,gFwInstallationDBConn)){
    fwInstallation_throw("fwInstallationDB_openDBConnection() -> ERROR WHILE OPENING DATABASE CONNECTION: " + errTxt, "ERROR", 7);
    return -1;
  };      
  
  //set current_schema to schema owner
  if(owner != "" && owner != username)
  {  
    sql = "ALTER SESSION SET CURRENT_SCHEMA = " + owner;
    fwInstallation_throw("INFO: DB Connection Established. Setting current DB schema to " +  owner, "INFO");
    rdbExecuteSqlStatement (gFwInstallationDBConn, sql);
    if (rdbCheckError(errTxt, gFwInstallationDBConn))
    {
      fwInstallationDB_closeDBConnection();//force close connection if fails to set current schema
      fwInstallation_throw("fwInstallationDB_openDBConnection() -> DB ERROR setting current schema to schema owner: " + errTxt, "ERROR", 7);
      return -1;
    }

    //Make sure that the current schema is set to schema owner after reconnection:
    rdbSetSqlOnReconnect(gFwInstallationDBConn, sql);   
  
    if (rdbCheckError(errTxt, gFwInstallationDBConn))
    {
      fwInstallationDB_closeDBConnection();//force close connection if fails to set current schema
      fwInstallation_throw("fwInstallationDB_openDBConnection() -> Error establishing schema owner callback" + errTxt, "ERROR", 7);
      return -1;
    }
  }
  
  return 0;
}

/** This function returns whether the DB-agent of the installation tool must access the System Configuration DB or not
  @return true if the user has chosen to use the System Configuration DB, otherwise false
*/
bool fwInstallationDB_getUseDB()
{
  bool useDB = false;

  if(dpExists("fwInstallation_agentParametrization.db.useDB"))
    dpGet("fwInstallation_agentParametrization.db.useDB", useDB);
  
  return useDB;

}

/** This function sets the flag for the DB-agent of the installation tool to use System Configuration DB
  @param useDB flag indicating whether the DB must be accessed or not
  @return 0 if OK, -1 if errors
*/
int fwInstallationDB_setUseDB(bool useDB)
{
  return dpSet("fwInstallation_agentParametrization.db.useDB", useDB);
}

/** This function registers a PVSS project in the System Configuration DB
  @param projectName project name
  @param host hostname
  @param pmon_port pmon port
  @param pmon_username pmon username
  @param pmon_password pmon password
  @param projectDir project directory
  @param systemName system name
  @param systemNumber system number
  @param dataPortNr data port
  @param eventPortNr event manager port
  @param distPort distributed port
  @param centrallyManaged flag indicating whether project is centrally or locally managed
  @param pvssVersion version of PVSS
  @param os operating system {Windows or Linux}
  @param reduHost name of the host where the redundant peer runs
  @param systemComputer name of the host where the pair DB and event manager runs
  @param deleteFiles flag indicating whether component files are deleted after the deletion of a component
  @param askScattered if set to true and called from a UI, it informs the user that a scattered project will be registered as the system already exists.
  @return 0 if OK, -1 if errors
*/
int fwInstallationDB_registerProject(string projectName = "", 
                                     string host = "", 
                                     int pmon_port = 4999, 
                                     string pmon_username = "", 
                                     string pmon_password = "", 
                                     string projectDir = "", 
                                     string systemName = "", 
                                     int systemNumber = -1, 
                                     int dataPortNr = 4897, 
                                     int eventPortNr = 4998, 
                                     int distPort = 4777, 
                                     int centrallyManaged = 0, 
                                     string pvssVersion = "", 
                                     string os = "", 
                                     string reduHost = "",
                                     string systemComputer = "",
                                     int deleteFiles = 0,
                                     int instToolStatus = 0,
                                     bool askScattered = false,
                                     string projectPvssVersion = VERSION_DISP,
                                     int reduPort = 4899,
                                     int splitPort = 4778)
{
  string sql;
  string tool_version;
  
  int pc_id;
  int project_id;
  int system_id;
  int base_id, pvss_id, host_id;
  int redu_id = -1;   
  dyn_string exceptionInfo;
  dyn_dyn_mixed aRecords;
  dyn_mixed systemProperties;
  
  dyn_string ds;
  dyn_float df;
  dyn_mixed record;
  
  if(projectName == ""){
    projectName = PROJ;
    paGetProjHostPort(projectName, host, pmon_port);
    projectDir = PROJ_PATH;
    systemName = getSystemName();
    systemNumber = getSystemId();
    dyn_string ds = eventHost();
    systemComputer = strtoupper(ds[1]); 
    projectPvssVersion = VERSION_DISP;
    os = _WIN32?"WINDOWS":"LINUX";
  }
  
  if(projectName == PROJ)
  {
    if(pmon_username == "" || pmon_username == "N/A")
      pmon_username = gFwInstallationPmonUser;
    
    if(pmon_password == "" || pmon_password == "N/A")
      pmon_password = gFwInstallationPmonPwd;
  }

  fwInstallation_getToolVersion(tool_version);
  
  if(pvssVersion == "")
  {
    pvssVersion = VERSION_DISP;
    os = _WIN32?"WINDOWS":"LINUX";
  }

  if(os == ""){
    os = _WIN32?"WINDOWS":"LINUX";
  }

  if(!patternMatch("*:", systemName))
    systemName += ":";
      
  dynClear(exceptionInfo);
    
  if(host == "" || host == "localhost")
    host = fwInstallation_getHostname();
  
  host = strtoupper(host);

  //Check if host is registered, otherwise, register it first:
  if(fwInstallationDB_isPCRegistered(pc_id, host) != 0)
  {
    fwInstallation_throw("fwInstallationDB_isPCRegistered() -> Could not access the System Configuration DB. Please, check connection parameters");
    return -1;
  }
  
  if(pc_id == -1)
  {
    dyn_mixed hostInfo;
    fwInstallation_getHostProperties(host, hostInfo);
    if(fwInstallationDB_registerPC(host, hostInfo) != 0)
    {
      fwInstallation_throw("fwInstallationDB_registerProject() -> Could not register PC: " + host);
    }
  }

  fwInstallationDB_isPCRegistered(host_id, host);
  //Check if PVSS version is registered:
  base_id = -1;
  if(pvssVersion != "" && os != "")
  {
    if(fwInstallationDB_isPvssBaseRegistered(host, pvssVersion, os, base_id, pvss_id, host_id) == 0 && base_id == -1){
      fwInstallationDB_registerPvssBase(host, pvssVersion, os);
    }
    fwInstallationDB_isPvssBaseRegistered(host, pvssVersion, os, base_id, pvss_id, host_id);
  }
  
  //Check if the pvss system is already registered, otherwise, register it first:
  systemProperties[FW_INSTALLATION_DB_SYSTEM_NAME] = systemName;
  systemProperties[FW_INSTALLATION_DB_SYSTEM_NUMBER] = systemNumber;
  systemProperties[FW_INSTALLATION_DB_SYSTEM_DATA_PORT] = dataPortNr;
  systemProperties[FW_INSTALLATION_DB_SYSTEM_EVENT_PORT] = eventPortNr;
  systemProperties[FW_INSTALLATION_DB_SYSTEM_DIST_PORT] = distPort;
  systemProperties[FW_INSTALLATION_DB_SYSTEM_REDU_PORT] = reduPort;
  systemProperties[FW_INSTALLATION_DB_SYSTEM_SPLIT_PORT] = splitPort;  
  systemProperties[FW_INSTALLATION_DB_SYSTEM_COMPUTER] = systemComputer;
  systemProperties[FW_INSTALLATION_DB_SYSTEM_REDU_HOST] = reduHost;

  bool new = false;
  if(fwInstallationDB_isSystemRegistered(system_id, systemName) == 0 && system_id == -1){
    new = true;
    //FVR: Call to setsystemproperties instead of register system as the former function will call the 
    //     latter if necessary, i.e. if the system is not yet registered in the DB.
    int err = fwInstallationDB_setSystemProperties(systemProperties);
    if(fwInstallationDB_isSystemRegistered(system_id, systemName) != 0 || system_id < 0){
      fwInstallation_throw("fwInstallationDB_registerProject() -> Could not register system: " + systemName);
    }
  }
  else if(!isRedundant()){
    //Check if scattered system:
    if(askScattered && myManType() == UI_MAN)
    {
      ChildPanelOnCentralReturn("vision/MessageWarning2", "Question", makeDynString("$1:System: "+ systemName + " nr. " + systemNumber + "already registered in DB.\nClick OK to register an scattered project\notherwise make sure the PVSS system is unique", "$2:OK", "$3:Cancel"), df, ds);
      if(dynlen(df) <= 0  || df[1] < 1.)
        return -1;
    }else
    {
      fwInstallation_throw("System: "+ systemName + " nr. " + systemNumber + " already registered in DB. Assuming scattered project", "warning", 13);
    }
  }
  
  //check if systemInfo is up-to-date:
  dyn_mixed oldSystemInfo;
  if(!new)
  {
    if(fwInstallationDB_getPvssSystemProperties(systemName, oldSystemInfo))
    {
        fwInstallation_throw("Could not read system properties from DB: " + systemName);
        return -1;
    }

    if(oldSystemInfo[FW_INSTALLATION_DB_SYSTEM_DATA_PORT] != systemProperties[FW_INSTALLATION_DB_SYSTEM_DATA_PORT] ||
       oldSystemInfo[FW_INSTALLATION_DB_SYSTEM_EVENT_PORT] != systemProperties[FW_INSTALLATION_DB_SYSTEM_EVENT_PORT] ||
       oldSystemInfo[FW_INSTALLATION_DB_SYSTEM_DIST_PORT] != systemProperties[FW_INSTALLATION_DB_SYSTEM_DIST_PORT] ||
       oldSystemInfo[FW_INSTALLATION_DB_SYSTEM_REDU_PORT] != systemProperties[FW_INSTALLATION_DB_SYSTEM_REDU_PORT] ||
       oldSystemInfo[FW_INSTALLATION_DB_SYSTEM_SPLIT_PORT] != systemProperties[FW_INSTALLATION_DB_SYSTEM_SPLIT_PORT] ||       
       oldSystemInfo[FW_INSTALLATION_DB_SYSTEM_COMPUTER] != systemProperties[FW_INSTALLATION_DB_SYSTEM_COMPUTER])
//       oldSystemInfo[FW_INSTALLATION_DB_SYSTEM_REDU_COMPUTER] != systemProperties[FW_INSTALLATION_DB_SYSTEM_REDU_COMPUTER])
    {
      fwInstallationDB_setSystemProperties(systemProperties);
    }
  }
  if(fwInstallationDB_isProjectRegistered(project_id, projectName, host) == 0 && project_id == -1){

    //check if the project is redundant and if so, check if the project is already registered for the redundant host
  
    //When registering a project by hand using system configuration panels, reduHost must be set to a value different than NO_REDUNDANT  
    if(reduHost == "" && isRedundant()) //Project is redundant but reduHost has not been specified. Try to resolve redu host.
    {
      reduHost = fwInstallationRedu_getPair(); 
    }
  
    if(isRedundant())
    {
      // check if the redundant PC is registered, otherwise register it first
      if(fwInstallationDB_isPCRegistered(redu_id, reduHost) != 0)
      {
        fwInstallation_throw("fwInstallationDB_isPCRegistered() -> Could not access the System Configuration DB. Please, check connection parameters");
        return -1;
      }
  
      if(redu_id == -1)
      {
        dyn_mixed hostInfo;
        fwInstallation_getHostProperties(reduHost, hostInfo);
        if(fwInstallationDB_registerPC(reduHost, hostInfo) != 0)
        {
          fwInstallation_throw("fwInstallationDB_registerProject() -> Could not register PC: " + reduHost);
        }
        fwInstallationDB_isPCRegistered(redu_id, reduHost);
      }
      fwInstallationDB_isProjectRegistered(project_id, projectName, reduHost);
      if (myReduHostNum() !=1)//we want in the database computer ID to be project 1 and redu_id to be the host for project 2
      {
        //swap host_id and redu_id
        int tmp = host_id;
        host_id = redu_id;
        redu_id = tmp;
      }
    
    }  
    else 
      project_id = -1;
      
    if(project_id == -1)
    {
      //project is not yet registered for the redu host:
      int neverChecked = FW_INSTALLATION_DB_PROJECT_NEVER_CHECKED;
      record[1] = projectName;    
      record[2] = host_id;    
      record[3] = projectDir;    
      record[4] = pmon_port;    
      record[5] = pmon_username;    
      record[6] = pmon_password;    
      record[7] = tool_version;    
      record[8] = system_id;            
      record[9] = centrallyManaged;  
      if (redu_id > 0)  
      {
        record[10] = redu_id;
      }
      record[11] = deleteFiles;    
      record[12] = instToolStatus;    
      record[13] = projectPvssVersion;
      record[14] = os;

//       if(base_id > 0)
//       {
//         record[12] = base_id;    
//         sql = "INSERT INTO fw_sys_stat_pvss_project(id, project_name, computer_id, project_dir, "+
//               "pmon_port, pmon_username, pmon_password, fw_inst_tool_version, "+
//               "system_id, is_project_ok, , centrally_managed, "+
//               "delete_files, system_overview, redu_computer_id, inst_tool_status, pvss_base_id) "+
//               "VALUES ((fw_sys_stat_pvss_project_sq.NEXTVAL), :1, :2, :3, :4, :5, :6, :7, :8, NULL, SYSDATE, :9, :10, 1, NULL, :11, :12)";
//       }
//       else
//       {
        sql = "INSERT INTO fw_sys_stat_pvss_project(id, project_name, computer_id, project_dir, "+
              "pmon_port, pmon_username, pmon_password, fw_inst_tool_version, "+
              "system_id, is_project_ok, last_time_checked, centrally_managed, "+
              "system_overview, redu_computer_id, delete_files, inst_tool_status, pvss_version, os) "+
              "VALUES ((fw_sys_stat_pvss_project_sq.NEXTVAL), :1, :2, :3, :4, :5, :6, :7, :8, NULL, SYSDATE, :9, 1, :10, :11, :12, :13, :14)";      
//       }
      
      if(fwInstallationDB_execute(sql, record)) {fwInstallation_throw("fwInstallationDB_registerProject() -> Failed to register project. Could not execute the following SQL: " + sql); return -1;};
    }
    else if(!fwInstallationDB_getCentrallyManaged())
    {
      //project already registered for the redu host, update 
      if (!isRedundant() || myReduHostNum() ==1 )
      {
        record[1] = host_id;    
      }
      else
      {
        record[1] = redu_id;
      }
      record[2] = project_id;    

      fwInstallation_throw("INFO: fwInstallationDB_registerProject() -> Registering redundant project: " + projectName + " in host: " + host + ". Redundant host: " + reduHost, "info", 10);
      sql = "UPDATE fw_sys_stat_pvss_project SET redu_computer_id = :1 WHERE id = :2";
      if(fwInstallationDB_execute(sql, record)) {fwInstallation_throw("fwInstallationDB_registerProject() -> Could not execute the following SQL: " + sql); return -1;};
    }  
  }
  return 0;  
}


/** This function unregisters a project path from the System Configuration DB
  @param installationPath projec path to be unregistered
  @param projectName project name
  @param computerName hostname
  @return 0 if OK, -1 if errors
*/
int fwInstallationDB_unregisterInstallationPath(string installationPath, string projectName = "", string computerName = "")
{
  dyn_string exceptionInfo;
  dyn_dyn_mixed aRecords;
  string sql;
  bool isValid;
  
  int installation_path_id;
  int project_id;
          
  dynClear(aRecords);

  if(projectName == "")
    projectName = PROJ;
  
  if(computerName == "")
    computerName = fwInstallation_getHostname();
  
  computerName = strtoupper(computerName);

  if(fwInstallationDB_isInstallationPathRegistered(installationPath, installation_path_id, project_id, projectName, computerName) != 0)
  {
    fwInstallation_throw("fwInstallationDB_unregisterInstallationPath() -> Could not retrieve project installation path information from DB");
    return -1;
    
  }else if(installation_path_id == -1){
    fwInstallation_throw("INFO: fwInstallationDB_unregisterInstallationPath() -> Path: " + installationPath + " not registered in project: " + projectName + " computer: " + computerName + ". Nothing to be done.");
    return 0;      
  }else{
     
    dyn_mixed record;
    record[1] = installation_path_id;
        
    sql = "UPDATE fw_sys_stat_inst_path SET valid_until = SYSDATE WHERE id = :1";
    if(fwInstallationDB_execute(sql, record)) {fwInstallation_throw("fwInstallationDB_unregisterInstallationPath() -> Could not execute the following SQL: " + sql); return -1;};

  }      
  return 0;
}

/** This function unregisters all project paths at once from the System Configuration DB
  @param projectName project name
  @param computerName hostname
  @return 0 if OK, -1 if errors
*/
int fwInstallationDB_deleteAllProjectPaths(string projectName = "", string computerName = "")
{
  dyn_string exceptionInfo;
  string sql;
  
  if(projectName == "")
    projectName = PROJ;
  
  if(computerName == "")
    computerName = fwInstallation_getHostname();
  
  computerName = strtoupper(computerName);

  dyn_mixed record;
  record[1] = projectName;
  record[2] = computerName;
           
  sql = "delete fw_sys_stat_inst_path WHERE valid_until is null and project_id = " + 
        "(select id from fw_sys_stat_pvss_project where valid_until is null and project_name = :1 " +
        "and computer_id = (select id from fw_sys_stat_computer where hostname = :2 and valid_until is null))";
         
  if(fwInstallationDB_execute(sql, record)) {fwInstallation_throw("fwInstallationDB_deleteAllProjectPaths() -> Could not execute the following SQL: " + sql); return -1;};
 
  return 0;
}

/** This function retrieves all registered project paths from the System Configuration DB
  @param dbInstallationPaths list of project paths
  @param dbInstallationPathsIds list of DB indices of the different project paths
  @param projectName project name
  @param computerName hostname
  @return 0 if OK, -1 if errors
*/
int fwInstallationDB_getInstallationPaths(dyn_string &dbInstallationPaths, dyn_string &dbInstallationPathsIds, string projectName = "", string computerName = "")
{
  //GetCache1
  dyn_string parameters = makeDynString(projectName, computerName);
  if( fwInstallationDBCache_getCache("_getInstallationPaths", parameters, dbInstallationPaths, "paths") == 0 
  	&&  fwInstallationDBCache_getCache("_getInstallationPaths", parameters, dbInstallationPaths, "pathsIds") == 0 
	) {
  	return 0;
  }
  //EndGetCache1

  dyn_string exceptionInfo;
  string sql;
  dyn_dyn_mixed aRecords;
  int project_id;
  
  dynClear(exceptionInfo);
  dynClear(aRecords);  

  if(projectName == "")
    projectName = PROJ;
  
  if(computerName = "")
    computerName = fwInstallation_getHostname();
  
  computerName = strtoupper(computerName); 
  
  if(fwInstallationDB_isProjectRegistered(project_id, projectName, computerName) != 0)
  {
    fwInstallation_throw("fwInstallationDB_getInstallationPaths() - > Cannot get project information from DB.");
    return -1;  
  }else if(project_id == -1)
  {  
    fwInstallation_throw("ffwInstallationDB_getInstallationPaths() - > Project: " + projectName + " in computer: " + computerName + " not registered in DB.");
    return 0;        
  }else{
    dyn_mixed var;
    var[1] = project_id;
    
    sql = "SELECT id, path FROM fw_sys_stat_inst_path WHERE project_id = :1 AND valid_until IS NULL";
    if(fwInstallationDB_executeQuery(sql, var, aRecords))
   {
     fwInstallation_throw("fwInstallation_getInstallationPaths() -> Could not execute the following SQL query: " + sql);
     return -1;
   }  

    for(int i = 1; i <= dynlen(aRecords); i++) {            
      dynAppend(dbInstallationPathsIds, aRecords[i][1]);
      dynAppend(dbInstallationPaths, aRecords[i][2]);
    }
  }

  //SetCache1
  if( fwInstallationDBCache_setCache("_getInstallationPaths", parameters, dbInstallationPaths, "paths") == 0 
  	&&  fwInstallationDBCache_setCache("_getInstallationPaths", parameters, dbInstallationPaths, "pathsIds") == 0 
	) {
  }
  //EndSetCache
  
  return 0;    
  
}

/** This function retrieves all PVSS project registered in the System Configuration DB
  @param projectNames list of project names
  @param computerName hostname
  @param onlyActive if true ignores the history of projects
  @return 0 if OK, -1 if errors
*/

int fwInstallationDB_getPvssProjects(dyn_string &projectNames, string computerName = "", bool onlyActive = true)
{
  //GetCache1
  dyn_string parameters = makeDynString(computerName, onlyActive);
  if( fwInstallationDBCache_getCache("_getPvssProjects", parameters, projectNames ) == 0 ) {
  	return 0;
  }
  //EndGetCache1

  dyn_string exceptionInfo;
  string sql;
  dyn_dyn_mixed aRecords;
    dyn_mixed var;
  
  dynClear(exceptionInfo);
  dynClear(aRecords);  
  dynClear(projectNames);  
  
  if(computerName == "")
    computerName = fwInstallation_getHostname();
  
  computerName = strtoupper(computerName);
  
  if(computerName == "ALL" && onlyActive)
     sql = "SELECT project_name FROM fw_sys_stat_pvss_project WHERE valid_until IS NULL AND COMPUTER_ID IN (SELECT ID FROM FW_SYS_STAT_COMPUTER WHERE VALID_UNTIL IS NULL) OR REDU_COMPUTER_ID IN (SELECT ID FROM FW_SYS_STAT_COMPUTER WHERE VALID_UNTIL IS NULL) order by project_name";
  else if(computerName == "ALL" && !onlyActive) 
     sql = "SELECT project_name FROM fw_sys_stat_pvss_project order by project_name";
  else if(computerName != "ALL" && onlyActive){
    var[1] = computerName;
    sql = "SELECT project_name FROM fw_sys_stat_pvss_project " +  
           "WHERE valid_until IS NULL " + 
           "AND (computer_id = (SELECT id FROM fw_sys_stat_computer WHERE hostname = :1 AND valid_until IS NULL) " + 
           "OR redu_computer_id = (SELECT id FROM fw_sys_stat_computer WHERE hostname = :1 AND valid_until IS NULL)) order by project_name";
   }
  else
  {
    var[1] = computerName;
    
    sql = "SELECT project_name FROM fw_sys_stat_pvss_project " +  
          "WHERE (computer_id = (SELECT id FROM fw_sys_stat_computer WHERE hostname = :1) OR " +
          "redu_computer_id = ((SELECT id FROM fw_sys_stat_computer WHERE hostname = :1))) order by project_name";
  }
  if(fwInstallationDB_executeQuery(sql, var, aRecords))
  {
      fwInstallation_throw("fwInstallation_getPvssProjects() -> Could not execute the following SQL query: " + sql);
      return -1;
  }  

  for(int i = 1; i <= dynlen(aRecords); i++) {          
     dynAppend(projectNames, aRecords[i][1]);
  }
  
  //SetCache1
  if( fwInstallationDBCache_setCache("_getPvssProjects", parameters, projectNames ) == 0 ) {
  }
  //EndSetCache
  
  return 0;
}

/** This function registers a component in the System Configuration DB
  @param componentName component name
  @param componentVersion component version
  @param isSubComponent flag indicating if the component is a subcomponent
  @return 0 if OK, -1 if errors
*/
int fwInstallationDB_registerComponent(string componentName, string componentVersion, int isSubComponent)
{
  string sql;
  int component_id;

  dyn_string exceptionInfo;
  dyn_dyn_mixed aRecords;

  dynClear(exceptionInfo);

  //Check if component is already registered:
  if(fwInstallationDB_isComponentRegistered(componentName, componentVersion, component_id) == 0 && component_id != -1){
    return 0;  
  }

  dyn_mixed record;
  record[1] = componentName;
  record[2] = componentVersion;
  record[3] = isSubComponent;

  sql = "INSERT INTO fw_sys_stat_component(id, component_name, component_version, is_subcomponent, valid_from, valid_until) "+
        "VALUES (fw_sys_stat_component_sq.NEXTVAL, :1 ,:2, :3, SYSDATE, NULL)";
         
  if(fwInstallationDB_execute(sql, record)) {fwInstallation_throw("fwInstallationDB_registerProject() -> Could not execute the following SQL: " + sql); return -1;};

  return 0;  
}
/** This function checks if a component is registered in the System Configuration DB
  @param componentName component name
  @param componentVersion component version
  @param id DB index. -1 if the compnent is not registered in the DB
  @return 0 if OK, -1 if errors
*/
int fwInstallationDB_isComponentRegistered(string componentName, string componentVersion, int &id)
{
  //GetCache1
  dyn_string parameters = makeDynString(componentName, componentVersion);
  if( fwInstallationDBCache_getCache("_isComponentRegistered", parameters, id) == 0 ) {
  	return 0;
  }
  //EndGetCache1


  dyn_string exceptionInfo;
  dyn_dyn_mixed aRecords;
  string sql;

  dynClear(aRecords);
  
  dyn_mixed var;
  var[1] = componentName;    
  var[2] = componentVersion;    
  
  sql = "SELECT id FROM fw_sys_stat_component WHERE component_name = :1 AND component_version = :2 AND valid_until IS NULL";
  if(fwInstallationDB_executeQuery(sql, var, aRecords))
  {
    fwInstallation_throw("fwInstallation_isComponentRegistered() -> Could not execute the following SQL query: " + sql);
    return -1;
  }  

  if(dynlen(aRecords) > 0) {   
    id = aRecords[1][1];
  }
  else{
    id = -1;
  }

  //SetCache1
  if( fwInstallationDBCache_setCache("_isComponentRegistered", parameters, id) == 0 ) {
  }
  //EndSetCache
  
  return 0;
}

int fwInstallationDB_needsSynchronize(int &project_id,
                                      bool &needsSynchronize,
                                      string projectName = "",
                                      string computerName = "")
{
  dyn_string exceptionInfo;
  dyn_dyn_mixed aRecords;
  string sql;
  int pc_id;
  string reduHost;

  if(projectName == "")
    projectName = PROJ;
  
  if(computerName == "")
    computerName = fwInstallation_getHostname();

  computerName = strtoupper(computerName);

  dyn_mixed var;
  var[1] = projectName;    
  var[2] = computerName;    

  sql = "SELECT id, system_id, computer_id, need_synchronize FROM fw_sys_stat_pvss_project WHERE valid_until is null and project_name = :1 " +
        "AND (computer_id = (select id from fw_sys_stat_computer where hostname = :2 and valid_until is null) " + 
        "OR redu_computer_id = (select id from fw_sys_stat_computer where hostname = :2 and valid_until is null))";
    
  dynClear(aRecords);
      
  if(fwInstallationDB_executeQuery(sql, var, aRecords))
  {
    fwInstallation_throw("fwInstallationDB_isProjectRegistered() -> Could not execute the following SQL query: " + sql);
    return -1;
  }  
  if(dynlen(aRecords) > 0) {   
    if(g_fwInstallationVerbose)
      fwInstallation_throw("INFO: fwInstallationDB_isProjectRegistered() -> Project "+ projectName + " already registered in the DB for computer: " + computerName +" with id:" +  aRecords);
        
    project_id = aRecords[1][1];
    //Project is registered. Check if it is necessary to update the computer id in the system table to that where the event manager of the project runs:
    //int systemId = aRecords[1][2];
    //int computerId = aRecords[1][3];
    if( aRecords[1][4] == "N" ) {
      needsSynchronize = false;
      //Set the current last_time_checked. 
      //[TODO] Do we want to make also set the project status? This requires the cache to be kept alive until the beggining of next cycle of the agent if we don't want to get everything again.
      //if local changes are done, the server should know that something is being messed up on the client.
      //WE can also just force the synchronization if we suspect things can change locally, and we need that information.
      sql = "UPDATE fw_sys_stat_pvss_project SET last_time_checked = SYSDATE WHERE id = " + project_id; 
      if(rdbExecuteSqlStatement(gFwInstallationDBConn, sql)) {
      	  fwInstallation_throw("fwInstallationDBAgent_setProjectStatus() -> Could not execute the following SQL: " + sql); 
	  return -1;
      };
    }
    else 
      needsSynchronize = true;
  }
  else{
    project_id = -1;
    needsSynchronize = true;
  }
  return 0;
}
                                       


/** This function checks if a project is registered in the System Configuration DB
  @param project_id DB index of the project. -1 if the project is not registered in the DB.
  @param projectName project name
  @param computerName hostname
  @return 0 if OK, -1 if errors
*/
int fwInstallationDB_isProjectRegistered(int &project_id, 
                                         string projectName = "", 
                                         string computerName = "")
{
  
  //GetCache1
  dyn_string parameters = makeDynString(projectName, computerName);
  if( fwInstallationDBCache_getCache("_isProjectRegistered", parameters, project_id) == 0 ) {
  	return 0;
  }
  //EndGetCache1

  dyn_string exceptionInfo;
  dyn_dyn_mixed aRecords;
  string sql;
  int pc_id;
  string reduHost;
  

  if(projectName == "")
    projectName = PROJ;
  
  if(computerName == "")
    computerName = fwInstallation_getHostname();
  
      
  computerName = strtoupper(computerName);

  dyn_mixed var;
  var[1] = projectName;    
  var[2] = computerName;    

  sql = "SELECT id, system_id, computer_id FROM fw_sys_stat_pvss_project WHERE valid_until is null and project_name = :1 " +
        "AND (computer_id = (select id from fw_sys_stat_computer where hostname = :2 and valid_until is null) " + 
        "OR redu_computer_id = (select id from fw_sys_stat_computer where hostname = :2 and valid_until is null))";
  dynClear(aRecords);
      
  if(fwInstallationDB_executeQuery(sql, var, aRecords))
  {
    fwInstallation_throw("fwInstallationDB_isProjectRegistered() -> Could not execute the following SQL query: " + sql);
    return -1;
  }  
  if(dynlen(aRecords) > 0) {   
    project_id = aRecords[1][1];
    //Project is registered. Check if it is necessary to update the computer id in the system table to that where the event manager of the project runs:
    
    int systemId = aRecords[1][2];
    int computerId = aRecords[1][3];
    dynClear(var);
    var[1] = systemId;
    
    sql = "SELECT computer_id FROM fw_sys_stat_pvss_system WHERE id = :1";
    dynClear(aRecords);
      
    if(fwInstallationDB_executeQuery(sql, var, aRecords))
    {
      fwInstallation_throw("fwInstallationDB_isProjectRegistered() -> Could not execute the following SQL query: " + sql);
      return -1;
    }
    if(dynlen(aRecords) > 0 && aRecords[1][1] <= 0)
    {      
      DebugN("INFO: Updating Project Event Host info in the System Configuration DB for project");
      //Update is required
      dynClear(var);
      var[1] = computerId;
      var[2] = systemId;
      sql = "UPDATE fw_sys_stat_pvss_system SET computer_id = :1 WHERE id = :2";
      if(fwInstallationDB_execute(sql, var)) {fwInstallation_throw("fwInstallationDB_isProjectRegistered() -> Could not execute the following SQL: " + sql); return -1;};
    }  
    
  }
  else{
    project_id = -1;
  }

  //SetCache1
  if( fwInstallationDBCache_setCache("_isProjectRegistered", parameters, project_id) == 0 ) {
  }
  //EndSetCache

  return 0;
}


/** This function registers a host in the System Configuration DB
  @param host hostname
  @param hostInfo host properties
  @return 0 if OK, -1 if errors
*/
int fwInstallationDB_registerPC(string host = "", dyn_mixed hostInfo = "")
{
  int pcId = -1;
  string sql;
  string ip, ip2, mac, mac2, bmc_ip, bmc_user, bmc_pwd; 
     
  dyn_string exceptionInfo;
  dyn_dyn_mixed aRecords;
  dynClear(exceptionInfo);
  
  
  //override host since the previous function sets localhost
  if(host == ""){
    fwInstallation_getHostProperties(fwInstallation_getHostname(), hostInfo);    
  }
  
  host = strtoupper(host);
  
  hostInfo[FW_INSTALLATION_DB_HOST_NAME_IDX] = strtoupper(hostInfo[FW_INSTALLATION_DB_HOST_NAME_IDX]);
  
  if(dynlen(hostInfo) >= FW_INSTALLATION_DB_HOST_IP_1_IDX) 
    ip = hostInfo[FW_INSTALLATION_DB_HOST_IP_1_IDX]; 

  if(dynlen(hostInfo) >= FW_INSTALLATION_DB_HOST_MAC_1_IDX) 
    mac = hostInfo[FW_INSTALLATION_DB_HOST_MAC_1_IDX];

  if(dynlen(hostInfo) >= FW_INSTALLATION_DB_HOST_MAC_2_IDX) 
    mac2 = hostInfo[FW_INSTALLATION_DB_HOST_MAC_2_IDX];

  if(dynlen(hostInfo) >= FW_INSTALLATION_DB_HOST_IP_2_IDX) 
    ip2 = hostInfo[FW_INSTALLATION_DB_HOST_IP_2_IDX];

  if(dynlen(hostInfo) >= FW_INSTALLATION_DB_HOST_BMC_IP_IDX) 
    bmc_ip = hostInfo[FW_INSTALLATION_DB_HOST_BMC_IP_IDX];

  if(dynlen(hostInfo) >= FW_INSTALLATION_DB_HOST_BMC_PWD_IDX) 
    bmc_pwd = hostInfo[FW_INSTALLATION_DB_HOST_BMC_PWD_IDX];

  if(dynlen(hostInfo) >= FW_INSTALLATION_DB_HOST_BMC_USER_IDX) 
    bmc_user = hostInfo[FW_INSTALLATION_DB_HOST_BMC_USER_IDX];
  
    dyn_mixed record;
    
    record[1] = host;
    record[2] = ip;
    record[3] = mac;
    record[4] = ip2;
    record[5] = mac2;
    record[6] = bmc_ip;
    record[7] = bmc_user;
    record[8] = bmc_pwd;

  //Check if already exists:
  if(fwInstallationDB_isPCRegistered(pcId, host) == 0 && pcId == -1){
    sql = "INSERT INTO fw_sys_stat_computer(id, hostname, ip, mac, ip2, mac2, bmc_ip, bmc_user, bmc_pwd, valid_from, valid_until) "+
          "VALUES ((fw_sys_stat_computer_sq.NEXTVAL), :1, :2, :3, :4, :5, :6, :7, :8, SYSDATE, NULL)";
   if(fwInstallationDB_execute(sql, record)) {fwInstallation_throw("fwInstallationDB_registerPC() -> Could not execute the following SQL: " + sql); return -1;};

  }else{
    record[1] = host;
    record[2] = ip;
    record[3] = mac;
    record[4] = ip2;
    record[5] = mac2;
    record[6] = bmc_ip;
    record[7] = bmc_user;
    record[8] = bmc_pwd;
    record[9] = pcId;
    
    sql = "UPDATE fw_sys_stat_computer SET ip = :1, mac = :2, ip2 = :3 , mac2 = :4, bmc_ip = :5, bmc_user = :6, bmc_pwd = :7, valid_from = SYSDATE WHERE id = :9";
   if(fwInstallationDB_execute(sql, record)) {fwInstallation_throw("fwInstallationDB_registerPC() -> Could not execute the following SQL: " + sql); return -1;};
  }

  return 0;  
}

/** This function deletes a host from the System Configuration DB
  @param host host to be deleted
  @return 0 if OK, -1 if errors
*/
int fwInstallationDB_deletePC(string host = "")
{
  string sql;
    
  dyn_string exceptionInfo;
  dyn_dyn_mixed aRecords;
  dyn_dyn_mixed data;
  
  if(host == ""){
    host = fwInstallation_getHostname();    
  }  
 
  host = strtoupper(host);
  
  dyn_mixed record;
    
  record[1] = host;
  sql = "select id from fw_sys_stat_pvss_project where computer_id = (select id from fw_sys_stat_computer where hostname = :1) or redu_computer_id = (select id from fw_sys_stat_computer where hostname = :1)";
  if(fwInstallationDB_executeQuery(sql, record, data)) {fwInstallation_throw("fwInstallationDB_unregisterPC() -> Could not execute the following SQL: " + sql); return -1;};
  for(int i = 1; i <= dynlen(data); i++)
  {
    record[1] = data[i][1];
    sql = "DELETE fw_sys_stat_proj_inst_log WHERE project_id = :1";
    if(fwInstallationDB_execute(sql, record)) {fwInstallation_throw("fwInstallationDB_unregisterPC() -> Could not execute the following SQL: " + sql); return -1;};
  }
  record[1] = host;
  sql = "DELETE fw_sys_stat_computer WHERE hostname = :1";
  if(fwInstallationDB_execute(sql, record)) {fwInstallation_throw("fwInstallationDB_unregisterPC() -> Could not execute the following SQL: " + sql); return -1;};

  return 0;  
}

/** This function deletes a project from the System Configuration DB
  @param project project name
  @param host hostname
  @param deleteSystem flag indicating if the PVSS system must also be deleted
  @return 0 if OK, -1 if errors
*/
int fwInstallationDB_deleteProject(string project = "", string host = "", bool deleteSystem = false)
{
  int id;
  string sql;
  dyn_mixed projectInfo;    
  dyn_string exceptionInfo;
  dyn_dyn_mixed aRecords;
  
  dynClear(exceptionInfo);
  
  if(project == "")
    project = PROJ;
  
  if(host == ""){
    host = fwInstallation_getHostname();    
  }  
 
  host = strtoupper(host);
  dyn_mixed record;
  
  record[1] =project; 
  record[2] =host;   
 
  fwInstallationDB_getProjectProperties(project, host, projectInfo, id); 
  
  sql = "DELETE fw_sys_stat_pvss_project WHERE project_name = :1 and computer_id = (select id from fw_sys_stat_computer where hostname = :2)";
      
  if(fwInstallationDB_execute(sql, record)) {fwInstallation_throw("fwInstallationDB_deleteProject() -> Could not execute the following SQL: " + sql); return -1;};
    
  if(deleteSystem && dynlen(projectInfo) >= FW_INSTALLATION_DB_PROJECT_SYSTEM_NAME)
  {
    if(fwInstallationDB_deleteSystem(projectInfo[FW_INSTALLATION_DB_PROJECT_SYSTEM_NAME]) != 0)
    {  
      fwInstallation_throw("fwInstallationDB_deleteProject() -> Failed to delete PVSS system: " + projectInfo[FW_INSTALLATION_DB_PROJECT_SYSTEM_NAME]);
      return -1;
    }
  }
  return 0;  
}

/** This function deletes a PVSS system from the System Configuration DB
  @param systemName system name
  @return 0 if OK, -1 if errors
*/
int fwInstallationDB_deleteSystem(string systemName)
{
  string sql;
  dyn_string exceptionInfo;
  
  dynClear(exceptionInfo);
  
  dyn_mixed record;
  record[1] = systemName;
    
  sql = "DELETE fw_sys_stat_pvss_system WHERE SYSTEM_NAME = :1";
  
  if(fwInstallationDB_execute(sql, record)) {fwInstallation_throw("fwInstallationDB_deleteSystem() -> Could not execute the following SQL: " + sql); return -1;};

  return 0;  
}

/** This function deletes a project manager from the System Configuration DB
  @param managerInfo manager information as a dyn_mixed
  @param project project name
  @param host hostname
  @return 0 if OK, -1 if errors
*/
int fwInstallationDB_deleteProjectManager(dyn_mixed managerInfo, string project = "", string host = "")
{
  int project_id = -1;
  int manager_id = -1;
  string sql;
    
  dyn_string exceptionInfo;
  dyn_dyn_mixed aRecords;
  
  dynClear(exceptionInfo);
  
  if(project == "")
    project = PROJ;
  
  if(host == ""){
    host = fwInstallation_getHostname();    
  }  
 
  host = strtoupper(host);
  
  dyn_mixed record;
  record[1] = managerInfo[FW_INSTALLATION_DB_MANAGER_NAME_IDX];
  record[2] = managerInfo[FW_INSTALLATION_DB_MANAGER_OPTIONS_IDX];
  record[3] = project;
  record[4] = host;

  sql = "delete from fw_sys_stat_project_manager " + 
//        "where valid_until is null " + 
	      "where manager_type = :1 " + 
	      "and command_line = :2 " +
	      "and project_id = (select id from fw_sys_stat_pvss_project where valid_until is null and project_name = :3 and computer_id = (select id from fw_sys_stat_computer where hostname = :4 and valid_until is null))";
      
  if(fwInstallationDB_execute(sql, record, false)) {fwInstallation_throw("fwInstallationDB_deleteProjectManager() -> Could not execute the following SQL: " + sql); return -1;};
  
  return 0;  
}


int fwInstallationDB_deleteProjectManagers(string project = "", string host = "")
{
  string sql;
    
  dyn_dyn_mixed aRecords;
  
  if(project == "")
    project = PROJ;
  
  if(host == ""){
    host = fwInstallation_getHostname();    
  }  
  host = strtoupper(host);
  
  dyn_mixed record;
  record[1] = project;
  record[2] = host;

  sql = "delete from fw_sys_stat_project_manager " + 
	      "where " +
	      "project_id = (select id from fw_sys_stat_pvss_project where valid_until is null and project_name = :1 and computer_id = (select id from fw_sys_stat_computer where hostname = :2 and valid_until is null))";
 
  if(fwInstallationDB_execute(sql, record, false)) {fwInstallation_throw("fwInstallationDB_deleteProjectManager() -> Could not execute the following SQL: " + sql); return -1;};
  
  return 0;  
}


/** This function checks if a host is registered in the System Configuration DB
  @param id DB index of the host. -1 if the host is not registered in the DB.
  @param host hostname
  @return 0 if OK, -1 if errors
*/
int fwInstallationDB_isPCRegistered(int &id, string host = "")
{
  dyn_string exceptionInfo;
  dyn_dyn_mixed aRecords;
  dyn_dyn_mixed hostsInfo;
  string sql = "";
  
  id = -1;
  dynClear(aRecords);
  
  if(host == "")
    host = fwInstallation_getHostname();
  
  host = strtoupper(host);
  
  //Check first if PC has been registered in a different case, e.g. PCITco147 instead of PCITCO147
  if(fwInstallationDB_getHostsInfo(hostsInfo))
  {
    fwInstallation_throw("fwInstallation_isPCRegistered() -> Could not retrieve the lists of hosts from DB");
    return -1;
  }

  for(int i = 1; i <= dynlen(hostsInfo); i++)
  {
    if(strtoupper(hostsInfo[i][FW_INSTALLATION_DB_HOST_NAME_IDX]) == host)
    {
      id = hostsInfo[i][FW_INSTALLATION_DB_HOST_DB_IDX];
      //Check now if the hostname has to be updated:
      if(host != hostsInfo[i][FW_INSTALLATION_DB_HOST_NAME_IDX])
      {
        fwInstallation_throw("Found computer name in DB: " + hostsInfo[i][FW_INSTALLATION_DB_HOST_NAME_IDX] + ". Capitalizing it now: " + host, "INFO", 10);
        dyn_mixed record;
        record[1] = host;
        record[2] = id;
         
        sql = "update fw_sys_stat_computer set hostname = :1 where id = :2";
        if(fwInstallationDB_execute(sql, record)) {fwInstallation_throw("fwInstallationDB_isPCRegistered() -> Could not execute the following SQL: " + sql); return -1;};
      }
      
      break;
    }
  }
  return 0;
}

/** This function registers a PVSS system in the System Configuration DB
  @param systemProperties Information about the PVSS system as a dyn_mixed array
  @return 0 if OK, -1 if errors
*/
int fwInstallationDB_registerSystem(dyn_mixed systemProperties)
{
  string systemName = systemProperties[FW_INSTALLATION_DB_SYSTEM_NAME];
  int systemNumber = systemProperties[FW_INSTALLATION_DB_SYSTEM_NUMBER];
  int dataPortNr = systemProperties[FW_INSTALLATION_DB_SYSTEM_DATA_PORT];
  int eventPortNr = systemProperties[FW_INSTALLATION_DB_SYSTEM_EVENT_PORT];
  int distPort = systemProperties[FW_INSTALLATION_DB_SYSTEM_DIST_PORT];
  int reduPort = systemProperties[FW_INSTALLATION_DB_SYSTEM_REDU_PORT];
  int splitPort = systemProperties[FW_INSTALLATION_DB_SYSTEM_SPLIT_PORT];  
  string evHost = systemProperties[FW_INSTALLATION_DB_SYSTEM_COMPUTER];
    
  string sql;
  string host1;
  string host2;
  
  int systemId;
        
  dyn_string exceptionInfo;
  dyn_dyn_mixed aRecords;
  
  dynClear(exceptionInfo);

  if(systemName == ""){
    systemName = getSystemName();  
    systemNumber = getSystemId(systemName);
    //Get distribution port number:
    distPort = fwInstallation_getDistPort();
    reduPort = fwInstallation_getReduPort();
    splitPort = fwInstallation_getSplitPort();    
    dataPortNr = dataPort();
    eventPortNr = eventPort();    
    dyn_string ds = eventHost();    
    evHost = strtoupper(ds[1]);
  }
  
  if(!patternMatch("*:", systemName))
    systemName += ":";

  host1 = strtoupper(host1);
  host2 = strtoupper(host2);
  
  //Check if already exists:
  if(fwInstallationDB_isSystemRegistered(systemId, systemName) == 0 && systemId == -1){
    dyn_mixed record;
    
    record[1] = systemName;
    record[2] = systemNumber;
    record[3] = dataPortNr;
    record[4] = eventPortNr;
    record[5] = distPort;
    record[6] = reduPort;
    record[7] = splitPort;    

    int pcId = -1;    
    fwInstallationDB_isPCRegistered(pcId, evHost);
    if(pcId > 0)
    {
      record[8] = pcId;
      sql = "INSERT INTO fw_sys_stat_pvss_system(id, system_name, system_number, data_port, event_port, dist_port, parent_system_id, valid_from, valid_until, redu_port, split_port, computer_id) "+
             "VALUES ((fw_sys_stat_pvss_system_sq.NEXTVAL), :1, :2, :3, :4, :5, NULL, SYSDATE, NULL, :6, :7, :8)";
    }
    else
    {
      sql = "INSERT INTO fw_sys_stat_pvss_system(id, system_name, system_number, data_port, event_port, dist_port, parent_system_id, valid_from, valid_until, redu_port, split_port) "+
             "VALUES ((fw_sys_stat_pvss_system_sq.NEXTVAL), :1, :2, :3, :4, :5, NULL, SYSDATE, NULL, :6, :7)";
    }
    
    if(fwInstallationDB_execute(sql, record)) {fwInstallation_throw("fwInstallationDB_registerSystem() -> Could not execute the following SQL: " + sql); return -1;};
  }

  return 0;  
}

/** This function checks if a PVSS system is registered in the System Configuration DB
  @param id DB index of the system. -1 if the system is not registered in the DB.
  @param systemName system name
  @return 0 if OK, -1 if errors
*/
int fwInstallationDB_isSystemRegistered(int &id, string systemName = "")
{
  //GetCache1
  dyn_string parameters = makeDynString(systemName);
  if( fwInstallationDBCache_getCache("_isSystemRegistered", parameters, id) == 0 ) {
  	return 0;
  }
  //EndGetCache1

  string host1;
  string host2;
  
  dyn_string exceptionInfo;
  dyn_dyn_mixed aRecords;
  
  if(systemName == "")
    systemName = getSystemName();
  
  if(!patternMatch("*:", systemName))
    systemName += ":";

  dyn_mixed var;
  var[1] = systemName;    
  string sql = "SELECT id FROM fw_sys_stat_pvss_system WHERE system_name = :1 AND valid_until IS NULL";
  
  dynClear(aRecords);
  id = -1;
       
  if(fwInstallationDB_executeQuery(sql, var, aRecords))
  {
    fwInstallation_throw("fwInstallation_isSystemRegistered() -> Could not execute the following SQL query: " + sql);
    return -1;
  }  

  if(dynlen(aRecords) > 0) {   
    id = aRecords[1][1];
  }
  else{
    id = -1;
  }
  
  //SetCache1
  if( fwInstallationDBCache_setCache("_isSystemRegistered", parameters, id) == 0 ) {
  }
  //EndSetCache
  
  return 0;
}

/** This function checks if a project path is registered in the System Configuration DB
  @param installationPath Project path
  @param installation_path_id DB index of the project path. -1 if the project path is not yet registered in the DB.
  @param project_id DB index of the project. -1 if the project is not yet registered in the DB.
  @param projectName project name
  @param computerName hostname
  @return 0 if OK, -1 if errors
*/
int fwInstallationDB_isInstallationPathRegistered(string installationPath, 
                                                  int &installation_path_id, 
                                                  int &project_id, 
                                                  string projectName = "",
                                                  string computerName = "")
{
  //GetCache1
  dyn_string parameters = makeDynString(installationPath, projectName, computerName);
  if( fwInstallationDBCache_getCache("_isInstallationPathRegistered", parameters, installation_path_id, "path_id" ) == 0 
  	&& fwInstallationDBCache_getCache("_isInstallationPathRegistered", parameters, project_id, "proj_id" ) == 0 
	) {
  	return 0;
  }
  //EndGetCache1

  dyn_mixed hostInfo;
  dyn_string exceptionInfo;
  dyn_dyn_mixed aRecords;
  string sql;

  int computer_id;
  
  installation_path_id = -1;        
  dynClear(aRecords);

  if(projectName == "")
    projectName = PROJ;
  
  if(computerName == "")
    computerName = fwInstallation_getHostname();

  computerName = strtoupper(computerName);
  
  //Check that the computer is properly registered in the DB    
  if(fwInstallationDB_isPCRegistered(computer_id, computerName) == 0)
  {
    if(computer_id == -1){
      fwInstallation_getHostProperties(computerName, hostInfo);
      fwInstallationDB_registerPC(computerName, hostInfo);
      fwInstallationDB_isPCRegistered(computer_id);
    }
  }else{
    fwInstallation_throw("fwInstallationDB_isInstallationPathRegistered() -> Could not retrieve the PC info from the DB. Action aborted...");
    return -1;
  }
    
  //Check that the project is properly registered in the DB  
  if(fwInstallationDB_isProjectRegistered(project_id, projectName, computerName) == 0)
  {
    if(project_id == -1){
      fwInstallationDB_registerProject();
      fwInstallationDB_isProjectRegistered(project_id);
    }
  }else{
    fwInstallation_throw("fwInstallationDB_isInstallationPathRegistered() -> Could not retrieve the project info from the DB. Action aborted...");
    return -1;
  }

  
  if(computer_id != -1 && project_id != -1)
  {
    dyn_mixed var;
    var[1] = installationPath;    
    var[2] = project_id;    

    sql = "SELECT id FROM fw_sys_stat_inst_path WHERE path = :1 AND project_id = :2 AND valid_until IS NULL";      
    if(fwInstallationDB_executeQuery(sql, var, aRecords))
    {
      fwInstallation_throw("fwInstallation_isInstallationPathRegistered() -> Could not execute the following SQL query: " + sql);
      return -1;
    }  

    if(dynlen(aRecords) > 0) {         
      installation_path_id = aRecords[1][1];        
      }else 
        installation_path_id = -1;
    }
    
  //SetCache1
  if( fwInstallationDBCache_setCache("_isInstallationPathRegistered", parameters, installation_path_id, "path_id" ) == 0 
  	&& fwInstallationDBCache_setCache("_isInstallationPathRegistered", parameters, project_id, "proj_id" ) == 0 
	) {
  }
  //EndSetCache
  
  return 0;
}

/** This function registers a project path in the System Configuration DB
  @param installationPath Project path
  @param isDefault flag indicating if this path is the default installation path
  @param projectName project name
  @param computerName hostname
  @return 0 if OK, -1 if errors
*/
int fwInstallationDB_registerInstallationPath(string installationPath, 
                                              int isDefault, 
                                              string projectName = "", 
                                              string computerName = "")
{

  dyn_string exceptionInfo;
  dyn_dyn_mixed aRecords;
  string sql;
  string requestedBy = getUserName();      //To handle FW usernames
  string requestDate = getCurrentTime();
  int project_id;
  int installation_path_id;
  bool isValid;

  dynClear(aRecords);

  if(projectName == "")
    projectName = PROJ;

  if(computerName == "")
    computerName = fwInstallation_getHostname();
  
  computerName = strtoupper(computerName);
  
  if(fwInstallationDB_isInstallationPathRegistered(installationPath, installation_path_id, project_id, projectName, computerName) == 0 && project_id != -1)
  {
    if(installation_path_id == -1){

      if(rdbBeginTransaction(gFwInstallationDBConn)){
        fwInstallation_throw("fwInstallationDB_registerInstallationPath() -> Could not start DB transaction");
        return -1;
      }
      
      sql = "INSERT INTO fw_sys_stat_inst_path(id, project_id, path, valid_from, valid_until) VALUES((fw_sys_stat_inst_path_sq.NEXTVAL), " + project_id + ", \'" + installationPath + "\', SYSDATE, NULL)";      

      if(rdbExecuteSqlStatement(gFwInstallationDBConn, sql)){
        fwInstallation_throw("fwInstallationDB_registerInstallationPath() -> Could not execute the following SQL: " + sql);
        if(rdbRollbackTransaction(gFwInstallationDBConn))
          fwInstallation_throw("fwInstallationDB_registerInstallationPath() -> Could not roll back DB transaction.");
        
        return -1;
      }
  
      //Everything OK -> Check the id that was assigned and modify the project table to set default path if required     
      if(isDefault == 1 && fwInstallationDB_isInstallationPathRegistered(installationPath, installation_path_id, project_id, projectName, computerName) == 0 && installation_path_id != -1)
      {
        sql = "UPDATE fw_sys_stat_pvss_project SET default_inst_path_id = " + installation_path_id + " WHERE id = " + project_id;        
        if(rdbExecuteSqlStatement(gFwInstallationDBConn, sql)){
          fwInstallation_throw("fwInstallationDB_registerInstallationPath() -> Could not execute the following SQL: " + sql);
          if(rdbRollbackTransaction(gFwInstallationDBConn))
            fwInstallation_throw("fwInstallationDB_registerInstallationPath() -> Could not roll back DB transaction.");
        
          return -1;
        }else if(rdbCommitTransaction(gFwInstallationDBConn))
        {
          fwInstallation_throw("fwInstallationDB_registerInstallationPath() -> Could not commit DB transaction.");
          return -1;
        }
        
        }else if(rdbCommitTransaction(gFwInstallationDBConn))
        {
          fwInstallation_throw("fwInstallationDB_registerInstallationPath() -> Could not commit DB transaction.");
          return -1;
        }
      
    }else if(!isValid)
    {

      if(rdbBeginTransaction(gFwInstallationDBConn)){
        fwInstallation_throw("fwInstallationDB_registerInstallationPath() -> Could notstart DB transaction");
        return -1;
      }
      sql = "UPDATE fw_sys_stat_inst_path SET valid_until = NULL WHERE ID = " + installation_path_id;      
      if(rdbExecuteSqlStatement(gFwInstallationDBConn, sql)){
        fwInstallation_throw("fwInstallationDB_registerInstallationPath() -> Could not execute the following SQL: " + sql);
        if(rdbRollbackTransaction(gFwInstallationDBConn))
          fwInstallation_throw("fwInstallationDB_registerInstallationPath() -> Could not roll back DB transaction.");
        
        return -1;
      }

      //Everything OK -> Check the id that was assigned and modify the project table to set default path if required     
      if(isDefault == 1)
      {
        sql = "UPDATE fw_sys_stat_pvss_project SET default_inst_path_id = " + installation_path_id + " WHERE id = " + project_id;        
        if(rdbExecuteSqlStatement(gFwInstallationDBConn, sql)){
          fwInstallation_throw("fwInstallationDB_registerInstallationPath() -> Could not execute the following SQL: " + sql);
          if(rdbRollbackTransaction(gFwInstallationDBConn))
            fwInstallation_throw("fwInstallationDB_registerInstallationPath() -> Could not roll back DB transaction.");
        
          return -1;
        }else if(rdbCommitTransaction(gFwInstallationDBConn))
        {
          fwInstallation_throw("fwInstallationDB_registerInstallationPath() -> Could not commit DB transaction.");
          return -1;
        }
      }
      else if(rdbCommitTransaction(gFwInstallationDBConn))
      {
        fwInstallation_throw("fwInstallationDB_registerInstallationPath() -> Could not commit DB transaction.");
        return -1;
      }
    }
    else{
      return 0;        
    }
  }
  else{
    fwInstallation_throw("fwInstallationDB_registerInstallationPatht() -> Cannot talk to DB or project are not properly registered in the DB");
    return -1;
  }

  return 0;
}

/** This function retrieves the list of patches applied to a PVSS installation
  @param host hostname
  @param version PVSS version to check the patches for
  @param os host operating system
  @param patches list of applied patches
  @return 0 if OK, -1 if errors
*/
int fwInstallationDB_getPatchList(string host, string version, string os, dyn_string &patches)
{
  //GetCache1
  dyn_string parameters = makeDynString(host, version, os);
  if( fwInstallationDBCache_getCache("_getPatchList", parameters, patches) == 0 ) {
  	return 0;
  }
  //EndGetCache1

  string sql;
  dyn_dyn_mixed aRecords;

  dyn_mixed var;
  var[1] = host;     
  var[2] = version;     
  var[3] = os;     

  sql = "SELECT PATCH_NAME FROM FW_SYS_STAT_PVSS_PATCH WHERE ID IN "+ 
        "  (SELECT PATCH_ID FROM FW_SYS_STAT_PVSS_SETUP WHERE VALID_UNTIL IS NULL AND "+ 
        "     BASE_VERSION_ID = (select ID from fw_sys_stat_pvss_base_version "+
        "                        where computer_id = (select id from fw_sys_stat_computer where valid_until is null and hostname = :1) "+
        "                           and pvss_version_id = (select id from fw_sys_stat_pvss_version where version_name = :2 and os = :3)))";

  /*
  sql = "select patch_name from fw_sys_stat_pvss_patch where id in "+
        "(select patch_id " +
        "from fw_sys_stat_pvss_setup "+
        "where valid_until is null "+
        "  and base_version_id = " +
        "  	(select pvss_version_id " +
        "    from FW_SYS_STAT_PVSS_BASE_VERSION " +
        "   where computer_id = (select id from fw_sys_stat_computer where valid_until is null and hostname = :1) " + 
  	     "      and pvss_version_id = (select id from FW_SYS_STAT_PVSS_VERSION where version_name = :2 and os = :3)))";
*/
  
  if(fwInstallationDB_executeQuery(sql, var, aRecords))
  {
    fwInstallation_throw("fwInstallationDB_getPatchList() -> Could not execute the following SQL query: " + sql);
    return -1;
  }  

  for(int i = 1; i <= dynlen(aRecords); i++) {   
    dynAppend(patches, aRecords[i][1]);
  }
  
  //SetCache1
  if( fwInstallationDBCache_setCache("_getPatchList", parameters, patches) == 0 ) {
  }
  //EndSetCache
  
  return 0; 
}

/** This function retrieves the list of PVSS versions registered for a host in the System Configuration DB
  @param host hostname
  @param versions PVSS versions installed
  @param oss list of OS for different PVSS versions installed
  @return 0 if OK, -1 if errors
*/
int fwInstallationDB_getPvssVersions(string host = "", dyn_string &versions, dyn_string &oss)
{
  //GetCache1
  dyn_string parameters = makeDynString(host);
  if( fwInstallationDBCache_getCache("_getPvssVersions", parameters, versions, "versions") == 0 
  	&& fwInstallationDBCache_getCache("_getPvssVersions", parameters, oss, "oss") == 0 
	) {
  	return 0;
  }
  //EndGetCache1

  int pc_id;
  dyn_string exceptionInfo;
  string sql;
  dyn_dyn_mixed aRecords;
  
  dynClear(exceptionInfo);
  dynClear(aRecords);  

  if(host == "")
    host = fwInstallation_getHostname();
  
  host = strtoupper(host);
  
  if(fwInstallationDB_isPCRegistered(pc_id, host) != 0){
    fwInstallation_throw("fwInstallationDB_getPvssVersions() -> Could not connect to DB.");
    return -1; 
  }
  
  dyn_mixed var;
  var[1] = pc_id;     
  
  sql = "SELECT version_name, os FROM fw_sys_stat_pvss_version WHERE id IN (SELECT pvss_version_id FROM fw_sys_stat_pvss_base_version WHERE computer_id = :1)";
  if(fwInstallationDB_executeQuery(sql, var, aRecords))
  {
    fwInstallation_throw("fwInstallationDB_getPvssVersions() -> Could not execute the following SQL query: " + sql);
    return -1;
  }  

  for(int i = 1; i <= dynlen(aRecords); i++) {   
    dynAppend(versions, aRecords[i][1]);
    dynAppend(oss, aRecords[i][2]);
  }
  
  //SetCache1
  if( fwInstallationDBCache_setCache("_getPvssVersions", parameters, versions, "versions") == 0 
  	&& fwInstallationDBCache_setCache("_getPvssVersions", parameters, oss, "oss") == 0 
	) {
  }
  //EndSetCache
  
  return 0;
}

/** This function registers a PVSS version in the System Configuration DB
  @param version PVSS version string, "" means the version of the local project
  @param os Operating System, "" means the OS of the local project
  @return 0 if OK, -1 if errors
*/

int fwInstallationDB_registerPvssVersion(string version = "", string os = "")
{
  string sql;
  int id;
  dyn_string exceptionInfo;
  dyn_dyn_mixed aRecords;
  
  dynClear(exceptionInfo);
  
  //override host since the previous function sets localhost
  if(version == ""){
    version = VERSION_DISP;
  }
  
  if(_WIN32)
    os = "WINDOWS";
  else
    os = "LINUX";
  
  
  //Check if already exists:
  if(fwInstallationDB_isPvssVersionRegistered(version, os, id) != 0){
    fwInstallation_throw("fwInstallationDB_registerPvssVersion() -> Could not connect to DB. Check connection parameters");
    return -1;
  }

  if(id == -1){
    dyn_mixed record;
    record[1] = version;
    record[2] = os;
    sql = "INSERT INTO fw_sys_stat_pvss_version(id, version_name, os) VALUES ((fw_sys_stat_pvss_version_sq.NEXTVAL), :1, :2)";    
    if(fwInstallationDB_execute(sql, record)) {fwInstallation_throw("fwInstallationDB_registerPvssVersion() -> Could not execute the following SQL: " + sql); return -1;};
  }

  return 0;  
}


/** This function checks if a PVSS version is registered in the System Configuration DB
  @param version name of the PVSS version to be checked
  @param os operating system type {WINDOWS, LINUX}
  @param id DB index of the PVSS version. -1 means that the PVSS version is not registered in the DB.
  @return 0 if OK, -1 if errors
*/
int fwInstallationDB_isPvssVersionRegistered(string version, string os, int &id)
{
  //GetCache1
  dyn_string parameters = makeDynString(version, os);
  if( fwInstallationDBCache_getCache("_isPvssVersionRegistered", parameters, id) == 0 ) {
  	return 0;
  }
  //EndGetCache1

  dyn_string exceptionInfo;
  dyn_dyn_mixed aRecords;

  dynClear(aRecords);
  id = -1;
  
  dyn_mixed var;
  var[1] = version;     
  var[2] = os;     

  string sql = "SELECT id FROM fw_sys_stat_pvss_version WHERE version_name = :1 AND os = :2" ;  
  if(fwInstallationDB_executeQuery(sql, var, aRecords))
  {
    fwInstallation_throw("fwInstallation_isPvssVersionRegistered() -> Could not execute the following SQL query: " + sql);
    return -1;
  }  

  if(dynlen(aRecords) > 0)   
    id = aRecords[1][1];
  else
    id = -1;
  
  //SetCache1
  if( fwInstallationDBCache_setCache("_isPvssVersionRegistered", parameters, id) == 0 ) {
  }
  //EndSetCache
  
  return 0;
}

/** This function registers a PVSS patch in the System Configuration DB
  @param patch patch name
  @param version PVSS version name
  @param os operating sytem type {WINDOWS, LINUX}
  @return 0 if OK, -1 if errors
*/

int fwInstallationDB_registerPvssPatch(string patch, string version = "", string os = "")
{
  string sql;
  int pvss_id;
  int patch_id;
  dyn_string exceptionInfo;
  dyn_dyn_mixed aRecords;
  
  dynClear(exceptionInfo);
  
  //override host since the previous function sets localhost
  if(version == ""){
    version = VERSION_DISP;
  }
  
  if(_WIN32)
    os = "WINDOWS";
  else
    os = "LINUX";
  
  
  //Check if already exists:
  if(fwInstallationDB_isPvssPatchRegistered(patch, version, os, patch_id, pvss_id) != 0){
    fwInstallation_throw("fwInstallationDB_registerPvssPatch() -> Could not check if patch is registered: " + patch + " PVSS version: " + version);
    return -1;
  }

  if(patch_id > 0){
   //Nothing to be done. Patch already registered in DB
    return 0; 
  }

  //PVSS Version not yet registered. Registernig now:  
  if(pvss_id == -1){
    if(fwInstallationDB_registerPvssVersion(version, os) != 0){
      fwInstallation_throw("fwInstallationDB_registerPvssPatch() -> Failed to register the new PVSS version: " + version);
      return -1;
    }
    //Check pvss version has been properly registered:
    fwInstallationDB_isPvssVersionRegistered(version, os, pvss_id);
    
    if(pvss_id == -1){
      fwInstallation_throw("fwInstallationDB_registerPvssPatch() -> Failed to register PVSS version " + version + " Operating system: " + os );
      return -1;
    }
  }
  
  dyn_mixed record;
  record[1] = patch;
  record[2] = pvss_id;
  
  sql = "INSERT INTO fw_sys_stat_pvss_patch(id, patch_name, pvss_version_id) VALUES ((fw_sys_stat_pvss_patch_sq.NEXTVAL), :1, :2)";    
  if(fwInstallationDB_execute(sql, record)) {fwInstallation_throw("fwInstallationDB_registerPvssPatch() -> Could not execute the following SQL: " + sql); return -1;};

  return 0;  
}

/** This function registers a PVSS patch for a given PVSS version in the System Configuration DB
  @param patch PVSS patch name
  @param version PVSS version name
  @param os operating sytem type {WINDOWS, LINUX}
  @param patch_id DB index of the patch once registered.
  @param pvss_id DB index of the PVSS version
  @return 0 if OK, -1 if errors
*/
int fwInstallationDB_isPvssPatchRegistered(string patch, string version, string os, int &patch_id, int &pvss_id)
{
  //GetCache1
  dyn_string parameters = makeDynString(patch, version, os);
  if( fwInstallationDBCache_getCache("_isPvssPatchRegistered", parameters, patch_id, "patch_id") == 0 
	&& fwInstallationDBCache_getCache("_isPvssPatchRegistered", parameters, pvss_id, "pvss_id" ) == 0 
	) {
  	return 0;
  }
  //EndGetCache1

  dyn_string exceptionInfo;
  dyn_dyn_mixed aRecords;

  dynClear(aRecords);
  
  //Check that pvss version is registered:
  if(fwInstallationDB_isPvssVersionRegistered(version, os, pvss_id) != 0){
    fwInstallation_throw("fwInstallationDB_isPvssPatchRegistered() -> Could not connect to DB. Check connection parameters");
    return -1;
  }
  
  if(pvss_id == -1){
    patch_id = -1;
    return 0;
  }
  
  dyn_mixed var;
  var[1] = patch;     
  var[2] = pvss_id;     

  string sql = "SELECT id FROM fw_sys_stat_pvss_patch WHERE patch_name = :2 AND pvss_version_id  = :1";  
  if(fwInstallationDB_executeQuery(sql, var, aRecords))
  {
    fwInstallation_throw("fwInstallation_isPvssPatchRegistered() -> Could not execute the following SQL query: " + sql);
    return -1;
  }  

  if(dynlen(aRecords) > 0)   
    patch_id = aRecords[1][1];
  else
    patch_id = -1;
  
  //SetCache1
  if( fwInstallationDBCache_setCache("_isPvssPatchRegistered", parameters, patch_id, "patch_id") == 0 
	&& fwInstallationDBCache_setCache("_isPvssPatchRegistered", parameters, pvss_id, "pvss_id" ) == 0 
	) {
  }
  //EndSetCache
  
  return 0;
}

/** This function registers a base PVSS version (i.e. a version of PVSS in a host) in the System Configuration DB
  @param host hostname
  @param version PVSS version name
  @param os Operating System {WINDOWS, LINUX}
  @return 0 if OK, -1 if errors
*/
int fwInstallationDB_registerPvssBase(string host = "", string version = "", string os = "")
{
  string sql;
  int base_id;
  int host_id;
  int pvss_id;
  dyn_string exceptionInfo;
  dyn_dyn_mixed aRecords;
  
  dynClear(exceptionInfo);
  
  if(host == "")
    host = fwInstallation_getHostname();
  
  host = strtoupper(host);
  
  if(version == ""){
    version = VERSION_DISP;
  }
  
  if(_WIN32)
    os = "WINDOWS";
  else
    os = "LINUX";
  
  
  //Check if already exists:
  if(fwInstallationDB_isPvssBaseRegistered(host, version, os, base_id, pvss_id, host_id) != 0){
    fwInstallation_throw("fwInstallationDB_registerPvssBase() -> Could not connect to DB. Check connection parameters");
    return -1;
  }
  
  if(base_id > 0){
   //Nothing to be done. Patch already registered in DB
    return 0; 
  }

  //PVSS Version not yet registered. Registernig now:  
  if(pvss_id == -1){
    if(fwInstallationDB_registerPvssVersion(version, os) != 0){
//    if(fwInstallationDB_registerHostPvssVersions() != 0){
      fwInstallation_throw("fwInstallationDB_registerPvssPatch() -> Failed to register all host PVSS versions");
      return -1;
    }
    //Check pvss version has been properly registered:
    fwInstallationDB_isPvssVersionRegistered(version, os, pvss_id);
    
    if(pvss_id == -1){
      fwInstallation_throw("fwInstallationDB_registerPvssPatch() -> Failed to register PVSS version " + version + " Operating system: " + os );
      return -1;
    }
  }
  
  //Host not yet registered. Registernig now:  
  if(host_id == -1){
    if(fwInstallationDB_registerPC(host) != 0){
      fwInstallation_throw("fwInstallationDB_registerPvssPatch() -> Could not connect to DB. Check connection parameters");
      return -1;
    }
    //Check pvss version has been properly registered:
    fwInstallationDB_isPCRegistered(host_id, host);
    
    if(host_id == -1){
      fwInstallation_throw("fwInstallationDB_registerPvssPatch() -> Failed to register host " + host + " in DB");
      return -1;
    }
  }
  
  dyn_mixed record;
  record[1] = host_id;
  record[2] = pvss_id;
  
  sql = "INSERT INTO fw_sys_stat_pvss_base_version(id, computer_id, pvss_version_id) VALUES ((fw_sys_stat_base_version_sq.NEXTVAL), :1, :2)";    
  if(fwInstallationDB_execute(sql, record)) {fwInstallation_throw("fwInstallationDB_registerPvssBase() -> Could not execute the following SQL: " + sql); return -1;};

  return 0;  
}

/** This function checks if a PVSS base version is registed in the System Configuration DB
  @param host hostname
  @param version PVSS version name
  @param os operating system type
  @param base_id DB index of the PVSS base version. -1 if not registered in the DB.
  @param pvss_id DB index of the PVSS version
  @param host_id DB index of the host
  @return 0 if OK, -1 if errors
*/
int fwInstallationDB_isPvssBaseRegistered(string host, 
                                          string version, 
                                          string os, 
                                          int &base_id, 
                                          int &pvss_id, 
                                          int &host_id)
{
  //GetCache1
  dyn_string parameters = makeDynString(host, version, os);
  if( fwInstallationDBCache_getCache("_isPvssBaseRegistered", parameters, base_id, "base_id") == 0 
  	&& fwInstallationDBCache_getCache("_isPvssBaseRegistered", parameters, pvss_id, "pvss_id") == 0 
	&& fwInstallationDBCache_getCache("_isPvssBaseRegistered", parameters, host_id, "host_id") == 0 
	) {
  	return 0;
  }
  //EndGetCache1

  dyn_string exceptionInfo;
  dyn_dyn_mixed aRecords;

  dynClear(aRecords);
  
  //Check that pvss version is registered:
  if(fwInstallationDB_isPvssVersionRegistered(version, os, pvss_id) != 0){
    fwInstallation_throw("fwInstallationDB_isPvssBaseRegistered() -> Could not connect to DB. Check connection parameters");
    return -1;
  }
  
  if(fwInstallationDB_isPCRegistered(host_id, host) != 0){
    fwInstallation_throw("fwInstallationDB_isPvssBaseRegistered() -> Could not connect to DB. Check connection parameters");
    return -1;
  }
  
  if(pvss_id == -1 || host_id == -1){
    base_id = -1;
    return 0;
  }
  
  dyn_mixed var;
  var[1] = host_id;     
  var[2] = pvss_id;     

  string sql = "SELECT id FROM fw_sys_stat_pvss_base_version WHERE computer_id = :1 AND pvss_version_id  = :2";  
  if(fwInstallationDB_executeQuery(sql, var, aRecords))
  {
    fwInstallation_throw("fwInstallation_isPvssBaseRegistered() -> Could not execute the following SQL query: " + sql);
    return -1;
  }  

  if(dynlen(aRecords) > 0)   
    base_id = aRecords[1][1];
  else
    base_id = -1;
  
  //SetCache1
  if( fwInstallationDBCache_setCache("_isPvssBaseRegistered", parameters, base_id, "base_id") == 0 
  	&& fwInstallationDBCache_setCache("_isPvssBaseRegistered", parameters, pvss_id, "pvss_id") == 0 
	&& fwInstallationDBCache_setCache("_isPvssBaseRegistered", parameters, host_id, "host_id") == 0 
	) {
  }
  //EndSetCache
  
  return 0;
}

/** This function registers a PVSS setup (i.e. host + pvss base versio + list of patches) in the System Configuration DB
  @param host hostname
  @param version PVSS version
  @param os operating system type
  @param patches list of applied patches
  @return 0 if OK, -1 if errors
*/
int fwInstallationDB_registerPvssSetup(string host = "", 
                                       string version = "", 
                                       string os = "", 
                                       dyn_string patches = "")
{  
  int error = 0;
  string sql;
  int base_id;
  int host_id;
  int pvss_id;
  int patch_id;
  int setup_id;
  
  dyn_string exceptionInfo;
  dyn_dyn_mixed aRecords;
  dyn_string existingDbPatches;
  
  dynClear(exceptionInfo);
  dynClear(existingDbPatches);
  
  if(host == "")
    host = fwInstallation_getHostname();
  
  host = strtoupper(host);
  
  if(version == ""){
    version = VERSION_DISP;
  }
  
  if(_WIN32)
    os = "WINDOWS";
  else
    os = "LINUX";
  
  //patches empty?
  if(dynlen(patches)  == 1 && patches[1] == "")
    version = fwInstallation_getPvssVersion(patches);
  
  //Check if pvss base version is properly registered in db and force registration if not.
  if(fwInstallationDB_isPvssBaseRegistered(host, version, os, base_id, pvss_id, host_id) != 0)
  {
   fwInstallation_throw("fwInstallationDB_registerPvssSetup() -> Could not connect to the DB. "); 
   return -1;    
  }
  if(base_id == -1){
   if(fwInstallationDB_registerPvssBase(host, version, os) != 0)
   {
     fwInstallation_throw("fwInstallationDB_registerPvssSetup() -> Failed to register PVSS base setup in DB. "); 
     return -1;    
   }
 }
  //Everything went ok, retrieve base_id
  fwInstallationDB_isPvssBaseRegistered(host, version, os, base_id, pvss_id, host_id);
  fwInstallationDB_getPatchList(host, version, os, existingDbPatches);  
  
  //For each of the patches, check if they are registered, otherwise force registration:
  for(int i = 1; i <= dynlen(patches); i++){
    //remove current patch from list of existingDbPatches so that it does not get removed at the end:
    if(dynContains(existingDbPatches, patches[i]) > 0)
      dynRemove(existingDbPatches, dynContains(existingDbPatches, patches[i]));
        
    //Check if pvss base version is properly registered in db and force registration if not.
    if(fwInstallationDB_isPvssPatchRegistered(patches[i], version, os, patch_id, pvss_id) != 0)
    {
      fwInstallation_throw("fwInstallationDB_registerPvssSetup() -> Could not connect to the DB. "); 
      return -1;    
    }
    
    if(patch_id == -1){
      if(fwInstallationDB_registerPvssPatch(patches[i], version, os) != 0)
     {
       fwInstallation_throw("fwInstallationDB_registerPvssSetup() -> Failed to register PVSS patch" + patches[i] + "  in DB. "); 
       return -1;    
     }
     //Everything went ok, retrieve patch_id
     fwInstallationDB_isPvssPatchRegistered(patches[i], version, os, patch_id, pvss_id);
   }

  //Check if setup entry, i.e. pair base_version_id, patch_id in DB already
  if(fwInstallationDB_isPvssSetupEntryRegistered(base_id, patch_id, setup_id) != 0)
  {
    fwInstallation_throw("fwInstallationDB_registerPvssSetup() -> Failed to connect to DB"); 
    return -1;    
  }
  if(setup_id > 0){
   continue;
  } 
  
  dyn_mixed record;
  record[1] = base_id;
  record[2] = patch_id;
  
  sql = "INSERT INTO fw_sys_stat_pvss_setup(id, base_version_id, patch_id, valid_from, valid_until) VALUES ((fw_sys_stat_pvss_setup_sq.NEXTVAL), :1, :2, SYSDATE, NULL)";    
  if(fwInstallationDB_execute(sql, record)) {fwInstallation_throw("fwInstallationDB_registerPvssBase() -> Could not execute the following SQL: " + sql); ++error;};
   
  }//end of loop
  
  
  //loop now over the remaining existingDbPatches and remove them from the DB as they are not present in PVSS:
  for(int i = 1; i <= dynlen(existingDbPatches); i++)
  {
    if(fwInstallationDB_unregisterSetupPvssPatch(host, version, os, existingDbPatches[i]) != 0)
    {
      fwInstallation_throw("fwInstallationDB_registerPvssSetup() -> Could not unregister patch from DB: " + existingDbPatches[i], "warning");
      ++error;
    }
  }
    
  if(error)
    return -1;
  else
    return 0;

}

/** This function unregisters a patch from a PVSS setup in the System Configuration DB
  @param host hostname
  @param version PVSS version name
  @param os operating system type
  @param patch patch name
  @return 0 if OK, -1 if errors
*/
int fwInstallationDB_unregisterSetupPvssPatch(string host, string version, string os, string patch)
{
  int patch_id, pvss_id;
  int base_id, host_id;
      
  fwInstallationDB_isPvssPatchRegistered(patch, version, os, patch_id, pvss_id);
  fwInstallationDB_isPvssBaseRegistered(host, version, os, base_id, pvss_id, host_id);
  
  dyn_mixed record;
  record[1] = base_id;
  record[2] = patch_id;
  
  string sql = "update fw_sys_stat_pvss_setup SET valid_until = SYSDATE WHERE base_version_id = :1 AND patch_id  = :2";
  
  if(fwInstallationDB_execute(sql, record)) {fwInstallation_throw("fwInstallationDB_unregisterSetupPvssPatch() -> Could not execute the following SQL: " + sql); return -1;};

  return 0;  
}

/** This function checks if a patch is for a PVSS version in a host is registered in the System Configuration DB
  @param base_id DB index corresponding to the base PVSS version
  @param patch_id DB index identifying a patch
  @param setup_id DB index of the PVSS setup where the patch is registered. -1 if the patch is not registered in the PVSS setup
  @return 0 if OK, -1 if errors
*/

int fwInstallationDB_isPvssSetupEntryRegistered(int base_id, int patch_id, int &setup_id)
{
  //GetCache1
  dyn_string parameters = makeDynString(base_id, patch_id);
  if( fwInstallationDBCache_getCache("_isPvssSetupEntryRegistered", parameters, setup_id) == 0 ) {
  	return 0;
  }
  //EndGetCache1

  dyn_string exceptionInfo;
  dyn_dyn_mixed aRecords;

  dynClear(aRecords);
  
  dyn_mixed var;
  var[1] = base_id;     
  var[2] = patch_id;     

  string sql = "SELECT id FROM fw_sys_stat_pvss_setup WHERE base_version_id = :1 AND patch_id  = :2 AND valid_until IS NULL";  
  if(fwInstallationDB_executeQuery(sql, var, aRecords))
  {
    fwInstallation_throw("fwInstallation_isPvssSetupEntryRegistered() -> Could not execute the following SQL query: " + sql);
    return -1;
  }  

  if(dynlen(aRecords) > 0)   
    setup_id = aRecords[1][1];
  else
    setup_id = -1;
  
  //SetCache1
  if( fwInstallationDBCache_setCache("_isPvssSetupEntryRegistered", parameters, setup_id) == 0 ) {
  }
  //EndSetCache
  
  return 0;
}

/** This function registers all paths of the local project in the System Configuration DB
  @return 0 if OK, -1 if errors
*/
int fwInstallationDB_registerProjectPaths()
{
  int error = 0;
  string defaultInstallationPath;  
  dyn_string installationPaths;  
  dyn_string dbInstallationPaths;
  dyn_int dbInstallationPathsIds; 

  //Invalidate in DB all project paths:
  if(fwInstallationDB_deleteAllProjectPaths() != 0)
  {
    fwInstallation_throw("fwInstallationDB_registerProjectPaths() -> Could not delete previously defined project paths"); 
    return -1;    
  }
  
  
  fwInstallation_loadProjPaths(installationPaths);

  for(int i = 1; i <= dynlen(installationPaths); i++)
  {
    if(fwInstallationDB_registerInstallationPath(installationPaths[i], false) != 0){
      fwInstallation_throw("fwInstallationDB_registerProjectConfiguration() -> Failed to register FW Installation path "+ installationPaths[i]+ " in the DB. Proceeding with the next one now...");
      ++error;
    }
  }
  
  if(error) 
    return -1;

  return 0;
  
}

/** This function checks if a component is registered in the System Configuration DB
  @param component Name of the component
  @param version Version of the component
  @param project Project name
  @param hostname hostname
  @param component_id DB index identifying the component
  @param project_id DB index identifying the project
  @param projectComponentId DB index identifying the component in a project. -1 if the component is not registered in the project
  @return 0 if OK, -1 if errors
*/
int fwInstallationDB_isProjectComponentRegistered(string component, 
                                                  string version, 
                                                  string project, 
                                                  string hostname, 
                                                  int &component_id, 
                                                  int &project_id, 
                                                  int &projectComponentId)
{
  //GetCache1
  dyn_string parameters = makeDynString(component, version, project, hostname);
  if( fwInstallationDBCache_getCache("_isProjectComponentRegistered", parameters, component_id, "componentId" ) == 0 
  	&& fwInstallationDBCache_getCache("_isProjectComponentRegistered", parameters, project_id, "projectId" ) == 0 
	&& fwInstallationDBCache_getCache("_isProjectComponentRegistered", parameters, projectComponentId, "projCompId" ) == 0 
	) {
  	return 0;
  }
  //EndGetCache1

  string sql;
  dyn_string exceptionInfo;
  dyn_dyn_mixed aRecords;

  dynClear(aRecords);

  hostname = strtoupper(hostname);
    
  if(fwInstallationDB_isProjectRegistered(project_id, project, hostname) != 0 || fwInstallationDB_isComponentRegistered(component, version, component_id) != 0)
  {
    fwInstallation_throw("fwInstallationDB_isProjectComponentRegistered() -> Could not connect to the DB");
    project_id = -1;
    component_id = -1;
    return -1;
  }else if(project_id == -1 || component_id == -1){
    fwInstallation_throw("fwInstallationDB_isProjectComponentRegistered() -> Project: " + project + " in host: " + hostname + " or component " + component + " v." + version + " not registered in the DB.");
    project_id = -1;
    component_id = -1;
    return -1;
  }
  
  dyn_mixed var;
  var[1] = project_id;     
  var[2] = component_id;     
  var[3] = strtoupper(hostname);     
  
  sql = "SELECT id FROM fw_sys_stat_proj_install_comps WHERE valid_until IS NULL AND project_id = :1 AND component_id = :2 AND COMPUTER_ID = (SELECT ID FROM FW_SYS_STAT_COMPUTER WHERE VALID_UNTIL IS NULL AND HOSTNAME = :3)";
  if(fwInstallationDB_executeQuery(sql, var, aRecords))
  {
    fwInstallation_throw("fwInstallationDB_isProjectComponentRegistered() -> Could not execute the following SQL query: " + sql);
    return -1;
  }  

  if(dynlen(aRecords) > 0) 
     projectComponentId = aRecords[1][1];
  else
    projectComponentId = -1;

  //SetCache1
  if( fwInstallationDBCache_setCache("_isProjectComponentRegistered", parameters, component_id, "componentId" ) == 0 
  	&& fwInstallationDBCache_setCache("_isProjectComponentRegistered", parameters, project_id, "projectId" ) == 0 
	&& fwInstallationDBCache_setCache("_isProjectComponentRegistered", parameters, projectComponentId, "projCompId" ) == 0 
	) {
  }
  //EndSetCache
  
  return 0;
}

/** This function registers all components installed in a project in the System Configuration DB
  @param project project name
  @param hostname hostname
  @return 0 if OK, -1 if errors
*/
int fwInstallationDB_registerProjectFwComponents(string project = "", string hostname = "")
{
  int projectComponentId;
  int project_id;
  int component_id;
  dyn_string exceptionInfo;
  dyn_dyn_mixed aRecords;
  string sql;

  string defaultInstallationPath;  
  int error = 0;
  dyn_dyn_string componentsInfo;
  
  dyn_string componentNames;
  dyn_string componentVersions;
  dyn_string componentInstDirs;
  dyn_string componentDescFiles;
  dyn_int componentInstallationOK;
  dyn_int componentDependenciesOK;
  dyn_string componentPendingPostinstalls;
  
  bool isSubComponent;
  dyn_bool isSubComponentArray;

  dyn_string installationPaths;
  
  dyn_string dbInstallationPaths;
  dyn_int dbInstallationPathsIds; 
  dyn_dyn_mixed instComponents;
  dyn_dyn_mixed toBeRemovedComponents;
  
  bool found = false;
  bool update = false;
          
  dynClear(aRecords);
  dynClear(isSubComponentArray);
  
  if(project == "")
    project = PROJ;
  
  if(hostname == ""){
    hostname = fwInstallation_getHostname();    
  }

  hostname = strtoupper(hostname);  
  
  fwInstallation_getInstalledComponents(componentsInfo);
  fwInstallationDB_getCurrentProjectComponents(instComponents);
  for(int i = 1; i <= dynlen(componentsInfo); i++)
  {
    projectComponentId = -1;
    componentNames[i] = componentsInfo[i][1]; 
    componentVersions[i] = componentsInfo[i][2];
    componentInstDirs[i] = componentsInfo[i][3];
    componentDescFiles[i] = componentsInfo[i][4];
    componentInstallationOK[i] = componentsInfo[i][5];
    componentDependenciesOK[i] = componentsInfo[i][6];
    
    if(dynlen(componentsInfo[i]) < 7)//make sure we always get at least 7 elements
      componentsInfo[i][7] = "";
    
    componentPendingPostinstalls[i] = componentsInfo[i][7];
    
    found = false;
    update = false;
    for(int j = 1; j <= dynlen(instComponents); j++)
    {
      if(instComponents[j][1] == componentNames[i] && instComponents[j][2] == componentVersions[i])
      {
        //Component found => It is already register in DB. Nothing to be done.
        found = true;
        //Clear this component from instComponents array so that it is not removed at the end of the function:
        instComponents[j][1] = "";
        instComponents[j][2] = "";
                               
        //Check here if component needs to be updated:
        if(instComponents[j][FW_INSTALLATION_DB_COMPONENT_INSTALLATION_NOT_OK_IDX] != componentsInfo[i][5] ||
           instComponents[j][FW_INSTALLATION_DB_COMPONENT_DEPENDENCIES_OK_IDX] != componentsInfo[i][6] ||
           instComponents[j][FW_INSTALLATION_DB_COMPONENT_PENDING_POSTINSTALLS_IDX] != componentsInfo[i][7])
        {
//          if(instComponents[j][FW_INSTALLATION_DB_COMPONENT_INSTALLATION_NOT_OK_IDX] != componentsInfo[i][5])
            update = true;
        }
        break;
      }
    }  
    
    if(update)
    {
      if(fwInstallationDB_isProjectComponentRegistered(componentNames[i], componentVersions[i], project, hostname, component_id, project_id, projectComponentId) != 0)
      {
        fwInstallation_throw("fwInstallationDB_registerProjectFwComponents() -> Could not access the DB");
        return -1;    
      }

      dyn_mixed record;
      record[1] = componentInstallationOK[i];
      record[2] = componentDependenciesOK[i];
      record[3] = componentPendingPostinstalls[i];
      record[4] = component_id;
      record[5] = project_id;
      record[6] = hostname;
            
      sql = "UPDATE fw_sys_stat_proj_install_comps SET installation_ok = :1, dependencies_ok = :2, pending_postinstalls = :3 "+
            "WHERE component_id = :4 AND project_id = :5 AND computer_id = (select id from fw_sys_stat_computer where valid_until is null and hostname = :6)";
      if(fwInstallationDB_execute(sql, record, false)) {fwInstallation_throw("fwInstallationDB_registerProjectFwComponents() -> Could not execute the following SQL: " + sql); return -1;};
  }
  
    if(!found)
    {
      string dp = fwInstallation_getComponentDp(componentNames[i]);
      dpGet(dp + ".isItSubComponent", isSubComponent);
      isSubComponentArray[i] = isSubComponent;
        
      //Register component in DB if not yet done
      if(fwInstallationDB_registerComponent(componentNames[i], componentVersions[i], isSubComponent) != 0){
        fwInstallation_throw("fwInstallationDB_registerProjectConfiguration() -> Failed to register FW component "+ componentNames[i]+ " v." + componentVersions[i]);
        ++error;
      }
      if(fwInstallationDB_isProjectComponentRegistered(componentNames[i], componentVersions[i], project, hostname, component_id, project_id, projectComponentId) != 0)
      {
        fwInstallation_throw("fwInstallationDB_registerProjectFwComponents() -> Could not access the DB");
        return -1;    
      }
    
      if(projectComponentId > 0){
        continue;  //nothing to be done
      }else {
        int host_id = -1;
        fwInstallationDB_isPCRegistered(host_id, strtoupper(hostname));
        
        dyn_mixed record;
        record[1] = component_id;
        record[2] = project_id;
        record[3] = componentDescFiles[i];
        record[4] = componentInstDirs[i];
        record[5] = componentInstallationOK[i];
        record[6] = host_id;
                
         sql = "INSERT INTO fw_sys_stat_proj_install_comps (id, component_id, project_id, installation_date, description_file, installation_path, installation_ok, computer_id) VALUES " 
               + " (fw_sys_stat_proj_inst_comp_sq.nextval, :1, :2, SYSDATE, :3, :4, :5, :6)";
       
         if(fwInstallationDB_execute(sql, record)) {fwInstallation_throw("fwInstallationDB_registerProjectFwComponents() -> Could not execute the following SQL: " + sql); return -1;};
      }
    }
  }
  
  //loop now over the components that were not found and unregister them from the DB:
  for(int j = 1; j <= dynlen(instComponents); j++)
  {
    if( instComponents[j][1] == "")
      continue;
 
    fwInstallationDB_unregisterCurrentProjectComponent(instComponents[j][1], instComponents[j][2]);
  }

  return 0;
}
  
/** This function unregisters a component in a project from the System Configuration DB
  @param component name of the component
  @param version version of the component
  @param project project name
  @param host hostname
  @return 0 if OK, -1 if errors
*/
int fwInstallationDB_unregisterCurrentProjectComponent(string component, 
                                                       string version, 
                                                       string project = "", 
                                                       string host = "")
{
  int project_id = -1;
  int component_id = -1;
  string sql;
    
  dyn_string exceptionInfo;
  dyn_dyn_mixed aRecords;
  
  dynClear(exceptionInfo);
  
  if(project == "")
    project = PROJ;
  
  if(host == ""){
    host = fwInstallation_getHostname();    
  }  
 
  host = strtoupper(host);
  
  //Check if already exists:
  if(fwInstallationDB_isProjectRegistered(project_id, project, host) != 0)
  {
    fwInstallation_throw("fwInstallation_unregisterCurrentProjectComponent() -> Cannot access the DB.");
    return -1;
  }
  
  if(fwInstallationDB_isComponentRegistered(component, version, component_id) != 0)
  {
    fwInstallation_throw("fwInstallation_unregisterCurrentProjectComponent() -> Cannot access the DB.");
    return -1;
  }
  
  dyn_mixed record;
  record[1] = project_id;
  record[2] = component_id;
  record[3] = strtoupper(host);
  
  sql = "update FW_SYS_STAT_PROJ_INSTALL_COMPS set valid_until = sysdate where project_id = :1 and component_id = :2 and computer_id = (select id from fw_sys_stat_computer where valid_until is null and hostname = :3)";
  
  if(fwInstallationDB_execute(sql, record)) {fwInstallation_throw("fwInstallationDB_unregisterProjectManager() -> Could not execute the following SQL: " + sql); return -1;};

  return 0;  
}


/** This function registers all managers of the local project in the System Configuration DB
  @return 0 if OK, -1 if errors
*/

int fwInstallationDB_registerProjectManagers()
{
  int error = 0;
  dyn_dyn_mixed managersInfo;
  
  fwInstallationManager_getAllInfoFromPvss(managersInfo);
  for(int i = 1; i <= dynlen(managersInfo); i++){
    error += fwInstallationDB_registerProjectManager(managersInfo[i]);
  }
  
  if(error) 
    return -1;
  else
    return 0;

}

/** This function executes a simple SQL sentence
  (Deprecated? - orphan method in fwi6.0.2)
  @param sql SQL command to be executed
  @return 0 if OK, -1 if errors
*/
int fwInstallationDB_executeSqlSimple(string sql)
{
  //The command may change things on the database, we will want the cache to be reloaded
//  fwInstallationDBCache_clear();

  // fix for executing PL/SQL statements - they need to contain semicolon after the "END" statement
  if (substr(strltrim(strtoupper(sql)),0,5)=="BEGIN") {
  	sql=strrtrim(sql);// trim whitespaces
  	sql=strrtrim(sql,";"); // trim all semicolons that exist
  	sql=sql+";"; // add a single semicolon
  }

  int rc=rdbExecuteSqlStatement(gFwInstallationDBConn, sql);
  if (rc<0) {
  	fwInstallation_throw("Cannot execute SQL Statement - invalid dbConnection");
  	return -1;
  } else if (rc==1){
  	string errTxt;
    	rdbCheckError(errTxt, gFwInstallationDBConn);
  	  fwInstallation_throw("Cannot execute SQL statement. Error code: " + errTxt);
  	  return -1;
  }
  
  return 0;
}



/** executes SQL statements stored in a file
 (Deprecated? orphan method in fwi6.0.2) 
 *
 * Note that the all commands in the file should be terminated by the semicolon (;)
 * character, which should be the last characted in the line.
 * The comments (lines starting with "-" character) and white-spaces are a
 * also automatically removed.
 *
 * @param fileName          the name of the file, where the SQL statements are stored.
 *                          The file needs to be in the "config" directory of the project.
 * @param breakOnDbError    (optional, default is TRUE) determines if the function should
 *                          return terminate with an exception upon first encountered error,
 *                          or it should rather try to finish the remaining commands
 *                          (the errors encountered in a meantime will be reported at the end).
*/
int fwInstallationDB_executeSqlFromFile( string fileName,
                                         bool breakOnDbError=TRUE)
{
  //The command may change things on the database, we will want the cache to be reloaded
//  fwInstallationDBCache_clear();

  string sqlFile=getPath(CONFIG_REL_PATH, fileName);

  string sSql; // all statements in one string
  bool ok=fileToString(sqlFile,sSql);
  if (!ok) {
    fwInstallation_throw("The PL/SQL file "+ fileName + " cannot be opened");
    return -1;
  }

  dyn_string sql;
  dyn_string sqlLines=strsplit(sSql,"\n");
  string stmt="";
  int PlSqlBlock=0;
  for (int i=1;i<=dynlen(sqlLines);i++){
    string line = sqlLines[i];
    if (strltrim(strrtrim(line))=="") continue; // skip empty lines

    if (line[0]=="-") continue; // skip comments

    stmt+=line+"\n";

    // PL/SQL package begins...
    if (
	 (strpos(strtoupper(line),"PACKAGE")>=0)&&
	 (strpos(strtoupper(line),"CREATE")>=0)
	) PlSqlBlock++;
    // "anonymous" PL/SQL block ahead:
    if ((PlSqlBlock==0) && (strpos(strtoupper(line),"BEGIN")>=0)) PlSqlBlock++;
    if ((PlSqlBlock==0) && (strpos(strtoupper(line),"DECLARE")>=0)) PlSqlBlock++;
    // end of PL/SQL block marked by "END" and double semicolon,
    // or the "/" character at the beginning of the line
    if ((PlSqlBlock>0) &&
        (strpos(strtoupper(line),"END")>=0) &&
        (strpos(line,";;")>=0)
      ) {
      PlSqlBlock--;
    }
    if ((PlSqlBlock>0) && (strpos(line,"/")==0) ){
      // terminate immediately, strip the "/", and the newline, replace ";" with ";;"
      PlSqlBlock=0;
      stmt=strrtrim(stmt,"/ \n ;");
      stmt=strrtrim(stmt);
      stmt+=";;"; // append the double semicolon, so the processing below works OK!
      dynAppend(sql,stmt);
      stmt="";
      continue;
    }


    if (PlSqlBlock==0) {
       // we do not interpret what we have inside...

      if (line[strlen(line)-1]==";") {
        // statement is complete!
        dynAppend(sql,stmt);
        stmt="";
        continue;
      }

    }
  }
    // commit previous transaction...
    rdbCommitTransaction(gFwInstallationDBConn);
    int rc=rdbBeginTransaction(gFwInstallationDBConn);
    if (rc) {
	   //bool invalidConnection;
	   //_fwConfigurationDB_catchDbError(dbCon, invalidConnection, exceptionInfo);
	   fwInstallation_throw("Cannot start transaction");
	   return -1;
    };

    for (int i=1;i<=dynlen(sql);i++) {
	string stmt=strrtrim(sql[i]); // trim trailing spaces, endlines, etc
	int len=strlen(stmt);
	if (stmt[len-1]==";") stmt=substr(stmt,0,len-1); // trim the last semicolon at the end; only the last!!!
        dyn_string localExceptionInfo;
        int err = fwInstallationDB_executeSqlSimple(stmt);
        if (err && breakOnDbError) {
//            dynAppend(exceptionInfo,localExceptionInfo);
            rdbRollbackTransaction (gFwInstallationDBConn);
            return -1;
        };
    };

    rc=rdbCommitTransaction(gFwInstallationDBConn);
    // save the hierarchy...
    if (rc) {
	    bool invalidConnection;
	    //_fwConfigurationDB_catchDbError(dbCon, invalidConnection, exceptionInfo);
	    fwInstallation_throw("Cannot commit transaction","");
	    return -1;
    };
    
  return 0;
}

/** This function retrieves all hosts information from the System Configuration DB
  @param hostsInfo information for all hosts registered in the DB as a dyn_dyn_mixed matrix
  @return 0 if OK, -1 if errors
*/
int fwInstallationDB_getHostsInfo(dyn_dyn_mixed &hostsInfo)
{
  //GetCache1
  dyn_string parameters = makeDynString();
  if( fwInstallationDBCache_getCache("_getHostsInfo", parameters, hostsInfo) == 0 ) {
  	return 0;
  }
  //EndGetCache1

  dyn_string exceptionInfo;
  string sql;
  dyn_dyn_mixed aRecords;
  
  dynClear(exceptionInfo);
  dynClear(aRecords);  

  dyn_mixed var;
  sql = "SELECT hostname, ip, mac, ip2, mac2, bmc_ip, bmc_user, bmc_pwd, fmc_enable_ipmi, bmc_name, fmc_enable_monitoring, fmc_monitoring_level, fmc_enable_tm, fmc_enable_logger, id, location, description, fmc_os, fmc_ipmi_master, fmc_enable_process_monitoring, fmc_win_procs_controller  FROM fw_sys_stat_computer WHERE VALID_UNTIL IS NULL";

  if(fwInstallationDB_executeQuery(sql, var, aRecords))
  {
    fwInstallation_throw("fwInstallationDB_getHostsInfo() -> Could not execute the following SQL query: " + sql);
    return -1;
  }  

  hostsInfo = aRecords;
  
  //SetCache1
  if( fwInstallationDBCache_setCache("_getHostsInfo", parameters, hostsInfo) == 0 ) {
  }
  //EndSetCache
  
  return 0;
}


/** This function retrives the hosts properties from the DB
  @param hostnames list of hostnames 
  @param ips list of IP addresses
  @param macs list of MAC addresses
  @param ips2 list of second IP addresses
  @param macs2 list of second MAC addresses
  @param bmc_ips list of IP addresses of the BMC (IPMI)
  @param bmc_ips2 list of second IP addresses of the BMC (IPMI)
  @return 0 if OK, -1 if errors
*/
int fwInstallationDB_getHosts(dyn_string &hostnames, 
                              dyn_string &ips, 
                              dyn_string &macs, 
                              dyn_string &ips2, 
                              dyn_string &macs2, 
                              dyn_string &bmc_ips, 
                              dyn_string &bmc_ips2)
{
  //GetCache1
  dyn_string parameters = makeDynString();
  if( fwInstallationDBCache_getCache("_getHosts", parameters, hostnames, "hostnames") == 0 
  	&& fwInstallationDBCache_getCache("_getHosts", parameters, ips, "ips") == 0 
	&& fwInstallationDBCache_getCache("_getHosts", parameters, macs, "macs") == 0 
	&& fwInstallationDBCache_getCache("_getHosts", parameters, ips2, "ips2") == 0 
	&& fwInstallationDBCache_getCache("_getHosts", parameters, macs2, "macs2") == 0 
	&& fwInstallationDBCache_getCache("_getHosts", parameters, bmc_ips, "bmc_ips") == 0 
	&& fwInstallationDBCache_getCache("_getHosts", parameters, bmc_ips2, "bmc_ips2") == 0 
	) {
  	return 0;
  }
  //EndGetCache1

  //fwInstallation_flagDeprecated("fwInstallationDB_getHosts", "fwInstallationDB_getHostsInfo");

  dyn_string exceptionInfo;
  string sql;
  dyn_dyn_mixed aRecords;
  
  dynClear(exceptionInfo);
  dynClear(aRecords);  

  dyn_mixed var;
  sql = "SELECT hostname, ip, mac, ip2, mac2, bmc_ip, bmc_ip2 FROM fw_sys_stat_computer where valid_until is null order by hostname";
  if(fwInstallationDB_executeQuery(sql, var, aRecords))
  {
    fwInstallation_throw("fwInstallationDB_getHosts() -> Could not execute the following SQL query: " + sql);
    return -1;
  }  

  for(int i = 1; i <= dynlen(aRecords); i++) {   
    dynAppend(hostnames, strtoupper(aRecords[i][1]));
    dynAppend(ips, aRecords[i][2]);
    dynAppend(macs, aRecords[i][3]);
    dynAppend(ips2, aRecords[i][4]);
    dynAppend(macs2, aRecords[i][5]);
    dynAppend(bmc_ips, aRecords[i][6]);
    dynAppend(bmc_ips2, aRecords[i][7]);
  }
  
  //SetCache1
  if( fwInstallationDBCache_setCache("_getHosts", parameters, hostnames, "hostnames") == 0 
  	&& fwInstallationDBCache_setCache("_getHosts", parameters, ips, "ips") == 0 
	&& fwInstallationDBCache_setCache("_getHosts", parameters, macs, "macs") == 0 
	&& fwInstallationDBCache_setCache("_getHosts", parameters, ips2, "ips2") == 0 
	&& fwInstallationDBCache_setCache("_getHosts", parameters, macs2, "macs2") == 0 
	&& fwInstallationDBCache_setCache("_getHosts", parameters, bmc_ips, "bmc_ips") == 0 
	&& fwInstallationDBCache_setCache("_getHosts", parameters, bmc_ips2, "bmc_ips2") == 0 
	) {
  }
  //EndSetCache
  
  return 0;
}

/** This function retrieves the list of PVSS systems registered in the System Configuration DB
  @param systemsInfo information about all PVSS systems as a dyn_dyn_mixed
  @param onlyActive if true, ignores all history
  @return 0 if OK, -1 if errors
*/
int fwInstallationDB_getPvssSystems(dyn_dyn_mixed &systemsInfo, bool onlyActive = true)
{
  //GetCache1
  dyn_string parameters = makeDynString(onlyActive);
  if( fwInstallationDBCache_getCache("_getPvssSystems", parameters, systemsInfo) == 0 ) {
  	return 0;
  }
  //EndGetCache1

  dyn_string exceptionInfo;
  string sql;
  dyn_dyn_mixed aRecords;
  
  dynClear(exceptionInfo);
  dynClear(aRecords);  

  dyn_mixed var;
  
  if(onlyActive)
    sql = "SELECT system_name, system_number FROM fw_sys_stat_pvss_system WHERE valid_until IS NULL";
  else
    sql = "SELECT system_name, system_number FROM fw_sys_stat_pvss_system";
  
  if(fwInstallationDB_executeQuery(sql, var, aRecords))
  {
    fwInstallation_throw("fwInstallationDB_getPvssSystems() -> Could not execute the following SQL query: " + sql);
    return -1;
  }  
  
  systemsInfo = aRecords;
    
  //SetCache1
  if( fwInstallationDBCache_setCache("_getPvssSystems", parameters, systemsInfo) == 0 ) {
  }
  //EndSetCache
  
  return 0;
}

/** This function checks if a component has be registered as a subcomponent in the System Configuration DB
  @param component name of the component
  @param version version of the component
  @param isSubComponent if 1 the component is a subcomponent
  @return 0 if OK, -1 if errors
*/
int fwInstallationDB_getComponentProperties(string component, 
                                            string version, 
                                            int &isSubComponent)//, int &isOfficial, string &defaultPath)
{  
  //GetCache1
  dyn_string parameters = makeDynString(component, version);
  if( fwInstallationDBCache_getCache("_getComponentProperties", parameters, isSubComponent) == 0 ) {
  	return 0;
  }
  //EndGetCache1

  dyn_string exceptionInfo;
  string sql;
  dyn_dyn_mixed aRecords;
  int component_id;
  
  dynClear(exceptionInfo);
  dynClear(aRecords);  
  if(fwInstallationDB_isComponentRegistered(component, version, component_id) != 0)
  {
    fwInstallation_throw("fwInstallationDB_getComponentProperties() -> Cannot access the DB");
    return -1;
  }else if(component_id < 0)
  {
    fwInstallation_throw("fwInstallationDB_getComponentProperties() -> Component: " + component + " version" + version + " is not registered in the DB.");
    return -1;
  }  
  else{
    dyn_mixed var;
    var[1] = component_id;     

    sql = "SELECT is_subcomponent FROM fw_sys_stat_component WHERE id = :1";
    if(fwInstallationDB_executeQuery(sql, var, aRecords))
    {
      fwInstallation_throw("fwInstallationDB_getComponentProperties()() -> Could not execute the following SQL query: " + sql);
      return -1;
    }  
    if(dynlen(aRecords[1]) > 0){
    
    isSubComponent = aRecords[1][1];
    }
  }

  //SetCache1
  if( fwInstallationDBCache_setCache("_getComponentProperties", parameters, isSubComponent) == 0 ) {
  }
  //EndSetCache
  
  return 0;  
}

/** This function retrieves the information about all components registered in the System Configuration DB
  @param componentsInfo components information as a dyn_dyn_mixed
  @return 0 if OK, -1 if errors
*/
int fwInstallationDB_getAllComponents(dyn_dyn_mixed &componentsInfo)
{  
  //GetCache1
  dyn_string parameters = makeDynString();
  if( fwInstallationDBCache_getCache("_getAllComponents", parameters, componentsInfo) == 0 ) {
  	return 0;
  }
  //EndGetCache1

  dyn_string exceptionInfo;
  string sql;
  dyn_dyn_mixed aRecords;
  int component_id;
  
  dynClear(exceptionInfo);
  dynClear(aRecords);  

  dyn_mixed var;
  
  sql = "SELECT component_name, component_version FROM fw_sys_stat_component WHERE valid_until is null order by component_name, component_version";
  if(fwInstallationDB_executeQuery(sql, var, aRecords))
  {
    fwInstallation_throw("fwInstallationDB_getAllComponents() -> Could not execute the following SQL query: " + sql);
    return -1;
  }  
    
  componentsInfo = aRecords;

  //SetCache1
  if( fwInstallationDBCache_setCache("_getAllComponents", parameters, componentsInfo) == 0 ) {
  }
  //EndSetCache
  
  return 0;  
}


/** This function retrieves the properties of a host from the System Configuration DB
  @param hostname name of the host
  @param hostInfo host properties as a dyn_mixed
  @return 0 if OK, -1 if errors
*/
int fwInstallationDB_getHostProperties(string hostname, dyn_mixed &hostInfo)
{
  //GetCache1
  dyn_string parameters = makeDynString(hostname);
  if( fwInstallationDBCache_getCache("_getHostProperties", parameters, hostInfo) == 0 ) {
  	return 0;
  }
  //EndGetCache1

  dyn_string exceptionInfo;
  string sql;
  dyn_dyn_mixed aRecords;
  
  dynClear(exceptionInfo);
  dynClear(aRecords);  

  hostname = strtoupper(hostname);

  dyn_mixed var;
  var[1] = hostname;  
  
  sql = "SELECT hostname, ip, mac, ip2, mac2, bmc_ip, bmc_user, bmc_pwd, fmc_enable_ipmi, " +
                "bmc_name, fmc_enable_monitoring, fmc_monitoring_level, fmc_enable_tm, fmc_enable_logger, " +
                "id, fmc_enable_process_monitoring, fmc_win_procs_controller, location, description, fmc_os, " + 
                "fmc_ipmi_master, fmc_enable_archiving, fmc_enable_alarms FROM fw_sys_stat_computer WHERE hostname = :1";
       
  if(fwInstallationDB_executeQuery(sql, var, aRecords))
  {
    fwInstallation_throw("fwInstallationDB_getHosts() -> Could not execute the following SQL query: " + sql);
    return -1;
  }

  
  if(dynlen(aRecords) > 0) {   
    hostInfo = aRecords[1];
  }
  
  //SetCache1
  if( fwInstallationDBCache_setCache("_getHostProperties", parameters, hostInfo) == 0 ) {
  }
  //EndSetCache
  
  return 0;
}

/** This function sets the properties of a host in the System Configuration DB
  @param hostname Name of the host
  @param hostInfo Host properties as a dyn_mixed array
  @return 0 if OK, -1 if errors
*/
int fwInstallationDB_setHostProperties(string hostname, dyn_mixed hostInfo)
{
  dyn_string exceptionInfo;
  string sql;
  dyn_dyn_mixed aRecords;
  int pcId;
  string ip, ip2, mac, mac2, bmcip, bmcuser, bmcpwd;
  
  dynClear(exceptionInfo);
  dynClear(aRecords);  

  hostname = strtoupper(hostname);
  
  if(dynlen(hostInfo) >= FW_INSTALLATION_DB_HOST_IP_1_IDX)
    ip = hostInfo[FW_INSTALLATION_DB_HOST_IP_1_IDX];    
  
  if(dynlen(hostInfo) >= FW_INSTALLATION_DB_HOST_IP_2_IDX)
    ip2 = hostInfo[FW_INSTALLATION_DB_HOST_IP_2_IDX];    
  
  if(dynlen(hostInfo) >= FW_INSTALLATION_DB_HOST_MAC_1_IDX)
    mac = hostInfo[FW_INSTALLATION_DB_HOST_MAC_1_IDX];    
  
  if(dynlen(hostInfo) >= FW_INSTALLATION_DB_HOST_MAC_2_IDX)
    mac2 = hostInfo[FW_INSTALLATION_DB_HOST_MAC_2_IDX];    
  
  if(dynlen(hostInfo) >= FW_INSTALLATION_DB_HOST_BMC_IP_IDX)
    bmcip = hostInfo[FW_INSTALLATION_DB_HOST_BMC_IP_IDX];    
  
  if(dynlen(hostInfo) >= FW_INSTALLATION_DB_HOST_BMC_USER_IDX)
    bmcuser = hostInfo[FW_INSTALLATION_DB_HOST_BMC_USER_IDX];    
  
  if(dynlen(hostInfo) >= FW_INSTALLATION_DB_HOST_BMC_PWD_IDX)
    bmcpwd = hostInfo[FW_INSTALLATION_DB_HOST_BMC_PWD_IDX];    
  

///
  int enableIpmi;
  int enableLogger;
  int enableTm;
  int enableMonitoring;
  int enableProcesses;
  int monitoringLevel;
  string winProcsController, ipmiName, ipmiMaster, description, location, fmcOs;
  string archiving;
  int alarms;

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
/// 
  
  if(fwInstallationDB_isPCRegistered(pcId,  hostname) != 0){
    fwInstallation_throw("fwInstallationDB_setHostProperties() -> Could not access the DB");
    return -1;  
  }else if(pcId == -1){
    if(fwInstallationDB_registerPC(hostname, 
                                   hostInfo) != 0)
    {
      fwInstallation_throw("fwInstallationDB_setHostProperties() -> Could not force registration of host: " + hostname + " in DB");
      return -1;
    }
    
    fwInstallationDB_isPCRegistered(pcId,  hostname);

    if(pcId == -1)
    {
      fwInstallation_throw("fwInstallationDB_setHostProperties() -> Host: " + hostname + " not yet registered in DB");
      return -1;  
    }
  }
  dyn_mixed record;
  record[1] = ip;
  record[2] = mac;
  record[3] = ip2;
  record[4] = mac2;
  record[5] = bmcip;
  record[6] = bmcuser;
  record[7] = bmcpwd;
  record[8] = fmcOs;
  record[9] = enableIpmi;
  record[10] = enableMonitoring;
  record[11] = enableProcesses;
  record[12] = enableTm;
  record[13] = enableLogger;
  record[14] = monitoringLevel;
  record[15] = ipmiName;
  record[16] = ipmiMaster;
  record[17] = location;
  record[18] = description;
  record[19] = winProcsController;
  record[20] = alarms;
  record[21] = archiving;
  record[22] = hostname;
    
  sql = "UPDATE fw_sys_stat_computer SET ip = :1, mac = :2, ip2 = :3, mac2 = :4, bmc_ip = :5, bmc_user = :6, bmc_pwd = :7, fmc_os = :8, " + 
        "fmc_enable_ipmi = :9, fmc_enable_monitoring = :10, fmc_enable_process_monitoring = :11, fmc_enable_tm = :12, fmc_enable_logger = :13, " + 
        "fmc_monitoring_level = :14, bmc_name = :15, fmc_ipmi_master = :16, location = :17, description = :18, " + 
        "fmc_win_procs_controller = :19, fmc_enable_alarms = :20, fmc_enable_archiving = :21 " + 
        "WHERE hostname = :22";
    
  if(fwInstallationDB_execute(sql, record)) {fwInstallation_throw("fwInstallationDB_setHostProperties() -> Could not execute the following SQL: " + sql); return -1;};
  return 0;
}

/** This function checks if a project is centrally managed from the System Configuration DB
  @return 1 if centrally managed, 0 if locally managed
*/
int fwInstallationDB_getCentrallyManaged(string project = "", string host = "")
{
 int centrallyManaged;
 if(project == "")
   project = PROJ;
 if(host == "")
   host = strtoupper(fwInstallation_getHostname());
 
 fwInstallationDB_getProjectManagementMode(centrallyManaged, project, host);
     
 return centrallyManaged;
  
  
}

/** This function sets the centrally managed property of a project in the System Configuration DB
  @param centrallyManaged 1 if the project is centrally managed. 0 if locally managed
  @param project project name
  @param hostname hostname
  @return 0 if OK, -1 if errors
*/
int fwInstallationDB_setNeedsSynchronize(bool needSynchronize, string project = "", string hostname = "")
{
  int project_id;
  dyn_string exceptionInfo;
  dyn_dyn_mixed aRecords;
  string sql;

  dynClear(aRecords);

  if(project == "")
    project = PROJ;
  
  if(hostname == "")
    hostname = fwInstallation_getHostname();
  
  hostname = strtoupper(hostname);
  
  if(fwInstallationDB_isProjectRegistered(project_id, project, hostname) != 0)
  {
    fwInstallation_throw("fwInstallationDB_setNeedsSynchronize() -> Could not access the DB");
    return -1;
  }else{        
        dyn_mixed record;
        if( needSynchronize ) 
          record[1] = 'Y';
        else 
          record[1] = 'N';
        record[2] = project_id;
        
        sql = "UPDATE fw_sys_stat_pvss_project SET NEED_SYNCHRONIZE = :1 WHERE id = :2";
        if(fwInstallationDB_execute(sql, record, false)) {fwInstallation_throw("fwInstallationDB_setNeedsSynchronize() -> Could not execute the following SQL: " + sql); return -1;};
    }
  return 0;
}



/** This function sets the centrally managed property of a project in the System Configuration DB
  @param centrallyManaged 1 if the project is centrally managed. 0 if locally managed
  @param project project name
  @param hostname hostname
  @return 0 if OK, -1 if errors
*/
int fwInstallationDB_setCentrallyManaged(int centrallyManaged, string project = "", string hostname = "")
{
  int project_id;
  dyn_string exceptionInfo;
  dyn_dyn_mixed aRecords;
  string sql;

  dynClear(aRecords);

  if(project == "")
    project = PROJ;
  
  if(hostname == "")
    hostname = fwInstallation_getHostname();
  
  hostname = strtoupper(hostname);
  
  if(fwInstallationDB_isProjectRegistered(project_id, project, hostname) != 0)
  {
    fwInstallation_throw("fwInstallationDB_setCentrallyManaged() -> Could not access the DB");
    return -1;
  }else{        
        dyn_mixed record;
        record[1] = centrallyManaged;
        record[2] = project_id;
        
        sql = "UPDATE fw_sys_stat_pvss_project SET centrally_managed = :1 WHERE id = :2";
        if(fwInstallationDB_execute(sql, record)) {fwInstallation_throw("fwInstallationDB_setCentrallyManaged() -> Could not execute the following SQL: " + sql); return -1;};
    }
  
  return 0;
}

/** This function retrieves the project management mode
  @param isCentrallyManaged flag indicating if the project is centrally managed (1). 0 if locally managed
  @param project project name
  @param hostname hostname
  @return 0 if OK, -1 if errors
*/
int fwInstallationDB_getProjectManagementMode(bool &isCentrallyManaged, string project = "", string hostname = "")
{
  
  dyn_mixed projectProperties;
  int projectId;
  
  if(project == "")
    project = PROJ;
  
  if(hostname == "")
    hostname = fwInstallation_getHostname();
  
  hostname = strtoupper(hostname);
 
  if(fwInstallationDB_getProjectProperties(project, hostname, projectProperties, projectId) != 0)
  {
    fwInstallation_throw("fwInstallationDB_getProjectManagementMode() -> Could not retrieve project properties from the DB.");
    return -1;
  }
  
  if(projectId > 0)    
    isCentrallyManaged = projectProperties[FW_INSTALLATION_DB_PROJECT_CENTRALLY_MANAGED];  
  else{
    return -1;
  }
  
  return 0; 
}


/** This function retrieves the project properties from the System Configuration DB
  @param project project name
  @param hostname name of the host
  @param projectProperties Project properties as a dyn_mixed array
  @param projectId DB index of the project
  @return 0 if OK, -1 if errors
*/
int fwInstallationDB_getProjectProperties(string project, 
                                          string hostname, 
                                          dyn_mixed &projectProperties, 
                                          int &projectId)
{
  //GetCache1
  dyn_string parameters = makeDynString(project, hostname);
  if( fwInstallationDBCache_getCache("_getProjectProperties", parameters, projectProperties, "properties") == 0 
  	&& fwInstallationDBCache_getCache("_getProjectProperties", parameters, projectId, "projectId") == 0
	) {
  	return 0;
  }
  //EndGetCache1

  dyn_string exceptionInfo;
  string sql;
  dyn_dyn_mixed aRecords;
  
  dynClear(exceptionInfo);
  dynClear(aRecords);  
  dynClear(projectProperties);  
  
  hostname = strtoupper(hostname);
  
  if(fwInstallationDB_isProjectRegistered(projectId, project, hostname) != 0)
  {
     fwInstallation_throw("fwInstallationDB_getProjectProperties() -> Could not retrive information from the DB."); 
     return -1;
  }
  
  if(projectId == -1){
    dynClear(projectProperties);
    return 0;
  }
  
  dyn_mixed var;
  var[1] = project;  
  var[2] = hostname;  
  
  sql = "SELECT p.project_name, c.hostname, p.project_dir, s.system_name, s.system_number, p.pmon_port, p.pmon_username, p.pmon_password, " +
    	   "p.fw_inst_tool_version, p.centrally_managed, p.pvss_version, s.data_port, s.event_port, s.dist_port, p.os, " +	   
    	   "p.is_project_ok, p.is_pvss_ok, p.is_host_ok, p.is_path_ok, p.is_manager_ok, p.is_group_ok, p.is_component_ok, p.is_ext_process_ok, " +
    	   "p.last_time_checked, p.system_overview, p.upgrade, NULL, h.hostname, p.delete_files, p.inst_tool_status, s.redu_port, s.split_port " +
        "FROM fw_sys_stat_pvss_project p, fw_sys_stat_pvss_system s, fw_sys_stat_computer c, fw_sys_stat_computer h " +
        "WHERE (p.computer_id = c.id or p.redu_computer_id = c.id) and p.valid_until is null and s.valid_until is null and p.project_name = :1 AND S.COMPUTER_ID = H.ID AND p.system_id = s.id AND c.hostname = :2 AND " +
        "s.id = (select system_id from fw_sys_stat_pvss_project where valid_until is null and project_name = :1 and " +
        "(computer_id = (select id from fw_sys_stat_computer where hostname = :2 and valid_until is null) " +
        "  or redu_computer_id = (select id from fw_sys_stat_computer where hostname = :2 and valid_until is null))) ";

  if(fwInstallationDB_executeQuery(sql, var, aRecords))
  {
    fwInstallation_throw("fwInstallationDB_getProjectProperties() -> Could not execute the following SQL query: " + sql);
    return -1;
  }

  if(dynlen(aRecords) > 0)
  {
    projectProperties = aRecords[1];
    //resolve redundant pair:
    string reduHost;
    fwInstallationDB_getReduPair(hostname, project, reduHost);
    projectProperties[FW_INSTALLATION_DB_PROJECT_REDU_HOST] = reduHost;
  }
  
  //SetCache1
  if( fwInstallationDBCache_setCache("_getProjectProperties", parameters, projectProperties, "properties") == 0 
  	&& fwInstallationDBCache_setCache("_getProjectProperties", parameters, projectId, "projectId") == 0
	) {
  }
  //EndSetCache
  
  return 0;
}

/** This function retrieves redundant pair of a projec registered in the System Configuration DB
  @param hostname name of the host
  @param project name of the project
  @param reduHost name of the host where the redundant pair runs
  @return 0 if OK, -1 if errors
*/
int fwInstallationDB_getReduPair(string hostname, string project, string &reduHost)
{
  //GetCache1
  dyn_string parameters = makeDynString(hostname, project);
  if( fwInstallationDBCache_getCache("_getReduPair", parameters, reduHost) == 0 ) {
  	return 0;
  }
  //EndGetCache1

  dyn_string exceptionInfo;
  string sql;
  dyn_dyn_mixed aRecords;
  
  dynClear(exceptionInfo);
  dynClear(aRecords);  
  
  hostname = strtoupper(hostname);
  
  dyn_mixed var;
  var[1] = hostname;   
  var[2] = hostname;   
  var[3] = project;  

/*
  sql = "SELECT C.HOSTNAME FROM FW_SYS_STAT_COMPUTER C, FW_SYS_STAT_PVSS_PROJECT P WHERE P.PROJECT_NAME = :1 " +
	  "AND C.ID = (SELECT CASE WHEN a.computer_id = (select id from fw_sys_stat_computer where valid_until is null and hostname = :2) " +
    	  		            "THEN a.redu_computer_id " +
			          "WHEN a.redu_computer_id = (select id from fw_sys_stat_computer where valid_until is null and hostname = :2) " +
				    "THEN a.computer_id " +
			      "END " +
	              "FROM fw_sys_stat_pvss_project a, fw_sys_stat_pvss_project b " +
		      "WHERE a.valid_until is null and b.valid_until is null and a.id = b.id and a.redu_computer_id is not null)";
*/
    
/*
  sql = "SELECT C.HOSTNAME FROM FW_SYS_STAT_COMPUTER C, FW_SYS_STAT_PVSS_PROJECT P WHERE P.PROJECT_NAME = :1 " +
	       "AND C.ID = (SELECT CASE WHEN computer_id = (select id from fw_sys_stat_computer where valid_until is null and hostname = :2) THEN redu_computer_id " + 
	                        "WHEN redu_computer_id = (select id from fw_sys_stat_computer where valid_until is null and hostname = :2) THEN computer_id " +
	            "END " +
	            "FROM fw_sys_stat_pvss_project " + 
	            "WHERE valid_until is null and redu_computer_id is not null and " +
	                  "computer_id = (select id from fw_sys_stat_computer where valid_until is null and hostname = :2) " +
	                  "or redu_computer_id = (select id from fw_sys_stat_computer where valid_until is null and hostname = :2))";
*/

  sql = "SELECT HOSTNAME FROM FW_SYS_STAT_COMPUTER WHERE ID = ( " +
	         "SELECT * FROM (SELECT (CASE WHEN COMPUTER_ID = (SELECT ID FROM FW_SYS_STAT_COMPUTER WHERE VALID_UNTIL IS NULL AND HOSTNAME = :1) THEN REDU_COMPUTER_ID " + 
			                   "WHEN REDU_COMPUTER_ID = (SELECT ID FROM FW_SYS_STAT_COMPUTER WHERE VALID_UNTIL IS NULL AND HOSTNAME = :2) THEN COMPUTER_ID " + 
	    	             "END) A " + 
	         "FROM FW_SYS_STAT_PVSS_PROJECT " + 
	         "WHERE REDU_COMPUTER_ID IS NOT NULL AND PROJECT_NAME = :3 AND VALID_UNTIL IS NULL) T WHERE T.A IS NOT NULL)";

  if(fwInstallationDB_executeQuery(sql, var, aRecords))
  {
    fwInstallation_throw("fwInstallationDB_getReduPair() -> Could not execute the following SQL query: " + sql);
    return -1;
  }
  
  if(dynlen(aRecords) > 0)
    reduHost = aRecords[1][1];
  else 
    reduHost = strtoupper(hostname);
  
  //SetCache1
  if( fwInstallationDBCache_setCache("_getReduPair", parameters, reduHost) == 0 ) {
  }
  //EndSetCache
  
  return 0;
}

/*
int fwInstallationDB_unregisterAllHostPvssVersions(string host = "")
{
  dyn_mixed record;
  string sql = "";
  
  if(host == "")
   host = strtoupper(fwInstallation_getHostname());

  record[1] = host;
  sql = "delete fw_sys_stat_pvss_base_version  "+
        "where computer_id = "+
        "  (select id from fw_sys_stat_computer where valid_until is null and hostname = :1)";   
  
  if(fwInstallationDB_execute(sql, record)) {fwInstallation_throw("fwInstallationDB_unregisterAllHostPvssVersions() -> Could not execute the following SQL: " + sql + ",  bind variables: " + record); return -1;};

  return 0;
}
*/

/*
int fwInstallationDB_registerHostPvssVersions()
{
  int err = 0;
  string host = strtoupper(fwInstallation_getHostname());
  dyn_string pvssHostPvssVersions = fwInstallation_getHostPvssVersions();
  string os = "WINDOWS";
  
  if(!_WIN32)
    os = "LINUX";
  
  for(int i = 1; i <= dynlen(pvssHostPvssVersions); i++)
  {
    if(pvssHostPvssVersions[i] == VERSION) //Register the version with service pack
      pvssHostPvssVersions[i] = VERSION_DISP;
    
    if(fwInstallationDB_registerPvssVersion(host, pvssHostPvssVersions[i], os))
    {
      fwInstallation_throw("Failed to register in DB PVSS v." + pvssHostPvssVersions[i] + " OS: " + os + " Host: " + host);
      ++err;
    }
  }
  if(err)
    return -1;
  
  return 0;
}
*/

int fwInstallationDB_getHostPvssVersions(dyn_dyn_mixed &dbPvssVersions)
{
  string hostname = strtoupper(fwInstallation_getHostname());    
  string sql;
  dyn_dyn_mixed aRecords;
  dynClear(aRecords);  

  dyn_mixed var;
  var[1] = hostname;  

  sql = "select version_name, os from fw_sys_stat_pvss_version where id in " + 
        "(select pvss_version_id from FW_SYS_STAT_PVSS_BASE_VERSION "+
        "where computer_id = "+
          "(select id from fw_sys_stat_computer where hostname = :1 and valid_until is null))";
       
  if(fwInstallationDB_executeQuery(sql, var, aRecords))
  {
    fwInstallation_throw("fwInstallationDB_getHostPvssVersions() -> Could not execute the following SQL query: " + sql);
    return -1;
  }

  for(int i = 1; i <= dynlen(aRecords); i++)
  {
    dbPvssVersions[i][1] = aRecords[i][1];  
    dbPvssVersions[i][2] = aRecords[i][2];  
  }
  
  return 0;
}



/** This function retrieves list of paths registered in the System Configuration DB for a project
  @param project project name
  @param hostname hostname
  @param projectPaths list of project paths
  @return 0 if OK, -1 if errors
*/
int fwInstallationDB_getProjectPaths(string project = "", string hostname = "", dyn_string &projectPaths)
{
  //GetCache1
  dyn_string parameters = makeDynString(project, hostname);
  if( fwInstallationDBCache_getCache("_getProjectPaths", parameters, projectPaths) == 0 ) {
  	return 0;
  }
  //EndGetCache1

  dyn_string exceptionInfo;
  string sql;
  dyn_dyn_mixed aRecords;
  
  dynClear(exceptionInfo);
  dynClear(aRecords);  
  dynClear(projectPaths);

  hostname = strtoupper(hostname);
  
  dyn_mixed var;
  var[1] = project;  
  var[2] = hostname;  

  ///Project paths:
  if(project == "ALL" && hostname == "ALL")
    sql = "select d.path from fw_sys_stat_inst_path d where valid_until IS NULL";
  else
   sql = "select d.path from fw_sys_stat_inst_path d where d.valid_until IS NULL AND d.project_id = " +
	  "(select p.id from fw_sys_stat_pvss_project p where valid_until is null and p.project_name = :1  AND (p.computer_id = " + 
	  "	(select c.id from fw_sys_stat_computer c where c.valid_until is null and c.hostname = :2) " +
          "or redu_computer_id = (select c.id from fw_sys_stat_computer c where c.valid_until is null and c.hostname = :2))) order by id";
         
  if(fwInstallationDB_executeQuery(sql, var, aRecords))
  {
    fwInstallation_throw("fwInstallationDB_getProjectProperties() -> Could not execute the following SQL query: " + sql);
    return -1;
  }

  
  for(int i = 1; i <= dynlen(aRecords); i++) {  
    dynAppend(projectPaths, aRecords[i][1]);
  }
  
  //SetCache1
  if( fwInstallationDBCache_setCache("_getProjectPaths", parameters, projectPaths) == 0 ) {
  }
  //EndSetCache
  
  return 0;
  
}//end of function


/** This function sets the project properties in the system configuration DB
  @param project project name
  @param hostname hostname
  @param projectProperties project properties as a dyn_mixed array
  @param askScattered if true, it asks the user whether this is an scattered project as the system already exists
  @return 0 if OK, -1 if errors
*/
int fwInstallationDB_setProjectProperties(string project,
                                          string hostname, 
                                          dyn_mixed projectProperties, 
                                          bool askScattered = false)
{
  int project_id;
  dyn_string exceptionInfo;
  dyn_dyn_mixed aRecords;
  string sql;
  string pvssVersion;
  string os;
  int error = 0;
  dyn_mixed systemProperties;
  int base_id, pvss_id, host_id;

  dynClear(aRecords);

  hostname = strtoupper(hostname);
  
  if(fwInstallationDB_isProjectRegistered(project_id, project, hostname) != 0)
  {
    fwInstallation_throw("fwInstallationDB_setProjectProperties() -> Could not access the DB");
    return -1;
  }
  else if(project_id == -1)
  {  
      int deleteFiles = 0;
      if(dynlen(projectProperties) >= FW_INSTALLATION_DB_PROJECT_DELETE_FILES)
        deleteFiles = projectProperties[FW_INSTALLATION_DB_PROJECT_DELETE_FILES];
      int status;
      if(dynlen(projectProperties) >= FW_INSTALLATION_DB_PROJECT_TOOL_STATUS)
        status = projectProperties[FW_INSTALLATION_DB_PROJECT_TOOL_STATUS];
      
      if(fwInstallationDB_registerProject(project, 
                                       hostname, 
                                       projectProperties[FW_INSTALLATION_DB_PROJECT_PMON_PORT], 
                                       projectProperties[FW_INSTALLATION_DB_PROJECT_PMON_USER], 
                                       projectProperties[FW_INSTALLATION_DB_PROJECT_PMON_PWD], 
                                       projectProperties[FW_INSTALLATION_DB_PROJECT_DIR], 
                                       projectProperties[FW_INSTALLATION_DB_PROJECT_SYSTEM_NAME], 
                                       projectProperties[FW_INSTALLATION_DB_PROJECT_SYSTEM_NUMBER], 
                                       projectProperties[FW_INSTALLATION_DB_PROJECT_DATA], 
                                       projectProperties[FW_INSTALLATION_DB_PROJECT_EVENT], 
                                       projectProperties[FW_INSTALLATION_DB_PROJECT_DIST], 
                                       projectProperties[FW_INSTALLATION_DB_PROJECT_CENTRALLY_MANAGED],
                                       projectProperties[FW_INSTALLATION_DB_PROJECT_PVSS_VER],
                                       projectProperties[FW_INSTALLATION_DB_PROJECT_OS],
                                       projectProperties[FW_INSTALLATION_DB_PROJECT_REDU_HOST],
                                       projectProperties[FW_INSTALLATION_DB_PROJECT_SYSTEM_COMPUTER],
                                       deleteFiles,
                                       status,
                                       askScattered,
                                       projectProperties[FW_INSTALLATION_DB_PROJECT_PVSS_VER],
                                       projectProperties[FW_INSTALLATION_DB_PROJECT_REDU_PORT],
                                       projectProperties[FW_INSTALLATION_DB_PROJECT_SPLIT_PORT]) != 0)
    {
      fwInstallation_throw("fwInstallationDB_setComponentProperties() -> Could not register project "+ project + " in host: " + hostname + " in DB.");
      return -1;      
    }
    fwInstallationDB_isProjectRegistered(project_id, project, hostname);

    if(project_id == -1)
    {
      fwInstallation_throw("fwInstallationDB_setProjectProperties() -> Could not check if project is registered: ", project, hostname);
      return -1;
    
    }
  }
  else //project is registered. Upgrade project properties
  {
    
    fwInstallationDB_isPvssBaseRegistered(hostname, projectProperties[FW_INSTALLATION_DB_PROJECT_PVSS_VER], projectProperties[FW_INSTALLATION_DB_PROJECT_OS], base_id, pvss_id, host_id); 
       
       systemProperties[FW_INSTALLATION_DB_SYSTEM_NAME] = projectProperties[FW_INSTALLATION_DB_PROJECT_SYSTEM_NAME];
       systemProperties[FW_INSTALLATION_DB_SYSTEM_NUMBER] = projectProperties[FW_INSTALLATION_DB_PROJECT_SYSTEM_NUMBER];
       systemProperties[FW_INSTALLATION_DB_SYSTEM_DATA_PORT] = projectProperties[FW_INSTALLATION_DB_PROJECT_DATA];
       systemProperties[FW_INSTALLATION_DB_SYSTEM_EVENT_PORT ] = projectProperties[FW_INSTALLATION_DB_PROJECT_EVENT];
       systemProperties[FW_INSTALLATION_DB_SYSTEM_DIST_PORT ] = projectProperties[FW_INSTALLATION_DB_PROJECT_DIST];
       systemProperties[FW_INSTALLATION_DB_SYSTEM_REDU_PORT ] = projectProperties[FW_INSTALLATION_DB_PROJECT_REDU_PORT];
       systemProperties[FW_INSTALLATION_DB_SYSTEM_SPLIT_PORT ] = projectProperties[FW_INSTALLATION_DB_PROJECT_SPLIT_PORT];       
       systemProperties[FW_INSTALLATION_DB_SYSTEM_COMPUTER] = hostname;
       if(fwInstallationDB_setSystemProperties(systemProperties) != 0)
       {
         fwInstallation_throw("fwInstallationDB_setProjectProperties() -> Could not set PVSS system properties");
         ++error;
       }
       
       dyn_mixed record;
       record[1] = projectProperties[FW_INSTALLATION_DB_PROJECT_DIR]; 
       record[2] = projectProperties[FW_INSTALLATION_DB_PROJECT_PMON_PORT]; 
       record[3] = projectProperties[FW_INSTALLATION_DB_PROJECT_TOOL_VER];
       record[4] = projectProperties[FW_INSTALLATION_DB_PROJECT_CENTRALLY_MANAGED];
       //record[5] = base_id;
       record[5] = projectProperties[FW_INSTALLATION_DB_PROJECT_PVSS_VER];
       record[6] = projectProperties[FW_INSTALLATION_DB_PROJECT_OS];
       
       if(dynlen(projectProperties) >= FW_INSTALLATION_DB_PROJECT_DELETE_FILES)
         record[7] = projectProperties[FW_INSTALLATION_DB_PROJECT_DELETE_FILES];
       else
         record[7] = 0;
       
       if(projectProperties[FW_INSTALLATION_DB_PROJECT_REDU_HOST] != "") 
       { 
         int redu_id = -1;
         int centrally = projectProperties[FW_INSTALLATION_DB_PROJECT_CENTRALLY_MANAGED];

         if(!centrally)
         {
           string reduHost = strtoupper(projectProperties[FW_INSTALLATION_DB_PROJECT_REDU_HOST]);

           if(fwInstallationDB_isPCRegistered(redu_id, reduHost))
           {
             fwInstallation_throw("fwInstallationDB_setProjectProperties() -> Could not set PVSS system properties. Failed to check if redundant host is registered in the DB: " + reduHost);
             return -1;
           }
           if(redu_id == -1)
           {
             dyn_mixed hostInfo;
             fwInstallation_getHostProperties(reduHost, hostInfo);    
             redu_id = fwInstallationDB_registerPC(reduHost, hostInfo);
             //DebugN(hostInfo);
             //fwInstallation_throw("fwInstallationDB_setProjectProperties() -> Could not set PVSS system properties. Redundant host is not registered in the DB: " + reduHost);
             //return -1;
           }
         }
         else
         {
           fwInstallationDB_isPCRegistered(redu_id, projectProperties[FW_INSTALLATION_DB_PROJECT_REDU_HOST]);
         }
         record[8] = redu_id;         
       }
       
       if(dynlen(projectProperties) >= FW_INSTALLATION_DB_PROJECT_TOOL_STATUS)
       {
         record[9] =  projectProperties[FW_INSTALLATION_DB_PROJECT_SYSTEM_OVERVIEW];
         record[10] = projectProperties[FW_INSTALLATION_DB_PROJECT_UPGRADE];
         if( projectProperties[FW_INSTALLATION_DB_PROJECT_PMON_USER] != "N/A")
         {
           record[11] = projectProperties[FW_INSTALLATION_DB_PROJECT_PMON_USER];
           record[12] = projectProperties[FW_INSTALLATION_DB_PROJECT_PMON_PWD]; 
           record[13] = projectProperties[FW_INSTALLATION_DB_PROJECT_TOOL_STATUS];
           record[14] = project_id;
           sql = "UPDATE fw_sys_stat_pvss_project SET project_dir = :1, pmon_port = :2, " +
//                + "fw_inst_tool_version = :3, centrally_managed = :4, pvss_base_id = :5, delete_files = :6, redu_computer_id = :7, "
                + "fw_inst_tool_version = :3, centrally_managed = :4, pvss_version = :5, os = :6, delete_files = :7, redu_computer_id = :8, "
                + "system_overview = :9, upgrade = :10, pmon_username = :11, pmon_password = :12, inst_tool_status= :13 WHERE id = :14"; //upgrade = NULL  
         }
         else
         {
           record[11] = projectProperties[FW_INSTALLATION_DB_PROJECT_TOOL_STATUS];
           record[12] = project_id;
           sql = "UPDATE fw_sys_stat_pvss_project SET project_dir = :1, pmon_port = :2, " +
//                + "fw_inst_tool_version = :3, centrally_managed = :4, pvss_base_id = :5, delete_files = :6, redu_computer_id = :7, "
                + "fw_inst_tool_version = :3, centrally_managed = :4, pvss_version = :5, os= :6, delete_files = :7, redu_computer_id = :8, "
                + "system_overview = :9, upgrade = :10, inst_tool_status = :11 WHERE id = :12"; //upgrade = NULL  
         }
       }
       else if(dynlen(projectProperties) >= FW_INSTALLATION_DB_PROJECT_UPGRADE)
       {
         record[9] =  projectProperties[FW_INSTALLATION_DB_PROJECT_SYSTEM_OVERVIEW];
         record[10] = projectProperties[FW_INSTALLATION_DB_PROJECT_UPGRADE];
         if( projectProperties[FW_INSTALLATION_DB_PROJECT_PMON_USER] != "N/A")
         {
           record[11] = projectProperties[FW_INSTALLATION_DB_PROJECT_PMON_USER];
           record[12] =projectProperties[FW_INSTALLATION_DB_PROJECT_PMON_PWD]; 
           record[13] = project_id;
           sql = "UPDATE fw_sys_stat_pvss_project SET project_dir = :1, pmon_port = :2, " +
//                + "fw_inst_tool_version = :3, centrally_managed = :4, pvss_base_id = :5, delete_files = :6, redu_computer_id = :7, "
                + "fw_inst_tool_version = :3, centrally_managed = :4, pvss_version = :5, os = :6, delete_files = :7, redu_computer_id = :8, "
                + "system_overview = :9, upgrade = :10, pmon_username = :11, pmon_password = :12 WHERE id = :13"; //upgrade = NULL  
         }
         else
         {
           record[11] = project_id;
           sql = "UPDATE fw_sys_stat_pvss_project SET project_dir = :1, pmon_port = :2, " +
//                + "fw_inst_tool_version = :3, centrally_managed = :4, pvss_base_id = :5, delete_files = :6, redu_computer_id = :7, "
                + "fw_inst_tool_version = :3, centrally_managed = :4, pvss_version = :5, os= :6, delete_files = :7, redu_computer_id = :8, "
                + "system_overview = :9, upgrade = :10 WHERE id = :11"; //upgrade = NULL  
         }
       }
       else if(dynlen(projectProperties) >= FW_INSTALLATION_DB_PROJECT_SYSTEM_OVERVIEW)
       {
         record[9] =  projectProperties[FW_INSTALLATION_DB_PROJECT_SYSTEM_OVERVIEW];
         if( projectProperties[FW_INSTALLATION_DB_PROJECT_PMON_USER] != "N/A")
         {
           record[10] = projectProperties[FW_INSTALLATION_DB_PROJECT_PMON_USER];
           record[11] =projectProperties[FW_INSTALLATION_DB_PROJECT_PMON_PWD]; 
           record[12] = project_id;
           sql = "UPDATE fw_sys_stat_pvss_project SET  project_dir = :1, pmon_port = :2, "
//                + "fw_inst_tool_version = :3, centrally_managed = :4, pvss_base_id = :5, delete_files = :6, redu_computer_id = :7, " 
                + "fw_inst_tool_version = :3, centrally_managed = :4, pvss_version = :5, os = :6, delete_files = :7, redu_computer_id = :8, " 
                + "system_overview = :9, pmon_username = :10, pmon_password = :11 WHERE id = :12"; //upgrade = NULL  
         }
         else
         {
           record[10] = project_id;
           sql = "UPDATE fw_sys_stat_pvss_project SET  project_dir = :1, pmon_port = :2, "
//                + "fw_inst_tool_version = :3, centrally_managed = :4, pvss_base_id = :5, delete_files = :6, redu_computer_id = :7, " 
                + "fw_inst_tool_version = :3, centrally_managed = :4, pvss_version = :5, os = :6, delete_files = :7, redu_computer_id = :8, " 
                + "system_overview = :9 WHERE id = :10"; //upgrade = NULL  
         }
        
       }
       else
       {
         if( projectProperties[FW_INSTALLATION_DB_PROJECT_PMON_USER] != "N/A")
         {
           record[8] = projectProperties[FW_INSTALLATION_DB_PROJECT_PMON_USER];
           record[9] =projectProperties[FW_INSTALLATION_DB_PROJECT_PMON_PWD]; 
           record[10] = project_id;
           sql = "UPDATE fw_sys_stat_pvss_project SET  project_dir = :1, pmon_port = :2, "
//                + "fw_inst_tool_version = :3, centrally_managed = :4, pvss_base_id = :5, "
                + "fw_inst_tool_version = :3, centrally_managed = :4, pvss_version = :5, os = :6, "
                + "delete_files = :7, redu_computer_id = :8, pmon_username = :9, pmon_password = :10 WHERE id = :11";
         }
         else
         {
           record[9] = project_id;
           sql = "UPDATE fw_sys_stat_pvss_project SET  project_dir = :1, pmon_port = :2, "
//                + "fw_inst_tool_version = :3, centrally_managed = :4, pvss_base_id = :5, "
                + "fw_inst_tool_version = :3, centrally_managed = :4, pvss_version = :5, os = :6, "
                + "delete_files = :7, redu_computer_id = :8 WHERE id = :9";           
         }
       }
       if(fwInstallationDB_execute(sql, record)) {fwInstallation_throw("fwInstallationDB_setProjectProperties() -> Could not execute the following SQL: " + sql + ",  bind variables: " + record); return -1;};
    }
  
  if(error)
    return -1;
     
  return 0;
}

/** This function sets the system properties in the system configuration DB
  @param systemProperties PVSS system properties as a dyn_mixed array
  @return 0 if OK, -1 if errors
*/
int fwInstallationDB_setSystemProperties(dyn_mixed systemProperties)
{

  string systemName = systemProperties[FW_INSTALLATION_DB_SYSTEM_NAME];
  
  int system_id;
  dyn_string exceptionInfo;
  dyn_dyn_mixed aRecords;
  string sql;
  string pvssVersion;
  string os;
  
  int base_id, pvss_id, host_id;

  dynClear(aRecords);

  if(fwInstallationDB_isSystemRegistered(system_id, systemName) != 0)
  {
    fwInstallation_throw("fwInstallationDB_setSystemProperties() -> Could not access the DB");
    return -1;
  }
  
  if(system_id == -1){
    if(fwInstallationDB_registerSystem(systemProperties) != 0)
    {
      fwInstallation_throw("fwInstallationDB_setSystemProperties() -> Could not register system in DB: " + systemName);
      return -1;      
    }
    fwInstallationDB_isSystemRegistered(system_id, systemName);
    if(system_id == -1)
    {
      fwInstallation_throw("fwInstallationDB_setSystemProperties() -> Could not access the DB");
      return -1;
    
    }
  }else{
       dyn_mixed record;
       record[1] = systemProperties[FW_INSTALLATION_DB_SYSTEM_NUMBER];
       record[2] = systemProperties[FW_INSTALLATION_DB_SYSTEM_DATA_PORT];
       record[3] = systemProperties[FW_INSTALLATION_DB_SYSTEM_EVENT_PORT];
       record[4] = systemProperties[FW_INSTALLATION_DB_SYSTEM_DIST_PORT];
       record[5] = systemProperties[FW_INSTALLATION_DB_SYSTEM_REDU_PORT];
       record[6] = systemProperties[FW_INSTALLATION_DB_SYSTEM_SPLIT_PORT];
       if (!isRedundant() || myReduHostNum() == 1)
       {
         record[7] = systemProperties[FW_INSTALLATION_DB_SYSTEM_COMPUTER];
       }
       else
       {
         record[7] = systemProperties[FW_INSTALLATION_DB_SYSTEM_REDU_HOST]; 
       }
       record[8] = system_id;
       
       sql = "UPDATE fw_sys_stat_pvss_system SET system_number = :1, data_port = :2, event_port = :3, dist_port = :4, redu_port = :5, split_port = :6, computer_id = (select id from fw_sys_stat_computer where valid_until is null and hostname = :7) WHERE id = :8";
       if(fwInstallationDB_execute(sql, record)) {fwInstallation_throw("fwInstallationDB_setSystemProperties() -> Could not execute the following SQL: " + sql); return -1;};
    }   
  return 0;
}

/** This function sets the isSubComonponent flag of a component in the system configuration DB
  @param component name of the component
  @param version version of the comoponent
  @param isSubComponent 1 if the component is a subcomponent
  @return 0 if OK, -1 if errors
*/
int fwInstallationDB_setComponentProperties(string component, string version, int isSubComponent)//, int isOfficial, string defaultPath)
{
  int component_id;
  dyn_string exceptionInfo;
  dyn_dyn_mixed aRecords;
  string sql;

  dynClear(aRecords);

  if(fwInstallationDB_isComponentRegistered(component, version, component_id) != 0)
  {
    fwInstallation_throw("fwInstallationDB_setComponentProperties() -> Could not access the DB");
    return -1;
    
  }else if(component_id == -1){
    fwInstallation_throw("INFO: fwInstallationDB_setComponentProperties() -> Component: " + component + " v." + version + " not registered in DB.");
    return -1;      
  }else{
        
       dyn_mixed record;
       record[1] =isSubComponent;
       record[2] = component_id;
       sql = "UPDATE fw_sys_stat_component SET is_subcomponent = :1 WHERE id = :2";
       if(fwInstallationDB_execute(sql, record, false)) {fwInstallation_throw("fwInstallationDB_setComponentProperties() -> Could not execute the following SQL: " + sql); return -1;};
    }   
  return 0;
}


/** This function defines a child system for a particular PVSS system
  @param parentSystem Name of the parent PVSS system
  @param childSystem Name of the child PVSS system
  @return 0 if OK, -1 if errors
*/
int fwInstallationDB_addChildSystem(string parentSystem, string childSystem)
{
  int parentId;
  int childId;
  dyn_string exceptionInfo;
  dyn_dyn_mixed aRecords;
  string sql;

  dynClear(aRecords);

  if(fwInstallationDB_isSystemRegistered(parentId, parentSystem) != 0 || fwInstallationDB_isSystemRegistered(childId, childSystem) != 0)
  {
    fwInstallation_throw("fwInstallationDB_addChildSystem() -> Could not access the DB");
    return -1;
    
  }else if(parentId == -1 || childId == -1){
    fwInstallation_throw("fwInstallationDB_addChildSystem() -> Both systems must be registered in the FW System Static Configuration DB first");
    return -1;      
  }else{
        
       dyn_mixed record;
       record[1] =parentId;
       record[2] = childId;
       
       sql = "UPDATE fw_sys_stat_pvss_system SET parent_system_id = :1 WHERE id = :2";
       if(fwInstallationDB_execute(sql, record, false)) {fwInstallation_throw("fwInstallationDB_addChildSystem() -> Could not execute the following SQL: " + sql); return -1;};
    }   
  return 0;
}

/** This function removes a child from its parent in the system configuration DB
  @param systemName Name of the child PVSS system to be removed
  @return 0 if OK, -1 if errors
*/
int fwInstallationDB_removeChildSystem(string systemName)
{
  int id;
  dyn_string exceptionInfo;
  dyn_dyn_mixed aRecords;
  string sql;

  dynClear(aRecords);
  if(!patternMatch("*:", systemName))
    systemName += ":";

  if(fwInstallationDB_isSystemRegistered(id, systemName) != 0)
  {
    fwInstallation_throw("fwInstallationDB_removeChildSystem() -> Could not access the DB");
    return -1;    
  }else if(id == -1){
    DebugN("INFO: fwInstallationDB_removeChildSystem() -> System: " + systemName + " is not registered in the DB. Nothing to be done");
    return 0;      
  }else{
    dyn_mixed record;
    record[1] = id;

    sql = "UPDATE fw_sys_stat_pvss_system SET parent_system_id = NULL WHERE id = :1";
    if(fwInstallationDB_execute(sql, record, false)) {fwInstallation_throw("fwInstallationDB_removeChildSystem() -> Could not execute the following SQL: " + sql); return -1;};
  }

  return 0;
}

/** This function removes from the system configuration DB the system hierarchy tree
  @return 0 if OK, -1 if errors
*/
int fwInstallationDB_removeSystemHierarchy()
{
  int error = 0;
  dyn_dyn_mixed hierarchyInfo;
  
  if(fwInstallationDB_getSystemHierarchy(hierarchyInfo) != 0){
    fwInstallation_throw("fwInstallationDB_removeSystemHierarchy() -> Could not retrieve hierarchy from DB.");
    return -1;
  }

  for(int i = 1; i <= dynlen(hierarchyInfo); i++){
    
    error += fwInstallationDB_removeChildSystem(hierarchyInfo[i][FW_INSTALLATION_DB_SYSTEM_NAME_IDX]);
       
  }//end of loop  
 
  if(error)
    return -1;
  
  return 0;
}

/** This function retrieves the list of child systems of a particular parent as defined in the system configuration DB
  @param parentSystem Name of the parent PVSS system
  @param childSystems Children properties as a dyn_dyn_mixed matrix
  @return 0 if OK, -1 if errors
*/
int fwInstallationDB_getChildSystems(string parentSystem, dyn_dyn_mixed &childSystems)
{
  int parentId;
  dyn_string exceptionInfo;
  dyn_dyn_mixed aRecords;
  string sql;

  dynClear(aRecords);

  if(fwInstallationDB_isSystemRegistered(parentId, parentSystem) != 0)
  {
    fwInstallation_throw("fwInstallationDB_getChildSystems() -> Could not access the DB");
    return -1;
    
  }else if(parentId == -1){
    fwInstallation_throw("fwInstallationDB_getChildSystems() -> System: " + parentSystem + " cannot be found in the DB.");
    return -1;      
  }
  else
  {
    //Check that what is passed as parent system is the real parent of the child system:
    dyn_mixed var;
    var[1] = parentId;  
  
      sql = "select system_name, system_number, data_port, event_port, dist_port from fw_sys_stat_pvss_system where parent_system_id = :1 AND valid_until IS NULL";
      if(fwInstallationDB_executeQuery(sql, var, aRecords))
      {
        fwInstallation_throw("fwInstallationDB_getChildSystems() -> Could not execute the following SQL query: " + sql);
        return -1;
      }
  }
  
  childSystems = aRecords;   
  
  return 0;
}

/** This function retrieves the information about the hierarchy of PVSS systems defined in the system configuration DB
  @param hierarchyInfo Hierarchy information as a dyn_dyn_mixed matrix
  @return 0 if OK, -1 if errors
*/

int fwInstallationDB_getSystemHierarchy(dyn_dyn_mixed &hierarchyInfo)
{
  //GetCache1
  dyn_string parameters = makeDynString();
  if( fwInstallationDBCache_getCache("_getSystemHierarchy", parameters, hierarchyInfo) == 0 ) {
  	return 0;
  }
  //EndGetCache1

  dyn_string exceptionInfo;
  dyn_dyn_mixed aRecords;
  string sql;

  dynClear(aRecords);
  
  //Check that what is passed as parent system is the real parent of the child system:
  dyn_mixed var;
  sql = "select system_name, system_number, id, parent_system_id from fw_sys_stat_pvss_system start with id = (select id from fw_sys_stat_pvss_system where id in(select parent_system_id from fw_sys_stat_pvss_system where valid_until is null)) connect by prior id = parent_system_id order by system_name";
  if(fwInstallationDB_executeQuery(sql, var, aRecords))
  {
    fwInstallation_throw("fwInstallationDB_getChildSystems() -> Could not execute the following SQL query: " + sql);
    return -1;
  }
  hierarchyInfo = aRecords;
    
  //SetCache1
  if( fwInstallationDBCache_setCache("_getSystemHierarchy", parameters, hierarchyInfo) == 0 ) {
  }
  //EndSetCache
  
  return 0;
}


/** This function retrievesthe properties of a PVSS system from the System Configuration DB
  @param systemName Name of the PVSS system
  @param systemInfo System properties as a dyn_mixed array
  @return 0 if OK, -1 if errors
*/
int fwInstallationDB_getPvssSystemProperties(string systemName, dyn_mixed &systemInfo)
{
  //GetCache1
  dyn_string parameters = makeDynString(systemName);
  if( fwInstallationDBCache_getCache("_getPvssSystemProperties", parameters, systemInfo) == 0 ) {
  	return 0;
  }
  //EndGetCache1

  string id;
  dyn_string exceptionInfo;
  string sql;
  dyn_dyn_mixed aRecords;
  
  dynClear(exceptionInfo);
  dynClear(aRecords);  
  
  if(!patternMatch("*:", systemName))
    systemName += ":";

  dyn_mixed var;
  var[1] = systemName;  

  sql = "SELECT system_name, system_number, data_port, event_port, dist_port, parent_system_id, computer_id, redu_port, split_port " +
        "FROM fw_sys_stat_pvss_system WHERE system_name = :1 and valid_until is null";    
  if(fwInstallationDB_executeQuery(sql, var, aRecords))
  {
    fwInstallation_throw("fwInstallationDB_getPvssSystems() -> Could not execute the following SQL query: " + sql);
    return -1;
  }  
    
  if(dynlen(aRecords) > 0)
    systemInfo = aRecords[1];

  dynClear(aRecords);
  dynClear(var);
  
  //get the name of the computer where the event manager runs:
  if(dynlen(systemInfo) >= FW_INSTALLATION_DB_SYSTEM_COMPUTER)
  {
    var[1] = systemInfo[FW_INSTALLATION_DB_SYSTEM_COMPUTER];
    sql = "SELECT hostname FROM fw_sys_stat_computer where id = :1";
    if(fwInstallationDB_executeQuery(sql, var, aRecords))
    {
      fwInstallation_throw("fwInstallationDB_getPvssSystems() -> Could not execute the following SQL query: " + sql);
      return -1;
    }  
    
  if(dynlen(aRecords) > 0)
    systemInfo[FW_INSTALLATION_DB_SYSTEM_COMPUTER] = aRecords[1][1];
  }
  
  //SetCache1
  if( fwInstallationDBCache_setCache("_getPvssSystemProperties", parameters, systemInfo) == 0 ) {
  }
  //EndSetCache
  
  return 0;
}

/** This function retrieves the list of dist peers of a system as defined in the system configuration DB
  @param systemName Name of the PVSS system to retrieve the list of dist-peers for
  @param connectedSystemsInfo Dist-peers properties as a dyn_mixed array
  @param onlyServers if set to true, the direction of the connection is taken into account, i.e. the 
                     list of connected systems will only contains those the local system initiates the connection to.
  @return 0 if OK, -1 if errors
*/
int fwInstallationDB_getSystemConnectivity(string systemName, dyn_mixed &connectedSystemsInfo, bool onlyServers = false)
{
  //GetCache1
  dyn_string parameters = makeDynString(systemName, onlyServers);
  if( fwInstallationDBCache_getCache("_getSystemConnectivity", parameters, connectedSystemsInfo) == 0 ) {
  	return 0;
  }
  //EndGetCache1

  string id;
  dyn_string exceptionInfo;
  string sql;
  dyn_dyn_mixed aRecords;
  
  dynClear(exceptionInfo);
  dynClear(aRecords);  
  
  if(!patternMatch("*:", systemName))
    systemName += ":";

  if(fwInstallationDB_isSystemRegistered(id, systemName) != 0){
    fwInstallation_throw("fwInstallationDB_getSystemConnectivity() -> Could not talk to the DB. Check connection parameters"); 
    return -1;
  }else if(id == -1){
    fwInstallation_throw("fwInstallationDB_getSystemConnectivity() -> PVSS system: " + systemName + " not registered in the DB." );
    return -1;
  }else{
  
    dyn_mixed var;
    var[1] = id;  

    /* this query returns the full list of dist peers regardless who initiates the connection.
       Following a request from CMS (https://icecontrols.cern.ch/jira/browse/JCOP-22), this is now changed such that the list will only contain
       the names of the peers which the local system initiates the connection for.*/

    if(!onlyServers)    
    {
      sql = "SELECT s.system_name, s.system_number, s.data_port, s.event_port, s.dist_port, s.parent_system_id, c.hostname, s.redu_port, s.split_port, p.project_name FROM fw_sys_stat_pvss_system s, fw_sys_stat_pvss_project p, fw_sys_stat_computer c WHERE S.ID IN (" 
            + "SELECT CASE WHEN peer_1_id = :1 THEN peer_2_id"
  	         +    " WHEN peer_2_id = :1 THEN peer_1_id"
            +         " end "
            + " FROM fw_sys_stat_system_connect WHERE valid_until IS NULL) AND P.COMPUTER_ID = S.COMPUTER_ID AND P.SYSTEM_ID = S.ID AND C.ID = S.COMPUTER_ID order by s.system_name";
            
    }
    else
    {
      sql = "SELECT s.system_name, s.system_number, s.data_port, s.event_port, s.dist_port, s.parent_system_id, c.hostname, s.redu_port, s.split_port, p.project_name " + //, " +
            "FROM fw_sys_stat_pvss_system s, fw_sys_stat_pvss_project p, fw_sys_stat_computer c " +
            "WHERE P.COMPUTER_ID = S.COMPUTER_ID AND P.SYSTEM_ID = S.ID AND C.ID = S.COMPUTER_ID AND S.ID IN " +
	          "(SELECT peer_2_id " + 
	          "FROM fw_sys_stat_system_connect " +
	          "WHERE valid_until IS NULL AND PEER_1_ID = :1) ORDER BY s.system_name";
    }
    if(fwInstallationDB_executeQuery(sql, var, aRecords))
    {
      fwInstallation_throw("fwInstallationDB_getSystemConnectivity() -> Could not execute the following SQL query: " + sql);
      return -1;
    }  
  }
  
  connectedSystemsInfo = aRecords;
  for(int i = 1; i <= dynlen(connectedSystemsInfo); i++)
  {
    string hostname =  connectedSystemsInfo[i][FW_INSTALLATION_DB_SYSTEM_COMPUTER];
    connectedSystemsInfo[i][FW_INSTALLATION_DB_SYSTEM_COMPUTER] += ":" + connectedSystemsInfo[i][FW_INSTALLATION_DB_SYSTEM_DIST_PORT];
    string reduHost = "";
    fwInstallationDB_getReduPair(hostname, connectedSystemsInfo[i][FW_INSTALLATION_DB_SYSTEM_PROJECT], reduHost);
    if(reduHost != hostname)
      connectedSystemsInfo[i][FW_INSTALLATION_DB_SYSTEM_COMPUTER] += "$" + reduHost + ":" + connectedSystemsInfo[i][FW_INSTALLATION_DB_SYSTEM_DIST_PORT];
  }
    
  //SetCache1
  if( fwInstallationDBCache_setCache("_getSystemConnectivity", parameters, connectedSystemsInfo) == 0 ) {
  }
  //EndSetCache
  
  return 0;
}

/** This function retrieves the list of remote distpeers of a particular system from the system configuration DB
  @param systemName Name of the parent PVSS system
  @param connectedSystemsInfo List of connected dist-peers
  @return 0 if OK, -1 if errors
*/
int fwInstallationDB_getRemoteConnections(string systemName, dyn_mixed &connectedSystemsInfo)
{
  //GetCache1
  dyn_string parameters = makeDynString(systemName);
  if( fwInstallationDBCache_getCache("_getRemoteConnections", parameters, connectedSystemsInfo) == 0 ) {
  	return 0;
  }
  //EndGetCache1

  string id;
  dyn_string exceptionInfo;
  string sql;
  dyn_dyn_mixed aRecords;
  
  dynClear(exceptionInfo);
  dynClear(aRecords);  
  
  if(!patternMatch("*:", systemName))
    systemName += ":";

  if(fwInstallationDB_isSystemRegistered(id, systemName) != 0){
    fwInstallation_throw("fwInstallationDB_getRemoteConnections() -> Could not talk to the DB. Check connection parameters"); 
    return -1;
  }else if(id == -1){
    fwInstallation_throw("fwInstallationDB_getRemoteConnections() -> PVSS system: " + systemName + " not registered in the DB." );
    return -1;
  }else{
  
    dyn_mixed var;
    var[1] = id;  

    sql = "SELECT s.system_name, s.system_number, s.data_port, s.event_port, s.dist_port, s.parent_system_id, c.hostname, p.project_name, s.redu_port, s.split_port FROM fw_sys_stat_pvss_system s, fw_sys_stat_pvss_project p, fw_sys_stat_computer c WHERE S.ID IN (" 
          + "SELECT peer_2_id FROM fw_sys_stat_system_connect WHERE (peer_1_id = :1 AND valid_until IS NULL)) AND P.SYSTEM_ID = S.ID AND C.ID = P.COMPUTER_ID";

  if(fwInstallationDB_executeQuery(sql, var, aRecords))
    {
      fwInstallation_throw("fwInstallationDB_getRemoteConnections() -> Could not execute the following SQL query: " + sql);
      return -1;
    }  
  }
    
  connectedSystemsInfo = aRecords;
    
  //SetCache1
  if( fwInstallationDBCache_setCache("_getRemoteConnections", parameters, connectedSystemsInfo) == 0 ) {
  }
  //EndSetCache
  
  return 0;
}


/** This function retrieves the list of projects pointing to a single system (scattered projects)
  @param systemName Name of the parent PVSS system
  @param projectsInfo Projects' properties as a dyn_dyn_mixed matrix
  @return 0 if OK, -1 if errors
*/
int fwInstallationDB_getSystemProjects(string systemName, dyn_dyn_mixed &projectsInfo)
{
  //GetCache1
  dyn_string parameters = makeDynString(systemName);
  if( fwInstallationDBCache_getCache("_getSystemProjects", parameters, projectsInfo) == 0 ) {
  	return 0;
  }
  //EndGetCache1

  string id;
  dyn_string exceptionInfo;
  string sql;
  dyn_dyn_mixed aRecords;
  
  dynClear(exceptionInfo);
  dynClear(aRecords);  

  if(!patternMatch("*:", systemName))
    systemName += ":";

  
  if(fwInstallationDB_isSystemRegistered(id, systemName) != 0){
    fwInstallation_throw("fwInstallationDB_getSystemProjects() -> Could not talk to the DB. Check connection parameters"); 
    return -1;
  }else if(id == -1){
    fwInstallation_throw("fwInstallationDB_getSystemProjects() -> PVSS system: " + systemName + " not registered in the DB." );
    return -1;
  }else{
    dyn_mixed var;
    var[1] = id;  

    sql = "SELECT p.project_name, c.hostname FROM fw_sys_stat_pvss_project p, fw_sys_stat_computer c WHERE p.computer_id = c.id AND p.system_id = :1 AND p.valid_until IS NULL AND c.valid_until IS NULL";
    if(fwInstallationDB_executeQuery(sql, var, aRecords))
     {
      fwInstallation_throw("fwInstallationDB_getSystemProjects() -> Could not execute the following SQL query: " + sql);
      return -1;
    }  
  }  
    projectsInfo = aRecords;
    
  //SetCache1
  if( fwInstallationDBCache_setCache("_getSystemProjects", parameters, projectsInfo) == 0 ) {
  }
  //EndSetCache
  
  return 0;
}


/** This function registers a manager in a project in the system configuration DB
  @param managerInfo manager properties
  @param project project name
  @param hostname hostname
  @return 0 if OK, -1 if errors
*/
int fwInstallationDB_registerProjectManager(dyn_mixed managerInfo, string project = "", string hostname = "")
{
  int project_id;
  int manager_id;
  dyn_string exceptionInfo;
  dyn_dyn_mixed aRecords;
  string sql;
  int triggersAlerts;

  dynClear(aRecords);

  if(project == "")
    project = PROJ;
  
  if(hostname == ""){
    hostname = fwInstallation_getHostname();    
  }

  hostname = strtoupper(hostname);
   
  if(fwInstallationDB_isProjectManagerRegistered(managerInfo, project, hostname, manager_id, project_id) != 0)
  {
    fwInstallation_throw("fwInstallationDB_registerProjectManager() -> Could not access the DB");
    return -1;
    
  }else if(project_id == -1){
    fwInstallation_throw("fwInstallationDB_registerProjectManager() -> Project: " + project + " computer: " + hostname + " not registered in DB.");
    return -1;      
  }else if(manager_id > 0){
    if(fwInstallationDB_setPvssManagerProperties(managerInfo) != 0){
      fwInstallation_throw("fwInstallationDB_registerProjectManager() -> Could not change manager properties: ", managerInfo);
      return -1;      
    }
  }
  else if(fwInstallationDB_registerPvssManagerType(managerInfo[FW_INSTALLATION_DB_MANAGER_NAME_IDX]) != 0){
    fwInstallation_throw("fwInstallationDB_registerProjectManager() -> Could not register manager type " + managerInfo[FW_INSTALLATION_DB_MANAGER_NAME_IDX]);
    return -1;
  }else {
    
    if(managerInfo[FW_INSTALLATION_DB_MANAGER_START_IDX] == "always")
      triggersAlerts = 1;
    else
      triggersAlerts = 0;

       dyn_mixed record;
       record[1] = managerInfo[FW_INSTALLATION_DB_MANAGER_NAME_IDX];
       record[2] = managerInfo[FW_INSTALLATION_DB_MANAGER_START_IDX];
       record[3] = managerInfo[FW_INSTALLATION_DB_MANAGER_RESTART_IDX];
       record[4] = managerInfo[FW_INSTALLATION_DB_MANAGER_RESETMIN_IDX];
       record[5] = managerInfo[FW_INSTALLATION_DB_MANAGER_SECKILL_IDX];
       record[6] = managerInfo[FW_INSTALLATION_DB_MANAGER_OPTIONS_IDX];
       record[7] = project_id;
       record[8] = triggersAlerts;

//       sql = "INSERT INTO fw_sys_stat_project_manager (id, manager_type, start_mode, restart_count, reset_min, sec_kill, command_line, project_id, triggers_alerts, valid_from) VALUES " 
//             + " (fw_sys_stat_proj_manager_sq.nextval, :1, :2, :3, :4, :5, :6, :7, :8, SYSDATE)";
       sql = "INSERT INTO fw_sys_stat_project_manager (id, manager_type, start_mode, restart_count, reset_min, sec_kill, command_line, project_id, triggers_alerts) VALUES " 
             + " (fw_sys_stat_proj_manager_sq.nextval, :1, :2, :3, :4, :5, :6, :7, :8)";
       if(fwInstallationDB_execute(sql, record)) {fwInstallation_throw("fwInstallationDB_registerProjectManager() -> Could not execute the following SQL: " + sql); return -1;};
    }   
  return 0;
}


/** This function sets the properties of a manager in a project in the system configuration DB
  @param managerInfo manager properties
  @param project project name
  @param hostname hostname
  @return 0 if OK, -1 if errors
*/
int fwInstallationDB_setPvssManagerProperties(dyn_mixed managerInfo, string project = "", string hostname = "")
{
  dyn_string exceptionInfo;
  dyn_dyn_mixed aRecords;
  string sql;

  int project_id;
  int manager_id;
  int triggersAlerts;
          
  dynClear(aRecords);

  if(project == "")
    project = PROJ;
  
  if(hostname == "")
    hostname = fwInstallation_getHostname();

  hostname = strtoupper(hostname);
  
  if(fwInstallationDB_isProjectManagerRegistered(managerInfo, project, hostname, manager_id, project_id) != 0)
  {
    fwInstallation_throw("fwInstallationDB_setPvssManagerProperties() -> Could not retrieve information from DB");
    return -1;
    
  }else if(project_id == -1 || manager_id == -1){
    fwInstallation_throw("INFO: fwInstallationDB_setPvssManagerProperties() -> Project and manager are not registered in the DB.");
    return -1;      
  }else{  
      if(managerInfo[FW_INSTALLATION_DB_MANAGER_START_IDX] == "always")
        triggersAlerts = 1;
      else
        triggersAlerts = 0;
      
       dyn_mixed record;
       record[1] = managerInfo[FW_INSTALLATION_DB_MANAGER_START_IDX];
       record[2] = managerInfo[FW_INSTALLATION_DB_MANAGER_RESTART_IDX];
       record[3] = managerInfo[FW_INSTALLATION_DB_MANAGER_RESETMIN_IDX];
       record[4] = managerInfo[FW_INSTALLATION_DB_MANAGER_SECKILL_IDX];
       record[5] = managerInfo[FW_INSTALLATION_DB_MANAGER_OPTIONS_IDX];
       record[6] = triggersAlerts;
       record[7] = manager_id;
       
       sql = "UPDATE fw_sys_stat_project_manager SET start_mode = :1, restart_count = :2, reset_min = :3, sec_kill = :4, command_line = :5, triggers_alerts = :6 WHERE id = :7";
       if(fwInstallationDB_execute(sql, record)) {fwInstallation_throw("fwInstallationDB_setPvssManagerProperties() -> Could not execute the following SQL: " + sql); return -1;};

    }  
  
    
  return 0;
}

/** This function checks if a manager is registered in a project in the system configuration DB
  @param managerInfo manager properties
  @param project project name
  @param hostname hostname
  @param manager_id DB index of the manager
  @param project_id DB index of the project
  @return 0 if OK, -1 if errors
*/
int fwInstallationDB_isProjectManagerRegistered(dyn_mixed managerInfo, 
                                                string project,
                                                string hostname, 
                                                int &manager_id, 
                                                int &project_id)
{
  //GetCache1
  dyn_string parameters = makeDynString(managerInfo, project, hostname);
  if( fwInstallationDBCache_getCache("_isProjectManagerRegistered", parameters, manager_id, "manId") == 0 
  	&& fwInstallationDBCache_getCache("_isProjectManagerRegistered", parameters, project_id, "projId") == 0
	) {
  	return 0;
  }
  //EndGetCache1

  string sql;
  dyn_string exceptionInfo;
  dyn_dyn_mixed aRecords;
  dyn_mixed var;

  dynClear(aRecords);

  hostname = strtoupper(hostname);
    
  if(fwInstallationDB_isProjectRegistered(project_id, project, hostname) != 0){
    fwInstallation_throw("fwInstallationDB_isProjectManagerRegistered() -> Could not connect to the DB");
    project_id = -1;
    manager_id = -1;
    return -1;
  }else if(project_id == -1){
    fwInstallation_throw("fwInstallationDB_isProjectManagerRegistered() -> Project: " + project + " in host: " + hostname + " not registered in the DB.");
    manager_id = -1;
    return -1;
  }else{
    if(managerInfo[FW_INSTALLATION_DB_MANAGER_OPTIONS_IDX] == "")
    {
      var[1] = managerInfo[FW_INSTALLATION_DB_MANAGER_NAME_IDX];
      var[2] = project_id;
        
//      sql = "SELECT id, project_id FROM fw_sys_stat_project_manager WHERE manager_type = :1 AND command_line IS NULL AND project_id = :2 and valid_until is null";
        sql = "SELECT id, project_id FROM fw_sys_stat_project_manager WHERE manager_type = :1 AND command_line IS NULL AND project_id = :2";
    }
    else
    {
      var[1] = managerInfo[FW_INSTALLATION_DB_MANAGER_NAME_IDX];
      var[2] = managerInfo[FW_INSTALLATION_DB_MANAGER_OPTIONS_IDX];
      var[3] = project_id;
      
//      sql = "SELECT id, project_id FROM fw_sys_stat_project_manager WHERE manager_type = :1 AND command_line = :2 AND project_id = :3 and valid_until is null";
        sql = "SELECT id, project_id FROM fw_sys_stat_project_manager WHERE manager_type = :1 AND command_line = :2 AND project_id = :3";
    }
    if(fwInstallationDB_executeQuery(sql, var, aRecords))
    {
      fwInstallation_throw("fwInstallationDB_isProjectManagerRegistered() -> Could not execute the following SQL query: " + sql);
      return -1;
    }  

    if(dynlen(aRecords) > 0) {   
       manager_id = aRecords[1][1];
    }
    else{
      manager_id = -1;
    }
  }
  //SetCache1
  if( fwInstallationDBCache_setCache("_isProjectManagerRegistered", parameters, manager_id, "manId") == 0 
  	&& fwInstallationDBCache_setCache("_isProjectManagerRegistered", parameters, project_id, "projId") == 0
	) {
  }
  //EndSetCache
  
  return 0;
}


/** This function registers a manager type in the system configuration DB
  @param managerTypeInfo Manager type properties as a dyn_mixed
  @return 0 if OK, -1 if errors
*/
int fwInstallationDB_registerPvssManagerType(dyn_mixed managerTypeInfo)
{
  dyn_string exceptionInfo;
  dyn_dyn_mixed aRecords;
  string sql;
  bool isRegistered = false;

  dynClear(aRecords);

  //Ensure a dimension 3 array has been passed.
  if(dynlen(managerTypeInfo) < FW_INSTALLATION_DB_MANAGER_TYPE_DESCRIPTION_IDX){
     managerTypeInfo[FW_INSTALLATION_DB_MANAGER_TYPE_DESCRIPTION_IDX] = "";
     managerTypeInfo[FW_INSTALLATION_DB_MANAGER_TYPE_GROUP_IDX] = "";
   }else if(dynlen(managerTypeInfo) < FW_INSTALLATION_DB_MANAGER_TYPE_GROUP_IDX){
     managerTypeInfo[FW_INSTALLATION_DB_MANAGER_TYPE_GROUP_IDX] = "";
   }
  
  if(fwInstallationDB_isPvssManagerTypeRegistered(managerTypeInfo[FW_INSTALLATION_DB_MANAGER_TYPE_NAME_IDX], isRegistered) != 0)
  {
    fwInstallation_throw("fwInstallationDB_registerPvssManagerType() -> Could not access the DB");
    return -1;
    
  }else if(isRegistered){
    return 0;      
  }else{
    
      dyn_mixed record;
      record[1] = managerTypeInfo[FW_INSTALLATION_DB_MANAGER_TYPE_NAME_IDX];
      record[2] = managerTypeInfo[FW_INSTALLATION_DB_MANAGER_TYPE_DESCRIPTION_IDX];
      record[3] = managerTypeInfo[FW_INSTALLATION_DB_MANAGER_TYPE_GROUP_IDX];
    
      sql = "INSERT INTO fw_sys_stat_manager_type (manager_type, description, manager_group) VALUES (:1, :2, :3)";
      if(fwInstallationDB_execute(sql, record)) {fwInstallation_throw("fwInstallationDB_registerPvssManager() -> Could not execute the following SQL: " + sql); return -1;};
  }   
  return 0;
}

/** This function checks if a manager type is registered in the System Configuration DB
  @param managerType Manager type properties as a dyn_mixed
  @param isRegistered true if the manager type is registered
  @return 0 if OK, -1 if errors
*/
int fwInstallationDB_isPvssManagerTypeRegistered(string managerType, bool &isRegistered)
{
  //GetCache1
  dyn_string parameters = makeDynString(managerType);
  if( fwInstallationDBCache_getCache("_isPvssManagerTypeRegistered", parameters, isRegistered ) == 0 ) {
  	return 0;
  }
  //EndGetCache1

  dyn_string exceptionInfo;
  dyn_dyn_mixed aRecords;

  dynClear(aRecords);
  
  dyn_mixed var;
  var[1] = managerType;

  string sql = "SELECT manager_type FROM fw_sys_stat_manager_type WHERE manager_type = :1";
  if(fwInstallationDB_executeQuery(sql, var, aRecords))
  {
    fwInstallation_throw("fwInstallationDB_isPvssManagerTypeRegistered() -> Could not execute the following SQL query: " + sql);
    return -1;
  }  

  if(dynlen(aRecords) > 0) {   
     isRegistered = true;
  }
  else{
    isRegistered = false;
  }
  
  //SetCache1
  if( fwInstallationDBCache_setCache("_isPvssManagerTypeRegistered", parameters, isRegistered ) == 0 ) {
  }
  //EndSetCache
  
  return 0;
}

/** This function retrieves the list of managers in a project registered in the System Configuration DB
  @param managersInfo Manager  properties as a dyn_dyn_mixed
  @param projectName project name
  @param computerName hostname
  @return 0 if OK, -1 if errors
*/
int fwInstallationDB_getProjectManagers(dyn_dyn_mixed &managersInfo, 
                                        string projectName = "", 
                                        string computerName = "")
{
  //GetCache1
  dyn_string parameters = makeDynString(projectName, computerName);
  if( fwInstallationDBCache_getCache("_getProjectManagers", parameters, managersInfo) == 0 ) {
  	return 0;
  }
  //EndGetCache1

  int project_id;
  dyn_string exceptionInfo;
  string sql;
  
  dynClear(exceptionInfo);
  dynClear(managersInfo);
  
  if(projectName == "")
    projectName = PROJ;
  
  if(computerName == "")
    computerName = fwInstallation_getHostname();
  
  computerName = strtoupper(computerName);

  if(fwInstallationDB_isProjectRegistered(project_id, projectName, computerName) != 0){
    fwInstallation_throw("fwInstalltionDB_getProjectManagers() - > Cannot access the DB.");
    return -1;
  }
      
    
  if(project_id == -1){
      fwInstallation_throw("fwInstallationDB_getProjectManagers() - > Project: "+ projectName + " in computer: " + " Computer: " + computerName + " is not registered in DB.");
      return -1;      
  }
  
  dyn_mixed var;
  var[1] = project_id;

  sql = "SELECT manager_type, start_mode, restart_count, reset_min, sec_kill, command_line, triggers_alerts "+
        "FROM fw_sys_stat_project_manager " + 
        "WHERE project_id = :1";
//        "WHERE project_id = :1 and valid_until is null";
  if(fwInstallationDB_executeQuery(sql, var, managersInfo))
  {
    fwInstallation_throw("fwInstalltionDB_getProjectManagers() - > Could not execute the following SQL query: " + sql);
    return -1;
  }  
 
  //SetCache1
  if( fwInstallationDBCache_setCache("_getProjectManagers", parameters, managersInfo) == 0 ) {
  }
  //EndSetCache
  
  return 0;
}

/** This function retrieves list of components installed in a project registered in the System Configuration DB
  @param componentsInfo Components' properties as a dyn_dyn_mixed
  @param projectName project name
  @param computerName hostname
  @return 0 if OK, -1 if errors
*/
int fwInstallationDB_getProjectComponents(dyn_dyn_mixed &componentsInfo, 
                                          string projectName = "", 
                                          string computerName = "")
{
  //GetCache1
  dyn_string parameters = makeDynString(projectName, computerName);
  if( fwInstallationDBCache_getCache("_getProjectComponents", parameters, componentsInfo) == 0 ) {
  	return 0;
  }
  //EndGetCache1

  int project_id;
  dyn_string exceptionInfo;
  string sql;
  
  dynClear(exceptionInfo);
  dynClear(componentsInfo);
  
  if(projectName == "")
    projectName = PROJ;
  
  if(computerName == "")
    computerName = fwInstallation_getHostname();
  
  computerName = strtoupper(computerName);
  
  if(fwInstallationDB_isProjectRegistered(project_id, projectName, computerName) != 0){
    fwInstallation_throw("fwInstalltionDB_getProjectComponents() - > Cannot access the DB.");
    return -1;
  }
      
    
  if(project_id == -1){
      fwInstallation_throw("fwInstalltionDB_getProjectComponents() - > Project: "+ projectName + " Computer: " + computerName + " is not registered in DB.");
      return -1;      
  }
  
  dyn_mixed var;
  var[1] = projectName;
  var[2] = computerName;

  sql = "SELECT component_name, component_version, is_subcomponent, description_file, overwrite_files, force_required, is_silent, is_patch, restart_project FROM fw_sys_stat_proj_comps where project_name = :1 and hostname = :2";
  if(fwInstallationDB_executeQuery(sql, var, componentsInfo))
  {
    fwInstallation_throw("fwInstalltionDB_getProjectComponents() - > Could not execute the following SQL query: " + sql);
    return -1;
  }  
  //SetCache1
  if( fwInstallationDBCache_setCache("_getProjectComponents", parameters, componentsInfo) == 0 ) {
  }
  //EndSetCache
  
  return 0;
}    

/** This function registers in the System Configuration DB the connection between two dist-peers
  @param peer1Name Name of the first peer
  @param peer2Name Name of the second peer
  @return 0 if OK, -1 if errors
*/
int fwInstallationDB_addSystemConnection(string peer1Name, string peer2Name)
{
  int peer1Id, peer2Id;
  string sql;

  if(fwInstallationDB_isSystemRegistered(peer1Id, peer1Name, 1) == 0 && peer1Id != -1 &&
     fwInstallationDB_isSystemRegistered(peer2Id, peer2Name, 1) == 0 && peer2Id != -1)
  {

    dyn_mixed record;
    record[1] = peer1Id;
    record[2] = peer2Id;
    
    sql = "INSERT INTO FW_SYS_STAT_SYSTEM_CONNECT(peer_1_id, peer_2_id, valid_from) values(:1, :2, SYSDATE)";
    if(fwInstallationDB_execute(sql, record)) {fwInstallation_throw("fwInstallationDB_addSystemConnection() -> Could not execute the following SQL: " + sql); return -1;};
  }
  else{
    fwInstallation_throw("fwInstallationDB_addSystemConnection(): Cannot add distributed system connection between " + peer1Name + " and " + peer2Name + " as they cannot be found in the DB");
    return -1;
  }

  return 0;  
}

/** This function unregisters from the System Configuration DB the connection between two dist-peers
  @param peer1Name Name of the first peer
  @param peer2Name Name of the second peer
  @return 0 if OK, -1 if errors
*/
int fwInstallationDB_removeSystemConnection(string peer1Name, string peer2Name)
{
  int peer1Id, peer2Id;
  string sql;
  
  if(fwInstallationDB_isSystemRegistered(peer1Id, peer1Name, 1) == 0 && peer1Id != -1 &&
     fwInstallationDB_isSystemRegistered(peer2Id, peer2Name, 1) == 0 && peer2Id != -1)
  {
    dyn_mixed record;
    record[1] = peer1Id;
    record[2] = peer2Id;
    
    sql = "delete FW_SYS_STAT_SYSTEM_CONNECT WHERE (peer_1_id = :1 AND peer_2_id = :2) or (peer_1_id = :2 AND peer_2_id = :1)";
    if(fwInstallationDB_execute(sql, record)) {fwInstallation_throw("fwInstallationDB_removeSystemConnection() -> Could not execute the following SQL: " + sql); return -1;};
  }
  else{
    fwInstallation_throw("fwInstallationDB_removeSystemConnection(): Cannot remove distributed system connection between " + peer1Name + " and " + peer2Name + " as they cannot be found in the DB");
    return -1;
  }
  
  return 0;
}

/** This function reads from the System Configuration DB the project and host properties for a PVSS system
  @param systemName Name of the PVSS system
  @param projectSystemHostInfo projects and hosts properties as a dyn_dyn_mixed matrix
  @return 0 if OK, -1 if errors
*/
int fwInstallationDB_getSystemProjectHost(string systemName, dyn_dyn_mixed &projectSystemHostInfo)
{
  //GetCache1
  dyn_string parameters = makeDynString(systemName);
  if( fwInstallationDBCache_getCache("_getSystemProjectHost", parameters, projectSystemHostInfo ) == 0 ) {
  	return 0;
  }
  //EndGetCache1

  int id;
  dyn_string exceptionInfo;
  dyn_dyn_mixed aRecords;
  string sql;

  dynClear(aRecords);

  dyn_mixed var;
  var[1] = systemName;

  sql = "SELECT P.PROJECT_NAME, S.SYSTEM_NAME, S.SYSTEM_NUMBER, S.DIST_PORT, C.HOSTNAME FROM FW_SYS_STAT_PVSS_PROJECT P, FW_SYS_STAT_PVSS_SYSTEM S, FW_SYS_STAT_COMPUTER C WHERE P.COMPUTER_ID = C.ID AND P.SYSTEM_ID = S.ID AND S.SYSTEM_NAME = :1";
  if(fwInstallationDB_executeQuery(sql, var, aRecords))
  {
    fwInstallation_throw("fwInstallationDB_getSystemProjectHost() -> Could not execute the following SQL query: " + sql);
    return -1;
  }
  
  projectSystemHostInfo = aRecords;
  
  //SetCache1
  if( fwInstallationDBCache_setCache("_getSystemProjectHost", parameters, projectSystemHostInfo ) == 0 ) {
  }
  //EndSetCache
  
  return 0;
}

/** This function reads from the System Configuration DB the groups of components registered in a project
  @param group Name of the group of components
  @param projectGroupInfo group properties
  @param projectName project name
  @param computerName hostname
  @return 0 if OK, -1 if errors
*/
int fwInstallationDB_getProjectGroupProperties(string group, 
                                               dyn_mixed &projectGroupInfo, 
                                               string projectName = "", 
                                               string computerName = "")
{
  //GetCache1
  dyn_string parameters = makeDynString(group, projectName, computerName);
  if( fwInstallationDBCache_getCache("_getProjectGroupProperties", parameters, projectGroupInfo) == 0 ) {
  	return 0;
  }
  //EndGetCache1

  int project_id, group_id;
  dyn_string exceptionInfo;
  string sql;
  dyn_dyn_mixed aRecords;
  
  
  dynClear(exceptionInfo);
  
  if(projectName == "")
    projectName = PROJ;
  
  if(computerName == "")
    computerName = fwInstallation_getHostname();
  
  computerName = strtoupper(computerName);
  
  if(fwInstallationDB_isProjectRegistered(project_id, projectName, computerName) != 0){
    fwInstallation_throw("fwInstallationDB_getProjectGroupProperties() - > Cannot access the DB.");
    return -1;
  }
  
  if(project_id == -1){
      fwInstallation_throw("fwInstallationDB_getProjectGroupProperties() - > Project: "+ projectName + " in computer: " + " Computer: " + computerName + " is not registered in DB.");
      return -1;      
  }
  
  if(fwInstallationDB_isGroupRegistered(group, group_id) != 0){
    fwInstallation_throw("fwInstallationDB_getProjectGroupProperties() - > Cannot access the DB.");
    return -1;
  }
      
  if(group_id == -1){
      fwInstallation_throw("fwInstallationDB_getProjectGroupProperties() - > Group: " + group + " is not registered in DB.");
      return -1;      
  }
  
  dyn_mixed var;
  var[1] = project_id;
  var[2] = group_id;

  sql = "SELECT requested_by, request_date, overwrite_files,  force_required, is_silent, scheduled_inst_date " + 
        "FROM fw_sys_stat_project_groups WHERE project_id = :1 AND group_id = :2 AND valid_until IS NULL";
  if(fwInstallationDB_executeQuery(sql, var, aRecords))
  {
    fwInstallation_throw("fwInstalltionDB_getProjectGroupProperties() - > Could not execute the following SQL query: " + sql);
    return -1;
  }   
  
  if(dynlen(aRecords) > 0)
    projectGroupInfo = aRecords[1];
   
  //SetCache1
  if( fwInstallationDBCache_setCache("_getProjectGroupProperties", parameters, projectGroupInfo) == 0 ) {
  }
  //EndSetCache
  
  return 0;
}

/** This function reads from the System Configuration DB the current list of components installed in a project
  @param componentsInfo components' properties
  @param projectName project name
  @param computerName hostname
  @return 0 if OK, -1 if errors
*/
int fwInstallationDB_getCurrentProjectComponents(dyn_dyn_mixed &componentsInfo, 
                                                 string projectName = "", 
                                                 string computerName = "")
{
  //GetCache1
  dyn_string parameters = makeDynString(projectName, computerName);
  if( fwInstallationDBCache_getCache("_getCurrentProjectComponents", parameters, componentsInfo ) == 0 ) {
  	return 0;
  }
  //EndGetCache1

  int project_id;
  dyn_string exceptionInfo;
  string sql;
  dyn_dyn_mixed aRecords;
  
  
  dynClear(exceptionInfo);
  
  if(projectName == "")
    projectName = PROJ;
  
  if(computerName == "")
    computerName = fwInstallation_getHostname();
  
  computerName = strtoupper(computerName);
  
  if(fwInstallationDB_isProjectRegistered(project_id, projectName, computerName) != 0){
    fwInstallation_throw("fwInstallationDB_getCurrentProjectComponents() - > Cannot access the DB.");
    return -1;
  }
  
  if(project_id == -1){
      fwInstallation_throw("fwInstallationDB_getCurrentProjectComponents() - > Project: "+ projectName + " in computer: " + " Computer: " + computerName + " is not registered in DB.");
      return -1;      
  }
  
  dyn_mixed var;
  var[1] = project_id;
  var[2] = strtoupper(computerName);

   sql = "SELECT c.component_name, c.component_version, c.is_subcomponent, ic.description_file, ic.installation_ok, ic.dependencies_ok, ic.pending_postinstalls " +
         "FROM fw_sys_stat_component c, fw_sys_stat_proj_install_comps ic, fw_sys_stat_computer h " +
         "WHERE ic.project_id = :1 AND c.id = ic.component_id AND ic.valid_until IS NULL and ic.computer_id = h.id and h.valid_until is null and h.hostname = :2";
   

  if(fwInstallationDB_executeQuery(sql, var, aRecords))
  {
    fwInstallation_throw("fwInstallationDB_getCurrentProjectComponents() - > Could not execute the following SQL query: " + sql);
    return -1;
  }   
//DebugN(sql, var, aRecords);
  
  if(dynlen(aRecords) > 0)
    componentsInfo = aRecords;
  //SetCache1
  if( fwInstallationDBCache_setCache("_getCurrentProjectComponents", parameters, componentsInfo ) == 0 ) {
  }
  //EndSetCache
  
  return 0;
}

/** This function registers in the System Configuration DB the mapping between Windows and Linux paths, e.g. /afs/cern.ch - p:
  @param windowsPath Windows path
  @param linuxPath Linux path
  @return 0 if OK, -1 if errors
*/
int fwInstallationDB_registerPathMapping(string windowsPath, string linuxPath)
{
  int pathId;
  string sql;
  dyn_string exceptionInfo;
  dynClear(exceptionInfo);
  
  
  
  //Check if already exists:
  if(fwInstallationDB_isPathMappingRegistered(pathId, windowsPath, linuxPath) != 0 )
  {
    fwInstallation_throw("fwInstallationDB_registerPathMapping() -> DB Connection error");  
    return -1;
  }
  
  if(pathId == -1)
  {
    dyn_mixed record;
    record[1] = windowsPath;
    record[2] = linuxPath;
    
    sql = "INSERT INTO FW_SYS_STAT_PATH_MAPPING(id, windows_path, linux_path) VALUES ((fw_sys_stat_path_mapping_sq.NEXTVAL), :1, :2)";
    if(fwInstallationDB_execute(sql, record, false)) {fwInstallation_throw("fwInstallationDB_registerPathMapping() -> Could not execute the following SQL: " + sql); return -1;};

  }else{
    dyn_mixed record;
    record[1] = windowsPath;
    record[2] = linuxPath;
    record[3] = pathId;
    sql = "UPDATE FW_SYS_STAT_PATH_MAPPING SET windows_path = :1, linux_path = :2 WHERE id = :3";
    if(fwInstallationDB_execute(sql, record, false)) {fwInstallation_throw("fwInstallationDB_registerPathMapping() -> Could not execute the following SQL: " + sql); return -1;};
  }

  return 0;  
}

/** This function check from the System Configuration DB if a path mapping is registered
  @param id DB index of the path mapping
  @param windowsPath Windows path, e.g. P:
  @param linuxPath Linux path, e.g. /afs/cern.ch
  @return 0 if OK, -1 if errors
*/
int fwInstallationDB_isPathMappingRegistered(int &id, string windowsPath, string linuxPath)
{
  //GetCache1
  dyn_string parameters = makeDynString(windowsPath, linuxPath);
  if( fwInstallationDBCache_getCache("_isPathMappingRegistered", parameters, id) == 0 ) {
  	return 0;
  }
  //EndGetCache1

  dyn_string exceptionInfo;
  dyn_dyn_mixed aRecords;
  
  id = -1;
  dynClear(aRecords);
  
  dyn_mixed var;
  var[1] = windowsPath;
  var[2] = linuxPath;

  string sql = "SELECT id FROM FW_SYS_STAT_PATH_MAPPING WHERE windows_path = :1 AND linux_path = :2";
         
  if(fwInstallationDB_executeQuery(sql, var, aRecords))
  {
    fwInstallation_throw("fwInstallationDB_isPathMappingRegistered() -> Could not execute the following SQL query: " + sql);
    return -1;
  }  

  if(dynlen(aRecords) > 0) 
    id = aRecords[1][1];
  else
    id = -1;
  
  //SetCache1
  if( fwInstallationDBCache_setCache("_isPathMappingRegistered", parameters, id) == 0 ) {
  }
  //EndSetCache
  
  return 0;
}


/** This function unregisters from the System Configuration DB a path mapping
  @param windowsPath Windows path, e.g. P:
  @param linuxPath Linux path, e.g. /afs/cern.ch
  @return 0 if OK, -1 if errors
*/
int fwInstallationDB_unregisterPathMapping(string windowsPath, string linuxPath)
{
  int pathId = -1;
  string sql;
    
  dyn_string exceptionInfo;
  dyn_dyn_mixed aRecords;
  
  dynClear(exceptionInfo);
  
 
  //Check if already exists:
  if(fwInstallationDB_isPathMappingRegistered(pathId, windowsPath, linuxPath) != 0)
  {
    fwInstallation_throw("fwInstallationDB_unregisterPathMapping() -> Could not access DB. Check connection parameters.");
    return -1;
  }
  
  if(pathId == -1)
    return 0;

  dyn_mixed record;
  record[1] = pathId;
    
  sql = "DELETE FROM FW_SYS_STAT_PATH_MAPPING WHERE id = :1";
      
  if(fwInstallationDB_execute(sql, record, false)) {fwInstallation_throw("fwInstallationDB_unregisterPathMapping() -> Could not execute the following SQL: " + sql); return -1;};

  return 0;  
}

/** This function reads from the System Configuration DB the path mapped to a particular path in a different operating system
  @param path path, e.g. P: or /afs/cern.ch
  @param mappedPath mapped path in the other operating system, e.g. /afs/cern.ch or P:
  @return 0 if OK, -1 if errors
*/
int fwInstallationDB_getMappedPath(string path, string &mappedPath)
{
  //GetCache1
  dyn_string parameters = makeDynString(path);
  if( fwInstallationDBCache_getCache("_getMappedPath", parameters, mappedPath) == 0 ) {
  	return 0;
  }
  //EndGetCache1

  dyn_string exceptionInfo;
  string sql;
  dyn_dyn_mixed aRecords;
  
  dynClear(exceptionInfo);
  dynClear(aRecords);  

  dyn_mixed var;
  var[1] = path;
      
  sql = "SELECT windows_path, linux_path FROM fw_sys_stat_path_mapping WHERE windows_path = :1 OR linux_path = :1";
  if(fwInstallationDB_executeQuery(sql, var, aRecords))
  {
      fwInstallation_throw("fwInstallationDB_getMappedPath() -> Could not execute the following SQL query: " + sql);
      return -1;
  }  

  if(dynlen(aRecords)) {          
     if(aRecords[1][1] == path)
       mappedPath = aRecords[1][2];
     else
       mappedPath = aRecords[1][1];
  }
  
  //SetCache1
  if( fwInstallationDBCache_setCache("_getMappedPath", parameters, mappedPath) == 0 ) {
  }
  //EndSetCache
  
  return 0;
}

/** This function reads from the System Configuration DB all path mappings defined
  @param pattern search string pattern
  @param pathMapping array of path mappings a dyn_mixed
  @return 0 if OK, -1 if errors
*/
int fwInstallationDB_getAllMappedPaths(string pattern, dyn_mixed &pathMapping)
{
  //GetCache1
  dyn_string parameters = makeDynString(pattern);
  if( fwInstallationDBCache_getCache("_getAllMappedPaths", parameters, pathMapping) == 0 ) {
  	return 0;
  }
  //EndGetCache1

  dyn_string exceptionInfo;
  string sql;
  dyn_dyn_mixed aRecords;
  
  dynClear(exceptionInfo);
  dynClear(aRecords);  

  dyn_mixed var;

  sql = "SELECT windows_path, linux_path FROM fw_sys_stat_path_mapping WHERE windows_path like \'%" + pattern + "%\' OR linux_path like \'%" + pattern + "%\'";
  if(fwInstallationDB_executeDBQuery(sql, aRecords) != 0)
  {
      fwInstallation_throw("fwInstallationDB_getAllMappedPaths() -> Could not execute the following SQL query: " + sql);
      return -1;
  }  
  pathMapping = aRecords;
  //SetCache1
  if( fwInstallationDBCache_setCache("_getAllMappedPaths", parameters, pathMapping) == 0 ) {
  }
  //EndSetCache
  
  return 0;
}



/** This function reads from the System Configuration DB all PVSS systems in a computer
  @param computer hostname
  @param systems list of PVSS systems found
  @return 0 if OK, -1 if errors
*/
int fwInstallationDB_getComputerSystems(string computer, dyn_string &systems)
{
  //GetCache1
  dyn_string parameters = makeDynString(computer);
  if( fwInstallationDBCache_getCache("_getComputerSystems", parameters, systems) == 0 ) {
  	return 0;
  }
  //EndGetCache1

  dyn_string exceptionInfo;
  dyn_dyn_mixed aRecords;
  
  dyn_mixed var;
  var[1] = strtoupper(computer);

  string sql = "SELECT s.system_name FROM fw_sys_stat_pvss_system s where s.valid_until is null and s.id in (select system_id from fw_sys_stat_pvss_project where computer_id = (select id from fw_sys_stat_computer where hostname = :1 and valid_until is null))";
  dynClear(aRecords);
  if(fwInstallationDB_executeQuery(sql, var, aRecords))
  {
    fwInstallation_throw("fwInstallationDB_getComputerSystems() -> Could not execute the following SQL query: " + sql);
    return -1;
  }  

  if(dynlen(aRecords))
    systems = aRecords[1];
  
  //SetCache1
  if( fwInstallationDBCache_setCache("_getComputerSystems", parameters, systems) == 0 ) {
  }
  //EndSetCache
  
  return 0;

}


/** This function reads from the System Configuration DB the properties of the components wrongly installed all projects
  @param componentsInfo component properties
  @return 0 if OK, -1 if errors
*/
int fwInstallationDB_getComponentsIncorrectlyInstalled(dyn_dyn_mixed &componentsInfo)
{
  //GetCache1
  dyn_string parameters = makeDynString();
  if( fwInstallationDBCache_getCache("_getComponentsIncorrectlyInstalled", parameters, componentsInfo ) == 0 ) {
  	return 0;
  }
  //EndGetCache1

  dyn_string exceptionInfo;
  dyn_dyn_mixed aRecords;
  
  dyn_mixed var;
  string sql = "SELECT H.HOSTNAME, P.PROJECT_NAME, C.COMPONENT_NAME, C.COMPONENT_VERSION FROM FW_SYS_STAT_COMPONENT C, FW_SYS_STAT_PVSS_PROJECT P, FW_SYS_STAT_PROJ_INSTALL_COMPS PC, FW_SYS_STAT_COMPUTER H WHERE C.VALID_UNTIL IS NULL AND P.VALID_UNTIL IS NULL AND PC.VALID_UNTIL IS NULL AND PC.COMPONENT_ID = C.ID AND P.ID = PC.PROJECT_ID AND PC.INSTALLATION_OK = 1 AND H.VALID_UNTIL IS NULL AND H.ID = P.COMPUTER_ID ORDER BY H.HOSTNAME, P.PROJECT_NAME";

  dynClear(aRecords);
  if(fwInstallationDB_executeQuery(sql, var, aRecords))
  {
    fwInstallation_throw("fwInstallationDB_getCompomponentsIncorrectlyInstalled() -> Could not execute the following SQL query: " + sql);
    return -1;
  }  
  
  componentsInfo = aRecords;
  //SetCache1
  if( fwInstallationDBCache_setCache("_getComponentsIncorrectlyInstalled", parameters, componentsInfo ) == 0 ) {
  }
  //EndSetCache
  
  return 0;
}

/** This function reads from the System Configuration DB name of a systems with a particular number
  @param sysNumber PVSS system number
  @param name PVSS system name
  @param reduNr redundancy number (not used. Obsolete, legacy)
  @return 0 if OK, -1 if errors
*/
int fwInstallationDB_getSystemName(string sysNumber, string &name, int reduNr = 1)
{
  //GetCache1
  dyn_string parameters = makeDynString(sysNumber, reduNr);
  if( fwInstallationDBCache_getCache("_getSystemName", parameters, name) == 0 ) {
  	return 0;
  }
  //EndGetCache1

  dyn_string exceptionInfo;
  dyn_dyn_mixed aRecords;
  
  dyn_mixed var;
  var[1] = sysNumber;

  string sql = "SELECT SYSTEM_NAME FROM FW_SYS_STAT_PVSS_SYSTEM WHERE VALID_UNTIL IS NULL AND SYSTEM_NUMBER = :1";
  
  dynClear(aRecords);
  if(fwInstallationDB_executeQuery(sql, var, aRecords))
  {
    fwInstallation_throw("fwInstallationDB_getSystemName() -> Could not execute the following SQL query: " + sql);
    return -1;
  }  

  if(dynlen(aRecords) > 0)
    name = aRecords[1][1];
  
  //SetCache1
  if( fwInstallationDBCache_setCache("_getSystemName", parameters, name) == 0 ) {
  }
  //EndSetCache
  
  return 0;

}
/** This function checks if the project autoregistration is enabled
  @param autoreg_enabled Automatic registration enabled.
  @return 0 if OK, -1 if errors
*/
int fwInstallationDB_getProjectAutoregistration(int &autoreg_enabled)
{
  dyn_string exceptionInfo;
  dyn_dyn_mixed aRecords;
  
  string sql = "SELECT PROJECT_AUTOREG FROM FW_SYS_STAT_CONFIGURATION WHERE rownum=1";
  dyn_mixed var;
  
  dynClear(aRecords);
  if(fwInstallationDB_executeQuery(sql, var, aRecords))
  {
    fwInstallation_throw("fwInstallationDB_getProjectAutoregistration() -> Could not execute the following SQL query: " + sql);
    return -1;
  }  

  if(dynlen(aRecords) > 0)
    autoreg_enabled = aRecords[1][1];
 
  return 0;
}

/** This function sets the projects autoregistration 
  @param autoreg_enabled Automatic registration enabled.
  @return 0 if OK, -1 if errors
*/
int fwInstallationDB_setProjectAutoregistration(int autoreg_enabled)
{
  dyn_mixed record;
  record[1] = autoreg_enabled;
        
  string sql = "UPDATE FW_SYS_STAT_CONFIGURATION SET PROJECT_AUTOREG = :1 WHERE ROWNUM=1";
  if(fwInstallationDB_execute(sql, record)) {fwInstallation_throw("fwInstallationDB_setProjectAutoregistration() -> Could not execute the following SQL: " + sql); return -1;};
  
  return 0;
}
