#uses "majority_treeCache/treeCache.ctl"

/*
This library is not needed anymore

 */
/*
  action:
  0 - exclude
  1 - include
  
*/
void fwFsmUser_action(string node,string msg,int action,string parent="") {

}

void fwFsmUser_specialAction(string node, string action) {

}


// NOT USED ANYMORE

// // Clara's CB functions start here

// synchronized fwFsmUser_nodeIncluded   (string parent, string node) {fwFsmUser_action(node,"included",1,parent);}
// synchronized fwFsmUser_nodeExcluded   (string parent, string node) {fwFsmUser_action(node,"excluded",0,parent);}
// synchronized fwFsmUser_nodeExcludedAll(string parent, string node) {fwFsmUser_action(node,"excludedAll",0,parent);}

// synchronized fwFsmUser_nodeEnabled    (string parent, string node) {fwFsmUser_action(node,"enabled",1,parent);}
// synchronized fwFsmUser_nodeDisabled   (string parent, string node) {fwFsmUser_action(node,"disabled",0,parent);}

// fwFsmUser_nodeTaken      (string node)                {fwFsmUser_specialAction(node,"taken");}
// /*fwFsmUser_nodeReleased   (string node)                {fwFsmUser_action(node,"released",0);}
//   */
// fwFsmUser_nodeReleasedAll(string node)                {fwFsmUser_specialAction(node,"releasedall");}

// synchronized fwFsmUser_nodeExcludedRec    (string parent, string node) {fwFsmUser_action(node,"excludedRec",0,parent); }
// synchronized fwFsmUser_nodeExcludedAllRec (string parent, string node) {fwFsmUser_action(node,"excludedAllRec",0,parent); }
// synchronized fwFsmUser_nodeIncludedRec    (string parent, string node) {fwFsmUser_action(node,"includedRec",1,parent); }

