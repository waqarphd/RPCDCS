/*
* Created by Giovanni Polese (CERN)
*	date:30/06/2011
*	LastChange:30/06/2012
*
*        version: 1.2
*        automatic actions 
*        procedure to avoid oscillating channels

*/

#uses "CMS_RPCfwSupervisor/CMS_RPCfwSupervisor.ctl"
#uses "CMSfwAlertSystem/CMSfwAlertSystemUtil.ctl"
#uses "CMSfwAlertSystem/CMSfwAlertSystemGeneral.ctc"
#uses "CMS_RPCfwGeneral/CMS_RPCfwGeneral.ctl"

const int CMSRPCHVCor_vMaxAllowed = 9700;
const int CMSRPCHVCor_vMinAllowed = 8800;
const int p0 = 965;
const int refreshTime = 300;//A full refresh every ~6min
const int CMSRPCHVCor_correctionThrInVoltage = 15;//Volt required before rising an alert in case of long fill
const int CMSRPCHVCor_autocorrectionThrInVoltage = 2;//Volt required before rising an alert in case of long fill with Auto mode
const float CMSRPCHVCor_roP = 1;
const float CMSRPCHVCor_gAlfa = 0.8;
const string CMSRPCHVCor_Confdp ="HVCorrectionSumStatus"; 
const string CMSRPCHVCor_dpe = ".readBackSettings.v1";
const string CMSRPCHVCor_dpeV0 = ".readBackSettings.v0";
const string CMSRPCHVCor_dpesetV0 = ".settings.v0";

string CMSRPCHVCor_dpPressure ;
dyn_int vMonAvg,v0Avg;
dyn_string CMSRPCHVCor_bufferChs;
dyn_int CMSRPCHVCor_frequency;

int erCode;
main()
{
  string usc,esc;
  //delay(1,0);
  dyn_string dps,correctionDps;
  erCode = 0;
  RPCfwSupervisor_getAllHVChannels(dps);
  

  dyn_string logname;
  string name,lname;
  dyn_dyn_string channels;
  int step;
  int cycle = 20;
  int delayPerCycle = refreshTime/cycle;    
      
  for(int i = 1;i<=dynlen(dps);i++){
    lname = fwDU_getLogicalName(dps[i]);
    if(lname!=""){
    logname = strsplit(lname,"/");
    if(dynlen(logname)>0) name = logname[dynlen(logname)];
    string dp = name+"_VBEST";
    initCorr(dp,dps[i]);    
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
  clearBuffer();
  while(1){
     
    pressure = updatePressure();
    if(pressure ==-1){//Use US pressure and correct for the expected gap
      pressure = updatePressure(1) -5;
    }
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

void clearBuffer(){
dynClear(CMSRPCHVCor_bufferChs);
dynClear(CMSRPCHVCor_frequency);

}

int getOccurencyAndAppend(string ch){

  int result;  
  int pos = dynContains(CMSRPCHVCor_bufferChs,ch);
  if(pos>0){
  CMSRPCHVCor_frequency[pos] = CMSRPCHVCor_frequency[pos]+1;
  return CMSRPCHVCor_frequency[pos];
  }else{
  dynAppend(CMSRPCHVCor_bufferChs,ch);
  dynAppend(CMSRPCHVCor_frequency,1);
  return 1;
  }
}
void removeIfAny(string ch){

  int pos = dynContains(CMSRPCHVCor_bufferChs,ch);
  if(pos>0){
  dynRemove(CMSRPCHVCor_bufferChs,pos);
  dynRemove(CMSRPCHVCor_frequency,pos);  
  }

}



void smsSumAlertConfig(){

string notifType = "RPCSup_PTCorrAlerts";
if(!dpExists("CMSAlertSystem/SumAlerts/" + notifType)){
  CMS_RPCfwGeneralInstallation_smsUserConfigRPCDefault(notifType);
  CMSfwAlertSystemUtil_addAlertToNotification(notifType,getSystemName()+CMSRPCHVCor_Confdp+".algorithmError.errorId") ;
  fwAlertConfig_activate("CMSAlertSystem/SumAlerts/" + notifType+".Notification",exInfo);  
  }
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
   fwArchive_set(getSystemName()+CMSRPCHVCor_Confdp+".vlimits.vMax","RDB-99) EVENT",DPATTR_ARCH_PROC_SIMPLESM,
                      DPATTR_TIME_AND_VALUE_SMOOTH,5,10000,exceptionInfo);
   fwArchive_set(getSystemName()+CMSRPCHVCor_Confdp+".vlimits.vMin","RDB-99) EVENT",DPATTR_ARCH_PROC_SIMPLESM,
                      DPATTR_TIME_AND_VALUE_SMOOTH,5,10000,exceptionInfo);
   
   }else{
   int sta;
  dpGet(CMSRPCHVCor_Confdp+".algorithmError.errorInfo:_alert_hdl.._act_state",sta);
  if(!sta)dpSet(CMSRPCHVCor_Confdp+".algorithmError.errorId",0);
  else dpSet(CMSRPCHVCor_Confdp+".algorithmError.errorId",2);
  if(erCode>3) dpSet(CMSRPCHVCor_Confdp+".algorithmError.errorId",erCode);
  erCode = 0;
  if(dynlen(v0Avg)>0)  
  dpSet(CMSRPCHVCor_Confdp+".voltage.v0",dynAvg(v0Avg),
        CMSRPCHVCor_Confdp+".voltage.vBest",dynAvg(vMonAvg),
        CMSRPCHVCor_Confdp+".vlimits.vMax",dynMax(vMonAvg),
        CMSRPCHVCor_Confdp+".vlimits.vMin",dynMin(vMonAvg));
  dynClear(v0Avg);
  dynClear(vMonAvg);
  }
}

float updatePressure(int backupSensor = 0){
  
  int oldestPressureAccepted = 7200;//2 hours
  float res = -1;
  if(CMSRPCHVCor_dpPressure==""){
  string env = RPCfwSupervisor_getComponent("Services");
  dyn_string dps;
  if(backupSensor==0)
   dps = dpNames(env+"*_UXCPressure","RPCGasParameters");
  else  
   dps = dpNames(env+"*_USServiceAtmoPressure","RPCGasParameters");
  
  if(dynlen(dps)==1){
      CMSRPCHVCor_dpPressure= dps[1]+".value";     
    }else return -1;
    
   }
  
   if(dpExistsDPE(CMSRPCHVCor_dpPressure)){
     time ts;
     dpGet(CMSRPCHVCor_dpPressure,res,CMSRPCHVCor_dpPressure+":_original.._stime",ts);
     if(ts <getCurrentTime()-oldestPressureAccepted) return -2;//Not refreshing value
     else {
        dyn_float vectPress;
        dynAppend(vectPress,res);      
        for(int i = 1;i<10;i++){
          delay(5,0);
          dpGet(CMSRPCHVCor_dpPressure,res);
          if((res <(p0-50) )||(res>(p0+50)))
            continue;
          else                
            dynAppend(vectPress,res); 
        }
       res = dynAvg(vectPress);        
       if((res <(p0-50) )||(res>(p0+50)))//Cut not reasonable pressure values
         return -3;
       else return res;
     }
   }else return -1;
  
  return res;

}

initCorr(string dp,string dpe){
 
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
  
void generateError(string dp,int errorCode){
string info;
  switch (errorCode){
  case 11: info = "Correction coefficient not valid"; erCode = errorCode;break;  
  case 12: info = "Pressure value not valid, equal to 0"; erCode = errorCode;break;
  case 13: info = "v0 value too high or too low for chamber On state"; break;
  case 14: info = "vBest calculate higher than the vMaxAllowed"; break;
  case 15: info = "vBest calculate lower than the vMinAllowed"; break;
  case 16: info = "Hardware dp unreachable";erCode = errorCode;break;
  case 3: info = "AutoCorr. applied at " + (string)getCurrentTime();errorCode=0 ;break;
  case 2: info = "HV correction disabled.";break;
  case 1: info = "Chamber ON, Additional correction needs to be applied for this chamber (more than "+CMSRPCHVCor_correctionThrInVoltage+" V)";break;
  default : info = "Value Ready to be applied."; break;   
  }
  
  if(dpExists(dp)) dpSet(dp+".algorithmError.errorInfo",info,dp+".algorithmError.errorId",errorCode);
}

int calculateV(string dp,float p){

 int vMax,vMin,v0;
 float rot,rop;
 int enabled; 
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
 int vBest;
 if(rop<=0) {
   generateError(dp,11);
   return -1;
 }


 
 if((v0>vMax)||(v0<vMin)){
   generateError(dp,13);
   return -1;
  }  
 /*
  div--;
  div = div*rop + 1;
  vBest = v0*rot*div;*/
  vBest = v0*(1-CMSRPCHVCor_gAlfa+(CMSRPCHVCor_gAlfa*div));
  
   
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

   
  if(enabled==0) {
    generateError(dp,2);
   return -1;
  }  
   
   if(!dpExistsDPE(ch+CMSRPCHVCor_dpe)){
      generateError(dp,16);
   return -1;   
   }else {
  
     int v0Applied;
     int vSoftmax;
     
     dpGet(ch+CMSRPCHVCor_dpeV0,v0Applied,
           dpSubStr(ch+CMSRPCHVCor_dpeV0,DPSUB_SYS_DP)+".readBackSettings.vMaxSoftValue",vSoftmax);
     //I am writing into the FSM       
     if(vBest<vSoftmax)
       dpSet(ch+CMSRPCHVCor_dpe,vBest); 
     else 
       dpSet(ch+CMSRPCHVCor_dpe,vSoftmax); 
    
       if(v0Applied>CMSRPCHVCor_vMinAllowed){
        
        if(((v0Applied-vBest)>CMSRPCHVCor_correctionThrInVoltage )||
           ((v0Applied-vBest)<-CMSRPCHVCor_correctionThrInVoltage ) ){
         
          if(vSoftmax>vBest){
            int vMon;
           dpGet(ch+".actual.vMon",vMon);
           if(vMon >CMSRPCHVCor_vMinAllowed){ 
                //manually mode enabled = 1
                 generateError(dp,1);
                 return -1;
                 
             }
           }
        }else if (enabled==2){///Revise this codeeeeeeeee
        if(((v0Applied-vBest)>CMSRPCHVCor_autocorrectionThrInVoltage )||
           ((v0Applied-vBest)<-CMSRPCHVCor_autocorrectionThrInVoltage ) ){
            if(vSoftmax>vBest){
            int vMon;
           dpGet(ch+".actual.vMon",vMon);
           if(vMon >CMSRPCHVCor_vMinAllowed){ 
             //Tha automatic correction goes here
             if(getOccurencyAndAppend(ch)>2){//it corrects only if the thr is overcome for 3 consequential times
        
               if(vBest<vSoftmax){
                    int intermediateStep;
                   if(v0Applied>vBest) intermediateStep =  vBest + (int)((v0Applied-vBest)/2);
                   else intermediateStep = vBest  - (int)((vBest - v0Applied)/2);                
                   if(((v0Applied-intermediateStep)<=CMSRPCHVCor_autocorrectionThrInVoltage )&&
                      ((v0Applied-intermediateStep)>=-CMSRPCHVCor_autocorrectionThrInVoltage ) ){                   
                     dpSet(ch+CMSRPCHVCor_dpesetV0,intermediateStep);
                     delay(1,500);
                   }            
                   dpSet(ch+CMSRPCHVCor_dpesetV0,vBest); 
                 
                 }
             else if(v0Applied!=vSoftmax) 
                   dpSet(ch+CMSRPCHVCor_dpesetV0,vSoftmax);
             
             removeIfAny(ch);                 
             generateError(dp,3);
             return 0;
             }              
             generateError(dp,0);
             return 0;

             }
           }        
        
          }else removeIfAny(ch);
          
        } ///patchaaaaa         
      }   
   }

  generateError(dp,0);  
  return 0;
}



