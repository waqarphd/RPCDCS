// $License: NOLICENSE


/**@file
 *
 * This library contains builds on top of fwInstallation.ctl and fwInstallationDB.ctl
 * and it contains the functions called by the DB-Agent of the FW Comonent Installation Tool
 * for the synchronization of the contents of the local project and of the System Configuration DB. 
 * The functions in this library are not intended to be called from user scripts
 *
 * @author Fernando Varela Rodriguez (EN-ICE)
 * @version 3.3.10
 * @date   April 2007
 */
#uses "fwInstallation.ctl"
#uses "fwInstallationDB.ctl"
#uses "fwInstallationRedu.ctl"
#uses "CtrlPv2Admin"

/** Version of this library.
 * Used to determine the coherency of all libraries of the installtion tool
 * @ingroup Constants
*/
const string gFwInstallationAgentLibVersion = "6.2.4";

/**
 * @name fwInstallationDB.ctl: Definition of variables

   The following variables are used by the fwInstallationDB.ctl library

 * @{
 */
//Project status:
const int FW_INSTALLATION_DB_PROJECT_OK = 1;
const int FW_INSTALLATION_DB_PROJECT_MISSMATCH = 0;
const int FW_INSTALLATION_DB_PROJECT_NEVER_CHECKED = -1;

//
const int FW_INSTALLATION_DB_STATUS_PVSS_INFO = 1;
const int FW_INSTALLATION_DB_STATUS_PVSS_PATCH_INFO = 2;
const int FW_INSTALLATION_DB_STATUS_HOST_INFO = 3;
const int FW_INSTALLATION_DB_STATUS_PROJECT_INFO = 4;
const int FW_INSTALLATION_DB_STATUS_PATH_INFO = 5;
const int FW_INSTALLATION_DB_STATUS_MANAGER_INFO = 6;
const int FW_INSTALLATION_DB_STATUS_GROUP_INFO = 7;
const int FW_INSTALLATION_DB_STATUS_COMPONENT_INFO = 8;
//const int FW_INSTALLATION_DB_STATUS_EXT_PROCESS_INFO = 9;
const int FW_INSTALLATION_DB_STATUS_DIST_PEERS_INFO = 9;
//const int FW_INSTALLATION_DB_STATUS_REDU_INFO = 10;

const string csFwInstallationDBAgentLibVersion = "3.4.2";

const int FW_INSTALLATION_DB_PVSS_INSTALL_COMPONENT_IDX = 1;
const int FW_INSTALLATION_DB_PVSS_INSTALL_VERSION_IDX = 2;
const int FW_INSTALLATION_DB_PVSS_INSTALL_DESCFILE_IDX = 3;
const int FW_INSTALLATION_DB_PVSS_INSTALL_SOURCEDIR_IDX = 4;
const int FW_INSTALLATION_DB_PVSS_INSTALL_SUBCOMP_IDX = 5;
const int FW_INSTALLATION_DB_PVSS_INSTALL_SUBPATH_IDX = 6;
const int FW_INSTALLATION_DB_PVSS_INSTALL_FORCE_REQUIRED_IDX = 7;
const int FW_INSTALLATION_DB_PVSS_INSTALL_OVERWRITE_FILES_IDX = 8;
const int FW_INSTALLATION_DB_PVSS_INSTALL_SILENT_IDX = 9;
const int FW_INSTALLATION_DB_PVSS_INSTALL_GROUP_IDX = 10;

const int FW_INSTALLATION_DB_PVSS_DELETE_NAME_IDX = 1;
const int FW_INSTALLATION_DB_PVSS_DELETE_VERSION_IDX = 2;

const int FW_INSTALLATION_DB_DB_DELETE_COMPONENT_NAME_IDX = 1;
const int FW_INSTALLATION_DB_DB_DELETE_COMPONENT_VERSION_IDX = 2;
const int FW_INSTALLATION_DB_DB_DELETE_COMPONENT_SUBCOMP_IDX = 3;
const int FW_INSTALLATION_DB_DB_DELETE_COMPONENT_GROUP_IDX = 4;

const int FW_INSTALLATION_DB_DB_INSTALL_COMPONENT_NAME_IDX = 1;
const int FW_INSTALLATION_DB_DB_INSTALL_COMPONENT_VERSION_IDX = 2;
const int FW_INSTALLATION_DB_DB_INSTALL_COMPONENT_SUBCOMP_IDX = 3;
const int FW_INSTALLATION_DB_DB_INSTALL_COMPONENT_GROUP_IDX = 4;
const int FW_INSTALLATION_DB_DB_INSTALL_COMPONENT_DESCFILE_IDX = 5;

const int FW_INSTALLATION_DB_REINSTALL_COMPONENT_NAME_IDX = 1;
const int FW_INSTALLATION_DB_REINSTALL_COMPONENT_VERSION_IDX = 2;
const int FW_INSTALLATION_DB_REINSTALL_COMPONENT_SUBCOMP_IDX = 3;
const int FW_INSTALLATION_DB_REINSTALL_COMPONENT_DESCFILE_IDX = 4;
const int FW_INSTALLATION_DB_REINSTALL_RESTART_PROJECT_IDX = 5;
const int FW_INSTALLATION_DB_REINSTALL_OVERWRITE_FILES_IDX = 6;

//@} // end of constants

///Beginning of executable code:
int fwInstallationDbAgent_terminateOldInstances()
{
  dyn_int alienpids = fwInstallationDBAgent_getOldInstancesPid();
  for(int i=1;i<=dynlen(alienpids);i++){
    fwInstallation_throw("Previous instance of the FW Instllation Tool DB-Agent found with PID=" + alienpids[i] + ". This process will be terminated now...", "INFO", 10);
    string command ="%SystemRoot%/system32/wbem/wmic PROCESS where (commandline like \"%-f fwInstallationAgent.lst%\" and commandline like \"%-PROJ " + PROJ + "%\" and name=\""+fwInstallation_getWCCOAExecutable("ctrl")+".exe\" and processId='"+alienpids[i]+"') delete " ;
//DebugN(command);    
    system(command);
  }
  return 0;
}

dyn_int fwInstallationDBAgent_getOldInstancesPid()
{
  dyn_string pids;
  dyn_int pepinoPids;
  string str;
  string filename = PROJ_PATH + "config/Bobby.txt";  
  system("%SystemRoot%/system32/wbem/wmic PROCESS  where \"commandline like '%-f fwInstallationAgent.lst%' and name='"+fwInstallation_getWCCOAExecutable("ctrl")+".exe'\" get processId, creationDate > " + filename);  
  delay(1);  
  file f = fopen(filename,"r");
  int pidbobby; 
  fseek(f,2,SEEK_SET );   
  string linetext; 
  bool foundHeader =false;
  while (feof(f)==0) // so long as it is not at the end   
  { 
    string name, version,path;   
    str="";        
    fgets(str,1,f);
    if(str=="\n"){
      if(!foundHeader){
        //finally found first line break so the characters until now are dropped
        foundHeader=true;
        linetext="";
        continue;        
      }
      else{
         //a new line proccressid/creationtime starts, store previous one
         dynAppend(pids,linetext);
         linetext="";
      }                  
    }    
    else{      
      linetext = linetext + str;
    }
  }    
  //return only alien lines, wmic is ordeing by creation time. Newest on button
  dynRemove(pids,dynlen(pids));
  //scan pids and return only pids with no time
  for(int i=1;i<=dynlen(pids);i++){
    dyn_string parts = strsplit(pids[i]," ");
    dynAppend(pepinoPids, parts[3]);
  }
  return pepinoPids;
}

/** This function executes all pending reinstallation actions for the project
  @param restartProject flag indicating if project restart is required. Possible values are:
  
    0: project restart is not required
    
    1: project restart required
       
    2: project restart not required but post-installation scripts must be run
  @return 0 if OK, -1 if errors
*/
int fwInstallationDBAgent_executeProjectPendingReinstallations(int &restartProject)
{
  string project = PROJ;
  string host = fwInstallation_getHostname();
  dyn_dyn_mixed reinstallationsInfo;
  string component;
  bool status;
  string dontRestartProject;
  int error = 0;
  dyn_int xmlRestart = 0;
  int restartRequired = 0;
  
  fwInstallationDB_getProjectPendingReinstallations(host, project, reinstallationsInfo);
  if(dynlen(reinstallationsInfo) <= 0)//nothing to be done
    return 0;
    
  for(int i = 1; i <= dynlen(reinstallationsInfo); i++)
  {
    string descFile = fwInstallationDBAgent_getComponentFile(reinstallationsInfo[i][FW_INSTALLATION_DB_REINSTALL_COMPONENT_DESCFILE_IDX]);   
    string sourceDir = descFile;
    strreplace(sourceDir, "\\", "/");
    dyn_string dss = strsplit(sourceDir, "/");
    strreplace(sourceDir, dss[dynlen(dss)], "");
    
///////////    
    fwInstallation_throw("INFO: fwInstallationDBAgent_executeProjectPendingReinstallations() -> Installating component: " + reinstallationsInfo[i][FW_INSTALLATION_DB_REINSTALL_COMPONENT_DESCFILE_IDX], "INFO", 10);
///////////
//    fwInstallationDB_storeInstallationLog();
    fwInstallation_installComponent(descFile,
                                    sourceDir,
                                    reinstallationsInfo[i][FW_INSTALLATION_DB_REINSTALL_COMPONENT_SUBCOMP_IDX],
                                    component,
                                    status,
                                    dontRestartProject,
                                    "",
                                    false,
                                    reinstallationsInfo[i][FW_INSTALLATION_DB_REINSTALL_OVERWRITE_FILES_IDX]);
 
    //Unregister this installation:
    fwInstallationDB_unregisterProjectReinstallation(host, project, reinstallationsInfo[i][FW_INSTALLATION_DB_REINSTALL_COMPONENT_NAME_IDX], reinstallationsInfo[i][FW_INSTALLATION_DB_REINSTALL_COMPONENT_VERSION_IDX]);    
       
    //Check if component installation requires to restart the project:
    if(reinstallationsInfo[i][FW_INSTALLATION_DB_REINSTALL_RESTART_PROJECT_IDX] == 1)
      restartRequired = 1;

     if(strtolower(dontRestartProject) == "yes" )
       dynAppend(xmlRestart, 0);
      
     if(!status)
       ++error;     
   }//end of loop over components.     
  
  //Check if restart project is necessary:
  if(restartProject != 1) //restartProject == 1 means that the function was called with the option to force project restart.
  {
    if(dynContains(xmlRestart, 1) <= 0 ) //None of the reinstalled components requires a project restart
      restartProject = 2; //make sure the post-install scripts run
    
    if(restartRequired == 1)
    {
      restartProject = 1;    //At least one of the reinstallations required to restart the project.
    }
  }
  
  if(error)
    return -1;
  
  return 0; 
}

/** This function sets the synchronization lock, i.e. a kind of semaphore to ensure 
    that not concurrent installation are performed by the agent and the main panel of the installation tool.
  @return 0 if OK, -1 if errors
*/
int fwInstallationDBAgent_setSynchronizationLock()
{
  return dpSet("fwInstallation_agentParametrization.lock", 1);   
}

/** This function releases the synchronization lock.
  @return 0 if OK, -1 if errors
*/
int fwInstallationDBAgent_releaseSynchronizationLock()
{
  
  return dpSet("fwInstallation_agentParametrization.lock", 0);   
}

/** This function returns the current value of the synchronization lock
  @return 1 if the lock is set, 0 if unset
*/
int fwInstallationDBAgent_getSynchronizationLock()
{
  int lock;
  
  while(lock){
    dpGet("fwInstallation_agentParametrization.lock", lock);  
    delay(0, 500);
  }
  
  fwInstallationDBAgent_setSynchronizationLock();  
  
  return lock;
}

/** This function writes to the System Configuration DB result of the synchronization process
  @param status array of flags indicating the result of each of the steps performed during the synchronization process
  @param projectName Name of the project
  @param computerName hostname
  @return 0 if OK, -1 if errors
*/
int fwInstallationDBAgent_setProjectStatus(string projectName = "", string computerName = "")
{
  dyn_string exceptionInfo;
  dyn_dyn_mixed aRecords;
  string sql;

  int project_id;
          
  dynClear(aRecords);

  if(projectName == "")
    projectName = PROJ;
  
  if(computerName = "")
    computerName = fwInstallation_getHostname();
  
  computerName = strtoupper(computerName);

  //
  if(fwInstallationDB_isProjectRegistered(project_id, projectName, computerName) != 0){
   fwInstallation_throw("fwInstallationDBAgent_setProjectStatus() -> Cannot access the DB. Please check connection");
   return -1;       
  }
  else if(project_id == -1){
   fwInstallation_throw("fwInstallationDBAgent_setProjectStatus() -> Project: " + projectName + " in computer: " + computerName + " not registered in DB.");
   return -1;      
  }else{

    dyn_mixed dbInfo, pvssInfo;
    fwInstallationDBAgent_checkComponents(gFwInstallationDBAgentStatus[FW_INSTALLATION_DB_STATUS_COMPONENT_INFO], dbInfo, pvssInfo);
    
    sql = "UPDATE fw_sys_stat_pvss_project SET is_project_ok = " + gFwInstallationDBAgentStatus[FW_INSTALLATION_DB_STATUS_PROJECT_INFO] + 
          ", is_pvss_ok =  " + gFwInstallationDBAgentStatus[FW_INSTALLATION_DB_STATUS_PVSS_INFO] + 
          ", is_patch_ok =  " + gFwInstallationDBAgentStatus[FW_INSTALLATION_DB_STATUS_PVSS_PATCH_INFO] + 
          ", is_host_ok =  " + gFwInstallationDBAgentStatus[FW_INSTALLATION_DB_STATUS_HOST_INFO] + 
          ", is_path_ok =  " + gFwInstallationDBAgentStatus[FW_INSTALLATION_DB_STATUS_PATH_INFO] + 
          ", is_manager_ok =  " + gFwInstallationDBAgentStatus[FW_INSTALLATION_DB_STATUS_MANAGER_INFO] + 
          ", is_group_ok =  " + gFwInstallationDBAgentStatus[FW_INSTALLATION_DB_STATUS_GROUP_INFO] + 
          ", is_component_ok =  " + gFwInstallationDBAgentStatus[FW_INSTALLATION_DB_STATUS_COMPONENT_INFO] + 
//          ", is_ext_process_ok =  " + gFwInstallationDBAgentStatus[FW_INSTALLATION_DB_STATUS_EXT_PROCESS_INFO] + 
          ", is_dist_peers_ok =  " + gFwInstallationDBAgentStatus[FW_INSTALLATION_DB_STATUS_DIST_PEERS_INFO] + 
//          ", is_redu_info_ok =  " + gFwInstallationDBAgentStatus[FW_INSTALLATION_DB_STATUS_REDU_INFO] + 
          ", last_time_checked = SYSDATE WHERE id = " + project_id; 

    if(rdbExecuteSqlStatement(gFwInstallationDBConn, sql)) {fwInstallation_throw("fwInstallationDBAgent_setProjectStatus() -> Could not execute the following SQL: " + sql); return -1;};
  }      
  
  return dpSet("fwInstallation_agentParametrization.db.projectStatus", gFwInstallationDBAgentStatus);
}

/** This function synchronizes the contents of the System Configuration DB and of the local project
  @param restartProject flag indicating if project restart is required. Possible values are:
  
    0: project restart is not required
    
    1: project restart required
       
    2: project restart not required but post-installation scripts must be run
  @return 0 if OK, -1 if errors
*/

int fwInstallationDBAgent_synchronize(int &restartProject)
{
queries = 0;
    //Check if synchronization is necessary: if it is not, delay 
    if( !fwInstallationDBAgent_getForceFullSync() ) {
      int project_id;
      bool needsSynchronize = true;
      if(  fwInstallationDB_needsSynchronize(project_id,needsSynchronize) != 0 ) {
        fwInstallation_throw("fwInstallationDBAgent_synchronize() -> Could not synchronize host information with DB");
      } else {
        if ( needsSynchronize == false ) {
          } else {
            fwInstallationDBCache_clear();
          }
      }
    }
    
  int error;
  
  if(!globalExists("gFwInstallationDBAgentStatus")) 
    addGlobal("gFwInstallationDBAgentStatus", DYN_INT_VAR);
  
  while(!globalExists("gFwInstallationDBAgentStatus"))
  {
    delay(0, 100);
  }
	
  dynClear(gFwInstallationDBAgentStatus);

  //InitializeCache (Moved into fwInstallationAgentConsistencyChecker)

  //Call to synchronization functions:  
  if(fwInstallationDBAgent_synchronizeHostInfo() != 0){
    ++error;
    gFwInstallationDBAgentStatus[FW_INSTALLATION_DB_STATUS_HOST_INFO] = 0;
    fwInstallation_throw("fwInstallationDBAgent_synchronize() -> Could not synchronize host information with DB");
  }
  else
    gFwInstallationDBAgentStatus[FW_INSTALLATION_DB_STATUS_HOST_INFO] = 1;

  if(fwInstallationDBAgent_synchronizePvssSetupInfo() != 0){
    ++error;
    gFwInstallationDBAgentStatus[FW_INSTALLATION_DB_STATUS_PVSS_INFO] = 0;
    gFwInstallationDBAgentStatus[FW_INSTALLATION_DB_STATUS_PVSS_PATCH_INFO] = 0;
    fwInstallation_throw("fwInstallationDBAgent_synchronize() -> Could not synchronize PVSS information with DB");
  }
  else
  {

    gFwInstallationDBAgentStatus[FW_INSTALLATION_DB_STATUS_PVSS_INFO] = 1;
    gFwInstallationDBAgentStatus[FW_INSTALLATION_DB_STATUS_PVSS_PATCH_INFO] = 1;
  }
  
  if(fwInstallationDBAgent_synchronizeProjectInfo() != 0){
      gFwInstallationDBAgentStatus[FW_INSTALLATION_DB_STATUS_PROJECT_INFO] = 0;
      ++error;
      fwInstallation_throw("fwInstallationDBAgent_synchronize() -> Could not synchronize project information with DB");
    }
    else
      gFwInstallationDBAgentStatus[FW_INSTALLATION_DB_STATUS_PROJECT_INFO] = 1;
      

    if(fwInstallationDBAgent_synchronizeProjectPaths() != 0){
      gFwInstallationDBAgentStatus[FW_INSTALLATION_DB_STATUS_PATH_INFO] = 0;
      ++error;
      fwInstallation_throw("fwInstallationDBAgent_synchronize() -> Could not synchronize project paths with DB");
    }
    else
      gFwInstallationDBAgentStatus[FW_INSTALLATION_DB_STATUS_PATH_INFO] = 1;
    
    if(fwInstallationDBAgent_synchronizeProjectManagers() != 0)
    {
      ++error;
      gFwInstallationDBAgentStatus[FW_INSTALLATION_DB_STATUS_MANAGER_INFO] = 0;
      fwInstallation_throw("fwInstallationDBAgent_synchronize() -> Could not synchronize project managers with DB");
    }
    else
      gFwInstallationDBAgentStatus[FW_INSTALLATION_DB_STATUS_MANAGER_INFO] = 1;


    if(fwInstallationDBAgent_synchronizeProjectComponents(restartProject) != 0){
      ++error;
      gFwInstallationDBAgentStatus[FW_INSTALLATION_DB_STATUS_COMPONENT_INFO] = 0;
      fwInstallation_throw("fwInstallationDBAgent_synchronize() -> Could not synchronize project FW components");
    }
    else
      gFwInstallationDBAgentStatus[FW_INSTALLATION_DB_STATUS_COMPONENT_INFO] = 1;
      
    
    if(fwInstallationDBAgent_synchronizeDistPeers() != 0){
      ++error;
      gFwInstallationDBAgentStatus[FW_INSTALLATION_DB_STATUS_DIST_PEERS_INFO] = 0;
      fwInstallation_throw("fwInstallationDBAgent_synchronize() -> Could not synchronize list of dist peers with DB");
    }  
    else
      gFwInstallationDBAgentStatus[FW_INSTALLATION_DB_STATUS_DIST_PEERS_INFO] = 1;
      
    if(fwInstallationDBAgent_synchronizeReduInfo() != 0){
      ++error;
//      gFwInstallationDBAgentStatus[FW_INSTALLATION_DB_STATUS_REDU_INFO] = 0;
      fwInstallation_throw("fwInstallationDBAgent_synchronize() -> Could not synchronize redundant info with DB");
    }  
    else
//      gFwInstallationDBAgentStatus[FW_INSTALLATION_DB_STATUS_REDU_INFO] = 1;
  
  //export current project component list:
  if(fwInstallationDB_registerProjectFwComponents() != 0)
  {
    fwInstallation_throw("fwInstallationAgentDBConsistencyChecker -> Could not export current project component list. Check DB connection...");
  } 
    
  //Write the result of the synchronization process to the db
  if(fwInstallationDBAgent_setProjectStatus() != 0)  
  {
    fwInstallation_throw("fwInstallationDBAgent_synchronize() -> Could not verify PVSS-DB data consistency.");
    ++error;
  }
  
  //Synchronization is done, does not need any more, until change triggered on the DB
  fwInstallationDB_setNeedsSynchronize(false);      
  
//DebugN("End of sync, number of queries was: " + queries);  
queries = 0;  

  //fwInstallationDB_storeInstallationLog();
  if(error){
    fwInstallation_throw("PVSS-System Configuration DB synchronization finished with errors");
    return -1;
  }
  else{
    return 0;  
  }
}

/** This function retrieves from the System Configuration DB the current status of the syncrhonization process
  @param status array of flags indicating the result of each of the steps performed during the synchronization process
  @return 0 if OK, -1 if errors
*/
int fwInstallationDBAgent_checkIntegrity()
{
  string dbPvssVersion;
  string dbPvssOs;
  string pvssPvssVersion;
  string pvssPvssOs;
  dyn_string dbPatches;
  dyn_string pvssPatches;
  dyn_string dbIps;
  dyn_string pvssIps;
  dyn_string dbPaths;
  dyn_string pvssPaths;
  dyn_dyn_mixed dbManagersInfo;
  dyn_dyn_string pvssManagersInfo;
  dyn_mixed dbSystem;
  
  dyn_dyn_mixed dbComponentsInfo;
  dyn_dyn_mixed pvssComponentsInfo;
  dyn_mixed dbHostInfo;
  dyn_mixed dbPvssInfo;
  dyn_mixed dbProjectInfo;
  dyn_mixed pvssProjectInfo;
  dyn_mixed dbExtProcessInfo;
  dyn_mixed pvssExtProcessInfo;
  bool isOk;
  int error = 0;
  
  dyn_string onlyPvssSystemNames, onlyDbSystemNames, onlyPvssComputerNames, onlyDbComputerNames;
  dyn_int onlyPvssSystemNumbers, onlyDbSystemNumbers;
  
  //dynClear(status);
  
  //TODO check with FV if this is supposed to be done (commented out on newer version, with fewer argumentS).. 
  // check the need for status as well.
  //if(fwInstallationDBAgent_checkProjectPvssInfo(isOk, dbPvssInfo, pvssPvssVersion, pvssPvssOs) != 0)
  if(fwInstallationDBAgent_checkProjectPvssInfo(isOk, dbPvssInfo, pvssPvssVersion) != 0)
  {
     fwInstallation_throw("fwInstallationDBAgent_checkIntegrity() -> Could not check consistency between PVSS and DB for PVSS setup info");
     ++error;     
  }
  //status[FW_INSTALLATION_DB_STATUS_PVSS_INFO] =  isOk; 
  
  if(fwInstallationDBAgent_checkProjectPvssPatchesInfo(isOk, dbPatches, pvssPatches) != 0)
  {
     fwInstallation_throw("fwInstallationDBAgent_checkIntegrity() -> Could not check consistency between PVSS and DB for PVSS patch level");
     ++error;     
  }
  //status[FW_INSTALLATION_DB_STATUS_PVSS_PATCH_INFO] =  isOk; 
  
  if(fwInstallationDBAgent_checkHostInfo(isOk, dbHostInfo, pvssIps) != 0)
  {
     fwInstallation_throw("fwInstallationDBAgent_checkIntegrity() -> Could not check consistency between PVSS and DB for host: " + strtoupper(fwInstallation_getHostname()));
     ++error;     
  }
  //status[FW_INSTALLATION_DB_STATUS_HOST_INFO] =  isOk; 
  
  if(fwInstallationDBAgent_checkProjectInfo(isOk, dbProjectInfo, pvssProjectInfo) != 0)
  {
     fwInstallation_throw("fwInstallationDBAgent_checkIntegrity() -> Could not check consistency between PVSS and DB for project: " + PROJ);
     ++error;     
  }
  
  //status[FW_INSTALLATION_DB_STATUS_PROJECT_INFO] =  isOk; 
  
  if(fwInstallationDBAgent_checkProjectPathsInfo(isOk, dbPaths, pvssPaths) != 0)
  {
     fwInstallation_throw("fwInstallationDBAgent_checkIntegrity() -> Could not check consistency between PVSS and DB for project paths");
     ++error;     
  }
  //status[FW_INSTALLATION_DB_STATUS_PATH_INFO] =  isOk; 
  
  if(fwInstallationDBAgent_checkProjectManagersInfo(isOk, dbManagersInfo, pvssManagersInfo) != 0)
  {
     fwInstallation_throw("fwInstallationDBAgent_checkIntegrity() -> Could not check consistency between PVSS and DB for project managers");
     ++error;     
  }
 // status[FW_INSTALLATION_DB_STATUS_MANAGER_INFO] =  isOk; 

  if(fwInstallationDBAgent_checkComponents(isOk, dbComponentsInfo, pvssComponentsInfo) != 0)
  {
     fwInstallation_throw("fwInstallationDBAgent_checkIntegrity() -> Could not check consistency between PVSS and DB for FW components");
     ++error;     
  }
  //status[FW_INSTALLATION_DB_STATUS_COMPONENT_INFO] =  isOk; 

  if(fwInstallationDBAgent_checkDistPeers(isOk, onlyPvssSystemNames, onlyDbSystemNames, onlyPvssComputerNames, onlyDbComputerNames, onlyPvssSystemNumbers, onlyDbSystemNumbers) != 0)
  {
     fwInstallation_throw("fwInstallationDBAgent_checkIntegrity() -> Could not check consistency between PVSS and DB for FW components");
     ++error;     
  }
  //status[FW_INSTALLATION_DB_STATUS_DIST_PEERS_INFO] =  isOk; 

  
  //Set project status:
  /*if(fwInstallationDBAgent_setProjectStatus(status) != 0)
  {
     fwInstallation_throw("fwInstallationDBAgent_checkIntegrity() -> Could not set project status in DB.");
     ++error;     
  }*/
  
  if(error)
    return -1;
  else
    return 0;  
}



/** This function checks the consistency between the current project and the contents of the 
    System Configuration DB for the PVSS setup information
  @param isOk TRUE if DB and local project information is in sync
  @param dbPvssInfo PVSS information in the system configuration DB as a dyn_mixed array
  @param pvssPvssInfo PVSS information from the local project
  @return 0 if OK, -1 if errors
  
  TODO: Check with FV if this is supposed to remain. Activating for now, commented out on last version.
*/

/*int fwInstallationDBAgent_checkProjectPvssInfo(bool &isOk, dyn_mixed &dbPvssInfo, dyn_mixed &pvssPvssInfo)
{
  
  string project = PROJ;  
  string hostname = fwInstallation_getHostname();    
  
  hostname = strtoupper(hostname);
  
  pvssPvssInfo[FW_INSTALLATION_DB_PVSS_INFO_VERSION_IDX] = VERSION_DISP;
  
  if(_WIN32)
    pvssPvssInfo[FW_INSTALLATION_DB_PVSS_INFO_OS_IDX] = "WINDOWS";
  else
    pvssPvssInfo[FW_INSTALLATION_DB_PVSS_INFO_OS_IDX] = "LINUX";
  
  
  dyn_dyn_mixed dbHostPvssInfo; //contains all pvss versions and os in the host
  if(fwInstallationDB_getHostPvssVersions(dbHostPvssInfo)!=0)
  {
    fwInstallation_throw("fwInstallationDBAgent_checkProjectPvssInfo() -> Could not retrieve PVSS info from DB for host: " + hostname);
    return -1;
  }//end of if

  //Check that everything is ok:  
  isOk = false;
  for(int i = 1; i <= dynlen(dbHostPvssInfo); i++)
  {
    if(dynlen(dbHostPvssInfo[i]) >= 2 ) 
    {
      if(dbHostPvssInfo[i][FW_INSTALLATION_DB_PVSS_INFO_VERSION_IDX] == pvssPvssInfo[FW_INSTALLATION_DB_PVSS_INFO_VERSION_IDX] 
       && dbHostPvssInfo[i][FW_INSTALLATION_DB_PVSS_INFO_OS_IDX] == pvssPvssInfo[FW_INSTALLATION_DB_PVSS_INFO_OS_IDX] ) 
      {
        dbPvssInfo[FW_INSTALLATION_DB_PVSS_INFO_VERSION_IDX]= dbHostPvssInfo[i][FW_INSTALLATION_DB_PVSS_INFO_VERSION_IDX];
        dbPvssInfo[FW_INSTALLATION_DB_PVSS_INFO_OS_IDX]= dbHostPvssInfo[i][FW_INSTALLATION_DB_PVSS_INFO_OS_IDX];
        isOk = true;
        break;
      }
    }
  }
  return 0;  
}
*/

int fwInstallationDBAgent_checkProjectPvssInfo(bool &isOk, dyn_mixed &dbPvssInfo, dyn_mixed &pvssPvssInfo)
{
  
  string project = PROJ;  
  string hostname = fwInstallation_getHostname();    
  
  hostname = strtoupper(hostname);
  
  pvssPvssInfo[FW_INSTALLATION_DB_PVSS_INFO_VERSION_IDX] = VERSION_DISP;
  
  if(_WIN32)
    pvssPvssInfo[FW_INSTALLATION_DB_PVSS_INFO_OS_IDX] = "WINDOWS";
  else
    pvssPvssInfo[FW_INSTALLATION_DB_PVSS_INFO_OS_IDX] = "LINUX";
    
  if(fwInstallationDB_getProjectPvssInfo(project, hostname, dbPvssInfo) != 0) {
    fwInstallation_throw("fwInstallationDBAgent_checkProjectPvssInfo() -> Could not retrieve PVSS info from DB for project: " + project);
    return -1;
  }//end of if


  //Check that everything is ok:  
  if(dbPvssInfo == pvssPvssInfo)
    isOk = true;
  else
  {
    isOk = false;
    return 0;
  }
    
  return 0;  
}


/** This function checks the consistency of the PVSS version information
  @param isOk TRUE if DB and local project information is in sync
  @param dbPvssVersions PVSS information in the system configuration DB as a dyn_string array
  @param pvssPvssVersions PVSS information from the local host
  @return 0 if OK, -1 if errors
*/
int fwInstallationDBAgent_checkHostPvssInfo(bool &isOk, dyn_string &dbPvssVersions, dyn_string &pvssPvssVersions)
{
  string project = PROJ;  
  dyn_dyn_mixed dbPvssInfo;
  string hostname = strtoupper(fwInstallation_getHostname());    

  pvssPvssVersions = fwInstallation_getHostPvssVersions();
  for(int i = 1; i <= dynlen(pvssPvssVersions); i++)
    if(pvssPvssVersions[i] == VERSION)
      pvssPvssVersions[i] = VERSION_DISP;

  fwInstallationDB_getHostPvssVersions(dbPvssInfo);
  
  for(int i = 1; i <= dynlen(dbPvssInfo); i++)
    dynAppend(dbPvssVersions, dbPvssInfo[i][1]);

  dynSortAsc(pvssPvssVersions);  
  dynSortAsc(dbPvssVersions);  
  
  isOk = false;
  if(pvssPvssVersions == dbPvssVersions)
    isOk = true;
  
  return 0;  
}


/** This function updates the contents of the System Configuration DB for the PVSS setup information
  @return 0 if OK, -1 if errors
*/
/*
int fwInstallationDBAgent_synchronizePvssSetupInfo()
{
  bool patchesOk, pvssOk;
  dyn_string pvssPatches, dbPatches;
  dyn_mixed dbPvssInfo, pvssPvssInfo;

  if(fwInstallationDBAgent_checkProjectPvssInfo(pvssOk, dbPvssInfo, pvssPvssInfo) != 0)
  {
    fwInstallation_throw("fwInstallationDBAgent_synchronizePvssInfo() -> Failed to compare the host PVSS versions.");
    return -1;
  } 

  if(!pvssOk)
  {
	   //gCacheRequiresUpgrade = true;
    fwInstallationDBCache_clear();


    if(fwInstallationDB_unregisterAllHostPvssVersions() != 0)
    {
      fwInstallation_throw("fwInstallationDBAgent_synchronizePvssInfo() -> Failed to remove the previous PVSS versions from the DB.");
      return -1;
    }
    
    if(fwInstallationDB_registerProjectPvssVersion() != 0)
    {
      fwInstallation_throw("fwInstallationDBAgent_synchronizePvssInfo() -> Failed to update the host PVSS versions in the DB.");
      return -1;
    }
  }
  
  if(fwInstallationDBAgent_checkProjectPvssPatchesInfo(patchesOk, dbPatches, pvssPatches) != 0)
  {
    fwInstallation_throw("fwInstallationDBAgent_synchronizePvssInfo() -> Could not retrieve list of PVSS patches from PVSS and DB.");
    return -1;
  } 

  if(!patchesOk)
  {
    //gCacheRequiresUpgrade = true;
    fwInstallationDBCache_clear();
    if(fwInstallationDB_registerPvssSetup() != 0)
    {
      fwInstallation_throw("fwInstallationDBAgent_synchronizePvssInfo() -> Failed to update PVSS setup info in DB.");
      return -1;
    }
  }
  

  return 0;  
  
}
*/

int fwInstallationDBAgent_synchronizePvssSetupInfo()
{
  bool pvssOk, patchesOk;
  dyn_mixed dbPvssInfo, pvssPvssInfo;
  dyn_string pvssPatches, dbPatches;
    
  if(fwInstallationDBAgent_checkProjectPvssInfo(pvssOk, dbPvssInfo, pvssPvssInfo) != 0)
  {
    fwInstallation_throw("fwInstallationDBAgent_synchronizePvssInfo() -> Could not retrieve PVSS info from PVSS and DB.");
    return -1;
  } 
  
  if(fwInstallationDBAgent_checkProjectPvssPatchesInfo(patchesOk, dbPatches, pvssPatches) != 0)
  {
    fwInstallation_throw("fwInstallationDBAgent_synchronizePvssInfo() -> Could not retrieve list of PVSS patches from PVSS and DB.");
    return -1;
  } 

  if(!pvssOk || !patchesOk)
  {
    if(fwInstallationDB_registerPvssSetup() != 0)
    {
      fwInstallation_throw("fwInstallationDBAgent_synchronizePvssInfo() -> Failed to update PVSS setup info in DB.");
      return -1;
    }
  }
  

  return 0;  
  
}
/** This function checks the consistency between the current project and the contents of the 
    System Configuration DB for the PVSS patches information
  @param isOk TRUE if DB and local project information is in sync for patches
  @param dbPatches PVSS information in the system configuration DB as a dyn_mixed array
  @param pvssPatches PVSS information from the local project
  @return 0 if OK, -1 if errors
*/
int fwInstallationDBAgent_checkProjectPvssPatchesInfo(bool &isOk, dyn_string &dbPatches, dyn_string &pvssPatches)
{
  
  string hostname = fwInstallation_getHostname();    
  
  string os;
  string version = VERSION_DISP;
  
  hostname = strtoupper(hostname);
  
  if(_WIN32)
    os = "WINDOWS";
  else
    os = "LINUX";

  fwInstallationDB_getPatchList(hostname, version, os, dbPatches);
  fwInstallation_getPvssVersion(pvssPatches);

  //Check that everything is ok:  
  dynSortAsc(dbPatches);
  dynSortAsc(pvssPatches);
  if(dbPatches == pvssPatches)
    isOk = true;
  else
    isOk = false;
  
  return 0;  
}

/** This function checks the consistency between the current project and the contents of the 
    System Configuration DB for the host information
  @param isOk TRUE if DB and local project information is in sync for patches
  @param dbHostInfo PVSS information in the system configuration DB as a dyn_mixed array
  @param pvssHostInfo PVSS information from the local project
  @return 0 if OK, -1 if errors
*/
int fwInstallationDBAgent_checkHostInfo(bool &isOk, dyn_mixed &dbHostInfo, dyn_mixed &pvssHostInfo)
{
  string hostname = strtoupper(fwInstallation_getHostname());    

  if(fwInstallationDB_getHostProperties(hostname, dbHostInfo) != 0){
      fwInstallation_throw("fwInstallationDBAgent_checkHostInfo() -> Could not list of properties of host: " + hostname + " from DB.");
      return -1;
    }
  fwInstallation_getHostProperties(hostname, pvssHostInfo);  

  //For consistency we only require the hostname and primary ip number to be the same.
  if(dynlen(dbHostInfo) >= 2 && 
     dbHostInfo[FW_INSTALLATION_DB_HOST_NAME_IDX] == pvssHostInfo[FW_INSTALLATION_DB_HOST_NAME_IDX] && 
     dbHostInfo[FW_INSTALLATION_DB_HOST_IP_1_IDX] == pvssHostInfo[FW_INSTALLATION_DB_HOST_IP_1_IDX]) 
    isOk = true;
  else
    isOk = false;

  return 0;  
}


int fwInstallation_synchronizeHostPvssVersions()
{
  dyn_string pvssPvssVersions = fwInstallation_getHostPvssVersions();
  dyn_dyn_mixed dbPvssVersionsInfo;
  fwInstallationDB_getHostPvssVersions(dbPvssVersionsInfo);
  
  //Remove from the DB versions that are not installed any longer:
  for(int i = 1; i <= dynlen(dbPvssVersionsInfo); i++)
  {
    bool found = false;
    for(int j = 1; j <= dynlen(pvssPvssVersions); j++)
    {
      if(patternMatch(pvssPvssVersions[j] + "*", dbPvssVersionsInfo[i][1]) > 0)
      {
        found = true;
        break;
      }
    }
    if(!found)
    {
      string host = strtoupper(fwInstallation_getHostname());
      fwInstallation_throw("PVSS version: " + dbPvssVersionsInfo[i][1] + " no longer installed in host: " + host + ". Unregistering it from the DB now...", "INFO", 10);
      if(fwInstallationDB_unregisterHostPvssVersion(host, dbPvssVersionsInfo[i][1], dbPvssVersionsInfo[i][2]))
      {
        fwInstallation_throw("fwInstallationDBAgent_synchronizePvssInfo() -> Failed to unregister old PVSS versions from the DB: " + oldVersionsInfo);
      }
    }
  }

  return 0;
}  


/** This function updates the contents of the System Configuration DB for the host information
  @return 0 if OK, -1 if errors
*/
int fwInstallationDBAgent_synchronizeHostInfo()
{
  bool isOk;
  dyn_mixed dbHostInfo, pvssHostInfo;
  
  //syncrhonize host pvss versions:
  if(fwInstallation_synchronizeHostPvssVersions())
  {
    fwInstallation_throw("fwInstallationDBAgent_synchronizeHostInfo() -> Failed to synchronize the host PVSS versions");
    return -1;
  }
  
  if(fwInstallationDBAgent_checkHostInfo(isOk, dbHostInfo, pvssHostInfo) != 0)
  {
    fwInstallation_throw("fwInstallationDBAgent_synchronizeHostInfo() -> Could not retrieve host info from PVSS and DB.");
    return -1;
  } 
  
  if(isOk){
    return 0;
  }
  //gCacheRequiresUpgrade = true;
  fwInstallationDBCache_clear();

  if(fwInstallationDB_setHostProperties(strtoupper(fwInstallation_getHostname()), pvssHostInfo) != 0)
  {
    fwInstallation_throw("fwInstallationDBAgent_synchronizePvssInfo() -> Failed to update host info in DB.");
    return -1;
  }

  return 0;  
  
}

/** This function checks the consistency between the current project and the contents of the 
    System Configuration DB for the project information
  @param isOk TRUE if DB and local project information is in sync for patches
  @param dbProjectInfo PVSS information in the system configuration DB as a dyn_mixed array
  @param pvssProjectInfo PVSS information from the local project
  @return 0 if OK, -1 if errors
*/
int fwInstallationDBAgent_checkProjectInfo(bool &isOk, dyn_mixed &dbProjectInfo, dyn_mixed &pvssProjectInfo)
{
  string hostname = strtoupper(fwInstallation_getHostname());    
  string project = PROJ;
  int projectId;
  
  if(fwInstallationDB_getProjectProperties(project, hostname, dbProjectInfo, projectId) != 0){
    fwInstallation_throw("fwInstallationDBAgent_checkProjectInfo() -> Could not retrieve of properties of project: " + project + " from DB.");
    return -1;
  }//end of if
  
  if(fwInstallation_getProjectProperties(pvssProjectInfo) != 0)
  {
    fwInstallation_throw("fwInstallationDBAgent_checkProjectInfo() -> Could not retrieve of properties of project: " + project + " from PVSS.");
    return -1;
  }
  
  if(projectId >0 ) //if project already registered in DB, compare values
  {    
    
    int dbPmon = dbProjectInfo[FW_INSTALLATION_DB_PROJECT_PMON_PORT];
    int dbData = dbProjectInfo[FW_INSTALLATION_DB_PROJECT_DATA];
    int dbDist= dbProjectInfo[FW_INSTALLATION_DB_PROJECT_DIST];
    int dbEvent= dbProjectInfo[FW_INSTALLATION_DB_PROJECT_EVENT];    
    int dbRedu= dbProjectInfo[FW_INSTALLATION_DB_PROJECT_REDU_PORT];    
    int dbSplit= dbProjectInfo[FW_INSTALLATION_DB_PROJECT_SPLIT_PORT];        
    int instToolStatus = dbProjectInfo[FW_INSTALLATION_DB_PROJECT_TOOL_STATUS];
    
    if(dynlen(dbProjectInfo) && dbProjectInfo[FW_INSTALLATION_DB_PROJECT_NAME] == pvssProjectInfo[FW_INSTALLATION_DB_PROJECT_NAME] &&
       dbProjectInfo[FW_INSTALLATION_DB_PROJECT_HOST] == pvssProjectInfo[FW_INSTALLATION_DB_PROJECT_HOST] &&
       dbProjectInfo[FW_INSTALLATION_DB_PROJECT_DIR] == pvssProjectInfo[FW_INSTALLATION_DB_PROJECT_DIR] &&
       dbProjectInfo[FW_INSTALLATION_DB_PROJECT_SYSTEM_NAME] == pvssProjectInfo[FW_INSTALLATION_DB_PROJECT_SYSTEM_NAME] &&
       dbProjectInfo[FW_INSTALLATION_DB_PROJECT_SYSTEM_NUMBER] == pvssProjectInfo[FW_INSTALLATION_DB_PROJECT_SYSTEM_NUMBER] &&
       dbPmon == pmonPort() &&
       dbData == pvssProjectInfo[FW_INSTALLATION_DB_PROJECT_DATA] &&
       dbEvent == pvssProjectInfo[FW_INSTALLATION_DB_PROJECT_EVENT] &&
       dbDist == pvssProjectInfo[FW_INSTALLATION_DB_PROJECT_DIST] &&
       dbRedu == pvssProjectInfo[FW_INSTALLATION_DB_PROJECT_REDU_PORT] &&
       dbSplit == pvssProjectInfo[FW_INSTALLATION_DB_PROJECT_SPLIT_PORT] &&
       dbProjectInfo[FW_INSTALLATION_DB_PROJECT_TOOL_VER] == pvssProjectInfo[FW_INSTALLATION_DB_PROJECT_TOOL_VER] &&
       instToolStatus == pvssProjectInfo[FW_INSTALLATION_DB_PROJECT_TOOL_STATUS] &&
       dbProjectInfo[FW_INSTALLATION_DB_PROJECT_PVSS_VER] == pvssProjectInfo[FW_INSTALLATION_DB_PROJECT_PVSS_VER] &&
       dbProjectInfo[FW_INSTALLATION_DB_PROJECT_OS] == pvssProjectInfo[FW_INSTALLATION_DB_PROJECT_OS])
    {
      isOk = true;

    }
    else
    {
      isOk = false;  
    }
  }else{
    isOk = false;  

  }
  
  dyn_mixed dbSystem;
  dyn_mixed pvssSystem;

  if(isOk)//project info ok, check now system info.
  {
    if(fwInstallationDB_getPvssSystemProperties(pvssProjectInfo[FW_INSTALLATION_DB_PROJECT_SYSTEM_NAME], dbSystem) != 0){
      fwInstallation_throw("fwInstallationDBAgent_checkProjectInfo() -> Could not retrieve of properties of the system: " + pvssProjectInfo[FW_INSTALLATION_DB_PROJECT_SYSTEM_NAME] + " from DB.");
      return -1;
    }
    
    if(fwInstallation_getPvssSystemProperties(pvssProjectInfo[FW_INSTALLATION_DB_PROJECT_SYSTEM_NAME], pvssSystem) != 0)
    {
      fwInstallation_throw("fwInstallationDBAgent_checkProjectInfo() -> Could not list of properties of project: " + project + " from PVSS.");
      return -1;
    }
    if(dynlen(dbSystem) && 
       dbSystem[FW_INSTALLATION_DB_SYSTEM_NUMBER] == pvssSystem[FW_INSTALLATION_DB_SYSTEM_NUMBER] &&
       dbSystem[FW_INSTALLATION_DB_SYSTEM_DATA_PORT] == pvssSystem[FW_INSTALLATION_DB_SYSTEM_DATA_PORT] &&
       dbSystem[FW_INSTALLATION_DB_SYSTEM_EVENT_PORT] == pvssSystem[FW_INSTALLATION_DB_SYSTEM_EVENT_PORT] &&
       dbSystem[FW_INSTALLATION_DB_SYSTEM_DIST_PORT] == pvssSystem[FW_INSTALLATION_DB_SYSTEM_DIST_PORT] &&
       dbSystem[FW_INSTALLATION_DB_SYSTEM_REDU_PORT] == pvssSystem[FW_INSTALLATION_DB_SYSTEM_REDU_PORT] &&
       dbSystem[FW_INSTALLATION_DB_SYSTEM_SPLIT_PORT] == pvssSystem[FW_INSTALLATION_DB_SYSTEM_SPLIT_PORT] &&       
       dbSystem[FW_INSTALLATION_DB_SYSTEM_COMPUTER] == pvssSystem[FW_INSTALLATION_DB_SYSTEM_COMPUTER])
    {
      isOk = true;
    }
    else
    {
      isOk = false;  
    }
  }

  return 0;  
}

/** This function updates the contents of the System Configuration DB for the project information
  @return 0 if OK, -1 if errorsfwInstallationDB_registerSystem
*/
int fwInstallationDBAgent_synchronizeProjectInfo()
{
  bool isOk;
  dyn_mixed dbProjectInfo;
  dyn_mixed pvssProjectInfo;
  
  if(fwInstallationDBAgent_checkProjectInfo(isOk, dbProjectInfo, pvssProjectInfo) != 0)
  {
    fwInstallation_throw("fwInstallationDBAgent_synchronizeProjectInfo() -> Could not retrieve project info from PVSS and DB.");
    return -1;
  } 
  
  if(isOk){
    return 0;
  }

  //gCacheRequiresUpgrade = true;
  fwInstallationDBCache_clear();

  if(dynlen(dbProjectInfo) >= FW_INSTALLATION_DB_PROJECT_CENTRALLY_MANAGED)
  {
    int centrally = dbProjectInfo[FW_INSTALLATION_DB_PROJECT_CENTRALLY_MANAGED];
    if(centrally)
      pvssProjectInfo[FW_INSTALLATION_DB_PROJECT_REDU_HOST] = dbProjectInfo[FW_INSTALLATION_DB_PROJECT_REDU_HOST];
  }

  if(fwInstallationDB_setProjectProperties(PROJ, strtoupper(fwInstallation_getHostname()), pvssProjectInfo) != 0)
  {
    fwInstallation_throw("fwInstallationDBAgent_synchronizeProjectInfo() -> Failed to update project info in DB.");
    return -1;
  }
  
  return 0;  
}


/** This function checks the consistency between the current project and the contents of the 
    System Configuration DB for the project paths
  @param isOk TRUE if DB and local project information is in sync for patches
  @param dbPaths PVSS information in the system configuration DB as a dyn_mixed array
  @param pvssPaths PVSS information from the local project
  @return 0 if OK, -1 if errors
*/
int fwInstallationDBAgent_checkProjectPathsInfo(bool &isOk, 
                                                  dyn_string &dbPaths, 
                                                  dyn_string &pvssPaths)
{
  string hostname = strtoupper(fwInstallation_getHostname());    
  string project = PROJ;
  dyn_string commonPaths;
  
  hostname = strtoupper(hostname);
  dynClear(commonPaths);  
  
  if(fwInstallationDB_getProjectPaths(project, hostname, dbPaths) != 0){
    fwInstallation_throw("fwInstallationDBAgent_checkProjectInfo() -> Could not list of paths of project: " + project + " from DB.");
    return -1;
  }//end of if
  
  
  //Rest of the proj_paths:
  fwInstallation_loadProjPaths(pvssPaths);
  
  //Check that everything is ok:  
  if(dynlen(pvssPaths) != dynlen(dbPaths))
  {
//DebugN("Different list of project paths, ", pvssPaths, dbPaths);
    isOk = false;
    return 0;
  }
  else
  {
    for(int i = 1; i <= dynlen(pvssPaths); i++)
    {
//DebugN("Path " + i + " differs? " + pvssPaths[i] + "!=" + dbPaths[i], pvssPaths[i] != dbPaths[i]);
      if(pvssPaths[i] != dbPaths[i])
      {
        isOk = false;
        return 0;
      }
    }
  }
  
  isOk = true;

  return 0;  
}

/** This function synchronizes the list of project paths in the current project and in the
    System Configuration. The synchronization depends on the management mode of the project:
    
    - if the project is locally managed, the contents of the system confiuguration db 
      are updated with the list of project paths currently defined in the project.
      
      
    - if the project is centrally managed, the DB-Agent of the installation tool modifies
      the list of project paths defined in the local project to reflect the contents of the system configuration DB.
      
  @return 0 if OK, -1 if errors
*/
int fwInstallationDBAgent_synchronizeProjectPaths()
{
  bool isOk;
  dyn_mixed dbPaths;
  dyn_mixed pvssPaths;
  bool isCentrallyManaged = fwInstallationDB_getCentrallyManaged();

  if(fwInstallationDBAgent_checkProjectPathsInfo(isOk, dbPaths, pvssPaths) != 0)
  {
    fwInstallation_throw("fwInstallationDBAgent_synchronizeProjectPaths() -> Could not retrieve project info from PVSS and DB.");
    return -1;
  } 
//DebugN("sync paths: isOk, dbPaths, pvssPaths", isOk, dbPaths, pvssPaths);
  
  if(isOk){
    return 0;
  }

	//gCacheRequiresUpgrade = true;
  fwInstallationDBCache_clear();
  
  if(isCentrallyManaged)
  {
    dynRemove(pvssPaths, dynlen(pvssPaths));
    int err = fwInstallation_deleteProjectPaths(pvssPaths);
    err = fwInstallation_addProjectPaths(dbPaths); 
  }//end of centrally managed
  else
  {
    if(fwInstallationDB_registerProjectPaths() != 0)
    {
      fwInstallation_throw("fwInstallationDBAgent_synchronizeProjectPaths() -> Failed to update project paths in DB.");
      return -1;
    }
  }


  return 0;  
  
}


/** This function checks the consistency between the list of project managers 
  in the current project and those registered in the System Configuration DB
  @param isOk overall result of the consistency check
  @param dbManagersInfo managers information from the database
  @param pvssManagersInfo managers information from the local project
  
  @return 0 if OK, -1 if errors
*/
int fwInstallationDBAgent_checkProjectManagersInfo(bool &isOk, 
                                                   dyn_dyn_mixed &dbManagersInfo, 
                                                   dyn_dyn_string &pvssManagersInfo)
{
  string hostname = strtoupper(fwInstallation_getHostname());    
  string project = PROJ;
  int count = 0;
  
  if(fwInstallationDB_getProjectManagers(dbManagersInfo, project, hostname) != 0){
    fwInstallation_throw("fwInstallationDBAgent_checkProjectInfo() -> Could not list of managers of project: " + project + " from DB.");
    return -1;
  }//end of if

  fwInstallationManager_getAllInfoFromPvss(pvssManagersInfo);

  //Check consistency:
  if(dynlen(dbManagersInfo) != dynlen(pvssManagersInfo))
  {
    isOk = false;
    return 0;
  }
  
  for(int i =1 ; i <= dynlen(dbManagersInfo); i++)
  {
    //Find pvss component that matches dbComponent
    for(int j = 1; j <= dynlen(pvssManagersInfo); j++){
      if(pvssManagersInfo[j][FW_INSTALLATION_DB_MANAGER_NAME_IDX] == dbManagersInfo[i][FW_INSTALLATION_DB_MANAGER_NAME_IDX] &&
         dbManagersInfo[i][FW_INSTALLATION_DB_MANAGER_OPTIONS_IDX] == pvssManagersInfo[j][FW_INSTALLATION_DB_MANAGER_OPTIONS_IDX] &&
         dbManagersInfo[i][FW_INSTALLATION_DB_MANAGER_RESETMIN_IDX] == pvssManagersInfo[j][FW_INSTALLATION_DB_MANAGER_RESETMIN_IDX] &&
         dbManagersInfo[i][FW_INSTALLATION_DB_MANAGER_RESTART_IDX] == pvssManagersInfo[j][FW_INSTALLATION_DB_MANAGER_RESTART_IDX] &&
         dbManagersInfo[i][FW_INSTALLATION_DB_MANAGER_SECKILL_IDX] == pvssManagersInfo[j][FW_INSTALLATION_DB_MANAGER_SECKILL_IDX] &&
         dbManagersInfo[i][FW_INSTALLATION_DB_MANAGER_START_IDX] == pvssManagersInfo[j][FW_INSTALLATION_DB_MANAGER_START_IDX])
      {
        //We have indentified one manager. Comparing rest of the settings:
        if(dbManagersInfo[i][FW_INSTALLATION_DB_MANAGER_START_IDX] == pvssManagersInfo[j][FW_INSTALLATION_DB_MANAGER_START_IDX] &&
           dbManagersInfo[i][FW_INSTALLATION_DB_MANAGER_TRIGGERS_ALERTS_IDX] == pvssManagersInfo[j][FW_INSTALLATION_DB_MANAGER_TRIGGERS_ALERTS_IDX])
        {
          ++count;
          continue;
        }
      }//end of if
    }//end of loop over j    
  }  
  
  if(count == dynlen(dbManagersInfo))
    isOk = true;
  else
    isOk = false;

  return 0;  
}


/** This function updates the contents of the System Configuration DB for the project managers
  @return 0 if OK, -1 if errors
*/int fwInstallationDBAgent_synchronizeProjectManagers()
{
  bool isOk;
  dyn_mixed dbManagersInfo;
  dyn_mixed pvssManagersInfo;
  //bool isCentrallyManaged;
  bool found = false;
  
  if(fwInstallationDBAgent_checkProjectManagersInfo(isOk, dbManagersInfo, pvssManagersInfo) != 0)
  {
    fwInstallation_throw("fwInstallationDBAgent_synchronizeProjectManagers() -> Could not retrieve project info from PVSS and DB.");
    return -1;
  } 
  
  if(isOk){
    return 0;
  }

  
	 //gCacheRequiresUpgrade = true;
  fwInstallationDBCache_clear();
  
  if(fwInstallationDB_deleteProjectManagers())  
  {
    fwInstallation_throw("fwInstallationDBAgent_synchronizeProjectManagers() -> Failed to remove from the DB the old list of project managers");
    return -1;
  }
 
 //Add managers that are not registered
  if(fwInstallationDB_registerProjectManagers() != 0)
  {
    fwInstallation_throw("fwInstallationDBAgent_synchronizeProjectManagers() -> Failed to update project paths in DB.");
    return -1;
  }
  return 0;  
  
}

/** This function checks the consistency between the list of components 
  currently installed in the local project and those registered in the System Configuration DB
  @param isOk overall result of the consistency check
  @param dbComponentsInfo components information in the DB
  @param pvssComponentsInfo components information from the local project
  @return 0 if OK, -1 if errors
*/
int fwInstallationDBAgent_checkComponents(bool &isOk, 
                                          dyn_dyn_mixed &dbComponentsInfo, 
                                          dyn_dyn_mixed &pvssComponentsInfo)
{
  int count = 0;      
  
  isOk = false;
  
  fwInstallation_getInstalledComponents(pvssComponentsInfo);
    
  if(fwInstallationDB_getProjectComponents(dbComponentsInfo) != 0){
    fwInstallation_throw(" fwInstallationDBAgent_checkComponents() -> Could not retrieve the list of project FW components from DB."); 
    return -1;
  }
  
  if(dynlen(pvssComponentsInfo) != dynlen(dbComponentsInfo))
    return 0; 
    
  for(int i = dynlen(dbComponentsInfo); i > 0; i--) 
  {
    for(int j = dynlen(pvssComponentsInfo); j > 0; j--) 
    {
      if(dbComponentsInfo[i][FW_INSTALLATION_DB_COMPONENT_NAME_IDX] == pvssComponentsInfo[j][FW_INSTALLATION_DB_COMPONENT_NAME_IDX] &&
         dbComponentsInfo[i][FW_INSTALLATION_DB_COMPONENT_VERSION_IDX] == pvssComponentsInfo[j][FW_INSTALLATION_DB_COMPONENT_VERSION_IDX])
      {
        ++count;
      } 
    }
  }
  
  if(count != dynlen(pvssComponentsInfo))
    return 0;
  
  isOk = true;
  
  return 0;
  
}

/** This function cast a dyn_mixed to an string where the different elements are separated by "|";
  @param request dyn_mixed to be casted
  @return result of the casting operation as string
*/
string fwInstallationDBAgent_stringCastRequest(dyn_mixed request)
{
  string strRequest;
  
  for(int i =1; i <= dynlen(request); i++)
    strRequest += request[i] + "|";
  
  return strRequest;
}

/** This function synchronizes the list of components in the current project and in the
    System Configuration and exports the current list of components installed in the project to the DB.
    The synchronization depends on the management mode of the project:
    
    - if the project is locally managed, no synchronization is done. 
      Only the current list of components in the System Configuration DB 
      is updated with the list of components in the local project.
      
      
    - if the project is centrally managed, the DB-Agent of the installation tool uninstalls 
      and/or uninstalls all components such that the list of components installed in the project
      reflects the contents of the system configuration DB.
      
  @param restartProject flag indicating if project restart is required. Possible values are:
  
    0: project restart is not required
    
    1: project restart required
       
    2: project restart not required but post-installation scripts must be run  
       
  @return 0 if OK, -1 if errors
*/
int fwInstallationDBAgent_synchronizeProjectComponents(int &restartProject)
{
  dyn_dyn_mixed pvssInstallComponents, pvssDeleteComponents;
  bool isRunning = false;
  int error;
  int centrallyManaged = fwInstallationDB_getCentrallyManaged();
  int reinstalls = 0;
  
  if(fwInstallationDB_maxLogSizeExceeded()){fwInstallationDB_deleteInstallationLog();}
  //export current configuration of the project:
  fwInstallationDB_registerProjectFwComponents();
  
  if(!centrallyManaged)  //Nothing to be done at the component level
  {
    restartProject = 0;
    return 0;
  }
  error = fwInstallationDBAgent_getComponentPendingActions(restartProject, pvssInstallComponents, pvssDeleteComponents, reinstalls);
  return fwInstallationDBAgent_executeComponentPendingActions(restartProject, pvssInstallComponents, pvssDeleteComponents);

}

/** This function checks if the post-installation scripts are still running
  @param isRunning TRUE if post-install scripts are still being executed
  @return 0 if OK, -1 if errors
*/
int fwInstallationDBAgent_isPostInstallRunning(bool &isRunning) 
{
  string commandLine = "-f fwScripts.lst";
  string manager = fwInstallation_getWCCOAExecutable("ctrl");
 
  return fwInstallationManager_isRunning(manager, commandLine, isRunning);
}

/** This function returns the path to a description file where any Windows-Linux 
    path mapping is resolved, e.g. from /afs/cern.ch/myComponent.xml -> P:/myComponent.xml
  @param descFile original description file of the component including path
  @return new path to the component description file where possible path mappings have been resolved
*/
string fwInstallationDBAgent_getComponentFile(string descFile)
{

  string fileName = "";
  dyn_string ds;
  string pattern;
  string mappedPath;
  string sourceDir;  
  
  //Check that the description file can be accessed:
  if(access(descFile, R_OK) != 0)
  {
    //the original file is not accessible. 
    //Could it be a problem of the groups being 
    //defined with windows paths and being used 
    //in Linux or the other way around? If so, 
    //let us see if we can resolve the path mapping 
    //from the DB   
    
    if(!fwInstallationDB_getUseDB())  
    {
      //configure not to use the DB.
      return "";
    }

    //Original path is Windows or Linux?
    if(patternMatch("*:*", descFile) ||
       patternMatch("*\\*", descFile)) //Windows
    {
      ds = strsplit(descFile, "\\");
      int len = (dynlen(ds)-1);
      fileName = ds[dynlen(ds)];

      
      if(fwInstallationDB_getMappedPath(strtoupper(substr(descFile, 0, 1)) + ":", mappedPath) <0)
      {
        fwInstallation_throw("fwInstallationDBAgent_getComponentFile() -> Cannot resolve path mapping for description file: " + descFile);            
        return "";
      }
      else
      {
        strreplace(descFile, strtoupper(substr(descFile, 0, 1)) + ":", mappedPath);
        strreplace(sourceDir, strtoupper(substr(descFile, 0, 1)) + ":", mappedPath);
      }
    }
    else //Linux path
    {
      //needs to do some gymnastics: Check recursively from the longest possible path to the minimum one.
      ds = strsplit(descFile, "/");
      int len = dynlen(ds)-1;
      fileName = ds[dynlen(ds)]; 
      for(int i = 1; i <= (dynlen(ds)-1) ; i++)
      {
        pattern = "";
        for(int k = 1; k <= len ; k++)
        {
          if(ds[k] == "")
            continue;
                  
          pattern += "/" + ds[k];
        }
        --len;
            
        if(fwInstallationDB_getMappedPath(pattern, mappedPath) < 0)
        {
          fwInstallation_throw("fwInstallationDBAgent_getComponentFile() -> Cannot resolve path mapping for description file: " + descFile);            
          return "";
        }
            
        if(mappedPath != "")
          break;
                        
      }
      
      if(!patternMatch("*:", mappedPath))
        mappedPath += ":";
          
      strreplace(descFile, pattern, mappedPath);
      strreplace(sourceDir, pattern, mappedPath);
    }
  }

  return descFile;
}

/** This function executes all pending installation/uninstallatio of components
  @param restartProject (in/out) flag indicating if project restart is required. Possible values are:
  
    0: project restart is not required
    
    1: project restart required
       
    2: project restart not required but post-installation scripts must be run
  @param pvssInstallComponents (in) list of components to be installed in the project
  @param pvssDeleteComponents (in) list of components to be delete from the project
  @return 0 if OK, -1 if errors
*/
int fwInstallationDBAgent_executeComponentPendingActions(int &restartProject, 
                                                         dyn_dyn_mixed pvssInstallComponents, 
                                                         dyn_dyn_mixed pvssDeleteComponents) 
{
  int error;
  dyn_float df;
  dyn_string ds;
  int status;
  string component;
  string pattern;
  string mappedPath;
  string fileName;
  string descFile;
  string sourceDir;
  dyn_string dontRestartProjects;
  int xmlRestart = 0;
  dyn_mixed projectInfo;
  
  dyn_string allComponents, allVersions, allFiles, orderedFiles;

  if(dynlen(pvssInstallComponents) > 0)
  {
	//gCacheRequiresUpgrade = true;
    fwInstallationDBCache_clear();
    //order components according to their dependencies:
    for(int i = 1; i <= dynlen(pvssInstallComponents); i++)
    {
      string str = fwInstallationDBAgent_getComponentFile(pvssInstallComponents[i][FW_INSTALLATION_DB_PVSS_INSTALL_DESCFILE_IDX]);
      
      dynAppend(allFiles, str);
      dynAppend(allComponents, pvssInstallComponents[i][FW_INSTALLATION_DB_PVSS_INSTALL_COMPONENT_IDX]);
      dynAppend(allVersions, pvssInstallComponents[i][FW_INSTALLATION_DB_PVSS_INSTALL_VERSION_IDX]);     
    }
    
    fwInstallation_putComponentsInOrder_Install(allComponents, allVersions, allFiles, orderedFiles);

    for(int f = 1; f <= dynlen(orderedFiles); f++)
    {    
      for(int i = 1; i <= dynlen(allFiles); i++)
      {
        if(allFiles[i] == orderedFiles[f])
        {
          sourceDir = allFiles[i];
          strreplace(sourceDir, "\\", "/");
          dyn_string dss = strsplit(sourceDir, "/");
          strreplace(sourceDir, dss[dynlen(dss)], "");
	  
          fwInstallation_installComponent(allFiles[i],
                                          sourceDir,
                                          pvssInstallComponents[i][FW_INSTALLATION_DB_PVSS_INSTALL_SUBCOMP_IDX],
                                          component,
                                          status,
                                          dontRestartProjects[i],
                                          pvssInstallComponents[i][FW_INSTALLATION_DB_PVSS_INSTALL_SUBPATH_IDX],
                                          pvssInstallComponents[i][FW_INSTALLATION_DB_PVSS_INSTALL_FORCE_REQUIRED_IDX],
                                          pvssInstallComponents[i][FW_INSTALLATION_DB_PVSS_INSTALL_OVERWRITE_FILES_IDX],
                                          pvssInstallComponents[i][FW_INSTALLATION_DB_PVSS_INSTALL_SILENT_IDX],
                                          false,
                                          false);
          
          dontRestartProjects[i] = strtolower(dontRestartProjects[i]);
      
          if(!status)
            ++error;
          
          break; //do not loop over the remaining allFiles.
          
        }//end of if
      }//end of loop over components.     
      
    }
  } //end of if dynlen(pvssInstallComponents)
  
  if(dynlen(pvssDeleteComponents) > 0)
  {
	//gCacheRequiresUpgrade = true;
    
    fwInstallationDBCache_clear();
    //read project properties to find out if files should be deleted:
    int projectId;
    string host = fwInstallation_getHostname();
    fwInstallationDB_getProjectProperties(PROJ, host, projectInfo, projectId);
    
    int deleteFiles = 0;    
    if(dynlen(projectInfo) >= FW_INSTALLATION_DB_PROJECT_DELETE_FILES)
      deleteFiles = projectInfo[FW_INSTALLATION_DB_PROJECT_DELETE_FILES];
    
    for(int i = 1; i <= dynlen(pvssDeleteComponents); i++)
    {    
      if(pvssDeleteComponents[i][FW_INSTALLATION_DB_PVSS_DELETE_NAME_IDX] != "")
      {
        fwInstallation_deleteComponent(pvssDeleteComponents[i][FW_INSTALLATION_DB_PVSS_DELETE_NAME_IDX], status, deleteFiles, false); //do not delete files, do not delete subcomponents.
        if(!status)
          ++error;
      }
    }
    
    if(dynlen(pvssInstallComponents) <= 0)
    {
      restartProject = 2;  //Run post-delete scripts without restarting the project.
    }
  }

  //Execute reinstallations:
  error += fwInstallationDBAgent_executeProjectPendingReinstallations(restartProject);

  if(error > 0)
  {
    if(myManType() == UI_MAN)
      ChildPanelOnCentralModal("vision/MessageInfo1", "Synchronization failed", makeDynString("$1:There were errors while synchronizing the list of\nFW Components in PVSS and DB."));
    else
      fwInstallation_throw("fwInstallationDBAgent_executeComponentPendingActions() -> There were errors while synchronizing the list of FW Components in PVSS and DB.");
  }
  
  if(restartProject == 1)// && !isRunning)
  {
    if(myManType() == UI_MAN)
      ChildPanelOnCentralModal("fwInstallation/fwInstallationRestart.pnl", "Project restart required", makeDynString(""));
    else
    {
      DebugTN("INFO: Forcing project restart now...");
      fwInstallation_forceProjectRestart();
    } 
  }
   
  if(error > 0)
    return -1;
  
  return 0;
}

/** This function retrieves the list of pending installation/uninstallatio of components
  @param restartProject (out) flag indicating if project restart is required. Possible values are:
  
    0: project restart is not required
    
    1: project restart required
       
    2: project restart not required but post-installation scripts must be run
  @param pvssInstallComponents (out) list of components to be installed in the project
  @param pvssDeleteComponents (out) list of components to be delete from the project
  @param reinstalls (out) if not 0 means that there are pending reinstallation actions
  @return 0 if OK, -1 if errors  
*/
int fwInstallationDBAgent_getComponentPendingActions(int &restartProject, 
                                                     dyn_dyn_mixed &pvssInstallComponents, 
                                                     dyn_dyn_mixed &pvssDeleteComponents, 
                                                     int &reinstalls)
{
  bool isOk;
  dyn_string dbGroups;
  dyn_int groupsIds;
  dyn_string pvssGroups;
  dyn_dyn_mixed dbTmp, pvssTmp;
  dyn_dyn_mixed dbComponentsInfo;
  dyn_dyn_mixed pvssComponentsInfo;
  dyn_dyn_mixed commonComponentsInfo;
  dyn_dyn_mixed installedPvssComponentsInfo;
  dyn_dyn_mixed installedDbComponentsInfo;
  dyn_string components, versions, subcomponents, descFiles;
  
  int d = 1;
  int p = 1;
  bool status = true;
  //int k = 1;
  
  bool isCentrallyManaged = fwInstallationDB_getCentrallyManaged();
  int error;
  
  string descFile, sourceDir, component, subPath;
  bool isInstalled, forceInstallRequired, forceOverwriteFiles, isSilent, isSubcomponent;
  dyn_string componentGroups;
  dyn_mixed projectGroupInfo;
  int ii = 1;
  int jj = 1;
  bool found;
     
  restartProject = 2; //assume no restart required but there are insatallations and we want to run the postinstall scritps
  
  dynClear(pvssInstallComponents);
  dynClear(pvssDeleteComponents);
 
  if(isCentrallyManaged)
  {
    ii = 1;
    //Get list of all components in pvss
    fwInstallation_getInstalledComponents(pvssComponentsInfo);
    fwInstallationDB_getProjectComponents(dbComponentsInfo);
    
    //Loop over the components of the group and check if installed in PVSS:
    for(int j = 1; j <= dynlen(dbComponentsInfo); j++)
    {
      found = false;
      for(int k = 1; k <= dynlen(pvssComponentsInfo); k++)
      {
        if(dbComponentsInfo[j][FW_INSTALLATION_DB_COMPONENT_NAME_IDX] == pvssComponentsInfo[k][FW_INSTALLATION_DB_COMPONENT_NAME_IDX] &&
           dbComponentsInfo[j][FW_INSTALLATION_DB_COMPONENT_VERSION_IDX] == pvssComponentsInfo[k][FW_INSTALLATION_DB_COMPONENT_VERSION_IDX])
        {
          found = true;
        }
        
        if(found)
          break;
      }
 
      if(!found){
        string temp = dbComponentsInfo[j][FW_INSTALLATION_DB_PROJ_COMP_DESCFILE_IDX];
         dyn_string ds = strsplit(temp, "/");
         string sourceDir = "";

         if(!_WIN32 && !patternMatch("/*", temp) && !patternMatch("*:*", temp)) 
           sourceDir = "/";  //Make sure the linux path starts with '/'. Could be that in the DB we have a Windows path
                  
         if(_WIN32 && !patternMatch("*:*", temp) && !patternMatch("\\\\*", temp)) //OS is windows but DB path is Linux
           sourceDir = "/";  //Make sure the linux path starts with '/'. 

         
         for(int g = 1; g < dynlen(ds); g++)
           if(ds[g] != "")
             sourceDir += ds[g]+ "/";
         
         pvssInstallComponents[ii][FW_INSTALLATION_DB_PVSS_INSTALL_COMPONENT_IDX]= dbComponentsInfo[j][FW_INSTALLATION_DB_PROJ_COMP_NAME_IDX];
         pvssInstallComponents[ii][FW_INSTALLATION_DB_PVSS_INSTALL_VERSION_IDX]= dbComponentsInfo[j][FW_INSTALLATION_DB_PROJ_COMP_VERSION_IDX];
         pvssInstallComponents[ii][FW_INSTALLATION_DB_PVSS_INSTALL_DESCFILE_IDX]= dbComponentsInfo[j][FW_INSTALLATION_DB_PROJ_COMP_DESCFILE_IDX];
         pvssInstallComponents[ii][FW_INSTALLATION_DB_PVSS_INSTALL_SOURCEDIR_IDX]= sourceDir;
         pvssInstallComponents[ii][FW_INSTALLATION_DB_PVSS_INSTALL_SUBPATH_IDX] = "";
         pvssInstallComponents[ii][FW_INSTALLATION_DB_PVSS_INSTALL_SUBCOMP_IDX] = dbComponentsInfo[j][FW_INSTALLATION_DB_PROJ_COMP_IS_SUBCOMP_IDX];
         pvssInstallComponents[ii][FW_INSTALLATION_DB_PVSS_INSTALL_FORCE_REQUIRED_IDX] = dbComponentsInfo[j][FW_INSTALLATION_DB_PROJ_COMP_FORCE_IDX];
         pvssInstallComponents[ii][FW_INSTALLATION_DB_PVSS_INSTALL_OVERWRITE_FILES_IDX] = dbComponentsInfo[j][FW_INSTALLATION_DB_PROJ_COMP_OVERWRITE_IDX];
         pvssInstallComponents[ii][FW_INSTALLATION_DB_PVSS_INSTALL_SILENT_IDX] = dbComponentsInfo[j][FW_INSTALLATION_DB_PROJ_COMP_IS_SILENT_IDX];

         if(dbComponentsInfo[j][FW_INSTALLATION_DB_PROJ_COMP_RESTART_PROJECT_IDX])
         {
           restartProject = 1;
         }
         ++ii;
      }
    }//end of loop over group components
  
    if(dynlen(pvssInstallComponents)<=0)
      restartProject = 0;
    
      
    //Loop over all pvss groups and see if there is any component to be removed:
    //ii = 1; //reset loop counter
    for(int i = 1; i <= dynlen(pvssComponentsInfo); i++){
      found = false;
      for(int j = 1; j <= dynlen(dbComponentsInfo); j++){
        if(pvssComponentsInfo[i][FW_INSTALLATION_DB_COMPONENT_NAME_IDX] == dbComponentsInfo[j][FW_INSTALLATION_DB_COMPONENT_NAME_IDX])
          found = true;
        
        if(found)
          break;
      }
      
      if(!found)
      {
        
        if(dynlen(pvssInstallComponents) <=0) //Avoid project restart but only if there are no components to be installed
        {  
          restartProject = 2;
        }
        
        pvssDeleteComponents[jj][FW_INSTALLATION_DB_PVSS_DELETE_NAME_IDX]= pvssComponentsInfo[i][FW_INSTALLATION_DB_COMPONENT_NAME_IDX];
        pvssDeleteComponents[jj][FW_INSTALLATION_DB_PVSS_DELETE_VERSION_IDX]= pvssComponentsInfo[i][FW_INSTALLATION_DB_COMPONENT_VERSION_IDX];
        
        ++jj;
      }
    }//end of loop over pvss groups
    
    //Check if there are reinstallations to be done:
    dyn_dyn_mixed resintallationsInfo;
    
    fwInstallationDB_getProjectPendingReinstallations(fwInstallation_getHostname(), PROJ, resintallationsInfo);
    
    if(dynlen(resintallationsInfo)>0)
      reinstalls = 1;
    else
      reinstalls = 0;
    
  }//end of if centrally managed.

  
  if(error)
    return -1;
  else
    return 0;
   
}

/** This function sets the synchronization method
  @param bool: either true (force full synchronize on the client) or false (use server flag)
  @return 0 if OK, -1 if errors  
*/
int fwInstallationDBAgent_setForceFullSync(bool forceFullSynchronization)
{
  //[TODO] create configuration?
  //return dpSet("fwInstallation_agentParametrization.forceFullSynchronization", forceFullSynchronization);
  return 0;
}

/** This function reads the synchronization method
  @return true if full synchronize is intended
          false for synchronize on server trigger only.
*/
bool fwInstallationDBAgent_getForceFullSync()
{
  bool forceSynchronization = false;
  
  //[TODO] create configuration?
  //if(dpExists("fwInstallation_agentParametrization.forceFullSynchronize"))
  //  dpGet("fwInstallation_agentParametrization.forceFullSynchronize", forceSynchronization);

  return forceSynchronization;
}

/** This function sets the synchronization interval
  @param interval time in seconds between two consecutive synchronizations
  @return 0 if OK, -1 if errors  
*/
int fwInstallationDBAgent_setSyncInterval(int interval)
{
  return dpSet("fwInstallation_agentParametrization.syncInterval", interval);
}

/** This function reads the synchronization interval
  @return time in seconds between two consecutive synchronizations
*/
int fwInstallationDBAgent_getSyncInterval()
{
  int interval = 0;
  
  if(dpExists("fwInstallation_agentParametrization.syncInterval"))
    dpGet("fwInstallation_agentParametrization.syncInterval", interval);

  if(interval == 0)
    interval = 30;
    
  return interval;
}

/** This function checks the consistency between the list of dist peers defined
    in the local project and in the System Configuration DB
  @param isOk overall result of the consistency check
  @param onlyPvssSystemNames PVSS system names correspoding to peers defined 
         only in the config file of the local project, i.e. missing in the DB
  @param onlyDbSystemNames PVSS system names correspoding to peers defined 
         only in the DB, i.e. missing in the config file of the local project
  @param onlyPvssComputerNames Hostnames correspoding to peers defined 
         only in the config file of the local project, i.e. missing in the DB
  @param onlyDbComputerNames Hostnames correspoding to peers defined 
         only in the DB, i.e. missing in the config file of the local project.
  @param onlyPvssSystemNumbers PVSS system numbers correspoding to peers defined 
         only in the config file of the local project, i.e. missing in the DB
  @param onlyDbSystemNumbers PVSS system numbers correspoding to peers defined 
         only in the DB, i.e. missing in the config file of the local project.
  @return 0 if OK, -1 if errors  
*/
int fwInstallationDBAgent_checkDistPeers(bool &isOk, 
                                         dyn_string &onlyPvssSystemNames, 
                                         dyn_string &onlyDbSystemNames, 
                                         dyn_string &onlyPvssComputerNames, 
                                         dyn_string &onlyDbComputerNames, 
                                         dyn_int &onlyPvssSystemNumbers, 
                                         dyn_int &onlyDbSystemNumbers)
{
  string filename = PROJ_PATH + CONFIG_REL_PATH + "config";
  string systemName = getSystemName();
  dyn_dyn_mixed dbConnectedSystemsInfo;
  dyn_string pvssConnectedSystemsInfo;
  dyn_string pvssConnectedSystemNames;
  dyn_string pvssConnectedComputerNames;
  dyn_int pvssConnectedSystemNumbers;
  bool centrallyManaged = false;
  bool found = false;
  int err = 0;
  dyn_string computers;
    
  
  isOk = false;
  
  paCfgReadValueList(filename, "dist", "distPeer", pvssConnectedSystemsInfo);

   //system connectivity:
  if(fwInstallationDB_getSystemConnectivity(systemName, dbConnectedSystemsInfo, true) != 0)
  {
    fwInstallation_throw("fwInstallationDBAgent_checkDistPeers() -> DB Error. Could not retrieve the list of connected systems from DB");
    return -1;   
  }

  for(int i = 1; i <= dynlen(pvssConnectedSystemsInfo); i++)  //find all pvss systems only defined in the project
  {
    found = false;
    strreplace(pvssConnectedSystemsInfo[i], "\"", "");
    dyn_string ds = strsplit(pvssConnectedSystemsInfo[i], " ");
    dynAppend(pvssConnectedComputerNames, ds[1]);
    
    for(int j = 2; j <= dynlen(ds); j++) //make code robust as users may have inserted multiple " " between hostname and system number
    {
      if(ds[j] != "")
      {
        dynAppend(pvssConnectedSystemNumbers, ds[j]);
        break;
      }
    }
    
    for(int j = 1; j <= dynlen(dbConnectedSystemsInfo); j++)
    {
        if(strtoupper(dbConnectedSystemsInfo[j][FW_INSTALLATION_DB_SYSTEM_COMPUTER])== strtoupper(pvssConnectedComputerNames[i]) && 
           (int)dbConnectedSystemsInfo[j][2] == pvssConnectedSystemNumbers[i])
        {
          found = true;
          break;
        }        
    }
    
    if(!found)
    {
      dynAppend(onlyPvssSystemNumbers, pvssConnectedSystemNumbers[i]);
      dynAppend(onlyPvssComputerNames, pvssConnectedComputerNames[i]);
    }    
  }

  
  for(int j = 1; j <= dynlen(dbConnectedSystemsInfo); j++)  //find all pvss systems only defined in the DB
  {
    found = false;
    for(int i = 1; i <= dynlen(pvssConnectedSystemsInfo); i++)
    {
        if(strtoupper(dbConnectedSystemsInfo[j][FW_INSTALLATION_DB_SYSTEM_COMPUTER]) == strtoupper(pvssConnectedComputerNames[i]) && 
           (int)dbConnectedSystemsInfo[j][2] == pvssConnectedSystemNumbers[i])
        {
          found = true;
          break;
        }
    }
    
    if(!found)
    {
      dynAppend(onlyDbSystemNames, dbConnectedSystemsInfo[j][1]);
      dynAppend(onlyDbSystemNumbers, dbConnectedSystemsInfo[j][2]);
      dynAppend(onlyDbComputerNames, dbConnectedSystemsInfo[j][FW_INSTALLATION_DB_SYSTEM_COMPUTER]);
    }    
  }

  //Check consistency:
  if(dynlen(onlyPvssComputerNames) <= 0 &&
     dynlen(onlyDbComputerNames) <= 0)
    isOk = true;  
  else
    isOk = false;

    return 0 ;
  
}  

/** This function returns whether the distribution manager has to be restarted during the synchronization process
  @return 1 if the dist manager has to be restarted, otherwise 0.  
*/

int fwInstallationDBAgent_isDistRestartRequired()
{
  int required = 0;
  dpGet("fwInstallation_agentParametrization.managers.stopDistAfterSync", required);
  
  return required;  
}

/** This function synchronizes the list of dist peers in the current project and in the
    System Configuration. The synchronization depends on the management mode of the project:
    
    - if the project is locally managed, the contents of the system confiuguration db 
      are updated with the list of dist peers currently defined in the project.
      
      
    - if the project is centrally managed, the DB-Agent of the installation tool modifies
      the list of dist-peers defined in the local project to reflect the contents of the 
      system configuration DB.
  @return 0 if OK, -1 if errors      
*/
int fwInstallationDBAgent_synchronizeDistPeers()
{
  string filename = PROJ_PATH + CONFIG_REL_PATH + "config";
  string systemName = getSystemName();
  bool centrallyManaged = fwInstallationDB_getCentrallyManaged();
  bool found = false;
  int err = 0;
  dyn_string computers;
    
  dyn_string onlyPvssSystemNames, onlyDbSystemNames;
  dyn_string onlyPvssComputerNames, onlyDbComputerNames;
  dyn_int onlyPvssSystemNumbers, onlyDbSystemNumbers;
  bool isOk = false;
  bool modified = false;

  fwInstallationDBAgent_checkDistPeers(isOk, onlyPvssSystemNames, onlyDbSystemNames, onlyPvssComputerNames, onlyDbComputerNames, onlyPvssSystemNumbers, onlyDbSystemNumbers);    
  if(isOk)
    return 0; //Nothing to be done.
    
	//gCacheRequiresUpgrade = true;
  
  fwInstallationDBCache_clear();

  if(centrallyManaged)
  {
    //update config file:
    string s = "";
    
    
    //Delete first unncessary entries in the config file..but only if we are allowed
    if(fwInstallation_deleteFromConfigFile())
    {
      for(int i =1; i <= dynlen(onlyPvssComputerNames); i++)
      {
        s = "\"" + onlyPvssComputerNames[i] + "\" " + onlyPvssSystemNumbers[i];
        fwInstallation_throw("fwInstallationDBAgent_synchronizeDistPeers() -> Deleting from config file connectivity to distPeer: " + s, "INFO");
        paCfgDeleteValue (filename, "dist", "distPeer" , s);
        modified = true;
      }
    }
    
    //Add now missing entries to the config file:
    for(int i =1; i <= dynlen(onlyDbComputerNames); i++)
    {
      s = "NOQUOTE:\"" + onlyDbComputerNames[i] + "\" " + onlyDbSystemNumbers[i];
      fwInstallation_throw("fwInstallationDBAgent_synchronizeDistPeers() -> Registering in config file connectivity to distPeer: " + s, "INFO");
      paCfgInsertValue (filename, "dist", "distPeer" , s);
      modified = true;
    }

    //Restart the dist manager if necessary:
    if(modified && fwInstallationDBAgent_isDistRestartRequired())
    {
      fwInstallation_throw("List of dist peers modified, restarting the "+fwInstallation_getWCCOAExecutable("dist")+ " manager now...", "INFO", 10);
      fwInstallationManager_restart(fwInstallation_getWCCOAExecutable("dist"), "");
    }    
    else
      fwInstallation_throw("List of dist peers modified. The distribution manager ("+fwInstallation_getWCCOAExecutable("dist")+") must be restarted manually.", "INFO", 10);
    
  }
  else    // It is not possible to find out the system we should connect to if this is not unique in the computer.
  {
    //update db contents:
    
    //Delete first unncessary entries in the db:
    for(int i =1; i <= dynlen(onlyDbSystemNames); i++)
    {
      fwInstallation_throw("fwInstallationDBAgent_synchronizeDistPeers() -> Deleting from DB connection to distPeer: " + onlyDbSystemNames[i], "INFO");
      if(fwInstallationDB_removeSystemConnection(systemName, onlyDbSystemNames[i]) != 0)
      {
        ++err;
        fwInstallation_throw("fwInstallationDBAgent_synchronizeDistPeers() -> Could not delete peer from DB: " + onlyDbSystemNames[i], "WARNING");
      }

    }
    
    //Add now missing entries to DB:
    for(int i =1; i <= dynlen(onlyPvssComputerNames); i++)
    {      
      string peerName = "";
      fwInstallationDB_getSystemName(onlyPvssSystemNumbers[i], peerName);
      
      if(peerName == "" || fwInstallationDB_addSystemConnection(systemName, peerName) != 0)
      {
        ++err;
        fwInstallation_throw("fwInstallationDBAgent_synchronizeDistPeers() -> Could not register in DB connection to peer " + peerName + " " + onlyPvssSystemNumbers[i] + " in host: " + onlyPvssComputerNames[i], "warning", 12);
        continue;
      }
      
      fwInstallation_throw("fwInstallationDBAgent_synchronizeDistPeers() -> Registering in DB connection to distPeer: " + peerName + " in host: " + onlyPvssComputerNames[i], "INFO", 10);      

    }
  }
  return 0;   
}

int fwInstallationDBAgent_checkReduInfo(bool &isOk, string &dbData, string &dbEvent, string &pvssData, string &pvssEvent)
{
  dyn_mixed pvssProjectInfo;
  dyn_mixed dbProjectInfo;
  int projId = -1;
  fwInstallationDB_getProjectProperties(PROJ, fwInstallation_getHostname(), dbProjectInfo, projId);
  
  dbData = dbProjectInfo[FW_INSTALLATION_DB_PROJECT_HOST] + ":" + dbProjectInfo[FW_INSTALLATION_DB_PROJECT_DATA] + "$" + dbProjectInfo[FW_INSTALLATION_DB_PROJECT_REDU_HOST] + ":" + dbProjectInfo[FW_INSTALLATION_DB_PROJECT_DATA];
  dbEvent = dbProjectInfo[FW_INSTALLATION_DB_PROJECT_HOST] + ":" + dbProjectInfo[FW_INSTALLATION_DB_PROJECT_EVENT] + "$" + dbProjectInfo[FW_INSTALLATION_DB_PROJECT_REDU_HOST] + ":" + dbProjectInfo[FW_INSTALLATION_DB_PROJECT_EVENT];

  paCfgReadValue(PROJ_PATH + CONFIG_REL_PATH + "config", "general", "data", pvssData);
  paCfgReadValue(PROJ_PATH + CONFIG_REL_PATH + "config", "general", "event", pvssEvent);

  if((dbData == pvssData && dbEvent == pvssEvent) ||
     (dbProjectInfo[FW_INSTALLATION_DB_PROJECT_HOST] == dbProjectInfo[FW_INSTALLATION_DB_PROJECT_REDU_HOST]))
    isOk = true;
  else
  {
//DebugN("in check redu, dbData == pvssData, dbEvent == pvssEvent, dbData , pvssData , dbEvent , pvssEvent", dbData == pvssData, dbEvent == pvssEvent, dbData , pvssData , dbEvent , pvssEvent);    
    isOk = false;  
  }
//DebugN("in agent lib, dbData, dbEvent, pvssData, pvssEvent, isOk", dbData, dbEvent, pvssData, pvssEvent, isOk);  

  return 0;  
}  


/** This function synchronizes the project redundant information with the System Configuration. 
    The synchronization steps depend on the management mode of the project:
    
    - if the project is locally managed, the contents of the system configuration db
      
    - if the project is centrally managed, the DB-Agent of the installation tool modifies
      the contents of the local project config file and adds the necessary managers to the project console 
      to reflect the contents of the system configuration DB.
  @return 0 if OK, -1 if errors      
*/
int fwInstallationDBAgent_synchronizeReduInfo()
{
  string filename = PROJ_PATH + CONFIG_REL_PATH + "config";
  string systemName = getSystemName();
  bool centrallyManaged = fwInstallationDB_getCentrallyManaged();
  int err = 0;
  bool isOk = false;
  bool modified = false;
  string dbData, dbEvent, pvssData, pvssEvent;

  fwInstallationDBAgent_checkReduInfo(isOk, dbData, dbEvent, pvssData, pvssEvent);

  if(isOk)
    return 0; //Nothing to be done.
    
	//gCacheRequiresUpgrade = true;
  
  fwInstallationDBCache_clear();

  if(centrallyManaged)
  {
    fwInstallation_throw("fwInstallationDBAgent_synchronizeReduInfo() -> Registering in config file event and data definition for redundant project: event = " + dbEvent + ", data = " + dbData, "INFO");
    paCfgInsertValue (filename, "general", "event" , dbEvent);
    paCfgInsertValue (filename, "general", "data" , dbData);
    
    fwInstallationManager_add(fwInstallation_getWCCOAExecutable("redu"), "always", 30, 1, 1, "");
    fwInstallationManager_add(fwInstallation_getWCCOAExecutable("split"), "always", 30, 1, 1, "");

    //Restart managers:
    fwInstallation_throw("Redundancy configured. Restarting " + fwInstallation_getWCCOAExecutable("redu") + " manager now...", "INFO", 10);
    fwInstallationManager_restart(fwInstallation_getWCCOAExecutable("redu"), "");
    fwInstallation_throw("Redundancy configured. Restarting " + fwInstallation_getWCCOAExecutable("split") + " manager now...", "INFO", 10);
    fwInstallationManager_restart(fwInstallation_getWCCOAExecutable("split"), "");   
  }
  return 0;   
}


/** This function unregisters all project paths from the System Configuration DB for a particular project
  @param projectName name of the PVSS project
  @param computerName hostaname where the project runs
  @return 0 if OK, -1 if errors      
*/
int fwInstallationDBAgent_unregisterProjectPaths(string projectName = "", string computerName = "")
{
  dyn_string exceptionInfo;
  dyn_dyn_mixed aRecords;
  string sql;
  bool isValid;
  
  int project_id;

  if(projectName == "")
    projectName = PROJ;
  
  if(computerName == "")
    computerName = fwInstallation_getHostname();
  
  computerName = strtoupper(computerName);

  if(fwInstallationDB_isProjectRegistered(project_id, projectName, computerName) != 0)
  {
    fwInstallation_throw("fwInstallationDB_unregisterProjectPaths() -> Could not retrieve project installation path information from DB");
    return -1;
    
  }else if(project_id == -1){
    return 0;      
  }else{
         
     sql = "delete fw_sys_stat_inst_path WHERE project_id = " + project_id;
     if(rdbExecuteSqlStatement(gFwInstallationDBConn, sql)) {fwInstallation_throw("fwInstallationDB_unregisterProjectPaths() -> Could not execute the following SQL: " + sql); return -1;};
     
     fwInstallationDBCache_clear();
     }      
  return 0;
}


/** This function registers all project paths in the System Configuration DB for a particular project
  @param paths list of project paths
  @param projectName name of the PVSS project
  @param computerName hostaname where the project runs
  @return 0 if OK, -1 if errors      
*/
int fwInstallationDBAgent_registerProjectPaths(dyn_string paths, string projectName = "", string computerName = "")
{
  dyn_string exceptionInfo;
  dyn_dyn_mixed aRecords;
  string sql;
  bool isValid;
  
  int project_id;

  if(projectName == "")
    projectName = PROJ;
  
  if(computerName == "")
    computerName = fwInstallation_getHostname();
  
  computerName = strtoupper(computerName);

  if(fwInstallationDB_isProjectRegistered(project_id, projectName, computerName) != 0)
  {
    fwInstallation_throw("fwInstallationDB_registerProjectPaths() -> Could not retrieve project installation path information from DB");
    return -1;
    
  }else if(project_id == -1){
    return 0;      
  }else{
     for(int i = 1; i <= dynlen(paths); i++)
     {    
       sql = "INSERT INTO fw_sys_stat_inst_path(id, project_id, path, valid_from, valid_until) VALUES((fw_sys_stat_inst_path_sq.NEXTVAL), " + project_id + ", \'" + paths[i] + "\', SYSDATE, NULL)";      
       if(rdbExecuteSqlStatement(gFwInstallationDBConn, sql)) {fwInstallation_throw("fwInstallationDB_registerProjectPaths() -> Could not execute the following SQL: " + sql); return -1;};
       
       fwInstallationDBCache_clear();
     }
   }      
  return 0;
}




