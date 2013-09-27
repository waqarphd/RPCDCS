/**@file

This package contains hierarchy-related functions of the Configuration Database tool

@author Piotr Golonka (EN/ICE-SCD)
@date   July 2010
*/

global string _fwConfigurationDB_fileVersion_fwConfigurationDB_Hierarchies_ctl="3.3.63";



/**
@ingroup deviceConfigsIndices
*/

const int fwConfigurationDB_deviceConfig_VALUE         = 1;
const int fwConfigurationDB_deviceConfig_ADDRESS       = 2;
const int fwConfigurationDB_deviceConfig_ALERT         = 4;
const int fwConfigurationDB_deviceConfig_ARCHIVING     = 8;
const int fwConfigurationDB_deviceConfig_DPFUNCTION    = 16;
const int fwConfigurationDB_deviceConfig_CONVERSION    = 32;
const int fwConfigurationDB_deviceConfig_PVRANGE       = 64;
const int fwConfigurationDB_deviceConfig_SMOOTHING     = 128;
const int fwConfigurationDB_deviceConfig_UNITANDFORMAT = 256;
const int fwConfigurationDB_deviceConfig_ALLDEVPROPS = 511;
const int fwConfigurationDB_deviceConfig_FW_DEFAULTS = 32768;

//__________________________________________________________________________
/**
 * @name Indexing constants for deviceListObject variables

   The following constants are used to refer to the data in a single
   row of a @ref deviceListObject variable (a recipeRow).

 * @{
 */




/**
@ingroup deviceListObjectIndices
 */

const int fwConfigurationDB_DLO_DPNAME = 1; // full dp name or dp alias (with system name), depending on hierarchy type
const int fwConfigurationDB_DLO_DPTYPE = 2; // data point type
const int fwConfigurationDB_DLO_NAME = 3;   // short name of this single item (i.e. without the whole structure)
//const int fwConfigurationDB_DLO_TYPE = 4;   // device type, as stored in DB
const int fwConfigurationDB_DLO_MODEL = 5;  // device model, as stored in DB
const int fwConfigurationDB_DLO_COMMENT = 6;// commend
const int fwConfigurationDB_DLO_ITEMID = 7; // id of this item in the database
const int fwConfigurationDB_DLO_PARENTID = 8; // parent's id
const int fwConfigurationDB_DLO_DPID = 9;   // only for h/w hierarchy: datapoint id

const int fwConfigurationDB_DLO_REFDP = 10; // for logical hierarchy: the h/w device dpname is here

const int fwConfigurationDB_DLO_REFID = 11; // for logical hierarchy: the h/w device id is here when storing
const int fwConfigurationDB_DLO_REF_STATUS = 12; // for logical hierarchy: the status of the reference: 1: alias does not exits yet,
						// 2 - alias already exists and needs to be unmapped before assigning to the new device
						// 0 - undefined

const int fwConfigurationDB_DLO_PROPIDS = 13; // dyn_int list of item property id's from the database; each propId reflects
					      // the settings for one device (data point) element;
					      // this propid is used as key to the configs data for indicated elements
const int fwConfigurationDB_DLO_PROPNAMES = 14; // dyn_string list of item property names, corresponding to propids

const int fwConfigurationDB_DLO_CITEM_ID = 15; // CITEM_ID pointer...
const int fwConfigurationDB_DLO_MAX_IDX = 15;
//@} // end of indexing constants
//______________________________________________________________________________



void fwConfigurationDB_getDBHierarchies(dyn_int &ids, dyn_string &types, dyn_string &descriptions,
                                        dyn_string &validFrom, dyn_string &validTo,
                                        dyn_string &exceptionInfo)
{
    dyn_dyn_mixed aRecords;
    string sql="SELECT HVER,HTYPE,DESCR,VALID_FROM,VALID_TO FROM HIERARCHIES ORDER BY HVER";
    _fwConfigurationDB_executeDBQuery(sql,g_fwConfigurationDB_DBConnection, aRecords, exceptionInfo);
    if (dynlen(exceptionInfo)) return;
    for (int i=1;i<=dynlen(aRecords);i++) {
        if (((int)aRecords[i][4])<=0) aRecords[i][4]="";
        if (((int)aRecords[i][5])<=0) aRecords[i][5]="";
        dynAppend(ids,aRecords[i][1]);
        dynAppend(types,aRecords[i][2]);
        dynAppend(descriptions,aRecords[i][3]);
        dynAppend(validFrom,aRecords[i][4]);
        dynAppend(validTo,aRecords[i][5]);
    }

}



void fwConfigurationDB_extractHierarchyFromDB(string topDevice, string hierarchyType,
                                              dyn_dyn_mixed &deviceListObject,
                                              dyn_string &exceptionInfo, string system="")
{
    time t0;
    _fwConfigurationDB_startFunction("extractHierarchyFromDB", t0);

    if (fwConfigurationDB_progress(fwConfigurationDB_OPER_LoadHierachyFromDB,"Loading hierarchy info from DB", 10.0, exceptionInfo)) return;

    dynClear (deviceListObject);
    _fwConfigurationDB_ensureDeviceListObjectValid(deviceListObject);

    //if ((hierarchyType==fwDevice_HARDWARE) && (system=="")) system=getSystemName();

    string sqlTopDevice="rd.DPNAME=\'"+topDevice+"\'";
    bool hasRootDevice=TRUE;

    if (topDevice=="") {
	if (hierarchyType==fwDevice_LOGICAL) {
	    sqlTopDevice="rd.DPNAME IS NULL";
	    hasRootDevice=TRUE;
	} else {
	    if (system!="") {
		sqlTopDevice="rd.DPNAME=\'"+system+"\'";
		hasRootDevice=TRUE;
	    } else {
		hasRootDevice=FALSE;
		DebugN("WARNING! Querying the whole hierarchy in extractHierarchyFromDB. This may take a lot of time!");
	    }
	}
    }
    string queryRootDevice="SELECT rd.ID FROM V_ITEM_NAMES rd WHERE "+
        sqlTopDevice+" AND "+
        "rd.HVER="+g_fwConfigurationDB_DBHierarchyIDs[hierarchyType];

    string queryDeviceHierarchy="SELECT H.ITEM_ID,H.PARENT_ID,H.NAME,H.DPNAME,"+
        "H.DPTYPE,H.DETAIL,H.DESCRIPTION,h.dpid "+
        "FROM V_ITEMS H ";

    if (hasRootDevice) queryDeviceHierarchy=queryDeviceHierarchy+" START WITH H.ITEM_ID=("+queryRootDevice+") ";

    queryDeviceHierarchy=queryDeviceHierarchy+" CONNECT BY H.PARENT_ID = PRIOR H.ITEM_ID";

    queryDeviceHierarchy=queryDeviceHierarchy+" ORDER BY H.ITEM_ID";

    string sql = queryDeviceHierarchy;
    dyn_dyn_mixed aRecords;
    _fwConfigurationDB_executeDBQuery(sql,g_fwConfigurationDB_DBConnection, aRecords, exceptionInfo);
    if (dynlen(exceptionInfo)) return;
    if (fwConfigurationDB_progress(fwConfigurationDB_OPER_LoadHierachyFromDB,"Processing the data", 70.0, exceptionInfo)) return;

    for (int i=1;i<=dynlen(aRecords);i++) {

        dynAppend(deviceListObject[fwConfigurationDB_DLO_ITEMID],(int)aRecords[i][1]);
        dynAppend(deviceListObject[fwConfigurationDB_DLO_PARENTID],(int)aRecords[i][2]);
        dynAppend(deviceListObject[fwConfigurationDB_DLO_NAME],aRecords[i][3]);
        dynAppend(deviceListObject[fwConfigurationDB_DLO_DPNAME],aRecords[i][4]);
        dynAppend(deviceListObject[fwConfigurationDB_DLO_DPTYPE],aRecords[i][5]);
        dynAppend(deviceListObject[fwConfigurationDB_DLO_MODEL],aRecords[i][6]);
        dynAppend(deviceListObject[fwConfigurationDB_DLO_COMMENT],aRecords[i][7]);
        dynAppend(deviceListObject[fwConfigurationDB_DLO_DPID],(int)aRecords[i][8]);

	// fill the remaining space
	mixed dummy;
	for (int idx=fwConfigurationDB_DLO_REFDP;idx<=fwConfigurationDB_DLO_MAX_IDX;idx++) dynAppend(deviceListObject[idx],dummy);
    };

    if (dynlen(exceptionInfo)) return;


    if (fwConfigurationDB_progress(fwConfigurationDB_OPER_LoadHierachyFromDB,"Loading hierarchy info from DB", 100.0, exceptionInfo)) return;

    _fwConfigurationDB_endFunction("extractHierarchyFromDB", t0);
}



/**
Completes the information for the logical hierarchy

requires fields: fwConfigurationDB_DLO_DPNAME, fwConfigurationDB_DLO_DPTYPE
fills-in fields: fwConfigurationDB_DLO_REFDP,  fwConfigurationDB_DLO_REFID

skips the fields that has type == "Node"

*/
void _fwConfigurationDB_getReferencesFromDB( dyn_dyn_mixed &deviceListObject, string configurationName, dyn_string &exceptionInfo)
{

    dyn_string devList, refList;

    string sql="SELECT item_ID, REF_ID , refdpname FROM V_REFERENCES "+
		"WHERE CONFIG_TAG=\'"+configurationName+"\'";


    dyn_dyn_mixed aRecords;
    _fwConfigurationDB_executeDBQuery(sql,g_fwConfigurationDB_DBConnection, aRecords, exceptionInfo,3,TRUE);
    if (dynlen(exceptionInfo)) return;


    // protect from errors when empty recordset returned...
    if (dynlen(aRecords)==0) {
	dyn_mixed empty;
	aRecords[1]=empty;
	aRecords[2]=empty; // fix #55830
    };

    dyn_int dbItemIds=aRecords[1];
    dyn_int dbRefIds=aRecords[2];

    for (int i=1;i<=dynlen(deviceListObject[fwConfigurationDB_DLO_DPNAME]);i++) {
	if (deviceListObject[fwConfigurationDB_DLO_DPTYPE][i]=="FwNode") {
	    deviceListObject[fwConfigurationDB_DLO_REFDP][i]="";//deviceListObject[fwConfigurationDB_DLO_DPNAME][i];
	    deviceListObject[fwConfigurationDB_DLO_REFID][i]=0;
	    continue;
	}
	int idx=dynContains(dbItemIds,deviceListObject[fwConfigurationDB_DLO_ITEMID][i]);
	if (idx >0) {
	    deviceListObject[fwConfigurationDB_DLO_REFDP][i]=aRecords[3][idx];
	    deviceListObject[fwConfigurationDB_DLO_REFID][i]=dbRefIds[idx];
	} else {
	    deviceListObject[fwConfigurationDB_DLO_REFDP][i]="";
	    deviceListObject[fwConfigurationDB_DLO_REFID][i]=0;
	}
    }

}


/** Resolves device names
 *
 * This functions takes the list of device names - devices being
 * in either hierarchy, and tells what are the actual hierarchy
 * to which they belong, and what are the datapoint to which they
 * refer
 *
 */
void fwConfigurationDB_resolveDevices(dyn_string deviceList,
    dyn_string &devHierarchies, dyn_string &devDatapoints,
    dyn_string &exceptionInfo , bool errorOnNotFound=TRUE)
{
    dyn_string allDps;
    dyn_string allAliases;
    dpGetAllAliases (allDps, allAliases);

    for (int i=1;i<=dynlen(deviceList);i++) {
	string deviceName=deviceList[i];
	if (strpos(deviceName,":")>0) {
	    // hardware hierarchy
	    if ( (!dpExists(deviceName)) && errorOnNotFound) {
		fwException_raise(exceptionInfo,"ERROR","Device (HARDWARE) not found:\n"+deviceName,"");
		return;
	    }
	    devHierarchies[i]=fwDevice_HARDWARE;
	    devDatapoints[i]=dpSubStr(deviceName,DPSUB_SYS_DP);
	} else {
	    // it is an alias
	    string alias=deviceList[i];
	    int idx=dynContains(allAliases,alias);
	    if ((idx<1) && errorOnNotFound) {
		fwException_raise(exceptionInfo,"ERROR","Device (LOGICAL) not found:\n"+alias,"");
		return;
	    }
	    devHierarchies[i]=fwDevice_LOGICAL;
	    devDatapoints[i]=dpSubStr(allDps[idx],DPSUB_SYS_DP);
	} // some day: else FSM ...

    }

}





/** Gets the list of children items, in specified hierarchy
 *
 * @param rootNode  the name of the parent device (item)
 * @param hierarchyType the Framework hierarchy type:
 *              @li fwDevice_HARDWARE for Hardware hierarchy
 *              @li fwDevice_LOGICAL  for Logical hierarchy
 *      (other hierarchies are not supported yet).
 * @param nodeList  the resulting list of child items will be stored in this variable.
 *		Note that this is "append" operation, i.e. the contents of the variable
 *		are not cleared from previous content!
 * @param exceptionInfo standard exception handling variable
 * @param system (optional) the name of the system (for distributed systems);
 *              when not specified, the local system is assumed
 * @param includeRootNode (optional) determined if the rootNode will be included
 *          in the list; if TRUE (default) rootNode will be included, if FALSE - it will not.
 *
 *
 *
 * @see @ref qstart_devLists section of the Quick Start.
 */
void fwConfigurationDB_getHierarchyFromPVSS(string rootNode, string hierarchyType,
    dyn_string &nodeList,dyn_string &exceptionInfo,string system="", string includeRootNode=TRUE)
{
    time t0;
    if (includeRootNode) { // do not printout in recursive calls!
	_fwConfigurationDB_startFunction("getHierarchyFromPVSS", t0);
    }
    if (fwConfigurationDB_progress(fwConfigurationDB_OPER_GetHierachyFromSystem,"Getting hierarchy from PVSS", 10.0,
        exceptionInfo)) return;



    if (system=="") system=getSystemName();

    if (rootNode=="" || rootNode==system) {
        string nodeType;
        dyn_string rootNodes;
        if (hierarchyType==fwDevice_HARDWARE) {
            nodeType=fwNode_TYPE_VENDOR;
        }else if (hierarchyType==fwDevice_LOGICAL) {
            nodeType=fwNode_TYPE_LOGICAL_ROOT;
        } else {
            fwException_raise(exceptionInfo,"ERROR","Hierarchy type "+hierarchyType+" not supported","");
            return;
        }

        fwNode_getNodes(system, nodeType, rootNodes, exceptionInfo);
        if (dynlen(exceptionInfo)) return;
        for (int i=1;i<=dynlen(rootNodes);i++) {
	    string rNode=rootNodes[i];
	    if (hierarchyType==fwDevice_LOGICAL) {
		rNode=dpGetAlias(rNode+".");
		if (rNode=="") {
		    fwException_raise(exceptionInfo,"ERROR","Cannot resolve alias for root of logical hierarchy:"+rootNodes[i],"");
		    return;
		}
	    }
            dyn_string lNodeList;
            fwConfigurationDB_getHierarchyFromPVSS(rNode, hierarchyType, lNodeList, exceptionInfo, system,TRUE);
            if (dynlen(exceptionInfo)) return;
            dynAppend(nodeList,lNodeList);
        };
        return;
    }

    if (hierarchyType==fwDevice_HARDWARE) {
	// bugfix #14418: ensure that system name is in the name
	rootNode=_fwConfigurationDB_NodeNameWithSystem(rootNode, system, exceptionInfo);
	if (dynlen(exceptionInfo)) return;
    }

    if (includeRootNode) dynAppend(nodeList,rootNode);

    dyn_string localDevices;
    fwDevice_getChildren(rootNode,hierarchyType,localDevices,exceptionInfo);
    if (dynlen(exceptionInfo)) return;
    for (int i=1;i<=dynlen(localDevices);i++) {
        dynAppend(nodeList,localDevices[i]);
        fwConfigurationDB_getHierarchyFromPVSS(localDevices[i], hierarchyType, nodeList, exceptionInfo, system,FALSE);
        if (dynlen(exceptionInfo)) return;

    };

    if (fwConfigurationDB_progress(fwConfigurationDB_OPER_GetHierachyFromSystem,"Got hierarchy from PVSS", 100.0,
        exceptionInfo)) return;

    if (includeRootNode) { // do not printout in recursive calls!
	_fwConfigurationDB_endFunction("getHierarchyFromPVSS", t0);
    }

}


/** Copies one entry (line) of device object to another device object.
if dst_idx=0 this is "append" operation
*/
void _fwConfigurationDB_copyDeviceListObjectEntry(dyn_dyn_mixed srcObject, int src_idx,
    dyn_dyn_mixed &dstObject, int dst_idx, dyn_string &exceptionInfo)
{
    _fwConfigurationDB_ensureDeviceListObjectValid(srcObject);
    _fwConfigurationDB_ensureDeviceListObjectValid(dstObject);
    if (dst_idx==0) dst_idx=dynlen(dstObject[fwConfigurationDB_DLO_DPNAME])+1;
    for (int i=1;i<=fwConfigurationDB_DLO_MAX_IDX;i++) {
	if (dynlen(srcObject[i])>=src_idx) dstObject[i][dst_idx]=srcObject[i][src_idx];
    }
}

void _fwConfigurationDB_ensureDeviceListObjectValid(dyn_dyn_mixed &obj)
{
    if (dynlen(obj)<fwConfigurationDB_DLO_MAX_IDX) {
        dyn_mixed dummy;
        for (int i=(dynlen(obj)+1);i<=fwConfigurationDB_DLO_MAX_IDX;i++)
            obj[i]=dummy;
    }
}

/** For devices in the deviceList, the DeviceListObject is created,
filled with complete information.
Note that the function works for the devices that are already
in the system (i.e. the function is used when saving hierarchy to DB)
*/
void fwConfigurationDB_expandToDeviceListObject(string hierarchyType, dyn_string deviceList,
                    dyn_dyn_mixed &deviceListObject,dyn_string &exceptionInfo)
{
//DebugN("expandToDLO",deviceList);
    dynClear(deviceListObject);
    _fwConfigurationDB_ensureDeviceListObjectValid(deviceListObject);
    string system=getSystemName();
    dyn_dyn_string fwAllDevTypes;
    dyn_string allDpTypes=dpTypes();
    fwDevice_getAllTypes(fwAllDevTypes, exceptionInfo);
    if (dynlen(exceptionInfo)) return;


    for (int i=1;i<=dynlen(deviceList);i++) {

        string dpname="";
	string itemname="";
        string dptype="";
        string name="";
        string type="";
        string model="";
        string comment="";
	string nsdpname;
        unsigned dpid=-1;
        if ( (deviceList[i]==system)||(deviceList[i]=="")) {
            dpname=system;
	    itemname=dpname;
            dptype="";
            name=system;
            type="SYSTEM";
            model="SYSTEM";
        } else {


	    if (hierarchyType==fwDevice_HARDWARE) {
        	dpname=dpSubStr(deviceList[i],DPSUB_SYS_DP);
		itemname=dpname;
		int dummyelid;
    		nsdpname=dpSubStr(dpname,DPSUB_DP);
    		bool ok=dpGetId(nsdpname+".",dpid,dummyelid);
    		if (!ok) {
    	    	    fwException_raise(exceptionInfo,"ERROR","Cannot get DP ID for datapoint "+nsdpname, "");
            	    return;
    		}
	    } else if (hierarchyType==fwDevice_LOGICAL) {
		itemname=deviceList[i];
		dpname=dpAliasToName(itemname);
		dpname=dpSubStr(dpname,DPSUB_SYS_DP);
	    } else {
    		fwException_raise(exceptionInfo,"ERROR","hierarchy type "+hierarchyType+" not supported","");
    		return;
	    }

    	    dptype=dpTypeName(dpname);
    	    fwDevice_getName(itemname, name, exceptionInfo);
    	    fwDevice_getType(dptype, type, exceptionInfo);
    	    if (dynlen(exceptionInfo)) return;
//DebugN("resolving:",dpname,dptype,itemname,type);
    	    if (type=="") {
/*
		if (hierarchyType!=fwDevice_HARDWARE) {
		    fwException_raise(exceptionInfo,"ERROR","Cannot store non-Fw datapoint "+dpname+
		    "in hierarchy other than HARDWARE","");
		    return;
		}
*/
                // means: non-Framework device.
                type=dptype;
                model="DATAPOINT";
		if (hierarchyType==fwDevice_HARDWARE) {
		    name=nsdpname;
		} else {
		    name=itemname;
		}
    	    } else {
                dyn_string tmpDeviceObject;
                tmpDeviceObject[fwDevice_DP_NAME]=dpname;
                fwDevice_getModel(tmpDeviceObject, model, exceptionInfo);
                if (dynlen(exceptionInfo)) return;
    	    }
    	    comment=dpGetDescription(dpname+".");
    	    if (comment==(dpname+".")) comment=""; //// see details of dpGetDescription...;
        }


	int idx=dynlen(deviceListObject[fwConfigurationDB_DLO_DPNAME])+1;
        deviceListObject[fwConfigurationDB_DLO_ITEMID][idx]="";
        deviceListObject[fwConfigurationDB_DLO_PARENTID][idx]="";
        deviceListObject[fwConfigurationDB_DLO_DPNAME][idx]=itemname;
        deviceListObject[fwConfigurationDB_DLO_DPTYPE][idx]=dptype;
        deviceListObject[fwConfigurationDB_DLO_NAME][idx]=name;
//        deviceListObject[fwConfigurationDB_DLO_TYPE][idx]=type;
        deviceListObject[fwConfigurationDB_DLO_MODEL][idx]=model;
        deviceListObject[fwConfigurationDB_DLO_COMMENT][idx]=comment;
        deviceListObject[fwConfigurationDB_DLO_DPID][idx]=dpid;

	deviceListObject[fwConfigurationDB_DLO_REFDP][idx]="";
        deviceListObject[fwConfigurationDB_DLO_REFID][idx]="";
        deviceListObject[fwConfigurationDB_DLO_REF_STATUS][idx]=0;

        deviceListObject[fwConfigurationDB_DLO_PROPNAMES][idx]=makeDynString();
        deviceListObject[fwConfigurationDB_DLO_PROPIDS][idx]=makeDynInt(); // to be resolved later
    };

}



/**  adds the required (parent) devices to the list, based on the data in the database,
     puts the hierarchy in order.
     this function is used by @ref fwConfigurationDB_reconnectDevices

*/
void _fwConfigurationDB_dbCompleteDevicesInHierarchy(dyn_string &deviceList, string hierarchyType,
    string configurationName, dyn_string &exceptionInfo)
{

    string devListSql;

    // change my mind! Must not specify empty deviceList!
    if (dynlen(deviceList)==0) {
	fwException_raise(exceptionInfo,"ERROR in dbCompleteDevicesInHierarchy",
			    "Empty device list specified","");
	return;
    }


//    if (dynlen(deviceList)!=0) {
	devListSql=_fwConfigurationDB_listToSQLString("DPNAME", deviceList);
//    }

/*
    string sql= "SELECT UNIQUE citem_id, item_id, dpname from v_config_items "+
	        " WHERE tag=\'"+configurationName+"\' "+
	        " AND HVER="+g_fwConfigurationDB_DBHierarchyIDs[hierarchyType]+
	        " CONNECT BY PRIOR parent_id=item_id "+
	        " START WITH "+devListSql+
	        "  ORDER BY dpname" ;
*/

    string sql= "select unique dpname, item_id, parent_id from v_items "+
		" connect by prior parent_id=item_id start with "+
	        " item_id in ( "+
		"	select ci.item_id from v_config_items ci where "+devListSql+
			"and hver="+g_fwConfigurationDB_DBHierarchyIDs[hierarchyType]+
			"and tag=\'"+configurationName+"\')"+
		"order by dpname";



    dyn_dyn_mixed aRecords;
    _fwConfigurationDB_executeDBQuery(sql,g_fwConfigurationDB_DBConnection, aRecords, exceptionInfo,3,TRUE);
    if (dynlen(exceptionInfo)) return;
//DebugN("Complete devs returns",aRecords);
    if (dynlen(deviceList)) {
	// check if all devices were found...
	for (int i=1;i<=dynlen(deviceList);i++) {
	    //if (!dynContains(aRecords[3],deviceList[i])) {
	    if (!dynContains(aRecords[1],deviceList[i])) {
		fwException_raise(exceptionInfo,"ERROR in dbCompleteDevicesInHierarchy",
		"Device was not found in DB: "+deviceList[i],"");
		return;
	    }
	}
    }

    // otherwise: it's OK; substitute completed list
    //deviceList=aRecords[3];
    deviceList=aRecords[1];
}



/** adds the required (parent) devices to the list, puts the hierarchy in order
 *
 */
void _fwConfigurationDB_completeDevicesInHierarchy(dyn_string &deviceList, string hierarchyType,
    string system, dyn_string &exceptionInfo)
{
DebugN("completeDevsInH",system);
    dynUnique(deviceList);
    if (dynlen(deviceList)==0) return;

    dyn_string parents;

    // add parents to the list
    for (int i=1;i<=dynlen(deviceList);i++) {
        string devName=deviceList[i];

        if (hierarchyType==fwDevice_HARDWARE) {
            // in hardware hierarchy
            // resolving  parents should happen only for Framework devices...
            // and only for existing devices

            if (!dpExists(devName)) continue; // only for existing ones...
            string fwDevType;
            fwDevice_getType(dpTypeName(devName), fwDevType, exceptionInfo);
            if (dynlen(exceptionInfo)) return;
            if (fwDevType=="") continue; // means non-Framework device...
        }

        string parent="";
        fwDevice_getParent(devName, parent, exceptionInfo);
        if (dynlen(exceptionInfo)) return;
        parents[i]=parent;
        if (parent!="") {
            if (!dynContains(deviceList, parent)) {
                dynAppend(deviceList,parent);
            }
        }
    };

    dynSortAsc(deviceList);

    for (int i=1;i<=dynlen(deviceList);i++) {
        string dpname;
        if (hierarchyType==fwDevice_HARDWARE) {

            if (system=="") system=getSystemName();
            dpname=_fwConfigurationDB_NodeNameWithSystem(deviceList[i], system, exceptionInfo);
            if (dynlen(exceptionInfo)) return;
        } else if (hierarchyType==fwDevice_LOGICAL) {
            string itemname= _fwConfigurationDB_NodeNameWithoutSystem(deviceList[i]);
            dpname=dpAliasToName(itemname);
            if (dpname=="") {
                fwException_raise(exceptionInfo,"ERROR","Cannot resolve LOGICAL device "+itemname,"");
                return;
            }
            dpname=dpSubStr(dpname,DPSUB_SYS_DP);
        } else {
            fwException_raise(exceptionInfo,"ERROR","Hierarchy "+hierarchyType+" not supported","");
            return;
        }

        if (!dpExists(dpname)) {
            fwException_raise(exceptionInfo,"ERROR","Device does not exist:"+dpname,"");
            DebugN("Device:"+deviceList[i]+" (dp:"+dpname+") cannot be  found");
            return;
        }

        if (hierarchyType==fwDevice_HARDWARE) {
            deviceList[i]=dpname; // make sure the system name is in
        } else if (hierarchyType==fwDevice_LOGICAL) {
            if (system=="") {
                deviceList[i]= _fwConfigurationDB_NodeNameWithoutSystem(deviceList[i]);
            } else {
                deviceList[i]=_fwConfigurationDB_NodeNameWithSystem(deviceList[i], system, exceptionInfo);
                if (dynlen(exceptionInfo)) return;
            }
        }
    }
}

/** Finds the devices that exist and devices that do not exist,
 * returns them as deviceListObject variables, ready for further
 * processing.
 *
 * WARNING! Empty system name here means: don't filter!
 *
*/
void fwConfigurationDB_findDevicesInDB(string topDevice, string hierarchyType,
                                       dyn_string deviceList,
                                       dyn_dyn_mixed &deviceListObject, dyn_string &missingDevicesList,
                                       dyn_string &exceptionInfo, string system="")
{
    time t0;
    _fwConfigurationDB_startFunction("findDevicesInDB", t0);
    //if ((hierarchyType==fwDevice_HARDWARE) && (system=="")) system=getSystemName();
    dynClear(deviceListObject);
    _fwConfigurationDB_ensureDeviceListObjectValid(deviceListObject);

    dyn_dyn_mixed dbDeviceListObject;
    fwConfigurationDB_extractHierarchyFromDB(topDevice, hierarchyType,
                                             dbDeviceListObject,
                                             exceptionInfo, system);
    if (dynlen(exceptionInfo)) return;

    for (int i=1;i<=dynlen(deviceList);i++) {

        int idx=dynContains(dbDeviceListObject[fwConfigurationDB_DLO_DPNAME],deviceList[i]);
        if (idx>=1){
            _fwConfigurationDB_copyDeviceListObjectEntry(dbDeviceListObject, idx,
                deviceListObject,0,exceptionInfo);
            if (dynlen(exceptionInfo)) return;
            continue; // ok, already in DB; move on to the next device in the list
        }
        // otherwise - device is missing:
        dynAppend(missingDevicesList,deviceList[i]);
    }


    _fwConfigurationDB_endFunction("findDevicesInDB", t0);
}

/** check if datapoints exist and verify that existing ones
    have appropriate types and models. Find and group in the
    missingDevicesListObject the ones that does not exist,
    report (with exceptionInfo) if some of them exist with
    incompatible type
*/
void _fwConfigurationDB_verifyDatapoints(string hierarchyType,
                                       dyn_dyn_mixed &deviceListObject, dyn_dyn_mixed &missingDevicesListObject,
                                       dyn_string &exceptionInfo, bool checkDeviceLocal=FALSE)
{
    _fwConfigurationDB_ensureDeviceListObjectValid(deviceListObject);
    dynClear(missingDevicesListObject);
    _fwConfigurationDB_ensureDeviceListObjectValid(missingDevicesListObject);

    string sysName=getSystemName();
    for (int i=1;i<=dynlen(deviceListObject[fwConfigurationDB_DLO_DPNAME]);i++) {

	string dpname=deviceListObject[fwConfigurationDB_DLO_DPNAME][i];
        string type=deviceListObject[fwConfigurationDB_DLO_DPTYPE][i];
        string model=deviceListObject[fwConfigurationDB_DLO_MODEL][i];

        if (model=="SYSTEM") {
            continue;
        }

        if (checkDeviceLocal) {
	// this one checks that the node is really local!
    	    string checkDpname=_fwConfigurationDB_NodeNameWithSystem(dpname, sysName, exceptionInfo);
	    if (dynlen(exceptionInfo)) return;

	    if (hierarchyType==fwDevice_LOGICAL) {
		// additionally check if the referenced DP is local!
		string refDP=deviceListObject[fwConfigurationDB_DLO_REFDP][i];
		string refSysName=_fwConfigurationDB_NodeSystemName(refDP);
    		if (refSysName!=sysName) {
            	    fwException_raise(exceptionInfo,"ERROR","Node "+dpname+" is linked to non-local device "+refDP,"");
            	    return;
    		}
	    }
        };

	if (hierarchyType==fwDevice_HARDWARE) {

    	    if (!dpExists(dpname)) {
        	_fwConfigurationDB_copyDeviceListObjectEntry(deviceListObject, i,
            	    missingDevicesListObject,0,exceptionInfo);
        	if (dynlen(exceptionInfo)) return;
        	continue;
    	    }

    	    // if the device exist, check type and model
    	    string locType=dpTypeName(dpname);
    	    if (locType!=type && locType!="" && type!="") {
        	fwException_raise(exceptionInfo,"ERROR","Conflicting dp types for device "+dpname,"");
        	DebugN("Conflicting types for "+dpname,locType,type);
        	return;
    	    }

    	    // if the dpt match, check also models, for non-Framework devices
    	    if ( (model=="") || (model =="DATAPOINT")) continue;

    	    string locModel;
    	    fwDevice_getModel(makeDynString(dpname), locModel,exceptionInfo);
    	    if (dynlen(exceptionInfo)) return;
    	    if (model!=locModel && model!="" && locModel!="") {
        	fwException_raise(exceptionInfo,"ERROR","Conflicting models for device "+dpname,"");
        	DebugN("Conflicting models for "+dpname,"in DB:"+model,"in system:"+locModel);
		DebugN("Type in DB",type);
        	return;
    	    }


	} else if (hierarchyType==fwDevice_LOGICAL) {
	    // CAREFULY! We need to do everything on aliases!
	    // i.e. use dpAliasToName() and not dpExists
	    // this is for cases where node is e.g. renamed...
	    // and that is why we need this:

	    string dpalias=_fwConfigurationDB_NodeNameWithoutSystem(dpname);
	    string devDp=dpSubStr(dpAliasToName(dpalias),DPSUB_SYS_DP);
	    if (devDp=="") {
		// means that alias/node does not exist yet...
		if (type=="FwNode") {
		    // if this is a node (not a leaf) mark it for creation,
		    // that is: copy the entry to missingDevicesListObject
        	    _fwConfigurationDB_copyDeviceListObjectEntry(deviceListObject, i,
            		missingDevicesListObject,0,exceptionInfo);
        	    if (dynlen(exceptionInfo)) return;
		    // the node creation routine will take care of everything,
		    // so we can safely mark it as "no more postprocess needed"
		    deviceListObject[fwConfigurationDB_DLO_REF_STATUS][i]=0;

		} else {
		    // it's a leaf, and alias is not mapped to anything yet
		    deviceListObject[fwConfigurationDB_DLO_REF_STATUS][i]=1;
		}
	    } else {
		// alias is already mapped to some device...
		if (devDp!=deviceListObject[fwConfigurationDB_DLO_REFDP][i]) {
		    // alias already exists and need to be unmapped, but
		    // only for non-FwNode devices...
		    if ( (type=="FwNode") && (dpTypeName(devDp)=="FwNode")) {
			// for FwNodes this is OK, we could re-use them,
			// we will only need to change the alias
			deviceListObject[fwConfigurationDB_DLO_REF_STATUS][i]=0;
		    } else {
			deviceListObject[fwConfigurationDB_DLO_REF_STATUS][i]=2;
		    }
		}else{
		    // alias already mapped and OK
		    deviceListObject[fwConfigurationDB_DLO_REF_STATUS][i]=0;
		}
	    }



	} else {
	    fwException_raise(exceptionInfo,"ERROR","verifyDatapoints: hierarchy "+hierarchyType+" not supported","");
	    return;
	}

    } // end of loop

}

/** Creates missing devices in PVSS, so the structure reflects the one in the DB

note that it should work only for the local system

the systemName parameter is only meaning for logical hierarchy:
it indicates which type of logical hierarchy should be loaded: the one that includes system name,
or the one that does not (empty systemName). In the latter case, only the leaves that are currently
mapped to devices that are present on the current system are loaded, plus all the "branch" nodes that
lead to them...

@Deprecated use @ref fwConfigurationDB_updateDeviceConfigurationFromDB instead
*/
void fwConfigurationDB_updateDeviceHierarchyFromDB(string topDevice, string hierarchyType, dyn_string &exceptionInfo, string systemName="")
{
    fwException_raise(exceptionInfo, "ERROR","fwConfigurationDB_updateDeviceHierarchyFromDB is deprecated","");
    return;
    /*
    time t0;
    _fwConfigurationDB_startFunction("updateDeviceHierarchyFromDB", t0);

    if (fwConfigurationDB_progress(fwConfigurationDB_OPER_ApplyHierarchyToSystem,"Applying hierarchy in system", 10.0, exceptionInfo)) return;

    dyn_string dbDeviceDpNames,dbDeviceTypes,dbDeviceDetails,dbDeviceComments;
    dyn_int dbDeviceIds;

    if ( (hierarchyType!=fwDevice_HARDWARE) && (hierarchyType!=fwDevice_LOGICAL)) {
	fwException_raise(exceptionInfo,"ERROR","Hierarchy type: "+hierarchyType+" not supported.","");
        return;
    };

    // find out the system name of the top device,
    // and check if it is local system...
    string sysName=getSystemName();
    if (topDevice=="") {
	if (hierarchyType==fwDevice_HARDWARE) {
    	    topDevice=sysName;
	} // otherwise: we may have a LOGICAL hierarchy with common root...
    }

    dyn_dyn_mixed deviceListObject, missingDeviceListObject;
    _fwConfigurationDB_ensureDeviceListObjectValid(deviceListObject);
    _fwConfigurationDB_ensureDeviceListObjectValid(missingDeviceListObject);
    // find the devices in the database:
    fwConfigurationDB_extractHierarchyFromDB(topDevice, hierarchyType,
                                             deviceListObject,
                                             exceptionInfo);
    if (dynlen(exceptionInfo)) return;

    _fwConfigurationDB_verifyDatapoints(hierarchyType,
                                      deviceListObject, missingDeviceListObject,
                                      exceptionInfo,TRUE);

    if (dynlen(exceptionInfo)) return;

    _fwConfigurationDB_createDevices(missingDeviceListObject,exceptionInfo);
    if (dynlen(exceptionInfo)) return;
    _fwConfigurationDB_(deviceListObject,exceptionInfo);
    if (dynlen(exceptionInfo)) return;

    if (fwConfigurationDB_progress(fwConfigurationDB_OPER_ApplyHierarchyToSystem,"Applied hierarchy in system", 100.0, exceptionInfo)) return;

    _fwConfigurationDB_endFunction("updateDeviceHierarchyFromDB", t0);
*/
}





/////////////////
void _fwConfigurationDB_createDevices(dyn_dyn_mixed deviceListObject, string hierarchyType, dyn_string &exceptionInfo)
{

    int maxdev=dynlen(deviceListObject[fwConfigurationDB_DLO_DPNAME]);
    for (int i=1;i<=maxdev;i++){
        string dpname=_fwConfigurationDB_NodeNameWithoutSystem(deviceListObject[fwConfigurationDB_DLO_DPNAME][i]);
        string dptype=deviceListObject[fwConfigurationDB_DLO_DPTYPE][i];
        string model=deviceListObject[fwConfigurationDB_DLO_MODEL][i];
        string comment=deviceListObject[fwConfigurationDB_DLO_COMMENT][i];
        if (i%10==1) {
            if (fwConfigurationDB_progress(fwConfigurationDB_OPER_ApplyHierarchyToSystem,"Creating devices",
                                           15.0+35.0*i/maxdev, exceptionInfo)) return;
        }

        if (dptype=="FwNode") {
    	    if (hierarchyType==fwDevice_HARDWARE) {
    		// we do not create devices!
    		DebugN("We do not create ROOT node in HW hierarchy",dpname);
    		continue;
    	    }

    	    // otherwise: we have logical hierarchy

	    // special treatment - we need to use a special function to create the nodes...
            if (!g_fwNode_INITIALIZED) fwNode_initialize();
            string parent,name;
            fwDevice_getParent(dpname, parent, exceptionInfo);
            if (dynlen(exceptionInfo)) return;
            name=deviceListObject[fwConfigurationDB_DLO_NAME][i];

            fwNode_createLogical( name, parent, makeDynString("fwDevice/fwDeviceManage"),
                                  makeDynString("fwDevice/fwDeviceManage"),exceptionInfo);
            if (dynlen(exceptionInfo)) return;

        } else if (model=="" || model=="DATAPOINT"){
        	// non-framework datapoint
            int rc=dpCreate(dpname,dptype);
            if (rc) {fwException_raise(exceptionInfo,"ERROR","Failed to create datapoint "+dpname,"");return;}
            if (comment!="") dpSetComment ( dpname+".",comment);
        } else {

            // framework device...
            dyn_string deviceObject;
            deviceObject[fwDevice_DP_NAME]=dpname;
            deviceObject[fwDevice_DP_TYPE]=dptype;
            deviceObject[fwDevice_MODEL]=model;
            deviceObject[fwDevice_COMMENT]=comment;
            //DebugN("going to create Fw Device",deviceObject);
            fwDevice_create(deviceObject, makeDynString(""),exceptionInfo);
            if (dynlen(exceptionInfo)) return;
        }
    }
    if (fwConfigurationDB_progress(fwConfigurationDB_OPER_ApplyHierarchyToSystem,"DONE",100.0, exceptionInfo)) return;

}


void _fwConfigurationDB_configureDevices(dyn_dyn_mixed deviceListObject, string hierarchyType, dyn_string &exceptionInfo,
    int options=fwConfigurationDB_deviceConfig_ALLDEVPROPS)
{
    int maxdev=dynlen(deviceListObject[fwConfigurationDB_DLO_DPNAME]);
    // set defaults
    /////
    if (hierarchyType==fwDevice_HARDWARE) {
        //if (fwConfigurationDB_progress(fwConfigurationDB_OPER_ApplyHierarchyToSystem,"Setting defaults", 50.0, exceptionInfo)) return;

        dyn_string dpsForDefaults;
        dyn_string dptypesForDefaults;
        dyn_string dpmodelsForDefaults;

        dyn_string dpesWithConfigs;
        dyn_int    ipropsWithConfigs;



        for (int i=1;i<=maxdev;i++){
            string dpname=deviceListObject[fwConfigurationDB_DLO_DPNAME][i];
            string model=deviceListObject[fwConfigurationDB_DLO_MODEL][i];
//            string type=deviceListObject[fwConfigurationDB_DLO_TYPE][i];
            string dptype=deviceListObject[fwConfigurationDB_DLO_DPTYPE][i];
            dyn_string propNames=deviceListObject[fwConfigurationDB_DLO_PROPNAMES][i];
            dyn_int propIds=deviceListObject[fwConfigurationDB_DLO_PROPIDS][i];

            if (dptype=="FwNode") {
        	//DebugN("nothing to configure for FwNode",dpname);
                continue;
            }
            if (dynlen(propIds)!=0) {
                // check if one wants to use the settings...
                if ( (options & fwConfigurationDB_deviceConfig_ALLDEVPROPS)!=0 ) {

            	    for (int j=1;j<=dynlen(propIds);j++) {
                	dynAppend(dpesWithConfigs,dpname+propNames[j]);
                	dynAppend(ipropsWithConfigs,propIds[j]);
            	    }
            	} else {
            	    // the user requested loading none of properties!
            	    // but he may still want to use the Framework defaults...
                if ( (model!="DATAPOINT") && (options & fwConfigurationDB_deviceConfig_FW_DEFAULTS)) {
                    dynAppend(dpsForDefaults,dpname);
                    dynAppend(dptypesForDefaults,deviceListObject[fwConfigurationDB_DLO_DPTYPE][i]);
                    dynAppend(dpmodelsForDefaults,deviceListObject[fwConfigurationDB_DLO_MODEL][i]);
            	    }

            	}

            } else {
                // we may want to fall-back to defaults for framework devices
                if ( (model!="DATAPOINT") && (options & fwConfigurationDB_deviceConfig_FW_DEFAULTS)) {
                	dynAppend(dpsForDefaults,dpname);
                	dynAppend(dptypesForDefaults,deviceListObject[fwConfigurationDB_DLO_DPTYPE][i]);
                	dynAppend(dpmodelsForDefaults,deviceListObject[fwConfigurationDB_DLO_MODEL][i]);

                } else {
                    // NO POSSIBLE OPTION TO CONFIGURE THE DEVICE
                }
            }
        }


	// The defaults should only be applied to the devices that have no DB data asssociated
	//  (e.g. they were stored with "hierarchy only")
	// Note that the default configuration does not work for certain devices, such as CAEN EASY thingies
	// configure the devices with Fw defaults

    if (fwConfigurationDB_progress(fwConfigurationDB_OPER_LoadDeviceProperties,"Configuring devices", 10.0,
                                   exceptionInfo)) return;



	if (dynlen(dpsForDefaults)) {

    	    _fwConfigurationDB_configureFwDevicesWithDefaults(dpsForDefaults, dptypesForDefaults,
                                                    dpmodelsForDefaults, exceptionInfo);
    	    if (dynlen(exceptionInfo)) return;
	}


	if (dynlen(dpesWithConfigs)) {
    	    _fwConfigurationDB_configureDevicesFromDB(dpesWithConfigs, ipropsWithConfigs, exceptionInfo, options);
    	    if (dynlen(exceptionInfo)) return;
    	}

        //if (fwConfigurationDB_progress(fwConfigurationDB_OPER_ApplyHierarchyToSystem,"Setting defaults for "+dpname, 50.0+40.0*i/maxdev, exceptionInfo)) return;


    } else if (hierarchyType==fwDevice_LOGICAL) {
	// at first check if the linked devices in HARDWARE exist, (and if they are local)
        for (int i=1;i<=maxdev;i++) {
            string type      = deviceListObject[fwConfigurationDB_DLO_DPTYPE][i];
            string aliasName= _fwConfigurationDB_NodeNameWithoutSystem(deviceListObject[fwConfigurationDB_DLO_DPNAME][i]);

            dyn_string exceptionInfo2;
            string refDp=_fwConfigurationDB_NodeNameWithSystem(deviceListObject[fwConfigurationDB_DLO_REFDP][i],getSystemName(),exceptionInfo2);
            if (dynlen(exceptionInfo2)) {
        	deviceListObject[fwConfigurationDB_DLO_REF_STATUS][i]=-1;// mark it as invalid...
		// add some more information
		/*
                fwException_raise(exceptionInfo,"ERROR","Cannot create alias \n"+aliasName+
            		    " \n target device "+deviceListObject[fwConfigurationDB_DLO_REFDP][i]+
            		    " is on remote system.","");
                return;
                */
                DebugN("WARNING! Alias "+aliasName+ " points to remote "+deviceListObject[fwConfigurationDB_DLO_REFDP][i]+" - skipping it");
                continue;
            }
            if (type!="FwNode") {
                if(!dpExists(refDp)) {
                    fwException_raise(exceptionInfo,"ERROR","Cannot create alias \n"+aliasName+"\n target device "+refDp+" does not exist.","");
                    return;
                }
            }
        }

        for (int i=1;i<=maxdev;i++) {

            string aliasName= _fwConfigurationDB_NodeNameWithoutSystem(deviceListObject[fwConfigurationDB_DLO_DPNAME][i]);
            int status=deviceListObject[fwConfigurationDB_DLO_REF_STATUS][i];

            if (status==0) continue;

            if (status==-1) continue; // this is the case for remote system

            string refDpName= _fwConfigurationDB_NodeNameWithoutSystem(deviceListObject[fwConfigurationDB_DLO_REFDP][i]);
            string dpName;

            if (status==2) {

                dpName=dpSubStr(dpAliasToName(aliasName),DPSUB_DP); // dp that currently has this dp
                if (deviceListObject[fwConfigurationDB_DLO_DPTYPE][i]=="FwNode") {
                    // we even need to re-create the item!
                    dpDelete(dpName);

		    // bugfix #14832
		    //dpCreate(aliasName,"FwNode");
		    //dpSetAlias(aliasName+".",aliasName);

                    if (!g_fwNode_INITIALIZED) fwNode_initialize();
                    string parent,name;
                    fwDevice_getParent(aliasName, parent, exceptionInfo);
                    if (dynlen(exceptionInfo)) return;
                    name=deviceListObject[fwConfigurationDB_DLO_NAME][i];
                    fwNode_createLogical( name, parent, makeDynString("fwDevice/fwDeviceManage"),
                                          makeDynString("fwDevice/fwDeviceManage"),exceptionInfo);
                    if (dynlen(exceptionInfo)) return;
                } else {
            	    //DebugN("removing the alias from",dpName);
                    dpSetAlias(dpName+".","");
                    //DebugN("then setting the alias",aliasName,refDpName);
            	    dpSetAlias(refDpName+".",aliasName);

                }
            } else { // status!=2
        	//DebugN("setting the alias",aliasName,refDpName);
                dpSetAlias(refDpName+".",aliasName);
            }

        }
    }


}

/////////////////


void _fwConfigurationDB_getDBRootNodeId(string hierarchyType, int &rootNode,
                                        dyn_string &exceptionInfo, string systemName="")
{
    if (!mappingHasKey(g_fwConfigurationDB_DBHierarchyIDs,hierarchyType)) {
	fwException_raise(exceptionInfo,"ERROR","Hierarchy type: "+hierarchyType+" not supported in this ConfigurationDB","");
    	return;
    }

    rootNode=0;
    string queryRootNodeSql;

if ((hierarchyType==fwDevice_LOGICAL) && systemName=="") {
    // NOTE! in a LOGICAL hierarchy with common root, the DPNAME for the root is "",
    // but the NAME(!) of the root is "/"!
    // because we do this query on ITEMS table rather than on V_ITEM_NAMES view,
    // we need to use name, and hence have specific query!
	queryRootNodeSql="SELECT ID FROM ITEMS WHERE NAME=\'/\'"+
    	    " AND HVER="+g_fwConfigurationDB_DBHierarchyIDs[hierarchyType];
    } else {
	if (systemName=="") systemName=getSystemName();

	queryRootNodeSql="SELECT ID FROM ITEMS WHERE NAME=\'"+systemName+"\'"+
    	    " AND HVER="+g_fwConfigurationDB_DBHierarchyIDs[hierarchyType];
    }
    dyn_dyn_mixed aRootNode;
    _fwConfigurationDB_executeDBQuery(queryRootNodeSql,g_fwConfigurationDB_DBConnection, aRootNode, exceptionInfo);
    if (dynlen(exceptionInfo)) return;

    if (dynlen(aRootNode)==0) {
        fwException_raise(exceptionInfo,"ERROR",
                          "Inconsistency: no root node in DB for system "+systemName,"");
        return;
    } else  if (dynlen(aRootNode)>1){
        fwException_raise(exceptionInfo,"ERROR",
                          "Inconsistency: multiple root nodes in DB for system "+systemName,"");
        return;
    } else {
        rootNode=aRootNode[1][1];
    };
}




/** This one resolves the DB id's of items and
reports error if device was not found...

@param hierarchyType is dummy as of now!
*/
void _fwConfigurationDB_DBFindItems(string hierarchyType, dyn_string deviceList, dyn_int &itemIds,
                                    dyn_string &exceptionInfo)
{
    if (dynlen(deviceList)==0) return;

    time t0=getCurrentTime();
    if (fwConfigurationDB_progress(fwConfigurationDB_OPER_ResolveHierarchy,"Resolving device hierarchy", 10.0,
                                   exceptionInfo)) return;

    dynClear (itemIds);
    dyn_string uDeviceList=deviceList;
    dynUnique(uDeviceList);
    if (dynlen(uDeviceList)<1) return;


    string sDeviceList=_fwConfigurationDB_listToSQLString("DPNAME", uDeviceList);

//    string queryDevicesSql="SELECT DPNAME, ID FROM V_ITEM_NAMES WHERE "+
//        " HVER="+g_fwConfigurationDB_DBHierarchyIDs[hierarchyType]+" AND "+sDeviceList;
    string queryDevicesSql="SELECT DPNAME, ID FROM V_ITEM_NAMES WHERE "+sDeviceList;

    dyn_dyn_mixed aRecords;
    _fwConfigurationDB_executeDBQuery(queryDevicesSql,g_fwConfigurationDB_DBConnection, aRecords, exceptionInfo,2,TRUE);
    if (dynlen(exceptionInfo)) return;

    dyn_string dbDevices;
    dyn_int dbIds;

    if (dynlen(aRecords)>=2) {
	dbDevices=aRecords[1];
	dbIds=aRecords[2];
    }

    // and now resolve the names
    for (int i=1;i<=dynlen(deviceList);i++) {
        int idx=dynContains(dbDevices,deviceList[i]);
        if (idx>0) {
            itemIds[i]=dbIds[idx];
        } else {
    	    fwException_raise(exceptionInfo,"ERROR","Device not found in DB:\n"+deviceList[i],"");
        }
    };
    if (fwConfigurationDB_progress(fwConfigurationDB_OPER_ResolveHierarchy,"Resolved device hierarchy", 100.0,
                                   exceptionInfo)) return;

    time t1=getCurrentTime();
    time dt=t1-t0;
//DebugN("Resolving IDs of "+dynlen(uDeviceList)+" items took "+minute(dt)+":"+second(dt)+":"+milliSecond(dt));
}


/**
This one is used when storing the devices in DB, it assigns new
identifiers to the devices that are not present, then adjusts
parent pointers, etc.
It will also resolve the ID's of DPElements, if they are defined
*/
void _fwConfigurationDB_DBAssignItemIds(string hierarchyType, dyn_dyn_mixed &deviceListObject, dyn_string &exceptionInfo, string systemName="")
{

    _fwConfigurationDB_ensureDeviceListObjectValid(deviceListObject);
    if ( (systemName=="") && (hierarchyType==fwDevice_HARDWARE)) systemName=getSystemName();

    // find the root node for this system;
    int rootNode=0;
    _fwConfigurationDB_getDBRootNodeId(hierarchyType,rootNode, exceptionInfo, systemName);
    if (dynlen(exceptionInfo)) return;

    if (rootNode==0) {
	fwException_raise(exceptionInfo,"ERROR","Cannot find root node: "+systemName+" with hierarchy:"+hierarchyType,"");
	return;
    }

    // assign new id's to the devices.
    int nItems=dynlen(deviceListObject[fwConfigurationDB_DLO_DPNAME]);
    _fwConfigurationDB_getBatchOfSequenceNumbers(g_fwConfigurationDB_DBConnection, "ITEMS_ID_SEQ", nItems,
			    deviceListObject[fwConfigurationDB_DLO_ITEMID], exceptionInfo);
    if (dynlen(exceptionInfo)) return;



    //  fix the parent id's


    // we should firstly set the parents from the new ones being inserted,
    // then for remaining ones we should make a "guided" select with
    // dpnames specified. It will be much more performant than
    // "select *" - especially for the cases where a lot of devices
    // is already stored in DB...


    // sort-out the id's of the ones that were just given an id,
    // form a parallel list storing parent names...
    // and also a list suitable for inclusion in SQL Statement

    dyn_string parentDpNames;
    string sqlParentDpNames;
    for (int i=1;i<=dynlen(deviceListObject[fwConfigurationDB_DLO_DPNAME]);i++) {

        if(deviceListObject[fwConfigurationDB_DLO_MODEL][i]=="DATAPOINT"){
	    // this is non-framework device... we cannot rely on Framework hierarchies
	    // and we need to set its parent to rootNode
            deviceListObject[fwConfigurationDB_DLO_PARENTID][i]=rootNode;
	    continue;
	}

        string parentDpName;
        fwDevice_getParent(deviceListObject[fwConfigurationDB_DLO_DPNAME][i], parentDpName, exceptionInfo);
        if (dynlen(exceptionInfo)) return;

	if ( (parentDpName=="") || (parentDpName==systemName) ) {
            deviceListObject[fwConfigurationDB_DLO_PARENTID][i]=rootNode;
            continue;
        }


        // try with the newly created devices
        int idx=dynContains(deviceListObject[fwConfigurationDB_DLO_DPNAME],parentDpName);
        if (idx>=1) {
            deviceListObject[fwConfigurationDB_DLO_PARENTID][i] = deviceListObject[fwConfigurationDB_DLO_ITEMID][idx];
            continue;
        }

	// otherwise, we'll try to get them from the database.
	// in order to do that, we need to prepare a list
	// of devices to be queried...
	// we also mark that there is no id yet, by setting it to 0
	deviceListObject[fwConfigurationDB_DLO_PARENTID][i] = 0;

	if (!dynContains(parentDpNames, parentDpName)) {
	    sqlParentDpNames=sqlParentDpNames+"\'"+parentDpName+"\'"+",";
	}
	parentDpNames[i]=parentDpName;

    };

    // make a query only if there is anything to query...
    if (sqlParentDpNames!="") {
	// remove the trailing coma ...
	sqlParentDpNames=strrtrim(sqlParentDpNames,",");

	string queryParents="SELECT DPNAME,ID FROM V_ITEM_NAMES  "+
    	    " WHERE HVER="+g_fwConfigurationDB_DBHierarchyIDs[hierarchyType]+
	    " AND dpname IN ("+sqlParentDpNames+")";
	dyn_dyn_mixed aParents;
	_fwConfigurationDB_executeDBQuery(queryParents,g_fwConfigurationDB_DBConnection, aParents, exceptionInfo,2,TRUE);
	if (dynlen(exceptionInfo)) return;
	if (dynlen(aParents)<1) {
	    // ensure that the structure is ok...
	    aParents[1]=makeDynString();
	    aParents[2]=makeDynInt();
	}


	// complete the parent ids...
	for (int i=1;i<=dynlen(deviceListObject[fwConfigurationDB_DLO_DPNAME]);i++) {
	    if (deviceListObject[fwConfigurationDB_DLO_PARENTID][i]!=0) continue;
	    int idx=dynContains(aParents[1],parentDpNames[i]);
	    if (idx<1) {
		fwException_raise(exceptionInfo,"ERROR","Cannot resolve parent id:"+parentDpNames[i],"");
		return;
	    }
	    deviceListObject[fwConfigurationDB_DLO_PARENTID][i]=aParents[2][idx];
	}
    }

    if (dynlen(exceptionInfo)) return;

}

void _fwConfigurationDB_resolveLogicalIds(dyn_dyn_mixed &deviceListObject, dyn_string &exceptionInfo, string systemName)
{

    // the dpalias->dpname thing was not resolved yet... do it!
    for (int i=1;i<=dynlen(deviceListObject[fwConfigurationDB_DLO_DPNAME]);i++) {
	string itemname=deviceListObject[fwConfigurationDB_DLO_DPNAME][i];
	string dpname=dpAliasToName(itemname);
	dpname=dpSubStr(dpname,DPSUB_SYS_DP);
	deviceListObject[fwConfigurationDB_DLO_REFDP][i]=dpname;
    }


    _fwConfigurationDB_ensureDeviceListObjectValid(deviceListObject);

    dyn_int refIds,refIdx;
    dyn_string refDPNames;
    // we will look only for the ones that are not Nodes, because they are not stored in HW view!
    for (int i=1;i<=dynlen(deviceListObject[fwConfigurationDB_DLO_REFDP]);i++) {
    	if (deviceListObject[fwConfigurationDB_DLO_DPTYPE][i]=="FwNode") {
	    // give a link to itself!
	    deviceListObject[fwConfigurationDB_DLO_REFID][i]=deviceListObject[fwConfigurationDB_DLO_ITEMID][i];
	    continue;
	}
	dynAppend(refIdx,i);
	dynAppend(refDPNames,deviceListObject[fwConfigurationDB_DLO_REFDP][i]);
    }


     _fwConfigurationDB_DBFindItems(fwDevice_HARDWARE, refDPNames, refIds, exceptionInfo);
    if (dynlen(exceptionInfo)) return;
    for (int i=1;i<=dynlen(refIdx);i++) {
	deviceListObject[fwConfigurationDB_DLO_REFID][refIdx[i]]=refIds[i];
    }


}



/** Creates devices in DB

The function stores the devices in the appropriate hierarchy, without storing
their properties.
Note that the devices that are already present in the db will not be re-created.

CONVENTIONS:
     1) for HARDWARE hierarchy:
        *) systemName needs to be set. "" is equal to passing getSystemName()
        *) specifying the name of other (remote) system allows to save its hierarchy!
        *) topDevice and deviceDpNames needs to contain system name
        *) if sysname is not specified at all - use the one from systemName
        *) if sysname is included but differs from systemName: report an error
     2) for LOGICAL hierarchy
        A) when systemName!="" - use specified system name
           *) topDevice and deviceDpNames need to contain system name
           *) if sysname not specified - complete it from systemName
           *) if if differs: report an error
        B) when systemName=="", we have a hierarchy with common root across all systems
           (i.e. logical hierarchy without system names)
           *) topDevice and deviceDpNames must not include system name
           *) we simply cut it away if it was passed

@param topDevice - a "hint" information that tells where to start verification of whether device
		    exists, etc. Empty string ("") means the top of hierarchy
*/
void _fwConfigurationDB_saveDeviceHierarchyToDB(string topDevice, string hierarchyType, dyn_string deviceDpNames,
                                         dyn_string &exceptionInfo, string systemName, dyn_dyn_mixed &deviceListObject)
{

    time t0;
    _fwConfigurationDB_startFunction("saveDeviceHierarchyToDB", t0);

    if (fwConfigurationDB_progress(fwConfigurationDB_OPER_SaveHierarchyToDB,"Saving hierarchy in DB", 0.0,
        exceptionInfo)) return;

    _fwConfigurationDB_ensureDeviceListObjectValid(deviceListObject);
    if (hierarchyType==fwDevice_LOGICAL) {
	_fwConfigurationDB_checkCreateCommonRootNodeForLogicalHierarchy(exceptionInfo);
        if (dynlen(exceptionInfo)) return;

	if (systemName=="") {
	    //unified-root logical hierarchy
	    if (topDevice=="") {
		//topDevice="/"; // NO! The top of the unified-root hierarchy (as "DPNAME") is empty string! It is "NAME" that is "/"
	    } else {
		topDevice= _fwConfigurationDB_NodeNameWithoutSystem(topDevice);
	    }
	    for (int i=1;i<=dynlen(deviceDpNames);i++) {
		deviceDpNames[i]=_fwConfigurationDB_NodeNameWithoutSystem(deviceDpNames[i]);
	    }
	} else { // logical hierarchy with sys names
	    topDevice=_fwConfigurationDB_NodeNameWithSystem(topDevice, systemName, exceptionInfo);
	    if (dynlen(exceptionInfo)) return;
	    for (int i=1;i<=dynlen(deviceDpNames);i++) {
		deviceDpNames[i]=_fwConfigurationDB_NodeNameWithSystem(deviceDpNames[i], systemName, exceptionInfo);
		if (dynlen(exceptionInfo)) return;
	    }
	}

    } else if (hierarchyType==fwDevice_HARDWARE) {
	_fwConfigurationDB_DBCheckCreateSystemNode(fwDevice_HARDWARE,exceptionInfo);
        if (dynlen(exceptionInfo)) return;

	if (systemName=="") systemName=getSystemName();
	topDevice=_fwConfigurationDB_NodeNameWithSystem(topDevice, systemName, exceptionInfo);
	if (dynlen(exceptionInfo)) return;
	for (int i=1;i<=dynlen(deviceDpNames);i++) {
	    deviceDpNames[i]=_fwConfigurationDB_NodeNameWithSystem(deviceDpNames[i], systemName, exceptionInfo);
	    if (dynlen(exceptionInfo)) return;
	}

    } else {
	fwException_raise(exceptionInfo,"ERROR","Unsupported hierarchy type: "+hierarchyType,"");
	return;
    }


    // separate the ones that exist and the ones that does not exist
    dyn_dyn_mixed missingDevicesListObject;
    _fwConfigurationDB_ensureDeviceListObjectValid(missingDevicesListObject);
    dyn_string missingDevicesList;
    if (fwConfigurationDB_progress(fwConfigurationDB_OPER_SaveHierarchyToDB,"Resolving devices in DB",10.0, exceptionInfo)) return;
    fwConfigurationDB_findDevicesInDB (topDevice, hierarchyType, deviceDpNames,
                                       deviceListObject, missingDevicesList,
                                       exceptionInfo, systemName);
    if (dynlen(exceptionInfo)) return;

    if (fwConfigurationDB_progress(fwConfigurationDB_OPER_SaveHierarchyToDB,"Verifying existing devices in DB",30.0, exceptionInfo)) return;
    // verify that the ones that exist are OK...
    // maybe we should not return an error, but rather update
    // the information ? or suggest creating new hierarchy?

    anytype dummyMissing;
    _fwConfigurationDB_verifyDatapoints (hierarchyType, deviceListObject, dummyMissing, exceptionInfo,TRUE);
    if (dynlen(exceptionInfo)) return;

    // stop here if there is nothing to store...
    if ( dynlen(missingDevicesList)==0) {
	fwConfigurationDB_progress(fwConfigurationDB_OPER_SaveHierarchyToDB,"Nothing to store",100.0, exceptionInfo);
	fwConfigurationDB_progress(fwConfigurationDB_OPER_UpdateDBHierarchyInfo,"Nothing to update", 100.0,exceptionInfo);
	_fwConfigurationDB_endFunction("saveDeviceHierarchyToDB", t0);
	return;
    }


    if (fwConfigurationDB_progress(fwConfigurationDB_OPER_SaveHierarchyToDB,"Resolving device IDs",50.0, exceptionInfo)) return;


    // for the missing ones, complete the information about the types, etc
    // note, we do not use the information about missing devices, gathered in
    // the function above!
    fwConfigurationDB_expandToDeviceListObject(hierarchyType, missingDevicesList, missingDevicesListObject,exceptionInfo);
    if (dynlen(exceptionInfo)) return;

    _fwConfigurationDB_DBAssignItemIds(hierarchyType,missingDevicesListObject, exceptionInfo,systemName);
    if (dynlen(exceptionInfo)) return;





    if (dynlen(missingDevicesList) > 0 ) {
	_fwConfigurationDB_saveItemsToDB(missingDevicesListObject, hierarchyType, exceptionInfo);
	if (dynlen(exceptionInfo)) return;
    }



/*
    // trigger the update of the materialized view:
    _fwConfigurationDB_updateHierarchyView(g_fwConfigurationDB_DBConnection, exceptionInfo);
    if (dynlen(exceptionInfo)) return;
*/

    // the missing devices were stored by now, re-combine them
    // to the deviceListObject...
    for (int i=1;i<=fwConfigurationDB_DLO_MAX_IDX;i++) {
	dyn_mixed row=missingDevicesListObject[i];
	dynAppend(deviceListObject[i],row);
    }


    if (fwConfigurationDB_progress(fwConfigurationDB_OPER_SaveHierarchyToDB,"Saved hierarchy in DB", 100.0,
        exceptionInfo)) return;

    _fwConfigurationDB_endFunction("saveDeviceHierarchyToDB", t0);

}


void fwConfigurationDB_saveReferences(string configurationName, dyn_dyn_mixed deviceListObject, dyn_string &exceptionInfo)
{
    // choose the things to store...
    dyn_string devices;
    dyn_string aliases;
    for (int i=1;i<=dynlen(deviceListObject[fwConfigurationDB_DLO_DPNAME]);i++) {
	if (deviceListObject[fwConfigurationDB_DLO_DPTYPE][i]=="FwNode") continue;
	if (deviceListObject[fwConfigurationDB_DLO_REFID][i]==0) continue;
	dynAppend(aliases,deviceListObject[fwConfigurationDB_DLO_DPNAME][i]);
	dynAppend(devices,deviceListObject[fwConfigurationDB_DLO_REFDP][i]);
    }

    dyn_dyn_mixed dummyOutput;
    fwConfigurationDB_callPlSqlApi( "setReferences",
                        makeDynMixed(configurationName),
                        "S1,S2", "",
                        makeDynMixed(aliases,devices), dummyOutput,
                        exceptionInfo);
    if (dynlen(exceptionInfo)) return;

}


/** Returns the history of hierarchies mapping for specipied period of time,
and for certain configuration.

@param configName	the name of static configuration
@param hierarchyType    type of hierarchy (eg. fwDevice_LOGICAL)
@param startTime	start of queried period of time
@param endTime		end of queried period of time. Passing 0 as a parameter means: up to now
@param itemNames	list of logical names of devices being queried
@param references	the result will be put in this variable on return; explanation of the output format below
@param exceptionInfo	standard exception handling variable


The data returned by the function has a format of 4-column array:
@li references[1] contain item names (in logical view)
@li references[2] contain corresponding dp names from hardware view
@li references[3] contain the start of validity period for this mapping
@li references[4] contain the end of validity period for this mapping

The rows are sorted by logical dpname and start of validity.

Example:
<TABLE style="font-size:8;">
    <TR bgcolor="yellow"> <td>references[1]</td> <td>references[2]</td> <td>references[3]</td> <td>references[4]</td></tr>
    <tr><td>SubSys/straw1</td> <td>dist_1:CAEN/crate01/board00/channel001</td> <td>5 Jan 2006 </td> <td> 6 Jan 2006</td></tr>
    <tr><td>SubSys/straw1</td> <td>dist_1:CAEN/crate01/board00/channel011</td> <td>6 Jan 2006 </td> <td>10 Jan 2006 </td></tr>
    <tr><td>SubSys/straw1</td> <td>dist_1:CAEN/crate01/board10/channel001</td> <td>10 Jan 2006</td> <td> </td></tr>
    <tr><td>SubSys/straw2</td> <td>dist_1:CAEN/crate01/board01/channel002</td> <td>5 Jan 2006</td> <td> </td></tr>
    <tr><td>SubSys/straw3</td> <td>dist_1:CAEN/crate01/board01/channel003</td> <td>5 Jan 2006</td> <td> </td></tr>
</TABLE>
In this example, one can see that the SubSys/straw1 aparently had some problems: it was initially mapped
to first channel of first board, then on 6th of January 2006, reconnected to eleventh channel of first board,
then again, on 10th of January 2006 it was reconnected to first channel of tenth board, and stays as such since then.
The other two straws were not touched and stay connected to channel 2 and 3 on first board...

*/
void fwConfigurationDB_getReferencesHistory( string configName, string hierarchyType, time startTime, time endTime,
dyn_string itemNames, dyn_dyn_mixed &references, dyn_string &exceptionInfo)
{
    if (!dynlen(itemNames)) {
	fwException_raise(exceptionInfo,"ERROR in fwConfigurationDB_getReferencesHistory","No devices specified to resolve","");
	return;
    }

    dyn_dyn_mixed aRecords;
    time tNull=0;
    anytype tStart, tEnd; // non-initialized anytype - means NULL
    if (startTime>0) tStart=startTime;
    if (endTime>0) tEnd=endTime;

    fwConfigurationDB_callPlSqlApi( "getReferenceHistory",
		makeDynMixed(configName,tStart,tEnd),
                "S1", "S1,S2,D1,D2",
                makeDynMixed(itemNames), aRecords,
                exceptionInfo);
    if (dynlen(exceptionInfo)) return;

    references = aRecords;
}


/** Store items in DB (LOW LEVEL!)

All ID's for items already need to be there.
The things it stores: item id, parent id, name, type, model (or detail of type), comment, dpid
Only stores ITEMS-related part; logical mapping, configs, etc are stored elsewhere.
*/
void _fwConfigurationDB_saveItemsToDB(dyn_dyn_mixed deviceListObject, string hierarchyType, dyn_string &exceptionInfo)
{

    // prepare the "insert" command:
    anytype insertDeviceCmd;
    string insertDeviceSql="INSERT INTO ITEMS (HVER,ID,PARENT,NAME,TYPE,DPT_ID,DETAIL,DESCRIPTION,DPID,DPNAME) "+
			   " VALUES (:HVER, :ID, :PARENT, ':NAME',':DPTYPE',"+
			   " (SELECT DPT_ID FROM DEVICE_TYPES WHERE DPTYPE=':DPTYPE' AND VALID_TO IS NULL),"+
			   " ':DETAIL',:COMMENT,:DPID,':DPNAME')";

    _fwConfigurationDB_startCommand(insertDeviceSql, g_fwConfigurationDB_DBConnection,
                                    insertDeviceCmd, exceptionInfo);
    if (dynlen(exceptionInfo)) {rdbRollbackTransaction(g_fwConfigurationDB_DBConnection);return;}
    //DebugN("To Store:",missingDevicesListObject);

    for (int i=1;i<=dynlen(deviceListObject[fwConfigurationDB_DLO_DPNAME]);i++) {
	    if (i%100==1) {
		//DebugN(i,dynlen(missingDevicesListObject[fwConfigurationDB_DLO_DPNAME]));
    		if (fwConfigurationDB_progress(fwConfigurationDB_OPER_SaveHierarchyToDB,"Saving devices in DB",
        	    70+20.0*i/dynlen(deviceListObject[fwConfigurationDB_DLO_DPNAME]), exceptionInfo)) return;
	    }

    	    mapping params;
    	    params[":HVER"]     =   g_fwConfigurationDB_DBHierarchyIDs[hierarchyType];
    	    params[":ID"]       =   deviceListObject[fwConfigurationDB_DLO_ITEMID][i];
    	    params[":PARENT"]   =   deviceListObject[fwConfigurationDB_DLO_PARENTID][i];
    	    params[":NAME"]     =   deviceListObject[fwConfigurationDB_DLO_NAME][i];
    	    params[":DPTYPE"]   =   deviceListObject[fwConfigurationDB_DLO_DPTYPE][i];
    	    params[":DPNAME"]   =   deviceListObject[fwConfigurationDB_DLO_DPNAME][i];

    	    // fix #17872
    	    string escapedComment=deviceListObject[fwConfigurationDB_DLO_COMMENT][i];
    	    strreplace(escapedComment,"\'","\'\'");
    	    params[":COMMENT"]  =   "\'"+escapedComment+"\'";

    	    params[":DETAIL"]   =   deviceListObject[fwConfigurationDB_DLO_MODEL][i];

	    if (hierarchyType==fwDevice_HARDWARE)
    		params[":DPID"]     =  "\'"+deviceListObject[fwConfigurationDB_DLO_DPID][i]+"\'";
	    else
		params[":DPID"]     =   "NULL";
    	    _fwConfigurationDB_bindExecuteCommand(insertDeviceCmd, params, exceptionInfo);
    	    if (dynlen(exceptionInfo)) {rdbRollbackTransaction(g_fwConfigurationDB_DBConnection);return;}

	}; // end of for loop
	_fwConfigurationDB_finishCommand(insertDeviceCmd, exceptionInfo);
	if (dynlen(exceptionInfo)) {rdbRollbackTransaction(g_fwConfigurationDB_DBConnection);return;}

}


void fwConfigurationDB_getDeviceConfigurations(string hierarchyType,
	dyn_string &confNames, dyn_string &confDescriptions, dyn_int &confIds,
	dyn_string &exceptionInfo)
{
    //string sql="SELECT conf_tag, description, conf_id FROM config_desc "+" where hver="+g_fwConfigurationDB_DBHierarchyIDs[hierarchyType];
    string sql="SELECT conf_tag, description, conf_id FROM config_desc ";

    dyn_dyn_mixed aRecords;

    _fwConfigurationDB_executeDBQuery(sql,g_fwConfigurationDB_DBConnection, aRecords, exceptionInfo,3,TRUE);
    if (dynlen(exceptionInfo)) return;

    if (dynlen(aRecords)>=3) {
	confNames=aRecords[1];
	confDescriptions=aRecords[2];
	confIds=aRecords[3];
    }
}




/**
    @returns the device configuration id (CONF_ID);
*/
int _fwConfigurationDB_checkCreateDeviceConfiguration(string hierarchyType,
	string confName, string confDescription, dyn_string &exceptionInfo)
{

    // if configuration already exists, return the existing one:
    dyn_string confNames, confDescriptions;
    dyn_int confIds;
    int retVal;
    string sql;
    fwConfigurationDB_getDeviceConfigurations(hierarchyType,
		confNames, confDescriptions,confIds, exceptionInfo);
    if (dynlen(exceptionInfo)) return 0;

    int idx=dynContains(confNames, confName);
    // fix #17872
    string escapedConfDescription=confDescription;
    strreplace(escapedConfDescription,"\'","\'\'");

    if (idx<=0) {
        // configuration does note exist yet - create one
    dyn_int seqNumber;
    _fwConfigurationDB_getBatchOfSequenceNumbers(g_fwConfigurationDB_DBConnection,
	"CONF_ID_SEQ", 1, seqNumber, exceptionInfo);

    if (dynlen(exceptionInfo)) return 0;

        sql="INSERT INTO config_desc(conf_id,conf_tag,description) "+
		" VALUES( "+
		seqNumber[1]+","+
		"\'"+confName+"\',"+
		"\'"+escapedConfDescription+"\')";
        fwConfigurationDB_executeSqlSimple(sql, g_fwConfigurationDB_DBConnection,exceptionInfo);

        if (dynlen(exceptionInfo)) {
            dbRollbackTransaction(g_fwConfigurationDB_DBConnection);
            return 0;
        }
        retVal=seqNumber[1];
    } else {
        retVal=confIds[idx];
        // if new description given, set it (#32960)
        if (confDescription!="") {
            sql="UPDATE CONFIG_DESC SET DESCRIPTION=\'"+escapedConfDescription+"\' WHERE CONF_ID="+retVal;
    fwConfigurationDB_executeSqlSimple(sql, g_fwConfigurationDB_DBConnection,exceptionInfo);

    if (dynlen(exceptionInfo)) {
    	dbRollbackTransaction(g_fwConfigurationDB_DBConnection);
    	return 0;
    }
        }
    }
    return retVal;

}



void _fwConfigurationDB_checkSaveDpTypes(dyn_string dpTypes,dyn_int &dpTypeIds,
	    dyn_mixed &dpTypeElements, dyn_mixed &dpTypeElementIds, time date, dyn_string &exceptionInfo)
{
    /* Extract the information about the types from the database */
    if (!dynlen(dpTypes)) return;

    string dpTypesForSql=_fwConfigurationDB_listToSQLString("DPTYPE",dpTypes);
    dyn_dyn_mixed aRecords;
    // get the ones from DB...
    string sql="select dpt_id, develem_id,dptype,elementname,elementtype from v_device_configs" +
		" where "+dpTypesForSql+" order by dptype";

    // note that it may return types that do not contain elements (i.e. FwNode)

    _fwConfigurationDB_executeDBQuery(sql,g_fwConfigurationDB_DBConnection, aRecords, exceptionInfo,5,TRUE);
    if (dynlen(exceptionInfo)) {rdbRollbackTransaction(g_fwConfigurationDB_DBConnection);return;}
    //DebugN(aRecords);

    // regroup dpType data we got from the DB
    dyn_string dbDpTypes;
    dyn_int dbDpTypeIds;
    // the ones below are mixed, because each of them will contain elements of dyn_X type for each DPType
    dyn_mixed dbDpTypeElements, dbDpTypeElementIds,dbDpTypeElementTypes;

    if (dynlen(aRecords)>0) {
	string prevDpType="";
	dyn_string elementNames;
	dyn_int elementIds,elementTypes;
	int n=0;
	for (int i=1;i<=dynlen(aRecords[1]);i++) {
	    // optimized iteration through the results to build the lists
	    // of elements for each dptype;
	    // we take advantage of the fact that results were sorted by dpType...
	    string dpType=aRecords[3][i];
	    if (dpType!=prevDpType) {
		// i.e. next dpType
		prevDpType=dpType;
		dynClear(elementNames);
		dynClear(elementIds);
		dynClear(elementTypes);
		n++;
		dbDpTypes[n]=dpType;
		dbDpTypeIds[n]=aRecords[1][i];
	    }
    	    string elName=aRecords[4][i];
    	    // if the element is empty - skip it...
    	    if(elName!=""){
        	dynAppend(elementNames,aRecords[4][i]);
        	dynAppend(elementIds,aRecords[2][i]);
        	dynAppend(elementTypes,aRecords[5][i]);
    	    }
    	    // save the result:
    	    dbDpTypeElements[n]=elementNames;
    	    dbDpTypeElementIds[n]=elementIds;
    	    dbDpTypeElementTypes[n]=elementTypes;
	}
    }
    //DebugN("FromDB",dbDpTypes,dbDpTypeIds,dbDpTypeElements,dbDpTypeElementIds);


    /* Process the list of requested dpTypes. Identify the ones found   */
    /* in the database, and check if their data is up to date (compare) */

    dyn_mixed sysDpTypeElements,sysDpTypeElementTypes;

    dyn_int dbDifferingTypeIds; // we will use it to invalidate previous entries...
    dyn_string dpTypesToAdd;
    for (int i=1;i<=dynlen(dpTypes);i++){
	// find out the elements of the current dpType...
	dyn_string myElements;
	dyn_int myElementTypes;
	_fwConfigurationDB_getDPTElements2(dpTypes[i], myElements, myElementTypes,exceptionInfo, TRUE);
    	if (dynlen(exceptionInfo)) {rdbRollbackTransaction(g_fwConfigurationDB_DBConnection);return;}
    	sysDpTypeElementTypes[i]=myElementTypes;
    	sysDpTypeElements[i]=myElements;

	// check if the information about this dpType is in the database
	int idx=dynContains(dbDpTypes,dpTypes[i]);
	if (idx<1) {
	    // no. We'll need to add it...
	    dynAppend(dpTypesToAdd,dpTypes[i]);
	} else {
	    // yes, they are.
	    // We need to compare it with current dpType to check if it is up to date
	    bool differ=FALSE;
	    dyn_string dbElements=dbDpTypeElements[idx];
	    dyn_int dbElementTypes=dbDpTypeElementTypes[idx];

	    if (dynlen(myElements)!=dynlen(dbElements)) {
		differ=TRUE; // the number of elements differ
	    } else {
		// full scan of the list of elements, with type-checking
		for (int j=1;j<=dynlen(myElements);j++) {
		    int idx2=dynContains(dbElements,myElements[j]);
		    if (idx2<1) { // element not found
			differ=TRUE;
			break;
		    }
		    // check the type of the element:
		    if (myElementTypes[j]!=dbElementTypes[idx2]) {
			differ=TRUE;
			break;
		    }
		}
	    }
	    if (!differ) {
		// they match. we may already append it to the output!
		dpTypeIds[i]=dbDpTypeIds[idx];
		dpTypeElementIds[i]=dbDpTypeElementIds[idx];
		dpTypeElements[i]=dbDpTypeElements[idx];
	    } else {
		// they differ, therefore we will need to add a new entry ...
		dynAppend(dpTypesToAdd,dpTypes[i]);
		 // ... and mark the ones that will go out of date
		dynAppend(dbDifferingTypeIds, dbDpTypeIds[idx]);
	    }
	}
    } // end of for loop



    if (dynlen(dpTypesToAdd)==0) return;


    /* Add the missing/modified types */

    // get a batch of sequence numbers
    int nSeq=dynlen(dpTypesToAdd);
    dyn_int dpTypeSeqIds; // sequence number for properties...
    _fwConfigurationDB_getBatchOfSequenceNumbers(g_fwConfigurationDB_DBConnection, "DPT_ID_SEQ",
                                                 nSeq, dpTypeSeqIds , exceptionInfo);
    if (dynlen(exceptionInfo)) {rdbRollbackTransaction(g_fwConfigurationDB_DBConnection);return;}

    // -- prepare DB commands --
    anytype insertDpTypeCmd;
    string insertDpTypeSql="INSERT INTO DEVICE_TYPES (DPT_ID, DPTYPE, VALID_TO ) "+
			   " VALUES (:DPT_ID, :DPTYPE, :VALID_TO)";

    anytype insertDptElementCmd;
    string insertDptElementSql="INSERT INTO DEVICE_ELEMENTS (DEVELEM_ID, DPT_ID, ELEMENTNAME, ELEMENTTYPE ) "+
			   " VALUES (:DEVELEM_ID, :DPT_ID, :ELEMENTNAME, :ELEMENTTYPE)";

    _fwConfigurationDB_startCommand(insertDpTypeSql, g_fwConfigurationDB_DBConnection,
                                    insertDpTypeCmd, exceptionInfo);
    if (dynlen(exceptionInfo)) {rdbRollbackTransaction(g_fwConfigurationDB_DBConnection);return;}

    _fwConfigurationDB_startCommand(insertDptElementSql, g_fwConfigurationDB_DBConnection,
                                    insertDptElementCmd, exceptionInfo);
    if (dynlen(exceptionInfo)) {rdbRollbackTransaction(g_fwConfigurationDB_DBConnection);return;}

    // add the types:
    for (int i=1;i<=dynlen(dpTypesToAdd);i++) {
	// at first, insert the dptype itself...
    	mapping params;
	params[":DPT_ID"]   =   dpTypeSeqIds[i];
	params[":DPTYPE"]   =   "\'"+dpTypesToAdd[i]+"\'";
	params[":VALID_TO"]   =   "NULL";

    	_fwConfigurationDB_bindExecuteCommand(insertDpTypeCmd, params, exceptionInfo);
    	if (dynlen(exceptionInfo)) {rdbRollbackTransaction(g_fwConfigurationDB_DBConnection);return;}

	// then insert its the elements...

	// retrieve the list of elements and their types - we already extracted them above
	int idx=dynContains(dpTypes,dpTypesToAdd[i]);
    	dyn_string myElements=sysDpTypeElements[idx];
    	dyn_string myElementTypes=sysDpTypeElementTypes[idx];

	// get sequence numbers for the elements...
	dyn_int elementSeqIds=dynlen(myElements);
	int nElementSeq=dynlen(myElements);
	_fwConfigurationDB_getBatchOfSequenceNumbers(g_fwConfigurationDB_DBConnection,"DEVELEM_ID_SEQ",
		                                             nElementSeq, elementSeqIds , exceptionInfo);
    	if (dynlen(exceptionInfo)) {rdbRollbackTransaction(g_fwConfigurationDB_DBConnection);return;}

	for (int j=1;j<=nElementSeq;j++) {
	    mapping elemParams;
	    elemParams[":DEVELEM_ID"]=elementSeqIds[j];
	    elemParams[":DPT_ID"]=dpTypeSeqIds[i];
	    elemParams[":ELEMENTNAME"]="\'"+myElements[j]+"\'";
    	    elemParams[":ELEMENTTYPE"]=myElementTypes[j];
    	    _fwConfigurationDB_bindExecuteCommand(insertDptElementCmd, elemParams, exceptionInfo);
    	    if (dynlen(exceptionInfo)) {rdbRollbackTransaction(g_fwConfigurationDB_DBConnection);return;}
	}

	// finally, update the information in return-variables...
	// find out which property I am...
	dpTypeIds[idx]=dpTypeSeqIds[i];
	dpTypeElements[idx]=myElements;
	dpTypeElementIds[idx]=elementSeqIds;
    }


    // now invalidate the entries for types that were updated
    if (dynlen(dbDifferingTypeIds)>0) {
	string invalidateIdsForSql=_fwConfigurationDB_listToSQLString("DPT_ID",dbDifferingTypeIds);
	// invalidation of previous configuration:
	string invalidateSql="UPDATE DEVICE_TYPES SET VALID_TO=TO_DATE(\'"+
			    (string)date+"\' , \'yyyy.mm.dd hh24:mi:ss.???\') "+" WHERE "+invalidateIdsForSql;
	fwConfigurationDB_executeSqlSimple(invalidateSql, g_fwConfigurationDB_DBConnection,exceptionInfo);
	if (dynlen(exceptionInfo)) { rdbRollbackTransaction(g_fwConfigurationDB_DBConnection); return;}
	// update the pointers in the ITEMS table, so they now point to the new version of DPType info
	string updateSql="BEGIN"+
			"  for dpt in "+
			"    (select dpt_id,dptype from device_types where "+invalidateIdsForSql+")"+
	                "  loop"+
	                "    update items "+
	                "      set   dpt_id =  (select dpt_id from device_types where dptype=dpt.dptype and valid_to is null) "+
	                "      where dpt_id in (select dpt_id from device_types where dptype=dpt.dptype and valid_to is not null);"+
	                "  end loop;"+
	                " END;";
	fwConfigurationDB_executeSqlSimple(updateSql, g_fwConfigurationDB_DBConnection,exceptionInfo);
	if (dynlen(exceptionInfo)) { rdbRollbackTransaction(g_fwConfigurationDB_DBConnection); return;}

    }

    // finalize the commands - cleanup
    _fwConfigurationDB_finishCommand(insertDpTypeCmd, exceptionInfo);
    if (dynlen(exceptionInfo)) {rdbRollbackTransaction(g_fwConfigurationDB_DBConnection);return;}
    _fwConfigurationDB_finishCommand(insertDptElementCmd, exceptionInfo);
    if (dynlen(exceptionInfo)) {rdbRollbackTransaction(g_fwConfigurationDB_DBConnection);return;}

}


void _fwConfigurationDB_configureFwDevicesWithDefaults(dyn_string dps, dyn_string dptypes,
    dyn_string models, dyn_string &exceptionInfo)
{
    if (fwConfigurationDB_progress(fwConfigurationDB_OPER_LoadDeviceProperties,"Preparing defaults", 10.0,
                                   exceptionInfo)) return;


    // at first, get the default settings for all types/models we have here...
    dyn_string  dpmodels;
    dyn_anytype uaddressParameters;
    for (int i=1;i<=dynlen(dps);i++) { dynAppend(dpmodels,dptypes[i]+"|"+models[i]);}
    dyn_string udpmodels=dpmodels;
    dynUnique(udpmodels);
    for (int i=1;i<=dynlen(udpmodels);i++) {
        dyn_string p=strsplit(udpmodels[i],"|");
        // protect from situation with empty model - strsplit specific behaviour...
        if (substr(udpmodels[i],strlen(udpmodels[i])-1)=="|") dynAppend(p,"");
        string dptype=p[1];
        string model=p[2];
        dyn_string addressParam;
        fwDevice_getAddressDefaultParams(dptype, addressParam, exceptionInfo, model);
        if (dynlen(exceptionInfo)) {
    	    if (exceptionInfo[2]=="fwDevice_getAddressDefaultParams: default address type  not supported.") {
    		DebugN("WARNING: Device:"+dps+" type["+dptype+"/"+model+"] -> cannot have defaul address. Skipping.");
    		uaddressParameters[i]=makeDynString();
    		dynClear(exceptionInfo);
    	    } else {
    		DebugN("Error encountered in call to fwDevice_getAddressDefaultParams()",dptype,model);
    		return;
    	    }
    	}
        uaddressParameters[i]=addressParam;
    }

    if (fwConfigurationDB_progress(fwConfigurationDB_OPER_LoadDeviceProperties,"Configuring default addresses", 20.0,
                                   exceptionInfo)) return;

    // apply default addresses
    for (int i=1;i<=dynlen(dps);i++) {
        int idx=dynContains(udpmodels, dpmodels[i]);
        dyn_string addressParam=uaddressParameters[idx];
        if (dynlen(addressParam)==0) continue; // does not have default addressing...
        fwDevice_setAddress(dps[i],addressParam, exceptionInfo);
        if (dynlen(exceptionInfo)) return;
    }

    if (fwConfigurationDB_progress(fwConfigurationDB_OPER_LoadDeviceProperties,"Configuring default alerts", 30.0,
                                   exceptionInfo)) return;

    // apply default alerts
    for (int i=1;i<=dynlen(dps);i++) {
        fwDevice_setAlert(dps[i], fwDevice_ALERT_SET, exceptionInfo);
        if (dynlen(exceptionInfo)) return;
    }

    // maybe we should set default values here (?)

    // currently setting default archiving is not implemented...
    // one would need to enable this code at some stage
    //setup default archive class:
    //string archiveClass;
    //fwDevice_getArchiveClass(dptype, archiveClass, exceptionInfo);
    //if (dynlen(exceptionInfo)) return;
    //fwDevice_setArchive(dpname, archiveClass, fwDevice_ARCHIVE_SET,exceptionInfo);
    //if (dynlen(exceptionInfo)) return;

}




void fwConfigurationDB_updateDeviceConfigurationFromDB(string configurationName,
    string hierarchyType, dyn_string &exceptionInfo,  time validOn=0, dyn_string deviceList="", string systemName="",
    int options=fwConfigurationDB_deviceConfig_ALLDEVPROPS)
{

    /*
    if (configurationName=="") {
	// fall-back to previous method - get device hierarchy, etc
        DebugN("updating whole hierarchy using fwConfigurationDB_updateDeviceHierarchyFromDB");
        string topDevice="";
        fwConfigurationDB_updateDeviceHierarchyFromDB(topDevice, hierarchyType, exceptionInfo,systemName);
        if (dynlen(exceptionInfo)) return;
        return;
    }
    */

//DebugN("loading device configuration:"+configurationName, systemName);

    dyn_dyn_mixed deviceListObject, missingDeviceListObject;

    // we call the private one - the one that do not commit transaction!
    _fwConfigurationDB_getDeviceConfigurationFromDB(configurationName, hierarchyType, deviceListObject,
        exceptionInfo, validOn, deviceList,systemName);

    if (dynlen(exceptionInfo)) {
        rdbRollbackTransaction(g_fwConfigurationDB_DBConnection);
	return;
    }

    // unfold the list of device properties:
    dyn_string dpes;
    dyn_int propIds;
    for (int i=1;i<=dynlen(deviceListObject[fwConfigurationDB_DLO_DPNAME]);i++) {
        dyn_string elements=deviceListObject[fwConfigurationDB_DLO_PROPNAMES][i];
        dyn_int ids=deviceListObject[fwConfigurationDB_DLO_PROPIDS][i];
        for (int j=1;j<=dynlen(ids);j++) {
            dynAppend(dpes,deviceListObject[fwConfigurationDB_DLO_DPNAME][i]+elements[j]);
            dynAppend(propIds,ids[j]);
        }
    }

    // create devices, etc
    _fwConfigurationDB_verifyDatapoints(hierarchyType,
                                        deviceListObject, missingDeviceListObject,
                                        exceptionInfo,FALSE);
                                        //exceptionInfo,TRUE);

    if (dynlen(exceptionInfo)) {
        rdbRollbackTransaction(g_fwConfigurationDB_DBConnection);
	return;
    }
    // verify if the dptypes for the missing devices exist...
    dyn_string devTypes=missingDeviceListObject[fwConfigurationDB_DLO_DPTYPE];
    dynUnique(devTypes);
    dyn_string existingDpTypes=dpTypes();
    for (int i=1;i<=dynlen(devTypes);i++) {
	if (devTypes[i]=="") {
	    fwException_raise(exceptionInfo,"ERROR","Requested creation of device with empty DPType","");
	    int idx=dynContains(devTypes,"");
	    if (idx) {
		DebugN("Requested creation of a device with empty/unknown dptype",missingDeviceListObject[fwConfigurationDB_DLO_DPNAME][idx]);
	    }
    	    rdbRollbackTransaction(g_fwConfigurationDB_DBConnection);
	    return;
	}

	if (!dynContains(existingDpTypes,devTypes[i])) {
	    fwException_raise(exceptionInfo,"ERROR","Requested creation of device of unknown type ("+devTypes[i]+") Maybe a component missing?","");
	    int idx=dynContains(devTypes, devTypes[i]);
	    if (idx) {
		DebugN("Requested creation of a device with unknown dptype "+devTypes[i],
		    missingDeviceListObject[fwConfigurationDB_DLO_DPNAME][idx]);
	    }
	    rdbRollbackTransaction(g_fwConfigurationDB_DBConnection);
	    return;

	}
    }


    _fwConfigurationDB_createDevices(missingDeviceListObject,hierarchyType, exceptionInfo);
    if (dynlen(exceptionInfo)) {
        rdbRollbackTransaction(g_fwConfigurationDB_DBConnection);
	return;
    }


    _fwConfigurationDB_configureDevices(deviceListObject,hierarchyType,exceptionInfo, options);
    if (dynlen(exceptionInfo)) {
	rdbRollbackTransaction(g_fwConfigurationDB_DBConnection);
	return;
    }

    rdbCommitTransaction(g_fwConfigurationDB_DBConnection);

    DebugN("DONE!");

}





void _fwConfigurationDB_configureDevicesFromDB(dyn_string dpes, dyn_int propIds, dyn_string &exceptionInfo,
	int options=fwConfigurationDB_deviceConfig_ALLDEVPROPS)
{

    if (dynlen(dpes)==0) return;

    bool CONFIG_APPLY_ADDRESSES=(options & fwConfigurationDB_deviceConfig_ADDRESS);
    bool CONFIG_APPLY_VALUES=(options & fwConfigurationDB_deviceConfig_VALUE);
    bool CONFIG_APPLY_ALERTS=(options & fwConfigurationDB_deviceConfig_ALERT);
    bool CONFIG_APPLY_ARCHIVING=(options & fwConfigurationDB_deviceConfig_ARCHIVING);
    bool CONFIG_APPLY_DPFUNCTIONS=(options & fwConfigurationDB_deviceConfig_DPFUNCTION);
    bool CONFIG_APPLY_CONVERSIONS=(options & fwConfigurationDB_deviceConfig_CONVERSION);
    bool CONFIG_APPLY_PVRANGES=(options & fwConfigurationDB_deviceConfig_PVRANGE);
    bool CONFIG_APPLY_SMOOTHING=(options & fwConfigurationDB_deviceConfig_SMOOTHING);
    bool CONFIG_APPLY_UNITANDFORMAT=(options & fwConfigurationDB_deviceConfig_UNITANDFORMAT);

    dyn_dyn_mixed configurationData;

    // fix #70394: Error while restoring static configuration for CHAR_STRUCT typed elements
    mapping dpeSupportedConfigs;
    // check the capabilities of all dpes to receive certain configs
    for (int i=1;i<=dynlen(dpes);i++){
        dpeSupportedConfigs[dpes[i]]=dpGetAllConfigs(dpes[i]);
    }

    if (CONFIG_APPLY_VALUES){
        DebugN("loading/applying values...");

        if (fwConfigurationDB_progress(fwConfigurationDB_OPER_LoadDeviceProperties,"Loading values", 40.0,
                                   exceptionInfo)) return;

        dyn_int dpetypes;
        dyn_string valDpes,svalues;
        dyn_mixed values; // we probably have to have dyn_mixed here (see #14075 for the case of recipes...)
        DebugTN("loading the values");
        _fwConfigurationDB_loadValuesConfiguration(propIds, valDpes, dpetypes,svalues,exceptionInfo);
        if (dynlen(exceptionInfo)) return;
        // now decode strings to values
        DebugTN("converting the values");
        for (int i=1;i<=dynlen(valDpes);i++) {
	    // fix #70394: Error while restoring static configuration for CHAR_STRUCT typed elements
    	    // firstly check the capability of receiving the value...
    	    if ( dynContains(dpeSupportedConfigs[valDpes[i]],"_online")) {
        	anytype data;
        	_fwConfigurationDB_stringToData(svalues[i], dpetypes[i],"|",data, exceptionInfo);
        	if (dynlen(exceptionInfo)) return;
        	values[i]=data;
    	    } else {
    		//DebugTN("Warning! We will not set the value (unsupported dpelement type) ",valDpes[i],svalues[i]);
    		dynRemove(valDpes,i);
    		dynRemove(dpetypes,i);
    		dynRemove(svalues,i);
    		i--;
    	    }
        }
        if (fwConfigurationDB_progress(fwConfigurationDB_OPER_LoadDeviceProperties,"Setting values", 43.0,
                                   exceptionInfo)) return;

        DebugTN("setting values for "+dynlen(valDpes)+" dpes");
        fwConfigurationDB_dpSetManyDist(valDpes, values, exceptionInfo, false);
	if (dynlen(exceptionInfo)) return;
	DebugTN("values set OK");
    }

    if (CONFIG_APPLY_ALERTS){
        dynClear(configurationData);
        dyn_dyn_mixed sumAlertsConfigurationData, sumAlertsByPatternConfigurationData;
        if (fwConfigurationDB_progress(fwConfigurationDB_OPER_LoadDeviceProperties,"Loading alerts", 45.0,
                                   exceptionInfo)) return;

        _fwConfigurationDB_loadAlertConfiguration(propIds, dpes,
            configurationData, sumAlertsConfigurationData, sumAlertsByPatternConfigurationData,exceptionInfo);
        if(dynlen(exceptionInfo)) return;

        if (fwConfigurationDB_progress(fwConfigurationDB_OPER_LoadDeviceProperties,"Setting alerts", 48.0,
                                   exceptionInfo)) return;


        if (dynlen(configurationData[1])>0) {
            bool modifyOnly=FALSE;// ?
            fwAlertConfig_setMany(configurationData[1],
                                  configurationData[3],
                                  configurationData[4],
                                  configurationData[5],
                                  configurationData[6],
                                  configurationData[7],
                                  configurationData[8],
                                  configurationData[9],
                                  configurationData[10],
                                  exceptionInfo,
                                  modifyOnly);
            if (dynlen(exceptionInfo)) return;
            DebugN("Configured "+dynlen(configurationData[1])+" alerts");
        }

        if (dynlen(sumAlertsConfigurationData[1])>0) {
        DebugN("applying SUM alerts");

        if (fwConfigurationDB_progress(fwConfigurationDB_OPER_LoadDeviceProperties,"Setting summary alerts", 50.0,
                                   exceptionInfo)) return;


            // set summary...
            // we want "append" option, for summary alerts, so we need
            // to get current settings, then append, then set them...
            dyn_bool configExists;
            dyn_int alertConfigType,isActive;
            dyn_dyn_string alertTexts,alertClasses,summaryDpeList,alertPanelParameters;
            dyn_dyn_float alertLimits;
            dyn_string alertPanel,alertHelp;
            fwAlertConfig_getMany(sumAlertsConfigurationData[1],
                                  configExists,alertConfigType,alertTexts,alertLimits,
                                  alertClasses,summaryDpeList,alertPanel, alertPanelParameters,
                                  alertHelp,isActive,exceptionInfo);

            if (dynlen(exceptionInfo)) return;

            for (int i=1;i<=dynlen(sumAlertsConfigurationData[1]);i++) {
                dyn_string sumAlertDpes=summaryDpeList[i];
                dyn_string sumDpesDb=sumAlertsConfigurationData[7][i];
                dynAppend(sumAlertDpes, sumDpesDb);
                dynUnique(sumAlertDpes);
                sumAlertsConfigurationData[7][i]=sumAlertDpes;
            }


            bool modifyOnly=FALSE;// ?
            fwAlertConfig_setMany((dyn_string)sumAlertsConfigurationData[1],
                                  (dyn_int)sumAlertsConfigurationData[3],
                                  (dyn_dyn_string)sumAlertsConfigurationData[4],
                                  (dyn_dyn_float)sumAlertsConfigurationData[5],
                                  (dyn_dyn_string)sumAlertsConfigurationData[6],
                                  (dyn_dyn_string)sumAlertsConfigurationData[7],
                                  (dyn_string)sumAlertsConfigurationData[8],
                                  (dyn_dyn_string)sumAlertsConfigurationData[9],
                                  (dyn_string)sumAlertsConfigurationData[10],
                                  exceptionInfo,
                                  modifyOnly);
            if (dynlen(exceptionInfo)) return;
            // we also need to use activation information stored in  configurationData[11],

            DebugN("Configured "+dynlen(sumAlertsConfigurationData[1])+" summary alerts");
        }


        if (dynlen(sumAlertsByPatternConfigurationData[1])>0) {

    	    if (fwConfigurationDB_progress(fwConfigurationDB_OPER_LoadDeviceProperties,"Setting summary alerts with patterns", 52.0,
                                   exceptionInfo)) return;

            bool modifyOnly=FALSE;
            fwAlertConfig_setMany((dyn_string)sumAlertsByPatternConfigurationData[1],
                                  (dyn_int)sumAlertsByPatternConfigurationData[3],
                                  (dyn_dyn_string)sumAlertsByPatternConfigurationData[4],
                                  (dyn_dyn_float)sumAlertsByPatternConfigurationData[5],
                                  (dyn_dyn_string)sumAlertsByPatternConfigurationData[6],
                                  (dyn_dyn_string)sumAlertsByPatternConfigurationData[7],
                                  (dyn_string)sumAlertsByPatternConfigurationData[8],
                                  (dyn_dyn_string)sumAlertsByPatternConfigurationData[9],
                                  (dyn_string)sumAlertsByPatternConfigurationData[10],
                                  exceptionInfo,
                                  modifyOnly);
            if (dynlen(exceptionInfo)) return;
            // we also need to use activation information stored in  configurationData[11],

            DebugN("Configured "+dynlen(sumAlertsByPatternConfigurationData[1])+" summary alerts with patterns");

        }
        
        // now activate/deactivate the alerts; #53540
        dyn_string dpesToActivate, dpesToDeactivate;
        for (int i=1;i<=dynlen(configurationData[1]);i++) {
    	    string dpe=configurationData[1][i];
    	    if (configurationData[11][i] > 0) {
    		dynAppend(dpesToActivate,dpe);
    	    } else {
    		dynAppend(dpesToDeactivate,dpe);
    	    }
        }
        for (int i=1;i<=dynlen(sumAlertsConfigurationData[1]);i++) {
    	    string dpe=sumAlertsConfigurationData[1][i];
    	    if (sumAlertsConfigurationData[11][i] > 0) {
    		dynAppend(dpesToActivate,dpe);
    	    } else {
    		dynAppend(dpesToDeactivate,dpe);
    	    }
        }
        for (int i=1;i<=dynlen(sumAlertsByPatternConfigurationData[1]);i++) {
    	    string dpe=sumAlertsByPatternConfigurationData[1][i];
    	    if (sumAlertsByPatternConfigurationData[11][i] > 0) {
    		dynAppend(dpesToActivate,dpe);
    	    } else {
    		dynAppend(dpesToDeactivate,dpe);
    	    }
        }
        bool acknowledge = TRUE;
        bool checkIfExists = FALSE;
        bool storeInParamHistory = TRUE;
        fwAlertConfig_activateMultiple  (dpesToActivate,   exceptionInfo, acknowledge, checkIfExists, storeInParamHistory);
        fwAlertConfig_deactivateMultiple(dpesToDeactivate, exceptionInfo, acknowledge, checkIfExists, storeInParamHistory);
        if (dynlen(exceptionInfo)) return;
        DebugN("Activated "+dynlen(dpesToActivate)+", deactivated "+dynlen(dpesToDeactivate)+" alerts");
    }


    if (CONFIG_APPLY_ADDRESSES){
        if (fwConfigurationDB_progress(fwConfigurationDB_OPER_LoadDeviceProperties,"Loading addresses", 55.0,
                                   exceptionInfo)) return;

        DebugN("loading/applying address configs...");
        dynClear(configurationData);
        _fwConfigurationDB_loadAddressingConfiguration(propIds, dpes, configurationData, exceptionInfo);
        if(dynlen(exceptionInfo)) return;

        if (fwConfigurationDB_progress(fwConfigurationDB_OPER_LoadDeviceProperties,"Setting addresses", 60.0,
                                   exceptionInfo)) return;

        for (int i=1;i<=dynlen(configurationData);i++) {
            fwPeriphAddress_set(configurationData[i][1], configurationData[i][3], exceptionInfo);
            if (dynlen(exceptionInfo)) return;
        };
        if (dynlen(configurationData)) {
    	    DebugN("Configured "+dynlen(configurationData)+" addresses");
    	}
    }

    if (CONFIG_APPLY_ARCHIVING){
        if (fwConfigurationDB_progress(fwConfigurationDB_OPER_LoadDeviceProperties,"Loading archiving", 65.0,
                                   exceptionInfo)) return;

        DebugN("loading/applying archiving configs...");
        dynClear(configurationData);
        _fwConfigurationDB_loadArchivingConfiguration(propIds, dpes, configurationData, exceptionInfo);
        if(dynlen(exceptionInfo)) return;
        //DebugN("Got archiving configuration:",configurationData);

        bool checkClass = TRUE;
        bool activateArchiving = FALSE;// default in this function is TRUE;
        // we should use the information in configurationData[8] to activate archiving...
        if (dynlen(configurationData[1])) {
    	    if (fwConfigurationDB_progress(fwConfigurationDB_OPER_LoadDeviceProperties,"Set up archiving", 68.0,
                                   exceptionInfo)) return;

            fwArchive_setMany(configurationData[1], configurationData[3],configurationData[4],
                          configurationData[5],configurationData[6], configurationData[7],
                          exceptionInfo, checkClass, activateArchiving);
            if (dynlen(exceptionInfo)) return;
        }
        // now start/stop the archiving: fix #42560
        dyn_string dpesArchive=configurationData[1];
        dyn_string dpesArchiveOn;
        dyn_string dpesArchiveOff;
        for (int i=1;i<=dynlen(dpesArchive);i++) {
    	    if (configurationData[8][i]) {
    		dynAppend(dpesArchiveOn,dpesArchive[i]);
    	    } else {
    		dynAppend(dpesArchiveOff,dpesArchive[i]);
    	    }
        }
	fwArchive_startMultiple(dpesArchiveOn, exceptionInfo);
	if (dynlen(exceptionInfo)) return;
	fwArchive_stopMultiple(dpesArchiveOff, exceptionInfo);
	if (dynlen(exceptionInfo)) return;
        DebugN("Configured "+dynlen(configurationData[1])+" archiving");
    }

    if (CONFIG_APPLY_DPFUNCTIONS){
        if (fwConfigurationDB_progress(fwConfigurationDB_OPER_LoadDeviceProperties,"Loading dpfunctions", 70.0,
                                   exceptionInfo)) return;

        DebugN("loading/applying dpfunction configs...");
        dynClear(configurationData);
        _fwConfigurationDB_loadDpFunctionConfiguration(propIds, dpes, configurationData, exceptionInfo);
        if(dynlen(exceptionInfo)) return;

        //DebugN("got dpfcn data",configurationData);
        bool runChecks = TRUE;

    ///////////////////////// TO BE REMOVED IN FUTURE //////////////////////////
    /////////// TEMPORARY FIX FOR #28429 UNTIL THE FIX FROM OLIVER IS RELEASED /////

    // for fwConfigs <=3.1.1 we need to disable runChecks
    // below is the code that extracts the version number (see also #28525)
        dyn_string componentInfo;
	fwInstallation_getComponentInfo("fwConfigs","componentversionstring",componentInfo);
        string sver=componentInfo[1];
        dyn_string ds=strsplit(sver,".");
        float ver=0.0,factor=1;
        for (int i=1; i<=dynlen(ds);i++) {
    	    ver += (float)ds[i]/factor;
    	    factor*=1000.0;
        }
	if (ver<=3.001001) {
	    runChecks=FALSE;
	}

    /////////////////////////////////////////////////////////////////////////

        if (dynlen(configurationData[1])) {
        if (fwConfigurationDB_progress(fwConfigurationDB_OPER_LoadDeviceProperties,"Set up dpfunctions", 73.0,
                                   exceptionInfo)) return;

            fwDpFunction_setDpeConnectionMany(configurationData[1], configurationData[3],
                                          configurationData[4], configurationData[5],
                                          exceptionInfo, runChecks);

            if (dynlen(exceptionInfo)) return;
        }
        DebugN("Configured "+dynlen(configurationData[1])+" dpfunctions");
    }

    if (CONFIG_APPLY_CONVERSIONS){
        if (fwConfigurationDB_progress(fwConfigurationDB_OPER_LoadDeviceProperties,"Loading conversions", 75.0,
                                   exceptionInfo)) return;

        DebugN("loading/applying conversion configs...");
        dynClear(configurationData);
        _fwConfigurationDB_loadConversionConfiguration(propIds, dpes, configurationData, exceptionInfo);
        if(dynlen(exceptionInfo)) return;
        //DebugN("got conversion data:",configurationData);
        bool runDriverCheck = FALSE;
        if (dynlen(configurationData[1])) {
        if (fwConfigurationDB_progress(fwConfigurationDB_OPER_LoadDeviceProperties,"Setting up conversions", 77.0,
                                   exceptionInfo)) return;

            fwConfigConversion_setMany(configurationData[1], configurationData[3],
                                   configurationData[4], configurationData[5],
                                   configurationData[6], exceptionInfo, runDriverCheck);
            if (dynlen(exceptionInfo)) return;
        }
        DebugN("Configured "+dynlen(configurationData[1])+" conversions");
    }

    if (CONFIG_APPLY_PVRANGES){
        if (fwConfigurationDB_progress(fwConfigurationDB_OPER_LoadDeviceProperties,"Loading pvranges", 80.0,
                                   exceptionInfo)) return;

        DebugN("loading/applying pvrange configs...");
        dynClear(configurationData);

	// we need copies - the function belows returns the dpes for which we have settings....
	dyn_string dpeList=dpes;

    	dyn_int pvrTypes;

        _fwConfigurationDB_loadPvRangeConfiguration(propIds, dpeList, pvrTypes, configurationData, exceptionInfo);
        if(dynlen(exceptionInfo)) return;

        if (dynlen(configurationData)) {
        if (fwConfigurationDB_progress(fwConfigurationDB_OPER_LoadDeviceProperties,"Setting up pvranges", 83.0,
                                   exceptionInfo)) return;

	fwPvRange_setObjectMany( dpeList, pvrTypes, configurationData, exceptionInfo);

        if (dynlen(exceptionInfo)) return;
    	DebugN("Configured "+dynlen(dpeList)+" pvranges");

        }
    }

    if (CONFIG_APPLY_SMOOTHING){

        if (fwConfigurationDB_progress(fwConfigurationDB_OPER_LoadDeviceProperties,"Loading smoothing", 85.0,
                                   exceptionInfo)) return;

        DebugN("loading/applying smoothing configs...");
        dynClear(configurationData);
        _fwConfigurationDB_loadSmoothingConfiguration(propIds, dpes, configurationData, exceptionInfo);
        if(dynlen(exceptionInfo)) return;

        if (dynlen(configurationData[1])) {
            bool runDriverCheck = FALSE;
        if (fwConfigurationDB_progress(fwConfigurationDB_OPER_LoadDeviceProperties,"Setting up smoothing", 88.0,
                                   exceptionInfo)) return;

            fwSmoothing_setMany(configurationData[1], configurationData[3], configurationData[4],
                            configurationData[5], exceptionInfo, runDriverCheck);
            if (dynlen(exceptionInfo)) return;
        }
        DebugN("Configured "+dynlen(configurationData[1])+" smoothing");
    }

    if (CONFIG_APPLY_UNITANDFORMAT){
        if (fwConfigurationDB_progress(fwConfigurationDB_OPER_LoadDeviceProperties,"Loading unit and format", 90.0,
                                   exceptionInfo)) return;

        DebugN("loading/applying unit and format configs...");
        dynClear(configurationData);
        _fwConfigurationDB_loadUnitAndFormatConfiguration(propIds, dpes, configurationData, exceptionInfo);
        if(dynlen(exceptionInfo)) return;
        if (fwConfigurationDB_progress(fwConfigurationDB_OPER_LoadDeviceProperties,"Setting up unit and format", 93.0,
                                   exceptionInfo)) return;

        if (dynlen(configurationData[1])) {
            fwUnit_setMany(configurationData[1], configurationData[3], exceptionInfo);
            fwFormat_setMany(configurationData[1], configurationData[4], exceptionInfo);
        }
        if (dynlen(exceptionInfo)) return;
        DebugN("Configured "+dynlen(configurationData[1])+" units and formats");
    }


    // to wipe-out the temporary table, we need to commit the transaction...
    int rc=rdbCommitTransaction(g_fwConfigurationDB_DBConnection);
    if (rc) {
	//bool invalidConnection;
        //_fwConfigurationDB_catchDbError(g_fwConfigurationDB_DBConnection, invalidConnection, exceptionInfo);
        fwException_raise(exceptionInfo,"ERROR","Cannot commit transaction","");
        return;
    };


    if (fwConfigurationDB_progress(fwConfigurationDB_OPER_LoadDeviceProperties,"DONE", 100.0,
                               exceptionInfo)) return;

}






void _fwConfigurationDB_getIpropIdsInConfiguration(string configurationName,
                                    dyn_string &dpes, dyn_int &ipropIds,
                                    dyn_string &exceptionInfo)
{

    string sql="SELECT DPE_NAME, IPROP_ID FROM V_ITEM_PROPERTIES WHERE TAG=\'"+configurationName+"\'";
    dyn_dyn_mixed aRecords;
    _fwConfigurationDB_executeDBQuery(sql,g_fwConfigurationDB_DBConnection, aRecords, exceptionInfo,2,TRUE);
    if (dynlen(exceptionInfo)) return;
    if (dynlen(aRecords)>0) {
        dpes=(dyn_string)aRecords[1];
        ipropIds=(dyn_int)aRecords[2];
    }
}






/** Saves the device configuration to the database

@param	saveConfigs	may either be of bool, or of int type; in the former case, passing
    FALSE means that only the minimal (hierarchy) information is stored; passing TRUE means
    all configs of the devices are stored.@br
    If the int-typed parameter is used it should contain the sum of options refering to the
    configs that should be stored: the @ref deviceConfigsIndices constants should be used.
    To store no configs (i.e. only the minimal hierarchy information), one should pass 0;
    to store all properties one should pass the
    @c fwConfigurationDB_deviceConfig_ALLDEVPROPS constant.
*/
void fwConfigurationDB_saveDeviceConfigurationInDB(dyn_string deviceList, string hierarchyType,
    string configurationName, anytype saveConfigs, dyn_string &exceptionInfo, string systemName="", string confDescription="")
{

    int configsToSave=0;
    if (getType(saveConfigs)==BOOL_VAR) {
	if (saveConfigs==TRUE) configsToSave=fwConfigurationDB_deviceConfig_ALLDEVPROPS;
    } else if (getType(saveConfigs)==INT_VAR) {
	configsToSave=saveConfigs;
    } else {
	fwException_raise(exceptionInfo,"ERROR in fwConfigurationDB_saveDeviceConfigurationInDB",
	    "The saveConfigs parameter is neither BOOL not INT","");
	return;
    }


    string topDevice="";

    time t0=getCurrentTime();
    string date=t0;

    if (configurationName=="") {
        fwException_raise(exceptionInfo,"ERROR","Configuration name may not be empty","");
        return;
    }

    _fwConfigurationDB_completeDevicesInHierarchy(deviceList, hierarchyType, systemName, exceptionInfo);
    if (dynlen(exceptionInfo)) return;

    // commit previous transaction, if exists...
    rdbCommitTransaction(g_fwConfigurationDB_DBConnection);
    int rc=rdbBeginTransaction(g_fwConfigurationDB_DBConnection);
    if (rc) {
	//bool invalidConnection;
        //_fwConfigurationDB_catchDbError(g_fwConfigurationDB_DBConnection, invalidConnection, exceptionInfo);
        fwException_raise(exceptionInfo,"ERROR","Cannot start new transaction","");
        if (dynlen(exceptionInfo)) return;
    };


    dyn_dyn_mixed deviceListObject;
    _fwConfigurationDB_ensureDeviceListObjectValid(deviceListObject);

   if (fwConfigurationDB_progress(fwConfigurationDB_OPER_SaveDeviceMetaData,"Storing type information",  10.0, exceptionInfo)) return;




    // expand the types - we should do it in more optimized way...
    dyn_dyn_mixed devListObj;
    fwConfigurationDB_expandToDeviceListObject(hierarchyType, deviceList, devListObj, exceptionInfo);

    dyn_string dpTypes=devListObj[fwConfigurationDB_DLO_DPTYPE];
    dynUnique(dpTypes);
    dyn_int dpTypeIds;
    dyn_mixed dpTypeElements,dpTypeElementIds;
    DebugTN("saving types");
    _fwConfigurationDB_checkSaveDpTypes(dpTypes,dpTypeIds,dpTypeElements,dpTypeElementIds,t0, exceptionInfo);
    if (dynlen(exceptionInfo)) {rdbRollbackTransaction(g_fwConfigurationDB_DBConnection);return;}

   if (fwConfigurationDB_progress(fwConfigurationDB_OPER_SaveDeviceMetaData,"Storing version information",  70.0, exceptionInfo)) return;



    DebugTN("saving hierarchy");
    _fwConfigurationDB_saveDeviceHierarchyToDB(topDevice,  hierarchyType, deviceList, exceptionInfo, systemName, deviceListObject);
    if (dynlen(exceptionInfo)) {rdbRollbackTransaction(g_fwConfigurationDB_DBConnection);return;}




    //DebugN("Types OK",dpTypes,dpTypeIds);
    DebugTN("saving configuration version info");
    int conf_id=_fwConfigurationDB_checkCreateDeviceConfiguration(hierarchyType,configurationName, confDescription, exceptionInfo);
    if (dynlen(exceptionInfo)) {rdbRollbackTransaction(g_fwConfigurationDB_DBConnection);return;}

   if (fwConfigurationDB_progress(fwConfigurationDB_OPER_SaveDeviceMetaData,"Done",  100.0, exceptionInfo)) return;

    DebugN("OK. ConfID",conf_id);






    // resolve device types to device ids, resolve device element ids and names as well
    dyn_int deviceTypeIds; // parallel to deviceList;
    dyn_mixed deviceElementIds;

    for (int i=1;i<=dynlen(deviceListObject[fwConfigurationDB_DLO_DPNAME]);i++) {
        string dptype=deviceListObject[fwConfigurationDB_DLO_DPTYPE][i];
        int idx=dynContains(dpTypes,dptype);
        deviceTypeIds[i]=dpTypeIds[idx];
        if (dptype=="FwNode" && hierarchyType==fwDevice_HARDWARE) {
            deviceElementIds[i]=makeDynInt();
            deviceListObject[fwConfigurationDB_DLO_PROPNAMES][i]=makeDynString();
        } else {
            deviceElementIds[i]=dpTypeElementIds[idx];
            deviceListObject[fwConfigurationDB_DLO_PROPNAMES][i]=dpTypeElements[idx];
        }
    }

     if (hierarchyType==fwDevice_LOGICAL) {
        _fwConfigurationDB_resolveLogicalIds(deviceListObject, exceptionInfo,systemName);
    }


    DebugTN("Saving devices...");
    _fwConfigurationDB_saveDevicesInConfiguration(deviceListObject,hierarchyType, conf_id,
        deviceTypeIds, exceptionInfo, date);
    if (dynlen(exceptionInfo)) {rdbRollbackTransaction(g_fwConfigurationDB_DBConnection);return;}
    //DebugN("citemids:",deviceListObject[fwConfigurationDB_DLO_CITEM_ID]);



//////////////////

    if (hierarchyType==fwDevice_LOGICAL) {

	DebugN("saving logical mapping...");
	//dyn_dyn_int changedLogicalDeviceIds;
	//_fwConfigurationDB_checkLogicalChanged(deviceListObject, configurationName, changedLogicalDeviceIds, exceptionInfo);
	//if (dynlen(exceptionInfo)) {rdbRollbackTransaction(g_fwConfigurationDB_DBConnection);return;}
	fwConfigurationDB_saveReferences(configurationName, deviceListObject,exceptionInfo);
	if (dynlen(exceptionInfo)) {rdbRollbackTransaction(g_fwConfigurationDB_DBConnection);return;}

	// HERE WE SHOULD PROBABLY STORE THE ELEMENTS FOR ALL FwNode's: i.e. the panels, etc...
	// right now this is inhibited by configsToSave=0 :-(
	// most likely, we would only like to store these, if they differ, or something...
	// or maybe we could move this into _saveReferences part?
	configsToSave=0;

    }


    if (configsToSave!=0) {

    DebugN("storing props now...");



    bool storeValues=configsToSave & fwConfigurationDB_deviceConfig_VALUE;

    _fwConfigurationDB_saveDevicePropertiesToDB(deviceListObject, hierarchyType, deviceElementIds,
                                                date, exceptionInfo, storeValues);
    if (dynlen(exceptionInfo)) {rdbRollbackTransaction(g_fwConfigurationDB_DBConnection);return;}

    if (fwConfigurationDB_progress(fwConfigurationDB_OPER_SaveDevicesAndElements,"DONE",  100.0, exceptionInfo)) return;



    DebugN("properties saved OK");

    // get the list of all properties (needed for summary alerts)
    dyn_string allDpesInConfiguration;
    dyn_int allIpropIdsInConfiguration;

    _fwConfigurationDB_getIpropIdsInConfiguration(configurationName,
        allDpesInConfiguration, allIpropIdsInConfiguration,exceptionInfo);
    if (dynlen(exceptionInfo)) {rdbRollbackTransaction(g_fwConfigurationDB_DBConnection);return;}

    // form the lists of dpes and corresponding ipropIds...
    dyn_string dpes;
    dyn_int ipropIds;
/*
    for (int i=1;i<=dynlen(deviceListObject[fwConfigurationDB_DLO_DPNAME]);i++){

        dyn_int devIpropIds=deviceListObject[fwConfigurationDB_DLO_PROPIDS][i];
        dyn_string elementNames=deviceListObject[fwConfigurationDB_DLO_PROPNAMES][i];
        string devName=deviceListObject[fwConfigurationDB_DLO_DPNAME][i];
        for (int j=1;j<=dynlen(devIpropIds);j++) {
            dynAppend(dpes,devName+elementNames[j]);;
            dynAppend(ipropIds,devIpropIds[j]);
        }
    }
*/
   if (fwConfigurationDB_progress(fwConfigurationDB_OPER_SaveDeviceProperties,"Preparing...",  10.0, exceptionInfo)) return;

    dyn_dyn_string dpeSupportedConfigs;

    // select only the ones that reflect the devices we save...
    for (int i=1;i<=dynlen(allDpesInConfiguration);i++){
	dyn_string spl=strsplit(allDpesInConfiguration[i],".");
	string devName=spl[1];
	if (dynContains(deviceList,devName)) {
	    string _dpe=allDpesInConfiguration[i];

	    // exclude dpes of type DPEL_DPID: fix #17818
	    if (dpElementType(_dpe)==DPEL_DPID) continue;
            dyn_string supportedConfigs=dpGetAllConfigs(_dpe);

            dynAppend(dpes,_dpe);
            dynAppend(ipropIds, allIpropIdsInConfiguration[i]);
            dpeSupportedConfigs[dynlen(dpeSupportedConfigs)+1]=supportedConfigs;
	}
    }

    dyn_dyn_mixed configurationData;

    if (configsToSave & fwConfigurationDB_deviceConfig_ADDRESS) {
	if (fwConfigurationDB_progress(fwConfigurationDB_OPER_SaveDeviceProperties,"Extracting addressing data",  20.0, exceptionInfo)) return;

	DebugN("storing addressing data");
	dynClear(configurationData);
	
	// form a list of supported dpes...
	dyn_string supportedDpes;
	dyn_int    supportedIpropIds;
	for (int i=1;i<=dynlen(dpes);i++) {
	    if (dynContains(dpeSupportedConfigs[i],"_address")) {
		dynAppend(supportedDpes,dpes[i]);
		dynAppend(supportedIpropIds,ipropIds[i]);
	    }
	}	
	
//	_fwConfigurationDB_extractAddressingConfiguration(dpes,ipropIds, configurationData, exceptionInfo);
	_fwConfigurationDB_extractAddressingConfiguration(supportedDpes,supportedIpropIds, configurationData, exceptionInfo);
	if (dynlen(exceptionInfo)) {rdbRollbackTransaction(g_fwConfigurationDB_DBConnection);return;}
	if (fwConfigurationDB_progress(fwConfigurationDB_OPER_SaveDeviceProperties,"Storing addressing data",  25.0, exceptionInfo)) return;

	_fwConfigurationDB_saveAddressingConfiguration(configurationData, exceptionInfo);
	if (dynlen(exceptionInfo)) {rdbRollbackTransaction(g_fwConfigurationDB_DBConnection);return;}
    }

    if (configsToSave & fwConfigurationDB_deviceConfig_ALERT) {
	if (fwConfigurationDB_progress(fwConfigurationDB_OPER_SaveDeviceProperties,"Extracting alerts data",  30.0, exceptionInfo)) return;

	DebugN("storing alerts data");
	dynClear(configurationData);
	// form a list of supported dpes...
	dyn_string supportedDpes;
	dyn_int    supportedIpropIds;
	for (int i=1;i<=dynlen(dpes);i++) {
	    if (dynContains(dpeSupportedConfigs[i],"_alert_hdl")) {
		dynAppend(supportedDpes,dpes[i]);
		dynAppend(supportedIpropIds,ipropIds[i]);
	    }
	}	

	_fwConfigurationDB_extractAlertConfiguration(supportedDpes,supportedIpropIds,
                             allDpesInConfiguration, allIpropIdsInConfiguration,
                             configurationData,exceptionInfo);
	if (dynlen(exceptionInfo)) {rdbRollbackTransaction(g_fwConfigurationDB_DBConnection);return;}
	if (fwConfigurationDB_progress(fwConfigurationDB_OPER_SaveDeviceProperties,"Storing alerts data",  35.0, exceptionInfo)) return;

	_fwConfigurationDB_saveAlertConfiguration(configurationData, exceptionInfo);
	if (dynlen(exceptionInfo)) {rdbRollbackTransaction(g_fwConfigurationDB_DBConnection);return;}
    }

    if (configsToSave & fwConfigurationDB_deviceConfig_ARCHIVING) {
	if (fwConfigurationDB_progress(fwConfigurationDB_OPER_SaveDeviceProperties,"Extracting archiving data",  40.0, exceptionInfo)) return;

	DebugN("storing archiving data");
	dynClear(configurationData);
	// form a list of supported dpes...
	dyn_string supportedDpes;
	dyn_int    supportedIpropIds;
	for (int i=1;i<=dynlen(dpes);i++) {
	    if (dynContains(dpeSupportedConfigs[i],"_archive")) {
		dynAppend(supportedDpes,dpes[i]);
		dynAppend(supportedIpropIds,ipropIds[i]);
	    }
	}	
	_fwConfigurationDB_extractArchivingConfiguration(supportedDpes,supportedIpropIds, configurationData, exceptionInfo);
	if (dynlen(exceptionInfo)) {rdbRollbackTransaction(g_fwConfigurationDB_DBConnection);return;}

	if (fwConfigurationDB_progress(fwConfigurationDB_OPER_SaveDeviceProperties,"Storing archiving data",  45.0, exceptionInfo)) return;
	_fwConfigurationDB_saveArchivingConfiguration(configurationData, exceptionInfo);
	if (dynlen(exceptionInfo)) {rdbRollbackTransaction(g_fwConfigurationDB_DBConnection);return;}
    }

    if (configsToSave & fwConfigurationDB_deviceConfig_DPFUNCTION) {
	if (fwConfigurationDB_progress(fwConfigurationDB_OPER_SaveDeviceProperties,"Extracting dpfunction data",  50.0, exceptionInfo)) return;

	DebugN("storing dp-function data");
	dynClear(configurationData);
	// form a list of supported dpes...
	dyn_string supportedDpes;
	dyn_int    supportedIpropIds;
	for (int i=1;i<=dynlen(dpes);i++) {
	    if (dynContains(dpeSupportedConfigs[i],"_dp_fct")) {
		dynAppend(supportedDpes,dpes[i]);
		dynAppend(supportedIpropIds,ipropIds[i]);
	    }
	}	
	_fwConfigurationDB_extractDpFunctionConfiguration(supportedDpes,supportedIpropIds, configurationData, exceptionInfo);
	if (dynlen(exceptionInfo)) {rdbRollbackTransaction(g_fwConfigurationDB_DBConnection);return;}
	if (fwConfigurationDB_progress(fwConfigurationDB_OPER_SaveDeviceProperties,"Storing dpfunction data",  55.0, exceptionInfo)) return;

	_fwConfigurationDB_saveDpFunctionConfiguration(configurationData, exceptionInfo);
	if (dynlen(exceptionInfo)) {rdbRollbackTransaction(g_fwConfigurationDB_DBConnection);return;}
    }

    if (configsToSave & fwConfigurationDB_deviceConfig_CONVERSION) {
	if (fwConfigurationDB_progress(fwConfigurationDB_OPER_SaveDeviceProperties,"Extracting conversion data",  60.0, exceptionInfo)) return;

	DebugN("storing conversion data");
	dynClear(configurationData);
	// form a list of supported dpes...
	dyn_string supportedDpes;
	dyn_int    supportedIpropIds;
	for (int i=1;i<=dynlen(dpes);i++) {
	    if (dynContains(dpeSupportedConfigs[i],"_msg_conv")||dynContains(dpeSupportedConfigs[i],"_cmd_conv")) {
		dynAppend(supportedDpes,dpes[i]);
		dynAppend(supportedIpropIds,ipropIds[i]);
	    }
	}	
	_fwConfigurationDB_extractConversionConfiguration(supportedDpes,supportedIpropIds, configurationData, exceptionInfo);
	if (fwConfigurationDB_progress(fwConfigurationDB_OPER_SaveDeviceProperties,"Storing conversion data",  65.0, exceptionInfo)) return;
	if (dynlen(exceptionInfo)) {rdbRollbackTransaction(g_fwConfigurationDB_DBConnection);return;}
	_fwConfigurationDB_saveConversionConfiguration(configurationData, exceptionInfo);
    }

    if (configsToSave & fwConfigurationDB_deviceConfig_PVRANGE) {
	if (fwConfigurationDB_progress(fwConfigurationDB_OPER_SaveDeviceProperties,"Extracting pvrange data",  70.0, exceptionInfo)) return;

	DebugN("storing pvrange data");
	dynClear(configurationData);
	// form a list of supported dpes...
	dyn_string supportedDpes;
	dyn_int    supportedIpropIds;
	for (int i=1;i<=dynlen(dpes);i++) {
	    if (dynContains(dpeSupportedConfigs[i],"_pv_range")) {
		dynAppend(supportedDpes,dpes[i]);
		dynAppend(supportedIpropIds,ipropIds[i]);
	    }
	}	
	_fwConfigurationDB_extractPvRangeConfiguration(supportedDpes,supportedIpropIds, configurationData, exceptionInfo);
	if (fwConfigurationDB_progress(fwConfigurationDB_OPER_SaveDeviceProperties,"Storing pvrange data",  75.0, exceptionInfo)) return;
	if (dynlen(exceptionInfo)) {rdbRollbackTransaction(g_fwConfigurationDB_DBConnection);return;}
	_fwConfigurationDB_savePvRangeConfiguration(configurationData, exceptionInfo);
    }

    if (configsToSave & fwConfigurationDB_deviceConfig_SMOOTHING) {
	if (fwConfigurationDB_progress(fwConfigurationDB_OPER_SaveDeviceProperties,"Extracting smoothing data",  80.0, exceptionInfo)) return;

	DebugN("storing smoothing data");
	dynClear(configurationData);
	// form a list of supported dpes...
	dyn_string supportedDpes;
	dyn_int    supportedIpropIds;
	for (int i=1;i<=dynlen(dpes);i++) {
	    if (dynContains(dpeSupportedConfigs[i],"_smooth")) {
		dynAppend(supportedDpes,dpes[i]);
		dynAppend(supportedIpropIds,ipropIds[i]);
	    }
	}	
	_fwConfigurationDB_extractSmoothingConfiguration(supportedDpes,supportedIpropIds, configurationData, exceptionInfo);
	if (fwConfigurationDB_progress(fwConfigurationDB_OPER_SaveDeviceProperties,"Storing smoothing data",  85.0, exceptionInfo)) return;

	if (dynlen(exceptionInfo)) {rdbRollbackTransaction(g_fwConfigurationDB_DBConnection);return;}
	_fwConfigurationDB_saveSmoothingConfiguration(configurationData, exceptionInfo);
    }

    if (configsToSave & fwConfigurationDB_deviceConfig_UNITANDFORMAT) {
	if (fwConfigurationDB_progress(fwConfigurationDB_OPER_SaveDeviceProperties,"Extracting unit and format data",  90.0, exceptionInfo)) return;

	DebugN("storing unit and format data");
	dynClear(configurationData);
	_fwConfigurationDB_extractUnitAndFormatConfiguration(dpes,ipropIds, configurationData, exceptionInfo);
	if (dynlen(exceptionInfo)) {rdbRollbackTransaction(g_fwConfigurationDB_DBConnection);return;}
	if (fwConfigurationDB_progress(fwConfigurationDB_OPER_SaveDeviceProperties,"Storing unit and format data",  50.0, exceptionInfo)) return;

	_fwConfigurationDB_saveUnitAndFormatConfiguration(configurationData, exceptionInfo);
	if (dynlen(exceptionInfo)) {rdbRollbackTransaction(g_fwConfigurationDB_DBConnection);return;}
    }

}


    DebugN("Committing db transaction");
    rc=rdbCommitTransaction(g_fwConfigurationDB_DBConnection);
    if (rc) {
           //bool invalidConnection;
           //_fwConfigurationDB_catchDbError(g_fwConfigurationDB_DBConnection, invalidConnection, exceptionInfo);
           fwException_raise(exceptionInfo,"ERROR","Cannot commit transaction","");
           return;
    };

    if (fwConfigurationDB_progress(fwConfigurationDB_OPER_SaveDeviceProperties,"DONE",  100.0, exceptionInfo)) return;

    DebugN("DONE!");
}


void fwConfigurationDB_reconnectDevices(dyn_string deviceList, string configurationName,
	string hierarchyType, string targetSystem, dyn_string &exceptionInfo)
{
    if (hierarchyType!=fwDevice_HARDWARE) {
	fwException_raise(exceptionInfo,"ERROR in fwConfigurationDB_reconnectDevices",
	    "Hierarchy type "+hierarchyType+" not supported","");
	return ;
    }

    // find eventual parrent devices - we'll need this to save the hierarchy on the new machine...
    dyn_string allDeviceList=deviceList;
    string system="";

//    string system=getSystemName();
//    _fwConfigurationDB_completeDevicesInHierarchy(allDeviceList, hierarchyType, system, exceptionInfo);
//    if (dynlen(exceptionInfo)) return;


    // find the configuration...
    int refVer=0;
    string refVerSql="SELECT CONF_ID FROM CONFIG_DESC WHERE CONF_TAG=\'"+configurationName+"\'";
    dyn_dyn_mixed arefverdata;
    _fwConfigurationDB_executeDBQuery(refVerSql,g_fwConfigurationDB_DBConnection, arefverdata, exceptionInfo,1,TRUE);
    if (dynlen(exceptionInfo)) return;
    if (dynlen(arefverdata)<1) {
	fwException_raise(exceptionInfo,"ERROR","Cannot find configuration:"+configurationName,"");
	return;
    }
    refVer=arefverdata[1][1];


    _fwConfigurationDB_dbCompleteDevicesInHierarchy(allDeviceList, hierarchyType, configurationName, exceptionInfo);
    if (dynlen(exceptionInfo)) return;

    // locate the existing devices in the DB at first...
    dyn_dyn_mixed deviceListObject,allDeviceListObject;
    time validOn=0;

    // we call the public one, i.e. with commiting the transaction and thus cleanup of tmp_item_props
    fwConfigurationDB_getDeviceConfigurationFromDB(configurationName,
	hierarchyType, deviceListObject, exceptionInfo, validOn, deviceList);
    if (dynlen(exceptionInfo)) return;

    //and get hierarchical info for all ones:
    dyn_string dumMissing;
    fwConfigurationDB_findDevicesInDB("", hierarchyType,allDeviceList, allDeviceListObject, dumMissing, exceptionInfo);
    if (dynlen(exceptionInfo)) return;


    // identify the aliases that we remap...

    string idListSql=_fwConfigurationDB_listToSQLString("ref_id", deviceListObject[fwConfigurationDB_DLO_ITEMID]);

    string alsql="SELECT ID,REF_ID FROM REFERENCES WHERE VALID_TO IS NULL";
    alsql+=" and refver="+refVer;
    alsql+=" and "+idListSql;

    dyn_dyn_mixed aliasData;
    // aliasData[1] - ID (i.e. logical)
    // aliasData[2] - REF_ID (i.e. hardware)
    _fwConfigurationDB_executeDBQuery(alsql,g_fwConfigurationDB_DBConnection, aliasData, exceptionInfo,2,TRUE);
    if (dynlen(exceptionInfo)) return;

    // check if the specified ones exist...
    for (int i=1;i<=dynlen(deviceList);i++) {
	if (!dynContains(allDeviceListObject[fwConfigurationDB_DLO_DPNAME],deviceList[i])) {
	    // if exception not yet thrown - throw it
	    if (!dynlen(exceptionInfo))	{
		fwException_raise(exceptionInfo,"ERROR in fwConfigurationDB_reconnectDevices",
		    "Requested reconnect for device(s) not present in the DB. See log for details","");
		    DebugN("--- ERROR! Requested reconnect for device(s) not present in the DB:");
		    DebugN("    in configuration:"+configurationName);
	    }
	    DebugN("  -> device not found in DB:",deviceList[i]);
	}
    }
    if (dynlen(exceptionInfo)) return;


    // form lists with new system names...
    dyn_string newDeviceList, newAllDeviceList;
    for (int i=1;i<=dynlen(deviceList);i++) {
	string devNoSys=_fwConfigurationDB_NodeNameWithoutSystem(deviceList[i]);
	string devNewSys= _fwConfigurationDB_NodeNameWithSystem(devNoSys, targetSystem, exceptionInfo);
	if (dynlen(exceptionInfo)) return;
	newDeviceList[i]=devNewSys;
    }

    for (int i=1;i<=dynlen(allDeviceList);i++) {
	string devNoSys=_fwConfigurationDB_NodeNameWithoutSystem(allDeviceList[i]);
	string devNewSys= _fwConfigurationDB_NodeNameWithSystem(devNoSys, targetSystem, exceptionInfo);
	if (dynlen(exceptionInfo)) return;
	newAllDeviceList[i]=devNewSys;
    }

    //make sure we have a root node for the target system...
    _fwConfigurationDB_DBCheckCreateSystemNode(hierarchyType,exceptionInfo,targetSystem);
    if (dynlen(exceptionInfo)) return;


/*
    int origRootNodeId, newRootNodeId;
    _fwConfigurationDB_getDBRootNodeId(hierarchyType, origRootNodeId, exceptionInfo, getSystemName());
    _fwConfigurationDB_getDBRootNodeId(hierarchyType, newRootNodeId, exceptionInfo, targetSystem);

*/

    // find out all root nodes in the hierarchy

    dyn_string rootNodesNames;
    dyn_int rootNodesIds;
    string getRootNodesSql= "SELECT name,item_id FROM v_items "+
		    	    " WHERE parent_id IS NULL "+
		    	    " AND hver="+g_fwConfigurationDB_DBHierarchyIDs[hierarchyType];
    dyn_dyn_mixed aRecords;
    _fwConfigurationDB_executeDBQuery(getRootNodesSql,g_fwConfigurationDB_DBConnection, aRecords, exceptionInfo,2,TRUE);
    if (dynlen(exceptionInfo)) return;

    rootNodesNames=aRecords[1];
    rootNodesIds=aRecords[2];

    // then find out the id of the new root node...
    int newRootIdx=dynContains(rootNodesNames,targetSystem);
    int newRootNodeId=rootNodesIds[newRootIdx];

    // make sure that the devices in the target system do not exist yet...
    dyn_dyn_mixed newDeviceListObject;

    // we use the public one, which commits the connection
    fwConfigurationDB_getDeviceConfigurationFromDB(configurationName,
	hierarchyType, newDeviceListObject, exceptionInfo, validOn, newDeviceList);


    if (dynlen(newDeviceListObject[fwConfigurationDB_DLO_DPNAME])) {
	fwException_raise(exceptionInfo,"ERROR in fwConfigurationDB_reconnectDevices",
	    "Some of reconnected devices already exist in the target system. See log for details","");
	DebugN("--- ERROR! Requested reconnect for device(s) already exists in DB:");
	DebugN("    in configuration:"+configurationName);
	DebugN(newDeviceListObject[fwConfigurationDB_DLO_DPNAME]);
	DebugN("-------------------------------------------------------------------");
	return ;
    }


    // store the raw hierarchy at first, including all the devices (also: parents)

    // find out what we already have in the hierarchy for target system...
    dyn_string missingDeviceList;
    dyn_dyn_mixed existingNewDeviceListObject;
    fwConfigurationDB_findDevicesInDB(targetSystem, hierarchyType,
                                       newAllDeviceList,
                                       existingNewDeviceListObject, missingDeviceList,
                                       exceptionInfo, targetSystem);

    if (dynlen(exceptionInfo)) return;

    int nItems=dynlen(missingDeviceList);

    dyn_int newItemIds;
    _fwConfigurationDB_getBatchOfSequenceNumbers(g_fwConfigurationDB_DBConnection, "ITEMS_ID_SEQ", nItems,
			    newItemIds, exceptionInfo);
    if (dynlen(exceptionInfo)) return;

    // copy allDeviceListObject->deviceListObject,
    // remove what we do not know...
    dynClear(newDeviceListObject);
    _fwConfigurationDB_ensureDeviceListObjectValid(newDeviceListObject);

//DebugN("newAllDeviceList",newAllDeviceList);
//DebugN("allDeviceList",allDeviceList);
    dyn_int tmpIdx;
    for (int i=1;i<=dynlen(missingDeviceList);i++) {
	newDeviceListObject[fwConfigurationDB_DLO_DPNAME][i]=missingDeviceList[i];
//DebugN("processing",missingDeviceList[i]);
	// find counter-part in the source system
	int idx=dynContains(newAllDeviceList, missingDeviceList[i]);
//DebugN("index  in newAllDeviceList is ",idx);
	string srcName=allDeviceList[idx];
//DebugN("SourceName is ",srcName);
	idx= dynContains(allDeviceListObject[fwConfigurationDB_DLO_DPNAME],srcName);
//DebugN("ultimately index is",idx);
	tmpIdx[i]=idx;
	newDeviceListObject[fwConfigurationDB_DLO_DPTYPE][i]=allDeviceListObject[fwConfigurationDB_DLO_DPTYPE][idx];
	newDeviceListObject[fwConfigurationDB_DLO_NAME][i]=allDeviceListObject[fwConfigurationDB_DLO_NAME][idx];
//	newDeviceListObject[fwConfigurationDB_DLO_TYPE][i]=allDeviceListObject[fwConfigurationDB_DLO_TYPE][idx];
	newDeviceListObject[fwConfigurationDB_DLO_MODEL][i]=allDeviceListObject[fwConfigurationDB_DLO_MODEL][idx];
	newDeviceListObject[fwConfigurationDB_DLO_COMMENT][i]=allDeviceListObject[fwConfigurationDB_DLO_COMMENT][idx];

	// assign new item id...
	newDeviceListObject[fwConfigurationDB_DLO_ITEMID][i]=newItemIds[i];
	newDeviceListObject[fwConfigurationDB_DLO_PARENTID][i]=-1; // this will be resolved below

        newDeviceListObject[fwConfigurationDB_DLO_DPID][i]="";
	newDeviceListObject[fwConfigurationDB_DLO_REFDP][i]="";
	newDeviceListObject[fwConfigurationDB_DLO_REF_STATUS][i]="";
	newDeviceListObject[fwConfigurationDB_DLO_PROPIDS][i]=makeDynInt();
	newDeviceListObject[fwConfigurationDB_DLO_PROPNAMES][i]=makeDynString();
	newDeviceListObject[fwConfigurationDB_DLO_CITEM_ID][i]=""; // we need to resolve it elsewhere

    }

    // resolve parents now...
    for (int i=1;i<=dynlen(missingDeviceList);i++) {
	int idx=tmpIdx[i]; // restore the pointer to original in allDeviceListObject
	int origParentId=allDeviceListObject[fwConfigurationDB_DLO_PARENTID][idx];


	//if (origParentId==origRootNodeId) {
	int origParentIdx=dynContains(rootNodesIds,origParentId);
	if (origParentIdx) {
	    // means: parent is a root note
	    newDeviceListObject[fwConfigurationDB_DLO_PARENTID][i]=newRootNodeId;
	} else {
	    // reconstruct the name of the parent ...
	    int idxPar=dynContains(allDeviceListObject[fwConfigurationDB_DLO_ITEMID],origParentId);
	    string origParentName=allDeviceListObject[fwConfigurationDB_DLO_DPNAME][idxPar];
	    int idx2=dynContains(allDeviceList, origParentName);
	    string newParentName=newAllDeviceList[idx2];
	    // try to find it in the existing ones;
	    idx2=dynContains(existingNewDeviceListObject[fwConfigurationDB_DLO_DPNAME],newParentName);
	    if (idx2>0) {
		newDeviceListObject[fwConfigurationDB_DLO_PARENTID][i]=existingNewDeviceListObject[fwConfigurationDB_DLO_ITEMID][idx2];
	    } else {

	    // try to find in the new ones...
	    idx2= dynContains(newDeviceListObject[fwConfigurationDB_DLO_DPNAME],newParentName);
	    if (idx2>0) {
//DebugN("OK. Found in new ones", idx2,newDeviceListObject[fwConfigurationDB_DLO_ITEMID][idx2]);
		newDeviceListObject[fwConfigurationDB_DLO_PARENTID][i]=newDeviceListObject[fwConfigurationDB_DLO_ITEMID][idx2];
	    } else {
//DebugN("not found...");
		fwException_raise(exceptionInfo,"ERROR","Could not resolve all relations","");
		return;
	    }

	    }

	}
    }


    // commit previous transaction if existing...
    rdbCommitTransaction(g_fwConfigurationDB_DBConnection);

    // save the hierarchy...
    int rc=rdbBeginTransaction(g_fwConfigurationDB_DBConnection);
    if (rc) {
	//bool invalidConnection;
        //_fwConfigurationDB_catchDbError(g_fwConfigurationDB_DBConnection, invalidConnection, exceptionInfo);
        fwException_raise(exceptionInfo,"ERROR","Cannot start new transaction","");
        if (dynlen(exceptionInfo)) return;
    };



if (dynlen(newDeviceListObject[1])) {
DebugN("saving new devices");
//DebugN("=-NEW-=",newDeviceListObject);
    _fwConfigurationDB_saveItemsToDB(newDeviceListObject, hierarchyType, exceptionInfo);
    if (dynlen(exceptionInfo))  {rdbRollbackTransaction(g_fwConfigurationDB_DBConnection);return;}

/*
DebugN("Updating the hierarchy...");
    // trigger the update of the materialized view:
    _fwConfigurationDB_updateHierarchyView(g_fwConfigurationDB_DBConnection, exceptionInfo);
    if (dynlen(exceptionInfo))  {rdbRollbackTransaction(g_fwConfigurationDB_DBConnection);return;}
*/
}

DebugN("moving the devices...");


    // prepare the "move" command
    anytype moveDevCmd;
    string moveDevSql="UPDATE config_items SET ITEM_ID = :NEWITEMID WHERE CITEM_ID = :CITEM_ID ";

    _fwConfigurationDB_startCommand(moveDevSql, g_fwConfigurationDB_DBConnection, moveDevCmd, exceptionInfo);
    if (dynlen(exceptionInfo))  {rdbRollbackTransaction(g_fwConfigurationDB_DBConnection);return;}

    dyn_string updatedCitemIds;

    for (int i=1;i<=dynlen(deviceListObject[fwConfigurationDB_DLO_DPNAME]);i++) {
	int citemId=deviceListObject[fwConfigurationDB_DLO_CITEM_ID][i];
	string oldItemName=deviceListObject[fwConfigurationDB_DLO_DPNAME][i];
	int newItemId=0;

	// find the corresponding new name
	int idx=dynContains(deviceList,oldItemName);
	string newItemName=newDeviceList[idx];

	// try find this item in the new devices...
	idx=dynContains(newDeviceListObject[fwConfigurationDB_DLO_DPNAME],newItemName);
	if (idx>0) {
	    newItemId=newDeviceListObject[fwConfigurationDB_DLO_ITEMID][idx];
	} else {
	    // try to find it in the ones that were already stored...
	    idx=dynContains(existingNewDeviceListObject[fwConfigurationDB_DLO_DPNAME],newItemName);
	    if (idx>0) newItemId=existingNewDeviceListObject[fwConfigurationDB_DLO_ITEMID][idx];

	}

	if (newItemId!=0) {
    	    mapping params;
    	    params[":NEWITEMID"] = newItemId;
	    params[":CITEM_ID"]=citemId;
	    dynAppend(updatedCitemIds,citemId);
    	    _fwConfigurationDB_bindExecuteCommand(moveDevCmd, params, exceptionInfo);
    	    if (dynlen(exceptionInfo)) {rdbRollbackTransaction(g_fwConfigurationDB_DBConnection);return;}

	} else {
	    DebugN("unresolved![ProtectMe!]",i, citemId,oldItemName);
	}
    }

    _fwConfigurationDB_finishCommand(moveDevCmd, exceptionInfo);
    if (dynlen(exceptionInfo)) {rdbRollbackTransaction(g_fwConfigurationDB_DBConnection);return;}


    // update the data for consistency
    string citemIdsAsSql=_fwConfigurationDB_listToSQLString("citem_id", updatedCitemIds);

    DebugN("updating dpfunctions data");

//    string updateDPfSql="update config_dpfunctions set params=REPLACE(params,SUBSTR(params,1,INSTR(params,':',1,1)),\'"+targetSystem+"\') "+
//	       " where iprop_id in (select iprop_id from config_item_properties where "+citemIdsAsSql+")";
    string updateDPfSql="update config_dpfunctions set params=("+
			" case(INSTR(params,'|',1,1)) "+
			"	when 1 then REPLACE(params,SUBSTR(params,1,INSTR(params,':',1,1)),\'|"+targetSystem+"\')"+
			"	else        REPLACE(params,SUBSTR(params,1,INSTR(params,':',1,1)),\'"+targetSystem+"\')"+
			" END )"+
    	    		" where iprop_id in (select iprop_id from config_item_properties where "+citemIdsAsSql+")";


    fwConfigurationDB_executeSqlSimple(updateDPfSql, g_fwConfigurationDB_DBConnection,exceptionInfo);
    if (dynlen(exceptionInfo)) {rdbRollbackTransaction(g_fwConfigurationDB_DBConnection);return;}

    DebugN("updating alerts classes data");

    //string updateACSql="update config_dpealerts set classes=REPLACE(classes,SUBSTR(classes,1,INSTR(classes,':',1,1)),\'"+targetSystem+"\') "+
    //       " where iprop_id in (select iprop_id from config_item_properties where "+citemIdsAsSql+")";


    string updateACSql="update config_dpealerts set classes=("+
			" case(INSTR(classes,'|',1,1)) "+
			"	when 1 then REPLACE(classes,SUBSTR(classes,1,INSTR(classes,':',1,1)),\'|"+targetSystem+"\')"+
			"	else        REPLACE(classes,SUBSTR(classes,1,INSTR(classes,':',1,1)),\'"+targetSystem+"\')"+
			" END ) "+
    	    		" where iprop_id in (select iprop_id from config_item_properties where "+citemIdsAsSql+")";


    fwConfigurationDB_executeSqlSimple(updateACSql, g_fwConfigurationDB_DBConnection,exceptionInfo);
    if (dynlen(exceptionInfo)) {rdbRollbackTransaction(g_fwConfigurationDB_DBConnection);return;}

    DebugN("updating conversions data");

    //string updateConvSql="update config_conversions set arguments=REPLACE(arguments,SUBSTR(arguments,1,INSTR(arguments,':',1,1)),\'"+targetSystem+"\') "+
    //	" where iprop_id in (select iprop_id from config_item_properties where "+citemIdsAsSql+")";
    string updateConvSql="update config_conversions set arguments=("+
			" case(INSTR(arguments,'|',1,1)) "+
			"	when 1 then REPLACE(arguments,SUBSTR(arguments,1,INSTR(arguments,':',1,1)),\'|"+targetSystem+"\')"+
			"	else        REPLACE(arguments,SUBSTR(arguments,1,INSTR(arguments,':',1,1)),\'"+targetSystem+"\')"+
			" END )"+
    	    		" where iprop_id in (select iprop_id from config_item_properties where "+citemIdsAsSql+")";

    fwConfigurationDB_executeSqlSimple(updateConvSql, g_fwConfigurationDB_DBConnection,exceptionInfo);
    if (dynlen(exceptionInfo)) {rdbRollbackTransaction(g_fwConfigurationDB_DBConnection);return;}


    DebugN("updating aliases");
    // identify the aliases that we remap...

    string nodeListSql=_fwConfigurationDB_listToSQLString("refdpname", allDeviceList);

    string alsql="SELECT ITEM_ID,REF_ID, dpname, refdpname FROM v_REFERENCES WHERE ";
    alsql+=" config_id="+refVer;
    alsql+=" and "+nodeListSql;

    dyn_dyn_mixed aliasData;
    _fwConfigurationDB_executeDBQuery(alsql,g_fwConfigurationDB_DBConnection, aliasData, exceptionInfo,4,TRUE);
    if (dynlen(exceptionInfo)) return;

    time t0=getCurrentTime();
    if (dynlen(aliasData)<1) aliasData[1]=makeDynString(); // protect the next line...
    // order the list to be parallel to the allDeviceList, and hence to newAllDeviceList
    for (int i=1;i<=dynlen(aliasData[1]);i++) {
	string alias=aliasData[3][i];
	string oldDevice=aliasData[4][i];
	int oldDeviceId=aliasData[2][i];
	int idx=dynContains(allDeviceList,oldDevice);
	if (!idx) {
	    fwException_raise(exceptionInfo,"ERROR","Cannot find the device in the list","");
	    DebugN("Cannot find "+oldDevice+" in the list of devices being moved for alias "+alias);
	    return;
	}
	string newDevice=newAllDeviceList[idx];
	//DebugN(alias+" # "+oldDevice+" => "+newDevice);

	// find new device id...
	// at first in the newDeviceListObject...
	int newDeviceId=-1;
	int idxNewDev=dynContains(newDeviceListObject[fwConfigurationDB_DLO_DPNAME],newDevice);
	if (idxNewDev>=1) {
	    newDeviceId=newDeviceListObject[fwConfigurationDB_DLO_ITEMID][idxNewDev];
	} else {
	    // if not found, try the existingNewDeviceListObject;
	    idxNewDev=dynContains(existingNewDeviceListObject[fwConfigurationDB_DLO_DPNAME],newDevice);
	    if (idxNewDev>=1) newDeviceId=existingNewDeviceListObject[fwConfigurationDB_DLO_ITEMID][idxNewDev];

	}
	if (newDeviceId<0) {
	    fwException_raise(exceptionInfo,"ERROR","Cannot find the identifier of the new device","");
	    DebugN("Cannot find id for "+newDevice);
	    return;
	}

	//DebugN(oldDeviceId+" => "+newDeviceId);


	string invalidateAliasSql="update REFERENCES SET VALID_TO=TO_DATE(\'"+(string)t0+"\' , \'yyyy.mm.dd hh24:mi:ss.???\') "+
					"where VALID_TO IS NULL and refver="+refVer+
					" and ID="+aliasData[1][i];
	fwConfigurationDB_executeSqlSimple(invalidateAliasSql, g_fwConfigurationDB_DBConnection,exceptionInfo);
	if (dynlen(exceptionInfo)) {rdbRollbackTransaction(g_fwConfigurationDB_DBConnection);return;}

	string newAliasSql="insert into references(refver,id,ref_id,valid_from,valid_to) values ("+
		    refVer+" , "  +
		    aliasData[1][i]+" , " +
		    newDeviceId+" , "    +
		    " TO_DATE(\'"+(string)t0+"\' , \'yyyy.mm.dd hh24:mi:ss.???\'), "+
		    " NULL)";
	fwConfigurationDB_executeSqlSimple(newAliasSql, g_fwConfigurationDB_DBConnection,exceptionInfo);
	if (dynlen(exceptionInfo)) {rdbRollbackTransaction(g_fwConfigurationDB_DBConnection);return;}

    }

    rc=rdbCommitTransaction(g_fwConfigurationDB_DBConnection);
    if (rc) {
	//bool invalidConnection;
        //_fwConfigurationDB_catchDbError(g_fwConfigurationDB_DBConnection, invalidConnection, exceptionInfo);
        fwException_raise(exceptionInfo,"ERROR","Cannot commit transaction","");
        return;
    };


DebugN("OK!");

}


/** Stores "minimal" information about the devices to DB

  This function stores minimal information about devices into the DB,
  so that recipes for these devices may also be stored.

  @param[in,out] deviceList - list of names of devices; may include a mixture of devices
              from the HARDWARE and LOGICAL hierarchies; on exit, it will contain the
              list of devices that were actually stored/verified, namely: the non-existing
              devices are removed from the list, and devices that are needed to satisfy
              the hierarchical constraints (parents, grandparents,...) are added to the list
  @param[out] exceptionInfo - standard exception-handling parameter
  @param[in]  abortWhenDeviceMissing (optional, default FALSE) - if set to TRUE, the
              function will abort (and return an error) if some of specified devices
              does not exist, i.e. it will not store the good ones in the database; otherwise
              (the default behaviour), the missing devices will be skipped, the good ones
              will be stored in the database, and the return value of 1 will signify that
              there were missing devices.

  @retval 0 - everything OK: all devices are in DB now
  @retval 1 - some devices in the deviceList do not exist, and were skipped; the list
              of them is in the exceptionInfo; apart from that, everything was OK
  @retval -1 - there was an error while storing the devices; details in the exceptionInfo


  How to handle the return value and the exceptionInfo, when
  the @c abortWhenDeviceMissing parameter is @c FALSE.
  This example shows how to make sure that the recipeObject can be
  saved to DB. The devices that exist - are saved. For all devices
  that are missing, we post-process the recipeObject to remove the data
  for non-existing devices, then save the recipeObject to DB
  @code
    dyn_dyn_mixed recipeObject;
    // ... get the recipe into the recipeObject somehow...

    dyn_string deviceList=recipeObject[fwConfigurationDB_RO_DP_NAME];

    int rc=fwConfigurationDB_saveDevicesToDBMinimal(deviceList,exceptionInfo,FALSE);
    if (rc!=0) {
      // means something happen
      if (rc==-1) {
        fwExceptionHandling_display(exceptionInfo);
        // abort!
        return FALSE;
      } else if (rc==1) {
        // it is still OK, even though some of the devices were missing:
        // we choose not to display the exception, but only print a message to a log
        DebugN("There were some missing devices - the others were saved OK");
        // post-process the recipeObject, to remove the missing devices...
        // the good ones are returned in the (modified!) deviceList
        for (int i=1;i<=dynlen(recipeObject[fwConfigurationDB_RO_DP_NAME]);i++) {
          string dev=recipeObject[fwConfigurationDB_RO_DP_NAME][i];
          if (!dynContains(deviceList,dev)) {
            // remove the line from all data columns of the recipeObject
            for (int j=1;j<=fwConfigurationDB_RO_MAXIDX;j++) {
              dynRemove(recipeObject[j],i);
             }
             i--;//reset iterator
           }

         }
      }
    }

    // we could save the recipe into the DB now...
    fwConfigurationDB_saveRecipeToDB(recipeObject,"","MyTestRecipe",exceptionInfo);
    if (dynlen(exceptionInfo)){fwExceptionHandling_display(exceptionInfo);return;};
  @endcode

  */
int fwConfigurationDB_saveDevicesToDBMinimal(dyn_string &deviceList,
                                             dyn_string &exceptionInfo,
                                             bool abortWhenDeviceMissing=FALSE)
{

  fwConfigurationDB_checkInit(exceptionInfo);
  if (dynlen(exceptionInfo)) return;

  dynUnique(deviceList);

  dyn_string hwDevList,logDevList,devTypes;
  dyn_string dpTs;
  dyn_string mdExcInfo; // exceptionInfo for missing devices...

  // separate HW from LOGICAL...
    for (int i=1;i<=dynlen(deviceList);i++) {
      if (strpos(deviceList[i],":")<0) {
       if (dpAliasToName(deviceList[i])=="") {
         fwException_raise(mdExcInfo,"INFO",
                            "fwConfigurationDB_saveDevicesToDBMinimal: skipping non-existing alias:"+deviceList[i],
                            "");
         if (abortWhenDeviceMissing) {exceptionInfo=mdExcInfo;return 1;};
         continue;
       }
       dynAppend(logDevList,deviceList[i]);
      } else {
        if (!dpExists(deviceList[i])) {
          fwException_raise(mdExcInfo,"INFO",
                            "fwConfigurationDB_saveDevicesToDBMinimal: skipping non-existing dp:"+deviceList[i],
                            "");
          if (abortWhenDeviceMissing) {exceptionInfo=mdExcInfo;return 1;};
          continue;
        }
       dynAppend(hwDevList,deviceList[i]);
      }
    }

    // complete the logical hierarchy...
    _fwConfigurationDB_completeDevicesInHierarchy(logDevList, fwDevice_LOGICAL,"",exceptionInfo);
    if (dynlen(exceptionInfo)) return -1;

    // resolve aliases, and append the aliased dps to hardware list
    for (int i=1;i<=dynlen(logDevList);i++) {
       string dpname=dpSubStr(dpAliasToName(logDevList[i]),DPSUB_SYS_DP);
       if (dpTypeName(dpname)!="FwNode") dynAppend(hwDevList,dpname);
    }

    //complete the hardware hierarchy
    _fwConfigurationDB_completeDevicesInHierarchy(hwDevList, fwDevice_HARDWARE,getSystemName(),exceptionInfo);
    if (dynlen(exceptionInfo)) return -1;

    // now extract all dpTypes that we need
    // it is sufficient to do it for HW only (!)
    for (int i=1;i<=dynlen(hwDevList);i++) {
      string dpt=dpTypeName(hwDevList[i]);
      dynAppend(dpTs,dpt);
    }
    dynUnique(dpTs);

    //DebugN("Saving DPTs",dpTs);
    dyn_int dpTypeIds;
    dyn_mixed dpTypeElements, dpTypeElementIds;
    _fwConfigurationDB_checkSaveDpTypes(dpTs,dpTypeIds,dpTypeElements,dpTypeElementIds, getCurrentTime(), exceptionInfo);
    if (dynlen(exceptionInfo)) return -1;

    dyn_dyn_mixed deviceListObject;
    //DebugN("saving hw devs:",hwDevList);
    _fwConfigurationDB_saveDeviceHierarchyToDB("", fwDevice_HARDWARE,
                                             hwDevList,exceptionInfo,
                                             "",deviceListObject);
    if (dynlen(exceptionInfo)) return -1;
    //DebugN("Saving logical devs:",logDevList);
    _fwConfigurationDB_saveDeviceHierarchyToDB("", fwDevice_LOGICAL,
                                             logDevList,exceptionInfo,
                                             "",deviceListObject);
   if (dynlen(exceptionInfo)) return -1;
   //DebugN("Devices saved OK.");

   // on return, we want to give back the modified deviceList...
   dyn_string retDeviceList=hwDevList;
   dynAppend(retDeviceList,logDevList);
   deviceList=retDeviceList;

   // "rethrow" all the info about missing devices
   exceptionInfo=mdExcInfo;
   if (dynlen(exceptionInfo)) return 1;

   return 0;
}



/** Updates the device models in the database to the current ones
 *
 *
 * @param dpList the list of datapoint names, for which the model is to be changed.
 *               Note that if the datapoin
 * @param exceptionInfo standard framework exception-handling variable
 * @param updateAliases (optional, default TRUE), determines if the models for LOGICAL devices
 *                      which correspond to the specified datapoints should also be updated.
 *
 * @NOTE: Use with care and cautiously, of what the implications could be!
 * To be used from the dedicated device-conversion panels, such as the ones
 * for the fwWiener component.
 *
 */
void fwConfigurationDB_updateDeviceModelsInDB(dyn_string dpList, dyn_string &exceptionInfo, bool updateAliases=TRUE)
{
    dyn_string aliases;
    if (updateAliases){
        // resolve the aliases
        dyn_string dpListTemp;
        for (int i=1;i<=dynlen(dpList);i++) dpListTemp[i]=dpList[i]+".";
        aliases=dpGetAlias(dpListTemp);
    }

    fwConfigurationDB_checkInit(exceptionInfo);
    if (dynlen(exceptionInfo)) return;

    if (fwConfigurationDB_hasDBConnectivity==FALSE) {
        fwException_raise(exceptionInfo,"ERROR","The connection to ConfigurationDB is not available.","");
        return;
    }

    dbConnection dbCon = g_fwConfigurationDB_DBConnection;

    int rc=rdbBeginTransaction(dbCon);
    if (rc) {
        fwException_raise(exceptionInfo,"ERROR","Cannot start database transaction","");
        return;
    };

    string sqlStatement="UPDATE ITEMS SET DETAIL= :1 WHERE DPNAME= :2";

    dyn_dyn_mixed data;
    int idx=1;
    for (int i=1;i<=dynlen(dpList);i++) {
        string model;
        fwDevice_getModel(makeDynString(dpList[i]),model,exceptionInfo);
        if (dynlen(exceptionInfo)) {fwExceptionHandling_display(exceptionInfo); return;};
        dyn_mixed rowData=makeDynMixed(model,dpList[i]);
        data[idx++]=rowData;
        if (updateAliases && dynlen(aliases)>=i) {
            if (aliases[i]!=""){
                rowData=makeDynMixed(model,aliases[i]);
                data[idx++]=rowData;
            }
        }
    }

//  DebugN("Updating the models in the database... Please wait");
    _fwConfigurationDB_executeDBBulkCmd(sqlStatement,dbCon, data, exceptionInfo);
    if (dynlen(exceptionInfo)) {
        rdbRollbackTransaction(dbCon);
        return;
    }

    int rc=rdbCommitTransaction(dbCon);
    if (rc) {
        fwException_raise(exceptionInfo,"ERROR","Cannot commit database transaction","");
        return;
    };

    DebugN("Device models updated OK.");
}
