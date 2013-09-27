#uses "fwInstallationDB.ctl"
#uses "fwInstallationFSM.ctl"

/*
     WARNING: This library is a prototype. Please, do not use these functions in your development
              as changes to the API may still occur.
  
*/  

const int FW_INST_FSM_TYPE_PROPERTIES = 1;
const int FW_INST_FSM_TYPE_STATES = 2;
const int FW_INST_FSM_TYPE_ACTIONS = 3;
const int FW_INST_FSM_TYPE_SCRIPTS = 4;
const int FW_INST_FSM_TYPE_OBJ_PARAMS = 5;

//TYPE PROPERTIES:    
const int FW_INST_FSM_TYPE_NAME = 1;
const int FW_INST_FSM_TYPE_PANEL = 2;
const int FW_INST_FSM_TYPE_ACTIONS_DPE = 3;
const int FW_INST_FSM_TYPE_STATES_DPE = 4;
const int FW_INST_FSM_TYPE_IS_DEVICE = 5;
const int FW_INST_FSM_TYPE_INIT_SCRIPT = 6;
const int FW_INST_FSM_TYPE_CMD_SCRIPT = 7;
const int FW_INST_FSM_TYPE_STATE_SCRIPT = 8;

//STATES PROPERTIES:    
const int FW_INST_FSM_STATE_TYPE_NAME = 1;
const int FW_INST_FSM_STATE_NAME = 2;
const int FW_INST_FSM_STATE_COLOR = 3;
const int FW_INST_FSM_STATE_WHEN = 4;
const int FW_INST_FSM_STATE_UNKNOWN1 = 5;
const int FW_INST_FSM_STATE_UNKNOWN2 = 6;

//ACTIONS PROPERTIES:    
const int FW_INST_FSM_ACTION_TYPE_NAME = 1;
const int FW_INST_FSM_ACTION_NAME = 2;
const int FW_INST_FSM_ACTION_PARAMS = 3;
const int FW_INST_FSM_ACTION_VISIBILITY = 4;
const int FW_INST_FSM_ACTION_SML = 5;
const int FW_INST_FSM_ACTION_UNKNOWN1 = 6;
const int FW_INST_FSM_ACTION_STATE = 7;

//SCRIPT PROPERTIES:    
//const int FW_INST_FSM_SCRIPT_TYPE_NAME = 1;
//const int FW_INST_FSM_SCRIPT_TYPE = 2;
//const int FW_INST_FSM_SCRIPT_CODE = 3;

//OBJ PARAMS PROPERTIES:    
const int FW_INST_FSM_OBJ_PARAMS_TYPE_NAME = 1;
const int FW_INST_FSM_OBJ_PARAMS_VALUE = 2;

//FSM Components
const int FW_INST_FSM_COMPONENTS_STATES_DPE = 1;
const int FW_INST_FSM_COMPONENTS_ACTIONS_DPE = 2;
const int FW_INST_FSM_COMPONENTS_INITIAL_SCRIPTS = 3;
const int FW_INST_FSM_COMPONENTS_STATES_SCRIPTS = 4;
const int FW_INST_FSM_COMPONENTS_ACTIONS_SCRIPTS = 5;

//FSM Node:
const int FW_INST_FSM_NODE_NAME     = 1;
const int FW_INST_FSM_NODE_TYPE     = 2;
const int FW_INST_FSM_NODE_DEVICE   = 3;
const int FW_INST_FSM_NODE_CU       = 4;
const int FW_INST_FSM_NODE_PARENT   = 5;
const int FW_INST_FSM_NODE_CHILDREN = 6;
const int FW_INST_FSM_NODE_USERDATA = 7;

//FSM NODE USERDATA:
const int FW_INST_FSM_USERDATA_NODE_NAME = 1;
const int FW_INST_FSM_USERDATA_VALUE = 2;

//FSM HIERARCHY:
const int FW_INST_FSM_HIERARCHY_PARENT = 1;
const int FW_INST_FSM_HIERARCHY_CHILD = 2;

////Beginning of executable code:

void fwInstallationFSMDB_importTree(string tree, dyn_string &exception)
{
  dyn_string trees;
  dyn_dyn_mixed nodesInfo;
  dyn_dyn_mixed typesInfo;
  dyn_dyn_string statesInfo;
  dyn_dyn_string actionsInfo;
  dyn_dyn_mixed objParamsInfo;
  dyn_dyn_mixed hierarchyInfo;

  dyn_string types;
  dyn_string nodes;
  
  dyn_dyn_mixed nodesUserDataInfo;
  
  fwInstallationFSMDB_getTrees(trees, exception);
    
  fwInstallationFSMDB_getTreeNodes(tree, nodesInfo, exception);
  if(dynlen(exception))
    fwExceptionHandling_display(exception);

  for(int i = 1; i <= dynlen(nodesInfo); i++)
  {
    nodes[i] = nodesInfo[i][FW_INST_FSM_NODE_NAME];
    types[i] = nodesInfo[i][FW_INST_FSM_NODE_TYPE];
    
    fwInstallationFSM_setNodeProperties(nodesInfo[i], exception);
  }
  
  if(dynlen(exception))
    fwExceptionHandling_display(exception);    
  
  dynUnique(types);
  
  fwInstallationFSMDB_getNodesUserData(nodes, nodesUserDataInfo, exception);  
  if(dynlen(exception))
    fwExceptionHandling_display(exception);

  string node = "";
  dyn_string userData;
  
  for(int i = 1; i <= dynlen(nodesUserDataInfo); i++)
  {
    
    if(node != nodesUserDataInfo[i][FW_INST_FSM_USERDATA_NODE_NAME])
    {
      if(dynlen(userData) > 0)
      {
        fwInstallationFSM_setNodeUserData(node, userData, exception);
        dynClear(userData);
      }
      node = nodesUserDataInfo[i][FW_INST_FSM_USERDATA_NODE_NAME];
      dynAppend(userData, nodesUserDataInfo[i][FW_INST_FSM_USERDATA_VALUE]);        
    }else
      dynAppend(userData, nodesUserDataInfo[i][FW_INST_FSM_USERDATA_VALUE]);        
  }

  if(dynlen(userData) > 0)
  {
    fwInstallationFSM_setNodeUserData(node, userData, exception);
    dynClear(userData);
  }
  
///    
  fwInstallationFSMDB_getTypesProperties(types, typesInfo, exception);
  if(dynlen(exception))
    fwExceptionHandling_display(exception);


  for(int i = 1; i <= dynlen(typesInfo); i++)
  {
    fwInstallationFSM_setTypeProperties(typesInfo[i], exception); 
  }

  fwInstallationFSMDB_getTypesStates(types, statesInfo, exception);
  
  if(dynlen(exception))
    fwExceptionHandling_display(exception);

  string type = "";
  dyn_string states;
   
  for(int i = 1; i <= dynlen(statesInfo); i++)
  {
    if(type != statesInfo[i][FW_INST_FSM_STATE_TYPE_NAME])
    {
      if(dynlen(states) > 0)
      {
        fwInstallationFSM_setTypeStates(type, states, exception);
        dynClear(states);
      }
      type = statesInfo[i][FW_INST_FSM_STATE_TYPE_NAME];
      dynRemove(statesInfo[i], FW_INST_FSM_STATE_TYPE_NAME);
      dynAppend(states, statesInfo[i]);        
    }else
    {
      dynRemove(statesInfo[i], FW_INST_FSM_STATE_TYPE_NAME);
      dynAppend(states, statesInfo[i]);        
    }
  }

  //Check if there is still something to be set:  
  if(dynlen(states) > 0)
  {
     fwInstallationFSM_setTypeStates(type, states, exception);
     dynClear(states);
  }

  fwInstallationFSMDB_getTypesActions(types, actionsInfo, exception);
  
  if(dynlen(exception))
    fwExceptionHandling_display(exception);

  string type = "";
  dyn_string actions;
   
  for(int i = 1; i <= dynlen(actionsInfo); i++)
  {
    if(type != actionsInfo[i][FW_INST_FSM_ACTION_TYPE_NAME])
    {
      if(dynlen(actions) > 0)
      {
        fwInstallationFSM_setTypeActions(type, actions, exception);
        dynClear(actions);
      }
      type = actionsInfo[i][FW_INST_FSM_ACTION_TYPE_NAME];
      dynRemove(actionsInfo[i], FW_INST_FSM_ACTION_TYPE_NAME);
      dynAppend(actions, actionsInfo[i]);        
    }else
    {
      dynRemove(actionsInfo[i], FW_INST_FSM_ACTION_TYPE_NAME);
      dynAppend(actions, actionsInfo[i]);        
    }
  }

  //Check if there is still something to be set:  
  if(dynlen(actions) > 0)
  {
     fwInstallationFSM_setTypeActions(type, actions, exception);
     dynClear(actions);
  }

  fwInstallationFSMDB_getTypesObjParams(types, objParamsInfo, exception);
  
  if(dynlen(exception))
    fwExceptionHandling_display(exception);

  
  type = "";
  dyn_string objParams;

  for(int i = 1; i <= dynlen(objParamsInfo); i++)
  {
    if(type != objParamsInfo[i][FW_INST_FSM_OBJ_PARAMS_TYPE_NAME])
    {
      
      if(dynlen(objParams) > 0)
      {
        fwInstallationFSM_setTypeObjParams(type, objParams, exception);
        dynClear(objParams);
      }
      type = objParamsInfo[i][FW_INST_FSM_OBJ_PARAMS_TYPE_NAME];
      dynAppend(objParams, objParamsInfo[i][FW_INST_FSM_OBJ_PARAMS_VALUE]);        
    }else
    {
      dynAppend(objParams, objParamsInfo[i][FW_INST_FSM_OBJ_PARAMS_VALUE]);        
    }
  }
  
  //Check if there is still something to be set:
  if(dynlen(objParams) > 0)
  {
    fwInstallationFSM_setTypeObjParams(type, objParams, exception);
    dynClear(objParams);
  }
  

  fwInstallationFSMDB_getHierarchy(tree, hierarchyInfo, exception);  
  if(dynlen(exception))
    fwExceptionHandling_display(exception);
  
  //DebugN("HierarchyInfo: ", hierarchyInfo);
  
  string parent = "";
  dyn_string children;
  for(int i = 1; i <= dynlen(hierarchyInfo); i++)
  {
    if(parent != hierarchyInfo[i][FW_INST_FSM_HIERARCHY_PARENT])
    {
      if(dynlen(children) > 0)
      {
        //DebugN("setting children to ", parent, children);
        fwInstallationFSM_setNodeChildren(parent, children, exception);
        dynClear(children);
      }
      
      parent = hierarchyInfo[i][FW_INST_FSM_HIERARCHY_PARENT];
      if(i == 1 && dynContains(trees, parent) > 0) //Check if the first node is a root FSM node and if so, set its default parent.
      {
        fwInstallationFSM_setRootNodeParent(parent, exception);
      }
      
      dynAppend(children, hierarchyInfo[i][FW_INST_FSM_HIERARCHY_CHILD]);        
    }else
    {
      dynAppend(children, hierarchyInfo[i][FW_INST_FSM_HIERARCHY_CHILD]);
    }
  }  
  
  //Check if there is still something to be set:
  if(dynlen(children) > 0)
  {
    //DebugN("2 setting children to ", parent, children);
    fwInstallationFSM_setNodeChildren(parent, children, exception);
    dynClear(children);
  }
  
  //Generate FSM tree
//  fwFsmTree_generateAll();
  
}

void fwInstallationFSMDB_exportTree(string tree, dyn_string &exception)
{

  fwInstallationFSMDB_removeTree(tree, exception);
  if(dynlen(exception))
    return;
    
  fwInstallationFSMDB_exportTreeTypes(tree, exception);
  if(dynlen(exception))
    return;
  
  fwInstallationFSMDB_exportTreeNodes(tree, exception);
  if(dynlen(exception))
    return;
  
  fwInstallationFSMDB_exportHierarchy(tree, exception);
  if(dynlen(exception))
    return;
  
}
      
void fwInstallationFSMDB_exportTreeNodes(string tree, dyn_string &exception)
{
  dyn_string nodes;
  dyn_mixed nodeInfo;
  dyn_dyn_mixed info;
  dyn_mixed nodeUserData;
  dyn_dyn_mixed userDataInfo;

  fwTree_getAllTreeNodes(tree, nodes, exception);
  
  if(dynlen(exception))
  {
    fwExceptionHandling_display(exception);
    return;
  }
  
  dynAppend(nodes, tree);
  
  for(int i = 1; i <= dynlen(nodes); i++)
  {
    fwInstallationFSM_getNodeProperties(nodes[i], nodeInfo, exception);
    if(dynlen(exception))
    {
      fwExceptionHandling_display(exception);
      return;
    }
    info[i] = nodeInfo;
    
    
    fwInstallationFSM_getNodeUserData(nodes[i], nodeUserData, exception);
    if(dynlen(exception))
    {
      fwExceptionHandling_display(exception);
      return;
    }
    
    userDataInfo[i] = nodeUserData;
  }

 
 // DebugN("Exporting to DB nodes: ", info);
  
  fwInstallationFSMDB_setTreeNodeProperties(info, exception);
  if(dynlen(exception))
  {
    fwExceptionHandling_display(exception);
    return;
  }
  
  fwInstallationFSMDB_setTreeNodeUserData(userDataInfo, exception);
  if(dynlen(exception))
  {
    fwExceptionHandling_display(exception);
    return;
  }
  
}


void fwInstallationFSMDB_exportTreeTypes(string tree, dyn_string &exception)
{    
  dyn_string types;
  
  dyn_dyn_mixed typesInfo;
  dyn_dyn_mixed typesStates;
  dyn_dyn_mixed typesActions;
  dyn_dyn_mixed typesScripts;
  dyn_dyn_mixed typesObjParams;
  
  dyn_mixed infoType;
  dyn_dyn_mixed infoState;
  dyn_dyn_mixed infoAction;
  dyn_dyn_mixed infoScript;
  dyn_dyn_mixed infoObjParam;
  
  int n = 1, m = 1, o = 1, p = 1, q = 1;
  
  fwInstallationFSM_getTreeTypes(tree, types, exception); 

  if(dynlen(exception))
    return;  
  
  else if(dynlen(types) <= 0)
  {
    fwException_raise(exception, "ERROR", "Tree does not contain any type info:" + tree, -999999);
    return;
  }

  for(int i = 1; i <= dynlen(types); i++)
  {   
    dynClear(infoType);
    fwInstallationFSM_getTypeProperties(types[i], infoType, exception);
    if(dynlen(exception))
    {
      fwException_raise(exception, "ERROR", "fwInstallationDB_exportTree() -> Could not retrieve properties of type: " + type, -99999);
      continue;
    }
    
    if(dynlen(infoType))
    {    
      typesInfo[n] = infoType;
      ++n;
    }
       
    fwInstallationFSM_getTypeStates(types[i], infoState, exception);
    if(dynlen(exception))
    {
      fwException_raise(exception, "ERROR", "fwInstallationDB_exportTree() -> Could not retrieve states of type: " + type, -99999);
      continue;
    }
    
    for(int j = 1; j <= dynlen(infoState); j++)
    {
      if(dynlen(infoState[j]))
      {  
        //DebugN("appending to typesStates: ", infoState[j]);
        typesStates[m] = infoState[j];
        ++m;
        string state = infoState[j][FW_INST_FSM_STATE_NAME];
        dynClear(infoAction);
        fwInstallationFSM_getTypeStateActions(types[i], state, infoAction, exception);
        //DebugN("Retrieving actions for state: " + state + " gives: ", infoAction);
        if(dynlen(exception))
        {
          fwException_raise(exception, "ERROR", "fwInstallationDB_exportTree() -> Could not retrieve actions of state: " + state + " and type: " + types[i], -99999);
          continue;
        }
  
        for(int j = 1; j <= dynlen(infoAction); j++)
        {
          if(dynlen(infoAction[j]))
          {
            typesActions[o] = infoAction[j];
            ++o;
          }
        }  
      }
    }
    
/*
    fwInstallationFSM_getTypeActions(types[i], infoAction, exception);
    if(dynlen(exception))
    {
      fwException_raise(exception, "ERROR", "fwInstallationDB_exportTree() -> Could not retrieve actions of type: " + type, -99999);
      continue;
    }
  
    for(int j = 1; j <= dynlen(infoAction); j++)
    {
      if(dynlen(infoAction[j]))
      {
        typesActions[o] = infoAction[j];
        ++o;
      }
    }  
    
////////////////
*/
    
    fwInstallationFSM_getTypeObjParams(types[i], infoObjParam, exception);
    if(dynlen(exception))
    {
      fwException_raise(exception, "ERROR", "fwInstallationDB_exportTree() -> Could not retrieve object parameters of type: " + type, -99999);
      continue;
    }
  
    for(int j = 1; j <= dynlen(infoObjParam); j++)
    {
      if(dynlen(infoObjParam[j]))
      {
        typesObjParams[q] = infoObjParam[j];
        ++q;
      }
    }
  }
  
//  DebugN("typesInfo", typesInfo);
//  DebugN("typesStates", typesStates);
//  DebugN("typesActions", typesActions);
//  DebugN("typesScripts", typesScripts);
//  DebugN("typesObjParams", typesObjParams);
  
  //Save type info to DB:
  fwInstallationFSMDB_setTreeTypeProperties(typesInfo, exception);  
  if(dynlen(exception))
    fwException_raise(exception, "ERROR", "fwInstallationDB_exportTree() -> Could not export types info to the DB", -99999);
  
  fwInstallationFSMDB_setTreeTypeStates(typesStates, exception);  
  if(dynlen(exception))
    fwException_raise(exception, "ERROR", "fwInstallationDB_exportTree() -> Could not export types states info to the DB", -99999);
  
  fwInstallationFSMDB_setTreeTypeActions(typesActions, exception);  
  if(dynlen(exception))
    fwException_raise(exception, "ERROR", "fwInstallationDB_exportTree() -> Could not export types actions info to the DB", -99999);
  
  fwInstallationFSMDB_setTreeTypeObjParams(typesObjParams, exception);  
  if(dynlen(exception))
    fwException_raise(exception, "ERROR", "fwInstallationDB_exportTree() -> Could not export types object parameters info to the DB", -99999);

}

fwInstallationFSMDB_removeTree(string tree, dyn_string &exception)
{
  fwInstallationFSMDB_removeTreeTypeProperties(tree, exception);
  return;
}

/*
fwInstallationFSMDB_removeTree(string tree, dyn_string &exception)
{
  fwInstallationFSMDB_removeTreeTypeStates(tree, exception);
  if(dynlen(exception))
    return;
  
  fwInstallationFSMDB_removeTreeTypeObjParams(tree, exception);  
  if(dynlen(exception))
    return;
  
  fwInstallationFSMDB_removeTreeTypeActions(tree, exception);  
  if(dynlen(exception))
    return;
  
  fwInstallationFSMDB_removeTreeNodeUserData(tree, exception);
  
  if(dynlen(exception))
    return;
  
  fwInstallationFSMDB_removeTreeNodeProperties(tree, exception);  
  if(dynlen(exception))
    return;
  
  
  fwInstallationFSMDB_removeTreeTypeProperties(tree, exception);
  if(dynlen(exception))
    return;

  
}
*/
void fwInstallationFSMDB_exportTreeNodeProperties(string tree, dyn_string &exception)
{
  dyn_string nodes;
  dyn_mixed nodeInfo;
  dyn_dyn_mixed info;

  fwTree_getAllTreeNodes(tree, nodes, exception);
  
  if(dynlen(exception))
  {
    fwExceptionHandling_display(exception);
    return;
  }
  
  dynAppend(nodes, tree);
  
  for(int i = 1; i <= dynlen(nodes); i++)
  {
    fwInstallationFSM_getNodeProperties(nodes[i], nodeInfo, exception);
    if(dynlen(exception))
    {
      fwExceptionHandling_display(exception);
      return;
    }
    info[i] = nodeInfo;
  }

 
  fwInstallationFSMDB_setSystemNodeProperties(info, exception);
  
  if(dynlen(exception))
  {
    fwExceptionHandling_display(exception);
    return;
  }

}

void fwInstallationFSMDB_exportTreeTypeObjParams(string tree, dyn_string &exception)
{
  dyn_string types;
  dyn_dyn_mixed objParamsInfo;
  dyn_dyn_mixed info;

  fwInstallationFSM_getTreeTypeNames(tree, types, exception);
  if(dynlen(exception))
  {
    fwExceptionHandling_display(exception);
    return;
  }
  
  int n = 1;
  for(int i = 1; i <= dynlen(types); i++)
  {
    fwInstallationFSM_getTypeObjParams(types[i], objParamsInfo, exception);
    if(dynlen(exception))
    {
      fwExceptionHandling_display(exception);
      return;
    }
    
    for(int j = 1; j <= dynlen(objParamsInfo); j++)
    {      
      info[n] = objParamsInfo[j];
      ++n;
    }
  }
  
  fwInstallationFSMDB_setSystemTypeObjParams(info, exception);
  
  if(dynlen(exception))
  {
    fwExceptionHandling_display(exception);
    return;
  }

}

void fwInstallationFSMDB_exportTreeTypeActions(string tree, dyn_string &exception)
{
  dyn_string types;
  dyn_dyn_mixed actionsInfo;
  dyn_dyn_mixed info;

  fwInstallationFSM_getTreeTypeNames(tree, types, exception);
  if(dynlen(exception))
  {
    fwExceptionHandling_display(exception);
    return;
  }
  
  for(int i = 1; i <= dynlen(types); i++)
  {
    fwInstallationFSM_getTypeActions(types[i], actionsInfo, exception);
    if(dynlen(exception))
    {
      fwExceptionHandling_display(exception);
      return;
    }
    
    for(int j = 1; j <= dynlen(actionsInfo); j++)
      info[i] = actionsInfo[j];
  }
  
  fwInstallationFSMDB_setSystemTypeActions(info, exception);
  
  if(dynlen(exception))
  {
    fwExceptionHandling_display(exception);
    return;
  }

}


fwInstallationFSMDB_exportTreeTypeStates(string tree, dyn_string &exception)  
{
  dyn_string types;
  dyn_dyn_mixed statesInfo;
  dyn_dyn_mixed info;

  fwInstallationFSM_getTreeTypeNames(tree, types, exception);
  if(dynlen(exception))
  {
    fwExceptionHandling_display(exception);
    return;
  }
  
  for(int i = 1; i <= dynlen(types); i++)
  {
    fwInstallationFSM_getTypeStates(types[i], statesInfo, exception);
    if(dynlen(exception))
    {
      fwExceptionHandling_display(exception);
      return;
    }
    
    for(int j = 1; j <= dynlen(statesInfo); j++)
      info[i] = statesInfo[j];
  }

  fwInstallationFSMDB_setSystemTypeStates(info, exception);
  
  if(dynlen(exception))
  {
    fwExceptionHandling_display(exception);
    return;
  }

}

void fwInstallationFSMDB_exportTreeTypeProperties(string tree, dyn_string &exception)      
{
  dyn_string types;
  dyn_mixed typeInfo;
  dyn_dyn_mixed info;

  fwInstallationFSM_getTreeTypeNames(tree, types, exception);
  if(dynlen(exception))
  {
    fwExceptionHandling_display(exception);
    return;
  }
  
  for(int i = 1; i <= dynlen(types); i++)
  {
    fwInstallationFSM_getSystemTypeProperties(types[i], typeInfo, exception);
    if(dynlen(exception))
    {
      fwExceptionHandling_display(exception);
      return;
    }
    info[i] = typeInfo;
  }

  fwInstallationFSMDB_setSystemTypeProperties(info, exception);
  
  if(dynlen(exception))
  {
    fwExceptionHandling_display(exception);
    return;
  }

}

////Hierarchy:
fwInstallationFSMDB_exportHierarchy(string tree, dyn_string &exception)
{
  string type;
  dyn_string nodes;
  int typeId = -1;
  int nodeId = -1;
  dyn_dyn_mixed typeInfo;
  dyn_dyn_mixed nodeInfo;

  int parentType;
  dyn_int childTypes;
  
  string parent;
  dyn_string children;
  string device;
    
  fwTree_getAllTreeNodes(tree, nodes, exception);
  
  if(dynlen(exception))
    return;

  dynAppend(nodes, tree);

  //Build the hierarchy now:    
  for(int i = 1; i <= dynlen(nodes); i++)
  {
    
    fwTree_getParent(nodes[i], parent, exception);
    if(dynlen(exception))
    if(parent != "")    
      fwInstallationFSMDB_setNodeParent(nodes[i], parent, exception);
    
    fwTree_getChildren(nodes[i], children, exception);
    fwInstallationFSMDB_setNodeChildren(nodes[i], children, exception);

  }//end of loop over nodes
  
  return;
}


int fwInstallationFSMDB_getTrees(dyn_string &trees, dyn_string &exception)
{
  string id;
  dyn_dyn_mixed aRecords;
  string sql;
  
  dynClear(aRecords);

  sql = "SELECT NAME FROM FW_SYS_STAT_FSM_NODES WHERE ID NOT IN (SELECT DISTINCT(NODE_ID) FROM FW_SYS_STAT_FSM_HIERARCHIES WHERE VALID_UNTIL IS NULL)";

  if(g_fwInstallationSqlDebug)
      DebugN(sql);

  if(fwInstallationDB_executeDBQuery(sql, aRecords) != 0)
  {
    fwException_raise(exception, "ERROR", "fwInstallationDB_getChildTrees() -> Could not execute the following SQL query: " + sql, -99999);
    DebugN("ERROR: fwInstallationDB_getChildTrees() -> Could not execute the following SQL query: " + sql);
    return;
  }

  if(dynlen(aRecords))
    trees = aRecords[1];
  
  return;
}

//Types

fwInstallationFSMDB_getTreeTypes(string tree, dyn_dyn_mixed &typesInfo, dyn_string &exception)
{
  string sql;
  dyn_dyn_mixed aRecords;
  int nodeId = -1;
  int sysId = -1;
  string str;

  if(fwInstallationDB_isSystemRegistered(sysId) != 0)
  {
    fwException_raise(exception, "ERROR", "fwInstallationFSMDB_getTreeTypeProperties() -> Could not check if local system is registered in DB", -99999);
    return;
  }
  
  if(sysId <= 0)
  {
    fwException_raise(exception, "ERROR", "fwInstallationFSMDB_getTreeTypeProperties() -> Local system is not registered in DB", -99999);
    return;
  }

  fwInstallationFSMDB_isNodeRegistered(nodeId, tree, exception);  
  if(sysId <= 0)
  {
    fwException_raise(exception, "ERROR", "fwInstallationFSMDB_getTreeTypeProperties() -> FSM tree not registered in the DB: " + tree, -99999);
    return;
  }
  
  sql = "SELECT DISTINCT(NAME), PANEL, ACTIONS_DPE, STATES_DPE, IS_DEVICE " +
        "FROM FW_SYS_STAT_FSM_TYPES " + 
        "WHERE ID IN (select t.id from fw_sys_stat_fsm_nodes n, fw_sys_stat_fsm_types t where t.system_id = " + sysId + " and t.id = n.type_id and n.id in (select h.node_id " +
			    "from fw_sys_stat_fsm_hierarchies h " + 
			    "start with (h.parent_node_id = " + nodeId + " and h.valid_until is null) " + 
			    "connect by (prior h.node_id = h.parent_node_id and h.valid_until is null))) OR ID = (select type_id from fw_sys_stat_fsm_nodes where id = " + nodeId + ")";
         
  if(g_fwInstallationSqlDebug)
    DebugN(sql);
  
  if(fwInstallationDB_executeDBQuery(sql, aRecords) != 0)
  {
    DebugN("ERROR: fwInstallationFSMDB_getTreeTypeProperties() -> Could not execute the following SQL query: " + sql);
    fwException_raise(exception, "ERROR", "fwInstallationFSMDB_getTreeTypeProperties() -> Could not execute the following SQL query: " + sql, -99999);
    return;
  }  

  /*

  if(fwInstallationDB_isSystemRegistered(sysId) != 0)
  {
    fwException_raise(exception, "ERROR", "fwInstallationFSMDB_getTreeTypeProperties() -> Could not check if local system is registered in DB", -99999);
    return;
  }
  
  if(sysId <= 0)
  {
    fwException_raise(exception, "ERROR", "fwInstallationFSMDB_getTreeTypeProperties() -> Local system is not registered in DB", -99999);
    return;
  }

  //Get tree nodes:
  dyn_dyn_mixed nodesInfo;
  fwInstallationFSMDB_getTreeNodes(tree, nodesInfo, exception);  
  if(dynlen(exception))
  {
    fwException_raise(exception, "ERROR", "fwInstallationFSMDB_getTreeTypeProperties() -> Local system is not registered in DB", -99999);
    return;
  }
  
  if(dynlen(nodesInfo) <= 0)
    return;

  for(int i = 1 ; i <= dynlen(nodesInfo);i++)
    str = str + "\'" + nodesInfo[i][FW_INST_FSM_NODE_NAME] + "\', ";  
  
  if(dynlen(nodesInfo) > 1)
    str = str + "\'" + nodesInfo[dynlen(nodesInfo)][FW_INST_FSM_NODE_NAME] + "\'";
  
  sql = "SELECT DISTINCT(NAME), PANEL, ACTIONS_DPE, STATES_DPE, IS_DEVICE FROM FW_SYS_STAT_FSM_TYPES WHERE SYSTEM_ID = " + sysId + " AND VALID_UNTIL IS NULL AND NAME IN ("+ str +") ORDER BY ID" ;
         
  if(g_fwInstallationSqlDebug)
    DebugN(sql);
  
  if(fwInstallationDB_executeDBQuery(sql, aRecords) != 0)
  {
    DebugN("ERROR: fwInstallationFSMDB_getTreeTypeProperties() -> Could not execute the following SQL query: " + sql);
    fwException_raise(exception, "ERROR", "fwInstallationFSMDB_getTreeTypeProperties() -> Could not execute the following SQL query: " + sql, -99999);
    return;
  }  
*/
  
  typesInfo = aRecords;  
    
  return;   
}

fwInstallationFSMDB_getTypesProperties(dyn_string types, dyn_dyn_mixed &typesInfo, dyn_string &exception)
{
  string sql;
  dyn_dyn_mixed aRecords;
  int sysId = -1;
  string str;

  int topNodeId = -1;
    
  if(fwInstallationDB_isSystemRegistered(sysId) != 0)
  {
    fwException_raise(exception, "ERROR", "fwInstallationFSMDB_getTreeTypeProperties() -> Could not check if local system is registered in DB", -99999);
    return;
  }
  
  if(sysId <= 0)
  {
    fwException_raise(exception, "ERROR", "fwInstallationFSMDB_getTreeTypeProperties() -> Local system is not registered in DB", -99999);
    return;
  }
  
  for(int i = 1; i <= (dynlen(types)-1); i++)
  {
    str += "\'"+types[i]+"\', ";
  }
  
  str += "\'"+types[dynlen(types)]+"\'";
  
  
  sql = "SELECT NAME, PANEL, ACTIONS_DPE, STATES_DPE, IS_DEVICE, INIT_SCRIPT, CMD_SCRIPT, STATE_SCRIPT FROM FW_SYS_STAT_FSM_TYPES WHERE SYSTEM_ID = " + sysId + " AND VALID_UNTIL IS NULL AND NAME IN ("+ str +") ORDER BY ID" ;
         
  if(g_fwInstallationSqlDebug)
    DebugN(sql);
  
  if(fwInstallationDB_executeDBQuery(sql, aRecords) != 0)
  {
    DebugN("ERROR: fwInstallationFSMDB_getTreeTypeProperties() -> Could not execute the following SQL query: " + sql);
    fwException_raise(exception, "ERROR", "fwInstallationFSMDB_getTreeTypeProperties() -> Could not execute the following SQL query: " + sql, -99999);
    return;
  }  

  typesInfo = aRecords;  
    
  return;   
}


fwInstallationFSMDB_getTypesStates(dyn_string types, dyn_dyn_string &statesInfo, dyn_string &exception)
{
  string sql;
  dyn_dyn_mixed aRecords;
  string str = "";

  for(int i = 1; i <= (dynlen(types)-1); i++)
  {
    str += "\'"+types[i]+"\', ";
  }
  
  str += "\'"+types[dynlen(types)]+"\'";
  
  sql = "SELECT T.NAME, S.NAME, S.COLOR, S.WHEN, S.UNKNOWN1, S.UNKNOWN2 FROM FW_SYS_STAT_FSM_STATES S, FW_SYS_STAT_FSM_TYPES T WHERE T.ID = S.TYPE_ID AND T.VALID_UNTIL IS NULL AND S.VALID_UNTIL IS NULL AND S.TYPE_ID IN (SELECT ID FROM FW_SYS_STAT_FSM_TYPES WHERE VALID_UNTIL IS NULL AND NAME IN (" + str + ")) ORDER BY T.NAME";
         
  if(g_fwInstallationSqlDebug)
    DebugN(sql);
  
  if(fwInstallationDB_executeDBQuery(sql, aRecords) != 0)
  {
    DebugN("ERROR: fwInstallationFSMDB_getTreeTypeStates() -> Could not execute the following SQL query: " + sql);
    fwException_raise(exception, "ERROR", "fwInstallationFSMDB_getTreeTypeStates() -> Could not execute the following SQL query: " + sql, -99999);
    return;
  }  

  statesInfo = aRecords;  
    
  return;   
}

fwInstallationFSMDB_getTypesActions(dyn_string types, dyn_dyn_mixed &actionsInfo, dyn_string &exception)
{
  string sql;
  dyn_dyn_mixed aRecords;
  string str = "";

  for(int i = 1; i <= (dynlen(types)-1); i++)
  {
    str += "\'"+types[i]+"\', ";
  }
  
  str += "\'"+types[dynlen(types)]+"\'";

  sql = "SELECT T.NAME, S.NAME||'/'||A.NAME, A.PARAMS, A.VISIBILITY, A.SML, A.UNKNOWN1 " + 
        "FROM FW_SYS_STAT_FSM_ACTIONS A, FW_SYS_STAT_FSM_TYPES T, FW_SYS_STAT_FSM_STATES S " +
        "WHERE T.VALID_UNTIL IS NULL AND " +
	          "A.VALID_UNTIL IS NULL AND S.VALID_UNTIL IS NULL AND T.ID = S.TYPE_ID AND S.ID = A.STATE_ID AND " +
            "S.TYPE_ID IN (SELECT ID FROM FW_SYS_STAT_FSM_TYPES " +
      				"WHERE VALID_UNTIL IS NULL AND " +
      				"NAME IN (" + str + ")) ORDER BY T.ID, S.ID, A.ID";  
  
  if(g_fwInstallationSqlDebug)
    DebugN(sql);
  
  if(fwInstallationDB_executeDBQuery(sql, aRecords) != 0)
  {
    DebugN("ERROR: fwInstallationFSMDB_getTreeTypeActions() -> Could not execute the following SQL query: " + sql);
    fwException_raise(exception, "ERROR", "fwInstallationFSMDB_getTreeTypeActions() -> Could not execute the following SQL query: " + sql, -99999);
    return;
  }  

  actionsInfo = aRecords;  
    
  return;   
}


fwInstallationFSMDB_getTypesObjParams(dyn_string types, dyn_dyn_mixed &objParamsInfo, dyn_string &exception)
{
  string sql;
  dyn_dyn_mixed aRecords;
  string str = "";

  for(int i = 1; i <= (dynlen(types)-1); i++)
  {
    str += "\'"+types[i]+"\', ";
  }
  
  str += "\'"+types[dynlen(types)]+"\'";
  
  sql = "SELECT T.NAME, P.PARAM FROM FW_SYS_STAT_FSM_TYPE_OBJ_PARS P, FW_SYS_STAT_FSM_TYPES T WHERE T.ID = P.TYPE_ID AND P.VALID_UNTIL IS NULL AND P.TYPE_ID IN (SELECT T.ID FROM FW_SYS_STAT_FSM_TYPES T WHERE T.VALID_UNTIL IS NULL AND T.NAME IN (" + str + ")) ORDER BY T.NAME";
         
  if(g_fwInstallationSqlDebug)
    DebugN(sql);
  
  if(fwInstallationDB_executeDBQuery(sql, aRecords) != 0)
  {
    DebugN("ERROR: fwInstallationFSMDB_getTreeTypeObjParams() -> Could not execute the following SQL query: " + sql);
    fwException_raise(exception, "ERROR", "fwInstallationFSMDB_getTreeTypeObjParams() -> Could not execute the following SQL query: " + sql, -99999);
    return;
  }  

  objParamsInfo = aRecords;  
    
  return;   
}

fwInstallationFSMDB_getTreeNodes(string topNode, dyn_dyn_mixed &nodesInfo, dyn_string &exception)
{
  string sql;
  dyn_dyn_mixed aRecords;
  int topNodeId = -1;
  int sysId = -1;
    
  fwInstallationFSMDB_isNodeRegistered(topNodeId, topNode, exception);
  
  if(dynlen(exception))
  {
    fwException_raise(exception, "ERROR", "fwInstallationFSMDB_getTreeNodeProperties() -> Could not check if (sub)tree"+ topNode + " is registered in DB", -99999);
    return;
  }
  
  if(topNodeId < 0)
  {
    fwException_raise(exception, "ERROR", "fwInstallationFSMDB_getTreeNodeProperties() -> (sub)tree " + topNode + " is not registered in DB", -99999);
    return;
  }
  
  if(fwInstallationDB_isSystemRegistered(sysId))
  {
    fwException_raise(exception, "ERROR", "fwInstallationFSMDB_getTreeNodeProperties() -> Could not check if (sub)tree"+ topNode + " is registered in DB", -99999);
    return;
  }
  
  if(topNodeId < 0)
  {
    fwException_raise(exception, "ERROR", "fwInstallationFSMDB_getTreeNodeProperties() -> (sub)tree " + topNode + " is not registered in DB", -99999);
    return;
  }
  
  sql = "select n.name, t.name type, n.device, n.is_cu from fw_sys_stat_fsm_nodes n, fw_sys_stat_fsm_types t where t.id = n.type_id and n.id = " + topNodeId;
         
  if(g_fwInstallationSqlDebug)
    DebugN(sql);
  
  if(fwInstallationDB_executeDBQuery(sql, aRecords) != 0)
  {
    DebugN("ERROR: fwInstallationFSMDB_getTreeNodeProperties() -> Could not execute the following SQL query: " + sql);
    fwException_raise(exception, "ERROR", "fwInstallationFSMDB_getTreeNodeProperties() -> Could not execute the following SQL query: " + sql, -99999);
    return;
  }  
  
  nodesInfo[1] = aRecords[1];  

  dynClear(aRecords);
  sql = "select n.name, t.name type, n.device, n.is_cu from fw_sys_stat_fsm_nodes n, fw_sys_stat_fsm_types t where t.system_id = " + sysId + " and t.id = n.type_id and n.id in (select h.node_id " +  
        " from fw_sys_stat_fsm_hierarchies h " + 
        " start with (h.parent_node_id = " + topNodeId + " and h.valid_until is null) " +
        " connect by (prior h.node_id = h.parent_node_id and h.valid_until is null))";
         
  if(g_fwInstallationSqlDebug)
    DebugN(sql);
  
  if(fwInstallationDB_executeDBQuery(sql, aRecords) != 0)
  {
    DebugN("ERROR: fwInstallationFSMDB_getTreeNodeProperties() -> Could not execute the following SQL query: " + sql);
    fwException_raise(exception, "ERROR", "fwInstallationFSMDB_getTreeNodeProperties() -> Could not execute the following SQL query: " + sql, -99999);
    return;
  }  
  
  for(int i = 1; i <= dynlen(aRecords); i++)
  {
    nodesInfo[i + 1] = aRecords[i];  
  }  
  
  return;   
}


fwInstallationFSMDB_getNodesUserData(dyn_string nodes, dyn_dyn_mixed &nodesUserData, dyn_string &exception)
{
  string sql;
  dyn_dyn_mixed aRecords;
  string str = "";

    
  for(int i = 1; i <= (dynlen(nodes)-1); i++)
    str += "\'" + nodes[i] + "\', ";
  
  str += "\'" + nodes[dynlen(nodes)] + "\'";
  
  sql = "select n.name, ud.data from fw_sys_stat_fsm_nodes n, fw_sys_stat_fsm_node_userdata ud where n.id = ud.node_id and n.name in (" + str + ") and ud.valid_until is null order by ud.id, n.name";
         
  if(g_fwInstallationSqlDebug)
    DebugN(sql);
  
  if(fwInstallationDB_executeDBQuery(sql, aRecords) != 0)
  {
    DebugN("ERROR: fwInstallationFSMDB_getNodesUserData() -> Could not execute the following SQL query: " + sql);
    fwException_raise(exception, "ERROR", "fwInstallationFSMDB_getNodesUserData() -> Could not execute the following SQL query: " + sql, -99999);
    return;
  }  
  
  nodesUserData = aRecords;  
  
  return;   
}


void fwInstallationFSMDB_setTreeTypeProperties(dyn_dyn_mixed info, dyn_string &exception)
{
  int sysId = -1;
  string sql;
    
  string type;
  string panel;

  int isDevice;
  string actionsDpe;
  string statesDpe;
  string initScript;
  string cmdScript;
  string stateScript;
    
  //Find out system id:
  if(fwInstallationDB_isSystemRegistered(sysId))
  {
    fwException_raise(exception, "ERROR", "fwInstallationFSMDB_setTreeTypeProperties() -> Cannot retrieve PVSS System from the DB", -99999);
    return;
  }
  
  if(sysId == -1)
  {
    fwException_raise(exception, "ERROR", "fwInstallationFSMDB_setTreeTypeProperties() -> System: " + getSystemName() + " not yet registered in DB. Aborting...", -99999);
    return;
  }
  
  for(int i =1; i <= dynlen(info); i++)
  {  
    
    type = info[i][FW_INST_FSM_TYPE_NAME];
    panel = info[i][FW_INST_FSM_TYPE_PANEL];
    
    if(dynlen(info[i]) >= FW_INST_FSM_TYPE_IS_DEVICE)
    {
      isDevice = info[i][FW_INST_FSM_TYPE_IS_DEVICE];
      actionsDpe = info[i][FW_INST_FSM_TYPE_ACTIONS_DPE];
      statesDpe =  info[i][FW_INST_FSM_TYPE_STATES_DPE];
      initScript =  info[i][FW_INST_FSM_TYPE_INIT_SCRIPT];
      cmdScript =  info[i][FW_INST_FSM_TYPE_CMD_SCRIPT];
      stateScript =  info[i][FW_INST_FSM_TYPE_STATE_SCRIPT];
      sql = "INSERT INTO FW_SYS_STAT_FSM_TYPES(ID, NAME, SYSTEM_ID, PANEL, ACTIONS_DPE, STATES_DPE, IS_DEVICE, INIT_SCRIPT, CMD_SCRIPT, STATE_SCRIPT) VALUES (FW_SYS_STAT_FSM_TYPES_SQ.NEXTVAL, \'" +
            type + "\', "+ sysId+", \'" + panel + "\', \'" + actionsDpe + "\', \'" + statesDpe + "\', " + isDevice + ", \'"+initScript+"\', \'"+cmdScript+"\', \'"+stateScript+"\')";
    }
    else
    {
      sql = "INSERT INTO FW_SYS_STAT_FSM_TYPES(ID, NAME, SYSTEM_ID, PANEL, ACTIONS_DPE, STATES_DPE, IS_DEVICE, INIT_SCRIPT, CMD_SCRIPT, STATE_SCRIPT) VALUES (FW_SYS_STAT_FSM_TYPES_SQ.NEXTVAL, \'" +
            type + "\', "+ sysId+", \'" + panel + "\', NULL, NULL, 0, NULL, NULL, NULL)";
    }
    
    if(g_fwInstallationSqlDebug)
      DebugN(sql);
    
    if(rdbExecuteSqlStatement(gFwInstallationDBConn, sql)) {
      DebugN("ERROR: fwInstallationFSMDB_setTreeTypeProperties() -> Could not execute the following SQL: " + sql); 
      fwException_raise(exception, "ERROR", "fwInstallationFSMDB_setTreeTypeProperties() -> Could not execute the following SQL: " + sql, -99999);
      continue;
    }
  }
  
  return; 
}

void fwInstallationFSMDB_setTreeTypeActions(dyn_dyn_mixed info, dyn_string &exception)
{
  int stateId = -1;
  string sql;
    
  string type;
  string action;
  string params;
  int visibility;
  string sml;
  string uk1;
  
  for(int i =1; i <= dynlen(info); i++)
  {  
    //Find out type id:
    type = info[i][FW_INST_FSM_ACTION_TYPE_NAME];
    string state = info[i][FW_INST_FSM_ACTION_STATE];
    fwInstallationFSMDB_isTypeStateRegistered(stateId, state, type, exception);
    
    if(dynlen(exception))
    {
      fwException_raise(exception, "ERROR", "fwInstallationFSMDB_setTreeTypeActions() -> Cannot retrieve type "+ type+ "  from the DB", -99999);
      return;
    }
  
    if(stateId == -1)
    {
      fwException_raise(exception, "ERROR", "fwInstallationFSMDB_setTreeTypeActions() -> Type: " + type + " not yet registered in DB. Aborting...", -99999);
      continue;
    }
    
    action = info[i][FW_INST_FSM_ACTION_NAME];
    params = info[i][FW_INST_FSM_ACTION_PARAMS];
    visibility = info[i][FW_INST_FSM_ACTION_VISIBILITY];
    sml = info[i][FW_INST_FSM_ACTION_SML];
    uk1 = info[i][FW_INST_FSM_ACTION_UNKNOWN1];
    
    sql = "INSERT INTO FW_SYS_STAT_FSM_ACTIONS(ID, NAME, STATE_ID, PARAMS, VISIBILITY, SML, UNKNOWN1) VALUES (FW_SYS_STAT_FSM_ACTIONS_SQ.NEXTVAL, \'" +
            action + "\', "+ stateId+", \'" + params + "\', " + visibility + ", \'" + sml + "\', \'" + uk1 + "\')";
    
         
    if(g_fwInstallationSqlDebug)
      DebugN(sql);
    
    if(rdbExecuteSqlStatement(gFwInstallationDBConn, sql)) {
      DebugN("ERROR: fwInstallationFSMDB_setTreeTypeActions() -> Could not execute the following SQL: " + sql); 
      fwException_raise(exception, "ERROR", "fwInstallationFSMDB_setTreeTypeActions() -> Could not execute the following SQL: " + sql, -99999);
      continue;
    }
  }
  
  return; 
}

void fwInstallationFSMDB_setTreeTypeObjParams(dyn_dyn_mixed info, dyn_string &exception)
{
  int typeId = -1;
  string sql;
    
  string type;
  string param;

  for(int i =1; i <= dynlen(info); i++)
  {  
    //Find out type id:
    type = info[i][FW_INST_FSM_OBJ_PARAMS_TYPE_NAME];
    fwInstallationFSMDB_isTypeRegistered(typeId, type, exception);
    
    if(dynlen(exception))
    {
      fwException_raise(exception, "ERROR", "fwInstallationFSMDB_setTreeTypeObjParams() -> Cannot retrieve "+type+" from the DB", -99999);
      return;
    }
  
    if(typeId == -1)
    {
      fwException_raise(exception, "ERROR", "fwInstallationFSMDB_setSystemTypeObjParams() -> Type: " + type + " not yet registered in DB. Aborting...", -99999);
      continue;
    }
    
    param = info[i][FW_INST_FSM_OBJ_PARAMS_VALUE];
    
    sql = "INSERT INTO FW_SYS_STAT_FSM_TYPE_OBJ_PARS(ID, TYPE_ID, PARAM) VALUES (FW_SYS_STAT_FSM_T_OBJ_PARS_SQ.NEXTVAL, " +
            typeId + ", \'" + param + "\')";
    
         
    if(g_fwInstallationSqlDebug)
      DebugN(sql);
    
    if(rdbExecuteSqlStatement(gFwInstallationDBConn, sql)) {
      DebugN("ERROR: fwInstallationFSMDB_setTreeTypeObjParams() -> Could not execute the following SQL: " + sql); 
      fwException_raise(exception, "ERROR", "fwInstallationFSMDB_setTreeTypeObjParams() -> Could not execute the following SQL: " + sql, -99999);
      continue;
    }
  }
  
  return; 
}


void fwInstallationFSMDB_setTreeTypeStates(dyn_dyn_mixed info, dyn_string &exception)
{
  int typeId = -1;
  string sql;
    
  string type;
  string state;
  string color;
  string when;
  string uk1;
  string uk2;


  for(int i =1; i <= dynlen(info); i++)
  {  
    //Find out type id:
    type = info[i][FW_INST_FSM_STATE_TYPE_NAME];
    fwInstallationFSMDB_isTypeRegistered(typeId, type, exception);
    
    if(dynlen(exception))
    {
      fwException_raise(exception, "ERROR", "fwInstallationFSMDB_setTreeTypeStates() -> Cannot retrieve "+type+" from the DB", -99999);
      return;
    }
  
    if(typeId == -1)
    {
      fwException_raise(exception, "ERROR", "fwInstallationFSMDB_setTreeTypeStates() -> Type: " + type + " not yet registered in DB. Aborting...", -99999);
      continue;
    }
    
    state = info[i][FW_INST_FSM_STATE_NAME];
    color = info[i][FW_INST_FSM_STATE_COLOR];
    when = info[i][FW_INST_FSM_STATE_WHEN];
    uk1 = info[i][FW_INST_FSM_STATE_UNKNOWN1];
    uk2 = info[i][FW_INST_FSM_STATE_UNKNOWN2];
    
    sql = "INSERT INTO FW_SYS_STAT_FSM_STATES(ID, NAME, TYPE_ID, COLOR, WHEN, UNKNOWN1, UNKNOWN2) VALUES (FW_SYS_STAT_FSM_STATES_SQ.NEXTVAL, \'" +
            state + "\', "+ typeId+", \'" + color + "\', \'" + when + "\', \'" + uk1 + "\', \'" + uk2 + "\')";
    
         
    if(g_fwInstallationSqlDebug)
      DebugN(sql);
    
    if(rdbExecuteSqlStatement(gFwInstallationDBConn, sql)) {
      DebugN("ERROR: fwInstallationFSMDB_setTreeTypeStates() -> Could not execute the following SQL: " + sql); 
      fwException_raise(exception, "ERROR", "fwInstallationFSMDB_setTreeTypeStates() -> Could not execute the following SQL: " + sql, -99999);
      continue;
    }
  }
  
  return; 
}

void fwInstallationFSMDB_removeTreeTypeStates(string topNode, dyn_string &exception)
{
  int sysId = -1;
  string sql;
  int topNodeId = -1;
    
  fwInstallationFSMDB_isNodeRegistered(topNodeId, topNode, exception);
  
  if(dynlen(exception))
  {
    fwException_raise(exception, "ERROR", "fwInstallationFSMDB_removeTreeTypeStates() -> Could not check if (sub)tree "+ topNode + " is registered in DB", -99999);
    return;
  }
  
  if(topNodeId < 0)
  {
    //Tree does not exist, nothing to be deleted
    return;
  }
    
  //Find out system id:
  if(fwInstallationDB_isSystemRegistered(sysId))
  {
    fwException_raise(exception, "ERROR", "fwInstallationFSMDB_removeTreeTypeStates() -> Cannot retrieve PVSS System from the DB", -99999);
    return;
  }
  
  if(sysId == -1)
  {
    //nothing to be done
    return;
  }
  
  dyn_dyn_mixed aRecords;
  
  sql = "UPDATE FW_SYS_STAT_FSM_STATES SET VALID_UNTIL = SYSDATE WHERE VALID_UNTIL IS NULL AND TYPE_ID IN (SELECT ID FROM FW_SYS_STAT_FSM_TYPES WHERE VALID_UNTIL IS NULL AND SYSTEM_ID = " + sysId + ")";
    
         
  if(g_fwInstallationSqlDebug)
    DebugN(sql);
    
  if(rdbExecuteSqlStatement(gFwInstallationDBConn, sql)) {
    DebugN("ERROR: fwInstallationFSMDB_removeTreeTypeStates() -> Could not execute the following SQL: " + sql); 
    fwException_raise(exception, "ERROR", "fwInstallationFSMDB_removeTreeTypeStates() -> Could not execute the following SQL: " + sql, -99999);
    return;
  }
  
  return; 
}



void fwInstallationFSMDB_removeTreeTypeActions(string topNode, dyn_string &exception)
{
  int sysId = -1;
  string sql;
  int topNodeId = -1;
    
  fwInstallationFSMDB_isNodeRegistered(topNodeId, topNode, exception);
  
  if(dynlen(exception))
  {
    fwException_raise(exception, "ERROR", "fwInstallationFSMDB_removeTreeTypeActions() -> Could not check if (sub)tree "+ topNode + " is registered in DB", -99999);
    return;
  }
  
  if(topNodeId < 0)
  {
    //Tree does not exist, nothing to be deleted
    return;
  }
    
  //Find out system id:
  if(fwInstallationDB_isSystemRegistered(sysId))
  {
    fwException_raise(exception, "ERROR", "fwInstallationFSMDB_removeTreeTypeActions() -> Cannot retrieve PVSS System from the DB", -99999);
    return;
  }
  
  if(sysId == -1)
  {
    //nothing to be done
    return;
  }
  
  sql = "UPDATE FW_SYS_STAT_FSM_ACTIONS SET VALID_UNTIL = SYSDATE WHERE VALID_UNTIL IS NULL AND TYPE_ID IN (SELECT ID FROM FW_SYS_STAT_FSM_TYPES WHERE VALID_UNTIL IS NULL AND SYSTEM_ID = " + sysId + ")";
    
         
  if(g_fwInstallationSqlDebug)
    DebugN(sql);
    
  if(rdbExecuteSqlStatement(gFwInstallationDBConn, sql)) {
    DebugN("ERROR: fwInstallationFSMDB_removeTreeTypeActions() -> Could not execute the following SQL: " + sql); 
    fwException_raise(exception, "ERROR", "fwInstallationFSMDB_removeTreeTypeActions() -> Could not execute the following SQL: " + sql, -99999);
    return;
  }
  
  return; 
}

void fwInstallationFSMDB_removeTreeTypeObjParams(string topNode, dyn_string &exception)
{
  int sysId = -1;
  string sql;
  int topNodeId = -1;
    
  fwInstallationFSMDB_isNodeRegistered(topNodeId, topNode, exception);
  
  if(dynlen(exception))
  {
    fwException_raise(exception, "ERROR", "fwInstallationFSMDB_removeTreeTypeObjParams() -> Could not check if (sub)tree "+ topNode + " is registered in DB", -99999);
    return;
  }
  
  if(topNodeId < 0)
  {
    //Tree does not exist, nothing to be deleted
    return;
  }
    
  //Find out system id:
  if(fwInstallationDB_isSystemRegistered(sysId))
  {
    fwException_raise(exception, "ERROR", "fwInstallationFSMDB_removeTreeTypeObjParams() -> Cannot retrieve PVSS System from the DB", -99999);
    return;
  }
  
  if(sysId == -1)
  {
    //nothing to be done
    return;
  }
  
  sql = "UPDATE FW_SYS_STAT_FSM_TYPE_OBJ_PARS SET VALID_UNTIL = SYSDATE WHERE VALID_UNTIL IS NULL AND TYPE_ID IN (SELECT ID FROM FW_SYS_STAT_FSM_TYPES WHERE VALID_UNTIL IS NULL AND SYSTEM_ID = " + sysId + ") AND TYPE_ID IN (SELECT TYPE_ID FROM FW_SYS_STAT_FSM_TYPE_OBJ_PARS WHERE VALID_UNTIL IS NULL)";
    
         
  if(g_fwInstallationSqlDebug)
    DebugN(sql);
    
  if(rdbExecuteSqlStatement(gFwInstallationDBConn, sql)) {
    DebugN("ERROR: fwInstallationFSMDB_removeTreeTypeObjParams() -> Could not execute the following SQL: " + sql); 
    fwException_raise(exception, "ERROR", "fwInstallationFSMDB_removeTreeTypeObjParams() -> Could not execute the following SQL: " + sql, -99999);
    return;
  }
  
  return; 
}

/*
void fwInstallationFSMDB_removeTreeTypeProperties(string topNode, dyn_string &exception)
{
  int sysId = -1;
  string sql;
    
  dyn_string exceptionInfo;
  dyn_dyn_mixed aRecords;
  int topNodeId = -1;
    
  fwInstallationFSMDB_isNodeRegistered(topNodeId, topNode, exception);
  
  if(dynlen(exception))
  {
    fwException_raise(exception, "ERROR", "fwInstallationFSMDB_removeTreeTypeProperties() -> Could not check if (sub)tree "+ topNode + " is registered in DB", -99999);
    return;
  }
  
  if(topNodeId < 0)
  {
    //Tree does not exist, nothing to be deleted
    return;
  }
  
  //Find out system id:
  if(fwInstallationDB_isSystemRegistered(sysId))
  {
    fwException_raise(exception, "ERROR", "fwInstallationFSMDB_removeTreeTypeProperties() -> Cannot retrieve PVSS Tree from the DB", -99999);
    return;
  }
  
  if(sysId == -1)
  {
    //nothing to be done
    return;
  }
  
  sql = "UPDATE FW_SYS_STAT_FSM_TYPES SET VALID_UNTIL = SYSDATE WHERE VALID_UNTIL IS NULL AND SYSTEM_ID = " + sysId;
    
         
  if(g_fwInstallationSqlDebug)
    DebugN(sql);
    
  if(rdbExecuteSqlStatement(gFwInstallationDBConn, sql)) {
    DebugN("ERROR: fwInstallationFSMDB_removeTreeTypeProperties() -> Could not execute the following SQL: " + sql); 
    fwException_raise(exception, "ERROR", "fwInstallationFSMDB_removeTreeTypeProperties() -> Could not execute the following SQL: " + sql, -99999);
    return;
  }
  
  return; 
}
*/

void fwInstallationFSMDB_removeTreeTypeProperties(string topNode, dyn_string &exception)
{
  
  dyn_dyn_mixed typesInfo;
  int sysId = -1;
  string sql;
  string str;
  
  //Find out system id:
  if(fwInstallationDB_isSystemRegistered(sysId))
  {
    fwException_raise(exception, "ERROR", "fwInstallationFSMDB_removeTreeTypeProperties() -> Cannot retrieve PVSS Tree from the DB", -99999);
    return;
  }
  
  if(sysId == -1)
  {
    //nothing to be done
    return;
  }
  
  //Find out the FSM types used in the tree:
  fwInstallationFSMDB_getTreeTypes(topNode, typesInfo, exception);
  
  if(dynlen(exception))
  {
    fwException_raise(exception, "ERROR", "fwInstallationFSMDB_removeTreeTypeProperties() -> Could not read types from DB for tree: " + topNode, -99999);
    return;
  }
  
  if(dynlen(typesInfo)<= 0)
    return; //Nothing to be done.
  
  for(int i = 1; i <= (dynlen(typesInfo)-1); i++)
  {
    str = str + "\'"+ typesInfo[i][FW_INST_FSM_TYPE_NAME] + "\',";
  }
  
  str = str + "\'" + typesInfo[dynlen(typesInfo)][FW_INST_FSM_TYPE_NAME] + "\'";
  
  sql = "DELETE FW_SYS_STAT_FSM_TYPES WHERE NAME IN ("+str+ ") AND SYSTEM_ID = " + sysId;
         
  if(g_fwInstallationSqlDebug)
    DebugN(sql);
    
  if(rdbExecuteSqlStatement(gFwInstallationDBConn, sql)) {
    DebugN("ERROR: fwInstallationFSMDB_removeTreeTypeProperties() -> Could not execute the following SQL: " + sql); 
    fwException_raise(exception, "ERROR", "fwInstallationFSMDB_removeTreeTypeProperties() -> Could not execute the following SQL: " + sql, -99999);
    return;
  }
  /*
  int sysId = -1;
  string sql;
    
  dyn_string exceptionInfo;
  dyn_dyn_mixed aRecords;
  int topNodeId = -1;
    
  fwInstallationFSMDB_isNodeRegistered(topNodeId, topNode, exception);
  
  if(dynlen(exception))
  {
    fwException_raise(exception, "ERROR", "fwInstallationFSMDB_removeTreeTypeProperties() -> Could not check if (sub)tree "+ topNode + " is registered in DB", -99999);
    return;
  }
  
  if(topNodeId < 0)
  {
    //Tree does not exist, nothing to be deleted
    return;
  }
  
  //Find out system id:
  if(fwInstallationDB_isSystemRegistered(sysId))
  {
    fwException_raise(exception, "ERROR", "fwInstallationFSMDB_removeTreeTypeProperties() -> Cannot retrieve PVSS Tree from the DB", -99999);
    return;
  }
  
  if(sysId == -1)
  {
    //nothing to be done
    return;
  }
  
  sql = "DELETE FW_SYS_STAT_FSM_TYPES WHERE SYSTEM_ID = " + sysId;
         
  if(g_fwInstallationSqlDebug)
    DebugN(sql);
    
  if(rdbExecuteSqlStatement(gFwInstallationDBConn, sql)) {
    DebugN("ERROR: fwInstallationFSMDB_removeTreeTypeProperties() -> Could not execute the following SQL: " + sql); 
    fwException_raise(exception, "ERROR", "fwInstallationFSMDB_removeTreeTypeProperties() -> Could not execute the following SQL: " + sql, -99999);
    return;
  }
  */
  return; 
}

void fwInstallationFSMDB_isTypeStateRegistered(int &id, string state, string type, dyn_string &exception)
{
  string sql;
  dyn_string exceptionInfo;
  dyn_dyn_mixed aRecords;
  
  if(type == "")
  {
    fwException_raise(exception, "ERROR", "fwInstallationFSMDB_isTypeRegistered() -> Empty FSM type passed to function", -99999);
    return;
  } 

  if(fwInstallationDB_connect() != 0)
  {
    fwException_raise(exception, "ERROR", "fwInstallationFSMDB_isTypeRegistered() -> Could not connect to DB", -99999);
    return;
  }
      
  sql = "SELECT S.ID FROM FW_SYS_STAT_FSM_STATES S, FW_SYS_STAT_FSM_TYPES T WHERE T.NAME = \'" + type +"\' AND T.valid_until IS NULL AND S.VALID_UNTIL IS NULL AND S.NAME = \'" +  state + "\' AND T.ID = S.TYPE_ID";
         
  if(g_fwInstallationSqlDebug)
    DebugN(sql);
  
  if(fwInstallationDB_executeDBQuery(sql, aRecords) != 0)
  {
    DebugN("ERROR: fwInstallation_isTypeRegistered() -> Could not execute the following SQL query: " + sql);
    fwException_raise(exception, "ERROR", "fwInstallationFSMDB_isTypeRegistered() -> Could not execute the following SQL query: " + sql, -99999);
    return;
  }  

  if(dynlen(aRecords) > 0) {   
    if(g_fwInstallationVerbose)
      DebugN("INFO: fwInstallationFSMDB_isTypeRegistered() -> FSM type already registered in the DB: ", aRecords);
      
    id = aRecords[1][1];
  }
  else{
    if(g_fwInstallationVerbose)
      DebugN("INFO: fwInstallationDB_isTypeRegistered() -> FSM type not yet registered in the DB");
    
    id = -1;
  }
  
  return; 
}    

void fwInstallationFSMDB_isTypeRegistered(int &id, string type, dyn_string &exception)
{
  string sql;
  dyn_string exceptionInfo;
  dyn_dyn_mixed aRecords;
  
  if(type == "")
  {
    fwException_raise(exception, "ERROR", "fwInstallationFSMDB_isTypeRegistered() -> Empty FSM type passed to function", -99999);
    return;
  } 

  if(fwInstallationDB_connect() != 0)
  {
    fwException_raise(exception, "ERROR", "fwInstallationFSMDB_isTypeRegistered() -> Could not connect to DB", -99999);
    return;
  }
      
  sql = "SELECT ID FROM FW_SYS_STAT_FSM_TYPES WHERE NAME = \'" + type +"\' AND valid_until IS NULL" ;
         
  if(g_fwInstallationSqlDebug)
    DebugN(sql);
  
  if(fwInstallationDB_executeDBQuery(sql, aRecords) != 0)
  {
    DebugN("ERROR: fwInstallation_isTypeRegistered() -> Could not execute the following SQL query: " + sql);
    fwException_raise(exception, "ERROR", "fwInstallationFSMDB_isTypeRegistered() -> Could not execute the following SQL query: " + sql, -99999);
    return;
  }  

  if(dynlen(aRecords) > 0) {   
    if(g_fwInstallationVerbose)
      DebugN("INFO: fwInstallationFSMDB_isTypeRegistered() -> FSM type already registered in the DB: ", aRecords);
      
    id = aRecords[1][1];
  }
  else{
    if(g_fwInstallationVerbose)
      DebugN("INFO: fwInstallationDB_isTypeRegistered() -> FSM type not yet registered in the DB");
    
    id = -1;
  }
  
  return; 
}    


//Nodes:
void fwInstallationFSMDB_isNodeRegistered(int &id, string node, dyn_string &exception)
{
  int sysId = -1;
  string sql;
  dyn_string exceptionInfo;
  dyn_dyn_mixed aRecords;
  
  if(node == "")
  {
    fwException_raise(exception, "ERROR", "fwInstallationFSMDB_isNodeRegistered() -> Empty FSM node name passed to function", -99999);
    return;
  } 

  //resolve system id from db:
  if(fwInstallationDB_isSystemRegistered(sysId))
  {
    fwException_raise(exception, "ERROR", "fwInstallationFSMDB_isNodeRegistered() -> Could not resolve system id from DB: " + getSystemName(), -99999);
    return;
  }
  
  if(sysId < 0)
  {
    fwException_raise(exception, "ERROR", "fwInstallationFSMDB_isNodeRegistered() -> PVSS system not yet registered in the DB: " + getSystemName(), -99999);
    return;
  }
  
  sql = "SELECT ID FROM FW_SYS_STAT_FSM_NODES WHERE valid_until IS NULL AND NAME = \'" + node +"\' AND TYPE_ID IN (SELECT ID FROM FW_SYS_STAT_FSM_TYPES WHERE VALID_UNTIL IS NULL AND SYSTEM_ID = " + sysId + ")";
         
  if(g_fwInstallationSqlDebug)
    DebugN(sql);
  
  if(fwInstallationDB_executeDBQuery(sql, aRecords) != 0)
  {
    DebugN("ERROR: fwInstallation_isNodeRegistered() -> Could not execute the following SQL query: " + sql);
    fwException_raise(exception, "ERROR", "fwInstallationFSMDB_isNodeRegistered() -> Could not execute the following SQL query: " + sql, -99999);
    return;
  }  
  
  if(dynlen(aRecords) > 0) 
    id = aRecords[1][1];
  else
    id = -1;
  
  return; 
}


fwInstallationFSMDB_getTreeNodeUserData(string topNode, dyn_dyn_mixed &info, dyn_string &exception)
{
  string sql;
  dyn_dyn_mixed aRecords;
  int sysId = -1;
  int topNodeId = -1;
    
  fwInstallationFSMDB_isNodeRegistered(topNodeId, topNode, exception);
  
  if(dynlen(exception))
  {
    fwException_raise(exception, "ERROR", "fwInstallationFSMDB_getTreeNodeUserData() -> Could not check if (sub)tree "+ topNode + " is registered in DB", -99999);
    return;
  }
  
  if(topNodeId < 0)
  {
    fwException_raise(exception, "ERROR", "fwInstallationFSMDB_getTreeNodeUserData() -> (sub)tree " + topNode + " is not registered in DB", -99999);
    return;
  }
    
  if(fwInstallationDB_isSystemRegistered(sysId) != 0)
  {
    fwException_raise(exception, "ERROR", "fwInstallationFSMDB_getTreeNodeUserData() -> Could not check if local system is registered in DB", -99999);
    return;
  }
  
  if(sysId <= 0)
  {
    fwException_raise(exception, "ERROR", "fwInstallationFSMDB_getTreeNodeUserData() -> Local system is not registered in DB", -99999);
    return;
  }
  
  sql = "SELECT NODE_ID, DATA FROM FW_SYS_STAT_FSM_NODE_USERDATA WHERE VALID_UNTIL IS NULL AND NODE_ID IN (SELECT ID FROM FW_SYS_STAT_FSM_NODES WHERE VALID_UNTIL IS NULL AND TYPE_ID IN (SELECT ID FROM FW_SYS_STAT_FSM_TYPES WHERE VALID_UNTIL IS NULL AND SYSTEM_ID = " + sysId + ")) ORDER BY NODE_ID" ;
         
  if(g_fwInstallationSqlDebug)
    DebugN(sql);
  
  if(fwInstallationDB_executeDBQuery(sql, aRecords) != 0)
  {
    DebugN("ERROR: fwInstallationFSMDB_getTreeNodeUserData() -> Could not execute the following SQL query: " + sql);
    fwException_raise(exception, "ERROR", "fwInstallationFSMDB_getTreeNodeUserData() -> Could not execute the following SQL query: " + sql, -99999);
    return;
  }  

  info = aRecords;  
    
  return;   
}


void fwInstallationFSMDB_setTreeNodeProperties(dyn_dyn_mixed info, dyn_string &exception)
{
  int sysId = -1;
  string sql;
    
  string node;
  string type;
  string device;
  int isCu;
  int typeId = -1;
    
  //Find out system id:
  if(fwInstallationDB_isSystemRegistered(sysId))
  {
    fwException_raise(exception, "ERROR", "fwInstallationFSMDB_setTreeNodeProperties() -> Cannot retrieve PVSS System from the DB", -99999);
    return;
  }
  
  if(sysId == -1)
  {
    fwException_raise(exception, "ERROR", "fwInstallationFSMDB_setTreeNodeProperties() -> System: " + getSystemName() + " not yet registered in DB. Aborting...", -99999);
    return;
  }
  
  for(int i =1; i <= dynlen(info); i++)
  {  
    //find out type id:
    node = info[i][FW_INST_FSM_NODE_NAME];
    type = info[i][FW_INST_FSM_NODE_TYPE];
    
    fwInstallationFSMDB_isTypeRegistered(typeId, type, exception);
    
    if(dynlen(exception))
      continue;
    
    if(typeId == -1)
    {
      fwException_raise(exception, "ERROR", "fwInstallationFSMDB_setTreeNodeProperties() -> FSM Type: " + type + " not registered in DB. Skipping node: " + node, -99999);
      continue;
    }    
    
    device = info[i][FW_INST_FSM_NODE_DEVICE];
    isCu = info[i][FW_INST_FSM_NODE_CU];
    
    sql = "INSERT INTO FW_SYS_STAT_FSM_NODES(ID, NAME, TYPE_ID, DEVICE, IS_CU) VALUES (FW_SYS_STAT_FSM_NODES_SQ.NEXTVAL, \'" +
            node + "\', "+ typeId + ", \'" + device + "\', " + isCu + ")";
    
         
    if(g_fwInstallationSqlDebug)
      DebugN(sql);
    
    if(rdbExecuteSqlStatement(gFwInstallationDBConn, sql)) {
      DebugN("ERROR: fwInstallationFSMDB_setTreeNodeProperties() -> Could not execute the following SQL: " + sql); 
      fwException_raise(exception, "ERROR", "fwInstallationFSMDB_setTreeNodeProperties() -> Could not execute the following SQL: " + sql, -99999);
      continue;
    }
  }
  
  return; 
}


void fwInstallationFSMDB_removeTreeNodeProperties(string topNode, dyn_string &exception)
{
  int sysId = -1;
  string sql;
  int topNodeId = -1;
    
  fwInstallationFSMDB_isNodeRegistered(topNodeId, topNode, exception);
  
  if(dynlen(exception))
  {
    fwException_raise(exception, "ERROR", "fwInstallationFSMDB_removeTreeNodeProperties() -> Could not check if (sub)tree "+ topNode + " is registered in DB", -99999);
    return;
  }
  
  if(topNodeId < 0)
  {
    //Tree does not exist, nothing to be deleted
    return;
  }
      
  //Find out system id:
  if(fwInstallationDB_isSystemRegistered(sysId))
  {
    fwException_raise(exception, "ERROR", "fwInstallationFSMDB_removeTreeNodeProperties() -> Cannot retrieve PVSS System from the DB", -99999);
    return;
  }
  
  if(sysId == -1)
  {
    //nothing to be done
    return;
  }
  
  sql = "UPDATE FW_SYS_STAT_FSM_NODES SET VALID_UNTIL = SYSDATE WHERE VALID_UNTIL IS NULL AND TYPE_ID IN (SELECT ID FROM FW_SYS_STAT_FSM_TYPES WHERE VALID_UNTIL IS NULL AND SYSTEM_ID = " + sysId + ")";
    
         
  if(g_fwInstallationSqlDebug)
    DebugN(sql);
    
  if(rdbExecuteSqlStatement(gFwInstallationDBConn, sql)) {
    DebugN("ERROR: fwInstallationFSMDB_removeTreeNodeProperties() -> Could not execute the following SQL: " + sql); 
    fwException_raise(exception, "ERROR", "fwInstallationFSMDB_removeTreeNodeProperties() -> Could not execute the following SQL: " + sql, -99999);
    return;
  }
  
  return; 
}


//---
void fwInstallationFSMDB_setTreeNodeUserData(dyn_dyn_mixed info, dyn_string &exception)
{
  int sysId = -1;
  int nodeId = -1;
  string sql;
    
  string node;
  dyn_string value;
    
  //Find out system id:
  if(fwInstallationDB_isSystemRegistered(sysId))
  {
    fwException_raise(exception, "ERROR", "fwInstallationFSMDB_setTreeNodeUserData() -> Cannot retrieve PVSS System from the DB", -99999);
    return;
  }
  
  if(sysId == -1)
  {
    fwException_raise(exception, "ERROR", "fwInstallationFSMDB_setTreeNodeUserData() -> System: " + getSystemName() + " not yet registered in DB. Aborting...", -99999);
    return;
  }
  
  for(int i =1; i <= dynlen(info); i++)
  {  
    //find out type id:
    node = info[i][FW_INST_FSM_USERDATA_NODE_NAME];
    value = info[i][FW_INST_FSM_USERDATA_VALUE];
    
    fwInstallationFSMDB_isNodeRegistered(nodeId, node, exception);
    
    if(dynlen(exception))
      continue;
    
    if(nodeId == -1)
    {
      fwException_raise(exception, "ERROR", "fwInstallationFSMDB_setTreeNodeUserData() -> FSM Node: " + node + " not registered in DB. Skipping node: " + node, -99999);
      continue;
    }    
    
    for(int k = 1; k <= dynlen(value); k++)
    {
      sql = "INSERT INTO FW_SYS_STAT_FSM_NODE_USERDATA(ID, NODE_ID, DATA) VALUES (FW_SYS_STAT_FSM_NODE_USER_SQ.NEXTVAL, " +
              nodeId + ", \'"+ value[k] + "\')";
    
         
      if(g_fwInstallationSqlDebug)
        DebugN(sql);
    
      if(rdbExecuteSqlStatement(gFwInstallationDBConn, sql)) {
        DebugN("ERROR: fwInstallationFSMDB_setTreeNodeUserData() -> Could not execute the following SQL: " + sql); 
        fwException_raise(exception, "ERROR", "fwInstallationFSMDB_setTreeNodeUserData() -> Could not execute the following SQL: " + sql, -99999);
        continue;
      }
    }
  }
  
  return; 
}


void fwInstallationFSMDB_removeTreeNodeUserData(string topNode, dyn_string &exception)
{
  int sysId = -1;
  string sql;
  int topNodeId = -1;
    
  fwInstallationFSMDB_isNodeRegistered(topNodeId, topNode, exception);
  
  if(dynlen(exception))
  {
    fwException_raise(exception, "ERROR", "fwInstallationFSMDB_removeTreeNodeUserData() -> Could not check if (sub)tree "+ topNode + " is registered in DB", -99999);
    return;
  }
  
  if(topNodeId < 0)
  {
    //Tree does not exist, nothing to be deleted
    return;
  }
  
  //Find out system id:
  if(fwInstallationDB_isSystemRegistered(sysId))
  {
    fwException_raise(exception, "ERROR", "fwInstallationFSMDB_removeTreeNodeUserData() -> Cannot retrieve PVSS System from the DB", -99999);
    return;
  }
  
  if(sysId == -1)
  {
    //nothing to be done
    return;
  }
  
  sql = "UPDATE FW_SYS_STAT_FSM_NODE_USERDATA SET VALID_UNTIL = SYSDATE WHERE VALID_UNTIL IS NULL AND NODE_ID IN (SELECT ID FROM FW_SYS_STAT_FSM_NODES WHERE VALID_UNTIL IS NULL AND TYPE_ID IN (SELECT ID FROM FW_SYS_STAT_FSM_TYPES WHERE VALID_UNTIL IS NULL AND  SYSTEM_ID = " + sysId + "))";
    
         
  if(g_fwInstallationSqlDebug)
    DebugN(sql);
    
  if(rdbExecuteSqlStatement(gFwInstallationDBConn, sql)) {
    DebugN("ERROR: fwInstallationFSMDB_removeTreeNodeUserData() -> Could not execute the following SQL: " + sql); 
    fwException_raise(exception, "ERROR", "fwInstallationFSMDB_removeTreeNodeUserData() -> Could not execute the following SQL: " + sql, -99999);
    return;
  }
  
  return; 
}


void fwInstallationFSMDB_getNodeChildren(string node, dyn_string &children, dyn_string &exception)
{
  int id = -1;
  string sql;    
  dyn_string exceptionInfo;
  dyn_dyn_mixed aRecords;
  
  fwInstallationFSMDB_isNodeRegistered(id, node, exception);
  if(dynlen(exception))
    return;
  
  if(id == -1)
  {
    fwException_raise(exception, "ERROR", "fwInstallationFSMDB_getNodeChildren() -> Node: " + node + " not yet registered in DB. Aborting...", -99999);
    return;
  }

  sql = "SELECT NAME FROM FW_SYS_STAT_FSM_NODES WHERE VALID_UNTIL IS NULL AND ID IN (SELECT NODE_ID FROM FW_SYS_STAT_FSM_HIERARCHIES WHERE PARENT_NODE_ID = " + id + " AND VALID_UNTIL IS NULL)";
           
//  if(g_fwInstallationSqlDebug)
    DebugN(sql);
  
  if(fwInstallationDB_executeDBQuery(sql, aRecords) != 0)
  {
    DebugN("ERROR: fwInstallationFSMDB_getNodeChildren() -> Could not execute the following SQL query: " + sql);
    fwException_raise(exception, "ERROR", "fwInstallationFSMDB_getNodeRegistered() -> Could not execute the following SQL query: " + sql, -99999);
    return;
  }  

  if(dynlen(aRecords))
    children = aRecords[1];
    
  return; 
}

void fwInstallationFSMDB_getNodeParent(string node, string &parent, dyn_string &exception)
{
  int id = -1;
  string sql;    
  dyn_string exceptionInfo;
  dyn_dyn_mixed aRecords;
  
  fwInstallationFSMDB_isNodeRegistered(id, node, exception);
  if(dynlen(exception))
    return;
  
  if(id == -1)
  {
    fwException_raise(exception, "ERROR", "fwInstallationFSMDB_getNodeParent() -> Node: " + node + " not yet registered in DB. Aborting...", -99999);
    return;
  }

  sql = "SELECT NAME FROM FW_SYS_STAT_FSM_NODES WHERE VALID_UNTIL IS NULL AND ID = (SELECT PARENT_NODE_ID FROM FW_SYS_STAT_FSM_HIERARCHIES WHERE NODE_ID = " + id + " AND VALID_UNTIL IS NULL)";
           
  if(g_fwInstallationSqlDebug)
    DebugN(sql);
  
  if(fwInstallationDB_executeDBQuery(sql, aRecords) != 0)
  {
    DebugN("ERROR: fwInstallationFSMDB_getNodeParent() -> Could not execute the following SQL query: " + sql);
    fwException_raise(exception, "ERROR", "fwInstallationFSMDB_getNodeParent() -> Could not execute the following SQL query: " + sql, -99999);
    return;
  }  

  if(dynlen(aRecords))
    parent = aRecords[1][1];
    
  return; 
}


void fwInstallationFSMDB_setNodeParent(string node, string parent, dyn_string &exception)
{
  int id = -1;
  int parentId = -1;
  string sql;
  
  fwInstallationFSMDB_isNodeRegistered(id, node, exception);
  if(dynlen(exception))
  {
    fwException_raise(exception, "ERROR", "fwInstallationFSMDB_setNodeParent() -> Could not check if node is registered in DB: " + node, -9999);
    return;
  } 
  
  fwInstallationFSMDB_isNodeRegistered(parentId, parent, exception);
  if(dynlen(exception))
  {
    fwException_raise(exception, "ERROR", "fwInstallationFSMDB_setNodeParent() -> Could not check if parent node is registered in DB: " + parent, -9999);
    return;
  } 
  
  if(id == -1)
  {
    fwException_raise(exception, "ERROR", "fwInstallationFSMDB_setNodeParent() -> Node not yet registered in DB: " + node, -9999);
    return;
  }
  else if(parentId == -1)
  {
    fwException_raise(exception, "ERROR", "fwInstallationFSMDB_setNodeParent() -> Parent node not yet registered in DB: " + parent, -9999);
    return;
  }
  
  fwInstallationFSMDB_deleteNodeParent(node, exception);
  
  
  sql = "INSERT INTO FW_SYS_STAT_FSM_HIERARCHIES(NODE_ID, PARENT_NODE_ID) VALUES("+id+", "+parentId+")";
  
  if(g_fwInstallationSqlDebug)
    DebugN(sql);
    
  if(rdbExecuteSqlStatement(gFwInstallationDBConn, sql)) {
    DebugN("ERROR: fwInstallationFSMDB_setNodeParent() -> Could not execute the following SQL: " + sql); 
    fwException_raise(exception, "ERROR", "fwInstallationFSMDB_setNodeChildren() -> Could not execute the following SQL: " + sql, -99999);
    return;
  }
  
  return; 
}


void fwInstallationFSMDB_setNodeChildren(string node, dyn_string children, dyn_string &exception)
{
  int id = -1;
  int childId = -1;
  string sql;
  
  fwInstallationFSMDB_isNodeRegistered(id, node, exception);
  if(dynlen(exception))
  {
    fwException_raise(exception, "ERROR", "fwInstallationFSMDB_setNodeParent() -> Could not check if node is registered in DB: " + node, -9999);
    return;
  } 
  
  if(id == -1)
  {
    fwException_raise(exception, "ERROR", "fwInstallationFSMDB_setNodeChildren() -> Node not yet registered in DB: " + node, -9999);
    return;
  }

  fwInstallationFSMDB_deleteNodeChildren(node, exception);
  if(dynlen(exception))
    return;
  
  for(int i = 1; i <= dynlen(children); i++)
  {
    childId = -1;
    fwInstallationFSMDB_isNodeRegistered(childId, children[i], exception);
    if(dynlen(exception))
    {
      fwException_raise(exception, "ERROR", "fwInstallationFSMDB_setNodeChildren() -> Could not check if child node is registered in DB: " + children[i], -9999);
      return;
    }
     
  
    if(childId == -1)
    {
      fwException_raise(exception, "ERROR", "fwInstallationFSMDB_setNodeParent() -> Child node not yet registered in DB: " + children[i], -9999);
      return;
    }

    sql = "INSERT INTO FW_SYS_STAT_FSM_HIERARCHIES(NODE_ID, PARENT_NODE_ID) VALUES("+childId+", "+id+")";
  
    if(g_fwInstallationSqlDebug)
      DebugN(sql);
    
    if(rdbExecuteSqlStatement(gFwInstallationDBConn, sql)) {
      DebugN("ERROR: fwInstallationFSMDB_setNodeChildren() -> Could not execute the following SQL: " + sql); 
      fwException_raise(exception, "ERROR", "fwInstallationFSMDB_setNodeChildren() -> Could not execute the following SQL: " + sql, -99999);
      return;
    }
  }
  return; 
}


void fwInstallationFSMDB_deleteNodeParent(string node, dyn_string &exception)
{
  int id = -1;
  string sql;
    
  fwInstallationFSMDB_isNodeRegistered(id, node, exception);
  if(dynlen(exception))
    return;
  
  if(id == -1)
  {
    fwException_raise(exception, "ERROR", "fwInstallationFSMDB_deleteNodeParent() -> Node: " + node + " not yet registered in DB. Aborting...", -99999);
    return;
  }
  
  sql = "UPDATE FW_SYS_STAT_FSM_HIERARCHIES SET VALID_UNTIL = SYSDATE WHERE NODE_ID = " + id;
           
  if(g_fwInstallationSqlDebug)
    DebugN(sql);
    
  if(rdbExecuteSqlStatement(gFwInstallationDBConn, sql)) {
    DebugN("ERROR: fwInstallationFSMDB_deleteNodeParent() -> Could not execute the following SQL: " + sql); 
    fwException_raise(exception, "ERROR", "fwInstallationFSMDB_deleteNodeParent() -> Could not execute the following SQL: " + sql, -99999);    
    return;
  }
  
  return; 
}

void fwInstallationFSMDB_deleteNodeChildren(string node, dyn_string &exception)
{
  int id = -1;
  string sql;
    
  fwInstallationFSMDB_isNodeRegistered(id, node, exception);
  if(dynlen(exception))
    return;
  
  if(id == -1)
  {
    fwException_raise(exception, "ERROR", "fwInstallationFSMDB_deleteNodeChildren() -> Node: " + node + " not yet registered in DB. Aborting...", -99999);
    return;
  }
  
  sql = "UPDATE FW_SYS_STAT_FSM_HIERARCHIES SET VALID_UNTIL = SYSDATE WHERE PARENT_NODE_ID = " + id;
           
  if(g_fwInstallationSqlDebug)
    DebugN(sql);
    
  if(rdbExecuteSqlStatement(gFwInstallationDBConn, sql)) {
    DebugN("ERROR: fwInstallationFSMDB_deleteNodeChildren() -> Could not execute the following SQL: " + sql); 
    fwException_raise(exception, "ERROR", "fwInstallationFSMDB_deleteNodeChildren() -> Could not execute the following SQL: " + sql, -99999);    
    return;
  }
  
  return; 
}

int fwInstallationFSMDB_getHierarchy(string node, dyn_dyn_mixed &hierarchyInfo, dyn_string &exception)
{
  string id;
  dyn_dyn_mixed aRecords;
  string sql;
  
  dynClear(aRecords);

  if(node == "") {
    fwException_raise(exception, "ERROR", "fwInstallationFSMDB_getHierarchy() -> Empty top node of the hierarchy passed to function");
    return;
  }

  fwInstallationFSMDB_isNodeRegistered(id, node, exception);
  if(dynlen(exception))
    return;

  if(id == -1)
  {
    fwException_raise(exception, "ERROR", "fwInstallationFSMDB_getHierarchy() -> Top node of the hierarchy not registered in the DB: " + node);
    return;
  }

  sql = "select pn.name parent_name, n.name from fw_sys_stat_fsm_nodes n, fw_sys_stat_fsm_nodes pn, fw_sys_stat_fsm_hierarchies h " + 
        "where pn.valid_until is null and n.valid_until is null and pn.id = h.parent_node_id and n.id = h.node_id order by pn.id desc, pn.name";

  if(g_fwInstallationSqlDebug)
      DebugN(sql);

  if(fwInstallationDB_executeDBQuery(sql, aRecords) != 0)
  {
    DebugN("ERROR: fwInstallationFSMDB_getHierarchy() -> Could not execute the following SQL query: " + sql);
    return -1;
  }

  hierarchyInfo = aRecords;
  
  return;
}
