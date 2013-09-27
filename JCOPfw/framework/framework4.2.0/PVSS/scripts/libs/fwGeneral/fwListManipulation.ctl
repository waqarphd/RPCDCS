/**@name LIBRARY: fwListManipulation.ctl

This library contains functions to obtain lists of all dp names or dp types which contain
a given dp element name of a given type reference.

Creation Date: 19/12/00

Modification History: None

External functions:	fwListManipulation_getListOfDpTypeWithRef,
					fwListManipulation_getListOfDpWithRef,
					
				
Constraints: 	

Usage: JCOP framework internal, public

PVSS manager usage: VISION, CTRL

@author Herve Milcent (IT-CO)
*/

//@{

/**Gets a list of all the data point types which have a data point element
which is a type reference to a given type and which have the given name.

Modification History: None

Constraints: None

Usage: JCOP framework internal, public

PVSS manager usage: VISION, CTRL

@param typeRefToLookFor: The data point type reference to look for (eg. _FwDeclarations)
@param dpElementName: The name of the data point element to search for (eg. fwDeclarations)
@param returnList: The list of data point types is returned here
@param exception: Details of any exceptions are returned here

@author Herve Milcent (IT-CO)
*/
fwListManipulation_getListOfDpTypeWithRef(string typeRefToLookFor, string dpElementName,
				dyn_string &returnList, dyn_string &exception)
{
	dyn_dyn_string listOfRefs;
	int i,j,pos;
	dyn_string typeList, tempDpList;
        
	listOfRefs = dpGetRefsToDpType(typeRefToLookFor);
// DebugN(listOfRefs);
	for (i=1; i<= dynlen(listOfRefs);i++) {
//		DebugN(listOfRefs[i]);
//		pos = dynContains(listOfRefs[i],typeRefToLookFor);
//		dynRemove(listOfRefs[i],pos);
                
        for(j=1; j<=dynlen(listOfRefs[i]);j++) {
			pos = dynContains(listOfRefs[i],dpElementName);
			if(pos > 1) {
				typeList[dynlen(typeList)+1] = listOfRefs[i][1];
			}
        }
	}
	i=dynUnique(typeList);
//	DebugN(i,typeList);
	returnList = typeList;
}

/**Gets a list of all the data point names of dps which have a data point element
which is a type reference to a given type and which have the given name.

Modification History: None

Constraints: None

Usage: JCOP framework internal, public

PVSS manager usage: VISION, CTRL

@param typeRefToLookFor: The data point type reference to look for (eg. _FwDeclarations)
@param dpElementName: The name of the data point element to search for (eg. fwDeclarations)
@param returnList: The list of data point names is returned here
@param exception: Details of any exceptions are returned here

@author Herve Milcent (IT-CO)
*/
fwListManipulation_getListOfDpWithRef(string typeRefToLookFor, string dpElementName, 
				dyn_string &returnList, dyn_string &exception)
{
	int i;
	dyn_string typeList, dpList, tempDpList;
        
 	fwListManipulation_getListOfDpTypeWithRef(typeRefToLookFor, dpElementName, typeList, exception);

	for(i = 1; i<=dynlen(typeList);i++) {
		tempDpList = dpNames("*",typeList[i]);
		if(dynlen(tempDpList) > 0)
			dynAppend(dpList,tempDpList);
	}

	returnList = dpList;
}
//@}


