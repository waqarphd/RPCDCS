/***************************************************************
  
  RPC General Library v:1.0
  
  author: Giovanni Polese
  
****************************************************************/  

#uses "CMSfw_CAENOPCConfigurator/CMSfw_CAENOPCConfiguratorLib.ctl"
#uses "CMSfwAlertSystem/CMSfwAlertSystemUtil.ctl"
#uses "CMSfwAlertSystem/CMSfwAlertSystemGeneral.ctc"

const int CMS_RPCfwGeneral_LOG = 1;
const int CMS_RPCfwGeneral_HARD = 2;
const bool CMS_RPCfwGeneral_ACCESS_DCS = true;

string CMS_RPCfwGeneral_getSupervisorSys(){

dyn_string systemNumber;
fwInstallation_getApplicationSystem("CMS_RPCfwSupervisor",systemNumber);
if(dynlen(systemNumber)!=0)
return systemNumber[1];
else
	{
	return "Error";
	DebugN("Component not found");
	}

}

int CMS_RPCfwGeneral_createUserSMS(string user){

  if (user == "") return -1;
  string phoneNum;
  dyn_string users;
  switch (user){
    case "polese":phoneNum = "165807";
      break;
   default : phoneNum =  "165508";  
  
  }
  users = dpNames("*"+user+"*","CMSfwAlertSystemUsers");
  
  if(dynlen(users)==0)
      CMSfwAlertSystemUtil_addUser(user);
  else return 1;

  users = dpNames("*"+user+"*","CMSfwAlertSystemUsers");
  
  //in case it fails
  if(dynlen(users)==0)
  CMSfwAlertSystemUtil_createUser(user, user+ "@cern.ch", phoneNum);
  else if (user ==  "rpcbarre")
        dpSet(users[1]+".GSMNumber","165508");
  
  return 1;
}

void CMS_RPCfwGeneral_configureOPC() {
  dyn_string exc;
  DebugTN("Configuring OPC Server");
  CMSfw_CAENOPCConfigurator_configureFromFwCaenDps(exc);
  DebugN("Exc configuring OPC Server", exc);
  
}


void CMS_RPCfwHardware_getDeviceChannels(string pos, string type, dyn_dyn_string & channels)
    
{
  
  dyn_string children, exceptionInfo;
	string device, typeNode;
        string compName;
        if(strpos(type,"HV")>-1)
          compName = "BarrelHV";
        else if(strpos(type,"LV")>-1)
            compName = "BarrelLV";
        else if(strpos(type,"T")>-1)
          {
            compName = "BarrelT";
            type = "ADCTemp";
          }
        string parent = CMS_RPCfwGeneral_getComponent(compName)+pos;
        
	fwTree_getChildren(parent, children, exceptionInfo);
	//DebugN("ue",pos, children,"ola");
	if(dynlen(children)==0)
	{
		fwTree_getNodeDevice(parent, device, typeNode, exceptionInfo);
		//Debug("ok",typeNode,type);
                if(typeNode == "FwCaenChannel"+type)
                {
                  //Debug("ok");
                  dynAppend(channels[LOG], parent);                  
                  dynAppend(channels[HARD],dpSubStr(parent,DPSUB_SYS)+fwDU_getPhysicalName(parent));

                  }
		
	}	
	else
		for(int i=1; i<=dynlen(children); i++)
		{
			if(children[i][0]=="&")
				children[i] = substr (children[i], 5);

			CMS_RPCfwHardware_getDeviceChannels(children[i],type, channels);
		}
 
}

string CMS_RPCfwGeneral_detector(string name){
if(strpos(name,"YE")>-1)
	return "Endcap";
else
	return "Barrel";

}
