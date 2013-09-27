#uses "fwFMC/fwFMC.ctl"
#uses "fwDIM"

const string FW_FMC_TM_LIB_VERSION = "3.4.0";


int fwFMCTaskManager_createDPT()
{
  dyn_dyn_string name;
  dyn_dyn_int type;

  int i=1;	


  name[i] = makeDynString ("FwFMCTaskManager");
  type[i++] = makeDynInt (DPEL_STRUCT);

// info
	name[i] = makeDynString ("","server_info");
	type[i++] = makeDynInt (0,DPEL_STRUCT);

	name[i] = makeDynString ("","","version");
	type[i++] = makeDynInt (0,0,DPEL_STRING);

	name[i] = makeDynString ("","","success");
	type[i++] = makeDynInt (0,0,DPEL_INT);

// commands
	name[i] = makeDynString ("","commands");
	type[i++] = makeDynInt (0,DPEL_STRUCT);

	name[i] = makeDynString ("","","start");
	type[i++] = makeDynInt (0,0,DPEL_STRING);

	name[i] = makeDynString ("","","stop");
	type[i++] = makeDynInt (0,0,DPEL_STRING);

	name[i] = makeDynString ("","","kill");
	type[i++] = makeDynInt (0,0,DPEL_STRING);


// readings:
	name[i] = makeDynString ("","readings");
	type[i++] = makeDynInt (0,DPEL_STRUCT);

	name[i] = makeDynString ("","","list");
	type[i++] = makeDynInt (0,0,DPEL_DYN_STRING);

	name[i] = makeDynString ("","","log");
	type[i++] = makeDynInt (0,0,DPEL_STRING);

  return dpTypeChange (name, type);

}


bool fwFMCTaskManager_exists(string node, string systemName = "")
{
  if(systemName == "")
    systemName = getSystemName();
  
  string tmDp = fwFMCTaskManager_getDp(node, systemName);

  return dpExists(tmDp);  
}

string fwFMCTaskManager_getDp(string node, string systemName = "")
{
  if(systemName == "")
    systemName = getSystemName();
  
  string nodeDp = fwFMC_getNodeDp(node);
  
  return  nodeDp + "/" + "TaskManager";
}

int fwFMCTaskManager_add(string node)
{
  string dp = fwFMCTaskManager_getDp(node);
  strreplace(dp, getSystemName(), "");

  if(dpExists(dp))
  {
    //unsubscribe old dim services here:
    fwFMCTaskManager_unsubscribeDim(node);
  }else{
    dpCreate(dp, "FwFMCTaskManager");   
  }
  
  return fwFMCTaskManager_subscribeDim(node);
  
}

int fwFMCTaskManager_remove(string node)
{
  string dp = fwFMCTaskManager_getDp(node);
  
  if(dpExists(dp))
  {
    //Unsubscribe DIM services here:
    fwFMCTaskManager_unsubscribeDim(node); 
    dpSet(fwFMC_getNodeDp(node) + ".agentCommunicationStatus.taskManager", 0);

    return dpDelete(dp);
  }
  
  return 0;  
}

int fwFMCTaskManager_subscribeDim(string node)
{
  dyn_string service_names = makeDynString();
  dyn_string dp_names = makeDynString();
  dyn_string defaults = makeDynString();
  dyn_int timeouts = makeDynInt();
  dyn_int flags = makeDynInt();
  dyn_int immediate_updates = makeDynInt();
  int index = 1;
  string dp = fwFMCTaskManager_getDp(node);
  string configName = FW_FMC_TM_LOGGER_DIM_CONFIG;
  dyn_string cmd_names;
  dyn_string cmd_dp_names;
  string physicalNodeName = fwFMC_getNodePhysicalName(node);
  
  //************************
//* TASKMANAGER SERVICES *
//************************
/*  dp_names[index] = dp + ".server_info.version";
  service_names[index] = "/FMC/" + physicalNodeName + "/task_manager/server_version";
  defaults[index] = -1;
  timeouts[index] = 0;
  flags[index] = 0;
  immediate_updates[index++] = 1;
*/
  
  string nodeDp = fwFMC_getNodeDp(node);
  strreplace(nodeDp, getSystemName(), "");
  dp_names[index] = nodeDp + ".agentCommunicationStatus.taskManager";
//  dp_names[index] = dp + ".server_info.success";
  service_names[index] = "/FMC/" + physicalNodeName + "/task_manager/success";
  defaults[index] = -1;
  timeouts[index] = 0;
  flags[index] = 0;
  immediate_updates[index++] = 1;

  dp_names[index] = dp + ".readings.list";
  service_names[index] = "/FMC/" + physicalNodeName + "/task_manager/list";
  defaults[index] = -1;
  timeouts[index] = 0;
  flags[index] = 0;
  immediate_updates[index++] = 1;

  dp_names[index] = dp + ".readings.log";
  service_names[index] = "/FMC/" + physicalNodeName + "/task_manager/log";
  defaults[index] = -1;
  timeouts[index] = 0;
  flags[index] = 0;
  immediate_updates[index++] = 1;
  
  fwDim_subscribeServices(configName, service_names, dp_names, defaults, timeouts, flags, immediate_updates, FW_FMC_DIM_SAVE_NOW);
  
  
//************************
//* TASKMANAGER COMMANDS *
//************************
  cmd_dp_names[index] = dp + ".commands.start";
  cmd_names[index++] = "/FMC/" + physicalNodeName + "/task_manager/start";

  cmd_dp_names[index] = dp + ".commands.stop";
  cmd_names[index++] = "/FMC/" + physicalNodeName + "/task_manager/stop";

  cmd_dp_names[index] = dp + ".commands.kill";
  cmd_names[index++] = "/FMC/" + physicalNodeName + "/task_manager/kill";
            
  fwDim_subscribeCommands(configName, cmd_names, cmd_dp_names, FW_FMC_DIM_SAVE_NOW);

   return 0;
  
}

int fwFMCTaskManager_unsubscribeDim(string node)
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
  
  if(dynlen(dynPatternMatch(dp + ".agentCommunicationStatus.taskManager", dp_names)))
  {  
    fwDim_unSubscribeServicesByDp(configName, dp + ".agentCommunicationStatus.taskManager");
  }
  
  if(dynlen(dynPatternMatch("*:" + dp + ".agentCommunicationStatus.taskManager", dp_names)))
  {  
    fwDim_unSubscribeServicesByDp(configName, "*:" + dp + ".agentCommunicationStatus.taskManager");
  }
  
  if(dynlen(dynPatternMatch(fwFMCTaskManager_getDp(node) + "*", dp_names)))
  {  
    fwDim_unSubscribeServicesByDp(configName, fwFMCTaskManager_getDp(node) + "*");
  }
  dynClear(dp_names);
  
  fwDim_getSubscribedAny(configName, "clientCommands", all_items);
  
  if(dynlen(all_items) <= 0)
    return 0;
  else
    dp_names = all_items[1];  
      
  if(dynlen(dynPatternMatch(fwFMCTaskManager_getDp(node) + "*", dp_names)))
  {  
    fwDim_unSubscribeCommandsByDp(configName, fwFMCTaskManager_getDp(node) + "*");
  }
  return 0;
}

int fwFMCTaskManager_sendCommand(string node, string cmd, string systemName = "")
{             
  if(systemName == "")
    systemName = getSystemName();
  
  //Check comm with task manager:  
  if(fwFMC_isCommunicationOK(node, "taskManager", systemName) != 1)
    return -1;

  return dpSet(fwFMCTaskManager_getDp(node, systemName) + ".commands.start", cmd);
}

int fwFMCTaskManager_haltNode(string node, string systemName = "")
{
  if(systemName == "")
    systemName = getSystemName();
  
  return dpSet(fwFMCTaskManager_getDp(node, systemName) + ".commands.start","/sbin/shutdown -h now");
}

int fwFMCTaskManager_rebootNode(string node, string systemName = "")
{
  if(systemName == "")
    systemName = getSystemName();
  
  //Check comm with task manager:  
  if(fwFMC_isCommunicationOK(node, "taskManager", systemName) != 1)
    return -1;
  
  return dpSet(fwFMCTaskManager_getDp(node, systemName) + ".commands.start","/sbin/shutdown -r now");
}

int fwFMCTaskManager_shutdownNode(string node, string systemName = "")
{
  if(systemName == "")
    systemName = getSystemName();
  
  //Check comm with task manager:  
  if(fwFMC_isCommunicationOK(node, "taskManager", systemName) != 1)
    return -1;
  
  return dpSet(fwFMCTaskManager_getDp(node, systemName) + ".commands.start","/sbin/shutdown now");
}

