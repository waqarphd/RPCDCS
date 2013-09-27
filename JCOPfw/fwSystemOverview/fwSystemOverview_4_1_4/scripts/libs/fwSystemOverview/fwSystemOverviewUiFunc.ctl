#uses "fwSystemOverview/fwSystemOverviewFunc.ctl"

// Global Variables
global string fwSystemOverviewUiFunc_gInstanceName;
global string fwSystemOverviewUiFunc_gTreeViewMode;
global dyn_string fwSystemOverviewUiFunc_gSysNoFltLst;
global dyn_string fwSystemOverviewUiFunc_gManNameFltLst;
global dyn_string fwSystemOverviewUiFunc_gManStateFltLst;
global dyn_string fwSystemOverviewUiFunc_gHostNameFltLst;

int fwSystemOverviewUiFunc_connectDp2Ui(string workFunc, bool firstUpdate = TRUE)
{
  dyn_string sysDpList, projDpList, dpeList;
  int i, j;
  
  fwSystemOverviewFunc_getSysDPList(sysDpList);
  
  for(i = 1; i <= dynlen(sysDpList); i++){
    fwSystemOverviewFunc_getProjDPList(sysDpList[i], projDpList);
  
    for(j = 1; j <= dynlen(projDpList); j++){
      dynClear(dpeList);
      fwSystemOverviewUiFunc_makeDpeConnectList(projDpList[j], dpeList);

      dpConnect(workFunc, firstUpdate, dpeList);
    }
  }
  return 0;   
}

int fwSystemOverviewUiFunc_disconnectDp2Ui(string workFunc)
{
  dyn_string sysDpList, projDpList, dpeList;
  int i, j;
  
  fwSystemOverviewFunc_getSysDPList(sysDpList);
  
  for(i = 1; i <= dynlen(sysDpList); i++){
    fwSystemOverviewFunc_getProjDPList(sysDpList[i], projDpList);
  
    for(j = 1; j <= dynlen(projDpList); j++){
      dynClear(dpeList);
      fwSystemOverviewUiFunc_makeDpeConnectList(projDpList[j], dpeList);
      
      dpDisconnect(workFunc, dpeList);
    }
  }
  return 0;   
}

void fwSystemOverviewUiFunc_makeDpeConnectList(string projDp, dyn_string &dpeList)
{
      dynAppend(dpeList, projDp + fwSystemOverviewFunc_CURR_STATE_STR);
      dynAppend(dpeList, projDp + fwSystemOverviewFunc_PROJ_NAME_STR);
      dynAppend(dpeList, projDp + fwSystemOverviewFunc_ACT_PROJ_NAME_STR);
      dynAppend(dpeList, projDp + fwSystemOverviewFunc_SYSNO_STR);
      dynAppend(dpeList, projDp + fwSystemOverviewFunc_PMON_PORT_STR);
      dynAppend(dpeList, projDp + fwSystemOverviewFunc_EVM_PORT_STR);
      dynAppend(dpeList, projDp + fwSystemOverviewFunc_DM_PORT_STR);
      dynAppend(dpeList, projDp + fwSystemOverviewFunc_DISTMAN_PORT_STR);
      dynAppend(dpeList, projDp + fwSystemOverviewFunc_IP_STR);
      dynAppend(dpeList, projDp + fwSystemOverviewFunc_HOSTNAME_STR);
      dynAppend(dpeList, projDp + fwSystemOverviewFunc_PROJ_PATH_STR);
      dynAppend(dpeList, projDp + fwSystemOverviewFunc_MANAGER_STR + fwSystemOverviewFunc_OK_STATE_STR);
      dynAppend(dpeList, projDp + fwSystemOverviewFunc_MANAGER_STR + fwSystemOverviewFunc_NUM_STR);
      dynAppend(dpeList, projDp + fwSystemOverviewFunc_MANAGER_STR + fwSystemOverviewFunc_TYPE_STR);
      dynAppend(dpeList, projDp + fwSystemOverviewFunc_MANAGER_STR + fwSystemOverviewFunc_INDEX_STR);
      dynAppend(dpeList, projDp + fwSystemOverviewFunc_MANAGER_STR + fwSystemOverviewFunc_MODE_STR);
      dynAppend(dpeList, projDp + fwSystemOverviewFunc_MANAGER_STR + fwSystemOverviewFunc_OPTIONS_STR);
      dynAppend(dpeList, projDp + fwSystemOverviewFunc_MANAGER_STR + fwSystemOverviewFunc_PID_STR);
      dynAppend(dpeList, projDp + fwSystemOverviewFunc_MANAGER_STR + fwSystemOverviewFunc_RESETMIN_STR);
      dynAppend(dpeList, projDp + fwSystemOverviewFunc_MANAGER_STR + fwSystemOverviewFunc_RESTART_STR);
      dynAppend(dpeList, projDp + fwSystemOverviewFunc_MANAGER_STR + fwSystemOverviewFunc_SECKILL_STR);
      dynAppend(dpeList, projDp + fwSystemOverviewFunc_MANAGER_STR + fwSystemOverviewFunc_STARTTIME_STR);
      dynAppend(dpeList, projDp + fwSystemOverviewFunc_MANAGER_STR + fwSystemOverviewFunc_CURR_STATE_STR);
      dynAppend(dpeList, projDp + fwSystemOverviewFunc_MANAGER_STR + fwSystemOverviewFunc_UPDATED_STR);
}

void fwSystemOverviewUiFunc_getProjInfoInTree(shape tree, string projDp, dyn_anytype value, string command)
{
  unsigned sysNo, pMonPortNo, eventPortNo, dmPortNo, distPortNo;
  int projCStat;
  string projName, actProjName, sharedDir, hostIp, hostName;

  dyn_int        cStat, okStat, pid, num;
  dyn_uint       index, mode, resetMin, restart, secKill;
  dyn_time       startTime;
  dyn_string     type, opt;
  dyn_bool       lastUpdated;  
  
  int childCount, manCount, i, j;
  string sName;
  unsigned si;
  
  if(dynlen(value) == 0){
    fwSystemOverviewFunc_getProjData(projDp, projName, projCStat, sysNo, pMonPortNo, eventPortNo, dmPortNo, distPortNo, sharedDir, hostIp, hostName);
    fwSystemOverviewFunc_getProjManagersData(projDp, type, num, opt, mode, index, cStat, okStat, pid, resetMin, restart, secKill, startTime, lastUpdated); 
  }
  else{
    projCStat = value[1];
    projName = value[2];
    actProjName = value[3];
    sysNo = value[4];
    pMonPortNo = value[5];
    eventPortNo = value[6];
    dmPortNo = value[7];
    distPortNo = value[8];
    hostIp = value[9];
    hostName = value[10];
    sharedDir = value[11];
    okStat = value[12];
    num = value[13];
    type = value[14];
    index = value[15];
    mode = value[16];
    opt = value[17];
    pid = value[18];
    resetMin = value[19];
    restart = value[20];
    secKill = value[21];
    startTime = value[22];
    cStat = value[23];
    lastUpdated = value[24];
  }

  if(tree.itemExists(projDp))
    tree.setText(projDp, fwSystemOverviewUiFunc_STATE_COL, fwSystemOverviewFunc_getStrFromState(projCStat));
//  DebugN("in fwSystemOverviewUiFunc_getProjInfoInTree: Function Called", sysNo, projDp, projCStat, PMON_NO_RESPONSE);

  if(tree.itemExists(projDp) && projCStat < fwSystemOverviewFunc_PMON_NO_RESPONSE){
    childCount = dynlen(tree.children(projDp));
    manCount = dynCount(lastUpdated, TRUE);
    
//        DebugN(dpName + "_HOST_" + hostIndex + " CHILD COUNT: " + tree.childCount(dpName + "_HOST_" + hostIndex) + " MAN COUNT: " + manCount);
    if(childCount > manCount){
      for(j = manCount + 1; j <= childCount; j++){
        tree.removeItem(projDp + "_" + j);
//            DebugN("Remove Item: "+ dpName + "_HOST_" + hostIndex + "_" + j); 
      }
    }
    for (i = 1; i <= manCount; i++)        // to include code for updating the changed status of the managers
    {
      j = dynContains(lastUpdated, TRUE);
      lastUpdated[j] = FALSE;
      si = index[j];
      sName = pmon_getManDescript(type[j]);
      if ( sName == "" ) sName = type[j];
      if ( !isMotif() ) strreplace(sName, "&", "&&");

//        DebugN("getManagerInfoInTree: ITEM NAME:" + tree.itemExists(dpName+67));
      if(!tree.itemExists(projDp + "_" + si)){
       // DebugN("Item exists: " + tree.itemExists(projDp + "_" + si) + " " + projDp + "_" + si);
        tree.appendItem(projDp, projDp + "_" + si, sName);
        tree.setIcon(projDp + "_" + si, fwSystemOverviewUiFunc_SYSNAME_COL, PROJ_PATH + "pictures/fwSystemOverview/manager.gif");
//            DebugN("In GetProjInfo in tree: ", projDp);
      }
      else{
        tree.setText(projDp + "_" + si, fwSystemOverviewUiFunc_SYSNAME_COL, sName);
      }

      tree.setText(projDp + "_" + si, fwSystemOverviewUiFunc_STATE_COL, fwSystemOverviewFunc_getStrFromState(cStat[j]));
      tree.setText(projDp + "_" + si, fwSystemOverviewUiFunc_MANTYPE_COL, type[j]);
      tree.setText(projDp + "_" + si, fwSystemOverviewUiFunc_MANNO_COL, num[j]);
      tree.setText(projDp + "_" + si, fwSystemOverviewUiFunc_OPT_COL, opt[j]);
      tree.setText(projDp + "_" + si, fwSystemOverviewUiFunc_START_COL, startTime[j]);
      tree.setText(projDp + "_" + si, fwSystemOverviewUiFunc_PID_COL, pid[j]);
      tree.setText(projDp + "_" + si, fwSystemOverviewUiFunc_MODE_COL, pmonStartModeToStr(mode[j]));
      tree.setText(projDp + "_" + si, fwSystemOverviewUiFunc_RESTART_COL, restart[j]);
      tree.setText(projDp + "_" + si, fwSystemOverviewUiFunc_RESET_COL, resetMin[j]);
      tree.setText(projDp + "_" + si, fwSystemOverviewUiFunc_KILL_COL, secKill[j]);
      tree.setText(projDp + "_" + si, fwSystemOverviewUiFunc_INDEX_COL, index[j]);

      fwSystemOverviewUiFunc_setVisibleTreeNodes(tree, projDp + "_" + si, command, fwSystemOverviewUiFunc_gSysNoFltLst, fwSystemOverviewUiFunc_gHostNameFltLst, fwSystemOverviewUiFunc_gManNameFltLst, fwSystemOverviewUiFunc_gManStateFltLst);
      
    }
    fwSystemOverviewUiFunc_hideColumns(tree, fwSystemOverviewUiFunc_gTreeViewMode);
  }
  else{
    DebugN("in fwSystemOverviewUiFunc_getProjInfoInTree: PMON not responding or tree node does not exists ", "COMMAND: " + command, "PROJECT STATUS: " + projCStat, projDp, tree.itemExists(projDp));
  }
}


void fwSystemOverviewUiFunc_populateSysNProcTree(shape tree, string sysDpName, string parentDpName)
// Presently using recursion later to use for loop to avoid stack overload and handling loops and multiple parents    
{
  dyn_string childNodes, projDpList;
  string hostIp, hostName, projName, sharedDir;
  unsigned pMonPort, evmPort, dmPort, distPort;
  int projCStat;
  dyn_anytype value;
  
  string presentSystemName;
  unsigned sysNo, parentNo, sysState;
  
  unsigned childindex;

  if (sysDpName != ""){
    fwSystemOverviewFunc_getSysData(sysDpName, sysNo, presentSystemName, parentNo, childNodes, projDpList);

//To Check if the filter list is made in the view or lib of Data Struct    
//    dynAppend(gSysNoList, sysNo);
//    dynAppend(gSysNameList, presentSystemName);
  }
  DebugN(" Present System Name: " + presentSystemName);
  
  if(!tree.itemExists(sysDpName)){

    tree.appendItem(parentDpName, sysDpName, presentSystemName);
    tree.setIcon(sysDpName, fwSystemOverviewUiFunc_SYSNAME_COL, PROJ_PATH + "pictures/fwSystemOverview/system.bmp");
    tree.setText(sysDpName, fwSystemOverviewUiFunc_SYSNO_COL, sysNo);
    fwSystemOverviewFunc_getSysState(sysDpName, sysState);
    tree.setText(sysDpName, fwSystemOverviewUiFunc_STATE_COL, fwSystemOverviewFunc_getStrFromState(sysState));
//    DebugN("in fwSystemOverviewUiFunc_populateSysNProcTree: " + projDpList, childNodes);
    for(int index = 1; index <= dynlen(projDpList); index++){
      
      fwSystemOverviewFunc_getProjData(projDpList[index], projName, projCStat, sysNo, pMonPort, evmPort, dmPort, distPort, sharedDir, hostIp, hostName);
      
      tree.appendItem(sysDpName, projDpList[index], projName + ": " +hostName);
      tree.setIcon(projDpList[index], fwSystemOverviewUiFunc_SYSNAME_COL, PROJ_PATH + "pictures/fwSystemOverview/host.gif");
      tree.setText(projDpList[index], fwSystemOverviewUiFunc_HOSTIP_COL, hostIp);
      tree.setText(projDpList[index], fwSystemOverviewUiFunc_PMON_COL, pMonPort);
      tree.setText(projDpList[index], fwSystemOverviewUiFunc_EVM_COL, evmPort);
      tree.setText(projDpList[index], fwSystemOverviewUiFunc_DIST_COL, distPort);
      tree.setText(projDpList[index], fwSystemOverviewUiFunc_DM_COL, dmPort);
      tree.setText(projDpList[index], fwSystemOverviewUiFunc_PROJPATH_COL, sharedDir);
      tree.setExpandable(projDpList[index], true);
      tree.setOpen(projDpList[index], true);
//      DebugN(" Project DP Name: " + projDpList[index], projName);
      
//      fwSystemOverviewUiFunc_getProjInfoInTree(tree, projDpList[index], value, fwSystemOverviewUiFunc_gTreeViewMode);
    }
    tree.setOpen(sysDpName, true);
    for( childindex = 1; childindex <= dynlen(childNodes); childindex++){
      fwSystemOverviewUiFunc_populateSysNProcTree(tree, fwSystemOverviewFunc_sysNoToDp(childNodes[childindex]), sysDpName);
    }
    fwSystemOverviewUiFunc_hideColumns(tree, fwSystemOverviewUiFunc_gTreeViewMode);
  }
  else{
    DebugN("There is a loop in the dp struct or one child with many parents. Handle it later", "DPNAME: " + sysDpName);
    // There is a loop in the dp struct or one child with many parents. Handle it later
  }
}

/*  setVisibleTreeNodes(tree, projDp + "_" + si, command, fwSystemOverviewUiFunc_gSysNoFltLst, fwSystemOverviewUiFunc_gManNameFltLst, fwSystemOverviewUiFunc_gManStateFltLst);

refreshView(shape tree)
{
  dyn_string rootNodeList;

  if(tree.itemExists(fwSystemOverviewUiFunc_gInstanceName)){  
    rootNodeList = tree.children(fwSystemOverviewUiFunc_gInstanceName);
    for(int i = dynlen(rootNodeList); i >= 1; i--){
      if(tree.isVisible(rootNodeList[i])){
        refreshVisibleMan(tree , rootNodeList[i]);
      }
    }
    hideColumns(tree, fwSystemOverviewUiFunc_gTreeViewMode);
  } 
}

refreshVisibleMan(shape tree, string treeNodeName)
{
  dyn_string treeNodeChildList;
  int childno;

  treeNodeChildList = tree.children(treeNodeName);
  childno = dynlen(treeNodeChildList);
  
  if(dpTypeName(treeNodeName) == PROJ_NODE_TYPE){
    fwSystemOverviewUiFunc_getProjInfoInTree(tree, treeNodeName, fwSystemOverviewUiFunc_gTreeViewMode);
  }
  else if(childno > 0){
    for(int i = 1; i <= childno; i++){
      if(tree.isVisible(treeNodeChildList[i])){
        refreshVisibleMan(tree, treeNodeChildList[i]);
      }
    }
  }
  hideColumns(tree, fwSystemOverviewUiFunc_gTreeViewMode);
}

*/

bool fwSystemOverviewUiFunc_toggleTreeViewMode(shape tree, string command)
{  
  dyn_string rootNodeList;
  
  if(tree.itemExists(fwSystemOverviewUiFunc_gInstanceName)){  
    rootNodeList = tree.children(fwSystemOverviewUiFunc_gInstanceName);
    for(int i = dynlen(rootNodeList); i >= 1; i--){
      tree.setVisible(rootNodeList[i], 
                      fwSystemOverviewUiFunc_setVisibleTreeNodes(tree, rootNodeList[i], command, fwSystemOverviewUiFunc_gSysNoFltLst, 
                                                                 fwSystemOverviewUiFunc_gHostNameFltLst, fwSystemOverviewUiFunc_gManNameFltLst, 
                                                                 fwSystemOverviewUiFunc_gManStateFltLst));
    }
    tree.ensureItemVisible(fwSystemOverviewUiFunc_gInstanceName);
    fwSystemOverviewUiFunc_hideColumns(tree, fwSystemOverviewUiFunc_gTreeViewMode);
  }
  return true;
} 

//Caution hardcoded column index used in patternmatch
bool fwSystemOverviewUiFunc_setVisibleTreeNodes(shape tree, string treeNodeName, string command, dyn_string sysNoList, 
                                                dyn_string hostNameList, dyn_string manNameList, dyn_string manStateList)
{
  dyn_string treeNodeChildList;
  int        childno, pos;
  bool       childVisible, fVisible = TRUE;
  string     sysNode, hostName;
  int        nodeType;      // Enumerated type for sysNode = 0, proj = 1, man = 2, host = 3
  unsigned   sysNo;
  
  string     dpType;
  
  treeNodeChildList = tree.children(treeNodeName);
  childno = dynlen(treeNodeChildList);
  
  if(dpExists(treeNodeName)){
    dpType = dpTypeName(treeNodeName);
//    DebugN("in setVisibleTreeNodes: " + treeNodeName, dpType);
  }
  if(command == "SYSTEMVIEW" || command == "PROCESSVIEW"){
    if(dpType == fwSystemOverviewFunc_SYS_NODE_TYPE){
      sysNode = treeNodeName;
      nodeType = 0;
    }
    else if(dpType == fwSystemOverviewFunc_PROJ_NODE_TYPE){
      sysNode = tree.parent(treeNodeName);
      hostName = tree.getText(treeNodeName, fwSystemOverviewUiFunc_SYSNAME_COL);
      hostName = substr(hostName, strpos(hostName, ": ") + 2);
      nodeType = 1;
    }
    else{
      sysNode = tree.parent(tree.parent(treeNodeName));
      nodeType = 2;
    }
    
    if(dynlen(sysNoList) > 0){
      sysNo = fwSystemOverviewFunc_sysDpToNo(sysNode);
      if(dynContains(patternMatch(sysNo, sysNoList), TRUE) == 0){
        fVisible = FALSE;
      }
    }
    
    if(dynlen(hostNameList) > 0){
      if(nodeType == 1){
        if(dynContains(patternMatch(hostName, hostNameList), TRUE) == 0){
          fVisible = FALSE;
        }
      }
      else if( nodeType != 2){
        fVisible = FALSE;
      }
    }
  }
  else if(command == "HOSTSYSTEMVIEW" || command == "HOSTPROCESSVIEW"){
    if(patternMatch("*"+fwSystemOverviewFunc_SYSVIEW_NODE+"*", treeNodeName)){
      nodeType = 0;
      pos = strpos(treeNodeName, fwSystemOverviewFunc_SYSVIEW_NODE);
      sysNode = substr(treeNodeName, pos);
    }
    else if(dpType == fwSystemOverviewFunc_PROJ_NODE_TYPE){
      nodeType = 1;
      sysNode = tree.parent(treeNodeName);
      pos = strpos(sysNode, fwSystemOverviewFunc_SYSVIEW_NODE);
      sysNode = substr(sysNode, pos);
    }
    else if(patternMatch(fwSystemOverviewFunc_PROJVIEW_NODE+"*", treeNodeName)){
      nodeType = 2;
      pos = strpos(tree.parent(tree.parent(treeNodeName)), fwSystemOverviewFunc_SYSVIEW_NODE);
      sysNode = substr(tree.parent(tree.parent(treeNodeName)), pos);
    }
    else{        
      nodeType = 3;
      hostName = treeNodeName;
    }
    
    if(dynlen(hostNameList) > 0 && nodeType == 3){
      if(dynContains(patternMatch(hostName, hostNameList), TRUE) == 0){
        fVisible = FALSE;
      }
    }
    
    if(dynlen(sysNoList) > 0){
      if(nodeType == 0){
        sysNo = fwSystemOverviewFunc_sysDpToNo(sysNode);
        if(dynContains(patternMatch(sysNo, sysNoList), TRUE) == 0){
          fVisible = FALSE;
        }
      }
//       else if(nodeType == 3){
//         fVisible = FALSE;
//       }
    }
  }
  
  for(int i = 1; i <= childno; i++){
    if(command == "SYSTEMVIEW" || command == "PROCESSVIEW"){
      if(nodeType == 1 && fVisible == FALSE)
        continue;
      fVisible |= fwSystemOverviewUiFunc_setVisibleTreeNodes(tree, treeNodeChildList[i], command, sysNoList, hostNameList, manNameList, manStateList);
    }
    else if(command == "HOSTSYSTEMVIEW" || command == "HOSTPROCESSVIEW"){
      if((nodeType == 0 || nodeType == 3) && fVisible == FALSE)
        continue;
      childVisible |= fwSystemOverviewUiFunc_setVisibleTreeNodes(tree, treeNodeChildList[i], command, sysNoList, hostNameList, manNameList, manStateList);
    }
  }
  
  if(nodeType == 3 && childVisible == FALSE && (command == "HOSTSYSTEMVIEW" || command == "HOSTPROCESSVIEW"))
    fVisible = FALSE;

  if(fVisible == TRUE && nodeType == 2){
    if(command == "SYSTEMVIEW" || command == "HOSTSYSTEMVIEW"){
      fVisible = FALSE;
    }
    else{
      if(dynlen(manNameList) > 0){
        if(dynContains(patternMatch(tree.getText(treeNodeName, fwSystemOverviewUiFunc_MANTYPE_COL), manNameList), TRUE) == 0)
          fVisible = FALSE;
      }
      if(dynlen(manStateList) > 0){
        if(dynContains(patternMatch(tree.getText(treeNodeName, fwSystemOverviewUiFunc_STATE_COL), manStateList), TRUE) == 0)
          fVisible = FALSE;
      }
    }  
  }

  if(tree.isVisible(treeNodeName) ^ fVisible)
    tree.setVisible(treeNodeName, fVisible);
//   if(fVisible == FALSE)
//     DebugN(treeNodeName, command, "NODETYPE: "+nodeType, "is Visible: "+fVisible, hostName, hostNameList);
  return fVisible;          
}

int fwSystemOverviewUiFunc_populateSysNProcView(shape tree)
{
  dyn_string rootDPs;
  
  fwSystemOverviewFunc_getRootNodes(rootDPs);
  
  DebugN(fwSystemOverviewUiFunc_gInstanceName, rootDPs);
  tree.appendItem("", fwSystemOverviewUiFunc_gInstanceName, fwSystemOverviewUiFunc_gInstanceName);
  for(int rootindex = 1; rootindex <= dynlen(rootDPs); rootindex++)
    fwSystemOverviewUiFunc_populateSysNProcTree(tree, rootDPs[rootindex], fwSystemOverviewUiFunc_gInstanceName);

  tree.setOpen(fwSystemOverviewUiFunc_gInstanceName ,true);
  
}

int fwSystemOverviewUiFunc_populateHostView(shape tree)
{
  int index;
  dyn_string sysDpList;
  dyn_string projDpList;
  string sysName, hostName, hostIp, projName, sharedDir;
  unsigned pmonPortNo, eventPortNo, dmPortNo, distPortNo, sysNo;
  int projCStat;
  
  fwSystemOverviewFunc_getSysDPList(sysDpList);
    
  tree.appendItem("", fwSystemOverviewUiFunc_gInstanceName, fwSystemOverviewUiFunc_gInstanceName);
  
  for(int index = 1; index <= dynlen(sysDpList); index++){
    fwSystemOverviewFunc_getProjDPList(sysDpList[index], projDpList);
    
    for(int j = 1; j <= dynlen(projDpList); j++){
      fwSystemOverviewFunc_getProjData(projDpList[j], projName, projCStat, sysNo, pmonPortNo, eventPortNo, dmPortNo, distPortNo, sharedDir, hostIp, hostName);
          
      if(!tree.itemExists(hostName)){    
        tree.appendItem(fwSystemOverviewUiFunc_gInstanceName, hostName, hostName);
        tree.setIcon(hostName, 0, PROJ_PATH + "pictures/fwSystemOverview/host.gif");
      }
      fwSystemOverviewFunc_getSysName(sysDpList[index], sysName);
      if(!tree.itemExists(hostName + "_" + sysDpList[index])){
        tree.appendItem(hostName, hostName + "_" + sysDpList[index], sysName);
        tree.setIcon(hostName + "_" + sysDpList[index], 0, PROJ_PATH + "pictures/fwSystemOverview/system.bmp");
        tree.setText(hostName + "_" + sysDpList[index], fwSystemOverviewUiFunc_SYSNO_COL, sysNo);
      }
      if(!tree.itemExists(projDpList[j])){
        tree.appendItem(hostName + "_" + sysDpList[index], projDpList[j], projName);
        tree.setIcon(projDpList[j], 0, PROJ_PATH + "pictures/fwSystemOverview/host.gif");
        tree.setText(projDpList[j], fwSystemOverviewUiFunc_HOSTIP_COL, hostIp);
        tree.setText(projDpList[j], fwSystemOverviewUiFunc_PMON_COL, pmonPortNo);
        tree.setText(projDpList[j], fwSystemOverviewUiFunc_EVM_COL, eventPortNo);
        tree.setText(projDpList[j], fwSystemOverviewUiFunc_DIST_COL, distPortNo);
        tree.setText(projDpList[j], fwSystemOverviewUiFunc_DM_COL, dmPortNo);
        tree.setText(projDpList[j], fwSystemOverviewUiFunc_PROJPATH_COL, sharedDir);
        tree.setExpandable(projDpList[j], TRUE);
        tree.setOpen(projDpList[j], TRUE);
      }
    }        
  }
  tree.setOpen(fwSystemOverviewUiFunc_gInstanceName, true);
}

int fwSystemOverviewUiFunc_SYSNAME_COL   = 0;
int fwSystemOverviewUiFunc_SYSNO_COL     = 1;
int fwSystemOverviewUiFunc_STATE_COL     = 2;
int fwSystemOverviewUiFunc_HOSTIP_COL    = 3;
int fwSystemOverviewUiFunc_PMON_COL      = 4;
int fwSystemOverviewUiFunc_EVM_COL       = 5;
int fwSystemOverviewUiFunc_DIST_COL      = 6;
int fwSystemOverviewUiFunc_DM_COL        = 7;
int fwSystemOverviewUiFunc_PROJPATH_COL  = 8;
int fwSystemOverviewUiFunc_MANTYPE_COL   = 9;
int fwSystemOverviewUiFunc_MANNO_COL     = 10;
int fwSystemOverviewUiFunc_OPT_COL       = 11;
int fwSystemOverviewUiFunc_START_COL     = 12;
int fwSystemOverviewUiFunc_PID_COL       = 13;
int fwSystemOverviewUiFunc_MODE_COL      = 14;
int fwSystemOverviewUiFunc_RESTART_COL   = 15;
int fwSystemOverviewUiFunc_RESET_COL     = 16;
int fwSystemOverviewUiFunc_KILL_COL      = 17;
int fwSystemOverviewUiFunc_INDEX_COL     = 18;

fwSystemOverviewUiFunc_addColToSysNProcTree(shape tree)
{
  tree.addColumn("PVSS System");
  tree.addColumn("Num"); 
  tree.addColumn("St");           // Column Index = 2
  tree.addColumn("Host Address");   
  tree.addColumn("PMON Port");   
  tree.addColumn("EM Port");
  tree.addColumn("DistMan Port");
  tree.addColumn("DM Port");
  tree.addColumn("Proj Path");
//  tree.setColumnWidth(8,24);
  tree.addColumn("Manager");      // Column Index = 9
  tree.addColumn("No");           // Column Index = 10
//  tree.setColumnWidth(10,26);
  tree.addColumn("Options");  
  tree.addColumn("Start Time");
  tree.addColumn("PID");  
  tree.addColumn("Mode"); 
  tree.addColumn("Restart#");   
  tree.addColumn("ResetMin");   
  tree.addColumn("SecKill");   
  tree.addColumn("shmIndex");   
}

const int fwSystemOverviewUiFunc_PROC_COL_START  = 9;
const int fwSystemOverviewUiFunc_PROC_COL_END    = 18;
const int fwSystemOverviewUiFunc_SYS_COL_START   = 1;
const int fwSystemOverviewUiFunc_SYS_COL_END     = 8;

fwSystemOverviewUiFunc_addColToHostTree(shape tree)
{
  tree.addColumn("Host Machine");
  tree.addColumn("Num"); 
  tree.addColumn("St");           // Column Index = 2
  tree.addColumn("Host Address");   
  tree.addColumn("PMON Port");   
  tree.addColumn("EM Port");
  tree.addColumn("DistMan Port");
  tree.addColumn("DM Port");
  tree.addColumn("Proj Path");
//  tree.setColumnWidth(8,24);
  tree.addColumn("Manager");      // Column Index = 9
  tree.addColumn("No");           // Column Index = 10
//  tree.setColumnWidth(10,26);
  tree.addColumn("Options");  
  tree.addColumn("Start Time");
  tree.addColumn("PID");  
  tree.addColumn("Mode"); 
  tree.addColumn("Restart#");   
  tree.addColumn("ResetMin");   
  tree.addColumn("SecKill");   
  tree.addColumn("shmIndex");   
}

int fwSystemOverviewUiFunc_FSMNAME_COL        = 0;
int fwSystemOverviewUiFunc_DEVICENAME_COL     = 3;
//int fwSystemOverviewUiFunc_STATE_COL          = 2;    //Already defined
int fwSystemOverviewUiFunc_NODETYPE_COL       = 1;

fwSystemOverviewUiFunc_addColToFsmTree(shape tree)
{
  tree.addColumn("FSM Nodes");
  tree.addColumn("Node Type"); 
  tree.addColumn("State");           // Column Index = 2
  tree.addColumn("Device Name");   
}

fwSystemOverviewUiFunc_addColToMappingTree1(shape tree)
{
  tree.addColumn("PVSS System");
  tree.addColumn("Num"); 
  tree.addColumn("St");           // Column Index = 2
}

fwSystemOverviewUiFunc_addColToMappingTree2(shape tree)
{
  tree.addColumn("FSM Nodes");
  tree.addColumn("Node Type"); 
  tree.addColumn("State");           // Column Index = 2
  tree.addColumn("Device Name");   
}

fwSystemOverviewUiFunc_hideColumns(shape tree, string viewMode)
{
  if(viewMode == "PROCESSVIEW" || viewMode == "HOSTPROCESSVIEW"){
    for(int i = fwSystemOverviewUiFunc_PROC_COL_END; i >= fwSystemOverviewUiFunc_PROC_COL_START; i--)
      tree.adjustColumn(i);
  
    for(int i = fwSystemOverviewUiFunc_SYS_COL_START; i <= fwSystemOverviewUiFunc_SYS_COL_END; i++){
      if( i != 2)
        tree.hideColumn(i); //setColumnWidth(i,0);
      else
        tree.adjustColumn(i);
    }
  
  //  for(int i = PROC_COL_START; i <= PROC_COL_END; i++)
  //    tree.setColumnWidth(i, 90);
  }
  else if (viewMode == "SYSTEMVIEW" || viewMode == "HOSTSYSTEMVIEW"){
    for(int i = fwSystemOverviewUiFunc_SYS_COL_END; i >= fwSystemOverviewUiFunc_SYS_COL_START; i--)
      tree.adjustColumn(i);
  
    for(int i = fwSystemOverviewUiFunc_PROC_COL_START; i <= fwSystemOverviewUiFunc_PROC_COL_END; i++)
      tree.hideColumn(i); //setColumnWidth(i,0);
    
  
  //  for(int i = SYS_COL_START; i <= SYS_COL_END; i++)
  //    tree.setColumnWidth(i, 90);
    
  }
}

bool fwSystemOverviewUiFunc_populateManagerNameTable(shape manNameFilter, dyn_string managers)
{
  dyn_string     mans;
  dyn_dyn_string ddsResult;
  dyn_string     dsPath, dsSubs;
  string         sPath;
  int            iErr;
 
  manNameFilter.deleteAllLines();
  
  manNameFilter.tableMode(TABLE_SELECT_MULTIPLE);
  manNameFilter.selectByClick(TABLE_SELECT_LINE);

  sPath = PROJ_PATH;
  
  iErr = paCfgReadValueList(sPath+"/config/config", "general", "proj_path", dsPath, " = ");
  if ( iErr )
  {
    pmon_warningOutput("errorGetProjAttr", iErr, false);
    return;
  }
/*  iErr = paGetProjAttr(projName, "pvss_path", sPath);
  if ( iErr )
  {
    pmon_warningOutput("errorGetProjAttr", iErr, false);
    return;
  }
*/
  sPath = PVSS_PATH;
  
  dynInsertAt(dsPath, sPath, 1);

  for (int i = 1; i <= dynlen(dsPath); i++)
  {
    strreplace(dsPath[i], "\\","/");
    dsPath[i] += "/bin";
    if ( _WIN32 )
    {
      mans = getFileNames(dsPath[i], "PVSS00*.exe");
    }
    else
    {
      mans = getFileNames(dsPath[i], "PVSS00*");
    }
    dynAppend(managers, mans);
  }

  for (int j = dynlen(managers); j > 0; j-- )
  {
    strreplace(managers[j], ".exe", "");
    if (strpos(managers[j], "databg")>0 || 
        strpos(managers[j], "XCheck")>0 || 
        strpos(managers[j], "archiv")>0 || 
        strpos(managers[j], "pid")>0 || 
        strpos(managers[j], "blink")>0)
      dynRemove(managers, j);
  }
  dynUnique(managers);
  dynSortAsc(managers);
  dynInsertAt(managers, "All", 1);
  
  manNameFilter.appendLines(dynlen(managers), "manName", managers);
  manNameFilter.selectLineN(0);
  manNameFilter.lineVisible(0);
}

bool fwSystemOverviewUiFunc_populateManagerStateTable(shape manStateFilter, dyn_int manStateList)
{
  manStateFilter.deleteAllLines();

  manStateFilter.tableMode(TABLE_SELECT_MULTIPLE);
  manStateFilter.selectByClick(TABLE_SELECT_LINE);
  
  manStateFilter.appendLine("stateNo", "All", "stateDesc" , "");
  for(int i = 1; i <= dynlen(manStateList); i++){
    manStateFilter.appendLine("stateNo", manStateList[i], "stateDesc" , fwSystemOverviewFunc_getStrFromState(manStateList[i]));
  }
  manStateFilter.selectLineN(0);
  manStateFilter.lineVisible(0);
}

bool fwSystemOverviewUiFunc_populateSystemTable(shape sysNoFilter, dyn_string sysNoList, dyn_string sysNameList)
{
  sysNoFilter.deleteAllLines();
 
  sysNoFilter.tableMode(TABLE_SELECT_MULTIPLE);
  sysNoFilter.selectByClick(TABLE_SELECT_LINE);
  dynInsertAt(sysNoList, "All", 1);
  dynInsertAt(sysNameList, "", 1);
  
  sysNoFilter.appendLines(dynlen(sysNoList), "sysNo",sysNoList, "sysName",sysNameList);
  sysNoFilter.selectLineN(0);
  sysNoFilter.lineVisible(0);
}

bool fwSystemOverviewUiFunc_populateHostNameTable(shape hostNameFilter, dyn_string hostNameList)
{
  hostNameFilter.deleteAllLines();
 
  hostNameFilter.tableMode(TABLE_SELECT_MULTIPLE);
  hostNameFilter.selectByClick(TABLE_SELECT_LINE);
  dynInsertAt(hostNameList, "All", 1);
  
  hostNameFilter.appendLines(dynlen(hostNameList), "hostName",hostNameList);
  hostNameFilter.selectLineN(0);
  hostNameFilter.lineVisible(0);
  
}

/*
void fwSystemOverviewUiFunc_getFsmNodeInfo(string nodeName, string& type, string& state)
{
  dyn_string nodes, exInfo;
  fwFsm_isCU(nodeName, nodes, exInfo);
  
  DebugN(nodes, exInfo);

}


int fwSystemOverviewUiFunc_FSMNAME_COL        = 0;
int fwSystemOverviewUiFunc_DEVICENAME_COL     = 1;
int fwSystemOverviewUiFunc_STATE_COL          = 2;
int fwSystemOverviewUiFunc_NODETYPE_COL       = 3;
*/

void fwSystemOverviewUiFunc_populateFsmView(shape tree, string sysName = "")
{
  dyn_string nodes, exInfo;
  string device, type;
  string rootNodeName = "FSM";
  string parentTreeNode;
  
//  DebugN(fwFsm_getDomains());
  parentTreeNode = fwSystemOverviewUiFunc_gInstanceName;
  
  tree.appendItem("", fwSystemOverviewUiFunc_gInstanceName, fwSystemOverviewUiFunc_gInstanceName);


  sysName = (sysName =="" ? getSystemName(): sysName);
  strreplace(sysName, ":", "");
  
  fwTree_getChildren(sysName + ":" + rootNodeName, nodes, exInfo);
//  DebugN(nodes);
  
  for(int i = 1; i<= dynlen(nodes); i++){
    fwSystemOverviewUiFunc_populateFsmTree(tree, parentTreeNode, sysName, nodes[i],  exInfo);
  } 
   
  tree.setOpen(fwSystemOverviewUiFunc_gInstanceName ,true);  
}

void fwSystemOverviewUiFunc_populateFsmTree(shape tree, string parentTreeNode, string sysName, string nodeName, dyn_string exInfo)
{
  dyn_string nodes;
  string type, device, state, childSysName;
  string treeNodeName, actNodeName, nodeLabel;
  dyn_string userData;
  
  fwTree_getNodeDevice(sysName  + ":" + nodeName, device, type, exInfo);
  
  actNodeName = device;
  treeNodeName = device;

  _fwTree_getNodeSys(actNodeName);
  
  fwCU_getState(actNodeName,state);
//  fwFsm_isCU(
  fwTree_getChildren(device, nodes, exInfo);
  
//  DebugN(sysName, nodeName, actNodeName, device, type, state, nodes);

  childSysName = fwTree_getNodeSys(device, exInfo);
  strreplace(childSysName, ":", "");
  
  fwTree_getNodeUserData(actNodeName, userData, exInfo);
  if(dynlen(userData) > 2)
    nodeLabel = userData[3];
  else
    nodeLabel = actNodeName;
  
  if(!tree.itemExists(treeNodeName)){
    tree.appendItem(parentTreeNode, treeNodeName, nodeLabel);
  }
  else{
    tree.setText(treeNodeName, fwSystemOverviewUiFunc_FSMNAME_COL, nodeLabel);
  }
    
//  tree.setIcon(treeNodeName, fwSystemOverviewUiFunc_FSMNAME_COL, PROJ_PATH + "pictures/fwSystemOverview/system.bmp");
  tree.setText(treeNodeName, fwSystemOverviewUiFunc_DEVICENAME_COL, device);
  tree.setText(treeNodeName, fwSystemOverviewUiFunc_STATE_COL, state);
  tree.setText(treeNodeName, fwSystemOverviewUiFunc_NODETYPE_COL, type);
  tree.setOpen(treeNodeName, true);
  
  for(int i = 1; i<= dynlen(nodes); i++){
    fwSystemOverviewUiFunc_populateFsmTree(tree, treeNodeName, childSysName, nodes[i], exInfo);
  }
}
  
void fwSystemOverviewUiFunc_refreshFsmView(shape tree)
{
  dyn_string treeNodeList = tree.children(fwSystemOverviewUiFunc_gInstanceName);
  int childno = dynlen(treeNodeList);
  
  for(int i = 1; i <= childno; i++){
    fwSystemOverviewUiFunc_refreshFsmState(tree, treeNodeList[i]);
  }
}

void fwSystemOverviewUiFunc_refreshFsmState(shape tree, string treeNodeName)
{
  string nodeName = treeNodeName;
  string state;
  dyn_string childList;
  int childno;
  
  _fwTree_getNodeSys(nodeName);
  fwCU_getState(nodeName,state);
  
  tree.setText(treeNodeName, fwSystemOverviewUiFunc_STATE_COL, state);

  childList = tree.children(treeNodeName);
  childno = dynlen(childList);
  
  for(int i = 1; i <= childno; i++){
    fwSystemOverviewUiFunc_refreshFsmState(tree, childList[i]);
  }
} 

void fwSystemOverviewUiFunc_populateMappingView(shape tree1, shape tree2, string sysName = "")
{
  fwSystemOverviewUiFunc_populateFsmView(tree2, sysName);
  fwSystemOverviewUiFunc_populateMappingSysView(tree1);
}

int fwSystemOverviewUiFunc_populateMappingSysView(shape tree)
{
  dyn_string rootDPs;
  
  fwSystemOverviewFunc_getRootNodes(rootDPs);
  
  DebugN(fwSystemOverviewUiFunc_gInstanceName, rootDPs);
  tree.appendItem("", fwSystemOverviewUiFunc_gInstanceName, fwSystemOverviewUiFunc_gInstanceName);
  for(int rootindex = 1; rootindex <= dynlen(rootDPs); rootindex++)
    fwSystemOverviewUiFunc_populateMappingSysTree(tree, rootDPs[rootindex], fwSystemOverviewUiFunc_gInstanceName);

  tree.setOpen(fwSystemOverviewUiFunc_gInstanceName ,true);
  
}


void fwSystemOverviewUiFunc_populateMappingSysTree(shape tree, string sysDpName, string parentDpName)
// Presently using recursion later to use for loop to avoid stack overload and handling loops and multiple parents    
{
  dyn_string childNodes, projDpList;
  
  string presentSystemName;
  unsigned sysNo, parentNo, sysState;
  
  unsigned childindex;

  if (sysDpName != ""){
    fwSystemOverviewFunc_getSysData(sysDpName, sysNo, presentSystemName, parentNo, childNodes, projDpList);

//To Check if the filter list is made in the view or lib of Data Struct    
//    dynAppend(gSysNoList, sysNo);
//    dynAppend(gSysNameList, presentSystemName);
  }
  DebugN(" Present System Name: " + presentSystemName);
  
  if(!tree.itemExists(sysDpName)){
    tree.appendItem(parentDpName, sysDpName, presentSystemName);
    tree.setIcon(sysDpName, fwSystemOverviewUiFunc_SYSNAME_COL, PROJ_PATH + "pictures/fwSystemOverview/system.bmp");
    tree.setText(sysDpName, fwSystemOverviewUiFunc_SYSNO_COL, sysNo);
    fwSystemOverviewFunc_getSysState(sysDpName, sysState);
    tree.setText(sysDpName, fwSystemOverviewUiFunc_STATE_COL, fwSystemOverviewFunc_getStrFromState(sysState));
//    DebugN("in fwSystemOverviewUiFunc_populateSysNProcTree: " + projDpList, childNodes);
    tree.setOpen(sysDpName, true);
    for( childindex = 1; childindex <= dynlen(childNodes); childindex++){
      fwSystemOverviewUiFunc_populateMappingSysTree(tree, fwSystemOverviewFunc_sysNoToDp(childNodes[childindex]), sysDpName);
    }
//    fwSystemOverviewUiFunc_hideColumns(tree, fwSystemOverviewUiFunc_gTreeViewMode);
  }
  else{
    DebugN("There is a loop in the dp struct or one child with many parents. Handle it later", "DPNAME: " + sysDpName);
    // There is a loop in the dp struct or one child with many parents. Handle it later
  }
}

void fwSystemOverviewUiFunc_hiliteSysNodes(shape sysTree, dyn_string fsmNodeList)
{
  dyn_string sysNameList;
  dyn_string exInfo;
  
  for(int i = 1; i <= dynlen(fsmNodeList); i++){
    dynAppend(sysNameList, fwTree_getNodeSys(fsmNodeList[i], exInfo));
  }
  
  dyn_string treeNodeList = sysTree.children(fwSystemOverviewUiFunc_gInstanceName);
  int childno = dynlen(treeNodeList);
  
  for(int i = 1; i <= childno; i++){
    fwSystemOverviewUiFunc_hiliteCorrespondingSysNodes(sysTree, treeNodeList[i], sysNameList);
  }
}

void fwSystemOverviewUiFunc_hiliteCorrespondingSysNodes(shape sysTree, string treeNodeName, dyn_string sysNameList)
{
  sysTree.setSelectedItem(treeNodeName,
                          dynContains(patternMatch(sysTree.getText(treeNodeName, fwSystemOverviewUiFunc_SYSNAME_COL),
                                                   sysNameList), TRUE) != 0);
  
  dyn_string treeNodeList = sysTree.children(treeNodeName);
  int childno = dynlen(treeNodeList);
  
  for(int i = 1; i <= childno; i++){
    fwSystemOverviewUiFunc_hiliteCorrespondingSysNodes(sysTree, treeNodeList[i], sysNameList);
  }
}
    
    
void fwSystemOverviewUiFunc_hiliteFsmNodes(shape fsmTree, dyn_string sysNodeList)
{
  string sysName;
  dyn_string sysNameList;

  for(int i = 1; i <= dynlen(sysNodeList); i++){
    fwSystemOverviewFunc_getSysName(sysNodeList[i], sysName);
    dynAppend(sysNameList, sysName);
  }
  
  dyn_string treeNodeList = fsmTree.children(fwSystemOverviewUiFunc_gInstanceName);
  int childno = dynlen(treeNodeList);

//  DebugN("In hiliteFsmNodes", sysNameList, treeNodeList);
  
  for(int i = 1; i <= childno; i++){
    fwSystemOverviewUiFunc_hiliteCorrespondingFsmNodes(fsmTree, treeNodeList[i], sysNameList);
  }
}

void fwSystemOverviewUiFunc_hiliteCorrespondingFsmNodes(shape fsmTree, string treeNodeName, dyn_string sysNameList)
{
  string sysName = treeNodeName;
  sysName = _fwTree_getNodeSys(sysName);
//  DebugN("In hiliteCorrespondingFsmNodes",treeNodeName, sysName, sysNameList);
  
  fsmTree.setSelectedItem(treeNodeName,
                          dynContains(patternMatch(sysName, sysNameList), TRUE) != 0);
  
  dyn_string treeNodeList = fsmTree.children(treeNodeName);
  int childno = dynlen(treeNodeList);
  
  for(int i = 1; i <= childno; i++){
    fwSystemOverviewUiFunc_hiliteCorrespondingFsmNodes(fsmTree, treeNodeList[i], sysNameList);
  }
}

