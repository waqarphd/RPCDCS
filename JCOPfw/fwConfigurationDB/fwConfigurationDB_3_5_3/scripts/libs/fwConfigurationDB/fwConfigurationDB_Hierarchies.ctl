/**@file

This package contains hierarchy-related functions of the Configuration Database tool

@author Piotr Golonka (EN/ICE-SCD)
@date   February 2012
*/

global string _fwConfigurationDB_fileVersion_fwConfigurationDB_Hierarchies_ctl="3.5.3";



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
const int fwConfigurationDB_deviceConfig_NO_DEVICE_CREATE = 16384;// skip the devices that does not already exits, ie. "configure existing only" option for CMS
const int fwConfigurationDB_deviceConfig_FW_DEFAULTS = 32768;
const int fwConfigurationDB_deviceConfig_ADOPT_TO_SYSTEM = 65536;

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
const int fwConfigurationDB_DLO_PARENTDPNAME = 9; // parent's DP (full) name
const int fwConfigurationDB_DLO_DPID = 10;   // only for h/w hierarchy: datapoint id

const int fwConfigurationDB_DLO_REFDP = 11; // for logical hierarchy: the h/w device dpname is here

const int fwConfigurationDB_DLO_REFID = 12; // for logical hierarchy: the h/w device id is here when storing
const int fwConfigurationDB_DLO_REF_STATUS = 13; // for logical hierarchy: the status of the reference: 1: alias does not exits yet,
						// 2 - alias already exists and needs to be unmapped before assigning to the new device
						// 0 - undefined

const int fwConfigurationDB_DLO_PROPIDS = 14; // dyn_int list of item property id's from the database; each propId reflects
					      // the settings for one device (data point) element;
					      // this propid is used as key to the configs data for indicated elements
const int fwConfigurationDB_DLO_PROPNAMES = 15; // dyn_string list of item property names, corresponding to propids

const int fwConfigurationDB_DLO_CITEM_ID = 16; // CITEM_ID pointer...
const int fwConfigurationDB_DLO_MAX_IDX = 16;
//@} // end of indexing constants
//______________________________________________________________________________



void fwConfigurationDB_updateDeviceConfigurationFromDB(string configurationName,
    string hierarchyType, dyn_string &exceptionInfo,  time validOn=0, dyn_string deviceList="", string systemName="",
    int options=fwConfigurationDB_deviceConfig_ALLDEVPROPS)
{


    fwConfigurationDB_checkInit(exceptionInfo);
    if (fwConfigurationDB_checkErrors(exceptionInfo,false)) return;
    
    if (fwConfigurationDB_SchemaPrivs!="OWNER" && fwConfigurationDB_SchemaPrivs!="WRITER" && fwConfigurationDB_SchemaPrivs!="READER") {
	fwException_raise(exceptionInfo,"ERROR","Insufficient database rights to load static configuration","");
	fwConfigurationDB_checkErrors(exceptionInfo,false);
	return;
    }

    dyn_string origDeviceList=deviceList;

    dyn_dyn_mixed deviceListObject;

    // check if we got anything in the deviceList, if not - clear it...
    if (dynlen(deviceList)==1 && deviceList[1]=="") dynClear(deviceList);
    
    // PRE-SELECT THE DEVICES, EXPLORE THE HIERARCHY

    if (fwConfigurationDB_progress(fwConfigurationDB_OPER_LoadDevices,"Selecting devices to load", 1.0, exceptionInfo,false)) return;
    
    string topNode=""; // would mean: current system...
    int rc = _fwConfigurationDB_selectDevicesToLoad(configurationName, hierarchyType, deviceList, exceptionInfo, topNode);
    if (fwConfigurationDB_checkErrors(exceptionInfo,false)) return;
    // note: on return the deviceList might have been modified, and contains matching devices!
    if (dynlen(deviceList)==0) {
	fwException_raise(exceptionInfo,"WARNING","No valid devices to load","");
	DebugTN("WARNING No valid devices to load; original deviceList",origDeviceList);
	fwConfigurationDB_checkErrors(exceptionInfo, false);
	return;
    }

    // CHECK WHICH DEVICES EXIST
    dyn_string missingDevices;
    if (hierarchyType==fwDevice_HARDWARE) {
	for (int i=1;i<=dynlen(deviceList);i++) {
	    if (!dpExists(deviceList[i])) {
		dynAppend(missingDevices,deviceList[i]);
	    }
	}
	
	if (options & fwConfigurationDB_deviceConfig_NO_DEVICE_CREATE && dynlen(missingDevices)) {
	    //DebugTN("CONFIGURE WITHOUT RE-CREATING DEVICES: Filtering the list of properties");

	    fwConfigurationDB_executeSqlSimple("DELETE FROM TMP_ITEM_PROPS",g_fwConfigurationDB_DBConnection,exceptionInfo);
	    if (fwConfigurationDB_checkErrors(exceptionInfo,false)) return;

	    string sql="INSERT INTO TMP_ITEM_PROPS(DPENAME) VALUES(:DEVICE)";

	    _fwConfigurationDB_executeDBBulkCmd(sql,g_fwConfigurationDB_DBConnection, makeDynMixed(missingDevices), exceptionInfo, TRUE);
	    if (fwConfigurationDB_checkErrors(exceptionInfo,false)) return;

	    sql="DELETE FROM CDB_API_PARAMS WHERE S1 IN (SELECT DPENAME FROM TMP_ITEM_PROPS)";
	    fwConfigurationDB_executeSqlSimple(sql,g_fwConfigurationDB_DBConnection,exceptionInfo);
	    if (fwConfigurationDB_checkErrors(exceptionInfo,false)) return;
	    


	    // we do not need the content of TMP_ITEM_PROPS
	    fwConfigurationDB_executeSqlSimple("DELETE FROM TMP_ITEM_PROPS",g_fwConfigurationDB_DBConnection,exceptionInfo);
	    if (fwConfigurationDB_checkErrors(exceptionInfo,false)) return;
	    

	    // re-query the device list
	    dyn_dyn_mixed data;
	    sql="SELECT S1 from CDB_API_PARAMS order by s1";
	    _fwConfigurationDB_executeDBQuery(sql, g_fwConfigurationDB_DBConnection,data,exceptionInfo,1,TRUE);
	    if (fwConfigurationDB_checkErrors(exceptionInfo,false)) return;
	    

	    if (!dynlen(data)) {
		DebugTN("No devices left to configure. Exiting...");
		fwConfigurationDB_closeProgressDialog();
		return;
	    }
	    deviceList=data[1];
	    DebugTN("Devices that were left:",deviceList);

	} else {
	    DebugTN("We need to create devices:",dynlen(missingDevices));
	    DebugTN("Obtaining additional info from DB");
	    dyn_dyn_mixed data;
	    string sql = "select  cdb.i1,cdb.s1, i.name,i.type,i.detail,i.parent,i.description,i.dpid "+
	        " from items i, cdb_api_params cdb where cdb.i1=i.id order by dpid";
	    _fwConfigurationDB_executeDBQuery(sql, g_fwConfigurationDB_DBConnection,data,exceptionInfo,8,TRUE);
	    if (fwConfigurationDB_checkErrors(exceptionInfo,false)) return;
	    if (dynlen(data)>0) {	    
DebugTN("We will assign to deviceListObject...");	
    		deviceListObject[fwConfigurationDB_DLO_ITEMID]=data[1];
    		deviceListObject[fwConfigurationDB_DLO_PARENTID]=data[6];
    		deviceListObject[fwConfigurationDB_DLO_NAME]=data[3];;
    		deviceListObject[fwConfigurationDB_DLO_DPNAME]=data[2];
    		deviceListObject[fwConfigurationDB_DLO_DPTYPE]=data[4];
    		deviceListObject[fwConfigurationDB_DLO_MODEL]=data[5];
    		deviceListObject[fwConfigurationDB_DLO_COMMENT]=data[7];
    		deviceListObject[fwConfigurationDB_DLO_DPID]=data[8];
    	    }
    	}
    } else if (hierarchyType==fwDevice_LOGICAL) {
	DebugTN("Obtaining additional info from DB");
	dyn_dyn_mixed data;
	
	string sql = "select  c1.i1 devid, c1.s1 dpname, c1.s2 refdpname, c1.s3 devtype, c1.s4 devmodel,c1.s5 devname"+
	    " from cdb_api_params c1";
	_fwConfigurationDB_executeDBQuery(sql, g_fwConfigurationDB_DBConnection,data,exceptionInfo,6,TRUE);
	if (fwConfigurationDB_checkErrors(exceptionInfo,false)) return;
	

DebugTN("We will assign to deviceListObject...");
	if (dynlen(data)>0) {
    	    deviceListObject[fwConfigurationDB_DLO_ITEMID]=data[1];
    	    deviceListObject[fwConfigurationDB_DLO_DPNAME]=data[2];
    	    deviceListObject[fwConfigurationDB_DLO_REFDP]=data[3];    
    	    deviceListObject[fwConfigurationDB_DLO_DPTYPE]=data[4];
    	    deviceListObject[fwConfigurationDB_DLO_MODEL]=data[5];
    	    deviceListObject[fwConfigurationDB_DLO_NAME]=data[6];
	}
    }
    
    if (options && fwConfigurationDB_deviceConfig_ADOPT_TO_SYSTEM) {
    if (fwConfigurationDB_progress(fwConfigurationDB_OPER_LoadDevices,"Adopting devices to current system", 6.0, exceptionInfo,false)) return;

	DebugTN("Replacing the system name for remote devices");    

	if (hierarchyType==fwDevice_HARDWARE) {
	    dyn_string origDPNames=deviceListObject[fwConfigurationDB_DLO_DPNAME];
	    dyn_string localDPNames;

	    for (int i=1;i<=dynlen(origDPNames);i++) {
		dyn_string ds=strsplit(origDPNames[i],":");
		string localName=origDPNames[i];
		if (dynlen(ds)>1) localName=getSystemName()+ds[2];
		localDPNames[i]=localName;
	    }
	    deviceListObject[fwConfigurationDB_DLO_DPNAME]= localDPNames;

	} else if (hierarchyType==fwDevice_LOGICAL) {
	    dyn_string origRefNames=deviceListObject[fwConfigurationDB_DLO_REFDP];
	    dyn_string localRefNames;

	    for (int i=1;i<=dynlen(origRefNames);i++) {
		dyn_string ds=strsplit(origRefNames[i],":");
		string localName=origRefNames[i];
		if (dynlen(ds)>1) localName=getSystemName()+ds[2];
		localRefNames[i]=localName;
	    }
	    deviceListObject[fwConfigurationDB_DLO_REFDP] = localRefNames;
	}
    }

    if (fwConfigurationDB_progress(fwConfigurationDB_OPER_LoadDevices,"Verifying existing devices", 8.0, exceptionInfo,false)) return;

DebugTN("We call verifyDatapoints...");
    dyn_dyn_mixed missingDeviceListObject;
    _fwConfigurationDB_verifyDatapoints(hierarchyType,
                                      deviceListObject, missingDeviceListObject,
                                      exceptionInfo,TRUE);
    if (fwConfigurationDB_checkErrors(exceptionInfo,false)) return;

//DebugTN("going to create devices",dynlen(missingDeviceListObject[1]),dynlen(deviceList));
    if (fwConfigurationDB_progress(fwConfigurationDB_OPER_LoadDevices,"Creating missing devices", 10.0, exceptionInfo,false)) return;

	_fwConfigurationDB_createDevices(missingDeviceListObject,hierarchyType, exceptionInfo);
	if (fwConfigurationDB_checkErrors(exceptionInfo,false)) return;
	
DebugTN("Creation done!");
    
    

    if (fwConfigurationDB_progress(fwConfigurationDB_OPER_LoadDevices,"Configuring devices", 20.0, exceptionInfo,false)) return;

DebugTN("Configuring...");
    _fwConfigurationDB_configureDevices(deviceListObject,hierarchyType,exceptionInfo,options);
    if (fwConfigurationDB_checkErrors(exceptionInfo,false)) return;
    

DebugTN("Configuration done");
    fwConfigurationDB_closeProgressDialog();
}



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
void _fwConfigurationDB_copyDeviceListObjectEntry(dyn_dyn_mixed &srcObject, int src_idx,
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
	string parentName="";
        unsigned dpid=-1;
        if ( (deviceList[i]==system)||(deviceList[i]=="")) {
            dpname=system;
	    itemname=dpname;
            dptype="";
            parentName="";
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
    	fwDevice_getParent(itemname,parentName,exceptionInfo);
//DebugTN("got parent",itemname,parentName);
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
		    parentName=dpSubStr(nsdpname,DPSUB_SYS);
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

	// fix parent name...
	if (parentName=="") parentName=dpSubStr(nsdpname,DPSUB_SYS);

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
	deviceListObject[fwConfigurationDB_DLO_PARENTDPNAME][idx]=parentName;

	deviceListObject[fwConfigurationDB_DLO_REFDP][idx]="";
        deviceListObject[fwConfigurationDB_DLO_REFID][idx]="";
        deviceListObject[fwConfigurationDB_DLO_REF_STATUS][idx]=0;

        deviceListObject[fwConfigurationDB_DLO_PROPNAMES][idx]=makeDynString();
        deviceListObject[fwConfigurationDB_DLO_PROPIDS][idx]=makeDynInt(); // to be resolved later
    };

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
//if (i%100==1) DebugTN(i,dynlen(deviceListObject[fwConfigurationDB_DLO_DPNAME]),"We process",dpname,type,model);

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




/////////////////
void _fwConfigurationDB_createDevices(dyn_dyn_mixed deviceListObject, string hierarchyType, dyn_string &exceptionInfo)
{
    int sysId=getSystemId();

    // we should check for missing dpTypes
    dyn_string dpts=deviceListObject[fwConfigurationDB_DLO_DPTYPE];
    dynUnique(dpts);
    dyn_string alldpts=dpTypes();
    for (int i=1;i<=dynlen(dpts);i++) {
	if (!dynContains(alldpts,dpts[i])) {
	    string errMsg="Missing datapoint type "+dpts[i];
	    dyn_string dpts2=deviceListObject[fwConfigurationDB_DLO_DPTYPE];
	    int idx=dynContains(dpts2,dpts[i]);
	    if (idx) errMsg+="\nfor "+deviceListObject[fwConfigurationDB_DLO_DPNAME][idx];
	    fwException_raise(exceptionInfo,"ERROR",errMsg,"");
	    return;
	}
    }

    int maxdev=dynlen(deviceListObject[fwConfigurationDB_DLO_DPNAME]);
    for (int i=1;i<=maxdev;i++){
        string dpname=_fwConfigurationDB_NodeNameWithoutSystem(deviceListObject[fwConfigurationDB_DLO_DPNAME][i]);
        string dptype=deviceListObject[fwConfigurationDB_DLO_DPTYPE][i];
        string model=deviceListObject[fwConfigurationDB_DLO_MODEL][i];
        if (i%10==1) {
            if (fwConfigurationDB_progress(fwConfigurationDB_OPER_LoadDevices,"Creating devices",
                                           10.0+10.0*i/maxdev, exceptionInfo)) return;
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
    	    int dpid=deviceListObject[fwConfigurationDB_DLO_DPID][i];
            int rc=dpCreate(dpname,dptype,sysId,dpid);
            if (rc) {fwException_raise(exceptionInfo,"ERROR","Failed to create datapoint "+dpname,"");return;}
            // additional workaround for ENS-4865 (dpCreate fails silently)
            if (!dpExists(dpname)) {
        	// try to create the DP without specifying DPID
        	rc=dpCreate(dpname,dptype,sysId);
        	dyn_errClass err=getLastError();
        	if (dynlen(err) || rc) {
        	    DebugTN("Datapoint creation failed",rc,err);
        	    fwException_raise(exceptionInfo,"ERROR","Failed to create datapoint "+dpname,"");return;
        	}
            }
            string comment=deviceListObject[fwConfigurationDB_DLO_COMMENT][i];
            if (comment!="") dpSetComment ( dpname+".",comment);
        } else {

            // framework device...
            dyn_string deviceObject;
            deviceObject[fwDevice_DP_NAME]=dpname;
            deviceObject[fwDevice_DP_TYPE]=dptype;
            deviceObject[fwDevice_MODEL]=model;
            deviceObject[fwDevice_COMMENT]=deviceListObject[fwConfigurationDB_DLO_COMMENT][i];
            //DebugN("going to create Fw Device",deviceObject);
            fwDevice_create(deviceObject, makeDynString(""),exceptionInfo);
            if (dynlen(exceptionInfo)) return;
        }
    }
    if (fwConfigurationDB_progress(fwConfigurationDB_OPER_ApplyHierarchyToSystem,"DONE",100.0, exceptionInfo)) return;

}


void _fwConfigurationDB_configureDevices(dyn_dyn_mixed &deviceListObject,string hierarchyType, dyn_string &exceptionInfo,
    int options=fwConfigurationDB_deviceConfig_ALLDEVPROPS)
{

    if (hierarchyType==fwDevice_HARDWARE) {
    
	if (!(options & fwConfigurationDB_deviceConfig_FW_DEFAULTS)) {
    	    _fwConfigurationDB_configureDevicesFromDB(exceptionInfo, options);
    	    if (dynlen(exceptionInfo)) return;
    	    return;
    	} else {
    	    _fwConfigurationDB_configureFwDevicesWithDefaults(deviceListObject[fwConfigurationDB_DLO_DPNAME], 
    							      deviceListObject[fwConfigurationDB_DLO_DPTYPE],
    							      deviceListObject[fwConfigurationDB_DLO_MODEL], exceptionInfo);
    	    if (dynlen(exceptionInfo)) return;
    	    return;
    	}
    	
    } else if (hierarchyType==fwDevice_LOGICAL) {
	int maxdev=dynlen(deviceListObject[fwConfigurationDB_DLO_DPNAME]);

	// at first check if the linked devices in HARDWARE exist, (and if they are local)
        for (int i=1;i<=maxdev;i++) {
            string type      = deviceListObject[fwConfigurationDB_DLO_DPTYPE][i];
            string aliasName= _fwConfigurationDB_NodeNameWithoutSystem(deviceListObject[fwConfigurationDB_DLO_DPNAME][i]);

            dyn_string exceptionInfo2;
            string refDp=_fwConfigurationDB_NodeNameWithSystem(deviceListObject[fwConfigurationDB_DLO_REFDP][i],getSystemName(),exceptionInfo2);
            if (dynlen(exceptionInfo2)) {
        	deviceListObject[fwConfigurationDB_DLO_REF_STATUS][i]=-1;// mark it as invalid...
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




void fwConfigurationDB_getDeviceConfigurations(string hierarchyType,
	dyn_string &confNames, dyn_string &confDescriptions, dyn_int &confIds,
	dyn_string &exceptionInfo)
{
    //string sql="SELECT conf_tag, description, conf_id FROM config_desc "+" where hver="+g_fwConfigurationDB_DBHierarchyIDs[hierarchyType];
    string sql="SELECT conf_tag, description, conf_id FROM config_desc order by conf_tag";

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
    int confId;
    string sql;
    fwConfigurationDB_getDeviceConfigurations(hierarchyType,
		confNames, confDescriptions,confIds, exceptionInfo);
    if (dynlen(exceptionInfo)) return 0;

    int idx=dynContains(confNames, confName);

    if (idx<=0) {
        // configuration does note exist yet - create one
	sql="SELECT CONF_ID_SEQ.NextVal FROM DUAL";
	dyn_mixed aRecords;
	_fwConfigurationDB_executeDBQuery(sql,g_fwConfigurationDB_DBConnection,aRecords,exceptionInfo);
        if (dynlen(exceptionInfo)) {fwDbRollbackTransaction(g_fwConfigurationDB_DBConnection);return 0;}
        
	confId=aRecords[1][1];

        sql="INSERT INTO config_desc(conf_id,conf_tag,description) VALUES (:CONF_ID,:CONF_NAME,:CONF_DESCRIPTION)";
	mapping params;
	params[":CONF_ID"]=confId;
	params[":CONF_NAME"]=confName;
	params[":CONF_DESCRIPTION"]=confDescription;

	_fwConfigurationDB_executeDBCmd(sql,g_fwConfigurationDB_DBConnection, params, exceptionInfo);
        if (dynlen(exceptionInfo)) {fwDbRollbackTransaction(g_fwConfigurationDB_DBConnection);return 0;}
        
    } else {
        confId=confIds[idx];
        // if new description given, set it (#32960)
        if (confDescription!="") {
            sql="UPDATE CONFIG_DESC SET DESCRIPTION=:CONF_DESCRIPTION WHERE CONF_ID=:CONF_ID";
	    mapping params;
	    params[":CONF_DESCRIPTION"]=confDescription;
	    params[":CONF_ID"]=confId;
	    _fwConfigurationDB_executeDBCmd(sql,g_fwConfigurationDB_DBConnection, params, exceptionInfo);
    	    if (dynlen(exceptionInfo)) {fwDbRollbackTransaction(g_fwConfigurationDB_DBConnection);return 0;}
        }
    }
    return confId;
}



void _fwConfigurationDB_checkSaveDpTypes(dyn_string dpTypes,dyn_int &dpTypeIds,
	    dyn_mixed &dpTypeElements, dyn_mixed &dpTypeElementIds, time date, dyn_string &exceptionInfo)
{
    if (!dynlen(dpTypes)) return;

DebugTN("CheckSaveDpTypes");

    // we will again use the temporary table to lay out the data, and then flush it to the 
    // final destination; we will combine everything in CDB_API_PARAMS
    //
    //  s1: DpType name
    //  s2: element name
    //  i3: element type
    
    string sql="INSERT INTO CDB_API_PARAMS(S1,S2,i3) VALUES(:DPTName,:ElementName,:ElementType)";

    // extract the information about the dpTypes, and format them into an array ready-to use...
    dyn_dyn_mixed data;
    dyn_int allElemetTypes;
    int nrows=0;
    for (int i=1;i<=dynlen(dpTypes);i++) {
	dyn_string elementNames;
	dyn_int elementTypes;
	_fwConfigurationDB_getDPTElements2(dpTypes[i], elementNames, elementTypes,exceptionInfo,TRUE);
	if (dynlen(exceptionInfo)) {fwDbRollbackTransaction(g_fwConfigurationDB_DBConnection);return;}
	
	for (int j=1;j<=dynlen(elementNames);j++) {
	    dyn_mixed row=makeDynMixed(dpTypes[i],elementNames[j],elementTypes[j]);
	    nrows++;
	    data[nrows]=row;
	}
    }

    // cleanup data-transfer table
    fwConfigurationDB_executeSqlSimple("DELETE FROM CDB_API_PARAMS", g_fwConfigurationDB_DBConnection,exceptionInfo);
    if (dynlen(exceptionInfo)) {fwDbRollbackTransaction(g_fwConfigurationDB_DBConnection);return;}


    _fwConfigurationDB_executeDBBulkCmd(sql,g_fwConfigurationDB_DBConnection, data, exceptionInfo);
    if (dynlen(exceptionInfo)) {fwDbRollbackTransaction(g_fwConfigurationDB_DBConnection);return;}

    // now call the insert function!
    fwConfigurationDB_executeSqlSimple("DECLARE rc number;BEGIN rc:=fwConfigurationDB.checkSaveDpTypes;end;", g_fwConfigurationDB_DBConnection,exceptionInfo);
    if (dynlen(exceptionInfo)) {fwDbRollbackTransaction(g_fwConfigurationDB_DBConnection);return;}

    // and clean up the temporary table...
    fwConfigurationDB_executeSqlSimple("DELETE FROM CDB_API_PARAMS", g_fwConfigurationDB_DBConnection,exceptionInfo);
    if (dynlen(exceptionInfo)) {fwDbRollbackTransaction(g_fwConfigurationDB_DBConnection);return;}
    
}


void _fwConfigurationDB_configureFwDevicesWithDefaults(dyn_string &dps, dyn_string &dptypes,
    dyn_string &models, dyn_string &exceptionInfo)
{

DebugTN("REVIEW/OPTIMIZE ME:_configureFwDevicesWithDefaults");
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







void _fwConfigurationDB_configureDevicesFromDB(dyn_string &exceptionInfo, int options=fwConfigurationDB_deviceConfig_ALLDEVPROPS)
{

    dyn_dyn_mixed data;

    
    
    // the contents of temporary table TMP_ITEM_PROPS is preserved only for the time of transaction: start one
//    fwDbRollbackTransaction(g_fwConfigurationDB_DBConnection);
//    fwDbBeginTransaction(g_fwConfigurationDB_DBConnection);

    fwConfigurationDB_executeSqlSimple("DELETE FROM TMP_ITEM_PROPS", g_fwConfigurationDB_DBConnection, exceptionInfo);
    if (dynlen(exceptionInfo)) return;

    if (fwConfigurationDB_progress(fwConfigurationDB_OPER_LoadDeviceProperties,"Selecting properties", 15.0, exceptionInfo)) return;    

    DebugTN("Selecting the properties"); 
    string sql = "INSERT INTO TMP_ITEM_PROPS(iprop_id,dpename) "+
          "  select cip.iprop_id, CDB.s1||de.elementname "+
          "  from   cdb_api_params cdb, config_itemprops cip, device_elements de "+
          "  where "+
          "  cip.citem_id=cdb.i2 and "+
          "  cip.develem_id=de.develem_id";

    DebugTN("We execute",sql);
    fwConfigurationDB_executeSqlSimple(sql, g_fwConfigurationDB_DBConnection, exceptionInfo);
    if (dynlen(exceptionInfo)) return;
    DebugTN("Done...");


    if (options && fwConfigurationDB_deviceConfig_ADOPT_TO_SYSTEM) {
	DebugTN("We need to update system names for configs of remote devices...");
	sql="UPDATE TMP_ITEM_PROPS SET DPENAME=regexp_replace(DPENAME,'[^:]+[:]+','"+getSystemName()+"',1,1)";
	DebugTN("We execute",sql);
	fwConfigurationDB_executeSqlSimple(sql, g_fwConfigurationDB_DBConnection, exceptionInfo);
	if (dynlen(exceptionInfo)) return;
    }

    string sql = "select count(*) from tmp_item_props tip";
    DebugTN("Executing",sql);
    _fwConfigurationDB_executeDBQuery(sql, g_fwConfigurationDB_DBConnection,data,exceptionInfo,2,TRUE);
    if (dynlen(exceptionInfo)) return;
    int nProps=data[1][1];
    DebugTN("We have "+nProps+" properties to configure");
    
    if (options & fwConfigurationDB_deviceConfig_VALUE) {
	if (fwConfigurationDB_progress(fwConfigurationDB_OPER_LoadDevices,"Configuring Values", 20.0, exceptionInfo)) return;
	_fwConfigurationDB_loadApplyValues(exceptionInfo);
	if (dynlen(exceptionInfo)) return;
    }
    

    if (options & fwConfigurationDB_deviceConfig_ALERT) {
	if (fwConfigurationDB_progress(fwConfigurationDB_OPER_LoadDevices,"Configuring Alerts", 30.0, exceptionInfo)) return;
	_fwConfigurationDB_loadApplyAlerts(exceptionInfo);
	if (dynlen(exceptionInfo)) return;
	if (fwConfigurationDB_progress(fwConfigurationDB_OPER_LoadDevices,"Configuring Summary Alerts", 35.0, exceptionInfo)) return;
	_fwConfigurationDB_loadApplySumAlerts(exceptionInfo);
	if (dynlen(exceptionInfo)) return;
    }

    if (options & fwConfigurationDB_deviceConfig_ADDRESS) {
	if (fwConfigurationDB_progress(fwConfigurationDB_OPER_LoadDevices,"Configuring Addresses", 40.0, exceptionInfo)) return;
	_fwConfigurationDB_loadApplyAddresses(exceptionInfo);
	if (dynlen(exceptionInfo)) return;
    }

    if (options & fwConfigurationDB_deviceConfig_ARCHIVING) {
	if (fwConfigurationDB_progress(fwConfigurationDB_OPER_LoadDevices,"Configuring Archiving", 50.0, exceptionInfo)) return;
	_fwConfigurationDB_loadApplyArchiving(exceptionInfo);
	if (dynlen(exceptionInfo)) return;
    }

    
    if (options & fwConfigurationDB_deviceConfig_DPFUNCTION) {
	if (fwConfigurationDB_progress(fwConfigurationDB_OPER_LoadDevices,"Configuring DPFunctions", 60.0, exceptionInfo)) return;
	_fwConfigurationDB_loadApplyDpFunctions(exceptionInfo,options);
	if (dynlen(exceptionInfo)) return;
    }

    
    if (options & fwConfigurationDB_deviceConfig_CONVERSION) {
	if (fwConfigurationDB_progress(fwConfigurationDB_OPER_LoadDevices,"Configuring Conversions", 70.0, exceptionInfo)) return;
	_fwConfigurationDB_loadApplyConversions(exceptionInfo);
	if (dynlen(exceptionInfo)) return;
    }

    
    if (options & fwConfigurationDB_deviceConfig_PVRANGE) {
	if (fwConfigurationDB_progress(fwConfigurationDB_OPER_LoadDevices,"Configuring PVRange", 80.0, exceptionInfo)) return;
	_fwConfigurationDB_loadApplyPvRanges(exceptionInfo);
	if (dynlen(exceptionInfo)) return;
    }

    
    if (options & fwConfigurationDB_deviceConfig_SMOOTHING) {
	if (fwConfigurationDB_progress(fwConfigurationDB_OPER_LoadDevices,"Configuring Smoothing", 90.0, exceptionInfo)) return;
	_fwConfigurationDB_loadApplySmoothing(exceptionInfo);
	if (dynlen(exceptionInfo)) return;
    }
    
    
    if (options & fwConfigurationDB_deviceConfig_UNITANDFORMAT) {
	if (fwConfigurationDB_progress(fwConfigurationDB_OPER_LoadDevices,"Configuring Unit and Format", 95.0, exceptionInfo)) return;
	_fwConfigurationDB_loadApplyUnitAndFormat(exceptionInfo);
	if (dynlen(exceptionInfo)) return;
    }
    
    if (dynlen(exceptionInfo)) return;
    

    //// to wipe-out the temporary table, we need to commit the transaction...
    //int rc=fwDbCommitTransaction(g_fwConfigurationDB_DBConnection);
    //if (rc) {
    //    fwException_raise(exceptionInfo,"ERROR","Cannot commit transaction","");
    //    return;
    //};

    if (fwConfigurationDB_progress(fwConfigurationDB_OPER_LoadDevices,"DONE", 100.0, exceptionInfo)) return;

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

    int rc=fwDbBeginTransaction(dbCon);
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
        fwDbRollbackTransaction(dbCon);
        return;
    }

    int rc=fwDbCommitTransaction(dbCon);
    if (rc) {
        fwException_raise(exceptionInfo,"ERROR","Cannot commit database transaction","");
        return;
    };

    DebugN("Device models updated OK.");
}




///////////////////////////
/** Selects the devices to be loaded, prepares the data in ConfDB
     data-exchange tables.
     
     There are two ways to specify the list of devices:
      - explicitly: by passing it as input in deviceList parameter
      - look-up in the DB: specify the top node, such
        as the system name; this mode is activated by the fact of
        passing empty deviceList on input (on output it will be
        populated with device names); the topNode parameter
        should be passed: if left empty, the name of the current
        system will be taken.
     
     Then a cross-check is done on the deviceList passed on input:
     if all devices indeed exist in the specified configuration,
     the deviceList parameter, then they are sorted alphabeticaly
     (so that on return the deviceList param DIFFERS than the one on input)
      all the preparation is done and return code of zero is returned.
     However, if some of devices passed in deviceList are not
     present in the database, they will be skipped - on return
     a modified deviceList parameter will have the valid one,
     and the return value from the function will be 1
     
     Return codes less than zero signify an error - details in exceptionInfo
*/
int _fwConfigurationDB_selectDevicesToLoad(string configurationName, 
    string hierarchyType, dyn_string &deviceList, dyn_string &exceptionInfo, string topNode="")
{
    string sql;
    int rc;
    int hver;
    bool deviceListModified=FALSE;
    dyn_mixed params;
    dyn_dyn_mixed data;

    // check if specified configurationName exists
    sql="SELECT CONF_ID FROM CONFIG_DESC WHERE CONF_TAG=:1";
    params[1]=configurationName;
    _fwConfigurationDB_executeDBQueryWithParams(sql, g_fwConfigurationDB_DBConnection,params,data,exceptionInfo,1,FALSE);
    if (dynlen(exceptionInfo)) return -1;
    if (dynlen(data)<1) {
	fwException_raise(exceptionInfo,"ERROR","Static configuration does not exist in DB:"+configurationName,"");
	return -1;
    }
    int configId=data[1][1];

    dynClear(params);
    dynClear(data);
    
    // query the hierarchy
    sql="SELECT HVER FROM HIERARCHIES WHERE HTYPE=:1";
    params[1]=hierarchyType;
    _fwConfigurationDB_executeDBQueryWithParams(sql, g_fwConfigurationDB_DBConnection,params,data,exceptionInfo,1,FALSE);
    if (dynlen(exceptionInfo)) return -1;
    if (dynlen(data)<1) {
	fwException_raise(exceptionInfo,"ERROR","Unknown hierarchy type:"+hierarchyType,"");
	return -1;
    }
    hver=data[1][1];

    dynClear(params);
    dynClear(data);
    sql="";
    
    // do a cleanup of data-handling tables
    fwConfigurationDB_executeSqlSimple("DELETE FROM TMP_ITEM_PROPS",g_fwConfigurationDB_DBConnection,exceptionInfo);
    if (dynlen(exceptionInfo)) return -1;
    fwConfigurationDB_executeSqlSimple("DELETE FROM CDB_API_PARAMS",g_fwConfigurationDB_DBConnection,exceptionInfo);
    if (dynlen(exceptionInfo)) return -1;


    if (dynlen(deviceList)==0) {
	// this is "lookup mode": we do a hierarchical query

	if (hierarchyType==fwDevice_LOGICAL && topNode=="") {
	    sql = "insert into cdb_api_params(i1,s1) "+
		  " (select i.id,i.dpname from items i where i.hver=:1 "+
	    	"   start with i.dpname is null and i.parent is null connect by prior i.id=i.parent)";

	    params[1]=hver;

	} else{
	
	    if (topNode=="") topNode=getSystemName();
	    // firstly, let's resolve the devices in the hierarchy
	    sql = "insert into cdb_api_params(i1,s1) "+
		  " (select i.id, i.dpname from items i where i.hver=:1 "+
	    	"   start with i.dpname=:2 connect by prior i.id=i.parent)";

	    params[1]=hver;
	    params[2]=topNode;
	}
//DebugTN("Executing",sql,params);
	_fwConfigurationDB_executeDBCmd(sql,g_fwConfigurationDB_DBConnection, params, exceptionInfo);
	if (dynlen(exceptionInfo)) return -1;
    } else {
	// explicit list given: transmit it to DB

	dyn_string wildcardDevices;
	// firstly separate the items that contain wildcards: (*)
	for (int i=1;i<=dynlen(deviceList);i++) {
	    string dev=deviceList[i];
	    if (strpos(dev,'*')>=0) {
		dynRemove(deviceList,i);
		i--;
		strreplace(dev,'*','%');
		sql="INSERT INTO CDB_API_PARAMS(S1) SELECT DPNAME FROM ITEMS WHERE DPNAME LIKE :dev AND HVER=:hver";
		_fwConfigurationDB_executeDBCmd(sql,g_fwConfigurationDB_DBConnection, makeDynMixed(dev,hver), exceptionInfo);
		if (dynlen(exceptionInfo)) return -1;
	    }
	}

	sql = "INSERT INTO CDB_API_PARAMS(S1) VALUES (:DEVICE)";
//DebugTN("Executing",sql);
	_fwConfigurationDB_executeDBBulkCmd(sql, g_fwConfigurationDB_DBConnection, makeDynMixed(deviceList), exceptionInfo, TRUE);
	if (dynlen(exceptionInfo)) return -1;

	// remove duplicate entries
	sql="DELETE FROM CDB_API_PARAMS a WHERE "+
    	    "rowid > (select min(rowid) from CDB_API_PARAMS b  where b.S1 = a.S1 )";
//DebugTN("Executing",sql);
	fwConfigurationDB_executeSqlSimple(sql,g_fwConfigurationDB_DBConnection,exceptionInfo);

	// resolve the ones that are known...
	sql="UPDATE cdb_api_params cdb set cdb.i1=(SELECT i.id from ITEMS i where cdb.s1=i.dpname and i.hver="+hver+")";
//DebugTN("Executing",sql);
	fwConfigurationDB_executeSqlSimple(sql,g_fwConfigurationDB_DBConnection,exceptionInfo);
	if (dynlen(exceptionInfo)) return -1;
	
	// and drop all unknowns
	sql="DELETE from cdb_api_params where i1 is null";
//DebugTN("Executing",sql);
	fwConfigurationDB_executeSqlSimple(sql,g_fwConfigurationDB_DBConnection,exceptionInfo);
	if (dynlen(exceptionInfo)) return -1;

	
    }

    // now select the devices that are in the configuration.
    if (hierarchyType==fwDevice_HARDWARE) {
	
	sql = "update cdb_api_params cdb set i2=( "+
          "  SELECT ctn.citem_id from config_items_new ctn "+
          "  where ctn.tag_id=:CONFIG_ID and ctn.valid_to is null "+
          "  and cdb.i1=ctn.item_id)";
	params = makeDynInt(configId);
	_fwConfigurationDB_executeDBCmd(sql,g_fwConfigurationDB_DBConnection, params, exceptionInfo);
	if (dynlen(exceptionInfo)) return -1;
	sql = "DELETE FROM CDB_API_PARAMS WHERE I2 IS NULL";
	fwConfigurationDB_executeSqlSimple(sql,g_fwConfigurationDB_DBConnection, exceptionInfo);
	if (dynlen(exceptionInfo)) return -1;
	// Now re-query those that are left	
	dynClear(data);
	sql="SELECT S1,I1,I2 from CDB_API_PARAMS order by s1";
	//DebugTN("Exec",sql);
	_fwConfigurationDB_executeDBQuery(sql, g_fwConfigurationDB_DBConnection,data,exceptionInfo,3,TRUE);
	if (dynlen(exceptionInfo)) return -1;    

    } else if (hierarchyType==fwDevice_LOGICAL) {


	sql = "update cdb_api_params cdb set s2=(SELECT i.dpname from items i, REFERENCES RF WHERE rf.ref_id=i.id and RF.ID=CDB.i1 and rf.refver=:1 and rf.valid_To is null)"; 
	params = makeDynInt(configId);
	_fwConfigurationDB_executeDBCmd(sql,g_fwConfigurationDB_DBConnection, params, exceptionInfo);
	if (dynlen(exceptionInfo)) return -1;

	// remove those one that actually do not have mapping
	sql = "DELETE FROM CDB_API_PARAMS WHERE S2 IS NULL";
	fwConfigurationDB_executeSqlSimple(sql,g_fwConfigurationDB_DBConnection, exceptionInfo);
	if (dynlen(exceptionInfo)) return -1;

	// complete the information
	sql="UPDATE CDB_API_PARAMS CDB SET (cdb.s3, cdb.s4,cdb.s5) = (SELECT I.TYPE, i.DETAIL, I.NAME FROM ITEMS I where i.id=cdb.i1)";
	fwConfigurationDB_executeSqlSimple(sql,g_fwConfigurationDB_DBConnection, exceptionInfo);
	if (dynlen(exceptionInfo)) return -1;
	
	// Now re-query those that are left	
	dynClear(data);
	sql="SELECT S1 from CDB_API_PARAMS order by s1";
	_fwConfigurationDB_executeDBQuery(sql, g_fwConfigurationDB_DBConnection,data,exceptionInfo,1,TRUE);
	if (dynlen(exceptionInfo)) return -1;    

    }

//DebugTN("Exec",sql,params);
//DebugTN("Back from there...",data);

    // clean up whatever is left...
//    DebugTN("Exec",sql);


//DebugTN("Back; we will have #devices",dynlen(data[1]));    
    dyn_string newDeviceList;
    if (dynlen(data)) {
	newDeviceList=data[1];  
	dynSortAsc(deviceList);
    }

    if (dynlen(deviceList) && newDeviceList!=deviceList)  {
	deviceListModified=TRUE;
    }

    deviceList=newDeviceList;

    if (deviceListModified) {
	return 1;
    }

    return 0;

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

    dyn_dyn_mixed deviceListObject;
    
    if (dynlen(hwDevList)) {
	DebugN("saving minimal information about hardware devices");    
	_fwConfigurationDB_saveItemsToDB(hwDevList, fwDevice_HARDWARE,exceptionInfo);
	if (dynlen(exceptionInfo)) return -1;
    }

    if (dynlen(logDevList)) {
	DebugN("saving minimal information about logical devices");    
	_fwConfigurationDB_saveItemsToDB(logDevList, fwDevice_LOGICAL,exceptionInfo);
	if (dynlen(exceptionInfo)) return -1;
    }
   //DebugN("Devices saved OK.");

   // on return, we want to give back the modified deviceList...
   dyn_string retDeviceList=hwDevList;
   dynAppend(retDeviceList,logDevList);
   
   deviceList=retDeviceList;

   // "rethrow" all the info about missing devices
   exceptionInfo=mdExcInfo;
   if (dynlen(exceptionInfo)) return 1;

   fwDbCommitTransaction(g_fwConfigurationDB_DBConnection);

   return 0;
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
    dyn_string &exceptionInfo , bool errorOnNotFound=TRUE, dyn_string deviceSystems="")
{
    int systems;
    dyn_string allDps;
    dyn_string allAliases;
    
    systems = dynlen(deviceSystems);
//DebugN("RESOLVING:", deviceSystems);
    if(systems > 0)
    {
      dyn_string tempDps, tempAliases;
      for(int i=1; i<=systems; i++)
      {
        dpGetAllAliases (tempDps, tempAliases, "*", deviceSystems[i] + "*.");
        dynAppend(allDps, tempDps);
        dynAppend(allAliases, tempAliases);
      }
    }
    else
      dpGetAllAliases (allDps, allAliases, "*", "*.");

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

