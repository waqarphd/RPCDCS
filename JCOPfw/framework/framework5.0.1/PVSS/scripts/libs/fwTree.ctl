string _fwTree_getNodeSys(string &dp)
{
int pos;
string res;

	if((pos = strpos(dp,":")) >= 0)
	{
		res = substr(dp,0,pos);
		dp = substr(dp,pos+1);
	}
	else
		res = "";
	return res;
}

string _fwTree_makeNodeName(string node)
{
	return "fwTN_"+node;
}

string _fwTree_getNodeName(string dp)
{
int pos;
string node;
			
	if((pos = strpos(dp,_fwTree_makeNodeName(""))) >= 0)
	{
		node = substr(dp,pos+5);
	}
	return node;
}

_fwTree_getChildren(string node, dyn_string &children)
{
	dpGet(node+".children",children);
}

_fwTree_setChildren(string node, dyn_string children)
{
	dpSet(node+".children",children);
}

_fwTree_getParent(string node, string &parent)
{
	if(dpExists(node))
		dpGet(node+".parent",parent);
}

_fwTree_setParent(string node, string parent)
{
	dpSet(node+".parent",parent);
}

_fwTree_exception(dyn_string &exInfo, string exType, string exText)
{
  dynAppend(exInfo, makeDynString(exType, exText, ""));
}

string _fwTree_makeClipboard(string tree)
{
string clipboard;
			
	clipboard = "---Clipboard"+tree+"---";
	return clipboard;
}

string _fwTree_getTree(string node)
{
	string sys, parent;

	sys = _fwTree_getNodeSys(node);
	if(sys != "")
		node = sys+":"+node;
	_fwTree_getParent(node, parent);
	if(parent == "")
		return node;
	if(sys != "")
		parent = sys+":"+parent;
	return _fwTree_getTree(parent);	
}

string _fwTree_getUpperCU(string node)
{
	string sys, parent = "";
	int cu = 0;

	sys = _fwTree_getNodeSys(node);
	if(sys != "")
		node = sys+":"+node;
	_fwTree_getParent(node, parent);
	if(parent == "")
		return "";
	if(sys != "")
		parent = sys+":"+parent;
	dpGet(node+".cu",cu);
	if(cu)
		return node;
	if(node == parent)
		return parent;
	return _fwTree_getUpperCU(parent);	
}

string _fwTree_getClipboard(string node)
{
string node_name;
string tree;
string clipboard;

	node_name = _fwTree_makeNodeName(node);
	tree = _fwTree_getTree(node_name);
	tree = _fwTree_getNodeName(tree);
	clipboard = _fwTree_makeClipboard(tree);
	return clipboard;
}


/**@name LIBRARY: fwTree:
 
library of functions to create and add/remove nodes to/from a Hierarchical Tree
	
modifications: none

WARNING: the functions use the dpGet or dpSetWait, problems may occur when using these functions 
                in a working function called by a PVSS (dpConnect) or in a calling function 
 
Usage: JCOP framework internal, public

PVSS manager usage: VISION, CTRL

@version creation: 16/07/2003
@author C. Gaspar
 
        
 
*/ 
//@{
//-------------------------------------------------------------------------------- 

//fwTree_create: 
/**  Create a new Tree.
 	
Usage: JCOP framework internal, public

PVSS manager usage: VISION, CTRL

      @param node: The name of the tree
      @param exInfo: exception - returns a warning if node already exists
*/

fwTree_create(string node, dyn_string &exInfo)
{
string node_name, clipboard;

	node_name = _fwTree_makeNodeName(node);
	if(!dpExists(node_name))
	{
		dpCreate(node_name,"_FwTreeNode");
		clipboard = _fwTree_makeClipboard(node);
		fwTree_addNode(node, clipboard, exInfo); 
	}
	else
	{
		_fwTree_exception(exInfo,"WARNING","fwTree_create(): node "+
		node+" already exists");
	}
}

//fwTree_addNode: 
/**  Add a node (child or root) to a Tree.
 	
Usage: JCOP framework internal, public

PVSS manager usage: VISION, CTRL

      @param parent: The name of the parent (the tree name for root nodes)
      @param node: The new node name
      @param exInfo: exception - returns a warning if node already exists
*/

fwTree_addNode(string parent, string node, dyn_string &exInfo, int dupl = 0)
{
string node_name, parent_name, old_parent_name;
dyn_string children;
int index;

	node_name = _fwTree_makeNodeName(node);
	parent_name = _fwTree_makeNodeName(parent);
	if(!dpExists(node_name))
	{
		dpCreate(node_name,"_FwTreeNode");
	}
	else
	{
		_fwTree_getParent(node_name, old_parent_name);
		if(parent_name != old_parent_name)
		{
			if(dpExists(old_parent_name))
			{
				_fwTree_getChildren(old_parent_name, children);
				if((index = dynContains(children,node_name)) >= 0)
				{
					dynRemove(children,index);
					_fwTree_setChildren(old_parent_name, children);
				}
			}		
		}	
		if(!dupl)
		{
			_fwTree_exception(exInfo,"WARNING","fwTree_addNode(): node "+
			node+" already exists");
		}
	}
	if(parent != "")
	{
		dpSet(node_name+".parent",parent_name);
		if(dpExists(parent_name))
		{
			_fwTree_getChildren(parent_name, children);
			if(!dynContains(children,node_name))
			{
				dynAppend(children,node_name);
				_fwTree_setChildren(parent_name, children);
			}		
		}
		else
		{
			_fwTree_exception(exInfo,"WARNING","fwTree_addNode(): parent "+
			parent+" does not exist");
		}
	}
}

_fwTree_removeNode(string parent, string node, dyn_string &exInfo)
{
string node_name, parent_name;
dyn_string children;
int i, index;

	node_name = _fwTree_makeNodeName(node);
	parent_name = _fwTree_makeNodeName(parent);
	if(dpExists(node_name))
	{
		dpDelete(node_name);
	}
	else
	{
		_fwTree_exception(exInfo,"WARNING","fwTree_removeNode(): node "+
		node+" does not exist");
	}
	
	if(dpExists(parent_name))
	{
		_fwTree_getChildren(parent_name, children);
		if((index = dynContains(children,node_name)) >= 0)
		{
			dynRemove(children,index);
			_fwTree_setChildren(parent_name, children);
		}		
	}	
}

//fwTree_removeNode: 
/**  Remove a node (child or root) from a Tree.
 	
Usage: JCOP framework internal, public

PVSS manager usage: VISION, CTRL

      @param parent: The name of the parent (the tree name for root nodes)
      @param node: The node name
      @param exInfo: exception - returns a warning if node does not exist
*/
 
fwTree_removeNode(string parent, string node, dyn_string &exInfo)
{
dyn_string children;
int i;

	fwTree_getChildren(node, children, exInfo);
	if(dynlen(children))
	{
		for(i = 1; i <= dynlen(children); i++)
		{
			fwTree_cutNode(node, children[i], exInfo);
		}
	}
	_fwTree_removeNode(parent, node, exInfo);	
}

//fwTree_cutNode: 
/**  Cut a sub tree from a Tree.
 	
Usage: JCOP framework internal, public

PVSS manager usage: VISION, CTRL

      @param parent: The name of the parent
      @param node: The start node of the sub tree
      @param exInfo: exception - returns a warning if node does not exist
*/
fwTree_cutNode(string parent, string node, dyn_string &exInfo)
{
string node_name, parent_name, clipboard;
dyn_string children;
int i, index;

	node_name = _fwTree_makeNodeName(node);
	parent_name = _fwTree_makeNodeName(parent);
	clipboard = _fwTree_getClipboard(node);
//	clipboard_name = _fwTree_makeNodeName(clipboard);
	if(dpExists(node_name))
	{
		dpSet(node_name+".parent","");
	}	
	else
	{
		_fwTree_exception(exInfo,"WARNING","fwTree_cutNode(): node "+
		node+" does not exist");
	}
	if(dpExists(parent_name))
	{
		_fwTree_getChildren(parent_name, children);
		if((index = dynContains(children,node_name)) >= 0)
		{
			dynRemove(children,index);
			_fwTree_setChildren(parent_name, children);
		}		
	}
	if(clipboard != parent)
	{
		fwTree_addNode(clipboard, node, exInfo, 1);
/*
	if(dpExists(clipboard_name))
	{
		_fwTree_getChildren(clipboard_name, children);
		if(!dynContains(children,node_name))
		{
			dynAppend(children,node_name);
			_fwTree_setChildren(parent_name, children);
		}		
	}
*/
	}
}

//fwTree_pasteNode: 
/**  Paste a sub tree into a Tree.
 	
Usage: JCOP framework internal, public

PVSS manager usage: VISION, CTRL

      @param parent: The name of the parent
      @param node: The start node of the sub-tree
      @param exInfo: exception - returns a warning if node does not exist
*/

fwTree_pasteNode(string parent, string node, dyn_string &exInfo)
{

	fwTree_cutNode(_fwTree_getClipboard(node), node, exInfo);
	fwTree_addNode(parent, node, exInfo, 1);
}

//fwTree_renameNode: 
/**  Rename a node from a Tree.
 	
Usage: JCOP framework internal, public

PVSS manager usage: VISION, CTRL

      @param node: The node name
      @param new_node: The new node name
      @param exInfo: exception - returns a warning if node does not exist
      @returns: The node name actually created
*/

string fwTree_renameNode(string node, string new_node, dyn_string &exInfo)
{
	string the_new_node;

	the_new_node = fwTree_makeNode(new_node, exInfo);
	_fwTree_renameNode(node, the_new_node, exInfo);
	return the_new_node;
}
 
_fwTree_renameNode(string node, string new_node, dyn_string &exInfo)
{
string node_name, parent, new_node_name;
dyn_string children;
int i, res;

	node_name = _fwTree_makeNodeName(node);
	new_node_name = _fwTree_makeNodeName(new_node);
	if(dpExists(node_name))
	{
		fwTree_getParent(node, parent, exInfo);
		fwTree_addNode(parent, new_node, exInfo);
		dpCopyOriginal(node_name, new_node_name, res);
		_fwTree_removeNode(parent, node, exInfo);
		_fwTree_getChildren(new_node_name, children);
		for(i = 1; i<= dynlen(children); i++)
		{
			dpSet(children[i]+".parent",new_node_name);
		}
	}
	else
	{
		_fwTree_exception(exInfo,"WARNING","fwTree_renameNode(): node "+
		node+" does not exist");
	}
}

//fwTree_getChildren: 
/**  Get the children of a Tree node.
 	
Usage: JCOP framework internal, public

PVSS manager usage: VISION, CTRL

      @param parent: The name of the parent
      @param nodes: The list of children nodes
      @param exInfo: exception return
*/
 
fwTree_getChildren(string parent, dyn_string &nodes, dyn_string &exInfo)
{
string parent_name, sys, top, clipboard, clipboard_name;
dyn_string children;
int i, root;

	dynClear(nodes);
	sys = _fwTree_getNodeSys(parent);
	if(sys != "")
		parent_name = sys+":";
	parent_name += _fwTree_makeNodeName(parent);
	root = 0;
	_fwTree_getParent(parent_name, top);
	if(top == "")
	{
		root = 1;
		clipboard = _fwTree_makeClipboard(parent);
		clipboard_name = _fwTree_makeNodeName(clipboard);
	}
	if(dpExists(parent_name))
	{
		_fwTree_getChildren(parent_name, children);
		for(i = 1; i <= dynlen(children); i++)
		{
			if(root)
			{
				if(children[i] != clipboard_name)
					dynAppend(nodes, _fwTree_getNodeName(children[i]));
			}
			else
				dynAppend(nodes, _fwTree_getNodeName(children[i]));
		}
	}
	else
	{
		_fwTree_exception(exInfo,"WARNING","fwTree_getChildren(): node "+
		parent+" does not exist");
	}
}

fwTree_getChildrenWithClipboard(string parent, dyn_string &nodes, dyn_string &exInfo)
{
string parent_name, sys, top, clipboard, clipboard_name;
dyn_string children;
int i, root;

	dynClear(nodes);
	sys = _fwTree_getNodeSys(parent);
	if(sys != "")
		parent_name = sys+":";
	parent_name += _fwTree_makeNodeName(parent);
/*
	root = 0;
	_fwTree_getParent(parent_name, top);
	if(top == "")
	{
		root = 1;
		clipboard = _fwTree_makeClipboard(parent);
		clipboard_name = _fwTree_makeNodeName(clipboard);
	}
*/
	if(dpExists(parent_name))
	{
		_fwTree_getChildren(parent_name, children);
		for(i = 1; i <= dynlen(children); i++)
		{
/*
			if(root)
			{
				if(children[i] != clipboard_name)
					dynAppend(nodes, _fwTree_getNodeName(children[i]));
			}
			else
*/
				dynAppend(nodes, _fwTree_getNodeName(children[i]));
		}
	}
	else
	{
		_fwTree_exception(exInfo,"WARNING","fwTree_getChildren(): node "+
		parent+" does not exist");
	}
}

//fwTree_reorderChildren: 
/**  Rename a node from a Tree.
 	
Usage: JCOP framework internal, public

PVSS manager usage: VISION, CTRL

      @param parent: The name of the parent
      @param nodes: The list of children in the new order
      @param exInfo: exception - returns a warning if node does not exist
*/
 
fwTree_reorderChildren(string parent, dyn_string children, dyn_string &exInfo)
{
string parent_name, sys, top, clipboard, clipboard_name;
dyn_string children_names;
int i, root;

//	sys = _fwTree_getNodeSys(parent);
//	if(sys != "")
//		parent_name = sys+":";
//	parent_name += _fwTree_makeNodeName(parent);
	parent_name = _fwTree_makeNodeName(parent);
	root = 0;
	_fwTree_getParent(parent_name, top);
	if(top == "")
	{
		root = 1;
		clipboard = _fwTree_makeClipboard(parent);
		clipboard_name = _fwTree_makeNodeName(clipboard);
	}
	if(dpExists(parent_name))
	{
//		_fwTree_getChildren(parent_name, nodes);
		if(root)
			dynAppend(children_names, clipboard_name);
		for(i = 1; i <= dynlen(children); i++)
		{
			dynAppend(children_names, _fwTree_makeNodeName(children[i]));
		}
		_fwTree_setChildren(parent_name, children_names);
	}
	else
	{
		_fwTree_exception(exInfo,"WARNING","fwTree_getChildren(): node "+
		parent+" does not exist");
	}
}

//fwTree_getParent: 
/**  Get the Parent of a Tree node.
 	
Usage: JCOP framework internal, public

PVSS manager usage: VISION, CTRL

      @param node: The node
      @param parent: The name of its parent
      @param exInfo: exception - returns a warning if node does not exist
*/
 
fwTree_getParent(string node, string &parent, dyn_string &exInfo)
{
string node_name, sys;

	parent = "";
	sys = _fwTree_getNodeSys(node);
	if(sys != "")
		node_name = sys+":";
	node_name += _fwTree_makeNodeName(node);
	if(dpExists(node_name))
	{
		dpGet(node_name+".parent",parent); 
		parent = _fwTree_getNodeName(parent);
	}
	else
	{
		_fwTree_exception(exInfo,"WARNING","fwTree_getParent(): node "+
		node+" does not exist");
	}
}

//fwTree_getTreeName: 
/**  get the Tree name of a node.
 	
Usage: JCOP framework internal, public

PVSS manager usage: VISION, CTRL

      @param node: The node
      @param tree: The name of the tree
      @param exInfo: exception - returns a warning if node does not exist
*/

fwTree_getTreeName(string node, string &tree, dyn_string &exInfo)
{
string node_name;
string sys;

	sys = _fwTree_getNodeSys(node);
	if(sys != "")
		node_name = sys+":";
	node_name += _fwTree_makeNodeName(node);
//	node_name = _fwTree_makeNodeName(node);
	if(dpExists(node_name))
	{
		tree = _fwTree_getTree(node_name);
		tree = _fwTree_getNodeName(tree);
	}
	else
	{
		_fwTree_exception(exInfo,"WARNING","fwTree_getTreeName(): node "+
		node+" does not exist");
	}
}

fwTree_getCUName(string node, string &cuname, dyn_string &exInfo)
{
string node_name;
string sys;

	sys = _fwTree_getNodeSys(node);
	if(sys != "")
		node_name = sys+":";
	node_name += _fwTree_makeNodeName(node);
//	node_name = _fwTree_makeNodeName(node);
	if(dpExists(node_name))
	{
		cuname = _fwTree_getUpperCU(node_name);
		cuname = _fwTree_getNodeName(cuname);
	}
	else
	{
		_fwTree_exception(exInfo,"WARNING","fwTree_getCUName(): node "+
		node+" does not exist");
	}
}

//fwTree_getRootNodes: 
/**  Get all Tree Root nodes, i.e. All trees.
 	
Usage: JCOP framework internal, public

PVSS manager usage: VISION, CTRL

      @param parents: The names of all root parents
      @param exInfo: exception return 
*/
 
fwTree_getRootNodes(dyn_string &parents, dyn_string &exInfo)
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
		if(node == "")
		{
			dynAppend(parents,_fwTree_getNodeName(dps[i]));
		}
	}
}

//fwTree_getAllNodes: 
/**  Get all Tree's nodes.
 	
Usage: JCOP framework internal, public

PVSS manager usage: VISION, CTRL

      @param nodes: The names of all nodes
      @param exInfo: exception return
*/
 
fwTree_getAllNodes(dyn_string &nodes, dyn_string &exInfo)
{
dyn_string dps;
int i;
string node;

	dynClear(nodes);
	dps = dpNames("*.","_FwTreeNode");
	for(i = 1; i <= dynlen(dps); i++)
	{
		dps[i] = substr(dps[i],0,strlen(dps[i])-1);
		dynAppend(nodes,_fwTree_getNodeName(dps[i]));
	}
}

//fwTree_getAllTreeNodes: 
/**  Get all nodes belonging to a Tree.
 	
Usage: JCOP framework internal, public

PVSS manager usage: VISION, CTRL

      @param tree: The name of the tree
      @param nodes: The names of all nodes
      @param exInfo: exception return
*/
 
fwTree_getAllTreeNodes(string tree, dyn_string &nodes, dyn_string &exInfo)
{
dyn_string children;
int i;

	fwTree_getChildren(tree, children, exInfo);
//	dynAppend(nodes, children);
//	if(!dynlen(children))
//		return;
	for(i = 1; i <= dynlen(children); i++)
	{
		dynAppend(nodes, children[i]);
		fwTree_getAllTreeNodes(children[i], nodes, exInfo);
	}
	return;
}

//fwTree_getAllTreeNodesWithClipboard: 
/**  Get all nodes belonging to a Tree.
 	
Usage: JCOP framework internal, public

PVSS manager usage: VISION, CTRL

      @param tree: The name of the tree
      @param nodes: The names of all nodes
      @param exInfo: exception return
*/
 
fwTree_getAllTreeNodesWithClipboard(string tree, dyn_string &nodes, dyn_string &exInfo)
{
dyn_string children;
int i;

	fwTree_getChildrenWithClipboard(tree, children, exInfo);
//	dynAppend(nodes, children);
//	if(!dynlen(children))
//		return;
	for(i = 1; i <= dynlen(children); i++)
	{
		dynAppend(nodes, children[i]);
		fwTree_getAllTreeNodesWithClipboard(children[i], nodes, exInfo);
	}
	return;
}

//fwTree_isNode: 
/**  Check if a node exists.
 	
Usage: JCOP framework internal, public

PVSS manager usage: VISION, CTRL

      @param node: The name of the node to check
      @param exInfo: exception return
      @return 1 for yes in local system, 2 for yes remotely, 0 for no
*/
 
int fwTree_isNode(string node, dyn_string &exInfo)
{
string sys, node_name;
dyn_string syss;
int i, found = 0;
dyn_uint ids;

	sys = _fwTree_getNodeSys(node);
	if(sys != "")
	{
		node_name = sys+":";
		node_name += _fwTree_makeNodeName(node);
		if(dpExists(node_name))
		{
			found = 1;
		}
	}
	else
	{
		node_name = _fwTree_makeNodeName(node);
		getSystemNames(syss, ids);
		for(i = 1; i <= dynlen(syss); i++)
		{ 
			if(dpExists(syss[i]+":"+node_name))
			{
				sys = syss[i];
				found = 1;
				break;
			}
		}
	}
	if(found)
	{
		if(sys+":" == getSystemName())
			return 1;
		else
			return 2;
	}
	return 0;
}

//fwTree_isRoot: 
/**  Check if a node is a root node (i.e. a Tree name).
 	
Usage: JCOP framework internal, public

PVSS manager usage: VISION, CTRL

      @param node: The name of the node to check
      @param exInfo: exception return
      @returns: 1 for yes, 0 for no
*/
 
int fwTree_isRoot(string node, dyn_string exInfo)
{
	string node_name, top;

	node_name = _fwTree_makeNodeName(node);
	_fwTree_getParent(node_name, top);
	if(top == "")
		return 1;
	return 0;
}

//fwTree_isClipboard: 
/**  Check if node is a Trees's clipboard.
 	
Usage: JCOP framework internal, public

PVSS manager usage: VISION, CTRL

      @param node: The name of the node to check
      @param exInfo: exception return
      @returns: 1 for yes, 0 for no
*/
 
int fwTree_isClipboard(string node, dyn_string exInfo)
{
	int pos;

	if((pos = strpos(node,"---Clipboard")) == 0)
		return 1;
	return 0;
}

string fwTree_getNodeSys(string node, dyn_string &exInfo)
{
string node_name, sys;
dyn_string syss;
int i, pos;
string itssys;
dyn_uint ids;

	sys = _fwTree_getNodeSys(node);
	if(sys != "")
	{
		node_name = sys+":";
		node_name += _fwTree_makeNodeName(node);
		if(dpExists(node_name))
		{
/*
			itssys = getSystemName();
			if((pos = strpos(itssys,":")) >= 0)
			{
				itssys = substr(itssys,0,pos);
			}
			return itssys;
*/
			return sys;
		}
	}
	else
	{
		node_name = _fwTree_makeNodeName(node);
		getSystemNames(syss, ids);
		for(i = 1; i <= dynlen(syss); i++)
		{ 
			if(dpExists(syss[i]+":"+node_name))
			{
				return syss[i];
			}
		}
	}
	return "";
}

//fwTree_setNodeDevice: 
/**  Set a node's device.
 	
Usage: JCOP framework internal, public

PVSS manager usage: VISION, CTRL

      @param node: The node name
      @param device: The device name (dp name) this node corresponds to
      @param type: The device type
      @param exInfo: exception - returns a warning if node does not exist
*/

fwTree_setNodeDevice(string node, string device, string type, dyn_string &exInfo)
{
string node_name;
string dev_dp;

	node_name = _fwTree_makeNodeName(node);
	if(dpExists(node_name))
	{
		dev_dp = device;
		dpSet(node_name+".device",dev_dp);
		if(dev_dp != "")
		{
			if(type == "")
				type = dpTypeName(dev_dp+".");
		}
		dpSet(node_name+".type",type);
	}
	else
	{
		_fwTree_exception(exInfo,"WARNING","fwTree_setNodeDevice(): node "+
		node+" does not exist");
	}
}

fwTree_getNodeCUDevice(string node, int &cu, string &device, string &type, dyn_string &exInfo)
{
string node_name, sys;
string dev_dp;

	device = "";
	type = "";
	sys = _fwTree_getNodeSys(node);
	if(sys != "")
		node_name = sys+":";
	node_name += _fwTree_makeNodeName(node);
	if(dpExists(node_name))
	{
		dpGet(
			node_name+".cu",cu,
			node_name+".device",dev_dp,
		      	node_name+".type",type);
		device = dev_dp;
	}
	else
	{
		_fwTree_exception(exInfo,"WARNING","fwTree_getNodeDevice(): node "+
		node+" does not exist");
	}
}

//fwTree_getNodeDevice: 
/**  Get a node's device.
 	
Usage: JCOP framework internal, public

PVSS manager usage: VISION, CTRL

      @param node: The node name
      @param device: The device name (dp name) this node corresponds to
      @param type: The device type
      @param exInfo: exception - returns a warning if node does not exist
*/

fwTree_getNodeDevice(string node, string &device, string &type, dyn_string &exInfo)
{
string node_name, sys;
string dev_dp;

	device = "";
	type = "";
	sys = _fwTree_getNodeSys(node);
	if(sys != "")
		node_name = sys+":";
	node_name += _fwTree_makeNodeName(node);
	if(dpExists(node_name))
	{
		dpGet(node_name+".device",dev_dp,
		      node_name+".type",type);
		device = dev_dp;
	}
	else
	{
		_fwTree_exception(exInfo,"WARNING","fwTree_getNodeDevice(): node "+
		node+" does not exist");
	}
}

//fwTree_setNodeUserData: 
/**  Set a node's specific user data.
 	
Usage: JCOP framework internal, public

PVSS manager usage: VISION, CTRL

      @param node: The node name
      @param data: The user data
      @param exInfo: exception - returns a warning if node does not exist
*/

fwTree_setNodeUserData(string node, dyn_string data, dyn_string &exInfo)
{
string sys, node_name;
string dev_dp;

	sys = _fwTree_getNodeSys(node);
	if(sys != "")
		node_name = sys+":";
	node_name += _fwTree_makeNodeName(node);
	if(dpExists(node_name))
	{
		dpSet(node_name+".userdata",data);
	}
	else
	{
		_fwTree_exception(exInfo,"WARNING","fwTree_setNodeUserData(): node "+
		node+" does not exist");
	}
}

//fwTree_getNodeUserData: 
/**  Get a node's specific user data.
 	
Usage: JCOP framework internal, public

PVSS manager usage: VISION, CTRL

      @param node: The node name
      @param data: The user data
      @param exInfo: exception - returns a warning if node does not exist
*/

fwTree_getNodeUserData(string node, dyn_string &data, dyn_string &exInfo)
{
string node_name, sys;

	dynClear(data);
	sys = _fwTree_getNodeSys(node);
	if(sys != "")
		node_name = sys+":";
	node_name += _fwTree_makeNodeName(node);
	if(dpExists(node_name))
	{
		dpGet(node_name+".userdata",data);
	}
	else
	{
		_fwTree_exception(exInfo,"WARNING","fwTree_getNodeUserData(): node "+
		node+" does not exist");
	}
}

fwTree_setNodeCU(string node, int cu, dyn_string &exInfo)
{
string node_name;

	node_name = _fwTree_makeNodeName(node);
	if(dpExists(node_name))
	{
		dpSet(node_name+".cu",cu);
	}
	else
	{
		_fwTree_exception(exInfo,"WARNING","fwTree_setNodeCU(): node "+
		node+" does not exist");
	}
}

fwTree_getNodeCU(string node, int &cu, dyn_string &exInfo)
{
string node_name, sys;

	cu = 0;
	sys = _fwTree_getNodeSys(node);
	if(sys != "")
		node_name = sys+":";
	node_name += _fwTree_makeNodeName(node);
	if(dpExists(node_name))
	{
		dpGet(node_name+".cu",cu);
	}
	else
	{
		_fwTree_exception(exInfo,"WARNING","fwTree_getNodeCU(): node "+
		node+" does not exist");
	}
}

string fwTree_makeNodeNumber(int n, string obj)
{
string refstr, refnum, ref;

	sprintf(refnum,"%04d",n);
	ref = "&"+refnum+obj;
	return ref;
}

string fwTree_makeNode(string obj, dyn_string &exInfo)
{
string node, tmp;
int n;

	node = fwTree_getNodeDisplayName(obj, exInfo);
	tmp = node;
	n = 0;
	while(fwTree_isNode(node, exInfo))
	{
		++n;
		node = fwTree_makeNodeNumber(n, tmp);
	}
	return node;
}

string fwTree_makeNodeRef(string obj, dyn_string &exInfo)
{
string node, tmp;
int n;

	node = fwTree_getNodeDisplayName(obj, exInfo);
	tmp = node;
	n = 1;
	node = fwTree_makeNodeNumber(n, tmp);
	while(fwTree_isNode(node, exInfo))
	{
		++n;
		node = fwTree_makeNodeNumber(n, tmp);
	}
	return node;
}

//fwTree_createNode: 
/**  Create and Add a node (child or root) to a Tree.
 	
Usage: JCOP framework internal, public

PVSS manager usage: VISION, CTRL

      @param parent: The name of the parent (the tree name for root nodes)
      @param node: The new node name
      @param exInfo: exception - returns a warning if node already exists
      @returns: The node name actually created
*/

string fwTree_createNode(string parent, string node, dyn_string &exInfo)
{
	string new_node;

	new_node = fwTree_makeNode(node, exInfo);
	fwTree_addNode(parent, new_node, exInfo);
	return new_node;
}

//fwTree_getNodeDisplayName: 
/**  Get a node's display name.
 	
Usage: JCOP framework internal, public

PVSS manager usage: VISION, CTRL

      @param node: The full node name
      @param exInfo: exception - returns an error in case of problems
      @returns: The node name to use for display purposes
*/

string fwTree_getNodeDisplayName(string node, dyn_string exInfo)
{
string obj, node_name, sys;

	sys = _fwTree_getNodeSys(node);
	obj = node;
	if(sys != "")
		node_name = sys+":";
	node_name += _fwTree_makeNodeName(node);
	if(!dpExists(node_name))
	{
		_fwTree_exception(exInfo,"WARNING","fwTree_getNodeDisplayName(): node "+
		node+" does not exist");
	}
	if(strpos(node,"&") == 0)
		obj = substr(node,5);
	return(obj);
}

//fwTree_getNamedNodes: 
/**  Get all nodes with the same name.
 	
Usage: JCOP framework internal, public

PVSS manager usage: VISION, CTRL

      @param name: The node name
      @param exInfo: exception - returns an error in case of problems
      @returns: All nodes with the same name
*/

dyn_string fwTree_getNamedNodes(string name, dyn_string &exInfo)
{
dyn_string dps, nodes;
string node, node_name;
int i;
	
	node = fwTree_getNodeDisplayName(name, exInfo);
	node_name = _fwTree_makeNodeName(node);
	if(dpExists(node_name))
		dynAppend(nodes, node);
	dps = dpNames("*:fwTN_&*"+node,"_FwTreeNode");
	for(i = 1; i <= dynlen(dps); i++)
	{
		node_name = _fwTree_getNodeName(dps[i]);
		if(strpos(node_name,node) == 5)
			dynAppend(nodes, node_name);
	}
/*
	dps = dpNames("*:fwTN_"+node,"_FwTreeNode");
	for(i = 1; i <= dynlen(dps); i++)
	{
		node_name = _fwTree_getNodeName(dps[i]);
//		if(strpos(node_name,node) == 5)
			dynAppend(nodes, node_name);
	}
*/
	return nodes;
}
