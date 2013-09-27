/*
  RPC Majority Library
  version: 1.0
  author: Giovanni Polese  
  freely adapted from an idea of the CMS DCS Tracker Group

  @device  the device type as it was defined in the configuration
  @values  the values of the datapoint elements you defined to be connected to for this device type
  @all this is the total count that may be modified in this function (to take into account partial excluding of complex device units)
  @calcTotal tells if the function is called to compute the total (regardless the inclusion state) or the included devices 
  @node this is the node name in the FSM that might be used to retrieve some additional info
  @return array of integers of state counts of the defined states for this device type
 */

dyn_int majorityUser_stateCounts(string device, dyn_anytype values, // information needed to calculate the state counts
				 int&all, // all may be modified in this function
				 bool calcTotal, // is count for total statistics being calculated? (if not: included nodes statistics)
				 string node) { // node name: might me useful. all tree information can be retrieved using node and treeCache lib.

  // values are returned in the same order you defined in the majority_addDevice function. 


  // this is an example how to handle a FwCaenChannel device with 2 states (on and error)

     int on = 0,
     error = 0,
     notready = 0;
    // bit32 status = (bit32)values[1];
                   
     
     if ( device == "RPCchamber_maj" ) {
	    
	  // values from 2 to the end are possible sources of error
    if(dynlen(values)==1){
      if(values[1]=="ON")
        on = 1;
      else 
        error = 1;
        
    }else
     {
      error = 1;
    }
    
    }else
     {
      error = 1;     
     }  
//Debug(device,values,all,calcTotal,node,on,error);     
    
  return makeDynInt(on,error);
}

// translates fsm device dp to the dp, where the configured dpes are located.
// if your dpes are part of the fw fsm dev dps (normal case), leave this function unchanged
string majorityUser_dpTranslation(string fsmDevDp) {
     return fsmDevDp;
}

// majStates: contains mapping with fulfill status of devices:states
// mapPercentages: contains mapping with exact percentages (should not be needed normally)
string majorityUser_calcFsmState(mapping majStates,mapping mapPercentages,string node) {
  
     if ( majStates["RPCchamber_maj:OK"]      >= majority_ON    ) return "OK";
     else                                                       return "NOT_OK";


}
