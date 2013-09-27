/**@file
 *
 * This package contains the set of functions provided for bakward-compatibility
 *
 * @author Piotr Golonka (IT-CO/BE)
 * @date   August 2008
 */
global string _fwConfigurationDB_fileVersion_fwConfigurationDB_Deprecataed_ctl="3.3.52";


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
    fwConfigurationDB_findRecipesInDB (recipeNames, exceptionInfo,"*","","*","*",nodeName);
}



void _fwConfigurationDB_updateHierarchyView(dbConnection dbConn, dyn_string &exceptionInfo)
{
    DebugN("WARNING! updateHierarchyView is deprecated!");
}

/** Gets the database errors from PVSS

    WARNING! an "invalid connection" is not signalled as error,
        and it is not put in the exceptionInfo;
        It is trated separately -> indicated in the invalidConnection parameter.

*/
void _fwConfigurationDB_catchDbError(dbConnection &dbCon, bool &invalidConnection, dyn_string &exceptionInfo)
{
    DebugN("WARNING: _fwConfigurationDB_catchDbError should not be used! IT IS DEPRECATED. Please report to the developer");
    fwException_raise(exceptionInfo,"WARNING",
                      "_fwConfigurationDB_catchDbError should not be used! IT IS DEPRECATED. Please report to the developer","");
    return;
    /*
    int errorCount, errorNumber, errorNative;
    string errorDescription, SQLState;
    int rc=rdbGetError (dbCon, errorCount, errorNumber, errorNative, errorDescription, SQLState);
DebugN("RDBGetError:",errorCount, errorNumber, errorNative, errorDescription, SQLState);
    if (errorCount) {
        fwException_raise(exceptionInfo,"DB ERROR",errorDescription+"\n"+SQLState,"");
        DebugN("Database error",errorDescription,SQLState);
        return;
    }
*/
}

void fwConfigurationDB_GetDBRecipeMetaInfo(string tag,
                                           string &recipeComment,
                                           int &numDevices,
                                           int &numValues,
                                           int &numAlerts,
                                           dyn_string &exceptionInfo)
{
DebugN("WARNING: fwConfigurationDB_GetDBRecipeMetaInfo is deprecated");
}


void fwConfigurationDB_GetRecipeVersionsInDB(dyn_int &versions, dyn_string &descriptions,
                                             dyn_string &userCreated, dyn_string &dateCreated,
					     dyn_int &nDevices,
					     dyn_string &exceptionInfo)
{
DebugN("WARNING: fwConfigurationDB_GetRecipeVersionsInDB is deprecated");
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
    DebugN("WARNING: fwConfigurationDB_GetRecipeCaches is deprecated");

    dynClear(recipeCacheNames);
    dynClear(recipeCacheDPs);
    fwConfigurationDB_getRecipesInCache (recipeCacheNames, exceptionInfo, "*", system);

    for (int i=1;i<=dynlen(recipeCacheNames);i++) {
	recipeCacheDPs[i]=_fwConfigurationDB_getRecipeCacheDP(recipeCacheNames[i], exceptionInfo, FALSE);
	if (dynlen(exceptionInfo)) return;
    }

/*        

    dynClear(recipeCacheNames);
    dynClear(recipeCacheDPs);

    dyn_string tmpRecipeCacheDPs=dpNames("*","_FwRecipeCache");

    for (int i=1;i<=dynlen(tmpRecipeCacheDPs);i++) {
        string recipeName,hierarchy;
        dpGet(tmpRecipeCacheDPs[i]+".RecipeName",recipeName);
        // if the name is not defined, correct the situation immediately
        if (recipeName==""){
            recipeName=recipeCacheDPs[i];
            dpSetWait(tmpRecipeCacheDPs[i]+".RecipeName",recipeName);
        }
        dynAppend(recipeCacheDPs,tmpRecipeCacheDPs[i]);
        dynAppend(recipeCacheNames,recipeName);

    }
*/
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
    DebugN("WARNING: fwConfigurationDB_GetCacheRecipesForNode is deprecated");


    fwConfigurationDB_getRecipesInCache (recipeNames, exceptionInfo, nodeName, system);
    if (dynlen(exceptionInfo)) return;
/*

    string sysName=getSystemName();
    dynClear(recipeNames);
    dyn_string tmpRecipeCacheDPs=dpNames("*","_FwRecipeCache");

    for (int i=1;i<=dynlen(tmpRecipeCacheDPs);i++) {
        string recipeName;
        dyn_string devList;
        dpGet(tmpRecipeCacheDPs[i]+".RecipeName",recipeName,
              tmpRecipeCacheDPs[i]+".DataPoints.DPNames",devList);
        // if the name is not defined, correct the situation immediately
        if (recipeName==""){
            recipeName=tmpRecipeCacheDPs[i];
            dpSetWait(tmpRecipeCacheDPs[i]+".RecipeName",recipeName);
        }
        if ( (dynContains(devList,nodeName))||(nodeName=="")||(nodeName==sysName)) dynAppend(recipeNames,recipeName);

    }
*/
}


/**
 * @deprecated
  */
void fwConfigurationDB_storeDevicesInDB(string topDevice, string hierarchyType, dyn_string deviceDpNames,
                                           dyn_string &exceptionInfo, string systemName="")
{
    fwException_raise(exceptionInfo,"ERROR", "fwConfigurationDB_storeDevicesInDB() is deprecated","");
    return;
}
