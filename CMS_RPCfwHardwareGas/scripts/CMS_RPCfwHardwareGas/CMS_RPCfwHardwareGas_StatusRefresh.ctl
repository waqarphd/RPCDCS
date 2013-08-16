/***********************************************
  RefreshStatusGas script
  
  Version 1.4
  
  
*************************************************/  

string dipAddress;
 int alivevalue;
string RPCGasGetSysName(){
  dyn_string systemNumber;
  
  fwInstallation_getApplicationSystem("CMS_RPCfwHardwareGas",systemNumber);
  if(dynlen(systemNumber)==1)
    return systemNumber[1];
  else
  {
    return getSystemName();
    DebugN("Gas Component not found");
  }  
}

string sysName;

 main()
{
sysName = RPCGasGetSysName();
 checkDpTimed("RPCGasTimedCheck",200);
 timedFunc("completeRefresh","RPCGasTimedCheck");  
}

void checkDpTimed(string dp,int sec)
{
  if(!dpExists(dp))
  {
    dpCreate(dp,"_TimedFunc");
    dpSet(dp+".syncTime",-1);
   
  }
   dpSet(dp+".interval",sec);
  }
 
completeRefresh()
{
 // DebugTN("-->Start");
  string sysName = RPCGasGetSysName();
  statusrefresh();
  racktotalflowrefresh();

 calcHumfromdewP();
 // DebugTN("-->First part Done");
  delay(10);
  
  aliverefresh();
  pumprefresh();
  purifierrefresh();
  humidifierrefresh();
  exhaustrefresh();
  mixerrefresh();
  barrelrefresh();
  //DebugN("Barrel done");
  endcaprefresh();
  //DebugN("Endcap done");
  infrastructurerefresh();
  //DebugN("Infrastructure done");
 // DebugTN("-->End");
}

void calcHumfromdewP(){


if(dpExists("Environmental_UXCHumidity"))  
  {  
  dyn_string dpel = dpNames(RPCGasGetSysName()+"*Cooling_*", "RPCCooling");  

  float temp, dewP,hum;



  if(dynlen(dpel)==2){
    if(strpos(dpel[1],"Dew")>0){
    dpGet(dpel[1]+".value",dewP,dpel[2]+".value",temp);  
      }
    else dpGet(dpel[2]+".value",dewP,dpel[1]+".value",temp);  


    hum = pow(10, ((dewP-temp)/31.5)+2);

  }
  dpSet(RPCGasGetSysName()+"Environmental_UXCHumidity.value",hum);
  //DebugN(hum);
  }else{
  dpCreate("Environmental_UXCHumidity","RPCGasParameters");
  }
}
//Refresh the general status datapoint of the pump

pumprefresh()
{
  string valueget, valueset;
  string dpelget = dpNames(sysName+"*Pump*", "RPCGasParameterStatus");
  string dpelset = dpNames(sysName+"*Pump*", "RPCGasStatus");
  dpGet(dpelget+".state", valueget);
  if(valueget == 1) valueset = 2;
  else if(valueget == 2) valueset = 1;
  else if(valueget == 3) valueset = 0;
  else valueset = 2;
  dpSet (dpelset+".status", valueset);
}

//Refresh the general status datapoint of the purifier

purifierrefresh()
{  
  string valueget, valueset;
  int flag1 = 0, flag2 = 0;
  int error = 0, warning = 0;
  dyn_string dpelgets = dpNames(sysName+"*Purifier*", "RPCGasParameterStatus");
  //DebugN(dpelgets);
  string dpelset = dpNames(sysName+"*Purifier*", "RPCGasStatus");
  
  for(int i=1; i<=dynlen(dpelgets); i++){
    dpGet(dpelgets[i]+".state", valueget);
    if(i==3 || i==6){
      //DebugN(dpelgets[i]);
      if(valueget == 2);
      else if(valueget == 100) error++;
      else warning++;
    }
    else if(i == 1 || i == 2){
      if(valueget == 100) error++;
      else if(valueget == 2 || valueget == 8) flag1 = 1;
    }
    else if(i == 4 || i ==5){
      if(valueget == 100) error++;
      else if((valueget == 2) || (valueget == 8)) flag2 = 1;
    }    
  }
  if(flag1 == 0) error++;
  if(flag2 == 0) error++;
  
  if(error!=0){
     valueset = 2;
     dpSet(dpelset+".error", error);
   }
  else{
    if(warning!=0){
      valueset = 1;
      dpSet(dpelset+".warning", warning);
    }
    else valueset = 0;
  }
 
  dpSet (dpelset+".status", valueset);
}

//Refresh the general status datapoint of the humidifier

humidifierrefresh()
{
  string valueget, valueset;
  string dpelget = dpNames(sysName+"*Humidifier*", "RPCGasParameterStatus");
  string dpelset = dpNames(sysName+"*Humidifier*", "RPCGasStatus");
  dpGet(dpelget+".state", valueget);
  if(valueget == 1) valueset = 2;
  else if(valueget == 2) valueset = 1;
  else if(valueget == 3) valueset = 0;
  else if(valueget == 4) valueset = 0;
  else valueset = 2;
  dpSet (dpelset+".status", valueset);
}

// humidifierrefresh()
// {
//   string valueget, valueset;
//   int error = 0, warning = 0, unacknowledge = 0;
//   dyn_string dpelgets = dpNames(sysName+"*Humidifier*", "RPCGasParameters");
  //DebugN(dpelgets);
//   string dpelset = dpNames(sysName+"*Humidifier*", "RPCGasStatus");
//   
//     for(int i=1; i<=dynlen(dpelgets); i++){
//         if(i==2){
//           dpGet(dpelgets[i]+".value", valueget);
//           if((valueget == 2) || (valueget == 3));
//           else if(valueget == 1) error++;
//           else warning++;
//           }
//     else if(i==3){
//       dpGet(dpelgets[i]+".value:_alert_hdl.._act_state_color", valueget);
//       if(valueget == "");
//       else if((valueget == "_FwAlarmErrorAck") || (valueget == "FwAlarmErrorUnack")) error++;
//       else if((valueget == "_FwAlarmWarnAck") || (valueget == "FwAlarmWarnUnack")) warning++;    
//       else if((valueget == "_FwAlarmWarnWentUnack") || (valueget == "_FwAlarmErrorWentUnack")) unacknowledge++;
//     }
//   }
//     
//     if((error!=0) || (unacknowledge!=0)){
//      valueset = 2;
//      dpSet(dpelset+".error", error);
//    }
//   else{
//     if(warning!=0){
//       valueset = 1;
//       dpSet(dpelset+".warning", warning);
//     }
//     else valueset = 0;
//   }
//  
//   dpSet (dpelset+".status", valueset);  
//     
// }

//Refresh the general status datapoint of the exhaust

exhaustrefresh()
{
  string valueget, valueset;
  string dpelget = dpNames(sysName+"*Exhaust*Stat*", "RPCGasParameterStatus");
  string dpelset = dpNames(sysName+"*Exhaust*", "RPCGasStatus");
  dpGet(dpelget+".state", valueget);
  if(valueget == 1) valueset = 2;
  else if((valueget == 2) || (valueget == 3)) valueset = 0;
  else valueset = 2;
  dpSet (dpelset+".status", valueset);
  
}

//Refresh the general status datapoint of mixer


mixerrefresh()
{
  string valueget, valueset;
  string dpelget = dpNames(sysName+"*Mixer*Stat*", "RPCGasParameterStatus");
  string dpelset = dpNames(sysName+"*Mixer*", "RPCGasStatus");
  dpGet(dpelget+".state", valueget);
  if(valueget == 1) valueset = 2;
  else if((valueget == 2) || (valueget == 3)) valueset = 0;
  else valueset = 0;
  dpSet (dpelset+".status", valueset);
  
}

// mixerrefresh()
// {
//   string valueget, valueset;
//   int error = 0, warning = 0, unacknowledge = 0;
//   dyn_string dpelget = dpNames(sysName+"*Mixer*", "RPCGasParameters");
  //DebugN(dpelget);
//   string dpelset = dpNames(sysName+"*Mixer*", "RPCGasStatus");
//   for(int i=1; i<=dynlen(dpelget); i++){
//     if(i == 3){
//       dpGet(dpelget[i]+".value", valueget);
//       if(valueget == 0) error++;
//     }
//     else if(i == 9){
//       dpGet(dpelget[i]+".value", valueget);
//       if(valueget == 1) error++;
//     }
//     else{
//       dpGet(dpelget[i]+".value:_alert_hdl.._act_state_color", valueget);
//       if(valueget == "");
//       else if((valueget == "_FwAlarmErrorAck") || (valueget == "FwAlarmErrorUnack")) error++;
//       else if((valueget == "_FwAlarmWarnAck") || (valueget == "FwAlarmWarnUnack")) warning++;    
//       else if((valueget == "_FwAlarmWarnWentUnack") || (valueget == "_FwAlarmErrorWentUnack")) unacknowledge++;
//     }
//   }
//   
//   if((error!=0) || (unacknowledge!=0)){
//      valueset = 2;
//      dpSet(dpelset+".error", error);
//    }
//   else{
//     if(warning!=0){
//       valueset = 1;
//       dpSet(dpelset+".warning", warning);
//     }
//     else valueset = 0;
//   }
//  
//   dpSet (dpelset+".status", valueset);  
// 
//}

barrelrefresh()
{
 int error=0, warning=0;
 string valueget, valueset, dpelset;
 dpelset = dpNames(sysName+"*Barrel*", "RPCGasStatus");
 dyn_string barrel = makeDynString("Rack69", "Rack70", "Rack71", "Rack72", "Rack73", "Rack74", 
                                   "Rack75", "Rack76", "Rack77", "Rack78"); 
 
 for(int i=1; i<=dynlen(barrel); i++){
   string dpelget = dpNames(sysName+"*"+barrel[i]+"*State", "RPCGasParameterStatus");
   //DebugN(dpelget); 
   dpGet(dpelget+".state", valueget);
   if(valueget == 1) error++;

 }
 
 if(error!=0) valueset = 2;
 else if(warning!=0) valueset = 1;
 else valueset = 0;
 
 dpSet(dpelset+".status", valueset);
  
}

endcaprefresh()
{
 int error=0, warning=0;
 string valueget, valueset, dpelset;
 dpelset = dpNames(sysName+"*Endcap*", "RPCGasStatus");
 dyn_string endcap = makeDynString("Rack65", "Rack62", "Rack63", "Rack66", "Rack67", "Rack80", 
                                   "Rack81", "Rack83", "Rack84", "Rack85"); 
 
 for(int i=1; i<=dynlen(endcap); i++){
   string dpelget = dpNames(sysName+"*"+endcap[i]+"*State", "RPCGasParameterStatus");
   //DebugN(dpelget); 
   dpGet(dpelget+".state", valueget);
   if(valueget == 1) error++;
   //else if (valueget == 1) warning++;
   else{}
 }
 
 if(error!=0) valueset = 2;
 else if(warning!=0) valueset = 1;
 else valueset = 0;
 
 dpSet(dpelset+".status", valueset);
  
   
}

infrastructurerefresh()
{
  int error=0, warning=0;
  string valueget, valueset, dpelset;
  dpelset = dpNames(sysName+"*Infrastructure*", "RPCGasStatus");
  dyn_string elementstatus = makeDynString("Pump", "Mixer", "Exhaust", "Humidifier", "Purifier");//, "Purifier1_", "Purifier2_", "Purifier3_");
  
  for(int i=1; i<=dynlen(elementstatus); i++){
    string dpelget = dpNames(sysName+"*"+elementstatus[i]+"*", "RPCGasStatus");
    //DebugN(dpelget);
    dpGet(dpelget+".status", valueget);
    //DebugN(valueget);
    if(valueget == 2) error++;
    //else if(valueget == 1) warning++;
    else{}
  }
  
  if(error!=0) valueset = 2;
  else if(warning!=0) valueset = 1;
  else valueset = 0;
  
  dpSet(dpelset+".status", valueset);
   
}


statusrefresh()
{
 dyn_string chamberEndcap = makeDynString("EM3", "EM2", "EM1", "EP1", "EP2", "EP3");
 dyn_string chamberBarrel = makeDynString("WM2", "WM1", "W00", "WP1", "WP2");
 dyn_string RackNr = makeDynString("Rack67", "Rack63", "Rack66", "Rack62", "Rack65", "Rack83", 
                                   "Rack84", "Rack80", "Rack85", "Rack81", "Rack74", "Rack69",
                                   "Rack75", "Rack70", "Rack76", "Rack71", "Rack77", "Rack72", 
                                   "Rack78", "Rack73");
  
 for(int i = 1; i<= 6; i++){
   dyn_string disck = dpNames(chamberEndcap[i]+"*", "RPCGasChannel");
   int warningNr = 0, errorNr = 0, unacknowledgeNr = 0;
   string alarmvalue;
   
   for(int j = 1; j<=dynlen(disck); j++){
     
    dpGet(disck[j]+".flowIn:_alert_hdl.._act_state_color", alarmvalue);
            if((alarmvalue == "FwAlarmWarnUnack") || (alarmvalue == "FwAlarmWarnAck")){
                   warningNr ++; 
                   }
            else if((alarmvalue == "FwAlarmErrorUnack") ||  (alarmvalue == "FwAlarmErrorAck")){
                   errorNr ++;
                   }
            else if((alarmvalue == "FwAlarmErrorWentUnack") || (alarmvalue == "FwAlarmWarnWentUnack")){
                unacknowledgeNr ++;
              } 
            else {}
                    
    dpGet(disck[j]+".flowOut:_alert_hdl.._act_state_color", alarmvalue);
            if((alarmvalue == "FwAlarmWarnUnack") || (alarmvalue == "FwAlarmWarnAck")){
                   warningNr ++; 
                   }
            else if((alarmvalue == "FwAlarmErrorUnack") ||  (alarmvalue == "FwAlarmErrorAck")){
                   errorNr ++;
                   }
            else if((alarmvalue == "FwAlarmErrorWentUnack") || (alarmvalue == "FwAlarmWarnWentUnack")){
                unacknowledgeNr ++;
              }
            else{}
                    
    dpGet(disck[j]+".difference:_alert_hdl.._act_state_color", alarmvalue);
            if((alarmvalue == "FwAlarmWarnUnack") || (alarmvalue == "FwAlarmWarnAck")){
                   warningNr ++; 
                   }
            else if((alarmvalue == "FwAlarmErrorUnack") ||  (alarmvalue == "FwAlarmErrorAck")){
                   errorNr ++;
                   }
            else if((alarmvalue == "FwAlarmErrorWentUnack") || (alarmvalue == "FwAlarmWarnWentUnack")){
                unacknowledgeNr ++;
              }  
            else{}
   
            
   
   
   }
     if(errorNr > 15) dpSet(sysName+chamberEndcap[i]+".status", 2);
    else{
         if(warningNr > 15) dpSet(sysName+chamberEndcap[i]+".status", 1);
         else{
              if(unacknowledgeNr > 15) dpSet(sysName+chamberEndcap[i]+".status", 2);
              else dpSet(sysName+chamberEndcap[i]+".status", 0);
    }
  }
  
  dpSet(sysName+chamberEndcap[i]+".error", errorNr);
  dpSet(sysName+chamberEndcap[i]+".warning", warningNr);
  dpSet(sysName+chamberEndcap[i]+".unacknowledge", unacknowledgeNr);
  
  //DebugTN(errorNr, warningNr, unacknowledgeNr);
 }
 
 
 
 //delay(10);
 
 
 
 
 
 for(int i = 1; i<= 5; i++){
   dyn_string wheel = dpNames(chamberBarrel[i]+"*", "RPCGasChannel");
   int warningNr = 0, errorNr = 0, unacknowledgeNr = 0;
   string alarmvalue;
   
   for(int j = 1; j<=dynlen(wheel); j++){
     
    dpGet(wheel[j]+".flowIn:_alert_hdl.._act_state_color", alarmvalue);
            if((alarmvalue == "FwAlarmWarnUnack") || (alarmvalue == "FwAlarmWarnAck")){
                   warningNr ++; 
                   }
            else if((alarmvalue == "FwAlarmErrorUnack") ||  (alarmvalue == "FwAlarmErrorAck")){
                   errorNr ++;
                   }
            else if((alarmvalue == "FwAlarmErrorWentUnack") || (alarmvalue == "FwAlarmWarnWentUnack")){
                unacknowledgeNr ++;
              } 
            else {}
                    
    dpGet(wheel[j]+".flowOut:_alert_hdl.._act_state_color", alarmvalue);
            if((alarmvalue == "FwAlarmWarnUnack") || (alarmvalue == "FwAlarmWarnAck")){
                   warningNr ++; 
                   }
            else if((alarmvalue == "FwAlarmErrorUnack") ||  (alarmvalue == "FwAlarmErrorAck")){
                   errorNr ++;
                   }
            else if((alarmvalue == "FwAlarmErrorWentUnack") || (alarmvalue == "FwAlarmWarnWentUnack")){
                unacknowledgeNr ++;
              }
            else{}
                    
    dpGet(wheel[j]+".difference:_alert_hdl.._act_state_color", alarmvalue);
            if((alarmvalue == "FwAlarmWarnUnack") || (alarmvalue == "FwAlarmWarnAck")){
                   warningNr ++; 
                   }
            else if((alarmvalue == "FwAlarmErrorUnack") ||  (alarmvalue == "FwAlarmErrorAck")){
                   errorNr ++;
                   }
            else if((alarmvalue == "FwAlarmErrorWentUnack") || (alarmvalue == "FwAlarmWarnWentUnack")){
                unacknowledgeNr ++;
              }  
            else{}
   
            
   
   
   }
     if(errorNr > 15) dpSet(sysName+chamberBarrel[i]+".status", 2);
    else{
         if(warningNr >15) dpSet(sysName+chamberBarrel[i]+".status", 1);
         else{
              if(unacknowledgeNr >15) dpSet(sysName+chamberBarrel[i]+".status", 2);
              else dpSet(sysName+chamberBarrel[i]+".status", 0);
    }
  }
  
  dpSet(sysName+chamberBarrel[i]+".error", errorNr);
  dpSet(sysName+chamberBarrel[i]+".warning", warningNr);
  dpSet(sysName+chamberBarrel[i]+".unacknowledge", unacknowledgeNr);
  //DebugTN(errorNr, warningNr, unacknowledgeNr);
 } 
 
  
  for(int i =1; i<=20; i++){
    dyn_string rack = dpNames("*"+RackNr[i]+"*", "RPCGasParameterStatus");
    int warningNr = 0, errorNr = 0, unacknowledgeNr = 0;
    string alarmvalue;
  
    //DebugN(rack);
     for(int j = 1; j<=dynlen(rack); j++){
      
     dpGet(rack[j]+".state:_alert_hdl.._act_state_color", alarmvalue);
             if((alarmvalue == "FwAlarmWarnUnack") || (alarmvalue == "FwAlarmWarnAck")){
                    warningNr ++; 
                    }
             else if((alarmvalue == "FwAlarmErrorUnack") ||  (alarmvalue == "FwAlarmErrorAck")){
                    errorNr ++;
                    }
             else if((alarmvalue == "FwAlarmErrorWentUnack") || (alarmvalue == "FwAlarmWarnWentUnack")){
                 unacknowledgeNr ++;
               } 
             else {}
//                     
//     dpGet(rack[j]+".flowOut:_alert_hdl.._act_state_color", alarmvalue);
//             if((alarmvalue == "FwAlarmWarnUnack") || (alarmvalue == "FwAlarmWarnAck")){
//                    warningNr ++; 
//                    }
//             else if((alarmvalue == "FwAlarmErrorUnack") ||  (alarmvalue == "FwAlarmErrorAck")){
//                    errorNr ++;
//                    }
//             else if((alarmvalue == "FwAlarmErrorWentUnack") || (alarmvalue == "FwAlarmWarnWentUnack")){
//                 unacknowledgeNr ++;
//               }
//             else{}
//                     
//     dpGet(rack[j]+".difference:_alert_hdl.._act_state_color", alarmvalue);
//             if((alarmvalue == "FwAlarmWarnUnack") || (alarmvalue == "FwAlarmWarnAck")){
//                    warningNr ++; 
//                    }
//             else if((alarmvalue == "FwAlarmErrorUnack") ||  (alarmvalue == "FwAlarmErrorAck")){
//                    errorNr ++;
//                    }
//             else if((alarmvalue == "FwAlarmErrorWentUnack") || (alarmvalue == "FwAlarmWarnWentUnack")){
//                 unacknowledgeNr ++;
//               }  
//             else{}
//      
    }
      if(errorNr != 0) dpSet(sysName+RackNr[i]+".status", 2);
     else{
          if(warningNr !=0) dpSet(sysName+RackNr[i]+".status", 1);
          else{
               if(unacknowledgeNr !=0) dpSet(sysName+RackNr[i]+".status", 2);
               else dpSet(sysName+RackNr[i]+".status", 0);
     }
   }
   
   dpSet(sysName+RackNr[i]+".error", errorNr);
   dpSet(sysName+RackNr[i]+".warning", warningNr);
   dpSet(sysName+RackNr[i]+".unacknowledge", unacknowledgeNr);
//   
  //DebugTN(errorNr, warningNr, unacknowledgeNr);
//    
//    
  }
//  
}

racktotalflowrefresh()
{

  dyn_string endcapRacks = makeDynString("Rack65", "Rack62", "Rack63", "Rack66", "Rack67", 
                                         "Rack80", "Rack81", "Rack83", "Rack84", "Rack85");
  dyn_string barrelRacks = makeDynString("Rack69", "Rack70", "Rack71", "Rack72", "Rack73", 
                                         "Rack74", "Rack75", "Rack76", "RAck77", "Rack78");
  
  
}

aliverefresh()
{
 string dpname = dpNames(sysName+"*AliveCounter*", "RPCGasParameterStatus");
 string dpeset = dpNames(sysName+"*GeneralServiceSystem*", "RPCGasStatus");
 int check; 
 dpGet(dpname+".state", check);
 //DebugN(dpname, check);
 if(check == alivevalue){
  dpSet(dpeset+".status", 2);
  dpSet(dpeset+".error", 1);
 }
 else{
   dpSet(dpeset+".status", 0);
   dpSet(dpeset+".error", 0);
   alivevalue = check;
 }
}
