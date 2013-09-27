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
*/

#uses "fwSystemOverview/fwSystemOverview.ctl"

//@{
global shape fwSysOverviewUi_gTreeShape;
global string  fwSysOverviewUi_gInstanceName =  "fwSystemOverview" ;  // Root node name in the tree

// The variables below can be shifted to the panel's scoplib
global string fwSysOverviewUi_gTreeViewMode;
global dyn_string fwSysOverviewUi_gSysNoFltLst;
global dyn_string fwSysOverviewUi_gManNameFltLst;
global dyn_string fwSysOverviewUi_gManStateFltLst;
global dyn_string fwSysOverviewUi_gHostNameFltLst;


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
    case fwSystemOverviewFunc_STOPPED_NORMAL:
      icon = PROJ_PATH +  "pictures/stop_en.gif";
      break;
    case fwSystemOverviewFunc_INITIALIZE:
      icon =  PROJ_PATH + "pictures/start_en.gif";
      break;
    case fwSystemOverviewFunc_RUNNING:
      icon =  PROJ_PATH + "pictures/start_en.gif";
      break;
    case fwSystemOverviewFunc_BLOCKED:
      icon = PROJ_PATH + "pictures/attention_en.gif";
      break;
    case fwSystemOverviewFunc_STOPPED_ABNORMAL:
      icon = PROJ_PATH + "pictures/attention_en.gif";
      break;
    case fwSystemOverviewFunc_RAPID_RESTART:
      icon = PROJ_PATH + "pictures/attention_en.gif";
      break;
    case fwSystemOverviewFunc_PROJNAME_MISMATCH:
      icon = PROJ_PATH + "pictures/attention_en.gif";
      break;
    case fwSystemOverviewFunc_PMON_NO_RESPONSE:
      icon = PROJ_PATH + "pictures/no_response.gif";
      break;
    case  fwSystemOverviewFunc_PMON_NOT_RUNNING:
      icon = PROJ_PATH + "pictures/no_response.gif";
      break;
   }
  
  return icon;
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

void fwSysOverviewUi_updateSysStateInTree(shape tree, string sysDp)
{
  int sysState;
  dyn_string projDpList;
  
  fwSysOverview_getDeviceState(sysDp, sysState);
  
  tree.setIcon(sysDp, 1, fwSysOverviewUi_getIconState(sysState));
  tree.setText(sysDp, 1, fwSysOverview_getStrFromState(sysState));
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
  
  string systemName, childSysDp;
  unsigned childindex;
  dyn_string children;
  unsigned sysState;
  
  fwSysOverview_getDeviceName(sysDpName, systemName); 
  
  if(!tree.itemExists(sysDpName)){
    tree.appendItem(parentDpName, sysDpName, systemName);
    tree.setIcon(sysDpName, fwSysOverviewUi_SYSNAME_COL, PROJ_PATH + "pictures/fwSystemOverview/system.bmp");
    fwSysOverview_getDeviceState(sysDpName, sysState);
    tree.setIcon(sysDpName, 1, fwSysOverviewUi_getIconState(sysState));
    tree.setText(sysDpName, 1, fwSystemOverviewFunc_getStrFromState(sysState));
    tree.setOpen(sysDpName, true);
    
    if(showProj)
      fwSysOverviewUi_populateSysProjectTree(tree, sysDpName);
    
    fwSysOverview_getChildSystems(sysDpName, children);
    for( childindex = 1; childindex <= dynlen(children); childindex++){ 
      fwSysOverview_getSystemDp(children[childindex], childSysDp);
      fwSysOverviewUi_populateSysTree(tree, childSysDp, sysDpName,showProj);
      }
  }
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
  string projDp;
  int i;
  
  fwSysOverview_getHosts(hostNames);
  
  if(!tree.itemExists(fwSysOverviewUi_gInstanceName))  
     tree.appendItem("", fwSysOverviewUi_gInstanceName, fwSysOverviewUi_gInstanceName);
  
  for(int index = 1; index <= dynlen(hostNames); index++){
    
    fwSysOverview_getPcProjects(hostNames[index], projects);
     
    if(!tree.itemExists(fwSysOverview_SYSTEM_DP+hostNames[index])){    
        tree.appendItem(fwSysOverviewUi_gInstanceName, fwSysOverview_SYSTEM_DP+hostNames[index], hostNames[index]);
        tree.setIcon(fwSysOverview_SYSTEM_DP+hostNames[index], 0, PROJ_PATH + "pictures/fwSystemOverview/host.gif");
        }
   
    for(i=1;i<=dynlen(projects);i++)     
      {
      projDp =fwSysOverview_SYSTEM_DP+ hostNames[index]+ "/" + projects[i];
      if(!tree.itemExists(projDp)){
        tree.appendItem(fwSysOverview_SYSTEM_DP+hostNames[index], projDp, projects[i]);
        tree.setIcon(projDp, 0, PROJ_PATH + "pictures/fwSystemOverview/console.gif");
        }
    }        
  }
  tree.setOpen(fwSysOverviewUi_gInstanceName, true);
}

/** Populate system tree in mapping view

@param tree    Tree widget
*/
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

int fwSysOverviewUi_populateSysProjectTree(shape tree, string sysDpName)
{
  dyn_string projects;
  int i;
  string projName;
  dyn_string ds;
  
  fwSysOverview_getSystemProjects(sysDpName, projects);
  
 
  if(tree.itemExists(sysDpName)){   
    for(i=1;i<=dynlen(projects);i++)     
      { 
      
       ds = strsplit(projects[i], "/");
   
      if(!tree.itemExists(fwSysOverview_SYSTEM_DP + projects[i])){
        fwSysOverview_getDeviceName(fwSysOverview_SYSTEM_DP + projects[i],projName);
        tree.appendItem(sysDpName, fwSysOverview_SYSTEM_DP + projects[i], projName+":"+ds[1]);
        tree.setIcon(fwSysOverview_SYSTEM_DP + projects[i], 0, PROJ_PATH + "pictures/fwSystemOverview/console.gif");
        tree.setOpen(fwSysOverview_SYSTEM_DP + projects[i], TRUE);
        }
      } 
  }  
}



int fwSysOverviewUi_SYSNAME_COL   = 0;
int fwSysOverviewUi_STATE_COL     = 1;


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
  tree.setColumnWidth(0,250);  
  tree.addColumn("state");
}


void fwSysOverviewUi_addColToHostTree(shape tree)
{
  tree.addColumn("Host Machine");  
}

int fwSysOverviewUi_FSMNAME_COL        = 0;
int fwSysOverviewUi_DEVICENAME_COL     = 2;
int fwSysOverviewUi_NODETYPE_COL       = 1;



/** Add columns to the mapping view in the FSM tree
@par Constraints
	None

@par Usage
	Public

@par PVSS managers
	VISION, CTRL

@param tree    Tree widget
*/

void fwSysOverviewUi_addColToFsmTree(shape tree)
{
  tree.addColumn("FSM Nodes");
  tree.addColumn("Node Type"); 
  tree.addColumn("Device Name");   
}


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


  for(int i = 1; i <= dynlen(systemDpNames); i++){
    fwSysOverview_getDeviceName(systemDpNames[i], sysName);
    dynAppend(sysNameList, sysName);
  }
  
/*    for(int j = 1; j <= dynlen(projDpList); j++){
      fwSystemOverviewFunc_getProjAccessData(projDpList[j], hostName, pmonPortNo, userName, userPassword, sharedDir);
      dynAppend(hostList, hostName);
      fwSystemOverviewFunc_getProjManagersType(projDpList[j], type);
      dynAppend(managerNameList, type);
    }  
*/
  
  fwSysOverview_getHosts(hostList);

  
/* 
  fwSystemOverviewFunc_getStateList(stateList);
  dynUnique(stateList);
  dynSortAsc(stateList);
  
  dynUnique(managerNameList);
  dynSortAsc(managerNameList);
  
*/
  
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





void fwSysOverviewUi_populateFsmView(shape tree, string sysName = "")
{
  dyn_string nodes, exInfo;
  string device, type;
  string rootNodeName = "FSM";
  string parentTreeNode;
  
  parentTreeNode = fwSysOverviewUi_gInstanceName;
  
  if(!tree.itemExists(fwSysOverviewUi_gInstanceName))
     tree.appendItem("", fwSysOverviewUi_gInstanceName, fwSysOverviewUi_gInstanceName);

  if(sysName == "")
     sysName = getSystemName();
  
  strreplace(sysName, ":", "");
  
  fwTree_getChildren(sysName + ":" + rootNodeName, nodes, exInfo);
  
  for(int i = 1; i<= dynlen(nodes); i++){
    fwSysOverviewUi_populateFsmTree(tree, parentTreeNode, sysName, nodes[i],  exInfo);
  } 
   
  tree.setOpen(fwSysOverviewUi_gInstanceName ,true);  
}

/** Populate FSM tree nodes
@par Constraints
	None

@par Usage
	Public

@par PVSS managers
	VISION, CTRL

@param tree              Tree widget
@param parentTreeNode    Parent tree node name
@param sysName           System name
@param nodeName          FSM node name
@param exInfo            Exception information
*/

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
  
/** Refresh FSM tree
@param tree     Tree widget
*/

void fwSysOverviewUi_refreshFsmView(shape tree)
{
  dyn_string treeNodeList = tree.children(fwSysOverviewUi_gInstanceName);
  int childno = dynlen(treeNodeList);
  
  for(int i = 1; i <= childno; i++){
    fwSysOverviewUi_refreshFsmState(tree, treeNodeList[i]);
  }
}

/** Refresh FSM state of the tree node

@param tree          Tree widget
@param treeNodeName  Tree node name
*/

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

void fwSysOverviewUi_highlightFsmNodes(shape fsmTree, dyn_string sysNodeList)
{
  string sysName;
  dyn_string sysNameList;

  for(int i = 1; i <= dynlen(sysNodeList); i++){
    fwSysOverview_getDeviceName(sysNodeList[i], sysName);
  //  fwSystemOverviewFunc_getSysName(sysNodeList[i], sysName);
    dynAppend(sysNameList, sysName);
  }
  
  dyn_string treeNodeList = fsmTree.children(fwSysOverviewUi_gInstanceName);
  int childno = dynlen(treeNodeList);

  //DebugN("In highlightFsmNodes", sysNameList, treeNodeList);
  
  for(int i = 1; i <= childno; i++){
    fwSysOverviewUi_highlightCorrespondingFsmNodes(fsmTree, treeNodeList[i], sysNameList);
  }
}

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

int fwSysOverviewUi_openConsole(string moduleName, string id)
{
  dyn_mixed projectData;

//  projectData[] 1. pmon number | 2. pmon user name | 3. pmon user password
//                4. dirpath | 5. system name | 6. host name  
  
  if(dpExists(id)){
    if(dpTypeName(id) == "FwSystemOverviewPC")
       RootPanelOnModule( "fwSystemOverview/fwSystemOverview_IpmiPanel.pnl","IpmiPanel:"+id,moduleName,"");
     else if(dpTypeName(id) == "FwSystemOverviewProject"){     
            fwSysOverview_getProjAccessData(id, projectData);
            RootPanelOnModule( "fwSystemOverview/fwSystemOverview_managersTable.pnl","ProjectPanel:"+id,moduleName,makeDynString("$host:"+projectData[6], "$port:"+projectData[1], "$userName:"+projectData[2], "$userPassword:"+ projectData[3]));
          } 
       else
        RootPanelOnModule( "fwSystemOverview/fwSystemOverview_module.pnl","SysOverview"+id,moduleName,"");   
   }
   else
     RootPanelOnModule( "fwSystemOverview/fwSystemOverview_module.pnl","SysOverview"+id,moduleName,"");
}

//@}
 
