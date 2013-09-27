/**@file
 *
 * This package contains general functions of the Configuration Database tool
 *
 * @author Piotr Golonka (EN/ICE-SCD)
 * @date   June 2013
 * (c) Copyright CERN, All Rights Reserved
 */

global string _fwConfigurationDB_fileVersion_fwConfigurationDB_ctl="5.0.2";

/** Version of this tool.
 * Used to determine data-point and DB-schema compatibilty,
 * see also @ref fwConfigurationDB_schemaVersion
 * @ingroup Constants
*/
const float      fwConfigurationDB_version = 5.0;

/** Minimal version of the DB schema required for operation
 * see also @ref fwConfigurationDB_version
 * @ingroup Constants
*/
const float      fwConfigurationDB_minimalDBSchemaVersion=3.03;


const float     fwConfigurationDB_minimalRDBAccessVersion=5.00;

const string     fwConfigurationDB_RecipeCacheDpPrefix="RecipeCache/";
const string     fwConfigurationDB_RecipeTypeDpPrefix="RecipeType/";
const string     fwConfigurationDB_RecipeClassDpPrefix="RecipeClass/";
const string     fwConfigurationDB_ConnectionNamePrefix="DBConnections/";
const string     fwConfigurationDB_ConfigurationSetupPrefix="ConfigurationSetups/";
const string   _GfwConfigurationDB_defaultRecipeType="default";

global float    fwConfigurationDB_currentDBSchemaVersion=0.0;
global float    fwConfigurationDB_currentDPSchemaVersion=0.0;

/**
 * Stores the name of curntly used setup
 * @ingroup GlobalVariables
 */
global string       fwConfigurationDB_currentSetupName="";

/**  Tells if the tool was already initialized with some setup...
 * @ingroup GlobalVariables
 */
global bool      fwConfigurationDB_initialized=FALSE;



/**  Tells if the CDB is available at all in this setup
 * @ingroup GlobalVariables
 */
global bool      fwConfigurationDB_DBConfigured=FALSE;


/** Stores the name of currently used recipe type
 * @ingroup GlobalVariables
 */
global string   GfwConfigurationDB_currentRecipeType="";

/** Tells if the database connection used by current setup is open
 * @ingroup GlobalVariables
 */
global bool         g_fwConfigurationDB_DBConnectionOpen=FALSE;

/** Tells if the configuration database may be used
 * @ingroup GlobalVariables
 */
global bool      fwConfigurationDB_hasDBConnectivity=FALSE;

/** Stores the connection descriptor
 * @ingroup GlobalVariables
 */
global dbConnection g_fwConfigurationDB_DBConnection;

/** What privileges on the schema do one has:
    @li "OWNER" - schema owner
    @li "WRITER" - writer rights
    @li "READER" - reader rights
    @li "" (empt) - no ConfDB rights on the current schema

Note! The privileges need to be granted through the DB ROLE 
that is created together with the schema!
*/
global string fwConfigurationDB_SchemaPrivs;



/** Debug level for SQL statements (bitmask)

The actual debug level is the sum of the following:
    1 - print SQL selects
    2 - print SQL statements
    4 - print num of results in SQL select (summary info)
    8 - print the complete results of SQL select
*/
global int g_fwConfigurationDB_DebugSQL=0;

/** Debug level (bitmask)

The actual debug level is the sum of the following:
    1 - print function name on entry
    2 - print timing information on exit
    4 - print info on entry to functional parts of routines
    8 - massive debug info
*/
global int g_fwConfigurationDB_Debug=0;

/** Statistics-gathering variable

*/
global mapping g_fwConfigurationDB_stats;

// internal global variables
global mapping  GfwConfigurationDB_RTValues;
global mapping  GfwConfigurationDB_RTAlerts;
global mapping  GfwConfigurationDB_RTDevices;
global mapping  g_fwConfigurationDB_DBHierarchyIDs;


const int fwConfigurationDB_OPER_DBQuery=1;
const int fwConfigurationDB_OPER_DBExecuteSQL=2;
const int fwConfigurationDB_OPER_ResolveHierarchy=3;
const int fwConfigurationDB_OPER_LoadRecipeFromCache=4;
const int fwConfigurationDB_OPER_SaveRecipeToCache=5;
const int fwConfigurationDB_OPER_LoadRecipeFromDB=6;
const int fwConfigurationDB_OPER_SaveRecipeToDB=7;
const int fwConfigurationDB_OPER_GetRecipeFromSystem=8;
const int fwConfigurationDB_OPER_ApplyRecipeToSystem=9;
const int fwConfigurationDB_OPER_LoadHierachyFromDB=10;
const int fwConfigurationDB_OPER_SaveHierarchyToDB=11;
const int fwConfigurationDB_OPER_GetHierachyFromSystem=12;
const int fwConfigurationDB_OPER_ApplyHierarchyToSystem=13;
const int fwConfigurationDB_OPER_UpdateDBHierarchyInfo=14;
const int fwConfigurationDB_OPER_SaveDeviceProperties=15;
const int fwConfigurationDB_OPER_SaveDevicesAndElements=16;
const int fwConfigurationDB_OPER_SaveDeviceReferences=17;
const int fwConfigurationDB_OPER_SaveDeviceMetaData=18; // device conf version, device types
const int fwConfigurationDB_OPER_LoadDeviceProperties=19;

const int fwConfigurationDB_OPER_SaveDevices=20;
const int fwConfigurationDB_OPER_LoadDevices=21;

//__________________________________________________________________________
/**
 * @name Error Codes in general package
   See also @ref ErrorCodes "Error Codes overview" module
 * @{
*/

/** general error code
@ingroup ErrorCodes
*/
const int fwConfigurationDB_ERROR_GENERAL=-1;

/** data point type does not exist
@ingroup ErrorCodes
*/
const int fwConfigurationDB_ERROR_DPTNotExist=-2;

/** operation was canceled.
@ingroup ErrorCodes
*/
const int fwConfigurationDB_ERROR_OperationAborted=-3;

/** separator characted found in the list, which was going to be converted to a string
@ingroup ErrorCodes
*/
const int fwConfigurationDB_ERROR_SeparatorCharInStringList=-4;

//@} // end of Error codes
//______________________________________________________________________________

/** Checks if the tool was initialized, calls the initialization if needed
 *
 * @ingroup InitFunctions
 *
 * @param exceptionInfo standard exception handling routine
 *
 * @see fwConfigurationDB_checkInit
 * @see @ref qstart_initialization section of the "quick start" chapter
 */
synchronized void  fwConfigurationDB_checkInit(dyn_string &exceptionInfo)
{

    if (!fwConfigurationDB_initialized) {
        fwConfigurationDB_initialize("", exceptionInfo);
    };
}

/** Performs the initialization of the tool
 *
 * @ingroup InitFunctions
 *
 * @param setupName     specifies the name of the setup, as defined
 *                      in the "CDB Setup" panel. Specifying empty
 *                      string ("") means that the default setup should
 *                      be used.
 *
 * @param exceptionInfo standard exception handling variable.
 *
 * @see @ref qstart_initialization section of the "quick start" chapter
 */
synchronized void  fwConfigurationDB_initialize(string setupName, dyn_string &exceptionInfo)
{
    time t0;
    _fwConfigurationDB_startFunction("initialize", t0);

    string dpName;
    fwConfigurationDB_initialized=FALSE;

    fwConfigurationDB_SchemaPrivs="";

    _fwConfigurationDB_initNumericConstants();

    // close old db connection
    if (g_fwConfigurationDB_DBConnectionOpen) {
        //DebugN("Closing connection to the previous configuration database");
	fwDbDeleteConnection(g_fwConfigurationDB_DBConnection);
    }


    dyn_string setupNames, setupDPs;
    string defaultSetupName,defaultSetupDp;
    fwConfigurationDB_getSetups(setupNames, setupDPs, defaultSetupName,defaultSetupDp, exceptionInfo);
    if (dynlen(exceptionInfo)) return;
    if (defaultSetupName=="") {
        fwException_raise(exceptionInfo,"WARNING!",
                          "Cannot find default setup. Please configure the tool first.","");
        return;
    }

    if (setupName=="") {
        setupName=defaultSetupName;
        dpName=defaultSetupDp;
    } else {
        int idx=dynContains(setupNames,setupName);
        if (idx<1) {
            fwException_raise(exceptionInfo,"ERROR","Configuration Tool setup "+setupName+" not defined","");
            return;
        };
        dpName=setupDPs[idx];
    };

    // pre-configure the default recipe type
    if ( GfwConfigurationDB_currentRecipeType == "") fwConfigurationDB_setRecipeType("", exceptionInfo);
    if (dynlen(exceptionInfo)) return;

    string dbConnectionName;
    float version;
    int rc=dpGet(dpName+".DBConnection",dbConnectionName,
                dpName+".version",version);
    if (rc) {
        fwException_raise(exceptionInfo,"ERROR","Could not get Configuration Tool setup  "+setupName,"");
        return;
    }

    fwConfigurationDB_currentSetupName=setupName;
    fwConfigurationDB_initialized=TRUE;
    fwConfigurationDB_hasDBConnectivity=FALSE;
    fwConfigurationDB_currentDPSchemaVersion=version;

//    if (version!=fwConfigurationDB_version) {
//        DebugN("WARNING",
//               "Setup version="+version+" differs from the current tool version="+fwConfigurationDB_version);
//    }

    if (dbConnectionName=="" || dbConnectionName=="(none)") {
        // we do not need further initialisation of DB ...
	fwConfigurationDB_DBConfigured=FALSE;

	// fix #20401
	g_fwConfigurationDB_DBHierarchyIDs[fwDevice_HARDWARE]=1;
	g_fwConfigurationDB_DBHierarchyIDs[fwDevice_LOGICAL]=2;
	g_fwConfigurationDB_DBHierarchyIDs["FSM"]=3;

        return;
    };

    // if DB is going to be used, check the version...
    if (!isFunctionDefined("fwDbOption")) {
	fwException_raise(exceptionInfo,"ERROR","CtrlRDBAccess functions not available\n"+
			"Please install the recent PVSS cumulative patch!","");
	DebugN("ERROR: CtrlRDBAccess PVSS patch probably not installed");
	return;
    }

    mixed mVer;
    int rc=fwDbOption("GetVersion",0,mVer);
    if (rc) {
	fwException_raise(exceptionInfo,"ERROR","Cannot get the version of the CtrlRDBAccess library","");
	return;
    }
    float ver=mVer;
    if (ver<fwConfigurationDB_minimalRDBAccessVersion) {
	fwException_raise(exceptionInfo,"ERROR","The version of the CtrlRDBAccess ("+ver+") is too old. Required:"+fwConfigurationDB_minimalRDBAccessVersion,"");
	return;
    }


    fwConfigurationDB_DBConfigured=TRUE;

    dbConnection dbCon;
    fwConfigurationDB_openDBConnection(dbConnectionName, dbCon, exceptionInfo);
    if (dynlen(exceptionInfo)) return;


    g_fwConfigurationDB_DBConnection=dbCon;
    g_fwConfigurationDB_DBConnectionOpen=TRUE;

    _fwConfigurationDB_DBSchemaSanityCheck(dbCon, exceptionInfo);
    
    if (dynlen(exceptionInfo)) return;
    
    // everything is OK: activate the new connection
    fwConfigurationDB_hasDBConnectivity=TRUE;

    _fwConfigurationDB_endFunction("initialize", t0);
}


void fwConfigurationDB_getSetups(dyn_string &setupNames, dyn_string &setupDPs,
                                 string &defaultSetupName, string &defaultSetupDP,
                                 dyn_string &exceptionInfo)
{
    defaultSetupName="";
    defaultSetupDP="";
    setupDPs=dpNames(fwConfigurationDB_ConfigurationSetupPrefix+"*","_FwConfigurationDB_setup");

    if (dynlen(setupDPs)==0) {
	DebugN("Creating default ConfDB setup");
	fwConfigurationDB_createSetup("default",exceptionInfo,TRUE);
	if (dynlen(exceptionInfo)) return;
    }
    setupDPs=dpNames(fwConfigurationDB_ConfigurationSetupPrefix+"*","_FwConfigurationDB_setup");


    for (int i=1;i<=dynlen(setupDPs);i++){
        string dpname=dpSubStr(setupDPs[i],DPSUB_DP);
        setupNames[i]=substr(dpname,strlen(fwConfigurationDB_ConfigurationSetupPrefix));
        bool isDefault;
        dpGet(setupDPs[i]+".default",isDefault);
        if (isDefault) {
    	    if (defaultSetupName=="") {
        	defaultSetupName=setupNames[i];
        	defaultSetupDP=setupDPs[i];
    	    } else {
    		// multiple default setups??? bring some order here...
    		DebugN("WARNING! More than one ConfigurationDB Setup marked as default. Resetting "+setupNames[i]);
    		dpSet(setupDPs[i]+".default",FALSE);
    	    }
        }
    }
    if (defaultSetupName=="" && (dynlen(setupNames)>0)) {
        defaultSetupName=setupNames[1];
        defaultSetupDP=setupDPs[1];
        dpSet(defaultSetupDP+".default",TRUE);
    }
}


void _fwConfigurationDB_printLibraryFileVersions()
{

    dyn_string allGlobalVars;
    dyn_int globalTypes;
    getGlobals(allGlobalVars, globalTypes);

    dyn_string myFileVersions=dynPatternMatch("_fwConfigurationDB_fileVersion***",allGlobalVars);

    DebugN("---Currently loaded fwConfigurationDB libraries---");

    for (int i=1;i<=dynlen(myFileVersions);i++) {
	string varName=myFileVersions[i];
	string fName=substr(varName,33);
	strreplace(fName,"_ctl",".ctl");
	strreplace(fName,"_ctc",".ctc");
	//pad with spaces
	for (int j=strlen(fName);j<=40;j++) fName+=" ";
	dyn_string exceptionInfo;
	string version;
	fwGeneral_getGlobalValue(varName,version, exceptionInfo);
	DebugN(fName+" : "+version);
    }
DebugN("--------------------------------------------------");

}
