dyn_string fwTreeDisplay_getTrees()
{
dyn_string trees;
int pos, i;

	trees = fwFsm_getDps("*","_FwTreeType");
	for(i = 1; i <= dynlen(trees); i++)
	{
		if((pos = strpos(trees[i],"fwTT_")) >= 0)
		{
			trees[i] = substr(trees[i],pos+5);
		}
	}
	return trees;
}

fwTreeDisplay_createTree(string name, int mode, string root, dyn_string types, dyn_string names)
{
	string dp;
	dyn_string modes, exInfo;
	string type_list, name_list;
	
	dp = "fwTT_"+name;
	dpCreate(dp,"_FwTreeType");
	dpSet(dp+".name",name);
	dynAppend(modes,"editor");
	if(mode > 1)
		dynAppend(modes,"navigator");
	dpSet(dp+".modes",modes);
	dpSet(dp+".root",root);
	type_list = types;
	strreplace(type_list," | ",",");
	dpSet(dp+".nodeTypes",type_list);
	fwTree_create(name, exInfo);
	name_list = names;
	strreplace(name_list," | ",",");
	dpSet(dp+".nodeNames",name_list);
	fwTree_create(name, exInfo);
}

string fwTreeDisplay_getNodeTypes(string tree)
{
	string types;
	
	string dp = "fwTT_"+tree;
	dpGet(dp+".nodeTypes",types);
	return types;
}

string fwTreeDisplay_getNodeNames(string tree)
{
	string names;
	
	string dp = "fwTT_"+tree;
	dpGet(dp+".nodeNames",names);
	return names;
}

string fwTreeDisplay_getRoot(string tree)
{
	string root, name, sys;
	
	string dp = "fwTT_"+tree;
	dpGet(dp+".root",root);
	dpGet(dp+".name",name);
	if((root != name) && (root != ""))
	{
		sys = fwFsm_getSystemName()+":";
		if(root != sys)
		{
			fwTreeDisplay_changeSystemName(name, root, sys);
			root = sys;
			dpSet(dp+".root",root);
		}
	}
	dpConnect("fwTreeDisplay_refreshCB",dp+".refresh");
	return root;
}

fwTreeDisplay_changeSystemName(string tree, string oldsys, string newsys)
{
	dyn_string nodes, exInfo;
	string dev, type;
	int i;

	fwTree_getAllTreeNodesWithClipboard(tree, nodes, exInfo);
	for(i = 1; i <= dynlen(nodes); i++)
	{
		fwTree_getNodeDevice(nodes[i], dev, type, exInfo);
		if(strpos(dev,oldsys) == 0)
		{
			strreplace(dev, oldsys, newsys);
			fwTree_setNodeDevice(nodes[i], dev, type, exInfo);
		}
	}
}

int fwTreeDisplay_getTreeIndex()
{
  int treeIndex;
  string num; 

  num = TreeArrayIndex.text;
  treeIndex = num;
  return treeIndex;
}

fwTreeDisplay_getTree(int treeIndex)
{
int i;
dyn_string exInfo;
string root, types, names;
string treeIndexStr;

	while(!globalExists("FwTreeInit"))
		delay(0,100);
	while(!FwTreeInit)
		delay(0,100);
        
	if(!globalExists("CurrTreeIndex"))
	{
		addGlobal("FwTreeTops",DYN_STRING_VAR);
		addGlobal("FwTreeTypes",DYN_STRING_VAR);
		addGlobal("FwTreeNames",DYN_STRING_VAR);
		addGlobal("CurrTreeIndex",INT_VAR);
		addGlobal("PasteNode",STRING_VAR);
//		addGlobal("FwTreeDisplay_openItems",DYN_STRING_VAR);
	}
        if(!globalExists("FwFSMHierarchy"))
	  addGlobal("FwFSMHierarchy",INT_VAR);
        if(FwActiveTrees[treeIndex] == "FSM")
        {
	  FwFSMHierarchy = 1;
	  fwFsm_initialize();
        }
        else
          FwFSMHierarchy = 0;
	root = fwTreeDisplay_getRoot(FwActiveTrees[treeIndex]);
	types = fwTreeDisplay_getNodeTypes(FwActiveTrees[treeIndex]);
	names = fwTreeDisplay_getNodeNames(FwActiveTrees[treeIndex]);
	FwTreeTops[treeIndex] = root;
	FwTreeTypes[treeIndex] = types;
	FwTreeNames[treeIndex] = names;
	PasteNode = "";
	CurrTreeIndex = treeIndex;
	if(!dynContains(FwTreeRedos[treeIndex], FwActiveTrees[treeIndex]))	
		dynAppend(FwTreeRedos[treeIndex], FwActiveTrees[treeIndex]);
//	fwTreeDisplay_redoTree(CurrTree);
}

fwTreeDisplay_refreshCB(string dp, int value)
{
	dyn_string items;
	string tree;

	items = strsplit(dp,":.");
	tree = items[2];
	items = strsplit(tree,"_");
	tree = items[2];
	fwTreeDisplay_setRedoTree(tree);
}

fwTreeDisplay_refreshTree(string tree)
{
	string dp = "fwTT_"+tree;
	dpSetWait(dp+".refresh",1);
}

fwTreeDisplay_setRedoTree(string tree)
{
	int i;

	for(i = 1; i <= dynlen(FwActiveTrees); i++)
	{
		if(FwActiveTrees[i] == tree)
		{
			if(!dynContains(FwTreeRedos[i], tree))
				dynAppend(FwTreeRedos[i], tree);
		}
	}
}

fwTreeDisplay_setRedoTreeNode(string tree, string node)
{
	int i;

	for(i = 1; i <= dynlen(FwActiveTrees); i++)
	{
		if(FwActiveTrees[i] == tree)
		{
			if(!dynContains(FwTreeRedos[i], node))
				dynAppend(FwTreeRedos[i], node);
		}
	}
}

fwTreeDisplay_setExpandTreeNode(int treeIndex, string tree, string node)
{
	int i, n;

//DebugN("SET expand", treeIndex, tree, node);
  
  dynAppend(FwTreeExpands[treeIndex], node);
  
  if((FwTreeModes[treeIndex] == "editor") || (FwTreeModes[treeIndex] == "navigator"))
  {
    n = dynlen(FwActiveTrees);
    for(i = 1; i <= n; i++)
    {
      if( (i != treeIndex) /*|| (n == 1)*/)
      {
        if((FwTreeModes[i] == "editor") || (FwTreeModes[i] == "navigator"))
        {
          if(FwActiveTrees[i] == tree)
          {
//          FwTreeExpands[i] = node;
            dynAppend(FwTreeExpands[i], node);
          }
        }
      }
    }
	}
}

fwTreeDisplay_setCollapseTreeNode(int treeIndex, string tree, string node)
{
	int i, n;

	n = dynlen(FwActiveTrees);
	for(i = 1; i <= n; i++)
	{
		if( (i != treeIndex) || (n == 1))
		{
			if(FwActiveTrees[i] == tree)
				FwTreeCollapses[i] = node;
		}
	}
}

fwTreeDisplay_setSelectTreeNode(int treeIndex, string tree, string node)
{
	int i, n;

	n = dynlen(FwActiveTrees);
	for(i = 1; i <= n; i++)
	{
		if( (i != treeIndex) || (n == 1))
		{
			if(FwActiveTrees[i] == tree)
				FwTreeSelects[i] = node;
		}
	}
}
fwTreeDisplay_configNode(string id)
{
int treeIndex;
string currTree, currTreeMode, currTreeParent, currTreeNode;

        treeIndex = fwTreeDisplay_getTreeIndex();
	CurrTreeIndex = treeIndex;
	currTree = FwActiveTrees[treeIndex];
	currTreeMode = FwTreeModes[treeIndex];
	currTreeParent = this.parent(id);
	currTreeNode = id;
        if(currTreeParent == "")
          currTreeParent = currTree;
//DebugN(CurrTreeIndex, currTree+"_"+currTreeMode+"_entered", currTreeNode, currTreeParent);
	fwTreeDisplay_callUser2(currTree+"_"+currTreeMode+"_entered",
			currTreeNode, currTreeParent);
}

fwTreeDisplay_collapse(string id)
{
int treeIndex;
string currTree, currTreeMode, currTreeParent, currTreeNode;
int index;

//DebugN("Collapse clicked", id);
        treeIndex = fwTreeDisplay_getTreeIndex();
	CurrTreeIndex = treeIndex;
	currTree = FwActiveTrees[treeIndex];

//  	if((index = dynContains(FwTreeDisplay_openItems, id+"_"+treeIndex)))
//		dynRemove(FwTreeDisplay_openItems, index);
//	else
//		return;

	currTreeMode = FwTreeModes[treeIndex];
	currTreeParent = this.parent(id);
	currTreeNode = id;
        if(currTreeParent == "")
          currTreeParent = currTree;
//	fwTreeDisplay_collapseTreeNode(treeIndex, currTreeNode, 1);
	fwTreeDisplay_callUser2(currTree+"_"+currTreeMode+"_collapsed",
			currTreeNode, currTreeParent);
	fwTreeDisplay_setCollapseTreeNode(treeIndex, currTree, currTreeNode);
}

fwTreeDisplay_expand(string id)
{
int treeIndex, initialPos;
string currTree, currTreeMode, currTreeParent, currTreeNode;

//DebugN("Expand clicked", id);

	treeIndex = fwTreeDisplay_getTreeIndex();
	CurrTreeIndex = treeIndex;
	currTree = FwActiveTrees[treeIndex];

//DebugN(currTree, id+"_"+treeIndex, FwTreeDisplay_openItems);
//	if(!dynContains(FwTreeDisplay_openItems, id+"_"+treeIndex))
//		dynAppend(FwTreeDisplay_openItems, id+"_"+treeIndex);
//	else
//		return;
 
	currTreeMode = FwTreeModes[treeIndex];
	currTreeParent = this.parent(id);
	currTreeNode = id;
        if(currTreeParent == "")
          currTreeParent = currTree;
//DebugTN(id, treeIndex, currTree, currTreeParent, currTreeMode);
//	fwTreeDisplay_expandTreeNode(treeIndex, currTreeNode, 1);
	fwTreeDisplay_callUser2(currTree+"_"+currTreeMode+"_expanded",
			currTreeNode, currTreeParent);
//DebugN("set Expanded", treeIndex, currTree, currTreeNode);
	fwTreeDisplay_setExpandTreeNode(treeIndex, currTree, currTreeNode);
}

fwTreeDisplay_selectNode(string id)
{
int treeIndex;
string currTree, currTreeMode, currTreeParent, currTreeNode;

        treeIndex = fwTreeDisplay_getTreeIndex();
	CurrTreeIndex = treeIndex;
	currTree = FwActiveTrees[treeIndex];
	currTreeMode = FwTreeModes[treeIndex];
	currTreeParent = this.parent(id);
	currTreeNode = id;
        if(currTreeParent == "")
          currTreeParent = currTree;
	fwTreeDisplay_callUser2(currTree+"_"+currTreeMode+"_selected",
			currTreeNode, currTreeParent);
	fwTreeDisplay_setSelectTreeNode(treeIndex, currTree, currTreeNode);
}

fwTreeDisplay_expandTreeNode(int treeIndex, string node, int done = 0)
{
dyn_string children, exInfo;
int i;
string sys, node_name;

//DebugTN("********* expand", treeIndex, node);
//DebugN(node+"_"+treeIndex, FwTreeDisplay_openItems);
//	if(!dynContains(FwTreeDisplay_openItems, node+"_"+treeIndex))
//		dynAppend(FwTreeDisplay_openItems, node+"_"+treeIndex);
//	else
//		return;
	if(this.itemExists(node))
	{
		if(FwTreeModes[treeIndex] == "operator")
		{
			if(fwFsm_isObjectReference(node))
			{
				string aux;
				aux = fwTree_getNodeDisplayName(node, exInfo);
				fwUi_getDomainSys(aux, sys);
				sys = strrtrim(sys,":");
				if(sys == "")
					fwFsm_getObjectReferenceSystem(node, sys);
//DebugN("getSys", node, sys);
			}
			else
			{
				sys = _fwTree_getNodeSys(node);
				if(sys != "")
					node = sys+":"+node;
			}
			if(sys != "")
			{
				node_name = sys+":";
			}
			node_name += fwTree_getNodeDisplayName(node, exInfo);
			fwTree_getChildrenWithClipboard(node_name, children, exInfo);
		}
		else
			fwTree_getChildrenWithClipboard(node, children, exInfo);
//DebugN("********* expand", node, node_name, children);
		for(i = 1; i <= dynlen(children); i++)
		{
			if(children[i] != node)
			{
//DebugN("Expanding", node, children[i]);
				fwTreeDisplay_appendTreeNodes(treeIndex, node, children[i], 1, sys, 1);
//DebugN("Done Expanding", node, children[i]);
			}
		}

	  	if(!done)
		    this.setOpen(node, TRUE);
	}
//DebugTN("********* expand done", treeIndex, node);
}

fwTreeDisplay_collapseTreeNode(int treeIndex, string node, int done = 0)
{
  int index;

//  if((index = dynContains(FwTreeDisplay_openItems, node+"_"+treeIndex)))
//	dynRemove(FwTreeDisplay_openItems, index);
//  else
//	return;
  if(!done)
  {
  	if(this.itemExists(node))
    		this.setOpen(node, FALSE);
  }
}

fwTreeDisplay_selectTreeNode(int treeIndex, string node)
{
  if(this.itemExists(node))
	this.setSelectedItem(node, TRUE);
}


fwTreeDisplay_callUser2(string function, string node, string parent)
{
	if(isFunctionDefined(function))
	{

		execScript("main(string node, string parent) { "+
			function+"(node, parent);/* delay(20);*/}",
			makeDynString(), node, parent);

//		startThread(function, node, parent);
	}
}

fwTreeDisplay_callUser1(string function, string node)
{
	if(isFunctionDefined(function))
	{

		execScript("main(string node) { "+
			function+"(node);/* delay(20);*/}",
			makeDynString(), node);

//		startThread(function, node);
	}
}


fwTreeDisplay_deleteNodes(int treeIndex, string currNode, int first = 1)
{
  dyn_string children;
  int i, index;
  
  
//DebugTN("Delete", currNode);
//  this.setOpen(currNode, FALSE);
//  fwTreeDisplay_collapseTreeNode(treeIndex, currNode, 0);
////  this.removeItems(makeDynString(currNode));
//  if((index = dynContains(FwTreeDisplay_openItems, currNode+"_"+treeIndex)))
//	dynRemove(FwTreeDisplay_openItems, index);

  children = this.children(currNode);
//DebugN(children);
  for(i = 1; i <= dynlen(children); i++)
  {
    fwTreeDisplay_deleteNodes(treeIndex, children[i], 0);
  }

  if(FwTreeModes[treeIndex] == "operator")
	  fwFsmTree_disconnectNodeState(currNode, this.parent(currNode));
  if(first)
  	this.removeItems(makeDynString(currNode));
//DebugN("Removing", currNode);
//  this.removeItems(children);
}

fwTreeDisplay_redoTree(int treeIndex, string currNode)
{

	int i, n, pos = 1, level = 0, initialPos;
	dyn_string children, exInfo;
	dyn_anytype treeNode;
	string currParent;

//DebugTN("*********** redoTree", treeIndex, currNode);
        if(this.itemExists(currNode))
        {
        
          currParent = this.parent(currNode);
          fwTreeDisplay_deleteNodes(treeIndex, currNode);
        }
	else
	{
		if((FwTreeModes[treeIndex] == "operator") && (currNode == "FSM"))
		{
			if(!globalExists("FwFsmOperatorTree_viewAll"))
				addGlobal("FwFsmOperatorTree_viewAll", INT_VAR);
			fwTree_getChildrenWithClipboard(currNode, children, exInfo);
//DebugN(children);
			for(i = 1; i <= dynlen(children); i++)
			{
        			if(this.itemExists(children[i]))
        			{
//          				currParent = this.parent(children[i]);
          				fwTreeDisplay_deleteNodes(treeIndex, children[i]);
				}
			}
		}
	}
//        else
//        {
	  if(currNode == FwActiveTrees[treeIndex])
	  	currParent = currNode;
//        }
        fwTreeDisplay_appendTreeNodes(treeIndex, currParent, currNode);
/*
	if(currNode == FwActiveTrees[treeIndex])
	{
                currParent = "";
		if(FwTreeTops[treeIndex] != "")
		{
			fwTreeDisplay_insertNode(FwTreeTops[treeIndex], currParent, 
				FwActiveTrees[treeIndex]);
		}
	}
        if(this.itemExists(currNode))
	{
	        fwTreeDisplay_expandTreeNode(treeIndex, currNode, 0);
//		this.setOpen(currNode, TRUE);
	}
//	fwTreeDisplay_expandTreeNode(treeIndex, currNode, 1);
*/
//DebugTN("*********** redoTree done", currNode);
}

int fwTreeDisplay_appendTreeNodes(int treeIndex, string parent, string node, int levels = 2, string sys = "", int exp = 0)
{
dyn_string children, exInfo;
string node_name, child_node_name;
int i, ref, pos, n, dont, ret = 0, cu;
dyn_string udata;


//if(strpos(node,"IT_DAQ") >= 0)
//DebugTN("appendTreeNodes", treeIndex, levels, parent, node, sys, FwTreeModes[treeIndex], FwTreeDontShowInvisible[treeIndex], FwTreeTopNodes[treeIndex] );
    
	  if(sys != "")
		  node = sys+":"+node;
   if((FwTreeModes[treeIndex] == "operator") && (FwTreeDontShowInvisible[treeIndex]))
   {
     fwTree_getNodeUserData(node, udata, exInfo);
//DebugTN("Don't show Invisible", parent, node, udata, exInfo);
     if(dynlen(udata))
     {
       if(udata[1] == "0")
         return 0;
     }
   }

       
//DebugTN("manip", node, sys);
//	if(sys != "")
//		node = sys+":"+node;
	if(fwFsm_isObjectReferenceCU(node, cu))
	{
//DebugTN("getNodeCU");
//		fwTree_getNodeCU(node, cu, exInfo);
		if((FwTreeModes[treeIndex] != "operator") || (!cu))
		{
			node_name = "&";
			node_name += fwTree_getNodeDisplayName(node, exInfo);
////			fwFsm_getObjectReferenceSystem(node, sys);
		}
		else
		{
//			string aux, sys1;
//DebugTN("getObjRef");
//			if(sys!= "")
//				node = sys+":"+node;
			node_name += fwTree_getNodeDisplayName(node, exInfo);
			fwUi_getDomainSys(node_name, sys);
			sys = strrtrim(sys,":");
			if(sys == "")
				fwFsm_getObjectReferenceSystem(node, sys);
//DebugN("getSys", node, sys, aux, sys1);
//if(sys != sys1)
//DebugN("**************************** different", node, sys, aux, sys1);
//			node_name += fwTree_getNodeDisplayName(node, exInfo);
//			node = node_name;
		}
	}
	else
		node_name += fwTree_getNodeDisplayName(node, exInfo);
//DebugN(node, cu, node_name);
	if(parent == "")
		parent = "FSM";
//DebugTN("InsertNode", node, node_name, parent);
	if( (parent == _fwTree_makeClipboard(FwActiveTrees[treeIndex])) &&
	    ((FwTreeModes[treeIndex] == "navigator")||(FwTreeModes[treeIndex] == "operator")) )
			return 0;
	if(node_name == FwActiveTrees[treeIndex])
	{
                parent = "";
//DebugTN("InsertNode top?", node_name, FwTreeTops[treeIndex], parent,FwActiveTrees[treeIndex]);
		if(FwTreeTops[treeIndex] != "")
		{
			ret = fwTreeDisplay_insertNode(FwTreeTops[treeIndex], parent, 
				FwActiveTrees[treeIndex]);
		}
	}
	else if(node_name == _fwTree_makeClipboard(FwActiveTrees[treeIndex]))
	{
//DebugN("Clip", node_name, FwTreeModes[treeIndex]);
		if((FwTreeModes[treeIndex] != "navigator") && (FwTreeModes[treeIndex] != "operator"))
		{
			ret = fwTreeDisplay_insertNode("---Clipboard---", parent, 
				node);
		}
		else
		{
			return 0;
		}
	}
	else
	{
		ret = fwTreeDisplay_insertNode(node_name, parent, 
			node);
	}

//DebugTN("inserted", node);
//DebugN("node", node, node_name, parent, levels);
	if(ret == -1)
		return 0;
	if(!levels)
		return ret;
	levels--;
	if((FwTreeModes[treeIndex] == "operator") && (sys != ""))
	{
		if(node_name[0] == "&")
			node_name = substr(node_name,1);
//DebugTN("getChildren",sys+":"+node_name);
		fwTree_getChildrenWithClipboard(sys+":"+node_name, children, exInfo);		
//DebugTN("Got Children");
//DebugN("getChildren", sys+":"+node_name, node, children, exInfo);
//		node = node_name;
	}
	else
	{
		fwTree_getChildrenWithClipboard(node, children, exInfo);
	}
//DebugN("*******", node, children, levels);
  if(FwTreeModes[treeIndex] == "operator")
  {
    if(dynlen(FwTreeTopNodes[treeIndex]) && (node == "FSM"))
    {
      children = FwTreeTopNodes[treeIndex];
    }
  }
	for(i = 1; i <= dynlen(children); i++)
	{
   if(FwTreeModes[treeIndex] == "operator")
   {
/*
     if(dynlen(FwTreeTopNodes[treeIndex]))
     {
       if((node == "FSM") && (!dynContains(FwTreeTopNodes[treeIndex], children[i])))
         continue;
     }
*/
     if(FwTreeDontShowInvisible[treeIndex])
     {
       fwTree_getNodeUserData(children[i], udata, exInfo);
//DebugTN("Don't show Invisible", node, children[i], udata, exInfo);
       if(dynlen(udata))
       {
         if(udata[1] == "0")
           continue;
       }
     }
   }
		if(children[i] != node)
		{
			ret = fwTreeDisplay_appendTreeNodes(treeIndex, node, children[i], levels, sys, exp);
			if((ret) && (!levels) && (exp))
				break;
//			if((ret) && (!first))
//				break;
		}
	}
	return ret;

}

int fwTreeDisplay_insertNode(string node_name, string parent, string node)
{
  int treeIndex, cu, visi;
  string dev, type, label;
  dyn_string children, exInfo;

  treeIndex = fwTreeDisplay_getTreeIndex();
//if(strpos(node,"IT_DAQ") >= 0)
//DebugTN("************** TREE Appending Item", parent, node, node_name);
  if(!this.itemExists(node))
  {
//DebugN("************** New node - TREE Appending Item", parent, node, node_name);
    if((FwTreeModes[treeIndex] == "operator") && (FwActiveTrees[treeIndex] == "FSM"))
    {
        if(node_name == getSystemName())
	{
		return 0;
	}
	else
	{
		if(parent == "FSM")
			parent = "";
	}
	if(strpos(node_name,"&")== 0)
		node_name = "&";
	else
		node_name = "";
	node_name += fwFsmTree_getNodeLabel(node);
//	visi = fwFsmTree_getNodeVisibility(node);
//	if(visi != 1)
//		return -1;
//if(strpos(node,"IT_DAQ") >= 0)
//DebugN("************** TREE Appending&Connecting Item", parent, node, node_name);
//	fwFsmTree_connectNodeState(node, parent);
    }
    if(node_name == "---Clipboard---")
    	this.appendItem(parent, node, node_name, parent);
    else
    	this.appendItem(parent, node, node_name);

    if((FwTreeModes[treeIndex] == "operator") && (FwActiveTrees[treeIndex] == "FSM"))
    {
//if(strpos(node,"IT_DAQ") >= 0)
//DebugN("************** TREE Appending&Connecting Item", parent, node, node_name);
	fwFsmTree_connectNodeState(node, parent);
//DebugTN("connected", node);
    }
    if((FwTreeModes[treeIndex] != "operator") && (FwActiveTrees[treeIndex] == "FSM"))
    {
      if(node_name == getSystemName())
        this.setIcon(node, 0, "dptree/system.png");
      else
      {	
        fwTree_getNodeCU(node, cu, exInfo);
        if(cu)
          this.setIcon(node, 0, "cu_icon.gif");
        else
        {
          fwTree_getNodeDevice(node, dev, type, exInfo);
	  dev = fwFsm_getPhysicalDeviceName(dev);
          if(dpExists(dev))
            this.setIcon(node, 0, "du_icon.gif");
          else
            this.setIcon(node, 0, "lu_icon.gif");
        }
      }
    }
  }
  if(node == _fwTree_makeClipboard(FwActiveTrees[treeIndex]))
  {
	fwTree_getChildrenWithClipboard(node, children, exInfo);
	if(dynlen(children))
          this.setIcon(node, 0, "clipboard.gif");
        else
          this.setIcon(node, 0, "clipboard_empty.gif");
  }
  if(FwActiveTrees[treeIndex] == "TrendTree")
  {
    fwTree_getNodeDevice(node, dev, type, exInfo);
    if(type == fwTrending_PAGE)
    {
        this.setIcon(node, 0, "SysMgm/16x16/VariableTrend.png");      
    }
  }
//DebugTN("done", node);
  return 1;
}

fwTreeDisplay_setIcon(string node, string color)
{
  string fileName;
  string testName;
  
  testName = "state_icon_"+color+".gif";
  if (isfile(getPath(PIXMAPS_REL_PATH,testName))==true)
  {
    fileName = testName;
  }
  else
  {
    testName = "state_icon_"+color+".bmp";
    if (isfile(getPath(PIXMAPS_REL_PATH,testName))==true)
    {
      fileName = testName;
    }
    else
    {
      fileName = "";
    }
  }
  
  this.setIcon(node, 0, fileName);
//	this.setIcon(node, 0, "state_icon_"+color+".gif");
}

fwTreeDisplay_editorStd(string node, string parent)
{
dyn_string txt, exInfo;
int answer, paste_flag, redo, wait = 0;
string tree;

	redo = 0;
	if(PasteNode == "")
		paste_flag = 0;
	else
		paste_flag = 1;
	if( !fwTree_isClipboard(node, exInfo))
		dynAppend(txt,"PUSH_BUTTON, Add..., 1, 1");
	dynAppend(txt,"PUSH_BUTTON, Remove..., 2, 1");
	dynAppend(txt,"SEPARATOR");
	if((!fwTree_isRoot(node, exInfo)) && (!fwTree_isClipboard(node, exInfo)))
		dynAppend(txt,"PUSH_BUTTON, Cut, 3, 1");
	dynAppend(txt,"PUSH_BUTTON, Paste, 4, "+paste_flag);
	dynAppend(txt,"SEPARATOR");
	if((!fwTree_isRoot(node, exInfo)) && (!fwTree_isClipboard(node, exInfo)))
		dynAppend(txt,"PUSH_BUTTON, Rename, 5, 1");
	dynAppend(txt,"PUSH_BUTTON, Reorder, 6, 1");
	if((!fwTree_isRoot(node, exInfo)) && (!fwTree_isClipboard(node, exInfo)))
	{
		dynAppend(txt,"SEPARATOR");
		dynAppend(txt,"PUSH_BUTTON, Settings, 7, 1");
	}
	popupMenu(txt,answer);
	if(answer == 1)
	{
		fwTreeDisplay_askAddNodeStd(node, redo);
	}
	else if(answer == 2)
	{
		fwTreeDisplay_askRemoveNodeStd(parent, node, redo);
	}
	else if(answer == 3)
	{
		fwUi_informUserProgress("Please wait - Cutting Nodes ...", 100,60);
		PasteNode = node;
		fwTree_cutNode(parent, PasteNode, exInfo);
		fwTreeDisplay_callUser2(
			FwActiveTrees[CurrTreeIndex]+"_nodeCut",
			PasteNode, parent);
		redo = 1;
	}
	else if(answer == 4)
	{
		fwUi_informUserProgress("Please wait - Pasting Nodes ...", 100,60);
		fwTree_pasteNode(node, PasteNode, exInfo);
		fwTreeDisplay_callUser2(
			FwActiveTrees[CurrTreeIndex]+"_nodePasted",
			PasteNode, node);
		PasteNode = "";
		redo = 1;
	}
	else if(answer == 5)
	{
		fwTreeDisplay_askRenameNodeStd(node, 1, redo);
	}
	if(answer == 6)
	{
		fwTreeDisplay_askReorderNodeStd(node, redo);
	}
	if(answer == 7)
	{
		fwTreeDisplay_callUser2(
			FwActiveTrees[CurrTreeIndex]+"_nodeSettings",
			node, parent);
	}
	if(redo)
	{
		fwTreeDisplay_setRedoTree(FwActiveTrees[CurrTreeIndex]);
//DebugN("do setRedoTree",FwActiveTrees[CurrTreeIndex], parent, node);
	}	
	fwTree_getTreeName(parent, tree, exInfo);
	if(tree == "FSM")
		wait = 1;
	fwUi_uninformUserProgress(wait);
}

fwTreeDisplay_navigatorStd(string node, string parent)
{
dyn_string txt, exInfo;
int answer;

	if(!fwTree_isRoot(node, exInfo))
	{
		dynAppend(txt,"PUSH_BUTTON, View, 1, 1");
		popupMenu(txt,answer);
	}
	if(answer == 1)
	{
		fwTreeDisplay_callUser2(
			FwActiveTrees[CurrTreeIndex]+"_nodeView",
			node, parent);
	}
}

fwTreeDisplay_askAddNodeStd(string parent, int &done)
{
	dyn_string ret, exInfo;
	dyn_float res;
	string type, node, label, sys, msg, ref_parent;
	int i, cu, isnode, ref;

	done = 0;
/*
	ref_parent = parent;
	ref = fwFsm_isObjectReference(parent);
	if(ref)
	{
		ref_parent = fwFsm_getReferencedObject(parent);
		if(ref == 1)
			ref_parent = "&"+ref_parent;
	}
*/
	if(fwFsm_isObjectReference(parent))
		ref_parent = "&";
	ref_parent += fwTree_getNodeDisplayName(parent, exInfo);

	ChildPanelOnReturn("fwTreeDisplay/fwTreeAddNodeStd.pnl","Add Node",
		makeDynString(parent, ref_parent, 
		FwTreeTypes[CurrTreeIndex], FwTreeNames[CurrTreeIndex]),
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
				node = ret[i];
				label = ret[i+1];
/*
				isnode = fwTree_isNode(label, exInfo);
				if(isnode)
				{
					fwFsm_makeObjectReference(label, label);
//					fwUi_warnUser("Node "+label+" already exists, Not created", 
//					100,60);
//					done = 0;
//					return;
				}
				fwTree_addNode(parent, label, exInfo);
*/
				label = fwTree_createNode(parent, label, exInfo);
				if(node != "")
				{
					sys = fwFsm_getSystem(node);
					if(sys == "")
					{
						sys = fwFsm_getSystemName();
						node = sys+":"+node;
					}
				}
				fwTree_setNodeDevice(label, node, type, exInfo);
				fwTree_setNodeCU(label, cu, exInfo);
				fwTreeDisplay_callUser2(
					FwActiveTrees[CurrTreeIndex]+"_nodeAdded",
					label, parent);
			}
	}
}

fwTreeDisplay_removeNode(string parent, string node)
{
int i, cu;
dyn_string children, exInfo;

	fwTreeDisplay_callUser2(
		FwActiveTrees[CurrTreeIndex]+"_nodeRemoved",
		node, parent);
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

fwTreeDisplay_removeSubTree(string parent, string node)
{
dyn_string children, exInfo;
int i;

	fwTree_getChildren(node, children, exInfo);
	for(i = 1; i <= dynlen(children); i++)
	{
		fwTreeDisplay_removeSubTree(node, children[i]);
	}
	fwTreeDisplay_removeNode(parent, node);
}

string fwTreeDisplay_askRemoveNodeStd(string parent, string node, int &done)
{
	dyn_string ret, exInfo;
	dyn_float res;
	string msg, ref_node, ret_parent;
	int i, tree_flag, ref;

	done = 0;
/*
	ref_node = node;
	ref = fwFsm_isObjectReference(node);
	if(ref)
	{
		ref_node = fwFsm_getReferencedObject(node);
		if(ref == 1)
			ref_node = "&"+ref_node;
	}
*/
	if(fwFsm_isObjectReference(node))
		ref_node = "&";
	ref_node += fwTree_getNodeDisplayName(node, exInfo);

	ChildPanelOnReturn("fwTreeDisplay/fwTreeRemoveNodeStd.pnl","Remove Node",
		makeDynString(node, ref_node),
		100,60, res, ret);
	if(res[1])
	{
		msg = "Please Wait - Removing Nodes ...";
		fwUi_informUserProgress(msg, 100,60);
		done = 1;
		tree_flag = ret[1];
		ret_parent = parent;
		if(tree_flag == 0)
		{
			fwTreeDisplay_removeNode(parent, node);
		}
		else if(tree_flag == 1)			
		{
			fwTreeDisplay_removeSubTree(parent,node);
		}
		else
		{
			ret_parent = node;
			for(i = 2; i <= dynlen(ret); i++)
			{
				fwTreeDisplay_removeSubTree(node, ret[i]);
			}
		}
	}
	return ret_parent;
}

string fwTreeDisplay_askRenameNodeStd(string node, int allow_duplicate, int &done)
{
	dyn_string ret, exInfo;
	dyn_float res;
	int ref;
	string ref_node, new_node;

	new_node = "";
/*
	ref_node = node;
	ref = fwFsm_isObjectReference(node);
	if(ref)
	{
		ref_node = fwFsm_getReferencedObject(node);
		if(ref == 1)
			ref_node = "&"+ref_node;
	}
*/
	if(fwFsm_isObjectReference(node))
		ref_node = "&";
	ref_node += fwTree_getNodeDisplayName(node, exInfo);

	ChildPanelOnReturn("fwTreeDisplay/fwTreeRenameNodeStd.pnl","Rename Node",
		makeDynString(ref_node),
		100,60, res, ret);
	if(res[1])
	{
		new_node = ret[1];
		if(fwTree_isNode(new_node, exInfo))
		{
/*
			if(allow_duplicate)
			{
//				fwFsm_makeObjectReference(new_node, new_node);
				new_node = fwTree_makeNode(new_node, exInfo);
			}
			else
			{
				fwUi_warnUser("This node already exists",100,60);
					return "";
			}
*/
			if(!allow_duplicate)
			{
				fwUi_warnUser("This node already exists",100,60);
					return "";
			}
		}
		done = 1;
		new_node = fwTree_renameNode(node, new_node, exInfo);
		if(!globalExists("LastRenamedNode"))
			addGlobal("LastRenamedNode",STRING_VAR);
		LastRenamedNode = new_node;
		fwTreeDisplay_callUser2(
			FwActiveTrees[CurrTreeIndex]+"_nodeRenamed",
			node, new_node);
	}
	return new_node;
}

fwTreeDisplay_askReorderNodeStd(string node, int &done)
{
	dyn_string ret, exInfo, children;
	dyn_float res;

	done = 0;
	fwTree_getChildren(node, children, exInfo);
	ChildPanelOnReturn("fwTreeDisplay/fwTreeReorderNodeStd.pnl","Re-order Children",
		makeDynString(node),
		100,60, res, ret);
	if(res[1])
	{
		if(children != ret)
		{
			done = 1;
			fwTree_reorderChildren(node, ret, exInfo);
			fwTreeDisplay_callUser1(
				FwActiveTrees[CurrTreeIndex]+"_nodeReordered",
				node);
		}

	}
}
