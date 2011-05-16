

main() {

// Start the timed functions

checkDpTimed("RPC_GGM_cron",240);
timedFunc("GGMsystemCheck","RPC_GGM_cron");

checkDpTimed("RPC_GGM_wpcron",900);
timedFunc("GGMsystemCheckWP","RPC_GGM_wpcron");

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
   //volt = hv_trg0*(pres/965);

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
   //volt = hv_trg1*(pres/965);

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
   //volt = hv_trg2*(pres/965);

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
   //volt = hv_trg3*(pres/965);

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
   //volt = hv1*(pres/965);

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
   //volt = hv2*(pres/965);

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
   //volt = hv3*(pres/965);

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
   //volt = hv4*(pres/965);
   
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
   //volt = hv5*(pres/965);

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
   //volt = hv6*(pres/965);

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
   //volt = hv7*(pres/965);

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
   //volt = hv8*(pres/965);

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

void GGMsystemCheckWP() {

 float wpc3, wpc4, wpc5, wpc6, wpc7, wpc8, charge1, charge2, charge3, charge4, charge5, charge6, charge7, charge8;
 float ava1, ava2, ava3, ava4, ava5, ava6, ava7, ava8;
 float str1, str2, str3, str4, str5, str6, str7, str8;
 float rat1, rat2, rat3, rat4, rat5, rat6, rat7, rat8;
 float effi1, effi2, effi3, effi4, effi5, effi6, effi7, effi8; 
 float wpa3, wpa4, wpa5, wpa6, wpa7, wpa8;
 float wps3, wps4, wps5, wps6, wps7, wps8;
 float wpe3, wpe4, wpe5, wpe6, wpe7, wpe8;
 float wpr3, wpr4, wpr5, wpr6, wpr7, wpr8;
 int rc;
 
 rc=dpGet(RPCGGM_getSysName()+"rpc_ggm_ch01.daq.charge",charge1);
 rc=dpGet(RPCGGM_getSysName()+"rpc_ggm_ch02.daq.charge",charge2);
 rc=dpGet(RPCGGM_getSysName()+"rpc_ggm_ch03.daq.charge",charge3);
 rc=dpGet(RPCGGM_getSysName()+"rpc_ggm_ch04.daq.charge",charge4);
 rc=dpGet(RPCGGM_getSysName()+"rpc_ggm_ch05.daq.charge",charge5);
 rc=dpGet(RPCGGM_getSysName()+"rpc_ggm_ch06.daq.charge",charge6);
 rc=dpGet(RPCGGM_getSysName()+"rpc_ggm_ch07.daq.charge",charge7);
 rc=dpGet(RPCGGM_getSysName()+"rpc_ggm_ch08.daq.charge",charge8);

 rc=dpGet(RPCGGM_getSysName()+"rpc_ggm_ch01.daq.avalanche",ava1);
 rc=dpGet(RPCGGM_getSysName()+"rpc_ggm_ch02.daq.avalanche",ava2);
 rc=dpGet(RPCGGM_getSysName()+"rpc_ggm_ch03.daq.avalanche",ava3);
 rc=dpGet(RPCGGM_getSysName()+"rpc_ggm_ch04.daq.avalanche",ava4);
 rc=dpGet(RPCGGM_getSysName()+"rpc_ggm_ch05.daq.avalanche",ava5);
 rc=dpGet(RPCGGM_getSysName()+"rpc_ggm_ch06.daq.avalanche",ava6);
 rc=dpGet(RPCGGM_getSysName()+"rpc_ggm_ch07.daq.avalanche",ava7);
 rc=dpGet(RPCGGM_getSysName()+"rpc_ggm_ch08.daq.avalanche",ava8);

 rc=dpGet(RPCGGM_getSysName()+"rpc_ggm_ch01.daq.streamer",str1);
 rc=dpGet(RPCGGM_getSysName()+"rpc_ggm_ch02.daq.streamer",str2);
 rc=dpGet(RPCGGM_getSysName()+"rpc_ggm_ch03.daq.streamer",str3);
 rc=dpGet(RPCGGM_getSysName()+"rpc_ggm_ch04.daq.streamer",str4);
 rc=dpGet(RPCGGM_getSysName()+"rpc_ggm_ch05.daq.streamer",str5);
 rc=dpGet(RPCGGM_getSysName()+"rpc_ggm_ch06.daq.streamer",str6);
 rc=dpGet(RPCGGM_getSysName()+"rpc_ggm_ch07.daq.streamer",str7);
 rc=dpGet(RPCGGM_getSysName()+"rpc_ggm_ch08.daq.streamer",str8);

 rc=dpGet(RPCGGM_getSysName()+"rpc_ggm_ch01.daq.ratio",rat1);
 rc=dpGet(RPCGGM_getSysName()+"rpc_ggm_ch02.daq.ratio",rat2);
 rc=dpGet(RPCGGM_getSysName()+"rpc_ggm_ch03.daq.ratio",rat3);
 rc=dpGet(RPCGGM_getSysName()+"rpc_ggm_ch04.daq.ratio",rat4);
 rc=dpGet(RPCGGM_getSysName()+"rpc_ggm_ch05.daq.ratio",rat5);
 rc=dpGet(RPCGGM_getSysName()+"rpc_ggm_ch06.daq.ratio",rat6);
 rc=dpGet(RPCGGM_getSysName()+"rpc_ggm_ch07.daq.ratio",rat7);
 rc=dpGet(RPCGGM_getSysName()+"rpc_ggm_ch08.daq.ratio",rat8);

 rc=dpGet(RPCGGM_getSysName()+"rpc_ggm_ch01.daq.efficiency",effi1);
 rc=dpGet(RPCGGM_getSysName()+"rpc_ggm_ch02.daq.efficiency",effi2);
 rc=dpGet(RPCGGM_getSysName()+"rpc_ggm_ch03.daq.efficiency",effi3);
 rc=dpGet(RPCGGM_getSysName()+"rpc_ggm_ch04.daq.efficiency",effi4);
 rc=dpGet(RPCGGM_getSysName()+"rpc_ggm_ch05.daq.efficiency",effi5);
 rc=dpGet(RPCGGM_getSysName()+"rpc_ggm_ch06.daq.efficiency",effi6);
 rc=dpGet(RPCGGM_getSysName()+"rpc_ggm_ch07.daq.efficiency",effi7);
 rc=dpGet(RPCGGM_getSysName()+"rpc_ggm_ch08.daq.efficiency",effi8);

 //CHARGE
 if (charge2>0) { 
   wpc3 = charge3 / charge2;
   wpc4 = charge4 / charge2;
   wpc5 = charge5 / charge2;
   wpc6 = charge6 / charge2;
   wpc7 = charge7 / charge2;
   wpc8 = charge8 / charge2;
 }
 else {
   wpc3 = 0;
   wpc4 = 0;
   wpc5 = 0;
   wpc6 = 0;
   wpc7 = 0;
   wpc8 = 0;  
 } 
 
 dpSetWait(RPCGGM_getSysName()+"rpc_ggm_ch03.daq.WP.charge", wpc3);
 dpSetWait(RPCGGM_getSysName()+"rpc_ggm_ch04.daq.WP.charge", wpc4);
 dpSetWait(RPCGGM_getSysName()+"rpc_ggm_ch05.daq.WP.charge", wpc5);
 dpSetWait(RPCGGM_getSysName()+"rpc_ggm_ch06.daq.WP.charge", wpc6);
 dpSetWait(RPCGGM_getSysName()+"rpc_ggm_ch07.daq.WP.charge", wpc7);
 dpSetWait(RPCGGM_getSysName()+"rpc_ggm_ch08.daq.WP.charge", wpc8);

 //AVALANCHE
 if (ava2>0) { 
   wpa3 = ava3 / ava2;
   wpa4 = ava4 / ava2;
   wpa5 = ava5 / ava2;
   wpa6 = ava6 / ava2;
   wpa7 = ava7 / ava2;
   wpa8 = ava8 / ava2;
 }
 else {
   wpa3 = 0;
   wpa4 = 0;
   wpa5 = 0;
   wpa6 = 0;
   wpa7 = 0;
   wpa8 = 0;  
 } 

 dpSetWait(RPCGGM_getSysName()+"rpc_ggm_ch03.daq.WP.avalanche", wpa3);
 dpSetWait(RPCGGM_getSysName()+"rpc_ggm_ch04.daq.WP.avalanche", wpa4);
 dpSetWait(RPCGGM_getSysName()+"rpc_ggm_ch05.daq.WP.avalanche", wpa5);
 dpSetWait(RPCGGM_getSysName()+"rpc_ggm_ch06.daq.WP.avalanche", wpa6);
 dpSetWait(RPCGGM_getSysName()+"rpc_ggm_ch07.daq.WP.avalanche", wpa7);
 dpSetWait(RPCGGM_getSysName()+"rpc_ggm_ch08.daq.WP.avalanche", wpa8);

 //STREAMER
 if (str2>0) { 
   wps3 = str3 / str2;
   wps4 = str4 / str2;
   wps5 = str5 / str2;
   wps6 = str6 / str2;
   wps7 = str7 / str2;
   wps8 = str8 / str2;
 }
 else {
   wps3 = 0;
   wps4 = 0;
   wps5 = 0;
   wps6 = 0;
   wps7 = 0;
   wps8 = 0;  
 } 
 
 dpSetWait(RPCGGM_getSysName()+"rpc_ggm_ch03.daq.WP.streamer", wps3);
 dpSetWait(RPCGGM_getSysName()+"rpc_ggm_ch04.daq.WP.streamer", wps4);
 dpSetWait(RPCGGM_getSysName()+"rpc_ggm_ch05.daq.WP.streamer", wps5);
 dpSetWait(RPCGGM_getSysName()+"rpc_ggm_ch06.daq.WP.streamer", wps6);
 dpSetWait(RPCGGM_getSysName()+"rpc_ggm_ch07.daq.WP.streamer", wps7);
 dpSetWait(RPCGGM_getSysName()+"rpc_ggm_ch08.daq.WP.streamer", wps8);

 //STREAMER AV RATIO
 if (rat2>0) { 
   wpr3 = rat3 / rat2;
   wpr4 = rat4 / rat2;
   wpr5 = rat5 / rat2;
   wpr6 = rat6 / rat2;
   wpr7 = rat7 / rat2;
   wpr8 = rat8 / rat2;
 }
 else {
   wpr3 = 0;
   wpr4 = 0;
   wpr5 = 0;
   wpr6 = 0;
   wpr7 = 0;
   wpr8 = 0;  
 }
 dpSetWait(RPCGGM_getSysName()+"rpc_ggm_ch03.daq.WP.ratio", wpr3);
 dpSetWait(RPCGGM_getSysName()+"rpc_ggm_ch04.daq.WP.ratio", wpr4);
 dpSetWait(RPCGGM_getSysName()+"rpc_ggm_ch05.daq.WP.ratio", wpr5);
 dpSetWait(RPCGGM_getSysName()+"rpc_ggm_ch06.daq.WP.ratio", wpr6);
 dpSetWait(RPCGGM_getSysName()+"rpc_ggm_ch07.daq.WP.ratio", wpr7);
 dpSetWait(RPCGGM_getSysName()+"rpc_ggm_ch08.daq.WP.ratio", wpr8);

 //EFFICIENCY
 if (effi2>0) { 
   wpe3 = effi3 / effi2;
   wpe4 = effi4 / effi2;
   wpe5 = effi5 / effi2;
   wpe6 = effi6 / effi2;
   wpe7 = effi7 / effi2;
   wpe8 = effi8 / effi2;
 }
 else {
   wpe3 = 0;
   wpe4 = 0;
   wpe5 = 0;
   wpe6 = 0;
   wpe7 = 0;
   wpe8 = 0;  
 }
 dpSetWait(RPCGGM_getSysName()+"rpc_ggm_ch03.daq.WP.efficiency", wpe3);
 dpSetWait(RPCGGM_getSysName()+"rpc_ggm_ch04.daq.WP.efficiency", wpe4);
 dpSetWait(RPCGGM_getSysName()+"rpc_ggm_ch05.daq.WP.efficiency", wpe5);
 dpSetWait(RPCGGM_getSysName()+"rpc_ggm_ch06.daq.WP.efficiency", wpe6);
 dpSetWait(RPCGGM_getSysName()+"rpc_ggm_ch07.daq.WP.efficiency", wpe7);
 dpSetWait(RPCGGM_getSysName()+"rpc_ggm_ch08.daq.WP.efficiency", wpe8);
 
}

