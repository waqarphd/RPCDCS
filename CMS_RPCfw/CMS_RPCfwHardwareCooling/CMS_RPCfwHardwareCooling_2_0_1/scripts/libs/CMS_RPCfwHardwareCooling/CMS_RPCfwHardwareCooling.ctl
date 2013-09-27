/******************************
  
RPC Library for Cooling and DSS
author : Giovanni Polese
Version : 1.0
  
  
******************************/
/** CMS_RPCCoolDSS_getAllChannelsFromType
  @param sys : sytem name
  @param type : folder name from logical (HV,LV,LBB)
  @param channels : output channels found.
*/
void CMS_RPCCoolDSS_getAllChannelsFromType(string sys,string type, dyn_string & channels)
{
// sys: systemName; type: logical type (LV,HV,LBB) 
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
     alias = fwDU_getPhysicalName(children[i]);  
     if((strpos(alias,"Node")<0))  
       dynAppend(channels,sys + alias);      
     }
}


string CMS_RPCCoolDSS_getComponent(string type){

string value;
dyn_string systemNumber;

const string gasComp = "CMS_RPCfwHardwareGas";
const string blvComp = "CMS_RPCfwHardwareBarrelUXC";
const string elvComp = "CMS_RPCfwHardwareEndcapUXC";
const string bhvComp = "CMS_RPCfwHardwareBarrelUSC";
const string ehvComp = "CMS_RPCfwHardwareEndcapUSC";
const string psxComp = "CMS_RPCfwHardwareBarrelPSX";
const string supComp = "CMS_RPCfwSupervisor";
const string coolComp = "CMS_RPCfwHardwareCooling";

switch (type){
  case "EndcapT": value = elvComp;break;
  case "EndcapLV": value = elvComp;break;
  case "BarrelT": value = blvComp;break;
  case "BarrelLV": value = blvComp;break;
  case "BarrelHV": value = bhvComp;break;
  case "EndcapHV": value = ehvComp;break;
  case "Services": value = gasComp;break;
  case "Cooling": value = coolComp;break; 
  case "PSX": value = psxComp;break;  
  case "DSS": value = coolComp;break;
  case "Super": value =  supComp;break;
}

fwInstallation_getApplicationSystem(value,systemNumber);
//DebugN(systemNumber);

if(dynlen(systemNumber)!=0)
return systemNumber[1];
else
  {
  	
  return "";
  DebugN("Component not found");
  }


}

