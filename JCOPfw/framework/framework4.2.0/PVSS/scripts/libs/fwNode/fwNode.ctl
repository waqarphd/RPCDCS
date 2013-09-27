/**@file

@par Creation Date
	15/07/2003

@par Modification history

@par Constraints
	The function fwNode_initialize() has to be called before creating any
	logical node.

@author 
	Manuel Gonzalez Berges (IT-CO)
*/
//@{

// global variables

global bool g_fwNode_INITIALIZED = FALSE;
global int g_fwNode_SEQUENCE_NUMBER;

const string fwNode_LOGICAL_NAME_ROOT = "FwNode";
const unsigned fwNode_LOGICAL_NAME_DIGITS = 6;

const string fwNode_TYPE_VENDOR					= "VENDOR";
const string fwNode_TYPE_LOGICAL 				= "LOGICAL";
const string fwNode_TYPE_LOGICAL_ROOT			= "LOGICAL ROOT";
const string fwNode_TYPE_LOGICAL_DELETED_ROOT	= "LOGICAL DELETED ROOT";
const string fwNode_TYPE_ALL					= "ALL";

const unsigned fwNode_TYPE				= 1;
const unsigned fwNode_PANELS_NAVIGATOR	= 2;
const unsigned fwNode_PANELS_EDITOR		= 3;
const unsigned fwNode_DP_TYPES			= 4;


/** This function has to be called before creting any logical node.
It initializes teh sequence numbers to be used for the node names.

@par Constraints
	None

@par Usage
	Public

@par PVSS managers
	VISION, CTRL
*/
fwNode_initialize()
{
	int result;
	string sString, sNumeric;
	
	dyn_int nodeNumbers;
	dyn_string nodes = dpNames("*", "FwNode");
	
	for(int i = 1; i <= dynlen(nodes); i++)
	{
		sNumeric = "";
		
		// get rid of the system name
		nodes[i] = dpSubStr(nodes[i], DPSUB_DP);
		
		// parse to find a string + a number
		result = sscanf(nodes[i], "%[^0-9]%[0-9]", sString, sNumeric);
		
		if(sString == fwNode_LOGICAL_NAME_ROOT)
			nodeNumbers[i] = sNumeric;		
		else
			nodeNumbers[i] = 0;
			
//		DebugN(nodes[i], nodeNumbers[i], sString, sNumeric);
	}
	
	g_fwNode_SEQUENCE_NUMBER = dynMax(nodeNumbers) + 1;
	g_fwNode_INITIALIZED = TRUE;
}


/** Creates a Framework node (dp type FwNode) of the selected type and
configures it with the specified parameters.

@par Constraints
	None

@par Usage
	Private

@par PVSS managers
	VISION, CTRL
	
@param nodeNameOrAlias 
@param parentAlias
@param nodeType	type of the node. Currently the following types are supported:
					-fwNode_TYPE_VENDOR: root nodes in the hardware view
					-fwNode_TYPE_LOGICAL_ROOT: root nodes in the logical view
					-fwNode_TYPE_LOGICAL: normal nodes in the logical view
@param editorPanels panels to be used when the node is selected in the Editor mode
@param navigatorPanels panels to be used when the node is selected in the Navigator mode
@param childrenDpTypes in the case of a vendor node, dp types that can be created
@param exceptionInfo details of any exceptions are returned here
*/
_fwNode_create(	string nodeNameOrAlias, string parentAlias, string nodeType, dyn_string editorPanels,
				dyn_string navigatorPanels, dyn_string childrenDpTypes, dyn_string &exceptionInfo)
{
	string nodeName, nodeAlias, dpName;
	dyn_errClass err;
	
	if(!g_fwNode_INITIALIZED)
		fwNode_initialize();
	
	// if logical root, it cannot have a parent
	switch(nodeType)
	{
		case fwNode_TYPE_VENDOR:
			if(parentAlias != "")
			{
				fwException_raise(exceptionInfo, 
								  "ERROR",
								  "_fwNode_create(): a vendor node cannot have a parent node.",
								  "");
				return;				
			}
			nodeName = nodeNameOrAlias;
			nodeAlias = "";
			break;
			
		case fwNode_TYPE_LOGICAL_ROOT:
			if(parentAlias != "")
			{
				fwException_raise(exceptionInfo, 
								  "INFO",
								  "_fwNode_create(): a logical root node cannot have a parent node.",
								  "");
				return;				
			}
			sprintf(nodeName, "%s%0" + fwNode_LOGICAL_NAME_DIGITS + "d" ,fwNode_LOGICAL_NAME_ROOT, g_fwNode_SEQUENCE_NUMBER++);
			nodeAlias = nodeNameOrAlias;
			break;
			
		case fwNode_TYPE_LOGICAL:
			if(parentAlias == "")
			{
				fwException_raise(exceptionInfo, 
								  "ERROR",
								  "_fwNode_create(): a logical node has to be placed in a parent device.",
								  "");
				return;				
			}
			sprintf(nodeName, "%s%0" + fwNode_LOGICAL_NAME_DIGITS + "d" ,fwNode_LOGICAL_NAME_ROOT, g_fwNode_SEQUENCE_NUMBER++);
			nodeAlias = parentAlias + fwDevice_HIERARCHY_SEPARATOR + nodeNameOrAlias;
			break;
			
		case fwNode_TYPE_LOGICAL_DELETED_ROOT:
		default:
			fwException_raise(	exceptionInfo, 
							  	"ERROR",
								"_fwNode_create(): not supported node type (" + nodeType + ")",
								  "");
			return;
			break;
	}

	//DebugN(nodeName, nodeAlias, g_fwNode_SEQUENCE_NUMBER, g_fwNode_INITIALIZED);

	// check if alias is already in use
	if(nodeAlias != "")
	{
		dpName = dpAliasToName(nodeAlias);
		if(dpName!= "")
		{
			fwException_raise(exceptionInfo, 
							  "ERROR",
							  "_fwNode_create(): alias " + nodeAlias + " is already used in your system.",
							  "");
			return;				
		}
	}

	// actually create the node
	fwDevice_create(makeDynString(nodeName, "FwNode", "", ""),
					makeDynString(""),
					exceptionInfo);

	if(dynlen(exceptionInfo) > 0)
		return;
	
	// set the node configuration
	dpSet(	nodeName + ".type", nodeType,
			nodeName + ".dpTypes", childrenDpTypes,
			nodeName + ".navigatorPanels", navigatorPanels,
			nodeName + ".editorPanels", editorPanels);
	
	if(nodeAlias != "")
		dpSetAlias(nodeName + ".", nodeAlias);
		
	// test whether there were errors
	err = getLastError(); 
 	if(dynlen(err) > 0)
 	{
 		dpDelete(nodeName);
 		fwException_raise(	exceptionInfo,
 							"ERROR",
 							"_fwNode_create: Could not create the logical node",
 							"");
		return;
 	}
}


/** Creates a Framework logical node and configures it with the specified 
parameters. If no parent is specified, then it will be a logical root node.

@par Constraints
	None

@par Usage
	Public

@par PVSS managers
	VISION, CTRL
	
@param nodeAlias datapoint alias of the node. The node name will be of the form
					FwNodeXXXXXX, where XXXXXX is a sequential number
@param parentAlias datapoint alias of the parent in the logical view
@param editorPanels panels to be used when the node is selected in the Editor mode
@param navigatorPanels panels to be used when the node is selected in the Navigator mode
@param exceptionInfo details of any exceptions are returned here
*/
fwNode_createLogical(	string nodeAlias, string parentAlias, dyn_string editorPanels, 
						dyn_string navigatorPanels, dyn_string &exceptionInfo)
{
	string type;
	
	// if no parent is specified it is a root node
	if(parentAlias == "")
	{
		type = fwNode_TYPE_LOGICAL_ROOT;
	}
	else
	{
		type = fwNode_TYPE_LOGICAL;		
	}
	
	_fwNode_create(	nodeAlias, parentAlias, type, editorPanels,
					navigatorPanels, makeDynString(), exceptionInfo);
}


/** Creates a Framework vendor node and configures it with the specified parameters.
This nodes appear as root in the hardware view.

@par Constraints
	None

@par Usage
	Public

@par PVSS managers
	VISION, CTRL
	
@param nodeName name of the node
@param editorPanels panels to be used when the node is selected in the Editor mode
@param navigatorPanels panels to be used when the node is selected in the Navigator mode
@param childrenDpTypes in the case of a vendor node, dp types that can be created
@param exceptionInfo details of any exceptions are returned here
*/
fwNode_createVendor(string nodeName, dyn_string editorPanels, dyn_string navigatorPanels, 
					dyn_string childrenDpTypes, dyn_string &exceptionInfo)
{
	_fwNode_create(	nodeName, "", fwNode_TYPE_VENDOR, editorPanels,
					navigatorPanels, childrenDpTypes, exceptionInfo);
}


/** If the node passed is of type fwNode_TYPE_VENDOR, the function returns the possible 
children datapoint types.

@par Constraints

@par Usage
	Public

@par PVSS managers
	CTRL, VISION

@param nodeDpName the datapoint name of the node
@param nodeDpTypes returns the datapoint types that can be created as children of the vendor node
@param exceptionInfo details of any exceptions are returned here
*/
fwNode_getDpTypes(string nodeDpName, dyn_string &nodeDpTypes, dyn_string &exceptionInfo)
{
	string nodeType;
	
	fwNode_getType(nodeDpName, nodeType, exceptionInfo);
	
	if(nodeType == fwNode_TYPE_VENDOR)
	{
		dpGet(nodeDpName + ".dpTypes", nodeDpTypes);
	}
	else
	{
		nodeDpTypes = makeDynString();
		fwException_raise(	exceptionInfo, 
							"ERROR", 
							"fwNode_getDpTypes(): the specified device is not a vendor node (" + nodeDpName + ")",
							"");
		return;	
	}
}


/** If the node passed is of type fwNode_TYPE_VENDOR, the function sets the possible 
children datapoint types.

@par Constraints

@par Usage
	Public

@par PVSS managers
	CTRL, VISION

@param nodeDpName the datapoint name of the node
@param nodeDpTypes the datapoint types that can be created as children of the vendor node
@param exceptionInfo details of any exceptions are returned here
*/
fwNode_setDpTypes(string nodeDpName, dyn_string nodeDpTypes, dyn_string &exceptionInfo)
{
	string nodeType;
	
	fwNode_getType(nodeDpName, nodeType, exceptionInfo);
	
	if(nodeType == fwNode_TYPE_VENDOR)
	{
		dpSet(nodeDpName + ".dpTypes", nodeDpTypes);
	}
	else
	{
		fwException_raise(	exceptionInfo, 
							"ERROR", 
							"fwNode_setDpTypes(): the specified device is not a vendor node (" + nodeDpName + ")",
							"");
		return;	
	}
	
}
 
/** Gets all the nodes of the specified type in the specified system

@par Constraints
	None
	
@par Usage
	Public

@par PVSS managers
	VISION, CTRL

@param systemName name of the system that we are interested in
@param nodeType node type we are interested in:
					-fwNode_TYPE_VENDOR
					-fwNode_TYPE_LOGICAL
					-fwNode_TYPE_LOGICAL_ROOT
					-fwNode_TYPE_LOGICAL_DELETED_ROOT
					-fwNode_TYPE_ALL
@param nodes returns the nodes of the specified type in the specified system
@param exceptionInfo details of any exceptions are returned here
*/
fwNode_getNodes(string systemName, string nodeType, dyn_string &nodes, dyn_string &exceptionInfo)
{
	int i;
	string localNodeType, ownSystemName;
	dyn_string localNodes;
	
	// work around until dpNames with a specified dpType works correctly
	ownSystemName = getSystemName();
	if((ownSystemName == systemName) || (systemName == ""))
		localNodes = dpNames(systemName + "*", "FwNode");
	else
		fwDevice_dpNames(systemName + "*", "FwNode", localNodes, exceptionInfo);
	
	if (nodeType == fwNode_TYPE_ALL)
	{
		nodes = localNodes;
	}
	else
	{
		nodes = makeDynString();
		for(i = 1; i <= dynlen(localNodes); i++)
		{
			dpGet(localNodes[i] + ".type", localNodeType);
			if(localNodeType == nodeType)
			{
				dynAppend(nodes, localNodes[i]);
			}
		}
	}
//	DebugN("vendor Nodes " + vendorNodes);
//	DebugN("nodes " + nodes);
}


/** Gets panels associated with a given datapoint of type FwNode.

@par Constraints
	None
	
@par Usage
	Public

@par PVSS managers
	VISION, CTRL

@param nodeDpName the datapoint name of the node
@param mode which mode we are interested in
@param panels returns the requested panels
@param exceptionInfo details of any exceptions are returned here
*/
fwNode_getPanels(string nodeDpName, string mode, dyn_string &panels, dyn_string &exceptionInfo)
{
	switch(mode)
	{
		case fwDEN_MODE_NAVIGATOR:
			dpGet(nodeDpName + ".navigatorPanels", panels);
			break;
		case fwDEN_MODE_EDITOR:
			dpGet(nodeDpName + ".editorPanels", panels);
			break;
		default:
			break;
	}
}


/** Gets node type of a given datapoint. If the datapoint is not of type FwNode, an
exception is raised.

@par Constraints
	None
	
@par Usage
	Public

@par PVSS managers
	VISION, CTRL

@param nodeDpName the datapoint name of the node
@param nodeType	returns the node type
@param exceptionInfo details of any exceptions are returned here
*/
fwNode_getType(string nodeDpName, string &nodeType, dyn_string &exceptionInfo)
{	
	if(!dpExists(nodeDpName))
	{
		fwException_raise(exceptionInfo, 
						  "INFO",
						  "fwNode_getType(): The node" + nodeDpName + " does not exist.",
						  "");
		return;
	}

	dpGet(nodeDpName + ".type", nodeType);
}


/** Sets node type of a given datapoint. If the datapoint is not of type FwNode, an
exception is raised.

@par Constraints
	None
	
@par Usage
	Public

@par PVSS managers
	VISION, CTRL

@param nodeDpName the datapoint name of the node
@param nodeType the node type to be set
@param exceptionInfo details of any exceptions are returned here
*/
fwNode_setType(string nodeDpName, string nodeType, dyn_string &exceptionInfo)
{	
	if(!dpExists(nodeDpName))
	{
		fwException_raise(exceptionInfo, 
						  "INFO",
						  "fwNode_setType(): The node" + nodeDpName + " does not exist.",
						  "");
		return;
	}

	dpSet(nodeDpName + ".type", nodeType);
}
//@}