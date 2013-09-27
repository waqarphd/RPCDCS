#uses "fwXML/fwXML.ctl"
#uses "fwInstallation.ctl"
#uses "fwRDBArchiving/fwRDBConfig.ctl"
#uses "fwDIP/fwDIP.ctl"
#uses "fwNode/fwNode.ctl"


    


/*** Utilities for Configuration DB
     These functions are adapted from CMSfwInstallUtils ***/

void fwInstallationUtils_initPmonVars() {
  //Initialize the PMON variables:
  if ( !globalExists("gFwInstallationPmonUser") )   {
    addGlobal("gFwInstallationPmonUser", STRING_VAR);
  }
                                       
  if ( !globalExists("gFwInstallationPmonPwd") ) {
    addGlobal("gFwInstallationPmonPwd", STRING_VAR);
  }


  gFwInstallationPmonUser = "N/A";                                           
  gFwInstallationPmonPwd = "N/A";
   
}

string fwInstallationUtils_getWCCOAExecutable(string manager) {
  dyn_string prefixes = makeDynString("PVSS00","WCCIL","WCCOA");
  for (int i=1; i<= dynlen(prefixes); i++) {
    if (strpos(manager, prefixes[i]) == 0) {
      manager = substr(manager, strlen(prefixes[i]));
      break;
    }
  }
  if (isFunctionDefined("fwInstallation_getWCCOAExecutable") ) {
    return fwInstallation_getWCCOAExecutable(manager);
  }

  return "PVSS00" + manager;
}

string fwInstallationUtils_getManagerName(string manager) {
  if(VERSION_DISP != "3.8-SP2" &&
     VERSION_DISP != "3.8" && strpos(manager,"PVSS00") ==0)  
    {
      strreplace(manager, "PVSS00","");
    }
   
  if (strpos(manager, "WCC") == 0) return manager;
  return fwInstallationUtils_getWCCOAExecutable(manager);  
}


int fwInstallationUtils_startRdbManager( string host = "", 
					 int port = 4999, 
					 string user = "", 
					 string pwd = "") {
  
  string dbhost, dbuser;
  
  // The information has been written to the data point during the adoption process
  // the functions will write to the config file
  
  dpGet("_RDBArchive.db.host", dbhost,
        "_RDBArchive.db.user", dbuser);
  if (dbhost == "" || dbuser == "") {
      DebugTN("Host and user not set in the rdb");
      return -1;
  }
  fwRDBConfig_setHost(dbhost);
  fwRDBConfig_setUser(dbuser);
      
        
  fwInstallationUtils_initPmonVars();
  if(fwInstallationManager_setMode(fwInstallationUtils_getWCCOAExecutable("rdb"), "-num 99", "always", host, port, user, pwd) < 0)
    {
      fwInstallation_throw("fwInstallation_startRdb()-> Could not change manager: PVSS00rdb -num 99 start mode to always");
      return -1;
    }
  return 0;
}

/** 
 * Switch between the real driver and the simulator
 *
 @param driver if true start the driver and stop the simulator, if false start the simulator and stop the driver
 @param name 
 @param number 
 @return 
*/
bool fwInstallationUtils_switchSimDriver(bool driver, string name, int number) {
  fwInstallationUtils_initPmonVars();
  

  // fwInstallation_throw("Current user and pwd "+ gFwInstallationPmonUser + " " + gFwInstallationPmonPwd ,"INFO",10) ;
  return (fwInstallationUtils_fwInstallationManager_switch(driver, name, number) == 0);
}




/**
 * This is an alternative version of fwInstallationManager_switch that contains some bugfixes. 
 * Please change fwInstallationUtils_switchSimDriver to use the original  function if Fernando agrees to fix the function
 */

/** This function switches between the real driver and the simulator.

    @param driver	  if set to one the real driver is started, otherwise the simulator
    @param name			manager type
    @param number		driver number
    @param host	hostname
    @param port	pmon port
    @param user	pmon user
    @param pwd		pmon password

    @return 0 if OK, -1 if error
*/
int fwInstallationUtils_fwInstallationManager_switch(bool driver, 
						     string name, 
						     int number, 
						     string host = "", 
						     int port = 4999, 
						     string user = "", 
						     string pwd = "") 
{
  name = fwInstallationUtils_getManagerName(name);
  
  string msg = "Switching to " + (driver?"Driver":"Simulation Driver") + " for " + name;

  string sim = fwInstallationUtils_getWCCOAExecutable("sim");
  string dip = fwInstallationUtils_getWCCOAExecutable("dip");
  fwInstallation_throw(msg, "INFO", 10);


  dyn_mixed managerInfo;
  dyn_mixed simInfo;
  if(host == "")
    {
      host = fwInstallation_getHostname(); 
      port = pmonPort();
    }

  if(user == "")
    if(fwInstallation_getPmonInfo(user, pwd) != 0)
      {
	fwInstallation_throw("fwInstallationManager_switch: Could not resolve pmon username and password. Action aborted", "error", 1);
	return -1;
      }
  if (name == dip) {
    string mode = driver?"always":"manual";
    fwInstallation_throw("Setting dip: -num " + number + " to " + mode, "INFO", 10);
    if(fwInstallationManager_setMode(name, "-num " + number, mode, host, port, user, pwd) < 0)   {
      fwInstallation_throw("fwInstallationUtils_switchSimDriver()-> Could not change dip driver: " + number + " start mode to manual");
      return -1;
    }
    
    if (! driver) {
      fwInstallation_throw("Stopping" + "  " + name + " -num " + number , "INFO", 10);
      if(fwInstallationManager_command("STOP", name, "-num " + number,  host, port, user, pwd) < 0)
	{
	  fwInstallation_throw("fwInstallationManager_switch()-> Could not stop manager: " + name + " -num " + number);
	  return -1;
	}
  
      bool expired;
      fwInstallation_throw("Waiting for " + "  " + name + " -num " + number + " to stop " , "INFO", 10);
      fwInstallationManager_wait(driver, name, "-num " + number, 60, expired);

    }
    
    
    delay(2);
    return 0;
    

  }


  // Setting to manual both manager  

  fwInstallation_throw("Setting simulator: -num " + number + " to manual", "INFO", 10);
  if(fwInstallationManager_setMode(sim, "-num " + number, "manual", host, port, user, pwd) < 0)
    {
      fwInstallation_throw("fwInstallationManager_switch()-> Could not change simulator: " + number + " start mode to manual");
      return -1;
    }
  
  fwInstallation_throw("Setting driver: -num " + number + " to manual", "INFO", 10);
  if(fwInstallationManager_setMode(name, "-num " + number, "manual", host, port, user, pwd) < 0)
    {
      fwInstallation_throw("fwInstallationManager_switch()-> Could not change driver: " + number + " start mode to manual");
      return -1;
    }
    
  // Stopping both managers
    
  fwInstallation_throw("Stopping" + " simulator: -num " + number, "INFO", 10);
  if(fwInstallationManager_command("STOP", sim, "-num " + number,  host, port, user, pwd) < 0)
    {
      fwInstallation_throw("fwInstallationManager_switch()-> Could not stop simulator: " + number);
      return -1;
    }
    
  fwInstallation_throw("Stopping" + " driver: " + name + " -num " + number , "INFO", 10);
  if(fwInstallationManager_command("STOP", name, "-num " + number,  host, port, user, pwd) < 0)
    {
      fwInstallation_throw("fwInstallationManager_switch()-> Could not stop manager: " + name + " -num " + number);
      return -1;
    }
     
  // wait until they both  stop
  fwInstallationManager_waitForState(false, number);
  delay(1);  
  if(driver)
    {
    
      fwInstallation_throw("Setting driver: " + name + " -num " + number + " to " + (driver?"always":"manual"), "INFO", 10);
      if(fwInstallationManager_setMode(name, "-num " + number, "always", host, port, user, pwd) < 0)
	{
	  fwInstallation_throw("fwInstallationManager_switch()-> Could not change manager: " + name + " -num " + number + " start mode to always");
	  return -1;
	}  }
  else
    {
      fwInstallation_throw("Setting simulator: -num " + number + " to " + (!driver?"always":"manual"), "INFO", 10);
      if(fwInstallationManager_setMode(sim, "-num " + number, "always", host, port, user, pwd) < 0)
	{
	  fwInstallation_throw("fwInstallationManager_switch()-> Could not change simulator" + number + " start mode to always");
	  return -1;
	}
    }
 

  bool isRunning;
  if ( fwInstallationManager_isRunning((driver)?name:sim,"-num "+ number,isRunning,host,port,user,pwd) <0) {
    fwInstallation_throw("fwInstallationManager_switch()-> Could not check if manager is running");

    return -1;
  }
  
  if (! isRunning) {
    // wait up to 5 seconds to see if it starts running
    for (int i=1; i<= 5; i++) {
      delay(1);
      if ( fwInstallationManager_isRunning((driver)?name:sim,"-num "+ number,isRunning,host,port,user,pwd) <0) {
	fwInstallation_throw("fwInstallationManager_switch()-> Could not check if manager is running");

	return -1;
      }
      if (isRunning) break;

    }
  }
  // if still is not running
  if (! isRunning) {
    // in case it failed to start after setting to always
    string driver_or_sim = ((driver)?(" driver " + name):" simulator");
    fwInstallation_throw("Starting" + driver_or_sim + " -num " + number, "INFO", 10);
    if(fwInstallationManager_command("START", (driver)?name:sim, "-num " + number,  host, port, user, pwd) < 0)
      {
	fwInstallation_throw("fwInstallationManager_switch()-> Could not start " + driver_or_sim + " " + number);
	return -1;
      }
  }
  
  
  return 0;
}



/**  Debug Info in the log viewer
     @param message message to print
*/
void fwInstallationUtils_debugInfo(string message) {
  fwInstallation_throw(message ,"INFO",10) ;
  
}

/** Debug Info notifying end of post install
    @param component component being installed
*/
void fwInstallationUtils_endPostInstall(string component) {
  string version = fwInstallation_getComponentVersion(component);
  fwInstallationUtils_debugInfo("Component " + component + " version "  + version + ": " +  " postInstall script finished");
}

/** Load a hardware configuration from the config db
    @param configurationName tagName for the configuration
    @param exceptionInfo exceptions reported here
    @param setupName config db connection to be used
    @param deviceList list of devices to be loaded (default "*")
    @param adoptSys adopt the matching devices to the current system name
    @return 
*/
bool fwInstallationUtils_loadConfigurationDbHardware(string configurationName,  dyn_string& exceptionInfo, string setupName = "", dyn_string deviceList = makeDynString("*"),bool adoptSys = true, bool onlyCreateDps =false) {  
  // in case no system name is set in deviceList, add *:
  string devSys;
  for (int d=1; d<= dynlen(deviceList); d++) {
    fwGeneral_getSystemName(deviceList[d], devSys, exceptionInfo);
    if (devSys == "") {
      deviceList[d] = "*:" + deviceList[d];
    }

  }
  time validOn=0;
  string defaultConnectString;
  if (! onlyCreateDps) {
    DebugN("Loading hardware configuration " + configurationName + " from setupName " + ((setupName=="")?"default":setupName) + " deviceList " + deviceList);
    fwInstallationUtils_debugInfo("Loading hardware configuration " + configurationName + " from setupName " + ((setupName=="")?"default":setupName));
  } else {
    DebugN("Creating data points for configuration " + configurationName + " from setupName " + ((setupName=="")?"default":setupName) + " deviceList " + deviceList);
  }

  fwConfigurationDB_initialize(setupName, exceptionInfo);
  //  fwConfigurationDB_checkInit(exceptionInfo);
  if (dynlen(exceptionInfo)){fwInstallationUtils_debugInfo("Error connecting to Config DB" + exceptionInfo);return false; }
   
   
  time validOn=0;

  string systemName = getSystemName();
  
  DebugN("Configuring hardware view");  
  int deviceConfigs = 0;
  if (! onlyCreateDps) {
    deviceConfigs = fwConfigurationDB_deviceConfig_VALUE
      + fwConfigurationDB_deviceConfig_ADDRESS
      + fwConfigurationDB_deviceConfig_ALERT
      + fwConfigurationDB_deviceConfig_ARCHIVING
      + fwConfigurationDB_deviceConfig_DPFUNCTION
      + fwConfigurationDB_deviceConfig_CONVERSION
      + fwConfigurationDB_deviceConfig_PVRANGE
      + fwConfigurationDB_deviceConfig_SMOOTHING
      + fwConfigurationDB_deviceConfig_UNITANDFORMAT    
      ;
  }
  if (adoptSys) {
    DebugN("Adopting to current system");
    deviceConfigs = deviceConfigs + fwConfigurationDB_deviceConfig_ADOPT_TO_SYSTEM;
  }
  
  

  fwConfigurationDB_updateDeviceConfigurationFromDB(configurationName,
						    "HARDWARE", exceptionInfo, 
						    validOn, deviceList, systemName,
						    deviceConfigs					    ); // restore all values and configurations



  
  if (dynlen(exceptionInfo)) {
    fwInstallationUtils_debugInfo("Exceptions creating hw view " + exceptionInfo);
    return false;
  }
  if (! onlyCreateDps) {
    fwInstallationUtils_fixDipPublications(configurationName,exceptionInfo);
  }

  if (! onlyCreateDps) {
    fwInstallationUtils_debugInfo("Hardware view created");  
  }


  
  return true;
}

void fwInstallationUtils_fixDipPublications(string configurationName, dyn_string& exceptionInfo) {
  dyn_dyn_mixed deviceListObject;

  
  fwConfigurationDB_getDevicesInConfiguration(configurationName, "HARDWARE","", deviceListObject,exceptionInfo);  

 
  dyn_string dipconfigs; string dpconfig;
  for (int i=1; i<= dynlen(deviceListObject[fwConfigurationDB_DLO_DPTYPE]); i++) {
    if (deviceListObject[fwConfigurationDB_DLO_DPTYPE][i] == "_FwDipConfig") {
      fwGeneral_getNameWithoutSN(deviceListObject[fwConfigurationDB_DLO_DPNAME][i], dpconfig, exceptionInfo);
      dynAppend(dipconfigs, dpconfig);
    }
  }



  dyn_dyn_string publicationInfo;
  string item, dpe, tag; int rate, prev_rate;
  string mySys = getSystemName(); string prev_item = ""; dyn_string listTags, listDpes;
  if (isFunctionDefined("fwDIP_getAllPublications")) {
    for (int i=1; i<= dynlen(dipconfigs); i++) {
      dynClear(publicationInfo);
      fwDIP_getAllPublications(dipconfigs[i], publicationInfo, exceptionInfo);        
      if (dynlen(publicationInfo)>0) {
	//          DebugN(publicationInfo);
	fwDIP_unpublishAll(dipconfigs[i], exceptionInfo);    
	prev_item =""; prev_rate = 0;
	dynClear(listDpes); dynClear(listTags);
	for (int j=1; j<= dynlen(publicationInfo[fwDIP_OBJECT_DPES]); j++) {
	  item= publicationInfo[fwDIP_OBJECT_ITEM][j];
	  dpe = publicationInfo[fwDIP_OBJECT_DPES][j];
	  tag = publicationInfo[fwDIP_OBJECT_TAGS][j];
	  rate = (int) publicationInfo[fwDIP_OBJECT_UPDATE_RATES][j];
         
	  // fix system name
	  fwGeneral_getNameWithoutSN(dpe, dpe, exceptionInfo);
	  dpe = mySys + dpe;
          
          
	  //  DebugN(dipconfigs[i], j,item, dpe, tag, rate);
          
	  if ((item != prev_item) && (dynlen(listTags) >0)) {
	    //   DebugN("Publishing structure", prev_item, listDpes,listTags, prev_rate,dipconfigs[i]);
	    fwDIP_publishStructure(prev_item, listDpes,listTags, prev_rate, dipconfigs[i], exceptionInfo);
	    dynClear(listDpes); dynClear(listTags);
	  } 

          
	  if (tag == "") {
	    //            DebugN("Publishing primitive", item, dpe, rate,dipconfigs[i]);
	    fwDIP_publishPrimitive(item, dpe, rate,dipconfigs[i],exceptionInfo);
	  } else {
	    dynAppend(listTags, tag);    
	    dynAppend(listDpes, dpe);
	  }
          
	  prev_item = item;
	  prev_rate = rate;
	}
	if (dynlen(listTags) >0) {
	  // DebugN("Publishing structure", prev_item, listDpes,listTags, prev_rate,dipconfigs[i]);
	  fwDIP_publishStructure(prev_item, listDpes,listTags, prev_rate, dipconfigs[i], exceptionInfo);
	}
      }
    }
      
  }
  
}

/** Load a logical configuration from the configuration db
    @param configurationName configuration name to load
    @param exceptionInfo 
    @param setupName config db to use
    @param adoptSys adopt dpnames to local pvss system
    @return 
*/
bool fwInstallationUtils_loadConfigurationDbLogical(string configurationName, dyn_string& exceptionInfo, string setupName = "", bool adoptSys = true) {


  fwConfigurationDB_initialize(setupName, exceptionInfo);
  //  fwConfigurationDB_checkInit(exceptionInfo);
  if (dynlen(exceptionInfo)){fwInstallationUtils_debugInfo("Error connecting to Config DB" + exceptionInfo);return false; }
   
   

  
  DebugN("Configuring logical view");    

  dyn_string deviceList = makeDynString("*");
  time validOn=0;
  DebugN("Loading logical configuration " + configurationName + " from setupName " + ((setupName=="")?"default":setupName));
  fwInstallationUtils_debugInfo("Loading logical configuration " + configurationName + " from setupName " + ((setupName=="")?"default":setupName));

  
  int options = 0;
  if (adoptSys) {
    options += fwConfigurationDB_deviceConfig_ADOPT_TO_SYSTEM;
  }
  fwConfigurationDB_updateDeviceConfigurationFromDB(configurationName,
						    "LOGICAL", exceptionInfo, 
						    validOn, deviceList, "",
						    options);
  if (dynlen(exceptionInfo)) {
    fwInstallationUtils_debugInfo("Exceptions creating log view " + exceptionInfo);
    return false;
  }
  fwInstallationUtils_debugInfo("Logical view created");
  return true;
}

          
/*** XML HANDLING ***/



/** Parses a xml_file in a mapping variable
    The attributes are ignored, the text elements are reported as string, the nested elements are reported as mappings
    @param xml_file filename to load
    @param exInfo 
    @return mapping representing the xml
*/
mapping fwInstallationUtils_xmlToMap(string xml_file, dyn_string& exInfo)
{
  string xml_full_name = xml_file;//getPath(DATA_REL_PATH,xml_file);
  int rtn_code, docum, ident;
  string errMsg, errLin, errCol;

  string element;
  mapping structure;
  docum = xmlDocumentFromFile ( xml_full_name , errMsg , errLin , errCol );

  
  if ( docum < 0 )
    {
      fwException_raise(exInfo,"PARSE_ERROR", "Parsing Error-Message = '" + errMsg + "' Line=" + errLin + " Column=" + errCol ,"");
      return structure;
    }
  else
    {
      ident = xmlFirstChild ( docum );

    
      while ( xmlNodeType ( docum , ident ) != XML_ELEMENT_NODE )
	{
	  ident = xmlNextSibling ( docum , ident );

	}

      element = xmlNodeName ( docum , ident );

    
      structure = (fwInstallationUtils_analyse_substructure ( docum , ident , 1 , exInfo ));
    
      rtn_code = xmlCloseDocument ( docum );
      return structure;

    }
}


mapping  fwInstallationUtils_analyse_substructure ( int docum , int ident , int depth , dyn_string &exInfo )
{
  dyn_string tags, values;
  dyn_anytype attribs;
  string space = "";
  int rtn_code;
  dyn_mixed l;
  mapping m;
  // Note that the following constant must NOT be initialised by an expression!
  const int expected_rtn_codes = 2;  // Corresponds to ( 1 << XML_ELEMENT_NODE )

  rtn_code = fwXml_childNodesContent ( docum , ident , tags , attribs , values , exInfo );

  
  if ( ( rtn_code & ~expected_rtn_codes ) != 0 )
    {

      fwException_raise(exInfo, "PARSE+ERROR","Return-Code is '"+rtn_code+"' Max-Expected '"+expected_rtn_codes+"'" ,"");    
      return m;
    }
  
  //  for ( int i = 0 ; i < depth ; ++i ) { space += "   "; }
       
  m["tags"] = tags;
    
  for ( int idx = 1 ; idx <= dynlen(tags) ; ++idx )
    {
      int subtreeid = -1;
    
      if ( mappingHasKey ( attribs[idx] , fwXml_CHILDSUBTREEID ) )
	{
	  subtreeid = attribs[idx][fwXml_CHILDSUBTREEID];
	  mappingRemove ( attribs[idx] , fwXml_CHILDNODESTYPE );
	  mappingRemove ( attribs[idx] , fwXml_CHILDSUBTREEID );
	}
    
      //  DebugN ( "TagName = [" + depth + "]" + space + " '" + tags[idx] + "'"
      //        + /*( mappinglen(attribs[idx]) > 0 ?
      //         "   Attribs '" + (string)attribs[idx] + "'" : ""  ) +*/ " "  + values[idx]);
      if ( subtreeid != -1 )
	{  
	  l[idx] = fwInstallationUtils_analyse_substructure ( docum , subtreeid , depth + 1 , exInfo );
	} else {
	l[idx] =  values[idx];    
      }
    }
  m["values"] = l;
  return m;
}



/** Checks in this xml obj if it has a tag with a text element of a value
    @param xmlObj  object
    @param tag name of the tag
    @param value value to check
    @return true if xmlObj[tag] == value
*/
bool fwInstallationUtils_checkValue(mapping xmlObj, string tag, string value) {
  dyn_string tags = xmlObj["tags"];
  dyn_anytype values = xmlObj["values"];
  for (int i=1; i<= dynlen(tags); i++) {
     
    if (tags[i] != tag) continue;
    if (getType(values[i]) != STRING_VAR) {
      return false;
    }
    

    return (((string) values[i]) == value);
  }

  return false;    
}

/** 
    @param xmlObj xml object
    @param exInfo 
    @return list of tags for this object
*/
dyn_string fwInstallationUtils_getXmlTags(mapping xmlObj, dyn_string& exInfo) {
  if (! mappingHasKey(xmlObj,"tags") ) {
    //  fwException_raise(exInfo,"OBJECT_ERROR", "Mapping has no tags key","");
    return makeDynString();
  } 
  return ((dyn_string) xmlObj["tags"]);
   
}

/** 
    @param xmlObj xml object
    @param exInfo 
    @return list of values for this object. The values can be recursively xml objects
*/
dyn_mixed fwInstallationUtils_getXmlValues(mapping xmlObj, dyn_string& exInfo)  {
  if (! mappingHasKey(xmlObj,"values") ) {
    //fwException_raise(exInfo,"OBJECT_ERROR", "Mapping has no values key","");

    return makeDynMixed();
  } 
  return xmlObj["values"];

}


/** 
    @param xmlObj xml object
    @param tag tag to search
    @param index (out) index of the tag (0 if not found)
    @param default_val default value to return if the tag is not found
    @param exInfo errors
    @return value of the tag (can be an xml object)
*/
anytype fwInstallationUtils_getXmlTagContent(mapping xmlObj, string tag, int& index, anytype default_val, dyn_string& exInfo) {
  dyn_string tags = fwInstallationUtils_getXmlTags(xmlObj, exInfo);
  dyn_anytype values =fwInstallationUtils_getXmlValues(xmlObj, exInfo);
  if (dynlen(exInfo)>0) return "";
  index = dynContains(tags, tag);
  if (index == 0) {
    return default_val;
  }
  return values[index];    
    
}

/** Extracts tag names, patterns and config dbs for the configuration of a given system name in the targets
    @param xmlObj 
    @param sysName system name to extract the configuration
    @param tagNames list of configuration tag names
    @param patterns list of configuration patterns
    @param configDbs list of config dbs
    @param hardwareConfig true if the hardware configuration should be loaded
    @param logicalConfig true if the logical configuration should be loaded
    @param exInfo errors
*/
void fwInstallationUtils_getConfigurationsForSystem(mapping xmlObj, 
                                                    string sysName, 
                                                    dyn_string& tagNames, 
                                                    dyn_string& patterns,
                                                    dyn_string& configDbs,
                                                    dyn_bool& hardwareConfig,
                                                    dyn_bool& logicalConfig,
                                                    dyn_bool& force_reinstall,
                                                    dyn_string& exInfo) {
  tagNames = makeDynString();
  patterns = makeDynString();
  configDbs = makeDynString();
  
  sysName = strrtrim(sysName, ":");
  
    
    
  dyn_string tags = fwInstallationUtils_getXmlTags(xmlObj, exInfo);
  dyn_anytype values =fwInstallationUtils_getXmlValues(xmlObj, exInfo);
  if (dynlen(exInfo)>0) return;

  dyn_string tags_target; dyn_anytype  values_target; dyn_string tags_conf; dyn_string values_conf;
  mapping target;
    
  int idx = 0;
  for (int i=1; i<= dynlen(tags); i++) {
    if (tags[i] != "target") continue;
    if (getType(values[i]) != MAPPING_VAR) continue;

    if (fwInstallationUtils_checkValue(values[i], "system_name", sysName)  || fwInstallationUtils_checkValue(values[i], "system_name", sysName + ":") ) {
      target = (mapping) values[i];
      tags_target = fwInstallationUtils_getXmlTags(target, exInfo);
      values_target = fwInstallationUtils_getXmlValues(target, exInfo);

      for (int k=1; k<= dynlen(tags_target); k++) {       
	if (tags_target[k] == "configuration") {
	  idx++;
	  tagNames[idx] = "";  patterns[idx] = "*";    configDbs[idx] ="";   
	  logicalConfig[idx] = true;  hardwareConfig[idx] = true; force_reinstall[idx] = false;
	  tags_conf = fwInstallationUtils_getXmlTags(((mapping) values_target[k]), exInfo);
	  values_conf = fwInstallationUtils_getXmlValues(((mapping) values_target[k]), exInfo);
                 
	  for (int j=1; j<= dynlen(tags_conf); j++) {
	    switch (tags_conf[j]) {
	    case "tag" : tagNames[idx] = values_conf[j]; break;
	    case "pattern" : patterns[idx] = values_conf[j]; break;
	    case "db" : configDbs[idx] = values_conf[j]; break;
	    case "logical": logicalConfig[idx] = (values_conf[j]=="true"); break;
	    case "hardware": hardwareConfig[idx] = (values_conf[j]=="true"); break;  
	    case "force_reinstall" : force_reinstall[idx] = (values_conf[j]=="true"); break;  
	    }
	  }
	}
      }
    }

        
  }
    
}



/** Extract information about drivers to be stopped from an xmlObject
    @param xmlObj 
    @param drivers list of drivers
    @param numbers list of corresponding numbers
    @param exInfo 
*/
void fwInstallationUtils_getDriversToStop(mapping xmlObj, 
                                          dyn_string& drivers, 
                                          dyn_int& numbers, 
                                          dyn_string& exInfo) {
  drivers = makeDynString();
  numbers = makeDynString();
  int index;
  anytype managers_tag_cont =  fwInstallationUtils_getXmlTagContent(xmlObj, "stop_drivers", index, "",exInfo);
  mapping managers ;
  if (getType(managers_tag_cont) == MAPPING_VAR) managers = managers_tag_cont;
  
  if (index == 0) return;
  dyn_string tags = fwInstallationUtils_getXmlTags(managers, exInfo);
  dyn_anytype values =fwInstallationUtils_getXmlValues(managers, exInfo);
  if (dynlen(exInfo)>0) return;
  for (int i=1; i<= dynlen(tags); i++) {
    if (tags[i] != "manager") continue;
    drivers[dynlen(drivers)+1]= fwInstallationUtils_getXmlTagContent(values[i], "driver",index,"",exInfo);
    numbers[dynlen(numbers)+1] =  (int) fwInstallationUtils_getXmlTagContent(values[i], "num",index,0,exInfo);
  }
    
}



/** Get Info about managers to append to the project from an xml object
    @param xmlObj 
    @param types List of manager types (e.g. PVSS00ctrl)
    @param options List of manager options
    @param mode List of modes (always, manual,once)
    @param isDriver Is driver? 
    @param restart 
    @param count 
    @param sec_to_kill 
    @param restart Should the manager be restarted?
    @param exInfo 
*/void fwInstallationUtils_getManagersToAppend(mapping xmlObj, 
					       dyn_string& types, 
					       dyn_string& options, 
					       dyn_string& mode, 
					       dyn_bool& isDriver,                                              
					       dyn_int& restart,
					       dyn_int& count, 
					       dyn_int& sec_to_kill,
               dyn_bool& restartManager,
					       dyn_string& exInfo) {
  types = makeDynString();
  mode = makeDynString();
  isDriver = makeDynBool();
  restart = makeDynInt();
  count = makeDynInt();
  sec_to_kill = makeDynInt();
  restartManager = makeDynBool();
  
  dyn_int numbers = makeDynInt();
  
  int index;
  anytype managers_tag_cont =  fwInstallationUtils_getXmlTagContent(xmlObj, "append_managers", index, "",exInfo);
  mapping managers ;
  if (getType(managers_tag_cont) == MAPPING_VAR) managers = managers_tag_cont;
  
  if (index == 0) return;
  dyn_string tags = fwInstallationUtils_getXmlTags(managers, exInfo);
  dyn_anytype values =fwInstallationUtils_getXmlValues(managers, exInfo);
  if (dynlen(exInfo)>0) return;

  for (int i=1; i<= dynlen(tags); i++) {
    if (tags[i] != "manager") continue;
    types[dynlen(types)+1]= fwInstallationUtils_getXmlTagContent(values[i], "type",index,"",exInfo);
    numbers[dynlen(numbers)+1] =  (int) fwInstallationUtils_getXmlTagContent(values[i], "num",index,-1,exInfo);
    options[dynlen(options)+1] =   fwInstallationUtils_getXmlTagContent(values[i], "options",index,"",exInfo);
    if (numbers[dynlen(numbers)] > 0) {
      options[dynlen(options)] += " -num " + numbers[dynlen(numbers)]; 
    }
    mode[dynlen(mode)+1] =   fwInstallationUtils_getXmlTagContent(values[i], "mode",index,"always",exInfo);
    restart[dynlen(restart)+1] =  (int) fwInstallationUtils_getXmlTagContent(values[i], "restart",index,2,exInfo);
    count[dynlen(count)+1] =  (int) fwInstallationUtils_getXmlTagContent(values[i], "counter",index,2,exInfo);
    sec_to_kill[dynlen(sec_to_kill)+1] =  (int) fwInstallationUtils_getXmlTagContent(values[i], "sec_to_kill",index,30,exInfo);
    isDriver[dynlen(isDriver)+1] =  (fwInstallationUtils_getXmlTagContent(values[i], "isDriver",index,"false",exInfo) == "true");
    restartManager[dynlen(restartManager)+1] =  (fwInstallationUtils_getXmlTagContent(values[i], "restartManager",index,"false",exInfo) == "true");
  }
  for (int i=1; i<= dynlen(options);i++) {
      options[i] = strrtrim(strltrim(options[i], " "), " ");
  }
    
}




/** Load from the config db the configurations specified in the xml object for the given system name
    @param xmlObj XML Object
    @param sysName system name
    @param exInfo 
    @param callbackFunction (optional) a custom function to be called after each configuration is loaded
    @return number of configurations loaded
*/
int fwInstallationUtils_loadConfigurationsFromXml(mapping xmlObj, string sysName, string componentName, dyn_string& exInfo, string callbackFunction = "") {
  dyn_string tagNames;
  dyn_string patterns;
  dyn_string configDbs; 
  dyn_bool hardwareConfig;
  dyn_bool logicalConfig;
  dyn_bool force_reinstall;

  fwInstallationUtils_getConfigurationsForSystem(xmlObj, sysName,  tagNames,  patterns,  configDbs,  hardwareConfig,  logicalConfig, force_reinstall,exInfo) ;
  if (dynlen(exInfo)> 0) return 0;

  if (dynlen(tagNames) == 0) {
    DebugN("No configurations to load for system " + sysName);
    fwInstallationUtils_logCurrentConfiguration(componentName,tagNames,  patterns,  configDbs,  hardwareConfig,  logicalConfig, true);
    return 0;
  }
  
  // Find out if we have to load something or not. If not just return
    bool somethingToLoad = false;
    for (int i=1; i<= dynlen(tagNames); i++) {
      if (! force_reinstall[i]) {
	if (fwInstallationUtils_isConfigurationLoaded(componentName,tagNames[i],patterns[i], configDbs[i],hardwareConfig[i],logicalConfig[i])) {
      	  DebugTN("Configuration " + tagNames[i] + " is already loaded.");
       	  continue;
	}        
      }
      somethingToLoad = true;
      break;      
    }
    
    if (! somethingToLoad) {
        DebugTN("All configurations are already loaded for " + componentName + ". No need to stop the drivers");
        return 0;        
    }

  dyn_string drivers; dyn_int numbers;
  fwInstallationUtils_getDriversToStop(xmlObj, drivers, numbers, exInfo);
  if (dynlen(exInfo)> 0) return 0; 
  for (int i=1;i<= dynlen(drivers); i++) {
    DebugN("Stopping " + drivers[i] + " num " + numbers[i]);
    fwInstallationUtils_switchSimDriver(false, drivers[i], numbers[i]);
  }
  

  DebugN(dynlen(tagNames) + " configurations found for system " + sysName);
  dyn_string devList;
  if (dynlen(tagNames)>1) {
    // first create all the data points for all the configurations   - if there is only one configuration this step is not needed
    // this is useful if the data points in one configuration use data points in another configuration (for example in a dp function).
    // in this case we want to make sure that all the data points exist before starting to configure
    fwInstallationUtils_debugInfo("Creating data points for " + dynlen(tagNames) + " configurations");
    for (int i=1; i<= dynlen(tagNames); i++) {
      if (! force_reinstall[i]) {
	if (fwInstallationUtils_isConfigurationLoaded(componentName,tagNames[i],patterns[i], configDbs[i],hardwareConfig[i],logicalConfig[i])) {
	  DebugTN("Configuration " + tagNames[i] + " is already loaded. Skipping....");
	  continue;
	}        
      }
      if  (hardwareConfig[i]) {
        devList = strsplit(patterns[i], ",");
        DebugTN("Configuration " + tagNames[i] + " (" + i + "/" + dynlen(tagNames) + ") : Create Data Points");
	fwInstallationUtils_loadConfigurationDbHardware(tagNames[i],
							exInfo, configDbs[i], devList, true, true);
     
      }
    } 
  }
  
  int countLoaded = 0;
  for (int i=1; i<= dynlen(tagNames); i++) {
    if (! force_reinstall[i]) {
      if (fwInstallationUtils_isConfigurationLoaded(componentName,tagNames[i],patterns[i], configDbs[i],hardwareConfig[i],logicalConfig[i])) {
        DebugTN("Configuration " + tagNames[i] + " is already loaded. Skipping....");
        continue;
      }        
    }
    countLoaded++;
    if  (hardwareConfig[i]) {
      devList = strsplit(patterns[i], ",");
      DebugTN("Configuration " + tagNames[i] + " (" + i + "/" + dynlen(tagNames) + ")");
      fwInstallationUtils_loadConfigurationDbHardware(tagNames[i],
						      exInfo, configDbs[i], devList);
     
    }
    if (logicalConfig[i]) {
      fwInstallationUtils_loadConfigurationDbLogical(tagNames[i],
						     exInfo, configDbs[i]);
                                                      
    }
    if (strlen(callbackFunction)>0) {
      DebugN( "Calling custom function " , execScript("int main(string configName, int i, int n)" +  "{  " + callbackFunction + "(configName,i,n); }" , makeDynString(),tagNames[i],i, dynlen(tagNames)));
    }
  } 
 
  // Call again the custom function at the end with i = n+1 and configName = "".
  if (strlen(callbackFunction)>0) {
    DebugN( "Calling custom function at the end: " , execScript("int main(string configName, int i, int n)" +  "{  " + callbackFunction + "(configName,i,n); }" , makeDynString(),"",dynlen(tagNames)+1, dynlen(tagNames)));
 }
  for (int i=1;i<= dynlen(drivers); i++) {
    DebugN("starting " + drivers[i] + " num " + numbers[i]);
    fwInstallationUtils_switchSimDriver(true, drivers[i], numbers[i]);
  }
  fwInstallationUtils_logCurrentConfiguration(componentName,tagNames,  patterns,  configDbs,  hardwareConfig,  logicalConfig, (dynlen(exInfo)==0));
  if (dynlen(exInfo) >0) {
      DebugTN("********************* fwInstallationUtils: ERROR IN LOADING CONFIGURATIONS for " + componentName + " *********************");
      DebugTN("Exception: ", exInfo);
      DebugTN("********************* fwInstallationUtils: ERROR IN LOADING CONFIGURATIONS for " + componentName + " *********************");
  }
  return (countLoaded);

}  



fwInstallationUtils_createDataPointTypes() {
  if (dynlen(dpTypes("FwInstallationUtils_config")) == 1) return;
  
  dyn_dyn_string xxdepes;
  dyn_dyn_int xxdepei;
  
  int n;


  xxdepes[1] = makeDynString ("FwInstallationUtils_config","");
  xxdepes[2] = makeDynString ("",                          "configurations");
  xxdepes[3] = makeDynString ("",                          "success");
    
  xxdepei[1] = makeDynInt (DPEL_STRUCT);
  xxdepei[2] = makeDynInt (0,                          DPEL_DYN_STRING);
  xxdepei[3] = makeDynInt (0,                         DPEL_BOOL);
    
  n = dpTypeCreate(xxdepes,xxdepei);
  DebugN("fwInstallationUtils: Data point type created result ", n);   
    

}


bool fwInstallationUtils_isConfigurationLoaded(string componentName, string tagName, string pattern, string configDb,bool hardware, bool logical) {
  string dp = "FwInstallationUtils_config_" + componentName;
    
  if (! dpExists(dp) ) return false;
    
  dyn_string info; bool success;
  dpGet(dp + ".configurations", info,
        dp + ".success", success);
  if (! success) return false;
    
  string myInfo = "tagName=" + tagName + ",pattern=" + pattern + ",db=" + configDb + ",hw=" +(hardware?"Yes":"No") + ",logical=" +(logical?"Yes":"No");
    
  return (dynContains(info, myInfo)> 0);
    
}

/*
  Log the current configuration in a dp
*/
void fwInstallationUtils_logCurrentConfiguration(string componentName, dyn_string tagNames, dyn_string patterns, dyn_string configDbs, dyn_bool hardwareConfig, dyn_bool logicalConfig, bool success) {
  fwInstallationUtils_createDataPointTypes();
  
  string dp = "FwInstallationUtils_config_" + componentName;
  string dptype = "FwInstallationUtils_config";
  if (! dpExists(dp) ) {
    dpCreate(dp, dptype);
  }
  
  dyn_string info;
  for (int i=1; i<= dynlen(tagNames); i++) {
    info[i] = "tagName=" + tagNames[i] + ",pattern=" + patterns[i] + ",db=" + configDbs[i] + ",hw=" +(hardwareConfig[i]?"Yes":"No") + ",logical=" +(logicalConfig[i]?"Yes":"No");
  }
  dpSet(dp + ".configurations", info,
        dp + ".success", success);
  
  DebugN("fwInstallationUtils: logged configuration in dp " + dp);
}



/** Get the xml Object for the given component name (in the current system)
    @param componentName component name
    @param exInfo 
    @return 
*/
mapping fwInstallationUtils_getXmlObj(string componentName, dyn_string& exInfo) { 
  string sourceDir;

  mapping xmlObj;  
  int iRes =  fwInstallation_getComponentSourceDir(componentName, sourceDir);
  if (iRes == -1) {
    fwException_raise(exInfo,"DIR_ERROR", "Could not find source directory for " + componentName ,"");
    return xmlObj;      
    
  }
  
  string xmlFile = sourceDir + componentName + "_config.xml";
  if ( isfile(xmlFile) == 0 ) {
    DebugN("Configuration file for component " + componentName + " not found");
    return xmlObj;
  }
  DebugN("Loading configuration for " + componentName + " from " + xmlFile);
  

 
  xmlObj = fwInstallationUtils_xmlToMap(xmlFile, exInfo);
  return xmlObj;
}




/** Load configurations from the config db for a component in the current system
    @param componentName  Component
    @param exInfo 
    @param callbackFunction a custom function that is called after each configuration is loaded
    @return number of configurations loaded
*/
int fwInstallationUtils_loadConfigurations(string componentName, dyn_string& exInfo, string callBackFunction = "") {
  fwNode_initialize();
  
  string systemName = getSystemName();
  systemName = strrtrim(systemName, ":");
  mapping xmlObj=  fwInstallationUtils_getXmlObj(componentName, exInfo);
  if (dynlen(exInfo)>0) return;
  if (mappinglen(xmlObj) == 0) return;
  return fwInstallationUtils_loadConfigurationsFromXml(xmlObj, systemName, componentName, exInfo, callBackFunction);
}

/** Append the managers for the given component name in the current system
    @param componentName 
    @param exInfo 
    @param whichType 1 = only managers 2 = only drivers 3 = managers and drivers
*/
void fwInstallationUtils_appendManagers(string componentName, dyn_string& exInfo, int whichType = 3) {
  mapping xmlObj=  fwInstallationUtils_getXmlObj(componentName, exInfo);
  if (dynlen(exInfo)>0) return;
  if (mappinglen(xmlObj) == 0) return;
  
  dyn_string managers, options, mode;
  dyn_int restart, count, sec_to_kill; dyn_bool isDriver; dyn_bool restartManager;
  fwInstallationUtils_getManagersToAppend(xmlObj,  managers,  options,  mode, isDriver, restart,  count,  sec_to_kill, restartManager, exInfo);
  
  bool addDrivers = whichType & 2;
  bool addManagers = whichType & 1;
  for (int i=1; i<=dynlen(managers); i++) {
    if (isDriver[i]) {
      if (addDrivers) {
        DebugN("Appending " + managers[i] + " " + options[i] + " mode " + mode[i]);
        fwInstallationManager_appendDriver("DRIVER", managers[i], managers[i], mode[i],sec_to_kill[i], count[i],restart[i], options[i]);
      }
    } else {
      if (addManagers) {
        DebugN("Appending " + managers[i] + " " + options[i] + " mode " + mode[i] + " (restart = " + restartManager[i] + ")");        
        fwInstallationUtils_appendManager(managers[i], managers[i], mode[i],sec_to_kill[i], count[i], restart[i], options[i], restartManager[i]);
      }
    }
  }  
}

void fwInstallationUtils_appendManager(string  managerDescription, string managerType, string mode, int secondsBeforeKill , int restartNumber, int restartTimer, string managerOptions, bool restartManager ) {
  managerType = fwInstallationUtils_getWCCOAExecutable(managerType);
  
  bool managerFound = false;
  if (restartManager) {
    dyn_dyn_mixed managersInfo;
  
    fwInstallationManager_pmonGetManagers(managersInfo);
    for(int i=1; i<=dynlen(managersInfo[1]); i++)
    {
      string manager = managersInfo[FW_INSTALLATION_MANAGER_TYPE][i] + "|" + managersInfo[FW_INSTALLATION_MANAGER_OPTIONS][i];
      if(manager == (managerType + "|" + managerOptions))
      {
      managerFound = true;
      break;
      }
    }
  }

  if(managerFound)
  {
    //Call restart to restart running managers (e.g. CTRL scripts)
    fwInstallationManager_restart(managerType, managerOptions);
    //Set mode to what we want it to be in order to override any manual changes
    fwInstallationManager_setMode(managerType, managerOptions, mode);
  }
  else
  {
    fwInstallationManager_append(true, managerDescription, managerType, mode, secondsBeforeKill, restartNumber, restartTimer, managerOptions);
  }
}
    
/** Returns a human friendly string representation of the XML tree
    @param value the xml object to print
    @param exInfo errors
    @param depth start depth (default 0)
    @return human friendly string
*/
string fwInstallationUtils_xmlMapToString(anytype value, dyn_string& exInfo, int depth = 0) {
  string result = "";

  dyn_string tags;
  dyn_anytype values;
  mapping m;
  string space;
  for ( int i = 0 ; i < depth ; ++i ) { space += "   "; }
  switch (getType(value)) {
  case MAPPING_VAR:
    m = (mapping) value;
    tags = fwInstallationUtils_getXmlTags(m,exInfo);
    values = fwInstallationUtils_getXmlValues(m,exInfo);
    if (dynlen(exInfo)> 0) return "error";
        
    if (dynlen(tags) != dynlen(values)) {
      fwException_raise(exInfo,"OBJECT_ERROR", "Length of tags (" + dynlen(tags) + ") does not match length of values (" + dynlen(values) + ")" ,"");
      return "error";
    }
    for (int i=1; i<= dynlen(tags); i++) {
      result = result + "\n" + space +  tags[i] + ": " + fwInstallationUtils_xmlMapToString(values[i], exInfo, depth+1);
    }

    break;
  case STRING_VAR:
    result=  value ;
    break;
  default:
    result= "" + value + "";
    break;
  }    

  return result;
}



