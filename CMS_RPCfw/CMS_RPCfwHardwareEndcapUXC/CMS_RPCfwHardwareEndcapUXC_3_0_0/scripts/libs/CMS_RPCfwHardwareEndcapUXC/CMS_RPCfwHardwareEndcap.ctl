const int LOG = 1;
const int HARD = 2;
const bool ACCESS_DCS = FALSE;
global bool _OPCProtection_Enabled;


string RPCfwSupervisor_getSupervisorSys(){

dyn_string systemNumber;
fwInstallation_getApplicationSystem("CMS_RPCfwSupervisor",systemNumber);
//DebugN("789: "+value);
if(dynlen(systemNumber)!=0)
return systemNumber[1];
else
	{
	return "Error";
	DebugN("Component not found");
	}
}
string RPCfwSupervisor_getComponent(string type){

string value;
dyn_string systemNumber;
dpGet(getSystemName()+"CMS_RPCfwSupervisor.CompType."+type,value);
fwInstallation_getApplicationSystem(value,systemNumber);
DebugN("789: "+value);
if(dynlen(systemNumber)!=0)
return systemNumber[1];
else
{
	DebugN("Component Emulated");
        return getSystemName();

        
      }
}

CMS_RPCfwHardware_getDeviceChannels(string pos, string type, dyn_dyn_string & channels)
    
{
  
  dyn_string children, exceptionInfo;
	string device, typeNode;
        string compName;
        if(strpos(type,"HV")>-1)
          compName = "EndcapHV";
        else if(strpos(type,"LV")>-1)
            compName = "EndcapLV";
        else if(strpos(type,"T")>-1)
          {
            compName = "EndcapT";
            type = "ADCTemp";
          }
        string parent = RPCfwSupervisor_getComponent(compName)+pos;
        
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

// RPCfwSupervisor_getChannelsFromChildren(int level, string pos,string type,string sysName,dyn_string &children){
// 		
// 	dyn_string nodes,childrenName, temp, exceptionInfo,device;
// 	//fwTree_getAllTreeNodes(string tree, dyn_string &nodes, dyn_string &exInfo)
// 	int t = 1;
// 	bool flag = true;
// 	string nodeType;
// 	fwTree_getChildren(pos, nodes, exceptionInfo);
// 	//DebugN(sysName+pos,"ooso",nodes);	
// 	while(flag)
// 		{
// 		if(t==level)
// 			flag= false;
// 		else
// 			{
// 			for(int i =1;i<=dynlen(nodes);i++)
// 				{
// 				fwTree_getChildren(nodes[i], childrenName, exceptionInfo);
// 				dynAppend(temp,childrenName);
// 				}
// 				nodes= temp;
// 				dynClear(temp);
// 				t++;
// 			}
// 		}
// 		
// 	
// 	for(int i=1; i<=dynlen(nodes); i++)
// 	{
// 		if(strpos(nodes[i],"&")>-1)
// 			nodes[i]=strltrim(nodes[i],"&0001");
// 		
// 		fwCU_getType(nodes[i],nodeType);
// 		
// 			
// 		//DebugN(nodes[i],nodeType);
// 		if(nodeType == "RPC_Chamber")
// 		{
// 			RPCfwSupervisor_getChannels(nodes[i],type,sysName,device);
// 			//DebugN(nodes[i],type,sysName,"ooo",children);
// 		  dynAppend(children,device);
// 			
// 		}	
// 		else if(nodeType == "LinkBoardsBoxNode")
// 		{
// 			nodes[i]=strrtrim(nodes[i],"_LBB");
// 			RPCfwSupervisor_getChannels(nodes[i],type,sysName,device);
// 			//DebugN(nodes[i],type,sysName,"ooo",children);
// 		  dynAppend(children,device);
// 		  //DebugN("Ueeeee: ", device);
// 		}
// 	}
// 	
// }
// ex. getChannels($2,"HV",HV_COMPONENT, hvChannels);
// RPCfwSupervisor_getChannels(string pos,string type,string sysName,dyn_string &children){
// 		
// 	dyn_string channels,exceptionInfo;
// 	int len,po;
// 					
// 	fwTree_getChildren(sysName+pos+"_"+type, channels, exceptionInfo);
// 	for (int i=1;i<=dynlen(channels);i++)
// 		{
// 		po = strpos(channels[i],"&");
// 	  if(po>-1)
// 	  	{
// 	  	len = strlen(channels[i]);
// 	  	children[i] = sysName+fwDU_getPhysicalName(sysName+substr(channels[i],po+5,len));
// 	  	}
// 	  else
// 			children[i] = sysName+fwDU_getPhysicalName(sysName+channels[i]);
// 		}
// }
// 
// dyn_string RPCfwSupervisor_getLogical(dyn_string hardName)
// {
// 	dyn_string temp;
// 	for(int i = 1; i <=dynlen(hardName);i++)
// 		{
// 		temp[i]  = fwDU_getLogicalName(hardName[i]);
// 		}
// 	return temp;
// 
// }

string RPCfwSupervisor_detector(string name){
if(strpos(name,"YE")>-1)
	return "Endcap";
else
	return "Endcap";

}
