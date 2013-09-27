/**@file
 *
 * This package contains main skeleton for documentation of the Configuration Database tool
 *
 * @author Piotr Golonka (EN/ICE-SCD)
 * (c) Copyright CERN, All Rights Reserved
 */



/** @mainpage JCOP Framework Configuration Database component
 *
 *
 * @section GettingStarted Getting started
 *
 * In this section you will find a list of most useful functions.
 *
 * @subsection qstart_generalRemarks General Remarks
 *
 * @subsubsection qstart_ExceptionHandling Exception Handling
 *
 * Following the general JCOP Framework conventions each function contains
 * a parameter called <em>exceptionInfo</em> of <em>dyn_string&</em> type.
 * This parameter is used to pass the information about errors and exceptions,
 * and should always be used to handle the exception conditions.
 * In normal conditions, when no problems were encountered and a function
 * finished succesfully the contents of the <em>exceptionInfo</em> variable
 * will be empty; otherwise, it will contain the information about the nature
 * of the problem. This information may be displayed to the user in a standard
 * exception handling dialog box (if the function is executed from within a UI
 * manager) or printed to the log file. If the function is executed in non-UI manager
 * the actual method of handling the situation of exception is to be chosen by
 * the application developer. One should always check the contents of the
 * <em>exceptionInfo</em> after each call to the API functions of the ConfigurationDB tool.
 *
 * Example of error-handling in a panel:
 * @code
main()
{
    dyn_string exceptionInfo;
    int param=1;

    fwConfigurationDB_someFunction(param,exceptionInfo);
    if (dynlen(exceptionInfo)) { fwExceptionHandling_display(exceptionInfo); return; }
    // the code goes on ...
} @endcode
 *
 * Example of error handling in a control script:
 * @code
bool myFunction()
{
    // returns TRUE on success...

    dyn_string exceptionInfo;
    int param=1;

    fwConfigurationDB_someFunction(param,exceptionInfo);
    if (dynlen(exceptionInfo)) { DebugN(exceptionInfo); return FALSE; }
    // the code goes on ...
    return TRUE
} @endcode
 *
 *
 * @subsubsection qstart_initialization Initialization
 *
 * Before you start using any of the functions, you need to make sure
 * that the tool is initialized properly. The initialization procedure
 * takes care of opening the connection to the database server, selecting
 * the default recipe types and initialization of internal data structures.
 *
 * To initialize the tool, place the call to @ref fwConfigurationDB_initialize
 * function. Typicaly, one will use the default setup, hence the empty string
 * will be passed as the <em>setupName</em> parameter. The following code could be
 * used in the initialization of the panel:
 * @code
    dyn_string exceptionInfo;
    fwConfigurationDB_initialize("",exceptionInfo);
    if (dynlen(exceptionInfo)) {fwExceptionHandling_display(exceptionInfo);return};
    // further initializations, as needed...
 * @endcode
 *
 * To simply ensure the initialization was performed, without unnecessary forcing
 * of re-initialization (which involve reopening database connections and hence
 * may be a lengthy process), one may use the
 * @ref fwConfigurationDB_checkInit function instead; it will chech if the tool
 * has already been initialized, and call the @ref fwConfigurationDB_initialize if needed.
 *
 * Please note, that @ref fwConfigurationDB_checkInit does not allow to specify
 * the setup parameter: the default setup is always used.
 * We therefore suggest that @ref fwConfigurationDB_initialize is always used
 * for the first initialization, and @ref fwConfigurationDB_checkInit
 * is used later, as a "safeguard" function.
 *
 *
 * @subsubsection qstart_devLists Device lists
 *
 * A number of API functions in the ConfigurationDB requires the list
 * of devices (or items) as one of the parameters of the <em>dyn_string</em> type.
 * The device (item) name is:
 * @li the DataPoint Name for the HARDWARE view
 * @li the DataPoint Alias for the LOGICAL view
 * Device (item) name contains system name may be
 * significant. In the case of devices in HARDWARE hierarchy, the names of the devices
 * always need to contain system name; any device name in a list that does not contain system
 * name will automatically get it prepended (the name of current system will be used).
 * For the LOGICAL hierarchy, on the contrary, the presence of system name in the device (item) name
 * is meaningful and specifies the mode of operation (i.e. working without system name).
 *
 * Some functions consider passing an empty list as "no sub-selection specified",
 * others require that the devices (items) are specified explicitely.
 * To ease the task of building the device lists for the case where devices form a hierarchy,
 * the @ref fwConfigurationDB_getHierarchyFromPVSS may be used. It returns a
 * list of devices (items) that are children (and grand-children, ...) of a specified top-level
 * device (item) in a specified hierarchy.
 * The following example shows the use of this function:
 * the list of all children of the "CAEN" node on the local system
 * will be extracted (i.e. the list of all CAEN crates, their boards,
 * and channels):
 * @code
    string rootNode=getSystemName()+"CAEN";
    dyn_string deviceList;
    dyn_string exceptionInfo;
    fwConfigurationDB_getHierarchyFromPVSS(rootNode, fwDevice_HARDWARE,
                           deviceList, exceptionInfo);
    if (dynlen(exceptionInfo)) {fwExceptionHandling_display(exceptionInfo); return;}
 * @endcode
 *
 * For more information about device lists and hierarchies
 * see also @ref qstart_hierarchies section of this Quick Start.
 *

 * @subsection qstart_recipes Recipes
 *
 * Recipes store dynamic configuration data for a set of devices (items):
 * these contain the values of device elements and the settings of alerts.
 * Recipes may be stored either in a database or in a cache (a local datapoint).
 * *
 * A recipe is identified by a unique name (below also refered to as "tag" or "cacheName").
 * It is defined for a set of devices belonging to the same hierarchy.
 *
 * The use of recipes typicaly involve two steps: retrieving the recipe data from
 * a source, followed by storing these data or applying it to a system.
 * This involves the use of the @ref recipeObject data structure
 * as an intermediate, volatile storage variable, which holds the complete information
 * about a recipe.
 *
 * Recipe-related operations usually accept the @ref qstart_devLists as parameters,
 * to either specify the list of devices (items) for which a recipe is created,
 * or to make a sub-selection of a recipe.
 *
 * @subsubsection qstart_getAvailableRecipes Getting the list of available recipes
 * To get the list of available recipe caches one should use the functions:
 * @li @ref fwConfigurationDB_getRecipesInCache
 * @code
    dyn_string exceptionInfo, recipeList;
    fwConfigurationDB_getRecipesInCache ( recipeList,exceptionInfo);
    if (dynlen(exceptionInfo)) {fwExceptionHandling_display(exceptionInfo); return;}
    RecipeSelector.items=recipeList;
 * @endcode
 * @li the same function mat be used to get the list of recipes in recipe cache, defined for specified device
 * @code
    dyn_string exceptionInfo, recipeList;
    fwConfigurationDB_getRecipesInCache ( recipeList,exceptionInfo,"MyDCS/SubSys1/device1");
    if (dynlen(exceptionInfo)) {fwExceptionHandling_display(exceptionInfo); return;}
    RecipeSelector.items=recipeList;
 * @endcode
 * @li @ref fwConfigurationDB_getRecipesInDB to get the list of all recipes stored in the database:
 * @code
    dyn_string exceptionInfo, recipeList;
    fwConfigurationDB_getRecipesInDB(recipeList, exceptionInfo);
    if (dynlen(exceptionInfo)) {fwExceptionHandling_display(exceptionInfo); return;}
    RecipeSelector.items=recipeList;
 * @endcode
 * @li the same function mat be used to get the list of recipes in the database, defined for specified device
 * @code
    dyn_string exceptionInfo, recipeList;
    fwConfigurationDB_getRecipesInDB ( recipeList,exceptionInfo,"MyDCS/SubSys1/device1");
    if (dynlen(exceptionInfo)) {fwExceptionHandling_display(exceptionInfo); return;}
    RecipeSelector.items=recipeList;
 * @endcode
 *
 * @subsubsection qstart_recipe_load Loading stored Recipes
 * To load stored recipe to a recipeObject one should use the functions:
 * @li @ref fwConfigurationDB_loadRecipeFromCache to load a recipe from recipe cache
 * @li @ref fwConfigurationDB_loadRecipeFromDB    to load a recipe from the database
 *
 * Note that these function do not overwrite the passed <em>recipeObject</em>,
 * but rather perform "append" operations by means of the @ref fwConfigurationDB_combineRecipes function,
 * so combining the recipes is easy...
 *
 * @code
    // combine two recipes, and apply it to running system
    dyn_string exceptionInfo;
    dyn_dyn_mixed recipeObject;
    string hierarchy=fwDevice_LOGICAL
    dyn_string deviceList; // empty: get all devices...

    // get "coarse" settings from the database
    fwConfigurationDB_loadRecipeFromDB("hv_coarse_settings",deviceList, hierarchy,
					recipeObject,exceptionName,"");
    if (dynlen(exceptionInfo)) {fwExceptionHandling_display(exceptionInfo); return;}

    // append "fine-tune" settings stored in the cache
    fwConfigurationDB_loadRecipeFromCache("hv_fine_tune_settings", deviceList, hierarchy,
                                            recipeObject,exceptionInfo);
    if (dynlen(exceptionInfo)) {fwExceptionHandling_display(exceptionInfo); return;}

    // apply resulting recipe:
    fwConfigurationDB_applyRecipe   (recipeObject, hierarchy, exceptionInfo);
    if (dynlen(exceptionInfo)) {fwExceptionHandling_display(exceptionInfo); return;}
 * @endcode
 *
 * @subsubsection qstart_recipe_apply Apply Recipes
 * To apply a recipe stored in <em>recipeObject</em> to the system use the
 * @ref fwConfigurationDB_applyRecipe function.
 *
 * To get a recipe data into a <em>recipeObject</em> you may load the data
 * from database or a recipe cache using the functions described in
 * @ref qstart_recipe_load .
 * You may also create a <em>recipeObject</em> from a recipe template,
 * create a custom <em>recipeObject</em> following the format of the @ref recipeObject ,
 * edit the existing recipe, or aggregate recipes taken from various sources
 * by means of the @ref fwConfigurationDB_combineRecipes function.
 *
 * See subsection @ref qstart_recipe_load for a code example
 *
 * @subsubsection qstart_recipe_create Create Recipes
 * Typically a new recipe is created in two steps: the data needs to be extracted from
 * the running system and stored in @ref recipeObject , then it needs to be
 * stored in the database of the recipe cache.
 *
 * Before a recipe is extracted from the system, the recipe type needs to
 * be set. By default, when @ref fwConfigurationDB_initialize is created,
 * the default recipe type is preselected. A custom recipe type may be
 * set using @ref fwConfigurationDB_setRecipeType function.
 *
 * To extract the recipe data from the running system (i.e. take a "snapshot"
 * of the current settings)
 * the @ref fwConfigurationDB_extractRecipe function should be used.
 *
 * Example:
 * @code
    dyn_dyn_mixed recipeObject; // recipe data will go here
    dyn_string deviceList;
    dyn_string exceptionInfo;
    string hierarchyType=fwDevice_LOGICAL;

    // set the recipe type
    fwConfigurationDB_setRecipeType("OnlyVoltages", exceptionInfo);
    if (dynlen(exceptionInfo)) {fwExceptionHandling_display(exceptionInfo); return;}

    // extract the list of all items below ATLAS/EM/Barel/HV in logical hierarchy
    string rootNode=getSystemName()+"ATLAS/EM/Barel/HV";
    fwConfigurationDB_getHierarchyFromPVSS(rootNode, fwDevice_HARDWARE,
                           deviceList, exceptionInfo);
    if (dynlen(exceptionInfo)) {fwExceptionHandling_display(exceptionInfo); return;}

    // get the recipe data
    fwConfigurationDB_exctractRecipe(deviceList, hierarchyType,
				    recipeObject, exceptionInfo);
    if (dynlen(exceptionInfo)) {fwExceptionHandling_display(exceptionInfo); return;}
 * @endcode
 *
 *
 * @subsubsection quickstart_recipe_store Storing recipes
 * The recipes contained in a <em>recipeObject</em> can be permanently stored in the
 * database or, locally, in a recipe cache. The following functions are at programmer's
 * disposal:
 * @li @ref fwConfigurationDB_saveRecipeToDB     stores a recipe contained in a <em>recipeObject</em> into the database
 * @li @ref fwConfigurationDB_saveDiffRecipeToDB stored a differences, with respect to already stored recipe, in the database
 * @li @ref fwConfigurationDB_saveRecipeToCache  stores a recipe contained in a <em>recipeObject</em> into recipe cache;
 *          note that if a recipe cache with the same name already exists, it will be overwritten;
 *          otherwise: a new recipe cache, with given recipe name, will be created automatically
 *          by means of @ref fwConfigurationDB_createRecipeCache .
 *
 *
 * @subsubsection qstart_recipe_templates Recipe templates
 *
 * Recipe templates are an effective way of creating a recipes
 * that contain same settings for a number of devices:
 * the idea is to define the configuration data for
 * a single device only, then provide the list of devices
 * which should have this settings applied.
 * Recipe templates are used by means of the
 * @ref fwConfigurationDB_makeRecipeFromTemplate function.
 *
 * Any recipeObject may play a role of the recipe template;
 * for instance, the settings for one of HV channels, that
 * are stored in recipe cache may be loaded, then used to
 * create a recipe that will use these settings for the whole
 * HV subsystem, or a few boards of a HV crate.
 *
 * A recipe template (we use this term to refer to templRecipeObject variable
 * of the @ref fwConfigurationDB_makeRecipeFromTemplate function)
 * may contain the settings for more than one device types, e.g.
 * it may contain settings for a CAEN channel, a CAEN board and a CAEN crate.
 * The appropriate settings from the template will then be used (based on the
 * device type information) to select the settings for devices from the device list.
 *
 * In the example below we will use a part of "hv_ramp" recipe stored in a recipe
 * cache (strictly speaking: the settings for the first channel and the crate)
 * to create recipe template. Then, we will use such template to create a recipe
 * for the whole HV crate called "CAEN/crate1".
 * @code
    dyn_string exceptionInfo;
    dyn_dyn_mixed templateRecipeObject, recipeObject;

    // load a part of recipe from cache: only two devices are involved!
    fwConfigurationDB_loadRecipeFromCache("hv_ramp",
            makeDynString("SubSys/HvChannel001",
                          "SubSys/HVCrate"),
            fwDevice_LOGICAL, templateRecipeObject,exceptionInfo);
    if (dynlen(exceptionInfo)) {fwExceptionHandling_display(exceptionInfo); return;}

    // make a device list containing the whole CAEN crate.
    string deviceList;
    fwConfigurationDB_getHierarchyFromPVSS (getSystemName()+"CAEN/crate01",
                fwDevice_HARDWARE, deviceList, exceptionInfo);

    // use the template and the device list to create the recipe.
    // note that the template used settings for LOGICAL hierarchy,
    // and we create recipe for HARDWARE hierarchy!

    fwConfigurationDB_makeRecipeFromTemplate (deviceList, fwDevice_HARDWARE,
                                        templateRecipeObject, recipeObject, exceptionInfo);
    if (dynlen(exceptionInfo)) {fwExceptionHandling_display(exceptionInfo); return;}

    // the recipeObject contains the settings for the whole CAEN crate now...
 * @endcode
 *
 * @subsubsection qstart_recipe_adhoc "Manual" creation of recipes
 *
 * The recipe data is stored in a @c dyn_dyn_mixed variable with quite complex structure.
 * Even though it is possible to create an "ad hoc" recipe object by filling in the
 * fields in an array, it is much more convenient to use a dedicated fuction:
 * @ref fwConfigurationDB_saveDiffRecipeToDB to accomplish this task.
 * 
 * To create a recipeObject using this function it is sufficient to provide two
 * lists: one with the list of datapoint element names (with names of devices
 * from any of supported hierarchies), and a list of corresponding settings for
 * these device elements. Note that setting up alerts in this way is not
 * possible at the moment.
 *
 * The following example demonstrates the use of the function:
 * @code
    dyn_string deviceElements;
    dyn_mixed settings;
    
    deviceElements[1]="dist_1:CAEN/crate1.Commands.Kill";
    settings[1]=TRUE;
           
    deviceElements[2]="MyDetector/ECAL/HV/channel000.settings.v0";
    settings[2]=12.34;
    
    // this device is on remote system, yet it is visible!             
    deviceElements[3]="dist_2:CAEN/crate1/board00/channel004.settings.v1";
    settings[3]=56.78;
    
    // this logical device is again on remote system, yet it is visible...                 
    deviceElements[4]="MyDetector2/ECAL/HV/straw4.settings.i1";
    settings[4]=135.7;
                           
    dyn_dyn_mixed recipeObject;
    fwConfigurationDB_makeRecipe(deviceElements, settings, recipeObject, exceptionInfo, TRUE);
 * @endcode
 * In the example above, the recipe will contain 4 elements, for various devices
 * being in local and also in a remote system. Note that both: HARDWARE and LOGICAL devices
 * may be specified and mixed.
 *
 * Note that the last parameter passed into the function has the TRUE value. It signifies that
 * the created recipeObject will be filled with maximum of information that may be guessed from
 * the local and remote systems. This, however, requires that all specified devices exist.
 * Such complete recipe (if it contained only local devices, no remote ones) could be immediately
 * applied to a system, stored in a cache or in the database.
 *
 * However, sometimes one might need to create a recipe (e.g. for future use) that would contain
 * the devices that not yet exist (or devices on remote systems, which are not connected to 
 * the current system). In such situation one might specify the last parameter in the call to
 * @ref fwConfigurationDB_makeRecipe to be FALSE. In such situation, only minimal verification
 * of the device list is performed, and in particular the devices do not need to exist.
 * Such recipe  is not complete. It may not be applied to a system, or stored in a cache.
 * It may, however, be stored in the database! It is then the database's task to complete the
 * missing parts of recipe - the database may do that because the missing information is stored
 * in the static configuration data! 
 *
 * @subsubsection qstart_recipe_otherFunctions Other Functions
 * Let us now enumerate the remaining functions, which may be of general interest.
 *
 * @li To edit the contents of a recipeObject one may use the @ref fwConfigurationDB_editRecipe function,
 * which opens an appropriate panel.
 * @li To visualize  the contents of a recipeObject, it is not always useful to
 * dump its contents using <em>DebugN(recipeObject);</em>. A much more flexible way is
 * to use the @ref fwConfigurationDB_editRecipe function in the read-only mode.
 * @li To compare two recipe objects one may use the @ref fwConfigurationDB_compareRecipes function, which returns
 * a recipeObject with differences.
 * @li To substitute the system name in recipes in HARDWARE hierachy which
 * were stored with another system name one may use the @ref fwConfigurationDB_adoptRecipeObjectToSystem function.
 * @li To get a meta-information (i.e. description) of a recipe one may use
 *  @ref fwConfigurationDB_GetDBRecipeMetaInfo and @ref fwConfigurationDB_GetRecipeCacheMetaInfo functions.
 * @li To create a new, empty recipe in cache one may use the @ref fwConfigurationDB_createRecipeCache function.
 * This function will return an error if a cache with specified name already exists, hence it may be used to
 * protect the recipe caches from being overwritten by mistake with new values.
 *
 *
 * @subsection qstart_hierarchies Hierarchies
 * (documentation not yet completed)
 *
 *
 *
 * @section dataStructures Data Structures
 * PVSS has a limited set of basic data types. Therefore we decided to
 * apply on a naming convention to refer to "objects" passed and
 * returned in functions, using these basic types (dyn_X , dyn_dyn_X
 * or mapping PVSS types).
 *
 * The convention specifies the name of the variable in the definition
 * of the function parameter. For instance, all the functions that
 * used a recipeObject data structure (described below) will have
 * it listed explicitly as "mapping recipeObject" in the list
 * of the parameters.
 *
 * @subsection recipeObject
 *
 * The recipeObject data structure contains the data of a recipe. In PVSS it is
 * handled using dyn_dyn_mixed data type.
 * The data concerning recipe for a  data point element,
 * is stored in lines. Each column, all of which are the same length,
 * store a part of the recipe data for the data point element;
 * the first column is the "key" column - it stores the full names of the
 * data point elements.
 * The columns are refered to using pre-defined constants,
 * which are described in subsection @ref recipeObjectIndices .
 * The structure of the recipeObject is shown in the figure below:

<TABLE style="font-size:8;">
    <TR bgcolor="yellow">
        <td>#</td>
        <td>Data point element</td>
        <td> DP Name </td>
        <td> DP Type</td>
        <td> element</td>
        <td> element type</td>
        <td> has value </td>
        <td> has alert</td>
        <td> value</td>
        <td> alert active</td>
        <td> ... other alert settings</td>
    </TR>
    <tr>
        <td>1</td>
        <td>dist1:AnalogDigital/ai1.value</td>
        <td>dist1:AnalogDigital/ai1</td>
        <td>FwAnalogInput</td>
        <td>.value</td>
        <td>22 (DPEL_FLOAT)</td>
        <td>FALSE</td>
        <td>TRUE</td>
        <td></td>
        <td>TRUE</td>
        <td>...</td>

    </tr>
    <tr>
        <td>2</td>
        <td>dist1:AnalogDigital/ao1.value</td>
        <td>dist1:AnalogDigital/ao1</td>
        <td>FwAnalogOutput</td>
        <td>.value</td>
        <td>22 (DPEL_FLOAT)</td>
        <td>TRUE</td>
        <td>FALSE</td>
        <td>3.14</td>


    </tr>
</TABLE>

 * Although the type of each single cell of the table is "mixed", which
 * allows for storing any data type (including dynamic data types), we decided
 * to store the property value in the encoded form. The
 * @ref _fwConfigurationDB_dataToString and
 * @ref _fwConfigurationDB_stringToData functions are used to encode and decode
 * the data into a string. The other parts of data, including lists of alert
 * texts, alert classes, etc are stored using their native types inside the recipeObject.
 * For more information about the conventions, please refer to
 * subsection @ref recipeDataStorageConventions .
 *
 * @subsection connectionInfo
 *
 * @subsection RTData
 * The RTData object is used as a transient data storage space for Recipe Type
 * data, where the data is edited in RecipeTypeEdit.pnl panel.
 * It is a dyn_dyn_string-typed variable, with the following structure:
 *
 * @li RTData[i][1] : device type name
 * @li RTData[i][2] : device dptype name
 * @li RTData[i][3] : dp element
 * @li RTData[i][4] : property name
 * @li RTData[i][5] : save value
 * @li RTData[i][6] : save alert
 *
 * the "i" index refers to the entries for subsequent dpes of dpts.
 * Each entry could be uniquely identified by
 * RTData[i][2] and RTData[i][3] entries.
 *
 * Convention: for the Framework devices RTData[i][1] will store
 * the Framework Device Name according to device definitions,
 * e.g. "CAEN Board", and the RTData[i][2] will store the actual
 * data point type, e.g. FwCaenChannel.
 * For non-framework data poin types, both: RTData[i][1]
 * and RTData[i][2] will contain the data point type.
 * This way one can in fact distinguish the Framework
 * and non-Framework entries by checking if
 * RTData[i][1] and RTData[i][2] are the same.
 *
 * @section conventions Conventions
 *
 * @subsection recipeDataStorageConventions Conventions for recipe data storage
 * The following conventions for data encoding are used for recipes.
 *

<table>
<tr bgcolor="yellow">
    <td bgcolor="lightgreen">what/where</td>
    <td>System</td>
    <td>recipeObject</td>
    <td>recipe cache</td>
    <td>database</td>
</tr>
<tr>
    <td bgcolor="lightblue">property value</td>
    <td> <i>any type</i> </td>
    <td> as string </td>
    <td> as string </td>
    <td> as string </td>
</tr>

<tr>
    <td bgcolor="lightblue">alert active</td>
    <td> bool </td>
    <td> bool </td>
    <td> as string </td>
    <td> as string </td>
</tr>

<tr>
    <td bgcolor="lightblue">alert limits</td>
    <td> dyn_float </td>
    <td> dyn_float </td>
    <td> as string </td>
    <td> as string </td>
</tr>

<tr>
    <td bgcolor="lightblue">alert texts</td>
    <td> dyn_string </td>
    <td> dyn_string </td>
    <td> as string </td>
    <td> as string </td>
</tr>

<tr>
    <td bgcolor="lightblue">alert classes</td>
    <td> dyn_string </td>
    <td> dyn_string </td>
    <td> as string </td>
    <td> as string </td>
</tr>
</table>

 *  The @ref _fwConfigurationDB_dataToString and @ref _fwConfigurationDB_stringToData
 * functions are used to encode and decode the data into a string. The "|" character
 * is used as a separator when dynamic-list-typed variables are stored.
 *
 *
 * @section others Others
 * @li @ref ErrorCodes "Error Codes" returned in exceptionInfo
 * @li @ref recipeObjectIndices
 *
 *
 */


/// @if PrivateFunctions
/**
 * @defgroup PrivateFunctions Private Functions
 */
/// @endif

/**
 * @defgroup DBAccessFunctions Database Access Functions
 */

/**
 * @defgroup InitFunctions Initialization Functions
 */

/**
 * @defgroup RecipeFunctions Recipe Functions
 */


/**
 * @defgroup recipeObjectIndices Indices used to refer to recipeObject variables
 */


/**
 * @defgroup GlobalVariables Global variables
 */

/**
 * @defgroup Constants Set-up parameters
 */



/**
 * @defgroup ErrorCodes Error Codes
 *
 *
 * The following error codes are returned as the third parameter of exceptionInfo
 *
 * @li    codes < -100 are errors
 * @li    codes between -50 and -100 are warnings
 *
 */




//// documentation for error codes ...

//______________________________________________________________________________
///{@
///@ingroup ErrorCodes
//______________________________________________________________________________
/** @var fwConfigurationDB_ERROR_NoValuesDataInRT
 * in the current recipe, there is no information about values
 * to be stored for queried DPT (warning)
 */
/** @var fwConfigurationDB_ERROR_NoAlertsDataInRT
 * in the current recipe, there is no information about alerts
 * to be stored for queried DPT (warning)
 */
/** @var fwConfigurationDB_ERROR_NoRecipeType
 * specified recipe type does not exist (critical)
 */
/** @var fwConfigurationDB_ERROR_CantLoadRecipeType
 * specified recipe type cannot be loaded (critical)
 */
/** @var fwConfigurationDB_ERROR_CantLoadPartOfRecipeType
 * part of specified recipe type (refering to some device type) cannot be loaded (warning)
 *
 * This a warning (i.e. processing is not aborted);
 * a part of recipe type could not be retrieved,
 * either because corresponding data point does not exist, or it
 * exists, but the data cannot be loaded. This usually means that
 * the recipe type should be re-viewed/edited in
 * the fwConfigurationDB/EditRecipeType panel.
 */
/** @var fwConfigurationDB_ERROR_InvalidDataPointName
 * invalid data point name specified
 */
/** @var fwConfigurationDB_ERROR_StoreRecipeDataToCache
 * cannot store recipe data in recipe cache
 */
/** @var fwConfigurationDB_ERROR_NoRecipeCache
 * recipe cache does not exist
 */
/** @var fwConfigurationDB_ERROR_GetRecipeFromCache
 * error getting recipe data from the cache
 */
/** @var fwConfigurationDB_ERROR_CreateRecipeCache
 * error while creating recipe cache datapoint
 */
/** @var fwConfigurationDB_ERROR_RecipeCacheExists
 *  recipe cache with the same name already exists
 */

/** @var fwConfigurationDB_ERROR_DPENotInRecipe
 * specified DPE is not defined in the recipe...
 */

/** @var fwConfigurationDB_ERROR_DBNoConnection
 * connection to database does not exist
 */
  
 
 
 
///@}
//______________________________________________________________________________


//______________________________________________________________________________
///{@
///@ingroup recipeObjectIndices
/** @var fwConfigurationDB_RO_DPE_NAME
 */
/** @var fwConfigurationDB_RO_DP_NAME
 */
/** @var fwConfigurationDB_RO_DP_TYPE
 */
/** @var fwConfigurationDB_RO_ELEMENT_NAME
 */
/** @var fwConfigurationDB_RO_ELEMENT_TYPE
 */
/** @var fwConfigurationDB_RO_HAS_VALUE
 */
/** @var fwConfigurationDB_RO_HAS_ALERT
 */
/** @var fwConfigurationDB_RO_VALUE
 */
/** @var fwConfigurationDB_RO_ALERT_ACTIVE
 */
/** @var fwConfigurationDB_RO_ALERT_TEXTS
 */
/** @var fwConfigurationDB_RO_ALERT_LIMITS
 */
/** @var fwConfigurationDB_RO_ALERT_CLASSES
 */
/** @var fwConfigurationDB_RO_ALERT_TYPE
 */
/** @var fwConfigurationDB_RO_ALERT_MINIDX
 */
/** @var fwConfigurationDB_RO_ALERT_MAXIDX
 */
/** @var fwConfigurationDB_RO_MAXIDX
 */
/** @var fwConfigurationDB_RO_REC_VERSIONID
    contains recipe version for this element, hence allows to
    identify a group of elements of the same device with the same
    identifier
 */
 
/** @var fwConfigurationDB_RO_RECDATA_PROPID
    contains PROPID unique key identifying the property.
     This one is unique for every device element
 */

/** @var fwConfigurationDB_RO_DATECREATED
 */
 

/** @var fwConfigurationDB_RO_METAINFO_START
Indicates the first column storing the meta-information
 */
/** @var fwConfigurationDB_RO_METAINFO_END
Indicates the last column storing the meta-information
 */
 
 
/** @var fwConfigurationDB_RO_META_ORIGNAME
Original name of recipe at the source (e.g. in DB)
 */

/** @var fwConfigurationDB_RO_META_COMMENT
 */
/** @var fwConfigurationDB_RO_META_RECIPETYPE
The name of the recipe type that was used to create this recipe
 */



///@}
//______________________________________________________________________________

//______________________________________________________________________________
///{@
///@ingroup deviceObjectIndices
/** @var fwConfigurationDB_DLO_MODEL
    contains model name for framework devices,
    "DATAPOINT" if this is a non-framework data point,
    "SYSTEM" if this is a top-node of hierarchy
 */
/** @var fwConfigurationDB_DLO_TYPE
    contains device type name for framework devices,
    or data point type name for non-framework data points
 */


//______________________________________________________________________________
