// $License: NOLICENSE


/**@file
 *
 * This library contains the functions necessary to register and 
 * unregister upgrade request of the installation tool in the System Configuration DB.
 * The functions in these library are not intended to be called 
 * from user scripts
 *
 * @author Fernando Varela Rodriguez (EN-ICE)
 * @date   September 2010
 */

#uses "fwInstallation.ctl"
/** Version of this library.
 * Used to determine the coherency of all libraries of the installtion tool
 * @ingroup Constants
*/
const string csFwInstallationDBUpgradeLibVersion = "6.2.4";

/////Upgrade of the installation tool:
const int FW_INSTALLATION_DB_TOOL_UPGRADE_SOURCE_DIR = 1;
const int FW_INSTALLATION_DB_TOOL_UPGRADE_TARGET_DIR = 2;
const int FW_INSTALLATION_DB_TOOL_UPGRADE_SAFE_MODE = 3;
const int FW_INSTALLATION_DB_TOOL_UPGRADE_REQUESTED_ON = 4;
const int FW_INSTALLATION_DB_TOOL_UPGRADE_EXECUTED_ON = 5;
//@} // end of constants

//Beginning executable code:
/** This function registers in the database the upgrade of the installation tool
  @param upgradeInfo dyn_mixed array containing the information necessary to upgrade the installation tool
  @param host name of the host where the project runs
  @param project name of the project where the compnent has to be reinstalled
  @return 0 if OK, -1 if error
*/
int fwInstallationDBUpgrade_registerProjectToolUpgradeRequest(dyn_mixed upgradeInfo,
                                                       string host = "", 
                                                       string project = "")
{
  string sql;
  int project_id = -1;
  dyn_string exceptionInfo;
  dyn_dyn_mixed aRecords;
  dynClear(exceptionInfo);

  if(project == "")
    project = PROJ;
  
  if(host == "")
    host = strtoupper(fwInstallation_getHostname());

  //Check if project is registered:
  if(fwInstallationDB_isProjectRegistered(project_id, project, host) != 0)
  {
    fwInstallation_throw("ERROR: fwInstallationDBUpgrade_unregisterProjectToolUpgradeRequest() -> Could not check if project: " + project + " in host: " + host + " is registered in DB. Check DB connection parameters.");
    return -1;
  }
  else if(project_id == -1)
  {
     fwInstallation_throw("ERROR: fwInstallationDBUpgrade_unregisterProjectToolUpgradeRequest() -> Project " + project + " in host: " + host + " not yet registered in the DB.");
     return -1;  
  }
  
  dyn_mixed record;
  record[1] = upgradeInfo[1];
  record[2] = upgradeInfo[2];
  record[3] = upgradeInfo[3];
//  record[4] = upgradeInfo[4];
//  record[5] = upgradeInfo[5];
  record[4] = project_id;
  
  //Check if project is registered:
  bool exists = false;
  if(fwInstallationDBUpgrade_isProjectToolUpgradeRequestRegistered(project_id, exists) == -1)
  {
    fwInstallation_throw("fwInstallationDBUpgrade_registerProjectToolUpgradeRequest() -> Could not check if there is a pending tool upgrade for project " + project + " in host: " + host);
    return -1;
  }
  
  if(exists)
  {
    sql = "UPDATE FW_SYS_STAT_TOOL_UPGRADE SET SOURCE_DIR = :1, TARGET_DIR = :2, SAFE_MODE = :3, REQUESTED_ON = SYSDATE " + 
          "WHERE PROJECT_ID = :4 AND EXECUTED_ON IS NULL";
  }
  else
  {    
    sql = "INSERT INTO FW_SYS_STAT_TOOL_UPGRADE(ID, SOURCE_DIR, TARGET_DIR, SAFE_MODE, PROJECT_ID, REQUESTED_ON) " + 
          "VALUES(FW_SYS_STAT_TOOL_UPGRADE_SQ.NEXTVAL, :1, :2, :3, :4, SYSDATE)";
  }
  
  if(fwInstallationDB_execute(sql, record)) {fwInstallation_throw("fwInstallationDBUpgrade_registerProjectToolUpgradeRequest() -> Could not execute the following SQL: " + sql); return -1;};

  return 0;  
}
/** This function unregisters from the database the upgrade of the installation tool in a given project
  @param host name of the host where the project runs
  @param project name of the project
  @return 0 if OK, -1 if error
*/

int fwInstallationDBUpgrade_unregisterProjectToolUpgradeRequest(string host = "", string project = "")
{
  string sql;
  int project_id = -1;
  
  dyn_string exceptionInfo;
  dyn_dyn_mixed aRecords;

  dynClear(exceptionInfo);

  if(project == "")
    project = PROJ;
  
  if(host == "")
    host = strtoupper(fwInstallation_getHostname());
  
  //Check if project is registered:
  if(fwInstallationDB_isProjectRegistered(project_id, project, host) != 0)
  {
    fwInstallation_throw("fwInstallationDBUpgrade_unregisterProjectToolUpgradeRequest() -> Could not check if project: "+project+" in host: " + host + " is registered in DB. Check DB connection parameters.");
    return -1;
  }
  else if(project_id == -1)
  {
     fwInstallation_throw("fwInstallationDBUpgrade_unregisterProjectToolUpgradeRequest() -> Project "+project+" in host: " + host + " not yet registered in the DB.");
     return -1;  
  }

  dyn_mixed record;
  record[1] = project_id;
  sql = "UPDATE FW_SYS_STAT_TOOL_UPGRADE SET EXECUTED_ON = SYSDATE WHERE PROJECT_ID = :1 AND EXECUTED_ON IS NULL";
         
  if(fwInstallationDB_execute(sql, record)) {fwInstallation_throw("fwInstallationDBUpgrade_unregisterProjectToolUpgradeRequest() -> Could not execute the following SQL: " + sql); return -1;};

  return 0;  
}


/** This function checks if an upgrade of the installation tool has already 
*    been registered in the DB for a given project
*  @param project_id DB index of the project
*  @param exists TRUE if a pending request already exists
*  @return true if the upgrade request already exists, otherwise false
*/
int fwInstallationDBUpgrade_isProjectToolUpgradeRequestRegistered(int project_id, bool &exists)
{
  dyn_string exceptionInfo;
  dyn_dyn_mixed aRecords;
  string sql;

  dynClear(aRecords);
  dyn_mixed var;
  
  exists = false;
  var[1] = project_id;
  
  sql = "SELECT project_id FROM fw_sys_stat_tool_upgrade WHERE project_id = :1 AND executed_on is null";
  
  if(g_fwInstallationSqlDebug)
    DebugN(sql);
  
  if(fwInstallationDB_executeQuery(sql, var, aRecords))
  {
    fwInstallation_throw("ERROR: fwInstallationDBUpgrade_isProjectToolUpgradeRequestRegistered() -> Could not execute the following SQL query: " + sql);
    return -1;
  }  

  if(dynlen(aRecords) > 0)   
    exists = true;

  
  return 0;
} 

/** This function retrieves the pending upgrade request for the installation tool in a project
  @param upgradeInfo dyn_mixed array containing the upgrade information
  @param host name of the host where the project runs
  @param project name of the project
  @return 0 if OK, -1 if error
*/
int fwInstallationDBUpgrade_getProjectToolUpgradeRequest(dyn_mixed &upgradeInfo, string host = "", string project = "")
{
  int project_id;
  dyn_string exceptionInfo;
  dyn_dyn_mixed aRecords;
  string sql;

  dynClear(aRecords);
  dynClear(upgradeInfo);
    
  if(project == "")
    project = PROJ;
  
  if(host == "")
    host = strtoupper(fwInstallation_getHostname());

  //Check if project is registered:
  if(fwInstallationDB_isProjectRegistered(project_id, project, host) != 0)
  {
    fwInstallation_throw("ERROR: fwInstallationDBUpgrade_getProjectToolUpgradeRequest() -> Could not check if project: "+project+" in host: " + host + " is registered in DB. Check DB connection parameters.");
    return -1;
  }
  else if(project_id == -1)
  {
     fwInstallation_throw("ERROR: fwInstallationDBUpgrade_getProjectToolUpgradeRequest() -> Project "+project+" in host: " + host + " not yet registered in the DB.");
     return -1;  
  }
  
  dyn_mixed var;
  var[1] = project_id;
  
  sql = "select source_dir, target_dir, safe_mode, requested_on "
        + "from fw_sys_stat_tool_upgrade where project_id = :1 and executed_on is null";
  
  if(fwInstallationDB_executeQuery(sql, var, aRecords))
  {
    fwInstallation_throw("ERROR: fwInstallationDBUpgrade_getProjectToolUpgradeRequest() -> Could not execute the following SQL query: " + sql);
    return -1;
  }  

  if(dynlen(aRecords) > 0 )
    upgradeInfo = aRecords[1];

  return 0;
} 

