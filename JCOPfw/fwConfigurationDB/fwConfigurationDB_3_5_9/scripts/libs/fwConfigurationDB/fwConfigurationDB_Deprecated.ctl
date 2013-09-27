/**@file
 *
 * This package contains the set of functions provided for backward-compatibility
 *  or placeholders for deprecated functions
 *
 * @author Piotr Golonka (EN/ICE-SCD)
 * @date   December 2012
 */
global string _fwConfigurationDB_fileVersion_fwConfigurationDB_Deprecataed_ctl="3.5.9";



void _fwConfigurationDB_deprecated(string functionName, string comment="")
{
    DebugTN("ERROR! function "+functionName+" is deprecated", comment);
}

/** Gets the list of recipes available in database
 *
 * @param hierarchyType     dummy parameter now
 * @param recipeTags       the recipe names will be returned in this variable
 * @param exceptionInfo     standard exception handling variable
 *
 * @ingroup RecipeFunctions
 * @deprecated use @ref fwConfigurationDB_getRecipesInDB or @ref fwConfigurationDB_findRecipesInDB

 * @see @ref qstart_recipe_apply section of the Quick Start
 */
void fwConfigurationDB_GetRecipesInDB(string hierarchyType, dyn_string &recipeTags, dyn_string &exceptionInfo)
{
    _fwConfigurationDB_deprecated("fwConfigurationDB_GetRecipesInDB", "Use fwConfigurationDB_findRecipesInDB instead");
    fwConfigurationDB_findRecipesInDB (recipeTags, exceptionInfo,"*",hierarchyType);
}

/** Gets the list of recipes in database, for specified node
 *
 * @param nodeName          the name of the node (or device, or datapoint) for which recipes are queried
 * @param recipeNames       the recipe names will be returned in this variable
 * @param exceptionInfo     standard exception handling variable
 *
 * @ingroup RecipeFunctions
 * @see @ref qstart_recipe_apply section of the Quick Start
 * @deprecated use @ref fwConfigurationDB_getRecipesInDB or @ref fwConfigurationDB_findRecipesInDB
 */
void fwConfigurationDB_GetDBRecipesForNode(string nodeName, dyn_string &recipeNames, dyn_string &exceptionInfo)
{
    _fwConfigurationDB_deprecated("fwConfigurationDB_GetDBRecipesForNode", "Use fwConfigurationDB_findRecipesInDB instead");
    fwConfigurationDB_findRecipesInDB (recipeNames, exceptionInfo,"*","","*","*",nodeName);
}


/**
* @deprecated NO REPLACEMENT AVAILABLE
*/
void fwConfigurationDB_GetDBRecipeMetaInfo(string tag,
                                           string &recipeComment,
                                           int &numDevices,
                                           int &numValues,
                                           int &numAlerts,
                                           dyn_string &exceptionInfo)
{
    _fwConfigurationDB_deprecated("fwConfigurationDB_GetDBRecipeMetaInfo", 
	"NO REPLACEMENT AVAILABLE");
    fwException_raise(exceptionInfo,"ERROR","fwConfigurationDB_GetDBRecipeMetaInfo is DEPRECATED","");
    return;
}


/**
* @deprecated NO REPLACEMENT AVAILABLE
*/
void fwConfigurationDB_GetRecipeVersionsInDB(dyn_int &versions, dyn_string &descriptions,
                                             dyn_string &userCreated, dyn_string &dateCreated,
					     dyn_int &nDevices,
					     dyn_string &exceptionInfo)
{
    _fwConfigurationDB_deprecated("fwConfigurationDB_GetRecipeVersionsInDB", 
	"NO REPLACEMENT AVAILABLE");
    fwException_raise(exceptionInfo,"ERROR","fwConfigurationDB_GetRecipeVersionsInDB is DEPRECATED","");
    return;
}

/** Gets the list of recipes available in recipe caches
 *
 * @param hierarchyType     the type of Framework hierarchy, dummy now
 * @param recipeCacheNames  the recipe names will be returned in this variable
 * @param recipeCacheDPs    the list of datapoints corresponding to the recipe names will be stored in
 *                          returned in this variable
 * @param exceptionInfo     standard exception handling variable
 * @param system	    allows to look for recipe caches on remote systems
 *
 * @ingroup RecipeFunctions
 * @see @ref qstart_recipe_apply section of the Quick Start
 * @deprecated use @ref fwConfigurationDB_getRecipesInCache instead
 */
void fwConfigurationDB_GetRecipeCaches(string hierarchyType, dyn_string &recipeCacheNames,
 dyn_string &recipeCacheDPs, dyn_string &exceptionInfo, string system="")
{
    _fwConfigurationDB_deprecated("fwConfigurationDB_GetRecipeCaches", 
	"Use fwConfigurationDB_getRecipesInCache instead");

    dynClear(recipeCacheNames);
    dynClear(recipeCacheDPs);
    fwConfigurationDB_getRecipesInCache (recipeCacheNames, exceptionInfo, "*", system);

    for (int i=1;i<=dynlen(recipeCacheNames);i++) {
	recipeCacheDPs[i]=_fwConfigurationDB_getRecipeCacheDP(recipeCacheNames[i], exceptionInfo, FALSE);
	if (dynlen(exceptionInfo)) return;
    }
}

/** Gets the list of cached recipes for specified node
 *
 * @param nodeName          the name of the node (or device, or datapoint) for which recipes are queried
 * @param recipeNames       the recipe names will be returned in this variable
 * @param exceptionInfo     standard exception handling variable
 * @param system	    allows to look for recipe caches on remote systems
 *
 * @ingroup RecipeFunctions
 * @see @ref qstart_recipe_apply section of the Quick Start
 * @deprecated use @ref fwConfigurationDB_getRecipesInCache instead
 */
void fwConfigurationDB_GetCacheRecipesForNode(string nodeName, dyn_string &recipeNames, dyn_string &exceptionInfo, 
    string system="")
{
    _fwConfigurationDB_deprecated("fwConfigurationDB_GetCacheRecipesForNode", 
	"Use fwConfigurationDB_getRecipesInCache instead");

    fwConfigurationDB_getRecipesInCache (recipeNames, exceptionInfo, nodeName, system);
    if (dynlen(exceptionInfo)) return;
}


/**
* @deprecated NO REPLACEMENT AVAILABLE
*/
void fwConfigurationDB_storeDevicesInDB(string topDevice, string hierarchyType, dyn_string deviceDpNames,
                                           dyn_string &exceptionInfo, string systemName="")
{
    _fwConfigurationDB_deprecated("fwConfigurationDB_storeDevicesInDB", 
	"NO REPLACEMENT AVAILABLE");
    fwException_raise(exceptionInfo,"ERROR","fwConfigurationDB_storeDevicesInDB is DEPRECATED","");
    return;
}








/**
* @deprecated NO REPLACEMENT AVAILABLE
*/
void fwConfigurationDB_saveReferences(string configurationName, dyn_dyn_mixed deviceListObject, dyn_string &exceptionInfo)
{
    _fwConfigurationDB_deprecated("fwConfigurationDB_saveReferences", 
	"NO REPLACEMENT AVAILABLE");
    fwException_raise(exceptionInfo,"ERROR","fwConfigurationDB_saveReferences is DEPRECATED","");
    return;
}


/**
* @deprecated NO REPLACEMENT AVAILABLE
*/
void fwConfigurationDB_reconnectDevices(dyn_string deviceList, string configurationName,
	string hierarchyType, string targetSystem, dyn_string &exceptionInfo)
{
    _fwConfigurationDB_deprecated("fwConfigurationDB_reconnectDevices", 
	"Use the functionality provided by fwConfigurationDB_updateDeviceConfigurationFromDB instead.");
    fwException_raise(exceptionInfo,"ERROR","fwConfigurationDB_reconnectDevices is DEPRECATED","");
    return;

}



/** Creates missing devices in PVSS, so the structure reflects the one in the DB

note that it should work only for the local system

the systemName parameter is only meaning for logical hierarchy:
it indicates which type of logical hierarchy should be loaded: the one that includes system name,
or the one that does not (empty systemName). In the latter case, only the leaves that are currently
mapped to devices that are present on the current system are loaded, plus all the "branch" nodes that
lead to them...

@Deprecated use @ref fwConfigurationDB_updateDeviceConfigurationFromDB instead
*/
void fwConfigurationDB_updateDeviceHierarchyFromDB(string topDevice, string hierarchyType, dyn_string &exceptionInfo, string systemName="")
{
    _fwConfigurationDB_deprecated("fwConfigurationDB_updateDeviceHierarchyFromDB", 
	"Use fwConfigurationDB_updateDeviceConfigurationFromDB instead");
    fwException_raise(exceptionInfo,"ERROR","fwConfigurationDB_updateDeviceHierarchyFromDB is DEPRECATED","");
    return;
}


/** Finds the devices that exist and devices that do not exist,
 * returns them as deviceListObject variables, ready for further
 * processing.
 *
 * WARNING! Empty system name here means: don't filter!
 * @deprecated 
*/
void fwConfigurationDB_findDevicesInDB(string topDevice, string hierarchyType,
                                       dyn_string deviceList,
                                       dyn_dyn_mixed &deviceListObject, dyn_string &missingDevicesList,
                                       dyn_string &exceptionInfo, string system="")
{
    _fwConfigurationDB_deprecated("fwConfigurationDB_findDevicesInDB", 
	"NO REPLACEMENT AVAILABLE");
    fwException_raise(exceptionInfo,"ERROR","fwConfigurationDB_findDevicesInDB is DEPRECATED","");
    return;
}





/**
* @deprecated NO REPLACEMENT AVAILABLE
*/
void fwConfigurationDB_extractHierarchyFromDB(string topDevice, string hierarchyType,
                                              dyn_dyn_mixed &deviceListObject,
                                              dyn_string &exceptionInfo, string system="")
{
    _fwConfigurationDB_deprecated("fwConfigurationDB_extractHierarchyFromDB", 
	"NO REPLACEMENT AVAILABLE");
    fwException_raise(exceptionInfo,"ERROR","fwConfigurationDB_extractHierarchyFromDB is DEPRECATED","");
    return;
}


/**
* @deprecated NO REPLACEMENT AVAILABLE
*/
void fwConfigurationDB_getDeviceConfigurationFromDB(string configurationName,
    string hierarchyType, dyn_dyn_mixed &deviceListObject, dyn_string &exceptionInfo,
    time validOn=0, dyn_string deviceList="", string sysName="")
{
    _fwConfigurationDB_deprecated("fwConfigurationDB_getDeviceConfigurationFromDB", 
	"Use fwConfigurationDB_updateDeviceConfigurationFromDB instead");
    fwException_raise(exceptionInfo,"ERROR","fwConfigurationDB_getDeviceConfigurationFromDB is DEPRECATED","");
    return;
}

