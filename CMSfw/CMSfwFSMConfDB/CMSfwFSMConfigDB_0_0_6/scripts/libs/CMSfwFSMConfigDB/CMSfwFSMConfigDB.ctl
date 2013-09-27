global mapping CMSfwFSMConfigDB_abort;
global mapping CMSfwFSMConfigDB_inProgress;

const string CMSfwFSMConfigDB_CONFIGURATOR = "CMSfwFSMConfigurator";

const string CMSfwFSMConfigDB_CONFIGURATOR_STATE          = ".state";
const string CMSfwFSMConfigDB_CONFIGURATOR_MODE           = ".mode";

const string CMSfwFSMConfigDB_CONFIGURATOR_COMMAND    = ".sendCommand.command";
const string CMSfwFSMConfigDB_CONFIGURATOR_PARAMETER  = ".sendCommand.parameter";

const string CMSfwFSMConfigDB_CONFIGURATOR_VERIFY_DELAY     = ".configuration.verifyDelay";
const string CMSfwFSMConfigDB_CONFIGURATOR_VERIFY_RETRIES   = ".configuration.verifyRetries";
const string CMSfwFSMConfigDB_CONFIGURATOR_TOLERANCE        = ".configuration.floatTolerance";
const string CMSfwFSMConfigDB_CONFIGURATOR_RECIPE_NAME      = ".configuration.recipeName";
const string CMSfwFSMConfigDB_CONFIGURATOR_UPDATE_CACHE     = ".configuration.updateRecipeCache";
const string CMSfwFSMConfigDB_CONFIGURATOR_SETTINGS_MAP     = ".configuration.settingsDpes";
const string CMSfwFSMConfigDB_CONFIGURATOR_READBACK_MAP     = ".configuration.readbackDpes";
const string CMSfwFSMConfigDB_CONFIGURATOR_SHOW_ALL_STATES  = ".configuration.showIntermediateStates";
const string CMSfwFSMConfigDB_CONFIGURATOR_PERIODIC_VERIFY  = ".configuration.periodicVerify";

const string CMSfwFSMConfigDB_CONFIGURATOR_STATUS_LATEST           = ".status.latestResult";
const string CMSfwFSMConfigDB_CONFIGURATOR_STATUS_APPLIED_RECIPE   = ".status.appliedRecipe";
const string CMSfwFSMConfigDB_CONFIGURATOR_STATUS_VERIFY_FAIL      = ".status.verifyFailed";

const string CMSfwFSMConfigDB_CONFIGURATOR_DEBUG                   = ".debug.debugMode";
const string CMSfwFSMConfigDB_CONFIGURATOR_DEBUG_FAILED_DPES       = ".debug.verifyFailureDpes";
const string CMSfwFSMConfigDB_CONFIGURATOR_DEBUG_SETTING_DPES      = ".debug.recipeSettingDpes";
const string CMSfwFSMConfigDB_CONFIGURATOR_DEBUG_SETTING_VALUES    = ".debug.recipeSettingValues";
const string CMSfwFSMConfigDB_CONFIGURATOR_DEBUG_READBACK_DPES     = ".debug.verifyReadbackDpes";
const string CMSfwFSMConfigDB_CONFIGURATOR_DEBUG_READBACK_VALUES   = ".debug.verifyReadbackValues";



void CMSfwFSMConfigDB_startRecipeMonitor()
{
  DebugTN("CMS Recipe Manager: initialising");

  dyn_string libraries;
  if(dpExists("CMSfwFSMConfigDB_config"))
    dpGet("CMSfwFSMConfigDB_config.librariesToLoad", libraries);  

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
    startThread("CMSfwFSMConfigDB_monitorThread", configurator);
  }
}

void CMSfwFSMConfigDB_executeCommand(string device, string command, string device2, string parameter) {
  device = dpSubStr(device, DPSUB_DP);
//  DebugN("Executing ", command, parameter, " on " , device);
  
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
    bool result = CMSfwFSMConfigDB_verify(device);
    DebugN("Verify result "+ result);
  }
//OH mod - not supporting saving at the moment
//    else if (command == "SAVE_FROM_SYSTEM") {
//       tkFwConfigDB_SaveRecipeFromSystem(device,parameter); // parameter is the mode
//    }
}

void CMSfwFSMConfigDB_monitorThread(string sDeviceDp) 
{
//  DebugN("Starting monitor Thread for " + sPartition);
  int periodicVerify = 0;
  
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
    result = CMSfwFSMConfigDB_verify(sDeviceDp);
    
    CMSfwFSMConfigDB_getPeriodicVerifyTime(sDeviceDp, periodicVerify);
    delay(periodicVerify*60);
  }
}  



int CMSfwFSMConfigDB_verify(string sDeviceDp) {
  bool recipeInCache;
  string sRecipe="";
  string sSystemName = strrtrim(getSystemName(),":");
  string sMode="";
  
  dpGet(sDeviceDp + CMSfwFSMConfigDB_CONFIGURATOR_MODE, sMode);
  if(sMode == "")
    return 1;
  
  //skip verify if action is in progress, wait until next period
  //DebugTN(CMSfwFSMConfigDB_inProgress, dpSubStr(sDeviceDp, DPSUB_DP));
  if(mappingHasKey(CMSfwFSMConfigDB_inProgress, dpSubStr(sDeviceDp, DPSUB_DP)))
  {
    //DebugN("skipping if this is true:", CMSfwFSMConfigDB_inProgress[dpSubStr(sDeviceDp, DPSUB_DP)]);
    if(CMSfwFSMConfigDB_inProgress[dpSubStr(sDeviceDp, DPSUB_DP)])
      return 1;
  }
  
  CMSfwFSMConfigDB_getRecipeName(sDeviceDp, sMode, sRecipe);

  recipeInCache = CMSfwFSMConfigDB_checkRecipeInCache(sDeviceDp, sRecipe);
  if(!recipeInCache)
  {
    DebugTN("Periodic check aborted - recipe could not be cached");
    return -1;
  }

//DebugN("Name of the recipe to verify: " + sRecipe);

  dyn_string exceptionInfo;
  dyn_dyn_mixed recipeObject, recipeDiff;
    
  dynClear(recipeObject); 
  fwConfigurationDB_getRecipeFromCache(sDeviceDp + "/" + sRecipe, makeDynString(), "" ,recipeObject, exceptionInfo);
//DebugN(sRecipe +" with " + dynlen(recipeObject[fwConfigurationDB_RO_DPE_NAME]) + " entries got from Cache"); 

  if (dynlen(exceptionInfo) > 0)
    {
      DebugN(exceptionInfo);
      return -1;
    }

  bool bVerify;
      
  bVerify = CMSfwFSMConfigDB_verifyReadback(sDeviceDp,recipeObject,recipeDiff);
  if(!bVerify)
  {
    CMSfwFSMConfigDB_setConfiguratorState(sDeviceDp, "NOT_READY", "Readback verification failed");
    dpSet(sDeviceDp + CMSfwFSMConfigDB_CONFIGURATOR_STATUS_VERIFY_FAIL, TRUE);
    DebugTN("Periodic verify of " + sDeviceDp + " with recipe " + sRecipe + " - failed");
  }
  else
  {
    CMSfwFSMConfigDB_setConfiguratorState(sDeviceDp, "LOADED", "Periodic verify OK");
    dpSet(sDeviceDp + CMSfwFSMConfigDB_CONFIGURATOR_STATUS_VERIFY_FAIL, FALSE);
    DebugTN("Periodic verify of " + sDeviceDp + " with recipe " + sRecipe + " - OK");
  }

  bool debugMode;
  CMSfwFSMConfigDB_getDebugMode(sDeviceDp, debugMode);
  if(debugMode)
    dpSet(sDeviceDp + CMSfwFSMConfigDB_CONFIGURATOR_DEBUG_FAILED_DPES, dynlen(recipeDiff)?recipeDiff[3]:makeDynString());  

  return bVerify;
}

synchronized bool CMSfwFSMConfigDB_copyDBtoCache(string sDeviceDp, string sRecipeName)
{
  dyn_string exceptionInfo;
  dyn_dyn_mixed recipeObject;
  dyn_string recipeList;
  
  fwConfigurationDB_getRecipesInDB(recipeList, exceptionInfo);

  //DebugN("Recipes in db ", recipeList);
  if (! dynContains(recipeList, sRecipeName)) {
    DebugTN("Recipe " + sRecipeName + " not found in DB");
    return false;
  }
  
  fwConfigurationDB_getRecipeFromDB("","",fwDevice_HARDWARE,sRecipeName,recipeObject,exceptionInfo);
  fwConfigurationDB_createRecipeCache(sDeviceDp + "/" + sRecipeName,exceptionInfo);
  fwConfigurationDB_storeRecipeInCache(recipeObject, sDeviceDp + "/" + sRecipeName, fwDevice_HARDWARE, exceptionInfo);
  
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
  if(isFunctionDefined("CMSfwFSMConfigDB_User_getSettingReadbackMapping"))
  {
    CMSfwFSMConfigDB_User_getSettingReadbackMapping(sDeviceDp, dpElementNames, dpTypeNames, settingsDpeMap, readbackDpeMap);
  }
  else
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

bool CMSfwFSMConfigDB_checkRecipeInCache(string sDeviceDp, string sRecipe)
{
  bool updateCache;
  dyn_string exceptionInfo;
  dpGet(sDeviceDp + CMSfwFSMConfigDB_CONFIGURATOR_UPDATE_CACHE, updateCache);

  if(dpExists("RecipeCache/" + sDeviceDp + "/" + sRecipe))
  {
    if(updateCache)
    {
      fwConfigurationDB_initialize("", exceptionInfo);
      if(dynlen(exceptionInfo))
      {
        DebugTN("CMS Recipe Manager: ConfigDB not available, force refresh of recipes will be postponed until DB is available");
      }
      else
      {
        CMSfwFSMConfigDB_clearCache(sDeviceDp);
        if(!CMSfwFSMConfigDB_copyDBtoCache(sDeviceDp, sRecipe))
          return false;
      }
    }
  }
  else
  {
    fwConfigurationDB_initialize("", exceptionInfo);
    if(dynlen(exceptionInfo))
    {
      DebugTN("CMS Recipe Manager: ConfigDB not available, recipe is not currently cached");
      return false;
    }
    else
    {
      if(!CMSfwFSMConfigDB_copyDBtoCache(sDeviceDp, sRecipe))
        return false;
    }
  }

  return true;
}  
  

void CMSfwFSMConfigDB_DULoad(string device,string mode)
{
  dyn_string exceptionInfo;
  DebugTN("Configuring " + device + " in mode " + mode);
  dyn_dyn_mixed recipeDiff,recipeFromCache;
        
//  DebugN("CMSfwFSMConfigDB_DULoad",CMSfwFSMConfigDB_abort[device]);    
    
  CMSfwFSMConfigDB_inProgress[device] = true;    
  dpSet(device + CMSfwFSMConfigDB_CONFIGURATOR_MODE, mode);
 
  bool recipeInCache, applyResult;  
  string sRecipe;
  CMSfwFSMConfigDB_getRecipeName(device, mode, sRecipe);
  
  recipeInCache = CMSfwFSMConfigDB_checkRecipeInCache(device, sRecipe);
  if(!recipeInCache)
  {
    CMSfwFSMConfigDB_setConfiguratorState(device, "NOT_READY", "Recipe \"" + sRecipe + "\" could not be cached");
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
    CMSfwFSMConfigDB_User_preApplyRecipe(device, mode, sRecipe, dpSubStr(device, DPSUB_SYS));  

  applyResult = CMSfwFSMConfigDB_applyRecipeFromCache(device,sRecipe,recipeFromCache);
  dpSet(device + CMSfwFSMConfigDB_CONFIGURATOR_STATUS_APPLIED_RECIPE, sRecipe);

  if(isFunctionDefined("CMSfwFSMConfigDB_User_postApplyRecipe"))
    CMSfwFSMConfigDB_User_postApplyRecipe(device, mode, sRecipe, dpSubStr(device, DPSUB_SYS));  
  
  if(!applyResult)
  {
    CMSfwFSMConfigDB_setConfiguratorState(device, "NOT_READY", "Recipe was not applied successfully");
    DebugN("Recipe not applied successfully");
    CMSfwFSMConfigDB_inProgress[device] = false;    
    return;
  }
  
  if (CMSfwFSMConfigDB_abort[device] == "ABORT") {
    CMSfwFSMConfigDB_setConfiguratorState(device, "NOT_READY", "Aborted by user");
    CMSfwFSMConfigDB_inProgress[device] = false;    
    return;
  }

  bool verifySet, verifyReadback;
  int delayBeforeVerify, retries;
    
  verifySet = CMSfwFSMConfigDB_verifySetting(device,recipeFromCache,recipeDiff);
  if(!verifySet)
  {
    DebugTN("Verify of " + device + " with recipe " + sRecipe + " - SETTING failed");
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
      
      DebugTN("Verify of " + device + " with recipe " + sRecipe + " - READBACK failed");
      dpSet(device + CMSfwFSMConfigDB_CONFIGURATOR_STATUS_VERIFY_FAIL, TRUE);
      CMSfwFSMConfigDB_setConfiguratorState(device, "CONFIGURING");
      dpSet(dpesToSet, valuesToSet);
    }
    else
    {
      DebugTN("Verify of " + device + " with recipe " + sRecipe + " - OK");
      dpSet(device + CMSfwFSMConfigDB_CONFIGURATOR_STATUS_VERIFY_FAIL, FALSE);
      CMSfwFSMConfigDB_setConfiguratorState(device, "LOADED", "Recipe set and verified OK");
      CMSfwFSMConfigDB_inProgress[device] = false;    
      return; 
    }
  }  
  
  //retries to set must have failed
  CMSfwFSMConfigDB_setConfiguratorState(device, "NOT_READY", "Verification of readback of recipe failed");
  CMSfwFSMConfigDB_inProgress[device] = false;    
}  

bool CMSfwFSMConfigDB_applyRecipeFromCache(string sDeviceDp,string sRecipe,dyn_dyn_mixed& recipeObject,dyn_string aDeviceList = makeDynString())
{
  dyn_string exceptionInfo;
  dyn_string splittedRecipeName;
  string partition;
  splittedRecipeName = strsplit(sRecipe,"_");
  
  if(dynlen(splittedRecipeName)>5){
    partition = splittedRecipeName[5];
    DebugN(partition);
  }

//DebugN("apply recipe from cache", sRecipe, aDeviceList);
  fwConfigurationDB_getRecipeFromCache(sDeviceDp + "/" + sRecipe, aDeviceList,"",recipeObject,exceptionInfo);
  if (dynlen(exceptionInfo) > 0)
  {
    DebugN(exceptionInfo);
    return false;
  }

  fwConfigurationDB_applyRecipe(recipeObject,"",exceptionInfo,true);
  if (dynlen(exceptionInfo) > 0)
  {
    DebugN(exceptionInfo);
    return true;
  }

  return true;
}


bool CMSfwFSMConfigDB_verifySetting(string sDeviceDp, dyn_dyn_mixed recipeFromCache, dyn_dyn_mixed &differences)
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
      
      if(!matchingEntries[j])
        continue;
      
      for(int k=1; k<=dynlen(settingsPatternParts); k++)
      {
        dpe = targetDpes[j];
        strreplace(dpe, settingsPatternParts[k], readbackPatternParts[k]);    
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
//DebugN("Verify:", readbackDpes, readbackValues, currentValues);
  
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
  bool allStates;
  dpGet(sDeviceDp + CMSfwFSMConfigDB_CONFIGURATOR_SHOW_ALL_STATES, allStates);
//DebugN(sDeviceDp, sState);
  if(!allStates)
  {
    if(sState == "VERIFYING" || sState == "CONFIGURING")
      return;
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

