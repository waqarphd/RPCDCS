#uses "fwFMC/fwFMC.ctl"
#uses "fwDIM"

const string FW_FMC_IPMI_LIB_VERSION = "3.4.0";

const string FW_FMC_VENDOR_DP = "FMC.";

//const int FW_FMC_GROUP_NAME_IDX = 1;                                

const string FW_FMC_IPMI_DIM_CONFIG = "FMCIpmi";
                                
int fwFMCIpmi_createDPT(){

  dyn_dyn_string nameIPMI;
  dyn_dyn_int typeIPMI;

  int iIPMI=1;	

  //DebugN("Creating IPMI DPT");
  nameIPMI[iIPMI] = makeDynString (FW_FMC_IPMI_DPT);
  typeIPMI[iIPMI++] = makeDynInt (DPEL_STRUCT);
  
//	info:
  nameIPMI[iIPMI] = makeDynString ("","info");
  typeIPMI[iIPMI++] = makeDynInt (0,DPEL_STRUCT);

  nameIPMI[iIPMI] = makeDynString ("", "", "masterNode");
  typeIPMI[iIPMI++] = makeDynInt (0, 0, DPEL_STRING);

  nameIPMI[iIPMI] = makeDynString ("","","fanName");
  typeIPMI[iIPMI++] = makeDynInt (0,0,DPEL_DYN_STRING);


  nameIPMI[iIPMI] = makeDynString ("","","tempName");
  typeIPMI[iIPMI++] = makeDynInt (0,0,DPEL_DYN_STRING);


  nameIPMI[iIPMI] = makeDynString ("","","voltageName");
  typeIPMI[iIPMI++] = makeDynInt (0,0,DPEL_DYN_STRING);
  
// settings:
   nameIPMI[iIPMI] = makeDynString ("","settings");
   typeIPMI[iIPMI++] = makeDynInt (0,DPEL_STRUCT);

   nameIPMI[iIPMI] = makeDynString ("","","power_switch");
   typeIPMI[iIPMI++] = makeDynInt (0,0,DPEL_STRING);

// readings:
   nameIPMI[iIPMI] = makeDynString ("","readings");
   typeIPMI[iIPMI++] = makeDynInt (0,DPEL_STRUCT);

   nameIPMI[iIPMI] = makeDynString ("","","power_status");
   typeIPMI[iIPMI++] = makeDynInt (0,0,DPEL_INT);

   nameIPMI[iIPMI] = makeDynString ("","","power_status_timestamp");
   typeIPMI[iIPMI++] = makeDynInt (0,0,DPEL_INT);

   nameIPMI[iIPMI] = makeDynString ("","","sensors_timestamp");
   typeIPMI[iIPMI++] = makeDynInt (0,0,DPEL_INT);
  
  return dpTypeChange (nameIPMI, typeIPMI);
  
}

int fwFMCIpmi_createTempSensorDPT()
{
  dyn_dyn_string nameIPMI;
  dyn_dyn_int typeIPMI;

  int iIPMI=1;	

  nameIPMI[iIPMI] = makeDynString (FW_FMC_IPMI_TEMP_SENSOR_DPT);
  typeIPMI[iIPMI++] = makeDynInt (DPEL_STRUCT);
  
  nameIPMI[iIPMI] = makeDynString ("","value");
  typeIPMI[iIPMI++] = makeDynInt (0,DPEL_FLOAT);
  
  nameIPMI[iIPMI] = makeDynString ("","status");
  typeIPMI[iIPMI++] = makeDynInt (0,DPEL_STRING);  
 
  nameIPMI[iIPMI] = makeDynString ("","unit");
  typeIPMI[iIPMI++] = makeDynInt (0,DPEL_STRING);  
  
  return dpTypeChange (nameIPMI, typeIPMI);
}


int fwFMCIpmi_createVoltageSensorDPT()
{
  dyn_dyn_string nameIPMI;
  dyn_dyn_int typeIPMI;

  int iIPMI=1;	

  nameIPMI[iIPMI] = makeDynString (FW_FMC_IPMI_VOLTAGE_SENSOR_DPT);
  typeIPMI[iIPMI++] = makeDynInt (DPEL_STRUCT);
  
  nameIPMI[iIPMI] = makeDynString ("","value");
  typeIPMI[iIPMI++] = makeDynInt (0,DPEL_FLOAT);
  
  nameIPMI[iIPMI] = makeDynString ("","status");
  typeIPMI[iIPMI++] = makeDynInt (0,DPEL_STRING);  
 
  nameIPMI[iIPMI] = makeDynString ("","unit");
  typeIPMI[iIPMI++] = makeDynInt (0,DPEL_STRING);  

  return dpTypeChange (nameIPMI, typeIPMI);
}

int fwFMCIpmi_createFanSensorDPT()
{
  dyn_dyn_string nameIPMI;
  dyn_dyn_int typeIPMI;

  int iIPMI=1;	

  nameIPMI[iIPMI] = makeDynString (FW_FMC_IPMI_FAN_SENSOR_DPT);
  typeIPMI[iIPMI++] = makeDynInt (DPEL_STRUCT);
  
  nameIPMI[iIPMI] = makeDynString ("","value");
  typeIPMI[iIPMI++] = makeDynInt (0,DPEL_INT);
  
  nameIPMI[iIPMI] = makeDynString ("","status");
  typeIPMI[iIPMI++] = makeDynInt (0,DPEL_STRING);  
 
  nameIPMI[iIPMI] = makeDynString ("","unit");
  typeIPMI[iIPMI++] = makeDynInt (0,DPEL_STRING);  

  return dpTypeChange (nameIPMI, typeIPMI);
}

int fwFMCIpmi_createCurrentSensorDPT()
{
  dyn_dyn_string nameIPMI;
  dyn_dyn_int typeIPMI;

  int iIPMI=1;	

  nameIPMI[iIPMI] = makeDynString (FW_FMC_IPMI_CURRENT_SENSOR_DPT);
  typeIPMI[iIPMI++] = makeDynInt (DPEL_STRUCT);
  
  nameIPMI[iIPMI] = makeDynString ("","value");
  typeIPMI[iIPMI++] = makeDynInt (0,DPEL_FLOAT);
  
  nameIPMI[iIPMI] = makeDynString ("","status");
  typeIPMI[iIPMI++] = makeDynInt (0,DPEL_STRING);  
 
  nameIPMI[iIPMI] = makeDynString ("","unit");
  typeIPMI[iIPMI++] = makeDynInt (0,DPEL_STRING);  

  return dpTypeChange (nameIPMI, typeIPMI);
}



string fwFMCIpmi_getDp(string node, string systemName = "")
{
  if(systemName == "")
    systemName = getSystemName();
  
  return fwFMC_getNodeDp(node, systemName) + "/Ipmi";
}

string fwFMCIpmi_getMasterNode(string node, string systemName = "")
{
  string masterNode = "";
  if(systemName == "")
    systemName = getSystemName();
  
  if(dpExists(fwFMCIpmi_getDp(node, systemName) + ".info.masterNode"))
    dpGet(fwFMCIpmi_getDp(node, systemName) + ".info.masterNode", masterNode);

//  if(masterNode == "")
//  {
//    masterNode = "UNDEFINED_IPMI_MASTER_NODE";
//  }  
  
  return masterNode;
}

string fwFMCIpmi_getMasterNodeDp(string node, string systemName = "")
{
  if(systemName == "")
    systemName = getSystemName();
  
  return systemName + "_fwFMC_ipmi_" + fwFMCIpmi_getMasterNode(node, systemName);
}


int fwFMCIpmi_setMasterNode(string node, string ipmiMasterNode)
{
  dpSet(fwFMCIpmi_getDp(node) + ".info.masterNode", ipmiMasterNode);  
}

int fwFMCIpmi_add(string node, string ipmiDeviceName, string ipmiMasterNode)
{
  string ipmiDp = fwFMCIpmi_getDp(node);

  if(dpExists(ipmiDp))
  {
    //unsubscribe old dim services here:
//    DebugN("DP exsits, unsubscribing here");
    fwFMCIpmi_unsubscribeDim(node);
  }else{
    strreplace(ipmiDp, getSystemName(), "");

    dpCreate(ipmiDp, "FwFMCIpmi"); 
    dpSetComment(ipmiDp + ".readings.power_status", strtoupper(node) + " Power Status"); 
     
    fwFMCIpmi_setDeviceName(node, ipmiDeviceName);   
    fwFMCIpmi_setMasterNode(node, ipmiMasterNode);
//    DebugN("Sensor created here, setting Device name and masternode, ", ipmiDeviceName, ipmiMasterNode);
  }

//  //Check if server dpExists, otherwise create it now
//  if(!dpExists("_fwFMC_ipmi_" + ipmiMasterNode))
//  { 
//    dpCreate("_fwFMC_ipmi_" + + ipmiMasterNode, "_FwFMCServer");
//    fwFMCIpmi_setMasterDimConfig(ipmiMasterNode, FW_FMC_IPMI_DIM_CONFIG);
//    fwFMCIpmi_dimSubscribeServer(ipmiMasterNode);
//    DebugN("Server did not exits, it has been created here, ", ipmiMasterNode);
//  }
    
//  DebugN("Subscribing DIM services here");
  return fwFMCIpmi_subscribeDim(node, ipmiDeviceName);
  
}

string fwFMCIpmi_getDeviceName(string node, string systemName = "")
{
  if(systemName == "")
    systemName = getSystemName();
  
  string ipmiDeviceName = "";
  string nodeDp = fwFMC_getNodeDp(node, systemName);  
     
  dpGet(nodeDp + ".IPMIDeviceName", ipmiDeviceName);
  
  return ipmiDeviceName;
}


int fwFMCIpmi_setDeviceName(string node, string ipmiDeviceName)
{
  string nodeDp = fwFMC_getNodeDp(node);
  
  return dpSet(nodeDp + ".IPMIDeviceName", ipmiDeviceName);
}

synchronized int fwFMCIpmi_remove(string node)
{
  string ipmiDp = fwFMCIpmi_getDp(node);
  
  if(dpExists(ipmiDp))
  {
    //Unsubscribe DIM services here:
    fwFMCIpmi_unsubscribeDim(node); 
    fwFMCIpmi_setDeviceName(node, ""); 
    
    //Set Ipmi readout status to unknown
    dpSet(fwFMC_getNodeDp(node) + ".agentCommunicationStatus.ipmi", 0);
    //Delete all sensor dps:
    dyn_string dps = dpNames(ipmiDp + "/*");
    for(int i = 1; i <= dynlen(dps); i++)
      dpDelete(dps[i]);
      
    return dpDelete(ipmiDp);
  }
  
  return 0;  
}

synchronized int fwFMCIpmi_removeSensors(string node, string systemName = "")
{
  if(systemName == "")
    systemName = getSystemName();
  
  dyn_string dps = dpNames(fwFMC_getNodeDp(node, systemName) + "/Ipmi/*", "FwFMCIpmiTempSensor");
  dynAppend(dps, dpNames(fwFMC_getNodeDp(node, systemName) + "/Ipmi/*", "FwFMCIpmiFanSensor"));
  dynAppend(dps, dpNames(fwFMC_getNodeDp(node, systemName) + "/Ipmi/*", "FwFMCIpmiVoltageSensor"));
  dynAppend(dps, dpNames(fwFMC_getNodeDp(node, systemName) + "/Ipmi/*", "FwFMCIpmiCurrentSensor"));
  
  dyn_string types = makeDynString("temp", "fan", "voltage", "current");
  for(int i = 1; i <= dynlen(types); i++)
    fwFMCIpmi_unsubscribeDimSensors(node, types[i]);

  for(int i = 1; i <= dynlen(dps); i++)
    dpDelete(dps[i]);
  
  return 0;  
}


string fwFMCIpmi_getMasterDimConfig(string server)
{
  string config;
  
  dpGet("_fwFMC_ipmi_" + server + ".dimConfig", config);
  return config;
}

int fwFMCIpmi_setMasterDimConfig(string server, string config)
{
  return dpSet("_fwFMC_ipmi_" + server + ".dimConfig", config);
}

/*
int fwFMCIpmi_dimSubscribeServer(string ipmiMasterNode)
{
  dyn_string service_names = makeDynString();
  dyn_string dp_names = makeDynString();
  dyn_string defaults = makeDynString();
  dyn_int timeouts = makeDynInt();
  dyn_int flags = makeDynInt();
  dyn_int immediate_updates = makeDynInt();
  int index = 1;
  string configName = fwFMCIpmi_getMasterDimConfig(ipmiMasterNode);
  dyn_string cmd_names;
  dyn_string cmd_dp_names;
  string ipmiDp = "_fwFMC_ipmi_" + ipmiMasterNode;
  
//  dp_names[index] = ipmiDp + ".server_info.version";
//  service_names[index] = "/FMC/" + ipmiMasterNode + "/power_manager/server_version";
//  defaults[index] = -1;
//  timeouts[index] = 0;
//  flags[index] = 0;
//  immediate_updates[index++] = 1;

  dp_names[index] = ipmiDp + ".server_info.success";
  service_names[index] = "/FMC/" + ipmiMasterNode + "/power_manager/success";
  defaults[index] = -1;
  timeouts[index] = -2;
  flags[index] = 0;
  immediate_updates[index++] = 1;

  dp_names[index] = ipmiDp + ".server_info.actuator_version";
  service_names[index] = "/FMC/" + ipmiMasterNode + "/power_manager/actuator_version";
  defaults[index] = -1;
  timeouts[index] = -2;
  flags[index] = 0;
  immediate_updates[index++] = 1;

  dp_names[index] = ipmiDp + ".server_info.fmc_version";
  service_names[index] = "/FMC/" + ipmiMasterNode + "/power_manager/fmc_version";
  defaults[index] = -1;
  timeouts[index] = -2;
  flags[index] = 0;
  immediate_updates[index++] = 1;

    
  fwDim_subscribeServices(configName, service_names, dp_names, defaults, timeouts, flags, immediate_updates, FW_FMC_DIM_SAVE_NOW);

   return 0;
  
}
*/

synchronized int fwFMCIpmi_subscribeDim(string node, string ipmiDeviceName)
{

  dyn_string service_names = makeDynString();
  dyn_string dp_names = makeDynString();
  dyn_string defaults = makeDynString();
  dyn_int timeouts = makeDynInt();
  dyn_int flags = makeDynInt();
  dyn_int immediate_updates = makeDynInt();
  int index = 1;
  string ipmiDp = fwFMCIpmi_getDp(node);
  string configName = FW_FMC_IPMI_DIM_CONFIG;
  dyn_string cmd_names;
  dyn_string cmd_dp_names;
  
  fwDim_unSubscribeServicesByDp(configName, fwFMCIpmi_getDp(node) + "*");
  
  string nodeDp = fwFMC_getNodeDp(node);
  string ipmiMasterNode = fwFMCIpmi_getMasterNode(node);
  dp_names[index] = nodeDp + ".agentCommunicationStatus.ipmi";
  service_names[index] = "/FMC/" + ipmiMasterNode + "/power_manager/success";
  defaults[index] = -1;
  timeouts[index] = -2;
  flags[index] = 0;
  immediate_updates[index++] = 1;
  
  dp_names[index] = ipmiDp + ".info.fanName";
  service_names[index] = "/FMC/" + ipmiDeviceName + "/sensors/fan/names";
  defaults[index] = -1;
  timeouts[index] = -2;
  flags[index] = 0;
  immediate_updates[index++] = 1;

  dp_names[index] = ipmiDp + ".info.tempName";
  service_names[index] = "/FMC/" + ipmiDeviceName + "/sensors/temp/names";
  defaults[index] = -1;
  timeouts[index] = -2;
  flags[index] = 0;
  immediate_updates[index++] = 1;
  
  dp_names[index] = ipmiDp + ".info.voltageName";
  service_names[index] = "/FMC/" + ipmiDeviceName + "/sensors/voltage/names";
  defaults[index] = -1;
  timeouts[index] = -2;
  flags[index] = 0;
  immediate_updates[index++] = 1;
  
  dp_names[index] = nodeDp + ".readings.ipmi.power_status";
  service_names[index] = "/FMC/" + ipmiDeviceName + "/power_status";
  defaults[index] = -1;
  timeouts[index] = -2;
  flags[index] = 0;
  immediate_updates[index++] = 1;

  dp_names[index] = ipmiDp + ".readings.power_status_timestamp";
  service_names[index] = "/" + ipmiDeviceName + "/power_status_timestamp";
  defaults[index] = -1;
  timeouts[index] = -2;
  flags[index] = 0;
  immediate_updates[index++] = 1;

//  dp_names[index] = ipmiDp + ".readings.sensors_timestamp";
//  service_names[index] = "/" + ipmiDeviceName + "/sensors_timestamp";
//  defaults[index] = -1;
//  timeouts[index] = -2;
//  flags[index] = 0;
//  immediate_updates[index++] = 1; 
  
  //************************
  //* IPMI COMMANDS *
  //************************
  cmd_dp_names[index] = ipmiDp + ".settings.power_switch";
  cmd_names[index++] = "/FMC/" + ipmiDeviceName + "/power_switch";

//DebugN("****Subscribing: ", dp_names, " to ", service_names);

    
  fwDim_subscribeServices(configName, service_names, dp_names, defaults, timeouts, flags, immediate_updates, FW_FMC_DIM_SAVE_NOW);
  fwDim_subscribeCommands(configName, cmd_names, cmd_dp_names, FW_FMC_DIM_SAVE_NOW);

   return 0;
  
}

synchronized int fwFMCIpmi_subscribeDimSensors(string node, string type, dyn_string sensorDps)
{

  
  dyn_string service_names = makeDynString();
  dyn_string dp_names = makeDynString();
  dyn_string defaults = makeDynString();
  dyn_int timeouts = makeDynInt();
  dyn_int flags = makeDynInt();
  dyn_int immediate_updates = makeDynInt();
  int index = 1;
  string ipmiDp = fwFMCIpmi_getDp(node);
  string configName = FW_FMC_IPMI_DIM_CONFIG;
  dyn_string cmd_names;
  dyn_string cmd_dp_names;
  
  string ipmiDeviceName = fwFMCIpmi_getDeviceName(node);

  if(strtoupper(type) == "TEMP")
  {
    fwDim_unSubscribeServicesByDp(configName, fwFMCIpmi_getDp(node) + ".info.tempName");
  }
  else if (strtoupper(type) == "FAN")
  {
    fwDim_unSubscribeServicesByDp(configName, fwFMCIpmi_getDp(node) + ".info.fanName");
  }
  else if(strtoupper(type) == "VOLTAGE")
  {
    fwDim_unSubscribeServicesByDp(configName, fwFMCIpmi_getDp(node) + ".info.voltageName");
  }
  else if(strtoupper(type) == "CURRENT")
  {
    fwDim_unSubscribeServicesByDp(configName, fwFMCIpmi_getDp(node) + ".info.currentName");
  }

   //value
  service_names[1] = "/FMC/" + ipmiDeviceName + "/sensors/"+type+"/input";
  defaults[1] = -1;
  timeouts[1] = -2;
  flags[1] = 0;
  immediate_updates[1] = 1;
  
//  //status
  service_names[2] = "/FMC/" + ipmiDeviceName + "/sensors/"+type+"/status";
  defaults[2] = -1;
  timeouts[2] = -2;
  flags[2] = 0;
  immediate_updates[2] = 1;

        
//  //unit
//  service_names[3] = "/" + ipmiDeviceName + "/sensors/"+type+"/units";
//  defaults[3] = -1;
//  timeouts[3] = -1;
//  flags[3] = 0;
//  immediate_updates[3] = 1;
  
  for(int i = 1; i < dynlen(sensorDps); i++)
  {
    dp_names[1] += sensorDps[i] + ".value" + ";";
    dp_names[2] += sensorDps[i] + ".status" + ";";
//    dp_names[3] += sensorDps[i] + ".unit" + ";";
  }
    dp_names[1] += sensorDps[dynlen(sensorDps)] + ".value";
    dp_names[2] += sensorDps[dynlen(sensorDps)] + ".status";
//    dp_names[3] += sensorDps[dynlen(sensorDps)] + ".unit" + ";";
  

//  if(dynlen(sensorDps) < 8)  //for debugging
//  {
//    DebugN("Mapping: " +  node + " " + dynlen(sensorDps) + " " + service_names, dp_names);    
    fwDim_subscribeServices(configName, service_names, dp_names, defaults, timeouts, flags, immediate_updates, FW_FMC_DIM_SAVE_NOW);
//  }

  return 0;  
}


synchronized int fwFMCIpmi_unsubscribeDim(string node)
{
  dyn_string dp_names;
  dyn_dyn_string all_items;
  
  string configName = FW_FMC_IPMI_DIM_CONFIG;

/*  //SENSORS
  fwDim_getSubscribedAny(configName, "clientServices", all_items);
  
  if(dynlen(all_items) <= 0)
    return 0;
  else
    dp_names = all_items[1];  
   
     
  if(dynlen(dynPatternMatch(fwFMCIpmi_getDp(node) + "/*", dp_names)))
  {  
    fwDim_unSubscribeServicesByDp(configName, fwFMCIpmi_getDp(node) + "/*");
  }
  dynClear(dp_names);
  
  fwDim_getSubscribedAny(configName, "clientCommands", all_items);
  
  if(dynlen(all_items) <= 0)
    return 0;
  else
    dp_names = all_items[1];  
      
  if(dynlen(dynPatternMatch(fwFMCIpmi_getDp(node) + "/*", dp_names)))
  {  
    fwDim_unSubscribeCommandsByDp(configName, fwFMCIpmi_getDp(node) + "/*");
  }
  //END SENSORS
*/ 
   
  //NODE
  fwDim_getSubscribedAny(configName, "clientServices", all_items);
  
  if(dynlen(all_items) <= 0)
    return 0;
  else
    dp_names = all_items[1];  
   
  string dp = fwFMC_getNodeDp(node);
  strreplace(dp, getSystemName(), "");
  
  if(dynlen(dynPatternMatch(dp + ".agentCommunicationStatus.ipmi", dp_names)))
  {  
    fwDim_unSubscribeServicesByDp(configName, dp + ".agentCommunicationStatus.ipmi");
  }
     
  if(dynlen(dynPatternMatch("*:" + dp + ".agentCommunicationStatus.ipmi", dp_names)))
  {  
    fwDim_unSubscribeServicesByDp(configName, "*:" + dp + ".agentCommunicationStatus.ipmi");
  }
  
  if(dynlen(dynPatternMatch(fwFMCIpmi_getDp(node) + "*", dp_names)))
  {  
    fwDim_unSubscribeServicesByDp(configName, fwFMCIpmi_getDp(node) + "*");
  }
  dynClear(dp_names);
  
  fwDim_getSubscribedAny(configName, "clientCommands", all_items);
  
  if(dynlen(all_items) <= 0)
    return 0;
  else
    dp_names = all_items[1];  
      
  if(dynlen(dynPatternMatch(fwFMCIpmi_getDp(node) + "*", dp_names)))
  {  
    fwDim_unSubscribeCommandsByDp(configName, fwFMCIpmi_getDp(node) + "*");
  }
  //END OF NODE
  return 0;
}

synchronized int fwFMCIpmi_unsubscribeServer(string server)
{
  dyn_string dp_names;
  dyn_dyn_string all_items;
  
  string configName = fwFMCIpmi_getMasterDimConfig(server);

  fwDim_getSubscribedAny(configName, "clientServices", all_items);
  
  if(dynlen(all_items) <= 0)
    return 0;
  else
    dp_names = all_items[1];  
   
     
  if(dynlen(dynPatternMatch("_fwFMC_ipmi_" + server + "*", dp_names)))
  {  
    fwDim_unSubscribeServicesByDp(configName, "_fwFMC_ipmi_" + server + "*");
  }
  dynClear(dp_names);
  
  fwDim_getSubscribedAny(configName, "clientCommands", all_items);
  
  if(dynlen(all_items) <= 0)
    return 0;
  else
    dp_names = all_items[1];  
      
  if(dynlen(dynPatternMatch("_fwFMC_ipmi_" + server + "*", dp_names)))
  {  
    fwDim_unSubscribeCommandsByDp(configName, "_fwFMC_ipmi_" + server + "*");
  }
  return 0;
}

synchronized int fwFMCIpmi_unsubscribeDimSensors(string node, string type)
{
  dyn_string dp_names;
  dyn_dyn_string all_items;
  
  string configName = FW_FMC_IPMI_DIM_CONFIG;

  fwDim_getSubscribedAny(configName, "clientServices", all_items);
  
  if(dynlen(all_items) <= 0)
    return 0;
  else
    dp_names = all_items[1];  
   
     
  if(dynlen(dynPatternMatch(fwFMCIpmi_getDp(node) + "/"+type+"*", dp_names)))
  {  
    //DebugN("DIM Unsubscribing now: " + fwFMCIpmi_getDp(node) + "/"+type+"*");
    
    fwDim_unSubscribeServicesByDp(configName, fwFMCIpmi_getDp(node) + "/"+type+"*");
  }
  
  return 0;
}


bool fwFMCIpmi_exists(string node, string systemName = "")
{
  if(systemName == "")
    systemName = getSystemName();
  
  return dpExists(fwFMCIpmi_getDp(node, systemName));  
}

int fwFMCIpmi_cmd(string node, string systemName, string cmd)
{
  string ipmiDp;
  
  if(systemName == "")
    systemName = getSystemName();
  
//  if(!fwFMCIpmi_exists(node, systemName))
//    return 0; //Nothing to be done.

  if(fwFMC_isCommunicationOK(node, "ipmi", systemName) != 1)
    return -1;
  
  ipmiDp = fwFMCIpmi_getDp(node, systemName);

  return dpSet(ipmiDp + ".settings.power_switch", cmd);
  
}

int fwFMCIpmi_switchOff(string node, string systemName = "")
{
  return fwFMCIpmi_cmd(node, systemName, "off");  
}

int fwFMCIpmi_switchOn(string node, string systemName = "")
{
  return fwFMCIpmi_cmd(node, systemName, "on");    
}

int fwFMCIpmi_powerCycle(string node, string systemName = "")
{
  return fwFMCIpmi_cmd(node, systemName, "cycle");  
}

int fwFMCIpmi_getNodePowerStatus(string node, string &status, time &ts, string systemName = "")
{
  string ipmiDp;
  int ps;
  
  if(systemName == "")
    systemName = getSystemName();
  
  if(fwFMCIpmi_exists(node, systemName)) 
  {
    ipmiDp = fwFMCIpmi_getDp(node, systemName);
    
    dpGet(ipmiDp + ".readings.power_status", ps,
          ipmiDp + ".readings.power_status_timestamp", ts);
        
    if (ps == 0){
      status = "OFF";
    }else if (ps == 1){
      status = "ON";
    }
    else{
      status = "ERROR";
    }
  }
  else 
  {
    status = "ERROR";
    ts = 0;
    
    return -1; 
  }
  
  return 0;  
}

fwFMCIpmi_createTempSensorsCB(string ident, dyn_dyn_anytype val)
{
  const string type = "temp";
  string dp;
  string node;
  dyn_string ds;
  string temp;
  bool found = false;  
  dyn_string aliases;
  int sensorNr;
  dyn_string sensorDps;
  dyn_string sensorTags;
  bool updateSubscriptions = false;
  dyn_string exception;
    
  if(dynlen(val) < 2)
    return;

  int n = dynlen(val);
  for(int t = 2; t <= n; t++)  
  {
    dynClear(sensorTags);
    
    temp = val[t][1];
    ds = strsplit(temp, ".");
  
    dp = ds[1];
  
    if(patternMatch(getSystemName() + "*", dp))
      strreplace(dp, getSystemName(), "");
  
    node = fwFMC_getNodeName(dp);   
//    DebugN("Analyzing temperature sensors for host " + node + " (" + (t-1) + "/" + (n - 1) + ")");

    dynClear(aliases); 
  
    fwFMCIpmi_getSensorAliases(node, type, aliases);
  
    dynClear(sensorTags); 
   
    dyn_anytype da = val[t];
    sensorTags = da[2];
    for(int k = 1; k <= dynlen(sensorTags); k++)
    {
      found = false;
      sensorNr = k;
      strreplace(sensorTags[k], " ", "_");
      
      for(int j = dynlen(aliases); j >= 1; j--)
      {
        if(fwFMCIpmi_getDp(node) + "/" + type + "_" + sensorNr + "/" + sensorTags[k] == getSystemName() + aliases[j])
        {
          found = true;
          dynRemove(aliases, j);  //Sensor already exists
          break;
        }
      }
      
    
      //if sensor is not found, create it now:
      int err = 0;
      
      if(!found && sensorTags[k] != "-1" && !patternMatch("*IPMI*", sensorTags[k]))
      {
        err += fwFMCIpmi_createSensor(node, type, sensorNr, sensorTags[k]);
        DebugN("INFO: IPMI Sensor created: ", node, type, sensorNr, sensorTags[k]);
        updateSubscriptions = true;
      }
    }

//    delay(2);
  
    //Sensor dps have now been created. Now, DIM subscription takes place:
    sensorDps = fwFMCIpmi_getAllSensorDpNames(node, type);
  
    if(updateSubscriptions && dynlen(sensorDps) > 0)
    {
//    DebugN("Subscribing now fan sensors: ", sensorDps, type);
      fwFMCIpmi_subscribeDimSensors(node, type, sensorDps);
    }

  
    
    //Loop now over the sensors that do not exist anymore
    for(int i = dynlen(aliases); i >= 1; i--)
    {
      fwFMCIpmi_deleteSensor(aliases[i]);
    }  
  
  }
  //Archiving and alarms:
//  DebugN("temp", fwFMC_isArchivingEnabled(node), fwFMC_areAlarmsEnabled(node) );
  if(fwFMC_isArchivingEnabled(node) != "NONE")
    fwFMC_setArchiveIpmiSensors(node, "temp", exception);
  
  if(fwFMC_areAlarmsEnabled(node))
    fwFMC_setAlarmsIpmiSensors(node, "temp", exception);
  
  if(dynlen(exception))
    DebugN(exception);
  
  return;  
}

fwFMCIpmi_createVoltageSensorsCB(string ident, dyn_dyn_anytype val)
{
  const string type = "voltage";
  string dp;
  string node;
  dyn_string ds;
  string temp;
  bool found = false;  
  dyn_string aliases;
  int sensorNr;
  dyn_string sensorDps;
  dyn_string sensorTags;
  bool updateSubscriptions = false;
  dyn_string exception;  
  
  if(dynlen(val) < 2)
    return;

  int n = dynlen(val);
  for(int t = 2; t <= n; t++)  
  {

    dynClear(sensorTags);
    
    temp = val[t][1];
    ds = strsplit(temp, ".");
  
    dp = ds[1];
  
    if(patternMatch(getSystemName() + "*", dp))
      strreplace(dp, getSystemName(), "");
  
    node = fwFMC_getNodeName(dp);   
//    DebugN("Analyzing voltage sensors for host " + node + " (" + (t-1) + "/" + (n-1) + ")");

    dynClear(aliases); 
  
    fwFMCIpmi_getSensorAliases(node, type, aliases);
  
    
    dynClear(sensorTags); 
   
    dyn_anytype da = val[t];
    sensorTags = da[2];
    for(int k = 1; k <= dynlen(sensorTags); k++)
    {
      found = false;
      sensorNr = k;
      strreplace(sensorTags[k], " ", "_");
      
      for(int j = dynlen(aliases); j >= 1; j--)
      {
        
        if(fwFMCIpmi_getDp(node) + "/" + type + "_" + sensorNr + "/" + sensorTags[k] == getSystemName() + aliases[j])
        {
          found = true;
          dynRemove(aliases, j);  //Sensor already exists
          break;
        }
      }
      
    
      //if sensor is not found, create it now:
      int err = 0;
      
      if(!found && sensorTags[k] != "-1" && !patternMatch("*IPMI*", sensorTags[k]))
      {
        err += fwFMCIpmi_createSensor(node, type, sensorNr, sensorTags[k]); 
        DebugN("INFO: IPMI Sensor created: ", node, type, sensorNr, sensorTags[k]);
        updateSubscriptions = true;
      }
    }

    //delay(2);
  
    //Sensor dps have now been created. Now, DIM subscription takes place:
    sensorDps = fwFMCIpmi_getAllSensorDpNames(node, type);
  
    if(updateSubscriptions && dynlen(sensorDps) > 0)
    {
//    DebugN("Subscribing now fan sensors: ", sensorDps, type);
      fwFMCIpmi_subscribeDimSensors(node, type, sensorDps);
    }

  
    
    //Loop now over the sensors that do not exist anymore
    for(int i = dynlen(aliases); i >= 1; i--)
    {
      fwFMCIpmi_deleteSensor(aliases[i]);
    }  
  
  }  
  //Archiving and alarms:
  if(fwFMC_isArchivingEnabled(node) != "NONE")
    fwFMC_setArchiveIpmiSensors(node, "voltage", exception);
  
  if(fwFMC_areAlarmsEnabled(node))
    fwFMC_setAlarmsIpmiSensors(node, "voltage", exception);
  
  if(dynlen(exception))
    DebugN(exception);
  
  return;  

}

fwFMCIpmi_createCurrentSensorsCB(string ident, dyn_dyn_anytype val)
{
  const string type = "current";
  string dp;
  string node;
  dyn_string ds;
  string temp;
  bool found = false;  
  dyn_string aliases;
  int sensorNr;
  dyn_string sensorDps;
  dyn_string sensorTags;
  bool updateSubscriptions = false;
  dyn_string exception;  
  
  if(dynlen(val) < 2)
    return;

  int n = dynlen(val);
  for(int t = 2; t <= n; t++)  
  {

    dynClear(sensorTags);
    
    temp = val[t][1];
    ds = strsplit(temp, ".");
  
    dp = ds[1];
  
    if(patternMatch(getSystemName() + "*", dp))
      strreplace(dp, getSystemName(), "");
  
    node = fwFMC_getNodeName(dp);   
//    DebugN("Analyzing current sensors for host " + node + " (" + (t-1) + "/" + (n-1) + ")");

    dynClear(aliases); 
  
    fwFMCIpmi_getSensorAliases(node, type, aliases);
  
    
    dynClear(sensorTags); 
   
    dyn_anytype da = val[t];
    sensorTags = da[2];
    for(int k = 1; k <= dynlen(sensorTags); k++)
    {
      found = false;
      sensorNr = k;
      strreplace(sensorTags[k], " ", "_");
      
      for(int j = dynlen(aliases); j >= 1; j--)
      {
        
        if(fwFMCIpmi_getDp(node) + "/" + type + "_" + sensorNr + "/" + sensorTags[k] == getSystemName() + aliases[j])
        {
          found = true;
          dynRemove(aliases, j);  //Sensor already exists
          break;
        }
      }
      
    
      //if sensor is not found, create it now:
      int err = 0;
      
      if(!found && sensorTags[k] != "-1" && !patternMatch("*IPMI*", sensorTags[k]))
      {
        err += fwFMCIpmi_createSensor(node, type, sensorNr, sensorTags[k]); 
        DebugN("INFO: IPMI Sensor created: ", node, type, sensorNr, sensorTags[k]);
        updateSubscriptions = true;
      }
    }

    //delay(2);
  
    //Sensor dps have now been created. Now, DIM subscription takes place:
    sensorDps = fwFMCIpmi_getAllSensorDpNames(node, type);
  
    if(updateSubscriptions && dynlen(sensorDps) > 0)
    {
//    DebugN("Subscribing now fan sensors: ", sensorDps, type);
      fwFMCIpmi_subscribeDimSensors(node, type, sensorDps);
    }

  
    
    //Loop now over the sensors that do not exist anymore
    for(int i = dynlen(aliases); i >= 1; i--)
    {
      fwFMCIpmi_deleteSensor(aliases[i]);
    }  
  
  }  

  //Archiving and alarms:
  if(fwFMC_isArchivingEnabled(node) != "NONE")
    fwFMC_setArchiveIpmiSensors(node, "current", exception);
  
  if(fwFMC_areAlarmsEnabled(node))
    fwFMC_setAlarmsIpmiSensors(node, "current", exception);
  
  if(dynlen(exception))
    DebugN(exception);
  
  return;  

}

fwFMCIpmi_createFanSensorsCB(string ident, dyn_dyn_anytype val)
{
  const string type = "fan";
  string dp;
  string node;
  dyn_string ds;
  string temp;
  bool found = false;  
  dyn_string aliases;
  int sensorNr;
  dyn_string sensorDps;
  dyn_string sensorTags;
  bool updateSubscriptions = false;
  dyn_string exception;  
  
  if(dynlen(val) < 2)
    return;

  int n = dynlen(val);
  for(int t = 2; t <= n; t++)  
  {

    dynClear(sensorTags);
    
    temp = val[t][1];
    ds = strsplit(temp, ".");
  
    dp = ds[1];
  
    if(patternMatch(getSystemName() + "*", dp))
      strreplace(dp, getSystemName(), "");
  
    node = fwFMC_getNodeName(dp);   
//    DebugN("Analyzing fan sensors for host " + node + " (" + (t-1) + "/" + (n-1) + ")");

    dynClear(aliases); 
  
    fwFMCIpmi_getSensorAliases(node, type, aliases);
  
    
    dynClear(sensorTags); 
   
    dyn_anytype da = val[t];
    sensorTags = da[2];
    for(int k = 1; k <= dynlen(sensorTags); k++)
    {
      found = false;
      sensorNr = k;
      strreplace(sensorTags[k], " ", "_");
      
      for(int j = dynlen(aliases); j >= 1; j--)
      {
        
        if(fwFMCIpmi_getDp(node) + "/" + type + "_" + sensorNr + "/" + sensorTags[k] == getSystemName() + aliases[j])
        {
          found = true;
          dynRemove(aliases, j);  //Sensor already exists
          break;
        }
      }
      
    
      //if sensor is not found, create it now:
      int err = 0;
      
      if(!found && sensorTags[k] != "-1" && !patternMatch("*IPMI*", sensorTags[k]))
      {
        err += fwFMCIpmi_createSensor(node, type, sensorNr, sensorTags[k]); 
        DebugN("INFO: IPMI Sensor created: ", node, type, sensorNr, sensorTags[k]);
        updateSubscriptions = true;
      }
    }

    //delay(2);
  
    //Sensor dps have now been created. Now, DIM subscription takes place:
    sensorDps = fwFMCIpmi_getAllSensorDpNames(node, type);
  
    if(updateSubscriptions && dynlen(sensorDps) > 0)
    {
//    DebugN("Subscribing now fan sensors: ", sensorDps, type);
      fwFMCIpmi_subscribeDimSensors(node, type, sensorDps);
    }

  
    
    //Loop now over the sensors that do not exist anymore
    for(int i = dynlen(aliases); i >= 1; i--)
    {
      fwFMCIpmi_deleteSensor(aliases[i]);
    }  
  
  }  

  //Archiving and alarms:
  if(fwFMC_isArchivingEnabled(node) != "NONE")
    fwFMC_setArchiveIpmiSensors(node, "fan", exception);
  
  if(fwFMC_areAlarmsEnabled(node))
    fwFMC_setAlarmsIpmiSensors(node, "fan", exception);
  
  if(dynlen(exception))
    DebugN(exception);
  
  return;  
}

synchronized int fwFMCIpmi_deleteSensor(string alias)
{
 string temp = dpAliasToName(alias);
 dyn_string ds;
 
 if(!dpExists(temp))
   return 0;
 
 
 ds = strsplit(temp, ".");
 
 return dpDelete(ds[1]);
}

string fwFMCIpmi_getSensorDPT(string type)
{
  string dpt;
    
  switch(type)
  {
    case "temp": dpt = FW_FMC_IPMI_TEMP_SENSOR_DPT;
      break;
    case "voltage": dpt = FW_FMC_IPMI_VOLTAGE_SENSOR_DPT;
      break;
    case "fan": dpt = FW_FMC_IPMI_FAN_SENSOR_DPT;
      break;
    case "current": dpt = FW_FMC_IPMI_CURRENT_SENSOR_DPT;
      break;
    default: DebugN("ERROR: fwFMCIpmi_createSensor() -> Unknown sensor type: ", type);
      dpt = "";
      break;       
  }//end switch
  
  return dpt; 
}

synchronized int fwFMCIpmi_createSensors(string node, string systemName = "")
{
  int err = 0;
  dyn_string types = makeDynString("temp", "voltage", "current", "fan");
  bool updateSubscriptions = false;
  dyn_string exception;
  
  if(systemName == "")
    systemName = getSystemName();

  for(int i = 1; i <= dynlen(types); i++)
  {
  
    dyn_string sensorTags;
    string dp = fwFMCIpmi_getDp(node, systemName) + ".info."+types[i]+"Name";
    
    if(dpExists(dp))
      dpGet(dp, sensorTags);
    else
      continue;

    if(dynlen(sensorTags) > 0 && sensorTags[1] != "-1" && !patternMatch("*IPMI*", sensorTags[1]))
    {
      for(int k = 1; k <= dynlen(sensorTags); k++)
      {
          err += fwFMCIpmi_createSensor(node, types[i], k, sensorTags[k]);
          DebugN("INFO: IPMI Sensor created: ", node, types[i], k, sensorTags[k]);
          updateSubscriptions = true;
      }
      //Sensor dps have now been created. Now, DIM subscription takes place:
      dyn_string sensorDps = fwFMCIpmi_getAllSensorDpNames(node, types[i]);
  
      if(updateSubscriptions && dynlen(sensorDps) > 0)
      {
        //DebugN("Subscribing now sensors: ", sensorDps, types[i]);
        fwFMCIpmi_subscribeDimSensors(node, types[i], sensorDps);
      }
  
      //Archiving and alarms:
      if(fwFMC_isArchivingEnabled(node) != "NONE")
        fwFMC_setArchiveIpmiSensors(node, types[i], exception);
  
      if(fwFMC_areAlarmsEnabled(node))
        fwFMC_setAlarmsIpmiSensors(node, types[i], exception);
  
      if(dynlen(exception))
        DebugN(exception);
    }  
  }
  return;  
}

synchronized int fwFMCIpmi_createSensor(string node, string type, int sensorNr, string tag)
{
  string dp = fwFMCIpmi_getSensorDpName(node, type, sensorNr);
  dyn_string ds;
  string dpt = fwFMCIpmi_getSensorDPT(type); 
   
  strreplace(dp, getSystemName(), "");
  dpCreate(dp, dpt);  

  ds = strsplit(dp, ".");  
  
  //DebugN("Setting sensor alias: ", ds[1] + "/" + tag);
  strreplace(tag, " ", "_");
  return dpSetAlias(dp+ ".value", ds[1] + "/" + tag);
}


string fwFMCIpmi_getSensorDpName(string node, string type, int sensorNr, string systemName = "")
{
  if(systemName == "")
    systemName = getSystemName();
  
  return fwFMCIpmi_getDp(node, systemName) + "/" + type + "_" + sensorNr;
}


int fwFMCIpmi_getSensorAliases(string node, string type, dyn_string &aliases, string systemName = "")
{
  if(systemName == "")
    systemName = getSystemName();
  
  aliases = dpAliases("*", fwFMCIpmi_getDp(node, systemName) + "/" + type + "*.value");  
  
  return 0;      
}

dyn_string fwFMCIpmi_getAllSensorDpNames(string node, string type, string systemName = "")
{
  string dpt = fwFMCIpmi_getSensorDPT(type);
  dyn_string dps;
   
  if(systemName == "")
    systemName = getSystemName();
  
  //we want an ordered list of dps, i.e. ordered according to the sensor number
  int len = dynlen(dpNames(fwFMCIpmi_getDp(node, systemName) + "/" + type + "_*" , dpt));
  //DebugN("Dp names returns: ", dpNames(fwFMCIpmi_getDp(node) + "/" + type + "_*" , dpt));
  
  for(int i = 1; i <= len; i++)
  {
    //dynAppend(dps, fwFMCIpmi_getDp(node) + "/" + type + "_" + (i-1));    
    dynAppend(dps, fwFMCIpmi_getDp(node, systemName) + "/" + type + "_" + i);    
  }
  return dps;  
}    


    
fwFMCIpmi_removeMasterDpCB(string ident, dyn_dyn_anytype val)
{
  //Get all dps for the ipmi masters
  dyn_string masterDps = dpNames("*", "_FwFMCServer");
  dyn_string referenceDps = dpNames("*/Ipmi.info.masterNode");
  string master;
  bool found = false;
  int err;
  string str;
  
  if(dynlen(referenceDps) == 0)
  {
    for(int i =1; i <= dynlen(masterDps); i++)
    {
      strreplace(masterDps[i], getSystemName(), "");
      
      str = masterDps[i];
      strreplace(str, getSystemName(), "");
      strreplace(str, "_fwFMC_ipmi_", "");
      DebugN("INFO: IPMI master not in used. Deleting now..." + str);
      fwFMCIpmi_unsubscribeServer(str);
      err = dpDelete(masterDps[i]);      
    }
  }
      
  for(int i = 1; i <= dynlen(referenceDps); i++)
  {
    found = false;
    dpGet(referenceDps[i], master);
    
    for(int j = 1; j <= dynlen(masterDps); j++)
      if("_fwFMC_ipmi_" + master == masterDps[j])
      {
        found = true;
        continue;
      }
    
    if(!found)
    {
      DebugN("INFO: IPMI Master not in use anymore. Deleting now..." + master);
      fwFMCIpmi_unsubscribeServer(master);
      err = dpDelete("_fwFMC_ipmi_" + master);
    }
  }
  
  if(err)
    return -1;
  
  return 0; 
}


