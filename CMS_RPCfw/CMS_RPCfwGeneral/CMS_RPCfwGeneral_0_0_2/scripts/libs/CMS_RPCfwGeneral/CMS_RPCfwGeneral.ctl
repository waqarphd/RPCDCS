/***************************************************************
  
  RPC General Library v:1.7
  
  author: Giovanni Polese
  
****************************************************************/  
#uses "fwInstallationUtils.ctl"
#uses "CMSfw_CAENOPCConfigurator/CMSfw_CAENOPCConfiguratorLib.ctl"
#uses "CMSfwDetectorProtection/CMSfwDetectorProtection.ctl"

const int CMS_RPCfwGeneral_LOG = 1;
const int CMS_RPCfwGeneral_HARD = 2;
const bool CMS_RPCfwGeneral_ACCESS_DCS = true;


//_____________________________________________________________________________
bool 
CMS_RPCfwGeneralInstallation_getInstallationKey(string type, string FSMVersion = "1.0")
{  
  string dp = dpNames("*"+type+"*","RPCUtils");
  if(!dpExists(dp)) 
  {
    dpCreate(type,"RPCUtils"); 
    dpSet(type+".svalue",FSMVersion);  
    return true;
  }
  else
  {
    string versionPj;
    dpGet(type+".svalue", versionPj);
    dpSet(type+".svalue", FSMVersion);
    
    return FSMVersion!=versionPj;
  }    
  return false;
}


//_____________________________________________________________________________
void 
CMS_RPCfwGeneralInstallation_configSmsRPCSysCheck(string notifType, string dpName)
{
  dyn_string exInfo,dp = dpNames(dpName,"RPCUtils");
  if(dynlen(dp)>0)
  {
    CMSfwAlertSystemUtil_addAlertToNotification(notifType, dp[1]+".fvalue");
    fwAlertConfig_activate("CMSAlertSystem/SumAlerts/" + notifType+".Notification", exInfo);
  }
  else
  {
    if(!dpExists(getSystemName()+dp))
    {
      dyn_string alertTexts = makeDynString( "Ok", "Not Ok");
      dyn_float limits = (1); 
      dyn_string alertClasses = makeDynString( "" , "_fwErrorAck.");
      string alertPanel,summary,dp; dyn_string alertPanelParameters; string alertHelp;  
      dpCreate(dp,"RPCUtils");
      dp = getSystemName()+"RPCCheckUXC.fvalue";
      fwArchive_set(dp,"RDB-99) EVENT",DPATTR_ARCH_PROC_SIMPLESM,DPATTR_COMPARE_OLD_NEW,0,0,exInfo);
      fwAlertConfig_set(dp,DPCONFIG_ALERT_NONBINARYSIGNAL ,alertTexts,limits, alertClasses,summary,alertPanel,alertPanelParameters,
                        alertHelp,exInfo);
      fwAlertConfig_activate(dp,exInfo);
 
      CMSfwAlertSystemUtil_addAlertToNotification(notifType,dp+".fvalue") ;
      fwAlertConfig_activate("CMSAlertSystem/SumAlerts/" + notifType+".Notification",exInfo);
    }
  }
}


//_____________________________________________________________________________
void 
CMS_RPCfwGeneralInstallation_setOPCServerStatus(string caen,string subsys)
{
  dyn_string types;
  types = dpTypes("RPCUtils");
  if(dynlen(types)>0) 
  {    
    if(!dpExists("caen"+subsys+"ServerStatus"))
    {
      dpCreate("caen"+subsys+"ServerStatus","RPCUtils");
    }
  }
  
  dyn_string obj = dpNames("*"+caen+"*","FwCaenCrateSY1527");
  string newDps;  
  //  DebugN(obj);
  if(dynlen(obj)>0)
  {
    string dpe = obj+ ".Information.Sessions";
    newDps = "caen"+subsys+"ServerStatus.svalue";
    dyn_string exInfo;
    dyn_anytype conf;
    bool exist, isAct;
    fwPeriphAddress_get(dpe, exist, conf,isAct,exInfo);
   
    string newItem = substr((string)conf[fwPeriphAddress_ROOT_NAME],0,
			     (strpos((string)conf[fwPeriphAddress_ROOT_NAME],".")))
                     + ".ConnStatus";
  
    fwPeriphAddress_setOPC(newDps,conf[fwPeriphAddress_OPC_SERVER_NAME],
                           conf[fwPeriphAddress_DRIVER_NUMBER],newItem,
                           conf[fwPeriphAddress_OPC_GROUP_IN],
                           conf[fwPeriphAddress_DATATYPE],
                           conf[fwPeriphAddress_DIRECTION],
                           conf[fwPeriphAddress_OPC_SUBINDEX],exInfo);
  }
  else
  {    
    CMS_RPCfwGeneralInstallation_RPCDebug("Caen Mainframe not found");
  }
 
  ///// Set db
  string archiveClassName="RDB-99) EVENT"; //"ValueArchive_0000";//Archive's name
  float timeInterval=3600; 
  dyn_string exceptionInfo;

  fwArchive_set(newDps, archiveClassName,DPATTR_ARCH_PROC_SIMPLESM,DPATTR_COMPARE_OLD_NEW,
	        0.3, timeInterval,exceptionInfo);

  /// store interlock
  string interlock = obj + ".FrontPanInP.Interlock";
  fwArchive_set(interlock, archiveClassName,DPATTR_ARCH_PROC_SIMPLESM,DPATTR_COMPARE_OLD_NEW,
		 0.3, timeInterval,exceptionInfo);
   
    
}


//_____________________________________________________________________________
void 
CMS_RPCfwGeneralInstallation_createHVoffset()
{
  dyn_string types;
  types = dpTypes("RpcBoardOffset");
  //DebugN(types);

  if(dynlen(types)<1) 
  {
    // Create the data type

    dyn_dyn_string xxdepes;
    xxdepes[1] = makeDynString ("RpcBoardOffset","");
    xxdepes[2] = makeDynString ("","serial");
    xxdepes[3] = makeDynString ("","offset");

    dyn_dyn_int xxdepei;
    xxdepei[1] = makeDynInt (1);
    xxdepei[2] = makeDynInt (0,25);
    xxdepei[3] = makeDynInt (0,6);

    // Create the datapoint type
    int n = dpTypeCreate(xxdepes,xxdepei);

    DebugN ("Datapoint Type created ");   
  }  
    
  for(int i = 1 ; i<=90;i++)
  {
    if(!dpExists("OffsetBoard"+i))
    {
      dpCreate("OffsetBoard"+i,"RpcBoardOffset");
    }
  }
  DebugN("Offset dpt created");   
}


//_____________________________________________________________________________
int 
CMS_RPCfwGeneralInstallation_createUserSMS(string user)
{
  if (user == "") 
  {
    return -1;
  }
  string phoneNum;
  dyn_string users;
  switch (user)
  {
    case "polese":
      phoneNum = "165807";
      break;
    default: 
      phoneNum =  "165508";    
      break;
  }
  users = dpNames("*"+user+"*","CMSfwAlertSystemUsers");
  
  if(dynlen(users)==0)
  {
    CMSfwAlertSystemUtil_addUser(user);
  }
  else 
  {
    return 1;
  }

  users = dpNames("*"+user+"*","CMSfwAlertSystemUsers");
  
  //in case it fails
  if(dynlen(users)==0)
  {
    CMSfwAlertSystemUtil_createUser(user, user+ "@cern.ch", phoneNum);
  }
  else if (user ==  "rpcbarre")
  {
    dpSet(users[1]+".GSMNumber","165508");
  }
  
  return 1;
}


//_____________________________________________________________________________
string 
CMS_RPCfwGeneral_getSupervisorSys()
{
  dyn_string systemNumber;
  fwInstallation_getApplicationSystem("CMS_RPCfwSupervisor",systemNumber);
  if(dynlen(systemNumber)!=0)
  {
    return systemNumber[1];
  }
  else
  {
    return "Error";
    DebugN("Component not found");
  }
}


//_____________________________________________________________________________
void 
CMS_RPCfwGeneralInstallation_createUtilities()
{  
  dyn_string types;

  // Create dp for Utils
  types = dpTypes("RPCUtils");
  //DebugN(types);
  if(dynlen(types)<1) 
  {
    // Create the data type

    dyn_dyn_string xxdepes;
    xxdepes[1] = makeDynString ("RPCUtils","");
    xxdepes[2] = makeDynString ("","fvalue");
    xxdepes[3] = makeDynString ("","svalue");
    //xxdepes[3] = makeDynString ("","offset");

    dyn_dyn_int xxdepei;
    xxdepei[1] = makeDynInt (1);
    xxdepei[2] = makeDynInt (0,DPEL_FLOAT);
    xxdepei[3] = makeDynInt (0,DPEL_STRING);
 
    // Create the datapoint type
    int n = dpTypeCreate(xxdepes,xxdepei);

    DebugN ("Datapoint Type created ");
  }
}


//_____________________________________________________________________________
void 
CMS_RPCfwGeneralInstallation_installProtectionHV(string name = "LHCHandshake")
{
  dyn_mixed obj;
  dyn_string exc; 
    
  //////////// Parameters
  string dpe;
  string funct = "p1==1";
  string sysCentral = "{CMSfwHandshake}";

  // Output  
  string duType = "FwCaenChannel";
  string duElem = ".settings.v0";
  string topNode = "*/HV/*";
  string valstring = "7000";
  int valtype = 22;
  
  //verify  
  string item2check = ".actual.vMon";
  string function2use = "bool main(anytype value) {\n return ((float) value < 7050); \n}";
  int verifyDelay = 60;
    
  dyn_string names = makeDynString("Injection_request");
  
  //delete old;
  dyn_string dpss = dpNames(getSystemName()+"*"+name+"*",CMSfwDetectorProtection_CONFIGDP);
  if(dynlen(dpss)>0)
    dpDelete(dpss[1]);  

  CMSfwDetectorProtection_initObject(obj);
  if(name == "LHCHandshake")
  {  
    for(int i = 1; i<=dynlen(names);i++)
    {
      CMSfwDetectorProtection_addCondition(obj,"RPC"+names[i], exc);

      //Input
      // CMSfwDetectorProtection_createInput(name,dpe,funct,exc);
      CMSfwDetectorProtection_setInput(obj,"RPC"+names[i],sysCentral+":CMSfwDetectorProtection/Input/"+names[i],exc);
  
      //Output  
      CMSfwDetectorProtection_setOutputModeDpNamesOrAliases(obj,"RPC"+names[i],CMSfwDetectorProtection_MODE_DPALIASES,
                                                          topNode,duType,duElem,valstring,valtype,0,exc);

      //verify
      CMSfwDetectorProtection_setVerifyModeTreeCache(obj,"RPC"+names[i], item2check, function2use, verifyDelay, exc);

      //save  
    }
  }
  else if(name == "LHCCondition")
  {  
    CMSfwDetectorProtection_addCondition(obj,"RPC_LHC_Requires_Standby",exc);
    string dpInput = sysCentral+":CMSfwDetectorProtection/Input/LHC_Requires_Standby_CMS_SUB_RPC_PHY";
    CMSfwDetectorProtection_setInput(obj,"RPC_LHC_Requires_Standby",dpInput,exc);
    CMSfwDetectorProtection_setOutputModeDpNamesOrAliases(obj,"RPC_LHC_Requires_Standby",CMSfwDetectorProtection_MODE_DPALIASES,
                                                         topNode,duType,duElem,valstring,valtype,0,exc);

    CMSfwDetectorProtection_setVerifyModeTreeCache(obj,"RPC_LHC_Requires_Standby", item2check, function2use, verifyDelay, exc);
  }
    
  string dp = CMSfwDetectorProtection_getConfigDpName(name,getSystemName());
  CMSfwDetectorProtection_setConfigDp(obj,dp);
  CMSfwDetectorProtection_saveToDp(obj,exc);
  //setInput(obj);
  
  CMS_RPCfwGeneralInstallation_RPCDebug(" Protection Installed");  
}


//_____________________________________________________________________________
void 
CMS_RPCfwGeneralInstallation_CreateTypesGenCurrent()
{
  dyn_string types = dpTypes("RpcGlobalValue");

  //DebugN(types);

  if(dynlen(types)<1) 
  {
    // Create the data type

    dyn_dyn_string xxdepes;
    xxdepes[1] = makeDynString("RpcGlobalValue","");
    xxdepes[2] = makeDynString("","total");
    xxdepes[3] = makeDynString("","averange");

    dyn_dyn_int xxdepei;
    xxdepei[1] = makeDynInt(1);
    xxdepei[2] = makeDynInt(0,DPEL_FLOAT);
    xxdepei[3] = makeDynInt(0,DPEL_FLOAT);

    // Create the datapoint type
    int n = dpTypeCreate(xxdepes,xxdepei);

    DebugN ("Datapoint Type created ");
  }
}


//_____________________________________________________________________________
void CMS_RPCfwGeneralInstallation_configureOPC() 
{
  dyn_string exc;
  DebugTN("Configuring OPC Server");
  CMSfw_CAENOPCConfigurator_configureFromFwCaenDps(exc);
  DebugN("Exc configuring OPC Server", exc);  
}


//_____________________________________________________________________________
void 
CMS_RPCfwGeneralInstallation_smsUserConfigRPCDefault(string notification) 
{
  dyn_string exInfo;
  CMS_RPCfwGeneralInstallation_smsAlertConfig(notification,"polese",3,exInfo);
  CMS_RPCfwGeneralInstallation_smsAlertConfig(notification,"rpcbarre",1,exInfo);   
}

 
//_____________________________________________________________________________
void 
CMS_RPCfwGeneralInstallation_smsAlertConfig(string notifType, string user, 
					    int type, dyn_string & exInfo)
{
  //1 sms 2 email 3 sms+email
  dyn_string users;
    
  CMS_RPCfwGeneralInstallation_createUserSMS(user);
  // string notifType = "SupCheck";
  dyn_string notif = dpNames("*"+notifType+"*","CMSfwAlertSystemSumAlerts");
  //DebugN(notif,notifType);
  if(dynlen(notif)==1)
  {
    dpDelete(notif[1]);
    CMSfwAlertSystemUtil_createNotification (notifType);
  }
  else if (dynlen(notif)==0)
  {
    CMSfwAlertSystemUtil_createNotification (notifType);
  }

  // **************** Add user to notificatio
  string userdp = dpNames("*"+user+"*","CMSfwAlertSystemUsers");
  
  if(userdp!="")
  {   
    if((type == 2)||(type==3))
      CMSfwAlertSystemUtil_addNotificationToUser (userdp,notifType,"EMAIL",50);
    
    if((type == 1)||(type==3))
      CMSfwAlertSystemUtil_addNotificationToUser (userdp,notifType,"SMS",50);
  }
}


//_____________________________________________________________________________
void 
CMS_RPCfwGeneralInstallation_RPCDebug(string info)
{  
  dyn_string types = dpTypes("RPCVector");
  //DebugN(types);
  if(dynlen(types)<1)
  { 
    CMS_RPCfwGeneralInstallation_createRPCVector();
  }
  if(!dpExists("RPCcout"))
  {
    dpCreate("RPCcout","RPCVector");
  }

  dyn_string temp;
  dpGet(getSystemName()+"RPCcout.svalue",temp);
  if(info == "null")
  {
    dynClear(temp);
  }
  else
  {  
    dynAppend(temp,info);  
    DebugN(" RPC Installation Debug: "+info);
  }
  dpSet(getSystemName()+"RPCcout.svalue",temp);
}


//_____________________________________________________________________________
void 
CMS_RPCfwGeneralInstallation_createRPCVector()
{
  dyn_string types;
 
  types = dpTypes("RPCVector");
  //DebugN(types);
  if(dynlen(types)<1) 
  {
    // Create the data type

    dyn_dyn_string xxdepes;
    xxdepes[1] = makeDynString ("RPCVector","");
    xxdepes[2] = makeDynString ("","fvalue");
    xxdepes[3] = makeDynString ("","svalue");
    //xxdepes[3] = makeDynString ("","offset");

    dyn_dyn_int xxdepei;
    xxdepei[1] = makeDynInt (1);
    xxdepei[2] = makeDynInt (0,DPEL_DYN_FLOAT);
    xxdepei[3] = makeDynInt (0,DPEL_DYN_STRING);
 
    // Create the datapoint type
    int n = dpTypeCreate(xxdepes,xxdepei);
  }
}


//_____________________________________________________________________________
void CMS_RPCfwGeneralInstallation_createOPCGroup(int numberOfGroup = 3) 
{
  int fastRefreshRate =  2000;
  int slowRefreshRate = 10000;
  
  dyn_string dpName = dpNames("*","_OPCGroup"); 
  //DebugN(dpName); 
  int error; 
  bool inExists = false, outExists =false;

  dyn_string newDpIn = makeDynString("_FastGroupIn");
  dyn_string newDpOut = makeDynString("_FastGroupOut");

  for(int i = 1;i<numberOfGroup;i++ )
  {
    dynAppend(newDpIn,"_FastGroupIn"+i);
    dynAppend(newDpOut,"_FastGroupOut"+i);
  }

  string oldIn = "_CAENOPCGroupIn"; 
  string oldOut = "_CAENOPCGroupOut"; 
  string temp; 
  for(int j = 1; j<=dynlen(newDpIn); j++) 
  { 
    inExists = false; 
    outExists =false; 

    for(int i = 1; i<=dynlen(dpName);i++) 
    { 
      temp = dpSubStr(dpName[i],DPSUB_DP); 
      //DebugN(temp); 
      if(newDpIn[j] == temp) 
      { 
        inExists = true; 
      } 
      if(newDpOut[j] == temp) 
        outExists = true; 
    } 
    if(!inExists)  
    { 
      dpCreate(newDpIn[j],"_OPCGroup"); 
      dpCopyOriginal(oldIn,newDpIn[j],error); 
      //DebugN("error: ",error); 
    } 

    if(!outExists) 
    { 
      dpCreate(newDpOut[j],"_OPCGroup"); 
      dpCopyOriginal(oldOut,newDpOut[j],error); 
    } 

    dpSet(newDpIn[j] +".UpdateRateReq",fastRefreshRate); 
    dpSet(newDpIn[j] +".UpdateRateAct",fastRefreshRate); 
    dpSet(newDpOut[j] +".UpdateRateReq",fastRefreshRate); 
    dpSet(newDpOut[j] +".UpdateRateAct",fastRefreshRate); 
  } 

  dpSet(oldIn +".UpdateRateReq",slowRefreshRate); 
  dpSet(oldIn +".UpdateRateAct",slowRefreshRate); 
  dpSet(oldOut +".UpdateRateReq",slowRefreshRate); 
  dpSet(oldOut +".UpdateRateAct",slowRefreshRate); 
} 


//_____________________________________________________________________________
void 
CMS_RPCfwHardware_getDeviceChannels(string pos, string type, dyn_dyn_string & channels)    
{  
  dyn_string children, exceptionInfo;
  string device, typeNode;
  string compName;
  if(strpos(type,"HV")>-1)
  {
    compName = "BarrelHV";
  }
  else if(strpos(type,"LV")>-1)
  {
    compName = "BarrelLV";
  }
  else if(strpos(type,"T")>-1)
  {
    compName = "BarrelT";
    type = "ADCTemp";
  }

  string parent = CMS_RPCfwGeneral_getComponent(compName)+pos;
        
  fwTree_getChildren(parent, children, exceptionInfo);
  //DebugN("ue",pos, children,"ola");
  if(dynlen(children)==0)
  {
    fwTree_getNodeDevice(parent, device, typeNode, exceptionInfo);
    //Debug("ok",typeNode,type);
    if(typeNode == "FwCaenChannel"+type)
    {
      //Debug("ok");
      dynAppend(channels[LOG], parent);                  
      dynAppend(channels[HARD],dpSubStr(parent,DPSUB_SYS)+fwDU_getPhysicalName(parent));
    }
  }	
  else
  {
    for(int i=1; i<=dynlen(children); i++)
    {
      if(children[i][0]=="&")
        children[i] = substr (children[i], 5);

      CMS_RPCfwHardware_getDeviceChannels(children[i],type, channels);
    }
  }
}


//_____________________________________________________________________________
string 
CMS_RPCfwGeneral_detector(string name)
{
  if(strpos(name,"YE")>-1)
  {
    return "Endcap";
  }
  else
  {
    return "Barrel";
  }
}
