/**@file
 *
 * This package contains recipes-related functions of the Configuration Database tool
 *
 * @author Piotr Golonka (EN/ICE-SCD)
 * @date   October 2012
 */
global string _fwConfigurationDB_fileVersion_fwConfigurationDB_Recipes_ctl="3.5.7";

/** Determines the default mode for recipe merge...
*/
global string fwConfigurationDB_defaultRecipeMergeMode="ELEMENT";


//__________________________________________________________________________
/** @name Error Codes in Recipes package
 *
 * see also @ref ErrorCodes "Error Codes overview" module.
 * @{
 */
const int fwConfigurationDB_ERROR_CantLoadPartOfRecipeType  = -51;
const int fwConfigurationDB_ERROR_NoValuesDataInRT          = -52;
const int fwConfigurationDB_ERROR_NoAlertsDataInRT          = -53;
const int fwConfigurationDB_ERROR_NoRecipeType              = -103;
const int fwConfigurationDB_ERROR_CantLoadRecipeType        = -104;
const int fwConfigurationDB_ERROR_InvalidDataPointName      = -105;
const int fwConfigurationDB_ERROR_StoreRecipeDataToCache    = -106;
const int fwConfigurationDB_ERROR_NoRecipeCache             = -107;
const int fwConfigurationDB_ERROR_GetRecipeFromCache        = -108;
const int fwConfigurationDB_ERROR_CreateRecipeCache         = -109;
const int fwConfigurationDB_ERROR_RecipeCacheExists         = -110;
const int fwConfigurationDB_ERROR_DPENotInRecipe            = -111;
///@} // end of Error codes
//______________________________________________________________________________


//__________________________________________________________________________
/**
 * @name Indexing constants for recipeObject variables
 *
 * The following constants are used to refer to the data in a single
 * row of a @ref recipeObject variable (a recipeRow).
 * @{
 */
const int fwConfigurationDB_RO_DPE_NAME         = 1;
const int fwConfigurationDB_RO_DP_NAME          = 2;
const int fwConfigurationDB_RO_DP_TYPE          = 3;
const int fwConfigurationDB_RO_ELEMENT_NAME     = 4;
const int fwConfigurationDB_RO_ELEMENT_TYPE     = 5;
const int fwConfigurationDB_RO_HIERARCHY        = 6;
const int fwConfigurationDB_RO_HAS_VALUE        = 7;
const int fwConfigurationDB_RO_HAS_ALERT        = 8;
const int fwConfigurationDB_RO_VALUE            = 9;
const int fwConfigurationDB_RO_ALERT_ACTIVE     = 10;
const int fwConfigurationDB_RO_ALERT_TEXTS      = 11;
const int fwConfigurationDB_RO_ALERT_LIMITS     = 12;
const int fwConfigurationDB_RO_ALERT_CLASSES    = 13;
const int fwConfigurationDB_RO_ALERT_TYPE       = 14;
const int fwConfigurationDB_RO_ALERT_MINIDX     = 10;
const int fwConfigurationDB_RO_ALERT_MAXIDX     = 14;

/** contains recipe version for this element, hence allows to
identify a group of elements of the same device with the same
identifier
*/
const int fwConfigurationDB_RO_REC_VERSIONID	= 15;

/** contains PROPID unique key identifying the property.
This one is unique for every device element
*/
const int fwConfigurationDB_RO_RECDATA_PROPID	= 16;
const int fwConfigurationDB_RO_DATECREATED	= 17;

const int fwConfigurationDB_RO_MAXIDX           = 17;

// these ones encode the meta-information for the whole recipe object.
// they are present only in the first row of the recipeObject
const int fwConfigurationDB_RO_METAINFO_START	= 18;

/** Original name of recipe at the source (e.g. in DB)
*/
const int fwConfigurationDB_RO_META_ORIGNAME	= 18;
const int fwConfigurationDB_RO_META_COMMENT	= 19;
const int fwConfigurationDB_RO_META_RECIPETYPE	= 20;

const int fwConfigurationDB_RO_META_CLASSNAME = 21;
const int fwConfigurationDB_RO_META_AUTHOR = 22;
const int fwConfigurationDB_RO_META_CREATIONTIME = 23;
const int fwConfigurationDB_RO_META_LASTACTIVATIONTIME = 24;
const int fwConfigurationDB_RO_META_LASTMODIFICATIONTIME = 25;
const int fwConfigurationDB_RO_META_LASTACTIVATIONUSER = 26;
const int fwConfigurationDB_RO_META_LASTMODIFICATIONUSER = 27;
const int fwConfigurationDB_RO_META_PREDEFINED = 28;
const int fwConfigurationDB_RO_META_RECIPEVERSION = 29;

const int fwConfigurationDB_RO_METAINFO_END	= 29;


///@} // end of indexing constants
//______________________________________________________________________________



//__________________________________________________________________________
/**
 * @name Indexing constants for recipeClassInfo variables
 *
 * The following constants are used to refer to the elements of the
 * recipeClassInfo objects
 * @{
 */
const int fwConfigurationDB_RCL_CLASSNAME=1;
const int fwConfigurationDB_RCL_RECIPETYPE=2;
const int fwConfigurationDB_RCL_DESCRIPTION=3;
const int fwConfigurationDB_RCL_ELEMENTS=4;
const int fwConfigurationDB_RCL_DEVICES=5; // READ ONLY! extract the list of device names
const int fwConfigurationDB_RCL_INSTANCES=6;
const int fwConfigurationDB_RCL_EDITABLE=7;
const int fwConfigurationDB_RCL_LAST_ACTIVATED_RECIPE=8;
const int fwConfigurationDB_RCL_LAST_ACTIVATED_TIME=9;
const int fwConfigurationDB_RCL_LAST_ACTIVATED_USER=10;
const int fwConfigurationDB_RCL_LAST_MODIFIED_TIME=11;
const int fwConfigurationDB_RCL_LAST_MODIFIED_USER=12;

const int fwConfigurationDB_RCL_MAXIDX=12;

///@} // end of indexing constants
//______________________________________________________________________________

//__________________________________________________________________________
/** @name Public Functions for Recipe Handling
 *
 *  Naming conventions:<ul>
 *  <li> operations: <ul>
 *        <li> load/save From/To Cache/DB </li>
 *        <li>  extract/apply </li>
 *        <li>  get Recipes In DB/Cache </li>
 *        <li>  get/set Description In Cache/DB </li>
 *    </ul>
 *  </li>
 *  <li> parameters:<ul>
 *     <li> recipeObject , recipeObject1, recipeObject2, diffRecipeObject, templateRecipeObject
 *  deviceName, deviceList, hierarchyType, recipeName, recipeList</li>
 *    </ul>
 *  </li>
 *  </ul>
 *
 * Note that the functions used in version 3.0.X will still be supported in 3.1.X,
 *  yet their use is deprecated.
 *
 * @{
 */

/** Loads a recipe from cache to recipe object
 *
 * @param recipeName 	the name of the recipe
 * @param deviceList	list of the devices for which recipe is loaded;
 *                      specifying empty list means: load the recipe data for all
 *			devices it includes
 * @param hierarchyType	the type of hierarchy (fwDevice_HARDWARE, fwDevice_LOGICAL)
 * @param recipeObject	the recipe data will be stored in this variable
 * @param exceptionInfo	standard exception handling routine
 * @param systemName	(optional) the name of the system; default value; empty string
 *			("") means local system (default)
 *
 * @see @ref fwConfigurationDB_getRecipeFromCache
 * @ingroup RecipeFunctions
 */
void fwConfigurationDB_loadRecipeFromCache(string recipeName, dyn_string deviceList,
	string hierarchyType, dyn_dyn_mixed &recipeObject, dyn_string &exceptionInfo,
	string systemName="")
{
    fwConfigurationDB_getRecipeFromCache (recipeName, deviceList, hierarchyType,
					    recipeObject, exceptionInfo, systemName);
}

/** Loads a recipe from database to recipe object
 *
 * @param recipeName 	the name of the recipe
 * @param deviceList	list of the devices for which recipe is loaded;
 *                      specifying empty list means: load the recipe data for all
 *			devices it includes
 * @param hierarchyType	the type of hierarchy (fwDevice_HARDWARE, fwDevice_LOGICAL)
 * @param recipeObject	the recipe data will be stored in this variable
 * @param exceptionInfo	standard exception handling routine
 * @param systemName	(optional) dummy
 * @param topDevice	(optional) the name of the top device in the hierarchy,
 *			from which the devices should be searched for. Allows to
 *			load the recipe for a sub-tree of devices that start at
 *			@em topDevice; it may also speed-up the search in the device
 *			tree. <br>
 *			By default, empty string is used which means: start the
 *			search from the top of the hierachy (i.e. search through
 *			the complete list of devices).
 *
 * @param validAt	(optional) allows to query the history of recipes; 0 (default)
 *			means: extract the recipe as it is configured now, other date
 *			means: extract the recipe as it looked at that date.
 * @see @ref fwConfigurationDB_getRecipeFromDB
 * @ingroup RecipeFunctions
 */
void fwConfigurationDB_loadRecipeFromDB(string recipeName, dyn_string deviceList,
	string hierarchyType, dyn_dyn_mixed &recipeObject, dyn_string &exceptionInfo,
	string systemName="", string topDevice="", time validAt=0)
{
    fwConfigurationDB_getRecipeFromDB (topDevice, deviceList, hierarchyType,
					    recipeName, recipeObject,
					    exceptionInfo, systemName, validAt);
}

/** Saves a recipe contained in recipeObject to the database
 *
 * If a recipe with specified name already exists, a new version
 * for the recipe is stored - the old settings for the device elements
 * include in the new recipe object are not lost - the history is kept.
 * Otherwise, a new recipe is created in the database.
 *
 * @param recipeObject	the recipe data that is to be stored
 * @param hierarchyType	the type of hierarchy (fwDevice_HARDWARE, fwDevice_LOGICAL)
 * @param recipeName 	the name for the recipe
 * @param exceptionInfo	standard exception handling routine
 * @param versionDescription (optional) description for the new version of recipe data.
 *	Note that this is not a recipe comment - it should be rather considered as
 *	the documentation of the reason for which the recipe is changed
 *	(e.g. like adding a comment when committing changes in CVS).
 * @param autoSaveDevices if true, the minimal configuration for devices will be stored
 *
 * @see @ref fwConfigurationDB_storeRecipeInDB
 * @ingroup RecipeFunctions
 */
void fwConfigurationDB_saveRecipeToDB(dyn_dyn_mixed recipeObject, string hierarchyType,
	string recipeName,  dyn_string &exceptionInfo, string versionDescription="",
    bool autoSaveDevices=FALSE)
{
//DebugTN("SaveRecipeToDB",autoSaveDevices);
    if (autoSaveDevices) {
	dyn_string deviceList=recipeObject[fwConfigurationDB_RO_DP_NAME];
//DebugTN("autosaving devices");
        int rc=fwConfigurationDB_saveDevicesToDBMinimal(deviceList,exceptionInfo,TRUE);
        if (dynlen(exceptionInfo)) return;
    }

    fwConfigurationDB_storeRecipeInDB (recipeObject, hierarchyType, versionDescription,
					    exceptionInfo, recipeName);
}

/** Saves a recipe contained in recipeObject to the cache
 *
 * If a recipe cache with specified name already exists, it is overwritten
 * by the new recipe. Otherwise a new recipe cache is created.
 *
 * @param recipeObject	the recipe data that is to be stored in the cache
 * @param hierarchyType	the type of hierarchy (fwDevice_HARDWARE, fwDevice_LOGICAL)
 * @param recipeName 	the name for the recipe cache
 * @param exceptionInfo	standard exception handling routine
 *
 * @see @ref fwConfigurationDB_storeRecipeInCache
 * @ingroup RecipeFunctions
 */
void fwConfigurationDB_saveRecipeToCache (dyn_dyn_mixed recipeObject, string hierarchyType,
	string recipeName,  dyn_string &exceptionInfo)
{
    fwConfigurationDB_storeRecipeInCache (recipeObject, recipeName, hierarchyType, exceptionInfo);
}

/** Saves a differential recipe to the database
 *
 * The function compares the data stored in the @em recipeObject with the
 * data saved in the recipe specified by @recipeName in the database,
 * then stores the changes (differences) to this recipe in the database.
 *
 * @param recipeObject	the recipe data that is to be stored in the cache
 * @param hierarchyType	the type of hierarchy (fwDevice_HARDWARE, fwDevice_LOGICAL)
 * @param recipeName 	the name of the recipe
 * @param exceptionInfo	standard exception handling routine
 * @param versionDescription (optional) description for the new version of recipe data.
 *	Note that this is not a recipe comment - it should be rather considered as
 *	the documentation of the reason for which the recipe is changed
 *	(e.g. like adding a comment when committing changes in CVS).
 *
 * @ingroup RecipeFunctions
 * @see @ref fwConfigurationDB_storeDiffRecipeInDB
 */
void fwConfigurationDB_saveDiffRecipeToDB(dyn_dyn_mixed recipeObject, string hierarchyType,
    string recipeName,  dyn_string &exceptionInfo, string versionDescription="", bool autoSaveDevices=FALSE)
{
    string system="";
    fwConfigurationDB_storeDiffRecipeInDB (recipeObject, hierarchyType, versionDescription,
		    exceptionInfo, recipeName, system,autoSaveDevices);
}

/** Creates a recipe containing current settings of the system
 *
 * For a list of devices specified in @em deviceList, the current values
 * and alarm settings are extracted from the system (according to selected
 * recipe type), and placed in the recipeObject.
 *
 * @param deviceList	the list of devices to be included in the recipe
 * @param hierarchyType	the type of hierarchy (fwDevice_HARDWARE, fwDevice_LOGICAL)
 * @param recipeObject	the recipe data will be stored in this variable
 * @param exceptionInfo	standard exception handling routine
 * @param recipeType	(optional) the recipe type to be used. By default (empty string),
 *		the currently selected recipe type will be used. Otherwise, the specified
 *		recipe type will be set as default using @ref fwConfigurationDB_setRecipeType.
 *
 * @see @ref fwConfigurationDB_GetRecipeFromSystem
 * @ingroup RecipeFunctions
 */
void fwConfigurationDB_extractRecipe(dyn_string deviceList, string hierarchyType, dyn_dyn_mixed &recipeObject, dyn_string &exceptionInfo,
                                     string recipeType="", dyn_string deviceSystems="", string recipeTypeSystem="")
{
    if ( (recipeType!="") && (recipeType!=GfwConfigurationDB_currentRecipeType) ){
//DebugN("setting recipe type");
	fwConfigurationDB_setRecipeType(recipeType,exceptionInfo,recipeTypeSystem);
	if (dynlen(exceptionInfo)) return;
    }
    fwConfigurationDB_GetRecipeFromSystem (recipeObject, deviceList, hierarchyType, exceptionInfo, deviceSystems);
}

/** Applies the recipe to the system
 *
 * @param recipeObject	the data containing the recipe to be applied
 * @param hierarchyType	the type of hierarchy (fwDevice_HARDWARE, fwDevice_LOGICAL)
 * @param exceptionInfo	standard exception handling routine
 * @param allowApplyRemote if set to TRUE, then it is possible to apply a recipe that
 *        contains setting for devices in other systems
 *
 * @see @ref fwConfigurationDB_ApplyRecipe
 * @ingroup RecipeFunctions
 */
void fwConfigurationDB_applyRecipe(dyn_dyn_mixed recipeObject, string hierarchyType, dyn_string &exceptionInfo,bool
    allowApplyRemote=FALSE)
{
    fwConfigurationDB_ApplyRecipe (recipeObject, hierarchyType, exceptionInfo,allowApplyRemote);
}


/** Gets the description of the recipe cache
 *
 * @param recipeName	specifies the name of the recipe (cache)
 * @param recipeDescription	on return will contain the description of the recipe
 * @param exceptionInfo	standard exception handling routine
 *
 * @ingroup RecipeFunctions
 */
void fwConfigurationDB_getRecipeDescriptionInCache(string recipeName, string &recipeDescription, dyn_string &exceptionInfo)
{
    string dpName=_fwConfigurationDB_getRecipeCacheDP(recipeName, exceptionInfo, FALSE);
    if (dynlen(exceptionInfo)) return;

    int rc=dpGet(dpName+".RecipeComment",recipeDescription);
    if (rc) {
        fwException_raise(exceptionInfo,
                          "ERROR",
                          "Cannot get comment for recipe cache "+recipeName+".","");
        return;
    }
}

/** Gets the description of the recipe stored in database
 *
 * @param recipeName	specifies the name of the recipe
 * @param recipeDescription	on return will contain the description of the recipe
 * @param exceptionInfo	standard exception handling routine
 *
 * @ingroup RecipeFunctions
 */
void fwConfigurationDB_getRecipeDescriptionInDB(string recipeName, string &recipeDescription, dyn_string &exceptionInfo)
{
    string sql="SELECT DESCRIPTION FROM RECIPES WHERE NAME=\'"+recipeName+"\'";

    dyn_dyn_mixed aRecords;
    _fwConfigurationDB_executeDBQuery(sql,g_fwConfigurationDB_DBConnection, aRecords, exceptionInfo,1,TRUE);
    if (dynlen(exceptionInfo)) return;

    if (dynlen(aRecords)<1) {
	fwException_raise(exceptionInfo,"ERROR","Cannot locate recipe "+recipeName+" in the database","");
	return;
    }
    recipeDescription=aRecords[1][1];

}

/** Sets the description of the recipe cache
 *
 *
 * @param recipeName	specifies the name of the recipe (cache)
 * @param recipeDescription	should contain the new description for the recipe
 * @param exceptionInfo	standard exception handling routine
 *
 * @ingroup RecipeFunctions
 */
void fwConfigurationDB_setRecipeDescriptionInCache(string recipeName, string recipeDescription, dyn_string &exceptionInfo)
{
    string dpName=_fwConfigurationDB_getRecipeCacheDP(recipeName, exceptionInfo);
    if (dynlen(exceptionInfo)) return;

    int rc=dpSetWait(dpName+".RecipeComment",recipeDescription);
    if (rc) {
        fwException_raise(exceptionInfo,
                          "ERROR",
                          "Cannot set comment for recipe cache "+recipeName+".","");
        return;
    }
}

/** Sets the description of the recipe in database
 *
 * @param recipeName	specifies the name of the recipe (cache)
 * @param recipeDescription	should contain the new description for the recipe
 * @param exceptionInfo	standard exception handling routine
 *
 * @ingroup RecipeFunctions
 */
void fwConfigurationDB_setRecipeDescriptionInDB(string recipeName, string recipeDescription, dyn_string &exceptionInfo)
{
    if (fwConfigurationDB_SchemaPrivs!="OWNER" && fwConfigurationDB_SchemaPrivs!="WRITER") {
	fwException_raise(exceptionInfo,"ERROR","Insufficient database rights for changing recipes","");
	return;
    }


    string sql="UPDATE RECIPES SET DESCRIPTION=\'"+recipeDescription+"\' WHERE NAME=\'"+recipeName+"\'";

    fwConfigurationDB_executeSqlSimple(sql,g_fwConfigurationDB_DBConnection, exceptionInfo);
}

/** Sets the recipeType info for the recipe in database
 *
 * @param recipeName	specifies the name of the recipe (cache)
 * @param recipeTypeName should contain the new recipeType for the recipe
 * @param exceptionInfo	standard exception handling routine
 *
 * @ingroup RecipeFunctions
 */
void fwConfigurationDB_setRecipeTypeInfoInDB(string recipeName, string recipeTypeName, dyn_string &exceptionInfo)
{
    if (fwConfigurationDB_SchemaPrivs!="OWNER" && fwConfigurationDB_SchemaPrivs!="WRITER") {
	fwException_raise(exceptionInfo,"ERROR","Insufficient database rights for changing recipes","");
	return;
    }
    string sql="UPDATE RECIPES SET RECIPE_TYPE=\'"+recipeTypeName+"\' WHERE NAME=\'"+recipeName+"\'";

    fwConfigurationDB_executeSqlSimple(sql,g_fwConfigurationDB_DBConnection, exceptionInfo);
}



/** Gets the list of recipes available in database
 *
 * @param recipeList	on return will contain the list of recipe names (cache names)
 * @param exceptionInfo	standard exception handling routine
 * @param deviceName	(optional) the device for which the recipes are being looked-up;
 *			specifying empty string (default) returns all available recipes
 *
 * @see @ref fwConfigurationDB_findRecipesInDB
 * @ingroup RecipeFunctions
 */
void fwConfigurationDB_getRecipesInDB(dyn_string &recipeList, dyn_string &exceptionInfo, string deviceName="")
{
    if (deviceName=="") deviceName="*";

    fwConfigurationDB_findRecipesInDB (recipeList, exceptionInfo,"*","","*","*",deviceName);
}



/** Gets the list of recipes available in cache on local or remote system
 *
 * @param recipeList	on return will contain the list of recipe names
 * @param exceptionInfo	standard exception handling routine
 * @param deviceName	(optional) the device for which the recipes are being looked-up;
 *			specifying empty string (default) returns all available recipes
 *			in the system.
 * @param system	allows to get the list of recipe caches on a remote system.
 * @see @ref fwConfigurationDB_findRecipesInCache
 * @ingroup RecipeFunctions
 */
void fwConfigurationDB_getRecipesInCache (dyn_string &recipeList, dyn_string &exceptionInfo, string deviceName="", string system="")
{
    if ( (system!="") && (system[strlen(system)-1]!=":")) {
	fwException_raise(exceptionInfo,"ERROR in getRecipesInCache","The name of system does not end with colon "+system,"");
	return;
    }

    if (deviceName=="") deviceName="*";

    string recipeNameFilter=system+"*";
    fwConfigurationDB_findRecipesInCache (recipeList, exceptionInfo, recipeNameFilter,"","*","*",deviceName);

    if (dynlen(exceptionInfo)) return;
}


/** Returns meta-information describing a recipe in cache

*/
void fwConfigurationDB_getRecipeMetaInfoInCache (string recipeName, dyn_string &exceptionInfo,
    string &hierarchyType, string &recipeComment, string &recipeType)
{

    hierarchyType="";

    string dp=_fwConfigurationDB_getRecipeCacheDP(recipeName, exceptionInfo);
    if (dynlen(exceptionInfo)) return;

    int rc=dpGet(dp+".RecipeComment",recipeComment,
		dp+".RecipeType",recipeType);
    if (rc) {
	fwException_raise(exceptionInfo,"ERROR","Cannot get recipe meta information for "+recipeName,"");
	return;
    }

}

/** Returns meta-information describing a recipe in database

*/
void fwConfigurationDB_getRecipeMetaInfoInDB (string recipeName, dyn_string &exceptionInfo,
    string &hierarchyType, string &recipeComment, string &recipeType)
{
    if (fwConfigurationDB_SchemaPrivs!="OWNER" && fwConfigurationDB_SchemaPrivs!="WRITER" && fwConfigurationDB_SchemaPrivs!="READER") {
	fwException_raise(exceptionInfo,"ERROR","Insufficient database rights to get recipes","");
	return;
    }

    string sql="SELECT hver,description, recipe_type from recipes where name=\'"+recipeName+"\'";
    dyn_dyn_mixed aRecords;
    _fwConfigurationDB_executeDBQuery(sql,g_fwConfigurationDB_DBConnection, aRecords, exceptionInfo,3,TRUE);
    if (dynlen(exceptionInfo)) return;
    if (dynlen(aRecords)<1) {
	fwException_raise(exceptionInfo,"ERROR","Recipe "+recipeName+" does not exist in DB","");
	return;
    }

    recipeComment=aRecords[2][1];
    recipeType=aRecords[3][1];
    hierarchyType="UNKNOWN";
    int hType=aRecords[1][1];

    for (int i=1;i<=mappinglen(g_fwConfigurationDB_DBHierarchyIDs);i++) {
	string mkey=mappingGetKey(g_fwConfigurationDB_DBHierarchyIDs, i);
	int mval=mappingGetValue(g_fwConfigurationDB_DBHierarchyIDs, i);
	if (mval==hType) {
	    hierarchyType=mkey;
	    break;
	}
    }

}




/** returns the list of recipes in cache matching specified criteria

@returns the number of matching recipes found

*/
int fwConfigurationDB_findRecipesInCache (dyn_string &recipeNames, dyn_string &exceptionInfo,
    string recipeName="*", string hierarchyType="*", string recipeComment="*", string recipeType="*", string deviceName="*",
    string recipeClass="*")
{
    // find out system name, if user specified it in the recipeName
    string sys="";

    if (strpos(recipeName,":")>=0) {
	dyn_string ds=strsplit(recipeName,":");
	sys=ds[1]+":";
	if (dynlen(ds)>1) {
	    recipeName=ds[2];
	}
	int sysid=getSystemId(sys);
	// make sure the system is present
	if (sysid<0) {
	    fwException_raise(exceptionInfo,"ERROR in findRecipesInCache",
	    "Remote system "+sys+" does not exist","");
	    return 0;
	}
    }

    if (sys==":") sys="";

    if (recipeName=="") recipeName="*";
    if (recipeType=="") recipeType="*";
    if (recipeClass=="") recipeClass="*";

    string dpquery="SELECT '_online.._value' FROM 'RecipeCache/"+recipeName+".RecipeName'";

    string where="";

    if (recipeComment!="*") {
	if (where!="") where+=" AND ";

	if ( (strpos(recipeComment,"*")>=0) || (strpos(recipeComment,"?")>=0) )
	    where += " ('.RecipeComment:_online.._value' LIKE \""+recipeComment+"\")";
	else
	    where += " ('.RecipeComment:_online.._value' == \""+recipeComment+"\")";
    }

    if (recipeType!="*") {
	if (where!="") where+=" AND ";

	if ( (strpos(recipeType,"*")>=0) || (strpos(recipeType,"?")>=0) )
	    where += " ('.RecipeType:_online.._value' LIKE \""+recipeType+"\")";
	else
	    where += " ('.RecipeType:_online.._value' == \""+recipeType+"\")";
    }
    if (recipeClass!="*") {
	if (where!="") where+=" AND ";

	if ( (strpos(recipeClass,"*")>=0) || (strpos(recipeClass,"?")>=0) )
	    where += " ('.MetaInfo.ClassName:_online.._value' LIKE \""+recipeClass+"\")";
	else
	    where += " ('.MetaInfo.ClassName:_online.._value' == \""+recipeClass+"\")";
    }

    if (sys!="") dpquery+=" REMOTE '"+strrtrim(sys,":")+"' ";

    if (where!="") dpquery+=" WHERE "+where;
    dyn_dyn_anytype result;
    int rc=dpQuery(dpquery,result);
    if (rc<0) {
	fwException_raise(exceptionInfo,"ERROR","Cannot query recipe caches","");
	return 0;
    }

    dyn_string dps;
    for (int i=2;i<=dynlen(result);i++) {
	string d=result[i][1];
	// strip system name, if recipe is local...
	if (sys=="") {
	    d=dpSubStr(d,DPSUB_DP);
	} else {
	    d=dpSubStr(d,DPSUB_SYS_DP);
	}
	if (d!="") dynAppend(dps,d);
    }

    dynUnique(dps);

    //scan the device lists...
    if (deviceName!="*") {
	dyn_string newDpsList;
	for (int i=1;i<=dynlen(dps);i++) {
	    dyn_string devlist;
	    dpGet(dps[i]+".DataPoints.DPNames",devlist);

	    if ( (strpos(deviceName,"*")>=0) || (strpos(deviceName,"?")>=0) ) {
		dyn_string match=dynPatternMatch(deviceName,devlist);
		if (dynlen(match)) dynAppend(newDpsList,dps[i]);
	    } else {
		if (dynContains(devlist,deviceName)) dynAppend(newDpsList,dps[i]);
	    }
	}
	dps=newDpsList;
    }

    int prefixlen=strlen(sys+fwConfigurationDB_RecipeCacheDpPrefix);
    for (int i=1;i<=dynlen(dps);i++) {
	string recName=substr(dps[i],prefixlen);
	if (sys!="") recName=sys+recName;
	recipeNames[i]=recName;
    }

    return dynlen(recipeNames);

}

/** returns the list of recipes in the database matching specified criteria

@returns the number of matching recipes found, or -1 in case of error

*/
int fwConfigurationDB_findRecipesInDB (dyn_string &recipeNames, dyn_string &exceptionInfo,
    string recipeName="*",
    string hierarchyType="", string recipeComment="*", string recipeType="*", string deviceName="*")

{
    dynClear(recipeNames);
    dyn_dyn_mixed aRecords;

    if (fwConfigurationDB_SchemaPrivs!="OWNER" && fwConfigurationDB_SchemaPrivs!="WRITER" && fwConfigurationDB_SchemaPrivs!="READER") {
	fwException_raise(exceptionInfo,"ERROR","Insufficient database rights to get recipes","");
	return -1;
    }

    fwConfigurationDB_callPlSqlApi( "getRecipesList",
		    makeDynMixed(recipeName,deviceName,recipeComment,recipeType),
		    "", "s1",makeDynMixed(), aRecords,exceptionInfo);

    if (dynlen(exceptionInfo)) return -1;

    if (dynlen(aRecords)>=1) recipeNames=aRecords[1];

    dynSortAsc(recipeNames);
    return dynlen(recipeNames);
}



/** Opens recipe editor panel.
 *
 *    May only be used from UI manager.
 *
 * @returns TRUE if the recipe was changed (i.e. OK was clicked)
 * @ingroup RecipeFunctions
 */
bool fwConfigurationDB_editRecipe(dyn_dyn_mixed &recipeObject, bool readOnly=FALSE, string description="")
{
    dyn_float df;
    dyn_string ds;
    bool changed=FALSE;

    if (dynlen(recipeObject)==0) _fwConfigurationDB_ClearRecipeObject(recipeObject);


    if (description=="") {
	if (readOnly) description="View recipe";
	else description="Edit recipe";
    }

    addGlobal("g_fwConfigurationDB_editRecipeObject",DYN_DYN_MIXED_VAR);
    g_fwConfigurationDB_editRecipeObject=recipeObject;

    ChildPanelOnCentralReturn("fwConfigurationDB/fwConfigurationDB_RecipeEdit.pnl",
			    description,
	    makeDynString("$recipeObjectVarName:g_fwConfigurationDB_editRecipeObject",
			  "$readOnlyMode:"+readOnly,
			  "$description:"+description),
	    df,ds);

    if ((dynlen(df)) && (df[1]==1.0)){
	recipeObject=g_fwConfigurationDB_editRecipeObject;
	changed=TRUE;
    }

    removeGlobal("g_fwConfigurationDB_editRecipeObject");
    return changed;
}

/** Make a recipe out of a recipe template and a list of devices (items)
 *
 * @param deviceNames list of target device (item) names; the must exist in the current system.
 * @param hierarchyType (dummy)
 * @param templRecipeObject a recipeObject that contains the recipe template.
 * @param recipeObject on return the recipe made of template will be appended to this object
 * @param exceptionInfo standard exception handling variable
 * @ingroup RecipeFunctions
*/
void fwConfigurationDB_makeRecipeFromTemplate(dyn_string deviceNames, string hierarchyType,
		    dyn_dyn_mixed templRecipeObject, dyn_dyn_mixed &recipeObject, dyn_string &exceptionInfo)
{

dyn_dyn_mixed lRecipeObject;
_fwConfigurationDB_ClearRecipeObject(lRecipeObject);
if (!dynlen(templRecipeObject)) _fwConfigurationDB_ClearRecipeObject(templRecipeObject);

// we store the row indices of the templRecipeObject, which contain data for mapped device type...
mapping templRecipe_DevTypes;
for (int i=1;i<=dynlen(templRecipeObject[fwConfigurationDB_RO_DP_TYPE]);i++) {
    string devType=templRecipeObject[fwConfigurationDB_RO_DP_TYPE][i];
    dyn_int indices;
    if (mappingHasKey(templRecipe_DevTypes,devType)) indices=templRecipe_DevTypes[devType];
    dynAppend(indices,i);
    templRecipe_DevTypes[devType]=indices;
}


for (int i=1;i<=dynlen(deviceNames);i++) {
    string deviceName=deviceNames[i];
    string hwDevName;
    if (strpos(deviceName,":")>0) {
	// it is hardware hierarchy
	hwDevName=deviceName;
	if (!dpExists(hwDevName)) { fwException_raise(exceptionInfo,"ERROR","Device "+deviceName+" does not exist",""); return;}
    } else {
	// it is logical...
        hwDevName=dpSubStr(dpAliasToName(deviceName),DPSUB_SYS_DP);
        if (hwDevName=="") { fwException_raise(exceptionInfo,"ERROR","Logical device "+deviceName+" does not exist",""); return;}
    }


    string devType=dpTypeName(hwDevName);

    if (devType=="FwNode") continue;

    if (!mappingHasKey(templRecipe_DevTypes,devType)) {
	fwException_raise(exceptionInfo, "ERROR","Recipe template has no device of type "+devType+
						  "\n needed for "+deviceName,"");
	return;
    }

    dyn_string srcIndices=templRecipe_DevTypes[devType];

    // now copy the template data for all indices...
    for (int j=1;j<=dynlen(srcIndices);j++) {
	int src_idx=srcIndices[j];
	int dst_idx=1+dynlen(lRecipeObject[fwConfigurationDB_RO_DPE_NAME]);
	// at first make a copy of template data ...
	for (int k=1;k<=fwConfigurationDB_RO_MAXIDX;k++) {
	    lRecipeObject[k][dst_idx]=templRecipeObject[k][src_idx];
	}
	// then make appropriate corrections...
        string elementName=templRecipeObject[fwConfigurationDB_RO_ELEMENT_NAME][src_idx];
	lRecipeObject[fwConfigurationDB_RO_DPE_NAME][dst_idx]=hwDevName+elementName;
	lRecipeObject[fwConfigurationDB_RO_DP_NAME ][dst_idx]=deviceName;

    }
}

    // combine the recipes...
    fwConfigurationDB_combineRecipes(  recipeObject,
                                       recipeObject,
	                               lRecipeObject,
    	    			       exceptionInfo);
    if (dynlen(exceptionInfo)) return;

}


/** sets the recipe type to be used
 * @param recipeType	specifies the name of the recipe type
 * @param exceptionInfo 	standard exception handling variable
 * @param systemName	allows to use recipe type on remote systems
 * @exception exceptionInfo[3] may return the following error codes:
 * - @ref fwConfigurationDB_ERROR_CantLoadPartOfRecipeType (warning)
 * - @ref fwConfigurationDB_ERROR_NoRecipeType (error)
 * - @ref fwConfigurationDB_ERROR_CantLoadRecipeType (error)
 *
 * If any of the error exceptions was signaled, the current recipe type is
 * reset to an empty recipe.
 * @ingroup RecipeFunctions
 * @see @ref qstart_recipes section of Quick Start
 */
void fwConfigurationDB_setRecipeType(string recipeType, dyn_string &exceptionInfo, string systemName="")
{

    // local variables that will substitute the global at the end:
    mapping RTValues, RTAlerts, RTDevices;

    // clear the old one ...
    GfwConfigurationDB_currentRecipeType = "";
    GfwConfigurationDB_RTValues		 = RTValues;
    GfwConfigurationDB_RTAlerts		 = RTAlerts;
    GfwConfigurationDB_RTDevices	 = RTDevices;

    // the default one ...
    if (recipeType=="") recipeType=_GfwConfigurationDB_defaultRecipeType;

    if (systemName!="") {
	int sysid=getSystemId(systemName);
	if (sysid==-1) {
            fwException_raise(exceptionInfo,"ERROR in setRecipeType",
        	"No such system "+systemName ,
        	fwConfigurationDB_ERROR_NoRecipeCache);
            return;
	}
    }

    string dpName=systemName+fwConfigurationDB_RecipeTypeDpPrefix+recipeType;


    if (!dpExists(dpName)) {
    	fwException_raise(exceptionInfo,"ERROR","Recipe type: "+recipeType+" does not exist.",fwConfigurationDB_ERROR_NoRecipeType);
    	return;
    };

    dyn_string RTList;
    int i,rc;

    rc=dpGet(dpName+".RecipeTypeList",RTList);
    if (rc) {
        fwException_raise(exceptionInfo,
                          "ERROR",
                          "Cannot load recipe type "+recipeType+".",
                          fwConfigurationDB_ERROR_CantLoadRecipeType);
        return;
    };

    for (i=1;i<=dynlen(RTList);i++) {
        string RTDPT=systemName+RTList[i];
        if (!dpExists(RTDPT)) {
            fwException_raise(exceptionInfo,
                              "WARNING",
                              "Cannot load part of recipe type "+RTDPT+". It does not exist",
                              fwConfigurationDB_ERROR_CantLoadPartOfRecipeType);
	    // this is only a warning, we do not abort yet.
        };

        string DeviceType, DPType;
        dyn_string Values, Alerts;

        rc=dpGet(RTDPT + ".DPType", DPType,
                 RTDPT + ".SavePropertyValue", Values,
                 RTDPT + ".SaveAlert",Alerts);

        if (rc) {
            fwException_raise(exceptionInfo,
                              "WARNING",
                              "Cannot load part of recipe type "+RTDPT+". Cannot get the data",
                              fwConfigurationDB_ERROR_CantLoadPartOfRecipeType);
	    // this is only a warning, we do not abort yet.
        };
        DeviceType=_fwConfigurationDB_getFwDeviceName (DPType, exceptionInfo);
        if (dynlen(exceptionInfo)) return;
        RTValues[DPType] = Values;
        RTAlerts[DPType] = Alerts;
        RTDevices[DPType] = DeviceType;
    };

    GfwConfigurationDB_currentRecipeType = recipeType;
    GfwConfigurationDB_RTValues		 = RTValues;
    GfwConfigurationDB_RTAlerts		 = RTAlerts;
    GfwConfigurationDB_RTDevices	 = RTDevices;
//    DebugN("set recipe type:",recipeType);
}

/** combines two recipe objects
 * This function combines two recipe object into third object.
 * For the entries that exist in both source recipes,
 * the one in the second recipe have precedence, and will be used.
 *
 * The meta-information is treated in the following way:
 * if there is no meta information yet in the first recipe,
 * the meta information from @em srcRecipeObject2 is taken;
 * otherwise, if there is already a meta-information in the
 * @em srcRecipeObject1, it is discarded except the recipe type
 * name - this one will be set in the @em dstRecipeObject if
 * it is set in both srcRecipeObjects to equal values.
 *
 * @param dstRecipeObject  on return will contain the combined recipe
 * @param srcRecipeObject1  first recipe to combine
 * @param srcRecipeObject2  second recipe to combine
 * @param exceptionInfo standard exception handling variable
 * @param mergeMode (optional, default="")  determines the mode
 *		in which the merge is performed;
 *		"DEVICE" - the mode is per device
 *		"ELEMENT" - the mode is per element
 *		"" - take the global setting
 *
 * @ingroup RecipeFunctions
 * @see @ref qstart_recipes section of Quick Start
 */
void fwConfigurationDB_combineRecipes( 	dyn_dyn_mixed &dstRecipeObject,
					dyn_dyn_mixed srcRecipeObject1,
					dyn_dyn_mixed srcRecipeObject2,
					dyn_string &exceptionInfo,
					string mergeMode="")
{
    time t0;
    _fwConfigurationDB_startFunction("combineRecipes", t0);

    if (mergeMode=="") {
	mergeMode=fwConfigurationDB_defaultRecipeMergeMode;
    };

    if (mergeMode!="DEVICE" && mergeMode!="ELEMENT"){
	fwException_raise(exceptionInfo,"ERROR in combineRecipes","Bad mergeMode="+mergeMode,"");
	return;
    }

    if (!dynlen(srcRecipeObject1)) _fwConfigurationDB_ClearRecipeObject(srcRecipeObject1);
    if (!dynlen(srcRecipeObject2)) _fwConfigurationDB_ClearRecipeObject(srcRecipeObject2);

    dyn_dyn_mixed recipeObject;
    _fwConfigurationDB_ClearRecipeObject(recipeObject);

    dyn_string names1=srcRecipeObject1[fwConfigurationDB_RO_DPE_NAME];   // need to cast to dyn_string
    dyn_string names2=srcRecipeObject2[fwConfigurationDB_RO_DPE_NAME]; // need to cast to dyn_string

    dyn_string commonNames=dynIntersect(names2,names1);

    // we alse need to treat the cases of dbRecipeObject[fwConfigurationDB_RO_DPE_NAME][i]=="",
    // i.e. where the logical device was not mapped to any hardware devices...
    int idxCommon=dynContains(commonNames,""); if (idxCommon) dynRemove(commonNames,idxCommon);

    dyn_string deviceNames1,deviceNames2;
    dyn_string commonDeviceNames;
    if (mergeMode=="DEVICE") {
	// extract device names
	for (int i=1;i<=dynlen(names1);i++) {
	    dyn_string ds=strsplit(names1[i],".");
	    if (dynlen(ds)<1) ds[1]="";
	    dynAppend(deviceNames1,ds[1]);
	}
	for (int i=1;i<=dynlen(names2);i++) {
	    dyn_string ds=strsplit(names2[i],".");
	    if (dynlen(ds)<1) ds[1]="";
	    dynAppend(deviceNames2,ds[1]);
	}
	dyn_string uniqDevNames1=deviceNames1;
	dyn_string uniqDevNames2=deviceNames2;
	dynUnique(uniqDevNames1);
	dynUnique(uniqDevNames2);
	commonDeviceNames=dynIntersect(uniqDevNames2,uniqDevNames1);
	int idxCommonDevices=dynContains(commonDeviceNames,""); if (idxCommonDevices) dynRemove(commonDeviceNames,idxCommonDevices);
    }



    int idx=0;
    // get the ones from the first recipe, that are not in the second one...
    for (int i=1;i<=dynlen(names1);i++) {
	bool doCopy=FALSE;
	if (names1[i]=="") {
	    // again: in the case of a not-mapped logical device we need extra treatment:
	    //  look at the DP_NAME column, and see if it is there
	    int idx1=dynContains(srcRecipeObject2[fwConfigurationDB_RO_DP_NAME],srcRecipeObject1[fwConfigurationDB_RO_DP_NAME][i]);
	    if (!idx1) {
		// dp name ain't match: it does not exist in srcRecipeObject2, so we want to copy it...
		doCopy=TRUE;
	    } else {
		if (mergeMode=="DEVICE") {
		    doCopy=FALSE;
		    continue;
		}
		// and for the mergeMode=ELEMENT, the answer is not so simple...
		// the element name exists somewhere - we need to do thorough checking at the element level...
		doCopy=TRUE;
		for (int k=1;k<=dynlen(names2);k++) {
		    if ( (srcRecipeObject2[fwConfigurationDB_RO_DP_NAME][k]==srcRecipeObject1[fwConfigurationDB_RO_DP_NAME][i]) &&
		         (srcRecipeObject2[fwConfigurationDB_RO_ELEMENT_NAME][k]==srcRecipeObject1[fwConfigurationDB_RO_ELEMENT_NAME][i]) ) {

			doCopy=FALSE;
			continue;
		    }
		}
	    }
	} else {
	    // majority of cases is here - the name is specified OK
	    if (mergeMode=="ELEMENT") {
		if (!dynContains(commonNames,names1[i])) {
		    doCopy=TRUE;
		}
	    } else if (mergeMode=="DEVICE") {
		if (!dynContains(commonDeviceNames,deviceNames1[i])) {
		    doCopy=TRUE;
		}
	    }
	}

	if (doCopy) {
	    // copy!
	    idx++;
	    for (int j=1;j<=fwConfigurationDB_RO_MAXIDX;j++) recipeObject[j][idx]=srcRecipeObject1[j][i];
	}
    }
	
    // now append all the entries from second recipe
    for (int i=1;i<=fwConfigurationDB_RO_MAXIDX;i++) {
	dynAppend(recipeObject[i],srcRecipeObject2[i]);
    }

    // meta info
    // we take the defaults from src1, 
    // and then if there is meta info in src2, then we overwrite 
    // this will allow us to preserve meta info, FWCDB-1051, FWCDB-1048

    // firstly take a copy from src1, if it exists...
    int len1=dynlen(srcRecipeObject1);
    for (int i=fwConfigurationDB_RO_METAINFO_START;i<=fwConfigurationDB_RO_METAINFO_END;i++) {
      if (i>len1) break;
      dyn_mixed col=srcRecipeObject1[i];
      recipeObject[i]=col;
    }
    
    // then, append/overwrite with what is in src2 (if defined)
    int len2=dynlen(srcRecipeObject2);
    for (int i=fwConfigurationDB_RO_METAINFO_START;i<=fwConfigurationDB_RO_METAINFO_END;i++) {
      if (i>len2) break;
      dyn_mixed col=srcRecipeObject2[i];
      if (dynlen(col)) recipeObject[i]=col;

    }
    dstRecipeObject=recipeObject;

    _fwConfigurationDB_endFunction("combineRecipes", t0);
}




///@} // end of Public Recipe Functions
//______________________________________________________________________________
















/** Reads properties of device(s) from PVSS and stores in recipeObject
 *
 * This function reads the data from specified data points (devices),
 * according to current recipeType, then appends it to the data
 * already stored in the recipeObject.
 *
 * @param recipeObject     the structure containing recipe data.
 *                          The new settings will be appended to it.
 *                          See also @ref recipeObject data structure description.
 * @param deviceList        list of device names (from whatever hierarchy)
 * @param hierarchyType	hierarchy type - not used anymore!
 * @param exceptionInfo 	standard exception handling variable
 *
 * @see @ref qstart_recipes section of Quick Start
 * @ingroup RecipeFunctions
 * @deprecated Please use @ref fwConfigurationDB_extractRecipe instead
 */
void fwConfigurationDB_GetRecipeFromSystem(dyn_dyn_mixed &recipeObject,
                                           dyn_string deviceList,
                                           string hierarchyType,
                                           dyn_string &exceptionInfo, dyn_string deviceSystems = "")
{
    time t0;
    _fwConfigurationDB_startFunction("GetRecipeFromSystem", t0);

    int i,idx;


    // protection from the case when recipeObject is empty...
    if (dynlen(recipeObject)==0) _fwConfigurationDB_ClearRecipeObject(recipeObject);

    if (!dynlen(deviceList)) {
	_fwConfigurationDB_setRecipeOriginalRecipeType(recipeObject, GfwConfigurationDB_currentRecipeType, exceptionInfo);
	fwConfigurationDB_progress(fwConfigurationDB_OPER_GetRecipeFromSystem,"Extracted empty recipe from system", 100.0, exceptionInfo);
	return;
    }


    if (fwConfigurationDB_progress(fwConfigurationDB_OPER_GetRecipeFromSystem,"Resolving devices",
        5.0, exceptionInfo)) return;

    dynUnique(deviceList);

    dyn_string devHierarchies, devDatapoints;
    fwConfigurationDB_resolveDevices(deviceList,devHierarchies, devDatapoints, exceptionInfo, true, deviceSystems);
    if (dynlen(exceptionInfo)) return;



    if (fwConfigurationDB_progress(fwConfigurationDB_OPER_GetRecipeFromSystem,"Extracting recipe from system",
        10.0, exceptionInfo)) return;


    dyn_dyn_mixed lRecipeObject;
     _fwConfigurationDB_ClearRecipeObject(lRecipeObject);

    // initialize the meta-info
    _fwConfigurationDB_setRecipeOriginalRecipeType(lRecipeObject, GfwConfigurationDB_currentRecipeType, exceptionInfo);
    if (dynlen(exceptionInfo)) return;

    for (i=1;i<=dynlen(deviceList);i++) {
        if (i%20==1) {
            if (fwConfigurationDB_progress(fwConfigurationDB_OPER_GetRecipeFromSystem,"Extracting data from PVSS:",
                10.0+90.0*i/dynlen(deviceList), exceptionInfo)) return;
        }

        string itemName=deviceList[i];
        string dataPoint=devDatapoints[i];
        string dpType=dpTypeName(dataPoint);
	string hierarchyType=devHierarchies[i];

/*
        if (hierarchyType==fwDevice_HARDWARE) {
	    dataPoint=itemName;
            if (!dpExists(dataPoint)) {
                fwException_raise(exceptionInfo,"ERROR",
                                  "Recipe data cannot be extracted:\n"+
                                          "data point "+dataPoint+" does not exist.",
                                  fwConfigurationDB_ERROR_InvalidDataPointName);
                return;
            }
	    // make sure that in HARDWARE hierarchy we have system name here...
	    dataPoint=dpSubStr(dataPoint,DPSUB_SYS_DP);
	    itemName=dataPoint;
        } else if (hierarchyType==fwDevice_LOGICAL) {
            dataPoint=dpAliasToName(itemName);
            dataPoint=strrtrim(dataPoint,".");
            if (dataPoint=="") {
                fwException_raise(exceptionInfo,"ERROR", "GetRecipeFromSystem: cannot find logical device"+itemName,"");
                return;
            }
        } else {
            fwException_raise(exceptionInfo,"ERROR", "GetRecipeFromSystem: unsupported hierarchy:"+hierarchyType,"");
            return;
        }
*/

	// special processing for Nodes in the logical view - no values, no alerts
        if (hierarchyType==fwDevice_LOGICAL && (dpType=="FwNode")) {
	    // append "empty" node - we need it to be able to store tagging info for hierarchies!
            idx=dynContains(lRecipeObject[fwConfigurationDB_RO_DPE_NAME],itemName);
            if (idx<1) idx=dynlen(lRecipeObject[fwConfigurationDB_RO_DPE_NAME])+1;
            lRecipeObject[fwConfigurationDB_RO_DPE_NAME][idx]=itemName+".";
            lRecipeObject[fwConfigurationDB_RO_HIERARCHY][idx]=hierarchyType;
    	    lRecipeObject[fwConfigurationDB_RO_DP_NAME][idx]=itemName;
            lRecipeObject[fwConfigurationDB_RO_DP_TYPE][idx]=dpType;
            lRecipeObject[fwConfigurationDB_RO_ELEMENT_NAME][idx]=".";
            lRecipeObject[fwConfigurationDB_RO_ELEMENT_TYPE][idx]=0;
            lRecipeObject[fwConfigurationDB_RO_HAS_VALUE][idx]=FALSE;
            lRecipeObject[fwConfigurationDB_RO_HAS_ALERT][idx]=FALSE;
            anytype dummy;
            for (int k=fwConfigurationDB_RO_VALUE;k<=fwConfigurationDB_RO_MAXIDX;k++) lRecipeObject[k][idx]=dummy;
	    continue;
	}


	// find out what to extract for this device:
        dyn_string valueDPEs = fwConfigurationDB_getRTValues   (dpType, exceptionInfo);
        dyn_string alertDPEs = fwConfigurationDB_getRTAlerts   (dpType, exceptionInfo);
        if (dynlen(exceptionInfo)) {
            bool ok = _fwConfigurationDB_HandleMissingRT(dataPoint,dpType,exceptionInfo);
            if (ok) { /* retry: */ i--; continue;
            } else {
                return; // abort with error message
            };
        }


	// if device has neither value nor alert, store it with empty "." element
	// we need this to have tags (recipe names) work correctly.
	if ( (dynlen(valueDPEs)==0) && (dynlen(alertDPEs)==0) ) {
            idx=dynContains(lRecipeObject[fwConfigurationDB_RO_DPE_NAME],itemName);
            if (idx<1) idx=dynlen(lRecipeObject[fwConfigurationDB_RO_DPE_NAME])+1;
            lRecipeObject[fwConfigurationDB_RO_DPE_NAME][idx]=itemName;
            lRecipeObject[fwConfigurationDB_RO_HIERARCHY][idx]=hierarchyType;
    	    lRecipeObject[fwConfigurationDB_RO_DP_NAME][idx]=itemName;
            lRecipeObject[fwConfigurationDB_RO_DP_TYPE][idx]=dpType;
            lRecipeObject[fwConfigurationDB_RO_ELEMENT_NAME][idx]=".";
            lRecipeObject[fwConfigurationDB_RO_ELEMENT_TYPE][idx]=0;
            lRecipeObject[fwConfigurationDB_RO_HAS_VALUE][idx]=FALSE;
            lRecipeObject[fwConfigurationDB_RO_HAS_ALERT][idx]=FALSE;
            for (int k=fwConfigurationDB_RO_VALUE;k<=fwConfigurationDB_RO_MAXIDX;k++) lRecipeObject[k][idx]="";
	    continue;
	}

	// PROCESS THE VALUES:
	// we group dpGet's for all configs to gain performance:
	dyn_string  dpesToGet;
	dyn_anytype dpesValues;
        for (int j=1;j<=dynlen(valueDPEs);j++) {
    	    anytype empty;
            dpesToGet[j]=dataPoint+valueDPEs[j]+":_online.._value";
            dpesValues[j]=empty;
	}
	if (dynlen(dpesToGet)) {
	    int rc=dpGet(dpesToGet,dpesValues);
	    if (rc) {
		fwException_raise(exceptionInfo,"ERROR while extracting recipe","dpGet() failed, rc="+rc,"");
		DebugN("---- FAILED dpGet for",dpesToGet);
		return;
	    }
	}
        for (int j=1;j<=dynlen(valueDPEs);j++) {

            idx=dynContains(lRecipeObject[fwConfigurationDB_RO_DPE_NAME],itemName+valueDPEs[j]);
            if (idx<1) idx=dynlen(lRecipeObject[fwConfigurationDB_RO_DPE_NAME])+1;
            lRecipeObject[fwConfigurationDB_RO_DPE_NAME][idx]=dataPoint+valueDPEs[j];
            lRecipeObject[fwConfigurationDB_RO_HIERARCHY][idx]=hierarchyType;
    	    lRecipeObject[fwConfigurationDB_RO_DP_NAME][idx]=itemName;
            lRecipeObject[fwConfigurationDB_RO_DP_TYPE][idx]=dpType;
            lRecipeObject[fwConfigurationDB_RO_ELEMENT_NAME][idx]=valueDPEs[j];
            lRecipeObject[fwConfigurationDB_RO_ELEMENT_TYPE][idx]=dpElementType(dataPoint+valueDPEs[j]);
            lRecipeObject[fwConfigurationDB_RO_HAS_VALUE][idx]=TRUE;
            lRecipeObject[fwConfigurationDB_RO_HAS_ALERT][idx]=FALSE;

	    // encode the value... directly to lRecipeObject
            anytype value=dpesValues[j];
            _fwConfigurationDB_dataToString(value, lRecipeObject[fwConfigurationDB_RO_ELEMENT_TYPE][idx], "|",
                                            lRecipeObject[fwConfigurationDB_RO_VALUE][idx], exceptionInfo);
            if (dynlen(exceptionInfo)) return;

            // for the datapoint elements that also have alerts:
            if (dynContains(alertDPEs,valueDPEs[j])) {
                lRecipeObject[fwConfigurationDB_RO_HAS_ALERT][idx]=TRUE;
                _fwConfigurationDB_getAlertData(lRecipeObject,idx, exceptionInfo);
                if (dynlen(exceptionInfo)) return;
            } else {
        	// pad alerts part with empty data
                for (int k=fwConfigurationDB_RO_ALERT_MINIDX;k<=fwConfigurationDB_RO_ALERT_MAXIDX;k++) lRecipeObject[k][idx]="";
            }

            // pad to the end of the object
            for (int k=fwConfigurationDB_RO_ALERT_MAXIDX+1;k<=fwConfigurationDB_RO_MAXIDX;k++) lRecipeObject[k][idx]="";

        };


        // PROCESS DPE's WITH ALERTS
        for (int j=1;j<=dynlen(alertDPEs);j++) {

	    // exclude the ones that have values - they were processed above!
            if (dynContains(valueDPEs,alertDPEs[j])) continue;

            idx=dynContains(lRecipeObject[fwConfigurationDB_RO_DPE_NAME],dataPoint+alertDPEs[j]);
            if (idx<1) idx=dynlen(lRecipeObject[fwConfigurationDB_RO_DPE_NAME])+1;
            lRecipeObject[fwConfigurationDB_RO_DPE_NAME][idx]=dataPoint+alertDPEs[j];
            lRecipeObject[fwConfigurationDB_RO_HIERARCHY][idx]=hierarchyType;
            lRecipeObject[fwConfigurationDB_RO_DP_NAME][idx]=itemName;
            lRecipeObject[fwConfigurationDB_RO_DP_TYPE][idx]=dpType;
            lRecipeObject[fwConfigurationDB_RO_ELEMENT_NAME][idx]=alertDPEs[j];
            lRecipeObject[fwConfigurationDB_RO_ELEMENT_TYPE][idx]=dpElementType(dataPoint+alertDPEs[j]);
            lRecipeObject[fwConfigurationDB_RO_HAS_VALUE][idx]=FALSE;
            lRecipeObject[fwConfigurationDB_RO_VALUE][idx]="";
            lRecipeObject[fwConfigurationDB_RO_HAS_ALERT][idx]=TRUE;
            _fwConfigurationDB_getAlertData(lRecipeObject,idx, exceptionInfo);
            if (dynlen(exceptionInfo)) return;

	    // pad to the end of the object
	    for (int k=fwConfigurationDB_RO_ALERT_MAXIDX+1;k<=fwConfigurationDB_RO_MAXIDX;k++) lRecipeObject[k][idx]="";


	    // we skip empty entries...
	    // this is the case where recipe type tells us to extract the alert,
	    // but the alert is not configured for this device.
	    // However, we need special treatment
	    // 1) if it is a "Node" (indicated by element_type==0) we need to keep it
	    // 2) for "skipped" devices. we will need to keep a "node-like" entry
	    // The reasons for these is for storing proper tagging information...
	    // We will add them below - here we only remove empty entries
    	    if ( (lRecipeObject[fwConfigurationDB_RO_HAS_VALUE][idx]==FALSE) &&
	         (lRecipeObject[fwConfigurationDB_RO_HAS_ALERT][idx]==FALSE) ) {

	         if (lRecipeObject[fwConfigurationDB_RO_ELEMENT_TYPE][idx]!=0)  {

		    // just remove it... see the completing part below...
		    for (int k=1;k<=fwConfigurationDB_RO_MAXIDX;k++) dynRemove(lRecipeObject[k],idx);
		}
	    }


        };

    };



    // now, add also empty entries for devices that were not included...
    dyn_string existingDevs=lRecipeObject[fwConfigurationDB_RO_DP_NAME];
    dynUnique(existingDevs);
    for (i=1;i<=dynlen(deviceList);i++) {
	if (!dynContains(existingDevs,deviceList[i])) {
    	    string itemName=deviceList[i];

    	    string dataPoint=devDatapoints[i];
    	    string dpType=dpTypeName(dataPoint);
	    string hierarchyType=devHierarchies[i];

	    // append "empty" node - we need it to be able to store tagging info for hierarchies!
            int idx=dynlen(lRecipeObject[fwConfigurationDB_RO_DPE_NAME])+1;
            lRecipeObject[fwConfigurationDB_RO_DPE_NAME][idx]=dataPoint+".";
            lRecipeObject[fwConfigurationDB_RO_HIERARCHY][idx]=hierarchyType;
    	    lRecipeObject[fwConfigurationDB_RO_DP_NAME][idx]=itemName;
            lRecipeObject[fwConfigurationDB_RO_DP_TYPE][idx]=dpType;
            lRecipeObject[fwConfigurationDB_RO_ELEMENT_NAME][idx]=".";
            lRecipeObject[fwConfigurationDB_RO_ELEMENT_TYPE][idx]=0;
            lRecipeObject[fwConfigurationDB_RO_HAS_VALUE][idx]=FALSE;
            lRecipeObject[fwConfigurationDB_RO_HAS_ALERT][idx]=FALSE;
            for (int k=fwConfigurationDB_RO_VALUE;k<=fwConfigurationDB_RO_ALERT_MAXIDX;k++) lRecipeObject[k][idx]="";
	    for (int k=fwConfigurationDB_RO_ALERT_MAXIDX+1;k<=fwConfigurationDB_RO_MAXIDX;k++) lRecipeObject[k][idx]="";

	    continue;
	}
    }

    fwConfigurationDB_combineRecipes(  recipeObject,
                                       recipeObject,
                                       lRecipeObject,
                                    exceptionInfo);
    if (dynlen(exceptionInfo)) return;

    if (fwConfigurationDB_progress(fwConfigurationDB_OPER_GetRecipeFromSystem,"Extracted recipe from system",
        100.0, exceptionInfo)) return;
    //sleep(1,0)

    _fwConfigurationDB_endFunction("GetRecipeFromSystem", t0);
}

/** Applies a recipe stored in recipeObject to the system
 *
 * @param recipeObject     the structure containing recipe data.
 *                          See also @ref recipeObject data structure description.
 * @param hierarchyType	    hierarchy type (fwDevice_HARDWARE, fwDevice_LOGICAL, etc)
 * @param exceptionInfo 	standard exception handling variable
 * @param allowApplyRemote  (optional, default=FALSE) allows to perform dpSet's to remote locations;
 *				by default this is disabled (i.e. only local operations allowed) for
 *				security
 *
 * @see @ref qstart_recipes section of Quick Start
 * @ingroup RecipeFunctions
 * @deprecated use @ref fwConfigurationDB_applyRecipe instead
*/
void fwConfigurationDB_ApplyRecipe(dyn_dyn_mixed recipeObject, string hierarchyType, dyn_string &exceptionInfo,
				    bool allowApplyRemote=FALSE)
{
    time t0;
    _fwConfigurationDB_startFunction("ApplyRecipe", t0);

    int nProps=dynlen(recipeObject[fwConfigurationDB_RO_DPE_NAME]);

    if (fwConfigurationDB_progress(fwConfigurationDB_OPER_ApplyRecipeToSystem,"Applying recipe",
        10.0, exceptionInfo)) return;


    // step 1: parse...

    dyn_int     alertIdx, valueIdx;
    dyn_string  alertNotActiveDPEs, alertActiveDPEs;

    string localSystemName=getSystemName();

    for (int i=1;i<=nProps;i++) {
        string dptype=recipeObject[fwConfigurationDB_RO_DP_TYPE][i];
        if ( (dptype== "SYSTEM") || (dptype=="") ) continue;
	if (recipeObject[fwConfigurationDB_RO_ELEMENT_TYPE][i]==0) continue; // exclude "nodes" or things that have no properties...

	string dpename=recipeObject[fwConfigurationDB_RO_DPE_NAME][i];
	if (dpename=="") continue; // exclude cases of non-mapped logical nodes

	if (!allowApplyRemote) {
	    if (_fwConfigurationDB_NodeSystemName(dpename)!=localSystemName) {
		fwException_raise(exceptionInfo,"ERROR","Cannot apply recipe for non local node \n"+dpename,"");
		return;
	    }
	}

        if (recipeObject[fwConfigurationDB_RO_HAS_ALERT][i] == "TRUE") {
            dynAppend(alertIdx,i);
            dynAppend(alertNotActiveDPEs,recipeObject[fwConfigurationDB_RO_DPE_NAME][i]);
            int type=recipeObject[fwConfigurationDB_RO_ALERT_TYPE][i];

            if (recipeObject[fwConfigurationDB_RO_ALERT_ACTIVE][i]=="TRUE") {
                dynAppend(alertActiveDPEs,recipeObject[fwConfigurationDB_RO_DPE_NAME][i]);
            }
        }
        if (recipeObject[fwConfigurationDB_RO_HAS_VALUE][i] == "TRUE") {
            dynAppend(valueIdx,i);
        }
    };
    if (fwConfigurationDB_progress(fwConfigurationDB_OPER_ApplyRecipeToSystem,"Disabling old alerts",
        10.0, exceptionInfo)) return;

    if (g_fwConfigurationDB_Debug & 4) DebugN("disabling alerts...");
    if (g_fwConfigurationDB_Debug & 8) DebugN("dpDeactivateAlert on :",alertNotActiveDPEs);

    // bugfix #14796
    // disable the alerts
    //dpSetWait(alertNotActiveDPEs,alertNotActive);
    for (int i=1;i<=dynlen(alertNotActiveDPEs);i++) {
	bool ok;
	int alert_type;
	dpGet(alertNotActiveDPEs[i]+":_alert_hdl.._type",alert_type);
	if (alert_type!=DPCONFIG_NONE) {
    	    dpDeactivateAlert(alertNotActiveDPEs[i],ok,TRUE);
	    if (!ok) {
		fwException_raise(exceptionInfo,"ERROR","Could not deactivate alert on "+alertNotActiveDPEs[i],"");
		return;
	    }
	}
    }

    dyn_string dpes;
    dyn_mixed values; // bugfix #14075 - we need "mixed" here...

    if (fwConfigurationDB_progress(fwConfigurationDB_OPER_ApplyRecipeToSystem,"Preparing new alerts",
        40.0, exceptionInfo)) return;


    ///////////////////////////////////////////////////////////////
    // set the actual alerts...

    if (g_fwConfigurationDB_Debug & 4) DebugN("setting alerts...");
    for (int i=1;i<=dynlen(alertIdx);i++) {

        string dpe=recipeObject[fwConfigurationDB_RO_DPE_NAME][alertIdx[i]];
        dyn_string classes,texts;
        dyn_float limits;
        int type;

        bool configExists;
        int alertConfigType;
        dyn_string alertTexts;
        dyn_float alertLimits;
        dyn_string alertClasses;
        dyn_string summaryDpeList;
        string alertPanel;
        dyn_string alertPanelParameters;
        string alertHelp;
        bool isActive;
        fwAlertConfig_get(      dpe,
                                configExists,
                                alertConfigType,
                                alertTexts,
                                alertLimits,
                                alertClasses,
                                summaryDpeList,
                                alertPanel,
                                alertPanelParameters,
                                alertHelp,
                                isActive,
                                exceptionInfo);
        if (dynlen(exceptionInfo)) return;


        classes = recipeObject[fwConfigurationDB_RO_ALERT_CLASSES][alertIdx[i]];
        texts = recipeObject[fwConfigurationDB_RO_ALERT_TEXTS][alertIdx[i]];
        limits = recipeObject[fwConfigurationDB_RO_ALERT_LIMITS][alertIdx[i]];
        type = recipeObject[fwConfigurationDB_RO_ALERT_TYPE][alertIdx[i]];


        alertConfigType=type;

        alertClasses=classes;
        alertTexts=texts;
        alertLimits=limits;

//        dpe=dpSubStr(dpe,DPSUB_DP_EL);//fix #36657: allow "remote" apply
        fwAlertConfig_set(dpe,
                          alertConfigType,
                          alertTexts,
                          alertLimits,
                          alertClasses,
                          summaryDpeList,
                          alertPanel,
                          alertPanelParameters,
                          alertHelp,
                          exceptionInfo,
                          TRUE, // modifyOnly
                          TRUE, // fallBackToSet
                          "",// addDpeInSummary
                          FALSE // storeInParamHistory - FIX #21981
                          );

        if (dynlen(exceptionInfo)) return;



    }
    //////////////////////////////////////////////////////////////
    //set values

    if (g_fwConfigurationDB_Debug & 4) DebugN("setting values...");

    dynClear(dpes);
    dynClear(values);

    if (fwConfigurationDB_progress(fwConfigurationDB_OPER_ApplyRecipeToSystem,"Setting values",
        70.0, exceptionInfo)) return;


    // prepare the values...
    for (int i=1;i<=dynlen(valueIdx);i++) {

	mixed value;
	_fwConfigurationDB_stringToData   (	recipeObject[fwConfigurationDB_RO_VALUE][valueIdx[i]],
			recipeObject[fwConfigurationDB_RO_ELEMENT_TYPE][valueIdx[i]],
			"|",value, exceptionInfo);
	if (dynlen(exceptionInfo)) return;
        dynAppend(dpes,  recipeObject[fwConfigurationDB_RO_DPE_NAME][valueIdx[i]]);
        //dynAppend(values,recipeObject[fwConfigurationDB_RO_VALUE][valueIdx[i]]);
	values[dynlen(values)+1]=value; // bugfix #14075
        //dynAppend(values,value);
    }

    // fix #39373
    if (allowApplyRemote) {
	fwConfigurationDB_dpSetManyDist(dpes, values, exceptionInfo, true);
    } else {
	fwConfigurationDB_dpSetMany(dpes,values, exceptionInfo);
    }
    if (dynlen(exceptionInfo)) return;

    if (fwConfigurationDB_progress(fwConfigurationDB_OPER_ApplyRecipeToSystem,"Reactivating alerts",
        90.0, exceptionInfo)) return;

    // re-enable the alerts
    if (g_fwConfigurationDB_Debug & 4) DebugN("enabling alerts...");
    if (g_fwConfigurationDB_Debug & 8) DebugN("dpSetWait:",alertActiveDPEs);

    // bugfix #14796
    //dpSetWait(alertActiveDPEs,alertActive);
    for (int i=1;i<=dynlen(alertActiveDPEs);i++) {
	bool ok;
	dpActivateAlert(alertActiveDPEs[i],ok,TRUE);
	if (!ok) {
	    fwException_raise(exceptionInfo,"ERROR","Could not Activate alert on "+alertActiveDPEs[i],"");
	    return;
	}
    }


    _fwConfigurationDB_activateRecipeUpdateMetaInfo(recipeObject,exceptionInfo);
    if (dynlen(exceptionInfo)) return;

    if (fwConfigurationDB_progress(fwConfigurationDB_OPER_ApplyRecipeToSystem,"Recipe applied",
        100.0, exceptionInfo)) return;

    _fwConfigurationDB_endFunction("ApplyRecipe", t0);
}

/** Creates an empty recipe cache
 * @param recipeName    the name of the recipe cache
 * @param exceptionInfo standard exception handling variable
 * @param recipeComment (optional) comment for recipe type
 * @param hierarchyType (optional) hierarchy type, dummy now!
 * @see @ref qstart_recipes section of Quick Start
 * @ingroup RecipeFunctions
 */
string fwConfigurationDB_createRecipeCache(string recipeName, dyn_string &exceptionInfo,
                                           string recipeComment="",string hierarchyType="")
{
    if (recipeName=="") {
        fwException_raise(exceptionInfo,"ERROR","Cannot create recipe cache with empty name",
                          fwConfigurationDB_ERROR_InvalidDataPointName);
        return "";
    };

    // handle recipe cache names with system names
    string system="";
    string recipe=recipeName;
    int sysid=getSystemId();
    dyn_string ds=strsplit(recipeName,":");
    if (dynlen(ds)>1) {
	system=ds[1]+":";
	recipe=ds[2];
    }

    // verify that the remote system is available...
    if (system!="") {
	sysid=getSystemId(system);
	if (sysid==-1) {
            fwException_raise(exceptionInfo,"ERROR in fwConfigurationDB_createRecipeCache",
        	"Cannot create recipe cache "+recipeName+" - no such system "+system ,
        	fwConfigurationDB_ERROR_NoRecipeCache);
            return "";
	}
    }

    string dpName=fwConfigurationDB_RecipeCacheDpPrefix+recipe;

    if (dpExists(system+dpName)){
        fwException_raise(exceptionInfo, "ERROR in fwConfigurationDB_createRecipeCache",
    	    "Recipe cache "+recipeName+" already exists",
    	    fwConfigurationDB_ERROR_RecipeCacheExists);
        return "";
    }

    if (!dpIsLegalName(recipe)) {
        fwException_raise(exceptionInfo,"ERROR in fwConfigurationDB_createRecipeCache",
        "The name for the recipe cache is invalid:"+recipe,fwConfigurationDB_ERROR_InvalidDataPointName);
        return "";
    };

    int rc=dpCreate(dpName,"_FwRecipeCache",sysid);
    if (rc) {
        fwException_raise(exceptionInfo,"ERROR in fwConfigurationDB_createRecipeCache",
        "Cannot create recipe cache, code="+rc,fwConfigurationDB_ERROR_CreateRecipeCache);
        return "";
    };

    dpName=system+dpName;
    dpSetWait(dpName+".RecipeName",recipe,
          dpName+".RecipeComment",recipeComment,
          dpName+".Version",(string)fwConfigurationDB_version);

    return dpName;

}


/** Saves the recipe in a recipe cache
 * @param recipeObject  should contain the recipe data; you may store recipe remotely if you prefix the cacheName with system name.
 * @param cacheName     the name of the cache. Note that if the cache does not
 *                      exits, it will be created.
 * @param hierarchyType hierarchy type, dummy now...
 * @param exceptionInfo standard exception handling variable
 * @see @ref qstart_recipes section of Quick Start
 * @ingroup RecipeFunctions
 * @deprecated use @ref fwConfigurationDB_saveRecipeToCache instead
 */
void fwConfigurationDB_storeRecipeInCache(dyn_dyn_mixed recipeObject, string cacheName, string hierarchyType, dyn_string &exceptionInfo)
{
    time t0;
    _fwConfigurationDB_startFunction("storeRecipeInCache", t0);

    if (fwConfigurationDB_progress(fwConfigurationDB_OPER_SaveRecipeToCache,"Storing recipe in cache",
        10.0, exceptionInfo)) return;

    string dpName=_fwConfigurationDB_getRecipeCacheDP(cacheName, exceptionInfo, TRUE);
    if (dynlen(exceptionInfo)) return;

// we probably do not need this: it is done by getRecipeCacheDP already...
/*
    string recipeSystem="";
    if (strpos(cacheName,":")>=0) {
	dyn_string ds=strsplit(cacheName,":");
	recipeSystem=ds[1]+":";
	cacheName=ds[2];
    }
*/
    if (dynlen(recipeObject)==0) _fwConfigurationDB_ClearRecipeObject(recipeObject);

    dyn_string values_dpenames;
    dyn_string values_dpevalues;
    dyn_string alerts_dpenames;
    dyn_string alerts_alertactive;
    dyn_string alerts_alerttype;
    dyn_string alerts_alerttexts;
    dyn_string  alerts_alertlimits;
    dyn_string alerts_alertclasses;
    dyn_int    values_dpetypes;
    dyn_int    alerts_dpetypes;
    dyn_string datapoints_names;
    dyn_string datapoints_types;
    dyn_string datapoints_hierarchies;

    string hierarchy,recipeComment, recipeType, className, author, recipeVersion, lastActivationUser, lastModificationUser;
    time creationTime, lastActivationTime, lastModificationTime;
    bool predefined;

    lastModificationTime=getCurrentTime();
    lastModificationUser=getUserName();

    for (int i=1;i<=dynlen(recipeObject[fwConfigurationDB_RO_DPE_NAME]);i++) {
	string hierarchy =recipeObject[fwConfigurationDB_RO_HIERARCHY][i];
        if (recipeObject[fwConfigurationDB_RO_HAS_VALUE][i]) {
            if (hierarchy==fwDevice_HARDWARE) {
                dynAppend(values_dpenames,recipeObject[fwConfigurationDB_RO_DPE_NAME][i]);
            } else {
                dynAppend(values_dpenames,recipeObject[fwConfigurationDB_RO_DP_NAME][i]+recipeObject[fwConfigurationDB_RO_ELEMENT_NAME][i]);
            }

            dynAppend(values_dpetypes,recipeObject[fwConfigurationDB_RO_ELEMENT_TYPE][i]);
            dynAppend(values_dpevalues,recipeObject[fwConfigurationDB_RO_VALUE][i]);

        };

        if (recipeObject[fwConfigurationDB_RO_HAS_ALERT][i]) {


            if (hierarchy==fwDevice_HARDWARE) {
                dynAppend(alerts_dpenames,recipeObject[fwConfigurationDB_RO_DPE_NAME][i]);
            } else {
                dynAppend(alerts_dpenames,recipeObject[fwConfigurationDB_RO_DP_NAME][i]+recipeObject[fwConfigurationDB_RO_ELEMENT_NAME][i]);
            }

            dynAppend(alerts_dpetypes,recipeObject[fwConfigurationDB_RO_ELEMENT_TYPE][i]);
            dynAppend(alerts_alerttype,recipeObject[fwConfigurationDB_RO_ALERT_TYPE][i]);
            dynAppend(alerts_alertactive,recipeObject[fwConfigurationDB_RO_ALERT_ACTIVE][i]);
            string texts, classes, limits;

            _fwConfigurationDB_dataToString(recipeObject[fwConfigurationDB_RO_ALERT_TEXTS][i],
                                            DPEL_DYN_STRING,
                                            "|",texts,exceptionInfo);
            _fwConfigurationDB_dataToString(recipeObject[fwConfigurationDB_RO_ALERT_CLASSES][i],
                                            DPEL_DYN_STRING,
                                            "|",classes,exceptionInfo);
            _fwConfigurationDB_dataToString(recipeObject[fwConfigurationDB_RO_ALERT_LIMITS][i],
                                            DPEL_DYN_FLOAT,
                                            "|",limits,exceptionInfo);
            if (dynlen(exceptionInfo)) return;



            dynAppend(alerts_alerttexts, texts);
            dynAppend(alerts_alertclasses,classes);
            dynAppend(alerts_alertlimits,limits);

        }

        // This is to store the ones that have no alerts and no values
        if (!dynContains(datapoints_names,recipeObject[fwConfigurationDB_RO_DP_NAME][i])) {
            dynAppend(datapoints_names,recipeObject[fwConfigurationDB_RO_DP_NAME][i]);
            dynAppend(datapoints_hierarchies,recipeObject[fwConfigurationDB_RO_HIERARCHY][i]);
            dynAppend(datapoints_types,recipeObject[fwConfigurationDB_RO_DP_TYPE][i]);
        }
    };

    if (dynlen(recipeObject[fwConfigurationDB_RO_META_COMMENT])) recipeComment=recipeObject[fwConfigurationDB_RO_META_COMMENT][1];
    if (dynlen(recipeObject[fwConfigurationDB_RO_META_RECIPETYPE])) recipeType=recipeObject[fwConfigurationDB_RO_META_RECIPETYPE][1];
    if (dynlen(recipeObject[fwConfigurationDB_RO_META_CLASSNAME])) className=recipeObject[fwConfigurationDB_RO_META_CLASSNAME][1];
    if (dynlen(recipeObject[fwConfigurationDB_RO_META_AUTHOR])) author=recipeObject[fwConfigurationDB_RO_META_AUTHOR][1];
    if (dynlen(recipeObject[fwConfigurationDB_RO_META_CREATIONTIME]))creationTime=recipeObject[fwConfigurationDB_RO_META_CREATIONTIME][1];
    if (dynlen(recipeObject[fwConfigurationDB_RO_META_LASTACTIVATIONTIME]))lastActivationTime=recipeObject[fwConfigurationDB_RO_META_LASTACTIVATIONTIME][1];
    if (dynlen(recipeObject[fwConfigurationDB_RO_META_LASTMODIFICATIONTIME]))lastModificationTime=recipeObject[fwConfigurationDB_RO_META_LASTMODIFICATIONTIME][1];
    if (dynlen(recipeObject[fwConfigurationDB_RO_META_LASTACTIVATIONUSER]))lastActivationUser=recipeObject[fwConfigurationDB_RO_META_LASTACTIVATIONUSER][1];
    if (dynlen(recipeObject[fwConfigurationDB_RO_META_LASTMODIFICATIONUSER]))lastModificationUser=recipeObject[fwConfigurationDB_RO_META_LASTMODIFICATIONUSER][1];
    if (dynlen(recipeObject[fwConfigurationDB_RO_META_PREDEFINED]))predefined=recipeObject[fwConfigurationDB_RO_META_PREDEFINED][1];
    if (dynlen(recipeObject[fwConfigurationDB_RO_META_RECIPEVERSION]))recipeVersion=recipeObject[fwConfigurationDB_RO_META_RECIPEVERSION][1];

    if (dynlen(exceptionInfo)) return;

    int rc = dpSetWait(
    dpName+".RecipeName",cacheName,
    dpName+".RecipeComment",recipeComment,
    dpName+".RecipeType",recipeType,
    dpName+".DataPoints.DPNames",datapoints_names,
    dpName+".DataPoints.DPTypes",datapoints_types,
    dpName+".DataPoints.Hierarchy",datapoints_hierarchies,
    dpName+".Values.DPENames",values_dpenames,
    dpName+".Values.DPETypes",values_dpetypes,
    dpName+".Values.DPEValues",values_dpevalues,
    dpName+".Alerts.DPENames",alerts_dpenames,
    dpName+".Alerts.DPETypes",alerts_dpetypes,
    dpName+".Alerts.AlertActive",alerts_alertactive,
    dpName+".Alerts.AlertType",alerts_alerttype,
    dpName+".Alerts.AlertTexts",alerts_alerttexts,
    dpName+".Alerts.AlertClasses",alerts_alertclasses,
    dpName+".Alerts.AlertLimits",alerts_alertlimits,
		dpName+".MetaInfo.ClassName",className,
		dpName+".MetaInfo.Author",author ,
                dpName+".MetaInfo.CreationTime",creationTime,
		dpName+".MetaInfo.LastActivationTime",lastActivationTime,
                dpName+".MetaInfo.LastModificationTime",lastModificationTime,
		dpName+".MetaInfo.LastActivationUser",lastActivationUser,
                dpName+".MetaInfo.LastModificationUser",lastModificationUser,
                dpName+".MetaInfo.Predefined",predefined,
                dpName+".MetaInfo.RecipeVersion",recipeVersion  );

    if (rc) {
        fwException_raise(exceptionInfo, "ERROR", "Could not store recipe data in recipe cache "+cacheName,
                          fwConfigurationDB_ERROR_StoreRecipeDataToCache);
    };

    if (fwConfigurationDB_progress(fwConfigurationDB_OPER_SaveRecipeToCache,"Recipe stored in cache",
        100.0, exceptionInfo)) return;

    _fwConfigurationDB_endFunction("storeRecipeInCache", t0);

}

/** Loads a recipe from recipe cache
 * @param cacheName     the name of the cache
 * @param deviceList    the list of devices for which the recipe should be loaded.
 *			specifying empty list means that all devices in the
 *			recipe should be loaded
 * @param hierarchyType hierarchy type, dummy now
 * @param recipeObject  on return will contain the recipe data
 * @param exceptionInfo standard exception handling variable
 * @param system	dummy - deprecated
 * @ingroup RecipeFunctions
 * @see @ref qstart_recipes section of Quick Start
 * @deprecated use @ref fwConfigurationDB_loadRecipeFromCache instead
 */
void fwConfigurationDB_getRecipeFromCache(string cacheName, dyn_string deviceList, string hierarchyType, dyn_dyn_mixed &recipeObject, dyn_string &exceptionInfo, string systemName="")
{

    time t0;
    _fwConfigurationDB_startFunction("getRecipeFromCache", t0);

    if (dynlen(recipeObject)==0) _fwConfigurationDB_ClearRecipeObject(recipeObject);

    if (fwConfigurationDB_progress(fwConfigurationDB_OPER_LoadRecipeFromCache,"Load recipe from cache", 10.0,
        exceptionInfo)) return;

    string dpName=_fwConfigurationDB_getRecipeCacheDP(cacheName, exceptionInfo, FALSE);
    if (dynlen(exceptionInfo)) return;

    // check if the recipe is remote...
    string recipeSystem="";
////////////
    if (strpos(cacheName,":")>=0) {
	dyn_string ds=strsplit(cacheName,":");
	recipeSystem=ds[1]+":";
	int sysid=getSystemId(recipeSystem);
	// make sure the system is present
	if (sysid<0) {
	    fwException_raise(exceptionInfo,"ERROR in getRecipeFromCache",
	    "Remote system "+recipeSystem+" does not exist","");
	    return ;
	}
    }


/////////
    dyn_dyn_mixed cacheRecipeObject;
    _fwConfigurationDB_ClearRecipeObject(cacheRecipeObject);

    // fix #14725: the case of user passing "" instead of makeDynString()
    // as deviceList parameter!
    if ( (dynlen(deviceList)==1) && (deviceList[1]=="" ) ) dynClear(deviceList);

    dyn_string values_dpenames;
    dyn_string values_dpevalues;
    dyn_int    values_dpetypes;
    dyn_string alerts_dpenames;
    dyn_bool   alerts_alertactive;
    dyn_int alerts_alerttype;
    dyn_string alerts_alerttexts;
    dyn_string alerts_alertlimits;
    dyn_string alerts_alertclasses;
    dyn_int    alerts_dpetypes;

    dyn_string datapoints_names;
    dyn_string datapoints_types;
    dyn_string datapoints_hierarchies;

    string hierarchy,comment, recipeType, className, author, recipeVersion, lastActivationUser, lastModificationUser;
    time creationTime, lastActivationTime, lastModificationTime;
    bool predefined;

    int rc = dpGet( dpName+".RecipeComment",comment,
		    dpName+".RecipeType",recipeType,
                    dpName+".DataPoints.DPNames",datapoints_names,
                    dpName+".DataPoints.DPTypes",datapoints_types,
                    dpName+".DataPoints.Hierarchy",datapoints_hierarchies,
                    dpName+".Values.DPENames",values_dpenames,
                    dpName+".Values.DPETypes",values_dpetypes,
                    dpName+".Values.DPEValues",values_dpevalues,
                    dpName+".Alerts.DPENames",alerts_dpenames,
                    dpName+".Alerts.DPETypes",alerts_dpetypes,
                    dpName+".Alerts.AlertActive",alerts_alertactive,
                    dpName+".Alerts.AlertType",alerts_alerttype,
                    dpName+".Alerts.AlertTexts",alerts_alerttexts,
                    dpName+".Alerts.AlertClasses",alerts_alertclasses,
                    dpName+".Alerts.AlertLimits",alerts_alertlimits,
  		    dpName+".MetaInfo.ClassName",className,
		    dpName+".MetaInfo.Author",author ,
                    dpName+".MetaInfo.CreationTime",creationTime,
		    dpName+".MetaInfo.LastActivationTime",lastActivationTime,
                    dpName+".MetaInfo.LastModificationTime",lastModificationTime,
		    dpName+".MetaInfo.LastActivationUser",lastActivationUser,
                    dpName+".MetaInfo.LastModificationUser",lastModificationUser,
                    dpName+".MetaInfo.Predefined",predefined,
                    dpName+".MetaInfo.RecipeVersion",recipeVersion);

    if (rc) {
        fwException_raise(exceptionInfo, "ERROR", "Could get data from recipe cache "+cacheName,
                          fwConfigurationDB_ERROR_GetRecipeFromCache);
        return;
    };

    if ( dynlen(alerts_dpetypes)!=dynlen(alerts_dpenames) ) {
	DebugN("WARNING! The list of types types and list of names in the recipe cache "+cacheName+ " differ.");
	DebugN("         Consider loading recipe and saving it again to correct the problem");
    }

//    if (hierarchyType!="") {
//        if (hierarchy!=hierarchyType) {
//            fwException_raise(exceptionInfo, "ERROR", "Recipe: "+cacheName+" is not for "+hierarchyType+" hierarchy","");
//            return;
//        };
//    }


    time t2=getCurrentTime();

    if (g_fwConfigurationDB_Debug & 4) DebugN("processing values...");
    int n=0;
    int n_values=0;
    dyn_int values_indices;
    dyn_string values_dpes;
    for (int i=1;i<=dynlen(values_dpenames);i++) {
        dyn_string DpAndElement=strsplit(values_dpenames[i],".");
        string dpname=DpAndElement[1];
        string elementName=substr(values_dpenames[i],strlen(dpname));

        if (dynlen(deviceList)) {
		if (!dynContains(deviceList,dpname)) continue;
	};

	n++;
	n_values++;
	values_indices[n_values]=n;
	values_dpes[n_values]=values_dpenames[i];

        cacheRecipeObject[fwConfigurationDB_RO_DPE_NAME][n]=values_dpenames[i];
        cacheRecipeObject[fwConfigurationDB_RO_HIERARCHY][n]=""; // resolved below
        cacheRecipeObject[fwConfigurationDB_RO_DP_NAME][n]=dpname;
        cacheRecipeObject[fwConfigurationDB_RO_DP_TYPE][n]=""; // will be completed below...
        cacheRecipeObject[fwConfigurationDB_RO_ELEMENT_NAME][n]=elementName;
        cacheRecipeObject[fwConfigurationDB_RO_ELEMENT_TYPE][n]=values_dpetypes[i];
        cacheRecipeObject[fwConfigurationDB_RO_HAS_ALERT ][n]=FALSE;
        cacheRecipeObject[fwConfigurationDB_RO_HAS_VALUE][n]=TRUE;
        cacheRecipeObject[fwConfigurationDB_RO_VALUE][n]=values_dpevalues[i];
        anytype dummy;
        for (int k=fwConfigurationDB_RO_ALERT_MINIDX;k<=fwConfigurationDB_RO_ALERT_MAXIDX;k++) cacheRecipeObject[k][n]=dummy;
        // fix #20400
        for (int k=fwConfigurationDB_RO_ALERT_MAXIDX+1;k<=fwConfigurationDB_RO_MAXIDX;k++) cacheRecipeObject[k][n]=dummy;

    }


    if (g_fwConfigurationDB_Debug & 4) DebugN("processing alerts...");
    int n_alerts=0;
    dyn_int alerts_indices;
    dyn_string alerts_dpes;
    for (int i=1;i<=dynlen(alerts_dpenames);i++) {
        dyn_string DpAndElement=strsplit(alerts_dpenames[i],".");
        string dpname=DpAndElement[1];
        string elementName=substr(alerts_dpenames[i],strlen(dpname));
        if (dynlen(deviceList)) {
	    // fix #14725: the case of user passing "" instead of makeDynString()
	    // as deviceList parameter!
	    if ( (dynlen(deviceList)==1) && (deviceList[1]=="" )) {
		// do not skip any device!
	    } else {
		if (!dynContains(deviceList,dpname)) continue;
	    }
	};

	n++;
	n_alerts++;
	alerts_indices[n_alerts]=n;
	alerts_dpes[n_alerts]=alerts_dpenames[i];

        cacheRecipeObject[fwConfigurationDB_RO_DPE_NAME][n]=alerts_dpenames[i];
        cacheRecipeObject[fwConfigurationDB_RO_DP_NAME][n]=dpname;
        cacheRecipeObject[fwConfigurationDB_RO_DP_TYPE][n]="";
        cacheRecipeObject[fwConfigurationDB_RO_HIERARCHY][n]=""; // resolved below

        cacheRecipeObject[fwConfigurationDB_RO_ELEMENT_NAME][n]=elementName;
	// due to a previous bug in recipeCache, where type was not stored, we need
	// to protect this
	if (dynlen(alerts_dpetypes)>=1) {
	    cacheRecipeObject[fwConfigurationDB_RO_ELEMENT_TYPE][n]=alerts_dpetypes[i];
	} else {
	    // we will fix it below...
	    cacheRecipeObject[fwConfigurationDB_RO_ELEMENT_TYPE][n]=0;
	}
        cacheRecipeObject[fwConfigurationDB_RO_HAS_ALERT ][n]=TRUE;
        cacheRecipeObject[fwConfigurationDB_RO_HAS_VALUE][n]=FALSE;
        mixed dummy;
        cacheRecipeObject[fwConfigurationDB_RO_VALUE][n]=dummy;
        //cacheRecipeObject[fwConfigurationDB_RO_VALUE][n]="";
        cacheRecipeObject[fwConfigurationDB_RO_HAS_ALERT ][n]=TRUE;
        cacheRecipeObject[fwConfigurationDB_RO_ALERT_ACTIVE][n]=alerts_alertactive[i];
        cacheRecipeObject[fwConfigurationDB_RO_ALERT_TYPE][n]=alerts_alerttype[i];

	dyn_string alertClasses;
        _fwConfigurationDB_stringToData(alerts_alerttexts[i], DPEL_DYN_STRING, "|",
                                            cacheRecipeObject[fwConfigurationDB_RO_ALERT_TEXTS][n], exceptionInfo);
        _fwConfigurationDB_stringToData(alerts_alertclasses[i], DPEL_DYN_STRING, "|",
                                            alertClasses, exceptionInfo);
        _fwConfigurationDB_stringToData(alerts_alertlimits[i], DPEL_DYN_FLOAT, "|",
                                            cacheRecipeObject[fwConfigurationDB_RO_ALERT_LIMITS][n], exceptionInfo);

        // alert classes should not contain system name!
        for (int i=1;i<=dynlen(alertClasses);i++) {
    	    if (alertClasses!="") {
    		alertClasses[i]=_fwConfigurationDB_NodeNameWithoutSystem(alertClasses[i]);
    	    }
    	}

	cacheRecipeObject[fwConfigurationDB_RO_ALERT_CLASSES][n]=alertClasses;

        anytype dummy;
        // fix #20400
        for (int k=fwConfigurationDB_RO_ALERT_MAXIDX+1;k<=fwConfigurationDB_RO_MAXIDX;k++) cacheRecipeObject[k][n]=dummy;

        if (dynlen(exceptionInfo)) return;

    }

    if (g_fwConfigurationDB_Debug & 4) DebugN("combining alerts with values...");
    dyn_string commonDpes=dynIntersect(values_dpes,alerts_dpes);
    int value_idx, alert_idx;
    dyn_int remove_alert_idx;
    // find out the indices, copy the alert data ...
    for (int i=1;i<=dynlen(commonDpes);i++) {
	value_idx=values_indices[dynContains(values_dpes,commonDpes[i])];
	alert_idx=alerts_indices[dynContains(alerts_dpes,commonDpes[i])];
	// copy the data...
        cacheRecipeObject[fwConfigurationDB_RO_HAS_ALERT ][value_idx]=TRUE;
	for (int j=fwConfigurationDB_RO_ALERT_MINIDX;j<=fwConfigurationDB_RO_ALERT_MAXIDX;j++) {
	    cacheRecipeObject[j][value_idx]=cacheRecipeObject[j][alert_idx];
	}

        dynAppend(remove_alert_idx, alert_idx);
    }

    // sort remove_alert_idx in descending, and remove the entries
    dynSortAsc(remove_alert_idx);

    for (int i=dynlen(remove_alert_idx);i>=1;i--) {
	for (int j=1;j<=fwConfigurationDB_RO_MAXIDX;j++){
	    dynRemove(cacheRecipeObject[j],remove_alert_idx[i]);
	}
    }


    // resolve device types, hierarchies

        if (g_fwConfigurationDB_Debug & 4) DebugN("processing device types and hierarchies");
        // we assume that properties of a device are kept in a contiguous blocks,
        // so we could limit the number of dynContains() calls and speed up significantly
	string previousName="";
	string previousType="";
	string previousHierarchy="";
	int n=dynlen(cacheRecipeObject[fwConfigurationDB_RO_DP_NAME]);
	for (int i=1;i<=n;i++){
	    string dpName=cacheRecipeObject[fwConfigurationDB_RO_DP_NAME][i];
	    if (dpName==previousName) {
		cacheRecipeObject[fwConfigurationDB_RO_DP_TYPE][i]=previousType;
		cacheRecipeObject[fwConfigurationDB_RO_HIERARCHY][i]=previousHierarchy;
		continue;
	    }
	    previousName=dpName;
	    string dpType;
	    int idx=dynContains(datapoints_names,dpName);
	    if (idx<1) {
        	// just issue the warning to the log, this is not an error...
    		DebugN("WARNING: Inconsistency encountered in Recipe Cache "+cacheName);
        	DebugN("         value for elements of DP "+dpName+" present");
        	DebugN("         while the device is not in the "+cacheName+".DataPoints list.");
        	DebugN("         the settings will not be taken.");
        	continue;
	    }
    	    cacheRecipeObject[fwConfigurationDB_RO_DP_TYPE][i]=datapoints_types[idx];
    	    cacheRecipeObject[fwConfigurationDB_RO_HIERARCHY][i]=datapoints_hierarchies[idx];
	    previousType=datapoints_types[idx];
	    previousHierarchy=datapoints_hierarchies[idx];
	}



    // check if we need to resolve logical devs (#31813),
    // and only if we have (any) logical devices, get them...
   if (dynContains(datapoints_hierarchies,"LOGICAL")) {

    dyn_string allDps;
    dyn_string allAliases;
    dpGetAllAliases(allDps,allAliases,"*",recipeSystem+"*.**");

        if (g_fwConfigurationDB_Debug & 4)  DebugN("Resolve aliases...");
        for (int i=1;i<=dynlen(cacheRecipeObject[fwConfigurationDB_RO_DPE_NAME]);i++) {
    	    string deviceName=cacheRecipeObject[fwConfigurationDB_RO_DP_NAME][i];
    	    string dpName="";
    	    if (strpos(deviceName,":")>=1) {
    		// this is the "HARDWARE" hierarchy - includes system name and ":"!
    		dpName=deviceName;
    	    } else {
        	//dpName=dpAliasToName(deviceName);
        	int idx=dynContains(allAliases,deviceName);
        	if (idx>=1) dpName=allDps[idx];
    	    }
    	    if (dpName=="") {
                fwException_raise(exceptionInfo, "ERROR", "Cannot resolve device \n"+cacheRecipeObject[fwConfigurationDB_RO_DP_NAME][i],"");
                return;
            }

            dpName=strrtrim(dpName,".");
            cacheRecipeObject[fwConfigurationDB_RO_DPE_NAME][i]=dpName+cacheRecipeObject[fwConfigurationDB_RO_ELEMENT_NAME][i];
        }

    }

    // bugfix #13735
    if (dynlen(alerts_dpetypes)<1) {
        if (g_fwConfigurationDB_Debug & 4) DebugN("fixing element type information");
	for (int i=1;i<=dynlen(cacheRecipeObject[1]);i++) {
	    if (cacheRecipeObject[fwConfigurationDB_RO_ELEMENT_TYPE][i]!=0) continue;
		int elementType=dpElementType(cacheRecipeObject[fwConfigurationDB_RO_DPE_NAME][i]);
		cacheRecipeObject[fwConfigurationDB_RO_ELEMENT_TYPE][i]=elementType;
	}
    }


    // we also need to include "empty" entries: datapoints with no properties
    for (int i=1;i<=dynlen(datapoints_names);i++) {
	    string itemName=datapoints_names[i];

	    if (dynlen(deviceList)) {
		if (!dynContains(deviceList,itemName)) continue;
	    }

	    int idx=dynContains(cacheRecipeObject[fwConfigurationDB_RO_DP_NAME],itemName);
	    if (idx>0) continue; // already present - no need to store

	    // we'd like to append: i.e. find the index for new entry
            idx=dynlen(cacheRecipeObject[fwConfigurationDB_RO_DPE_NAME])+1;
	    string dpName="";
	    if (strpos(itemName,":")>=1) {
		// this is hardware hierarchy
		dpName=itemName;
	    } else {
		if (datapoints_types[i]=="FwNode") {
		    dpName=itemName; // for FwNode, we take the name directly!
		} else {
		    dpName=dpAliasToName(itemName);
		}
	    }

	    if (dpName=="") {
        	fwException_raise(exceptionInfo, "ERROR", "Cannot resolve device "+itemName+" found in recipe cache","");
            	return;
    	    }
    	    dpName=strrtrim(dpName,".");

	    // fill the new entry
            cacheRecipeObject[fwConfigurationDB_RO_DPE_NAME][idx]=dpName+".";
    	    cacheRecipeObject[fwConfigurationDB_RO_DP_NAME][idx]=itemName;
            cacheRecipeObject[fwConfigurationDB_RO_DP_TYPE][idx]=datapoints_types[i];
            cacheRecipeObject[fwConfigurationDB_RO_HIERARCHY][idx]=datapoints_hierarchies[i];
            cacheRecipeObject[fwConfigurationDB_RO_ELEMENT_NAME][idx]=".";
            cacheRecipeObject[fwConfigurationDB_RO_ELEMENT_TYPE][idx]=0;
            cacheRecipeObject[fwConfigurationDB_RO_HAS_VALUE][idx]=FALSE;
            cacheRecipeObject[fwConfigurationDB_RO_HAS_ALERT][idx]=FALSE;
            anytype dummy;
            for (int k=fwConfigurationDB_RO_VALUE;k<=fwConfigurationDB_RO_ALERT_MAXIDX;k++) cacheRecipeObject[k][idx]=dummy;
            // fix #20400
            for (int k=fwConfigurationDB_RO_ALERT_MAXIDX+1;k<=fwConfigurationDB_RO_MAXIDX;k++) cacheRecipeObject[k][idx]=dummy;

    }


    if (comment!="") cacheRecipeObject[fwConfigurationDB_RO_META_COMMENT][1]=comment;
    cacheRecipeObject[fwConfigurationDB_RO_META_ORIGNAME][1]=cacheName;
    if (recipeType!="") cacheRecipeObject[fwConfigurationDB_RO_META_RECIPETYPE][1]=recipeType;
  
    time tNull=0;

    if (className!="") cacheRecipeObject[fwConfigurationDB_RO_META_CLASSNAME][1]=className;
    if (author!="") cacheRecipeObject[fwConfigurationDB_RO_META_AUTHOR][1]=author;
    if (creationTime>tNull) cacheRecipeObject[fwConfigurationDB_RO_META_CREATIONTIME][1]=creationTime;
    if (lastActivationTime>tNull) cacheRecipeObject[fwConfigurationDB_RO_META_LASTACTIVATIONTIME][1]=lastActivationTime;
    if (lastModificationTime>tNull)cacheRecipeObject[fwConfigurationDB_RO_META_LASTMODIFICATIONTIME][1]=lastModificationTime;
    if (lastActivationUser!="") cacheRecipeObject[fwConfigurationDB_RO_META_LASTACTIVATIONUSER][1]=lastActivationUser;
    if (lastModificationUser!="") cacheRecipeObject[fwConfigurationDB_RO_META_LASTMODIFICATIONUSER][1]=lastModificationUser;
    cacheRecipeObject[fwConfigurationDB_RO_META_PREDEFINED][1]=predefined;
    if (recipeVersion!="") cacheRecipeObject[fwConfigurationDB_RO_META_RECIPEVERSION][1]=recipeVersion;

    fwConfigurationDB_combineRecipes( 	recipeObject,
					recipeObject,
					cacheRecipeObject,
					exceptionInfo);


    if (fwConfigurationDB_progress(fwConfigurationDB_OPER_LoadRecipeFromCache,"Loaded recipe from cache",
        100.0, exceptionInfo)) return;

    _fwConfigurationDB_endFunction("getRecipeFromCache", t0);
}







/** Saves the differences in recipe to the database
 *
 * This function firstly compares the specified recipe with the one already in the database
 * then stores only the differences
 *
 * @param recipeObject          should contain the recipe data to be stored
 * @param hierarchyType         dummy now
 * @param versionDescription    a text describing this version
 * @param exceptionInfo         standard exception handling variable
 * @param tag                   recipe tag (recipe name)
 *
 * @ingroup RecipeFunctions
 * @see @ref qstart_recipe_apply section of the Quick Start
 * @deprecated use @ref fwConfigurationDB_saveDiffRecipeToDB instead
 */
 
 
void fwConfigurationDB_storeDiffRecipeInDB(dyn_dyn_mixed recipeObject, string hierarchyType, string versionDescription,
			    dyn_string &exceptionInfo, string tag,string system="", bool autoSaveDevices=FALSE)
{

    time t0;
    _fwConfigurationDB_startFunction("storeDiffRecipeInDB", t0);
    fwConfigurationDB_checkOpenDB(exceptionInfo);
    if (dynlen(exceptionInfo)) return;


    dyn_string existingRecipes;
    fwConfigurationDB_getRecipesInDB(existingRecipes, exceptionInfo);
    if (dynlen(exceptionInfo)) return;

    if (!dynContains(existingRecipes,tag)) {
	//DebugN("INFO: storeDiffRecipeInDB called, but recipe "+tag+" does not exist yet in the DB. Storing the recipe.");
	if (fwConfigurationDB_progress(fwConfigurationDB_OPER_SaveRecipeToDB,"Storing recipe to DB", 10.0,
    	    exceptionInfo)) return;
	fwConfigurationDB_saveRecipeToDB(recipeObject, "", tag,  exceptionInfo, versionDescription,autoSaveDevices);

	if (dynlen(exceptionInfo)) return;
	_fwConfigurationDB_endFunction("storeDiffRecipeInDB", t0);
	// simply store the recipe!
	return;
    }


    if (fwConfigurationDB_progress(fwConfigurationDB_OPER_SaveRecipeToDB,"Comparing recipes: get recipe from DB", 10.0,
        exceptionInfo)) return;

//    if ((hierarchyType==fwDevice_HARDWARE) && (system=="")) system=getSystemName();
    if (dynlen(recipeObject)==0) _fwConfigurationDB_ClearRecipeObject(recipeObject);


    dyn_dyn_mixed dbRecipeObject, diffRecipeObject;
    dyn_string deviceList=recipeObject[fwConfigurationDB_RO_DP_NAME];
    dynUnique(deviceList);

    if (fwConfigurationDB_progress(fwConfigurationDB_OPER_SaveRecipeToDB,"Comparing recipes: get recipe from DB", 10.0,
        exceptionInfo)) return;

//    fwConfigurationDB_getRecipeFromDB("", deviceList, hierarchyType, tag, dbRecipeObject, exceptionInfo,system);

    dyn_dyn_mixed dbRecipeObject; // the data that we will get from DB
    _fwConfigurationDB_ClearRecipeObject(dbRecipeObject);

//    if ((hierarchyType==fwDevice_HARDWARE) && (system=="")) system=getSystemName();

    dyn_int prop_ids;
    _fwConfigurationDB_getRecipeDataFromDB("", deviceList, hierarchyType, tag, dbRecipeObject, exceptionInfo, system, prop_ids);
    if (dynlen(exceptionInfo)) return;

    bool differs = fwConfigurationDB_compareRecipes( dbRecipeObject, recipeObject, diffRecipeObject, hierarchyType, exceptionInfo);
    if (dynlen(exceptionInfo)) return;

    if (!differs) {
	DebugN("No differences w.r.t recipe in db");
	if (fwConfigurationDB_progress(fwConfigurationDB_OPER_SaveRecipeToDB,"No changes to store", 100.0, exceptionInfo)) return;
	_fwConfigurationDB_endFunction("storeDiffRecipeInDB", t0);
	return;
    }

    // append differences to the current recipe, and push to the database.
    // the PL/SQL function will be wise enough to actually save only the
    // things that has changed...
    dyn_dyn_mixed newRecipeObject;
    fwConfigurationDB_combineRecipes( newRecipeObject,
    				      dbRecipeObject,
                                      diffRecipeObject,
    	    			      exceptionInfo);
    if (dynlen(exceptionInfo)) return;

/*
DebugN("in db:",dbRecipeObject);
DebugN("diff:",diffRecipeObject);
DebugN("will store",newRecipeObject);
*/

    fwConfigurationDB_saveRecipeToDB(newRecipeObject, "",tag,exceptionInfo,versionDescription,autoSaveDevices);
    if (dynlen(exceptionInfo)) return;
    _fwConfigurationDB_endFunction("storeDiffRecipeInDB", t0);
}

/** Saves recipe to the database
 *
 * This function stores a new version of recipe data,
 *
 * @param recipeObject          should contain the recipe data to be stored
 * @param hierarchyType         the type of Framework hierarchy: fwDevice_HARDWARE or fwDevice_LOGICAL.
 * @param versionDescription    a text describing this version
 * @param exceptionInfo         standard exception handling variable
 * @param tag                   recipe name; if empty name is specified, the function will try to figure out
 *				the name from the meta-information stored in the recipeObject
 *
 * @ingroup RecipeFunctions
 * @see @ref qstart_recipe_apply section of the Quick Start
 * @deprecated use @ref fwConfigurationDB_saveRecipeToDB instead
 */
void fwConfigurationDB_storeRecipeInDB(dyn_dyn_mixed recipeObject, string hierarchyType, string versionDescription,
			    dyn_string &exceptionInfo, string tag)
{

    fwConfigurationDB_checkOpenDB(exceptionInfo);
    if (dynlen(exceptionInfo)) return;

    if (fwConfigurationDB_SchemaPrivs!="OWNER" && fwConfigurationDB_SchemaPrivs!="WRITER") {
	fwException_raise(exceptionInfo,"ERROR","Insufficient database rights for storing recipes","");
	return;
    }

    // check if the recipe exists; if not, create a new one...
    dyn_string existingRecipes;
    fwConfigurationDB_getRecipesInDB(existingRecipes, exceptionInfo);
    if (dynlen(exceptionInfo)) return;

    if (!dynContains(existingRecipes,tag)) {
	string createRecipeSql="BEGIN fwConfigurationDB.createRecipe('"+tag+"');END;";
	fwConfigurationDB_executeSqlSimple(createRecipeSql, g_fwConfigurationDB_DBConnection, exceptionInfo);
	if (dynlen(exceptionInfo)) return;

	    // update the meta info, if specified...
	if (dynlen(recipeObject[fwConfigurationDB_RO_META_COMMENT])) {
	    string recCmt=recipeObject[fwConfigurationDB_RO_META_COMMENT][1];
	    if (recCmt!="") fwConfigurationDB_setRecipeDescriptionInDB(tag, recCmt, exceptionInfo);
	    if (dynlen(exceptionInfo)) return;
	}

	if (dynlen(recipeObject[fwConfigurationDB_RO_META_RECIPETYPE])) {
	    string recTyp=recipeObject[fwConfigurationDB_RO_META_RECIPETYPE][1];
	    if (recTyp!="") fwConfigurationDB_setRecipeTypeInfoInDB(tag, recTyp, exceptionInfo);
	    if (dynlen(exceptionInfo)) return;
	}


    }

    //dyn_int propsToInvalidate;
    //_fwConfigurationDB_storeRecipeInDB(recipeObject, hierarchyType, versionDescription, exceptionInfo, tag, propsToInvalidate);
    _fwConfigurationDB_storeRecipeInDB(recipeObject, tag, versionDescription, exceptionInfo);

}

void _fwConfigurationDB_storeRecipeInDB(dyn_dyn_mixed recipeObject,
    string recipeName, string versionDescription, dyn_string &exceptionInfo)
{

    if (fwConfigurationDB_SchemaPrivs!="OWNER" && fwConfigurationDB_SchemaPrivs!="WRITER") {
	fwException_raise(exceptionInfo,"ERROR","Insufficient database rights for storing recipes","");
	return;
    }

    // here we assume that the recipe already exists

    time t0;
    _fwConfigurationDB_startFunction("storeRecipeInDB", t0);

    if (recipeName=="") {
	// we will try to use the name that is in meta-info of the recipeObject
	int rc=_fwConfigurationDB_getRecipeOriginalName(recipeObject, recipeName, exceptionInfo);
	if (rc!=0) { fwException_raise(exceptionInfo,"ERROR","Empty name for recipe specified;","");return; }
	DebugN("INFO: empty recipe name in storeRecipeInDB(). Using the one from recipeObject:",recipeName);
    }

    if (dynlen(recipeObject[fwConfigurationDB_RO_DP_NAME])==0) {
	fwException_raise(exceptionInfo,"WARNING","The recipe object is empty...",""); return;
    }

    if (fwConfigurationDB_progress(fwConfigurationDB_OPER_SaveRecipeToDB,"Store recipe in database", 0.0,
        exceptionInfo)) return;

    int rc=fwDbBeginTransaction(g_fwConfigurationDB_DBConnection);
    if (rc) { fwException_raise(exceptionInfo,"ERROR","Cannot start new transaction",""); return;};

    dyn_mixed dummyOutput;
    fwConfigurationDB_callPlSqlApi( "storeRecipe",
		    makeDynMixed(recipeName,versionDescription,getUserName()),
		    "S1,S2,I4,I5,C1,I6,I7,S5,S6,S7,I1", "",
		    makeDynMixed(
			recipeObject[fwConfigurationDB_RO_DP_NAME],
			recipeObject[fwConfigurationDB_RO_ELEMENT_NAME],
			recipeObject[fwConfigurationDB_RO_HAS_VALUE],
			recipeObject[fwConfigurationDB_RO_HAS_ALERT],
			recipeObject[fwConfigurationDB_RO_VALUE],
			recipeObject[fwConfigurationDB_RO_ALERT_TYPE],
			recipeObject[fwConfigurationDB_RO_ALERT_ACTIVE],
			recipeObject[fwConfigurationDB_RO_ALERT_LIMITS],
			recipeObject[fwConfigurationDB_RO_ALERT_CLASSES],
			recipeObject[fwConfigurationDB_RO_ALERT_TEXTS],
			recipeObject[fwConfigurationDB_RO_RECDATA_PROPID]
		    ),
		    dummyOutput,exceptionInfo);
    if (dynlen(exceptionInfo)) {fwDbRollbackTransaction(g_fwConfigurationDB_DBConnection);return;}

    if (fwConfigurationDB_progress(fwConfigurationDB_OPER_SaveRecipeToDB,"Updating meta info", 90.0, exceptionInfo)) return;



    rc=fwDbCommitTransaction(g_fwConfigurationDB_DBConnection);
    if (rc) {fwException_raise(exceptionInfo,"ERROR","Cannot commit transaction","");return;};

    if (fwConfigurationDB_progress(fwConfigurationDB_OPER_SaveRecipeToDB,"Recipe saved in DB", 100.0, exceptionInfo)) return;

    _fwConfigurationDB_endFunction("storeRecipeInDB", t0);

}

/** Loads a recipe from database
 * @param topDevice     the top device in the hierarchy - it is a "hint" for the database,
 *                      telling where to start looking for. An empty string ("") may safely
 *                      be specified to tell that the devices should be searched for starting
 *                      from the very top of hierarchy.
 * @param deviceList    the list of devices for which the recipe should be loaded.
 *			specifying empty list will result in loading the whole recipe data
 *			(for all devices)
 * @param hierarchyType hierarchy type, dummy parameter now...
 * @param tag           the recipe tag (recipe name)
 * @param recipeObject  on return will contain the recipe data
 * @param exceptionInfo standard exception handling variable
 * @ingroup RecipeFunctions
 * @see @ref qstart_recipes section of Quick Start
 * @deprecated use @ref fwConfigurationDB_loadRecipeFromDB instead
 */
void fwConfigurationDB_getRecipeFromDB(string topDevice, dyn_string deviceList, string hierarchyType,
	string tag, dyn_dyn_mixed &recipeObject, dyn_string &exceptionInfo, string system="", time validAt=0)
{
    time t0;
    _fwConfigurationDB_startFunction("getRecipeFromDB", t0);

    if (fwConfigurationDB_SchemaPrivs!="OWNER" && fwConfigurationDB_SchemaPrivs!="WRITER" && fwConfigurationDB_SchemaPrivs!="READER") {
	fwException_raise(exceptionInfo,"ERROR","Insufficient database rights for loading recipes","");
	return;
    }


    dyn_string recipeTags;
    fwConfigurationDB_getRecipesInDB(recipeTags, exceptionInfo);
    if (dynlen(exceptionInfo)) return;

    if (!dynContains(recipeTags,tag)) {
	fwException_raise(exceptionInfo,"ERROR","Recipe "+tag+" does not exist in DB","");
	return;
    }

    dyn_dyn_mixed dbRecipeObject; // the data that we will get from DB
    _fwConfigurationDB_ClearRecipeObject(dbRecipeObject);

//    if ((hierarchyType==fwDevice_HARDWARE) && (system=="")) system=getSystemName();

    if (dynlen(recipeObject)==0) _fwConfigurationDB_ClearRecipeObject(recipeObject);

    if (fwConfigurationDB_progress(fwConfigurationDB_OPER_LoadHierachyFromDB,"Loading recipe from DB",
        10.0, exceptionInfo)) return;



    dyn_int prop_ids;
    _fwConfigurationDB_getRecipeDataFromDB(topDevice, deviceList, hierarchyType, tag, dbRecipeObject, exceptionInfo, system,prop_ids, validAt);
    if (dynlen(exceptionInfo)) return;


    _fwConfigurationDB_getRecipeMetaInformationFromDB(tag, hierarchyType, dbRecipeObject, exceptionInfo);
    if (dynlen(exceptionInfo)) return;

    // now we combine the recipes - the one that was already in recipeObject
    // and the one we got from DB...
    if (fwConfigurationDB_progress(fwConfigurationDB_OPER_LoadHierachyFromDB,"Combining the recipes",
        95.0, exceptionInfo)) return;

    fwConfigurationDB_combineRecipes( 	recipeObject,
					recipeObject,
					dbRecipeObject,
					exceptionInfo);

    if (dynlen(exceptionInfo)) return;

    if (fwConfigurationDB_progress(fwConfigurationDB_OPER_LoadHierachyFromDB,"Recipe loaded from DB",
        100.0, exceptionInfo)) return;

    _fwConfigurationDB_endFunction("getRecipeFromDB", t0);

}


void _fwConfigurationDB_getRecipeMetaInformationFromDB(string recipeName, string hierarchyType,
	dyn_dyn_mixed &recipeObject, dyn_string &exceptionInfo)
{
    if (fwConfigurationDB_SchemaPrivs!="OWNER" && fwConfigurationDB_SchemaPrivs!="WRITER" && fwConfigurationDB_SchemaPrivs!="READER") {
	fwException_raise(exceptionInfo,"ERROR","Insufficient database rights for loading recipes","");
	return;
    }

    string sql="SELECT TAGID,NAME,HVER,DESCRIPTION,RECIPE_TYPE FROM RECIPES WHERE NAME=\'"+recipeName+"\'";

//    if (hierarchyType!="") sql=sql+" AND HVER="+g_fwConfigurationDB_DBHierarchyIDs[hierarchyType];

    dyn_dyn_mixed aRecords;
    _fwConfigurationDB_executeDBQuery(sql,g_fwConfigurationDB_DBConnection, aRecords, exceptionInfo,5,TRUE);
    if (dynlen(exceptionInfo)) return;

    if (dynlen(aRecords)<1) {
	fwException_raise(exceptionInfo,"ERROR","Cannot locate recipe "+recipeName+" in the database","");
	return;
    }

    _fwConfigurationDB_setRecipeComment(recipeObject, aRecords[4][1], exceptionInfo);
    _fwConfigurationDB_setRecipeOriginalName(recipeObject, recipeName, exceptionInfo);
    _fwConfigurationDB_setRecipeOriginalRecipeType(recipeObject, aRecords[5][1], exceptionInfo);

}

void _fwConfigurationDB_getRecipeDataFromDB(string topDevice,
                                         dyn_string deviceList,
                                         string hierarchyType,
                                         string recipeName,
                                        dyn_dyn_mixed &dbRecipeObject,
                                        dyn_string &exceptionInfo,
                                        string system,
                                        dyn_int &prop_ids,
                                        time validAt=0)
{

    time zeroTime=0;

    _fwConfigurationDB_ClearRecipeObject(dbRecipeObject);

    // fix #14725: the case of user passing "" instead of makeDynString()
    // as deviceList parameter!
    if ((dynlen(deviceList)==1) && deviceList[1]=="") {
	    deviceList=makeDynString();
    }


    if (fwConfigurationDB_progress(fwConfigurationDB_OPER_LoadHierachyFromDB,"Locating devices in DB",
    	    20.0, exceptionInfo)) return;


    // cleanup Input/Output table
    fwConfigurationDB_executeSqlSimple("DELETE FROM CDB_API_PARAMS", g_fwConfigurationDB_DBConnection, exceptionInfo);
    if (dynlen(exceptionInfo)) return;

    int rc;

    if ( dynlen(deviceList)>0 ) { // use specified device list
	string insertDeviceSql="insert into cdb_api_params(s1) values (:dpname)";
	_fwConfigurationDB_executeDBBulkCmd(insertDeviceSql,g_fwConfigurationDB_DBConnection,
                                        makeDynMixed(deviceList),exceptionInfo, TRUE);
	if (dynlen(exceptionInfo)) return;

    } else if (topDevice!="") { // use hierarchy from topDevice

	dyn_mixed params;
	dynAppend(params,recipeName);
	string topDeviceSql;
	if (topDevice=="/") {
    	    topDeviceSql="dpname is null";
	} else {
	    topDeviceSql="dpname=:topDevice";
	    dynAppend(params,topDevice);
	}

	string selectDevicesSql = "insert into CDB_API_PARAMS(s1) select dpname from v_items "+
		" where item_id in ( "+
		"      select unique item_id from v_recipesAll "+
                "      where valid_To is Null "+
                "      and tag=:recipeName"+
                ")"+
	        " connect by prior item_id=parent_id  start with "+topDeviceSql+
	        " order by item_id";

	_fwConfigurationDB_executeDBBulkCmd(selectDevicesSql,g_fwConfigurationDB_DBConnection,
                                        makeDynMixed(params),exceptionInfo);

	if (dynlen(exceptionInfo)) return;

    }  else {
	// topDevice is "", no device list -> that means: extract all in recipe
    }



    // check/process the time specification; if "0" was passed, we need to conver it to NULL..
    anytype timeSpec; // null
    time zeroTime=0;
    if (validAt>zeroTime) timeSpec=validAt;

    dyn_mixed aRecords;

    fwConfigurationDB_callPlSqlApi( "getRecipe2",
		    makeDynMixed(recipeName,timeSpec),
		    "",
		    "i1,i2,i3,i4,i5,i6,i7,s1,s2,s3,s4,s5,s6,s7,c1,s9,d1,d2",
		    makeDynMixed(), // device specification already inserted above!
		    aRecords,
		    exceptionInfo,
		    makeDynInt(0,0,0,BOOL_VAR,BOOL_VAR,0,BOOL_VAR,0,0,0,0,DYN_FLOAT_VAR,DYN_STRING_VAR,DYN_STRING_VAR,0,0,0,0), // column types
		    FALSE // do not cleanup the input table!
		    );
    if (dynlen(exceptionInfo)) {fwDbRollbackTransaction(g_fwConfigurationDB_DBConnection);return;}


    if (dynlen(aRecords)==0) {
//	DebugN("WARNING! Recipe returned by DB is empty! Probably none of selected devices is in the recipe");
	return;
    } else {
	if (dynlen(aRecords[1])==0) {
//	DebugN("WARNING! Recipe returned by DB is empty! Probably none of selected devices is in the recipe");
	return;
	}
    }


    dyn_string colDevice	= aRecords[8];
    dyn_string colProperty	= aRecords[9];
    dyn_string colDpType	= aRecords[10];
//    dyn_string colDevModel	= aRecords[11];
    dyn_string colHierarchy	= aRecords[16];

    dyn_string dpes; // we will construct it here...

    // warnings about unresolved devices should be reported only once...
    dyn_string unresolved;

    for (int i=1;i<=dynlen(colProperty);i++) {
        if (colHierarchy[i]==fwDevice_HARDWARE) {
    	    dpes[i]=colDevice[i]+colProperty[i];

    	} else if (colHierarchy[i]==fwDevice_LOGICAL) {
	    // FwNodes need to pass without change.
	    if (colDpType[i]=="FwNode") {
		//DPE should simply have a dot at the end
		dpes[i]=colDevice[i]+".";
		continue;
	    }

            string dpName=dpAliasToName(colDevice[i]);
            if (dpName!="") {
        	dpName=strrtrim(dpName,".");
        	dpes[i]=dpName+colProperty[i];
            } else {
        	if (!dynContains(unresolved,colDevice[i])) {
        	    dynAppend(unresolved,colDevice[i]);
            	    // {fwException_raise(exceptionInfo, "ERROR", "Cannot resolve logical device "+dbRecipeObject[fwConfigurationDB_RO_DP_NAME][i],"");return;}
            	    DebugN("Cannot resolve logical device "+colDevice[i]);
            	}
        	dpes[i]="";
	    }

        } else {
    	    fwException_raise(exceptionInfo,"Cannot resolve device "+colDevice[i]+"\n Unknown hierarchy:"+colHierarchy[i],"");
    	    return;
        }

    }

    dbRecipeObject[fwConfigurationDB_RO_DPE_NAME]       = dpes;
    dbRecipeObject[fwConfigurationDB_RO_DP_TYPE]	= colDpType;
    dbRecipeObject[fwConfigurationDB_RO_HIERARCHY]	= colHierarchy;
    dbRecipeObject[fwConfigurationDB_RO_DP_NAME]	= colDevice;
    dbRecipeObject[fwConfigurationDB_RO_ELEMENT_NAME]	= colProperty;
    dbRecipeObject[fwConfigurationDB_RO_ELEMENT_TYPE] 	= aRecords[2];;
    dbRecipeObject[fwConfigurationDB_RO_HAS_VALUE] 	= aRecords[4];
    dbRecipeObject[fwConfigurationDB_RO_HAS_ALERT] 	= aRecords[5];
    dbRecipeObject[fwConfigurationDB_RO_VALUE] 		= aRecords[15];
    dbRecipeObject[fwConfigurationDB_RO_REC_VERSIONID]  = aRecords[3];
    dbRecipeObject[fwConfigurationDB_RO_RECDATA_PROPID] = aRecords[1];
    dbRecipeObject[fwConfigurationDB_RO_DATECREATED] 	= aRecords[17];
    dbRecipeObject[fwConfigurationDB_RO_ALERT_ACTIVE]	= aRecords[7];
    dbRecipeObject[fwConfigurationDB_RO_ALERT_TEXTS]	= aRecords[14];
    dbRecipeObject[fwConfigurationDB_RO_ALERT_LIMITS] 	= aRecords[12];;
    dbRecipeObject[fwConfigurationDB_RO_ALERT_CLASSES] 	= aRecords[13];
    dbRecipeObject[fwConfigurationDB_RO_ALERT_TYPE]	= aRecords[6];

    // for compatibility...
    prop_ids=dbRecipeObject[fwConfigurationDB_RO_RECDATA_PROPID];

    // cleanup Input/Output table
    fwConfigurationDB_executeSqlSimple("DELETE FROM CDB_API_PARAMS", g_fwConfigurationDB_DBConnection, exceptionInfo);
    if (dynlen(exceptionInfo)) return;

}




/** gets the properties (DPEs) to be saved, according to the current recipeType

@param dataPointType	the data point type for which properties are queried
@param exceptionInfo 	standard exception handling variable
@returns		the list of data point elements for specified dataPointType


*/
dyn_string fwConfigurationDB_getRTValues(string dataPointType, dyn_string &exceptionInfo)
{
    dyn_string RTValues;

    // load default recipe type, if needed
    if ( GfwConfigurationDB_currentRecipeType == "") fwConfigurationDB_setRecipeType("", exceptionInfo);
    if (dynlen(exceptionInfo)) return RTValues;

    if (!mappingHasKey(GfwConfigurationDB_RTValues,dataPointType)) {
	fwException_raise(exceptionInfo,
			  "WARNING",
			  "No definition of values to store for DPT:"+
			    dataPointType+
			    " in the current recipe type ("+
			    GfwConfigurationDB_currentRecipeType+")",
			  fwConfigurationDB_ERROR_NoValuesDataInRT);
	return RTValues;
    };

    RTValues=GfwConfigurationDB_RTValues[dataPointType];

    return RTValues;
}


/** gets the properties (DPEs) for which alert settings shoul be saved, according to the current recipeType

@param dataPointType	the data point type for which properties are queried
@param exceptionInfo 	standard exception handling variable
@returns		the list of data point elements for specified dataPointType


*/
dyn_string fwConfigurationDB_getRTAlerts(string dataPointType, dyn_string &exceptionInfo)
{

    dyn_string RTAlerts;

    // load default recipe type, if needed
    if ( GfwConfigurationDB_currentRecipeType == "") fwConfigurationDB_setRecipeType("", exceptionInfo);
    if (dynlen(exceptionInfo)) return RTAlerts;

    if (!mappingHasKey(GfwConfigurationDB_RTAlerts,dataPointType)) {
	fwException_raise(exceptionInfo,
			  "WARNING",
			  "No definition of alerts to store for DPT:"+
			    dataPointType+
			    " in the current recipe type ("
			    +GfwConfigurationDB_currentRecipeType+")",
			  fwConfigurationDB_ERROR_NoAlertsDataInRT);
	return RTAlers;
    };

    RTAlerts=GfwConfigurationDB_RTAlerts[dataPointType];

    return RTAlerts;


}





/** Handles the situation where the Recipe Type is missing

This function handles the situation when missing Recipe Type data
for some device type is encountered, which is signaled by the
@ref fwConfigurationDB_ERROR_NoValuesDataInRT  exception.

It displays the dialog that allows to edit the properties to be stored, etc.

@param dataPoint        the name of the data point that causes the problem
@param dpType           the data point type for dataPoint
@param exceptionInfo 	standard exception handling variable
@returns                FALSE if the situation could not be recovered
                        (i.e. user cancelled the dialog), TRUE otherwise.

*/
bool _fwConfigurationDB_HandleMissingRT(string dataPoint, string dpType,
                                         dyn_string &exceptionInfo)
{
    // we handle only this type of error:
    if (exceptionInfo[3] != fwConfigurationDB_ERROR_NoValuesDataInRT ) {
        // re-throw the error...
        return false;

    }

    dyn_float df;
    dyn_string ds;
    dyn_string locExceptionInfo;
    ChildPanelOnCentralModalReturn("fwConfigurationDB/fwConfigurationDB_RecipeSave_MissingRT.pnl",
                                   "Missing Recipe Type Data",
                                   makeDynString("$DataPointName:"+dataPoint,
                                                 "$DataPointType:"+dpType),
                                   df,ds);
    if (dynlen(df)<1) {
        fwException_raise(exceptionInfo, "ERROR","Recipe creation aborted.",
                          fwConfigurationDB_ERROR_OperationAborted);
        return FALSE;
    }
    if (df[1]==3.0) {
        // add temporarily to current recipe type,
        // storing none of properties
        string dev;
        dyn_string propNames,dpes;
        _fwConfigurationDB_getPropertiesAndDPEs   ( dpType, propNames, dpes, dev,locExceptionInfo);

        if (dynlen(locExceptionInfo)) { dynAppend(exceptionInfo,locExceptionInfo); return FALSE; }
        GfwConfigurationDB_RTValues[dpType]=makeDynString();
        GfwConfigurationDB_RTAlerts[dpType]=makeDynString();
        GfwConfigurationDB_RTDevices[dpType]=dev;
        dynClear(exceptionInfo);
        return TRUE;

    } else if (df[1]==2.0) {

        // add temporarily to current recipe type...
        // storing all of properties

        string dev;
        dyn_string propNames,dpes;
        _fwConfigurationDB_getPropertiesAndDPEs   ( dpType, propNames, dpes, dev,locExceptionInfo);

        if (dynlen(locExceptionInfo)) { dynAppend(exceptionInfo,locExceptionInfo); return FALSE; }
        GfwConfigurationDB_RTValues[dpType]=dpes;
        GfwConfigurationDB_RTAlerts[dpType]=dpes;
        GfwConfigurationDB_RTDevices[dpType]=dev;
        dynClear(exceptionInfo);
        return TRUE;
    } else if (df[1]==1.0) {
        // should have been added already, hope it's OK
        dynClear(exceptionInfo);
        return TRUE;
    } else {
        // just abort...
        fwException_raise(exceptionInfo, "ERROR","Recipe creation aborted.",
                          fwConfigurationDB_ERROR_OperationAborted);
        return FALSE;
    };


}


void _fwConfigurationDB_recipeObjectToAlertObject(dyn_mixed recipeObject,
						  string dpe,
						  dyn_dyn_anytype &alertObject,
						  dyn_string &exceptionInfo)
{

    bool active; // if alert is active or not
    int type; // alert type, be it DPCONFIG_NONE, DPCONFIG_ALERT_BINARYSIGNAL, DPCONFIG_ALERT_NONBINARYSIGNAL
    dyn_float limits;
    dyn_string classes;
    dyn_string texts;
    string panel;
    dyn_string panelParameters;
    string help;
    string dpeName;


    int idx=dynContains(recipeObject[fwConfigurationDB_RO_DPE_NAME],dpe);
    if (idx<1) {
        fwException_raise(exceptionInfo,"ERROR","Data point element "+dpe+" not found in recipe",fwConfigurationDB_ERROR_DPENotInRecipe);
        return;
    };

    // for the case of logical hierarchy, we need to substitute the name
    // in the alertObject, so it is the actual name from the LOGICAL
    // hierarchy, not the dpe passed as argument, which reflects some
    // device in HARDWARE hierarchy!
    // so we should rather re-construct it...
    dpeName=recipeObject[fwConfigurationDB_RO_DP_NAME][idx]+recipeObject[fwConfigurationDB_RO_ELEMENT_NAME][idx];

    string dpeType=recipeObject[fwConfigurationDB_RO_ELEMENT_TYPE][idx];
    bool configExists=recipeObject[fwConfigurationDB_RO_HAS_ALERT][idx];

    type=DPCONFIG_NONE;

    if (configExists) {
        type=recipeObject[fwConfigurationDB_RO_ALERT_TYPE][idx];
	    active=recipeObject[fwConfigurationDB_RO_ALERT_ACTIVE][idx];
        limits=recipeObject[fwConfigurationDB_RO_ALERT_LIMITS][idx];
        classes=recipeObject[fwConfigurationDB_RO_ALERT_CLASSES][idx];
        texts=recipeObject[fwConfigurationDB_RO_ALERT_TEXTS][idx];
    }



    _fwAlertConfig_createDpeAlertConfigObject(alertObject,dpeName,type,
                                              active,limits,classes,
                                              texts,panel,panelParameters,
                                              help,exceptionInfo,dpeType);

    if (dynlen(exceptionInfo)) return;

}



void _fwConfigurationDB_alertObjectToRecipeObject(dyn_dyn_anytype alertObject,
        dyn_dyn_mixed &recipeObject,
        dyn_string &exceptionInfo)
{

    bool active; // if alert is active or not
    int type; // alert type, be it DPCONFIG_NONE, DPCONFIG_ALERT_BINARYSIGNAL, DPCONFIG_ALERT_NONBINARYSIGNAL
    dyn_float limits;
    dyn_string classes;
    dyn_string texts;
    string panel;
    dyn_string panelParameters;
    string help;
    string dpeName,dpe,dpeType;
    bool configExists=FALSE;

    // protection from the case when recipeObject is empty...
    if (dynlen(recipeObject)==0) _fwConfigurationDB_ClearRecipeObject(recipeObject);

    _fwAlertConfig_readDpeAlertConfigObject( alertObject,
            dpeName, type, active, limits, classes, texts,
            panel, panelParameters, help,
            exceptionInfo, dpeType);
    if (dynlen(exceptionInfo)) return;

    int idx=0;

    // for the LOGICAL hierarchy, we need to disentangle the name
    // see _fwConfigurationDB_recipeObjectToAlertObject()  above.
    //
    // in "dpeName" (taken from alertObject) we have dpe as in logical hierarchy,
    // and the "dpe" part in the recipeObject needs to be in the hardware hierarchy...
    string dpName, elementName;
    dyn_string splitDpeName=strsplit(dpeName,".");
    dpName=splitDpeName[1];
    elementName=substr(dpeName,strlen(dpName));

    for (int i=1;i<=dynlen(recipeObject[fwConfigurationDB_RO_DPE_NAME]);i++) {
        if ( (recipeObject[fwConfigurationDB_RO_DP_NAME][i]==dpName) &&
             (recipeObject[fwConfigurationDB_RO_ELEMENT_NAME][i]==elementName) ) {
		 idx=i;
		 break;
	}
    };

    if (idx<1) {
        fwException_raise(exceptionInfo,"ERROR","Data point element "+dpe+" not found in recipe",fwConfigurationDB_ERROR_DPENotInRecipe);
        return;
    };

    if (type!=DPCONFIG_NONE) configExists=TRUE;

    for (int i=fwConfigurationDB_RO_ALERT_MINIDX;i<=fwConfigurationDB_RO_ALERT_MAXIDX;i++) recipeObject[i][idx]="";

    recipeObject[fwConfigurationDB_RO_ALERT_TYPE][idx]=type;
    recipeObject[fwConfigurationDB_RO_HAS_ALERT][idx]=configExists;
    recipeObject[fwConfigurationDB_RO_ALERT_ACTIVE][idx]=active;

    recipeObject[fwConfigurationDB_RO_ALERT_TEXTS][idx]=texts;
    recipeObject[fwConfigurationDB_RO_ALERT_LIMITS][idx]=limits;
    recipeObject[fwConfigurationDB_RO_ALERT_CLASSES][idx]=classes;
}




/** Returns an empty recipe object.

This function creates (or clears) the variable passed as the argument,
and sets its structure appropriately, so all the columns are defined.

@arg recipeObject   the recipe object variable to be (re-)initialized.
*/
void _fwConfigurationDB_ClearRecipeObject(dyn_dyn_mixed &recipeObject)
{
    dynClear(recipeObject);
        dyn_mixed column;
    for (int i=1;i<=fwConfigurationDB_RO_MAXIDX;i++) {
        recipeObject[i]=column;
    };
    // and initialize the meta info as well;
    for (int i=fwConfigurationDB_RO_METAINFO_START;i<=fwConfigurationDB_RO_METAINFO_END;i++)
    {
	recipeObject[i]=column;
    }
}




string _fwConfigurationDB_getRecipeCacheDP(string recipeCache, dyn_string &exceptionInfo,
	bool create=FALSE)
{
    // handle recipe cache names with system names
    string system="";
    string recipe=recipeCache;
    dyn_string ds=strsplit(recipeCache,":");
    if (dynlen(ds)>1) {
	system=ds[1]+":";
	recipe=ds[2];
    }

    // verify that the remote system is available...
    if (system!="") {
	int sysid=getSystemId(system);
	if (sysid==-1) {
            fwException_raise(exceptionInfo,"ERROR","Remote recipe "+recipeCache+" not available: no such system "+system ,
            fwConfigurationDB_ERROR_NoRecipeCache);
            return "";
	}
    }

    string dpName=system+fwConfigurationDB_RecipeCacheDpPrefix+recipe;
    if (!dpExists(dpName)) {
        if (create) {
            return fwConfigurationDB_createRecipeCache(recipeCache, exceptionInfo);
        } else {
            fwException_raise(exceptionInfo,"ERROR","Recipe Cache "+recipeCache+" does not exist",fwConfigurationDB_ERROR_NoRecipeCache);
            return "";
        }
    }

    // check if the name is of appropriate type
    string dpType=dpTypeName(dpName);
    if (dpType!="_FwRecipeCache") {
        fwException_raise(exceptionInfo,"ERROR","Recipe Cache "+recipeCache+" does not exist, yet the datapoint with conflicting name "+dpName+" was found.",fwConfigurationDB_ERROR_NoRecipeCache);
        return "";
    };

    return  dpName;
}



/** Gets meta-information concerning the recipe cache
 */
void fwConfigurationDB_GetRecipeCacheMetaInfo(string recipeCache,
                                              string &recipeComment,
                                              int &numDevices,
                                              int &numValues,
                                              int &numAlerts,
                                              dyn_string &exceptionInfo)
{
    string dpName=_fwConfigurationDB_getRecipeCacheDP(recipeCache, exceptionInfo, FALSE);
    if (dynlen(exceptionInfo)) return;

    dyn_string devNames,values,alerts;

    dpGet(dpName+".RecipeComment",recipeComment,
          dpName+".DataPoints.DPNames",devNames,
          dpName+".Values.DPENames",values,
          dpName+".Alerts.DPENames",alerts);
    numDevices=dynlen(devNames);
    numValues=dynlen(values);
    numAlerts=dynlen(alerts);

}




void fwConfigurationDB_adoptRecipeObjectToSystem(dyn_dyn_mixed &recipeObject, string systemName, dyn_string &exceptionInfo)
{
if (systemName=="") systemName=getSystemName();

for (int i=1;i<=dynlen(recipeObject[1]);i++) {
    string newDpName,newName;

    // cut-away current system name:
    dyn_string sDpName=strsplit(recipeObject[fwConfigurationDB_RO_DPE_NAME][i],":");
    if (dynlen(sDpName)>1) {
	newDpName=systemName+sDpName[2];
    } else { // system name was not there...
	newDpName=systemName+sDpName[1];
    }
    recipeObject[fwConfigurationDB_RO_DPE_NAME][i]=newDpName;

    dyn_string sName=strsplit(recipeObject[fwConfigurationDB_RO_DP_NAME][i],":");
    if (dynlen(sName)>1) {
	newName=systemName+sName[2];
	recipeObject[fwConfigurationDB_RO_DP_NAME][i]=newName; // fix #42908
    } else { // system name was not there...
	//// it might have been LOGICAL hierarchy with common root...
	//// therefore we do not force it here:
	//newName=systemName+sName[1];
    }
};

}


/** Produces differential recipe

This function compares two recipeObject's and creates a recipe which
contains differences between them.
The differences are calculated in the (recipe2 - recipe1) manner, i.e.:
    @li the diffRecipe will contain all items that differ between recipe2 and recipe1. The values from recipe2 will be used
    @li the diffRecipe will contain all items that are present in recipe2 and not present in recipe1
    @li the diffRecipw will NOT contain the items that are present in recipe1 and not present in recipe2

@param recipeObject1 - first of the compared recipe objects
@param recipeObject2 - second of the compared recipe objects
@param diffRecipeObject - on return will contain the difference between the two recipes
@param exceptionInfo - standard exception handling variable.
@param hierarchyType - dummy now
@returns TRUE if recipes differ, FALSE if they are the same
*/
bool fwConfigurationDB_compareRecipes( dyn_dyn_mixed recipeObject1, dyn_dyn_mixed recipeObject2,
    dyn_dyn_mixed &diffRecipeObject, string hierarchyType, dyn_string &exceptionInfo)
{
    bool differ=FALSE;

//    if (hierarchyType==fwDevice_HARDWARE) {
//    } else if (hierarchyType==fwDevice_LOGICAL) {
//    } else {
//        fwException_raise(exceptionInfo, "ERROR","Hierarchy type "+hierarchyType+" not supported","");
//        return FALSE;
//    }

    if (dynlen(recipeObject1)==0) _fwConfigurationDB_ClearRecipeObject(recipeObject1);
    if (dynlen(recipeObject2)==0) _fwConfigurationDB_ClearRecipeObject(recipeObject2);
    _fwConfigurationDB_ClearRecipeObject(diffRecipeObject);

    int difflen=0;

    for (int i=1;i<=dynlen(recipeObject2[1]);i++) {

	//DebugN("comparing",recipeObject2[1][i]);
	// maybe we need some hierarchy-dependent treatment here...
	// such as  use "name+element" in place of dpe for LOGICAL
	// or maybe we need to strip system name?
	string dpeName=recipeObject2[fwConfigurationDB_RO_DPE_NAME][i];
	int idx=0;
	if (dpeName=="") {
	    // the case of logical node not mapped to any hardware.
	    // we need special treatment...

	    int idx1=dynContains(recipeObject1[fwConfigurationDB_RO_DP_NAME],recipeObject2[fwConfigurationDB_RO_DP_NAME][i]);
	    if (idx1) {
    		// "bad luck": element name exists somewhere - we need to locate it manually:
		for (int k=1;k<=dynlen(recipeObject1[1]);k++) {
		    if ( (recipeObject1[fwConfigurationDB_RO_DP_NAME][k]==recipeObject2[fwConfigurationDB_RO_DP_NAME][i]) &&
		         (recipeObject1[fwConfigurationDB_RO_ELEMENT_NAME][k]==recipeObject2[fwConfigurationDB_RO_ELEMENT_NAME][i]) ) {
			idx=k;
			continue;
		    }
		}
	    }

	} else {
	    idx=dynContains(recipeObject1[fwConfigurationDB_RO_DPE_NAME],dpeName);
	}

	if (idx<1) {
	    differ=TRUE;
	    difflen++;
	    //DebugN("diff: we need to copy from i="+i);
	    // means: it's not present... copy it to diffRecipeObject...
	    for (int j=1; j<=fwConfigurationDB_RO_MAXIDX;j++) {
		/*
		if (dynlen(recipeObject2)<j) {
		    DebugN("CAN'T COPY FROM "+i+","+j+"  DYNLEN(ro2) is",dynlen(recipeObject2));
		    continue;
		}
		if (dynlen(recipeObject2[j])<i) {
		    DebugN("CAN'T COPY FROM "+i+","+j+"  DYNLEN(ro2["+j+"]) is",dynlen(recipeObject2[j]));
		    continue;
		}
		if (dynlen(diffRecipeObject)<j) {
		    DebugN("CAN'T COPY TO "+i+","+j+"  DYNLEN(dro2) is",dynlen(diffRecipeObject));
		    continue;
		}
		*/
		diffRecipeObject[j][difflen]=recipeObject2[j][i];
	    }
	    continue;
	}
	// otherwise: item exists in both objects, we need to make deep comparison
	//
	// maybe we should alsodo some consistency checking on types, element names, etc...
	bool elementDiffers=FALSE;

	// compare "has a" parts...
	for (int k=fwConfigurationDB_RO_HAS_VALUE;k<=fwConfigurationDB_RO_HAS_ALERT;k++) {
	    if (recipeObject1[k][idx]!=recipeObject2[k][i]) {
	        differ=TRUE;
		difflen++;
		for (int j=1; j<=fwConfigurationDB_RO_MAXIDX;j++) { diffRecipeObject[j][difflen]=recipeObject2[j][i]; }
		elementDiffers=TRUE;
		break;
	    }
	}
	if (elementDiffers) continue;
	// now, check values, but only if they are present...
	if (recipeObject2[fwConfigurationDB_RO_HAS_VALUE][i]) {
	    if (recipeObject1[fwConfigurationDB_RO_VALUE][idx]!=recipeObject2[fwConfigurationDB_RO_VALUE][i]) {
	        differ=TRUE;
		difflen++;
		for (int j=1; j<=fwConfigurationDB_RO_MAXIDX;j++) { diffRecipeObject[j][difflen]=recipeObject2[j][i]; }
		continue;
	    }
	}

	// and check the alerts...
	if (recipeObject2[fwConfigurationDB_RO_HAS_ALERT][i]) {
	    for (int k=fwConfigurationDB_RO_ALERT_MINIDX;k<=fwConfigurationDB_RO_ALERT_MAXIDX;k++) {
		if (recipeObject1[k][idx]!=recipeObject2[k][i]) {
	    	    differ=TRUE;
		    difflen++;
		    for (int j=1; j<=fwConfigurationDB_RO_MAXIDX;j++) { diffRecipeObject[j][difflen]=recipeObject2[j][i]; }
		    elementDiffers=TRUE;
		    break;
		}
	    }
	}
	//if (elementDiffers) continue;

    } // end of loop over recipeObject2 elements...


    // fill the meta-info part of the diffRecipeObject
    // these will be the ones of the recipeObject2
    for (int i=fwConfigurationDB_RO_METAINFO_START;i<=fwConfigurationDB_RO_METAINFO_END;i++) {
	if (i>dynlen(recipeObject2)) break;
	dyn_mixed col=recipeObject2[i];
        diffRecipeObject[i]=col;
    }

    return differ;
}


void fwConfigurationDB_dropRecipeInDB(string recipeName, string hierarchyType, dyn_string &exceptionInfo)
{

    // extract the TAGID of the recipe...
    fwConfigurationDB_checkOpenDB(exceptionInfo);



    string sql="SELECT tagid FROM recipes where name=\'"+recipeName+"\'";
//    if (hierarchyType!="")
//    sql+="and hver="+g_fwConfigurationDB_DBHierarchyIDs[hierarchyType];
    dyn_dyn_mixed aRecords;

    _fwConfigurationDB_executeDBQuery(sql,g_fwConfigurationDB_DBConnection, aRecords, exceptionInfo,1,TRUE);
    if (dynlen(exceptionInfo)) return;
    if (dynlen(aRecords)<1) {
	fwException_raise(exceptionInfo,"ERROR","Cannot delete recipe "+recipeName+" - it does not exist","");
	return;
    }
    int tagid=aRecords[1][1];

    // drop the items that are not referenced by other recipes...
    string sql_sub="SELECT propid FROM recipe_tags "+
		    " WHERE tagid="+tagid+
		    " AND propid NOT IN (SELECT propid FROM recipe_tags WHERE tagid!="+tagid+")";

    sql = "DELETE FROM RECIPE_DATA WHERE PROPID IN ("+sql_sub+")";


    fwConfigurationDB_executeSqlSimple(sql, g_fwConfigurationDB_DBConnection, exceptionInfo);
    if (dynlen(exceptionInfo)) return;

    // now drop our references for the data referenced by the others
    sql= "DELETE FROM recipe_tags WHERE tagid="+tagid;
    fwConfigurationDB_executeSqlSimple(sql, g_fwConfigurationDB_DBConnection, exceptionInfo);
    if (dynlen(exceptionInfo)) return;


    // drop the item in RECIPES as well...
    sql= "DELETE FROM recipes WHERE tagid="+tagid;
    fwConfigurationDB_executeSqlSimple(sql, g_fwConfigurationDB_DBConnection, exceptionInfo);
    if (dynlen(exceptionInfo)) return;

    //drop the recipe versions that are not referenced by any recipe anymore...
    sql="delete from recipe_versions where rver not in (select rver from recipe_data group by rver)";
    fwConfigurationDB_executeSqlSimple(sql, g_fwConfigurationDB_DBConnection, exceptionInfo);
    if (dynlen(exceptionInfo)) return;

}



void fwConfigurationDB_dropRecipeInCache(string recipeName, string hierarchyType, dyn_string &exceptionInfo)
{

// note that hierarchyType is dummy here - we lookup through the name only. We only want to
// keep it for compatibility...


    string dpName=_fwConfigurationDB_getRecipeCacheDP(recipeName, exceptionInfo, FALSE);
    if (dynlen(exceptionInfo)) return;

    int rc=dpDelete(dpName);
    if (rc) {
	fwException_raise(exceptionInfo,"ERROR","Could not delete recipe cache: "+recipeName,"");
	return;
    }
}


void _fwConfigurationDB_setRecipeComment(dyn_dyn_mixed &recipeObject, string recipeComment, dyn_string &exceptionInfo)
{
    fwConfigurationDB_setRecipeMetaInfo(recipeObject, fwConfigurationDB_RO_META_COMMENT, recipeComment,exceptionInfo);
}

void _fwConfigurationDB_setRecipeOriginalName(dyn_dyn_mixed &recipeObject, string recipeName, dyn_string &exceptionInfo)
{
    fwConfigurationDB_setRecipeMetaInfo(recipeObject, fwConfigurationDB_RO_META_ORIGNAME, recipeName,exceptionInfo);
}

void _fwConfigurationDB_setRecipeOriginalRecipeType(dyn_dyn_mixed &recipeObject, string recipeType, dyn_string &exceptionInfo)
{
    fwConfigurationDB_setRecipeMetaInfo(recipeObject, fwConfigurationDB_RO_META_RECIPETYPE, recipeType,exceptionInfo);
}

void _fwConfigurationDB_setRecipeClass(dyn_dyn_mixed &recipeObject, string recipeClass, dyn_string &exceptionInfo)
{
    fwConfigurationDB_setRecipeMetaInfo(recipeObject, fwConfigurationDB_RO_META_CLASSNAME, recipeClass,exceptionInfo);
}

void _fwConfigurationDB_setRecipeAuthor(dyn_dyn_mixed &recipeObject, string recipeAuthor, dyn_string &exceptionInfo)
{
    fwConfigurationDB_setRecipeMetaInfo(recipeObject, fwConfigurationDB_RO_META_AUTHOR, recipeAuthor,exceptionInfo);
}

void _fwConfigurationDB_setRecipeCreationTime(dyn_dyn_mixed &recipeObject, time creationTime, dyn_string &exceptionInfo)
{
    fwConfigurationDB_setRecipeMetaInfo(recipeObject, fwConfigurationDB_RO_META_CREATIONTIME, creationTime,exceptionInfo);
}

void _fwConfigurationDB_setRecipeLastActivationTime(dyn_dyn_mixed &recipeObject, time lastActivationTime, dyn_string &exceptionInfo)
{
    fwConfigurationDB_setRecipeMetaInfo(recipeObject, fwConfigurationDB_RO_META_LASTACTIVATIONTIME, lastActivationTime,exceptionInfo);
}

void _fwConfigurationDB_setRecipeLastModificationTime(dyn_dyn_mixed &recipeObject, time lastModificationTime, dyn_string &exceptionInfo)
{
    fwConfigurationDB_setRecipeMetaInfo(recipeObject, fwConfigurationDB_RO_META_LASTMODIFICATIONTIME, lastModificationTime,exceptionInfo);
}

void _fwConfigurationDB_setRecipeLastActivationUser(dyn_dyn_mixed &recipeObject, string lastActivationUser, dyn_string &exceptionInfo)
{
    fwConfigurationDB_setRecipeMetaInfo(recipeObject, fwConfigurationDB_RO_META_LASTACTIVATIONUSER, lastActivationUser,exceptionInfo);
}

void _fwConfigurationDB_setRecipeLastModificationUser(dyn_dyn_mixed &recipeObject, string lastModificationUser, dyn_string &exceptionInfo)
{
    fwConfigurationDB_setRecipeMetaInfo(recipeObject, fwConfigurationDB_RO_META_LASTMODIFICATIONUSER, lastModificationUser,exceptionInfo);
}
void _fwConfigurationDB_setRecipePredefined(dyn_dyn_mixed &recipeObject, bool predefined, dyn_string &exceptionInfo)
{
    fwConfigurationDB_setRecipeMetaInfo(recipeObject, fwConfigurationDB_RO_META_PREDEFINED, predefined, exceptionInfo);
}
void _fwConfigurationDB_setRecipeVersionString(dyn_dyn_mixed &recipeObject, string recipeVersion, dyn_string &exceptionInfo)
{
    fwConfigurationDB_setRecipeMetaInfo(recipeObject, fwConfigurationDB_RO_META_RECIPEVERSION, recipeVersion, exceptionInfo);
}


int _fwConfigurationDB_getRecipeComment(dyn_dyn_mixed &recipeObject, string &recipeComment, dyn_string &exceptionInfo)
{
    return fwConfigurationDB_getRecipeMetaInfo(recipeObject, fwConfigurationDB_RO_META_COMMENT, recipeComment, exceptionInfo);
}

int _fwConfigurationDB_getRecipeOriginalName(dyn_dyn_mixed &recipeObject, string &recipeName, dyn_string &exceptionInfo)
{
    return fwConfigurationDB_getRecipeMetaInfo(recipeObject, fwConfigurationDB_RO_META_ORIGNAME, recipeName, exceptionInfo);
}

int _fwConfigurationDB_getRecipeOriginalRecipeType(dyn_dyn_mixed &recipeObject, string &recipeType, dyn_string &exceptionInfo)
{
    return fwConfigurationDB_getRecipeMetaInfo(recipeObject, fwConfigurationDB_RO_META_RECIPETYPE, recipeType, exceptionInfo);
}

//////
void _fwConfigurationDB_getRecipeClass(dyn_dyn_mixed &recipeObject, string &recipeClass, dyn_string &exceptionInfo)
{
    fwConfigurationDB_getRecipeMetaInfo(recipeObject, fwConfigurationDB_RO_META_CLASSNAME, recipeClass,exceptionInfo);
}

void _fwConfigurationDB_getRecipeAuthor(dyn_dyn_mixed &recipeObject, string &recipeAuthor, dyn_string &exceptionInfo)
{
    fwConfigurationDB_getRecipeMetaInfo(recipeObject, fwConfigurationDB_RO_META_AUTHOR, recipeAuthor,exceptionInfo);
}

void _fwConfigurationDB_getRecipeCreationTime(dyn_dyn_mixed &recipeObject, time &creationTime, dyn_string &exceptionInfo)
{
    fwConfigurationDB_getRecipeMetaInfo(recipeObject, fwConfigurationDB_RO_META_CREATIONTIME, creationTime,exceptionInfo);
}

void _fwConfigurationDB_getRecipeLastActivationTime(dyn_dyn_mixed &recipeObject, time &lastActivationTime, dyn_string &exceptionInfo)
{
    fwConfigurationDB_getRecipeMetaInfo(recipeObject, fwConfigurationDB_RO_META_LASTACTIVATIONTIME, lastActivationTime,exceptionInfo);
}

void _fwConfigurationDB_getRecipeLastModificationTime(dyn_dyn_mixed &recipeObject, time &lastModificationTime, dyn_string &exceptionInfo)
{
    fwConfigurationDB_getRecipeMetaInfo(recipeObject, fwConfigurationDB_RO_META_LASTMODIFICATIONTIME, lastModificationTime,exceptionInfo);
}

void _fwConfigurationDB_getRecipeLastActivationUser(dyn_dyn_mixed &recipeObject, string &lastActivationUser, dyn_string &exceptionInfo)
{
    fwConfigurationDB_getRecipeMetaInfo(recipeObject, fwConfigurationDB_RO_META_LASTACTIVATIONUSER, lastActivationUser,exceptionInfo);
}

void _fwConfigurationDB_getRecipeLastModificationUser(dyn_dyn_mixed &recipeObject, string &lastModificationUser, dyn_string &exceptionInfo)
{
    fwConfigurationDB_getRecipeMetaInfo(recipeObject, fwConfigurationDB_RO_META_LASTMODIFICATIONUSER, lastModificationUser,exceptionInfo);
}
void _fwConfigurationDB_getRecipePredefined(dyn_dyn_mixed &recipeObject, bool &predefined, dyn_string &exceptionInfo)
{
    fwConfigurationDB_getRecipeMetaInfo(recipeObject, fwConfigurationDB_RO_META_PREDEFINED, predefined, exceptionInfo);
}
void _fwConfigurationDB_getRecipeVersionString(dyn_dyn_mixed &recipeObject, string &recipeVersion, dyn_string &exceptionInfo)
{
    fwConfigurationDB_getRecipeMetaInfo(recipeObject, fwConfigurationDB_RO_META_RECIPEVERSION, recipeVersion, exceptionInfo);
}


/////
/**
    @retval 0 if recipe comment was present in the recipeObject
    @retval 1 if meta information was not present in the recipeObject
    @retval -1 if recipeObject structure was incorrect...
    @retval -2 if data idx was wrong
*/
int fwConfigurationDB_getRecipeMetaInfo(dyn_dyn_mixed &recipeObject, int idx, mixed &info, dyn_string &exceptionInfo)
{
    if ( (idx<fwConfigurationDB_RO_METAINFO_START) || (idx>fwConfigurationDB_RO_METAINFO_END)) {
	fwException_raise(exceptionInfo, "ERROR in getRecipeMetaInfo","Unknown data idx="+idx,"");;
	return -2;
    }

    info="";
    int ncols=dynlen(recipeObject);
    if (ncols<fwConfigurationDB_RO_MAXIDX) {
	fwException_raise(exceptionInfo, "ERROR in getRecipeMetaInfo","Wrong recipeObject passed","");
	return 0;
    }

    if (ncols<fwConfigurationDB_RO_METAINFO_END) return 1;

    if (dynlen(recipeObject[idx])>=1) {
	info=recipeObject[idx][1];
    } else {
	return 1;
    }
    return 0;
}

void fwConfigurationDB_setRecipeMetaInfo(dyn_dyn_mixed &recipeObject, int idx, string info, dyn_string &exceptionInfo)
{
    if ( (idx<fwConfigurationDB_RO_METAINFO_START) || (idx>fwConfigurationDB_RO_METAINFO_END)) {
	fwException_raise(exceptionInfo, "ERROR in setRecipeMetaInfo","Unknown data idx="+idx,"");;
	return;
    }
    int ncols=dynlen(recipeObject);
    if (ncols<fwConfigurationDB_RO_MAXIDX) {
	fwException_raise(exceptionInfo, "ERROR in setRecipeMetaInfo","Wrong recipeObject passed","");
	return;
    }

    recipeObject[idx][1]=info;
}

/** Create an ad-hoc recipeObject based on list of device elements and their settings

    @ingroup RecipeFunctions


    @param[in] deviceElements: list of device elements. The devices may come either from
	the hardware or from logical view. Each device name should be followed by element name.
	For instance: dist_1:CAEN/crate1/board00/channel000.settings.v0 (for HARDWARE: it
	is simply the full data point element name),
	or MyDetector/ECAL/HV/straw0.settings.i0 (for LOGICAL: it is the device's LOGICAL
	name followed by the element name, and the element name starts with "." character).
    @param[in] list containing settings for corresponding devices in the @c deviceElements list.
	If empty list is passed, these will be snapshotted from the current online values
	for corresponding dpes
    @param[out] recipeObject will be filled with the recipe object created from provided input
    @param[out] exceptionInfo standard exception handling object
    @param[in] checkExists (optional), if set to TRUE, the list of device elements will be
	checked to see if all of the specified device elements exist. Should be set to FALSE
	if a recipeObject is to be created with settings for devices that do not exist yet.
	Note that without checkExists=TRUE, the recipeObject will have limited usability,
	namely it cannot be stored to cache or applied to system!

*/
void fwConfigurationDB_makeRecipe(dyn_string deviceElements, dyn_mixed settings,
    dyn_dyn_mixed &recipeObject, dyn_string &exceptionInfo, bool checkExists=TRUE)
{
    _fwConfigurationDB_ClearRecipeObject(recipeObject);

    if (dynlen(deviceElements)==0) return;

    bool snapshotSettings=false;
    if (dynlen(settings)==0) snapshotSettings=true;
    
    if (snapshotSettings) checkExists=TRUE;

    if ( (!snapshotSettings) && (dynlen(deviceElements)!=dynlen(settings))) {
	fwException_raise(exceptionInfo,"ERROR in fwConfigurationDB_makeRecipe",
	    "The length of deviceElements ("+dynlen(deviceElements)+
	    ") and settings ("+dynlen(settings)+")  do not match","");
	return;
    }


    for (int i=1;i<=dynlen(deviceElements);i++) {
	string dpe,sys, dev, element, hierarchy;
	dpe=deviceElements[i];

	// extract system name, guess the hierarchy
	dyn_string ds=strsplit(dpe,":");
	if (dynlen(ds)<=1) {
	    // this is probably a logical device - it does not contain the system name...
	    sys="";
	    dpe=ds[1];
	    hierarchy=fwDevice_LOGICAL;
	} else {
	    sys=ds[1]+":";
	    dpe=ds[2];
	    hierarchy=fwDevice_HARDWARE;
	}

	// separate device name from element name
	ds=strsplit(dpe,".");
	dev=sys+ds[1];
	// reconstruct element name
	for (int j=2;j<=dynlen(ds);j++) element+="."+ds[j];
	if (element=="") element=".";

	// remove repeated entries: the latest take precedence
	// for that we will find out the index where we place the data
	int idx=dynContains(recipeObject[fwConfigurationDB_RO_DPE_NAME],deviceElements[i]);
	if (idx<1) idx=dynlen(recipeObject[fwConfigurationDB_RO_DPE_NAME])+1;


	// if we snapshot the settings, we will complete it in the "checkExists" block below...
	int dataType=0;
	if (!snapshotSettings) {
	    dataType=_fwConfigurationDB_typeIdToDpeTypeId(getType(settings[i]));
	    if (dataType==0) {
		fwException_raise(exceptionInfo,"Error in fwConfigurationDB_makeRecipe",
		    "Cannot convert data type for deviceElements[i]","");
		    return;
	    }
	}

	recipeObject[fwConfigurationDB_RO_DPE_NAME][idx]=deviceElements[i];
	recipeObject[fwConfigurationDB_RO_DP_NAME][idx]=dev;
	recipeObject[fwConfigurationDB_RO_DP_TYPE][idx]="";
	recipeObject[fwConfigurationDB_RO_ELEMENT_NAME][idx]=element;
	recipeObject[fwConfigurationDB_RO_ELEMENT_TYPE][idx]=dataType;
	recipeObject[fwConfigurationDB_RO_HIERARCHY][idx]=hierarchy;
	recipeObject[fwConfigurationDB_RO_HAS_VALUE][idx]=true;
	recipeObject[fwConfigurationDB_RO_HAS_ALERT][idx]=false;
	// cast the value to its string representation

	string sval;
	if (!snapshotSettings) {
	    _fwConfigurationDB_dataToString(settings[i], dataType, "|", sval, exceptionInfo);
	    if (dynlen(exceptionInfo)) return;
	}
	recipeObject[fwConfigurationDB_RO_VALUE][idx]=sval;

	// pad the alerts part with dummy data...
	mixed dummy;

	for (int j=fwConfigurationDB_RO_ALERT_MINIDX; j<=fwConfigurationDB_RO_MAXIDX;j++) recipeObject[j][idx]=dummy;
    }

    mixed dummy;
    for (int i=fwConfigurationDB_RO_METAINFO_START;i<=fwConfigurationDB_RO_METAINFO_END;i++) recipeObject[i][1]=dummy;


    // we enhance the data now, based on what our systems know...

    if (checkExists) {
	// we extract all aliases from all systems
	dyn_string allDps, allAliases;
	dpGetAllAliases (allDps, allAliases,"*","*:*.**" );
	for (int i=1;i<=dynlen(recipeObject[fwConfigurationDB_RO_DPE_NAME]);i++) {
	    string dev=recipeObject[fwConfigurationDB_RO_DP_NAME][i];

	    if (recipeObject[fwConfigurationDB_RO_HIERARCHY][i]==fwDevice_LOGICAL) {
		int idx=dynContains(allAliases,dev);

		if (idx<1) {
		    // maybe it's not yet a disaster... the user might have forgotten
		    // to put system name in the device. let's check it
		    if (dpExists(dev)) {
			// ok. let's fix the hierarchy and proceed further down
			recipeObject[fwConfigurationDB_RO_HIERARCHY][i]=fwDevice_HARDWARE;
			dev=dpSubStr(dev,DPSUB_SYS_DP);
			recipeObject[fwConfigurationDB_RO_DP_NAME][i]=dev;
			recipeObject[fwConfigurationDB_RO_DPE_NAME][i]=dev+recipeObject[fwConfigurationDB_RO_ELEMENT_NAME][i];
		    } else {
			fwException_raise(exceptionInfo,"ERROR in fwConfigurationDB_makeRecipe",
			"Device (alias) does not exist: "+dev,"");
			return;
		    }

		} else {
		    // OK. It is a valid alias
		    // reconstruct the dpe so that it contains datapoint name now!
		    dev=dpSubStr(allDps[idx],DPSUB_SYS_DP);
		}
	    }


    	    if (recipeObject[fwConfigurationDB_RO_HIERARCHY][i]==fwDevice_HARDWARE) {

		if (!dpExists(dev)) {
		    fwException_raise(exceptionInfo,"ERROR in fwConfigurationDB_makeRecipe",
		    "Device does not exist: "+dev,"");
		    return;
		}
	    }

	    // fix the dpType info
	    recipeObject[fwConfigurationDB_RO_DP_TYPE][i]=dpTypeName(dev);

	    // reconstruct the dpe so that it contains datapoint name now, and not an alias or anything...
	    string dpe=dev+recipeObject[fwConfigurationDB_RO_ELEMENT_NAME][i];
	    recipeObject[fwConfigurationDB_RO_DPE_NAME][i]=dpe;

	    // now check if element exists, and fill in the element type info...
	    int elType=dpElementType(dpe);
	    if (elType<1) {
		fwException_raise(exceptionInfo,"ERROR in fwConfigurationDB_makeRecipe",
		    "Device element invalid: "+
			recipeObject[fwConfigurationDB_RO_DP_NAME][i]+recipeObject[fwConfigurationDB_RO_ELEMENT_NAME][i],
		    "");
		return;
	    }
	    recipeObject[fwConfigurationDB_RO_ELEMENT_TYPE][i]=elType;


	}
	// now if we need, we will get the values
	if (snapshotSettings) {
DebugTN("IMPLEMENT ME: OPTIMIZE THE SINGLE DPGET IN THE MAKERECIPE CALL!!!");	
	    dyn_mixed vals;
	    dpGet(recipeObject[fwConfigurationDB_RO_DPE_NAME],vals);
	    settings=vals;
	}
	
	// and now we loop once again to cast the values correctly
	for (int i=1;i<=dynlen(recipeObject[fwConfigurationDB_RO_DPE_NAME]);i++) {
	    int elType=recipeObject[fwConfigurationDB_RO_ELEMENT_TYPE][i];
	    string dpe=recipeObject[fwConfigurationDB_RO_DPE_NAME][i];
	    // we know the exact element type, so we could actually cast the data correctly now
	    // let's overwrite it...
	    string sval;
	    _fwConfigurationDB_dataToString(settings[i],elType, "|", sval, exceptionInfo);
	    if (dynlen(exceptionInfo)) return;
	    recipeObject[fwConfigurationDB_RO_VALUE][i]=sval;
	
	}
    }
}

/** Extracts value(s) from a recipe

The function extracts a value ("setting") from an exising recipe, for a set of dp-elements.

@param[in] recipeObject		contains the recipe data, from which the values are to be extracted
@param[in,out] deviceElements	on entry, it should contain the list of dp-elements for which the values are queried; note that
				these deviceElemets may contain wildcard characters, so that, for instance, all elements for
				a device could be specified, without actually naming them explicitely, or a list of devices matching
				some naming convention may be specified. Note that if element is not specified (i.e. only
				the dp name is passed, not followed by a dot and the element name, all elements for matching
				device will be returned as well.<br/>
				on exit, the original contents will be replaced by the expanded list of identified data point elements,
				for which the corresponding settings will be stored in the @c settings parameter.
@param[out] settings		on return i'th row will contain the settings (values) for i'th deviceElement of @c deviceElements
@param[in]  exceptionInfo 	standard exception handling variable

@b Example: extract all settings for a device with alias "myDevice",
that are stored in a @c recipeObject. Note that alias "myDevice" is
not resolved to hardware name, but kept as is in the name (unlike when
reading directly from the recipeObject's column  fwConfigurationDB_RO_DPE_NAME)
@code
  dyn_string deviceElements=makeDynString("myDevice.*");
  dyn_string exceptionInfo;
  dyn_mixed  values;
  fwConfigurationDB_extractSettingFromRecipe(deviceElements, values, exceptionInfo);

  // on return one would get a data such as
  // deviceElements[1]="myDevice.settings.v0";     settings[1]=10.0;
  // deviceElements[2]="myDevice.settings.i0";     settings[2]=20.0;
  // deviceElements[3]="myDevice.commands.OnOff";  settings[3]=30.0;
@endcode

@b Example: extract the voltages for all channels in board01 and board13 of crate1
and board05 of crate2. Note the use of wildcard characters: "*" replacing any
part of name, "?" replacing one character, and "[,]" specifying a set of values.
@code
  dyn_string deviceElements;
  dyn_string exceptionInfo;
  dyn_mixed  values;

  deviceElements[1] = "dist_1:CAEN/crate1/board[01,13]/channel*.settings.v?";
  deviceElements[2] = "dist_1:CAEN/crate2/board05/channel*.settings.v?";

  fwConfigurationDB_extractSettingFromRecipe(deviceElements, values, exceptionInfo);

  // on return one would get a data such as
  // deviceElements[1]  = "dist_1:CAEN/crate1/board01/channel001.settings.v0";     settings[1]  =10.0;
  // deviceElements[2]  = "dist_1:CAEN/crate1/board01/channel001.settings.v0";     settings[2]  =20.0;
  // deviceElements[3]  = "dist_1:CAEN/crate1/board01/channel002.settings.v0";     settings[3]  =10.0;
  // deviceElements[4]  = "dist_1:CAEN/crate1/board01/channel002.settings.v0";     settings[4]  =20.0;
  // ...
  // deviceElements[n-1]= "dist_1:CAEN/crate1/board13/channel005.settings.v0";     settings[n-1]=90.0;
  // deviceElements[n]  = "dist_1:CAEN/crate1/board13/channel006.settings.v0";     settings[n]  =90.0;
  // ...
  // deviceElements[k-1]= "dist_1:CAEN/crate2/board05/channel005.settings.v0";     settings[k-1]=90.0;
  // deviceElements[k]  = "dist_1:CAEN/crate2/board05/channel006.settings.v0";     settings[k]  =99.0;
  // ... etc
@endcode


*/
void fwConfigurationDB_extractSettingFromRecipe(dyn_dyn_mixed recipeObject, dyn_string &deviceElements,
		dyn_mixed &values, dyn_mixed &exceptionInfo)
{
    if (dynlen(recipeObject)<1) {
	fwException_raise(exceptionInfo,"ERROR in fwConfigurationDB_extractSettingFromRecipe","Recipe is empty","");
	return;
    }

    dyn_string dpes;
    dynClear(values);

    // reconstruct dpe name
    // we do not use the fwConfigurationDB_RO_DPE_NAME column, because it always points to
    // hardware device, whereas we want to be able to serve aliases as well
    dyn_string dpeNames;
    for (int i=1;i<=dynlen(recipeObject[fwConfigurationDB_RO_DPE_NAME]);i++) {
	dpeNames[i]=recipeObject[fwConfigurationDB_RO_DP_NAME][i]+""+recipeObject[fwConfigurationDB_RO_ELEMENT_NAME][i];
    }
    for (int i=1;i<=dynlen(deviceElements);i++) {
	string deviceFilter="";
	string elementFilter="";
	// separate element name and device name;
	dyn_string ds=strsplit(deviceElements[i],".");
	deviceFilter=ds[1];
	elementFilter=substr(deviceElements[i],strlen(deviceFilter));
	string filter=deviceFilter+elementFilter;
	if (elementFilter=="") {
	    elementFilter=".*";
	    filter=deviceFilter+elementFilter;
	    deviceElements[i]=filter;
	}
	if ( strpos(filter,"*")==-1 && strpos(filter,"?")==-1 && strpos(filter,"[")==-1) {
//	DebugN("processing non-wildcard",filter);
	    // no wildcard - go on and try to match
	    int idx=dynContains(dpeNames,filter);
	    if (idx>0 && recipeObject[fwConfigurationDB_RO_HAS_VALUE][idx]==1 && dynContains(dpes,filter)<1 ) {
		mixed value;
		_fwConfigurationDB_stringToData(recipeObject[fwConfigurationDB_RO_VALUE][idx],
		recipeObject[fwConfigurationDB_RO_ELEMENT_TYPE][idx],"|",value,exceptionInfo);
		if (dynlen(exceptionInfo)) return;
		dynAppend(dpes,filter);
		dynAppend(values,value);

	    }
	} else {
//	    DebugN("processing wildcard",filter);

	    // this one contains a pattern
	    dyn_string foundDpes=dynPatternMatch(filter,dpeNames);
	    if (dynlen(foundDpes)) {
		// we need to iterate through the recipeObject to identify them
		for (int j=1;j<=dynlen(dpeNames);j++) {
		    if (patternMatch(filter,dpeNames[j])) {
			if (!dynContains(dpes,dpeNames[j]) && recipeObject[fwConfigurationDB_RO_HAS_VALUE][j]==1){
			    mixed value;
			    _fwConfigurationDB_stringToData(recipeObject[fwConfigurationDB_RO_VALUE][j],
				recipeObject[fwConfigurationDB_RO_ELEMENT_TYPE][j],"|",value,exceptionInfo);
			    if (dynlen(exceptionInfo)) return;
			    dynAppend(dpes,dpeNames[j]);
			    dynAppend(values,value);
			}
		    }
		}
	    }

	}
    }

    deviceElements=dpes;

}










/**
	Returns the DPName of a DP that holds the recipe class definition, checks if it exists,
	and checks if remote system is available as well

	@param className [IN] the name of the recipe class; could be specified as a recipe class
                         in a remote system, by prefixing the name of the class with system name and colon,
                         e.g. "RemoteSys1:MyRecipeClass"
        @param exists [IN,OUT] defined how the check/handling for non-existing recipe classes is handled.
                       when TRUE on input and the recipe class does not exist, an error is dropped into exceptionInfo
                       when FALSE on input, then no error is generated; in any case, on return the variable will tell
                       whether recipe class exists or not.
        @param exceptionInfo [OUT] standard exception handling variables
        @returns the name of the datapoint.
*/
string _fwConfigurationDB_getRecipeClassDP(string className, bool &exists, dyn_string &exceptionInfo)
{
    dynClear(exceptionInfo);
    exists=false;
    bool errOnNonExistent=exists;

    // eliminate illegal names (special characters in the name...
    if (!dpIsLegalName(className)) {
        fwException_raise(exceptionInfo,"ERROR","The name for the recipe class is invalid","");
        return "";
    }

    // handle recipe class names with system names
    string system="";
    string recipeClass=className;
    int sysid=getSystemId();
    dyn_string ds=strsplit(className,":");
    if (dynlen(ds)>1) {
	system=ds[1]+":";
	recipeClass=ds[2];
    }

    // verify that the remote system is available...
    if (system!="") {
	sysid=getSystemId(system);
	if (sysid==-1) {
            fwException_raise(exceptionInfo,"ERROR",
        	"Cannot get remote recipe class "+className+" - no such system "+system ,"");
            return "";
	}
    }

    string classDp=system+fwConfigurationDB_RecipeClassDpPrefix+className;

    exists=dpExists(classDp);
    if (errOnNonExistent) {
	fwException_raise(exceptionInfo,"ERROR","Unknown recipe class "+className);
	DebugTN("ERROR in _fwConfigurationDB_getRecipeClassDP", "Cannot find recipe class "+className+ " - dp does not exist",classDp);
	return;
    }

    return classDp;
}






/** 
 * Creates a new recipe class.
 * @param recipeClass - [IN] Name of the new recipe class.(could be remote!)
 * @param recipeType - [IN] Name of the recipe type used by the new recipe class.
 * @param description - [IN] Comment for the new recipe class.
 * @param editable - [IN] "editable" flag for the new recipe class
 * @param elements - [IN] the list of device elements or devices (hardware, logical)
 * @param exceptionInfo - [OUT] Standard exception handling variable.
 */
void fwConfigurationDB_createRecipeClass(string recipeClass, string recipeType, 
                                         string description, bool editable, 
                                         dyn_string elements, dyn_string &exceptionInfo)
{
	bool exists=FALSE; // ON INPUT: we do not want an exception for not existing 
	string classDp=_fwConfigurationDB_getRecipeClassDP(recipeClass, exists, exceptionInfo);
	if (dynlen(exceptionInfo)) return;
	if (exists) {
		fwException_raise(exceptionInfo,"ERROR","Cannot create recipe class "+recipeClass+" - it already exists","");
		DebugTN("ERROR in fwConfigurationDB_createRecipeClass", "Cannot create recipe class "+recipeClass+ " - dp already exist",classDp);
		return;
	}

    // Check if requested recipe type exists
    string recTypeDp=fwConfigurationDB_RecipeTypeDpPrefix+recipeType;
    if (!dpExists(recTypeDp)){
      fwException_raise(exceptionInfo,"ERROR","The recipe type: "+recipeType+" doesn't exist.","");
      DebugTN("ERROR in fwConfigurationDB_createRecipeClass","The recipe type: "+recipeType+" doesn't exist.",recTypeDp);
      return;      
    }
    
    int rc = dpCreate(classDp,"_FwRecipeClass");
    if (rc) {
        fwException_raise(exceptionInfo,"ERROR","Could not create recipe class "+recipeClass,"");
	DebugTN("ERROR in fwConfigurationDB_createRecipeClass","Could not create recipe class "+recipeClass,classDp,getLastError());
        return;
    }

    rc= dpSetWait(classDp+".Editable",editable,
              classDp+".LastModificationUser",getUserName(),
              classDp+".LastModificationTime",getCurrentTime());

    if (rc) {
        fwException_raise(exceptionInfo,"ERROR","Could not set up recipe class "+recipeClass,"");
	DebugTN("ERROR in fwConfigurationDB_createRecipeClass","Could not set up recipe class "+recipeClass,classDp,getLastError());
        return;
    }

    // now do the expanding of devices, etc properly and set this all up...
    fwConfigurationDB_modifyRecipeClass(recipeClass, elements,  recipeType, description, exceptionInfo,FALSE);
}


/** 
 * Deletes a recipe class
 * @param recipeClass - [IN] Name of the recipe class to be deleted.
 * @param deleteRecipes - [IN] If set to TRUE, all the recipes (instances) belonging to this class 
 *                        will also be deleted from recipe caches; deleting from the DB needs to be
 *                        done separately!
 * @param exceptionInfo - [OUT] Standard exception handling variable.
 */ 
void fwConfigurationDB_deleteRecipeClass(string recipeClass, bool deleteRecipes, dyn_string &exceptionInfo) 
{
	bool exists=TRUE; // ON INPUT: we want an exception for not existing 
	string classDp=_fwConfigurationDB_getRecipeClassDP(recipeClass, exists, exceptionInfo);
	if (dynlen(exceptionInfo)) return;

	bool isEditable;
	dpGet(classDp+".Editable",isEditable);
	if (!isEditable) {
           fwException_raise(exceptionInfo,"ERROR","Deleting recipe class "+recipeClass+" is not allowed","");
           return;    
	}

	if (deleteRecipes) {
	   dyn_string recipes;
           int rc=dpGet(classDp+".Recipes",recipes);
	   if (rc) {
           	fwException_raise(exceptionInfo,"ERROR","Cannot get the list of instances while deleting recipe class "+recipeClass,"");
	   	DebugTN("ERROR in fwConfigurationDB_deleteRecipeClass","Cannot get the list of instances while deleting recipe class "+recipeClass,classDp+".Recipes",getLastError());
		// no return! we want to proceed 
	   }
	   for (int i=1;i<=dynlen(recipes);i++) {
		fwConfigurationDB_dropRecipeInCache(recipes[i],"",exceptionInfo);
                // no return! we want to process them all
	   }
	}

	int rc=dpDelete(classDp);
	if (rc) {
           fwException_raise(exceptionInfo,"ERROR","Could not delete recipe class "+recipeClass,"");
	   DebugTN("ERROR in fwConfigurationDB_deleteRecipeClass","Could not delete recipe class "+recipeClass,classDp,getLastError());
           return;
    }
}

/** Creates a new instance of recipe class, with current only values and saves it in a cache

    Note that the recipe cache that is created will be of form RecipeClass/RecipeName

    @param recipeName the name for the new recipe instance; may be prepended by system name and colon
                      to create the instance on the remote system (e.g. dist_2:MyRecipe)
    @param className the name of recipe class
    @param exceptionInfo standard exception handling variable
*/
void fwConfigurationDB_instantiateRecipeOfClass(string recipeName, string className, dyn_string &exceptionInfo)
{
    bool exists=TRUE; // ON INPUT: we want an exception for not existing 
    string classDp=_fwConfigurationDB_getRecipeClassDP(className, exists, exceptionInfo);
    if (dynlen(exceptionInfo)) return;

    string recipeDp;

    // treat a case of recipe on a remote system;
    dyn_string ds=strsplit(recipeName,":");
    if (dynlen(ds)>1) {
	recipeDp=ds[1]+":"+fwConfigurationDB_RecipeCacheDpPrefix+className+"/"+ds[2];
	recipeName=ds[1]+":"+recipeClass+"/"+ds[2];
    } else {
	recipeName=className+"/"+recipeName;
	recipeDp=fwConfigurationDB_RecipeCacheDpPrefix+recipeName;
    }

    if (dpExists(recipeDp)) {
	fwException_raise(exceptionInfo,"ERROR","Recipe already exists: "+recipeName,"");
	return;
    }
    

    dyn_string elements,recipes;
    dpGet(classDp+".Elements",elements,
          classDp+".Recipes",recipes);

    time t0=getCurrentTime();

    dyn_dyn_mixed recipeObject;
    fwConfigurationDB_makeRecipe(elements, makeDynMixed(), recipeObject, exceptionInfo);
    if (dynlen(exceptionInfo)) return;

    recipeObject[fwConfigurationDB_RO_META_CREATIONTIME]=t0;
    recipeObject[fwConfigurationDB_RO_META_AUTHOR]=getUserName();
    recipeObject[fwConfigurationDB_RO_META_CLASSNAME]=className;
    //recipeObject[fwConfigurationDB_RO_META_PREDEFINED]=isPredefined;
    
    fwConfigurationDB_createRecipeCache(recipeName, exceptionInfo);
    if (dynlen(exceptionInfo)) return;

    
    fwConfigurationDB_saveRecipeToCache (recipeObject, "", recipeName,  exceptionInfo);
    if (dynlen(exceptionInfo)) return;
    
    dynAppend(recipes,recipeName);
    dpSetWait(classDp+".Recipes",recipes);
}

/** Deletes an instance of recipe class
*/
void fwConfigurationDB_deleteRecipeOfClass(string recipeName, string className, dyn_string &exceptionInfo)
{
    bool exists=TRUE; // ON INPUT: we want an exception for not existing 
    string classDp=_fwConfigurationDB_getRecipeClassDP(className, exists, exceptionInfo);
    if (dynlen(exceptionInfo)) return;

    dyn_string recipes;
    dpGet(classDp+".Recipes",recipes);

    string recipeDp=fwConfigurationDB_RecipeCacheDpPrefix+className+"/"+recipeName;

    // treat a case of recipe on a remote system;
    dyn_string ds=strsplit(recipeName,":");
    if (dynlen(ds)>1) {
	recipeDp=ds[1]+":"+fwConfigurationDB_RecipeCacheDpPrefix+className+"/"+ds[2];
	recipeName=ds[1]+":"+className+"/"+ds[2];
    } else {
	recipeName=className+"/"+recipeName;
    }
    if (!dpExists(recipeDp)) {
	fwException_raise(exceptionInfo,"ERROR","Cannot delete recipe instance: "+recipeName+" - it does not exist","");
	return;
    }
    
    int idx=dynContains(recipes,recipeName);
    if (idx<1) {
	fwException_raise(exceptionInfo,"ERROR","Cannot delete recipe instance: "+recipeName+" - it is not in the list of instances of the class","");
	DebugTN("ERROR","Cannot delete recipe instance: "+recipeName+" - it is not in the list of instances of the class",recipeName,recipes);
	return;
    }

    fwConfigurationDB_dropRecipeInCache(recipeName, "", exceptionInfo);
    if (dynlen(exceptionInfo)) return;

    dynRemove(recipes,idx);
    dpSetWait(classDp+".Recipes",recipes);
    
}



/**
 * Gets the list of instances of a recipe class.
 * @param recipeClass - [IN] Recipe class name.
 * @param scanAll - [IN], if set to TRUE, the function will scan all the recipe caches (on the local system)
 *                  to see if their "recipe class" match, and return the available ones;
 *                  otherwise it will return the "official" list that is declared in the recipeClass
 * @param exceptionInfo - [OUT] Standard exception handling variable.
 * @returns List containing the name of the recipe class instances.
 */
dyn_string fwConfigurationDB_getRecipeClassInstances(string recipeClass, bool scanAll, dyn_string &exceptionInfo)
{
	bool exists=TRUE; // ON INPUT: we want an exception for not existing 
	string classDp=_fwConfigurationDB_getRecipeClassDP(recipeClass, exists, exceptionInfo);
	if (dynlen(exceptionInfo)) return;

	dyn_string recipes;

	if (scanAll) {
	    fwConfigurationDB_findRecipesInCache(recipes,exceptionInfo,"*","*","*","*","*",recipeClass);
	    if (dynlen(exceptionInfo)) return makeDynString();
	} else {
	   int rc=dpGet(classDp+".Recipes",recipes);
	   if (rc) {
           	fwException_raise(exceptionInfo,"ERROR","Cannot get the list of instances of recipe class "+recipeClass,"");
	   	DebugTN("ERROR in fwConfigurationDB_getRecipeClassInstances","Cannot get the list of instances of recipe class "+recipeClass,classDp+".Recipes",getLastError());
		return makeDynString();
	   }
	}

	return recipes;
}



/** 
 * Gets the list of recipe classes and their comments.
 * @param recipeClassNames - [OUT] List containing the recipe class names.
 * @param recipeClassComments - [OUT] List containing the recipe class comments.
 * @param exceptionInfo - [OUT] Standard exception handling variable.
 * @param systemName - [IN] System name where to look for the recipe classes. By default
 *                     it will look in the local system; passing "*:" as the argument will
 *                     cause a lookup in all the systems.
 */ 
void fwConfigurationDB_getRecipeClasses(dyn_string &recipeClassNames, dyn_string &recipeClassComments,
                                      dyn_string &exceptionInfo, string systemName="")
{
    dynClear(recipeClassNames);
    dynClear(recipeClassComments);

    if (systemName!="") {
	// make sure that we have the trailing ":" at the end of system name
	strrtrim(systemName,":");
	systemName+=":";
    }

    if (systemName!="" && systemName!="*:") {
        int sysid=getSystemId(systemName);
        if (sysid==-1) {
    	     fwException_raise(exceptionInfo,"ERROR", "Cannot get remote recipe classes: invalid system name: "+systemName , "");
    	     return ;
        }
    }

    dyn_string recipeClassDps=dpNames(systemName+fwConfigurationDB_RecipeClassDpPrefix+"*","_FwRecipeClass");
    dynSortAsc(recipeClassDps);
    for (int i=1;i<=dynlen(recipeClassDps);i++) {
        string rcSysName=dpSubStr(recipeClassDps[i],DPSUB_SYS);
        string rcName=dpSubStr(recipeClassDps[i],DPSUB_DP);
        rcName=substr(rcName,strlen(fwConfigurationDB_RecipeClassDpPrefix));
        if (systemName!="") rcName=rcSysName+rcName;
        string rcComment;
        int rc = dpGet(recipeClassDps[i]+".Description",rcComment);
        if (rc) {
            fwException_raise(exceptionInfo,"ERROR","Could not get description for recipe class: "+rcName,"");
            return;
        }
        dynAppend(recipeClassNames,rcName);
        dynAppend(recipeClassComments,rcComment);
    }

}

/** Modify recipe class

    This functions modifies the recipe class: based on the list of devices and recipe type,
    it re-calculates the list of dp elements, and does some sanity checks.

   @param recipeClass the name of the class
   @param newDeviceList the list of devices; their types are checked for compatibility with recipeType;
           note that a mixture of LOGICAL ("alias") and HARDWARE ("datapoints") may be specified;
           note also that you could specify device elements (rather than devices); in such case they
           are not checked against recipeType, and they are only checked if they exist;
           for instance one may pass: makeDynString("PUMP1","dist_1:Pumps/PumpAAA0002","ENGINE.settings.speed");
           which contains a LOGICAL device name, then a hardware device name, then a complete device element
           (with device being specified through alias); for the first two, the expansion of devices to elements
           according to recipe type will be performed.
   @param newRecipeType the new recipe type; empty string means keep the existing recipe type
   @param newDescription the new description text
   @param exceptionInfo standard exception handling variable
   @param updateInstances (optional, default TRUE) - update all the instances of the recipes of this class,
	    so that they have an up-to-date list of elements.

*/
void fwConfigurationDB_modifyRecipeClass(string recipeClass, dyn_string newDeviceList,  string newRecipeType,
                                         string newDescription, dyn_string &exceptionInfo, bool updateInstances=TRUE)
{

    dyn_mixed rclInfo;
    fwConfigurationDB_getRecipeClassInfo(recipeClass, rclInfo, exceptionInfo);
    if (dynlen(exceptionInfo)) return;

    if (newRecipeType=="") newRecipeType=rclInfo[fwConfigurationDB_RCL_RECIPETYPE];

    
    dyn_dyn_string recipeTypeData;
    _fwConfigurationDB_getRecipeTypeData(newRecipeType,recipeTypeData,exceptionInfo);
    if (dynlen(exceptionInfo)) {
	// append our part
	fwException_raise(exceptionInfo,"ERROR","Cannot get recipe type data while modifying recipe class "+recipeClass);
	return;
    }
    // convert the recipeTypeData to useful form: mapping with keys being DPTypes 
    // and values being list of elements that are to be stored
    mapping rtElements;
    fwConfigurationDB_getRecipeTypeDataMapping(newRecipeType, rtElements, exceptionInfo);
    if (dynlen(exceptionInfo)) return;

    dynSortAsc(newDeviceList);
    dyn_string elements;    
    // verify the new device list, and expand it according to the recipeType where needed
    for (int i=1;i<=dynlen(newDeviceList);i++) {
	string devName=newDeviceList[i];	
	string elemName=""; 
	int dotidx=strpos(devName,".");
	if (dotidx>0) {
	    // this is a device element!
	    elemName=substr(devName,dotidx);
	    devName=substr(devName,0,dotidx);
	}
	string devDpName=devName;
	if (strpos(devName,":")<1) {
	    // "LOGICAL" device (alias)
	    devDpName=dpAliasToName(devName);
	    if (devDpName=="") {
		fwException_raise(exceptionInfo,"ERROR","Failed to modify recipe class "+recipeClass+" - logical device does not exist: "+newDeviceList[i],"");
		DebugTN("ERROR in fwConfigurationDB_modifyRecipeClass while modifying recipe class "+recipeClass, "Logical device does not exist:",
		    newDeviceList[i],devName);
		return;
	    
	    }
	    devDpName=dpSubStr(devDpName,DPSUB_SYS_DP);
	}
	// check if it exists: depending on whether it is a device or an element...
	if (dotidx>0) {
	    if (dynlen(dpNames(devDpName+elemName))<1) {
		fwException_raise(exceptionInfo,"ERROR","Failed to modify recipe class "+recipeClass+" - device element does not exist: "+newDeviceList[i],"");
		DebugTN("ERROR in fwConfigurationDB_modifyRecipeClass while modifying recipe class "+recipeClass, "Device element does not exist:",
		    newDeviceList[i],devName, devDpName,elemName);
		return;
	    }
	    // otherwise: everything OK! append to the final list and continue!
	    dynAppend(elements,newDeviceList[i]);
	    continue;
	
	} else { // it is a device... check if exists
	    if (!dpExists(devDpName)) {
		fwException_raise(exceptionInfo,"ERROR","Failed to modify recipe class "+recipeClass+" - device does not exist: "+devName,"");
		DebugTN("ERROR in fwConfigurationDB_modifyRecipeClass while modifying recipe class "+recipeClass, "Device does not exist:",
		    devName, devDpName);
		return;
	    }
	}
	string dpt=dpTypeName(devDpName);
	if (!mappingHasKey(rtElements,dpt)) {
	    fwException_raise(exceptionInfo,"ERROR","Failed to modify recipe class "+recipeClass+" - device: "+devName+" not in recipe type "+newRecipeType,"");
	    DebugTN("ERROR in fwConfigurationDB_modifyRecipeClass while modifying recipe class "+recipeClass, "Device type not in recipe type "+newRecipeType,
		devName, "DPType:"+dpt);
	    return;
	}
	dyn_string devElems=rtElements[dpt];
	for (int j=1;j<=dynlen(devElems);j++) {
	    dynAppend(elements,devName+devElems[j]);
	}
    }
    
    rclInfo[fwConfigurationDB_RCL_RECIPETYPE]=newRecipeType;
    rclInfo[fwConfigurationDB_RCL_DESCRIPTION]=newDescription;
    rclInfo[fwConfigurationDB_RCL_ELEMENTS]=elements;
    
    _fwConfigurationDB_updateRecipeClass(recipeClass, rclInfo,exceptionInfo, updateInstances);
}

/** Internal function to modify recipe class: does not check the content passed in recipeClassInfo
*/
void _fwConfigurationDB_updateRecipeClass(string recipeClass, dyn_mixed recipeClassInfo,
                                    dyn_string &exceptionInfo, bool updateInstances=TRUE)
{
    bool exists=TRUE; // ON INPUT: we want an exception for not existing 
    string classDp=_fwConfigurationDB_getRecipeClassDP(recipeClass, exists, exceptionInfo);
    if (dynlen(exceptionInfo)) return;

    time lastModifiedTime=getCurrentTime();
    string lastModifiedUser=getUserName();

    dpSetWait(
	classDp+".RecipeType",recipeClassInfo[fwConfigurationDB_RCL_RECIPETYPE],
        classDp+".Description",recipeClassInfo[fwConfigurationDB_RCL_DESCRIPTION],
        classDp+".Elements",recipeClassInfo[fwConfigurationDB_RCL_ELEMENTS],
        classDp+".LastModificationTime",lastModifiedTime,
        classDp+".LastModificationUser",lastModifiedUser,
        classDp+".Editable",recipeClassInfo[fwConfigurationDB_RCL_EDITABLE]
    );

    if (updateInstances) {
	// loop through all instances and update their "last modified" field!
	dyn_string recipes;
	dpGet(classDp+".Recipes",recipes);
	for (int i=1;i<=dynlen(recipes);i++) {
	    dyn_dyn_mixed recipeObject;
	    fwConfigurationDB_loadRecipeFromCache(recipes[i], makeDynString(),"",recipeObject, exceptionInfo);
	    if (dynlen(exceptionInfo)) {
		fwException_raise(exceptionInfo,"WARNING","While updating recipe class "+recipeClass+" failed to update recipe "+recipes[i],"");
		DebugTN("WARNING: While updating recipe class "+recipeClass+" failed to update recipe "+recipes[i],"Skipping it and continuing...");
		continue;
	    }
	    // check if the list of DPEs have changed...
	    dyn_string oldDpeList;
	    for (int j=1;j<=dynlen(recipeObject[fwConfigurationDB_RO_DPE_NAME]);j++) {
		dynAppend(oldDpeList,recipeObject[fwConfigurationDB_RO_DP_NAME][j]+recipeObject[fwConfigurationDB_RO_ELEMENT_NAME][j]);
	    }
	    
	    dyn_string existingElements=oldDpeList;

	    dyn_string newDpeList=recipeClassInfo[fwConfigurationDB_RCL_ELEMENTS];
	    dynSortAsc(oldDpeList);
	    dynSortAsc(newDpeList);
	    if (oldDpeList!=newDpeList) {

		// and also need to remove the ones that were removed...
		dyn_string toRemoveElements;
		for (int j=1;j<=dynlen(oldDpeList);j++){
		    if (!dynContains(newDpeList,oldDpeList[j])) dynAppend(toRemoveElements,oldDpeList[j]);		
		}
		dyn_string missingElements;
		for (int j=1;j<=dynlen(newDpeList);j++) {
		    if (!dynContains(oldDpeList,newDpeList[j])) dynAppend(missingElements,newDpeList[j]);
		}

		// Removing is tricky before column indices/lengths change!
		// prepare a list of indices, then remove starting from the back!
		dyn_int toRemoveIdx;
		for (int j=1;j<=dynlen(toRemoveElements);j++) {
		    int idx=dynContains(existingElements,toRemoveElements[j]);
		    if (idx) dynAppend(toRemoveIdx,idx);
		}
		dynSortAsc(toRemoveIdx);
		for (int k=1;k<=fwConfigurationDB_RO_MAXIDX;k++){
		    dyn_mixed col=recipeObject[k];
		    for (int j=dynlen(toRemoveIdx);j>=1;j--) {
			dynRemove(col,toRemoveIdx[j]);
		    }
		    recipeObject[k]=col;
		}
		
		
		// now we snapshot the current values for missing elements
		dyn_dyn_mixed missingRecipeObject;
		fwConfigurationDB_makeRecipe(missingElements, makeDynMixed(), missingRecipeObject, exceptionInfo);		
		fwConfigurationDB_combineRecipes(  recipeObject, recipeObject, missingRecipeObject, exceptionInfo);

	    }
	    

	    fwConfigurationDB_setRecipeMetaInfo(recipeObject, fwConfigurationDB_RO_META_LASTMODIFICATIONTIME, lastModifiedTime,exceptionInfo);
	    fwConfigurationDB_setRecipeMetaInfo(recipeObject, fwConfigurationDB_RO_META_LASTMODIFICATIONUSER, lastModifiedUser,exceptionInfo);
//DebugTN("Modified recipe",recipes[i],recipeObject);

	    fwConfigurationDB_saveRecipeToCache (recipeObject, "", recipes[i], exceptionInfo);

	}
    }
}


void fwConfigurationDB_getRecipeClassInfo(string recipeClass, 
		dyn_mixed &recipeClassInfo, dyn_string &exceptionInfo)
{
    // clear and make sure the length of the object is OK
    dynClear(recipeClassInfo);
    recipeClassInfo[fwConfigurationDB_RCL_MAXIDX]="";

    bool exists=TRUE; // ON INPUT: we want an exception for not existing 
    string classDp=_fwConfigurationDB_getRecipeClassDP(recipeClass, exists, exceptionInfo);
    if (dynlen(exceptionInfo)) return;

    string recipeType,description,lastActivationUser,lastModificationUser,lastActivatedOfThisType;
    time lastActivationTime,lastModificationTime;
    dyn_string elements,recipes;
    bool editable;
    
    int rc = dpGet( classDp+".RecipeType",recipeType,
                    classDp+".Description",description,
                    classDp+".LastActivationTime",lastActivationTime,
                    classDp+".LastActivatedOfThisType",lastActivatedOfThisType,
                    classDp+".LastActivationUser",lastActivationUser,
                    classDp+".LastModificationTime",lastModificationTime,
                    classDp+".LastModificationUser",lastModificationUser,
                    classDp+".Elements",elements,
                    classDp+".Recipes",recipes,
                    classDp+".Editable",editable);
    if (rc) {
	fwException_raise(exceptionInfo,"ERROR","Could not get info of recipe class: "+recipeClass,"");
	DebugTN("ERROR in fwConfigurationDB_getRecipeClassInfo","Could not get into of recipe class: "+recipeClass,classDp,getLastError());
        return;
    }

    // extract the pure class name, without system name    
    string classNameWithoutSystem=recipeClass;
    if (strpos(recipeClass,":")>=0) {
        dyn_string ds=strsplit(recipeClass,":");
        classNameWithoutSystem=ds[2];
    }

    // extract the list of devices out of all elements...
    dyn_string devices;
    for (int i=1;i<=dynlen(elements);i++) {
	int dotidx=strpos(elements[i],".");
	string devName=substr(elements[i],0,dotidx);
	dynAppend(devices,devName);
    }
    dynUnique(devices);
    dynSortAsc(devices);
    
    recipeClassInfo[fwConfigurationDB_RCL_CLASSNAME]=classNameWithoutSystem;    
    recipeClassInfo[fwConfigurationDB_RCL_RECIPETYPE]=recipeType;
    recipeClassInfo[fwConfigurationDB_RCL_DESCRIPTION]=description;
    recipeClassInfo[fwConfigurationDB_RCL_ELEMENTS]=elements;
    recipeClassInfo[fwConfigurationDB_RCL_DEVICES]=devices;
    recipeClassInfo[fwConfigurationDB_RCL_INSTANCES]=recipes;
    recipeClassInfo[fwConfigurationDB_RCL_EDITABLE]=editable;
    recipeClassInfo[fwConfigurationDB_RCL_LAST_MODIFIED_TIME]=lastModificationTime;
    recipeClassInfo[fwConfigurationDB_RCL_LAST_ACTIVATED_USER]=lastActivationUser;
    recipeClassInfo[fwConfigurationDB_RCL_LAST_ACTIVATED_RECIPE]=lastActivatedOfThisType;
    recipeClassInfo[fwConfigurationDB_RCL_LAST_MODIFIED_USER]=lastModificationUser;
    recipeClassInfo[fwConfigurationDB_RCL_LAST_ACTIVATED_TIME]=lastActivationTime;

}

/** Internal function
    updates various meta info (of recipe instance, of a class), when
    recipe gets activated.
*/
void _fwConfigurationDB_activateRecipeUpdateMetaInfo(dyn_dyn_mixed &recipeObject, dyn_string &exceptionInfo)
{
    // firstly, extract the info from activated recipeObject
    string recipeName, recipeClass;
    fwConfigurationDB_getRecipeMetaInfo(recipeObject, fwConfigurationDB_RO_META_CLASSNAME, recipeClass,exceptionInfo);
    fwConfigurationDB_getRecipeMetaInfo(recipeObject, fwConfigurationDB_RO_META_ORIGNAME,  recipeName, exceptionInfo);

    if (recipeClass=="") return; // nothing to update...
    if (recipeName=="") return; // nothing to update...

    time t0=getCurrentTime();

    // treat the recipe class
    bool exists=TRUE; // ON INPUT: we want an exception for not existing 
    string classDp=_fwConfigurationDB_getRecipeClassDP(recipeClass, exists, exceptionInfo);
    if (dynlen(exceptionInfo)) return;

    dpSetWait(classDp+".LastActivationTime",t0,
	      classDp+".LastActivatedOfThisType",recipeName,
	      classDp+".LastActivationUser",getUserName()
    );
    
    // treat the recipe cache
    string recipeCacheDp;
    dyn_string ds=strsplit(recipeName,":");
    if (dynlen(ds)>1) {
	recipeCacheDp=ds[1]+":"+fwConfigurationDB_RecipeCacheDpPrefix+recipeName;
    } else {
	recipeCacheDp=fwConfigurationDB_RecipeCacheDpPrefix+recipeName;
    }
    
    if (!dpExists(recipeCacheDp)) {
	fwException_raise(exceptionInfo,"ERROR","Cannot update recipe activation data: recipe cache not found "+recipeName,"");
	return;
    }
    dpSetWait(recipeCacheDp+".MetaInfo.LastActivationTime",t0,
	      recipeCacheDp+".MetaInfo.LastActivationUser",getUserName());
}
