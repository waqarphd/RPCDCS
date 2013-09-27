dyn_string fwFMCPmon_getNodeProjectDps(string node, string systemName = "")
{
  dyn_string projectDps;
  string hostDp = fwFMCPmon_getSystemOverviewNodeDp(node, systemName);
  projectDps = dpNames(hostDp +"/*", "FwSystemOverviewProject");
  return projectDps;
}

string fwFMCPmon_getProjectName(string projectDp)
{
  dyn_string ds = strsplit(projectDp, "/");
  return ds[dynlen(ds)];
}

string fwFMCPmon_getProjectState(string projectDp)
{
  int iState = -1;
  dpGet(projectDp + ".readings.state", iState);
  string str;
  switch(iState){
    case fwSysOverview_STOPPED_NORMAL:
      str = "STOPPED";
      break;
    case fwSysOverview_INITIALIZE:
      str = "INITIALIZING";
      break;
    case fwSysOverview_RUNNING:
      str = "RUNNING";
      break;
    case fwSysOverview_BLOCKED:
      str = "MANAGER BLOCKED";
      break;
    case fwSysOverview_STOPPED_ABNORMAL:
      str = "MANAGER ABN. STOPPED";
      break;
    case fwSysOverview_RAPID_RESTART:
      str = "RAPID RESTART";
      break;
    case fwSysOverview_PROJNAME_MISMATCH:
      str = "PROJECT NAME MISMATCH";
      break;
    case fwSysOverview_PMON_NO_RESPONSE:
      str = "PMON NOT RESPONDING";
      break;
    case fwSysOverview_PMON_NOT_RUNNING:
      str = "PMON NOT RUNNING";
      break;
    case fwSysOverview_MONITORING_STOPPED:
      str = "NOT MONITORED";
      break;
    default:
      str = "STATE NOT DEFINED";
      break;
   }  
  return str;
}

bool fwFMCPmon_exists(string node, string systemName = "")
{    
  string soDp = fwFMCPmon_getSystemOverviewDp(node);
  return dpExists(dp);
}

string fwFMCPmon_getDp(string node, string systemName = "")
{
  if(systemName == "")
    systemName = getSystemName();
  
  string nodeDp = fwFMC_getNodeDp(node);
  
  return  nodeDp + "/" + "Pmon";
}

string fwFMCPmon_getSystemOverviewNodeDp(string node, string systemName = "")
{
  if(systemName == "")
    systemName = getSystemName();
  
  string dp = systemName + "SystemOverview/" + node;
  
  return dp;
}

/*
int fwFMCPmon_add(string node, bool createSOHost = true)
{
  const string soHostDpt = "FwSystemOverviewPC";
  string dp = fwFMCPmon_getDp(node);
  string soDp = fwFMCPmon_getSystemOverviewDp(node);
  
  strreplace(dp, getSystemName(), "");
  if(!dpExists(dp))
  {
    dpCreate(dp, "FwFMCPmon");   
  }
  
  dyn_string types = dpTypes(soHostDpt, getSystemId());
  if(createSOHost && dynContains(types, soHostDpt) > 0 && !dpExists(soDp))
  {
    dpCreate(soDp, soHostDpt);
  }
  
  return dpSet(dp + "systemOverviewHostDp", soDp);
}
void fwFMCPmon_connectReadoutDpe(string node, dyn_string &exception)
{    
  string nodeDp = fwFMC_getNodeDp(node);
  string soNodeDp = fwFMCPmon_getSystemOverviewNodeDp(node);
 
  fwDpFunction_setDpeConnection(nodeDp + ".agentCommunicationStatus.pmon", 
                                makeDynString(soNodeDp + ".agentCommunicationStatus.pmon:_online.._value"
                                              ),
                                makeDynString(),
                                "p10==1&&p11==1?1:p10==1&&p11==0?0:p1==1||p2==1||p3==1||p4==1||p5==1||p6==1||p7==1||p8==1||p9==1||p12==1?1:(p1==-1||p1==0)&&(p2==-1||p2==0)&&(p3==-1||p3==0)&&(p4==-1||p4==0)&&(p5==-1||p5==0)&&(p6==-1||p6==0)&&(p7==-1||p7==0)&&(p8==-1||p8==0)&&(p9==-1||p9==0)&&(p10==-1||p10==0)&&(p12==-1||p12==0)?-1:0",
                                exception,
                                1);

  return;
}

int fwFMCPmon_remove(string node, bool removeSOHost = true)
{
  string dp = fwFMCPmon_getDp(node);  
  string soDp = fwFMCPmon_getSystemOverviewNodeDp(node);
  if(dpExists(dp))
  {
    //Unsubscribe DIM services here:
    dpSet(fwFMC_getNodeDp(node) + ".agentCommunicationStatus.pmon", 0);
    dpDelete(dp);
  }
  
  if(removeSOHost && dpExists(soDp))
    dpDelete(soDp);
  
  return 0;  
}
*/
