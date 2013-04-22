dyn_string chanToCheck;

main()
{
 dyn_string nodes,exInfo;
 string val;
  
 // 2. Start the Time Functions

  checkDpTimed("EUXCTimedCheck",120);
  timedFunc("systemCheck","EUXCTimedCheck");
  
  checkDpTimed("UXCTempCheck",600);    
  timedFunc("TempCheck","UXCTempCheck"); 

//protection on OPC 
  
  dyn_string checkOPC = dpNames("caenLVESe*","RPCUtils"); 


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
  if(dynlen(chanToCheck)==0)
  {
    dyn_string a = dpAliases("*UXEndcap/T/*","*");  
    for(int i=1;i<=dynlen(a);i++)
    {
        if (strpos(a[i], "_R")>-1)
        {
          dynAppend (chanToCheck, a[i]);
        }
     }
  }
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
    dpGet(getSystemName()+ fwDU_getPhysicalName(chanToCheck[i]) + ".actual.temperature",value);
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
    dpSet(getSystemName() + "globTmon"+wheels[i]+".total", sum[i]);
    dpSet(getSystemName() + "globTmon"+wheels[i]+".averange", sum[i] / n[i]);
  }
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
 if(!dpExists(getSystemName()+"RPCCheckEUXC"))
 {
  dyn_string alertTexts = makeDynString( "Ok", "Not Ok");
  dyn_float limits = (1); 
  dyn_string alertClasses = makeDynString( "" , "_fwErrorAck.");
  string alertPanel,summary,dp; dyn_string alertPanelParameters; string alertHelp;

   
  dpCreate("RPCCheckEUXC","RPCUtils");
 dp = getSystemName()+"RPCCheckEUXC.fvalue";
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
 dyn_string sy1527 = dpNames("*LV02*","FwCaenCrateSY1527");
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
 dyn_string checkOPC = dpNames("caenLVE*","RPCUtils"); 
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
 dpSet(getSystemName()+"RPCCheckEUXC.fvalue",rint);
 dpSet(getSystemName()+"RPCCheckEUXC.svalue",info);
   
   
 }

void checkExists()
{
   dyn_string types;
  types = dpTypes("sysCheck");
  //DebugN(types);
  if(dynlen(types)<1) 
  {
  int n;

  dyn_dyn_string xxdepes;

  dyn_dyn_int xxdepei;

 

// Create the data type

  xxdepes[1] = makeDynString ("sysCheck","");

  xxdepes[2] = makeDynString ("","value");
  //xxdepes[3] = makeDynString ("","ts");


  xxdepei[1] = makeDynInt (DPEL_STRUCT);

  xxdepei[2] = makeDynInt (0,DPEL_STRING);

  

// Create the datapoint type

  n = dpTypeCreate(xxdepes,xxdepei);

  DebugN ("Datapoint Type created ");

  }

  
  
  
  }
