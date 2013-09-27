/**@name SCRIPT: unDistributedControl.ctl

@author: Herve Milcent (LHC-IAS)

Creation Date: 12/07/2002

Modification History: 
	11/05/2006: Herve
		- optimization of dpSet
		
	06/07/2004: Herve
		- in unDistributedControl_init: 
			. remove the dist_read and replace it by unDistributedControl_getAllDeviceConfig
			. unDistributedControl DP are not created anymore, must be present
			. remove the redundancy
			. dpConnect to _Connection.Dist.ManNums and _DistManager.State.SystemNums
			

version 1.0

Purpose: 
This script implements the unDistributedControl component. The DistributedControl component checks if the 
remote PVSS systems defined are connected or not. The result of this check can be used to set 
the graphical characteristics of a component, send a message to the operator, send email, send an SMS, etc.

Usage: Public

PVSS manager usage: CTRL (WCCOACTRL)

Constraints:
	. global variable: the following variables are global to the script
		. g_unDistributedControl_localDpName: the data point name for the local system: string
		. g_unDistributedControl_dsSysName: the list of the remote system names: dyn_string
		. g_unDistributedControl_dsRemoteDpName: the list of data point name for the remote systems: dyn_string
		. g_DistConnected: is the local WCCILdist manager connected
	. constant:
		. c_unDistributedControl_dpType: the DistributedControl component data point type
		. c_unDistributedControl_dpName: the beginning of the data point name of the DistributedControl component
		. c_unDistributedControl_dpElementName: the data point element name of the DistributedControl component
	. data point type needed: _UnDistributedControl
	. data point: the following data point is needed per system names
		. _unDistributedControl_XXX_n: of type _UnDistributedControl, XXX is the remote system name (without :)
	. PVSS version: 3.0 
	. operating system: WXP, NT and Linux, but tested only under WXP and Linux.
	. distributed system: yes.
*/

// global declaration
global string g_unDistributedControl_localDpName;
global dyn_string g_unDistributedControl_dsRemoteSysName;
global dyn_int g_unDistributedControl_dsRemoteSysId;
global dyn_string g_unDistributedControl_dsRemoteDpName;
global dyn_bool g_unDistributedControl_dbRemoteState;
global bool g_unDistributedControl_bLocalState;
global dyn_bool g_unDistributedControl_dbIsConfigured;
global bool g_unDistributedControl_initialized;

global bool g_unDistributedControl_useMessageText;
global bool g_unDistributedControl_useUnicosBehaviour;

// end global declaration

//@{

// main
/**
Purpose:
This is the main of the script.

Usage: Public

PVSS manager usage: CTRL (WCCOACTRL)

Constraints:
	. no temporary data point, no ActiveX
	. PVSS version: 3.0 
	. operating system: WXP, NT and Linux, but tested only under WXP and Linux.
	. distributed system: yes.
*/
main()
{
	dyn_string exceptionInfo; // to hold any errors returned by the function

// initialize the select/deselect mechanism
	unDistributedControl_init(exceptionInfo);

// handle any error, send message to the MessageText component
	if(dynlen(exceptionInfo) > 0) {
		if(g_unDistributedControl_useMessageText)
			unMessageText_sendException("*", "*", "DistributedControl", "user", "*", exceptionInfo);

// handle any error uin case the send message failed
		if(dynlen(exceptionInfo) > 0) {
			DebugN(getCurrentTime(), exceptionInfo);
		}
	}
	else {
		if(g_unDistributedControl_useMessageText)
			unMessageText_send("*", "*", "DistributedControl", "user", "*", "EXPERTINFO", 
					getCatStr("unDistributedControl", "STARTED") , exceptionInfo);

// handle any error uin case the send message failed
		if(dynlen(exceptionInfo) > 0) {
			DebugN(getCurrentTime(), getCatStr("unDistributedControl", "STARTED"), exceptionInfo);
		}
	}
}

// unDistributedControl_init
/**
Purpose:
This function does the initialisation the DistributedControl component. 

The list of remote PVSS system is read from the config file via the dist_readConfig function. A dpConnect is done to 
the internal data point in order to check if the remote systems are connected or not. Redundancy is not supported.

	@param exceptionInfo: dyn_string, output, Details of any exceptions are returned here

Usage: Public

PVSS manager usage: CTRL (WCCOACTRL)

Constraints:
	. global variable: the following variables are global to the script
		. g_unDistributedControl_localDpName: the data point name for the local system: string
		. g_unDistributedControl_dsRemoteDpName: the list of data point name for the remote systems: dyn_string
		. g_unDistributedControl_dsRemoteSysName: the list of remote system name
		. g_unDistributedControl_localDpName: the local data point name
	. constant:
		. c_unDistributedControl_dpType: the DistributedControl component data point type
		. c_unDistributedControl_dpName: the beginning of the data point name of the DistributedControl component
		. c_unDistributedControl_dpElementName: the data point element name of the DistributedControl component
	. data point type needed: _UnDistributedControl
	. data point: the following data point is needed per system names, if it does not exist it is created at startup
		. _unDistributedControl_XXX_n: of type _UnDistributedControl, XXX is the remote system name (without :)
	. PVSS version: 3.0 
	. operating system: WXP, NT and Linux, but tested only under WXP and Linux.
	. distributed system: yes.
*/
unDistributedControl_init(dyn_string &exceptionInfo)
{
	dyn_string dsSystemName, dsHost;
	dyn_int diPortNumber, diSystemId;
	int len, i, pos, iRes;
	string sControlDpPattern, query, sDpName;
	
// check if messageText is available
	if(isFunctionDefined("unMessageText_sendException"))
		g_unDistributedControl_useMessageText = TRUE;
	else
		g_unDistributedControl_useMessageText = FALSE;
		
//	if(fwInstallation_checkInstalledComponent(c_unDistributedControl_requiredCoreName, c_unDistributedControl_requiredCoreVersion) >=0)
	if(isFunctionDefined("unTree_EventInitializeConfiguration"))
		g_unDistributedControl_useUnicosBehaviour = TRUE;
	else
		g_unDistributedControl_useUnicosBehaviour = FALSE;

// read all the config of type _UnDistributedControl
	unDistributedControl_getAllDeviceConfig(dsSystemName, diSystemId, dsHost, diPortNumber);
	g_unDistributedControl_initialized = false;
	
	len = dynlen(dsSystemName);	
	for(i=1;i<=len;i++) {
// fill the global variables
		if((dsSystemName[i]+":") != getSystemName()) {
			dynAppend(g_unDistributedControl_dsRemoteDpName, c_unDistributedControl_dpName+dsSystemName[i]);
			dynAppend(g_unDistributedControl_dsRemoteSysName, dsSystemName[i]);
			dynAppend(g_unDistributedControl_dsRemoteSysId, diSystemId[i]);
			dynAppend(g_unDistributedControl_dbRemoteState, false);
			dynAppend(g_unDistributedControl_dbIsConfigured, g_unDistributedControl_useUnicosBehaviour);
		}
	}	

// initialise the local dpname
	g_unDistributedControl_localDpName = c_unDistributedControl_dpName+ 
						substr(getSystemName(), 0, strpos(getSystemName(), ":"));

	if(!g_unDistributedControl_useUnicosBehaviour)
	{
		if(!dpExists(g_unDistributedControl_localDpName))
		{
			dpCreate(g_unDistributedControl_localDpName, c_unDistributedControl_dpType);
			unDistributedControl_setDeviceConfig(getSystemName(), getSystemId(), getHostname(), 0, exceptionInfo);
		}
	}

	g_unDistributedControl_bLocalState = false;

	if(!g_unDistributedControl_useUnicosBehaviour)
	{
//		while(!g_unDistributedControl_initialized)
//			delay(0,100);

		sControlDpPattern = "_unDistributedControl_*";
		query = "SELECT '_online.._value' FROM '{" + sControlDpPattern + c_unDistributedControl_dpConfigElementName + "}'";
		iRes = dpQueryConnectSingle("_unDistributedControl_handleNewSystems", FALSE,
																sControlDpPattern + c_unDistributedControl_dpConfigElementName, query);
		if(iRes == -1) {
			fwException_raise(exceptionInfo, "ERROR", "unDistributedControl_init: failed to establish monitoring of new Dist DPs","");
		}
	}

// end of initialisation, connect to the dist dps.
// no redundancy, so just connect to dist dp
	iRes = dpConnect("_unDistributedControl_callback", "_Connections.Dist.ManNums", "_DistManager.State.SystemNums");
	if(iRes == -1) {
		fwException_raise(exceptionInfo, "ERROR", "unDistributedControl_init: the Dist DP is not existing","");
	}
		
}


_unDistributedControl_handleNewSystems(string connectionId, dyn_dyn_anytype data)
{
	int i, pos, length;
	string dpName, systemName;
	dyn_mixed systemDetails;
		
	length = dynlen(data);
	for(i=2; i<=length; i++)
	{
		dpName = dpSubStr(data[i][1], DPSUB_DP);
		pos = dynContains(g_unDistributedControl_dsRemoteDpName, dpName);
//DebugN(pos, g_unDistributedControl_dsRemoteDpName, dpName);
		if(pos <= 0)
		{
			unDistributedControl_getDeviceConfig(dpName, systemName, systemDetails);
			if(dynlen(systemDetails) >= c_unDistributedControl_INDEX_SYS_ID)
			{		
			//include new system
				dynAppend(g_unDistributedControl_dsRemoteDpName, c_unDistributedControl_dpName+systemName);
				dynAppend(g_unDistributedControl_dsRemoteSysName, systemName);
				dynAppend(g_unDistributedControl_dsRemoteSysId, systemDetails[c_unDistributedControl_INDEX_SYS_ID]);
				dynAppend(g_unDistributedControl_dbRemoteState, false);
				dynAppend(g_unDistributedControl_dbIsConfigured, false);
			}		
		}
	}
}

// _unDistributedControl_callback
/**
Purpose:
This is the callback function called in the case of no redundant system. It sets the _unDistributedControl data point according to the state 
of the remote systems. 

localSystemIds contains the manager number of the local WCCILdist. No value means that the WCCILdist 
is not connected, therefore all the _unDistributedControl have to be set to false because there is no connection to the 
remote systems. 

remoteSystemIds contains the list of remote WCCILdist manager number connected and ready to the local WCCILdist, equivalent to 
remote system name because the WCCILdist manager number must be unique within the whole distributed system. 
getSystemId(remote systemName) returns the Id of the remote system, if the corresponding Id is in the remoteSystemIds 
then the _unDistributedControl is set to true, otherwise it is set to false.

	@param sConn: string, input, the _Connections.Dist.ManNums data point element
	@param localSystemIds: dyn_int, input, the value of _Connections.Dist.ManNums data point element
	@param sDistConnectionDp: string, input, the _DistManager.State.SystemNums data point element
	@param remoteSystemIds: dyn_int, input, the value of _DistConnections.Dist.ManNums data point element

Usage: Public

PVSS manager usage: CTRL (WCCOACTRL)

Constraints:
	. PVSS version: 3.0 
	. operating system: WXP, NT and Linux, but tested only under WXP and Linux.
	. distributed system: yes.
*/
_unDistributedControl_callback(string sConn, dyn_int localSystemIds, string sDistConnectionDp, dyn_int remoteSystemIds)
{
	bool localSystemConnected, remoteSystemConnected;
	int deviceSystemId, posId, i, len;
	string messageString;
	dyn_bool states;
	dyn_string attributes, exceptionInfo;

//DebugN("_unDistributedControl_callback", localSystemIds, remoteSystemIds);

	if(!g_unDistributedControl_useUnicosBehaviour)
		unDistributedControl_checkSystemList(remoteSystemIds, exceptionInfo);

	if(dynlen(localSystemIds) < 1) {
// local WCCILdist not connected  
// set all the system state dps to false
		len = dynlen(g_unDistributedControl_dsRemoteDpName);
		for(i=1;i<=len;i++) {
			messageString = getCatStr("unDistributedControl", "REMNOTCON")+ ": "+g_unDistributedControl_dsRemoteSysName[i];
			unDistributedControl_prepareChanges(g_unDistributedControl_dsRemoteDpName[i], FALSE,
								g_unDistributedControl_dbRemoteState[i], messageString, attributes, states, exceptionInfo);

			g_unDistributedControl_dbRemoteState[i] = false;
		}

// set the local system state to false
		localSystemConnected = FALSE;
	}
	else {
		len = dynlen(g_unDistributedControl_dsRemoteSysName);
// check which system among the defined one are connected, check in systemIds
		for(i=1;i<=len;i++) {
// get the systemId
			deviceSystemId = g_unDistributedControl_dsRemoteSysId[i];
// if the systemId is included, remote system connected and ready
			posId = dynContains(remoteSystemIds, deviceSystemId);
//DebugN(g_unDistributedControl_dsRemoteSysId, remoteSystemIds, posId);
			if(posId>0)
				remoteSystemConnected= TRUE;
			else
				remoteSystemConnected= FALSE;

			messageString = getCatStr("unDistributedControl", remoteSystemConnected?"REMCONOK":"REMNOTCON")
								+ ": "+g_unDistributedControl_dsRemoteSysName[i];

			unDistributedControl_prepareChanges(g_unDistributedControl_dsRemoteDpName[i], remoteSystemConnected,
								g_unDistributedControl_dbRemoteState[i], messageString, attributes, states, exceptionInfo);

			g_unDistributedControl_dbRemoteState[i] = remoteSystemConnected;
		}
// local WCCILdist connected
// set the local system state to true
		localSystemConnected = TRUE;
	}

	messageString = getCatStr("unDistributedControl", localSystemConnected?"LOCCONOK":"LOCNOTCON")
						+ ": "+g_unDistributedControl_localDpName;
	unDistributedControl_prepareChanges(g_unDistributedControl_localDpName, localSystemConnected,
						g_unDistributedControl_bLocalState, messageString, attributes, states, exceptionInfo);

	g_unDistributedControl_bLocalState = localSystemConnected;

	if(!g_unDistributedControl_initialized)
		g_unDistributedControl_initialized = true;
		
	unDistributedControl_setStates(attributes, states, exceptionInfo);

//DebugTN("end _unDistributedControl_callback", g_unDistributedControl_bLocalState, g_unDistributedControl_dbRemoteState);

// handle any error in case the send message failed
	if(dynlen(exceptionInfo) > 0) {
		DebugN(getCurrentTime(), messageString, exceptionInfo);
	}
}


unDistributedControl_prepareChanges(string dpName, bool isConnected, bool previousState, string messageString, dyn_string &attributes, dyn_bool &states, dyn_string &exceptionInfo)
{
//if uninitialised OR initialised and different to previous state
	if((!g_unDistributedControl_initialized) || (g_unDistributedControl_initialized && (isConnected != previousState)))
	{
//append to list of dps to set with new value
		dynAppend(attributes, dpName+c_unDistributedControl_dpElementName);
		dynAppend(states, isConnected);

//write a message to indicate the change
		if(g_unDistributedControl_useMessageText)
			unMessageText_send("*", "*", "DistributedControl", "user", "*", "ERROR", messageString, exceptionInfo);
		else
			DebugN(getCurrentTime(), messageString);
	}

}

unDistributedControl_setStates(dyn_string attributes, dyn_bool states, dyn_string &exceptionInfo)
{
//just do a dpSetWait if there are settings to be made, plus some error checking
	dyn_errClass errors;

	if(dynlen(attributes) > 0)
	{
//DebugN("Setting...", attributes, states);
		dpSetWait(attributes, states);
		errors = getLastError();
	    	if(dynlen(errors) > 0)
			fwException_raise(exceptionInfo, "ERROR", "unDistributedControl_setStates: Could not set the new connection states of the systems", "");
	}
}

unDistributedControl_checkSystemList(dyn_int remoteSystemIds, dyn_string &exceptionInfo)
{
	int i, pos, systemId, numberOfSystems, numberOfKnownSystems, numberOfMonitoredSystems;
	string systemName;
	dyn_mixed systemDetails;
	dyn_string systemNames;

	numberOfSystems = dynlen(remoteSystemIds);
	numberOfKnownSystems = dynlen(dynIntersect(remoteSystemIds, g_unDistributedControl_dsRemoteSysId));
	numberOfMonitoredSystems = dynlen(g_unDistributedControl_dbIsConfigured);

//if some systems do not have their configuration stored
	if(dynContains(g_unDistributedControl_dbIsConfigured, false))
	{	
		for(i=1; i<=numberOfMonitoredSystems; i++)
		{
			if(g_unDistributedControl_dbIsConfigured[i] == false)
			{
				systemId = getSystemId(g_unDistributedControl_dsRemoteSysName[i] + ":");
				if(dynContains(remoteSystemIds, systemId))
				{
//DebugN("Adding new system configuration for newly connected system", g_unDistributedControl_dsRemoteSysName[i]);
					g_unDistributedControl_dbIsConfigured[i] = true;		
					_unDistributedControl_getSystemDetails(g_unDistributedControl_dsRemoteSysName[i], systemDetails, exceptionInfo);
					unDistributedControl_setDeviceConfig(g_unDistributedControl_dsRemoteSysName[i],
																									systemDetails[c_unDistributedControl_INDEX_SYS_ID],
																									systemDetails[c_unDistributedControl_INDEX_HOST_NAME],
																									systemDetails[c_unDistributedControl_INDEX_PORT_NUM], exceptionInfo);
					g_unDistributedControl_dsRemoteSysId[i] = systemDetails[c_unDistributedControl_INDEX_SYS_ID];
				}
			}
		}
	}
	
//do a quick check to see if all systems are know, if so return
	if(numberOfSystems == numberOfKnownSystems)
		return;

	for(i=1; i<=numberOfSystems; i++)
	{
		if(dynContains(g_unDistributedControl_dsRemoteSysId, remoteSystemIds[i]) <= 0)
		{
			systemName = getSystemName(remoteSystemIds[i]);
			
			_unDistributedControl_includeNewSystem(systemName, exceptionInfo, FALSE);
			_unDistributedControl_getSystemDetails(systemName, systemDetails, exceptionInfo);
			unDistributedControl_setDeviceConfig(systemName, systemDetails[c_unDistributedControl_INDEX_SYS_ID],
																												systemDetails[c_unDistributedControl_INDEX_HOST_NAME],
																												systemDetails[c_unDistributedControl_INDEX_PORT_NUM], exceptionInfo);
			
			systemName = strrtrim(systemName, ":");

			dynAppend(g_unDistributedControl_dsRemoteDpName, c_unDistributedControl_dpName+systemName);
			dynAppend(g_unDistributedControl_dsRemoteSysName, systemName);
			dynAppend(g_unDistributedControl_dsRemoteSysId, systemDetails[c_unDistributedControl_INDEX_SYS_ID]);
			dynAppend(g_unDistributedControl_dbRemoteState, false);
			dynAppend(g_unDistributedControl_dbIsConfigured, true);
		}
	}
//DebugN(g_unDistributedControl_dsRemoteDpName, g_unDistributedControl_dsRemoteSysName, g_unDistributedControl_dsRemoteSysId);
}
//@}

