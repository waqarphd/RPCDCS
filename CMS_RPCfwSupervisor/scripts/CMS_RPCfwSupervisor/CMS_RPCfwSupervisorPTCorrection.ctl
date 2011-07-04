/*
* Created by Giovanni Polese (CERN)
*	date:30/06/2011
*	LastChange:30/06/2011
*
*        version: 1.1
*         
*/

#uses "CMS_RPCfwSupervisor/CMS_RPCfwSupervisor.ctl"
#uses "CMSfwAlertSystem/CMSfwAlertSystemUtil.ctl"
#uses "CMSfwAlertSystem/CMSfwAlertSystemGeneral.ctc"

const int CMSRPCHVCor_vMaxAllowed = 9700;
const int CMSRPCHVCor_vMinAllowed = 8800;
const int p0 = 965;
const int refreshTime = 400;//A full refresh every ~8min
const int CMSRPCHVCor_correctionThrInVoltage = 40;//Volt required before rising an alert in case of long fill
const float CMSRPCHVCor_roP = 1;

const string CMSRPCHVCor_Confdp ="HVCorrectionSumStatus"; 
const string CMSRPCHVCor_dpe = ".readBackSettings.v1";
const string CMSRPCHVCor_dpeV0 = ".readBackSettings.v0";

string CMSRPCHVCor_dpPressure ;
dyn_int vMonAvg,v0Avg;
main()
{
  string usc,esc;
  //delay(1,0);
  dyn_string dps,correctionDps;
  
  RPCfwSupervisor_getAllHVChannels(dps);
  

  dyn_string logname;
  string name,lname;
  dyn_dyn_string channels;
  int step;
  int cycle = 20;
  int delayPerCycle = refreshTime/cycle;    
      
  checkType();

  for(int i = 1;i<=dynlen(dps);i++){
    lname = fwDU_getLogicalName(dps[i]);
    if(lname!=""){
    logname = strsplit(lname,"/");
    if(dynlen(logname)>0) name = logname[dynlen(logname)];
    string dp = name+"_VBEST";
    init(dp,dps[i]);    
    dynAppend(correctionDps,dp);
    }
  }

  //Split the channels number in order to decrease the load on the data man
  for(int i = 1;i<=dynlen(correctionDps);i++){

     step = (i % cycle) + 1;
     dynAppend(channels[step],correctionDps[i]);
     
   }   
  int res = 0;
  summaryStatus(res);
  createSumAlert(CMSRPCHVCor_Confdp+".algorithmError.errorInfo",correctionDps);
  smsSumAlertConfig();
  float pressure;
  while(1){
     
    pressure = updatePressure();
    
    if(CMSRPCHVCor_Confdp !="") dpSet(CMSRPCHVCor_Confdp+".params.P",pressure); 
    if(dynlen(channels)!=0){
    for(int i = 1;i<=dynlen(channels);i++){
       for(int j = 1;j<=dynlen(channels[i]);j++){
      dpSet(channels[i][j]+".params.P",pressure); 
      res += calculateV(channels[i][j],pressure);          
      }
      delay(delayPerCycle);
      
    }
    summaryStatus(res);
    res = 0; 
    }else break;

  dynClear(v0Avg);
  dynClear(vMonAvg);
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
  string notifType = "RPCSup_PTCorrAlerts";
  notif = dpNames("*"+notifType+"*","CMSfwAlertSystemSumAlerts");
  if(dynlen(notif)!=0)    dpDelete(notif[1]);
    CMSfwAlertSystemUtil_createNotification(notifType);
  
  /////// ******************** Add alert to notification

                  
 
 CMSfwAlertSystemUtil_addAlertToNotification(notifType,getSystemName()+CMSRPCHVCor_Confdp+".algorithmError.errorId") ;
    
  // **************** Add user to notificatio
  
  CMSfwAlertSystemUtil_addNotificationToUser(user1,notifType,"EMAIL",50);
  CMSfwAlertSystemUtil_addNotificationToUser(user1,notifType,"SMS",50);
  CMSfwAlertSystemUtil_addNotificationToUser(user2,notifType,"SMS",50);

fwAlertConfig_activate("CMSAlertSystem/SumAlerts/" + notifType+".Notification",exInfo);

  }

int createSumAlert(string dpe,dyn_string elem){


  string alertPanel; dyn_string alertPanelParameters,summary; string alertHelp;
  dyn_string exceptionInfo,
  alertTexts = makeDynString("OK", "HV PT Correction in warning state") ;
  
  dyn_float limits =  makeDynFloat( 1 ); 

  dyn_string alertClasses;// = makeDynString( "" ,"_fwErrorNack_70.");


  for(int i = 1;i<=dynlen(elem);i++)
    elem[i] = elem[i]+".algorithmError.errorId";
  
  
  fwAlertConfig_deactivate(dpe,exceptionInfo);
  fwAlertConfig_set(dpe,DPCONFIG_SUM_ALERT ,alertTexts,limits, alertClasses
                         ,elem,alertPanel,alertPanelParameters,
                           alertHelp,exceptionInfo);
  //
  //DebugN(exceptionInfo);
  fwAlertConfig_activate(dpe,exceptionInfo);
  //dpSet(dpe+":_alert_hdl.2._class", "_fwErrorNack_70.");
}

void summaryStatus(int res){
 
      
  
    if(!dpExists(CMSRPCHVCor_Confdp)){
      dpCreate(CMSRPCHVCor_Confdp,RPCfwSupervisor_HVCorrDpType);
   dyn_string alertTexts = makeDynString( "OK","HV Pressure Correction procedure in warning state");
       
   dyn_float limits = makeDynFloat(1); 
   dyn_string alertClasses =makeDynString( "","_fwErrorNack_70.");
   string alertPanel; 
   dyn_string alertPanelParameters,summary,exceptionInfo; 
   string alertHelp;
   fwAlertConfig_set(CMSRPCHVCor_Confdp+".algorithmError.errorId",DPCONFIG_ALERT_NONBINARYSIGNAL ,alertTexts,limits, alertClasses,
                     summary,alertPanel,alertPanelParameters,
                     alertHelp,exceptionInfo);   
   fwAlertConfig_activate(CMSRPCHVCor_Confdp+".algorithmError.errorId",exceptionInfo);

      
     
 
   fwArchive_set(getSystemName()+CMSRPCHVCor_Confdp+".voltage.v0","RDB-99) EVENT",DPATTR_ARCH_PROC_SIMPLESM,
                      DPATTR_TIME_AND_VALUE_SMOOTH,5,100000,exceptionInfo);
   fwArchive_set(getSystemName()+CMSRPCHVCor_Confdp+".voltage.vBest","RDB-99) EVENT",DPATTR_ARCH_PROC_SIMPLESM,
                      DPATTR_TIME_AND_VALUE_SMOOTH,5,10000,exceptionInfo);
   
   
   }else{
   bool sta;
  dpGet(CMSRPCHVCor_Confdp+".algorithmError.errorInfo:_alert_hdl.._active",sta);
  if(sta)dpSet(CMSRPCHVCor_Confdp+".algorithmError.errorId",2);
  else dpSet(CMSRPCHVCor_Confdp+".algorithmError.errorId",0); 
  if(dynlen(v0Avg)>0)  
  dpSet(CMSRPCHVCor_Confdp+".voltage.v0",dynAvg(v0Avg),CMSRPCHVCor_Confdp+".voltage.vBest",dynAvg(vMonAvg));
  dynClear(v0Avg);
  dynClear(vMonAvg);
  }
}

float updatePressure(){
  
  int oldestPressureAccepted = 7200;//2 hours
  float res = -1;
  if(CMSRPCHVCor_dpPressure==""){
  string env = RPCfwSupervisor_getComponent("Services");
  dyn_string dps = dpNames(env+"*_UXCPressure","RPCGasParameters");

  if(dynlen(dps)==1){
      CMSRPCHVCor_dpPressure= dps[1]+".value";     
    }else return -1;
    
   }
  
   if(dpExistsDPE(CMSRPCHVCor_dpPressure)){
     time ts;
     dpGet(CMSRPCHVCor_dpPressure,res,CMSRPCHVCor_dpPressure+":_original.._stime",ts);
     if(ts <getCurrentTime()-oldestPressureAccepted) return -2;//Not refreshing value
     else if((res <(p0-50) )||(res>(p0+50)))//Cut not reasonable pressure values
       return -3;
     else return res;
         
   }else return -1;
  
  return res;

}

init(string dp,string dpe){
 
   int vMax,vMin,v0;
   float rop;
   string ch;

  if(!dpExists(dp)){
   
   dpCreate(dp,RPCfwSupervisor_HVCorrDpType);
  
   dyn_string alertTexts = makeDynString("OK","Warning Condition for HV Pressure correction", "Algorithm Error");
       
   dyn_float limits = makeDynInt(1,10); 
   dyn_string alertClasses =makeDynString("","_fwErrorNack.", "_fwErrorNack."); //makeDynString("","_fwErrorNack_70.", "_fwErrorNack_70.");
   string alertPanel; 
   dyn_string alertPanelParameters,summary,exceptionInfo; 
   string alertHelp;
   fwAlertConfig_set(dp+".algorithmError.errorId",DPCONFIG_ALERT_NONBINARYSIGNAL ,alertTexts,limits, alertClasses,
                     summary,alertPanel,alertPanelParameters,
                     alertHelp,exceptionInfo);   
   fwAlertConfig_activate(dp+".algorithmError.errorId",exceptionInfo);
   
  } 
 
  dpGet(dp+".vlimits.vMax",vMax,dp+".vlimits.vMin",
      vMin,dp+".hwChannel",ch,dp+".coefficients.roP",rop);
   
  if(vMax==0)
  dpSet(dp+".vlimits.vMax",CMSRPCHVCor_vMaxAllowed);
  if(vMin==0)
    dpSet(dp+".vlimits.vMin",CMSRPCHVCor_vMinAllowed);
  if(rop!=CMSRPCHVCor_roP)
    dpSet(dp+".coefficients.roP",CMSRPCHVCor_roP);
  if(ch !=dpe) 
     dpSet(dp+".hwChannel",dpe);
}  
  
generateError(string dp,int errorCode){
string info;
  switch (errorCode){
  case 11: info = "Correction coefficient not valid"; break;  
  case 12: info = "Pressure value not valid, equal to 0"; break;
  case 13: info = "v0 value too high or too low for chamber On state"; break;
  case 14: info = "vBest calculate higher than the vMaxAllowed"; break;
  case 15: info = "vBest calculate lower than the vMinAllowed"; break;
  case 16: info = "HV correction disabled";break;
  case 17: info = "Hardware dp unreachable";break;
  case 1: info = "Chamber ON, Additional correction is required for this chamber (more than "+CMSRPCHVCor_correctionThrInVoltage+" V)";break;
  default : info = "Value Ready to be applied. Chamber in STB"; break;   
  }
  if(dpExists(dp)) dpSet(dp+".algorithmError.errorInfo",info,dp+".algorithmError.errorId",errorCode);
}

int calculateV(string dp,float p){

 int vMax,vMin,v0;
 float rot,rop;
 bool enabled; 
  string ch;

  dpGet(dp+".vlimits.vMax",vMax,dp+".vlimits.vMin",
      vMin,dp+".coefficients.roT",rot,dp+".coefficients.roP",rop,
      dp+".voltage.v0",v0,
      dp+".enabled",enabled,dp+".hwChannel",ch);


  rot = 1;
  
  if(p<=0){
    generateError(dp,12);
   return -1;
  }
 float i = (float) p;
 float i1 = (float) p0;
 float div = i/i1;
 div--;
 if(rop<=0) {
   generateError(dp,11);
   return -1;
 }

 div = div*rop + 1;
 
 if((v0>vMax)||(v0<vMin)){
   generateError(dp,13);
   return -1;
  }  
  
   int vBest = v0*rot*div;

      //Add to the avg only the parameters really to be loaded into the sys  
  dynAppend(v0Avg,v0);
  dynAppend(vMonAvg,vBest);     
   
   if(vBest>vMax){
   generateError(dp,14);
   return -1;
   }
   if(vBest<vMin){
   generateError(dp,15);
   return -1;
   }
   dpSet(dp+".voltage.vBest",vBest);

   
  if(!enabled) {
    generateError(dp,16);
   return -1;
  }  
   
   if(!dpExistsDPE(ch+CMSRPCHVCor_dpe)){
      generateError(dp,17);
   return -1;   
   }else {
          
    dpSet(ch+CMSRPCHVCor_dpe,vBest); 
  
     int v0Applied;
     
     dpGet(ch+CMSRPCHVCor_dpeV0,v0Applied);
    
       if(v0Applied>CMSRPCHVCor_vMinAllowed){
        
        if(((v0Applied-vBest)>CMSRPCHVCor_correctionThrInVoltage )||
           ((v0Applied-vBest)<-CMSRPCHVCor_correctionThrInVoltage ) ){   
           generateError(dp,1);
           return -1; 
         }          
        }   
   }

   generateError(dp,0);  
  return 0;
}

bool checkType(){

  
  dyn_dyn_string elements,xxdepes; 
  dyn_dyn_int types,xxdepei;
  dyn_string tys = dpTypes(RPCfwSupervisor_HVCorrDpType);

  
  
  xxdepes[1] = makeDynString (RPCfwSupervisor_HVCorrDpType);
  
  xxdepes[2] = makeDynString ("","enabled");

xxdepes[3] = makeDynString ("","voltage");

xxdepes[4] = makeDynString ("","","vBest");

xxdepes[5] = makeDynString ("","","v0");

xxdepes[6] = makeDynString ("","vlimits");

xxdepes[7] = makeDynString ("","","vMax");

xxdepes[8] = makeDynString ("","","vMin");

xxdepes[9] = makeDynString ("","algorithmError");

xxdepes[10] = makeDynString ("","","errorId");

xxdepes[11] = makeDynString ("","","errorInfo");

xxdepes[12] = makeDynString ("","hwChannel");

xxdepes[13] = makeDynString ("","coefficients");

xxdepes[14] = makeDynString ("","","roT");

xxdepes[15] = makeDynString ("","","roP"); 

xxdepes[16] = makeDynString ("","params");

xxdepes[17] = makeDynString ("","","P");

xxdepes[18] = makeDynString ("","","T");


xxdepei[1] = makeDynInt (DPEL_STRUCT);

xxdepei[2] = makeDynInt (0,DPEL_BOOL);

xxdepei[3] = makeDynInt (0,DPEL_STRUCT);

xxdepei[4] = makeDynInt (0,0,DPEL_INT);

xxdepei[5] = makeDynInt (0,0,DPEL_INT);

xxdepei[6] = makeDynInt (0,DPEL_STRUCT);

xxdepei[7] = makeDynInt (0,0,DPEL_INT);

xxdepei[8] = makeDynInt (0,0,DPEL_INT);

xxdepei[9] = makeDynInt (0,DPEL_STRUCT);

xxdepei[10] = makeDynInt (0,0,DPEL_INT);

xxdepei[11] = makeDynInt (0,0,DPEL_STRING);
 
xxdepei[12] = makeDynInt (0,DPEL_STRING);

xxdepei[13] = makeDynInt (0,DPEL_STRUCT);

xxdepei[14] = makeDynInt (0,0,DPEL_FLOAT);

xxdepei[15] = makeDynInt (0,0,DPEL_FLOAT);
 
xxdepei[16] = makeDynInt (0,DPEL_STRUCT);

xxdepei[17] = makeDynInt (0,0,DPEL_FLOAT);

xxdepei[18] = makeDynInt (0,0,DPEL_FLOAT);

if(dynlen(tys)>0)  {
    dpTypeGet(RPCfwSupervisor_HVCorrDpType, elements, types);

if(!(compare(elements,xxdepes)&& compare(types,xxdepei)))
{
  dyn_string dps = dpNames("*",RPCfwSupervisor_HVCorrDpType);
  
  for(int i = 1;i<=dynlen(dps);i++) dpDelete(dps[i]);

  dpTypeDelete(RPCfwSupervisor_HVCorrDpType);

  dpTypeCreate(xxdepes,xxdepei);
}
}else dpTypeCreate(xxdepes,xxdepei);


}
bool compare(dyn_dyn_anytype a,dyn_dyn_anytype b){
  
 
if(dynlen(a)!= dynlen(b)) return false;  
  
for(int i = 1; i<=dynlen(a);i++){

  if(dynlen(a[i])!=dynlen(b[i])) 
    return false;
  for(int j = 1;j<=dynlen(a[i]);j++){
    if(a[i][j]!=b[i][j]){

      return false;
    }
  }

}

return true;
}

