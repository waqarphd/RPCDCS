bool showErrorDialog = true;
mixed fwSystemOverviewFunc_mutex;

 
//Datapoint Types
const string fwSystemOverviewFunc_SYSCOLL_TYPE      = "_FwSystemOverviewList";                                  
const string fwSystemOverviewFunc_SYS_NODE_TYPE     = "_FwSystemOverviewSystem";
const string fwSystemOverviewFunc_PROJ_NODE_TYPE    = "_FwSystemOverviewProject";

//Datapoints prefix
const string fwSystemOverviewFunc_PROJVIEW_NODE     = "fw_SysView_Project_";
const string fwSystemOverviewFunc_SYSVIEW_NODE      = "fw_SysView_System_";
const string fwSystemOverviewFunc_DPNAME_ARRAY      = "fw_SysView_Collection";
                                  
//Datapoint Elements for SYSCOLL_TYPE
const string fwSystemOverviewFunc_SYSLIST_STR       = ".SysList";

//Common Datapoint Elements
const string fwSystemOverviewFunc_CURR_STATE_STR    = ".CurrentState";
const string fwSystemOverviewFunc_OK_STATE_STR      = ".OkState";

//Datapoint Elements for SYS_NODE_TYPE
const string fwSystemOverviewFunc_SYSNAME_STR       = ".SysName";
const string fwSystemOverviewFunc_SYSNO_STR         = ".SysNo";
const string fwSystemOverviewFunc_PROJLIST_STR      = ".ProjList";
const string fwSystemOverviewFunc_CHILD_STR         = ".ChildSysNoList";
const string fwSystemOverviewFunc_PARENT_STR        = ".ParentSysNo";


//Datapoint Elements for PROJ_NODE_TYPE
const string fwSystemOverviewFunc_DM_PORT_STR       = ".DmPort";
const string fwSystemOverviewFunc_DISTMAN_PORT_STR  = ".DistPort";
const string fwSystemOverviewFunc_EVM_PORT_STR      = ".EVMPort";
const string fwSystemOverviewFunc_IP_STR            = ".HostIP";
const string fwSystemOverviewFunc_HOSTNAME_STR      = ".HostName";
const string fwSystemOverviewFunc_PMON_PORT_STR     = ".PmonPort";
const string fwSystemOverviewFunc_PROJ_PATH_STR     = ".SharedDirPath";
const string fwSystemOverviewFunc_PROJ_NAME_STR     = ".ExpectedProjectName";
const string fwSystemOverviewFunc_ACT_PROJ_NAME_STR = ".ActualProjectName";

const string fwSystemOverviewFunc_USER_NAME_STR     = ".UserName";
const string fwSystemOverviewFunc_USER_PASSWORD_STR = ".UserPassword";

const string fwSystemOverviewFunc_POLL_PROJ_STR     = ".PollProject";
const string fwSystemOverviewFunc_IS_POLL_PROJ_STR  = ".IsPollingProject";

// Manager String Paths
const string fwSystemOverviewFunc_MANAGER_STR       = ".Managers";

// Manager Elements
const string fwSystemOverviewFunc_INDEX_STR         = ".Index";
const string fwSystemOverviewFunc_MODE_STR          = ".Mode";
const string fwSystemOverviewFunc_OPTIONS_STR       = ".Options";
const string fwSystemOverviewFunc_PID_STR           = ".PID";
const string fwSystemOverviewFunc_RESETMIN_STR      = ".ResetMin";
const string fwSystemOverviewFunc_RESTART_STR       = ".Restart#";
const string fwSystemOverviewFunc_SECKILL_STR       = ".SecKill";
const string fwSystemOverviewFunc_STARTTIME_STR     = ".StartTime";
const string fwSystemOverviewFunc_TYPE_STR          = ".Type";
const string fwSystemOverviewFunc_NUM_STR           = ".Num";
const string fwSystemOverviewFunc_UPDATED_STR       = ".LastUpdated";


// States

const int fwSystemOverviewFunc_STOPPED_NORMAL    = 0;
const int fwSystemOverviewFunc_INITIALIZE        = 1;
const int fwSystemOverviewFunc_RUNNING           = 2;
const int fwSystemOverviewFunc_BLOCKED           = 3;
const int fwSystemOverviewFunc_STOPPED_ABNORMAL  = 10;
const int fwSystemOverviewFunc_RAPID_RESTART     = 11;
const int fwSystemOverviewFunc_PROJNAME_MISMATCH = 12;
const int fwSystemOverviewFunc_PMON_NO_RESPONSE  = 13;
const int fwSystemOverviewFunc_PMON_NOT_RUNNING  = 14;


/*
bool openConfigFile(string &filestr)
{
  fileSelector (filestr,"/", false, "*.*" );
  // getProjectname
 // fileSelector ( string &filestr, string dirstr [, bool notUp, string patternstr] [,bool open] );
   
}
*/

/* Config File structure. The block delimiter are marked by square brackets i.e. [system]. These delimiters are case sensative
Each field entry should be seperated by newline (presently). can use ';' as a demilimiter if required
   [system]
     sysNo = $no
     sysName = $name
     parentSysNo = $parentNo
   
   [project]
     projectName = $ProjectName
     hostIP = $IPString
     hostName =$HostName        -- Redundant ????
     pmonPort = $PortNo
     dmPort = $PortNo
     evmPort = $PortNo
     userName = $name
     userPassword = $password
     sharedDir = $projPath

     [managers]
       PVSS00data = $ManNo, $OkState,
       PVSS00ctrl = $ManNo, $OkState
       PVSS00dist = $ManNo, $OkState
       ...........
       ...........
     [managers]
   [project]
   
   [system]
*/

bool fwSystemOverviewFunc_readConfigFile(string fileName)
{
  string       result;
  dyn_string   ds1;
  dyn_errClass err;

  dyn_string   sysDpList;
  int i = 0;
  
  if (!fileToString(fileName, result)){
    err = getLastError();
    if ( dynlen(err) && showErrorDialog ){
      errorDialog(err);
    }
    return(false);
  }

//  strreplace(result, " ", "");
  strreplace(result, "\t", "");
  strreplace(result, "\r", "");
  while(strreplace(result, "\n\n", "\n") != 0);

  if(!fwSystemOverviewFunc_strTagSplit(result, "[system]", ds1)){
    if (showErrorDialog){
      popupMessage("_Ui_1", "in getConfig: Error: ABORTING: Check Log");
    }
    DebugN("in getConfig: Error: ABORTING: Check Log");

    return false;
  }
  
  if (!dpExists(fwSystemOverviewFunc_DPNAME_ARRAY)){
    dpCreate(fwSystemOverviewFunc_DPNAME_ARRAY , fwSystemOverviewFunc_SYSCOLL_TYPE);
  }
  else{
  // empty the array and delete the datapoints else do other suitable operation
  //presently deleting the sysDPs
      fwSystemOverviewFunc_getSysDPList(sysDpList);
      for(i = 1; i <= dynlen(sysDpList); i++)
        fwSystemOverviewFunc_deleteSysDP(sysDpList[i]);
      
      dynClear(sysDpList);
  }
  
  if(strlen(ds1[1]) > 0)
    DebugN("in readConfigFile: There should be no free text outside the [system] block: " + ds1[1]); 

  //remove first one as it is blank array because there should be no text outside the system block
  dynRemove(ds1, 1);
  
  if(!fwSystemOverviewFunc_readSysInfo(ds1, sysDpList)){
    if (showErrorDialog){
      popupMessage("_Ui_1", "in getConfig: Error: ABORTING: Check Log");
    }
    fwSystemOverviewFunc_deleteSysDP(sysDpList);
    DebugN("in getConfig: Error: ABORTING: Check Log");
    return false;
  }
  
  fwSystemOverviewFunc_setSysDPList(sysDpList);
  return true;
}

bool fwSystemOverviewFunc_readSysInfo(dyn_string ds, dyn_string& sysDpList)
{
  string sysDp;
  
  for(int i = 1; i<= dynlen(ds); i++){
    if(!fwSystemOverviewFunc_readSysParam(ds[i], sysDp)){
      DebugN("in readSysInfo: Error in readSysParam");
      return false;
    }
    dynAppend(sysDpList, sysDp);
  }
  
  fwSystemOverviewFunc_buildSysGraph(sysDpList);
  
  return true;  
}

bool fwSystemOverviewFunc_readSysParam(string sysStr, string& sysDp) 
{
  dyn_string   ds;
  string       tempStr;
  
  dyn_string   projDpList;
  unsigned     sysNo;
  string       sysName;
  unsigned     parentNo;
  

  fwSystemOverviewFunc_strTagSplit(sysStr, "[project]", ds);
  
  if(!fwSystemOverviewFunc_strGetParam(ds[1], "sysNo", tempStr)){
    DebugN("in readSysParam: No SysNo defined in Config file");
    return false;
  }
  
  sysNo = tempStr;
  
  fwSystemOverviewFunc_strGetParam(ds[1], "sysName", sysName);
  
  fwSystemOverviewFunc_strGetParam(ds[1], "parentSysNo", tempStr);

  if(strtolower(tempStr) == "null" || tempStr == "0")
    parentNo = 0;
  else
    parentNo = tempStr;
    
  dynRemove(ds, 1);
  
  if(!fwSystemOverviewFunc_readProjInfo(ds, sysNo, projDpList)){
    for(int i = 1; i < dynlen(projDpList); i++){
      if(dpExists(projDpList[i]))
        dpDelete(projDpList[i]);
    }
    DebugN("in readSysParam: Could not read Project Info from config");
    return false;
  }
  
  sysDp = fwSystemOverviewFunc_sysNoToDp(sysNo);
  
  if(!dpExists(sysDp)){
    dpCreate(sysDp, fwSystemOverviewFunc_SYS_NODE_TYPE);
  }
  
  fwSystemOverviewFunc_setSysNodeData(sysDp, sysNo, sysName, parentNo, projDpList);
  fwSystemOverviewFunc_setSysState(sysDp, fwSystemOverviewFunc_PMON_NOT_RUNNING);
  
  return true;
} 

bool fwSystemOverviewFunc_readProjInfo(dyn_string ds, unsigned sysNo, dyn_string& projDpList)
{
  string projDp;
  
  for(int i = 1; i <= dynlen(ds); i++){
    if(!fwSystemOverviewFunc_readProjParam(ds[i], sysNo, projDp)){
      DebugN("in readProjInfo: Could not read Project Parameters from config file");
      return false;
    }
    if(strlen(projDp) > 0)
      dynAppend(projDpList, projDp);
    projDp = "";
  }
  return true;
}

bool flagGetAddr = true;
bool flagGetIP  = true;

bool fwSystemOverviewFunc_readProjParam(string projStr, unsigned sysNo, string& projDp)
{
  dyn_string ds;
  
  string hostIP, hostName, userName, userPassword, projPath, projName;
  string tempStr, dpHostName;
  unsigned dmPortNo, evmPortNo, pmonPortNo, distPortNo;
  
  fwSystemOverviewFunc_strTagSplit(projStr, "[managers]", ds);
  
  if(strlen(ds[1]) == 0){
    DebugN("in readProjParam: No project variables available");
    return false;
  }
  
  fwSystemOverviewFunc_strGetParam(ds[1], "hostIP", hostIP);
  fwSystemOverviewFunc_strGetParam(ds[1], "hostName", hostName);
  fwSystemOverviewFunc_strGetParam(ds[1], "projectName", projName);
  fwSystemOverviewFunc_strGetParam(ds[1], "sharedDir", projPath);
  fwSystemOverviewFunc_strGetParam(ds[1], "userName", userName);
  fwSystemOverviewFunc_strGetParam(ds[1], "userPassword", userPassword);
  
  fwSystemOverviewFunc_strGetParam(ds[1], "pmonPort", tempStr);
  if(strlen(tempStr) == 0 || strtolower(tempStr) == "null")
    pmonPortNo = 0;
  else if(strtolower(tempStr) == "default")
    pmonPortNo = 4999;
  else
    pmonPortNo = tempStr;
  
  fwSystemOverviewFunc_strGetParam(ds[1], "dmPort", tempStr);
  if(strlen(tempStr) == 0 || strtolower(tempStr) == "null")
    dmPortNo = 0;
  else if(strtolower(tempStr) == "default")
    dmPortNo = 4897;
  else
    dmPortNo = tempStr;
  
  fwSystemOverviewFunc_strGetParam(ds[1], "evmPort", tempStr);
  if(strlen(tempStr) == 0 || strtolower(tempStr) == "null")
    evmPortNo = 0;
  else if(strtolower(tempStr) == "default")
    evmPortNo = 4998;
  else
    evmPortNo = tempStr;
  
  fwSystemOverviewFunc_strGetParam(ds[1], "distPort", tempStr);
  if(strlen(tempStr) == 0 || strtolower(tempStr) == "null")
    distPortNo = 0;
  else if(strtolower(tempStr) == "default")
    distPortNo = 4777;
  else
    distPortNo = tempStr;
  
  if(pmonPortNo ==0 || (strlen(hostIP) ==0 && strlen(hostName) == 0)){
    DebugN("in readProjParam: Blank pmonPort munber or blank Host Address and Name");
    return false;
  }
  else if(flagGetIP && strlen(hostIP) == 0 && strlen(hostName) > 0)
    hostIP = getHostByName(hostName);
  else if(flagGetAddr && strlen(hostName) == 0 && strlen(hostIP) > 0)
    hostName = getHostByAddr(hostIP);
  
  dpHostName = hostName;
  strreplace(dpHostName, ".", "_");
  
  
  projDp = fwSystemOverviewFunc_makeProjDpName(sysNo, dpHostName, pmonPortNo);
  
  if(!dpExists(projDp)){
    dpCreate(projDp, fwSystemOverviewFunc_PROJ_NODE_TYPE);
  }

  fwSystemOverviewFunc_setProjData(projDp, projName, fwSystemOverviewFunc_PMON_NOT_RUNNING, sysNo, pmonPortNo, evmPortNo, dmPortNo, distPortNo, projPath, hostIP, hostName, userName, userPassword);
  
  dynRemove(ds, 1);
  if(!fwSystemOverviewFunc_readManInfo(ds, projDp)){
    DebugN("in readProjParam: Problem while reading Managers Info");
    return false;
  }
  return true;
}

bool fwSystemOverviewFunc_readManInfo(dyn_string ds, string projDp)
{
  dyn_string     ds1;
  dyn_string     ds2;
  
  dyn_int        cStat, okStat, pid, num;
  dyn_uint       index, mode, resetMin, restart, secKill;
  dyn_time       startTime;
  dyn_string     type, opt;
  dyn_bool       lastUpdated;  
      
  if(dynlen(ds)!=1){
    DebugN("in readManInfo: Problem while reading config file. Only one set of Managers tag supported");
    return false;
  }
  strreplace(ds[1]," ","");
  while(strreplace(ds[1],"\n\n", "\n") != 0);
  ds1 = strsplit(ds[1], "\n");
//  DebugN("in readManInfo: ds1=" + ds1);
  
  for(int i = 1; i <= dynlen(ds1); i++){
    ds2 = strsplit(ds1[i], "=,");
    
    dynAppend(type, ds2[1]);
    dynAppend(num, ds2[2]);
    dynAppend(okStat, ds2[3]);
    dynAppend(opt, "");
    dynAppend(index, i);
    dynAppend(cStat, fwSystemOverviewFunc_PMON_NOT_RUNNING);
    dynAppend(pid, -1);
    dynAppend(mode, 0);
    dynAppend(startTime, "");
    dynAppend(resetMin, "");
    dynAppend(restart, "");
    dynAppend(secKill, "");
    dynAppend(lastUpdated, FALSE);
  }
  
  fwSystemOverviewFunc_setProjManagersData(projDp, type, num, opt, mode, index, cStat, okStat, pid, resetMin, restart, secKill, startTime, lastUpdated);
  
  return true;
}

bool fwSystemOverviewFunc_buildSysGraph(dyn_string sysDpList)
{
  dyn_uint leafNodes, orphanNodes, floatingNodes, intermediateNodes;
  dyn_dyn_string misdirectedNodes;
  unsigned presentSystemNo, parentNo;
  dyn_uint childNodes;
  string sysName, sysDp;
  dyn_string projDpList;
  
  int j;
 
  // populate child array of each node
  for(j = 1; j <= dynlen(sysDpList); j++){
    
    fwSystemOverviewFunc_getSysData(sysDpList[j], presentSystemNo, sysName, parentNo, childNodes, projDpList);

    if(parentNo == 0){
      continue;
    }
    
    sysDp = fwSystemOverviewFunc_sysNoToDp(parentNo);
    
    if(!dpExists(sysDp)){
      dynAppend(misdirectedNodes[j], parentNo);      //remove the link from the DP and add it to misdirected list
      parentNo = 0;
      fwSystemOverviewFunc_setSysParentNode(sysDpList[j], parentNo);
      continue;
    }
    
    fwSystemOverviewFunc_getSysChildNodes(sysDp, childNodes);
    
    if(dynContains(childNodes, presentSystemNo) == 0)                //the list of the childrens in the parent list
      dynAppend(childNodes, presentSystemNo); 
    
    dynSortAsc(childNodes);
    
    fwSystemOverviewFunc_setSysChildNodes(sysDp, childNodes);//    dpSet(SYSVIEW_NODE + parentNo + CHILD_STR, childNodes);
  }
//  DebugN(dpNameList);

  for(j = 1; j <= dynlen(sysDpList); j++){
    
    fwSystemOverviewFunc_getSysData(sysDpList[j], presentSystemNo, sysName, parentNo, childNodes, projDpList);
//    DebugN(parentNo, childNodes, presentSystemNo);
    
    if(parentNo == 0 && dynlen(childNodes) == 0 && dynContains(floatingNodes, presentSystemNo) == 0)
       dynAppend(floatingNodes, presentSystemNo);
    else if(parentNo != 0 && dynlen(childNodes) == 0 && dynContains(leafNodes, presentSystemNo) == 0)
       dynAppend(leafNodes, presentSystemNo);
    else if(parentNo == 0 && dynlen(childNodes) != 0 && dynContains(orphanNodes, presentSystemNo) == 0)
       dynAppend(orphanNodes, presentSystemNo);
    else if(parentNo != 0 && dynlen(childNodes) != 0 && dynContains(intermediateNodes, presentSystemNo) == 0)
       dynAppend(intermediateNodes, presentSystemNo);
  }
  DebugN("PARENTS: " + orphanNodes + " CHILDRENS: "+ leafNodes + " FLOATING: " + floatingNodes + " INTERMEDIATE: " + intermediateNodes);
  
  if(dynlen(misdirectedNodes) > 0) 
    for(int i = 1; i <= dynlen(sysDpList); i++)
      if(dynlen(misdirectedNodes[i]) > 0)
        DebugN("DP NAME: " + sysDpList[i] + " MIS-DIRECTED: " + misdirectedNodes[i]);
}

//Get the parameter of the tag; format 'tag'  = 'variable' which is delimited by newline.
bool fwSystemOverviewFunc_strGetParam(string source, string tag, string& result)
{
  string str;
  int beg, end;

  result = str;
  
  beg = strpos(source, tag);
  
  if(beg == -1){
/*    if (showErrorDialog){
      popupMessage("_Ui_1", "in strGetParam: No Tag Found: " + tag  + "in string: " + source);
    }
*/  DebugN("in strGetParam: No Tag Found: " + tag  + "in string: " + source);
    return false;
  }
  
  source = substr(source, beg);
  
  beg = strpos(source, "=");
  if(beg == -1){
    DebugN("in strGetParam: No '=' found in string: " + source);
    return false;
  }
  
  end = strpos(source, "\n");
  if(end == -1){
    DebugN("in strGetParam: No newline character in string: " + source);
    end = strlen(source);
  }

  str = substr(source, beg+1, end-beg-1);

  str = strltrim(str, "\n\t\" ");
  str = strrtrim(str, "\n\t\" ");
  result = str;

  return true;
}


// Split the string delimiting on the tag
//returns the splitted string. The first string array contains the test outside the "tag block"
bool fwSystemOverviewFunc_strTagSplit(string source, string tag, dyn_string& result)
{
  dyn_string ds;
  string str, tempStr;

  int pos;
  bool isEnclosed = false;

  //Remove first and last newline, tab, spaces
  source = strltrim(source,"\n\t ");
  source = strrtrim(source,"\n\t ");

  pos = strpos(source, tag);
  if(pos == -1){
    DebugN("strTagSplit: No " + tag + " tag found");
    return false;
  }
  while( pos != -1){
    if(pos > 0){
      tempStr = substr(source, 0, pos);
      tempStr = strrtrim(tempStr,"\n\t ");

      if(isEnclosed)
        dynAppend(ds, tempStr);
      else
        str += tempStr;
    }
    isEnclosed = !isEnclosed;
    source = substr(source, pos+strlen(tag));
    source = strltrim(source,"\n\t ");
    pos = strpos(source, tag);
  }
  
  if(strlen(source) > 0)
    str = str + source + "\n";
  
  strreplace(str, "\n\n", "\n");

  dynInsertAt(ds,str,1);

  result = ds;
  
  if(isEnclosed){
    DebugN("in strTagSplit: Mismatch Delimiter: " + tag, "Processed String: " + ds, "String: "+ str);
    return false;
  }
  
  return true;
}

int fwSystemOverviewFunc_pollSystems()
{
  dyn_string sysDpList, projDpList, dpeList;
  dyn_bool valueList;
  
  int i, j;
  
  fwSystemOverviewFunc_getSysDPList(sysDpList);
  
  for(i = 1; i <= dynlen(sysDpList); i++){
    fwSystemOverviewFunc_getProjDPList(sysDpList[i], projDpList);
    
    for(j = 1; j <= dynlen(projDpList); j++){
      dynAppend(dpeList, projDpList[j] + fwSystemOverviewFunc_POLL_PROJ_STR);
      dynAppend(valueList, TRUE);
    }
//      fwSystemOverviewFunc_pollProject(projDpList[j]);
  }
  
  dpSet(dpeList, valueList);
  return 0;   
}

int fwSystemOverviewFunc_connectPollProjectDpe()
{
  dyn_string sysDpList, projDpList;
  int i, j;
  
  fwSystemOverviewFunc_getSysDPList(sysDpList);
  
  for(i = 1; i <= dynlen(sysDpList); i++){
    fwSystemOverviewFunc_getProjDPList(sysDpList[i], projDpList);
  
    for(j = 1; j <= dynlen(projDpList); j++){
      dpConnect("fwSystemOverviewFunc_wfPollProject", FALSE, projDpList[j] + fwSystemOverviewFunc_POLL_PROJ_STR);
    }
  }
  return 0;   
}

int fwSystemOverviewFunc_disconnectPollProjectDpe()
{
  dyn_string sysDpList, projDpList;
  int i, j;
  dyn_errClass err;
  
  fwSystemOverviewFunc_getSysDPList(sysDpList);
  
  for(i = 1; i <= dynlen(sysDpList); i++){
    fwSystemOverviewFunc_getProjDPList(sysDpList[i], projDpList);
  
    for(j = 1; j <= dynlen(projDpList); j++){
//      err = dpDisconnect("fwSystemOverviewFunc_wfPollProject", projDpList[j] + fwSystemOverviewFunc_POLL_PROJ_STR);
      if(dpDisconnect("fwSystemOverviewFunc_wfPollProject", projDpList[j] + fwSystemOverviewFunc_POLL_PROJ_STR) == -1){
        err = getLastError();
        if ( dynlen(err)){
          DebugN(sysDpList[i], projDpList[j], projDpList[j] + fwSystemOverviewFunc_POLL_PROJ_STR, err);
        }
      }
    }
  }
  return 0;   
}

int fwSystemOverviewFunc_wfPollProject(string dpeName, bool value)
{
  string projDp = dpeName;
  
  strreplace(projDp, getSystemName(), "");
  strreplace(projDp, fwSystemOverviewFunc_POLL_PROJ_STR + ":_online.._value", "");
  fwSystemOverviewFunc_pollProject(projDp);
}

int fwSystemOverviewFunc_getIsPolling(string projDp, bool& isPolling)
{
  return dpGet(projDp + fwSystemOverviewFunc_IS_POLL_PROJ_STR, isPolling);
}

int fwSystemOverviewFunc_setIsPolling(string projDp, bool isPolling)
{
  return dpSet(projDp + fwSystemOverviewFunc_IS_POLL_PROJ_STR, isPolling);
}

bool fwSystemOverviewFunc_pollProject(string projDp)
{
  dyn_string ipAddr, userName, userPassword;
  unsigned sysNo;
  unsigned pMonPort;
  string sharedDir;
  bool isPolling = false;
  int manCount, i, idx, j, k;
  
  int currProjStat;

  int            err;
  dyn_dyn_string ddsResult, ddsResultStati;
  dyn_bool       pat1, pat2, pat3;
  dyn_string     typeTemp, numTemp;
  
  dyn_int        cStat, okStat, pid, num;
  dyn_uint       index, mode, resetMin, restart, secKill;
  dyn_time       startTime;
  dyn_string     type, opt;
  dyn_bool       lastUpdated;  
  string         actProjName;
  
  if (projDp != ""){
    synchronized(fwSystemOverviewFunc_mutex){
      fwSystemOverviewFunc_getIsPolling(projDp, isPolling);
      fwSystemOverviewFunc_setIsPolling(projDp, TRUE);
    }
    
    if(isPolling == TRUE)
      return false;
     
    fwSystemOverviewFunc_getProjAccessData(projDp, ipAddr, pMonPort, userName,userPassword, sharedDir);
    fwSystemOverviewFunc_getProjManagersData(projDp, type, num, opt, mode, index, cStat, okStat, pid, resetMin, restart, secKill, startTime, lastUpdated);   
    
    for(j = 1; j <= dynlen(type); j++){
      typeTemp[j] = strtolower(type[j]);
      numTemp[j] = num[j];
      lastUpdated[j] = FALSE;
    }
  }
  else{
    DebugN("Error in pollProject: NULL DP");
    return false;
  }
  
  if((err = pmon_query(userName+"#"+userPassword+"#PROJECT:", ipAddr, pMonPort, ddsResult, false, true)) == false){
    if(strlen(ddsResult[1][1]) > 0){
      actProjName = ddsResult[1][1];
      err = pmon_query(userName+"#"+userPassword+"#MGRLIST:LIST", ipAddr, pMonPort, ddsResult, true, true);
      err = pmon_query(userName+"#"+userPassword+"#MGRLIST:STATI", ipAddr, pMonPort, ddsResultStati, true, true);
  
      if ( err )
      {
        pmon_warningOutput("In pollProject: errPmonNotRunning", -1, false);
        //return;
      }
      else{
        manCount = dynlen(ddsResult);
        for (i = 1; i <= manCount; i++)        // to include code for updating the changed status of the managers
        {
          if ( !isMotif() ) strreplace(ddsResult[i][1], "&", "&&");
          pat1 = patternMatch(strtolower(ddsResult[i][1]), typeTemp);
          pat2 = patternMatch((int)ddsResultStati[i][5], numTemp);
          
          for(k = 1; k <= dynlen(pat1); k++){  // Considering that the Manager type and Num forms a unique ID adding to array. 
            pat3[k] = pat1[k] & pat2[k];      // Otherwise option field can also be considered. 
          }
          if(dynCount(pat3, TRUE) == 1){
            j = dynContains(pat3, TRUE);
            type[j] = ddsResult[i][1];
            opt[j] = ( dynlen(ddsResult[i]) > 5)?ddsResult[i][6]:"";
            index[j] = i;
            cStat[j] = ddsResultStati[i][1];
            pid[j] = ddsResultStati[i][2];
            mode[j] = ddsResultStati[i][3];
            startTime[j] = ddsResultStati[i][4];
            num[j] = ddsResultStati[i][5];
            resetMin[j] = ddsResult[i][4];
            restart[j] = ddsResult[i][5];
            secKill[j] = ddsResult[i][3];
            lastUpdated[j] = TRUE;               
          }
          else if(dynCount(pat3, TRUE) == 0){
            dynAppend(type, ddsResult[i][1]);
            dynAppend(opt, ( dynlen(ddsResult[i]) > 5)?ddsResult[i][6]:"");
            dynAppend(index, i);
            dynAppend(cStat, ddsResultStati[i][1]);
            dynAppend(pid, ddsResultStati[i][2]);
            dynAppend(mode, ddsResultStati[i][3]);
            dynAppend(startTime, ddsResultStati[i][4]);
            dynAppend(num, ddsResultStati[i][5]);
            dynAppend(resetMin, ddsResult[i][4]);
            dynAppend(restart, ddsResult[i][5]);
            dynAppend(secKill, ddsResult[i][3]);
            dynAppend(lastUpdated, TRUE);
          }
          else {
            do{
              j = dynContains(pat3, TRUE);
              pat3[j] = FALSE;
            } while(lastUpdated[j] != FALSE);
            
            type[j] = ddsResult[i][1];
            opt[j] = ( dynlen(ddsResult[i]) > 5)?ddsResult[i][6]:"";
            index[j] = i;
            cStat[j] = ddsResultStati[i][1];
            pid[j] = ddsResultStati[i][2];
            mode[j] = ddsResultStati[i][3];
            startTime[j] = ddsResultStati[i][4];
            num[j] = ddsResultStati[i][5];
            resetMin[j] = ddsResult[i][4];
            restart[j] = ddsResult[i][5];
            secKill[j] = ddsResult[i][3];
            lastUpdated[j] = TRUE;               
          }
        }
      }
      fwSystemOverviewFunc_setProjDataNState(projDp, actProjName, type, num, opt, mode, index, cStat, pid, resetMin, restart, secKill, startTime, lastUpdated);   // for comman manager struct
    }
    else{
//    DebugTN("PMON NOT RESPONDING: ",projDp, ddsResult);
      fwSystemOverviewFunc_setProjPmonNotResponding(projDp);
    }
  }
  else{
//    DebugTN("PMON NOT RUNNING: ",projDp, ddsResult);
    fwSystemOverviewFunc_setProjPmonNotRunning(projDp);
  }
//  DebugN("in pollProject: "+projDp, err);
  fwSystemOverviewFunc_setIsPolling(projDp, FALSE);
}

string fwSystemOverviewFunc_getStrFromState(int stat)
{
  string str;
  
  switch(stat){
    case fwSystemOverviewFunc_STOPPED_NORMAL:
      str = "STOPPED";
      break;
    case fwSystemOverviewFunc_INITIALIZE:
      str = "INITIALIZE";
      break;
    case fwSystemOverviewFunc_RUNNING:
      str = "RUNNING";
      break;
    case fwSystemOverviewFunc_BLOCKED:
      str = "BLOCKED";
      break;
    case fwSystemOverviewFunc_STOPPED_ABNORMAL:
      str = "STOPPED ABNORMAL";
      break;
    case fwSystemOverviewFunc_RAPID_RESTART:
      str = "RAPID RESTART";
      break;
    case fwSystemOverviewFunc_PROJNAME_MISMATCH:
      str = "PROJECT NAME MISMATCH";
      break;
    case fwSystemOverviewFunc_PMON_NO_RESPONSE:
      str = "PMON NOT RESPONDING";
      break;
    case fwSystemOverviewFunc_PMON_NOT_RUNNING:
      str = "PMON NOT RUNNING";
      break;
    default:
      str = "STATE NOT DEFINED";
      break;
   }
  
  return str;
}

string fwSystemOverviewFunc_getStateFromStr(string stat)
{
  int str;
  
  switch(stat){
    case "STOPPED":
      str = fwSystemOverviewFunc_STOPPED_NORMAL;
      break;
    case "INITIALIZE":
      str = fwSystemOverviewFunc_INITIALIZE;
      break;
    case "RUNNING":
      str = fwSystemOverviewFunc_RUNNING;
      break;
    case "BLOCKED":
      str = fwSystemOverviewFunc_BLOCKED;
      break;
    case "STOPPED ABNORMAL":
      str = fwSystemOverviewFunc_STOPPED_ABNORMAL;
      break;
    case "RAPID RESTART":
      str = fwSystemOverviewFunc_RAPID_RESTART;
      break;
    case "PROJECT NAME MISMATCH":
      str = fwSystemOverviewFunc_PROJNAME_MISMATCH;
      break;
    case "PMON NOT RESPONDING":
      str = fwSystemOverviewFunc_PMON_NO_RESPONSE;
      break;
    case "PMON NOT RUNNING":
      str = fwSystemOverviewFunc_PMON_NOT_RUNNING;
      break;
    default:
      str = -1;
      break;
   }
  
  return str;
}

int fwSystemOverviewFunc_setProjPmonNotRunning(string projDp)
{
  return dpSet(projDp + fwSystemOverviewFunc_CURR_STATE_STR, fwSystemOverviewFunc_PMON_NOT_RUNNING);
}

int fwSystemOverviewFunc_setProjPmonNotResponding(string projDp)
{
  return dpSet(projDp + fwSystemOverviewFunc_CURR_STATE_STR, fwSystemOverviewFunc_PMON_NO_RESPONSE);
}

int fwSystemOverviewFunc_getProjManagersType(string projDp, dyn_string& type)
{  
  return dpGet(projDp + fwSystemOverviewFunc_MANAGER_STR + fwSystemOverviewFunc_TYPE_STR, type);
}
int fwSystemOverviewFunc_getProjManagersData(string projDp, dyn_string& type, dyn_int& num, dyn_string& opt, dyn_uint& mode, dyn_uint& index, dyn_int& cStat, dyn_int& okStat,
                        dyn_int& pid, dyn_uint& resetMin, dyn_uint& restart, dyn_uint& secKill, dyn_time& startTime, dyn_bool& lastUpdated)
{
  return dpGet(projDp + fwSystemOverviewFunc_MANAGER_STR + fwSystemOverviewFunc_OK_STATE_STR, okStat,
               projDp + fwSystemOverviewFunc_MANAGER_STR + fwSystemOverviewFunc_NUM_STR, num,   
               projDp + fwSystemOverviewFunc_MANAGER_STR + fwSystemOverviewFunc_TYPE_STR, type,
               projDp + fwSystemOverviewFunc_MANAGER_STR + fwSystemOverviewFunc_INDEX_STR, index,
               projDp + fwSystemOverviewFunc_MANAGER_STR + fwSystemOverviewFunc_MODE_STR, mode, 
               projDp + fwSystemOverviewFunc_MANAGER_STR + fwSystemOverviewFunc_OPTIONS_STR, opt,
               projDp + fwSystemOverviewFunc_MANAGER_STR + fwSystemOverviewFunc_PID_STR, pid,
               projDp + fwSystemOverviewFunc_MANAGER_STR + fwSystemOverviewFunc_RESETMIN_STR, resetMin,
               projDp + fwSystemOverviewFunc_MANAGER_STR + fwSystemOverviewFunc_RESTART_STR, restart,
               projDp + fwSystemOverviewFunc_MANAGER_STR + fwSystemOverviewFunc_SECKILL_STR, secKill,
               projDp + fwSystemOverviewFunc_MANAGER_STR + fwSystemOverviewFunc_STARTTIME_STR, startTime,
               projDp + fwSystemOverviewFunc_MANAGER_STR + fwSystemOverviewFunc_CURR_STATE_STR, cStat,
               projDp + fwSystemOverviewFunc_MANAGER_STR + fwSystemOverviewFunc_UPDATED_STR, lastUpdated
               ); 
}

int fwSystemOverviewFunc_setProjManagersData(string projDp, dyn_string type, dyn_int num, dyn_string opt, dyn_uint mode, dyn_uint index, dyn_int cStat, dyn_int okStat,
                        dyn_int pid, dyn_uint resetMin, dyn_uint restart, dyn_uint secKill, dyn_time startTime, dyn_bool lastUpdated)
{
  dyn_string dpNameList;
  dyn_anytype value;
  
  dpNameList[1] = projDp + fwSystemOverviewFunc_MANAGER_STR + fwSystemOverviewFunc_OK_STATE_STR; value[1] = okStat;
  dpNameList[2] = projDp + fwSystemOverviewFunc_MANAGER_STR + fwSystemOverviewFunc_NUM_STR; value[2] = num;   
  dpNameList[3] = projDp + fwSystemOverviewFunc_MANAGER_STR + fwSystemOverviewFunc_TYPE_STR; value[3] = type;
  dpNameList[4] = projDp + fwSystemOverviewFunc_MANAGER_STR + fwSystemOverviewFunc_INDEX_STR; value[4] = index;
  dpNameList[5] = projDp + fwSystemOverviewFunc_MANAGER_STR + fwSystemOverviewFunc_MODE_STR; value[5] = mode; 
  dpNameList[6] = projDp + fwSystemOverviewFunc_MANAGER_STR + fwSystemOverviewFunc_OPTIONS_STR; value[6] = opt;
  dpNameList[7] = projDp + fwSystemOverviewFunc_MANAGER_STR + fwSystemOverviewFunc_PID_STR; value[7] = pid;
  dpNameList[8] = projDp + fwSystemOverviewFunc_MANAGER_STR + fwSystemOverviewFunc_RESETMIN_STR; value[8] = resetMin;
  dpNameList[9] = projDp + fwSystemOverviewFunc_MANAGER_STR + fwSystemOverviewFunc_RESTART_STR; value[9] = restart;
  dpNameList[10] = projDp + fwSystemOverviewFunc_MANAGER_STR + fwSystemOverviewFunc_SECKILL_STR; value[10] = secKill;
  dpNameList[11] = projDp + fwSystemOverviewFunc_MANAGER_STR + fwSystemOverviewFunc_STARTTIME_STR; value[11] = startTime;
  dpNameList[12] = projDp + fwSystemOverviewFunc_MANAGER_STR + fwSystemOverviewFunc_CURR_STATE_STR; value[12] = cStat;
  dpNameList[13] = projDp + fwSystemOverviewFunc_MANAGER_STR + fwSystemOverviewFunc_UPDATED_STR; value[13] = lastUpdated; 
  
  return dpSet(dpNameList, value);
/*  return dpSet(projDp + MANAGER_STR + OK_STATE_STR, okStat,
               projDp + MANAGER_STR + NUM_STR, num,   
               projDp + MANAGER_STR + TYPE_STR, type,
               projDp + MANAGER_STR + INDEX_STR, index,
               projDp + MANAGER_STR + MODE_STR, mode, 
               projDp + MANAGER_STR + OPTIONS_STR, opt,
               projDp + MANAGER_STR + PID_STR, pid,
               projDp + MANAGER_STR + RESETMIN_STR, resetMin,
               projDp + MANAGER_STR + RESTART_STR, restart,
               projDp + MANAGER_STR + SECKILL_STR, secKill,
               projDp + MANAGER_STR + STARTTIME_STR, startTime,
               projDp + MANAGER_STR + CURR_STATE_STR, cStat,
               projDp + MANAGER_STR + UPDATED_STR, lastUpdated
               ); */
}

int fwSystemOverviewFunc_setProjDataNState(string projDp, string actProjName, dyn_string& type, dyn_int& num, dyn_string& opt, dyn_uint& mode, dyn_uint& index, dyn_int& cStat, 
                        dyn_int& pid, dyn_uint& resetMin, dyn_uint& restart, dyn_uint& secKill, dyn_time& startTime, dyn_bool lastUpdated)
{
  dyn_int okStat;
  dyn_bool mask;
  int projCStat;
  string projName;
  int i;
  
  dyn_string dpNameList;
  dyn_anytype value;
  
  bool useMask = TRUE;
  
  dpGet(projDp + fwSystemOverviewFunc_MANAGER_STR + fwSystemOverviewFunc_OK_STATE_STR, okStat,
        projDp + fwSystemOverviewFunc_PROJ_NAME_STR, projName);
  
  for(i = 1; i <= dynlen(cStat); i++){
    if(dynlen(okStat) >= i && lastUpdated[i] == TRUE)
      dynAppend(mask, TRUE);
    else
      dynAppend(mask, FALSE);
    
    if(cStat[i] == 0){
      if (pid[i] == -1)
        cStat[i] = (mode[i] == PMON_START_MANUAL) ? 0 : fwSystemOverviewFunc_STOPPED_ABNORMAL;
      else if (pid[i] == -2)   // restarting too rapidly
        cStat[i] = fwSystemOverviewFunc_RAPID_RESTART;
    }
  }

  if(useMask)
    projCStat = dynMax(cStat, mask);
  else
    projCStat = dynMax(cStat);
  
  if(projName != actProjName)
    projCStat = fwSystemOverviewFunc_PROJNAME_MISMATCH;

  dpNameList[1] = projDp + fwSystemOverviewFunc_CURR_STATE_STR; value[1] = projCStat;
  dpNameList[2] = projDp + fwSystemOverviewFunc_ACT_PROJ_NAME_STR; value[2] = actProjName;
  dpNameList[3] = projDp + fwSystemOverviewFunc_MANAGER_STR + fwSystemOverviewFunc_NUM_STR; value[3] = num;   
  dpNameList[4] = projDp + fwSystemOverviewFunc_MANAGER_STR + fwSystemOverviewFunc_TYPE_STR; value[4] = type;
  dpNameList[5] = projDp + fwSystemOverviewFunc_MANAGER_STR + fwSystemOverviewFunc_INDEX_STR; value[5] = index;
  dpNameList[6] = projDp + fwSystemOverviewFunc_MANAGER_STR + fwSystemOverviewFunc_MODE_STR; value[6] = mode; 
  dpNameList[7] = projDp + fwSystemOverviewFunc_MANAGER_STR + fwSystemOverviewFunc_OPTIONS_STR; value[7] = opt;
  dpNameList[8] = projDp + fwSystemOverviewFunc_MANAGER_STR + fwSystemOverviewFunc_PID_STR; value[8] = pid;
  dpNameList[9] = projDp + fwSystemOverviewFunc_MANAGER_STR + fwSystemOverviewFunc_RESETMIN_STR; value[9] = resetMin;
  dpNameList[10] = projDp + fwSystemOverviewFunc_MANAGER_STR + fwSystemOverviewFunc_RESTART_STR; value[10] = restart;
  dpNameList[11] = projDp + fwSystemOverviewFunc_MANAGER_STR + fwSystemOverviewFunc_SECKILL_STR; value[11] = secKill;
  dpNameList[12] = projDp + fwSystemOverviewFunc_MANAGER_STR + fwSystemOverviewFunc_STARTTIME_STR; value[12] = startTime;
  dpNameList[13] = projDp + fwSystemOverviewFunc_MANAGER_STR + fwSystemOverviewFunc_CURR_STATE_STR; value[13] = cStat;
  dpNameList[14] = projDp + fwSystemOverviewFunc_MANAGER_STR + fwSystemOverviewFunc_UPDATED_STR; value[14] = lastUpdated; 
  
  return dpSet(dpNameList, value);
/*  return dpSet(projDp + CURR_STATE_STR, projCStat,
               projDp + ACT_PROJ_NAME_STR, projName,
               projDp + MANAGER_STR + NUM_STR, num,   
               projDp + MANAGER_STR + TYPE_STR, type,
               projDp + MANAGER_STR + INDEX_STR, index,
               projDp + MANAGER_STR + MODE_STR, mode, 
               projDp + MANAGER_STR + OPTIONS_STR, opt,
               projDp + MANAGER_STR + PID_STR, pid,
               projDp + MANAGER_STR + RESETMIN_STR, resetMin,
               projDp + MANAGER_STR + RESTART_STR, restart,
               projDp + MANAGER_STR + SECKILL_STR, secKill,
               projDp + MANAGER_STR + STARTTIME_STR, startTime,
               projDp + MANAGER_STR + CURR_STATE_STR, cStat,
               projDp + MANAGER_STR + UPDATED_STR, lastUpdated
               );   */
}

int fwSystemOverviewFunc_getProjAccessData(string projDp, string &hostName, unsigned &pmonPortNo, string &userName, string &userPassword, string &sharedDir)
{
  return dpGet(projDp + fwSystemOverviewFunc_HOSTNAME_STR, hostName, 
               projDp + fwSystemOverviewFunc_PMON_PORT_STR, pmonPortNo, 
               projDp + fwSystemOverviewFunc_USER_NAME_STR, userName,
               projDp + fwSystemOverviewFunc_USER_PASSWORD_STR, userPassword,
               projDp + fwSystemOverviewFunc_PROJ_PATH_STR, sharedDir);
}

int fwSystemOverviewFunc_getProjData(string projDp, string& projName, int& projCStat, unsigned& sysNo, unsigned &pmonPortNo, unsigned &eventPortNo, 
                unsigned &dmPortNo, unsigned &distPortNo, string &sharedDir, string& hostIp, string& hostName)
{
  return dpGet(projDp + fwSystemOverviewFunc_PROJ_NAME_STR, projName, 
               projDp + fwSystemOverviewFunc_SYSNO_STR, sysNo, 
               projDp + fwSystemOverviewFunc_PMON_PORT_STR, pmonPortNo, 
               projDp + fwSystemOverviewFunc_EVM_PORT_STR, eventPortNo,
               projDp + fwSystemOverviewFunc_DM_PORT_STR, dmPortNo,
               projDp + fwSystemOverviewFunc_DISTMAN_PORT_STR, distPortNo,
               projDp + fwSystemOverviewFunc_IP_STR, hostIp,
               projDp + fwSystemOverviewFunc_HOSTNAME_STR, hostName,
               projDp + fwSystemOverviewFunc_PROJ_PATH_STR, sharedDir);
}

int fwSystemOverviewFunc_setProjData(string projDp, string projName, int projCStat, unsigned sysNo, unsigned pmonPortNo, unsigned eventPortNo, 
                unsigned dmPortNo, unsigned distPortNo, string sharedDir, string hostIp, string hostName, string userName, string userPassword)
{
  dyn_string dpNameList;
  dyn_anytype value;
  
  dpNameList[1] = projDp + fwSystemOverviewFunc_PROJ_NAME_STR; value[1] = projName; 
  dpNameList[2] = projDp + fwSystemOverviewFunc_SYSNO_STR; value[2] = sysNo; 
  dpNameList[3] = projDp + fwSystemOverviewFunc_PMON_PORT_STR; value[3] = pmonPortNo; 
  dpNameList[4] = projDp + fwSystemOverviewFunc_USER_NAME_STR; value[4] = userName;
  dpNameList[5] = projDp + fwSystemOverviewFunc_USER_PASSWORD_STR; value[5] = userPassword;
  dpNameList[6] = projDp + fwSystemOverviewFunc_EVM_PORT_STR; value[6] = eventPortNo;
  dpNameList[7] = projDp + fwSystemOverviewFunc_DM_PORT_STR; value[7] = dmPortNo;
  dpNameList[8] = projDp + fwSystemOverviewFunc_DISTMAN_PORT_STR; value[8] = distPortNo;
  dpNameList[9] = projDp + fwSystemOverviewFunc_IP_STR; value[9] = hostIp;
  dpNameList[10] = projDp + fwSystemOverviewFunc_HOSTNAME_STR; value[10] = hostName;
  dpNameList[11] = projDp + fwSystemOverviewFunc_PROJ_PATH_STR; value[11] = sharedDir;
  
  return dpSet(dpNameList, value);
/* return dpSet(projDp + PROJ_NAME_STR, projName, 
               projDp + SYSNO_STR, sysNo, 
               projDp + PMON_PORT_STR, pmonPortNo, 
               projDp + USER_NAME_STR, userName,
               projDp + USER_PASSWORD_STR, userPassword,
               projDp + EVM_PORT_STR, eventPortNo,
               projDp + DM_PORT_STR, dmPortNo,
               projDp + DISTMAN_PORT_STR, distPortNo,
               projDp + IP_STR, hostIp,
               projDp + HOSTNAME_STR, hostName,
               projDp + PROJ_PATH_STR, sharedDir);*/
}

int fwSystemOverviewFunc_getSysDPList(dyn_string& sysDpList)
{
  return dpGet(fwSystemOverviewFunc_DPNAME_ARRAY + fwSystemOverviewFunc_SYSLIST_STR, sysDpList);
}

int fwSystemOverviewFunc_setSysDPList(dyn_string sysDpList)
{
  return dpSet(fwSystemOverviewFunc_DPNAME_ARRAY + fwSystemOverviewFunc_SYSLIST_STR, sysDpList);
}
 
int fwSystemOverviewFunc_getProjDPList(string sysDp, dyn_string& projDpList)
{
  return dpGet(sysDp + fwSystemOverviewFunc_PROJLIST_STR, projDpList);
}
 
int fwSystemOverviewFunc_setProjDPList(string sysDp, dyn_string projDpList)
{
  return dpSet(sysDp + fwSystemOverviewFunc_PROJLIST_STR, projDpList);
}

// int getParentNode(string dpName, unsigned &parentNode)
// {
//   return dpGet(dpName + PARENT_STR, parentNode);
// }

int fwSystemOverviewFunc_setSysParentNode(string dpName, unsigned parentNode)
{
  return dpSet(dpName + fwSystemOverviewFunc_PARENT_STR, parentNode);
}

// int getChildNodes(string dpName, dyn_uint &childNodes)
// {
//   return dpGet(dpName + CHILD_STR, childNodes);
// }

// int setChildNodes(string dpName, dyn_uint childNodes)
// {
//   return dpSet(dpName + CHILD_STR, childNodes);
// }

int fwSystemOverviewFunc_setSysNodeData(string sysDp, unsigned sysNo, string sysName, unsigned parentNo, dyn_string projDpList)
{
  return dpSet(sysDp + fwSystemOverviewFunc_SYSNO_STR, sysNo, 
               sysDp + fwSystemOverviewFunc_SYSNAME_STR , sysName,
               sysDp + fwSystemOverviewFunc_PARENT_STR , parentNo,
               sysDp + fwSystemOverviewFunc_PROJLIST_STR , projDpList);
}

int fwSystemOverviewFunc_setSysState(string sysDp, unsigned sysState)
{
  return dpSet(sysDp + fwSystemOverviewFunc_CURR_STATE_STR, sysState);
}

string fwSystemOverviewFunc_sysNoToDp(unsigned sysNo)
{
  return fwSystemOverviewFunc_SYSVIEW_NODE + sysNo;
}

int fwSystemOverviewFunc_sysDpToNo(string sysDp)
{
  strreplace(sysDp, fwSystemOverviewFunc_SYSVIEW_NODE, "");
  return (int)sysDp;
}

string fwSystemOverviewFunc_makeProjDpName(unsigned sysNo, string dpHostName, unsigned pmonPortNo)
{
  return fwSystemOverviewFunc_PROJVIEW_NODE+sysNo+"_"+dpHostName+"_"+pmonPortNo;
}

int fwSystemOverviewFunc_getSysChildNodes(string sysDp, dyn_uint& childNodes)
{
  return dpGet(sysDp + fwSystemOverviewFunc_CHILD_STR, childNodes);
}

int fwSystemOverviewFunc_setSysChildNodes(string sysDp, dyn_uint childNodes)
{
  return dpSet(sysDp + fwSystemOverviewFunc_CHILD_STR, childNodes);
}

int fwSystemOverviewFunc_getSysData(string sysDp, unsigned& sysNo, string& sysName, unsigned& parentNo, dyn_uint& childNodes, dyn_string& projDpList)
{
  return dpGet(sysDp + fwSystemOverviewFunc_SYSNO_STR, sysNo, 
               sysDp + fwSystemOverviewFunc_SYSNAME_STR , sysName,
               sysDp + fwSystemOverviewFunc_PARENT_STR , parentNo,
               sysDp + fwSystemOverviewFunc_CHILD_STR , childNodes,
               sysDp + fwSystemOverviewFunc_PROJLIST_STR , projDpList);
}

int fwSystemOverviewFunc_getSysName(string sysDp, string& sysName)
{
  return dpGet(sysDp + fwSystemOverviewFunc_SYSNAME_STR , sysName);
}


int fwSystemOverviewFunc_getSysState(string sysDp, unsigned& sysState)
{
  return dpGet(sysDp + fwSystemOverviewFunc_CURR_STATE_STR, sysState);
}

// int getSysNo(string dpName, unsigned &sysNo)
// {
//   return dpGet(dpName + SYSNO_STR, sysNo);
// }
// 
// int getSysName(string dpName, string &sysName)
// {
//   return dpGet(dpName + SYSNAME_STR, sysName);
// }
// 
// int getEvmPort(string dpName, unsigned &evmPort)
// {
//   return dpGet(dpName + EVM_PORT_STR, evmPort);
// }
// 
// int getDmPort(string dpName, unsigned &dmPort)
// {
//   return dpGet(dpName + DATAMAN_PORT_STR, dmPort);
// }
// 
// int getDistmanPort(string dpName, unsigned &distmanPort)
// {
//   return dpGet(dpName + DISTMAN_PORT_STR, distmanPort);
// }

bool fwSystemOverviewFunc_getRootNodes(dyn_string &rootDPs)
{  
  string dpArrayName = fwSystemOverviewFunc_DPNAME_ARRAY;
  dyn_string dpNameList, projDpList;
  dyn_uint childNodes;
  unsigned parentNode, sysNo;
  string sysName;
  
  
  fwSystemOverviewFunc_getSysDPList(dpNameList);

  for(int j = 1; j <= dynlen(dpNameList); j++){
    
    fwSystemOverviewFunc_getSysData(dpNameList[j], sysNo, sysName, parentNode, childNodes, projDpList);
        
    if(parentNode == 0 && dynContains(rootDPs, dpNameList[j]) == 0)
      dynAppend(rootDPs, dpNameList[j]);
  } 
  return(true);   
}

bool fwSystemOverviewFunc_deleteCollDP()
{
    if(dpExists(fwSystemOverviewFunc_DPNAME_ARRAY))
      dpDelete(fwSystemOverviewFunc_DPNAME_ARRAY);
}

bool fwSystemOverviewFunc_deleteSysDP(string sysDp)
{
  dyn_string projDpList;
  
  fwSystemOverviewFunc_getProjDPList(sysDp, projDpList);

  for(int i = 1; i<= dynlen(projDpList); i++)
   if(dpExists(projDpList[i]))
     dpDelete(projDpList[i]);
  
  if(dpExists(sysDp))
    dpDelete(sysDp);
}

bool fwSystemOverviewFunc_deleteDPStruct()
{
  dyn_string dpNameList;
  
  fwSystemOverviewFunc_getSysDPList(dpNameList);
  
  for(int i = 1; i<= dynlen(dpNameList); i++)
    fwSystemOverviewFunc_deleteSysDP(dpNameList[i]);
  
  fwSystemOverviewFunc_deleteCollDP();
}

fwSystemOverviewFunc_populateFilterListFromDp(dyn_uint& sysNoList, dyn_string& sysNameList, dyn_string& hostList, dyn_int& stateList, dyn_string& managerNameList)
{
  dyn_string sysDpList;
  dyn_string projDpList;
  string sysName, hostName, userName, userPassword, sharedDir, type;
  unsigned sysNo, parentNo, pmonPortNo;
  dyn_uint childNodes;
      
//  dyn_int 
  
  fwSystemOverviewFunc_getSysDPList(sysDpList);
  
  for(int i = 1; i <= dynlen(sysDpList); i++){
    fwSystemOverviewFunc_getSysData(sysDpList[i], sysNo, sysName, parentNo, childNodes, projDpList);
    dynAppend(sysNoList, sysNo);
    
    for(int j = 1; j <= dynlen(projDpList); j++){
      fwSystemOverviewFunc_getProjAccessData(projDpList[j], hostName, pmonPortNo, userName, userPassword, sharedDir);
      dynAppend(hostList, hostName);
      fwSystemOverviewFunc_getProjManagersType(projDpList[j], type);
      dynAppend(managerNameList, type);
    }
  }
  
  dynUnique(sysNoList);
  dynSortAsc(sysNoList);
  
  dynClear(sysNameList);
  
  for(int i = 1; i <= dynlen(sysNoList); i++){
    fwSystemOverviewFunc_getSysName(fwSystemOverviewFunc_sysNoToDp(sysNoList[i]), sysName);
    dynAppend(sysNameList, sysName);
  }
  
  dynUnique(hostList);
  dynSortAsc(hostList);
  
  fwSystemOverviewFunc_getStateList(stateList);
  dynUnique(stateList);
  dynSortAsc(stateList);
  
  dynUnique(managerNameList);
  dynSortAsc(managerNameList);
}

void fwSystemOverviewFunc_getStateList(dyn_int& stateList)
{
  for(int i = -20; i <= 30; i++){
    if(fwSystemOverviewFunc_getStrFromState(i) != "STATE NOT DEFINED")
      dynAppend(stateList, i);
  }
}
