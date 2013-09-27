/*
 * Detector Protection component
 *
 * @author Lorenzo Masetti CMS DCS lorenzo.masetti@cern.ch  
 */

#uses "fwConfigurationDB/fwConfigurationDB_Utils.ctl"
#uses "majority_treeCache/treeCache.ctl"

// Constants to index a detectorProtection object (of type dyn_mixed)
const int CMSfwDetectorProtection_CONDITIONNAME = 1;
const int CMSfwDetectorProtection_INPUTDPES = 2;
const int CMSfwDetectorProtection_CONDITIONACTIVE = 3;
const int CMSfwDetectorProtection_FIRED = 4;
const int CMSfwDetectorProtection_CHANGED = 5;
const int CMSfwDetectorProtection_OUTPUTMODE = 6;

// MODE dpes
const int CMSfwDetectorProtection_OUTPUTDPES = 7;

// MODE treeCache
const int CMSfwDetectorProtection_TOPNODE = 8;
const int CMSfwDetectorProtection_DUTYPE = 9;
const int CMSfwDetectorProtection_DPELEMENT = 10;
const int CMSfwDetectorProtection_TREECACHETOPNODE = 11;

//MODE userFunction
const int CMSfwDetectorProtection_USERFUNCTION = 12;

const int CMSfwDetectorProtection_OUTPUTVALUE = 13;
const int CMSfwDetectorProtection_OUTPUTVALUETYPE = 14;
const int CMSfwDetectorProtection_CONFIGDP = 15;

const int CMSfwDetectorProtection_ENABLEVERIFY = 16;

// MODE dpes
const int CMSfwDetectorProtection_VERIFY_DPES = 17;

// MODE treeCache
const int CMSfwDetectorProtection_VERIFY_DPELEMENT = 18;

// Verify function
const int CMSfwDetectorProtection_VERIFY_FUNCTION = 19;

const int CMSfwDetectorProtection_VERIFY_DELAY = 20;
const int CMSfwDetectorProtection_VERIFY_FREQUENCY = 21;
const int CMSfwDetectorProtection_VERIFY_USERFUNCTION = 22;

const int CMSfwDetectorProtection_DISCONNECTED_TIMEOUT = 23;
const int CMSfwDetectorProtection_DEBUGLEVEL = 24;
const int CMSfwDetectorProtection_OUTPUTVALUE_USERFUNCTION = 25;
const int CMSfwDetectorProtection_PREPOST_USERFUNCTION = 26;
const int CMSfwDetectorProtection_DELAY = 27;
const int CMSfwDetectorProtection_CONDITIONTYPE = 28;
const int CMSfwDetectorProtection_INFOFUNCTION = 29;
const int CMSfwDetectorProtection_CUSTOMPROPERTIES = 30;

// "Linear" Translation in memory of the action matrix
const int CMSfwDetectorProtection_OUTDPES = 31;
const int CMSfwDetectorProtection_OUTDPES_CONDITIONS = 32;

const string CMSfwDetectorProtection_configType = "CMSfwDetectorProtectionConfig";
const string CMSfwDetectorProtection_inputType = "CMSfwDetectorProtectionInput";
const string CMSfwDetectorProtection_replyType = "CMSfwDetectorProtectionReply";
const string CMSfwDetectorProtection_managerType = "CMSfwDetectorProtectionManager";
string CMSfwDetectorProtection_managerDp = "CMSfwDetectorProtection/CtrlManager";
const string CMSfwDetectorProtection_generalConfigDp = "CMSfwDetectorProtection/GeneralConfig";

string CMSfwDetectorProtection_managerDpReplies = "CMSfwDetectorProtection/CtrlManagerCheckReply";

// Enumeration of the possible modes

const int CMSfwDetectorProtection_MODE_DPES = 1;
const int CMSfwDetectorProtection_MODE_TREECACHE = 2;
const int CMSfwDetectorProtection_MODE_USERFUNCTION = 3;
const int CMSfwDetectorProtection_MODE_DPNAMES = 4;
const int CMSfwDetectorProtection_MODE_DPALIASES = 5;

    
int CMSfwDetectorProtection_debugLevel = 2;

// System Numbers
const int CMSfwDetectorProtection_SYSNUM_FROM = 1;
const int CMSfwDetectorProtection_SYSNUM_TO = 512;



// Working memory
dyn_mixed CMSfwDetectorProtection_currentObject;

dyn_bool CMSfwDetectorProtection_dpeValues;
dyn_bool CMSfwDetectorProtection_dpeValueUpdated;
dyn_bool CMSfwDetectorProtection_toVerify;
dyn_bool CMSfwDetectorProtection_connected;
dyn_string CMSfwDetectorProtection_systems;
dyn_bool CMSfwDetectorProtection_systemConnected;
dyn_time CMSfwDetectorProtection_disconnectionTime;
dyn_string CMSfwDetectorProtection_connectedInputDps;
dyn_time CMSfwDetectorProtection_conditionChangedTime;
dyn_string CMSfwDetectorProtection_reconnectedSystems;
bool   CMSfwDetectorProtection_isConnecting = false; 
dyn_string CMSfwDetectorProtection_maskedDpes;
dyn_int CMSfwDetectorProtection_conditionsToRecompute; // because of changed masked dpes

int CMSfwDetectorProtection_verifySync = 0;

global bool CMSfwDetectorProtection_checkInvalid = true; 

global int CMSfwDetectorProtection_numLockedDpes = 0;



/** 
  @param object 
*/
void CMSfwDetectorProtection_initObject(dyn_mixed& object) {
  dyn_dyn_string dds;
  dyn_dyn_int ddi;
  
  object[CMSfwDetectorProtection_CONDITIONNAME] = makeDynString();
  object[CMSfwDetectorProtection_INPUTDPES] = makeDynString(); 
  object[CMSfwDetectorProtection_FIRED] = makeDynBool();
  object[CMSfwDetectorProtection_CHANGED] = makeDynBool();
  object[CMSfwDetectorProtection_OUTPUTMODE] = makeDynInt();
  object[CMSfwDetectorProtection_OUTPUTDPES] = dds;
  object[CMSfwDetectorProtection_TOPNODE] = makeDynString();
  object[CMSfwDetectorProtection_DUTYPE] = dds;
  object[CMSfwDetectorProtection_DPELEMENT] = dds;
  object[CMSfwDetectorProtection_TREECACHETOPNODE] = makeDynString();
  object[CMSfwDetectorProtection_USERFUNCTION] = makeDynString();
  object[CMSfwDetectorProtection_OUTPUTVALUE] = makeDynMixed();
  object[CMSfwDetectorProtection_OUTPUTVALUE_USERFUNCTION] = makeDynString();
  object[CMSfwDetectorProtection_CONDITIONACTIVE] = makeDynBool();
  object[CMSfwDetectorProtection_CONFIGDP] = CMSfwDetectorProtection_getConfigDpName("default");
  object[CMSfwDetectorProtection_ENABLEVERIFY] = makeDynBool();
  object[CMSfwDetectorProtection_VERIFY_DPES] = dds;
  object[CMSfwDetectorProtection_VERIFY_DPELEMENT]  = dds;
  object[CMSfwDetectorProtection_VERIFY_FUNCTION] = makeDynString();
  object[CMSfwDetectorProtection_VERIFY_DELAY] = makeDynInt();
  object[CMSfwDetectorProtection_VERIFY_FREQUENCY] = 60 ;
  object[CMSfwDetectorProtection_VERIFY_USERFUNCTION] = makeDynString();
  object[CMSfwDetectorProtection_DISCONNECTED_TIMEOUT] = makeDynInt();
  object[CMSfwDetectorProtection_DELAY] = makeDynInt();
  object[CMSfwDetectorProtection_OUTPUTVALUETYPE] = makeDynInt();
  object[CMSfwDetectorProtection_DEBUGLEVEL] = 2;
  object[CMSfwDetectorProtection_PREPOST_USERFUNCTION] = makeDynString();
  object[CMSfwDetectorProtection_CONDITIONTYPE] = makeDynString();
  object[CMSfwDetectorProtection_INFOFUNCTION] = makeDynString();
  object[CMSfwDetectorProtection_CUSTOMPROPERTIES] = makeDynString();
  object[CMSfwDetectorProtection_OUTDPES] = makeDynString();
  object[CMSfwDetectorProtection_OUTDPES_CONDITIONS] = ddi;
}
    


    
int CMSfwDetectorProtection_getConditionIndex(dyn_mixed& object,string name) {
  return dynContains( CMSfwDetectorProtection_conditionName(object), name);
}
    
void CMSfwDetectorProtection_addCondition(dyn_mixed& object,string name, dyn_string& exceptionInfo) {
  if (dynContains( CMSfwDetectorProtection_conditionName(object), name)) {
    fwException_raise(exceptionInfo, "ALREADY_PRESENT", name + " is already present in the list of the conditions",""); 
    return;
  }
  
  dynAppend(object[CMSfwDetectorProtection_CONDITIONNAME], name);
  int index = dynlen(object[CMSfwDetectorProtection_CONDITIONNAME]);      
  object[CMSfwDetectorProtection_INPUTDPES][index] = ""; 
  object[CMSfwDetectorProtection_CONDITIONACTIVE][index] = true;
  object[CMSfwDetectorProtection_ENABLEVERIFY][index] = false;
  object[CMSfwDetectorProtection_VERIFY_FUNCTION][index] = "";
  object[CMSfwDetectorProtection_VERIFY_DPES][index] = makeDynString();
  object[CMSfwDetectorProtection_VERIFY_DPELEMENT][index] = makeDynString();
  object[CMSfwDetectorProtection_DISCONNECTED_TIMEOUT][index] = -1; // timeout not active by default
  object[CMSfwDetectorProtection_DELAY][index] = 0; // delay not active by default
  object[CMSfwDetectorProtection_VERIFY_DELAY][index] =30;
  object[CMSfwDetectorProtection_VERIFY_USERFUNCTION][index] ="";
  object[CMSfwDetectorProtection_PREPOST_USERFUNCTION][index] = "";  
  object[CMSfwDetectorProtection_CONDITIONTYPE][index] = "generic";
  object[CMSfwDetectorProtection_CUSTOMPROPERTIES][index] = "";
  object[CMSfwDetectorProtection_INFOFUNCTION][index] = "";
}

void CMSfwDetectorProtection_deleteCondition(dyn_mixed& object, string name, dyn_string& exceptionInfo) {
  int index = CMSfwDetectorProtection_getConditionIndex(object,name);
  if (index == 0) {
    fwException_raise(exceptionInfo, "NOT_FOUND", name + " not found in the list of the conditions",""); 
    return;
  }  
  
  CMSfwDetectorProtection_deleteConditionByIndex(object, index, exceptionInfo);
  
}

void CMSfwDetectorProtection_deleteConditionByIndex(dyn_mixed& object, int index, dyn_string& exceptionInfo) {

  if ((index<1) || (index>dynlen(object[CMSfwDetectorProtection_INPUTDPES]))) {
    fwException_raise(exceptionInfo, "INDEX_OUT_OF_RANGE", "index " + index + " out of range in object while deleting by index",""); 
    return;
  }
  for (int i=1; i<= dynlen(object); i++) {
    if ((i == CMSfwDetectorProtection_VERIFY_FREQUENCY) || (i == CMSfwDetectorProtection_CONFIGDP) || (i == CMSfwDetectorProtection_DEBUGLEVEL)) continue;
    dynRemove(object[i], index); 
  }
  
}

string CMSfwDetectorProtection_getDefaultInputName(string dpe) {
  string name = dpSubStr(dpe,DPSUB_DP_EL);
  strreplace(name, "/","_");
  strreplace(name,".","_"); 
  return name;   
}

/** 
  @param name name of the input condition
  @param dpe the dp element to connect to
  @param function function to apply (returns true when condition is fired)
  @param exceptionInfo 
  @param description description of the condition
  @return input data point with element .status
*/
string CMSfwDetectorProtection_createInput( string name,string dpe,string function, dyn_string& exceptionInfo, string description = "") {
  string sys;

  fwGeneral_getSystemName(dpe,sys,exceptionInfo);

  if (! CMSfwDetectorProtection_hasRequiredPrivileges(sys) ) {
      fwException_raise(exceptionInfo, "INSUFFICIENT_PRIVILEGES", "Insufficient privileges on system " + sys,""); 
      return "";
  }
   
  if (! dpExists(dpe) ) {
    fwException_raise(exceptionInfo, "DPE_NOT_FOUND", dpe + " not found",""); 
    return ""; 
  }  
  
  if (name == "") {
    name = CMSfwDetectorProtection_getDefaultInputName(dpe); 
  }
  
  string dpname = sys+ "CMSfwDetectorProtection/Input/" + name;
  CMSfwDetectorProtection_createDp(dpname, CMSfwDetectorProtection_inputType, exceptionInfo);                        
  if (dynlen(exceptionInfo)>0) return "";
      
  dpe = dpSubStr(dpe, DPSUB_SYS_DP_EL) + ":_original.._value";
  
  // DebugN(dpname + ".status", dpe, function);
  
  fwDpFunction_setDpeConnection(dpname + ".status", makeDynString(dpe),makeDynString(),function, exceptionInfo);
  if (strrtrim(description," ") == "") {
    description = name;
    strreplace(description,"_"," ");      
  }
  dpSetDescription(dpname + ".status", description);  
  
  string replydp = CMSfwDetectorProtection_convertToReplyDp(dpname);  
  CMSfwDetectorProtection_createReply(replydp, exceptionInfo);
     
  return dpname + ".status";  
}

string CMSfwDetectorProtection_createReply(string replydp, dyn_string& exceptionInfo) {
  if (dpExists(replydp)) return replydp;
  
  CMSfwDetectorProtection_createDp(replydp, CMSfwDetectorProtection_replyType, exceptionInfo);
  if (dynlen(exceptionInfo)>0) return "";
  dyn_string dpes;
  for (int s=CMSfwDetectorProtection_SYSNUM_FROM; s<= CMSfwDetectorProtection_SYSNUM_TO; s++) {
    dynAppend(dpes, replydp + ".sys" + s +  ":_original.._exp_inv" );
  }
  CMSfwDetectorProtection_dpSetAll(dpes , true); 
  
  return replydp;
}

void CMSfwDetectorProtection_createMissingReplyDps(dyn_string& exceptionInfo,string systemName = "") {
    dyn_string inputdps = dpNames(systemName + "*", CMSfwDetectorProtection_inputType);
    string replydp;
    for (int i=1; i<= dynlen(inputdps); i++) {
      replydp = CMSfwDetectorProtection_convertToReplyDp(inputdps[i]);
      if (! dpExists(replydp) )   {        
        CMSfwDetectorProtection_createReply(replydp, exceptionInfo);
      }
    }
}

string CMSfwDetectorProtection_getInputDescription(string dpname) {
  dpname = dpSubStr(dpname , DPSUB_SYS_DP) + ".status";
  
  dyn_string exc;
  string description = dpGetDescription(dpname );
  if (description == dpname) {
    fwDevice_getName(dpSubStr(dpname , DPSUB_SYS_DP) ,description, exc);
    strreplace(description,"_"," ");
  }
  return description;
}

void CMSfwDetectorProtection_setDebugLevel(dyn_mixed& object, int debugLevel) {
  object[CMSfwDetectorProtection_DEBUGLEVEL] = debugLevel; 
}

void CMSfwDetectorProtection_setInput(dyn_mixed& object,string name, string dp, dyn_string& exceptionInfo) {
  int index = CMSfwDetectorProtection_getConditionIndex(object,name);
  if (index == 0) {
    fwException_raise(exceptionInfo, "NOT_FOUND", name + " not found in the list of the conditions",""); 
    return;
  }  
  if (dpExists(dp)) {
    if (dpTypeName(dp) != CMSfwDetectorProtection_inputType ) {
      fwException_raise(exceptionInfo, "WRONG_TYPE", dp + " not of type " + CMSfwDetectorProtection_inputType,"");
      return; 
    }
    dp = dpSubStr(dp, DPSUB_SYS_DP);
  } else {
  //  CMSfwDetectorProtection_debug3(dp + " does not exist. Setting anyway");    
  }
  
 
  object[CMSfwDetectorProtection_INPUTDPES][index] = dp + ".status";
}

// timeout in seconds. -1 means infinite
void CMSfwDetectorProtection_setTimeout(dyn_mixed& object, string name, int timeout, dyn_string& exceptionInfo) {
  int index = CMSfwDetectorProtection_getConditionIndex(object,name);
  if (index == 0) {
    fwException_raise(exceptionInfo, "NOT_FOUND", name + " not found in the list of the conditions",""); 
    return;
  } 
  object[CMSfwDetectorProtection_DISCONNECTED_TIMEOUT][index] = timeout;
}  

// delay in seconds before firing.
void CMSfwDetectorProtection_setDelay(dyn_mixed& object, string name, int delayTime, dyn_string& exceptionInfo) {
  int index = CMSfwDetectorProtection_getConditionIndex(object,name);
  if (index == 0) {
    fwException_raise(exceptionInfo, "NOT_FOUND", name + " not found in the list of the conditions",""); 
    return;
  } 
  object[CMSfwDetectorProtection_DELAY][index] = delayTime;
} 


// Set the function to be used in the user interface to get more info about the condition
void CMSfwDetectorProtection_setInfoFunction(dyn_mixed& object, string name, string funct, dyn_string& exceptionInfo) {
  int index = CMSfwDetectorProtection_getConditionIndex(object,name);
  if (index == 0) {
    fwException_raise(exceptionInfo, "NOT_FOUND", name + " not found in the list of the conditions",""); 
    return;
  } 
  object[CMSfwDetectorProtection_INFOFUNCTION][index] = funct;
} 
//Condition type. This may be useful to group different conditions of the same type during the analysis
void CMSfwDetectorProtection_setConditionType(dyn_mixed& object, string name, string type, dyn_string& exceptionInfo) {
  int index = CMSfwDetectorProtection_getConditionIndex(object,name);
  if (index == 0) {
    fwException_raise(exceptionInfo, "NOT_FOUND", name + " not found in the list of the conditions",""); 
    return;
  } 
  object[CMSfwDetectorProtection_CONDITIONTYPE][index] = type;
} 

void CMSfwDetectorProtection_getConditionCustomProperties(dyn_mixed& object, string name, dyn_string& properties, dyn_string& exceptionInfo) {
  int index = CMSfwDetectorProtection_getConditionIndex(object,name);
  if (index == 0) {
    fwException_raise(exceptionInfo, "NOT_FOUND", name + " not found in the list of the conditions",""); 
    return;
  } 
  string props;  

  if (dynlen(object[CMSfwDetectorProtection_CUSTOMPROPERTIES]) < index) {
      properties = makeDynString();
      return;
  }
  properties = CMSfwDetectorProtection_unflatten_dyn(object[CMSfwDetectorProtection_CUSTOMPROPERTIES][index]);
}

string CMSfwDetectorProtection_getPropertyValue(dyn_string properties, string key) {  
  dyn_string spl;
  for (int i=1; i<= dynlen(properties); i++) {
    spl = strsplit(properties[i],"=");
    if (dynlen(spl) != 2) continue;
    if (spl[1] == key) return spl[2];                   
  }
  return "";
}


void CMSfwDetectorProtection_setConditionCustomProperties(dyn_mixed& object, string name, dyn_string properties, dyn_string& exceptionInfo) {
  int index = CMSfwDetectorProtection_getConditionIndex(object,name);
  if (index == 0) {
    fwException_raise(exceptionInfo, "NOT_FOUND", name + " not found in the list of the conditions",""); 
    return;
  } 
  string props;  
  props = CMSfwDetectorProtection_flatten_dyn(properties);
  object[CMSfwDetectorProtection_CUSTOMPROPERTIES][index] = props;
}



int CMSfwDetectorProtection_getPureMode(int mode) {
  if (mode > 100) return mode-100;
  return mode; 
}

void CMSfwDetectorProtection_setOutputMode(dyn_mixed& object,string name, int mode, dyn_string& exceptionInfo) {
  int index = CMSfwDetectorProtection_getConditionIndex(object,name);
  if (index == 0) {
    fwException_raise(exceptionInfo, "NOT_FOUND", name + " not found in the list of the conditions",""); 
    return;
  }  
  
  int mode2 = CMSfwDetectorProtection_getPureMode(mode);
  if ((mode2 < CMSfwDetectorProtection_MODE_DPES) || (mode2 > CMSfwDetectorProtection_MODE_DPALIASES)) {
    fwException_raise(exceptionInfo, "INVALID_MODE", "Invalid mode",""); 
    return;
  }
  object[CMSfwDetectorProtection_OUTPUTMODE][index] = mode;  
}

void CMSfwDetectorProtection_setOutputModeDpes(dyn_mixed& object,string name, dyn_string dpes, string valueStr, int valueType, dyn_string& exceptionInfo) {
  CMSfwDetectorProtection_setOutputMode(object,name,  CMSfwDetectorProtection_MODE_DPES, exceptionInfo);
  if (dynlen(exceptionInfo)>0) return;
  int index = CMSfwDetectorProtection_getConditionIndex(object,name);
  
  CMSfwDetectorProtection_setOutputValue(object,index,valueStr,valueType,exceptionInfo);
    
  object[CMSfwDetectorProtection_OUTPUTDPES][index] = dpes;
   
  // Set to dummy for other modes
  object[CMSfwDetectorProtection_TOPNODE][index] = "";
  object[CMSfwDetectorProtection_DUTYPE][index] = "";
  object[CMSfwDetectorProtection_DPELEMENT][index] = "";
  object[CMSfwDetectorProtection_TREECACHETOPNODE][index] = "";
   
  object[CMSfwDetectorProtection_USERFUNCTION][index] = "";
}

void CMSfwDetectorProtection_setVerifyModeDpes(dyn_mixed& object,string name, dyn_string dpes,string function, int verifyDelay,dyn_string& exceptionInfo) {

  int index = CMSfwDetectorProtection_getConditionIndex(object,name);
  if (index == 0) {
    fwException_raise(exceptionInfo, "NOT_FOUND", name + " not found in the list of the conditions",""); 
    return;
  }  
      
  if   (CMSfwDetectorProtection_getPureMode(object[CMSfwDetectorProtection_OUTPUTMODE][index]) != CMSfwDetectorProtection_MODE_DPES) {
    fwException_raise(exceptionInfo, "WRONG_MODE", "The Output mode must be the same of the verify mode",""); 
    return;
  } 
   
  object[CMSfwDetectorProtection_ENABLEVERIFY][index] = true;
   
  object[CMSfwDetectorProtection_VERIFY_DPES][index] = dpes;
   
  // Set to dummy for other modes

  object[CMSfwDetectorProtection_VERIFY_DPELEMENT][index] = makeDynString();
  object[CMSfwDetectorProtection_VERIFY_USERFUNCTION][index] = "";
   
  object[CMSfwDetectorProtection_VERIFY_FUNCTION][index] = function;
  object[CMSfwDetectorProtection_VERIFY_DELAY][index] = verifyDelay;
}

void CMSfwDetectorProtection_setOutputModeTreeCache(dyn_mixed& object,string name, string topNode, string treeCacheTopNode, dyn_string duType, dyn_string dpElement, string valueStr, int valueType, bool preprocess, dyn_string& exceptionInfo) {
  CMSfwDetectorProtection_setOutputMode(object,name,  CMSfwDetectorProtection_MODE_TREECACHE + ((preprocess)?100:0), exceptionInfo);
  if (dynlen(exceptionInfo)>0) return;
  int index = CMSfwDetectorProtection_getConditionIndex(object,name);
  
  CMSfwDetectorProtection_setOutputValue(object,index,valueStr,valueType,exceptionInfo);
 
  object[CMSfwDetectorProtection_TOPNODE][index] = topNode;
  object[CMSfwDetectorProtection_DUTYPE][index]  = duType;
  object[CMSfwDetectorProtection_DPELEMENT][index] = dpElement;
  object[CMSfwDetectorProtection_TREECACHETOPNODE][index] = treeCacheTopNode;
     

   
  // Set to dummy for other modes
   
  object[CMSfwDetectorProtection_OUTPUTDPES][index] =makeDynString(); 
   
  object[CMSfwDetectorProtection_USERFUNCTION][index] = "";
}

void CMSfwDetectorProtection_setOutputModeDpNamesOrAliases(dyn_mixed& object,string name, int outputMode,string topNode,  dyn_string duType, dyn_string dpElement, string valueStr, int valueType, bool preprocess, dyn_string& exceptionInfo) {
  if ((outputMode !=  CMSfwDetectorProtection_MODE_DPNAMES) && (outputMode !=  CMSfwDetectorProtection_MODE_DPALIASES)) {
    fwException_raise(exceptionInfo, "WRONG_MODE", "The Output mode must be DP NAMES or DP ALIASES",""); 
    return;    
  }
  CMSfwDetectorProtection_setOutputMode(object,name,  outputMode + ((preprocess)?100:0), exceptionInfo);
  if (dynlen(exceptionInfo)>0) return;
  int index = CMSfwDetectorProtection_getConditionIndex(object,name);
  
  CMSfwDetectorProtection_setOutputValue(object,index,valueStr,valueType,exceptionInfo);
 
  object[CMSfwDetectorProtection_TOPNODE][index] = topNode;
  object[CMSfwDetectorProtection_DUTYPE][index]  = duType;
  object[CMSfwDetectorProtection_DPELEMENT][index] = dpElement;
  object[CMSfwDetectorProtection_TREECACHETOPNODE][index] = "";
     

   
  // Set to dummy for other modes
   
  object[CMSfwDetectorProtection_OUTPUTDPES][index] =makeDynString(); 
   
  object[CMSfwDetectorProtection_USERFUNCTION][index] = "";
}


/* this is valid also for modes DPNAMES and DPALIASES */      
void CMSfwDetectorProtection_setVerifyModeTreeCache(dyn_mixed& object,string name, dyn_string dpElement,string function, int verifyDelay,dyn_string& exceptionInfo) {

  int index = CMSfwDetectorProtection_getConditionIndex(object,name);
  if (index == 0) {
    fwException_raise(exceptionInfo, "NOT_FOUND", name + " not found in the list of the conditions",""); 
    return;
  }  
      
  dyn_int allowed_modes = makeDynInt(CMSfwDetectorProtection_MODE_TREECACHE,CMSfwDetectorProtection_MODE_DPALIASES, CMSfwDetectorProtection_MODE_DPNAMES);
  
  if   (! dynContains(allowed_modes, CMSfwDetectorProtection_getPureMode(object[CMSfwDetectorProtection_OUTPUTMODE][index]))) {
    fwException_raise(exceptionInfo, "WRONG_MODE", "The Output mode must be the same of the verify mode",""); 
    return;
  } 
   
  if (dynlen(dpElement) != dynlen(object[CMSfwDetectorProtection_DPELEMENT][index])) {
    fwException_raise(exceptionInfo, "WRONG_LENGTH", "The verify dp element must have the same length of the elements defined for the output action",""); 
    return;    
  }
  object[CMSfwDetectorProtection_ENABLEVERIFY][index] = true;
   
  object[CMSfwDetectorProtection_VERIFY_DPES][index] = makeDynString();
   
  // Set to dummy for other modes

  object[CMSfwDetectorProtection_VERIFY_DPELEMENT][index] = dpElement;
  object[CMSfwDetectorProtection_VERIFY_USERFUNCTION][index] = "";
       
  object[CMSfwDetectorProtection_VERIFY_FUNCTION][index] = function;
  object[CMSfwDetectorProtection_VERIFY_DELAY][index] = verifyDelay;
}


void CMSfwDetectorProtection_setOutputModeUserFunction(dyn_mixed& object,string name, string userFunction, string valueStr, int valueType, bool preprocess, dyn_string& exceptionInfo) {
  CMSfwDetectorProtection_setOutputMode(object,name,  CMSfwDetectorProtection_MODE_USERFUNCTION + + ((preprocess)?100:0), exceptionInfo);
  if (dynlen(exceptionInfo)>0) return;
  int index = CMSfwDetectorProtection_getConditionIndex(object,name);   
  CMSfwDetectorProtection_setOutputValue(object,index,valueStr,valueType,exceptionInfo);
     
  object[CMSfwDetectorProtection_USERFUNCTION][index]= userFunction;
  // DebugN("User function ", userFunction ,       object[CMSfwDetectorProtection_USERFUNCTION][index]);
   
  // Set to dummy for other modes
  object[CMSfwDetectorProtection_OUTPUTDPES][index] =makeDynString(); 
       
  object[CMSfwDetectorProtection_TOPNODE][index] = "";
  object[CMSfwDetectorProtection_DUTYPE][index] = "";
  object[CMSfwDetectorProtection_DPELEMENT][index] = "";
  object[CMSfwDetectorProtection_TREECACHETOPNODE][index] = "";
}

void CMSfwDetectorProtection_setOutputValue(dyn_mixed& object, int index, string valueStr, int valueType, dyn_string& exceptionInfo) {
  anytype value;
  _fwConfigurationDB_stringToData(valueStr, valueType, "|",value,exceptionInfo);
   
  object[CMSfwDetectorProtection_OUTPUTVALUE][index] = value;  
  object[CMSfwDetectorProtection_OUTPUTVALUE_USERFUNCTION][index] = ""; 
  object[CMSfwDetectorProtection_OUTPUTVALUETYPE][index] = valueType;   
 
}

void CMSfwDetectorProtection_setOutputValueUserFunction(dyn_mixed& object, string  name, string function, dyn_string& exceptionInfo) {  
  int index = CMSfwDetectorProtection_getConditionIndex(object,name);
  if (index == 0) {
    fwException_raise(exceptionInfo, "NOT_FOUND", name + " not found in the list of the conditions",""); 
    return;
  }  
  
  object[CMSfwDetectorProtection_OUTPUTVALUE][index] = "";  
  object[CMSfwDetectorProtection_OUTPUTVALUE_USERFUNCTION][index] = function; 
}


void CMSfwDetectorProtection_setPrePostUserFunction(dyn_mixed& object, string name, string function, dyn_string& exceptionInfo) {
  int index = CMSfwDetectorProtection_getConditionIndex(object,name);
  if (index == 0) {
    fwException_raise(exceptionInfo, "NOT_FOUND", name + " not found in the list of the conditions",""); 
    return;
  }
  object[CMSfwDetectorProtection_PREPOST_USERFUNCTION][index] = function;
}

void CMSfwDetectorProtection_setVerifyModeUserFunction(dyn_mixed& object,string name, string function, int verifyDelay,dyn_string& exceptionInfo) {

  int index = CMSfwDetectorProtection_getConditionIndex(object,name);
  if (index == 0) {
    fwException_raise(exceptionInfo, "NOT_FOUND", name + " not found in the list of the conditions",""); 
    return;
  }  
      
  if   (CMSfwDetectorProtection_getPureMode(object[CMSfwDetectorProtection_OUTPUTMODE][index]) != CMSfwDetectorProtection_MODE_USERFUNCTION) {
    fwException_raise(exceptionInfo, "WRONG_MODE", "The Output mode must be the same of the verify mode",""); 
    return;
  } 
  object[CMSfwDetectorProtection_ENABLEVERIFY][index] = true;
   
  object[CMSfwDetectorProtection_VERIFY_DPES][index] = makeDynString();
   
  object[CMSfwDetectorProtection_VERIFY_DPELEMENT][index] = makeDynString();
   
  object[CMSfwDetectorProtection_VERIFY_FUNCTION][index] = function;
  object[CMSfwDetectorProtection_VERIFY_DELAY][index] = verifyDelay;
  object[CMSfwDetectorProtection_VERIFY_USERFUNCTION][index] = "";
}

void CMSfwDetectorProtection_setVerifyCustomVerifyFunction(dyn_mixed& object,string name, string verifyFunction, int verifyDelay,dyn_string& exceptionInfo) {
  int index = CMSfwDetectorProtection_getConditionIndex(object,name);
  if (index == 0) {
    fwException_raise(exceptionInfo, "NOT_FOUND", name + " not found in the list of the conditions",""); 
    return;
  }  
   
  object[CMSfwDetectorProtection_ENABLEVERIFY][index] = true;
   
  object[CMSfwDetectorProtection_VERIFY_DPES][index] = makeDynString();
   
  object[CMSfwDetectorProtection_VERIFY_DPELEMENT][index] = makeDynString();
   
  object[CMSfwDetectorProtection_VERIFY_FUNCTION][index] = "";
  object[CMSfwDetectorProtection_VERIFY_DELAY][index] = verifyDelay;
  object[CMSfwDetectorProtection_VERIFY_USERFUNCTION][index] = verifyFunction;   
}

void CMSfwDetectorProtection_setVerifyFrequency(dyn_mixed& object, int frequency) {
  if (frequency < 30) {
    DebugN("Cannot use a verify frequency lower than 30"); 
    frequency = 30; 
  } 
  object[CMSfwDetectorProtection_VERIFY_FREQUENCY] = frequency;
  
}

void CMSfwDetectorProtection_setVerifyDisabled(dyn_mixed& object, string name, dyn_string& exceptionInfo) {
  int index = CMSfwDetectorProtection_getConditionIndex(object,name);
  if (index == 0) {
    fwException_raise(exceptionInfo, "NOT_FOUND", name + " not found in the list of the conditions",""); 
    return;
  }  
   
  object[CMSfwDetectorProtection_ENABLEVERIFY][index] = false;
   
  object[CMSfwDetectorProtection_VERIFY_DPES][index] = makeDynString();
   
  object[CMSfwDetectorProtection_VERIFY_DPELEMENT][index] = makeDynString();
   
  object[CMSfwDetectorProtection_VERIFY_FUNCTION][index] = "";
  object[CMSfwDetectorProtection_VERIFY_DELAY][index] = 30;
  object[CMSfwDetectorProtection_VERIFY_USERFUNCTION][index] = "";   
   
}

void CMSfwDetectorProtection_setActive(dyn_mixed& object, string name, bool active, dyn_string& exceptionInfo) {
  int index = CMSfwDetectorProtection_getConditionIndex(object,name);   
  if (index == 0) {
    fwException_raise(exceptionInfo, "NOT_FOUND", name + " not found in the list of the conditions",""); 
    return;
  }  
  object[CMSfwDetectorProtection_CONDITIONACTIVE][index] = active;   
}

void CMSfwDetectorProtection_setConfigDp(dyn_mixed& object, string dpname) {
  object[CMSfwDetectorProtection_CONFIGDP] = dpname;   
}

string CMSfwDetectorProtection_getConfigDpName(string configName, string sys = "") {
  if (strlen(sys)== 0) sys = getSystemName();
  return strrtrim(sys,":") + ":CMSfwDetectorProtection/Configuration/" + configName;
}


dyn_string CMSfwDetectorProtection_flatten_dyndyn(dyn_dyn_string array) {
  dyn_string res;
  for ( int i = dynlen(array) ; i ; i -- ) {
    res[i] = CMSfwDetectorProtection_flatten_dyn(array[i]);
  }
  return res;
}

dyn_dyn_string CMSfwDetectorProtection_unflatten_dyndyn(dyn_string flattened) {
  dyn_dyn_string res;
  for ( int i = dynlen(flattened) ; i ; i -- ) {
    res[i] = CMSfwDetectorProtection_unflatten_dyn(flattened[i]);
  }
  return res;
}

// converts an array to a string using a defined delimiter
// that should not occur within the original data :-)
string CMSfwDetectorProtection_flatten_dyn(dyn_string array,string delimiter="\t") {
  string flattened;
  for ( int k = 1 ; k <= dynlen(array) ; k ++ ) {
    if ( k > 1 ) {
      flattened += delimiter;
    }
    flattened += array[k];
  }
  return flattened;
}

dyn_string CMSfwDetectorProtection_unflatten_dyn(string flattened,string delimiter="\t") {
  dyn_string unflattened = strsplit(flattened,delimiter);
  /* 
     It is a documented "feature" of the function strsplit, that the resulting
     array will contain only the same number of elements than the number of
     delimiters, if the last character in the input string is the delimiter!
     This is unwanted in our case and has to be treated manually:
  */
  if ( substr(flattened,strlen(flattened)-1) == delimiter ) {
    dynAppend(unflattened,"");
  }
  return unflattened;
}


string CMSfwDetectorProtection_createDp(string dp,string dpType,dyn_string& exceptionInfo) {
  dp = strrtrim(dp,".");
  string system;
  dyn_string parts = strsplit(dp,":");
  if ( dynlen(parts) == 1 ) {
    system = getSystemName();
  }
  else {
    system = parts[1];
    dp = parts[2];
  }
  
  system = strrtrim(system,":")+":";
  string longdp = system + dp;
  if ( !dpExists(longdp) ) {
    dpCreate(dp,dpType,getSystemId(system));
    if ( dynlen(getLastError()) ) {
      fwException_raise(exceptionInfo, "UNABLE_TO_CREATE_DP", "Unable to create dp " + dp + " on system " + system,""); 
      return "";
    }
  }
  return longdp;
}


void CMSfwDetectorProtection_saveToDp(dyn_mixed& object, dyn_string& exceptionInfo, bool active = true) {
  string dp = object[CMSfwDetectorProtection_CONFIGDP];
  if (! dpExists(dp) ) {
    dp = CMSfwDetectorProtection_createDp(dp, CMSfwDetectorProtection_configType, exceptionInfo);
    if (dynlen(exceptionInfo) ) return ;     
  } 

  string sys;
  fwGeneral_getSystemName(dp, sys,exceptionInfo);

  if (! CMSfwDetectorProtection_hasRequiredPrivileges(sys) ) {
      fwException_raise(exceptionInfo, "INSUFFICIENT_PRIVILEGES", "Insufficient privileges on system " + sys,""); 
      return ;
  }
   
  dyn_string valueString;
  
  for (int i=1; i<= dynlen(object[CMSfwDetectorProtection_OUTPUTVALUE]); i++) {
    _fwConfigurationDB_dataToString( object[CMSfwDetectorProtection_OUTPUTVALUE][i], object[CMSfwDetectorProtection_OUTPUTVALUETYPE][i],"|",valueString[i],exceptionInfo);
  }
  dpSet(dp + ".conditions.list.name", object[CMSfwDetectorProtection_CONDITIONNAME],
	dp + ".conditions.list.active", object[CMSfwDetectorProtection_CONDITIONACTIVE],
        dp + ".conditions.list.type", object[CMSfwDetectorProtection_CONDITIONTYPE],
	dp + ".conditions.input.dpes", object[CMSfwDetectorProtection_INPUTDPES],
	dp + ".conditions.input.delay", object[CMSfwDetectorProtection_DELAY],
	dp + ".conditions.list.customProperties", object[CMSfwDetectorProtection_CUSTOMPROPERTIES],
        
	dp + ".conditions.output.mode",object[CMSfwDetectorProtection_OUTPUTMODE],
	dp + ".conditions.output.mode_dpes.dpes",CMSfwDetectorProtection_flatten_dyndyn(object[CMSfwDetectorProtection_OUTPUTDPES]),
	dp + ".conditions.output.mode_treeCache.topNode",object[CMSfwDetectorProtection_TOPNODE],
	dp + ".conditions.output.mode_treeCache.duType",CMSfwDetectorProtection_flatten_dyndyn(object[CMSfwDetectorProtection_DUTYPE]),
	dp + ".conditions.output.mode_treeCache.dpElement",CMSfwDetectorProtection_flatten_dyndyn(object[CMSfwDetectorProtection_DPELEMENT]),
	dp + ".conditions.output.mode_treeCache.treeCacheTopNode", object[CMSfwDetectorProtection_TREECACHETOPNODE],
	dp + ".conditions.output.mode_userFunction.userFunction",object[CMSfwDetectorProtection_USERFUNCTION],
	dp + ".conditions.output.setting.value",valueString ,
      	dp + ".conditions.output.setting.valueType",object[CMSfwDetectorProtection_OUTPUTVALUETYPE] ,
        dp + ".conditions.output.setting.userFunction",object[CMSfwDetectorProtection_OUTPUTVALUE_USERFUNCTION]  ,
	dp + ".conditions.verify.enabled",object[CMSfwDetectorProtection_ENABLEVERIFY],
	dp + ".conditions.verify.mode_dpes.dpes",CMSfwDetectorProtection_flatten_dyndyn(object[CMSfwDetectorProtection_VERIFY_DPES]),
	dp + ".conditions.verify.mode_treeCache.dpElement",CMSfwDetectorProtection_flatten_dyndyn(object[CMSfwDetectorProtection_VERIFY_DPELEMENT]),
	dp + ".conditions.verify.function",(object[CMSfwDetectorProtection_VERIFY_FUNCTION]),
	dp + ".conditions.verify.delay",(object[CMSfwDetectorProtection_VERIFY_DELAY]),
	dp + ".conditions.verify.verifyUserFunction", object[CMSfwDetectorProtection_VERIFY_USERFUNCTION],
	dp + ".conditions.verify.frequency",(object[CMSfwDetectorProtection_VERIFY_FREQUENCY]),
        dp + ".conditions.disconnection.timeout",object[CMSfwDetectorProtection_DISCONNECTED_TIMEOUT],
        dp + ".conditions.userCallback.prePost", object[CMSfwDetectorProtection_PREPOST_USERFUNCTION],
        dp + ".conditions.userCallback.infoFunction", object[CMSfwDetectorProtection_INFOFUNCTION],
        dp + ".config.debugLevel",object[CMSfwDetectorProtection_DEBUGLEVEL],
	dp + ".config.active", active,
	dp + ".config.updated", getCurrentTime());            
}


void CMSfwDetectorProtection_loadFromDp(dyn_mixed& object, string dp, dyn_string& exceptionInfo, bool convertComponents= true) {
  if (! dpExists(dp) ) {
    fwException_raise(exceptionInfo, "DP_NOT_FOUND", "Dp not found " + dp,""); 
    return ;
  } 
  dp  = dpSubStr(dp,DPSUB_SYS_DP); 
   
  dynClear(object);
  CMSfwDetectorProtection_initObject(object);
  CMSfwDetectorProtection_setConfigDp(object,dp);
   
  dyn_string tmp1,tmp2,tmp3,tmp4,tmp5,tmp6;
   
  
  dyn_string valueString;
  dpGet(dp + ".conditions.list.name", object[CMSfwDetectorProtection_CONDITIONNAME],
      	dp + ".conditions.list.active", object[CMSfwDetectorProtection_CONDITIONACTIVE],
        dp + ".conditions.list.type", object[CMSfwDetectorProtection_CONDITIONTYPE],
        dp + ".conditions.list.customProperties", object[CMSfwDetectorProtection_CUSTOMPROPERTIES],
       	dp + ".conditions.input.dpes",    object[CMSfwDetectorProtection_INPUTDPES],
        dp + ".conditions.input.delay", object[CMSfwDetectorProtection_DELAY],
	dp + ".conditions.output.mode",object[CMSfwDetectorProtection_OUTPUTMODE],
	dp + ".conditions.output.mode_dpes.dpes",tmp2,
	dp + ".conditions.output.mode_treeCache.topNode",object[CMSfwDetectorProtection_TOPNODE],
	dp + ".conditions.output.mode_treeCache.duType",tmp3,
	dp + ".conditions.output.mode_treeCache.dpElement",tmp4,
	dp + ".conditions.output.mode_treeCache.treeCacheTopNode", object[CMSfwDetectorProtection_TREECACHETOPNODE],
	dp + ".conditions.output.mode_userFunction.userFunction",object[CMSfwDetectorProtection_USERFUNCTION],       
	dp + ".conditions.output.setting.value",valueString,
        dp + ".conditions.output.setting.valueType",object[CMSfwDetectorProtection_OUTPUTVALUETYPE],
        dp + ".conditions.output.setting.userFunction",object[CMSfwDetectorProtection_OUTPUTVALUE_USERFUNCTION]  ,
	dp + ".conditions.verify.enabled",object[CMSfwDetectorProtection_ENABLEVERIFY],
	dp + ".conditions.verify.mode_dpes.dpes",tmp5,
	dp + ".conditions.verify.mode_treeCache.dpElement",tmp6,
	dp + ".conditions.verify.function",(object[CMSfwDetectorProtection_VERIFY_FUNCTION]),    
	dp + ".conditions.verify.delay",(object[CMSfwDetectorProtection_VERIFY_DELAY]),
	dp + ".conditions.verify.verifyUserFunction", object[CMSfwDetectorProtection_VERIFY_USERFUNCTION],
	dp + ".conditions.verify.frequency",(object[CMSfwDetectorProtection_VERIFY_FREQUENCY]),
        dp + ".conditions.disconnection.timeout",object[CMSfwDetectorProtection_DISCONNECTED_TIMEOUT],
        dp + ".conditions.userCallback.prePost", object[CMSfwDetectorProtection_PREPOST_USERFUNCTION],
	dp + ".conditions.userCallback.infoFunction", object[CMSfwDetectorProtection_INFOFUNCTION],
        dp + ".config.debugLevel", object[CMSfwDetectorProtection_DEBUGLEVEL]);
   
  dynClear(object[CMSfwDetectorProtection_OUTPUTVALUE]);
  
  for (int i=1; i<= dynlen(valueString); i++) {
    _fwConfigurationDB_stringToData(valueString[i],object[CMSfwDetectorProtection_OUTPUTVALUETYPE][i],"|",object[CMSfwDetectorProtection_OUTPUTVALUE][i], exceptionInfo);
  } 
  
  
  if (convertComponents) {
  // convert component names in the inputs
    for (int i=1; i<= dynlen(object[CMSfwDetectorProtection_INPUTDPES]); i++) {
      object[CMSfwDetectorProtection_INPUTDPES][i] = CMSfwDetectorProtection_replaceComponentsWithSystem(object[CMSfwDetectorProtection_INPUTDPES][i]);
    }
  }
  
  //// START OF CHECKS FOR CONVERTING FROM PREVIOUS VERSIONS OF THE DP TYPE
  
  if ((dynlen(object[CMSfwDetectorProtection_OUTPUTVALUE_USERFUNCTION]) == 0) && (dynlen(object[CMSfwDetectorProtection_OUTPUTVALUE])>0)) {
    for (int i=1; i<= dynlen(object[CMSfwDetectorProtection_OUTPUTVALUE]); i++) {
      object[CMSfwDetectorProtection_OUTPUTVALUE_USERFUNCTION][i] = ""; 
    }
    // if it was saved in a previous version, update to the right length
    CMSfwDetectorProtection_debug2("Updating dp " + dp  + ".conditions.output.setting.userFunction" );
    dpSet(dp + ".conditions.output.setting.userFunction",object[CMSfwDetectorProtection_OUTPUTVALUE_USERFUNCTION]);
  }

    
  if ((dynlen(object[CMSfwDetectorProtection_PREPOST_USERFUNCTION]) == 0) && (dynlen(object[CMSfwDetectorProtection_CONDITIONNAME])>0)) {
    for (int i=1; i<= dynlen(object[CMSfwDetectorProtection_CONDITIONNAME]); i++) {
      object[CMSfwDetectorProtection_PREPOST_USERFUNCTION][i] = ""; 
    }
    // if it was saved in a previous version, update to the right length
    CMSfwDetectorProtection_debug2("Updating dp " + dp   + ".conditions.userCallback.prePost");
    dpSet( dp + ".conditions.userCallback.prePost", object[CMSfwDetectorProtection_PREPOST_USERFUNCTION]);
  }
  
  if ((dynlen(object[CMSfwDetectorProtection_INFOFUNCTION]) == 0) && (dynlen(object[CMSfwDetectorProtection_CONDITIONNAME])>0)) {
    for (int i=1; i<= dynlen(object[CMSfwDetectorProtection_CONDITIONNAME]); i++) {
      object[CMSfwDetectorProtection_INFOFUNCTION][i] = ""; 
    }
    // if it was saved in a previous version, update to the right length
    CMSfwDetectorProtection_debug2("Updating dp " + dp   + ".conditions.userCallback.infoFunction");
    dpSet( dp + ".conditions.userCallback.infoFunction", object[CMSfwDetectorProtection_INFOFUNCTION]);
  }
    
  if ((dynlen(object[CMSfwDetectorProtection_DELAY]) == 0) && (dynlen(object[CMSfwDetectorProtection_INPUTDPES])>0)) {
    for (int i=1; i<= dynlen(object[CMSfwDetectorProtection_INPUTDPES]); i++) {
      object[CMSfwDetectorProtection_DELAY][i] = 0;
    }
    // if it was saved in a previous version, update to the right length
    CMSfwDetectorProtection_debug2("Updating dp " + dp + ".conditions.input.delay");
    dpSet(  dp + ".conditions.input.delay", object[CMSfwDetectorProtection_DELAY]);
  }
  
  if ((dynlen(object[CMSfwDetectorProtection_CONDITIONTYPE]) == 0) && (dynlen(object[CMSfwDetectorProtection_CONDITIONNAME])>0)) {
    for (int i=1; i<= dynlen(object[CMSfwDetectorProtection_CONDITIONNAME]); i++) {
      object[CMSfwDetectorProtection_CONDITIONTYPE][i] = "generic"; 
    }
    // if it was saved in a previous version, update to the right length
    CMSfwDetectorProtection_debug2("Updating dp " + dp   + ".conditions.list.type");
    dpSet( dp +  ".conditions.list.type", object[CMSfwDetectorProtection_CONDITIONTYPE]);
  }

  
  if ((dynlen(object[CMSfwDetectorProtection_CUSTOMPROPERTIES])) < dynlen(object[CMSfwDetectorProtection_CONDITIONNAME])) {
    for (int i=dynlen(object[CMSfwDetectorProtection_CUSTOMPROPERTIES] )+1; i<= dynlen(object[CMSfwDetectorProtection_CONDITIONNAME]); i++) {
      object[CMSfwDetectorProtection_CUSTOMPROPERTIES][i] = ""; 
    }
    // if it was saved in a previous version, update to the right length
    CMSfwDetectorProtection_debug2("Updating dp " + dp   + ".conditions.list.customProperties");
    dpSet( dp +  ".conditions.list.customProperties", object[CMSfwDetectorProtection_CUSTOMPROPERTIES]);
  }
  
  
  if (dynlen(object[CMSfwDetectorProtection_VERIFY_USERFUNCTION]) < dynlen(object[CMSfwDetectorProtection_CONDITIONNAME])) {
    for (int i=dynlen(object[CMSfwDetectorProtection_VERIFY_USERFUNCTION] )+1; i<= dynlen(object[CMSfwDetectorProtection_CONDITIONNAME]); i++) {
      object[CMSfwDetectorProtection_VERIFY_USERFUNCTION][i] = ""; 
    }
    CMSfwDetectorProtection_debug2("Updating dp " + dp   + ".conditions.verify.verifyUserFunction");
    dpSet( dp + ".conditions.verify.verifyUserFunction", object[CMSfwDetectorProtection_VERIFY_USERFUNCTION]);
  }
  
  //// END OF CHECKS FOR CONVERTING FROM PREVIOUS VERSIONS OF THE DP TYPE
    
  object[CMSfwDetectorProtection_OUTPUTDPES] = CMSfwDetectorProtection_unflatten_dyndyn(tmp2) ;       
  object[CMSfwDetectorProtection_DUTYPE]= CMSfwDetectorProtection_unflatten_dyndyn(tmp3) ;       
  object[CMSfwDetectorProtection_DPELEMENT] = CMSfwDetectorProtection_unflatten_dyndyn(tmp4) ;     
  object[CMSfwDetectorProtection_VERIFY_DPES]= CMSfwDetectorProtection_unflatten_dyndyn(tmp5) ;     
  object[CMSfwDetectorProtection_VERIFY_DPELEMENT]= CMSfwDetectorProtection_unflatten_dyndyn(tmp6) ;            
}

bool CMSfwDetectorProtection_loadLocalConfiguration(dyn_mixed& object, dyn_string& exceptionInfo, string systemName = "", bool convertComponents = true) {
  dyn_string dps = dpNames(systemName + "*", CMSfwDetectorProtection_configType);
  if (dynlen(dps) == 0) {
    fwException_raise(exceptionInfo, "NO_DP_FOUND", "No config dp found in system",""); 
    return false;
  }
  int index = 1;

  for (int i=1; i<= dynlen(dps); i++) {
    dps[i] = dps[i] + ".config.active"; 
  } 
  dyn_bool active;
  dpGet(dps,active);
    

  bool first = true; dyn_mixed obj2;
  for (int i=1; i<= dynlen(dps); i++) {
    if (active[i]) {
      if (first) {
        CMSfwDetectorProtection_loadFromDp(object, dps[i], exceptionInfo, convertComponents);            
        first = false;
      } else {
        CMSfwDetectorProtection_loadFromDp(obj2, dps[i], exceptionInfo, convertComponents);            
        object = CMSfwDetectorProtection_merge(object, obj2, exceptionInfo);
      }
    }
  }
  if (first) {
    // fwException_raise(exceptionInfo,"NO_ACTIVE_DP_FOUND", "No Active configuration dp found in system",""); 
    CMSfwDetectorProtection_debug2( "No Active configuration dp found in local system");
    CMSfwDetectorProtection_initObject(object);
    return false;
  }  
  return true;
}

void CMSfwDetectorProtection_setActiveDp(string dp, bool active, dyn_string& exceptionInfo) {
  if (! dpExists(dp) ) {
    fwException_raise(exceptionInfo, "DP_NOT_FOUND", "Dp not found " + dp,""); 
    return ;
  } 
  dpSet(dps[i] + ".config.active", active);   

}

dyn_mixed CMSfwDetectorProtection_merge(dyn_mixed obj1, dyn_mixed obj2, dyn_string& exceptionInfo) {
  
  dyn_mixed res  = obj1;
  
  for (int i=1; i<= dynlen(obj1); i++) {
    if ((i == CMSfwDetectorProtection_CONFIGDP)) continue;
    if ((i == CMSfwDetectorProtection_VERIFY_FREQUENCY)) {
      res[i] = dynMin(makeDynInt(obj1[i],obj2[i]));
      continue; 
    }
    if (i==CMSfwDetectorProtection_DEBUGLEVEL) {
      res[i] = dynMax(makeDynInt(obj1[i],obj2[i])); 
      continue;
    }
    dynAppend(res[i],obj2[i]); 
  } 
  
  /*  

  // I think this check might be skipped 
  
  dyn_string names = res[CMSfwDetectorProtection_CONDITIONNAME];
  dynUnique(names);
  if (dynlen(names) != dynlen(res[CMSfwDetectorProtection_CONDITIONNAME])) {
  fwException_raise(exceptionInfo,"DUPLICATE_NAME","Duplicate name in conditions to merge","");
  return obj1; 
  }
  */

  return res;  
}




/** CORE FUNCTIONS **/


void CMSfwDetectorProtection_setDebug(int debugLevel) {
  CMSfwDetectorProtection_debugLevel = debugLevel;
  CMSfwDetectorProtection_debug3("new debug level is "+debugLevel);
}

void CMSfwDetectorProtection_debug(string msg,int debugLevel, string managerDp = CMSfwDetectorProtection_managerDp) {
  if ( CMSfwDetectorProtection_debugLevel >= debugLevel ) {
    DebugTN("CMSfwDetectorProtection: "+msg);
  }
  if ((debugLevel == 1) && (myManType() == CTRL_MAN)) {     
    dyn_string logString;
    dpGet(managerDp + ".log", logString); 
    if (dynlen(logString)>100) {
      dynRemove(logString,1); 
    }
    dynAppend(logString, ((string) getCurrentTime()) + ": " + msg);
    dpSet(managerDp + ".log", logString); 
  }
}


void CMSfwDetectorProtection_debug1(string msg) { CMSfwDetectorProtection_debug(msg,1); } // most important msgs
void CMSfwDetectorProtection_debug2(string msg) { CMSfwDetectorProtection_debug(msg,2); }
void CMSfwDetectorProtection_debug3(string msg) { CMSfwDetectorProtection_debug(msg,3); }
void CMSfwDetectorProtection_debug4(string msg) { CMSfwDetectorProtection_debug(msg,4); } // most detailed/expert msgs


void CMSfwDetectorProtection_appendArray(dyn_string& a1, dyn_string& a2) {
  for (int i=1; i<= dynlen(a2); i++)
    dynAppend(a1, a2[i]); 
}

anytype CMSfwDetectorProtection_getOutputValue(dyn_mixed& object, int index, dyn_bool& cache) {
  
  if (  object[CMSfwDetectorProtection_OUTPUTVALUE_USERFUNCTION][index] == "" ) {
    return  object[CMSfwDetectorProtection_OUTPUTVALUE][index];
  }
  if (dynlen(cache)>= index) {
    if (cache[index]) {
      anytype value =  object[CMSfwDetectorProtection_OUTPUTVALUE][index];    
      return value;
    }  
  }
  

  anytype value;
   
  int res = evalScript(value,   object[CMSfwDetectorProtection_OUTPUTVALUE_USERFUNCTION][index], makeDynString());
  if (res == -1) {
    CMSfwDetectorProtection_debug1("ERROR IN USER FUNCTION TO GET THE OUTPUT VALUE " +  object[CMSfwDetectorProtection_OUTPUTVALUE_USERFUNCTION][index]);
    return 0; 
  }
  CMSfwDetectorProtection_debug4("Output value for condition " + index + " from userFunction = " + value);

  if (dynlen(cache)>= index) {
    object[CMSfwDetectorProtection_OUTPUTVALUE][index] = value; // cache the value here
    cache[index] = true;
  }
  return value;
}

void CMSfwDetectorProtection_connect(dyn_mixed& object, dyn_string& exceptionInfo) {
  dyn_string exc;
  bool connectToAllSystems = false;
   
  string remotesys;  
  CMSfwDetectorProtection_isConnecting = true;
  // it is very important to fill the 2 arrays before calling the connection. 
  // This way if the same dpe is used in more than one condition, 
  // the first connection can already update the others
  for (int i=1; i<= dynlen(object[CMSfwDetectorProtection_CONDITIONNAME]); i++) {
    CMSfwDetectorProtection_connected[i] = false;
    CMSfwDetectorProtection_dpeValues[i] = false;
  }
  for (int i=1; i<= dynlen(object[CMSfwDetectorProtection_CONDITIONNAME]); i++) {
    remotesys = CMSfwDetectorProtection_getInputSystem(object,i);

    if (remotesys == "") {
        // a Component was specified but the system is not connected
        CMSfwDetectorProtection_debug4("System cannot be resolved for " + object[CMSfwDetectorProtection_INPUTDPES][i]);
        connectToAllSystems = true;
        continue;      
    }
    if (! CMSfwDetectorProtection_isSystemConnected(remotesys) ) {
      continue;
    }
    CMSfwDetectorProtection_connectCondition(object,i, exceptionInfo);
  }
  CMSfwDetectorProtection_isConnecting = false;  
  
  for (int i=1; i<= dynlen(object[CMSfwDetectorProtection_CONDITIONNAME]); i++) {
    if (! object[CMSfwDetectorProtection_CONDITIONACTIVE][i] ) {
      continue;
    }
    remotesys = CMSfwDetectorProtection_getInputSystem(object,i);
    CMSfwDetectorProtection_addSystem(remotesys);
  }

  CMSfwDetectorProtection_connectToSystems();
  /*
  if (connectToAllSystems) {
      dyn_string unDists = dpNames( "_unDistributedControl_*", "_UnDistributedControl");
      string sys;
      CMSfwDetectorProtection_debug4("Connecting to all " + dynlen(unDists) + " unDist dps");
      for (int i=1; i<= dynlen(unDists); i++) {
        sys = dpSubStr(unDists[i], DPSUB_DP);
        
        strreplace(sys,"_unDistributedControl_","");
        CMSfwDetectorProtection_connectSystem(sys);
      }
  }
  */
   
    
}

void CMSfwDetectorProtection_connectToSystems() {
  string post = ""; 
  int reduNum = myReduHostNum();
   if(reduNum == 2){  
     post = "_2";
   }
  int iRes = dpConnect("CMSfwDetectorProtection_connectToSystemsCallback", "_Connections" + post + ".Dist.ManNums", "_DistManager" + post + ".State.SystemNums");
	if(iRes == -1) {
		CMSfwDetectorProtection_debug1( "the Dist DP is not existing");
	}
}

void CMSfwDetectorProtection_connectToSystemsCallback(string sConn, dyn_int localSystemIds, string sDistConnectionDp, dyn_int remoteSystemIds) {
  bool connected;
  string sysName;
  dyn_string exc;
  int index;

  dyn_string remote = dpNames("*:_Event.ReadLicense", "_Event");

  dyn_string systems;
  

  for (int i=1; i<= dynlen(remote); i++) {
     fwGeneral_getSystemName(remote[i], sysName, exc);
     sysName = strrtrim(sysName, ":");    
     dynAppend(systems, sysName);
      
  }  
  CMSfwDetectorProtection_appendArray(systems, CMSfwDetectorProtection_systems);
  dynUnique(systems);

  
  bool all_disconnected;
  	if(dynlen(localSystemIds) < 1) {
  // local PVSS00dist not connected  
      all_disconnected = true;
    }

  string localSys = strrtrim(getSystemName(), ":");
    
  for (int i=1; i<= dynlen(systems); i++) {
    sysName = systems[i];

    if (sysName == localSys) connected= true;
    else if (all_disconnected) connected = false;    
    else connected =    CMSfwDetectorProtection_isSystemConnected(sysName);   

    
    //DebugN("Searching in " , CMSfwDetectorProtection_systems);
    
    index = dynContains(CMSfwDetectorProtection_systems,sysName);
    if ((index == 0) || (connected != CMSfwDetectorProtection_systemConnected[index])) {
     /* if (index> 0) {
          DebugTN(sysName + CMSfwDetectorProtection_systemConnected[index] + "-> " + connected);
      } else {
        DebugTN(sysName + " ? -> " + connected);            
      }
      */
      CMSfwDetectorProtection_systemConnectionChanged(sysName, connected, true);
    }
  }
 
}


void CMSfwDetectorProtection_connectCondition(dyn_mixed& object, int i, dyn_string& exceptionInfo) {
  if (! object[CMSfwDetectorProtection_CONDITIONACTIVE][i] ) {
    return;
  }
  string  dpe = object[ CMSfwDetectorProtection_INPUTDPES ][i];   
  if (dynContains(CMSfwDetectorProtection_connectedInputDps, dpe)) {
    CMSfwDetectorProtection_connected[i] = true; // already connected
    return;
  }    

  if (! dpExists(dpe) ) {
    CMSfwDetectorProtection_connected[i] = false;
    CMSfwDetectorProtection_debug1("Warning: input dpe not found: " + dpe);
    fwException_raise(exceptionInfo, "DP_NOT_FOUND", "Input dpe not found: " + dpe, "");
    return;
  }
  
  if (object[CMSfwDetectorProtection_ENABLEVERIFY][i]) {
    string dp = CMSfwDetectorProtection_convertToReplyDp(dpe);
    int mySysNum = getSystemId();
    if (! dpExists(dp) ) {
      delay(0, mySysNum*10); // to avoid having many systems creating the dp at the same moment
      if (! dpExists(dp)) {
        CMSfwDetectorProtection_debug3("Creating reply dp " + dp);
        CMSfwDetectorProtection_createDp(dp, CMSfwDetectorProtection_replyType, exceptionInfo);
        for (int s=CMSfwDetectorProtection_SYSNUM_FROM; s<= CMSfwDetectorProtection_SYSNUM_TO; s++) {
  	        dpSet(dp + ".sys" + s + ":_original.._exp_inv" , (s != mySysNum));
        }
        dyn_string logMsg;
        dynAppend(logMsg , ((string) getCurrentTime()) + " Created dp from system " + mySysNum + " ("+ getSystemName() + ")");
        dpSet(dp + ".log", logMsg, dp + ".updated", true);        
        
      }
    }      
    bool invalid;
    dpGet(dp + ".sys" + mySysNum+ ":_original.._exp_inv" , invalid);    
    dpSet(dp + ".sys" + mySysNum+ ":_original.._exp_inv" , false,  dp + ".sys" + mySysNum, 0);
    if (invalid) {
        dyn_string logMsg;
        dpGet(dp + ".log", logMsg);
        dynInsertAt(logMsg , ((string) getCurrentTime()) + " Subscribed from system " + mySysNum + " ("+ getSystemName() + ")",1);
        dpSet(dp + ".log", logMsg, dp + ".updated", true);        
    }
  }  
    
  CMSfwDetectorProtection_debug4("Connecting " + dpe+ "  for condition " + i);
  
  CMSfwDetectorProtection_connected[i] = true; 

  dynAppend(CMSfwDetectorProtection_connectedInputDps,dpe);
        
  dpConnect("CMSfwDetectorProtection_changedCondition", dpe);      
}

int CMSfwDetectorProtection_addSystem(string sysName) {  
  sysName = strrtrim(sysName, ":");
  
  int index = dynContains(CMSfwDetectorProtection_systems, sysName);
  if (index == 0) {
    dynAppend (CMSfwDetectorProtection_systems, sysName);
    index = dynlen(CMSfwDetectorProtection_systems);
    CMSfwDetectorProtection_systemConnected[index] = CMSfwDetectorProtection_isSystemConnected(sysName);
    CMSfwDetectorProtection_disconnectionTime[index] = 0;
    return index;
  } else {
    return index;    
  }
      
  /*if (! dpExists(dpe) ) {
    CMSfwDetectorProtection_debug1(dpe + " does not exist");
    return;
  }
   
  CMSfwDetectorProtection_debug4("Connecting to system status in " + dpe);
  dpConnect("CMSfwDetectorProtection_systemConnectionChanged",dpe); 
  */
}

bool CMSfwDetectorProtection_isSystemConnected(string sysName) {
  string post = ""; 
  int reduNum = myReduHostNum();
   if(reduNum == 2){  
     post = "_2";
   }

  if (sysName == strrtrim(getSystemName(), ":")) return true;
    dyn_int sysIds;
  dpGet("_Connections" + post + ".Dist.ManNums", sysIds);
  if (dynlen(sysIds)<1) return false;
  
  sysName = strrtrim(sysName, ":") + ":";
  
  string dpe = sysName + "_Event.ReadLicense:_online.._value";
  // a data point that exists in any system
  if (! dpExists(dpe) ) return false;
  anytype val;
  
  int rc = dpGet(dpe, val);
  if (rc == -1) return false;
  
  dyn_errClass err = getLastError();
  if (dynlen(err)>0) return false;

  
  return true;
  
  
/*  string dpe =  "_unDistributedControl_" + sysName + ".connected";

  if (! dpExists(dpe) ) return true;
   
  bool conn;
  dpGet(dpe, conn);
  return conn; 
  */
}

bool CMSfwDetectorProtection_isComponentReference(string sys, string& component) {
    component = sys;
    if (substr(sys,0,1) == "{") {
      component = substr(sys, 1, strpos(sys,"}") -1);
      return true;
    }
    return false;
}

synchronized void CMSfwDetectorProtection_systemConnectionChanged(string dpe, bool connected, bool isSysName = false) {
  string sysName;
  if (isSysName) {
    sysName = dpe;
  } else {
    dpe = dpSubStr(dpe, DPSUB_SYS_DP_EL);
    sysName = dpSubStr(dpe, DPSUB_DP);
    strreplace(sysName,"_unDistributedControl_","");
  }
  int index =  dynContains(CMSfwDetectorProtection_systems, sysName);
  if (index == 0) index = CMSfwDetectorProtection_addSystem(sysName);
  
  CMSfwDetectorProtection_systemConnected[index] = connected;
  CMSfwDetectorProtection_debug2(sysName + " is now " + ((connected)?"connected":"DISCONNECTED"));
  if (! connected) {
   /* time t;
    dpGet(dpe + ":_original.._stime" , t);
    */
    CMSfwDetectorProtection_disconnectionTime[index] = getCurrentTime();
    } else {
      CMSfwDetectorProtection_disconnectionTime[index] = 0;
    }
  
  // if a system goes to connected and not all the conditions have been connected, check if there is a condition to connect in this system

  string component;  
  if ((connected) && (dynCount(CMSfwDetectorProtection_connected, true) < dynlen(CMSfwDetectorProtection_connected))) {
    dyn_string components = CMSfwDetectorProtection_getInstalledComponents(sysName);    
    for (int i=1; i<= dynlen(CMSfwDetectorProtection_currentObject[CMSfwDetectorProtection_INPUTDPES]); i++) {
      if (CMSfwDetectorProtection_isComponentReference(CMSfwDetectorProtection_currentObject[CMSfwDetectorProtection_INPUTDPES][i], component)) {
        if (dynContains(components, component)) {
          CMSfwDetectorProtection_debug4("Remapping all inputs referring to {" + component + "} to newly connected system " + sysName);
          CMSfwDetectorProtection_remapSystemToComponent(CMSfwDetectorProtection_currentObject, "{" + component +"}:", sysName + ":");
          
        }
      }
        

    }
    
    CMSfwDetectorProtection_connectConditionsInSystem(CMSfwDetectorProtection_currentObject,sysName);
  }
  if (connected) {
    dynAppend(CMSfwDetectorProtection_reconnectedSystems, sysName);
  }
  
}

void CMSfwDetectorProtection_connectConditionsInSystem(dyn_mixed& object, string sysName) {
  dyn_string exc;
  CMSfwDetectorProtection_addSystem(sysName);
  
  for (int i=1; i<= dynlen(object[CMSfwDetectorProtection_CONDITIONNAME]); i++) {
    if  (CMSfwDetectorProtection_connected[i]) continue;
    if (CMSfwDetectorProtection_getInputSystem(object,i) != sysName) continue;
    CMSfwDetectorProtection_connectCondition(object,i, exc);        
  }
}


string CMSfwDetectorProtection_getInputSystem(dyn_mixed& object, int index) {
  if (dynlen(object[CMSfwDetectorProtection_INPUTDPES])< index) return "";
  string sys; dyn_string exc;
  object[CMSfwDetectorProtection_INPUTDPES][index] = CMSfwDetectorProtection_replaceComponentsWithSystem(object[CMSfwDetectorProtection_INPUTDPES][index]);
  fwGeneral_getSystemName(object[CMSfwDetectorProtection_INPUTDPES][index],sys, exc);
    if (substr(sys,0,1) == "{") return "";
  sys= strrtrim(sys,":");

  return sys;       
   
}

string CMSfwDetectorProtection_replaceComponentsWithSystem(string inputdp) {
    string sys; dyn_string exc;
    fwGeneral_getSystemName(inputdp,sys, exc);
    
    int index; string component;
    if (CMSfwDetectorProtection_isComponentReference(sys, component)) { // a component is specified instead of a system (syntax = {component})
     string inp;
     fwGeneral_getNameWithoutSN(inputdp,inp, exc);
     
     dyn_string systems; 
     fwInstallation_getApplicationSystem(component, systems);
//     DebugTN("Searching systems for " + component + ": "  , systems);
     if (dynlen(systems)== 0) {
       return inputdp;
     } else {
       index = 1;
       if (dynlen(systems)>1) {
         for (int i=1; i<= dynlen(systems); i++) {
           if (dpExists(systems[i] + inp) && (CMSfwDetectorProtection_isSystemConnected(systems[i]))) {
               index = i;
           }
         }
        }
        if (substr(systems[index],0,1) == "*") return inputdp; // in some strange cases fwInstallation_getApplicationSystem returns *system:* (when the system is not connected)
        return systems[index] + inp;
      }
     } else {
         return inputdp;
     } 
   
}


synchronized void CMSfwDetectorProtection_changedCondition(string dpe, bool value) {
  // Update the working memory
  dpe = dpSubStr(dpe,DPSUB_SYS_DP_EL); 
  for (int i=1; i<= dynlen(CMSfwDetectorProtection_currentObject[CMSfwDetectorProtection_INPUTDPES]); i++) {
    if (! CMSfwDetectorProtection_currentObject[CMSfwDetectorProtection_CONDITIONACTIVE][i] ) {
      continue;
    }
    if ( CMSfwDetectorProtection_currentObject[CMSfwDetectorProtection_INPUTDPES][i] == dpe) {
      if ((! CMSfwDetectorProtection_isConnecting) && (CMSfwDetectorProtection_dpeValues[i] == value)) continue; // to avoid updating the fired timestamp if the condition changes from true to true
      CMSfwDetectorProtection_dpeValues[i] = value;
      if (  CMSfwDetectorProtection_isConnecting) {
	dpGet(dpe + ":_original.._stime",  CMSfwDetectorProtection_conditionChangedTime[i]);
      } else {
	CMSfwDetectorProtection_conditionChangedTime[i] = getCurrentTime();
      }
    } 
  }
}


bool CMSfwDetectorProtection_systemNotConnectedForCondition(dyn_mixed& object, int i) {
  if (object[CMSfwDetectorProtection_DISCONNECTED_TIMEOUT][i] == -1) return false;    
  string sysName = CMSfwDetectorProtection_getInputSystem(object,i);
  int index = dynContains(CMSfwDetectorProtection_systems, sysName);
  if ( CMSfwDetectorProtection_systemConnected[index]) return false;
   
  // if it is disconnected for longer than the timeout
   
  time now = getCurrentTime();        
  return ((now - CMSfwDetectorProtection_disconnectionTime[index])>object[CMSfwDetectorProtection_DISCONNECTED_TIMEOUT][i]); 
}

void CMSfwDetectorProtection_analyzeTypes(dyn_mixed& object, dyn_dyn_int locking_condition, dyn_dyn_string& locking_type, dyn_string& fired_types) {
  dyn_string types; string type;
  for (int i=1; i<= dynlen(locking_condition); i++) {
    dynClear(types);
    for (int j=1; j<= dynlen(locking_condition[i]); j++) {
      type = object[ CMSfwDetectorProtection_CONDITIONTYPE][locking_condition[i][j]];
      if (! dynContains(types, type) ) dynAppend(types, type);
      if (! dynContains(fired_types, type) ) dynAppend(fired_types, type);
    }
    locking_type[i] = types;
  } 
}

void CMSfwDetectorProtection_analyze(dyn_mixed& object, dyn_string& locked, dyn_dyn_int& locking_condition, dyn_int& fired_conditions, string systemName, dyn_string& exceptionInfo, dyn_string conditionsToCheck = makeDynString(), bool ignore_masking = false) { 
  dyn_bool conditionValues; dyn_time changedTime; dyn_bool connectedSys; dyn_time disconnectTime;
  bool failed = false;


  // here we analyze also the non active conditions  
  for (int i=1; i<= dynlen(object[CMSfwDetectorProtection_INPUTDPES]); i++) {
    if ((dynlen(conditionsToCheck) >0) && (! dynContains(conditionsToCheck, object[CMSfwDetectorProtection_INPUTDPES][i]))) {
      continue;
    }
    if (! dpExists( object[CMSfwDetectorProtection_INPUTDPES][i] ) ) {
      fwException_raise(exceptionInfo, "DP_NOT_EXISTING","Condition dp " +  object[CMSfwDetectorProtection_INPUTDPES][i] + " does not exist","");
      failed = true;
    }
  }
  if (failed) return;


  for (int i=1; i<= dynlen(conditionsToCheck); i++) {
    conditionsToCheck[i] = dpSubStr(conditionsToCheck[i], DPSUB_SYS_DP) + ".status";
  } 

    dyn_string changedTimeDps;

 

  if (dynlen(conditionsToCheck) == 0) {
    _treeCache_dpGetAll(object[CMSfwDetectorProtection_INPUTDPES], conditionValues);
     changedTimeDps = object[CMSfwDetectorProtection_INPUTDPES];
     for (int i=1; i<= dynlen(changedTimeDps); i++) changedTimeDps[i] = changedTimeDps[i] + ":_original.._stime"; 
    _treeCache_dpGetAll(changedTimeDps, changedTime);
  } else {
    dyn_bool conditionValues2; dyn_time changedTime2;
    _treeCache_dpGetAll(conditionsToCheck, conditionValues2);
    changedTimeDps  =conditionsToCheck;
     for (int i=1; i<= dynlen(changedTimeDps); i++) changedTimeDps[i] = changedTimeDps[i] + ":_original.._stime"; 
    _treeCache_dpGetAll(changedTimeDps, changedTime2);
    int index;
    for (int i=1; i<= dynlen(object[CMSfwDetectorProtection_CONDITIONNAME]); i++) {
      index = dynContains(conditionsToCheck,object[CMSfwDetectorProtection_INPUTDPES][i]);
      if (index == 0) {
	conditionValues[i] = false;
	changedTime[i] = 0;
      } else {
	conditionValues[i] = conditionValues2[index];
	changedTime[i] = changedTime2[index];
      }
    }
  }

  
  dyn_string systems, systemsconnected, systemtimes; string sys;
  for (int i=1; i<= dynlen(object[CMSfwDetectorProtection_CONDITIONNAME]); i++) {
    if (! object[CMSfwDetectorProtection_CONDITIONACTIVE][i]) {
      object[CMSfwDetectorProtection_FIRED][i] = false; 
      continue;   
    }

    object[CMSfwDetectorProtection_FIRED][i] = conditionValues[i];
    /*   if (object[CMSfwDetectorProtection_DELAY][i]>0) {
	 if (conditionValues[i]) {
	 time now = getCurrentTime();
	 if ((now - changedTime[i]) <= object[CMSfwDetectorProtection_DELAY][i])
	 object[CMSfwDetectorProtection_FIRED][i] = false; // this is not 100% correct, bcs it can happen that the condition moves from true to true, but how can I know??         
	 } 
	 }
    */
    sys = CMSfwDetectorProtection_getInputSystem(object,i);
    if (! dynContains(systems, sys) ) dynAppend(systems, sys);        
  }
  for (int i=1; i<= dynlen(systems); i++) {
    systemsconnected[i] = systemName + "_unDistributedControl_" + systems[i] + ".connected";
    systemtimes[i] = systemsconnected[i] + ":_original.._stime"; 
  }
  for (int i=1; i<= dynlen(systems); i++) {
    if (dpExists(systemsconnected[i]) ) {
      dpGet(systemsconnected[i], connectedSys[i],
	    systemtimes[i],disconnectTime[i]); 
    }  else {
      connectedSys[i] = true;
      disconnectTime[i] = 0;     
    }
  }

  
  int index;
  time now = getCurrentTime();        
  for (int i=1; i<= dynlen(object[CMSfwDetectorProtection_CONDITIONNAME]); i++) {
    sys = CMSfwDetectorProtection_getInputSystem(object,i);
    index = dynContains(systems, sys);
    if (! connectedSys[index] ) {
      if  ((now - disconnectTime[index])>object[CMSfwDetectorProtection_DISCONNECTED_TIMEOUT][i]) {
	object[CMSfwDetectorProtection_FIRED][i] = true; 
      }
    }
  }

  CMSfwDetectorProtection_computeIndexes(object, systemName, true, false);
  dyn_string maskedDpes = makeDynString();
  if (! ignore_masking) {
    maskedDpes =  CMSfwDetectorProtection_getMaskedDpesForSystem(systemName);
  }
  
  dynClear(locked); dynClear(locking_condition); dynClear(fired_conditions); 

  for (int i=1; i<= dynlen(object[CMSfwDetectorProtection_CONDITIONNAME]); i++) {   
    if (object[CMSfwDetectorProtection_FIRED][i] )   dynAppend(fired_conditions, i); 
  }
  
  int conditionIndex; dyn_int locking;
  for (int d=1; d<= dynlen(object[CMSfwDetectorProtection_OUTDPES]); d++) {
    if (dynContains(maskedDpes, object[CMSfwDetectorProtection_OUTDPES][d])) {
        continue; // skip masked dpes
    }
    dynClear(locking);
    for (int j=1; j<= dynlen(object[CMSfwDetectorProtection_OUTDPES_CONDITIONS][d]); j++) {
      conditionIndex = object[CMSfwDetectorProtection_OUTDPES_CONDITIONS][d][j];
      if (object[CMSfwDetectorProtection_FIRED][conditionIndex]) {
	      dynAppend(locking, conditionIndex);
      }
    }
    if (dynlen(locking) >0) {
      dynAppend(locked, object[CMSfwDetectorProtection_OUTDPES][d]);
      dynAppend(locking_condition, locking);
    }    
  }

  /*  for (int i=1; i<= dynlen(object[CMSfwDetectorProtection_CONDITIONNAME]); i++) {   
      if (! object[CMSfwDetectorProtection_CONDITIONACTIVE][i]) continue;   
      if (! object[CMSfwDetectorProtection_FIRED][i] ) continue;
      dynAppend(fired_conditions, i);
      outputdpes = CMSfwDetectorProtection_getOutputDpes(object, i, false, systemName);  
      for (int j=1; j<= dynlen(outputdpes); j++) {
      index = dynContains(locked, outputdpes[j]);
      if (index == 0) {
      dynAppend(locked, outputdpes[j]);
      dynAppend(locking_condition, makeDynInt(i));
      }  else {
      dynAppend(locking_condition[index], i);    
      }                             
      }
      }
  */
  
}


dyn_string CMSfwDetectorProtection_getConditionsLockingDpe(string dpe, dyn_string& exc, bool ignore_masking = false) {
    dyn_mixed obj;
    string sys;
    fwGeneral_getSystemName(dpe, sys, exc);
    CMSfwDetectorProtection_loadLocalConfiguration(obj, exc,sys);
    if (dynlen(exc)) return makeDynString();
    dyn_int locking_condition;
    CMSfwDetectorProtection_analyzeDpe(obj, dpe, locking_condition, exc, ignore_masking);
    if (dynlen(exc)) return makeDynString();
    dyn_string conditions; string inputdp;
    for (int i=1; i<= dynlen(locking_condition); i++) {
      inputdp = dpSubStr(obj[CMSfwDetectorProtection_INPUTDPES][locking_condition[i]] , DPSUB_SYS_DP);
      if (! dynContains(conditions, inputdp) ) dynAppend(conditions, inputdp);
    }
    return conditions;
        
}


void CMSfwDetectorProtection_analyzeDpe(dyn_mixed& obj, string dpe, dyn_int& locking_condition, dyn_string& exceptionInfo, bool ignore_masking = false) {
  dynClear(locking_condition);
  dyn_string locked; dyn_dyn_int conditions;
  string systemName; dyn_string exc; dyn_int fired_conditions;
  fwGeneral_getSystemName(dpe, systemName,exc);
  CMSfwDetectorProtection_analyze(obj, locked, conditions, fired_conditions,systemName, exceptionInfo, makeDynString(), ignore_masking);
  int index = dynContains(locked, dpe);
  if (index == 0) return ;
  locking_condition = conditions[index];  
}


void CMSfwDetectorProtection_loadObjects(dyn_string& sysnames, dyn_mixed& objects, dyn_string& exceptionInfo) {
  dynClear(objects);
  for (int i=dynlen(sysnames); i>0; i--) {
    if (dynlen(dpNames(sysnames[i] + "*", CMSfwDetectorProtection_configType)) == 0){
      dynRemove(sysnames,i);
    }
  }
  for (int i=1; i<= dynlen(sysnames); i++) {
    if (shapeExists("txtProgress")) txtProgress.text = "Loading configuration for system " + sysnames[i];
    CMSfwDetectorProtection_loadLocalConfiguration(objects[i],exceptionInfo,sysnames[i]);
    //      DebugN("Summary " +i, CMSfwDetectorProtection_summaryObject(objects[i]));//
    if (dynlen(exceptionInfo)>0 ) break;
  } 
}




void CMSfwDetectorProtection_analyzeMultipleSystems(
						    /* inputs */    
						    dyn_string& sysnames, dyn_dyn_mixed& objects, bool by_type,  bool only_fired, bool show_description,
						    /* outputs */
						    dyn_string& all_conditions, dyn_string& all_inputs, 
						    dyn_bool& all_fired, dyn_string& all_locked_dpes, dyn_dyn_int& all_locking_conditions, dyn_int& conditions_count_locked,   dyn_dyn_string& all_condition_type, dyn_string& types,
						    /* outputs if by_type == true */
						    dyn_dyn_string& all_locking_types, dyn_string& all_types, dyn_int& types_count_locked, 
						    dyn_dyn_int& all_conditions_object_indexes, dyn_dyn_int& all_conditions_condition_indexes,
						    dyn_string& exceptionInfo ) {
    
  dyn_string locked; dyn_dyn_int locking_condition;  dyn_int fired_conditions;
  dyn_dyn_string locking_type; dyn_string fired_types;
  dyn_string conditions; int num;

  string type; types = makeDynString();
  
  int index;
  dyn_string conditionsToCheck;


  conditionsToCheck = all_conditions; // initialize it to sthg to restrict the analysis only to some conditions


  dynClear(all_conditions); dynClear(all_inputs); dynClear(all_fired); dynClear(all_locked_dpes); dynClear(all_locking_conditions); dynClear(conditions_count_locked);
  dynClear(all_locking_types); dynClear(all_types); dynClear(all_conditions_object_indexes);  dynClear(all_conditions_condition_indexes);
  
  dyn_int translation_conditions; int conditionIndex;
  
  for (int i=1; i<= dynlen(sysnames); i++) {
    //DebugN("Analyzing " + sysnames[i]);
    if (shapeExists("txtProgreess") ) {
      txtProgress.text = "Analyzing conditions in system " + sysnames[i] + ". Please wait...";
      txtProgress.visible = true;
    }
    CMSfwDetectorProtection_analyze(objects[i],locked, locking_condition, fired_conditions, sysnames[i], exc, conditionsToCheck);
    if (by_type) {
      dynClear(locking_type); dynClear(fired_types);
      CMSfwDetectorProtection_analyzeTypes(objects[i],  locking_condition, locking_type, fired_types );         
    }
    if (dynlen(exceptionInfo) > 0) return; 
    // DebugN(locking_condition,fired_conditions);
     
    //DebugN(sysnames[i],dynlen(locked));
    conditions = CMSfwDetectorProtection_conditionName(objects[i]);
    translation_conditions = makeDynInt();
    for (int c=1; c<= dynlen(conditions); c++) {
      index = dynContains(all_inputs, (objects[i])[CMSfwDetectorProtection_INPUTDPES][c]);
      type = (objects[i])[CMSfwDetectorProtection_CONDITIONTYPE][c];

      if (index == 0) {
	if (show_description) {
	  dynAppend(all_conditions, CMSfwDetectorProtection_getInputDescription((objects[i])[CMSfwDetectorProtection_INPUTDPES][c]));
	} else {
	  dynAppend(all_conditions, conditions[c]);
	}
	dynAppend(all_condition_type, makeDynString(type));
	dynAppend(all_inputs,  (objects[i])[CMSfwDetectorProtection_INPUTDPES][c]);
	dynAppend(all_fired, dynContains(fired_conditions, c));
	dynAppend(conditions_count_locked,0);
	dynAppend(all_conditions_object_indexes, makeDynInt(i));
	dynAppend(all_conditions_condition_indexes, makeDynInt(c));
          
	index = dynlen(all_conditions);              
      } else {
	if (! show_description) {
	  CMSfwDetectorProtection_analyze_addConditionName(all_conditions[index], conditions[c]);     
	}
	if (! dynContains(all_condition_type[index], type) ) dynAppend(all_condition_type[index], type);
	dynAppend(all_conditions_object_indexes[index],i);
	dynAppend(all_conditions_condition_indexes[index], c);          
      }
      if (! by_type) {
	if ((! only_fired) || ( all_fired[index])) {
	  if (! dynContains(types, type) ) dynAppend(types, type);                      
	}
      }
      translation_conditions[c] = index;       
    }
    //   DebugN("Translation for object "  + i , translation_conditions);


    for (int d=1; d<= dynlen(locked); d++) {
      dynAppend(all_locking_conditions, makeDynInt());
      index = dynlen(all_locking_conditions);
      for (int j=1; j<= dynlen(locking_condition[d]); j++) {
	conditionIndex = translation_conditions[locking_condition[d][j]]; // locking_condition[d][j] gives the index of the jth condition locking the dth datapoint. 
	// The index is relative to current object and must be translated to the global indexing (the same condition can lock dpes in more than 1 system)
	conditions_count_locked[conditionIndex]++; // this is just the count of the number of locked dpes
	dynAppend(all_locking_conditions[index], conditionIndex);
      }
    }
    // I am sure that these are new DPEs because they come from a different system
    dynAppend(all_locked_dpes, locked);
    //   DebugN("all_locked_dpes, all_locking_conditions",all_locked_dpes, all_locking_conditions);
    if (by_type) {
      dynAppend(all_locking_types, locking_type);
      for (int t=1; t<= dynlen(fired_types); t++) {
	if (! dynContains(all_types, fired_types[t]) ) dynAppend (all_types, fired_types[t]);             
      }
    }
     
 
  }
  if (by_type) {
    int typeIndex; bool add_all_types = false;
    dynClear(types_count_locked);
    if (dynlen(all_types)>0) {
      if (dynlen(all_types)>1) {
        dynAppend(all_types, "(Any type)");
        add_all_types = true;
      }
      types_count_locked[dynlen(all_types)] = 0;
      int indexAllTypes = dynlen(all_types);
      for (int d=1; d<= dynlen(all_locked_dpes); d++) {
	for (int j=1; j<= dynlen(all_locking_types[d]); j++) {
	  typeIndex = dynContains(all_types,all_locking_types[d][j]);
	  types_count_locked[typeIndex]++;                           
	}
	if (add_all_types) {
	  types_count_locked[ indexAllTypes] ++; 
	  dynAppend(all_locking_types[d], all_types[indexAllTypes]);
	}
      }
    }
  }
}


void CMSfwDetectorProtection_analyze_addConditionName(string& conditions, string condition) {  
  dyn_string condNames = strsplit(conditions, ",");
  if (! dynContains(condNames, condition) ) dynAppend(condNames, condition);
  fwGeneral_dynStringToString(condNames, conditions,",");          
}

bool CMSfwDetectorProtection_conditionFiredSinceMoreThanDelay(dyn_mixed& object, int i, time now = 0) {
  if (object[CMSfwDetectorProtection_DELAY][i] == 0) return CMSfwDetectorProtection_dpeValues[i];
  if (! CMSfwDetectorProtection_dpeValues[i]) {         
    return false; // if it's not fired, don't look at the time
      
  }
  // if it is holding for longer than the timeout
   
  if (now == 0) now = getCurrentTime();
  //   DebugTN( "Check changed time for condition ", i, ((int) (now - CMSfwDetectorProtection_conditionChangedTime[i])), object[CMSfwDetectorProtection_DELAY][i]);    
  return ((now - CMSfwDetectorProtection_conditionChangedTime[i])>object[CMSfwDetectorProtection_DELAY][i]); 
}



string CMSfwDetectorProtection_getOutputKey(dyn_mixed& object, int index) {  
  string key = "";
        
  switch  (CMSfwDetectorProtection_getPureMode(object[CMSfwDetectorProtection_OUTPUTMODE][index])) {
  case CMSfwDetectorProtection_MODE_DPES:
    // no need to cache    
    break;
  case CMSfwDetectorProtection_MODE_TREECACHE:
  case CMSfwDetectorProtection_MODE_DPALIASES:
  case CMSfwDetectorProtection_MODE_DPNAMES:  
    key = object[CMSfwDetectorProtection_OUTPUTMODE][index] + " " + object[CMSfwDetectorProtection_TREECACHETOPNODE][index] + " " + object[CMSfwDetectorProtection_DUTYPE][index] + " " +
      object[CMSfwDetectorProtection_TOPNODE][index] + (object[CMSfwDetectorProtection_DPELEMENT][index]);
    break;
  case CMSfwDetectorProtection_MODE_USERFUNCTION:
    key = object[CMSfwDetectorProtection_OUTPUTMODE][index] + " " + object[CMSfwDetectorProtection_USERFUNCTION][index];   
    break;
  }
  
  return key;
}
void CMSfwDetectorProtection_registerOutputCache(dyn_mixed& object, int index, dyn_string& keys, dyn_int& conditions) {
  
  string key = CMSfwDetectorProtection_getOutputKey(object, index);
  if (strlen(key) > 0) {
    dynAppend(keys, key);
    dynAppend(conditions, index);
  }  
}

int CMSfwDetectorProtection_getOutputDpeCacheIndex(dyn_mixed& object, int index, dyn_string& keys, dyn_int& conditions) {
  string key = CMSfwDetectorProtection_getOutputKey(object, index);
  if (key == "") return -1;
  int cacheIndex = dynContains(keys, key);
  if (cacheIndex > 0) return conditions[cacheIndex];
  return -1;         
}


void CMSfwDetectorProtection_computeIndexes(dyn_mixed& object, string systemName = "", bool skip_not_fired = false, bool clear = true) {
  if (dynlen(object[CMSfwDetectorProtection_CONDITIONNAME]) == 0) return;  
  dyn_string outputdpes;
  
  dyn_bool cache;

  dyn_string keys; dyn_int conditions;
    
  dyn_int already_mapped_conditions;
  if (clear) {
    dynClear(object[CMSfwDetectorProtection_OUTDPES]);
    dyn_dyn_int ddi;
    object[CMSfwDetectorProtection_OUTDPES_CONDITIONS] = ddi;
  } else {
    for (int i=1; i<= dynlen(object[CMSfwDetectorProtection_OUTDPES_CONDITIONS]);i++) {
      for (int j=1; j<= dynlen(object[CMSfwDetectorProtection_OUTDPES_CONDITIONS][i]); j++) {
        if (! dynContains(already_mapped_conditions,object[CMSfwDetectorProtection_OUTDPES_CONDITIONS][i][j]) ) {
	  dynAppend(already_mapped_conditions,object[CMSfwDetectorProtection_OUTDPES_CONDITIONS][i][j]);
        }
      }
    }
    for (int i=1; i<= dynlen(already_mapped_conditions); i++) {
      CMSfwDetectorProtection_registerOutputCache(object,already_mapped_conditions[i], keys, conditions);
    }
    //    DebugN("already_mapped_conditions ",already_mapped_conditions);
  }
  
  cache[dynlen(object[CMSfwDetectorProtection_CONDITIONNAME])] = false;
  bool first = true;
  int index; int conditionSameOutput;
  int n;
  if (skip_not_fired) {
    n = dynCount(object[CMSfwDetectorProtection_FIRED], true);
  } else {
    n = dynlen(object[CMSfwDetectorProtection_CONDITIONNAME]);      
  }
  int countCond = 0;
  for (int i=1; i<= dynlen(object[CMSfwDetectorProtection_CONDITIONNAME]); i++) {   
    if (! object[CMSfwDetectorProtection_CONDITIONACTIVE][i]) continue; 
    if ((skip_not_fired) && (! object[CMSfwDetectorProtection_FIRED][i])) continue;    
    
    
    countCond++;
    if (myManType() == UI_MAN) {
      if (shapeExists("txtProgress")) {
	setValue("txtProgress", "text","System " + systemName + " processing condition " +countCond + "/" + n );
      }  
    }
    
    if (dynContains(already_mapped_conditions,i)) {
      // DebugN("Already mapped ", i);
      continue;    
    }
    
    conditionSameOutput = CMSfwDetectorProtection_getOutputDpeCacheIndex(object,i, keys, conditions);
    if (conditionSameOutput != -1) {
      //DebugN("Condition " + i + " has some output as " + conditionSameOutput);
      for (int c=1; c<= dynlen(object[CMSfwDetectorProtection_OUTDPES_CONDITIONS]); c++) {
        if (dynContains(object[CMSfwDetectorProtection_OUTDPES_CONDITIONS][c], conditionSameOutput)) {
	  dynAppend(object[CMSfwDetectorProtection_OUTDPES_CONDITIONS][c], i);
        }
      }
      continue;
    }
    
    outputdpes = CMSfwDetectorProtection_getOutputDpes(object, i, false, systemName);  
    CMSfwDetectorProtection_registerOutputCache(object,i, keys, conditions);
    
    //    CMSfwDetectorProtection_debug4("Condition " + i + ":" + dynlen(outputdpes) + " output dpes"); //DebugN(outputdpes);
    for (int j=1; j<= dynlen(outputdpes); j++) {
      if (first) { 
        index = 0; // for the first condition of course the output data points are all new
      }   else {
        index = dynContains(object[CMSfwDetectorProtection_OUTDPES], outputdpes[j]);
      }
      if (index == 0) {
      	dynAppend(object[CMSfwDetectorProtection_OUTDPES], outputdpes[j]);
      	index = dynlen(object[CMSfwDetectorProtection_OUTDPES]);
        dynAppend(object[CMSfwDetectorProtection_OUTDPES_CONDITIONS], makeDynInt(i));
      } else {
        dynAppend(object[CMSfwDetectorProtection_OUTDPES_CONDITIONS][index], i); 
      }          
    }
    first =false; // enable the search in the object[CMSfwDetectorProtection_OUTDPES] list for the next conditions
  }
}

bool  CMSfwDetectorProtection_checkMappingConsistencyForObject(dyn_mixed& object) {
  dyn_mixed newObject;
  newObject = object;

  CMSfwDetectorProtection_computeIndexes(newObject);

  // check outdpes
  
  if (object[CMSfwDetectorProtection_OUTDPES] != newObject[CMSfwDetectorProtection_OUTDPES]) {
    CMSfwDetectorProtection_debug1("Consistency: List of possibly locked dpes not matching");
    return false;
  }

  int n = dynlen(object[CMSfwDetectorProtection_OUTDPES_CONDITIONS]);

  if (n != dynlen(newObject[CMSfwDetectorProtection_OUTDPES_CONDITIONS])) {
    CMSfwDetectorProtection_debug1("Consistency: Length of  conditions not matching: " +n + "!=" + dynlen(newObject[CMSfwDetectorProtection_OUTDPES_CONDITIONS]));
    return false;
  }

  for (int i=1; i<= n; i++) {
    if (object[CMSfwDetectorProtection_OUTDPES_CONDITIONS][i] != newObject[CMSfwDetectorProtection_OUTDPES_CONDITIONS][i]) {
      CMSfwDetectorProtection_debug1("Consistency: Locking conditions have changed for dpe " +object[CMSfwDetectorProtection_OUTDPES][i]);
      return false;
    }
  }

  return true;
}


void CMSfwDetectorProtection_checkMappingConsistency() {
  CMSfwDetectorProtection_checkUnsubscribedConsistency();
  bool valid  = CMSfwDetectorProtection_checkMappingConsistencyForObject(CMSfwDetectorProtection_currentObject);

  if (valid) {
    CMSfwDetectorProtection_debug3("Checked mapping consistency: OK");
  } else {
    CMSfwDetectorProtection_debug1("Mapping consistency NOT OK!");
  }

  dpSet(CMSfwDetectorProtection_managerDp + ".consistency.invalid", (! valid));
}
void CMSfwDetectorProtection_checkUnsubscribedConsistency() {
    dyn_string exc;  
  dyn_string repliesToUnsubscribe = CMSfwDetectorProtection_findUnsubscribedAndValidReplies(getSystemName(), exc);
  if (dynlen(exc) >0)  {
      CMSfwDetectorProtection_debug1("Problem during consistency check of valid replies " + exc);
  } else {
   dpSet(CMSfwDetectorProtection_managerDp + ".consistency.repliesToUnsubscribe.list", repliesToUnsubscribe,
         CMSfwDetectorProtection_managerDp + ".consistency.repliesToUnsubscribe.num" , dynlen(repliesToUnsubscribe));
  }
}



dyn_string CMSfwDetectorProtection_getDpesLockedByCondition(int conditionIndex) {
  dyn_string dpes;
  for (int i=1; i<= dynlen(object[CMSfwDetectorProtection_OUTDPES_CONDITIONS]); i++) {
    if (dynContains(object[CMSfwDetectorProtection_OUTDPES_CONDITIONS][i],conditionIndex)) {
      dynAppend(dpes, object[CMSfwDetectorProtection_OUTDPES][i]);
    }
  }
  return dpes;
}

bool CMSfwDetectorProtection_systemJustConnectedForCondition(dyn_mixed& object, int i) {
  if (dynlen(CMSfwDetectorProtection_reconnectedSystems) == 0) return false;
  string sysName = CMSfwDetectorProtection_getInputSystem(object,i);
  return dynContains(CMSfwDetectorProtection_reconnectedSystems, sysName);
}


/*
  * This is the function that check if the condition have changed since the last call and in case will lock the datapoints
  */
synchronized void CMSfwDetectorProtection_recompute(dyn_mixed& object, dyn_string maskedDpes, bool force = false) {
  // Find changed conditions
  
  time start;

  start = getCurrentTime();
  
  string dpe; int changed = 0;
  dyn_int confirm_gone= makeDynInt();
  dyn_int start_verify = makeDynInt();
  dyn_int reply_just_connected = makeDynInt();
  bool fired, justConnected, toRecompute;
  for (int i=1; i<= dynlen(object[CMSfwDetectorProtection_CONDITIONNAME]); i++) {
    if (! object[CMSfwDetectorProtection_CONDITIONACTIVE][i]) {
      object[CMSfwDetectorProtection_FIRED][i] = false; // just to put something in the array
      continue;   
    }
    fired =  CMSfwDetectorProtection_conditionFiredSinceMoreThanDelay(object,i,start) || /* (! CMSfwDetectorProtection_connected[i] ) || */ ( CMSfwDetectorProtection_systemNotConnectedForCondition(object,i)) ;
    
    justConnected = (CMSfwDetectorProtection_systemJustConnectedForCondition(object,i));
    toRecompute = dynContains(CMSfwDetectorProtection_conditionsToRecompute, i) || force;
    if ((dynlen(object[CMSfwDetectorProtection_FIRED])<i) || (object[CMSfwDetectorProtection_FIRED][i] !=  fired) || (justConnected) || (toRecompute)) {
      object[CMSfwDetectorProtection_FIRED][i] = fired;
      CMSfwDetectorProtection_debug2("Condition " + object[CMSfwDetectorProtection_CONDITIONNAME][i] + " (" + i + ") changed : fired = " + object[CMSfwDetectorProtection_FIRED][i]);
      // if ((object[CMSfwDetectorProtection_ENABLEVERIFY][i])) {
      if ( object[CMSfwDetectorProtection_FIRED][i] ) {
      	dynAppend(start_verify,i);
       	if ((justConnected) || (toRecompute)) dynAppend(reply_just_connected, i); // if just connected we reply 0 and then we set to verify
      } else {
	      dynAppend(confirm_gone, i);
      }
      //}
      changed++;
    }    
  
    
  }


  if (changed == 0) return;
  // this will clear the list of systems that were just reconnected (in the call of recopute just after the reconnection of a system, in this case changed is for sure >0 )
  dynClear(CMSfwDetectorProtection_reconnectedSystems); 
  // conditions are recomputed once after the masked dpes have changed
  dynClear(CMSfwDetectorProtection_conditionsToRecompute);

  // Compute the dpes to set - and lock and the dpes to release
    
  dyn_string  outputdpes;
  dyn_bool lock;
  dyn_int settingCondition;
  int index; bool oldLock;
    
  for (int i=1; i<= dynlen(object[CMSfwDetectorProtection_OUTDPES]); i++) {
    lock[i] = false; settingCondition[i] = 0;
  }
  dyn_bool cache;
  cache[dynlen(object[CMSfwDetectorProtection_CONDITIONNAME])] = false;

  // This loop makes use of the structure created in recomputeIndexes. This is quite fast
  // Scan all dpes and all conditions that can lock the dpe  
  int conditionIndex;
  for (int d=1; d<= dynlen(object[CMSfwDetectorProtection_OUTDPES]); d++) {
    for (int j=1; j<= dynlen(object[CMSfwDetectorProtection_OUTDPES_CONDITIONS][d]); j++) {
      conditionIndex = object[CMSfwDetectorProtection_OUTDPES_CONDITIONS][d][j];
      if (object[CMSfwDetectorProtection_FIRED][conditionIndex]) {
	lock[d] = true;
	if (settingCondition[d] != 0) {
	  if ( CMSfwDetectorProtection_getOutputValue(object,settingCondition[d],cache) != CMSfwDetectorProtection_getOutputValue(object,conditionIndex, cache)) {
	    CMSfwDetectorProtection_debug1("**** CRITICAL ERROR : Two fired conditions ask to set dpe " + object[CMSfwDetectorProtection_OUTDPES][d] + " to different values (" 
					   + CMSfwDetectorProtection_getOutputValue(object,settingCondition[d], cache) + " given from "
					   + " condition " +object[CMSfwDetectorProtection_CONDITIONNAME][settingCondition[d]] + " (" + settingCondition[d] + ") != " + CMSfwDetectorProtection_getOutputValue(object,conditionIndex, cache)+ ")" + 
					   " while processing condition " + object[CMSfwDetectorProtection_CONDITIONNAME][conditionIndex] + " ( " + conditionIndex + " ) ");                    
	  }
	}
	settingCondition[d] = conditionIndex;             
      }
    }      
  }
  
    
  //DebugN(object[CMSfwDetectorProtection_OUTDPES], lock,settingCondition);
  
  dyn_string locked, unlocked; dyn_mixed values;
  // Force lock = 0 for masked channels
  // masked channels
  int indexMaskedDpe;
  for (int i=1; i<= dynlen(maskedDpes); i++) {
    indexMaskedDpe = dynContains(object[CMSfwDetectorProtection_OUTDPES], maskedDpes[i]);
    if (indexMaskedDpe>0) {
        lock[indexMaskedDpe] = false;
    }
  }
  
  for (int i=1; i<= dynlen(object[CMSfwDetectorProtection_OUTDPES]); i++) {
    if (lock[i]) {
      dynAppend(locked, object[CMSfwDetectorProtection_OUTDPES][i]);
      values[dynlen(values)+1] =  CMSfwDetectorProtection_getOutputValue(object,settingCondition[i], cache); 
    } else {
      dynAppend(unlocked, object[CMSfwDetectorProtection_OUTDPES][i]);     
    }
  }  

  // Update the number of locked dps if needed  
  int numLocked = dynlen(locked);
  if (numLocked != CMSfwDetectorProtection_numLockedDpes) {
    dpSet( CMSfwDetectorProtection_managerDp + ".n_locked_dpes" , numLocked);
    CMSfwDetectorProtection_numLockedDpes = numLocked;   
  }
  
    
  
  // Call user function for conditions that just fired
  
  CMSfwDetectorProtection_callUserFunction(object,start_verify, "fired", "pre");
  
    
  // Lock all the elements that need to be locked and set them 

  dyn_int isLocked = CMSfwDetectorProtection_getLocked(locked);
  // skip the ones that are already locked
  for (int i=  dynlen(locked); i>0; i--) {
    if (isLocked[i] == 1) {
      dynRemove(locked,i);
      dynRemove(values,i);
    }
  } 
    
 

  CMSfwDetectorProtection_debug2(" " + dynlen(locked) + " dpes to lock" );
  CMSfwDetectorProtection_setLocked(locked,true);

    
  // Set the values
  CMSfwDetectorProtection_dpSetMany(locked, values);
    
  CMSfwDetectorProtection_callUserFunction(object,start_verify, "fired", "post");
  

  
  // Call user function for conditions that just went
  CMSfwDetectorProtection_callUserFunction(object,confirm_gone,"gone","pre");
    
  // Unlock all the elements that need to be unlocked
    
  isLocked = CMSfwDetectorProtection_getLocked(unlocked);
  // skip the ones that are already unlocked
  for (int i=  dynlen(unlocked); i>0; i--) {
    if (isLocked[i] != 1) dynRemove(unlocked,i); 
  }       
  
  CMSfwDetectorProtection_debug4(" " + dynlen(unlocked) + " dpes to unlock");
  CMSfwDetectorProtection_setLocked(unlocked, false);    
    
  // Confirm conditions where FIRED goes 1 -> 0
    
  dyn_string replydps; string replydp;
  for (int i=1; i<= dynlen(confirm_gone); i++) {
    if (! object[CMSfwDetectorProtection_ENABLEVERIFY][confirm_gone[i]]) continue;
    replydp = CMSfwDetectorProtection_convertToReplyDp(object[CMSfwDetectorProtection_INPUTDPES][confirm_gone[i]]);
    if (! dynContains(replydps,  replydp) ) {
      dynAppend(replydps, replydp);
    }
    CMSfwDetectorProtection_toVerify[confirm_gone[i]] = false;
  }
  
  // these are the reply dps where we should answer 0 because the system just reconnected (they also will be set to be verified and we will eventually reply 1)
  for (int i=1; i<= dynlen(reply_just_connected); i++) {
    if (! object[CMSfwDetectorProtection_ENABLEVERIFY][reply_just_connected[i]]) continue;
    replydp = CMSfwDetectorProtection_convertToReplyDp(object[CMSfwDetectorProtection_INPUTDPES][reply_just_connected[i]]);
    if (! dynContains(replydps,  replydp) ) {
      dynAppend(replydps, replydp);
    }
  }

  for (int i=1; i<= dynlen(replydps); i++) {
    CMSfwDetectorProtection_reply(replydps[i], false); 
  }
    
  // Call user function for conditions that just went
  CMSfwDetectorProtection_callUserFunction(object,confirm_gone,"gone","post");
  
    
    
  //  Set the verification
  
  dyn_string inputdps; string inputdp;
  for (int i=1; i<= dynlen(start_verify); i++) {
    if (! object[CMSfwDetectorProtection_ENABLEVERIFY][start_verify[i]]) continue;
    inputdp =  object[CMSfwDetectorProtection_INPUTDPES][start_verify[i]];
    if (! dynContains(inputdps, inputdp) ) dynAppend(inputdps, inputdp);     
  }
  
  for (int i=1; i<= dynlen(inputdps); i++) {
    startThread("CMSfwDetectorProtection_setVerify", inputdps[i]);  
  }
    

  int elapsed = period(getCurrentTime()) - period(start);

  CMSfwDetectorProtection_debug("Analysis performed in " + elapsed  + " seconds.", ((elapsed<3)?4:1));
  
}

void CMSfwDetectorProtection_unlockAll(dyn_mixed& object) {
  if (fwInstallationRedu_isPassive()) return;
  dyn_string unlocked = object[CMSfwDetectorProtection_OUTDPES];
  dyn_int isLocked = CMSfwDetectorProtection_getLocked(unlocked);
  // skip the ones that are already unlocked
  for (int i=  dynlen(unlocked); i>0; i--) {
    if (isLocked[i] == 0) {
      dynRemove(unlocked,i);
    }
  }
    
  CMSfwDetectorProtection_setLocked(unlocked, false);
  int numLocked = 0;
  if (numLocked != CMSfwDetectorProtection_numLockedDpes) {
    dpSet( CMSfwDetectorProtection_managerDp + ".n_locked_dpes" , numLocked);
    CMSfwDetectorProtection_numLockedDpes = numLocked;   
  }
}

void CMSfwDetectorProtection_callUserFunction(dyn_mixed& object,dyn_int conditions, string fired_gone, string pre_post) {
  for (int i=1; i<= dynlen(conditions); i++) {
    if (strlen(object[CMSfwDetectorProtection_PREPOST_USERFUNCTION][conditions[i]]) > 0) {
      string functionName = "CMSfwDetectorProtectionUser_" +pre_post + "_" +  fired_gone ;
      string function= "void main() { if (isFunctionDefined(\"" + functionName + "\")) { " + functionName + "(); } } ";
      function += "\n" +  object[CMSfwDetectorProtection_PREPOST_USERFUNCTION][conditions[i]];
      if (execScript(function, makeDynString()) == -1) {
        CMSfwDetectorProtection_debug1("Error in running script " + function);  
      }      
    }
  }   
}

void CMSfwDetectorProtection_setVerify(string inputdp) {
  dyn_int indexes;
  delay(CMSfwDetectorProtection_getMinimumDelayTime(CMSfwDetectorProtection_currentObject,inputdp, indexes)); 
  // in indexes i have all the indexes of the conditions with the same input dpe which have the verify enabled
  synchronized (CMSfwDetectorProtection_verifySync) {
    for (int i=1; i<= dynlen(indexes); i++) {
      if (CMSfwDetectorProtection_currentObject[CMSfwDetectorProtection_FIRED][indexes[i]]) {
	CMSfwDetectorProtection_debug4("Setting to verify = true for condition " + indexes[i] );    
	CMSfwDetectorProtection_toVerify[indexes[i]] = true; 
      } else {
	CMSfwDetectorProtection_debug4("Condition  " + indexes[i]  + " not fired anymore. Setting toVerify = false");    
	CMSfwDetectorProtection_toVerify[indexes[i]] = false; 
      }
    }
  }       
}


int CMSfwDetectorProtection_getMinimumDelayTime(dyn_mixed& object, string inputdp, dyn_int& indexes) {
  int min = -1;
  indexes = makeDynInt();
  for (int i=1; i<= dynlen(object[CMSfwDetectorProtection_CONDITIONNAME]); i++) { 
    if (object[CMSfwDetectorProtection_INPUTDPES][i] != inputdp) continue;     
    if (object[CMSfwDetectorProtection_ENABLEVERIFY][i]) {
      dynAppend(indexes, i);
      if (min == -1) min = object[CMSfwDetectorProtection_VERIFY_DELAY][i];
      else min = dynMin(makeDynInt(min,object[CMSfwDetectorProtection_VERIFY_DELAY][i]));  
    }     
  }
  return min;
}


dyn_string CMSfwDetectorProtection_getCorrespondingVerifyDpes(dyn_mixed& object, int index, string dpe, string mySys) {
      dyn_string settings, verif; string function; dyn_string result;
      int indexDpe;
      switch  (CMSfwDetectorProtection_getPureMode(object[CMSfwDetectorProtection_OUTPUTMODE][index])) {
          case CMSfwDetectorProtection_MODE_DPES:
          // if the length is the same,
          settings = CMSfwDetectorProtection_getOutputDpes(object, index, false, mySys);
          verif = CMSfwDetectorProtection_getOutputDpes(object, index, true, mySys);
          if (dynlen(settings) == dynlen(verif)) {
              dpe = dpSubStr(dpe , DPSUB_SYS_DP);
              for (int i=1; i<= dynlen(verif); i++) {
                  if (dpSubStr(settings[i], DPSUB_SYS_DP) == dpe) return makeDynString(verif[i]);
              } 
              CMSfwDetectorProtection_debug1("Cannot find corresponding verify dpe for " + dpe);
          } else {
            return makeDynString();          
          }
        
          break;
          case CMSfwDetectorProtection_MODE_TREECACHE:
          case CMSfwDetectorProtection_MODE_DPNAMES:
          case CMSfwDetectorProtection_MODE_DPALIASES:
            return makeDynString(dpSubStr(dpe, DPSUB_SYS_DP) + object[CMSfwDetectorProtection_VERIFY_DPELEMENT][index]);
          break;
          
         case CMSfwDetectorProtection_MODE_USERFUNCTION: //use the user function in PREPOSTUSERFUNCTION
      if (strlen(object[CMSfwDetectorProtection_PREPOST_USERFUNCTION][index]) > 0) {
      string functionName = "CMSfwDetectorProtectionUser_convertToReadback" ;
      string function= "dyn_string main() { if (isFunctionDefined(\"" + functionName + "\")) { return " + functionName + "(\"" + dpe + "\"); } else {return makeDynString() ; } } ";
      function += "\n" +  object[CMSfwDetectorProtection_PREPOST_USERFUNCTION][index];

      if (evalScript(result,function, makeDynString()) == -1) {
        CMSfwDetectorProtection_debug1("Error in running script " + function);  
        return makeDynString();
      }
      return result;      
    }      
          break;
 
            
      }
      return makeDynString();
      
}

dyn_string CMSfwDetectorProtection_getOutputDpes(dyn_mixed& object, int index, bool verify = false, string mySys = "") {
  dyn_string dpes,dutypes; dyn_string nodes; int res; dyn_string aliases; dyn_string dpes_temp;
  if (mySys == "") mySys = getSystemName(); 
  switch  (CMSfwDetectorProtection_getPureMode(object[CMSfwDetectorProtection_OUTPUTMODE][index])) {
  case CMSfwDetectorProtection_MODE_DPES:
    if (verify) {
      dpes = object[CMSfwDetectorProtection_VERIFY_DPES][index];
    } else {
      dpes = object[CMSfwDetectorProtection_OUTPUTDPES][index];
    }
    break;
  case CMSfwDetectorProtection_MODE_TREECACHE:
    treeCache_start(object[CMSfwDetectorProtection_TREECACHETOPNODE][index]);
    dutypes = object[CMSfwDetectorProtection_DUTYPE][index];
    for (int i=1; i<= dynlen(dutypes); i++) {
      if (! treeCache_isNode(object[CMSfwDetectorProtection_TOPNODE][index])) {
	CMSfwDetectorProtection_debug1("Warning: " + object[CMSfwDetectorProtection_TOPNODE] + " is not cached");
	break;
      }
      nodes = treeCache_getNodesOfTypeBelow( object[CMSfwDetectorProtection_TOPNODE][index],dutypes[i]);

      for (int j=1; j<= dynlen(nodes); j++) {
	if (treeCache_getSystem(nodes[j]) == mySys) { 
	  dynAppend(dpes, treeCache_getFsmDevDp(nodes[j]) + ((verify)?(object[CMSfwDetectorProtection_VERIFY_DPELEMENT][index]):(object[CMSfwDetectorProtection_DPELEMENT][index]))) ;
	}
      }

    } 

    // here i return because i am sure they all belong to the same system
    return dpes;
    break;
  case CMSfwDetectorProtection_MODE_USERFUNCTION:

    res = evalScript(dpes, object[CMSfwDetectorProtection_USERFUNCTION][index], makeDynString(), 
		     object[CMSfwDetectorProtection_CONDITIONNAME][index], object[CMSfwDetectorProtection_INPUTDPES][index],mySys,verify);
    if (res == -1) {
      CMSfwDetectorProtection_debug1("Error in executing user function to get dpes");      
      dpes= makeDynString();
    }
    break;
  case CMSfwDetectorProtection_MODE_DPNAMES:
    dutypes = object[CMSfwDetectorProtection_DUTYPE][index];
    for (int t=1; t<= dynlen(dutypes); t++) {
      dpes_temp = dpNames(mySys + object[CMSfwDetectorProtection_TOPNODE][index] + "*", dutypes[t]);
      for (int k=1; k<= dynlen(dpes_temp) ; k++) {
        dynAppend(dpes, dpSubStr(dpes_temp[k], DPSUB_SYS_DP) + ((verify)?(object[CMSfwDetectorProtection_VERIFY_DPELEMENT][index]):(object[CMSfwDetectorProtection_DPELEMENT][index])));     
      }  
    }
    return dpes;
    break;
  case CMSfwDetectorProtection_MODE_DPALIASES:
    dutypes = object[CMSfwDetectorProtection_DUTYPE][index];
    dpGetAllAliases(dpes, aliases, object[CMSfwDetectorProtection_TOPNODE][index] + "*",mySys + "*.**" );
    //     DebugTN(dpes, aliases);
    for (int i=dynlen(dpes); i>0 ; i--) {
      if (! dynContains(dutypes,dpTypeName(dpes[i]))) {
	dynRemove(dpes,i); 
      } else {
	dpes[i] = dpSubStr(dpes[i], DPSUB_SYS_DP) + ((verify)?(object[CMSfwDetectorProtection_VERIFY_DPELEMENT][index]):(object[CMSfwDetectorProtection_DPELEMENT][index]));     
      }
    }
    //DebugTN(dpes);
    dynSortAsc(dpes); dynUnique(dpes);
    //DebugTN(dpes);
    return dpes;
    break;
  }
  
  // select dpes from mySys
  dyn_string exc; string sys;
  for (int i=dynlen(dpes); i>0; i--) {
    fwGeneral_getSystemName(dpes[i], sys, exc);
    if (sys != mySys) dynRemove(dpes,i); 
  }
  return dpes;
}





void CMSfwDetectorProtection_restart(string dp, bool restart) {
  DebugTN("*** DETECTOR PROTECTION RESTARTING ****");
  DebugTN("*** PLEASE do not forget to set this manager to always ****");
  delay(2);
  exit(0);      
}

void CMSfwDetectorProtection_triggerRestart(string sys) {
  dpSet(sys +  CMSfwDetectorProtection_managerDp + ".triggerRestart", true);
  if (dpExists(sys +  CMSfwDetectorProtection_managerDp + "_2.triggerRestart")) {
      dpSet(sys +  CMSfwDetectorProtection_managerDp + "_2.triggerRestart", true);
  }
}


void CMSfwDetectorProtection_triggerConsistencyCheck(string sys, dyn_string& exceptionInfo) {
  int timeout = 30;
  dyn_anytype returnValues;
  bool timerExpired;
  dyn_anytype condition = makeDynAnytype();

  string managerdp = sys +  CMSfwDetectorProtection_managerDp ;
  if (! dpExists(managerdp + ".consistency.check") ) {
    fwException_raise(exceptionInfo, "DP_DOES_NOT_EXISTS","Manager dp " + managerdp + ".consistency.check" + " does not exist",
		      "");
    return;
  }
  dyn_string waitVal = makeDynString(sys +  CMSfwDetectorProtection_managerDp + ".consistency.invalid" + ":_original.._value");

  dpSet(managerdp + ".consistency.check", true);
  
  if (dpWaitForValue(waitVal,condition, 
		     waitVal, returnValues, timeout, timerExpired) == -1) {
    fwException_raise(exceptionInfo, "ERROR","Error in dpWaitForValue",
		      "");
    return;
  }
  if (timerExpired) {
    fwException_raise(exceptionInfo, "TIMER_EXPIRED","Timer expired",
		      "");
  }  
}


void CMSfwDetectorProtection_startLoopsAndCallbacks() {
   CMSfwDetectorProtection_debug4("Starting alive beat loop");
   startThread("CMSfwDetectorProtection_aliveLoop", CMSfwDetectorProtection_managerDp);
   startThread("CMSfwDetectorProtection_consistencyLoop");     
  
  dpConnect("CMSfwDetectorProtection_cbConsistencyCheck", false,CMSfwDetectorProtection_managerDp + ".consistency.check");
  
  delay(1);
  CMSfwDetectorProtection_checkUnsubscribedConsistency();
}


void CMSfwDetectorProtection_setupAlertConsistency(string managerDp) {
  dyn_string exc;
  
  dpSetDescription(managerDp + ".consistency.invalid", "Det. Protection mapping invalid on " + getSystemName());
  string alertClass = "_fwFatalNack_90.";
  fwAlertConfig_setDigital(managerDp + ".consistency.invalid", makeDynString("", "Detector protection mapping invalid on system "  + getSystemName() + " please restart it when possible!"), makeDynString("", alertClass),
                           "",makeDynString(),"", exc);
  
  
  fwAlertConfig_activate(managerDp + ".consistency.invalid", exc);
  
  if  (dynlen(exc)>0) {
    CMSfwDetectorProtection_debug1(exc);
  } 
}

/*
  This is the start function that is called in the script 
  */
void CMSfwDetectorProtection_start() {  
  dyn_string exc; string alertClass;
  
  /** Create the manager data points */
  if (myReduHostNum() ==2) {
    CMSfwDetectorProtection_managerDp= CMSfwDetectorProtection_managerDp + "_2";
  }
  if (! dpExists(  CMSfwDetectorProtection_managerDp) ) {
    dpCreate(CMSfwDetectorProtection_managerDp, CMSfwDetectorProtection_managerType); 
    CMSfwDetectorProtection_setupAlertConsistency(CMSfwDetectorProtection_managerDp);
  }
  if (isRedundant() && (myReduHostNum() == 1) && ( ! fwInstallationRedu_isPassive())) {
    if (! dpExists (CMSfwDetectorProtection_managerDp + "_2") ) {
      dpCreate(CMSfwDetectorProtection_managerDp + "_2", CMSfwDetectorProtection_managerType); 
      CMSfwDetectorProtection_setupAlertConsistency(CMSfwDetectorProtection_managerDp+ "_2");
    }
  }
  
  if (! dpExists(CMSfwDetectorProtection_generalConfigDp)) {
      dpCreate(CMSfwDetectorProtection_generalConfigDp,"CMSfwDetectorProtectionGeneralConfig");
  }
  
  dpSet(CMSfwDetectorProtection_managerDp + ".startTime", getCurrentTime(),
        CMSfwDetectorProtection_managerDp + ".n_locked_dpes" , 0);
  
  // Load local configuration: this will merge all the configurations stored in configuration dbs into a single object
  bool loadResult = CMSfwDetectorProtection_loadLocalConfiguration(CMSfwDetectorProtection_currentObject, exc); 

  if (dynlen(exc)) {
    CMSfwDetectorProtection_debug1(exc); delay(10); return;
  }


  dpConnect("CMSfwDetectorProtection_restart",false,CMSfwDetectorProtection_managerDp + ".triggerRestart");

  // If all conditions are disabled, just stay idle (will be restarted when needed)
  if (! loadResult ) {
   CMSfwDetectorProtection_startLoopsAndCallbacks();
  
    while (1) {
      CMSfwDetectorProtection_debug3("All conditions disabled");       
      delay(3600);
    }     
  }
  CMSfwDetectorProtection_setDebug(CMSfwDetectorProtection_currentObject[CMSfwDetectorProtection_DEBUGLEVEL]);  

   
  //DebugN(CMSfwDetectorProtection_currentObject);
  //CMSfwDetectorProtection_debug4(CMSfwDetectorProtection_summaryObject(CMSfwDetectorProtection_currentObject));

  
  bool startVerifyLoop = false;
  for (int i=1; i<= dynlen(CMSfwDetectorProtection_currentObject[CMSfwDetectorProtection_CONDITIONNAME]); i++) {
    CMSfwDetectorProtection_toVerify[i] = false;
    if (CMSfwDetectorProtection_currentObject[CMSfwDetectorProtection_ENABLEVERIFY][i]) startVerifyLoop = true;
    // preprocess dpes
    if (CMSfwDetectorProtection_currentObject[CMSfwDetectorProtection_OUTPUTMODE][i]>=100) {      
      CMSfwDetectorProtection_currentObject[CMSfwDetectorProtection_OUTPUTDPES][i] = CMSfwDetectorProtection_getOutputDpes(CMSfwDetectorProtection_currentObject, i);
      CMSfwDetectorProtection_debug4("Preprocessed dpes for condition " + i + " got " + dynlen( CMSfwDetectorProtection_currentObject[CMSfwDetectorProtection_OUTPUTDPES][i] ) + " dpes"); 
      if (  (CMSfwDetectorProtection_currentObject[CMSfwDetectorProtection_ENABLEVERIFY][i]) && 
	    (strlen(CMSfwDetectorProtection_currentObject[CMSfwDetectorProtection_VERIFY_USERFUNCTION][i]) == 0) ) {
	       CMSfwDetectorProtection_currentObject[CMSfwDetectorProtection_VERIFY_DPES][i] = CMSfwDetectorProtection_getOutputDpes(CMSfwDetectorProtection_currentObject, i, true);
      }
      CMSfwDetectorProtection_currentObject[CMSfwDetectorProtection_OUTPUTMODE][i] = CMSfwDetectorProtection_MODE_DPES;
    }
    
  }
 
  // Compute dpe indexes. This will convert the information stored in the object in a faster data structure 
  // (list of dpes, for each dpe a list of conditions that can lock it)
  CMSfwDetectorProtection_debug2("Computing dpe indexes...");
  CMSfwDetectorProtection_computeIndexes(CMSfwDetectorProtection_currentObject);

  // Connect to the input conditions
  CMSfwDetectorProtection_debug2("Connecting conditions...");
  CMSfwDetectorProtection_connect(CMSfwDetectorProtection_currentObject, exc);
  if (dynlen(exc)) {
    DebugN(exc);  
  }
  CMSfwDetectorProtection_maskedDpes = makeDynString();
  CMSfwDetectorProtection_conditionsToRecompute = makeDynInt();
  // Connect to runtime configurations
  dpConnect("CMSfwDetectorProtection_updateIgnoreInvalid", CMSfwDetectorProtection_generalConfigDp + ".ignoreInvalidBit");
  dpConnect("CMSfwDetectorProtection_updateMaskedDpes",  
              CMSfwDetectorProtection_generalConfigDp + ".mask.maskedDpes");
  dpSet(CMSfwDetectorProtection_managerDp + ".consistency.invalid", false);
  CMSfwDetectorProtection_setupAlertConsistency(CMSfwDetectorProtection_managerDp);
  
  
  // Alert when the invalid bit is ignored
  alertClass = "_fwWarningNack_50.";
    fwAlertConfig_setDigital(CMSfwDetectorProtection_generalConfigDp + ".ignoreInvalidBit", makeDynString("", "Invalid bit ignored by Detector Protection on "  + getSystemName() ), makeDynString("", alertClass),
                           "",makeDynString(),"", exc);
  
  
  fwAlertConfig_activate(CMSfwDetectorProtection_generalConfigDp + ".ignoreInvalidBit", exc);

  if  (dynlen(exc)>0) {
    CMSfwDetectorProtection_debug1(exc);
  } 

    // Unlock all data points just in case
  CMSfwDetectorProtection_unlockAll(CMSfwDetectorProtection_currentObject);
  // If running on a redundant system we must connect to check when the system becomes active
  CMSfwDetectorProtection_connectRedundancy();
  
  CMSfwDetectorProtection_debug2("Starting main loop...");  
  // This is the main loop checking if the status of the conditions has changed (every second)
  startThread("CMSfwDetectorProtection_mainLoop");
 
   
  if (startVerifyLoop) {
    // delay(30);
    // The verify loop is responsible for verifying that the safe condition is reached and to reply
    CMSfwDetectorProtection_debug2("Starting verify loop...");
    startThread("CMSfwDetectorProtection_verifyLoop");
  }  
   
 CMSfwDetectorProtection_debug2("Starting loops and callbacks...");
 // Additional loops and callbacks
 CMSfwDetectorProtection_startLoopsAndCallbacks();
 
  
 
    
}

void CMSfwDetectorProtection_cbConsistencyCheck(string dpe, bool check) {
 CMSfwDetectorProtection_checkMappingConsistency();

}


void CMSfwDetectorProtection_updateIgnoreInvalid(string dpe, bool ignore){
    CMSfwDetectorProtection_checkInvalid = (! ignore);    
}

synchronized void CMSfwDetectorProtection_updateMaskedDpes(string dpe2, dyn_string maskedDpes) {
  CMSfwDetectorProtection_debug4("Masked dpes  are now " + dynlen(maskedDpes));
  dyn_string allMaskedAndUnmasked = CMSfwDetectorProtection_maskedDpes;
  CMSfwDetectorProtection_maskedDpes = maskedDpes;
  dynAppend(allMaskedAndUnmasked, maskedDpes);
  dynUnique(allMaskedAndUnmasked);
  // we have to recompute the conditions that involve the data points that were newly masked or unmasked

  int index, condition;
  for (int i=1; i<= dynlen(allMaskedAndUnmasked); i++) {
    index = dynContains(CMSfwDetectorProtection_currentObject[CMSfwDetectorProtection_OUTDPES], allMaskedAndUnmasked[i]);
    if (index > 0) {
      for (int j=1; j<= dynlen(CMSfwDetectorProtection_currentObject[CMSfwDetectorProtection_OUTDPES_CONDITIONS][index]); j++) {
        condition = CMSfwDetectorProtection_currentObject[CMSfwDetectorProtection_OUTDPES_CONDITIONS][index][j];
        if (! dynContains(CMSfwDetectorProtection_conditionsToRecompute,condition) )
          dynAppend(CMSfwDetectorProtection_conditionsToRecompute,condition);
      }
    }
  }
      
  CMSfwDetectorProtection_debug4("Conditions to recompute : " + CMSfwDetectorProtection_conditionsToRecompute);
}

void CMSfwDetectorProtection_mainLoop() { 
  while (1) {
    CMSfwDetectorProtection_recompute(CMSfwDetectorProtection_currentObject, CMSfwDetectorProtection_maskedDpes);
    delay(1);    
  } 
}

void CMSfwDetectorProtection_aliveLoop(string managerDp) {
  while (1) {
    dpSet(managerDp + ".aliveTime", getCurrentTime());
    delay(60);    
  }
}

void CMSfwDetectorProtection_consistencyLoop() {
  while (1) {
    delay(3600);
    CMSfwDetectorProtection_checkMappingConsistency();
  }
}

bool CMSfwDetectorProtection_verifyObject(dyn_mixed& object, int index, bool stop_at_first_error, dyn_string& problems, string systemName = "", int checkInvalid = -1, dyn_string maskedDpes = makeDynString()) {
  int res;   bool verify; int indexMaskedDpe;
  if (checkInvalid == -1) {
    checkInvalid = CMSfwDetectorProtection_checkInvalid;
  }
  dyn_string maskedReadbacks = makeDynString();
  for (int i=1; i<= dynlen(maskedDpes); i++ ) {
    dynAppend(maskedReadbacks, 
              CMSfwDetectorProtection_getCorrespondingVerifyDpes(object, index,maskedDpes[i], systemName));
  }
    
  time start, stop;  
  dyn_string customVerifResult;
  if (dynlen(object)<CMSfwDetectorProtection_VERIFY_USERFUNCTION) {
    CMSfwDetectorProtection_debug1("Length of object= " + dynlen(object) + " while looking for index " + CMSfwDetectorProtection_VERIFY_USERFUNCTION);
  } else if (index > dynlen(object[CMSfwDetectorProtection_VERIFY_USERFUNCTION])) {
     CMSfwDetectorProtection_debug1("Length of USERFUNCTION= " + ( dynlen(object[CMSfwDetectorProtection_VERIFY_USERFUNCTION]))+ " while looking for index " + index);
     DebugN("input " + object[CMSfwDetectorProtection_INPUTDPES][index]);
  } else if ( strlen (object[CMSfwDetectorProtection_VERIFY_USERFUNCTION][index])>0 ) {
    res = evalScript(customVerifResult, object[CMSfwDetectorProtection_VERIFY_USERFUNCTION][index], makeDynString(),
                     object, index, stop_at_first_error, systemName, checkInvalid, maskedDpes);
    if (res == -1) {
      CMSfwDetectorProtection_debug1("Problem in custom function for verification");
      return false; 
    }
  // the function should return a dyn_string where the first element is 0 or 1 (ok or not), the rest are the problems. If this is empty it is supposed to be ok
    if (dynlen(  customVerifResult) == 0) {
        verify =false;
    }   else {
        verify = (customVerifResult[1] == "1");          
        dynRemove(customVerifResult,1);
        problems = customVerifResult;
    }

    CMSfwDetectorProtection_debug4("Verification with custom function: " + ((verify)?"ok":"failed"));
    return verify;
  }
  dyn_string outdpes =  CMSfwDetectorProtection_getOutputDpes(object, index,true, systemName);
  int nmasked  = 0;
  for (int i=1; i<= dynlen(maskedReadbacks); i++) {
      indexMaskedDpe = dynContains(outdpes, maskedReadbacks[i]);
      if (indexMaskedDpe>0) {
          dynRemove(outdpes, indexMaskedDpe); nmasked++;
      }
  }
  CMSfwDetectorProtection_debug4("Verifying " + dynlen(outdpes) + " for condition " + index + " (" + object[CMSfwDetectorProtection_CONDITIONNAME][index] + ") - removed because masked " + nmasked);
  dyn_mixed values;
  if (dynlen(outdpes) > 0) {
    dpGet(outdpes, values);
  } else {
    CMSfwDetectorProtection_debug2("0 dpes to verify for condition " + index);    
  }
   


  bool verifyResult = true;

  if (checkInvalid) {
    dyn_string outdpes_invalid;
    for (int i=1; i<= dynlen(outdpes); i++) {
      outdpes_invalid[i] = outdpes[i] + ":_online.._bad";
    }  
    dyn_bool bad;
    if (dynlen(outdpes_invalid)>0) {
      dpGet(outdpes_invalid, bad);
    }

  
    for (int i=1; i<= dynlen(bad); i++) {
      if (bad[i]) {
	CMSfwDetectorProtection_debug4("Verification failed: " + outdpes[i] + " invalid" );
	dynAppend(problems , outdpes[i] + "=invalid");
	verifyResult = false;
	if (stop_at_first_error)  return false;
      }
    }
    
  }

  
  for (int i=1; i<= dynlen(values); i++) {
    res = evalScript(verify, object[CMSfwDetectorProtection_VERIFY_FUNCTION][index], makeDynString(), 
		     values[i]);
    if (! verify) {
      CMSfwDetectorProtection_debug4("Verification failed: " + outdpes[i] + " = " + values[i]);
      dynAppend(problems , outdpes[i] + "=" + values[i]);
      verifyResult = false;
      if (stop_at_first_error)  return false;
    }

  }
  if (verifyResult) 
    CMSfwDetectorProtection_debug4("Verification ok");
  else
    CMSfwDetectorProtection_debug4("Verification failed");
  return verifyResult;
}


void CMSfwDetectorProtection_verify(dyn_mixed& object, dyn_string maskedDpes) {
  dyn_string outputdpes ;
  dyn_string replydps; dyn_bool result; string replydp;
  int index; bool verifyResult;
  dyn_bool cache = makeDynBool();
           
  dyn_string problems; 
  synchronized (CMSfwDetectorProtection_verifySync) {
    for (int i=1; i<= dynlen(object[CMSfwDetectorProtection_CONDITIONNAME]); i++) {
      if (! object[CMSfwDetectorProtection_CONDITIONACTIVE][i]) {
	continue;   
      }  
      
      if ((dynlen(CMSfwDetectorProtection_toVerify)>=i) && (CMSfwDetectorProtection_toVerify[i] )) {
	if ((object[CMSfwDetectorProtection_FIRED][i])) {
	  replydp = CMSfwDetectorProtection_convertToReplyDp(object[CMSfwDetectorProtection_INPUTDPES][i]);
	  verifyResult = CMSfwDetectorProtection_verifyObject(object,i, true, problems, "", -1, maskedDpes);
	  index = dynContains(replydps, replydp);
	  if (index == 0) {
	    dynAppend(replydps,replydp);
	    index = dynlen(replydps);
	    result[index] = verifyResult; 
	  }
	  if (verifyResult) {
	    CMSfwDetectorProtection_toVerify[i] = false;
	  } else {
	    result[index] = false; // false overwrites true (all must be verified to give the reply)
	    // set again
	    outputdpes = CMSfwDetectorProtection_getOutputDpes(object,i);   
      // strip masked
      for (int i=1; i<= dynlen(maskedDpes); i++) {
           index = dynContains(outputdpes, maskedDpes[i]);
           if (index>0) {
              dynRemove(outputdpes, index);
           }       
      }      
	    CMSfwDetectorProtection_dpSetAll(outputdpes,  CMSfwDetectorProtection_getOutputValue(object,i, cache));                
	  }
	} else {
	  CMSfwDetectorProtection_debug4("Condition " + i + " not fired anymore. Skipping verification and setting toVerify to false");           
	  CMSfwDetectorProtection_toVerify[i] = false; 
	}  
      }
    }
  
    // Reply to the verified ones
  
    for (int i=1; i<= dynlen(replydps); i++) {
      if (result[i]) {
	CMSfwDetectorProtection_reply(replydps[i] , true);
      } 
    }
  } 
}


dyn_string CMSfwDetectorProtection_getMaskedDpesForSystem(string systemName) {
    string dp = systemName + CMSfwDetectorProtection_generalConfigDp + ".mask.maskedDpes";
    if (! dpExistsDPE(dp)) return makeDynString();
    dyn_string masked;
    dpGet(dp, masked);
    return masked;
}

void CMSfwDetectorProtection_stripMasked(dyn_string& dps, dyn_string systems) {
  if (dynlen(dps) == 0) return;
  string sys; dyn_string exc;

  dyn_string maskedDpes;
  for (int i=1; i<= dynlen(systems); i++) {
      dynAppend(maskedDpes, CMSfwDetectorProtection_getMaskedDpesForSystem(systems[i]));
  }
  int index;
  for (int i=1; i<= dynlen(maskedDpes); i++) {
    index = dynContains(dps, maskedDpes[i]);
    if (index>0) dynRemove(dps, index);
  }    
}


/** 
  @param replydp reply dp of a condition (use * to query all conditions)
  @param systemName get affected data points in this system
  @param list list of strings of the form dpe = value
  @param exceptionInfo any exception is returned here
  @return 
*/
bool CMSfwDetectorProtection_getListAffectedDpes(string replydp, string systemName, dyn_string& list, dyn_string& exceptionInfo, bool stripMasked = false) {
  string inputdp;
  if (replydp == "*") {
      inputdp = "*";
  } else {
     inputdp = CMSfwDetectorProtection_convertToInputDp(replydp) + ".status";
     if (! dpExists(inputdp) ) {
          fwException_raise(exceptionInfo, "INPUT_DOES_NOT_EXISTS","Input condition dp " + inputdp + " does not exist",
		      "");
        return false;
     }
   }
  
  dyn_mixed object; 
  if (myManType() == UI_MAN) {
      if (shapeExists("txtProgress")) {
       	setValue("txtProgress", "text","Loading configuration for system " + systemName  );
      }  
    }
  CMSfwDetectorProtection_loadLocalConfiguration(object, exceptionInfo, systemName);
  if (dynlen(exceptionInfo)) return false;
 dyn_string dps;
  int count = 0;
  if (replydp == "*") {
    CMSfwDetectorProtection_computeIndexes(object,systemName);
    dps =  object[CMSfwDetectorProtection_OUTDPES];
    count = 1;
 } else { 


  for (int i=1; i<= dynlen(object[CMSfwDetectorProtection_INPUTDPES]); i++) {
    if (! object[CMSfwDetectorProtection_CONDITIONACTIVE][i]) {
      continue;
    }
    if ((inputdp == "*") || (object[CMSfwDetectorProtection_INPUTDPES][i] == inputdp)) {
      count++;
      dynAppend(dps, CMSfwDetectorProtection_getOutputDpes(object,i, false, systemName));

    }
  }  
  dynUnique(dps);
  }
  if (stripMasked) {
    CMSfwDetectorProtection_stripMasked(dps, makeDynString(systemName));
  }

  dyn_mixed values;
  if (dynlen(dps)>0) {
    dpGet(dps, values);
  }
  dynClear(list);
  for (int i=1; i<= dynlen(dps); i++) {
    list[i] = dps[i] + "=" + values[i];
  }  
  
  
  if (count == 0) {
    fwException_raise(exceptionInfo, "NO_CONDITION","No condition connected to " + inputdp + " on system " + systemName,"");
    return false;
  }
      if (myManType() == UI_MAN) {
      if (shapeExists("txtProgress")) {
	setValue("txtProgress", "text","");
      }  
    }

}

bool  CMSfwDetectorProtection_verifyRemote(string replydp, string systemName, dyn_string& problems, dyn_string& exceptionInfo) {
  string inputdp = CMSfwDetectorProtection_convertToInputDp(replydp) + ".status";
  dynClear(problems);
     

 
  if (! dpExists(inputdp) ) {
    fwException_raise(exceptionInfo, "INPUT_DOES_NOT_EXISTS","Input condition dp " + inputdp + " does not exist",
		      "");
    return false;
  }
  bool fired;     
  dpGet(inputdp, fired);
  if ( ! fired ) {
    fwException_raise(exceptionInfo, "NOT_FIRED","Condition not fired","");
    return false;
  }
     
  dyn_mixed object; 
  CMSfwDetectorProtection_loadLocalConfiguration(object, exceptionInfo, systemName);
  if (dynlen(exceptionInfo)) return false;
  
  dyn_string maskedDpes = CMSfwDetectorProtection_getMaskedDpesForSystem(systemName);
     

  int count; bool verifyResult = true; bool verify; int checkInvalid; 
     
  string dpIgnoreInvalid =  systemName + CMSfwDetectorProtection_generalConfigDp + ".ignoreInvalidBit";          
  if (dpExists(dpIgnoreInvalid)) {
    dpGet(dpIgnoreInvalid, checkInvalid);
    checkInvalid = 1-checkInvalid;
  } else {
    checkInvalid = 0; // old version did not check the invalid
  }

  for (int i=1; i<= dynlen(object[CMSfwDetectorProtection_INPUTDPES]); i++) {
    if (! object[CMSfwDetectorProtection_CONDITIONACTIVE][i]) {
      continue;
    }
    if (object[CMSfwDetectorProtection_INPUTDPES][i] == inputdp) {
      count++;
      verify = CMSfwDetectorProtection_verifyObject(object, i, false, problems, systemName, checkInvalid, maskedDpes);
      if (! verify) verifyResult = false;
    }
  }  
  if (count == 0) {
    fwException_raise(exceptionInfo, "NO_CONDITION","No condition connected to " + inputdp + " on system " + systemName,"");
    return false;
  }
    
  return verifyResult;
    
}

bool CMSfwDetectorProtection_isSubscribedFromSystem(string systemName, string replydp, dyn_string& exceptionInfo) {
  string inputdp = CMSfwDetectorProtection_convertToInputDp(replydp) + ".status";
  
  dyn_mixed object; 
  CMSfwDetectorProtection_loadLocalConfiguration(object, exceptionInfo, systemName);
  if (dynlen(exceptionInfo)) return false;
  int count = 0;
  for (int i=1; i<= dynlen(object[CMSfwDetectorProtection_INPUTDPES]); i++) {
    if (! object[CMSfwDetectorProtection_CONDITIONACTIVE][i]) {
      continue;
    }
    if (object[CMSfwDetectorProtection_INPUTDPES][i] == inputdp) {
      count++;
    }
  }
  return (count>0);  
}

bool CMSfwDetectorProtection_reply(string dp, bool reply) { 
  if (! dpExists(dp) ) {
    CMSfwDetectorProtection_debug1("Impossible to reply! Dp " + dp + " does not exist");  
    return false;
  }
  int mySys = getSystemId();
  CMSfwDetectorProtection_debug3("Replying " + reply + " in dp " + dp + " for system " + mySys);
  dpSet(dp + ".sys" + mySys,  reply,
        dp + ".sys" + mySys  + ":_original.._exp_inv" ,  false,
        dp + ".updated", getCurrentTime());
  return true;
}


string CMSfwDetectorProtection_convertToReplyOrInputDp(string dp, string type) {
  //  dp = dpSubStr(dp, DPSUB_SYS_DP); // does not work if dp does not exist
  int pos = strpos(dp, ".");
  if (pos > -1) dp = substr(dp, 0,pos );
  string sys;dyn_string exc;
  fwGeneral_getSystemName(dp, sys, exc); 
  fwDevice_getName(dp,dp, exc);
  return sys + "CMSfwDetectorProtection/" + type  +  "/" + dp;  
}

string CMSfwDetectorProtection_convertToReplyDp(string dp) {
  return CMSfwDetectorProtection_convertToReplyOrInputDp(dp, "Reply");
}

string CMSfwDetectorProtection_convertToInputDp(string dp) {
  return CMSfwDetectorProtection_convertToReplyOrInputDp(dp, "Input");
}

void CMSfwDetectorProtection_verifyLoop() {
  while (1) {
    delay(CMSfwDetectorProtection_currentObject[CMSfwDetectorProtection_VERIFY_FREQUENCY]);
    CMSfwDetectorProtection_verify(CMSfwDetectorProtection_currentObject, CMSfwDetectorProtection_maskedDpes);
  }
}

/** performs a dpSet for a list of datapoint elements of the same system

    note: one can be tempted to put an & and pass these values by reference 
    (even if they are not changed) to avoid reallocation
    however if you do so, for some unknown reason a runtime error happens
    so don't do it!
    Lorenzo July 13 09
*/
bool CMSfwDetectorProtection_dpSetMany(dyn_string dpes, dyn_anytype values) {
  if (dynlen(dpes)!=dynlen(values)) {
    CMSfwDetectorProtection_debug1("ERROR in CMSfwDetectorProtection_dpSetMany: number of dpes:"+dynlen(dpes)+
				   " and values:"+dynlen(values)+" does not match");
    return false;
  }
  if (dynlen(dpes) == 0) return true;    
  dyn_string exc;
  // i don't need dpSetManyDist because the dpes all belong to the local system
  fwConfigurationDB_dpSetMany(dpes, values,exc);
  if (dynlen(exc) > 0) {
    CMSfwDetectorProtection_debug1("Exception from   fwConfigurationDB_dpSetMany " + exc);
    return false;
  }
  return true;

}



/** performs a dpSet for a list of datapoint elements all to the same value
 *
 The parameter dpes could be passed by reference to avoid re-allocation but we don't (see note above)

*/
bool CMSfwDetectorProtection_dpSetAll(dyn_string dpes, anytype value) {
  dyn_anytype values;
  for (int i=1; i<= dynlen(dpes); i++) {
    values[i] = value;
  }

  return CMSfwDetectorProtection_dpSetMany(dpes, values);
}


/** performs a dpSet for the specified element in a list of datapoints all at the same value
 */
bool CMSfwDetectorProtection_dpMassSet(dyn_string dps, string element, anytype value) {
  for (int i=1; i<= dynlen(dps); i++) {
    dps[i] += element; 
  }
  
  return CMSfwDetectorProtection_dpSetAll(dps, value);
}

bool CMSfwDetectorProtection_setLocked(dyn_string dpes, int locked) {
  // in a passive system it is possible to set lock to false, but better to avoid that!
  if ((! locked) && (fwInstallationRedu_isPassive())) return true;
  return CMSfwDetectorProtection_dpMassSet(dpes,":_lock._original._locked",locked);
}

dyn_int CMSfwDetectorProtection_getLocked(dyn_string dpes) {
  if (dynlen(dpes) == 0) return makeDynInt();
  for (int i=1; i<= dynlen(dpes); i++) {
    dpes[i] +=  ":_lock._original._locked";
  } 
  dyn_int locked;
  dpGet(dpes, locked);
  return locked;
}


string CMSfwDetectorProtection_summaryObject(dyn_mixed& object) {
  string res;
  res = ("Debug level: " + object[CMSfwDetectorProtection_DEBUGLEVEL] + "\n");
  res += "Verify frequency: " + object[CMSfwDetectorProtection_VERIFY_FREQUENCY] + 
    "\n\n";  
  for (int i=1; i<= dynlen(object[CMSfwDetectorProtection_CONDITIONNAME]); i++) {
    res +=  CMSfwDetectorProtection_summaryCondition(object,i) ;             
  }  
  return res;
}

string CMSfwDetectorProtection_summaryCondition(dyn_mixed& object, int i, bool include_index = true) {
  string res = "*****************************\nCondition " + ((include_index)?i:"") + ":" + object[CMSfwDetectorProtection_CONDITIONNAME][i] + "\n";
  dyn_string modenames = makeDynString("Dpes","Tree Cache","User function","DP Names","DP Aliases");
    
  res += "Active: " + object[CMSfwDetectorProtection_CONDITIONACTIVE][i] + "\n";
  res += "Type: "  + object[CMSfwDetectorProtection_CONDITIONTYPE][i] + "\n";
    
  int delayTime = object[CMSfwDetectorProtection_DELAY][i] + "\n";
    
  if (delayTime > 0) {
    res += "Delay before executing action: " + delayTime + " seconds\n";
  }
    
    
  int timeout = object[CMSfwDetectorProtection_DISCONNECTED_TIMEOUT][i] + "\n";
    
  if (timeout == -1) {
    res += "Timeout for disconnection of system disabled \n"; 
  } else {
    res += "Timeout: condition is fired when system is disconnected for  " + timeout + " seconds\n";
  }
    
    
  res += "\n == INPUT == \n";
    
  res += "Condition " + object[CMSfwDetectorProtection_INPUTDPES][i] + "\n";
    
  int pureMode = CMSfwDetectorProtection_getPureMode(object[CMSfwDetectorProtection_OUTPUTMODE][i]);
  res += "\n == OUTPUT == \n";
  res += "Mode: " + modenames[pureMode] + "\n";
  if (object[CMSfwDetectorProtection_OUTPUTMODE][i]>100) res += "Preprocess: true\n";
    
  switch (pureMode) {
  case CMSfwDetectorProtection_MODE_DPES:
    res += "Output DPEs: " + object[CMSfwDetectorProtection_OUTPUTDPES][i] + "\n";
    break;
  case CMSfwDetectorProtection_MODE_TREECACHE:
    res += "Tree Cache Top Node:" +  object[CMSfwDetectorProtection_TREECACHETOPNODE][i] + "\n";
    res += "Top Node:" +  object[CMSfwDetectorProtection_TOPNODE][i] + "\n";
    res += "Act on DUs: ";
    for (int k=1; k<= dynlen(object[CMSfwDetectorProtection_DUTYPE][i]); k++) {
      res += object[CMSfwDetectorProtection_DUTYPE][i][k] + "/" + object[CMSfwDetectorProtection_DPELEMENT][i][k] + " " ;
    }
    res +="\n";
    break;
  case CMSfwDetectorProtection_MODE_USERFUNCTION:
    res += "User function: " + object[CMSfwDetectorProtection_USERFUNCTION][i] + "\n";
    break;                
  case CMSfwDetectorProtection_MODE_DPNAMES:         
  case CMSfwDetectorProtection_MODE_DPALIASES: 
    res += "Prefix: " + object[CMSfwDetectorProtection_TOPNODE][i] + "\n";
    res += "Act on types: ";
    for (int k=1; k<= dynlen(object[CMSfwDetectorProtection_DUTYPE][i]); k++) {
      res += object[CMSfwDetectorProtection_DUTYPE][i][k] + "/" + object[CMSfwDetectorProtection_DPELEMENT][i][k] + " " ;
    }        
    res +="\n";
    break;       
  }
  if (object[CMSfwDetectorProtection_OUTPUTVALUE_USERFUNCTION][i] == "") {
    res += "Set to value: " +   object[CMSfwDetectorProtection_OUTPUTVALUE][i] + "\n";
  } else {
    res += "Set to result of the user function : \n" + object[CMSfwDetectorProtection_OUTPUTVALUE_USERFUNCTION][i]  + "\n";                 
  }
  if (strlen(object[CMSfwDetectorProtection_PREPOST_USERFUNCTION][i])>0) {
    res += "\n == USER FUNCTIONS CALLED WHEN THE CONDITION IS FIRED / GONE == \n";
    res += object[CMSfwDetectorProtection_PREPOST_USERFUNCTION][i] + "\n"; 
  }
    
  res += "\n == VERIFY == \n";
    
  if (! object[CMSfwDetectorProtection_ENABLEVERIFY][i]) {
    res += "Disabled\n";
    return res; 
  }
    
  res += "Delay before verifying: " +  object[CMSfwDetectorProtection_VERIFY_DELAY][i] + " s\n";
  if ((dynlen(object[CMSfwDetectorProtection_VERIFY_USERFUNCTION]) >= i) && (strlen(object[CMSfwDetectorProtection_VERIFY_USERFUNCTION][i]) > 0)) {
    res += "Using custom verify function: \n" +   object[CMSfwDetectorProtection_VERIFY_USERFUNCTION][i] + "\n";
  } else {
    switch (pureMode) {
    case CMSfwDetectorProtection_MODE_DPES:
      res += "Verify DPEs: " + object[CMSfwDetectorProtection_VERIFY_DPES][i] + "\n";
      break;
    case CMSfwDetectorProtection_MODE_TREECACHE:
      res += "Tree Cache Top Node:" +  object[CMSfwDetectorProtection_TREECACHETOPNODE][i] + "\n";
      res += "Top Node:" +  object[CMSfwDetectorProtection_TOPNODE][i] + "\n";
      res += "Verify DUs: ";
      for (int k=1; k<= dynlen(object[CMSfwDetectorProtection_DUTYPE][i]); k++) {
	res += object[CMSfwDetectorProtection_DUTYPE][i][k] + "/" + object[CMSfwDetectorProtection_VERIFY_DPELEMENT][i][k];
      }
      res +="\n";
      break;
    case CMSfwDetectorProtection_MODE_USERFUNCTION:
      res += "User function with third parameter = true is used to get the verify elements: " + object[CMSfwDetectorProtection_USERFUNCTION][i] + "\n";
      break;                
    }  
    res += "Function to check the elements: \n" + object[CMSfwDetectorProtection_VERIFY_FUNCTION][i] + "\n";
    
  }
  dyn_string properties, exc;
  CMSfwDetectorProtection_getConditionCustomProperties(object, object[CMSfwDetectorProtection_CONDITIONNAME][i], properties, exc);
  if (dynlen(properties)>0) res += "\n== CUSTOM PROPERTIES ==\n";
  for (int p=1; p<= dynlen(properties); p++) {
    res += properties[p] + "\n";
  }
  return res;
}  


/////


// For convenience - accessors to the object with functions - mutators are not needed

   
// List of conditions
dyn_string CMSfwDetectorProtection_conditionName(dyn_mixed& object) {
  return (dyn_string) object[CMSfwDetectorProtection_CONDITIONNAME];
}  

 

// Inputs in the matrix
dyn_string CMSfwDetectorProtection_inputDpes(dyn_mixed& object) {
  return (dyn_string) object[CMSfwDetectorProtection_INPUTDPES];
}   


// Status of the condition
dyn_bool CMSfwDetectorProtection_fired(dyn_mixed& object) {
  return (dyn_bool) object[CMSfwDetectorProtection_FIRED];
}   
dyn_bool CMSfwDetectorProtection_changed(dyn_mixed& object) {
  return (dyn_bool) object[CMSfwDetectorProtection_CHANGED];
}   

// Output of the matrix

dyn_int CMSfwDetectorProtection_outputMode(dyn_mixed& object) {
  return (dyn_int) object[CMSfwDetectorProtection_OUTPUTMODE];
}   

// Mode  DPEs
dyn_dyn_string CMSfwDetectorProtection_outputDpes(dyn_mixed& object) {
  return (dyn_dyn_string) object[CMSfwDetectorProtection_OUTPUTDPES];
}   

// Mode  treeCache
dyn_string CMSfwDetectorProtection_topNode(dyn_mixed& object) {
  return (dyn_string) object[CMSfwDetectorProtection_TOPNODE];
}   

dyn_dyn_string CMSfwDetectorProtection_duType(dyn_mixed& object) {
  return (dyn_dyn_string) object[CMSfwDetectorProtection_DUTYPE];
}   

dyn_dyn_string CMSfwDetectorProtection_dpElement(dyn_mixed& object) {
  return (dyn_dyn_string) object[CMSfwDetectorProtection_DPELEMENT];
}   
dyn_string CMSfwDetectorProtection_treeCacheTopNode(dyn_mixed& object) {
  return (dyn_string) object[CMSfwDetectorProtection_TREECACHETOPNODE];
}   

// Mode user function
dyn_string CMSfwDetectorProtection_userFunction(dyn_mixed& object) {
  return (dyn_string) object[CMSfwDetectorProtection_USERFUNCTION];
}   

// Output (common to all modes)

dyn_mixed CMSfwDetectorProtection_outputValue(dyn_mixed& object) {
  return (dyn_mixed) object[CMSfwDetectorProtection_OUTPUTVALUE];
}   

dyn_bool CMSfwDetectorProtection_conditionActive(dyn_mixed& object) {
  return (dyn_bool) object[CMSfwDetectorProtection_CONDITIONACTIVE]; 
}

/** Reply functions **/

void CMSfwDetectorProtection_setToInvalid(string replydp, int sysnumber) {
  replydp = dpSubStr(replydp, DPSUB_SYS_DP);
  dpSet(replydp + ".sys" + sysnumber + ":_original.._exp_inv", true);
  if (dpExists(replydp + ".log")) {
      dyn_string logMsg;
      dpGet(replydp + ".log", logMsg);
      dynInsertAt(logMsg, ((string) getCurrentTime()) + ": "  + "Removing system " + sysnumber + " (" + getSystemName(sysnumber) + ") from the systems to wait for",1);
      dpSet(replydp + ".log", logMsg);
  }
  dpSet(replydp + ".updated", true);
}

dyn_string CMSfwDetectorProtection_getValidDpes(string replydp) {
  replydp = dpSubStr(replydp, DPSUB_SYS_DP);
  dyn_string els = dpNames(replydp + ".sys*", CMSfwDetectorProtection_replyType);
  dyn_string el_invalid;
  dyn_bool invalid;
  for (int i=1; i<= dynlen(els); i++) {
    el_invalid[i] = els[i] + ":_original.._invalid"; 
  }
  dpGet(el_invalid, invalid);
    
  for (int i= dynlen(els); i>0; i--) {
    if (invalid[i]) dynRemove(els, i);        
  }
  return els;
        
}  

bool CMSfwDetectorProtection_wait(string replydp, int delaytime = 30, int timeout = 1200, int startTimeTolerance = 10, bool debug = false) {
  replydp = dpSubStr(replydp, DPSUB_SYS_DP);
  dyn_string els = CMSfwDetectorProtection_getValidDpes(replydp);
  if (debug) DebugTN(dynlen(els) + " valid elements found");
  dyn_string el_timestamp;

  dyn_time ts;
        
  time startTime = getCurrentTime()- startTimeTolerance;  
        
  for (int i=1; i<= dynlen(els); i++) {
    el_timestamp = els[i] + ":_original.._stime";
  }

    
  int elapsed = 0;
  bool success= false;
  dyn_bool result;
  int count;
  while (1) {
    if (elapsed > timeout) break;
    delay(delaytime);
    elapsed += delaytime;
    if (debug) DebugTN("Getting replies");
    dpGet(els, result,
	  el_timestamp, ts);
    count = 0;
    for (int i=1; i<= dynlen(els); i++) {
      if (result[i] && (ts[i]>startTime)) count++;
    }
    if (debug) DebugTN(count + "/" + dynlen(els) + " OK");
    if (count == dynlen(els)) {
      if (debug) DebugTN("Success");
      success=true;
      break; 
    }
        
  }
    
  return success;    
}

string CMSfwDetectorProtection_getSystemNameFromReplyDpe(string replydpe) {
  string replydp = dpSubStr(replydpe, DPSUB_SYS_DP);
  strreplace(replydpe, replydp + ".sys", "");
  return getSystemName((int) replydpe);     
}

bool CMSfwDetectorProtection_checkReply(string replydp, dyn_string sysNames = makeDynString()) {
  replydp = dpSubStr(replydp, DPSUB_SYS_DP);
  dyn_string els = CMSfwDetectorProtection_getValidDpes(replydp);
  dyn_bool result;
  dyn_int sysNumbers; int num;
  for (int i=1; i<= dynlen(sysNames); i++) {
    num = getSystemId(sysNames[i]);
    if (num > 0) {
      dynAppend(sysNumbers, num); 
    }
  }
       
  string numStr;
  if (dynlen(sysNumbers) > 0) {
    for (int i= dynlen(els); i>0; i--) {
      numStr= els[i];
      strreplace(numStr, replydp + ".sys", "");
      num = (int) numStr;
      if (! dynContains(sysNumbers, num) ) {
	dynRemove(els,i); 
      }
    }
  }
  if (dynlen(els)==0) return true;
    
  dpGet(els, result);
  time t = getCurrentTime();
  
  for (int i=1; i<= dynlen(result); i++) {  
    if (! result[i] ) return false;
    if (! CMSfwDetectorProtection_isManagerRunning(CMSfwDetectorProtection_getSystemNameFromReplyDpe(els[i]), t) ) return false;
  }
  return true;
  
}

bool CMSfwDetectorProtection_isManagerRunning(string systemName, time t = getCurrentTime()) {
  string dpe  = CMSfwDetectorProtection_getActiveCtrlManager(systemName) + ".aliveTime";

  if (! dpExists(dpe) ) return false;   
  time aliveTime;
  dpGet(dpe, aliveTime);
  return ((period(t) - period(aliveTime)) <= 120);
   
 
} 
void CMSfwDetectorProtection_setAlertForInput(string inputdp, dyn_string& exceptionInfo, string alertClass = "_fwFatalNack.") {
  if (! dpExists(inputdp) ) {
    fwException_raise(exceptionInfo, "DP_NOT_EXISTING", inputdp + " dp does not exist",""); 
    return;
  }
  
  inputdp = dpSubStr(inputdp, DPSUB_SYS_DP);
  
  if (dpTypeName(inputdp) != CMSfwDetectorProtection_inputType) {
    fwException_raise(exceptionInfo, "WRONG_TYPE", inputdp + " should be of type " + CMSfwDetectorProtection_inputType,""); 
    return;    
  }
  
  fwAlertConfig_setDigital(inputdp + ".status", makeDynString("", CMSfwDetectorProtection_getInputDescription(inputdp)), makeDynString("", alertClass),
                           "CMSfwDetectorProtection/view_input.pnl",makeDynString("$sDpName:" + inputdp),"", exceptionInfo);
  
  fwAlertConfig_activate(inputdp + ".status", exceptionInfo);
    
}

void CMSfwDetectorProtection_deleteAlertForInput(string inputdp, dyn_string& exceptionInfo, string alertClass = "_fwFatalNack.") {
  if (! dpExists(inputdp) ) {
    fwException_raise(exceptionInfo, "DP_NOT_EXISTING", inputdp + " dp does not exist",""); 
    return;
  }
  
  inputdp = dpSubStr(inputdp, DPSUB_SYS_DP);
  
  if (dpTypeName(inputdp) != CMSfwDetectorProtection_inputType) {
    fwException_raise(exceptionInfo, "WRONG_TYPE", inputdp + " should be of type " + CMSfwDetectorProtection_inputType,""); 
    return;    
  }
  
  
  fwAlertConfig_deleteDigital(inputdp + ".status", exceptionInfo);
    
}


dyn_string CMSfwDetectorProtection_getRequiredPrivileges(string systemName) {
  dyn_string requiredPrivileges; 

  string priv_dpe = systemName + CMSfwDetectorProtection_generalConfigDp + ".accessControl.requiredPrivileges";
  if (! dpExists(priv_dpe)) return makeDynString();
   dpGet(priv_dpe, requiredPrivileges);
   return requiredPrivileges;
}
bool CMSfwDetectorProtection_hasRequiredPrivileges(string systemName) {
  if (myManType() != UI_MAN) return true;
  string userName;
  fwAccessControl_getUserName(userName);
  if (userName == "root") return true;

  dyn_string requiredPrivileges; 

  string priv_dpe = systemName + CMSfwDetectorProtection_generalConfigDp + ".accessControl.requiredPrivileges";
  if (! dpExists(systemName + CMSfwDetectorProtection_managerDp) ) {
      return false; // system is not connected
  }
  if (! dpExists(priv_dpe)) return true; // system uses old version without access control

  dpGet(priv_dpe, requiredPrivileges);

  if (dynlen(requiredPrivileges) == 0) return true;

  
    dyn_string exceptionInfo;
    bool hasPrivilege;
    for (int i=1; i<= dynlen(requiredPrivileges); i++) {
      
      // check if current user has privilege level "Modify"
      fwAccessControl_isGranted(requiredPrivileges[i], hasPrivilege, exceptionInfo);

      if (hasPrivilege) return true;
      
      
    }

    
    return (false) ;
}

bool CMSfwDetectorProtection_setRequiredPrivileges(string systemName, dyn_string requiredPrivileges) {
  string priv_dpe = systemName + CMSfwDetectorProtection_generalConfigDp;
  
  if (! dpExists(priv_dpe)) {
      dyn_string exc;
      CMSfwDetectorProtection_createDp(priv_dpe ,CMSfwDetectorProtection_managerType, exc);
      if (dynlen(exc)>0) return false;      
  }
  priv_dpe +=   ".accessControl.requiredPrivileges";

  dpSet(priv_dpe, requiredPrivileges);
  return true;
}


dyn_string CMSfwDetectorProtection_findUnsubscribedAndValidReplies(string systemName, dyn_string& exceptionInfo) {
    int sysNumber = getSystemId(systemName);
    if (sysNumber == -1) {
        fwException_raise(excdeptionInfo, "SYS_INVALID", "System Id for " + systemName + " not found","");
        return;
    }
    dyn_string replydps = dpNames("*:*", CMSfwDetectorProtection_replyType);
    dyn_dyn_mixed obj;
    dyn_string result = makeDynString();
    
    CMSfwDetectorProtection_loadLocalConfiguration(obj, exceptionInfo, systemName);
    if (dynlen(exceptionInfo)>0) return;
    bool invalid; string inputdp; int count =0;
 //   DebugN("Checking if valid in ", replydps);
    for (int i=1; i<= dynlen(replydps); i++) {
      dpGet(replydps[i] + ".sys" + sysNumber + ":_original.._exp_inv", invalid);

      if (! invalid) {
   //       DebugN(replydps[i] +  ".sys" + sysNumber + " is valid");
          inputdp = CMSfwDetectorProtection_convertToInputDp(replydps[i]) + ".status";
          count = 0;
          for (int j=1; j<= dynlen(obj[CMSfwDetectorProtection_INPUTDPES]); j++) {
            if (! obj[CMSfwDetectorProtection_CONDITIONACTIVE][j]) {
              continue;
             }
            if (obj[CMSfwDetectorProtection_INPUTDPES][j] == inputdp) {
              count++;
            }
          }
     //     DebugN(inputdp + " subscribed " + count + " times in system " + systemName); 
          if (count == 0) {
              dynAppend(result, replydps[i]);
          }
    }
  }
  
  return result;  
}
        

void CMSfwDetectorProtection_remapSystemToComponent(dyn_mixed& object, string from, string to) {
  string sys; dyn_string exc; string input;
  for (int i=1; i<= dynlen(object[CMSfwDetectorProtection_INPUTDPES]); i++) {
     fwGeneral_getSystemName(object[CMSfwDetectorProtection_INPUTDPES][i], sys, exc); 
     if (sys == from) {
       fwGeneral_getNameWithoutSN(object[CMSfwDetectorProtection_INPUTDPES][i], input, exc);
       object[CMSfwDetectorProtection_INPUTDPES][i] = to + input;
     }
  }
}

void CMSfwDetectorProtection_remapSystemsToComponents(string systemName, dyn_string systems, dyn_string components, dyn_string& exc) {
  if (dynlen(systems) != dynlen(components)) {
      fwException_raise(exc, "WRONG_PAR","Systems and components must have the same length",""); return;
  }
    dyn_string configDps = dpNames(systemName + "*", CMSfwDetectorProtection_configType);
    dyn_mixed obj; bool active;
    for (int i=1; i<= dynlen(configDps); i++) {
        CMSfwDetectorProtection_loadFromDp(obj, configDps[i], exc, false);
        for (int j=1; j<= dynlen(systems); j++) {
          CMSfwDetectorProtection_remapSystemToComponent(obj, systems[j], "{" + components[j] + "}:");
        }
        dpGet(configDps[i] + ".config.active", active);
        CMSfwDetectorProtection_saveToDp(obj, exc,active);
    }
}

    
dyn_string CMSfwDetectorProtection_getInstalledComponents(string systemName)
{
  // freely adapted from fwInstallation
  dyn_string dynComponentNames;
  dyn_string systemName_Component;
  dyn_string dataPointTypes;

  string componentName;
  int i;	
  dyn_string ds;
  unsigned systemId;
 
  if(systemName == ""){
    systemName = getSystemName();    
  }else if(!patternMatch("*:", systemName))
  {
    systemName += ":";
  } 
  
  systemId = getSystemId(systemName);
  
   
  // get existing data point types
  dataPointTypes = dpTypes("*", systemId);
	
  // check whether the "_FwInstallationComponents" dpt exists
  if(dynContains(dataPointTypes, "_FwInstallationComponents") > 0)
  {
    // get the names of all installed components
    dynComponentNames = dpNames(systemName + "*", "_FwInstallationComponents");


    // remove datapoints related to redundant systems
       for ( i = dynlen(dynComponentNames); i >0 ; i--)
    {
           if (substr(dynComponentNames[i],	strlen(dynComponentNames[i])-2,2) == "_2") {
               dynRemove(dynComponentNames,i);
           }
         
     }	
    for ( i = 1; i <= dynlen(dynComponentNames); i++)
    {
			
			// remove the system name from the component name
			dynComponentNames[i] = dpSubStr( dynComponentNames[i], DPSUB_DP );
			
			// delete the fwInstallation_ prefix from the component name
			strreplace(dynComponentNames[i], "fwInstallation_" , "");		
		
	   }
  }
  return 	dynComponentNames;
		
	
}

string CMSfwDetectorProtection_codeToCreateSystem(string systemName="") {
  if (systemName == "") systemName = getSystemName();
  dyn_string dps = dpNames(systemName + "*", CMSfwDetectorProtection_configType);


  dyn_string exc;
  string res = "";
  dyn_mixed obj;
  for (int i=1; i<= dynlen(dps); i++) {
    CMSfwDetectorProtection_loadFromDp(obj, dps[i], exc, false);
    if (dynlen(exc)>0) {
      DebugN(exc);
      return exc;
    } else {
      res += CMSfwDetectorProtection_codeToCreateObject(obj, (i==1),false);
    }
  }
  
  string priv_dpe = systemName + CMSfwDetectorProtection_generalConfigDp + ".accessControl.requiredPrivileges";
  dyn_string privileges = CMSfwDetectorProtection_getRequiredPrivileges(systemName);
  
  if ( dynlen(privileges)>0) {
      res+="\n" + "CMSfwDetectorProtection_setRequiredPrivileges(" + "\"\"," + CMSfwDetectorProtection_getMakeDynStringCode(privileges) + ");\n";
  }
  res += "DebugN(\"Detector Protection configured. Exceptions=\",exc);\n";
  res+="}";

  return res;
}

string CMSfwDetectorProtection_codeToCreateObject(dyn_mixed& object, bool addStart = true, bool addEnd=true) {
  string res = "";
  dyn_string exc;
  if (addStart) {
    res += "#uses \"CMSfwDetectorProtection/CMSfwDetectorProtection.ctl\"\n\n";
    res += "void configureProtection() {\n";
    res += "dyn_mixed obj; ";
    res += "string name;\n";
    res += "dyn_string exc;\n";
  } 

  string dp = object[CMSfwDetectorProtection_CONFIGDP];
  fwGeneral_getNameWithoutSN(dp,dp,exc);

  res += "\n\n//CONFIG DP " + dp + "\n";
  
  if (!addStart) {
    res += "dynClear(obj);\n";
  }

  res += "CMSfwDetectorProtection_initObject(obj);\n";
  res += ("CMSfwDetectorProtection_setDebugLevel(obj," + object[CMSfwDetectorProtection_DEBUGLEVEL] + ");\n");
  
  res += "CMSfwDetectorProtection_setVerifyFrequency(obj, " + object[CMSfwDetectorProtection_VERIFY_FREQUENCY] + 
    ");\n\n";  
  for (int i=1; i<= dynlen(object[CMSfwDetectorProtection_CONDITIONNAME]); i++) {
    res +=  CMSfwDetectorProtection_codeToCreateCondition(object,i) ;             
  }  

  res += "\nCMSfwDetectorProtection_setConfigDp(obj,\"" + dp + "\");\n";
  bool active = true;
  if (dpExists(object[CMSfwDetectorProtection_CONFIGDP]))
    dpGet(object[CMSfwDetectorProtection_CONFIGDP] + ".config.active", active);

  res +="CMSfwDetectorProtection_saveToDp(obj,exc" + ((active)?"":",false") + ");\n\n";
  if (addEnd) {
    res += "}";
  }
  return res;
}



string CMSfwDetectorProtection_getStringRepresentationForType(int type) {
  switch (type) {
   case DPEL_FLOAT: return "DPEL_FLOAT";
   case DPEL_BOOL: return "DPEL_BOOL";
   case DPEL_INT: return "DPEL_INT";
   case DPEL_CHAR: return  "DPEL_CHAR";
   case DPEL_STRING: return   "DPEL_STRING" ;
  } 
  return type;
}
string CMSfwDetectorProtection_codeToCreateCondition(dyn_mixed& object, int i) {
  string res ="";
  string name =   object[CMSfwDetectorProtection_CONDITIONNAME][i] ;
  string objname = "obj,name,";
  string excadd = ",exc);\n";
  //  dyn_string modenames = makeDynString("Dpes","Tree Cache","User function","DP Names","DP Aliases");
  
  res+="\n//Condition " + name + "\n";
  res +="name=\"" + name + "\";\n";

  res += "CMSfwDetectorProtection_addCondition(" + objname + substr(excadd,1); 
  if (! object[CMSfwDetectorProtection_CONDITIONACTIVE][i]) {
    res += "CMSfwDetectorProtection_setActive(" + objname + "false" + excadd;
  }
  
  res += "CMSfwDetectorProtection_setConditionType( " + objname   + "\"" +  object[CMSfwDetectorProtection_CONDITIONTYPE][i]+ "\"" +excadd;
    
  int delayTime = object[CMSfwDetectorProtection_DELAY][i] + "\n";
    
  if (delayTime > 0) {
    res += "CMSfwDetectorProtection_setDelay( " + objname + delayTime + excadd;
  }
    
    
  int timeout = object[CMSfwDetectorProtection_DISCONNECTED_TIMEOUT][i] + "\n";
    
  if (timeout != -1) {
    res += "CMSfwDetectorProtection_setTimeout(" + objname + timeout +excadd;
  }
    
  string inputdp = object[CMSfwDetectorProtection_INPUTDPES][i];
  inputdp = substr(inputdp, 0, strlen(inputdp) - 7);
  
  res += "CMSfwDetectorProtection_setInput(" + objname + "\"" +  inputdp + "\"" + excadd;
    
  int pureMode = CMSfwDetectorProtection_getPureMode(object[CMSfwDetectorProtection_OUTPUTMODE][i]);
  bool preprocess = (object[CMSfwDetectorProtection_OUTPUTMODE][i]>=100);

    
  string valueStrValueType = "," + "\"" + object[CMSfwDetectorProtection_OUTPUTVALUE][i] +"\"" +  "," + CMSfwDetectorProtection_getStringRepresentationForType(object[CMSfwDetectorProtection_OUTPUTVALUETYPE][i]) ;
  string pureModeStr;
  switch (pureMode) {
  case CMSfwDetectorProtection_MODE_DPES:
    res += "CMSfwDetectorProtection_setOutputModeDpes(" + objname +  CMSfwDetectorProtection_getMakeDynStringCode(object[CMSfwDetectorProtection_OUTPUTDPES][i]) + valueStrValueType + excadd; 
    break;
  case CMSfwDetectorProtection_MODE_TREECACHE:
    res += "CMSfwDetectorProtection_setOutputModeTreeCache(" + objname +"\"" +  object[CMSfwDetectorProtection_TOPNODE][i]  +"\"" +  "," + "\"" +  object[CMSfwDetectorProtection_TREECACHETOPNODE][i] +"\"" +  "," + CMSfwDetectorProtection_getMakeDynStringCode( object[CMSfwDetectorProtection_DUTYPE][i])  + "," + CMSfwDetectorProtection_getMakeDynStringCode(object[CMSfwDetectorProtection_DPELEMENT][i]) + valueStrValueType + ", " + preprocess + excadd ;
    break;
  case CMSfwDetectorProtection_MODE_USERFUNCTION:
    res += "CMSfwDetectorProtection_setOutputModeUserFunction(" + objname +  CMSfwDetectorProtection_escapeString(object[CMSfwDetectorProtection_USERFUNCTION][i])  +  valueStrValueType + ", " + preprocess + excadd ;
    break;                
  case CMSfwDetectorProtection_MODE_DPNAMES:         
  case CMSfwDetectorProtection_MODE_DPALIASES: 
    pureModeStr = (pureMode == CMSfwDetectorProtection_MODE_DPNAMES)?"CMSfwDetectorProtection_MODE_DPNAMES":"CMSfwDetectorProtection_MODE_DPALIASES";
    res += "CMSfwDetectorProtection_setOutputModeDpNamesOrAliases(" + objname   + pureModeStr + ","+ "\"" + 
     object[CMSfwDetectorProtection_TOPNODE][i] + "\"" +  "," + CMSfwDetectorProtection_getMakeDynStringCode( object[CMSfwDetectorProtection_DUTYPE][i])  + "," + CMSfwDetectorProtection_getMakeDynStringCode(object[CMSfwDetectorProtection_DPELEMENT][i]) + valueStrValueType + ", " + preprocess + excadd ;;
    break;       
  }
  if (object[CMSfwDetectorProtection_OUTPUTVALUE_USERFUNCTION][i] != "") {
    res += "CMSfwDetectorProtection_setOutputValueUserFunction(" + objname   + CMSfwDetectorProtection_escapeString(object[CMSfwDetectorProtection_OUTPUTVALUE_USERFUNCTION][i]) + excadd;                 
  }
  if (strlen(object[CMSfwDetectorProtection_PREPOST_USERFUNCTION][i])>0) {
    
    res += "CMSfwDetectorProtection_setPrePostUserFunction(" + objname +   CMSfwDetectorProtection_escapeString(object[CMSfwDetectorProtection_PREPOST_USERFUNCTION][i]) +  excadd; 
  }


  dyn_string properties, exc;
  CMSfwDetectorProtection_getConditionCustomProperties(object, object[CMSfwDetectorProtection_CONDITIONNAME][i], properties, exc);
  if (dynlen(properties) >0) {
    res += "CMSfwDetectorProtection_setConditionCustomProperties(" + objname + CMSfwDetectorProtection_getMakeDynStringCode(properties) + excadd;
  }

  if ((dynlen(object[CMSfwDetectorProtection_INFOFUNCTION]) >= i) && (strlen(object[CMSfwDetectorProtection_INFOFUNCTION][i])>0)) {
    res +="CMSfwDetectorProtection_setInfoFunction(" + objname + CMSfwDetectorProtection_escapeString(object[CMSfwDetectorProtection_INFOFUNCTION][i]) + excadd;
  }
    
  if (! object[CMSfwDetectorProtection_ENABLEVERIFY][i]) {
    return res; 
  }
  

  string verifDelayExc = "," + object[CMSfwDetectorProtection_VERIFY_DELAY][i] + excadd;

  if ((dynlen((object[CMSfwDetectorProtection_VERIFY_USERFUNCTION]))>=i) && (strlen(object[CMSfwDetectorProtection_VERIFY_USERFUNCTION][i]) > 0)) {
    res += "CMSfwDetectorProtection_setVerifyCustomVerifyFunction(" + objname +   CMSfwDetectorProtection_escapeString(object[CMSfwDetectorProtection_VERIFY_USERFUNCTION][i]) + verifDelayExc;
  } else {
    switch (pureMode) {
    case CMSfwDetectorProtection_MODE_DPES:
      res += "CMSfwDetectorProtection_setVerifyModeDpes("  + objname +  + CMSfwDetectorProtection_getMakeDynStringCode(object[CMSfwDetectorProtection_VERIFY_DPES][i]) + "," + CMSfwDetectorProtection_escapeString(object[CMSfwDetectorProtection_VERIFY_FUNCTION][i]) +  verifDelayExc;
      break; 
    case CMSfwDetectorProtection_MODE_TREECACHE:
    case CMSfwDetectorProtection_MODE_DPNAMES:         
    case CMSfwDetectorProtection_MODE_DPALIASES: 
      res += "CMSfwDetectorProtection_setVerifyModeTreeCache(" + objname +   CMSfwDetectorProtection_getMakeDynStringCode(object[CMSfwDetectorProtection_VERIFY_DPELEMENT][i]) + "," +   CMSfwDetectorProtection_escapeString(object[CMSfwDetectorProtection_VERIFY_FUNCTION][i]) +  verifDelayExc;    
      break;
    case CMSfwDetectorProtection_MODE_USERFUNCTION:     
      res += "CMSfwDetectorProtection_setVerifyModeUserFunction(" + objname + CMSfwDetectorProtection_escapeString(object[CMSfwDetectorProtection_VERIFY_FUNCTION][i]) + verifDelayExc;

    }  
    
  }

  return res;
}

void CMSfwDetectorProtection_getInputDpConfig(string inputdp, string& dpe, string& function, langString& description) {
  dyn_string param;
  inputdp = dpSubStr(inputdp, DPSUB_SYS_DP);
  dpe= "";
  dpGet(inputdp + ".status:_dp_fct.._param", param,
        inputdp+ ".status:_dp_fct.._fct", function);
  if (dynlen(param)>0) {
     dpe = dpSubStr(param[1], DPSUB_SYS_DP_EL);
  }
  description = CMSfwDetectorProtection_getInputDescription(inputdp );
}


string CMSfwDetectorProtection_codeToCreateAllInputDps(dyn_string systemName) {
    dyn_string dps = dpNames(systemName + "*", CMSfwDetectorProtection_inputType);
    string res = "";
    for (int i=1; i<= dynlen(dps); i++) {
      res += CMSfwDetectorProtection_codeToCreateInputDp(dps[i], (i==1), (i==dynlen(dps)));
    }  
    return res;
}

string CMSfwDetectorProtection_codeToCreateInputDp(string inputdp, bool addStart=true, bool addEnd= true) {
    string res;
    if (! dpExists(inputdp)) return "";
    if (dpTypeName(inputdp) != CMSfwDetectorProtection_inputType) return "";
    string dpe, function; string description;
    CMSfwDetectorProtection_getInputDpConfig(inputdp, dpe, function,description);
    string name;dyn_string exc;
    strreplace(function,"\"","\\" + "\"");
    

    fwDevice_getName( dpSubStr(inputdp,DPSUB_DP), name, exc);
    if (addStart) {
      res = "void configureInputCond() {\n";
      res += "dyn_string exc;\n";    
    }
    
    fwGeneral_getNameWithoutSN(dpe, dpe, exc);
    
    res+="CMSfwDetectorProtection_createInput(\""+  name + "\", \"" +  dpe + "\",\"" +  function + "\", exc" + ",\"" + description + "\");\n" ;
    if (addEnd) {
      res += "}";     
    }
    return res;
}

string CMSfwDetectorProtection_getMakeDynStringCode(dyn_string ds) {
  string res = "makeDynString(";
  for (int i=1; i<= dynlen(ds); i++) {
    res +="\"" + ds[i] + "\"";
    if (i<dynlen(ds)) res +=",";
  }
  res+=")";
  return res;
}

string CMSfwDetectorProtection_escapeString(string s) {
  strreplace(s,"\n","\\" + "n");
  strreplace(s,"\"","\\" + "\"");
  return "\"" + s + "\"";
}
void CMSfwDetectorProtection_connectRedundancy(){
  string reduDpStatus;

  if(!isRedundant()){
    return;
  }else{
   int reduNum = myReduHostNum();
   if(reduNum == 2){  
     reduDpStatus = "_ReduManager_2.EvStatus";
   }
   else{   
     reduDpStatus = "_ReduManager.EvStatus";
  
   }
   dpConnect("CMSfwDetectorProtection_switchActive", false, reduDpStatus);
 }

}
synchronized CMSfwDetectorProtection_switchActive(string dpe, bool active) {
  if (! active) {
      return;
  }
  CMSfwDetectorProtection_debug2("Switching to active. Unlocking and relocking");
  CMSfwDetectorProtection_unlockAll(CMSfwDetectorProtection_currentObject);
  CMSfwDetectorProtection_recompute(CMSfwDetectorProtection_currentObject, CMSfwDetectorProtection_maskedDpes, true);
  
}
bool CMSfwDetectorProtection_isHost2Active(string sys) {
  string dpe = sys  + "_ReduManager_2.Status.Active";
  bool active = false;
  if (dpExists(dpe)) 
    dpGet(dpe, active);
  return active;
}

string CMSfwDetectorProtection_getActiveCtrlManager(string sys) {
  sys = strrtrim(sys,":") + ":";
  string dp = sys + CMSfwDetectorProtection_managerDp ;
  if  (CMSfwDetectorProtection_isHost2Active(sys)) dp = dp + "_2";
  return dp;  
}
