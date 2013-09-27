/*
  Simple FSM tree cache library
  Authors: Manuel FAHRER (manuel.fahrer@cern.ch), Lorenzo MASETTI (lorenzo.masetti@cern.ch) 
  Contact: Lorenzo MASETTI (lorenzo.masetti@cern.ch)
*/

/*

  To create the cache for your system use these 2 functions:


  // this reads all the information from the FSM and writes it in a data point of type treecCache

  treeCache_create(topNode, makeDynString(), exceptionInfo); 

  // this creates the treeCache_included datapoints and sets the dp functions (connected to the internal FSM dps)
  
  treeCache_initIncluded(topNode);

*/

// the node given to the first call of treeCache_start(...) will overwrite this variable
string treeCache_defaultNode = "";

// please do not touch the delimiters without any strong reason!
const string treeCache_delimiter1 = "\n"; // separates data of different nodes in data entry
const string treeCache_delimiter2 = "\t"; // separates array elements in a flattened string
const int treeCache_CUtimeout = 6; // number of seconds to wait after CU take/release for CU included reinitialization
const string treeCache_defaultNodeDp = "_treeCache_defaultNode";
const string treeCache_includedDp = "treeCache_included.";

/*
  Simulate a 2-fold map with a dyn_dyn_string
  and two dyn_strings containing the sets of keys.
  This is supposed to save a lot of memory compared to PVSS maps
  (because of possible overhead for mapping administration in PVSS)
*/
global dyn_dyn_string  treeCache_data;
global dyn_string      treeCache_nodes;
global dyn_string      treeCache_items;
global dyn_string      treeCache_types;
global int            treeCache_isLogical;

global mapping         treeCache_topNodesCaches;



global dyn_string      treeCache_exc;
global bool            treeCache_dataInMemory = false;
global mapping         treeCache_localTopNodes;
global string          treeCache_topNode;
global mapping         treeCache_parentSystems;
global int             treeCache_debugLevel = 4;

global mapping         treeCache_includedCache;
global string          treeCache_userFunctionGetType;

/*

  public functions start here

*/


/* 
   Wrapper functions to access all cached data.
   'node' paramter may also contain a nodeIdx number. In this case 'isIdx' must be set to 'true'
*/

// system name where the FSM node is located (with terminal ":")
string treeCache_getSystem(string node,bool isIdx=false) {return _treeCache_getData("system",node,isIdx);}

// FSM object type
string treeCache_getType(string node,bool isIdx=false) {return _treeCache_getData("type",node,isIdx);}

// FSM object type index
int treeCache_getTypeIdx(string node,bool isIdx=false) {return (int)_treeCache_getData("typeIdx",node,isIdx);}

// FSM unit type: CU, LU or DU
string treeCache_getUnit(string node,bool isIdx=false) {return _treeCache_getData("unit",node,isIdx);}

// FSM unit type idx: 1, 0 or 2 (corresponding to above listed order)
int treeCache_getUnitIdx(string node,bool isIdx=false) {return (int)_treeCache_getData("unitIdx",node,isIdx);}

// FSM unit type idx for all children of a node
dyn_int treeCache_getChildrenUnitIdx(string node,bool isIdx=false) {
  dyn_int indices = treeCache_getChildrenI(node,isIdx);
  dyn_int unitIndices;
  for ( int i = 1 ; i <= dynlen(indices) ; i ++ ) {
    unitIndices[i] = treeCache_getUnitIdx(indices[i],true);
  }
  return unitIndices;
}

dyn_string treeCache_getChildren(string node,bool isIdx=false) {
  dyn_int indices = treeCache_getChildrenI(node,isIdx);
  dyn_string children;
  for ( int i = 1 ; i <= dynlen(indices) ; i ++ ) {
    children[i] = treeCache_nodes[indices[i]];
  }
  return children;
}

// all children node indices
dyn_int treeCache_getChildrenI(string node,bool isIdx=false) {return _treeCache_unflatten(_treeCache_getData("children",node,isIdx),treeCache_delimiter2);}

// parent node name
string treeCache_getParent(string node,bool isIdx=false) {return _treeCache_getData("parent",node,isIdx);}

// parent node index
int treeCache_getParentI(string node,bool isIdx=false) {return _treeCache_getData("parentIdx",node,isIdx);}

// get level in hierarchy (starting from 1 at top node)
int treeCache_getLevel(string node,bool isIdx=false) {return _treeCache_getData("level",node,isIdx);}

// get level in system hierarchy (starting from 1 at top level system)
int treeCache_getSystemLevel(string node,bool isIdx=false) {return _treeCache_getData("systemLevel",node,isIdx);}

// get level in system (starting from 1 at top node in system)
int treeCache_getLevelInSystem(string node,bool isIdx=false) {return _treeCache_getData("levelInSystem",node,isIdx);}

// get number of nodes below specified node
int treeCache_getNumberOfNodesBelow(string node,bool isIdx=false) {return _treeCache_getData("NnodesBelow",node,isIdx);}

// get number of tree levels below specified node
int treeCache_getNumberOfLevelsBelow(string node,bool isIdx=false) {return _treeCache_getData("NlevelsBelow",node,isIdx);}

// get number of system levels below specified node
int treeCache_getNumberOfSystemsBelow(string node,bool isIdx=false) {return _treeCache_getData("NsystemsBelow",node,isIdx);}

// get number of node levels below specified node in corresponding system
int treeCache_getNumberOfLevelsBelowInSystem(string node,bool isIdx=false) {return _treeCache_getData("NlevelsInSystemBelow",node,isIdx);}

// get fsm dev dp
string treeCache_getFsmDevDp(string node,bool isIdx=false) {return _treeCache_getData("devDp",node,isIdx);}

// get fsm internal dp
string treeCache_getFsmInternalDp(string node,bool isIdx=false) {return _treeCache_getData("intDp",node,isIdx);}

// get fsm user label
string treeCache_getFsmUserLabel(string node,bool isIdx=false) {
  // in the logical this is not cached
  if (! dynContains(treeCache_items,"userLabel")) {
    if (isIdx) return  treeCache_getNode(node);
    else return node;
  }
  return _treeCache_getData("userLabel",node,isIdx);
}

// is node visible in fw FSM UI ?
bool treeCache_isVisible(string node,bool isIdx=false) {
  // in the logical this is not cached
  if (! dynContains(treeCache_items,"visible")) {
    return true;
  }
  return _treeCache_getData("visible",node,isIdx);}

int treeCache_isLogical() {
  return treeCache_isLogical;
}


// get all fw Fsm UI visible children
//dyn_string treeCache_getVisibleChildren(string node,bool isIdx=false) {return _treeCache_unflatten(_treeCache_getData("visibleChildren",node,isIdx),treeCache_delimiter2);}
dyn_string treeCache_getVisibleChildren(string node,bool isIdx=false) {
  dyn_int indices = treeCache_getChildrenI(node,isIdx);
  dyn_string nodes;
  for ( int i = 1 ; i <= dynlen(indices) ; i ++ ) {
    if ( treeCache_isVisible(indices[i],true) ) {
      dynAppend(nodes,treeCache_nodes[indices[i]]);
    }
  }
  return nodes;
}


// is node existing?
bool treeCache_isNode(string node,bool isIdx=false) {return isIdx?((int)node<=dynlen(treeCache_nodes)):dynContains(treeCache_nodes,node);}

// get node name to given nodeIdx
string treeCache_getNode(int nodeIdx) {
  treeCache_getNodeIdx(nodeIdx,true); // check nodeIdx
  return treeCache_nodes[nodeIdx];
}

/* 
   Is node included or excluded?
*/
bool treeCache_getIncluded(string node,bool isIdx=false, bool use_cache = false) {
  treeCache_start();
  bool included;
  if (isIdx) node = treeCache_getNode(node);
  if (use_cache) {
    if (mappingHasKey(treeCache_includedCache, node)) return treeCache_includedCache[node];
  }
     
  string dp = treeCache_getIncludedDp(node);
  if ( ! dpExists(dp)) {
    treeCache_debug1("treeCache_getIncluded: WARNING Dp " + dp + " for inclusion does not exist for node " + node + ". Returning true!!!");
    return true;
  }
  dpGet(dp,included);
  if (use_cache) {
    treeCache_includedCache[node] = included; // in the case you use the cache but it was not initialized, just save this single value to the cache 
  }
  return included;
}

// NOTE: In a graph, the result of this function might NOT be unique:
// Only ONE possible path from node to the top will be returned !!!!
dyn_string treeCache_getAncestors(string node,bool isIdx=false) {
  treeCache_start();
  dyn_string list;
  int idx = treeCache_getNodeIdx(node,isIdx);
  while ( idx ) {
    dynAppend(list, treeCache_nodes[idx]);
    idx = treeCache_getParentI(idx,true);
  }
  return list;
}

void treeCache_clearIncludedCache() {
  mappingClear(treeCache_includedCache); 
}

void treeCache_initIncludedCache(string root, string dont_go_below_type="", bool isIdx = false) {
  mappingClear(treeCache_includedCache);
  treeCache_start();
  int nodeIdx = treeCache_getNodeIdx(root, isIdx);
  dyn_int stack = makeDynInt(nodeIdx);  
  dyn_int visited;
  dyn_string children; 
 
  while (dynlen(stack)>0) {
    nodeIdx = stack[dynlen(stack)];
    dynRemove(stack, dynlen(stack)); 
    dynAppend(visited, nodeIdx);
    if ((strlen(dont_go_below_type)==0) || (treeCache_getType(nodeIdx,true) != dont_go_below_type)) {
      children = treeCache_getChildrenI(nodeIdx, true);
      for (int i=1; i<= dynlen(children); i++) {
	dynAppend(stack,children[i]);         
      }
    }
  }
 
  dyn_string dps;
  for (int i=1; i<= dynlen(visited); i++) {
    if (strlen(treeCache_getType(visited[i], true))>0) { // not a "system node"
      dps[i] = treeCache_getIncludedDp(treeCache_getNode(visited[i]));
    }
  }
 
  dynSortAsc(dps);
  dyn_bool included;
  _treeCache_dpGetAll(dps,included);
  for (int i=1; i<= dynlen(included); i++) {
    treeCache_includedCache[treeCache_getNodeFromIncludedDp(dps[i])] = included[i];  
  }
  treeCache_debug2("Included cache initialized for " + dynlen(dps) + " nodes"); 
}

/* 
   @return true if in all the path from root to the node the nodes are included

   To use the cache you have to call treeCache_initIncludedCache before
*/
bool treeCache_isIncluded(string node, string root, bool cache = false) {
  dyn_string path = treeCache_getAncestors(node);
  //   DebugN("Path for " + node ,path);
  int index_root = dynContains(path, root);
  if (index_root == 0) return false;
   
  for (int i=1; i<= index_root-1; i++) {
    if (! treeCache_getIncluded(path[i],false,cache)) {
      // DebugN(node + " is excluded at the level of " + path[i]); 
      return false; 
    }
  } 
  return true;
}


/*
  Connect to inclusion of one node  
  callback will take parameters (string dp, bool included)
  To get the node use function treeCache_getNodeFromIncludedDp
*/
void treeCache_connectIncluded(string cb, string node, bool firstTime = false,bool isIdx=false) {
  if (isIdx) node = treeCache_getNode(node);
  dpConnect(cb, firstTime,treeCache_getIncludedDp(node));
}

string treeCache_getIncludedDp(string node, bool use_cached_information = true) { 
  // Version that does not need to load treeCache into memory in the fwFsmUser callback functions -- should not be needed anymore
  if (! treeCache_dataInMemory ) use_cached_information = false;
  if (! treeCache_isNode(node) ) use_cached_information = false;
  
  if (use_cached_information) {   
    if (treeCache_getUnit(node) == "CU") {        
      return treeCache_getSystem(node) +     
        "treeCache_included_"
        +    node + ".";
    } else {
        return treeCache_getFsmInternalDp(node) + ".mode.enabled";
    }
  } else {
    // if data is not in memory  i get the system with fw functions
    string internal;
     fwCU_getDp(node, internal);   
     if (dpExists(internal + "_FWM.fsm.currentState")) {
       return _treeCache_getSystemFromFw(node) +     
        "treeCache_included_"
        +    node + ".";   
       } else {
          return internal + ".mode.enabled"; 
       }
        
  }
  
}

string treeCache_getNodeFromIncludedDp(string dp) {
  if (dpTypeName(dp) == "treeCache_included") {
    dp = dpSubStr(dp,DPSUB_DP);
    strreplace(dp,"treeCache_included_","");
    return dp;  
  } else {
   dp = dpSubStr(dp,DPSUB_SYS_DP);
   int nodeIdx = dynContains(_treeCache_getAllData("intDp"), dp);
   if (nodeIdx>0) return treeCache_nodes[nodeIdx];
   else return "";    
  }
}

// Returns selected node information in special format.
// For details on the format, see _treeCache_composeNodeInfo
string treeCache_getNodeInfo(string  node, bool isIdx = false) {
  return _treeCache_composeNodeInfo(treeCache_getNodeIdx(node,isIdx),
				    treeCache_getUnit(node),
				    treeCache_getTypeIdx(node),
				    treeCache_getLevel(node));
}

// some functions to retreive data for all nodes collected in arrays
dyn_string treeCache_getAllNodes() {treeCache_start();return treeCache_nodes;}
dyn_string treeCache_getAllUnits() {return _treeCache_getAllData("unit");}
dyn_int    treeCache_getAllTypeIndices() {return (dyn_int)_treeCache_getAllData("typeIdx");}
dyn_string treeCache_getAllLevels() {return (dyn_int) _treeCache_getAllData("level");}


/*
 * this function gets the start and stop index to visit the node.
 * To visit the sub tree just do a for (int nodeIdx = start; nodeIdx <= stop; nodeIdx++) 
 * then to get the node name use treeCache_getNode(nodeIdx), to get other information use the standard functions
 * with nodeIdx = true
 */
void treeCache_getVisitIndexes(string node, int& start, int& stop, bool isIdx = false) {
  // Indexes are like that
  //   
  //                 1
  //               /   \
  //              2     7
  //            /  \     \
  //           3    4     8   
  //               /  \    \
  //              5    6    9
  //                        / \
  //                       10 11
  //
  //   So if i find the last descendent on the right i can start from the index of the root and loop until that index
  //  and i will visit 
  //  all the (sub) tree in depth-first order
                       
  treeCache_start();
  start = treeCache_getNodeIdx(node, isIdx);
 
  stop = start;
  dyn_int children;
  // find the last descendent on the right
  while (true)  {
    children = treeCache_getChildrenI(stop, true);
    if (dynlen(children) == 0) return;
    stop = children[dynlen(children)];
  }
    
}

dyn_int treeCache_getNodesToVisitBreadthFirst(string node, bool isIdx = false) {
  treeCache_start();
  int nodeIdx = treeCache_getNodeIdx(node, isIdx);
  dyn_int queue = makeDynInt(nodeIdx);
  dyn_int visited;
  while (dynlen(queue)>0) {
    nodeIdx = queue[1];
    dynRemove(queue, 1);     
    dynAppend(visited, nodeIdx);
    dynAppend(queue,treeCache_getChildrenI(nodeIdx, true));        
  }
  return visited;   
} 


/* This visits only the included nodes  (Depth First) */
dyn_int treeCache_getIncludedNodesToVisit(string node, string dont_go_below_type = "",bool isIdx = false, bool use_old_cache = false) {
  treeCache_start();
  if (! use_old_cache) treeCache_initIncludedCache(node, dont_go_below_type, isIdx);
  int nodeIdx = treeCache_getNodeIdx(node, isIdx);
  dyn_int stack = makeDynInt(nodeIdx);
  dyn_int visited;
  dyn_string children; 
 
  while (dynlen(stack)>0) {
    nodeIdx = stack[dynlen(stack)];
    dynRemove(stack, dynlen(stack)); 
    dynAppend(visited, nodeIdx);
    if (treeCache_getType(nodeIdx,true) != dont_go_below_type) {
      children = treeCache_getChildrenI(nodeIdx, true);
      for (int i=1; i<= dynlen(children); i++) {
	if (treeCache_getIncluded(children[i], true, true)) {
	  dynAppend(stack,children[i]);
	}
      }
    }
  }
  return visited;   
} 

void treeCache_getExcludedNodes(string node, dyn_string& excluded_nodes, dyn_bool& hasExcludedParent) {
  treeCache_start();
  treeCache_initIncludedCache(node);
  int start, stop;
  treeCache_getVisitIndexes(node,start,stop);
  dynClear(excluded_nodes); 
  for (int nodeIdx = start+1 /* dont' check node itself */; nodeIdx<= stop; nodeIdx++) {
    // Debug("Checking inclusion of " + treeCache_getNode(nodeIdx));
    if ( ! treeCache_getIncluded(nodeIdx,true, true) ) {
      if (strlen(treeCache_getType(nodeIdx,true))>0) dynAppend(excluded_nodes, treeCache_getNode(nodeIdx));
      //else DebugTN("Found strange node ",  nodeIdx, treeCache_getNode(nodeIdx));
      // DebugN("excluded");
    } else {
      //   DebugN("included");
    }
  }
  
  string parent;
  for (int i=1; i<= dynlen(excluded_nodes); i++) {
    parent = treeCache_getParent(excluded_nodes[i]);
    //DebugN("Checking if " + parent + " is included in " + node);
    if (parent == node) {
      hasExcludedParent[i] = false; 
    } else {
      hasExcludedParent[i] =(!  treeCache_isIncluded(parent, node, true));    
      // DebugN(hasExcludedParent[i]);
    }
  }
    
}


/*
  visits tree starting at node to get all device nodes of specified type. You may want to use the wrapper function treeCache_getNodesOfTypeBelow (see next)
  
  @param node node where to start
  @param type given type
  @param nodes (out) returns the result
  @param only_included  - does not continue the search in the subtrees that are not included
  @param dont_go_below_type - does not continue the search below given type  
*/

void treeCache_getNodesOfType(string node,string type,dyn_string&nodes, bool only_included = false, string dont_go_below_type = "", bool use_old_cache= false) {
  treeCache_start();
  dynClear(nodes);

  if (only_included) {
    dyn_int indexes = treeCache_getIncludedNodesToVisit(node,dont_go_below_type, false,use_old_cache);

    int node;
    for (int i=1; i<= dynlen(indexes); i++) {
      node = indexes[i];
      if ( type == treeCache_getType(node,true) ) {
	dynAppend(nodes,treeCache_nodes[(int)node]);
      }  
    } 
  } else {
    int start, stop;     
    treeCache_getVisitIndexes(node, start, stop);
    for (int node = start; node <= stop; node++) {     
      if ( type == treeCache_getType(node,true) ) {
	dynAppend(nodes,treeCache_nodes[(int)node]);
      }
    }
  }
}

/*
  Wrapper to previous function
*/
dyn_string treeCache_getNodesOfTypeBelow(string node, string type, bool only_included = false, string dont_go_below_type = "", bool use_old_cache=false) {
  dyn_string nodes;  
  treeCache_getNodesOfType(node,type,nodes,only_included,dont_go_below_type, use_old_cache);
  return nodes;
}


void treeCache_display(string node, dyn_string& rows, bool show_devices_dp = false) {
  string type="";
  string sys;
  dyn_string children;
  treeCache_start();
  
  int start, stop;
  treeCache_getVisitIndexes(node, start, stop);
  string line;
  string node;
  for (int nodeIdx = start; nodeIdx <= stop; nodeIdx++) {    
    node = treeCache_getNode(nodeIdx);    
    type = treeCache_getType(nodeIdx,true);
    string tab;
    int lev = treeCache_getLevel(nodeIdx,true)-1;
    for (int i=1; i<= lev; i++) {
      tab += "      ";               
    }
    line = (tab + node + " (" + type + ")" );
    if ((show_devices_dp) && (treeCache_getUnit(nodeIdx, true) == "DU")) {
      line += " " + treeCache_getFsmDevDp(nodeIdx, true); 
    }
    DebugN(line);
    dynAppend(rows, line);    
  }
  


  
}  
/*
  special functions start here
*/

// Returns selected node information for all nodes.
// For details on the format, see _treeCache_composeNodeInfo
dyn_string treeCache_getAllNodesInfo(bool visibleOnly=false, int start = 1, int stop = -1) {
  treeCache_start();
  // It should be faster to read all data in advance and then composing the information
  // in one go instead of reading and composing data for each node separately
  dyn_string units = treeCache_getAllUnits();
  dyn_int indices = treeCache_getAllTypeIndices();
  dyn_int levels = treeCache_getAllLevels();
  dyn_string info;
  if (stop == -1) stop = dynlen(units);

  for ( int n = start ; n <= stop ; n ++ ) {
    if ( levels[n] /*no admin node*/ && ( !visibleOnly || treeCache_isVisible(n,true) ) ) {
      dynAppend(info,_treeCache_composeNodeInfo(n,
						units[n],
						indices[n],
						levels[n]));
    }
  }
  return info;
}



/*
  Returns selected information from sub tree in special format.
*/
void treeCache_getTreeInfo(string node,dyn_string&info, bool visibleOnly = true, bool isIdx = false) {
  treeCache_start();
  dynClear(info);
  int start, stop;
  treeCache_getVisitIndexes(node,start,stop,isIdx);
  info = treeCache_getAllNodesInfo(visibleOnly,start,stop);
}

void treeCache_setTreeInfo(string node, bool visibleOnly = true) {
  dyn_string info;
  treeCache_getTreeInfo(node,info, visibleOnly);
  dpSet("treeCache_"+node + ".treeInfo", info);
}

// returns FSM type from given type index
string treeCache_getTypeFromIdx(int idx) {
  treeCache_start();
  if ( idx > dynlen(treeCache_types) ) {
    _treeCache_error("given type idx ("+idx+") too large. maximum is "+dynlen(treeCache_types));
  }
  return treeCache_types[idx];
}

// return index to given FSM type
int treeCache_getIdxFromType(string type) {
  treeCache_start();
  int idx = dynContains(treeCache_types,type);
  if ( !idx ) {
    _treeCache_error("given type ("+type+") does not exist");
  }
  return idx;
}

bool _treeCache_isTopNodeCached(string node) {
  return mappingHasKey(treeCache_topNodesCaches,node + ":data");
}

void _treeCache_saveDataTopNode(string node) {
  if (_treeCache_isTopNodeCached(node)) return;
  treeCache_debug3("Storing top node " + node + " to cache");
  treeCache_topNodesCaches[node + ":data"] = treeCache_data;
  treeCache_topNodesCaches[node + ":items"] = treeCache_items;
  treeCache_topNodesCaches[node + ":nodes"] = treeCache_nodes;
  treeCache_topNodesCaches[node + ":types"] = treeCache_types;
  treeCache_topNodesCaches[node + ":isLogical"] = treeCache_isLogical;
}

void _treeCache_loadDataTopNode(string node) {
  treeCache_debug3("Loading top node " + node + " from cache");
  treeCache_data = treeCache_topNodesCaches[node + ":data"] ;
  treeCache_items = treeCache_topNodesCaches[node + ":items"];
  treeCache_nodes = treeCache_topNodesCaches[node + ":nodes"] ;
  treeCache_types = treeCache_topNodesCaches[node + ":types"] ;
  treeCache_isLogical = treeCache_topNodesCaches[node + ":isLogical"];

  treeCache_topNode = node;
  treeCache_dataInMemory = true;
}




/*
  Starts cache for specified node. Node can be any in existing FSM hierarchy.

  If this node (and all its sub tree) is found to be cached in dp structure,
  this dp is read into the data structure in memory.
  If  forcedWrite is true, the data structure is
  filled using fw functions, and this information is written to the dp structure (but it is better 
  to call treeCache_create in order to create the cache, instead)
*/
synchronized int treeCache_start(string node="",int debugLevel=2,bool forcedUpdate=false,
				 dyn_string excludedFsmTypes=makeDynString(), 
				 dyn_string dummy = makeDynString()) {

  if ( treeCache_dataInMemory && !forcedUpdate && ((node == "") || node == treeCache_topNode)) {
    return 0;
  }

  treeCache_debugLevel = debugLevel;

  if (forcedUpdate) {
    if (strlen(treeCache_create(node, excludedFsmTypes, treeCache_exc)) == 0) {
      DebugN(treeCache_exc);
      return -1;
    }
    else {
      return 0;
	 }
  }
  dyn_string dps;
  if (node == "") {
    // check for default node dp
       
    // Only use the local information
    if (dpExists(treeCache_defaultNodeDp)) {
      dps = makeDynString(treeCache_defaultNodeDp); 
    }
    if ( dynlen(dps) ) { 
      dpGet(dps[1]+".",treeCache_defaultNode); // set default node name from dp
    }
    else { // dp has to be created
      if ( strlen(node) >0 ) {
	treeCache_defaultNode = node; // node evtl given in this function is now becoming new default node
      } else {
	// look for local caches
	dps = dpNames("*","treeCache");
	if (dynlen(dps)>0) {
	  dps[1] = dpSubStr(dps[1],DPSUB_DP);
	  // take the first one and set it as default
	  strreplace(dps[1], "treeCache_","");
	  treeCache_defaultNode = dps[1];
	  treeCache_debug1("No default node was set. Using " + treeCache_defaultNode);
	  if (dynlen(dps)>1) {
	    treeCache_debug1("WARNING: There were several cache dps and I used the first one!" + dps);
	  }
	} else {
    // Check if by chance we were called from an FSM panel
    if ((strlen($1)>0) && (dpExists(_treeCache_getSystemFromFw($1) + "treeCache_" + $1))) {
       node = $1;        
       treeCache_defaultNode = node;
    } else {   
  	  // otherwise we miserably fail    
  	  return _treeCache_error("No default node found and no treeCache_* datapoint found. Please create some treeCache data point first!");
    }
	}
      }
      treeCache_setDefault(treeCache_defaultNode);
    }
  }
  _treeCache_isDefault(node);
     
  if ((treeCache_dataInMemory) && (node != treeCache_topNode)) { // if topNode is changed 
    _treeCache_saveDataTopNode(treeCache_topNode);
    if (_treeCache_isTopNodeCached(node)) {
      _treeCache_loadDataTopNode(node);
      return 0;
    }
  }

  treeCache_topNode = node;
  dynClear(dps);
  int count_waiting = 0; int max_count = 24;
  while (dynlen(dps) == 0) {
    dps = dpNames("*:treeCache_"+node,"treeCache");        
    if ( dynlen(dps) > 0) {
      if (dynlen(dps) == 1) { // ok. Only one dp found (hopefully in the right system) read from there
	_treeCache_read(dps[1]);
        string dpSystem; fwGeneral_getSystemName(dps[1], dpSystem,  treeCache_exc);
	if (treeCache_isLogical()) {
	  node = substr(node,strlen("logical_")-1);
	}
        if (treeCache_getSystem(node) != dpSystem) {
          treeCache_debug1("Warning: read cache from " + dpSystem + " but the node is on system " + treeCache_getSystem(node) );
        }
      } else { // more than one dp found. Get the one in the proper system
	string dp_treeCacheNode = _treeCache_getSystemFromFw(node) + "treeCache_" + node;
	if (! dpExists(dp_treeCacheNode) ) {
	  return _treeCache_error("Dp " + dp_treeCacheNode + " not found");	  
	}
	_treeCache_read(dp_treeCacheNode);
	treeCache_debug1("Warning " + dynlen(dps) + " dps found for " + node + ". using " + dp_treeCacheNode);
      }  
    }  else {    
      if (fwFsmTree_isNode(node)) {
	string dp_treeCacheNode = _treeCache_getSystemFromFw(node) + "treeCache_" + node;
	return _treeCache_error ("dp "  + dp_treeCacheNode + " not found ");
        // the node IS an FSM node but has not been cached --- give error
      } else {
        // the node is not an FSM node. This might mean that the system where the node 
        // and the treeCache dp are located is not connected yet. So we try again in a while
	// wait for the connection of the system
	treeCache_debug1("Could not find cache information for node " + node);
	treeCache_debug1("Waiting 10 seconds for the connection of the system (" + (count_waiting+1) + "/" + max_count + ")");
	delay(10);
	count_waiting++;
	if (count_waiting >= max_count) {
	  return _treeCache_error ("treeCache dp for"  + node + " not found ");
	}
      }
    }
  }
  return 0;
}


/**
   Use this function to set a custom function to get the type when the cache is read out from a logical tree
   (in this case the default is dpTypeName[|model])
 **/
void treeCache_setFunctionGetType(string function) {
  treeCache_userFunctionGetType = function;
}

string treeCache_setDefault(string node, string system="") {
  string res = treeCache_createDp(treeCache_defaultNodeDp,"ExampleDP_Text", system);
  if ((strlen(res)>0) && (dpExists(res))) {
    dpSet(res+".",node);
  }
  return res;
}

///////////////////////////////////////////////////////////////////////////////////////////////////////
/*
  Reads the tree from the FSM and writes this information
  into memory and then to the dp structure.
*/
string treeCache_create(string node,dyn_string excludedFsmTypes = makeDynString(), dyn_string& exceptionInfo, bool logical = false) {
  _treeCache_init();
  dyn_string nodesToVisit = makeDynString(node);
  treeCache_debug1("treeCache: started reading tree at node "+node );
  if (logical) {
    treeCache_debug1("Using logical view");
  }
  for ( int k = 1 ; k <= dynlen(nodesToVisit) ; k ++ ) {
    // recursive visit of tree starts here
    int d1,d2,d3,d4,d5,d6;
    if ( _treeCache_visit(nodesToVisit[k],d1,d2,d3,d4,d5,d6,excludedFsmTypes, exceptionInfo, logical) < 0 ) {
      return "";
    }
  }
  treeCache_debug1("treeCache: finished reading " + ((logical)?"logical":"FSM") + " tree");
  treeCache_dataInMemory = true;

  treeCache_debug3("treeCache: started writing information to dp structure");
  string sysNode ;
  string prefix ;
  prefix = "treeCache_";
  if (logical) {
    sysNode = treeCache_getSystem(node);
  } else {
    sysNode= _treeCache_getSystemFromFw(node);
  }
  if (logical) prefix = prefix + "logical";
  string dp = treeCache_createDp(prefix + node,"treeCache",
				 sysNode);
     
  _treeCache_fillCacheDp(dp, logical);
  if (! logical) {
    // delete other old caches of the same top node in oter systems (the information used to be replicated in all the systems)
    dyn_string dps = dpNames("*:" + prefix+node,"treeCache");
    string sysName;
    for (int i=1; i<= dynlen(dps); i++) {
      fwGeneral_getSystemName(dps[i], sysName, treeCache_exc);
      if (sysName != sysNode) {
	treeCache_debug1("Deleting old cached information on system " + sysName);
	dpDelete(dps[i]);
      }
    }
   }


   
  treeCache_debug2("treeCache: finished writing information to dp structure " + dp);
  return dp;
}

void treeCache_recreateIncludedDps(string topNode, string systemName = "") {
    if (strlen(systemName) == 0) systemName = getSystemName();
    
    treeCache_start(topNode);

    
    bool all_exist = true;
    int start, stop;
    treeCache_getVisitIndexes(topNode, start,stop);
      string includeddp;
          
    for (int n=start; n<= stop; n++) {
      if ((treeCache_getSystem(n,true) == systemName)) {
         if (treeCache_getUnit(n, true) == "CU") {
             includeddp =  treeCache_getIncludedDp(treeCache_getNode(n));
             if (! dpExists(includeddp) ) {
                all_exist = false;
                break;
             }             
         } 
      }
    }  
     
    if (all_exist) return;
   
    treeCache_debug1("Some included Dps not found in system " + systemName + " i am going to recreate them");
   // otherwise recreate them
    treeCache_initIncluded(topNode,false, false, systemName);   
}

/**
   Create and set the functions in the included DP
   @param topNode topNode wherre to start
   @param systemName create only the dps in the specified system name

   other parameters kept for back compatibility 
**/
int treeCache_initIncluded(string topNode, bool dummyOnlyCU = false, bool dummy2=false, string systemName = "") {
  if (dummyOnlyCU) {
    DebugTN("The hack to correct only for the CUs is not needed anymore."); return 0;
  }
  treeCache_start(topNode);
  int start, stop;
  treeCache_getVisitIndexes(topNode, start,stop);

  string includeddp; string node; string internal;
  dyn_string exceptionInfo;
  string dpe;

  for (int n=start; n<= stop; n++) {
    if ((strlen(systemName)>0) && (treeCache_getSystem(n,true) != systemName)) {
        continue; // to recover and create the included data points only in the current system
    }
    node = treeCache_getNode(n);
    if (treeCache_getUnit(n, true) == "CU") {
      includeddp =treeCache_createDp(treeCache_getIncludedDp(node),"treeCache_included");
      internal = treeCache_getFsmInternalDp(n, true);
      dpe = internal + "_FWM.fsm.currentState";
      dpe = dpSubStr(dpe, DPSUB_DP_EL) + ":_original.._value"; 
      fwDpFunction_setDpeConnection(includeddp + ".", makeDynString(dpe), makeDynString(),"(p1 == \"INCLUDED\") || (p1==\"MANUAL\")", exceptionInfo);
    } else {
      /*
      dpe = internal + ".mode.enabled";
      dpe = dpSubStr(dpe, DPSUB_DP_EL) + ":_original.._value"; 
      fwDpFunction_setDpeConnection(includeddp + ".", makeDynString(dpe), makeDynString(),"p1", exceptionInfo);
      */
    }
    if (dynlen(exceptionInfo) >0 ) {
      DebugN(exceptionInfo);
      return _treeCache_error("Unable to set the dp function in the included dp for node " + node);
    }
  }
  return 0;
}


string treeCache_createDp(string dp,string dpType,string system="") {
  dp = strrtrim(dp,".");
  if ( !strlen(system) ) {
    dyn_string parts = strsplit(dp,":");
    if ( dynlen(parts) == 1 ) {
      system = getSystemName();
    }
    else {
      system = parts[1];
      dp = parts[2];
    }
  }
  system = strrtrim(system,":")+":";
  string longdp = system + dp;
  if ( !dpExists(longdp) ) {
    dpCreate(dp,dpType,getSystemId(system));
    if ( dynlen(getLastError()) ) {
      _treeCache_error("Unable to create dp "+dp+" of type "+dpType+" in system "+system+
		       " with systemId "+getSystemId(system)+" (full dp name is "+longdp+"). will exit now.");
      return "";
    }
    //return true; // dp created
  }
  //return false; // dp not created
  return longdp;
}

int treeCache_getNodeIdx(string node,int isIdx=false) {
  treeCache_start();
  int nodeIdx;
  if ( isIdx ) {
    nodeIdx = node;
    if ( nodeIdx > dynlen(treeCache_nodes) ) {
      _treeCache_error("node index ("+nodeIdx+") too large");
      nodeIdx = 0;
    }
  }
  else {
    nodeIdx = dynContains(treeCache_nodes,node);
    if ( !nodeIdx ) {
      _treeCache_error("node ("+node+") is not cached");
      nodeIdx = 0;
    }
  }
  return nodeIdx;
}



/** Debug Functions **/

void treeCache_setDebug(int debugLevel) {
  treeCache_debugLevel = debugLevel;
  treeCache_debug3("new debug level is "+debugLevel);
}

void treeCache_debug(string msg,int debugLevel) {
  if ( treeCache_debugLevel >= debugLevel ) {
    DebugTN("treeCache: "+msg);
  }
}
void treeCache_debug1(string msg) { treeCache_debug(msg,1); } // most important msgs
void treeCache_debug2(string msg) { treeCache_debug(msg,2); }
void treeCache_debug3(string msg) { treeCache_debug(msg,3); }
void treeCache_debug4(string msg) { treeCache_debug(msg,4); } // most detailed/expert msgs



string treeCache_getIncludingDomain(string node) {
  if (! treeCache_isNode(node)) return node; // mmm... just try

  string domain;
  if (treeCache_getUnit(node)=="CU") {
    domain = node;
  } else {
    dyn_string ancestors = treeCache_getAncestors(node);
    for (int i=1; i<= dynlen(ancestors); i++) {
      if (treeCache_getUnit(ancestors[i]) == "CU") {
	domain = ancestors[i];
	break;
      } 
    }     
  }
  return domain;
  
}

/** Function for UI **/

void treeCache_fsmView(string node) {
   ChildPanelOnCentral("majority_treeCache/StartFSM.pnl" ,"Start FSM for " + node, makeDynString("$1:" + node));   
}

void treeCache_fsmDoView(string node) {  
  string domain = treeCache_getIncludingDomain(node);

   fwUi_showFsmObject(domain,node);


//   if (globalExists("moduleName") && (strlen(moduleName)>0) && (isFunctionDefined("fwFsmUser_nodeDoubleClicked"))) {
//     fwFsmUser_nodeDoubleClicked(node,domain);
//   } else {         
//     fwUi_showFsmObject(domain,node);
//   }
}


void treeCache_openPanel_viewExcludedNodes(string cache_topNode, string root) {
   ChildPanelOnCentral("majority_treeCache/viewExcludedNodes.pnl",
		       "View excluded nodes below " + treeCache_getFsmUserLabel(root),
      makeDynString("$treeCache_topNode:" + cache_topNode, "$1:" + root));
}


/*

  internal functions start here

*/

/*
  Gives summary of node information in following format:
  unit:FSMtypeIdx>treelevel<node
  examples:
  CU:1>1<CMS_DCS
  CU:2>2<CMS_TRK
  LU:3>3<CMS_TRK_BARREL
  CU:2>2<CMS_ECAL
  LU:4>3<CMS_ECAL_HV
*/
/*
  string _treeCache_composeNodeInfo(string node,string unit,int typeIdx,int level) {
  return unit+":"+typeIdx+strexpand("\\fill{>}",level)+node;
  }
*/


string _treeCache_composeNodeInfo(int  nodeIdx,string unit,int
typeIdx,int level) {
  string label = treeCache_getFsmUserLabel(nodeIdx, true);
  string node = treeCache_getNode(nodeIdx);
  if(label=="")
	label=node;
  return unit+":"+typeIdx+">"+level+"<"+node + "@" + label;
}


void _treeCache_init() {
  treeCache_dataInMemory = false;
  dynClear(treeCache_nodes);
  //dynClear(treeCache_nodesParents);
  dynClear(treeCache_items);
  dynClear(treeCache_data);
  dynClear(treeCache_types);
}

// reads from fw FSM the system, where the node is located
string _treeCache_getSystemFromFw(string node) {
  string internal_dpname,systemName;
  fwCU_getDp(node,internal_dpname);
  fwGeneral_getSystemName(internal_dpname,systemName,treeCache_exc);
  return systemName;
}

// reads dp structure into memory
int _treeCache_read(string dp) {
  _treeCache_init();
  treeCache_debug1("treeCache: started reading cache in "+dp);
  dyn_string flattened;
  dpGet(dp+".data",flattened,
	dp+".nodes",treeCache_nodes,
        dp+".items",treeCache_items,
	dp+".types",treeCache_types,
	dp + ".isLogical", treeCache_isLogical);
  int Nnodes = dynlen(treeCache_nodes);
  int Nitems = dynlen(treeCache_items);
  int Nflat = dynlen(flattened);
  // put data into memory structure and perform sanity check
  if ( Nitems != Nflat ) {
    return _treeCache_error("read data insane: number of items is "+Nitems+" whereas length of data array is "+Nflat);
  }
  for ( int i = 1 ; i <= dynlen(treeCache_items) ; i ++ ) {
    treeCache_data[i] = _treeCache_unflatten(flattened[i],treeCache_delimiter1);
    int N = dynlen(treeCache_data[i]);
    if ( Nnodes != N ) {
      return _treeCache_error("read data insane: number of nodes is "+Nnodes+
			      " whereas length of data array for item "+treeCache_items[i]+" is "+N);
    }
  }

  treeCache_dataInMemory = true;
  treeCache_debug1("treeCache: finished reading cache");
  return 0;
}

_treeCache_fillCacheDp(string dp, int logical = 0) {
  dp = treeCache_createDp(dp,"treeCache");
  if (strlen(dp)==0) {
    treeCache_debug1("Unable to create dp " + dp);
    return;
  }
  dyn_string flattened;
  for ( int i = 1 ; i <= dynlen(treeCache_items) ; i ++ ) {
    dynAppend(flattened,_treeCache_flatten(treeCache_data[i],treeCache_delimiter1));
  }
  dpSet(dp+".data",flattened);
  dpSet(dp+".nodes",treeCache_nodes);
  dpSet(dp+".items",treeCache_items);
  dpSet(dp+".types",treeCache_types);
  dpSet(dp+".isLogical", logical);
}


dyn_string _treeCache_getAllData(string item) {
  treeCache_start();
  int itemIdx = dynContains(treeCache_items,item);
  if ( !itemIdx ) {
    _treeCache_error("getAllData: item ("+item+") does not exist");
  }
  return treeCache_data[itemIdx];
}

/*
  Reads a specific item from a specific node. Data is returned always as string.
  Conversion is done later in the wrapper functions.
*/
string _treeCache_getData(string item,string node,bool isIdx=false) {
  return _treeCache_getDataI(item,treeCache_getNodeIdx(node,isIdx));
}

string _treeCache_getDataI(string item,int nodeIdx) {
  treeCache_start();
  int itemIdx = dynContains(treeCache_items,item);
  if ( !itemIdx ) {
    _treeCache_error("getData: item ("+item+") does not exist (nodeIdx=" + nodeIdx + ")");
  }
  // in case of non existing nodes or items, this statement will be entered anyhow.
  // this is wanted to force PVSS to generate an additional warning/error
  return treeCache_data[itemIdx][nodeIdx];
}

//checks, if node is default (empty) and sets node name in this case to FSM top node
bool _treeCache_isDefault(string&node) {
  bool isDefault = !strlen(node);
  if ( isDefault ) {
    node = treeCache_defaultNode;
  }
  return isDefault;
}

// writes data to memory structure. 
// if item does not yet exist, it is added automatically
void _treeCache_setData(string item,int nodeIdx,string data,bool newNode=false) {
  int itemIdx = dynContains(treeCache_items,item);
  // simulate map with dyn_dyn_string to store data: save memory!
  if ( !itemIdx ) {
    dynAppend(treeCache_items,item);
    itemIdx = dynlen(treeCache_items);
  }
  // if node is new, write dummy data for this node into all existing items
  if ( newNode ) {
    for ( int i = 1 ; i <= dynlen(treeCache_items) ; i ++ ) {
      treeCache_data[i][nodeIdx] = "";
    }
  }
  treeCache_data[itemIdx][nodeIdx] = data;
}

// converts an array to a string using a defined delimiter
// that should not occur within the original data :-)
string _treeCache_flatten(dyn_string array,string delimiter) {
  string flattened;
  for ( int k = 1 ; k <= dynlen(array) ; k ++ ) {
    if ( k > 1 ) {
      flattened += delimiter;
    }
    flattened += array[k];
  }
  return flattened;
}

dyn_string _treeCache_unflatten(string flattened,string delimiter) {
  dyn_string unflattened = strsplit(flattened,delimiter);
  /* 
     It is a documented "feature" of the function strsplit, that the resulting
     array will contain only the same number of elements than the number of
     delimiters, if the last character in the input string is the delimiter!
     This is unwanted in our case and has to be treated manually:
  */
  if ( substr(flattened,strlen(flattened)-1) == delimiter ) {
    dynAppend(unflattened,"");
  }
  return unflattened;
}

string _treeCache_system(string sys) {
  if ( !strlen(sys) ) {
    sys = getSystemName();
  }
  return strrtrim(sys,":");
}

int _treeCache_error(string msg) {
  treeCache_debug1("\n\n\n!!!!!!!!!!!!!!\ntreeCache: error occured. description follows.\n"+msg+"\n\n\n\n");
  return -1;
}




string _treeCache_getTypeFromDp(string deviceDpName) {
  string model, type;
  if (strlen(treeCache_userFunctionGetType) > 0) {
    int res  = evalScript(type,"string main(string deviceDpName) { " + treeCache_userFunctionGetType + "}",makeDynString(),deviceDpName);
    if (res != -1) {
      return type;
    }  
  }
  dyn_string exceptionInfo;
  fwDevice_getModel(deviceDpName, model, exceptionInfo);
  type = dpTypeName(deviceDpName);
  if (strlen(model)>0) type = type + "|" + model;
  return type;
}

// recursive visit of tree to read information from fw FSM and write it into memory structure
int _treeCache_visit(string node,int&Nnodes,int&Nlevels,int&Nsystems,int&NlevelsInSystem,
		     int&nodeIdx,bool&systemChanged,dyn_string&excludedFsmTypes,
		     dyn_string& exceptionInfo,  bool logical = false,
		     int parentIdx=0,int level=1, // level in whole tree
		     string parentSystem="",int systemLevel=0, // system level in whole tree
		     int levelInSystem=1,
		     int unitTypeIdx=-1,
		     bool visible=true		   
		     ) {
  // ignore the part before :: (fixed thanks to DT) -- LM Feb 18 09
  int indexSplit = strpos(node,"::");
  if (indexSplit>0) {
    node = substr(node,indexSplit+2);
  }
  string type,unitType; string deviceDpName;
  if (logical) {
    deviceDpName = dpSubStr(dpAliasToName(node), DPSUB_SYS_DP);
    if ( ! dpExists(deviceDpName)) {
      fwException_raise(exceptionInfo, "Node does not exist", "node ("+node+") does not exist in logical tree. abort.", "");
      return _treeCache_error("node ("+node+") does not exist in logical tree. abort.");
    }
    type = _treeCache_getTypeFromDp(deviceDpName);
  } else {
    fwCU_getType(node,type); // FSM object type
  }
  if ( dynContains(excludedFsmTypes,type) ) { // ignore this node
    return 1;
  }
  
  if (! logical) {
    if ( !fwFsmTree_isNode(node) && !parentIdx ) {
      fwException_raise(exceptionInfo, "Node does not exist", "node ("+node+") does not exist in FSM tree. abort.", "");
      return _treeCache_error("node ("+node+") does not exist in FSM tree. abort.");
    }
  }
     
  dyn_int unitTypeIndices;
  dyn_string visibleChildren;
  
  if (! logical) {
    visibleChildren = fwFsmUi_getAllChildren(node,node,unitTypeIndices);
    for ( int v = 1 ; v <= dynlen(visibleChildren) ; v ++ ) {
      visibleChildren[v] = strsplit(visibleChildren[v],"::")[1];
    }
  }
  dyn_string children;
  if (logical) {
    fwDevice_getChildren(node, fwDevice_LOGICAL, children,exceptionInfo);
    if (dynlen(exceptionInfo)>0) {
      return _treeCache_error("Exception when running fwDevice_getChildren. abort.");
    } 
    for (int i=1; i<= dynlen(children); i++) {
      unitTypeIndices[i] = 0;
    }
  } else {
    children = fwCU_getChildren(unitTypeIndices,node);
  }

  string parent;
  if ( !parentIdx ) { // first call of visit: this is the top node in this (partial) hierarchy
    if (logical) {
      parent ="";
    } else {
      int tmp1;
      string tmp2;
      parent = fwCU_getParent(tmp1,node);
      if ( dynlen(children) ) { // has children: should be the normal case
	tmp1 = fwCU_getParent(unitTypeIdx,children[1]);
      }
      else if ( strlen(parent) ) { // STRANGE: has no children, so go to parent to find out unit type
	dyn_int tmpIndices;
	dyn_string tmpNodes = fwCU_getChildren(tmpIndices,parent);
	unitTypeIdx = tmpIndices[dynContains(tmpNodes,node)]; // array MUST contain child node
      }
      if ( !strlen(parent) ) {
	parent = "FSM";
      }
    }
  }
  else {
    parent = treeCache_nodes[parentIdx];
  }
  
  if (logical) {
    unitType = ((dynlen(children)>0)?"LU":"DU");
    unitTypeIdx = ((dynlen(children)>0)?0:2);
  } else {
    switch(unitTypeIdx) {
    case 0: unitType = "LU";break;
    case 1: unitType = "CU";break;
    case 2: unitType = "DU";break;
      // default is not handled: unitType will remain empty
    }
  }
  if ( unitTypeIdx < 2 ) {
    treeCache_debug2("treeCache: processing "+unitType+" "+node);
  }
  int typeIdx = dynContains(treeCache_types,type);
  if ( !typeIdx ) {
    dynAppend(treeCache_types,type);
    typeIdx = dynlen(treeCache_types);
  }
  string system;
  if (logical) {
    fwGeneral_getSystemName(deviceDpName, system, exceptionInfo);
  } else {
    system = _treeCache_getSystemFromFw(node);
  }
  if ( system != parentSystem ) {
    if ( !mappingHasKey(treeCache_parentSystems,system) ) {
      treeCache_parentSystems[system] = parentSystem;
    }
    systemLevel ++;
    levelInSystem = 1;
    systemChanged = true;
  }
  int Nch = dynlen(children);

  string devDp,intDp,userLabel;
  dyn_string udata, exInfo;
  if (logical) {
    devDp = deviceDpName;    
  } else {
    fwCU_getDevDp(node,devDp);
    fwCU_getDp(node,intDp);
    fwTree_getNodeUserData(system+node, udata, exInfo); // must put system in front of node name (undocumented)
    if (dynlen(udata) == 0) {
      fwTree_getNodeUserData(node, udata, exInfo); // if it does not work, try without system
    }
    if ( dynlen(udata) >= 3 ) {
      userLabel = udata[3];
    }
    if (dynlen(udata)>0) {
      visible = udata[1]; // don't use the value got from recursion because it could be wrong
    } // otherwise use the value got from recursion   
  }
     
  dynAppend(treeCache_nodes,node);
  nodeIdx = dynlen(treeCache_nodes);
  _treeCache_setData("system",nodeIdx,system);
  _treeCache_setData("type",nodeIdx,type);
  _treeCache_setData("typeIdx",nodeIdx,typeIdx);
  _treeCache_setData("unit",nodeIdx,unitType);
  _treeCache_setData("unitIdx",nodeIdx,unitTypeIdx);
  _treeCache_setData("parent",nodeIdx,parent);
  //_treeCache_setData("nodesParents",nodeIdx,node+fwFsmUser_delimiter+parent);
  _treeCache_setData("parentIdx",nodeIdx,parentIdx);
  _treeCache_setData("level",nodeIdx,level);
  _treeCache_setData("systemLevel",nodeIdx,systemLevel);
  _treeCache_setData("levelInSystem",nodeIdx,levelInSystem);
  _treeCache_setData("devDp",nodeIdx,devDp);
  if (! logical) {
    _treeCache_setData("intDp",nodeIdx,intDp);
    _treeCache_setData("userLabel",nodeIdx,userLabel);
    _treeCache_setData("visible",nodeIdx,(int)visible);
  }


  /*
    Recursive visit: Provide as much information to child call as possible.
    Current node becomes parent node there.
    Unit type indices are obtained for free when getting list of children from fw FSM.
  */
  int NnodesL = 1; // This local node counts as one
  int NlevelsL,NsystemsL;
  dyn_string indices;
  for ( int c = 1 ; c <= Nch ; c ++ ) {
    int NlevelsInSystemL,nodeIdxL;
    bool systemChangedL;
    int res = _treeCache_visit(children[c],
			       NnodesL,NlevelsL,NsystemsL,NlevelsInSystemL,nodeIdxL,systemChangedL,
			       excludedFsmTypes,
			       exceptionInfo,
			       logical,
			       nodeIdx,level+1,
			       system,systemLevel,
			       levelInSystem+1,
			       unitTypeIndices[c],
			       dynContains(visibleChildren,children[c])
			       );
    if ( res ==  0 ) {dynAppend(indices,nodeIdxL);} // not ignored
    if ( res == -1 ) {return -1;} // error occured
    if ( res ==  1 ) {continue;} // has ignored FSM type

    int reference = (systemChangedL?levelInSystem:NlevelsInSystemL);
    if ( NlevelsInSystem < reference ) {
      NlevelsInSystem = reference;
    }
  }
  if ( !Nch ) {
    NlevelsInSystem = levelInSystem;
  }
  Nnodes += NnodesL;
  int referLevels = (Nch?NlevelsL:level);
  if ( Nlevels < referLevels ) {
    Nlevels = referLevels;
  }
  int referSystems = (Nch?NsystemsL:systemLevel);
  if ( Nsystems < referSystems ) {
    Nsystems = referSystems;
  }
  _treeCache_setData("NnodesBelow",nodeIdx,NnodesL-1);
  _treeCache_setData("NlevelsBelow",nodeIdx,Nch?NlevelsL-level:0);
  _treeCache_setData("NsystemsBelow",nodeIdx,Nch?NsystemsL-systemLevel:0);
  _treeCache_setData("NlevelsInSystemBelow",nodeIdx,NlevelsInSystem-levelInSystem);
  _treeCache_setData("children",nodeIdx,_treeCache_flatten(indices,treeCache_delimiter2));

  return 0;
}

int treeCache_updateDevDps(string topNode, bool debug = false) {
  if (treeCache_start(topNode) == -1) return -1;
  int start, stop;
  treeCache_getVisitIndexes(topNode, start, stop);
  string node, devDp, intDp;
  int count = 0;
  for (int n=start; n<= stop; n++) {
    node = treeCache_getNode(n);
    fwCU_getDevDp(node,devDp);
    fwCU_getDp(node,intDp);
    if (devDp != _treeCache_getDataI("devDp", n)) {
      if (debug) {
         treeCache_debug1("Found change in " + node + " devDp: " +  _treeCache_getDataI("devDp", n) + " -> " + devDp); 
      }
      count++;
    }
    if (intDp != _treeCache_getDataI("intDp", n)) {
      if (debug) {
         treeCache_debug1("Found change in " + node + " intDp: " +  _treeCache_getDataI("intDp", n) + " -> " + intDp); 
      }
      count++;
    }    
    _treeCache_setData("devDp",n,devDp);    
    _treeCache_setData("intDp",n,intDp);
  }
     
  if (count >0) {
    string sysNode = treeCache_getSystem(topNode);
    string dp = treeCache_createDp("treeCache_" + topNode,"treeCache",
				 sysNode); 
    _treeCache_fillCacheDp(dp, false);
  }
  treeCache_debug3(count + " changes applied");
  return count;

}



/* dpGets multiple dpes from different systems */
void _treeCache_dpGetAll(dyn_string dpes, dyn_anytype& values) {
  dyn_string dpes_temp;
  dyn_anytype values_temp;

  dyn_string exc;
  dynClear(values);

  if (dynlen(dpes)==0) return;

  string prev_sys;
  string sys;
  fwGeneral_getSystemName(dpes[1], prev_sys, exc);

  
  int steps = 1;
  for (int i=1; i<= dynlen(dpes); i++) {
    fwGeneral_getSystemName(dpes[i], sys, exc);
    //    DebugN("Step " + i + "(" + dpes[i] + ")");
    if (  (sys != prev_sys)) {
      dpGet(dpes_temp, values_temp);
      //     DebugN("System change found  dpGetting ", dpes_temp, values_temp);
      dynAppend(values, values_temp);
      dynClear(dpes_temp);
      prev_sys = sys;
      steps++;
    }
    
    dynAppend(dpes_temp, dpes[i]);    
    //    delay(1);
  }

  // DebugN("Got in " + steps + " steps");
  dpGet(dpes_temp, values_temp);
  //  DebugN("Last found  dpGetting ", dpes_temp, values_temp);
  dynAppend(values, values_temp);
}



