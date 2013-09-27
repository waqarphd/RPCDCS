/**@file

This package contains device-configuration functions of the Configuration Database tool

@author Piotr Golonka (EN/ICE-SCD)
@date   April 2011
*/
global string _fwConfigurationDB_fileVersion_fwConfigurationDB_DeviceConfiguration_ctl="3.3.65";






void _fwConfigurationDB_saveDevicesInConfiguration(dyn_dyn_mixed &deviceListObject,
    string hierarchyType, int confId, dyn_int dpTypeIds, dyn_string &exceptionInfo, string date)
{

    if (fwConfigurationDB_progress(fwConfigurationDB_OPER_SaveDevicesAndElements,"Prepare to save devices",  1.0, exceptionInfo)) return;

    // invalidate previous configuration for these devices

    // we will also create a list of device ID's suitable to be included in the query
    string sqlDevList=_fwConfigurationDB_itemIdListForSQLQuery(deviceListObject[fwConfigurationDB_DLO_ITEMID]);

    // invalidation of previous configuration:
    string invalidateSql="UPDATE CONFIG_TAGS SET VALID_TO=TO_DATE(\'"+date+"\' , \'yyyy.mm.dd hh24:mi:ss.???\') "+
        " WHERE CITEM_ID IN ("+
        "	SELECT CITEM_ID FROM V_CONFIG_ITEMS WHERE "+sqlDevList+")"+
        " AND CONF_ID="+confId;

    fwConfigurationDB_executeSqlSimple(invalidateSql, g_fwConfigurationDB_DBConnection,exceptionInfo);
    if (dynlen(exceptionInfo)) {rdbRollbackTransaction(g_fwConfigurationDB_DBConnection);return;}


    int nDevices=dynlen(deviceListObject[fwConfigurationDB_DLO_DPNAME]);
    if (nDevices==0) return;
    // get a set of propIds

    dyn_int citemIds;
    _fwConfigurationDB_getBatchOfSequenceNumbers(g_fwConfigurationDB_DBConnection, "CITEM_ID_SEQ", nDevices,
                                                 citemIds, exceptionInfo);
    if (dynlen(exceptionInfo)) return;
    deviceListObject[fwConfigurationDB_DLO_CITEM_ID]=citemIds;

    anytype insertDevCmd,tagDevCmd,insertElementCmd;
    string insertDevSql="INSERT INTO CONFIG_ITEMS (CITEM_ID, DPT_ID, ITEM_ID ) "+
        " VALUES (:CITEM_ID, :DPT_ID, :ITEM_ID)";

    string tagDevSql="INSERT INTO CONFIG_TAGS(CONF_ID,CITEM_ID,VALID_FROM, VALID_TO) "+
        " VALUES ("+confId+", :CITEM_ID, :VALID_FROM, NULL)";


    _fwConfigurationDB_startCommand(insertDevSql, g_fwConfigurationDB_DBConnection,
                                    insertDevCmd, exceptionInfo);
    if (dynlen(exceptionInfo)) {rdbRollbackTransaction(g_fwConfigurationDB_DBConnection);return;}
    _fwConfigurationDB_startCommand(tagDevSql, g_fwConfigurationDB_DBConnection,
                                    tagDevCmd, exceptionInfo);
    if (dynlen(exceptionInfo)) {rdbRollbackTransaction(g_fwConfigurationDB_DBConnection);return;}

    for (int i=1;i<=nDevices;i++) {
	if (i%10==1)
	if (fwConfigurationDB_progress(fwConfigurationDB_OPER_SaveDevicesAndElements,"Save devices",  10.0+40*i/nDevices, exceptionInfo)) return;

        mapping params;
        params[":CITEM_ID"] =   deviceListObject[fwConfigurationDB_DLO_CITEM_ID][i];
        params[":ITEM_ID"]  =  deviceListObject[fwConfigurationDB_DLO_ITEMID][i];
        params[":DPT_ID"]   =   dpTypeIds[i];
        _fwConfigurationDB_bindExecuteCommand(insertDevCmd, params, exceptionInfo);
        if (dynlen(exceptionInfo)) {rdbRollbackTransaction(g_fwConfigurationDB_DBConnection);return;}

        mapping tagParams;
        tagParams[":CITEM_ID"] =   deviceListObject[fwConfigurationDB_DLO_CITEM_ID][i];
        tagParams[":VALID_FROM"] =   "TO_DATE(\'"+date+"\' , \'yyyy.mm.dd hh24:mi:ss.???\') ";

        _fwConfigurationDB_bindExecuteCommand(tagDevCmd, tagParams, exceptionInfo);
        if (dynlen(exceptionInfo)) {rdbRollbackTransaction(g_fwConfigurationDB_DBConnection);return;}

    }

    _fwConfigurationDB_finishCommand(insertDevCmd, exceptionInfo);
    if (dynlen(exceptionInfo)) {rdbRollbackTransaction(g_fwConfigurationDB_DBConnection);return;}
    _fwConfigurationDB_finishCommand(tagDevCmd, exceptionInfo);
    if (dynlen(exceptionInfo)) {rdbRollbackTransaction(g_fwConfigurationDB_DBConnection);return;}

}



void _fwConfigurationDB_saveDevicePropertiesToDB(dyn_dyn_mixed &deviceListObject,
                                                 string hierarchyType,
                                                 dyn_mixed &deviceElementIds,
                                                 string startDate,dyn_string &exceptionInfo,
                                                 bool storeValues=TRUE)
{
   if (fwConfigurationDB_progress(fwConfigurationDB_OPER_SaveDevicesAndElements,"Storing device elements",  50.0, exceptionInfo)) return;


/////////

    anytype insertElementCmd;
    string insertElementSql="INSERT INTO CONFIG_ITEM_PROPERTIES(IPROP_ID,CITEM_ID,DEVELEM_ID, VALUE) "+
        " VALUES (:IPROP_ID, :CITEM_ID, :DEVELEM_ID, :VALUE)";
    dyn_dyn_mixed data;
    int idx=0;
    
    // determine the number of properties, so we now how many IPROP_IDs to request
    int nProps=0;

    for (int i=1;i<=dynlen(deviceListObject[fwConfigurationDB_DLO_PROPNAMES]);i++) {
        dyn_string elementNames=deviceListObject[fwConfigurationDB_DLO_PROPNAMES][i];
        nProps=nProps+dynlen(elementNames);
    }

    dyn_int ipropIds;
    _fwConfigurationDB_getBatchOfSequenceNumbers(g_fwConfigurationDB_DBConnection, "IPROP_ID_SEQ", nProps,  ipropIds, exceptionInfo);
    if (dynlen(exceptionInfo)) return;

    // loop over all devices
    for (int i=1;i<=dynlen(deviceListObject[fwConfigurationDB_DLO_DPNAME]);i++) {

	if (fwConfigurationDB_progress(fwConfigurationDB_OPER_SaveDevicesAndElements,
	"Storing elements of "+deviceListObject[fwConfigurationDB_DLO_DPNAME][i],
	50.0+50.0*i/dynlen(deviceListObject[fwConfigurationDB_DLO_DPNAME]), exceptionInfo)) return;

        dyn_int    elementIds=deviceElementIds[i];
        dyn_string elementNames=deviceListObject[fwConfigurationDB_DLO_PROPNAMES][i];
        dyn_int devIpropIds;
	// loop over all elements in a device
        for (int j=1;j<=dynlen(elementIds);j++) {
            string dpe=deviceListObject[fwConfigurationDB_DLO_DPNAME][i]+elementNames[j];
	    //DebugN("Save prop:",dpe);
            dyn_mixed propParams;

            int ipropid=ipropIds[nProps];
            dynAppend(devIpropIds,ipropid);
            nProps--;
            propParams[1] =   ipropid;
            propParams[2] =   deviceListObject[fwConfigurationDB_DLO_CITEM_ID][i];


            propParams["3"] =   elementIds[j];

	    if (storeValues) {
        	anytype value;
        	string svalue="";
        	int dpet=dpElementType(dpe);
        	
        	//if ( (dpet!=DPEL_STRUCT)) {
    		// fix #70394: Error while restoring static configuration for CHAR_STRUCT typed elements	
        	dyn_string supportedConfigs=dpGetAllConfigs(dpe);   
        	if (dynContains(supportedConfigs,"_original")) {
            	    int dpgrc=dpGet(dpe,value);
            	    if (dpgrc!=0) {
            		dyn_errClass err=getLastError();
            		fwException_raise(exceptionInfo,"ERROR","Could not get value for "+dpe+" (see the log)","");
            		DebugTN("Error in _fwConfigurationDB_saveDevicePropertiesToDB","Could not get value for "+dpe,(string)err);
            		rdbRollbackTransaction(g_fwConfigurationDB_DBConnection);
            		return;
            	    } 
            	    _fwConfigurationDB_dataToString(value, dpet, "|",svalue,exceptionInfo);
            	    if (dynlen(exceptionInfo)) {rdbRollbackTransaction(g_fwConfigurationDB_DBConnection);return;}
        	}
        	// fix #17872 - not needed anymore as we use real binding below!
        	//strreplace(svalue,"\'","\'\'");

        	propParams[4] = svalue;
            } else {
        	anytype dummy;
        	propParams[4] = dummy;
            }

    	    idx++;
    	    data[idx]=propParams;    

        };
        deviceListObject[fwConfigurationDB_DLO_PROPIDS][i]=devIpropIds;
    }

    _fwConfigurationDB_executeDBBulkCmd(insertElementSql,g_fwConfigurationDB_DBConnection,data, exceptionInfo);
    if (dynlen(exceptionInfo)) {rdbRollbackTransaction(g_fwConfigurationDB_DBConnection);return;}


}


// this one is public - it commits the transaction at the end...


void fwConfigurationDB_getDeviceConfigurationFromDB(string configurationName,
    string hierarchyType, dyn_dyn_mixed &deviceListObject, dyn_string &exceptionInfo,
    time validOn=0, dyn_string deviceList="", string sysName="")
{
    time t0;
    _fwConfigurationDB_startFunction("getDeviceConfigurationFromDB", t0);

    _fwConfigurationDB_getDeviceConfigurationFromDB(configurationName,
	hierarchyType, deviceListObject, exceptionInfo,
	validOn, deviceList, sysName);

    // commit the transaction we started - clean up the temporary table
    rdbCommitTransaction(g_fwConfigurationDB_DBConnection);
    _fwConfigurationDB_endFunction("getDeviceConfigurationFromDB", t0);

}

// this one is private one - it does not commit the transaction
void _fwConfigurationDB_getDeviceConfigurationFromDB(string configurationName,
    string hierarchyType, dyn_dyn_mixed &deviceListObject, dyn_string &exceptionInfo,
    time validOn=0, dyn_string deviceList="", string sysName="")
{


    if (hierarchyType==fwDevice_HARDWARE) {
	//if (sysName=="") sysName=getSystemName();
    } else if (hierarchyType==fwDevice_LOGICAL) {
    } else {
	fwException_raise(exceptionInfo,"ERROR","Hierarchy type "+hierarchyType+" not supported","");
	return;
    }
    if (fwConfigurationDB_progress(fwConfigurationDB_OPER_LoadHierachyFromDB,"Loading device info from DB", 10.0, exceptionInfo)) return;

    dynClear (deviceListObject);
    _fwConfigurationDB_ensureDeviceListObjectValid(deviceListObject);

    string sql= "select item_id, citem_id, name, dpname, dptype, model, description, parent_id, dpid"+
        "	from v_config_items"+
        "	where tag=\'"+configurationName+"\' ";

    bool hasDeviceList=FALSE;
    if (dynlen(deviceList)) {
	if (deviceList[1]!="") { // skip if default "" parameter

	    string dpnamesForSql=_fwConfigurationDB_listToSQLString("DPNAME", deviceList);
	    sql=sql+"  and "+dpnamesForSql;
	    hasDeviceList=TRUE;
	}
    }

    if (!hasDeviceList){
	// restrict to the local system using hierarchical query...
	 sql=sql+ "  and item_id in ( "+
				 "     select item_id from v_items where hver="+g_fwConfigurationDB_DBHierarchyIDs[hierarchyType];
	 if (sysName=="") {
	    //// we may simply skip start_with - we want ALL!
	    //sql = sql+ 		" start with dpname is null ";
	 } else{
	    sql = sql+          " start with dpname=\'"+sysName+"\'";
	}
	sql=sql+"     connect by prior item_id=parent_id)";
    }
    sql=sql+ "	order by citem_id";
    dyn_dyn_mixed aRecords;

    _fwConfigurationDB_executeDBQuery(sql,g_fwConfigurationDB_DBConnection, aRecords, exceptionInfo,10,TRUE);
    if (dynlen(exceptionInfo)) return;
    if (fwConfigurationDB_progress(fwConfigurationDB_OPER_LoadHierachyFromDB,"Processing the data", 70.0, exceptionInfo)) return;

    if (dynlen(aRecords)<1) return;

    deviceListObject[fwConfigurationDB_DLO_ITEMID]=(dyn_int)aRecords[1];
    deviceListObject[fwConfigurationDB_DLO_CITEM_ID]=(dyn_int)aRecords[2];
    deviceListObject[fwConfigurationDB_DLO_NAME]=aRecords[3];
    deviceListObject[fwConfigurationDB_DLO_DPNAME]=aRecords[4];
    deviceListObject[fwConfigurationDB_DLO_DPTYPE]=aRecords[5];
//    deviceListObject[fwConfigurationDB_DLO_TYPE]  =aRecords[6];
    deviceListObject[fwConfigurationDB_DLO_MODEL]=aRecords[6];
    deviceListObject[fwConfigurationDB_DLO_COMMENT]=aRecords[7];
    deviceListObject[fwConfigurationDB_DLO_PARENTID]=(dyn_int)aRecords[8];
    deviceListObject[fwConfigurationDB_DLO_DPID]=(dyn_int)aRecords[9];

    // fill with dummy...
    deviceListObject[fwConfigurationDB_DLO_PROPNAMES][dynlen(aRecords[1])]=makeDynString();
    deviceListObject[fwConfigurationDB_DLO_PROPIDS][dynlen(aRecords[1])]=makeDynInt();

    // status information should be obtained below,
//    deviceListObject[fwConfigurationDB_DLO_REFDP]=dummy;
//    deviceListObject[fwConfigurationDB_DLO_REFID]=dummy;
//    deviceListObject[fwConfigurationDB_DLO_REF_STATUS]=dummy;





    // now extract the element ids, etc

    string citem_ids_as_sql=_fwConfigurationDB_listToSQLString("citem_id", deviceListObject[fwConfigurationDB_DLO_CITEM_ID]);


    // NOTE! We use a temporary table tmp_item_props to store the list of selected ipropid's.
    // it is truncated automatically on commit, hence we need a transaction here.

    // note! We do not check for errors here! (problems on windows)
    rdbCommitTransaction(g_fwConfigurationDB_DBConnection);
    rdbBeginTransaction(g_fwConfigurationDB_DBConnection);
    //int rc=dbCommitTransaction(g_fwConfigurationDB_DBConnection);
    //if (!rc) rc=dbBeginTransaction(g_fwConfigurationDB_DBConnection);
    //if (rc) {
	//bool invalidConnection;
	//_fwConfigurationDB_catchDbError(g_fwConfigurationDB_DBConnection, invalidConnection, exceptionInfo);
	//fwException_raise(exceptionInfo,"ERROR","Cannot start new transaction","");
	//return;
    //};

    string sqlForTempTable="insert into tmp_item_props(iprop_id,dpename) "+
			    "  select iprop_id,dpe_name from v_item_properties where "+citem_ids_as_sql;
    fwConfigurationDB_executeSqlSimple(sqlForTempTable, g_fwConfigurationDB_DBConnection, exceptionInfo);
    if (dynlen(exceptionInfo)) {rdbRollbackTransaction(g_fwConfigurationDB_DBConnection);return;}


    //string sql2= " select citem_id, iprop_id, prop_name, value from v_item_properties "+
    //    " where "+citem_ids_as_sql+
    //    " order by citem_id";
    string sql2= " select citem_id, iprop_id, prop_name, value from v_item_properties "+
        " where iprop_id in ( select iprop_id from tmp_item_props )"+
        " order by citem_id";
    dyn_dyn_mixed aRecords2;
    _fwConfigurationDB_executeDBQuery(sql2,g_fwConfigurationDB_DBConnection, aRecords2, exceptionInfo,4,TRUE);
    if (dynlen(exceptionInfo)) {rdbRollbackTransaction(g_fwConfigurationDB_DBConnection);return;}

    if (dynlen(aRecords2)>0) {

        int prev_cid=-1;
        int cid_idx=-1;
        dyn_string elementNames;
        dyn_int elementIds;
        for (int i=1;i<=dynlen(aRecords2[1]);i++) {
            int cid=aRecords2[1][i];
            if (cid!=prev_cid) {
                dynClear(elementNames);
                dynClear(elementIds);
                cid_idx=dynContains(deviceListObject[fwConfigurationDB_DLO_CITEM_ID],cid);
                prev_cid=cid;
            }
            dynAppend(elementNames,aRecords2[3][i]);
            dynAppend(elementIds,aRecords2[2][i]);
            deviceListObject[fwConfigurationDB_DLO_PROPNAMES][cid_idx]=elementNames;
            deviceListObject[fwConfigurationDB_DLO_PROPIDS][cid_idx]=elementIds;
        }
    }


    if (hierarchyType==fwDevice_LOGICAL) {
        _fwConfigurationDB_getReferencesFromDB(	deviceListObject,configurationName,exceptionInfo);
	if (dynlen(exceptionInfo)) {rdbRollbackTransaction(g_fwConfigurationDB_DBConnection);return;}
    }

    if (fwConfigurationDB_progress(fwConfigurationDB_OPER_LoadHierachyFromDB,"Loading hierarchy info from DB", 100.0, exceptionInfo)) return;


    // note! This one is "private" one, it does not do the cleanup of temporary table
    // by commiting the connection!!!
}


void _fwConfigurationDB_loadValuesConfiguration(dyn_int propIds, dyn_string &dpes, dyn_int &dpetypes,
                                                dyn_string &values, dyn_string &exceptionInfo)
{
//    string propidsListAsSql=_fwConfigurationDB_listToSQLString("IPROP_ID", propIds);

//    string sql="SELECT dpe_name, value, dpe_type from v_item_properties" +
//        " where "+propidsListAsSql+
//        " and dpe_type!=1";
    string sql="SELECT dpe_name, value, dpe_type from v_item_properties" +
        " where iprop_id in ( select iprop_id from tmp_item_props )"+
        " and dpe_type!=1";


    dyn_dyn_mixed aRecords;
    _fwConfigurationDB_executeDBQuery(sql,g_fwConfigurationDB_DBConnection, aRecords, exceptionInfo,3,TRUE);
    if (dynlen(exceptionInfo)) return;

    if (dynlen(aRecords)>=3) {
	dpes=aRecords[1];
	values=aRecords[2];
	dpetypes=aRecords[3];
    }

}


















/////////////////////////////





/** Extracts addressing configuration from PVSS
 *
 * @param dpes      list of the data point element names for which configuration is requested
 * @param ipropIds  corresponding list of IPROP_ID identifiers (in the database) of the data-point elements
 * @param addressingData on return contains the configuration data (internal format described below)
 * @param exceptionInfo standard exception handling variable
 *
 * the addressingData variable has the following format:
 * @li addressingData[i] - represent complete address settings for a single dpe:
 * @li addressingData[i][1] is string-typed dpe name (i.e. dp + element name)
 * @li addressingData[i][2] contains associated IPROP_ID (int)
 * @li addressingData[i][3] is addressConfig object (dyn_anytype)
*/
void _fwConfigurationDB_extractAddressingConfiguration(dyn_string dpes, dyn_string ipropIds,
    dyn_dyn_mixed &addressingData, dyn_string &exceptionInfo)
{
    time t0;
    _fwConfigurationDB_startFunction("extractAddressingConfiguration", t0);
    dynClear(addressingData);
    for (int i=1;i<=dynlen(dpes);i++) {
        string dpe=dpes[i];
        bool configExists, isActive;
        dyn_anytype addressConfigObject;
        fwPeriphAddress_get(dpe, configExists, addressConfigObject, isActive, exceptionInfo);
        if (dynlen(exceptionInfo)) return;
        if (configExists) {
            int idx=dynlen(addressingData)+1;
            addressingData[idx][1]=dpe;
            addressingData[idx][2]=ipropIds[i];
            addressingData[idx][3]=addressConfigObject;
        }
    }
    _fwConfigurationDB_endFunction("extractAddressingConfiguration", t0);
}



/** Saves addressing configuration to Configuration Database
 *
 * @param addressingData should contain the configuration data to be stored (internal format)
 * @param exceptionInfo standard exception handling variable
 */
void _fwConfigurationDB_saveAddressingConfiguration(dyn_dyn_mixed addressingData, dyn_string &exceptionInfo)
{
    time t0;
    _fwConfigurationDB_startFunction("saveAddressingConfiguration", t0);

    anytype cmd;
    string sql="INSERT INTO CONFIG_ADDRESSES (IPROP_ID, TYPE, DRIVER, DIRECTION, DATATYPE, ACTIVE, OPTIONS ) "+
        " VALUES (:IPROP_ID, :TYPE, :DRIVER, :DIRECTION, :DATATYPE, :ACTIVE, :OPTIONS)";

    _fwConfigurationDB_startCommand(sql, g_fwConfigurationDB_DBConnection,
                                    cmd, exceptionInfo);
    if (dynlen(exceptionInfo)) {rdbRollbackTransaction(g_fwConfigurationDB_DBConnection);return;}

    for (int i=1;i<=dynlen(addressingData);i++) {
        mapping params;
        dyn_anytype addressObject=addressingData[i][3];
        params[":IPROP_ID"]=addressingData[i][2];
        params[":TYPE"]="\'"+addressObject[fwPeriphAddress_TYPE]+"\'";
        params[":DRIVER"]=(int)addressObject[fwPeriphAddress_DRIVER_NUMBER];
        params[":DIRECTION"]=(int)addressObject[fwPeriphAddress_DIRECTION];
        params[":DATATYPE"]=(int)addressObject[fwPeriphAddress_DATATYPE];
        params[":ACTIVE"]=(int)addressObject[fwPeriphAddress_ACTIVE];

        string options=addressObject[fwPeriphAddress_REFERENCE]; // this is stored at the beginning of options!
        for (int j=FW_PARAMETER_FIELD_LOWLEVEL;j<=dynlen(addressObject);j++) {
            options=options+"|"+(string)addressObject[j]; // fix #19075 we need to cast here explicitely to string-otherwise it breaks!
        }
        params[":OPTIONS"]="\'"+options+"\'";
        _fwConfigurationDB_bindExecuteCommand(cmd, params, exceptionInfo);
        if (dynlen(exceptionInfo)) {rdbRollbackTransaction(g_fwConfigurationDB_DBConnection);return;}
    }

    _fwConfigurationDB_finishCommand(cmd, exceptionInfo);
    if (dynlen(exceptionInfo)) {rdbRollbackTransaction(g_fwConfigurationDB_DBConnection);return;}
    _fwConfigurationDB_endFunction("saveAddressingConfiguration", t0);
}


/** Loads addressing configuration from Configuration Database
 *
 * @param dpes      list of the data point element names for which configuration is loaded
 * @param ipropIds  corresponding list of IPROP_ID identifiers (in the database) of the data-point elements
 * @param addressingData on return contains the configuration data loaded from database (internal format)
 * @param exceptionInfo standard exception handling variable
 */
void _fwConfigurationDB_loadAddressingConfiguration(dyn_int propIds, dyn_string dpes,
    dyn_dyn_mixed &addressingData, dyn_string &exceptionInfo)
{
    time t0;
    _fwConfigurationDB_startFunction("loadAddressingConfiguration", t0);

    dynClear(addressingData);
//    string propidsListAsSql=_fwConfigurationDB_listToSQLString("IPROP_ID", propIds);

    //string sql="SELECT IPROP_ID, TYPE, DRIVER, DIRECTION,DATATYPE, ACTIVE, OPTIONS FROM CONFIG_ADDRESSES "+
    //    " WHERE "+propidsListAsSql;
    string sql="SELECT IPROP_ID, TYPE, DRIVER, DIRECTION,DATATYPE, ACTIVE, OPTIONS FROM CONFIG_ADDRESSES "+
        " where iprop_id in ( select iprop_id from tmp_item_props )";

    dyn_dyn_mixed aRecords;

    _fwConfigurationDB_executeDBQuery(sql,g_fwConfigurationDB_DBConnection, aRecords, exceptionInfo,7,TRUE);
    if (dynlen(exceptionInfo)) return;

    int max=0;
    if (dynlen(aRecords)) max=dynlen(aRecords[1]);

    for (int i=1;i<=max;i++) {
        dyn_anytype addressObject;
        string adrOpt=aRecords[7][i];
        dyn_mixed options=strsplit(adrOpt,"|");
        // fix #58663: cannot restore S7 addresses with empty poll group
        // check if we have "|" as the last character, and if so, fix what strsplit is not doing for us...
        if (adrOpt!="" && substr(adrOpt,strlen(adrOpt)-1)=="|") dynAppend(options,"");
        
        string reference=options[1];
        dynRemove(options,1);
        int propid=aRecords[1][i];
        addressObject[fwPeriphAddress_TYPE]=aRecords[2][i];
        addressObject[fwPeriphAddress_DRIVER_NUMBER]=aRecords[3][i];
        addressObject[fwPeriphAddress_DIRECTION]=aRecords[4][i];
        addressObject[fwPeriphAddress_DATATYPE]=aRecords[5][i];
        addressObject[fwPeriphAddress_ACTIVE]=aRecords[6][i];
        addressObject[fwPeriphAddress_REFERENCE]=reference;
        
        // temporary fix for #49981: poll groups for the S7 driver need to have a leading underscore,
        // and they are extracted (and saved to DB) without one...
        if (addressObject[fwPeriphAddress_TYPE]=="S7") {
    	    string pollGroup=options[dynlen(options)];
    	    if (pollGroup!="" && substr(pollGroup,0,1)!="_") {
    		pollGroup="_"+pollGroup;
    		options[dynlen(options)]=pollGroup;
    	    }
        }                                                                                    
        
        for (int j=1;j<=dynlen(options);j++)
            addressObject[FW_PARAMETER_FIELD_LOWLEVEL-1+j]=options[j];
        int idx=dynlen(addressingData)+1;
        int dpeidx=dynContains(propIds,propid);
        addressingData[idx][1]=dpes[dpeidx];
        addressingData[idx][2]=aRecords[1][i];
        addressingData[idx][3]=addressObject;
    }
    _fwConfigurationDB_endFunction("loadAddressingConfiguration", t0);
}










/** Extracts alert configuration from PVSS
 *
 * @param dpes      list of the data point element names for which configuration is requested
 * @param ipropIds  corresponding list of IPROP_ID identifiers (in the database) of the data-point elements
 * @param alertData on return contains the configuration data (internal format)
 * @param exceptionInfo standard exception handling variable
 */
void _fwConfigurationDB_extractAlertConfiguration(dyn_string dpes,dyn_int ipropIds,
    dyn_string allDpes, dyn_int allIpropIds,
    dyn_dyn_mixed &alertData, dyn_string &exceptionInfo)
{
    time t0;
    _fwConfigurationDB_startFunction("extractAlertConfiguration", t0);
    dynClear(alertData);
    alertData[13][1]="";// make the object valid: create at least 11 columns

    // fix #48430
    // Don't try to extract the addresses for DPE's of types that are not allowed
    dyn_string newDpes,newAllDpes;
    dyn_int newAllIpropIds,newIpropIds;
    for (int i=1;i<=dynlen(dpes);i++) {
	int dpeType=dpElementType(dpes[i]);
	if ( (dpeType != DPEL_DPID) &&
	     (dpeType != DPEL_DYN_DPID) &&
	     (dpeType != DPEL_DPID_STRUCT) &&
	     (dpeType != DPEL_DYN_DPID_STRUCT) ) {
	        dynAppend(newDpes,dpes[i]);
        	dynAppend(newIpropIds,ipropIds[i]);
	        dynAppend(newAllDpes,allDpes[i]);
	        dynAppend(newAllIpropIds,allIpropIds[i]);
	}
    }
    // note! we do not return the modified values to the caller!
    // we substitute the variables to simplify code below
    dpes=newDpes;
    allDpes=newAllDpes;
    allIpropIds=newAllIpropIds;
    ipropIds=newIpropIds;
    
    dyn_bool configExists,isActive;
    dyn_int alertConfigType;
    dyn_dyn_string alertTexts,alertClasses,summaryDpeList,alertPanelParameters;
    dyn_dyn_float alertLimits;
    dyn_string alertPanel,alertHelp;
    fwAlertConfig_getMany( dpes,
                           configExists,
                           alertConfigType,
                           alertTexts,
                           alertLimits,
                           alertClasses,
                           summaryDpeList,
                           alertPanel,
                           alertPanelParameters,
                           alertHelp,
                           isActive,
                           exceptionInfo);

    if (dynlen(exceptionInfo)) return;

    for (int i=1;i<=dynlen(dpes);i++) {
        if (configExists[i]) {
            int idx=dynlen(alertData[1])+1;
            alertData[1][idx]=dpes[i];
            alertData[2][idx]=ipropIds[i];
            alertData[3][idx]=alertConfigType[i];
            alertData[4][idx]=alertTexts[i]; // dyn_string!
            alertData[5][idx]=alertLimits[i]; // dyn_float!
            alertData[6][idx]=alertClasses[i]; // dyn_string!


            alertData[8][idx]=alertPanel[i];
            alertData[9][idx]=alertPanelParameters[i];//dyn_string!
            alertData[10][idx]=alertHelp[i];
            alertData[11][idx]=isActive[i];

            // decode ipropIds of the alerts included in summary
            // leave only the ones present in the configuration...
            //
            // note that we should get the list of all DPEs in configuration
            // from DB, rather than from ipropIds, which only
            // contains the elements currently being stored...
            dyn_string sumDpes=summaryDpeList[i];
            if (dynlen(sumDpes)==1) {
        	// this may be the case of dpelist specified by pattern...
        	if (strpos(sumDpes[1],"*")>=0 || strpos(sumDpes[1],"?")>=0) {
        	    alertData[12][idx]=makeDynInt(-1);
        	    alertData[7][idx]=sumDpes[1];
        	    continue;
        	}
            }
            dyn_int    includedSumIds;
            dyn_string includedSumDpes;
            for (int j=1;j<=dynlen(sumDpes);j++) {
                int sumIdx=dynContains(allDpes,sumDpes[j]);
                if (sumIdx>0) {
                    int alarmIpropId=allIpropIds[sumIdx];
                    //DebugN("element of summary alert for "+dpes[i]+" found!",sumDpes[j],alarmIpropId);
                    dynAppend(includedSumIds,alarmIpropId);
                    dynAppend(includedSumDpes,sumDpes[j]);
                } else {
                    //DebugN("element of summary alert for "+dpes[i]+" not present:",sumDpes[j]);
                }
            }
            alertData[7][idx]=includedSumDpes; // dyn_string!
            alertData[12][idx]=includedSumIds; // dyn_int!

        }
    }

    _fwConfigurationDB_endFunction("extractAlertConfiguration", t0);
}

/** Saves alert configuration to Configuration Database
 *
 * @param alarmData should contain the configuration data to be stored (internal format)
 * @param exceptionInfo standard exception handling variable
 */
void _fwConfigurationDB_saveAlertConfiguration(dyn_dyn_mixed &alertData, dyn_string &exceptionInfo)
{
    time t0;
    _fwConfigurationDB_startFunction("saveAlertConfiguration", t0);

    if (dynlen(alertData[1])>0) {
        anytype cmdAlert, cmdAlertDpe, cmdAlertSum, cmdAlertMisc;
        string sqlAlert="INSERT INTO CONFIG_ALERTS (IPROP_ID, TYPE, ACTIVE) "+
            " VALUES (:IPROP_ID, :TYPE, :ACTIVE)";
        string sqlAlertDpe="INSERT INTO CONFIG_DPEALERTS (IPROP_ID, TEXTS, LIMITS, CLASSES) "+
            " VALUES (:IPROP_ID, :TEXTS, :LIMITS, :CLASSES)";
        string sqlAlertSum="INSERT INTO CONFIG_SUMALERTS (IPROP_ID, TEXTS, CLASS, SUMDPELIST) "+
            " VALUES (:IPROP_ID, :TEXTS, :CLASS, :SUMDPELIST)";
        string sqlAlertMisc="INSERT INTO CONFIG_ALERTS_MISC (IPROP_ID,PANEL, PANELPARAMS, HELP ) "+
            " VALUES (:IPROP_ID, :PANEL, :PPARAMS, :HELP)";

        _fwConfigurationDB_startCommand(sqlAlert, g_fwConfigurationDB_DBConnection,
                                    cmdAlert, exceptionInfo);
        _fwConfigurationDB_startCommand(sqlAlertDpe, g_fwConfigurationDB_DBConnection,
                                        cmdAlertDpe, exceptionInfo);
        _fwConfigurationDB_startCommand(sqlAlertSum, g_fwConfigurationDB_DBConnection,
                                        cmdAlertSum, exceptionInfo);
        _fwConfigurationDB_startCommand(sqlAlertMisc, g_fwConfigurationDB_DBConnection,
                                        cmdAlertMisc, exceptionInfo);

        if (dynlen(exceptionInfo)) {rdbRollbackTransaction(g_fwConfigurationDB_DBConnection);return;}
        for (int i=1;i<=dynlen(alertData[1]);i++) {



            mapping paramsAlert, paramsAlertDpe,paramsAlertSum, paramsAlertMisc;
            int iprop_id=alertData[2][i];
            int alertType=alertData[3][i];

            // store generic information...
            paramsAlert[":IPROP_ID"]=iprop_id;
            paramsAlert[":TYPE"]=alertType;
            paramsAlert[":ACTIVE"]=(int)alertData[11][i];
            _fwConfigurationDB_bindExecuteCommand(cmdAlert, paramsAlert, exceptionInfo);
            if (dynlen(exceptionInfo)) {rdbRollbackTransaction(g_fwConfigurationDB_DBConnection);return;}


            if (alertType==DPCONFIG_SUM_ALERT){
                // store alert summary information...
                string sval;
                paramsAlertSum[":IPROP_ID"]=iprop_id;
                dyn_string ds=alertData[4][i];
                _fwConfigurationDB_dataToString(ds , DPEL_DYN_STRING,"|", sval,exceptionInfo);

        	// fix #17872
        	strreplace(sval,"\'","\'\'");
		string escClass=alertData[6][i];
        	strreplace(escClass,"\'","\'\'");


                paramsAlertSum[":TEXTS"]="\'"+sval+"\'";
                paramsAlertSum[":CLASS"]="\'"+escClass+"\'";


                //ds=alertData[7][i];
                //_fwConfigurationDB_dataToString(ds , DPEL_DYN_STRING,"|",sval,exceptionInfo);

                dyn_int di=alertData[12][i];

		// the DPE list may be specified using DP PATTERN
		if (dynlen(di)==1 && di[1]==-1) {
		    // then we will take it as it is, prepending with keyword "PATTERN:"
		    sval="PATTERN:"+alertData[7][i];
		} else {
		    // otherwise we use the list of dp-alert IDs,
            	    _fwConfigurationDB_dataToString(di , DPEL_DYN_INT,"|",sval,exceptionInfo);
            	}
                paramsAlertSum[":SUMDPELIST"]="\'"+sval+"\'";
                if (dynlen(exceptionInfo)) return;
                _fwConfigurationDB_bindExecuteCommand(cmdAlertSum, paramsAlertSum, exceptionInfo);
                if (dynlen(exceptionInfo)) {rdbRollbackTransaction(g_fwConfigurationDB_DBConnection);return;}

            } else {
                // store dpe-alert information...

                string sval;
                paramsAlertDpe[":IPROP_ID"]=iprop_id;
                dyn_string ds=alertData[4][i];
                _fwConfigurationDB_dataToString(ds , DPEL_DYN_STRING,"|", sval,exceptionInfo);
        	// fix #17872
        	strreplace(sval,"\'","\'\'");

                paramsAlertDpe[":TEXTS"]="\'"+sval+"\'";
                dyn_float df=alertData[5][i];
                _fwConfigurationDB_dataToString(df , DPEL_DYN_FLOAT,"|", sval,exceptionInfo);
                paramsAlertDpe[":LIMITS"]="\'"+sval+"\'";
                ds=alertData[6][i];
                _fwConfigurationDB_dataToString(ds , DPEL_DYN_STRING,"|", sval,exceptionInfo);
        	// fix #17872
        	strreplace(sval,"\'","\'\'");

                paramsAlertDpe[":CLASSES"]="\'"+sval+"\'";
                if (dynlen(exceptionInfo)) return;
                _fwConfigurationDB_bindExecuteCommand(cmdAlertDpe, paramsAlertDpe, exceptionInfo);
                if (dynlen(exceptionInfo)) {rdbRollbackTransaction(g_fwConfigurationDB_DBConnection);return;}
            }

            string alertPanel=alertData[8][i];
            if (alertPanel!="") {
                string sval;
                paramsAlertMisc[":IPROP_ID"]=iprop_id;
                paramsAlertMisc[":PANEL"]="\'"+alertPanel+"\'";
                dyn_string ds=alertData[9][i];
                _fwConfigurationDB_dataToString(ds , DPEL_DYN_STRING,"|",sval,exceptionInfo);
        	// fix #17872
        	strreplace(sval,"\'","\'\'");

                paramsAlertMisc[":PPARAMS"]="\'"+sval+"\'";
                paramsAlertMisc[":HELP"]   ="\'"+alertData[10][i]+"\'";
                if (dynlen(exceptionInfo)) return;
                _fwConfigurationDB_bindExecuteCommand(cmdAlertMisc, paramsAlertMisc, exceptionInfo);
                if (dynlen(exceptionInfo)) {rdbRollbackTransaction(g_fwConfigurationDB_DBConnection);return;}
            }
        }

    _fwConfigurationDB_finishCommand(cmdAlert, exceptionInfo);
    _fwConfigurationDB_finishCommand(cmdAlertDpe, exceptionInfo);
    _fwConfigurationDB_finishCommand(cmdAlertSum, exceptionInfo);
    _fwConfigurationDB_finishCommand(cmdAlertMisc, exceptionInfo);
    if (dynlen(exceptionInfo)) {rdbRollbackTransaction(g_fwConfigurationDB_DBConnection);return;}
    }

_fwConfigurationDB_endFunction("saveAlertConfiguration", t0);
}


/** Loads alert configuration from Configuration Database
 *
 * @param dpes      list of the data point element names for which configuration is loaded
 * @param ipropIds  corresponding list of IPROP_ID identifiers (in the database) of the data-point elements
 * @param alertData on return contains the configuration data loaded from database (internal format)
 * @param exceptionInfo standard exception handling variable
 */
void _fwConfigurationDB_loadAlertConfiguration(dyn_int propIds, dyn_string dpes,
                                               dyn_dyn_mixed &alertData,
                                               dyn_dyn_mixed &sumAlertData,
                                               dyn_dyn_mixed &sumAlertByPatternData,
                                               dyn_string &exceptionInfo)
{
    time t0;
    _fwConfigurationDB_startFunction("loadAlertConfiguration", t0);
    dynClear(alertData);
    dynClear(sumAlertData);
    dynClear(sumAlertByPatternData);
    alertData[13][1]="";// make the object valid: create at least 11 columns
    sumAlertData[13][1]="";
    sumAlertByPatternData[13][1]="";

//    string propidsListAsSql=_fwConfigurationDB_listToSQLString("IPROP_ID", propIds);

    //string sql="SELECT IPROP_ID, TYPE, ACTIVE, TEXTS, LIMITS, CLASSES, "+
    //    " SUMDPELIST,PANEL,PANELPARAMS,HELP FROM V_CONFIG_ALERTS "+
    //    " WHERE "+propidsListAsSql;
    string sql="SELECT IPROP_ID, TYPE, ACTIVE, TEXTS, LIMITS, CLASSES, "+
        " SUMDPELIST,PANEL,PANELPARAMS,HELP FROM V_CONFIG_ALERTS "+
        " where iprop_id in ( select iprop_id from tmp_item_props )";

    dyn_dyn_mixed aRecords;

    _fwConfigurationDB_executeDBQuery(sql,g_fwConfigurationDB_DBConnection, aRecords, exceptionInfo,10,TRUE);
    if (dynlen(exceptionInfo)) return;
    if (dynlen(aRecords)<1) { _fwConfigurationDB_endFunction("loadAlertConfiguration", t0); return;}

    for (int i=1;i<=dynlen(aRecords[1]);i++) {
	int alertType=aRecords[2][i];
        int idx=0;
        int propidx=dynContains(propIds,aRecords[1][i]);
        switch (alertType) {

        case DPCONFIG_SUM_ALERT:
    	    if (strpos((string)aRecords[7][i],"PATTERN:")==0) {
    		//DP list specified by pattern
                idx=dynlen(sumAlertByPatternData[1])+1;
                sumAlertByPatternData[1][idx]=dpes[propidx]; //dpe
                sumAlertByPatternData[2][idx]=aRecords[1][i]; //iprop_id
                sumAlertByPatternData[3][idx]=aRecords[2][i]; // type
                sumAlertByPatternData[8][idx]=aRecords[8][i]; // alertPanel
                sumAlertByPatternData[10][idx]=aRecords[10][i]; // alertHelp
                sumAlertByPatternData[11][idx]=aRecords[3][i]; // active

		// explicit cast to string needed by substr: thank you Robert Stringer!
                sumAlertByPatternData[7][idx]=makeDynString(substr((string)aRecords[7][i],8)); // dp pattern
                sumAlertByPatternData[12][idx]=makeDynInt(-1); // dp pattern

            // alert texts:
                _fwConfigurationDB_stringToData(aRecords [4][i], DPEL_DYN_STRING, "|",
                                                sumAlertByPatternData[4][idx], exceptionInfo);
            // alert limits:
                _fwConfigurationDB_stringToData(aRecords [5][i], DPEL_DYN_FLOAT, "|",
                                                sumAlertByPatternData[5][idx], exceptionInfo);
            // alert classes:
                _fwConfigurationDB_stringToData(aRecords [6][i], DPEL_DYN_STRING, "|",
                                                sumAlertByPatternData[6][idx], exceptionInfo);
                // panel params
                _fwConfigurationDB_stringToData(aRecords [9][i], DPEL_DYN_STRING, "|",
                                                sumAlertByPatternData[9][idx], exceptionInfo);


	       } else {
		// DP list specified explicitely
                idx=dynlen(sumAlertData[1])+1;
                sumAlertData[1][idx]=dpes[propidx]; //dpe
                sumAlertData[2][idx]=aRecords[1][i]; //iprop_id
                sumAlertData[3][idx]=aRecords[2][i]; // type
                sumAlertData[8][idx]=aRecords[8][i]; // alertPanel
                sumAlertData[10][idx]=aRecords[10][i]; // alertHelp
                sumAlertData[11][idx]=aRecords[3][i]; // active
                            // alert texts:
                _fwConfigurationDB_stringToData(aRecords [4][i], DPEL_DYN_STRING, "|",
                                                sumAlertData[4][idx], exceptionInfo);
            // alert limits:
                _fwConfigurationDB_stringToData(aRecords [5][i], DPEL_DYN_FLOAT, "|",
                                                sumAlertData[5][idx], exceptionInfo);
            // alert classes:
                _fwConfigurationDB_stringToData(aRecords [6][i], DPEL_DYN_STRING, "|",
                                                sumAlertData[6][idx], exceptionInfo);
                // panel params
                _fwConfigurationDB_stringToData(aRecords [9][i], DPEL_DYN_STRING, "|",
                                                sumAlertData[9][idx], exceptionInfo);


        	// we have it as a list of ID's
            	dyn_int alertDpeIds;
            	dyn_string alertDpeNames;
            	_fwConfigurationDB_stringToData(aRecords [7][i], DPEL_DYN_INT, "|",
                                                alertDpeIds, exceptionInfo);
        	// now convert ids to dps for dpelist...
            	sumAlertData[12][idx]=alertDpeIds;
            	for (int j=1;j<=dynlen(alertDpeIds);j++) {
            	    int alertIdx=dynContains(propIds,alertDpeIds[j]);
            	    if (alertIdx<1) {
                        fwException_raise(exceptionInfo,"ERROR","Inconsistency in summary alert data","");
                        DebugN("Inconsistency in alert data! Cannot resolve ipropid="+alertDpeIds+" for summary alert of "+sumAlertData[1][idx]);
                        DebugN("IpropId of dp with sumalert:",aRecords[1][i]);
                        return;
            	    }
            	    dynAppend(alertDpeNames,dpes[alertIdx]);
            	}
            	sumAlertData[7][idx]=alertDpeNames;
	       }

	    break;

        default:

                idx=dynlen(alertData[1])+1;
                alertData[1][idx]=dpes[propidx]; //dpe
                alertData[2][idx]=aRecords[1][i]; //iprop_id
                alertData[3][idx]=aRecords[2][i]; // type
                alertData[8][idx]=aRecords[8][i]; // alertPanel
                alertData[10][idx]=aRecords[10][i]; // alertHelp
                alertData[11][idx]=aRecords[3][i]; // active
                        // alert texts:
                _fwConfigurationDB_stringToData(aRecords [4][i], DPEL_DYN_STRING, "|",
                                                alertData[4][idx], exceptionInfo);
            // alert limits:
                _fwConfigurationDB_stringToData(aRecords [5][i], DPEL_DYN_FLOAT, "|",
                                                alertData[5][idx], exceptionInfo);
            // alert classes:
                _fwConfigurationDB_stringToData(aRecords [6][i], DPEL_DYN_STRING, "|",
                                                alertData[6][idx], exceptionInfo);
                // panel params
                _fwConfigurationDB_stringToData(aRecords [9][i], DPEL_DYN_STRING, "|",
                                                alertData[9][idx], exceptionInfo);



            break;

        }// end of switch()

    }// end of for loop

    _fwConfigurationDB_endFunction("loadAlertConfiguration", t0);
}


////////////

/** Extracts archiving configuration from PVSS
 *
 * @param dpes      list of the data point element names for which configuration is requested
 * @param ipropIds  corresponding list of IPROP_ID identifiers (in the database) of the data-point elements
 * @param archivingData on return contains the configuration data (internal format)
 * @param exceptionInfo standard exception handling variable
 */
void _fwConfigurationDB_extractArchivingConfiguration(dyn_string dpes,dyn_int ipropIds,
    dyn_dyn_mixed &archivingData, dyn_string &exceptionInfo)
{
    time t0;
    _fwConfigurationDB_startFunction("extractArchivingConfiguration", t0);
    dynClear(archivingData);
    archivingData[9][1]="";// make the object valid: (number of columns)

    dyn_bool configExists,isActive;
    dyn_string archiveClass;
    dyn_int archiveType, smoothProcedure;
    dyn_float deadband,timeInterval;


    fwArchive_getMany(dpes, configExists, archiveClass, archiveType, smoothProcedure,
                      deadband, timeInterval,isActive,exceptionInfo);
    if (dynlen(exceptionInfo)) return;

    for (int i=1;i<=dynlen(dpes);i++) {
        if (configExists[i]) {
            int idx=dynlen(archivingData[1])+1;
            archivingData[1][idx]=dpes[i];
            archivingData[2][idx]=ipropIds[i];
            archivingData[3][idx]=archiveClass[i];
            archivingData[4][idx]=archiveType[i];
            archivingData[5][idx]=smoothProcedure[i];
            archivingData[6][idx]=deadband[i];
            archivingData[7][idx]=timeInterval[i];
            archivingData[8][idx]=isActive[i];
        }
    }

    _fwConfigurationDB_endFunction("extractArchivingConfiguration", t0);
}

/** Saves archiving configuration to Configuration Database
 *
 * @param archivingData should contain the configuration data to be stored (internal format)
 * @param exceptionInfo standard exception handling variable
 */
void _fwConfigurationDB_saveArchivingConfiguration(dyn_dyn_mixed &archivingData, dyn_string &exceptionInfo)
{
    time t0;
    _fwConfigurationDB_startFunction("saveArchivingConfiguration", t0);

    if (dynlen(archivingData[1])>0) {
        anytype cmd;
        string sql="INSERT INTO CONFIG_ARCHIVING (IPROP_ID, CLASSNAME, TYPE, "+
            " SMOOTHPROC, DEADBAND, TIMEINTVAL, ACTIVE) "+
            " VALUES (:IPROP_ID, :CLASSNAME, :TYPE, :SMOOTHPROC,:DEADBAND,:TIMEINTVAL, :ACTIVE)";

        _fwConfigurationDB_startCommand(sql, g_fwConfigurationDB_DBConnection,
                                        cmd, exceptionInfo);

        if (dynlen(exceptionInfo)) {rdbRollbackTransaction(g_fwConfigurationDB_DBConnection);return;}
        for (int i=1;i<=dynlen(archivingData[1]);i++) {
            mapping params;

            // store generic information...
            params[":IPROP_ID"]=archivingData[2][i];
            params[":CLASSNAME"]="\'"+archivingData[3][i]+"\'";
            params[":TYPE"]=archivingData[4][i];
            params[":SMOOTHPROC"]=archivingData[5][i];
            params[":DEADBAND"]=archivingData[6][i];
            params[":TIMEINTVAL"]=archivingData[7][i];
            params[":ACTIVE"]=(int)archivingData[8][i];
            _fwConfigurationDB_bindExecuteCommand(cmd, params, exceptionInfo);
            if (dynlen(exceptionInfo)) {rdbRollbackTransaction(g_fwConfigurationDB_DBConnection);return;}
        }
        _fwConfigurationDB_finishCommand(cmd, exceptionInfo);
        if (dynlen(exceptionInfo)) {rdbRollbackTransaction(g_fwConfigurationDB_DBConnection);return;}
    }
    _fwConfigurationDB_endFunction("saveArchivingConfiguration", t0);
}


/** Loads archiving configuration from Configuration Database
 *
 * @param dpes      list of the data point element names for which configuration is loaded
 * @param ipropIds  corresponding list of IPROP_ID identifiers (in the database) of the data-point elements
 * @param archivingData on return contains the configuration data loaded from database (internal format)
 * @param exceptionInfo standard exception handling variable
 */
void _fwConfigurationDB_loadArchivingConfiguration(dyn_int propIds, dyn_string dpes,
                                               dyn_dyn_mixed &archivingData, dyn_string &exceptionInfo)
{
    time t0;
    _fwConfigurationDB_startFunction("loadArchivingConfiguration", t0);
    dynClear(archivingData);
    archivingData[9][1]="";// make the object valid: (number of columns)

//    string propidsListAsSql=_fwConfigurationDB_listToSQLString("IPROP_ID", propIds);

    //string sql="SELECT IPROP_ID, CLASSNAME, TYPE, SMOOTHPROC, DEADBAND, TIMEINTVAL, ACTIVE "+
    //    " FROM CONFIG_ARCHIVING "+
    //    " WHERE "+propidsListAsSql;
    string sql="SELECT IPROP_ID, CLASSNAME, TYPE, SMOOTHPROC, DEADBAND, TIMEINTVAL, ACTIVE "+
        " FROM CONFIG_ARCHIVING "+
        " where iprop_id in ( select iprop_id from tmp_item_props )";


    dyn_dyn_mixed aRecords;

    _fwConfigurationDB_executeDBQuery(sql,g_fwConfigurationDB_DBConnection, aRecords, exceptionInfo,7,TRUE);
    if (dynlen(exceptionInfo)) return;
    if (dynlen(aRecords)>0) {
        archivingData[2]=aRecords[1]; //iprop_id
        archivingData[3]=aRecords[2]; // classname
        archivingData[4]=aRecords[3]; // type
        archivingData[5]=aRecords[4]; // smooth
        archivingData[6]=(dyn_float)aRecords[5]; // deadband
        archivingData[7]=(dyn_float)aRecords[6]; // timeintval
        archivingData[8]=aRecords[7]; // active

        for (int i=1;i<=dynlen(aRecords[1]);i++) {
            int idx=dynContains(propIds,aRecords[1][i]);
            archivingData[1][i]=dpes[idx]; //dpe
        }
    }
    _fwConfigurationDB_endFunction("loadArchivingConfiguration", t0);
}



////////////

/** Extracts dp function configuration from PVSS
 *
 * @param dpes      list of the data point element names for which configuration is requested
 * @param ipropIds  corresponding list of IPROP_ID identifiers (in the database) of the data-point elements
 * @param dpFunctionData on return contains the configuration data (internal format)
 * @param exceptionInfo standard exception handling variable
 */
void _fwConfigurationDB_extractDpFunctionConfiguration(dyn_string dpes,dyn_int ipropIds,
    dyn_dyn_mixed &dpFunctionData, dyn_string &exceptionInfo)
{
    time t0;
    _fwConfigurationDB_startFunction("extractDpFunctionConfiguration", t0);
    dynClear(dpFunctionData);
    dpFunctionData[6][1]="";// make the object valid: (number of columns)

    dyn_bool configExists;
    dyn_dyn_string functionParams,functionGlobals;
    dyn_string functionDefinition;

    fwDpFunction_getDpeConnectionMany(dpes, configExists, functionParams,
                                      functionGlobals, functionDefinition, exceptionInfo);
    if (dynlen(exceptionInfo)) return;
    for (int i=1;i<=dynlen(dpes);i++) {
        if (configExists[i]) {
            int idx=dynlen(dpFunctionData[1])+1;
            dpFunctionData[1][idx]=dpes[i];
            dpFunctionData[2][idx]=ipropIds[i];
            dpFunctionData[3][idx]=functionParams[i];
            dpFunctionData[4][idx]=functionGlobals[i];
            dpFunctionData[5][idx]=functionDefinition[i];
        }
    }

    _fwConfigurationDB_endFunction("extractDpFunctionConfiguration", t0);
}

/** Saves dp function configuration to Configuration Database
 *
 * @param dpFunctionData should contain the configuration data to be stored (internal format)
 * @param exceptionInfo standard exception handling variable
 */
void _fwConfigurationDB_saveDpFunctionConfiguration(dyn_dyn_mixed &dpFunctionData, dyn_string &exceptionInfo)
{
    time t0;
    _fwConfigurationDB_startFunction("saveDpFunctionConfiguration", t0);
    if (dynlen(dpFunctionData[1])>0) {
        anytype cmd;
        string sql="INSERT INTO CONFIG_DPFUNCTIONS (IPROP_ID, PARAMS, GLOBALS, DEFINITION)"+
            " VALUES (:IPROP_ID, :PARAMS, :GLOBALS, :DEFINITION)";

        _fwConfigurationDB_startCommand(sql, g_fwConfigurationDB_DBConnection,
                                        cmd, exceptionInfo);

        if (dynlen(exceptionInfo)) {rdbRollbackTransaction(g_fwConfigurationDB_DBConnection);return;}
        for (int i=1;i<=dynlen(dpFunctionData[1]);i++) {
            mapping params;
            params[":IPROP_ID"]=dpFunctionData[2][i];
            string sval;
            dyn_string ds=dpFunctionData[3][i];
            _fwConfigurationDB_dataToString(ds , DPEL_DYN_STRING,"|", sval,exceptionInfo);
            params[":PARAMS"]="\'"+sval+"\'";
            ds=dpFunctionData[4][i];
            _fwConfigurationDB_dataToString(ds , DPEL_DYN_STRING,"|", sval,exceptionInfo);
            params[":GLOBALS"]="\'"+sval+"\'";
            params[":DEFINITION"]="\'"+dpFunctionData[5][i]+"\'";

            _fwConfigurationDB_bindExecuteCommand(cmd, params, exceptionInfo);
            if (dynlen(exceptionInfo)) {rdbRollbackTransaction(g_fwConfigurationDB_DBConnection);return;}
        }
        _fwConfigurationDB_finishCommand(cmd, exceptionInfo);
        if (dynlen(exceptionInfo)) {rdbRollbackTransaction(g_fwConfigurationDB_DBConnection);return;}
    }

    _fwConfigurationDB_endFunction("saveDpFunctionConfiguration", t0);
}


/** Loads dp function configuration from Configuration Database
 *
 * @param dpes      list of the data point element names for which configuration is loaded
 * @param ipropIds  corresponding list of IPROP_ID identifiers (in the database) of the data-point elements
 * @param dpFunctionData on return contains the configuration data loaded from database (internal format)
 * @param exceptionInfo standard exception handling variable
 */
void _fwConfigurationDB_loadDpFunctionConfiguration(dyn_int propIds, dyn_string dpes,
    dyn_dyn_mixed &dpFunctionData, dyn_string &exceptionInfo)
{
    time t0;
    _fwConfigurationDB_startFunction("loadDpFunctionConfiguration", t0);
    dynClear(dpFunctionData);
    dpFunctionData[6][1]="";// make the object valid: (number of columns)

//    string propidsListAsSql=_fwConfigurationDB_listToSQLString("IPROP_ID", propIds);

    //string sql="SELECT IPROP_ID, PARAMS, GLOBALS, DEFINITION "+
    //    " FROM CONFIG_DPFUNCTIONS "+
    //    " WHERE "+propidsListAsSql;
    string sql="SELECT IPROP_ID, PARAMS, GLOBALS, DEFINITION "+
        " FROM CONFIG_DPFUNCTIONS "+
        " where iprop_id in ( select iprop_id from tmp_item_props )";


    dyn_dyn_mixed aRecords;

    _fwConfigurationDB_executeDBQuery(sql,g_fwConfigurationDB_DBConnection, aRecords, exceptionInfo,4,TRUE);
    if (dynlen(exceptionInfo)) return;
    if (dynlen(aRecords)>0) {
        dpFunctionData[2]=aRecords[1]; //iprop_id
        dpFunctionData[5]=aRecords[4]; //iprop_id
        for (int i=1;i<=dynlen(aRecords[1]);i++) {
            int idx=dynContains(propIds,aRecords[1][i]);
            dpFunctionData[1][i]=dpes[idx]; //dpe
            //params
            _fwConfigurationDB_stringToData(aRecords [2][i], DPEL_DYN_STRING, "|",
                                            dpFunctionData[3][i], exceptionInfo);
            // globals
            _fwConfigurationDB_stringToData(aRecords [3][i], DPEL_DYN_STRING, "|",
                                            dpFunctionData[4][i], exceptionInfo);
        }
    }
    _fwConfigurationDB_endFunction("loadDpFunctionConfiguration", t0);
}


////////////

/** Extracts conversion configuration from PVSS
 *
 * @param dpes      list of the data point element names for which configuration is requested
 * @param ipropIds  corresponding list of IPROP_ID identifiers (in the database) of the data-point elements
 * @param conversionData on return contains the configuration data (internal format)
 * @param exceptionInfo standard exception handling variable
 */
void _fwConfigurationDB_extractConversionConfiguration(dyn_string dpes,dyn_int ipropIds,
    dyn_dyn_mixed &conversionData, dyn_string &exceptionInfo)
{
    time t0;
    _fwConfigurationDB_startFunction("extractConversionConfiguration", t0);
    dynClear(conversionData);
    conversionData[7][1]="";// make the object valid: (number of columns)


    dyn_bool configExistsCmd,configExistsMsg;
    dyn_int conversionTypeCmd,conversionTypeMsg, orderCmd, orderMsg;
    dyn_dyn_float argumentsCmd,argumentsMsg;

    // message conversion
    int configTypeMsg=DPCONFIG_CONVERSION_RAW_TO_ENG_MAIN;
    int configTypeCmd=DPCONFIG_CONVERSION_ING_TO_RAW_MAIN;
    fwConfigConversion_getMany(dpes, configExistsMsg, configTypeMsg,
                               conversionTypeMsg, orderMsg,argumentsMsg, exceptionInfo);
    fwConfigConversion_getMany(dpes, configExistsCmd, configTypeCmd,
                               conversionTypeCmd, orderCmd,argumentsCmd, exceptionInfo);

    if (dynlen(exceptionInfo)) return;
    for (int i=1;i<=dynlen(dpes);i++) {
        if (configExistsMsg[i]) {
            int idx=dynlen(conversionData[1])+1;
            conversionData[1][idx]=dpes[i];
            conversionData[2][idx]=ipropIds[i];
            conversionData[3][idx]=configTypeMsg;
            conversionData[4][idx]=conversionTypeMsg[i];
            conversionData[5][idx]=orderMsg[i];
            conversionData[6][idx]=argumentsMsg[i];
        }
        if (configExistsCmd[i]) {
            int idx=dynlen(conversionData[1])+1;
            conversionData[1][idx]=dpes[i];
            conversionData[2][idx]=ipropIds[i];
            conversionData[3][idx]=configTypeCmd;
            conversionData[4][idx]=conversionTypeCmd[i];
            conversionData[5][idx]=orderCmd[i];
            conversionData[6][idx]=argumentsCmd[i];
        }
    }

    _fwConfigurationDB_endFunction("extractConversionConfiguration", t0);
}

/** Saves conversion configuration to Configuration Database
 *
 * @param conversionData should contain the configuration data to be stored (internal format)
 * @param exceptionInfo standard exception handling variable
 */
void _fwConfigurationDB_saveConversionConfiguration(dyn_dyn_mixed &conversionData,
    dyn_string &exceptionInfo)
{
    time t0;
    _fwConfigurationDB_startFunction("saveConversionConfiguration", t0);

    if (dynlen(conversionData[1])>0) {
        anytype cmd;
        string sql="INSERT INTO CONFIG_CONVERSIONS (IPROP_ID, TYPE, CONVTYPE, CONVORDER, ARGUMENTS)"+
            " VALUES (:IPROP_ID, :TYPE, :CONVTYPE, :CONVORDER, :ARGUMENTS)";

        _fwConfigurationDB_startCommand(sql, g_fwConfigurationDB_DBConnection,
                                        cmd, exceptionInfo);

        if (dynlen(exceptionInfo)) {rdbRollbackTransaction(g_fwConfigurationDB_DBConnection);return;}
        for (int i=1;i<=dynlen(conversionData[1]);i++) {
            mapping params;
            params[":IPROP_ID"]=conversionData[2][i];
            params[":TYPE"]=conversionData[3][i];
            params[":CONVTYPE"]=conversionData[4][i];
            params[":CONVORDER"]=conversionData[5][i];

            string sval;
            dyn_float ds=conversionData[6][i];
            _fwConfigurationDB_dataToString(ds , DPEL_DYN_FLOAT,"|", sval,exceptionInfo);
            params[":ARGUMENTS"]="\'"+sval+"\'";
            _fwConfigurationDB_bindExecuteCommand(cmd, params, exceptionInfo);
            if (dynlen(exceptionInfo)) {rdbRollbackTransaction(g_fwConfigurationDB_DBConnection);return;}
        }
        _fwConfigurationDB_finishCommand(cmd, exceptionInfo);
        if (dynlen(exceptionInfo)) {rdbRollbackTransaction(g_fwConfigurationDB_DBConnection);return;}
    }

    _fwConfigurationDB_endFunction("saveConversionConfiguration", t0);
}


/** Loads conversion configuration from Configuration Database
 *
 * @param dpes      list of the data point element names for which configuration is loaded
 * @param ipropIds  corresponding list of IPROP_ID identifiers (in the database) of the data-point elements
 * @param conversionData on return contains the configuration data loaded from database (internal format)
 * @param exceptionInfo standard exception handling variable
 */
void _fwConfigurationDB_loadConversionConfiguration(dyn_int propIds, dyn_string dpes,
    dyn_dyn_mixed &conversionData, dyn_string &exceptionInfo)
{
    time t0;
    _fwConfigurationDB_startFunction("loadConversionConfiguration", t0);
    dynClear(conversionData);
    conversionData[7][1]="";// make the object valid: (number of columns)
//    string propidsListAsSql=_fwConfigurationDB_listToSQLString("IPROP_ID", propIds);

    //string sql="SELECT IPROP_ID, TYPE, CONVTYPE, CONVORDER, ARGUMENTS "+
    //    " FROM CONFIG_CONVERSIONS "+
    //    " WHERE "+propidsListAsSql;
    string sql="SELECT IPROP_ID, TYPE, CONVTYPE, CONVORDER, ARGUMENTS "+
        " FROM CONFIG_CONVERSIONS "+
        " where iprop_id in ( select iprop_id from tmp_item_props )";

    dyn_dyn_mixed aRecords;

    _fwConfigurationDB_executeDBQuery(sql,g_fwConfigurationDB_DBConnection, aRecords, exceptionInfo,5,TRUE);
    if (dynlen(exceptionInfo)) return;
    if (dynlen(aRecords)>0) {
        conversionData[2]=(dyn_int)aRecords[1]; //iprop_id
        conversionData[3]=(dyn_int)aRecords[2]; // type
        conversionData[4]=(dyn_int)aRecords[3]; // convtype
        conversionData[5]=(dyn_int)aRecords[4]; // order
        for (int i=1;i<=dynlen(aRecords[1]);i++) {
            int idx=dynContains(propIds,aRecords[1][i]);
            conversionData[1][i]=dpes[idx]; //dpe
            //arguments
            _fwConfigurationDB_stringToData(aRecords [5][i], DPEL_DYN_FLOAT, "|",
                                            conversionData[6][i], exceptionInfo);
        }
    }


    _fwConfigurationDB_endFunction("loadConversionConfiguration", t0);
}





////////////

/** Extracts pv range configuration from PVSS
 *
 * @param dpes      list of the data point element names for which configuration is requested
 * @param ipropIds  corresponding list of IPROP_ID identifiers (in the database) of the data-point elements
 * @param pvRangeData on return contains the configuration data (internal format)
 *					columns 1-
 * @param exceptionInfo standard exception handling variable
 */
void _fwConfigurationDB_extractPvRangeConfiguration(dyn_string dpes,dyn_int ipropIds,
    dyn_dyn_mixed &pvRangeData, dyn_string &exceptionInfo)
{
    time t0;
    _fwConfigurationDB_startFunction("extractPvRangeConfiguration", t0);

    dynClear(pvRangeData);

    dyn_bool configExists;
    dyn_int pvRangeTypes;
    dyn_dyn_mixed configData;
    fwPvRange_getObjectMany( dpes, configExists, pvRangeTypes,
                            configData, exceptionInfo);
    if (dynlen(exceptionInfo)) return;
    for (int i=1;i<=dynlen(configData);i++) {
	if (!configExists[i]) continue;
	dyn_mixed obj=configData[i];

	obj[9]=dpes[i];
	obj[10]=ipropIds[i];
	obj[11]=pvRangeTypes[i];
	dynAppend(pvRangeData,obj);
    }
/*
    dyn_bool configExists,negateRange,ignoreOutside,inclusiveMin,inclusiveMax;
    dyn_float minValue, maxValue;

    //// #17981/#17982 - pv ranges of type RANGECHECK not supported by Framework.
    //// we skip saving pvrange for them as of now...

    dyn_string chkDpes,pvrDpes;
    dyn_int pvrIpropIds;
    dyn_int chktypes;
    for (int i=1;i<=dynlen(dpes);i++) {
        dynAppend(chkDpes,dpes[i]+":_pv_range.._type");
    }
    dpGet(chkDpes,chktypes);
    for (int i=1;i<=dynlen(chkDpes);i++) {
        switch(chktypes[i]) {
        case DPCONFIG_NONE:
            break;
        case DPCONFIG_MINMAX_PVSS_RANGECHECK:
            dynAppend(pvrDpes,dpes[i]);
            dynAppend(pvrIpropIds,ipropIds[i]);
            break;
        case DPCONFIG_SET_PVSS_RANGECHECK:
            DebugN("WARNING! Unsupported PVRANGE of type RANGECHECK for "+dpes[i]+" ->skipping it");
            break;
        default:
            fwException_raise(exceptionInfo,"ERROR",
                              "PVRange type "+chktypes[i]+" not supported for "+dpes[i],"");
            return;
            break;
        }

    }
// then substitute lists...
    dpes=pvrDpes;
    ipropIds=pvrIpropIds;

//DebugN("calling getMany for",dpes);

    fwPvRange_getMany(dpes, configExists, minValue, maxValue,
                      negateRange, ignoreOutside,
                      inclusiveMin, inclusiveMax, exceptionInfo);
    if (dynlen(exceptionInfo)) return;
    for (int i=1;i<=dynlen(dpes);i++) {
        if (configExists[i]) {
            int idx=dynlen(pvRangeData[1])+1;
            pvRangeData[1][idx]=dpes[i];
            pvRangeData[2][idx]=ipropIds[i];
            pvRangeData[3][idx]=minValue[i];
            pvRangeData[4][idx]=maxValue[i];
            pvRangeData[5][idx]=negateRange[i];
            pvRangeData[6][idx]=ignoreOutside[i];
            pvRangeData[7][idx]=inclusiveMin[i];
            pvRangeData[8][idx]=inclusiveMax[i];
        }
    }
*/
    _fwConfigurationDB_endFunction("extractPvRangeConfiguration", t0);
}

/** Saves pv range configuration to Configuration Database
 *
 * @param pvRangeData should contain the configuration data to be stored (internal format)
 * @param exceptionInfo standard exception handling variable
 */
void _fwConfigurationDB_savePvRangeConfiguration(dyn_dyn_mixed &pvRangeData,
    dyn_string &exceptionInfo)
{
    time t0;
    _fwConfigurationDB_startFunction("savePvRangeConfiguration", t0);
    if ((dynlen(pvRangeData)>0) && (dynlen(pvRangeData[1])>0)) {
        anytype cmd;
        string sql="INSERT INTO CONFIG_PVRANGES (IPROP_ID, PVRTYPE, MINVALUE, MAXVALUE, "+
                    " NEGRANGE, IGNOUTSIDE, INCLMIN, INCLMAX, PVRVALS)"+
                    " VALUES (:IPROP_ID, :PVRTYPE, :MINVALUE, :MAXVALUE, :NEGRANGE, "+
                    " :IGNOUTSIDE, :INCLMIN, :INCLMAX, :PVRVALS)";

        _fwConfigurationDB_startCommand(sql, g_fwConfigurationDB_DBConnection,
                                        cmd, exceptionInfo);

        if (dynlen(exceptionInfo)) {rdbRollbackTransaction(g_fwConfigurationDB_DBConnection);return;}
        for (int i=1;i<=dynlen(pvRangeData);i++) {
            mapping params;
            params[":MINVALUE"]  = (float)pvRangeData[i][fwPvRange_MINIMUM_VALUE];
            params[":MAXVALUE"]  = (float)pvRangeData[i][fwPvRange_MAXIMUM_VALUE];
            params[":NEGRANGE"]  = (int)pvRangeData[i][fwPvRange_NEGATE_RANGE];
            params[":IGNOUTSIDE"]= (int)pvRangeData[i][fwPvRange_IGNORE_OUTSIDE];
            params[":INCLMIN"]   = (int)pvRangeData[i][fwPvRange_INCLUSIVE_MINIMUM];
            params[":INCLMAX"]   = (int)pvRangeData[i][fwPvRange_INCLUSIVE_MAXIMUM];
            if (pvRangeData[i][11]==DPCONFIG_MATCH_PVSS_RANGECHECK) {
        	params[":PVRVALS"]   = "\'"+pvRangeData[i][fwPvRange_VALUE_PATTERN]+"\'";
            } else if (pvRangeData[i][11]==DPCONFIG_SET_PVSS_RANGECHECK) {
        	dyn_string data=pvRangeData[i][fwPvRange_VALUE_SET];
        	string encodedData;
        	_fwConfigurationDB_dataToString(data,DPEL_DYN_STRING, "|", encodedData,exceptionInfo);
		if (dynlen(exceptionInfo)) return;
        	params[":PVRVALS"] = "\'"+encodedData+"\'";
            } else {
        	params[":PVRVALS"]="''";
            }

            params[":IPROP_ID"]  = pvRangeData[i][10];
            params[":PVRTYPE"]   = (int) pvRangeData[i][11];
            _fwConfigurationDB_bindExecuteCommand(cmd, params, exceptionInfo);
            if (dynlen(exceptionInfo)) {rdbRollbackTransaction(g_fwConfigurationDB_DBConnection);return;}
        }
        _fwConfigurationDB_finishCommand(cmd, exceptionInfo);
        if (dynlen(exceptionInfo)) {rdbRollbackTransaction(g_fwConfigurationDB_DBConnection);return;}
    }
    _fwConfigurationDB_endFunction("savePvRangeConfiguration", t0);
}


/** Loads pv range configuration from Configuration Database
 *
 * @param ipropIds  list of IPROP_ID identifiers (effectively DPE's in the database) for which the
 *			configuration is loaded
 * @param dpes  on input - needs to contain the list of dpenames, parallel to ipropIds; this
 *		list is overwritten on return!
 *		on return, will contain the list of dpes for which the pvrange data exist; the
 *			actual data (in a ready-to-apply pvrange "object" format) is returned
 *			in @c pvRangeData
 * @param pvrTypes  on return contains types of pvrange for subsequent dpes
 * @param pvRangeData on return contains the configuration data loaded from database (pvrange "object" format)
 * @param exceptionInfo standard exception handling variable
 */
void _fwConfigurationDB_loadPvRangeConfiguration(dyn_int propIds, dyn_string &dpes, dyn_int &pvrTypes,
    dyn_dyn_mixed &pvRangeData, dyn_string &exceptionInfo)
{
    time t0;
    _fwConfigurationDB_startFunction("loadPvRangeConfiguration", t0);
    dynClear(pvRangeData);
//    pvRangeData[11][1]="";// make the object valid: (number of columns)

//    string propidsListAsSql=_fwConfigurationDB_listToSQLString("IPROP_ID", propIds);

    //string sql="SELECT IPROP_ID, MINVALUE, MAXVALUE, NEGRANGE, IGNOUTSIDE, INCLMIN, INCLMAX"+
    //    " FROM CONFIG_PVRANGES "+
    //    " WHERE "+propidsListAsSql;
    string sql="SELECT MINVALUE, MAXVALUE, PVRVALS, PVRVALS, NEGRANGE, IGNOUTSIDE, INCLMIN, INCLMAX,"+
        " '', IPROP_ID,PVRTYPE FROM CONFIG_PVRANGES "+
        " where iprop_id in ( select iprop_id from tmp_item_props )";

    dyn_dyn_mixed aRecords;
    dyn_string newDpes;
    _fwConfigurationDB_executeDBQuery(sql,g_fwConfigurationDB_DBConnection, aRecords, exceptionInfo);
    if (dynlen(exceptionInfo)) return;
    if (dynlen(aRecords)>0) {
	for (int i=1;i<=dynlen(aRecords);i++) {
	    // restore the dpe name
	    int idx=dynContains(propIds,(int)(aRecords[i][10]));
	    newDpes[i]=dpes[idx];
	    pvrTypes[i]=aRecords[i][11];
	    mixed dat=aRecords[i];
	    if (pvrTypes[i]==DPCONFIG_SET_PVSS_RANGECHECK) {
    		string encodedData=aRecords[i][fwPvRange_VALUE_SET];
    		anytype decodedData;
    		_fwConfigurationDB_stringToData(encodedData, DPEL_DYN_STRING, "|", decodedData,exceptionInfo);
    		if (dynlen(exceptionInfo)) return;
    		dat[fwPvRange_VALUE_SET]=decodedData;
    	    }
    	    pvRangeData[i]=dat;

	}
    }
    dpes=newDpes;
/*
    if (dynlen(aRecords)>0) {
        pvRangeData[2]=(dyn_int)aRecords[1]; //iprop_id
        pvRangeData[3]=(dyn_float)aRecords[2]; // min
        pvRangeData[4]=(dyn_float)aRecords[3]; // max
        pvRangeData[5]=(dyn_bool)aRecords[4]; // negrange
        pvRangeData[6]=(dyn_bool)aRecords[5]; // ignoutside
        pvRangeData[7]=(dyn_bool)aRecords[6]; // inclmin
        pvRangeData[8]=(dyn_bool)aRecords[7]; // inclmax
        for (int i=1;i<=dynlen(aRecords[1]);i++) {
            int idx=dynContains(propIds,aRecords[1][i]);
            pvRangeData[1][i]=dpes[idx]; //dpe
        }
    }
*/
    _fwConfigurationDB_endFunction("loadPvRangeConfiguration", t0);
}

////////////

/** Extracts smoothing configuration from PVSS
 *
 * @param dpes      list of the data point element names for which configuration is requested
 * @param ipropIds  corresponding list of IPROP_ID identifiers (in the database) of the data-point elements
 * @param smoothingData on return contains the configuration data (internal format)
 * @param exceptionInfo standard exception handling variable
 */
void _fwConfigurationDB_extractSmoothingConfiguration(dyn_string dpes,dyn_int ipropIds,
    dyn_dyn_mixed &smoothingData, dyn_string &exceptionInfo)
{
    time t0;
    _fwConfigurationDB_startFunction("extractSmoothingConfiguration", t0);
    dynClear(smoothingData);
    smoothingData[6][1]="";// make the object valid: (number of columns)
    dyn_bool configExists;
    dyn_int smoothProcedure;
    dyn_float deadband, timeInterval;

    fwSmoothing_getMany(dpes, configExists, smoothProcedure, deadband, timeInterval, exceptionInfo);
    if (dynlen(exceptionInfo)) return;
    for (int i=1;i<=dynlen(dpes);i++) {
        if (configExists[i]) {
            int idx=dynlen(smoothingData[1])+1;
            smoothingData[1][idx]=dpes[i];
            smoothingData[2][idx]=ipropIds[i];
            smoothingData[3][idx]=smoothProcedure[i];
            smoothingData[4][idx]=deadband[i];
            smoothingData[5][idx]=timeInterval[i];
        }
    }
    _fwConfigurationDB_endFunction("extractSmoothingConfiguration", t0);
}

/** Saves smoothing configuration to Configuration Database
 *
 * @param smoothingData should contain the configuration data to be stored (internal format)
 * @param exceptionInfo standard exception handling variable
 */
void _fwConfigurationDB_saveSmoothingConfiguration(dyn_dyn_mixed &smoothingData,
    dyn_string &exceptionInfo)
{
    time t0;
    _fwConfigurationDB_startFunction("saveSmoothingConfiguration", t0);
    if (dynlen(smoothingData[1])>0) {
        anytype cmd;
        string sql="INSERT INTO CONFIG_SMOOTHING (IPROP_ID, PROC, DEADBAND, TIMEINTVAL) "+
            " VALUES (:IPROP_ID, :PROC, :DEADBAND, :TIMEINTVAL) ";

        _fwConfigurationDB_startCommand(sql, g_fwConfigurationDB_DBConnection,
                                        cmd, exceptionInfo);

        if (dynlen(exceptionInfo)) {rdbRollbackTransaction(g_fwConfigurationDB_DBConnection);return;}
        for (int i=1;i<=dynlen(smoothingData[1]);i++) {
            mapping params;
            params[":IPROP_ID"]  = smoothingData[2][i];
            params[":PROC"]      = smoothingData[3][i];
            params[":DEADBAND"]  = smoothingData[4][i];
            params[":TIMEINTVAL"]= smoothingData[5][i];
            _fwConfigurationDB_bindExecuteCommand(cmd, params, exceptionInfo);
            if (dynlen(exceptionInfo)) {rdbRollbackTransaction(g_fwConfigurationDB_DBConnection);return;}
        }
        _fwConfigurationDB_finishCommand(cmd, exceptionInfo);
        if (dynlen(exceptionInfo)) {rdbRollbackTransaction(g_fwConfigurationDB_DBConnection);return;}
    }

    _fwConfigurationDB_endFunction("saveSmoothingConfiguration", t0);
}


/** Loads smoothing configuration from Configuration Database
 *
 * @param dpes      list of the data point element names for which configuration is loaded
 * @param ipropIds  corresponding list of IPROP_ID identifiers (in the database) of the data-point elements
 * @param smoothingData on return contains the configuration data loaded from database (internal format)
 * @param exceptionInfo standard exception handling variable
 */
void _fwConfigurationDB_loadSmoothingConfiguration(dyn_int propIds, dyn_string dpes,
    dyn_dyn_mixed &smoothingData, dyn_string &exceptionInfo)
{
    time t0;
    _fwConfigurationDB_startFunction("loadSmoothingConfiguration", t0);
    dynClear(smoothingData);
    smoothingData[6][1]="";// make the object valid: (number of columns)
//    string propidsListAsSql=_fwConfigurationDB_listToSQLString("IPROP_ID", propIds);

    //string sql="SELECT IPROP_ID, PROC, DEADBAND, TIMEINTVAL "+
    //    " FROM CONFIG_SMOOTHING "+
    //    " WHERE "+propidsListAsSql;
    string sql="SELECT IPROP_ID, PROC, DEADBAND, TIMEINTVAL "+
        " FROM CONFIG_SMOOTHING "+
        " where iprop_id in ( select iprop_id from tmp_item_props )";

    dyn_dyn_mixed aRecords;

    _fwConfigurationDB_executeDBQuery(sql,g_fwConfigurationDB_DBConnection, aRecords, exceptionInfo,5,TRUE);
    if (dynlen(exceptionInfo)) return;
    if (dynlen(aRecords)>0) {
        smoothingData[2]=(dyn_int)aRecords[1]; //iprop_id
        smoothingData[3]=(dyn_int)aRecords[2]; // proc
        smoothingData[4]=(dyn_float)aRecords[3]; // deadband
        smoothingData[5]=(dyn_float)aRecords[4]; // timeintval
        for (int i=1;i<=dynlen(aRecords[1]);i++) {
            int idx=dynContains(propIds,aRecords[1][i]);
            smoothingData[1][i]=dpes[idx]; //dpe
        }
    }
    _fwConfigurationDB_endFunction("loadSmoothingConfiguration", t0);
}

////////////

/** Extracts unit and format configuration from PVSS
 *
 * @param dpes      list of the data point element names for which configuration is requested
 * @param ipropIds  corresponding list of IPROP_ID identifiers (in the database) of the data-point elements
 * @param unitAndFormatData on return contains the configuration data (internal format)
 * @param exceptionInfo standard exception handling variable
 */
void _fwConfigurationDB_extractUnitAndFormatConfiguration(dyn_string dpes,dyn_int ipropIds,
    dyn_dyn_mixed &unitAndFormatData, dyn_string &exceptionInfo)
{
    time t0;
    _fwConfigurationDB_startFunction("extractUnitAndFormatConfiguration", t0);
    dynClear(unitAndFormatData);
    unitAndFormatData[5][1]="";// make the object valid: (number of columns)

    dyn_bool unitExists,formatExists;
    dyn_string unit,format;

    fwUnit_getMany  (dpes, unitExists,   unit,  exceptionInfo);
    fwFormat_getMany(dpes, formatExists, format,exceptionInfo);
    if (dynlen(exceptionInfo)) return;
    for (int i=1;i<=dynlen(dpes);i++) {
        if ((unitExists[i])||(formatExists[i])) {
            int idx=dynlen(unitAndFormatData[1])+1;
            unitAndFormatData[1][idx]=dpes[i];
            unitAndFormatData[2][idx]=ipropIds[i];
            if (unitExists[i])
                unitAndFormatData[3][idx]=unit[i];
            else
                unitAndFormatData[3][idx]="";
            if (formatExists[i])
                unitAndFormatData[4][idx]=format[i];
            else
                unitAndFormatData[4][idx]="";
        }
    }
    _fwConfigurationDB_endFunction("extractUnitAndFormatConfiguration", t0);

}

/** Saves unit and format configuration to Configuration Database
 *
 * @param unitAndFormatData should contain the configuration data to be stored (internal format)
 * @param exceptionInfo standard exception handling variable
 */
void _fwConfigurationDB_saveUnitAndFormatConfiguration(dyn_dyn_mixed &unitAndFormatData,
    dyn_string &exceptionInfo)
{
    time t0;
    _fwConfigurationDB_startFunction("saveUnitAndFormatConfiguration", t0);
    if (dynlen(unitAndFormatData[1])>0) {
        anytype cmd;
        string sql="INSERT INTO CONFIG_UF (IPROP_ID, UNIT, FMT) "+
            " VALUES (:IPROP_ID, :UNIT, :FMT) ";

        _fwConfigurationDB_startCommand(sql, g_fwConfigurationDB_DBConnection,
                                        cmd, exceptionInfo);

        if (dynlen(exceptionInfo)) {rdbRollbackTransaction(g_fwConfigurationDB_DBConnection);return;}
        for (int i=1;i<=dynlen(unitAndFormatData[1]);i++) {
            mapping params;
            params[":IPROP_ID"]  = unitAndFormatData[2][i];
            params[":UNIT"]      = "\'"+unitAndFormatData[3][i]+"\'";
            params[":FMT"]       = "\'"+unitAndFormatData[4][i]+"\'";
            _fwConfigurationDB_bindExecuteCommand(cmd, params, exceptionInfo);
            if (dynlen(exceptionInfo)) {rdbRollbackTransaction(g_fwConfigurationDB_DBConnection);return;}
        }
        _fwConfigurationDB_finishCommand(cmd, exceptionInfo);
        if (dynlen(exceptionInfo)) {rdbRollbackTransaction(g_fwConfigurationDB_DBConnection);return;}
    }

    _fwConfigurationDB_endFunction("saveUnitAndFormatConfiguration", t0);
}


/** Loads unit and format configuration from Configuration Database
 *
 * @param dpes      list of the data point element names for which configuration is loaded
 * @param ipropIds  corresponding list of IPROP_ID identifiers (in the database) of the data-point elements
 * @param unitAndFormatData on return contains the configuration data loaded from database (internal format)
 * @param exceptionInfo standard exception handling variable
 */
void _fwConfigurationDB_loadUnitAndFormatConfiguration(dyn_int propIds, dyn_string dpes,
    dyn_dyn_mixed &unitAndFormatData, dyn_string &exceptionInfo)
{
    time t0;
    _fwConfigurationDB_startFunction("loadUnitAndFormatConfiguration", t0);
    dynClear(unitAndFormatData);
    unitAndFormatData[5][1]="";// make the object valid: (number of columns)

//    string propidsListAsSql=_fwConfigurationDB_listToSQLString("IPROP_ID", propIds);

    //string sql="SELECT IPROP_ID, UNIT, FMT FROM CONFIG_UF "+
    //    " WHERE "+propidsListAsSql;
    string sql="SELECT IPROP_ID, UNIT, FMT FROM CONFIG_UF "+
        " where iprop_id in ( select iprop_id from tmp_item_props )";

    dyn_dyn_mixed aRecords;

    _fwConfigurationDB_executeDBQuery(sql,g_fwConfigurationDB_DBConnection, aRecords, exceptionInfo,3,TRUE);
    if (dynlen(exceptionInfo)) return;
    if (dynlen(aRecords)>0) {
        unitAndFormatData[2]=(dyn_int)aRecords[1]; //iprop_id
        unitAndFormatData[3]=aRecords[2]; // unit
        unitAndFormatData[4]=aRecords[3]; // format
        for (int i=1;i<=dynlen(aRecords[1]);i++) {
            int idx=dynContains(propIds,aRecords[1][i]);
            unitAndFormatData[1][i]=dpes[idx]; //dpe
        }
        
	// #42559 quick-fix the UTF-8 encoded characters...
	for (int i=1;i<=dynlen(unitAndFormatData[3]);i++) {
	    string u=unitAndFormatData[3][i];
	    int c=(int) u[0];
	    if (c==194) { // escape char for UTF-8 for thinhs such as "micro"
		// strip it!
		unitAndFormatData[3][i]=substr(u,1);
	    }
	}
    }
    
    _fwConfigurationDB_endFunction("loadUnitAndFormatConfiguration", t0);
}






