/*
* Created by Giovanni Polese (Lappeenranta University of Technology
*	date:08/03/2007
*	LastChange:27/06/2011
*
*        Reset Alert script
*        Fixed bug MAO
         cdcs removed
         Added Vmon/Imon barrel and endcap avg
         
*/
#uses "CMS_RPCfwSupervisor/CMS_RPCfwSupervisor.ctl"
dyn_string sysNames,dps;
dyn_dyn_string channels;
dyn_float prevVmon;
main()
{

// Start the timed functions

checkDpTimed("RPCSupTimedCheck",240);
timedFunc("systemCheck","RPCSupTimedCheck");

checkDpTimed("RPCSupPercCheck",180);
timedFunc("statusRefresh","RPCSupPercCheck");

checkDpTimed("RPCSupSMSReset",1800);
timedFunc("resetSMSAlert","RPCSupSMSReset");

}



void resetSMSAlert()
{
  
  if(dynlen(dps)==0){
  dyn_string syss;
      
  //delay(1,0);
  syss[1] = RPCfwSupervisor_getSupervisorSys();
  syss[2] = RPCfwSupervisor_getComponent("BarrelLV");
  syss[3] = RPCfwSupervisor_getComponent("BarrelHV");
  
 syss[4] = RPCfwSupervisor_getComponent("EndcapLV");
  syss[5] = RPCfwSupervisor_getComponent("EndcapHV");
  syss[6] = RPCfwSupervisor_getComponent("Services");
 // DebugN(psx);
 
  if(syss[1]=="")
  {
  delay(4,0);
syss[1] = RPCfwSupervisor_getSupervisorSys();
  syss[2] = RPCfwSupervisor_getComponent("BarrelLV");
  syss[3] = RPCfwSupervisor_getComponent("BarrelHV");
  
 syss[4] = RPCfwSupervisor_getComponent("EndcapLV");
  syss[5] = RPCfwSupervisor_getComponent("EndcapHV");
  syss[6] = RPCfwSupervisor_getComponent("Services");    
    }
 

  dyn_string dpeAlarm;
  dynClear(dps);
 dyn_string alertTexts,dpelist;
 dyn_float limits; 
 dyn_string alertClasses,exInfo ;
  string alertPanel,color; dyn_string alertPanelParameters; string alertHelp;
bool isOn,active;




  for(int i =1;i<=dynlen(syss);i++){
    dpeAlarm = dpNames(syss[i]+"*","CMSfwAlertSystemSumAlerts");  

  for(int i =1 ;i<=dynlen(dpeAlarm);i++)
  {
      dynAppend(dps,dpeAlarm[i]+".Notification");

    fwAlertConfig_getSummary(dpeAlarm[i]+".Notification",isOn,alertTexts,dpelist,alertPanel,
                              alertPanelParameters, alertHelp,active,exInfo);
    dynAppend(dps,dpelist);
    }
  
  
  
  } 
  
}
  string alias;
  int actAlert = 0;
  bool ack;
  dyn_string exInfo;

  for(int i = 1; i<=dynlen(dps);i++)
  { 
    dpGet(dps[i]+":_alert_hdl.._ack_possible",ack);
  if(ack) fwAlertConfig_acknowledge(dps[i],exInfo);

     
  }
 
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


  xxdepei[1] = makeDynInt (1);

  xxdepei[2] = makeDynInt (0,DPEL_FLOAT);

  xxdepei[3] = makeDynInt (0,DPEL_FLOAT);

   n = dpTypeCreate(xxdepes,xxdepei); 

  }
}


void statusRefresh(){

dyn_string dpN = makeDynString("HVBarrelAvg","HVEndcapAvg");
bool stable = false;  
dyn_int value;

createTypePerc();
dyn_string type = makeDynString("HV","HV","LV","LV","LBB","LBB");
  if(dynlen(sysNames)<1){
    
  
  dynAppend(sysNames, RPCfwSupervisor_getComponent("BarrelHV"));
  dynAppend(sysNames, RPCfwSupervisor_getComponent("EndcapHV"));
  dynAppend(sysNames, RPCfwSupervisor_getComponent("BarrelLV"));
  dynAppend(sysNames,RPCfwSupervisor_getComponent("EndcapLV"));
  dynAppend(sysNames, sysNames[3]);
  dynAppend(sysNames, sysNames[4]);
  
  
  for(int i =1;i<=dynlen(sysNames);i++)
  {
   getAllChs(sysNames[i],type[i],channels[i]); 
  
  }

  }
  int on= 0,
    sum = 0,len;
  
  dyn_dyn_string tempChs;
//   DebugTN("1");
  for(int j = 1; j<=dynlen(type);j++){//  
  
    if(j % 2 == 1){
       on = 0;
       sum = 0; 
    }
  len =  dynlen(channels[j]);  
  sum = sum +len;
  if(len<500){  
  for(int i = 1;i<=len;i++){
    
        dpGet(channels[j][i]+".actual.status",value[i]);
        if(value[i]==1)
          on++;
    }
  }else{
    for(int i =1;i<=len;i++){
      int jj = i/500 + 1;
      dynAppend(tempChs[jj],channels[j][i]+".actual.status");    
    }
    for(int i = 1; i<=dynlen(tempChs);i++){
      for(int k = 1; k<=dynlen(tempChs[i]);k++){    
         dpGet(tempChs[i][k],value[k]);
        if(value[k]==1)
          on++;
      }
      delay(1,0);
      //DebugTN("late");
    }  

  }
  
  
  if(j % 2 ==0){
    write(j/2,on,sum);
    if((type[j]=="HV")&&(sum-on<10)) stable = true;
    
   }
//  DebugTN(sum,on);

}
  dyn_string exInfo;
  //refresh vmon /imon

  if(stable){//chamber not ramping
  dyn_int vmon;
  dyn_float imon;
  
  delay(2,0);
  for(int i = 1; i<=2;i++){
     for(int j = 1;j<=dynlen(channels[i]);j++){
    
        dpGet(channels[i][j]+".actual.vMon",vmon[j],
              channels[i][j]+".actual.iMon",imon[j]);
       
     }
     int avg = dynAvg(vmon);
    
     if(avg>8000){//I suppose that most of the chambers are on
     
       if(!dpExists(dpN[i]+"Vmon")){
        dpCreate(dpN[i]+"Vmon","RPCGlobalPerc");
        fwArchive_set(getSystemName()+dpN[i]+"Vmon.total","RDB-99) EVENT",DPATTR_ARCH_PROC_SIMPLESM,
                      DPATTR_TIME_AND_VALUE_SMOOTH,5,10000,exInfo);
      }
       if(!dpExists(dpN[i]+"Imon")){
        dpCreate(dpN[i]+"Imon","RPCGlobalPerc");
        fwArchive_set(getSystemName()+dpN[i]+"Imon.total","RDB-99) EVENT",DPATTR_ARCH_PROC_SIMPLESM,
                      DPATTR_TIME_AND_VALUE_SMOOTH,0.5,10000,exInfo);
      }
      
      dyn_int newvmon;
      for(int k = 1;k<=dynlen(vmon);k++)
      {
        if(vmon[k]>8000) dynAppend(newvmon,vmon[k]);

      }
      if(dynlen(prevVmon)==0)dynAppend(prevVmon,dynAvg(newvmon));//Add barrel first round
      else if (dynlen(prevVmon)==1)dynAppend(prevVmon,dynAvg(newvmon));//Add Endcap second round
      else if(((prevVmon[i]-dynAvg(newvmon))<20)&&((prevVmon[i]-dynAvg(newvmon))>-20)){
      dpSet(dpN[i]+"Vmon.total",dynAvg(newvmon), dpN[i]+"Imon.total",dynAvg(imon));
      prevVmon[i] = dynAvg(newvmon);    
      }else prevVmon[i] = dynAvg(newvmon);    
        
    }else if((avg>6800)&&(avg<7040)){
 
      if(!dpExists(dpN[i]+"Imon7000")){
          dpCreate(dpN[i]+"Imon7000","RPCGlobalPerc");
          fwArchive_set(getSystemName()+dpN[i]+"Imon7000.total","RDB-99) EVENT",DPATTR_ARCH_PROC_SIMPLESM,
                        DPATTR_TIME_AND_VALUE_SMOOTH,3,10000,exInfo);
        }
      if(!dpExists(dpN[i]+"NumCh7000")){
          dpCreate(dpN[i]+"NumCh7000","RPCGlobalPerc");
          fwArchive_set(getSystemName()+dpN[i]+"NumCh7000.total","RDB-99) EVENT",DPATTR_ARCH_PROC_SIMPLESM,
                        DPATTR_TIME_AND_VALUE_SMOOTH,1,10000,exInfo);
        }
      
      dyn_int newvmon;
      dyn_float newImon;
      for(int k = 1;k<=dynlen(vmon);k++)
      {
        if((vmon[k]>6980)&&(avg<7040)) {
          dynAppend(newvmon,vmon[k]);
          dynAppend(newImon,imon[k]);
          }

      }
      if(dynlen(prevVmon)==0)dynAppend(prevVmon,dynAvg(newvmon));//Add barrel first round
      else if (dynlen(prevVmon)==1)dynAppend(prevVmon,dynAvg(newvmon));//Add Endcap second round
      else if(((prevVmon[i]-dynAvg(newvmon))<20)&&((prevVmon[i]-dynAvg(newvmon))>-20)){
      
      string sNewImon = dynAvg(newImon);
      float fNewImon = substr(sNewImon,0,strpos(sNewImon,".")+3);
      dpSet(dpN[i]+"Imon7000.total",fNewImon,dpN[i]+"NumCh7000.total",dynlen(newImon));
      prevVmon[i] = dynAvg(newvmon);    
      }else prevVmon[i] = dynAvg(newvmon);  
    
    
    }
   dynClear(vmon);
   dynClear(imon);
   delay(2,0);
  }
 }

}

void write(int pos, int ok, int total){
dyn_string vect = makeDynString("HVperc","LVperc","LBBperc");

// DebugFN(pos);
// DebugN(vect[pos]);
if(!dpExists(vect[pos]))
  dpCreate(vect[pos],"RPCGlobalPerc");

dpSet(vect[pos]+".ok",ok,vect[pos]+".total",total);

}

void getAllGasChs(string sys,dyn_string & channels){
  
  channels = dpNames("*"+sys+"W*","RPCGasChannel");
  
  }

void getAllFebs(string sys,dyn_string & channels){
  
  dyn_string names, geo = dpNames("*"+sys+"Feb_W*","RpcFebGeo");
  //DebugN()
  string febid;
  for(int i= 1;i<=dynlen(geo);i++){
    
    dpGet(geo[i]+".febIds",febid);        
    //DebugN(geo[i]);    
    names = strsplit(febid,";");
    for(int y = 1;y<=dynlen(names);y++)
      dynAppend(channels,sys+"Feb"+names[y]);
    
    }

  }

void getAllChs(string sys,string type, dyn_string & channels)
{
 
  string alias;
  dyn_string exInfo,nodes, children;
  fwNode_getNodes(sys, fwDevice_LOGICAL, nodes, exInfo);
  // DebugN(nodes);
     for(int i = 1; i <= dynlen(nodes); i++)
      {
        alias = dpGetAlias(nodes[i] + ".");
	//DebugN(nodes[i], alias);
	nodes[i] = sys + alias;
      
      if(strpos(nodes[i],type)>1)  
        fwDevice_getChildren(nodes[i], fwDevice_LOGICAL, children, exInfo);		                        
      
      }
    // DebugN(children);
     for(int i = 1; i<=dynlen(children);i++)
     {
     //if((strpos(children[i],search)>1))  
       dynAppend(channels,sys + fwDU_getPhysicalName(children[i]));      
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

void systemCheck()
{
 dyn_string exInfo;
 
 /// Legenda:
 //  1.database error
 
 dyn_int vector = makeDynInt(0,0,0,0,0,0,0,0); 
 dyn_string svector = makeDynString("rdb error on sys 213","dist Manager off on sys 213","lost communication with 210",
                                   "lost communication with 211","lost communication with 212",
                                   "lost communication with 214","lost communication with 215",
                                   "lost communication with 19");
 
 if(!dpExists(getSystemName()+"RPCSup_Check"))
 {
  
  dyn_string exceptionInfo,alertTexts = makeDynString("OK", "System Error") ;
  dyn_float limits; 
  dyn_string alertClasses = makeDynString("", "_fwWarningAck.");
  string alertPanel; dyn_string alertPanelParameters,summary; string alertHelp;
  limits = makeDynFloat( 1 );
  dpCreate("RPCSup_Check","RPCUtils"); 
  fwArchive_set(getSystemName()+"RPCSup_Check.fvalue","RDB-99) EVENT",DPATTR_ARCH_PROC_SIMPLESM,DPATTR_COMPARE_OLD_NEW,0,0,exInfo);
  fwAlertConfig_set(getSystemName()+"RPCSup_Check.fvalue",DPCONFIG_ALERT_NONBINARYSIGNAL ,alertTexts,limits, alertClasses,summary,alertPanel,alertPanelParameters,
             alertHelp,exceptionInfo);
 }
 string info;
 //************* Check connections for RDB
 string result;
 dyn_string channels = makeDynString("_RDBArchive.dbConnection.connected","_Connections.Dist.ManNums");
 dyn_string values = makeDynString("RDB error");
 for(int i = 1; i<=dynlen(channels);i++)
 {
   dpGet(getSystemName()+channels[i],result);
   //DebugN(result);
   if((result=="")||(result == "FALSE"))
   {
     vector[i]=1;
   }
   result="";
 }
 // vector dim = 2;
 
 //****************** Check dist connection with all the other subsistem
 dyn_string distNum = makeDynString("210","211","212","214","215","19");
 dyn_string val;
 dpGet(getSystemName()+"_DistConnections.Dist.ManNums",val);
   for(int j = 1;j<=dynlen(distNum);j++)
   { 
    for(int i =1 ; i<=dynlen(val);i++)
     {  
      if(distNum[j]!=val[i])
      {
       vector[2+j]=1;
     
       }
      else
      {
        //DebugN(val[i]);
        vector[2+j]=0;
        break;
        }
     } 
   }
 

 //DebugN(total);
 
  
 // write analisys results
 
 float total = 0;
 
 for(int i = 1; i<=dynlen(vector);i++ )
 {
   if(vector[i] == 1)
   {
     total = total + pow(2,i);
     info = info + svector[i]+" ; ";
     }
   }
// DebugN(total,vector);
 dpSet(getSystemName()+"RPCSup_Check.fvalue",total);
 dpSet(getSystemName()+"RPCSup_Check.svalue",info);
   
   
}
