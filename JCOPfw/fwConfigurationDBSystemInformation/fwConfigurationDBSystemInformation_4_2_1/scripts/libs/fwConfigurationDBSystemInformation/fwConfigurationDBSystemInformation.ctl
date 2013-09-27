#uses "fwInstallation.ctl"
#uses "fwInstallationDB.ctl"
#uses "fwInstallationDBAgent.ctl"

int FW_INST_TAG_COL = 0;
int FW_INST_VERSION_COL = 1;
int FW_INST_TYPE_COL = 2;

string FW_INST_SYSTEM_TYPE = "SYSTEM";
string FW_INST_COMPUTER_TYPE = "COMPUTER";
string FW_INST_PROJECT_TYPE = "PROJECT";
string FW_INST_GROUP_TYPE = "GROUP";
string FW_INST_COMPONENT_TYPE = "COMPONENT";
       
string FW_INST_SYSTEM_PNL = "fwConfigurationDBSystemInformation/fwConfigurationDBSystemInformation_systemManager.pnl";
string FW_INST_COMPUTER_PNL = "fwConfigurationDBSystemInformation/fwConfigurationDBSystemInformation_computerManager.pnl";
string FW_INST_PROJECT_PNL = "fwConfigurationDBSystemInformation/fwConfigurationDBSystemInformation_projectManager.pnl";
string FW_INST_GROUP_PNL = "fwConfigurationDBSystemInformation/fwConfigurationDBSystemInformation_groupManager.pnl";
string FW_INST_COMPONENT_PNL = "fwConfigurationDBSystemInformation/fwConfigurationDBSystemInformation_componentProperties.pnl";
string FW_INST_PVSS_SYSTEM_PNL = "fwConfigurationDBSystemInformation/fwConfigurationDBSystemInformation_pvssSystemProperties.pnl";

string FW_INST_SYSTEM_NAME_PNL = "SYSTEM";
string FW_INST_PVSS_SYSTEM_NAME_PNL = "PVSS SYSTEM";
string FW_INST_COMPUTER_NAME_PNL = "COMPUTER";
string FW_INST_PROJECT_NAME_PNL = "PROJECT";
string FW_INST_GROUP_NAME_PNL = "GROUP";
string FW_INST_COMPONENT_NAME_PNL = "COMPONENT";

const string FW_SYS_STAT_SEPARATOR = "/";

const string FW_SYS_STAT_DB_NAV_DPT = "_FwSysStatDbEditorNavigator";	
const string FW_SYS_STAT_DB_NAV_DP = "fwSysStatDbEditorNavigator";	
const string FW_SYS_STAT_REQUIRED_INSTALLATION_TOOL_VERSION = "6.1.0";	

const string FW_CONFDB_LOGGER_DPT = "_FwConfDBSystemInformationActionsLog";
const string FW_CONFDB_LOGGER = "fwConfDBSystemInformationLogger";
const string FW_CONFDB_LOGGER_ENABLED = ".enableLogging";
const string FW_CONFDB_LOGGER_ACTION_TIME= ".action.time";
const string FW_CONFDB_LOGGER_ACTION_DESCRIPTION = ".action.description";
const string FW_CONFDB_LOGGER_ACTION_USER = ".action.user";

dyn_string FW_SYS_STAT_DB_NAV_MODES; 


const int FW_SYS_STAT_ERROR = -1;
const int FW_SYS_STAT_OK = 0;

const string csFwSysStatManangementLibVersion = "4.1.2";
const string csFwSysStatManagementTool = "4.1.2";

//Hierarchy of PVSS systems  passed as a dyn_dyn_mixed:
int FW_CONFDB_SYSSTAT_SYSTEM_NAME_IDX = 1;
int FW_CONFDB_SYSSTAT_SYSTEM_NUMBER_IDX = 2;
int FW_CONFDB_SYSSTAT_SYSTEM_ID_IDX = 3;
int FW_CONFDB_SYSSTAT_SYSTEM_PARENT_ID_IDX = 4;

//Project group properties:
const int FW_INSTALLATION_DB_PROJECT_GROUP_REQUESTED_BY = 1;
const int FW_INSTALLATION_DB_PROJECT_GROUP_REQUESTED_DATE = 2;
const int FW_INSTALLATION_DB_PROJECT_GROUP_OVERWRITE = 3;
const int FW_INSTALLATION_DB_PROJECT_GROUP_FORCE = 4;
const int FW_INSTALLATION_DB_PROJECT_GROUP_SILENT = 5;
const int FW_INSTALLATION_DB_PROJECT_GROUP_INST_DATE = 6;


int fwConfigurationDBSystemInformation_createRedundantCopy(string project, string hostname, string reduHost) 
{
  dyn_mixed projectInfo;
  int id = -1;
  
  reduHost = strtoupper(reduHost);
  if(reduHost == "")
  {
    fwInstallation_throw("Cannot create redundant copy of the project. Redundant hostname cannot be empty");    
    return -1;
  }
  
  if(fwInstallationDB_isPCRegistered(id, reduHost))
  {
    fwInstallation_throw("Cannot create redundant copy of the project. Could not check if host is registered in the DB: " + reduHost);    
    return -1;
  }
  
  if(id == -1)
  {
    dyn_mixed hostInfo;
    hostInfo[FW_INSTALLATION_DB_HOST_NAME_IDX] = reduHost;
    if(fwInstallationDB_registerPC(reduHost, hostInfo))
    {
      fwInstallation_throw("Cannot create redundant copy of the project. Could not register in the DB: " + reduHost);    
      return -1;
    }
    
    fwInstallationDB_isPCRegistered(id, reduHost);
    if(id == -1)
    {
      fwInstallation_throw("Cannot create redundant copy of the project. Could not check if host is registered in the DB: " + reduHost);    
      return -1;
    }
  }
  
  if(fwInstallationDB_getProjectProperties(project, hostname, projectInfo, id))  
  {
    fwInstallation_throw("Cannot create redundant copy of the project. Could not read properties of project: " + project + " in host: " + hostname + " from the DB");    
    return -1;
  }
  else if(id == -1)
  {
    fwInstallation_throw("Cannot create redundant copy of the project. Project: " + project + " in host: " + hostname + " is not registered in the DB");    
    return -1;
  }
  
  projectInfo[FW_INSTALLATION_DB_PROJECT_REDU_HOST] = reduHost;
  if(fwInstallationDB_setProjectProperties(project, hostname, projectInfo))  
  {
    fwInstallation_throw("Cannot create redundant copy of the project. Could not set properties of project: " + project + " in host: " + reduHost + " in the DB");    
    return -1;
  }
  return 0;
}

/*
int fwConfigurationDBSystemInformation_moveProject(string host, string project, string newHost, string newEvHost = "")
{
   dyn_mixed projectProperties;
   int hostId = -1, projectId = -1;
   string sql;

   //Initial checks
   if(newHost == "") {fwInstallation_throw("Failed to move: " + project + " in host: " + host + ". The target host name cannot be empty"); return -1;}
   if(newEvHost == "") newEvHost = newHost;

   fwInstallationDB_getProjectProperties(project, host, projectProperties, projectId);
   if(projectId == -1) {fwInstallation_throw("Failed to move: " + project + " as this project is not registered in host: " + host);return -1;}
   
   if(fwInstallationDB_isPCRegistered(hostId, newHost)){fwInstallation_throw("Failed to move: " + project + " as it failed to check if host is registered in DB: " + newHost); return -1;}
   if(hostId == -1)
   {
     dyn_mixed hostInfo;
     hostInfo[FW_INSTALLATION_DB_HOST_NAME_IDX] = newHost;
     
     if(fwInstallationDB_registerPC(newHost, hostInfo)) {fwInstallation_throw("Failed to move: " + project + " as it failed to register the new host in the DB: " + newHost); return -1;}
     
     fwInstallationDB_isPCRegistered(hostId, newHost);
     if(hostId == -1) {fwInstallation_throw("Failed to move: " + project + " as it failed to register the new host in the DB: " + newHost); return -1;}
   }
   
   sql = "UPDATE FW_SYS_STAT_PVSS_PROJECT SET COMPUTER_ID = " + hostId + " WHERE ID = " + projectId;
   if(g_fwInstallationSqlDebug) DebugN(sql);
     
   if(rdbExecuteSqlStatement(gFwInstallationDBConn, sql)) {DebugN("Failed to move project: " + project + " in host: "+host+ " -> Could not execute the following SQL: " + sql); return -1;};

   //Update now the system information:
   dyn_mixed systemInfo;
   fwInstallationDB_getPvssSystemProperties(projectProperties[FW_INSTALLATION_DB_PROJECT_SYSTEM_NAME], systemInfo);
   systemInfo[FW_INSTALLATION_DB_SYSTEM_COMPUTER] = newEvHost;

   if(fwInstallationDB_setSystemProperties(systemInfo)) {fwInstallation_throw("Failed to move: " + project + " as it failed to update the system information: " + newHost); return -1;}
   
   return 0;
}
*/

int fwConfigurationDBSystemInformation_copyProject(string host, string project, string newHost, string newSystem = "", int newSysNum = -1, string evHost = "", bool copyPaths = true, bool copyDistPeers = true)
{
  dyn_mixed projectProperties;
  int id = -1;

  if(newHost == "") {fwInstallation_throw("Failed to copy: " + project + " in host: " + host + ". The target host name cannot be empty"); return -1;}

  fwInstallationDB_getProjectProperties(project, newHost, projectProperties, id);
  if(id != -1)
  {
    dyn_string ds;
    dyn_float df;
    ChildPanelOnCentralModalReturn("fwInstallation/fwInstallationDB_question.pnl", "Warning", makeDynString("$txt:Project: " + project + " already exists in the target PC: " + newHost + "\nDo you want to overwrite it?"), df, ds);
    if(dynlen(df) <= 0 || df[1] == 0.)
      return 0;
  }
  
  fwInstallationDB_getProjectProperties(project, host, projectProperties, id);
  if(id == -1)
  {
    fwInstallation_throw("Failed to copy: " + project + " as this project is not registered in host: " + host);
    return -1;
  }  

  string oldSystem = projectProperties[FW_INSTALLATION_DB_PROJECT_SYSTEM_NAME];
  int oldSysNum = projectProperties[FW_INSTALLATION_DB_PROJECT_SYSTEM_NUMBER];
  
  if(newSystem == ""){newSystem = oldSystem;}   
  if(newSysNum == -1){newSysNum = oldSysNum;}    
  
//  projectProperties[FW_INSTALLATION_DB_PROJECT_NAME] = project;   
  projectProperties[FW_INSTALLATION_DB_PROJECT_HOST] = strtoupper(newHost);   
  projectProperties[FW_INSTALLATION_DB_PROJECT_SYSTEM_NAME] = newSystem;   
  projectProperties[FW_INSTALLATION_DB_PROJECT_SYSTEM_NUMBER] = newSysNum;   
  
  if(evHost == "")      
    projectProperties[FW_INSTALLATION_DB_PROJECT_SYSTEM_COMPUTER] = strtoupper(newHost);   
  else
    projectProperties[FW_INSTALLATION_DB_PROJECT_SYSTEM_COMPUTER] = strtoupper(evHost);   
  
  if(fwInstallationDB_setProjectProperties(project, newHost, projectProperties)){fwInstallation_throw("Failed to copy: " + project + " from host: " + host + " to host: " + newHost);return -1;}
  
  //Copy project paths here if necessary:
  if(copyPaths)
  {
    if(fwConfigurationDBSystemInformation_copyProjectPaths(host, project, newHost, project)){fwInstallation_throw("Failed to copy project paths from: " + project + " in host: " + host + " to project "+newProject +" in host: " + newHost);return -1;}
  }
  //Copy distpeers here if necessary:
  if(copyDistPeers)
  {
    if(fwConfigurationDBSystemInformation_copySystemDistPeers(oldSystem, newSystem)){fwInstallation_throw("Failed to copy list of distPeers from: " + project + " in host: " + host + " to host: " + newHost);return -1;}
  }
  
  //Copy now the project configuration:
  if(fwConfigurationDBSystemInformation_copyProjectComponents(host, project, newHost, project)){fwInstallation_throw("Failed to copy project components from " + project + " in host: " + host + " to host: " + newHost); return -1;}

  return 0;
}

int fwConfigurationDBSystemInformation_copyProjectPaths(string host, string project, string newHost, string newProject)
{
  dyn_string projectPaths;  
  if(fwInstallationDB_getProjectPaths(project, host, projectPaths)) {fwInstallation_throw("Failed to copy project paths: Could not read path lists for project" + project + " in host: " + host); return -1;}

  int err = 0;
  for(int i = 1; i <= dynlen(projectPaths); i++)
  {
    if(fwInstallationDB_registerInstallationPath(projectPaths[i], false, newProject, newHost) != 0){
      fwInstallation_throw("Failed to copy project paths -> Failed to register " +projectPaths[i] + "into " + newProject + " in host: " + newHost);
      ++err;
    }
  }
  
  if(err)
    return -1;
  
  return 0;
}

int fwConfigurationDBSystemInformation_copySystemDistPeers(string sys, string newSys)
{
  dyn_dyn_mixed connectedSystemsInfo;
  if(fwInstallationDB_getSystemConnectivity(sys, connectedSystemsInfo, true)){fwInstallation_throw("Failed to copy project distPeers -> Failed to retrieve list of distpeers from system: " + sys);return -1;}
  
  int err = 0;
  for(int i = 1; i <= dynlen(connectedSystemsInfo); i++)
  {
    if(fwInstallationDB_addSystemConnection(newSys, connectedSystemsInfo[i][FW_INSTALLATION_DB_SYSTEM_NAME]))
    {
      fwInstallation_throw("Failed to copy project distPeers -> Failed to register connection between systems:" + newSys + " and " + connectedSystemsInfo[i][FW_INSTALLATION_DB_SYSTEM_NAME]);
      ++err;
    }
  }
  
  if(err)
    return -1;
  
  return 0;
}


int fwConfigurationDBSystemInformation_copyProjectComponents(string host, string project, string newHost, string newProject)
{
  dyn_string groups;
  dyn_int groupIds;
  
  if(fwInstallationDB_getProjectGroups(groups, groupIds, true, project, host)) {fwInstallation_throw("Failed to copy project components: Could not read component configuration for project" + project + " in host: " + host); return -1;}

  int err = 0;
  for(int i = 1; i <= dynlen(groups); i++)
  {
    dyn_mixed projectGroupInfo;
    dynClear(projectGroupInfo);
    fwInstallationDB_getProjectGroupProperties(groups[i], 
                                               projectGroupInfo, 
                                               project, 
                                               host);
    
    if(fwInstallationDB_registerGroupInProject(groups[i], 
                                               projectGroupInfo[FW_INSTALLATION_DB_PROJECT_GROUP_OVERWRITE], 
                                               projectGroupInfo[FW_INSTALLATION_DB_PROJECT_GROUP_FORCE], projectGroupInfo[FW_INSTALLATION_DB_PROJECT_GROUP_SILENT], 
                                               1, 
                                               "", 
                                               newProject, 
                                               newHost))
    {
      fwInstallation_throw("Failed to copy project components. Could not copy " + groups[i] + " from " + project + " in host: " + host + " to " + newProject + " in host: " + newHost);
      ++err;
    }
  }
  
  if(err)
    return -1;
  
  return 0;
}

int fwConfigurationDBSystemInformation_checkProjectComponents(string computerName, string project, bool &isOk, dyn_mixed &requiredMissing, dyn_mixed &instMissing)
{
  
  dyn_dyn_mixed reqComponents, instComponents;
  
  dynClear(requiredMissing);
  dynClear(instMissing);
  
  fwInstallationDB_getProjectComponents(reqComponents, project, computerName);
  fwInstallationDB_getCurrentProjectComponents(instComponents, project, computerName);
  
  for(int i = 1; i <= dynlen(reqComponents); i++)
  {
    bool found = false;
    for(int j = 1; j <= dynlen(instComponents);  j++)
    {
      if(reqComponents[i][FW_INSTALLATION_DB_COMPONENT_NAME_IDX] == instComponents[j][FW_INSTALLATION_DB_COMPONENT_NAME_IDX] &&
         reqComponents[i][FW_INSTALLATION_DB_COMPONENT_VERSION_IDX] == instComponents[j][FW_INSTALLATION_DB_COMPONENT_VERSION_IDX])
      {
        found = true;
        break;
      }
    }
    if(!found)
      dynAppend(requiredMissing, reqComponents[i]);
  }
  
  if(dynlen(requiredMissing) > 0)
  {
    isOk = false;
    return 0;
  }
  
  for(int i = 1; i <= dynlen(instComponents); i++)
  {
    bool found = false;
    for(int j = 1; j <= dynlen(reqComponents);  j++)
    {
      if(reqComponents[j][FW_INSTALLATION_DB_COMPONENT_NAME_IDX] == instComponents[i][FW_INSTALLATION_DB_COMPONENT_NAME_IDX] &&
         reqComponents[j][FW_INSTALLATION_DB_COMPONENT_VERSION_IDX] == instComponents[i][FW_INSTALLATION_DB_COMPONENT_VERSION_IDX])
      {
        found = true;
        break;
      }
    }
    
    if(!found)
      dynAppend(instMissing, instComponents[i]);
      
  }

//  DebugN(requiredMissing, instMissing);  

  if(dynlen(requiredMissing) <= 0 && dynlen(instMissing) <= 0)
    isOk = true;
  else
    isOk = false;
  
  return 0;
}

bool fwConfigurationDBSystemInformation_isAdoptionPossible(string computerName, string project)
{
  bool isOk = true;
  dyn_dyn_mixed instComponents, reqComponents;
  
  fwInstallationDB_getCurrentProjectComponents(instComponents, project, computerName);
  fwInstallationDB_getProjectComponents(reqComponents, project, computerName);

  for(int i = 1; i <= dynlen(instComponents); i++)
  {
    bool found = false;
    for(int j = 1; j <= dynlen(reqComponents); j++)
    {
      if(instComponents[i][FW_INSTALLATION_DB_COMPONENT_NAME_IDX] == reqComponents[j][FW_INSTALLATION_DB_COMPONENT_NAME_IDX] &&
         instComponents[i][FW_INSTALLATION_DB_COMPONENT_VERSION_IDX] != reqComponents[j][FW_INSTALLATION_DB_COMPONENT_VERSION_IDX])
      {
        //fwInstallation_throw("Project: " + project + " @ host: " + computerName + ": Configuration cannot be adopted as there are conflicts at the component level:\n Component: " + reqComponents[j][FW_INSTALLATION_DB_COMPONENT_NAME_IDX] + " Version installed in project: " + instComponents[j][FW_INSTALLATION_DB_COMPONENT_VERSION_IDX] + ". Version already registered in the DB: " + instComponents[j][FW_INSTALLATION_DB_COMPONENT_VERSION_IDX]);
        isOk = false;
        break;
      }
    }
    
    if(!isOk)
      break;
  }
  
  return isOk;
}


int fwConfigurationDBSystemInformation_adoptProjectConfiguration(string computerName, string project, string group = "", bool force = false)
{
  int groupId = -1;
  bool registerGroup = false;
  
  if(group == "")
    group = "g"+project;
  
  //Check if adoption is possible:
  if(!force && !fwConfigurationDBSystemInformation_isAdoptionPossible(computerName, project))
  {
    //fwInstallation_throw("Project configuration cannot be adopted as there are conflicts at the component level. These conflicts must be resolved first!");
    return -1;
  }
  
  //Invalidate all previous project groups if told to force adoption:
  if(force)
    fwInstallationDBSystemInformation_removeAllProjectGroups(project, computerName);
  
  //check if already registered:
  fwInstallationDB_isGroupRegistered(group, groupId);
    
  if(groupId < 0)
    registerGroup = true;
  else 
  {
    if(fwInstallationDBSystemInformation_unregisterAllGroupComponents(group) != 0)
    {
      ChildPanelOnCentral("vision/MessageInfo1", "ERROR", makeDynString("Failed to unregister previous components in default group."));
      return -1;
    }
    registerGroup = false;
  } 
  
  if(registerGroup)
  {
    if(fwInstallationDB_registerGroup(group) != 0)
    {
      ChildPanelOnCentral("vision/MessageInfo1", "ERROR", makeDynString("Could not create new group in DB.\nGroup names must be unique."));
      return -1;
    }
  }
  
  //Read components from table and and register them in the group
  //if they are not currently already assigned through another group
  
  dyn_dyn_mixed instComponents, reqComponents;
  fwInstallationDB_getCurrentProjectComponents(instComponents, project, computerName);
  fwInstallationDB_getProjectComponents(reqComponents, project, computerName);

  //DebugN(instComponents, "inst**************req", reqComponents);  
  for(int i = 1; i <= dynlen(instComponents); i++)
  {
    bool found = false;
    for(int j = 1; j <= dynlen(reqComponents); j++)
    {
      if(instComponents[i][FW_INSTALLATION_DB_COMPONENT_NAME_IDX] == reqComponents[j][FW_INSTALLATION_DB_COMPONENT_NAME_IDX] &&
         instComponents[i][FW_INSTALLATION_DB_COMPONENT_VERSION_IDX] == reqComponents[j][FW_INSTALLATION_DB_COMPONENT_VERSION_IDX])
      {
        DebugN("instComponents[i][FW_INSTALLATION_DB_COMPONENT_NAME_IDX]", instComponents[i][FW_INSTALLATION_DB_COMPONENT_NAME_IDX], instComponents[i][FW_INSTALLATION_DB_COMPONENT_VERSION_IDX]);
        found = true;
        break;
      }
    } 
    //DebugN("Registering " + componentName + " v." + componentVersion);
    if(!found)
    {
      if(fwInstallationDB_registerComponentInGroup(instComponents[i][FW_INSTALLATION_DB_COMPONENT_NAME_IDX], 
                                                   instComponents[i][FW_INSTALLATION_DB_COMPONENT_VERSION_IDX], 
                                                   instComponents[i][FW_INSTALLATION_DB_COMPONENT_SUBCOMP_IDX], 
                                                   instComponents[i][FW_INSTALLATION_DB_COMPONENT_DESC_FILE_IDX], 
                                                   group) != 0)
      {
        ++error;
        DebugN("ERROR: Could not add component: " + instComponents[i][FW_INSTALLATION_DB_COMPONENT_NAME_IDX] + " v." + instComponents[i][FW_INSTALLATION_DB_COMPONENT_VERSION_IDX] + " into group: " + group); 
      }
    }
  }
  
  //DebugN("Adding group to project: " + group);
  if(fwInstallationDB_registerGroupInProject(group, 0, 1, 0, 1, "", project, computerName) != 0)
  {
    ChildPanelOnCentralModal("vision/MessageInfo1", "ERROR", makeDynString("$1:Cannot adopt project configuration.\nCould not add group: " + group + " to project: " + project + " in computer: " + computerName)); 
    return -1;
  }
  
  return 0; 
}


string fwConfigurationDBSystemInformation_getToolVersion()
{
  return csFwSysStatManagementTool;
}

int fwConfigurationDBSystemInformation_init()
{
  string schemaVersion = "N/A";
  
  int err = fwInstallationDB_connect();
  
  fwInstallationDB_getSchemaVersion(schemaVersion);
    
  FW_SYS_STAT_DB_NAV_MODES = makeDynString("Projects Setup", "System Hierarchy");
  
  if(fwConfigurationDBSystemInformation_createEditorNavigatorDpt() != 0 || 
     fwConfigurationDBSystemInformation_createEditorNavigatorDp() != 0  ||
     fwConfigurationDBSystemInformation_setCurrentNavigationMode(FW_SYS_STAT_DB_NAV_MODES[1]) != 0)
  {
    return FW_SYS_STAT_ERROR;
  }else{
    cbModes.items = FW_SYS_STAT_DB_NAV_MODES;
    cbModes.text = FW_SYS_STAT_DB_NAV_MODES[1];
    dpConnect("fwConfigurationDBSystemInformation_displayCurrentModeCB", FW_SYS_STAT_DB_NAV_DP + ".currentMode");
    dpConnect("fwConfigurationDBSystemInformation_refreshTreeCB", FW_SYS_STAT_DB_NAV_DP + ".currentMode");
  }
  
  txVersion.text = "DB schema v.: " + schemaVersion;
  string ver;
  fwInstallation_getToolVersion(ver);
  txInstToolVersion.text = "FW Component Installation Tool v." + ver;
  txToolVersion.text = "System Configuration DB Editor v." + fwConfigurationDBSystemInformation_getToolVersion();

  string user, db;
  dpGet("fwInstallation_agentParametrization.db.connection.username", user,
        "fwInstallation_agentParametrization.db.connection.server", db);
  txDB.text = "DB Server: " + db;
  txUser.text = "DB User: " + user;                    
  if(err == 0)
  {
    txStatus.text = "OK";
    shConnectionStatus.backCol = "green";
  }
  else
  {
    txStatus.text = "NOT OK";
    shConnectionStatus.backCol = "red";
  }

  if(fwInstallation_checkToolVersion(FW_SYS_STAT_REQUIRED_INSTALLATION_TOOL_VERSION) < 1)
  {
      ChildPanelOnCentralModal("vision/MessageInfo1", "Wrong Installer Version", makeDynString("$1:This version of the application requires \nversion "+FW_SYS_STAT_REQUIRED_INSTALLATION_TOOL_VERSION + " of the Component Installation Tool.\nPlease, upgrade the installer version"));
      return -1;
  }    
  
  return FW_SYS_STAT_OK;

}
void fwConfigurationDBSystemInformation_refreshTreeCB(string modeDpe, string currentMode)
{
  //string id = treeEditor.currentItem();
  //string parent = treeEditor.parent(id);
  
  
  switch(currentMode){
    case "Projects Setup":  fwConfigurationDBSystemInformation_refreshSetupTree();
                            break; 
                            
    case "System Hierarchy":  fwConfigurationDBSystemInformation_refreshHierarchyTree();
                            break; 
    default: DebugN("WARNING: fwConfigurationDBSystemInformation_refreshTreeCB() -> Unknown current mode: ", currentMode);
             break;
    
  }//end of switch  
  
//  if(treeEditor.itemExists(parent)){
//    DebugN("Expanding parent: ", parent, treeEditor.getText(parent, 0));
//    treeEditor.ensureItemVisible(parent);  
//  }
}

int fwConfigurationDBSystemInformation_clearTree()
{
  int col = treeEditor.columns;
  for(int i = col-1; i >= 0; i--){
    treeEditor.removeColumn(i);
  }

  return FW_SYS_STAT_OK;
}

void fwConfigurationDBSystemInformation_refreshSetupTree()
{
  dyn_string hostnames, ips, macs, ips2, macs2, bmc_ips, bmc_ips2;
  dyn_string projects;
  bool onlyActive = true;
  dyn_string groups;
  dyn_int groupIds;
  dyn_string componentNames, componentVersions;
  dyn_string ids;
  dyn_dyn_mixed componentsInfo;
  
  string id = treeEditor.currentItem();
  string parent = treeEditor.parent(id);
  
  if(fwInstallationDB_connect() != 0)
  {
    ChildPanelOnCentral("vision/MessageInfo1", "ERROR: DB Connection failed", makeDynString("$1:DB Connection failed.\nPlease check DB connection parameters"));
  }
  
  ids =treeEditor.children("");
  if(dynlen(ids))
    treeEditor.removeItems(ids);
  
  fwConfigurationDBSystemInformation_clearTree();
  
  
  //Add three columns 
 treeEditor.addColumn("DB Editor and Navigator"); 
 treeEditor.addColumn("Version"); 
 treeEditor.addColumn("type"); 
 treeEditor.hideColumn(FW_INST_TYPE_COL);
  
  fwInstallationDB_getHosts(hostnames, ips, macs, ips2, macs2, bmc_ips, bmc_ips2);

  treeEditor.appendItem("","Computers", "Computers");           
  treeEditor.setText("Computers", FW_INST_TYPE_COL, FW_INST_SYSTEM_TYPE);
  for(int i = 1; i <= dynlen(hostnames); i++){
     treeEditor.appendItem("Computers", hostnames[i], hostnames[i]); 
     treeEditor.setText(hostnames[i], FW_INST_TYPE_COL, FW_INST_COMPUTER_TYPE); 
     //For each of the hosts, get the list of PVSS projects
     fwInstallationDB_getPvssProjects(projects, hostnames[i], onlyActive);
     for(int j = 1; j <= dynlen(projects); j++){
       treeEditor.appendItem(hostnames[i],  hostnames[i]+"|"+projects[j], projects[j]);
       treeEditor.setText(hostnames[i]+"|"+projects[j], FW_INST_TYPE_COL, FW_INST_PROJECT_TYPE); 
       
/* Savannah #47320: Tree too slow when dealing with a big system.
              //List of groups per project
       fwInstallationDB_getProjectGroups(groups, groupIds, onlyActive, projects[j], hostnames[i]);

       for(int k = 1; k <= dynlen(groups); k++){
         treeEditor.appendItem(hostnames[i]+"|"+projects[j], hostnames[i]+"|"+projects[j]+"|"+groups[k], groups[k]); 
         treeEditor.setText(hostnames[i]+"|"+projects[j]+"|"+groups[k], FW_INST_TYPE_COL, FW_INST_GROUP_TYPE); 
         fwInstallationDB_getGroupComponents(groups[k], componentsInfo);
//         componentNames = componentsInfo[i][FW_INSTALLATION_DB_COMPONENT_NAME_IDX];
//         componentVersions = componentsInfo[i][FW_INSTALLATION_DB_COMPONENT_VERSION_IDX];
         for(int z = 1; z <= dynlen(componentsInfo); z++){
            treeEditor.appendItem(hostnames[i]+"|"+projects[j]+"|"+groups[k], hostnames[i]+"|"+projects[j]+"|"+groups[k]+ "|" + (string) componentsInfo[z][FW_INSTALLATION_DB_COMPONENT_NAME_IDX], (string) componentsInfo[z][FW_INSTALLATION_DB_COMPONENT_NAME_IDX]);
            treeEditor.setText(hostnames[i]+"|"+projects[j]+"|"+groups[k]+ "|" + (string)  componentsInfo[z][FW_INSTALLATION_DB_COMPONENT_NAME_IDX], FW_INST_VERSION_COL, (string) componentsInfo[z][FW_INSTALLATION_DB_COMPONENT_VERSION_IDX]); 
            treeEditor.setText(hostnames[i]+"|"+projects[j]+"|"+groups[k]+ "|" + (string) componentsInfo[z][FW_INSTALLATION_DB_COMPONENT_NAME_IDX], FW_INST_TYPE_COL, FW_INST_COMPONENT_TYPE);    
         }
       }
*/       
     }      
  }  
   //treeEditor.hideColumn(FW_INST_TYPE_COL);
  
  if(treeEditor.itemExists(parent)){
    //DebugN("Expanding parent: ", parent, treeEditor.getText(parent, 0));
    treeEditor.ensureItemVisible(parent);  
  }
 
}

void fwConfigurationDBSystemInformation_refreshHierarchyTree()
{
  dyn_string ids;
  dyn_dyn_mixed hierarchyInfo;
  string id = treeEditor.currentItem();
  string parent = treeEditor.parent(id);
  string parentId, idx, text;
  string num;
  
  dynClear(hierarchyInfo);
    
  if(fwInstallationDB_connect() != 0)
  {
    ChildPanelOnCentral("vision/MessageInfo1", "ERROR: DB Connection failed", makeDynString("$1:DB Connection failed.\nPlease check DB connection parameters"));
  }
  
  treeEditor.clear();
  fwConfigurationDBSystemInformation_clearTree();
  
  
  //Add three columns 
  treeEditor.addColumn("System Name"); 
  treeEditor.addColumn("Number"); 
  
  fwConfigurationDBSystemInformation_getSystemHierarchy(hierarchyInfo);

  for(int i = 1; i <= dynlen(hierarchyInfo); i++){
    if(dynlen(hierarchyInfo[i]) < 4)//Show also systems in the tree with no parent 
       hierarchyInfo[i][FW_CONFDB_SYSSTAT_SYSTEM_PARENT_ID_IDX] = "";
      
     if(hierarchyInfo[i][FW_CONFDB_SYSSTAT_SYSTEM_PARENT_ID_IDX] <= 0)
       hierarchyInfo[i][FW_CONFDB_SYSSTAT_SYSTEM_PARENT_ID_IDX] = "";
     
     parentId = hierarchyInfo[i][FW_CONFDB_SYSSTAT_SYSTEM_PARENT_ID_IDX];
     idx = hierarchyInfo[i][FW_CONFDB_SYSSTAT_SYSTEM_ID_IDX];
     text = hierarchyInfo[i][FW_CONFDB_SYSSTAT_SYSTEM_NAME_IDX];
     num = hierarchyInfo[i][FW_CONFDB_SYSSTAT_SYSTEM_NUMBER_IDX];
      
     //DebugN("adding a new node to: ", parentId, idx, text, num);
     treeEditor.appendItem(parentId, idx, text);
     treeEditor.setText(idx,1, num);
     
     //delay(2);
     //treeEditor.appendItem((string) hierarchyInfo[i][FW_CONFDB_SYSSTAT_SYSTEM_PARENT_ID_IDX],  (string) hierarchyInfo[i][FW_CONFDB_SYSSTAT_SYSTEM_ID_IDX], (string) hierarchyInfo[i][FW_CONFDB_SYSSTAT_SYSTEM_NAME_IDX]); 
     //treeEditor.setText((string) hierarchyInfo[i][FW_CONFDB_SYSSTAT_SYSTEM_ID_IDX], 1, (string) hierarchyInfo[i][FW_CONFDB_SYSSTAT_SYSTEM_NUMBER_IDX]); 
  }
  
  if(treeEditor.itemExists(parent)){
    //DebugN("Expanding parent: ", parent, treeEditor.getText(parent, 0));
    treeEditor.ensureItemVisible(parent);  
  }

}

void fwConfigurationDBSystemInformation_displayCurrentModeCB(string modeDpe, string currentMode)
{
  tfCurrentMode.text = currentMode;

}

int fwConfigurationDBSystemInformation_createEditorNavigatorDpt()
{
  dyn_string existingTypes = dpTypes(FW_SYS_STAT_DB_NAV_DPT);
  dyn_dyn_string dynDynElements;
  dyn_dyn_int dynDynTypes;
  int result = 0;

  dynDynElements[1] = makeDynString (FW_SYS_STAT_DB_NAV_DPT, "");
  dynDynTypes[1] = makeDynInt (DPEL_STRUCT);

  dynDynElements[2] = makeDynString ("","modes");
  dynDynElements[3] = makeDynString ("","currentMode");
  dynDynElements[4] = makeDynString ("","centralRepository");
  dynDynElements[5] = makeDynString ("","","active");
  dynDynElements[6] = makeDynString ("","","path");
  
  dynDynTypes[2] = makeDynInt (0, DPEL_DYN_STRING);
  dynDynTypes[3] = makeDynInt (0, DPEL_STRING);
  dynDynTypes[4] = makeDynInt (0, DPEL_STRUCT);
  dynDynTypes[5] = makeDynInt (0, 0, DPEL_INT);
  dynDynTypes[6] = makeDynInt (0, 0, DPEL_STRING);

  // Create or change the datapoint type
   if(dynlen(existingTypes) <= 0)
  	 result = dpTypeCreate(dynDynElements, dynDynTypes );
   else
   	 result = dpTypeChange(dynDynElements, dynDynTypes );
	
   dynClear(dynDynElements);
   dynClear(dynDynTypes);

   return result;
  
}

int fwConfigurationDBSystemInformation_createEditorNavigatorDp()
{
  int err = dpCreate(FW_SYS_STAT_DB_NAV_DP, FW_SYS_STAT_DB_NAV_DPT);
  if(err == 0 )
   return dpSet(FW_SYS_STAT_DB_NAV_DP + ".modes", FW_SYS_STAT_DB_NAV_MODES);

  return FW_SYS_STAT_ERROR;
 
}

int fwConfigurationDBSystemInformation_getNavigationModes(dyn_string &modes){
  return dpGet(FW_SYS_STAT_DB_NAV_DP + ".modes", modes); 
}

int fwConfigurationDBSystemInformation_setCurrentNavigationMode(string currentMode)
{
  dyn_string modes;
  
  fwConfigurationDBSystemInformation_getNavigationModes(modes);
  
  if(dynContains(modes, currentMode) > 0){
    return dpSet(FW_SYS_STAT_DB_NAV_DP + ".currentMode", currentMode); 
  }else{
    DebugN("ERROR: fwConfigurationDBSystemInformation_setCurrentNavigationMode() -> Invalid navigation mode");
    return FW_SYS_STAT_ERROR;
  }  
}
  
int fwConfigurationDBSystemInformation_getCurrentNavigationMode(string &currentMode)
{
  return dpGet(FW_SYS_STAT_DB_NAV_DP + ".currentMode", currentMode); 
}
   
//Hierarchy of PVSS Systems:
int fwConfigurationDBSystemInformation_addChildSystem(string parentSystem, string childSystem)
{
  int parentId;
  int childId;
  dyn_string exceptionInfo;
  dyn_dyn_mixed aRecords;
  string sql;

  dynClear(aRecords);


  if(fwInstallationDB_isSystemRegistered(parentId, parentSystem) != 0 || fwInstallationDB_isSystemRegistered(childId, childSystem) != 0)
  {
    DebugN("ERROR: fwInstallationDB_addChildSystem() -> Could not access the DB");
    return -1;    
  }else if(parentId == -1 || childId == -1){
    DebugN("ERROR: fwInstallationDB_addChildSystem() -> Both systems must be registered in the FW System Static Configuration DB first");
    return -1;      
  }else{      
     sql = "UPDATE fw_sys_stat_pvss_system SET parent_system_id = " + parentId + " WHERE id = " + childId;
       
    if(g_fwInstallationSqlDebug)
      DebugN(sql);
  
    if(rdbExecuteSqlStatement(gFwInstallationDBConn, sql)) {DebugN("ERROR: fwInstallationDB_addChildSystem() -> Could not execute the following SQL: " + sql); return -1;};
  }
  
  return 0;
}

int fwConfigurationDBSystemInformation_removeChildSystem(string systemName)
{
  int id;
  dyn_string exceptionInfo;
  dyn_dyn_mixed aRecords;
  string sql;

  dynClear(aRecords);
  if(!patternMatch("*:", systemName))
    systemName += ":";

  //DebugN("Removing system " + systemName);
  
  if(fwInstallationDB_isSystemRegistered(id, systemName) != 0)
  {
    DebugN("ERROR: fwConfigurationDBSystemInformation_removeChildSystem() -> Could not access the DB");
    return -1;    
  }else if(id == -1){
    DebugN("INFO: fwConfigurationDBSystemInformation_removeChildSystem() -> System: " + systemName + " is not registered in the DB. Nothing to be done");
    return 0;      
  }else{
    sql = "UPDATE fw_sys_stat_pvss_system SET parent_system_id = NULL WHERE id = " + id;
         
    if(g_fwInstallationSqlDebug)
      DebugN(sql);
  
    if(rdbExecuteSqlStatement(gFwInstallationDBConn, sql)) {DebugN("ERROR: fwConfigurationDBSystemInformation_removeChildSystem() -> Could not execute the following SQL: " + sql); return -1;};
  }

  return 0;
}

int fwConfigurationDBSystemInformation_removeSystemHierarchy(string startingSystemName = "")
{
  int error = 0;
  dyn_dyn_mixed hierarchyInfo;
  
  if(fwConfigurationDBSystemInformation_getSystemHierarchy(hierarchyInfo, startingSystemName) != 0){
    DebugN("ERROR: fwInstallationDB_removeSystemHierarchy() -> Could not retrieve hierarchy from DB.");
    return -1;
  }

  //DebugN("****getSystemHierarchy returns for deletion: ", hierarchyInfo);
  
  for(int i = 1; i <= dynlen(hierarchyInfo); i++){
    error += fwConfigurationDBSystemInformation_removeChildSystem(hierarchyInfo[i][FW_CONFDB_SYSSTAT_SYSTEM_NAME_IDX]);   
  }//end of loop  
  
  error += fwConfigurationDBSystemInformation_removeChildSystem(startingSystemName);   
 
  if(error)
    return -1;
  
  return 0;
}


int fwConfigurationDBSystemInformation_getChildSystems(string parentSystem, dyn_dyn_mixed &childSystems)
{
  int parentId;
  dyn_string exceptionInfo;
  dyn_dyn_mixed aRecords;
  string sql;

  dynClear(aRecords);

  if(fwInstallationDB_isSystemRegistered(parentId, parentSystem) != 0)
  {
    DebugN("ERROR: fwInstallationDB_getChildSystems() -> Could not access the DB");
    return -1;
    
  }else if(parentId == -1){
    DebugN("ERROR: fwInstallationDB_getChildSystems() -> System: " + parentSystem + " cannot be found in the DB.");
    return -1;      
  }else{
    
    //Check that what is passed as parent system is the real parent of the child system:
    sql = "select system_name, system_number, data_port, event_port, dist_port from fw_sys_stat_pvss_system where parent_system_id = " + parentId + " AND valid_until IS NULL";
       
    if(g_fwInstallationSqlDebug)
      DebugN(sql);

    if(fwInstallationDB_executeDBQuery(sql, aRecords) != 0)
    {
      DebugN("ERROR: fwInstallationDB_getChildSystems() -> Could not execute the following SQL query: " + sql);
      return -1;
    }
  }
  
  childSystems = aRecords;   
  
  return 0;
}


int fwConfigurationDBSystemInformation_getSystemHierarchy(dyn_dyn_mixed &hierarchyInfo, string startingSystemName = "")
{
//  int topSystemId;
  dyn_string exceptionInfo;
  dyn_dyn_mixed aRecords;
  string sql;
  string id;
  dyn_mixed systemInfo;
  
  dynClear(aRecords);

  //DebugN("In getSystemHierarchy: called for startingSystemName: ", startingSystemName);
  
//  if(fwInstallationDB_isSystemRegistered(topSystemId, topSystem) != 0)
//  {
//    DebugN("ERROR: fwInstallationDB_getChildSystems() -> Could not access the DB");
//    return -1;
//    
//  }else if(topSystemId == -1){
//    DebugN("ERROR: fwInstallationDB_getChildSystems() -> System: " + parentSystem + " cannot be found in the DB.");
//    return -1;      
//  }else{
    
    //Check that what is passed as parent system is the real parent of the child system:
    //sql = "select system_name, system_number, id, parent_system_id from fw_sys_stat_pvss_system start with id = " + topSystemId + " connect by prior id = parent_system_id AND valid_until IS NULL";
  if(startingSystemName == "") {
/*    
    //find root id:
    sql = "select system_name, system_number, id, parent_system_id, level from fw_sys_stat_pvss_system where connect_by_isleaf = 0" + 
          " start with parent_system_id is null connect by prior id = parent_system_id order by level, system_name"; 

DebugN("sql 1: ", sql);

    if(fwInstallationDB_executeDBQuery(sql, aRecords) != 0)
    {
      DebugN("ERROR: fwInstallationDB_getChildSystems() -> Could not execute the following SQL query: " + sql);
      return -1;
    }
      
    if(dynlen(aRecords) > 0){
      hierarchyInfo[1] = aRecords[1];
      //DebugN("Root system: ", hierarchyInfo);
    }else
    {
      //Hierarchy not yet defined
      return 0;
    }
      
    dynClear(aRecords);
*/    
    sql = "select system_name, system_number, id, parent_system_id, level from fw_sys_stat_pvss_system " + 
          "where valid_until is null "+
          "start with parent_system_id  is NULL connect by prior id = parent_system_id order by level, system_name";
  //          "start with parent_system_id  = " + hierarchyInfo[1][3] + " connect by prior id = parent_system_id order by level, system_name";
    
  }
  else
  {
    if(fwInstallationDB_isSystemRegistered(id, startingSystemName) != 0)
    {
      DebugN("ERROR: fwInstallationDB_getChildSystems() -> Could not access the DB");
      return -1;      
    }else if(id == -1){
      DebugN("ERROR: fwInstallationDB_getChildSystems() -> System: " + startingSystemName + " cannot be found in the DB.");
      return -1;      
    }else{
      fwInstallationDB_getPvssSystemProperties(startingSystemName, systemInfo);
      //DebugN("appending ", systemInfo);
      hierarchyInfo[1] = systemInfo;
      
      //sql = "select system_name, system_number, id, parent_system_id from fw_sys_stat_pvss_system " +
      //      "where valid_until is null " + 
      //      "start with id IN (select id from fw_sys_stat_pvss_system where valid_until is null and system_name = \'" + startingSystemName + "\')connect by prior id = parent_system_id ORDER BY parent_id";
      sql = "select system_name, system_number, id, parent_system_id from fw_sys_stat_pvss_system " + 
            "where valid_until is null "+
            "start with parent_system_id = " + id + " connect by prior id = parent_system_id order by system_name";
      
    }
  }

  if(g_fwInstallationSqlDebug)
      DebugN(sql);

  if(fwInstallationDB_executeDBQuery(sql, aRecords) != 0)
  {
    DebugN("ERROR: fwInstallationDB_getChildSystems() -> Could not execute the following SQL query: " + sql);
    return -1;
  }

  hierarchyInfo = aRecords;
  
//  if(startingSystemName == ""){
//    for(int i = 1; i <= dynlen(aRecords); i++)
//      hierarchyInfo[i+1] = aRecords[i];
//  }else{
//    hierarchyInfo = aRecords;
//  }
  
  //DebugN("hierarchyInfo: ", hierarchyInfo);
  
  return 0;
}

int fwConfigurationDBSystemInformation_getOrphanSystems(dyn_dyn_mixed &hierarchyInfo)
{
  dyn_string exceptionInfo;
  dyn_dyn_mixed aRecords;
  string sql;
  dyn_mixed systemInfo;
  
  dynClear(aRecords);

  sql = "select system_name, system_number, id from fw_sys_stat_pvss_system " + 
          "where valid_until is null and parent_system_id is null " + 
          "and id not in (select parent_system_id from fw_sys_stat_pvss_system " + 
                          "where parent_system_id is not null and valid_until is null)";

  if(g_fwInstallationSqlDebug)
      DebugN(sql);

  if(fwInstallationDB_executeDBQuery(sql, aRecords) != 0)
  {
    DebugN("ERROR: fwInstallationDB_getChildSystems() -> Could not execute the following SQL query: " + sql);
    return -1;
  }

  hierarchyInfo = aRecords;
  
  return 0;
}


fwConfigurationDBSystemInformation_updateComponentTable(string groupName)
{
  dyn_dyn_mixed componentsInfo;
  
  if(fwInstallationDB_getGroupComponents(groupName, componentsInfo) != 0){
     ChildPanelOnCentral("vision/MessageInfo1", "ERROR", makeDynString ("$1:Could not connect to DB. Check connection parameters")); 
     return;
  }else{
     tbGroupComponents.deleteAllLines();
          
     for(int i = 1; i <= dynlen(componentsInfo); i++) {
       //setValue("tbGroupComponents", "appendLine", "component", componentsInfo[i][FW_INSTALLATION_DB_COMPONENT_NAME_IDX], "version", componentsInfo[i][FW_INSTALLATION_DB_COMPONENT_NAME_IDX], "sourcePath", componentsInfo[i][FW_INSTALLATION_DB_COMPONENT_SOURCE_DIR_IDX]);
       //DebugN("***", ShowSubComponents.state(0), componentsInfo[i][FW_INSTALLATION_DB_COMPONENT_SUBCOMP_IDX]);
       
       if(ShowSubComponents.state(0))
         setValue("tbGroupComponents", "appendLine", "component", componentsInfo[i][FW_INSTALLATION_DB_COMPONENT_NAME_IDX], "version", componentsInfo[i][FW_INSTALLATION_DB_COMPONENT_VERSION_IDX], "descFile", componentsInfo[i][FW_INSTALLATION_DB_COMPONENT_DESC_FILE_IDX]);
       else{
         if(componentsInfo[i][FW_INSTALLATION_DB_COMPONENT_SUBCOMP_IDX] == 0)
           setValue("tbGroupComponents", "appendLine", "component", componentsInfo[i][FW_INSTALLATION_DB_COMPONENT_NAME_IDX], "version", componentsInfo[i][FW_INSTALLATION_DB_COMPONENT_VERSION_IDX], "descFile", componentsInfo[i][FW_INSTALLATION_DB_COMPONENT_DESC_FILE_IDX]);
       }
     }//end of loop
  }  
}

//Groups: Functions moved from fwInstallationDB.ctl

int fwInstallationDB_unregisterProjectGroup(string groupName, string projectName = "", string computerName = "")
{
  int projectGroup_id;
  dyn_string exceptionInfo;
  dyn_dyn_mixed aRecords;
  string sql;

  int project_id;
  int group_id;
          
  dynClear(aRecords);

  if(projectName == "")
    projectName = PROJ;
  
  if(computerName == "")
    computerName = getHostname();
  
  if(fwInstallationDB_isGroupInProjectRegistered(groupName, projectGroup_id, group_id, project_id, projectName, computerName) != 0)
  {
    DebugN("ERROR: fwInstallationDB_unregisterProjectGroup() -> Could not retrieve project group information from DB");
    return -1;
    
  }else if(projectGroup_id == -1){
    DebugN("INFO: fwInstallationDB_unregisterProjectGroup() -> Group: " + groupName + " not registered in project: " + projectName + " computer: " + computerName + ". Nothing to be done.");
    return 0;      
    }else{
      //DebugN("Unregistering project group = " + groupName + ", which has an ID = " + projectGroup_id);
 
       sql = "UPDATE fw_sys_stat_project_groups SET valid_until = SYSDATE WHERE id = " + projectGroup_id;
         
       if(g_fwInstallationSqlDebug)
         DebugN(sql);
  
       if(rdbExecuteSqlStatement(gFwInstallationDBConn, sql)) {DebugN("ERROR: fwInstallationDB_unregisterProjectGroup() -> Could not execute the following SQL: " + sql); return -1;};

    }  
  
    
  return 0;
}

int fwInstallationDBSystemInformation_unregisterAllGroupComponents(string group)
{
  int err = 0;
  dyn_dyn_mixed componentsInfo;
  
  if(fwInstallationDB_getGroupComponents(group, componentsInfo) != 0)
  {
    DebugN("ERROR: fwInstllationDB_unregisterAllGroupComponents() -> Could not retrieve list of components of group: ", group);
    return -1;
  }
  
  for(int i = 1; i <= dynlen(componentsInfo); i++)
  {
    if(fwInstallationDB_unregisterGroupComponent(componentsInfo[i][FW_INSTALLATION_DB_COMPONENT_NAME_IDX], componentsInfo[i][FW_INSTALLATION_DB_COMPONENT_VERSION_IDX], group) != 0)
    {
      DebugN("ERROR: fwInstllationDB_unregisterAllGroupComponents() -> Could not unregister component " + compnentsInfo[i][FW_INSTALLATION_DB_COMPONENT_NAME_IDX] + " v" + componentsInfo[i][FW_INSTALLATION_DB_COMPONENT_VERSION_IDX] + " from group: ", group);
      ++err;
    }
  }
  
  return err;
}

int fwInstallationDB_unregisterGroupComponent(string componentName, string componentVersion, string groupName, bool commit = true)
{
  int groupComponent_id;
  dyn_string exceptionInfo;
  dyn_dyn_mixed aRecords;
  string sql;

  int project_id;
  int group_id;
  int component_id;
  bool isRegistered;
            
  dynClear(aRecords);


  if(fwInstallationDB_isComponentInGroupRegistered(componentName, componentVersion, groupName, isRegistered, component_id, group_id) != 0)
  {
    DebugN("ERROR: fwInstallationDB_unregisterGroupComponent() -> Could not retrieve project component group information from DB");
    return -1;
    
  }else if(!isRegistered){
    DebugN("INFO: fwInstallationDB_unregisterGroupComponent() -> Component: " + componentName + " v." + componentVersion + " Group: " + groupName + " not registered. Nothing to be done.");
    return 0;      
  }else{
     
     sql = "UPDATE fw_sys_stat_comp_in_groups SET valid_until = SYSDATE WHERE fw_component_id = " + component_id + " AND group_id = " + group_id + " AND valid_until IS NULL";
         
     if(g_fwInstallationSqlDebug)
       DebugN(sql);
     
     if(commit)
     {
       if(rdbExecuteSqlStatement(gFwInstallationDBConn, sql)) {DebugN("ERROR: fwInstallationDB_unregisterGroupComponent() -> Could not execute the following SQL: " + sql); return -1;};
     }
     else
     {
        if(fwInstallationDB_executeTransaction(sql)!=0) {DebugN("ERROR: fwInstallationDB_unregisterGroupComponent() -> Could not execute the following SQL transaction: " + sql); return -1;};
     }
   
   }      
  return 0;
}

int fwInstallationDB_deleteGroup(string groupName)
{
  int group_id;
  dyn_string exceptionInfo;
  string sql;

  //Delete all components from the group first
  sql = "DELETE FROM FW_SYS_STAT_COMP_IN_GROUPS WHERE GROUP_ID = (SELECT ID FROM FW_SYS_STAT_GROUP_OF_COMP WHERE NAME = \'"+groupName+"\')";
         
  if(g_fwInstallationSqlDebug)
    DebugN(sql);
     
  if(rdbExecuteSqlStatement(gFwInstallationDBConn, sql)) {DebugN("ERROR: fwInstallationDB_deleteGroup() -> Could not execute the following SQL: " + sql); return -1;};

  //Delete now the group itself:
  sql = "DELETE FROM FW_SYS_STAT_GROUP_OF_COMP WHERE NAME = \'" + groupName + "\'";
         
  if(g_fwInstallationSqlDebug)
    DebugN(sql);
     
  if(rdbExecuteSqlStatement(gFwInstallationDBConn, sql)) {DebugN("ERROR: fwInstallationDB_deleteGroup() -> Could not execute the following SQL: " + sql); return -1;};

  return 0;
}


int fwInstallationDB_getGroupComponents(string groupName, dyn_dyn_mixed &componentsInfo)
{
  int group_id;
  dyn_string exceptionInfo;
  string sql;
  dyn_dyn_mixed aRecords;
  
  dynClear(exceptionInfo);
  dynClear(aRecords);  
    
  if(fwInstallationDB_isGroupRegistered(groupName, group_id) == 0){
    if(group_id == -1){
      DebugN("ERROR: fwInstallationDB_getProjectGroups() - > Group: "+ groupName + " is not registered in DB.");
      return -1;      
    }else{    
      
      sql = "SELECT c.component_name, c.component_version, c.is_subcomponent, gc.description_file FROM fw_sys_stat_component c, fw_sys_stat_comp_in_groups gc WHERE c.valid_until IS NULL AND c.id IN (SELECT fw_component_id FROM fw_sys_stat_comp_in_groups WHERE group_id = " + group_id + "AND valid_until IS NULL) AND c.id = gc.fw_component_id AND gc.valid_until IS NULL AND group_id = " + group_id;
       
      if(g_fwInstallationSqlDebug)
        DebugN(sql);

      if(fwInstallationDB_executeDBQuery(sql, aRecords) != 0)
      {
        DebugN("ERROR: fwInstallation_getGroupComponents() -> Could not execute the following SQL query: " + sql);
        return -1;
      }  
      
      componentsInfo = aRecords;

    }  
  }else{
    DebugN("ERROR: fwInstallationDB_getGroupComponents() - > Cannot access the DB.");
    return -1;
  }
  
  return 0;
  
}

int fwInstallationDB_getGroupACDomain(string groupName, string &acdomain)
{
  int group_id;
  dyn_string exceptionInfo;
  string sql;
  dyn_dyn_mixed aRecords;
  
  dynClear(exceptionInfo);
  dynClear(aRecords);  
    
  if(fwInstallationDB_isGroupRegistered(groupName, group_id) == 0){
    if(group_id == -1){
      DebugN("ERROR: fwInstallationDB_getGroupACDomain() - > Group: "+ groupName + " is not registered in DB.");
      return -1;      
    }else{    
      
      sql = "SELECT acdomain FROM fw_sys_stat_group_of_comp WHERE id = " + group_id;
       
      if(g_fwInstallationSqlDebug)
        DebugN(sql);

      if(fwInstallationDB_executeDBQuery(sql, aRecords) != 0)
      {
        DebugN("ERROR: fwInstallationDB_getGroupACDomain() -> Could not execute the following SQL query: " + sql);
        return -1;
      }  
      
      acdomain = aRecords[1][1];

    }  
  }else{
    DebugN("ERROR: fwInstallationDB_getGroupACDomain() - > Cannot access the DB.");
    return -1;
  }
  
  return 0;
  
}


int fwInstallationDB_setGroupACDomain(string groupName, string acdomain, bool commit = true)
{
  dyn_string exceptionInfo;
  dyn_dyn_mixed aRecords;
  string sql;

  int group_id;
  

  if(fwInstallationDB_isGroupRegistered(groupName, group_id) != 0)
  {
    DebugN("ERROR: fwInstallationDB_setGroupACDomain() - > Group: "+ groupName + " is not registered in DB.");
    return -1;
    
  }else{
     
     sql = "UPDATE fw_sys_stat_group_of_comp SET acdomain = '" + acdomain + "' WHERE id = " + group_id;
         
     if(g_fwInstallationSqlDebug)
       DebugN(sql);

     if(commit)
     {
       if(rdbExecuteSqlStatement(gFwInstallationDBConn, sql)) {DebugN("ERROR: fwInstallationDB_setGroupACDomain() -> Could not execute the following SQL: " + sql); return -1;};
     }
     else
     {
        if(fwInstallationDB_executeTransaction(sql)!=0) {DebugN("ERROR: fwInstallationDB_setGroupACDomain() -> Could not execute the following SQL transaction: " + sql); return -1;};
     }
   
   }      
  return 0;
}


int fwInstallationDB_getProjectGroups(dyn_string &groupNames, dyn_int &groupIds, bool onlyActive = true, string projectName = "", string computerName = "")
{
  int project_id;
  dyn_string exceptionInfo;
  string sql;
  dyn_dyn_mixed aRecords;
  
  dynClear(exceptionInfo);
  dynClear(aRecords);  
  dynClear(groupNames);
  dynClear(groupIds);
  
  if(projectName == "")
    projectName = PROJ;
  
  if(computerName == "")
    computerName = getHostname();
  
  if(fwInstallationDB_isProjectRegistered(project_id, projectName, computerName) == 0){
    if(project_id == -1){
      DebugN("ERROR: fwInstalltionDB_getProjectGroups() - > Project: "+ projectName + " in computer: " + " Computer: " + computerName + " is not registered in DB.");
      return -1;      
    }else{

      if(onlyActive)
       sql = "SELECT g.name, pg.group_id FROM fw_sys_stat_group_of_comp g, fw_sys_stat_project_groups pg " + 
              "WHERE g.id = pg.group_id AND pg.project_id = " + project_id + " AND valid_until IS NULL";
      else  
       sql = "SELECT g.name, pg.group_id FROM fw_sys_stat_group_of_comp g, fw_sys_stat_project_groups pg " + 
              "WHERE g.id = pg.group_id AND pg.project_id = " + project_id;
       
       if(g_fwInstallationSqlDebug)
         DebugN(sql);
  
       if(fwInstallationDB_executeDBQuery(sql, aRecords) != 0)
       {
         DebugN("ERROR: fwInstallationDB_projectGroups() -> Could not execute the following SQL query: " + sql);
         return -1;
       }  

       for(int i = 1; i <= dynlen(aRecords); i++) {   
         
         dynAppend(groupNames, aRecords[i][1]);
         dynAppend(groupIds, aRecords[i][2]);
       }
    }  
  }else{
    DebugN("ERROR: fwInstalltionDB_getProjectGroups() - > Cannot access the DB.");
    return -1;
  }
  
  return 0;
}

int fwInstallationDB_getComponentGroups(dyn_string &groupNames)
{
  dyn_string exceptionInfo;
  string sql;
  dyn_dyn_mixed aRecords;
  
  dynClear(exceptionInfo);
  dynClear(aRecords);  
  dynClear(groupNames);  
  
  sql = "SELECT name FROM fw_sys_stat_group_of_comp";
           
  if(g_fwInstallationSqlDebug)
      DebugN(sql);
  
  if(fwInstallationDB_executeDBQuery(sql, aRecords) != 0)
  {
      DebugN("ERROR: fwInstallation_getComponentGroups() -> Could not execute the following SQL query: " + sql);
      return -1;
  }  

  for(int i = 1; i <= dynlen(aRecords); i++) {          
     dynAppend(groupNames, aRecords[i][1]);
  }
  
  return 0;
}

int fwInstallationDB_getComponentGroupsAndDomains(dyn_string &groupNames, dyn_string& acDomains)
{
  dyn_string exceptionInfo;
  string sql;
  dyn_dyn_mixed aRecords;
  
  dynClear(exceptionInfo);
  dynClear(aRecords);  
  dynClear(groupNames);  
  dynClear(acDomains);    

  sql = "SELECT name, acdomain FROM fw_sys_stat_group_of_comp";
           
  if(g_fwInstallationSqlDebug)
      DebugN(sql);
  
  if(fwInstallationDB_executeDBQuery(sql, aRecords) != 0)
  {
      DebugN("ERROR: fwInstallation_getComponentGroups() -> Could not execute the following SQL query: " + sql);
      return -1;
  }  

  for(int i = 1; i <= dynlen(aRecords); i++) {          
     dynAppend(groupNames, aRecords[i][1]);
     dynAppend(acDomains, aRecords[i][2]);     
  }
  
  return 0;
}

int fwInstallationDB_getProjectComponentGroups(string project, string computer, dyn_string &groupNames)
{
  dyn_string exceptionInfo;
  string sql;
  dyn_dyn_mixed aRecords;
  
  dynClear(exceptionInfo);
  dynClear(aRecords);  
  dynClear(groupNames);  
  

  dyn_mixed var;
  var[1] = project;
  var[2] = computer;
  
  sql = "select name from fw_sys_stat_group_of_comp " + 
        "where id in (select group_id from fw_sys_stat_project_groups where valid_until is null and project_id = (select id from fw_sys_stat_pvss_project where project_name = :1 and " +
        "id in (select project_id from fw_sys_stat_pvss_project where VALID_UNTIL IS NULL AND (computer_id = " + 
        "(select id from fw_sys_stat_computer where hostname = :2 and valid_until is null) or redu_computer_id = (select id from fw_sys_stat_computer where hostname = :2 and valid_until is null)))))";
           
  if(g_fwInstallationSqlDebug)
      DebugN(sql);
  
//  if(fwInstallationDB_executeDBQuery(sql, aRecords) != 0)
  if(fwInstallationDB_executeQuery(sql, var, aRecords))
  {
      DebugN("ERROR: fwInstallation_getComponentGroups() -> Could not execute the following SQL query: " + sql);
      return -1;
  }  

  for(int i = 1; i <= dynlen(aRecords); i++) {          
     dynAppend(groupNames, aRecords[i][1]);
  }
  
  return 0;
}

int fwInstallationDB_getHostComponentGroups(string computer, dyn_string &groupNames)
{
  dyn_string exceptionInfo;
  string sql;
  dyn_dyn_mixed aRecords;
  
  dynClear(exceptionInfo);
  dynClear(aRecords);  
  dynClear(groupNames);  
  

  dyn_mixed var;
  var[1] = computer;
  
  sql = "select name " +
        "from fw_sys_stat_group_of_comp " +
        "where id in (select group_id " +
			 "from fw_sys_stat_project_groups " +
			 "where valid_until is null and " + 
			 	"project_id IN (select id from fw_sys_stat_pvss_project " +
			 	              "where VALID_UNTIL IS NULL " + 
			 	              	"AND (computer_id = (select id from fw_sys_stat_computer where hostname = :1 and valid_until is null) " +
			 	                					"or redu_computer_id = (select id from fw_sys_stat_computer where hostname = :1 and valid_until is null))))";
           
  if(g_fwInstallationSqlDebug)
      DebugN(sql);
  
//  if(fwInstallationDB_executeDBQuery(sql, aRecords) != 0)
  if(fwInstallationDB_executeQuery(sql, var, aRecords))
  {
      DebugN("ERROR: fwInstallation_getComponentGroups() -> Could not execute the following SQL query: " + sql);
      return -1;
  }  

  for(int i = 1; i <= dynlen(aRecords); i++) {          
     dynAppend(groupNames, aRecords[i][1]);
  }
  
  return 0;
}


int fwInstallationDB_isGroupRegistered(string group, int &id)
{
  dyn_string exceptionInfo;
  dyn_dyn_mixed aRecords;
  
  strreplace(group, ".", "_");
  
  string sql = "SELECT id FROM fw_sys_stat_group_of_comp WHERE name = \'" + group +"\'" ;
  
  dynClear(aRecords);
  id = -1;
      
  if(g_fwInstallationSqlDebug)
    DebugN(sql);

  if(fwInstallationDB_executeDBQuery(sql, aRecords) != 0)
  {
    DebugN("ERROR: fwInstallation_isGroupRegistered() -> Could not execute the following SQL query: " + sql);
    return -1;
  }  

  if(dynlen(aRecords) > 0) {   
    if(g_fwInstallationVerbose)
      DebugN("INFO: fwInstallationDB_isGroupRegistered() -> Group " + group + " already registered in the DB with id: ", aRecords);
      
    id = aRecords[1][1];
  }
  else{
    if(g_fwInstallationVerbose)
      DebugN("INFO: fwInstallationDB_isGroupRegistered() -> Group " + group + " not yet registered in the DB");
    
    id = -1;
  }
  
  return 0;
}

/*
int fwInstallationDB_getGroupProperties(string group, dyn_mixed &groupInfo)
{
  dyn_string exceptionInfo;
  string sql;
  dyn_dyn_mixed aRecords;
  
  dynClear(exceptionInfo);
  dynClear(aRecords);  

  dyn_mixed var;
  var[1] = group;  
  
  sql = "SELECT name, centrally_managed FROM FW_SYS_STAT_GROUP_OF_COMP WHERE name = :1";
       
  if(g_fwInstallationSqlDebug)
    DebugN(sql);

//  if(fwInstallationDB_executeDBQuery(sql, aRecords) != 0)
  if(fwInstallationDB_executeQuery(sql, var, aRecords))
  {
    fwInstallation_throw("ERROR: fwInstallationDB_getGroupProperties() -> Could not execute the following SQL query: " + sql);
    return -1;
  }

  
  if(dynlen(aRecords) > 0) {   
    groupInfo = aRecords[1];
  }
  
  return 0;
}
*/

int fwInstallationDB_registerGroup(string group, string acdomain="")
{
  string sql;
    
  dyn_string exceptionInfo;
  dyn_dyn_mixed aRecords;
  int id;
  
  dynClear(exceptionInfo);
  
  strreplace(group, ".", "_");

  //Check if already exists:
  if(fwInstallationDB_isGroupRegistered(group, id) == 0 && id == -1){

    if(g_fwInstallationVerbose)
      DebugN("INFO: fwInstallationDB_registerGroup() -> Group: " + group + " not yet registered in the DB. Proceeding with registration now...");  

    sql = "INSERT INTO fw_sys_stat_group_of_comp(id, name, acdomain) VALUES ((fw_sys_stat_group_of_comp_sq.NEXTVAL), \'" + group + "\','" +acdomain + "\')";
         
    if(g_fwInstallationSqlDebug)
      DebugN(sql);

    if(rdbExecuteSqlStatement(gFwInstallationDBConn, sql)) {DebugN("ERROR: fwInstallationDB_registerProject() -> Could not execute the following SQL: " + sql); return -1;}; 
  
  }

  return 0;  
}

/*
int fwInstallationDB_setGroupProperties(dyn_mixed groupProperties)
{
  string sql;
    
  dyn_string exceptionInfo;
  dyn_dyn_mixed aRecords;
  int id;

  string group = groupProperties[1];
  int centrallyManaged = groupProperties[2];
    
  dynClear(exceptionInfo);
  
  strreplace(group, ".", "_");
  sql = "UPDATE fw_sys_stat_group_of_comp SET centrally_managed = " + centrallyManaged + " WHERE name = \'" + group + "\'";
         
  if(g_fwInstallationSqlDebug)
    DebugN(sql);

  if(rdbExecuteSqlStatement(gFwInstallationDBConn, sql)) {DebugN("ERROR: fwInstallationDB_registerProject() -> Could not execute the following SQL: " + sql); return -1;}; 

  return 0;  
}
*/

int fwInstallationDB_isComponentInGroupRegistered(string componentName, string componentVersion, string groupName, bool &isRegistered, int &component_id, int &group_id)
{

  dyn_string exceptionInfo;
  dyn_dyn_mixed aRecords;
  string sql;

  dynClear(aRecords);
  isRegistered = false;
  
  if(fwInstallationDB_isComponentRegistered(componentName, componentVersion, component_id) != 0)
  { 
    Debug("ERROR: fwInstallationDB_isComponentInGroupRegistered() -> Cannot talk to DB. Check DB connection parameters");
    return -1;
  }else if(component_id != -1){
    if(fwInstallationDB_isGroupRegistered(groupName, group_id) == 0 && group_id != -1)
    {
 
      sql = "SELECT fw_component_id FROM fw_sys_stat_comp_in_groups WHERE fw_component_id = " + component_id + " AND group_id = " + group_id + " AND valid_until IS NULL";      
      if(g_fwInstallationSqlDebug)
        DebugN(sql);

     if(fwInstallationDB_executeDBQuery(sql, aRecords) != 0)
     {
       DebugN("ERROR: fwInstallation_isComponentInGroupRegistered() -> Could not execute the following SQL query: " + sql);
       return -1;
      }  

      if(dynlen(aRecords) > 0) {   
        if(g_fwInstallationVerbose)
          DebugN("INFO: fwInstallationDB_isComponentInGroupRegistered() -> Component "+ componentName + " v." + componentVersion + " is alaready registered in group " + groupName);

        isRegistered = true;

      }
    }else{    
      DebugN("ERROR: fwInstallationDB_isComponentInGroupRegistered() -> Group "+ groupName + " not registered in group DB");
      isRegistered = false;
      return 0;
    }
  }else{
    if(g_fwInstallationVerbose)
      DebugN("WARNING: fwInstallationDB_isComponentInGroupRegistered() -> Component "+ componentName + " v." + componentVersion + " not registered in group DB");
    isRegistered = false;
    return 0;
  }
    
  return 0;
}


int fwInstallationDB_registerComponentInGroup(string componentName, string componentVersion, int isSubComponent, string descFile, string groupName, bool commit = true)
{

  dyn_string exceptionInfo;
  dyn_dyn_mixed aRecords;
  string sql;

  int group_id;
  int component_id;
  bool isRegistered = false;

//  DebugN("fwConfDBSystem lib, registerComponentInGroup: ", componentName, componentVersion, isSubComponent, descFile, groupName);
            
  dynClear(aRecords);
  
  if(fwInstallationDB_isComponentInGroupRegistered(componentName, componentVersion, groupName, isRegistered, component_id, group_id) == 0)
  {
    if(isRegistered)
    {
      if(g_fwInstallationVerbose)
        DebugN("INFO: fwInstallationDB_registerComponentInGroup() -> Component: " + componentName + " v." + componentVersion + " already registered in group " + groupName + ". Nothing to be done...");      
        
      return 0;
    }
      
    if(g_fwInstallationVerbose){
      DebugN("INFO: fwInstallationDB_registerComponentInGroup() -> Component: " + componentName + " v." + componentVersion + " not yet registered in group " + groupName + ". Registering now...");
    }
    
    if(fwInstallationDB_isComponentRegistered(componentName, componentVersion, component_id) == 0 && component_id == -1)
    {
      if(g_fwInstallationVerbose){
        DebugN("INFO: fwInstallationDB_registerComponentInGroup() -> Component: " + componentName + " v." + componentVersion + " not yet registered in DB. Registering now...");
      }

      //DebugN("fwConfDBSystem lib, registering compoent firts: ", componentName, componentVersion, isSubComponent);

      if(fwInstallationDB_registerComponent(componentName, componentVersion, isSubComponent) != 0){
        DebugN("ERROR: fwInstallationDB_registerComponentInGroup() -> Could not register component " + componentName + " v. " + componentVersion + " in DB.");
        return -1;
      }
      else 
        fwInstallationDB_isComponentRegistered(componentName, componentVersion, component_id);
        
    }
      
    if(fwInstallationDB_isGroupRegistered(groupName, group_id) == 0 && group_id == -1)
    {
      if(g_fwInstallationVerbose){
        DebugN("INFO: fwInstallationDB_registerComponentInGroup() -> Group: " + groupName);
      }

      if(fwInstallationDB_registerGroup(groupName) != 0){
        DebugN("ERROR: fwInstallationDB_registerComponentInGroup() -> Could not register group " + groupName + " in DB.");
        return -1;
      }
      else
        fwInstallationDB_isGroupRegistered(groupName, group_id);
    } 
    
    if(component_id != -1 && group_id != -1)
    {
      sql = "INSERT INTO fw_sys_stat_comp_in_groups(group_id, fw_component_id, valid_from, valid_until, description_file) VALUES(" + group_id + ", "+ component_id + ", SYSDATE, NULL, \'" + descFile + "\')";      
      if(g_fwInstallationSqlDebug)
        DebugN(sql);
  
      if(commit)
      {      
        if(rdbExecuteSqlStatement(gFwInstallationDBConn, sql)) {DebugN("ERROR: fwInstallationDB_registerProject() -> Could not execute the following SQL: " + sql); return -1;};
              
      }
      else
      {
        if(fwInstallationDB_executeTransaction(sql)!=0) {DebugN("ERROR: fwInstallationDB_registerProject() -> Could not execute the following SQL transaction: " + sql); return -1;};
      }
          

    }
  }
  return 0;
}


bool fwInstallationDB_isDefaultGroup(string group)
{
  dyn_dyn_mixed componentsInfo;
  string version;
    
  fwInstallationDB_getGroupComponents(group, componentsInfo);
  
  if(dynlen(componentsInfo))
  { 
    version = componentsInfo[1][FW_INSTALLATION_DB_COMPONENT_VERSION_IDX];
    strreplace(version, ".", "_");
    if(group == componentsInfo[1][FW_INSTALLATION_DB_COMPONENT_NAME_IDX] + "_" + version)
      return true;
  }  

  return false;
}




int fwInstallationDB_registerComponentInDefaultGroup(string componentName, string componentVersion, string descFile, int isSubComponent)
{
  string groupName = componentName + "_" + componentVersion;

  return fwInstallationDB_registerComponentInGroup(componentName, componentVersion, isSubComponent, desFile, groupName);
            
}

/////////////////////
int fwInstallationDB_isGroupInProjectRegistered(string groupName, int &id, int &group_id, int &project_id, string projectName = "", string computerName = "")
{

  dyn_string exceptionInfo;
  dyn_dyn_mixed aRecords;
  string sql;

  int computer_id;
          
  dynClear(aRecords);

  if(projectName == "")
    projectName = PROJ;
  
  if(computerName == "")
    computerName = getHostname();
  
  //Check that the computer is properly registered in the DB    
  if(fwInstallationDB_isPCRegistered(computer_id, computerName) == 0)
  {    
    if(computer_id == -1){
      if(g_fwInstallationVerbose){
          DebugN("INFO: fwInstallationDB_isGroupInProjectRegistered() -> Registering computer now...");
      }
      
      fwInstallationDB_registerPC(computerName);
      fwInstallationDB_isPCRegistered(computer_id, computerName);
    }
  }else{
    DebugN("ERROR: fwInstallationDB_isGroupInProjectRegistered() -> Could not retrieve the PC info from the DB. Action aborted...");
    return -1;
  }
    
  //Check that the project is properly registered in the DB  
  if(fwInstallationDB_isProjectRegistered(project_id, projectName, computerName) == 0)
  {
    if(project_id == -1){
      if(g_fwInstallationVerbose){
          DebugN("INFO: fwInstallationDB_isGroupInProjectRegistered() -> Registering project now...");
      }
      fwInstallationDB_registerProject(projectName, computerName);
      fwInstallationDB_isProjectRegistered(project_id, projectName, computerName);
      if(project_id < 0){
        DebugN("ERROR: fwInstallationDB_isGroupInProjectRegistered() -> Could noregister project:"+projectName,+" computer:" +computerName+" in DB. Action aborted...");
        return -1;
      }
    }
  }else{
    DebugN("ERROR: fwInstallationDB_isGroupInProjectRegistered() -> Could not retrieve the project info from the DB. Action aborted...");
    return -1;
  }

  //Check that the project is group is properly registered in the DB  
  if(fwInstallationDB_isGroupRegistered(groupName, group_id) == 0)
  {
    if(group_id == -1){
      if(g_fwInstallationVerbose){
        DebugN("INFO: fwInstallationDB_isGroupInProjectRegistered() -> Registering group now...");
      }
      fwInstallationDB_registerGroup(groupName);
      fwInstallationDB_isGroupRegistered(groupName, group_id);
    }
  }else{
    DebugN("ERROR: fwInstallationDB_isGroupInProjectRegistered() -> Could not retrieve the group info from the DB. Action aborted...");
    return -1;
  }

  
  if(computer_id != -1 && project_id != -1 && group_id != -1)
  {
    sql = "SELECT id FROM fw_sys_stat_project_groups WHERE project_id = " + project_id + " AND group_id = " + group_id + " AND valid_until IS NULL";      
    if(g_fwInstallationSqlDebug)
      DebugN(sql);

   if(fwInstallationDB_executeDBQuery(sql, aRecords) != 0)
   {
     DebugN("ERROR: fwInstallation_isGroupInProjectRegistered() -> Could not execute the following SQL query: " + sql);
     return -1;
   }  

    if(dynlen(aRecords) > 0) {   
      if(g_fwInstallationVerbose){
        DebugN("INFO: fwInstallationDB_isGroupInProjectRegistered() -> Group "+ groupName + " already registered in project" + projectName + " in computer " + computerName);
      }

      id = aRecords[1][1];        
      }else 
        id = -1;
    }
    
  return 0;
}



int fwInstallationDB_registerGroupInProject(string groupName, int overwriteFiles = 0, int forceRequired = 1, int isSilent = 0, int restartProject = 1, string scheduledInstDate = "", string projectName = "", string computerName = "")
{

  dyn_string exceptionInfo;
  dyn_dyn_mixed aRecords;
  string sql;
  string requestedBy = getUserName();      //To handle FW usernames
  string requestDate = getCurrentTime();
  int project_group_id;
  int group_id;
  int project_id;
  bool registerComponents = false;
  dyn_string components;
  dyn_string versions;
  int component_id;
  dyn_bool isSubComponents;
  dyn_string descFiles;
  int error = 0;
  dyn_dyn_mixed componentsInfo;
             
  dynClear(aRecords);

  if(projectName == ""){
    projectName = PROJ;
    registerComponents = true;
  }

  if(computerName == "")
    computerName = getHostname();

  if(scheduledInstDate == "")
    scheduledInstDate = getCurrentTime();
  
  if(fwInstallationDB_isGroupInProjectRegistered(groupName, project_group_id, group_id, project_id, projectName, computerName) == 0 && group_id != -1 && project_id != -1)
  {
    
    if( project_group_id == -1){
 
      //sql = "INSERT INTO fw_sys_stat_project_groups VALUES((fw_sys_stat_project_groups_sq.NEXTVAL), " + group_id + ", "+ project_id + ", \'" + requestedBy + "\', to_date(" + requestDate + "), "+ overwriteFiles + ", " + forceRequired + ", " + isSilent + ", to_date(" + scheduledInstDate + "))";      
      sql = "INSERT INTO fw_sys_stat_project_groups(id, group_id, project_id, requested_by, request_date, overwrite_files, force_required, is_silent, restart_project, scheduled_inst_date, valid_until) VALUES((fw_sys_stat_project_groups_sq.NEXTVAL), " + group_id + ", "+ project_id + ", \'" + requestedBy + "\', SYSDATE, "+ overwriteFiles + ", " + forceRequired + ", " + isSilent + ", " + restartProject + ", NULL, NULL)";      

      if(g_fwInstallationSqlDebug)
      DebugN(sql);
  
      if(rdbExecuteSqlStatement(gFwInstallationDBConn, sql)) {DebugN("ERROR: fwInstallationDB_registerProject() -> Could not execute the following SQL: " + sql); return -1;};
      
      if(registerComponents){
        fwInstallationDB_getGroupComponents(groupName, componentsInfo);
        for(int i = 1; i <= dynlen(componentsInfo); i++)
        {

            //Register component in group.
            if(fwInstallationDB_registerComponentInGroup(componentsInfo[i][FW_INSTALLATION_DB_COMPONENT_NAME_IDX], 
                                                         componentsInfo[i][FW_INSTALLATION_DB_COMPONENT_VERSION_IDX], 
                                                         componentsInfo[i][FW_INSTALLATION_DB_COMPONENT_SUBCOMP_IDX],
                                                         componentsInfo[i][FW_INSTALLATION_DB_COMPONENT_DESC_FILE_IDX],
                                                         groupName) != 0)
            {
              DebugN("ERROR: fwInstallationDB_registerGroupInProject() -> Failed to register component " + componentsInfo[i][FW_INSTALLATION_DB_COMPONENT_NAME_IDX] + " v." + componentsInfo[i][FW_INSTALLATION_DB_COMPONENT_VERSION_IDX] + " in group " + groupName); 
              ++error;
            }
//          }
        }//end of loop
      }
      
  
    }else{
      if(g_fwInstallationVerbose)
        DebugN("INFO: fwInstallationDB_registerGroupInProject() -> Group is already registered for this project");
      
      return 0;        
       
    }
  }
  else{
    DebugN("ERROR: fwInstallationDB_registerGroupInProject() -> Cannot talk to DB or either group or project are not properly registered in the DB");
    return -1;
  }
  if(error)
    return -1;
  else
    return 0;
}

int fwInstallationDB_getComponentProjectGroup(string component, string version, dyn_string &componentGroups, string projectName = "", string computerName = "")
{
  int project_id, component_id;
  dyn_string exceptionInfo;
  string sql;
  
  
  dynClear(exceptionInfo);
  
  if(projectName == "")
    projectName = PROJ;
  
  if(computerName == "")
    computerName = getHostname();
  
  if(fwInstallationDB_isProjectRegistered(project_id, projectName, computerName) != 0){
    DebugN("ERROR: fwInstallationDB_getComponentProjectGroup() - > Cannot access the DB.");
    return -1;
  }
  
  if(project_id == -1){
      DebugN("ERROR: fwInstallationDB_getComponentProjectGroup() - > Project: "+ projectName + " in computer: " + " Computer: " + computerName + " is not registered in DB.");
      return -1;      
  }
  
  if(fwInstallationDB_isComponentRegistered(component, version, component_id) != 0){
    DebugN("ERROR: fwInstallationDB_getComponentProjectGroup() - > Cannot access the DB.");
    return -1;
  }
  
  if(component_id == -1){
      DebugN("ERROR: fwInstallationDB_getComponentProjectGroup() - > Component: " + component + " v." + version + " is not registered in DB.");
      return -1;      
  }
  
  sql = "SELECT name FROM fw_sys_stat_group_of_comp WHERE id IN " + 
            "(SELECT group_id FROM fw_sys_stat_comp_in_groups WHERE fw_component_id = " + component_id + ") " + 
          "AND id IN " +
            "(SELECT group_ID FROM fw_sys_stat_project_groups WHERE project_id = "+ project_id +")";
       
  if(g_fwInstallationSqlDebug)
    DebugN(sql);
  
  if(fwInstallationDB_executeDBQuery(sql, componentGroups) != 0)
  {
    DebugN("ERROR: fwInstallationDB_getComponentProjectGroup() - > Could not execute the following SQL query: " + sql);
    return -1;
  }    
  return 0;
}

int fwInstallationDB_getGroupComponentXml(string component, string version, string group, string &xml)
{
  int group_id, component_id;
  dyn_string exceptionInfo;
  string sql;
  dyn_dyn_mixed aRecords;
  
  dynClear(exceptionInfo);
  
  if(fwInstallationDB_isGroupRegistered(group, group_id) != 0){
    DebugN("ERROR: fwInstallationDB_getGroupComponentXml() - > Cannot access the DB.");
    return -1;
  }
  
  if(group_id == -1){
      DebugN("ERROR: fwInstallationDB_getGroupComponentXml() - > Group: " + group + " is not registered in DB.");
      return -1;      
  }
  
  if(fwInstallationDB_isComponentRegistered(component, version, component_id) != 0){
    DebugN("ERROR: fwInstallationDB_getGroupComponentXml() - > Cannot access the DB.");
    return -1;
  }
  
  if(component_id == -1){
      DebugN("ERROR: fwInstallationDB_getGroupComponentXml() - > Component: " + component + " v." + version + " is not registered in DB.");
      return -1;      
  }
  
  sql = "SELECT description_file FROM fw_sys_stat_comp_in_groups WHERE fw_component_id = " + component_id + 
        " AND group_id = " + group_id;
       
  if(g_fwInstallationSqlDebug)
    DebugN(sql);
  
  if(fwInstallationDB_executeDBQuery(sql, aRecords) != 0)
  {
    DebugN("ERROR: fwInstallationDB_getGroupComponentXml() - > Could not execute the following SQL query: " + sql);
    return -1;
  }    
  
  if(dynlen(aRecords))
    xml = aRecords[1];
  
  return 0;
}


int fwInstallationDBSystemInformation_removeAllProjectGroups(string project, string computerName)
{
  dyn_string groups;
  dyn_int groupIds  ;
  int error = 0;
    
  if(fwInstallationDB_getProjectGroups(groups, groupIds, true, project, computerName)!=0)
  {
    DebugN("ERROR: fwInstallationDBSystemInformation_removeAllProjectGroups() -> Could not retrieve list of groups for project: " + project + " in computer: " + computerName);
    return -1;
  }
  
  for(int i = 1; i <= dynlen(groups); i++)
  {
    if(fwInstallationDB_unregisterProjectGroup(groups[i], project, computerName) != 0)
    {
      DebugN("ERROR: fwInstallationDBSystemInformation_removeAllProjectGroups() -> Could not unregister group: " + groups[i] + "from project: " + project + " in computer: " + computerName);    
      ++error;
    }
  }
  
  if(error)
    return -1;    
 
  return 0; 
}


int fwConfigurationDBSystemInformation_getGroupProjectsMode(string group,  dyn_dyn_mixed &projectsInfo, string mode = "CENTRAL")
{
  int group_id, component_id;
  dyn_string exceptionInfo;
  string sql;
  dyn_dyn_mixed aRecords;
  int centrallyManaged = 1;

  
  if(mode == "LOCAL")
    centrallyManaged = 0;
    
  dynClear(exceptionInfo);
  
  if(fwInstallationDB_isGroupRegistered(group, group_id) != 0){
    DebugN("ERROR: fwConfigurationDBSystemInformation_getGroupProjectsMode() - > Cannot access the DB.");
    return -1;
  }
  
  if(group_id == -1){
      DebugN("ERROR: fwConfigurationDBSystemInformation_getGroupProjectsMode() - > Group: " + group + " is not registered in DB.");
      return -1;      
  }
  
  sql = "SELECT C.HOSTNAME, P.PROJECT_NAME " + 
        "FROM FW_SYS_STAT_PROJECT_GROUPS PG, FW_SYS_STAT_PVSS_PROJECT P, FW_SYS_STAT_GROUP_OF_COMP G, FW_SYS_STAT_COMPUTER C  " +
        "WHERE G.ID = PG.GROUP_ID AND PG.PROJECT_ID = P.ID AND PG.VALID_UNTIL IS NULL AND (C.ID = P.COMPUTER_ID OR C.ID = REDU_COMPUTER_ID) AND P.CENTRALLY_MANAGED = " + centrallyManaged + " AND G.ID = " +  + group_id + " " +
        "ORDER BY C.HOSTNAME, P.PROJECT_NAME";
       
  if(g_fwInstallationSqlDebug)
    DebugN(sql);
  
  if(fwInstallationDB_executeDBQuery(sql, aRecords) != 0)
  {
    DebugN("ERROR: fwConfigurationDBSystemInformation_getGroupProjectsMode() - > Could not execute the following SQL query: " + sql);
    return -1;
  }    
  
  projectsInfo = aRecords;
  
  return 0;
}


int fwConfigurationDBSystemInformation_copyComponentFiles(string path, dyn_string xmls)
{
  dyn_string files;
  dyn_string failedXmls;
  int error = 0;
  string sourceDir = "";
  
  //1.- remove previous backup files
  //DebugN("Emptying trash now....", fwConfigurationDBSystemInformation_getCentralRepository());
  fwInstallation_emptyTrash(fwConfigurationDBSystemInformation_getCentralRepository());
  
  //2.- Copy now the files:  
  dynClear(failedXmls);
  
  for(int i = 1; i <= dynlen(xmls); i++) 
  {
    sourceDir = "";
    dynClear(files);
    if(fwConfigurationDBSystemInformation_getAllFiles(xmls[i], sourceDir, files))
    {
      ChildPanelOnCentral("vision/MessageInfo1", "ERROR", makeDynString("Could not load XML file:\n" + xmls[i]));
      dynAppend(failedXmls, xmls[i]);
      error = 1;
      continue;
    }
    
//    DebugN("**********", sourceDir, files);
    error = 0;
    //
    for(int j = 1; j <= dynlen(files); j++)
    {  
      if(fwInstallation_copyFile(sourceDir + "/" + files[j], path + "/" + files[j], fwConfigurationDBSystemInformation_getCentralRepository()) != 0)
      {
        DebugN("ERROR: fwConfigurationDBSystemInformation_copyComponentFiles() -> Failed to copy file: " + sourceDir + "/" +files[j]);
        ++error;
      }
    }
  }

  if(error)  
  {
    ChildPanelOnCentral("vision/MessageInfo1", "ERROR", makeDynString("There were errors copying files.\nCheck log-viewer for details"));
    return -1;
  }
}



int fwConfigurationDBSystemInformation_getAllFiles(string xml, string &sourceDir, dyn_string &files)
{
  string str;
  if(!fileToString(xml, str))
  {
    DebugN("ERROR: fwConfigurationDBSystemInformation_getAllFiles() -> Failed to load xml file: " + xml);
    return -1;
  }
  
  sourceDir = xml;
  strreplace(xml, "\\", "/");
  dyn_string ds = strsplit(xml, "/");
  strreplace(sourceDir, ds[dynlen(ds)], "");  
  
  ds = strsplit(str, "\n");
  string component = "";
  
  for(int i = 1; i <= dynlen(ds); i++)
  {
    strreplace(ds[i], " ", "");
    strreplace(ds[i], "\t", "");
      
    if(patternMatch("*<name>*", ds[i]))
    {
      component = ds[i];
      strreplace(component, "<name>", "");
      strreplace(component, "</name>", "");
    }
    else if(patternMatch("*<postInstall>*", ds[i]))
    {
      strreplace(ds[i], "<postInstall>", "");
      strreplace(ds[i], "</postInstall>", "");
      string path = _fwInstallation_baseDir(ds[i]);
      if(patternMatch("./*", path))
        path = substr(path, 2, strlen(path));
            
      path = sourceDir + path;      
      string pattern = _fwInstallation_fileName(ds[i]);
      dyn_string temp = getFileNames(path, pattern);
      for(int k = 1; k <= dynlen(temp); k++)
      {
        string str = path + "/" + temp[k];
        strreplace(str, sourceDir, "");
        dynAppend(files, str);
      }
//      dynAppend(files, ds[i]);
    }
    else if(patternMatch("*<file>*", ds[i]))
    {
      strreplace(ds[i], "<file>", "");
      strreplace(ds[i], "</file>", "");
      string path = _fwInstallation_baseDir(ds[i]);
      if(patternMatch("./*", path))
        path = substr(path, 2, strlen(path));
            
      path = sourceDir + path;      
      string pattern = _fwInstallation_fileName(ds[i]);
      dyn_string temp = getFileNames(path, pattern);
      for(int k = 1; k <= dynlen(temp); k++)
      {
        string str = path + "/" + temp[k];
        strreplace(str, sourceDir, "");
        dynAppend(files, str);
      }
      
//      dynAppend(files, ds[i]);
    }
    else if(patternMatch("*<dplist>*", ds[i]))
    {
      strreplace(ds[i], "<dplist>", "");
      strreplace(ds[i], "</dplist>", "");
      string path = _fwInstallation_baseDir(ds[i]);
      if(patternMatch("./*", path))
        path = substr(path, 2, strlen(path));
            
      path = sourceDir + path;      
      string pattern = _fwInstallation_fileName(ds[i]);
      dyn_string temp = getFileNames(path, pattern);
      for(int k = 1; k <= dynlen(temp); k++)
      {
        string str = path + "/" + temp[k];
        strreplace(str, sourceDir, "");
        dynAppend(files, str);
      }
//      dynAppend(files, ds[i]);
    }
    else if(patternMatch("*<config>*", ds[i]))
    {
      strreplace(ds[i], "<config>", "");
      strreplace(ds[i], "</config>", "");
      string path = _fwInstallation_baseDir(ds[i]);
      if(patternMatch("./*", path))
        path = substr(path, 2, strlen(path));
            
      path = sourceDir + path;      
      string pattern = _fwInstallation_fileName(ds[i]);
      dyn_string temp = getFileNames(path, pattern);
      for(int k = 1; k <= dynlen(temp); k++)
      {
        string str = path + "/" + temp[k];
        strreplace(str, sourceDir, "");
        dynAppend(files, str);
      }
      
//      dynAppend(files, ds[i]);
    }
    else if(patternMatch("*<help>*", ds[i]))
    {
      strreplace(ds[i], "<help>", "");
      strreplace(ds[i], "</help>", "");
      string path = _fwInstallation_baseDir(ds[i]);
      if(patternMatch("./*", path))
      {
        path = substr(path, 2, strlen(path));
      }     
      path = sourceDir + "help/en_US.iso88591/" + path;      
      string pattern = _fwInstallation_fileName(ds[i]);
      dyn_string temp = getFileNames(path, pattern);

      for(int k = 1; k <= dynlen(temp); k++)
      {
        string str = path + "/" + temp[k];
        strreplace(str, sourceDir, "");
        dynAppend(files, str);
      }
      
//      dynAppend(files, ds[i]);
    }
    else if(patternMatch("*<init>*", ds[i]))
    {
      strreplace(ds[i], "<init>", "");
      strreplace(ds[i], "</init>", "");
      string path = _fwInstallation_baseDir(ds[i]);
      if(patternMatch("./*", path))
        path = substr(path, 2, strlen(path));
            
      path = sourceDir + path;      
      string pattern = _fwInstallation_fileName(ds[i]);
      dyn_string temp = getFileNames(path, pattern);
      for(int k = 1; k <= dynlen(temp); k++)
      {
        string str = path + "/" + temp[k];
        strreplace(str, sourceDir, "");
        dynAppend(files, str);
      }
//      dynAppend(files, ds[i]);
    }
    else if(patternMatch("*<delete>*", ds[i]))
    {
      strreplace(ds[i], "<delete>", "");
      strreplace(ds[i], "</delete>", "");
      string path = _fwInstallation_baseDir(ds[i]);
      if(patternMatch("./*", path))
        path = substr(path, 2, strlen(path));
            
      path = sourceDir + path;      
      string pattern = _fwInstallation_fileName(ds[i]);
      dyn_string temp = getFileNames(path, pattern);
      for(int k = 1; k <= dynlen(temp); k++)
      {
        string str = path + "/" + temp[k];
        strreplace(str, sourceDir, "");
        dynAppend(files, str);
      }
//      dynAppend(files, ds[i]);
    }
    else if(patternMatch("*<postDelete>*", ds[i]))
    {
      strreplace(ds[i], "<postDelete>", "");
      strreplace(ds[i], "</postDelete>", "");
      string path = _fwInstallation_baseDir(ds[i]);
      if(patternMatch("./*", path))
        path = substr(path, 2, strlen(path));
            
      path = sourceDir + path;      
      string pattern = _fwInstallation_fileName(ds[i]);
      dyn_string temp = getFileNames(path, pattern);
      for(int k = 1; k <= dynlen(temp); k++)
      {
        string str = path + "/" + temp[k];
        strreplace(str, sourceDir, "");
        dynAppend(files, str);
      }
//      dynAppend(files, ds[i]);
    }
    else if(patternMatch("*<config_windows>*", ds[i]))
    {
      strreplace(ds[i], "<config_windows>", "");
      strreplace(ds[i], "</config_windows>", "");
      string path = _fwInstallation_baseDir(ds[i]);
      if(patternMatch("./*", path))
        path = substr(path, 2, strlen(path));
            
      path = sourceDir + path;      
      string pattern = _fwInstallation_fileName(ds[i]);
      dyn_string temp = getFileNames(path, pattern);
      for(int k = 1; k <= dynlen(temp); k++)
      {
        string str = path + "/" + temp[k];
        strreplace(str, sourceDir, "");
        dynAppend(files, str);
      }
//      dynAppend(files, ds[i]);
    }
    else if(patternMatch("*<config_linux>*", ds[i]))
    {
      strreplace(ds[i], "<config_linux>", "");
      strreplace(ds[i], "</config_linux>", "");
      string path = _fwInstallation_baseDir(ds[i]);
      if(patternMatch("./*", path))
        path = substr(path, 2, strlen(path));
            
      path = sourceDir + path;      
      string pattern = _fwInstallation_fileName(ds[i]);
      dyn_string temp = getFileNames(path, pattern);
      for(int k = 1; k <= dynlen(temp); k++)
      {
        string str = path + "/" + temp[k];
        strreplace(str, sourceDir, "");
        dynAppend(files, str);
      }
//      dynAppend(files, ds[i]);
    }
    else if(patternMatch("*<postDelete>*", ds[i]))
    {
      strreplace(ds[i], "<postDelete>", "");
      strreplace(ds[i], "</postDelete>", "");
      string path = _fwInstallation_baseDir(ds[i]);
      if(patternMatch("./*", path))
        path = substr(path, 2, strlen(path));
            
      path = sourceDir + path;      
      string pattern = _fwInstallation_fileName(ds[i]);
      dyn_string temp = getFileNames(path, pattern);
      for(int k = 1; k <= dynlen(temp); k++)
      {
        string str = path + "/" + temp[k];
        strreplace(str, sourceDir, "");
        dynAppend(files, str);
      }
    }
  }//end of loop

  return 0;
}

string fwConfigurationDBSystemInformation_getCentralRepository()
{
  string path = "";
  dpGet("fwSysStatDbEditorNavigator.centralRepository.path", path);
  
  return path;
}

int fwConfigurationDBSystemInformation_setCentralRepository(string path)
{
  //check that the path passed exists. otherwise create it
  if(access(path, F_OK))
  {
    //directory does not exist, try to create it now:
    if(!mkdir(path))
    {
      ChildPanelOnCentral("vision/MessageInfo1", "ERROR", makeDynString("$1:Could not create central repository: " + path));
      return -1;
    }
  }

  //Check if path is writeable
  if(access(path, W_OK))
  {
    ChildPanelOnCentral("vision/MessageInfo1", "ERROR", makeDynString("$1:Path: " + path + "\nis not writeable. You will not be able to copy files"));
    return -1;
  }
      
  return dpSet("fwSysStatDbEditorNavigator.centralRepository.path", path);
}

bool  fwConfigurationDBSystemInformation_isLoggingEnabled()
{
  bool enabled;
  if (dpExists(FW_CONFDB_LOGGER + FW_CONFDB_LOGGER_ENABLED))
  {
    dpGet(FW_CONFDB_LOGGER + FW_CONFDB_LOGGER_ENABLED, enabled);
  }
  
  return enabled;
}

void  fwConfigurationDBSystemInformation_enableLogging(bool enabled)
{
  if (!dpExists(FW_CONFDB_LOGGER))
  {
    dpCreate(FW_CONFDB_LOGGER, FW_CONFDB_LOGGER_DPT);
  }
  
  dpSet(FW_CONFDB_LOGGER + FW_CONFDB_LOGGER_ENABLED, enabled);
  
}

void fwConfigurationDBSystemInformation_logAction(string description, time actionTime = getCurrentTime(), string user = "")
{
  if (user == "" && isFunctionDefined("fwAccessControl_getUserName"))
  {
    fwAccessControl_getUserName(user);
  }
  if (dpExists(FW_CONFDB_LOGGER))
  {
    dpSet(FW_CONFDB_LOGGER + FW_CONFDB_LOGGER_ACTION_TIME, actionTime,
          FW_CONFDB_LOGGER + FW_CONFDB_LOGGER_ACTION_DESCRIPTION, description,
          FW_CONFDB_LOGGER + FW_CONFDB_LOGGER_ACTION_USER, user);
  }
}

//each row contains [1] time [2] description [3] user
dyn_dyn_string fwConfigurationDBSystemInformation_getLoggedActions(time startTime, time endTime, string userPattern="", string descriptionPattern = "")
{
  string format  ="%Y.%m.%d %H:%M:%S";
  string start = formatTime(format, startTime);
  string end = formatTime(format, endTime);
  dyn_dyn_anytype tab;
  string query = "SELECT '" + FW_CONFDB_LOGGER_ACTION_TIME + ":_original.._value', '" + FW_CONFDB_LOGGER_ACTION_TIME + ":_original.._stime'," +
                "'" + FW_CONFDB_LOGGER_ACTION_DESCRIPTION + ":_original.._value', '" + FW_CONFDB_LOGGER_ACTION_DESCRIPTION + ":_original.._stime'," + 
                "'" + FW_CONFDB_LOGGER_ACTION_USER + ":_original.._value' ,'" + FW_CONFDB_LOGGER_ACTION_USER + ":_original.._stime'" 
                " FROM '" + FW_CONFDB_LOGGER + "*' WHERE _DPT=\"" + FW_CONFDB_LOGGER_DPT + "\"" + 
                " TIMERANGE(\""+start+"\",\"" + end + "\",1,0) ";
  dpQuery(query, tab);

  string dpElement;
  string stime;
  dyn_string tmp;
  mapping timeStampToData;
  for (int i=2; i<= dynlen(tab); i++)
  {
     tmp = strsplit(dpSubStr(tab[i][1], DPSUB_DP_EL), ".");
     dpElement = "." + tmp[dynlen(tmp)-1] + "." + tmp[dynlen(tmp)];

     switch(dpElement)
     {
       case FW_CONFDB_LOGGER_ACTION_TIME:
         stime = formatTime(format, tab[i][3], ".%04d");
         if (mappingHasKey(timeStampToData, stime))
         {
           dyn_string data = timeStampToData[stime];
           data[1] = tab[i][2];
           timeStampToData[stime] = data;
         }
         else
         {
           dyn_string data = makeDynString(tab[i][2], "", "");//init
           timeStampToData[stime] = data;
         }
         break;
       case FW_CONFDB_LOGGER_ACTION_DESCRIPTION:
         stime = formatTime(format, tab[i][5], ".%04d");
         if (mappingHasKey(timeStampToData, stime))
         {
           dyn_string data = timeStampToData[stime];
           data[2] = tab[i][4];
           timeStampToData[stime] = data;
         }
         else
         {
           dyn_string data = makeDynString("", tab[i][4], "");//init
           timeStampToData[stime] = data;
         }
         break;
       case FW_CONFDB_LOGGER_ACTION_USER: 
         stime = formatTime(format, tab[i][7], ".%04d");
         if (mappingHasKey(timeStampToData, stime))
         {
           dyn_string data = timeStampToData[stime];
           data[3] = tab[i][6];
           timeStampToData[stime] = data;
         }
         else
         {
           dyn_string data = makeDynString("", "", tab[i][6]);//init
           timeStampToData[stime] = data;
         }
         break;
     }  
  }
  
  dyn_dyn_string loggedActions;
  dyn_string keys = mappingKeys(timeStampToData);
  for(int i=1; i<=dynlen(keys); i++)
  {
    dyn_string data = timeStampToData[keys[i]];
    if ((userPattern != "" && !patternMatch(userPattern, data[3])) ||
        (descriptionPattern != "" && !patternMatch(descriptionPattern, data[2])))
    {
      continue;
    }
    
    
    dynAppend(loggedActions, data);
  }
  
  return loggedActions;
}
