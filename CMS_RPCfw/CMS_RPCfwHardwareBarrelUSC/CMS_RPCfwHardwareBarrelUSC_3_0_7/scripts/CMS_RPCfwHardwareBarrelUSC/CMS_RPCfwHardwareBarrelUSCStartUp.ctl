/*
 * Created by Giovanni Polese (Lappeenranta University of Technology
 *	date:08/03/2007
 *	LastChange:15/02/2010
 *       version: 1.9
 *       improved the checking for fsm refresh
 *
 */

dyn_string chanToCheck;
string caen1527;
dyn_dyn_string chStatus;
int dim;
const string version = "1.9";


//_____________________________________________________________________________
main()
{
  DebugN("Start up script version: ",version); 
  
  //----------------- Refresh status every 5 minutes
  dyn_string c1527=dpAliases("*RPCUSBarrel/Crates/*","*");
  if(dynlen(c1527)>0)
  {
    caen1527 = getSystemName()+fwDU_getPhysicalName(c1527[1]);
  }
   
  dyn_string chs = dpAliases("*RPCUSBarrel/HV/*","*");
  int step = 0;
  dim = 1;
  for (int i = 1; i<=dynlen(chs);i++)
  {
    step = (i % 10) + 1;
    dynAppend(chStatus[step],fwDU_getPhysicalName(chs[i]));
  }
  
  //DebugN(dynlen(chStatus),chStatus[1]); 
  
  if(!dpExists("USCFSMtime"))
  {
    dpCreate("USCFSMtime","RPCUtils");
    dpSet("USCFSMtime.fvalue",40);      
  }
  int refTime;   
  dpGet("USCFSMtime.fvalue",refTime);
  dpSet("USCFSMtime.svalue",version);

  checkDpTimed("USCFSMRefresh",refTime);
  timedFunc("FSMRefresh","USCFSMRefresh");

  dyn_string nodes, exInfo;
 
  checkDpTimed("USCTimedCheck",120);
  timedFunc("systemCheck","USCTimedCheck");
  checkDpTimed("USCCurrentCheck",600);
  timedFunc("currentCheck","USCCurrentCheck");

  dyn_string checkOPC = dpNames("caenHV*","RPCUtils"); 
  //DebugN(checkOPC);
  //_OPCProtection_Enabled = true;

  if(dynlen(checkOPC)>0)
  {
    dpConnect("turnOPCOff",checkOPC[1]+".svalue");
  }
}


//_____________________________________________________________________________
void 
turnOPCOff(string dpe, string value)
{
  if(value=="Ko")
  {
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


//_____________________________________________________________________________
void 
FSMRefresh()
{
  dyn_string chs = chStatus[dim];
  int status,v0,vmon,i0,ri1;
  time now = getCurrentTime();
  time last;
  int tdiff;
  string alias, state, cu;
  string sys =getSystemName(); 
  dyn_string exInfo;
  for(int i = 1;i<=dynlen(chs);i++)
  {
    dpGet(sys+chs[i]+".settings.v0:_original.._stime",last);
    tdiff = now -last;
    if(tdiff>40)
    {    
      dpGet(sys+chs[i]+".actual.status",status,
            sys+chs[i]+".actual.vMon",vmon,
            sys+chs[i]+".settings.v0",v0,
            sys+chs[i]+".readBackSettings.i1",ri1,
            sys+chs[i]+".readBackSettings.i0",i0
           );
    
      if((status<2)&&(v0-vmon < 30)&&(v0-vmon > -30))
      {
        //
        alias = fwDU_getLogicalName(sys+chs[i]);    
        fwTree_getCUName(alias, cu, exInfo);
        if(dynlen(exInfo)==0)
        {
          fwDU_getState(cu,alias,state);
          //
          if(((state == "ON")&&(vmon <8800))||((state != "ON")&&(vmon >8800))||(i0>ri1))
          {
           dpSet(sys+chs[i]+".actual.status",status);
          }
        }
      }
    }
  }

  if(dim == 10)
    dim = 1;
  else
    dim ++;
}


//_____________________________________________________________________________
void 
currentCheck()
{
  float value;
  dyn_float sum;
  dyn_int n;
  int pos;
  
  if(dynlen(chanToCheck)==0)
  {
    chanToCheck = dpAliases("*RPCUSBarrel/HV/*","*");
  }
  
  dyn_string wheels = makeDynString("WP2","WP1","W00","WM1","WM2");
  
  for(int i = 1;i<=dynlen(wheels);i++)
  {
    n[i]= 0;
    sum[i]= 0;
  }
  for(int i = 1; i<=dynlen(chanToCheck);i++)
  {
    pos = strpos(chanToCheck[i],"_W");
    pos = dynContains(wheels,substr(chanToCheck[i],pos+1,3));
    dpGet(getSystemName()+ fwDU_getPhysicalName(chanToCheck[i]) + ".actual.iMon",value);
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
      dpSet(getSystemName() + "globImon"+wheels[i]+".total", sum[i]);
      dpSet(getSystemName() + "globImon"+wheels[i]+".averange", sum[i] / n[i]);
    }
  }
}


//_____________________________________________________________________________
void 
checkDpTimed(string dp,int sec)
{
  if(!dpExists(dp))
  {
    dpCreate(dp,"_TimedFunc");
  }
  dpSet(dp+".syncTime",-1);
  dpSet(dp+".interval",sec);
}


//_____________________________________________________________________________
void 
systemCheck()
{
  // checkExists();
  dyn_string exInfo;
  int rint = 0;
  if(!dpExists(getSystemName()+"RPCCheckUSC"))
  {
    dyn_string alertTexts = makeDynString( "Ok", "Not Ok");
    dyn_float limits = (1); 
    dyn_string alertClasses = makeDynString( "" , "_fwErrorAck.");
    string alertPanel,summary,dp; 
    dyn_string alertPanelParameters; 
    string alertHelp;
   
    dpCreate("RPCCheckUSC","RPCUtils");
    dp = getSystemName()+"RPCCheckUSC.fvalue";
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
  time refresh, now = getCurrentTime();
  dyn_string sy1527 = dpNames("*","FwCaenCrateSY1527");
  string mainf;
  for(int i = 1 ; i<=dynlen(sy1527);i++)
  {
    dpGet(sy1527[i]+".FanStatus.FanStat:_original.._stime",refresh);
    //DebugN(refresh);
    float dif =now - refresh; 
    if(dif>200)
    {
      info = info + "Fan stopped;";
      rint = rint + 8;
    }
    mainf = sy1527[i];
  }
 
  //check opc control if exists
  string op;
  dyn_string checkOPC = dpNames("caenHV*","RPCUtils"); 
  //DebugN(checkOPC);
  if(dynlen(checkOPC)>0)
  {
    dpGet(checkOPC[1]+".svalue",op);
    if(op != "Ok")
    {
      info = info + "OPC server KO;";
      rint = rint + 16;
      if(strlen(mainf)>0)
      {   
        dpSet(mainf+".Information.ModelName","Ko"); 
      }
    }
    else if(strlen(mainf)>0)   
    {
      dpGet(mainf+".Information.ModelName",op);
      if(op == "Ko")
      {
        dpSet(mainf+".Information.ModelName","SY1527");
      }
    }
  }
  // fsm heartbeat
  string sval;
  // dpGet(getSystemName()+"RPCCheckUSC.svalue",sval);
  dpGet(caen1527+".userDefined",sval); 
  if(sval == "0")
  {
    rint = rint + 32;
    info = info + " FSM not responding;";
  }
  dpSet(caen1527+".userDefined","0");   
       
  // write analisys results
  dpSet(getSystemName()+"RPCCheckUSC.fvalue",rint);
  dpSet(getSystemName()+"RPCCheckUSC.svalue",info);

  //refresh FSM
  string infoSerial;
  dpGet(caen1527+".Information.ModelName", infoSerial);
  dpSet(caen1527+".Information.ModelName", infoSerial);
}


//_____________________________________________________________________________
void 
checkExists()
{
  dyn_string types = dpTypes("sysCheck");
  //DebugN(types);
  if(dynlen(types)<1) 
  {
    // Create the data type

    dyn_dyn_string xxdepes;
    xxdepes[1] = makeDynString ("sysCheck","");
    xxdepes[2] = makeDynString ("","value");
    //xxdepes[3] = makeDynString ("","ts");

    dyn_dyn_int xxdepei;
    xxdepei[1] = makeDynInt (DPEL_STRUCT);
    xxdepei[2] = makeDynInt (0,DPEL_STRING);

    // Create the datapoint type
    int n = dpTypeCreate(xxdepes, xxdepei);

    DebugN ("Datapoint Type created ");
  }
}



