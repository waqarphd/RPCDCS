#uses "fwInstallationDB.ctl"
#uses "fwInstallationFSMDB.ctl"

/*
     WARNING: This library is a prototype. Please, do not use these functions in your development
              as changes to the API may still occur.
  
*/  

////////FSM functions:


void fwInstallationFSM_getTypeStateActions(string type, string state, dyn_dyn_mixed &info, dyn_string &exception)
{
  dyn_string actions;
  
  string dp = "fwOT_" + type;
  
  if(!dpExists(dp + "."))
  {
    fwException_raise(exception, "ERROR", "fwInstallationFSM_getTypeActions() -> Associated dp does not exits for FSM type: " + type, -99999);
    return;
  }
     
  dpGet(dp + ".actions", actions);
  
  for(int i = 1; i <= dynlen(actions)/5;i++)
  { 
    string newState = actions[(i-1)*5+FW_INST_FSM_ACTION_NAME - 1];
    dyn_string ds = strsplit(newState, "/");
    if(dynlen(ds) != 2)
    {
      fwException_raise(exception, "ERROR", "fwInstallationFSM_getTypeStateActions() -> Incorrect format for action name: "+ newState + " for type " + type + ". Expected format: STATE/CMD", -99999);
      return;
    }
    
    if(ds[1] == state)
    {
      info[i][FW_INST_FSM_ACTION_TYPE_NAME] =  type;
      info[i][FW_INST_FSM_ACTION_STATE] =  ds[1];
      info[i][FW_INST_FSM_ACTION_NAME] = ds[2];
      info[i][FW_INST_FSM_ACTION_PARAMS] = actions[(i-1)*5+FW_INST_FSM_ACTION_PARAMS - 1];
      info[i][FW_INST_FSM_ACTION_VISIBILITY] = actions[(i-1)*5+FW_INST_FSM_ACTION_VISIBILITY - 1];
      info[i][FW_INST_FSM_ACTION_SML] = actions[(i-1)*5+FW_INST_FSM_ACTION_SML - 1];
      info[i][FW_INST_FSM_ACTION_UNKNOWN1] = actions[(i-1)*5+FW_INST_FSM_ACTION_UNKNOWN1 - 1];
    }
  }  

  
  return; 
  
}

void fwInstallationFSM_setTypeActions(string type, dyn_string info, dyn_string &exception)
{
  string dp = "fwOT_" + type;
  
  if(!dpExists(dp + "."))
    if(dpCreate("fwOT_" + type, "_FwFsmObjectType"))
    {
      fwException_raise(exception, "fwInstallationFSM_setTypeActions()-> Cannot create new FSM type " + type, -99999);
      return;
    }
     
  dpSet(dp + ".actions", info);
  
  return; 
}

void fwInstallationFSM_setTypeStates(string type, dyn_string info, dyn_string &exception)
{
  string dp = "fwOT_" + type;
  
  if(!dpExists(dp + "."))
    if(dpCreate("fwOT_" + type, "_FwFsmObjectType"))
    {
      fwException_raise(exception, "fwInstallationFSM_setTypeActions()-> Cannot create new FSM type " + type, -99999);
      return;
    }
  dpSet(dp + ".states", info);
  
  return; 
}




void fwInstallationFSM_getTypeObjParams(string type, dyn_dyn_mixed &info, dyn_string &exception)
{
  dyn_string objParams;
  
  string dp = "fwOT_" + type;
  
  if(!dpExists(dp + "."))
  {
    fwException_raise(exception, "ERROR", "fwInstallationFSM_getTypeObjParams() -> Associated dp does not exits for FSM type: " + type, -99999);
    return;
  }
     
  dpGet(dp + ".parameters", objParams);

  for(int i = 1; i <= dynlen(objParams);i++)
  {
    info[i][FW_INST_FSM_OBJ_PARAMS_TYPE_NAME] =  type;    
    info[i][FW_INST_FSM_OBJ_PARAMS_VALUE] = objParams[FW_INST_FSM_OBJ_PARAMS_VALUE - 1];
  }  

  
  return; 
  
}

void fwInstallationFSM_setTypeObjParams(string type, dyn_string info, dyn_string &exception)
{
  string dp = "fwOT_" + type;
  
  if(!dpExists(dp + "."))
    if(dpCreate("fwOT_" + type, "_FwFsmObjectType"))
    {
      fwException_raise(exception, "fwInstallationFSM_setTypeObjParams()-> Cannot create new FSM type " + type, -99999);
      return;
    }
  
  dpSet(dp + ".parameters", info);

  return; 
  
}


void fwInstallationFSM_getTypeStates(string type, dyn_dyn_mixed &info, dyn_string &exception)
{
  dyn_string states;
  
  string dp = "fwOT_" + type;
  
  if(!dpExists(dp + "."))
  {
    fwException_raise(exception, "ERROR", "fwInstallationFSM_getTypeStates() -> Associated dp does not exits for FSM type: " + type, -99999);
    return;
  }
     
  dpGet(dp + ".states", states);
  
//DebugN("in lib, appending to states: ", states, dynlen(states));  
  
  for(int i = 1; i <= dynlen(states)/5;i++)
  {
    info[i][FW_INST_FSM_STATE_TYPE_NAME] =  type;
    info[i][FW_INST_FSM_STATE_NAME] = states[(i-1)*5+FW_INST_FSM_STATE_NAME - 1];
    info[i][FW_INST_FSM_STATE_COLOR] = states[(i-1)*5+FW_INST_FSM_STATE_COLOR - 1];
    info[i][FW_INST_FSM_STATE_WHEN] = states[(i-1)*5+FW_INST_FSM_STATE_WHEN - 1];
    info[i][FW_INST_FSM_STATE_UNKNOWN1] = states[(i-1)*5+FW_INST_FSM_STATE_UNKNOWN1 - 1];
    info[i][FW_INST_FSM_STATE_UNKNOWN2] = states[(i-1)*5+FW_INST_FSM_STATE_UNKNOWN2 - 1];
  }  

  
  return; 
  
}

void fwInstallationFSM_getTreeTypes(string tree, dyn_string &types, dyn_string &exception)
{
  string type;
  dyn_string nodes;
  
  fwTree_getAllTreeNodes(tree, nodes, exception);
  
  if(dynlen(exception))
    return;
    
  dynAppend(nodes, tree);
  for(int i = 1; i <= dynlen(nodes); i++)
  {
    fwCU_getType(nodes[i], type);
    
    if(type != "" && dynContains(types, type) <= 0)
      dynAppend(types, type);
  }

  return;  
}

void fwInstallationFSM_getTypeProperties(string type, dyn_mixed &info, dyn_string &exception)
{
  string panel = "";
  dyn_string parameters, components, actions, states;
  string dp = "fwOT_" + type;
  
  info[FW_INST_FSM_TYPE_NAME] =  type;

  if(!dpExists(dp + "."))
  {
    fwException_raise(exception, "ERROR", "Associated dp does not exits for FSM type: " + type, -99999);
    return;
  }
     
  dpGet(dp + ".panel", panel,
        dp + ".components", components);
  

  info[FW_INST_FSM_TYPE_PANEL] = panel;
    
  if(dynlen(components))
  {
    info[FW_INST_FSM_TYPE_ACTIONS_DPE] = components[FW_INST_FSM_COMPONENTS_ACTIONS_DPE];  
    info[FW_INST_FSM_TYPE_STATES_DPE] = components[FW_INST_FSM_COMPONENTS_STATES_DPE];  
  
    if(components[FW_INST_FSM_COMPONENTS_ACTIONS_DPE] != "" || components[FW_INST_FSM_COMPONENTS_STATES_DPE] != "")
      info[FW_INST_FSM_TYPE_IS_DEVICE] = 1; 
    else
      info[FW_INST_FSM_TYPE_IS_DEVICE] = 0; 
    
    info[FW_INST_FSM_TYPE_INIT_SCRIPT] = components[FW_INST_FSM_COMPONENTS_INITIAL_SCRIPTS];  
    info[FW_INST_FSM_TYPE_CMD_SCRIPT] = components[FW_INST_FSM_COMPONENTS_ACTIONS_SCRIPTS];  
    info[FW_INST_FSM_TYPE_STATE_SCRIPT] = components[FW_INST_FSM_COMPONENTS_STATES_SCRIPTS];  
    
  }

  return; 
}


void fwInstallationFSM_setTypeProperties(dyn_mixed info, dyn_string &exception)
{ 
  if(dynlen(info) <= 0)
  {
    fwException_raise(exception, "ERROR", "fwInstallationFSM_setTypeProperties() -> Invalid type structure: " + info, -99999);
    return;
  }
  
  string type = info[FW_INST_FSM_TYPE_NAME];  
  string dp = "fwOT_" + info[FW_INST_FSM_TYPE_NAME];
  dyn_string components;
  
  if(!dpExists(dp + "."))
    if(dpCreate("fwOT_" + type, "_FwFsmObjectType"))
    {
      fwException_raise(exception, "fwInstallationFSM_setTypeProperties()-> Cannot create new FSM type " + type, -99999);
      return;
    }

     
  if(dynlen(info)>= FW_INST_FSM_TYPE_STATE_SCRIPT)
  {
    components[FW_INST_FSM_COMPONENTS_ACTIONS_DPE] = info[FW_INST_FSM_TYPE_ACTIONS_DPE];
    components[FW_INST_FSM_COMPONENTS_STATES_DPE] = info[FW_INST_FSM_TYPE_STATES_DPE];
    components[FW_INST_FSM_COMPONENTS_INITIAL_SCRIPTS] = info[FW_INST_FSM_TYPE_INIT_SCRIPT];
    components[FW_INST_FSM_COMPONENTS_ACTIONS_SCRIPTS] = info[FW_INST_FSM_TYPE_CMD_SCRIPT];
    components[FW_INST_FSM_COMPONENTS_STATES_SCRIPTS] = info[FW_INST_FSM_TYPE_STATE_SCRIPT];
  }
    
  dpSet(dp + ".panel", info[FW_INST_FSM_TYPE_PANEL]);
  
  if(dynlen(components))
    dpSet(dp + ".components", components);
  
  return; 
}


void fwInstallationFSM_getNodeUserData(string node, dyn_mixed &userData, dyn_string &exception)
{
  dyn_mixed nodeInfo;
  
  fwInstallationFSM_getNodeProperties(node, nodeInfo, exception);
  
  if(dynlen(exception))
    return;
  
  userData[FW_INST_FSM_USERDATA_NODE_NAME] = nodeInfo[FW_INST_FSM_NODE_NAME];
  userData[FW_INST_FSM_USERDATA_VALUE] = nodeInfo[FW_INST_FSM_NODE_USERDATA];
  
  return; 
}

void fwInstallationFSM_setNodeUserData(string node, dyn_string userData, dyn_string &exception)
{
  string dp = "fwTN_" + node;
  
  if(!dpExists(dp + "."))
  {
    if(dpCreate(dp, "_FwTreeNode"))
    {
      fwException_raise(exception, "ERROR", "fwInstallationFSM_setNodeUserData() -> Cannot create new FSM node: " + node, -99999);
      return;
    }
  }
  
  dpSet(dp + ".userdata", userData);
  
  return;
}



void fwInstallationFSM_getNodeProperties(string node, dyn_mixed &nodeInfo, dyn_string &exception)
{
  string dp = "fwTN_" + node;
  dyn_string children, userData;
  string type, device, parent; 
  int isCU = -1;  
  
  if(!dpExists(dp + "."))
  {
    fwException_raise(exception, "ERROR", "fwInstallationFSM_getNodeProperties() -> Associated internal dp for FSM node does not exist: " + node, -99999);
    return;
  }
  
  nodeInfo[FW_INST_FSM_NODE_NAME] = node;
  
  dpGet(dp + ".children", children, 
        dp + ".device", device, 
        dp + ".type", type, 
        dp + ".cu", isCU, 
        dp + ".parent", parent, 
        dp + ".userdata", userData);
  
  nodeInfo[FW_INST_FSM_NODE_CHILDREN] = children; 
  nodeInfo[FW_INST_FSM_NODE_DEVICE] = device; 
  nodeInfo[FW_INST_FSM_NODE_TYPE] = type; 
  nodeInfo[FW_INST_FSM_NODE_PARENT] = parent; 
  nodeInfo[FW_INST_FSM_NODE_CU] = isCU; 
  nodeInfo[FW_INST_FSM_NODE_USERDATA] = userData;
  
  return;
}

void fwInstallationFSM_setRootNodeParent(string node, dyn_string &exception)
{
  string dp = "fwTN_" + node;
  
  if(!dpExists(dp + "."))
  {
    fwException_raise(exception, "ERROR", "fwInstallationFSM_setNodeChildren() -> Node does not exist: " + node, -99999);
    return;
  }
      
  dpSet(dp + ".parent", "fwTN_FSM");
  
  if(!dpExists("fwTN_FSM."))
  {
    fwException_raise(exception, "ERROR", "fwInstallationFSM_setNodeChildren() -> Node does not exist: FSM", -99999);
    return;
  }
     
  dyn_string children; 
  dpGet("fwTN_FSM.children", children);
  
  if(dynContains(children, dp) <= 0)
  {
    dynAppend(children, dp);
    dpSet("fwTN_FSM.children", children);
  }
  
  return;
}

void fwInstallationFSM_setNodeChildren(string node, dyn_string children, dyn_string &exception)
{
  string dp = "fwTN_" + node;
  dyn_string childDps;
  dyn_string dps;  
  dyn_string parents;
  
  if(!dpExists(dp + "."))
  {
    fwException_raise(exception, "ERROR", "fwInstallationFSM_setNodeChildren() -> Node does not exist: " + node, -99999);
    return;
  }
      
  
  //Now for each of the children, set its parent;
  for(int i = 1; i <= dynlen(children); i++)
  {
    if(!dpExists("fwTN_" + children[i]))
    {
      fwException_raise(exception, "ERROR", "fwInstallationFSM_setNodeChildren() -> Node does not exist. Will not be able to set its parent: " + children[i], -99999);
      continue;
    }
    dynAppend(childDps, "fwTN_" + children[i] + ".parent");
    dynAppend(dps, "fwTN_" + children[i]);
    dynAppend(parents, dp);
  }
  
  dpSet(dp + ".children", dps);  
  dpSet(childDps, parents);
  
  return;
}

void fwInstallationFSM_setNodeProperties(dyn_mixed nodeInfo, dyn_string &exception)
{
  string node = nodeInfo[FW_INST_FSM_NODE_NAME];
  string dp = "fwTN_" + node;
  
  if(!dpExists(dp + "."))
  {
    if(dpCreate(dp, "_FwTreeNode"))
    {
      fwException_raise(exception, "ERROR", "fwInstallationFSM_setNodeProperties() -> Cannot create new FSM node: " + node, -99999);
      return;
    }
  }
      
  dpSet(dp + ".device", nodeInfo[FW_INST_FSM_NODE_DEVICE], 
        dp + ".type", nodeInfo[FW_INST_FSM_NODE_TYPE], 
        dp + ".cu", nodeInfo[FW_INST_FSM_NODE_CU]);
  
  return;
}
