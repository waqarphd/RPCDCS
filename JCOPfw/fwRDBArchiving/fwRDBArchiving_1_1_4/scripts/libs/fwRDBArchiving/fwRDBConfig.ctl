/**@file

A library including the necessary functions to get and change RDB Archiving parameters

@par Creation Date
	6/4/2006	

@author 
	Angela Brett
*/

/** @par Constraints
	None
	
@par Usage
	Public
	
@par PVSS managers
	RDB

\return the host used for RDB archiving */
string fwRDBConfig_getHost() {
	return getRDBSetting(hostDPE);
}

/** 
Sets the host for RDB archiving to \a newHost 
The RDB Archive manager must be restarted after this is done.

@par Constraints
	None
	
@par Usage
	Public
	
@par PVSS managers
	RDB */
void fwRDBConfig_setHost(string newHost) {
	setRDBSetting(hostDPE,newHost);
	setConfigValue("ValueArchiveRDB","db", newHost);
}

/** @par Constraints
	None
	
@par Usage
	Public
	
@par PVSS managers
	RDB

\return the username used for RDB archiving */
string fwRDBConfig_getUser() {
	return getRDBSetting(userDPE);
}

/** 
Sets the username for RDB archiving to \a newUser 
The RDB Archive manager must be restarted after this is done.

@par Constraints
	None
	
@par Usage
	Public
	
@par PVSS managers
	RDB
 */
void fwRDBConfig_setUser(string newUser) {
	setRDBSetting(userDPE,newUser);
	setConfigValue("ValueArchiveRDB", "Dbuser", newUser);
}

/** 

Sets the password for RDB archiving to \a newPassword 
The RDB Archive manager must be restarted after this is done.

@par Constraints
	None
	
@par Usage
	Public
	
@par PVSS managers
	RDB */
void fwRDBConfig_setPassword(string newPassword) {
	string cryptedPwd;
  cryptAESRDB(newPassword,cryptedPwd);
  setRDBSetting("password",cryptedPwd);
}

/* Internal functions start here!

		*** *   * ***** ***** ****  *   *  ***  *       ***** *   * *   *  ***  ***** ***  ***  *   *  ***
		 *  **  *   *   *     *   * **  * *   * *       *     *   * **  * *   *   *    *  *   * **  * *   *
		 *  **  *   *   *     *   * **  * *   * *       *     *   * **  * *       *    *  *   * **  * *   
		 *  * * *   *   ****  ****  * * * ***** *       ****  *   * * * * *	  *    *  *   * * * *  ***
		 *  *  **   *   *     *   * *  ** *   * *       *     *   * *  ** *       *    *  *   * *  **     *
		 *  *  **   *   *     *   * *  ** *   * *       *     *   * *  ** *   *   *    *  *   * *  ** *   *
     	*** *   *   *   ***** *   * *   * *   * *****   *      ***  *   *  ***    *   ***  ***  *   *  ***
	
*/

dbConnection	conGeneral;

//executes the SQL command sSQL, disregarding any returned rows.
//assumes the connection to the database has already been opened.
//fwRDBConfig_executeSQLCommand("CALL ENABLEARCHIVING('"+mode+"')");
void fwRDBConfig_executeSQLCommand(string sSQL) {
	dyn_dyn_mixed bindValues;
	executeSQLCommand(sSQL,bindValues);
}

void fwRDBConfig_closeConnection() {
	//DebugN("Closing connection");
	rdbCloseConnection(conGeneral);
}

string getRDBError(string operation,int rc) {
	// check for PVSS errors
	if (rc) {
		dyn_errClass err=getLastError();
		/*if (dynlen(err))*/ return "PVSS error "+operation+": "+err;
	}
	// and check for DB errors
	int i1,i2,i3;
	string err1, err2;
	rc=rdbGetError(conGeneral,i1,i2,i3,err1,err2);
	if (rc) {
		return "ERROR "+err1+","+err2;
	}
	return "";
}

bool fwRDBConfig_openConnection(string dbName,string user,string password) {
		string connectString;
		int 			rc;
		dyn_string		exceptionInfo;	
	//db_connectStr = "driver=<DRIVER>;dbq=<DBNAME>;Uid=<USER>;Pwd=<PASSWORD>;" ;
	connectString = "driver=QOCI8;server=localhost;uid="+user+";pwd="+password+";database="+dbName+";" ;
/*fwConfigurationDB_dbConnect (db_connectStr, "ORACLE",dbName,user, password, conGeneral, exceptionInfo);
if(dynlen(exceptionInfo) > 0)
					{
						fwExceptionHandling_display(exceptionInfo);
						return false;
}*/

	int rc=rdbOpenConnection(connectString,conGeneral,"");
	string error=getRDBError("opening connection",rc);
	if (strlen(error)) {
		DebugN(error);
		return false;
	}
	// print out the status of the dbcon
	mixed retval;
	rc=rdbOption("Inspect",conGeneral,retval);
	DebugN(rc,retval);
	return true;
}

string getRDBSetting(string dpe) {	
	string dpName="_RDBArchive.db."+dpe;
	string value;
	if (dpExists(dpName)) dpGet(dpName,value);
	return value;
}

//argh, we're setting a setting, if only I could think of a better name... luckily this is a private function.
void setRDBSetting(string dpe,string newValue) {
	//we have to set the same values in both _RDBArchive dps.
	//The actual _RDBArchive dp names depend on the setup, but _RDBArchive and _RDBArchive_2 are the defaults.	
	string dpName="_RDBArchive.db."+dpe; 
	string dpName2="_RDBArchive_2.db."+dpe;
	if (dpExists(dpName)) dpSet(dpName,newValue);
	if (dpExists(dpName2)) dpSet(dpName2,newValue);
}

const string hostDPE="host";
const string userDPE="user";

/*
Sets the value of the key in section sectionName of the config file to value.
If there already is an entry for that key, it will be changed. Otherwise, one will be added.
If the section does not exist, it will be added.
If there is more than one entry for that key, they will all be changed... but you would usually
use this function for the sort of key which can only have one value (otherwise you could use paCfgInsertValue)
returns 0 - "success"  -1 - error
*/
int setConfigValue(string sectionName,string key,string value,bool quote=true) {
	dyn_string section;
	int entryIndex;
	dyn_string entry;
	string newEntry=key;
	if (quote) newEntry+=" = \""+value+"\"";
	else newEntry+=" = "+value;

	if (findConfigEntry(sectionName,key,section,entryIndex)) {
		section[entryIndex]=newEntry;
	} else {
		dynAppend(section,newEntry);
	}
	return fwInstallation_setSection(sectionName,section);
}

bool getConfigValue(string sectionName,string key,string &value) {
	dyn_string section;
	int entryIndex;
	dyn_string entry;
	if (findConfigEntry(sectionName,key,section,entryIndex)) {
		dyn_string entry;
		entry=strsplit(section[entryIndex],"=");
		value=strrtrim(strltrim(entry[2]));
		value=strrtrim(strltrim(value,"\""),"\"");
		return true;
	} else {
		return false;
	}
}

bool findConfigEntry(string sectionName,string key,dyn_string &section,int &index) {
	int entryIndex;
	dyn_string entry;
	bool entryExists=false;
	int getSectionError=fwInstallation_getSection(sectionName,section);
	if (getSectionError==0) {
		for (entryIndex=1;entryIndex<=dynlen(section);entryIndex++) {
			entry=strsplit(section[entryIndex],"=");
			if (dynlen(entry)>1) {
				if (strtolower(strrtrim(strltrim(entry[1])))==strtolower(key)) {
					index=entryIndex;
					entryExists=true;
				}
			}
		}
	}
	return entryExists;
}

string getConfigFilePath() {
	return getPath(CONFIG_REL_PATH) + "config";
}

//returns value in single quotes, or the string NULL if value is NULL
string quoted(string value) {
	if (value) return "'"+value+"'";
	else return "NULL";
}

string resolveAlias(string dpName) {
	string resolved;
	if (dpExists(dpName)) return dpName; //in case the same string is both an actual DP and an alias to a different one, give preference to the actual DP.
	//if (dynContains(dpAliases(dpName),dpName)) //this is too slow
	resolved=dpAliasToName(dpName);
	if (resolved) return resolved;
	return dpName;
}

//adds the alias name for the DP which the supplied dpe is in to the aliases table.
//assumes the database connection has already been opened.
void writeIntoAliasTableIfNecessary(string dpename,dyn_string &DPsAdded) {
		//it might seem strange to be resolving an alias only to then find out the alias,
		//but we are finding the alias for the DP itself, not the DPE. DPE aliases are written to the database automatically.
		//DPsAdded keeps a record of which DP names have been added, so that the same ones won't be added many times. This makes no difference to the database, since recordAliasChange only writes alias information if the alias has changed. However it's inefficient to call the database a lot of times to do nothing.
		string dpName=dpSubStr(resolveAlias(dpename),DPSUB_SYS_DP)+".";
		if (!dynContains(DPsAdded,dpName)) {
			string alias=dpGetAlias(dpName);
			mapping bindValues;
			bindValues["dpname"]=dpName;
			bindValues["alias"]=alias;
			string sSQL="call recordAliasChange(:dpname,:alias)";
			executeSQLCommand(sSQL,bindValues);
			dynAppend(DPsAdded,dpName);
		}
}

bool runSQL(string sql,mapping &bindVariables,dyn_dyn_mixed &data,bool getData,bool columnWise=true) {
	int rc;
	dbRecordset rs;
	dbCommand cmd;
	string error;
	
	DebugN(sql);
	rc=rdbStartCommand(conGeneral, sql, cmd);
	error=getRDBError("starting command",rc);
	if (!strlen(error)) {
		if (mappinglen(bindVariables)) {
			rc=rdbBindParams(cmd,bindVariables);
			error=getRDBError("binding variables",rc);
		}
		if (!strlen(error)) {
			rc=rdbExecuteCommand(cmd);
			error=getRDBError("executing command",rc);
			if (!strlen(error)) {
				if (getData) {
					int maxRecords=0;
					rc=rdbGetData(cmd, data, columnWise, maxRecords);
					error=getRDBError("getting data",rc);
				}
				if (!strlen(error)) {
					rdbFinishCommand(cmd);
					//DebugN(data);
					return true;
				}
			}
		}
	}
	bool ok;
	dyn_string exceptionInfo;
	fwGeneral_openMessagePanel  (  error, ok, exceptionInfo, "Error running SQL statement",  true);  
	return false;
}

//executes the SQL command sSQL, disregarding any returned rows.
//assumes the connection to the database has already been opened.
void executeSQLCommand(string sql,mapping &bindVariables) {
	dyn_dyn_mixed data;
	runSQL(sql,bindVariables,data,false);
}

bool runSelectCommand(string sql,dyn_dyn_mixed &data,mapping &bindVariables,bool columnWise=true) {
	//DebugN(columnWise);
	return runSQL(sql,bindVariables,data,true,columnWise);
}
