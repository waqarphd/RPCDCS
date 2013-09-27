#uses "fwFMC/fwFMC.ctl"
#uses "fwDIM"

const string FW_FMC_PROCESS_LIB_VERSION = "3.4.0";

const string FW_FMC_DIM_CONFIG_PROCESS = "FMCProcesses";

void fwFMCProcess_getAllProcesses(dyn_string nodes,
                                  dyn_string &allHosts, 
                                  dyn_string &allProcs, 
                                  dyn_string &allCmd,
                                  dyn_int &allPid,
                                  dyn_int &allMemory,
                                  dyn_float &allCpu,
                                  dyn_string &allUser,
                                  dyn_string &allStartDates)
{
  dyn_string procs, cmd, user;
  dyn_int memory, pid;
  dyn_float cpu;
  dyn_string startDates;
  string host;
  
  dynClear(allHosts);
  dynClear(allProcs);
  dynClear(allCmd);
  dynClear(allPid);
  dynClear(allMemory);
  dynClear(allCpu);
  dynClear(allUser);
  dynClear(allStartDates);

  for(int k = 1; k <= dynlen(nodes); k++)
  {
    string procsDp = "FMC/"+nodes[k]+"/Process.processes";  
    
    if(!dpExists(procsDp))
      continue;
    
//    for(int i = 1; i <= dynlen(procsDps); i++)
//    {
      dpGet(procsDp + ".name", procs,
            procsDp + ".pid", pid,
            procsDp + ".commandLine", cmd,
            procsDp + ".username", user,
            procsDp + ".memory", memory,
            procsDp + ".cpu", cpu,
            procsDp + ".startDate", startDates);
    
      if(dynlen(procs) == 1 && procs[1] == "-1")
        continue;
    
      host = fwFMCProcess_getProcessHost(procsDp);
    
      bool correctArraySize = false;
      for(int j = 1; j <= dynlen(procs); j++) //ensure it has the same length as the other arrays.
      {
        dynAppend(allHosts, host);
      
        if(correctArraySize||dynlen(startDates) == 1 && startDates[1] == "-1") //Linux: process start dates not yet available
        {
          correctArraySize = true;
          startDates[j] = "N/A";
        }
      }
    
  //if(dynlen(procs) != dynlen(user))
  //DebugN(dynlen(procs),dynlen(user), host);

      dynAppend(allProcs, procs);
      dynAppend(allPid, pid);
      dynAppend(allCmd, cmd);
      dynAppend(allMemory, memory);
      dynAppend(allCpu, cpu);
    

      dynAppend(allUser, user);
      dynAppend(allStartDates, startDates);
//    } 
  }  
/*DebugN(dynlen(allHosts), 
       dynlen(allProcs), 
       dynlen(allPid), 
       dynlen(allCmd), 
       dynlen(allMemory), 
       dynlen(allCpu), 
       dynlen(allUser),
       dynlen(allStartDates));  
*/  
}

string fwFMCProcess_getProcessHost(string dp)
{
  dyn_string ds = strsplit(dp, "/");
  
  if(dynlen(ds) < 2)
    return "";
  
  return ds[2];
}

int fwFMCProcess_createServer(string server)
{
  if(!dpExists("_fwFMCProcess_" + server))
    dpCreate("_fwFMCProcess_" + server, "_FwFMCServer");
  
  fwFMCProcess_dimSubscribeServer(server);
  dpSet("_fwFMCProcess_" + server + ".server_info.name", server);
 
  return 0; 
}

dyn_string fwFMCProcess_getServerDps()
{
  return dpNames("_fwFMCProcess_*.", "_FwFMCServer");
}

int fwFMCProcess_createDPT()
{
  int error = 0;
  
  error += fwFMCProcess_createBaseDPT();
  error += fwFMCProcess_createMonitoredProcessDPT();
  error += fwFMCProcess_createMonitoredServiceDPT();
  
  if(error)
    return -1;
  
  return 0;
}

dyn_dyn_mixed fwFMCProcess_getProcesses(string node, string systemName = "")
{
  dyn_dyn_mixed processInfo;
  dyn_string names, commandLines, usernames;
  dyn_int cpus, pids, memories; 
  
  if(systemName == "")
    systemName = getSystemName();
  
  string dp = fwFMC_getNodeDp(node, systemName);
  
  dpGet(dp + "/Process.processes.name", names,
        dp + "/Process.processes.pid", pids,
        dp + "/Process.processes.commandLine", commandLines,
        dp + "/Process.processes.cpu", cpus,
        dp + "/Process.processes.memory", memories,
        dp + "/Process.processes.username", usernames);
 
  if(dynlen(names) <= 0 || names[1] == -1) //no processes
    return processInfo;

  dyn_int di = makeDynInt(dynlen(names), dynlen(pids), dynlen(commandLines), dynlen(cpus), dynlen(memories), dynlen(usernames));
  int n = dynMin(di);
  
  for(int i = 1; i <= n; i++)
  {
    processInfo[i][1] = names[i];
    //to overcome problem in FMC as PID array is not published:
    if(dynlen(pids) >=i)
      processInfo[i][2] = pids[i];
    else
      processInfo[i][2] = -1;
    
    processInfo[i][3] = commandLines[i];
    processInfo[i][4] = usernames[i];
    processInfo[i][5] = cpus[i];
    processInfo[i][6] = memories[i];
  }
  
  return processInfo;
}

dyn_dyn_mixed fwFMCProcess_getServices(string node, string systemName = "")
{
  dyn_dyn_mixed processInfo;
  dyn_string names, types, modes;
  dyn_int pids, desktops, started;
   
  if(systemName == "")
    systemName = getSystemName();
  
  string dp = fwFMC_getNodeDp(node, systemName);
  
  dpGet(dp + "/Process.services.name", names,
        dp + "/Process.services.pid", pids,
        dp + "/Process.services.type", types,
        dp + "/Process.services.started", started,
        dp + "/Process.services.desktopInteract", desktops,
        dp + "/Process.services.startMode", modes);
  
  if(dynlen(names) <= 0 || names[1] == -1)
    return processInfo;
  
  dyn_int di = makeDynInt(dynlen(names), dynlen(pids), dynlen(types), dynlen(started), dynlen(desktops), dynlen(modes));  
  int n = dynMin(di);
  
  for(int i = 1; i <= n; i++)
  {
    processInfo[i][1] = names[i];
    processInfo[i][2] = pids[i];
    processInfo[i][3] = types[i];
    processInfo[i][4] = modes[i];
    processInfo[i][5] = started[i];
    processInfo[i][6] = desktops[i];
  }
  
  return processInfo;
}

int fwFMCProcess_createBaseDPT(){

  dyn_dyn_string nameBase;
  dyn_dyn_int typeBase;

  int iBase=1;	

  nameBase[iBase] = makeDynString ("FwFMCProcess");
  typeBase[iBase++] = makeDynInt (DPEL_STRUCT);

  nameBase[iBase] = makeDynString ("","processes");
  typeBase[iBase++] = makeDynInt (0, DPEL_STRUCT);

  nameBase[iBase] = makeDynString ("","", "pid");
  typeBase[iBase++] = makeDynInt (0, 0, DPEL_DYN_INT);
  
  nameBase[iBase] = makeDynString ("","", "memory");
  typeBase[iBase++] = makeDynInt (0, 0, DPEL_DYN_INT);
  
  nameBase[iBase] = makeDynString ("","", "cpu");
  typeBase[iBase++] = makeDynInt (0, 0, DPEL_DYN_FLOAT);
  
  nameBase[iBase] = makeDynString ("","", "name");
  typeBase[iBase++] = makeDynInt (0, 0, DPEL_DYN_STRING);

  nameBase[iBase] = makeDynString ("","", "username");
  typeBase[iBase++] = makeDynInt (0, 0, DPEL_DYN_STRING);
  
  nameBase[iBase] = makeDynString ("","", "commandLine");
  typeBase[iBase++] = makeDynInt (0, 0, DPEL_DYN_STRING);


///
  nameBase[iBase] = makeDynString ("","services");
  typeBase[iBase++] = makeDynInt (0, DPEL_STRUCT);

  nameBase[iBase] = makeDynString ("","", "pid");
  typeBase[iBase++] = makeDynInt (0, 0, DPEL_DYN_INT);
  
  nameBase[iBase] = makeDynString ("","", "desktopInteract");
  typeBase[iBase++] = makeDynInt (0, 0, DPEL_DYN_INT);
  
  nameBase[iBase] = makeDynString ("","", "started");
  typeBase[iBase++] = makeDynInt (0, 0, DPEL_DYN_INT);
  
  nameBase[iBase] = makeDynString ("","", "name");
  typeBase[iBase++] = makeDynInt (0, 0, DPEL_DYN_STRING);

  nameBase[iBase] = makeDynString ("","", "type");
  typeBase[iBase++] = makeDynInt (0, 0, DPEL_DYN_STRING);

  nameBase[iBase] = makeDynString ("","", "startMode");
  typeBase[iBase++] = makeDynInt (0, 0, DPEL_DYN_STRING);
  
  nameBase[iBase] = makeDynString ("", "command");
  typeBase[iBase++] = makeDynInt (0, DPEL_STRING);

  return dpTypeChange (nameBase, typeBase);

}



int fwFMCProcess_createMonitoredProcessDPT(){

  dyn_dyn_string nameBase;
  dyn_dyn_int typeBase;

  int iBase=1;	

  nameBase[iBase] = makeDynString ("FwFMCMonitoredProcess");
  typeBase[iBase++] = makeDynInt (DPEL_STRUCT);
  
  nameBase[iBase] = makeDynString ("", "pid");
  typeBase[iBase++] = makeDynInt (0, DPEL_INT);
  
  nameBase[iBase] = makeDynString ("","memory");
  typeBase[iBase++] = makeDynInt (0, DPEL_INT);
  
  nameBase[iBase] = makeDynString ("","updated");
  typeBase[iBase++] = makeDynInt (0, DPEL_INT);
  
  nameBase[iBase] = makeDynString ("","state");
  typeBase[iBase++] = makeDynInt (0, DPEL_INT);
  
  nameBase[iBase] = makeDynString ("", "cpu");
  typeBase[iBase++] = makeDynInt (0, DPEL_FLOAT);

  nameBase[iBase] = makeDynString ("", "name");
  typeBase[iBase++] = makeDynInt (0, DPEL_STRING);
  
  nameBase[iBase] = makeDynString ("", "username");
  typeBase[iBase++] = makeDynInt (0, DPEL_STRING);
  
  nameBase[iBase] = makeDynString ("", "cmd");
  typeBase[iBase++] = makeDynInt (0, DPEL_STRING);
  
  return dpTypeChange (nameBase, typeBase);
}

int fwFMCProcess_createMonitoredServiceDPT(){

  dyn_dyn_string nameBase;
  dyn_dyn_int typeBase;

  int iBase=1;	

  nameBase[iBase] = makeDynString ("FwFMCMonitoredService");
  typeBase[iBase++] = makeDynInt (DPEL_STRUCT);
  
  nameBase[iBase] = makeDynString ("","readings");
  typeBase[iBase++] = makeDynInt (0, DPEL_STRUCT);
  
  nameBase[iBase] = makeDynString ("", "","started");
  typeBase[iBase++] = makeDynInt (0, 0, DPEL_INT);
  
  nameBase[iBase] = makeDynString ("", "", "pid");
  typeBase[iBase++] = makeDynInt (0, 0, DPEL_INT);
  
  nameBase[iBase] = makeDynString ("", "","desktopInteract");
  typeBase[iBase++] = makeDynInt (0, 0, DPEL_INT);
  
  nameBase[iBase] = makeDynString ("", "", "name");
  typeBase[iBase++] = makeDynInt (0, 0, DPEL_STRING);
  
  nameBase[iBase] = makeDynString ("", "", "type");
  typeBase[iBase++] = makeDynInt (0, 0, DPEL_STRING);
  
  nameBase[iBase] = makeDynString ("", "", "startMode");
  typeBase[iBase++] = makeDynInt (0, 0, DPEL_STRING);
  
  return dpTypeChange (nameBase, typeBase);
}

//Work functions

bool fwFMCProcess_exists(string node, string systemName = "")
{
  if(systemName == "")
    systemName = getSystemName();
  
  string processDp = fwFMCProcess_getDp(node, systemName);

  return dpExists(processDp);  
}

string fwFMCProcess_getDp(string node, string systemName = "")
{
  if(systemName == "")
    systemName = getSystemName();
  
  string nodeDp = fwFMC_getNodeDp(node, systemName);
  
  return  nodeDp + "/" + "Process";
}


synchronized int fwFMCProcess_add(string node)
{
  dyn_string exception;
  int error = 0;
 
  if(!fwFMCProcess_exists(node))
  {
    string dp = fwFMCProcess_getDp(node);
    strreplace(dp, getSystemName(), "");
    error = dpCreate(dp, "FwFMCProcess");
    
    if(error){
      fwFMC_msg("ERROR: fwFMCProcess_add() -> Could not create process monitoring dp");
      return -1;
    }
  }
  //delay(1);
  error += fwFMCProcess_dimSubscribe(node);
  
  //Notify the DIM server that the new node has to be monitored:
  //fwFMCProcess_monitorNode(node, exception);
  
  if(dynlen(exception))
  {
    fwExceptionHandling_display(exception);
    ++error;
  }

  if(error)
    return -1;
   
  return 0; 
}

int fwFMCProcess_remove(string node)
{
  int error = 0;
  
  error += fwFMCProcess_removeAllMonitoredProcesses(node);
  error += fwFMCProcess_removeAllMonitoredServices(node);
  
  if(dpExists(fwFMCProcess_getDp(node)))
  {
    fwFMCProcess_unsubscribe(node);  
    dpSet(fwFMC_getNodeDp(node) + ".agentCommunicationStatus.process", 0);
        
    error += dpDelete(fwFMCProcess_getDp(node));  
  }
  
  if(error)
    return -1;
  
  return 0; 
}

int fwFMCProcess_removeAllMonitoredProcesses(string node)
{
  
  string dp = fwFMCProcess_getDp(node, getSystemName()) + "/MonitoredProcesses/";
  string configName = FW_FMC_DIM_CONFIG_PROCESS;

  strreplace(dp, getSystemName(), "");
  
  dyn_string dp_names;
  dyn_dyn_string all_items;
  
  fwDim_getSubscribedAny(configName, "clientServices", all_items);
  
  if(dynlen(all_items) > 0)
  {
    dp_names = all_items[1];  
    if(dynlen(dynPatternMatch(dp + "*", dp_names)))
    {  
      fwDim_unSubscribeServicesByDp(configName, dp + "*");
    }
  }
  
  dyn_string dps = dpNames(dp + "*", "FwFMCMonitoredProcesses");
  for(int i = 1; i <= dynlen(dps); i++)
    dpDelete(dps[1]);
  
  return 0;
}

int fwFMCProcess_removeAllMonitoredServices(string node)
{
  string dp = fwFMCProcess_getDp(node, getSystemName()) + "/MonitoredServices/";
  string configName = FW_FMC_DIM_CONFIG_PROCESS;

  dyn_string dp_names;
  dyn_dyn_string all_items;
  
  strreplace(dp, getSystemName(), "");
  fwDim_getSubscribedAny(configName, "clientServices", all_items);
  
  if(dynlen(all_items) > 0)
  {
    dp_names = all_items[1];  
    if(dynlen(dynPatternMatch(dp + "*", dp_names)))
    {  
      fwDim_unSubscribeServicesByDp(configName, dp + "*");
    }
  }
  
  dyn_string dps = dpNames(dp + "*", "FwFMCMonitoredServices");
  for(int i = 1; i <= dynlen(dps); i++)
    dpDelete(dps[1]);
  
  return 0;
}

//DIM
int fwFMCProcess_unsubscribe(string node) // works only in a local system
{
  dyn_string dp_names;
  dyn_dyn_string all_items;
  
  string configName = FW_FMC_DIM_CONFIG_PROCESS;

  fwDim_getSubscribedAny(configName, "clientServices", all_items);
  
  if(dynlen(all_items) <= 0)
    return 0;
  else
    dp_names = all_items[1];  
  
  string processDp = fwFMCProcess_getDp(node);
   
  processDp = dpSubStr(processDp, DPSUB_DP);                 // atemporary solution for DIM purposes

  string dp = fwFMC_getNodeDp(node);
  strreplace(dp, getSystemName(), "");
  
  if(dynlen(dynPatternMatch(dp + ".agentCommunicationStatus.process", dp_names)))
  {  
    fwDim_unSubscribeServicesByDp(configName, dp + ".agentCommunicationStatus.process");
  }
  
  if(dynlen(dynPatternMatch("*:" + dp + ".agentCommunicationStatus.process", dp_names)))
  {  
    fwDim_unSubscribeServicesByDp(configName, "*:" + dp + ".agentCommunicationStatus.process");
  }
  
  if(dynlen(dynPatternMatch(processDp + ".*", dp_names)))
  {  
    fwDim_unSubscribeServicesByDp(configName, processDp + ".*");
  }
  dynClear(dp_names);
  
  fwDim_getSubscribedAny(configName, "clientCommands", all_items);
  
  if(dynlen(all_items) <= 0)
    return 0;
  else
    dp_names = all_items[1];  
      
  if(dynlen(dynPatternMatch(processDp + ".*", dp_names)))
  {  
    fwDim_unSubscribeCommandsByDp(configName, processDp + ".*");
  }
  
  return 0;
}

synchronized int fwFMCProcess_dimSubscribe(string node) // works only in a local system
{
  dyn_string service_names;
  dyn_int defaults;
  dyn_string dp_names;
  string processDp = fwFMCProcess_getDp(node);
  string configName = FW_FMC_DIM_CONFIG_PROCESS;
  int index = 1;
  dyn_int flags;
  dyn_int timeouts;
  dyn_int immediate_updates;
  string physicalNodeName = fwFMC_getNodePhysicalName(node);

  
  fwFMCProcess_unsubscribe(node);
  
  // a temporary solution for DIM purposes 
  processDp = dpSubStr(processDp, DPSUB_DP);                     
  
  string nodeDp = fwFMC_getNodeDp(node);
  strreplace(nodeDp, getSystemName(), "");
  dp_names[index] = nodeDp + ".agentCommunicationStatus.process";
  service_names[index] = "/FMC/" + physicalNodeName + "/ps/success";
  defaults[index] = -1;
  timeouts[index] = -2;
  flags[index] = 0;
  immediate_updates[index++] = 1;
    
  dp_names[index] = processDp + ".processes.commandLine";
  service_names[index] = "/FMC/" + physicalNodeName + "/ps/summary/processes/data/CMDLINE";
  defaults[index] = -1;
  timeouts[index] = -2;
  flags[index] = 0;
  immediate_updates[index++] = 1;
  
  dp_names[index] = processDp + ".processes.username";
  service_names[index] = "/FMC/" + physicalNodeName + "/ps/summary/processes/data/USER";
  defaults[index] = -1;
  timeouts[index] = -2;
  flags[index] = 0;
  immediate_updates[index++] = 1;
  
  dp_names[index] = processDp + ".processes.startDate";
  service_names[index] = "/FMC/" + physicalNodeName + "/ps/summary/processes/data/START";
  defaults[index] = -1;
  timeouts[index] = -2;
  flags[index] = 0;
  immediate_updates[index++] = 1;
  
  dp_names[index] = processDp + ".processes.pid";
  service_names[index] = "/FMC/" + physicalNodeName + "/ps/summary/processes/data/TGID";
  defaults[index] = -1;
  timeouts[index] = -2;
  flags[index] = 0;
  immediate_updates[index++] = 1;
  
  dp_names[index] = processDp + ".processes.memory";
  service_names[index] = "/FMC/" + physicalNodeName + "/ps/summary/processes/data/VSIZE";
  defaults[index] = -1;
  timeouts[index] = -2;
  flags[index] = 0;
  immediate_updates[index++] = 1;
  
  dp_names[index] = processDp + ".processes.cpu";
  service_names[index] = "/FMC/" + physicalNodeName + "/ps/summary/processes/data/PCPU";
  defaults[index] = -1.;
  timeouts[index] = -2;
  flags[index] = 0;
  immediate_updates[index++] = 1;
  
  dp_names[index] = processDp + ".processes.name";
  service_names[index] = "/FMC/" + physicalNodeName + "/ps/summary/processes/data/CMD"; 
  defaults[index] = -1;
  timeouts[index] = -2;
  flags[index] = 0;
  immediate_updates[index++] = 1;

  string os = fwFMC_getNodeOs(node);
  if(os == "WINDOWS")
  {
    dp_names[index] = processDp + ".services.name";
    service_names[index] = "/FMC/" + physicalNodeName + "/ps/summary/services/data/names"; 
    defaults[index] = -1;
    timeouts[index] = -2;
    flags[index] = 0;
    immediate_updates[index++] = 1;
  
    dp_names[index] = processDp + ".services.type";
    service_names[index] = "/FMC/" + physicalNodeName + "/ps/summary/services/data/types";
    defaults[index] = -1;
    timeouts[index] = -2;
    flags[index] = 0;
    immediate_updates[index++] = 1;
  
    dp_names[index] = processDp + ".services.pid";
    service_names[index] = "/FMC/" + physicalNodeName + "/ps/summary/services/data/pids"; 
    defaults[index] = -1;
    timeouts[index] = -2;
    flags[index] = 0;
    immediate_updates[index++] = 1;
  
    dp_names[index] = processDp + ".services.startMode";
    service_names[index] = "/FMC/" + physicalNodeName + "/ps/summary/services/data/modes";
    defaults[index] = -1;
    timeouts[index] = -2;
    flags[index] = 0;
    immediate_updates[index++] = 1;
  
    dp_names[index] = processDp + ".services.started";
    service_names[index] = "/FMC/" + physicalNodeName + "/ps/summary/services/data/started";
    defaults[index] = -1;
    timeouts[index] = -2;
    flags[index] = 0;
    immediate_updates[index++] = 1;
  
    dp_names[index] = processDp + ".services.desktopInteract";
    service_names[index] = "/FMC/" + physicalNodeName + "/ps/summary/services/data/desktop_interact";
    defaults[index] = -1;
    timeouts[index] = -2;
    flags[index] = 0;
    immediate_updates[index++] = 1;
  }
  
  fwDim_subscribeServices(configName, service_names, dp_names, defaults, timeouts, flags, immediate_updates, FW_FMC_DIM_SAVE_NOW);
  
  int index = 1;
  dyn_string cmd_dp_names;
  dyn_string cmd_names;
  
  cmd_dp_names[index] = processDp + ".command";
  cmd_names[index++] = "/FMC/" + physicalNodeName + "/ps/cmd";
  
  if(os == "LINUX")
  {
    cmd_dp_names[index] = processDp + ".startMonitoringProcess";
    cmd_names[index++] = "/FMC/" + physicalNodeName + "/ps/startMonitoring";

    cmd_dp_names[index] = processDp + ".stopMonitoringProcess";
    cmd_names[index++] = "/FMC/" + physicalNodeName + "/ps/stopMonitoring";  
  }
  
  fwDim_subscribeCommands(configName, cmd_names, cmd_dp_names, FW_FMC_DIM_SAVE_NOW);
  
  return 0;
}


void fwFMCProcess_dimSubscribeServer(string server) // works only in a local system
{
  string configName = FW_FMC_DIM_CONFIG_PROCESS;
  int index = 1;
  dyn_string cmd_dp_names;
  dyn_string cmd_names;
  string dp = "_fwFMCProcess_" + server;
  
  strreplace(dp, getSystemName(), "");
  
  cmd_dp_names[index] = dp + ".cmd";
  cmd_names[index++] = "/FMC/ps/cmd";
  
  fwDim_subscribeCommands(configName, cmd_names, cmd_dp_names, FW_FMC_DIM_SAVE_NOW);
  
  dyn_string service_names;
  dyn_int defaults;
  dyn_string dp_names;
  int index = 1;
  dyn_int flags;
  dyn_int timeouts;
  dyn_int immediate_updates;
  
  dp_names[index] = dp + ".server_info.dim_version";
  service_names[index] = "/FMC/" + strtoupper(server) + "/ps/VERSION_NUMBER";
  defaults[index] = -1;
  timeouts[index] = -2;
  flags[index] = 0;
  immediate_updates[index++] = 1;
  
  fwDim_subscribeServices(configName, service_names, dp_names, defaults, timeouts, flags, immediate_updates, FW_FMC_DIM_SAVE_NOW);

  return;
}


void fwFMCProcess_initCB(string ident, int val)
{
  dyn_string exception;
  dyn_string processes, services;
  dyn_string nodes = fwFMCProcess_getExistingNodes(); 

  if(val <= 1) //We do not have connection to the server. Nothing to be done.
    return;

  //for(int i = 1; i <= dynlen(nodes); i++)
    //fwFMCProcess_monitorNode(nodes[i], exception);
  
  delay(10);
  
  //Monitored processes and services: Do not do it in previous loop to give some time to the dim server to implement the address space
  for(int i = 1; i <= dynlen(nodes); i++)
  {
    dynClear(processes);
    string procDp = fwFMCProcess_getDp(nodes[i]);
    
    processes = fwFMCProcess_getMonitoredProcesses(nodes[i], exception);
    
    for(int j = 1; j <= dynlen(processes); j++)
    {
      string name, cmd;
      int pid;
      
      dpGet(procDp + "/MonitoredProcesses/" + processes[j] + ".config.pid", pid,
            procDp + "/MonitoredProcesses/" + processes[j] + ".config.name", name,
            procDp + "/MonitoredProcesses/" + processes[j] + ".config.cmd", cmd);
            
      //string dp = fwFMCProcess_getMonitoredProcessDp(nodes[i], name, pid);      
      
      //dpGet(dp + ".config.cmd", cmd,
      //      dp + ".config.pid", pid);
      
      DebugN("Starting monitoring of process: ", nodes[i], name, pid, cmd);
      fwFMCProcess_createMonitoredProcess(nodes[i], name, pid, cmd);
      //delay(0, 500);
    }
    
    dynClear(services);
    services = fwFMCProcess_getMonitoredServices(nodes[i], exception);
    
    //DebugN("List of monitored services: ", nodes[i], services);
    for(int j = 1; j <= dynlen(services); j++)
    {
      string dp = fwFMCProcess_getMonitoredServiceDp(nodes[i], services[j]);      
      DebugN("Starting monitoring of service: ", nodes[i], services[j]);
      fwFMCProcess_createMonitoredService(nodes[i], services[j]);
      //delay(0, 500);
    }
  }//end of loop
  
  
  //Exception Handling here:
  if(dynlen(exception))
    fwExceptionHandling_display(exception);
  
  return;  
}

/////////////////////////

int fwFMCProcess_getOriginalPid(string node, string cmd, string systemName = "")
{
  int pid = -1;  
  
  if(systemName == "")
    systemName = getSystemName();
    
  dyn_string dps;
  
  if(fwFMC_getNodeOs(node) == "WINDOWS")
    dps = dpNames(systemName + "*/" + node + "/*", "FwFMCMonitoredProcess");
  else
    dps = dpNames(systemName + "*/" + node + "/*", "FwFMCMonitoredProcessLinux");
  
  for(int i = 1; i <= dynlen(dps); i++)
  {
    string command;
    dpGet(dps[i] + ".config.cmd", command);
    
    if(command == cmd)
    {
      dpGet(dps[i] + ".config.pid", pid);
      break;
    }
  }  
  
  return pid;
}

void fwFMCProcess_removeMonitoredProcess(string node, string name, string cmd, dyn_string &exception, bool deleteDp = true)    
{

  int pid = fwFMCProcess_getOriginalPid(node, cmd);

  if(pid < 0)
  {
    fwException_raise(exception, "ERROR", "fwFMCProcess_removeMonitoredProcess() -> failed to stop monitoring of process: " + name + "\ncmd: " + cmd + " as the original PID could not be resolved.", -9999);
    return;
  }
    
  string dp = fwFMCProcess_getDp(node);    
  fwFMCProcess_unsubscribeMonitoredProcess(node, name, pid);
  
  if(fwFMC_getNodeOs(node) == "WINDOWS")
    dpSet(dp + ".command", "StopMonitoringProcess " + cmd); 
  else
    dpSet(dp + ".stopMonitoringProcess", "-c " + name); 
  
  
  if(deleteDp)
    dpDelete(fwFMCProcess_getMonitoredProcessDp(node, name, pid));
   
  return;
}

void fwFMCProcess_removeMonitoredService(string node, string name, bool deleteDp = true)    
{
//  fwFMCProcess_sendServiceCommand(node, name, 5);
  fwFMCProcess_unsubscribeMonitoredService(node, name);
  
  if(deleteDp)
    dpDelete(fwFMCProcess_getMonitoredServiceDp(node, name));

  return;   
}
    
string fwFMCProcess_getMonitoredProcessDp(string node, string name, int pid, string systemName = "")
{
  if(systemName == "")
    systemName = getSystemName();
  
  strreplace(name, ".", "_");
  strreplace(name, " ", "_");
  
  return (fwFMCProcess_getDp(node, systemName) + "/MonitoredProcesses/" + name + "_" + pid);
}    

string fwFMCProcess_getMonitoredServiceDp(string node, string name, string systemName = "")
{
  if(systemName == "")
    systemName = getSystemName();
  
  strreplace(name, " ", "_");
  return (fwFMCProcess_getDp(node, systemName) + "/MonitoredServices/" + name);
}    
    
void fwFMCProcess_createMonitoredProcess(string node, string name, int pid, string cmd)
{
  dyn_string names, users, cmds;
  dyn_int pids, memories, cpus;
  
  string procDp = fwFMCProcess_getDp(node);
  string dp = fwFMCProcess_getMonitoredProcessDp(node, name, pid, getSystemName());
  string os = fwFMC_getNodeOs(node);
  
  if(patternMatch(getSystemName() + "*", dp))
    strreplace(dp, getSystemName(), "");
  
  if(!dpExists(dp))
  {
    if(os == "WINDOWS")
      dpCreate(dp, "FwFMCMonitoredProcess");
    else
      dpCreate(dp, "FwFMCMonitoredProcessLinux");
    
    //Apply default addressing here:
    dyn_string ex;
    //Find out the archive class to be used:
    dyn_string dpes, defaultClasses;
    dyn_float deadbands, timeIntervals;
    dyn_int smoothTypes, smoothProcedures;
    dyn_bool canHaveArchive;
     _fwFMC_getArchivingSettings(dp, dpes, defaultClasses, deadbands, 
                timeIntervals, smoothTypes, smoothProcedures, canHaveArchive);
     
DebugN("setting archiving, using defaultClass", defaultClasses[1]);     

    fwDevice_setArchive(dp, defaultClasses[1], fwDevice_ARCHIVE_SET, ex);
    if(dynlen(ex))
      DebugN(ex);
      
      
    fwFMCProcess_dimSubscribeMonitoredProcess(node, fwFMCProcess_getProcessSubscriptionName(name), pid);
  }

  if(os == "WINDOWS")
  {
    dpSet(procDp + ".command", "StartMonitoringProcess " + fwFMCProcess_getProcessSubscriptionName(name) + " " + pid + " "+ cmd,
          dp + ".config.name", name,
          dp + ".config.cmd", cmd,
          dp + ".config.pid", pid);
  }
  else
  {
    dpSet(procDp + ".startMonitoringProcess", "-c " + name,
          dp + ".config.name", name,
          dp + ".config.cmd", cmd,
          dp + ".config.pid", pid);
  }
  
  dpGet(fwFMCProcess_getDp(node) + ".processes.pid", pids,
        fwFMCProcess_getDp(node) + ".processes.memory",memories,
        fwFMCProcess_getDp(node) + ".processes.cpu", cpus,
        fwFMCProcess_getDp(node) + ".processes.name", names,
        fwFMCProcess_getDp(node) + ".processes.commandLine", cmds,
        fwFMCProcess_getDp(node) + ".processes.username", users);
  
  for(int i = 1; i <= dynlen(cmds); i++)
  {
    if(cmds[i] == cmd)
    {
      delay(0, 200);//allow some time for DIM to udpate the values of the service.
      dpSet(fwFMCProcess_getMonitoredProcessDp(node, name, pid) + ".readings.pid", pids[i],
            fwFMCProcess_getMonitoredProcessDp(node, name, pid) + ".readings.memory", memories[i],
            fwFMCProcess_getMonitoredProcessDp(node, name, pid) + ".readings.state", 1,
            fwFMCProcess_getMonitoredProcessDp(node, name, pid) + ".readings.cpu", cpus[i]);
      break;
    }
  }
  
  return;  
}

void fwFMCProcess_createMonitoredService(string node, string name)
{
  string processDp = fwFMCProcess_getDp(node);
  string dp;
  if(!dpExists(fwFMCProcess_getMonitoredServiceDp(node, name)))
  {
    dp = fwFMCProcess_getMonitoredServiceDp(node, name);
    strreplace(dp, getSystemName(), "");
    
    dpCreate(dp, "FwFMCMonitoredService");
    fwFMCProcess_dimSubscribeMonitoredService(node, name);
  }

  dpSet(processDp + ".command", "StartMonitoringService " + name);
  dyn_int pids, started, desktopInteract;
  dyn_string names, type, startMode;
  
  dpGet(fwFMCProcess_getDp(node) + ".services.pid", pids,
        fwFMCProcess_getDp(node) + ".services.name",names,
        fwFMCProcess_getDp(node) + ".services.started", started,
        fwFMCProcess_getDp(node) + ".services.desktopInteract", desktopInteract,
        fwFMCProcess_getDp(node) + ".services.type", type,
        fwFMCProcess_getDp(node) + ".services.startMode", startMode);
  
  for(int i = 1; i <= dynlen(names); i++)
  {
    if(names[i] == name)
    {
      delay(0, 200);//allow some time for DIM to udpate the values of the service.
      dpSet(dp + ".readings.pid", pids[i],
            dp + ".readings.name",names[i],
            dp + ".readings.started", started[i],
            dp + ".readings.desktopInteract", desktopInteract[i],
            dp + ".readings.type", type[i],
            dp + ".readings.startMode", startMode[i]);
      break;
    }
  }
  return;  
}

int fwFMCProcess_unsubscribeMonitoredProcess(string node, string name, int pid) // works only in a local system
{
  dyn_string dp_names;
  dyn_dyn_string all_items;
  
  string configName = FW_FMC_DIM_CONFIG_PROCESS;

  fwDim_getSubscribedAny(configName, "clientServices", all_items);
  
  if(dynlen(all_items) <= 0)
    return 0;
  else
    dp_names = all_items[1];  
  
  string monitProcessDP = fwFMCProcess_getMonitoredProcessDp(node, name, pid);
  
  //a temporary solution of DIM purposes
  strreplace(monitProcessDP, getSystemName(), "");
  //monitProcessDP = dpSubStr(monitProcessDP, DPSUB_DP);
  
  if(dynlen(dynPatternMatch(monitProcessDP + "*" , dp_names)))
  {  
    fwDim_unSubscribeServicesByDp(configName, monitProcessDP + ".readings");
  }
  
  dynClear(dp_names);
  
  fwDim_getSubscribedAny(configName, "clientCommands", all_items);
 
  if(dynlen(all_items) <= 0)
    return 0;
  else
    dp_names = all_items[1];  
      
  if(dynlen(dynPatternMatch(monitProcessDP + "*", dp_names)))
  {  
    fwDim_unSubscribeCommandsByDp(configName, monitProcessDP);
  }
  
  return 0;
}

int fwFMCProcess_unsubscribeMonitoredService(string node, string name) //works only in a local system
{
  dyn_string dp_names;
  dyn_dyn_string all_items;
  
  string configName = FW_FMC_DIM_CONFIG_PROCESS;
  
  string monitServiceDP = fwFMCProcess_getMonitoredServiceDp(node, name);
  
  //a temporary solution of DIM purposes
//  monitServiceDP = dpSubStr(monitServiceDP, DPSUB_DP);
  strreplace(monitServiceDP, getSystemName(), "");

  strreplace(name, " ", "_");
  fwDim_getSubscribedAny(configName, "clientServices", all_items);
  
  if(dynlen(all_items) <= 0)
    return 0;
  else
    dp_names = all_items[1];  
   
     
  if(dynlen(dynPatternMatch(monitServiceDP + "*", dp_names)))
  {  
    fwDim_unSubscribeServicesByDp(configName, monitServiceDP);
  }
  
  dynClear(dp_names);
  
  fwDim_getSubscribedAny(configName, "clientCommands", all_items);
  
  if(dynlen(all_items) <= 0)
    return 0;
  else
    dp_names = all_items[1];  
      
  if(dynlen(dynPatternMatch(monitServiceDP + "*", dp_names)))
  {  
    fwDim_unSubscribeCommandsByDp(configName, monitServiceDP);
  }
  
  return 0;
}

    
int fwFMCProcess_dimSubscribeMonitoredProcess(string node, string name, int pid) //works only in a local system
{
  dyn_string service_names;
  dyn_int defaults;
  dyn_string dp_names;
  string processDp = fwFMCProcess_getMonitoredProcessDp(node, name, pid);
  string configName = FW_FMC_DIM_CONFIG_PROCESS;
  int index = 1;
  dyn_int flags;
  dyn_int timeouts;
  dyn_int immediate_updates;
  string physicalNodeName = fwFMC_getNodePhysicalName(node);

  fwFMCProcess_unsubscribeMonitoredProcess(node, name, pid);
  
  //a temporary solution of DIM purposes
  processDp = dpSubStr(processDp, DPSUB_DP);
  
  strreplace(name, ".", "_");

  dp_names[index] = processDp + ".readings";
  
  if(fwFMC_getNodeOs(node) == "WINDOWS")
    service_names[index] = "/FMC/" + physicalNodeName + "/ps/" + name + "_" + pid + "/summary/data";
  else
    service_names[index] = "/FMC/" + physicalNodeName + "/ps/summary/monitored/processes/" + name + "{}" + pid + "/data";
  
  defaults[index] = -1;
  timeouts[index] = -2;
  flags[index] = 0;
  immediate_updates[index++] = 0;
  
  fwDim_subscribeServices(configName, service_names, dp_names, defaults, timeouts, flags, immediate_updates, FW_FMC_DIM_SAVE_NOW);
  
  return 0;
}

int fwFMCProcess_dimSubscribeMonitoredService(string node, string name)//works only in a local system
{
  dyn_string service_names;
  dyn_int defaults;
  dyn_string dp_names;
  string serviceDp = fwFMCProcess_getMonitoredServiceDp(node, name) + ".readings";
  string configName = FW_FMC_DIM_CONFIG_PROCESS;
  int index = 1;
  dyn_int flags;
  dyn_int timeouts;
  dyn_int immediate_updates;
  string physicalNodeName = fwFMC_getNodePhysicalName(node);

  fwFMCProcess_unsubscribeMonitoredService(node, name);
  
  //a temporary solution of DIM purposes
  serviceDp = dpSubStr(serviceDp, DPSUB_DP);

  strreplace(name, " ", "_");
  dp_names[index] = serviceDp;
  service_names[index] = "/FMC/" + physicalNodeName + "/ps/" + name + "/summary/data";
  defaults[index] = -1;
  timeouts[index] = -2;
  flags[index] = 0;
  immediate_updates[index++] = 0;
  
  fwDim_subscribeServices(configName, service_names, dp_names, defaults, timeouts, flags, immediate_updates, FW_FMC_DIM_SAVE_NOW);
  
  return 0;
}

       
void fwFMCProcess_sendProcessCommand(string node, int pid, string name, string cmd, int answer)
{
  string processDp = fwFMCProcess_getDp(node);
  dyn_string exception;
      
  if(answer == 1)
    dpSet(processDp + ".command", "StartProcess \"" + cmd + "\"");
  else if(answer == 2)
    dpSet(processDp + ".command", "StopProcess " + pid);
  else if(answer == 3)
    dpSet(processDp + ".command", "KillProcess " + pid);
  else if(answer == 4)
  {
    //delay(1);
    
    if(!fwFMCProcess_monitoredProcessExists(node, name, pid, getSystemName()))
    {
      fwFMCProcess_createMonitoredProcess(node, name, pid, cmd);
//      fwFMCProcess_dimSubscribeMonitoredProcess(node, name, pid); 
//      fwFMCProcess_dimSubscribeMonitoredProcess(node, fwFMCProcess_getProcessSubscriptionName(name), pid);
    }
      

  }
  else if(answer == 5)
  {
//    dpSet(processDp + ".command", "StopMonitoringProcess " + cmd);
//    delay(1);
    fwFMCProcess_removeMonitoredProcess(node, name, cmd, exception, true);
  }
  else if(answer == 0)
    return;
  
  else
    DebugN("ERROR: fwFMCProcess_sendProcessCommand() -> Unknown command type: " + answer); 
  
  return;  
}    

bool fwFMCProcess_monitoredServiceExists(string node, string name, string systemName = "")
{
  if(systemName == "")
    systemName = getSystemName();
  
  return dpExists(fwFMCProcess_getMonitoredServiceDp(node, name, systemName));
}

bool fwFMCProcess_monitoredProcessExists(string node, string name, int pid, string systemName)
{
  if(systemName == "")
    systemName = getSystemName();
  
  return dpExists(fwFMCProcess_getMonitoredProcessDp(node, name, pid, systemName));
}

void fwFMCProcess_sendServiceCommand(string node, string name, int answer)
{
  string processDp = fwFMCProcess_getDp(node);
      
  if(answer == 1)
    dpSet(processDp + ".command", "StartService " + name);
  else if(answer == 2)
    dpSet(processDp + ".command", "StopService " + name);
  else if(answer == 4)
  {
    if(!fwFMCProcess_monitoredServiceExists(node, name))
    {
      fwFMCProcess_createMonitoredService(node, name);
//      fwFMCProcess_dimSubscribeMonitoredService(node, name);
    }
  }
  else if(answer == 5)
  {
    dpSet(processDp + ".command", "StopMonitoringService " + name);
    delay(1);
    fwFMCProcess_removeMonitoredService(node, name);
  }
  else if( answer == 0)
    return;
  
  else
    DebugN("ERROR: fwFMCProcess_sendProcessCommand() -> Unknown command type: " + answer); 
  
  return;  
}    

//////////////////////////


dyn_string fwFMCProcess_getMonitoredProcesses(string node, dyn_string &exception, string systemName = "")
{
  if(systemName == "")
    systemName = getSystemName();
  
  string dp = fwFMCProcess_getDp(node, systemName);
  dp += "/MonitoredProcesses/";
 
  dyn_string procDps;
   
  if(patternMatch("*.", dp))
    strrtrim(dp, ".");
    
  
  if(fwFMC_getNodeOs(node) == "WINDOWS")
    procDps = dpNames(dp+"*", "FwFMCMonitoredProcess");  
  else
    procDps = dpNames(dp+"*", "FwFMCMonitoredProcessLinux");  
    
  //DebugN("Looking for ", dp+"*", "FwFMCMonitoredProcess", procDps);

  strreplace(dp, systemName, "");  
  for(int i = 1; i <= dynlen(procDps); i++)
  {
//    strreplace(procDps[i], getSystemName(), "");
    strreplace(procDps[i], systemName, "");
    strreplace(procDps[i], dp, "");
  }
      
  return procDps; 
}


dyn_string fwFMCProcess_getMonitoredServices(string node, dyn_string &exception, string systemName = "")
{
  if(systemName == "")
    systemName = getSystemName();
  
  string dp = fwFMCProcess_getDp(node, systemName);
  
  dp += "/MonitoredServices/";
  
  dyn_string procDps;
   
  if(patternMatch("*.", dp))
    strrtrim(dp, ".");
    
  procDps = dpNames(dp+"*", "FwFMCMonitoredService");  
  //DebugN("Looking for ", dp+"*", "FwFMCMonitoredService", procDps);
  
  for(int i = 1; i <= dynlen(procDps); i++)
  {
//    strreplace(procDps[i], getSystemName(), "");
    strreplace(procDps[i], systemName, "");    
    strreplace(procDps[i], dp, "");
  }
    
  return procDps; 
}

dyn_string fwFMCProcess_getExistingNodes(string systemName = "")
{
  if(systemName == "")
    systemName = getSystemName();
  
  dyn_string nodes;
  
  dyn_string nodeDps = dpNames(systemName + "*", "FwFMCProcess");
    
  for(int i = 1; i <= dynlen(nodeDps); i++)
  {
    nodes[i] = fwFMC_getNodeName(nodeDps[i]);
  }
  
  return nodes;
}

string fwFMCProcess_getProcessSubscriptionName(string name)
{
  strreplace(name, " ", "_");
  return name;
}
