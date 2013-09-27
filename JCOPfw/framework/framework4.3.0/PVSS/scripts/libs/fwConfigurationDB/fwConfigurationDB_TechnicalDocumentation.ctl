/**@file
 *
 * Technical documentation of the tool
 *
 * @author Piotr Golonka (EN/ICE-SCD)
 *
 * Please refer to the following topics
 *
 * @ul @ref PLSQLAPI
 */


/**
@page TechnicalDocumentation Technical Documentation
 *
 * @ref PLSQLAPI
 *
 */

/** @defgroup PLSQLAPI External access to ConfigurationDB (PL/SQL API)
 *
 * External access to the data stored in the ConfigurationDB is provided
 * by means of a PL/SQL package, containing the set of functions:
 */


/** Finds devices for which configuration data exists in a given recipe
 *
 * @ingroup PLSQLAPI
 *
 * @param[in] recipeName - the name of the recipe which is queried
 * @param[in] deviceFilter (optional, default null) 
 *	specifies device name(s) to be checked; note that '*' and '%' may be
 *	used as wildcards, and may be placed at any place within the parameter.
 * @param[in] validAt (optional, default null) allows to query historical
 *	recipes - null signifies "current recipe", otherwise a recipe as it
 *	was at the specified date will be checked.
 *
 * @returns CDB_API_PARAMS(S1) will contain the list of matching recipes;
 * note that the device names will be APPENDED, i.e. the previous contents of the
 * CDB_API_PARAMS are not cleared.
 *
 * @exception ORA-20001 (input data not consistent) see: @ref checkInputTable
 * @exception ORA-20002 (no such recipe) the recipe specified in @c recipeName does not exist
 *
 * @par Example 1: 
 * Show the devices in MyDetector/ECAL for which settings exist in the "PHYSICS/RUN" recipe
 * @code
 *  DELETE FROM CDB_API_PARAMS;
 *  BEGIN fwConfigurationDB.getDevicesInRecipe('PHYSICS/RUN','MyDetector/ECAL/%');END;
 *  SELECT S1 from CDB_API_PARAMS;
 * @endcode
 */
fwConfigurationDB.getDevicesInRecipe(
        VARCHAR2 recipeName,
        VARCHAR2 deviceFilter=null,
        DATE validAt=NULL);

/** Returns device names present in given static configuration
 * @ingroup PLSQLAPI
 *
 * The function returns the list of the names of devices which were saved in specified
 * static configuration, and match specified device filter.
 * Note that the previous contents of the CDB_API_PARAMS table will be wiped out.
 *
 * @param[in] configurationName - the name of the static configuration to be queried
 * @param[in] deviceFilter (optional, default null) - allows to filter the devices;
 *		null value means no filtering (all devices in the configuration will
 *		be returned). Both: % and * may be used as wildcards.
 *
 * @returns CDB_API_PARAMS(s1) will contain the list of device names
 *
 * @exception ORA-20002 (no such configuration) the static configuration specified in 
 *			@c configurationName does not exist
 *
 * @par Example 1:
 * show all CAEN devices in all systems , in configuration called "MySetup". Note the
 * use of wildcard characters * and % to specify all systems (the beginning of the string)
 * and all child devices (end of the string).
 * @code
 *	BEGIN fwConfigurationDB.getDevicesInConfiguration('MySetup','*:CAEN/%');END;
 *	SELECT s1 FROM CDB_API_PARAMS
 * @endcode
 */
fwConfigurationDB.getDevicesInConfiguration(
        VARCHAR2 configurationName,
        VARCHAR2 deviceFilter=null);

/** Gets recipe data
 * @ingroup PLSQLAPI
 *
 * @param[in] recipeName - the name of recipe to query
 * @param[in] validAt (optional, default null) - allows to query historical recipes;
 * 	null means: current recipe, otherwise the recipe as it was at the specified
 *	date will be returned
 * @param[in,out] CDB_API_PARAMS[S1] (optional) may contain the list of devices for which
 *	recipe data is queried; note that the original list will be altered: the order
 *      of devices may change, and only the devices for which recipe data exist will
 *      be present in this column (see below)
 *
 * @returns CDB_API_PARAMS table will contain the recipe data; each row represents
 *	the settings (values and alerts) for a single data point element (hence
 *	the settings for a single device may span multiple, yet consecutive, rows).
 *	Recipe data is placed in the following columns:
 *	@li I1 propertyId (a unique id for recipe data of a data point element)
 *	@li I2 dp element type ("property type") - the type of data, as returned 
 *		by dpElementType() function of PVSS
 *	@li I3 recipe version: ordinal version number for recipe; a common
 *		version number is assigned to all settings stored at the same time
 *	@li I4 determines if value ("setting") is stored in S8
 *	@li I5 determines if alert is configured (the details of which are in I6,I7,S5,S6,S7)
 *	@li I6 the type of alert: one of DPCONFIG_NONE=0, DPCONFIG_ALERT_BINARYSIGNAL=12,
 *		DPCONFIG_ALERT_NONBINARYSIGNAL=13
 *	@li I7 determines if alert is activated
 *	@li I8 device id (a unique id for device)
 * 	@li S1 device name 
 *	@li S2 element name
 *	@li S3 device type (data point type)
 *      @li S4 device model (for Framework devices)
 *	@li S5 alert limits (list of values separated with the | character)
 *	@li S6 alert classes (list of values separated with the | character)
 *	@li S7 alert texts (list of values separated with the | character)
 *	@li S8 datapoint element value(s) ("setting")
 *	@li S9 the type of hierarchy to which the device belongs
 *	@li D1 the time when this setting was stored (start of IOV)
 *	@li D2 the time when this setting was replaced by another, or NULL if the setting
 *		is still valid (end of IOV)
 *	.
 *
 * @exception ORA-20001 (input data not consistent) see: @ref checkInputTable
 * @exception ORA-20002 (no such recipe) the recipe specified in @c recipeName does not exist
 *
 * @par Example 1:
 * Extract the current settings stored in recipe "PHYSICS/RUN" (for all devices for which
 * these settings exist); print out datapoint elements and settings
 * @code
 * DELETE FROM CDB_API_PARAMS;
 * BEGIN fwConfigurationDB.getRecipe('PHYSICS/RUN'); END;
 * -- only print out the data for which values are defined
 * SELECT S1||S2, S8 FROM CDB_API_PARAMS WHERE I4=1;
 * @endcode
 *
 * @par Example 2:
 * As above, but extract the recipe "PHYSICS/RUN", as it looked on 1 April 2007.
 * @code
 * DELETE FROM CDB_API_PARAMS;
 * BEGIN fwConfigurationDB.getRecipe('PHYSICS/RUN', TO_DATE('2007-04-01','YYYY-MM-DD')); END;
 * SELECT S1||S2, S8 FROM CDB_API_PARAMS WHERE I4=1;
 * @endcode
 *
 * @par Example 3:
 * Get current settings from recipe "PHYSICS/RUN" for two selected devices: 
 * "MyDetector/ECAL/HV/chn1" and "MyDetector/ECAL/HV/chn2"
 * @code
 * DELETE FROM CDB_API_PARAMS;
 * INSERT INTO CDB_API_PARAMS(S1) VALUES 'MyDetector/ECAL/HV/chn1';
 * INSERT INTO CDB_API_PARAMS(S1) VALUES 'MyDetector/ECAL/HV/chn2';
 * BEGIN fwConfigurationDB.getRecipe('PHYSICS/RUN');END;
 * SELECT * FROM CDB_API_PARAMS;
 * @endcode
 */
fwConfigurationDB.getRecipe(
        VARCHAR2 recipeName,
        DATE validAt=0);

/** Get list of recipes or find a recipe
 * @ingroup PLSQLAPI
 *
 * The function returns the list of names of recipes that
 * fulfil certain criteria. By default (with all parameters
 * set to default values) it returns the list of all recipes in the database.
 * Note that the function wipes out the previous content of the CDB_API_PARAMS
 * table.
 *
 * @param[in] recipeNameFilter  (optional, default null) allows to filter on
 * 	the recipe name; wildcards ('*' or '%' characters) are allowed.
 *	Specifying null will disable this selection criteria (i.e. all recipes
 *	matching the remaining criteria will be returned).
 * @param[in] deviceFilter (optional, default null) allows to search for
 *	recipe which contain specified device(s). This parameter may contain
 *	wildcards ( '*' or '%' characters), so that any device matching the
 *	specified filter will be approved.
 *	Specifying null will disable this selection criteria (i.e. all recipes
 *	matching the remaining criteria will be returned).
 * @param[in] recipeCommentFilter (optional, default '*') allows to filter on
 * 	the recipe comment; wildcards ('*' or '%' characters) are allowed.
 * @param[in] recipeTypeFilter (optional, default '*') allows to filter on
 * 	the recipe type; wildcards ('*' or '%' characters) are allowed.
 *
 * @returns The CDB_API_PARAMS will contain the names and the meta-information
 *	describing the recipes in the following columns:
 *	@li S1 recipe name
 *	@li S2 recipe comment
 *	@li S3 recipe type
 *	.
 *	Note that if no matching recipes are found, the CDB_API_PARAMS will be
 *	empty.
 *
 * @par Example 1:
 * Show the names of recipes which have any CAEN devices inside, and its name
 * starts with "PHYSICS":
 * @code
 *	BEGIN fwConfigurationDB.getRecipesList('PHYSICS/%','*CAEN*'); END;
 *	SELECT S1 FROM CDB_API_PARAMS;
 * @endcode
 */
fwConfigurationDB.getRecipesList(
    VARCHAR2 recipeNameFilter=null,
    VARCHAR2 deviceFilter=null,
    VARCHAR2 recipeCommentFilter='*',
    VARCHAR2 recipeTypeFilter='*');

/** Get the list of available static configurations
 * @ingroup PLSQLAPI
 *
 * @param[in] configurationNameFilter (optional, default null) allows to filter
 *	on configuration names: the '*' and '%' wildcards are allowed; null
 *	means: get all configuration names
 *
 * @returns CDB_API_PARAMS[S1] will contain the list of configuration names
 *
 * Note that the previous contents of the CDB_API_PARAMS table will be wiped out.
 */
fwConfigurationDB.getConfigurationsList(
    VARCHAR2 configurationNameFilter=null);

/** Creates a new recipe with given name and comment
 * @ingroup PLSQLAPI
 *
 * @param[in] recipeName  the name for the recipe
 * @param[in] recipeDescription (optional, default null) the comment for the recipe
 *
 * @exception ORA-20002 (recipe already exists) the recipe specified in @c recipeName already exists
 *
 */
fwConfigurationDB.createRecipe(
        VARCHAR2 recipeName,
        VARCHAR2 recipeDescription=null);

/** Stores a new version of recipe data
 * @ingroup PLSQLAPI
 *
 * @param[in] recipeName - the name of the recipe
 * @param[in] versionDescription (optional, default null) text indicating the reason for this new version
 * @param[in] userCreated (optional, default null) the name of the user who created this version
 * @param[in,out] CDB_API_PARAMS table needs to be filled with recipe data; each row contains settings for one
 *		data point element. The data should be placed in the following columns:
 *	@li S1 device name
 *	@li S2 device element name (including leading dot!)
 *	@li I1 (optionally) may contain PropId (i.e. known from loading a recipe previously), see below in examples
 *	@li I4 should be set to 1 if value ("setting") is available
 *	@li I5 should be set to 1 if alarm is configured
 *
 *	.
 *	The following column need to be filled with valid data, if value is specified (i.e. I4=1),
 *	otherwise they may contain NULL:
 *	@li S8 contains the value ("setting"). For values being lists,
 *		the elements should be concatenated into a string, separated using the | character
 *
 *	.
 *	The following columns need to be filled with valid data, if alert is specified (i.e. I5=1),
 *	otherwise they may contain NULL:
 *	@li I6 alert type; the alert type may be one of
 *		DPCONFIG_NONE=0, DPCONFIG_ALERT_BINARYSIGNAL=12, DPCONFIG_ALERT_NONBINARYSIGNAL=13
 *	@li I7 alert active flag; 1 means alert is active
 *	@li S6 alert classes; the names of alert classes should be concatenated
 *		and separated using the | character. Note that for there needs to be an empty alert class that signifies
 *		the valid alert range! For instance "|_fwErrorAck" or "_fwErrorAck||_fwErrorAck" or "_fwErrorAck|" 
 *		(note the trailing | character in this last example!)
 *	@li S7 alert texts; texts needs to be concatenated and separated using the | character
 *	@li S5 alert limits; limits need to be concatenated and separated using the | character
 *	.
 * 
 * @exception ORA-20002 (no such recipe) the recipe specified in @c recipeName does not exist
 * @exception ORA-20023 (no such device) a device has not been stored in any of existing static configurations
 * @exception ORA-20024 (no such device element) a device has no such element
 *
 * @returns Note: the contents of CDB_API_PARAMS may be undefined and will differ from the one
 * passed as an input! Internally, the following data is filled in the CDB_API_PARAMS:
 * @li I8: DPID (datapoint ID)
 * @li I1: IPROP_ID - assigned for records that do not have it
 * @li I2: DEVELEM_ID (DP element ID)
 * @li I3: RVER (recipe version ID )
 * @li I4: marks (sets to 1) the devices that do not need to be invalidated
 *
 * .
 *
 * For a set of examples, refer to the main page of @ref PLSQLAPI.
 */
fwConfigurationDB.storeRecipe(
        VARCHAR2 recipeName,
        VARCHAR2 versionDescription=null,
        VARCHAR2 userCreated=null);


/** Returns the mapping between devices and aliases
 * @ingroup PLSQLAPI
 *
 * @param[in] configurationName the name of static configuration from which 
 *	the mapping should be retrieved
 * @param[in] validAt (optional, default null) if not null, allows to query
 *	historical mapping. The mapping that is returned is the one that was
 *	in the Configuration Database at the time specified using this parameter.
 * @param[in,out] CDB_API_PARAMS[s1] (optional) may contain the list of aliases for
 *	which the mapping is queried; if CDB_API_PARAMS is empty, the mapping
 *	for all devices will be returned.  Note that the contents of the 
 *	CDB_API_PARAMS will be altered - you may not assume the order of items,
 *	and the presence of all aliases you placed there on input!
 *
 * @returns CDB_API_PARAMS will contain the mapping in the following columns
 * 	@li S1 device alias
 *	@li S2 device (datapoint) name to which the alias points
 *	@li S3 hierarchy type of the device in S1
 *	@li S4 hierarchy type of the device in S2
 *	@li D1 the time this mapping was stored (i.e. became effective)
 *	@li D2 the time this mapping was replaced by other mapping
 *		(i.e. the end of validity for historical mapping),
 *		or NULL if the mapping is still valid
 *	@li I1 device alias ID
 *	@li I2 refered (device) ID
 *
 *	.
 *
 * @exception ORA-20001 (input data not consistent) see: @ref checkInputTable
 * @exception ORA-20005 (no such configuration) the static configuration specified 
 *	in @c configurationName does not exist
 *
 */
fwConfigurationDB.getReferences(
        VARCHAR2 configurationName,
        DATE validAt=null);

/** Stores a new mapping between devices and aliases
 * @ingroup PLSQLAPI
 *
 * @param[in] configurationName the name of static configuration to which 
 *	the mapping should be stored
 * @param CDB_API_PARAMS needs to be filled in with the following information
 *	@li S1 the alias
 *	@li S2 the datapoint (device) to which the alias should be pointing
 *
 *	.
 *
 * @exception ORA-20005 (no such configuration) the static configuration specified 
 *	in @c configurationName does not exist
 * @exception ORA-20021 (device list not unique) one or more devices in S2 column
 *	does not exist in the static configuration, or it is given more than once,
 *	or it is null
 * @exception ORA-20022 (alias list not unique) one or more aliases in S1 column
 *	does not exist in the static configuration, or it is given more than once,
 *	or it is null
 * @exception ORA-20023 (no such alias) an alias does not exist in any of static configurations
 * @exception ORA-20024 (no such device) a device does not exist in any of static configurations
 *
 */
fwConfigurationDB.setReferences(
        VARCHAR2 configurationName);

/** Returns the history of mappings for given aliases
 * @ingroup PLSQLAPI
 *
 * @param[in] configurationName - the name of static configuration to be queried
 * @param[in] startDate (optional, default null) the start of the period to query;
 * 	null means no start limit: get the history starting from the first available
 * 	entries
 * @param[in] endDate (optional, default null) the end of the period to query;
 * 	null means no end limit: get the history up to the current mapping
 * @param[in] CDB_API_PARAMS[S1] (optional) may contain the aliases for which the mapping
 *	is being queried; if the table is empty, the mapping for all aliases will be
 *	queried (carefully! this may be a lot of data!)
 *
 * @returns CDB_API_PARAMS will be filled with possibly multiple records per
 * 	every alias: a single line indicates one IOV (Interval of Validity)
 *	per one device. The data will be in the following columns:
 * 	@li S1 device alias
 * 	@li S2 device dpname refered to by the alias
 * 	@li S3 hierarchy type of S1
 * 	@li S4 hierarchy type of S2
 * 	@li D1 start of IOV for this mapping
 * 	@li D2 end of IOV for this mapping
 *	@li I1 device alias ID
 *	@li I2 refered (device) ID
 *
 * .
 * @par Example 1:
 * show the changes to the mapping for aliases MyDetector/ECAL/chn1 and MyDetector/ECAL/chn2 
 * performed throughout the month of April 2007, stored in static configuration "MySetup".
 * @code
 * DELETE FROM CDB_API_PARAMS;
 * INSERT INTO CDB_API_PARAMS(s1) VALUES 'MyDetector/ECAL/chn1';
 * INSERT INTO CDB_API_PARAMS(s1) VALUES 'MyDetector/ECAL/chn2';
 * BEGIN 
 *	fwConfigurationDB.getReferenceHistory('MySetup', 
	    TO_DATE('2007-04-01','YYYY-MM-DD'), 
	    TO_DATE('2007-04-30','YYYY-MM-DD')
	);
 * END;
 * SELECT S1 Alias, S2 Device , D1 Since, D2 Till from CDB_API_PARAMS;
 * @endcode
 * This example might hypotetically return the following results:
 * @code
 * |---------------------|------------------------------|-----------|------------|
 * | Alias               | Device                       | Since     | Till       |
 * |---------------------|------------------------------|-----------|------------|
 * |MyDetector/ECAL/chn1 |dist_1:CAEN/crate1/bd00/chn00 |2006-10-12 | 2007-04-05 |
 * |MyDetector/ECAL/chn1 |dist_1:CAEN/crate1/bd10/chn05 |2007-04-05 | 2007-04-10 |
 * |MyDetector/ECAL/chn1 |dist_1:CAEN/crate1/bd00/chn00 |2007-04-10 | NULL       |
 * |MyDetector/ECAL/chn2 |dist_1:CAEN/crate1/bd00/chn01 |2007-04-03 | 2007-04-05 |
 * |MyDetector/ECAL/chn2 |dist_1:CAEN/crate2/bd12/chn02 |2007-04-10 | 2007-06-20 |
 * |---------------------|------------------------------|-----------|------------|
 * @endcode
 * These results may be interpretted as follows:
 * @li first three lines contain information about the first alias, the
 * 	remaining ones - about the second alias - this is indicated by the 
 *	value in the first column
 * @li The first alias was pointing to crate1/bd00/chn00 until 2007-04-05,
 * 	and it was the mapping that was valid since 2006-10-12. We do not
 *	know what was the mapping before.
 * @li The mapping for the first alias changed twice in the month or April,
 *	and the last change (which actually reversed the first change) is still
 *	valid up till now (note the NULL value
 * @li The second alias was added (or reactivated) only on 2007-04-03. Before the
 *	1st of April it did not exist. The mapping in the fourth line lasted till
 *	5th of April, then the device was deleted - this can be seen by looking 
 *	at the "Since" value in the next line - it differs from the "Till" column.
 * @li The second device was added again on 10th of April, and the mapping lasted
 *	till 2007-06-20, at which date the mapping has changed: the device alias was
 *	either deleted again, or its mapping has changed to something else. One could
 *	not tell the reason: the query was executed with @c endDate set to end of April;
 *	one would need to specify null as the @c endDate to see the history past the
 *	end of April.
 *
 * .
 *
 */
fwConfigurationDB.getReferenceHistory(
        VARCHAR2 configurationName,
        DATE startDate=null,
        DATE endDate=null);

/** Checks the consistency of the data in the CDB_API_PARAMS table
 * @ingroup PLSQLAPI
 *
 * SCOPE OF USE: Internal
 *
 * The function checks if all columns (except S1, and - depending on @c checkS2 parameter - also S2) 
 * in the CDB_API_PARAMS are empty. This is to make sure that the user did not forget to clean up
 * the CDB_API_PARAMS table after the previous use. This function is called internally 
 * by most of the function in the package. The function also returns the number of rows in the CDB_API_PARAMS,
 * i.e. the number of input records.
 *
 * @param checkS2 (default 1) determines if the S2 column should be checked. Passing NULL will
 *	result in S2 not being checked (i.e. signifies that S2 contain valid data).
 *
 * @returns the number of rows in the CDB_API_PARAMS table
 *
 * @exception ORA-20001 (fwConfigurationDB: Input table CDB_API_PARAM not consistent. Forgot to TRUNC it before use?) 
 * is reported if the data is not consistent (i.e. the table contains the data which is not acceptable as input to
 * the procedure - S1 or/and S2 columns are not empty)
 *
 *
 */
int fwConfigurationDB.checkInputTable(NUMBER checkS2=1);

/** Draws a set of numbers from named sequence
 *
 * The function draws a set of @c n numbers from sequence called @c sequenceName .
 *
 * SCOPE OF USE: Internal
 *
 * @param[in] sequenceName  the name of sequence
 * @param[in] n  the number of sequence numbers to draw (default: one)
 *
 * @returns on return the sequence numbers will be placed in
 *  column @c I1 of table @c CDB_API_PARAMS ;
 *
 *
 * @ingroup PLSQLAPI
 */
fwConfigurationDB.t_getSequenceNumbers(VARCHAR2 sequenceName, NUMBER n=1);


/** @brief  Input/Output table for the PL/SQL API
 *
 * @ingroup PLSQLAPI
 *
 * CDB_API_PARAMS is a global temporary table used to pass the data from/to
 * the PL/SQL functions contained in the package  @ref PLSQLAPI .
 *
 * The table is used to pass the data which has a form of list of records, such
 * as the list of device names, or a list of settings for a recipe, where
 * device element is specified in one column, and the corresponding setting in another.
 *
 * The fields in the table have no a`priori associated meaning, that is why their names
 * are generic. Each function expects its input data to be present in certain columns,
 * and delivers the output into certain columns - the actual assignment (or: meaning)
 * for each column is provided in the description of each procedure.
 *
 * Being a temporary table, CDB_API_PARAMS does not occupy disk space: it is created in
 * the memory of the database server, and the data contained in it persist
 * only within a session. That also means that separate database sessions 
 * (connected to the same database schema) will refer to their private
 * instances of CDB_API_PARAMS, and will not see/alter the data in the
 * instances belonging to other sessions.
 *
 * The CDB_API_PARAMS table preserves it contents when a commit operation
 * is performed. This is to be able to feed the results returned by one
 * PL/SQL procedure as an input to another. A user should
 * remember to truncate this table before calling a PL/SQL procedure,
 * if he wants to assure the consistency of the data passed into the
 * procedure, using the SQL statement:
 * @code
 *	DELETE FROM CDB_API_PARAMS;
 * @endcode
 * For safety, some data-integrity checking mechanisms are built into
 * a majority of functions in the package; calling a procedure without
 * cleaning up this I/O table will end up in an error.
 *
 */
struct CDB_API_PARAMS {

    NUMBER I1; //!< generic integer parameter, usually an index
    NUMBER I2; //!< generic integer parameter
    NUMBER I3; //!< generic integer parameter
    NUMBER I4; //!< generic integer parameter
    NUMBER I5; //!< generic integer parameter
    NUMBER I6; //!< generic integer parameter
    NUMBER I7; //!< generic integer parameter
    NUMBER I8; //!< generic integer parameter
    VARCHAR2[512] S1; //!< string parameter; typically contains a device name
    VARCHAR2[512] S2; //!< string parameter
    VARCHAR2[256] S3; //!< string parameter
    VARCHAR2[256] S4; //!< string parameter
    VARCHAR2[256] S5; //!< string parameter
    VARCHAR2[256] S6; //!< string parameter
    VARCHAR2[4000] S7; //!< long string parameter
    VARCHAR2[4000] S8; //!< long string parameter
    VARCHAR2[16] S9; //!< short string parameter
    VARCHAR2[16] S10; //!< short string parameter
    DATE D1; //!< date/time parameter, typicaly the start time (beginning of IOV)
    DATE D2; //!< date/time parameter, typicaly the end time (end of IOV)
    BLOB B1; //!< blob parameter
};



//______________________________________________________________________________
