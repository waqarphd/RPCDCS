/*********************

 UXC StartUp script
 Version: 1.4
 
 
**********************/ 
dyn_string chanToCheck;
main()
{
 dyn_string nodes,exInfo;
 string val;

 // 2. Start the Time Functions

  checkDpTimed("UXCTimedCheck",120);
  timedFunc("systemCheck","UXCTimedCheck");
  
  checkDpTimed("UXCTempGlob",300);
  timedFunc("TempCheck","UXCTempGlob");

//protection on OPC 
  
  dyn_string checkOPC = dpNames("caenLV*","RPCUtils"); 
 //DebugN(checkOPC);
// _OPCProtection_Enabled = true;

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





void TempCheck(){  
  float value;
  dyn_float sum ;
  dyn_int n;
  int pos; 
  dyn_string wheels = makeDynString("WM2","WM1","W00","WP1","WP2");  
  
  if(dynlen(chanToCheck)==0)
  {
    chanToCheck = dpAliases("*UXBarrel/T/*","*");
    globalTemperature();
    
  }
 
  for(int i = 1;i<=dynlen(wheels);i++)
  {
    n[i]= 0;
    sum[i]= 0;
    }
  for(int i = 1; i<=dynlen(chanToCheck);i++)
  {
    pos = strpos(chanToCheck[i],"_W");
    pos = dynContains(wheels,substr(chanToCheck[i],pos+1,3));
    dpGet(getSystemName()+ fwDU_getPhysicalName(chanToCheck[i]) + ".actual.temperature",value);
    if(value > 0)
    {
      sum[pos] = sum[pos] + value;
      n[pos]++;
      }
    }
  
  for(int i = 1;i<=dynlen(wheels);i++)
  {
    if(n[i]!=0)
    {
      dpSet(getSystemName() + "globTmon"+wheels[i]+".total", sum[i]);
      dpSet(getSystemName() + "globTmon"+wheels[i]+".averange", sum[i] / n[i]);
    }
  }
}
void globalTemperature() 

{ 

dyn_string types; 

types = dpTypes("RpcGlobalTValue"); 

//DebugN(types); 

if(dynlen(types)<1) CreateTypesGenTemp(); 

dyn_string Discs = makeDynString("WM2","WM1","W00","WP1","WP2");  




dyn_string exceptionInfo; 

for(int i = 1; i<=dynlen(Discs);i++) 

{ 

  if(!dpExists("globTmon"+Discs[i])){ 

dpCreate("globTmon"+Discs[i],"RpcGlobalTValue"); 

fwArchive_setMultiple("globTmon"+Discs[i]+".averange" , "RDB-99) EVENT",DPATTR_ARCH_PROC_SIMPLESM,DPATTR_TIME_AND_VALUE_SMOOTH,

0.3,2000,exceptionInfo); 

fwArchive_setMultiple("globTmon"+Discs[i]+".total" , "RDB-99) EVENT",DPATTR_ARCH_PROC_SIMPLESM,DPATTR_TIME_AND_VALUE_SMOOTH,

0.3,2000,exceptionInfo); 
}

} 



} 


void CreateTypesGenTemp()

{

dyn_string types;

//types = dpTypes("RpcGlobalValue");

//DebugN(types);

if(dynlen(types)<1) 

{

int n;

dyn_dyn_string xxdepes;

dyn_dyn_int xxdepei;

// Create the data type

xxdepes[1] = makeDynString ("RpcGlobalTValue","");

xxdepes[2] = makeDynString ("","averange");

xxdepes[3] = makeDynString ("","total");


xxdepei[1] = makeDynInt (1);

xxdepei[2] = makeDynInt (0,DPEL_FLOAT);

xxdepei[3] = makeDynInt (0,DPEL_FLOAT);

// Create the datapoint type

n = dpTypeCreate(xxdepes,xxdepei);



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
//  DebugN("create");
  }

void systemCheck()
{
 //checkExists();
 dyn_string exInfo;
 int rint = 0;
 if(!dpExists(getSystemName()+"RPCCheckUXC"))
 {
  dyn_string alertTexts = makeDynString( "Ok", "Not Ok");
  dyn_float limits = (1); 
  dyn_string alertClasses = makeDynString( "" , "_fwErrorAck.");
  string alertPanel,summary,dp; dyn_string alertPanelParameters; string alertHelp;

   
  dpCreate("RPCCheckUXC","RPCUtils");
 dp = getSystemName()+"RPCCheckUXC.fvalue";
 fwArchive_set(dp,"RDB-99) EVENT",DPATTR_ARCH_PROC_SIMPLESM,DPATTR_COMPARE_OLD_NEW,0,0,exInfo);
 fwAlertConfig_set(dp,DPCONFIG_ALERT_NONBINARYSIGNAL ,alertTexts,limits, alertClasses,summary,alertPanel,alertPanelParameters,
             alertHelp,exInfo);
 fwAlertConfig_activate(dp,exInfo);
 }
 string info;
 //************* Check connections for RDB and CAEN and then the fans status
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
 dyn_string sy1527 = dpNames("*rb1527lv*","FwCaenCrateSY1527");
 string mainf;
 for(int i = 1 ; i<=dynlen(sy1527);i++)
 {
   dpGet(sy1527[i]+".FanStatus.FanStat:_original.._stime",refresh);
  //DebugN(refresh);
 if((now - refresh)>120)
   {
    info = info + "Fan stopped;";
    rint = rint + 8;
    }
    mainf = sy1527[i];
  }
 
 //check opc control if exists
 string op;
 dyn_string checkOPC = dpNames("caenLV*","RPCUtils"); 
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
 
 
 // write analisys results
 dpSet(getSystemName()+"RPCCheckUXC.fvalue",rint);
 dpSet(getSystemName()+"RPCCheckUXC.svalue",info);
   
   
 }
