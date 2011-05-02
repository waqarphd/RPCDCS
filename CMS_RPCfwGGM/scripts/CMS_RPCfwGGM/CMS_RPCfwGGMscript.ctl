

main() {

// Start the timed functions

checkDpTimed("RPC_GGM_cron",240);
timedFunc("GGMsystemCheck","RPC_GGM_cron");

}

void GGMsystemCheck() {
 
 float temp, ;
 int pres, hv1, volt, auto3, auto4, auto5, auto6, auto7, auto8;
 int hv3, hv4, hv5, hv6, hv7, hv8, rc;
     
 rc=dpGet(RPCGGM_getSysName()+"sensors.temperature_box",temp);  
 rc=dpGet(RPCGGM_getSysName()+"sensors.pressure_box",pres);  

 rc=dpGet(RPCGGM_getSysName()+"rpc_ggm_ch03.hv",hv3);  
 rc=dpGet(RPCGGM_getSysName()+"rpc_ggm_ch04.hv",hv4);  
 rc=dpGet(RPCGGM_getSysName()+"rpc_ggm_ch05.hv",hv5);  
 rc=dpGet(RPCGGM_getSysName()+"rpc_ggm_ch06.hv",hv6);  
 rc=dpGet(RPCGGM_getSysName()+"rpc_ggm_ch07.hv",hv7);  
 rc=dpGet(RPCGGM_getSysName()+"rpc_ggm_ch08.hv",hv8);  

 rc=dpGet(RPCGGM_getSysName()+"rpc_ggm_ch03.autohv",auto3);  
 rc=dpGet(RPCGGM_getSysName()+"rpc_ggm_ch04.autohv",auto4);  
 rc=dpGet(RPCGGM_getSysName()+"rpc_ggm_ch05.autohv",auto5);  
 rc=dpGet(RPCGGM_getSysName()+"rpc_ggm_ch06.autohv",auto6);  
 rc=dpGet(RPCGGM_getSysName()+"rpc_ggm_ch07.autohv",auto7);  
 rc=dpGet(RPCGGM_getSysName()+"rpc_ggm_ch08.autohv",auto8);  


 if (auto3==1) {
   volt = hv3*(1010/pres)+((temp+273)/293);
   if (volt>8000) {
     if (volt<10250) {
       dpSetWait(RPCGGM_getSysName()+"CAEN/GGM/board00/channel004.settings.v0", volt);
     }
   }
 }
 
 if (auto4==1) {
   volt = hv4*(1010/pres)+((temp+273)/293);
   if (volt>8000) {
     if (volt<10250) {
       dpSetWait(RPCGGM_getSysName()+"CAEN/GGM/board00/channel005.settings.v0", volt);
     }
   }
 }
 
 if (auto5==1) { 
   volt = hv5*(1010/pres)+((temp+273)/293);
   if (volt>8000) {
     if (volt<10250) {
       dpSetWait(RPCGGM_getSysName()+"CAEN/GGM/board02/channel000.settings.v0", volt);
     }
   }
 }
 
 if (auto6==1) {
   volt = hv6*(1010/pres)+((temp+273)/293);
   if (volt>8000) {
     if (volt<10250) {
       dpSetWait(RPCGGM_getSysName()+"CAEN/GGM/board02/channel001.settings.v0", volt);
     }
   }
 }
 
 if (auto7==1) {
   volt = hv7*(1010/pres)+((temp+273)/293);
   if (volt>8000) {
     if (volt<10250) {
       dpSetWait(RPCGGM_getSysName()+"CAEN/GGM/board02/channel002.settings.v0", volt);
     }
   }
 }
 
 if (auto8==1) {
   volt = hv8*(1010/pres)+((temp+273)/293);
   if (volt>8000) {
     if (volt<10250) {
       dpSetWait(RPCGGM_getSysName()+"CAEN/GGM/board02/channel003.settings.v0", volt); 
     }
   }
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
  }
}
