#uses "fwInstallation.ctl"
#uses "fwInstallationUtils.ctl"


/*** WRAPPER FUNCTIONS TO NEW fwInstallationUtils library 
     Please use directly fwInstallationUtils_loadConfigurations wherever possible     
 ***/
// if driver switch to real driver otherwise switch to simulator
bool CMSfwInstallUtils_switchSimDriver(bool driver, string name, int number) {
  return fwInstallationUtils_switchSimDriver(driver,name, number);
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
  fwInstallationUtils_debugInfo(message);  
}

void CMSfwInstallUtils_endPostInstall(string component) { 
  fwInstallationUtils_endPostInstall(component);

}

bool CMSfwInstallUtils_loadConfigurationDbHardware(string configurationName, dyn_string dipConfigs = makeDynString()) {

  dyn_string exc;

  DebugTN("**** CMSfwInstallUtils_loadConfigurationDbHardware is deprecated. Please consider using fwInstallationUtils_loadConfigurations ***");

  return fwInstallationUtils_loadConfigurationDbHardware(configurationName, exc);

}

bool CMSfwInstallUtils_loadConfigurationDbLogical(string configurationName) {
  DebugTN("**** CMSfwInstallUtils_loadConfigurationDbLogical is deprecated. Please consider using fwInstallationUtils_loadConfigurations ***");

  dyn_string exc;
  return fwInstallationUtils_loadConfigurationDbLogical(configurationName, exc);

}

/***
 * Functions to save the configuration
 ***/
             
dyn_string CMSfwInstallUtils_getDeviceList(string configDp) {
    dyn_string dps_list , dptypes_list, exclude;
    dpGet(configDp + ".dps", dps_list, 
          configDp + ".dptypes", dptypes_list,
          configDp+ ".excludeDps", exclude);
    
   // DebugN(dps_list, dptypes_list);
    
    dyn_string devs;
    for (int i=1; i<= dynlen(dps_list); i++) {
        dynAppend(devs, dpNames(dps_list[i]));
    }
    
    dyn_string dps; dyn_string exc; string dpname;
    for (int i=1; i<= dynlen(dptypes_list); i++) {
        dps = dpNames("*", dptypes_list[i]);

        if (strpos(dptypes_list[i], "ExampleDP_") == 0) { // strip the ExampleDP_* data points

          for (int j=dynlen(dps); j>0; j--) {
            fwGeneral_getNameWithoutSN(dps[j],dpname, exc);
            if (strpos(dpname, "ExampleDP_") == 0) {
                DebugN("CMSfwInstallUtils_getDeviceList: Removing " + dps[j]);
                dynRemove(dps, j);
            }

          }
        }


        dynAppend(devs, dps);
        
        
    }
    
    dynUnique(devs);
    dyn_string exclList;
    
    for (int i=1; i<= dynlen(exclude); i++) {
        dynAppend(exclList, dpNames(exclude[i]));
    }
   
    int index;
    for (int i=1; i<= dynlen(exclList); i++) {
        index = dynContains(devs, exclList[i]);
        if (index >0) dynRemove(devs, index);
    }

    for (int i=dynlen(devs); i>0; i--) 
    {
      if (dpTypeName(devs[i])== "FwNode") {
	dynRemove(devs, i);
      }
    }
   
    return devs;
}


void CMSfwInstallUtils_save(string configurationName, dyn_string deviceList, int deviceConfigs =0, bool delete_old=true) {
  
  string systemName =getSystemName();
  string hierarchy = fwDevice_HARDWARE;
  
  string configDesc = configurationName;
  dyn_string exceptionInfo;


  if (deviceConfigs == 0) {
    deviceConfigs = fwConfigurationDB_deviceConfig_VALUE
    + fwConfigurationDB_deviceConfig_ADDRESS
    + fwConfigurationDB_deviceConfig_ALERT
    + fwConfigurationDB_deviceConfig_ARCHIVING
    + fwConfigurationDB_deviceConfig_DPFUNCTION
    + fwConfigurationDB_deviceConfig_CONVERSION
    + fwConfigurationDB_deviceConfig_PVRANGE
    + fwConfigurationDB_deviceConfig_SMOOTHING
    + fwConfigurationDB_deviceConfig_UNITANDFORMAT;
  }  
  fwConfigurationDB_checkInit(exceptionInfo);  
  if (dynlen(exceptionInfo)>0) {
      fwExceptionHandling_display(exceptionInfo); return ;
  }

  
  if (delete_old) {
    CMSfwInstallUtils_deleteConfiguration(configurationName, exceptionInfo);
      if (dynlen(exceptionInfo)>0) {
      fwExceptionHandling_display(exceptionInfo); return ;
      }
  }
 

fwConfigurationDB_openProgressDialog(
	makeDynInt( fwConfigurationDB_OPER_SaveDevices),
	makeDynString(	"Store devices to DB"));

  fwConfigurationDB_saveDeviceConfigurationInDB(deviceList, hierarchy,
    configurationName, deviceConfigs , exceptionInfo, systemName, configDesc);


  if (fwConfigurationDB_handleErrors(exceptionInfo)) return;
  fwConfigurationDB_closeProgressDialog();
}

void  CMSfwInstallUtils_saveLogical(string configurationName) {
      string systemName =getSystemName();
  string hierarchy = fwDevice_LOGICAL;
  
    string configDesc = configurationName;
  dyn_string exceptionInfo;
  
    fwConfigurationDB_checkInit(exceptionInfo);  
  if (dynlen(exceptionInfo)>0) {
      fwExceptionHandling_display(exceptionInfo); return ;
  }
  fwConfigurationDB_openProgressDialog(
	makeDynInt( fwConfigurationDB_OPER_SaveDevices),
	makeDynString(	"Store devices to DB"));

  dyn_string deviceList, roots;

  dyn_string exceptionInfo;
  fwNode_getNodes("",fwNode_TYPE_LOGICAL_ROOT,   roots,   exceptionInfo);

  for (int i=1; i<= dynlen(roots); i++) {
    roots[i] = dpGetAlias(roots[i] + ".") ;
  }
  
    DebugN("Saving logical view Root nodes  = ", roots);
    for (int i=1; i<= dynlen(roots); i++) {
        dynClear(deviceList);
        DebugN("Getting hierarchy from PVSS. This may take time for large hierarchies...");
       
       fwConfigurationDB_getHierarchyFromPVSS(roots[i],hierarchy,
                                           deviceList,exceptionInfo,"");

       DebugN(dynlen(deviceList) + " nodes found");
  
      fwConfigurationDB_saveDeviceConfigurationInDB(deviceList,hierarchy ,
        configurationName, 0 , exceptionInfo, systemName, configDesc);
  
  
       if (fwConfigurationDB_handleErrors(exceptionInfo)) return;
     }
        fwConfigurationDB_closeProgressDialog();

  
  
  }


void  CMSfwInstallUtils_saveLogicalFromDeviceList(string configurationName, dyn_string& hwDeviceList) {
      string systemName =getSystemName();
  string hierarchy = fwDevice_LOGICAL;
  if (configurationName == "") {
      DebugTN("Got empty configuration Name");
      return;
  }
  if (dynlen(hwDeviceList) == 0) {
      DebugTN("Got empty list ");
      return;
  }

  
  
    string configDesc = configurationName;
  dyn_string exceptionInfo;
  
  fwConfigurationDB_checkInit(exceptionInfo);  
  if (dynlen(exceptionInfo)>0) {
      fwExceptionHandling_display(exceptionInfo); return ;
  }
  fwConfigurationDB_openProgressDialog(
	makeDynInt( fwConfigurationDB_OPER_SaveDevices),
	makeDynString(	"Store devices to DB"));

  dyn_string deviceList, roots;

  dyn_string exceptionInfo;
  fwNode_getNodes("",fwNode_TYPE_LOGICAL_ROOT,   roots,   exceptionInfo);

  for (int i=1; i<= dynlen(roots); i++) {
    roots[i] = dpGetAlias(roots[i] + ".") ;
  }
  
    DebugN("Saving logical view Root nodes  = ", roots);
    for (int i=1; i<= dynlen(roots); i++) {
        dynClear(deviceList);
        DebugN("Getting hierarchy from PVSS for " + roots[i] + ". This may take time for large hierarchies...");
       
       fwConfigurationDB_getHierarchyFromPVSS(roots[i],hierarchy,
                                           deviceList,exceptionInfo,"");
       if (dynlen(exceptionInfo)>0) {
           DebugTN("Error ", exceptionInfo);
           return;
       }

       DebugN(dynlen(deviceList) + " nodes found");
       string devDp;
       for (int i=dynlen(deviceList); i>= 1; i--) {
         devDp = dpSubStr(dpAliasToName(deviceList[i]), DPSUB_SYS_DP);
         if (dpTypeName(devDp) == "FwNode") continue;
         if (! dynContains(hwDeviceList, devDp) ) {
             dynRemove(deviceList, i);
         }
       }
       
       DebugN(dynlen(deviceList) + " nodes remaining after filtering");
   //   DebugTN(deviceList);
      
      fwConfigurationDB_saveDeviceConfigurationInDB(deviceList,hierarchy ,
        configurationName, 0 , exceptionInfo, systemName, configDesc);
  
  
      if (fwConfigurationDB_handleErrors(exceptionInfo)) {
        DebugN(exceptionInfo);
        return;
      }
     }
        fwConfigurationDB_closeProgressDialog();

  
  
  }



void CMSfwInstallUtils_deleteConfiguration(string configurationName, dyn_string& exc) {
  string sql = "delete from config_items_new where TAG_ID=(select CONF_ID FROM CONFIG_DESC WHERE CONF_TAG='" + configurationName+ "')";
  string sql2 = "delete from config_desc where CONF_TAG='" + configurationName + "'";
  fwConfigurationDB_executeSqlSimple(sql,  g_fwConfigurationDB_DBConnection,exc);
  if (dynlen(exc)>0) return;
  fwConfigurationDB_executeSqlSimple(sql2,  g_fwConfigurationDB_DBConnection,exc); 
  
  DebugN("Deleted configuration " + configurationName);
  
}

/**
 * Old function to import ascii files. (Should not be used anymore)
 **/

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
      // Try to find it in the component source folder

    string sourceDir;    
    string comp = strsplit(asciiFile, "/")[1];
    if (fwInstallation_getComponentSourceDir(comp, sourceDir) == 0) {
      if ((access(sourceDir + tail, F_OK) == 0)) {
         asciiFile = sourceDir + tail;
         found = true;
        }
    }
      
  }


  if (! found) {
    CMSfwInstallUtils_debugInfo("File " + asciiFile + " not found");
    return false;
  }
 
  
  string asciiManager = PVSS_BIN_PATH + fwInstallationUtils_getWCCOAExecutable("ascii");
  string infoFile = getPath(LOG_REL_PATH) + "PVSS00ascii_info.log";
  string logFile =  getPath(LOG_REL_PATH) + "PVSS00ascii_log.log";

  string cmd = asciiManager + " -proj " + PROJ + " -in " + asciiFile + " -yes -log +stderr -log -file > "
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

/*
 Creates a SQL file to run in the condition db to update the aliases table for a given system 
  */
string CMSfwInstallUtils_saveSqlAliases(string sysName = "") {
  dyn_string dps, aliases;
  if (strlen(sysName) == 0) sysName = getSystemName();
  sysName = strrtrim(sysName, ":") + ":";
  dpGetAllAliases(dps, aliases, "*/*",sysName+ "*.");

  string host, user, pwd;
  dpGet(sysName + "_RDBArchive.db.user", user);
  
   string sql= "--- connect to " + user + " and run this script to update the aliases\n";
   sql+= "---script generated at " + formatTime("%c",getCurrentTime()) + "\n\n";
   

  dyn_string dpsAdded;
  for (int i=1; i<= dynlen(dps); i++) {   
    if (dpTypeName(dps[i]) == "FwNode") continue;
    strreplace(dps[i], "\\","\\\\");
    strreplace(aliases[i], "\\","\\\\");
    sql += "call recordAliasChange('" + dps[i] + "','" + aliases[i] + "');\n";
    
  }
  sql+="commit;\n";
  
  string fn = PROJ_PATH + DATA_REL_PATH + "aliases_" + strrtrim(sysName, ":") + "_" +  formatTime("%Y%m%d_%H%M",getCurrentTime()) + ".sql";
  file f = fopen(fn, "w");
  fputs(sql, f);
  
  fclose(f);

   DebugN(fn);
    return fn;
}

/** 
    Retrieve the list of devices from a configuration that was already saved and create a device list with the same devices
  **/
void CMSfwInstallUtils_createDeviceListFromConfiguration(string configurationName, dyn_string& exceptionInfo) {
  
  if (strlen(configurationName) == 0) {
      fwException_raise(exceptionInfo, "NO NAME", "Please specify a configuration","");
      return;
  }
    fwConfigurationDB_checkInit(exceptionInfo);
    if (dynlen(exceptionInfo) >0) return ;
    
    dyn_dyn_mixed deviceListObject;
    fwConfigurationDB_getDevicesInConfiguration(configurationName, fwDevice_HARDWARE,"",deviceListObject, exceptionInfo);
    if (dynlen(exceptionInfo) >0) return ;
    dyn_string devices;
    for (int i=1; i<= dynlen(deviceListObject[1]); i++) {
      fwGeneral_getNameWithoutSN( deviceListObject[1][i], devices[i] , exceptionInfo);
    }
    
    DebugN(dynlen(devices) + " devices found");
    
      string dpName = "CMSfwInstallUtils/deviceList/" + configurationName + "_devices";
      strreplace(dpName,".","_");
      
  if (! dpExists(dpName) ) {
      dpCreate(dpName, "CMSfwInstallUtilsDeviceList");
      dyn_errClass err = getLastError();
      if (dynlen(err)>0) {
         throwError(err); // write errors to stderr    
         fwException_raise(exceptionInfo, "DP_NOT_CREATED", "Unable to create dp","");
         return;
      }
  }
  
  dpSet(dpName + ".dps", devices,
        dpName + ".dptypes", makeDynString(),
        dpName + ".excludeDps", makeDynString(),
        dpName + ".configurationName", configurationName);
        
}
