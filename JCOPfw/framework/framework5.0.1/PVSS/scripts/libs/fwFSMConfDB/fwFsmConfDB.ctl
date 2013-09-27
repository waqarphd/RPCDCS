/**@file
 *
 * This package contains the functions used by the interface between the 
 * Finite State Machine and the Configuration DB.
 *
 * @author Francisca Calheiros(IT-CO/BE) and Fernando Varela (IT-CO/BE)
 * @date 29th of July 2008
 */

/**
 * @name FSM-ConfDB Interface: Definition of constants

   The following constants are used by the FSM - ConfDB Interface

 * @{
 */
#uses "fwFSMConfDB/fwFsmConfDBAtlas.ctl"

global string fwFSMConfDB_gConfigurationName = "FsmConfDB"; 
global string fwFSMConfDB_gConfigurationDescription = "FSM-ConDB Device Configuration";

//Global variable to be implemented by the FW Configuration DB Tool. To be moved...
global string fwFSMConfDB_defaultRecipeMergeMode="DEVICE";

/**
 *Name of the ERROR state of the configurator
 *@ingroup FSMCOnfDB Constants
 */
const string g_csErrorState = "ERROR"; 	

/**
 *Name of the READY state of the configurator
 *@ingroup FSMCOnfDB Constants
 */		  
const string g_csReadyState = "READY";	

/**
 *Name of the NOT_READY state of the configurator
 *@ingroup FSMCOnfDB Constants
 */	        
const string g_csNotReadyState = "NOT_READY";		

/**
 *FSMConfDB return OK
 *@ingroup FSMCOnfDB Constants
 */
const int fwFSMConfDB_OK = 0;


/**
 *general FSMCOnfDB error code
 *@ingroup FSMCOnfDB Constants
 */
const int fwFSMConfDB_ERROR = -1;
        
const string g_csFSMConfDBDPT = "FwFSMConfDB";          //Configurator DPT
const string g_csFwFSMConfDBDelimiter = "/";            //Delimiter used in recipe names
const string g_csFwFSMConfDBSetup = "FwFSMConfDB";      //Name of the ConfDB setup used 
const string g_csModeDelimiter = "|";                   //Delimiter used in recipe names when using subModes(mode|subMode)

const string g_csDevicesDPE = ".devices";	        //DPE that holds the internal list of devices to be configured in a SMI++ domain
const string g_csCommandsDPE = ".commands";	        //DPE that holds the internal list of comamnds of a DU type
const string g_csCachesDPE = ".caches";			//DPE that holds the internal list of caches loaded from the DB for a SMI++ domain
const string g_csRecipesDPE = ".recipes";	        //DPE that holds the internal list of recipes loaded from the DB for a SMI++ domain
const string g_csUseConfDBDPE = ".useConfDB";	        //DPE that flags whether the ConfDB should be used or not.
const int    g_maxCmdNr = 10;                              //Max number of FSM commands for a run mode
const string g_CachePrefix = "FwFSMConfDB";             //Prefix of the cache objects used by the fwFSMCOnfDB Interface
const string g_csSplitAtDpe = "FwFSMConfDBParametrization.splitCachesAt";  //This dpe defines the number of devices for wich a recipe is split into different caches
const string g_csForceUpdate = "FwFSMConfDBParametrization.forceUpdateFromDB";  //DPE that flags whether to force an update from DB or not.
const string g_csStopOnError = "FwFSMConfDBParametrization.stopOnError"; //DPE that flags whether the caching of recipes must be aborted if not all requested  
const string g_csStopNoRecipes = "FwFSMConfDBParametrization.stopNoRecipes"; //DPE that flags whether the caching of recipes must be aborted if not all requested  
const string g_csClearCaches = "FwFSMConfDBParametrization.clearCaches"; //DPE that flags whether the FSMConfDB caches should be clear averytime the FSM starts                                                                      //devices are defined in a particular recipe.
const string g_csDUTypesDPE = ".duTypes";               //DPE holding the list of DU types handled by a configurator
const string g_csConfiguratorDUType = "FwFSMConfDBDUT";                    //FSM-ConfDB configurator DU type

const string g_csDelayInterval = "FwFSMConfDBParametrization.delayInterval"; //DPE that defines the interval that the configurator wait for the devices
const string g_csApplyRecipesTimeout = ".applyRecipes.timeout";              //DPE that defines the apply recipe timeout of each configurator
const string g_csApplyRecipeUsingConfigurator = ".applyRecipes.usingConfigurator"; // DPE that flags whether the configurator apply the recipes or not
const string g_csApplyRecipeSimplified = ".applyRecipes.simplifiedAR";      // DPE that activates the simplified APPLY_RECIPE command
const string g_csRecipePattern = ".recipePattern"; // DPE to define a recipe pattern to load
const string g_csIgnoreDeviceList = ".ignoreDeviceList"; //DPE that flags whether the Configurator ignores the list of devices when loading a recipe

//@} // end of FSMConfDB constants

/**
 * @name FSM-ConfDB Interface: Definition of variables

   The following variables are used by the FSM - ConfDB Interface

 * @{
 */
/** 
 * Name of the FW Hierarchy to be used
 * @ingroup GlobalVariables 
 */
global string g_sFwDevice_HIERARCHY; 
//@} // end of FSMConfDB variables

// bool g_bAlreadyDone =FALSE;

 dyn_string g_dsDevicesList;      
 dyn_string g_dsDevicesCommandList;	  
 dyn_string g_dsDeviceTypeList;  
 
 // list of all loaded Modes from DB  
 dyn_string g_dsloadedModes;  
 
// value that indicates the mode to be used to apply recipes
// int g_applyRecipeMode;

bool fwFSMConfDB_ceckCacheIntegrity(string cache, dyn_string &exception)
{
  dyn_dyn_mixed sysRecipeObject, cacheRecipeObject, diffRecipeObject;
  dyn_string deviceList;
    
  fwConfigurationDB_loadRecipeFromCache(cache, makeDynString(), "", cacheRecipeObject, exception);
  if(dynlen(exception))
    return false; 
       
  deviceList = cacheRecipeObject[fwConfigurationDB_RO_DP_NAME];
  dynUnique(deviceList);
  
  fwConfigurationDB_extractRecipe(deviceList, "",
                  sysRecipeObject, exception);

  if(dynlen(exception))
    return false;

  bool same = fwConfigurationDB_compareRecipes(sysRecipeObject, cacheRecipeObject, diffRecipeObject, "", exception);
  
  if(dynlen(exception))
    return exception;
  
  if(same)
    return false;
  
  return true;    
}

dyn_string fwFSMConfDB_getConfiguratorCaches(string domain)
{
  dyn_string caches = dpNames("RecipeCache/FwFSMConfDB/" + domain + "/*.", "_FwRecipeCache");;
  dyn_string userRecipes = fwFSMConfDB_getConfiguratorUserRecipes(domain);
  string sys = getSystemName();
  dyn_string dps;
    
  for(int i = 1; i <= dynlen(caches); i++)
  {
    strreplace(caches[i], sys, "");
    strreplace(caches[i], "RecipeCache/", "");
    strreplace(caches[i], ".", "");
  }  
  
  //Check that userRecipes are already loaded into caches:
  for(int i = 1; i <= dynlen(userRecipes); i++)
  {
    if(patternMatch("*$sMode*", userRecipes[i]))
    {
      strreplace(userRecipes[i], "$sMode/", "");
      dps = dpNames(getSystemName() + "RecipeCache/*/" + userRecipes[i], "_FwRecipeCache");
    }
    else
      dps = makeDynString("RecipeCache/" + userRecipes[i]);

    for(int j = 1; j <= dynlen(dps); j++)
    {
      if(!dpExists(dps[j]))
        continue;
      
      strreplace(dps[j], sys, "");
      strreplace(dps[j], "RecipeCache/", "");
      strreplace(dps[j], ".", "");
      dynAppend(caches, dps[j]);
    }  
  }


  return caches; 
}

dyn_string fwFSMConfDB_getConfiguratorUserRecipes(string domain)
{
  dyn_string userRecipes;  
  string configurator = fwFSMConfDB_getDomainConfigurator(domain);
  
  dpGet(configurator + ".userRecipes", userRecipes); 
  
  return userRecipes; 
} 
 
 
 
 
/** Initializes the FSMConfDB configurator. In addition, it also initializes the connection 
 * to the Configuration DB and the internal list of devices to be configured in the SMI++ domain.
 * If connection to ConfDB cannot be established, the configurator goes to an ERROR state, 
 * otherwise to NOT_READY state.
 * @param sDomain Name of the SMI++ domain
 * @param sConfigurator name of the configurator
 * @return error code: -1 if error, 0 if OK
 */
int fwFSMConfDB_initialize(string sDomain, string sConfigurator)
{   
  bool bUseDB, clearCaches;
  string hierarchy;
  dyn_string dsStr;
  dyn_string exInfo;
  int i;
  
   //Set initial state to NOT_READY
   fwFSMConfDB_setState(sConfigurator, g_csNotReadyState);
   
  //  get configurator parameters  
    dpGet(g_csClearCaches,clearCaches, sConfigurator + g_csUseConfDBDPE,bUseDB);   

   //get value that indicates the mode to be used to apply recipes
   //g_applyRecipeMode = fwFSMConfDB_getApplyRecipeUsingConfigurator(sDomain);
   
   if(clearCaches)
   {
    //clear list of modes loaded by the configurator
    dynClear(g_dsloadedModes);  
    
    //Delete previous caches used by the fwFSMConfDB Interface
    fwConfigurationDB_findRecipesInCache(dsStr, exInfo, g_CachePrefix +"/"+sDomain+"/*");
    
    for(i=1; i<=dynlen(dsStr); i++)
      {
       fwConfigurationDB_dropRecipeInCache(dsStr[i],hierarchy, exInfo);
       }
   }  
  
  //Disable if parent is a LU otherwise initialize connection to DB
  string parent;
  dyn_string exceptionInfo;

  fwTree_getParent(sConfigurator, parent, exceptionInfo);
  if(parent != sDomain){
    fwCU_disableObj(sDomain, sConfigurator);
    return fwFSMConfDB_OK;
  }
  else{
       //Set internal list of devices: 
       fwFSMConfDB_updateDeviceList(sDomain, sConfigurator);  
    
       dpGet(sConfigurator + g_csUseConfDBDPE,bUseDB);
    
       if(bUseDB){
         //Initialize connection to DB
         DebugN("INFO: Initializing connection to the Configuration DB for SMI++ Domain: " + sDomain);
         if(fwFSMConfDB_initConfDBConnection()!= 0){
           //Set configurator initial state to error if it cannot initialize connection to DB
           fwFSMConfDB_setState(sConfigurator, g_csErrorState);
           return fwFSMConfDB_ERROR;
           }else
               fwFSMConfDB_setState(sConfigurator, g_csNotReadyState);
          }else{
              DebugN("INFO: Initializing connection to recipe caches  for SMI++ Domain: " + sDomain);
              //Set configurator initial state to NOT_READY
              fwFSMConfDB_setState(sConfigurator, g_csNotReadyState);
             }              
      }
  
  return fwFSMConfDB_OK;
}

/** Gets the FW hierarchy in use for the specified control domain
* @param sDomain Name of the SMI++ domain
* @param  sFwHierarchy name of the hierarchy
* @return Error code: 0 if all OK, -1 if invalid hierarchy name
*/
int fwFSMConfDB_getFwHierarchy(string sDomain, string &sFwHierarchy)
{
  string hierarchy;

  dpGet("FwFSMConfDBParametrization.fwHierarchy", hierarchy);

  // dpGet(sDomain + "_ConfDB.fwHierarchy", hierarchy); : for future versions
  
  switch(hierarchy){
    case "fwDevice_HARDWARE": sFwHierarchy = fwDevice_HARDWARE;
	                          break;

    case "fwDevice_LOGICAL":  sFwHierarchy = fwDevice_LOGICAL;
	                          break;

    case "fwDevice_FSM":      sFwHierarchy = fwDevice_FSM;
	                          break;

    default:                  DebugN("ERROR: fwFSMConfDB_getFwHierarchy() -> Invalid FW Hierarchy name: " + sFwHierarchy);
	                          sFwHierarchy = "";
	                          return fwFSMConfDB_ERROR;
    
  
  }//end of switch
  
  return fwFSMConfDB_OK;
}

/** Sets the FW hierarchy in use for the specified control domain
* @param sDomain Name of the SMI++ domain
* @param sFwHierarchy name of the hierarchy to be set: fwDevice_HARDWARE or fwDevice_LOGICAL
* @return Error code: 0 if all OK, -1 if invalid hierarchy name
*/
int fwFSMConfDB_setFwHierarchy(string sDomain, string sFwHierarchy)
{
  string hierarchy;

  switch(sFwHierarchy){
    case fwDevice_HARDWARE: hierarchy = "fwDevice_HARDWARE";
	                          break;

    case fwDevice_LOGICAL:  hierarchy = "fwDevice_LOGICAL";
	                          break;

    default: DebugN("ERROR: fwFSMConfDB_setFwhierarchy() -> Invalid FW Hierarchy name: " + sFwHierarchy);
	     sFwHierarchy = "";
	     return fwFSMConfDB_ERROR;    
  
  }//end of switch
  
  dpSet("FwFSMConfDBParametrization.fwHierarchy", hierarchy);

  return fwFSMConfDB_OK;
}

/** Gets the UseConfDB flag
 * @param sConfigurator name of the configurator
 * @return TRUE if ConfDB is in use, otherwise FALSE
*/
bool fwFSMConfDB_getUseConfDB(string sConfigurator)
{
  bool useConfDB;
  
  dpGet(sConfigurator + g_csUseConfDBDPE, useConfDB);

  return useConfDB;
}


/** Updates the internal list of devices handled by a FSMConfDB configurator
 * @param sDomain Name of the SMI++ domain as a string
 * @param sConfigurator name of the domain configurator
 */
void fwFSMConfDB_updateDeviceList(string sDomain, string sConfigurator)
{
  dyn_string duTypes;
  string newType;
  
  dyn_string states;
  dyn_string commandsAux;
  dyn_string stateCommands;
  dyn_string nsDeviceList;
  dyn_string deviceList = fwFSMConfDB_getDomainDevices(sDomain);
  dyn_int visi;
  //Set list of configurator devices
  if(dynContains(deviceList, getSystemName() + sConfigurator) > 0)
     dynRemove(deviceList, dynContains(deviceList, getSystemName() + sConfigurator));
  
  dpSet(sConfigurator + g_csDevicesDPE, deviceList); 
 
  dynClear(commandsAux);
   
  //Set the list of DU types:
  for(int i = 1; i <=dynlen(deviceList); i++)
  {
    nsDeviceList[i] = fwFSMConfDB_removeSystemName(deviceList[i]);

    fwCU_getType(nsDeviceList[i], newType);

   //FC:23/11/2006 -> check if type already exists
    if(dynContains(duTypes,newType)<=0){

      dynAppend(duTypes, newType);
      //Get list of commands for the DU-Type
      fwUi_getObjStates(sDomain, nsDeviceList[i], states);
 
      for(int p = 1; p <= dynlen(states);p++){
        dynClear(stateCommands);       

     //new function to show all commands: visible & insible ones - fwFSM v25.8
     if(isFunctionDefined("fwUi_getObjStateAllActions"))
        fwUi_getObjStateAllActions(sDomain, nsDeviceList[i], states[p], stateCommands);
       else
        fwUi_getObjStateActions(sDomain, nsDeviceList[i], states[p], stateCommands);
      
     dynAppend(commandsAux, stateCommands);
       
      }
      //FVR: 4/7/2006 -> Restrict to a list of unique commands
      dynUnique(commandsAux);
    }

  }
  
 dpSet(sConfigurator + g_csCommandsDPE,commandsAux);

  return;
}

/** Retrives the list of devices to be handle by a FSMConfDB configurator
 * @param sDomain Name of the SMI++ domain as a string
 * @return list of devices in the SMI++ domain
 */
dyn_string fwFSMConfDB_getDomainDevices(string sDomain)
{
  dyn_string devices;

   fwFSMConfDB_getAllDevices(sDomain, sDomain, devices);
  
   dynUnique(devices);
  
  return devices;
}

/** Gets all Device Units in a SMI++ domain recursively
 * @param domain Name of the SMI++ domain as a string
 * @param lunit logical unit
 * @param devices list of devices as a dyn_string
 * @param ignore_disabled optional flag to indicate whether the disabled devices must be included in the list or not. The default value is 0
 */
void fwFSMConfDB_getAllDevices(string domain, string lunit, dyn_string &devices, int ignore_disabled = 0, bool excludeMajority = true)
{

  dyn_string children;
  dyn_int children_types;
  int i, index, enabled;
  string state, sys, node, obj;

  fwUi_getDomainSys(domain, sys);
	
  children = fwCU_getChildren(children_types, domain+"::"+lunit);
  
  for(i = 1; i <= dynlen(children); i++)
  {
    if(excludeMajority && patternMatch("*_FWMAJ", children[i]))
      continue;  //skip majority voting devices
    
    if(children_types[i] == 2)
    {
      if(!fwFSMConfDB_isConfigurator(sys+children[i]))
      {
        if(fwFsm_isLogicalDeviceName(children[i]))                    
	  dynAppend(devices, children[i]);
        else
          dynAppend(devices, sys+children[i]);
      }
    }
    else if(children_types[i] == 0)
    {
      fwFSMConfDB_getAllDevices(domain, children[i], devices);
    }
  }
  
  //DebugN("*****getAllDevices", devices);
  return;
}


/** Function to check whether a device is a configurator or not
 * @param sDevice name of the device to be checked
 * @return TRUE if the device is a configurator otherwise FALSE
 */
bool fwFSMConfDB_isConfigurator(string sDevice)
{
  string device = fwFSMConfDB_removeSystemName(sDevice);
  
 // if(g_sFwDevice_HIERARCHY == fwDevice_LOGICAL)
    //device = dpAliasToName(device);
 
  //check if it's a logical device
  if(!dpExists(device))
    device = dpAliasToName(device);
  
  if(dpTypeName(device) == g_csFSMConfDBDPT)
    return true;
  else
    return false;

}


 /** Retrieves the name of the configurator object in an SMI++ domain
 * @param sDomain name of the SMI++ domain
 * @return name of the FSMConfDB configurator
 */
string fwFSMConfDB_getDomainConfigurator(string sDomain)
{
  string configurator;

  configurator = sDomain + "_ConfDB";

  if(dpExists(configurator) && dpTypeName(configurator) == g_csFSMConfDBDPT)
    return configurator;

  DebugN("ERROR: fwFSMConfDB_getDomainConfigurator() -> No configurator found in domain: " + sDomain);
  return "";
}

/** Removes the system name from a dp-name
 * @param sDpName name of the dp
 * @return dp-name without the system name
 */
string fwFSMConfDB_removeSystemName(string sDpName)
{
  dyn_string ds;

  ds = strsplit(sDpName, ":");
  if(dynlen(ds) > 1)
    return ds[2];
  else 
    return ds[1];  

}

/** This function connects to the state of the FSMConfDB configurator. 
 * Should the state of the configurator is set to READY after the time given by the timeout value
 * the function returns TRUE, otherwise FALSE. This function is intended to be called from the 
 * DU in the hierarchy to pause their transitions while the configurator object loads all recipes 
 * from the ConfDB.
 * @param sDomain Name of the SMI++ object
 * @param sConfigurator Name of the FSMConfDB Configurator
 * @param timeout time interval to wait before the state of the configurator is set to ERROR
 * @return flag indicating if the action has timed out or not.
 */
bool fwFSMConfDB_waitForStateChange(string sDomain, string sConfigurator, time timeout) 
{  
  dyn_string dpNamesWait, dpNamesReturn; 
  dyn_anytype conditions, returnValues; 
  int status; 
  bool timerExpired = false; 

  string currentState = "";
  fwDU_getState(sDomain, sConfigurator, currentState);
  
  if(currentState == g_csReadyState)  
    return fwFSMConfDB_OK;

  dpNamesWait = makeDynString(sConfigurator + ".status:_online.._value"); 
 
  // indication of the condition that must be fulfilled 
  conditions[1] = 1; 
 
  // assignment of the datapoints for dpNamesReturn
  dpNamesReturn = makeDynString(sConfigurator + ".status:_online.._value" ); 

  status = dpWaitForValue(dpNamesWait, conditions, dpNamesReturn, returnValues, timeout, timerExpired); 

  return fwFSMConfDB_ERROR*timerExpired; //-1 if error, 0 if OK
} 

/** This function waits for the configurator to apply the recipes. 
 * Is intended to be called from the DU to pause their transitions while the configurator 
 * applies all recipes to the devices. Should only be used when the option:Configurator apply recipe is active.
 * @param sDomain Name of the SMI++ object
 * @param sConfigurator Name of the FSMConfDB Configurator
 * @return 0 if the recipe was applied otherwise -1
 */

int fwFSMConfDB_waitForConfiguratorApplyRecipe(string sDomain, string sConfigurator) 
{  
  dyn_string dpNamesWait, dpNamesReturn; 
  dyn_anytype conditions, returnValues;  
  int status;
  string  configuratorState;
  
  if(fwFSMConfDB_getApplyRecipeUsingConfigurator(sDomain)!=1)
    return fwFSMConfDB_OK;
  
  dpNamesWait = makeDynString(sDomain +"|"+sConfigurator + ".fsm.executingAction:_online.._value"); 

  // indication of the condition that must be fulfilled 
  conditions[1] = ""; 
 
  // assignment of the datapoints for dpNamesReturn
  dpNamesReturn = makeDynString(sDomain +"|"+sConfigurator + ".fsm.executingAction:_online.._value"); 
 
  status = dpWaitForValue(dpNamesWait, conditions, dpNamesReturn, returnValues,0); 

  dpGet(sDomain +"|"+sConfigurator + ".fsm.currentState", configuratorState);
  
  if(configuratorState=="READY")
    return fwFSMConfDB_OK;
    else
        return fwFSMConfDB_ERROR;
} 

/** Terminates the current action for a device in a SMI++ domain
 * @param sDomain Name of the SMI++ object
 * @param sDevice Name of the device
 */
void fwFSMConfDB_terminateCurrentCommand(string sDomain, string sDevice)
{
  string state = "";

  sDevice=fwFSMConfDB_removeSystemName(sDevice);

  fwDU_getState(domain, device, state);
  fwDU_setState(domain, device, state);
  
  return;
}   


/** Initializes the connection to the ConfDB for a given setup
 * @param setupName name of the setup in the configuration DB
 * @return error code: -1 if error, 0 if OK
 */

// FC: Function changed on 28.11.2006
int fwFSMConfDB_initConfDBConnection()
{
  dyn_string exceptionInfo;

  fwConfigurationDB_checkInit(exceptionInfo);

  if(dynlen(exceptionInfo) > 0){
    DebugN("ERROR: fwFSMConfDB_initConfDBConnection() -> " + exceptionInfo);
    return fwFSMConfDB_ERROR;
  }
  return fwFSMConfDB_OK;
}

/** Gets the list of device units to be configured by a FSMConfDB configurator
 * @param sConfigurator name of the configurator
 * @return list of devices units
 */

dyn_string fwFSMConfDB_getConfiguratorDevices(string sConfigurator)
{ 
  dyn_string devices;
 dpGet(sConfigurator + g_csDevicesDPE, devices);

  return devices;
}

/** Checks if a recipe cache exists
* @param sCache recipe cache name
* @return error code: -1 if it does not exist or 0 if all OK
*/
int fwFSMConfDB_cacheExists(string sCache)
{
  if(dpExists("RecipeCache/" + sCache))
    return fwFSMConfDB_OK;
  else
    return fwFSMConfDB_ERROR;
}

string fwFSMConfDB_getDefaultModeName()
{
  return "DEFAULT";
}


/** Synchronizes the contents (i.e. recipes) of the configuration DB and the internal PVSS caches 
 * used by the Configuration DB tool, for a given running mode of the experiment. This function
 * also sets up the internal data-points which hold the so-called "Recipe Dictionary". The recipe
 * dictionary is an internal table which holds the cache names for the different devices and recipes 
 * in a SMI++ control domain. 
 * @param sDomain name of the SMI++ control domain
 * @param sMode running mode of the experiment to load the recipes for. This is an optional parameter.
 * If left empty, the current running mode of the experiment is resolved by the FWFSMConfDB Interface
 * @return error code: -1 in the event of error, 0 if OK
 */
int fwFSMConfDB_cacheAllRecipesForMode(string sDomain, string sMode = "")
{															 

  dyn_string allRecipeTags;
  string systemName = "";
  string cacheName = "";
  dyn_string exceptionInfo;
  dyn_dyn_mixed recipeObject, tempRecipeObject;
  dyn_string deviceList;

  dyn_string commonDevices,recipeDevices;
  dyn_string cacheList;
  dyn_string subModes;
             
  dyn_string modesPattern;
  string commandRecipeStr;
  
  //     
  string sConfigurator = fwFSMConfDB_getDomainConfigurator(sDomain);
  //
  bool useConfDB = fwFSMConfDB_getUseConfDB(sConfigurator);
  //
  dyn_string stateCommands;   //list of commands to be handle by the configurator
  dyn_string commandRecipes; //list of recipes related with FSM commands 
 
  dyn_string userRecipes; //list of user aditional recipes to be loaded by the configurator

  bool forceUpdate, bStopOnError,ignoreDeviceList, stopNoRecipes;  
  string str;  
  string sMainMode;
  dyn_string modeRecipeTags, defaultRecipeTags;
  string recipePattern;
  
  dpGet(g_csForceUpdate,forceUpdate, g_csStopOnError,bStopOnError,
        sConfigurator + g_csRecipePattern, recipePattern,
        sConfigurator + g_csIgnoreDeviceList, ignoreDeviceList,
        "FwFSMConfDBParametrization.stopNoRecipes", stopNoRecipes);
  
  if(sMode == "")
    sMode = fwFSMConfDB_getCurrentMode(sConfigurator);

  DebugN("INFO: Configurator in FSM Domain: " + sDomain + " loading mode: " + sMode);
  
  if((dynContains(g_dsloadedModes,sMode)>0)&&(!forceUpdate))
  {
    DebugN("INFO: Recipes for mode: " + sMode + " already loaded.");
    return fwFSMConfDB_OK;          
   }
  
  
  //check if mode contains submodes:  
  subModes = strsplit(sMode,g_csModeDelimiter);

  sMainMode = subModes[1];
  
  modesPattern = makeDynString(fwFSMConfDB_getDefaultModeName());    
  
    
  for(int i = 1; i <= dynlen(subModes); i++)
  {
    if(i == 1)
      str = subModes[i];
    else
      str += g_csModeDelimiter + subModes[i];
    
    dynAppend(modesPattern, str);
    
  }//end of loop over submodes

  if(useConfDB){ //Initialize connection to DB if flag set
  
    if(fwFSMConfDB_initConfDBConnection()!= 0){
      DebugN("WARNING::fwFSMConfDB_cacheAllRecipesForMode()-> Connection to ConfDB cannot establish. Forcing to use internal caches...");
      useConfDB = FALSE;  //Force usage of caches
    } //end of if connection fails
  }

 //Check useConfDB again as it may have changed in the previous if, i.e. if DB connection could not be established   
 if(useConfDB){
    
   //Get list of recipes in DB for the given running mode 
   DebugN("INFO: fwFSMConfDB_cacheAllRecipesForMode() -> Accessing ConfDB to load all recipes.");
   fwConfigurationDB_findRecipesInDB(allRecipeTags,
                                    exceptionInfo,
                                    sMainMode+"*",
                                    g_sFwDevice_HIERARCHY);
   
   fwConfigurationDB_findRecipesInDB(defaultRecipeTags,
                                    exceptionInfo,
                                    fwFSMConfDB_getDefaultModeName() +"*",
                                    g_sFwDevice_HIERARCHY);

   dynAppend(allRecipeTags, defaultRecipeTags);
   
   if(dynlen(exceptionInfo) > 0){
       DebugN("ERROR::fwFSMConfDB_cacheAllRecipesForMode()->" + exceptionInfo); 
       return fwFSMConfDB_ERROR;
     }
   
   }
   else{//Get list of recipes in cache for the given running mode   
     DebugN("INFO: fwFSMConfDB_cacheAllRecipesForMode() -> Accessing internal caches to load all recipes.");    
 
     fwConfigurationDB_findRecipesInCache(allRecipeTags,
                                          exceptionInfo,
                                          sMainMode+"*");
     
     fwConfigurationDB_findRecipesInCache(defaultRecipeTags,
                                          exceptionInfo,
                                          fwFSMConfDB_getDefaultModeName() +"*",
                                          g_sFwDevice_HIERARCHY);
   
     dynAppend(allRecipeTags, defaultRecipeTags);
     
     if(dynlen(exceptionInfo) > 0){
       DebugN("ERROR::fwFSMConfDB_cacheAllRecipesForMode()->" + exceptionInfo); 
       return fwFSMConfDB_ERROR;
       }
     
     //  Remove fwFSMConfDB caches from list of caches                                
     for(int ii = 1; ii <=dynlen(allRecipeTags); ii++){
       if(patternMatch("*" + g_CachePrefix + "*", allRecipeTags[ii])){
        dynRemove(allRecipeTags, ii);
        ii--;
       }      
     } 
   } //end of retrieval of caches
   
   
  //recipe filter in case the users defined a recipePattern to reduce the list of recipes to be loaded
  if(recipePattern!="")
  {
    for(int ii = 1; ii <=dynlen(allRecipeTags); ii++){
       if(strpos(allRecipeTags[ii],recipePattern)<0){
         dynRemove(allRecipeTags, ii);
         ii--;
         }      
       }     
  }
  
  // select only recipes for the current running mode.  
//DebugN("Starting filtering on modes: ", modesPattern);  
  for(int i = 1; i <= dynlen(modesPattern); i++)
  {
    for(int j = 1; j <= dynlen(allRecipeTags); j++)
    {
      if(patternMatch(modesPattern[i] + "/*", allRecipeTags[j]))
        dynAppend(modeRecipeTags, allRecipeTags[j]);
    }
  }
  
//DebugN("After mode filtering: ", modeRecipeTags);

  if(dynlen(modeRecipeTags)!=0)
  {                                          
   
//--------------------------------------------------------------------------------------------------------------
// new code 04.05.2007    
  
   //list of commands handled by the configurator
    dpGet(sConfigurator + g_csCommandsDPE, stateCommands);
    
    //find the recipes related with FSM commands

    //It could happen that there are recipes like PHYSICS/GOTO_READY and PHYSICS/GOTO_READY_1, etc.
    //In order to also load them and create separate caches, they will be treated as it there were separate commands for these recipes.
    dyn_string realStateCommands = stateCommands; //Copy the list of command to a temporary varialbe
    dyn_string recipesTemp = modeRecipeTags;       //Copy the list of recipes for the mode to a temp variable.
    dyn_string potentialCommands;                 //List of all possible/potential commands
    potentialCommands = modeRecipeTags;           //Assign recipe names to list of potential commands. Later the run mode will be dropped

    for(int i = 1; i <= dynlen(recipesTemp); i++)
    {
      for(int j = 1; j <= dynlen(modesPattern); j++)
      strreplace(potentialCommands[i], modesPattern[j] + "/", ""); //Drop the mode from the string
      //strreplace(potentialCommands[i], sMode + "/", ""); //Drop the mode from the string
    }

//DebugN("Potential commands: ", potentialCommands);    
            
    for(int i = 1; i <= dynlen(realStateCommands); i++) //loop over the real commmands and see if there are 
    {
      dynAppend(stateCommands, dynPatternMatch(realStateCommands[i]+ "_*", potentialCommands));
    }
//DebugN("stateCommands", stateCommands);    

   //Get all devices handled by the configurator 
   //If ignoreDeviceList is active device list should be empty, configurator loads the full recipe
    if(ignoreDeviceList)
      dynClear(deviceList);
    else
      deviceList = fwFSMConfDB_getConfiguratorDevices(sConfigurator);
           
    for(int i = 1; i<=dynlen(stateCommands); i++){
      dynClear(recipeObject);
      dynClear(commandRecipes);
	
      dynAppend(commandRecipes, dynPatternMatch("*/" + stateCommands[i], modeRecipeTags));    
   
      if(!dynlen(commandRecipes))
        continue;
      
      cacheName = g_CachePrefix + g_csFwFSMConfDBDelimiter+ sDomain + g_csFwFSMConfDBDelimiter + commandRecipes[dynlen(commandRecipes)];  
      
      DebugN("INFO::Loading recipe: " + commandRecipes[dynlen(commandRecipes)] + " for domain: " + sDomain + ". Please wait...");
   
//      for(int ii = 1; ii <=dynlen(commandRecipes); ii++)
      for(int ii = dynlen(commandRecipes); ii >=1; ii--)
       {
//DebugN(">>>>Loading recipe: " + commandRecipes[ii]);        
        commandRecipeStr = commandRecipes[ii];
        dynClear(tempRecipeObject);
        if(useConfDB){ 
          fwConfigurationDB_loadRecipeFromDB(commandRecipes[ii],
					    deviceList, 
					    g_sFwDevice_HIERARCHY, 
                                            tempRecipeObject,
         				    exceptionInfo,
                                            systemName,
 					     "");
	
         }else{
          fwConfigurationDB_loadRecipeFromCache(commandRecipes[ii],    
                                               deviceList,  
                                               g_sFwDevice_HIERARCHY,
                                               tempRecipeObject,  
                                               exceptionInfo,
                                               systemName);  
         }
         
         if(dynlen(recipeObject) > 0)
           fwFSMConfDB_combineRecipes(recipeObject,
	  			      tempRecipeObject, //New recipe object
				      recipeObject,     //Old recipe object
                                      exceptionInfo,
				      fwFSMConfDB_defaultRecipeMergeMode);
         else
           recipeObject = tempRecipeObject;
               
         //Check exception.
         if(dynlen(exceptionInfo) > 0){
           DebugN("ERROR::fwFSMConfDB_cacheAllRecipesForMode()->" + exceptionInfo); 
           return fwFSMConfDB_ERROR;
         }

      } // end of loop over commandRecipes
    
    if(dynlen(recipeObject[2]) <= 0) //if there is no device in recipe object, try next command
      continue;
    
   // Check that all devices in the list are defined in the recipe, ignore if ignoreDeviceList is active
    if(!ignoreDeviceList) 
    { 
     recipeDevices =  recipeObject[2];     
     commonDevices = dynIntersect(recipeDevices, deviceList); 

     if(dynlen(commonDevices) != dynlen(deviceList))
      {  
       if(bStopOnError)
        {
         DebugN("ERROR: fwFSMConfDB_cacheAllRecipesForMode() -> Some devices are missing in the recipe: " + commandRecipeStr + " for FSM domain: " + sDomain + " and the flag bStopOnError is set to true. Aborting...");         
         return fwFSMConfDB_ERROR;
         } else    
            DebugN("WARNING: fwFSMConfDB_cacheAllRecipesForMode()-> Some devices are missing in the recipe: " + commandRecipeStr + " for FSM domain: " + sDomain);
      }
    }

    //Store recipe object in cache
     fwConfigurationDB_saveRecipeToCache(recipeObject,  
                                         g_sFwDevice_HIERARCHY, 
                                         cacheName,  
                                         exceptionInfo); 

     if(dynlen(exceptionInfo) > 0) { 
       DebugN("ERROR::fwFSMConfDB_cacheAllRecipesForMode()->" + exceptionInfo); 
       return fwFSMConfDB_ERROR; 
      }
  }//end of loop over state commands;
      
  }
  
  //Look for user recipes to load    
  dpGet(sConfigurator+".userRecipes", userRecipes);
  
  if(dynlen(modeRecipeTags)==0 && stopNoRecipes && dynlen(userRecipes) <= 0) {  
    DebugN("ERROR:: No recipes found for mode " + sMode + ". Moving to state ERROR.");
    return fwFSMConfDB_ERROR; 
  }
  else if(dynlen(modeRecipeTags) <= 0 && dynlen(userRecipes) <= 0)
    DebugN("INFO:: No recipes found for mode " + sMode + ". Moving to state OK.");
  
  int err = 0;
  // don't load userRecipes when using cache
  if(dynlen(userRecipes)>0 && useConfDB)
   {
    for(int i = 1; i <=dynlen(userRecipes); i++)
     {       
      strreplace(userRecipes[i], "$sMode", sMode);
      
      DebugN("INFO::Loading user recipe: " + userRecipes[i]);
      //Check that the recipe exists if flag stopNoRecipes is set:   
      fwConfigurationDB_loadRecipeFromDB(userRecipes[i],
				         "", 
				         g_sFwDevice_HIERARCHY, 
				         recipeObject,
         			         exceptionInfo,
                                         systemName,
 				         "");
//     if(dynlen(exceptionInfo) > 0) { 
//           DebugN("WARNING::fwFSMConfDB_cacheAllRecipesForMode()-> Recipe " + userRecipes[i] + " not found."); 
//           continue;
//     }
     
     if(stopNoRecipes && dynlen(recipeObject) <= 0) //recipe not found
     {
        DebugN("ERROR:: User recipe not found: " + userRecipes[i] + ". Stop if no recipe found flag set. Moving to state ERROR.");
        return fwFSMConfDB_ERROR; 
     }
      
    //Store recipe object in cache
     if(dynlen(recipeObject))
       fwConfigurationDB_saveRecipeToCache(recipeObject,  
                                           g_sFwDevice_HIERARCHY, 
                                           userRecipes[i],  
                                           exceptionInfo);  
  
       if(dynlen(exceptionInfo) > 0) { 
           DebugN("ERROR::fwFSMConfDB_cacheAllRecipesForMode()->" + exceptionInfo); 
           ++err;
       }
    }
  }

      
  // insert mode in the list of loaded modes
  dynAppend(g_dsloadedModes, sMode);
  
  if(err)
    return fwFSMConfDB_ERROR;
  
  return fwFSMConfDB_OK;
}

/** Loads to PVSS caches all existing recipes in the confDB
 * @param sDomain name of the SMI++ control domain
 * @return error code: -1 in the event of error, 0 if OK
 */
int fwFSMConfDB_cacheAllRecipes(string sDomain)
{
  string systemName = "";
  string cacheName = "";
  dyn_string exceptionInfo;
  dyn_dyn_mixed recipeObject;
  dyn_string recipeTags;
  dyn_string deviceList; 

  //1.- Get the list of recipes available in database
  fwConfigurationDB_getRecipesInDB (recipeTags,
		                    exceptionInfo,
		                    "" );                                  
   
  //2.- Find the devices in this subtree:   
  deviceList = fwFSMConfDB_getDomainDevices(sDomain);

  //3.- Create one PVSS cache per recipe
  for(int i = 1; i <=dynlen(recipeTags); i++){ 		//Loop over recipes in DB

      cacheName = recipeTags[i];  //For the time being, we create one cache per recipe

      //Load value for a device from the recipe in store it in a recipeObject
      fwConfigurationDB_loadRecipeFromDB(recipeTags[i],   
                                         deviceList,  
                                         g_sFwDevice_HIERARCHY,   
                                         recipeObject,  
                                         exceptionInfo,
                                         systemName,
                                         "");                       
      //Store recipe object in cache
      fwConfigurationDB_saveRecipeToCache(recipeObject,  
                                          g_sFwDevice_HIERARCHY,  
                                          cacheName,  
                                          exceptionInfo);  
                         
      if(dynlen(exceptionInfo) > 0) { 
        //fwExceptionHandling_display(exceptionInfo); 
        DebugN("ERROR::" + exceptionInfo); 
        return fwFSMConfDB_ERROR; 
      }
    }
  return fwFSMConfDB_OK;
}

/** Sets the state of the FSMConfDB Configurator
 * @param sDevice name of the device to set the device to
 * @param sState desired state
 * @return error code: -1 in the event of error, 0 if OK
 */
int fwFSMConfDB_setState(string sDevice, string sState)
{
  int val;
  switch(sState){
    case g_csReadyState: val = 1;
                       break;
    case g_csErrorState: val = -1;
                       break;
    case g_csNotReadyState:   val = 0;
                       break;
    default:           val = -2;
                       DebugN("ERROR: Unknown state: " + sState + " of device: " + sDevice);

  }
  return dpSet(sDevice + ".status", val);

}

/** Sets the running mode to the FSMConfDB Configurator
 * @param sConfigurator name of the FSMConfDB configurator
 * @param sMode experiment's running mode
 * @return error code: -1 in the event of error, 0 if OK
 */
int fwFSMConfDB_setCurrentMode(string sConfigurator, string sMode)
{
  return dpSet(sConfigurator + ".currentMode", sMode);
}

/** Gets the running mode(PHYSICS,COSMICS,...) to the FSMConfDB Configurator
 * @param sConfigurator name of the FSMConfDB configurator
 * @return current running mode
 */
string fwFSMConfDB_getCurrentMode(string sConfigurator)
{  
  string mode;
  dpGet(sConfigurator + ".currentMode", mode);

  return mode;
}

/** Applies a recipe cache associated to a FSM command to a device
 * @param sDomain name of the SMI++ domain
 * @param sDevice name of the device to apply the recipe to
 * @param sCommand SMI++ command
 * @param sMode running mode. This parameter is optional. If empty, it is current running mode 
 * resolved by the function
 * @return error code: -1 in the event of error, 0 otherwise
 */
int fwFSMConfDB_applyRecipe(string sDomain, string sDevice, string sCommand, string sMode = "")
{
 return fwFSMConfDB_ApplyRecipe(sDomain, sDevice, sCommand, sMode = "");
  }


/** Applies a recipe cache associated to a FSM command to a device
 * @param sDomain name of the SMI++ domain
 * @param sDevice name of the device to apply the recipe to
 * @param sCommand SMI++ command
 * @param sMode running mode. This parameter is optional. If empty, it is current running mode 
 * resolved by the function
 * @return error code: -1 in the event of error, 0 otherwise
 * @deprecated use @ref fwFSMConfDB_applyRecipe instead
 */
int fwFSMConfDB_ApplyRecipe(string sDomain, string sDevice, string sCommand, string sMode = "")
{
  string configurator;
  dyn_dyn_mixed recipeObject;
  dyn_string exceptionInfo;

  if(sMode == ""){
    configurator = fwFSMConfDB_getDomainConfigurator(sDomain);
    sMode = fwFSMConfDB_getCurrentMode(configurator);
  }

  //Cache name:
  string cache;
  
  if(fwFSMConfDB_getCache(sDomain, sDevice, sCommand, sMode, cache)!=0)
     return fwFSMConfDB_ERROR;

  fwConfigurationDB_loadRecipeFromCache(cache, makeDynString(sDevice), g_sFwDevice_HIERARCHY, recipeObject, exceptionInfo);  
  
  fwConfigurationDB_applyRecipe(recipeObject, g_sFwDevice_HIERARCHY, exceptionInfo); 
  
  if(dynlen(exceptionInfo)>0)  
    {
     DebugN("ERROR: " + exceptionInfo); 
     return fwFSMConfDB_ERROR;
     }
  
  return fwFSMConfDB_OK; 
}

/** Applies a user recipe cache associated to a device or group of devices
 * @param sDomain name of the SMI++ domain
 * @param devices list of devices to apply the recipe to
 * @return error code: -1 in the event of error, 0 otherwise
 */
int fwFSMConfDB_applyUserRecipe(string recipeName, dyn_string devices = "")
{
  dyn_dyn_mixed recipeObject;
  dyn_string exceptionInfo;

  fwConfigurationDB_loadRecipeFromCache(recipeName, devices, g_sFwDevice_HIERARCHY, recipeObject, exceptionInfo);  
  
  fwConfigurationDB_applyRecipe(recipeObject, g_sFwDevice_HIERARCHY, exceptionInfo); 
  
  if(dynlen(exceptionInfo)>0)  
    {
     DebugN("ERROR: " + exceptionInfo); 
     return fwFSMConfDB_ERROR;
     }

  return fwFSMConfDB_OK; 
}

/** Checks that all devices specified in the second argument are defined in the corresponding recipe
 * @param sRecipe name of the recipe
 * @param dsDevices list of requested devices
 * @param dsCommonDevices sublist of devices from the requested list of devices properly defined in the recipe
 * @param useConfDB optional flag to indicate whether to get the Recipe from the DB or Cache. The default value is FALSE.
 * @return 0 if all requested devices are properly defined in the recipe or -1 if there is a mismatch
 */

int fwFSMConfDB_checkDevicesInRecipe(string sRecipe, dyn_string dsDevices, dyn_string &dsCommonDevices, bool useConfDB = false)
{
  dyn_dyn_mixed recipeObject;
  dyn_string exceptionInfo;
  string systemName = getSystemName();
  dyn_string recipeDevices;

  dynClear(dsCommonDevices);

  if(useConfDB){
    fwConfigurationDB_loadRecipeFromDB(sRecipe,  
                                       "",  
                                       g_sFwDevice_HIERARCHY,  //This has to change. Cannot be hardcoded 
                                       recipeObject,  
                                       exceptionInfo,
                                       systemName,
                                       "");  
  }else{
    fwConfigurationDB_loadRecipeFromCache(sRecipe,    
                                          "",  
                                          g_sFwDevice_HIERARCHY,  //This has to change. Cannot be hardcoded
                                          recipeObject,  
                                          exceptionInfo,
                                          systemName);  
  }
     
  if(dynlen(exceptionInfo) > 0){
    DebugN("ERROR: fwFSMConfDB_checkDevicesInRecipe() -> " + exceptionInfo);
    return fwFSMConfDB_ERROR;
  }
  recipeDevices =  recipeObject[2]; 

  dsCommonDevices = dynIntersect(recipeDevices, dsDevices); 

  if(dynlen(dsCommonDevices) != dynlen(dsDevices))
  {        
    DebugN("WARNING: fwFSMConfDB_checkDevicesInRecipe() -> Some of the requested devices are not defined in recipe: " + sRecipe);
    return fwFSMConfDB_ERROR;
  }
  
  return fwFSMConfDB_OK;
}


/**Get all CU's belonging to a Tree.
 * @param fsmTree name of the Tree
 * @param CUlist list of CUs in the tree
 */
int fwFSMConfDB_getAllTreeCUs(string fsmTree, dyn_string &CUlist)
{
  dyn_int children_types;

  dyn_string children,exInfo;
  
  dynClear(children_types);
  children = fwCU_getChildren(children_types,fsmTree);
  
  for(int i =1; i<=dynlen(children);i++)
  {
    if(children_types[i]==1)
    {
      dynAppend(CUlist,children[i]);
      fwFSMConfDB_getAllTreeCUs(children[i],CUlist);
    }
  }   
}

/**Get all CU's from all Tree's nodes
 * @return list of CUs
 */
dyn_string fwFSMConfDB_getAllCUs()
{
  dyn_string cuList;
  dyn_string exInfo;
  dyn_string nodes; 
  string domain;
 
  dynClear(cuList);

  //get all FSM nodes  
  fwTree_getAllNodes(nodes, exInfo);
  if(dynlen(exInfo) > 0){
    DebugN("ERROR: fwFSMConfDB_getAllCUs() -> " + exInfo);
    return makeDynString("");
  }
        
  //loop over the nodes in a tree and identify the CUs:
  for(int j = 1; j <= dynlen(nodes); j++){
    fwTree_getCUName(nodes[j], domain, exInfo);
    if(fwFsm_isCU(domain, nodes[j]) == 1)
    dynAppend(cuList, nodes[j]);
  }
  return cuList;
}

/** The function returns the name of the configurator to an SMI++ domain
* @param sDomain name of the SMI++ domain
* @return name of the configurator.
*/
string fwFSMConfDB_getConfiguratorName(string sDomain)
{
  return sDomain + "_ConfDB";
}

/** The function adds a configurator to a SMI++ domain.
* @param sDomain name of the SMI++ domain
* @param type configurator DU type
* @return Error code: 0 if all OK, -1 if error.
*/
int fwFSMConfDB_addConfigurator(string sDomain, string type = "")
{
  string dpName;
  string du;
  int isCu;
  dyn_string exceptionInfo;
    
  //check that we got a CU:
  fwTree_getNodeCU(sDomain,isCu,exceptionInfo);
  if(!isCu){
    DebugN("ERROR: fwFSMConfDB_addConfigurator() -> The node: " + sDomain + " is not a control unit. Aborted.");
    return fwFSMConfDB_ERROR;
  }
 
  dpName = fwFSMConfDB_getConfiguratorName(sDomain);

  // check if node already exists
  if(fwFsmTree_isNode(dpName)==1){
    DebugN("ERROR:Configurator "+dpName+ " already exists.");
    return fwFSMConfDB_ERROR;
    }
  
  //1.-Create associated dp:
   dpCreate(dpName, g_csFSMConfDBDPT);
 
  //2.-Create an alias for the configurator, used when working with logical hierarchy

   dpSetAlias(dpName+".",dpName);   
    
  //3.-Add Du to the SMI++ domain

   //default configurator type 
   if(type == "")
     type = g_csConfiguratorDUType;
   
   du = fwFsmTree_addNode(sDomain, dpName, type, 0);
     
  DebugN("DU added: " + dpName + " ->>>> to domain: " + sDomain);

  
  // START ATLAS specific mods
  // - create ATLAS_DU_STATUS node, if it does not already exist
  // - PWP 14.08.2009
  if(isFunctionDefined("fwFsmUser_Atlas")){
    return fwFSMConfDBAtlas_addStatusConfigurator(sDomain);
  }
  // END ATLAS specific mods
  
  
  return fwFSMConfDB_OK;
}


/** The function changes the configurator settings.
* @param sDomain name of the SMI++ domain
* @param applyRecipeMode 0:device, 1:configurator, 2:configurator in simplified mode
* @param applyRecipeTimeout optional, time interval to wait before the state of the configurator is set to ERROR, default is 20 sec. 
* @param recipeLocation optional flag to indicate whether to get the Recipe from the DB or Cache. The default value is FALSE. 
* @return Error code: 0 if all OK, -1 if error.
*/
int fwFSMConfDB_changeConfigurator(string sDomain, int applyRecipeMode, int applyRecipeTimeout=20, bool useConfDB=FALSE)
{
 string configuratorDP;
 bool simplifiedAR;
  
 configuratorDP=fwFSMConfDB_getConfiguratorName(sDomain);
  
 if(!dpExists(configuratorDP)){
    DebugN("ERROR: configurator for domain"+ sDomain +" does not exist, create configurator first");
    return fwFSMConfDB_ERROR;
  }
  
 if(applyRecipeMode==2)
  {
    simplifiedAR=TRUE;
    applyRecipeMode=TRUE;
  }
    else
      simplifiedAR=FALSE;
    
 dpSetWait(configuratorDP+g_csApplyRecipeUsingConfigurator,applyRecipeMode,
           configuratorDP+g_csApplyRecipeSimplified,simplifiedAR,
           configuratorDP+g_csApplyRecipesTimeout,applyRecipeTimeout,
           configuratorDP+g_csUseConfDBDPE,useConfDB); 

 if(applyRecipeMode==2)
       DebugN(configuratorDP+" parameters: Apply recipes in simplified mode, "+applyRecipeTimeout+" sec. timeout.");
       else if(applyRecipeMode==1)
            DebugN(configuratorDP+" parameters: Configurator apply all recipes, "+applyRecipeTimeout+" sec. timeout.");
            else
                DebugN(configuratorDP+" parameters: Each device apply recipe to itself."); 

 if(useConfDB)
   DebugN("Load recipes from DB");
   else
     DebugN("Load recipes from cache");
 
return fwFSMConfDB_OK;
}


/** Removes a configurator of an SMI++ domain.
* @param sDomain name of the SMI++ domain
* @param sConfigurator name of the configurator
* @return Error code: 0 if all OK, -1 if error.
*/
int fwFSMConfDB_removeConfigurator(string sDomain, string sConfigurator)
{
 if (dpExists(sConfigurator))
    dpDelete(sConfigurator);
   else
     DebugN(sConfigurator +" dp does not exist !");
      
 // Remove configurator node from the tree 
 fwFsmTree_removeNode(sDomain,sConfigurator,0);
 
 
  // START ATLAS specific mods
  // - delete ATLAS_DU_STATUS node, if it exists
  // - PWP 14.08.2009
  if(isFunctionDefined("fwFsmUser_Atlas")){
    fwFSMConfDBAtlas_removeStatusConfigurator(sDomain);
  }
  // END ATLAS specific mods
 
 //refresh the FSM tree in the Device Editor Navigator
 fwFsmTree_refreshTree();
 
 DebugN(sConfigurator+" deleted");
 
  return fwFSMConfDB_OK;
}


/** Add a configurator to all SMI++ domains for all trees.
* @return Error code: 0 if all OK, -1 if error.
*/
 int fwFSMConfDB_addAllConfigurators()
 {
  dyn_string nodes;

  nodes=fwFSMConfDB_getAllCUs();

  for(int i=1;i<=dynlen(nodes);i++)
  {
   if(fwFSMConfDB_addConfigurator(nodes[i])<0){
     DebugN("ERROR:fwFSMConfDB_addConfigurator()->Configurator was not added for node "+nodes[i]);
     return fwFSMConfDB_ERROR; 
    }
  }
  
  //refresh the FSM tree in the Device Editor Navigator
  fwFsmTree_refreshTree(); 
 
 return fwFSMConfDB_OK;
}

/**Removes the configurator name from a dp-name
 * @param sDpName name of the dp
 * @return dp-name without the configurator name
 */
string fwFSMConfDB_removeConfiguratorName(string sDpName)
{
  dyn_string ds;

  ds = strsplit(sDpName, "/");
  if(dynlen(ds) > 1)
    return ds[2];
  else 
    return ds[1];  
}

/** Gets the flag value that indicates the mode to be used to apply recipes
 * @param sConfigurator name of the configurator
 * @return 1: configurator applies recipes to all enabled devices in its CU,
 *         2: configurator applies the same recipe to all anabled devices(simplified APPLY_RECIPE)
 *         0: device apply recipe to itself 
*/
int fwFSMConfDB_getApplyRecipeUsingConfigurator(string sDomain)
{
  bool applyRecipeUsingConfigurator, simplifiedAR;
  string configurator = sDomain+"_ConfDB";
  string confExecutingAction;
                      
  dpGet(configurator+g_csApplyRecipeUsingConfigurator, applyRecipeUsingConfigurator,
        configurator+g_csApplyRecipeSimplified, simplifiedAR,
        sDomain + fwFsm_separator + configurator + fwDU_getFsmMidfix()+ ".executingAction",confExecutingAction);

  if(applyRecipeUsingConfigurator && confExecutingAction!="" && simplifiedAR)
    return 2;
    else if (applyRecipeUsingConfigurator && confExecutingAction!="" && !simplifiedAR)
           return 1;
         else
            return FALSE;
}

/**Waits for the requests of all the enabled devices that are executing an action 
 * @param sDomain name of the SMI++ domain
 * @param sConfigurator name of the configurator
 * @return error code: -1 in the event of error, 0 otherwise
 */
int fwFSMConfDB_waitForDevices(string sDomain, string sConfigurator)
{
  dyn_string deviceList,enabledDevices,enabledDeviceList;
  int delayInterval,timeout;
  int enabled,i;
  int t=0;
  string action;
  
  deviceList = fwFSMConfDB_getConfiguratorDevices(sConfigurator);

  //Read the delay interval parameter
  dpGet(g_csDelayInterval,delayInterval,sConfigurator+g_csApplyRecipesTimeout,timeout);
  

  for(i=1;i<=dynlen(deviceList);i++)
  {
    deviceList[i]=fwFSMConfDB_removeSystemName(deviceList[i]);
    fwUi_getEnabled(sDomain, deviceList[i], enabled);
    if(enabled){
      dynAppend(enabledDeviceList, sDomain + fwFsm_separator + deviceList[i] + fwDU_getFsmMidfix()+ ".executingAction");
     }
  }
  
  int previousActiveDevices;
  int activeDevices=dynlen(enabledDeviceList);
  dyn_anytype executingActions;
  
  do
  {
    previousActiveDevices = activeDevices;

    dpGet(enabledDeviceList, executingActions);    
    activeDevices=dynlen(executingActions)-dynCount(executingActions, "");    
    delay(0,500);
    }
  while (previousActiveDevices!=activeDevices);
  
 // DebugN("activeDevices="+activeDevices);
  
  while((activeDevices!=dynlen(g_dsDevicesList))&&(t< timeout))
     {
      delay(1);
      t++;  
     }
 // DebugN("devicesThatRequested: " + dynlen(g_dsDevicesList));
 // DebugN("Time:"+t);
  
  //DebugN("Enabled Devices: "+ dynlen(enabledDevices)+ " = devicesThatRequested: " + dynlen(g_dsDevicesList));

  if(t>=timeout){
    DebugN("ERROR:fwFSMConfDB_waitForDevices()->Timeout");
    return fwFSMConfDB_ERROR;
    }
    
  return fwFSMConfDB_OK;
}
 
/**Fuction used by the configurator to apply the recipes to all enabled devices in a CU
 * @param sDomain name of the SMI++ domain
 * @param sConfigurator name of the configurator
 * @param sMode running mode. This parameter is optional. If empty, it is current running mode 
 * resolved by the function
 * @return error code: -1 in the event of error, 0 otherwise
 */
int fwFSMConfDB_applyAllRecipesFromCache(string sDomain, string sConfigurator, string sMode = "")
{
  dyn_dyn_mixed recipeObject;
  dyn_string recipeDevices, commonDevices;
  dyn_string exceptionInfo;
  dyn_string deviceList,commandList;
  string device, command;
  string cache;
  dyn_string subModes, splitCUcommand;
  int   enabled,i,j, index;
  bool  recipeError;
  int applyRecipeMode;
  
   //checks if it's either the configurator or the device to apply the recipes
   applyRecipeMode = fwFSMConfDB_getApplyRecipeUsingConfigurator(sDomain);
     
   if(applyRecipeMode==0) // device apply recipe to itself
     return fwFSMConfDB_OK;
    
   if(sMode == ""){
     sMode = fwFSMConfDB_getCurrentMode(sConfigurator);
    }
              
   recipeError=FALSE;
    
  // -------------------- 2: simplified APPLY_RECIPE -----------------------------------------
  
   if(applyRecipeMode==2)  
    { 
     dpGet(sDomain +"|"+sDomain + ".fsm.executingAction:_online.._value",command);
     
     //remove command parameters
     splitCUcommand = strsplit(command,"/");
     
     command = splitCUcommand[1];
     
     deviceList = fwFSMConfDB_getConfiguratorDevices(sConfigurator);  

     for(i=1;i<=dynlen(deviceList);i++)
       {
       fwUi_getEnabled(sDomain, fwFSMConfDB_removeSystemName(deviceList[i]), enabled);
       if(!enabled){
         dynRemove(deviceList, i);
         i--;
         }
      }
     
     if(fwFSMConfDB_getCache(sDomain, device, command, sMode, cache)==0)
       {
         fwConfigurationDB_loadRecipeFromCache(cache, deviceList, g_sFwDevice_HIERARCHY, recipeObject, exceptionInfo);  

         fwConfigurationDB_applyRecipe(recipeObject, g_sFwDevice_HIERARCHY, exceptionInfo);  
      
         recipeDevices =  recipeObject[2]; 

         commonDevices = dynIntersect(recipeDevices, deviceList); 
         
         if(dynlen(commonDevices)!= dynlen(deviceList))       
           DebugN("WARNING: fwFSMConfDB_applyAllRecipesFromCache() -> Some of the devices are not defined in recipe: " + cache);
        }
       else
          {
           DebugN("ERROR:fwFSMConfDB_applyAllRecipesFromCache()-> Can't find recipe "+cache);
           return fwFSMConfDB_ERROR;
           }
         
       if(dynlen(exceptionInfo)>0) { 
              DebugN("ERROR: " + exceptionInfo);
              recipeError=TRUE;       
             }     
     } 
   
  // --------------------- 1: APPLY_RECIPE ----------------------------------------------------  
     else if(applyRecipeMode==1)
       {
        //Wait for the request of all devices
        if(fwFSMConfDB_waitForDevices(sDomain, sConfigurator) < 0){
        DebugN("ERROR: fwFSMConfDB_applyAllRecipesFromCache() -> Timeout of configurator "+sConfigurator);
        return fwFSMConfDB_ERROR;
          }
   
        commandList = g_dsDevicesCommandList;
        dynUnique(commandList);
   
        for(i=1;i<=dynlen(commandList);i++)
          { 
           dynClear(recipeObject);
      
          if(fwFSMConfDB_getCache(sDomain, device, commandList[i], sMode, cache)==0)
           {
            // filter the devices with the same command
            dynClear(deviceList);
       
            for(j=1;j<=dynlen(g_dsDevicesList);j++)
             {
              if(g_dsDevicesCommandList[j]==commandList[i]){
              dynAppend(deviceList,g_dsDevicesList[j]);
              }
             }

            fwConfigurationDB_loadRecipeFromCache(cache, deviceList, g_sFwDevice_HIERARCHY, recipeObject, exceptionInfo);  

            fwConfigurationDB_applyRecipe(recipeObject, g_sFwDevice_HIERARCHY, exceptionInfo);  
      
            recipeDevices =  recipeObject[2]; 

            commonDevices = dynIntersect(recipeDevices, deviceList); 
            
            if(dynlen(commonDevices)!= dynlen(deviceList))       
               DebugN("WARNING: fwFSMConfDB_applyAllRecipesFromCache() -> Some of the devices are not defined in recipe: " + cache);
     
            if(dynlen(exceptionInfo)>0) { 
              DebugN("ERROR: " + exceptionInfo);
              recipeError=TRUE;       
             }
           }
           else
            {
             DebugN("ERROR:fwFSMConfDB_applyAllRecipesFromCache()-> Can't find recipe "+cache);
             recipeError=TRUE;
             }     
          } //end loop over commands
           
     dynClear(g_dsDevicesCommandList);
     dynClear(g_dsDevicesList);
    } // end APPLY_RECIPE
  
  if(recipeError){
    DebugN("ERROR: fwFSMConfDB_applyAllRecipesFromCache() -> Some recipes were not applied correctly");
    return fwFSMConfDB_ERROR;
   }
  
  return fwFSMConfDB_OK;
}

/** Checks if it's either the configurator or the device to apply the recipe and calls respectively the function 
 * fwFSMConfDB_requestApplyRecipes()or fwFSMConfDB_applyRecipe().
 * @param sDomain name of the SMI++ domain
 * @param sDevice name of the device to apply the recipe to
 * @param sCommand SMI++ command
 * @param sMode running mode. This parameter is optional. If empty, it is current running mode 
 * @return error code: -1 in the event of error, 0 otherwise
 */
int fwFSMConfDB_applyRecipeFromCache(string sDomain, string sDevice, string sCommand, string sMode = "")
{
  return fwFSMConfDB_ApplyRecipeFromCache(sDomain, sDevice, sCommand, sMode = "");
  }

/** Checks if it's either the configurator or the device to apply the recipe and calls respectively the function 
 * fwFSMConfDB_requestApplyRecipes()or fwFSMConfDB_ApplyRecipe().
 * @param sDomain name of the SMI++ domain
 * @param sDevice name of the device to apply the recipe to
 * @param sCommand SMI++ command
 * @param sMode running mode. This parameter is optional. If empty, it is current running mode 
 * @return error code: -1 in the event of error, 0 otherwise
 * @deprecated use @ref fwFSMConfDB_applyRecipeFromCache instead
 */
int fwFSMConfDB_ApplyRecipeFromCache(string sDomain, string sDevice, string sCommand, string sMode = "")
{
  dyn_string deviceList;
  int applyRecipeMode;

// F.Calheiros: changed 12.07.06 
// get the alias name of sDevice when working with fwDevice_LOGICAL, otherwise add system name to sDevice name
  
/*  if(fwFsm_isLogicalDeviceName(sDevice)){
    sDevice = dpGetAlias(getSystemName()+sDevice+".");
    }
    else 
       sDevice = getSystemName() + sDevice;
*/
  
  deviceList = fwFSMConfDB_getConfiguratorDevices(fwFSMConfDB_getConfiguratorName(sDomain));
  
  if(dynContains(deviceList,getSystemName()+sDevice)>0)
    sDevice = getSystemName() + sDevice;
    else
       sDevice = dpGetAlias(getSystemName()+sDevice+".");   
  
  applyRecipeMode = fwFSMConfDB_getApplyRecipeUsingConfigurator(sDomain);
  
  if(applyRecipeMode==1)
   {   
    fwFSMConfDB_requestApplyRecipes(sDomain, sDevice, sCommand);
   }
    else if(applyRecipeMode==0)
           {
             if(fwFSMConfDB_applyRecipe(sDomain, sDevice, sCommand, sMode)<0)
                return fwFSMConfDB_ERROR;
           }
    
 return fwFSMConfDB_OK;
}

/**Finds the index number of the sDevice in the list of devices handle by a FSMConfDB configurator
 * @param sDomain Name of the SMI++ domain as a string
 * @param sDevice name of the SMI++ device
 * @return the index of the device, 0 if device doesn't exist in the list
*/
int fwFSMConfDB_findDeviceNumber(string sDomain, string sDevice)
{
  dyn_string deviceList;
  int index;
  deviceList = fwFSMConfDB_getConfiguratorDevices(fwFSMConfDB_getConfiguratorName(sDomain));
  
  if(dynContains(deviceList,sDevice)<=0)
     sDevice = dpGetAlias(getSystemName()+sDevice+".");

  return dynContains(deviceList,sDevice);
}

/**Request configurator to apply recipe(populate configurator's variables)if command comes from a parent, 
 * otherwise apply recipe to current device
 * @param sDomain Name of the SMI++ domain as a string
 * @param sDevice name of the SMI++ device
 * @param sCommand SMI++ command
 * @param sMode running mode. This parameter is optional. If empty, it is current running mode 
 * resolved by the function
 * @return error code: -1 in the event of error, 0 otherwise
*/

int fwFSMConfDB_requestApplyRecipes(string sDomain, string sDevice, string sCommand, string sMode = "")
{
  int deviceNumber;
//  string type;

     deviceNumber = fwFSMConfDB_findDeviceNumber(sDomain,sDevice);

     if(deviceNumber>0)
      {
 	dynInsertAt(g_dsDevicesCommandList,sCommand,deviceNumber);
        dynInsertAt(g_dsDevicesList,sDevice,deviceNumber); 
       }  
     else{
         DebugN("The device is not in configurator list");
         return fwFSMConfDB_ERROR;
       }
 return fwFSMConfDB_OK;
}


void fwFSMConfDB_DUTinitialize(string domain, string device) 
{        
  fwFSMConfDB_initialize(domain, device);  
}
  
void fwFSMConfDB_DUTvalueChanged( string domain, string device, int status, string &fwState ) 
{ 
  
  // START ATLAS specific mods
  // - ATLAS has STATE and STATUS
  // - READY/NOT_READY are STATEs, ERROR is STATUS
  // - set state of ATLAS_DU_STATUS node, if it exists
  // - PWP 14.08.2009
  if(isFunctionDefined("fwFsmUser_Atlas")){
    fwFSMConfDBAtlas_DUTvalueChanged(domain, device, status, fwState); 
    return;  // Return if device existed, otherwise default to old behaviour
  }
  // END ATLAS specific mods
  
  if (status > 0)  
  {  
    fwState = g_csReadyState;  
  }  
  else if (status > -1) 
  { 
    fwState = g_csNotReadyState; 
  } 
  else  
  { 
    fwState = g_csErrorState; 
  } 
} 

void fwFSMConfDB_DUTdoCommand(string domain, string device, string command)  
{   
      string mode = "";    
	if (command =="APPLY_RECIPE")  
	{  
           fwDU_getCommandParameter(domain, device, "sMode", mode);      
           if(fwFSMConfDB_applyAllRecipesFromCache(domain, device, mode) == 0) {      
              fwFSMConfDB_setState(device, g_csReadyState);     
            }    
            else {     
               fwFSMConfDB_setState(device, g_csErrorState);                  
            }                
	 }    
	else if (command == "LOAD")  
	{ 
  // START ATLAS specific mods
  // - reinitialise DB connection if status is error
  //   (ATLAS does not allow ERROR STATE ;-) )
  // - PWP 14.08.2009
  if(isFunctionDefined("fwFsmUser_Atlas")){
    if(fwFSMConfDBAtlas_DUTdoCommand(domain, device, command) < 0)
      return;
  }
  // END ATLAS specific mods
    
            fwDU_getCommandParameter(domain, device, "sMode", mode);    
            fwFSMConfDB_setCurrentMode(device, mode);    
    
            if(fwFSMConfDB_cacheAllRecipesForMode(domain, mode) == 0) {   
                fwFSMConfDB_setState(device, g_csReadyState);     
              }     
              else {    
                fwFSMConfDB_setState(device, g_csErrorState);    
              }                                 
	}   
	else if (command == "RECOVER")  
	{      
          if(fwFSMConfDB_getUseConfDB(device))
           {
            if(fwFSMConfDB_initConfDBConnection()!= 0){
              fwFSMConfDB_setState(device, g_csErrorState);
              // Fernando - why no return here? PWP
              }
            }   
         fwFSMConfDB_setState(device, g_csNotReadyState);
       
	}   
        else if (command ==  "UNLOAD")    
        {      
            dynClear(g_dsloadedModes); 
            fwFSMConfDB_setState(device, g_csNotReadyState);     
        }  
}  
  
/** Retrieves the cache name where the configuration information is stored for a given mode and command
 * in a SMI++ domain
 * @param sDomain name of the SMI++ control domain
 * @param sDevice name of the device to be configured
 * @param sCommand name of the command associated with the cache
 * @param sMode running mode of the experiment to load the recipes for
 * @param sCache name of the cache holding the configuration information
 * @return error code: -1 in the event of error, 0 if OK
 */
int fwFSMConfDB_getCache(string sDomain, string sDevice, string sCommand, string sMode, string &sCache)
{
  
  dyn_string subModes;
  
  sCache =  g_CachePrefix + g_csFwFSMConfDBDelimiter + sDomain + g_csFwFSMConfDBDelimiter + sMode + g_csFwFSMConfDBDelimiter + sCommand; 
  
  if(fwFSMConfDB_cacheExists(sCache)!=0) //recipe cache not found
   {
     subModes = strsplit(sMode,g_csModeDelimiter);
     if(dynlen(subModes)>1)
     {
       strreplace (sMode,g_csModeDelimiter+subModes[dynlen(subModes)],"");
       fwFSMConfDB_getCache(sDomain, sDevice, sCommand, sMode,sCache);
     }
     else
        { // look for existing "DEFAULT" recipes
         sCache = g_CachePrefix + g_csFwFSMConfDBDelimiter + sDomain + g_csFwFSMConfDBDelimiter + fwFSMConfDB_getDefaultModeName()+ g_csFwFSMConfDBDelimiter + sCommand;
         if(fwFSMConfDB_cacheExists(sCache)!=0)   // "DEFAULT recipe not found"
           {
            DebugN("ERROR: fwFSMConfDB_getCache() -> Could not find recipe: "+sCache+". Aborting...");
            return fwFSMConfDB_ERROR;
           }
        }
    }
   
 return fwFSMConfDB_OK;
}


////////////////////////Function belonging to the FW Configuration DB Tool////////////

/** combines two recipe objects
 * This function combines two recipe object into third object.
 * For the entries that exist in both source recipes,
 * the one in the second recipe have precedence, and will be used.
 *
 * The meta-information is treated in the following way:
 * if there is no meta information yet in the first recipe,
 * the meta information from @em srcRecipeObject2 is taken;
 * otherwise, if there is already a meta-information in the
 * @em srcRecipeObject1, it is discarded except the recipe type
 * name - this one will be set in the @em dstRecipeObject if
 * it is set in both srcRecipeObjects to equal values.
 *
 * @param dstRecipeObject  on return will contain the combined recipe
 * @param srcRecipeObject1  first recipe to combine
 * @param srcRecipeObject2  second recipe to combine
 * @param exceptionInfo standard exception handling variable
 * @param mergeMode (optional, default="")  determines the mode
 *		in which the merge is performed;
 *		"DEVICE" - the mode is per device
 *		"ELEMENT" - the mode is per element
 *		"" - take the global setting
 *
 * @ingroup RecipeFunctions
 * @see @ref qstart_recipes section of Quick Start
 */
void fwFSMConfDB_combineRecipes(dyn_dyn_mixed &dstRecipeObject,
				dyn_dyn_mixed srcRecipeObject1,
				dyn_dyn_mixed srcRecipeObject2,
				dyn_string &exceptionInfo,
				string mergeMode="")
{  
    time t0;
    _fwConfigurationDB_startFunction("combineRecipes", t0);

    if (mergeMode=="") {
	mergeMode=fwConfigurationDB_defaultRecipeMergeMode;
    };
    
    if (mergeMode!="DEVICE" && mergeMode!="ELEMENT"){
	fwException_raise(exceptionInfo,"ERROR in combineRecipes","Bad mergeMode="+mergeMode,"");
	return;
    }

    if (!dynlen(srcRecipeObject1)) _fwConfigurationDB_ClearRecipeObject(srcRecipeObject1);
    if (!dynlen(srcRecipeObject2)) _fwConfigurationDB_ClearRecipeObject(srcRecipeObject2);

    dyn_dyn_mixed recipeObject;
    _fwConfigurationDB_ClearRecipeObject(recipeObject);

    dyn_string names1=srcRecipeObject1[fwConfigurationDB_RO_DPE_NAME];   // need to cast to dyn_string
    dyn_string names2=srcRecipeObject2[fwConfigurationDB_RO_DPE_NAME]; // need to cast to dyn_string

    dyn_string commonNames=dynIntersect(names2,names1);
    // we alse need to treat the cases of dbRecipeObject[fwConfigurationDB_RO_DPE_NAME][i]=="",
    // i.e. where the logical device was not mapped to any hardware devices...
    int idxCommon=dynContains(commonNames,""); if (idxCommon) dynRemove(commonNames,idxCommon);

    dyn_string deviceNames1,deviceNames2;
    dyn_string commonDeviceNames;
    if (mergeMode=="DEVICE") {
	// extract device names
	for (int i=1;i<=dynlen(names1);i++) {
	    dyn_string ds=strsplit(names1[i],".");
	    if (dynlen(ds)<1) ds[1]="";
	    dynAppend(deviceNames1,ds[1]);
	}
	for (int i=1;i<=dynlen(names2);i++) {
	    dyn_string ds=strsplit(names2[i],".");
	    if (dynlen(ds)<1) ds[1]="";
	    dynAppend(deviceNames2,ds[1]);
	}
	dyn_string uniqDevNames1=deviceNames1;
	dyn_string uniqDevNames2=deviceNames2;
	dynUnique(uniqDevNames1);
	dynUnique(uniqDevNames2);
	commonDeviceNames=dynIntersect(uniqDevNames2,uniqDevNames1);
        
	int idxCommonDevices=dynContains(commonDeviceNames,""); if (idxCommonDevices) dynRemove(commonDeviceNames,idxCommonDevices);
    }
    


    int idx=0;
    // get the ones from the first recipe, that are not in the second one...
    for (int i=1;i<=dynlen(names1);i++) {
      
	bool doCopy=FALSE;
	if (names1[i]=="") {
	    // again: in the case of a not-mapped logical device we need extra treatment:
	    //  look at the DP_NAME column, and see if it is there
	    int idx1=dynContains(srcRecipeObject2[fwConfigurationDB_RO_DP_NAME],srcRecipeObject1[fwConfigurationDB_RO_DP_NAME][i]);
	    if (!idx1) {
		// dp name ain't match: it does not exits in srcRecipeObject2, so we want to copy it...
		doCopy=TRUE;
	    } else {
		if (mergeMode=="DEVICE") {
		    doCopy=FALSE;
		    continue;
		}
		// and for the mergeMode=ELEMENT, the answer is not so simple...
		// the element name exists somewhere - we need to do thorough checking at the element level...
		doCopy=TRUE;
		for (int k=1;k<=dynlen(names2);k++) {
		    if ( (srcRecipeObject2[fwConfigurationDB_RO_DP_NAME][k]==srcRecipeObject1[fwConfigurationDB_RO_DP_NAME][i]) &&
		         (srcRecipeObject2[fwConfigurationDB_RO_ELEMENT_NAME][k]==srcRecipeObject1[fwConfigurationDB_RO_ELEMENT_NAME][i]) ) {

			doCopy=FALSE;
			continue;
		    }
		}
	    }
	} else {
	    // majority of cases is here - the name is specified OK
	    if (mergeMode=="ELEMENT") {
		if (!dynContains(commonNames,names1[i])) {
		    doCopy=TRUE;
		}
	    } else if (mergeMode=="DEVICE") {
              if (!dynContains(commonDeviceNames,deviceNames1[i])) { //if the device in the first recipe object i not in the list of common devices, copy its value
		    doCopy=TRUE;
		}
	    }
	}

	if (doCopy) {
	    // copy!
	    idx++;
	    for (int j=1;j<=fwConfigurationDB_RO_MAXIDX;j++)
            {
              recipeObject[j][idx]=srcRecipeObject1[j][i];
            }
	}
    }

    // now append all the entries from second recipe
    for (int i=1;i<=fwConfigurationDB_RO_MAXIDX;i++) {
	dynAppend(recipeObject[i],srcRecipeObject2[i]);
    }


    // if the meta info already exist in the first recipe, wipe it out - it's not valid anymore;
    // otherwise, get the one from srcRecipeObject2...
    int len1=dynlen(srcRecipeObject1);
    if (len1>=fwConfigurationDB_RO_METAINFO_START) {
	// simply: don't copy anything - i.e. we will have these cleared.

	// unlesss... we have the same recipeType in both...
	string rtype1,rtype2;
	int rc1=_fwConfigurationDB_getRecipeOriginalRecipeType(srcRecipeObject1, rtype1, exceptionInfo);
	int rc2=_fwConfigurationDB_getRecipeOriginalRecipeType(srcRecipeObject2, rtype2, exceptionInfo);
	if (dynlen(exceptionInfo)) return;
	if ( (rc1==0) && (rc2==0) && (rtype1==rtype2) )
	_fwConfigurationDB_setRecipeOriginalRecipeType(recipeObject, rtype1, exceptionInfo);
	if (dynlen(exceptionInfo)) return;

    } else {
	// there was nothing in src1, so we adopt the thing from src2
	int len2=dynlen(srcRecipeObject2);
	for (int i=fwConfigurationDB_RO_METAINFO_START;i<=fwConfigurationDB_RO_METAINFO_END;i++) {
	    if (i>len2) break;
	    dyn_mixed col=srcRecipeObject2[i];
	    recipeObject[i]=col;
	}

    }

    dstRecipeObject=recipeObject;
    _fwConfigurationDB_endFunction("combineRecipes", t0);
}


