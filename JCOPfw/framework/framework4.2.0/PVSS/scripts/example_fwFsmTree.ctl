// Example of dynamically creating an FSM Tree:
/*
 - CU1
   - LU1
     - dev000
     ...
     - dev009
*/

main()
{
string curr_node, dev_name;
int i;

    // Remove CU1 if it already exists
    fwFsmTree_removeNode("FSM","CU1");

    // Create a Top-level Control Unit (CU1) of type Node
    curr_node = fwFsmTree_addNode("FSM", "CU1", "Node", 1);

    if(curr_node != "")
    {

        // Create a Logical Unit (LU1) of type Node
        curr_node = fwFsmTree_addNode(curr_node, "LU1", "Node", 0);

        if(curr_node != "")
        {

	    // Change the label for CU1/LU1
            fwFsmTree_setNodeLabel(curr_node, "myLU1");

            // Create 10 Device Units of type Device
	    // the DPs dev000 to dev009 have to exist already
	    for(i = 0; i < 10; i++)
	    {
		sprintf(dev_name,"dev%03d",i);
                fwFsmTree_addNode(curr_node, dev_name, "FwAiDevice", 0);
	    }

            // Add a Majority object in CU1/LU1 for devices of type Device
            fwFsmTree_addMajorityNode(curr_node, "FwAiDevice", "more", 1,
	        makeDynString("ERROR"), 1, 0);

	}
    }
    // Generate the FSM for CU1
    fwFsmTree_generateTreeNode("CU1");

    // Refresh the Tree in case the DEN is running
    fwFsmTree_refreshTree();

    // Start FSM processes for the CU1 sub-tree
    fwFsmTree_startTreeNode("CU1");
}
