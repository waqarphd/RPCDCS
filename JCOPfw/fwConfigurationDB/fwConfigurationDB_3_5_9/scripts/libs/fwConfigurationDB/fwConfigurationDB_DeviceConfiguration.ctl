/**@file

This package contains device-configuration functions of the Configuration Database tool

@author Piotr Golonka (EN/ICE-SCD)
@date   December 2012
*/
global string _fwConfigurationDB_fileVersion_fwConfigurationDB_DeviceConfiguration_ctl="3.5.9";


void _fwConfigurationDB_loadApplyValues(dyn_string &exceptionInfo)
{
	DebugTN("loading/applying values...");

        if (fwConfigurationDB_progress(fwConfigurationDB_OPER_LoadDeviceProperties,"Loading values", 40.0,
                                   exceptionInfo)) return;

        DebugTN("loading the values");
        ////////////
        // WORKAROUND FOR #86425
	string sql = "select tip.dpename, cv.pvalue, CASE when de.elementtype=24 then 25 else de.elementtype end ELEMENTTYPE"+
                 " from CONFIG_ITEMPROPS p, tmp_item_props tip, device_elements de , config_values cv "+
                 " where  "+
		 " cv.iprop_id = tip.iprop_id and "+
                 " p.iprop_id=tip.iprop_id and "+
                 " de.develem_id=p.develem_id ";
//                 " and de.elementtype!=1"; // eliminate eventual DPEL_STRUCT!
                 
	dyn_int colTypes=makeDynInt(0,-3,DPEL_INT);
	DebugTN("Executing",sql);
	dbCommand dbCmd;
	fwConfigurationDB_initializeQuery( sql, g_fwConfigurationDB_DBConnection, dbCmd, exceptionInfo);
	if (dynlen(exceptionInfo)) return;
	DebugTN("query executed, processing data by chunks now...");
	int rc=0;
	int maxRecords=100000;
	int nLoops=0;
	do {
	    nLoops++;
	    if (fwConfigurationDB_progress(fwConfigurationDB_OPER_LoadDevices,"Loading values ["+nLoops+"]", 20.0, exceptionInfo,false)) {
		fwDbFinishCommand (dbCmd);
		return;
	    }
	    dyn_dyn_mixed data;
	    rc=fwConfigurationDB_fetchQuery(dbCmd, data,exceptionInfo, maxRecords, FALSE ,TRUE, colTypes,3);
	    
	    if (fwConfigurationDB_progress(fwConfigurationDB_OPER_LoadDevices,"Checking values ["+nLoops+"]", 20.0, exceptionInfo,false)) {
		fwDbFinishCommand (dbCmd);
		return;
	    }
	    
	    DebugTN("Fetched a chunk",dynlen(data));
	    DebugTN("Verify compatibility");
	    dyn_string valDpes;
	    dyn_mixed  values;
	    int nVals=0;
	    for (int i=1;i<=dynlen(data);i++) {
		string valDpe=data[i][1];
		mixed value=data[i][2];
		dyn_string supportedConfigs=dpGetAllConfigs(valDpe);
    		if ( dynContains(supportedConfigs,"_online")) {
    		    nVals++;
		    valDpes[nVals]=valDpe;
		    values[nVals]=value; //dynAppend fails if value is of dyn_ type
    		}
	    }
	    DebugTN("Processing done, we will have "+nVals+" values");
	    if (dynlen(valDpes)) {
		DebugTN("Setting the values now...");
		if (fwConfigurationDB_progress(fwConfigurationDB_OPER_LoadDevices,"Setting values ["+nLoops+"]", 20.0, exceptionInfo,false)) {
		    fwDbFinishCommand (dbCmd);
		    return;
		}

    		fwConfigurationDB_dpSetManyDist(valDpes, values, exceptionInfo, false);
		if (dynlen(exceptionInfo)) return;
		DebugTN("Value set done");
	    }
	} while (rc==1);
 	

        DebugTN("loading big values");
	string sql = "select tip.dpename, pbig.cvalue, CASE when de.elementtype=24 then 25 else de.elementtype end  ELEMENTTYPE"+
                 " from CONFIG_VALUES_BIG pbig, CONFIG_ITEMPROPS p, tmp_item_props tip, device_elements de  "+
                 " where  "+
                 " pbig.iprop_id=tip.iprop_id and "+
                 " p.iprop_id=pbig.iprop_id and "+
                 " de.develem_id=p.develem_id";
                 
	dyn_int colTypes=makeDynInt(0,-3,DPEL_INT);
	DebugTN("Executing",sql);
	dbCommand dbCmdBig;
	fwConfigurationDB_initializeQuery( sql, g_fwConfigurationDB_DBConnection, dbCmdBig, exceptionInfo);
	if (dynlen(exceptionInfo)) return;
	DebugTN("query executed, processing data by chunks now...");
	rc=0;
	maxRecords=10000;
	nLoops=0;
	do {
	    nLoops++;
	    if (fwConfigurationDB_progress(fwConfigurationDB_OPER_LoadDevices,"Loading big values ["+nLoops+"]", 25.0, exceptionInfo,false)) {
		fwDbFinishCommand (dbCmdBig);
		return;
	    }
	    
	    dyn_dyn_mixed data;
	    rc=fwConfigurationDB_fetchQuery(dbCmdBig, data,exceptionInfo, maxRecords, FALSE ,TRUE, colTypes,3);
	    if (dynlen(exceptionInfo)) return;
	    
	    DebugTN("Fetched a chunk",dynlen(data));
	    if (fwConfigurationDB_progress(fwConfigurationDB_OPER_LoadDevices,"Checking big values ["+nLoops+"]", 25.0, exceptionInfo,false)) {
		fwDbFinishCommand (dbCmdBig);
		return;
	    }

	    DebugTN("Verify compatibility");
	    dyn_string valDpes;
	    dyn_mixed  values;
	    int nVals=0;
	    for (int i=1;i<=dynlen(data);i++) {
		string valDpe=data[i][1];
		mixed value=data[i][2];
		dyn_string supportedConfigs=dpGetAllConfigs(valDpe);
    		if ( dynContains(supportedConfigs,"_online")) {
    		    nVals++;
		    valDpes[nVals]=valDpe;
		    values[nVals]=value; //dynAppend fails if value is of dyn_ type
    		}
	    }
	    DebugTN("Processing done, remaining big values",dynlen(valDpes));
	    if (dynlen(valDpes)) {
	    if (fwConfigurationDB_progress(fwConfigurationDB_OPER_LoadDevices,"Setting big values ["+nLoops+"]", 25.0, exceptionInfo,false)) {
	    	fwDbFinishCommand (dbCmdBig);
		return;
	    }

		DebugTN("Setting the big values now...");
    		fwConfigurationDB_dpSetManyDist(valDpes, values, exceptionInfo, false);
		if (dynlen(exceptionInfo)) return;
		DebugTN("Big Value set done");
	    }
	} while (rc==1);


    	//if (fwConfigurationDB_progress(fwConfigurationDB_OPER_LoadDeviceProperties,"Setting values", 43.0,exceptionInfo)) return;

	DebugTN("values set OK");

}


void _fwConfigurationDB_savePropValuesToDB(dyn_string dpeList, dyn_int dpeIdList,
	    dyn_string &exceptionInfo, bool storeIfAddrOut=true, bool storeIfAddrIn=true)
{
    DebugTN("Saving property values",dynlen(dpeList));

    string sql;
    dyn_dyn_mixed data;
    dyn_mixed params;
    dyn_errClass err;


DebugTN("... filtering only the ones that have _original");
    // process the list of dpes to select only the ones that could have a value
    for (int i=1;i<=dynlen(dpeList);i++) {
	string dpe=dpeList[i];
        dyn_string supportedConfigs=dpGetAllConfigs(dpe);
	if (!dynContains(supportedConfigs,"_original")) {
	    dynRemove(dpeList,i);
	    dynRemove(dpeIdList,i);
	    i--;
	}
    }
DebugTN("... filtering done",dynlen(dpeList));
    if (!dynlen(dpeList)) {
	DebugTN("No values to extract/save...");
	return;
    }
    
    // now check if we have more exclusions to do...
    if ( !storeIfAddrOut || !storeIfAddrIn) {
DebugTN("Filtering on addrIn,addOut",storeIfAddrIn,storeIfAddrOut);

	dyn_string dpeAddrDirs,dpeAddrTypes;
	dyn_int addrDirs,addrTypes,propIdIdx;
	// form a list of DPEs
	for (int i=1;i<=dynlen(dpeList);i++) {
	    //dynAppend(dpeAddrTypes,dpeList[i]+":_address.._type");
	    dynAppend(dpeAddrTypes,dpeList[i]+":_distrib.._type");
	}
DebugTN("getting addrTypes");
	dpGet(dpeAddrTypes,addrTypes);

  	err=getLastError();
	if (dynlen(err)) {
	    fwException_raise(exceptionInfo,"ERROR","Could not extract address types. See log for details","");
	    DebugTN("ERROR","Could not extract address types");
	    DebugTN(dpeAddrTypes);
	    DebugTN(err);
	    fwDbRollbackTransaction(g_fwConfigurationDB_DBConnection); 
	    return;
	}
DebugTN("Got them. Now we prepare DPEs to get directions");
	for (int i=1;i<=dynlen(dpeAddrTypes);i++) {
	    if (addrTypes[i]!=0) { // means we have an address
		dynAppend(dpeAddrDirs,dpeList[i]+":_address.._direction");
		dynAppend(propIdIdx, i);
	    }
	}
	
	if (dynlen(dpeAddrDirs)) {
DebugTN("getting address directions");
	    dpGet(dpeAddrDirs,addrDirs);	
	    err=getLastError();
    if (dynlen(err)) {
		fwException_raise(exceptionInfo,"ERROR","Could not extract address directions. See log for details","");
		DebugTN("ERROR","Could not extract address types");
		DebugTN(dpeAddrDirs);
		DebugTN(err);
		fwDbRollbackTransaction(g_fwConfigurationDB_DBConnection); 
		return;
	    }
    
  DebugTN("final filtering starts... on entry we have",dynlen(dpeList));	

	    //for (int i=1;i<=dynlen(dpeAddrDirs);i++) {
	    for (int i=dynlen(dpeAddrDirs);i>=1;i--) {
		int dir=addrDirs[i];
    //DebugTN(i,dpeList[propIdIdx[i]],dir);
		if (!storeIfAddrOut && (dir==1 || dir==5 || dir==6|| dir==7|| dir==8)) {

		    dynRemove(dpeList,propIdIdx[i]);
		    dynRemove(dpeIdList,propIdIdx[i]);     
     //DebugTN("removing this OUTAddr",propIdIdx[i]);
           continue;
		}
		if (!storeIfAddrIn && (dir==2 || dir==3 || dir==4 || dir==5 || dir==6|| dir==7|| dir==8)) {
		    dynRemove(dpeList,propIdIdx[i]);	    
		    dynRemove(dpeIdList,propIdIdx[i]);
       //DebugTN("removing this INAddr",propIdIdx[i]);        
		}
	    }
DebugTN("after final filtering done we have",dynlen(dpeList));	    
//DebugTN(dpeList);
	}
    }


    if (!dynlen(dpeList)) {
	DebugTN("No values to extract/save...");
	return;
    }


    // Note! It is safe to make a big dpGet. Tests show that performance
    // scales linearly with the number of dpes (at least up to 400k dpes,
    // which takes around 16 seconds on my SLC5 VBox
DebugTN("Getting values from PVSS...");
    dyn_mixed values;
    dpGet(dpeList,values);
    err=getLastError();
    if (dynlen(err)) {
	    fwException_raise(exceptionInfo,"ERROR","Could not extract values from PVSS. See log for details","");
	    DebugTN("ERROR","Could not extract address types");
	    DebugTN(dpeList);
	    DebugTN(err);
	    fwDbRollbackTransaction(g_fwConfigurationDB_DBConnection); 
	    return;
    }
DebugTN("Got values from PVSS",dynlen(values));    

    dyn_int idsSmall, idsBig;
    dyn_mixed valSmall, valBig;
    int nSmall=0;
    int nBig=0;
    for (int i=1;i<=dynlen(dpeList);i++) {
	// workaround for #86425: force "bit-pattern" type (24) to string...
	int vtype=getType(values[i]);
	if (vtype==BIT32_VAR || vtype==DPEL_BIT32) values[i]=(string)values[i];
	string s=values[i];
	if (strlen(s) < 32) { 
	    nSmall++;
	    idsSmall[nSmall]=dpeIdList[i]; 
	    valSmall[nSmall]=values[i]; // dynAppend does not work when value itself is of type dyn...
	} else { 
	    nBig++;
	    idsBig[nBig]=dpeIdList[i];
	    valBig[nBig]=values[i];
	}
    }

    sql="INSERT INTO CONFIG_VALUES(IPROP_ID,PVALUE) VALUES(:IPROP_ID,:PVALUE)";
    
    data[1]=idsSmall;
    data[2]=valSmall;
DebugTN("Executing",sql, "with "+dynlen(valSmall)+" values");
    _fwConfigurationDB_executeDBBulkCmd(sql,g_fwConfigurationDB_DBConnection,data, exceptionInfo,TRUE);
    if (dynlen(exceptionInfo)) { fwDbRollbackTransaction(g_fwConfigurationDB_DBConnection); return;}


    sql="INSERT INTO CONFIG_VALUES_BIG(IPROP_ID,CVALUE) VALUES(:IPROP_ID,:CVALUE)";
    data[1]=idsBig;
    data[2]=valBig;
DebugTN("Executing",sql, "with "+dynlen(valBig)+" values");
    _fwConfigurationDB_executeDBBulkCmd(sql,g_fwConfigurationDB_DBConnection,data, exceptionInfo,TRUE);

    if (dynlen(exceptionInfo)) { fwDbRollbackTransaction(g_fwConfigurationDB_DBConnection); return;}

    DebugTN("Finished saving property values");

}











/////////////////////////////



void _fwConfigurationDB_loadApplyAddresses(dyn_string &exceptionInfo)
{
    if (fwConfigurationDB_progress(fwConfigurationDB_OPER_LoadDeviceProperties,"Loading addresses", 55.0,
                                   exceptionInfo)) return;

    DebugTN("loading/applying address configs...");

    string sql = "SELECT CA.TYPE, CA.DRIVER, NULL REF, CA.DIRECTION, CA.DATATYPE, CA.ACTIVE, CA.OPTIONS, TIP.DPENAME "+
                 " FROM CONFIG_ADDRESSES CA, TMP_ITEM_PROPS TIP "+
                 " where CA.iprop_id =TIP.iprop_id";

    dyn_int colTypes=makeDynInt(DPEL_STRING,DPEL_INT,DPEL_STRING,DPEL_INT,DPEL_INT,DPEL_INT,DPEL_DYN_STRING);
    DebugTN("Executing",sql);
    dbCommand dbCmd;
    
    fwConfigurationDB_initializeQuery( sql, g_fwConfigurationDB_DBConnection, dbCmd, exceptionInfo);
    if (dynlen(exceptionInfo)) return;
    DebugTN("query executed, processing data by chunks now...");

    int rc=0;
    int maxRecords=10000;
    int nLoops=0;
    do {
	nLoops++;
	dyn_dyn_mixed data;
	if (fwConfigurationDB_progress(fwConfigurationDB_OPER_LoadDevices,"Loading addresses ["+nLoops+"]", 40.0, exceptionInfo,false)) {
	    fwDbFinishCommand (dbCmd);
	    return;
	}
	
	rc=fwConfigurationDB_fetchQuery(dbCmd, data,exceptionInfo, maxRecords, FALSE ,TRUE, colTypes,8);
	if (dynlen(exceptionInfo)) return;
	    
	DebugTN("Fetched a chunk",dynlen(data));
	DebugTN("Processing...");
	dyn_string dpes;
	if (fwConfigurationDB_progress(fwConfigurationDB_OPER_LoadDevices,"Processing addresses ["+nLoops+"]", 30.0, exceptionInfo,false)) {
	    fwDbFinishCommand (dbCmd);
	    return;
	}
	
	// note ! We take advantage of the fact that the layout of addrCfgParams matches the layout of queried data,
	// ie. indices are (fwPeriphAddress_TYPE=1, fwPeriphAddress_DRIVER_NUMBER=2, fwPeriphAddress_REFERENCE=3,
	//                  fwPeriphAddress_DIRECTION=4, fwPeriphAddress_DATATYPE=5, fwPeriphAddress_ACTIVE=6
	// and then the options start at FW_PARAMETER_FIELD_LOWLEVEL      = 11

	for ( int i=1;i<=dynlen(data);i++) {
	    dynAppend(dpes,data[i][8]);
	    dyn_mixed options=data[i][7];
	    data[i][fwPeriphAddress_REFERENCE]=options[1];
	    // append remaining options
	    for (int j=2;j<=dynlen(options);j++) data[i][9+j]=options[j];
      // workaround for DIP: remove the system name from fwPeriphAddress_DIP_CONFIG_DP
      if (data[i][fwPeriphAddress_TYPE]==fwPeriphAddress_TYPE_DIP) {
        string confDP=data[i][fwPeriphAddress_DIP_CONFIG_DP];
        // eliminate the bug with system name
        if (strpos(confDP,":")>0){ 
          // eliminate old system name
          dyn_string ds=strsplit(confDP,":");
          confDP=ds[2];
        }
        // and add own system name
        data[i][fwPeriphAddress_DIP_CONFIG_DP]=getSystemName()+confDP;
        // eliminate the fallout of ENS-3763 ENS-4987
        if (strpos(confDP,".")>0){ 
          // take only the datapoint - strip the element name
          dyn_string ds=strsplit(confDP,".");
          confDP=ds[1];
        }        
      }
	}
	//DebugTN("Data",data);
	if (dynlen(dpes)) {
	    bool runDriverCheck=TRUE;
	    DebugTN("Calling fwPeriphAddress_setMany");
	    if (fwConfigurationDB_progress(fwConfigurationDB_OPER_LoadDevices,"Setting addresses ["+nLoops+"]", 40.0, exceptionInfo,false)) {
		fwDbFinishCommand (dbCmd);
		return;
	    }
	    fwPeriphAddress_setMany(dpes, data, exceptionInfo,runDriverCheck);
	    if (dynlen(exceptionInfo)) return;
    	    DebugTN("Configured a bunch of "+dynlen(dpes)+" addresses");
    	}
    } while (rc==1);
    
    DebugTN("Address configuration done");
}


/** Extracts addressing configuration from PVSS and save to DB
 *
 * @param dpes      list of the data point element names for which configuration is requested
 * @param ipropIds  corresponding list of IPROP_ID identifiers (in the database) of the data-point elements
 *
 * we assume that the configuration was already created, and ipropIds are valid
 */
void _fwConfigurationDB_savePropAddressToDB(dyn_string dpes,dyn_int ipropIds, dyn_string &exceptionInfo)
{

    string sql="INSERT INTO CONFIG_ADDRESSES (IPROP_ID, TYPE, DRIVER, DIRECTION, DATATYPE, ACTIVE, OPTIONS ) "+
        " VALUES (:IPROP_ID, :TYPE, :DRIVER, :DIRECTION, :DATATYPE, :ACTIVE, :OPTIONS)";

    dyn_dyn_mixed addressingData;
    int nAddrData=0;


    dyn_bool configExists, isActive;
    dyn_dyn_anytype addrCfg;
    DebugTN("We extract addressing parameters");
    fwPeriphAddress_getMany(dpes, configExists, addrCfg, isActive, exceptionInfo);
    if (dynlen(exceptionInfo)) { fwDbRollbackTransaction(g_fwConfigurationDB_DBConnection); return;}
    DebugTN("We got addressing parameters", dynlen(addrCfg));

    
    dyn_dyn_mixed addressingData;

    for (int i=1;i<=dynlen(addrCfg);i++) {        
        if (configExists[i]) {
    	    int pos=dynlen(addressingData)+1;
            addressingData[pos][1] = ipropIds[i];
            addressingData[pos][2] = addrCfg[i][fwPeriphAddress_TYPE];
            addressingData[pos][3] = addrCfg[i][fwPeriphAddress_DRIVER_NUMBER];
            addressingData[pos][4] = addrCfg[i][fwPeriphAddress_DIRECTION];
            addressingData[pos][5] = addrCfg[i][fwPeriphAddress_DATATYPE];
            addressingData[pos][6] = addrCfg[i][fwPeriphAddress_ACTIVE];

          // workaround for ENS-3763 , ENS-4897
          if (addrCfg[i][fwPeriphAddress_TYPE]==fwPeriphAddress_TYPE_DIP) {
            string confDP=addrCfg[i][fwPeriphAddress_DIP_CONFIG_DP];
            addrCfg[i][fwPeriphAddress_DIP_CONFIG_DP]=dpSubStr(confDP,DPSUB_DP);
          }
    
            
    	    dyn_string options=makeDynString((string)addrCfg[i][fwPeriphAddress_REFERENCE]); // we store this at the beginning of options!
    	    for (int j=FW_PARAMETER_FIELD_LOWLEVEL;j<=dynlen(addrCfg[i]);j++) dynAppend(options,(string)addrCfg[i][j]);
          
         addressingData[pos][7] = options;
        }
        
    }

    DebugTN("Executing",sql, "with "+dynlen(addressingData)+" values");
    _fwConfigurationDB_executeDBBulkCmd(sql,g_fwConfigurationDB_DBConnection,addressingData, exceptionInfo);
    if (dynlen(exceptionInfo)) { fwDbRollbackTransaction(g_fwConfigurationDB_DBConnection); return;}
    DebugTN("Saving of addresses DONE");
}


///////////////







/** Extracts alert configuration from PVSS and save to DB
 *
 * @param dpes      list of the data point element names for which configuration is requested
 * @param ipropIds  corresponding list of IPROP_ID identifiers (in the database) of the data-point elements
 *
 * we assume that the configuration was already created, and ipropIds are valid
 */
void _fwConfigurationDB_savePropAlertsToDB(dyn_string dpes,dyn_int ipropIds, dyn_string &exceptionInfo)
{

    if (!mappingHasKey(g_fwConfigurationDB_stats,"ALERTS/#All")) 		g_fwConfigurationDB_stats["ALERTS/#All"]=0;
    if (!mappingHasKey(g_fwConfigurationDB_stats,"ALERTS/#Sum")) 	g_fwConfigurationDB_stats["ALERTS/#Sum"]=0;
    if (!mappingHasKey(g_fwConfigurationDB_stats,"ALERTS/#Dpe")) 	g_fwConfigurationDB_stats["ALERTS/#Dpe"]=0;
    if (!mappingHasKey(g_fwConfigurationDB_stats,"ALERTS/#Misc")) 	g_fwConfigurationDB_stats["ALERTS/#Misc"]=0;
    if (!mappingHasKey(g_fwConfigurationDB_stats,"ALERTS/T Extract"))   g_fwConfigurationDB_stats["ALERTS/T Extract"]=0.0;
    if (!mappingHasKey(g_fwConfigurationDB_stats,"ALERTS/T Process"))   g_fwConfigurationDB_stats["ALERTS/T Process"]=0.0;
    if (!mappingHasKey(g_fwConfigurationDB_stats,"ALERTS/T Save")) 	g_fwConfigurationDB_stats["ALERTS/T Save"]=0.0;

    DebugTN("SavePropAlertsToDB start");
    dyn_dyn_mixed alertObjectList;
    time t1=getCurrentTime();
    fwAlertConfig_objectGetMany(dpes, alertObjectList, exceptionInfo);
    time t2=getCurrentTime();    
    time dt=t2-t1;
    g_fwConfigurationDB_stats["ALERTS/T Extract"]+=(float)period(dt)+0.001*milliSecond(dt);
    
    if (dynlen(exceptionInfo)) {fwDbRollbackTransaction(g_fwConfigurationDB_DBConnection); return;}
    DebugTN("Got alerts configuration",dynlen(alertObjectList));
//DebugTN(dpes,alertObjectList);    


    t1=getCurrentTime();

        string sqlAlert="INSERT INTO CONFIG_ALERTS (IPROP_ID, TYPE, ACTIVE, DISCRETE, IMPULSE) "+
            " VALUES (:IPROP_ID, :TYPE, :ACTIVE, :DISCRETE, :IMPULSE)";
        string sqlAlertDpe="INSERT INTO CONFIG_DPEALERTS (IPROP_ID, TEXTS, LIMITS, CLASSES, INCLUSIVE, NEGATED) "+
            " VALUES (:IPROP_ID, :TEXTS, :LIMITS, :CLASSES, :INCLUSIVE, :NEGATED)";


	// to insert the list of DPEs, store them in expanded way in CDB_API_PARAMS, then call the MERGE function:
	// I1 -> IPROPID
	// S2 -> Included alarm dpe
        string sqlAlertSum1="INSERT INTO CONFIG_SUMALERTS (IPROP_ID, TEXTS, CLASS, THRESHOLD) "+
            " VALUES (:IPROP_ID, :TEXTS, :CLASS, :THRESHOLD)";
        string sqlAlertSumClean="DELETE FROM CDB_API_PARAMS";
        string sqlAlertSum2="INSERT INTO CDB_API_PARAMS (I1, S2) VALUES (:IPROP_ID, :SUMDPENAME)";
        string sqlAlertSum3="MERGE INTO CONFIG_SUMALERTS CSA USING "+
    			    "  (SELECT c1.i1 IPROP_ID, LSTAGGNUM(tip.iprop_id) SUMDPELIST "+
    			    "      FROM CDB_API_PARAMS c1, TMP_ITEM_PROPS tip "+
    			    "      WHERE tip.DPENAME=c1.s2 "+
    			    "      GROUP BY c1.i1) TRA "+
    			    " ON (CSA.IPROP_ID=TRA.IPROP_ID) "+
    			    " WHEN MATCHED THEN "+
    			    "   UPDATE SET csa.sumdpelist=tra.sumdpelist";

        string sqlAlertMisc="INSERT INTO CONFIG_ALERTS_MISC (IPROP_ID,PANEL, PANELPARAMS, HELP, STATEBITS, LIMITSSTATEBITS, TEXTSWENT ) "+
            " VALUES (:IPROP_ID, :PANEL, :PPARAMS, :HELP, :STATEBITS, :LIMITSSTATEBITS,: TEXTSWENT)";
    
    dyn_dyn_mixed alertData, alertDpeData, alertSumData,alertSumDpeData,alertMiscData;

    for (int i=1;i<=dynlen(dpes);i++) {    
	dyn_mixed alarmObject=alertObjectList[i];
	dyn_dyn_mixed alarmLimits=alarmObject[fwAlertConfig_ALERT_LIMIT];
	dyn_dyn_mixed alarmParams=alarmObject[fwAlertConfig_ALERT_PARAM];
	

	//DebugTN("Processing alarm for ",dpes[i], "type",alarmParams[fwAlertConfig_ALERT_PARAM_TYPE][1]);
	
	if (alarmParams[fwAlertConfig_ALERT_PARAM_TYPE][1]==0) continue;
	
	int pos=dynlen(alertData)+1;
	alertData[pos][1] = ipropIds[i];
	alertData[pos][2] = (int)alarmParams[fwAlertConfig_ALERT_PARAM_TYPE][1];
	alertData[pos][3] = (int)alarmParams[fwAlertConfig_ALERT_PARAM_ACTIVE][1];
	alertData[pos][4] = (int)alarmParams[fwAlertConfig_ALERT_PARAM_DISCRETE][1];
	alertData[pos][5] = (int)alarmParams[fwAlertConfig_ALERT_PARAM_IMPULSE][1];
	
	if (alarmParams[fwAlertConfig_ALERT_PARAM_TYPE][1]==DPCONFIG_SUM_ALERT) {

	    dyn_string sumdpes=alarmParams[fwAlertConfig_ALERT_PARAM_SUM_DPE_LIST];
	    if (dynlen(sumdpes)==1 && (strpos(sumdpes[1],"*")>=0 || strpos(sumdpes[1],"?")>=0) ) {
	    	int pos=dynlen(alertSumDpeData)+1;
		alertSumDpeData[pos][1]=ipropIds[i];
		alertSumDpeData[pos][2]="PATTERN:"+sumdpes[1];
	    } else {

		for (int j=1;j<=dynlen(sumdpes);j++) {
	    	    int pos=dynlen(alertSumDpeData)+1;
		    alertSumDpeData[pos][1]=ipropIds[i];
		    alertSumDpeData[pos][2]=sumdpes[j];
		}
		
	    }
	    dyn_string classes, texts;
	    int nclasses;
	    for (int j=1;j<=dynlen(alarmLimits);j++) {
//DebugTN("SUMALERT ON "+dpes[i],ipropIds[i],j,alarmLimits[j][fwAlertConfig_ALERT_LIMIT_CLASS],(string)alarmLimits[j][fwAlertConfig_ALERT_LIMIT_TEXT]);
		// alert class should be stored without system name
		string alClass=dpSubStr(alarmLimits[j][fwAlertConfig_ALERT_LIMIT_CLASS],DPSUB_DP_EL);
		dynAppend(classes,alClass);
		if (alClass!="") nclasses++;
		dynAppend(texts,alarmLimits[j][fwAlertConfig_ALERT_LIMIT_TEXT]);
	    }
	    if (nclasses==0) dynClear(classes);
	    int pos=dynlen(alertSumData)+1;
	    alertSumData[pos][1] = ipropIds[i];
	    alertSumData[pos][2]=texts;
	    alertSumData[pos][3]=classes;
	    alertSumData[pos][4]=alarmParams[fwAlertConfig_ALERT_PARAM_SUM_THRESHOLD][1];
	} else {

	    dyn_string classes,texts,limits;
	    dyn_bool included,negated;
	    bool isDiscrete=alarmParams[fwAlertConfig_ALERT_PARAM_DISCRETE][1];

	    int numIncluded=0; // we count them to do "zero-suppression"
	    int numNegated=0;
	    for (int j=1;j<=dynlen(alarmLimits);j++) {
		dynAppend(texts,alarmLimits[j][fwAlertConfig_ALERT_LIMIT_TEXT]);

		// alert class should be stored without system name
		dynAppend(classes,dpSubStr(alarmLimits[j][fwAlertConfig_ALERT_LIMIT_CLASS],DPSUB_DP_EL));
		if (isDiscrete) {
		    dynAppend(limits,alarmLimits[j][fwAlertConfig_ALERT_LIMIT_VALUE_MATCH]);
		    int neg=(int)alarmLimits[j][fwAlertConfig_ALERT_LIMIT_NEGATION];
		    dynAppend(negated,neg);
		    if (neg) numNegated++;
		} else {
		    // note! For analog alarms, we should skip the value passed in the first index!
		    // for digital ones, we would not even need to save them!
		    if (alarmParams[fwAlertConfig_ALERT_PARAM_TYPE][1]==DPCONFIG_ALERT_BINARYSIGNAL) continue;
		    if (j>1) { 
			dynAppend(limits,alarmLimits[j][fwAlertConfig_ALERT_LIMIT_VALUE]);
			int incl=(int)alarmLimits[j][fwAlertConfig_ALERT_LIMIT_VALUE_INCLUDED];
			dynAppend(included,incl);
			if (incl) numIncluded++;
		    }
		}
	    }
	    if (numIncluded==0) dynClear(included);
	    if (numNegated==0) dynClear(negated);
	    int pos=dynlen(alertDpeData)+1;
	    alertDpeData[pos][1] = ipropIds[i];
	    alertDpeData[pos][2] = texts;
	    alertDpeData[pos][3] = limits;
	    alertDpeData[pos][4] = classes;
	    alertDpeData[pos][5] = included;
	    alertDpeData[pos][6] = negated;
	}
	
	// now treat the additional data
	string panel	       = alarmParams[fwAlertConfig_ALERT_PARAM_PANEL][1];
	dyn_string panelParams = alarmParams[fwAlertConfig_ALERT_PARAM_PANEL_PARAMETERS];
	string help            = alarmParams[fwAlertConfig_ALERT_PARAM_HELP][1];
	string stateBits       = alarmLimits[1][fwAlertConfig_ALERT_LIMIT_STATE_BITS]; // note! It is really a single parameter, not per-limit!


	
	dyn_string limitsStateBits,textsWent;
	int nTextsWent=0;;
	int nLimStateBits=0;
	for (int j=1;j<=dynlen(alarmLimits);j++) {
	    dynAppend(limitsStateBits,alarmLimits[j][fwAlertConfig_ALERT_LIMIT_STATE_BITS]);
	    dynAppend(textsWent,alarmLimits[j][fwAlertConfig_ALERT_LIMIT_TEXT_WENT]);
	    if (alarmLimits[j][fwAlertConfig_ALERT_LIMIT_STATE_BITS]!="") nLimStateBits++;
	    if (alarmLimits[j][fwAlertConfig_ALERT_LIMIT_TEXT_WENT]!="") nTextsWent++;
	}
	if (nLimStateBits==0) dynClear(limitsStateBits);
	if (nTextsWent==0)    dynClear(textsWent);
	if (panel!="" || dynlen(panelParams) || help!="" || stateBits!="" || nTextsWent || nLimStateBits ) {
	    int pos=dynlen(alertMiscData)+1;
	    alertMiscData[pos][1] = ipropIds[i];
	    alertMiscData[pos][2] = panel;
	    alertMiscData[pos][3] = panelParams; 
	    alertMiscData[pos][4] = help;
	    alertMiscData[pos][5] = stateBits;
	    alertMiscData[pos][6] = limitsStateBits;
	    alertMiscData[pos][7] = textsWent;
	}
	
    }

    g_fwConfigurationDB_stats["ALERTS/#All"]+=dynlen(alertData);
    g_fwConfigurationDB_stats["ALERTS/#Dpe"]+=dynlen(alertDpeData);
    g_fwConfigurationDB_stats["ALERTS/#Sum"]+=dynlen(alertSumData);
    g_fwConfigurationDB_stats["ALERTS/#Sum"]+=dynlen(alertMiscData);
    
    
    t2=getCurrentTime();    
    dt=t2-t1;
    g_fwConfigurationDB_stats["ALERTS/T Process"]+=(float)period(dt)+0.001*milliSecond(dt);


    t1=getCurrentTime();    
        
    DebugTN("Executing",sqlAlert, "with "+dynlen(alertData)+" values");
//    DebugTN(alertData);
    _fwConfigurationDB_executeDBBulkCmd(sqlAlert,g_fwConfigurationDB_DBConnection,alertData, exceptionInfo);
    if (dynlen(exceptionInfo)) { fwDbRollbackTransaction(g_fwConfigurationDB_DBConnection); return;}


    DebugTN("Executing",sqlAlertDpe, "with "+dynlen(alertDpeData)+" values");
    _fwConfigurationDB_executeDBBulkCmd(sqlAlertDpe,g_fwConfigurationDB_DBConnection,alertDpeData, exceptionInfo);
    if (dynlen(exceptionInfo)) { fwDbRollbackTransaction(g_fwConfigurationDB_DBConnection); return;}

    DebugTN("Executing cleanup",sqlAlertSumClean);
    fwConfigurationDB_executeSqlSimple(sqlAlertSumClean, g_fwConfigurationDB_DBConnection,exceptionInfo);
    if (dynlen(exceptionInfo)) {fwDbRollbackTransaction(g_fwConfigurationDB_DBConnection);return;}

    DebugTN("Executing",sqlAlertSum1, "with "+dynlen(alertSumData)+" values");
    _fwConfigurationDB_executeDBBulkCmd(sqlAlertSum1,g_fwConfigurationDB_DBConnection,alertSumData, exceptionInfo);
    if (dynlen(exceptionInfo)) { fwDbRollbackTransaction(g_fwConfigurationDB_DBConnection); return;}

    DebugTN("Executing",sqlAlertSum2, "with "+dynlen(alertSumDpeData)+" values");
    _fwConfigurationDB_executeDBBulkCmd(sqlAlertSum2,g_fwConfigurationDB_DBConnection,alertSumDpeData, exceptionInfo);
    if (dynlen(exceptionInfo)) { fwDbRollbackTransaction(g_fwConfigurationDB_DBConnection); return;}


    DebugTN("Executing",sqlAlertSum3);
    fwConfigurationDB_executeSqlSimple(sqlAlertSum3, g_fwConfigurationDB_DBConnection,exceptionInfo);
    if (dynlen(exceptionInfo)) {fwDbRollbackTransaction(g_fwConfigurationDB_DBConnection);return;}

//    _fwConfigurationDB_showItemsInCDB_API_PARAMS("CDB API PARAMS");
//    _fwConfigurationDB_queryPrint("SELECT count(*) FROM TMP_ITEM_PROPS");
//    string sqlDbg="SELECT c1.i1 IPROP_ID, LSTAGGNUM(tip.iprop_id) SUMDPELIST "+
//    			    "      FROM CDB_API_PARAMS c1, TMP_ITEM_PROPS tip "+
//    			    "      WHERE tip.DPENAME=c1.s2 "+
//    			    "      GROUP BY c1.i1 ";
//    _fwConfigurationDB_queryPrint(sqlDbg);
//    _fwConfigurationDB_queryPrint("SELECT * FROM CONFIG_SUMALERTS WHERE IPROP_ID IN(SELECT IPROP_ID FROM TMP_ITEM_PROPS)","",20);
    
    DebugTN("Executing cleanup",sqlAlertSumClean);
    fwConfigurationDB_executeSqlSimple(sqlAlertSumClean, g_fwConfigurationDB_DBConnection,exceptionInfo);
    if (dynlen(exceptionInfo)) {fwDbRollbackTransaction(g_fwConfigurationDB_DBConnection);return;}


    DebugTN("Executing",sqlAlertMisc, "with "+dynlen(alertMiscData)+" values");
    _fwConfigurationDB_executeDBBulkCmd(sqlAlertMisc,g_fwConfigurationDB_DBConnection,alertMiscData, exceptionInfo);
    if (dynlen(exceptionInfo)) { fwDbRollbackTransaction(g_fwConfigurationDB_DBConnection); return;}


    t2=getCurrentTime();    
    dt=t2-t1;
    g_fwConfigurationDB_stats["ALERTS/T Save"]+=(float)period(dt)+0.001*milliSecond(dt);


   DebugTN("Alerts saving DONE");

}


void _fwConfigurationDB_loadApplyAlerts(dyn_string &exceptionInfo)
{
	dyn_dyn_mixed configurationData;
        if (fwConfigurationDB_progress(fwConfigurationDB_OPER_LoadDeviceProperties,"Loading alerts", 45.0,
                                   exceptionInfo)) return;

/////////////////////
	string sql ="SELECT TIP.DPENAME,  "+ 	//[1]
	            "       TIP.IPROP_ID, "+ 	//[2]
	            "       CA.TYPE,      "+ 	//[3]
	            "       CA.ACTIVE,    "+ 	//[4]
	            "       CADPE.TEXTS,  "+ 	//[5]
	            "       CADPE.LIMITS, "+ 	//[6]
	            "       CADPE.CLASSES,"+ 	//[7]
	            "       NULL SUMDPELIST,"+ 	//[8]
	            "       CAMISC.PANEL,  "+ 	//[9]
	            "       CAMISC.PANELPARAMS,"+	//[10]
	            "       CAMISC.HELP,   "+	//[11]
	            "       CA.DISCRETE,   "+	//[12]
	            "       CA.IMPULSE,    "+	//[13]
	            "       CADPE.INCLUSIVE,"+	//[14]
	            "       CADPE.NEGATED, "+	//[15]
	            "       NULL THRESHOLD,  "+	//[16]
	            "       CAMISC.STATEBITS,"+	//[17]
	            "       CAMISC.LIMITSSTATEBITS, "+	//[18]
	            "       CAMISC.TEXTSWENT"+	//[19]
	           " FROM CONFIG_ALERTS CA, TMP_ITEM_PROPS TIP, CONFIG_DPEALERTS CADPE, CONFIG_ALERTS_MISC CAMISC "+
	           " WHERE  CA.IPROP_ID=TIP.IPROP_ID "+
	           " AND CADPE.IPROP_ID=CA.IPROP_ID  "+
	           " AND CAMISC.IPROP_ID(+)=CA.IPROP_ID ";

	dyn_int colTypes=makeDynInt(0,		//DPENAME
				0,		//IPROP_ID
				DPEL_INT,	//TYPE
				DPEL_INT,	//ACTIVE
				DPEL_DYN_STRING,//TEXTS
				DPEL_DYN_STRING, //LIMITS
				DPEL_DYN_STRING,//CLASSES
				DPEL_DYN_STRING,//SUMDPELIST
				DPEL_STRING,	//PANEL
				DPEL_DYN_STRING,//PANELPARAMS
				DPEL_STRING,	//HELP
				DPEL_BOOL,	//DISCRETE
				DPEL_BOOL,	//IMPULSE
				DPEL_DYN_BOOL,	//INCLUSIVE
				DPEL_DYN_BOOL,	//NEGATED
				DPEL_INT,	//THRESHOLD for summary alarms
				DPEL_STRING,	//STATEBITS
				DPEL_DYN_STRING,//STATEBITS OF LIMITS
				DPEL_DYN_STRING //TEXTS WENT
				);
	DebugTN("Executing",sql);
	_fwConfigurationDB_executeDBQuery(sql, g_fwConfigurationDB_DBConnection,configurationData,exceptionInfo,19,TRUE,colTypes);
	if (dynlen(exceptionInfo)) return;
	DebugTN("Got alerts from DB");
//	DebugTN(configurationData[1],configurationData[2],configurationData[8]);
	if (dynlen(configurationData) && dynlen(configurationData[1])) {
	    DebugTN("Reformatting the data",dynlen(configurationData[1]));
	    dyn_dyn_mixed alarmObjectList;
	    dyn_string alertDpes=configurationData[1];
	    dyn_int alertIpropIds=configurationData[2];

	    for (int i=1;i<=dynlen(alertDpes);i++) {
		dyn_mixed alarmObject;
		dyn_dyn_mixed alarmLimits;
		dyn_dyn_mixed alarmParams;
		dyn_mixed alarmTexts=configurationData[5][i];
		dyn_mixed alarmThresholds=configurationData[6][i];
		dyn_mixed alarmClasses=configurationData[7][i];
		dyn_mixed valuesIncluded=configurationData[14][i];
		dyn_mixed negated=configurationData[15][i];
		dyn_mixed limitsStateBits=configurationData[18][i];
		dyn_mixed wentTexts=configurationData[19][i];
		    
		int totalRanges=dynlen(alarmTexts);
		// initialize first elements of limiting values to dummy values
		mixed dummy;
		alarmLimits[1][fwAlertConfig_ALERT_LIMIT_VALUE]=dummy;
		// process the ranges
		for (int j=1;j<=totalRanges;j++) {
		    alarmLimits[j][fwAlertConfig_ALERT_LIMIT_TEXT] = alarmTexts[j];
		    if (configurationData[12][i]) {
			// discrete alarms
			alarmLimits[j][fwAlertConfig_ALERT_LIMIT_VALUE_MATCH] = alarmThresholds[j];
			alarmLimits[j][fwAlertConfig_ALERT_LIMIT_VALUE] = dummy;
		    } else {
			// analog or digital alarm, with ranges...; 
			// note that the first index is dummy (numThresholds==numRanges-1)
			if (j<totalRanges && j<=dynlen(alarmThresholds)) {
			    alarmLimits[j+1][fwAlertConfig_ALERT_LIMIT_VALUE_MATCH] = dummy;
			    alarmLimits[j+1][fwAlertConfig_ALERT_LIMIT_VALUE] = alarmThresholds[j];
			    if (dynlen(valuesIncluded)) { 
				alarmLimits[j+1][fwAlertConfig_ALERT_LIMIT_VALUE_INCLUDED] = valuesIncluded[j];
			    } else { 
				alarmLimits[j+1][fwAlertConfig_ALERT_LIMIT_VALUE_INCLUDED]=FALSE;
			    }
			}
		    }
		    if (dynlen(alarmClasses)) {
			alarmLimits[j][fwAlertConfig_ALERT_LIMIT_CLASS] = dpSubStr(alarmClasses[j],DPSUB_DP_EL);
		    } else {
			alarmLimits[j][fwAlertConfig_ALERT_LIMIT_CLASS] = "";			
		    }

		    if (dynlen(negated)) { 
			alarmLimits[j][fwAlertConfig_ALERT_LIMIT_NEGATION] = negated[j];
		    } else {
			alarmLimits[j][fwAlertConfig_ALERT_LIMIT_NEGATION]=FALSE;
		    }

		    alarmLimits[j][fwAlertConfig_ALERT_LIMIT_STATE_BITS] = configurationData[17][i];

		    if (dynlen(limitsStateBits)) {
			alarmLimits[j][fwAlertConfig_ALERT_LIMIT_LIMITS_STATE_BITS] = limitsStateBits[j];
		    } else {
			alarmLimits[j][fwAlertConfig_ALERT_LIMIT_LIMITS_STATE_BITS] = "";
		    }
		    if (dynlen(wentTexts)) {
			alarmLimits[j][fwAlertConfig_ALERT_LIMIT_TEXT_WENT] = wentTexts[j];
		    } else {
			alarmLimits[j][fwAlertConfig_ALERT_LIMIT_TEXT_WENT] = "";
		    }

		}

		alarmParams[fwAlertConfig_ALERT_PARAM_TYPE][1]      = configurationData[3][i];
		alarmParams[fwAlertConfig_ALERT_PARAM_SUM_DPE_LIST] = configurationData[8][i];
		alarmParams[fwAlertConfig_ALERT_PARAM_SUM_THRESHOLD][1] = configurationData[16][i];
		alarmParams[fwAlertConfig_ALERT_PARAM_ADD_DPE_TO_SUMMARY][1] = "";
		alarmParams[fwAlertConfig_ALERT_PARAM_PANEL][1] = configurationData[9][i];
    		alarmParams[fwAlertConfig_ALERT_PARAM_PANEL_PARAMETERS] = configurationData[10][i];
    		alarmParams[fwAlertConfig_ALERT_PARAM_HELP][1] =          configurationData[11][i];
        	alarmParams[fwAlertConfig_ALERT_PARAM_DISCRETE][1] = configurationData[12][i];
        	alarmParams[fwAlertConfig_ALERT_PARAM_IMPULSE][1] = configurationData[13][i];
            	alarmParams[fwAlertConfig_ALERT_PARAM_MODIFY_ONLY][1] = FALSE;
            	alarmParams[fwAlertConfig_ALERT_PARAM_FALLBACK_TO_SET][1] = FALSE;
                alarmParams[fwAlertConfig_ALERT_PARAM_STORE_IN_HISTORY][1] = TRUE;
                alarmParams[fwAlertConfig_ALERT_PARAM_RANGES][1] = totalRanges;
                alarmParams[fwAlertConfig_ALERT_PARAM_ACTIVE][1] = configurationData[4][i];

    		    
		alarmObject[fwAlertConfig_ALERT_LIMIT]=alarmLimits;
		alarmObject[fwAlertConfig_ALERT_PARAM]=alarmParams;
		alarmObjectList[i]=alarmObject;
	    }
//DebugTN("AlertDPES",alertDpes);
//DebugTN(alarmObjectList);
	    if (dynlen(alertDpes)) {
		DebugTN("Done. Setting the alerts now",dynlen(alertDpes),dynlen(alarmObjectList));
		fwAlertConfig_objectSetMany(alertDpes, alarmObjectList, exceptionInfo);
		if (dynlen(exceptionInfo)) return;
		DebugTN("DONE!");
	    }
	}

/////////
        // now activate/deactivate the alerts;
        dyn_string dpesToActivate, dpesToDeactivate;
        if (dynlen(configurationData)) {
    	    for (int i=1;i<=dynlen(configurationData[4]);i++) {
    		string dpe=configurationData[1][i];
    		if (configurationData[4][i] > 0) {
    		    dynAppend(dpesToActivate,dpe);
    		} else {
    		    dynAppend(dpesToDeactivate,dpe);
    		}
    	    }
    	    bool acknowledge = TRUE;
    	    bool checkIfExists = FALSE;
    	    bool storeInParamHistory = TRUE;
    	    if (dynlen(dpesToActivate))   fwAlertConfig_activateMultiple  (dpesToActivate,   exceptionInfo, acknowledge, checkIfExists, storeInParamHistory);
    	    if (dynlen(dpesToDeactivate)) fwAlertConfig_deactivateMultiple(dpesToDeactivate, exceptionInfo, acknowledge, checkIfExists, storeInParamHistory);
    	    if (dynlen(exceptionInfo)) return;
    	}
        DebugN("Activated "+dynlen(dpesToActivate)+", deactivated "+dynlen(dpesToDeactivate)+" alerts");
}

void _fwConfigurationDB_loadApplySumAlerts(dyn_string &exceptionInfo)
{
	dyn_dyn_mixed configurationData;
        dyn_dyn_mixed sumAlertsConfigurationData, sumAlertsByPatternConfigurationData;
        if (fwConfigurationDB_progress(fwConfigurationDB_OPER_LoadDeviceProperties,"Loading alerts", 45.0,
                                   exceptionInfo)) return;

/////////////////////
	string sql ="SELECT TIP.DPENAME,  "+ 	//[1]
	            "       TIP.IPROP_ID, "+ 	//[2]
	            "       CA.TYPE,      "+ 	//[3]
	            "       CA.ACTIVE,    "+ 	//[4]
	            "       CASUM.TEXTS,  "+ 	//[5]
	            "       NULL LIMITS, "+ 	//[6]
	            "       CASUM.CLASS,"+ 	//[7]
	            "       ASUM.SUMDPELIST,"+ 	//[8]
	            "       CAMISC.PANEL,  "+ 	//[9]
	            "       CAMISC.PANELPARAMS,"+	//[10]
	            "       CAMISC.HELP,   "+	//[11]
	            "       CA.DISCRETE,   "+	//[12]
	            "       CA.IMPULSE,    "+	//[13]
	            "       NULL INCLUSIVE,"+	//[14]
	            "       NULL NEGATED, "+	//[15]
	            "       CASUM.THRESHOLD,  "+	//[16]
	            "       CAMISC.STATEBITS,"+	//[17]
	            "       CAMISC.LIMITSSTATEBITS, "+	//[18]
	            "       CAMISC.TEXTSWENT"+	//[19]
	           " FROM CONFIG_ALERTS CA, TMP_ITEM_PROPS TIP, CONFIG_SUMALERTS CASUM, "+
	           " TABLE(fwConfigurationDB.getSummaryAlerts) ASUM, CONFIG_ALERTS_MISC CAMISC "+
	           " WHERE  CA.IPROP_ID=TIP.IPROP_ID "+
	           " AND CASUM.IPROP_ID=CA.IPROP_ID  "+
	           " AND  ASUM.IPROP_ID=CA.IPROP_ID  "+
	           " AND CAMISC.IPROP_ID(+)=CA.IPROP_ID ";

	dyn_int colTypes=makeDynInt(0,		//DPENAME
				0,		//IPROP_ID
				DPEL_INT,	//TYPE
				DPEL_INT,	//ACTIVE
				DPEL_DYN_STRING,//TEXTS
				DPEL_DYN_STRING, //LIMITS
				DPEL_DYN_STRING,//CLASSES
				DPEL_DYN_STRING,//SUMDPELIST
				DPEL_STRING,	//PANEL
				DPEL_DYN_STRING,//PANELPARAMS
				DPEL_STRING,	//HELP
				DPEL_BOOL,	//DISCRETE
				DPEL_BOOL,	//IMPULSE
				DPEL_DYN_BOOL,	//INCLUSIVE
				DPEL_DYN_BOOL,	//NEGATED
				DPEL_INT,	//THRESHOLD for summary alarms
				DPEL_STRING,	//STATEBITS
				DPEL_DYN_STRING,//STATEBITS OF LIMITS
				DPEL_DYN_STRING //TEXTS WENT
				);


    string sqlAlertSumClean="DELETE FROM CDB_API_PARAMS";

    DebugTN("Executing sumalert cleanup",sqlAlertSumClean);
    fwConfigurationDB_executeSqlSimple(sqlAlertSumClean, g_fwConfigurationDB_DBConnection,exceptionInfo);
    if (dynlen(exceptionInfo)) {fwDbRollbackTransaction(g_fwConfigurationDB_DBConnection);return;}
    DebugTN("Committing it...");
    fwDbCommitTransaction(g_fwConfigurationDB_DBConnection);

    DebugTN("Executing",sql);
    _fwConfigurationDB_executeDBQuery(sql, g_fwConfigurationDB_DBConnection,configurationData,exceptionInfo,19,TRUE,colTypes);
	if (dynlen(exceptionInfo)) return;
	DebugTN("Got alerts from DB");
//	DebugTN(configurationData[1],configurationData[2],configurationData[8]);

	if (dynlen(configurationData) && dynlen(configurationData[1])) {
	    DebugTN("Reformatting the data",dynlen(configurationData[1]));
	    dyn_dyn_mixed alarmObjectList;
	    dyn_string alertDpes=configurationData[1];
	    dyn_int alertIpropIds=configurationData[2];

/************************ TO BE COMPLETED IN A FUTURE RELEASE ******************************
		// we will need an "append" mode for summary alarms, hence we will need
		// to extract their configuration... for that we need a list of those
		// dpes that have summary alarms
		dyn_string sumAlarmDpes;
		dyn_string existingSumAlerts;
		for (int i=1;i<=dynlen(alertDpes);i++) {
		    int alarmType=configurationData[3][i];
		    if (alarmType!=DPCONFIG_SUM_ALERT) continue;
		    dynAppend(sumAlarmDpes,alertDpes[i]);
		    string dpePattern;
		    int curAlertType;
		    dpGet(dpe + ":_alert_hdl.._type", curAlertType)
		    if (curAlertType==DPCONFIG_SUM_ALERT)
		    dpGet(alertDpes[i] + ":_alert_hdl.._dp_pattern", dpePattern);
		    dynAppend(existingSumAlerts,dpePattern);
		}
******************************************************************************************/		
	    for (int i=1;i<=dynlen(alertDpes);i++) {
		dyn_mixed alarmObject;
		dyn_dyn_mixed alarmLimits;
		dyn_dyn_mixed alarmParams;
		dyn_mixed alarmTexts=configurationData[5][i];
		dyn_mixed alarmThresholds=configurationData[6][i];
		dyn_mixed alarmClasses=configurationData[7][i];
		dyn_mixed valuesIncluded=configurationData[14][i];
		dyn_mixed negated=configurationData[15][i];
		dyn_mixed limitsStateBits=configurationData[18][i];
		dyn_mixed wentTexts=configurationData[19][i];
		    
		// initialize first elements of limiting values to dummy values
		mixed dummy;
		alarmLimits[1][fwAlertConfig_ALERT_LIMIT_VALUE]=dummy;
		alarmLimits[1][fwAlertConfig_ALERT_LIMIT_VALUE_MATCH]=dummy;

		    
		// process the range-part... for symmetry with dpe-alerts processing,
		// we do it in a loop, even though there is only one range...
		int totalRanges=dynlen(alarmTexts);
		for (int j=1;j<=totalRanges;j++) {
		    alarmLimits[j][fwAlertConfig_ALERT_LIMIT_TEXT] = alarmTexts[j];
		    if (dynlen(valuesIncluded)) { 
			alarmLimits[j][fwAlertConfig_ALERT_LIMIT_VALUE_INCLUDED] = valuesIncluded[j];
		    } else { 
			alarmLimits[j][fwAlertConfig_ALERT_LIMIT_VALUE_INCLUDED]=FALSE;
		    }
		    if (dynlen(alarmClasses)) {
			alarmLimits[j][fwAlertConfig_ALERT_LIMIT_CLASS] = dpSubStr(alarmClasses[j],DPSUB_DP_EL);
		    } else {
			alarmLimits[j][fwAlertConfig_ALERT_LIMIT_CLASS] = "";
		    }

		    if (dynlen(negated)) { 
			alarmLimits[j][fwAlertConfig_ALERT_LIMIT_NEGATION] = negated[j];
		    } else {
			alarmLimits[j][fwAlertConfig_ALERT_LIMIT_NEGATION]=FALSE;
		    }

		    alarmLimits[j][fwAlertConfig_ALERT_LIMIT_STATE_BITS] = configurationData[17][i];

		    if (dynlen(limitsStateBits)) {
			alarmLimits[j][fwAlertConfig_ALERT_LIMIT_LIMITS_STATE_BITS] = limitsStateBits[j];
		    } else {
			alarmLimits[j][fwAlertConfig_ALERT_LIMIT_LIMITS_STATE_BITS] = "";
		    }
		    if (dynlen(wentTexts)) {
			alarmLimits[j][fwAlertConfig_ALERT_LIMIT_TEXT_WENT] = wentTexts[j];
		    } else {
			alarmLimits[j][fwAlertConfig_ALERT_LIMIT_TEXT_WENT] = "";			    
		    }
		}

		alarmParams[fwAlertConfig_ALERT_PARAM_TYPE][1]      = configurationData[3][i];
		alarmParams[fwAlertConfig_ALERT_PARAM_SUM_DPE_LIST] = configurationData[8][i];
		alarmParams[fwAlertConfig_ALERT_PARAM_SUM_THRESHOLD][1] = configurationData[16][i];
		alarmParams[fwAlertConfig_ALERT_PARAM_ADD_DPE_TO_SUMMARY][1] = "";
		alarmParams[fwAlertConfig_ALERT_PARAM_PANEL][1] = configurationData[9][i];
    		alarmParams[fwAlertConfig_ALERT_PARAM_PANEL_PARAMETERS] = configurationData[10][i];
    		alarmParams[fwAlertConfig_ALERT_PARAM_HELP][1] =          configurationData[11][i];
        	alarmParams[fwAlertConfig_ALERT_PARAM_DISCRETE][1] = configurationData[12][i];
        	alarmParams[fwAlertConfig_ALERT_PARAM_IMPULSE][1] = configurationData[13][i];
            	alarmParams[fwAlertConfig_ALERT_PARAM_MODIFY_ONLY][1] = FALSE;
            	alarmParams[fwAlertConfig_ALERT_PARAM_FALLBACK_TO_SET][1] = FALSE;
                alarmParams[fwAlertConfig_ALERT_PARAM_STORE_IN_HISTORY][1] = TRUE;
                alarmParams[fwAlertConfig_ALERT_PARAM_RANGES][1] = totalRanges;
                alarmParams[fwAlertConfig_ALERT_PARAM_ACTIVE][1] = configurationData[4][i];
                    
		alarmObject[fwAlertConfig_ALERT_LIMIT]=alarmLimits;
		alarmObject[fwAlertConfig_ALERT_PARAM]=alarmParams;
		alarmObjectList[i]=alarmObject;
		    
	    }
	    if (dynlen(alertDpes)) { 
		DebugTN("Done. Setting the sumalerts now",dynlen(alertDpes),dynlen(alarmObjectList));
		fwAlertConfig_objectSetMany(alertDpes, alarmObjectList, exceptionInfo);
		if (dynlen(exceptionInfo)) return;
		DebugTN("DONE!");
	    }
	}

/////////
        // now activate/deactivate the alerts;
        dyn_string dpesToActivate, dpesToDeactivate;
        if (dynlen(configurationData)) {
    	    for (int i=1;i<=dynlen(configurationData[4]);i++) {
    		string dpe=configurationData[1][i];
    		if (configurationData[4][i] > 0) {
    		    dynAppend(dpesToActivate,dpe);
    		} else {
    		    dynAppend(dpesToDeactivate,dpe);
    		}
    	    }
    	    bool acknowledge = TRUE;
    	    bool checkIfExists = FALSE;
    	    bool storeInParamHistory = TRUE;
    	    if (dynlen(dpesToActivate)) fwAlertConfig_activateMultiple  (dpesToActivate,   exceptionInfo, acknowledge, checkIfExists, storeInParamHistory);
    	    if (dynlen(dpesToDeactivate)) fwAlertConfig_deactivateMultiple(dpesToDeactivate, exceptionInfo, acknowledge, checkIfExists, storeInParamHistory);
    	    if (dynlen(exceptionInfo)) return;
    	}
        DebugN("Activated "+dynlen(dpesToActivate)+", deactivated "+dynlen(dpesToDeactivate)+" sumalerts");

    DebugTN("Executing cleanup",sqlAlertSumClean);
    fwConfigurationDB_executeSqlSimple(sqlAlertSumClean, g_fwConfigurationDB_DBConnection,exceptionInfo);
    if (dynlen(exceptionInfo)) {fwDbRollbackTransaction(g_fwConfigurationDB_DBConnection);return;}
}




void _fwConfigurationDB_loadApplyArchiving(dyn_string &exceptionInfo)
{
        if (fwConfigurationDB_progress(fwConfigurationDB_OPER_LoadDeviceProperties,"Loading archiving", 65.0,
                                   exceptionInfo)) return;

        DebugTN("loading/applying archiving configs...");
        
        string sql ="SELECT TIP.DPENAME, CA.CLASSNAME, CA.TYPE, CA.SMOOTHPROC, CA.DEADBAND, CA.TIMEINTVAL, CA.ACTIVE "+
        	    " FROM CONFIG_ARCHIVING CA, TMP_ITEM_PROPS TIP"+
                    " where CA.iprop_id =TIP.iprop_id";
        dyn_int colTypes=makeDynInt(0,0,0,0,DPEL_FLOAT,DPEL_FLOAT,DPEL_INT);
	DebugTN("Executing",sql);
        dbCommand dbCmd;      

        fwConfigurationDB_initializeQuery( sql, g_fwConfigurationDB_DBConnection, dbCmd, exceptionInfo);
            DebugTN("query executed, processing data by chunks now...");
            if (dynlen(exceptionInfo)) return;
        
        int rc=0;
        int maxRecords=100000;
        int nLoops=0;
        do {
    	    nLoops++;
    	    if (fwConfigurationDB_progress(fwConfigurationDB_OPER_LoadDevices,"Loading archiving ["+nLoops+"]", 50.0, exceptionInfo,false)) {
    		fwDbFinishCommand (dbCmd);
    		return;
    	    }

    	    dyn_dyn_mixed data;
            rc=fwConfigurationDB_fetchQuery(dbCmd, data,exceptionInfo, maxRecords, TRUE ,TRUE, colTypes,7);
            if (dynlen(exceptionInfo)) return;
            dyn_string dpes;
    	    bool checkClass = TRUE;
    	    bool activateArchiving = FALSE;// default in this function is TRUE;
    	    // we should use the information in configurationData[8] to activate archiving...
            if (dynlen(data) && dynlen(data[1])) {
        	DebugTN("Processing...");
        	DebugTN("Fetched a chunk",dynlen(data[1]));
                dyn_string dpesArchive=data[1];
                if (dynlen(dpesArchive)) {
		    DebugTN("Setting archive...");
    		    if (fwConfigurationDB_progress(fwConfigurationDB_OPER_LoadDevices,"Setting up archiving ["+nLoops+"]", 50.0, exceptionInfo,false)) {
    			fwDbFinishCommand (dbCmd);
    			return;
    		    }

        	    fwArchive_setMany(dpesArchive, data[2],data[3],data[4],data[5], data[6],exceptionInfo, checkClass, activateArchiving);
        	    if (dynlen(exceptionInfo)) return;
		    DebugTN("Process activate/deactivate...");
    		    if (fwConfigurationDB_progress(fwConfigurationDB_OPER_LoadDevices,"Activate/Deactivate archiving ["+nLoops+"]", 50.0, exceptionInfo,false)) {
    			fwDbFinishCommand (dbCmd);
    			return;
    		    }

    		    // now start/stop the archiving: fix #42560
    		    dyn_string dpesArchiveOn;
    		    dyn_string dpesArchiveOff;
    		    for (int i=1;i<=dynlen(dpesArchive);i++) {
    			if (data[7][i]) {
    			    dynAppend(dpesArchiveOn,dpesArchive[i]);
    			} else {
    			    dynAppend(dpesArchiveOff,dpesArchive[i]);
    			}
    		    }
		    DebugTN("activate/deactivate...");
		    if (dynlen(dpesArchiveOn)) fwArchive_startMultiple(dpesArchiveOn, exceptionInfo);
		    if (dynlen(exceptionInfo)) return;
		    if (dynlen(dpesArchiveOff))fwArchive_stopMultiple(dpesArchiveOff, exceptionInfo);
		    if (dynlen(exceptionInfo)) return;
		}
    		DebugN("Configured "+dynlen(data[1])+" archiving configs in this batch");
            
            }
        } while (rc==1);             
        DebugTN("Configuration of archiving done");                

}


////////////
/** Extracts archiving configuration from PVSS and save to DB
 *
 * @param dpes      list of the data point element names for which configuration is requested
 * @param ipropIds  corresponding list of IPROP_ID identifiers (in the database) of the data-point elements
 *
 * we assume that the configuration was already created, and ipropIds are valid
 */
void _fwConfigurationDB_savePropArchivingToDB(dyn_string dpes,dyn_int ipropIds, dyn_string &exceptionInfo)
{
    string sql="INSERT INTO CONFIG_ARCHIVING (IPROP_ID, CLASSNAME, TYPE, "+
            " SMOOTHPROC, DEADBAND, TIMEINTVAL, ACTIVE) "+
            " VALUES (:IPROP_ID, :CLASSNAME, :TYPE, :SMOOTHPROC,:DEADBAND,:TIMEINTVAL, :ACTIVE)";


    dyn_bool configExists,isActive;
    dyn_string archiveClass;
    dyn_int archiveType, smoothProcedure;
    dyn_float deadband,timeInterval;

    DebugTN("We extract archiving parameters");
    fwArchive_getMany(dpes, configExists, archiveClass, archiveType, smoothProcedure,
                      deadband, timeInterval,isActive,exceptionInfo);
    if (dynlen(exceptionInfo)) { fwDbRollbackTransaction(g_fwConfigurationDB_DBConnection); return;}
    
    DebugTN("We got archiving parameters", dynlen(archiveType));
    dyn_dyn_mixed archivingData;

    for (int i=1;i<=dynlen(dpes);i++) {
        if (configExists[i]) {
    	    int pos=dynlen(archivingData)+1;
            archivingData[pos][1] = ipropIds[i];
            archivingData[pos][2] = archiveClass[i];
            archivingData[pos][3] = archiveType[i];
            archivingData[pos][4] = smoothProcedure[i];
            archivingData[pos][5] = deadband[i];
            archivingData[pos][6] = timeInterval[i];
            archivingData[pos][7] = isActive[i];
        }
    }

    DebugTN("Executing",sql, "with "+dynlen(archivingData)+" values");
    _fwConfigurationDB_executeDBBulkCmd(sql,g_fwConfigurationDB_DBConnection,archivingData, exceptionInfo);
    if (dynlen(exceptionInfo)) { fwDbRollbackTransaction(g_fwConfigurationDB_DBConnection); return;}
    DebugTN("Saving of archiving DONE");

}




void _fwConfigurationDB_loadApplyDpFunctions(dyn_string &exceptionInfo, int options)
{

    if (fwConfigurationDB_progress(fwConfigurationDB_OPER_LoadDeviceProperties,"Loading dpfunctions", 70.0,
				    exceptionInfo)) return;

    bool runChecks = TRUE;

	DebugTN("loading/applying dpfunction configs...");

string sql ="SELECT TIP.DPENAME, CDPF.PARAMS, CDPF.GLOBALS, CDPF.DEFINITION, CDPF.FUNCTYPE, CDPF.STATFUNCTYPES, CDPF.STATOPTS "+
			" FROM CONFIG_DPFUNCTIONS CDPF, TMP_ITEM_PROPS TIP"+
				" where CDPF.iprop_id =TIP.iprop_id";
	dyn_int colTypes=makeDynInt(0,DPEL_DYN_STRING,DPEL_DYN_STRING,0,0,DPEL_DYN_INT,DPEL_DYN_STRING);
	dbCommand dbCmd;
	fwConfigurationDB_initializeQuery( sql, g_fwConfigurationDB_DBConnection, dbCmd, exceptionInfo);
	if (dynlen(exceptionInfo)) return;
	DebugTN("query executed, processing data by chunks now...");

	string mySysNameNoColon=strrtrim(getSystemName(),":");
	int rc=0;
	int maxRecords=10000;
	int nLoops=0;
        do {
    	    nLoops++;
    	    dyn_dyn_mixed data;
    	    
    	    if (fwConfigurationDB_progress(fwConfigurationDB_OPER_LoadDevices,"Loading dpFunctions ["+nLoops+"]", 60.0, exceptionInfo,false)) {
    		fwDbFinishCommand (dbCmd);
    		return;
    	    }
    	    
            rc=fwConfigurationDB_fetchQuery(dbCmd, data,exceptionInfo, maxRecords, FALSE ,TRUE, colTypes,7);
            if (dynlen(exceptionInfo)) return;
    	    if (fwConfigurationDB_progress(fwConfigurationDB_OPER_LoadDevices,"Processing dpFunctions ["+nLoops+"]", 60.0, exceptionInfo,false)) {
    		fwDbFinishCommand (dbCmd);
    		return;
    	    }

    	    DebugTN("Got the data; Re-arranging data now",dynlen(data));
    	    dyn_mixed dpfObjectList;
    	    if (dynlen(data)==0) break; // protect from having an empty result set
    	    dyn_string dpfDpes=getDynString(data,1);
	    for (int i=1;i<=dynlen(data);i++){
    	    	dyn_mixed dpfObject;
    	    	dyn_string dpfParams=data[i][2];
    	    	if (options && fwConfigurationDB_deviceConfig_ADOPT_TO_SYSTEM) {
    	    	    for (int j=1;j<=dynlen(dpfParams);j++) {
    	    		string param=dpfParams[j];
    	    		dyn_string ds=strsplit(param,":");
    	    		if (dynlen(ds)>1) {
    	    		    param=mySysNameNoColon;
    	    		    for (int k=2;k<=dynlen(ds);k++) param+=":"+ds[k];
    	    		}
    	    		dpfParams[j]=param;
    	    	    }
    	    	}
    		dpfObject[fwDpFunction_OBJ_FUNCTION] = data[i][4];
    		dpfObject[fwDpFunction_OBJ_GLOBAL]   = data[i][3];
    		dpfObject[fwDpFunction_OBJ_TYPE]     = data[i][5];
    		dpfObject[fwDpFunction_OBJ_STAT_TYPE]= data[i][6];
		// parse the list of various options for statistical functions
		dyn_string statOpts=data[i][7];
		int statInterval=0, statDelay=0;
		bool statReadArchive=false;
		if (dynlen(statOpts)>0) statInterval=statOpts[1];
		if (dynlen(statOpts)>1) statDelay=statOpts[2];
		if (dynlen(statOpts)>2) statReadArchive=statOpts[3];
		dpfObject[fwDpFunction_OBJ_STAT_INTERVAL]=statInterval;
		dpfObject[fwDpFunction_OBJ_STAT_DELAY]=statDelay;
		dpfObject[fwDpFunction_OBJ_STAT_READ_ARCHIVE]=statReadArchive;
    		dpfObject[fwDpFunction_OBJ_PARAM]    = dpfParams;
		dpfObjectList[i]=dpfObject;
	    }
	    
	    
		if (dynlen(dpfDpes)) {
		    DebugTN("We apply a bunch of dpfuncs through object",dynlen(dpfDpes));
    		    if (fwConfigurationDB_progress(fwConfigurationDB_OPER_LoadDevices,"Setting dpFunctions ["+nLoops+"]", 60.0, exceptionInfo,false)) {
    			fwDbFinishCommand (dbCmd);
    			return;
    		    }
	      	    fwDpFunction_objectSetMany(dpfDpes,dpfObjectList,exceptionInfo,runChecks);
	    	    if (dynlen(exceptionInfo)) return;
	    	}

        } while (rc==1);

		DebugTN("Configuration of dpfuns done.");
}

////////////


_fwConfigurationDB_savePropDpFunctionToDB(dyn_string dpes,dyn_int ipropIds, dyn_string &exceptionInfo)
{
    string sql="INSERT INTO CONFIG_DPFUNCTIONS (IPROP_ID, PARAMS, GLOBALS, DEFINITION, FUNCTYPE, STATFUNCTYPES, STATOPTS)"+
            " VALUES (:IPROP_ID, :PARAMS, :GLOBALS, :DEFINITION, :FUNCTYPE, :STATFUNCTYPES, :STATOPTS)";


    dyn_bool configExists;
    dyn_mixed dpfObjectList;

    DebugTN("We extract dpFunction parameters");
    fwDpFunction_objectGetMany(dpes, configExists, dpfObjectList, exceptionInfo);
    if (dynlen(exceptionInfo)) { fwDbRollbackTransaction(g_fwConfigurationDB_DBConnection); return;}
    
    DebugTN("We got dpFunction parameters", dynlen(configExists));
    dyn_dyn_mixed dpfData;
    
    for (int i=1;i<=dynlen(dpes);i++) {    
	if (configExists[i]) {
	    dyn_mixed dpfObject=dpfObjectList[i];
    	    int pos=dynlen(dpfData)+1;
            dpfData[pos][1] = ipropIds[i];
            dpfData[pos][2] = dpfObject[fwDpFunction_OBJ_PARAM];
            dpfData[pos][3] = dpfObject[fwDpFunction_OBJ_GLOBAL];
            dpfData[pos][4] = dpfObject[fwDpFunction_OBJ_FUNCTION];
            dpfData[pos][5] = dpfObject[fwDpFunction_OBJ_TYPE];
            
            
            
	    dyn_string statOpts;
	    dyn_int statFunTypes;
	    if (dpfObject[fwDpFunction_OBJ_TYPE]==DPCONFIG_STAT_FUNCTION) {
	        statOpts = makeDynString( dpfObject[fwDpFunction_OBJ_STAT_INTERVAL],
					  dpfObject[fwDpFunction_OBJ_STAT_DELAY],
					  dpfObject[fwDpFunction_OBJ_STAT_READ_ARCHIVE]);
        	statFunTypes = dpfObject[fwDpFunction_OBJ_STAT_TYPE];
	    }
            dpfData[pos][6] = statFunTypes;
	    dpfData[pos][7] = statOpts;
	}
    }

    DebugTN("Executing",sql, "with "+dynlen(dpfData)+" values");
    _fwConfigurationDB_executeDBBulkCmd(sql,g_fwConfigurationDB_DBConnection,dpfData, exceptionInfo);
    if (dynlen(exceptionInfo)) { fwDbRollbackTransaction(g_fwConfigurationDB_DBConnection); return;}
    DebugTN("Saving of DPFunctions DONE");
    
}




void _fwConfigurationDB_loadApplyConversions(dyn_string &exceptionInfo)
{
        if (fwConfigurationDB_progress(fwConfigurationDB_OPER_LoadDeviceProperties,"Loading conversions", 75.0,
                                   exceptionInfo)) return;

        DebugTN("loading/applying conversion configs...");

		string sql="SELECT TIP.DPENAME, CC.TYPE, CC.CONVTYPE, CC.CONVORDER, CC.ARGUMENTS "+
                    " FROM CONFIG_CONVERSIONS CC, TMP_ITEM_PROPS TIP "+
                    " where CC.iprop_id =TIP.iprop_id";            
            
        dyn_int colTypes=makeDynInt(0,0,0,0,DPEL_DYN_FLOAT);

		dbCommand dbCmd;
		fwConfigurationDB_initializeQuery( sql, g_fwConfigurationDB_DBConnection, dbCmd, exceptionInfo);
		if (dynlen(exceptionInfo)) return;
		DebugTN("query executed, processing data by chunks now...");

		int rc=0;
		int maxRecords=10000;
		bool runDriverCheck=FALSE;
		int nLoops=0;
		do {
			nLoops++;
			
			if (fwConfigurationDB_progress(fwConfigurationDB_OPER_LoadDevices,"Loading conversions ["+nLoops+"]", 70.0, exceptionInfo,false)) {
    			    fwDbFinishCommand (dbCmd);
    			    return;
    			}

			
			dyn_dyn_mixed data;
			rc=fwConfigurationDB_fetchQuery(dbCmd, data,exceptionInfo, maxRecords, TRUE ,TRUE, colTypes,5);
			if (dynlen(exceptionInfo)) return;
			if (dynlen(data) && dynlen(data[1])) {
				DebugTN("Got the data; applying it",dynlen(data[1]));
				
			    if (fwConfigurationDB_progress(fwConfigurationDB_OPER_LoadDevices,"Setting conversions ["+nLoops+"]", 70.0, exceptionInfo,false)) {
    				fwDbFinishCommand (dbCmd);
    				return;
    			    }
				
				fwConfigConversion_setMany(data[1], data[2],
										   data[3], data[4],
										   data[5], exceptionInfo, runDriverCheck);
				if (dynlen(exceptionInfo)) return;
			}
		} while (rc==1);
		DebugTN("Conversions configured OK");
}

////////////

_fwConfigurationDB_savePropConversionToDB(dyn_string dpes,dyn_int ipropIds, dyn_string &exceptionInfo)
{
    string sql="INSERT INTO CONFIG_CONVERSIONS (IPROP_ID, TYPE, CONVTYPE, CONVORDER, ARGUMENTS)"+
            " VALUES (:IPROP_ID, :TYPE, :CONVTYPE, :CONVORDER, :ARGUMENTS)";


    dyn_bool configExistsCmd,configExistsMsg;
    dyn_int conversionTypeCmd,conversionTypeMsg, orderCmd, orderMsg;
    dyn_dyn_float argumentsCmd,argumentsMsg;

    DebugTN("We extract conversion parameters");

    fwConfigConversion_getMany(dpes, configExistsMsg, DPCONFIG_CONVERSION_RAW_TO_ENG_MAIN,
                               conversionTypeMsg, orderMsg,argumentsMsg, exceptionInfo);
    if (dynlen(exceptionInfo)) { fwDbRollbackTransaction(g_fwConfigurationDB_DBConnection); return;}
    fwConfigConversion_getMany(dpes, configExistsCmd, DPCONFIG_CONVERSION_ING_TO_RAW_MAIN,
                               conversionTypeCmd, orderCmd,argumentsCmd, exceptionInfo);
    if (dynlen(exceptionInfo)) { fwDbRollbackTransaction(g_fwConfigurationDB_DBConnection); return;}

    DebugTN("We got conversion parameters", dynlen(configExistsMsg));


    dyn_dyn_mixed conversionData;

    for (int i=1;i<=dynlen(dpes);i++) {
        if (configExistsMsg[i]) {
            int pos=dynlen(conversionData)+1;
            conversionData[pos][1]=ipropIds[i];
            conversionData[pos][2]=DPCONFIG_CONVERSION_RAW_TO_ENG_MAIN;
            conversionData[pos][3]=conversionTypeMsg[i];
            conversionData[pos][4]=orderMsg[i];
            conversionData[pos][5]=argumentsMsg[i];
            
        }

        if (configExistsCmd[i]) {
            int pos=dynlen(conversionData)+1;
            conversionData[pos][1]=ipropIds[i];
            conversionData[pos][2]=DPCONFIG_CONVERSION_ING_TO_RAW_MAIN;
            conversionData[pos][3]=conversionTypeCmd[i];
            conversionData[pos][4]=orderCmd[i];
            conversionData[pos][5]=argumentsCmd[i];
        }
    }
    DebugTN("Executing",sql, "with "+dynlen(conversionData)+" values");
    _fwConfigurationDB_executeDBBulkCmd(sql,g_fwConfigurationDB_DBConnection,conversionData, exceptionInfo);
    if (dynlen(exceptionInfo)) { fwDbRollbackTransaction(g_fwConfigurationDB_DBConnection); return;}
    DebugTN("Saving of Conversion DONE");

}


void _fwConfigurationDB_loadApplyPvRanges(dyn_string &exceptionInfo)
{
        if (fwConfigurationDB_progress(fwConfigurationDB_OPER_LoadDeviceProperties,"Loading pvranges", 80.0,
                                   exceptionInfo)) return;

        DebugN("loading/applying pvrange configs...");

	// NOTE! We construct the SQL in such a way, that the leading columns match exactly the structure
	// of the pvRange configuration object; then we append a couple of separating NULLs, and then
	// the pvrange type and dpename
	
	// note! we need a workaround for ENS-4575 (truncation of large values), therefore
	// for MINVALUE and MAXVALUE we do a TO_CHAR, and then force type casting of the columns to DPEL_FLOAT below
	
	string sql="SELECT TO_CHAR(CPV.MINVALUE), " + // fwPvRange_MINIMUM_VALUE=1
	           "       TO_CHAR(CPV.MAXVALUE), " + // fwPvRange_MAXIMUM_VALUE=2
	           "       CPV.PVRVALS,  " + // fwPvRange_VALUE_SET=3
	           "       CPV.PVRVALS,  " + // fwPvRange_VALUE_PATTERN=4
	           "       CPV.NEGRANGE, " + // fwPvRange_NEGATE_RANGE=5
	           "       CPV.IGNOUTSIDE,"+ // fwPvRange_IGNORE_OUTSIDE=6
	           "       CPV.INCLMIN, "  + // fwPvRange_INCLUSIVE_MINIMUM=7
	           "       CPV.INCLMAX, "  + // fwPvRange_INCLUSIVE_MAXIMUM=8
                   " NULL,NULL,NULL,NULL, "+ // separation,reserved for eventual extensions
                   "       CPV.PVRTYPE, TIP.DPENAME "+
                   " FROM CONFIG_PVRANGES CPV, TMP_ITEM_PROPS TIP"+
                    " where CPV.iprop_id =TIP.iprop_id";

        dyn_int colTypes=makeDynInt(DPEL_FLOAT,DPEL_FLOAT,DPEL_DYN_STRING,0,0,0,0,0,0,0,0,0,0,0);

		dbCommand dbCmd;
		fwConfigurationDB_initializeQuery( sql, g_fwConfigurationDB_DBConnection, dbCmd, exceptionInfo);
		if (dynlen(exceptionInfo)) return;
		DebugTN("query executed, processing data by chunks now...");

		int rc=0;
		int maxRecords=10000;
		int nLoops=0;
		do {
		    nLoops++;
		    
		    if (fwConfigurationDB_progress(fwConfigurationDB_OPER_LoadDevices,"Loading PV-Ranges ["+nLoops+"]", 80.0, exceptionInfo,false)) {
    			fwDbFinishCommand (dbCmd);
    			return;
    		    }

		    
			dyn_dyn_mixed data;
			rc=fwConfigurationDB_fetchQuery(dbCmd, data,exceptionInfo, maxRecords, FALSE ,TRUE, colTypes,14);
			if (dynlen(exceptionInfo)) return;
			if (dynlen(data) && dynlen(data[1])) {

			if (fwConfigurationDB_progress(fwConfigurationDB_OPER_LoadDevices,"Processing PV-Ranges ["+nLoops+"]", 80.0, exceptionInfo,false)) {
    			    fwDbFinishCommand (dbCmd);
    			    return;
    			}

			// workaround for ENS-4481
			dyn_float minValues=getDynFloat(data,1);
			dyn_float maxValues=getDynFloat(data,2);
			
			bool modif=_fwConfigurationDB_expandFloats(minValues, exceptionInfo);
			if (dynlen(exceptionInfo)) return;
			if (modif) for (int i=1;i<=dynlen(data);i++) data[i][1]=minValues[i];

			modif=_fwConfigurationDB_expandFloats(maxValues, exceptionInfo);
			if (dynlen(exceptionInfo)) return;
			if (modif) for (int i=1;i<=dynlen(data);i++) data[i][2]=maxValues[i];

			dyn_string dpeList=getDynString(data,14);
			dyn_int pvrTypes=getDynInt(data,13);

			if (dynlen(dpeList)) {
			    if (fwConfigurationDB_progress(fwConfigurationDB_OPER_LoadDevices,"Setting PV-Ranges ["+nLoops+"]", 80.0, exceptionInfo,false)) {
    				fwDbFinishCommand (dbCmd);
    				return;
    			    }
			    fwPvRange_setObjectMany( dpeList, pvrTypes, data, exceptionInfo);
			    if (dynlen(exceptionInfo)) return;
			    DebugN("Configured batch of "+dynlen(dpeList)+" pvranges");
			}
			
			}
		} while (rc==1);
		DebugTN("PVRanges configured OK");

}


_fwConfigurationDB_savePropPVRangeToDB(dyn_string dpes,dyn_int ipropIds, dyn_string &exceptionInfo)
{
    string sql="INSERT INTO CONFIG_PVRANGES (IPROP_ID, PVRTYPE, MINVALUE, MAXVALUE, "+
                    " NEGRANGE, IGNOUTSIDE, INCLMIN, INCLMAX, PVRVALS)"+
                    " VALUES (:IPROP_ID, :PVRTYPE, :MINVALUE, :MAXVALUE, :NEGRANGE, "+
                    " :IGNOUTSIDE, :INCLMIN, :INCLMAX, :PVRVALS)";

    dyn_bool configExists;
    dyn_int pvRangeTypes;
    dyn_dyn_mixed configData;
    
    DebugTN("We extract pvrange parameters");
    fwPvRange_getObjectMany( dpes, configExists, pvRangeTypes,
                            configData, exceptionInfo);
    if (dynlen(exceptionInfo)) { fwDbRollbackTransaction(g_fwConfigurationDB_DBConnection); return;}
    DebugTN("We got pvrange parameters", dynlen(configExists));
    dyn_dyn_mixed pvrData;



    dyn_float minValues=getDynFloat(configData,fwPvRange_MINIMUM_VALUE);
    dyn_float maxValues=getDynFloat(configData,fwPvRange_MAXIMUM_VALUE);
    // workaround for ENS-4481
    _fwConfigurationDB_collapseFloats(minValues, exceptionInfo, "Storing PVRange [min]");
    if (dynlen(exceptionInfo)) { 	fwDbRollbackTransaction(g_fwConfigurationDB_DBConnection); return;}

    _fwConfigurationDB_collapseFloats(maxValues, exceptionInfo, "Storing PVRange [max]");
    if (dynlen(exceptionInfo)) { fwDbRollbackTransaction(g_fwConfigurationDB_DBConnection); return;}


    for (int i=1;i<=dynlen(configData);i++) {
	if (configExists[i]) {
	    dyn_mixed obj=configData[i];
            int pos=dynlen(pvrData)+1;

            pvrData[pos][1] = ipropIds[i];
	    pvrData[pos][2] = pvRangeTypes[i];
	    pvrData[pos][3] = minValues[i];
	    pvrData[pos][4] = maxValues[i];
	    pvrData[pos][5] = obj[fwPvRange_NEGATE_RANGE];
	    pvrData[pos][6] = obj[fwPvRange_IGNORE_OUTSIDE];
	    pvrData[pos][7] = obj[fwPvRange_INCLUSIVE_MINIMUM];
	    pvrData[pos][8] = obj[fwPvRange_INCLUSIVE_MAXIMUM];
	    pvrData[pos][9] = obj[fwPvRange_VALUE_SET];
	}
    }

    DebugTN("Executing",sql, "with "+dynlen(pvrData)+" values");
    _fwConfigurationDB_executeDBBulkCmd(sql,g_fwConfigurationDB_DBConnection,pvrData, exceptionInfo);
    if (dynlen(exceptionInfo)) { fwDbRollbackTransaction(g_fwConfigurationDB_DBConnection); return;}
    DebugTN("Saving of PVRanges DONE");

}



void _fwConfigurationDB_loadApplySmoothing(dyn_string &exceptionInfo)
{
        if (fwConfigurationDB_progress(fwConfigurationDB_OPER_LoadDeviceProperties,"Loading smoothing", 85.0,
                                   exceptionInfo)) return;

        DebugTN("loading/applying smoothing configs...");
        
        string sql="SELECT TIP.DPENAME, CS.PROC, CS.DEADBAND, CS.TIMEINTVAL "+
                   " FROM CONFIG_SMOOTHING CS, TMP_ITEM_PROPS TIP "+                   
                    " where CS.iprop_id = TIP.iprop_id";            

		dyn_int colTypes=makeDynInt(DPEL_STRING,DPEL_INT,DPEL_FLOAT,DPEL_FLOAT);
		bool runDriverCheck = FALSE;

		dbCommand dbCmd;
		fwConfigurationDB_initializeQuery( sql, g_fwConfigurationDB_DBConnection, dbCmd, exceptionInfo);
		if (dynlen(exceptionInfo)) return;
		DebugTN("query executed, processing data by chunks now...");

		int rc=0;
		int maxRecords=10000;
		bool runDriverCheck=TRUE;
		int nLoops;
		do {
			nLoops++;
			if (fwConfigurationDB_progress(fwConfigurationDB_OPER_LoadDevices,"Loading smoothing ["+nLoops+"]", 90.0, exceptionInfo,false)) {
    			    fwDbFinishCommand (dbCmd);
    			    return;
    			}

			dyn_dyn_mixed data;
			
			rc=fwConfigurationDB_fetchQuery(dbCmd, data,exceptionInfo, maxRecords, TRUE ,TRUE, colTypes,4);
			if (dynlen(exceptionInfo)) return;

			if (fwConfigurationDB_progress(fwConfigurationDB_OPER_LoadDevices,"Setting smoothing ["+nLoops+"]", 90.0, exceptionInfo,false)) {
    			    fwDbFinishCommand (dbCmd);
    			    return;
    			}
			
			if (dynlen(data) && dynlen(data[1])) {
				fwSmoothing_setMany(data[1], data[2], data[3],data[4], exceptionInfo, runDriverCheck);
				if (dynlen(exceptionInfo)) return;
				DebugN("Configured batch of "+dynlen(data[1])+" smoothing.");
			}
			
		} while (rc==1);
		
		DebugTN("Smoothing configured OK");
}


_fwConfigurationDB_savePropSmoothingToDB(dyn_string dpes,dyn_int ipropIds, dyn_string &exceptionInfo)
{
    string sql="INSERT INTO CONFIG_SMOOTHING (IPROP_ID, PROC, DEADBAND, TIMEINTVAL) "+
            " VALUES (:IPROP_ID, :PROC, :DEADBAND, :TIMEINTVAL) ";

    dyn_bool configExists;
    dyn_int smoothProcedure;
    dyn_float deadband, timeInterval;

    DebugTN("We extract smoothing parameters");
    fwSmoothing_getMany(dpes, configExists, smoothProcedure, deadband, timeInterval, exceptionInfo);
    if (dynlen(exceptionInfo)) { fwDbRollbackTransaction(g_fwConfigurationDB_DBConnection); return;}
    DebugTN("We got smoothing parameters", dynlen(configExists));

    dyn_dyn_mixed smData;
    
    for (int i=1;i<=dynlen(dpes);i++) {
	if (configExists[i]) {
            int pos=dynlen(smData)+1;

            smData[pos][1] = ipropIds[i];
	    smData[pos][2] = smoothProcedure[i];
	    smData[pos][3] = deadband[i];
	    smData[pos][4] = timeInterval[i];
	}
    }

    DebugTN("Executing",sql, "with "+dynlen(smData)+" values");
    _fwConfigurationDB_executeDBBulkCmd(sql,g_fwConfigurationDB_DBConnection,smData, exceptionInfo);
    if (dynlen(exceptionInfo)) { fwDbRollbackTransaction(g_fwConfigurationDB_DBConnection); return;}
    DebugTN("Saving of Smoothing DONE");


}


void _fwConfigurationDB_loadApplyUnitAndFormat(dyn_string &exceptionInfo)
{
        if (fwConfigurationDB_progress(fwConfigurationDB_OPER_LoadDeviceProperties,"Loading unit and format", 90.0,
                                   exceptionInfo)) return;

        DebugTN("loading/applying unit and format configs...");
        
        
        string sql="SELECT TIP.DPENAME, UF.UNIT, UF.FMT FROM CONFIG_UF UF, TMP_ITEM_PROPS TIP "+
                    " where UF.iprop_id = TIP.iprop_id";            
                   
		dyn_int colTypes=makeDynInt(DPEL_STRING,DPEL_STRING,DPEL_STRING);
		dbCommand dbCmd;
		fwConfigurationDB_initializeQuery( sql, g_fwConfigurationDB_DBConnection, dbCmd, exceptionInfo);
		if (dynlen(exceptionInfo)) return;
		DebugTN("query executed, processing data by chunks now...");

		int rc=0;
		int maxRecords=10000;
		bool runDriverCheck=TRUE;
		int nLoops=0;
		do {
		    nLoops++;
			if (fwConfigurationDB_progress(fwConfigurationDB_OPER_LoadDevices,"Loading Unit/Format ["+nLoops+"]", 90.0, exceptionInfo,false)) {
    			    fwDbFinishCommand (dbCmd);
    			    return;
    			}

			dyn_dyn_mixed data;
			
			rc=fwConfigurationDB_fetchQuery(dbCmd, data,exceptionInfo, maxRecords, TRUE ,TRUE, colTypes,3);
			if (dynlen(exceptionInfo)) return;
			
			if (dynlen(data) && dynlen(data[1])) {
			    if (fwConfigurationDB_progress(fwConfigurationDB_OPER_LoadDevices,"Setting Unit/Format ["+nLoops+"]", 90.0, exceptionInfo,false)) {
    				fwDbFinishCommand (dbCmd);
    				return;
    			    }
				fwUnit_setMany(data[1], data[2], exceptionInfo);
				fwFormat_setMany(data[1], data[3], exceptionInfo);
				if (dynlen(exceptionInfo)) return;
				DebugN("Configured batch of "+dynlen(data[1])+" u&f");
			}
			
		} while (rc==1);
		
		DebugTN("Unit and format configured OK");
}






_fwConfigurationDB_savePropUnitAndFormatToDB(dyn_string dpes,dyn_int ipropIds, dyn_string &exceptionInfo)
{
    string sql="INSERT INTO CONFIG_UF (IPROP_ID, UNIT, FMT) "+
            " VALUES (:IPROP_ID, :UNIT, :FMT) ";

    dyn_bool unitExists,formatExists;
    dyn_string unit,format;

    DebugTN("We extract unit and format parameters");

    fwUnit_getMany  (dpes, unitExists,   unit,  exceptionInfo);
    fwFormat_getMany(dpes, formatExists, format,exceptionInfo);
    if (dynlen(exceptionInfo)) { fwDbRollbackTransaction(g_fwConfigurationDB_DBConnection); return;}
    DebugTN("We got unit and format parameters");

    dyn_dyn_mixed ufData;

    for (int i=1;i<=dynlen(dpes);i++) {
        if ((unitExists[i]) || (formatExists[i])) {
            int pos=dynlen(ufData)+1;
            ufData[pos][1] = ipropIds[i];
            ufData[pos][2] = unit[i];
            ufData[pos][3] = format[i];
        }
    }

    DebugTN("Executing",sql, "with "+dynlen(ufData)+" values");
    _fwConfigurationDB_executeDBBulkCmd(sql,g_fwConfigurationDB_DBConnection,ufData, exceptionInfo);
    if (dynlen(exceptionInfo)) { fwDbRollbackTransaction(g_fwConfigurationDB_DBConnection); return;}
    DebugTN("Saving of Unit and Format DONE");

}


/** Main function that saves static configuration - compatibility mode

@param  saveConfigs     may either be of bool, or of int type; in the former case, passing
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
    int options=saveConfigs;
    fwConfigurationDB_saveDeviceConfiguration(deviceList, configurationName, hierarchyType, exceptionInfo, options);
}

/** Main function that saves static configuration

*/
void fwConfigurationDB_saveDeviceConfiguration(dyn_string deviceList,
		string configurationName, 
		string hierarchyType,
		dyn_string &exceptionInfo, 
		int options=fwConfigurationDB_deviceConfig_ALLDEVPROPS)
{
    dyn_string dpeList;
    dyn_int dpeIdList;
    string sql;
    dyn_dyn_mixed data;
    dyn_mixed params;

    if (fwConfigurationDB_SchemaPrivs!="OWNER" && fwConfigurationDB_SchemaPrivs!="WRITER") {
	fwException_raise(exceptionInfo,"ERROR","Insufficient database rights to save static configuration","");
	fwConfigurationDB_checkErrors(exceptionInfo,false);
	return;
    }


    time t0=getCurrentTime();    


    mappingClear(g_fwConfigurationDB_stats);
    g_fwConfigurationDB_stats["PROCESS/Function"]="saveDeviceConfiguration";
    g_fwConfigurationDB_stats["PROCESS/ConfigName"]=configurationName;
    g_fwConfigurationDB_stats["PROCESS/T elapsed"]=0.0;

    DebugTN("START of saving new configuration for "+dynlen(deviceList)+" devices, into "+configurationName);

    // make sure the device list is unique!
    dynUnique(deviceList);

    if (fwConfigurationDB_progress(fwConfigurationDB_OPER_SaveDevices,"Saving device hierarchy", 1.0, exceptionInfo,true)) return;

    g_fwConfigurationDB_stats["PROCESS/#Devices"]=dynlen(deviceList);
    time t1=getCurrentTime();
    _fwConfigurationDB_saveItemsToDB(deviceList, hierarchyType,exceptionInfo);
    if (fwConfigurationDB_progress(fwConfigurationDB_OPER_SaveDevices,"Device hierarchy saved", 5.0, exceptionInfo,true)) return;


    
    time t2=getCurrentTime();    
    time dt=t2-t1;
    g_fwConfigurationDB_stats["ITEMS/T save items"]=(float)period(dt)+0.001*milliSecond(dt);
    
    ////// PREPARE SAVING OF PROPERTIES
    
    DebugTN("We prepare to save the properties");

    if (fwConfigurationDB_progress(fwConfigurationDB_OPER_SaveDevices,"Generating property list", 6.0, exceptionInfo,true)) return;


/* All the input - the list of devices - is already in CDB_API_PARAMS 
    -> Check/create new configurationName
	* generate CITEM_IDs, put them in CDB_API_PARAMS.I2
	* put the CITEM_IDs initially into CONFIG_ITEMS_NEW, with VALID_FROM=NULL
    -> Fill the TMP_ITEM_PROPS: 
	* expand the list of DPs to list of all DPEs
	* create new IPROP_IDS for all the entries
        * put the item ids into CONFIG_ITEMPROPS, so we have the initial mapping 
          of IPROP_IDs to CITEM_IDs already there...
    
*/
    t1=getCurrentTime();
    sql="BEGIN fwConfigurationDB.saveStaticConfiguration(:configurationName,:hierarchyType); END;";
    params[1]=configurationName;
    params[2]=hierarchyType;
    _fwConfigurationDB_executeDBCmd(sql,g_fwConfigurationDB_DBConnection, params, exceptionInfo);
    if (dynlen(exceptionInfo)) { 
	_fwConfigurationDB_showItemsInCDB_API_PARAMS("On error the data in CDB_API_PARAMS was");
	fwConfigurationDB_checkErrors(exceptionInfo,true);
	return;
    }
    time t2=getCurrentTime();    
    time dt=t2-t1;
    g_fwConfigurationDB_stats["PROPERTIES/generate,save properties"]=(float)period(dt)+0.001*milliSecond(dt);

    dt=t2-t0;
    g_fwConfigurationDB_stats["PROCESS/T elapsed"]=(float)period(dt)+0.001*milliSecond(dt);
    
    /////////////////////////////
    DebugTN("Properties prepared OK. Check how many do we have");    
    sql="SELECT COUNT(*) FROM TMP_ITEM_PROPS";
    _fwConfigurationDB_executeDBQuery(sql, g_fwConfigurationDB_DBConnection,data,exceptionInfo);
    if (fwConfigurationDB_checkErrors(exceptionInfo,true)) return;
    
    int len=data[1][1];
    DebugTN("We counted the number of properties:",len);
    
    bool finished=false;
    int dpesProcessed=0;
    int dpesInLoop=5000;
    int nLoops=0;

    g_fwConfigurationDB_stats["PROCESS/#Properties"]=len;
    g_fwConfigurationDB_stats["PROCESS/#Total loops "]=(len/dpesInLoop)+1;
    g_fwConfigurationDB_stats["PROCESS/#Loops "]=0;



    if (len==0) {
	DebugTN("No properties to store... COMMITTING AND FINISHING SAVING CONFIGURATION");
	if (fwConfigurationDB_progress(fwConfigurationDB_OPER_SaveDevices,"No properties to save", 100.0, exceptionInfo,true)) return;
	fwDbCommitTransaction(g_fwConfigurationDB_DBConnection); 
	fwConfigurationDB_closeProgressDialog();
	return;
    }

    if (fwConfigurationDB_progress(fwConfigurationDB_OPER_SaveDevices,"Generating device property list", 6.0, exceptionInfo,true)) return;

    // prepare the partial processing of properties...
    // we will retrieve IPROPs in blocks, and loop until we process them all...

    sql="SELECT IPROP_ID,DPENAME FROM TMP_ITEM_PROPS";
    dbCommand cmd;
    string errTxt;
    int rc; 
    rc = fwDbStartCommand (g_fwConfigurationDB_DBConnection, sql, cmd);
    if (rc) {
	fwDbCheckError(errTxt,cmd);
	fwException_raise(exceptionInfo,"ERROR","Cannot start DB Query\n"+errTxt,"");
	DebugTN("ERROR","Could not start SQL query",sql,errTxt);
	fwConfigurationDB_checkErrors(exceptionInfo,true);
	return;
    }
    rc = fwDbExecuteCommand (cmd);
    if (rc) {
	fwDbCheckError(errTxt,cmd);
	fwException_raise(exceptionInfo,"ERROR","Cannot execute DB Query\n"+errTxt,"");
	DebugTN("ERROR","Could not start SQL query",sql,errTxt);
	fwDbFinishCommand(cmd);
	fwConfigurationDB_checkErrors(exceptionInfo,true);
	return;
    }
    
    
    
    
    while (!finished) {
	// break out:
	finished=true;

	dynClear(data);
	dynClear(dpeList);
	dynClear(dpeIdList);
	DebugTN("Retrieving elements for a batch");
	rc=fwDbGetData(cmd,data,true,dpesInLoop,makeDynInt(DPEL_INT, DPEL_STRING));

	if (rc == 1) {
	    // we will still have something to retrieve next time... 
	    finished=false; 
	} else if (rc != 0) {
	    fwDbCheckError(errTxt,cmd);
	    fwException_raise(exceptionInfo,"ERROR","Cannot get DB data\n"+errTxt,"");
	    DebugTN("ERROR","Could not get DB data",sql,errTxt);
	    break;
	}
	
	if (!dynlen(data)) {
	    DebugTN("No (more) properties to store...");
	    break;
	}
	
	dpeIdList=data[1];
	dpeList=data[2];
	DebugTN("We will process (another) "+dynlen(dpeList)+"/"+len+" dpes  (already processed "+dpesProcessed+")");
	
	string loopStr="["+(nLoops+1)+"/"+(int)(len/dpesInLoop+1)+"]";
	

	
	
	if (options & fwConfigurationDB_deviceConfig_VALUE) {
	    if (fwConfigurationDB_progress(fwConfigurationDB_OPER_SaveDevices,
		"Saving Values "+loopStr, 9.0+90.0*dpesProcessed/len, exceptionInfo,true)) break;
		
	    //bool storeIfAddrOut=false;
    	    //bool storeIfAddrIn=false;
	    bool storeIfAddrOut=true;
    	    bool storeIfAddrIn=false;
	    _fwConfigurationDB_savePropValuesToDB(dpeList, dpeIdList, exceptionInfo,
						storeIfAddrOut, storeIfAddrIn);


	}

	if (options & fwConfigurationDB_deviceConfig_ALERT) {
	    if (fwConfigurationDB_progress(fwConfigurationDB_OPER_SaveDevices,
		"Saving alerts "+loopStr, 9.0+90.0*(dpesProcessed+1*dynlen(dpeList)/9)/len, exceptionInfo,true)) break;
	    _fwConfigurationDB_savePropAlertsToDB(dpeList,dpeIdList, exceptionInfo);
	}

	if (options & fwConfigurationDB_deviceConfig_ADDRESS) {
	    if (fwConfigurationDB_progress(fwConfigurationDB_OPER_SaveDevices,
		"Saving addresses "+loopStr, 9.0+90.0*(dpesProcessed+2*dynlen(dpeList)/9)/len, exceptionInfo,true)) break;
	    _fwConfigurationDB_savePropAddressToDB(dpeList, dpeIdList, exceptionInfo);
	}

	if (options & fwConfigurationDB_deviceConfig_ARCHIVING) {
	    if (fwConfigurationDB_progress(fwConfigurationDB_OPER_SaveDevices,
		"Saving  archiving "+loopStr, 9.0+90.0*(dpesProcessed+3*dynlen(dpeList)/9)/len, exceptionInfo,true)) break;
	    _fwConfigurationDB_savePropArchivingToDB(dpeList, dpeIdList, exceptionInfo);
	}

	if (options & fwConfigurationDB_deviceConfig_DPFUNCTION) {
	    if (fwConfigurationDB_progress(fwConfigurationDB_OPER_SaveDevices,
		"Saving dpFunctions "+loopStr, 9.0+90.0*(dpesProcessed+4*dynlen(dpeList)/9)/len, exceptionInfo,true)) break;
	    _fwConfigurationDB_savePropDpFunctionToDB(dpeList, dpeIdList, exceptionInfo);
	}

	if (options & fwConfigurationDB_deviceConfig_CONVERSION) {
	    if (fwConfigurationDB_progress(fwConfigurationDB_OPER_SaveDevices,
		"Saving conversions "+loopStr, 9.0+90.0*(dpesProcessed+5*dynlen(dpeList)/9)/len, exceptionInfo,true)) break;
	    _fwConfigurationDB_savePropConversionToDB(dpeList, dpeIdList, exceptionInfo);
	}

	if (options & fwConfigurationDB_deviceConfig_PVRANGE) {
	    if (fwConfigurationDB_progress(fwConfigurationDB_OPER_SaveDevices,
		"Saving PV-Ranges "+loopStr, 9.0+90.0*(dpesProcessed+6*dynlen(dpeList)/9)/len, exceptionInfo,true)) break;
	    _fwConfigurationDB_savePropPVRangeToDB(dpeList, dpeIdList, exceptionInfo);
	}

	if (options & fwConfigurationDB_deviceConfig_SMOOTHING) {
	    if (fwConfigurationDB_progress(fwConfigurationDB_OPER_SaveDevices,
		"Saving Smoothing "+loopStr, 9.0+90.0*(dpesProcessed+7*dynlen(dpeList)/9)/len, exceptionInfo,true)) break;
	    _fwConfigurationDB_savePropSmoothingToDB(dpeList, dpeIdList, exceptionInfo);
	}

	if (options & fwConfigurationDB_deviceConfig_UNITANDFORMAT) {
	    if (fwConfigurationDB_progress(fwConfigurationDB_OPER_SaveDevices,
		"Saving Unit/Format "+loopStr, 9.0+90.0*(dpesProcessed+8*dynlen(dpeList)/9)/len, exceptionInfo,true)) break;
	    _fwConfigurationDB_savePropUnitAndFormatToDB(dpeList, dpeIdList, exceptionInfo);
	}
	
	if (fwConfigurationDB_progress(fwConfigurationDB_OPER_SaveDevices,
		"Saved properties "+loopStr, 9.0+90.0*(dpesProcessed+9*dynlen(dpeList)/9)/len, exceptionInfo,true)) break;

	dpesProcessed+=dynlen(dpeList);
	nLoops++;
	g_fwConfigurationDB_stats["PROCESS/#Processed items "]=dpesProcessed;
	g_fwConfigurationDB_stats["PROCESS/#Loops "]=nLoops;
	t2=getCurrentTime();    
	dt=t2-t1;
	g_fwConfigurationDB_stats["PROCESS/T elapsed"]=(float)period(dt)+0.001*milliSecond(dt);

    } //end of the big "while" loop


    fwDbFinishCommand(cmd);
    if (fwConfigurationDB_checkErrors(exceptionInfo,true)) return;

    DebugTN("All dpe processed...",dpesProcessed,len);
    
    if (fwConfigurationDB_progress(fwConfigurationDB_OPER_SaveDevices,
		"Committing transaction", 99.0, exceptionInfo,true)) return;
    
    DebugTN("Committing transaction");
    DebugTN("IMPLEMENTME: CHECK STATUS OF TRANSACTION COMMIT!");    
    fwDbCommitTransaction(g_fwConfigurationDB_DBConnection); 
    DebugTN("FINISHED/Committed saving the configuration");

    fwConfigurationDB_closeProgressDialog();

    time t2=getCurrentTime();    
    time dt=t2-t0;
    g_fwConfigurationDB_stats["PROCESS/T total "]=(float)period(dt)+0.001*milliSecond(dt);


    DebugTN("---------- STATISTICS -------------------");
    DebugTN(g_fwConfigurationDB_stats);
    DebugTN("-----------------------------------------");
//    mappingClear(g_fwConfigurationDB_stats);

}





/**********
 Lay out the data in temporary tables, check which devices exist, save the
 minimal hierarchy information into the ITEMS table - it generates ITEM_IDs, etc

 It expands the deviceList to include necessary hierarchical devices, 
 and checks if devices exist.

	
    Layout of CDB_API_PARAMS:
    I1 -> ITEM_ID
    I2 -> CITEM_ID
    I3 -> PARENT_ID
    I4 -> DPID (Hardware hierarchy)
    I5 -> REF ID (Logical hierarchy)
    I7 -> DPType ID
    I8 -> Flags that a device is new

    S1 -> DEVICE DPNAME
    S2 -> REF DPNAME (Logical hierarchy)
    S3 -> TYPE (DPTYPE)
    S4 -> DETAIL (MODEL)    
    S5 -> DEVICE NAME (short)
    S6 -> PARENT DPNAME
    S7 -> COMMENT

*/
void _fwConfigurationDB_saveItemsToDB(dyn_string deviceList, string hierarchyType,
    dyn_string &exceptionInfo)
{

    string sql;
    dyn_dyn_mixed data;
    dyn_mixed params;

    // check/resolve hierarchy;
    if (hierarchyType != fwDevice_HARDWARE && hierarchyType != fwDevice_LOGICAL) {
	fwException_raise(exceptionInfo,"ERROR","Unsupported hierarchy: "+hierarchyType,"");
	return;
    }

    dyn_dyn_mixed deviceListObject;

    DebugTN("Calling completeDevsInH");
    _fwConfigurationDB_completeDevicesInHierarchy(deviceList, hierarchyType,"", exceptionInfo);
    if (dynlen(exceptionInfo)) return;
    
    DebugTN("Sorting deviceList");
    dynSortAsc(deviceList);

    DebugTN("expanding to deviceListObject");
    fwConfigurationDB_expandToDeviceListObject(hierarchyType, deviceList,deviceListObject,exceptionInfo);
    if (dynlen(exceptionInfo)) return;

    DebugTN("Cleanup data-handling tables");
    fwDbRollbackTransaction(g_fwConfigurationDB_DBConnection);
    // do a cleanup of data-handling tables
    fwConfigurationDB_executeSqlSimple("DELETE FROM TMP_ITEM_PROPS",g_fwConfigurationDB_DBConnection,exceptionInfo);
    if (dynlen(exceptionInfo)) return;
    fwConfigurationDB_executeSqlSimple("DELETE FROM CDB_API_PARAMS",g_fwConfigurationDB_DBConnection,exceptionInfo);
    if (dynlen(exceptionInfo)) return;
    
    DebugTN("We start transaction");
    int rc=fwDbBeginTransaction(g_fwConfigurationDB_DBConnection);
    if (rc) {
	fwException_raise(exceptionInfo,"ERROR","Could not start DB transaction","");
	DebugTN("Could not start transaction!",rc,getLastError());
	return;
    }


    DebugTN("We chceck/create sys node; PLEASE REVIEW IT");
    _fwConfigurationDB_DBCheckCreateSystemNode(hierarchyType, exceptionInfo);
    if (dynlen(exceptionInfo)) { fwDbRollbackTransaction(g_fwConfigurationDB_DBConnection); return;}

    DebugTN("We check/save dptypes...");
    dyn_string dpTypes=deviceListObject[fwConfigurationDB_DLO_DPTYPE];
    dynUnique(dpTypes);
    dyn_int dpTypeIds;
    dyn_mixed dpTypeElements, dpTypeElementIds;
    time date=getCurrentTime();
    if (fwConfigurationDB_progress(fwConfigurationDB_OPER_SaveDevices,"Saving DPTypes", 2.0, exceptionInfo,true)) return;
    _fwConfigurationDB_checkSaveDpTypes(dpTypes,dpTypeIds,dpTypeElements, dpTypeElementIds, date, exceptionInfo);

    if (dynlen(exceptionInfo)) { fwDbRollbackTransaction(g_fwConfigurationDB_DBConnection); return;}
    DebugTN("Done saving dptypes");

    // do a cleanup of data-handling tables - saving of properties leaves something there (?)
    fwConfigurationDB_executeSqlSimple("DELETE FROM CDB_API_PARAMS",g_fwConfigurationDB_DBConnection,exceptionInfo);
    if (dynlen(exceptionInfo)) return;

    dynClear(data);
    if (hierarchyType==fwDevice_HARDWARE) {
	if (fwConfigurationDB_progress(fwConfigurationDB_OPER_SaveDevices,"Saving Device hierarchy", 4.0, exceptionInfo,true)) return;


	sql= " INSERT INTO CDB_API_PARAMS( S1, S3, S4, S5, S7, I4, S6) "+
                " VALUES ( :DPNAME, :DPTYPE, :DEVMODEL, :DEVNAME, :DPCOMMENT, :DPID, :PARENTDPNAME)";
	
	data[1] = deviceListObject[fwConfigurationDB_DLO_DPNAME];
	data[2] = deviceListObject[fwConfigurationDB_DLO_DPTYPE];
	data[3] = deviceListObject[fwConfigurationDB_DLO_MODEL];
	data[4] = deviceListObject[fwConfigurationDB_DLO_NAME];
	data[5] = deviceListObject[fwConfigurationDB_DLO_COMMENT];
	data[6] = deviceListObject[fwConfigurationDB_DLO_DPID];
	data[7] = deviceListObject[fwConfigurationDB_DLO_PARENTDPNAME];
//DebugTN("Executing...",sql);	
//DebugTN("WITH DATA:",data);
	_fwConfigurationDB_executeDBBulkCmd(sql, g_fwConfigurationDB_DBConnection, data, exceptionInfo, TRUE);
	if (dynlen(exceptionInfo)) { fwDbRollbackTransaction(g_fwConfigurationDB_DBConnection); return;}





    DebugTN("Calling PL/SQL's function to insert items");
    dynClear(params);
    params[1]=hierarchyType;
    sql="BEGIN fwConfigurationDB.saveItems(:hierarchy);END;";
    _fwConfigurationDB_executeDBCmd(sql,g_fwConfigurationDB_DBConnection, params, exceptionInfo);
    if (dynlen(exceptionInfo)) { 
	_fwConfigurationDB_showItemsInCDB_API_PARAMS("On error the data in CDB_API_PARAMS was");
	fwDbRollbackTransaction(g_fwConfigurationDB_DBConnection); 
	return;
	}

    DebugTN("Hardware hierarchy: items saved OK.");
	
    } else if (hierarchyType == fwDevice_LOGICAL) {
	if (fwConfigurationDB_progress(fwConfigurationDB_OPER_SaveDevices,"Saving Device hierarchy", 20.0, exceptionInfo,true)) return;
    
	DebugTN("We treat the logical now...");
	
	// the dpalias->dpname thing was not resolved yet... do it!
	for (int i=1;i<=dynlen(deviceListObject[fwConfigurationDB_DLO_DPNAME]);i++) {
	    string itemname=deviceListObject[fwConfigurationDB_DLO_DPNAME][i];
	    string dpname=dpAliasToName(itemname);
	    dpname=dpSubStr(dpname,DPSUB_SYS_DP);
	    deviceListObject[fwConfigurationDB_DLO_REFDP][i]=dpname;
	}
	                                               
	sql= " INSERT INTO CDB_API_PARAMS( S1, S2, S3, S4, S5, S6) "+
                " VALUES ( :DPNAME, :REFDPNAME, :DPTYPE, :MODEL, :NAME, :PARENTDPNAME)";

	data[1] = deviceListObject[fwConfigurationDB_DLO_DPNAME];
	data[2] = deviceListObject[fwConfigurationDB_DLO_REFDP];
	data[3] = deviceListObject[fwConfigurationDB_DLO_DPTYPE];
	data[4] = deviceListObject[fwConfigurationDB_DLO_MODEL];
	data[5] = deviceListObject[fwConfigurationDB_DLO_NAME];
	data[6] = deviceListObject[fwConfigurationDB_DLO_PARENTDPNAME];
	_fwConfigurationDB_executeDBBulkCmd(sql, g_fwConfigurationDB_DBConnection, data, exceptionInfo, TRUE);
	if (dynlen(exceptionInfo)) { fwDbRollbackTransaction(g_fwConfigurationDB_DBConnection); return;}

	DebugTN("Calling PL/SQL's function to insert items");
	dynClear(params);
	params[1]=hierarchyType;
	sql="BEGIN fwConfigurationDB.saveItems(:hierarchy);END;";
	_fwConfigurationDB_executeDBCmd(sql,g_fwConfigurationDB_DBConnection, params, exceptionInfo);
	if (dynlen(exceptionInfo)) { 
	    _fwConfigurationDB_showItemsInCDB_API_PARAMS("On error the data in CDB_API_PARAMS was");
	    fwDbRollbackTransaction(g_fwConfigurationDB_DBConnection); 
	    return;
	}
	DebugTN("Logical hierarchy: items saved OK.");
	if (fwConfigurationDB_progress(fwConfigurationDB_OPER_SaveDevices,"Saved Device hierarchy", 90.0, exceptionInfo,true)) return;
    }

}


/** helper function that shows the devices included in configuration, starting from specified topDevice

    if configurationName is empty, it takes the devices of "ITEMS" table (i.e. "all")

    topNode should specify the system name for hardware hierarchy; if left empty, all devices from all
    systems are returned

*/
void fwConfigurationDB_getDevicesInConfiguration(string configurationName,
    string hierarchyType,
    string topNode,
    dyn_dyn_mixed &deviceListObject,
    dyn_string &exceptionInfo)
{
    // we make a query in such a way that the output is directly usable as deviceListObject (without last few columns)
    string sql;
    dyn_dyn_mixed data;
    mapping params;

    sql="SELECT i.DPNAME DPNAME, i.TYPE DPTYPE, i.NAME NAME, null DTYPE,i.DETAIL MODEL,i.DESCRIPTION CMNT,i.ID ITEMID,i.PARENT PARENTID, j.DPNAME PARENTDPNAME, null dDPID";
    
    if (configurationName!="" && hierarchyType==fwDevice_LOGICAL)  sql+=" ,k.DPNAME REFDPNAME, rf.ref_id REFID ";
    else sql+=" , NULL REFDPNAME, NULL REFID ";

    sql+=",null REFSTATUS";
    
    if (topNode!="") {
	sql="WITH IT AS ( "+
	    " SELECT * "+
	    " from items it start with it.dpname=:topNode connect by prior it.id=it.parent) "+
	    sql +
	    " FROM IT I, ITEMS J ";

	params["topNode"]=topNode;

    } else {
	sql+=" FROM ITEMS i, ITEMS j ";
    }

    if (configurationName!="" && hierarchyType==fwDevice_HARDWARE)  sql+=" ,CONFIG_ITEMS_NEW CI ";
    else if (configurationName!="" && hierarchyType==fwDevice_LOGICAL)  sql+=" ,REFERENCES RF, ITEMS K ";

    sql+= " WHERE (j.id(+)=i.parent) and i.hver=(SELECT HVER FROM HIERARCHIES WHERE HTYPE=:htype) ";
    params["htype"]=hierarchyType;

    if (configurationName!="" && hierarchyType==fwDevice_HARDWARE)  {
	sql += 	" AND CI.ITEM_ID=i.ID "+
		" AND CI.VALID_TO IS NULL "+
		" AND CI.TAG_ID = (SELECT CONF_ID FROM CONFIG_DESC WHERE CONF_TAG=:confName)";
	params["confName"]=configurationName;
    } else if (configurationName!="" && hierarchyType==fwDevice_LOGICAL)  {
	sql += 	" AND RF.ID=i.ID "+
		" AND K.ID=RF.REF_ID "+
		" AND RF.VALID_TO IS NULL "+
		" AND RF.REFVER = (SELECT CONF_ID FROM CONFIG_DESC WHERE CONF_TAG=:confName)";
	params["confName"]=configurationName;
    }
    
    sql+= " ORDER BY DPNAME ";
    
    //DebugTN(sql,params);
    _fwConfigurationDB_executeDBQueryWithParams(sql,g_fwConfigurationDB_DBConnection, params, data, exceptionInfo,13,TRUE);
    if (dynlen(exceptionInfo)) return;
    deviceListObject=data;

}

void fwConfigurationDB_getPropsOfDeviceInConfiguration(string configurationName,
    string deviceName,
    dyn_string &propNames,
    dyn_int &ipropIds,
    dyn_string &exceptionInfo)
{
    dyn_dyn_mixed data;
    mapping params;    
    string sql="SELECT PROP_NAME,iprop_id FROM V_ITEM_PROPERTIES WHERE item_dpname=:dpname and tag=:configName ORDER BY IPROP_ID";
    params["dpname"]=deviceName;
    params["configName"]=configurationName;
    _fwConfigurationDB_executeDBQueryWithParams(sql,g_fwConfigurationDB_DBConnection, params, data, exceptionInfo,2,TRUE);
    if (dynlen(exceptionInfo)) return;
    if (dynlen(data)) {
	propNames=data[1];
	ipropIds=data[2];
    }
}