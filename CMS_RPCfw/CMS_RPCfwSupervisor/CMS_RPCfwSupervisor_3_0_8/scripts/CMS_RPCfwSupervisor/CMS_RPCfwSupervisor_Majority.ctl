/******************************************************
  
  RPCSupervisor_Majority Script
  author: G. Polese  
  version :0.1

*************************************************************/


#uses "majority_treeCache/majorityLib.ctl"
#uses "majority_treeCache/treeCache.ctl"
#uses "CMS_RPCfwSupervisor/CMS_RPCfwSupervisor_MajorityUser.ctl"

main() {
  majority_debug4("Starting majority on system " + getSystemName());
  string topNode = "CMS_RPC"; // set your top node here    
  majority_start(topNode,1 // debug level
		 );

}
