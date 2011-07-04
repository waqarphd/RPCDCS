/******************************************************
  
  RPC Supervisor Library  v1.6

*************************************************************/


// Examples to use
// string DETECTOR = RPCfwSupervisor_detector($2);
//   string HV_COMPONENT = RPCfwSupervisor_getComponent(DETECTOR +"HV");
//   string LV_COMPONENT = RPCfwSupervisor_getComponent(DETECTOR +"LV");

//    RPCfwSupervisor_getChannelsFromName($2,"HV",HV_COMPONENT,output);
//    RPCfwSupervisor_getChannelsFromName($2,"LV",LV_COMPONENT,output);
//    RPCfwSupervisor_getChannelsFromName($2,"LBB",LV_COMPONENT,output);

const int LOG = 1;
const int HARD = 2;
const bool ACCESS_DCS = FALSE;

global string _hvbsys;
global string _hvesys;
global string _lvbsys;
global string _lvesys;
global string _supsys;
global string _sersys;

bool _initSupervisor = false;

global bool STATUSVALUES_G = TRUE;
const string RPCfwSupervisor_HVCorrDpType = "RPCHVCorrection";


/** 

initialization of the system name for Supervisor machine  
  
*/

void RPCfwSupervisor_getAllHVChannels(dyn_string & channels){

  dyn_string temp;
  dynClear(channels);
  RPCfwSupervisor_getSupervisorInit();
  
  RPCfwSupervisor_getAllChannelsFromType(_hvbsys,"HV",channels);
  
  RPCfwSupervisor_getAllChannelsFromType(_hvesys,"HV",temp);
  dynAppend(channels,temp);

}

void RPCfwSupervisor_getSupervisorInit(){

  if(!_initSupervisor){
  _supsys = RPCfwSupervisor_getSupervisorSys();
  _lvbsys = RPCfwSupervisor_getComponent("BarrelLV");
  _hvbsys = RPCfwSupervisor_getComponent("BarrelHV");
  
  _lvesys = RPCfwSupervisor_getComponent("EndcapLV");
  _hvesys = RPCfwSupervisor_getComponent("EndcapHV");
  _sersys = RPCfwSupervisor_getComponent("Services");
  
  _initSupervisor = true;  
  }
  

}

int RPCfwSupervisor_getHVCorrectionDps(dyn_string & dps){

  dynClear(dps);
  dps = dpNames(RPCfwSupervisor_getSupervisorSys()+"*_VBEST",RPCfwSupervisor_HVCorrDpType);
  if(dynlen(dps)==0) return -1;
  
  return 0;

}

string RPCfwSupervisor_getSupervisorSys(){

dyn_string systemNumber;
fwInstallation_getApplicationSystem("CMS_RPCfwSupervisor",systemNumber);
//DebugN("789: "+value);
if(dynlen(systemNumber)!=0)
return systemNumber[1];
else
	{
	return "";
	DebugN("Component not found");
	}

}

int RPCfwSupervisor_OPCStatus(string sys){
  
  bool isOk = true;
  
  dyn_string name = dpNames(sys+"caen*","RPCUtils");
  //DebugN(HV_COMPONENT,name);
  string val;
  if(dynlen(name)<1)
    return -1;
  else
  for(int i = 1;i<=dynlen(name);i++)
  {
    dpGet(name[i]+".svalue",val);
    if(val == "Ko")
      isOk = false;
   //DebugN(val); 
    }
    
  return isOk;
  }


void RPCfwSupervisor_getAllChannelsFromType(string sys,string type, dyn_string & channels,string search = "NULL")
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
     //if((strpos(children[i],search)>1))
       if(search == "NULL")  
         dynAppend(channels,sys + fwDU_getPhysicalName(children[i]));
       else if((strpos(children[i],search)>1))
         dynAppend(channels,sys + fwDU_getPhysicalName(children[i]));
               
     }
  
  }

RPCfwSupervisor_getChannelsFromName(string name, string type,string sysName, dyn_string & channels)
{
// To get channels starting from logical name
  //  dyn_string channels ;
  int pos = strpos(name,"_W");
  if(pos>0)
  {
  string search = substr(name,pos+1);
  string alias;
  dyn_string exInfo,nodes, children;
  fwNode_getNodes(sysName, fwDevice_LOGICAL, nodes, exInfo);
   
     for(int i = 1; i <= dynlen(nodes); i++)
      {
        alias = dpGetAlias(nodes[i] + ".");
	//DebugN(nodes[i], alias);
	nodes[i] = sysName + alias;
      
      if(strpos(nodes[i],type)>1)  
        fwDevice_getChildren(nodes[i], fwDevice_LOGICAL, children, exInfo);		                        
      
      }
     for(int i = 1; i<=dynlen(children);i++)
     {
     if((strpos(children[i],search)>1))  
       dynAppend(channels,sysName + fwDU_getPhysicalName(children[i]));      
     }
  
  }
  else{
  pos = strpos(name,"_E"); 
  if(pos>0)
  {
   endcapRPCfwSupervisor_getChannelsFromName(name,  type,sysName, channels);
  }
  } 
  
}

string RPCfwSupervisor_getComponent(string type){

  //Possible types BarrelHV, BarrelLV, Services, EndcapHV, EndcapLV
string value;
dyn_string systemNumber;

if(type=="EndcapT") type = "EndcapLV";

//DebugN(type);
if(type!="Services")
dpGet(RPCfwSupervisor_getSupervisorSys()+"CMS_RPCfwSupervisor.CompType."+type,value);
else
  value = "CMS_RPCfwHardwareGas";

fwInstallation_getApplicationSystem(value,systemNumber);
//DebugN(systemNumber);
if(type[0]=="E")
{
  if(dynlen(systemNumber)<1)  
  {
  if(type =="EndcapHV")
  {
  //systemNumber[1]="dist_215:";
  dynAppend(systemNumber,"cms_rpc_dcs_06:");
  }
  else if(type =="EndcapLV")
  dynAppend(systemNumber,"cms_rpc_dcs_05:");
  }

  
  return systemNumber[1];
}
if(dynlen(systemNumber)!=0)
return systemNumber[1];
else
  {
  	
  return "";
  DebugN("Component not found");
  }


}





RPCfwSupervisor_getChannelsFromChildren(int level, string pos,string type,string sysName,dyn_string &children){
		
	dyn_string nodes,childrenName, temp, exceptionInfo,device;
	//fwTree_getAllTreeNodes(string tree, dyn_string &nodes, dyn_string &exInfo)
	int t = 1;
	bool flag = true;
	string nodeType;
	fwTree_getChildren(pos, nodes, exceptionInfo);
	//if(type == "LBB")
        //DebugN(sysName+pos,"ooso",nodes);	
	while(flag)
		{
		if(t==level)
			flag= false;
		else
			{
			for(int i =1;i<=dynlen(nodes);i++)
				{
				fwTree_getChildren(nodes[i], childrenName, exceptionInfo);
				dynAppend(temp,childrenName);
				}
				nodes= temp;
				dynClear(temp);
				t++;
			}
		}
		
	string tName,tempName,parent,cu,parentt;
	dyn_string exInfo,sysna;
        for(int i=1; i<=dynlen(nodes); i++)
	{
	int posAmp=strpos(nodes[i],"&");
        nodeType = "";	
           if(posAmp>-1)
            {
            tempName = nodes[i];//name with &
            nodes[i]=substr(nodes[i],posAmp+5,strlen(nodes[i])-5);//strltrim(nodes[i],"&0001");
            tName = nodes[i];//name without &
            
	       fwTree_getCUName(sysName+nodes[i],parentt,exInfo);
               //DebugN("Cu on remote system",parentt,exInfo);
               fwTree_getCUName(tempName,parent,exInfo);
               //DebugN("Cu on this system",parent,exInfo);
               if(dynlen(exInfo)>0)
               {
               //fwCU_getType(parent+"::"+parentt+"::"+,tipo);
                 if(strpos($2,"|")>-1)
                 sysna = strsplit($2,"|");
                 else
                   sysna[2] = $2;
                 fwTree_getCUName(sysna[2],cu,exInfo);
                 strreplace(parent,"C_","C_UXC_");
                 cu = cu+"|"+parentt+"|"+tName;
                 //DebugN("Malo:",nodes[i]);
                 dpGet(cu+".type",nodeType);
                 // fwCU_getType(nodes[i],nodeType);
                 dynClear(exInfo);          
                 }
               else
                 {
                 nodes[i] = parent+"::"+parentt+"::"+nodes[i];    
               
                 if((parent!="")&&(parentt!=""))
                    fwCU_getType(nodes[i],nodeType);
                 }
               
            }
            else                
                fwCU_getType(nodes[i],nodeType);
		
            //DebugN("-rrrr->",nodes[i],nodeType);
			
		
		if((nodeType == "RPC_Chamber")&&(type!="LBB"))
		{
			RPCfwSupervisor_getChannels(nodes[i],type,sysName,device);
			//DebugN(nodes[i],type,sysName,"chamb",children);
		  dynAppend(children,device);
			
		}	
		else if((nodeType == "RPC_LBBLV")&&(type=="LBB"))
		{
			nodes[i]=strrtrim(tName,"_LBB");
			RPCfwSupervisor_getChannels(nodes[i],type,sysName,device);
 			//DebugN(nodes[i],type,sysName,"lbb",children);
                        //DebugN("Ueeeee: ", device);
		  dynAppend(children,device);
		  
		}
        
	}
        //DebugN(children,"ela");
	
}

// ex. getChannels($2,"HV",HV_COMPONENT, hvChannels);
RPCfwSupervisor_getChannels(string pos,string type,string sysName,dyn_string &children){
		
	dyn_string channels,exceptionInfo;
	int len,po;
					
	fwTree_getChildren(sysName+pos+"_"+type, channels, exceptionInfo);
	for (int i=1;i<=dynlen(channels);i++)
		{
		po = strpos(channels[i],"&");
	  if(po>-1)
	  	{
	  	len = strlen(channels[i]);
	  	children[i] = sysName+fwDU_getPhysicalName(sysName+substr(channels[i],po+5,len));
	  	}
	  else
			children[i] = sysName+fwDU_getPhysicalName(sysName+channels[i]);
		}
}

dyn_string RPCfwSupervisor_getLogical(dyn_string hardName)
{
	dyn_string temp;
	for(int i = 1; i <=dynlen(hardName);i++)
		{
		temp[i]  = fwDU_getLogicalName(hardName[i]);
		}
	return temp;

}

string RPCfwSupervisor_detector(string name){
if(strpos(name,"_E")>-1)
	return "Endcap";
else
	return "Barrel";

}
endcapRPCfwSupervisor_getChannelsFromName(string name, string type,string sysName, dyn_string & channels)
{
// To get channels starting from logical name
//  dyn_string channels ;
  int pos;
  pos = strpos(name,"_E");
  //DebugN("this is type:",type);
  
  if(pos>0)
  {
  string search = substr(name,pos+1);
  string alias;
  dyn_string exInfo,nodes, children;
  fwNode_getNodes(sysName, fwDevice_LOGICAL, nodes, exInfo);

  for(int i = 1; i <= dynlen(nodes); i++)
      {
        alias = dpGetAlias(nodes[i] + ".");
	//DebugN("nodes[i],alias",nodes[i], alias);
	nodes[i] = sysName + alias;
	//type = "/"+type;
        //DebugN("search before", search);        
      if(strpos(nodes[i],"/"+type)>-1)  
        {
                fwDevice_getChildren(nodes[i], fwDevice_LOGICAL, children, exInfo);		                        
               // DebugN(nodes[i]+"getting"+ type+" type--------",children);
        }
      }
   if(search=="EP1_R3" && type == "LBB"){search="EP1_R2_R3";}//hassan
   if(search=="EP2_R3" )                {search="EP2_R2_R3";}//hassan
   if(search=="EP3_R3" )                {search="EP3_R2_R3";}// hassan
   
   if(search=="EN1_R3" && type == "LBB"){search="EN1_R2_R3";}//taimoor
   if(search=="EN2_R3" )                {search="EN2_R2_R3";}//taimoor
   if(search=="EN3_R3" )                {search="EN3_R2_R3";}// taimoor
  //   DebugN("search after", search);
//     DebugN("children--------",children);
     for(int i = 1; i<=dynlen(children);i++)
     {
if((strpos(children[i],search)>-1))  
             dynAppend(channels,sysName + fwDU_getPhysicalName(children[i]));     
     }
}
}
/** 
  @param dpTrendName : canvas name 
  @param length :  number of curves
  @param chs : channels physical names to plot

  center the curves with 20% of variation  
  
*/
void RPCSupervisor_SetAxis(string dpTrendName,int length,dyn_string chs){
dyn_dyn_int ranges;
int val;
dyn_string exceptionInfo;

for(int i = 1;i<=length;i++)
{
dpGet(chs[i],val);

//DebugN(values[i]+"."+values[i+length]);
ranges[i][1] = val - val*0.2;
if(ranges[i][1] == val)
  ranges[i][1]--;
ranges[i][2] = val + val*0.2;
if(ranges[i][2] == val)
  ranges[i][2]++;
}
dpTrendName = RPCfwSupervisor_getSupervisorSys()+dpTrendName;
dyn_dyn_string pp;
fwTrending_getPlot(dpTrendName,pp,exceptionInfo);				
for(int i = 1; i<=length;i++)
  {
    if(pp[fwTrending_PLOT_OBJECT_AXII][1])
      {
      pp[fwTrending_PLOT_OBJECT_RANGES_MAX][i]=ranges[i][2];
      pp[fwTrending_PLOT_OBJECT_RANGES_MIN][i]=ranges[i][1];
    }
  } 

//DebugN(pp);
fwTrending_setPlot(dpTrendName,pp,exceptionInfo);

}
