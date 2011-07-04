/******************************************************
*  Script for automatic actions among different systems
*  author: G. Polese (Unknown University of Nowhere)
*  version: 1.4
*  Last Update: 15/01/2011
*  
*  
*******************************************************/  
/******* 
bit legenda
1: false ok, true masked
2: false ok, true hightemp
   
   Add alert2cDCS
   Add sms2Alert
   Add GasInfrastructures
   FSM Sectors control
*******/
#uses "CMSfwAlertSystem/CMSfwAlertSystemUtil.ctl"
#uses "CMSfwAlertSystem/CMSfwAlertSystemGeneral.ctc"
#uses "CMS_RPCfwSupervisor/CMS_RPCfwSupervisor.ctl"
const int highTemp = 24; 
bool inOut;
dyn_string Tchans;
int tOk, tBad;
dyn_dyn_string chs2mon, reference;
dyn_string dpstatus ;

main(){

inOut = true;  
  
checkDpTimed("RPCXactions",210);
timedFunc("CheckorExec","RPCXactions");

checkDpTimed("RPCStatusAlert",31);
timedFunc("statusAlert","RPCStatusAlert");

}
void checkDpTimed(string dp,int sec)
{
  if(!dpExists(dp))
  {
    dpCreate(dp,"_TimedFunc");
    dpSet(dp+".syncTime",-1);
    dpSet(dp+".interval",sec);
  }
  
  }
void CheckorExec(){

if(inOut){ 
  tempCheck();
  inOut = false;
  }else{
    executeTactions();
    inOut = true;  
  }
}

void tempCheck(){
  if(dynlen(Tchans)==0){
  dyn_string temp; 
  string sys = RPCfwSupervisor_getComponent("BarrelLV");
  RPCfwSupervisor_getAllChannelsFromType(sys,"T",Tchans);
  sys = RPCfwSupervisor_getComponent("EndcapLV");  
  RPCfwSupervisor_getAllChannelsFromType(sys,"T",temp);
  dynAppend(Tchans,temp);
  
  }
  string name;
  bool find,bit2set;
  tOk = 0;
  tBad = 0;
  dyn_string dpes;
  float val;
  for(int i =1 ;i<=dynlen(Tchans);i++){//dynlen(Tchans)

  dpGet(Tchans[i]+".actual.temperature",val);  
  if(val>highTemp){
    bit2set = true;
    tBad++;
    }
  else if(val < 10){
    bit2set = false;
    tBad++;  
    }else{
      bit2set = false;
      tOk++;    
    }
  find = dpAction(Tchans[i],dpes);  
  if(find)  setCheckBit(dpes,bit2set);
     
  }
  writeT(tOk,tOk+tBad);

}

void setCheckBit(dyn_string dpes,bool b2s){
  
  bit32 value;
  for(int i =1 ;i<=dynlen(dpes);i++){
    dpGet(dpes[i]+".ivalue",value);
    if(getBit(value,1)==false){//if bit 1 is not true => is not masked
      setBit(value,2,b2s);// if need to be off, bit 2 is true
      dpSet(dpes[i]+".ivalue",value);
      if(b2s) dpSet(dpes[i]+".inputAction","Action required on HV.");    
    }
  
  } 
}

bool dpAction(string channel,dyn_string & dpes){

int first,last; 
string logName,sys; 
  
sys = RPCfwSupervisor_getSupervisorSys();
logName =  fwDU_getLogicalName(channel);
first = strpos(logName,"RPC_");
last = strpos(logName,"_T");
logName = substr(logName,first,last-first);

dynClear(dpes);
dpes = dpNames(sys+"*"+logName+"*","RPCXActions");
//DebugN(sys+"*"+logName+"*",dpes);
if(dynlen(dpes)>0) return true;
else return false;

}

void executeTactions(){
  
  string sys = RPCfwSupervisor_getSupervisorSys();
  dyn_string dpes = dpNames(sys+"*","RPCXActions");
  bit32 value;
  for(int i = 1;i<=dynlen(dpes);i++){//bit 2 is the bit for temp problem
   
  bool result = true; 
  dpGet(dpes[i]+".ivalue",value);
  if((getBit(value,2))&&(!getBit(value,1))){
    result = lowerHV(dpes[i]);
    if(result) dpSet(dpes[i]+".outputAction","Action on HV executed.");
    else dpSet(dpes[i]+".outputAction","Action on HV aborted.");
    }
  }

}

bool lowerHV(string chName){
  dyn_string dps;
  string sys;
  string name = dpSubStr(chName,DPSUB_DP);
  name = substr(name,0, strpos(name,"_Xact"));
  if(strpos(name,"_W")>0)
    sys = RPCfwSupervisor_getComponent("BarrelHV");
  else if (strpos(name,"_E")>0)
    sys = RPCfwSupervisor_getComponent("EndcapHV");
  if(sys!="")
    RPCfwSupervisor_getChannelsFromName(name,"HV",sys,dps);
  else return false;
  
  int vmon;
  bool isOn;  
  if(dynlen(dps)<1) return false;
  else  
  {
  for(int i = 1;i<=dynlen(dps);i++)
    {
     dpGet(dps[i]+".actual.isOn",isOn,dps[i]+".actual.vMon",vmon);
     // Here the condition on Voltage >7000 and channel on
     if((vmon>7050)&&(isOn))
       dpSet(dps[i]+".settings.v0",7000);
    }  
  
  }
  return true;  
  
}

void writeT(int ok,int total){

string dp = "Tperc";

if(!dpExists(dp))
  dpCreate(dp,"RPCGlobalPerc");

dpSet(dp+".ok",ok,dp+".total",total);

}



void createTypePerc(){

  dyn_string types = dpTypes("RPCGlobalPerc");
  //DebugN(types);
  if(dynlen(types)<1) 
  {
  int n;

  dyn_dyn_string xxdepes;

  dyn_dyn_int xxdepei;

 

// Create the data type

  xxdepes[1] = makeDynString ("RPCGlobalPerc","");

  xxdepes[2] = makeDynString ("","ok");
  
  xxdepes[3] = makeDynString ("","total");
  //xxdepes[3] = makeDynString ("","offset");


  xxdepei[1] = makeDynInt (1);

  xxdepei[2] = makeDynInt (0,DPEL_FLOAT);

  xxdepei[3] = makeDynInt (0,DPEL_FLOAT);

   n = dpTypeCreate(xxdepes,xxdepei); 

}
}
void statusAlert()
{

 if(dynlen(chs2mon)<1) init();
string val;
int res = 0;
 for(int i = 1;i<=dynlen(chs2mon);i++){
   res = 0;
   for(int j = 1;j<=dynlen(chs2mon[i]);j++){
     dpGet(chs2mon[i][j],val);
     if((i==5)&&(j==1))
     {
       time t1,t2;
       t1 = val;
       t2 = getCurrentTime();
       float di = t2-t1;
       if(di>300) {res = 1; break;}
     }else if (i==9){
     if(val==reference[i][j]) {res = 1; break;}
     }else{
       if(val!=reference[i][j]) {res = 1; break;}
     }   
 
   }

   if(!dpExists(dpstatus[i])){
     createDp(dpstatus[i]);
     smsSumAlertConfig();
     dpSet(dpstatus[i]+".fvalue",res);
     
   }
   else
     dpSet(dpstatus[i]+".fvalue",res);
 
 } 
  
}

void smsSumAlertConfig(){

  
    dyn_string users,exInfo;
  
//  DebugN("RE");
  string user1 = "polese";
  
  users = dpNames("*"+user1+"*","CMSfwAlertSystemUsers");
  
  if(dynlen(users)==0)
      CMSfwAlertSystemUtil_addUser(user1);
    
  string user2 = "rpcbarre";
  
  users = dpNames("*"+user2+"*","CMSfwAlertSystemUsers");
    
  if(dynlen(users)==0)
  {
      CMSfwAlertSystemUtil_addUser(user2);
    users = dpNames("*"+user2+"*","CMSfwAlertSystemUsers");
  if(dynlen(users)>0)  
  dpSet(users[1]+".GSMNumber","165508");
  else{
  dpCreate("CMSAlertSystem/Users/"+user2,"CMSfwAlertSystemUsers");
   dpSet("CMSAlertSystem/Users/"+user2+".GSMNumber","165508"); 
  }
  
  }

  dyn_string notif;
  string notifType = "RPCSup_MainAlerts";
  notif = dpNames("*"+notifType+"*","CMSfwAlertSystemSumAlerts");
  if(dynlen(notif)!=0)    dpDelete(notif[1]);
    CMSfwAlertSystemUtil_createNotification(notifType);
  
  /////// ******************** Add alert to notification

                  
  dyn_string dps = dpNames("*RPC_*","RPCUtils");
      for(int i = 1;i<=dynlen(dps);i++)
      {  
    CMSfwAlertSystemUtil_addAlertToNotification(notifType,dps[i]+".fvalue") ;
    }
  // **************** Add user to notificatio
  
  CMSfwAlertSystemUtil_addNotificationToUser ("CMSAlertSystem/Users/"+user1,notifType,"EMAIL",50);
  CMSfwAlertSystemUtil_addNotificationToUser ("CMSAlertSystem/Users/"+user1,notifType,"SMS",50);
  CMSfwAlertSystemUtil_addNotificationToUser ("CMSAlertSystem/Users/"+user2,notifType,"SMS",50);

fwAlertConfig_activate("CMSAlertSystem/SumAlerts/" + notifType+".Notification",exInfo);

  }

bool createDp(string dp){
  dyn_string exceptionInfo;
  float deadband=2;
  dyn_string types= dpTypes("RPCUtils");
  if(dynlen(types)>0){
    dpCreate(dp,"RPCUtils");
    fwArchive_set(dp+".fvalue" , "RDB-99) EVENT" ,DPATTR_ARCH_PROC_SIMPLESM,DPATTR_COMPARE_OLD_NEW ,deadband, 10000,exceptionInfo);
   dyn_string alertTexts = makeDynString( "OK", "Warning");
       
   dyn_float limits = makeDynFloat(0.9); 
   dyn_string alertClasses = makeDynString( "" ,"_fwErrorNack_70.");
   string alertPanel; 
   dyn_string alertPanelParameters,summary; 
   string alertHelp;
   fwAlertConfig_set(dp+".fvalue",DPCONFIG_ALERT_NONBINARYSIGNAL ,alertTexts,limits, alertClasses,summary,alertPanel,alertPanelParameters,
             alertHelp,exceptionInfo);
  }else
    return false;

}
  
void init(){
  
  dpstatus= makeDynString("RPC_DCSStatus","RPC_HWCommunication",
                                      "RPC_PCStatus","RPC_DSSStatus",
                                      "RPC_GASStatus","RPC_HWTemperature",
                                      "RPC_Cooling","RPC_FsmNotUpdated","RPC_SectorInError");
  dyn_string temp;
  string sup,uxc,usc,exc,esc,psx;
  sup = RPCfwSupervisor_getSupervisorSys();
  uxc = RPCfwSupervisor_getComponent("BarrelLV");
  usc = RPCfwSupervisor_getComponent("BarrelHV");
  
  exc = RPCfwSupervisor_getComponent("EndcapLV");
  esc = RPCfwSupervisor_getComponent("EndcapHV");
  psx = RPCfwSupervisor_getComponent("Services");
  
  RPCfwSupervisor_getSupervisorInit();

  if(psx =="") psx = _sersys;
  
  dyn_string systemNames = makeDynString(sup,uxc,usc,exc,esc,psx);
  
  //1: DCS led

  for(int i = 1; i<=dynlen(systemNames); i++)
  {
    temp = dpNames(systemNames[i]+"*Check*","RPCUtils");
    for(int j = 1; j<=dynlen(temp);j++)
    {
      dynAppend(chs2mon[1],temp[j]+".fvalue");
      dynAppend(reference[1],"0");
 
    }
    
  }

  //2: OPC comm led

  //  DebugTN("3");
  for(int i = 1; i<=dynlen(systemNames); i++)
  {
    temp = dpNames(systemNames[i]+"*caen*","RPCUtils");
    for(int j = 1; j<=dynlen(temp);j++)
    {
     dynAppend(chs2mon[2],temp[j]+".svalue");
      dynAppend(reference[2],"Ok");
     }
   }
  // 3: pcs status led
  dyn_string dps = makeDynString("_RDBArchive.dbConnection.connected",
                                 "_Connections.Dist.ManNums:_original.._active");
 dyn_string dpsErr = makeDynString("DB Connection problem on ",
                                 "Lost communication from ");
  for(int i = 1; i<=dynlen(systemNames); i++)
  {
    
    for(int j = 1; j<=dynlen(dps);j++)
      {
      dynAppend(chs2mon[3],systemNames[i]+dps[j]);
      dynAppend(reference[3],"TRUE");

      }
   }
  //DebugN(chs2mon);
// 4: DSS
   dyn_string dpalarm = dpNames(psx+"*DSS*","CMSfwAlertSystemSumAlerts");
  
  for(int i = 1; i<=dynlen(dpalarm);i++){
  
    dynAppend(chs2mon[4],dpalarm[i]+".Notification:_alert_hdl.._act_state");  
    dynAppend(reference[4],"0");
  }  

  // 5 : gas led
  dynAppend(chs2mon[5],psx + "AliveCounter.state:_original.._stime"); 
 dynAppend(reference[5],getCurrentTime());
  dyn_string dpelset = dpNames(psx +"*Infrastructure*", "RPCGasStatus");
  if(dynlen(dpelset)>0){
  dynAppend(chs2mon[5], dpelset[1]+ ".status"); 
  dynAppend(reference[5],0);
  }
 
  //6: equipment temperature

   dpalarm = dpNames(uxc+"*Board*","CMSfwAlertSystemSumAlerts");
  dynAppend(dpalarm,dpNames(usc+"*Board*","CMSfwAlertSystemSumAlerts"));
  dynAppend(dpalarm,dpNames(esc+"*Board*","CMSfwAlertSystemSumAlerts"));
  dynAppend(dpalarm,dpNames(exc+"*Board*","CMSfwAlertSystemSumAlerts"));
  //DebugN(dpalarm);

  for(int i = 1; i<=dynlen(dpalarm);i++){
  
   dynAppend(chs2mon[6],dpalarm[i]+".Notification:_alert_hdl.._act_state");   
  dynAppend(reference[6],"0");
  
  }
  // 7: Cooling
   dpalarm = dpNames(psx+"*Cooling*","CMSfwAlertSystemSumAlerts");
  

  for(int i = 1; i<=dynlen(dpalarm);i++){
  
  dynAppend(chs2mon[7],dpalarm[i]+".Notification:_alert_hdl.._act_state");  
  dynAppend(reference[7],"0");
  
  }  
  
  // 8 : FSM
dyn_string fsmnames;
  for(int i = 1; i<=dynlen(systemNames);i++){
   dynClear(fsmnames);
  fsmnames = dpNames(systemNames[i]+"*","_FwCtrlUnit");
  for(int j = 1;j<=dynlen(fsmnames);j++){
  dynAppend(chs2mon[8],fsmnames[j]+".running");
  dynAppend(reference[8],"1");
  }
  
  }
  
  // 9: page1 status
  dyn_string rpcsects;
  dyn_string objs = dpNames(sup+"*RPCTop_Tree","RPCVector");
  if(dynlen(objs)>0){  
    dpGet(objs[1]+".svalue",rpcsects);
    if(dynlen(rpcsects)>0){
       for(int j = 1;j<=dynlen(rpcsects);j++){
       dynAppend(chs2mon[9],rpcsects[j]);
       dynAppend(reference[9],"ERROR");
     }
        
    }
   }
  }
