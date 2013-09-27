main()
{
dyn_string nodes, refnode, exInfo;
int i;
int num;
string refstr, refnum, newref;

	fwTree_getAllNodes(nodes, exInfo);
	for(i = 1; i <= dynlen(nodes); i++)
	{
		if(fwFsm_isObjectReference(nodes[i]))
		{
			if(patternMatch("&[0123456789]*", nodes[i]))
			{
				if(!patternMatch("&[0123456789][0123456789]*", nodes[i]))
				{
					refstr = substr(nodes[i], 1, 1);
					refnode = substr(nodes[i], 2);
					num = refstr;
					newref = fwFsm_makeReferenceNumber(num, refnode);
					DebugN("renaming "+nodes[i]+" to "+newref);
					fwTree_renameNode(nodes[i], newref, exInfo);
				}
			}
		}
	}
}