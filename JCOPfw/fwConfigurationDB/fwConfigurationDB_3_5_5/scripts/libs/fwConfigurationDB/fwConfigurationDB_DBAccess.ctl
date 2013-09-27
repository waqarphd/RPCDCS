/**@file

This package contains database access functions of the Configuration Database tool

@author Piotr Golonka (EN/ICE-SCD)
@date   March 2012
*/

global string _fwConfigurationDB_fileVersion_fwConfigurationDB_DBAccess_ctl="3.5.5";

//__________________________________________________________________________
/** @name Error Codes in DBAccess package
 * see also @ref ErrorCodes "Error Codes overview" module.
 * @{
 */
const int fwConfigurationDB_ERROR_DBNoConnection = -162;
///@} // end of Error codes
//______________________________________________________________________________



//__________________________________________________________________________
/**
 * @name Database Access functions

 These functions are used in context of database access


 * @{
*/




/** opens connection to the database
@ingroup DBAccessFunctions

@param exceptionInfo 	standard exception handling variable

Returned error codes:
@li @ref fwConfigurationDB_ERROR_DBNoConnection (error)

*/
void fwConfigurationDB_openDBConnection(string dbConnectionName, dbConnection &dbCon, dyn_string &exceptionInfo)
{
    string description, connectString,dbType,dbName,dbUser,dbSchema,dbPassword;

    // check if the connection is already in the pool managed by CtrlRDBAccess...
    dyn_string conNames;
    int rc=fwDbGetConnectionNames(conNames);
    if (rc) {
	fwException_raise(exceptionInfo,"ERROR","Could not get connection names","");
	return;
    }

    if (dynContains(conNames,dbConnectionName)) {
	int rc=fwDbGetConnection(dbConnectionName,dbCon);
	if (rc) {
	    fwException_raise(exceptionInfo,"ERROR","Could not get connection "+dbConnectionName,"");
	    return;
	}
	
	fwConfigurationDB_SchemaPrivs = _fwConfigurationDB_checkSchemaPrivileges(dbCon, exceptionInfo);
	return;
    }


    fwConfigurationDB_getDBConnection(dbConnectionName,
                            	    description, dbType, dbName,
                                    dbUser,dbPassword, connectString,
                                    dbSchema,
                                    exceptionInfo);
    if (dynlen(exceptionInfo)) return;


/*
    int rc=dpGet(dpName+".version",version)
    if (version<fwConfigurationDB_version) {
        DebugN("WARNING!","Connection "+dbConnectionName+" has version="+version+
                " older than current version="+fwConfigurationDB_version);
    }
*/
    fwConfigurationDB_dbConnect(dbConnectionName,connectString, dbType,dbName, dbUser, dbSchema,dbPassword, dbCon, exceptionInfo);

    if (dynlen(exceptionInfo)) {
        // append some more information to the exception info
        exceptionInfo[2]="Failed to open connection: "+dbConnectionName+"\n"+exceptionInfo[2];
        return;
    }
//    DebugN("Database connection opened succesfully:",dbConnectionName);

    fwConfigurationDB_SchemaPrivs = _fwConfigurationDB_checkSchemaPrivileges(dbCon, exceptionInfo);

}


string _fwConfigurationDB_checkSchemaPrivileges(dbConnection dbCon, dyn_string &exceptionInfo)
{
    string schemaPrivs="";

    dyn_mixed aRecords;
    string sql="SELECT USER,SYS_CONTEXT('USERENV','CURRENT_SCHEMA') FROM DUAL";
    _fwConfigurationDB_executeDBQuery(sql,dbCon, aRecords, exceptionInfo);
    if (dynlen(exceptionInfo)) return;
    
    if (aRecords[1][1] == aRecords[1][2]) {
    	schemaPrivs="OWNER";
    } else  {
	// not an owner: then query the privileges to the schema...
	dynClear(aRecords);
	string sql="SELECT COUNT(*) FROM USER_TAB_PRIVS WHERE TABLE_NAME='ITEMS' AND OWNER=SYS_CONTEXT('USERENV','CURRENT_SCHEMA') AND PRIVILEGE='SELECT'";
	_fwConfigurationDB_executeDBQuery(sql,dbCon, aRecords, exceptionInfo);
	if (dynlen(exceptionInfo)) return;
	if (aRecords[1][1]>0) schemaPrivs="READER";

	dynClear(aRecords);
	string sql="SELECT COUNT(*) FROM USER_TAB_PRIVS WHERE TABLE_NAME='ITEMS' AND OWNER=SYS_CONTEXT('USERENV','CURRENT_SCHEMA') AND PRIVILEGE='INSERT'";
	_fwConfigurationDB_executeDBQuery(sql,dbCon, aRecords, exceptionInfo);
	if (dynlen(exceptionInfo)) return;
	if (aRecords[1][1]>0) schemaPrivs="WRITER";
    }
    
    return schemaPrivs;
}


void fwConfigurationDB_checkOpenDB(dyn_string &exceptionInfo)
{
    fwConfigurationDB_checkInit(exceptionInfo);
    if (dynlen(exceptionInfo)) return;
    if (!fwConfigurationDB_hasDBConnectivity) {
        fwException_raise(exceptionInfo,"ERROR","ConfigurationDB is not available.","");
        return;
    }

//    if (!g_fwConfigurationDB_DBConnectionOpen) {
//        fwConfigurationDB_openDB("", exceptionInfo);
//    }
}


void fwConfigurationDB_initializeQuery( string sql, dbConnection conn, 
    dbCommand &dbCmd, dyn_string &exceptionInfo)
{
    dyn_mixed dummyParams;
    fwConfigurationDB_initializeQueryWithParams(sql,conn,dummyParams, dbCmd, exceptionInfo);
}


// note! bindParams could be either dyn_mixed or mapping!
void fwConfigurationDB_initializeQueryWithParams( string sql, dbConnection conn, mixed bindParams,
    dbCommand &dbCmd, dyn_string &exceptionInfo)
{
    // fix for the default value of the parameter...
    mapping m;
    dyn_mixed dm;
    if (getType(bindParams)==MAPPING_VAR) {
	m=bindParams;
    } else {
	dm=bindParams;
    }

    if (g_fwConfigurationDB_DebugSQL & 1) DebugTN("Init/Exec Query SQL:",sql);
    dbCommand cmd;
    string errTxt;
    int rc;
    
    rc = fwDbStartCommand (conn, sql, cmd);
    if (rc) {
	fwDbCheckError(errTxt,cmd);
	string oraMsg;
	string oraCode=_fwConfigurationDB_extractOraErrCode(errTxt, oraMsg);
	DebugN("ERROR:Could not initialize SQL query",sql);
	DebugN("     "+errTxt);
	fwException_raise(exceptionInfo,"ERROR","DB Query initialization error ("+oraCode+")\n"+oraMsg,"");
	//fwDbFinishCommand (cmd);
	return;
    }

    rc=0;
    if (dynlen(dm)) {
	rc = fwDbBindParams(cmd,dm);
    } else if (mappinglen(m)) {
	rc = fwDbBindParams(cmd,m);
    }
    if (rc) {
	    fwDbCheckError(errTxt,cmd);
	    string oraMsg;
	    string oraCode=_fwConfigurationDB_extractOraErrCode(errTxt, oraMsg);
	    DebugN("ERROR:Could not bind params for SQL Query",sql);
	    DebugN("     "+errTxt);
	    DebugN("Bind params:");
	    DebugN(bindParams);
	    fwException_raise(exceptionInfo,"ERROR","DB parameter bind error ("+oraCode+")\n"+oraMsg,"");
	    fwDbFinishCommand (cmd);
	    return;
    }
    
										    
    rc = fwDbExecuteCommand (cmd);
    if (rc) {
	fwDbCheckError(errTxt,cmd);
	string oraMsg;
	string oraCode=_fwConfigurationDB_extractOraErrCode(errTxt, oraMsg);
	DebugN("ERROR:Could not execute SQL query",sql);
	DebugN("     "+errTxt);
	fwException_raise(exceptionInfo,"ERROR","DB Query execution error ("+oraCode+")\n"+oraMsg,"");
	fwDbFinishCommand (cmd);
	return;
    }
    
    dbCmd=cmd;
//DebugTN("Initquery done for",sql);

}

/**
    Fetches the data from the already-executed (initialized) db query,
    according to specification.
    
    @param closeOnNoMoreData - if all data from the query is fetched,
	it will finalize the dbCommand (so you do not need to do it
	    yourself)
    
    @returns 0 if there is no more data to fecth
    @returns 1 if there is still data to fetch
    @returns -1 in case of an error
*/
int fwConfigurationDB_fetchQuery( dbCommand &dbCmd, dyn_dyn_mixed &aRecords,
    dyn_string &exceptionInfo,int maxRecords=0, bool columnWise=FALSE, 
    bool closeOnNoMoreData=TRUE, dyn_int colTypes=0, int numCol=999)
{
//DebugTN("fetchQuery starts...");
    // fix for the default value of the parameter...
    if ( (dynlen(colTypes)==1) && (colTypes[1]==0)) dynClear(colTypes);

    string errTxt;
    int rc;
//DebugTN("calling fwDbGetData");
    if (dynlen(colTypes)) {
	rc=fwDbGetData(dbCmd,aRecords,columnWise,maxRecords,colTypes);
    } else {
	rc=fwDbGetData(dbCmd,aRecords,columnWise,maxRecords);
    }
//DebugTN("OK. Got the data");
    int nRecords=0;
    if (columnWise) {
	if (dynlen(aRecords)) nRecords=dynlen(aRecords[1]);
    } else {
	nRecords=dynlen(aRecords);
    }

    if (rc==1) {
	//DebugTN("Fetched "+nRecords+" records; still data to fetch");
	return 1;
    } else if (rc==0) {
	if (closeOnNoMoreData) {
	    //DebugTN("Fetched "+nRecords+" records; all data fetched; closing dbCommand");
	    rc = fwDbFinishCommand (dbCmd);
	    //DebugTN("command finished",rc);
	    if (rc) {
	    	fwDbCheckError(errTxt,dbCmd);
		DebugTN("WARNING:Could not close the dbCommand",errTxt);
	    };
	} else {
	    //DebugTN("Fetched "+nRecords+" records; all data fetched; dbCommand NOT CLOSED");	
	}
	return 0;
    } else {
	fwDbCheckError(errTxt,dbCmd);
	string oraMsg;
	string oraCode=_fwConfigurationDB_extractOraErrCode(errTxt, oraMsg);
	DebugN("ERROR:Could not get data from SQL query, rc="+rc);
	DebugN("     "+errTxt);
	fwException_raise(exceptionInfo,"ERROR","DB Query data fetch error ("+oraCode+")\n"+oraMsg,"");
	fwDbFinishCommand (dbCmd);
	return -1;
    }
}







void _fwConfigurationDB_executeDBQuery(string sql,dbConnection conn, dyn_dyn_mixed &aRecords, dyn_string &exceptionInfo, 
int numCol=999, bool columnWise=FALSE, dyn_int colTypes=0)
{
    dyn_mixed dummyParams;
    _fwConfigurationDB_executeDBQueryWithParams(sql,conn, dummyParams, aRecords, exceptionInfo, numCol, columnWise, colTypes);

}



void _fwConfigurationDB_executeDBQueryWithParams(string sql,dbConnection conn, anytype bindParams, dyn_dyn_mixed &aRecords, dyn_string &exceptionInfo, 
int numCol=999, bool columnWise=FALSE, dyn_int colTypes=0)
{
    dbCommand dbCmd;
    fwConfigurationDB_initializeQueryWithParams( sql, conn, bindParams, dbCmd, exceptionInfo, bindParams);
    if (dynlen(exceptionInfo)) return;

    int maxRecords=0;
    bool closeOnNoMoreData=TRUE;
    fwConfigurationDB_fetchQuery( dbCmd, aRecords, exceptionInfo,
	    maxRecords=0, columnWise, closeOnNoMoreData, colTypes, numCol);
    if (dynlen(exceptionInfo)) return;
//    DebugTN("back from fetchQuery...");
    if (g_fwConfigurationDB_DebugSQL & 4) {
	int nresults=dynlen(aRecords);
	if (columnWise) {
	    if (dynlen(aRecords)>=1) nresults=dynlen(aRecords[1]);
	    else nresults=0;
	}
	DebugTN("Query SQL:"+nresults+" result(s) fetched");
    }
    if (g_fwConfigurationDB_DebugSQL & 8) DebugTN("Query SQL results:\n",aRecords);
}

void _fwConfigurationDB_executeDBBulkCmd(string sql,dbConnection conn, dyn_dyn_mixed data, dyn_string &exceptionInfo, bool columnWise=FALSE)
{
    

    dyn_dyn_mixed params;
    if (fwConfigurationDB_progress(fwConfigurationDB_OPER_DBQuery,"Executing SQL command", 0.0,
                                   exceptionInfo)) return;


    if (columnWise && (dynlen(data)>0)) {
	// we need to transpose the parameters table :-(
	
	// prepare new columns
	for (int i=1;i<=dynlen(data[1]);i++) {
	    dyn_mixed empty;
	    params[i]=empty;
	}
	
	for (int i=1;i<=dynlen(data);i++) {
	    dyn_mixed row=data[i];
	    for (int j=1;j<=dynlen(row);j++) params[j][i]=row[j];
	}
    } else {
	params=data;
    }

    if (g_fwConfigurationDB_DebugSQL & 1) DebugTN("Execute Bulk SQL:",sql);
    if (g_fwConfigurationDB_DebugSQL & 4) DebugTN("       with "+dynlen(data)+" records");
    if (g_fwConfigurationDB_DebugSQL & 8) DebugTN("       with data:\n",params);

    dbCommand cmd;
    string errTxt;
    
    int rc = fwDbStartCommand (conn, sql, cmd);
    if (rc) {
	fwDbCheckError(errTxt,cmd);
	string oraMsg;
	string oraCode=_fwConfigurationDB_extractOraErrCode(errTxt, oraMsg);
	DebugN("ERROR:Could not initialize SQL command",sql);
	DebugN("     "+errTxt);
	fwException_raise(exceptionInfo,"ERROR","DB Command initialization error ("+oraCode+")\n"+oraMsg,"");
	//fwDbFinishCommand (cmd);
	return;
    }

    rc = fwDbBindAndExecute(cmd,params);
    if (rc) {
	fwDbCheckError(errTxt,cmd);
	string oraMsg;
	string oraCode=_fwConfigurationDB_extractOraErrCode(errTxt, oraMsg);
	DebugN("ERROR:Could not execute SQL command",sql);
	DebugN("     "+errTxt);
	fwException_raise(exceptionInfo,"ERROR","DB Command execution error ("+oraCode+")\n"+oraMsg,"");
	fwDbFinishCommand (cmd);
	return;
    }

    rc = fwDbFinishCommand (cmd);
    if (fwConfigurationDB_progress(fwConfigurationDB_OPER_DBQuery,"SQL command executed", 100.0,
                                   exceptionInfo)) return;

}


/* let's try to serve both: dyn_mixed and mapping params ...*/
//void _fwConfigurationDB_executeDBCmd(string sql,dbConnection conn, dyn_mixed params, dyn_string &exceptionInfo)
void _fwConfigurationDB_executeDBCmd(string sql,dbConnection conn, anytype params, dyn_string &exceptionInfo)
{
    if (fwConfigurationDB_progress(fwConfigurationDB_OPER_DBQuery,"Executing SQL command", 0.0,
                                   exceptionInfo)) return;

    if (g_fwConfigurationDB_DebugSQL & 1) DebugTN("Execute SQL:",sql);
    if (g_fwConfigurationDB_DebugSQL & 4) DebugTN("       with params:\n",params);

    dbCommand cmd;
    string errTxt;
    
    int rc = fwDbStartCommand (conn, sql, cmd);
    if (rc) {
	fwDbCheckError(errTxt,cmd);
	string oraMsg;
	string oraCode=_fwConfigurationDB_extractOraErrCode(errTxt, oraMsg);
	DebugN("ERROR:Could not initialize SQL command",sql);
	DebugN("     "+errTxt);
	fwException_raise(exceptionInfo,"ERROR","DB Command initialization error ("+oraCode+")\n"+oraMsg,"");
	//fwDbFinishCommand (cmd);
	return;
    }
    if (getType(params)==MAPPING_VAR) {
	mapping m=params;
	rc = fwDbBindParams(cmd, m);
    } else {
	dyn_mixed dm=params;
	rc = fwDbBindParams(cmd,dm);
    }
	if (rc) {
	    fwDbCheckError(errTxt,cmd);
	    string oraMsg;
	    string oraCode=_fwConfigurationDB_extractOraErrCode(errTxt, oraMsg);
	    DebugN("ERROR:Could not bind params for SQL command",sql);
	    DebugN("     "+errTxt);
	    fwException_raise(exceptionInfo,"ERROR","DB parameter bind error ("+oraCode+")\n"+oraMsg,"");
	    fwDbFinishCommand (cmd);
	    return;
	}

    rc = fwDbExecuteCommand(cmd);
    if (rc) {
	fwDbCheckError(errTxt,cmd);
	string oraMsg;
	string oraCode=_fwConfigurationDB_extractOraErrCode(errTxt, oraMsg);
	DebugN("ERROR:Could not execute SQL command",sql);
	DebugN("     "+errTxt);
	fwException_raise(exceptionInfo,"ERROR","DB Command execution error ("+oraCode+")\n"+oraMsg,"");
	fwDbFinishCommand (cmd);
	return;
    }

    rc = fwDbFinishCommand (cmd);
    if (fwConfigurationDB_progress(fwConfigurationDB_OPER_DBQuery,"SQL command executed", 100.0,
                                   exceptionInfo)) return;

}



void fwConfigurationDB_executeSqlSimple(string sql, dbConnection connection,dyn_string &exceptionInfo)
{
    if (g_fwConfigurationDB_DebugSQL & 2) DebugTN("Execute SQL:",sql);

    // fix for executing PL/SQL statements - they need to contain semicolon after the "END" statement
    if (substr(strltrim(strtoupper(sql)),0,5)=="BEGIN") {
	sql=strrtrim(sql);// trim whitespaces
	sql=strrtrim(sql,";"); // trim all semicolons that exist
	sql=sql+";"; // add a single semicolon
    }

    int rc=fwDbExecuteSqlStatement(connection, sql);
    if (rc<0) {
	fwException_raise(exceptionInfo,"ERROR in fwConfigurationDB_executeSqlSimple","Cannot execute SQL Statement;rc="+rc,"");
	string errTxt;
	fwDbCheckError(errTxt,connection);
	DebugN("Cannot execute SQL command",sql,errTxt);
//	DebugTN(getLastError());
	return;
    } else if (rc==1){
	string errTxt;
	fwDbCheckError(errTxt,connection);
	DebugN("Cannot execute SQL command",sql,errTxt);
	fwException_raise(exceptionInfo,"ERROR in fwConfigurationDB_executeSqlSimple","Cannot execute SQL statement (see log)","");
	return;
    } else if (rc==2){
	DebugN("Warning, fwConfigurationDB_executeSqlSimple, executing SQL Select statement via fwDbExecuteSqlStatement - no data will be returned",sql);
    }
}

/** Checks if all specified keywords are present in the string
 - used for parsing of SQL file
 note that the keywords should be comma or space separated
 
 if ALL the keywords are found, the funtion returns TRUE
*/
bool _fwConfigurationDB_hasKeywords(string src, string keywords)
{

    dyn_string ds=strsplit(strtoupper(src)," \t");
    dyn_string kwds=strsplit(strtoupper(keywords),", ");
    for (int i=1;i<=dynlen(kwds);i++) {
	string kwd=kwds[i];
	dyn_string match=dynPatternMatch(kwd,ds);
	if (!dynlen(match)) return FALSE;
    }
    return TRUE;
}

/** executes SQL statements stored in a file
 *
 * Note that the all commands in the file should be terminated by the semicolon (;)
 * character, which should be the last characted in the line.
 * The comments (lines starting with "-" character) and white-spaces are a
 * also automatically removed.
 *
 * @ingroup DBAccessFunctions
 * @param dbCon            database connection descriptor
 * @param filename          the name of the file, where the SQL statements are stored.
 *                          The file needs to be in the "config" directory of the project.
 * @param whatItIs          a short text describing the context in which the statements
 *                          are executed. Used only for printouts.
 * @param exceptionInfo 	standard exception handling variable
 * @param breakOnDbError    (optional, default is TRUE) determines if the function should
 *                          return terminate with an exception upon first encountered error,
 *                          or it should rather try to finish the remaining commands
 *                          (the errors encountered in a meantime will be reported at the end).
*/
void _fwConfigurationDB_executeSqlFromFile(dbConnection dbCon,
                                           string fileName, string whatItIs,
                                           dyn_string &exceptionInfo,
                                           bool breakOnDbError=TRUE)
{


  string sqlFile=getPath(CONFIG_REL_PATH,fileName);

  string sSql; // all statements in one string
  bool ok=fileToString(sqlFile,sSql);
  if (!ok) {
    fwException_raise(exceptionInfo,"ERROR","The file with SQL statements for "+whatItIs+
                          " cannot be opened","");
    return;
  }

  dyn_string sql;
  dyn_string sqlLines=strsplit(sSql,"\n");
  string stmt="";
  int PlSqlBlock=0;
  for (int i=1;i<=dynlen(sqlLines);i++){
    string line = sqlLines[i];
    if (strltrim(strrtrim(line))=="") continue; // skip empty lines


    // PL/SQL package begins...
    if (_fwConfigurationDB_hasKeywords(line, "CREATE,PACKAGE")) PlSqlBlock++;
    //if ( (strpos(strtoupper(line),"CREATE")>=0) && (strpos(strtoupper(line),"PACKAGE")>=0) ) PlSqlBlock++;
    // PL/SQL package/type body begins...
    if (_fwConfigurationDB_hasKeywords(line, "CREATE,BODY")) PlSqlBlock++;
    //if ( (strpos(strtoupper(line),"CREATE")>=0) && (strpos(strtoupper(line),"BODY")>=0) ) PlSqlBlock++;

    if ((PlSqlBlock==0) &&_fwConfigurationDB_hasKeywords(line, "CREATE,FUNCTION")) PlSqlBlock++;

    // object type creation (PL/SQL) ahead:
    //if ((PlSqlBlock==0) &&_fwConfigurationDB_hasKeywords(line, "OBJECT")) PlSqlBlock++;
    if ((PlSqlBlock==0) &&_fwConfigurationDB_hasKeywords(line, "CREATE,TYPE")) PlSqlBlock++;
    //if ((PlSqlBlock==0) && (strpos(strtoupper(line),"OBJECT")>=0)) PlSqlBlock++;

    // "anonymous" PL/SQL block ahead:
    if ((PlSqlBlock==0) &&_fwConfigurationDB_hasKeywords(line, "BEGIN")) PlSqlBlock++;
    if ((PlSqlBlock==0) &&_fwConfigurationDB_hasKeywords(line, "DECLARE")) PlSqlBlock++;
    //if ((PlSqlBlock==0) && (strpos(strtoupper(line),"BEGIN")>=0)) PlSqlBlock++;
    //if ((PlSqlBlock==0) && (strpos(strtoupper(line),"DECLARE")>=0)) PlSqlBlock++;
    // end of PL/SQL block marked by "END" and double semicolon,
    // or the "/" character at the beginning of the line


    if ((PlSqlBlock>0) && 
	_fwConfigurationDB_hasKeywords(line, "END") &&
        //(strpos(strtoupper(line),"END")>=0) &&
        (strpos(line,";;")>=0)
      ) {
      PlSqlBlock--;
    }

    if (PlSqlBlock==0) {
	if (line[0]=="-") continue; // skip comments
	if (strltrim(strrtrim(line))=="") continue; // skip empty lines
    }

    stmt+=line+"\n";

    if ((PlSqlBlock>0) && (strpos(line,"/")==0) ){
      // terminate immediately, strip the "/", and the newline, replace ";" with ";;"
      PlSqlBlock=0;
      stmt=strrtrim(stmt,"/ \n ;");
      stmt=strrtrim(stmt);
      stmt+=";;"; // append the double semicolon, so the processing below works OK!
      dynAppend(sql,stmt);
      stmt="";
      continue;
    }

    // catch eventual situations where we did not process the leading "/", such as in create .. lstagg function
    if (line=="/") { 
	//DebugTN("###TRAILING slash");
        stmt="";
        continue;
    }

    if (PlSqlBlock==0) {
       // we do not interpret what we have inside...

      if (line[strlen(line)-1]==";") {
        // statement is complete!
        dynAppend(sql,stmt);
  //      DebugN("--------END STMT ----------");
        stmt="";
        continue;
      }

    }
  }

    //DebugN(sql);

    // commit previous transaction...
    fwDbCommitTransaction(dbCon);
    int rc;
    for (int i=1;i<=dynlen(sql);i++) {
	string stmt=strrtrim(sql[i]); // trim trailing spaces, endlines, etc
	int len=strlen(stmt);
	//DebugTN("Before processing",stmt);
	if (stmt[len-1]==";") stmt=substr(stmt,0,len-1); // trim the last semicolon at the end; only the last!!!
	//DebugTN("After processing, passed to executeSqlSimple",stmt);
        dyn_string localExceptionInfo;
        fwConfigurationDB_executeSqlSimple(stmt, dbCon, localExceptionInfo);
        if (dynlen(localExceptionInfo) && breakOnDbError) {
            dynAppend(exceptionInfo,localExceptionInfo);
            //fwDbRollbackTransaction (dbCon);
            return;
        };
        //DebugN("\n========"+whatItIs+"========");
    };
}



///@} // end of DB Access functions
//______________________________________________________________________________

// private functions ...
void fwConfigurationDB_dbConnect( string dbConnectionName,
				string connectString, string dbType, string dbName,
                                 string dbUser, string dbSchema, string dbPassword,
                                 dbConnection &dbCon, dyn_string &exceptionInfo, bool errorIfOpenFails=TRUE)
{
    if ( connectString=="") {
        fwException_raise(exceptionInfo,"ERROR","Empty connect string","");
        return;
    }

    if (strpos(dbSchema,";")>=0||strpos(dbSchema,"-")>=0||strpos(dbSchema," ")>=0||strpos(dbSchema,"'")>=0) {
	fwException_raise(exceptionInfo,"ERROR","DbSchema cannot contain special characters","");
	return;
    }

    dbSchema=strtoupper(dbSchema);
    dbUser=strtoupper(dbUser);

    if (strpos(connectString,"<DRIVER>")>=0) {
        string driver;
        _fwConfigurationDB_getDBDriver(dbType, driver, exceptionInfo);
        if (dynlen(exceptionInfo)) return;
        if (strreplace(connectString,"<DRIVER>",driver)!=1) {
            fwException_raise(exceptionInfo,"ERROR","Could not set <DRIVER> in the connect string","");
            return;
        }
    }

    if (strpos(connectString,"<USER>")>=0)
        if (strreplace(connectString,"<USER>",dbUser)!=1) {
            fwException_raise(exceptionInfo,"ERROR","Could not set <USER> in the connect string","");
            return;
        }
    if (strpos(connectString,"<PASSWORD>")>=0)
        if (strreplace(connectString,"<PASSWORD>",dbPassword)!=1) {
            fwException_raise(exceptionInfo,"ERROR","Could not set <PASSWORD> in the connect string","");
            return;
        }
    if (strpos(connectString,"<DBNAME>")>=0)
        if (strreplace(connectString,"<DBNAME>",dbName)!=1) {
            fwException_raise(exceptionInfo,"ERROR", "Could not set <DBNAME> in the connect string","");
            return;
        }

    // for error reporting - we need the connect string without password in open text!
    string fConStr=connectString;
    strreplace(fConStr,dbPassword,"*");

    int rc=fwDbOpenConnection(connectString,dbCon,dbConnectionName);

    if (rc) { // this indicates improper connect string;
	string errTxt;
	rc=fwDbCheckError(errTxt,dbCon);
	
	if (strpos(errTxt,"ORA-12154")>=0) {
	    errTxt="Specified database name is incorrect (ORA-12154)";
	} else 	if (strpos(errTxt,"ORA-01017")>=0) {
	    errTxt="Wrong user name or password (ORA-01017)";	
	}

	
	DebugN(rc,"Failed DB Connection with connect string:",fConStr,errTxt);
	fwException_raise(exceptionInfo,"ERROR in fwConfigurationDB_dbConnect",errTxt,"");
	return;

    }

    // validity check via fwDbOption(Inspect)...
    mixed mLog;
    int rc=fwDbOption("Inspect",dbCon,mLog);

    switch(rc) {
	case 0:
	    // everything OK, connection is open
	    break;

	case 1:
	case 2:
	    // dbConnection not initialized
	    fwException_raise(exceptionInfo,"ERROR in fwConfigurationDB_dbConnect",
		    "Connection not initialized","");
	    DebugN("Failed to initialize connection",fConStr,m);
	    return;
	    break;
	case 3:
	    if (errorIfOpenFails) {
		int i1,i2,i3;
		string s1,s2;
		fwDbGetError(dbCon,i1,i2,i3,s1,s2);
		string sErr=s1+"\n"+s2;

    		if (strpos(sErr,"ORA-01005")>=0) {
        	    sErr="Could not open database connection, empty password (ORA-01005)";
    		} else if (strpos(sErr,"ORA-01017")>=0) {
        	    sErr="Could not open database connection, bad username/password (ORA-01017)";
    		} else if (strpos(sErr,"ORA-12154")>=0) {
        	    sErr="Could not open database connection, bad database name (ORA-12154)";
		}

		fwException_raise(exceptionInfo,"ERROR in fwConfigurationDB_dbConnect",
		    sErr,"");
		return;

	    }
	    break;
	default:
	    fwException_raise(exceptionInfo,"ERROR in fwConfigurationDB_dbConnect",
		    "Unknown state "+rc,"");
	    DebugN("Unknown state of the DB Connection",m);
	    return;
	    break;

    }
    
    // session options:
    string sessionSql="ALTER SESSION SET ";

    // date format:
    sessionSql+= " NLS_DATE_FORMAT = 'YYYY-MM-DD HH24:MI:SS' ";
    
    if (dbSchema!="" && dbSchema!=dbUser) {
	sessionSql+=" CURRENT_SCHEMA = "+dbSchema+" ";
    }

    // set session options
    rc=fwDbSetSqlOnReconnect(dbCon,sessionSql,true);
//    DebugTN("Setting session opts",sessionSql);
    if (rc) {
    
	string errTxt;
	fwDbCheckError(errTxt,dbCon);
	string oraMsg;
	string oraCode=_fwConfigurationDB_extractOraErrCode(errTxt, oraMsg);
	if (oraCode=="ORA-01435") {
	    fwException_raise(exceptionInfo,"ERROR","Cannot set up DB session - invalid schema owner name:"+strtoupper(dbSchema),"");
	} else {
	    fwException_raise(exceptionInfo,"ERROR","Cannot set up session parameters ("+oraCode+")\n"+oraMsg,"");
	}
	fwDbDeleteConnection(dbCon);
	dbConnection empty;
	dbCon=empty;
	return;
    }

    // set the name of the application, so that it is available in SYS_CONTEXT('USERENV','CLIENT_INFO')
    string appInfo="PVSS/fwConfigurationDB-"+_fwConfigurationDB_fileVersion_fwConfigurationDB_ctl;
    dyn_string exceptionInfo2;    
    fwConfigurationDB_executeSqlSimple("BEGIN dbms_application_info.set_client_info('"+appInfo+"');END;", dbCon, exceptionInfo2);
    if (dynlen(exceptionInfo2)) {DebugTN("Could not set client info",(string)exceptionInfo2[2]);return;};


}



void _fwConfigurationDB_getDBDriver(string dbType, string &driver, dyn_string &exceptionInfo)
{

    if (dbType!="ORACLE") {
        fwException_raise(exceptionInfo,"ERROR","Driver type "+dbType+" not supported","");
    }

    mixed mDrivers;
    int rc=fwDbOption("GetDrivers",0,mDrivers);
    if (rc) {
        fwException_raise(exceptionInfo,"ERROR","Cannot get the list of DB drivers","");
        return;
    }

    dyn_string drivers=mDrivers;
    driver="QOCI8";

    if (!dynContains(drivers,driver)) {
        fwException_raise(exceptionInfo,"ERROR","Oracle driver ("+driver+") not available","");
        return;
    }
}




string _fwConfigurationDB_extractOraErrCode(string errTxt, string &oraMsg)
{
    string oraCode;
    string msg="";
    int pos=strpos(errTxt,"ORA-");
    if (pos>=0) {
	string s=substr(errTxt,pos);
	dyn_string t=strsplit(s,"\n");
	msg=substr(t[1],11);
	sscanf(s,"%s",oraCode);
	oraCode=strrtrim(oraCode,":");
    }
    oraMsg=msg;
    return oraCode;
}


void fwConfigurationDB_callPlSqlApi( string  functionName,
				     dyn_mixed functionParams,
				     string inputColumns,
				     string outputColumns,
				     dyn_dyn_mixed inputData,
				     dyn_dyn_mixed &outputData,
				     dyn_string &exceptionInfo,
				     dyn_int outputColumnTypes=0,
				     bool cleanupInputTable=TRUE)
{
    // check all the parameters before we begin, prepare where needed
    string inputDataSql;
    string executeSql;
    string outputDataSql;

    // prepare command for data input
    if (inputColumns!="") {
	// prepare a string with bind parameter names...
	dyn_string ds=strsplit(inputColumns,",");
	string bindInput;
	for (int i=1;i<=dynlen(ds);i++) {
	    bindInput+=":"+ds[i];
	    if (i!=dynlen(ds)) bindInput+=",";
	}
	
	if (dynlen(ds)!=dynlen(inputData)) {
	    fwException_raise(exceptionInfo,"ERROR in fwConfigurationDB_callPlSqlApi","Wrong number of data columns","");
	    DebugN("Error in fwConfigurationDB_callPlSqlApi("+functionName+") -> inputColumns specifies "+dynlen(ds)+
		    " columns, and there are "+dynlen(inputData)+" in inputData");
	    return;
	}

        inputDataSql="INSERT INTO CDB_API_PARAMS("+inputColumns+") VALUES("+bindInput+")";
    }

    // prepare command for data output
    if (outputColumns!="") {
        outputDataSql="SELECT "+outputColumns+" FROM CDB_API_PARAMS";

	// trick to catch the case of outputColumnTypes not being specified -> i.e. use defaults
	if (dynlen(outputColumnTypes)==1 && outputColumnTypes[1]==0) dynClear(outputColumnTypes);

    }

    // prepare command for the API Call
    executeSql="BEGIN fwConfigurationDB."+functionName+"(";
    for (int i=1;i<=dynlen(functionParams);i++) {
	executeSql+=":PAR"+i;
	if (i!=dynlen(functionParams)) executeSql+=",";
    }
    executeSql+="); END;";

    // transaction here???




    if (cleanupInputTable) {
       // cleanup Input/Output table
	fwConfigurationDB_executeSqlSimple("DELETE FROM CDB_API_PARAMS", g_fwConfigurationDB_DBConnection, exceptionInfo);
        if (dynlen(exceptionInfo)) return;
    }

    // put in the input data
    if (inputDataSql!="") {	
	_fwConfigurationDB_executeDBBulkCmd(inputDataSql,g_fwConfigurationDB_DBConnection, inputData,exceptionInfo,TRUE);
	if (dynlen(exceptionInfo)) return;
    }
    // execute the API function
    _fwConfigurationDB_executeDBCmd(executeSql, g_fwConfigurationDB_DBConnection, 
	functionParams, exceptionInfo);

//DebugN("WARNING!!! WE FORCE COMMIT TRANSACTION IN callPlSqlApi() ! REMOVE IT!");
//fwDbCommitTransaction(g_fwConfigurationDB_DBConnection);
	
    if (dynlen(exceptionInfo)) return;
    
    // fetch the output data
    if (outputDataSql!="") {
	dynClear(outputData);
        _fwConfigurationDB_executeDBQuery(outputDataSql,g_fwConfigurationDB_DBConnection, 
    	    outputData, exceptionInfo, 32, TRUE,outputColumnTypes);
        
    }
}
