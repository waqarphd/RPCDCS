global mapping CMSfwFSMConfigDB_abort;
global mapping CMSfwFSMConfigDB_inProgress;

const string CMSfwFSMConfigDB_CONFIGURATOR = "CMSfwFSMConfigurator";
const string CMSfwFSMConfigDB_CONFIG_DP = "CMSfwFSMConfigDB_config";

const string CMSfwFSMConfigDB_CONFIGURATOR_STATE          = ".state";
const string CMSfwFSMConfigDB_CONFIGURATOR_MODE           = ".mode";

const string CMSfwFSMConfigDB_CONFIGURATOR_COMMAND    = ".sendCommand.command";
const string CMSfwFSMConfigDB_CONFIGURATOR_PARAMETER  = ".sendCommand.parameter";

const string CMSfwFSMConfigDB_CONFIGURATOR_VERIFY_DELAY         = ".configuration.verifyDelay";
const string CMSfwFSMConfigDB_CONFIGURATOR_VERIFY_RETRIES       = ".configuration.verifyRetries";
const string CMSfwFSMConfigDB_CONFIGURATOR_TOLERANCE            = ".configuration.floatTolerance";
const string CMSfwFSMConfigDB_CONFIGURATOR_RECIPE_NAME          = ".configuration.recipeName";
const string CMSfwFSMConfigDB_CONFIGURATOR_UPDATE_CACHE         = ".configuration.updateRecipeCache";
const string CMSfwFSMConfigDB_CONFIGURATOR_SETTINGS_MAP         = ".configuration.settingsDpes";
const string CMSfwFSMConfigDB_CONFIGURATOR_READBACK_MAP         = ".configuration.readbackDpes";
const string CMSfwFSMConfigDB_CONFIGURATOR_SHOW_ALL_STATES      = ".configuration.showIntermediateStates";
const string CMSfwFSMConfigDB_CONFIGURATOR_USE_MODIFIED      = ".configuration.useModified";
const string CMSfwFSMConfigDB_CONFIGURATOR_PERIODIC_VERIFY      = ".configuration.periodicVerify";
const string CMSfwFSMConfigDB_CONFIGURATOR_PERIODIC_CACHE_CHECK = ".configuration.periodicCacheCheck";

const string CMSfwFSMConfigDB_CONFIGURATOR_STATUS_LATEST           = ".status.latestResult";
const string CMSfwFSMConfigDB_CONFIGURATOR_STATUS_APPLIED_RECIPE   = ".status.appliedRecipe";
const string CMSfwFSMConfigDB_CONFIGURATOR_STATUS_VERIFY_FAIL      = ".status.verifyFailed";
const string CMSfwFSMConfigDB_CONFIGURATOR_STATUS_CACHE_VALIDITY   = ".status.cacheValidity";

const string CMSfwFSMConfigDB_CONFIGURATOR_DEBUG                   = ".debug.debugMode";
const string CMSfwFSMConfigDB_CONFIGURATOR_DEBUG_FAILED_DPES       = ".debug.verifyFailureDpes";
const string CMSfwFSMConfigDB_CONFIGURATOR_DEBUG_SETTING_DPES      = ".debug.recipeSettingDpes";
const string CMSfwFSMConfigDB_CONFIGURATOR_DEBUG_SETTING_VALUES    = ".debug.recipeSettingValues";
const string CMSfwFSMConfigDB_CONFIGURATOR_DEBUG_READBACK_DPES     = ".debug.verifyReadbackDpes";
const string CMSfwFSMConfigDB_CONFIGURATOR_DEBUG_READBACK_VALUES   = ".debug.verifyReadbackValues";


void CMSfwFSMConfigDB_configure(dyn_string libraries, bool useCache, string systemName = "") {
 dpSet(systemName + CMSfwFSMConfigDB_CONFIG_DP + ".librariesToLoad", libraries,
      systemName + CMSfwFSMConfigDB_CONFIG_DP + ".useCacheInsteadOfDb", useCache);
}

void CMSfwFSMConfigDB_startRecipeMonitor()
{
  DebugTN("CMS Recipe Manager: initialising");

  dyn_string libraries;
  if(dpExists(CMSfwFSMConfigDB_CONFIG_DP))
    dpGet(CMSfwFSMConfigDB_CONFIG_DP + ".librariesToLoad", libraries);  

  for(int i=1; i<=dynlen(libraries); i++)
  {
    DebugTN("CMS Recipe Manager: loading user library - " + libraries[i]);
    execScript("#uses \"" + libraries[i] + "\" main(){}", makeDynString());
  }  
  
  dpQueryConnectSingle("CMSfwFSMConfigDB_configuratorSetup", TRUE, "connect", "SELECT '_smooth.._type' FROM '*.' WHERE _DPT = \"" + CMSfwFSMConfigDB_CONFIGURATOR + "\"");

  DebugTN("CMS Recipe Manager: initialisation complete");
}

CMSfwFSMConfigDB_configuratorSetup(string identifier, dyn_dyn_mixed queryResults)
{
  int length = dynlen(queryResults);
  dyn_string aObjs;

  for(int i=2; i<=length; i++)
  {
    string configurator = dpSubStr(queryResults[i][1], DPSUB_DP);
    CMSfwFSMConfigDB_abort[configurator] = "OK";
//DebugN(configurator);
    dpConnect("CMSfwFSMConfigDB_executeCommand", false, configurator + CMSfwFSMConfigDB_CONFIGURATOR_COMMAND, configurator + CMSfwFSMConfigDB_CONFIGURATOR_PARAMETER);
    startThread("CMSfwFSMConfigDB_verifyHwCacheConsistencyThread", configurator);
    startThread("CMSfwFSMConfigDB_verifyCacheDbConsistencyThread", configurator);
  }
}

void CMSfwFSMConfigDB_executeCommand(string device, string command, string device2, string parameter) {
  device = dpSubStr(device, DPSUB_DP);
  DebugN("Executing ", command, parameter, " on " , device);
  
  if (command == "LOAD")
  {
    switch(parameter)
    {
      case "NO_CONFIG":
        CMSfwFSMConfigDB_setConfiguratorState(device, "LOADED");
        break;
      default:
        CMSfwFSMConfigDB_abort[device] = "LOAD";
        startThread("CMSfwFSMConfigDB_DULoad",device,parameter);
        break;
    }
  }
  if (command == "RELOAD")
  {
    string sMode;
    CMSfwFSMConfigDB_abort[device] = "LOAD";
    dpGet(device + CMSfwFSMConfigDB_CONFIGURATOR_MODE, sMode);
    startThread("CMSfwFSMConfigDB_DULoad",device,sMode);
  }
  else if(command == "ABORT")
  {
    CMSfwFSMConfigDB_abort[device] = "ABORT";
    // maybe we should try to stop the thread !!!
    CMSfwFSMConfigDB_setConfiguratorState(device, "NOT_READY", "Aborted by user");
  }
  else if(command == "VERIFY")
  {
    CMSfwFSMConfigDB_setConfiguratorState(device, "VERIFYING");
    bool result = CMSfwFSMConfigDB_verify(device);
//    DebugN("Verify result "+ result);
  }
   else if (command == "SAVE_FROM_HW") {
     dyn_string spl = strsplit(parameter, ",");
     bool saveCache = true; bool saveDB = false;
     string sMode = spl[1];
     if (dynlen(spl)>=2) {
         saveCache = (spl[2] == "true");         
     }
     if (dynlen(spl)>=3) {
         saveDB = (spl[3] == "true");         
     }     
          
     startThread("CMSfwFSMConfigDB_saveFromHw", device, sMode, saveCache, saveDB)  ;               
  }
}

void CMSfwFSMConfigDB_saveFromHw(string device, string sMode, bool saveCache, bool saveDB) {
  dyn_string exceptionInfo;
   if(isFunctionDefined("CMSfwFSMConfigDB_User_extractRecipeFromHw"))
   {
     string what = "";
     if (saveCache && saveDB) what  = "cache/db";
     else {
         if (saveCache) what = "cache";
         if (saveDB) what = "db";
     }
     dyn_dyn_mixed recipeObject; string sRecipe;
      bool bExtract = CMSfwFSMConfigDB_User_extractRecipeFromHw(device, sMode, recipeObject, sRecipe);
      if (bExtract) {
          bool bSave = CMSfwFSMConfigDB_saveRecipeObjectToCacheAndDb(sRecipe, recipeObject, saveCache, saveDB, exceptionInfo);
          if (bSave) {
            dpSetWait(device + CMSfwFSMConfigDB_CONFIGURATOR_MODE, sMode);
            CMSfwFSMConfigDB_setConfiguratorState(device,"","Saved to " + what + " successfully");
          } else {
            CMSfwFSMConfigDB_setConfiguratorState(device,"","Error in saving recipe to " + what );
          }
      } else {
          CMSfwFSMConfigDB_setConfiguratorState(device,"","Error in extracting recipe from " + what );            
      }
      

    } else{
      CMSfwFSMConfigDB_setConfiguratorState(device,"","Error : function CMSfwFSMConfigDB_User_extractRecipeFromHw is not defined");            
    }
                   
}


bool CMSfwFSMConfigDB_saveRecipeObjectToCacheAndDb(string sRecipe, dyn_dyn_mixed& recipeObject, bool saveCache, bool saveDB, dyn_string& exceptionInfo) {
  if (saveCache) {

    fwConfigurationDB_saveRecipeToCache(recipeObject,"",sRecipe,exceptionInfo);
    if (dynlen(exceptionInfo) > 0) {
        DebugN("Exception in save recipe to cache", exceptionInfo);
      return false; 
    }
  }
  if(saveDB){
    fwDevice_getName(sRecipe,sRecipe,exceptionInfo);
    DebugN("Saving to db with name " + sRecipe);
    /* hierarchy is dummy */
    fwConfigurationDB_saveRecipeToDB(recipeObject,fwDevice_LOGICAL,sRecipe, exceptionInfo);

    if (dynlen(exceptionInfo) >0) {
        DebugTN("Exc in store recipe to db ", exceptionInfo);
      return false;
    }
  }  
  
  return true;
}

bool CMSfwFSMConfigDB_executeSaveToCacheOrDb(string configDp, string sMode, bool saveCache, bool saveDB, time timeout = 600) {
    string parameter = sMode + "," + ((saveCache)?"true":"false")  + "," + ((saveDB)?"true":"false");
    dpSetWait(configDp + CMSfwFSMConfigDB_CONFIGURATOR_COMMAND, "SAVE_FROM_HW",
              configDp + CMSfwFSMConfigDB_CONFIGURATOR_PARAMETER, parameter); 
     
  bool timerExpired;
  dyn_anytype condition;
  dyn_anytype returnValues;
  //  DebugN("Waiting for feedback");
 
  dyn_string waitVal = makeDynString(configDp + CMSfwFSMConfigDB_CONFIGURATOR_STATUS_LATEST + ":_original.._value");
  if (dpWaitForValue(waitVal,condition, 
		     waitVal, returnValues, timeout, timerExpired) == -1) {
    DebugN("Error in dpWaitForValue");
    return false;
  }
  if (timerExpired) {
    DebugN("Error: timeout expired");
    return false;
  }
  if (strpos(((string) returnValues[1]), "successfully")>=0) {
      return true;
  } 
  return false;
}

void CMSfwFSMConfigDB_verifyHwCacheConsistencyThread(string sDeviceDp) 
{
//  DebugN("Starting monitor Thread for " + sPartition);
  int periodicVerify = 0;
  if (! dpExists(sDeviceDp) ) {
      DebugTN("Dp deleted ", sDeviceDp); return;
  }
  while(periodicVerify <= 0)
  {
    delay(60);
    CMSfwFSMConfigDB_getPeriodicVerifyTime(sDeviceDp, periodicVerify);
  }

  //try to stagger verify loops - delay here can be between 0 and ~60 seconds
  delay(rand()/500.0);

  int result;
  while(true)
  {
   if (! dpExists(sDeviceDp) ) {
      DebugTN("Dp deleted ", sDeviceDp); return;
    }
    CMSfwFSMConfigDB_setConfiguratorState(sDeviceDp, "VERIFYING");
    result = CMSfwFSMConfigDB_verify(sDeviceDp);
    
    CMSfwFSMConfigDB_getPeriodicVerifyTime(sDeviceDp, periodicVerify);
    delay(periodicVerify*60);
  }
}  

void CMSfwFSMConfigDB_verifyCacheDbConsistencyThread(string sDeviceDp) 
{
//  DebugN("Starting monitor Thread for " + sPartition);
  if (! dpExists(sDeviceDp) ) {
      DebugTN("Dp deleted ", sDeviceDp); return;
  }
  int periodicVerify = 0;
  
  while(periodicVerify <= 0)
  {
    delay(60);
    CMSfwFSMConfigDB_getCacheValidityVerifyTime(sDeviceDp, periodicVerify);
  }

  //try to stagger verify loops - delay here can be between 60 and ~120 seconds
  delay(60 + rand()/500.0);

  int result;
  while(true)
  {
    if (! dpExists(sDeviceDp) ) {
      DebugTN("Dp deleted ", sDeviceDp); return;
    }
    result = CMSfwFSMConfigDB_checkCache(sDeviceDp);
    
    CMSfwFSMConfigDB_getCacheValidityVerifyTime(sDeviceDp, periodicVerify);
    delay(periodicVerify*60);
  }
} 

int CMSfwFSMConfigDB_checkCache(string sDeviceDp)
{
  dyn_string badRecipes, recipes, recipeList, exceptionInfo;

  fwConfigurationDB_getRecipesInCache(recipeList, exceptionInfo);
  recipes = dynPatternMatch(sDeviceDp + "/*", recipeList);

  for(int i=1; i<=dynlen(recipes); i++)
  {
    bool result;
    dyn_string localException;
    dyn_dyn_mixed diffObject, dbRecipeObject, cacheRecipeObject;
    string sRecipeName = recipes[i];

    fwConfigurationDB_getRecipeFromCache(sRecipeName,"",fwDevice_HARDWARE,cacheRecipeObject,localException);

    strreplace(sRecipeName, sDeviceDp + "/", "");
    result = CMSfwFSMConfigDB_copyDBtoMemory(sDeviceDp, sRecipeName, dbRecipeObject, localException);
    if(!result)
    {
//      DebugTN("Cache validity check for " + sDeviceDp + " aborted - " + sRecipeName + " recipe could not be loaded");
      //if no connection, just report error but do not indicate problem with recipe validity
      continue;
    }

    if (dynlen(localException) > 0)
    {
      DebugN(localException);
      continue;
    }

    bool bDiffs;
    bDiffs = fwConfigurationDB_compareRecipes(cacheRecipeObject, dbRecipeObject, diffObject, fwDevice_HARDWARE, exceptionInfo);
    
    if(bDiffs)
    {
      dynAppend(badRecipes, sRecipeName);
    }
  }
//DebugN(badRecipes);
  string list;
  fwGeneral_dynStringToString(badRecipes, list, " and ");
  if(dynlen(badRecipes) == 0)
  {
    dpSet(sDeviceDp + CMSfwFSMConfigDB_CONFIGURATOR_STATUS_CACHE_VALIDITY, TRUE);
//    DebugTN("Cache validity check for " + sDeviceDp + " - no cache inconsistencies found");
    return TRUE;
  }
  else
  {
    dpSet(sDeviceDp + CMSfwFSMConfigDB_CONFIGURATOR_STATUS_CACHE_VALIDITY, FALSE);
//    DebugTN("Cache validity check for " + sDeviceDp + " - cached recipe " + list + " different from DB");
    return FALSE;
  }
}


int CMSfwFSMConfigDB_verify(string sDeviceDp) {
  bool recipeInCache;
  string sRecipeName="";
  string sSystemName = strrtrim(getSystemName(),":");
  string sMode="";
  
  dpGet(sDeviceDp + CMSfwFSMConfigDB_CONFIGURATOR_MODE, sMode);
  if(sMode == "") {
    CMSfwFSMConfigDB_setConfiguratorState(sDeviceDp, "NOT_READY", "No mode is set");
    return 1;
  }
  
  //skip verify if action is in progress, wait until next period
  //DebugTN(CMSfwFSMConfigDB_inProgress, dpSubStr(sDeviceDp, DPSUB_DP));
  if(mappingHasKey(CMSfwFSMConfigDB_inProgress, dpSubStr(sDeviceDp, DPSUB_DP)))
  {
    //DebugN("skipping if this is true:", CMSfwFSMConfigDB_inProgress[dpSubStr(sDeviceDp, DPSUB_DP)]);
    if(CMSfwFSMConfigDB_inProgress[dpSubStr(sDeviceDp, DPSUB_DP)])
      return 1;
  }
  
  CMSfwFSMConfigDB_getRecipeName(sDeviceDp, sMode, sRecipeName);

  recipeInCache = CMSfwFSMConfigDB_checkRecipeInCache(sDeviceDp, sRecipeName);
  if(!recipeInCache)
  {
      CMSfwFSMConfigDB_setConfiguratorState(sDeviceDp, "NOT_READY", "Recipe " +  sRecipeName + " recipe could not be cached");
//    DebugTN("Periodic verify for " + sDeviceDp + " aborted - " + sRecipeName + " recipe could not be cached");
    return -1;
  }

//DebugN("Name of the recipe to verify: " + sRecipeName);

  dyn_string exceptionInfo;
  dyn_dyn_mixed recipeObject, recipeDiff, recipeDiffAlerts;
    
  bool result;
  result = CMSfwFSMConfigDB_copyCachetoMemory(sDeviceDp, sRecipeName, recipeObject, exceptionInfo);
  if(!result)
  {
//    DebugTN("Periodic verify for " + sDeviceDp + " aborted - cached recipe " + sRecipeName + " could not be loaded");
    return -1;
  }

  if (dynlen(exceptionInfo) > 0)
  {
    DebugN(exceptionInfo);
    return -1;
  }
  
  bool bVerify;
      
  bVerify = CMSfwFSMConfigDB_verifyReadback(sDeviceDp,recipeObject,recipeDiff);
  bool bVerifyAlerts= CMSfwFSMConfigDB_verifyAlerts(sDeviceDp, recipeObject, recipeDiffAlerts, exceptionInfo);
  
 // DebugTN("Verify readback result " + bVerify, "Verify alerts result = " + bVerifyAlerts);

  if (dynlen(exceptionInfo) >0) {
      DebugTN("Exc in verifying alerts ", exceptionInfo);
      CMSfwFSMConfigDB_setConfiguratorState(sDeviceDp, "NOT_READY", "Exception in verifying alerts for " +  sRecipeName );
      return -1;
  }
      
      
  
  if(!( bVerify && bVerifyAlerts))
  {
    string what = ""; 
    if (!bVerify) what = "Readback";
    if (!bVerifyAlerts) {
        if (strlen(what) > 0) what += " and ";
        what+= "Alert";        
    }
    CMSfwFSMConfigDB_setConfiguratorState(sDeviceDp, "MODIFIED", what + " verification failed");
    dpSet(sDeviceDp + CMSfwFSMConfigDB_CONFIGURATOR_STATUS_VERIFY_FAIL, TRUE);
//    DebugTN("Periodic verify of " + sDeviceDp + " with recipe " + sRecipeName + " - failed");
  }
  else
  {
    CMSfwFSMConfigDB_setConfiguratorState(sDeviceDp, "LOADED", "Periodic verify OK");
    dpSet(sDeviceDp + CMSfwFSMConfigDB_CONFIGURATOR_STATUS_VERIFY_FAIL, FALSE);
//    DebugTN("Periodic verify of " + sDeviceDp + " with recipe " + sRecipeName + " - OK");
  }

  bool debugMode;
  CMSfwFSMConfigDB_getDebugMode(sDeviceDp, debugMode);

  
  if(debugMode) {
    if (dynlen(recipeDiffAlerts) > 0) {
        for (int i=1; i<= dynlen(recipeDiffAlerts[1]); i++) {
          recipeDiffAlerts[1][i] += " alert";
        }   
        dynAppend(recipeDiff[3], recipeDiffAlerts[1]);
    }
    dpSet(sDeviceDp + CMSfwFSMConfigDB_CONFIGURATOR_DEBUG_FAILED_DPES, dynlen(recipeDiff)?recipeDiff[3]:makeDynString());  
  }

  return bVerify;
}

bool CMSfwFSMConfigDB_copyDBtoCache(string sDeviceDp, string sRecipeName, dyn_string &exceptionInfo)
{
  dyn_dyn_mixed recipeObject;
  bool result;  
  
  result = CMSfwFSMConfigDB_copyDBtoMemory(sDeviceDp, sRecipeName, recipeObject, exceptionInfo);
  if(!result)
    return false;
  
  fwConfigurationDB_createRecipeCache(sDeviceDp + "/" + sRecipeName,exceptionInfo);
  fwConfigurationDB_storeRecipeInCache(recipeObject, sDeviceDp + "/" + sRecipeName, fwDevice_HARDWARE, exceptionInfo);
  dpSet(sDeviceDp + CMSfwFSMConfigDB_CONFIGURATOR_STATUS_CACHE_VALIDITY, TRUE);
  
  return true;
}

synchronized bool CMSfwFSMConfigDB_copyDBtoMemory(string sDeviceDp, string sRecipeName, dyn_dyn_mixed &recipeObject, dyn_string &exceptionInfo)
{
  bool useCache;
  dyn_string recipeList;
  
  dynClear(recipeObject);

  if(dpExists(CMSfwFSMConfigDB_CONFIG_DP))
    dpGet(CMSfwFSMConfigDB_CONFIG_DP + ".useCacheInsteadOfDb", useCache);  

//DebugN("CMSfwFSMConfigDB_copyDBtoMemory", useCache);
  if(!useCache)
  {
    fwConfigurationDB_initialize("", exceptionInfo);
    if(dynlen(exceptionInfo) > 0)
      return false;
  }

  if(useCache)  
    fwConfigurationDB_getRecipesInCache(recipeList, exceptionInfo);
  else
    fwConfigurationDB_getRecipesInDB(recipeList, exceptionInfo);

  if (! dynContains(recipeList, sRecipeName)) {
    string source = useCache?"Cache":"DB";
//    DebugTN("Recipe " + sRecipeName + " not found in " + source);
    return false;
  }
  
//DebugN("CMSfwFSMConfigDB_copyDBtoMemory", "Recipe found: " + sRecipeName);
  if(useCache)  
    fwConfigurationDB_getRecipeFromCache(sRecipeName,"",fwDevice_HARDWARE,recipeObject,exceptionInfo);
  else
    fwConfigurationDB_getRecipeFromDB("","",fwDevice_HARDWARE,sRecipeName,recipeObject,exceptionInfo);

  return true;
}

bool CMSfwFSMConfigDB_copyCachetoMemory(string sDeviceDp, string sRecipeName, dyn_dyn_mixed &recipeObject, dyn_string &exceptionInfo, dyn_string deviceList = makeDynString() , string sSystem = "")
{
  dyn_string recipeList;
  
  dynClear(recipeObject);
  fwConfigurationDB_getRecipesInCache(recipeList, exceptionInfo,"", sSystem);

  //DebugN("Recipes in db ", recipeList);
  if (! dynContains(recipeList, sSystem + sDeviceDp + "/" + sRecipeName)) {
    DebugTN("Recipe " + sSystem + sDeviceDp + "/" + sRecipeName + " not found in cache", recipeList);
    return false;
  }
  
  fwConfigurationDB_getRecipeFromCache(sSystem + sDeviceDp + "/" + sRecipeName,deviceList,fwDevice_HARDWARE,recipeObject,exceptionInfo);

  //WORKAROUND - next code covers the case where the recipe object contains
  //items where the dpes are not resolved from the alias names
  for(int i=dynlen(recipeObject[fwConfigurationDB_RO_DPE_NAME]); i>0; i--)
  {
    if(recipeObject[fwConfigurationDB_RO_DPE_NAME][i] == "")
    {
      for(int j=1; j<=dynlen(recipeObject); j++)
        dynRemove(recipeObject[j], i);
    }
  }
  if(dynlen(recipeObject[fwConfigurationDB_RO_DPE_NAME]) <= 0) {
    DebugN("0 dpe names in recipe");
    return false;
  }
  //END OF WORKAROUND
    
  //adapt all items in recipe to local system name

  if (sSystem == "") sSystem = getSystemName();
  
  fwConfigurationDB_adoptRecipeObjectToSystem(recipeObject,sSystem, exceptionInfo);  
  if (dynlen(exceptionInfo)) 
  { 
    DebugTN("Configuration DB failed to execute: fwConfigurationDB_adoptRecipeObjectToSystem :"+exceptionInfo);   
    return false; 
  }
  
  //WORKAROUND - fix problem of applying to devices that do not exist
  for(int i=dynlen(recipeObject[fwConfigurationDB_RO_DPE_NAME]); i>0; i--)
  {
    if(!dpExists(recipeObject[fwConfigurationDB_RO_DPE_NAME][i]))
    {
      //DebugTN("Removing not existing ", recipeObject[fwConfigurationDB_RO_DPE_NAME][i]);
      for(int j=1; j<=dynlen(recipeObject); j++)
        dynRemove(recipeObject[j], i);
    }
  }
  if(dynlen(recipeObject[fwConfigurationDB_RO_DPE_NAME]) <= 0) {
     DebugN("0 dpe names in recipe after workaround 2");
    return false;
  }
  //END OF WORKAROUND

  return true;
}

CMSfwFSMConfigDB_clearCache(string sDeviceDp)
{
  dyn_string cachedRecipes;
  
  cachedRecipes = dpNames("RecipeCache/" + sDeviceDp + "/*");
  
  for(int i=1; i<=dynlen(cachedRecipes); i++)
    dpDelete(cachedRecipes[i]);

  dpSet(sDeviceDp + CMSfwFSMConfigDB_CONFIGURATOR_UPDATE_CACHE, FALSE);
}


CMSfwFSMConfigDB_getSettingReadbackMapping(string sDeviceDp, dyn_string dpElementNames, dyn_string dpTypeNames, dyn_string &settingsDpeMap, dyn_string &readbackDpeMap)
{
  bool useDefault = true;
  if(isFunctionDefined("CMSfwFSMConfigDB_User_getSettingReadbackMapping"))
  {
    CMSfwFSMConfigDB_User_getSettingReadbackMapping(sDeviceDp, dpElementNames, dpTypeNames, settingsDpeMap, readbackDpeMap, useDefault);
  }
  if (useDefault) 
  {
    dpGet(sDeviceDp + CMSfwFSMConfigDB_CONFIGURATOR_SETTINGS_MAP, settingsDpeMap,
          sDeviceDp + CMSfwFSMConfigDB_CONFIGURATOR_READBACK_MAP, readbackDpeMap);
    
    if(settingsDpeMap == makeDynString())
    {
      _CMSfwFSMConfigDB_getSettingReadbackMappingDefaults(dpElementNames, dpTypeNames, settingsDpeMap, readbackDpeMap);
    }
  }
}

_CMSfwFSMConfigDB_getSettingReadbackMappingDefaults(dyn_string dpElementNames, dyn_string dpTypeNames, dyn_string &settingsDpeMap, dyn_string &readbackDpeMap)
{
  dyn_string tempSettings, tempReadback;
  mapping settingsSpecificity, readbackSpecificity;
  
  dynUnique(dpTypeNames);
  dynClear(settingsDpeMap);  
  dynClear(readbackDpeMap);  
  
  for(int i=1; i<=dynlen(dpTypeNames); i++)
  {
    switch(dpTypeNames[i])
    {
      case "FwCaenChannel":
        dynAppend(tempSettings, "*.settings.*");
        dynAppend(tempReadback, "*.readBackSettings.*");
        break;
      case "FwWienerChannel":
        dynAppend(tempSettings, "*.Settings.*");
        dynAppend(tempReadback, "*.ReadBackSettings.*");
        break;
      case "FwWienerMarathon":
        dynAppend(tempSettings, "*.Sensor.*.Settings.*");
        dynAppend(tempReadback, "*.Sensor.*.ReadBackSettings.*");
        dynAppend(tempSettings, "*.Temperature.*.Settings.*");
        dynAppend(tempReadback, "*.Temperature.*.ReadBackSettings.*");
        break;
      case "FwWienerMarathonChannel":
        dynAppend(tempSettings, "*.Settings.*");
        dynAppend(tempReadback, "*.ReadbackSettings.*");
        break;
      case "FwAio":
      case "FwDio":
        dynAppend(tempSettings, "*.outValue");
        dynAppend(tempReadback, "*.inValue");
        break;
    }
  }

//DebugN(tempSettings, tempReadback);
  
  //assign each mapping dependant on it's specificity
  //(i.e. how many * it has to determine how many parts of elements are defined)
  //more * means more specific
  for(int i=1; i<=dynlen(tempSettings); i++)
  {
    int specificity = dynlen(strsplit(tempSettings[i], "*"));
    
    if(!mappingHasKey(settingsSpecificity, specificity))
      settingsSpecificity[specificity] = makeDynString();
    if(!mappingHasKey(readbackSpecificity, specificity))
      readbackSpecificity[specificity] = makeDynString();
    
    dynAppend(settingsSpecificity[specificity], tempSettings[i]);
    dynAppend(readbackSpecificity[specificity], tempReadback[i]);
  }
  
//DebugN(settingsSpecificity, readbackSpecificity);
  
  //sort the setting/readback mappings according to specificity
  //this ensure that the most specific cases are checked first
  //this avoids matching with less specific criteria first
  //which leads to the more specific criteria never being tested
  dyn_int keys;
  keys = mappingKeys(settingsSpecificity);
  dynSortAsc(keys);
  for(int i=dynlen(keys); i>0; i--)
  {
    dynAppend(settingsDpeMap, settingsSpecificity[keys[i]]);
    dynAppend(readbackDpeMap, readbackSpecificity[keys[i]]);
  }

//DebugN(settingsDpeMap, readbackDpeMap);
}

CMSfwFSMConfigDB_getDebugMode(string sDeviceDp, bool &debugMode)
{
  dpGet(sDeviceDp + CMSfwFSMConfigDB_CONFIGURATOR_DEBUG, debugMode);   
}

CMSfwFSMConfigDB_getCacheValidityVerifyTime(string sDeviceDp, int &periodicVerify)
{
  if(isFunctionDefined("CMSfwFSMConfigDB_User_getPeriodicCacheCheckTime"))
  {
    CMSfwFSMConfigDB_User_getPeriodicVerifyTime(sDeviceDp, periodicVerify);
  }
  else
  {
    dpGet(sDeviceDp + CMSfwFSMConfigDB_CONFIGURATOR_PERIODIC_CACHE_CHECK, periodicVerify); 
  }
}

CMSfwFSMConfigDB_getPeriodicVerifyTime(string sDeviceDp, int &periodicVerify)
{
  if(isFunctionDefined("CMSfwFSMConfigDB_User_getPeriodicVerifyTime"))
  {
    CMSfwFSMConfigDB_User_getPeriodicVerifyTime(sDeviceDp, periodicVerify);
  }
  else
  {
    dpGet(sDeviceDp + CMSfwFSMConfigDB_CONFIGURATOR_PERIODIC_VERIFY, periodicVerify); 
  }
}

CMSfwFSMConfigDB_getVerifyOptions(string sDeviceDp, int &verifyRetries, int &verifyDelay)
{
  if(isFunctionDefined("CMSfwFSMConfigDB_User_getVerifyOptions"))
  {
    CMSfwFSMConfigDB_User_getVerifyOptions(sDeviceDp, verifyRetries, verifyDelay);
  }
  else
  {
    dpGet(sDeviceDp + CMSfwFSMConfigDB_CONFIGURATOR_VERIFY_DELAY, verifyDelay,
          sDeviceDp + CMSfwFSMConfigDB_CONFIGURATOR_VERIFY_RETRIES, verifyRetries);  
  }
}

CMSfwFSMConfigDB_getVerifyTolerance(string sDeviceDp, float &tolerance)
{
  if(isFunctionDefined("CMSfwFSMConfigDB_User_getVerifyTolerance"))
  {
    CMSfwFSMConfigDB_User_getVerifyTolerance(sDeviceDp, tolerance);
  }
  else
  {
    dpGet(sDeviceDp + CMSfwFSMConfigDB_CONFIGURATOR_TOLERANCE, tolerance);
  }
}

CMSfwFSMConfigDB_getRecipeName(string sDeviceDp, string sMode, string &sRecipeName)
{
  string sSystem = strrtrim(getSystemName(),":");

  if(isFunctionDefined("CMSfwFSMConfigDB_User_getRecipeName"))
  {
    CMSfwFSMConfigDB_User_getRecipeName(sDeviceDp, sMode, sRecipeName);
  }
  else
  { 
    dpGet(sDeviceDp + CMSfwFSMConfigDB_CONFIGURATOR_RECIPE_NAME, sRecipeName);
    if(sRecipeName != "")
    {
      mapping modeRecipeMap;
      dyn_string modes = strsplit(sRecipeName, ";");
      
      for(int i=1; i<=dynlen(modes); i++)
      {
        dyn_string tempMapping = strsplit(modes[i], ":");
        if(dynlen(tempMapping) == 2)
          modeRecipeMap[strtoupper(tempMapping[1])] = tempMapping[2];
        else
          modeRecipeMap[strtoupper(sMode)] = tempMapping[1];          
      }
        
      sRecipeName = modeRecipeMap[strtoupper(sMode)];
//DebugN(sRecipeName);
      strreplace(sRecipeName, "<mode>", sMode);
      strreplace(sRecipeName, "<system>", sSystem);
//DebugN(sRecipeName);
    }
    else
    {
    //if nothing defined, use tracker convention
      dyn_string sParts = strsplit(sDeviceDp,"_");
      string sPartition = sParts[2];
      sRecipeName = sSystem+"_"+sPartition+"_"+ sMode;
    }
  }
}

bool CMSfwFSMConfigDB_checkRecipeInCache(string sDeviceDp, string sRecipeName)
{
  bool updateCache;
  dyn_string exceptionInfo;
  dpGet(sDeviceDp + CMSfwFSMConfigDB_CONFIGURATOR_UPDATE_CACHE, updateCache);
 // DebugTN("CMS Recipe Manager: check recipe in cache " + "RecipeCache/" + sDeviceDp + "/" + sRecipeName);
  
  if(dpExists("RecipeCache/" + sDeviceDp + "/" + sRecipeName))
  {
    if(updateCache)
    {
      CMSfwFSMConfigDB_clearCache(sDeviceDp);
      if(!CMSfwFSMConfigDB_copyDBtoCache(sDeviceDp, sRecipeName, exceptionInfo))
      {
      DebugTN("CMS Recipe Manager: Recipe could not be loaded from ConfigDB, force refresh of recipes will be postponed until DB is available");
        return false;
      }
    }
  }
  else
  {
    if(!CMSfwFSMConfigDB_copyDBtoCache(sDeviceDp, sRecipeName, exceptionInfo))
    {
      DebugTN("CMS Recipe Manager: Recipe could not be loaded from ConfigDB, recipe is not currently cached");
      return false;
    }
  }

  return true;
}  
  

void CMSfwFSMConfigDB_DULoad(string device,string mode)
{
  dyn_string exceptionInfo;
//  DebugTN("Configuring " + device + " in mode " + mode);
  dyn_dyn_mixed recipeDiff,recipeFromCache;
        
//  DebugN("CMSfwFSMConfigDB_DULoad",CMSfwFSMConfigDB_abort[device]);    
    
  CMSfwFSMConfigDB_inProgress[device] = true;    
  dpSet(device + CMSfwFSMConfigDB_CONFIGURATOR_MODE, mode);
 
  bool recipeInCache, applyResult;  
  string sRecipeName;
  CMSfwFSMConfigDB_getRecipeName(device, mode, sRecipeName);
  
  recipeInCache = CMSfwFSMConfigDB_checkRecipeInCache(device, sRecipeName);
  if(!recipeInCache)
  {
    CMSfwFSMConfigDB_setConfiguratorState(device, "NOT_READY", "Recipe \"" + sRecipeName + "\" could not be cached");
    CMSfwFSMConfigDB_inProgress[device] = false;    
    return;
  }

  if (CMSfwFSMConfigDB_abort[device] == "ABORT") {
    CMSfwFSMConfigDB_setConfiguratorState(device, "NOT_READY", "Aborted by user");
    CMSfwFSMConfigDB_inProgress[device] = false;    
    return;
  }

  CMSfwFSMConfigDB_setConfiguratorState(device, "CONFIGURING");
  
  if(isFunctionDefined("CMSfwFSMConfigDB_User_preApplyRecipe"))
    CMSfwFSMConfigDB_User_preApplyRecipe(device, mode, sRecipeName, dpSubStr(device, DPSUB_SYS));  

  applyResult = CMSfwFSMConfigDB_applyRecipeFromCache(device,sRecipeName,recipeFromCache);
  dpSet(device + CMSfwFSMConfigDB_CONFIGURATOR_STATUS_APPLIED_RECIPE, sRecipeName);

  
  if(!applyResult)
  {
    CMSfwFSMConfigDB_setConfiguratorState(device, "NOT_READY", "Recipe was not applied successfully");
    DebugN("Recipe not applied successfully");
    CMSfwFSMConfigDB_inProgress[device] = false;    
    return;
  }
  if(isFunctionDefined("CMSfwFSMConfigDB_User_postApplyRecipe")) {
    applyResult = CMSfwFSMConfigDB_User_postApplyRecipe(device, mode, sRecipeName, recipeFromCache);  
    if (! applyResult) {
    CMSfwFSMConfigDB_setConfiguratorState(device, "NOT_READY", "Post apply Recipe returned problem");
//    DebugN("Recipe not applied successfully");
    CMSfwFSMConfigDB_inProgress[device] = false;    
    return;
        
    }
  }
  if (CMSfwFSMConfigDB_abort[device] == "ABORT") {
    CMSfwFSMConfigDB_setConfiguratorState(device, "NOT_READY", "Aborted by user");
    CMSfwFSMConfigDB_inProgress[device] = false;    
    return;
  }

  bool verifySet, verifyReadback, verifyAlerts;
  int delayBeforeVerify, retries;
    
  verifySet = CMSfwFSMConfigDB_verifySetting(device,recipeFromCache,recipeDiff);
  if(!verifySet)
  {
//    DebugTN("Verify of " + device + " with recipe " + sRecipeName + " - SETTING failed");
    dpSet(device + CMSfwFSMConfigDB_CONFIGURATOR_STATUS_VERIFY_FAIL, TRUE);
    CMSfwFSMConfigDB_setConfiguratorState(device, "NOT_READY", "Verificaton of setting of recipe failed");
    CMSfwFSMConfigDB_inProgress[device] = false;    
    return;
  }
  
  CMSfwFSMConfigDB_getVerifyOptions(device, retries, delayBeforeVerify);

  for(int i=1; i<=(retries+1); i++)
  {
//    DebugTN("Waiting for " + delayBeforeVerify + " seconds before checking readback, attempt: " + i + "/" + retries);

    //do not wait period on first check (maybe readback is already equal to setting)
    if(i!=1)
      delay(delayBeforeVerify);  

    CMSfwFSMConfigDB_setConfiguratorState(device, "VERIFYING");
  
    verifyReadback = CMSfwFSMConfigDB_verifyReadback(device,recipeFromCache,recipeDiff);
    
    bool debugMode;
    CMSfwFSMConfigDB_getDebugMode(device, debugMode);
    if(debugMode)
      dpSet(device + CMSfwFSMConfigDB_CONFIGURATOR_DEBUG_FAILED_DPES, dynlen(recipeDiff)?recipeDiff[3]:makeDynString());  

    if(!verifyReadback)
    {
      dyn_string dpesToSet = recipeDiff[1];
      dyn_mixed valuesToSet = recipeDiff[2];
      
//      DebugTN("Verify of " + device + " with recipe " + sRecipeName + " - READBACK failed");
      dpSet(device + CMSfwFSMConfigDB_CONFIGURATOR_STATUS_VERIFY_FAIL, TRUE);
      CMSfwFSMConfigDB_setConfiguratorState(device, "CONFIGURING");
      dpSet(dpesToSet, valuesToSet);
    }
    else
    {
      verifyAlerts = CMSfwFSMConfigDB_verifyAlerts(device, recipeFromCache, recipeDiff, exceptionInfo);
      if (dynlen(exceptionInfo)> 0) {
          DebugTN("Exception in verifying alerts ", exceptionInfo);
      }  
      if (! verifyAlerts ) {
         dpSet(device + CMSfwFSMConfigDB_CONFIGURATOR_STATUS_VERIFY_FAIL, TRUE);
         CMSfwFSMConfigDB_setConfiguratorState(device, "MODIFIED", "Verificaton of alerts of recipe failed");
        CMSfwFSMConfigDB_inProgress[device] = false;    
          return;
  
      }
//      DebugTN("Verify of " + device + " with recipe " + sRecipeName + " - OK");
      dpSet(device + CMSfwFSMConfigDB_CONFIGURATOR_STATUS_VERIFY_FAIL, FALSE);
      CMSfwFSMConfigDB_setConfiguratorState(device, "LOADED", "Recipe set and verified OK");
      CMSfwFSMConfigDB_inProgress[device] = false;    
      return; 
    }
  }  
  
  //retries to set must have failed
  CMSfwFSMConfigDB_setConfiguratorState(device, "MODIFIED", "Verification of readback of recipe failed");
  CMSfwFSMConfigDB_inProgress[device] = false;    
}  

bool CMSfwFSMConfigDB_applyRecipeFromCache(string sDeviceDp,string sRecipeName,dyn_dyn_mixed& recipeObject,dyn_string aDeviceList = makeDynString(), string sSystemName = "")
{
  dyn_string exceptionInfo;
  dyn_string splittedRecipeName;


  bool result;
//  DebugN("Copy cache to memory ", sDeviceDp, sRecipeName, aDeviceList);
  result = CMSfwFSMConfigDB_copyCachetoMemory(sDeviceDp, sRecipeName, recipeObject, exceptionInfo, aDeviceList, sSystemName);
  
  if(!result)
  {
    DebugTN(sDeviceDp + ": Cached recipe could not be loaded - " + sRecipeName);
    return false;
  }

  if (dynlen(exceptionInfo) > 0)
  {
    DebugN(exceptionInfo);
    return false;
  }
//  DebugTN("Applying recipe for " + dynlen(recipeObject[fwConfigurationDB_RO_DPE_NAME]) + " elements");
  

  fwConfigurationDB_applyRecipe(recipeObject,"",exceptionInfo,true);
  if (dynlen(exceptionInfo) > 0)
  {
    DebugN("Exception in applying recipe: ", exceptionInfo);
    return false;
  }

  return true;
}


bool CMSfwFSMConfigDB_verifyAlerts(string sDeviceDp, dyn_dyn_mixed &recipeFromCache, dyn_dyn_mixed &differences,dyn_string& exceptionInfo) {
  bool debug;
  CMSfwFSMConfigDB_getDebugMode(sDeviceDp,debug);
  
  dyn_string  deviceList ;
  dyn_dyn_mixed recipeFromSystem, recipeDiff;
  dyn_string deviceSystems;
  string systemName, sRecipeType,sRecipeName ,sAlertDetailsCache, sAlertDetailsSys;
  dynClear(differences);
  bool hasAlerts = false;
    for (int i=1; i<= dynlen(recipeFromCache[fwConfigurationDB_RO_HAS_ALERT]); i++) {
      if(recipeFromCache[fwConfigurationDB_RO_HAS_ALERT][i]) {
        hasAlerts = true; break;
      }
    }
    
    if (! hasAlerts) 
      return true;
    
  deviceList = recipeFromCache[fwConfigurationDB_RO_DP_NAME];
  dynUnique(deviceList);
  
  fwConfigurationDB_getRecipeMetaInfo(recipeFromCache,fwConfigurationDB_RO_META_RECIPETYPE,sRecipeType,exceptionInfo);
  fwConfigurationDB_getRecipeMetaInfo(recipeFromCache,fwConfigurationDB_RO_META_ORIGNAME,sRecipeName,exceptionInfo);
  if (dynlen(exceptionInfo)>0) return false;
 
  fwGeneral_getSystemName(sDeviceDp, systemName, exceptionInfo);

  dyn_string deviceSystems;
  if (systemName != "") {
    for (int i=1; i<= dynlen(deviceList); i++) {
      deviceSystems[i] = systemName;
    }
   } else {
     deviceSystems = makeDynString();     
   }
 // DebugTN("Extract recipe for " + dynlen(deviceList) + " devices systemName = " + systemName);
  fwConfigurationDB_setRecipeType(sRecipeType, exceptionInfo, systemName);
    
  fwConfigurationDB_extractRecipe(deviceList,"",recipeFromSystem,exceptionInfo,"", deviceSystems); // do not pass the recipe type here : it will get the default set above
  //DebugTN("Comparing with cache recipe");

  if (dynlen(exceptionInfo)>0) return false;
    
  fwConfigurationDB_compareRecipes( recipeFromSystem, recipeFromCache, 
				      recipeDiff, "", exceptionInfo);

  if (dynlen(exceptionInfo)>0) return false;
  
//  DebugTN(dynlen(recipeDiff[fwConfigurationDB_RO_DPE_NAME]) + " differences");
  for (int i=1; i<= dynlen(recipeDiff[fwConfigurationDB_RO_DPE_NAME]); i++) {
       if(recipeDiff[fwConfigurationDB_RO_HAS_ALERT][i])
    {
      if (dynlen(exceptionInfo)>0) return false;
      dynAppend(differences[1], recipeDiff[fwConfigurationDB_RO_DPE_NAME][i]);
      sAlertDetailsCache = CMSfwFSMConfigDB_getAlertDetails(recipeDiff, i);
      dynAppend(differences[2], sAlertDetailsCache);
      int idx = dynContains(recipeFromSystem[fwConfigurationDB_RO_DPE_NAME], recipeDiff[fwConfigurationDB_RO_DPE_NAME][i]);
      if (idx == 0) {
          sAlertDetailsSys = "dpe not found in system";
       } else {
            sAlertDetailsSys = CMSfwFSMConfigDB_getAlertDetails(recipeFromSystem,idx);
       }
      dynAppend(differences[3], sAlertDetailsSys);
    }
   
   
    }
  dyn_string settingDpes, readbackValues, readbackDpes , currentValues;
  if ((debug) && (dynlen(differences)>0)) {
          dpGet(sDeviceDp + CMSfwFSMConfigDB_CONFIGURATOR_DEBUG_SETTING_DPES, settingDpes,
          sDeviceDp + CMSfwFSMConfigDB_CONFIGURATOR_DEBUG_SETTING_VALUES, readbackValues,
          sDeviceDp + CMSfwFSMConfigDB_CONFIGURATOR_DEBUG_READBACK_DPES, readbackDpes,
          sDeviceDp + CMSfwFSMConfigDB_CONFIGURATOR_DEBUG_READBACK_VALUES, currentValues);
          for (int i=1; i<= dynlen(differences[1]); i++) {
              dynAppend(settingDpes, differences[1][i] + " alert");
              dynAppend(readbackValues, differences[2][i]);
              dynAppend(readbackDpes, differences[1][i] + " alert");
              dynAppend(currentValues, differences[3][i]);                            
          }
          dpSet(sDeviceDp + CMSfwFSMConfigDB_CONFIGURATOR_DEBUG_SETTING_DPES, settingDpes,
          sDeviceDp + CMSfwFSMConfigDB_CONFIGURATOR_DEBUG_SETTING_VALUES, readbackValues,
          sDeviceDp + CMSfwFSMConfigDB_CONFIGURATOR_DEBUG_READBACK_DPES, readbackDpes,
          sDeviceDp + CMSfwFSMConfigDB_CONFIGURATOR_DEBUG_READBACK_VALUES, currentValues);
          
  }

  
  return (dynlen(differences) == 0);

       
} 

string CMSfwFSMConfigDB_getAlertDetails(dyn_dyn_mixed& recipe, int i) {
    if (dynlen(recipe[fwConfigurationDB_RO_ALERT_ACTIVE]) <i) return "index " + i + " out of range";
    if (! recipe[fwConfigurationDB_RO_HAS_ALERT][i] ) return "no alert";
    return recipe[fwConfigurationDB_RO_ALERT_LIMITS][i] + 
        " active=" + recipe[fwConfigurationDB_RO_ALERT_ACTIVE][i] +
        " texts =(" + recipe[fwConfigurationDB_RO_ALERT_TEXTS][i] + 
        ") type=" + recipe[fwConfigurationDB_RO_ALERT_TYPE][i];
}
bool CMSfwFSMConfigDB_verifySetting(string sDeviceDp, dyn_dyn_mixed &recipeFromCache, dyn_dyn_mixed &differences)
{
  dynClear(differences);
  dyn_string targetDpes, currentValues, targetValues;
  dyn_bool recipeHasValue;
  
  targetDpes = recipeFromCache[fwConfigurationDB_RO_DPE_NAME];
  targetValues = recipeFromCache[fwConfigurationDB_RO_VALUE];
  recipeHasValue = recipeFromCache[fwConfigurationDB_RO_HAS_VALUE];

  //deal with recipes that have items with no value saved
  for(int i=dynlen(targetDpes); i>0; i--)
  {
    if(!recipeHasValue[i])
    {
      dynRemove(targetDpes, i);
      dynRemove(targetValues, i);
    }
  }  
  
  dpGet(targetDpes, currentValues);
  
//DebugN(currentValues, targetValues);
  if(targetValues != currentValues)
  {
//DebugN("problem setting recipe, perhaps dpe is locked");
    for(int i=1; i<=dynlen(targetValues); i++)
    {
      if(targetValues[i] != currentValues[i])
      {
        dynAppend(differences[1], targetDpes[i]);
        dynAppend(differences[2], targetValues[i]);
        dynAppend(differences[3], targetDpes[i]);
        dynAppend(differences[4], currentValues[i]);
      }
    }
    return false;
  }
  else
    return true;
}

bool CMSfwFSMConfigDB_verifyReadback(string sDeviceDp, dyn_dyn_mixed recipeFromCache, dyn_dyn_mixed &differences)
{
  dynClear(differences);
  bool debug;
  float tolerance;
  dyn_string dpTypeNames, targetDpes, readbackDpes, settingDpes, settingsDpeMap, readbackDpeMap, currentValues, targetValues, readbackValues;
  dyn_bool recipeHasValue;
  dyn_int dataTypes, readbackDataTypes;

  targetDpes = recipeFromCache[fwConfigurationDB_RO_DPE_NAME];
  targetValues = recipeFromCache[fwConfigurationDB_RO_VALUE];
  recipeHasValue = recipeFromCache[fwConfigurationDB_RO_HAS_VALUE];  
  dataTypes = recipeFromCache[fwConfigurationDB_RO_ELEMENT_TYPE];
  dpTypeNames = recipeFromCache[fwConfigurationDB_RO_DP_TYPE];
  
  CMSfwFSMConfigDB_getSettingReadbackMapping(sDeviceDp, targetDpes, dpTypeNames, settingsDpeMap, readbackDpeMap);
  CMSfwFSMConfigDB_getVerifyTolerance(sDeviceDp, tolerance);
  CMSfwFSMConfigDB_getDebugMode(sDeviceDp, debug);
    
//DebugN("Verify:", settingsDpeMap, readbackDpeMap);
  for(int i=1; i<=dynlen(settingsDpeMap); i++)
  {
    dyn_bool matchingEntries;
    dyn_string matchingDpes, settingsPatternParts, readbackPatternParts;
    matchingEntries = patternMatch(settingsDpeMap[i], targetDpes);
    
    settingsPatternParts = strsplit(settingsDpeMap[i], "*");
    readbackPatternParts = strsplit(readbackDpeMap[i], "*");

    for(int j=dynlen(targetDpes); j>0; j--)
    {
      string dpe;
      
      if(!recipeHasValue[j])    
        continue;
      
      dpe = targetDpes[j];
      if(matchingEntries[j])
      {
        for(int k=1; k<=dynlen(settingsPatternParts); k++)
        {
          strreplace(dpe, settingsPatternParts[k], readbackPatternParts[k]);    
        }
      }
      
      dynAppend(readbackDpes, dpe);
      dynAppend(readbackValues, targetValues[j]);
      dynAppend(readbackDataTypes, dataTypes[j]);
      dynAppend(settingDpes, targetDpes[j]);
      
      dynRemove(targetValues, j);      
      dynRemove(dataTypes, j);
      dynRemove(targetDpes, j);     
    }
  }
    
  if(dynlen(readbackDpes) > 0)
    dpGet(readbackDpes, currentValues);
  else
    currentValues = makeDynString();
  
  if(debug)
  {
    dpSet(sDeviceDp + CMSfwFSMConfigDB_CONFIGURATOR_DEBUG_SETTING_DPES, settingDpes,
          sDeviceDp + CMSfwFSMConfigDB_CONFIGURATOR_DEBUG_SETTING_VALUES, readbackValues,
          sDeviceDp + CMSfwFSMConfigDB_CONFIGURATOR_DEBUG_READBACK_DPES, readbackDpes,
          sDeviceDp + CMSfwFSMConfigDB_CONFIGURATOR_DEBUG_READBACK_VALUES, currentValues);
  }

  if(dynlen(currentValues) == 0)
    return true;
//DebugN("Verify:", settingDpes, readbackDpes, readbackValues, currentValues);
  
  for(int i=1; i<=dynlen(currentValues); i++)
  {
    if(readbackDataTypes[i] == DPEL_FLOAT)
    {
      float current, expected;
      
      current = currentValues[i];
      expected = readbackValues[i];
      
//DebugN("Compare float:", readbackDpes[i], current, expected+tolerance, expected-tolerance);
      if((current > expected+tolerance) || (current < expected-tolerance))
      {
        dynAppend(differences[1], settingDpes[i]);
        dynAppend(differences[2], readbackValues[i]);
        dynAppend(differences[3], readbackDpes[i]);
        dynAppend(differences[4], currentValues[i]);
      }
    }
    else
    {
      if(currentValues[i] != readbackValues[i])
      {
        dynAppend(differences[1], settingDpes[i]);
        dynAppend(differences[2], readbackValues[i]);
        dynAppend(differences[3], readbackDpes[i]);
        dynAppend(differences[4], currentValues[i]);
      }
    }
  }

  if(dynlen(differences)>0)
  {
//DebugN("problem with readback of recipe");
    return false;
  }
  else
    return true;
}

CMSfwFSMConfigDB_setConfiguratorState(string sDeviceDp, string sState, string sStatus="")
{
  if (sState == "") {        
      dpSet(
        sDeviceDp + CMSfwFSMConfigDB_CONFIGURATOR_STATUS_LATEST, sStatus);
      return;   
  }  
  bool allStates, useModified;
  dpGet(sDeviceDp + CMSfwFSMConfigDB_CONFIGURATOR_SHOW_ALL_STATES, allStates,
        sDeviceDp + CMSfwFSMConfigDB_CONFIGURATOR_USE_MODIFIED, useModified);
//DebugN(sDeviceDp, sState);
  if(!allStates)
  {
    if(sState == "VERIFYING" || sState == "CONFIGURING")
      return;
  }
  if (! useModified) {
      if (sState == "MODIFIED") sState = "NOT_READY";
  }

    
  dpSet(sDeviceDp + CMSfwFSMConfigDB_CONFIGURATOR_STATE, sState,
        sDeviceDp + CMSfwFSMConfigDB_CONFIGURATOR_STATUS_LATEST, sStatus);
}


/*
CMSfwFSMConfigDB_User_getSettingReadbackMapping(string sDeviceDp, dyn_string dpElementNames, dyn_string dpTypeNames, dyn_string &settingsDpeMap, dyn_string &readbackDpeMap)
{
  //must use same number of * in each pattern
  //dpes are specified with system name so can use * at beginning to avoid needing to specify it
  settingsDpeMap = makeDynString("dist_1:CAEN/Crate1/board00/channel000.settings.i0");
  readbackDpeMap = makeDynString("dist_1:ExampleDP_Arg1.");
}
*/
