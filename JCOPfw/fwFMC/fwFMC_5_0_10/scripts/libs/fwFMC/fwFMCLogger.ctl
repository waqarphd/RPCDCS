#uses "fwFMC/fwFMC.ctl"
#uses "fwDIM"



const string FW_FMC_LOGGER_LIB_VERSION = "3.4.0";

const string FW_FMC_TM_LOGGER_DIM_CONFIG = "FMCTmLogger";

int fwFMCLogger_createDPT()
{
  dyn_dyn_string name;
  dyn_dyn_int type;

  int i=1;	


  name[i] = makeDynString ("FwFMCLogger");
  type[i++] = makeDynInt (DPEL_STRUCT);

// info
	name[i] = makeDynString ("","server_info");
	type[i++] = makeDynInt (0,DPEL_STRUCT);

	name[i] = makeDynString ("","","version");
	type[i++] = makeDynInt (0,0,DPEL_STRING);

	name[i] = makeDynString ("","","success");
	type[i++] = makeDynInt (0,0,DPEL_INT);

// settings
	name[i] = makeDynString ("","settings");
	type[i++] = makeDynInt (0,DPEL_STRUCT);

	name[i] = makeDynString ("","","setStored");
	type[i++] = makeDynInt (0,0,DPEL_STRING);

      	name[i] = makeDynString ("","","setFilter");
	type[i++] = makeDynInt (0,0,DPEL_STRING);


// readings:
	name[i] = makeDynString ("","readings");
	type[i++] = makeDynInt (0,DPEL_STRUCT);

	name[i] = makeDynString ("","","log");
	type[i++] = makeDynInt (0,0,DPEL_STRING);

	name[i] = makeDynString ("","","logCache");
	type[i++] = makeDynInt (0,0,DPEL_DYN_STRING);

	name[i] = makeDynString ("","","stored");
	type[i++] = makeDynInt (0,0,DPEL_STRING);

	name[i] = makeDynString ("","","filter");
	type[i++] = makeDynInt (0,0,DPEL_STRING);


  return dpTypeChange (name, type);

}

bool fwFMCLogger_exists(string node, string systemName = "")
{
  if(systemName == "")
    systemName = getSystemName();

  string dp = fwFMCLogger_getDp(node, systemName);

  return dpExists(dp);  
}

string fwFMCLogger_getDp(string node, string systemName = "")
{
  if(systemName == "")
    systemName = getSystemName();
  
  string nodeDp = fwFMC_getNodeDp(node, systemName);
  
  return  nodeDp + "/" + "Logger";
}

int fwFMCLogger_add(string node)
{
  string dp = fwFMCLogger_getDp(node);
  
  if(dpExists(dp))
  {
    //unsubscribe old dim services here:
    fwFMCLogger_unsubscribeDim(node);
  }else{
    strreplace(dp, getSystemName(), "");
    dpCreate(dp, "FwFMCLogger");   
  }
  
  return fwFMCLogger_subscribeDim(node);
  
}

int fwFMCLogger_remove(string node)
{
  string dp = fwFMCLogger_getDp(node);
  
  if(dpExists(dp))
  {
    //Unsubscribe DIM services here:
    fwFMCLogger_unsubscribeDim(node); 
    dpSet(fwFMC_getNodeDp(node) + ".agentCommunicationStatus.logger", 0);

    return dpDelete(dp);
  }
  
  return 0;  
}


int fwFMCLogger_subscribeDim(string node)
{
  dyn_string service_names = makeDynString();
  dyn_string dp_names = makeDynString();
  dyn_string defaults = makeDynString();
  dyn_int timeouts = makeDynInt();
  dyn_int flags = makeDynInt();
  dyn_int immediate_updates = makeDynInt();
  int index = 1;
  string dp = fwFMCLogger_getDp(node);
  string configName = FW_FMC_TM_LOGGER_DIM_CONFIG;
  string physicalNodeName = fwFMC_getNodePhysicalName(node);
  dyn_string cmd_names;
  dyn_string cmd_dp_names;
  string nodeDp = fwFMC_getNodeDp(node);
  
//*******************
//* LOGGER SERVICES *
//*******************
/*  dp_names[index] = dp + ".server_info.version";
  service_names[index] = "/FMC/" + physicalNodeName + "/logger/server_version";
  defaults[index] = -1;
  timeouts[index] = 0;
  flags[index] = 0;
  immediate_updates[index++] = 1;
*/
//  dp_names[index] = dp + ".server_info.success";
  dp_names[index] = nodeDp + ".agentCommunicationStatus.logger";
  service_names[index] = "/FMC/" + physicalNodeName + "/logger/fmc/success";
  defaults[index] = -1;
  timeouts[index] = 0;
  flags[index] = 0;
  immediate_updates[index++] = 1;

  dp_names[index] = dp + ".readings.logCache";
  service_names[index] = "/FMC/" + physicalNodeName + "/logger/fmc/last_log";
  defaults[index] = -1;
  timeouts[index] = 0;
  flags[index] = 0;
  immediate_updates[index++] = 1;
  
  dp_names[index] = dp + ".readings.stored";
  service_names[index] = "/FMC/" + physicalNodeName + "/logger/fmc/log";
  defaults[index] = -1;
  timeouts[index] = 0;
  flags[index] = 0;
  immediate_updates[index++] = 1;

  dp_names[index] = dp + ".readings.filter";
  service_names[index] = "/FMC/" + physicalNodeName + "/logger/fmc/get_properties";
  defaults[index] = -1;
  timeouts[index] = 0;
  flags[index] = 0;
  immediate_updates[index++] = 1;
                    
  fwDim_subscribeServices(configName, service_names, dp_names, defaults, timeouts, flags, immediate_updates, FW_FMC_DIM_SAVE_NOW);

//************************
//* Logger COMMANDS *
//************************
  cmd_dp_names[index] = dp + ".settings.setFilter";
  cmd_names[index++] = "/FMC/" + physicalNodeName + "/logger/fmc/set_properties";

//  cmd_dp_names[index] = dp + ".settings.setStored";
//  cmd_names[index++] = "/FMC/" + physicalNodeName + "/logger/fmc/log_set_stored";

            
  fwDim_subscribeCommands(configName, cmd_names, cmd_dp_names, FW_FMC_DIM_SAVE_NOW);
    
   return 0;
  
}

int fwFMCLogger_unsubscribeDim(string node)
{
  dyn_string dp_names;
  dyn_dyn_string all_items;
  
  string configName = FW_FMC_TM_LOGGER_DIM_CONFIG;

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
  
  if(dynlen(dynPatternMatch("*:" + dp + ".agentCommunicationStatus.logger", dp_names)))
  {  
    fwDim_unSubscribeServicesByDp(configName, "*:" + dp + ".agentCommunicationStatus.logger");
  }
  
  if(dynlen(dynPatternMatch(fwFMCLogger_getDp(node) + "*", dp_names)))
  {  
    fwDim_unSubscribeServicesByDp(configName, fwFMCLogger_getDp(node) + "*");
  }
  dynClear(dp_names);
  
  fwDim_getSubscribedAny(configName, "clientCommands", all_items);
  
  if(dynlen(all_items) <= 0)
    return 0;
  else
    dp_names = all_items[1];  
      
  if(dynlen(dynPatternMatch(fwFMCLogger_getDp(node) + "*", dp_names)))
  {  
    fwDim_unSubscribeCommandsByDp(configName, fwFMCLogger_getDp(node) + "*");
  }
  return 0;
}

int fwFMCLogger_setFilter(string node, string filter, string systemName = "")
{
  if(systemName == "")
    systemName = getSystemName();
  
  return dpSet(fwFMCLogger_getDp(node, systemName) + ".settings.setFilter", filter);
}

string fwFMCLogger_getFilter(string node, string systemName = "")
{
  if(systemName == "")
    systemName = getSystemName();
  
  string filter;
  
  dpGet(fwFMCLogger_getDp(node, systemName) + ".readings.filter", filter);
  
  return filter;
}

int fwFMCLogger_setStored(string node, int stored, string systemName = "")
{
  if(systemName == "")
    systemName = getSystemName();
  
  return dpSet(fwFMCLogger_getDp(node, systemName) + ".settings.setStored", "-S " + stored);
}

int fwFMCLogger_getStored(string node, string systemName = "")
{
  if(systemName == "")
    systemName = getSystemName();

  string stored;
  
  dpGet(fwFMCLogger_getDp(node, systemName) + ".readings.stored", stored);
  
  strreplace(stored, "-S ", "");
  return (int) stored;
}


