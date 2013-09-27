// $License: NOLICENSE
#uses "fwInstallation.ctl"
#uses "fwInstallationUpgrade.ctl"

const string FW_SYS_STAT_DB_AGENT_SCRIPT = "6.2.4";

main()
{
  bool isOK;
//  dyn_int options;
  int error;
  int restartProject = 0;
  int isRunning = 0;
  string sPath;
  int sleep = 5;
  string dp = fwInstallation_getInstallationDp();
  bool isConnected = false;
  
  fwInstallation_throw("Starting FW Installation Tool DB-Agent v." + FW_SYS_STAT_DB_AGENT_SCRIPT, "INFO"); 
  //Check that the installation tool has been successfully installed:
  if(FW_SYS_STAT_DB_AGENT_SCRIPT != csFwInstallationToolVersion || 
     FW_SYS_STAT_DB_AGENT_SCRIPT != csFwInstallationLibVersion  ||
     FW_SYS_STAT_DB_AGENT_SCRIPT != csFwInstallationDBLibVersion  ||
     FW_SYS_STAT_DB_AGENT_SCRIPT != gFwInstallationAgentLibVersion ||
     FW_SYS_STAT_DB_AGENT_SCRIPT != csFwInstallationManagerLibVersion ||
     FW_SYS_STAT_DB_AGENT_SCRIPT != csFwInstallationXmlLibVersion ||
     FW_SYS_STAT_DB_AGENT_SCRIPT != csFwInstallationPackagerLibVersion
     ) 
  {
    fwInstallation_throw("Inconsistency between library versions of the FW Installation Tool. Reinstall the tool...");
    fwInstallation_throw("Tool is v." + csFwInstallationToolVersion, "INFO", 10);
    fwInstallation_throw("fwInstallation.ctl is v." + csFwInstallationLibVersion, "INFO", 10);
    fwInstallation_throw("fwInstallationDB.ctl is v." + csFwInstallationDBLibVersion, "INFO", 10);
    fwInstallation_throw("fwInstallationDBAgent.ctl is v." + gFwInstallationAgentLibVersion, "INFO", 10);
    fwInstallation_throw("fwInstallationDBManager.ctl is v." + csFwInstallationManagerLibVersion, "INFO", 10);
    fwInstallation_throw("fwInstallationDBXml.ctl is v." + csFwInstallationXmlLibVersion, "INFO", 10);
    fwInstallation_throw("fwInstallationDBPackager.ctl is v." + csFwInstallationPackagerLibVersion, "INFO", 10);
    fwInstallation_throw("fwInstallationAgentDBConsistencyChecker.ctl script is v." + FW_SYS_STAT_DB_AGENT_SCRIPT, "INFO", 10);    
    fwInstallation_throw("FW Component Installation Tool exitting...");    
    return;
  }

  //Give time to pmon to start all managers in the console:
  delay(sleep);  
  
  //Before connecting to the DB and if Windows, kill previous instances of the DB-agent if they exist.
  //This is necessary to overcome some problems with CtrlRDBAccess that prevents the manager from exiting when the project is stopped.
  if(_WIN32)
    fwInstallationDbAgent_terminateOldInstances();
  
  do
  {
    //Initial configuration of the FW Installation Tool:
    setUserId(getUserId("para"));
    if (!getUserPermission(4)){ //Make sure that we have the rights, otherwise exit...
      fwInstallation_throw("Sorry but you do no have sufficient rights on this system to run the FW Installation Tool. Exitting...");
      return;
    }
    else 
    {
      if(fwInstallation_init(false))
      {
        fwInstallation_throw("Failed to initialize the FW Component Installation Tool");
        return;
      }
//      if(fwInstallation_loadInitFile())
//      {
//        //DebugN("Init config file cannot be accessed. Interactive configuration of the FW Installation Tool required");
//      }
    }
    
    if(dpExists(dp + ".installationDirectoryPath"))
      dpGet(dp + ".installationDirectoryPath", sPath);
    
    if(sPath == "")
    {
//      fwInstallation_throw("FW Installation directory not defined. Checking again in " + fwInstallationDBAgent_getSyncInterval() + "s.", "INFO");
      delay(fwInstallationDBAgent_getSyncInterval()); //Agent panel is pop-up. Let the user interact with it
    }
  }while (sPath == "");

  fwInstallationDBAgent_releaseSynchronizationLock();

  //InitializeCache for new cycle.
  if( fwInstallationDB_initializeCache() != 0) {
    ++error;
    fwInstallation_throw("fwInstallationAgentDBConsistencyChecker() -> Could not start cache.");
  };  
  while(1)
  {
    
    if(fwInstallationRedu_isPassive())
    {
      //DebugN("INFO: Passive redundant system. Checking again in " + fwInstallationDBAgent_getSyncInterval() + "s.");
      delay(fwInstallationDBAgent_getSyncInterval());
      continue;
    }
   
    if(!fwInstallationDB_getUseDB()){
        delay(fwInstallationDBAgent_getSyncInterval());
        continue;
    }
    
    //allow some time in case the PVSS00ascii manager is importing the init file:
    delay(10);
    
    if(fwInstallationDB_connect() != 0){
      isConnected = false;
      fwInstallation_throw("fwInstallationDBConsistencyChecker script -> Could not connect to DB. Next attempt in "+ fwInstallationDBAgent_getSyncInterval() + "s.", "WARNING"); 
      delay(fwInstallationDBAgent_getSyncInterval());
      continue;
    }

 
    //Check schema version is correct, otherwise sleep:
    string version = "";
    fwInstallationDB_getSchemaVersion(version);
    
    if(!fwInstallationDB_compareSchemaVersion())
    {
      fwInstallation_throw("FW Installation Tool DB-Agent: Wrong db schema. Required schema version is: " + FW_INSTALLATION_DB_REQUIRED_SCHEMA_VERSION + " current is " + version);         
      fwInstallationDB_storeInstallationLog();
      delay(1);
      fwInstallationDB_closeDBConnection();
      isConnected = false;      
      delay(fwInstallationDBAgent_getSyncInterval());
      continue;
    }
    
    if(!isConnected) //we got this far, we have a valid DB connection
    {
      isConnected = true;
      fwInstallation_throw("Connection to FW System Configuration DB sucessfully established. Schema v." + version, "INFO");    
    }
      
    //do not do anything if post-installation scripts of a previous installation are still running:
    isRunning = 1;
    fwInstallationDBAgent_isPostInstallRunning(isRunning); 
    if(isRunning)
    {
      fwInstallation_throw("FW Installation Tool DB-Agent: PostInstallation scripts still running. Skipping sync...", "INFO");
      delay(fwInstallationDBAgent_getSyncInterval());
      continue;
    }
    
    //Check if the FW Component Installation Tool has to be upgraded:
    if(fwInstallationDB_getCentrallyManaged()) //do it only if the project is centrally managed
    {
//      fwInstallation_resetLog();
      int errCode = fwInstallationUpgrade_execute();
      if(errCode == -1)
      {
        fwInstallation_throw("Failed to execute the Upgrade Remote Request of the FW Component Installation Tool. Old version of the tool still running", "WARNING", 13);
	       fwInstallationDB_storeInstallationLog();
      }
      else if(errCode == -2)
      {
        fwInstallation_throw("Failed to execute the Upgrade Remote Request of the FW Component Installation Tool. DB-Agent exiting...");
	       fwInstallationDB_storeInstallationLog();
	       delay(1);
        return;
      }
    }
      
//    fwInstallationDBAgent_getSynchronizationOptions(options);
//    if(dynlen(options))
//    {
      int projectId, autoregEnabled;
      fwInstallationDB_isProjectRegistered(projectId);
      fwInstallationDB_getProjectAutoregistration(autoregEnabled);
      if (projectId > 0 || autoregEnabled == 1) //if the project is already registered or the autoregistration is enabled
      {
      error = fwInstallationDBAgent_getSynchronizationLock();    
      if(fwInstallationDBAgent_synchronize(restartProject) != 0)
      {
        error = fwInstallationDBAgent_releaseSynchronizationLock();
        fwInstallation_throw("DB-Project synchronization failed.");
        delay(fwInstallationDBAgent_getSyncInterval());
        continue;
      }
      
//DebugN("**************right after sync ", restartProject);      
      error = fwInstallationDBAgent_releaseSynchronizationLock();
      if(restartProject == 1)// Project restart is required
      {
        fwInstallationDBAgent_releaseSynchronizationLock();
        fwInstallation_throw("Closing connection to System Configuration DB", "INFO"); 
        fwInstallationDB_storeInstallationLog();
        int ret = fwInstallationDB_closeDBConnection(); 
        
//DebugN("&&&&&&&&&&&&&&&&&&&&Calling restart project from script");   
        fwInstallation_throw("FW Installation Tool: Forcing project restart", "INFO"); 
        fwInstallationDB_storeInstallationLog();

        if(fwInstallation_forceProjectRestart())
          fwInstallation_throw("FW Installation Tool: Failed to restart the project"); 
        
        exit(); //make sure own manager dies in PVSS 3.8-SP1
      }
      else if(restartProject == 2) //No project restart required. Run PostInstallation Scripts
      {
        //Trigger postInstallation scripts here:
//DebugN("&&&&&&&&&&&&&&&&&&&&Running post install scripts");   
        fwInstallation_throw("FW Installation Tool: Running component post-installation scripts. Project restart will be skipped", "INFO"); 
        fwInstallationManager_command("START", fwInstallation_getWCCOAExecutable("ctrl"), "-f fwScripts.lst");
        fwInstallationDBAgent_releaseSynchronizationLock();
      }   
      
      fwInstallationDBAgent_releaseSynchronizationLock();
      fwInstallationDB_storeInstallationLog();

      //Clear the cache.
      //fwInstallationDBCache_clear();      
      }
      delay(fwInstallationDBAgent_getSyncInterval());
      
//    }
  }//end while(1)
}//end of main
