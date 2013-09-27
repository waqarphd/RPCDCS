/****
  IMPORTANT: THIS FILE IS ONLY AN EXAMPLE OF A MAJORITY SCRIPT. 

                 ============== DO NOT PUT YOUR SUBDETECTOR SPECIFIC CODE HERE ===============
                        		 Never run this script!!!

     Just copy this file into your package (e.g. for the tracker "scripts/CMS_TRACKER/majority.ctl"),
     then include your specific majorityUser library and start the script.   
 ****/

#uses "majority_treeCache/majorityLib.ctl"
#uses "majority_treeCache/treeCache.ctl"

// ===> PLEASE CHANGE <==== 
// Include here your specific majorityUser library
#uses "CMS_TRACKER/majorityUser.ctl"

main() {
  majority_debug4("Starting majority on system " + getSystemName());
  string topNode = "CMS_TRACKER"; // set your top node here    <==== PLEASE CHANGE!!
  majority_start(topNode,1 // debug level
		 );

  // you may want to pass a third parameter that is the treeCache topNode if you need to use 
  //  the same treeCache but with different topNodes for different majorities
			 
  // that's all
}
