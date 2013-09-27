#uses "fwFMC/fwFMC.ctl"

const string FW_FMC_DIM_CONFIG_PROCESS = "FMCProcesses";
const string FW_FMC_PROCESS_LIB_VERSION = "3.4.0";


//---------------------------------------Processes---------------------------------------

void fwFMCProcess_monitorProcesses(dyn_string& connectedNodes)
{
    dyn_string nodes = fwFMCProcess_getMonitoredProcessesNodes();
    //dpconnect to the nodes that are not connected
    for (int i=1; i<=dynlen(nodes); i++)
    {
      if (!dynContains(connectedNodes, nodes[i]))
      {
        string dpName = fwFMCProcess_getDp(nodes[i]);

        dpConnect("_fwFMCProcessMonitoringCB", dpName +".processes.pid"
                                             , dpName +".processes.memory"
                                             , dpName +".processes.cpu"
                                             , dpName +".processes.name"
                                             , dpName +".processes.commandLine");
        dynAppend(connectedNodes,  nodes[i]);
      }
    }
    
    //dpDisconnect from nodes for which we don't monitor processes anymore
    for(int i=dynlen(connectedNodes); i>0; i--)//we are going to remove elements => start from the end
    {
      if(!dynContains(nodes, connectedNodes[i]))
      {
        string dpName = fwFMCProcess_getDp(connectedNodes[i]);

        dynRemove(connectedNodes,  i);
        dpDisconnect("_fwFMCProcessMonitoringCB", dpName +".processes.pid"
                                             , dpName +".processes.memory"
                                             , dpName +".processes.cpu"
                                             , dpName +".processes.name"
                                             , dpName +".processes.commandLine");
      }
    }

}

dyn_string fwFMCProcess_getMonitoredProcessesNodes()
{
  dyn_string nodes;
  dyn_string monitoredProcesses = dpNames("FMC*", FW_FMC_MONITORED_PROCESS_DPT);
  for(int i =1; i<=dynlen(monitoredProcesses);i++)
  {
    string node = fwFMC_getNodeName(monitoredProcesses[i]);
    if(!dynContains(nodes, node))
      dynAppend(nodes, node);
  }
  return nodes;
}

void _fwFMCProcessMonitoringCB(string pidDp, dyn_int pidArr,
                               string memoryDp, dyn_int memoryArr,
                               string cpuDp, dyn_float cpuArr,
                               string nameDp, dyn_string nameArr,
                               string cmdLineDp, dyn_string cmdLineArr)
{

  //get the node name
   string node = fwFMC_getNodeName(dpSubStr(pidDp, DPSUB_DP));

   //get all the monitored processes for that node
  string dpPrefix = _fwFMCProcess_getProcessDpPrefix(node);
  dyn_string monitoredProcesses = dpNames(dpPrefix  + "*", FW_FMC_MONITORED_PROCESS_DPT);
  
  //for each of the processes update pid, cpu, memory, username, startdate, isRunning = true
  for (int i=1; i <= dynlen(monitoredProcesses);i++)
  {
    string name, cmdLine;
    int pid;
    dpGet(monitoredProcesses[i] + ".config.name", name,
          monitoredProcesses[i] + ".config.cmd", cmdLine,
          monitoredProcesses[i] + ".readings.pid", pid);
    bool found = false;
    int memory;
    float cpu;
    string username;
    int pidIndex = dynContains(pidArr, pid);
    if (pidIndex > 0 && cmdLineArr[pidIndex] == cmdLine && nameArr[pidIndex] == name)
    {
      memory = memoryArr[pidIndex];
      cpu = cpuArr[pidIndex];
      found = true;      
    }
    else
    {
      for(int j=1; j<= dynlen(pidArr); j++)
      {
        if (cmdLine == cmdLineArr[j] && name == nameArr[j])
        {
          pid = pidArr[j];
          memory = memoryArr[j];
          cpu = cpuArr[j];
          found = true;
          break;
        }
      }
    }
    
    dpSet(monitoredProcesses[i] + ".readings.pid", pid,
          monitoredProcesses[i] + ".readings.memory", memory,
          monitoredProcesses[i] + ".readings.cpu", cpu,
          monitoredProcesses[i] + ".readings.state", (int)found);    
  }
}

void fwFMCProcess_startMonitoringProcess(string node, int pid, string name, string options)
{
  string dpPrefix = _fwFMCProcess_getProcessDpPrefix(node);
 
  // check whether this process is already monitored
  dyn_string monitoredProcessesPids = dpNames(dpPrefix  + "*.readings.pid", FW_FMC_MONITORED_PROCESS_DPT);
  
  bool processMonitored = false;
  if (dynlen(monitoredProcessesPids) > 0)
  {
    dyn_int pids;
    dpGet(monitoredProcessesPids, pids);
    int pidIndex = dynContains(pids, pid);
    if (pidIndex > 0)
    {
      string processDp = dpSubStr(monitoredProcessesPids[pidIndex], DPSUB_DP);
      string processCmd, processName;
      dpGet(processDp + ".config.name", processName,
            processDp + ".config.cmd", processCmd);
      processMonitored = (processCmd == options) && (processName == name);
    }
  }

  if(!processMonitored) // new process to monitor
  {
    dyn_string monitoredProcesses = dpNames(dpPrefix  + "*", FW_FMC_MONITORED_PROCESS_DPT);
    bool otherProcessesFromHostMonitored = (dynlen(monitoredProcesses) > 0);    
    string dpName = _fwFMCProcess_createProcessDpName(node, name);

    if (dpCreate(dpName, FW_FMC_MONITORED_PROCESS_DPT) != -1)
    {
      string processesDp = fwFMCProcess_getDp(node);
      dyn_int pidArr, memoryArr;
      dyn_float cpuArr;
      dpGet(processesDp +".processes.pid", pidArr,
            processesDp +".processes.memory", memoryArr,
            processesDp +".processes.cpu", cpuArr);
      int processIdx = dynContains(pidArr, pid);
      int memory;
      float cpu;
      if (processIdx > 0)
      {
        memory = memoryArr[processIdx];
        cpu = cpuArr[processIdx];
      }
      dpSet(dpName + ".config.pid", pid,
            dpName + ".readings.pid", pid,
            dpName + ".config.name", name,
            dpName + ".config.cmd", options,
            dpName + ".readings.memory", memory,
            dpName + ".readings.cpu", cpu,            
            dpName + ".readings.state", 1);
      
      
      //set archive
      fwFMCProcess_setupArchiving(dpName);
    
    }
    else
      DebugN("Failed to create dp: " + dpName);
  }
  else
    DebugN("This process is already monitored: " + pid + " " + options + " " + name);

}


void fwFMCProcess_stopMonitoringProcess(string node, int pid, string name, string options)
{
  dyn_string ex;
  string dpPrefix = _fwFMCProcess_getProcessDpPrefix(node);
  dyn_string monitoredProcessesPids = dpNames(dpPrefix  + "*.readings.pid", FW_FMC_MONITORED_PROCESS_DPT);
  dyn_int pids;
  dpGet(monitoredProcessesPids, pids);

  int pidIndex = dynContains(pids, pid);
  bool processMonitored = false;
  string processDp;
  if (pidIndex > 0)
  {
    processDp = dpSubStr(monitoredProcessesPids[pidIndex], DPSUB_DP);
    string processCmd, processName;
    dpGet(processDp + ".config.name", processName,
          processDp + ".config.cmd", processCmd);
    processMonitored = (processCmd == options) && (processName == name);
  }

  if (processMonitored && processDp != "")
  {
    dpDelete(processDp);
  }
}

string _fwFMCProcess_createProcessDpName(string node, string name)
{
  string dpName;
  if (node != "")
  {
    string dpPrefix = _fwFMCProcess_getProcessDpPrefix(node); 
    int index = 1;    
    strreplace(name, ".", "");
    dpName = dpPrefix + name + "_" + index;
     while (dpExists(dpName))
     {
       index++;
       dpName = dpPrefix + name + "_" + index;
     }
  }

  return dpName;
}

string _fwFMCProcess_getProcessDpPrefix(string node, string systemName = "")
{
  return systemName + "FMC/" + strtoupper(node) + "/Process/MonitoredProcesses/";
}

string _fwFMCProcess_getServiceDpPrefix(string node, string systemName = "")
       
{
  return systemName + "FMC/" + strtoupper(node) + "/Process/MonitoredServices/";
}

void fwFMCProcess_sendProcessCommand(string node, int pid, string name, string cmd, int answer)
{
  string processDp = fwFMCProcess_getDp(node);
  dyn_string exception;
  if(answer == 1)
  {
      fwFMCProcess_startMonitoringProcess(node, pid, name, cmd);

  }
  else if(answer == 2)
  {
     fwFMCProcess_stopMonitoringProcess(node, pid, name, cmd);
  }
  else if(answer == 0)
    return;
  
  else
    DebugN("ERROR: fwFMCProcess_sendProcessCommand() -> Unknown command type: " + answer); 
  
  return;  
}    

//------------------------------Services---------------------------------------------------------------
void fwFMCProcess_monitorServices(dyn_string& connectedNodes)
{
    dyn_string nodes = fwFMCProcess_getMonitoredServicesNodes();
    //dpconnect to the nodes that are not connected
    for (int i=1; i<=dynlen(nodes); i++)
    {
      if (!dynContains(connectedNodes, nodes[i]))
      {
        string dpName = fwFMCProcess_getDp(nodes[i]);
        
        dpConnect("_fwFMCServiceMonitoringCB", dpName +".services.pid"
                                         , dpName +".services.desktopInteract"              
                                         , dpName +".services.started"
                                         , dpName +".services.name"
                                         , dpName +".services.type"
                                         , dpName +".services.startMode");
        dynAppend(connectedNodes,  nodes[i]);
      }
    }
    
    //dpDisconnect from nodes for which we don't monitor services anymore
    for(int i=dynlen(connectedNodes); i>0; i--)
    {
      if(!dynContains(nodes, connectedNodes[i]))
      {
        string dpName = fwFMCProcess_getDp(connectedNodes[i]);
        
        dynRemove(connectedNodes,  i);
        dpDisconnect("_fwFMCServiceMonitoringCB", dpName +".services.pid"
                                         , dpName +".services.desktopInteract"              
                                         , dpName +".services.started"
                                         , dpName +".services.name"
                                         , dpName +".services.type"
                                         , dpName +".services.startMode");
      }
    }
 
}

dyn_string fwFMCProcess_getMonitoredServicesNodes()
{
  dyn_string nodes;
  dyn_string monitoredServices = dpNames("FMC*", FW_FMC_MONITORED_SERVICE_DPT);
  for(int i =1; i<=dynlen(monitoredServices);i++)
  {
    string node = fwFMC_getNodeName(monitoredServices[i]);
    if(!dynContains(nodes, node))
      dynAppend(nodes, node);
  }
  return nodes;
}

void _fwFMCServiceMonitoringCB(string pidDp, dyn_int pidArr,
                               string desktopInteractDp, dyn_int desktopInteractArr,                               
                               string startedDp, dyn_int startedArr,
                               string nameDp, dyn_string nameArr,
                               string typeDp, dyn_string typeArr,                               
                               string startModeDp, dyn_string startModeArr)
{

  //get the node name
   string node = fwFMC_getNodeName(dpSubStr(pidDp, DPSUB_DP));

   //get all the monitored services for that node
  string dpPrefix = _fwFMCProcess_getServiceDpPrefix(node);
  dyn_string monitoredServices = dpNames(dpPrefix  + "*", FW_FMC_MONITORED_SERVICE_DPT);
  
  for (int i=1; i <= dynlen(monitoredServices);i++)
  {
    string name;
    int pid;
    dpGet(monitoredServices[i] + ".readings.name", name,
          monitoredServices[i] + ".readings.pid", pid);
    int desktopInteract, started;
    string type, startMode;
    int pidIndex = dynContains(pidArr, pid);
    if (pidIndex > 0 && nameArr[pidIndex] == name)
    {
      desktopInteract = desktopInteractArr[pidIndex];
      started = startedArr[pidIndex];
      type = typeArr[pidIndex];
      startMode = startModeArr[pidIndex];      
    }
    else
    {
      for(int j=1; j<= dynlen(pidArr); j++)
      {
        if (name == nameArr[j])
        {
          pid = pidArr[j];
          desktopInteract = desktopInteractArr[j];
          started = startedArr[j];
          type = typeArr[j];
          startMode = startModeArr[j]; 
          break;
        }
      }
    }
    
    dpSet(monitoredServices[i] + ".readings.pid", pid,
          monitoredServices[i] + ".readings.desktopInteract", desktopInteract,
          monitoredServices[i] + ".readings.started", started,
          monitoredServices[i] + ".readings.type", type,
          monitoredServices[i] + ".readings.startMode", startMode);    
  }
}


string _fwFMCProcess_createServiceDpName(string node, int pid)
{
  string dpName;
  if (node != "")
  {
    string dpPrefix = _fwFMCProcess_getServiceDpPrefix(node); 
    int index = 1;    
    dpName = dpPrefix + pid + "_" + index;
     while (dpExists(dpName))
     {
       index++;
       dpName = dpPrefix + pid+ "_" + index;
     }
  }

  return dpName;
}




void fwFMCProcess_sendServiceCommand(string node, int pid, string name, int answer)
{
  string processDp = fwFMCProcess_getDp(node);
      
  if(answer == 1)
  {
     fwFMCProcess_startMonitoringService(node, pid, name);
  }
  else if(answer == 2)
  {
     fwFMCProcess_stopMonitoringService(node, pid, name);
  }
  else if( answer == 0)
    return;
  
  else
    DebugN("ERROR: fwFMCProcess_sendProcessCommand() -> Unknown command type: " + answer); 
  
  return;  
}    

void fwFMCProcess_startMonitoringService(string node, int pid, string name)
{
  string dpPrefix = _fwFMCProcess_getServiceDpPrefix(node);
 
  // check whether this service is already monitored
  dyn_string monitoredServicesPids = dpNames(dpPrefix  + "*.readings.pid", FW_FMC_MONITORED_SERVICE_DPT);
  
  bool serviceMonitored = false;
  if (dynlen(monitoredServicesPids) > 0)
  {
    dyn_int pids;
    dpGet(monitoredServicesPids, pids);
    int pidIndex = dynContains(pids, pid);
    if (pidIndex > 0)
    {
      string serviceDp = dpSubStr(monitoredServicesPids[pidIndex], DPSUB_DP);
      string serviceName;
      dpGet(serviceDp + ".readings.name", serviceName);
      serviceMonitored = (serviceName == name);
    }
  }

  if(!serviceMonitored) // new service to monitor
  {
    dyn_string monitoredServices = dpNames(dpPrefix  + "*", FW_FMC_MONITORED_SERVICE_DPT);
    string dpName = _fwFMCProcess_createServiceDpName(node, pid);

    if (dpCreate(dpName, FW_FMC_MONITORED_SERVICE_DPT) != -1)
    {
      string processesDp = fwFMCProcess_getDp(node);
      dyn_int pidArr, desktopInteractArr, startedArr;
      dyn_string startedArr, typeArr, startModeArr;
      dpGet(processesDp +".services.pid", pidArr,
            processesDp +".services.desktopInteract", desktopInteractArr,
            processesDp +".services.started", startedArr,
            processesDp +".services.type", typeArr,
            processesDp +".services.startMode", startModeArr);
      int processIdx = dynContains(pidArr, pid);
      int desktopInteract, started;
      string type, startMode;
      if (processIdx > 0)
      {
        desktopInteract = desktopInteractArr[processIdx];
        started = startedArr[processIdx];
        type = typeArr[processIdx];
        startMode  =startModeArr[processIdx];
      }
      
      dpSet(dpName + ".readings.pid", pid,
            dpName + ".readings.name", name,
            dpName + ".readings.desktopInteract", desktopInteract,            
            dpName + ".readings.started", started,
            dpName + ".readings.type", type,
            dpName + ".readings.startMode", startMode); 
      
      //set archive
      fwFMCProcess_setupArchiving(dpName);
      
    }
    else
      DebugN("Failed to create dp: " + dpName);
  }
  else
    DebugN("This service is already monitored: " + pid + " " + name);
}

void fwFMCProcess_stopMonitoringService(string node, int pid, string name)    
{
  dyn_string ex;
  string dpPrefix = _fwFMCProcess_getServiceDpPrefix(node);
  dyn_string monitoredServicesPids = dpNames(dpPrefix  + "*.readings.pid", FW_FMC_MONITORED_SERVICE_DPT);
  dyn_int pids;
  dpGet(monitoredServicesPids, pids);

  int pidIndex = dynContains(pids, pid);
  bool serviceMonitored = false;
  string serviceDp;
  if (pidIndex > 0)
  {
    serviceDp = dpSubStr(monitoredServicesPids[pidIndex], DPSUB_DP);
    string serviceName;
    dpGet(serviceDp + ".readings.name", serviceName);
    serviceMonitored = (serviceName == name);
  }

  if (serviceMonitored && serviceDp != "")
  {
    dpDelete(serviceDp);
  }
}

//-----------------------------------------------------------

void fwFMCProcess_setupArchiving(string monitoredProcessDp)
{
  dyn_string ex;
  //Find out the archive class to be used:
  dyn_string dpes, defaultClasses;
  dyn_float deadbands, timeIntervals;
  dyn_int smoothTypes, smoothProcedures;
  dyn_bool canHaveArchive;
   _fwFMC_getArchivingSettings(monitoredProcessDp, dpes, defaultClasses, deadbands, 
                timeIntervals, smoothTypes, smoothProcedures, canHaveArchive);

  if(dynlen(defaultClasses) > 0 && defaultClasses[1] != "EMPTY")
  { 
    DebugN("setting archiving, using defaultClass", defaultClasses[1]);     
    fwDevice_setArchive(monitoredProcessDp, defaultClasses[1], fwDevice_ARCHIVE_SET, ex);
    if(dynlen(ex))
      DebugN(ex);
  }
}

string fwFMCProcess_getDp(string node, string systemName = "")
{
  if(systemName == "")
    systemName = getSystemName();
  
  string nodeDp = fwFMC_getNodeDp(node, systemName);
  
  return  nodeDp + "/" + "Process";
}


bool fwFMCProcess_exists(string node, string systemName = "")
{
  if(systemName == "")
    systemName = getSystemName();
  
  string processDp = fwFMCProcess_getDp(node, systemName);

  return dpExists(processDp);  
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



dyn_string fwFMCProcess_getMonitoredProcesses(string node, dyn_string &exception, string systemName = "")
{
  if(systemName == "")
    systemName = getSystemName();
  
  string dp = fwFMCProcess_getDp(node, systemName);
  dp += "/MonitoredProcesses/";
 
  dyn_string procDps;
   
  if(patternMatch("*.", dp))
    strrtrim(dp, ".");
    
  
  procDps = dpNames(dp+"*", "FwFMCMonitoredProcess");  
    
 
  strreplace(dp, systemName, "");  
  for(int i = 1; i <= dynlen(procDps); i++)
  {
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
  
  for(int i = 1; i <= dynlen(procDps); i++)
  {
    strreplace(procDps[i], systemName, "");    
    strreplace(procDps[i], dp, "");
  }
    
  return procDps; 
}


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
    

      dynAppend(allProcs, procs);
      dynAppend(allPid, pid);
      dynAppend(allCmd, cmd);
      dynAppend(allMemory, memory);
      dynAppend(allCpu, cpu);
    

      dynAppend(allUser, user);
      dynAppend(allStartDates, startDates);

  }  
}

string fwFMCProcess_getProcessHost(string dp)
{
  dyn_string ds = strsplit(dp, "/");
  
  if(dynlen(ds) < 2)
    return "";
  
  return ds[2];
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
  
  return 0;
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
