

main() {

// Start the timed functions

checkDpTimed("RPC_GGM_cron",240);
timedFunc("GGMsystemCheck","RPC_GGM_cron");

}

void GGMsystemCheck() {
 
 float temp, volt, pres, hv1, hv2, hv3, hv4, hv5, hv6, hv7, hv8, hv_trg0, hv_trg1, hv_trg2, hv_trg3;
 bool auto1, auto2, auto3, auto4, auto5, auto6, auto7, auto8, auto_trg0, auto_trg1, auto_trg2, auto_trg3;
 int rc;
 
 rc=dpGet(RPCGGM_getSysName()+"sensors.temperature_box",temp);  
 rc=dpGet(RPCGGM_getSysName()+"sensors.pressure_box",pres);  

 rc=dpGet(RPCGGM_getSysName()+"rpc_ggm_ch01.hv",hv1);
 rc=dpGet(RPCGGM_getSysName()+"rpc_ggm_ch02.hv",hv2); 
 rc=dpGet(RPCGGM_getSysName()+"rpc_ggm_ch03.hv",hv3);  
 rc=dpGet(RPCGGM_getSysName()+"rpc_ggm_ch04.hv",hv4);  
 rc=dpGet(RPCGGM_getSysName()+"rpc_ggm_ch05.hv",hv5);  
 rc=dpGet(RPCGGM_getSysName()+"rpc_ggm_ch06.hv",hv6);  
 rc=dpGet(RPCGGM_getSysName()+"rpc_ggm_ch07.hv",hv7);  
 rc=dpGet(RPCGGM_getSysName()+"rpc_ggm_ch08.hv",hv8);  
 rc=dpGet(RPCGGM_getSysName()+"rpc_ggm_trg0.hv",hv_trg0); 
 rc=dpGet(RPCGGM_getSysName()+"rpc_ggm_trg1.hv",hv_trg1); 
 rc=dpGet(RPCGGM_getSysName()+"rpc_ggm_trg2.hv",hv_trg2); 
 rc=dpGet(RPCGGM_getSysName()+"rpc_ggm_trg3.hv",hv_trg3); 

 
 rc=dpGet(RPCGGM_getSysName()+"rpc_ggm_ch01.autohv",auto1); 
 rc=dpGet(RPCGGM_getSysName()+"rpc_ggm_ch02.autohv",auto2); 
 rc=dpGet(RPCGGM_getSysName()+"rpc_ggm_ch03.autohv",auto3);  
 rc=dpGet(RPCGGM_getSysName()+"rpc_ggm_ch04.autohv",auto4);  
 rc=dpGet(RPCGGM_getSysName()+"rpc_ggm_ch05.autohv",auto5);  
 rc=dpGet(RPCGGM_getSysName()+"rpc_ggm_ch06.autohv",auto6);  
 rc=dpGet(RPCGGM_getSysName()+"rpc_ggm_ch07.autohv",auto7);  
 rc=dpGet(RPCGGM_getSysName()+"rpc_ggm_ch08.autohv",auto8);  
 rc=dpGet(RPCGGM_getSysName()+"rpc_ggm_trg0.autohv",auto_trg0); 
 rc=dpGet(RPCGGM_getSysName()+"rpc_ggm_trg1.autohv",auto_trg1); 
 rc=dpGet(RPCGGM_getSysName()+"rpc_ggm_trg2.autohv",auto_trg2); 
 rc=dpGet(RPCGGM_getSysName()+"rpc_ggm_trg3.autohv",auto_trg3); 

 if (auto_trg0==1) {
   volt = hv_trg0*(pres/965)*(293/(temp+273));
   if (volt>8000) {
     if (volt<10400) {
       dpSetWait(RPCGGM_getSysName()+"CAEN/GGM/board00/channel000.settings.v0", volt);
     }
   }
 }
 else {
   dpSetWait(RPCGGM_getSysName()+"CAEN/GGM/board00/channel000.settings.v0", hv_trg0);
 }  
 
 if (auto_trg1==1) {
   volt = hv_trg1*(pres/965)*(293/(temp+273));
   if (volt>8000) {
     if (volt<10400) {
       dpSetWait(RPCGGM_getSysName()+"CAEN/GGM/board00/channel001.settings.v0", volt);
     }
   }
 }
 else {
   dpSetWait(RPCGGM_getSysName()+"CAEN/GGM/board00/channel001.settings.v0", hv_trg1);
 }   
 
 if (auto_trg2==1) {
   volt = hv_trg2*(pres/965)*(293/(temp+273));
   if (volt>8000) {
     if (volt<10400) {
       dpSetWait(RPCGGM_getSysName()+"CAEN/GGM/board02/channel004.settings.v0", volt);
     }
   }
 }
 else {
   dpSetWait(RPCGGM_getSysName()+"CAEN/GGM/board02/channel004.settings.v0", hv_trg2);
 }   
 
 if (auto_trg3==1) {
   volt = hv_trg3*(pres/965)*(293/(temp+273));
   if (volt>8000) {
     if (volt<10400) {
       dpSetWait(RPCGGM_getSysName()+"CAEN/GGM/board02/channel005.settings.v0", volt);
     }
   }
 }
 else {
   dpSetWait(RPCGGM_getSysName()+"CAEN/GGM/board02/channel005.settings.v0", hv_trg3);
 }    
 
 
 if (auto1==1) {
   volt = hv1*(pres/965)*(293/(temp+273));
   if (volt>8000) {
     if (volt<10400) {
       dpSetWait(RPCGGM_getSysName()+"CAEN/GGM/board00/channel002.settings.v0", volt);
     }
   }
 }
 else {
   dpSetWait(RPCGGM_getSysName()+"CAEN/GGM/board00/channel002.settings.v0", hv1);
 }  
 

  if (auto2==1) {
   volt = hv2*(pres/965)*(293/(temp+273));
   if (volt>8000) {
     if (volt<10400) {
       dpSetWait(RPCGGM_getSysName()+"CAEN/GGM/board00/channel003.settings.v0", volt);
     }
   }
 }
 else {
   dpSetWait(RPCGGM_getSysName()+"CAEN/GGM/board00/channel003.settings.v0", hv2);
 }
 
 
 if (auto3==1) {
   volt = hv3*(pres/965)*(293/(temp+273));
   if (volt>8000) {
     if (volt<10400) {
       dpSetWait(RPCGGM_getSysName()+"CAEN/GGM/board00/channel004.settings.v0", volt);
     }
   }
 }
 else {
   dpSetWait(RPCGGM_getSysName()+"CAEN/GGM/board00/channel004.settings.v0", hv3);
 }
 
 
 
 if (auto4==1) {
   volt = hv4*(pres/965)*(293/(temp+273));
   if (volt>8000) {
     if (volt<10400) {
       dpSetWait(RPCGGM_getSysName()+"CAEN/GGM/board00/channel005.settings.v0", volt);
     }
   }
 }
 else {
   dpSetWait(RPCGGM_getSysName()+"CAEN/GGM/board00/channel005.settings.v0", hv4);
 }
 
 
 if (auto5==1) { 
   volt = hv5*(pres/965)*(293/(temp+273));
   if (volt>8000) {
     if (volt<10400) {
       dpSetWait(RPCGGM_getSysName()+"CAEN/GGM/board02/channel000.settings.v0", volt);
     }
   }
 }
 else {
   dpSetWait(RPCGGM_getSysName()+"CAEN/GGM/board02/channel000.settings.v0", hv5);
 }
 
 
 
 if (auto6==1) {
   volt = hv6*(pres/965)*(293/(temp+273));
   if (volt>8000) {
     if (volt<10400) {
       dpSetWait(RPCGGM_getSysName()+"CAEN/GGM/board02/channel001.settings.v0", volt);
     }
   }
 }
 else {
   dpSetWait(RPCGGM_getSysName()+"CAEN/GGM/board02/channel001.settings.v0", hv6);
 }
 
 
 if (auto7==1) {
   volt = hv7*(pres/965)*(293/(temp+273));
   if (volt>8000) {
     if (volt<10400) {
       dpSetWait(RPCGGM_getSysName()+"CAEN/GGM/board02/channel002.settings.v0", volt);
     }
   }
 }
 else {
   dpSetWait(RPCGGM_getSysName()+"CAEN/GGM/board02/channel002.settings.v0", hv7);
 }
 
 
 if (auto8==1) {
   volt = hv8*(pres/965)*(293/(temp+273));
   if (volt>8000) {
     if (volt<10400) {
       dpSetWait(RPCGGM_getSysName()+"CAEN/GGM/board02/channel003.settings.v0", volt); 
     }
   }
 }
 else {
   dpSetWait(RPCGGM_getSysName()+"CAEN/GGM/board02/channel003.settings.v0", hv8);
 }
 
}

string RPCGGM_getSysName(){
 
dyn_string systemNumber;
fwInstallation_getApplicationSystem("CMS_RPCfwGGM",systemNumber);
if(dynlen(systemNumber)!=0)
return systemNumber[1];
else
      {
      //return "Error";
      //DebugN("Component not found");
      }
}

void checkDpTimed(string dp,int sec)
{
  if(!dpExists(dp))
  {
    dpCreate(dp,"_TimedFunc");
    dpSet(dp+".syncTime",-1);
    dpSet(dp+".interval",sec);
    dpSet(dp+".time",0);
    
  }
}
