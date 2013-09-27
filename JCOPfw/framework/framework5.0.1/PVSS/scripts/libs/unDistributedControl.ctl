/**@name LIBRARY: unDistributedControl.ctl

@author: Herve Milcent (LHC-IAS)

Creation Date: 31/04/2002

Modification History: 
	06/07/2004: Herve
		- add unDistributedControl_getAllDeviceConfig: get the config of all the declared _UnDistribtuedControl
		- add unDistributedControl_setDeviceConfig: set the config of the _UnDistribtuedControl_systemName
		- add unDistributedControl_checkCreateDp: to check if the dp _unDistributedControl_XXX_n: of type _UnDistributedControl exists, 
				if not it creates it, remove the dpSet connected to false: so during the creation it is set to false, and anytime after 
				the connected state is set by the unDistributedControl script.

version 1.0

External Functions: 
	. unDistributedControl_register: to register a call back function to the unDistributedControl component
	. unDistributedControl_deregister: to deregister a call back function to the unDistributedControl component
	. unDistributedControl_isRemote: to check if a given PVSS system name is a remote system
	. unDistributedControl_isConnected: to check if the PVSS system is connected
	. unDistributedControl_checkCreateDp: to check if the dp _unDistributedControl_XXX_n: of type _UnDistributedControl exists, 
				if not it creates it.
	. unDistributedControl_getAllConfigDevice: get the config of all the declared _UnDistribtuedControl


Internal Functions: 
	
Purpose: 
This library contains functions for the unDistributedControl component. The DistributedControl component checks if the 
remote PVSS systems defined in the config file are connected or not. The result of this check can be used to set 
the graphical characteristics of a component, send a message to the operator, send email, send an SMS, etc.

Usage: Public

PVSS manager usage: CTRL (WCCOACTRL), UI 

Constraints:
	. constant: 
		. c_unDistributedControl_dpElementName: the data point element of the _unDistributedControl
	. data point type needed: _UnDistributedControl
	. data point: an instance of _UnDistributedControl: _unDistributedControl_xxx where xxx = system name 
	. PVSS version: 3.0 
	. operating system: Linux, NT and W2000, but tested only under W2000.
	. distributed system: yes.
*/
// contsant declaration
const string c_unDistributedControl_dpType = "_UnDistributedControl";
const string c_unDistributedControl_dpName = "_unDistributedControl_";
const string c_unDistributedControl_dpElementName=".connected";
const string c_unDistributedControl_dpConfigElementName=".config";
const string c_unDistributedControl_separator=";";
const string c_unDistributedControl_requiredCoreName="unCore";
const string c_unDistributedControl_requiredCoreVersion="3.6";

const unsigned c_unDistributedControl_INDEX_HOST_NAME=1;
const unsigned c_unDistributedControl_INDEX_PORT_NUM=2;
const unsigned c_unDistributedControl_INDEX_SYS_ID=3;

// end of constant declaration

//@{

// unDistributedControl_register
/**
Purpose:
to register a call back function to the unDistributedControl component. This function does a dpConnect of the 
sAdviseFunction call back function to the _unDistributedControl_xxx (xxx = system name of the remote PVSS system). 

In case of error, bResult is set to false and an exception is raised in exceptionInfo.

The call back function must be like:
CBFunc(string sDp, bool bConnected)
{
}
bConnected: true (the remote system is connected and synchronised)/false (the remote system is not connected)

it is recommended to do nothing if the bConnected is true. it is better to have another dpConnect function to other  
data. When a remote system is reconnected, any callback function to dp of the remot system will be called after the 
initialisation of the remote connection. Therefore the CBFunc will be called first and then any other call back 
function for the remote dp.

	@param sAdviseFunction: string, input, the name of the call back function
	@param bRes: bool, output, the result of the register call
	@param bConnected: bool, output, is the remote system connected
	@param sSystemName: string, input, the name of remote PVSS system
	@param exceptionInfo: dyn_string, output, Details of any exceptions are returned here

Usage: Public

PVSS manager usage: CTRL (WCCOACTRL), UI 

Constraints:
	. constant: 
		. c_unDistributedControl_dpElementName: the data point element of the _unDistributedControl
	. data point type needed: _UnDistributedControl
	. data point: an instance of _UnDistributedControl: _unDistributedControl_xxx where xxx = system name 
	. PVSS version: 3.0 
	. operating system: Linux, NT and W2000, but tested only under W2000.
	. distributed system: yes.
*/
unDistributedControl_register(string sAdviseFunction, bool &bRes, bool &bConnected, string sSystemName, dyn_string &exceptionInfo)
{
	string query, sDistributedControlDpName, sLocalControlDpName;
	int iRes;
		
	bRes = false;
	bConnected = false;

	if(sAdviseFunction == "") {
		fwException_raise(exceptionInfo, "ERROR", getCatStr("unDistributedControl", "LIBREGERR"),"");
		return;
	}
	
	sDistributedControlDpName = "_unDistributedControl_" + strrtrim(sSystemName, ":");

//	if(fwInstallation_checkInstalledComponent(c_unDistributedControl_requiredCoreName, c_unDistributedControl_requiredCoreVersion) < 0)
	if(!isFunctionDefined("unTree_EventInitializeConfiguration"))
	{
		if(!dpExists(sDistributedControlDpName))
			_unDistributedControl_includeNewSystem(sSystemName, exceptionInfo);
	}
	
	if(dpExists(sDistributedControlDpName)) {
		iRes = dpConnect(sAdviseFunction, sDistributedControlDpName+c_unDistributedControl_dpElementName);
		if(iRes == -1) {
			fwException_raise(exceptionInfo, 
				"ERROR", getCatStr("unDistributedControl", "LIBREGDPCONERR") + sAdviseFunction +", "+sDistributedControlDpName,"");
		}
		else {
			bRes = true;
			dpGet(sDistributedControlDpName+c_unDistributedControl_dpElementName, bConnected);
		}
	}
	else
		fwException_raise(exceptionInfo, 
				"ERROR", getCatStr("unDistributedControl", "LIBREGNODP") + sDistributedControlDpName,"");
}

// unDistributedControl_deregister
/**
Purpose:
to deregister a call back function to the unDistributedControl component. This function does a dpDisconnect of the 
sAdviseFunction call back function to the _unDistributedControl_xxx (xxx = system name of the remote PVSS system). 

	@param sAdviseFunction: string, input, the name of the call back function
	@param bRes: bool, output, the result of the register call
	@param bConnected: bool, output, is the remote system connected
	@param sSystemName: string, input, the name of remote PVSS system
	@param exceptionInfo: dyn_string, output, Details of any exceptions are returned here

Usage: Public

PVSS manager usage: CTRL (WCCOACTRL), UI 

Constraints:
	. constant: 
		. c_unDistributedControl_dpElementName: the data point element of the _unDistributedControl
	. data point type needed: _UnDistributedControl
	. data point: an instance of _UnDistributedControl: _unDistributedControl_xxx where xxx = system name 
	. PVSS version: 3.0 
	. operating system: Linux, NT and W2000, but tested only under W2000.
	. distributed system: yes.
*/
unDistributedControl_deregister(string sAdviseFunction, bool &bRes, bool &bConnected, string sSystemName, dyn_string &exceptionInfo)
{
	string sDistributedControlDpName;
	int iRes;
		
	bRes = false;
	bConnected = false;

	if(sAdviseFunction == "") {
		fwException_raise(exceptionInfo, "ERROR", getCatStr("unDistributedControl", "LIBDEREGERR"),"");
		return;
	}
	
	sDistributedControlDpName = "_unDistributedControl_" + strrtrim(sSystemName, ":");

	if(dpExists(sDistributedControlDpName)) {
		iRes = dpDisconnect(sAdviseFunction, sDistributedControlDpName+c_unDistributedControl_dpElementName);
		if(iRes == -1) {
			fwException_raise(exceptionInfo, 
				"ERROR", getCatStr("unDistributedControl", "LIBDEREGDPCONERR") + sAdviseFunction +", "+sDistributedControlDpName,"");
		}
	}
	else
		fwException_raise(exceptionInfo, 
				"ERROR", getCatStr("unDistributedControl", "LIBDEREGNODP") + sDistributedControlDpName,"");
}

// unDistributedControl_isRemote
/**
Purpose:
To check if a given PVSS system name is a remote system
This function returns true if the sSystemName is the local PVSS system, i.e.: if it is the system name (getSystemName()) of 
the caller of this function. Otherwise it returns false.

	@param isRemoteSystem: bool, output, is the PVSS system a remote system
	@param sSystemName: string, input, the name of remote PVSS system

Usage: Public

PVSS manager usage: CTRL (WCCOACTRL), UI 

Constraints:
	. PVSS version: 3.0 
	. operating system: Linux, NT and W2000, but tested only under W2000.
	. distributed system: yes.
*/
unDistributedControl_isRemote(bool &isRemoteSystem, string sSystemName)
{
	if(sSystemName == getSystemName()) 
		isRemoteSystem = false;
	else
		isRemoteSystem = true;
}

// unDistributedControl_isConnected
/**
Purpose:
to check if the PVSS system is connected. If the sSystemName is the local system (getSystemName()) is Connected is true.

	@param isConnected: bool, output, is the PVSS system connected
	@param sSystemName: string, input, the name of remote PVSS system

Usage: Public

PVSS manager usage: CTRL (WCCOACTRL), UI

Constraints:
	. PVSS version: 3.0 
	. operating system: Linux, NT and W2000, but tested only under W2000.
	. distributed system: yes.
*/
unDistributedControl_isConnected(bool &isConnected, string sSystemName)
{
	string sDistributedControlDpName;

	isConnected = false;
	
	if(sSystemName == getSystemName()) {
		isConnected = true;
	}
	else {
		sDistributedControlDpName = "_unDistributedControl_"+substr(sSystemName, 0, strpos(sSystemName, ":"));
		if(dpExists(sDistributedControlDpName)) {
			dpGet(sDistributedControlDpName+c_unDistributedControl_dpElementName, isConnected);
		}
	}
//	DebugN(sDistributedControlDpName, isConnected);
}

// unDistributedControl_getAllDeviceConfig
/**
Purpose:
get the config of all the declared _UnDistribtuedControl. empty field or 0 means default value.

	@param dsSystemName: dyn_string, output, list of all the PVSS systemName of the declared _UnDistribtuedControl
	@param diSystemId: dyn_int, output, list of all the PVSS system ID of the declared _UnDistribtuedControl
	@param dsHostName: dyn_string, output, list of all the hostname of the declared _UnDistribtuedControl
	@param diPortNumber: dyn_int, output, list of all the port number of the WCCILdist of the declared _UnDistribtuedControl

Usage: Public

PVSS manager usage: CTRL (WCCOACTRL), UI 

Constraints:
	. PVSS version: 3.0 
	. operating system: Linux, NT and W2000, but tested only under W2000.
	. distributed system: yes.
*/
unDistributedControl_getAllDeviceConfig(dyn_string &dsSystemName, dyn_int &diSystemId, dyn_string &dsHostName, dyn_int &diPortNumber)
{
	dyn_string dsDp = dpNames(getSystemName()+c_unDistributedControl_dpName+"*", c_unDistributedControl_dpType);
	int i, len;
	string systemName;
	dyn_mixed systemDetails;
	dyn_string l_dsSystemName, l_dsHostName;
	dyn_int l_diSystemId, l_diPortNumber;
	
	len = dynlen(dsDp);
	for(i=1;i<=len;i++) {
// correct system name
			unDistributedControl_getDeviceConfig(dsDp[i], systemName, systemDetails);
			if(dynlen(systemDetails) >= c_unDistributedControl_INDEX_SYS_ID)
			{
				dynAppend(l_dsSystemName, systemName);
				dynAppend(l_dsHostName, systemDetails[c_unDistributedControl_INDEX_HOST_NAME]);
				dynAppend(l_diPortNumber, systemDetails[c_unDistributedControl_INDEX_PORT_NUM]);
				dynAppend(l_diSystemId, systemDetails[c_unDistributedControl_INDEX_SYS_ID]);
			}
	}
	
	dsSystemName = l_dsSystemName;
	diSystemId = l_diSystemId;
	dsHostName = l_dsHostName;
	diPortNumber = l_diPortNumber;
}

unDistributedControl_getDeviceConfig(string sConfigDpName, string &sSystemName, dyn_mixed &dmSystemDetails)
{
	int pos;
	string dpName, sConfig;
	dyn_string dsSplit;
	
	pos = strpos(sConfigDpName, c_unDistributedControl_dpName);
	
	if(pos > -1) {
		dpGet(sConfigDpName+c_unDistributedControl_dpConfigElementName, sConfig);
		dmSystemDetails = strsplit(sConfig, c_unDistributedControl_separator);
		sSystemName = substr(sConfigDpName, pos+strlen(c_unDistributedControl_dpName), strlen(sConfigDpName));
	}
}


// unDistributedControl_setDeviceConfig
/**
Purpose:
set the config of all the _UnDistribtuedControl_systemName. empty field or 0 means default value.

	@param sSystemName: string, input, the PVSS systemName with or without : of the declared _UnDistribtuedControl
	@param iSystemId: int, input, the PVSS system ID of the declared _UnDistribtuedControl
	@param sHostName: string, input, the hostname of the declared _UnDistribtuedControl
	@param iPortNumber: int, input, the port number of the WCCILdist of the declared _UnDistribtuedControl
	@param exceptionInfo: dyn_string, output, the error is returned here

Usage: Public

PVSS manager usage: CTRL (WCCOACTRL), UI 

Constraints:
	. PVSS version: 3.0 
	. operating system: Linux, NT and W2000, but tested only under W2000.
	. distributed system: yes.
*/
unDistributedControl_setDeviceConfig(string sSystemName, int iSystemId, string sHostName, int iPortNumber, dyn_string &exceptionInfo)
{
	int pos;
	string systemName, hostName, sConfig, systemId, portNumber;
	
// remove the : if any	
	sSystemName = strrtrim(sSystemName, ":");

	if(dpExists(c_unDistributedControl_dpName+sSystemName)) {
		if(sHostName == "localhost")
			hostName = "";
		else
			hostName = sHostName;
		if(iPortNumber == 0)
			portNumber = "";
		else 
			portNumber = iPortNumber;
		if(iSystemId == 0)
			systemId = "";
		else 
			systemId = iSystemId;
		sConfig=hostName+c_unDistributedControl_separator+portNumber+c_unDistributedControl_separator+systemId+c_unDistributedControl_separator;

		dpSet(c_unDistributedControl_dpName+sSystemName+c_unDistributedControl_dpConfigElementName,sConfig);
	}
	else {
			fwException_raise(exceptionInfo, "ERROR", 
						"unDistributedControl_setDeviceConfig(): the remote system internal data point: "+sSystemName+" is not existing","");
	}
}

// unDistributedControl_checkCreateDp
/**
Purpose:
This function checks if the dp _unDistributedControl_XXX_n: of type _UnDistributedControl exists, if not it creates it.

	@param sDpName: string, input, the data point name
	@param exceptionInfo: dyn_string, output, Details of any exceptions are returned here

Usage: Public

PVSS manager usage: CTRL (WCCOACTRL)

Constraints:
	. constant:
		. c_unDistributedControl_dpType: the DistributedControl component data point type
	. data point type needed: _UnDistributedControl
	. PVSS version: 3.0 
	. operating system: W2000, NT and Linux, but tested only under W2000 and Linux.
	. distributed system: yes.
*/
unDistributedControl_checkCreateDp(string sDpName, dyn_string &exceptionInfo)
{
	bool bError = false;
	
	sDpName = strrtrim(sDpName, ":");

// if it is not existing creates it
	if(!dpExists(sDpName)) {
		dpCreate(sDpName, c_unDistributedControl_dpType);
// a second check is done after the creation to ensure that the data point is created (just in case of error)
// it is also a way to wait the creation which is asynchronous.
		if(!dpExists(sDpName)) {
			fwException_raise(exceptionInfo, "ERROR", 
						"unDistributedControl_checkCreateDp(): the data point: "+sDpName+" was not created","");
			bError = true;
		}
	}
}

_unDistributedControl_includeNewSystem(string systemName, dyn_string &exceptionInfo, bool triggerInclusion = TRUE)
{
	string messageString;
	dyn_mixed systemDetails;

	if(!dpExists(c_unDistributedControl_dpName+systemName))
		unDistributedControl_checkCreateDp(c_unDistributedControl_dpName+systemName, exceptionInfo);

	if(triggerInclusion)
		unDistributedControl_setDeviceConfig(systemName, 0, "", 0, exceptionInfo);		
}

_unDistributedControl_getSystemDetails(string systemName, dyn_mixed &systemDetails, dyn_string &exceptionInfo)
{
	int systemId;
	dyn_string hostNames;

	systemName = strrtrim(systemName, ":");
	systemId = getSystemId(systemName + ":");
	if(systemId < 0)
	{
		systemDetails[c_unDistributedControl_INDEX_HOST_NAME] = "";
		systemDetails[c_unDistributedControl_INDEX_PORT_NUM] = 0;
		systemDetails[c_unDistributedControl_INDEX_SYS_ID] = 0;
		return;		
	}

	if(dpExists(systemName + ":_Connections.Data.HostNames"))
	{
		dpGet(systemName + ":_Connections.Data.HostNames", hostNames);
		if(dynlen(hostNames) == 0)
		{
			systemDetails[c_unDistributedControl_INDEX_HOST_NAME] = "";
			systemDetails[c_unDistributedControl_INDEX_PORT_NUM] = 0;
			systemDetails[c_unDistributedControl_INDEX_SYS_ID] = 0;
			return;		
		}
		else
			systemDetails[c_unDistributedControl_INDEX_HOST_NAME] = hostNames[1];
	}
	
	systemDetails[c_unDistributedControl_INDEX_PORT_NUM] = 0;
	systemDetails[c_unDistributedControl_INDEX_SYS_ID] = systemId;
}
//@}