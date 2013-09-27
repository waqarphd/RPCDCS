/**@name LIBRARY: fwFsmUi:
 
library of functions to use in order to create an Experiment Specific look and feel for FSM main panels,
these functions can be used inside a user specific "fwUiXXX.pnl".
A standard "fwUi.pnl" is distributed as an example.
	
modifications: none

Usage: JCOP framework internal, public

PVSS manager usage: VISION, CTRL

@version creation: 16/12/2005
@author C. Gaspar
 
        
 
*/ 
//@{
//-------------------------------------------------------------------------------- 

//fwFsmUi_init: 
/**  Initialize the Operations Panel.
Called by default by the standard fwUi.pnl (it initializes mainly the access control)
 	
Usage: JCOP framework internal, public

PVSS manager usage: VISION

      @param node: The node name (CU) for this panel (available in $node).
      @param obj: The object name (LU/DU/Obj) (available in $obj).
*/
fwFsmUi_init(string node, string obj)
{
DebugTN("+++++++++++++ Opening Panel", node, obj);

	fwFsm_initialize(0);
	fwUi_getAccess(node);
	fwUi_getDisplayInfo(makeDynString(node));
	if(!globalExists("FwFSMUi_ModePanelBusy"))
		addGlobal("FwFSMUi_ModePanelBusy", INT_VAR);
}

//fwFsmUi_addLogo: 
/**  Place a Logo in the FSM main panel.
 	
Usage: JCOP framework internal, public

PVSS manager usage: VISION

      @param name: The Logo name. 5 logos are available "CERN", "ALICE", "ATLAS", "CMS" and "LHCb".
      @param x: The X coordinate for the logo.
      @param y: The Y coordinate for the logo.
*/
fwFsmUi_addLogo(string name, int x, int y)
{
	addSymbol(myModuleName(),myPanelName(),"fwFSMuser/logo.pnl",
		"logo",
		makeDynString(name),
		x, y, 0,1,1);
}

//fwFsmUi_addClock: 
/**  Place a Clock in the FSM main panel.
 	
Usage: JCOP framework internal, public

PVSS manager usage: VISION

      @param x: The X coordinate for the clock.
      @param y: The Y coordinate for the clock.
*/
fwFsmUi_addClock(int x, int y)
{
	addSymbol(myModuleName(),myPanelName(),"fwFSM/ui/fwUiClock.pnl",
		"clock",
		makeDynString(),
		x, y, 0, 1 ,1);
}

//fwFsmUi_addUserLogin: 
/**  Place a Loggin widget in the FSM main panel.
 	
Usage: JCOP framework internal, public

PVSS manager usage: VISION

      @param x: The X coordinate for the Login widget.
      @param y: The Y coordinate for the Login widget.
*/
fwFsmUi_addUserLogin(int x, int y)
{

	if(isFunctionDefined("fwAccessControl_selectPrivileges"))
	{
		dyn_string types;

		types = dpTypes("_FwAccessControl*");
		if(dynlen(types))
		{
			addSymbol(myModuleName(), myPanelName(), 
				"objects/fwAccessControl/fwAccessControl_CurrentUser.pnl", "user", 
				makeDynString(), x, y, 0, 1, 1);
		}
	}
}

//fwFsmUi_addMessageBox: 
/**  Place a Message Box in the FSM main panel.
 	
Usage: JCOP framework internal, public

PVSS manager usage: VISION

      @param x: The X coordinate for the Message Box.
      @param y: The Y coordinate for the Message Box.
      @param width: The width of the message box (0 = default size)
*/
fwFsmUi_addMessageBox(int x, int y, int width = 0, string node = "")
{
  string type;
  
  fwCU_getType(node, type);
DebugN(type);
  if(type == "ECS_Domain_v1")
  {
DebugTN(node, type, x, y, width);
    y -= 30;
  }
	addSymbol(myModuleName(),myPanelName(),"fwFSM/ui/fwUiMessage.pnl",
		"message",
		makeDynString(width, node),
		x, y, 0,1,1);
}

//fwFsmUi_addCloseButton: 
/**  Place a Close Button in the FSM main panel.
When clicked the Close Button will release the FSM tree.
 	
Usage: JCOP framework internal, public

PVSS manager usage: VISION

      @param node: The node name (CU) for this panel (available in $node).
      @param obj: The Top object name (LU/DU/Obj) for this panel (available in $obj).
      @param x: The X coordinate for the Close Button.
      @param y: The Y coordinate for the Close Button.
*/
fwFsmUi_addCloseButton(string node, string obj, int x, int y)
{
	addSymbol(myModuleName(),myPanelName(),"fwFSM/ui/fwUiClose.pnl",
		"close",
		makeDynString("$node:"+node,"$obj:"+obj),
		x, y, 0,1,1);
}

//fwFsmUi_addObjWithLock: 
/**  Place an FSM Object with a CU type lock in the FSM main panel.
 	
Usage: JCOP framework internal, public

PVSS manager usage: VISION

      @param node: The node name (CU) for this panel (available in $node).
      @param obj: The object name (a CU) (either $obj or the result of fwFsmUi_getXXXChildren()).
      @param x: The X coordinate for the Object.
      @param y: The Y coordinate for the Object.
      @return The X coordinate of the end of the object, if the user wants to place an adjacent widget
*/
int fwFsmUi_addObjWithLock(string node, string obj, int x, int y, string part = "")
{
	int nextx;
	addSymbol(myModuleName(),myPanelName(),"fwFSM/ui/fwFsmObjWithLock.pnl",
		obj,
		makeDynString("$domain:"+node,"$obj:"+obj,"$part:"+part),
		x, y, 0,1,1);
	nextx = x+181+130+22;
	return nextx;
}

//fwFsmUi_addObjWithDevLock: 
/**  Place an FSM Object with a LU/DU/Obj type lock (enable/disable widget) in the FSM main panel.
 	
Usage: JCOP framework internal, public

PVSS manager usage: VISION

      @param node: The node name (CU) for this panel (available in $node).
      @param obj: The object name (LU/DU/Obj) (either $obj or the result of fwFsmUi_getXXXChildren()).
      @param x: The X coordinate for the Object.
      @param y: The Y coordinate for the Object.
      @return The X coordinate of the end of the object, if the user wants to place an adjacent widget
*/
int fwFsmUi_addObjWithDevLock(string node, string obj, int x, int y, string part = "")
{
	int nextx;
	addSymbol(myModuleName(),myPanelName(),"fwFSM/ui/fwFsmObjWithDevLock.pnl",
		obj,
		makeDynString("$domain:"+node,"$obj:"+obj,"$part:"+part),
		x, y, 0,1,1);
	nextx = x+181+130+22;
	return nextx;
}

//fwFsmUi_addObj: 
/**  Place an FSM Object without any lock widget in the FSM main panel.
 	
Usage: JCOP framework internal, public

PVSS manager usage: VISION

      @param node: The node name (CU) for this panel (available in $node).
      @param obj: The object name (CU/LU/DU/Obj) (either $obj or the result of fwFsmUi_getXXXChildren()).
      @param x: The X coordinate for the Object.
      @param y: The Y coordinate for the Object.
      @param panel: (optional) The filename of the panel to be placed, default: "fwFSM/ui/fwFsmObj.pnl".
      @return The X coordinate of the end of the object, if the user wants to place an adjacent widget
*/
int fwFsmUi_addObj(string node, string obj, int x, int y, 
	string panel = "fwFSM/ui/fwFsmObj.pnl", string part = "")
{
	int nextx;
	addSymbol(myModuleName(), myPanelName(), panel, obj,
		makeDynString("$domain:"+node,"$obj:"+obj,"$part:"+part),
		x, y, 0,1,1);
	nextx = x+181+130;
	return nextx;
}

//fwFsmUi_addObjButton: 
/**  Place only a small FSM Object (only state and actions) in the FSM main panel.
 	
Usage: JCOP framework internal, public

PVSS manager usage: VISION

      @param node: The node name (CU) for this panel (available in $node).
      @param obj: The object name (CU/LU/DU/Obj) (either $obj or the result of fwFsmUi_getXXXChildren()).
      @param x: The X coordinate for the Object.
      @param y: The Y coordinate for the Object.
      @param panel: (optional) The filename of the panel to be placed, default: "fwFSM/ui/fwSmiObj.pnl".
      @param params: (optional) Additional $parameters to be passed to the panel, default: none.
      @return The X coordinate of the end of the object, if the user wants to place an adjacent widget
*/
int fwFsmUi_addObjButton(string node, string obj, int x, int y,
	string panel = "fwFSM/ui/fwSmiObj.pnl", dyn_string params = makeDynString(), string part = "")
{
	int nextx;
	dyn_string pars;

	pars = makeDynString("$domain:"+node,"$obj:"+obj,"$part:"+part);
	dynAppend(pars, params);
	addSymbol(myModuleName(), myPanelName(), panel, obj, pars,
		x, y, 0,1,1);
	nextx = x+130;
	return nextx;
}

//fwFsmUi_addLockButton: 
/**  Place only a a CU type lock for a given CU in the FSM main panel.
 	
Usage: JCOP framework internal, public

PVSS manager usage: VISION

      @param node: The node name (CU) for this panel (available in $node).
      @param obj: The object name (CU) (either $obj or the result of fwFsmUi_getXXXChildren()).
      @param x: The X coordinate for the Lock Widget.
      @param y: The Y coordinate for the Lock Widget.
      @return The X coordinate of the end of the object, if the user wants to place an adjacent widget
*/
int fwFsmUi_addLockButton(string node, string obj, int x, int y)
{
	int nextx;
	addSymbol(myModuleName(),myPanelName(),"fwFSM/ui/fwFsmLock.pnl",
		obj,
		makeDynString("$domain:"+node,"$obj:"+obj),
		x, y, 0,1,1);
	nextx = x+22;
	return nextx;
}

//fwFsmUi_addDevLockButton: 
/**  Place only a LU/DU/Obj type lock (enable/disable widget) for a given Object in the FSM main panel.
 	
Usage: JCOP framework internal, public

PVSS manager usage: VISION

      @param node: The node name (CU) for this panel (available in $node).
      @param obj: The object name (LU/DU/Obj) (either $obj or the result of fwFsmUi_getXXXChildren()).
      @param x: The X coordinate for the Widget.
      @param y: The Y coordinate for the Widget.
      @return The X coordinate of the end of the object, if the user wants to place an adjacent widget
*/
int fwFsmUi_addDevLockButton(string node, string obj, int x, int y, string part = "")
{
	int nextx;
	addSymbol(myModuleName(),myPanelName(),"fwFSM/ui/fwFsmDevLock.pnl",
		obj,
		makeDynString("$domain:"+node,"$obj:"+obj,"$part:"+part),
		x, y, 0,1,1);
	nextx = x+22;
	return nextx;
}

//fwFsmUi_removeObj: 
/**  Remove an FSM Object from the FSM main panel.
 	
Usage: JCOP framework internal, public

PVSS manager usage: VISION

      @param node: The node name (CU) for this panel (available in $node).
      @param obj: The object name (LU/DU/Obj) (either $obj or the result of fwFsmUi_getXXXChildren()).
*/
void fwFsmUi_removeObj(string node, string obj)
{
	removeSymbol(myModuleName(),myPanelName(),obj);
}

//fwFsmUi_addAlarmButton: 
/**  Place an Alarm Button in the FSM main panel.
 	
Usage: JCOP framework internal, public

PVSS manager usage: VISION

      @param node: The node name (CU) for this panel (available in $node).
      @param obj: The object name (CU/LU/DU/Obj) (normally $obj).
      @param x: The X coordinate for the Alarm Button.
      @param y: The Y coordinate for the Alarm Button.
      @return The X coordinate of the end of the object, if the user wants to place an adjacent widget
*/
int fwFsmUi_addAlarmButton(string node, string obj, int x, int y)
{
	int nextx;
	addSymbol(myModuleName(),myPanelName(),"fwFSM/ui/fwAlarmButton.pnl",
		"AlButton",
		makeDynString("$node:"+node,"$obj:"+obj),
		x, y, 0,1,1);
	nextx = x+33;
	return nextx;
}

//fwFsmUi_addUserPanel: 
/**  Place a User Panel in the FSM main panel.
 	
Usage: JCOP framework internal, public

PVSS manager usage: VISION

      @param node: The node name (CU) for this panel (available in $node).
      @param obj: The object name (CU/LU/DU/Obj) (normally $obj).
      @param x: The X coordinate for the User Panel.
      @param y: The Y coordinate for the User Panel.
*/
fwFsmUi_addUserPanel(string node, string obj, int x, int y)
{
	string panel, panel_path, sys, dev;

	fwUi_getUserPanel(node, obj, panel);
	if(panel != "")
	{
		panel_path = fwUi_getPanelPath(panel);
		if(panel_path != "")
		{
			dev = obj;
			if(fwFsm_isDU(node, obj))
			{
				fwUi_getDomainSys(node, sys);
				dev = fwFsm_getPhysicalDeviceName(sys+obj);
				dev = sys+dev;
			}
			addSymbol(myModuleName(),myPanelName(),panel_path,
				"specific",
				makeDynString(node, dev),
				x, y, 0,1,1);
		}
	}
}

//fwFsmUi_getAllChildren: 
/**  Get All Visible Children of a node (CU or LU) in the FSM main panel.
 	
Usage: JCOP framework internal, public

PVSS manager usage: VISION

      @param node: The node name (CU) for this panel (available in $node).
      @param obj: The object name (CU/LU) (normally $obj).
      @param flags: Return the type of each child: 1 = CU, 2 = DU, 0 = LU or Obj.
      @return The list of children.
*/
dyn_string fwFsmUi_getAllChildren(string node, string obj, dyn_int &flags)
{
dyn_string children;

	children = fwFsm_getObjChildren(node, obj, flags);
	fwUi_removeNotVisibleChildrenFlags(node, children, flags);
	return children;
}

dyn_string fwFsmUi_getChildrenCUs(string node)
{
dyn_string children;

	children = fwFsm_getLogicalUnitCUs(node);
	fwUi_removeNotVisibleChildren(node, children);
	return children;
}

dyn_string fwFsmUi_getChildrenDUs(string node, string lunit="")
{
dyn_string children;

	if(lunit == "")
		lunit = node;
	children = fwFsm_getLogicalUnitDevices(node, lunit);
	fwUi_removeNotVisibleChildren(node, children);
	return children;
}

dyn_string fwFsmUi_getChildrenObjs(string node, string lunit = "")
{
dyn_string children;

	if(lunit == "")
		lunit = node;
	children = fwFsm_getLogicalUnitObjects(node, lunit);
	fwUi_removeNotVisibleChildren(node, children);
	return children;
}

int fwFsmUi_connectModeBits(string callback, string domain, string obj, int wait = 1, string part = "")
{
	int ret;

	ret = fwUi_connectModeBits(callback, domain, obj, wait, part);
	return ret;
}

fwFsmUi_disconnectModeBits(string domain, string obj)
{

	fwUi_disconnectModeBits(domain, obj);
}

bit32 fwFsmUi_getOwnModeBits()
{
	return fwUi_getOwnModeBits();
}

bit32 fwFsmUi_getModeBits(string domain, string obj)
{
	return fwUi_getModeBits(domain, obj);
}

int fwFsmUi_isFree(bit32 statusBits)
{
	return getBit(statusBits, FwFreeBit);
}

int fwFsmUi_isOwner(bit32 statusBits)
{
	return getBit(statusBits, FwOwnerBit);
}

int fwFsmUi_isExclusive(bit32 statusBits)
{
	return getBit(statusBits, FwExclusiveBit);
}

int fwFsmUi_isShared(bit32 statusBits)
{
	return !getBit(statusBits, FwExclusiveBit);
}

int fwFsmUi_isComplete(bit32 statusBits)
{
	return getBit(statusBits, FwCompleteBit);
}

int fwFsmUi_areStatesUsed(bit32 statusBits)
{
	return getBit(statusBits, FwUseStatesBit);
}

int fwFsmUi_areCommandsSent(bit32 statusBits)
{
	return getBit(statusBits, FwSendCommandsBit);
}

// exclusive, useStates or sendCommands = -1 => means no change)
fwFsmUi_setCUMode(string domain, string obj, int exclusive, int useStates, int sendCommands)
{
	fwUi_setCUMode(domain, obj, exclusive, useStates, sendCommands);
}

fwFsmUi_setDUMode(string domain, string obj, int enable)
{
	fwUi_setDUMode(domain, obj, enable);
}

string fwFsmUi_getCUMode(string domain, string obj)
{
	return fwUi_getCUMode(domain, obj);
}

string fwFsmUi_getDUMode(string domain, string obj)
{
	return fwUi_getDUMode(domain, obj);
}

dyn_string fwFsmUi_getCUModeActions(string domain, string obj)
{
	return fwUi_getCUModeActions(domain, obj);
}

dyn_string fwFsmUi_getDUModeActions(string domain, string obj)
{
	return fwUi_getDUModeActions(domain, obj);
}

fwFsmUi_setCUModeByName(string domain, string obj, string cmd)
{
	fwUi_setCUModeByName(domain, obj, cmd);
}

fwFsmUi_setDUModeByName(string domain, string obj, string cmd, string part = "")
{
	fwUi_setDUModeByName(domain, obj, cmd, part);
}

int fwFsmUi_connectSummaryAlarm(string callback, string domain, string lunit = "")
{
int ret;

	ret = fwUi_connectSummaryAlarm(callback,domain,lunit);
	return ret;
}

fwFsmUi_disconnectSummaryAlarm(string domain, string lunit = "")
{
	fwUi_disconnectSummaryAlarm(domain,lunit);
}

string FwFsmUi_AlarmCallback;

//fwFsmUi_connectAlarmState: 
/**  Connect to the alarm state of the top node (CU, LU or DU) in the FSM main panel.
The Callback function will be called with one parameter: 
yourCallbackName(int alarm_state), <alarm_state> can be 1 = yes, there are alarms; 0 = No, no alarms.
 	
Usage: JCOP framework internal, public

PVSS manager usage: VISION, CTRL

      @param callback: The routine to be called when the alarm state changes
      @param node: The node name (CU) for this panel (available in $node).
      @param obj: The object name (CU/LU/DU) (normally $obj).
*/
int fwFsmUi_connectAlarmState(string callback, string node, string obj)
{

	FwFsmUi_AlarmCallback = callback;
	fwCU_connectAlarmState("_fwFsmUi_alarmStateChanged", node+"::"+obj);
	
}

//fwFsmUi_disconnectAlarmState: 
/**  Disconnect from the alarm state of the top node (CU, LU or DU) in the FSM main panel.
 	
Usage: JCOP framework internal, public

PVSS manager usage: VISION, CTRL

      @param node: The node name (CU) for this panel (available in $node).
      @param obj: The object name (CU/LU/DU) (normally $obj).
*/
int fwFsmUi_disconnectAlarmState(string node, string obj)
{

	fwCU_disconnectAlarmState(node+"::"+obj);	
}

_fwFsmUi_alarmStateChanged(string node, int state)
{
	delay(0, 500);
	startThread(FwFsmUi_AlarmCallback, state);
}

int FwFsmUi_AlertFilterFirstTime = 1;

//fwFsmUi_setAlarmFilter: 
/**  If an 'Alert Row' has been included in the FSM main panel, set its filter to represent the FSM Tree.
This routine should be used inside the callback passed to fwFsmUi_connectAlarmState.
 	
Usage: JCOP framework internal, public

PVSS manager usage: VISION, CTRL

      @param node: The node name (CU) for this panel (available in $node).
      @param obj: The object name (CU/LU/DU) (normally $obj).
*/
fwFsmUi_setAlarmFilter(string node, string obj)
{
	string domain, sys;
	dyn_string devices;
	int i, index;

	devices = fwUi_getIncludedTreeDevices(node, obj);
	for(i = 1; i <= dynlen(devices); i++)
	{
		sys = fwFsm_getSystem(devices[i]);
		devices[i] = sys+":"+fwFsm_getPhysicalDeviceName(devices[i]);
	}
	if(FwFsmUi_AlertFilterFirstTime)
	{
	  	delay(2);
		FwFsmUi_AlertFilterFirstTime = 0;
	}
	fwUi_setAlarmFilter(devices);
}

//fwFsmUi_getOperatorAccess: 
/**  Check if the Logged in user has "Operator" Privileges.
 	
Usage: JCOP framework internal, public

PVSS manager usage: VISION

      @param node: The node name (CU) for this panel (available in $node).
      @param obj: (optional) The object name (LU/DU/Obj) (available in $obj).
      @return 1:yes, 0:no
*/
int fwFsmUi_getOperatorAccess(string domain, string obj = "")
{
	int index, topIndex;
	string node;
	string sub_domain;

	node = domain;
	if(obj != "")
	{
		if((sub_domain = fwFsm_getAssociatedDomain(obj)) != "")
		{
			node = sub_domain;
		}
	}
	topIndex = dynContains(AccessControlTopNodes, domain);
	if(!topIndex)
		return 1;
	if(index = dynContains(AccessControlNodes[topIndex], node))
	{
		return AccessControlOperatorGranted[topIndex][index];
	}
	return fwUi_getOperatorAccess(node);
}

//fwFsmUi_getExpertAccess: 
/**  Check if the Logged in user has "Expert" Privileges.
 	
Usage: JCOP framework internal, public

PVSS manager usage: VISION

      @param node: The node name (CU) for this panel (available in $node).
      @param obj: (Optional) The object name (LU/DU/Obj) (available in $obj).
      @return 1:yes, 0:no
*/
int fwFsmUi_getExpertAccess(string domain, string obj = "")
{
	int index, topIndex;
	string node;
	string sub_domain;

	node = domain;
	if(obj != "")
	{
		if((sub_domain = fwFsm_getAssociatedDomain(obj)) != "")
		{
			node = sub_domain;
		}
	}
	topIndex = dynContains(AccessControlTopNodes, domain);
	if(!topIndex)
		return 1;
	if(index = dynContains(AccessControlNodes[topIndex], node))
	{
		return AccessControlExpertGranted[topIndex][index];
	}
	return fwUi_getExpertAccess(node);
}

//fwFsmUi_report: 
/**  Reports a User Message in the "Messages" box of the current panel.
Can be used by a User Specific Panel to report messages and also to report messages
to a specific CU panel even from a control script.
 	
Usage: JCOP framework internal, public

PVSS manager usage: VISION

      @param msg: The message to be reported
      @param node: (optional) The node name (CU) where the message should be reported.
*/
fwFsmUi_report(string msg, string node = "")
{
	fwUi_report(msg, node);
}

string myDomain, myObj, ColorWidget, StateWidget, ActionsWidget;
string State = "";
int FSMBusy = 0;
int Operateable = -1;
int AccessControlOperator = -1;
int AccessControlExpert = -1;
time myLastChange = 0;
int myDelaying = 0;
global mapping ActionFilters;

fwFsmUi_setActionFilter(string domain, string obj, dyn_string actions)
{
  ActionFilters[domain+"::"+obj] = actions;
}

dyn_string fwFsmUi_getActionFilter(string domain, string obj)
{
  dyn_string actions;
  if(mappingHasKey(ActionFilters,domain+"::"+obj))
  {
    actions = ActionFilters[domain+"::"+obj];
//    DebugN("mappingHasKey",domain+"::"+obj, actions);
  }
  return actions;
}

//fwFsmUi_connectObjButton: 
/**  Connect a display widget (CascadeButton for example) to state changes of an FSM object.
Can be used in reference panels of the family of the ones used with fwFsmUi_addObjXXX (fwFsmObj.pnl)
Can be called in the "EventInitialize" of any button or widget in the reference panel. 
Different widget names can be given to show the state, the color and/or the current list of actions.
If The list of actions is to be shown the "actionsWidget" must be a "CascadeButton".

Usage: JCOP framework internal, public

PVSS manager usage: VISION, CTRL

      @param domain: The node name (CU) in this reference panel (normally $domain).
      @param obj: The object name (CU/LU/DU) (normally $obj).
      @param colorWidget: A widget for showing the color: "none" (default) - means don't show the color, "" - means current widget.
      @param stateWidget: A widget for showing the state: "none" (default) - means don't show the state, "" - means current widget.
      @param actionsWidget: A widget for showing the list of actions: "none" (default) - means don't show the actions, "" - means current widget.
*/
fwFsmUi_connectObjButton(string domain, string obj, 
	string colorWidget = "none", string stateWidget = "none", string actionsWidget = "none",
	string part = "")
{
	dyn_string exInfo;

	myDomain = domain;
	myObj = obj;
	ColorWidget = colorWidget;
	StateWidget = stateWidget;
	ActionsWidget = actionsWidget;
//DebugTN("Calling fwUi_addLocalObj from fwFsmUi_connectObjButton");
  fwUi_addLocalObj(domain, obj);
	fwUi_connectCurrentState("_fwFsmUi_show_state", domain, obj);
	fwUi_connectExecutingAction("_fwFsmUi_show_busy", domain, obj);
	fwFsmUi_connectModeBits("_fwFsmUi_show_mode", domain, obj, 1, part);
	if(isFunctionDefined("fwAccessControl_setupPanel"))
	{
		fwAccessControl_setupPanel("_fwFsmUi_loggedUserAccessControlCallback",exInfo);
	}
}


_fwFsmUi_loggedUserAccessControlCallback(string s1, string s2)
{
	int topIndex;
//DebugTN("accessControlCallback button", $domain);
	topIndex = dynContains(AccessControlTopNodes, $domain);
//DebugN("topIndex", $domain, topIndex);
	if(!topIndex)
		return;
	while(AccessControlTopNodeBusy[topIndex])
		delay(0,500);
//DebugTN("accessControlCallback button done");
	_fwFsmUi_show_mode();
}

_fwFsmUi_show_state(string dp, string state)
{
	int operate_domain, operate_object;

//DebugTN("***************** Show State", dp, state);
	if(Operateable == -1)
	{ 
//		fwUi_getDomainOperation(FwFsm_TopDomain, operate_domain);
		fwUi_getDomainOperation(fwUi_getTopDomain(myDomain, myObj), operate_domain);
		fwUi_getOperation(myDomain, myObj, operate_object);
		Operateable = (operate_domain && operate_object);
	}
/*
	if(AccessControlOperator == -1)
	{
		AccessControlOperator = fwFsmUi_getOperatorAccess(myDomain, myObj);
		AccessControlExpert = fwFsmUi_getExpertAccess(myDomain, myObj);
	}
*/
	State = fwUi_convertLocalCurrentState(myDomain, myObj, state);
	if(StateWidget != "none")
		setValue(StateWidget,"text",State);
	_fwFsmUi_show_mode();
}

_fwFsmUi_show_busy(string dp, string action)
{
//DebugTN("***************** Show Busy", dp, action);
	if(StateWidget == "none")
		return;
	if(action == "")
	{
		FSMBusy = 0;
//		setValue(StateWidget,"enabled",1);
	}
	else
	{
		FSMBusy = 1;
//		setValue(StateWidget,"enabled",0);
	}
	_fwFsmUi_show_mode();
}

_fwFsmUi_show_mode()
{
	bit32 bits;
	int operate, colored, oper, force_operate = 0;
	int i;
	string color;
	dyn_string actions, actionFilter;
	dyn_int visis;
	time t;

//DebugTN("*** fwUi_show_mode Starting",myDomain, myObj);
	if(!myDelaying)
	{
		myDelaying = 1;
//		delay(0, 800);
		delay(1);
		myDelaying = 0;
	}
	else
	{
//DebugTN("fwUi_show_mode Returning!",myDomain, myObj);
		return;
	}

	bits = fwFsmUi_getOwnModeBits();
	if(State == "")
		return;

	if(FSMBusy)
		setValue(StateWidget,"foreCol","grey");
	else
		setValue(StateWidget,"foreCol","black");
	fwUi_getLocalObjStateColor(myDomain, myObj, State, color);
	if(!FSMBusy)
  {
   actionFilter = fwFsmUi_getActionFilter(myDomain, myObj);
		fwUi_getLocalObjStateActions(myDomain, myObj, State, actions, visis, actionFilter);
//DebugTN("fwUi_show_mode",myDomain, myObj, State, actions, visis, actionFilter);
  }
	else
	{
		dynAppend(actions,"AbortCommand");
		dynAppend(visis, 1);
		dynAppend(actions,"RestartFSM");
		dynAppend(visis, 2);
//		dynAppend(actions,"OpenDEN");
//		dynAppend(visis, 2);
	}
	if((!dynlen(actions)) && (State == "DEAD"))
	{
		dynAppend(actions,"RestartFSM");
		dynAppend(visis, 2);
   if(isLHCb())
   {
		  dynAppend(actions,"OpenDEN");
		  dynAppend(visis, 2);
   }
		force_operate = 1;
	}
	AccessControlOperator = fwFsmUi_getOperatorAccess(myDomain, myObj);
	AccessControlExpert = fwFsmUi_getExpertAccess(myDomain, myObj);
//DebugTN("fwUi_show_mode1",myDomain, myObj, State, actions, visis, actionFilter);
//DebugN("show_mode", myDomain, myObj, State, color, bits, actions, visis);
//DebugTN("show_mode", myDomain, myObj, State, color, AccessControlOperator, AccessControlExpert);
	if(ColorWidget != "none")
	{
		if( (getBit(bits, FwUseStatesBit)) && (!getBit(bits, FwSendCommandsBit)) &&
			  (!getBit(bits, FwCUFreeBit)))
			setValue(ColorWidget,"backCol",color);
		else if( (getBit(bits, FwFreeBit)) || (!getBit(bits, FwUseStatesBit)) )
			setValue(ColorWidget,"backCol","_3DFace");
		else
			setValue(ColorWidget,"backCol",color);
	}
	if(ActionsWidget == "none")
		return;
  if(fwFsm_isDU(myDomain, myObj))
  {
    	operate = (
		 (getBit(bits, FwOwnerBit) || ((!getBit(bits, FwExclusiveBit)) && (!getBit(bits, FwFreeBit)))) &&
/*		 (getBit(bits, FwUseStatesBit) || (getBit(bits, FwSendCommandsBit))) &&*/
		 Operateable && AccessControlOperator);
  }
  else
  {
    	operate = (
		 (getBit(bits, FwOwnerBit) || ((!getBit(bits, FwExclusiveBit)) && (!getBit(bits, FwFreeBit)))) &&
		 (getBit(bits, FwUseStatesBit) || (getBit(bits, FwSendCommandsBit))) &&
		 Operateable && AccessControlOperator);
  }
//DebugTN("smiButton",myDomain,myObj, bits, Operateable, AccessControlOperator, operate); 
	setValue(ActionsWidget,"removeItem","");
//DebugN(actions);
	for( i = 0; i < dynlen(actions) ; i++)
	{
		oper = operate;
		if(force_operate)
			oper = 1;
   if(actions[i+1] == fwFsm_actionSeparator)
   {
		  setValue(ActionsWidget,"insertItem","",2,-1,i,"");
   }
   else
   {
		  setValue(ActionsWidget,"insertItem","",0,-1,i,actions[i+1]);
		  if((visis[i+1] == 2) && (!AccessControlExpert))
		  	oper = 0;
//DebugN("enabling",i, myDomain, myObj, State, actions[i+1], oper);
		  setValue(ActionsWidget,"enableItem",i,oper);
   }
	}
//DebugTN("***************** End ********** Show State/Busy", myDomain, myObj);
}

fwFsmUi_getexecutingDevices(string node, dyn_string &devices, dyn_string &domains)
{
	dyn_string children;
	dyn_int children_types;
	int i, cu = 0;
	string action, parent;

	children = fwCU_getIncludedChildren(children_types, node);
	for(i = 1; i <= dynlen(children); i++)
	{
		if(children_types[i] == 2)
		{
			if(!fwFsm_isDomain(node))
			{
				cu = 0;
				while(!cu)
				{
					parent = fwCU_getParent(cu, node);
					if(parent == "")
						break;
				}
				if(cu)
					node = parent;
			}
			fwUi_getExecutingAction(node, children[i], action);
			if(action != "")
			{
				dynAppend(devices,children[i]);
				if(!dynContains(domains, node))
					dynAppend(domains, node);
			}
		}
		else
		{
			fwFsmUi_getexecutingDevices(children[i], devices, domains);

		}	
	}
}

fwFsmUi_abort(string domain, string obj)
{
string node, parent, child, sys;
dyn_string devices, domains;
int i;

	node = obj;
//DebugN("Aborting", domain, obj);
	if(domain != obj)
	{
		if(fwFsm_isAssociated(obj))
		{
			parent = fwFsm_getAssociatedDomain(obj);
			child = fwFsm_getAssociatedObj(obj);
			if(parent == child)
				node = child;
		}
		else
			node = domain/*+"::"+obj*/;
	}
	fwFsmUi_getexecutingDevices(node, devices, domains);
//DebugN(node, devices, domains);
	for(i = 1; i <= dynlen(domains); i++)
	{
		fwUi_getDomainSys(domains[i], sys);
		strreplace(sys,":","");
//DebugTN("Restarting Devices of "+ domains[i] +" on System: "+sys);
   if(sys != "")
   {
		  fwUi_report("Restarting Devices of "+ domains[i] +" on System: "+sys);
		  fwFsm_restartDomainDevices(domains[i], sys);
   }
   else
   {
	   fwUi_report("Can not Restart Devices of "+ domains[i] +" - PVSS System down?");
   }
	} 
}

fwFsmUi_restartFSM(string domain, string obj)
{
	string node, sys;

	if(fwFsm_isCU(domain, obj))
		node = obj;
	else
		node = domain;
//DebugN(domain, obj);
	if(domain != obj)
	{
		if(fwFsm_isAssociated(obj))
			node = fwFsm_getAssociatedDomain(obj);
	}
	fwUi_getDomainSys(node, sys);
	strreplace(sys,":","");
//DebugTN("Restarting FSM Tree "+ node +" on System: "+sys);
  if(sys != "")
  {
	  fwUi_report("Restarting FSM Tree "+ node +" on System: "+sys);
	  fwFsm_restartTreeDomains(node, sys);
  }
  else
  {
	  fwUi_report("Can not Restart FSM Tree "+ node +" - PVSS System down?");
  }
}

fwFsmUi_openDEN(string domain, string obj)
{
	string node, sys, host;
  int daPort, evPort;

	if(fwFsm_isCU(domain, obj))
		node = obj;
	else
		node = domain;
//DebugN(domain, obj);
	if(domain != obj)
	{
		if(fwFsm_isAssociated(obj))
			node = fwFsm_getAssociatedDomain(obj);
	}
	fwUi_getDomainSys(node, sys);
  fwFsmUi_getProjHostPorts(sys, host, daPort, evPort);
//	strreplace(sys,":","");
//DebugTN("Restarting FSM Tree "+ node +" on System: "+sys);
  if(sys != "")
  {
	  fwUi_report("Opening Device Editor Navigator on System: "+sys+" (host: "+host+")");
	  fwFsmUi_startDEN(host, daPort, evPort);
  }
  else
  {
	  fwUi_report("Can not Open Device Editor Navigator for "+ node +" - PVSS System down?");
  }
}

fwFsmUi_getProjHostPorts(string sys, string &host, int &daPort, int &evPort)
{
  string proj, unDist;
  dyn_string items;
  int num;
  int ret;
  dyn_dyn_string  ddsResult;
  int port, i;
  
  proj = sys;
  strreplace(proj,":","");
//DebugTN("getProjHostPorts",sys, proj);
  if(proj == "")
  {
    paGetProjHostPort(proj, host, port);
//DebugTN("getProjHostPorts/paGetProjHostPort",sys, proj, host, port);
  }
  else
  {
    dpGet("_unDistributedControl_"+proj+".config",unDist);
    items = strsplit(unDist,";");
    host = items[1];
    num = items[3];
    port = (num+100)*100;
//    ret = pmon_query("##MGRLIST:LIST", host, port, ddsResult, FALSE, TRUE);    
    ret = pmon_query("##PROJECT:", host, port, ddsResult, FALSE, TRUE);    
//DebugTN("getProjHostPorts/pmon_query",sys, proj, host, port, ddsResult);
//DebugTN("getProjHostPort", sys, items, host, port, ddsResult);
    if(!dynlen(ddsResult))
    {
      port = 4999;
//      ret = pmon_query("##MGRLIST:LIST", host, port, ddsResult, FALSE, TRUE);    
      ret = pmon_query("##PROJECT:", host, port, ddsResult, FALSE, TRUE);    
//DebugTN("getProjHostPorts/pmon_query1",sys, proj, host, port, ddsResult);
//DebugTN("getProjHostPort", sys, items, host, port, ddsResult);
    }
  }
  if(port != 4999)
  {
    daPort = port+1;
    evPort = port+2;
  }
  else
  {
    daPort = 4897;
    evPort = 4998;
  }
}

fwFsmUi_startDEN(string host, int daPort, int evPort)
{
  string dist, panel, projConfig;
  
  dist = "-event "+host+":"+evPort+" -data "+host+":"+daPort;
  panel = "-p fwDeviceEditorNavigator/fwDeviceEditorNavigator.pnl";
  if(strpos(PROJ,"CentralShortcutProject") == 0)
  {
    projConfig = "-proj "+PROJ+" +config "+PROJ_PATH+"/config/config";
  }
  else
  {
    projConfig = "-proj "+PROJ;
  }
  if (_UNIX)
  {
    system(PVSS_BIN_PATH+"PVSS00ui"+" "+projConfig+" "+dist+" "+panel+" -menuBar -iconBar&");
    DebugN(PVSS_BIN_PATH+"PVSS00ui"+" "+projConfig+" "+dist+" "+panel+" -menuBar -iconBar&");
  }
  else
  {
    system("start /B "+PVSS_BIN_PATH+"PVSS00ui"+" "+projConfig+" "+dist+" "+panel+" -menuBar -iconBar");
    DebugN("start /B "+PVSS_BIN_PATH+"PVSS00ui"+" "+projConfig+" "+dist+" "+panel+" -menuBar -iconBar");
  }
}
//fwFsmUi_sendObjButtonAction: 
/**  Send an action from a widget (CascadeButton) to an FSM object.
Can be used in reference panels of the family of the ones used with fwFsmUi_addObjXXX (fwFsmObj.pnl)
Can be called in the "EventClick" of the CacadeButton showing the object state (see above). 

Usage: JCOP framework internal, public

PVSS manager usage: VISION, CTRL

      @param domain: The node name (CU) in this reference panel (normally $domain).
      @param obj: The object name (CU/LU/DU) (normally $obj).
      @param id: The action id (Normally a parameter to the "EventClick" of the "CascadeButton").
      @param actionsWidget: The widget showing the list of actions: "" (default) = current widget.
*/
fwFsmUi_sendObjButtonAction(string domain, string obj, int id, string actionsWidget = "")
{
string cmd, state, type;
dyn_string pars;
int x, y, i, pos;
dyn_string items;
string par, value, val_type, sys;
int ask_user = 0, user_ok;

	getValue(actionsWidget, "textItem", id, cmd);
	if(cmd == "AbortCommand")
	{
//DebugN("Abort", domain, obj, cmd);
		fwFsmUi_abort(domain, obj);
		return;
	}
	else if(cmd == "RestartFSM")
	{
//DebugN("Restart", domain, obj, cmd);
		fwFsmUi_restartFSM(domain, obj);
		return;
	}
	else if(cmd == "OpenDEN")
	{
//DebugN("Restart", domain, obj, cmd);
		fwFsmUi_openDEN(domain, obj);
		return;
	}
	fwUi_getCurrentState(domain, obj, state);
  if(isFunctionDefined("fwFsmUser_interceptCommand"))
  {
    user_ok = fwFsmUser_interceptCommand(domain, obj, state, cmd);
    if(!user_ok)
      return;
  }
	fwFsm_getObjectType(domain+"::"+obj, type);
	fwUi_getDomainSys(domain, sys);
	fwFsm_readObjectActionParameters(sys+type, state, cmd, pars);
	if(dynlen(pars))
	{
		getValue(actionsWidget,"position",x,y);
		for(i = 1; i <= dynlen(pars); i++)
		{
			items = strsplit(pars[i]," ");
			par = items[2];
			val_type = items[1];
			value = "";
			if(dynlen(items) > 2)
			{		
				value = items[4];
				if((pos = strpos(value,"\"")) == 0)
				{
					value = substr(value,1,strlen(value)-2);
				}
			}
			if(strreplace(value, "$dp=", "") == 0)
			{
				ask_user = 1;
			}
			else
			{
				strreplace(value,"$domain",domain);
				strreplace(value,"$obj",obj);
				if(dpExists(value))
					dpGet(value, value);
				fwFsmUi_addParameter(cmd, par, val_type, value);
			}
		}
		if(ask_user)
			ChildPanelOn("fwFSM/ui/fwFsmParams.pnl","Params",
				makeDynString(sys+type, state, cmd, domain, obj), x+25, y);
		else
		{
			fwUi_sendCommand(domain, obj, cmd);
		}
	}
	else
		fwUi_sendCommand(domain, obj, cmd);
}


fwFsmUi_addParameter(string &cmd, string param, string type, string value, int escape = 1)
{
	cmd += "/"+param;
	switch(type)
	{
		case "string":
			cmd += "(S)";
			break;
		case "int":
			cmd += "(I)";
			break;
		case "float":
			cmd += "(F)";
			break;
	}
	if(escape)
	{
		value = _fwUi_escape(value);
	}
	cmd += "="+value;
}

//fwFsmUi_connectLock: 
/**  Connect a display widget (Button for example) to state changes of an FSM object mode, either control, logical, or device units
Can be used in reference panels of the family of the ones used with fwFsmUi_addObjXXX (fwSmiObj.pnl)
Can be called in the "EventInitialize" of any button or widget in the reference panel. 

Usage: JCOP framework internal, public

PVSS manager usage: VISION, CTRL

      @param domain: The node name (CU) in this reference panel (normally $domain).
      @param obj: The object name (CU/LU/DU) (normally $obj).
      @param isCU: (optional) Flag for control units, default: false
*/

fwFsmUi_connectLock(string domain, string obj, bool isCU = true, string part = "")
{
 int ret;
 string cu;
	myDomain = domain;
	myObj = obj;
//DebugN("Connecting Lock", domain, obj);
	if (isCU)
 {
		ret = fwFsmUi_connectModeBits("_fwFsmUi_show_it", domain, obj, 0);
   if(!ret)
   {
//DebugN("Connected Lock failed", domain, obj, ret);
     cu = fwUi_getModeObj(domain, obj);
     fwUi_connectCurrentState("_fwFsmUi_show_it", domain, cu+"_FWM");
		  ret = fwFsmUi_connectModeBits("_fwFsmUi_show_it", domain, obj, 1);
     fwUi_disconnectCurrentState("_fwFsmUi_show_it", domain, cu+"_FWM");
   }
  }
	else 
		ret = fwFsmUi_connectModeBits("_fwFsmUi_dev_show_it", domain, obj, 1, part);
//DebugN("Connected Lock", domain, obj, ret);
}

_fwFsmUi_show_it(string dp, string val)
{
	string color;
	dyn_string actions;
	int i, index, locknum;
	bit32 statusBits;
	string cu, state, toolTip, owner, user, tooltipState;
	int enabled;

//DebugTN("*** fwUi_show_mode Lock Starting",myDomain, myObj);
	if(!myDelaying)
	{
		myDelaying = 1;
		delay(0, 500);
		myDelaying = 0;
	}
	else
	{
//DebugTN("fwUi_show_mode Lock Returning!",myDomain, myObj);
		return;
	}
	statusBits = fwFsmUi_getOwnModeBits();

  cu = fwUi_getModeObj(myDomain, myObj);
	fwUi_checkOwnership(cu, enabled, owner);
	state = fwUi_getCUMode(myDomain, myObj);
	tooltipState = state;
	if(tooltipState == "ExcludedPerm")
		tooltipState = "Excluded (not propagated)";
	if(tooltipState == "LockedOutPerm")
		tooltipState = "LockedOut (not propagated)";
    	toolTip = "Click to see control options.\nMode: "+tooltipState;
//    	if (getBit(statusBits,FwFreeBit)) toolTip += "\nIs free";
//DebugN("ShowIt lock", myDomain, myObj, state, statusBits);
	if(owner != "")
	{
		user = fwUi_getManagerIdInfo(owner);
		toolTip += "\nOwner: "+owner;
		toolTip += "\nUser: "+user;
	    	if (!getBit(statusBits,FwExclusiveBit)) toolTip += "\nIs Shared";
    		if (getBit(statusBits,FwIncompleteDeadBit)) toolTip += "\nHas DEAD child(ren)";
    		if (getBit(statusBits,FwIncompleteBit)) toolTip += "\nHas Excluded child(ren)";
    		if (getBit(statusBits,FwIncompleteDevBit)) toolTip += "\nHas Disabled child(ren)";
	}
	locknum = 0;
	if(statusBits == 0)
	{
		if((state == "LockedOut") || (state == "LockedOutPerm"))
			locknum = 7;
		else
			locknum = 5;
	}
	else if(getBit(statusBits,FwOwnerBit))
	{
		if(getBit(statusBits,FwExclusiveBit))
			locknum = 1;
		else
			locknum = 2;
	}
	else
	{
		if(!getBit(statusBits,FwFreeBit))
		{
			if((state == "LockedOut") || (state == "LockedOutPerm"))
			{
				if(getBit(statusBits,FwExclusiveBit))
					locknum = 9;
				else
					locknum = 8;
			}
			else
			{
				if(getBit(statusBits,FwExclusiveBit))
					locknum = 4;
				else
					locknum = 3;
			}
		}
		else
		{
//			if((!getBit(statusBits,FwUseStatesBit))&&(!getBit(statusBits,FwUseStatesBit)))
			if(!getBit(statusBits,FwSendCommandsBit))
			{
				if((state == "LockedOut") || (state == "LockedOutPerm"))
					locknum = 7;
				else
					locknum = 5;
			}
			else
     {
				if((state == "LockedOut") || (state == "LockedOutPerm"))
					locknum = 7;
				else if((state == "Excluded") || (state == "ExcludedPerm"))
					locknum = 5;
      else
				  locknum = 6;
     }
		}
	}
//DebugN(myDomain, myObj, statusBits, locknum, state);
	if(locknum)
	{
		_fwFsmUi_changeLayer(locknum, statusBits, state);
		setValue("lock"+locknum,"toolTipText",toolTip);
	}
}

_fwFsmUi_changeLayer(int num, bit32 statusBits, string state)
{
	int i;

	for(i = 1; i <= 9; i++)	
		setValue("lock"+i,"visible",0);
	if (num) 
	{
		setValue("lock"+num,"visible",1);
		if((num < 5) && (state != "Excluded") && (state != "LockedOut") && (state != "LockedOutPerm") && (state != "DEAD"))
		{
/*
			if(getBit(statusBits,FwCompleteBit))
				setValue("lock"+num,"backCol","_3DFace");
			else
				setValue("lock"+num,"backCol","FwModeTreeIncomplete");
*/
			if (getBit(statusBits,FwIncompleteDeadBit))
				setValue("lock"+num,"backCol","FwStateAttention3");
			else if (getBit(statusBits,FwIncompleteBit))
				setValue("lock"+num,"backCol","FwStateAttention2");
			else if (getBit(statusBits,FwIncompleteDevBit))
				setValue("lock"+num,"backCol","FwStateAttention1");
			else 
				setValue("lock"+num,"backCol","_3DFace");
		}
		else 
			setValue("lock"+num,"backCol","_3DFace");
	}
}

_fwFsmUi_dev_show_it()
{
	string color;
	dyn_string actions;
	int i, index;
	bit32 statusBits;

//DebugTN("*** fwUi_show_mode Lock Starting",myDomain, myObj);
	if(!myDelaying)
	{
		myDelaying = 1;
		delay(0, 500);
		myDelaying = 0;
	}
	else
	{
//DebugTN("fwUi_show_mode Lock Returning!",myDomain, myObj);
		return;
	}
	statusBits = fwFsmUi_getOwnModeBits();
	if (getBit(statusBits,FwOwnerBit))
	{
		if (getBit(statusBits,FwExclusiveBit))
			_fwFsmUi_changeDeviceLayer(1, statusBits);
		else 
			_fwFsmUi_changeDeviceLayer(2, statusBits);
	}
	else 
	{
		if(!getBit(statusBits,FwFreeBit))
		{
			if (getBit(statusBits,FwExclusiveBit))
				_fwFsmUi_changeDeviceLayer(4, statusBits);
			else 
				_fwFsmUi_changeDeviceLayer(3, statusBits);
		}
		else 
			_fwFsmUi_changeDeviceLayer(5, statusBits);
	}
}

_fwFsmUi_changeDeviceLayer(int num, bit32 statusBits)
{
string widget;

	setValue("disabled","visible",0);
	setValue("enabled","visible",0);
	setValue("disabled_grey","visible",0);
	setValue("enabled_grey","visible",0);
	if((num == 1) || (num == 2) || (num == 3))
	{
		if(getBit(statusBits,FwSendCommandsBit))
		{
			setValue("enabled","visible",1);
			widget = "enabled";
		}
		else
		{
			setValue("disabled","visible",1);
		}
	}
	else
	{
		if(getBit(statusBits,FwSendCommandsBit))
		{
			setValue("enabled_grey","visible",1);
			widget = "enabled_grey";
		}
		else 
		{
			setValue("disabled_grey","visible",1);
		}
	}
	if(getBit(statusBits,FwIncompleteDevBit))
	{
		if((num < 5) && (widget != ""))
			setValue(widget,"backCol","FwStateAttention1");
		else
			setValue(widget,"backCol","_3DFace");
	}
	else
		setValue(widget,"backCol","_3DFace");
}

//fwFsmUi_changeMode: 
/**  Send a mode change to FSM object.
Can be used in reference panels of the family of the ones used with fwFsmUi_addObjXXX (fwFsmObj.pnl)
Can be called in the "EventClick" of the Button showing the object mode (see above). 

Usage: JCOP framework internal, public

PVSS manager usage: VISION, CTRL

      @param domain: The node name (CU) in this reference panel (normally $domain).
      @param obj: The object name (CU/LU/DU) (normally $obj).
      @param isCU: True if the object is a CU (default=true).
      @param widget: The widget showing the list of modes: "" (default) = current widget.

*/

fwFsmUi_changeMode(string domain, string obj, bool isCU = true, string widget="", string part = "")
{
	string mode;
	int x,y;
	dyn_float res;
	dyn_string ret;
	string error, msg, report, report1;
	int i, pos, view_only, done = 0, show_it = 0;
	dyn_string children;
	dyn_int types;
  int modes_open = 0;
  dyn_string modules;
  string module;
  
  modules = getVisionNames();
  for(i = 1; i <= dynlen(modules); i++)
  {
    if(isPanelOpen("Modes",modules[i]))
    {
      modes_open = 1;
      module = modules[i];
      break;
    }
  }
//DebugN("Mode", modules, modes_open, FwFSMUi_ModePanelBusy);
//	if (isPanelOpen("Modes"))
  if(modes_open)
  {
    if(!FwFSMUi_ModePanelBusy)
    {
//  	  PanelOffPanel("Modes");
      PanelOffModule("Modes",module);
//DebugN("panel Off Modes");
    }
    return;
	}
//	getValue("AccessControl","text", view_only);
	getValue(widget, "position", x, y);
//	ChildPanelOnReturn("fwFSM/ui/fwFsmModes.pnl","Modes",
//			makeDynString("$domain:"+$domain, "$obj:"+$obj, "$access:"+view_only), 
//			x+25, y+10, res, ret);
//	DebugN("changeMode of "+obj);
	string panelName
		= isCU ? "fwFSM/ui/fwFsmModes.pnl" : "fwFSM/ui/fwFsmDevModes.pnl";
	ChildPanelOnReturn(panelName, "Modes",
		makeDynString("$domain:"+domain, "$obj:"+obj, "$part:"+part),
		x+25, y+10, res, ret);
	children = fwCU_getChildren(types,domain);
//DebugN("Modes returned", ret);
	for(i = 1; i <= dynlen(ret); i++)
	{
		error = ret[i];
		if((pos = strpos(error," - ")) >= 0)
		{
			msg = substr(error, pos+3);
			fwUi_report(msg);
			report += msg+"\n";
			show_it = 1;
		}
		else
		{
     string error_part;
     error_part = error;
     if((pos = strpos(error," (")) >= 0)
       error_part = substr(error,0,pos);
			if(!done)
			{
				if(!dynContains(children, error_part))
				{ 
					report1 += "LockedOut Nodes (below this level):\n";
					show_it = 1;
					done = 1;
				}
			}
			if(!dynContains(children, error_part))
				report1 += "    "+error+"\n";
		}
	}
	if(isFunctionDefined("fwFsmUser_nodeAction"))
		fwFsmUser_nodeAction(domain, fwFsm_getAssociatedObj(obj));
	if(show_it)
	{	
		fwUi_uninformUser();
		fwUi_informUser(fwFsm_getAssociatedObj(obj)+" Action Report:", 100, 100, "Dismiss", report, report1);
	}
	FwFSMUi_ModePanelBusy = 0;
}

fwFsmUi_closeModeDescription()
{
  if(!FwFSMUi_ModePanelBusy)
  	PanelOffPanel("Modes");
  PanelOffPanel("Description");
}

//fwFsmUi_setDisallowedOperationStates: 
/**  Prevent the user to change operation mode (Include, Exclude, etc) when in a certain set of states.
Can be used at any time to define a list of object types and a list of states. If an object of the chosen
type is in the chosen state the object can not be excluded. For example an object of type: DAQ can not
be Excluded (or Included) while it is in state: RUNNING.  

Usage: JCOP framework internal, public

PVSS manager usage: VISION, CTRL

      @param types: A list of Object Types.
      @param states: A list of States (one State per Object Types).

*/
fwFsmUi_setDisallowedOperationStates(dyn_string types, dyn_string states)
{
dyn_string list;
int i, done = 0;

	dpGet("ToDo.disallowedOperationStates", list);
	for(i = 1; i <= dynlen(types); i++)
	{
		if(!dynContains(list, types[i]+"|"+states[i]))
		{
			dynAppend(list, types[i]+"|"+states[i]);
			done = 1;
		}
	}
	if(done)
		dpSet("ToDo.disallowedOperationStates", list);

}

//fwFsmUi_setDisallowedOperationsForStates: 
/**  Prevent the user to change operation mode (Include, Exclude, etc) when in a certain set of states.
Can be used at any time to define a list of object types and a list of states. If an object of the chosen
type is in the chosen state the object can not be excluded. For example an object of type: DAQ can not
be Excluded (or Included) while it is in state: RUNNING.  

Usage: JCOP framework internal, public

PVSS manager usage: VISION, CTRL

      @param types: A list of Object Types.
      @param states: A list of States per Object Type.

*/
fwFsmUi_setDisallowedOperationsForStates(dyn_string types, dyn_dyn_string states)
{
dyn_string list;
int i, j, done = 0;

	dpGet("ToDo.disallowedOperationStates", list);
	for(i = 1; i <= dynlen(types); i++)
	{
		for(j = 1; j <= dynlen(states[i]); j++)
		{
			if(!dynContains(list, types[i]+"|"+states[i][j]))
			{
				dynAppend(list, types[i]+"|"+states[i][j]);
				done = 1;
			}
		}
	}
	if(done)
		dpSet("ToDo.disallowedOperationStates", list);
}

dyn_string DisallowedOperationStates;
dyn_string DOTypes;
dyn_string DOStates;

int fwFsmUi_isOperationAllowed(string domain, string obj)
{
string type, state;
dyn_string items;
int i;
dyn_int indexes;

	fwFsm_getObjectType(domain+"::"+obj, type);
	fwUi_getCurrentState(domain, obj, state);
//DebugN("isOpAllowed", domain, obj, type, state);
	if(!dynlen(DisallowedOperationStates))
	{
		dpGet("ToDo.disallowedOperationStates", DisallowedOperationStates);
		for(i = 1; i <= dynlen(DisallowedOperationStates); i++)
		{
			items = strsplit(DisallowedOperationStates[i],"|");
			if(dynlen(items) == 2)
			{
				DOTypes[i] = items[1];
				DOStates[i] = items[2];
			}
		}
	}
	if(!dynContains(DisallowedOperationStates, type+"|"+state))
	{
		for(i = 1; i <= dynlen(DOTypes); i++)
		{
			if(patternMatch(DOTypes[i], type))
				dynAppend(indexes, i);
		}
		for(i = 1; i <= dynlen(indexes); i++)
		{
			if(DOStates[indexes[i]] == state)
				return 0;
		}
		return 1;
	}
	return 0;
}

int fwFsmUi_isParentOperationAllowed(string domain, string obj)
{
string type, state, action;
dyn_string items;
int i;
dyn_int indexes;

	fwFsm_getObjectType(domain+"::"+obj, type);
	fwUi_getExecutingAction(domain, domain, action);
	if(action == "")
		fwUi_getCurrentState(domain, domain, state);
	else
		state = "FwFsmBUSY";
//DebugN("isOpAllowed", domain, obj, type, state, action);
	
	if(!dynlen(DisallowedOperationStates))
	{
		dpGet("ToDo.disallowedOperationStates", DisallowedOperationStates);
		for(i = 1; i <= dynlen(DisallowedOperationStates); i++)
		{
			items = strsplit(DisallowedOperationStates[i],"|");
			if(dynlen(items) == 2)
			{
				DOTypes[i] = items[1];
				DOStates[i] = items[2];
			}
		}
	}
//DebugN("DisallowedOperationStates",DisallowedOperationStates, type+"|"+state)
	if(!dynContains(DisallowedOperationStates, type+"|"+state))
	{
		for(i = 1; i <= dynlen(DOTypes); i++)
		{
			if(patternMatch(DOTypes[i], type))
				dynAppend(indexes, i);
		}
		for(i = 1; i <= dynlen(indexes); i++)
		{
			if(DOStates[indexes[i]] == state)
				return 0;
		}
		return 1;
	}
	return 0;
}

fwFsmUi_changeIdentity(string id)
{
	fwUi_changeIdentity(id);
}

//fwFsmUi_setOpenOnSingleClick: 
/**  Set the opening of FSM panels to Single Click (default is Double Click).  

Usage: JCOP framework internal, public

PVSS manager usage: VISION, CTRL

      @param yes: 1 = yes, single click, 0 = no, double click.

*/
fwFsmUi_setOpenOnSingleClick(int yes)
{
	dpSet("ToDo.openOnSingleClick", yes);
}

fwFsmUi_ObjButtonClick(string domain, string obj, string parent = "")
{
	int openSingle;
	int cursor;

 	if(isFunctionDefined("fwFsmUser_nodeClicked"))
		fwFsmUser_nodeClicked(domain, obj, parent);
	else
	{
		dpGet("ToDo.openOnSingleClick", openSingle);
		if(openSingle)
		{
			cursor = this.cursor;
			this.cursor = CURSOR_WAIT;
			fwUi_showFsmObject(domain, obj, parent); 
			this.cursor = cursor;
		}
	}
}

fwFsmUi_ObjButtonDoubleClick(string domain, string obj, string parent = "")
{
	int openSingle;
        int cursor;

	if(isFunctionDefined("fwFsmUser_nodeDoubleClicked"))
		fwFsmUser_nodeDoubleClicked(domain, obj, parent);
	else
	{
		dpGet("ToDo.openOnSingleClick", openSingle);
		if(!openSingle)
		{
			cursor = this.cursor;
			this.cursor = CURSOR_WAIT;
			fwUi_showFsmObject(domain, obj, parent); 
			this.cursor = cursor;
		}
	}
}

fwFsmUi_ObjButtonRightClick(string domain, string obj, string parent = "")
{
	int x,y, answer;
	dyn_string lines;

	if(isFunctionDefined("fwFsmUser_nodeRightClicked"))
		fwFsmUser_nodeRightClicked(domain, obj, parent);
	else
	{
	  	getValue("","position",x,y);
		dynAppend(lines, "PUSH_BUTTON,Description, 1, 1");
  		if((domain != obj) && (parent == ""))
    			dynAppend(lines, "PUSH_BUTTON,Show Parent, 2, 1");

		dynAppend(lines, "SEPARATOR");
		dynAppend(lines, "PUSH_BUTTON,Restart FSM, 3, 1");
   if(isLHCb())
		  dynAppend(lines, "PUSH_BUTTON,Open DEN, 4, 1");
		popupMenu(lines, answer);
  		if(answer == 1)
  		{
    			ChildPanelOn("fwFSM/ui/fwFsmObjDescript.pnl","Description",
      			makeDynString($domain, $obj), x, y+25);
  		}
  		else if(answer == 2)
  		{
    			fwCU_view($domain);
  		}
  		else if(answer == 3)
  		{
 			fwFsmUi_restartFSM(domain, obj);
		 }
  		else if(answer == 4)
  		{
 			fwFsmUi_openDEN(domain, obj);
		 }
	}
}

fwFsmUi_view(string domain, string obj, int x = -1, int y = -1)
{
        int cursor;

	if(isFunctionDefined("fwFsmUser_nodeView"))
		fwFsmUser_nodeView(domain, obj, x, y);
	else
	{
		cursor = this.cursor;
		this.cursor = CURSOR_WAIT;
		fwUi_showFsmObject(domain, obj, "", x, y); 
		this.cursor = cursor;
	}
}

global dyn_int FwFsmUi_Locks;

fwFsmUi_modesPanelInit()
{
	bit32 statusBits;
	string modeObj, state, text;
	dyn_string modes, actions;
	int i, j, index, index1, n, show_n, viewOnly, opAllowed;

	setValue("title","text",$obj);
	state = fwUi_getCUMode($domain, $obj);
	
  if(state == "ExcludedPerm")
    state = "Excluded (not propagated)";
  else if(state == "LockedOutPerm")
    state = "LockedOut (not propagated)";

  setValue("state","text","Is "+state);
	
//	viewOnly = $access;
//	if(!viewOnly)
//        opAllowed = fwFsmUi_isOperationAllowed($domain, $obj);
//        opAllowed = fwFsmUi_isParentOperationAllowed($domain, $obj);
	if(fwFsmUi_getOperatorAccess($domain))
  {
//          DebugN("Operator access yes");
		modes = fwUi_getCUModeActions($domain, $obj);
  }
//DebugN("Op allowed", $domain, $obj, opAllowed, modes);
	n = dynlen(modes);
//	show_n = n;
//	if(n > 2)
//	{
//		n = 2;
//		show_n = 3;
//		setValue("more","visible",1);
//	}

//	setPanelSize( myModuleName(), myPanelName(), 0, 200, 74+32*show_n);
	for(i = 1; i <= 6; i++)
	{
		setValue("text"+i,"visible",0);
		for(j = 1; j <= 6; j++)
		{
			index = i*10+j;
			setValue("lock"+index,"visible",0);
		}
	}
//DebugN("modes", modes);
	show_n = n;
  if(dynlen(modes))
  {
    if(modes[1] == "Release")
    {
      if(n > 1)
	    {
	  	  n = 1;
	  	  show_n = 2;
	  	  setValue("more1","visible",1);
	    }
    }
    else
    {
	    if(n > 2)
	    {
	    	n = 2;
	    	show_n = 3;
	    	setValue("more","visible",1);
	    }
    }
  }
  if(index = dynContains(modes,"Exclude&LockOut"))
  {
    if(index1 = dynContains(modes,"Exclude"))
    {
       dynRemove(modes, index);
       dynInsertAt(modes,"Exclude&LockOut",index1+1);
    }
  }
  if(index = dynContains(modes,"ReleaseAll"))
  {
    if(index1 = dynContains(modes,"Take"))
    {
       dynRemove(modes, index);
       dynInsertAt(modes,"ReleaseAll",index1);
    }
  }
/*
  if(index = dynContains(modes,"ReleaseAll"))
  {
       dynRemove(modes, index);
       dynAppend(modes,"ReleaseAll");
  }
  if((index = dynContains(modes,"Take")) && (dynlen(modes) > 1))
  {
    modes[index] = "(Re)Take";
  }
*/
  dynClear(FwFsmUi_Locks);
	for(i = 1; i <= dynlen(modes); i++)
	{
		fwFsmUi_modesPanelEnableItem(i, modes[i]);
	}
	fwFsmUi_modesPanelShowItems(n, show_n);
}

fwFsmUi_modesPanelClose()
{
dyn_string errors, lockedOut;

  getValue("Message","items",errors);
  getValue("LockedOut","items",lockedOut);
//DebugTN("Done action", errors, lockedOut, $domain, $obj);
  dynAppend(errors, lockedOut);
  if(isFunctionDefined("fwFsmUser_commandAborted"))
    fwFsmUser_commandAborted($obj);
  PanelOffReturn(makeDynFloat(0),errors);
}

fwFsmUi_modesPanelClick()
{
string cmd, state;
dyn_string errors, lockedOut;
int i;

  FwFSMUi_ModePanelBusy = 1;
  for(i = 1; i <= 7; i++)
    setValue("text"+i,"enabled",0);
//        setValue("","enabled",0);
  getValue("","text",cmd);
  strreplace(cmd,"&&","&");
  strreplace(cmd,"(Re)","");
  if(cmd == "Don't Propagate")
  {
    state = fwUi_getCUMode($domain, $obj);
    if(strpos(state,"Excluded") == 0)
      cmd = "ExcludePerm";
    else
      cmd = "LockOutPerm";
  }
  fwFsmUi_setCUModeByName($domain, $obj, cmd);
  getValue("Message","items",errors);
  getValue("LockedOut","items",lockedOut);
//DebugN("Done action", errors, lockedOut);
  dynAppend(errors, lockedOut);
  for(i = 1; i <= 7; i++)
    setValue("text"+i,"enabled",1);
//    setValue("","enabled",1);
  PanelOffReturn(makeDynFloat(0),errors);
}

fwFsmUi_modesPanelMoreClick()
{
  this.visible = 0;
  fwFsmUi_modesPanelShowItems(0);
}

fwFsmUi_modesPanelRightClick()
{
string mode;
int answer, i, exclusivity;
dyn_string txt, modes;

  if(!fwFsmUi_getExpertAccess($domain))
    return;
  mode = fwUi_getCUMode($domain, $obj);
  if((mode == "Included") || (mode == "InLocal"))
  {
    modes = fwUi_getCUModeActions($domain, $obj);
    if ((dynContains(modes, "Exclude")) || (dynContains(modes, "Release")))
      return;
    dynAppend(txt,"PUSH_BUTTON, Expert Menu, 1, 1");
    popupMenu(txt,answer);
    if(answer == 1)
    {
      if(mode == "Included")
        dynAppend(modes, "ForceExclude");
      else if(mode == "InLocal")
        dynAppend(modes, "ForceRelease");
      fwUi_getExclusivity($obj, exclusivity);
      if(exclusivity == 1)
        dynAppend(modes, "ForceShare");
      else
        dynAppend(modes, "ForceExclusive");
      for(i = 1; i <= dynlen(modes); i++)
      {
        fwFsmUi_modesPanelEnableItem(i, modes[i]);
      }
      fwFsmUi_modesPanelShowItems(dynlen(modes));
    }
  }
  else if(mode == "Excluded")
  {
    modes = fwUi_getCUModeActions($domain, $obj);
    dynAppend(txt,"PUSH_BUTTON, Expert Menu, 1, 1");
    popupMenu(txt,answer);
    if(answer == 1)
    {
      dynAppend(modes, "ExcludePerm");
      for(i = 1; i <= dynlen(modes); i++)
      {
        fwFsmUi_modesPanelEnableItem(i, modes[i]);
      }
      fwFsmUi_modesPanelShowItems(dynlen(modes));
    }
  }        
  else if(mode == "ExcludedPerm")
  {
    modes = fwUi_getCUModeActions($domain, $obj);
    dynAppend(txt,"PUSH_BUTTON, Expert Menu, 1, 1");
    popupMenu(txt,answer);
    if(answer == 1)
    {
      dynAppend(modes, "Exclude");
      for(i = 1; i <= dynlen(modes); i++)
      {
        fwFsmUi_modesPanelEnableItem(i, modes[i]);
      }
      fwFsmUi_modesPanelShowItems(dynlen(modes));
    }
  }
  else if(mode == "LockedOut")
  {
    modes = fwUi_getCUModeActions($domain, $obj);
    dynAppend(txt,"PUSH_BUTTON, Expert Menu, 1, 1");
    popupMenu(txt,answer);
    if(answer == 1)
    {
      dynAppend(modes, "LockOutPerm");
      for(i = 1; i <= dynlen(modes); i++)
      {
        fwFsmUi_modesPanelEnableItem(i, modes[i]);
      }
      fwFsmUi_modesPanelShowItems(dynlen(modes));
    }
  }        
  else if(mode == "LockedOutPerm")
  {
    modes = fwUi_getCUModeActions($domain, $obj);
    dynAppend(txt,"PUSH_BUTTON, Expert Menu, 1, 1");
    popupMenu(txt,answer);
    if(answer == 1)
    {
      dynAppend(modes, "LockOut");
      for(i = 1; i <= dynlen(modes); i++)
      {
        fwFsmUi_modesPanelEnableItem(i, modes[i]);
      }
      fwFsmUi_modesPanelShowItems(dynlen(modes));
    }
  }
}

fwFsmUi_modesPanelShowItems(int n, int show_n = 0)
{
int i, lock_index;
int hor = 0, ver = 0;
int len;

//DebugTN("ShowItems", n, FwFsmUi_Locks);
  if(!n)
    n = dynlen(FwFsmUi_Locks);
  if(!show_n)
    show_n = n;
	for(i = 1; i <= n; i++)
	{
		setValue("text"+i,"visible",1);
		if(FwFsmUi_Locks[i])
		{
			lock_index = i*10+FwFsmUi_Locks[i];
			setValue("lock"+lock_index,"visible",1);
		}
	}
 panelSize("", hor, ver);
 len = 74+32*show_n;
 if(isFunctionDefined("fwFsmUser_progressBar"))
 {
   if(shapeExists("ProgressBar"))
     removeSymbol(myModuleName(), myPanelName(),"ProgressBar");
    delay(0, 100); 
    addSymbol(myModuleName(), myPanelName(),"fwFSM/ui/fwFsmModesProgress.pnl","ProgressBar",
            makeDynString(),20, len - 20, 0, 1, 1);
    len += 20;
  }
 	setPanelSize( myModuleName(), myPanelName(), 0, hor, len);
}

fwFsmUi_modesPanelEnableItem(int index, string text)
{
	int lock, lock_index;
	
	if((text == "Include") || (text == "Take") || (text == "(Re)Take") || (text == "UnLockOut&Include") || 
	   (text == "Exclusive") || (text == "Ignore"))
		lock = 1;
	else if(text == "Share")
		lock = 2;
	else if((text == "Exclude") || (text == "ExcludeAll") ||
	   (text == "Manual")  || (text == "Release") || (text == "ReleaseAll") ||
    (text == "ForceExclude") || (text == "ForceRelease") || (text == "UnLockOut") )
		 lock = 5;
  else if((text == "LockOut") || (text == "Exclude&LockOut"))
    lock = 6;
  else if(text == "ForceShare")
    lock = 3;
  else if(text == "ForceExclusive")
    lock = 4;
        
  strreplace(text,"&","&&");
  if(text == "ExcludePerm")
    text = "Don't Propagate";
  if(text == "LockOutPerm")
    text = "Don't Propagate";
	setValue("text"+index,"text",text);
//	setValue("text"+index,"visible",1);
	if(lock)
	{
		lock_index = index*10+lock;
//		setValue("lock"+lock_index,"visible",1);
	}
	FwFsmUi_Locks[index] = lock;
}

