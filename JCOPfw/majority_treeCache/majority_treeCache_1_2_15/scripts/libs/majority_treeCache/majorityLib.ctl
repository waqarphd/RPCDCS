#uses "email.ctl"
#uses "majority_treeCache/treeCache.ctl"

/*
  Majority library --- general algorithm to keep state counts of devices updated for a generic FSM tree
  
  For customization see the instructions at http://lomasett.web.cern.ch/lomasett/treeCache_Majority/
 

  Authors: Manuel FAHRER (manuel.fahrer@cern.ch), Lorenzo MASETTI (lorenzo.masetti@cern.ch), CMS Tracker Control System
  Contact: Lorenzo MASETTI (lorenzo.masetti@cern.ch) CMS Central DCS
*/

const int      majority_TOTALZERO = -1;
const int      majority_OFF = 0; // none of the devices are in the state ( perc = 0% )
const int      majority_MIXED = 1; // some of the devices are in the state ( 0% < perc < maj% )
const int      majority_ON = 2; // the majority condition is exactly fulfilled ( maj% == perc ), so ON for the first time
const int      majority_MORE = 3; // the majority condition is more than fulfilled ( maj% < perc < 100% )
const int      majority_ALL = 4; // all devices are on ( perc = 100% )
 
const string   majority_base = "majority";
const string   majority_arrayDelimiter = "\t";
const string   majority_Xdelimiter = ":";


global bool           majority_polling = false;
global int            majority_debugLevel = 4;
global string         majority_topNode;
global dyn_string     majority_devices;
global dyn_dyn_string majority_devicesFsmTypes;
global dyn_int        majority_devicesWeights;
global dyn_dyn_string majority_devicesDpes;
global dyn_dyn_string majority_devicesStates;
global dyn_string     majority_devicesXstates;
global dyn_dyn_string majority_colors;
global dyn_int        majority_deviceIdxXstates;
global dyn_int        majority_devicesXstateIdx;
global dyn_dyn_int    majority_devicesXpercIdx;
global dyn_string     majority_percLevelsOrNodes;
global dyn_dyn_float  majority_percNumbers;
global dyn_int        majority_numberInit;
global dyn_int        majority_allNumberInit;
global dyn_string     majority_pollLevelsOrNodes;
global dyn_int        majority_pollLoop;
global dyn_int        majority_pollTimes;
global dyn_int        majority_pollMax;
global int            majority_refresh = 600;

global mapping        majority_parameter;
global mapping        majority_n;
global mapping        majority_updated;
global mapping        majority_mapN;
global mapping        majority_mapInfo;
global mapping        majority_mapDeviceIdx;
global mapping        majority_mapNodeIdx;
global mapping        majority_mapCounts;
global mapping        majority_mapPollingPerc;
global mapping        majority_mapFsmStates;
global mapping        majority_weightsCache;

global mapping        majority_totals;


global mapping        majority_lastUpdater;
global mapping        majority_CUIncluded;

global bool           majority_parentSystemConnected;
global bool           majority_alwaysCalcFsmState;

global int            majority_mutex;

global bool           majority_internalMode= true;
global bool           majority_forceValid = false; // Special options to force the majority always to be valid (disabling the check that the totals correspond) not reccomended

/** Constant to access a majority_OBJECT type **/
const int majority_DEVICES = 1;
const int majority_DEVICESFSMTYPES = 2;
const int majority_DEVICESWEIGHTS = 3;
const int majority_DEVICESDPES = 4;
const int majority_DEVICESSTATES = 5;
const int majority_DEVICESXSTATES = 6;
const int majority_COLORS = 7;
const int majority_INTERNALMODE = 8;



const float    majority_initialFactorPollingTime = 2;
float          majority_factorPollingTime = majority_initialFactorPollingTime;
bool           majority_pollMaxActive = false; // enabled when startup is finished
bool           majority_valid = false; // set to true when startup is finished

time           majority_startTime;

global string  majority_mailNotification = "";
global string majority_ui_mode = "percentage";

global string  majority_clearPollingConfigurationDp = "majority_clearPollingConfiguration";

//int            majority_totalDelta;

// must be called as first step of majority configuration
void majority_new(string topNode, string cache_topNode = "") {
  majority_topNode = topNode;
  if ( cache_topNode == "")  cache_topNode = topNode;
  treeCache_start(cache_topNode,false);
}

int majority_checkNew() {
  if ( !strlen(majority_topNode) ) {
    return majority_error("no top node specified");
  }
  return 0;
}

/*
  configuration of devices must happen BEFORE majority_create is called
*/
int majority_addDevice(string device,dyn_string fsmType,dyn_string dpes,dyn_string states,int weight=1) {
  majority_addDeviceMultipleDUType(device, makeDynString(fsmType), dpes, states, weight);
}

int majority_addDeviceMultipleDUType(string device,dyn_string fsmTypes,dyn_string dpes,dyn_string states,int weight=1) {
  if ( majority_checkNew() ) {
    return -1;
  }
 
     
  majority_debug3("registering device "+device+" with states "+states);
  if ( !dynlen(dpes) )   {
    majority_debug3("for type(s) " + fsmTypes + " the majority will connect to the state");
    //    return majority_error("no datapoint elements configured for device "+device);
  }
  for ( int d = dynlen(dpes) ; d ; d -- ) {
    dpes[d] = strltrim(dpes[d],"."); // remove eventually given dot "."
    if ( strpos(dpes[d],":") < 0 ) {
      // add default attribute to dpe if not there
      dpes[d] += ":_online.._value";
    }
  }
  if ( !dynlen(states) ) {
    return majority_error("no states configured for device "+device);
  }
  if ( dynContains(majority_devices,device) ) {
    return majority_error("device "+device+" already exists");
  }
  dynAppend(majority_devices,device);
  dynAppend(majority_devicesFsmTypes,fsmTypes);
  dynAppend(majority_devicesDpes,dpes);
  dynAppend(majority_devicesWeights,weight);
  dynAppend(majority_devicesStates,states);
     
  for ( int s = 1 ; s <= dynlen(states) ; s ++ ) {
    dynAppend(majority_devicesXstates,device+majority_Xdelimiter+states[s]);
    dynAppend(majority_devicesXpercIdx[dynlen(majority_devices)],dynlen(majority_devicesXstates));
    dynAppend(majority_deviceIdxXstates,dynlen(majority_devices));
    dynAppend(majority_devicesXstateIdx,s);
    dynAppend(majority_numberInit,-1);
  }
  return 0;
}

void majority_setRefresh(int refresh) {
  if (refresh < 200) {
    majority_debug1("Refresh too short. Set to 200 ms");
    refresh = 200;
  }
  majority_refresh = refresh;
}


/*
 * Set whether the state callback should be called regardless of the percentages or only when the percentages
 * move from one defined interval to the other
 * 
 * @param calcFsmState new value 
 */
void majority_setAlwaysCalcFsmState(bool calcFsmState) {
  majority_alwaysCalcFsmState = calcFsmState; 
}


/*
  This function adds a percentage configuration of all states of a specific device.
  It will be added to node and all nodes below or on creation of the tree or
  to all nodes of the specified level and all levels below.
  It must be called after all devices and states have been added (look function above).
*/
int majority_addPercentages(string levelOrNode,string device,dyn_float percentages) {
  if ( majority_checkNew() ) {
    return -1;
  }
  if ( majority_checkLevelOrNode(levelOrNode) < 0 ) {
    return -1;
  }
  int nodeIdx;
  if ( majority_addToArray(levelOrNode,majority_percLevelsOrNodes,nodeIdx) ) {
    majority_percNumbers[nodeIdx] = majority_numberInit;
  }

  int deviceIdx = dynContains(majority_devices,device);
  if ( !deviceIdx ) {
    return majority_error("unknown device "+device);
  }
  int Nstates = dynlen(majority_devicesStates[deviceIdx]);
  if ( Nstates != dynlen(percentages) ) {
    return majority_error("number of states ("+Nstates+") in device "+device+
			  " does not match with number of percentages ("+dynlen(percentages)+
			  ") given for level/node "+levelOrNode);
  }
  for ( int s = 1 ; s <= Nstates ; s ++ ) {
    int idx = dynContains(majority_devicesXstates,device+majority_Xdelimiter+majority_devicesStates[deviceIdx][s]);
    majority_percNumbers[nodeIdx][idx] = percentages[s];
  }
  return 0;
}




/* These are the standard colors for on without the lighter green when perc = 100% */
dyn_string majority_getStandardColorsPhysics() {
  return makeDynString("FwStateOKNotPhysics","FwStateAttention1","FwStateOKPhysics","FwStateOKPhysics","FwStateOKPhysics");
}

dyn_string majority_getStandardColorsOn() {
  return makeDynString("FwStateOKNotPhysics","FwStateAttention1","FwStateOKPhysics","FwStateOKPhysics","Green");
}

dyn_string majority_getStandardColorsError() {
  return makeDynString("_Window","FwStateAttention2","FwStateAttention2","FwStateAttention3","FwStateAttention3");
}

/*
  colors is the array of colors to be used in the user interface in dependence of the status  (majority_OFF, majority_MIXED, majority_ON, majority_MORE, majority_ALL)
  Hint for defining colors:
  for an ON    state: majority_getStandardColorsOn() 
  for an ERROR state: majority_getStandardColorsError()
    
  (These are the default colors, but can be customized as you want);
*/
int majority_addColors(string device, string state, dyn_string colors) {
  if ( majority_checkNew() ) {
    return -1;
  }
  int deviceIdx = dynContains(majority_devices,device);
  if ( !deviceIdx ) {
    return majority_error("unknown device "+device);
  }
  int idx = dynContains(majority_devicesXstates,device+majority_Xdelimiter+state);
  if ( ! idx ) {
    return majority_error("unknown state "+state);
  }
  if (dynlen(colors)<  majority_ALL +1) {
    for (int i=1; i<= majority_ALL+1; i++) {
      colors[i] = "_Window"; 
    }  
  }
  majority_debug3("registering colors  for device "+device+" state "+state + ": " + colors);

  majority_colors[idx] = colors;
  return 0;
}     


/* 
   Sets a polling configuration to a specific level or node in the tree and
   all nodes below. Tree level counting starts at 1 (top node). A level number
   passed as integer parameter automatically will be converted to a string.
   A given configuration is valid in the tree until it is overwritten by a newer
   configuration for a level or a node below.
   This function may be called at any time during configuration.

   n: number of polling loop cycles to wait for changed delta (a reasoable value is 3)
   t: polling (waiting) time in poll cycle in ms (reasonable values are 200 for levels deep in tree and 500 for upper levels)
   m: maximum number of pollings on one number (reasonable is 10 to 30). after this number is reached, the delta will be propagated in any case!
   m==0: allow infinite number of polls on a number

   If no poll config is added, majority will not use polling!!
*/
int majority_addPollConfig(string levelOrNode,int n,int t,int m) {
  if ( majority_checkNew() ) {
    return -1;
  }
  if ( majority_checkLevelOrNode(levelOrNode) < 0 ) {
    return -1;
  }
  if ( n < 0 ) {
    return majority_error("invalid number of polls "+n+" given for level/node "+levelOrNode);
  }
  if ( t <= 0 ) {
    return majority_error("invalid polling time "+t+" given for level/node "+levelOrNode);
  }
  if ( m < 0 ) {
    return majority_error("invalid max number of polls "+m+" given for level/node "+levelOrNode);
  }
  int nodeIdx;
  majority_polling = true;
  majority_addToArray(levelOrNode,majority_pollLevelsOrNodes,nodeIdx);
  dynAppend(majority_pollLoop,n);
  dynAppend(majority_pollTimes,t);
  dynAppend(majority_pollMax,m);
}

void majority_clearPollConfig() {
  dynClear(majority_pollLoop);
  dynClear(majority_pollTimes);
  dynClear(majority_pollMax);
}


int majority_deleteConfig(string topNode) {
  string cfgDp = treeCache_createDp(majority_base+"Config_"+topNode,
				    majority_base+"Config",
				    treeCache_getSystem(topNode));
  if (dpExists(cfgDp)) {
    if ( dpDelete(cfgDp) == -1) 
      return majority_error(getLastError() + " while deleting " + cfgDp);
  }
  majority_clearConfig();
  return 0;
}

void majority_clearConfig() {
  dynClear(majority_devices);
  dynClear(majority_devicesFsmTypes);
  dynClear(majority_devicesWeights);
  dynClear(majority_devicesDpes);
  dynClear(majority_devicesStates);
  dynClear(majority_devicesXstates);
  dynClear(majority_colors);
  dynClear(majority_deviceIdxXstates);
  dynClear(majority_devicesXstateIdx);
  dynClear(majority_devicesXpercIdx);
  dynClear(majority_percLevelsOrNodes);
  dynClear(majority_percNumbers);
  dynClear(majority_numberInit);
  dynClear(majority_allNumberInit);
  dynClear(majority_pollLevelsOrNodes);
  dynClear(majority_pollLoop);
  dynClear(majority_pollTimes);
  dynClear(majority_pollMax);  
}
/*
  Creates or modifies a dp based majority tree starting at node.
  This (sub)tree must be a pure TREE in that sense that no node
  must have more than one parents!!
  This function uses a previously given set of devices and percentages.
  
  @param systemName creates only the missing dps on the given systemName
  @param check      do not create the dps in the given systemName, only check if they exist
  @return in case check== true:  -1 if some dp do not exist, 0 otherwise
*/

int majority_create(string systemName = "", bool check = false) {
  if ( majority_checkNew() ) {
    return -1;
  }
  if (check) {
      majority_debug1("checking if dps exist for system " + systemName);
  } else {
    majority_debug1("creating tree: started at node "+majority_topNode);
    if (systemName != "") {
      majority_debug1("recreating dps for system " + systemName);      
    }
  }
  
  // creating config dp
  string cfgDp;
  if (systemName == "") {
   cfgDp = treeCache_createDp(majority_base+"Config_"+majority_topNode,
				    majority_base+"Config",
				    treeCache_getSystem(majority_topNode));
     
    if (majority_refresh<200) {
      majority_debug1("Warning: " + majority_refresh + " too low. Set it to 200");
      majority_refresh = 200;
    }
    // and filling it with previously given config
    dpSet(cfgDp+".devices.list",majority_devices,
    	cfgDp+".devices.fsmTypes",majority_flatten(majority_devicesFsmTypes),
	cfgDp+".devices.states",majority_flatten(majority_devicesStates),
	cfgDp+".devices.dpes",majority_flatten(majority_devicesDpes),
	cfgDp+".devices.weights",majority_flatten(majority_devicesWeights),
	cfgDp+".devices.devicesXpercIdx",majority_flatten(majority_devicesXpercIdx),
	cfgDp+".devices.colors", majority_flatten(majority_colors),
	cfgDp+".percentages.devicesXstates",majority_devicesXstates,
	cfgDp+".percentages.deviceIdxXstates",majority_deviceIdxXstates,
	cfgDp+".percentages.devicesXstateIdx",majority_devicesXstateIdx,
	cfgDp+".percentages.levelsOrNodes",majority_percLevelsOrNodes,
	cfgDp+".percentages.numbers",majority_flatten(majority_percNumbers),
	cfgDp+".polling.on",majority_polling,
	cfgDp+".polling.n",majority_pollLoop,
	cfgDp+".polling.times",majority_pollTimes,
	cfgDp+".polling.max",majority_pollMax,
	cfgDp+".polling.levelsOrNodes",majority_pollLevelsOrNodes,
	cfgDp + ".refresh", majority_refresh,
        cfgDp + ".internalMode", majority_internalMode);

  }    

  int result = majority_createVisit(treeCache_getNodeIdx(majority_topNode),majority_numberInit,3,300,20, systemName, check);
  if ((check) && (result==-1)) return -1;
     
  int start, stop;
  treeCache_getVisitIndexes(majority_topNode, start, stop); 
  dyn_string systems; string sys;
  for (int i=1; i<= stop; i++) {
    sys = treeCache_getSystem(i, true);
    if ((strlen(sys)>0) && (! dynContains(systems, sys) )) dynAppend(systems, sys);
  }
  if (strlen(systemName) > 0) systems = makeDynString(systemName);
  
  //DebugN(systems);
  string clearDp;
  for (int i=1; i<= dynlen(systems); i++) {
    // DebugN("Trying to create " + systems[i] + majority_clearPollingConfigurationDp);
    clearDp = systems[i] + majority_clearPollingConfigurationDp;
    if ((check) && (! dpExists(clearDp))) return -1;
    
    string dp_upd = treeCache_createDp( clearDp, "ExampleDP_Int");
    majority_debug1("Set updated in " + dp_upd);
    dpSet(dp_upd + ".", 1);
  }
  majority_debug1("finished creation of tree");
  return 0;
}

int majority_createVisit(int nodeIdx,dyn_string percentages,int pollLoop,int pollTime,int pollMax, string systemName = "", bool check = false) {
  dyn_string children = treeCache_getChildrenI(nodeIdx,true);
  string fsmType= treeCache_getType(nodeIdx,true);
  bool du = (majority_getUnitFixed(nodeIdx, true) == "DU");
  bool connect = false;
  for ( int dev = dynlen(majority_devicesFsmTypes) ; dev ; dev -- ) {
    if ( dynContains(majority_devicesFsmTypes[dev], fsmType)  ) {
      connect = true;
      break;
    }
  }
  
  if ((!dynlen(children)) && (!connect) ) {
    return 0; // ignore nodes that are not without children in majority tree. This way the datapoints for the interesting devices are also created because in this case connect == true because they are of the proper type
  }
  string node = treeCache_getNode(nodeIdx);     
  string nodeSys = treeCache_getSystem(nodeIdx, true);
  bool writeToDp = ((systemName == "") || (nodeSys == systemName));
  
  
  dyn_int total;
  for (int d=1; d<= dynlen(majority_devices); d++) {
    total[d] = 0;
    for (int t=1; t<= dynlen(majority_devicesFsmTypes[d]); t++) {
      total[d] += dynlen(treeCache_getNodesOfTypeBelow(node, majority_devicesFsmTypes[d][t])); // * majority_devicesWeights[d]; // here i don't need to use getTotal because it's just to check if it's >0
    }
  }
  if (majority_arrayZero(total)) {
    return 0;
    // ignore nodes without interesting children 
  }
  if (! check) {
    majority_debug2("processing "+majority_getUnitFixed(nodeIdx,true)+" "+node);
  }
  string dp;
  if (writeToDp) {
    if ((check) && ( ! dpExists(nodeSys + majority_base+"_"+node))) return -1;
    if (! check) {
      
      dp  = treeCache_createDp(majority_base+"_"+node,
    				 majority_base,
    				 treeCache_getSystem(nodeIdx,true));
     
      dpSet(dp + ".admin.topNode",majority_topNode);
    }
  }
  if (check) writeToDp = false; // only checking, continue without writing to dp
     
     
  int percIdx = majority_getConfigIdx(node,nodeIdx,majority_percLevelsOrNodes);
  if ( percIdx ) { // new percentage config found
    for ( int d = dynlen(percentages) ; d ; d -- ) {
      float num = majority_percNumbers[percIdx][d];
      if ( num >= 0 ) {
	      percentages[d] = num;
      }
    }
  }
  int notSetIdx = dynContains(percentages,-1);
  if ( notSetIdx ) {
    return majority_error("missing configuration of percentages for device"+majority_Xdelimiter+
			  "state "+majority_devicesXstates[notSetIdx]+" in node "+node);
  }
  int pollIdx = majority_getConfigIdx(node,nodeIdx,majority_pollLevelsOrNodes);
  if ( pollIdx ) {
    pollLoop = majority_pollLoop[pollIdx];
    pollTime = majority_pollTimes[pollIdx];
    pollMax = majority_pollMax[pollIdx];
  }
  if (! du ) {
     if (writeToDp) {
      dpSet(dp+".admin.percentages",percentages,
          	  dp+".admin.pollLoop",pollLoop,
         	  dp+".admin.pollTime",pollTime,
          	  dp+".admin.pollMax",pollMax);
    }
  }

  // Initialize all majority dps with the correct number of 0's
  dyn_int init_int = makeDynInt();
  dyn_float init_float = makeDynFloat();
  dyn_int init_int_devices = makeDynInt();


  for (int i=1; i<= dynlen(majority_devicesXstates); i++) {
    init_int[i] = 0;
    init_float[i] = 0.0;
  }
  for (int i=1; i<= dynlen(majority_devices); i++) {
    init_int_devices[i] =0;
  }
     
  string it;
  if (writeToDp) {
  for (int included_total =0; included_total<= 1; included_total++) {
    it = (included_total?".included":".total");
    dyn_int temp_perc;
   
      dpGet(dp + it + ".percentages", temp_perc);
      if (dynlen(temp_perc) != dynlen(init_float)) {
        dpSet(dp + it + ".percentages", init_float,
	            dp + it + ".states.n", init_int,
        	    dp + it + ".all.n", init_int_devices	       );	
      }    
   }
  }

  for ( int c = dynlen(children) ; c ; c -- ) {
    if ( majority_createVisit(children[c],percentages,pollLoop,pollTime,pollMax, systemName, check) != 0 ) {
      return -1;
    }
  }
  return 0;
}

void majority_recreate(string systemName = "") {
  if (strlen(systemName) ==0) {
      systemName = getSystemName();
  }
  
  int result = majority_create(systemName, true); // check
  
  if (result == -1) {
      majority_debug1("Some majority dps are missing for the local system. Recreating them");
      majority_create(systemName, false);
  }
}


string majority_getConfigDp(string topNode, bool use_cache = true) {  
  string sys;
  if (use_cache) sys = treeCache_getSystem(topNode);
  else {
    fwUi_getDomainSys(topNode, sys); // if it is a CU (domain) find the proper system Name
    if (sys == "") // if not found (not a CU) use fwCU_getDp
      sys = _treeCache_getSystemFromFw(topNode);
  }
  
  return sys+majority_base+"Config_"+topNode;
}

int majority_readConfigObject(dyn_mixed& majority_object, string topNode="", bool use_cache = true) {
  int res = majority_readConfig(topNode, use_cache);
  if (res == -1) return -1;
  majority_object[majority_DEVICES] = majority_devices;
  majority_object[majority_DEVICESFSMTYPES] = majority_devicesFsmTypes;
  majority_object[majority_DEVICESWEIGHTS] = majority_devicesWeights;
  majority_object[majority_DEVICESSTATES] = majority_devicesStates;
  majority_object[majority_DEVICESDPES] = majority_devicesDpes;
  majority_object[majority_DEVICESXSTATES] = majority_devicesXstates;
  majority_object[majority_COLORS] = majority_colors;
  majority_object[majority_INTERNALMODE] = majority_internalMode;

  return res;
}

int majority_readConfig(string topNode = "", bool use_cache = true) {
  if (topNode == "") {
    if ( majority_checkNew() ) {
      return -1;
    }
    topNode = majority_topNode;
  }
  string cfgDp = majority_getConfigDp(topNode, use_cache);
  dyn_string tmp0,tmp1,tmp2,tmp3,tmp4,tmp5;
  dpGet(cfgDp+".devices.list",majority_devices,
	cfgDp+".devices.fsmTypes",tmp0,
	cfgDp+".devices.states",tmp1,
	cfgDp+".devices.dpes",tmp2,
	cfgDp+".devices.weights",majority_devicesWeights,
	cfgDp+".devices.devicesXpercIdx",tmp4,
	cfgDp+".devices.colors",tmp5,
	cfgDp+".percentages.devicesXstates",majority_devicesXstates,
	cfgDp+".percentages.deviceIdxXstates",majority_deviceIdxXstates,
	cfgDp+".percentages.devicesXstateIdx",majority_devicesXstateIdx,
	cfgDp+".percentages.levelsOrNodes",majority_percLevelsOrNodes,
	cfgDp+".percentages.numbers",tmp3,
	cfgDp+".polling.on",majority_polling,
	cfgDp+".polling.n",majority_pollLoop,
	cfgDp+".polling.times",majority_pollTimes,
	cfgDp+".polling.max",majority_pollMax,
	cfgDp+".polling.levelsOrNodes",majority_pollLevelsOrNodes,
	cfgDp + ".refresh", majority_refresh,
        cfgDp + ".internalMode", majority_internalMode
	);
  majority_devicesFsmTypes = majority_unflatten(tmp0);
  majority_devicesStates = majority_unflatten(tmp1);
  majority_devicesDpes = majority_unflatten(tmp2);
  majority_percNumbers = majority_unflatten(tmp3);
  majority_devicesXpercIdx = majority_unflatten(tmp4);
  majority_colors = majority_unflatten(tmp5);
  dynClear(majority_numberInit);
  dynClear(majority_allNumberInit);
  majority_numberInit[dynlen(majority_devicesXstates)] = 0;
  majority_allNumberInit[dynlen(majority_devices)] = 0;
  return 0;
}

string majority_getColor(dyn_mixed& majority_object,int maj_state, string device, string state) {
  if (maj_state == -1) return "FwEquipmentDisabled";
  else {
    int idx = dynContains(majority_object[majority_DEVICESXSTATES],device+majority_Xdelimiter+state);
    if (! idx) return "FwEquipmentDisabled";
    dyn_dyn_string colors = (majority_object[majority_COLORS]);
    return colors[idx][maj_state+1]; 
  }
   
}



/* Perform dpSet for many datapoints

   "Inspired" by fwConfigurationDB_dpSetMany. But here i have to handle a single system and i do not debug

*/
void majority_dpSetMany(dyn_string &dpes, dyn_mixed &values, dyn_string &exceptionInfo, bool debug = false)
{
  if (dynlen(dpes) == 0) return;
  const int majority_OPTIMUM_DP_SET_SIZE = 70;

  int rc;
  dyn_string dpeGroup;
  dyn_mixed  valGroup;
  int j=0;
  for (int i=1;i<=dynlen(dpes);i++) {
    j++;
    dpeGroup[j]=dpes[i];
    valGroup[j]=values[i];
    if (j >= majority_OPTIMUM_DP_SET_SIZE)
      {	
	rc=dpSetWait(dpeGroup,valGroup);
	if (rc!=0) {
	  dyn_errClass err=getLastError();
	  fwException_raise(exceptionInfo,"ERROR","majority_dpSetMany: cannot set values","");
	  DebugN("ERROR in majority_dpSetMany",err);
	}
	dynClear(dpeGroup);
	dynClear(valGroup);
	j=0;
      }
  }

  //apply remaining part...
  if (j>0) {
    rc=dpSetWait(dpeGroup,valGroup);
    if (rc!=0) {
      dyn_errClass err=getLastError();
      fwException_raise(exceptionInfo,"ERROR","majority_dpSetMany: cannot set values","");
      DebugN("ERROR in majority_dpSetMany",err);
    }   
  }    
  if (debug) {
    DebugTN(dynlen(dpes) + " dpes set ");
  }
}

void majority_update() {
  string dpe, numberMode, dp, node, element; dyn_int n; int isAll;
  dyn_string exc;
  dyn_string dpes; dyn_mixed values;
  
  // wait a bit for the initialization
  delay(0,majority_refresh*2);
  majority_debug3("Starting to update the dps");
  while (1) {
    dynClear(dpes); dynClear(values);
    synchronized (majority_mutex) {
      //      DebugN("Updating " + mappinglen(majority_n) + " nodes");
      for (int i=1; i<= mappinglen(majority_mapCounts); i++) {
	//	DebugN(mappingGetKey(majority_mapCounts,i), mappingGetValue(majority_mapCounts,i));
	
	dpe = mappingGetKey(majority_mapCounts,i);       
	if (! mappingHasKey(majority_updated, dpe) ) {
	  // there will be no updated information for the mapCounts of the internal nodes that we connect by state 
	  continue;
	}
	if (! majority_updated[dpe]) continue;
	n = mappingGetValue(majority_mapCounts,i);
	//if (! dpExists(dpe)) continue; // in principle it should not be necessary but just in case the majority was not reconfigured and the datapoint does not exist
	//	dpSet(dpe,n );
	// do not dpSet directly. Instead group the dpSets in groups of optimum size
	dynAppend(dpes, dpe);
	values[dynlen(values)+1] = n;
	majority_updated[dpe] = false; // set to false here and to true when updated
      }

      // here we also have to set the percentages so it is more difficult to group the dpSet's. 
      // The function majority_updatePercentages appends to dpes and values what needs to be set 
      for (int i=1; i<= mappinglen(majority_n); i++) {
	dpe = mappingGetKey(majority_n,i);
	if (! majority_updated[dpe]) continue;
	n = mappingGetValue(majority_n,i);


	dp = dpSubStr(dpe,DPSUB_DP);
	if (dp == "") {
	  dyn_errClass err = getLastError(); //test whether no errors 
	  if(dynlen(err) > 0) 
	    { 

	      throwError(err); // write errors to stderr 
	    } 
	  majority_error("Impossible to find dp for dpe " + dpe + ": error " + err);
	  majority_updated[dpe] = false; // updated is set to false here and to true when updated
    majority_sendMail("Problem with dpe found", "dpe = " + dpe + " error = " + err);
	  continue;
	}

	// do not dpSet directly. Instead group the dpSets in groups of optimum size
	dynAppend(dpes, dpe);
	values[dynlen(values)+1] = n;

	element = dpe;
	strreplace(element, dp, "");
	
	if (strpos(element, "total")>=0) {
	  numberMode = "total";
	} else {
	  numberMode = "included";
	}
	isAll = (strpos(element, ".all")>=0);

	node = dp;
	strreplace(node , majority_base + "_", ""); 

	majority_updatePercentages(dp, numberMode, isAll, treeCache_getNodeIdx(node), n, dpes, values);  
	majority_updated[dpe] = false; // updated is set to false here and to true when updated
      }
      majority_dpSetMany(dpes, values, exc); 

    }
    delay(0,majority_refresh);
  }
}

void majority_setInternalMode(bool leaf) {
  majority_internalMode = leaf; 
}

void majority_start(string topNode,int debugLevel=4, string cache_topNode = "") { // 1 (important messages only) ... 4 (all msgs, also debugs)

  if (! isFunctionDefined("majorityUser_stateCounts")) {
    majority_error("Function majorityUser_stateCounts is not defined. PLEASE INCLUDE YOUR CUSTOMIZED majorityUser LIBRARY");
    delay(10);
    return;
  }

  if (! isFunctionDefined("majorityUser_calcFsmState")) {
    majority_error("Function majorityUser_calcFsmState is not defined. PLEASE INCLUDE YOUR CUSTOMIZED majorityUser LIBRARY");
    delay(10);
    return;
  }

  if (strlen(cache_topNode)==0) cache_topNode = topNode;
  treeCache_start(cache_topNode);

  
  
  

  majority_startTime = getCurrentTime();
  majority_debugLevel = debugLevel;

  // create restart handling
  string restartDp = treeCache_createDp(majority_base+"_triggerRestart","ExampleDP_Bit");
  dpConnect("majority_restartCB",false,restartDp+".");
  
  majority_readMailRecipients(topNode) ;
  
  string clearpollDp = treeCache_createDp(majority_clearPollingConfigurationDp, "ExampleDP_Text");
  dpConnect("majority_clearPollingCb",false,clearpollDp + ".");
  majority_debug4("Created " + clearpollDp);
  
  majority_new(topNode, cache_topNode);
  majority_debug1("starting up for topnode "+majority_topNode);

  // majority config
  majority_readConfig();
  

  
  
  string mySystem = getSystemName();


  //  just in case the included dp do not exist, recreate them
   treeCache_recreateIncludedDps(cache_topNode); // this will check if they already exist

   // in case the majority dps need to be recreated in the local system
   majority_recreate(mySystem);    

  
  dyn_string topNodes;
  if (treeCache_getSystem(topNode) == mySystem) {
    majority_debug1("I am the supervisor system in tree hierarchy");
    topNodes = makeDynString(topNode);          
  } else {
    
    
    int start, stop;
    treeCache_getVisitIndexes(topNode, start, stop);
    for (int n = start+1; n<= stop; n++) {
      if (strlen(treeCache_getType(n,true))==0) continue;
      if (treeCache_getSystem(n,true) != treeCache_getSystem(treeCache_getParentI(n,true), true)) {
        if (treeCache_getSystem(n,true) == mySystem) {
	  dynAppend(topNodes, treeCache_getNode(n)); 
        } 
      }
    }     
  
    dynUnique(topNodes);
    if (dynlen(topNodes)==0) {
      majority_error("No top nodes found in system " + mySystem);
      delay(10);
      return;
    }
    
    string parentSystem = strrtrim(treeCache_getSystem(treeCache_getParent(topNodes[1])),":");
    string dp = "_unDistributedControl_"+parentSystem+".connected";
    dpGet(dp,majority_parentSystemConnected);
    dpConnect("majority_checkConnected",true,dp);
    majority_debug1("I am a child system in tree hierarchy and my parent is " + parentSystem);    
  }
  
  
  
  
  majority_factorPollingTime = majority_initialFactorPollingTime;
  majority_debug1("Polling time is multiplied by " + majority_factorPollingTime + " during startup");
  
  for ( int n = 1 ; n<= dynlen(topNodes) ; n ++ ) {
    majority_startVisit(treeCache_getNodeIdx(topNodes[n]));
  }
  
  dyn_int nodeIdx; dyn_string dpes; string callbackFunction; string dpe;


  majority_debug3("Now connecting to " + mappinglen(majority_mapInfo) + " remote majority dps");
  for (int i=1; i<= mappinglen(majority_mapInfo); i++) {
    dpe = mappingGetKey(majority_mapInfo,i);
    dpConnect("majority_nCB", dpe);
  }  

  majority_debug3("Now connecting to " + mappinglen(majority_mapNodeIdx) + " set of data points for the state callback");
  for (int i=1; i<= mappinglen(majority_mapNodeIdx); i++) {
    dpes = mappingGetKey(majority_mapNodeIdx,i);
    nodeIdx = mappingGetValue(majority_mapNodeIdx, i);
    //    majority_debug4("Connecting " + i + " " + treeCache_getNode(nodeIdx[1]) + " ( " + dynlen(dpes) + " dpes, " + dynlen(nodeIdx) + " nodes) " + dpes);
    if (majority_getUnitFixed(nodeIdx[1],true) == "DU") {
      if ( dpConnect("majority_stateCB",dpes) ) {
	majority_error("error when connecting "+dpes);
      }
    } else {
      if ( dpConnect("majority_stateCBInternalNode",dpes[1]) ) {
	majority_error("error when connecting "+dpes[1]);
      }
    }
  }

  startThread("majority_update");
  majority_debug1("finished starting up");
}


void majority_readMailRecipients(string topNode = "") {
  if (strlen(topNode)==0) topNode = majority_topNode;
  string mailDp = majority_getConfigDp(topNode) + ".admin.mailRecipients";
  dpGet(mailDp  ,majority_mailNotification); 
}

void majority_clearPollingCb(string dp, int value) {
  majority_debug2("Clearing polling configuration. Will be read again");
  mappingClear(majority_mapPollingPerc); 
}

bool majority_hasNoDescendantsOfType(string node, dyn_string types) {
  dyn_string nodes;
  for (int t=1; t<= dynlen(types); t++) {
    nodes = (treeCache_getNodesOfTypeBelow(node,types[t]));
    if (dynlen(nodes)>0) {
      if (nodes[1]==node) dynRemove(nodes,1); // if it's of the same type it will always be the first
      if (dynlen(nodes)>0) return false;     
    }
  }
  return true;
}

int majority_getTotalBelow(string node, string fsmType, dyn_string fsmTypes, bool internalMode, bool included = false) {
  dyn_string nodes = treeCache_getNodesOfTypeBelow(node, fsmType,included,"",true);
  if (! internalMode) return dynlen(nodes);
  if (dynlen(nodes)==0) return 0;
  if ((majority_getUnitFixed(nodes[1]) != "DU")) {
    int count = 0;
    for (int i= dynlen(nodes); i>0; i--) {
      if (majority_hasNoDescendantsOfType(nodes[i], fsmTypes)) {
	count++; 
      }
    }
    return count; 
  } else {
    return dynlen(nodes);    
  }
}

bool majority_isConfiguredAsDu(string fsmType) {

  int devSelected = 0;
  for ( int dev = 1 ; dev <=  dynlen(majority_devicesFsmTypes) ; dev++ ) {
    if ( dynContains(majority_devicesFsmTypes[dev], fsmType)  ) {
      devSelected = dev;
      break;              
    }      
  }       
  if (devSelected == 0) return false;
  return (dynlen(majority_devicesDpes[devSelected])>0);
}

string majority_getUnitFixed(string node, bool isIdx = false) {
  int nodeIdx = treeCache_getNodeIdx(node,isIdx);
  string unit = treeCache_getUnit(nodeIdx,true);
  string fsmType = treeCache_getType(nodeIdx, true);
  if (unit != "DU") {
    if ((majority_isConfiguredAsDu(fsmType)) && (treeCache_getFsmDevDp(nodeIdx, true) != treeCache_getFsmInternalDp(nodeIdx, true))) {
      majority_debug4("Forcing " + treeCache_getNode(nodeIdx) + " of type " + fsmType + " to be treated as a DU");
      unit = "DU";
    }
  }
  return unit;
}

int majority_getTotalNumberOfDevices(string node,string device, string fsmType, dyn_string fsmTypes, bool internalMode, int weight, bool included = false, bool use_userFunction = true, int devIndex = -1) {
  
  if (weight != -1) {
    return majority_getTotalBelow(node, fsmType,fsmTypes, internalMode) * weight;
  } else {    
    if (use_userFunction) {
      if (isFunctionDefined("majorityUser_getDeviceWeight")) {
	int total = 0;
	dyn_string nodes = treeCache_getNodesOfTypeBelow(node, fsmType,included,"",true);
	for (int i=1; i<= dynlen(nodes); i++) {
	  total += majorityUser_getDeviceWeight(nodes[i], device);
	}
	return total;
      } else {
        majority_debug1("Error: function majorityUser_getDeviceWeight not defined and weight = -1 for device " + device);
        return majority_getTotalNumberOfDevices(node, device, fsmType, fsmTypes, internalMode, 1);      
      }
    } else {
      // from the UI i want the same result without using the user function 
      int total = 0; 
      dyn_string nodes = treeCache_getNodesOfTypeBelow(node, fsmType,included,"",true);     
      dyn_string dps;
      string it = (included)?".included":".total";
      for (int i=1; i<= dynlen(nodes); i++) {
	dps[i] = majority_getDpFromNode(nodes[i]) + it + ".all.n";
      }
      // get the total
      dyn_dyn_int ns;
      _treeCache_dpGetAll(dps, ns);
      for (int i=1; i<= dynlen(nodes); i++) {
	total += ns[i][devIndex];
      }
      return total;        
    }
  }
}
void majority_startVisit(int nodeIdx) {
  //void majority_startVisit(string node) {
  // cannot use Lorenzo's new fancy linear visit due to special tree dependend interuption conditions during visit
  //int start,stop;
  //treeCache_getVisitIndexes(node,start,stop);
     
  dyn_string children = treeCache_getChildrenI(nodeIdx,true);
  string node = treeCache_getNode(nodeIdx);
  string unit = majority_getUnitFixed(nodeIdx, true);
  string dp = treeCache_getSystem(nodeIdx,true)+majority_base+"_"+node;
  string relatedTopNode;
  string fsmType = treeCache_getType(nodeIdx,true);


  if ( ! dpExists(dp) ) return;
  dpGet(dp + ".admin.topNode", relatedTopNode);
  if (strlen(relatedTopNode) == 0) {
    majority_debug1("WARNING: " + node + " has an empty topNode. Setting to " + majority_topNode);
    dpSet(dp+".admin.topNode", majority_topNode);             
  } else if (relatedTopNode != majority_topNode) {
    majority_debug3("Ignoring " + node + " because its topNode is " + relatedTopNode);                              
    return;
  }
     
  if ( unit != "DU" ) {
    // Check if the device types contain this type even if it is not a DU
    bool connect = false;
    int devSelected = -1;
    for ( int dev = dynlen(majority_devicesFsmTypes) ; dev ; dev -- ) {
      //      DebugTN("Looking for " + fsmType + " in " +majority_devicesFsmTypes[dev]);               
      if ( dynContains(majority_devicesFsmTypes[dev], fsmType)  ) {
        if (majority_internalMode) { // if this option is checked only connect to the CUs that have no children of the same type below
          if (majority_hasNoDescendantsOfType(node, majority_devicesFsmTypes[dev])) {
	    connect = true;
	    devSelected = dev;
	    break;              
          }
        } else { // if not, connect anyway
	  connect = true;
	  devSelected = dev;
	  break;
	}
      }
    }       
             
    if ((! connect) && ( !dynlen(children) )) { // ignore non-devices without children
      majority_debug3("Ignoring " + node + " because has no children");
      if (dpExists(dp)) dpSet(dp + ".admin.valid", true);
      return;
    }
    string msg;
    dyn_int total = makeDynInt();
    for (int d=1; d<= dynlen(majority_devices); d++) {
      total[d] = 0;
      for (int t=1; t<= dynlen(majority_devicesFsmTypes[d]); t++) {
	total[d] += majority_getTotalNumberOfDevices(node, majority_devices[d], majority_devicesFsmTypes[d][t], majority_devicesFsmTypes[d], majority_internalMode,  majority_devicesWeights[d]);
      }
    }
    if ( getSystemName() != treeCache_getSystem(nodeIdx,true) ) {
      // don't connect to nodes that have no interesting children
      if (majority_arrayZero(total)) {
	majority_debug4("Ignoring " + node + " because it has no interesting children");
	dpSet(dp + ".admin.valid", true);
	return;
      }
      // The system has changed right now from a supervisor system to the system level below,
      // so just dpConnect to its summary numbers (.all and .n)

      majority_debug3("connecting to "+unit+" "+node);
      majority_mapN[dp+".included.states.n"] = majority_numberInit;
      majority_mapN[dp+".included.all.n"] = majority_allNumberInit;
      majority_mapN[dp+".total.states.n"] = majority_numberInit;
      majority_mapN[dp+".total.all.n"] = majority_allNumberInit;
      if (! mappingHasKey(majority_mapInfo, dp+".included.states.n") ) {
	// the first time that we found the node
	majority_mapInfo[dp+".included.states.n"] = makeDynInt(nodeIdx,0,0);
	majority_mapInfo[dp+".included.all.n"] = makeDynInt(nodeIdx,0,1);
	majority_mapInfo[dp+".total.states.n"] = makeDynInt(nodeIdx,1,0);
	majority_mapInfo[dp+".total.all.n"] = makeDynInt(nodeIdx,1,1);

	// connect to included state of CUs in system below
	if (! treeCache_isLogical() ) {
	  treeCache_connectIncluded("majority_includedCB",node,false);
	}
      } else {
	// if the same node is found more than once (multiple references), append the additional nodeIdx at the end
	dynAppend(majority_mapInfo[dp+".included.states.n"], nodeIdx);
	dynAppend(majority_mapInfo[dp+".included.all.n"], nodeIdx);
	dynAppend(majority_mapInfo[dp+".total.states.n"], nodeIdx);
	dynAppend(majority_mapInfo[dp+".total.all.n"] , nodeIdx);
      }
            
      int Npollings , pollingTime, pollMax;

      return; // finish processing of nodes in supervisor system at this layer
    }
    else { // 'normal' LU or CU, so initializing all numbers
      majority_totals["node" + nodeIdx] = total;
      dyn_int array_of_minusOne = majority_arrayOfValues(dynlen(majority_numberInit), -1);

      if ( unit == "CU" ) {
	majority_debug2("initializing "+unit+" "+node);
	majority_debug3("Total for node " + node + ": " + total);
      }
      else {
	majority_debug4("initializing "+unit+" "+node);
	majority_debug3("Total for node " + node + ": " + total);
      }

      if (majority_arrayZero(total)) {
	majority_debug3("Setting valid to true for " + dp + " that has no managed children");
	if (dpExists(dp)) dpSet(dp + ".admin.valid", true);
      } else {
	dpSet(dp+".included.states.n",majority_numberInit,
	      dp+".included.all.n",majority_allNumberInit,
	      dp+".included.percentages",majority_numberInit,
	      dp+".included.fsmState","UNUSED", // this is the default initialization for the state
	      dp+".included.majStates",array_of_minusOne,
	      
	      dp+".total.states.n",majority_numberInit,
	      dp+".total.all.n",majority_allNumberInit,
	      dp+".total.percentages",majority_numberInit,
	      dp+".total.fsmState","UNUSED", 
	      dp+".total.majStates",array_of_minusOne,
	      dp + ".admin.valid", false);  
	majority_setPar(dp + ".included.all.delta", majority_allNumberInit);
	majority_setPar(dp + ".included.all.polls", 0);
	majority_setPar(dp + ".total.all.delta", majority_allNumberInit);
	majority_setPar(dp + ".total.all.polls", 0);
	// no direct connection to a CU or LU when it is in the same system: we only dpConnect to DUs.

	// if this is a CU/LU of a type that we want to connect, connect to the FSM state 
	// this is then treated as a device unit below the node that calls the callback with only one parameter 
	// that is the state
	if (connect) {      
	  // connect to the internal dp, do not use fwCU_connectState
	  string statedpe = treeCache_getFsmInternalDp(nodeIdx,true) + ".fsm.currentState:_online.._value"; 
          majority_debug4("Connecting to state of " + node + " (" + statedpe + ")");
	  if (! mappingHasKey(majority_mapDeviceIdx,statedpe) ) {
	    majority_mapDeviceIdx[statedpe] = makeDynInt(devSelected);
	    majority_mapNodeIdx[statedpe] = makeDynInt(nodeIdx);
	    /*	    if (dpConnect("majority_stateCBInternalNode",statedpe)) {
		    majority_error("error when connecting "+ statedpe);
		    }
	    */
	  } else {
	    dynAppend(majority_mapDeviceIdx[statedpe], devSelected);
	    dynAppend(majority_mapNodeIdx[statedpe], nodeIdx);
	    // 	    string state;
	    // 	    dpGet(statedpe, state);
	    // 	    majority_stateCBInternalNode(statedpe, state);
	  }

	}
      }
    }
  }
  else { // this is a device: connect to it here even if it is on another system!! (Can happen in fw fsm?! I don't know!)
    dpSet(dp+".included.states.n",majority_numberInit,
	  dp+".included.all.n",majority_allNumberInit,
	  dp+".included.fsmState","", // this is the default initialization for the state
	  dp+".total.states.n",majority_numberInit,
	  dp+".total.all.n",majority_allNumberInit,
	  dp+".total.fsmState","", 
	  dp + ".admin.valid", true); // as far as we know DUs are always valid 

    string devdp; 
    if (isFunctionDefined("majorityUser_nodeTranslation")) {
      devdp = majorityUser_nodeTranslation(node);
    } else {
      devdp = treeCache_getFsmDevDp(nodeIdx,true);
      devdp = majorityUser_dpTranslation(devdp);
    }
    devdp = strrtrim(devdp,".");

    for ( int dev = dynlen(majority_devicesFsmTypes) ; dev ; dev -- ) {
      if ( ! dynContains(majority_devicesFsmTypes[dev], fsmType)  ) {
	continue;
      }
      dyn_string dpes = majority_devicesDpes[dev];
      dyn_string userDpes;
      bool use_userDpes = false;
      if (isFunctionDefined("majorityUser_nodeTranslationToDpes")) {
	userDpes = majorityUser_nodeTranslationToDpes(majority_devices[dev], node, use_userDpes);       
      } 
      if (use_userDpes) {
	dpes = userDpes; string element;
	for ( int d = dynlen(dpes) ; d ; d -- ) {
	  element = dpSubStr(dpes[d],   DPSUB_SYS_DP_EL_CONF_DET);
	  element = strrtrim(substr(element, strlen(dpSubStr(dpes[d],   DPSUB_SYS_DP))),".");
	  if ( strpos(element,":") < 0 ) {
	    // add default attribute to dpe if not there
	    dpes[d] += ":_online.._value";
	  }
	}
	majority_debug4("using dpes provided by user function " + dpes);
      } else {
	for ( int d = dynlen(dpes) ; d ; d -- ) {
	  dpes[d] = devdp + "." + dpes[d];
	  majority_debug4("connecting to "+dpes[d]);
	}
      }
      if (! mappingHasKey(majority_mapDeviceIdx,dpes) ) {
	majority_mapDeviceIdx[dpes] = makeDynInt(dev);
	majority_mapNodeIdx[dpes] = makeDynInt(nodeIdx);
	/*	if ( dpConnect("majority_stateCB",true,dpes) ) {
		majority_error("error when connecting "+dpes);
		}
	*/
      } else {
	dynAppend(majority_mapDeviceIdx[dpes], dev);
	dynAppend(majority_mapNodeIdx[dpes], nodeIdx);
	// 	dyn_mixed dpes_values;
	// 	dpGet(dpes, dpes_values);
	// 	majority_stateCB(dpes, dpes_values);
      }
    }
  }
  if (( treeCache_getLevelInSystem(nodeIdx,true) != 1 ) && (node != majority_topNode)) {
    if (! treeCache_isLogical()) {
      treeCache_connectIncluded("majority_includedCB",node,false);
    }
  }
  for ( int c = 1 ; c<= dynlen(children) ; c ++ ) {
    majority_startVisit(children[c]);
  }
}

/*
  internal functions start here
*/

void majority_checkConnected(string dpe, bool connected) {
  // previously disconnected
  if ( connected && !majority_parentSystemConnected ) {
    majority_debug1("parent system is connected again");
    majority_restart();
  }
  majority_parentSystemConnected = connected;
}

void majority_restartCB(string dpe,bool dummy) {
  majority_restart();
}

void majority_restart() {
  majority_debug1("restarting local majority manager ...\n\n\n\nPLEASE DO NOT FORGET TO SET THIS MANAGER TO 'ALWAYS'!!!!!\n\n\n");
  delay(0,500);
  exit(0);
}

void majority_triggerRestartLocal() {
  majority_triggerRestart();
}

void majority_triggerRestartAll() {
  majority_triggerRestart("*:");
}

void majority_triggerRestart(string sysPattern="") { // triggers a restart of majority managers
  dyn_string dps = dpNames(sysPattern+majority_base+"_triggerRestart","ExampleDP_Bit");
  for ( int d = dynlen(dps) ; d ; d -- ) {
    majority_debug1("triggering restart of majority manager in system "+dpSubStr(dps[d],DPSUB_SYS));
    dpSet(dps[d]+".",false);
  }
}

void majority_triggerRestartSystemsUnder(string node) {
  dyn_string systems;
  string sys;
  int start, stop;
  treeCache_getVisitIndexes(node, start, stop);
  for (int n= start; n<= stop; n++) {
    sys = treeCache_getSystem(n, true);
    if (! dynContains(systems, sys) ) {
      dynAppend(systems, sys);
    }
  }

  for (int i=1; i<= dynlen(systems); i++) {
    majority_triggerRestart(strrtrim(systems[i],":") + ":");
  }
}

int majority_getDeviceWeight(string node, string device) {
  string key = node + "," + device;
  if (mappingHasKey(majority_weightsCache, key)) {
    return majority_weightsCache[key];
  } else {
    int w = majorityUser_getDeviceWeight(node, device);
    majority_weightsCache[key] = w;
    return w;
  }
}

void majority_stateCB(dyn_string dpes,dyn_anytype values) {
  dyn_int deviceIdxs = majority_mapDeviceIdx[dpes];
  dyn_int nodeIdxs = majority_mapNodeIdx[dpes];
  int deviceIdx, nodeIdx;
  string node;
  
  dynUnique(deviceIdxs);
  bool loop_over_nodes = ((dynlen(deviceIdxs) == 1) && (dynlen(nodeIdxs)>1));

  if ((! loop_over_nodes ) && (dynlen(nodeIdxs) != dynlen(deviceIdxs))) {
    majority_error("Inconsistent lengths of nodeIdxs and deviceIdxs for " + dpes + " on " + treeCache_getNode(nodeIdxs[1])  + ": " + nodeIdxs + " " + deviceIdxs );    
    exit(0);
    return;
    // Please avoid the very complicated case where the same dpe should change two different device types related to  nodes with multiple references!! Or one or the other!!! If needed i can think about how to program that.
  }

  // the same dpes can trigger the callback in more than 1 device (trick to handle a graph)
  for (int d=1; d<= dynlen(deviceIdxs); d++) {
    deviceIdx = deviceIdxs[d]; nodeIdx= nodeIdxs[d];
    node= treeCache_getNode(nodeIdx);

    //DebugTN("Changed " + node);
    int weight = majority_devicesWeights[deviceIdx];
    if (weight == -1) { // this allows for device units of variable weight
      weight = majority_getDeviceWeight(node, majority_devices[deviceIdx]); // the function uses value from cache or calls majorityUser_getDeviceWeight
    } 
    for ( int calcTotal = 0 ; calcTotal <= 1 ; calcTotal ++ ) {
      int all = weight;
      dyn_int stateCounts = majorityUser_stateCounts(majority_devices[deviceIdx],values,all,calcTotal,node);
      if ( dynlen(stateCounts) != dynlen(majority_devicesXpercIdx[deviceIdx]) ) {
	majority_error("returned number of states by user function does not match with state config");
	exit(0);
	return;
      }
      for ( int isAll = 0 ; isAll <= 1 ; isAll ++ ) {
	string key = "majority_" + node + (calcTotal?".total.":".included.") + (isAll?"all":"states") + ".n";
	dyn_int counts,countsOld;
	synchronized(majority_mapCounts) {
	  if ( mappingHasKey(majority_mapCounts,key) ) {
	    countsOld = majority_mapCounts[key];
	  }
	  else {
	    countsOld[dynlen(isAll?majority_allNumberInit:majority_numberInit)] = 0;
	    majority_mapCounts[key] = countsOld;
	  }
	  counts = countsOld;
	  // now replace current counts in this array
	  if ( isAll ) {
	    counts[deviceIdx] = all;
	  }
	  else {
	    for ( int s = dynlen(stateCounts) ; s ; s -- ) {
	      counts[majority_devicesXpercIdx[deviceIdx][s]] = stateCounts[s];
	    }
	  }
	  majority_mapCounts[key] = counts;
	}
    
	majority_arrayAdd(counts,countsOld,-1,key+" stateCB");
	//      DebugTN(counts, countsOld, key + " stateCB");
	///// set updated
	synchronized (majority_mutex) {
	  if (! majority_arrayZero(counts)) {
	    majority_updated[key] = true;
	  } else if (! mappingHasKey(majority_updated, key) ) {
	    majority_updated[key] = true;
	  }
	}      
      
	majority_updateTreeBranch(nodeIdx,isAll,counts,calcTotal);
	if (loop_over_nodes) {
	  for (int ni = 2; ni <= dynlen(nodeIdxs); ni++) {
	    majority_updateTreeBranch(nodeIdxs[ni],isAll,counts,calcTotal);
	  }
	}
      }
    }
  }
}

void majority_stateCBInternalNode(string dpe, string state) {
  // treat it as if it were a DU child of the related control unit with a dpe that gives the state

  dyn_int deviceIdxs = majority_mapDeviceIdx[dpe];
  dyn_int nodeIdxs = majority_mapNodeIdx[dpe];
  int deviceIdx, nodeIdx;
  string node;
  // the same dpes can trigger the callback in more than 1 device (trick to handle a graph)
  for (int d=1; d<= dynlen(deviceIdxs); d++) {
    deviceIdx = deviceIdxs[d]; nodeIdx= nodeIdxs[d];
    node= treeCache_getNode(nodeIdx);
  
    //  DebugTN("Changed " + node + " " + state);

    for ( int calcTotal = 0 ; calcTotal <= 1 ; calcTotal ++ ) {
      // is always included!
      int all = majority_devicesWeights[deviceIdx];
      dyn_int stateCounts;
      stateCounts = majorityUser_stateCounts(majority_devices[deviceIdx],makeDynString(state),all,calcTotal,node);
      if ( dynlen(stateCounts) != dynlen(majority_devicesXpercIdx[deviceIdx]) ) {
	majority_error("returned number of states by user function does not match with state config");
	exit(0);
	return;      
      }
      for ( int isAll = 0 ; isAll <= 1 ; isAll ++ ) {
	string key = node + (calcTotal?".total.":".included.") + (isAll?"all":"states"); // here i don't put the n because the node does not exist and i do not want to update any dp in majority_update
	dyn_int counts,countsOld;
	synchronized(majority_mapCounts) {
	  if ( mappingHasKey(majority_mapCounts,key) ) {
	    countsOld = majority_mapCounts[key];
	  }
	  else {
	    countsOld[dynlen(isAll?majority_allNumberInit:majority_numberInit)] = 0;
	    majority_mapCounts[key] = countsOld;
	  }
	  counts = countsOld;
	  // now replace current counts in this array
	  if ( isAll ) {
	    counts[deviceIdx] = all;
	  }
	  else {
	    for ( int s = dynlen(stateCounts) ; s ; s -- ) {
	      counts[majority_devicesXpercIdx[deviceIdx][s]] = stateCounts[s];
	    }
	  }
	  majority_mapCounts[key] = counts;
	}
    
	majority_arrayAdd(counts,countsOld,-1,key+" stateCBInternalNode");
	//      DebugTN(counts, countsOld, key + " stateCB");
	majority_updateTreeBranch(nodeIdx,isAll,counts,calcTotal,false,false); // call it with move_to_parent = false
      }
    }
  }  
}

void majority_nCB(string dpe,dyn_int numbers) {
  dpe = dpSubStr(dpe,DPSUB_SYS_DP_EL); // delete attribute and config from dpe
  dyn_int info = majority_mapInfo[dpe]; // [1]:nodeIdx [2]:included(0)/total(1) [3]:n(0)/all(1) -- from 4 onwards, additional nodes
  dyn_int old;
  synchronized(majority_mapN) {
    old = majority_mapN[dpe];
    majority_mapN[dpe] = numbers;
  }
  majority_arrayAdd(numbers,old,-1,dpe+" nCB"); // numbers = numbers - old
  majority_updateTreeBranch(info[1],info[3],numbers,info[2]);
  for (int i=4; i<= dynlen(info); i++) {
    majority_updateTreeBranch(info[i],info[3],numbers,info[2]);
  }
}



void majority_includedCB(string dp, bool state) {
  string node = treeCache_getNodeFromIncludedDp(dp);
  int nodeIdx = treeCache_getNodeIdx(node);
  bool handled;

  majority_debug3(node+" is now "+(state?"included":"excluded"));
  if (majority_getUnitFixed(nodeIdx, true) != "CU") {
    string dp = node + ".included.";
    string sys = treeCache_getSystem(nodeIdx,true);
    int sign = (state?1:-1);
    for ( int isAll = 0 ; isAll <= 1 ; isAll ++ ) {
      string dpe = "majority_" + dp + (isAll?"all":"states") + ".n";
      dyn_int counts;
      if ( majority_getUnitFixed(nodeIdx,true) == "DU" ) {
	handled = false;
	for ( int dev = dynlen(majority_devicesFsmTypes) ; dev ; dev -- ) {
	  if ( dynContains(majority_devicesFsmTypes[dev], treeCache_getType(nodeIdx, true) )) {
	    handled = true;
	  }
	}
	if (! handled ) return; // ignore not handled DU
	counts = majority_mapCounts[dpe];
      }
      else { // LU 
	//// -------
	if (sys == getSystemName()) {
	  counts = majority_getN(dpe, 0);   
	} else {
	  dpGet(sys+dpe,counts);
	}
      }
      majority_arrayScale(counts,sign);
	 
      majority_updateTreeBranch(nodeIdx,isAll,counts,false,true);
    }
  } else { // for a CU: update with no deltas by reading the values in all the children
    if (mappingHasKey(majority_CUIncluded,node)) {
      if (majority_CUIncluded[node] == state) {
        majority_debug4(node +" inclusion goes " + state + "->" + state + ".Returning");
        return;
      }
    }
    majority_CUIncluded[node] = state;
    startThread("majority_updateWithNoDeltas",node, nodeIdx);
  }
}


void majority_updateWithNoDeltas(string node, int nodeIdx, bool calcTotal = false) {
  bool debug = false;
  string numberMode = (calcTotal?"total":"included");
  do {
    int parentIdx = treeCache_getParentI(nodeIdx, true);
    string parent = treeCache_getNode(parentIdx);

    string identif = node + "(" + getThreadId() + ")";
    majority_lastUpdater[parent] = identif;


    int Npollings = 3;
    int pollingTime = 150;

    for (int i=1; i<=Npollings; i++) {
      if (debug) DebugTN(identif + " poll " + i + "/" + Npollings);
      delay(0,pollingTime);
      if (majority_lastUpdater[parent] != identif) {
	if (debug) DebugTN(identif + " kicked out"); 
	return;
      }
    }
    if (debug) DebugTN(identif + " will now update " + parent);


     
    dyn_int children = treeCache_getChildrenI(parentIdx, true);
    for (int c= dynlen(children); c>0; c--) {
      if (! _majority_getIncluded(children[c],true)) {
	dynRemove(children, c);
      } 
    }
    if (debug) {
      string list;
      for (int i=1; i<= dynlen( children); i++) {
	list += treeCache_getNode(children[i]) + " ";
      }
      DebugTN("Included children " + list);
    }

    
    for (int isAll = 0; isAll <= 1; isAll++) {
      string dpe,  sys,dp;
      dyn_int tot_counts, zeros, counts;

 	
      zeros = majority_arrayOfValues((isAll)?dynlen(majority_devices):dynlen(majority_devicesXstates));
      tot_counts = zeros;       
      string relatedTopNode, majoritydp;
      synchronized (majority_mutex) {
	for (int c= 1; c<= dynlen(children); c++) {	          
	  dp = treeCache_getNode(children[c]) + "." + numberMode +  ".";
	  sys = treeCache_getSystem(children[c],true);
	  dpe = dp + (isAll?"all":"states") ;
	  dpe = majority_base+"_"+dpe+".n";
	  majoritydp = sys + majority_base + "_" + treeCache_getNode(children[c]);
	  if (! dpExists(majoritydp) ) continue;
	  dpGet(majoritydp + ".admin.topNode", relatedTopNode);	  
            
	  if (relatedTopNode != majority_topNode) {
	    majority_debug3("Ignoring node " + majoritydp + " belonging to " + relatedTopNode);
	    continue; // ignore children belonging to a different majority topNode
	  }

	  if ( majority_getUnitFixed(children[c],true) == "DU" ) {
	    string fsmType = treeCache_getType(children[c], true);
	    bool handled = false;
	    for ( int dev = dynlen(majority_devicesFsmTypes) ; dev ; dev -- ) {
	      if ( dynContains(majority_devicesFsmTypes[dev], fsmType )) {
		handled = true;
	      }
	    }
	    if (! handled) continue;
	    counts = majority_mapCounts[dpe];
	  }  else { // LU or CU	  
	    string dpeget = sys+dpe;
	    if ( ! dpExists(dpeget) ) continue;
	    if (sys!= getSystemName()) {
	      if (mappingHasKey(majority_mapN,dpeget)) {
        	counts =   majority_mapN[dpeget];
	      } else { // should never happen
		dpGet(dpeget, counts);
	      }
	    } else {
	      counts = majority_getN(dpe,isAll);
	    }
	    if (debug) DebugTN("Getting " + dpe + " = " + counts);
	  }
	  majority_arrayAdd(tot_counts, counts);
	}

	dp = parent + ".included.";
	sys = treeCache_getSystem(parentIdx, true);
	dpe = majority_base+"_" + dp + (isAll?"all.":"states.") ;
	//dpGet(sys+dpe,counts);
	counts = majority_getN(dpe + "n",isAll);
	if (debug) DebugTN(dpe + ": " + counts + " -> " + tot_counts);
	if (! majority_arrayEquals(counts,tot_counts)) {
	  //	  dpSet(sys+majority_base+"_"+dpe+".n",tot_counts);
	  majority_setN(dpe + "n",tot_counts);
	  //	      sys+majority_base+"_"+dpe+".delta",zeros);
	  majority_setPar(dpe + "delta", zeros);

	}
	// Should not be needed. It will be updated next time that majority_update is called!
	/*
	  if (isAll ==1) {
	  // update the percentages only once with isAll = true (this automatically loops over all the states)
	  dyn_string dpes; dyn_mixed values;
	  majority_updatePercentages(majority_base+"_"+parent, numberMode, true, parentIdx, tot_counts, dpes, values, true);  
	  }
	*/
            
       
      } // synchronized
    } // for isAll


    nodeIdx = parentIdx;
       
  } while (( treeCache_getLevelInSystem(nodeIdx,true) != 1 ) && (nodeIdx != treeCache_getNodeIdx(majority_topNode)));
}
     



bool majority_nodeAndChildrenInSystem(int nodeIdx, string sysName) {
  if (treeCache_getSystem(nodeIdx, true)!= sysName) return false;
  dyn_int children = treeCache_getChildrenI(nodeIdx, true);
  for (int i=1; i<= dynlen(children); i++) {
    if (treeCache_getSystem(children[i], true)!= sysName) return false; 
  }
  return true;
}

bool _majority_getIncluded(string node, bool isIdx) {
  if (treeCache_isLogical()) return true;
  return treeCache_getIncluded(node, isIdx);
}

void majority_updateTreeBranch(int nodeIdx, bool isAll, dyn_int deltaN, 
			       bool ignoreExcluded, bool fromIncludedCB=false, bool move_to_parent = true) {

  if ( majority_arrayZero(deltaN) ) { // all deltaN[] are 0
    return;
  }
  string numberMode = (ignoreExcluded?"total":"included");
  dyn_int dpDeltaN,dpDeltaNold;
  bool included = true;
  bool polling = ( majority_polling && !fromIncludedCB && move_to_parent);

  // propagate in tree from leaf to root
  do {
    if (move_to_parent) {
      if ( !fromIncludedCB && included ) {
	included = _majority_getIncluded(nodeIdx,true);
      }
      fromIncludedCB = false;
      if ( !included && !ignoreExcluded ) {
	break;
      }
      nodeIdx = treeCache_getParentI(nodeIdx,true);
    } 
    
    string node = treeCache_getNode(nodeIdx);
    string dp = majority_base+"_"+node;
    string dpe = dp+"."+numberMode+"."+(isAll?"all.":"states.");
    if ( polling ) {
      int Npollings,pollingTime,pollMax,polls;
         
      if (! mappingHasKey(majority_mapPollingPerc,dp + ".admin.pollLoop")) {
	dpGet(dp+".admin.pollLoop",Npollings,
	      dp+".admin.pollTime",pollingTime,
	      dp+".admin.pollMax",pollMax);
	majority_debug4("Setting mapPolling for " + dp + ".admin.pollLoop");
	majority_mapPollingPerc[dp + ".admin.pollLoop"] = Npollings;
	majority_mapPollingPerc[dp+".admin.pollTime"] = pollingTime;
	majority_mapPollingPerc[dp+".admin.pollMax"] = pollMax;
      } else {      
	// Try to avoid a dpGet in this crucial point. Will it work?
	Npollings = majority_mapPollingPerc[dp + ".admin.pollLoop"];
	pollingTime = majority_mapPollingPerc[dp+".admin.pollTime"];
	pollMax = majority_mapPollingPerc[dp+".admin.pollMax"];
      }
      pollingTime = pollingTime * majority_factorPollingTime;
      
      synchronized(majority_mutex) {
	// notify other nodes waiting on change of deltaN
	/*dpGet(dpe+"delta",dpDeltaNold,
	  dpe+"polls",polls);
	*/              
	dpDeltaNold = majority_getPar(dpe + "delta", isAll);
	polls = majority_getPar(dpe + "polls");
        
	polls ++;
	if (( polls > pollMax ) && (majority_pollMaxActive)) {
	  Npollings = 0; // this means: no poll here any more, go to upper node in any case!!
	}
	majority_arrayAdd(dpDeltaNold,deltaN,1,dpe+" updateTreeBranch"); // for the polling!!
	majority_setPar(dpe + "delta", dpDeltaNold);
	majority_setPar(dpe + "polls", polls);
        
	/* dpSet(dpe+"delta",dpDeltaNold,
	   dpe+"polls",polls); */

      }
      // unsynchXronized polling over change of dpDeltaN
      //Npollings = 0;
      for ( int p = 0 ; p < Npollings ; p ++ ) {
	delay(0,pollingTime); // no problem if pollingTime > 999
	synchronized(majority_mutex) {
	  dpDeltaN = majority_getPar(dpe + "delta", isAll);
	}
        
	/*	dpGet(dpe+"delta",dpDeltaN); */
	if ( dpDeltaN != dpDeltaNold ) {
	  // leave this branch visit instance as another instance is caring for the delta
	  return;
	}
      }
	
      synchronized(majority_mutex) {
	majority_setPar(   dpe+"polls",0);    
      }
      //     dpSet(dpe+"polls",0); // update this node and propagate delta up to next node
    }
    //if ( rememberFromIncludedCB ) {
    //DebugTN("updating node",dp,dpe,deltaN,numberMode,isAll,nodeIdx);
    //}
    synchronized(majority_mutex) {
      majority_updateNode(node,dp,dpe,deltaN,numberMode,isAll,nodeIdx,polling);
    }
    if (! move_to_parent) {
      move_to_parent = true;// at the next step always go to parent
      polling = ( majority_polling && !fromIncludedCB && move_to_parent); 
    }
  } while (( treeCache_getLevelInSystem(nodeIdx,true) != 1 ) && (nodeIdx != treeCache_getNodeIdx(majority_topNode)));
}

anytype majority_getFromMapping(mapping& m, string key) {
  if (mappingHasKey(m, key)) return m[key];
  else {
    anytype value;
    dpGet(key, value);
    m[key] = value;
    return value;
  }
}

anytype majority_getPar(string key, int isAll = -1) {
  if (! mappingHasKey(majority_parameter, key)) {
    if (isAll == -1) {
      return 0;
    } else {
      dyn_int delta;
      delta[dynlen(isAll?majority_allNumberInit:majority_numberInit)] = 0;
      return delta;
    }
  }
  return majority_parameter[key]; 
}

void majority_setPar(string key, anytype value) {
  majority_parameter[key] = value; 
}


dyn_int majority_getN(string key, int isAll, bool showWarning = false ) {
  if (! mappingHasKey(majority_n, key)) {
    if (showWarning) {  DebugTN(key + " was not present in the majority_n map "); }
    dyn_int n;
    n[dynlen(isAll?majority_allNumberInit:majority_numberInit)] = 0;
    return n;    
  }
  return majority_n[key]; 
}

void majority_setN(string key, dyn_int value) {
  //  DebugN("setN " + key + " " + value);
  majority_n[key] = value; 
  majority_updated[key] = true;
}

int majority_getUptime() {
  return  (period(getCurrentTime()) - period(majority_startTime)) ;
}

void majority_updateNode(string node, string dp,string dpe,dyn_int&deltaN,string numberMode,
			 bool isAll,int nodeIdx,bool polling) {
  // do the following only in case of propagation to the next node!
  dyn_int n,dpDeltaN;
  //     dpGet(dpe+"n",n);

  n = majority_getN(dpe + "n", isAll);
  dpDeltaN=majority_getPar(dpe + "delta", isAll);
     
  //   dpe+"delta",dpDeltaN); // probably, new dpDeltaN is different from original deltaN, maybe 0 in meanwhile (??!)
  if ( polling ) {
    deltaN = dpDeltaN; // dpDeltaN at least contains old deltaN in case of polling
    if ( majority_arrayZero(dpDeltaN) ) {
      return;
    }
  }
  else {
    majority_arrayAdd(deltaN,dpDeltaN,1,dpe+" updateNode (1)");
  }
  majority_arrayAdd(n,deltaN,1,dpe+" updateNode (2)");
   
  if ((isAll) && (numberMode == "total")) {
    if (majority_arrayEquals(n,majority_totals["node" + nodeIdx])) {
      majority_debug4(dp + " now initialized");
      dpSet(dp + ".admin.valid", true);
      if (majority_factorPollingTime != 1) {
	if (treeCache_getLevelInSystem(node) == 1) {
	  majority_debug3("Setting back the polling time to 1") ;
	  majority_debug3("Started in " + majority_getUptime() + " seconds");
	  majority_factorPollingTime = 1;     
	  majority_pollMaxActive = true;
	  majority_valid = true;
	}
      }
    } else {
      majority_debug4(dp + " not yet initialized");
      if (majority_forceValid) {
	dpSet(dp + ".admin.valid", true);
      } else {
	dpSet(dp + ".admin.valid", false);
      }
    }
  }
  //dpSet(dpe+"n",n);
  majority_setN(dpe + "n",n);
  majority_setPar(dpe+"delta",isAll?majority_allNumberInit:majority_numberInit);
  //DebugTN("dynlen",dynlen(isAll?majority_allNumberInit:majority_numberInit),isAll,dynlen(majority_numberInit));
  // warning when n < 0
  for ( int k = dynlen(n) ; k ; k -- ) {
    if ( n[k] < 0 ) {
      startThread("majority_checkNegativeN", dpe, isAll);
    }
  }     
  // percentages are now updated in the majority_update() function running in  a separate  global thread...
  //     startThread("majority_updatePercentages",dp,numberMode,isAll,nodeIdx, n);
}



int majority_setPercentages(string node, dyn_float compPerc, bool recursive = true) {
  if (dynlen(compPerc) != dynlen(majority_devicesXstates)) {
    return _majority_error("Percentage length not matching should be " + dynlen(majority_devicesXstates));
  }

  string dp = majority_getDpFromNode(node);

  if (! dpExists(dp) ) return -1;

  dpSet(dp + ".admin.percentages", compPerc);
     
  if (! recursive) return 0;

  int start, stop;
  treeCache_getVisitIndexes(node, start, stop);
  for (int i=start; i<= stop; i++) {
    if (majority_getUnitFixed(i, true) != "DU") {
      majority_setPercentages(treeCache_getNode(i), compPerc, false);
    }
  }

  return 0;
}

/*
  This updates dpes and values with the dpes and values to set
  if execute_dpSet == true then at the end it sets the values and clears the arrays

*/
void majority_updatePercentages(string dp, string numberMode, bool isAll, int nodeIdx, dyn_int n,
				dyn_string& dpes, dyn_mixed& values , bool execute_dpSet = false) {

  // objective: remove all the dpGets from this function and group the dpSet's at the end

  // update percentages and FSM state only for 
  // (included node information and - of course - [now, also for total numbers]) LUs/CUs
  if ( /*( numberMode == "total" ) || */
      ( majority_getUnitFixed(nodeIdx,true) == "DU" ) ) {
    return;
  }
  dyn_int nAll;
  string fsmState;
  bool calcFsmState = false;

  dyn_float compPerc,perc;
  string dpe = dp+"."+numberMode+".";
  dyn_string exc;
  fwGeneral_getNameWithoutSN(dpe, dpe, exc);

  compPerc = majority_getFromMapping(majority_mapPollingPerc, dp + ".admin.percentages");
  // DebugN("compPerc ", dp, compPerc);

  if ( isAll ) { // "all" state: loop over the states of this device and update their percentage
    nAll = n; // all device counts
    //dpGet(dpe+"states.n",n); // state counts 

    n = majority_getN(dpe + "states.n", 0);   
  }
  else { // update state percentage using current total value
    //dpGet(dpe+"all.n",nAll); 

    nAll = majority_getN(dpe + "all.n", 1); 
  }


  for ( int i = dynlen(n) ; i ; i -- ) {
    int deviceIdx = majority_deviceIdxXstates[i];
    perc[i] = (nAll[deviceIdx]>0)?100.*n[i]/nAll[deviceIdx]:0;
    //
    // this check was done to avoid recomputing the fsmState when the percentages change into the limits. It is not crucial
    //    majority_checkPerc(perc[i],oldPerc[i],compPerc[i],calcFsmState);
  }


  dynAppend(dpes, dpe + "percentages");
  values[dynlen(values) + 1] = perc;
  //dpSet(dpe+"percentages",perc);
     
  mapping majStates,mapPerc;
  dyn_int majStatesArray;
  int majority;
  for ( int i = dynlen(perc) ; i ; i -- ) {
    // Check sanity of percentages
    if ((majority_valid) && ((perc[i] <0) || (perc[i] > 100))) {
      int uptime = majority_getUptime();
      if (uptime > 400) {
	startThread("majority_checkPercentageOutOfRange",dpe, nodeIdx, numberMode);
      }
    }
       	  
    if (nAll[majority_deviceIdxXstates[i]] == 0) majority = majority_TOTALZERO;
    else if ( perc[i] == 0 ) majority = majority_OFF;
    else if ( (   0 <  perc[i] ) &&  ( perc[i] <  compPerc[i] ) ) majority = majority_MIXED;
    else if  (  ( 100 >  perc[i] ) && ( perc[i] == compPerc[i] ) )  majority = majority_ON;
    else if ( ( 100 >  perc[i] ) && ( perc[i] > compPerc[i] ) ) majority = majority_MORE;
    else majority = majority_ALL;
    majStates[majority_devicesXstates[i]] = majority;
    majStatesArray[i] = majority;
    mapPerc[majority_devicesXstates[i]] = perc[i];
  }

  /*
    if ( !calcFsmState  && (oldFsmState!="UNUSED")  ) {
    fsmState = oldFsmState;
    } else {
    fsmState = majorityUser_calcFsmState(majStates,mapPerc,treeCache_getNode(nodeIdx));
    }
  */



  string fsmState;
  fsmState = majorityUser_calcFsmState(majStates,mapPerc,treeCache_getNode(nodeIdx));
  string oldFsmState = majority_getFromMapping(majority_mapFsmStates,dpe + "fsmState");

  // if the FSM state has changed, append it to the list of data points to set and update the mapping
  if (oldFsmState != fsmState) {
    majority_mapFsmStates[dpe + "fsmState"] = fsmState;    
    dynAppend(dpes, dpe+"fsmState");
    values[dynlen(values) + 1] = fsmState;
  }
  
  dynAppend(dpes, dpe+ "majStates"); 
  values[dynlen(values)+1] = majStatesArray;

  if (execute_dpSet) {
    dyn_string exc;
    majority_dpSetMany(dpes, values,exc);
    dynClear(dpes); dynClear(values);
  }

}
void majority_sendMail(string subject,string body) {
  if (strlen(majority_mailNotification)==0) return;
     
  dyn_string recipients = strsplit(majority_mailNotification,",");
  string server = "cernmx.cern.ch";
  string client = getenv("COMPUTERNAME");
  string sender = strrtrim("majority-"+getSystemName(),":") + "@cern.ch";
  body += "\n\nall recipients of this mail:\n"+recipients+"\n";
  dyn_string email = makeDynString("",sender,"[majority] " + subject,body);
  int ret;
  for ( int o = 1 ; o <= dynlen(recipients) ; o ++ ) {
    email[1] = recipients[o];
    majority_debug3(sender+" sending email with subject '"+subject+"' to "+email[1]);
    emSendMail(server,client,email,ret);
    if ( ret ) {
      majority_debug1("\n\n\nERROR: problem sending email from "+client+" via "+server+
		      "\nsubject:"+subject+"\ncontents:\n"+body+"\n\n");
    }
  }
}

void majority_checkPercentageOutOfRange(string dpe, int nodeIdx, string numberMode) {
  
  
  delay(8); // wait if it comes back to a normal value (it can happen if you update n before the totals!)            
  dyn_float perc, prev_perc;
  
  dpGet(dpe + "percentages", perc);
  int count = 0;
  int n = 0;
  do {
    prev_perc = perc;
    delay(2);
    dpGet(dpe + "percentages", perc);     
    if ( majority_arrayEquals(perc, prev_perc)) n++;
    count++;
  } while ((n < 2) && (count < 100)); // wait for stability or a max of 200 seconds
                
  
  for ( int i = dynlen(perc) ; i ; i -- ) {
    if ((perc[i] <0) || (perc[i] > 100)) {
      int uptime = majority_getUptime();
                        
      string text = "WARNING: Percentage out of range (" + (perc[i]) + "%) for " + treeCache_getNode(nodeIdx) + " in " + majority_devicesXstates[i] + " numberMode=" + numberMode +  
	+ "\nAfter " + uptime + " seconds of operation\nMajority was restarted on system " + getSystemName();
      majority_debug1(text);
      majority_sendMail("Percentage out of range",text);
      majority_restart(); 
    }
  }
}


majority_checkNegativeN(string dpe, int isAll) {
  delay(8);
  dyn_int n = majority_getN(dpe, isAll);

  for ( int k = dynlen(n) ; k ; k -- ) {
    if ( n[k] < 0 ) {
      string text = "WARNING: n["+k+"] == "+n[k]+" in "+dpe+"n" + "\nMajority restarted:" + majority_valid
	+"\nAfter " + majority_getUptime() + " seconds of operation";          
      majority_debug1(text);
      majority_sendMail("negative n detected",text);
      if (majority_valid) majority_restart(); 
    }
  }
}
/* Set the list of recipients that should be notified (comma separated) */
void majority_setMailRecipients(string topNode, string list_recipients) {
  string mailDp = majority_getConfigDp(topNode) + ".admin.mailRecipients";
  dpSet(mailDp  ,list_recipients);
}

void majority_arrayScale(dyn_int&a,int factor=1) {
  for ( int i = dynlen(a) ; i ; i -- ) {
    a[i] *= factor;
  }
}

void majority_arrayAdd(dyn_int&a,dyn_int&b,int factor=1,string where="") {
  if ( dynlen(a) != dynlen(b) ) {
    majority_debug1("WARNING: array mismatch ("+dynlen(a)+","+dynlen(b)+") in arrayAdd(). debug:"+a+" @ "+b+" @ "+factor+" @ "+where);
  }
  for ( int i = dynlen(a) ; i ; i -- ) {
    a[i] += (factor*b[i]);
  }
}

bool majority_arrayZero(dyn_int&a) {
  return ( dynCount(a,0) == dynlen(a) ); // all elements are 0
}


dyn_int majority_arrayOfValues(int len, int value = 0) {
  dyn_int a;
  for (int j = 1; j<= len; j++) a[j] = value;
  return a;
}

bool majority_arrayEquals(dyn_int a, dyn_int b) {
  if ( dynlen(a) != dynlen(b) ) {
    majority_debug1("WARNING: array mismatch ("+dynlen(a)+","+dynlen(b)+") in arrayEquals(). debug:"+a+" @ "+b+" @ ");
    return false;
  }
  for ( int i = dynlen(a) ; i ; i -- ) {
    if (a[i]!=b[i]) return false;
  }
  return true;
}

void majority_checkPerc(float perc,float oldPerc,float compPerc,bool&calcFsmState) {
  if (majority_alwaysCalcFsmState) {
    calcFsmState = true;
    return; 
  }
  if ( ( ( perc < compPerc ) && ( compPerc < oldPerc ) ) ||
       ( ( perc > compPerc ) && ( compPerc > oldPerc ) ) ||
       ( ( perc ==0        ) && ( 0        < oldPerc ) ) ||
       ( ( perc > 0        ) && ( 0        ==oldPerc ) ) ||
       ( ( perc < 100      ) && ( 100      ==oldPerc ) ) ||
       ( ( perc ==100      ) && ( 100      > oldPerc ) ) )
    {
      calcFsmState = true;
    }
}

dyn_string majority_getConfigs() {
  dyn_string dps = dpNames(majority_base+"Config*",majority_base+"Config");
  dyn_string topNodes;
  for ( int d = dynlen(dps) ; d ; d -- ) {
    topNodes[d] = strsplit(dpSubStr(dps[d],DPSUB_DP),"_")[2];
  }
  return topNodes;
}

int majority_getConfigIdx(string node,int nodeIdx,dyn_string&array) {
  int idx = dynContains(array,node); // is node contained in configured array?
  if ( !idx ) {
    idx = dynContains(array,treeCache_getLevel(nodeIdx,true)); // no, try level
  }
  return idx;
}

int majority_getWeight(string device) {
  int deviceIdx = dynContains(majority_devices,device);
  if ( !deviceIdx ) {
    return majority_error("unknown device "+device);
  }
  return majority_devicesWeights[deviceIdx];
}

bool majority_addToArray(string element,dyn_string&array,int&idx) {
  idx = dynContains(array,element);
  if ( !idx ) {
    dynAppend(array,element);
    idx = dynlen(array);
    return true;
  }
  return false;
}

// verify sanity of level or node
int majority_checkLevelOrNode(string levelOrNode) {
  int level = levelOrNode;
  if ( (string)level == levelOrNode ) { // is level number
    if ( ( level <= 0 ) || 
	 ( level > treeCache_getNumberOfLevelsBelow(treeCache_getTopNode())+1 ) ) {
      return majority_error("level "+level+" out of range");
    }
    return level;
  }
  if ( !treeCache_isNode(levelOrNode) ) {
    return majority_error("node "+levelOrNode+" does not exist");
  }
  return 0;
}

dyn_string majority_flatten(dyn_dyn_string array) {
  dyn_string res;
  for ( int i = dynlen(array) ; i ; i -- ) {
    res[i] = _treeCache_flatten(array[i],treeCache_delimiter1);
  }
  return res;
}

dyn_dyn_string majority_unflatten(dyn_string flattened) {
  dyn_dyn_string res;
  for ( int i = dynlen(flattened) ; i ; i -- ) {
    res[i] = _treeCache_unflatten(flattened[i],treeCache_delimiter1);
  }
  return res;
}



void majority_setDebug(int debugLevel) {
  majority_debugLevel = debugLevel;
  majority_debug3("new debug level is "+debugLevel);
}
void majority_debug(string msg,int debugLevel) {
  if ( majority_debugLevel >= debugLevel ) {
    DebugTN("majority: "+msg);
  }
}
void majority_debug1(string msg) { majority_debug(msg,1); } // most important msgs
void majority_debug2(string msg) { majority_debug(msg,2); }
void majority_debug3(string msg) { majority_debug(msg,3); }
void majority_debug4(string msg) { majority_debug(msg,4); } // most detailed/expert msgs

int majority_error(string msg) {
  majority_debug1("\n\n\nERROR OCCURED:\n\n"+msg+"\n\n\n\n\n");
  return -1;
}

void majority_automaticConfig(int base_poll_time, int base_max = 3) {
  majority_debug1("Starting automatic config with base_poll_time = " + base_poll_time);
  string dp = treeCache_createDp("majority_base_poll_time", "ExampleDP_Int",treeCache_getSystem(majority_topNode));
  dpSet(dp + ".", base_poll_time); 
  majority_clearPollConfig();
  majority_visitConfig(majority_topNode,1, base_poll_time, base_max);
}


void majority_visitConfig(string node, int level,int base_poll_time, int base_max) {

  string unit = majority_getUnitFixed(node);
  if (unit == "DU") return;
  
  
  dyn_string children = treeCache_getChildren(node);
  
  
  int n_children = 0;
  string fsmType;

  for (int i=1; i<= dynlen(children); i++) {
    unit = majority_getUnitFixed(children[i]);
    fsmType = treeCache_getType(children[i]);
    if (unit == "DU") {
      for ( int dev = dynlen(majority_devicesFsmTypes) ; dev ; dev -- ) {
	if ( ! dynContains(majority_devicesFsmTypes[dev] ,fsmType) ) {
	  continue;
	}
	n_children ++; // count the device unit only if it is of one type defined in the majority
      }
    } else {
      // in the case of CU / LU
      // count as child only if it has other children              
      if (dynlen(treeCache_getChildren(children[i])) > 0) {
	n_children++; 
      } 
        
    }
  }
          
  
  if (n_children == 0) {
    return;      
  }
  
  int number_polls;
  int poll_time; // milli seconds
  int max; // max number of polls
  
  if (n_children == 1) {
    max = 0; number_polls = 1; poll_time = 1; 
  } else {
    //max = dynMin(makeDynInt(dynMax(makeDynInt(,n_children-2)),22));
    max = base_max; if (n_children > 12) max++;
    
    //poll_time = base_poll_time;
    
    poll_time = (int) (base_poll_time * (0.3 + (0.1 * dynMin(makeDynInt(12,n_children))))) * majority_correctionFactor(level); 
    // n_children >= 2 so the minimum is base_poll_time * (0.3 + 0.1 *2) = 0.5 * base_poll_time and the maximum is 
    // base_poll_time * (0.3 + 0.1 * 12) = 1.5 * base_poll_time
    // this is then multiplied by a correction factor that is 1.3 for the top level and decreases when you increase the level -- removed this factor!
    
    if (n_children > 15) {
      number_polls = 2;
    } else {
      number_polls = 1;    
    }
    poll_time = poll_time / number_polls;
  }

  majority_debug1("Configuring node " + node + " n_children=" + n_children + ", num_polls = " +  number_polls + " poll_time=" + poll_time + " max = " + max);
         
  majority_addPollConfig(node,number_polls,poll_time,max);
  
  for (int c=1; c<= dynlen(children); c++) {
    majority_visitConfig(children[c], level+1,base_poll_time, base_max); 
  }  
}

float majority_correctionFactor(int level) {
  return 1;
  /*
    if (level == 1) {
    return 1.3; 
    } else if (level == 2) {
    return 1.1;    
    } else if (level == 3) {
    return 0.9;     
    } else {
    return 0.8;    
    }
  */
}


/*
  Auxiliary functions for graphical interfaces
*/



string majority_getDpFromNode(string node, bool use_cache = true) {
  string sys;
  if (use_cache) sys = treeCache_getSystem(node);
  else {
    fwUi_getDomainSys(node, sys); // if it is a CU (domain) find the proper system Name
    if (sys == "") // if not found (not a CU) use fwCU_getDp
      sys = _treeCache_getSystemFromFw(node);
  }
  return sys + majority_base + "_" + node;
}


string majority_getConfig(string topNode) {
  return majority_getConfigDp(topNode);		       
}

dyn_string majority_getDevicesXStates(string topNode) {
  dyn_string devicesXStates;
  dpGet(majority_getConfig(topNode) + ".percentages.devicesXstates", devicesXStates);
  return devicesXStates;

}

dyn_string majority_getDevices(string topNode) {
  dyn_string devices;
  dpGet(majority_getConfig(topNode) + ".devices.list", devices);
  return devices;
}


/*
  Function to find devices in the given state. The function performs an intelligent visit of the majority tree

  @param topNode majority topNode (to read the configuration)
  @param treeCacheTopNode topNode for treeCache
  @param root node where to start the search
  @param included search among the included devices or among alll
  @param device   device type to search (as in the configuration of the majority)
  @param state    basic state of the device to search
  @param notInState if this is true it will find all the devices NOT in the given state
  @return list of devices (node names) satisfying the search criteria
*/
dyn_string majority_find(string topNode, string treeCacheTopNode, string root, bool included, string device, string state, bool notInState = false) {
  // Get the needed information in a majority object
  dyn_mixed majority_object; 
  majority_new(topNode, treeCacheTopNode);
  majority_readConfigObject(majority_object,topNode);
  return majority_findFromObject(majority_object, topNode, root, included, device, state, notInState);
 
}

// same as above if you have already the majority_object loaded
// The majority_object is passed by reference for avoid reallocating memory
dyn_string majority_findFromObject(dyn_mixed& majority_object, string topNode, string root,  bool included, string device, string state, bool notInState = false) {
  int index_devXstate = dynContains(majority_object[majority_DEVICESXSTATES], device + ":" + state);
  int index_dev = dynContains(majority_object[majority_DEVICES], device);
  if (index_devXstate == 0) {
    majority_error("device:state not found " + device + ":" + state);
    return makeDynString();
  }

  dyn_string device_types = majority_object[majority_DEVICESFSMTYPES][index_dev];
  return majority_findNodes(topNode,root,  included, index_devXstate, index_dev,device_types,  notInState, majority_object[majority_INTERNALMODE]);  
}

dyn_string majority_findNodes(string topNode,string node, bool included, int index_devXstate, int index_dev, dyn_string device_types, bool not = false, bool internalMode = true) {  
  dyn_string nodes = makeDynString(node);
  dyn_int selected_nodes = makeDynInt();
  if (included) treeCache_initIncludedCache(node);
    
  int pos, value;
  while (dynlen(nodes)>0) {
    for (int i= dynlen(nodes); i>0; i--) {
      if (dynContains(device_types, treeCache_getType(nodes[i])) ) {
     	if (majority_getUnitFixed(nodes[i])!="DU") {
          if (internalMode) {
            if (! majority_hasNoDescendantsOfType(nodes[i], device_types)) {
              continue; // skip internal nodes in the search
            } 
          }
        }
	
	// insert in the proper position in order to obtain an ordered array
	value = treeCache_getNodeIdx(nodes[i]);
	pos = dynlen(selected_nodes);
	while ((pos >0) && (selected_nodes[pos] >  value)) {
	  pos--;
	}        
	dynInsertAt(selected_nodes, value,pos + 1);
	
	if (majority_getUnitFixed(nodes[i])=="DU") {
	  dynRemove(nodes,i); 
	}
      } 
    }
    dyn_string children;
    for (int i= dynlen(nodes); i>0; i--) {
      children = treeCache_getChildren(nodes[i]);
      if (included) {
	for (int c=dynlen(children); c>0; c--) {
	  if (! treeCache_getIncluded(children[c],false,true)) {
	    dynRemove(children,c);
	  }
	}
      }
      dynAppend(nodes, children);
      dynRemove(nodes,i);                        
    }
    nodes = majority_selectByState(topNode,nodes, included, index_devXstate,index_dev, device_types, not);       
  }
  // selected nodes is an ordered array so the nodes are in the correct order
  dyn_string selected_nodes_names = makeDynString();
  for (int i=1; i<= dynlen(selected_nodes); i++) {
    selected_nodes_names[i] = treeCache_getNode(selected_nodes[i]);
  }
  return selected_nodes_names;
}

dyn_string majority_selectByState(string topNode,dyn_string nodes, bool included, int index_devXstate, int index_dev,dyn_string fsmDeviceType, bool not = false) {
  dyn_string nodesDp, allDp; 
  dyn_string selected_nodes;
  string majority_dp;
  for (int i=dynlen(nodes); i>0; i--) {
    majority_dp = majority_getDpFromNode(nodes[i]);
    if (! dpExists(majority_dp) ) {
      dynRemove(nodes,i);
    }
  }
    
  dyn_string topNodes, topNodesDp;
    
  for (int i=1; i<= dynlen(nodes); i++) {
    majority_dp = majority_getDpFromNode(nodes[i]);
    nodesDp[i] = majority_dp + ((included)?".included":".total")  + ".states.n";     
    allDp[i] = majority_dp + ((included)?".included":".total")  + ".all.n";     
    topNodesDp[i] = majority_dp + ".admin.topNode";                                         
  }
  dyn_dyn_int counts;
  dyn_dyn_int totals;
     
  _treeCache_dpGetAll(topNodesDp, topNodes);
  _treeCache_dpGetAll(nodesDp, counts);
  if (not) {
    _treeCache_dpGetAll(allDp, totals);
  }
    
    
    
  bool passed;

  for (int i=1; i<= dynlen(nodes); i++) {
    if (topNodes[i] != topNode) {
      passed = false;
    } else if (not) {
      passed = (counts[i][index_devXstate]<totals[i][index_dev]); 
    } else {
      passed = (counts[i][index_devXstate]>0);
    }
    //DebugN("node, counts, passed",nodes[i],nodesDp[i],counts[i],passed); delay(0,20);
      
      
    if (passed) dynAppend(selected_nodes, nodes[i]); 
  } 
  return selected_nodes;
}

/** UI Functions start here **/

/* select table mode : can be
   -percentage (default)
   -percentage% (percentage with % sign)
   -absolute (absolute number)
   -ratio (absolute/total)
*/
void majority_ui_setTableMode(string mode) {
  dyn_string possibleModes = makeDynString("percentage","percentage%","absolute","ratio");
  if (! dynContains(possibleModes, mode) ) {
    DebugN("Unknown mode "+ mode + ".Switching to default");
    mode = "percentage"; 
  }
  majority_ui_mode = mode;
}

void majority_ui_addElement(string node, string majority_topNode,  string detail_panel = "",
			    string treeCache_topNode = "", string column, int x, int y, int column_width=34, bool show_header = false, string column_label = "", bool showTotal = false, string ref_panel_name = ""
			    , dyn_string detailed_devices = makeDynString()) {
  if (column_label == "") column_label = column;
                                         
  majority_ui_addTable(node, majority_topNode, detail_panel, treeCache_topNode, makeDynString(column), makeDynString(column_label), column_width, false, show_header, x,y, showTotal, ref_panel_name, detailed_devices);
}

void majority_ui_addRow(string node, string majority_topNode, string detail_panel = "", string treeCache_topNode = "", dyn_string selected_columns = makeDynString(), 
			dyn_string column_labels = makeDynString(), int column_width = 34, bool show_header =false, int x = 360, int y = 90, bool showTotal = false, string ref_panel_name = "", dyn_string detailed_devices = makeDynString()) {
  majority_ui_addTable(node, majority_topNode, detail_panel,treeCache_topNode, selected_columns, column_labels, column_width, false, show_header, x,y, showTotal, ref_panel_name, detailed_devices);
}


/* Use this function to add the table to your fsm panel */
/*
 * @node the node to display
 * @majority_topNode majority_topNode top node in the majority
 * @detail_panel  panel to show the details (default  "majority_treeCache/majorityDetails.pnl", you may want to use a customized version)
 * @treeCache_topNode top node for tree cache (default == majority_topNode)
 * @selected_columns list of columns to display (in the form device:state). Default = all
 * @column_labels Labels for the columns (default is the names)
 * @show_children show all the children of the node (to put it besides the FSM panel) - if false only one row with the node parameters is displayed
 * @show_header   show the table header?
 * @column_width column width in pixel
 * @x x coordinate (do not change the default if adding to an FSM panel)
 * @y y coordinate (do not change the default if adding to an FSM panel)
 * @showTotal     show the total numbers and not the included
 * @ref_panel_name     name of the reference panel (default = "majrefpanel_" + node)
 * @detailed_devices   list of devices to be shown in the detailed panel opened on click (default: all)
 */
void majority_ui_addTable(string node, string majority_topNode, string detail_panel = "",
			  string treeCache_topNode = "", dyn_string selected_columns = makeDynString(), 
			  dyn_string column_labels = makeDynString(), int column_width = 34, bool show_children = true, bool show_header= true, int x = -1, int y = -1, bool showTotal = false, 
			  string ref_panel_name = "", dyn_string detailed_devices = makeDynString()) { 

  if (strlen(treeCache_topNode) == 0) treeCache_topNode = majority_topNode;
  treeCache_start(treeCache_topNode);
    
  int default_x = 360; int default_y = 90; // this is the default position of the FSM children
  if ((x == -1) && (y == -1)) {
    string shapeName = "";
    dyn_string children = treeCache_getVisibleChildren(node);
    shapeName = children[1];
    if (treeCache_getUnit(shapeName) == "CU") shapeName = shapeName + "::" + shapeName;
    if (! shapeExists(shapeName) ) {
      x = default_x; y = default_y;
    } else {
      int xshape, yshape;
      getValue(shapeName, "position",xshape, yshape);
      x = default_x;
      y = yshape - 10;
    }
  }

  if (strlen(detail_panel) ==0) detail_panel = "majority_treeCache/majorityDetails.pnl";
  if (strlen(ref_panel_name) == 0) ref_panel_name = "majrefpanel_" + node;
  string labels;
  if (dynlen(column_labels) == 0) labels = "auto";
  else {
    fwGeneral_dynStringToString(column_labels, labels); 
  }
 
  string cols;
  if (dynlen(selected_columns) == 0) cols = "all";
  else fwGeneral_dynStringToString(selected_columns, cols);

  string  detailed_devices_str;
  fwGeneral_dynStringToString(detailed_devices, detailed_devices_str);
  
  addSymbol(myModuleName(), myPanelName(),"majority_treeCache/majorityTable.pnl",ref_panel_name,makeDynString("$1:" + node,
													      "$majority_topNode:" + majority_topNode,
													      "$majority_detailPanel:" + detail_panel,
													      "$treeCache_topNode:" + treeCache_topNode,
													      "$column_labels:" + labels,
													      "$column_width:" + column_width,
													      "$selected_columns:" + cols,
													      "$show_children:" + ((int) show_children),
													      "$show_header:" + ((int) show_header),
													      "$mode:"+ majority_ui_mode,
													      "$show_total:" + (showTotal?1:0),
													      "$detailed_devices:" + detailed_devices_str),
	    x,y,0,1,1);            
}


void majority_getAccessControlConfiguration(bool& alwaysHide, string& required_privilege) {
  string cfgDp = majority_getConfigDp($majority_topNode); 
  dpGet(cfgDp + ".accessControl.hideExpertCommands",alwaysHide,
	cfgDp + ".accessControl.requiredPrivilege",required_privilege);
}

/* 

 */
void majority_setAccessControl_alwaysHide(string topNode,bool alwaysHide) {
  string cfgDp = majority_getConfigDp(topNode); 
  dpSet(cfgDp + ".accessControl.hideExpertCommands",alwaysHide);
}

void majority_setAccessControl_required_privilege(string topNode,string  required_privilege) {
  string cfgDp = majority_getConfigDp(topNode); 
  dpSet(cfgDp + ".accessControl.requiredPrivilege",required_privilege);
}


string majority_getNodeNameFunction(string topNode) {
  string cfgDp = majority_getConfigDp(topNode); 
  string function;
  dpGet(cfgDp + ".ui.functionNodeName",function);
  return function;
}


void majority_setNodeNameFunction(string topNode, string function) {
  string cfgDp = majority_getConfigDp(topNode); 
  dpSet(cfgDp + ".ui.functionNodeName",function);
}

void majority_setForceValid(bool forceValid) {
  majority_forceValid = forceValid;
}

/* Gets the majority configuration for an FSM node without using the treeCache

   @node (in) FSM node 
   @topNode (out) majority topNode
   @dp (out)      dp to connect to (usually to dp + ".included.percentages" and dp + ".included.majStates" for the colors)
   @majorityObject (out) contains all the configuration info
   @exceptionInfo (out)  problems are returned here
    
*/
void majority_getNodeConfiguration(string node, string& topNode, string& dp, dyn_mixed& majorityObject, dyn_string& exceptionInfo) {
  if (! fwFsmTree_isNode(node) ) {
    fwException_raise(exceptionInfo, "NOT_A_NODE", node + " is not an FSM node", "");
    return;
  }
  
  dp = majority_getDpFromNode(node, false);
  if (! dpExists(dp) ) {
    fwException_raise(exceptionInfo, "DP_NOT_FOUND", dp + " not found", "");
    return;
  }
  dpGet(dp + ".admin.topNode", topNode);
  
  if (! fwFsmTree_isNode(topNode) ) {
    fwException_raise(exceptionInfo, "NOT_A_NODE", topNode + " is not an FSM node", "");
    return;
  }
  string configDp = majority_getConfigDp(topNode, false);

  if (! dpExists(configDp) ) {
    fwException_raise(exceptionInfo, "DP_NOT_FOUND", configDp + " not found", "");
    return;
  }
  
  int res = majority_readConfigObject(majorityObject, topNode, false);
  if (res == -1) {
    fwException_raise(exceptionInfo, "CONFIG_ERROR", "Error while reading majority config for  " + topNode, "");
    return;
  }  
}

void majority_openDetails(string node) {
  string topNode; string dp; dyn_mixed obj; dyn_string exc;
  majority_getNodeConfiguration(node, topNode, dp, obj, exc);
    
  ChildPanelOnCentral("majority_treeCache/majorityDetails.pnl",
		      "Majority details for " +( node), makeDynString("$1:" + node, "$majority_topNode:" + topNode, "$treeCache_topNode:" + topNode, 
								      "$devices:"));
                          
}
