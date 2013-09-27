dyn_string sysNames;
dyn_dyn_string channels,lvchannels;
#uses "CMS_RPCfwHardwareCooling/CMS_RPCfwHardwareCooling.ctl"
main()
{
string psx = CMS_RPCCoolDSS_getComponent("Services");  
dyn_string dssFlag = dpNames(psx+"*UPS_Low_Voltage*");
  

dyn_string type = makeDynString("MAO","MAO","LV","LV","LBB","LBB");
  if(dynlen(sysNames)<1){
    
  dynAppend(sysNames, CMS_RPCCoolDSS_getComponent("BarrelLV"));
  dynAppend(sysNames,CMS_RPCCoolDSS_getComponent("EndcapLV"));
   
  
  for(int i =1;i<=dynlen(sysNames);i++)
  {
   CMS_RPCCoolDSS_getAllChannelsFromType(sysNames[i],type[i],channels[i]); 
   CMS_RPCCoolDSS_getAllChannelsFromType(sysNames[i],type[i+2],lvchannels[i]); 
   CMS_RPCCoolDSS_getAllChannelsFromType(sysNames[i],type[i+4],lvchannels[i]); 
  }

  dynSortAsc(channels[1]);
  dynSortAsc(channels[2]);
   dynSortAsc(lvchannels[1]);
  dynSortAsc(lvchannels[2]);
  }



//DebugTN("dss",dssFlag);
if(dynlen(dssFlag)==1)  
dpConnect("sendAction",dssFlag[1]+".value");  
  
  
}

void sendAction(string dpe, bool value){
  DebugN("in", value);

  if(value){
//DebugN(lvchannels[1],dynlen(lvchannels[1]));
  for(int k = 1;k<3;k++){
    for(int i =1;i<=dynlen(lvchannels[k]);i++){
    dpSet(lvchannels[k][i]+".settings.onOff",0);
    }
  }
  delay(280,0);
  bool onoff = false;
  for(int k = 1;k<3;k++){
    for(int i =1;i<=dynlen(lvchannels[k]);i++){
    dpGet(lvchannels[k][i]+".actual.isOn",onoff);
    if(onoff)break;
    }
    if(onoff)break;
  }
  if(!onoff){
    for(int k = 1;k<3;k++){
    for(int i =1;i<=dynlen(channels[k]);i++){
    dpSet(channels[k][i]+".settings.onOff",0);
    }
  }
  }else{
    delay(60,0);
    for(int k = 1;k<3;k++){
      for(int i =1;i<=dynlen(channels[k]);i++){
      dpSet(channels[k][i]+".settings.onOff",0);
      }
    }
  
  }
  
  
  }
  
  
 }

