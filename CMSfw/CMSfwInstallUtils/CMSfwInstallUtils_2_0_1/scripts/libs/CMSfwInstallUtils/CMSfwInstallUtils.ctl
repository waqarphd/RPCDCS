#uses "fwInstallation.ctl"


bool CMSfwInstallUtils_importAsciiFile(string asciiFile) {

  string tail = "/dplist/" + asciiFile;
   DebugN("Importing ascii file " + asciiFile);
  dyn_string projPaths;
  fwInstallation_getProjPaths(projPaths);
  //  DebugN("proj paths ", projPaths);

  bool found = false;
  for (int i =1; i <= dynlen(projPaths); i++) {
  //  DebugN(projPaths[i] + tail);
    if ((access(projPaths[i] + tail, F_OK) == 0)) {
     asciiFile = projPaths[i] + tail;
     found = true;
     break;
    }
  }
  if (! found) {
    CMSfwInstallUtils_debugInfo("File " + asciiFile + " not found");
    return false;
  }
 
  
  string asciiManager = PVSS_BIN_PATH + "PVSS00ascii";
  string infoFile = getPath(LOG_REL_PATH) + "PVSS00ascii_info.log";
  string logFile =  getPath(LOG_REL_PATH) + "PVSS00ascii_log.log";

  string cmd = asciiManager + " -in " + asciiFile + " -yes -log +stderr -log -file > "
    + infoFile + " 2> " + logFile;								
  int err;

  if (_WIN32) 
    {
      err = system("cmd /c " + cmd);
      if (err != 0)
	{
	  CMSfwInstallUtils_debugInfo("    Could not import properly the file " + asciiFile + " (Error number = " + err +")");
	  return false;
	}
    }
  else  //LIN
    {
      err = system(cmd);
      if (err != 0)
	{
	  CMSfwInstallUtils_debugInfo("    Could not import properly the file " + asciiFile + " (Error number = " + err +")");
	  return false;
	}
    }
									
  return true;
}



void CMSfwInstallUtils_initPmonVars() {
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


// if driver switch to real driver otherwise switch to simulator
bool CMSfwInstallUtils_switchSimDriver(bool driver, string name, int number) {
  CMSfwInstallUtils_initPmonVars();
 // fwInstallation_throw("Current user and pwd "+ gFwInstallationPmonUser + " " + gFwInstallationPmonPwd ,"INFO",10) ;
  return (CMSfwInstallUtils_fwInstallationManager_switch(driver, name, number) == 0);
}




/**
   * This is an alternative version of fwInstallationManager_switch that contains some bugfixes. 
   * Please change CMSfwInstallUtils_switchSimDriver to use the original  function if Fernando agrees to fix the function
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
int CMSfwInstallUtils_fwInstallationManager_switch(bool driver, 
                                  string name, 
                                  int number, 
                                  string host = "", 
                                  int port = 4999, 
                                  string user = "", 
                                  string pwd = "") 
{
  string msg = "Switching to " + (driver?"Driver":"Simulation Driver") + " for " + name;

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
  


// Setting to manual both manager  

    fwInstallation_throw("Setting simulator: -num " + number + " to manual", "INFO", 10);
    if(fwInstallationManager_setMode("PVSS00sim", "-num " + number, "manual", host, port, user, pwd) < 0)
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
    if(fwInstallationManager_command("STOP", "PVSS00sim", "-num " + number,  host, port, user, pwd) < 0)
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
    if(fwInstallationManager_setMode("PVSS00sim", "-num " + number, "always", host, port, user, pwd) < 0)
    {
      fwInstallation_throw("fwInstallationManager_switch()-> Could not change simulator" + number + " start mode to always");
      return -1;
    }
  }
 

  bool isRunning;
  if ( fwInstallationManager_isRunning((driver)?name:"PVSS00sim","-num "+ number,isRunning,host,port,user,pwd) <0) {
    fwInstallation_throw("fwInstallationManager_switch()-> Could not check if manager is running");

    return -1;
  }
  
  if (! isRunning) {
     // wait up to 5 seconds to see if it starts running
    for (int i=1; i<= 5; i++) {
              delay(1);
        if ( fwInstallationManager_isRunning((driver)?name:"PVSS00sim","-num "+ number,isRunning,host,port,user,pwd) <0) {
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
    if(fwInstallationManager_command("START", (driver)?name:"PVSS00sim", "-num " + number,  host, port, user, pwd) < 0)
    {
      fwInstallation_throw("fwInstallationManager_switch()-> Could not start " + driver_or_sim + " " + number);
      return -1;
    }
  }
  
  
  return 0;
}
void CMSfwInstallUtils_waitManager(bool running, int number, int numberoftime=0) {
  fwInstallationManager_waitForState(running, number);
}


// returns true if some  driver is running
// (whether the simulator or the real opc client)
bool CMSfwInstallUtils_isManagerRunning(int number) {
  return fwInstallationManager_isDriverRunning(number);
}

void CMSfwInstallUtils_debugInfo(string message) {
  string cat;
  int prio,typ,co;
  
  cat ="CMSfwInstallUtils/CMSfwInstallUtils_errors"; 
  prio=PRIO_INFO; /* Constant which defines the importance of the error of the information */
  typ =ERR_CONTROL; //Type of the error
  co = 1; /* Sequence number of the information message from the own catalog "myError" */

  errClass retError; /* errClass variable for the makeError function */
  retError = makeError(cat,prio,typ,co,message);
   throwError(retError);    
}

void CMSfwInstallUtils_endPostInstall(string component) {
  string version = fwInstallation_getComponentVersion(component);
  CMSfwInstallUtils_debugInfo("Component " + component + " version "  + version + ": " +  " postInstall script finished");
}

bool CMSfwInstallUtils_loadConfigurationDbHardware(string configurationName) {
  dyn_string exceptionInfo;
  dyn_string deviceList;
  
  time validOn=0;
  string defaultConnectString;


  fwConfigurationDB_checkInit(exceptionInfo);
  if (dynlen(exceptionInfo)){CMSfwInstallUtils_debugInfo("Error connecting to Config DB" + exceptionInfo);return false; }
   
   
  time validOn=0;
  dyn_string deviceList;
  string systemName = getSystemName();
  
  DebugN("Configuring hardware view");  
  int deviceConfigs = 0; //fwConfigurationDB_deviceConfig_ALLDEVPROPS;
  
  deviceConfigs = fwConfigurationDB_deviceConfig_VALUE
    + fwConfigurationDB_deviceConfig_ADDRESS
    + fwConfigurationDB_deviceConfig_ALERT
    + fwConfigurationDB_deviceConfig_ARCHIVING
    + fwConfigurationDB_deviceConfig_DPFUNCTION
    + fwConfigurationDB_deviceConfig_CONVERSION
    + fwConfigurationDB_deviceConfig_PVRANGE
    + fwConfigurationDB_deviceConfig_SMOOTHING
    + fwConfigurationDB_deviceConfig_UNITANDFORMAT;
  

  fwConfigurationDB_updateDeviceConfigurationFromDB(configurationName,
						    "HARDWARE", exceptionInfo, 
						    validOn, deviceList, systemName,
	 deviceConfigs					    ); // restore all values and configurations


  if (dynlen(exceptionInfo)) {
    CMSfwInstallUtils_debugInfo("Exceptions creating hw view " + exceptionInfo);
    return false;
  }
  CMSfwInstallUtils_debugInfo("Hardware view created");
  return true;
}

bool CMSfwInstallUtils_loadConfigurationDbLogical(string configurationName) {
  DebugN("Configuring logical view");    
  dyn_string exceptionInfo;
  dyn_string deviceList;
  time validOn=0;
 
  fwConfigurationDB_updateDeviceConfigurationFromDB(configurationName,
						    "LOGICAL", exceptionInfo, 
						    validOn, deviceList, "",
						    0);
  if (dynlen(exceptionInfo)) {
    CMSfwInstallUtils_debugInfo("Exceptions creating log view " + exceptionInfo);
    return false;
  }
  CMSfwInstallUtils_debugInfo("Logical view created");
  return true;
}


// /*** Template of a postInstall script for a CMS component ***/

// 
// main() {
  /// Set all the drivers to manual
//     
    /// e.g. OPC
//   
//   DebugN("Setting OPC to simulator. Result = "+  CMSfwInstallUtils_switchSimDriver(false,"PVSS00opc", 6));  
// 
// //RDB configuration
// 
  // Only user and host need to be specified here, to update the config file
  // the (crypted) password is set from a dpl
// 
//   fwRDBConfig_setUser(...);
//   fwRDBConfig_setHost(...);
//   DebugN("RDB configured");
//   
//   
//   
//   /* If you use the configuration db (reccomended) */
//   
//   string configurationName = "..."; // set the configuration name used in the config db here
//   bool res = CMSfwInstallUtils_loadConfigurationDbHardware(configurationName) ;
//   
//   /* Load also the logical view from configuration db */
//   if (res) {  
//     res = CMSfwInstallUtils_loadConfigurationDbLogical(configurationName);
//   }
//   
//   if (! res) {
//     CMSfwInstallUtils_debugInfo("Errors in the configuration db retrieval");
//   }
//   
//   /* If you don't use configuration db, import the ascii file of the datapoints with an address here. Don't add them as dplist in the XML file otherwise
//      they will be loaded when no driver or simulator is running. Instead include them in the XML of your component as simple <file> entries and
//      load them in the postInstall. */
//   
  // the file name is searched in the dplist directory of all the project paths
//   
//   CMSfwInstallUtils_importAsciiFile(asciiFile);
//   
//   
//   DebugN("Running fsm post install");
  /// If you have one FSM postInstall, copy the  code generated with fwInstallation_Packager and run it here 
  // (better than having two separate postInstall file. In this way you can be sure that FSM post install runs when the hardware and logical view are retrieved from the DB)
//   fsmpostinstall();
//   
//   
  /// Set the access control for the FSM <-- customize the domain and privilege. The first is the privilege needed for taking the FSM, the second is the privilege for the expert actions
//   fwFsmTree_accessTreeNodeRec("FSM","CMS:Control|CMS:Control",1);
// 
   /// Set all the drivers to always
  /// e.g. the OPC
//   DebugN("Setting back OPC to driver. Result = "+  CMSfwInstallUtils_switchSimDriver(true,"PVSS00opc", 6)); 
// 
//   
  /// Send a final info message 
//   
//   CMSfwInstallUtils_endPostInstall(componentName);
//   
// }
// 
// 
//   
