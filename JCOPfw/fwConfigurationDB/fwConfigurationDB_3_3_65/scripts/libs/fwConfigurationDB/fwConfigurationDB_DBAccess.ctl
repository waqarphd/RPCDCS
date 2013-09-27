/**@file

This package contains database access functions of the Configuration Database tool

@author Piotr Golonka (EN/ICE-SCD)
@date   April 2011
*/

global string _fwConfigurationDB_fileVersion_fwConfigurationDB_DBAccess_ctl="3.3.65";

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

    string description, connectString,dbType,dbName,dbUser,dbPassword;

    // check if the connection is already in the pool managed by CtrlRDBAccess...
    dyn_string conNames;
    int rc=rdbGetConnectionNames(conNames);
    if (rc) {
	fwException_raise(exceptionInfo,"ERROR","Could not get connection names","");
	return;
    }

    if (dynContains(conNames,dbConnectionName)) {
	int rc=rdbGetConnection(dbConnectionName,dbCon);
	if (rc) {
	    fwException_raise(exceptionInfo,"ERROR","Could not get connection "+dbConnectionName,"");
	    return;
	}
	return;
    }


    fwConfigurationDB_getDBConnection(dbConnectionName,
                            	    description, dbType, dbName,
                                    dbUser,dbPassword, connectString,
                                    exceptionInfo);
    if (dynlen(exceptionInfo)) return;


/*
    int rc=dpGet(dpName+".version",version)
    if (version<fwConfigurationDB_version) {
        DebugN("WARNING!","Connection "+dbConnectionName+" has version="+version+
                " older than current version="+fwConfigurationDB_version);
    }
*/
    fwConfigurationDB_dbConnect(dbConnectionName,connectString, dbType,dbName, dbUser, dbPassword, dbCon, exceptionInfo);

    if (dynlen(exceptionInfo)) {
        // append some more information to the exception info
        fwException_raise(exceptionInfo,"ERROR","Failed to open connection:"+dbConnectionName,"");
        return;
    }
//    DebugN("Database connection opened succesfully:",dbConnectionName);
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


void _fwConfigurationDB_executeDBQuery(string sql,dbConnection conn, dyn_dyn_mixed &aRecords, dyn_string &exceptionInfo, 
int numCol=999, bool columnWise=FALSE, dyn_int colTypes=0)
{

    // fix for the default value of the parameter...
    if ( (dynlen(colTypes)==1) && (colTypes[1]==0)) dynClear(colTypes);

    if (g_fwConfigurationDB_DebugSQL & 1) DebugN("Query SQL:",sql);

    if (fwConfigurationDB_progress(fwConfigurationDB_OPER_DBQuery,"Executing SQL query", 0.0,
                                   exceptionInfo)) return;

    dbCommand cmd;
    string errTxt;

    int rc = rdbStartCommand (conn, sql, cmd);
    if (rc) {
	rdbCheckError(errTxt,cmd);
	string oraMsg;
	string oraCode=_fwConfigurationDB_extractOraErrCode(errTxt, oraMsg);
	DebugN("ERROR:Could not initialize SQL query",sql);
	DebugN("     "+errTxt);
	fwException_raise(exceptionInfo,"ERROR","DB Query initialization error ("+oraCode+")\n"+oraMsg,"");
	//rdbFinishCommand (cmd);
	return;
    }

    rc = rdbExecuteCommand (cmd);
    if (rc) {
	rdbCheckError(errTxt,cmd);
	string oraMsg;
	string oraCode=_fwConfigurationDB_extractOraErrCode(errTxt, oraMsg);
	DebugN("ERROR:Could not execute SQL query",sql);
	DebugN("     "+errTxt);
	fwException_raise(exceptionInfo,"ERROR","DB Query execution error ("+oraCode+")\n"+oraMsg,"");
	rdbFinishCommand (cmd);
	return;
    }

    if (dynlen(colTypes)) {
	int maxRecords=0; // 0 means no limit
	rc=rdbGetData(cmd,aRecords,columnWise,maxRecords,colTypes);
    } else {
	rc=rdbGetData(cmd,aRecords,columnWise);
    }
    if (rc) {
	rdbCheckError(errTxt,cmd);
	string oraMsg;
	string oraCode=_fwConfigurationDB_extractOraErrCode(errTxt, oraMsg);
	DebugN("ERROR:Could not get data from SQL query",sql);
	DebugN("     "+errTxt);
	fwException_raise(exceptionInfo,"ERROR","DB Query data fetch error ("+oraCode+")\n"+oraMsg,"");
	rdbFinishCommand (cmd);
	return;
    }

    rc = rdbFinishCommand (cmd); //closes subset
    if (fwConfigurationDB_progress(fwConfigurationDB_OPER_DBQuery,"SQL query executed", 100.0,
                                   exceptionInfo)) return;

    if (g_fwConfigurationDB_DebugSQL & 4) {
	int nresults=dynlen(aRecords);
	if (columnWise) {
	    if (dynlen(aRecords)>=1) nresults=dynlen(aRecords[1]);
	    else nresults=0;
	}
	DebugN("Query SQL:"+nresults+" result(s) fetched");
    }
    if (g_fwConfigurationDB_DebugSQL & 8) DebugN("Query SQL results:\n",aRecords);
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

    if (g_fwConfigurationDB_DebugSQL & 1) DebugN("Execute Bulk SQL:",sql);
    if (g_fwConfigurationDB_DebugSQL & 4) DebugN("       with "+dynlen(data)+" records");
    if (g_fwConfigurationDB_DebugSQL & 8) DebugN("       with data:\n",params);

    dbCommand cmd;
    string errTxt;
    
    int rc = rdbStartCommand (conn, sql, cmd);
    if (rc) {
	rdbCheckError(errTxt,cmd);
	string oraMsg;
	string oraCode=_fwConfigurationDB_extractOraErrCode(errTxt, oraMsg);
	DebugN("ERROR:Could not initialize SQL command",sql);
	DebugN("     "+errTxt);
	fwException_raise(exceptionInfo,"ERROR","DB Command initialization error ("+oraCode+")\n"+oraMsg,"");
	//rdbFinishCommand (cmd);
	return;
    }

    rc = rdbBindAndExecute(cmd,params);
    if (rc) {
	rdbCheckError(errTxt,cmd);
	string oraMsg;
	string oraCode=_fwConfigurationDB_extractOraErrCode(errTxt, oraMsg);
	DebugN("ERROR:Could not execute SQL command",sql);
	DebugN("     "+errTxt);
	fwException_raise(exceptionInfo,"ERROR","DB Command execution error ("+oraCode+")\n"+oraMsg,"");
	rdbFinishCommand (cmd);
	return;
    }

    rc = rdbFinishCommand (cmd);
    if (fwConfigurationDB_progress(fwConfigurationDB_OPER_DBQuery,"SQL command executed", 100.0,
                                   exceptionInfo)) return;

}



void _fwConfigurationDB_executeDBCmd(string sql,dbConnection conn, dyn_mixed params, dyn_string &exceptionInfo)
{
    
    if (fwConfigurationDB_progress(fwConfigurationDB_OPER_DBQuery,"Executing SQL command", 0.0,
                                   exceptionInfo)) return;

    if (g_fwConfigurationDB_DebugSQL & 1) DebugN("Execute SQL:",sql);
    if (g_fwConfigurationDB_DebugSQL & 4) DebugN("       with params:\n",params);

    dbCommand cmd;
    string errTxt;
    
    int rc = rdbStartCommand (conn, sql, cmd);
    if (rc) {
	rdbCheckError(errTxt,cmd);
	string oraMsg;
	string oraCode=_fwConfigurationDB_extractOraErrCode(errTxt, oraMsg);
	DebugN("ERROR:Could not initialize SQL command",sql);
	DebugN("     "+errTxt);
	fwException_raise(exceptionInfo,"ERROR","DB Command initialization error ("+oraCode+")\n"+oraMsg,"");
	//rdbFinishCommand (cmd);
	return;
    }

	rc = rdbBindParams(cmd,params);
	if (rc) {
	    rdbCheckError(errTxt,cmd);
	    string oraMsg;
	    string oraCode=_fwConfigurationDB_extractOraErrCode(errTxt, oraMsg);
	    DebugN("ERROR:Could not bind params for SQL command",sql);
	    DebugN("     "+errTxt);
	    fwException_raise(exceptionInfo,"ERROR","DB parameter bind error ("+oraCode+")\n"+oraMsg,"");
	    rdbFinishCommand (cmd);
	    return;
	}

    rc = rdbExecuteCommand(cmd);
    if (rc) {
	rdbCheckError(errTxt,cmd);
	string oraMsg;
	string oraCode=_fwConfigurationDB_extractOraErrCode(errTxt, oraMsg);
	DebugN("ERROR:Could not execute SQL command",sql);
	DebugN("     "+errTxt);
	fwException_raise(exceptionInfo,"ERROR","DB Command execution error ("+oraCode+")\n"+oraMsg,"");
	rdbFinishCommand (cmd);
	return;
    }

    rc = rdbFinishCommand (cmd);
    if (fwConfigurationDB_progress(fwConfigurationDB_OPER_DBQuery,"SQL command executed", 100.0,
                                   exceptionInfo)) return;

}


void _fwConfigurationDB_startCommand(string sql, dbConnection &connection, anytype &dbCmd, dyn_string &exceptionInfo)
{
    // once we will get variable binding, we will do dbStartCommand (connection, cmdStr, command);
    // and return the actual dbCommand handle in "cmd". For now, we leave it dummy,
    // because we need to prepare all the statements individually anyway...

    // as of now we will store the SQL string and some information about the place-holders

    dyn_mixed  cmdStruct;
    dbCommand  command;
    dyn_string paramsNames;

    // find the positional parameters for binding
    dyn_string tmp=strsplit(sql,":");
    // the first one in the command, like "INSERT", so we start with number 2...
    for (int i=2;i<=dynlen(tmp);i++) {
        //use the characters only up to the next space, comma, brace
        string token=":"; // start the name with ":" which was removed by strsplit
        for (int k=0;k<strlen(tmp[i]);k++) {
            bool endOfToken=FALSE; // we will not be able to use "break" because we use switch()...
            switch ((tmp[i])[k]) {
                case ' ':
                case '\'':
                case ',':
                case '(':
                case ')':
                case '=':
                case '<':
                case '>':
                case '!':
                    endOfToken=TRUE;
                    break;
                default:
                    token=token+(tmp[i])[k];
                    break;
            };
            if (endOfToken || (k==strlen(tmp[i]))) {
                dynAppend(paramsNames,token);
                break; // now we can use it
            };
        };
    }
    cmdStruct[1]=sql;        // the SQL string
    cmdStruct[2]=connection; // the dbConnection
    cmdStruct[3]=paramsNames;// names of the positional parameters
    dbCmd=cmdStruct;


}

void _fwConfigurationDB_finishCommand(anytype &dbCmd, dyn_string &exceptionInfo)
{
    // dummy in the implementation with no bound variables ...
    //dynClear(dbCmd);
}

void _fwConfigurationDB_bindExecuteCommand(anytype &dbCmd, mapping params, dyn_string &exceptionInfo)
{
    if (getType(dbCmd)!=DYN_MIXED_VAR) {
        fwException_raise(exceptionInfo,"ERROR","Invalid DB Command passed for execution: bad type "+getType(dbCmd),"");
        return;
    }
    if (dynlen(dbCmd)!=3) {
        fwException_raise(exceptionInfo,"ERROR","Invalid DB Command passed for execution","");
        return;
    }

    dyn_string ReqParams=dbCmd[3];
    dyn_string availParams=mappingKeys(params);
    string sql=dbCmd[1];
    for (int i=1;i<=dynlen(ReqParams);i++) {
        if (!dynContains(availParams,ReqParams[i])) {
            fwException_raise(exceptionInfo,"ERROR","Parameter "+ReqParams[i]+" not bound.","");
            return;
        }
        strreplace(sql,ReqParams[i],params[ReqParams[i]]);

    };
    fwConfigurationDB_executeSqlSimple(sql, dbCmd[2], exceptionInfo);
    if (dynlen(exceptionInfo)) {
	dynClear(exceptionInfo);
	string errTxt;
	rdbCheckError(errTxt,dbCmd[2]);
	DebugN("Cannot execute SQL command:\n",sql,"\n"+errTxt);
        fwException_raise(exceptionInfo,"ERROR in _fwConfigurationDB_bindExecuteCommand","Cannot execute command (see log)","");
        return;
    }
}


void fwConfigurationDB_executeSqlSimple(string sql, dbConnection connection,dyn_string &exceptionInfo)
{
    if (g_fwConfigurationDB_DebugSQL & 2) DebugN("Execute SQL:",sql);

    // fix for executing PL/SQL statements - they need to contain semicolon after the "END" statement
    if (substr(strltrim(strtoupper(sql)),0,5)=="BEGIN") {
	sql=strrtrim(sql);// trim whitespaces
	sql=strrtrim(sql,";"); // trim all semicolons that exist
	sql=sql+";"; // add a single semicolon
    }

    int rc=rdbExecuteSqlStatement(connection, sql);
    if (rc<0) {
	fwException_raise(exceptionInfo,"ERROR in fwConfigurationDB_executeSqlSimple","Cannot execute SQL Statement;rc="+rc,"");
	string errTxt;
	rdbCheckError(errTxt,connection);
	DebugN("Cannot execute SQL command",sql,errTxt);
//	DebugTN(getLastError());
	return;
    } else if (rc==1){
	string errTxt;
	rdbCheckError(errTxt,connection);
	DebugN("Cannot execute SQL command",sql,errTxt);
	fwException_raise(exceptionInfo,"ERROR in fwConfigurationDB_executeSqlSimple","Cannot execute SQL statement (see log)","");
	return;
    } else if (rc==2){
	DebugN("Warning, fwConfigurationDB_executeSqlSimple, executing SQL Select statement via rdbExecuteSqlStatement - no data will be returned",sql);
    }
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

    if (line[0]=="-") continue; // skip comments

    stmt+=line+"\n";

    // PL/SQL package begins...
    if (
	 (strpos(strtoupper(line),"PACKAGE")>=0)&&
	 (strpos(strtoupper(line),"CREATE")>=0)
	) PlSqlBlock++;
    // "anonymous" PL/SQL block ahead:
    if ((PlSqlBlock==0) && (strpos(strtoupper(line),"BEGIN")>=0)) PlSqlBlock++;
    if ((PlSqlBlock==0) && (strpos(strtoupper(line),"DECLARE")>=0)) PlSqlBlock++;
    // end of PL/SQL block marked by "END" and double semicolon,
    // or the "/" character at the beginning of the line
    if ((PlSqlBlock>0) &&
        (strpos(strtoupper(line),"END")>=0) &&
        (strpos(line,";;")>=0)
      ) {
      PlSqlBlock--;
    }
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
    rdbCommitTransaction(dbCon);
    int rc=rdbBeginTransaction(dbCon);
    if (rc) {
	   //bool invalidConnection;
	   //_fwConfigurationDB_catchDbError(dbCon, invalidConnection, exceptionInfo);
	   fwException_raise(exceptionInfo,"ERROR","Cannot start transaction","");
	   return;
    };

    for (int i=1;i<=dynlen(sql);i++) {
	string stmt=strrtrim(sql[i]); // trim trailing spaces, endlines, etc
	int len=strlen(stmt);
	if (stmt[len-1]==";") stmt=substr(stmt,0,len-1); // trim the last semicolon at the end; only the last!!!
        dyn_string localExceptionInfo;
        fwConfigurationDB_executeSqlSimple(stmt, dbCon, localExceptionInfo);
        if (dynlen(localExceptionInfo) && breakOnDbError) {
            dynAppend(exceptionInfo,localExceptionInfo);
            rdbRollbackTransaction (dbCon);
            return;
        };
        //DebugN("\n========"+whatItIs+"========");
    };

    rc=rdbCommitTransaction(dbCon);
    // save the hierarchy...
    if (rc) {
	bool invalidConnection;
	//_fwConfigurationDB_catchDbError(dbCon, invalidConnection, exceptionInfo);
	fwException_raise(exceptionInfo,"ERROR","Cannot commit transaction","");
	return;
    };

}



///@} // end of DB Access functions
//______________________________________________________________________________

// private functions ...
void fwConfigurationDB_dbConnect( string dbConnectionName,
				string connectString, string dbType, string dbName,
                                 string dbUser, string dbPassword,
                                 dbConnection &dbCon, dyn_string &exceptionInfo, bool errorIfOpenFails=TRUE)
{
    if ( connectString=="") {
        fwException_raise(exceptionInfo,"ERROR","Empty connect string","");
        return;
    }


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

    int rc=rdbOpenConnection(connectString,dbCon,dbConnectionName);


    if (rc) { // this indicates improper connect string;
	string errTxt;
	rc=rdbCheckError(errTxt,dbCon);
	
	if (strpos(errTxt,"ORA-12154")>=0) {
	    errTxt="Specified database name is incorrect (ORA-12154)";
	} else 	if (strpos(errTxt,"ORA-01017")>=0) {
	    errTxt="Wrong user name or password (ORA-01017)";	
	}

	
	DebugN(rc,"Failed DB Connection with connect string:",fConStr,errTxt);
	fwException_raise(exceptionInfo,"ERROR in fwConfigurationDB_dbConnect",errTxt,"");
	return;

    }

    // validity check via rdbOption(Inspect)...
    mixed mLog;
    int rc=rdbOption("Inspect",dbCon,mLog);

    switch(rc) {
	case 0:
	    return; // everything OK, connection is open
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
		rdbGetError(dbCon,i1,i2,i3,s1,s2);
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
    
    // set session options:
    
    // date format:
    fwConfigurationDB_executeSqlSimple("ALTER SESSION SET NLS_DATE_FORMAT = 'YYYY-MM-DD HH24:MI:SS'",dbCon ,exceptionInfo);

}



void _fwConfigurationDB_getDBDriver(string dbType, string &driver, dyn_string &exceptionInfo)
{

    if (dbType!="ORACLE") {
        fwException_raise(exceptionInfo,"ERROR","Driver type "+dbType+" not supported","");
    }

    mixed mDrivers;
    int rc=rdbOption("GetDrivers",0,mDrivers);
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



void _fwConfigurationDB_checkSequenceSane(dbConnection conn, string seqName, string tblName, string colName, dyn_string &exceptionInfo)
{
    string sql1="SELECT seq.last_number FROM user_sequences seq WHERE seq.sequence_name=\'"+seqName+"\'";
    string sql2="SELECT MAX("+colName+") FROM "+tblName;
    string sql3="SELECT "+seqName+".NextVal FROM DUAL";
    dyn_dyn_mixed a1,a2,a3;

    _fwConfigurationDB_executeDBQuery(sql1,conn, a1, exceptionInfo, 1);
    if (dynlen(exceptionInfo)) return;
    _fwConfigurationDB_executeDBQuery(sql2,conn, a2, exceptionInfo, 1);
    if (dynlen(exceptionInfo)) return;

    if (dynlen(a1)!=1) {fwException_raise(exceptionInfo,"ERROR","Cannot get sequence "+seqName,""); return;}
    if (dynlen(a2)!=1) {fwException_raise(exceptionInfo,"ERROR","Cannot get max idx of "+tblName,""); return;}
    int seqIdx=a1[1][1];
    int maxIdx=a2[1][1];
    if (seqIdx>=maxIdx) return;

    DebugN("Winding up sequence :"+seqName+" to index "+maxIdx);
    int diff=maxIdx-seqIdx;
    dyn_int seq;
    _fwConfigurationDB_getBatchOfSequenceNumbers(conn, seqName, diff, seq, exceptionInfo);
    if (dynlen(exceptionInfo)) return;
    /*
    while (seqIdx<maxIdx) {
	_fwConfigurationDB_executeDBQuery(sql3,conn, a3, exceptionInfo, 1);
	if (dynlen(exceptionInfo)) return;
	seqIdx=a3[1][1];
    }
    */


}

void _fwConfigurationDB_getBatchOfSequenceNumbers(dbConnection conn, string seqName, int howMany, dyn_int &seq, dyn_string &exceptionInfo)
{
    dynClear(seq);

    string sql="BEGIN fwConfigurationDB.t_getSequenceNumbers(\'"+seqName+"\',"+howMany+");END";
    fwConfigurationDB_executeSqlSimple(sql,conn,exceptionInfo);
    if (dynlen(exceptionInfo)) return;

    string sql2="SELECT i1 FROM CDB_API_PARAMS";
    dyn_dyn_mixed aRecords;
    _fwConfigurationDB_executeDBQuery(sql2,conn,aRecords , exceptionInfo,1,TRUE);
    if (dynlen(exceptionInfo)) return;
    seq=aRecords[1];
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
//rdbCommitTransaction(g_fwConfigurationDB_DBConnection);
	
    if (dynlen(exceptionInfo)) return;
    
    // fetch the output data
    if (outputDataSql!="") {
	dynClear(outputData);
        _fwConfigurationDB_executeDBQuery(outputDataSql,g_fwConfigurationDB_DBConnection, 
    	    outputData, exceptionInfo, 32, TRUE,outputColumnTypes);
        
    }
}
