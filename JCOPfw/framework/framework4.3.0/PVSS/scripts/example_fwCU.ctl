// Example of operating an FSM tree from a script or a User panel
fwFsmExample_operateTree()
{
    fwCU_takeTree("DCS","clara");
    fwCU_shareTree("DCS","clara");
    delay(5);
    fwCU_releaseTree("DCS","clara");
    delay(5);
    fwCU_takeTree("DCS","clara");
    fwCU_exclusiveTree("DCS","clara");
    delay(5);
    fwCU_excludeTree("DCS","SubDet1","clara");
    delay(5);
    fwCU_includeTree("DCS","SubDet1","clara");
    delay(5);
    fwCU_releaseTree("DCS","clara");
}

// Example of getting Tree information inside a CU, LU or Obj User panel 
// (Panel called with $1=CU name and $2=LU or Obj name)
fwFsmExample_viewTree()
{
    dyn_string children;
    dyn_int children_types;
    int i, al_state;
    string state;

    children = fwCU_getChildren(children_types, $1+"::"+$2);
    fwCU_getState($1+"::"+$2, state);
    DebugN("State of Node: "+$1+"::"+$2+" is "+state); 
    for(i = 1; i <= dynlen(children); i++)
    {
        fwCU_getState($1+"::"+children[i], state);
	DebugN("State of Child: "+children[i]+" is "+state); 
    }
}

// Example of getting DU information inside a DU User panel 
// (Panel called with $1=CU name, $2=DU Datapoint name)
fwFsmExample_viewDU()
{
    string obj, state;
		int al_state;

    // Get the DU name from the DP name (possibly logical)
    fwCU_getDevName($1, $2, obj);
    // Get the DU state:
    fwCU_getState($1+"::"+$2, state);
    DebugN("State of Node: "+$1+"::"+$2+" is "+state);
}

