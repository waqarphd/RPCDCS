/**@file

This library contains the functions needed by the Device Editor and Navigator.
The tool displays all the devices of the system in a hierarchical way. It also
allows to browse through them to display operation and configuration information.

@par Creation Date
	31/10/2001

@par Modification History					

@par Constraints
	Requires the fwTreeView and fwGeneral components of the Framework installed.

@par Usage
	Private

@par PVSS managers
	VISION

@author Manuel Gonzalez Berges (IT-CO)

*/

//@{

// Constants
const string fwDEN_DEVICE_MODULE	= "DEVICE_MODULE";

// Constants to define running modes
const string fwDEN_MODE_NAVIGATOR 		= "MODE_NAVIGATOR";
const string fwDEN_MODE_EDITOR 			= "MODE_EDITOR";
const string fwDEN_MODE_SAME 			= "MODE_SAME";
const string fwDEN_MODE_SWITCH 			= "MODE_SWITCH";

// Indexes for array with statuses
const string fwDEN_STATUS_LOCAL	= 1;
const string fwDEN_STATUS_EDIT	= 2;

// Commands through callback
const string fwDEN_COMMAND_REFRESH_NODE = "COMMAND_REFRESH_POSITION";
const string fwDEN_COMMAND_UPDATE_STATUS	= "COMMAND_UPDATE_STATUS";
const string fwDEN_COMMAND_REFRESH_SELECTED	= "COMMAND_REFRESH_SELECTED";

const string fwDEN_COMMAND_DP = "fwDeviceEditorNavigator_";

// Commands through right click
const int fwDEN_CANCEL			= 0;
const int fwDEN_COPY_LEAFS		= 1;
const int fwDEN_COPY_DEVICE		= 2;
const int fwDEN_CLIPBOARD_PASTE = 3;

// Commands through dpConnect
const string fwDEN_COMMAND_REFRESH	= "REFRESH";

// Tabs
const int fwDEN_TAB_INDEX_HARDWARE	= 0;
const int fwDEN_TAB_INDEX_LOGICAL	= 1;

// relative positin of the trees in the DEN
const int fwDEN_TREE_RELATIVE_X = 0;
const int fwDEN_TREE_RELATIVE_Y = 0;

// global variables

// default mode when starting
// cannot put directly fwDEN_MODE_NAVIGATOR because it is not evaluated (will be possible in 3.0?)
global string g_fwDEN_mode = "NAVIGATOR"; 

global string g_fwDEN_selectedDevice = "";
global string g_fwDEN_currentHierarchyType = "";

// mapping of tree types to level 1 node types
global mapping g_fwDEN_treeToNodeType;

// whether to display panels for a specific hierarchy type
global mapping g_fwDEN_displayDevicePanel;

// mapping of tress to hardware or logical hierarchies (the only real ones with children, etc)
global mapping g_fwDEN_treeToHierarchy;

// converts index of the tab to the reference name of the treeView
global mapping g_fwDEN_tabIndexToReference;
	
// selected system (used for hardware select)
global string g_fwDEN_selectedSystem = "";


_fwDeviceEditorNavigator_init()
{ 

	fwDevice_initialize();
	
  // hardware tree
  g_fwDEN_displayDevicePanel[fwDevice_HARDWARE] 	= TRUE;
  g_fwDEN_treeToNodeType[fwDevice_HARDWARE]		= fwNode_TYPE_VENDOR;
  g_fwDEN_treeToHierarchy[fwDevice_HARDWARE] 		= fwDevice_HARDWARE;
  g_fwDEN_tabIndexToReference[fwDEN_TAB_INDEX_HARDWARE] = "hardwareTree.";
  
  // hardware select tree
  g_fwDEN_displayDevicePanel[fwDevice_HARDWARE_SELECT]	= FALSE;
  g_fwDEN_treeToNodeType[fwDevice_HARDWARE_SELECT]	= fwNode_TYPE_VENDOR;
  g_fwDEN_treeToHierarchy[fwDevice_HARDWARE_SELECT]	= fwDevice_HARDWARE;
  
  // logical tree
  g_fwDEN_displayDevicePanel[fwDevice_LOGICAL] 	        = TRUE;
  g_fwDEN_treeToNodeType[fwDevice_LOGICAL]		= fwNode_TYPE_LOGICAL_ROOT;
  g_fwDEN_treeToHierarchy[fwDevice_LOGICAL]		= fwDevice_LOGICAL;
  g_fwDEN_tabIndexToReference[fwDEN_TAB_INDEX_LOGICAL]	= "logicalTree.";
  
  // logical clipboard tree
  g_fwDEN_displayDevicePanel[fwDevice_LOGICAL_CLIPBOARD] 	= false;
  g_fwDEN_treeToNodeType[fwDevice_LOGICAL_CLIPBOARD]		= fwNode_TYPE_LOGICAL_DELETED_ROOT;
  g_fwDEN_treeToHierarchy[fwDevice_LOGICAL_CLIPBOARD]		= fwDevice_LOGICAL;
  g_fwDEN_tabIndexToReference[fwDevice_LOGICAL_CLIPBOARD]	= "clipboard.";
}

/**

Modification History:

@par Constraints

@par Usage
	Private

@par PVSS managers
	VISION

@param exceptionInfo returns details of any exceptions
@param offsetX offset in the x direction to place device module
@param offsetY offset in the y direction to place device module
*/
fwDeviceEditorNavigator_openRootModule(dyn_string &exceptionInfo, int offsetX = 0, int offsetY = 0)
{
	int xPos, yPos, xSize, ySize;
	float f;
	dyn_int geometry;
 
 	getZoomFactor(f);

//	_fwDeviceEditorNavigator_getModuleGeometry(myManNum(), myModuleName(), geometry, exceptionInfo);
	
	panelPosition(myModuleName(), "", xPos, yPos);
	panelSize(rootPanel(), xSize, ySize);
//	DebugN(rootPanel());

//	DebugN(xPos, xSize, fwDEN_TREE_RELATIVE_X, offsetX, f);
//	DebugN(yPos, ySize, fwDEN_TREE_RELATIVE_Y, offsetY, f);
	

	ModuleOn(	fwDEN_DEVICE_MODULE, 
				xPos + (xSize + fwDEN_TREE_RELATIVE_X + offsetX) * f,
				yPos + (fwDEN_TREE_RELATIVE_Y + offsetY) * f ,
				0, 0, 1, 1, "Scale");
}

/**

@par Constraints

@par Usage
	Private

@par PVSS managers
	VISION

@param command
@param selectedNode
@param exceptionInfo returns details of any exceptions
*/
fwDeviceEditorNavigator_callCommand(string command, dyn_string selectedNode, dyn_string &exceptionInfo)
{  	
	switch(command)
	{
		case fwDEN_COMMAND_REFRESH_NODE:
		case fwDEN_COMMAND_UPDATE_STATUS:
		case fwDEN_COMMAND_REFRESH_SELECTED:
		
			dpSet(	fwDEN_COMMAND_DP + myManNum() + ".command", command,
					fwDEN_COMMAND_DP + myManNum() + ".selectedNode", selectedNode);
			break;
		default:
			fwException_raise(	exceptionInfo,
								"ERROR",
								"fwDeviceEditorNavigator_callCommand(): The command " + command + " is not supported",
								"");
			break;
	}
}

/**

@par Constraints

@par Usage
	Private

@par PVSS managers
	VISION

@param dpe1
@param command
@param dpe2
@param selectedNode
*/
fwDeviceEditorNavigator_executeCommand(string dpe1, string command, string dpe2, dyn_string selectedNode)
{  
	//DebugN("fwDeviceEditorNavigator_executeCommand");
	dyn_string exceptionInfo;
	switch(command)
	{
		case fwDEN_COMMAND_REFRESH_SELECTED:
		{
			int selectedTabIndex, pos;
			getValue("", "activeRegister", selectedTabIndex);
			//DebugN("Active tab is " + selectedTabIndex);
			fwTreeView_getSelectedPosition(pos, g_fwDEN_tabIndexToReference[selectedTabIndex]);
			fwDeviceEditorNavigator_expandTree(pos, g_fwDEN_tabIndexToReference[selectedTabIndex]);
			break;
		}
		case fwDEN_COMMAND_UPDATE_STATUS:
		{
			dyn_bool status;
			
			// get status and update mode
			_fwDeviceEditorNavigator_getStatus(selectedNode[fwTreeView_VALUE], status, exceptionInfo);
			if(!status[fwDEN_STATUS_LOCAL])
			{
				fwDeviceEditorNavigator_setMode(fwDEN_MODE_NAVIGATOR, FALSE, exceptionInfo);
			}
			else
			{
				fwDeviceEditorNavigator_setMode(fwDEN_MODE_SAME, TRUE, exceptionInfo);
			}
			break;
		}
		case fwDEN_COMMAND_REFRESH_NODE:
			break;
		default:
			break;
	}
}


/** Returns current status of the Device Editor & Navigator.
Currently this comprises:
	-whether a local or a remote system is selected
	-whether edit is possible
Also the global variable (g_fwDEN_selectedSystem) with the 
current selected system is updated.
	
@par Constraints

@par Usage
	Private

@par PVSS managers
	VISION

@param device device dp name or dp alias
@param status array with current status
			-status[fwDEN_STATUS_LOCAL]: whether we are in the local system or not
			-status[fwDEN_STATUS_EDIT]: whether we are in Editor mode or not.
@param exceptionInfo details of any exceptions are returned here
*/
_fwDeviceEditorNavigator_getStatus(string device, dyn_bool &status, dyn_string &exceptionInfo)
{ 
	// get current system name and check if it is local
	fwGeneral_getSystemName(device, g_fwDEN_selectedSystem, exceptionInfo);
	if(g_fwDEN_selectedSystem == getSystemName())
		status[fwDEN_STATUS_LOCAL] = TRUE;
	else
		status[fwDEN_STATUS_LOCAL] = FALSE;
	
	if(status[fwDEN_STATUS_LOCAL] && (g_fwDEN_mode == fwDEN_MODE_EDITOR))
		status[fwDEN_STATUS_EDIT] = TRUE;
	else
		status[fwDEN_STATUS_EDIT] = FALSE;	
		
	//DebugN(device, g_fwDEN_selectedSystem, getSystemName(), status);
}

/** Returns the geometry of a given module in a given user interface.

@par Constraints

@par Usage
	Private

@par PVSS managers
	VISION

@param uiNumber manager number of the UI we are interested in
@param reqModuleName name of the module we are interested in
@param geometry returns the geometry of the module
@param exceptionInfo details of any exceptions are returned here
*/
_fwDeviceEditorNavigator_getModuleGeometry(int uiNumber, string reqModuleName, dyn_int &geometry, dyn_string &exceptionInfo)
{  
	int x, y, width, height;
	string 	moduleName, panelName,
			dp = "_Ui_" + uiNumber;
	
	dpGet(	dp + ".ModuleGeometry.ModuleName", moduleName,
			dp + ".ModuleGeometry.PanelName", panelName,
			dp + ".ModuleGeometry.X", x,
			dp + ".ModuleGeometry.Y", y,
			dp + ".ModuleGeometry.Width", width,
			dp + ".ModuleGeometry.Height", height);
	
	//DebugN(moduleName, panelName, x, y, width, height);
	if(reqModuleName != moduleName)
	{
		fwException_raise(	exceptionInfo,
							"ERROR",
							"The desired module name is not currently active",
							"");
	}
	
	geometry = makeDynInt(x, y, width, height);
}


/** Function to paste a device (pastedDevice) and its children as
child of another device (destDevice) in the logical hierarchy

@par Constraints

@par Usage
	Private

@par PVSS managers
	VISION

@param destDevice destination device object
@param pastedDevice pasted device object
@param exceptionInfo details of any exceptions are returned here
*/
fwDeviceEditorNavigator_pasteLogical(dyn_string destDevice, dyn_string pastedDevice, dyn_string &exceptionInfo)
{
	int i, result;
	string deviceDp, dpNameWithoutSN, dpAliasWithoutSN;
	dyn_string children;
	dyn_errClass errorClass;
	
	//DebugN("fwDeviceEditorNavigator_pasteLogical. destDevice: " + destDevice + " pastedDevice " + pastedDevice);

	pastedDevice[fwDevice_DP_NAME] = strrtrim(dpAliasToName(pastedDevice[fwDevice_DP_ALIAS]), ".");	
	fwDevice_getChildren(pastedDevice[fwDevice_DP_ALIAS], fwDevice_LOGICAL, children, exceptionInfo);

	// build new dp alias: remove character marking cut and concatenate aliases
	fwDevice_getName(pastedDevice[fwDevice_DP_ALIAS], pastedDevice[fwDevice_ALIAS], exceptionInfo);
	pastedDevice[fwDevice_ALIAS] = strltrim(pastedDevice[fwDevice_ALIAS], fwDevice_HIERARCHY_LOGICAL_CUT);
	pastedDevice[fwDevice_DP_ALIAS] = destDevice[fwDevice_DP_ALIAS] + fwDevice_HIERARCHY_SEPARATOR + pastedDevice[fwDevice_ALIAS];
	
	// Remove root device from clipboard (only nodes can be root)
	if(dpTypeName(pastedDevice[fwDevice_DP_NAME]) == "FwNode")
	{
		//fwDeviceEditorNavigatorClipboard_addDevice(deviceDpName, exceptionInfo);
		fwNode_getType(pastedDevice[fwDevice_DP_NAME], pastedDevice[fwDevice_MODEL], exceptionInfo);
		
		// if the device being pasted was a root in the clipboard, its type has to be changed
		if(pastedDevice[fwDevice_MODEL] == fwNode_TYPE_LOGICAL_DELETED_ROOT)
		{
			// if no parent was specified, then we are pasting in the system level
			fwGeneral_getNameWithoutSN(destDevice[fwDevice_DP_NAME], dpNameWithoutSN, exceptionInfo);
			fwGeneral_getNameWithoutSN(destDevice[fwDevice_DP_ALIAS], dpAliasWithoutSN, exceptionInfo);
			if((dpNameWithoutSN == "") && (dpAliasWithoutSN == ""))
			{
				fwNode_setType(pastedDevice[fwDevice_DP_NAME], fwNode_TYPE_LOGICAL_ROOT, exceptionInfo);
				// correct default dp alias because no parent was given
				pastedDevice[fwDevice_DP_ALIAS] = strltrim(pastedDevice[fwDevice_DP_ALIAS], fwDevice_HIERARCHY_SEPARATOR);
			}
			else
			{
				// pasting in another logical node
				fwNode_setType(pastedDevice[fwDevice_DP_NAME], fwNode_TYPE_LOGICAL, exceptionInfo);
			}
		}
	}
	
	
	// the function is recursive because the children also have to be pasted
	for(i = 1; i <= dynlen(children); i++)
	{
		fwDeviceEditorNavigator_pasteLogical(pastedDevice, makeDynString("", "", "", "", children[i]), exceptionInfo);
	}

	fwGeneral_getNameWithoutSN(pastedDevice[fwDevice_DP_ALIAS], dpAliasWithoutSN, exceptionInfo);
	//DebugN("Setting alias for " + pastedDevice[fwDevice_DP_NAME] + " to " + dpAliasWithoutSN);
	result = dpSetAlias(pastedDevice[fwDevice_DP_NAME] + ".", dpAliasWithoutSN);	
	if(result)
	{
		errorClass = getLastError();
		//DebugN(errorClass);

		fwException_raise(exceptionInfo, "ERROR",
						  "fwDeviceEditorNavigator_pasteLogical(). Could not set alias of " + pastedDevice[fwDevice_DP_NAME] +
						  " to " + dpAliasWithoutSN,
						  "");
	}	
}

_fwDeviceEditorNavigator_displayAssociatedDevicePanel(string deviceDpName, string hierarchyType, string mode, dyn_string &exceptionInfo)
{
  dyn_string panelList;

  if(deviceDpName != "")
  {
    if(dpTypeName(deviceDpName) == "FwNode")
    {
      fwDevice_getInstancePanels(deviceDpName, mode, panelList, exceptionInfo);
    }
    else
    {
      string deviceModel;
      fwDevice_getModel(makeDynString(deviceDpName), deviceModel, exceptionInfo);
		
		switch(hierarchyType)
		{
			case fwDevice_HARDWARE:
			{
				if (mode == fwDEN_MODE_NAVIGATOR)
					fwDevice_getDefaultOperationPanels(dpTypeName(deviceDpName), panelList, exceptionInfo, deviceModel);
				else
					fwDevice_getDefaultConfigurationPanels(dpTypeName(deviceDpName), panelList, exceptionInfo, deviceModel);
				break;
			}
			case fwDevice_LOGICAL:
			{
				if (mode == fwDEN_MODE_NAVIGATOR)
					fwDevice_getDefaultOperationLogicalPanels(dpTypeName(deviceDpName), panelList, exceptionInfo, deviceModel);
				else
					fwDevice_getDefaultConfigurationLogicalPanels(dpTypeName(deviceDpName), panelList, exceptionInfo, deviceModel);
				break;
			}
			default:
				break;
		}
    }
  }
  
  if(dynlen(panelList) < 1)
    panelList = makeDynString("");			
	
  // if there is no panel associated close device module is opened
  if(panelList[1] == "")
  {
    if(isModuleOpen(fwDEN_DEVICE_MODULE))
      ModuleOff(fwDEN_DEVICE_MODULE);
    return;
  }
  
  if(!isModuleOpen(fwDEN_DEVICE_MODULE))
    fwDeviceEditorNavigator_openRootModule(exceptionInfo);
		
  if(getPath(PANELS_REL_PATH, panelList[1] + ".pnl") != "")
  {
    RootPanelOnModule(panelList[1] + ".pnl", 
                      panelList[1] + ".pnl " + deviceDpName + " in " + g_fwDEN_mode, 
                      fwDEN_DEVICE_MODULE,
                      makeDynString("$sDpName:" + deviceDpName,
                                    "$bHierarchyBrowser:" + TRUE,
                                    "$sParentReference:" + " ",
                                    "$sHierarchyType:" + hierarchyType));
  }
  else
  {
    fwException_raise(exceptionInfo, "WARNING",
                      "The panel \"" + panelList[1] +".pnl" + "\" could not be found", "");
  }
  
  if(dynlen(exceptionInfo) > 0)
    fwExceptionHandling_display(exceptionInfo);
}


//@}