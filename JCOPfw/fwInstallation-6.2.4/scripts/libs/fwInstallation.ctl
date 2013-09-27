//FVR
// $License: NOLICENSE
/**@file
 *
 * This package contains general functions of the FW Component Installation tool
 *
 * @author Fernando Varela (EN-ICE)
 * @date   August 2010
 */

#uses "CtrlPv2Admin"
#uses "pmon.ctl"
#uses "dist.ctl"    //Not loaded by default by control managers

#uses "fwInstallationDB.ctl"
#uses "fwInstallationDBAgent.ctl"
#uses "fwInstallationRedu.ctl"
#uses "fwInstallationManager.ctl"
#uses "fwInstallationXml.ctl"
#uses "fwInstallationPackager.ctl"
#uses "fwInstallationDeprecated.ctl"
///////////////////////////////////////////////////
/** Version of this tool.
 * Used to determine the coherency of all libraries of the installation tool
 * @ingroup Constants
*/
const string csFwInstallationToolVersion = "6.2.4";
/** Version of this library.
 * Used to determine the coherency of all libraries of the installtion tool
 * @ingroup Constants
*/
const string csFwInstallationLibVersion = "6.2.4";
///////////////////////////////////////////////////
/**
 * @name fwInstallation.ctl: Definition of variables

   The following variables are used by the fwInstallationManager.ctl library

 * @{
 */

dyn_bool    gButtonsEnabled;
string      gUserName;
string      gPassword;
string      gDebugFlag;
int         gSelectedMan;
int         gManShifted;
bool        gRefreshManagerList;
int         gRefreshSec;
int         gRefreshMilli;
int         gRefreshTime;

string      gTcpHostName;
int         gTcpPortNumber;
int         gTcpFileDescriptor;
int         gTcpFileDescriptor2;
string      gTcpFifo;

string      gTestVariable;
bool        gShowLicenseWarning;
int         gErrorCounter;
bool        gCloseEnabled;
dyn_string  gParams;

global string      gFwInstallationPmonUser;
global string      gFwInstallationPmonPwd;
global dyn_dyn_string      gFwInstallationLog;
global string      gFwInstallationLogPost;

global string      gFwInstallationCurrentComponent;

//@} // end of constants


/** Name of this component.
 * @ingroup Constants
*/
const string gFwInstallationComponentName = "fwInstallation";
/** Name of the config file of the tool.
 * @ingroup Constants
*/
const string gFwInstallationConfigFile = "fwInstallation.config";
/** Name of the init file loaded at start up of the tool.
 * @ingroup Constants
*/
const string gFwInstallationInitFile = "fwInstallationInit.config";

/** Name of the init file loaded at start up of the tool.
 * @ingroup Constants
*/
const string gFwInstallationInitScript = "fwInstallationInitScript.ctl";

/** Returned error code in case of problems
 * @ingroup Constants
*/
const int gFwInstallationError = -1;
/** Returned error code in case everything is OK
 * @ingroup Constants
*/
const int gFwInstallationOK = 0;
/** Constant that stores a particular error has already been shown
 * @ingroup Constants
*/
bool gFwInstallationErrorShown = FALSE;

/** Constant that stores if the user has clicked in the Yes to All button during installations
 * @ingroup Constants
*/
bool gFwYesToAll = FALSE;

//const int EXPIRED_REQUEST_ACTION = 1;
//const int EXPIRED_REQUEST_NAME = 2;
//const int EXPIRED_REQUEST_VERSION = 3;
//const int EXPIRED_REQUEST_EXECUTION_DATE = 4;

/** keyword used to replace by the current version name
 * @ingroup Constants
*/
string fwInstallation_VERSION_KEYWORD = "%VERSION%";
/** Path to the trash folder
 * @ingroup Constants
*/
const string gFwTrashPath = PROJ_PATH + "/fwTrash/";


//Beginning executable code:

int fwInstallation_deleteProjectPaths(dyn_string paths)
{
  for(int i = 1; i <= dynlen(paths); i++)
  { 
    fwInstallation_throw("fwInstallationDBAgent_synchronizeProjectPaths() -> Deleting project path from config file: " + paths[i], "info", 10);
    fwInstallation_removeProjPath(paths[i]);
  }
  
  return 0;
}

int fwInstallation_addProjectPaths(dyn_string dbPaths)
{ 
  for(int i = 1; i <= dynlen(dbPaths); i++)
  { 
    fwInstallation_throw("fwInstallationDBAgent_synchronizeProjectPaths() -> Adding new project path to config file: " + dbPaths[i], "info", 10);
    fwInstallation_addProjPath(dbPaths[i], 999);
  }
  return 0;
}

dyn_string fwInstallation_getHostPvssVersions()
{
  dyn_string pvssVersions;
  
  if(_WIN32)
  {
    string key = "HKEY_LOCAL_MACHINE\\SOFTWARE\\ETM\\PVSS II";
    string res = fwInstallation_getWinRegKey(key);
    dyn_string values = strsplit(res, "\n");
    for(int i = 1; i <= dynlen(values); i++)
    {
      if(patternMatch(key + "\\*", values[i]))
      {
        strreplace(values[i], key + "\\", "");
        if(values[i] != "" && values[i] != "AutoStart" && values[i] != "Configs" && strtoupper(values[i]) != "CMF")
        {
          if(values[i] == VERSION)
            values[i] = VERSION_DISP;
          
          dynAppend(pvssVersions, values[i]);
        }
      }
    }
  }
  else
  {
    string tempFile = PROJ_PATH + "/rpmQuery.txt";
    system("rpm -qa | grep -i pvss > " + tempFile);
    string res = "";
    fileToString(tempFile, res);
    dyn_string values = strsplit(res, "\n");
    for(int i = 1; i <= dynlen(values); i++)
    {
      dyn_string ds = strsplit(values[i], "-");
      //version
      dyn_string ds2 = strsplit(ds[1], "_");
      string version = ds2[dynlen(ds2)];
      dyn_string ds3 = strsplit(ds[2], ".");
      version = version + "-SP" + ds3[1];
      if(values[i] == VERSION)
         values[i] = VERSION_DISP;
      
      dynAppend(pvssVersions, version);
    }
  }
  return pvssVersions;
}

string fwInstallation_getWinRegKey(string key)
{
  string res;  
  string tempFile = PROJ_PATH + "\\regquery.txt";
  
  system("cmd /c reg query \"" + key +"\" > " + tempFile);
  fileToString(tempFile, res);
  
  return res;
}


dyn_string fwInstallation_getComponentPendingPostInstalls(string component)
{
  dyn_string componentScripts;
  dyn_string projectScripts = fwInstallation_getProjectPendingPostInstalls();
  
  dpGet(fwInstallation_getComponentDp(component) + ".postInstallFiles", componentScripts);
  return dynIntersect(componentScripts, projectScripts);
}

dyn_string fwInstallation_getProjectPendingPostInstalls()
{
  dyn_string scripts;
  dpGet(fwInstallation_getInstallationDp() + ".postInstallFiles", scripts);
  return scripts;
}

void fwInstallation_resetLog()
{
  gFwInstallationLog = makeDynString();
}

string fwInstallation_getWCCOAExecutable(string type)
{
  string prefix = "PVSS00";

  if(VERSION_DISP != "3.8-SP2" &&
     VERSION_DISP != "3.8")  
  {
    if(strtolower(type) == "data" ||
       strtolower(type) == "event" ||
       strtolower(type) == "dist" ||
       strtolower(type) == "sim" ||
       strtolower(type) == "redu" ||
       strtolower(type) == "split" ||
       strtolower(type) == "proxy" ||
       strtolower(type) == "databg" ||
       strtolower(type) == "pmon" 
       )
    {
      prefix = "WCCIL";    
    }
    else
    {
      prefix = "WCCOA";
    }
  }
  
  return prefix + strtolower(type);
}

void fwInstallation_appendLog(string msg, string severity)
{  
  if(myManType() == CTRL_MAN)
    msg = fwInstallation_getWCCOAExecutable("ctrl") + "(" + myManNum() + "): " + msg;
  else
    msg = fwInstallation_getWCCOAExecutable("ui") + "(" + myManNum() + "): " + msg;
    
  dyn_string log_line = makeDynString((string) getCurrentTime(), severity, msg);
  dynAppend(gFwInstallationLog, log_line);
  
  if(fwInstallationDB_isConnected())
    fwInstallationDB_storeInstallationLog();
}

/** This function deploys the crashAction script for the restart of the DB-Agent 
 *  of the Installation Tool when it gets blocked
 *
 * @return  0 if OK, -1 if error
*/
/*
int fwInstallation_deployCrashActionScript()
{
  string fw_installation_filename = PROJ_PATH +  BIN_REL_PATH;
  string filename = PROJ_PATH +  BIN_REL_PATH;
  
  //initialize   
  if(_WIN32)
  {
    filename += "crashAction.cmd";
    fw_installation_filename += "fwInstallation_crashAction.cmd";
  }
  else
  {
    filename += "crashAction.sh";
    fw_installation_filename += "fwInstallation_crashAction.sh";
  }
  
  if(access(filename, R_OK)) //the file does not exist or it is not readable. Just copy the new one
  {
    fwInstallation_throw("Copying the Crash Action Script for the DB-agent of the Component Installation Tool", "INFO", 10);
    if(fwInstallation_copyFile(fw_installation_filename, filename))
    {
      fwInstallation_throw("Failed to copy the Crash Action Script for the DB-agent of the Component Installation Tool");
      return -1;
    }
    system("chmod +x " + filename);    
    system("dos2unix " + filename);    
    system("dos2unix " + fw_installation_filename);    
  }  
  //if the file already exists, check if the necessary info for the installation tool is up-to-date  
  return fwInstallation_updateCrashActionScript(filename, fw_installation_filename);  
}
*/

/** This function checks and, if necessary, updates the crash action script of the Installation Tool
 *
 * @param filename name of the crash action script as expected by PMON, including the full path
 * @param fw_installation_filename name of the crash action script delievered with this version of the Installation Tool, including the full name
 * @return  0 if OK, -1 if error
*/

/*
int fwInstallation_updateCrashActionScript(string filename, string fw_installation_filename)
{
  string scriptContents;
  string fwInstallationScriptContents;
  dyn_string ds, dsInstallation;
  string beginTag = "::#Beginning FW_INSTALLATION#";
  string endTag = "::#End FW_INSTALLATION#";
  string versionTag = "::# Version:";
  string version = "";
  string versionInstallation = "";
  bool write = false;
  
  if(!_WIN32)
  {
    beginTag = substr(beginTag, 2, strlen(beginTag));
    endTag = substr(endTag, 2, strlen(endTag));
    versionTag = substr(versionTag, 2, strlen(versionTag));
  }
  
  fileToString(filename, scriptContents);
  fileToString(fw_installation_filename, fwInstallationScriptContents);
  
  ds = strsplit(scriptContents, "\n");
  dsInstallation = strsplit(fwInstallationScriptContents, "\n");

  int beginPos = dynContains(ds, beginTag); 
  int endPos = -1;
  if(beginPos > 0)
  {
    version = fwInstallation_getCrashActionScriptVersion(filename);
    versionInstallation = fwInstallation_getCrashActionScriptVersion(fw_installation_filename);
    if(version != versionInstallation)
    {
      fwInstallation_throw("Crash Action script for the Installation Tool needs to be udpate from version " 
                           + version + " to version " + versionInstallation, "INFO", 10);
      //find end tag:
      endPos = dynContains(ds, endTag);
      if(endPos > beginPos)
      {
        write = true;
        for(int z = endPos; z >= beginPos; z--)
        {
          dynRemove(ds, z);
        }
        dynAppend(ds, dsInstallation); 
      }
    }
  }

  if(write)
    if(fwInstallation_saveFile(ds, filename))
    {
      fwInstallation_throw("Failed to save the crashAction script");
      return -1;
    }
  
  if(!_WIN32)
  {
    system("chmod +x " + filename);    //make sure the file is executable
    system("dos2unix " + filename);    
    system("dos2unix " + fw_installation_filename);    
  }
 
  return 0;
}
*/

/** This function returns the version of a crash action script
 *
 * @param filename name of the file containing the crash action script
 * @return  version of the script as a string
*/
/*
string fwInstallation_getCrashActionScriptVersion(string filename)
{
  string scriptContents;
  dyn_string ds;
  string beginTag = "::#Beginning FW_INSTALLATION#";
  string versionTag = "::# Version:";
  
  if(!_WIN32)
  {    
    beginTag = substr(beginTag, 2, strlen(beginTag));
//    endTag = substr(endTag, 2, strlen(endTag));
    versionTag = substr(versionTag, 2, strlen(versionTag));
  }
  
  fileToString(filename, scriptContents);
  
  ds = strsplit(scriptContents, "\n");
  int beginPos = dynContains(ds, beginTag); 
  if(beginPos > 0)
  {
    for(int i = beginPos; i <= dynlen(ds); i++)
    {
      if(patternMatch(versionTag + "*", ds[i]))
      {
        //Check the version
        string version = ds[i];
        strreplace(version, versionTag, "");
        strreplace(version, " ", "");
        strreplace(version, "\n", "");
        return version;
      }
    }//end of loop
  }  
  
  return "";
}
*/

/** Checks if a particular patch has been applied to the current installation
 *
 * @param patch patch name
 * @return  0 if the patch is not present
            1 if the patch has been applied
*/
bool fwInstallation_isPatchInstalled(string patch)
{
  dyn_string patches;
  fwInstallation_getPvssVersion(patches);
  
  return dynContains(patches, patch);
}

/** Check if the PVSS version is equal or newer than the required PVSS version passed as argument
 *
 * @param reqVersion required PVSS version
 * @return  2 if current PVSS version is greater than the required one.
            1 if current and required PVSS versions are equal.
            0 if the required version is greater than the current one.

*/
int fwInstallation_checkPvssVersion(string reqVersion)
{
  int reqMajor, reqMinor, reqSP;
  int currMajor, currMinor, currSP;
  
  float fReqVersion = fwInstallation_pvssVersionAsFloat(reqVersion, reqMajor, reqMinor, reqSP);
  float fCurrVersion = fwInstallation_pvssVersionAsFloat(VERSION_DISP, currMajor, currMinor, currSP);

  if(fReqVersion > fCurrVersion)
    return 0;
  else if(fReqVersion == fCurrVersion) 
    return 1;
  
  return 2;
}
/** Checks if the version of the FW Component Installation Tool is equal or newer than the required PVSS version passed as argument
 *
 * @param reqVersion required version of the FW Component Installation Tool
 * @return  2 if current Tool version is greater than the required one.
            1 if current and required Tool versions are equal.
            0 if the required version is greater than the current one.

*/
int fwInstallation_checkToolVersion(string reqVersion)
{
  int reqMajor, reqMinor, reqSP;
  int currMajor, currMinor, currSP;
  
  float fReqVersion = fwInstallation_stringVersionAsFloat(reqVersion, reqMajor, reqMinor, reqSP);
  float fCurrVersion = fwInstallation_stringVersionAsFloat(csFwInstallationToolVersion, currMajor, currMinor, currSP);

  if(fReqVersion > fCurrVersion)
    return 0;
  else if(fReqVersion == fCurrVersion) 
    return 1;
  
  return 2;
}

/** Converts a Component or Tool version from string to float for easy comparison
 *
 * @param  reqVersion - (in) name of the pvss version
 * @param  version - (out) number corresponding to the version of the release
 * @param  major - (out) number corresponding to the major version of the release
 * @param  minor - (out) number corresponding to the minor version of the release
 * @return  pvss version as a float
*/
float fwInstallation_stringVersionAsFloat(string reqVersion, int &version, int &major, int &minor)
{
  dyn_string ds2 = strsplit(reqVersion, ".");

  version = 0;
  major = 0;
  minor = 0;
  
  version = ds2[1];
  if(dynlen(ds2) >= 2)
    major = ds2[2];
  if(dynlen(ds2) >= 3)
    minor = ds2[3];
  
  return version* 1000000. + major * 1000. + minor;
}
/** Converts a PVSS version from string to float for easy comparison
 *
 * @param  reqVersion - (in) name of the pvss version
 * @param  major - (out) number corresponding to the major version of the release
 * @param  minor - (out) number corresponding to the minor version of the release
 * @param  sp - (out) number corresponding to the Service Pack of the release
 * @return  pvss version as a float
*/
float fwInstallation_pvssVersionAsFloat(string reqVersion, int &major, int &minor, int &sp)
{
  dyn_string ds = strsplit(reqVersion, "-");
  dyn_string ds2 = strsplit(ds[1], ".");

  major = 0;
  minor = 0;
  sp = 0;
  
  major = ds2[1];
  if(dynlen(ds2) >= 2)
    minor = ds2[2];
  
  if(dynlen(ds) >= 2)
  {
    string str = substr(ds[2], 2, (strlen(ds[2])-2));
    sp = str;
  }
  
  return major * 1000. + minor + sp/100.;
}

/** Gets the properties of a particular PVSS system as a dyn_mixed
 *
 * @param  systemName - (in) name of the pvss system
 * @param  pvssSystem - (out) properties of the system
 * @return  0 if everything OK, -1 if errors
*/
int fwInstallation_getPvssSystemProperties(string systemName, dyn_mixed &pvssSystem)
{
  
  pvssSystem[FW_INSTALLATION_DB_SYSTEM_NAME] = systemName;
  pvssSystem[FW_INSTALLATION_DB_SYSTEM_NUMBER] = getSystemId();
  pvssSystem[FW_INSTALLATION_DB_SYSTEM_DATA_PORT] = dataPort();
  pvssSystem[FW_INSTALLATION_DB_SYSTEM_EVENT_PORT] = eventPort();
  pvssSystem[FW_INSTALLATION_DB_SYSTEM_PARENT_SYS_ID] = -1; 
  dyn_string evHosts = eventHost();
  
  pvssSystem[FW_INSTALLATION_DB_SYSTEM_COMPUTER] = strtoupper(evHosts[1]);

  int distPort = fwInstallation_getDistPort();
  int reduPort = fwInstallation_getReduPort();
  int splitPort = fwInstallation_getSplitPort();  
  pvssSystem[FW_INSTALLATION_DB_SYSTEM_DIST_PORT] = distPort;
  pvssSystem[FW_INSTALLATION_DB_SYSTEM_REDU_PORT] = reduPort;
  pvssSystem[FW_INSTALLATION_DB_SYSTEM_SPLIT_PORT] = splitPort;  
  
  return 0;
}

/** Throws a PVSS error in the log 
 * @param  msg - (in) error message
 * @param  severity - (int) severity of the message: ERROR, WARNING, INFO
 * @param  code - (int) code of the error message in the fwInstallation catalog
*/
void fwInstallation_throw(string msg, string severity = "ERROR", int code = 1)
{
  int prio = PRIO_WARNING; 
  int type = ERR_CONTROL;
  
  switch(strtoupper(severity))
  {
    case "INFO": prio = PRIO_INFO; code =10; break;
    case "WARNING": prio = PRIO_WARNING; break;
    case "ERROR": prio = PRIO_SEVERE; break;
  }
  
  errClass err = makeError("fwInstallation", prio, type, code, msg);
  throwError(err);
  if(fwInstallationDB_getUseDB() && fwInstallationDB_isConnected())
  {
    fwInstallation_appendLog(msg, strtoupper(severity));
  }
  
  return;
}


/** Order the dpl files of a component according to the attributes defined in the XML file
 * @param  files - (in) files to the ordered as a dyn_string
 * @param  attribs - (int) XML attributes for the files ordered as the 'files' argument
 * @return  ordered list of the files according to the attribs values
*/
dyn_string fwInstallation_orderDplFiles(dyn_string files, dyn_int attribs)
{
  dyn_string orderedFiles;
  dyn_string ds;

  //find those files having an attributed specified and build ds array with only them:
  for(int i = 1; i <= dynlen(files); i++)
    if(attribs[i] > 0)
      ds[attribs[i]] = files[i]; 
  
  //now append files with no attribute defined:
  for(int i = 1; i <= dynlen(files); i++)
    if(dynContains(ds, files[i]) <= 0)
      dynAppend(ds, files[i]); 
  
  //Now remove empty/non-initialized elements that there could be in ds array
  for(int i = 1; i <= dynlen(ds); i++)
    if(ds[i] != "")
      dynAppend(orderedFiles, ds[i]); 

  return orderedFiles;
}

/** This functions is to be called from the close event of a panel. 
    It checks whether the connection with the event manager is established or not. 
    If the connection is down, the function will call exit() to close the actual panel.
    If the connection is to the event manager is still up, the calling code can decide
    whether the panel must closed or not. This is done through the argument closeIfConnected.
    Typically the argument will be set to false in the cases where the developer wants to prevent
    that the user closes the panel by clicking on the top-right 'x' of the window.

  @param closeIfConnected: (boolean) Defines whether the current panel has to be close if the 
                         connection to the event manager is still up. The default value is false
                         (i.e. the function will not close the panel) 
  @return 0 - success,  -1 - error 
  @author F. Varela 
*/
int fwInstallation_closePanel(bool closeIfConnected = false) 
{
  dyn_anytype da, daa;
  da[1]  = myModuleName();     
  da[2]  = myPanelName();
  daa[1] = 0.0; daa[2] = "FALSE"; // Return value optional  
  da[3] = daa;                    // dyn_anytype binding

  if(!isEvConnOpen()) 
    return panelOff(da);
  else if(closeIfConnected)
    PanelOff();

  return 0;
}


/** Retrieves the name of the local host without network domain
 * @return  name of the local host as string
*/
string fwInstallation_getHostname()
{
  string host = getHostname();
  dyn_string ds = strsplit(host, ".");
  
  return ds[1];
}

/** Gets the name of the internal datapoint of the Installation Tool
 * @return  dp name as string
*/
string fwInstallation_getInstallationDp()
{
  string dp;
  
  if(myReduHostNum() > 1)
    dp = "fwInstallationInfo_" + myReduHostNum();
  else
    dp = "fwInstallationInfo";

  return dp;
}

/** Returns wether the DB-agent must delete or not from the project config file during synchronization with the System Configuration DB
 * @return  True is deletions must be carried out, FALSE if deletion is inhibited.
*/
bool fwInstallation_deleteFromConfigFile()
{
  bool edit = false;
  string dp = fwInstallation_getInstallationDp();
  
  dpGet(dp + ".deleteFromConfigFile", edit);
  
  return edit; 
}

/** Function used to flag deprecated functions in the library
 * @param deprecated name of the deprecated function
 * @param toBeUsed name of the function to be used instaed. If an empty argument is passed, a 
 *                 different message will be shown, telling that the user must report its usage.
*/
void fwInstallation_flagDeprecated(string deprecated, string toBeUsed = "")
{
  string str = gFwInstallationCurrentComponent + " Function :" + deprecated +" is deprecated and may eventually disappear.";
  
  if(toBeUsed != "")
    str += " Please use " + toBeUsed + " instead.";
  else
    str += " Should you be using it, please, reported to IceControls.Support@cern.ch";
  
  fwInstallation_throw(str, "WARNING", 11);
  
  return;
    
}

/** Function during the installation of the components to resolve the right name for a file depending on the current PVSS version
 * @param baseFileName (in) base name of the file
 * @param targetVersions (in) name of the target PVSS version
 * @param considerSpLevel (in) argument that defines whether the Service Pack level has to be also taken into account
 * @return final name of the file matching the target pvss version
*/
string fwInstallation_findFileForPvssVersion(string baseFileName, dyn_string targetVersions = makeDynString(), bool considerSpLevel = FALSE)
{
  bool matchingVersion = FALSE;
  string localFileName = "", currentVersion;
    
  //get current VERSION of VERSION_DISP (DISP includes Service Pack level)
  currentVersion = considerSpLevel?VERSION_DISP:VERSION;
  
  //if target versions specified, check if current version matches the pattern of any target version
  //if not, then assume that current version is a valid target version
  if(dynlen(targetVersions) == 0)
    matchingVersion = TRUE;
  else
  {      
    //search for pattern in target versions that matches current PVSS version
    for(int i=1; i<=dynlen(targetVersions) && !matchingVersion; i++)
      matchingVersion = patternMatch(targetVersions[i], currentVersion);
  }
    
  //if current PVSS version is a valid target version then try to search for the specified file
  if(matchingVersion)
  {
    //substitute the keyword with the current PVSS version, if no keyword, simply append version to file name
    if(strpos(baseFileName, fwInstallation_VERSION_KEYWORD) >= 0)
      strreplace(baseFileName, fwInstallation_VERSION_KEYWORD, currentVersion);
    else
      baseFileName += currentVersion;

    //search for file in all PVSS paths, return highest level file found
    localFileName = getPath("", baseFileName);
  }
  
  return localFileName;
}

/** Function to retrieve host properties as a dyn_mixed array
 * @param hostname (int) name of the host
 * @param pvssHostInfo (out) host properties
 * @return 0 if OK, -1 if errors
*/
int fwInstallation_getHostProperties(string hostname, dyn_mixed &pvssHostInfo)
{
  
  dyn_string pvssIps;
  
  hostname = strtoupper(hostname);
  pvssHostInfo[FW_INSTALLATION_DB_HOST_NAME_IDX] = hostname;  
  pvssHostInfo[FW_INSTALLATION_DB_HOST_IP_1_IDX] =  getHostByName(hostname, pvssIps); 
  
  //assign pvssIps to ... 
  if(dynlen(pvssIps) && pvssHostInfo[FW_INSTALLATION_DB_HOST_IP_1_IDX] == "")
    pvssHostInfo[FW_INSTALLATION_DB_HOST_IP_1_IDX] = pvssIps[1];
       
  if(dynlen(pvssIps) > 1)
    pvssHostInfo[FW_INSTALLATION_DB_HOST_IP_2_IDX] = pvssIps[2];
  
  return 0;
}  

/** Function to move files into the trash
 * @param filename (in) name of the file to be moved
 * @param trashPath (in) path to the trash. Empty path means use the default path
 * @return 0 if OK, -1 if errors
*/
int fwInstallation_sendToTrash(string filename, string trashPath = "")
{
  string str = filename;
  strreplace(str, "\\", "/");
  time t = getCurrentTime();
  str += "." + year(t) + "_" + month(t) + "_" + day(t) + "_" + hour(t) + "_" + minute(t);  
  dyn_string ds = strsplit(str, "/");
  
  if(trashPath == "")
    trashPath = gFwTrashPath;
  else
    trashPath += "/fwTrash/";
  
  if(access(trashPath, W_OK))
    if(!mkdir(trashPath))
    {
      fwInstallation_throw("fwInstallation_sendToTrash()-> Could not create trash folder", "ERROR", 1);
      return -1;
    }
    
  return !moveFile(filename, trashPath + ds[dynlen(ds)]);
}

/** Empty the trash of the FW Component Installation Tool
 * @param path (in) path to the trash. Empty path means use the default path
 * @return 0 if OK, -1 if errors
*/
int fwInstallation_emptyTrash(string path = "")
{
  int err = 0;
  if(path == "")
    path = gFwTrashPath;
  else
    path += "/fwTrash/";
  
  dyn_string files = getFileNames(path);

  for(int i = 1; i <= dynlen(files); i++)
  {
    if(remove(path + files[i]))
      ++err;
  }
  if(err)
    return -1;
    
  return 0;  
}


////
/** Function to make a binary comparison of two files. Contribution from TOTEM.
 * @param filename1 (in) name of the first file for comparison
 * @param filename2 (in) name of the second file for comparison
 * @return true if the two files are identical, false if the files are different
 * 
*/
bool fwInstallation_fileCompareBinary(string filename1, string filename2)
{
   if (!isfile(filename1)||!isfile(filename2))
   {
       return false;
   }

   if (getFileSize(filename1)!=getFileSize(filename2))
   {
     return false;
   }

   file f1, f2;
   int size=1024;
   int c1, c2;
   blob b1, b2;

   //opens a file for reading in the binary mode rb
   f1 = fopen(filename1, "rb");
   f2 = fopen(filename2, "rb");

     bool result = true;
   while (true)
   {
     if (feof(f1)!=0) {break;}
     if (feof(f2)!=0) {break;}

     c1 = blobRead(b1, size, f1);
     c2 = blobRead(b2, size, f2);

     if (c1!=c2) {result=false;}
     if (b1!=b2) {result=false;}
   }

   fclose(f1);
   fclose(f2);

   return result;
}

/** Function to copy files. If blind copy fails (e.g. an executable is in used), the 
 *  function will try to rename the existing file and only then copy the file once again.
 * @param source (in) name of the file to be copied
 * @param destination (in) target file name including full path
 * @param trashPath (in) path to trash
 * @param compare (in) argument used to compare files before copying. If files are identical the file is not re-copied.
 * @return 0 if OK, -1 if errors
 * 
*/
int fwInstallation_copyFile(string source, string destination, string trashPath = "", bool compare = true)
{
  time t = getCurrentTime();
  
  if(compare)
  {
    if(fwInstallation_fileCompareBinary(source, destination)) //if files are binary identical, do not copy them
      return 0;
  }
  
  if(!copyFile(source, destination))
  {    
    if(access(destination, F_OK) == 0)
    {
      fwInstallation_throw("INFO: fwInstallation_copyFile() -> Renaming old file before trying to copy new one....", "INFO", 10);
      //File already exists, move it to trash first and then try to copy the new file:
      if(fwInstallation_sendToTrash(destination, trashPath))
      {
        fwInstallation_throw("fwInstallation_copyFile() -> Could not move previous version of the file in target directory: " + destination, "error", 4);
        return -1; 
      }
  
      if(!copyFile(source, destination))
      {
        fwInstallation_throw("fwInstallation_copyFile() -> Could not copy file: " + destination, "error", 5);
        //put old file back:
        //moveFile(destination + "." + str, destination);    
        return -1;
      }      
      else
        fwInstallation_throw("INFO: fwInstallation_copyFile() -> File successfully copied: " + destination, "info", 10);
    }
    else
    {
        fwInstallation_throw("fwInstallation_copyFile() -> Could not copy file: " + destination, "error", 5);
        return -1;
    }
  }
  
  return 0;
}
        
/** This function registers a PVSS project path
  @param sPath: (in) path to be registered as string
  @return 0 if success,  -1 if error 
  @author F. Varela 
*/
int fwInstallation_registerProjectPath(string sPath)
{
  string      sSep = (_WIN32)?"\\":"/",
              projName, remoteHost, sVersion;
  dyn_anytype daResult;
  dyn_anytype da, daa;
  dyn_string  projs, version, projpath, ds;
  int         i, x, y, iPmonPort;
  int         iErr, iErr2;
  dyn_errClass dErr;
  bool errorShown = false;

  if ( !globalExists("gParams") )
    addGlobal("gParams", DYN_ANYTYPE_VAR);
  
  strreplace(sPath, "\\", "/");
  ds = strsplit(sPath, "/");
  projName = (dynlen(ds)>0)?ds[dynlen(ds)]:"";
  
  if ( strrtrim(strltrim(sPath)) == "" || projName == "" )
  {
    //pmon_warningOutput("Console�3551", -1);
    if(myManType() == UI_MAN)
	    ChildPanelOnCentralModal("vision/MessageInfo1", "ERROR", "$1:Project registration error.\nEmpty path or project name");
    else
      fwInstallation_throw("Project registration error.\nEmpty path or project name");
    
    return -1;
  }

  sPath = "";
  for ( i = 1; i <= dynlen(ds) - 1; i++ )
    sPath += ds[i] + "/";
  
  //Check if path exists:
  if(access(sPath, F_OK) != 0) //if directory does not exist, create it now
  {
    if(_WIN32)
      system("cmd /c mkdir " + sPath);
    else
      system("mkdir " + sPath);
  }
   

  iErr = paRegProj(projName, sPath, remoteHost, iPmonPort, true, false);
/*  
  if ( iErr )
  {
    if(myManType() == UI_MAN)
      ChildPanelOnCentralModal("vision/MessageInfo1", "ERROR", "$1:Path registration failed.");
    else
      fwInstallation_throw("Path registration failed.");

    return -1;
  }
*/  
  return 0;  
}

/** This function retrieves the version of an installed component
  @param component (in) name of the component
  @return component version as string
*/
string fwInstallation_getComponentVersion(string component)
{
  string version;
    
  fwInstallation_isComponentInstalled(component, version);
    
  return version;
}

/** This function checks if a component is installed in the current project
  @param component (in) name of the component
  @param version (out) current version of the installed component
  @return true if the component is installed, false otherwise
*/
bool fwInstallation_isComponentInstalled(string component, string &version)
{
  dyn_anytype componentInfo;
  
  if(!dpExists(fwInstallation_getComponentDp(component)))
  {
    version = "";  
    return false;  
  }
  else 
  {
    if(fwInstallation_getComponentInfo(component, "componentversionstring", componentInfo ) != 0)
    {
      fwInstallation_throw("fwInstallation_getComponentVersion() -> Could not retrieve the version of component: " + component); 
      return -1;
    }
  
  if(dynlen(componentInfo))
    version = componentInfo[1];
  else
    version = "";  
  }
    
  return true;
}

/** This function retrieves the source directory from which a component was installed
  @param component (in) name of the component
  @param sourceDir (out) source directory
  @return 0 if everything OK, -1 if errors.
*/
int fwInstallation_getComponentSourceDir(string component, string &sourceDir)
{
  dyn_anytype componentInfo;
  
  if(fwInstallation_getComponentInfo(component, "sourceDir", componentInfo ) != 0)
  {
    fwInstallation_throw("fwInstallation_getComponentSourceDir() -> Could not retrieve the source directory of component: " + component); 
    return -1;
  }
  
  if(dynlen(componentInfo))
    sourceDir = componentInfo[1];
  else
    sourceDir = "";
  
  return 0;
}

/** This function returns the name of a component correspoding to an internal dp of the installation tool
  @param dp (in) name of the dp of the installation tool
  @return name of the component
*/
string fwInstallation_dp2name(string dp)
{
  
  //remove system name
  if(strpos(dp, ":") > 0)
    strreplace(dp, getSystemName(), "");

  //remove fwInstallation prefix  
  strreplace(dp, "fwInstallation_", "");

  //remove _2 if it exists  
  if(strpos(dp, "_1") > 0){
    dp = substr(dp, 0, strpos(dp, "_1"));
  }
  if(strpos(dp, "_2") > 0){
    dp = substr(dp, 0, strpos(dp, "_2"));
  }
  return dp;
}

/** This function updates the internal dp-type used by the installation tool for the components
*/
fwInstallation_updateComponentDps()
{
  string name;
  dyn_string compDps = fwInstallation_getInstalledComponentDps();
  
  for(int z = 1; z <= dynlen(compDps); z++)
  {
    dpGet(compDps[z] + ".name", name);
                  
    if(name != fwInstallation_dp2name(compDps[z]))
      dpSet(compDps[z] + ".name", fwInstallation_dp2name(compDps[z]));
  }
}


/** This function adds the main libraries of the installation tool to the config file of the project
*/
void fwInstallation_addLibToConfig()
{
  dyn_string libs;
  
	paCfgReadValueList(PROJ_PATH + CONFIG_REL_PATH + "config", "ui", "LoadCtrlLibs", libs);
	if(dynContains(libs, "fwInstallation.ctl") == 0)
		paCfgInsertValue(PROJ_PATH + CONFIG_REL_PATH + "config", "ui", "LoadCtrlLibs", "fwInstallation.ctl");		

	paCfgReadValueList(PROJ_PATH + CONFIG_REL_PATH + "config", "ctrl", "LoadCtrlLibs", libs);
	if(dynContains(libs, "fwInstallation.ctl") == 0)
		paCfgInsertValue(PROJ_PATH + CONFIG_REL_PATH + "config", "ctrl", "LoadCtrlLibs", "fwInstallation.ctl");		
}

/** This function updates the main dp-type (FwInstallationInformation) of the installation tool from previous versions
  @return 0 if OK, -1 if errors
*/
int fwInstallation_updateDPT()
{
  string dp = fwInstallation_getInstallationDp();
  string probeDp = "fw_InstallationProbing";
  probeDp = fwInstallationRedu_getLocalDp(probeDp);
  dpCreate(probeDp,"_FwInstallationComponents");	
	
  if(!dpExists(dp + ".status") ||!dpExists(dp + ".name") || !dpExists(probeDp  + ".helpFile") || !dpExists(probeDp + ".description"))
  {
    int dpCreateResult = 0;
    _fwInstallation_createDataPointTypes(FALSE, dpCreateResult); //Not up-to-date: Update dpts now
    if(dpCreateResult)
      return -1;
  }
                	
  if(dpExists(probeDp))
    dpDelete(probeDp);
  
  return 0;
}
void fwInstallation_setCurrentComponent(string component, string version = "")
{
  gFwInstallationCurrentComponent = component;
  if(version != "")
    gFwInstallationCurrentComponent = gFwInstallationCurrentComponent + " v." + version;
                                      
  return;
}

void fwInstallation_unsetCurrentComponent()
{
  gFwInstallationCurrentComponent = "";
  return;
}


/** Sets the status of the installation tool
  @param status true if OK, false if error
*/
void fwInstallation_setToolStatus(bool status)
{
  string dp = fwInstallation_getInstallationDp();
  dpSet(dp + ".status", status);
  
  return;
}

bool fwInstallation_getToolStatus()
{
  bool status = false;
  string dp = fwInstallation_getInstallationDp();
  dpGet(dp + ".status", status);
  
  return status;
}
/** This function needs to be called before the first use of the installation library and after each installation.
  @param runPostInstall (in) this variable specifies whether pending post-install scripts, if any, must be run during initialization
  @return 0 if OK, -1 if errors 
*/
int fwInstallation_init(bool runPostInstall = true)
{
	dyn_string dataPointTypes;
	int dpCreateResult;
	dyn_string dynPostInstallFiles_all; // all the postInstall init files to be executed
	dyn_string dynScripts;
	int i;
	int iReturn;
	dyn_float dreturnf;
	dyn_string dreturns;
	string testString, startMode;
  string dp = fwInstallation_getInstallationDp();
  string dpa = fwInstallation_getAgentDp();
        	
	//Add libs to config file if they do not exist yet
  fwInstallation_addLibToConfig();


  if ( !globalExists("gFwInstallationLog") )
    addGlobal("gFwInstallationLog", DYN_DYN_STRING_VAR);
  
  //Initialize the PMON variables:
  if ( !globalExists("gFwInstallationPmonUser") )
    addGlobal("gFwInstallationPmonUser", STRING_VAR);
  
  if ( !globalExists("gFwInstallationPmonPwd") )
    addGlobal("gFwInstallationPmonPwd", STRING_VAR);
  
  if ( !globalExists("gFwInstallationCurrentComponent") )
    addGlobal("gFwInstallationCurrentComponent", STRING_VAR);

  gFwInstallationPmonUser = "N/A";
  gFwInstallationPmonPwd = "N/A";
  
	// check whether the _FwInstallationComponents dpt exists
	dataPointTypes = dpTypes();
	if (dynContains(dataPointTypes, "_FwInstallationComponents") <= 0)
	{
		fwInstallation_throw("Starting the Installation Tool for the first time", "INFO", 10);
		// create the installation tool internal data points	
		_fwInstallation_createDataPointTypes(TRUE, dpCreateResult);
		// check the result
		if (dpCreateResult)
  		fwInstallation_throw("Failed to create the internal data points. Please re-install the FW Component Installation Tool");
    
   fwInstallation_throw("Internal data points for the installation tool created", "INFO", 10);
	}
  else if(fwInstallation_updateDPT())//Check that the DPTs are up-to-date:
  {
    fwInstallation_throw("Could not update internal DPTs of the installation tool");
    return -1;
  }

  if(!dpExists(dp))
  {
    dpCreate(dp, "_FwInstallationInformation");
  }
  
  //if there are components installed, make sure that the dp-element 'name' is properly filled:
  fwInstallation_updateComponentDps();
    
  //Create trash if it does not exist:
  string sourceDir;
  dpGet(dp + ".installationDirectoryPath", sourceDir);
  
  if(sourceDir != "" && access(sourceDir, F_OK) >= 0)
  {
    fwInstallation_addProjPath(sourceDir, 999);
/*    if(fwInstallation_createTrash(sourceDir))
    {
      fwInstallation_throw("fwInstallation_sendToTrash()-> Could not create trash folder", "error", 4);
      fwInstallation_setToolStatus(false);
      return -1;
    }
*/    
  } 
//  else
//  {
//    fwInstallation_throw("Invalid installation directory: " + sourceDir);
//  }  
  
  //Install installation agent:
  if(!fwInstallation_isAgentInstalled())      
  {
    fwInstallation_throw("Installation Tool DB-agent not up-to-date. Forcing update now...", "INFO", 10);
    if(fwInstallation_installAgent())
    {
      fwInstallation_throw("fwInstallation_init() -> Could not install FW installation Agent");
      return -1;
    }
    fwInstallation_throw("FW Component Installation DB-agent successfully installed", "INFO", 10);
  }
  
  fwInstallation_updateVersion();
  
  //Load init file as the user may have defined the schema owner there
  fwInstallation_loadInitFile();
  //Load init scripts
  if(fwInstallation_runInitScript())
  {
    fwInstallation_setToolStatus(false);
    fwInstallation_throw("There were errors executing the init script FW Component Installation Tool");
    return -1;
  }
  //Check if the DB is to be used and if so, upgrade system table to populate the event computer id column if required:
  int projectId = -1;
  if(fwInstallationDB_getUseDB() && fwInstallationDB_connect() == 0)
    fwInstallationDB_isProjectRegistered(projectId);
  
  //add control manager for post installation scripts:
  string user, pwd, host = fwInstallation_getHostname();
  int port = pmonPort();
  fwInstallation_getPmonInfo(user, pwd);
  fwInstallationManager_add(fwInstallation_getWCCOAExecutable("ctrl"), "once", 30, 1, 1, "-f fwScripts.lst", host, port, user, pwd);
  //fwInstallation_throw("Ctrl Manager to project console for component post-install scripts added", "INFO", 10);
  
  if(runPostInstall)
  {
    fwInstallation_executePostInstallScripts();
  }

/*  
  //Deploy the crash action script for the installation tool:
  if(VERSION != "3.6")
  {
    if(fwInstallation_deployCrashActionScript())
    {
      fwInstallation_setToolStatus(false);
      fwInstallation_throw("fwInstallation_init() -> Failed to deploy the crash action script of the FW Component Installation Tool");
      return -1;
    }
  }
*/ 
 
//  fwInstallation_throw("*** FW Component Installation Tool v." + csFwInstallationToolVersion+ " ready ***", "INFO", 10);
  fwInstallation_setToolStatus(true);
  return 0;
}


/** This function lauches the pending post-installation of scripts of installed components (if any)
  @return 0 if OK, -1 if errors 
*/
int fwInstallation_executePostInstallScripts()
{
  dyn_string dynPostInstallFiles_all;
  string dp = fwInstallation_getInstallationDp();
        
  dpGet(dp + ".postInstallFiles:_original.._value", dynPostInstallFiles_all);
  
  if(dynlen(dynPostInstallFiles_all))
  {
    string user, pwd, host = fwInstallation_getHostname();
    int port = pmonPort();
    fwInstallation_getPmonInfo(user, pwd);

    return fwInstallationManager_command("START", fwInstallation_getWCCOAExecutable("ctrl"), "-f fwScripts.lst", host, port, user, pwd);
  }
  return 0;
}

/** This function creates the trash for the installation tool
  @param sourceDir (in) path where to create the trash as string
  @return 0 if OK, -1 if errors 
*/
int fwInstallation_createTrash(string sourceDir)
{
  if(sourceDir != "" && access(sourceDir, W_OK))
  if(!mkdir(sourceDir))
    return -1;
  
  return 0;
}

/** This function updates the version number of the installation tool from previous versions
  @return 0 if OK, -1 if errors 
*/
int fwInstallation_updateVersion()
{
  string version;
  string dp = fwInstallation_getInstallationDp();
  
  int error = fwInstallation_getToolVersion(version);
  
  if(error != 0){
    fwInstallation_throw("fwInstallation_getToolVersion() -> Could not update the installation tool version");
    return -1;
  }
    
  if(version != csFwInstallationToolVersion)
    dpSet(dp + ".version", csFwInstallationToolVersion);

  return 0;
}

/** This function retrieves the current version of the installation tool used in a particular PVSS system.
  @param version (out) version of the tool
  @param systemName (int) name the pvss system where to read the installation tool version from
  @return 0 if OK, -1 if errors 
*/
int fwInstallation_getToolVersion(string &version, string systemName = "")
{  
  string dp = fwInstallation_getInstallationDp();
  
  if(systemName == "")
    systemName = getSystemName();

  if(systemName == getSystemName())
  {
    version = csFwInstallationToolVersion;
    return 0;  //If local system we are done
  }
      
  //In case we want to read tool version in a different version
  if(!patternMatch("*:", systemName))
    systemName += ":";
  
  if(!dpExists(dp + ".version")){
    version = "";
    return -1;
  }
  else {
    dpGet(systemName + dp + ".version", version);    
  }
  return 0;
}

/** This function retrieves name of the internal dp holding the parameterization of the DB-agent
  @return name of the internal dp as string 
*/
string fwInstallation_getAgentDp()
{
  string dp;
  
  if(myReduHostNum() > 1)
    dp = "fwInstallation_agentParametrization_" + myReduHostNum();
  else
    dp = "fwInstallation_agentParametrization";
  
  return dp;
}

/** This function retrieves name of the internal dp holding the pending installation requests to be executed by the DB-Agent
  @return name of the dp as string  
*/
string fwInstallation_getAgentRequestsDp()
{
  string dp;
  
  if(myReduHostNum() > 1)
    dp = "fwInstallation_agentPendingRequests_" + myReduHostNum();
  else
    dp = "fwInstallation_agentPendingRequests";
  
  return dp;
}


/** This function checks if the DB-agent of the installation tool is installed in the current project
  @return true if the agent is installed, false otherwise
*/
bool fwInstallation_isAgentInstalled()
{
  string dp = fwInstallation_getAgentDp();
  if(dpExists(dp + ".managers.stopDistAfterSync") && dpExists(dp + ".db.connection.schemaOwner") && dpExists(dp + ".db.connection.driver"))
     return true;
   else
     return false;  
}

/** This function installs the DB-Agent of the FW Component Installation Tool
  @return 0 if OK, -1 if errors 
*/
int  fwInstallation_installAgent()
{
  int error = 0;
  dyn_string dataPointTypes = dpTypes();
  string oldVersion;
  string newVersion;
  string dp = fwInstallation_getInstallationDp();
  string dpa = fwInstallation_getAgentDp();
        
    error = _fwInstallation_createAgentDataPointType("_FwInstallation_agentParametrization", true);

  if(error){
    fwInstallation_throw("fwInstallation_installAgent() -> Could not create DPT for FW installation agent");
    return -1;
  }
  if(_fwInstallation_createAgentDataPointType("_FwInstallation_agentPendingRequests", true))
  {
    fwInstallation_throw("fwInstallation_installAgent() -> Could not create DPT for FW installation agent");
    return -1;
  }
  
  // check whether the fwInstallation_agentParametrization dp exists
  string dpa = fwInstallation_getAgentDp();
  if(!dpExists(dpa))
  {
    error = dpCreate(dpa, "_FwInstallation_agentParametrization");
    if(error){
      fwInstallation_throw("fwInstallation_installAgent() -> Could not create DP for FW installation agent: Agent parametrization");
      return -1;
    }
  }
  else
  {
    //this piece of code is necessary to upgrade from versions previous to 4.0.0
    //as the owner was introduced only in this version of the tool.
    string owner, writer;
    dpGet(dpa + ".db.connection.schemaOwner", owner,
          dpa + ".db.connection.username", writer);
    
    if(owner == "" || writer == owner)
    {
      //Load init file as schema owner may have been defined there:
      fwInstallation_loadInitFile();
    }
  }
  
  string dpr = fwInstallation_getAgentRequestsDp();
  if(!dpExists(dpr))
  {
    error = dpCreate(dpr, "_FwInstallation_agentPendingRequests");
    if(error){
      fwInstallation_throw("fwInstallation_installAgent() -> Could not create DP for FW installation agent: Agent installation requests");
      return -1;
    }
    fwInstallationDBAgent_setSyncInterval(300);
  }else
  {
    time tSync;
    
    dpGet(dpa + ".syncInterval:_online.._stime", tSync);
    
    if(tSync <= makeTime(2000, 1, 1, 1)){
      fwInstallationDBAgent_setSyncInterval(300);
    }
  }
  //Add Agent Ctrl and NV managers to the PVSS console:
  string user, pwd, host = fwInstallation_getHostname();
  int port = pmonPort();
  fwInstallation_getPmonInfo(user, pwd);

  fwInstallationManager_add(fwInstallation_getWCCOAExecutable("ctrl"), "always", 30, 3, 3, "-f fwInstallationAgent.lst", host, port, user, pwd);
  
  dpSet(dpa + ".db.projectStatus", makeDynInt(0, 0, 0, 0, 0, 0, 0, 0, 0));
  
  return error;
}


/** This function creates the internal dp-types of the installtation tool
@param type name of the dp-type to be created
@param create flag to indicated if the dp-type has to be overwritten (obsolete, legacy)
@return result 0 if OK, -1 otherwise 
*/

int _fwInstallation_createAgentDataPointType(string type, bool create)
{
	dyn_dyn_string dynDynElements;
	dyn_dyn_int dynDynTypes;
	
	int result = 0;

    dynDynElements[1] = makeDynString (type , "");
    dynDynTypes[1] = makeDynInt (DPEL_STRUCT);

    if(type == "_FwInstallation_agentParametrization")
    {	
	  dynDynElements[2] = makeDynString ("","db");
	  dynDynElements[3] = makeDynString ("","", "connection");
	         dynDynElements[4] = makeDynString ("", "", "", "driver");
          dynDynElements[5] = makeDynString ("", "", "", "server");
          dynDynElements[6] = makeDynString ("", "", "", "username");
          dynDynElements[7] = makeDynString ("" , "", "", "password");          
          dynDynElements[8] = makeDynString ("" , "", "", "initialized");          
          dynDynElements[9] = makeDynString ("" , "", "", "schemaOwner");          
	  dynDynElements[10] = makeDynString ("", "", "useDB");
	  dynDynElements[11] = makeDynString ("", "", "projectStatus");
//	  dynDynElements[12] = makeDynString ("", "", "synchronization");
	  dynDynElements[12] = makeDynString ("", "lock");
	  dynDynElements[13] = makeDynString ("", "restart");
	  dynDynElements[14] = makeDynString ("", "syncInterval");
          dynDynElements[15] = makeDynString ("", "managers");
          dynDynElements[16] = makeDynString ("", "", "stopDist");
          dynDynElements[17] = makeDynString ("", "", "stopUIs");
          dynDynElements[18] = makeDynString ("", "", "stopCtrl");
          dynDynElements[19] = makeDynString ("", "", "stopDistAfterSync");
          

    dynDynTypes[2] = makeDynInt (0, DPEL_STRUCT);
	    dynDynTypes[3] = makeDynInt (0, 0, DPEL_STRUCT);
	      dynDynTypes[4] = makeDynInt (0, 0, 0, DPEL_STRING);
	  dynDynTypes[5] = makeDynInt (0, 0, 0, DPEL_STRING);
	  dynDynTypes[6] = makeDynInt (0, 0, 0, DPEL_STRING);
	  dynDynTypes[7] = makeDynInt (0, 0, 0, DPEL_STRING);
	  dynDynTypes[8] = makeDynInt (0, 0, 0, DPEL_INT);
	  dynDynTypes[9] = makeDynInt (0, 0, 0, DPEL_STRING);
	  dynDynTypes[10] = makeDynInt (0, 0, DPEL_INT);
	  dynDynTypes[11] = makeDynInt (0, 0, DPEL_DYN_INT);
//	  dynDynTypes[12] = makeDynInt (0, 0, DPEL_DYN_INT);
	  dynDynTypes[12] = makeDynInt (0, DPEL_INT);
	  dynDynTypes[13] = makeDynInt (0, DPEL_INT);
	  dynDynTypes[14] = makeDynInt (0, DPEL_INT);
	  dynDynTypes[15] = makeDynInt (0, DPEL_STRUCT);
	  dynDynTypes[16] = makeDynInt (0, 0, DPEL_INT);
	  dynDynTypes[17] = makeDynInt (0, 0, DPEL_INT);
	  dynDynTypes[18] = makeDynInt (0, 0, DPEL_INT);
   dynDynTypes[19] = makeDynString (0, 0, DPEL_INT);
   }
    else if(type == "_FwInstallation_agentPendingRequests")
   {
	  dynDynElements[2] = makeDynString ("","restart");
	  dynDynElements[3] = makeDynString ("","pvssInstallRequests");
	  dynDynElements[4] = makeDynString ("", "pvssDeleteRequests");
          dynDynElements[5] = makeDynString ("", "dbInstallRequests");
          dynDynElements[6] = makeDynString ("", "dbDeleteRequests");
          dynDynElements[7] = makeDynString ("", "trigger");
          dynDynElements[8] = makeDynString ("", "execute");
          dynDynElements[9] = makeDynString ("", "msg");
          dynDynElements[10] = makeDynString ("", "managerReconfiguration");
          dynDynElements[11] = makeDynString ("", "", "manager");
          dynDynElements[12] = makeDynString ("", "", "startMode");
          dynDynElements[13] = makeDynString ("", "", "secKill");
          dynDynElements[14] = makeDynString ("", "", "restartCount");
          dynDynElements[15] = makeDynString ("", "", "resetMin");
          dynDynElements[16] = makeDynString ("", "", "commandLine");

          dynDynTypes[2] = makeDynInt (0, DPEL_INT);
	  dynDynTypes[3] = makeDynInt (0, DPEL_DYN_STRING);
	  dynDynTypes[4] = makeDynInt (0, DPEL_DYN_STRING);
	  dynDynTypes[5] = makeDynInt (0, DPEL_DYN_STRING);
	  dynDynTypes[6] = makeDynInt (0, DPEL_DYN_STRING);
          dynDynTypes[7] = makeDynInt (0, DPEL_INT);
          dynDynTypes[8] = makeDynInt (0, DPEL_INT);
          dynDynTypes[9] = makeDynInt (0, DPEL_STRING);
          dynDynTypes[10] = makeDynInt (0, DPEL_STRUCT);
	  dynDynTypes[11] = makeDynInt (0, 0, DPEL_DYN_STRING);
	  dynDynTypes[12] = makeDynInt (0, 0, DPEL_DYN_STRING);
	  dynDynTypes[13] = makeDynInt (0, 0, DPEL_DYN_INT);
	  dynDynTypes[14] = makeDynInt (0, 0, DPEL_DYN_INT);
	  dynDynTypes[15] = makeDynInt (0, 0, DPEL_DYN_INT);
	  dynDynTypes[16] = makeDynInt (0, 0, DPEL_DYN_STRING);
          
   }
    
 	 result = dpTypeChange(dynDynElements, dynDynTypes );
	
   dynClear(dynDynElements);
   dynClear(dynDynTypes);
   
   return result;
}


/** The function reads all project paths from the config file into a dyn_string.
@param projPaths: dyn_string which will be filled with the project paths from the config file
@return 0 if success,  -1 if error, -2 if no project paths in the config file (this should not happen)
*/
int fwInstallation_getProjPaths( dyn_string & projPaths )
{
	string configPath = getPath(CONFIG_REL_PATH);
	string configFile = configPath + "config";

	paCfgReadValueList(configFile, "general", "proj_path", projPaths, "=");
}

/** This function backs up the project config file. 
*   It is intendended to be called before component installation/uninstallation
  @return 0 if OK, -1 otherwise 
*/
int fwInstallation_backupProjectConfigFile()
{
  string configPath = getPath(CONFIG_REL_PATH);
  string configFile = configPath + "config";
  time t = getCurrentTime();
  string str = t; //Casting to string
        
  strreplace(str, ".", "_");
  strreplace(str, ":", "_");
  strreplace(str, " ", "_");
        
  string bkConfigFile = configPath + "config_" + str;
            
  return fwInstallation_copyFile(configFile, bkConfigFile);
}

/** This functions writes all project paths given in a dyn_string to the config file 
*   and overwrites existing paths exept the main project path.
  @param projPaths: dyn_string with the project paths for the config file
  @return 0 if OK, -1 if error 
*/
int fwInstallation_setProjPaths( dyn_string projPaths )
{
	dyn_string configLines;
	
	dyn_int tempPositions;
	dyn_string tempLines;
	string tempLine;
	int i,j;
	bool sectionFound = FALSE;
	
	string configPath = getPath(CONFIG_REL_PATH);
	string configFile = configPath + "config";

	if(_fwInstallation_getConfigFile(configLines) == 0)
	{
		for (i=1; i<=dynlen(configLines); i++)
		{
			tempLine = configLines[i];
			if(strpos(tempLine, "proj_path") >= 0)
			{
				dynAppend(tempPositions,i);
			}
		}
		if(dynlen(tempPositions)>0)
		{
			sectionFound = TRUE;
			dynClear(tempLines);
			for (j=1; j<=dynlen(projPaths); j++)
			{
				tempLine = "proj_path = \"" + projPaths[j] + "\"";
				dynAppend(tempLines,tempLine);
			}
			for (j=dynlen(tempPositions); j>=1; j--)	
			{
				dynRemove(configLines,tempPositions[j]);
			}
			dynInsertAt(configLines,tempLines,tempPositions[1]);
		}
		if(sectionFound)
		{
			fwInstallation_saveFile(configLines, configFile);
		} else {
			return -2;
		}
	} else {
		return -1;
	}
 return 0;       
}


/** This function add a project path to the config file.
@param projPath: string that contains the project path to be added to the config file
@param position: position of the added path in the list (n = specified position, try 999 for last before main project path)
@return 0 if success,  -1 if error,  -2 if position out of range
@author S. Schmeling
*/
synchronized int fwInstallation_addProjPath(string projPath, int position)
{
	dyn_string configLines;
	
	dyn_int tempPositions;
	string tempLine;
	int i,j;
	bool sectionFound = FALSE;
	
	string configPath = getPath(CONFIG_REL_PATH);
	string configFile = configPath + "config";

	if(_fwInstallation_getConfigFile(configLines) == 0)
	{
          if(dynContains(configLines, "proj_path = \"" + projPath + "\""))  //Path already in file. Nothing to be done
            return 0;
          
		for (i=1; i<dynlen(configLines); i++)
		{
			tempLine = configLines[i];
			if(strpos(tempLine, "proj_path") >= 0)
			{
				dynAppend(tempPositions,i);
			}
		}
		if(dynlen(tempPositions)>0)
		{
			sectionFound = TRUE;
			tempLine = "proj_path = \"" + projPath + "\"";
			if(position > 0) 
			{
				if(position < dynlen(tempPositions))
				{
					dynInsertAt(configLines,tempLine,tempPositions[position]);
				} else {
					dynInsertAt(configLines,tempLine,tempPositions[dynlen(tempPositions)]);
				}
			}			
		}
		if(sectionFound == TRUE)
		{
    fwInstallation_registerProjectPath(projPath);
			return fwInstallation_saveFile(configLines, configFile);
		} else {
			return -2;
		}
	} else {
		return -1;
	}
        return 0;
}


/** This function removes the given project path from the config file.
@param projPath: string that contains the project path to be removed from the config file
@return 0 if success, -1 if general error, -2 if project path does not exist
@author S. Schmeling
*/
synchronized int fwInstallation_removeProjPath( string projPath )
{
/*  
	dyn_string configLines;
	
	dyn_int tempPositions;
	dyn_string tempLines;
	string tempLine;
	int i,j;
	bool sectionFound = FALSE;
*/	
  string configPath = getPath(CONFIG_REL_PATH);
  string configFile = configPath + "config";

  paCfgDeleteValue(configFile, "general", "proj_path", projPath);

/*  
	if(_fwInstallation_getConfigFile(configLines) == 0)
	{
		for (i=1; i<=dynlen(configLines); i++)
		{
			tempLine = configLines[i];
			if(strpos(tempLine, "proj_path") >= 0)
			{
				if(strpos(tempLine, projPath) >= 0)
				{
					dynAppend(tempPositions,i);
				}
			}
		}
		if(dynlen(tempPositions)>0)
		{
			sectionFound = TRUE;
			for (j=dynlen(tempPositions); j>=1; j--)	
			{
				dynRemove(configLines,tempPositions[j]);
			}
		}
		if(sectionFound == TRUE)
		{
			return fwInstallation_saveFile(configLines, configFile);
		} else {
			return -2;
		}
	} else {
		return -1;
	}
*/  
}

/** This function retrieves name of the internal dp associated with an installed component
  @param componentName (int) name of the component in a string
  @return version of the component as a string 
*/
string fwInstallation_getComponentDp(string componentName)
{
  string dp;
  if(myReduHostNum() > 1 && !patternMatch("*_"+ myReduHostNum(), componentName)) 
    dp = "fwInstallation_"+strltrim(strrtrim(componentName)) + "_" + myReduHostNum();
  else
    dp = "fwInstallation_"+strltrim(strrtrim(componentName));

  return dp;
}


/** This function returns the following property of the installed component: list of files for this component

@param componentName: string with the name of the component 
@param componentProperty: name of the requested property
@param componentInfo: variable that contains the property of the component
@return 0 - "success"  -1 - error 
@author S. Schmeling and F. Varela
*/
int fwInstallation_getComponentInfo( string componentName, string componentProperty, dyn_anytype & componentInfo )
{
	string temp_componentProperty, temp_string;
	float temp_float;
	dyn_anytype temp_dyn_string;
	bool temp_bool;
	int i;
	
	temp_componentProperty = strtolower(componentProperty);

        string dp = fwInstallation_getComponentDp(componentName);
    	
	switch(temp_componentProperty)
	{
		case "componentfiles": 
			i = dpGet(dp +".componentFiles:_original.._value", temp_dyn_string);
			dynAppend(componentInfo, temp_dyn_string);
			return i;
			break;
		case "configGeneral": 
			i = dpGet(dp+".configFiles.configGeneral:_original.._value", temp_dyn_string);
			dynAppend(componentInfo, temp_dyn_string);
			return i;
			break;
		case "configLinux": 
			i = dpGet(dp+".configFiles.configLinux:_original.._value", temp_dyn_string);
			dynAppend(componentInfo, temp_dyn_string);
			return i;
			break;
		case "configWindows": 
			i = dpGet(dp+".configFiles.configWindows:_original.._value", temp_dyn_string);
			dynAppend(componentInfo, temp_dyn_string);
			return i;
			break;
		case "initfiles": 
			i = dpGet(dp+".initFiles:_original.._value", temp_dyn_string);
			dynAppend(componentInfo, temp_dyn_string);
			return i;
			break;
		case "postinstallfiles": 
			i = dpGet(dp+".postInstallFiles:_original.._value", temp_dyn_string);
			dynAppend(componentInfo, temp_dyn_string);
			return i;
			break;
		case "dplistfiles": 
			i = dpGet(dp+".dplistFiles:_original.._value", temp_dyn_string);
			dynAppend(componentInfo, temp_dyn_string);
			return i;
			break;
		case "requiredcomponents": 
			i = dpGet(dp+".requiredComponents:_original.._value", temp_dyn_string);
			dynAppend(componentInfo, temp_dyn_string);
			return i;
			break;
		case "subcomponents": 
			i = dpGet(dp+".subComponents:_original.._value", temp_dyn_string);
			dynAppend(componentInfo, temp_dyn_string);
			return i;
			break;
		case "scriptfiles": 
			i = dpGet(dp+".scriptFiles:_original.._value", temp_dyn_string);
			dynAppend(componentInfo, temp_dyn_string);
			return i;
			break;
		case "date": 
			i = dpGet(dp+".date:_original.._value", temp_string);
			dynAppend(componentInfo, temp_string);
			return i;
			break;
		case "descfile": 
			i = dpGet(dp+".descFile:_original.._value", temp_string);
			dynAppend(componentInfo, temp_string);
			return i;
			break;
		case "sourcedir": 
			i = dpGet(dp+".sourceDir:_original.._value", temp_string);
			dynAppend(componentInfo, temp_string);
			return i;
			break;
		case "installationdirectory": 
			i = dpGet(dp+".installationDirectory:_original.._value", temp_string);
			dynAppend(componentInfo, temp_string);
			return i;
			break;
		case "componentversion": 
		case "componentversionstring": 
			i = dpGet(dp+".componentVersionString:_original.._value", temp_string);
			if(temp_string == "")
			{
				i += dpGet(dp+".componentVersion:_original.._value", temp_float);
				if(temp_float == floor(temp_float))
				{
					sprintf(temp_string,"%2.1f",temp_float);
				} else {
					temp_string = temp_float;
				}
				dpSet(dp + ".componentVersionString:_original.._value", componentVersionString);
			}
			dynAppend(componentInfo, temp_string);
			return i;
			break;
		case "requiredinstalled": 
			i = dpGet(dp+".requiredInstalled:_original.._value", temp_bool);
			dynAppend(componentInfo, temp_bool);
			return i;
			break;
		case "isitsubcomponent": 
			i = dpGet(dp+".isItSubComponent:_original.._value", temp_bool);
			dynAppend(componentInfo, temp_bool);
			return i;
			break;
		default:
			dynAppend(componentInfo, "Property not known");
			return -1;
	}			
}

/** This function returns the name of the internal dps correspoding to all components installed in the project
@return names of the internal dps as a dyn_string 
*/
dyn_string fwInstallation_getInstalledComponentDps()
{
  dyn_string componentDPs;
  
  if(myReduHostNum() > 1)
    componentDPs = dpNames("fwInstallation_*_" + myReduHostNum(), "_FwInstallationComponents");
  else
  {
    componentDPs = dpNames("fwInstallation_*", "_FwInstallationComponents");
    for(int i = dynlen(componentDPs); i >= 1; i--)
    {
      if(strpos(componentDPs[i], ":") > 0)
        strreplace(componentDPs[i], getSystemName(), "");
      
      //Savannah #54773 
      if(patternMatch("*_2", componentDPs[i])|| patternMatch("*_3", componentDPs[i]) || patternMatch("*_4", componentDPs[i]))
        dynRemove(componentDPs, i);
    }
    
  }
  return componentDPs;
}

/** This function gets the information about all installed components into a dyn_dyn_string structure:
	[n][1] component name
	[n][2] component version
	[n][3] path to the installation
        [n][4] description file
@param componentsInfo: dyn_dyn_string that will contain all installed components and their respective version numbers
@return 0 if success,  -1 if error, -999999 if no components installed
@author S. Schmeling and F. Varela
*/
int fwInstallation_getInstalledComponents(dyn_dyn_string & componentsInfo)
{
  dyn_dyn_string tempAllInfo;	
  dyn_string componentDPs;
  string componentVersionString, installationDirectory, descFile;
  float componentVersion;
  string sourcePath;
  int installationNotOK;
  int dependenciesOK;
  string name;
        
  componentDPs = fwInstallation_getInstalledComponentDps();
  dynClear(tempAllInfo);

	if(dynlen(componentDPs) == 0)
	{
		return -999999;
	} 
  else 
  {
		for (int i=1; i<=dynlen(componentDPs); i++)
		{  
      dpGet(componentDPs[i]+".name", name,
            componentDPs[i]+".componentVersionString",componentVersionString,
            componentDPs[i]+".installationDirectory",installationDirectory,
            componentDPs[i]+".descFile", descFile,
            componentDPs[i]+".sourceDir", sourcePath,
            componentDPs[i]+".installationNotOK", installationNotOK,
            componentDPs[i]+".requiredInstalled", dependenciesOK);
      fwInstallation_updateComponentVersionFormat(name);
      dpGet(componentDPs[i]+".componentVersionString", componentVersionString);
                        
      if(patternMatch("*/", sourcePath))
        descFile = sourcePath + descFile;
      else
        descFile = sourcePath + "/" + descFile;
    
      dynAppend(tempAllInfo[i], name);
      dynAppend(tempAllInfo[i], componentVersionString);
      dynAppend(tempAllInfo[i], installationDirectory);
      dynAppend(tempAllInfo[i], descFile);
      dynAppend(tempAllInfo[i], installationNotOK);
      dynAppend(tempAllInfo[i], dependenciesOK);
      dynAppend(tempAllInfo[i], fwInstallation_getComponentPendingPostInstalls(name));
		}
		componentsInfo = tempAllInfo;
		return 0;
	}
}

/** This function gets the information about all available components in the specified paths into a dyn_dyn_string structure:
	- component name
	- component version
	- subcomponent [yes/no]
	- path to the description file

@param componentPaths (in) dyn_string with the paths to description files
@param componentsInfo (out) dyn_dyn_string that will contain all installed components and their respective version numbers and their paths
@param component (in) component pattern
@param scanRecursively (in) flag indicating if the search must recurse over subdirectories
@return 0 if success, -1 if error 
@author S. Schmeling and F. Varela
*/
int fwInstallation_getAvailableComponents(dyn_string componentPaths, 
                                          dyn_dyn_string & componentsInfo, 
                                          string component = "*", 
                                          bool scanRecursively = false)
{
 	string dirCurrentValue;
	dyn_string dynAvailableDescriptionFiles;
	string componentFileName;
	string strComponentFile;
	string tagName;
	string tagValue;

	string componentName;
	float componentVersion;
	string componentVersionString;
	
	int result;
	
	bool	fileLoaded;
	bool isItSubComponent = false;
	
	int i, j, ii, iii;

	dyn_dyn_string tempAllInfo;
	dynClear(tempAllInfo);
	iii = 0;
        
        string dontRestartProject = "no";

	if(dynlen(componentPaths) == 0)
	{
		return -1;
	}

	for(ii=1; ii<=dynlen(componentPaths); ii++)
	{
		dirCurrentValue = componentPaths[ii];
		// it the directory name is empty
		if (dirCurrentValue != "")
		{
			// read the names of files that have the .xml extension in a directory specified by dirCurrentValue
			//FVR: Do it recursively
			if(scanRecursively)
  	          dynAvailableDescriptionFiles =  fwInstallation_getFileNamesRec(dirCurrentValue, component + ".xml");
 	        else
	          dynAvailableDescriptionFiles =  getFileNames(dirCurrentValue, component + ".xml");			

			// for each component description file, read the component name, version and display it in the graphic table
			
			for( i = 1; i <= dynlen(dynAvailableDescriptionFiles); i++)
			{
				// get the file name of an .xml description file
				componentFileName = dynAvailableDescriptionFiles[i];                                
                                dyn_string tags, values;
                                dyn_anytype attribs;
                                int err = 0;
                                
                                if(fwInstallationXml_getTag(dirCurrentValue + "/" + componentFileName, "name", values, attribs) != 0 ||
                                   dynlen(values) <= 0)
                                {
                                  //non-component file
                                  continue;
                                }
                                
                                componentName = values[1];
                                dynClear(values);
                                fwInstallationXml_getTag(dirCurrentValue + "/" + componentFileName, "version", values, attribs);
                                componentVersionString = values[1];
                                componentVersion = values[1];
                                
                                dynClear(values);
                                fwInstallationXml_getTag(dirCurrentValue + "/" + componentFileName, "subComponent", values, attribs);
                                if(dynlen(values) > 0 )
                                  if((strtolower(values[1]) == "yes"))
                                    isItSubComponent = true;
                                  else
                                    isItSubComponent = false;
                                                                  
                                dynClear(values);
                                fwInstallationXml_getTag(dirCurrentValue + "/" + componentFileName, "dontRestartProject", values, attribs);
                                if(dynlen(values) > 0 )
                                  dontRestartProject = values[1];

					// check whether the description file contains the component name
					if(componentName != "") 
					{
						iii++;
						dynAppend(tempAllInfo[iii], componentName);
						dynAppend(tempAllInfo[iii], componentVersionString);
						dynAppend(tempAllInfo[iii], dontRestartProject);
						if(isItSubComponent)
						{
							dynAppend(tempAllInfo[iii], "yes");
						} else {
							dynAppend(tempAllInfo[iii], "no");
						}
						dynAppend(tempAllInfo[iii], dirCurrentValue + "/" + componentFileName);
					 	componentName = "";
						isItSubComponent = false;
					}
			}
		}
	}
	componentsInfo = tempAllInfo;
	return 0;
}

/** This function allows to show a timed out popup during installation

@param popupText		text to be shown
@author Sascha Schmeling
*/
int fwInstallation_popup(string popupText)
{
 dyn_float df;
	dyn_string ds;
	
	if(myManType() == UI_MAN)
	{
		ChildPanelOnCentralReturn("fwInstallation/fwInstallation_popup.pnl", "fwInstallation",
                                          makeDynString("$text:"+popupText), df, ds);
	}
  else
    fwInstallation_throw("INFO: " + popupText, "info", 10);
  
  return 0;
}

/** This function returns the project name
@return project name as string
*/
string paGetProjName()
{
	return PROJ;
}

/** This function retrieves the system name(s) on which a certain 
"application" = component is installed.

@param applicationName	name of the application/component to be found
@param systemNames			name(s) of the system(s) with the application/component installed
@author Sascha Schmeling
*/

fwInstallation_getApplicationSystem(string applicationName, dyn_string &systemNames)
{
	string tempString;
	systemNames = dpNames("*:fwInstallation_"+applicationName, "_FwInstallationComponents");
	
	if(dynlen(systemNames) > 0)
		for(int i=1; i<=dynlen(systemNames); i++)
		{
			dpGet(systemNames[i]+".componentVersionString", tempString);
			if(tempString != "")
				systemNames[i] = dpSubStr(systemNames[i], DPSUB_SYS);
			else
				systemNames[i] = "*" + dpSubStr(systemNames[i], DPSUB_SYS) + "*";				
		}
		
	dynSortAsc(systemNames);
}


/** This function retrieves the PVSS version number as well as the installed patches

@param patches (out) dyn_string array with all installed patches
@return pvss version as a string
*/
string fwInstallation_getPvssVersion(dyn_string & patches)
{
  string pvssVersion = VERSION_DISP;
  dynClear(patches);

  patches = getFileNames(PVSS_PATH + "/install", "*.lst");
  for(int i = dynlen(patches); i >= 1; i--)
  strreplace(patches[i], ".lst", ""); 

	return pvssVersion;
}

/** This function shows the help file associated to a component

@param componentName	(in) name of the component in the database
@param systemName (in) name of the system where to look for the component
@author Sascha Schmeling
*/
fwInstallation_showHelpFile(string componentName, string systemName = "")
{
  int replaced;
  string 	path, tempHelpFile, helpFile, browserCommand;
  string dp = fwInstallation_getComponentDp(componentName);
  
  if(!dpExists("fwGeneral.help.helpBrowserCommandWindows"))
  {
    if(myManType() == UI_MAN)
      ChildPanelOnCentral("vision/MessageInfo1", "ERROR", "Sorry you need to install the fwCore\nin order to enable this functionality.");
    else
      fwInstallation_throw("Sorry you need to install the fwCore\nin order to enable this functionality.");
    
    return;
  }
  	
    if(systemName == "")
      systemName = getSystemName();
    
    if(!patternMatch("*:", systemName))
      systemName += ":";

	componentName = strltrim(componentName, "_");
            
	dpGet(dp + ".installationDirectory", path,
              dp + ".helpFile", tempHelpFile);
  
  if(!patternMatch("*/", path))
    path += "/";

	helpFile = path + "help/en_US.iso88591/"+ tempHelpFile;
	
	strreplace(helpFile, "\\\\", "\\");
	strreplace(helpFile, "\\", "/");

	if(_WIN32)
	{
		dpGet(systemName + "fwGeneral.help.helpBrowserCommandWindows", browserCommand);
		if(browserCommand =="")
			browserCommand = "cmd /c start iexplore $1";
		replaced = strreplace(browserCommand, "$1", helpFile);
		if(replaced == 0)
			browserCommand = browserCommand + " " + helpFile;
		system(browserCommand);
	}
	else
	{
		dpGet(systemName + "fwGeneral.help.helpBrowserCommandLinux", browserCommand);
		if(browserCommand =="")
			browserCommand = "mozilla $1";
		replaced = strreplace(browserCommand, "$1", helpFile);
		if(replaced == 0)
			browserCommand = browserCommand + " " + helpFile;
		system(browserCommand);
	}
}	

/** This function gets all entries from the config file into string structures
@param configLines: dyn_string containing the lines from the config file 
@return 0 if OK, -1 if error
@author M. Sliwinski, adapted for library by S. Schmeling and F. Varela
*/
int _fwInstallation_getConfigFile(dyn_string & configLines)
{
	bool fileLoaded = false;
	string fileInString;
	string configPath = getPath(CONFIG_REL_PATH);
	string configFile = configPath + "config";
	
// load config file into dyn_string
	fileLoaded = fileToString(configFile, fileInString);
	if (! fileLoaded )
	{
		fwInstallation_throw("fwInstallationLib: Cannot load config file");
		return -1;
	} else {
		configLines = strsplit(fileInString, "\n");
		return 0;
	}
}

/** this function saves the dyn_string  into PVSS project confg file

@param configLines: the dyn_string containing the lines from the  file
@param filename: the name of a file
@author M.Sliwinski. Modified by F. Varela (with a lot of pain...)
*/
int fwInstallation_saveFile( dyn_string & configLines, string filename)
{
	int i;
	string strLinesToSave;
	

	file fileHdlConfig;
	
	int writeResult;

	// open the file for writing
	fileHdlConfig = fopen(filename, "w");
	// if the file is not opened
	if(fileHdlConfig == 0)
	{
		fwInstallation_throw("fwInstallation: File " + filename + " could not be opened", "error", 4);
		return -1;
	}
	else
	{
		// copy each line from a dyn_string into string and separate the lines with newline character
		for(i = 1; i <= dynlen(configLines); i++)
		{
                  if(configLines[i] !=  "")
                  {
                    if(configLines[i] != "\n")
                    {
                      if(patternMatch("[*", configLines[i]))
                        strLinesToSave += "\n" + configLines[i]; //If a new section, add also a blank line just before
                      
		      strLinesToSave += configLines[i] + "\n";
                    }
                      else
                      strLinesToSave += configLines[i];
                  }     
		}
		// save the string into the file
		writeResult = fputs(strLinesToSave , fileHdlConfig);
		fclose(fileHdlConfig);
		return 0;
	}
}


/** This function deletes the information for the component from the project config file.

@param componentName: the name of a component
@author S.Schmeling and patched by F. Varela.
*/
_fwInstallation_DeleteComponentFromConfig(string componentName)
{
	dyn_string configLines; // this table contains the config file - each row contains one line from config file
	string configPath = getPath(CONFIG_REL_PATH);
	string configFile = configPath + "config";
	int i;
	bool insideComponentConfiguration = FALSE;

	if(_fwInstallation_getConfigFile(configLines) == 0)
	{
		for(i=1; i<=dynlen(configLines); i++)
		{		
			if(strltrim(strrtrim(configLines[i])) == "#begin " + componentName)
			{
				insideComponentConfiguration = TRUE;
			}
			else if(strltrim(strrtrim(configLines[i])) == "#end " + componentName)
			{
				insideComponentConfiguration = FALSE;
				dynRemove(configLines, i);
				i--;
			}
                        
			if(insideComponentConfiguration)
			{
				dynRemove(configLines, i);
				i--;
			}
		}
// save the config file
		fwInstallation_saveFile(configLines, configPath + "config");
	} else {
		return -1;
	}
}


/** This function creates the Installation Component DPT and DP
@param create (in) flag to indicate if an existing dp-type has to be overwritten (obsolete, legacy)
@param result (out) result of the operation, 0 if OK, -1 if error
@author M.Sliwinski, adapted by S. Schmeling and F. Varela.
*/
_fwInstallation_createDataPointTypes(bool create, int & result)
{
	int n;
	dyn_dyn_string dynDynElements;
	dyn_dyn_int dynDynTypes;
	
	result = 0;
	
	dynDynElements[1] = makeDynString ("_FwInstallationComponents", "", "");
	dynDynElements[2] = makeDynString ("", "componentFiles", "");
	dynDynElements[3] = makeDynString ("", "configFiles", "");

	dynDynElements[4] = makeDynString ("", "", "configWindows");
	dynDynElements[5] = makeDynString ("", "", "configLinux");
	dynDynElements[6] = makeDynString ("", "", "configGeneral");

	dynDynElements[7] = makeDynString ("", "initFiles", "");
	dynDynElements[8] = makeDynString ("", "postInstallFiles", "");
	
	dynDynElements[9] = makeDynString ("", "dplistFiles", "");
	dynDynElements[10] = makeDynString ("", "componentVersion", "");
	dynDynElements[11] = makeDynString ("", "date", "");
	dynDynElements[12] = makeDynString ("", "descFile", "");
	dynDynElements[13] = makeDynString ("", "installationDirectory", "");
	dynDynElements[14] = makeDynString ("", "requiredComponents", "");
	dynDynElements[15] = makeDynString ("", "requiredInstalled", "");
	dynDynElements[16] = makeDynString ("", "subComponents", "");
	dynDynElements[17] = makeDynString ("", "isItSubComponent", "");
	dynDynElements[18] = makeDynString ("", "scriptFiles", "");
	dynDynElements[19] = makeDynString ("", "componentVersionString", "");

	dynDynElements[20] = makeDynString ("", "deleteFiles", "");
	dynDynElements[21] = makeDynString ("", "postDeleteFiles", "");

	dynDynElements[22] = makeDynString ("", "helpFile", "");

	dynDynElements[23] = makeDynString ("", "sourceDir", "");
	dynDynElements[24] = makeDynString ("", "installationNotOK", "");
	dynDynElements[25] = makeDynString ("", "comments", "");
	dynDynElements[26] = makeDynString ("", "name", "");
	dynDynElements[27] = makeDynString ("", "description", "");

	dynDynTypes[1] = makeDynInt (DPEL_STRUCT);
	dynDynTypes[2] = makeDynInt (0, DPEL_DYN_STRING);
	dynDynTypes[3] = makeDynInt (0, DPEL_STRUCT);
	
	dynDynTypes[4] = makeDynInt (0, 0, DPEL_DYN_STRING);
	dynDynTypes[5] = makeDynInt (0, 0, DPEL_DYN_STRING);
	dynDynTypes[6] = makeDynInt (0, 0, DPEL_DYN_STRING);
	
	dynDynTypes[7] = makeDynInt (0, DPEL_DYN_STRING);
	dynDynTypes[8] = makeDynInt (0, DPEL_DYN_STRING);
	dynDynTypes[9] = makeDynInt (0, DPEL_DYN_STRING);
	dynDynTypes[10] = makeDynInt (0, DPEL_FLOAT);
	dynDynTypes[11] = makeDynInt (0, DPEL_STRING);
	dynDynTypes[12] = makeDynInt (0, DPEL_STRING);
	dynDynTypes[13] = makeDynInt (0, DPEL_STRING);
	dynDynTypes[14] = makeDynInt (0, DPEL_DYN_STRING);
	dynDynTypes[15] = makeDynInt (0, DPEL_BOOL);
	dynDynTypes[16] = makeDynInt (0, DPEL_DYN_STRING);
	dynDynTypes[17] = makeDynInt (0, DPEL_BOOL);
	dynDynTypes[18] = makeDynInt (0, DPEL_DYN_STRING);
	dynDynTypes[19] = makeDynInt (0, DPEL_STRING);

	dynDynTypes[20] = makeDynInt (0, DPEL_DYN_STRING);
	dynDynTypes[21] = makeDynInt (0, DPEL_DYN_STRING);

	dynDynTypes[22] = makeDynInt (0, DPEL_STRING);
	dynDynTypes[23] = makeDynInt (0, DPEL_STRING);
	dynDynTypes[24] = makeDynInt (0, DPEL_BOOL);
	dynDynTypes[25] = makeDynInt (0, DPEL_DYN_STRING);
	dynDynTypes[26] = makeDynInt (0, DPEL_STRING);
	dynDynTypes[27] = makeDynInt (0, DPEL_STRING);

	n = dpTypeChange(dynDynElements, dynDynTypes );
        
	// check the result of creating dpts
	if(n == -1)
	  result = -1;
	
	dynClear(dynDynElements);
	dynClear(dynDynTypes);
	
	dynDynElements[1] = makeDynString ("_FwInstallationInformation" , "");
	dynDynElements[2] = makeDynString ("","installationDirectoryPath");
	dynDynElements[3] = makeDynString ("","postInstallFiles");
	dynDynElements[4] = makeDynString ("","postDeleteFiles", "");
	dynDynElements[5] = makeDynString ("","lastSourcePath");
	dynDynElements[6] = makeDynString ("","addManagersDisabled");
	dynDynElements[7] = makeDynString ("","activateManagersDisabled");
	dynDynElements[8] = makeDynString ("","version");
	dynDynElements[9] = makeDynString ("", "blockUis");
	dynDynElements[10] = makeDynString ("", "deleteFromConfigFile");
	dynDynElements[11] = makeDynString ("", "status");

	dynDynTypes[1] = makeDynInt (DPEL_STRUCT);
	dynDynTypes[2] = makeDynInt (0, DPEL_STRING);
	dynDynTypes[3] = makeDynInt (0, DPEL_DYN_STRING);
	dynDynTypes[4] = makeDynInt (0, DPEL_DYN_STRING);
	dynDynTypes[5] = makeDynInt (0, DPEL_STRING);
	dynDynTypes[6] = makeDynInt (0, DPEL_BOOL);
	dynDynTypes[7] = makeDynInt (0, DPEL_BOOL);
	dynDynTypes[8] = makeDynInt (0, DPEL_STRING);
	dynDynTypes[9] = makeDynInt (0, DPEL_BOOL);
	dynDynTypes[10] = makeDynInt (0, DPEL_BOOL);
	dynDynTypes[11] = makeDynInt (0, DPEL_BOOL);
		
  n = dpTypeChange(dynDynElements, dynDynTypes );
	
	// check the result of creating dpts
	if(n == -1)
		result = -1;
  
}


/** This function proposes an installation directory
  @return path to the installation directory defined by the user as a string
*/
string _fwInstallation_proposeInstallationDir()
{
	string path;
	dyn_string steps;
	steps = strsplit(getPath(LOG_REL_PATH), "/");
	if(dynlen(steps)>2)
		for(int i=1; i<dynlen(steps)-1; i++)
			path += steps[i] +"/";
	else
		path = steps[1] +"/";
	return path + "fwComponents_"+formatTime("%Y%m%d", getCurrentTime())+"/";
}
  

/** This function gets the components data from the directory specified in the textBox and fills the graphic table with it.

@param tableName (in) the name of a graphic table to be filled with data 
@param sourceWidget (in) the name of a widget containing the directory from which the data about the components is taken
@param systemName (in) name of the pvss system where to look for components
@param scanRecursively (in) flag indicating if the search must recurse over subdirectories
@return 0 - "success"  -1 - error 
@author M.Sliwinski. Modified by F. Varela.
*/
int fwInstallation_getComponentsInfo(string tableName , 
                                     string sourceWidget, 
                                     string systemName = "", 
                                     bool scanRecursively = false)
{
	string dirCurrentValue;
	dyn_string dynAvailableDescriptionFiles;
	string componentFileName;
	string strComponentFile;
	string tagName;
	string tagValue;

	string componentName;
	float componentVersion;
	string componentVersionString;
	
	shape shape_dirFromSourceWidget = getShape(sourceWidget);
	shape shape_destinationTable = getShape(tableName);
	int result;
	
	bool	fileLoaded;
	bool isItSubComponent = false;
	
	int i, j;
  bool showSubComponents;
  string dontRestartProject = "no";
  dyn_anytype attribs;
        
 
  if(systemName == "")
    systemName = getSystemName();
    
  if(!patternMatch("*:", systemName))
    systemName += ":";
    
   
	shape_destinationTable.deleteAllLines();
	
	dirCurrentValue = shape_dirFromSourceWidget.text;
	if (dirCurrentValue == "")
  {
//    fwInstallation_throw("You must define the source directory", "WARNING", 10);
	   return 0;
 	}
  
  if(!patternMatch("*/", dirCurrentValue))
  dirCurrentValue += "/";

  strreplace(dirCurrentValue, "\\", "/");  
  
	// read the names of files that have the .xml extension in a directory specified by dirCurrentValue
	//FVR: Do it recursively
	if(scanRecursively)
  	  dynAvailableDescriptionFiles =  fwInstallation_getFileNamesRec( dirCurrentValue, "*.xml");
	else
	  dynAvailableDescriptionFiles = getFileNames(dirCurrentValue, "*.xml");

        
  if(dynlen(dynAvailableDescriptionFiles) <= 0)
  {
    if(myManType() == UI_MAN)
      ChildPanelOnCentral("vision/MessageInfo1", "Not files found", makeDynString("$1:No component files found.\nAre you sure the directory is readable?"));
    else
      fwInstallation_throw("No component files found.\nAre you sure the directory is readable?");
    return 0;
  }
  
	// for each component description file, read the component name, version and display it in the graphic table
	for( i = 1; i <= dynlen(dynAvailableDescriptionFiles); i++)
	{
		 // get the file name of an .xml description file
		 componentFileName = dynAvailableDescriptionFiles[i];
		
 		// load the description file
	 	//fileLoaded = fileToString(dirCurrentValue + "/" + componentFileName, strComponentFile);
    dyn_string ds;
    if(fwInstallationXml_getTag(dirCurrentValue + "/" + componentFileName, "name", ds, attribs))
    { 
			  fwInstallation_throw("fwInstallation: Cannot load " + componentFileName + " file ", "error", 4);	
       continue;
    }
    else if(dynlen(ds) < 1)//bug #38484: Check that it is a component file:
      continue;
   
    componentName = ds[1];
                
    dynClear(ds);
    fwInstallationXml_getTag(dirCurrentValue + "/" + componentFileName, "version", ds, attribs); 
    if(dynlen(ds) < 1)//bug #38484: Check that it is a component file:
    {
            continue; //not a component file
    }
    componentVersionString = ds[1];
    componentVersion =  componentVersionString;
                
    dynClear(ds);
    fwInstallationXml_getTag(dirCurrentValue + "/" + componentFileName, "subComponent", ds, attribs);
    if(dynlen(ds) > 0 && strtolower(ds[1]) == "yes")
      isItSubComponent = true;
                
    fwInstallationXml_getTag(dirCurrentValue + "/" + componentFileName, "dontRestartProject", ds, attribs);
    if((dynlen(ds) > 0 && strtolower(ds[1]) == "yes"))
  		  dontRestartProject = "yes";
                                
			// check whether the description file contains the component name
			// and whether it is a subcomponent - if it is a subcomponent - do not display it in a table with available components
    getValue("ShowSubComponents","state", 0, showSubComponents);

			if((componentName != "") && ((!isItSubComponent) || (isItSubComponent && showSubComponents)))
			{
  			// this component can be installed - put it in the table with available components. 
				//if (componentName == "") - it means that the xml file does not contain the component name
				//							 or the component file does not describe a component				
				// Check if the component is already installed	
				if(systemName != "*" || systemName != "*:")  //If we are not dealing with more than one system, look if component is installed
				  fwInstallation_componentInstalled(componentName, componentVersionString, result, systemName, 1);
				
				if (result == 1) // component is installed
				{
					if(isItSubComponent)
						  shape_destinationTable.appendLine("componentName", "_"+componentName, "componentVersion", componentVersionString, "colStatus" , "Installed" , "descFile", dirCurrentValue + "/" + componentFileName);
					else
						  shape_destinationTable.appendLine("componentName", componentName, "componentVersion", componentVersionString, "colStatus" , "Installed" , "descFile", dirCurrentValue + "/" + componentFileName);
				}
				else // component is not installed
				{
					// display the information about the component
					if(isItSubComponent)
						shape_destinationTable.appendLine("componentName", "_"+componentName, "componentVersion", componentVersionString, "descFile", dirCurrentValue + "/" + componentFileName);
					else
					  shape_destinationTable.appendLine("componentName", componentName, "componentVersion", componentVersionString, "descFile", dirCurrentValue + "/" + componentFileName);
				}
			 	componentName = "";
			}
		 isItSubComponent = false;
	 }
  return 0;
}



/** This function checks if the component is already installed. It checks the PVSSDB.

@param componentName (in) the name of a component to be checked
@param requestedComponentVersion (in) requested version of the component
@param result (out) result of the operation (obsolete, legacy)
@param systemName (in) system where to check if the component is installed
@param beStrict (in) flag to indicate an exact match of the versions installed and required
@return 1 - "component installed"  0 - "component not installed"
*/
fwInstallation_componentInstalled(string componentName, 
                                  string requestedComponentVersion, 
                                  int &result, 
                                  string systemName = "", 
                                  bool beStrict = false)
{
    string installedComponentVersion,dummy;
    float installedComponentVersionOld;
    string dp = fwInstallation_getComponentDp(componentName);

    if(systemName == "")
      systemName = getSystemName();
    
    if(!patternMatch("*:", systemName))
      systemName += ":";
  	
	// check whether the component data point exists - if it exists it is installed
	if(dpExists(dp))
	{
		// retrieve the version of installed component
		dpGet(dp + ".componentVersionString:_original.._value", installedComponentVersion);

		// Legacy
		if(installedComponentVersion == "")
		{
			fwInstallation_throw("Updating information for component: " + componentName, "INFO", 10);
			dpGet(dp + ".componentVersion:_original.._value", installedComponentVersionOld);
			sprintf(dummy,"%5.5f",installedComponentVersionOld);
			installedComponentVersion = strltrim(strrtrim(dummy,"0"));
			if(strpos(installedComponentVersion,".") == strlen(installedComponentVersion)-1)
			{
				installedComponentVersion += "0";
			}
			dpSet(dp + ".componentVersionString", installedComponentVersion);
		}
		result = (_fwInstallation_CompareVersions(installedComponentVersion,requestedComponentVersion, beStrict));
	}
	else
	{
		// return the component is not installed
		result = 0;
	}	
}

void fwInstallation_updateComponentVersionFormat(string componentName)
{
  string componentVersionString, componentVersion;
  
  string dp = fwInstallation_getComponentDp(componentName);
  dpGet(dp + ".componentVersionString", componentVersionString);
  if(componentVersionString == "")
  {
    dpGet(dp + ".componentVersion", componentVersion);
    if(componentVersion == floor(componentVersion)) sprintf(componentVersionString,"%2.1f",componentVersion);
    else componentVersionString = componentVersion;

    dpSetWait(dp + ".componentVersionString", componentVersionString);
  }
  return;
}


/** This function retrieves the installed components from the PVSS database and 
fills the graphic table - "tblInstalledComponents"

@author M.Sliwinski and F. Varela
*/

synchronized fwInstallation_getInstalledComponentsUI()
{
  dyn_string dynComponentNames, dynComponentNameDps;
  dyn_string systemName_Component;
  dyn_string dataPointTypes;

  string componentName;
  string componentVersionString;
  float componentVersion;
  bool installationNotOK; 
  string descFile, helpFile;
  string installationDirectory;
  shape shape_destinationTable;
  bool isItSubComponent;	
  int row = 0, column;
  int i;	
  dyn_string ds;
  unsigned systemId;
  bool showSubComponents = false;
  bool requiredInstalled = true;

  // get shape of the graphic table	
  tblInstalledComponents.deleteAllLines();
  
  fwInstallation_checkComponentBrokenDependencies();  
  
  ErrorText.visible = FALSE;
  ErrorText2.visible = FALSE;
  ErrorColor1.visible = FALSE;
  ErrorColor2.visible = FALSE;
	
  // get existing data point types
  showSubComponents = ShowInstalledSubComponents.state(0);
	
  // get the names of all installed components
  dynComponentNameDps = fwInstallation_getInstalledComponentDps();
  dynComponentNames = dynComponentNameDps;
    
  for ( i = 1; i <= dynlen(dynComponentNames); i++)
  {
    requiredInstalled = true;
    installationNotOK = false;
    dynComponentNames[i] = dpSubStr( dynComponentNames[i], DPSUB_DP );
    strreplace(dynComponentNames[i], "fwInstallation_" , "");
    componentName = dynComponentNames[i];
      
    fwInstallation_updateComponentVersionFormat(componentName);
    dyn_string subcomponents;
    dynClear(subcomponents);
    dpGet(dynComponentNameDps[i] + ".installationNotOK", installationNotOK,
          dynComponentNameDps[i] + ".isItSubComponent", isItSubComponent,
          dynComponentNameDps[i] + ".helpFile", helpFile,
          dynComponentNameDps[i] + ".name", componentName,
          dynComponentNameDps[i] + ".subComponents", subcomponents,
          dynComponentNameDps[i] + ".requiredInstalled", requiredInstalled,
          dynComponentNameDps[i] + ".componentVersionString", componentVersionString);
    
    //check that the sub-components are actually installed. If not, remove them from the list:      
    for(int z = dynlen(subcomponents); z >= 1; z--)
    {
      string ver = "";
      if(!fwInstallation_isComponentInstalled(subcomponents[z], ver)) dynRemove(subcomponents, z);
    }
			
    // if it is the subcomponent
    if(isItSubComponent)
      continue;
    // this is not the sub-component - display it in a graphic table
    if(helpFile != "")
      tblInstalledComponents.appendLine("componentName", componentName, 
                                        "componentVersion", componentVersionString,
                                        "helpFile", "HELP");
    else
      tblInstalledComponents.appendLine("componentName", componentName, "componentVersion", componentVersionString);

    if(installationNotOK)
    {
      setValue("tblInstalledComponents", "cellBackColRC", row, "componentName", "yellow"); 
      ErrorText.visible = TRUE;
      ErrorColor1.visible = TRUE;
    }
      
    // check if the components required by this component are installed
    if(!requiredInstalled)
    {
      setValue("tblInstalledComponents", "cellBackColRC", row, "componentName", "STD_trend_pen6");
      ErrorText2.visible = TRUE;
      ErrorColor2.visible = TRUE;
    }
    ++row;
    

    // show subComponents:
    //are there subcomponent and do they have to be shown?   
    if(showSubComponents && dynlen(subcomponents))
    {
      dynSortAsc(subcomponents);
      //Check which version of the subcomponent is installed
      for(int k = 1; k <= dynlen(subcomponents); k++)
      {
        requiredInstalled = true;
        installationNotOK = false;
        fwInstallation_updateComponentVersionFormat(subcomponents[k]);
        dpGet(fwInstallation_getComponentDp(subcomponents[k]) + ".installationNotOK", installationNotOK,
              fwInstallation_getComponentDp(subcomponents[k]) + ".helpFile", helpFile,
              fwInstallation_getComponentDp(subcomponents[k]) + ".componentVersionString", componentVersionString);
        
        if(helpFile != "")
          tblInstalledComponents.appendLine("componentName", "_"+subcomponents[k], 
                                            "componentVersion", componentVersionString,
                                            "helpFile", "HELP");
        else
          tblInstalledComponents.appendLine("componentName", "_"+subcomponents[k], "componentVersion", componentVersionString);
      
        if(installationNotOK)
        {
          setValue("tblInstalledComponents", "cellBackColRC", row, "componentName", "yellow"); 
          ErrorText.visible = TRUE;
          ErrorColor1.visible = TRUE;
        }
        // check if the components required by this component are installed
        if(!requiredInstalled)
        {
          setValue("tblInstalledComponents", "cellBackColRC", row, "componentName", "STD_trend_pen6");
          ErrorText2.visible = TRUE;
          ErrorColor2.visible = TRUE;
        }          
        ++row;
      }
    }
  }
  return;
}

/** this functions outputs the message into the log textarea of a panel
@param message: the message to be displayed
*/
fwInstallation_showMessage(dyn_string message)
{

	int i, length;
	string isUI = false;
  
	if(myManType() == UI_MAN && shapeExists("list"))
        isUI = true;
 
	length = dynlen(message);
	for (i = 1; i <= length; i++)
	{		
		if(isUI){
		  list.appendItem(message[i]);	
  	  if(logFileName.text != "")
	    {
		    fwInstallation_writeToMainLog(message[i] + "\n");
	    }
	  }//else{
	   // fwInstallation_throw(message[i] + "\n", "INFO", 10);
	  //}
	}
		if(isUI){
	    length = list.itemCount();
	    list.bottomPos(length);
	    list.selectedPos(length);
	  }
}

/** This function executes a script from the component .init file

@param componentInitFile: the .init file with the functions to be executed
@param iReturn: -1 if error calling the script, otherwise, it returns the error code of the user script
@author F. Varela
*/
fwInstallation_evalScriptFile(string componentInitFile , int &iReturn)
{
	string fileInString;
	anytype retVal;
	int result;

  if(access(componentInitFile, R_OK) != 0)	
  {
    fwInstallation_throw("Execution of script: " + componentInitFile + " aborted as the file is not readable");
    iReturn = -1;
    return;
  }
 
	if (!fileToString(componentInitFile, fileInString))
	{
		fwInstallation_throw("fwInstallation: Cannot load " + componentInitFile);
		iReturn =  -1;
   return;
	}
  
  iReturn = evalScript(retVal, fileInString, makeDynString("$value:12345"));
  if(iReturn)
    return;
  
  iReturn = retVal; //Make iReturn equal to the error code returned by the user script
  
  return;  
}


/** This function compares two component versions
  @param installedComponentVersion (in) version name as string of the component installed
  @param requestedComponentVersion (in) required component version
  @param beStrict (in) if set to true, the comparison will required that both component versions as identical
  @return 1 if the required component is equal or older than the version installed, 0 otherwise
*/
int _fwInstallation_CompareVersions(string installedComponentVersion, string requestedComponentVersion, bool beStrict = false)
{
  int result=1;
  int count = 1, minCount;
  dyn_string dsInstalled = strsplit(installedComponentVersion, ".");
  dyn_string dsRequested = strsplit(requestedComponentVersion, ".");
  int request, install;
  bool goOn = true;
  
    
  if(dynlen(dsRequested) <= dynlen(dsInstalled))
    minCount = dynlen(dsRequested);
  else
    minCount = dynlen(dsInstalled);    
  
  if(dynlen(dsInstalled) <= 0)
  {
    result = 0;
    return result;
  }
  else if(dynlen(dsRequested) <= 0)
  {
    result = 1;
    return result;
  }
  
  do
  {
    sscanf(dsInstalled[count], "%d", install);
    sscanf(dsRequested[count], "%d", request);
    
    if(install > request)
    {
      result = 1;   //install is greater than requested
      goOn = false;
      //break;
    }
    else if(install < request) //requested is smaller than installed
    {
      result = 0;
      goOn = false;
      //break;
    }
    ++count;
  }while(count <= minCount && goOn);
  
  if(beStrict && !goOn)
    result = 0;
    
  return result;

}		

/** This function reads the config file and retrieves the list of proj_paths
  @param proj_paths: the return value with a list of proj_paths
  @author M.Sliwinski
*/

int fwInstallation_loadProjPaths(dyn_string & proj_paths)
{
	
	dyn_string parameter_Value;
	dyn_string configLines;
	
	bool fileLoaded = false;
	
	string fileInString;

	string tempLine;
	string tempParameter;
	string tempValue;
	string tempString; 

	string configPath = getPath(CONFIG_REL_PATH);
	string configFile = configPath + "config";
	
	int i, j ;
	
	fileLoaded = fileToString(configFile, fileInString);
	if (! fileLoaded )
	{
	
		Debug("\n Cannot load " + configFile + " file");
		return -1;
	}
	configLines = strsplit(fileInString, "\n");
	
// each line is loaded in a row of dyn_string configLines
	for(i = 1; i <= dynlen(configLines); i++)
	{
		tempLine = strltrim(strrtrim(configLines[i]));
		
		if(tempLine != "")
		{				
				parameter_Value = strsplit(tempLine, "=");
				
				tempParameter = strltrim(strrtrim(parameter_Value[1]));
				
				if(tempParameter == "proj_path")
				{  
				
					tempValue = strltrim(strrtrim(parameter_Value[2]));
				
					strreplace(tempValue, "\"" , "");

				
				  // now value is without quotation marks
					
					dynAppend(proj_paths, tempValue);
				}
		}	
	}		
	return 1;				
}

/** this function deletes the component  files
@param componentFiles: the dyn_string with the names of the files to be deleted
@param installationDirectory: the name of the installation directory
@return 0 if OK, -1 if errors
@author M.Sliwinski and modified by F. Varela
*/

int fwInstallation_deleteFiles(dyn_string & componentFiles, string installationDirectory)
{
	string fileToDelete;
	string cmd;
	string err;
	int x;
	int i;
	string result;
	int iReturn = 0;
	string logFile =  getPath(LOG_REL_PATH) + "InstallationTool.log";
	
	// Deleting the files
	
	for(i = 1; i <= dynlen(componentFiles); i++)
		{
			strreplace( installationDirectory, "//", "/" );
			
			// remove the first dot in file name
			fileToDelete = strltrim(componentFiles[i], ".");
			
//SMS			Debug("\n Deleting installationDir: " + installationDirectory + " file: " + fileToDelete + " - ");
			
			// on windows
			if (_WIN32) 
			{
				strreplace( installationDirectory , "/" , "\\");
				strreplace( fileToDelete , "/" , "\\");


				cmd = "del " +  installationDirectory + fileToDelete +  " 2> " + logFile;
				err = system("cmd /c " + cmd);
				
				if (err != 0)
				{
						fwInstallation_showMessage(makeDynString("Could not delete file " + installationDirectory + fileToDelete));
						iReturn = -1;
				}
			}
			else  // on linux
			{
				cmd = "rm " +  installationDirectory + fileToDelete +  " >> " + logFile;
				err = system(cmd);
				if (err != 0)
				{
						fwInstallation_showMessage(makeDynString("Could not delete file " + installationDirectory + fileToDelete));
						iReturn = -1;
				}
			}
			
//SMS			Debug(err);
			x = fileToString (logFile, result);
			
//SMS			Debug(x);
			
		}
		
		return iReturn;
}

/** This function writes to the main log
@author M.Sliwinski
*/
fwInstallation_writeToMainLog(string message)
{
	file logFile;
	dyn_string tempPaths;
	string tempPath;
	int i;
	
	string fileName = getPath(LOG_REL_PATH) + "/fwInstallation.log";
	
	strreplace(fileName, "\\", "/");

	if( _WIN32 )
	{
		strreplace(fileName, "/", "\\");
		strreplace(tempPath, "/", "\\");
	}

	logFile = fopen(fileName,"a");
	if(ferror(logFile) != 0)
	{
		fwInstallation_throw("fwInstallation: Cannot write to LogFile "+fileName, "error", 4);
	} else {
		fprintf(logFile,"%s\n",message);
	}
	fclose(logFile);
}
/** This function retrieves the path from a full filename
@param filePath (in) full file name (basedir + filename)
@return path to the file
*/
string _fwInstallation_baseDir(string filePath)
{
	string temp_string = filePath;
	dyn_string tempPath = strsplit(temp_string, "/");
	string returnString = "";	
	int i;

	if(dynlen(tempPath) > 1)
	{
		for (i=1; i<dynlen(tempPath); i++)
		{
			temp_string = tempPath[i];
			returnString += temp_string +"/";
		}
	}
	return returnString;
}

/** This function retrieves the name of a file from the full path to the file
@param filePath (in) full file name (basedir + filename)
@return filename as string
*/
string _fwInstallation_fileName(string filePath)
{
	string temp_string = filePath;
	dyn_string tempPath = strsplit(strrtrim(strltrim(temp_string, " "), " "), "/");
	string returnString = "";	
	int i;

	if(dynlen(tempPath) > 0)
	{
		returnString = tempPath[dynlen(tempPath)];
	}
	return returnString;
}


/** This function puts the components to be installed in order in which they should be installed 
The algorithm is similar to that used during deleting the components (see fwInstallation_putComponentsInOrder_Delete() function btn_ApplyDelete()) 
 
@param componentsNames: the names of the components to be installed 
@param componentsVersions: the versions of components to be installed 
@param componentFiles: the file names with the description of the components 
@param componentFilesInOrder: the  file names with the description of the components

@author F. Varela and R. Gomez-Reino
*/
fwInstallation_putComponentsInOrder_Install(dyn_string & componentsNames, 
                                            dyn_string & componentsVersions, 
                                            dyn_string & componentFiles, 
                                            dyn_string & componentFilesInOrder)  
{            
  int k = 1;
  dyn_dyn_string dependecyMatrix;
  dyn_string componentsInOrder;
  dyn_string tempDynRequired;
  for(int i = 1; i <= dynlen(componentFiles); i++)	
  {
     componentFiles[i] = fwInstallationDBAgent_getComponentFile(componentFiles[i]);
     
     fwInstallation_readComponentRequirements(componentFiles[i], tempDynRequired);  
     if(dynlen(tempDynRequired)<=0)
     {
       dynAppend(componentFilesInOrder,componentFiles[i]);
       dynAppend(componentsInOrder,componentsNames[i]);
     }
     else
     {
       dependecyMatrix[k] = makeDynString(componentsNames[i], componentFiles[i]);
       for(int w=1; w<=dynlen(tempDynRequired);w++)
         dynAppend(dependecyMatrix[k],tempDynRequired[w]);
       ++k;
     }
   } 
  while (dynlen(dependecyMatrix)>0){
    dyn_dyn_string remaningMatrix ; 
    remaningMatrix =dependecyMatrix; 
    for (int i=1;i<=dynlen(dependecyMatrix);i++){
      bool skip =false;
      for (int j=3;j<=dynlen(dependecyMatrix[i]);j++){           
        if ((!dynContains(componentsInOrder, substr(dependecyMatrix[i][j],0,strpos(dependecyMatrix[i][j],"=")))) && 
             dynContains(componentsNames, substr(dependecyMatrix[i][j],0,strpos(dependecyMatrix[i][j],"="))))
          skip =TRUE;
      }    
      if(skip == FALSE){
          dynAppend(componentFilesInOrder,dependecyMatrix[i][2]); 
          dynAppend(componentsInOrder,dependecyMatrix[i][1]);
          for(int g=1;g<=dynlen(remaningMatrix);g++){
            if(remaningMatrix[g][1]==dependecyMatrix[i][1])
              dynRemove(remaningMatrix,g);;
          }          
      }
    }
    dependecyMatrix = remaningMatrix;
  }
  
  fwInstallation_throw("Resulting list of components sorted for installation according to their dependencies: " +  componentsInOrder + ". Please wait...", "INFO");
  if(fwInstallationDB_getUseDB() && fwInstallationDB_connect() == 0)
   fwInstallationDB_storeInstallationLog();
  
}

/** This function reads the requirements from the component description file

@param descFile (in) the file with the description of a component 
@param dynRequiredComponents (out) the dyn_string of requiredComponents
@author M.Sliwinski
*/
fwInstallation_readComponentRequirements(string descFile, dyn_string & dynRequiredComponents)
{
	bool	fileLoaded;
	string strComponentFile;
	string tagName;
	string tagValue;
	int i;
        dyn_anytype attribs;
        dyn_string values;

	// clear the required components table
	dynClear(dynRequiredComponents);
	
	if(_WIN32)
	{
		strreplace(descFile, "/", "\\");
	}	
	// load the description file into strComponentFile string
        if(fwInstallationXml_getTag(descFile, "required", dynRequiredComponents, attribs))
        {
          fwInstallation_throw("fwInstallation_readComponentRequirements() -> Cannot load " + descFile + " file ", "error", 4);
          return;
        }
		
}

/** This function resolves the Pmon Information (i.e. user name and password)
  @param user (out) user 
  @param pwd (out) password
  @return 0 if OK, -1 if errors.
*/
int fwInstallation_getPmonInfo(string &user, string &pwd)
{
  dyn_float df;
  dyn_string ds;
  dyn_mixed projectProperties;
  int projectId;
  
  //Cache Segment
    bool isProjectRegisteredCache = false;
    string dbCacheProjectUser = "";         
    string dbCacheProjectPassword = "";     
    dyn_mixed dbProjectInfo;                
    if( globalExists("gDbCache") && mappingHasKey(gDbCache, "dbProjectInfo") ) { 
       dbProjectInfo = gDbCache["dbProjectInfo"];                               
       if( dynlen(dbProjectInfo) > 1 ) {                                       
         isProjectRegisteredCache = true;                                      
         dbCacheProjectUser = dbProjectInfo[FW_INSTALLATION_DB_PROJECT_PMON_USER];
         dbCacheProjectPassword = dbProjectInfo[FW_INSTALLATION_DB_PROJECT_PMON_PWD];
       }                                                                       
     }                                                                         
  //End Cache segment                                                       
                                                                               
  
  //Check if password can be read from the DB
  if(gFwInstallationPmonUser != "N/A" && gFwInstallationPmonPwd != "N/A")   //nothing to be done. Globals have already been initialized
  {
    user = gFwInstallationPmonUser;
    pwd = gFwInstallationPmonPwd;    
    return 0;
  }
  
  if(!fwInstallation_isPmonProtected())
  {
    //Nothing to be done; Return empty strings
    user = "";
    pwd = "";
  }
  else if(fwInstallationDB_getUseDB() && fwInstallationDB_connect() == 0)
  {
    if( isProjectRegisteredCache ) {
      user = dbCacheProjectUser;
      password = dbCacheProjectPassword;
    } else {
      if(fwInstallationDB_isProjectRegistered(projectId, PROJ, strtoupper(fwInstallation_getHostname())))
      {
        fwInstallation_throw("fwInstallation_getPmonInfo() -> Could not access the DB to read the PMON info. Failed to check if the project is registered in the System Configuration DB", "error", 7);
        gFwInstallationPmonUser = "N/A";
        gFwInstallationPmonPwd = "N/A";
        return -1;
      }
      else if(projectId == -1)
      {
        if(myManType() != UI_MAN)
        {
          fwInstallation_throw("fwInstallation_getPmonInfo() -> Project not yet registered in the DB. Cannot resolve the pmon parameters from the System Configuration DB", "warning", 10);
          gFwInstallationPmonUser = "N/A";
          gFwInstallationPmonPwd = "N/A";
          return -1;
        }
        else
        {
          fwInstallation_throw("Prompting user to enter PMON info", "INFO", 10);
          int err = fwInstallation_askForPmonInfo(user, pwd);
          gFwInstallationPmonUser = user;
          gFwInstallationPmonPwd = pwd;
          return err;
        }
      }
      else if(fwInstallationDB_getProjectProperties(PROJ, strtoupper(fwInstallation_getHostname()), projectProperties, projectId))
      {
        fwInstallation_throw("fwInstallation_getPmonInfo() -> Could not access the DB to read the PMON info", "error", 7);
        gFwInstallationPmonUser = "N/A";
        gFwInstallationPmonPwd = "N/A";
        return -1;
      }
    
      user = projectProperties[FW_INSTALLATION_DB_PROJECT_PMON_USER];
      pwd = projectProperties[FW_INSTALLATION_DB_PROJECT_PMON_PWD];    
     }
  } 
  else if(myManType() == UI_MAN)
  {
    fwInstallation_askForPmonInfo(user, pwd);
  }
  else
  {
    fwInstallation_throw("Could not resolve pmon username/password");
    user = "N/A";
    pwd = "N/A";
    gFwInstallationPmonUser = "N/A";
    gFwInstallationPmonPwd = "N/A";
    return -1;
  }
  
  gFwInstallationPmonUser = user;
  gFwInstallationPmonPwd = pwd;

  return 0; 
}      

int fwInstallation_askForPmonInfo(string &user, string &pwd)
{
  dyn_string ds;
  dyn_float df;
  ChildPanelOnCentralReturn("fwInstallation/fwInstallation_pmon.pnl", "Username/Password required", makeDynString(""), df, ds);
  if(!dynlen(df) || df[1] != 1.)
  {
    user = "N/A";
    pwd = "N/A";
//    gFwInstallationPmonUser = "N/A";
//    gFwInstallationPmonPwd = "N/A";
    return -1;
  }
  else
  {
    user = ds[1];
    pwd = ds[2];
  }
  
  return 0;
}

/** This function forces the restart of the whole project
@author F. Varela
*/
int fwInstallation_forceProjectRestart()
{
  string host;
  int port;
  int iErr = paGetProjHostPort(paGetProjName(), host, port);
  string cmd;              
  string user, pwd;
  string dpr = fwInstallation_getAgentRequestsDp();

  
  //Try to use first pmon without user and password and see if it fails:
  if(!fwInstallation_isPmonProtected())
  {
    cmd = "##RESTART_ALL:";
    if(!pmon_command(cmd, host, port, FALSE, TRUE))
    {
      fwInstallation_throw("FW Installation Tool forcing project restart", "INFO", 10);
      //Project successfully restarted. We are done
      return 0;
    }
  }
  
  //Pmon does have a username and password. Try to resolve them on the fly.
  fwInstallation_getPmonInfo(user, pwd);       
  cmd = user + "#" + pwd + "#" + "RESTART_ALL:";    
  
  paVerifyPassword(PROJ, user, pwd, iErr);
  if(iErr)
  {
    fwInstallation_throw("Invalid Pmon Username/Password. Cannot restart the project", "WARNING", 6);
    return -1;
  }
  
  if(pmon_command(cmd, host, port, FALSE, TRUE))
  {
    fwInstallation_throw("Cannot restart the project", "WARNING");
    return -1;
  }

  fwInstallation_throw("FW Installation Tool forcing project restart", "INFO", 10);
  return 0;          
}


/** This function resolves the source path from the component description file
  @param componentFile (out) full path to the XML file of the component 
  @return source directory
*/
string fwInstallation_getComponentPath(string componentFile)
{  
  string path = "";
  dyn_string ds;
  int len = strlen(componentFile);

  if(componentFile == "")
    return "";
  
  ds = strsplit(componentFile, "/");
  strreplace(componentFile, ds[dynlen(ds)], "");
  path = componentFile;

  return path;
}

/** This function retrieves whether the component can be registered only 
    or if all component files have to be copied during installation
  @param destinationDir (in) target directory for installation. 
                         Note that a previous installtion of the component may exist in there.
  @param componentName (in) name of the component being installed
  @param forceOverwriteFiles (in) flag to force overwriting of existing files
  @param isSilent (in) flag to specify if the installation is silent (no windows will be pop up even during interactive installation)
  @return 0 if OK, -1 if error.
*/
int fwInstallation_getRegisterOnly(string destinationDir, 
                                   string componentName, 
                                   bool forceOverwriteFiles, 
                                   bool isSilent)
{
  int registerOnly = 0;
  string installedVersion;
  dyn_string ds;
  dyn_float df;
  
  if(fwInstallationDB_getUseDB() && fwInstallationDB_getCentrallyManaged() && !forceOverwriteFiles && fwInstallation_checkTargetDirectory(destinationDir, componentName, installedVersion))
  {
    registerOnly = 1; 
  }                            
  else if(!gFwYesToAll && fwInstallation_checkTargetDirectory(destinationDir, componentName, installedVersion) && !forceOverwriteFiles)
  {
   if(!isSilent){
     if(myManType() == UI_MAN)
  	   ChildPanelOnCentralReturn("fwInstallation/fwInstallation_messageInfo3", "Warning", makeDynString("$1:A previous installation (v." + installedVersion + ") of the component:\n" + componentName + " exists in the destination directory.\nDo you want to overwrite the files?"), df, ds); 
     
      if(df[1] < 0.){
         fwInstallation_throw("fwInstallation_getRegisterOnly() -> Installation of " + componentName + " aborted by the user.", "INFO");
         return -1;
      }else if(df[1] == 1.){
	        fwInstallation_throw("fwInstallation_getRegisterOnly() -> Overwriting files of component" + componentName + " in directory " + destinationDir, "INFO");
         registerOnly = 0;
      }else if(df[1] == 0.){
         fwInstallation_throw("INFO: fwInstallation_getRegisterOnly() -> Registering component " + componentName + " only. Not copying files...", "INFO");
         registerOnly = 1;
         }else{
           gFwYesToAll = 1;
         }
     
      } else{
          fwInstallation_throw("fwInstallation_getRegisterOnly() -> Registering component " + componentName + " only. Not copying files...", "INFO");
          registerOnly = 1;
      }
  }
  else if(fwInstallation_isComponentInstalled(componentName, installedVersion))
  {
    string previousDir = fwInstallation_getComponentPath(componentName);
     if(destinationDir != previousDir)
     {
       if(!isSilent)
       {
         if(myManType() == UI_MAN)
         {
          	ChildPanelOnCentralReturn("fwInstallation/fwInstallation_messageInfo3", "Warning", makeDynString("$1:A previous installation (v." + installedVersion + ") of the component:\n" + componentName + " was previously installed in a different path.\nAre you sure you want to proceed?"), df, ds); 
           if(df[1] <= 0.)
           {
             fwInstallation_throw("fwInstallation_getRegisterOnly() -> Installation of " + componentName + " aborted by the user.", "INFO");
             return -1;
           }
           else if(df[1] > 0)
           {
  	          fwInstallation_throw("fwInstallation_getRegisterOnly() -> Installing component " + componentName + " in a new directory: " + destinationDir, "INFO");
             registerOnly = 0;
           }
           else
           {
             gFwYesToAll = 1;
           }
        }
      }
    }
  }
  else
    registerOnly = 0;

  return registerOnly;
}

/** This function forces all required components to be installed prior to the installation of a given component if available in the distribution
 @param componentName (in) name of the component being installed
 @param dynRequiredComponents (in) array of required components
 @param sourceDir (in) source directory for installation
 @param forceInstallRequired (in) flag to force installation of required components
 @param forceOverwriteFiles (in) flag to force all existing files to be overwritten
 @param isSilent (in) flag to define if the installation is silent, i.e. no pop-ups
 @param requiredInstalled (out) returned argument indicating if the required components have been successfully installed or not
 @param actionAborted (out) flag that indicates if the action was aborted by the user
 @return 0 if OK, -1 if errors
*/
int fwInstallation_installRequiredComponents(string componentName, 
                                             dyn_string dynRequiredComponents, 
                                             string sourceDir, 
                                             bool forceInstallRequired, 
                                             bool forceOverwriteFiles, 
                                             bool isSilent, 
                                             int & requiredInstalled, 
                                             bool &actionAborted)
{
  string strNotInstalledNames = "";
  dyn_string dsNotInstalledComponents, dsFileComponentName, dsFileComponentVersion, dsFileComponent;
  dyn_string dreturns;
  dyn_string dreturnf;
  string componentPath;
  
  actionAborted = false;
  
  fwInstallation_getNotInstalledComponentsFromRequiredComponents(dynRequiredComponents, strNotInstalledNames);
	
  // show the panel that asks if it should be installed
  if( strNotInstalledNames != "")
  {
    fwInstallation_throw("Missing at installation of "+componentName+ ": " + strNotInstalledNames, "info", 10);
      
    //If all components are available proceed with the installation otherwise cancel installation of dependent components by claering the arrays
    dsNotInstalledComponents = strsplit(strNotInstalledNames, "|");
    
    fwInstallation_checkDistribution(sourceDir, dsNotInstalledComponents, dsFileComponentName, dsFileComponentVersion, dsFileComponent);
		
    //FVR: Check the forceInstallRequired flag is not set:
    if(!forceInstallRequired)
    {
      // show the panel informing the user about broken dependencies
      if(myManType() == UI_MAN)
        ChildPanelOnCentralReturn("fwInstallation/fwInstallationDependency.pnl", "fwInstallation_Dependency",
	                          makeDynString("$strDependentNames:" + strNotInstalledNames , "$componentName:" + componentName, "$callingPanel:" + "ToInstall", "$fileComponentName:" + dsFileComponentName, "$fileComponentVersion:" + dsFileComponentVersion), dreturnf, dreturns);
      else
        dreturns[1] = "Install_Delete"; //Force installation of this component

      // check the return value
      if(dreturns[1] == "Install_Delete")
      {
	      requiredInstalled = false;
	      fwInstallation_showMessage(makeDynString("User choice at installation of "+componentName+": INSTALL"));
      }
      else if(dreturns[1] == "DoNotInstall_DoNotDelete")
      {
	      fwInstallation_showMessage(makeDynString("User choice at installation of "+componentName+": ABORT"));
        actionAborted = true;
	      return gFwInstallationOK;
      }
      else if(dreturns[1] == "InstallAll_DeleteAll"){  
        forceInstallRequired = true;     //FVR: 30/03/2006: Install all required components
      }
    }

   //Check if flag is now true -> Need of another if since the value of the flag could have changed in the previous loop
   if(forceInstallRequired){
     for(int kk = 1; kk <= dynlen(dsFileComponentName); kk++)
     {
       componentPath = fwInstallation_getComponentPath(dsFileComponent[kk]);
       string componentSubPath = substr(componentPath, strlen(sourceDir));
       bool componentInstalled = false;
       string dontRestartProject = "no";
       fwInstallation_throw("Forcing installation of the required component: " + dsFileComponentName[kk] + " v." + dsFileComponentVersion[kk]);
       if(fwInstallation_installComponent(dsFileComponent[kk], 
                                          sourceDir, 
                                          false, 
                                          dsFileComponentName[kk], 
                                          componentInstalled, 
                                          dontRestartProject,
                                          componentSubPath, 
                                          forceInstallRequired, 
                                          forceOverwriteFiles, 
                                          isSilent) == gFwInstallationError && isSilent)
       {
         fwInstallation_showMessage(makeDynString("ERROR: Silent installation failed installing dependent component: " + componentName)); 
         fwInstallation_throw("Silent installation failed installing dependent component: " + componentName); 
         string dp = fwInstallation_getComponentDp(dsFileComponentName[kk]);
         
         dpSet(dp + ".installationNotOK", false);
	       return gFwInstallationError;
       }
      }
     }
   }  // end check the component dependencies

  return 0; 
}

/** This function checks the syntax of a component script
 @param sourceDir (in) source directory for installation
 @param subPath (in) path to the appended to the source directory
 @param script name of the script to be tested
 @return 0 if OK, -1 if errors
*/
int fwInstallation_checkScript(string sourceDir, string subPath, string script)
{
  string strTestFile;
  if (!fileToString(sourceDir + subPath + script, strTestFile))
  {
    fwInstallation_throw("fwInstallation: init script "+ sourceDir + subPath + script + " cannot be loaded", "WARNING", 10);
    return -1;
  } 
  else 
  {  
    if(!checkScript(strTestFile))
    {
      fwInstallation_throw("fwInstallation: init script "+ sourceDir + subPath + script + " is not valid", "WARNING", 10);
      return -1;
    }
  }
  
  return 0;
}


/** This function verifies the integrity of a package
 @param sourceDir (in) source directory for installation
 @param subPath (in) path to be appended to the sourceDir
 @param componentName (in) name of the component being installed
 @param destinationDir (in) target directory for installation
 @param registerOnly (in) flag indicating whether file copying can be avoided or not if the files already exist
 @param dynInitFiles (in) component init scripts
 @param dynPostInstallFiles (in) component init scripts
 @param dynInitFiles (in) component post-install scripts
 @param dynDeleteFiles (in) component delete scripts
 @param dynPostDeleteFiles (in) component post-delete scripts
 @param dynFileNames (in) component files
 @param isSilent (in) flag to define if the installation is silent, i.e. no pop-ups
 @param actionAborted (out) flag that indicates if the action was aborted by the user
 @return 0 if OK, -1 if error
*/
int fwInstallation_verifyPackage(string sourceDir, 
                                 string subPath,
                                 string componentName,
				                           string destinationDir,
                                 bool registerOnly, 
                                 dyn_string dynInitFiles, 
                                 dyn_string dynPostInstallFiles, 
                                 dyn_string dynDeleteFiles,
                                 dyn_string dynPostDeleteFiles,
                                 dyn_string dynFileNames,
                                 int isSilent,
                                 bool &actionAborted)
{
  int errorCounter = 0;	
  string strTestFile;
  bool fileLoaded;
  string errorString;
  dyn_string strErrors;
  dyn_string dreturns;
  dyn_float dreturnf;
  int error;
  int k = 1;
  
  actionAborted = false;

  for (k=1; k<=dynlen(dynInitFiles); k++)
  {
    if(fwInstallation_checkScript(sourceDir, subPath, dynInitFiles[k]) < 0)
    {
     dynAppend(strErrors, "The init script " + dynFileNames[k] +" cannot be load. Check its syntax!");
     errorCounter++;
   }
  }

  for (k=1; k<=dynlen(dynPostInstallFiles); k++)
  {
    if(fwInstallation_checkScript(sourceDir, subPath, dynPostInstallFiles[k]) < 0)
    {
     dynAppend(strErrors, "The post-install script " + dynFileNames[k] +" cannot be load. Check its syntax!");
     errorCounter++;
   }
  }
  
  for (k=1; k<=dynlen(dynDeleteFiles); k++)
  {
    if(fwInstallation_checkScript(sourceDir, subPath, dynDeleteFiles[k]) < 0)
    {
      dynAppend(strErrors, "The delete script " + dynFileNames[k] +" cannot be load. Check its syntax!");      
      errorCounter++;
    }
  }

  for (k=1; k<=dynlen(dynPostDeleteFiles); k++)
  {
    if(fwInstallation_checkScript(sourceDir, subPath, dynPostDeleteFiles[k]) < 0)
    {
      errorCounter++;
      dynAppend(strErrors, "The delete script " + dynFileNames[k] +" cannot be load. Check its syntax!");      
    }     
  }

  error = access(destinationDir,W_OK);
  if(error!=0 && !registerOnly)
  {
    errorCounter++;
    dynAppend(strErrors, "The folder "+ destinationDir +" is not write enabled");      
    fwInstallation_throw("fwInstallation: the folder "+ destinationDir +" is not write enabled");
  } 
  

  for (k=1; k<=dynlen(dynFileNames); k++)
  {
    if(access(sourceDir + subPath+ "/" + dynFileNames[k],R_OK) != 0)
    {
      errorCounter++;
      dynAppend(strErrors, "The file "+ sourceDir+ subPath + "/" + dynFileNames[k] +" does not exist");
      fwInstallation_throw("The file "+ sourceDir+ subPath + "/" + dynFileNames[k] +" does not exist", "WARNING");
    }
  }

  string dp = fwInstallation_getComponentDp(componentName);

  if(errorCounter!=0)
  {
    if(!isSilent)
    {
      if(myManType() == UI_MAN)
        ChildPanelOnCentralReturn("fwInstallation/fwInstallationDependency.pnl", "fwInstallation_Dependency",
                                  makeDynString("$strDependentNames:" + strErrors , "$componentName:" + componentName, "$callingPanel:" + "Checker"), dreturnf, dreturns);
       else
          dreturns[1] = "Install_Delete";
       
        // check the return value
       if(dreturns[1] == "Install_Delete")
       {
         fwInstallation_throw("fwInstallation: "+errorCounter+" error(s) found. Installation of "+componentName+" will continue on user request", "WARNING", 10);
         return gFwInstallationError; 
       }
       else if(dreturns[1] == "DoNotInstall_DoNotDelete")
       {
        fwInstallation_throw("fwInstallation: "+errorCounter+" error(s) found. Installation of "+componentName+" is aborted", "INFO");
        actionAborted = true;
        return gFwInstallationOK;
      }
    }
    else
    {
      fwInstallation_throw("fwInstallation: "+errorCounter+" error(s) found. Silent installation of "+componentName+" is aborted");
      actionAborted = true;
      return gFwInstallationError;          
    }
  }
  
  return 0;
}

/** This function copies all component files
 @param componentName (in) name of the component being installed
 @param sourceDir (in) source directory for installation
 @param subPath (in) path to be appended to the sourceDir
 @param destinationDir (in) target directory for installation
 @param dynFileNames (in) component files
 @param registerOnly (in) flag indicating whether file copying can be avoided or not if the files already exist
 @param isSilent (in) flag to define if the installation is silent, i.e. no pop-ups
 @return 0 if OK, -1 if error
*/
int fwInstallation_copyComponentFiles(string componentName, 
                                      string sourceDir, 
                                      string subPath, 
                                      string destinationDir, 
                                      dyn_string dynFileNames, 
                                      bool registerOnly, 
                                      bool isSilent)
{
  string fileToCopy;
  int i;
  int errorCounter;
  string errorString;
  int fileCopied;
  int errorInstallingComponent = 1; // has value -1 if there were any errors during the component installation, 1 if everything is OK

  string dp = fwInstallation_getComponentDp(componentName);
  
  if(sourceDir != destinationDir)
  {
    if(dynlen(dynFileNames) > 0)
      fwInstallation_showMessage(makeDynString("    Copying files ...."));
    
    for (i =1; i <= dynlen(dynFileNames); i++)
    {
      //strreplace( destinationDir, "//", "/" );
      //strreplace( sourceDir, "//", "/" );
      
      fileToCopy = strltrim(dynFileNames[i], ".");
      
      if(!registerOnly){
        fileCopied =  fwInstallation_copyFile(sourceDir+ subPath + fileToCopy, destinationDir + fileToCopy);
      }
      
      if(fileCopied != 0 && !registerOnly) 
      {
        fwInstallation_throw("Error copying file - source: " + sourceDir+ subPath + fileToCopy + " destination: " + destinationDir + fileToCopy, "error", 4);
        fwInstallation_showMessage(makeDynString("      Error copying file: " + fileToCopy));
        if(dpExists(dp + ".installationNotOK")) dpSet(dp + ".installationNotOK", true);
        return -1;
      }
    }
  }
  return 0;
}

/** This function imports the dpl files of a component
 @param componentName (in) name of the component being installed
 @param sourceDir (in) source directory for installation
 @param subPath (in) path to be appended to the sourceDir
 @param dynDplistFiles (in) list of dpl files to be imported
 @param updateTypes (in) flag to indicate if existing types have to be updated or not
 @return 0 if OK, -1 if error
*/
int fwInstallation_importComponentAsciiFiles(string componentName, 
                                             string sourceDir, 
                                             string subPath, 
                                             dyn_string dynDplistFiles, 
                                             bool updateTypes = true)
{
  string fileToCopy;
  string asciiFile;
  string cmd;
  string infoFile = getPath(LOG_REL_PATH) + fwInstallation_getWCCOAExecutable("ascii") + "_info.log";
  string logFile =  getPath(LOG_REL_PATH) + fwInstallation_getWCCOAExecutable("ascii") + "_log.log";
  int err;
  int errorInstallingComponent = 0;
  string result;
  dyn_string resultInLines;  
  int i = 1;
  string dplistFile;
  string asciiManager = PVSS_BIN_PATH + fwInstallation_getWCCOAExecutable("ascii");
  
  string dp = fwInstallation_getComponentDp(componentName);
  
  for( i = 1; i <= dynlen(dynDplistFiles); i++)
  {	
    dplistFile = dynDplistFiles[i];
    fwInstallation_throw("Importing dplist file: " + dplistFile, "INFO");
    fileToCopy = strltrim(dplistFile, ".");
    asciiFile = sourceDir+ subPath + fileToCopy;
    
    if(asciiFile == "")
    {
      fwInstallation_throw("fwInstallation_importComponentAsciiFiles() -> Empty ASCII file name passed for component: " + componentName);
								 
      dpSet(dp + ".installationNotOK", true);
      return gFwInstallationError;
    }
    else
    {
      if(updateTypes)
      {
        fwInstallation_throw("Calling ASCII manager with DP-Type update option", "INFO", 10);
        cmd = asciiManager + " -in \"" + asciiFile + "\" -yes -log +stderr -log -file > " + infoFile + " 2> " + logFile;
      }
      else
      {
        fwInstallation_throw("Calling ASCII manager with NO DP-Type update option", "INFO", 10);
        cmd = asciiManager + " -in \"" + asciiFile + "\" -log +stderr -log -file > " + infoFile + " 2> " + logFile;
      }

      if (_WIN32) 
      {
        err = system("cmd /c " + cmd);
      }
      else  //LIN
      {
        err = system(cmd);
      }
      if (err != 0  && 
          err != 55 && 
          err != 58 &&
          err != 56)
      {
        fwInstallation_throw("Could not import properly the file " + asciiFile + " (Error number = " + err +")");
        errorInstallingComponent = -1;
      }
      else if(err > 0)
      {
        fwInstallation_throw("Warnings while importing the dpl file " + asciiFile + " (Error number = " + err +"). Find details in PROJ_PATH/log/" + fwInstallation_getWCCOAExecutable("ascii") + ".log. The installation will proceed anyway...", "WARNING", 10);
      }
      
      // Show result of the import of the current file in the log text field
      fileToString (logFile, result);
      resultInLines = strsplit (result, "\n");
      fwInstallation_showMessage(resultInLines);
    }
    fwInstallation_showMessage(makeDynString(""));
  }
  
  if(errorInstallingComponent == -1)
    return -1;
  
  return 0;
}

/** This function imports the dpl files of a component
 @param componentName (in) name of the component being installed
 @param sourceDir (in) source directory for installation
 @param subPath (in) path to be appended to the sourceDir
 @param dynConfigFiles_general (in) list of dpl files to be imported
 @param dynConfigFiles_linux (in) list of dpl files to be imported (linux only)
 @param dynConfigFiles_windows (in) list of dpl files to be imported (windows only)
 @return 0 if OK, -1 if error
*/
int fwInstallation_importConfigFiles(string componentName, 
                                     string sourceDir, 
                                     string subPath,
                                     dyn_string dynConfigFiles_general, 
                                     dyn_string dynConfigFiles_linux, 
                                     dyn_string dynConfigFiles_windows)
{
  int i = 1;
  string componentConfigFile;
  
  for(i = 1; i <= dynlen(dynConfigFiles_linux); i++)
  {
    if(! _WIN32)
    {
      fwInstallation_showMessage(makeDynString("    Importing linux config file ... "));
      componentConfigFile = sourceDir+ subPath + strltrim(dynConfigFiles_linux[i], ".");
      fwInstallation_AddComponentIntoConfig( componentConfigFile,  componentName);
    }
  }
// end import config files for linux

// import config files for windows

  for(i = 1; i <= dynlen(dynConfigFiles_windows); i++)
  {
    if(_WIN32)
    {
      fwInstallation_showMessage(makeDynString("    Importing windows config file ... "));
      componentConfigFile = sourceDir+ subPath + strltrim(dynConfigFiles_windows[i], ".");
      fwInstallation_AddComponentIntoConfig( componentConfigFile,  componentName);
    }
  }
// end import config files for windows
		
// import config files
  if(dynlen(dynConfigFiles_general) > 0)
    fwInstallation_throw("Importing general config file ... ", "INFO");
  
  for(i = 1; i <= dynlen(dynConfigFiles_general); i++)
  {
    componentConfigFile = sourceDir+ subPath + strltrim(dynConfigFiles_general[i], ".");
    fwInstallation_AddComponentIntoConfig( componentConfigFile,  componentName);
  }
  
  return 0;
}


/** This function executes the component init scripts
 @param componentName (in) name of the component being installed
 @param sourceDir (in) source directory for installation
 @param subPath (in) path to be appended to the sourceDir
 @param dynInitFiles (in) list of init files to be executed
 @param isSilent (in) flag to define if the installation is silent, i.e. no pop-ups
 @return 0 if OK, -1 if error
*/
int fwInstallation_executeComponentInitScripts(string componentName, 
                                               string sourceDir, 
                                               string subPath, 
                                               dyn_string dynInitFiles, 
                                               int isSilent)
{
  int i;
  string componentInitFile;
  int iReturn;
  
  for(i =1; i <= dynlen(dynInitFiles); i++)
  {
    componentInitFile = sourceDir + subPath+ strltrim(dynInitFiles[i], ".");
    fwInstallation_throw("Executing the init file : " + componentInitFile, "INFO");
	
    // read the file and execute it
    fwInstallation_evalScriptFile(componentInitFile , iReturn);
    if(iReturn == -1)
    {
      fwInstallation_throw("Error executing script: " + componentInitFile);
      return -1;
    }
  }
  return 0; 
}

/** This function stores in the component internal dp of the installation tool the list of post install scripts to be run
 @param dynPostInstallFiles_current (in) list of post-install files to be stored
 @return 0 if OK, -1 if error
*/
int fwInstallation_storeComponentPostInstallScripts(dyn_string dynPostInstallFiles_current)
{
  dyn_string dynPostInstallFiles_all;
  string dp = fwInstallation_getInstallationDp();

  dpGet(dp + ".postInstallFiles", dynPostInstallFiles_all);
  dynAppend(dynPostInstallFiles_all, dynPostInstallFiles_current); 
  dpSet(dp + ".postInstallFiles", dynPostInstallFiles_all);			
  
  return 0;
}

/** This function creates the internal dp for the installed component
 @param componentName (in) name of the component being installed
 @param componentVersion (in) component version
 @param descFile (in) component description file
 @param isItSubComponent (in) component description file
 @param sourceDir (in) source directory for installation
 @param date (in) source directory for installation
 @param helpFile (in) source directory for installation
 @param destinationDir (in) source directory for installation
 @param dynComponentFiles (in) source directory for installation
 @param dynConfigFiles_general (in) list of dpl files to be imported
 @param dynConfigFiles_linux (in) list of dpl files to be imported (linux only)
 @param dynConfigFiles_windows (in) list of dpl files to be imported (windows only)
 @param dynInitFiles (in) list of init scripts
 @param dynPostInstallFiles (in) list of post install scritps
 @param dynDeleteFiles (in) list of delete scripts
 @param dynPostDeleteFiles (in) list of post-delete scripts
 @param dynDplistFiles (in) list of dpl files
 @param dynRequiredComponents (in) list of required components
 @param dynSubComponents (in) list of subcomponents
 @param dynScriptsToBeAdded (in) list of scritps
 @param requiredInstalled (in) flag to indicated if the required component were installed
 @param comments (in) component comments
 @param description (in) component description
 @return 0 if OK, -1 if error
*/
int fwInstallation_createComponentInternalDp(string componentName, string componentVersion, 
                                             string descFile, int isItSubComponent, 
                                             string sourceDir, string date, 
                                             string helpFile, string destinationDir,
                                             dyn_string dynComponentFiles, dyn_string dynConfigFiles_general, 
                                             dyn_string dynConfigFiles_linux, dyn_string dynConfigFiles_windows,
                                             dyn_string dynInitFiles, dyn_string dynPostInstallFiles, 
                                             dyn_string dynDeleteFiles, dyn_string dynPostDeleteFiles,
                                             dyn_string dynDplistFiles,
                                             dyn_string dynRequiredComponents, dyn_string dynSubComponents, 
                                             dyn_string dynScriptsToBeAdded, int requiredInstalled, 
                                             dyn_string comments,
                                             string description)
{
  // save the component info into the PVSS database
  fwInstallation_throw("Saving the component info into the database: " + componentName + " v." + componentVersion, "INFO");
  string dp = fwInstallation_getComponentDp(componentName);
  
  if (dpCreate(dp, "_FwInstallationComponents") == 0 )
  {
    dpSet(dp + ".componentVersion", componentVersion,
          dp + ".componentVersionString", componentVersion,
          dp + ".descFile", descFile,
          dp + ".sourceDir", sourceDir,
          dp + ".installationDirectory", destinationDir,
          dp + ".date", date,
          dp + ".helpFile", helpFile,
          dp + ".componentFiles", dynComponentFiles,
          dp + ".configFiles.configGeneral", dynConfigFiles_general,
          dp + ".configFiles.configLinux", dynConfigFiles_linux,
          dp + ".configFiles.configWindows", dynConfigFiles_windows,
          dp + ".initFiles", dynInitFiles,
          dp + ".postInstallFiles", dynPostInstallFiles,
          dp + ".deleteFiles", dynDeleteFiles,
          dp + ".postDeleteFiles", dynPostDeleteFiles,
          dp + ".dplistFiles", dynDplistFiles,
          dp + ".requiredComponents", dynRequiredComponents,
          dp + ".requiredInstalled", requiredInstalled,
          dp + ".subComponents", dynSubComponents,
          dp + ".isItSubComponent", isItSubComponent,
          dp + ".scriptFiles", dynScriptsToBeAdded,
          dp + ".comments", comments,
          dp + ".description", description,
          dp + ".name", componentName);
  }
  else
  {
    fwInstallation_showMessage(makeDynString("    ERROR: The information cannot be saved into the database "));
    fwInstallation_writeToMainLog(formatTime("[%Y-%m-%d_%H:%M:%S] ",getCurrentTime()) + componentName + " " + componentVersion + " installed with errors");
    fwInstallation_showMessage(makeDynString("    Component installed with errors - check the log."));
    dpSet(dp + ".requiredInstalled:_original.._value", false);
    dpSet(dp + ".installationNotOK", true);
    return -1;
  }
  
  return 0;
}

/** This function checks if there is any dependency broken among the installed components 
 *  and sets the values of the internal dps accordingly
 @return 0 (error code not yet implemented)
*/
int fwInstallation_checkComponentBrokenDependencies()
{
  dyn_string dynNotProperlyInstalled;
  dyn_string dynRequiredComponents;
  dyn_string dynSubComponents;
  string strNotInstalledNames;
  int i = 1;
  string str = "";
  
  if(myReduHostNum() > 1)
    str = "_" + myReduHostNum();
  
  //fwInstallation_getListOfNotProperlyInstalledComponents(dynNotProperlyInstalled);
  dyn_string dps = fwInstallation_getInstalledComponentDps();
  
  for(i = 1; i <= dynlen(dps); i++)
  {
    strNotInstalledNames = "";
    dynClear(dynRequiredComponents);
    dynClear(dynSubComponents);
    dpGet(dps[i] + ".requiredComponents", dynRequiredComponents,
          dps[i] + ".subComponents", dynSubComponents);    
    fwInstallation_getNotInstalledComponentsFromRequiredComponents(dynRequiredComponents, strNotInstalledNames);
    if(strNotInstalledNames == "")
    {
      dpSet(dps[i] + ".requiredInstalled", true);
    }
    else
    {
      dpSet(dps[i] + ".requiredInstalled", false);
      continue;
    }
    
    strNotInstalledNames = "";
    fwInstallation_getNotInstalledComponentsFromRequiredComponents(dynSubComponents, strNotInstalledNames);
    if(strNotInstalledNames == "")
    {
      dpSet(dps[i] + ".requiredInstalled", true);
    }
    else
    {
      dpSet(dps[i] + ".requiredInstalled", false);
      continue;
    }
  }
  
  return 0;
}


/*
int fwInstallation_checkComponentBrokenDependencies()
{
  dyn_string dynNotProperlyInstalled;
  dyn_string dynRequiredComponents;
  string strNotInstalledNames;
  int i = 1;
  string str = "";
  
  if(myReduHostNum() > 1)
    str = "_" + myReduHostNum();
  
  fwInstallation_getListOfNotProperlyInstalledComponents(dynNotProperlyInstalled);
  
  for(i = 1; i <= dynlen(dynNotProperlyInstalled); i++)
  {
    dynClear(dynRequiredComponents);
    string dp = fwInstallation_getComponentDp(dynNotProperlyInstalled[i]);
    //dpGet(dp + ".requiredComponents", dynRequiredComponents);
    
    dpGet(dynNotProperlyInstalled[i] + ".requiredComponents", dynRequiredComponents);    
    
    fwInstallation_getNotInstalledComponentsFromRequiredComponents(dynRequiredComponents, strNotInstalledNames);
    
    if(strNotInstalledNames == "")
      dpSet(dynNotProperlyInstalled[i] + ".requiredInstalled", true);
//      dpSet(dp + ".requiredInstalled", true);
  }
  
  return 0;
}
*/
string fwInstallation_getComponentName(string filename)
{
  string component = filename;
  strreplace(component, fwInstallation_getComponentPath(component), "");
  strreplace(component, ".xml", "");
  
  return component;
}
/** This function installs the component. It copies the files, imports the component DPs, DPTs, updates the project config file

@param descFile: the file with the description of a component 
@param sourceDir: the root directory with the component files
@param isItSubComponent: it is false - if it is the master component; it is true if it is the sub component
@param componentName: it is the return value - the name of the installed component
@param componentInstalled: set to 1 if the component is properly installed
@param dontRestartProject: indicates whether the project has to be restarted after installations or not
@param subPath: path to be appended to the source directory
@param forceInstallRequired this flag indicates whether all required components must be installed provided that 
       they correct versions are found in the distribution. This is a optional parameter. The default value is false to keep the tool backwards compatible.
	   Note that the value of this parameter is set to the default value (TRUE) when a silent installation is chosen.
@param forceOverwriteFiles this flag indicates whether the files of the component must be overwritten if a previous installation of the component is detected in the target directory
       This is a optional parameter. The default value is false to keep the tool backwards compatible.
	   Note that the value of this parameter is set to the default value (FALSE) when a silent installation is chosen.
@param isSilent flag indicating whether we are dealing with a silent installation of the packages or not. The default value is false.
@param installSubComponents flag indicating whether subcomponents have to also be installed
@return Error code: -1 if ERROR, 0 if all OK.
@author  F. Varela.
*/
int fwInstallation_installComponent(string descFile, 
                                    string sourceDir, 
                                    bool isItSubComponent,  
                                    string & componentName, 
                                    bool & componentInstalled, 
                                    string &dontRestartProject, 
                                    string subPath = "", 
                                    bool forceInstallRequired = false, 
                                    bool forceOverwriteFiles = false, 
                                    bool isSilent = false, 
                                    bool installSubComponents = true)
{

  string destinationDir;  // the name of a directory where the component will be installed
  dyn_float df;
  dyn_string ds;
  	
  dyn_float dreturnf; // return value of a panel
  dyn_string dreturns; // return value of a panel
	
  string componentFileName; 
  string fileToCopy;
  string asciiManager;
  string infoFile;
  string logFile;
  string cmd;
  string strComponentFile; 
  string asciiFile;
  string result;
  string tmpResult;
  int dpCreated;
  int iReturn; // the return value of function fwInstallation_evalScriptFile;
//  dyn_string dynComponentFileLines;
  dyn_string dynFileNames;
  dyn_string dynComponentFiles;
//  dyn_string dynPostDeleteFiles_current;
  dyn_string dynPostDeleteFiles_all;
//  dyn_string dynPostInstallFiles_current;
  dyn_string dynPostInstallFiles_all;
  dyn_string dynPostDeleteFiles;
  dyn_string dynPostInstallFiles;
  dyn_string dynConfigFiles_general;
  dyn_string dynConfigFiles_linux;
  dyn_string dynConfigFiles_windows;
  dyn_string dynInitFiles;
  dyn_string dynDeleteFiles;
  dyn_string dynDplistFiles;
  dyn_string resultInLines;
  dyn_string dynScriptsToBeAdded; 
  string helpFile;

  // sub Components handling
  dyn_string dynSubComponents;
	
  // end sub Components handling

  string componentVersion;
  string date;
  string componentConfigFile = "";
  string dplistFile;
  bool requiredInstalled = true;
	
  // component dependencies
	
  dyn_string dynRequiredComponents;
	
  string strNotInstalledNames = "";
	

  float floatInstalledVersion;
  string strInstalledName; 
  dyn_string  dynNotProperlyInstalled;
	
  // end component dependencies
	
  string tagName;
  string tagValue;
  string filePath, filePattern, fileNameToAdd;
  dyn_string fileNames;
	
  bool	fileLoaded;
  bool x;
  string err;
  string componentInitFile;
	
  int i, j, k;
  int pos1, pos2, pos3, pos4;
  int dpGetResult;
  int fileCopied;

  int error = 0;
	
  int registerOnly = 0;
  dyn_string proj_paths;

  dyn_string dsNotInstalledComponents;
  dyn_string dsGoodComponents;
  
  dyn_dyn_string componentsInfo;
  dyn_string currentComponentInfo;
  dyn_string dsTmp;
  string notInstalledComponentName;
  string notInstalledComponentVersion;
  string fileComponentName;
  string fileComponentVersion;
  string fileComponent;

  string componentPath; 
  dyn_string comments;
  string description;
  
  dyn_string dsFileComponentName;
  dyn_string dsFileComponentVersion;
  dyn_string dsFileComponent;  
  
  dynClear(dsFileComponentName);
  dynClear(dsFileComponentVersion);
  dynClear(dsFileComponent);

  string installedVersion;
  string dp = fwInstallation_getInstallationDp();
  
  dontRestartProject = "no";

  // add a control manager for the fwScripts.lst
  string user, pwd, host = fwInstallation_getHostname();
  int port = pmonPort();
  fwInstallation_getPmonInfo(user, pwd);
  fwInstallationManager_add(fwInstallation_getWCCOAExecutable("ctrl"), "once", 30, 1, 1, "-f fwScripts.lst", host, port, user, pwd);

  if(descFile == "")
  {
    if(myManType() == UI_MAN) ChildPanelOnCentralModal("fwInstallation/fwInstallation_popup.pnl", "Installation ERROR", makeDynString("$text:Failed to install component: " + componentName + ". The XML file is not defined"));
    
    fwInstallation_throw("fwInstallation_installComponent() -> Failed to install component: " + componentName + ".\nThe XML file is not defined");
    return -1;
  }
  
  // get the destination dir
  dpGet(dp + ".installationDirectoryPath", destinationDir);
  
  //step 1
  dyn_dyn_mixed parsedComponentInfo;
  if(fwInstallationXml_parseFile(sourceDir, descFile, subPath, destinationDir, parsedComponentInfo))
  {
    if(myManType() == UI_MAN) ChildPanelOnCentralModal("fwInstallation/fwInstallation_popup.pnl", "Installation ERROR", makeDynString("$text:Failed to install component: " + sourceDir + "/" + descFile + ".\nXML file not properly parsed"));
    fwInstallation_throw("fwInstallation_installComponent() -> Failed to install component: " + sourceDir + "/" + descFile + ". XML file not properly parsed");
    return -1;
  }  
  componentName = parsedComponentInfo[FW_INSTALLATION_XML_COMPONENT_NAME];
  componentVersion = parsedComponentInfo[FW_INSTALLATION_XML_COMPONENT_VERSION];
  dynSubComponents = parsedComponentInfo[FW_INSTALLATION_XML_COMPONENT_SUBCOMPONENTS];
  dynFileNames = parsedComponentInfo[FW_INSTALLATION_XML_COMPONENT_FILES];
  dynPostDeleteFiles = parsedComponentInfo[FW_INSTALLATION_XML_COMPONENT_POST_DELETE_SCRIPTS];
  dynPostInstallFiles = parsedComponentInfo[FW_INSTALLATION_XML_COMPONENT_POST_INSTALL_SCRIPTS];
  dyn_string dynPostDeleteFilesCurrent = parsedComponentInfo[FW_INSTALLATION_XML_COMPONENT_POST_DELETE_SCRIPTS_CURRENT];
  dyn_string dynPostInstallFilesCurrent = parsedComponentInfo[FW_INSTALLATION_XML_COMPONENT_POST_INSTALL_SCRIPTS_CURRENT];
  dynConfigFiles_general = parsedComponentInfo[FW_INSTALLATION_XML_COMPONENT_CONFIG_FILES];
  dynConfigFiles_linux = parsedComponentInfo[FW_INSTALLATION_XML_COMPONENT_CONFIG_FILES_LINUX];
  dynConfigFiles_windows = parsedComponentInfo[FW_INSTALLATION_XML_COMPONENT_CONFIG_FILES_WINDOWS];
  dynInitFiles = parsedComponentInfo[FW_INSTALLATION_XML_COMPONENT_INIT_SCRIPTS];
  dynDeleteFiles = parsedComponentInfo[FW_INSTALLATION_XML_COMPONENT_DELETE_SCRIPTS];
  dynDplistFiles = parsedComponentInfo[FW_INSTALLATION_XML_COMPONENT_DPLIST_FILES];
  dynScriptsToBeAdded = parsedComponentInfo[FW_INSTALLATION_XML_COMPONENT_SCRIPT_FILES];
  helpFile = parsedComponentInfo[FW_INSTALLATION_XML_COMPONENT_HELP_FILE];
  date = parsedComponentInfo[FW_INSTALLATION_XML_COMPONENT_DATE];
  comments = parsedComponentInfo[FW_INSTALLATION_XML_COMPONENT_COMMENTS];
  description = parsedComponentInfo[FW_INSTALLATION_XML_COMPONENT_DESCRIPTION];
  dynRequiredComponents = parsedComponentInfo[FW_INSTALLATION_XML_COMPONENT_REQUIRED_COMPONENTS];
  string requiredPvssVersion = parsedComponentInfo[FW_INSTALLATION_XML_COMPONENT_REQUIRED_PVSS_VERSION];
  bool strictPvssVersion = parsedComponentInfo[FW_INSTALLATION_XML_COMPONENT_STRICT_PVSS_VERSION][1];
  string requiredPvssPatch = parsedComponentInfo[FW_INSTALLATION_XML_COMPONENT_REQUIRED_PVSS_PATCH];
  dyn_string dynPreinit = parsedComponentInfo[FW_INSTALLATION_XML_COMPONENT_PREINIT_SCRIPTS];
  bool updateTypes = parsedComponentInfo[FW_INSTALLATION_XML_COMPONENT_UPDATE_TYPES][1];
  string requiredInstallerVersion = parsedComponentInfo[FW_INSTALLATION_XML_COMPONENT_REQUIRED_INSTALLER_VERSION];
  bool strictInstallerVersion = parsedComponentInfo[FW_INSTALLATION_XML_COMPONENT_STRICT_INSTALLER_VERSION][1];
  
  fwInstallation_setCurrentComponent(componentName, componentVersion);
  
  string msg;
  int ret = -1;
  if(requiredPvssVersion != "") //Check PVSS version
  {
    fwInstallation_throw("Component: "+componentName + "v." + componentVersion + " requires PVSS version: " + requiredPvssVersion + ". Checking condition now...", "INFO", 10);
    ret = fwInstallation_checkPvssVersion(requiredPvssVersion);
    
    if(ret <= 0)
    {
      msg = "Current PVSS version: " + VERSION_DISP + " older than the required version " + requiredPvssVersion + ".\nInstallation aborted";
      if(myManType() == UI_MAN) ChildPanelOnCentralModal("fwInstallation/fwInstallation_popup.pnl", "Installation ERROR", makeDynString("$text:" + msg));
      fwInstallation_throw(msg, "ERROR");
      fwInstallation_unsetCurrentComponent();
      return -1;
    }
    else if(strictPvssVersion && ret!= 1)
    {
      msg = "Current PVSS version: " + VERSION_DISP + " older than the required version " + requiredPvssVersion + ".\nInstallation aborted";
      if(myManType() == UI_MAN) ChildPanelOnCentralModal("fwInstallation/fwInstallation_popup.pnl", "Installation ERROR", makeDynString("$text:" + msg));
      fwInstallation_throw(msg, "ERROR");
      fwInstallation_unsetCurrentComponent();
      return -1;
    }
    else
    {
      fwInstallation_throw("OK: Current PVSS version: " + VERSION_DISP + " equal or newer than required version " 
                           + requiredPvssVersion, "INFO", 10);
    }
  }
  
  if(requiredPvssPatch != "") //Check patching
  {
    fwInstallation_throw("Component: "+componentName + "v." + componentVersion + " requires PVSS patch: " + requiredPvssPatch + ". Checking condition now...", "INFO", 10);

    if(fwInstallation_isPatchInstalled(requiredPvssPatch) <= 0 && ret == 1) //Check the patch level only if we are talking about the exact PVSS version.
    {
      msg = "Current PVSS version: " + VERSION_DISP 
            + " does not contain patch: " + requiredPvssPatch + ". Component installation aborted";
      if(myManType() == UI_MAN) ChildPanelOnCentralModal("fwInstallation/fwInstallation_popup.pnl", "Installation ERROR", makeDynString("$text:" + msg));
      fwInstallation_throw(msg, "ERROR");
      fwInstallation_unsetCurrentComponent();
      return -1;
    }
    else
    {
      fwInstallation_throw("OK: Patch: " + requiredPvssPatch + " applied to current PVSS version: " + VERSION_DISP, "INFO", 10);
    }
  }
  
  if(requiredInstallerVersion != "") //Check PVSS version
  {
    fwInstallation_throw("Component: "+componentName + "v." + componentVersion + " requires a version: " + requiredInstallerVersion + " of the FW Component Installation Tool. Checking condition now...", "INFO", 10);
    int ret = fwInstallation_checkToolVersion(requiredInstallerVersion);
    if(ret <= 0)
    {
      msg = "Current version of the Installation Tool: " + csFwInstallationToolVersion 
                           + " is older than the required version " + requiredInstallerVersion + ". Installation aborted";
      if(myManType() == UI_MAN) ChildPanelOnCentralModal("fwInstallation/fwInstallation_popup.pnl", "Installation ERROR", makeDynString("$text:" + msg));
      fwInstallation_throw(msg, "ERROR");
      fwInstallation_unsetCurrentComponent();
      return -1;
    }
    else if(strictInstallerVersion && ret!= 1)
    {
      msg = "Component: "+componentName + "v." + componentVersion 
                           + " can only be installed using version " + requiredInstallerVersion + ". Installation aborted";
      if(myManType() == UI_MAN) ChildPanelOnCentralModal("fwInstallation/fwInstallation_popup.pnl", "Installation ERROR", makeDynString("$text:" + msg));
      fwInstallation_throw(msg, "ERROR");
      fwInstallation_unsetCurrentComponent();
      return -1;
    }
    else
    {
      fwInstallation_throw("OK: Current version of the FW Component Installation Tool: " + csFwInstallationToolVersion + " equal or newer than required version " 
                           + requiredInstallerVersion, "INFO", 10);
    }
  }


////////////////////////////////////////////////
  fwInstallation_throw("Now installing " + componentName  + " v." + componentVersion + " from " + sourceDir + ". XML File: " + descFile, "INFO");
  //step 2
  
  //FVR: 31/03/2006: Check if the component already exists in the destination directory:
  //Check that the forceOverwriteFiles is not true in addition
  registerOnly = fwInstallation_getRegisterOnly(destinationDir, componentName,  forceOverwriteFiles, isSilent);
  if(registerOnly < 0.) //Installation aborted by the user.
    return 0;

  //// check if all scripts all valid, and all directories are writeable and if all source files exist
  bool actionAborted = false;
  bool componentIntegrityWrong = false;
  if(fwInstallation_verifyPackage(sourceDir, 
                                  subPath,
                                  componentName,
				                            destinationDir,
                                  registerOnly, 
                                  dynInitFiles, 
                                  dynPostInstallFilesCurrent, 
                                  dynDeleteFiles,
                                  dynPostDeleteFilesCurrent,
                                  dynFileNames,
                                  isSilent,
                                  actionAborted))
  {
    fwInstallation_throw("fwInstallation_installComponent() -> Failed to verify component package: " + componentName);
    componentIntegrityWrong = true; //signal that we know that there was a problem with the component but the user has decided to go ahead.
    ++error;
  }

  if(actionAborted) //user has decided to cancel the installation or we are running from a ctrl manager
  {
    fwInstallation_unsetCurrentComponent();
    return 0;
  }
  
  //step 2.5, :-)
  //Run Pre-init scripts
  if(fwInstallation_executeComponentInitScripts(componentName, sourceDir, subPath, dynPreinit, isSilent))
  {
    fwInstallation_setComponentInstallationStatus(componentName, false);
    msg = "Execution of component pre-init script(s) failed. Installation of " + componentName + " v." + componentVersion + " aborted.";
    if(myManType() == UI_MAN) ChildPanelOnCentralModal("fwInstallation/fwInstallation_popup.pnl", "Installation ERROR", makeDynString("$text:" + msg));
    fwInstallation_throw(msg, "ERROR");
    fwInstallation_unsetCurrentComponent();
    return -1;
  }
  //step 3
  //install required component if necessary:
  if(fwInstallation_installRequiredComponents(componentName, dynRequiredComponents, sourceDir, forceInstallRequired, forceOverwriteFiles, isSilent, requiredInstalled, actionAborted))
  {
    msg = "Could not force installation of required components for component " + componentName;
    if(myManType() == UI_MAN) ChildPanelOnCentralModal("fwInstallation/fwInstallation_popup.pnl", "Installation ERROR", makeDynString("$text:" + msg));
    fwInstallation_throw(msg, "ERROR");
    ++error;
  }
  
  if(actionAborted) //user has decided to cancel the installation or running from ctrl script
  {
    fwInstallation_unsetCurrentComponent();
    return 0;
  }
  
// install the subcomponents if they exist
  if(installSubComponents && dynlen(dynSubComponents))
  {
    fwInstallation_showMessage(makeDynString("     Installing sub Components ... "));
    for(i = 1; i <= dynlen(dynSubComponents); i++)
    {
      if(fwInstallation_installComponent(dynSubComponents[i], sourceDir, true, dynSubComponents[i], componentInstalled, dontRestartProject))
      {
        fwInstallation_setComponentInstallationStatus(componentName, false);
        msg = "Failed to install subcomponent: " + dynSubComponents[i] + " from: " + sourceDir;
        if(myManType() == UI_MAN) ChildPanelOnCentralModal("fwInstallation/fwInstallation_popup.pnl", "Installation ERROR", makeDynString("$text:" + msg));
        fwInstallation_throw(msg, "ERROR");
        fwInstallation_unsetCurrentComponent();
        return -1;
      }
    }
  }

  // copy all the files
  if(fwInstallation_copyComponentFiles(componentName, sourceDir, subPath, destinationDir, dynFileNames, registerOnly, isSilent))
  {
    msg = "Failed to copy component files: " + componentName;
    if(myManType() == UI_MAN) 
    {
      dyn_float df;
      dyn_string ds;
      ChildPanelOnCentralModalReturn("fwInstallation/fwInstallation_popup.pnl", "Installation ERROR", makeDynString("$text:" + msg), df, ds);
    }
    
    fwInstallation_throw(msg, "error", 4);
    if(!componentIntegrityWrong) //The component integrity is OK but there were problems copying the file.
    {
      fwInstallation_setComponentInstallationStatus(componentName, false);
      fwInstallation_unsetCurrentComponent();
      return -1;
    }
  }		

// import the dplist files with the ASCII manager
  if(fwInstallationRedu_isComponentInstalledInPair(componentName, componentVersion))
  {
    fwInstallation_throw("fwInstallation_installComponent() -> Redundant system. Component already installed in pair. ASCII import will be skipped for component: " + componentName, "INFO");
  }
  else
  {
    if(fwInstallation_importComponentAsciiFiles(componentName, sourceDir, subPath, dynDplistFiles, updateTypes))
    {
      fwInstallation_setComponentInstallationStatus(componentName, false);
      msg = "Failed to import .dpl files for component: " + componentName + " " + dynDplistFiles;
      if(myManType() == UI_MAN) ChildPanelOnCentralModal("fwInstallation/fwInstallation_popup.pnl", "Installation ERROR", makeDynString("$text:" + msg));
      fwInstallation_throw(msg);
      fwInstallation_unsetCurrentComponent();
      return -1;
    }
  }

  if(fwInstallation_importConfigFiles(componentName, sourceDir, subPath, dynConfigFiles_general, dynConfigFiles_linux, dynConfigFiles_windows))
  {
    fwInstallation_setComponentInstallationStatus(componentName, false);
    msg = "Failed to import config files for component: " + componentName;
    if(myManType() == UI_MAN) ChildPanelOnCentralModal("fwInstallation/fwInstallation_popup.pnl", "Installation ERROR", makeDynString("$text:" + msg));
    fwInstallation_throw(msg);
    fwInstallation_unsetCurrentComponent();
    return -1;
  }

// add scripts to the fwScripts.lst file
  if(fwInstallation_executeComponentInitScripts(componentName, sourceDir, subPath, dynInitFiles, isSilent))
  {
    fwInstallation_setComponentInstallationStatus(componentName, false);
    msg = "Failed to execute init scripts for component: " + componentName;
    if(myManType() == UI_MAN) ChildPanelOnCentralModal("fwInstallation/fwInstallation_popup.pnl", "Installation ERROR", makeDynString("$text:" + msg));
    fwInstallation_throw(msg);
    fwInstallation_unsetCurrentComponent();
    return -1;
  }
 
  string xml = descFile;
  strreplace(xml, "\\", "/");
  dyn_string ddss = strsplit(descFile, "/");
  xml = "./" + ddss[dynlen(ddss)];
  
  //dynSubComponents is the list of XML files of the subcomponents. We need to extract only the names to set the internal dp
  dyn_string subcomponents;
  for(int i = 1; i <= dynlen(dynSubComponents); i++)
    subcomponents[i] = fwInstallation_getComponentName(dynSubComponents[i]);
  
  if(fwInstallation_createComponentInternalDp(componentName, componentVersion, xml, isItSubComponent, sourceDir, date, helpFile, destinationDir,
                                              dynFileNames, dynConfigFiles_general, dynConfigFiles_linux, dynConfigFiles_windows,
                                              dynInitFiles, dynPostInstallFiles, dynDeleteFiles, dynPostDeleteFiles, dynDplistFiles,
                                              dynRequiredComponents, subcomponents, dynScriptsToBeAdded, requiredInstalled, comments, description))
                                              
  {
    fwInstallation_setComponentInstallationStatus(componentName, false);
    msg = "Failed to create internal dp for the Installation Tool for component: " + componentName;
    if(myManType() == UI_MAN) ChildPanelOnCentralModal("fwInstallation/fwInstallation_popup.pnl", "Installation ERROR", makeDynString("$text:" + msg));
    fwInstallation_throw(msg);
    fwInstallation_unsetCurrentComponent();
    return -1;
  }
  
  // the component has been installed - check whether it has corrected the broken dependencies
  if(fwInstallation_checkComponentBrokenDependencies())
  {
    fwInstallation_throw("fwInstallation_installComponent() -> Failed to check broken dependencies for component: " + componentName);
    ++error;
  }

  //Store post-installation scripts for execution:
  if(fwInstallation_storeComponentPostInstallScripts(dynPostInstallFiles))
  {
    msg = "Failed to store post-installation scripts for component: " + componentName;
    if(myManType() == UI_MAN) ChildPanelOnCentralModal("fwInstallation/fwInstallation_popup.pnl", "Installation ERROR", makeDynString("$text:" + msg));
    fwInstallation_throw(msg);
    ++error;
  }
  
  //Legacy		
  componentInstalled = true;

  if(error)
  {
    msg = "ERROR during component installation: " + componentName;
    fwInstallation_throw(msg);
    fwInstallation_setComponentInstallationStatus(componentName, false);
    if(myManType() == UI_MAN)
    { 
      dyn_float df;
      dyn_string ds;
      ChildPanelOnCentralModalReturn("fwInstallation/fwInstallation_popup.pnl", "Installation ERROR", makeDynString("$text:" + msg), df, ds);
    }
  }
  else
  {
    msg = "The installation of component " + componentName + " v." + componentVersion + " completed OK";
    if(dynlen(dynPostInstallFiles))
      msg += " - Note that there are still post-installation scripts pending execution";
    
    fwInstallation_throw(msg, "INFO", 10);
    fwInstallation_setComponentInstallationStatus(componentName, true);
  }
  
  dyn_int projectStatus;
  if(fwInstallationDB_getUseDB() && fwInstallationDB_connect() == 0)
  {
    fwInstallation_throw("Updating FW System Configuration DB after installation of " + componentName + " v"+ componentVersion, "INFO", 10);
    fwInstallationDB_storeInstallationLog();
    fwInstallationDB_registerProjectFwComponents();
    fwInstallationDBAgent_checkIntegrity(projectStatus);
  }
//  if(fwInstallationDB_getUseDB() && fwInstallationDBAgent_checkIntegrity(projectStatus) != 0)
//    fwInstallation_throw("Could not check PVSS-DB contents integrity", "error", 7);
                	
  fwInstallation_unsetCurrentComponent();
  return gFwInstallationOK;	
}


/** This function sets the internal dpes of the component dp according to the status of the installation

@param componentName component name
@param ok status of installation
@return Error code: -1 if ERROR, 0 if all OK.
@author  F. Varela.
*/

int fwInstallation_setComponentInstallationStatus(string componentName, bool ok)
{
  string dp;
  
  if(myReduHostNum() > 1)
    dp = "fwInstallation_" + componentName + "_" + myReduHostNum();
  else
    dp = "fwInstallation_" + componentName;

  if(!dpExists(dp))
    return 0;
  
  return dpSet(dp + ".installationNotOK", !ok);
}


/** This function retrieves the list of components which were not properly installed - there was error in dependencies
and the user still wanted to install the component.

@param dynNotProperlyInstalled: the list of components which were installed with broken dependencies - .requiredInstalled:_original.._value is false
@author M.Sliwinski
*/
fwInstallation_getListOfNotProperlyInstalledComponents(dyn_string & dynNotProperlyInstalled)
{
		dyn_string dynInstalledComponents;
		int i;
		bool requiredInstalled;
		
		// retrieve all installed components
	        dynInstalledComponents =  fwInstallation_getInstalledComponentDps();
		
		for(i = 1; i <= dynlen(dynInstalledComponents); i++)
		{	
  			dpGet(dynInstalledComponents[i] + ".requiredInstalled:_original.._value", requiredInstalled);
                        
			if(!requiredInstalled)
			  dynAppend(dynNotProperlyInstalled, dynInstalledComponents[i]);
		}		
}

/** This function checks if all the required components are installed. It returns a string of components that are not
installed and required.

@param dynRequiredComponents: the name of a componentConfigFile
@param strNotInstalledNames: the name of a component
@author M.Sliwinski
*/
fwInstallation_getNotInstalledComponentsFromRequiredComponents(dyn_string & dynRequiredComponents, string & strNotInstalledNames)
{
	int i;
	dyn_string dynInstalledComponents, dynInstalledComponentDps;
	dyn_string dynTmpNameVersion;
	string strRequiredName;
	string stringInstalledVersion;
	string stringRequiredVersion;
	
	if (dynlen(dynRequiredComponents) > 0)
	{
	
	
		// retrieve all installed components
		
		dynInstalledComponentDps =  fwInstallation_getInstalledComponentDps();
                dynInstalledComponents = dynInstalledComponentDps;
                
		for(i = 1; i <= dynlen(dynInstalledComponents); i++)
		{	
			// cut the system name from the installed components
			dynInstalledComponents[i] = dpSubStr( dynInstalledComponents[i], DPSUB_DP );
			// cut the fwInstallation_ prefix 
			strreplace(dynInstalledComponents[i], "fwInstallation_" , "");		
		}
				
		for( i = 1; i <= dynlen(dynRequiredComponents); i++)
		{
			// retrieve the name and version of the component
			dynTmpNameVersion = strsplit(dynRequiredComponents[i] , "=");
			strRequiredName = strltrim(strrtrim(dynTmpNameVersion[1]));
			if(dynlen(dynTmpNameVersion) > 1)
				stringRequiredVersion = strltrim(strrtrim(dynTmpNameVersion[2]));
			else
				stringRequiredVersion = "";
			
			
			// check whether the required component is installed
			
			if(dynContains(dynInstalledComponents, strRequiredName))
			{
				// the required component is installed
				// checking the version of the installed component
                                 string reqDp = fwInstallation_getComponentDp(strRequiredName);
				 dpGet(reqDp + ".componentVersionString:_original.._value", stringInstalledVersion);
				 if(_fwInstallation_CompareVersions(stringInstalledVersion, stringRequiredVersion))
				 {
				 
				 	// the installed version of the component is greater than the required version - OK
				 }
				 else
				 {
				 	// the installed version is older than the required version
					strNotInstalledNames += strRequiredName + "=" + stringRequiredVersion + "|";
                                 }
			}
			else
			{
				// the required component is not installed
				strNotInstalledNames += strRequiredName + "=" + stringRequiredVersion + "|";
			}
		}
	}
}

/** This function reads the information from the componentConfigFile and copies it into the project config file.
Function uses the following functions: fwInstallation_loadConfigIntoTables, fwInstallation_AddComponentIntoConfigIntoMemory
fwInstallation_saveFile

@param componentConfigFile: the name of a componentConfigFile
@param componentName: the name of a component
@author M.Sliwinski and F. Varela
*/

fwInstallation_AddComponentIntoConfig(string componentConfigFile, string componentName)
{
	
	string configPath = getPath(CONFIG_REL_PATH);
	string configFile = configPath + "config";
	
	dyn_string loadedSections;  // this table contains the sections loaded from the config file
	dyn_dyn_string configSectionTable; // the memory representation of a config file     [1][i] - [section:parameter] , [i+1][j] - [value]
	dyn_string configLines; // this table contains the config file - each row contains one line from config file
	dynClear(loadedSections);
	configSectionTable [1] = "";
	configSectionTable [2] = "";
	configSectionTable [3] = "";

	// load the config file into its memory representation			
	fwInstallation_loadConfigIntoTables(loadedSections, configSectionTable, configLines, configFile);

	// add component into memory if not fwInstallation
	if(componentName != gFwInstallationComponentName)
        {
  	  fwInstallation_AddComponentIntoConfigIntoMemory(loadedSections, configSectionTable, configLines, componentConfigFile , componentName);
        }
        
	fwInstallation_saveFile(configLines, configPath + "config");

}


/** This function reads the information from the component config file and saves the information into memory:
loadedSections and configSectionTable - the tables containing the information about the sections:parameters:values
configLines: the table containing the lines of a config file

@param loadedSections: the list of loaded sections
@param configSectionTable: the memory representation of a config file     [1][i] - [section:parameter] , [i+1][j] - [value]
@param configLines: the dyn_string containing the lines of a config file
@param fileName: the name of a config file of a component
@param componentName: the name of a component
@author M.Sliwinski
*/

int fwInstallation_AddComponentIntoConfigIntoMemory(dyn_string & loadedSections, dyn_dyn_string & configSectionTable, dyn_string & configLines, string fileName, string componentName)
{
	string fileInString;
	string tempLine;
	string currentSection = "NOT_YET_DEFINED";
	dyn_string componentLines; // contains the lines from the component config file
	dyn_dyn_string componentParameters; // [1][i] - section name; [i + 1][j] - section parameters ( lines )
	bool fileLoaded = false;
	dyn_string linesToAdd;
	string tempParameter;
	string tempValue;
	string tempString,tempStringQuotes;
	
	dyn_string strValues;
	dyn_string parameterValue;
	
	int idxOfSection;
	int sectionExistsInConfig;
	int valueExistsInConfig;
	int i, j , k;
	int returnValue;
	
	
//	componentParameters[1] = "";
//	componentParameters[2] = "";
	dynClear(componentParameters[1]);
	dynClear(componentParameters[2]);
	
	// first delete the old information about the component from the config file
	fwInstallation_deleteComponentFromConfigInMemory(loadedSections, configSectionTable, configLines, componentName);
		
	
	// load the component config file
	fileLoaded = fileToString(fileName, fileInString);
	
	if (! fileLoaded )
	{
	
		fwInstallation_throw("Cannot load " + fileName + " file", "error", 4);
	}
	else 
	{

			componentLines = strsplit(fileInString, "\n");
			
			
			for(i = 1; i <= dynlen(componentLines); i++)
			{
				tempLine = strltrim(strrtrim(componentLines[i]));
		
		
				if (tempLine == "" )
				{
		//			Debug("\n The line is blank |"  + tempLine + "|");
				}
				else if ( strtok(tempLine, "#") == 0)
				{
					if( currentSection == "NOT_YET_DEFINED")
					{
						// we do not know in which section to add the comment
					}
					else  // add the comment into the table
					{
						idxOfSection = dynContains(componentParameters[1], currentSection);
						
						dynAppend(componentParameters[idxOfSection + 1], tempLine);
					}
				}
				else if ( strtok(tempLine, "[") == 0)  // this is a section
				{
					
					dynAppend(componentParameters[1] ,tempLine);
					currentSection = tempLine;
							
				}
				else // this is parametrization
				{
					 if(currentSection == "NOT_YET_DEFINED")
					 {
					 	fwInstallation_throw("the component file has errors  section is not defined. line: " + i);
					 }
					 else
					 {
					 	idxOfSection = dynContains(componentParameters[1], currentSection);
					 	//Debug("&&&&Parametrization: ", tempLine);
					 	dynAppend(componentParameters[idxOfSection + 1], tempLine);
					 }
				}
			} //end  for ( i = 1; i <= dynlen(componentLines)
			
			// the component information is now in the componentParameters table
		
			
		// adding the component into the config file
		
			for(i = 1; i <= dynlen(componentParameters[1]); i++)
			{
				currentSection = componentParameters[1][i];
				
		//		Debug("\n adding the lines in section: " + currentSection);
				
				sectionExistsInConfig = dynContains(loadedSections, currentSection);
				
				if(sectionExistsInConfig == 0) // the section does not exist - add the lines into the config table and into the memory
				{
					dynClear(linesToAdd);
							
					dynAppend(loadedSections, currentSection);
					dynAppend(configLines, currentSection);
					
					dynAppend(configLines, "#begin " + componentName);
					dynAppend(configLines, "#This should not be edited manually");
					dynAppend(configLines, "#if the component is empty it means that the parametrization is already done in the section");

					for(j =1; j <= dynlen(componentParameters[i + 1]); j++)
					{
						tempLine = strltrim(strrtrim(componentParameters[i + 1][j]));
						
						if (tempLine == "")
						{
		//					 Debug("\n The line is blank: |" + tempLine + "|");
						}
						else if( strtok(tempLine, "#") == 0)
						{
		//					Debug("\n The line is a comment: |" + tempLine + "|");
							dynAppend(linesToAdd, tempLine);
		//
						}
						else  // this line is a parametrization - check if the value already exist, if not add it
						{
								parameterValue = strsplit(tempLine, "=");
								tempParameter = strltrim(strrtrim(parameterValue[1]));
								tempValue = strltrim(strrtrim(parameterValue[2]));
								tempStringQuotes = tempValue; //SMS
								tempString = strltrim(strrtrim(tempValue, "\""), "\"");
								tempValue = tempString;
								strValues = strsplit(tempValue, ",");
								
								for(k = 1; k <= dynlen(strValues); k++)
								{
									tempValue = strltrim(strrtrim(strValues[k]));
									
									returnValue = fwInstallation_configContainsValue(configSectionTable, currentSection, tempParameter, tempValue);
									if( returnValue == 1)
									{
										// the value is already defined for this section and parameter
									}
									else
									{
										if(tempString == tempStringQuotes)	//SMS only if quotes where there before, put them again
										{
											dynAppend(linesToAdd, tempParameter + " = " + tempValue );	//SMS
										} else {
											dynAppend(linesToAdd, tempParameter + " = \"" + tempValue + "\"");	//SMS the original line
										}
		
										fwInstallation_addValueIntoMemory(configSectionTable, currentSection, tempParameter, tempValue); 
									}
								}	
						}

					}
					dynAppend(configLines, linesToAdd);
					dynAppend(configLines, "#end " + componentName + "\n");
					
					// we have added the whole information into the section			
				}
				else if(sectionExistsInConfig == -1)
				{
					Debug("\n ERROR: Cannot check if section exists in loadedSections table");
				}
				else // add the lines into the config table and into the memory
				{
					//Debug("&&&& 5 section exists in the config");
					if(dynlen(componentParameters) >= i+1)
					{
						dynClear(linesToAdd);
					 	dynAppend(linesToAdd, "#begin " + componentName);
						dynAppend(linesToAdd, "#This should not be edited manually");
						dynAppend(linesToAdd, "#if the component is empty it means that the parametrization is already done in the section");
						
						for(j = 1; j <= dynlen(componentParameters[i + 1]); j++)
						{
							tempLine = strltrim(strrtrim(componentParameters[i + 1][j]));
							
							if (tempLine == "")
							{
			//					 Debug("\n The line is blank: |" + tempLine + "|");
							}
							else if( strtok(tempLine, "#") == 0)
							{
			//					Debug("\n The line is a comment: |" + tempLine + "|");
								dynAppend(linesToAdd, tempLine);
			//
							}
							else  // this line is a parametrization - check if the value already exist, if not add it
							{
									parameterValue = strsplit(tempLine, "=");
									tempParameter = strltrim(strrtrim(parameterValue[1]));
									tempValue = strltrim(strrtrim(parameterValue[2]));
									
									tempStringQuotes = tempValue; //SMS
									tempString = strltrim(strrtrim(tempValue, "\""), "\"");
									tempValue = tempString;
									strValues = strsplit(tempValue, ",");
									
									for(k = 1; k <= dynlen(strValues); k++)
									{
										tempValue = strltrim(strrtrim(strValues[k]));
										
										returnValue = fwInstallation_configContainsValue(configSectionTable, currentSection, tempParameter, tempValue);
										if( returnValue == 1)
										{
											// the value is already defined for this section and parameter
										}
										else
										{
                                                                                        if(tempParameter == "distPeer")
                                                                                        {  
												dynAppend(linesToAdd, tempParameter + " = " + tempStringQuotes);	//SMS
                                                                                        }
											else if(tempString == tempStringQuotes)	//SMS only if quotes where there before, put them again
											{
												dynAppend(linesToAdd, tempParameter + " = " + tempValue );	//SMS
											} else {
												dynAppend(linesToAdd, tempParameter + " = \"" + tempValue + "\"");	//SMS the original line
											}
			
											fwInstallation_addValueIntoMemory(configSectionTable, currentSection, tempParameter, tempValue); 
										}
									}	
							}
						}
						
						dynAppend(linesToAdd, "#end " + componentName + "\n");
					}
		
		
		    // we are adding the lines - linesToAdd   into the configLines table under  - currentSection
					fwInstallation_addLinesIntoSection(configLines, currentSection, linesToAdd);
				}
			}

	}
}


/** This function adds the lines from linesToAdd into the configLines under the section specified by currentSection

@param configLines: the dyn_string with file lines
@param currentSection: the name of a currentSection
@param linesToAdd: the lines to be added

@author M.Sliwinski
*/

int fwInstallation_addLinesIntoSection(dyn_string & configLines, string currentSection, dyn_string  linesToAdd)
{
	int idxOfLine;
	int i;
	int returnValue;
	
	string tempLine;
	
	for( i = 1; i <= dynlen(configLines); i++)
	{
		tempLine = strltrim(strrtrim(configLines[i]));
		
		// find the section where it should be inserted	
		if(tempLine == currentSection)
		{
			// insert the lines into the configLines
			returnValue = dynInsertAt(configLines, linesToAdd, ++i);
			
			if(returnValue == -1)
			{
				return -1;
			}
			else
			{
				return 1;
			}
		}	
	}
	
	
}

/** This function adds [section:parameter] , [value] data into the memory representation of a config file

@param configSectionTable: the memory representation of a config file     [1][i] - [section:parameter] , [i+1][j] - [value]
@param section: the value of a section
@param parameter: the value of a parameter
@param value: the value of a "value"

@author M.Sliwinski
*/

int fwInstallation_addValueIntoMemory(dyn_dyn_string & configSectionTable, string section, string parameter, string value)
{
	int	idxSectionParam;
	int idxValue;
	int idxTemp;
	
	// get the index of section:parameter
	idxSectionParam = dynContains(configSectionTable[1], section + ":" + parameter);
	
	if (idxSectionParam == 0)
	{
		// add the section:parameter to the configSectionTable
		
		dynAppend(configSectionTable[1], section + ":" + parameter);
		
		// find the index of section:parameter
		idxTemp	= dynContains(configSectionTable[1], section + ":" + parameter);
		
		// add the value into memory
		dynAppend(configSectionTable[idxTemp + 1], value);	
	}
	else if(idxSectionParam == -1)
	{
		Debug("Error: fwInstallation_addValueIntoMemory");
		return -1;
	}
	else
	{
		idxValue = dynContains(configSectionTable[idxSectionParam + 1], value);
		
		if (idxValue == 0)
		{
			dynAppend(configSectionTable[idxSectionParam + 1], value);	
		}
		else if(idxValue == -1)
		{
			Debug("Error: fwInstallation_addValueIntoMemory");
		}
		else
		{	
			// This value already exists - do nothing
		}
	}
	return 1;

}

/** This function deletes the config info about a component from the memory representation of a config file - [section:parameter] , [value]
and from the configLines dyn_string

@param loadedSections: the list of sections loaded from the config file
@param configSectionTable: the memory representation of a config file     [1][i] - [section:parameter] , [i+1][j] - [value]
@param configLines: the dyn_string containing the lines from the config file
@param componentName: the name of a component to be deleted

@author M.Sliwinski
*/

int fwInstallation_deleteComponentFromConfigInMemory(dyn_string & loadedSections, dyn_dyn_string & configSectionTable, dyn_string & configLines, string componentName)
{
	int i, j;
	
	int configLength;
	int idxSectionParam;
	int idxSection;
	int idxValue;
	int idxCurrent;
	int removeResult;
	
	string currentSection;
	dyn_string sections;
	dyn_string configSectionRow;
	
	string tempLine;
	string tempParameter;
	string tempValue;
	string tempString;
	string tempSection;
	dyn_string parameter_Value;
	
	dyn_dyn_int components; // [1][i] index of beginning of a component definition;  [2][i] index of ending of a component definition
	dyn_string strValues;
	
	int idxBegin = 0;
	int idxEnd = 0;
	
	dynClear(sections);
	dynClear(components[1]);
	dynClear(components[2]);
	


// find out where are the components situated and in which sections
// we are interested in the indexes of #begin and #end lines
	for(i = 1; i <= dynlen(configLines); i++)
	{
	
		if ( strtok(configLines[i], "[") == 0)
		{
						currentSection = configLines[i];
		}
		
			if(configLines[i] == "#begin " + componentName)
			{
				idxBegin = i;
			}
			
			if(configLines[i] == "#end " + componentName)
			{
				idxEnd = i;
			}
			
			if(idxBegin < idxEnd)
			{
				dynAppend(components[1], idxBegin); 
				dynAppend(components[2], idxEnd);
				dynAppend(sections, currentSection);

				idxBegin = 0;
				idxEnd = 0;
			}
	}


// delete the component from the file ( the configLines table ) and from configSectionTable

	for(i = dynlen(components[1]); i >=1; i--)
	{
		idxBegin = components[1][i];
		idxEnd = components[2][i];
	
		idxCurrent = idxEnd;

		currentSection = sections[i];

		for(idxCurrent = idxEnd; idxCurrent >= idxBegin; idxCurrent--)
		{
			// delete it from the configSectionTable
			tempLine = strltrim(strrtrim(configLines[idxCurrent]));
			removeResult = dynRemove(configLines, idxCurrent);
			if (removeResult == -1)
			{
				Debug("\n ERROR: fwInstallation_deleteComponentFromConfigInMemory(): could not remove the line from table");
			}
			
			if (tempLine == "" )
			{
			}
			else if ( strtok(tempLine, "#") == 0)
			{
			}
			else // the templine contains parameters
			{
				parameter_Value = strsplit(tempLine, "=");
				tempParameter = strltrim(strrtrim(parameter_Value[1]));
				tempValue = strltrim(strrtrim(parameter_Value[2]));
				tempString = strltrim(strrtrim(tempValue, "\""));
				tempValue = tempString;  // now value is without quotation marks
				strValues = strsplit(tempValue, ",");
				
				for(j = 1 ; j <= dynlen(strValues); j++)
				{
					tempValue = strValues[j];
					strValues[j] = strrtrim(strltrim(tempValue , "\" ") , "\" ");
				}
				
				tempString = currentSection + ":" + tempParameter;
				
				// Deleting the values from memory
				idxSectionParam = dynContains(configSectionTable[1], tempString);
					
				if(idxSectionParam == 0)
				{
				}
				else if (idxSectionParam == -1)
				{
					fwInstallation_throw("Cannot read value from configSectionTable: ");
				}
				else{
				
					for(j = 1; j <= dynlen(strValues); j++)
					{
						idxValue = dynContains(configSectionTable[idxSectionParam + 1], strValues[j]);
						
						if(idxValue > 0)
						{
							removeResult = dynRemove(configSectionTable[idxSectionParam + 1], idxValue);
						}					
					}

				} // else
			}
				
		}
		
	}
	
}


/** This function checks whether the section-parameter-value is defined in the memory


@param configSectionTable: the memory representation of a config file     [1][i] - [section:parameter] , [i+1][j] - [value]
@param section: the value of a section
@param parameter: the value of a parameter
@param value: the value of a "value"

@author M.Sliwinski
*/

int fwInstallation_configContainsValue(dyn_dyn_string & configSectionTable, string section , string parameter, string value)
{
	int idxOfParameter;
	int idxOfValue;
	
	idxOfParameter = dynContains(configSectionTable[1] , section + ":" + parameter);
	
	if(idxOfParameter == 0)
	{
//		Debug("\n fwInstallation_configContainsValue: There is no section_parameter:" + section + ":" + parameter);
		return 0;
	}
	else if (idxOfParameter == -1)
	{
		Debug("\n ERROR: fwInstallation_configContainsValue: error in checking section_parameter" );
		return 0;
	}
	else
	{	
		idxOfValue = dynContains(configSectionTable[idxOfParameter + 1], value);
		if(idxOfValue ==  0)
		{
			return 0;
		}
		else if (idxOfValue == -1)
		{
//			Debug("\n fwInstallation_configContainsValue: error in checking value" );
			return 0;
		}
		else
		{
//			Debug("\n fwInstallation_configContainsValue: value exists: returning 1");
			return 1;
		}
		
	}
}

						
/** This function builds the memory representation of a config file

@param loadedSections: the list of sections loaded from the config file
@param configSectionTable: the memory representation of a config file     [1][i] - [section:parameter] , [i+1][j] - [value]
@param configLines: dyn_string containing the lines from the config file 
@param fileName: the name of a config file

@author M.Sliwinski
*/
	
int fwInstallation_loadConfigIntoTables(dyn_string & loadedSections, dyn_dyn_string & configSectionTable, dyn_string & configLines, string fileName)
{
//	dyn_string knownSections = makeDynString("[ui]" , "[ctrl]");
	
	dyn_string parameter_Value;

	int idxSectionParam;
	int idxSection;
	int idxValue;
	int sectionLength;

	bool fileLoaded = false;

	string fileInString;

	string tempLine;
	string tempParameter;
	string tempValue;
	string tempString; 

	dyn_string strValues;
	
	string currentSection = "NOT_KNOWN";
	string lineTrimmed;
	
	int i, j ;
	
	fileLoaded = fileToString(fileName, fileInString);
	
	if (! fileLoaded )
	{
	
		fwInstallation_throw("Cannot load " + fileName + " file");
	}
	else 
	{
//		Debug("\n" + fileName + " - file loaded");
	}

	configLines = strsplit(fileInString, "\n");
	
	
// each line is loaded in a row of dyn_string configLines
	
	for(i = 1; i <= dynlen(configLines); i++)
	{
		tempLine = strltrim(strrtrim(configLines[i]));

					
		if (tempLine == "" )
		{
//			Debug("\n The line is blank |"  + tempLine + "|");
		}
		else if ( strtok(tempLine, "#") == 0)
		{
//			Debug("\n This line is a comment |"  + tempLine + "|");
		}
		else if ( strtok(tempLine, "[") == 0)
		{
//			Debug("\n This line is a section |"  + tempLine + "|");
		//	if(dynContains(knownSections, tempLine))
		//	{
//						Debug("\n Adding new section into memory: " + tempLine);
			
					dynAppend(loadedSections ,tempLine);
					currentSection = tempLine;
					
		//	}
		//	else
		//	{
			//	Debug("\n This section is not known");
		//				currentSection = "NOT_KNOWN";
		//	}
		}
		else // this is parametrization
		{ 
			if (currentSection == "NOT_KNOWN")
			{
				// Debug("\n This section is not known: don't add parameter to memory");
			}
			else // This section is already in memory
			{
//				Debug("\n Adding the parameter into memory" + tempLine + "|");
				
				parameter_Value = strsplit(tempLine, "=");
				
				tempParameter = strltrim(strrtrim(parameter_Value[1]));
				
				tempValue = strltrim(strrtrim(parameter_Value[2]));
				
				tempString = strltrim(strrtrim(tempValue, "\""));
				
				tempValue = tempString;  // now value is without quotation marks
				
				strValues = strsplit(tempValue, ",");
				
				for(j = 1 ; j <= dynlen(strValues); j++)
				{
					tempValue = strValues[j];
					strValues[j] = strrtrim(strltrim(tempValue , "\" ") , "\" ");
				}
				
				// we hava all the values in a dyn_string - strValues
								
				idxSection = dynContains(loadedSections, currentSection);
				
				if (idxSection > 0)  // this section is in loaded sections
				{
				
					tempString = currentSection + ":" + tempParameter;
												
					idxSectionParam = dynContains(configSectionTable[1], tempString);
					
	//				Debug("\n idxSection : " + idxSection );
				
					if(idxSectionParam == 0)  // the parameter tempParameter is not defined
					{
						
						dynAppend(configSectionTable[1], tempString);
						
//						Debug("\n Adding parameter: " + tempString + " and values: " + strValues + "for the first time");
						
						idxSectionParam = dynContains(configSectionTable[1], tempString);
						
						for( j = 1; j<= dynlen(strValues); j++)
						{
							
							dynAppend(configSectionTable[idxSectionParam + 1], strValues[j]);
							
						}
							
	//					Debug("\n adding the parameter: " + tempParameter );			
					}
					else if( idxSectionParam == -1)
					{

					}
					else // the parameter is defined for the section add the value
					{
		
			
						for( j = 1; j<= dynlen(strValues); j++)
						{
									
							idxValue = dynContains(configSectionTable[idxSectionParam + 1], strValues[j]);
							
							if(idxValue == 0)
							{
								dynAppend(configSectionTable[idxSectionParam + 1], strValues[j]);
//								Debug("\n Adding parameter: " + tempString + " and values: " + strValues);
								
							}
							else if (idxValue == -1)
							{
								Debug("\n ERROR: fwInstallation_loadConfigIntoTables():  Error in adding Value into memory");
							}
							else
							{
//								Debug("\n This value already exists: " + tempValue);
							}
						}
					}
				} // if (dynContains(loadedSections, currentSection))
				else
				{	
					// This parameter is in a "not known section"
				}
				
			}
		
		} // else		
	} // end for	
        
        

}

/** This function saves the new proj_path order into the config file

@param projPaths (in) the value with a list of proj_paths
@return 0 if OK, -1 if error
@author Sascha Schmeling
*/

int fwInstallation_changeProjPaths(dyn_string projPaths)
{  
	dyn_string parameter_Value;
	dyn_string configLines;
	
	bool fileLoaded = false;
	
	string fileInString;

	string tempLine;
	string tempParameter;
	string tempValue;
	string tempString; 

	string configPath = getPath(CONFIG_REL_PATH);
	string configFile = configPath + "config";
	string configFileEntry;
	
	
	int i, j ;
	int numberOfProjPaths = 0;
	int indexOfProjPath = 0;
//SMS changes to accomodate commented project paths
	dyn_int projPathIndex;	
        
        
  //FVR reshuffle project paths to make sure that the last one corresponds to the project path
  dynRemove(projPaths, dynContains(projPaths, PROJ_PATH));
  dynAppend(projPaths, PROJ_PATH);
        
	fileLoaded = fileToString(configFile, fileInString);
	
	if (! fileLoaded )
	{
	
		Debug("\n Cannot load " + configFile + " file");
		return -1;
	}
	//else 
	//{
		//Debug("\n" + configFile + " - file loaded");
	//}

	configLines = strsplit(fileInString, "\n");
	
// each line is loaded in a row of dyn_string configLines

	dynClear(projPathIndex);	
	for(i = 1; i <= dynlen(configLines); i++)
	{
		tempLine = strltrim(strrtrim(configLines[i]));
		
		if(tempLine == "")
		{
		}
		else
		{				
				parameter_Value = strsplit(tempLine, "=");
				
				tempParameter = strltrim(strrtrim(parameter_Value[1]));
				
				if(tempParameter == "proj_path")
				{  
			
					numberOfProjPaths++;
					dynAppend(projPathIndex,i);		//SMS store positions of valid project paths in the config file
					if(indexOfProjPath == 0)
					{
						indexOfProjPath = i;
					}			
	
				}
		}	
	}		

	if(numberOfProjPaths!=dynlen(projPaths))
	{
		return -1;
	} else {
		// exchange loaded projPaths with ordered ones
		for(i=numberOfProjPaths;i>=1;i--)
		{
			dynRemove(configLines, projPathIndex[i]);			
			configFileEntry = "proj_path = \"" + projPaths[i] + "\"";
			dynInsertAt(configLines, configFileEntry , projPathIndex[i]);
		}
		
		fwInstallation_saveFile(configLines, configFile);
	
		return 1;
	}
}

/** This function creates a project path, either creates the directory or just adds the path

@param sPath:	project path to be created
@param createDirectory flag to indicate if the directory has to be created if it does not exist (default value is true)
@return 0 if OK, -1 if error
*/

int fwInstallation_createPath(string sPath, bool createDirectory = true)
{
  dyn_string projPaths;
  int i, x;
  string result;
	
  int directoryExists;
  bool state;
  string cmd, err = 0;
  string dp = fwInstallation_getInstallationDp();
	
  if (access(sPath, F_OK) == -1 && createDirectory)
  {
    mkdir(sPath, "755");
		 if(access(sPath, F_OK) != -1)
      fwInstallation_throw("New directory successfully created: " + sPath, "INFO", 10);
			else
			{
         fwInstallation_throw("You must define the full path. Project path will not be added");
         return -1;
     }
  }
	//the directory has been created - add it into the config file
	if(fwInstallation_addProjPath(sPath, 999))
  {
    fwInstallation_throw("File to add project path to config file: " + sPath);    
    return -1;
  }
        
  dpSet(dp + ".installationDirectoryPath", sPath);
  
  return 0;
}

///FVR: 29/03/2006

/** This function retrieves the component information from the PVSS DB and
	displays it in the panel

@param componentName the name of a file with component description
@author M.Sliwinski
*/

fwInstallation_getComponentDescriptionPVSSDB(string componentName)
{
	float componentVersion;
	string descFile;
	string date;
	dyn_string componentFiles;
	dyn_string configFiles_linux;
	dyn_string configFiles_windows;
	dyn_string configFiles_general;
	dyn_string initFiles;
	dyn_string dplistFiles;
	dyn_string scriptFiles;
	dyn_string requiredComponents;
	dyn_string requiredNameVersion;
	dyn_string dynSubComponents;
	dyn_string postInstallFiles;
	string componentVersionString;
	
	string requiredName;
	string requiredVersion;
	//shape shape_destinationTable = getShape("tblSubComponents");
        string dp = fwInstallation_getComponentDp(componentName);

	int i;

		dpGet(dp + ".componentVersionString:_original.._value", componentVersionString);
		dpGet(dp + ".descFile:_original.._value", descFile);
		dpGet(dp + ".componentFiles:_original.._value", componentFiles);
		dpGet(dp + ".configFiles.configLinux:_original.._value", configFiles_linux);
		dpGet(dp + ".configFiles.configWindows:_original.._value", configFiles_windows);
		dpGet(dp + ".configFiles.configGeneral:_original.._value", configFiles_general);

		dpGet(dp + ".initFiles:_original.._value", initFiles);
		dpGet(dp + ".scriptFiles:_original.._value", scriptFiles);
		dpGet(dp + ".dplistFiles:_original.._value", dplistFiles);
		dpGet(dp + ".requiredComponents:_original.._value", requiredComponents);
		dpGet(dp + ".date:_original.._value", date);
		dpGet(dp + ".subComponents:_original.._value", dynSubComponents);
		dpGet(dp + ".postInstallFiles:_original.._value", postInstallFiles);

		TextName.text = componentName;
		TextVersion.text = componentVersionString;
		TextDate.text = date;
		
		for(i = 1; i<= dynlen(componentFiles); i++)
			selectionOtherFiles.appendItem(componentFiles[i]);
		
		for(i = 1; i<= dynlen(configFiles_windows); i++)
			selectionConfigFiles_windows.appendItem(configFiles_windows[i]);
		
		for(i = 1; i<= dynlen(configFiles_linux); i++)
			selectionConfigFiles_linux.appendItem(configFiles_linux[i]);
		
		for(i = 1; i<= dynlen(configFiles_general); i++)
			selectionConfigFiles_general.appendItem(configFiles_general[i]); 
		
		for(i = 1; i<= dynlen(initFiles); i++)
			selectionInitFiles.appendItem(initFiles[i]);
		
		for(i = 1; i<= dynlen(dplistFiles); i++)
			selectionDplistFiles.appendItem(dplistFiles[i]);
		
		for(i = 1; i<= dynlen(scriptFiles); i++)
			selectionScripts.appendItem(scriptFiles[i]);
		
		for(i = 1; i<= dynlen(requiredComponents); i++)
		{	
			requiredNameVersion = strsplit(requiredComponents[i], "=");
			requiredName = requiredNameVersion[1];
			
			if(dynlen(requiredNameVersion) > 1)
			{
				requiredVersion = requiredNameVersion[2];
			}
			else
			{
				requiredVersion = " ";
			}
			
			selectionRequiredComponents.appendItem(requiredName + " ver.: " + requiredVersion);
			
		}
		
		for(i = 1; i <= dynlen(postInstallFiles); i++)
			selectionPostInstallFiles.appendItem(postInstallFiles[i]);
		
		for(i = 1; i <= dynlen(dynSubComponents); i++)
			selectionSubComponents.appendItem( dynSubComponents[i]);
}

/** This function puts the components to be deleted in order in which they should be deleted
The function only checks if the component chosen for deleting depend on each other.
The function operates on the component information contained in the PVSS DB

algorithm: suppose we have the following components to delete:  com1, com2, com3
the dependencies are following:
	com1: is required by com2
	com2: is required by com3
	com3: is nor required by them
We can first delete the com3 because it is not required by com1 i com3
	the dependencies are following:
	com1: is required by com2
	com2: is not required by any component
If there is a loop: com1 is required by com2 and com2 is required by com1 the components can not be ordered

@param componentsNames: the dyn_string of the components to be put in order before deleting 
@param componentsNamesInOrder: the dyn_string of the ordered components to be deleted

@author M.Sliwinski
*/

fwInstallation_putComponentsInOrder_Delete(dyn_string componentsNames, dyn_string & componentsNamesInOrder)
{
	dyn_dyn_string dependencies; //  first column - component name, next columns - components that require this component
	dyn_string dynDependentComponents;
	string tempComponentName;
	bool emptyListExists = true;
	int i, j, k;
	
	// build the dependencies table
	// for each compomponent
	for(i = 1; i <= dynlen(componentsNames); i++)
	{
		// build the dependencies table
		dynAppend(dependencies[i] , componentsNames[i]);
		
		// get the list of dependent components
		fwInstallation_getListOfDependentComponents(componentsNames[i], dynDependentComponents);
		// append the dependent components
		dynAppend(dependencies[i], dynDependentComponents);
	}
	 

	// put the components in order - algorithm is described in the comment before the function
	while(emptyListExists)
	{
		emptyListExists = false;
			
			// for each component	
			for(i = 1; i <= dynlen(componentsNames); i++)
			{
				// if it is not required by other components
				if((dynlen(dependencies[i]) == 1) && (dependencies[i][1] != "EMPTY"))
				{
					emptyListExists = true;

					tempComponentName = dependencies[i][1];
					
					// remove the component name from the dependencies table ( set it to EMPTY value )
					dependencies[i][1] = "EMPTY"; 
					
					// put it at the end of the  components in order
					dynAppend(componentsNamesInOrder, tempComponentName);
					
					// remove the component from the list
					for(j = 1; j <= dynlen(componentsNames); j++)
					{
						
						k = dynContains(dependencies[j], tempComponentName);
						
						if(k > 0)
						{
							// this component no longer requires other components
							dynRemove(dependencies[j], k);	
						}	
					}
				}
			}
	}
	
	// if there were unsolved dependencies copy the components to the end of the list
	
	for(i = 1; i <= dynlen(componentsNames); i++)
	{
		if(dependencies[i][1] != "EMPTY")
		{
			dynAppend(componentsNamesInOrder, dependencies[i][1]);
		}	
	}
		
}


/** This function gets the list of dependent components. This functions from the list of  all  installed components
 retrieves the list of components that require strComponentName

@param strComponentName: the name of the component for which we would like to find dependent components
@param dynDependentComponents: the dyn_string of components that require the strComponentName component
@author M.Sliwinski
*/

fwInstallation_getListOfDependentComponents(string strComponentName, dyn_string & dynDependentComponents)
{

	dyn_string dynInstalledComponents, dynInstalledComponentDps;
	dyn_string dynRequiredComponents;
	dyn_string dynTmpNameVersion;
	string strTmpName;
	int i, j, k;
	
	dynClear(dynDependentComponents);
	
	// get all the components installed in the system
  dynInstalledComponentDps =  fwInstallation_getInstalledComponentDps();
	// check all the components whether they require the strComponentName
	for(i = 1; i <= dynlen(dynInstalledComponentDps); i++) 
	{
    dynInstalledComponents[i] = dpSubStr( dynInstalledComponentDps[i], DPSUB_DP ); 
    strreplace(dynInstalledComponents[i], "fwInstallation_", "");

    if( dynInstalledComponents[i] != strComponentName)
    {
      // retrieve the required components
      dpGet(dynInstalledComponentDps[i] + ".requiredComponents", dynRequiredComponents);
      // check whether the strComponentName is required by this component
      for(j = 1; j <= dynlen(dynRequiredComponents); j++)
      {
        dynClear(dynTmpNameVersion);
        dynTmpNameVersion = strsplit(dynRequiredComponents[j], "=");
        strTmpName = strltrim(strrtrim(dynTmpNameVersion[1]));
        if(strTmpName == strComponentName)
        {
					  dynAppend(dynDependentComponents, dynInstalledComponents[i]);	
				  }
      }
    }
  }
}

/** this function deletes the component files, the component information from the config file
	and the internal DP created by the installation tool with the description of a component. 
	This function does not delete the component data point types ( ETM is planning to 
	add the functionality of deleting the DPT, DP from the ASCII Manager ).

@param componentName (in) the name of a component to be deleted
@param componentDeleted (out) result of the operation
@param deleteAllFiles (in) flag indicating if the components files must also be deleted. Default value is true.
@param deleteSubComponents flag indicating if the subcomponent must also be deleted. Default value is true.
@author F. Varela
*/
int fwInstallation_deleteComponent(string componentName, 
                                   bool & componentDeleted, 
                                   bool deleteAllFiles = TRUE, 
                                   bool deleteSubComponents = true)
{

	dyn_string componentFiles, componentFilesDelete;
	dyn_string deleteFiles;
	dyn_string postDeleteFiles;
	dyn_string dynDependentComponents;
	dyn_string dynSubComponents;
	string strDependentComponentsNames;
	dyn_string dreturns;
	dyn_float dreturnf;
	int iReturn;
	int	errorDeletingComponent, error;
	int i,k;
	string installationDirectory, tempString;
	int errorCounter = 0;
	string errorString,descFileName;
	dyn_string strErrors = "";
	bool deletionAborted = FALSE;
	dyn_string dynPostDeleteFiles_all;
  string componentVersion;
  string msg;
  
  string dp = fwInstallation_getComponentDp(componentName);
  if(!dpExists(dp))
  {
    componentDeleted = true;
    return 0;
  }
	  
  dpGet(dp + ".componentVersionString", componentVersion,
        dp + ".installationDirectory", installationDirectory,
        dp + ".subComponents", dynSubComponents,
        dp + ".componentFiles", componentFiles,
        dp + ".deleteFiles", deleteFiles,
        dp + ".postDeleteFiles", postDeleteFiles);
  dynUnique(componentFiles);
  
  if(installationDirectory == "") {fwInstallation_throw("The installation directory for the " + componentName + " does not exist or is not specified!", "error", 4);return -1;}

  fwInstallation_throw("Deleting component: " + componentName + " v." + componentVersion + " from project " + PROJ + " in host " + fwInstallation_getHostname(), "info", 10);
  //begin check the component dependencies - if it is required by other components 
  fwInstallation_getListOfDependentComponents(componentName, dynDependentComponents);
  if(dynlen(dynDependentComponents) > 0)
  {
    for(i = 1; i <= dynlen(dynDependentComponents); i++) strDependentComponentsNames += dynDependentComponents[i] + "|";
    fwInstallation_showMessage(makeDynString("Dependent components at deletion of "+componentName+":",strDependentComponentsNames));
    // ask the user if he wants to delete this component - other components are using it
    if(myManType() == UI_MAN)
      ChildPanelOnCentralReturn("fwInstallation/fwInstallationDependencyDelete.pnl", "fwInstallation_Dependency_Delete",
                                makeDynString("$strDependentNames:" + strDependentComponentsNames , "$componentName:" + componentName, "$callingPanel:" + "ToDelete"), dreturnf, dreturns);
    else
    {
//      fwInstallation_throw("Deleting component: " + componentName + ", which is required by " + strDependentComponentsNames, "warning", 10);
      dreturns[1] = "Install_Delete";
    }
			
    // check the return value of fwInstallationDependency .pnl
    if(dreturns[1] == "Install_Delete")
    {
      fwInstallation_showMessage(makeDynString("User choice at deletion of "+componentName+": DELETE"));
    }
    else if(dreturns[1] == "DoNotInstall_DoNotDelete")
    {
      fwInstallation_showMessage(makeDynString("User choice at deletion of "+componentName+": ABORT"));
      deletionAborted = TRUE;
    }
  }

  // check if all files are deletable
  // FVR: Do this check only if the deleteAllFiles flag is set to true
  if(deleteAllFiles)
  {	
    for (k=1; k<=dynlen(componentFiles); k++)
    {
      if(access(installationDirectory + "/" + componentFiles[k], F_OK) == 0)
        dynAppend(componentFilesDelete, componentFiles[k]);
      else
        fwInstallation_throw("Component " + componentName + " points to a non existing file: " + installationDirectory + "/" + componentFiles[k], "WARNING", 3);
    }
  }

	if(!deletionAborted)
	{
	  if(myManType() == UI_MAN && shapeExists("logFileName"))	
            logFileName.text = installationDirectory + "/log/fwDeInstallation_"+componentName+"_"+formatTime("%Y%m%d_%H%M%S",getCurrentTime())+".log\"";
          
		fwInstallation_writeToMainLog(formatTime("[%Y-%m-%d_%H:%M:%S] ",getCurrentTime()) + "Starting to delete " + componentName);
		fwInstallation_showMessage(makeDynString("Deleting " + componentName + " ... ")); 
		
		// delete all subcomponents
		for(i = 1; i <= dynlen(dynSubComponents); i++)
		{
      if(deleteSubComponents)
      {
        fwInstallation_showMessage(makeDynString("   Deleting sub components .."));
        fwInstallation_deleteComponent(dynSubComponents[i], componentDeleted, deleteAllFiles, deleteSubComponents);
      }
   }	

		
   // begin store the postDelete files in a datapoint
		if(dynlen(postDeleteFiles)>0)
   {
     for(i=1; i<=dynlen(postDeleteFiles); i++)
			  dynAppend(dynPostDeleteFiles_all, installationDirectory +"/"+ postDeleteFiles[i]);
    
		  dpSet(fwInstallation_getInstallationDp() + ".postDeleteFiles", dynPostDeleteFiles_all);			
   }
    
   // delete the DP
   dpDelete(dp);
   delay(1);             
   
   // execute delete scripts
   for(i =1; i <= dynlen(deleteFiles); i++)
   {
     msg = "Executing the delete file ... ";
     fwInstallation_throw(msg, "INFO", 10);
     fwInstallation_showMessage(makeDynString(msg));
     string componentDeleteFile = deleteFiles[i];
     // read the file and execute it		
     fwInstallation_evalScriptFile( installationDirectory +"/"+ componentDeleteFile , iReturn);
     if(iReturn == -1)
     {
       msg = "Executing the delete file: " + componentDeleteFile + " - Component: " + componentName;
       fwInstallation_throw(msg, "WARNING", 10);
//       fwInstallation_showMessage(makeDynString(msg));
       errorDeletingComponent = -1;
     }
   }
   
   if(deleteAllFiles)
   {
     msg = "Deleting files for component: " + componentName;
     fwInstallation_throw(msg, "INFO", 10);
     fwInstallation_showMessage(makeDynString(msg));
     if(fwInstallation_deleteFiles(componentFilesDelete, installationDirectory)) 
       errorDeletingComponent = -1;
		}
		
		// now delete the component info from the config file
   msg = "Updating the project config file after component deletion: " + componentName;
   fwInstallation_throw(msg, "INFO", 10);
//		fwInstallation_showMessage(makeDynString(msg));
		_fwInstallation_DeleteComponentFromConfig(componentName);
	}

	if(myManType() == UI_MAN && shapeExists("logFileName"))	
	  logFileName.text = "";

	if((errorDeletingComponent == -1) || (deletionAborted))
	{
    msg = "There were errors while deleting the components - see the log for details - Component: " + componentName;
//    fwInstallation_showMessage(makeDynString(msg));		
    fwInstallation_throw(msg);		
    if(deletionAborted)
    {
      fwInstallation_writeToMainLog(formatTime("[%Y-%m-%d_%H:%M:%S] ",getCurrentTime()) + componentName + " de-installation aborted");
    } else 
    {
      fwInstallation_writeToMainLog(formatTime("[%Y-%m-%d_%H:%M:%S] ",getCurrentTime()) + componentName + " deleted with errors");
    }
    componentDeleted = FALSE;
	}
	else
	{
    msg = "Component deleted: " + componentName;
    fwInstallation_throw(msg, "INFO", 10);
//    fwInstallation_showMessage(makeDynString(msg));
    fwInstallation_writeToMainLog(formatTime("[%Y-%m-%d_%H:%M:%S] ",getCurrentTime()) + componentName + " deleted");
    componentDeleted = true;
	}

  if(myManType() == UI_MAN && shapeExists("logFileName"))
    tempString = logFileName.text;
  
  if(tempString != "")
  {
//    fwInstallation_showMessage(makeDynString("Please find the log file for this deinstallation operation in:",tempString));
    fwInstallation_writeToMainLog(formatTime("[%Y-%m-%d_%H:%M:%S] ",getCurrentTime()) + "Please find the log file for this de-installation operation in: "+tempString);
  }
  
  if(fwInstallation_checkComponentBrokenDependencies()) fwInstallation_throw("fwInstallation_deleteComponent() -> Failed to check broken dependencies");
  
  dyn_int projectStatus;
  if(fwInstallationDB_getUseDB() && fwInstallationDB_connect() == 0)
  {
    fwInstallation_throw("Updating FW System Configuration DB after deletion of " + componentName + " v"+ componentVersion, "INFO", 10);
    fwInstallationDB_storeInstallationLog();
    fwInstallationDB_registerProjectFwComponents();
    fwInstallationDBAgent_checkIntegrity(projectStatus);
  }

  return 0;
}


/** This function resolves the XML files and versions of the compoents required 
*   for installation during the installation of a particular component

@param sourceDir (in) source directory
@param requiredComponents (in) list of required components
@param dsFileComponentName (out) list of names corresponding to the required components (obsolete, legacy)
@param dsFileVersions (out) list versions corresponding to the required components
@param dsFileComponent (out) list of XML files corresponding to the required components
@return 0 if success, -1 if error 
*/
int fwInstallation_checkDistribution(string sourceDir, 
                                     dyn_string requiredComponents, 
                                     dyn_string &dsFileComponentName, 
                                     dyn_string &dsFileVersions, 
                                     dyn_string &dsFileComponent)
{
  dyn_dyn_string componentsInfo;
  dyn_string dsTmp;
  string requiredComponentName;
  string requiredComponentVersion;
  string fileComponentName;
  string fileComponentVersion;
  string fileComponent;
   
  fwInstallation_getAvailableComponents(sourceDir, componentsInfo);
  for(int jj = 1; jj <= dynlen(requiredComponents); jj++){
    dsTmp = strsplit(requiredComponents[jj], "=");
    requiredComponentName = dsTmp[1];
    requiredComponentVersion = dsTmp[2];
                
    for(int ii = 1; ii <= dynlen(componentsInfo);ii++){
      fileComponentName = componentsInfo[ii][1];
      fileComponentVersion = componentsInfo[ii][2];
      fileComponent = componentsInfo[ii][5];
      if(patternMatch(requiredComponentName, fileComponentName)){
        fwInstallation_throw("Required component found in distribution:" + requiredComponentName + ". Comparing versions", "info", 10);
        if(_fwInstallation_CompareVersions(fileComponentVersion, requiredComponentVersion)){
          fwInstallation_throw("Distribution version OK. Proceeding with the installation: " + fileComponentVersion + " required: " +  requiredComponentVersion, "info", 10);
          fwInstallation_throw("Component description file: " + fileComponent, "info", 10);
          dynAppend(dsFileComponentName, fileComponentName);
          dynAppend(dsFileComponent, fileComponent);
          dynAppend(dsFileVersions, fileComponentVersion);
        }else{
          fwInstallation_throw("Distribution version NOT OK. Aborting installation: " + fileComponentVersion + " required: " +  requiredComponentVersion);
          return -1;
        }
      }
    }
  }
  //If all components are available it all right otherwise error
  if(dynlen(dsFileComponentName) == dynlen(requiredComponents))
    return 0;
  else
	  return -1;
  
}


/** This function checks if a given component is correctly installed

@param componentName: Name of the component to be checked
@param version: Version of the component to be checked. Optional parameter: if emtpy it checks for any version.
@return 0 if the component version or newer correctly installed,  -1 if the component installed correctly or just not installed
@author F. Varela
*/
int fwInstallation_checkInstalledComponent(string componentName, string version = "")
{
  dyn_string componentDPs;
  string componentDP;
  bool requiredComponents;
  
  string componentVersionString, installationDirectory;
  float componentVersion;

  componentDP = fwInstallation_getComponentDp(componentName);
        
  if(!dpExists(componentDP))
  {
    return -1;
  }
  dpGet(componentDP+".componentVersionString:_online.._value",componentVersionString,
        componentDP+".installationDirectory:_online.._value",installationDirectory,
        componentDP+".requiredInstalled:_online.._value", requiredComponents);


	if(componentVersionString == "")
	{
		dpGet(componentDP + ".componentVersion:_original.._value", componentVersion);
		if(componentVersion == floor(componentVersion))
		{
			sprintf(componentVersionString,"%2.1f",componentVersion);
		} else {
			componentVersionString = componentVersion;
		}
		dpSet(componentDP + ".componentVersionString:_original.._value", componentVersionString);
	}

  if(version != "" && !_fwInstallation_CompareVersions(componentVersionString, version)){
    fwInstallation_throw("fwInstallation_checkInstalledComponent()-> An old version:"+ componentVersionString +" of the component: " + componentName + " is installed in this system. Requested version: " + version, "INFO", 10);
    return -1;	  
	}
	
	if(!requiredComponents){
    fwInstallation_throw("fwInstallation_checkInstalledComponent()-> Version:"+ componentVersionString +" of the component: " + componentName + " is installed but not all required components", "INFO", 10);
    return -1;	  	
	}
  fwInstallation_throw("fwInstallation_checkInstalledComponent()-> Version:"+ componentVersionString +" of the component: " + componentName + " installed in this system", "INFO", 10);
  return 0;
}

/** This function checks if a previous installation of a particular directory exists in the target directiory
@param destinationDir (in) target directory
@param componentName (in) name of the component to be checked
@param versionInstalled (in) version of the component installed, if any
@return 0 if OK, -1 if error
*/
int fwInstallation_checkTargetDirectory(string destinationDir, string componentName, string &versionInstalled)
{
  dyn_string componentFiles = getFileNames(destinationDir, componentName + ".xml");
  
  if(dynlen(componentFiles) >0)
  {
    dyn_dyn_mixed componentInfo;  
    fwInstallationXml_load(destinationDir + "/" + componentFiles[1], componentInfo);
    versionInstalled = componentInfo[FW_INSTALLATION_XML_COMPONENT_VERSION];
    return 1;
  }
  
  versionInstalled = "";
  return 0;
}


/** This function retrieves the files in a directory recursing over sub-directories
@param dir (in) directory where to look for files
@param pattern (in) search pattern
@return list of file found as a dyn_string 
*/
dyn_string fwInstallation_getFileNamesRec(string dir = ".", string pattern = "*")
{
	dyn_string tempDynString;
	dyn_string allFileNames;
	string newDir = "/*";
	dynClear(allFileNames);
	fwInstallation_recurserFileNames(dir, "*", allFileNames);

	if(dynlen(allFileNames) > 0)
		for(int i=1; i<=dynlen(allFileNames); i++)
		{
			strreplace(allFileNames[i], dir + "/", "");
			strreplace(allFileNames[i], "//", "/");
		}

    if(pattern != "*")
      pattern = "*" + pattern;

	for(int i=1; i<=dynlen(allFileNames); i++){
		if(patternMatch(pattern, allFileNames[i]))
			dynAppend(tempDynString, allFileNames[i]);
	}
	return tempDynString;
}

/** Helper function used by fwInstallation_getFileNamesRec
@param dir (in) directory where to look for files
@param pattern (in) search pattern
@param fileNames (out) names of the files found
*/
fwInstallation_recurserFileNames(string dir, string pattern, dyn_string & fileNames)
{
	dyn_string tempDynString = getFileNames(dir + "/*", pattern);
	dyn_string tempDynString2 = getFileNames(dir, pattern);
	
	if(dynlen(tempDynString2) > 0)
		for(int i=1; i<=dynlen(tempDynString2); i++)
			tempDynString2[i] = dir +"/"+ tempDynString2[i];
	
	dynAppend(fileNames, tempDynString2);
	dynRemove(tempDynString, 1);
	if(dynlen(tempDynString) > 0)
		for(int i=1; i<=dynlen(tempDynString); i++)
			fwInstallation_recurserFileNames(dir + "/" + tempDynString[i] + "/", pattern, fileNames);
}

/** This function retrieves the full path to the XML description file of a component
@param componentName (in) name of the component
@param componentVersion (in) version of the component (legacy, not used)
@param sourceDir (in) source directory
@param descriptionFile (out) XML description file
@param isItSubComponent (out) indicates if it is a subcomponent or not
@return 0 if OK, -1 if error
*/
int fwInstallation_getDescriptionFile(string componentName,
                                      string componentVersion, 
                                      string sourceDir, 
                                      string &descriptionFile, 
                                      bool &isItSubComponent)
{
  string fileName = componentName + ".xml";
  dyn_dyn_string componentsInfo;

  fwInstallation_getAvailableComponents(makeDynString(sourceDir), componentsInfo, componentName);
  for(int i =1; i <= dynlen(componentsInfo); i++){
    
	  if(componentsInfo[i][1] == componentName && componentsInfo[i][2] == componentVersion)
    {
	    descriptionFile = componentsInfo[i][4];

	    if(componentsInfo[i][3] == "no")
	      isItSubComponent = false;
	    else
	      isItSubComponent = true;

        return 0;
    }
  }
  return -1;
}

/** This function parses the xml file of a coponent to find out if it is a sub-component
@param xmlFile (in) XML file name
@param isSubComponent (out) indicates if it is a subcomponent or not
@return 0 if OK, -1 if error
*/
int fwInstallation_isSubComponent(string xmlFile, bool &isSubComponent)
{
  dyn_dyn_mixed componentInfo;  
  isSubComponent = false;
  if(fwInstallationXml_load(xmlFile, componentInfo))
  {	
     fwInstallation_throw("fwInstallation_isSubComponent() -> Could not load XML file " + xmlFile + ". Aborted.", "error", 4);
     return -1;
  }
  isSubComponent = componentInfo[FW_INSTALLATION_XML_COMPONENT_IS_SUBCOMPONENT][1];
  
  return 0;

}
/** This function returns the port used by the distribution manager of the local project
@return port number
*/
int fwInstallation_getDistPort()
{
  int port;
  string filename = PROJ_PATH + "/config/config";
  string section = "dist";

  paCfgReadValue(filename,section, "distPort", port);
 
  if(port == 0)
    port = 4777;

  return port; 
}

/** This function returns the redundancy port of the local project
@return port number
*/
int fwInstallation_getReduPort()
{
  int port;
  string filename = PROJ_PATH + "/config/config";
  string section = "redu";

  paCfgReadValue(filename,section, "portNr", port);
 
  if(port == 0)
    port = 4899;

  return port; 
}

/** This function returns the split port of the local project
@return port number
*/
int fwInstallation_getSplitPort()
{
  int port;
  string filename = PROJ_PATH + "/config/config";
  string section = "split";

  paCfgReadValue(filename,section, "splitPort", port);
 
  if(port == 0)
    port = 4778;

  return port; 
}

/** This function returns the pmon user (not yet implemented)
@return pmon user 
*/
string fwInstallation_getPmonUser()
{
   return "N/A";   
}

/** This function returns the pmon pwd (not yet implemented)
@return pmon user 
*/
string fwInstallation_getPmonPwd()
{
   return "N/A";   
}

/** This function returns the properties of the local project as a dyn_mixed array
@param projectInfo (in) Project properties
@return 0 if OK, -1 if error
*/
int fwInstallation_getProjectProperties(dyn_mixed &projectInfo)
{
  string fwInstToolVer;
  string pvssOs;
  string hostname = fwInstallation_getHostname();
  
  hostname = strtoupper(hostname);
  
  if(_WIN32)
    pvssOs = "WINDOWS";
  else
    pvssOs = "LINUX";
  
  fwInstallation_getToolVersion(fwInstToolVer);

  projectInfo[FW_INSTALLATION_DB_PROJECT_NAME] = PROJ;
  projectInfo[FW_INSTALLATION_DB_PROJECT_HOST] = hostname;
  projectInfo[FW_INSTALLATION_DB_PROJECT_DIR] = PROJ_PATH;
  projectInfo[FW_INSTALLATION_DB_PROJECT_SYSTEM_NAME] = getSystemName();
  projectInfo[FW_INSTALLATION_DB_PROJECT_SYSTEM_NUMBER] = getSystemId();
  projectInfo[FW_INSTALLATION_DB_PROJECT_PMON_PORT] = pmonPort();
  projectInfo[FW_INSTALLATION_DB_PROJECT_PMON_USER] = fwInstallation_getPmonUser();
  projectInfo[FW_INSTALLATION_DB_PROJECT_PMON_PWD] = fwInstallation_getPmonPwd();
  projectInfo[FW_INSTALLATION_DB_PROJECT_TOOL_VER] = fwInstToolVer;
  
  if(fwInstallationDB_getUseDB())
    projectInfo[FW_INSTALLATION_DB_PROJECT_CENTRALLY_MANAGED] = fwInstallationDB_getCentrallyManaged();
  else
    projectInfo[FW_INSTALLATION_DB_PROJECT_CENTRALLY_MANAGED] = 0;
    
  projectInfo[FW_INSTALLATION_DB_PROJECT_PVSS_VER] = VERSION_DISP;
  projectInfo[FW_INSTALLATION_DB_PROJECT_DATA] = dataPort();
  projectInfo[FW_INSTALLATION_DB_PROJECT_EVENT] = eventPort();
  projectInfo[FW_INSTALLATION_DB_PROJECT_DIST] = fwInstallation_getDistPort();
  projectInfo[FW_INSTALLATION_DB_PROJECT_REDU_PORT] = fwInstallation_getReduPort();
  projectInfo[FW_INSTALLATION_DB_PROJECT_SPLIT_PORT] = fwInstallation_getSplitPort();  
  projectInfo[FW_INSTALLATION_DB_PROJECT_SYSTEM_OVERVIEW] = 1;  
  projectInfo[FW_INSTALLATION_DB_PROJECT_UPGRADE] = "";
  projectInfo[FW_INSTALLATION_DB_PROJECT_TOOL_STATUS]= fwInstallation_getToolStatus();
//  projectInfo[FW_INSTALLATION_DB_PROJECT_REDU_NR] = fwInstallation_getRedundancyNumber();
  dyn_string ds = eventHost();
  projectInfo[FW_INSTALLATION_DB_PROJECT_SYSTEM_COMPUTER] = strtoupper(ds[1]);
   
  
  if(_WIN32)
    projectInfo[FW_INSTALLATION_DB_PROJECT_OS] = "WINDOWS";  
  else
    projectInfo[FW_INSTALLATION_DB_PROJECT_OS] = "LINUX";  

  projectInfo[FW_INSTALLATION_DB_PROJECT_REDU_HOST] = fwInstallationRedu_getPair();
  
  return 0;  
}


/** This function loads the init file for the installation tool
@return 0 if OK, -1 if error
*/
int fwInstallation_loadInitFile()
{
  string cmd;
  string asciiManager = PVSS_BIN_PATH + fwInstallation_getWCCOAExecutable("ascii");
  string infoFile = getPath(LOG_REL_PATH) + fwInstallation_getWCCOAExecutable("ascii") + "_info.log";
  string logFile =  getPath(LOG_REL_PATH) + fwInstallation_getWCCOAExecutable("ascii") + "_log.log";
  string asciiFile = "";
  string instDir;
  dyn_string paths;
  string dp = fwInstallation_getInstallationDp();
  
  //find asccii file:
  fwInstallation_getProjPaths(paths);
  for(int i = dynlen(paths); i >= 1; i--)
  {
    paths[i] +="/config/"; 
    if(access(paths[i] + gFwInstallationInitFile, R_OK) == 0)
    {
	    asciiFile = paths[i] + gFwInstallationInitFile;
      break;
    }
  }

  if(asciiFile == "")
  {
//    fwInstallation_throw("FW Installation Tool init file cannot be found.", "INFO", 10);
	  return 0;
  }
  
  fwInstallation_throw("FW Installation Tool Init file found. Loading now: " + asciiFile, "INFO", 10);
 //Can we write to the log directory?
  if(access(PROJ_PATH + LOG_REL_PATH, W_OK) != 0)
  {
    fwInstallation_throw("fwInstallation_loadInitFile() -> Project log directory not writeable. Omitting stderr output.", "warning");
    cmd = asciiManager + " -in \"" + asciiFile + "\" -yes -noVerbose";								
  }
  else
  {
    cmd = asciiManager + " -in \"" + asciiFile + "\" -yes -log +stderr -log -file > "
	        + infoFile + " 2> " + logFile;								
  }

  if(_WIN32)
  {
    system("cmd /c " + cmd);  
  }
  else
    system(cmd);
  
  dpGet(dp + ".installationDirectoryPath", instDir);
  if(access(instDir, F_OK) != 0)
    mkdir(instDir, 777);
  
  if(access(instDir, W_OK) != 0)
  {
    fwInstallation_throw("fwInstallation_loadInitFile() -> Could not create installation directory", "error", 4);
    return -1;
  }

  fwInstallation_addProjPath(instDir, 999); 
  
  return 0;
   
}

/** This function loads the init file for the installation tool
@return 0 if OK, -1 if error
*/
int fwInstallation_runInitScript()
{
  int iReturn = 0;
  string script = "";
  dyn_string paths;
  
  //find asccii file:
  fwInstallation_getProjPaths(paths);
  for(int i = dynlen(paths); i >= 1; i--)
  {
    paths[i] +="/scripts/"; 
    if(access(paths[i] + gFwInstallationInitScript, R_OK) == 0)
    {
	    script = paths[i] + gFwInstallationInitScript;
      break;
    }
  }

  if(script == "")
  {
//    fwInstallation_throw("FW Installation Tool init script cannot be found.", "INFO", 10);
    return 0;
  }
  
  fwInstallation_throw("FW Installation Tool Init script found. Executing now: " + script, "INFO", 10);
  fwInstallation_evalScriptFile(script, iReturn);
  
  return iReturn;   
}


/** This function checks if pmon is protected with a username and a pwd
@return 0 if PMON is NOT protected, 1 otherwise
*/
int fwInstallation_isPmonProtected()
{
  bool err;
  string str, host;  
  int port, iErr = paGetProjHostPort(PROJ, host, port);
  dyn_dyn_string dsResult;
  
  paVerifyPassword(PROJ, "", "", iErr);
  if(iErr > 0)
    return 1;
  
  return 0; 
}
/** This function returns post install files that are scheduled to run

@param allPostInstallFiles:	dyn_string to contain the list of post install files
@return 0 - "success"  -1 - error 
@author S. Schmeling
*/
int fwInstallation_postInstallToRun(dyn_string & allPostInstallFiles)
{
	dyn_string dynPostInstallFiles_all;
        string dp = fwInstallation_getInstallationDp();
        
	if(dpExists(dp))
	{
		// get all the post install init files
		dpGet(dp + ".postInstallFiles:_original.._value", dynPostInstallFiles_all);
		allPostInstallFiles = dynPostInstallFiles_all;
		return 0;
	} else {
		dynClear(allPostInstallFiles);
		return -1;
	}
}


/** This function gets a specified section into a dyn_string

@param section: string to define the section 
@param configEntry: dyn_string that will contain the lines for the section
@return 0 - "success"  -1 - error  -2 - section does not exist
@author S. Schmeling
*/

int fwInstallation_getSection( string section, dyn_string & configEntry )
{ 
	dyn_string configLines;
	
	dyn_string tempLines;
	string tempLine;
	int i,j;
	bool sectionFound = FALSE;
	
	string configPath = getPath(CONFIG_REL_PATH);
	string configFile = configPath + "config";

	if(_fwInstallation_getConfigFile(configLines) == 0)
	{
		for (i=1; i<=dynlen(configLines); i++)
		{
			tempLine = configLines[i];
			if(strpos(strltrim(strrtrim(tempLine)), "["+section+"]") == 0)
			{
				if(sectionFound == FALSE)
				{
					sectionFound = TRUE;
				}
				j = 1;
				do
				{
					if(i+j <= dynlen(configLines))
					{
						tempLine = configLines[i+j];
						if(strpos(strltrim(strrtrim(tempLine)),"[") != 0)
						{
//							if(tempLine != "")
//							{
							dynAppend(tempLines,tempLine);
//							}
							j++;
						}
					}
				}
				while ((strpos(strltrim(strrtrim(tempLine)),"[") != 0) && (i+j <=dynlen(configLines)));
				i += j-1;
			}
		}
		if(sectionFound == TRUE)
		{
			configEntry = tempLines;
			return 0;
		} else {
			return -2;
		}
	} else {
		return -1;
	}
}


/** This function sets a specified section from a dyn_string

@param section: string to define the section to where the data has to written
@param configEntry: dyn_string that contains the lines for the section
@return 0 - "success"  -1 - error
@author S. Schmeling
*/

int fwInstallation_setSection( string section, dyn_string configEntry )
{
	if(fwInstallation_clearSection( section ) != -1)
	{
		return fwInstallation_addToSection( section, configEntry );	
	} else {
		return -1;
	}
}


/** This function will delete all entries of the specified section as well as all but the first header.

@param section: string to define the section which will be cleared (first header will stay)
@return 0 - "success"  -1 - error  -2 - section does not exist
@author S. Schmeling
*/

int fwInstallation_clearSection( string section )
{
	dyn_string configLines;
	dyn_int tempPositions;
	dyn_string tempLines;
	string tempLine;
	int i,j;
	bool sectionFound = FALSE;
	
	string configPath = getPath(CONFIG_REL_PATH);
	string configFile = configPath + "config";

	if(_fwInstallation_getConfigFile(configLines) == 0)
	{
		for (i=1; i<=dynlen(configLines); i++)
		{
			tempLine = configLines[i];
			if(strpos(strltrim(strrtrim(tempLine)), "["+section+"]") == 0)
			{
				if(sectionFound == FALSE)
				{
					sectionFound = TRUE;
				} else {
					dynAppend(tempPositions,i);
				}
				if(i < dynlen(configLines))
				{
					j = 1;
					do
					{
						tempLine = configLines[i+j];
						if(strpos(strltrim(strrtrim(tempLine)),"[") != 0)
						{
							dynAppend(tempPositions,i+j);
							if(tempLine != "")
							{
								dynAppend(tempLines,tempLine);
							}
							j++;
						}
					}
					while ((strpos(strltrim(strrtrim(tempLine)),"[") != 0) && (i+j <=dynlen(configLines)));
					i += j-1;
				}
			}
		}
		if(dynlen(tempPositions)>0)
		{
			for (i=dynlen(tempPositions); i>0; i--)
			{
				dynRemove(configLines, tempPositions[i]);
			}
		}			
		if(sectionFound == TRUE)
		{
			return fwInstallation_saveFile(configLines, configFile);
		} else {
			return -2;
		}
	} else {
		return -1;
	}
}

/** This function adds the given lines to a section in the config file.

@param section: string to define the section where the data has to be added (will be created if not existing)
@param configEntry: dyn_string containing the lines to be added
@return 0 - "success"  -1 - error 
@author S. Schmeling
*/
int fwInstallation_addToSection( string section, dyn_string configEntry )
{
	dyn_string configLines;
	
	dyn_int tempPositions;
	dyn_string tempLines;
	string tempLine;
	int i,j;
	bool sectionFound = FALSE;
	
	string configPath = getPath(CONFIG_REL_PATH);
	string configFile = configPath + "config";

	j = -1;

	if(_fwInstallation_getConfigFile(configLines) == 0)
	{
		for (i=1; i<=dynlen(configLines); i++)
		{
			tempLine = configLines[i];
			if(strpos(strltrim(strrtrim(tempLine)), "["+section+"]") == 0)
			{
				j = i;
				break;
			}
		}
		tempLines = configEntry;
		if(j > 0)
		{
			if(j+1 <= dynlen(configLines))
				dynInsertAt(configLines,tempLines,j+1);
			else
				dynAppend(configLines,tempLines);			
		} else {
			tempLine = "[" + section + "]";
			dynInsertAt(tempLines,tempLine,1);
			dynAppend(configLines,tempLines);
		}
		return fwInstallation_saveFile(configLines, configFile);
	} else {
		return -1;
	}
}
