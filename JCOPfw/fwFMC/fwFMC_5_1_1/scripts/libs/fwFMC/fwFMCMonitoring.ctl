#uses "fwFMC/fwFMC.ctl"
#uses "fwDIM"


const string FW_FMC_MONITORING_LIB_VERSION = "3.4.0";


const int FW_FMC_CPU_IDX = 1;
const int FW_FMC_MEMORY_IDX = 2;
const int FW_FMC_NETWORK_IDX = 3;
const int FW_FMC_TCPIP_IDX = 4;
const int FW_FMC_INTERRUPTS_IDX = 5;
const int FW_FMC_COALESCENCE_IDX = 6;
const int FW_FMC_RUN_LEVEL_IDX = 7;
const int FW_FMC_PROCESS_IDX = 8;
const string FW_FMC_DIM_CONFIG_PERMANENT = "FMCContinuousMonitoring";
const string FW_FMC_DIM_CONFIG_TEMP = "FMCTemporaryMonitoring";


dyn_float fwFMCMonitoring_getFssUsage(string node, string systemName = "")
{
  if(systemName == "")
    systemName = getSystemName();
  
  dyn_float usages;
  if(fwFMCMonitoring_fsExists(node, systemName))
  {
    dyn_string dps;
    fwFMCMonitoring_getFSDps(node, dps, systemName);
    for(int i = 1; i <= dynlen(dps); i++)
    {
      float fs;
      dpGet(dps[i] + ".readings.user", fs);
      dynAppend(usages, fs);
    }
  }
  return usages;
}

int fwFMCMonitoring_createDPT()
{
  int error = 0;
  
  error += fwFMCMonitoring_createBaseDPT();
  error += fwFMCMonitoring_createCpuBaseDPT();
  error += fwFMCMonitoring_createNetworkBaseDPT();
  error += fwFMCMonitoring_createFsBaseDPT();
  error += fwFMCMonitoring_createFsDPT();
  error += fwFMCMonitoring_createCpuDPT();
  error += fwFMCMonitoring_createMemDPT();
  error += fwFMCMonitoring_createNetworkDPT();
  error += fwFMCMonitoring_createProcessDPT();
  
  if(error)
    return -1;
  
  return 0;
}

int fwFMCMonitoring_createBaseDPT(){

  dyn_dyn_string nameBase;
  dyn_dyn_int typeBase;

  int iBase=1;	

  nameBase[iBase] = makeDynString ("FwFMCMonitoring");
  typeBase[iBase++] = makeDynInt (DPEL_STRUCT);

  nameBase[iBase] = makeDynString ("","level");
  typeBase[iBase++] = makeDynInt (0, DPEL_INT);

  nameBase[iBase] = makeDynString ("","OS");
  typeBase[iBase++] = makeDynInt (0, DPEL_STRUCT);

  nameBase[iBase] = makeDynString ("", "", "server_info");
  typeBase[iBase++] = makeDynInt (0, 0, DPEL_STRUCT);
  
  nameBase[iBase] = makeDynString ("", "", "", "version");
  typeBase[iBase++] = makeDynInt (0, 0, 0, DPEL_STRING);

  nameBase[iBase] = makeDynString ("", "", "", "success");
  typeBase[iBase++] = makeDynInt (0, 0, 0, DPEL_INT);
  
  nameBase[iBase] = makeDynString ("","","readings");
  typeBase[iBase++] = makeDynInt (0, 0, DPEL_STRUCT);

  nameBase[iBase] = makeDynString ("","","","name");
  typeBase[iBase++] = makeDynInt (0, 0, 0, DPEL_STRING);
  
  nameBase[iBase] = makeDynString ("", "","","distribution");
  typeBase[iBase++] = makeDynInt (0, 0, 0, DPEL_STRING);

  nameBase[iBase] = makeDynString ("", "","","kernel");
  typeBase[iBase++] = makeDynInt (0, 0, 0, DPEL_STRING);

  nameBase[iBase] = makeDynString ("", "","","release");
  typeBase[iBase++] = makeDynInt (0, 0, 0, DPEL_STRING);

  nameBase[iBase] = makeDynString ("", "","","machine");
  typeBase[iBase++] = makeDynInt (0, 0, 0, DPEL_STRING);

  return dpTypeChange (nameBase, typeBase);

}



int fwFMCMonitoring_createCpuBaseDPT(){

  dyn_dyn_string nameBase;
  dyn_dyn_int typeBase;

  int iBase=1;	

  nameBase[iBase] = makeDynString ("FwFMCCpuBase");
  typeBase[iBase++] = makeDynInt (DPEL_STRUCT);
  
  nameBase[iBase] = makeDynString ("", "server_info");
  typeBase[iBase++] = makeDynInt (0, DPEL_STRUCT);
  
  nameBase[iBase] = makeDynString ("", "","cpustat");
  typeBase[iBase++] = makeDynInt (0, 0, DPEL_STRUCT);
  
  nameBase[iBase] = makeDynString ("", "", "", "version");
  typeBase[iBase++] = makeDynInt (0, 0, 0, DPEL_STRING);

  nameBase[iBase] = makeDynString ("", "", "", "success");
  typeBase[iBase++] = makeDynInt (0, 0, 0, DPEL_INT);
  
  nameBase[iBase] = makeDynString ("", "", "cpuinfo");
  typeBase[iBase++] = makeDynInt (0, 0, DPEL_STRUCT);
  
  nameBase[iBase] = makeDynString ("", "", "", "version");
  typeBase[iBase++] = makeDynInt (0, 0, 0, DPEL_STRING);

  nameBase[iBase] = makeDynString ("", "", "", "success");
  typeBase[iBase++] = makeDynInt (0, 0, 0, DPEL_INT);
  
  nameBase[iBase] = makeDynString ("", "readings");
  typeBase[iBase++] = makeDynInt (0,DPEL_STRUCT);

  nameBase[iBase] = makeDynString ("","", "devices");
  typeBase[iBase++] = makeDynInt (0, 0, DPEL_DYN_STRING);
  
  nameBase[iBase] = makeDynString ("","", "ctxtRate");
  typeBase[iBase++] = makeDynInt (0, 0, DPEL_FLOAT);
  
  nameBase[iBase] = makeDynString ("","", "averageLoad");
  typeBase[iBase++] = makeDynInt (0, 0, DPEL_STRUCT);
  
  nameBase[iBase] = makeDynString ("","", "", "user");
  typeBase[iBase++] = makeDynInt (0, 0, 0, DPEL_FLOAT);
  
  nameBase[iBase] = makeDynString ("","", "", "system");
  typeBase[iBase++] = makeDynInt (0, 0, 0, DPEL_FLOAT);
  
  nameBase[iBase] = makeDynString ("","", "", "nice");
  typeBase[iBase++] = makeDynInt (0, 0, 0, DPEL_FLOAT);
  
  nameBase[iBase] = makeDynString ("","", "", "idle");
  typeBase[iBase++] = makeDynInt (0, 0, 0, DPEL_FLOAT);
  
  nameBase[iBase] = makeDynString ("","", "", "iowait");
  typeBase[iBase++] = makeDynInt (0, 0, 0, DPEL_FLOAT);
  
  nameBase[iBase] = makeDynString ("","", "", "irq");
  typeBase[iBase++] = makeDynInt (0, 0, 0, DPEL_FLOAT);
  
  nameBase[iBase] = makeDynString ("","", "", "softirq");
  typeBase[iBase++] = makeDynInt (0, 0, 0, DPEL_FLOAT);  
  
  return dpTypeChange (nameBase, typeBase);

}

int fwFMCMonitoring_createFsBaseDPT(){

  dyn_dyn_string nameFs;
  dyn_dyn_int typeFs;

  int iFs=1;	


  nameFs[iFs] = makeDynString ("FwFMCFsBase");
  typeFs[iFs++] = makeDynInt (DPEL_STRUCT);
  
  nameFs[iFs] = makeDynString ("", "server_info");
  typeFs[iFs++] = makeDynInt (0, DPEL_STRUCT);
  
  nameFs[iFs] = makeDynString ("", "", "version");
  typeFs[iFs++] = makeDynInt (0, 0, DPEL_STRING);

  nameFs[iFs] = makeDynString ("", "", "success");
  typeFs[iFs++] = makeDynInt (0, 0, DPEL_INT);

  nameFs[iFs] = makeDynString ("", "readings");
  typeFs[iFs++] = makeDynInt (0,DPEL_STRUCT);
  
  nameFs[iFs] = makeDynString ("","","devices");
  typeFs[iFs++] = makeDynInt (0, 0,DPEL_DYN_STRING);
    
  return dpTypeChange (nameFs, typeFs);

}

int fwFMCMonitoring_createNetworkBaseDPT(){

  dyn_dyn_string nameBase;
  dyn_dyn_int typeBase;

  int iBase=1;	


  nameBase[iBase] = makeDynString ("FwFMCNetworkBase");
  typeBase[iBase++] = makeDynInt (DPEL_STRUCT);
  
  nameBase[iBase] = makeDynString ("", "server_info");
  typeBase[iBase++] = makeDynInt (0, DPEL_STRUCT);
  
  nameBase[iBase] = makeDynString ("", "", "version");
  typeBase[iBase++] = makeDynInt (0, 0, DPEL_STRING);

  nameBase[iBase] = makeDynString ("", "", "success");
  typeBase[iBase++] = makeDynInt (0, 0, DPEL_INT);
    
  nameBase[iBase] = makeDynString ("","readings");
  typeBase[iBase++] = makeDynInt (0, DPEL_STRUCT);

  nameBase[iBase] = makeDynString ("","", "devices");
  typeBase[iBase++] = makeDynInt (0, 0, DPEL_DYN_STRING);

  
  return dpTypeChange (nameBase, typeBase);

}

//*************
//* createCpu *
//*************
int fwFMCMonitoring_createCpuDPT(){

  dyn_dyn_string nameCpu;
  dyn_dyn_int typeCpu;
  int iCpu=1;	

  nameCpu[iCpu] = makeDynString ("FwFMCCpu");
  typeCpu[iCpu++] = makeDynInt (DPEL_STRUCT);

  nameCpu[iCpu] = makeDynString ("","info");
  typeCpu[iCpu++] = makeDynInt (0,DPEL_STRUCT);
  
  nameCpu[iCpu] = makeDynString ("","","vendor_id");
  typeCpu[iCpu++] = makeDynInt (0,0,DPEL_STRING);

  nameCpu[iCpu] = makeDynString ("","","family");
  typeCpu[iCpu++] = makeDynInt (0,0,DPEL_STRING);

  nameCpu[iCpu] = makeDynString ("","","model");
  typeCpu[iCpu++] = makeDynInt (0,0,DPEL_STRING);

  nameCpu[iCpu] = makeDynString ("","","model_name");
  typeCpu[iCpu++] = makeDynInt (0,0,DPEL_STRING);

  nameCpu[iCpu] = makeDynString ("","","stepping");
  typeCpu[iCpu++] = makeDynInt (0,0,DPEL_STRING);

  nameCpu[iCpu] = makeDynString ("","","clock");
  typeCpu[iCpu++] = makeDynInt (0,0,DPEL_STRING);

  nameCpu[iCpu] = makeDynString ("","","cache_size");
  typeCpu[iCpu++] = makeDynInt (0,0,DPEL_STRING);

  nameCpu[iCpu] = makeDynString ("","","physical_id");
  typeCpu[iCpu++] = makeDynInt (0,0,DPEL_STRING);

  nameCpu[iCpu] = makeDynString ("","","siblings");
  typeCpu[iCpu++] = makeDynInt (0,0,DPEL_STRING);
  
  nameCpu[iCpu] = makeDynString ("","","performance");
  typeCpu[iCpu++] = makeDynInt (0,0,DPEL_STRING);

  nameCpu[iCpu] = makeDynString ("","readings");
  typeCpu[iCpu++] = makeDynInt (0,DPEL_STRUCT);

  nameCpu[iCpu] = makeDynString ("","","user");
  typeCpu[iCpu++] = makeDynInt (0,0,DPEL_FLOAT);

  nameCpu[iCpu] = makeDynString ("","","system");
  typeCpu[iCpu++] = makeDynInt (0,0,DPEL_FLOAT);

  nameCpu[iCpu] = makeDynString ("","","nice");
  typeCpu[iCpu++] = makeDynInt (0,0,DPEL_FLOAT);

  nameCpu[iCpu] = makeDynString ("","","idle");
  typeCpu[iCpu++] = makeDynInt (0,0,DPEL_FLOAT);

  nameCpu[iCpu] = makeDynString ("","","iowait");
  typeCpu[iCpu++] = makeDynInt (0,0,DPEL_FLOAT);

  nameCpu[iCpu] = makeDynString ("","","irq");
  typeCpu[iCpu++] = makeDynInt (0,0,DPEL_FLOAT);

  nameCpu[iCpu] = makeDynString ("","","softirq");
  typeCpu[iCpu++] = makeDynInt (0,0,DPEL_FLOAT);
  
  return dpTypeChange (nameCpu, typeCpu);
}


//*************
//* createMem *
//*************
int fwFMCMonitoring_createMemDPT(){

	dyn_dyn_string nameMem;
	dyn_dyn_int typeMem;

	int iMem=1;	

	nameMem[iMem] = makeDynString ("FwFMCMem");
	typeMem[iMem++] = makeDynInt (DPEL_STRUCT);
        
        nameMem[iMem] = makeDynString ("", "server_info");
        typeMem[iMem++] = makeDynInt (0, DPEL_STRUCT);
  
        nameMem[iMem] = makeDynString ("", "", "version");
        typeMem[iMem++] = makeDynInt (0, 0, DPEL_STRING);

        nameMem[iMem] = makeDynString ("", "", "success");
        typeMem[iMem++] = makeDynInt (0, 0, DPEL_INT);
  
	nameMem[iMem] = makeDynString ("","readings");
	typeMem[iMem++] = makeDynInt (0,DPEL_STRUCT);

	nameMem[iMem] = makeDynString ("","","total");
	typeMem[iMem++] = makeDynInt (0,0,DPEL_INT);

	nameMem[iMem] = makeDynString ("","","free");
	typeMem[iMem++] = makeDynInt (0,0,DPEL_INT);

	nameMem[iMem] = makeDynString ("","","total_swap");
	typeMem[iMem++] = makeDynInt (0,0,DPEL_INT);

	nameMem[iMem] = makeDynString ("","","free_swap");
	typeMem[iMem++] = makeDynInt (0,0,DPEL_INT);

	return dpTypeChange (nameMem, typeMem);
}


//*************
//* createMem *
//*************
int fwFMCMonitoring_createFsDPT(){

	dyn_dyn_string nameFs;
	dyn_dyn_int typeFs;

	int iFs=1;	

	nameFs[iFs] = makeDynString ("FwFMCFs");
	typeFs[iFs++] = makeDynInt (DPEL_STRUCT);
                
	nameFs[iFs] = makeDynString ("","readings");
	typeFs[iFs++] = makeDynInt (0,DPEL_STRUCT);

	nameFs[iFs] = makeDynString ("","","total_root");
	typeFs[iFs++] = makeDynInt (0,0,DPEL_FLOAT);
        
	nameFs[iFs] = makeDynString ("","","user");
	typeFs[iFs++] = makeDynInt (0,0,DPEL_FLOAT);
        
	nameFs[iFs] = makeDynString ("","","file_system");
	typeFs[iFs++] = makeDynInt (0,0,DPEL_STRING);

	nameFs[iFs] = makeDynString ("","","mount_point");
	typeFs[iFs++] = makeDynInt (0,0,DPEL_STRING);

	return dpTypeChange (nameFs, typeFs);
}


//*****************
//* createNetwork *
//*****************
int fwFMCMonitoring_createNetworkDPT(){

	dyn_dyn_string nameNetwork;
	dyn_dyn_int typeNetwork;
	int iNetwork=1;	

	nameNetwork[iNetwork] = makeDynString ("FwFMCNetwork");
	typeNetwork[iNetwork++] = makeDynInt (DPEL_STRUCT);

// info
	nameNetwork[iNetwork] = makeDynString ("","readings");
	typeNetwork[iNetwork++] = makeDynInt (0,DPEL_STRUCT);

	nameNetwork[iNetwork] = makeDynString ("","","rx_bit_rate");
	typeNetwork[iNetwork++] = makeDynInt (0,0,DPEL_FLOAT);

	nameNetwork[iNetwork] = makeDynString ("","","tx_bit_rate");
	typeNetwork[iNetwork++] = makeDynInt (0,0,DPEL_FLOAT);

	nameNetwork[iNetwork] = makeDynString ("","","rx_errors_fraction");
	typeNetwork[iNetwork++] = makeDynInt (0,0,DPEL_FLOAT);

	nameNetwork[iNetwork] = makeDynString ("","","tx_errors_fraction");
	typeNetwork[iNetwork++] = makeDynInt (0,0,DPEL_FLOAT);
	
        nameNetwork[iNetwork] = makeDynString ("","","name");
	typeNetwork[iNetwork++] = makeDynInt (0,0,DPEL_STRING);
        
	return dpTypeChange (nameNetwork, typeNetwork);
}


//*****************
//* createProcess *
//*****************
int fwFMCMonitoring_createProcessDPT(){

	dyn_dyn_string nameProcess;
	dyn_dyn_int typeProcess;

	int iProcess=1;	


	nameProcess[iProcess] = makeDynString ("FwFMCProcess");
	typeProcess[iProcess++] = makeDynInt (DPEL_STRUCT);

	nameProcess[iProcess] = makeDynString ("","info");
	typeProcess[iProcess++] = makeDynInt (0,DPEL_STRUCT);

	nameProcess[iProcess] = makeDynString ("","","server_version");
	typeProcess[iProcess++] = makeDynInt (0,0,DPEL_STRING);

	nameProcess[iProcess] = makeDynString ("","","sensor_version");
	typeProcess[iProcess++] = makeDynInt (0,0,DPEL_STRING);

// alarm
	nameProcess[iProcess] = makeDynString ("","alarm");
	typeProcess[iProcess++] = makeDynInt (0,DPEL_STRUCT);

	nameProcess[iProcess] = makeDynString ("","","alarm");
	typeProcess[iProcess++] = makeDynInt (0,0,DPEL_INT);

	nameProcess[iProcess] = makeDynString ("","","success");
	typeProcess[iProcess++] = makeDynInt (0,0,DPEL_INT);

	nameProcess[iProcess] = makeDynString ("","","nprocs");
	typeProcess[iProcess++] = makeDynInt (0,0,DPEL_INT);

// settings
	nameProcess[iProcess] = makeDynString ("","settings");
	typeProcess[iProcess++] = makeDynInt (0,DPEL_STRUCT);

	nameProcess[iProcess] = makeDynString ("","","alarmSetup");
	typeProcess[iProcess++] = makeDynInt (0,0,DPEL_STRUCT);

	nameProcess[iProcess] = makeDynString ("","","","uneqErr_success");
	typeProcess[iProcess++] = makeDynInt (0,0,0,DPEL_INT);

//	nameProcess[iProcess] = makeDynString ("","","","nprocsMaxWarn");
//	typeProcess[iProcess++] = makeDynInt (0,0,0,DPEL_INT);

	nameProcess[iProcess] = makeDynString ("","","","maxErr_nprocs");
	typeProcess[iProcess++] = makeDynInt (0,0,0,DPEL_INT);

// readings :
	nameProcess[iProcess] = makeDynString ("","readings");
	typeProcess[iProcess++] = makeDynInt (0,DPEL_STRUCT);

	nameProcess[iProcess] = makeDynString ("","","success");
	typeProcess[iProcess++] = makeDynInt (0,0,DPEL_INT);

	nameProcess[iProcess] = makeDynString ("","","nprocs");
	typeProcess[iProcess++] = makeDynInt (0,0,DPEL_INT);

	nameProcess[iProcess] = makeDynString ("","","updates");
	typeProcess[iProcess++] = makeDynInt (0,0,DPEL_DYN_INT);

	nameProcess[iProcess] = makeDynString ("","","CMD");
	typeProcess[iProcess++] = makeDynInt (0,0,DPEL_DYN_STRING);

	nameProcess[iProcess] = makeDynString ("","","SCH");
	typeProcess[iProcess++] = makeDynInt (0,0,DPEL_DYN_STRING);

	nameProcess[iProcess] = makeDynString ("","","TID");
	typeProcess[iProcess++] = makeDynInt (0,0,DPEL_DYN_INT);

	nameProcess[iProcess] = makeDynString ("","","PSR");
	typeProcess[iProcess++] = makeDynInt (0,0,DPEL_DYN_INT);

	nameProcess[iProcess] = makeDynString ("","","RSS");
	typeProcess[iProcess++] = makeDynInt (0,0,DPEL_DYN_INT);

	nameProcess[iProcess] = makeDynString ("","","TTY");
	typeProcess[iProcess++] = makeDynInt (0,0,DPEL_DYN_STRING);

	nameProcess[iProcess] = makeDynString ("","","%MEM");
	typeProcess[iProcess++] = makeDynInt (0,0,DPEL_DYN_FLOAT);

	nameProcess[iProcess] = makeDynString ("","","%CPU");
	typeProcess[iProcess++] = makeDynInt (0,0,DPEL_DYN_FLOAT);

	nameProcess[iProcess] = makeDynString ("","","NICE");
	typeProcess[iProcess++] = makeDynInt (0,0,DPEL_DYN_STRING);

	nameProcess[iProcess] = makeDynString ("","","TGID");
	typeProcess[iProcess++] = makeDynInt (0,0,DPEL_DYN_INT);

	nameProcess[iProcess] = makeDynString ("","","UTGID");
	typeProcess[iProcess++] = makeDynInt (0,0,DPEL_DYN_STRING);

	nameProcess[iProcess] = makeDynString ("","","PPID");
	typeProcess[iProcess++] = makeDynInt (0,0,DPEL_DYN_INT);

	nameProcess[iProcess] = makeDynString ("","","PRIO");
	typeProcess[iProcess++] = makeDynInt (0,0,DPEL_DYN_STRING);

	nameProcess[iProcess] = makeDynString ("","","SIZE");
	typeProcess[iProcess++] = makeDynInt (0,0,DPEL_DYN_INT);

	nameProcess[iProcess] = makeDynString ("","","STAT");
	typeProcess[iProcess++] = makeDynInt (0,0,DPEL_DYN_STRING);

	nameProcess[iProcess] = makeDynString ("","","USER");
	typeProcess[iProcess++] = makeDynInt (0,0,DPEL_DYN_STRING);

	nameProcess[iProcess] = makeDynString ("","","NLWP");
	typeProcess[iProcess++] = makeDynInt (0,0,DPEL_DYN_INT);

	nameProcess[iProcess] = makeDynString ("","","SHARE");
	typeProcess[iProcess++] = makeDynInt (0,0,DPEL_DYN_INT);

	nameProcess[iProcess] = makeDynString ("","","GROUP");
	typeProcess[iProcess++] = makeDynInt (0,0,DPEL_DYN_STRING);

	nameProcess[iProcess] = makeDynString ("","","VSIZE");
	typeProcess[iProcess++] = makeDynInt (0,0,DPEL_DYN_INT);

	nameProcess[iProcess] = makeDynString ("","","RTPRIO");
	typeProcess[iProcess++] = makeDynInt (0,0,DPEL_DYN_STRING);

	nameProcess[iProcess] = makeDynString ("","","CATCHED");
	typeProcess[iProcess++] = makeDynInt (0,0,DPEL_DYN_STRING);

	nameProcess[iProcess] = makeDynString ("","","BLOCKED");
	typeProcess[iProcess++] = makeDynInt (0,0,DPEL_DYN_STRING);

	nameProcess[iProcess] = makeDynString ("","","CMDLINE");
	typeProcess[iProcess++] = makeDynInt (0,0,DPEL_DYN_STRING);

	nameProcess[iProcess] = makeDynString ("","","ELAPSED");
	typeProcess[iProcess++] = makeDynInt (0,0,DPEL_DYN_STRING);

	nameProcess[iProcess] = makeDynString ("","","PENDING");
	typeProcess[iProcess++] = makeDynInt (0,0,DPEL_DYN_STRING);

	nameProcess[iProcess] = makeDynString ("","","IGNORED");
	typeProcess[iProcess++] = makeDynInt (0,0,DPEL_DYN_STRING);

	nameProcess[iProcess] = makeDynString ("","","STARTED");
	typeProcess[iProcess++] = makeDynInt (0,0,DPEL_DYN_STRING);

	nameProcess[iProcess] = makeDynString ("","","CPUTIME");
	typeProcess[iProcess++] = makeDynInt (0,0,DPEL_DYN_STRING);

	return dpTypeChange (nameProcess, typeProcess);
}


//Work functions

bool fwFMCMonitoring_exists(string node, string systemName= "")
{
  if(systemName == "")
    systemName = getSystemName();
  
  string monitoringDp = fwFMCMonitoring_getDp(node, systemName);

  return dpExists(monitoringDp);  
}

string fwFMCMonitoring_getDp(string node, string systemName = "")
{
  if(systemName == "")
    systemName = getSystemName();
  
  string nodeDp = fwFMC_getNodeDp(node, systemName);
  
  return  nodeDp + "/" + "Monitoring";
}


//level = 0 => Standard monitoring  
int fwFMCMonitoring_add(string node, int level = 0)
{
  int err = 0;
  string monitoringDp = fwFMCMonitoring_getDp(node);
  strreplace(monitoringDp, getSystemName(), "");
  
  if(!fwFMCMonitoring_exists(node))
  {
    strreplace(monitoringDp, getSystemName(), "");
    err = dpCreate(monitoringDp, "FwFMCMonitoring");
    
    if(err){
      fwFMC_msg("ERROR: fwFMCMonitoring_add() -> Could not create monitoring dps");
      return -1;
    }
  }
  
  fwFMCMonitoring_setLevel(node, level);  
  
//  err += fwFMCMonitoring_dimSubscribeMonitoringBase(node);  
  err += fwFMCMonitoring_addMemory(node); 
 //  delay(1);
  err += fwFMCMonitoring_addCpu(node);
//  delay(1);
  err += fwFMCMonitoring_addNetwork(node);  
//  delay(1);
  err += fwFMCMonitoring_addFS(node);
//  delay(1);


  //DIM subscriptions:
  err = fwFMCMonitoring_dimSubscribeMonitoringBase(node);
//  delay(1);
  err += fwFMCMonitoring_dimSubscribeFSBase(node);
//  delay(1);
  err += fwFMCMonitoring_dimSubscribeNetworkBase(node);
    
  
//  delay(3); //allow some time so that sensors get updated.
//
//  err += fwFMCMonitoring_createSensors(node);  
//  
//  if(err)
//    return -1;
  dyn_string exception;
  string type = fwFMC_isArchivingEnabled(node);

/*  
  if(type == "Standard")
    fwFMC_setDefaultArchive(node, exception);
  else if(type == "Advanced")
    fwFMC_setDefaultArchive(node, exception, true, true);
  else
    fwFMC_setDefaultArchive(node, exception, false);
  
  if(fwFMC_areAlarmsEnabled(node))  
    fwFMC_setDefaultAlarms(node, exception);

  if(dynlen(exception))
    fwExceptionHandling_display(exception);
*/  
  
  return 0; 
}

/*
int fwFMCMonitoring_createSensors(string node)
{
 
  string dp;
  dyn_string devices, deviceDps;
  int err = 0;
  
  //CPUs:  
  dynClear(deviceDps);
  dynClear(devices);
    
  dp = fwFMCMonitoring_getDp(node);
  string  str= dpSubStr(dp, DPSUB_DP);
    
  fwFMCMonitoring_getDevices(node, "cpu", devices);
  //DebugN("CPU devices: ", node, devices);  

    
  for(int i = 1; i <= dynlen(devices); i++)
  {
    if(devices[i] == "-1")
      continue;
      
    dynAppend(deviceDps, dp + "/Cpus/" + devices[i]);
      
    if(!dpExists(dp + "/Cpus/" + devices[i]))
    {
      DebugN("Creating now device: " + dp + "/Cpus." + devices[i]);
//      dpCreate(dp + "/Cpus/" + devices[i], "FwFMCCpu");

      dpCreate(str + "/Cpus/" + devices[i], "FwFMCCpu");
    }
  }
    
  err = fwFMCMonitoring_dimSubscribeAllDevices(fwFMC_getNodeName(dp), "cpu");

  //FS
  dynClear(deviceDps);
  dynClear(devices);

  
  fwFMCMonitoring_getDevices(node, "fs", devices);
  //DebugN("FS devices: ", devices);  
  
  for(int i = 1; i <= dynlen(devices); i++)
  {
    if(devices[i] == "-1")
      continue;
      
    dynAppend(deviceDps, dp + "/FS/" + devices[i]);
    if(!dpExists(dp + "/FS/" + devices[i]))
    {
      DebugN("Creating now: " + str + "/FS/" + devices[i]);
      strreplace(dp, getSystemName(), "");
//      dpCreate(dp + "/FS/" + devices[i], "FwFMCFs");
//      dpCreate(str + "/FS/" + devices[i], "FwFMCFs");
    }      
  }
    
  err = fwFMCMonitoring_dimSubscribeAllDevices(node, "fs");


  //Network
  dynClear(deviceDps);
  dynClear(devices);
  
  fwFMCMonitoring_getDevices(node, "network", devices);
  //DebugN("Network devices: ", devices);  
    
  for(int i = 1; i <= dynlen(devices); i++)
  {
    if(devices[i] == "-1")
      continue;
      
    dynAppend(deviceDps, dp + "/Network/" + devices[i]);
    if(!dpExists(dp + "/Network/" + devices[i]))
    {
      DebugN("Creating now: " + str + "/Network/" + devices[i]);
      strreplace(dp, getSystemName(), "");
//      dpCreate(dp + "/Network/" + devices[i], "FwFMCNetwork");
      dpCreate(str + "/Network/" + devices[i], "FwFMCNetwork");
    }      
  }
    
  err = fwFMCMonitoring_dimSubscribeAllDevices(node, "network");

  if(err)
    return -1;
    
  return 0;   
}
*/


dyn_string fwFMCMonitoring_getNICs(string node, string systemName)
{
  dyn_string nics;
  
  dpGet(fwFMCMonitoring_getDp(node, systemName) + "/Network.info.name", nics);
  
  return nics;  
}

int fwFMCMonitoring_addCpu(string node)
{
  string str;
  int n = 0;
  string monitoringDp;
  
  if(!fwFMCMonitoring_cpusExists(node))
  {
//    dpCreate(fwFMCMonitoring_getDp(node) + "/Cpus", "FwFMCCpuBase");
    
    monitoringDp = fwFMCMonitoring_getDp(node);
    monitoringDp = dpSubStr(monitoringDp, DPSUB_DP);
                       
    dpCreate(monitoringDp + "/Cpus", "FwFMCCpuBase");
  }

  //Add archiving of average values:  
  dyn_string exception;
  if(fwFMC_isArchivingEnabled(node) != "NONE")
    fwFMC_setArchiveCpuBase(node, exception);

  if(dynlen(exception)>0)
    if(myManType() == UI_MAN)
      fwExceptionHandling_display(exception);
    else
      DebugN(exception);
  
  fwFMCMonitoring_dimSubscribeCpuBase(node);  
  
  return 0;
}

int fwFMCMonitoring_addProcess(string node)
{
  string monitoringDp;
  
  if(!fwFMCMonitoring_processExists(node))
  {
//    dpCreate(fwFMCMonitoring_getDp(node) + "/Processes", "FwFMCProcess");
   
    monitoringDp = fwFMCMonitoring_getDp(node);
    monitoringDp = dpSubStr(monitoringDp, DPSUB_DP);
                       
    dpCreate(monitoringDp + "/Processes", "FwFMCProcess");
  }
  
  fwFMCMonitoring_dimSubscribeProcess(node);
  
  return 0;
}

int fwFMCMonitoring_addMemory(string node)
{
  string monitoringDp;
  
  if(!fwFMCMonitoring_memoryExists(node))
  {
//    dpCreate(fwFMCMonitoring_getDp(node) + "/Memory", "FwFMCMem");
    
    monitoringDp = fwFMCMonitoring_getDp(node);
    monitoringDp = dpSubStr(monitoringDp, DPSUB_DP);
    
    dpCreate(monitoringDp + "/Memory", "FwFMCMem");
  }
  
//DebugN("Calling DIM subscribe memory for node: " + node);  

  fwFMCMonitoring_dimSubscribeMemory(node);
  dyn_string exception;  
  fwFMCMonitoring_connectMemoryDpes(node, exception);
  
//delay(1);

  if(fwFMC_isArchivingEnabled(node) != "NONE")
    fwFMC_setArchiveMemory(node, exception);
  
  if(dynlen(exception))
    fwExceptionHandling_display(exception);
  
  return 0;
}

int fwFMCMonitoring_addFS(string node)
{
  string monitoringDp;
  
  if(!fwFMCMonitoring_fsExists(node))
  {
//    dpCreate(fwFMCMonitoring_getDp(node) + "/FS", "FwFMCFsBase");
    monitoringDp = fwFMCMonitoring_getDp(node);
    monitoringDp = dpSubStr(monitoringDp, DPSUB_DP);
    
    dpCreate(monitoringDp + "/FS", "FwFMCFsBase");
  }
  //fwFMCMonitoring_dimSubscribeFSBase(node);
  
  return 0;
}

int fwFMCMonitoring_addNetwork(string node)
{
  dyn_string nics;
  string str;
  string monitoringDp;
  
  if(!fwFMCMonitoring_networksExists(node))
  {
//    dpCreate(fwFMCMonitoring_getDp(node) + "/Network", "FwFMCNetworkBase");
    monitoringDp = fwFMCMonitoring_getDp(node);
    monitoringDp = dpSubStr(monitoringDp, DPSUB_DP);
    
    dpCreate(monitoringDp + "/Network", "FwFMCNetworkBase");
  }
//  fwFMCMonitoring_dimSubscribeNetworkBase(node);
  
  return 0;
}




/////////////////
bool fwFMCMonitoring_cpusExists(string node, string systemName = "")
{
  if(systemName == "")
    systemName = getSystemName();
  
  return dpExists(fwFMCMonitoring_getDp(node, systemName) + "/Cpus");
}

bool fwFMCMonitoring_processExists(string node, string systemName = "")
{
  if(systemName == "")
    systemName = getSystemName();
  
  return dpExists(fwFMCMonitoring_getDp(node, systemName) + "/Processes");
}

bool fwFMCMonitoring_networksExists(string node, string systemName = "")
{
  if(systemName == "")
    systemName = getSystemName();
  
  return dpExists(fwFMCMonitoring_getDp(node, systemName) + "/Network");
}

bool fwFMCMonitoring_fsExists(string node, string systemName = "")
{
  if(systemName == "")
    systemName = getSystemName();
  
  return dpExists(fwFMCMonitoring_getDp(node, systemName) + "/FS");
}
////////////////////////////////

bool fwFMCMonitoring_cpuExists(string node, int n, string systemName = "")
{
  if(systemName == "")
    systemName = getSystemName();
  
  return dpExists(fwFMCMonitoring_getDp(node, systemName) + "/Cpus/" + n);
}

bool fwFMCMonitoring_networkExists(string node, string nic, string systemName = "")
{
  if(systemName == "")
    systemName = getSystemName();
  
  return dpExists(fwFMCMonitoring_getDp(node, systemName) + "/Network/" + nic);
}


bool fwFMCMonitoring_memoryExists(string node, string systemName = "")
{
  if(systemName == "")
    systemName = getSystemName();
  
  return dpExists(fwFMCMonitoring_getDp(node, systemName) + "/Memory");
}


int fwFMCMonitoring_remove(string node)
{
  int error = 0;
  
  error += fwFMCMonitoring_removeAllCpus(node);
  error += fwFMCMonitoring_removeAllNetwork(node);
  error += fwFMCMonitoring_removeMemory(node);
  error += fwFMCMonitoring_removeAllFS(node);
  error += fwFMCMonitoring_unsubscribeMonitoringBase(node);
  dpSet(fwFMC_getNodeDp(node) + ".agentCommunicationStatus.monitoring.os", 0,
        fwFMC_getNodeDp(node) + ".agentCommunicationStatus.monitoring.memory", 0,
        fwFMC_getNodeDp(node) + ".agentCommunicationStatus.monitoring.fs", 0,
        fwFMC_getNodeDp(node) + ".agentCommunicationStatus.monitoring.cpuinfo", 0,
        fwFMC_getNodeDp(node) + ".agentCommunicationStatus.monitoring.cpustat", 0,
        fwFMC_getNodeDp(node) + ".agentCommunicationStatus.monitoring.network", 0
        );

  
  if(dpExists(fwFMCMonitoring_getDp(node)))
  {
    error += dpDelete(fwFMCMonitoring_getDp(node));  
  }
  
  if(error)
    return -1;
  
  return 0; 
}

int fwFMCMonitoring_removeAllCpus(string node)
{
  dyn_string cpus;

  fwFMCMonitoring_getCpuDps(node, cpus);  
  for(int i = 1; i <= dynlen(cpus); i++)
    dpDelete(cpus[i]);
  
  if(dpExists(fwFMCMonitoring_getDp(node) + "/Cpus"))
  {
    fwFMCMonitoring_unsubscribeAllCpus(node);
    return dpDelete(fwFMCMonitoring_getDp(node) + "/Cpus"); 
  }
  return 0;
}

int fwFMCMonitoring_removeCpu(string node, string device)
{

  if(dpExists(fwFMCMonitoring_getDp(node) + "/Cpus/" + device))
  {
    fwFMCMonitoring_unsubscribeCpu(node, device);
    return dpDelete(fwFMCMonitoring_getDp(node) + "/Cpus/" + device); 
  }
  
  return 0;
}

int fwFMCMonitoring_removeAllFS(string node)
{
  dyn_string fss;
  
  fwFMCMonitoring_getFSDps(node, fss);  
  for(int i = 1; i <= dynlen(fss); i++)
    dpDelete(fss[i]);
  
  if(dpExists(fwFMCMonitoring_getDp(node) + "/FS"))
  {
    fwFMCMonitoring_unsubscribeAllFS(node);
    return dpDelete(fwFMCMonitoring_getDp(node) + "/FS"); 
  }
  return 0;
}

int fwFMCMonitoring_removeFS(string node, string device)
{
  if(dpExists(fwFMCMonitoring_getDp(node) + "/FS/" + device))
  {
    fwFMCMonitoring_unsubscribeFS(node, device);
    return dpDelete(fwFMCMonitoring_getDp(node) + "/FS/" + device); 
  }
  return 0;
}

int fwFMCMonitoring_removeAllNetwork(string node)
{
  dyn_string nics;
  
  fwFMCMonitoring_getNetworkDps(node, nics);  
  for(int i = 1; i <= dynlen(nics); i++)
    dpDelete(nics[i]);
  
  if(dpExists(fwFMCMonitoring_getDp(node) + "/Network"))
  {
      fwFMCMonitoring_unsubscribeAllNetwork(node);
      return dpDelete(fwFMCMonitoring_getDp(node) + "/Network");
  } 
  return 0;
}

int fwFMCMonitoring_removeNIC(string node, string device)
{
  
  if(dpExists(fwFMCMonitoring_getDp(node) + "/Network/" + device))
  {
      fwFMCMonitoring_unsubscribeNIC(node, device);
      return dpDelete(fwFMCMonitoring_getDp(node) + "/Network/" + device);
  } 
  return 0;
}


int fwFMCMonitoring_removeProcess(string node)
{
  if(dpExists(fwFMCMonitoring_getDp(node) + "/Processes"))
  {
    fwFMCMonitoring_unsubscribeProcess(node);    
    return dpDelete(fwFMCMonitoring_getDp(node) + "/Processes");  
  }  
  return 0;
}


int fwFMCMonitoring_removeMemory(string node)
{
  if(dpExists(fwFMCMonitoring_getDp(node) + "/Memory"))
  {
    fwFMCMonitoring_unsubscribeMemory(node);    
    return dpDelete(fwFMCMonitoring_getDp(node) + "/Memory");  
  }  
  return 0;
}

int fwFMCMonitoring_getCpuDps(string node, dyn_string &cpuDps, string systemName = "")
{
  if(systemName == "")
    systemName = getSystemName();
  
  cpuDps = dpNames(fwFMCMonitoring_getDp(node, systemName) + "/Cpus/*", "FwFMCCpu");  
 
  return 0; 
}  

int fwFMCMonitoring_getFSDps(string node, dyn_string &fsDps, string systemName = "")
{
  if(systemName == "")
    systemName = getSystemName();
  
  fsDps = dpNames(fwFMCMonitoring_getDp(node, systemName) + "/FS/*", "FwFMCFs");  
 
  return 0; 
}  

int fwFMCMonitoring_getNetworkDps(string node, dyn_string &networkDps, string systemName = "")
{
  if(systemName == "")
    systemName = getSystemName();
  
  networkDps = dpNames(fwFMCMonitoring_getDp(node, systemName) + "/Network/*", "FwFMCNetwork");  
 
  return 0; 
}  



//DIM
int fwFMCMonitoring_unsubscribeAllCpus(string node) //works only in a local system
{
  dyn_string dp_names;
  dyn_dyn_string all_items;
  string monitoringDp = fwFMCMonitoring_getDp(node);
  
  // a temporary solution for DIM
  monitoringDp = dpSubStr(monitoringDp, DPSUB_DP);
  
//  string configName = fwFMC_getNodeDimConfig(node);
  string configName = FW_FMC_DIM_CONFIG_PERMANENT;

  fwDim_getSubscribedAny(configName, "clientServices", all_items);
  
  if(dynlen(all_items) <= 0)
    return 0;
  else
    dp_names = all_items[1];  
   
//DebugN(">>>>>>>>>>>>>>>>>>>Unbsuscribing CPUs");
     
  if(dynlen(dynPatternMatch(monitoringDp + "/Cpus*", dp_names)))
  {  
//    fwDim_unSubscribeServicesByDp(configName, fwFMCMonitoring_getDp(node) + "/Cpus*");
    fwDim_unSubscribeServicesByDp(configName, monitoringDp + "/Cpus*");
  }
  dynClear(dp_names);
  
  fwDim_getSubscribedAny(configName, "clientCommands", all_items);
  
  if(dynlen(all_items) <= 0)
    return 0;
  else
    dp_names = all_items[1];  
      
  if(dynlen(dynPatternMatch(monitoringDp + "/Cpus*", dp_names)))
  {  
    fwDim_unSubscribeCommandsByDp(configName, monitoringDp + "/Cpus*");
  }

  configName = FW_FMC_DIM_CONFIG_TEMP;

  fwDim_getSubscribedAny(configName, "clientServices", all_items);
  
  if(dynlen(all_items) <= 0)
    return 0;
  else
    dp_names = all_items[1];  
   
   //DebugN("Unbsuscribing CPUs");
     
  if(dynlen(dynPatternMatch(monitoringDp + "/Cpus*", dp_names)))
  {  
    fwDim_unSubscribeServicesByDp(configName, monitoringDp + "/Cpus*");
  }
  dynClear(dp_names);
  
  fwDim_getSubscribedAny(configName, "clientCommands", all_items);
  
  if(dynlen(all_items) <= 0)
    return 0;
  else
    dp_names = all_items[1];  
      
  if(dynlen(dynPatternMatch(monitoringDp + "/Cpus*", dp_names)))
  {  
    fwDim_unSubscribeCommandsByDp(configName, monitoringDp + "/Cpus*");
  }
  
  return 0;
}


int fwFMCMonitoring_unsubscribeCpu(string node, string device) //works only in a local system
{
  dyn_string dp_names;
  dyn_dyn_string all_items;
  string monitoringDp = fwFMCMonitoring_getDp(node);

  // a temporary solution for DIM
  monitoringDp = dpSubStr(monitoringDp, DPSUB_DP);
    
  //string configName = fwFMC_getNodeDimConfig(node);
  string configName = FW_FMC_DIM_CONFIG_PERMANENT;
  
//DebugN(">>>>>>Unsubscribing cpu " + device);

  fwDim_getSubscribedAny(configName, "clientServices", all_items);
  
  if(dynlen(all_items) <= 0)
    return 0;
  else
    dp_names = all_items[1];  

  if(dynlen(dynPatternMatch(monitoringDp + "/Cpus.readings.devices", dp_names)))
  {  
    //DebugN("*****Unsubscribing: " + monitoringDp + "/Cpus.readings.devices");
    
    fwDim_unSubscribeServicesByDp(configName, monitoringDp + "/Cpus.readings.devices");
  }
  
  configName = FW_FMC_DIM_CONFIG_TEMP;

  fwDim_getSubscribedAny(configName, "clientServices", all_items);
  
  if(dynlen(all_items) <= 0)
    return 0;
  else
    dp_names = all_items[1];  
  dynClear(dp_names);
     
 //DebugN("Unbsuscribing CPU: " + fwFMCMonitoring_getDp(node) + "/Cpus/" + device);
     
  if(dynlen(dynPatternMatch(monitoringDp + "/Cpus/" + device, dp_names)))
  {  
    fwDim_unSubscribeServicesByDp(configName, monitoringDp + "/Cpus/" + device);
  }
  dynClear(dp_names);
  
  fwDim_getSubscribedAny(configName, "clientCommands", all_items);
  
  if(dynlen(all_items) <= 0)
    return 0;
  else
    dp_names = all_items[1];  
      
  if(dynlen(dynPatternMatch(monitoringDp + "/Cpus/" + device, dp_names)))
  {  
    fwDim_unSubscribeCommandsByDp(configName, monitoringDp + "/Cpus/" + device);
  }
  return 0;
}

int fwFMCMonitoring_unsubscribeAllTemporaryServices()
{
  string configName = FW_FMC_DIM_CONFIG_TEMP;

//  fwDim_unSubscribeServices(configName, "*", 1);

    
  fwDim_unSubscribeServicesByDp(configName, "*/FS*");
  fwDim_unSubscribeCommandsByDp(configName, "*/FS*");
  fwDim_unSubscribeServicesByDp(configName, "*/Network*");
  fwDim_unSubscribeCommandsByDp(configName, "*/Network*");
  fwDim_unSubscribeServicesByDp(configName, "*.OS.*");
  fwDim_unSubscribeCommandsByDp(configName, "*.OS.*");  

    
  return 0;
}

int fwFMCMonitoring_unsubscribeMonitoringBase(string node) //works only in a local system
{
  dyn_string dp_names;
  dyn_dyn_string all_items;
  string monitoringDp = fwFMCMonitoring_getDp(node);

  // a temporary solution for DIM
  monitoringDp = dpSubStr(monitoringDp, DPSUB_DP);
    
  
//  string configName = fwFMC_getNodeDimConfig(node);
  string configName = FW_FMC_DIM_CONFIG_TEMP;

  fwDim_getSubscribedAny(configName, "clientServices", all_items);
  
  if(dynlen(all_items) <= 0)
    return 0;
  else
    dp_names = all_items[1];  
   
  string dp = fwFMC_getNodeDp(node);
  strreplace(dp, getSystemName(), "");
 
  if(dynlen(dynPatternMatch("*:" + dp + ".agentCommunicationStatus.monitoring.*", dp_names)))
  {  
    fwDim_unSubscribeServicesByDp(configName, "*:" + dp + ".agentCommunicationStatus.monitoring.*");
  }
  
  if(dynlen(dynPatternMatch(dp + ".agentCommunicationStatus.monitoring.*", dp_names)))
  {  
    fwDim_unSubscribeServicesByDp(configName, dp + ".agentCommunicationStatus.monitoring.*");
  }
  
  if(dynlen(dynPatternMatch(monitoringDp + ".OS.*", dp_names)))
  {  
    //DebugN("*****" + dynPatternMatch(fwFMCMonitoring_getDp(node) + ".OS.*", dp_names));

    fwDim_unSubscribeServicesByDp(configName, monitoringDp + ".OS.*", 1);
  }
  dynClear(dp_names);

  // Continuous monitoring: 
  configName = FW_FMC_DIM_CONFIG_PERMANENT;

  fwDim_getSubscribedAny(configName, "clientServices", all_items);
  
  if(dynlen(all_items) <= 0)
    return 0;
  else
    dp_names = all_items[1];  
   
  //DebugN("*****" + fwFMCMonitoring_getDp(node) + ".OS.*");
  
  if(dynlen(dynPatternMatch(dp + ".agentCommunicationStatus.monitoring.*", dp_names)))
  {  
    fwDim_unSubscribeServicesByDp(configName, dp + ".agentCommunicationStatus.monitoring.*");
  }
  
/*  
  fwDim_getSubscribedAny(configName, "clientCommands", all_items);
  
  if(dynlen(all_items) <= 0)
    return 0;
  else
    dp_names = all_items[1];  
      
  if(dynlen(dynPatternMatch(monitoringDp + ".OS.*", dp_names)))
  {  
    fwDim_unSubscribeCommandsByDp(configName, monitoringDp + ".OS.*", 1);
  }
*/
  return 0;
}


int fwFMCMonitoring_unsubscribeAllFS(string node) //works only in a local system
{
  dyn_string dp_names;
  dyn_dyn_string all_items;
  
  string monitoringDp = fwFMCMonitoring_getDp(node);

  // a temporary solution for DIM
  monitoringDp = dpSubStr(monitoringDp, DPSUB_DP);
    
  
//  string configName = fwFMC_getNodeDimConfig(node);
  string configName = FW_FMC_DIM_CONFIG_TEMP;

  fwDim_getSubscribedAny(configName, "clientServices", all_items);
  
  if(dynlen(all_items) <= 0)
    return 0;
  else
    dp_names = all_items[1];  
   
     
  if(dynlen(dynPatternMatch(monitoringDp + "/FS*", dp_names)))
  {  
    fwDim_unSubscribeServicesByDp(configName, monitoringDp + "/FS*");
  }
  dynClear(dp_names);
  
  fwDim_getSubscribedAny(configName, "clientCommands", all_items);
  
  if(dynlen(all_items) <= 0)
    return 0;
  else
    dp_names = all_items[1];  
      
  if(dynlen(dynPatternMatch(monitoringDp + "/FS*", dp_names)))
  {  
    fwDim_unSubscribeCommandsByDp(configName, monitoringDp + "/FS*");
  }
  return 0;
}

int fwFMCMonitoring_unsubscribeFS(string node, string device) //works only in a local system
{
  dyn_string dp_names;
  dyn_dyn_string all_items;
  
  string monitoringDp = fwFMCMonitoring_getDp(node);

// a temporary solution for DIM
  monitoringDp = dpSubStr(monitoringDp, DPSUB_DP);
    
  
//  string configName = fwFMC_getNodeDimConfig(node);
  string configName = FW_FMC_DIM_CONFIG_TEMP;
  
  fwDim_getSubscribedAny(configName, "clientServices", all_items);
  
  if(dynlen(all_items) <= 0)
    return 0;
  else
    dp_names = all_items[1];  
   
  if(dynlen(dynPatternMatch(monitoringDp + "/FS.readings.devices", dp_names)))
  {  
    fwDim_unSubscribeServicesByDp(configName, monitoringDp + "/FS.readings.devices");
  }
       
  if(dynlen(dynPatternMatch(fwFMCMonitoring_getDp(node) + "/FS/" + device + "*", dp_names)))
  {  
    fwDim_unSubscribeServicesByDp(configName, monitoringDp + "/FS/" + device + "*");
  }
  dynClear(dp_names);
  
  fwDim_getSubscribedAny(configName, "clientCommands", all_items);
  
  if(dynlen(all_items) <= 0)
    return 0;
  else
    dp_names = all_items[1];  
      
  if(dynlen(dynPatternMatch(monitoringDp + "/FS/" + device + "*", dp_names)))
  {  
    fwDim_unSubscribeCommandsByDp(configName, monitoringDp + "/FS/" + device + "*");
  }
  return 0;
}


int fwFMCMonitoring_unsubscribeAllNetwork(string node)//works only in a local system
{
  dyn_string dp_names;
  dyn_dyn_string all_items;
  
  
  string monitoringDp = fwFMCMonitoring_getDp(node);

  // a temporary solution for DIM
  monitoringDp = dpSubStr(monitoringDp, DPSUB_DP);
    
  
//  string configName = fwFMC_getNodeDimConfig(node);
  string configName = FW_FMC_DIM_CONFIG_TEMP;

  fwDim_getSubscribedAny(configName, "clientServices", all_items);
  
  if(dynlen(all_items) <= 0)
    return 0;
  else
    dp_names = all_items[1];  
      
  
  //DebugN("services: ", dp_names, "dynlen()", dynlen(dynPatternMatch(fwFMCMonitoring_getDp(node) + "/Network*", dp_names)));
  
  if(dynlen(dynPatternMatch(monitoringDp + "/Network*", dp_names)))
  {  
    fwDim_unSubscribeServicesByDp(configName, monitoringDp + "/Network*");
  }
  dynClear(dp_names);
  
  fwDim_getSubscribedAny(configName, "clientCommands", all_items);
  
  if(dynlen(all_items) <= 0)
    return 0;
  else
    dp_names = all_items[1];  
      
  if(dynlen(dynPatternMatch(monitoringDp + "/Network*", dp_names)))
  {  
    fwDim_unSubscribeCommandsByDp(configName, monitoringDp + "/Network*");
  }
  return 0;
}

int fwFMCMonitoring_unsubscribeNIC(string node, string device) //works only in a local system
{
  dyn_string dp_names;
  dyn_dyn_string all_items;
  
  
  string monitoringDp = fwFMCMonitoring_getDp(node);

  // a temporary solution for DIM
  monitoringDp = dpSubStr(monitoringDp, DPSUB_DP);
    
  
  
//  string configName = fwFMC_getNodeDimConfig(node);
  string configName = FW_FMC_DIM_CONFIG_TEMP;

  fwDim_getSubscribedAny(configName, "clientServices", all_items);
  
  if(dynlen(all_items) <= 0)
    return 0;
  else
    dp_names = all_items[1];  
      
  if(dynlen(dynPatternMatch(monitoringDp + "/Network.readings.devices", dp_names)))
  {  
    fwDim_unSubscribeServicesByDp(configName, monitoringDp + "/Network.readings.devices");
  }
  
  
  if(dynlen(dynPatternMatch(monitoringDp + "/Network/" + device, dp_names)))
  {  
    fwDim_unSubscribeServicesByDp(configName, monitoringDp + "/Network/" + device);
  }
  dynClear(dp_names);
  
  fwDim_getSubscribedAny(configName, "clientCommands", all_items);
  
  if(dynlen(all_items) <= 0)
    return 0;
  else
    dp_names = all_items[1];  
      
  if(dynlen(dynPatternMatch(monitoringDp + "/Network/" + device, dp_names)))
  {  
    fwDim_unSubscribeCommandsByDp(configName, monitoringDp + "/Network/" + device);
  }
  return 0;
}

int fwFMCMonitoring_unsubscribeProcess(string node) //works only in a local system
{
  dyn_string dp_names;
  dyn_dyn_string all_items;
   
  
  string monitoringDp = fwFMCMonitoring_getDp(node);

  // a temporary solution for DIM
  monitoringDp = dpSubStr(monitoringDp, DPSUB_DP);
    
  
//  string configName = fwFMC_getNodeDimConfig(node);

  fwDim_getSubscribedAny(configName, "clientServices", all_items);
  
  if(dynlen(all_items) <= 0)
    return 0;
  else
    dp_names = all_items[1];  
      
  if(dynlen(dynPatternMatch(monitoringDp + "/Processes*", dp_names)))
  {  
    fwDim_unSubscribeServicesByDp(configName, monitoringDp + "/Processes*");
  }
  dynClear(dp_names);
  
  fwDim_getSubscribedAny(configName, "clientCommands", all_items);
  
  if(dynlen(all_items) <= 0)
    return 0;
  else
    dp_names = all_items[1];  
      
  if(dynlen(dynPatternMatch(monitoringDp + "/Processes*", dp_names)))
  {  
    fwDim_unSubscribeCommandsByDp(configName, monitoringDp + "/Processes*");
  }
  return 0;
}

int fwFMCMonitoring_unsubscribeMemory(string node) //works only in a local system
{
  dyn_string dp_names;
  dyn_dyn_string all_items;

  
  string monitoringDp = fwFMCMonitoring_getDp(node);

  // a temporary solution for DIM
  monitoringDp = dpSubStr(monitoringDp, DPSUB_DP);
    
  
//  string configName = fwFMC_getNodeDimConfig(node);
  string configName = FW_FMC_DIM_CONFIG_PERMANENT;

  fwDim_getSubscribedAny(configName, "clientServices", all_items);
  
  if(dynlen(all_items) <= 0)
    return 0;
  else
    dp_names = all_items[1];  
      
  if(dynlen(dynPatternMatch(monitoringDp + "/Memory*", dp_names)))
  {  
    fwDim_unSubscribeServicesByDp(configName, monitoringDp + "/Memory*");
  }
  dynClear(dp_names);
  
  fwDim_getSubscribedAny(configName, "clientCommands", all_items);
  
  if(dynlen(all_items) <= 0)
    return 0;
  else
    dp_names = all_items[1];  
      
  if(dynlen(dynPatternMatch(monitoringDp + "/Memory*", dp_names)))
  {  
    fwDim_unSubscribeCommandsByDp(configName, monitoringDp + "/Memory*");
  }
  return 0;
}



int fwFMCMonitoring_dimSubscribeMemory(string node) //works only in a local system
{
  dyn_string service_names;
  dyn_int defaults;
  dyn_string dp_names;
  string nodeMonitoringDp = fwFMCMonitoring_getDp(node);
//  string configName = fwFMC_getNodeDimConfig(node);
  string configName = FW_FMC_DIM_CONFIG_PERMANENT;
  int index = 1;
  dyn_int flags;
  dyn_int timeouts;
  dyn_int immediate_updates;
  string physicalNodeName = fwFMC_getNodePhysicalName(node);

// a temporary solution for DIM
  nodeMonitoringDp = dpSubStr(nodeMonitoringDp, DPSUB_DP);
  
  //DebugN("DIM Subscription of base Memory services");  
//  fwFMCMonitoring_unsubscribeMemory(node);
  //delay(2);
      
  string nodeDp = fwFMC_getNodeDp(node);
  strreplace(nodeDp, getSystemName(), "");
  dp_names[index] = nodeDp + ".agentCommunicationStatus.monitoring.memory";
  service_names[index] = "/FMC/" + physicalNodeName + "/memory/success";
  defaults[index] = -1;
  timeouts[index] = -2;
  flags[index] = 0;
  immediate_updates[index++] = 1;
  
  dp_names[index] = nodeMonitoringDp + "/Memory.readings";
  service_names[index] = "/FMC/" + physicalNodeName + "/memory/summary/data";
  defaults[index] = -1;
  timeouts[index] = -2;
  flags[index] = 0;
  immediate_updates[index++] = 1;
  
/*  dp_names[index] = nodeMonitoringDp + "/Memory.server_info.version";
  service_names[index] = "/FMC/" + physicalNodeName + "/memory/version";
  defaults[index] = -1;
  timeouts[index] = -2;
  flags[index] = 0;
  immediate_updates[index++] = 1;
*/
    
  
//  dp_names[index] = nodeMonitoringDp + "/Memory.server_info.success";
  
//DebugN("subscribing memory: ", service_names, dp_names, configName);  

  fwDim_subscribeServices(configName, service_names, dp_names, defaults, timeouts, flags, immediate_updates, FW_FMC_DIM_SAVE_NOW);
  
  return 0;
}

int fwFMCMonitoring_dimSubscribeProcess(string node) //works only in a local system
{
  dyn_string service_names;
  dyn_int defaults;
  dyn_string dp_names;
  string nodeMonitoringDp = fwFMCMonitoring_getDp(node);
//  string configName = fwFMC_getNodeDimConfig(node);
  int index = 1;
  dyn_int flags;
  dyn_int timeouts;
  dyn_int immediate_updates;
  string physicalNodeName = fwFMC_getNodePhysicalName(node);
  string nodeDp = fwFMC_getNodeDp(node);
  strreplace(nodeDp, getSystemName(), "");

// a temporary solution for DIM
  nodeMonitoringDp = dpSubStr(nodeMonitoringDp, DPSUB_DP);
  
//    fwFMCMonitoring_unsubscribeProcess(node);


/*	dp_names[index] = nodeMonitoringDp + "/Processes.info.server_version";
	  service_names[index] = "/FMC/" + physicalNodeName + "/procs/server_version";
	    defaults[index] = -1;
	      timeouts[index] = -2;
	        flags[index] = 0;
	          immediate_updates[index++] = 1;
*/

 dp_names[index] = nodeDp + ".agentCommunicationStatus.process";
//	dp_names[index] = nodeMonitoringDp + "/Processes.readings.success";
	  service_names[index] = "/FMC/" + physicalNodeName + "/procs/success";
	    defaults[index] = -1;
	      timeouts[index] = -2;
	        flags[index] = 0;
	          immediate_updates[index++] = 1;

	dp_names[index] = nodeMonitoringDp + "/Processes.readings.nprocs";
	  service_names[index] = "/FMC/" + physicalNodeName + "/procs/nprocs";
	    defaults[index] = -1;
	      timeouts[index] = -2;
	        flags[index] = 0;
	          immediate_updates[index++] = 1;


      if(fwFMCMonitoring_getLevel(node) > 0)
      {                            
	dp_names[index] = nodeMonitoringDp + "/Processes.readings.updates";
	  service_names[index] = "/FMC/" + physicalNodeName + "/procs/updates";
	    defaults[index] = -1;
	      timeouts[index] = -2;
	        flags[index] = 0;
	          immediate_updates[index++] = 1;
      
	dp_names[index] = nodeMonitoringDp + "/Processes.readings.SCH";
	  service_names[index] = "/FMC/" + physicalNodeName + "/procs/SCH";
	    defaults[index] = -1;
	      timeouts[index] = -2;
	        flags[index] = 0;
	          immediate_updates[index++] = 1;

	dp_names[index] = nodeMonitoringDp + "/Processes.readings.TID";
	  service_names[index] = "/FMC/" + physicalNodeName + "/procs/TID";
	    defaults[index] = -1;
	      timeouts[index] = -2;
	        flags[index] = 0;
	          immediate_updates[index++] = 1;

	dp_names[index] = nodeMonitoringDp + "/Processes.readings.PSR";
	  service_names[index] = "/FMC/" + physicalNodeName + "/procs/PSR";
	    defaults[index] = -1;
	      timeouts[index] = -2;
	        flags[index] = 0;
	          immediate_updates[index++] = 1;

	dp_names[index] = nodeMonitoringDp + "/Processes.readings.RSS";
	  service_names[index] = "/FMC/" + physicalNodeName + "/procs/RSS";
	    defaults[index] = -1;
	      timeouts[index] = -2;
	        flags[index] = 0;
	          immediate_updates[index++] = 1;

	dp_names[index] = nodeMonitoringDp + "/Processes.readings.TTY";
	  service_names[index] = "/FMC/" + physicalNodeName + "/procs/TTY";
	    defaults[index] = -1;
	      timeouts[index] = -2;
	        flags[index] = 0;
	          immediate_updates[index++] = 1;
                  
	dp_names[index] = nodeMonitoringDp + "/Processes.readings.NICE";
	  service_names[index] = "/FMC/" + physicalNodeName + "/procs/NICE";
	    defaults[index] = -1;
	      timeouts[index] = -2;
	        flags[index] = 0;
	          immediate_updates[index++] = 1;
                  
                  
	dp_names[index] = nodeMonitoringDp + "/Processes.readings.UTGID";
	  service_names[index] = "/FMC/" + physicalNodeName + "/procs/UTGID";
	    defaults[index] = -1;
	      timeouts[index] = -2;
	        flags[index] = 0;
	          immediate_updates[index++] = 1;

	dp_names[index] = nodeMonitoringDp + "/Processes.readings.PPID";
	  service_names[index] = "/FMC/" + physicalNodeName + "/procs/PPID";
	    defaults[index] = -1;
	      timeouts[index] = -2;
	        flags[index] = 0;
	          immediate_updates[index++] = 1;

	dp_names[index] = nodeMonitoringDp + "/Processes.readings.PRIO";
	  service_names[index] = "/FMC/" + physicalNodeName + "/procs/PRIO";
	    defaults[index] = -1;
	      timeouts[index] = -2;
	        flags[index] = 0;
	          immediate_updates[index++] = 1;

	dp_names[index] = nodeMonitoringDp + "/Processes.readings.SIZE";
	  service_names[index] = "/FMC/" + physicalNodeName + "/procs/SIZE";
	    defaults[index] = -1;
	      timeouts[index] = -2;
	        flags[index] = 0;
	          immediate_updates[index++] = 1;

                  
	dp_names[index] = nodeMonitoringDp + "/Processes.readings.NLWP";
	  service_names[index] = "/FMC/" + physicalNodeName + "/procs/NLWP";
	    defaults[index] = -1;
	      timeouts[index] = -2;
	        flags[index] = 0;
	          immediate_updates[index++] = 1;

	dp_names[index] = nodeMonitoringDp + "/Processes.readings.SHARE";
	  service_names[index] = "/FMC/" + physicalNodeName + "/procs/SHARE";
	    defaults[index] = -1;
	      timeouts[index] = -2;
	        flags[index] = 0;
	          immediate_updates[index++] = 1;

	dp_names[index] = nodeMonitoringDp + "/Processes.readings.GROUP";
	  service_names[index] = "/FMC/" + physicalNodeName + "/procs/GROUP";
	    defaults[index] = -1;
	      timeouts[index] = -2;
	        flags[index] = 0;
	          immediate_updates[index++] = 1;
                  
                  
	dp_names[index] = nodeMonitoringDp + "/Processes.readings.RTPRIO";
	  service_names[index] = "/FMC/" + physicalNodeName + "/procs/RTPRIO";
	    defaults[index] = -1;
	      timeouts[index] = -2;
	        flags[index] = 0;
	          immediate_updates[index++] = 1;

	dp_names[index] = nodeMonitoringDp + "/Processes.readings.CATCHED";
	  service_names[index] = "/FMC/" + physicalNodeName + "/procs/CATCHED";
	    defaults[index] = -1;
	      timeouts[index] = -2;
	        flags[index] = 0;
	          immediate_updates[index++] = 1;

	dp_names[index] = nodeMonitoringDp + "/Processes.readings.BLOCKED";
	  service_names[index] = "/FMC/" + physicalNodeName + "/procs/BLOCKED";
	    defaults[index] = -1;
	      timeouts[index] = -2;
	        flags[index] = 0;
	          immediate_updates[index++] = 1;

	dp_names[index] = nodeMonitoringDp + "/Processes.readings.CMDLINE";
	  service_names[index] = "/FMC/" + physicalNodeName + "/procs/CMDLINE";
	    defaults[index] = -1;
	      timeouts[index] = -2;
	        flags[index] = 0;
	          immediate_updates[index++] = 1;

	dp_names[index] = nodeMonitoringDp + "/Processes.readings.ELAPSED";
	  service_names[index] = "/FMC/" + physicalNodeName + "/procs/ELAPSED";
	    defaults[index] = -1;
	      timeouts[index] = -2;
	        flags[index] = 0;
	          immediate_updates[index++] = 1;

	dp_names[index] = nodeMonitoringDp + "/Processes.readings.PENDING";
	  service_names[index] = "/FMC/" + physicalNodeName + "/procs/PENDING";
	    defaults[index] = -1;
	      timeouts[index] = -2;
	        flags[index] = 0;
	          immediate_updates[index++] = 1;

	dp_names[index] = nodeMonitoringDp + "/Processes.readings.IGNORED";
	  service_names[index] = "/FMC/" + physicalNodeName + "/procs/IGNORED";
	    defaults[index] = -1;
	      timeouts[index] = -2;
	        flags[index] = 0;
	          immediate_updates[index++] = 1;
                                    
                  
      }

	dp_names[index] = nodeMonitoringDp + "/Processes.readings.CMD";
	  service_names[index] = "/FMC/" + physicalNodeName + "/procs/CMD";
	    defaults[index] = -1;
	      timeouts[index] = -2;
	        flags[index] = 0;
	          immediate_updates[index++] = 1;


	dp_names[index] = nodeMonitoringDp + "/Processes.readings.%MEM";
	  service_names[index] = "/FMC/" + physicalNodeName + "/procs/%MEM";
	    defaults[index] = -1;
	      timeouts[index] = -2;
	        flags[index] = 0;
	          immediate_updates[index++] = 1;

	dp_names[index] = nodeMonitoringDp + "/Processes.readings.%CPU";
	  service_names[index] = "/FMC/" + physicalNodeName + "/procs/%CPU";
	    defaults[index] = -1;
	      timeouts[index] = -2;
	        flags[index] = 0;
	          immediate_updates[index++] = 1;


	dp_names[index] = nodeMonitoringDp + "/Processes.readings.TGID";
	  service_names[index] = "/FMC/" + physicalNodeName + "/procs/TGID";
	    defaults[index] = -1;
	      timeouts[index] = -2;
	        flags[index] = 0;
	          immediate_updates[index++] = 1;


	dp_names[index] = nodeMonitoringDp + "/Processes.readings.STAT";
	  service_names[index] = "/FMC/" + physicalNodeName + "/procs/STAT";
	    defaults[index] = -1;
	      timeouts[index] = -2;
	        flags[index] = 0;
	          immediate_updates[index++] = 1;

	dp_names[index] = nodeMonitoringDp + "/Processes.readings.USER";
	  service_names[index] = "/FMC/" + physicalNodeName + "/procs/USER";
	    defaults[index] = -1;
	      timeouts[index] = -2;
	        flags[index] = 0;
	          immediate_updates[index++] = 1;


	dp_names[index] = nodeMonitoringDp + "/Processes.readings.VSIZE";
	  service_names[index] = "/FMC/" + physicalNodeName + "/procs/VSIZE";
	    defaults[index] = -1;
	      timeouts[index] = -2;
	        flags[index] = 0;
	          immediate_updates[index++] = 1;


	dp_names[index] = nodeMonitoringDp + "/Processes.readings.STARTED";
	  service_names[index] = "/FMC/" + physicalNodeName + "/procs/STARTED";
	    defaults[index] = -1;
	      timeouts[index] = -2;
	        flags[index] = 0;
	          immediate_updates[index++] = 1;

	dp_names[index] = nodeMonitoringDp + "/Processes.readings.CPUTIME";
	  service_names[index] = "/FMC/" + physicalNodeName + "/procs/CPUTIME";
	    defaults[index] = -1;
	      timeouts[index] = -2;
	        flags[index] = 0;
	          immediate_updates[index++] = 1;

  
  fwDim_subscribeServices(configName, service_names, dp_names, defaults, timeouts, flags, immediate_updates, FW_FMC_DIM_SAVE_NOW);
  
  return 0;
}


int fwFMCMonitoring_dimSubscribeNetworkBase(string node) //works only in a local system
{
  dyn_string service_names;
  dyn_int defaults;
  dyn_string dp_names;
  string nodeMonitoringDp = fwFMCMonitoring_getDp(node);
//  string configName = fwFMC_getNodeDimConfig(node);
  string configName = FW_FMC_DIM_CONFIG_TEMP;
  int index = 1;
  dyn_int flags;
  dyn_int timeouts;
  dyn_int immediate_updates;
  string physicalNodeName = fwFMC_getNodePhysicalName(node);
  dyn_string cmd_names;
  dyn_string cmd_dp_names;

// a temporary solution for DIM
  nodeMonitoringDp = dpSubStr(nodeMonitoringDp, DPSUB_DP);
  
  //DebugN("DIM Subscription of base Network services");
    
//    fwFMCMonitoring_unsubscribeAllNetwork(node);                  
	dp_names[index] = nodeMonitoringDp + "/Network.readings.devices";
	  service_names[index] = "/FMC/" + physicalNodeName + "/net/ifs/devices";
	    defaults[index] = -1;
	      timeouts[index] = -2;
	        flags[index] = 0;
	          immediate_updates[index++] = 1;

//    fwFMCMonitoring_unsubscribeAllNetwork(node);                  
    
 string nodeDp = fwFMC_getNodeDp(node);   
 strreplace(nodeDp, getSystemName(), "");
 dp_names[index] = nodeDp + ".agentCommunicationStatus.monitoring.network";
//	dp_names[index] = nodeMonitoringDp + "/Network.server_info.success";
	  service_names[index] = "/FMC/" + physicalNodeName + "/net/ifs/success";
	    defaults[index] = -1;
	      timeouts[index] = -2;
	        flags[index] = 0;
	          immediate_updates[index++] = 1;

/*    fwFMCMonitoring_unsubscribeAllNetwork(node);                  
	dp_names[index] = nodeMonitoringDp + "/Network.server_info.version";
	  service_names[index] = "/FMC/" + physicalNodeName + "/nif/version";
	    defaults[index] = -1;
	      timeouts[index] = -2;
	        flags[index] = 0;
	          immediate_updates[index++] = 1;
*/
  //DebugN("DIM Subscription of base Network serv", configName, service_names, dp_names);                
  fwDim_subscribeServices(configName, service_names, dp_names, defaults, timeouts, flags, immediate_updates, FW_FMC_DIM_SAVE_NOW);
  
//  cmd_dp_names[index] = nodeMonitoringDp + "/Network.settings.reset";
//  cmd_names[index++] = "/" + physicalNodeName + "/nif/reset";

//  fwDim_subscribeCommands(configName, cmd_names, cmd_dp_names);          
  
  return 0; 
}  



int fwFMCMonitoring_dimSubscribeNIC(string node, string nic) //works only in a local system
{
  dyn_string service_names;
  dyn_int defaults;
  dyn_string dp_names;
  string nodeMonitoringDp = fwFMCMonitoring_getDp(node);
//  string configName = fwFMC_getNodeDimConfig(node);
  string configName = FW_FMC_DIM_CONFIG_TEMP;
  int index = 1;
  dyn_int flags;
  dyn_int timeouts;
  dyn_int immediate_updates;
  string physicalNodeName = fwFMC_getNodePhysicalName(node);
  dyn_string cmd_names;
  dyn_string cmd_dp_names;

  if(nic == -1) //nothing to be done
    return 0;
  
  
// a temporary solution for DIM
  nodeMonitoringDp = dpSubStr(nodeMonitoringDp, DPSUB_DP);
  
    
  dp_names[index] = nodeMonitoringDp + "/Network/" + nic + ".readings";
  service_names[index] = "/FMC/" + physicalNodeName + "/net/ifs/summary/"+ nic +"/data";
  defaults[index] = -1;
  timeouts[index] = -2;
  flags[index] = 0;
  immediate_updates[index++] = 1;
  
//  fwFMCMonitoring_unsubscribeNIC(node, nic);
  
  
  fwDim_subscribeServices(configName, service_names, dp_names, defaults, timeouts, flags, immediate_updates, FW_FMC_DIM_SAVE_NOW);

//  cmd_dp_names[index] = nodeMonitoringDp + "/Network.settings.reset";
//  cmd_names[index++] = "/" + physicalNodeName + "/nif/reset";
//  fwDim_subscribeCommands(configName, cmd_names, cmd_dp_names);
  
      
  return 0; 
} 
    
int fwFMCMonitoring_dimSubscribeFSBase(string node) //works only in  a local system
{
  dyn_string service_names;
  dyn_int defaults;
  dyn_string dp_names;
  string nodeMonitoringDp = fwFMCMonitoring_getDp(node);
//  string configName = fwFMC_getNodeDimConfig(node);
  string configName = FW_FMC_DIM_CONFIG_TEMP;
  int index = 1;
  dyn_int flags;
  dyn_int timeouts;
  dyn_int immediate_updates;
  string physicalNodeName = fwFMC_getNodePhysicalName(node);
 
  
// a temporary solution for DIM
  nodeMonitoringDp = dpSubStr(nodeMonitoringDp, DPSUB_DP);
  
  
  //DebugN("DIM Subscription of base FS services");
  
//  fwFMCMonitoring_unsubscribeAllFS(node);                  
  
/*  dp_names[index] = nodeMonitoringDp + "/FS.server_info.version";
  service_names[index] = "/FMC/" + physicalNodeName + "/filesystems/server_version";
  defaults[index] = -1;
  timeouts[index] = -2;
  flags[index] = 0;
  immediate_updates[index++] = 1;
*/
  string nodeDp = fwFMC_getNodeDp(node);   
  strreplace(nodeDp, getSystemName(), "");
  dp_names[index] = nodeDp + ".agentCommunicationStatus.monitoring.fs";
  //dp_names[index] = nodeMonitoringDp + "/FS.server_info.success";
  service_names[index] = "/FMC/" + physicalNodeName + "/filesystems/success";
  defaults[index] = -1;
  timeouts[index] = -2;
  flags[index] = 0;
  immediate_updates[index++] = 1;

    
  dp_names[index] = nodeMonitoringDp + "/FS.readings.devices";
  service_names[index] = "/FMC/" + physicalNodeName + "/filesystems/devices";
  defaults[index] = -1;
  timeouts[index] = -2;
  flags[index] = 0;
  immediate_updates[index++] = 1;

  fwDim_subscribeServices(configName, service_names, dp_names, defaults, timeouts, flags, immediate_updates, FW_FMC_DIM_SAVE_NOW);
  
  return 0; 
} 

int fwFMCMonitoring_dimSubscribeFS(string node, string device) //works only in a local system
{
  dyn_string service_names;
  dyn_int defaults;
  dyn_string dp_names;
  string nodeMonitoringDp = fwFMCMonitoring_getDp(node);
//  string configName = fwFMC_getNodeDimConfig(node);
  string configName = FW_FMC_DIM_CONFIG_TEMP;
  int index = 1;
  dyn_int flags;
  dyn_int timeouts;
  dyn_int immediate_updates;
  string physicalNodeName = fwFMC_getNodePhysicalName(node);

// a temporary solution for DIM
  nodeMonitoringDp = dpSubStr(nodeMonitoringDp, DPSUB_DP);  
  
  if(device == -1) //nothiing to be done
    return 0;
  
//  fwFMCMonitoring_unsubscribeFS(node, device);

  
  dp_names[index] = nodeMonitoringDp + "/FS/" + device + ".readings";
  //DebugN("Mapping: " + "/FMC/" + physicalNodeName + "/filesystems/summary/" + device + "/data");
  service_names[index] = "/FMC/" + physicalNodeName + "/filesystems/summary/" + device + "/data";
  defaults[index] = -1;
  timeouts[index] = -2;
  flags[index] = 0;
  immediate_updates[index++] = 1;

  fwDim_subscribeServices(configName, service_names, dp_names, defaults, timeouts, flags, immediate_updates, FW_FMC_DIM_SAVE_NOW);
  
  return 0; 
} 

int fwFMCMonitoring_dimSubscribeCpuBase(string node)
{
  dyn_string service_names;
  dyn_int defaults;
  dyn_string dp_names;
  string nodeMonitoringDp = fwFMCMonitoring_getDp(node);
//  string configName = fwFMC_getNodeDimConfig(node);
  string configName = FW_FMC_DIM_CONFIG_PERMANENT;
  int index = 1;
  dyn_int flags;
  dyn_int timeouts;
  dyn_int immediate_updates;
  string physicalNodeName = fwFMC_getNodePhysicalName(node);

// a temporary solution for DIM
  nodeMonitoringDp = dpSubStr(nodeMonitoringDp, DPSUB_DP);  
  
  
  //DebugN("DIM Subscription of base CPU services");
  
//  fwFMCMonitoring_unsubscribeAllCpus(node);

/*  dp_names[index] = nodeMonitoringDp + "/Cpus.server_info.cpustat.version";
  service_names[index] = "/FMC/" + physicalNodeName + "/cpu/stat/version";
  defaults[index] = -1;
  timeouts[index] = -2;
  flags[index] = 0;
  immediate_updates[index++] = 1;
*/
  string nodeDp = fwFMC_getNodeDp(node);   
  strreplace(nodeDp, getSystemName(), "");
  dp_names[index] = nodeDp + ".agentCommunicationStatus.monitoring.cpustat";
  //dp_names[index] = nodeMonitoringDp + "/Cpus.server_info.cpustat.success";
  service_names[index] = "/FMC/" + physicalNodeName + "/cpu/stat/success";
  defaults[index] = -1;
  timeouts[index] = -2;
  flags[index] = 0;
  immediate_updates[index++] = 1;

  
/*  dp_names[index] = nodeMonitoringDp + "/Cpus.server_info.cpuinfo.version";
  service_names[index] = "/FMC/" + physicalNodeName + "/cpu/info/version";
  defaults[index] = -1;
  timeouts[index] = -2;
  flags[index] = 0;
  immediate_updates[index++] = 1;
*/
  string nodeDp = fwFMC_getNodeDp(node);   
  strreplace(nodeDp, getSystemName(), "");
  dp_names[index] = nodeDp + ".agentCommunicationStatus.monitoring.cpuinfo";
//  dp_names[index] = nodeMonitoringDp + "/Cpus.server_info.cpuinfo.success";
  service_names[index] = "/FMC/" + physicalNodeName + "/cpu/info/success";
  defaults[index] = -1;
  timeouts[index] = -2;
  flags[index] = 0;
  immediate_updates[index++] = 1;


  dp_names[index] = nodeMonitoringDp + "/Cpus.readings.averageLoad";
  service_names[index] = "/FMC/" + physicalNodeName + "/cpu/stat/load/average/data";
  defaults[index] = -1;
  timeouts[index] = -2;
  flags[index] = 0;
  immediate_updates[index++] = 1;

/*  dp_names[index] = nodeMonitoringDp + "/Cpus.readings.ctxtRate";
  service_names[index] = "/FMC/" + physicalNodeName + "/cpu/stat/ctxt/data";
  defaults[index] = -1;
  timeouts[index] = -2;
  flags[index] = 0;
  immediate_updates[index++] = 1;
*/
                  
  dp_names[index] = nodeMonitoringDp + "/Cpus.readings.devices";
  service_names[index] = "/FMC/" + physicalNodeName + "/cpu/stat/devices";
  defaults[index] = -1;
  timeouts[index] = -2;
  flags[index] = 0;
  immediate_updates[index++] = 1;

  fwDim_subscribeServices(configName, service_names, dp_names, defaults, timeouts, flags, immediate_updates, FW_FMC_DIM_SAVE_NOW);
  
  return 0; 
}  

int fwFMCMonitoring_dimSubscribeMonitoringBase(string node) //works only in a local system
{
  dyn_string service_names;
  dyn_int defaults;
  dyn_string dp_names;
  string nodeMonitoringDp = fwFMCMonitoring_getDp(node);
//  string configName = fwFMC_getNodeDimConfig(node);
  string configName = FW_FMC_DIM_CONFIG_TEMP;
  int index = 1;
  dyn_int flags;
  dyn_int timeouts;
  dyn_int immediate_updates;
  string physicalNodeName = fwFMC_getNodePhysicalName(node);

// a temporary solution for DIM
  nodeMonitoringDp = dpSubStr(nodeMonitoringDp, DPSUB_DP);  
    
  
  //DebugN("DIM Subscription of base OS services");
  //DebugN("***** dim config: " + configName);
  
//    fwFMCMonitoring_unsubscribeMonitoringBase(node);

	dp_names[index] = nodeMonitoringDp + ".OS.readings";
	  service_names[index] = "/FMC/" + physicalNodeName + "/os/data";
	    defaults[index] = -1;
	      timeouts[index] = -2;
	        flags[index] = 0;
	          immediate_updates[index++] = 1;

/*	dp_names[index] = nodeMonitoringDp + ".OS.server_info.version";
	  service_names[index] = "/FMC/" + physicalNodeName + "/os/server_version";
	    defaults[index] = -1;
	      timeouts[index] = -2;
	        flags[index] = 0;
	          immediate_updates[index++] = 1;
*/
  string nodeDp = fwFMC_getNodeDp(node);   
  strreplace(nodeDp, getSystemName(), "");
  dp_names[index] = nodeDp + ".agentCommunicationStatus.monitoring.os";
//	dp_names[index] = nodeMonitoringDp + ".OS.server_info.success";
	  service_names[index] = "/FMC/" + physicalNodeName + "/os/success";
	    defaults[index] = -1;
	      timeouts[index] = -2;
	        flags[index] = 0;
	          immediate_updates[index++] = 1;

  fwDim_subscribeServices(configName, service_names, dp_names, defaults, timeouts, flags, immediate_updates, FW_FMC_DIM_SAVE_NOW);
  
  return 0; 
}  
int fwFMCMonitoring_dimSubscribeAllDevices(string node, string type) //works only in a local system
{
  int err = 0;
  dyn_string devices;
  
  type = strtolower(type);
  fwFMCMonitoring_getDevices(node, type, devices);
  
  for(int i = 1; i <= dynlen(devices); i++)
  {
    if(devices[i] == -1)
      continue;
    
    if(type == "cpu")
      err += fwFMCMonitoring_dimSubscribeCpu(node, devices[i]);
    else if(type == "fs")
      err += fwFMCMonitoring_dimSubscribeFS(node, devices[i]);
    else if(type == "network")
      err += fwFMCMonitoring_dimSubscribeNIC(node, devices[i]);
    else
    {
      DebugN("ERROR: fwFMCMonitoring_dimSubscribeAllDevices() -> Cannot make DIM subscriptions. Unknown device type: " + type);
      return -1;
    }
  }
  if(err)
    return -1;        
       
  return 0;
        
}    

int fwFMCMonitoring_dimSubscribeCpu(string node, string device) //works only in a local system
{
  dyn_string service_names;
  dyn_int defaults;
  dyn_string dp_names;
  string nodeMonitoringDp = fwFMCMonitoring_getDp(node);
//  string configName = fwFMC_getNodeDimConfig(node);
  string configName = FW_FMC_DIM_CONFIG_TEMP;
  int index = 1;
  dyn_int flags;
  dyn_int timeouts;
  dyn_int immediate_updates;
  string physicalNodeName = fwFMC_getNodePhysicalName(node);
  string str;

// a temporary solution for DIM
  nodeMonitoringDp = dpSubStr(nodeMonitoringDp, DPSUB_DP);  
    
   
//  DebugN("DIM subscription for core: " + device + " dim config: " + configName);  
  if(device == -1) //nothiing to be done
    return 0;
   
//  fwFMCMonitoring_unsubscribeCpu(node, device);
  
  dp_names[index] = nodeMonitoringDp + "/Cpus/" + device + ".readings";
  service_names[index] = "/FMC/" + physicalNodeName + "/cpu/stat/load/" + device + "/data";
  defaults[index] = -1;
  timeouts[index] = -2;
  flags[index] = 0;
  immediate_updates[index++] = 1;

  dp_names[index] = nodeMonitoringDp + "/Cpus/" + device + ".info";
  service_names[index] = "/FMC/" + physicalNodeName + "/cpu/info/" + device + "/data";
  defaults[index] = -1;
  timeouts[index] = -2;
  flags[index] = 0;
  immediate_updates[index++] = 1;

//DebugN("config_name, service_names, dp_names", service_names, dp_names);  
  
  fwDim_subscribeServices(configName, service_names, dp_names, defaults, timeouts, flags, immediate_updates, FW_FMC_DIM_SAVE_NOW);
  
  return 0; 
}


int fwFMCMonitoring_getLevel(string node, string systemName = "")
{
  int level;
  
  if(systemName == "")
    systemName = getSystemName();
  
  if(dpExists(fwFMCMonitoring_getDp(node, systemName) + ".level"))
    dpGet(fwFMCMonitoring_getDp(node, systemName) + ".level", level);
  else
    level = 0;
  
  return level;
}

int fwFMCMonitoring_setLevel(string node, int level)
{
  string dp = fwFMCMonitoring_getDp(node);
  strreplace(dp, getSystemName(), "");
      
  return dpSet(dp + ".level", level);

}

//New functions:
int fwFMCMonitoring_getDevices(string node, string type, dyn_string &devices, string systemName = "")
{
  if(systemName == "")
    systemName = getSystemName();
  
  string pattern;
  
  type = strtolower(type);
  
  switch(type)
  {
    case "cpu": pattern = "Cpus";
      break;
    case "network": pattern = "Network";
      break;
    case "fs": pattern = "FS";
      break;
    default:
      DebugN("ERROR: fwFMCMonitoring_getDevices() -> Unknown device type: " + type);
      return -1;   
  }

//  DebugN("Looking for dps that match: " + fwFMCMonitoring_getDp(node, systemName) + "/" + pattern + "*");  
  dyn_string dps = dpNames(fwFMCMonitoring_getDp(node, systemName) + "/" + pattern + "/*");
  for(int i = 1; i <= dynlen(dps); i++)
  {
    dyn_string ds = strsplit(dps[i], "/");
    dynAppend(devices, ds[dynlen(ds)]);
  }
  //dpGet(fwFMCMonitoring_getDp(node, systemName) + "/" + pattern + ".readings.devices", devices);
  
  return 0;
}
    
fwFMCMonitoring_createCpuCB(string ident, dyn_dyn_anytype val)
{
  string dp;
  string node;
  dyn_string ds;
  string temp;
  bool found = false;  
  dyn_string devices;
  dyn_string existingDevices; 
  bool cpusExists;
  
  if(dynlen(val) < 2)
    return;
  

  for(int i = 2; i <= dynlen(val); i++)
  {
    if(val[i][2] == "")
      continue;
   
    devices = val[i][2];
    //find out node dp and list of existing devices:
    temp = val[i][1];
    ds = strsplit(temp, ".");
    dp = ds[1];
  
    if(patternMatch(getSystemName() + "*", dp))
      strreplace(dp, getSystemName(), "");
  
    node = fwFMC_getNodeName(dp); 
    //this variable is used when the archiving is set, in order not to override the archiving each time the project restarts
    cpusExists =  fwFMCMonitoring_cpusExists(node);
    dynClear(existingDevices);
    fwFMCMonitoring_getDevices(node, "cpu", existingDevices);
  
    for(int k = 1; k <= dynlen(devices); k++)
    {
      if(devices[k] == "-1")
        continue;
      
      if(dynContains(existingDevices, devices[k]) > 0)
      {
        //if device already exists, remove it from the list of existing devices such that it does not get removed at the end
        dynRemove(existingDevices, dynContains(existingDevices, devices[k]));
      }
      else
      {
        string dp = fwFMCMonitoring_getDp(node) + "/Cpus/"+ devices[k];
        strreplace(dp, getSystemName(), "");    
        DebugN("Creating now sensor: " + dp);
        dpCreate(dp, "FwFMCCpu");
        while(!dpExists(dp))
          delay(0, 20);
        
        fwFMCMonitoring_dimSubscribeCpu(node, devices[k]);
      }
    }
    
    dyn_string exception;
    if(fwFMC_isArchivingEnabled(node) == "Advanced" && !cpusExists)
      fwFMC_setArchiveCPU(node, exception);
  
    if(dynlen(exception))
      DebugN(exception);
  }//end of loop
  
//  //Delete now the devices that do not exist anymore:
//  for(int i =1 ; i <= dynlen(existingDevices); i++) 
//  {
//    fwFMCMonitoring_removeCpu(node, existingDevices[i]);
//  }
  
  return; 
}

fwFMCMonitoring_createNicCB(string ident, dyn_dyn_anytype val)
{
  string dp;
  string node;
  dyn_string ds;
  string temp;
  bool found = false;  
  dyn_string devices;
  dyn_string existingDevices; 
  dyn_string exception;
  bool nicExists;
  
  if(dynlen(val) < 2)
    return;
  
  for(int i = 2; i <= dynlen(val); i++)
  {
    if(val[i][2] == "")
      continue;
    temp = val[i][1];
    ds = strsplit(temp, ".");
  
    dp = ds[1];
  
//   if(patternMatch(getSystemName() + "*", dp))
//     strreplace(dp, getSystemName(), "");
  
    node = fwFMC_getNodeName(dp); 
    
    //this variable is sued when the archiving is set, in order not to override the archiving each time the project restarts
    nicExists = fwFMCMonitoring_networksExists(node);
    
    dynClear(existingDevices);
    fwFMCMonitoring_getDevices(node, "network", existingDevices);
    devices = val[i][2];
    
    for(int k = 1; k <= dynlen(devices); k++)
    {
      if(devices[k] == "-1")
        continue;
 
      if(dynContains(existingDevices, devices[k]) > 0)
      {
        //if device already exists, remove it from the list of existing devices such that it does not get removed at the end
        dynRemove(existingDevices, dynContains(existingDevices, devices[k]));
      }
      else
      {
        string dp = fwFMCMonitoring_getDp(node) + "/Network/"+ devices[k];
        strreplace(dp, getSystemName(), "");    
        DebugN("Creating now sensor: " + dp);
        dpCreate(dp, "FwFMCNetwork");
        while(!dpExists(dp))
          delay(0, 20);
        fwFMCMonitoring_dimSubscribeNIC(node, devices[k]);
      }
    }
    
    dyn_string exception;
    if(fwFMC_isArchivingEnabled(node) == "Advanced" && !nicExists)
      fwFMC_setArchiveNetwork(node, exception);
  
    if(dynlen(exception))
      DebugN(exception);
    
  }//end of loop
  
//  //Delete now the devices that do not exist anymore:
//  for(int i =1 ; i <= dynlen(existingDevices); i++) 
//  {
//    fwFMCMonitoring_removeNIC(node, existingDevices[i]);
//  }
 
  return; 
}

fwFMCMonitoring_createFsCB(string ident, dyn_dyn_anytype val)
{
  string dp;
  string node;
  dyn_string ds;
  string temp;
  bool found = false;  
  dyn_string devices;
  dyn_string existingDevices; 
  bool fsExists = false;
  if(dynlen(val) < 2)
    return;
  for(int i = 2; i <= dynlen(val); i++)
  {
    if(val[i][2] == "")
      continue;
   
    temp = val[i][1];
    ds = strsplit(temp, ".");
  
    dp = ds[1];
  
//  if(patternMatch(getSystemName() + "*", dp))
//    strreplace(dp, getSystemName(), "");

    node = fwFMC_getNodeName(dp); 
    //this variable is sued when the archiving is set, in order not to override the archiving
    // and the alarms setting each time the project restarts    
    //fsExists = fwFMCMonitoring_fsExists(node);
    dynClear(existingDevices);
    fwFMCMonitoring_getDevices(node, "fs", existingDevices);
    devices = val[i][2];
    
    for(int k = 1; k <= dynlen(devices); k++)
    {
      if(devices[k] == "-1")
        continue;
      
      if(dynContains(existingDevices, devices[k]) > 0)
      {
        //if device already exists, remove it from the list of existing devices such that it does not get removed at the end
        dynRemove(existingDevices, dynContains(existingDevices, devices[k]));
      }
      else
      {
        string dp = fwFMCMonitoring_getDp(node) + "/FS/"+ devices[k];
        strreplace(dp, getSystemName(), "");    
        DebugN("Creating now sensor: " + dp);
        dpCreate(dp, "FwFMCFs");
        while(!dpExists(dp))
          delay(0, 20);
        fwFMCMonitoring_dimSubscribeFS(node, devices[k]);
      }
    }
    
    dyn_string exception;
//    if(fwFMC_isArchivingEnabled(node) != "NONE" && !fsExists)
    if(fwFMC_isArchivingEnabled(node) != "NONE")
    {
      fwFMC_setArchiveFS(node, exception);
    }
    if(fwFMC_areAlarmsEnabled(node))
    {
      fwFMC_setDefaultAlarms(node, exception);
    }
    if(dynlen(exception))
      DebugN(exception);  
    
  }//end of loop
  
//  //Delete now the devices that do not exist anymore:
//  for(int i =1 ; i <= dynlen(existingDevices); i++) 
//  {
//    fwFMCMonitoring_removeFS(node, existingDevices[i]);
//  }

  
 

  return; 
}

float fwFMCMonitoring_getAverageCpuLoad(string node, string systemName = "")
{
  float idle = -1.;
  float user = -1.;
  int temp;
  float avCpu = -1;
  
  if(systemName == "")
    systemName = getSystemName();
  
  string monitoringDp = fwFMCMonitoring_getDp(node, systemName);
  int commStatus = -1;
  dpGet(fwFMC_getNodeDp(node, systemName) + ".agentCommunicationStatus.monitoring.cpustat", commStatus);
// DebugN("cpu", node, commStatus);  
   if(!dpExists(monitoringDp) || commStatus != 1)
  {
    return -1.;
  }
    
  dpGet(monitoringDp + "/Cpus.readings.averageLoad.idle", idle);
  
  temp = (floor(idle*10)/10.);
  avCpu = (1000.-temp*10.)/10.;
  
  return avCpu;  
  
}

void fwFMCMonitoring_getMemoryLoad(string node, float &usedMemory, float &usedSwap, string systemName = "")
{
  if(systemName == "")
    systemName = getSystemName();
  
  string monitoringDp = fwFMCMonitoring_getDp(node, systemName);
  int total, free, free_swap, total_swap;
  
  int commStatus = -1;
  dpGet(fwFMC_getNodeDp(node, systemName) + ".agentCommunicationStatus.monitoring.memory", commStatus);
  
  if(!dpExists(monitoringDp) || commStatus != 1)
  {
    usedMemory = -1;
    usedSwap = -1;
    return;
  }
  
  dpGet(monitoringDp + "/Memory.readings.userMemory", usedMemory,
        monitoringDp + "/Memory.readings.usedSwap", usedSwap);
  
  usedMemory = floor(usedMemory*10.)/10.;
  usedSwap = floor(usedSwap*10.)/10.;

  return;  
}

int fwFMCMonitoring_getReadoutStatus(string node, dyn_int check, string &status, string systemName = "")
{
  if(systemName == "")
    systemName = getSystemName();
  
  dyn_int statuses;
  string monitoringDp = fwFMCMonitoring_getDp(node, systemName);
  
  if(!dpExists(monitoringDp))
  {  
    status = "ERROR";
    return 0;
  }

  if(check[1])
    dpGet(monitoringDp + ".agentCommunicationStatus.monitoring.cpustat", statuses[1]);
  
  if(check[2])
    dpGet(monitoringDp + ".agentCommunicationStatus.monitoring.cpuinfo", statuses[1]);
  
  if(check[3])
    dpGet(monitoringDp + ".agentCommunicationStatus.monitoring.memory", statuses[1]);
  
  if(check[4])
    dpGet(monitoringDp + ".agentCommunicationStatus.monitoring.network", statuses[1]);
  
  if(check[5])
    dpGet(monitoringDp + ".agentCommunicationStatus.monitoring.os", statuses[1]);
  
  if(check[6])
    dpGet(monitoringDp + ".agentCommunicationStatus.monitoring.fs", statuses[1]);
  
  //DebugN(statuses[1] && statuses[2] && statuses[3] && statuses[4] && statuses[5] && statuses[6]);
  
  if(dynSum(check) == dynSum(statuses))
    status = "OK";
  else
    status = "ERROR"; 
  
  return 0;
}

void fwFMCMonitoring_connectMemoryDpes(string node, dyn_string &exception)
{    
  string monitoringDp = fwFMCMonitoring_getDp(node);
  string memoryDp = monitoringDp + "/Memory";
  fwDpFunction_setDpeConnection(memoryDp + ".readings.userMemory", 
                                makeDynString(memoryDp + ".readings.free:_online.._value",
                                              memoryDp + ".readings.total:_online.._value"
                                              ),
                                makeDynString(),
                                "p2!=0?100.-p1*1./p2*100.:-1",
                                exception,
                                1);
  fwDpFunction_setDpeConnection(memoryDp + ".readings.usedSwap", 
                                makeDynString(memoryDp + ".readings.free_swap:_online.._value",
                                              memoryDp + ".readings.total_swap:_online.._value"
                                              ),
                                makeDynString(),
                                "p2!=0?100.-p1*1./p2*100.:-1",
                                exception,
                                1);


}
