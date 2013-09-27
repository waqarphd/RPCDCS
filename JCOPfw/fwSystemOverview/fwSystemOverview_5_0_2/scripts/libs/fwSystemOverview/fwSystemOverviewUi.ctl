/**@file

This library contains functions associated with the JCOP Framework System Overview tool. The 
functions are for connecting the user interface to the datapoints, updating the data in
user interface in various display modes

@par Creation Date
	15/02/2007

@par Modification History
	
@par Constraints

@author 
	Kuldeep Joshi (BARC, India) mailto:kuldeep.joshi@gmail.com
        Francisca Calheiros (IT/CO-BE)
        Fernando Varela (IT/CO-BE)
        Pawel Macuda (IT/CO-BE)
*/

#uses "fwSystemOverview/fwSystemOverview.ctl"

//@{
global shape fwSysOverviewUi_gTreeShape;
global string  fwSysOverviewUi_gInstanceName =  "fwSystemOverview" ;  // Root node name in the tree
global int fwSysOverviewUi_gAccessControl;

// The variables below can be shifted to the panel's scoplib
global string fwSysOverviewUi_gTreeViewMode;
global dyn_string fwSysOverviewUi_gSysNoFltLst;
global dyn_string fwSysOverviewUi_gManNameFltLst;
global dyn_string fwSysOverviewUi_gManStateFltLst;
global dyn_string fwSysOverviewUi_gHostNameFltLst;

int fwSysOverviewUi_SYSNAME_COL   = 0;
int fwSysOverviewUi_STATE_COL     = 1;
int fwSysOverviewUi_FSMNAME_COL   = 0;
int fwSysOverviewUi_DEVICENAME_COL = 2;
int fwSysOverviewUi_NODETYPE_COL = 1;

//@{
/** Connect the system current status datapoint element to the respective work function

@param workFuncSys    Callback function when the current state of the system is updated
@param firstUpdate    To indicate if the callback should execute on connecting to the datapoint
*/
    
int fwSysOverviewUi_connectDp2Ui(string workFuncSys, bool firstUpdate = TRUE)
{
  dyn_string systemDpNames;
  int i;
  
  fwSysOverview_getSystemsDps(systemDpNames);
  
  for(i = 1; i <= dynlen(systemDpNames); i++){
    dpConnect(workFuncSys, firstUpdate, systemDpNames[i] + fwSysOverview_STATE);
  }
  return fwSysOverview_OK;   
}

int fwSysOverviewUi_connectProjState(string workFuncSys, bool firstUpdate = TRUE)
{
  dyn_string projDps;
  int i;
  
  fwSysOverview_getAllProjects(projDps);
  
  for(i = 1; i <= dynlen(projDps); i++){
    dpConnect(workFuncSys, firstUpdate, projDps[i] + fwSysOverview_STATE);
  }
  return fwSysOverview_OK;   
}    
    
/** Disconnect the system current status datapoint element to the respective work function

@param workFuncSys    Callback function when the current state of the system is updated
*/

int fwSysOverviewUi_disconnectDp2Ui(string workFuncSys)
{
  dyn_string systemDpNames;
  int i, j;
  
   fwSysOverview_getSystemsDps(systemDpNames);
  
  for(i = 1; i <= dynlen(systemDpNames); i++){
    dpDisconnect(workFuncSys, systemDpNames[i] + fwSysOverview_STATE);
  }
  return fwSysOverview_OK;   
}

string fwSysOverviewUi_getIconState(int state)
{
  string icon;
  
  switch(state){
    case fwSysOverview_STOPPED_NORMAL:
      icon = PROJ_PATH +  "pictures/fwSystemOverview/stop_en.gif";
      break;
    case fwSysOverview_INITIALIZE:
      icon =  PROJ_PATH + "pictures/fwSystemOverview/start_en.gif";
      break;
    case fwSysOverview_RUNNING:
      icon =  PROJ_PATH + "pictures/fwSystemOverview/start_en.gif";
      break;
    case fwSysOverview_BLOCKED:
      icon = PROJ_PATH + "pictures/fwSystemOverview/attention_en.gif";
      break;
    case fwSysOverview_STOPPED_ABNORMAL:
      icon = PROJ_PATH + "pictures/fwSystemOverview/attention_en.gif";
      break;
    case fwSysOverview_RAPID_RESTART:
      icon = PROJ_PATH + "pictures/fwSystemOverview/attention_en.gif";
      break;
    case fwSysOverview_PROJNAME_MISMATCH:
      icon = PROJ_PATH + "pictures/fwSystemOverview/attention_en.gif";
      break;
    case fwSysOverview_PMON_NO_RESPONSE:
      icon = PROJ_PATH + "pictures/fwSystemOverview/no_response.gif";
      break;
   }
  
  return icon;
}

string fwSysOverviewUi_getPlcIconState(int state)
{
  string icon;
  
  switch(state){
    case 1:
      icon =  PROJ_PATH + "pictures/fwSystemOverview/start_en.gif";
      break;
    case 0:
      icon = PROJ_PATH + "pictures/fwSystemOverview/attention_en.gif";
      break;
    }
  
  return icon;
}
string fwSysOverviewUi_getStrFromPlcState(int state)
{
  string text;
  
  switch(state){
    case 1:
      text =  "OK";
      break;
    case 0:
      text = "ERROR";
      break;
    }
  
  return text;
}
fwSysOverviewUi_getPlcState(string icemonPlcDp, int& state)
{
  state = 1;
  if (dpExists(icemonPlcDp + ".:_alert_hdl.._act_state"))
  {
    bool active;
    dpGet(icemonPlcDp + ".:_alert_hdl.._act_state", active);
    state = (int)!active;
  }
}
/** Update the system state in the tree
@par Constraints
	None

@par Usage
	Public

@par PVSS managers
	VISION, CTRL

@param tree    Tree widget to be updated
@param sysDp   System datapoint name
@param command View mode for the tree
*/

void fwSysOverviewUi_updateDevStateInTree(shape tree, string deviceDp)
{
  int deviceState;
  
  fwSysOverview_getDeviceState(deviceDp, deviceState);
  
  if(tree.itemExists(deviceDp))
  {
   tree.setIcon(deviceDp, 1, fwSysOverviewUi_getIconState(deviceState));
   tree.setText(deviceDp, 1, fwSysOverview_getStrFromState(deviceState));
   }
}

/** Populate the system and the process tree
 
@par Constraints
	None

@par Usage
	Public

@par PVSS managers
	VISION, CTRL

@param tree    Tree widget to be populated
@param sysDpName  System datapoint name
@param parentDpName  Parent tree node name
*/

void fwSysOverviewUi_populateSysTree(shape tree, string sysDpName, string parentDpName, bool showProj=TRUE)
{
  
  string systemName, childSysDp;  unsigned childindex;
  dyn_string children;
  unsigned sysState;
  string dbSystemName;
  dyn_string exceptionInfo;
  
  fwSysOverview_getDeviceName(sysDpName, systemName); 
  if(!tree.itemExists(sysDpName))
  {
    fwSysOverview_getSystemDb(sysDpName, dbSystemName, exceptionInfo);
    if(dynlen(exceptionInfo)){return;}
    
    tree.appendItem(parentDpName, sysDpName, dbSystemName);
    tree.setIcon(sysDpName, fwSysOverviewUi_SYSNAME_COL, PROJ_PATH + "pictures/fwSystemOverview/system.bmp");
    tree.setOpen(sysDpName, true);
    
    if(showProj)
      fwSysOverviewUi_populateSysProjectTree(tree, sysDpName);
  }
  tree.setColumnWidth(0, 180);
  return;
}

/** Populate Host View
@par Constraints
	None

@par Usage
	Public

@par PVSS managers
	VISION, CTRL

@param tree     Tree widget
*/
int fwSysOverviewUi_populateHostView(shape tree)
{
  int index;
  dyn_string hostNames;
  dyn_string projects;
  string projDp, projState;
  int i;
  string dbProject, dbHost;
  dyn_string exception;
    
  fwSysOverview_getHosts(hostNames);
  
  if(dynlen(hostNames) <= 0)
  {
    DebugN("WARNING: Application not yet configured. Not hosts found");
    return 0;
  }
  
  if(!tree.itemExists(fwSysOverviewUi_gInstanceName))  
     tree.appendItem("", fwSysOverviewUi_gInstanceName, fwSysOverviewUi_gInstanceName);
  
  for(int index = 1; index <= dynlen(hostNames); index++)
  {     
     
    if(!tree.itemExists(fwSysOverview_SYSTEM_DP + dbHost))
    {    
      fwSysOverview_getHostDb(hostNames[index], dbHost, exception);
      if(dynlen(exception)){fwExceptionHandling_display(exception); continue;}  
      tree.appendItem(fwSysOverviewUi_gInstanceName, hostNames[index], dbHost);
      tree.setIcon(hostNames[index], 0, PROJ_PATH + "pictures/fwSystemOverview/host.gif");
    }
   
    fwSysOverview_getPcProjects(hostNames[index], projects);
    
    for(i=1;i<=dynlen(projects);i++)     
    {
//      strreplace(projects[i],getSystemName(),"");   //
      projDp = projects[i];
        
      if(!tree.itemExists(projDp))
      {
        fwSysOverview_getProjectDb(projDp, dbProject, exception);
        if(dynlen(exception)){fwExceptionHandling_display(exception); continue;}
        
        tree.appendItem(hostNames[index], projDp, dbProject);
        tree.setIcon(projDp, 0, PROJ_PATH + "pictures/fwSystemOverview/console.gif");
        fwSysOverview_getDeviceState(projDp, projState);
        tree.setIcon(projDp, 1, fwSysOverviewUi_getIconState(projState));
        tree.setText(projDp, 1, fwSysOverview_getStrFromState(projState));
      }
    }        
  }
  tree.setOpen(fwSysOverviewUi_gInstanceName, true);
  tree.setColumnWidth(0, 180);
}

/** Populate system tree in mapping view

@param tree    Tree widget
*/
/*
int fwSysOverviewUi_populateMappingSysView(shape tree)
{
  dyn_string rootDPs;
  
  fwSysOverview_getRootNodes(rootDPs);
  
  if(!tree.itemExists(fwSysOverviewUi_gInstanceName))
    tree.appendItem("", fwSysOverviewUi_gInstanceName, fwSysOverviewUi_gInstanceName);
  
  for(int rootindex = 1; rootindex <= dynlen(rootDPs); rootindex++)
    fwSysOverviewUi_populateSysTree(tree, rootDPs[rootindex], fwSysOverviewUi_gInstanceName,FALSE);

  tree.setOpen(fwSysOverviewUi_gInstanceName ,true);
  
}
*/

/** Change tree view mode. Toggle between system view and process view

@param tree    Tree widget
@param command View mode for the tree
*/

bool fwSysOverviewUi_toggleTreeViewMode(shape tree, string command)
{  
  dyn_string rootNodeList;
  
  if(tree.itemExists(fwSysOverviewUi_gInstanceName)){
    rootNodeList = tree.children(fwSysOverviewUi_gInstanceName);
    for(int i = dynlen(rootNodeList); i >= 1; i--){
      tree.setVisible(rootNodeList[i], 
                                      fwSysOverviewUi_setVisibleTreeNodes(tree, rootNodeList[i], command, fwSysOverviewUi_gSysNoFltLst, 
                                                          fwSysOverviewUi_gHostNameFltLst, fwSysOverviewUi_gManNameFltLst, 
                                                          fwSysOverviewUi_gManStateFltLst));
    }
    tree.ensureItemVisible(fwSysOverviewUi_gInstanceName);
    fwSysOverviewUi_hideColumns(tree, fwSysOverviewUi_gTreeViewMode);
  }
  return true;
} 



/** Populate Hierarchy View
@par Constraints
	None

@par Usage
	Public

@par PVSS managers
	VISION, CTRL

@param tree    Tree widget
*/

int fwSysOverviewUi_populateSysView(shape tree)
{
  dyn_string rootDPs;

  fwSysOverview_getRootNodes(rootDPs);
  
  if(!tree.itemExists(fwSysOverviewUi_gInstanceName))
     tree.appendItem("", fwSysOverviewUi_gInstanceName, fwSysOverviewUi_gInstanceName);
  
  for(int rootindex = 1; rootindex <= dynlen(rootDPs); rootindex++)
    fwSysOverviewUi_populateSysTree(tree, rootDPs[rootindex], fwSysOverviewUi_gInstanceName);

  tree.setOpen(fwSysOverviewUi_gInstanceName ,true);  
}


void fwSysOverviewUi_populateSysProjectTree(shape tree, string sysDpName)
{
//  dyn_string projects;
  string projName;
  dyn_string ds;
  dyn_string exceptionInfo;
  dyn_string projectDpNames;
  string dbProjectName, hostDpName, dbHostName;
  string projState;

  fwSysOverview_getSystemProjects(sysDpName, projectDpNames, exceptionInfo);
  
 
  if(tree.itemExists(sysDpName))
  {
    for(int i =1;i<=dynlen(projectDpNames);i++)     
    {       
      if(!tree.itemExists(projectDpNames[i]))
      {
        fwSysOverview_getProjectDb(projectDpNames[i], dbProjectName, exceptionInfo);
        if(dynlen(exceptionInfo)){continue;}
      
        fwSysOverview_getProjectPc(projectDpNames[i], hostDpName, exceptionInfo);
        if(dynlen(exceptionInfo)){continue;}
      
        fwSysOverview_getHostDb(hostDpName, dbHostName, exceptionInfo);
        if(dynlen(exceptionInfo)){continue;}
        tree.appendItem(sysDpName, projectDpNames[i], dbProjectName + ":" + dbHostName);
        fwSysOverview_getDeviceState(projectDpNames[i], projState);
        tree.setIcon(projectDpNames[i], 1, fwSysOverviewUi_getIconState(projState));
        tree.setText(projectDpNames[i], 1, fwSysOverview_getStrFromState(projState));
        tree.setIcon(projectDpNames[i], 0, PROJ_PATH + "pictures/fwSystemOverview/console.gif");
        tree.setOpen(projectDpNames[i], TRUE);
      }
    } 
  }  
}



/** Add cloumns to hierarchy tree
@par Constraints
	None

@par Usage
	Public

@par PVSS managers
	VISION, CTRL

@param tree    Tree widget
*/

void fwSysOverviewUi_addColToSysTree(shape tree)
{
  tree.addColumn("PVSS System");
  tree.setColumnWidth(0,180);  
  tree.addColumn("state");
}


void fwSysOverviewUi_addColToHostTree(shape tree)
{
  tree.addColumn("Host Machine"); 
  tree.setColumnWidth(0,180);   
  tree.addColumn("state");
}

void fwSysOverviewUi_addColToPlcTree(shape tree)
{
  tree.addColumn("Name"); 
  tree.setColumnWidth(0,180);   
  tree.addColumn("state");
}




/** Add columns to the mapping view in the FSM tree
@par Constraints
	None

@par Usage
	Public

@par PVSS managers
	VISION, CTRL

@param tree    Tree widget
*/
/*
void fwSysOverviewUi_addColToFsmTree(shape tree)
{
  tree.addColumn("FSM Nodes");
  tree.addColumn("Node Type"); 
  tree.addColumn("Device Name");   
}
*/

/** Populate the filter list from datapoint
@par Constraints
	None

@par Usage
	Public

@par PVSS managers
	VISION, CTRL

@param sysNoList      System number filter list
@param sysNameList    System name filter list
@param hostList       Host name filter list
@param stateList      Manager state filter list
@param managerNameList  Manager name filter list
*/

void fwSysOverviewUi_populateFilterListFromDp(dyn_string& sysNameList, dyn_string& hostList, dyn_int& stateList, dyn_string& managerNameList)
{
  dyn_string systemDpNames;
  string sysName;
  unsigned sysNo, parentNo, pmonPortNo;
  dyn_uint childNodes;
      
  dynClear(sysNameList);
  
  fwSysOverview_getSystemsDps(systemDpNames);
  if(dynlen(systemDpNames) <= 0)
  {
    DebugN("WARNING: Application not yet configured. No system found");
    return 0;
  }


  for(int i = 1; i <= dynlen(systemDpNames); i++){
    fwSysOverview_getDeviceName(systemDpNames[i], sysName);
    dynAppend(sysNameList, sysName);
  }
 
  fwSysOverview_getHosts(hostList);

}




/** Populate filter table

@param filterTable Name of the filter table
@param itemList    List of items to be append to the table
*/

bool fwSysOverviewUi_populateFilterTable(shape filterTable, dyn_string itemList)
{
  filterTable.deleteAllLines();
 
  filterTable.tableMode(TABLE_SELECT_MULTIPLE);
  filterTable.selectByClick(TABLE_SELECT_LINE);
  dynInsertAt(itemList, "All", 1);
  
  filterTable.appendLines(dynlen(itemList), filterTable.columnToName(0),itemList);
  filterTable.selectLineN(0);
  filterTable.lineVisible(0);
}




/*
void fwSysOverviewUi_populateFsmView(shape fsmtree, string sysName = "")
{
  dyn_string nodes, exInfo;
  string device, type;
  string rootNodeName = "FSM";
  string parentTreeNode;
  
  dyn_string children;
  parentTreeNode = fwSysOverviewUi_gInstanceName;

  
  if(!fsmtree.itemExists(fwSysOverviewUi_gInstanceName))
  {
     fsmtree.appendItem("", fwSysOverviewUi_gInstanceName, fwSysOverviewUi_gInstanceName);
  }
  

  if(sysName == "")
  {
    dyn_string rootDPs;
    fwSysOverview_getRootNodes(rootDPs);
    
    if(dynlen(rootDPs)<= 0)
      return; 
    
//    strreplace(rootDPs[1], "SystemOverview/SYSTEM/", "");
//    sysName = rootDPs[1];    
    fwSysOverview_getDeviceName(rootDPs[1], sysName);
    
  }
  strreplace(sysName, ":", "");
  
  fwTree_getChildren(sysName + ":" + rootNodeName, nodes, exInfo);
  
  for(int i = 1; i<= dynlen(nodes); i++)
  {
    fwSysOverviewUi_populateFsmTree(fsmtree, parentTreeNode, sysName, nodes[i],  exInfo);
  } 
   
  tree.setOpen(fwSysOverviewUi_gInstanceName ,true);  
}
*/

/** Populate FSM tree nodes
@par Constraints
	None

@par Usage
	Publica

@par PVSS managers
	VISION, CTRL

@param tree              Tree widget
@param parentTreeNode    Parent tree node name
@param sysName           System name
@param nodeName          FSM node name
@param exInfo            Exception information
*/

/*
void fwSysOverviewUi_populateFsmTree(shape tree, string parentTreeNode, string sysName, string nodeName, dyn_string exInfo)
{
  dyn_string nodes;
  string type, device, state, childSysName;
  string treeNodeName, actNodeName, nodeLabel;
  dyn_string userData;
  
  fwTree_getNodeDevice(sysName  + ":" + nodeName, device, type, exInfo);
  
  treeNodeName = device;

  fwTree_getChildren(device, nodes, exInfo);

  childSysName = fwTree_getNodeSys(device, exInfo);
  strreplace(childSysName, ":", "");
  
  fwTree_getNodeUserData(device, userData, exInfo);
  if(dynlen(userData) > 2)
    nodeLabel = userData[3];
  else
    nodeLabel = device;
  
  if(!tree.itemExists(treeNodeName)){
    tree.appendItem(parentTreeNode, treeNodeName, nodeLabel);
  }
  else{
    tree.setText(treeNodeName, fwSysOverviewUi_FSMNAME_COL, nodeLabel);
  }
    
  tree.setIcon(treeNodeName, fwSysOverviewUi_FSMNAME_COL, PROJ_PATH + "pictures/fwSystemOverview/right_en.gif");
  tree.setText(treeNodeName, fwSysOverviewUi_DEVICENAME_COL, device);
  tree.setText(treeNodeName, fwSysOverviewUi_NODETYPE_COL, type);
//  tree.setOpen(treeNodeName, true);
  
  for(int i = 1; i<= dynlen(nodes); i++){
    fwSysOverviewUi_populateFsmTree(tree, treeNodeName, childSysName, nodes[i], exInfo);
  }
}
*/

/** Refresh FSM tree
@param tree     Tree widget
*/
/*
void fwSysOverviewUi_refreshFsmView(shape tree)
{
  dyn_string treeNodeList = tree.children(fwSysOverviewUi_gInstanceName);
  int childno = dynlen(treeNodeList);
  
  for(int i = 1; i <= childno; i++){
    fwSysOverviewUi_refreshFsmState(tree, treeNodeList[i]);
  }
}
*/

/** Refresh FSM state of the tree node

@param tree          Tree widget
@param treeNodeName  Tree node name
*/

/*
void fwSysOverviewUi_refreshFsmState(shape tree, string treeNodeName)
{
  string nodeName = treeNodeName;
  string state;
  dyn_string childList;
  int childno;
  
  _fwTree_getNodeSys(nodeName);
  fwCU_getState(nodeName,state);
  
  tree.setText(treeNodeName, fwSysOverviewUi_FSMSTATE_COL, state);

  childList = tree.children(treeNodeName);
  childno = dynlen(childList);
  
  for(int i = 1; i <= childno; i++){
    fwSysOverviewUi_refreshFsmState(tree, childList[i]);
  }
}    
*/

/** Hilight the system nodes in the system tree of mapping view
@par Constraints
	None

@par Usage
	Public

@par PVSS managers
	VISION, CTRL

@param sysTree      Tree widget
@param fsmNodeList  FSM node list, for which the system nodes are to be hilighted
*/

/*
void fwSysOverviewUi_highlightSysNodes(shape sysTree, dyn_string fsmNodeList)
{
  dyn_string sysNameList;
  dyn_string exInfo;
  
  for(int i = 1; i <= dynlen(fsmNodeList); i++){
    dynAppend(sysNameList, fwTree_getNodeSys(fsmNodeList[i], exInfo));
  }
  
  dyn_string treeNodeList = sysTree.children(fwSysOverviewUi_gInstanceName);
  int childno = dynlen(treeNodeList);
  
  for(int i = 1; i <= childno; i++){
    fwSysOverviewUi_highlightCorrespondingSysNodes(sysTree, treeNodeList[i], sysNameList);
  }
}
*/


/** Hilight the system node as per the sysNameList
@par Constraints
	None

@par Usage
	Public

@par PVSS managers
	VISION, CTRL

@param sysTree       Tree widget
@param treeNodeName  Tree node name in the system tree
@param sysNameList   List of system nodes which are to be hilighted
*/
/*
void fwSysOverviewUi_highlightCorrespondingSysNodes(shape sysTree, string treeNodeName, dyn_string sysNameList)
{
  sysTree.setSelectedItem(treeNodeName,
                          dynContains(patternMatch(sysTree.getText(treeNodeName, fwSysOverviewUi_SYSNAME_COL),
                                                   sysNameList), TRUE) != 0);
  
  dyn_string treeNodeList = sysTree.children(treeNodeName);
  int childno = dynlen(treeNodeList);
  
  for(int i = 1; i <= childno; i++){
    fwSysOverviewUi_highlightCorrespondingSysNodes(sysTree, treeNodeList[i], sysNameList);
  }
}
*/

    
/** Hilight the FSM nodes in the FSM tree of mapping view
@par Constraints
	None

@par Usage
	Public

@par PVSS managers
	VISION, CTRL

@param fsmTree      Tree widget
@param sysNodeList  System node list, for which the FSM nodes are to be hilighted
*/
/*
void fwSysOverviewUi_highlightFsmNodes(shape fsmTree, dyn_string sysNodeList)
{
  string sysName;
  dyn_string sysNameList;

  for(int i = 1; i <= dynlen(sysNodeList); i++){
    fwSysOverview_getDeviceName(sysNodeList[i], sysName);
    dynAppend(sysNameList, sysName);
  }
  
  dyn_string treeNodeList = fsmTree.children(fwSysOverviewUi_gInstanceName);
  int childno = dynlen(treeNodeList);

  //DebugN("In highlightFsmNodes", sysNameList, treeNodeList);
  
  for(int i = 1; i <= childno; i++){
    fwSysOverviewUi_highlightCorrespondingFsmNodes(fsmTree, treeNodeList[i], sysNameList);
  }
}
*/

/** Hilight the FSM node as per the sysNameList
@par Constraints
	None

@par Usage
	Public

@par PVSS managers
	VISION, CTRL

@param fsmTree       Tree widget
@param treeNodeName  Tree node name in the FSM tree
@param sysNameList   List of system nodes which are to be hilighted
*/
/*
void fwSysOverviewUi_highlightCorrespondingFsmNodes(shape fsmTree, string treeNodeName, dyn_string sysNameList)
{
  string sysName = treeNodeName;
  sysName = _fwTree_getNodeSys(sysName);
  
  fsmTree.setSelectedItem(treeNodeName,
                          dynContains(patternMatch(sysName, sysNameList), TRUE) != 0);
  
  dyn_string treeNodeList = fsmTree.children(treeNodeName);
  int childno = dynlen(treeNodeList);
  
  for(int i = 1; i <= childno; i++){
    fwSysOverviewUi_highlightCorrespondingFsmNodes(fsmTree, treeNodeList[i], sysNameList);
  }
}
*/

int fwSysOverviewUi_openConsole(string moduleName, string id)
{

  dyn_mixed projectData; //  projectData[] 1. pmon number | 2. pmon user name | 3. pmon user password
                                        // 4. dirpath | 5. system name | 6. host name
  string sysName;
  string dbProjectName;
  dyn_string exceptionInfo;
   
  if(id == "fwSystemOverview")
  {
    if(moduleName == "hierarchyconsole")
    {
      RootPanelOnModule( "fwSystemOverview/fwSystemOverview_projectsSummary.pnl","SysOverview_1",moduleName,makeDynString("$projectDps:", "$embedded:TRUE"));     
      tfPreviousPanel.text = "SysOverview_1";
    }
    else if(moduleName == "hostconsole")
    {      
      string systemName = "";
      systemName = fwSysOverview_getFmcSystem(); 
      dyn_string nodes;
      fwFMC_getNodes(nodes, systemName);
      RootPanelOnModule("fwFMC/fwFMC_nodesSummaryNavigator.pnl",
                        "SysOverview_1",
                        "hostconsole",
                        makeDynString("$view:", "$sDpName:", "$group:", "$nodes:" + nodes));

      tfPreviousPanel.text = "SysOverview_1";
    }
    else if(moduleName == "mappingFsmconsole")
    {
    }
    return 0;
  }
  else if(dpExists(id))
  {
    if(dpTypeName(id) == "FwSystemOverviewPC")
    {
      fwSysOverviewUi_openFmcPanel(moduleName,id);
    }
    else if(dpTypeName(id) == "FwSystemOverviewProject")
    {    
      fwSysOverview_getProjAccessData(id, projectData);
      fwSysOverview_getProjectDb(id, dbProjectName, exceptionInfo);
      string fmcDp = fwSysOverview_getFMCdpName(projectData[fwSysOverview_PROJECT_HOST_IDX]);
      if(dynlen(exceptionInfo)){return;}
      RootPanelOnModule( "fwSystemOverview/fwSystemOverview_managersTable.pnl","ProjectPanel:" + id, moduleName,
                         makeDynString("$host:"+projectData[fwSysOverview_PROJECT_HOST_IDX], 
                                       "$port:"+projectData[fwSysOverview_PROJECT_PMON_NUM_IDX],
                                       "$userName:"+projectData[fwSysOverview_PROJECT_PMON_USER_IDX], 
                                       "$userPassword:"+ projectData[fwSysOverview_PROJECT_PMON_PASS_IDX], 
                                       "$system:"+ projectData[fwSysOverview_PROJECT_SYSTEM_NAME_IDX], 
                                       "$project:" + dbProjectName,
                                       "$sDpName:" + fmcDp)
                       );                 
      tfPreviousPanel.text = "ProjectPanel:" + id;
    }
    else if(dpTypeName(id) == "FwSystemOverviewSystem")
    { 
      dyn_string ex;
      string sys = "";
      fwSysOverview_getSystemDb(id, sys, ex);
      string hostDp, host;
      fwSysOverview_getSystemHost(id, hostDp, ex);
      fwSysOverview_getHostDb(hostDp, host, ex);
      dyn_string projectDps;
      fwSysOverview_getSystemProjects(id, projectDps, ex);
      RootPanelOnModule("fwSystemOverview/fwSystemOverview_system.pnl", "SystemPanel:" + id, moduleName, makeDynString("$system:" + sys, "$host:" + host, "$projectDps:"+projectDps));
      tfPreviousPanel.text = "SystemPanel:" + id;
    } 
  }
  else if (id== "PLCs")
  {
    RootPanelOnModule( "objects/PLCMONITORING/icemonWidgetContainerModule.pnl","SysOverview_3","plcsconsole",makeDynString("$1:", "$2:", "$deviceType:PLCS", "$modName:plcsModule"));     
    tfPreviousPanel.text = "SysOverview_3";
  }
  else if (moduleName == "plcsconsole")
  {
    string dp = dpAliasToName(id);
   
    if (dp != "" && dpTypeName(dp) == "IcemonPlc")
    {
      bool isDU;
      string domain = icemon_getDomain(id, isDU);
      RootPanelOnModule("fwSystemOverview/Fsm/IcemonPlcBasic.pnl", "plc_" + id, "plcsconsole", makeDynString("$1:"+domain, "$2:" + id));
    }
  }

}
  
int fwSysOverviewUi_openFmcPanel(string moduleName, string id)
{
  string host;
  fwSysOverview_getDeviceName(id, host);
  
  strreplace(host, "SystemOverview/", "");
  string dpName = fwSysOverview_getFMCdpName(host);
  
  if(isFunctionDefined("fwFMC_getNodeDp") && dpExists(fwSysOverview_getFmcSystem() + "fwInstallation_fwFMC")&& dpName!="")
    RootPanelOnModule("fwFMC/fwFMC_nodeNavigator.pnl","IpmiPanel:" + id,moduleName,makeDynString("$sDpName:"+ dpName));
        
  else
    RootPanelOnModule("fwSystemOverview/fwSystemOverview_noFmc.pnl","IpmiPanel:" + id,moduleName,makeDynString("$node:"+ host));  
  
  tfPreviousPanel.text = "IpmiPanel:" + id;
}

int fwSysOverviewUi_checkForAccessControl()
{
//  bool accessControl;
  string domain;
  
//  dpGet("fwSysOverviewParametrization.accessControl", accessControl);
  
//  if(dpExists("fwInstallation_fwAccessControl") && accessControl)
  if(dpExists("fwInstallation_fwAccessControl"))
  {
    DebugN("Access control is active");
    
    fwSysOverview_getACDomain(domain);
    
    if(domain == "")
    {
      DebugN("Access domain is not configured.");
      
      ModuleOnWithPanel("Access Domain",-1,-1,0,0,1,1,"","vision/MessageWarning","warning", 
                        "Access domain is not configured! You may do it via configuration panel.");
      stayOnTop(TRUE, "Access Domain"); 
      
      
      fwSysOverviewUi_gAccessControl = 1;
      return fwSysOverview_ERROR;
    } 
    else
    {
      // Place a login/current access control user widget in the Installation panel
      addSymbol(myModuleName(), "SystemOverview", 
  	      "objects/fwAccessControl/fwAccessControl_CurrentUser.pnl", "user", 
                makeDynString(), 1000, 15, 0, 1, 1);
      //disable all control commands
      fwSysOverviewUi_gAccessControl = 0;
      return fwSysOverview_OK;
    }
  }
  else 
  {
    DebugN("Access control is disabled");
    fwSysOverviewUi_gAccessControl = 1;
    return fwSysOverview_ERROR;  
  }
}
//@}

int fwSysOverviewUi_populatePlcView(shape tree)
{
  int index;
  dyn_string plcs;
  string plcDp; 
  int plcState;

  dyn_string plcDps = dpNames("plc*", "IcemonPlc");
  string plcName;

  
  if(dynlen(plcDps) <= 0)
  {
    DebugN("WARNING: No plcs found");
    return 0;
  }
  
  if(!tree.itemExists("PLCs"))  
     tree.appendItem("", "PLCs", "PLCs");
  
  dyn_string plcAliases;
  fwSysOverviewUi_getPlcAliases(plcDps, plcAliases);

  for(int index = 1; index <= dynlen(plcDps); index++)
  { 
    plcName = plcAliases[index]; 
    
    tree.appendItem("PLCs", plcName, plcName);
    string type;
    dpGet(plcDps[index] + ".Configuration.type", type);
    string image;
    switch (type)
    {
      case SIEMENS_PLC_S7_400:
        image = "pictures/logo/siemens_s7-400_icon.png";
        break;
      case SIEMENS_PLC_S7_300:
        image = "pictures/logo/siemens_s7-300_icon.png";
        break;
      case SCHNEIDER_PLC_QUANTUM:
        image = "pictures/logo/schneider_quantum_icon.png";
        break;
      case SCHNEIDER_PLC_PREMIUM:
        image = "pictures/logo/schneider_premium_icon.png";
        break;
    }
    tree.setIcon(plcName, 0, PROJ_PATH + image );
    fwSysOverviewUi_getPlcState(plcDps[index], plcState);
    tree.setIcon(plcName, 1, fwSysOverviewUi_getPlcIconState(plcState));
    tree.setText(plcName, 1, fwSysOverviewUi_getStrFromPlcState(plcState));
   
  }
  tree.setOpen("PLCs", true);
  tree.setColumnWidth(0, 180);
}

void fwSysOverviewUi_getPlcAliases(dyn_string& plcDps, dyn_string& plcAliases)
{
  for(int i = 1; i <= dynlen(plcDps); i++)
  { 
    dynAppend(plcAliases, dpGetAlias(plcDps[i] + ".")); 
  }
  string tmp;
  //order the aliases alphabetically (keep the dps in sync)
  for(int i=1; i<= dynlen(plcAliases); i++)
  {
    for (int j=i+1; j<=dynlen(plcAliases); j++)
    {
      if (plcAliases[j] < plcAliases[i])
      {
        //swap the aliases
        tmp = plcAliases[i];
        plcAliases[i] = plcAliases[j];
        plcAliases[j] = tmp;
        
        //swap the dps
        tmp = plcDps[i];
        plcDps[i] = plcDps[j];
        plcDps[j] = tmp;
      }
    }
  }
}

