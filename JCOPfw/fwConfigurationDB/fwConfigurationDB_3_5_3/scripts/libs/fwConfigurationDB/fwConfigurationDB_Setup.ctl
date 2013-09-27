/**@file

This package contains setup  functions of the Configuration Database tool

@author Piotr Golonka (EN/ICE-SCD)
@date   February 2012
*/

global string _fwConfigurationDB_fileVersion_fwConfigurationDB_Setup_ctl="3.5.3";


float fwConfigurationDB_verifyDBSchema(dbConnection dbCon, dyn_string &exceptionInfo)
{
    dyn_dyn_mixed aRecords;
    string sql = "SELECT count(*) FROM ALL_VIEWS WHERE VIEW_NAME='V_CONFDB' "+
                 " AND OWNER=sys_context('USERENV','CURRENT_SCHEMA')";
    _fwConfigurationDB_executeDBQuery(sql,dbCon, aRecords, exceptionInfo);
    if (dynlen(exceptionInfo)) {
	fwException_raise(exceptionInfo,"ERROR","Cannot determine if fwConfigurationDB schema is installed","");
	return -1.0;
    }
    int installed=aRecords[1][1];
    if (installed==0) return 0.0;//// means: not installed

    dynClear(aRecords);
    string schemaVersionSql="SELECT SCHEMA_VERSION FROM V_CONFDB";
    _fwConfigurationDB_executeDBQuery(schemaVersionSql,dbCon, aRecords, exceptionInfo);
    if (dynlen(exceptionInfo)) return -1.0;
    if (dynlen(aRecords)<1) {
	fwException_raise(exceptionInfo,"ERROR","Cannot determine the version fwConfigurationDB schema","");
	return -1.0;    
    }
    
    float schemaVer=aRecords[1][1];
    return schemaVer;
}


void fwConfigurationDB_createDBSchema(dbConnection dbCon, dyn_string &exceptionInfo,bool dropExistingSchema=FALSE)
{

    if (dropExistingSchema) {
        DebugN("Dropping existing schema");
        fwConfigurationDB_dropDBSchema(dbCon, exceptionInfo);
    }


    _fwConfigurationDB_executeSqlFromFile(dbCon,"fwConfigurationDB_createSchema.sql",
                                          "CREATE DB SCHEMA", exceptionInfo,TRUE);
    if (dynlen(exceptionInfo)) return;

    DebugN("Database schema succesfully created");
}


/** This one does not stop upon an error, which may be e.g. missing table, etc...
*/
void fwConfigurationDB_dropDBSchema(dbConnection dbCon, dyn_string &exceptionInfo)
{
    _fwConfigurationDB_executeSqlFromFile(dbCon,"fwConfigurationDB_dropSchema.sql",
                                          "DROP DB SCHEMA", exceptionInfo,TRUE);
}



void fwConfigurationDB_updateDBSchema(dbConnection dbCon, dyn_string &exceptionInfo)
{
    float curSchemaVersion=fwConfigurationDB_verifyDBSchema(dbCon, exceptionInfo);
    if (dynlen(exceptionInfo)) return;

    if (curSchemaVersion==0.0) {
	DebugN("No schema exist - nothing to update.");
	return; // nothing to do here...
    }

    if (curSchemaVersion==fwConfigurationDB_minimalDBSchemaVersion) {
	DebugN("DB Schema is already up to date.");
	return; // nothing to do here...
    }
    if (curSchemaVersion>fwConfigurationDB_minimalDBSchemaVersion) {
	fwException_raise(exceptionInfo,"ERROR","The schema version in the DB ("+curSchemaVersion+")"+
			" is newer than the one supported by this version of the ConfigurationDB tool ("+
			fwConfigurationDB_minimalDBSchemaVersion+"). You need to upgrade the ConfigurationDB component.","");
	return;
    }

    string filename;
    sprintf(filename,"fwConfigurationDB_upgradeSchema_%.2f-%.2f.sql",
		curSchemaVersion,
		fwConfigurationDB_minimalDBSchemaVersion);
    _fwConfigurationDB_executeSqlFromFile(dbCon,filename,
                                          "UPDATE DB SCHEMA", exceptionInfo,TRUE);
    if (dynlen(exceptionInfo)) return;

}


void fwConfigurationDB_createSetup(string setupName,dyn_string &exceptionInfo, bool noCheck=FALSE)
{

    if (setupName=="") {
        fwException_raise(exceptionInfo,"ERROR","Setup name cannot be empty","");
        return;
    }

    string dpname=fwConfigurationDB_ConfigurationSetupPrefix+setupName;

    if (noCheck==FALSE) {
	dyn_string setupNames, setupDPs;
	string defaultSetupName, defaultSetupDP;
	fwConfigurationDB_getSetups(setupNames, setupDPs,
                                defaultSetupName, defaultSetupDP,
                                exceptionInfo);
	if (dynlen(exceptionInfo)) return;

	if (dynContains(setupNames,setupName)) {
    	    fwException_raise(exceptionInfo,"ERROR","Setup with this name already exists","");
    	    return;
	};

	if (!dpIsLegalName(dpname)) {
    	    fwException_raise(exceptionInfo,"ERROR","The name for the setup is invalid.","");
    	    return;
	};

    }

    int rc=dpCreate(dpname,"_FwConfigurationDB_setup");

    if (rc) {
        fwException_raise(exceptionInfo,"ERROR","Cannot create new setup","");
        return;
    }

    rc=dpSet(dpname+".version",fwConfigurationDB_version);
    if (rc) {
        fwException_raise(exceptionInfo,"ERROR","Cannot initialize new setup","");
        return;
    }

}



/**
Returns the list of configured db connections
 */
void fwConfigurationDB_getDBConnectionList(dyn_string &dbConnectionNames, dyn_string &dbConnectionDPs,
                                        dyn_string &exceptionInfo, bool getRemote=FALSE)
{
    if (getRemote) {
        dbConnectionDPs=dpNames("*:"+fwConfigurationDB_ConnectionNamePrefix+"*","_FwDBConnection");
        dynSortAsc(dbConnectionDPs);
	for (int i=1;i<=dynlen(dbConnectionDPs);i++){
    	    string dpname=dpSubStr(dbConnectionDPs[i],DPSUB_DP);
    	    string sys=dpSubStr(dbConnectionDPs[i],DPSUB_SYS);
    	    if (sys==getSystemName()) sys="";
    	    dbConnectionNames[i]=sys+substr(dpname,strlen(fwConfigurationDB_ConnectionNamePrefix));
	}
    
    } else {
        dbConnectionDPs=dpNames(fwConfigurationDB_ConnectionNamePrefix+"*","_FwDBConnection");
        dynSortAsc(dbConnectionDPs);
	for (int i=1;i<=dynlen(dbConnectionDPs);i++){
    	    string dpname=dpSubStr(dbConnectionDPs[i],DPSUB_DP);
    	    dbConnectionNames[i]=substr(dpname,strlen(fwConfigurationDB_ConnectionNamePrefix));
	}
    }
}


void fwConfigurationDB_getDBConnection(string dbConnectionName,
					string &description, string &dbType, string &dbName,
					string &userName, string &password, string &connectString,
					string &schemaName, dyn_string &exceptionInfo)
{
    string DPName = fwConfigurationDB_ConnectionNamePrefix + dbConnectionName;
    
    if (strpos(dbConnectionName,":")>0) {
	// connection info stored on another system!
	dyn_string ds=strsplit(dbConnectionName,":");
	DPName=ds[1]+":"+fwConfigurationDB_ConnectionNamePrefix +ds[2];
    }
    
    if (!dpExists(DPName)) {
	fwException_raise(exceptionInfo,"ERROR","DB Connection: "+dbConnectionName+" does not exist","");
	return;
    }
    float version;
    int rc=dpGet(   DPName+".description",description,
		    DPName+".dbUser",userName,
		    DPName+".dbSchema",schemaName,
		    DPName+".dbName",dbName,
		    DPName+".dbType",dbType,
		    DPName+".dbPassword",password,
		    DPName+".version",version,
		    DPName+".connectString",connectString);

    if (rc) {
	fwException_raise(exceptionInfo,"ERROR", "Cannot get database connection information","");
	return;
    }

//    if (version<fwConfigurationDB_version) {
//	DebugN("WARNING: Outdated verion of DBConnection "+dbConnectionName+" ("+version+"). Expect problems with the connect string");
//	return;
//    }

}


//#12624
string fwConfigurationDB_createDBConnection(string dbConnectionName,
					string description, string dbType, string dbName,
					string userName, string password, string connectString,
					string schemaName, dyn_string &exceptionInfo)
{

    if (dbConnectionName=="") {
	fwException_raise(exceptionInfo,"ERROR","Connection name cannot be empty","");
	return;
    }

    string dpName=fwConfigurationDB_ConnectionNamePrefix+dbConnectionName;
    string sys=getSystemName();
    if (strpos(dbConnectionName,":")>0) {
	// connection info stored on another system!
	dyn_string ds=strsplit(dbConnectionName,":");
	dpName=fwConfigurationDB_ConnectionNamePrefix +ds[2];
	sys=ds[1]+":";
    }

    if (!dpIsLegalName(dpName)) {
        fwException_raise(exceptionInfo,"ERROR","The name for the connection is invalid",fwConfigurationDB_ERROR_InvalidDataPointName);
        return "";
    }
    int sysNum=getSystemId(sys);
    if (sysNum<=0){
        fwException_raise(exceptionInfo,"ERROR","The system for the connection is invalid",fwConfigurationDB_ERROR_InvalidDataPointName);
        return "";    
    }

    if (dpExists(sys+dpName)){
	fwException_raise(exceptionInfo,"ERROR", "Database connection "+dbConnectionName+" already exists","");
	return "";
    }

    int rc=dpCreate(dpName,"_FwDBConnection",sysNum);
    if (rc) {
	fwException_raise(exceptionInfo,"ERROR","Cannot create database connection","");
	return "";
    }


    fwConfigurationDB_modifyDBConnection(dbConnectionName, description, dbType, dbName, userName,
					password, connectString, schemaName, exceptionInfo);
    return dpName;

}

//#12624
/** Modifies specified db connection

Warning; if empty password is specified, the password will not be changed (it is left as it is)
@param password needs to be specified in unencrypted form(!)
*/
void fwConfigurationDB_modifyDBConnection(string dbConnectionName,
					string description, string dbType, string dbName,
					string userName, string password, string connectString,
                                        string schemaName, dyn_string &exceptionInfo)
{
    string DPName = fwConfigurationDB_ConnectionNamePrefix + dbConnectionName;
    if (strpos(dbConnectionName,":")>0) {
	// connection info stored on another system!
	dyn_string ds=strsplit(dbConnectionName,":");
	DPName=ds[1]+":"+fwConfigurationDB_ConnectionNamePrefix +ds[2];
    }

    if (!dpExists(DPName)) {
	fwException_raise(exceptionInfo,"ERROR","DB Connection: "+dbConnectionName+" does not exist","");
	return;
    }

    int rc=dpSetWait(DPName+".version",fwConfigurationDB_version,
		    DPName+".description",description,
		    DPName+".dbUser",userName,
		    DPName+".dbSchema",schemaName,
		    DPName+".dbName",dbName,
		    DPName+".dbType",dbType,
		    DPName+".connectString",connectString);

    if (password!="") {
	string pwd=password;
	if (strpos(strtolower(connectString),"enc_pwd=")>=0) {
	    string encPwd=fwDbEncryptPassword(password);
	    pwd=encPwd;
	}
	rc=rc+dpSetWait(DPName+".dbPassword",pwd);
    }

    if (rc) {
	fwException_raise(exceptionInfo,"ERROR", "Cannot update database connection","");
	return;
    }

}

void fwConfigurationDB_dropDBConnection(string dbConnectionName,
                                        dyn_string &exceptionInfo)
{
    string DPName = fwConfigurationDB_ConnectionNamePrefix + dbConnectionName;
    if (strpos(dbConnectionName,":")>0) {
	// connection info stored on another system!
	dyn_string ds=strsplit(dbConnectionName,":");
	DPName=ds[1]+":"+fwConfigurationDB_ConnectionNamePrefix +ds[2];
    }

    if (!dpExists(DPName)) {
	fwException_raise(exceptionInfo,"ERROR","DB Connection: "+dbConnectionName+" does not exist","");
	return;
    }

    int rc=dpDelete(DPName);

    if (rc) {
	fwException_raise(exceptionInfo,"ERROR", "Cannot delete database connection "+dbConnectionName,"");
	return;
    }

}

void _fwConfigurationDB_getDefaultConnectString(string dbType, string &defaultConnectString,
        dyn_string &exceptionInfo)
{
    defaultConnectString="";
    if (dbType!="ORACLE") {
        fwException_raise(exceptionInfo,"ERROR","Database connection type "+dbType+" not supported","");
        return;
    }

//    defaultConnectString="driver=<DRIVER>;uid=<USER>;pwd=<PASSWORD>;database=<DBNAME>;";
    defaultConnectString="driver=<DRIVER>;uid=<USER>;enc_pwd=<PASSWORD>;database=<DBNAME>;";

/*
    if(_UNIX) {
        if (dbType=="ORACLE")
            defaultConnectString="driver=<DRIVER>;server=localhost;uid=<USER>;pwd=<PASSWORD>;database=<DBNAME>;";
        else if (dbType=="ODBC")
            defaultConnectString="driver=QODBC3;DSN=<DBNAME>;UID=<USER>;PWD=<PASSWORD>;";
    } else {
        if (dbType=="ORACLE") {
            defaultConnectString="driver=<DRIVER>;dbq=<DBNAME>;Uid=<USER>;Pwd=<PASSWORD>;";
	    // append switch for pre-fecth
	    defaultConnectString=defaultConnectString+"PFC=200;";
	    // append switch that deactivates query timeout
	    defaultConnectString=defaultConnectString+"QTO=F;";
        } else if (dbType=="ODBC")
            defaultConnectString="DSN=<DBNAME>;UID=<USER>;PWD=<PASSWORD>";
    }
*/
}



void _fwConfigurationDB_DBCheckCreateSystemNode(string hierarchyType, dyn_string &exceptionInfo, string system="")
{
    string systemName;
    if (system=="") systemName=getSystemName();
    else systemName=system;
    
    if (hierarchyType==fwDevice_LOGICAL) systemName="/";

    string queryRootNodeSql="SELECT ID FROM ITEMS WHERE NAME=\'"+systemName+"\'"+
        " AND HVER="+g_fwConfigurationDB_DBHierarchyIDs[hierarchyType];
    dyn_dyn_mixed aRootNode;
    _fwConfigurationDB_executeDBQuery(queryRootNodeSql,g_fwConfigurationDB_DBConnection, aRootNode, exceptionInfo);
    if (dynlen(exceptionInfo)) return;
    if (dynlen(aRootNode)>0) return;

    // otherwise: create it...
    string insertRootNodeSql="INSERT INTO ITEMS (HVER,ID,NAME,TYPE,DETAIL,DPNAME,DESCRIPTION) SELECT :HVER,ITEMS_ID_SEQ.NextVal,:NAME,:TYPE,:DETAIL,:DPNAME,:DSC FROM DUAL";

    mapping params;
    params["HVER"]=g_fwConfigurationDB_DBHierarchyIDs[hierarchyType];
    params["TYPE"]="SYSTEM";
    params["DETAIL"]="SYSTEM";
    if (hierarchyType==fwDevice_LOGICAL) {
	params["NAME"]=systemName;
	params["DPNAME"]="";
	params ["DSC"]="Top of unified LOGICAL hierarchy";
    } else {
	params["NAME"]=systemName;
	params["DPNAME"]=systemName;
	params["DSC"]="Top of HARDWARE hierarchy for "+systemName;
    }
    
    
//    DebugTN("We execute:",insertRootNodeSql,params);
    _fwConfigurationDB_executeDBCmd(insertRootNodeSql,g_fwConfigurationDB_DBConnection, params, exceptionInfo);
    if (dynlen(exceptionInfo)) {fwDbRollbackTransaction(g_fwConfigurationDB_DBConnection);return;};
        
    DebugTN("created root node in DB for "+systemName+" hierarchy:"+hierarchyType);
}




/**
    Performs sanity checks of the database schema, signals errors,
    tries to recover as much as possible.
*/
void _fwConfigurationDB_DBSchemaSanityCheck(dbConnection dbCon, dyn_string &exceptionInfo)
{
    float schemaVersion=fwConfigurationDB_verifyDBSchema(dbCon, exceptionInfo);
    if (dynlen(exceptionInfo)) return;
    fwConfigurationDB_currentDBSchemaVersion=schemaVersion;


    if (schemaVersion==0.0) {
	fwException_raise(exceptionInfo,"ConfigurationDB ERROR","No database schema","");
        return;
    }

    if (schemaVersion<fwConfigurationDB_minimalDBSchemaVersion) {
	fwException_raise(exceptionInfo,"ConfigurationDB ERROR",
    		"Database schema version="+schemaVersion+" differs from the required version="+fwConfigurationDB_minimalDBSchemaVersion,
                "");
	return;
    };

    // now, determine the current identifiers of the hierarchies
    // current has a null "VALID_TO" field...
    string sql="SELECT HTYPE,HVER FROM HIERARCHIES";
    dyn_dyn_mixed aRecords;
    _fwConfigurationDB_executeDBQuery(sql,dbCon,aRecords, exceptionInfo,2,TRUE);
    if (dynlen(exceptionInfo)) return;

    int nextHverId=1;
    bool insertedNew=FALSE;
    // react to empty return
    if (dynlen(aRecords)<2) {
	aRecords=makeDynMixed(makeDynMixed(),makeDynMixed());
    } else {
	nextHverId=dynMax((dyn_int)aRecords[2])+1;
    }
    
    if (!dynContains(aRecords[1],fwDevice_HARDWARE)) {
	sql="INSERT INTO HIERARCHIES(HVER,HTYPE,VALID_FROM) VALUES("+nextHverId+",'"+fwDevice_HARDWARE+"',SYSDATE)";
	fwConfigurationDB_executeSqlSimple(sql, dbCon, exceptionInfo);
	if (dynlen(exceptionInfo)) return;
	nextHverId++;
	insertedNew=TRUE;
    }

    if (!dynContains(aRecords[1],fwDevice_LOGICAL)) {
	sql="INSERT INTO HIERARCHIES(HVER,HTYPE,VALID_FROM) VALUES("+nextHverId+",'"+fwDevice_LOGICAL+"',SYSDATE)";
	fwConfigurationDB_executeSqlSimple(sql, dbCon, exceptionInfo);
	if (dynlen(exceptionInfo)) return;
	nextHverId++;    
	insertedNew=TRUE;

    }

    if (!dynContains(aRecords[1],"FSM")) {
    	sql="INSERT INTO HIERARCHIES(HVER,HTYPE,VALID_FROM) VALUES("+nextHverId+",'FSM',SYSDATE)";
	fwConfigurationDB_executeSqlSimple(sql, dbCon, exceptionInfo);
	if (dynlen(exceptionInfo)) return;
	nextHverId++;
	insertedNew=TRUE;

    }

    if (insertedNew) {
	// we need to reread...
	
	sql="SELECT HTYPE,HVER FROM HIERARCHIES WHERE VALID_TO IS NULL";
	dynClear(aRecords);
	_fwConfigurationDB_executeDBQuery(sql,dbCon,aRecords, exceptionInfo,2,TRUE);
	if (dynlen(exceptionInfo)) return;
	if (dynlen(aRecords)<1) { fwException_raise(exceptionInfo,"ERROR","Cannot initialize database schema","");return;};
    }
    
    mapping hierarchies;
    // populate Hierarchy ID information:
    for (int i=1;i<=dynlen(aRecords[1]);i++) hierarchies[aRecords[1][i]]=aRecords[2][i];
    if (!mappingHasKey(hierarchies, fwDevice_HARDWARE)) {
        fwException_raise(exceptionInfo,"ERROR",
                          "Hardware hierarchy not defined inside the configuration database ","");
        return;
    }
    if (!mappingHasKey(hierarchies, fwDevice_LOGICAL)) {
        fwException_raise(exceptionInfo,"ERROR",
                          "Logical hierarchy not defined inside the configuration database ","");
        return;
    }

    g_fwConfigurationDB_DBHierarchyIDs=hierarchies;

}






//__________________________________________________________________________
/**
 * @name Recipe Type functions

 These functions are used in context of recipe types.
 Recipe type uses RTdata object described in subsection @ref RTData


 * @{
 */


/** creates an empty recipe type with given name and description

@param recipeType       specifies the name of the recipe type
@param recipeComment    specifies the description
@param exceptionInfo    standard exception handling variable

@ingroup RecipeTypeFunctions
 */
void fwConfigurationDB_createRecipeType(string recipeType, string recipeComment, dyn_string &exceptionInfo)
{
    int rc;
    string dpName=fwConfigurationDB_RecipeTypeDpPrefix+recipeType;
    if (dpExists(dpName)) {
    fwException_raise(exceptionInfo,"ERROR","Recipe type: "+recipeType+" already exists.","");
        return;
    };

    if (!dpIsLegalName(dpName)) {
        fwException_raise(exceptionInfo,"ERROR","The name for the recipe type is invalid","");
        return;
    };

    rc = dpCreate(dpName,"_FwRecipeTypeDescriptor");

    if (rc) {
        fwException_raise(exceptionInfo,"ERROR","Could not create recipe type "+dpName,"");
        return;
    };

    rc=dpSet(dpName+".Description",recipeComment);
    if (rc) {
        fwException_raise(exceptionInfo,"ERROR","Could not set comment for recipe type "+recipeType,"");
        return;
    };

}

/** deletes a recipe type

@param recipeType       specifies the name of the recipe type
@param exceptionInfo    standard exception handling variable

@ingroup RecipeTypeFunctions
 */
void fwConfigurationDB_deleteRecipeType(string recipeType, dyn_string &exceptionInfo)
{
    string dpName=fwConfigurationDB_RecipeTypeDpPrefix+recipeType;
    if (!dpExists(dpName)) {
	fwException_raise(exceptionInfo,"ERROR","Recipe type: "+recipeType+
                      " does not exist.",fwConfigurationDB_ERROR_NoRecipeType);
        return;
    };

    if (recipeType==_GfwConfigurationDB_defaultRecipeType) {
        fwException_raise(exceptionInfo,"ERROR","You may not delete the default recipe type","");
        return;
    };

    dyn_string RTypes;
    int rc=dpGet(dpName+".RecipeTypeList",RTypes);
    if (rc) {
        fwException_raise(exceptionInfo,"ERROR","Cannot resolve the contents of recipe type "+recipeType,"");
        return;    
    }
    
    for (int i=1;i<=dynlen(RTypes);i++) {
        string recipeType=RTypes[i];
	rc=dpDelete(recipeType);
	if (rc) {
    	    fwException_raise(exceptionInfo,"ERROR","Could not delete data of recipe type "+dpName,"");
    	}

    }
    
    rc = dpDelete(dpName);
    if (rc) {
        fwException_raise(exceptionInfo,"ERROR","Could not delete recipe type "+dpName,"");
        return;
    };

    // maybe we should also delete all parts ...
}

/** returns the list of available recipe types

@param recipeTypeNames      on return contains the list of recipe type names
@param recipeTypeComments   on return contains the list of recipe type comments
@param exceptionInfo        standard exception handling variable
@param systemName	    allows to search for recipe types on remote systems
@ingroup RecipeTypeFunctions
 */
void fwConfigurationDB_getRecipeTypes(dyn_string &recipeTypeNames, dyn_string &recipeTypeComments,
                                      dyn_string &exceptionInfo, string systemName="")
{
    dynClear(recipeTypeNames);
    dynClear(recipeTypeComments);
    
    
    if (systemName!="") {
	int sysid=getSystemId(systemName);
        if (sysid==-1) {
    	    fwException_raise(exceptionInfo,"ERROR in getRecipeTypes",
        	"No such system "+systemName , "");
    	    return ;
        }
    }

    dyn_string recipeTypeDps=dpNames(systemName+fwConfigurationDB_RecipeTypeDpPrefix+"*","_FwRecipeTypeDescriptor");
    for (int i=1;i<=dynlen(recipeTypeDps);i++) {
        string rtname=dpSubStr(recipeTypeDps[i],DPSUB_DP);
        rtname=substr(rtname,strlen(fwConfigurationDB_RecipeTypeDpPrefix));
        string rtcomment;
        int rc = dpGet(recipeTypeDps[i]+".Description",rtcomment);
        if (rc) {
        fwException_raise(exceptionInfo,"ERROR","Could not get description for recipe type: "+rtname,"");
            return;
        }
        dynAppend(recipeTypeNames,rtname);
        dynAppend(recipeTypeComments,rtcomment);
    };
}

/** returns the recipe types that contain descriptions for certain dp type

@param dpType		datapoint type for which the recipe types are queried
@param recipeTypeNames	on return contains the list of recipe type names
@param exceptionInfo	standard exception handling variable

@ingroup RecipeTypeFunctions
 */
void fwConfigurationDB_findRecipeTypes(string dpType,dyn_string &recipeTypeNames,dyn_string &exceptionInfo, string systemName="")
{

    if (systemName!="") {
	int sysid=getSystemId(systemName);
        if (sysid==-1) {
    	    fwException_raise(exceptionInfo,"ERROR in findRecipeTypes",
        	"No such system "+systemName , "");
    	    return ;
        }
    }


    dynClear(recipeTypeNames);
    dyn_string rtDps=dpNames(systemName+"*","_FwRecipeTypeDescriptor");
    for (int i=1;i<=dynlen(rtDps);i++) {
	dyn_string ds=strsplit(rtDps[i],"/");
	if (dynlen(ds)<2) continue;
	string rtName=ds[2];
	dyn_string dptlist;
	dpGet(rtDps[i]+".RecipeTypeList",dptlist);
	string pattern=fwConfigurationDB_RecipeTypeDpPrefix+"*/"+dpType;
	if (dynlen(dynPatternMatch(pattern,dptlist))) {
		dynAppend(recipeTypeNames,rtName);
	}
    }
}



void _fwConfigurationDB_getRTDescription(string recipeType, string &description, dyn_string &exceptionInfo)
{
    string dpName=fwConfigurationDB_RecipeTypeDpPrefix+recipeType;
    if (!dpExists(dpName)) {
    fwException_raise(exceptionInfo,"ERROR","Recipe type: "+recipeType+
                      " does not exist.",fwConfigurationDB_ERROR_NoRecipeType);
        return;
    };
    dpGet(dpName+".Description",description);
}

void _fwConfigurationDB_setRTDescription(string recipeType, string description, dyn_string &exceptionInfo)
{
    string dpName=fwConfigurationDB_RecipeTypeDpPrefix+recipeType;
    if (!dpExists(dpName)) {
    fwException_raise(exceptionInfo,"ERROR","Recipe type: "+recipeType+
                      " does not exist.",fwConfigurationDB_ERROR_NoRecipeType);
        return;
    };
    dpSet(dpName+".Description",description);
}


void _fwConfigurationDB_getRecipeTypeData(string recipeType, dyn_dyn_string &RTData, dyn_string &exceptionInfo)
{
    int rc;
    dyn_string RTypes;

    dynClear(RTData);
    string dpName=fwConfigurationDB_RecipeTypeDpPrefix+recipeType;
    if (!dpExists(dpName)) {
    fwException_raise(exceptionInfo,"ERROR","Recipe type: "+recipeType+
                      " does not exist.",fwConfigurationDB_ERROR_NoRecipeType);
        return;
    };

    rc=dpGet(dpName+".RecipeTypeList",RTypes);

    for (int i=1;i<=dynlen(RTypes);i++) {
        string recipeType=RTypes[i];
        if (!dpExists(recipeType)) {
            fwException_raise(exceptionInfo,"WARNING",
                              "Recipe Type "+recipeType+" is missing.","");
        };

        string devType,dpType;
        dyn_string saveValue,saveAlert;


        rc=dpGet(recipeType+".DPType",dpType,
                 recipeType+".SavePropertyValue",saveValue,
                 recipeType+".SaveAlert",saveAlert);
        if (rc) {
            fwException_raise(exceptionInfo,"ERROR",
                              "Cannot load Recipe Type partial info from: "+recipeType,"");
        }
        // check if the actual DP Type exists in the system (partial bugfix #12621)
        if (dynlen(dpTypes(dpType))==0) {
    	 // suppress the message upon request from Clara Gaspar:
        /*
            DebugN("WARNING in getRecipeTypeData(): dpType "+dpType+"\n"+
                    "       is a part of recipe type "+recipeType+"\n"+
                    "       but it is not defined in this system. Skipping it.");
    	*/
            continue;
        }
        int i0=dynlen(RTData);
        _fwConfigurationDB_RTAddToModel(dpType,RTData,exceptionInfo);
        if (dynlen(exceptionInfo)) return;
        int i1=dynlen(RTData);
        for(int j=i0+1;j<=i1;j++) {
            int idx=dynContains(saveValue,RTData[j][3]);
            if (idx>0) RTData[j][5]=TRUE;
            idx=dynContains(saveAlert,RTData[j][3]);
            if (idx>0) RTData[j][6]=TRUE;
        }
    }
}

/** Modifies specified recipe type

@param recipeType the name of the recipe type
@param RTData an object holding recipe type definition, in the following format:
    (i indicating subsequent "rows" of recipe type definition)
    RTData[i][1] : (not used in this function)
    RTData[i][2] : DPType name
    RTData[i][3] : DPElement name
    RTData[i][4] : (not used in this function)
    RTData[i][5] : Save value for this element: "TRUE"/"FALSE"
    RTData[i][6] : Save alert for this element: "TRUE"/"FALSE"
@param exceptionInfo standard exception handling variable

*/
void _fwConfigurationDB_setRecipeTypeData(string recipeType, dyn_dyn_string RTData, dyn_string &exceptionInfo)
{
    int rc;

    string dpName=fwConfigurationDB_RecipeTypeDpPrefix+recipeType;
    if (!dpExists(dpName)) {
    fwException_raise(exceptionInfo,"ERROR","Recipe type: "+recipeType+
                      " does not exist.",fwConfigurationDB_ERROR_NoRecipeType);
        return;
    };

    // at first: let's form the list of recipe-type-per-device-type:
    dyn_string rt_dptypes;   // will hold the list of  dptypes
    dyn_string rt_datapoints; // will hold recipe-type datapoints for them

    for (int i=1;i<=dynlen(RTData);i++) {
        if (!dynContains(rt_dptypes,RTData[i][2])){
            dynAppend(rt_dptypes,RTData[i][2]);
            dynAppend(rt_datapoints,"");
        }
    }

    // get the datapoints that already exist...
    dyn_string RTList;
    rc=dpGet(dpName+".RecipeTypeList",RTList);
    if (rc) {
        fwException_raise(exceptionInfo,"ERROR",
                          "Cannot get the recipe type information from:"+dpName,"");
        return;
    };
    for (int i=1;i<=dynlen(RTList);i++) {
        string dpType;
        dpGet(RTList[i]+".DPType",dpType);
        int idx=dynContains(rt_dptypes,dpType);
        if (idx) {
            rt_datapoints[idx]=RTList[i];
        };
    };

    dyn_string newRTList;
    // and create the ones that does not yet exist
    // the ones with "" in rt_datapoints haven't the dp yet
    for (int i=1;i<=dynlen(rt_datapoints);i++) {
        if (rt_datapoints[i]=="") {
            string rdpname=dpName+"/"+rt_dptypes[i];
            if (!dpExists(rdpname)) {
                rc=dpCreate(rdpname,"_FwRecipeType");
                if (rc) {
                    fwException_raise(exceptionInfo,"ERROR",
                                      "Cannot create recipe-type partial information:"+rdpname,"");
                    return;
                }
            }
            rt_datapoints[i]=rdpname;
        };
        //rt_datapoints[i]=dpSubStr(rt_datapoints[i],DPSUB_SYS_DP); // #fix #18899
        rt_datapoints[i]=dpSubStr(rt_datapoints[i],DPSUB_DP);
        dynAppend(newRTList,rt_datapoints[i]);
    };

    // set the list of the master recipe...
    rc=dpSet(dpName+".RecipeTypeList",newRTList);
    if (rc) {
        fwException_raise(exceptionInfo,"ERROR",
                          "Cannot set the recipe type information in:"+dpName,"");
        return;
    };

    // now fill all datapoints...
    for (int i=1;i<=dynlen(rt_datapoints);i++) {

	// scan the gRTData and find properties and alerts for this dptype
        dyn_string saveValueList, saveAlertList;
        for (int j=1;j<=dynlen(RTData);j++) {
            if (RTData[j][2] == rt_dptypes[i]) {
                if (RTData[j][5]) dynAppend(saveValueList,RTData[j][3]);
                if (RTData[j][6]) dynAppend(saveAlertList,RTData[j][3]);
            }
        }
        rc=dpSet(rt_datapoints[i]+".DPType",rt_dptypes[i],
                 rt_datapoints[i]+".SavePropertyValue",saveValueList,
                 rt_datapoints[i]+".SaveAlert",saveAlertList);
        if (rc) {
            fwException_raise(exceptionInfo,"ERROR",
                              "Cannot set the partial recipe type information in:"+rt_datapoints[i],"");
            return;
        };

    };

}




void _fwConfigurationDB_RTAddToModel(string dptName, dyn_dyn_string &RTData, dyn_string &exceptionInfo)
{
	// use also deviceDefinition information
	// we will mark the dpelements which are
	// not declared as device properties
	// with "$" in the property name

    string devName;
    dyn_string props,dpes;
    _fwConfigurationDB_getPropertiesAndDPEs(dptName,props,dpes, devName,exceptionInfo);
    if (dynlen(exceptionInfo))  return;
    for (int j=1;j<=dynlen(dpes);j++) {
        dyn_string RT;
        RT[1] = devName;
        RT[2] = dptName;
        RT[3] = dpes[j];
        if(j<=dynlen(props)) {
            RT[4] = props[j];
        } else {
            RT[4]="$";
        }
        if (RT[4]=="") RT[4] = "DPE:"+dpes[j];
        RT[5] = FALSE;
        RT[6] = FALSE;

        RTData[dynlen(RTData)+1]=RT;
    };
}

/**  convert the recipeTypeData to useful form: mapping with keys being DPTypes
      and values being list of elements that are to be stored
*/
void fwConfigurationDB_getRecipeTypeDataMapping(string recipeType, mapping &rtElements, dyn_string &exceptionInfo)
{
    dyn_dyn_string recipeTypeData;
    _fwConfigurationDB_getRecipeTypeData(recipeType,recipeTypeData,exceptionInfo);
    if (dynlen(exceptionInfo)) return;
    
    for (int i=1;i<=dynlen(recipeTypeData);i++) {                                       
	string rtDpType=recipeTypeData[i][2];
	string elName=recipeTypeData[i][3];
	bool storeValue=recipeTypeData[i][5];
	bool storeAlert=recipeTypeData[i][6];
	dyn_string currentElements;
	if (mappingHasKey(rtElements,rtDpType)) currentElements=rtElements[rtDpType];
	if (storeValue) {
	    dynAppend(currentElements,elName);
    	rtElements[rtDpType]=currentElements;
	}
    }
}                                                                                                       
//@} // end of Recipe Type functions
//______________________________________________________________________________
