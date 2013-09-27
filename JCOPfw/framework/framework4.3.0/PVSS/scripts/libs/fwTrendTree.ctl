// node clicked on editor Tree
TREND_editor_selected(string node, string parent)
{
}

// node right-clicked on editor Tree
TREND_editor_entered(string node, string parent)
{
	fwTreeDisplay_editorStd(node, parent);
}

// node clicked on navigator Tree
TREND_navigator_selected(string node, string parent)
{
}

// node right-clicked on navigator Tree
TREND_navigator_entered(string node, string parent)
{
	fwTreeDisplay_navigatorStd(node, parent);
}

// "Seetings" button selected on editor Tree
// Please add the opening of your "settings" panel
TREND_nodeSettings(string node, string parent)
{
}

// "View" button selected on navigator Tree 
// Please add the opening of your "view" panel
TREND_nodeView(string node, string parent)
{
}

// The following routines are available in case of need 
TREND_nodeAdded(string new_node, string parent)
{
	DebugN("Added "+new_node+" to "+parent);	
}

TREND_nodeRemoved(string node, string parent)
{
	DebugN("Removed "+node+" from "+parent);	
}

TREND_nodeCut(string node, string parent)
{
	DebugN("Cut "+node+" from "+parent);	
}

TREND_nodePasted(string node, string parent)
{
	DebugN("Pasted "+node+" to "+parent);	
}

TREND_nodeRenamed(string old_node, string new_node)
{
	DebugN("Renamed "+old_node+" to "+new_node);	
}

TREND_nodeReordered(string node)
{
	DebugN("Reordered "+node);	
}