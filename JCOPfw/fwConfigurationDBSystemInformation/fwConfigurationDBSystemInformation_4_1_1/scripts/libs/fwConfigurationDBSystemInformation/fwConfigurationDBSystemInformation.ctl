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


dyn_string FW_SYS_STAT_DB_NAV_MODES; 


const int FW_SYS_STAT_ERROR = -1;
const int FW_SYS_STAT_OK = 0;

const string csFwSysStatManangementLibVersion = "1.2.2";
const string csFwSysStatManagementTool = "1.2.2";

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

string fwConfigurationDBSystemInformation_getToolVersion()
{
  return csFwSysStatManagementTool;
}

int fwConfigurationDBSystemInformation_init()
{
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
  
  txVersion.text = "System Configuration DB Editor v." + fwConfigurationDBSystemInformation_getToolVersion();
                      
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
     //For each of the projects, get the list of PVSS projects
     fwInstallationDB_getPvssProjects(projects, hostnames[i], onlyActive);
     for(int j = 1; j <= dynlen(projects); j++){
       treeEditor.appendItem(hostnames[i],  hostnames[i]+"|"+projects[j], projects[j]);
       treeEditor.setText(hostnames[i]+"|"+projects[j], FW_INST_TYPE_COL, FW_INST_PROJECT_TYPE); 
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
     if(hierarchyInfo[i][FW_CONFDB_SYSSTAT_SYSTEM_PARENT_ID_IDX] <= 0)
       hierarchyInfo[i][FW_CONFDB_SYSSTAT_SYSTEM_PARENT_ID_IDX] = "";
     
     parentId = hierarchyInfo[i][FW_CONFDB_SYSSTAT_SYSTEM_PARENT_ID_IDX];
     idx = hierarchyInfo[i][FW_CONFDB_SYSSTAT_SYSTEM_ID_IDX];
     text = hierarchyInfo[i][FW_CONFDB_SYSSTAT_SYSTEM_NAME_IDX];
     num = hierarchyInfo[i][FW_CONFDB_SYSSTAT_SYSTEM_NUMBER_IDX];
      
     treeEditor.appendItem(parentId, idx, text);
     treeEditor.setText(parentId, idx, num);
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
  dynDynTypes[2] = makeDynInt (0, DPEL_DYN_STRING);
  dynDynTypes[3] = makeDynInt (0, DPEL_STRING);

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
    sql = "select system_name, system_number, redundancy_number, data_port, event_port, dist_port, redu_system_id from fw_sys_stat_pvss_system where parent_system_id = " + parentId + " AND valid_until IS NULL";
       
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
    //find root id:
    sql = "select system_name, system_number, id, parent_system_id from fw_sys_stat_pvss_system where connect_by_isleaf = 0" + 
          "start with parent_system_id is null connect by prior id = parent_system_id"; 

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
    
    sql = "select system_name, system_number, id, parent_system_id from fw_sys_stat_pvss_system " + 
          "where valid_until is null "+
          "start with parent_system_id  = " + hierarchyInfo[1][3] + " connect by prior id = parent_system_id ";
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
            "start with parent_system_id = " + id + " connect by prior id = parent_system_id ";
    }
  }

  if(g_fwInstallationSqlDebug)
      DebugN(sql);

  if(fwInstallationDB_executeDBQuery(sql, aRecords) != 0)
  {
    DebugN("ERROR: fwInstallationDB_getChildSystems() -> Could not execute the following SQL query: " + sql);
    return -1;
  }

//  if(startingSystemName == ""){
    for(int i = 1; i <= dynlen(aRecords); i++)
      hierarchyInfo[i+1] = aRecords[i];
//  }else{
//    hierarchyInfo = aRecords;
//  }
  
  //DebugN("hierarchyInfo: ", hierarchyInfo);
  
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
     
     //DebugN("These are the group components: ", componentsInfo);
     
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

int fwInstallationDB_unregisterGroupComponent(string componentName, string componentVersion, string groupName, string projectName = "", string computerName = "")
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

  if(projectName == "")
    projectName = PROJ;
  
  if(computerName = "")
    computerName = getHostname();

  if(fwInstallationDB_isComponentInGroupRegistered(componentName, componentVersion, groupName, isRegistered, component_id, group_id) != 0)
  {
    DebugN("ERROR: fwInstallationDB_unregisterGroupComponent() -> Could not retrieve project component group information from DB");
    return -1;
    
  }else if(!isRegistered){
    DebugN("INFO: fwInstallationDB_unregisterGroupComponent() -> Component: " + componentName + " v." + componentVersion + " Group: " + groupName + " not registered in project: " + projectName + " computer: " + computerName + ". Nothing to be done.");
    return 0;      
  }else{
     
     sql = "UPDATE fw_sys_stat_comp_in_groups SET valid_until = SYSDATE WHERE fw_component_id = " + component_id + " AND group_id = " + group_id + " AND valid_until IS NULL";
         
     if(g_fwInstallationSqlDebug)
       DebugN(sql);
     
     if(rdbExecuteSqlStatement(gFwInstallationDBConn, sql)) {DebugN("ERROR: fwInstallationDB_unregisterGroupComponent() -> Could not execute the following SQL: " + sql); return -1;};
   
   }      
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
      
      sql = "SELECT c.component_name, c.component_version, c.is_subcomponent, c.default_path, c.is_official, gc.description_file FROM fw_sys_stat_component c, fw_sys_stat_comp_in_groups gc WHERE c.valid_until IS NULL AND c.id IN (SELECT fw_component_id FROM fw_sys_stat_comp_in_groups WHERE group_id = " + group_id + "AND valid_until IS NULL) AND c.id = gc.fw_component_id AND gc.valid_until IS NULL AND group_id = " + group_id;

       
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


int fwInstallationDB_registerGroup(string group)
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

    sql = "INSERT INTO fw_sys_stat_group_of_comp(id, name) VALUES ((fw_sys_stat_group_of_comp_sq.NEXTVAL), \'" + group + "\')";
         
    if(g_fwInstallationSqlDebug)
      DebugN(sql);

    if(rdbExecuteSqlStatement(gFwInstallationDBConn, sql)) {DebugN("ERROR: fwInstallationDB_registerProject() -> Could not execute the following SQL: " + sql); return -1;}; 
  
  }

  return 0;  
}


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


int fwInstallationDB_registerComponentInGroup(string componentName, string componentVersion, int isSubComponent, string descFile, string groupName)
{

  dyn_string exceptionInfo;
  dyn_dyn_mixed aRecords;
  string sql;

  int group_id;
  int component_id;
  bool isRegistered = false;

  //DebugN("registerComponentInGroup: ", componentName, componentVersion, isSubComponent, descFile, groupName);
            
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
  
      if(rdbExecuteSqlStatement(gFwInstallationDBConn, sql)) {DebugN("ERROR: fwInstallationDB_registerProject() -> Could not execute the following SQL: " + sql); return -1;};

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



int fwInstallationDB_registerGroupInProject(string groupName, int overwriteFiles = 0, int forceRequired = 1, int isSilent = 0, string scheduledInstDate = "", string projectName = "", string computerName = "")
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
      sql = "INSERT INTO fw_sys_stat_project_groups(id, group_id, project_id, requested_by, request_date, overwrite_files, force_required, is_silent, scheduled_inst_date, valid_until) VALUES((fw_sys_stat_project_groups_sq.NEXTVAL), " + group_id + ", "+ project_id + ", \'" + requestedBy + "\', SYSDATE, "+ overwriteFiles + ", " + forceRequired + ", " + isSilent + ", NULL, NULL)";      

      if(g_fwInstallationSqlDebug)
      DebugN(sql);
  
      if(rdbExecuteSqlStatement(gFwInstallationDBConn, sql)) {DebugN("ERROR: fwInstallationDB_registerProject() -> Could not execute the following SQL: " + sql); return -1;};
      
      if(registerComponents){
        fwInstallation_getGroupComponents(groupName, components, versions, isSubComponents, descFiles); 
        for(int i = 1; i <= dynlen(components); i++)
        {

          //Register component:
//          fwInstallationDB_isComponentRegistered(components[i], versions[i], component_id);
//          if(id == -1){
//            if(fwInstallationDB_registerComponent(components[i], versions[i], isSubComponent) != 0)
//            {
//              DebugN("ERROR: fwInstallationDB_registerGroupInProject() -> Failed to register component " + components[i] + " v." + versions[i] + " in group " + groupName); 
//              ++error;
//            }
            //Register component in group.
            if(fwInstallationDB_registerComponentInGroup(components[i], versions[i], isSubComponents[i], descFiles[i], groupName) != 0)
            {
              DebugN("ERROR: fwInstallationDB_registerGroupInProject() -> Failed to register component " + components[i] + " v." + versions[i] + " in group " + groupName); 
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










