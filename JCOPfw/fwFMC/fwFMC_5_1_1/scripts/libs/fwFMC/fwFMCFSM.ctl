#uses "fwFMC/fwFMC.ctl"
#uses "fwSystemOverview/fwSystemOverview.ctl"

const string modFsmNodeProperties = "modFsmNodeProperties";


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
    fwAccessControl_isGranted(domain + ":expert", isGranted, ex);
  
  for(int i = 1; i <= dynlen(actions); i++)
  {
    dynAppend(menu, ("PUSH_BUTTON, "+actions[i]+", "+i+", " + isGranted)); 
  }
  popupMenu(menu, ret);
  if(ret > 0 && ret <= dynlen(actions))
    fwCU_sendCommand(obj, actions[ret]);

  return;  
}

fwFsmUser_operateNodeClick(string domain, string obj)
 {
   string panel = "";
   string panelRef = "";

   fwUi_getUserPanel(domain, obj, panel);
   if(panel != "")
     panel = "fwFMC/" + panel;

   panelRef = domain + "_specific";

   RootPanelOnModule(panel, obj, modFsmNodeProperties, makeDynString(domain, obj));
  return;  
}
 
fwFMCFSM_getRootNodes(dyn_string &parents, dyn_string &exInfo)
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

int fwFMCFSM_getTrees(dyn_string &fmcTrees)
{
  dyn_int internalTypes;
  dyn_string trees, ex;
  fwFMCFSM_getRootNodes(trees, ex);
  for(int i = 1; i <= dynlen(trees); i++)  
    if(patternMatch("FMC_*", trees[i]))
      dynAppend(fmcTrees, trees[i]);
  
  return;
}

bool fwFMCFSM_isTreeRunning(string tree)
{
  string state;
  fwCU_getState(tree, state);
//  DebugN(state);
  return state == "DEAD"?false:true;
}
