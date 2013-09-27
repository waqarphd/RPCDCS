#uses "fwFSMConfDB/fwFsmConfDB.ctl"

/**@file
 *
 * This package contains the functions required to support the FSM status as implemented by ATLAS.
 *
 * @author P. Phillips (ATLAS) and Fernando Varela (IT-CO/BE)
 * @date 18th of Aug 2009
 */

int fwFSMConfDBAtlas_addStatusConfigurator(string sDomain)
{
  string dpName = "STATUS_"+ fwFSMConfDB_getConfiguratorName(sDomain);
  if(fwFsmTree_isNode(dpName)==1){
    DebugN("ERROR:Configurator STATUS node "+dpName+ " already exists.");
    return fwFSMConfDB_ERROR;
  }
    
  string du = fwFsmTree_addNode("STATUS_"+sDomain,dpName,"ATLAS_DU_STATUS",0);
  
  DebugN("DU added: " + dpName + " ->>>> to domain: " + "STATUS_" + sDomain +" DU:"+du);
  
  return fwFSMConfDB_OK;
}


void fwFSMConfDBAtlas_removeStatusConfigurator(string sDomain, string sConfigurator)
{
  string dpName = "STATUS_"+ fwFSMConfDB_getConfiguratorName(sDomain);
  if(fwFsmTree_isNode(dpName)==1)
    fwFsmTree_removeNode("STATUS_"+sDomain,"STATUS_"+sConfigurator,0);
  
  return;
}

void fwFSMConfDBAtlas_DUTvalueChanged(string domain, string device, int status, string &fwState)
{ 
    string dpName = "STATUS_"+ fwFSMConfDB_getConfiguratorName(domain);
    if(fwFsmTree_isNode(dpName)==1){
    // ATLAS_DU_STATUS exists for this node:
    // - follow ATLAS behaviour
    if (status > 0){
      fwState = g_csReadyState;  
    }else{
      fwState = g_csNotReadyState;
    }    
  
    if(status > -1) 
      fwFsmAtlas_setStatus(domain, device, "OK");
    else 
      fwFsmAtlas_setStatus(domain, device, "ERROR");
      
    return;
  }
}
  
int fwFSMConfDBAtlas_DUTdoCommand(string domain, string device, string command)
{
  int val;
  dpGet(device + ".status", val);
  
  if(val<0){ //error
    if(fwFSMConfDB_getUseConfDB(device)){
      if(fwFSMConfDB_initConfDBConnection()!= 0){
        fwFSMConfDB_setState(device, g_csErrorState);
        return -1;
      }
    }
  }
    
  return 0;    
}
  
