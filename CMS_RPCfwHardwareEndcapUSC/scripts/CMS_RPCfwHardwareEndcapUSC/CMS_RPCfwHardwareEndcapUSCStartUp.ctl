/// Version 1.7 date: 15/10/09

dyn_string chanToCheck;
dyn_dyn_string chStatus;
int dim;

main()
{

 dyn_string nodes,exInfo;
 string val;
 
dyn_string chs = dpAliases("*RPCUSEndcap/HV/*","*");
   int step = 0;
   dim = 1;
   for (int i = 1; i<=dynlen(chs);i++)
   {
     step = (i % 6) + 1;
     dynAppend(chStatus[step],fwDU_getPhysicalName(chs[i]));
     
     }
   
  
  if(!dpExists("USCEFSMtime"))
   {
    dpCreate("USCEFSMtime","RPCUtils");
    dpSet("USCEFSMtime.fvalue",40);      
    }
  int refTime;   
  dpGet("USCEFSMtime.fvalue",refTime);
  checkDpTimed("USCEFSMRefresh",refTime);
  timedFunc("FSMRefresh","USCEFSMRefresh"); 
 
 
    checkDpTimed("USCTimedCheck",120);    
    timedFunc("systemCheck","USCTimedCheck");    
    checkDpTimed("USCCurrentCheck",600);    
    timedFunc("currentCheck","USCCurrentCheck");    




dyn_string checkOPC = dpNames("caenHV*","RPCUtils"); 
 //DebugN(checkOPC);
 //_OPCEHVProtection_Enabled = true;

 if(dynlen(checkOPC)>0)
 {
   dpConnect("turnOPCOff",checkOPC[1]+".svalue");
 }
     
}

void turnOPCOff(string dpe, string value){

 
    if(value=="Ko"){

    dpSet(getSystemName()+"OPC_Conf_General.regInput.idOperation:_original.._value", 5);
  
    time t;
    dyn_string dpNamesWait, dpNamesReturn;
    dyn_anytype conditions, returnValues;
    int status;
 
    dpNamesWait = makeDynString(getSystemName()+"OPC_Conf_General.regInput.idOperation:_original.._value");
    conditions[1] = 0;
    dpNamesReturn = makeDynString(getSystemName()+"OPC_Conf_General.regInput.idOperation:_online.._value" );
    t = 30;

    // Wait until the operation is completed - code 0
    status = dpWaitForValue( dpNamesWait, conditions, dpNamesReturn, returnValues, t );  
  
  }
 
}


void FSMRefresh(){
  
  dyn_string chs = chStatus[dim];
  int status,v0,vmon,i0,ri1;
  time now = getCurrentTime();
  time last;
  int tdiff;
  string alias, state,cu;
  string sys =getSystemName(); 
  dyn_string exInfo;
  for(int i = 1;i<=dynlen(chs);i++){
    
    dpGet(sys+chs[i]+".settings.v0:_original.._stime",last);
    tdiff = now -last;
    if(tdiff>40){    
    dpGet(sys+chs[i]+".actual.status",status,
          sys+chs[i]+".actual.vMon",vmon,
          sys+chs[i]+".settings.v0",v0,
          sys+chs[i]+".readBackSettings.i1",ri1,
          sys+chs[i]+".readBackSettings.i0",i0
          );
    
    if((status<2)&&(v0-vmon < 30)&&(v0-vmon > -30)){
      //
     alias = fwDU_getLogicalName(sys+chs[i]);    
     fwTree_getCUName(alias, cu, exInfo);
     if(dynlen(exInfo)==0){
      fwDU_getState(cu,alias,state);
      //
       if(((state == "ON")&&(vmon <8800))||((state != "ON")&&(vmon >8800))||(i0>ri1))
       dpSet(sys+chs[i]+".actual.status",status);
      }
    }
    }
    }
  if(dim == 6)
    dim = 1;
  else
    dim ++;
  }


void systemCheck()
{
// checkExists();
 dyn_string exInfo;
 int rint = 0;
  if(!dpExists(getSystemName()+"RPCCheckUSCE"))
 {
  dyn_string alertTexts = makeDynString( "Ok", "Not Ok");
  dyn_float limits = (1); 
  dyn_string alertClasses = makeDynString( "" , "_fwErrorAck.");
  string alertPanel,summary,dp; dyn_string alertPanelParameters; string alertHelp;

   
 dpCreate("RPCCheckUSCE","RPCUtils");
 dp = getSystemName()+"RPCCheckUSCE.fvalue";
 fwArchive_set(dp,"RDB-99) EVENT",DPATTR_ARCH_PROC_SIMPLESM,DPATTR_COMPARE_OLD_NEW,0,0,exInfo);
 fwAlertConfig_set(dp,DPCONFIG_ALERT_NONBINARYSIGNAL ,alertTexts,limits, alertClasses,summary,alertPanel,alertPanelParameters,
             alertHelp,exInfo);
 fwAlertConfig_activate(dp,exInfo);
 }

 
 string info;
 // Check connections
 string result;
 dyn_string channels = makeDynString("_RDBArchive.dbConnection.connected","_CAENOPCServer.Connected");
 dyn_string values = makeDynString("RDB error","OPC Error");
 for(int i = 1; i<=dynlen(channels);i++)
 {
   dpGet(getSystemName()+channels[i],result);
   if(!result)
   {
     info = info + values[i] + ";";
       rint = rint + (i*2);
   }
 }

 
 
  // check fan status
time refresh,now = getCurrentTime();
 dyn_string sy1527 = dpNames("*HV02*","FwCaenCrateSY1527");
 string mainf;
 for(int i = 1 ; i<=dynlen(sy1527);i++)
 {
   dpGet(sy1527[i]+".FanStatus.FanStat:_original.._stime",refresh);
  //DebugN(refresh);
 if((now - refresh)>60)
   {
    info = info + "Fan stopped;";
    rint = rint + 8;
    }
    mainf = sy1527[i];
  }
 
 //check opc control if exists
 string op;
 dyn_string checkOPC = dpNames("caenHVE*","RPCUtils"); 
 //DebugN(checkOPC);
 if(dynlen(checkOPC)>0)
 {
   dpGet(checkOPC[1]+".svalue",op);
   if(op != "Ok")
   {
    info = info + "OPC server KO;";
    rint = rint + 16;
 if(strlen(mainf)>0)   dpSet(mainf+".Information.ModelName","Ko"); 
    }else if(strlen(mainf)>0)   
      {
      dpGet(mainf+".Information.ModelName",op);
      if(op == "Ko")
      dpSet(mainf+".Information.ModelName","SY1527");
      }
    
      
   }
 // fsm heartbeat
//   string sval;
//   dpGet(getSystemName()+"RPCCheckUSCE.svalue",sval);
//    if(strpos(sval,"fsmOk")<0)
//     {
//      rint = rint + 32;
//      info = info + " FSM not responding;";
//      }
      
       
 // write analisys results
 dpSet(getSystemName()+"RPCCheckUSCE.fvalue",rint);
 dpSet(getSystemName()+"RPCCheckUSCE.svalue",info);
//refresh FSM
 string infoSerial;
    dpGet(sy1527+".Information.ModelName",infoSerial);
   dpSet(sy1527+".Information.ModelName",infoSerial);
   
   
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

void currentCheck(){  
  float value;
  dyn_float sum ;
  dyn_int n;
  int pos;  
  if(dynlen(chanToCheck)==0)
    chanToCheck = dpAliases("*RPCUSEndcap/HV/*","*");  
  dyn_string wheels = makeDynString("EP3","EP2","EP1","EN1","EN2","EN3");  
  for(int i = 1;i<=dynlen(wheels);i++)
  {
    n[i]= 0;
    sum[i]= 0;
    }
  for(int i = 1; i<=dynlen(chanToCheck);i++)
  {
    pos = strpos(chanToCheck[i],"_E");
    pos = dynContains(wheels,substr(chanToCheck[i],pos+1,3));
    dpGet(getSystemName()+ fwDU_getPhysicalName(chanToCheck[i]) + ".actual.iMon",value);
    if(value > 0)
    {
     // DebugN(chanToCheck[i],value);
      sum[pos] = sum[pos] + value;
      n[pos]++;
      }
    }
  
  for(int i = 1;i<=dynlen(wheels);i++)
  {
  if(n[i]!=0)
  {
    dpSet(getSystemName() + "globImon"+wheels[i]+".total", sum[i]);
    dpSet(getSystemName() + "globImon"+wheels[i]+".averange", sum[i] / n[i]);
  }
  }
}


