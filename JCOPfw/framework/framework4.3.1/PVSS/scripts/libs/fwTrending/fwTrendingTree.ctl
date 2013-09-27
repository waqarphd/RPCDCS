/**@file

This library contains the functions required by the Trending Tree

@par Creation Date
	04/11/04

@par Modification History
	None
	
@par Constraints
	Some functions rely on the fwTree and some require the Trending Editor and Navigator panel

@par Usage
	Internal

@par PVSS managers
	VISION

@author 
	Oliver Holme (IT-CO)
*/

//@{
const string fwTrendingTree_TREE_NAME = "TrendTree";
const int fwTrendingTree_USER_DATA_PARAMETERS = 1;

global bool isTrendEdit;
//@}

//@{
/** Function that is called when the user selects an item in the Trend Tree (Navigator mode) 

@par Constraints
	None

@par Usage
	Internal

@par PVSS managers
	VISION

@param node			input, name of the selected node
@param parent		input, name of the parent of the selected node
*/
TrendTree_navigator_selected(string node, string parent)
{
	fwTrendingTree_showItemInfo(node, parent);
}

/** Function that is called when the user selects an item in the Trend Tree (Editor mode) 

@par Constraints
	None

@par Usage
	Internal

@par PVSS managers
	VISION

@param node			input, name of the selected node
@param parent		input, name of the parent of the selected node
*/
TrendTree_editor_selected(string node, string parent)
{
	fwTrendingTree_showItemInfo(node, parent);
}

/** Function that is called when the user chooses to Add an item in the Trend Tree (Editor mode) 

Adapted from generic function in fwTreeDisplay.ctl

@par Constraints
	None

@par Usage
	Internal

@par PVSS managers
	VISION

@param parent		input, name of the parent of the node to be created
@param mode			input, the type of addition.  Can be one of:
									"addnode"			- add an emtpy node to the tree
									"addnew"			- create a new device (plot or page) and create a new node to add it in the tree
									"addexisting"	- create a new node to link to an existing device (plot or page)
@param done			output, value is 1 if the node was created, 0 if the process was stopped before creation
*/
fwTrendingTree_addToTree(string parent, string mode, int &done)
{
	dyn_string ret, exInfo;
	dyn_float res;
	string templateParameters, type, node, label, sys, msg, ref_parent;
	int i, cu, isnode, ref;

	done = 0;

	if(fwFsm_isObjectReference(parent))
		ref_parent = "&";
	ref_parent += fwTree_getNodeDisplayName(parent, exInfo);

	ChildPanelOnReturn("fwTrending/fwTrendingAddToTree.pnl","Add...",
		makeDynString(parent, ref_parent, 
		FwTreeTypes[CurrTreeIndex], FwTreeNames[CurrTreeIndex], "$mode:" + mode),
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
				if(mode != "addnode")
				{
					fwTrendingTree_getTemplateParameters(node, templateParameters, exInfo);
					fwTree_setNodeUserData(label, templateParameters, exInfo);
				}
				fwTree_setNodeCU(label, cu, exInfo);
				fwTreeDisplay_callUser2(
					FwActiveTrees[CurrTreeIndex]+"_nodeAdded",
					label, parent);
			}
	}
}

/** Function that displays the information about the currently selected node in the Trending Editor & Navigator

@par Constraints
	None

@par Usage
	Internal

@par PVSS managers
	VISION

@param node			input, name of the selected node
@param parent		input, name of the parent of the selected node
*/
fwTrendingTree_showItemInfo(string node, string parent)
{
	string device, deviceType, deviceName;
	dyn_string exceptionInfo;
	
	fwTree_getNodeDevice(node, device, deviceType, exceptionInfo);
	fwDevice_getType(deviceType, deviceName, exceptionInfo);
	
	if((device == "") && (deviceType == " "))
		deviceName = "Trending Tree Node";

	itemDpName.text = device;
	itemDpType.text = deviceName;
}

/** Function that is called when the user right-clicks an item in the Trend Tree (Navigator mode) 
It displays a contextual menu with the ncessary options for the selected device in the current mode.

Adapted from generic function in fwTreeDisplay.ctl

@par Constraints
	None

@par Usage
	Internal

@par PVSS managers
	VISION

@param node			input, name of the selected node
@param parent		input, name of the parent of the selected node
*/
TrendTree_navigator_entered(string node, string parent)
{
	int answer;
	string device, deviceType;
	dyn_string txt, exInfo;

	if((node == "0") && (parent == "0"))
		return;

	if(!fwTree_isRoot(node, exInfo))
	{
		fwTree_getNodeDevice(node, device, deviceType, exInfo);
		if((deviceType == fwTrending_PLOT) || (deviceType == fwTrending_PAGE))
			dynAppend(txt,"PUSH_BUTTON, View, 1, 1");
		else
			dynAppend(txt,"PUSH_BUTTON, View, 1, 0");
	}
	else
	{
		dynAppend(txt,"PUSH_BUTTON, Manage Plots and Pages..., 8, 1");
	}

	popupMenu(txt,answer);
			
	if(answer == 1)
	{
		fwTreeDisplay_callUser2(
			FwActiveTrees[CurrTreeIndex]+"_nodeView",
			node, parent);
	}
	if(answer == 8)
	{
		fwTrendingTree_manageTrendingDevices(node);
	}	
}

/** Function that is called when the user right-clicks an item in the Trend Tree (Editor mode) 
It displays a contextual menu with the ncessary options for the selected device in the current mode.

Adapted from generic function in fwTreeDisplay.ctl

@par Constraints
	None

@par Usage
	Internal

@par PVSS managers
	VISION

@param node			input, name of the selected node
@param parent		input, name of the parent of the selected node
*/
TrendTree_editor_entered(string node, string parent)
{
bool needs;
dyn_string txt, exInfo;
int answer, paste_flag, redo, wait = 0;
string tree, device, deviceType;

	if((node == "0") && (parent == "0"))
		return;

	redo = 0;
	if(PasteNode == "")
		paste_flag = 0;
	else
		paste_flag = 1;
	if(!fwTree_isClipboard(node, exInfo))
	{
		dynAppend(txt,"CASCADE_BUTTON, Add, 1");
	}
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
		fwTree_getNodeDevice(node, device, deviceType, exInfo);
		if((deviceType == fwTrending_PLOT) || (deviceType == fwTrending_PAGE))
		{
			dynAppend(txt,"SEPARATOR");
			dynAppend(txt,"PUSH_BUTTON, Settings, 7, 1");

			fwTrendingTree_checkIfNeedsTemplateParameters(node, device, deviceType, needs, exInfo);
			if(needs)			
				dynAppend(txt,"PUSH_BUTTON, Template Parameters, 8, 1");
			else
				dynAppend(txt,"PUSH_BUTTON, Template Parameters, 8, 0");
		}
		else
		{
			dynAppend(txt,"SEPARATOR");
			dynAppend(txt,"PUSH_BUTTON, Settings, 7, 0");
			dynAppend(txt,"PUSH_BUTTON, Template Parameters, 8, 0");
		}
	}
	if(fwTree_isRoot(node, exInfo))
	{
		dynAppend(txt,"SEPARATOR");
		dynAppend(txt,"PUSH_BUTTON, Manage Plots and Pages..., 9, 1");
	}

	if(!fwTree_isClipboard(node, exInfo))
	{
		dynAppend(txt,"Add");
		dynAppend(txt,"PUSH_BUTTON, Add Node..., 11, 1");
		dynAppend(txt,"PUSH_BUTTON, Add New Plot/Page..., 12, 1");
		dynAppend(txt,"PUSH_BUTTON, Add Existing Plot/Page..., 13, 1");
	}

	popupMenu(txt,answer);
	if(answer == 1)
	{
		fwTrendingTree_addToTree(node, "", redo);
	}
	if(answer == 11)
	{
		fwTrendingTree_addToTree(node, "addnode", redo);
	}
	if(answer == 12)
	{
		fwTrendingTree_addToTree(node, "addnew", redo);
	}
	if(answer == 13)
	{
		fwTrendingTree_addToTree(node, "addexisting", redo);
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
	if(answer == 8)
	{
		fwTreeDisplay_callUser2(
			FwActiveTrees[CurrTreeIndex]+"_nodeParameters",
			node, parent);
	}
	if(answer == 9)
	{
		fwTrendingTree_manageTrendingDevices(node);
	}
	
	if(redo)
	{
		fwTreeDisplay_setRedoTree(FwActiveTrees[CurrTreeIndex]);
	}	
	fwTree_getTreeName(parent, tree, exInfo);
	if(tree == "FSM")
		wait = 1;
	fwUi_uninformUserProgress(wait);
}

/** Function that is called when the user selects View from the contextual menu in the Trend Tree (Navigator mode) 

Adapted from generic function in fwTreeDisplay.ctl

@par Constraints
	None

@par Usage
	Internal

@par PVSS managers
	VISION

@param node			input, name of the selected node
@param parent		input, name of the parent of the selected node
*/
TrendTree_nodeView(string node, string parent)
{
	string device, deviceType;
	dyn_string exceptionInfo;

		fwTree_getNodeDevice(node, device, deviceType, exceptionInfo);
		fwTrendingTree_displayNode(node, device, deviceType, FALSE);
}

/** Function that is called when the user selects Settings from the contextual menu in the Trend Tree (Editor mode) 

Adapted from generic function in fwTreeDisplay.ctl

@par Constraints
	None

@par Usage
	Internal

@par PVSS managers
	VISION

@param node			input, name of the selected node
@param parent		input, name of the parent of the selected node
*/
TrendTree_nodeSettings(string node, string parent)
{
	string device, deviceType;
	dyn_string exceptionInfo;

		fwTree_getNodeDevice(node, device, deviceType, exceptionInfo);
		fwTrendingTree_displayNode(node, device, deviceType, TRUE);
}


/** Function that is called when the user selects Template Parameters from the contextual menu in the Trend Tree (Editor mode)
Reads any existing settings from the node user data and then lets the user modify the values for any required parameters.
This modified value is then saved back to the user data. 

@par Constraints
	None

@par Usage
	Internal

@par PVSS managers
	VISION

@param node			input, name of the selected node
@param parent		input, name of the parent of the selected node
*/
TrendTree_nodeParameters(string node, string parent)
{
	string device, deviceType;
	dyn_string userData, exceptionInfo;
	dyn_dyn_string configData;

		fwTree_getNodeDevice(node, device, deviceType, exceptionInfo);
		fwTree_getNodeUserData(node, userData, exceptionInfo);
		
		if(deviceType == fwTrending_PAGE)
			fwTrending_getPage(device, configData, exceptionInfo);
		else if(deviceType == fwTrending_PLOT)
			fwTrending_getPlot(device, configData, exceptionInfo);

		fwTrending_modifyAllTemplateParameters(fwTrendingTree_TREE_NAME, configData, deviceType,
																							userData[fwTrendingTree_USER_DATA_PARAMETERS], exceptionInfo, TRUE);
																							
		fwTree_setNodeUserData(node, userData, exceptionInfo);
}


/** Checks if any template parameters are mentioned in the configuration for the given node/device in the tree. 

@par Constraints
	None

@par Usage
	Internal

@par PVSS managers
	VISION

@param node						input, name of the selected node
@param device					input, name of the device attached to the node
@param deviceType			input, dp type of the device attached to the node
@param areNeeded			output, TRUE if any template parameters are mentioned in configuration, else FALSE
@param exceptionInfo	Any exceptions are returned here
*/
fwTrendingTree_checkIfNeedsTemplateParameters(string node, string device, string deviceType, bool &areNeeded, dyn_string &exceptionInfo)
{
	bool isConnected;
	dyn_string parameters;
	dyn_dyn_string configData;
	
	if(!dpExists(device))
	{
		areNeeded = FALSE;
		return;
	}
	
	_fwTrending_isSystemForDpeConnected(device, isConnected, exceptionInfo);
	if(!isConnected)
	{
		areNeeded = FALSE;
		return;
	}
	
	if(deviceType == fwTrending_PAGE)
		fwTrending_getPage(device, configData, exceptionInfo);
	else if(deviceType == fwTrending_PLOT)
		fwTrending_getPlot(device, configData, exceptionInfo);

	fwTrending_getAllTemplateParametersForConfiguration(configData, deviceType, parameters, exceptionInfo);

	if(dynlen(parameters)>0)
		areNeeded = TRUE;
	else
		areNeeded = FALSE;
}


/** Function that is called when the user selects "Manage Plots and Pages..." from the contextual menu in the Trend Tree (Editor mode) 

@par Constraints
	None

@par Usage
	Internal

@par PVSS managers
	VISION

@param node			input, used to determine the panel title and also passed as $ parameter to panel (but this is not used by the panel)
*/
fwTrendingTree_manageTrendingDevices(string node)
{
  ChildPanelOnCentral("fwTrending/fwTrendingManageChildren.pnl",
      "Manage Plots and Pages: "+node,
      makeDynString("$sDpName:" + node, 
							      "$sParentReference:"));
}

/** Function that is used to show either the editor or navigator panel for a specific tree node 

@par Constraints
	Only works for devices other than tree nodes (i.e. TrendingPages or TrendingPlots)

@par Usage
	Internal

@par PVSS managers
	VISION

@param node					input, the currently selected node in the tree
@param device				input, the name of the device attached to the selected node
@param deviceType		input, the dpType of the device attached to the selected node
@param editorMode		Optional parameter, default value TRUE.  TRUE to display editor panel, FALSE to show navigator panel.
*/
fwTrendingTree_displayNode(string node, string device, string deviceType, bool editorMode = TRUE)
{
	string templateParameters;
	dyn_string userData, exceptionInfo;

	if(editorMode)
	{
		if(dpExists(device))
			fwTrendingTree_showEditorPanel(device, deviceType, exceptionInfo);
		else
		{
			fwException_raise(exceptionInfo, "ERROR", "The device connected to this node does not exist.", "");
			fwExceptionHandling_display(exceptionInfo);
		}
	}
	else
	{
		fwTree_getNodeUserData(node, userData, exceptionInfo);
		if(dynlen(userData) >= fwTrendingTree_USER_DATA_PARAMETERS)
			fwTrendingTree_showNavigatorPanel(device, deviceType, userData[fwTrendingTree_USER_DATA_PARAMETERS], exceptionInfo);
		else
			fwTrendingTree_showNavigatorPanel(device, deviceType, "", exceptionInfo);
	}
}

/*
Function used to synchronise all the node names that are attached to the same device
The name is read from the dpe specified in the tree config for which to use as the name of a node.
The device is then found throughout the tree and each node is renamed to match the value in the dpe.

@par Constraints
	None

@par Usage
	Internal

@par PVSS managers
	VISION

@param tree		input, name of the tree to synchronise
@param dp			input, the dp which to synchronise the labels for

fwTrendingTree_updateLabelsForDp(string tree, string dp)
{
	int position, i;
	string dpeForName, device, deviceType, newLabel, nodeTypes, nodeNames;
	dyn_string dsNodeTypes, dsNodeNames, nodeList, exceptionInfo;

	deviceType = dpTypeName(dp);

	nodeTypes = fwTreeDisplay_getNodeTypes(tree);
	nodeNames = fwTreeDisplay_getNodeNames(tree);
	
	dsNodeTypes = strsplit(nodeTypes, ",");
	dsNodeNames = strsplit(nodeNames, ",");
	
	position = dynContains(dsNodeTypes, deviceType);
	dpeForName = dsNodeNames[position];
	strreplace(dpeForName, "DP", dp);
	dpGet(dpeForName, newLabel);

	fwTree_getAllTreeNodes(tree, nodeList, exceptionInfo);

	for(i=1; i<=dynlen(nodeList); i++)
	{
		fwTree_getNodeDevice(nodeList[i], device, deviceType, exceptionInfo);
		if(device == dp)
			fwTree_renameNode(nodeList[i], newLabel, exceptionInfo);
	}

		fwTreeDisplay_setRedoTree(tree);

}
*/

/** Finds all the occurences of a given device tree

@par Constraints
	None

@par Usage
	Internal

@par PVSS managers
	VISION

@param device					input, the device to search for
@param parents				input, a list of parents of the nodes to which the device is attached
@param nodes					input, a list of the nodes to which the device is attached
@param exceptionInfo	Any exceptions are returned here
*/
fwTrendingTree_findInTree(string device, dyn_string &parents, dyn_string &nodes, dyn_string &exceptionInfo)
{
	int i, length, j;
	string parent, linkedDevice, deviceType, label;
	dyn_uint dui;
	dyn_string sysNames, nodeList, tempNodeList;
	dyn_dyn_anytype dda;

	parents = makeDynString();
	nodes = makeDynString();

	getSystemNames(sysNames, dui);
	length = dynlen(sysNames);
	for(i=1; i<=length; i++)
	{
		dpQuery("SELECT '.parent:_online.._value'  FROM '*' REMOTE '" + sysNames[i] +
						":' WHERE _DPT = \"_FwTreeNode\" AND '.device:_online.._value' == \""
						+ device + "\"", dda);
						
		if(dynlen(dda)>1)
		{
			for(j=2; j<=dynlen(dda); j++)
			{
				dynAppend(nodes, dda[j][1]);
				dynAppend(parents, sysNames[i] + ":" + dda[j][2]);
			}
		}
	}
}

/** Shows the editor panel for the given device (panel to be shown is read from device definitions)

@par Constraints
	None

@par Usage
	Internal

@par PVSS managers
	VISION

@param device					input, the device to open the panel for
@param deviceType			input, the dpType of the device
@param exceptionInfo	Any exceptions are returned here
*/
fwTrendingTree_showEditorPanel(string device, string deviceType, dyn_string &exceptionInfo)
{
	string deviceTypeName, model;
	dyn_float df;
	dyn_string panelsList, ds;

	fwDevice_getModel(makeDynString(device), model, exceptionInfo);
	fwDevice_getDefaultConfigurationPanels(deviceType, panelsList, exceptionInfo, model);
	fwDevice_getType(deviceType, deviceTypeName, exceptionInfo);

	ChildPanelOnCentralReturn(panelsList[1] + ".pnl", 
							deviceTypeName + " configuration: " + device,
							makeDynString("$sDpName:" + device,
											"$Command:edit",
											"$sParentReference:"),
											df, ds);							
}

/** Shows the navigator panel for the given device (panel to be shown is read from device definitions)

@par Constraints
	None

@par Usage
	Internal

@par PVSS managers
	VISION

@param device									input, the device to open the panel for
@param deviceType							input, the dpType of the device
@param templateParameters			input, any template parameters for the device are passed here
@param exceptionInfo					Any exceptions are returned here
*/
fwTrendingTree_showNavigatorPanel(string device, string deviceType, string templateParameters, dyn_string &exceptionInfo)
{
	int rows, columns;
	string model;
	dyn_float df;
	dyn_string panelsList, ds;
	dyn_dyn_string data;

	fwDevice_getModel(makeDynString(device), model, exceptionInfo);
	fwDevice_getDefaultOperationPanels(deviceType, panelsList, exceptionInfo, model);
	
	if(deviceType == fwTrending_PAGE)
	{	
		if(dpExists(device))
			fwTrending_getPage(device, data, exceptionInfo);
		else
			data[fwTrending_PAGE_OBJECT_TITLE] = "Page";
		
		ChildPanelOn(panelsList[1] + ".pnl",
											"Trending Page: " + data[fwTrending_PAGE_OBJECT_TITLE],
											makeDynString("$PageName:" + device,
																		"$OpenPageName:" + device,
																		"$bEdit:", "$templateParameters:" + templateParameters), 0, 0);
	}
	else
	{
		if(dpExists(device))
			fwTrending_getPlot(device, data, exceptionInfo);
		else
			data[fwTrending_PLOT_OBJECT_TITLE] = "Plot";

		ChildPanelOn(panelsList[1] + ".pnl", 
												"Single Trend: " + data[fwTrending_PLOT_OBJECT_TITLE],
												makeDynString("$PageName:" + "",
																			"$OpenPageName:" + "",
																			"$PlotName:" + device,
																			"$bEdit:", "$templateParameters:" + templateParameters), 0, 0);
	}
}

/** Adds a clipboard to the Trend Tree

@par Constraints
	Only needs to be run once

@par Usage
	Internal

@par PVSS managers
	VISION
*/
_fwTrendingTree_addClipboard()
{
	dyn_string exceptionInfo;

	fwTree_addNode(fwTrendingTree_TREE_NAME,"---Clipboard" + fwTrendingTree_TREE_NAME + "---", exceptionInfo);
}

/** Upgrades old trees to the new format of tree (new format as of fwTrending2.3)

@par Constraints
	Should only be run once

@par Usage
	Internal

@par PVSS managers
	VISION
*/
_fwTrendingTree_upgradeTree()
{
	dyn_string nodes, exceptionInfo;
	int i, cu;

	fwTree_getRootNodes(nodes, exceptionInfo);
	for(i = 1; i <= dynlen(nodes); i++)
	{
		fwTree_getNodeCU(nodes[i], cu, exceptionInfo);
		if(!cu)
		{
			if(strpos(nodes[i], "WindowTree") == 0)
				continue;

			if(strpos(nodes[i], "---Clipboard") == 0)
				continue;
				
			if(strpos(nodes[i], "FSM") == 0)
				continue;
		
			if(strpos(nodes[i], fwTrendingTree_TREE_NAME) == 0)
				continue;

DebugN("\tUpgrading trend tree node "+nodes[i]+" for fwTrending2.3 and above");
			fwTree_addNode(fwTrendingTree_TREE_NAME, nodes[i], exceptionInfo);
		}
	}
}

/** Goes through old trees and adds the system name to any device references that do not contain the system name

@par Constraints
	If not system name is specified, it is assumed that the device is on the local system

@par Usage
	Internal

@par PVSS managers
	VISION
	
@param node		Used to recursively work through the tree.  Give the name of the top node of the tree
*/
_fwTrendingTree_addSystemNameRecursive(string node)
{
	int i;
	string device, type;
	dyn_string children, exceptionInfo;

	fwTree_getChildren(node, children, exceptionInfo);
	
	for(i=1; i<=dynlen(children); i++)
	{
		fwTree_getNodeDevice(children[i], device, type, exceptionInfo);
		if((device != "") && (strpos(device, ":") < 0))
		{
			fwTree_setNodeDevice(children[i], getSystemName() + device, type, exceptionInfo);
		}	
		_fwTrendingTree_addSystemNameRecursive(children[i]);
	}
}

/** For a given device connected to a tree node, this function will check if any template parameters are required.
If so, a dialog is shown and the user can enter values for the template parameters (or choose not to).
This string is then returned by the function, and the value should then be stored in the userData of the relevant data.

@par Constraints
	None

@par Usage
	Internal

@par PVSS managers
	VISION

@param device									input, the device to look at for template parameters
@param parameterString				output, any template parameters that were configured by the user are returned here
@param exceptionInfo					Any exceptions are returned here
*/
fwTrendingTree_getTemplateParameters(string device, string &parameterString, dyn_string &exceptionInfo)
{
	string dpType;
	dyn_dyn_string configurationData;

	parameterString = "";

	dpType = dpTypeName(device);
	switch(dpType)
	{
		case fwTrending_PAGE:
			fwTrending_getPage(device, configurationData, exceptionInfo);
			fwTrending_checkAndGetAllTemplateParameters(fwTrendingTree_TREE_NAME, configurationData, dpType, parameterString, exceptionInfo, TRUE);
			break;
		case fwTrending_PLOT:
			fwTrending_getPlot(device, configurationData, exceptionInfo);
			fwTrending_checkAndGetAllTemplateParameters(fwTrendingTree_TREE_NAME, configurationData, dpType, parameterString, exceptionInfo, TRUE);
			break;
		default:
			break;
	}
}
//@}


