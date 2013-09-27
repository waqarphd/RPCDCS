#uses "fwSystemOverview/fwSystemOverview.ctl"

string fwSysOverviewFsm_getProjectState(string projectDp)
{
  string fsmState;
  string projectDetailedState = fwSysOverview_getProjectState(projectDp);
  
  if(projectDetailedState == "RUNNING" || projectDetailedState == "STOPPED")
    fsmState = projectDetailedState;
  else
    fsmState = "ERROR";
  
  return fsmState;
}

dyn_string fwSysOverviewFsm_getTreeDevices(string tree, bool uniqueDeviceList = false, string pattern = "")
{
  dyn_string devices = fwUi_getIncludedTreeDevices(tree);
  if(uniqueDeviceList)
    dynUnique(devices);
  
  if(pattern != "")
  {
    dyn_string tmp;
    for(int i=1; i<=dynlen(devices); i++)
    {
      strreplace(devices[i], getSystemName(), "");
      if (patternMatch(pattern, devices[i]))
      {
        dynAppend(tmp, devices[i]);
      }
    }
    devices = tmp;
  }
  
  return devices;
}

string fwSysOverviewFsm_getTreeByLabel(string treeLabel)
{
  string tree;
  dyn_string soTrees;
  fwSystemOverviewFsm_getTrees(soTrees);
  for(int i=1; i<=dynlen(soTrees); i++)
  {
    string label;
    fwUi_getLabel(soTrees[i], soTrees[i], label);
    if (label == treeLabel)
    {
      tree = soTrees[i];
      break;
    }
  }
  return tree;
}

dyn_string fwSysOverviewFsm_getChildrenOfType(string tree, string childrenDpType)
{
  dyn_string ex, nodes;
  fwTree_getAllTreeNodes(tree, nodes, ex);
// if(childrenDpType == "IcemonPlc")  
// DebugN("getAllTreeNodes gives", tree, nodes);  
   int n = dynlen(nodes);
  dyn_string children;
  string child;
  for(int i = 1; i <= n; i++)
  {
    child = nodes[i];
    string dp = "";
    if(dpExists(nodes[i]))
      dp = nodes[i];
    else if (strpos(nodes[i], "&") == 0)
    {
      child = fwTree_getNodeDisplayName(nodes[i], ex) ;
      
      if (!dpExists(child))
        dp = dpAliasToName(child);
      else
        dp = child;
    }
    else
      dp = dpAliasToName(nodes[i]);
    
    if(dpExists(dp) && dpTypeName(dp) == childrenDpType)
    {
      if (!dynContains(children, child))
        dynAppend(children, child);
    }
  }
  
/*  dyn_int internalTypes;
  dyn_string allChildren = fwCU_getChildren(internalTypes, node);
  dyn_string children;
  
  for(int i = 1; i <= dynlen(allChildren); i++)
    if(dpExists(allChildren[i]) && dpTypeName(allChildren[i]) == childrenDpType)
    {
      dynAppend(children, allChildren[i]);
    }
 */  
  return children;  
} 

dyn_dyn_string fwSysOverviewFsm_getChildrenOfTypeWithDomain(string tree, string childrenOfType, string controlUnit)
{
  dyn_dyn_string children;
  _fwSysOverviewFsm_getChildrenOfTypeWithDomain(tree, childrenOfType, controlUnit, children);
  return children;
}
void _fwSysOverviewFsm_getChildrenOfTypeWithDomain(string tree, string childrenOfType, string controlUnit, dyn_dyn_string& children)
{
  dyn_string ex, nodes;
  string node;
//fwInstallation_throw(1);  
  fwTree_getChildren(tree, nodes, ex);
//fwInstallation_throw(2);  
  int childrenLength = dynlen(children);
//  int foundChildrenCount = 1;
  int n = dynlen(nodes);
  for(int i=1; i<= n; i++)
  {
    if (_fwSysOverviewFsm_isOfType(nodes[i], childrenOfType))
    {
      //int index = childrenLength + foundChildrenCount;
      ++childrenLength;
//      if(patternMatch("&*", nodes[i]))
      if (strpos(nodes[i], "&") == 0) 
      {
        node = fwTree_getNodeDisplayName(nodes[i], ex) ;
        
        if (!_fwSysOverviewFsm_dynContains(children, node))
        {
          children[childrenLength][1] = node;
          children[childrenLength][2] = controlUnit;
        }
      }
      else if (!_fwSysOverviewFsm_dynContains(children, nodes[i]))

      {
        children[childrenLength][1] = nodes[i];
        children[childrenLength][2] = controlUnit;
      }
//      foundChildrenCount++;
    }
    if (fwSysOverviewFsm_isDomain(nodes[i]))
      _fwSysOverviewFsm_getChildrenOfTypeWithDomain(nodes[i], childrenOfType, nodes[i], children);
    else
      _fwSysOverviewFsm_getChildrenOfTypeWithDomain(nodes[i], childrenOfType, controlUnit, children);
  }
//fwInstallation_throw(3);  
}

/** This funciton is introduce to work around the performance issues of fwFsm_isDomain 
which internally uses a mapping*/
bool fwSysOverviewFsm_isDomain(string domain)
{
  return dpExists("fwCU_"+domain);  
}

string fwSysOverviewFsm_getDomain(string device)
{
  string domain;
  dyn_string devices = dpNames("*|" + device, "_FwFsmDevice");
  if (dynlen(devices) >0)
  {
    dyn_string tmpArr = strsplit(dpSubStr(devices[1], DPSUB_DP), "|");
    domain = tmpArr[1];  
  }
  return domain;
}

bool _fwSysOverviewFsm_dynContains(dyn_dyn_string ddsArray, string element)
{
  for(int i=1;i <= dynlen(ddsArray); i++)
  {
    for (int j=1; j<= dynlen(ddsArray[i]); j++)
    {
      if (ddsArray[i][j] == element)
        return true;    
    }    
  }
  
  return false;
}

bool _fwSysOverviewFsm_isOfType(string node, string type)
{
  bool isOfType = false;
  dyn_string ex; 
  string dp = "";
 
  if(dpExists(node))
    dp = node;
  else if (strpos(node, "&") == 0)
  {
    string displayName = fwTree_getNodeDisplayName(node, ex) ;
    if (!dpExists(displayName))
      dp = dpAliasToName(displayName);
    else
      dp = displayName;
  }
  else
    dp = dpAliasToName(node);
 
  isOfType = (dpExists(dp) && (dpTypeName(dp) == type));
  return isOfType;
}


const string modFsmNodeProperties = "modFsmNodeProperties";

/*
string fwFsmUser_nodeEnabled(string parent, string dev)
{  
  fwSysOverview_enableProjectMonitoring(dev);  
  fwSysOverview_stopMonitoring();
  fwSysOverview_startMonitoring();
}

string fwFsmUser_nodeDisabled(string parent, string dev)
{
  fwSysOverview_disableProjectMonitoring(dev);
  fwSysOverview_stopMonitoring();
  fwSysOverview_startMonitoring(); 
}
*/
fwFsmUser_operateNodeRightClick(string domain, string obj)
{
  dyn_string actions;
  string state;
  fwCU_getState(obj, state);
  fwUi_getObjStateAllActions(domain, obj, state, actions);
  dyn_string menu;
  int ret;
  dynClear(menu);
  string domain = "";
  fwSysOverview_getACDomain(domain);
  dyn_string ex;
  int isGranted = 0; 
  
  if(domain == "")
    isGranted = 1;
  else
  {
    string expertPrivilege = fwSysOverview_getExpertPrivilege();
    // check the current  privilege level 
    if (expertPrivilege == "")
    {
      DebugN("No expert privilege defined!");
      return;
    }
    fwAccessControl_isGranted(domain + ":" +expertPrivilege, isGranted, ex);
   
  }
  for(int i = 1; i <= dynlen(actions); i++)
  {
    dynAppend(menu, ("PUSH_BUTTON, "+actions[i]+", "+i+", " + isGranted)); 
  }
  popupMenu(menu, ret);
  if(ret > 0 && ret <= dynlen(actions))
    fwCU_sendCommand(obj, actions[ret]);

  return;  
}

dyn_string fwSysOverviewFsm_getApplicationNodes(string application)
{
  dyn_string hostDps = fwSysOverviewFsm_getChildrenOfType(application, "FwFMCNode");
  dyn_string hosts;
  
  for(int i = 1; i <= dynlen(hostDps); i++)
    dynAppend(hosts, fwFMC_getNodeName(hostDps[i]));

  return hosts;  
}

fwFsmUser_operateNodeClick(string domain, string obj)
{
  
   string panel = "";
   string panelRef = "";
   dyn_string hosts;
   
  //get rid of the previous panel shown:   
  string oldPanel = tfCurrentFsmNodePanel.text; 
                       
  if(oldPanel != "" && isPanelOpen(oldPanel, modFsmNodeProperties))
    PanelOffModule(oldPanel, modFsmNodeProperties);
  
//  bool state = false;
//  getValue("FW_SYSTEM_OVERVIEW_TOOL.cbEditor", state, 0, state);
  if(cbEditor.state(0))
//  if(state)
  {
    if(fwFsm_isDU(domain, obj))
    {
      string type = dpTypeName(obj);
      
      if(type == "FwFMCNode")
      {
        panel = "fwConfigurationDBSystemInformation/fwConfigurationDBSystemInformation_computerProperties.pnl";
        string node = fwFMC_getNodeName(obj);
        RootPanelOnModule(panel, obj, modFsmNodeProperties, makeDynString("$computer:"+node, "$embedded:TRUE"));
      }
      else if(type == "FwSystemOverviewProject")
      {
        panel = "fwConfigurationDBSystemInformation/fwConfigurationDBSystemInformation_projectProperties.pnl";
        dyn_string ex;
        string project = "";
        fwSysOverview_getProjectDb(obj, project, ex);
        string nodeDp, node;
        fwSysOverview_getProjectPc(obj, nodeDp, ex);
        fwSysOverview_getHostDb(nodeDp, node, ex);

        RootPanelOnModule(panel, obj, modFsmNodeProperties, makeDynString("$computer:"+node, "$project:"+project, "$embedded:TRUE"));
      }      
    }
    else
    {
      hosts = fwSysOverviewFsm_getApplicationNodes(obj);    
      panel = "fwConfigurationDBSystemInformation/fwConfigurationDBSystemInformation_systemManager.pnl";
      RootPanelOnModule(panel, obj, modFsmNodeProperties, makeDynString("$computer:"+hosts));
    }
  }
  else
  {
    fwUi_getUserPanel(domain, obj, panel);
    if(panel != "")
      panel = "fwSystemOverview/Fsm/" + panel;
     
    panelRef = domain + "_specific";
    RootPanelOnModule(panel, obj, modFsmNodeProperties, makeDynString(domain, obj));
  }  
  
  tfCurrentFsmNodePanel.text = panel;
     
  return;  
}
 
fwSystemOverviewFsm_getRootNodes(dyn_string &parents, dyn_string &exInfo)
{
  dyn_string dps;
  int i;
  string node;

	dynClear(parents);
	dps = dpNames("*.","_FwTreeNode");
	for(i = 1; i <= dynlen(dps); i++)
	{
		dps[i] = substr(dps[i],0,strlen(dps[i])-1);
		dpGet(dps[i]+".parent",node);
		if(node == "fwTN_FSM" && !patternMatch("*fwTN_---*", dps[i]))
		{
			dynAppend(parents,_fwTree_getNodeName(dps[i]));
		}
	}
}

int fwSystemOverviewFsm_getTrees(dyn_string &fmcTrees)
{
  dyn_int internalTypes;
  dyn_string trees, ex;
  fwSystemOverviewFsm_getRootNodes(trees, ex);
  for(int i = 1; i <= dynlen(trees); i++)  
    if(patternMatch("fwSO_*", trees[i]))
      dynAppend(fmcTrees, trees[i]);
  
  return;
}

bool fwSystemOverviewFsm_isTreeRunning(string tree)
{
  string state;
  fwCU_getState(tree, state);
//  DebugN(state);
  return state == "DEAD"?false:true;
}


