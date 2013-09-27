/**@name LIBRARY: fwFsmTree:
 
library of functions to dynamically create FSM Trees.
These functions can be used in User Interfaces or Ctrl Scripts
	
modifications: none

Usage: JCOP framework internal, public

PVSS manager usage: VISION, CTRL

@version creation: 17/02/2005
@author C. Gaspar
 
        
 
*/ 
//@{
//-------------------------------------------------------------------------------- 

int fwFsmTree_isFsmHierarchy(string node)
{
	string tree;
	dyn_string exInfo;

	fwTree_getTreeName(node, tree, exInfo);
	if(tree == "FSM")
		return 1;
	return 0;
}

FSM_editor_selected(string node, string parent)
{
	string dev, type, sys;
	int cu, pcu, visi;
	dyn_string exInfo;

	fwTree_getNodeDevice(node, dev, type, exInfo);
	setValue("type","text",type);
	setValue("object","text", dev);
	fwTree_getNodeCU(node, cu, exInfo);
	visi = fwFsmTree_isFsmHierarchy(node);
	setValue("cu","visible",visi);
	setValue("cu","state",0,cu);
}

FSM_editor_entered(string node, string parent)
{
	fwFsmTree_editor(node, parent);
}

FSM_navigator_selected(string node, string parent)
{
}

FSM_navigator_entered(string node, string parent)
{
	fwFsmTree_navigator(node, parent);
}

fwFsmTree_getObjFromTnode(string tnode, string parent, string &domain, string &obj, int flag = 0)
{
string device, type, node;
dyn_string exInfo;
int cu, ref = 0;

//DebugN("Operator1", parent, node);
	node = tnode;
	fwTree_getNodeCU(node, cu, exInfo);
	if(fwFsm_isObjectReference(node))
	{
		fwTree_getNodeDevice(node, device, type, exInfo);
		node = fwFsm_extractSystem(device);
		ref = 1;
	}
	if(cu)
		parent = node;
	node = fwFsm_convertToAssociated(node);
	if(fwFsm_isAssociated(node))
	{
//DebugTN("Is assoc", node, ref, flag);
		if((!ref) || (flag))
   {
			parent = fwFsm_getAssociatedDomain(node);
  		node = fwFsm_getAssociatedObj(node);
   }
	}
	domain = fwFsm_extractSystem(parent);
	domain = fwTree_getNodeDisplayName(domain, exInfo);
//DebugN("isDomain", parent, domain, node, cu, ref);
	if(!fwFsm_isDomain(domain))
	{
		string parent_parent;

		fwTree_getCUName(parent, parent_parent, exInfo);
		domain = parent_parent;
	}
	if(!fwFsm_isAssociated(node))
		obj = fwTree_getNodeDisplayName(node, exInfo);
	else
		obj = fwFsm_extractSystem(node);
//DebugN("FromTnode", domain, node);
}

FSM_operator_entered(string node, string parent)
{
	int open;
  
	if(isFunctionDefined("fwFsmUser_operateNodeRightClick"))
  {
    string domain, obj;
    if(node == "")
      return;
    fwFsmTree_getObjFromTnode(node, parent, domain, obj, 1);
    fwFsmUser_operateNodeRightClick(domain, obj);
    return;
  }
 	dpGet("ToDo.openOnSingleClick", open);

	if(open < 2)
		fwFsmTree_openPanel(node, parent);
//	else
//		fwFsmTree_showInfo(node, parent);
}

FSM_operator_selected(string node, string parent)
{
	int open;
  
	if(isFunctionDefined("fwFsmUser_operateNodeClick"))
  {
    string domain, obj;
    if(node == "")
      return;
    fwFsmTree_getObjFromTnode(node, parent, domain, obj, 1);
    fwFsmUser_operateNodeClick(domain, obj);
    return;
  }
	dpGet("ToDo.openOnSingleClick", open);

	if(open < 2)
  {
//		fwFsmTree_showInfo(node, parent);
  }
	else
		fwFsmTree_openPanel(node, parent);
}

fwFsmTree_openPanel(string node, string parent)
{
string domain, obj;
int x = -1, y = -1, done = 0;

	fwUi_uninformUser();
	if(node == "")
		return;
	fwFsmTree_getObjFromTnode(node, parent, domain, obj, 1);
//DebugN("getObjFromTnode", node, parent, domain, obj);
  panelPosition(myModuleName(), "", x, y);
 	x += 256;
//	if(y < 0)
//	  y = 0;
  if(globalExists("FwFSMMainPanelOpen"))
  {
    if((FwFSMMainPanelOpen == "") || (FwFSMMainPanelOpen == node))
    {
      FwFSMMainPanelOpen = node;
    	y -= 23;
      done = 1;
    }
  }
	if(y < 0)
	  y = 0;
  if(!done)
  {
//    x += 20;
//    y += 70;
    y = -1;
  }
//	fwUi_showFsmObject(domain, obj, "", x,y);
	fwFsmUi_view(domain, obj, x, y);
}

fwFsmTree_showInfo(string node, string parent)
{
	string domain, obj;
	bit32 statusBits;
	string cu, state, toolTip, owner, obj_state, user;
	int enabled;


	if(node == "")
		return;
	fwFsmTree_getObjFromTnode(node, parent, domain, obj, 1);
//DebugN("selected", node, parent, domain, obj);
	statusBits = fwFsmUi_getModeBits(domain, obj);

    	cu = fwUi_getModeObj(domain, obj);
	fwUi_checkOwnership(cu, enabled, owner);
	state = fwUi_getCUMode(domain, obj);
    	toolTip = "Mode: "+state;
	if(owner != "")
	{
		user = fwUi_getManagerIdInfo(owner);
		toolTip += "\nOwner: "+owner+" ("+user+")";
	    	if (!getBit(statusBits,FwExclusiveBit)) toolTip += "\nIs Shared";
    		if (getBit(statusBits,FwIncompleteBit)) toolTip += "\nHas Excluded child(ren)";
    		if (getBit(statusBits,FwIncompleteDevBit)) toolTip += "\nHas Disabled child(ren)";
	}
	fwUi_getCurrentState(domain, obj, obj_state);
	fwUi_uninformUser();
	fwUi_informUser("Node: "+obj+" in state "+obj_state, 100, 100, "Dismiss", toolTip);
}


dyn_string FwFsmTree_TreeNodes;
dyn_string FwFsmTree_FSMNodes;
dyn_int FwFsmTree_FSMModes;
dyn_string FwFsmTree_FSMColors;
dyn_int FwFsmTree_FSMNodesConnected;
dyn_string FwFsmTree_FSMNodesDp;
int FwFsmTree_someDown = 0;

//int FwFsmOperatorTree_viewAll = 0;

fwFsmTree_setViewAll(int flag)
{
	FwFsmOperatorTree_viewAll = flag;
}

fwFsmTree_checkTreeSystems(int tmout)
{
int i, ret;

	while(1)
	{
		for(i = 1; i <= dynlen(FwFsmTree_FSMNodesConnected); i++)
		{
			if(FwFsmTree_FSMNodesConnected[i] == -1)
			{
				FwFsmTree_FSMNodesConnected[i] = 0;
				ret = fwCU_connectOperationMode("fwFsmTree_modeChange",FwFsmTree_FSMNodes[i], FwFsmOperatorTree_viewAll);
				if(!ret)
					FwFsmTree_FSMNodesConnected[i] = -1;
				else
				{
					DebugTN("FwFsmTree: Node up", FwFsmTree_TreeNodes[i], FwFsmTree_FSMNodes[i]);
					FwFsmTree_someDown--;
				}
			}
		}
		if(FwFsmTree_someDown <= 0)
			break;
		delay(tmout);
	}
}

fwFsmTree_connectNodeState(string node, string parent)
{
string domain, obj, domain1, obj1, dp;
int i, index, index1, ret;
dyn_int indexes, indexes1, indexes2;

//if(strpos(node,"IT_DAQ") >= 0)
//	if(!globalExists("FwFsmOperatorTree_viewAll"))
//		addGlobal("FwFsmOperatorTree_viewAll", INT_VAR);
//DebugN("connectNodeState", node, parent, dynlen(FwFsmTree_TreeNodes), dynlen(FwFsmTree_FSMNodesConnected));
	fwFsmTree_getObjFromTnode(node, parent, domain, obj);
//DebugN("Connecting", node, parent, domain, obj);
//if(domain == "")
//DebugN("********************** bad", node, parent, domain, obj);
	if((domain != obj) && (domain != ""))
		obj = domain+"::"+obj;
//DebugN("connectNodeState", node, parent, domain, obj);
	if(!(index = dynContains(FwFsmTree_TreeNodes, node)))
		index = dynAppend(FwFsmTree_TreeNodes, node);
//DebugN("connectNodeState",node, parent, domain, obj);
	if(!(index1 = dynContains(FwFsmTree_FSMNodes, obj)))
	{
		FwFsmTree_FSMNodes[index] = obj;	
		FwFsmTree_FSMModes[index] = -1;
		FwFsmTree_FSMColors[index] = "";
		FwFsmTree_FSMNodesConnected[index] = 0;
		FwFsmTree_FSMNodesDp[index] = "";
		dynAppend(indexes, index);
//		fwCU_connectOperationMode("fwFsmTree_modeChange",obj, FwFsmOperatorTree_viewAll);
//		_fwFsmTree_getNodeDp(obj, domain1, obj1, dp);
//		fwUi_connectOwnerExclusivity("fwFsmTree_ownerChanged", domain1, obj1);
//		fwCU_connectState("fwFsmTree_stateChange",obj); 
	}
	else
	{
		FwFsmTree_FSMNodes[index] = obj;	
		FwFsmTree_FSMModes[index] = -1;	
		FwFsmTree_FSMColors[index] = "";
		FwFsmTree_FSMNodesDp[index] = "";
//		fwFsmTree_setInitialMode(FwFsmTree_TreeNodes[index], FwFsmTree_FSMModes[index1], index);
		FwFsmTree_FSMNodesConnected[index] = 0;
		dynAppend(indexes1, index);
		dynAppend(indexes2, index1);
	}
	for(i = 1; i <= dynlen(indexes); i++)
	{
		index = indexes[i];
		ret = fwCU_connectOperationMode("fwFsmTree_modeChange",FwFsmTree_FSMNodes[index], FwFsmOperatorTree_viewAll);
		if(!ret)
		{
			DebugTN("FwFsmTree: Node down", FwFsmTree_TreeNodes[index], FwFsmTree_FSMNodes[index]);
			FwFsmTree_FSMNodesConnected[index] = -1;
			if(!FwFsmTree_someDown)
			{
				startThread("fwFsmTree_checkTreeSystems", 10);
			}
			FwFsmTree_someDown++;
		}
//		FwFsmTree_FSMNodesConnected[index] = 2;
	}
	for(i = 1; i <= dynlen(indexes1); i++)
	{
		index = indexes1[i];
		index1 = indexes2[i];
//DebugN("Setting Initial Mode", FwFsmTree_TreeNodes[index], FwFsmTree_TreeNodes[index1], FwFsmTree_FSMModes[index1], index, index1);
//		fwFsmTree_setInitialMode(FwFsmTree_TreeNodes[index], FwFsmTree_FSMModes[index1], index);
		fwFsmTree_setInitialMode(index, index1);
//		FwFsmTree_FSMNodesConnected[index] = 1;
	}
//	fwCU_connectState("fwFsmTree_stateChange",obj); 
}

fwFsmTree_disconnectNodeState(string node, string parent)
{
string domain, obj, domain1, obj1, dp;
int index;

//DebugN("disconnectNodeState", node, parent, dynlen(FwFsmTree_TreeNodes), dynlen(FwFsmTree_FSMNodesConnected));
	fwFsmTree_getObjFromTnode(node, parent, domain, obj);
	if(domain != obj)
		obj = domain+"::"+obj;
	if(index = dynContains(FwFsmTree_TreeNodes, node))
	{
		if(FwFsmTree_FSMNodesConnected[index] == 2)
		{
//			fwCU_disconnectState("fwFsmTree_stateChange",obj); 
			_fwFsmTree_getNodeDp(FwFsmTree_FSMNodes[index], domain1, obj1, dp);
			fwUi_disconnectCurrentState("fwFsmTree_stateChange", domain1, obj1);
		}
//DebugN("disconnecting", node, domain1, obj1, dp, obj); 
		fwCU_disconnectOperationMode("fwFsmTree_modeChange",obj);
		dynRemove(FwFsmTree_TreeNodes, index);
		dynRemove(FwFsmTree_FSMNodes, index);
		dynRemove(FwFsmTree_FSMModes, index);
		dynRemove(FwFsmTree_FSMColors, index);
		dynRemove(FwFsmTree_FSMNodesConnected, index);		
		dynRemove(FwFsmTree_FSMNodesDp, index);		
	}
}

//int fwFsmTree_modeSem;

//fwFsmTree_setInitialMode(string treeNode, int mode, int i)
fwFsmTree_setInitialMode(int index, int index1)
{
//	string color, tnode;
//	int i, done = 0;

//if(strpos(treeNode,"IT_DAQ") >= 0)
//DebugN("********* Original Mode Changed", treeNode, mode);
//	if(FwFsmTree_FSMModes[index] != FwFsmTree_FSMModes[index1])
//	{
		FwFsmTree_FSMModes[index] = FwFsmTree_FSMModes[index1];
		FwFsmTree_FSMColors[index] = FwFsmTree_FSMColors[index1];
		fwFsmTree_setIcon(index);
//DebugN("Setting Icon", index);
//	}
}

fwFsmTree_modeChange(string node, int mode)
{
	string color, tnode;
	int i, done = 0, ret;
	string domain, obj, dp;

//if(strpos(node,"IT_DAQ") >= 0)
//DebugN("********* Mode Changed", node, mode);
//	synchronized(fwFsmTree_modeSem)
//	{
	for(i = 1; i <= dynlen(FwFsmTree_FSMNodes); i++)
	{
		if(FwFsmTree_FSMNodes[i] == node)
		{
//if(strpos(node,"IT_DAQ") >= 0)
//DebugN("********* Found Mode Changed", node, mode, i);
			if(FwFsmTree_FSMModes[i] != mode)
			{
				FwFsmTree_FSMModes[i] = mode;
				fwFsmTree_setIcon(i);
			}
			if(mode == 1)
			{
				if(!done)
				{
					if(!FwFsmTree_FSMNodesConnected[i])
					{
//						fwCU_connectState("fwFsmTree_stateChange",FwFsmTree_FSMNodes[i]); 
						_fwFsmTree_getNodeDp(node, domain, obj, dp);
						FwFsmTree_FSMNodesDp[i] = dp;
//DebugN("^^^^^^^^^^^^^ Connecting State for node", FwFsmTree_FSMNodes[i], domain, obj, dp);
						ret = fwUi_connectCurrentState("fwFsmTree_stateChange", domain, obj);
						if(ret) 
							FwFsmTree_FSMNodesConnected[i] = 2;
					}
					else
						ret = 1;
					done = 1;
				}
				else
				{
					if(ret)
						FwFsmTree_FSMNodesConnected[i] = 1;
				}
//DebugTN("Connected?", node, FwFsmTree_TreeNodes[i], FwFsmTree_FSMNodes[i], FwFsmTree_FSMNodesConnected[i]);
			}
		}
	}
//	}
}

_fwFsmTree_getNodeDp(string node, string &domain, string &obj, string &dp)
{
	string tmpobj;

	domain = node;
	obj = _fwCU_getNodeObj(domain);
//	if((domain != obj) && (fwFsm_isCU(domain, obj)))
	if((domain != obj) && (fwFsm_isDomain(obj)))
		obj = obj+"::"+obj;
	tmpobj = fwFsm_convertAssociated(obj);
	tmpobj = fwFsm_convertAssociated(obj);
	fwUi_getSysPrefix(domain, dp);
	dp += fwFsm_separator+tmpobj+".fsm";
//if(strpos(node,"IT_DAQ") >= 0)
//DebugN("getNodeDp", node, domain, obj, dp);
}

//fwFsmTree_stateChange(string node, string state)
fwFsmTree_stateChange(string dp, string state)
{
	string color, tnode, node;
	int i, index, pos;

//DebugN("stateChanged",node, state);
//DebugN("%%%%%%%%%%%%%%%%% stateChanged", dp, state);
	if(state == "")
		return;

	if ((pos = strpos(dp, ".currentState")) > 0)
		dp = substr(dp, 0, pos);
	if((index = dynContains(FwFsmTree_FSMNodesDp, dp)) > 0)
		node = FwFsmTree_FSMNodes[index];
	else
	{
		return;
	}
//	synchronized(fwFsmTree_modeSem)
//	{
	fwCU_getStateColor(node, state, color);
	for(i = 1; i <= dynlen(FwFsmTree_FSMNodes); i++)
	{
		if(FwFsmTree_FSMNodes[i] == node)
		{
			if(FwFsmTree_FSMColors[i] != color)
			{
				FwFsmTree_FSMColors[i] = color;
				fwFsmTree_setIcon(i);
			}
		}
	}
//	}
}

fwFsmTree_setIcon(int i)
{
//if(strpos(FwFsmTree_TreeNodes[i],"IT_DAQ") >= 0)
//DebugN("********* Setting Icon", FwFsmTree_TreeNodes[i]);
	if(FwFsmTree_FSMModes[i] <= 0)
		fwTreeDisplay_setIcon(FwFsmTree_TreeNodes[i], "FwDead");
	else
	{
		if(FwFsmTree_FSMColors[i] != "")
			fwTreeDisplay_setIcon(FwFsmTree_TreeNodes[i], FwFsmTree_FSMColors[i]);
	}
}

string RedoExtraNode = "";

fwFsmTree_editor(string node, string parent)
{
dyn_string txt, exInfo;
int answer, ret, cu;
int paste_flag;
string new_node, dev, type;
int redo, i, add_flag;
dyn_string redo_nodes, new_nodes;
string redo_node_parent;
int fsm_type;

//	fwFsm_initialize();
	redo = 0;
	RedoExtraNode = "";
	dynClear(redo_nodes);
	redo_node_parent = "";
	if(PasteNode == "")
		paste_flag = 0;
	else
		paste_flag = 1;
	if(node == fwFsm_clipboardNodeName)
	{
		dyn_string children;

		fwTree_getChildren(node, children, exInfo);
		if(dynlen(children) >= 1)
			dynAppend(txt,"PUSH_BUTTON, Remove..., 100, 1");
		else
			return;
	}
	else if(parent != node)
	{
		fwFsm_setSmiDomain(node);
		fwTree_getNodeCU(node, cu, exInfo);
		add_flag = 0;
//		if(cu && !fwFsm_isProxy(node))
//		if(!fwFsm_isProxy(node))
		if((!fwFsm_isProxy(node)) && (!fwFsm_isObjectReference(node)))
		{
//			dynAppend(txt,"PUSH_BUTTON, Add..., 1, 1");
			dynAppend(txt,"CASCADE_BUTTON, Add..., 1");
			add_flag = 1;
		}
		dynAppend(txt,"PUSH_BUTTON, Remove..., 2, 1");
		dynAppend(txt,"SEPARATOR");
		dynAppend(txt,"PUSH_BUTTON, Cut, 4, 1");
		dynAppend(txt,"PUSH_BUTTON, Paste, 5, "+paste_flag);
//		if((!fwFsm_isProxy(node)) && (fwFsm_isObjectReference(node)) != 1)
		if((!fwFsm_isProxy(node)) && (!fwFsm_isObjectReference(node)))
		{
			dynAppend(txt,"SEPARATOR");
			dynAppend(txt,"PUSH_BUTTON, Rename, 3, 1");
//			dynAppend(txt,"PUSH_BUTTON, Change Type, 8, 1");
		}
//		if(fwFsm_isObjectReference(node) == 1)
		if(fwFsm_isObjectReference(node))
		{
			dynAppend(txt,"SEPARATOR");
			dynAppend(txt,"PUSH_BUTTON, Update Reference, 9, 1");
		}
		else //if(cu)
		{
			dyn_string children;

//			fwUi_getChildren(node, children);
			fwTree_getChildren(node, children, exInfo);
			if(dynlen(children) > 1)
			{
				dynAppend(txt,"SEPARATOR");
				dynAppend(txt,"PUSH_BUTTON, Re-order Children, 15, 1");
			}
		}
		dynAppend(txt,"SEPARATOR");
		dynAppend(txt,"PUSH_BUTTON, Settings, 6, 1");
		if((!fwFsm_isProxy(node)) && (!fwFsm_isObjectReference(node)))
		  dynAppend(txt,"PUSH_BUTTON, Advanced Settings, 24, 1");
		if((cu) && (!fwFsm_isObjectReference(node)))
		{
			if(isFunctionDefined("fwAccessControl_selectPrivileges"))
			{
				dynAppend(txt,"SEPARATOR");
				dynAppend(txt,"PUSH_BUTTON, Access Control, 21, 1");
			}
			if(isFunctionDefined("fwFSMConfDB_initialize"))
			{
				dynAppend(txt,"SEPARATOR");
				dynAppend(txt,"PUSH_BUTTON, FSM Configuration DB, 22, 1");
			}
			dynAppend(txt,"SEPARATOR");
			dynAppend(txt,"PUSH_BUTTON, Generate FSM, 7, 1");
		}
	}
	else
	{
		dyn_string children;

		dynAppend(txt,"PUSH_BUTTON, Add..., 14, 1");
		dynAppend(txt,"SEPARATOR");
		dynAppend(txt,"PUSH_BUTTON, Paste, 5, "+paste_flag);

//		fwUi_getChildren(node, children);
		fwTree_getChildren(node, children, exInfo);
		if(dynlen(children) > 1)
		{
			dynAppend(txt,"SEPARATOR");
			dynAppend(txt,"PUSH_BUTTON, Re-order Children, 15, 1");
		}
		dynAppend(txt,"SEPARATOR");
		dynAppend(txt,"PUSH_BUTTON, Settings, 6, 1");
		dynAppend(txt,"PUSH_BUTTON, Advanced Settings, 23, 1");
		if(isFunctionDefined("fwAccessControl_selectPrivileges"))
		{
			dynAppend(txt,"SEPARATOR");
			dynAppend(txt,"PUSH_BUTTON, Access Control, 21, 1");
		}
		dynAppend(txt,"SEPARATOR");
		dynAppend(txt,"PUSH_BUTTON, Generate ALL FSMs, 7, 1");
	}
	if(add_flag)
	{
		dynAppend(txt,"Add...");
		dynAppend(txt,"PUSH_BUTTON, Devices, 10, 1");
		dynAppend(txt,"PUSH_BUTTON, Objects, 11, 1");
//		if(cu)
//			dynAppend(txt,"PUSH_BUTTON, Special Threshold Object, 20, 1");
	}
	popupMenu(txt,answer);
	if(answer == 1)
	{
	}
	else if(answer == 2)
	{
		new_node = fwFsmTree_askRemoveNode(parent, node, redo);
		dynAppend(redo_nodes,new_node);
	}
	else if(answer == 3)
	{
		fwFsmTree_askRenameNode(parent, node, redo, new_node);
		dynAppend(redo_nodes,new_node);
//		if(parent != "FSM")
			redo_node_parent = parent;		
	}
	else if(answer == 4)
	{
		fwUi_informUserProgress("Please wait - Cutting Nodes ...", 100,60);
		PasteNode = node;
		fwTree_cutNode(parent,PasteNode, exInfo);
//		if(parent != "FSM")
			dynAppend(redo_nodes,parent);
		redo = 1;
	}
	else if(answer == 5)
	{
		fwUi_informUserProgress("Please wait - Pasting Nodes ...", 100,60);
		fwTree_pasteNode(node, PasteNode, exInfo);
		dynAppend(redo_nodes,PasteNode);
//		if(node != "FSM")
			redo_node_parent = node;		
		PasteNode = "";
		redo = 1;
	}
	else if(answer == 6)
	{
		if(parent ==  node)
		{
			fwFsmTree_parametrizeTree();
		}
		else
		{
			ret = fwFsmTree_parametrizeTreeNode(parent, node, redo);
			if(ret)
				fwUi_informUserProgress("Please wait...", 100,60);
			dynAppend(redo_nodes,node);
			if(parent != "FSM")
				redo_node_parent = parent;
		}
	}
	else if(answer == 7)
	{
		if(parent ==  node)
		{
			fwFsmTree_generateAll();
		}
		else
		{
			fwUi_informUserProgress("Please wait...", 100,60);
			fwFsmTree_generateTreeNode(node);
			fwUi_uninformUserProgress(1);
		}
	}
	else if(answer == 8)
	{
		fwFsmTree_askTypeNode(parent, node, redo);
		dynAppend(redo_nodes,node);
		if(parent != "FSM")
			redo_node_parent = parent;
	}
	else if(answer == 9)
	{
		fwFsmTree_askUpdateReference(parent, node, redo);
//		dynAppend(redo_nodes, node);
		if(parent != "FSM")
			redo_node_parent = parent;
	}
	if(answer == 10)
	{
		fwFsmTree_askAddNode(node, redo, new_nodes, "Device");
		dynAppend(redo_nodes, new_nodes);
		if(node != "FSM")
			redo_node_parent = node;
	}
	if(answer == 11)
	{
		fwFsmTree_askAddNode(node, redo, new_nodes, "Object");
		dynAppend(redo_nodes, new_nodes);
		if(node != "FSM")
			redo_node_parent = node;
	}
	if(answer == 12)
	{
	}
//	if(answer == 13)
//	{
//		if(isFunctionDefined("fwTreeUser_displayNode"))
//		{
//			fwTree_getNodeDevice(node, dev, type, exInfo);
//			fwTreeUser_displayNode(node, dev, type);
//		}
//	}
	if(answer == 14)
	{
		fwFsmTree_askAddNode("FSM", redo, new_nodes, "Object");
		dynAppend(redo_nodes, new_nodes);
	}
	if(answer == 15)
	{
//		fwFsmTree_askReorderNode(node, redo);
		fwTreeDisplay_askReorderNodeStd(node, redo);
		dynAppend(redo_nodes, node);
	}
	if(answer == 20)
	{
		fwFsmTree_askAddSpecialNode(node, redo, new_node, "Object");
		dynAppend(redo_nodes,new_node);
		if(node != "FSM")
			redo_node_parent = node;
	}
	if(answer == 21)
	{
		fwFsmTree_accessTreeNode(node);
	}
	if(answer == 22)
	{
		fwFsmTree_confDBTreeNode(node);
	}
	if(answer == 23)
	{
		if(parent == node)
		{
			fwFsmTree_parametrizeTreeAdvanced();
		}
	}
	else if(answer == 24)
	{
			ret = fwFsmTree_parametrizeTreeNodeAdvanced(parent, node, redo);
			if(ret)
				fwUi_informUserProgress("Please wait...", 100,60);
			dynAppend(redo_nodes,node);
			if(parent != "FSM")
				redo_node_parent = parent;
	}
	if(answer == 100)
	{
		new_node = fwFsmTree_askRemoveNode(parent, node, redo);
		dynAppend(redo_nodes,new_node);
	}
	if(redo)
	{
//DebugN("redo", answer, redo, redo_node_parent, redo_nodes);
		if(answer == 5)
		{
			fwTreeDisplay_setRedoTreeNode(FwActiveTrees[CurrTreeIndex], "---ClipboardFSM---");
//			delay(1);
		}
		if(redo_node_parent != "")
		{
			if(!fwFsm_isDomain(redo_node_parent))
			{
				fwTree_getCUName(redo_node_parent, redo_node_parent, exInfo);
				if(redo_node_parent == "")
					redo_node_parent = "FSM";
			}
//DebugN("node_parent", redo_node_parent);
			if((redo_node_parent != "FSM") && (redo_node_parent != fwFsm_clipboardNodeName))
			{
				fwUi_informUserProgress("Please wait...", 100,60);
				fwFsmTree_generateTreeNode(redo_node_parent, 0);
//				fwUi_uninformUserProgress(1);
			}
			fwTreeDisplay_setRedoTreeNode(FwActiveTrees[CurrTreeIndex], redo_node_parent);
		}
		for(i = 1; i <= dynlen(redo_nodes); i++)
		{
			if(!fwFsm_isDomain(redo_nodes[i]))
			{
				fwTree_getCUName(redo_nodes[i], redo_nodes[i], exInfo);
				if(redo_nodes[i] == "")
					redo_nodes[i] = "FSM";
			}
//DebugN("nodes", i, redo_nodes[i]);
			if(redo_nodes[i] != redo_node_parent)
			{
				if((redo_nodes[i] != "FSM") && (redo_nodes[i] != fwFsm_clipboardNodeName))
				{
					fwUi_informUserProgress("Please wait...", 100,60);
					fwFsmTree_generateTreeNode(redo_nodes[i], 0);
//					fwUi_uninformUserProgress(1);
				}
				fwTreeDisplay_setRedoTreeNode(FwActiveTrees[CurrTreeIndex], redo_nodes[i]);
			}
		}
		if((answer == 2) || (answer == 4))
		{
			fwTreeDisplay_setRedoTreeNode(FwActiveTrees[CurrTreeIndex], "---ClipboardFSM---");
//			delay(1);
		}
		if(RedoExtraNode != "")
		{
			fwTreeDisplay_setRedoTreeNode(FwActiveTrees[CurrTreeIndex], RedoExtraNode);
			RedoExtraNode = "";
		}
/*
		else
			fwTreeDisplay_setRedoTreeNode(FwActiveTrees[CurrTreeIndex], redo_nodes[1]);
*/
/*
			if((redo_node_parent == "FSM") || (redo_node_parent == fwFsm_clipboardNodeName))
				redo_node_parent = "";
			fwFsmTree_generateTreeNode(redo_node, 0, redo_node_parent);
*/
	}
	fwUi_uninformUserProgress(1);
}

fwFsmTree_redoTree()
{
	fwTreeDisplay_setRedoTree(FwActiveTrees[CurrTreeIndex]);
}

fwFsmTree_navigator(string node, string parent)
{
dyn_string txt, children, exInfo;
int answer, ret, cu, fsm_type;;
string device, type;

	fwFsm_initialize();
//	ActiveTree = 2;
//	node = _fwTree_getCurrentTreeNode();
	fwTree_getNodeCU(node, cu, exInfo);
//	fsm_type = _fwTree_isFsmHierarchy(node);
//	if(parent == node)
//		parent = "";
	if(parent != node)
	{
		dynAppend(txt,"PUSH_BUTTON, View, 5, 1");
		if((cu) && (!fwFsm_isObjectReference(node)))
		{
			dynAppend(txt,"SEPARATOR");
			dynAppend(txt,"PUSH_BUTTON, Start/Restart Node, 1, 1");
			dynAppend(txt,"PUSH_BUTTON, Stop Node, 2, 1");
			fwTree_getChildren(node,children, exInfo);
			if(dynlen(children))
			{
				dynAppend(txt,"SEPARATOR");
				dynAppend(txt,"PUSH_BUTTON, Start/Restart Tree, 3, 1");
				dynAppend(txt,"PUSH_BUTTON, Stop Tree, 4, 1");
			}
		}
	}
	else
	{
		dynAppend(txt,"PUSH_BUTTON, Start/Restart ALL, 6, 1");
		dynAppend(txt,"PUSH_BUTTON, Stop ALL, 7, 1");
		dynAppend(txt,"PUSH_BUTTON, Restart PVSS00smi, 8, 1");
		dynAppend(txt,"PUSH_BUTTON, Restart PVSS00ctrl, 9, 1");
	}
	popupMenu(txt,answer);
	if(answer == 1)
	{
		fwFsmTree_startTreeNode(node,0);
	}
	if(answer == 2)
	{
		fwFsmTree_stopTreeNode(node,0);
	}
	if(answer == 3)
	{
		fwFsmTree_startTreeNode(node,1);
	}
	else if(answer == 4)
	{
		fwFsmTree_stopTreeNode(node,1);
	}
	else if(answer == 5)
	{
//		if(fwFsm_isObjectReference(node) == 1)
		if(fwFsm_isObjectReference(node))
		{
//			node = fwFsm_getReferencedObject(node);
			fwTree_getNodeDevice(node, device, type, exInfo);
			node = fwFsm_extractSystem(device);
		}
//		else
//		{
			if(cu)
				parent = node;
//			else
//				parent = _fwTree_getCurrentTreeParent();
//		}
		node = fwFsm_convertToAssociated(node);
		if(fwFsm_isAssociated(node))
		{
			parent = fwFsm_getAssociatedDomain(node);
			node = fwFsm_getAssociatedObj(node);
		}
		if(!fwFsm_isDomain(parent))
		{
			string parent_parent;

			fwTree_getCUName(parent, parent_parent, exInfo);
			parent = parent_parent;
		}
		node = fwTree_getNodeDisplayName(node, exInfo);
//		fwUi_showFsmObject(parent, node);
		fwFsmUi_view(parent, node);
	}
	if(answer == 6)
	{
		fwFsmTree_startTree();
	}
	else if(answer == 7)
	{
		fwFsmTree_stopTree();
	}
	else if(answer == 8)
	{
		fwFsmTree_restartPVSS00smi();
	}
	else if(answer == 9)
	{
		fwFsmTree_restartPVSS00ctrl();
	}
}

fwFsmTree_askAddSpecialNode(string parent, int &done, string &new_node, string obj_type)
{
	dyn_string ret, exInfo, items;
	dyn_float res;
	string type, node, label, sys, domain, obj, msg, prefix, node_prefix, aux_parent;
	int i, cu, index, noref, cu_noref, isnode;

	done = 0;
	new_node = "";
	ChildPanelOnReturn("fwFSM/ui/fwTreeAddSpecialNode.pnl","Add Node",
		makeDynString(parent, obj_type),
		100,60, res, ret);
	if(res[1])
	{
		msg = "Please Wait - Creating Nodes ...";
		fwUi_informUserProgress(msg, 100,60);
		done = 1;
		type = ret[1];
		cu = ret[2];
		for(i = 3; i <= dynlen(ret); i+=2)
		{
			noref = 0;
			cu_noref = 0;
			node = ret[i];

			new_node = fwFsmTree_addTreeNode(parent, node, type, cu);
			if(strpos(new_node,"!") == 0)
			{
				label = substr(new_node,1);
				new_node = "";
				fwUi_warnUser("Node "+label+" already exists, Not created", 
				100,60);
				done = 0;
				return;
			}
		}			
	}
}

fwFsmTree_askAddNode(string parent, int &done, dyn_string &new_nodes, string obj_type)
{
	dyn_string ret, exInfo, items;
	dyn_float res;
	string type, node, label, sys, domain, obj, msg, prefix, node_prefix, aux_parent, new_node;
	int i, cu, index, noref, cu_noref, isnode;

	done = 0;
	dynClear(new_nodes);
	ChildPanelOnReturn("fwFSM/ui/fwTreeAddNode.pnl","Add Node",
		makeDynString(parent, obj_type),
		100,60, res, ret);
	if(!dynlen(res))
		return;
	if(res[1])
	{
		msg = "Please Wait - Creating Nodes ...";
		fwUi_informUserProgress(msg, 100,60);
		done = 1;
		type = ret[1];
		cu = ret[2];
		for(i = 3; i <= dynlen(ret); i+=2)
		{
			noref = 0;
			cu_noref = 0;
			node = ret[i];

			new_node = fwFsmTree_addTreeNode(parent, node, type, cu);
//DebugN("Adding", parent, node, type, cu, new_node);
			if(strpos(new_node,"!") == 0)
			{
				label = substr(new_node,1);
				new_node = "";
				fwUi_warnUser("Node "+label+" already exists, Not created", 
				100,60);
				if(i == 3)
					done = 0;
				return;
			}
			if(cu)
				dynAppend(new_nodes, new_node);
		}			
	}
}

string fwFsmTree_checkSubDevice(string node)
{
	string dev, str;

	dev = node;
	if(strpos(dev,".") >= 0)
	{
		strreplace(dev,".","/");
		if(dpExists(node))
		{
			str = dpGetAlias(node);
			if(str == "")
			{
				dpSetAlias(node, dev);
			}
		}
	}
	if(dev != node)
		return dev;
	return "";	
}


fwFsmTree_removeSingleNode(string parent, string node)
{
int i, cu;
dyn_string children, exInfo;
/*
	fwTreeDisplay_callUser2(
		FwActiveTrees[CurrTreeIndex]+"_nodeRemoved",
		node, parent);
*/
	FSM_nodeRemoved(node, parent);
/*
	fwTree_getChildren(node, children, exInfo);
	if(dynlen(children))
	{
		for(i = 1; i <= dynlen(children); i++)
		{
			fwTree_cutNode(node, children[i], exInfo);
		}
	}
*/
	fwTree_removeNode(parent, node, exInfo);
}

//fwFsmTree_removeNode: 
/**  Remove a node from the FSM Tree.
 	
Usage: JCOP framework internal, public

PVSS manager usage: VISION, CTRL

      @param parent: The parent name ("FSM" for root nodes).
      @param node: the name of the node to be removed.
      @param recurse: 0 = only node, 1 = recursively remove also children (default).
*/

fwFsmTree_removeNode(string parent, string node, int recurse = 1)
{
dyn_string children, exInfo;
int i;

	strreplace(node,".","/");
	if(recurse)
	{
		fwTree_getChildren(node, children, exInfo);
		for(i = 1; i <= dynlen(children); i++)
		{
			fwFsmTree_removeNode(node, children[i], recurse);
		}
	}
	fwFsmTree_removeSingleNode(parent, node);
}

//fwFsmTree_addNode: 
/**  Add a node to the FSM Tree.
 	
Usage: JCOP framework internal, public

PVSS manager usage: VISION, CTRL

      @param parent: The parent name ("FSM" for root nodes).
      @param node: the name of the node (CU, DU or local object) to be added.
		   Can contain a system prefix if on a different system.
      @param type: the FSM Object type (must be defined in advance using the DEN)
      @param cu: flag specifying wether to add it as CU or not.
*/

string fwFsmTree_addNode(string parent, string node, string type, int cu)
{
string new_node;

	new_node = fwFsmTree_addTreeNode(parent, node, type, cu);
	if(strpos(new_node,"!") == 0)
		return "";
	return new_node;
}

string fwFsmTree_addTreeNode(string parent, string node, string type, int cu)
{
	dyn_string ret, exInfo, items;
	dyn_float res;
	string label, sys, domain, obj, msg, prefix, node_prefix, aux_parent, dev;
	int i, index, noref, cu_noref, isnode;
	string new_node;

	label = node;
	label = fwFsm_extractSystem(label);
	node = fwFsm_convertToAssociated(node);
	prefix = "";
	node_prefix = "";
	sys = fwFsm_getSystem(node);
	node = fwFsm_extractSystem(node);
	if(sys == "")
		sys = fwFsm_getSystemName();	
	if(!fwFsm_isAssociated(node))
	{
		if(!cu)
		{
//DebugN("isCU",fwFsm_isCU(label,label));
			if(fwFsm_isDomainInSys(label, sys))
			{
				node_prefix = node +"::";
			}
			else
			{
				if(fwFsm_isProxyType(type))
				{
					dev = fwFsmTree_checkSubDevice(node);
					if(dev != "")
					{
						node = label = dev;
					}
					noref = 1;
				}
				else
				{
//					prefix = parent +"|";
//					node_prefix = parent +"::";
				}
			}
		}
		else
		{
			fwTree_getParent(label, aux_parent, exInfo);
			if(aux_parent == "FSM")
				cu_noref = 1;
		}
		dev = label;
	}
	else
	{
		label = fwFsm_convertToAssociated(label);
		node_prefix = fwFsm_getAssociatedDomain(label)+"::"; 
		label = fwFsm_getAssociatedObj(label);
//		prefix = "&1";
		prefix = "";
		dev = label;
		label = fwTree_makeNodeRef(label, exInfo);
	}
//new	node = node_prefix+fwFsm_getPhysicalDeviceName(sys+":"+dev);
	node = node_prefix+dev;
	node = sys+":"+node;
	label = prefix+label;
	isnode = fwTree_isNode(label, exInfo);
/*
	if(isnode && !fwFsmTree_isFsmHierarchy(sys+":"+label))
	{
		new_node = "!"+label;
		return new_node;
	}
*/
	if(isnode)
        {
		fwTree_getParent(label, aux_parent, exInfo);
		if(aux_parent == parent)
		{
			new_node = "!"+label;
			return new_node;
		}
	}
	if(((isnode == 1) && (!cu_noref)) || ((isnode == 2) && (!noref)))
	{
		string tmp_label;
//		tmp_label = label;
//		fwFsm_makeObjectReference(tmp_label, label);
//		fwTree_addNode(parent, label, exInfo);
		label = fwTree_createNode(parent, label, exInfo);
		fwTree_setNodeDevice(label, node, type, exInfo);
		fwTree_setNodeCU(label,cu, exInfo);
		new_node = label;
	}
	else
	{
		fwTree_addNode(parent, label, exInfo, 1);
		fwTree_setNodeDevice(label, node, type, exInfo);
		fwTree_setNodeCU(label,cu, exInfo);
		new_node = label;
	}
	fwFsmTree_setNodeDefaultUserData(new_node);
	if(isnode)
		RedoExtraNode = aux_parent;
	return new_node;
}

//fwFsmTree_isNode: 
/**  Check if a node exists in the FSM Tree.
 	
Usage: JCOP framework internal, public

PVSS manager usage: VISION, CTRL

      @param node: the name of the node (CU, DU or local object) to check.
		   Can contain a system prefix, and can also be of the form <CU>::<obj>.
      @return 1 for yes in local system, 2 for yes remotely, 0 for no
*/

int fwFsmTree_isNode(string node)
{
  int ret, exists, i;
  dyn_string children, exInfo;
  string domain, obj, sys, dev, type;
  
  if(fwFsm_isAssociated(node))
  {
    domain = fwFsm_getAssociatedDomain(node);
    obj = fwFsm_getAssociatedObj(node);
    if((exists = fwFsmTree_isNode(domain)))
    {
      if(exists == 2)
      {
        if(strpos(domain,":") < 0)
        {
          sys = fwTree_getNodeSys(domain, exInfo);
          domain = sys+":"+domain;
        }
      }
      fwTree_getChildren(domain, children, exInfo);
      if(dynContains(children, obj))
        return exists;
      else
      {
        for(i = 1; i <= dynlen(children); i++)
        {
          if(fwTree_getNodeDisplayName(children[i], exInfo) == obj)
          {
            return exists;
          }
        }
      }
    }
    return 0;
  }
  else
  {
    return fwTree_isNode(node, exInfo);
  }
}

/*
int fwFsmTree_isNode(string node)
{
dyn_string exInfo;

	return fwTree_isNode(node, exInfo);
}
*/

fwFsmTree_setNodeDefaultUserData(string node)
{
string cu, obj, type;
dyn_string udata, exInfo;

	fwTree_getCUName(node, cu, exInfo);
	fwTree_getNodeDevice(node, obj, type, exInfo);
	obj = fwFsm_extractSystem(obj);
//	fwFsm_setObjectLabelPanel(cu, obj, label, "", -1, -1);	
	fwTree_getNodeUserData(node, udata, exInfo);
	udata[1] = 1;
	udata[2] = 1;
	udata[3] = fwFsm_getDefaultLabel(cu, obj);
	udata[4] = "";
	fwTree_setNodeUserData(node, udata, exInfo);
}

//fwFsmTree_addMajorityNode: 
/**  Add a majority node to an FSM Tree Node.
 	
Parameres are as in Majority panel

Usage: JCOP framework internal, public

PVSS manager usage: VISION, CTRL

      @param parent: The parent name (CU or LU), returned by fwFsmtree_addNode(...)
      @param type: the Type of objects for which the majority applies
      @param op: Operation: "more" than n objects or "less" then n objects
      @param threshold: the number n for the ERROR threshold
      @param states: the list of bad (if "more") or good (if "less") states.
      @param or_out_flag: if set if the object is disabled/excluded it counts too.
      @param and_in_flag: if set if the object is enabled/included it counts too.
      @param low_threshold: (optional) a WARNING threshold, default = 1.
*/

string fwFsmTree_addMajorityNode(string node, string type, string op, int threshold, dyn_string states,
	int or_out_flag, int and_in_flag, int low_threshold = 1)
{
	string maj_name;

	maj_name = fwFsmTree_createMajorityDp(node, type, op, threshold, states, or_out_flag, and_in_flag, low_threshold);
	return fwFsmTree_addNode(node, maj_name, "FwDevMajority", 0);
}

//fwFsmTree_setNodeLabel: 
/**  Change the label for an FSM Tree Node.

Usage: JCOP framework internal, public

PVSS manager usage: VISION, CTRL

      @param node: The node name (returned by fwFsmtree_addNode(...))
      @param label: the new Label
*/

fwFsmTree_setNodeLabel(string node, string label)
{
string cu, obj, type;
dyn_string udata, exInfo;

//	fwTree_getCUName(node, cu, exInfo);
//	fwTree_getNodeDevice(node, obj, type, exInfo);
//	obj = fwFsm_extractSystem(obj);
//	fwFsm_setObjectLabelPanel(cu, obj, label, "", -1, -1);	
	fwTree_getNodeUserData(node, udata, exInfo);
//	udata[1] = 1;
//	udata[2] = 1;
	udata[3] = label;
//	udata[4] = "";
	fwTree_setNodeUserData(node, udata, exInfo);
}

string fwFsmTree_getNodeLabel(string node)
{
string label;
dyn_string udata, exInfo;

	fwTree_getNodeUserData(node, udata, exInfo);
	label = udata[3];
	return label;
}

//fwFsmTree_setNodePanel: 
/**  Change the user panel for an FSM Tree Node.

Usage: JCOP framework internal, public

PVSS manager usage: VISION, CTRL

      @param node: The node name (returned by fwFsmtree_addNode(...))
      @param panel: the new Panel name
*/

fwFsmTree_setNodePanel(string node, string panel)
{
string cu, obj, type;
dyn_string udata, exInfo;

//	fwTree_getCUName(node, cu, exInfo);
	fwTree_getNodeDevice(node, obj, type, exInfo);
//	obj = fwFsm_extractSystem(obj);
//	fwFsm_setObjectLabelPanel(cu, obj, "", panel, -1, -1);	
	if(panel != type+".pnl")
	{
		fwTree_getNodeUserData(node, udata, exInfo);
//		udata[1] = 1;
//		udata[2] = 1;
//		udata[3] = label;
		udata[4] = panel;
		fwTree_setNodeUserData(node, udata, exInfo);
	}
}

//fwFsmTree_setNodeVisibility: 
/**  Change the visibility (wether it gets displayed or not) for an FSM Tree Node.

Usage: JCOP framework internal, public

PVSS manager usage: VISION, CTRL

      @param node: The node name (returned by fwFsmtree_addNode(...))
      @param visi: 0 = not visible, 1 = visible (default)
*/

fwFsmTree_setNodeVisibility(string node, int visi = 1)
{
string cu, obj, type;
dyn_string udata, exInfo;

//	fwTree_getCUName(node, cu, exInfo);
//	fwTree_getNodeDevice(node, obj, type, exInfo);
//	obj = fwFsm_extractSystem(obj);
//	fwFsm_setObjectLabelPanel(cu, obj, "", "", visi, -1);	
	fwTree_getNodeUserData(node, udata, exInfo);
	udata[1] = visi;
//	udata[2] = 1;
//	udata[3] = label;
//	udata[4] = panel;
	fwTree_setNodeUserData(node, udata, exInfo);
}

int fwFsmTree_getNodeVisibility(string node)
{
string cu, obj, type;
dyn_string udata, exInfo;
int visi;

	fwTree_getNodeUserData(node, udata, exInfo);
	visi = udata[1];
	return visi;
}

//fwFsmTree_setNodeAccessControl: 
/**  Change the Domain/Privilege(s) level of an FSM Tree Node.

Usage: JCOP framework internal, public

PVSS manager usage: VISION, CTRL

      @param node: The node name (returned by fwFsmtree_addNode(...))
      @param access: the new Domain:Privilege[|Domain:Privilege] level
*/

fwFsmTree_setNodeAccessControl(string node, string access)
{
dyn_string udata, exInfo;

	fwTree_getNodeUserData(node, udata, exInfo);
	udata[5] = access;
	fwTree_setNodeUserData(node, udata, exInfo);
}

//fwFsmTree_getNodeAccessControl: 
/**  Get the Domain/Privilege(s) level of an FSM Tree Node.

Usage: JCOP framework internal, public

PVSS manager usage: VISION, CTRL

      @param node: The node name (returned by fwFsmtree_addNode(...))
      @param access: the current Domain:Privilege[|Domain:Privilege] level
*/

fwFsmTree_getNodeAccessControl(string node, string &access)
{
dyn_string udata, exInfo;

	access = "";
	fwTree_getNodeUserData(node, udata, exInfo);
	if(dynlen(udata) >= 5)
		access = udata[5];
}

FSM_nodeRemoved(string node, string parent)
{
	fwFsmTree_cleanupNode(parent, node);
}

dyn_string fwFsmTree_cleanupNode(string parent, string node)
{
int cu;
dyn_string children, exInfo;
string device, type, dp;

	if(parent != "FSM")
	{
		fwUi_getObjDp(parent, parent, dp);
		dp += ".";
		fwFsm_removeSummaryAlarm(dp);
	}
	fwTree_getNodeCU(node, cu, exInfo);
	if(cu)
	{
		if(fwFsm_isObjectReference(node))
		{
//			device = fwFsm_getReferencedObject(node);
			device = fwTree_getNodeDisplayName(node, exInfo);
		}
		else
		{
			fwTree_getChildren(node, children, exInfo);
			fwFsm_deleteDomain(node);
			device = node;
		}
		fwFsm_deleteDomainRef(parent, device);
	}
	else
	{
		fwTree_getNodeDevice(node, device, type, exInfo);
		device = fwFsm_extractSystem(device);
		if(!fwFsm_isDomain(parent))
		{
			fwTree_getCUName(parent, parent, exInfo);
		}
		fwFsm_deleteDomainDevice(parent, device);
	}
	return(children);
}

string fwFsmTree_askRemoveNode(string parent, string node, int &done)
{
	string ret;

	done = 0;
	ret = fwTreeDisplay_askRemoveNodeStd(parent, node, done);
	return ret;
}


fwFsmTree_checkReferences(string node, dyn_string &refs, dyn_string &syss, dyn_string &cus, dyn_string &lus)
{
	string ref_parent, ref_cu, child;
	dyn_string exInfo, children, more_refs, more_syss;
	int i, j;

	fwFsm_getObjectReferences(node, refs, syss);
	for(i = 1; i <= dynlen(refs); i++)
	{
		fwTree_getParent(syss[i]+":"+refs[i], ref_parent, exInfo);
		fwTree_getCUName(syss[i]+":"+refs[i], ref_cu, exInfo);
		dynAppend(lus, ref_parent);
		dynAppend(cus, ref_cu);
//DebugN(syss[i]+":"+refs[i], ref_parent, ref_cu);
	}
//	fwTree_getChildren(node, children, exInfo);
	fwFsmTree_getChildrenRec(node, children);
	for(i = 1; i <= dynlen(children); i++)
	{
		fwFsm_getObjectReferences(children[i], more_refs, more_syss);
		for(j = 1; j <= dynlen(more_refs); j++)
		{
			fwTree_getParent(more_syss[j]+":"+more_refs[j], ref_parent, exInfo);
			fwTree_getCUName(more_syss[j]+":"+more_refs[j], ref_cu, exInfo);
			dynAppend(lus, ref_parent);
			dynAppend(cus, ref_cu);
		}
		dynAppend(refs, more_refs);
		dynAppend(syss, more_syss);
	}
}


fwFsmTree_renameRef(string new_child, string new_node, string device, string type)
{
string sys, domain, dev, new_device, new_type;
dyn_string exInfo;
int flag;

	flag = 0;
	fwTree_getNodeDevice(new_child, new_device, new_type, exInfo);
	if(device != "")
	{
		new_device = device;
		flag = 1;
	}
	if(type != "")
	{
		new_type = type;
	}
	sys = fwFsm_getSystem(new_device);
	new_device = fwFsm_extractSystem(new_device);
	if(fwFsm_isAssociated(new_device))
	{
		domain = fwFsm_getAssociatedDomain(new_device);
		dev = fwFsm_getAssociatedObj(new_device);
		if(flag)
		{
			if(new_node != "")
			{
				if(dev == domain)
					domain = new_node;
				dev = new_node;
			}
		}
		else
		{
			if(dev == domain)
				dev = new_node;
			domain = new_node;
		}
		new_device = sys+":"+domain+"::"+dev;
	}
	else
	{
		if(new_node != "")
		{ 
			dev = new_node;
			new_device = sys+":"+dev;
		}
		else
		{
			new_device = sys+":"+new_device+"::"+new_device;
		}
	}		
	fwTree_setNodeDevice(new_child, new_device, new_type, exInfo);
}

FSM_nodeRenamed(string node, string new_node)
{
	string device, type, sys;
	dyn_string userData, exInfo;
	int cu, refnew;
	string refnode, refnewnode, parent, dev;

	refnew = fwFsm_isObjectReference(new_node);
	fwTree_getNodeDevice(new_node, device, type, exInfo);
	fwTree_getNodeCU(new_node, cu, exInfo);
	fwTree_getParent(new_node, parent, exInfo);
	fwTree_getNodeUserData(new_node, userData, exInfo);
	refnode = fwTree_getNodeDisplayName(node, exInfo);
	refnewnode = fwTree_getNodeDisplayName(new_node, exInfo);
	if(userData[3] == refnode)
	{
		userData[3] = refnewnode;
		fwTree_setNodeUserData(new_node, userData, exInfo);
	}
	if((cu) && (!refnew))
		fwFsm_deleteDomain(node);
	else
	{
		dev = fwFsm_extractSystem(device);
		fwFsm_deleteDomainDevice(parent, dev);
	}
	if(refnew)
	{
		fwFsmTree_renameRef(new_node, refnewnode, device, type);
	}
	else		
	{
		sys = fwFsm_getSystem(device);
		device = sys+":"+refnewnode;
		fwTree_setNodeDevice(new_node, device, type, exInfo);
	}
}

int fwFsmTree_getReferences(string node, string action, int &answer)
{
	dyn_string refs, syss, cus, lus, exInfo;
	int i;
	string ref;

	addGlobal("ReferenceList",DYN_STRING_VAR);
	fwFsmTree_checkReferences(node, refs, syss, cus, lus);
	answer = 1;
	if(dynlen(refs))
	{
		for(i = 1; i <= dynlen(refs); i++)
		{
//			ref = fwFsm_getReferencedObject(refs[i]);
			ref = fwTree_getNodeDisplayName(refs[i], exInfo);
			dynAppend(ReferenceList,ref);
			dynAppend(ReferenceList,lus[i]);
			dynAppend(ReferenceList,cus[i]);
			dynAppend(ReferenceList,syss[i]);
		}
//		if(fwFsm_isObjectReference(node) == 2)
//			node = fwFsm_getReferencedObject(node);
		node = fwTree_getNodeDisplayName(node, exInfo);
		fwUi_askUserReferences("Are you sure you want to "+action+" "+node+"?", 
			100,60, 0, answer);
		if(answer == 0)
		{
			removeGlobal("ReferenceList");
		}
		return 1;
	}
	return 0;
}

fwFsmTree_askRenameNode(string parent, string node, int &done, string &redo_node)
{
	dyn_string ret, children, exInfo, refs, syss, domains;
	dyn_float res;
	string device, type, node_name, new_node, new_node_name, sys, dev, child;
	int cu, cup, i, j, answer, ref;
	string label, ref_node, ref_parent;
	int allow_duplicate = 0;

	done = 0;
	fwFsmTree_getReferences(node, "Rename", answer);
	if(answer == 0)
		return;
	fwTree_getNodeCU(node, cu, exInfo);
	if(!cu)
		allow_duplicate = 1;
	new_node = fwTreeDisplay_askRenameNodeStd(node, allow_duplicate, done);
	if(done)
	{
			redo_node = new_node;
		if(dynlen(ReferenceList))
			fwUi_warnUserReferences("",100,60);
	}
	removeGlobal("ReferenceList");
}

fwFsmTree_getChildrenRec(string node, dyn_string &objs)
{
	int i, cu;
	dyn_string children, exInfo;
		
	fwTree_getChildren(node, children, exInfo);
	for(i = 1; i <= dynlen(children); i++)
	{
		dynAppend(objs, children[i]);
		fwTree_getNodeCU(children[i], cu, exInfo);
		if(!cu)
			fwFsmTree_getChildrenRec(children[i], objs);
	}
}

string fwFsmTree_checkReferenceValid(string ref, int &valid)
{
	string device, type, node, sys, domain, device1, type1, sys1, ret;
	dyn_string exInfo, children;
	int i, cu;

	valid = 0;
	fwTree_getNodeDevice(ref, device, type, exInfo);
//DebugN(ref, device, exInfo);
	sys = fwFsm_getSystem(device);
	device = fwFsm_extractSystem(device);
	if(fwFsm_isAssociated(device))
	{
		domain = fwFsm_getAssociatedDomain(device);
		device = fwFsm_getAssociatedObj(device);
//DebugN(domain, device, sys+":"+domain);
		if(fwTree_isNode(sys+":"+domain, exInfo))
		{
//DebugN("is node");
			if(domain == device)
			{
				fwTree_getNodeCU(sys+":"+domain, cu, exInfo);
				if(cu)
					valid = 2;
				else
				{
					valid = 3;
					ret = sys+":"+domain;
				}
			}
			else
			{
//				fwTree_getChildren(sys+":"+domain, children, exInfo);
				fwFsmTree_getChildrenRec(sys+":"+domain, children);
//DebugN(sys+":"+domain, children);
				for(i = 1; i <= dynlen(children); i++)
				{
					fwTree_getNodeDevice(sys+":"+children[i], device1, type1, exInfo);
					sys1 = fwFsm_getSystem(device1);
					device1 = fwFsm_extractSystem(device1);
//DebugN(sys+":"+domain, children[i], device1, device);
					if(device1 == device)
					{
						fwTree_getNodeCU(sys+":"+children[i], cu, exInfo);
						if(!cu)
							valid = 2;
						else
							valid = 3;
					}
				}
			}
		}
		else
		{
//DebugN("is not node", exInfo);
			if(domain != device)
				valid = 1;
		}		
	}
	else
	{
		domain = device;
		if(fwTree_isNode(sys+":"+domain, exInfo))
			valid = 2;		
	}
//DebugN("valid", valid);
	return ret;
}


fwFsmTree_askUpdateReference(string parent, string node, int &done)
{
	dyn_string ret, children, exInfo, refs, syss, domains;
	dyn_float res;
	string device, type, node_name, new_node, new_node_name, sys, dev, child;
	int cu, cup, i, j, valid;
	string label, ref_parent, guess, tnode;

	done = 0;
	tnode = fwFsmTree_checkReferenceValid(node, valid);
	if(valid == 2)
	{
		fwUi_informUser("Reference is correct",100,60, "Ok");
		return;
	}
	if(globalExists("LastRenamedNode"))
		guess = LastRenamedNode;
	else
	{
//DebugN("LastRenamedNode doesn't exist");
		guess = "";
	}
	if(valid == 3)
		guess = tnode;
//DebugN(node, guess, valid);
	ChildPanelOnReturn("fwFSM/ui/fwTreeUpdateReference.pnl","Rename Node",
		makeDynString(node, guess, valid),
		100,60, res, ret);
	if(res[1])
	{
		done = 1;
		new_node = ret[1];
		if(!globalExists("LastRenamedNode"))
			addGlobal("LastRenamedNode",STRING_VAR);
		LastRenamedNode = new_node;
//DebugN("Got", new_node);
		if(valid == 0)
		{
			new_node = fwFsm_extractSystem(new_node);
			label = fwTree_makeNode(new_node, exInfo);
			new_node = label;
			fwTree_renameNode(node, label, exInfo);
			FSM_nodeRenamed(node, label);
		}
		else if(valid == 1)
		{
			fwFsmTree_renameRef(node, new_node, "", "");
		}
		else if(valid == 3)
		{
			fwFsmTree_renameRef(node, "", new_node, "");
		}
//DebugN("new_node", new_node, valid);
	}
}

fwFsmTree_askTypeNode(string parent, string node, int &done)
{
	dyn_string ret, exInfo;
	dyn_float res;
	string device, type, new_type, ref_node;
	int ref;

	done = 0;

	if(fwFsm_isObjectReference(node))
		ref_node = "&";
	ref_node += fwTree_getNodeDisplayName(node, exInfo);

	ChildPanelOnReturn("fwFSM/ui/fwTreeTypeNode.pnl","Change Type of Node",
		makeDynString(ref_node),
		100,60, res, ret);
	if(res[1])
	{
		done = 1;
		new_type = ret[1];

		fwTree_getNodeDevice(node, device, type, exInfo);
		fwTree_setNodeDevice(node, device, new_type, exInfo);
	}
}
	
//fwFsmTree_generateAll: 
/**  Generate the full FSM Tree.
 	
Usage: JCOP framework internal, public

PVSS manager usage: VISION, CTRL

*/
fwFsmTree_generateAll()
{
dyn_string nodes, exInfo;
int i, cu;
dyn_string objs, states;

	fwFsm_initialize(0);
	fwUi_informUserProgress("Please wait...", 100,60);
	fwFsm_generateDeviceTypes();
	fwFsm_generateObjectTypes();
	fwTree_getChildren("FSM",nodes, exInfo);
	for(i = 1; i <= dynlen(nodes); i++)
	{
//		if(nodes[i] != fwFsm_clipboardNodeName)
//		{
			fwTree_getNodeCU(nodes[i],cu, exInfo);
			if(cu)
			{
				fwFsmTree_generateTreeNode(nodes[i]);
			}
//		}
	}
	fwUi_uninformUserProgress(1);
}

//fwFsmTree_generateFsmTypes: 
/**  Generate only the Object/Device Types (Not the FSM Tree).
 	
Usage: JCOP framework internal, public

PVSS manager usage: VISION, CTRL

*/
fwFsmTree_generateFsmTypes()
{

	fwFsm_initialize(0);
	fwUi_informUserProgress("Please wait...", 100,60);
	fwFsm_generateDeviceTypes();
	fwFsm_generateObjectTypes();
	fwUi_uninformUserProgress(1);
}

fwFsmTree_generateDevice(string node, string child, int rec, 
	dyn_string &objs, dyn_string &types, dyn_string &cus, dyn_string &tnodes)
{
	string obj, type, sys, cu, old_cu, dp, new_dp, node_name, maj_name, maj_type;
	dyn_string items, exInfo;
	int res;

	node_name = fwTree_getNodeDisplayName(node, exInfo);
	if(strpos(child,"_FWMAJ") > 0)
	{
		items = strsplit(child,"/");
		maj_type = items[dynlen(items)];		
		fwTree_getCUName(node, cu, exInfo);
//DebugN("Majority", node, cu, child);
		if(cu == node_name)
			maj_name = cu+"/"+maj_type;
		else
			maj_name = cu+"/"+node_name+"/"+maj_type;
//DebugN("Majority", node, cu, child, maj_name);
		if(child != maj_name)
		{
//DebugN("Error", node, cu, child);
/*
			dp = child;
			items = strsplit(child,"/");
				old_cu = items[1];
			if(node_name == cu)
				strreplace(dp, old_cu+"/","");
			else
			{
				if(dynlen(items) == 3)
					strreplace(dp, old_cu+"/", cu+"/");
				else
					strreplace(dp, old_cu+"/", cu+"/"+old_cu+"/");
			}
*/
			dp = maj_name;
			dpCreate(dp, "FwDevMajority");
			dpCopyOriginal(child, dp, res);
//DebugN("new_dp", old_cu, dp, res);			
			fwTree_renameNode(child, dp, exInfo);
			fwTree_getNodeDevice(dp, obj, type, exInfo);
			fwTree_setNodeDevice(dp, getSystemName()+dp, type, exInfo);
//DebugN("new_dp", old_cu, dp, res, obj, type);			
			dpDelete(child);
			child = dp;			
		}
	}
	fwTree_getNodeDevice(child, obj, type, exInfo);
	sys = fwFsm_getSystem(obj);
	obj = fwFsm_extractSystem(obj);
/*
	dynAppend(objs,obj+"@"+node);
	dynAppend(types,type);
	dynAppend(cus,0);
	dynAppend(tnodes, children[i]);
*/
	if(rec)
	{
//		dynInsertAt(objs,obj+"@"+node_name,1);
		dynAppend(objs,obj+"@"+node_name);
	}
	else
	{
//		dynInsertAt(objs,obj,1);
		dynAppend(objs,obj);
	}
//	dynInsertAt(types,type,1);
//	dynInsertAt(cus,0,1);
//	dynInsertAt(tnodes, child, 1);
	dynAppend(types,type);
	dynAppend(cus,0);
	dynAppend(tnodes, child);
//DebugN("generateDevice", node, child, rec, objs);
}

fwFsmTree_generateChildrenRec(string node, dyn_string &objs, dyn_string &types, 
	dyn_string &cus, dyn_string &tnodes)
{
	int i;
	dyn_string children, exInfo;
	string obj, type, sys;
		
	fwTree_getChildren(node, children, exInfo);
//DebugN("Generating children rec",node, children, types, cus, tnodes);
	for(i = 1; i <= dynlen(children); i++)
	{
/*
		fwTree_getNodeDevice(children[i],obj,type, exInfo);
		sys = fwFsm_getSystem(obj);
		obj = fwFsm_extractSystem(obj);
		dynInsertAt(objs,obj+"@"+node,1);
		dynInsertAt(types,type,1);
		dynInsertAt(cus,0,1);
		dynInsertAt(tnodes, children[i],1);
*/
		fwFsmTree_generateDevice(node, children[i], 1, objs, types, cus, tnodes);		
		fwFsmTree_generateChildrenRec(children[i], objs, types, cus, tnodes);
	}
}

//fwFsmTree_generateTreeNode: 
/**  Generate the FSM Tree starting from a specific node.
 	
Usage: JCOP framework internal, public

PVSS manager usage: VISION, CTRL

      @param node: the name of the node (CU) to generate the tree from.
*/
fwFsmTree_generateTreeNode(string node, int recurse = 1, string parent_node = "")
{
string obj, type, msg, sys, logobj;
dyn_string children, exInfo;
dyn_string objs, types, tnodes;
dyn_int cus;
int i, cu;
int pos, closeInfo = 0;
/*
	if(parent_node != "")
		fwFsmTree_generateTreeNode(parent_node, 0, "");
*/
//DebugN("Generating node "+node);
	fwTree_getNodeCU(node, cu, exInfo);
	if(!cu)
		return;
	fwTree_getChildren(node, children, exInfo);
//DebugN("generating", node, children);
	for(i = 1; i <= dynlen(children); i++)
	{
		fwTree_getNodeCU(children[i], cu, exInfo);
		if(cu)
		{
			fwTree_getNodeDevice(children[i],obj,type, exInfo);
			sys = fwFsm_getSystem(obj);
			if(recurse)
			{
				if((sys == fwFsm_getSystemName()) && (!fwFsm_isObjectReference(children[i])))
					fwFsmTree_generateTreeNode(children[i]);
			}
//			logobj = fwFsm_getLogicalDeviceName(obj);
			obj = fwFsm_extractSystem(obj);
//			dynAppend(objs,logobj+"::"+obj);
//			dynAppend(objs,logobj+"::"+logobj);
			dynAppend(objs,obj+"::"+obj);
			dynAppend(types,type);
			dynAppend(cus,1);
			dynAppend(tnodes, children[i]);
		}
		else
		{
			fwFsmTree_generateDevice(node, children[i], 0, objs, types, cus, tnodes);
			fwFsmTree_generateChildrenRec(children[i], objs, types, cus, tnodes);		
		}
	}
	fwTree_getNodeDevice(node,obj,type, exInfo);
	sys = fwFsm_getSystem(obj);
	if((sys == fwFsm_getSystemName()) && (!fwFsm_isObjectReference(node)))
	{
//		logobj = fwFsm_getLogicalDeviceName(obj);
		obj = fwFsm_extractSystem(obj);
		dynAppend(objs,obj);
//		dynAppend(objs,logobj);
		dynAppend(types,type);
		dynAppend(cus, 1);
		dynAppend(tnodes, node);
//DebugN("creating", node, objs, types, cus, tnodes);
//DebugN(node, objs, types, cus);
		fwFsm_createDomain(node);
		fwFsm_createDomainObjects(node, objs, types, cus, tnodes);
		fwFsm_writeSmiDomain(node);
	}
}

fwFsmTree_recurseOperation(string node, int flag)
{
dyn_string children, exInfo;
int i, cu;
string obj, type;


	fwUi_getChildren(node, children);
	for(i = 1; i <= dynlen(children); i++)
	{
		fwFsmTree_recurseOperation(children[i], flag);
	}
//	fwUi_setDomainOperation(node, flag);
	fwUi_setDomainObjectsOperation(node, flag);
}

fwFsmTree_recursePanel(string node, string panel)
{
dyn_string children, exInfo;
int i, cu;
string obj, type;


	fwUi_getChildren(node, children);
	for(i = 1; i <= dynlen(children); i++)
	{
		fwFsmTree_recurseOperation(children[i], flag);
	}
//	fwUi_setDomainOperation(node, flag);
	fwUi_setDomainObjectsOperation(node, flag);
}

fwFsmTree_parametrizeTreeAdvanced()
{
dyn_float res;
dyn_string ret, componentInfo, nodes, exInfo;
string old_path, path, old_sys, sys, dev, type;
int ok, i, auto_start, start_all_systems, summary_alarms, auto_include, ref_auto_enable;


	ChildPanelOnReturn("fwFSM/ui/fwTreeAdvancedSettings.pnl","Advanced FSM Settings",
		makeDynString(),100, 60, res, ret);
	if(res[1])
	{
		path = ret[1];
		old_sys = ret[2];
		sys = ret[3];
		auto_start = ret[4];
		start_all_systems = ret[5];
		summary_alarms = ret[6];
   auto_include = ret[7];
   ref_auto_enable = ret[8];
		ok = fwInstallation_getComponentInfo("fwFSM", "installationdirectory", componentInfo);
		old_path = componentInfo[1];
		fwUi_informUserProgress("Please wait - Applying Advanced Settings ...", 100,60);
		if(old_path != path)
			dpSet("fwInstallation_" + "fwFSM" + ".installationDirectory", path);
		if(old_sys != sys)
		{
			fwTree_getAllTreeNodes("FSM", nodes, exInfo);
			for(i = 1; i <= dynlen(nodes); i++)
			{
				fwTree_getNodeDevice(nodes[i], dev, type, exInfo);
				if((strpos(dev, old_sys+":") == 0) ||
				   ((strpos(dev,":") < 0) && (old_sys == "")))
				{
					dev = fwFsm_extractSystem(dev);
					dev = sys+":"+dev;
					fwTree_setNodeDevice(nodes[i], dev, type, exInfo);
				}
			}
		}
		if(auto_start != -1)
			dpSet("ToDo.autoStart", auto_start);
		if(start_all_systems != -1)
			dpSet("ToDo.startAllSystems", start_all_systems);
		if(summary_alarms != -1)
			dpSet("ToDo.noSummaryAlarms", (!summary_alarms));
		if(auto_include != -1)
   {
     if(dpExists("ToDo.noAutoInclude"))
			  dpSet("ToDo.noAutoInclude", auto_include);
   }		
		if(ref_auto_enable != -1)
   {
     if(dpExists("ToDo.refAutoEnable"))
			  dpSet("ToDo.refAutoEnable", ref_auto_enable);
   }		
	}
}

fwFsmTree_parametrizeTree()
{
dyn_float res;
dyn_string ret;
string panel;
int w, h;


	ChildPanelOnReturn("fwFSM/ui/fwTreeSettings.pnl","Parameters",
		makeDynString(),100,60, res, ret);
	if(res[1])
	{
		panel = ret[1];
		w = ret[2];
		h = ret[3];
		fwUi_informUserProgress("Please wait - Applying Settings ...", 100,60);
		if(ret[2] != 0)
			fwFsm_setMainPanel(panel, w, h);
		else				
			fwFsm_setMainPanel(panel);
	}
}

int fwFsmTree_parametrizeTreeNode(string parent, string node, int &done)
{
int flag1, flag2, ref, cu;
dyn_float res;
dyn_string ret, exInfo;
string parent_parent, ref_node, device, type;
int ret1 = 0;
	
	done = 0;
	parent_parent = parent;
//DebugN("settings", parent, node);
	if((parent != "FSM") && (!fwFsm_isDomain(parent)))
	{
		fwTree_getCUName(parent, parent_parent, exInfo);
		parent = parent_parent;
	}
	if(fwFsm_isDomain(node))
		parent = node;
//DebugN("isDomain", parent, node);
	fwFsm_setSmiDomain(parent);

	ref_node = fwTree_getNodeDisplayName(node, exInfo);
	if(fwFsm_isObjectReference(node))
	{
//DebugN("isReference", node);
		fwTree_getNodeDevice(node, device, type, exInfo);
		fwTree_getNodeCU(node, cu, exInfo);			
		ref_node = fwFsm_extractSystem(device);
		if(cu)
			ref_node += "::"+ref_node;
//		node = ref_node;
	}
//DebugN(parent_parent, parent, node, ref_node);
//	node = ref_node;
	ChildPanelOnReturn("fwFSM/ui/fwTreeNodeSettings.pnl","Parameters",
		makeDynString(parent, ref_node, node),100,60, res, ret);
	if(res[1])
	{
		ret1 = 1;
		if(ret[5] != "")
		{
			fwTree_getNodeDevice(node, device, type, exInfo);
			fwTree_setNodeDevice(node, device, ret[5], exInfo);
//DebugN("Setting Type", node, device, ret[5]);
			done = 1;
		}
		if(ret[6] != "")
		{
			fwFsmTree_cleanupNode(parent, ref_node);
			fwTree_setNodeCU(node, ret[6], exInfo);
//DebugN("Setting CU", node, ret[6]);
			done = 1;
			return ret1;
		}
		if(ret[7] != "")
		{
			fwFsm_setCUCtrlFlag(node, ret[7]);
//DebugN("Setting CU", node, ret[7]);
			return ret1;
		}
		if((ret[1] != "") || (ret[2] != "") || (ret[3] != "") || (ret[4] != ""))
		{
			flag1 = ret[3];
			flag2 = ret[4];
			if(parent == node)
			{
				if(parent_parent != "FSM")
				{
					fwFsm_setObjectLabelPanel(parent_parent, parent+"::"+ref_node, 
						ret[1], ret[2], flag1, -1);
				}
				fwFsm_setObjectLabelPanel(parent, ref_node, 
					ret[1], ret[2], flag1, -1);
				if(flag2 != -1)
				{
					fwUi_setDomainOperation(ref_node, flag2);
					fwFsmTree_recurseOperation(ref_node, flag2);
				}
			}
			else
			{
				fwFsm_setObjectLabelPanel(parent, ref_node, 
					ret[1], ret[2], flag1, flag2);
			}
		}
	}
	return ret1;
}

int fwFsmTree_parametrizeTreeNodeAdvanced(string parent, string node, int &done)
{
int flag1, flag2, ref, cu;
dyn_float res;
dyn_string ret, exInfo;
string parent_parent, ref_node, device, old_type, type;
int i, ret1 = 0;
	
	done = 0;
	parent_parent = parent;
//DebugN("settings", parent, node);
	if((parent != "FSM") && (!fwFsm_isDomain(parent)))
	{
		fwTree_getCUName(parent, parent_parent, exInfo);
		parent = parent_parent;
	}
	if(fwFsm_isDomain(node))
		parent = node;
//DebugN("isDomain", parent, node);
	fwFsm_setSmiDomain(parent);

	ref_node = fwTree_getNodeDisplayName(node, exInfo);
	if(fwFsm_isObjectReference(node))
	{
//DebugN("isReference", node);
		fwTree_getNodeDevice(node, device, type, exInfo);
		fwTree_getNodeCU(node, cu, exInfo);			
		ref_node = fwFsm_extractSystem(device);
		if(cu)
			ref_node += "::"+ref_node;
//		node = ref_node;
	}
//DebugN(parent_parent, parent, node, ref_node);
//	node = ref_node;
	ChildPanelOnReturn("fwFSM/ui/fwTreeNodeSettingsAdvanced.pnl","Parameters",
		makeDynString(parent, ref_node, node),100,60, res, ret);
	if(res[1])
	{
    ret1 = 1;
    type = ret[2];
    for(i = 3; i <= dynlen(ret); i++)
    {
			  fwTree_getNodeDevice(ret[i], device, old_type, exInfo);
			  fwTree_setNodeDevice(ret[i], device, type, exInfo);
DebugTN("Changing Type of "+ ret[i]+" to "+ type);
    }
    done = 1;
/*
		ret1 = 1;
		if(ret[5] != "")
		{
			fwTree_getNodeDevice(node, device, type, exInfo);
			fwTree_setNodeDevice(node, device, ret[5], exInfo);
//DebugN("Setting Type", node, device, ret[5]);
			done = 1;
		}
		if(ret[6] != "")
		{
			fwFsmTree_cleanupNode(parent, ref_node);
			fwTree_setNodeCU(node, ret[6], exInfo);
//DebugN("Setting CU", node, ret[6]);
			done = 1;
			return ret1;
		}
		if(ret[7] != "")
		{
			fwFsm_setCUCtrlFlag(node, ret[7]);
//DebugN("Setting CU", node, ret[7]);
			return ret1;
		}
		if((ret[1] != "") || (ret[2] != "") || (ret[3] != "") || (ret[4] != ""))
		{
			flag1 = ret[3];
			flag2 = ret[4];
			if(parent == node)
			{
				if(parent_parent != "FSM")
				{
					fwFsm_setObjectLabelPanel(parent_parent, parent+"::"+ref_node, 
						ret[1], ret[2], flag1, -1);
				}
				fwFsm_setObjectLabelPanel(parent, ref_node, 
					ret[1], ret[2], flag1, -1);
				if(flag2 != -1)
				{
					fwUi_setDomainOperation(ref_node, flag2);
					fwFsmTree_recurseOperation(ref_node, flag2);
				}
			}
			else
			{
				fwFsm_setObjectLabelPanel(parent, ref_node, 
					ret[1], ret[2], flag1, flag2);
			}
		}
*/
	}
	return ret1;
}

fwFsmTree_confDBTreeNode(string node)
{

	ChildPanelOn("fwFSMConfDB/fwFSMConfDB.pnl","FSM Configuration DB",
		makeDynString(node), 100, 60);
}

fwFsmTree_accessTreeNode(string node)
{
string access;
dyn_string privileges;
dyn_float res;
dyn_string ret;

	ChildPanelOnReturn("fwFSM/ui/fwTreeNodeAccess.pnl","Access Control",
		makeDynString(node), 100, 60, res, ret);
	if(res[1])
	{
		privileges[1] = ret[1];
		fwFsmTree_accessTreeNodeRec(node, privileges[1], ret[2]);
	}
}

fwFsmTree_accessTreeNodeRec(string node, string priv, int rec)
{
dyn_string exInfo;
dyn_string nodes;
int i, cu;

	if(rec)
	{
		fwTree_getChildren(node, nodes, exInfo);
		for(i = 1; i <= dynlen(nodes); i++)
		{
			fwTree_getNodeCU(nodes[i], cu, exInfo);
			if((cu) && (!fwFsm_isObjectReference(nodes[i])))
			{
				fwFsmTree_accessTreeNodeRec(nodes[i], priv, rec);
			}
		}
	}
	fwFsmTree_setNodeAccessControl(node, priv);
}

		
//fwFsmTree_refreshTree: 
/**  Refresh the FSM tree in the Device Editor Navigator.
 	
Usage: JCOP framework internal, public

PVSS manager usage: VISION, CTRL

*/
fwFsmTree_refreshTree()
{
	fwTreeDisplay_refreshTree("FSM");
}

//fwFsmTree_startTree: 
/**  Restart the full FSM tree.
 	
Usage: JCOP framework internal, public

PVSS manager usage: VISION, CTRL

*/
fwFsmTree_startTree()
{

	fwUi_informUserProgress("Please wait...",100,60);
	fwFsm_restartAllDomains();
	fwUi_uninformUserProgress(1);
}

//fwFsmTree_stopTree: 
/**  Stop the full FSM tree.
 	
Usage: JCOP framework internal, public

PVSS manager usage: VISION, CTRL

*/
fwFsmTree_stopTree()
{

	fwUi_informUserProgress("Please wait...",100,60);
	fwFsm_stopAllDomains();
	fwUi_uninformUserProgress(1);
}

fwFsmTree_restartPVSS00smi()
{

	fwUi_informUserProgress("Please wait...",100,60);
	fwFsm_restartPVSS00smi();
	fwUi_uninformUserProgress(1);
}

fwFsmTree_restartPVSS00ctrl()
{

	fwUi_informUserProgress("Please wait...",100,60);
	fwFsm_restartPVSS00ctrl();
	fwUi_uninformUserProgress(1);
}

//fwFsmTree_startTreeNode: 
/**  Restart the FSM for a node or a Sub-tree.
 	
Usage: JCOP framework internal, public

PVSS manager usage: VISION, CTRL

      @param node: the name of the node (CU) to be restarted.
      @param recurse: 1 = restart also its children recursively (default).

*/
fwFsmTree_startTreeNode(string node, int recurse = 1)
{

	fwUi_informUserProgress("Please wait...",100,60);
	if(recurse)
		fwFsm_restartTreeDomains(node);
	else
		fwFsm_restartDomain(node);
	fwUi_uninformUserProgress(1);
}

//fwFsmTree_stopTreeNode: 
/**  Stop the FSM for a node or a Sub-tree.
 	
Usage: JCOP framework internal, public

PVSS manager usage: VISION, CTRL

      @param node: the name of the node (CU) to be stopped.
      @param recurse: 1 = stop also its children recursively (default).

*/
fwFsmTree_stopTreeNode(string node, int recurse = 1)
{
	fwUi_informUserProgress("Please wait...",100,60);
	if(recurse)
		fwFsm_stopTreeDomains(node);
	else
		fwFsm_stopDomain(node);
	fwUi_uninformUserProgress(1);

}


_fwTree_recurseDisplayObject(string sys, string domain, string obj, string &name)
{
string aux_domain, aux_obj;

	if(fwFsm_isAssociated(obj))
	{
		aux_domain = fwFsm_getAssociatedDomain(obj);
		aux_obj = fwFsm_getAssociatedObj(obj);
		if(domain != aux_domain)
			name += "::"+aux_domain;
		_fwTree_recurseDisplayObject(sys, aux_domain, aux_obj, name);
	}
	else
	{
		obj = fwFsm_getLogicalDeviceName(sys+":"+obj);
		if(domain != obj)
			name += "::"+obj;
	}
}

_fwTree_getDisplayObject(string sys, string domain, string obj, string &name)
{
string aux_domain, aux_obj;

	name = "";
	if(fwFsm_isAssociated(obj))
	{
		aux_domain = fwFsm_getAssociatedDomain(obj);
		if(aux_domain == domain)
		{
			return;
		}
		aux_obj = fwFsm_getAssociatedObj(obj);
		name = aux_domain;
		_fwTree_recurseDisplayObject(sys, aux_domain, aux_obj, name);
	}
	
}

int fwFsmTree_checkObjectsOfType(string type)
{
	dyn_string syss, objs;
	string domain, obj;
	int i;

	addGlobal("ObjectsOfTypeInUse",DYN_STRING_VAR);
	dynClear(ObjectsOfTypeInUse);
	fwFsm_getObjectsOfType(type, syss, objs);
	if(dynlen(objs))
	{
		for(i = 1; i <= dynlen(objs); i++)
		{
			if(fwFsm_isAssociated(objs[i]))
			{
				domain = fwFsm_getAssociatedDomain(objs[i]);
				obj = fwFsm_getAssociatedObj(objs[i]);
			}
			dynAppend(ObjectsOfTypeInUse,obj);
			dynAppend(ObjectsOfTypeInUse,domain);
			dynAppend(ObjectsOfTypeInUse,syss[i]);
		}
		fwUi_warnUserTypeInUse("",100,60);
		removeGlobal("ObjectsOfTypeInUse");
		return 1;
	}
	removeGlobal("ObjectsOfTypeInUse");
	return 0;
}

string fwFsmTree_createMajorityDp(string node, string type, string op, int threshold, 
	dyn_string states, int or_out_flag, int and_in_flag, int low_threshold = 1)
{
	int i, index, aux, reverse, maxDevs, or, and;
	string label;
	dyn_string all_states, children;
	string cu, maj_name, node_name;
	dyn_string exInfo;

	or = or_out_flag;
	and = and_in_flag;
	node_name = fwTree_getNodeDisplayName(node, exInfo);	
	if(!fwFsm_isDomain(node_name))
	{
		fwTree_getCUName(node, cu, exInfo);
		maj_name = cu+"/"+node_name+"/"+type+"_FWMAJ";
	}
	else
	{
		maj_name = node_name+"/"+type+"_FWMAJ";
	}
	children = fwFsm_getLogicalUnitChildrenOfType(cu, node_name, type);  
//	fwFsm_getDomainObjectsOfType(node, type, children);
//DebugN("children", children);  
	if(index = dynContains(children, node_name)) 
			dynRemove(children, index);
	maxDevs = dynlen(children);
	reverse = 0;
	if(op == "less")
	{
		threshold = maxDevs - threshold;
		fwFsm_getObjectStates(type, all_states);
		for(i = 1; i <= dynlen(states); i++)
		{
			if(index = dynContains(all_states, states[i]))
				dynRemove(all_states,index);	
		}
		states = all_states;
		aux = or;
		or = and;
		and = aux;
		reverse = maxDevs;
	}
//DebugN(maj_name, threshold, states);
	if(!dpExists(maj_name))
		dpCreate(maj_name,"FwDevMajority");
	dpSetWait(maj_name+".threshold",threshold,
		maj_name+".low_threshold",low_threshold,
		maj_name+".bad_states",states,
		maj_name+".disabled",or,
		maj_name+".enabled",and,
		maj_name+".reverse",reverse);
	return maj_name;
}

//fwFsmTree_importType: 
/**  Import an FSM Type from another system.
 	
Usage: JCOP framework internal, public

PVSS manager usage: VISION, CTRL

      @param type: the type to be imported.
      @param sys: the system name from where to import the type.
*/
fwFsmTree_importType(string type, string sys)
{
	string base_type;
	dyn_string states;

	fwFsm_initialize(0);
	if(fwFsm_isDeviceCompositType(type, sys))
	{
		base_type = fwFsm_getDeviceCompositBaseType(type, sys);
		fwFsm_setDeviceBaseType(base_type);
	}	
	fwFsm_copyDevObjType(sys,type);
	fwFsm_createLocalObject(type);
	fwFsm_getLocalStates(states);
	if(dynlen(states))
	{
		fwFsm_writeLocalObject(type, states);
	}
	fwFsm_deleteLocalObject();
}

//fwFsmTree_changeType: 
/**  Change the FSM Type of a tree node (CU or LU).
 	
Usage: JCOP framework internal, public

PVSS manager usage: VISION, CTRL

      @param node: the name of the node (CU, DU or local object) to change the type.
		   can be of the form <CU>::<obj>.
      @param type: the type to change to.
*/
/*
fwFsmTree_changeType(string node, string type)
{
  int ret, exists, i;
  dyn_string children, exInfo;
  string domain, obj, sys, dev, type;
  
  if(fwFsm_isAssociated(node))
  {
    domain = fwFsm_getAssociatedDomain(node);
    obj = fwFsm_getAssociatedObj(node);
    if((exists = fwFsmTree_isNode(domain)))
    {
      if(exists == 2)
      {
        if(strpos(domain,":") < 0)
        {
          sys = fwTree_getNodeSys(domain, exInfo);
          domain = sys+":"+domain;
        }
      }
      fwTree_getChildren(domain, children, exInfo);
      if(dynContains(children, obj))
        return exists;
      else
      {
        for(i = 1; i <= dynlen(children); i++)
        {
          if(fwTree_getNodeDisplayName(children[i], exInfo) == obj)
          {
            return exists;
          }
        }
      }
    }
    return 0;
  }
  else
  {
    return fwTree_isNode(node, exInfo);
  }
}

int get_CU()
{
	int cu;
	dyn_string exInfo;

	fwTree_getNodeCU($3, cu, exInfo);
	return cu;
}

int get_CU_enabled(int &enabled)
{
	int cu, pcu, ccu;
	dyn_string exInfo, children;
        string parent;
	int i, can_change = 1;

	cu = get_CU();
	fwTree_getParent($3, parent, exInfo);
	fwTree_getNodeCU(parent, pcu, exInfo);
	if(cu)
	{
//		fwTree_getNodeCU($1, pcu, exInfo);
		if(!pcu)
		{
			can_change = -1;
//DebugN("Can't change, Parent is not CU");
		}
		fwTree_getChildren($3,children, exInfo);
		for(i = 1; i <= dynlen(children); i++)
		{
			fwTree_getNodeCU(children[i], ccu, exInfo);
			if(ccu)
			{
				can_change = -2;
//DebugN("Can't change, Some children are CUs");
				break;
			}
		}
	}
	else
	{
//		fwTree_getNodeCU($1, pcu, exInfo);
		if(strpos($3,"&") == 0)
		{
			can_change = -3;
//DebugN("Can't change, CU name already exists");
		}
		if(!pcu)
		{
			can_change = -4;
//DebugN("Can't change, Parent not CU");
		}
	}
//	enabled = 1;
//	if(cant_change)
	enabled = can_change;
	return cu;
}
*/
