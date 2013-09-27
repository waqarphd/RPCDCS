/**@file

This library contains function associated with the Unit part of the common config.
Functions allows to set, get and delete the unit of a dpe or multiple dpes

@par Creation Date
	07/07/2004

@par Modification History
	23/03/2005 - Milosz Hulboj - addition of prototype for browsing DIP hierarchy
	
@par Constraints
	None

@par Usage
	Public

@par PVSS managers
	VISION, CTRL

@author 
	Oliver Holme (IT-CO)
*/


//@{

//New API manager supports both 0x1a (unprintable char) and ! as seperators
//0x1a caused problems with ASCII export/import so is now obsolete
char fwDIP_SEPERATOR = "!";
char fwDIP_SEPERATOR_OBSOLETE = 0x1a;

int fwDIP_DRIVER_NUMBER = 13;

int fwDIP_OBJECT_DPES = 1;
int fwDIP_OBJECT_ITEM = 2;
int fwDIP_OBJECT_TAGS = 3;
int fwDIP_OBJECT_UPDATE_RATES = 4;

string fwDIP_CONFIG_DPT = "_FwDipConfig";
string fwDIP_CONFIG_CLIENT_DPE = "clientConfig";
string fwDIP_CONFIG_SERVER_DPE = "serverConfig";
string fwDIP_CONFIG_SERVER_DISABLED_DPE = "serverConfigDisabled";

string fwDIP_DEFAULT_TAG = "__DIP_DEFAULT__";
string fwDIP_SELFTEST_DPE = "_MemoryCheck.FreeKB"; // DPE for checking the API manager state

/* How long to wait for the response from the API-manager, before the TIMEOUT occurs */
int fwDIPBrowser_TIMEOUT = 20;

/* Status codes returned by the API manager */
int fwDIPBrowser_ResultType_ERROR 				= 0; /* Something is wrong - invalid address or publication not defined */
int fwDIPBrowser_ResultType_BRANCH				= 1; /* The given address points to a branch */
int fwDIPBrowser_ResultType_LEAF  				= 2; /* The given address points to a leaf (publication) */
int fwDIPBrowser_ResultType_LEAFBRANCH 		= 3; /* The given address points to a branch
																									that is also a publication */
																									
//string ApiManagerDp = "DIPConfig_1"; // temporary - for testing
string fwDIPBrowser_InitialAddress;
//@}


//@{
/** Function to publish a structured DIP publication

@par Constraints
	None

@par Usage
	Public

@par PVSS managers
	VISION, CTRL

@param item						input, the name of the DIP item
@param dpes						input, the list of dpes that combine to form the DIP item
@param tags						input, the tag names for the data coming from the dpes listed
@param updateRate			input, the required value for the buffer time - zero means data is sent on any change of any dpe 
@param configDp				input, the name of the DIP configDp to which to save the configuration
@param exceptionInfo	output, details of any exceptions are returned here
@param overwrite			Optional parameters, default value FALSE.  If TRUE, any previous configuration for the item is overwritten.
*/
fwDIP_publishStructure(string item, dyn_string dpes, dyn_string tags, int updateRate, string configDp, dyn_string &exceptionInfo, bool overwrite = FALSE)
{
	bool isConfigured;
	int currentUpdateRate, i, length;
	string configEntry, currentConfigDp, currentConfigEntry;
	dyn_string entriesToRemove, currentDpes, currentTags;

	if(strpos(configDp, ".") != (strlen(configDp) - 1))
		configDp += ".";
	configDp += fwDIP_CONFIG_SERVER_DPE;

	length = dynlen(dpes);
	for(i=1; i<=length; i++)
	{
		if(dpes[i] == dpSubStr(dpes[i], DPSUB_DP_EL))
			dpes[i] = getSystemName() + dpes[i];
	}

	// Strip the leading 'slashes'
	item = strltrim(item,"/");
	
	fwDIP_getItemPublication(item, isConfigured, currentDpes, currentTags, currentUpdateRate, currentConfigDp, exceptionInfo);
	if(isConfigured)
	{
		if(!overwrite)
		{
			fwException_raise(exceptionInfo, "ERROR", "The DIP item \"" + item + "\" is already being published.  To reconfigure, you must first unpublish.", "");
			return;
		}
		if(strrtrim(currentConfigDp, ".") == strrtrim(configDp, "."))
		{
			_fwDIP_constructPublishConfigEntry(item, currentDpes, currentTags, currentUpdateRate, currentConfigEntry, exceptionInfo);
			dynAppend(entriesToRemove, currentConfigEntry);
		}
		else
			fwDIP_unpublish(item, exceptionInfo);
	}

	_fwDIP_constructPublishConfigEntry(item, dpes, tags, updateRate, configEntry, exceptionInfo);
	_fwDIP_modifyConfigList(makeDynString(configEntry), entriesToRemove, configDp, exceptionInfo);
}


/** Function to publish a primitive DIP publication

@par Constraints
	None

@par Usage
	Public

@par PVSS managers
	VISION, CTRL

@param item						input, the name of the DIP item
@param dpe						input, the dpe that contains the data for the item
@param updateRate			input, the required value for the buffer time - zero means data is sent on any change of any dpe 
@param configDp				input, the name of the DIP configDp to which to save the configuration
@param exceptionInfo	output, details of any exceptions are returned here
@param overwrite			Optional parameters, default value FALSE.  If TRUE, any previous configuration for the item is overwritten.
*/
fwDIP_publishPrimitive(string item, string dpe, int updateRate, string configDp, dyn_string &exceptionInfo, bool overwrite = FALSE)
{
	fwDIP_publishStructure(item, makeDynString(dpe), makeDynString(""), updateRate, configDp, exceptionInfo, overwrite);
}


/** Function to delete the configuration of a DIP publication

@par Constraints
	None

@par Usage
	Public

@par PVSS managers
	VISION, CTRL

@param publicationName		input, the name of the DIP item that currently published and you want to remove
@param exceptionInfo			output, details of any exceptions are returned here
*/
fwDIP_unpublish(string publicationName, dyn_string &exceptionInfo)
{
	bool isConfigured;
	int i, length, updateRate;
	string item, configDp;
	dyn_string dpes, tagNames, configList, newList;

	_fwDIP_checkIsItemPublished(publicationName, isConfigured, configDp, exceptionInfo);
	if(strpos(configDp, ".") != (strlen(configDp) - 1))
		configDp += ".";
	configDp = configDp + fwDIP_CONFIG_SERVER_DPE;
	if(isConfigured)
	{
		_fwDIP_getConfigList(configDp, configList, exceptionInfo);

		length = dynlen(configList);
		for(i=1; i<=length; i++)
		{
			_fwDIP_deconstructPublishConfigEntry(configList[i], item, dpes, tagNames, updateRate, exceptionInfo);
			if(item != publicationName)
				dynAppend(newList, configList[i]);
		}

		_fwDIP_setConfigList(configDp, newList, exceptionInfo);
	}
}


/** Unpublish all publications currently configured in the specific DIP configuration DP

@par Constraints
	None

@par Usage
	Public

@par PVSS managers
	VISION, CTRL

@param configDp          input, the name of the DIP configDp to work on
@param exceptionInfo     output, details of any exceptions are returned here
*/
fwDIP_unpublishAll(string configDp, dyn_string &exceptionInfo)
{
  if(strpos(configDp, ".") != (strlen(configDp) - 1))
    configDp += ".";
  configDp = configDp + fwDIP_CONFIG_SERVER_DPE;

  _fwDIP_setConfigList(configDp, makeDynString(), exceptionInfo);
}


/** Function to subscribe a dpe to a primitive DIP publication

@par Constraints
	None

@par Usage
	Public

@par PVSS managers
	VISION, CTRL

@param item						input, the name of the DIP item to subscribe to
@param dpe						input, the dpe that the received data will be written to
@param configDp				input, the name of the DIP configDp to which to save the configuration
@param exceptionInfo	output, details of any exceptions are returned here
@param overwrite			Optional parameters, default value FALSE.  If TRUE, any previous configuration for the item is overwritten.
*/
fwDIP_subscribePrimitive(string item, string dpe, string configDp, dyn_string &exceptionInfo, bool overwrite = FALSE)
{
	fwDIP_subscribeMany(makeDynString(dpe), configDp, makeDynString(item), makeDynString(fwDIP_DEFAULT_TAG), exceptionInfo, overwrite);
}


/** Function to subscribe several dpes to a structured DIP publication

@par Constraints
	None

@par Usage
	Public

@par PVSS managers
	VISION, CTRL

@param item						input, the name of the DIP item to subscribe to
@param dpes						input, the list of dpes that the received data will be written to
@param tags						input, a list of the tags to read from the DIP item, corresponding to the list of dpes
												(i.e. the data of which tag goes to which dpe)
@param configDp				input, the name of the DIP configDp to which to save the configuration
@param exceptionInfo	output, details of any exceptions are returned here
@param overwrite			Optional parameters, default value FALSE.  If TRUE, any previous configuration for the item is overwritten.
*/
fwDIP_subscribeStructure(string item, dyn_string dpes, dyn_string tags, string configDp, dyn_string &exceptionInfo, bool overwrite = FALSE)
{
	dyn_string items;
	for(int i=1; i<=dynlen(dpes); i++)
		dynAppend(items,item);
	fwDIP_subscribeMany(dpes, configDp, items, tags, exceptionInfo, overwrite);
}


/** Subscribe many dpes to the given DIP publications and tags

@par Constraints
	None

@par Usage
	Public

@par PVSS managers
	VISION, CTRL

@param dpes						input, the list of dpes that the subscribed data will be written to
@param configDp				input, the name of the DIP configDp to which to save the configuration
@param items					input, a list of the DIP items that each dpe will be subscribed to
@param tags						input, a list of the tags to read from the DIP item, corresponding to the list of dpes
												(i.e. the data of which tag goes to which dpe)
												if an entry in items is a primitive publication then the corresponding value in tags should be ""
@param exceptionInfo	output, details of any exceptions are returned here
@param overwrite			Optional parameters, default value FALSE.  If TRUE, any previous configuration for the item is overwritten.
*/
fwDIP_subscribeMany(dyn_string dpes, string configDp, dyn_string items, dyn_string tags, dyn_string &exceptionInfo, bool overwrite = FALSE)
{
	bool isRunning;
	dyn_bool isConfigured;
	int i, length;
	dyn_string addresses, dpesToSet, dpesToAddToConfigList, configDps;		

	if(strpos(configDp, ".") != (strlen(configDp) - 1))
		configDp += ".";
	configDp += fwDIP_CONFIG_CLIENT_DPE;
	if(dynContains(dpes,"")!=0)
	{
		fwException_raise(exceptionInfo, "ERROR", "One or many blank dpes addresses passed.", "");
	}

	length = dynlen(dpes);
	for(i=1; i<=length; i++)
	{
		if(dpes[i] == dpSubStr(dpes[i], DPSUB_DP_EL))
			dpes[i] = getSystemName() + dpes[i];
	}

	length = dynlen(tags);
	for(i=1; i<=length; i++)
	{
		if(tags[i] == "")
			tags[i] = fwDIP_DEFAULT_TAG;
	}

        _fwDIP_checkIsSimRunning(isRunning, exceptionInfo);
	if(!isRunning)
	{
		fwException_raise(exceptionInfo, "ERROR", "The DIP Simulation driver (number "+fwDIP_DRIVER_NUMBER+") is not running", "");
		return;
	}
	

	_fwDIP_checkIsDpeListSubscribed(dpes, isConfigured, configDps, exceptionInfo);

	length = dynlen(items);
	for(i=1; i<=length; i++)
	{
		if(!overwrite && isConfigured[i])
			fwException_raise(exceptionInfo, "ERROR", "The data point \"" + dpes[i] + "\" is already configured for DIP.  To reconfigure, you must first unsubscribe.", "");
		else
		{
			if(tags[i] == "")
				dynAppend(addresses, items[i]);
			else
				dynAppend(addresses, items[i] + fwDIP_SEPERATOR + tags[i]);

			dynAppend(dpesToSet, dpes[i]);
//DebugN(strrtrim(configDps[i], "."), strrtrim(configDp, "."));
			if(strrtrim(configDps[i], ".") != strrtrim(configDp, "."))
				dynAppend(dpesToAddToConfigList, dpes[i]);
		}	
	}

	fwDIP_unsubscribeMany(dpesToAddToConfigList, exceptionInfo);
//	DebugN(dpesToSet,addresses,dpesToAddToConfigList,configDp);
	_fwDIP_setManyAddressConfig(dpesToSet, addresses, exceptionInfo);
	_fwDIP_modifyConfigList(dpesToAddToConfigList, makeDynString(), configDp, exceptionInfo);
}


/** Subscribe a single dpe to a DIP publication and tag

@par Constraints
	None

@par Usage
	Public

@par PVSS managers
	VISION, CTRL

@param dpe						input, the dpe that the subscribed data will be written to
@param configDp				input, the name of the DIP configDp to which to save the configuration
@param item						input, the DIP item that the dpe will be subscribed to
@param tag						input, the tag to read from the DIP item
												if the item is a primitive publication then the value of tag should be ""
@param exceptionInfo	output, details of any exceptions are returned here
@param overwrite			Optional parameters, default value FALSE.  If TRUE, any previous configuration for the item is overwritten.
*/
fwDIP_subscribe(string dpe, string configDp, string item, string tag, dyn_string &exceptionInfo, bool overwrite = FALSE)
{
	fwDIP_subscribeMany(makeDynString(dpe), configDp, makeDynString(item), makeDynString(tag), exceptionInfo, overwrite);
}


/** Remove DIP subscription info from config dp

@par Constraints
	None

@par Usage
	Internal

@par PVSS managers
	VISION, CTRL

@param dpes						input, the dpes for which any DIP subscription should be deleted.
@param exceptionInfo	output, details of any exceptions are returned here
*/
_fwDIP_removeSubscription(dyn_string dpes, dyn_string &exceptionInfo)
{
	dyn_bool isConfigured;
	int i, length, configDpNumber = 1;
	mapping configDps;
	dyn_string configDp;
	dyn_dyn_string currentConfig;
	
	length = dynlen(dpes);
	for(i=1; i<=length; i++)
	{
		if(dpes[i] == dpSubStr(dpes[i], DPSUB_DP_EL))
			dpes[i] = getSystemName() + dpes[i];
	}

	_fwDIP_checkIsDpeListSubscribed(dpes, isConfigured, configDp, exceptionInfo);

	length = dynlen(dpes);
	for(i=1; i<=length; i++)
	{
		if(isConfigured[i])
		{
			if(!mappingHasKey(configDps, configDp[i]))
			{
				configDps[configDp[i]] = configDpNumber;
				configDpNumber++;
			}
			
			dynAppend(currentConfig[configDps[configDp[i]]], dpes[i]);
		}
	}
		
	length = mappinglen(configDps);
	for(i=1; i<=length; i++)
	{
		configDp = mappingGetKey(configDps, i);
		_fwDIP_modifyConfigList(makeDynString(), dpes[i], configDp, exceptionInfo);
	}
}


/** Unsubscribe many dpes from DIP publications
This function deletes information from the DIP config dp and also clears the address config.
You should not unsubscribe many items while the DIP manager is running - doing so may produce a lot of errors in the log.
If you need to unsubscribe without stopping the DIP manager it is recommended to use fwDIP_unsubscribe() with a delay
between each call.

@par Constraints
	None

@par Usage
	Public

@par PVSS managers
	VISION, CTRL

@param dpes						input, the dpes for which any DIP subscription should be deleted.
@param exceptionInfo	output, details of any exceptions are returned here
*/
fwDIP_unsubscribeMany(dyn_string dpes, dyn_string &exceptionInfo)
{
	fwPeriphAddress_deleteMultiple(dpes, exceptionInfo);
	if(dynlen(exceptionInfo)!=0)
		return;
	_fwDIP_removeSubscription(dpes, exceptionInfo);
}


/** Unsubscribe a single dpe from a DIP publication
This function deletes information from the DIP config dp and also clears the address config.

@par Constraints
	None

@par Usage
	Public

@par PVSS managers
	VISION, CTRL

@param dpe						input, the dpe for which any DIP subscription should be deleted.
@param exceptionInfo	output, details of any exceptions are returned here
*/
fwDIP_unsubscribe(string dpe, dyn_string &exceptionInfo)
{
	fwPeriphAddress_delete(dpe, exceptionInfo);
	if(dynlen(exceptionInfo)!=0)
		return;
	_fwDIP_removeSubscription(makeDynString(dpe), exceptionInfo);
}


/** Unsubscribe all subscriptions currently configured in the specific DIP configuration DP

@par Constraints
	None

@par Usage
	Public

@par PVSS managers
	VISION, CTRL

@param configDp          input, the name of the DIP configDp to work on
@param exceptionInfo     output, details of any exceptions are returned here
*/
fwDIP_unsubscribeAll(string configDp, dyn_string &exceptionInfo)
{
  dyn_string dpes;
  
  if(strpos(configDp, ".") != (strlen(configDp) - 1))
    configDp += ".";
  configDp = configDp + fwDIP_CONFIG_CLIENT_DPE;

  _fwDIP_getConfigList(configDp, dpes, exceptionInfo);
  fwPeriphAddress_deleteMultiple(dpes, exceptionInfo);
  if(dynlen(exceptionInfo)!=0)
    return;

  _fwDIP_setConfigList(configDp, makeDynString(), exceptionInfo);
}


/** Get the current subscription info for a dpe

@par Constraints
	None

@par Usage
	Public

@par PVSS managers
	VISION, CTRL

@param dpe						input, the dpe for which the DIP subscription should be read
@param isConfigured		output, TRUE is dpe is subscribed to DIP data, else FALSE
@param configDp				output, the DIP config dp that contains the details of the subscription
@param address				output, the address string in the form dipItem + fwDIP_SEPERATOR + dipTag
@param exceptionInfo	output, details of any exceptions are returned here
*/
fwDIP_getDpeSubscription(string dpe, bool &isConfigured, string &configDp, string &address, dyn_string &exceptionInfo)
{
	_fwDIP_checkIsDpeSubscribed(dpe, isConfigured, configDp, exceptionInfo);

	if(isConfigured)
		_fwDIP_getAddressConfig(dpe, address, exceptionInfo);
	else
		address = "";
}


/** Get the current publication info for a given DIP publication

@par Constraints
	None

@par Usage
	Public

@par PVSS managers
	VISION, CTRL

@param dipItem				input, the DIP item to look for and get its current configuration details
@param isConfigured		output, TRUE if the DIP item is published, FALSE if no configuration exists
@param dpes						output, the list of dpes which are used as the data source for the DIP publication
@param tags						output, the list of tags, corresponding to each dpe, that forms the structure of the DIP publication
@param updateRate			output, the current setting of the buffer time
@param configDp				output, the DIP config dp which contains the configuration data for the item
@param exceptionInfo	output, details of any exceptions are returned here
*/
fwDIP_getItemPublication(string dipItem, bool &isConfigured, dyn_string &dpes, dyn_string &tags, int &updateRate, string &configDp, dyn_string &exceptionInfo)
{
	int i, length, j, numberOfPubs, tempUpdateRate;
	string publicationName;
	dyn_string configDpsList, configList, tempDpes, tempTags;

	isConfigured = FALSE;
	configDpsList = dpNames("*:*", fwDIP_CONFIG_DPT);
	
	length = dynlen(configDpsList);
	for(i=1; i<=length; i++)
	{
		_fwDIP_getConfigList(configDpsList[i]+".serverConfig", configList, exceptionInfo);
	
		numberOfPubs = dynlen(configList);
		for(j=1; j<=numberOfPubs; j++)
		{
			_fwDIP_deconstructPublishConfigEntry(configList[j], publicationName, tempDpes, tempTags, tempUpdateRate, exceptionInfo);
			if(publicationName == dipItem)
			{
				isConfigured = TRUE;
				dpes = tempDpes;
				tags = tempTags;
				updateRate = tempUpdateRate;
				configDp = configDpsList[i];
				return;
			}
		}
	}
}


/** Check to see if a DIP item is already published

@par Constraints
	None

@par Usage
	Internal

@par PVSS managers
	VISION, CTRL

@param item						input, the DIP item to look for
@param isConfigured		output, TRUE if the DIP item is published, FALSE if no configuration exists
@param configDp				output, the DIP config dp which contains the configuration data for the item
@param exceptionInfo	output, details of any exceptions are returned here
*/
_fwDIP_checkIsItemPublished(string item, bool &isConfigured, string &configDp, dyn_string &exceptionInfo)
{
	int updateRate;
	dyn_string dpes, tags;

	fwDIP_getItemPublication(item, isConfigured, dpes, tags, updateRate, configDp, exceptionInfo);
}


/** Check to see if the dpes in a list are already subscribed

@par Constraints
	None

@par Usage
	Internal

@par PVSS managers
	VISION, CTRL

@param dpes						input, the list of dpes to look for
@param isConfigured		output, a list of BOOLs, TRUE if the dpe is subscribed to DIP data, else FALSE
@param configDps				output, the list of DIP config dps which contain the configuration data for the dpes
@param exceptionInfo	output, details of any exceptions are returned here
*/
_fwDIP_checkIsDpeListSubscribed(dyn_string dpes, dyn_bool &isConfigured, dyn_string &configDps, dyn_string &exceptionInfo)
{
	bool found;
	int i, j, length, list;
	dyn_string configDpsList;
	dyn_dyn_string configList;

	length = dynlen(dpes);
	for(i=1; i<=length; i++)
	{
		if(dpes[i] == dpSubStr(dpes[i], DPSUB_DP_EL))
			dpes[i] = getSystemName() + dpes[i];
	}

	configDpsList = dpNames("*:*", fwDIP_CONFIG_DPT);
	
	length = dynlen(configDpsList);
	for(i=1; i<=length; i++)
	{
		_fwDIP_getConfigList(configDpsList[i]+".clientConfig", configList[i], exceptionInfo);
	}
	
	list = dynlen(dpes);
	for(i=1; i<=list; i++)
	{
		found = FALSE;
		
		for(j=1; (j<=length) && (!found); j++)
		{	
			if(dynContains(configList[j], dpes[i])>0)
			{
				isConfigured[i] = TRUE;
				configDps[i] = configDpsList[j]+".clientConfig";
				found = TRUE;
			}
			else
			{
				isConfigured[i] = FALSE;
				configDps[i] = "";
			}
		}
	}
}


/** Check to see if a dpe is already subscribed

@par Constraints
	None

@par Usage
	Internal

@par PVSS managers
	VISION, CTRL

@param dpe						input, the dpe to look for
@param isConfigured		output, TRUE if the dpe is subscribed to DIP data, else FALSE
@param configDp				output, the DIP config dp which contains the configuration data for the dpe
@param exceptionInfo	output, details of any exceptions are returned here
*/
_fwDIP_checkIsDpeSubscribed(string dpe, bool &isConfigured, string &configDp, dyn_string &exceptionInfo)
{
	dyn_bool configured;
	dyn_string config;
	
	_fwDIP_checkIsDpeListSubscribed(makeDynString(dpe), configured, config, exceptionInfo);
	isConfigured = configured[1];
	configDp = config[1];
}


/** Get all current DIP publications for a specific config DP (API manager)
This returns the data in a organised dyn_dyn_string - use fwDIP_OBJECT_... constants to read data out

@par Constraints
	None

@par Usage
	Public

@par PVSS managers
	VISION, CTRL

@param configDp									input, the DIP config dp to read from
@param currentPublicationInfo		output, the DIP publication configuration stored within the data point
																	(use fwDIP_OBJECT_... constants to read data out of here)
@param exceptionInfo						output, details of any exceptions are returned here
*/
fwDIP_getAllPublications(string configDp, dyn_dyn_string &currentPublicationInfo, dyn_string &exceptionInfo)
{
	int i, j, tagNumber, length, updateRate;
	string publicationName;
	dyn_string configList, tagNames, dpes;

	if(strpos(configDp, ".") != (strlen(configDp) - 1))
		configDp += ".";
	configDp += fwDIP_CONFIG_SERVER_DPE;

	_fwDIP_getConfigList(configDp, configList, exceptionInfo);

	length = dynlen(configList);
	for(i=1; i<=length; i++)
	{
		_fwDIP_deconstructPublishConfigEntry(configList[i], publicationName, dpes, tagNames, updateRate, exceptionInfo);
		tagNumber = dynlen(tagNames);
		for(j=1; j<=tagNumber; j++)
		{
			dynAppend(currentPublicationInfo[fwDIP_OBJECT_ITEM], publicationName);
			dynAppend(currentPublicationInfo[fwDIP_OBJECT_UPDATE_RATES], updateRate);
		}
		
		dynAppend(currentPublicationInfo[fwDIP_OBJECT_DPES], dpes);
		dynAppend(currentPublicationInfo[fwDIP_OBJECT_TAGS], tagNames);
	}
}


/** Get all current DIP subscriptions for a specific config DP (API manager)
This returns the data in a organised dyn_dyn_string - use fwDIP_OBJECT_... constants to read data out

@par Constraints
	None

@par Usage
	Public

@par PVSS managers
	VISION, CTRL

@param configDp									input, the DIP config dp to read from
@param currentSubscriptionInfo	output, the DIP subscription configuration stored within the data point
																	(use fwDIP_OBJECT_... constants to read data out of here)
@param exceptionInfo						output, details of any exceptions are returned here
*/
fwDIP_getAllSubscriptions(string configDp, dyn_dyn_string &currentSubscriptionInfo, dyn_string &exceptionInfo)
{
	dyn_string subscribedItems, dpes, items, tags;

	if(strpos(configDp, ".") != (strlen(configDp) - 1))
		configDp += ".";
	configDp += fwDIP_CONFIG_CLIENT_DPE;

	_fwDIP_getConfigList(configDp, dpes, exceptionInfo);
	_fwDIP_getManyAddressConfig(dpes, subscribedItems, exceptionInfo);
	_fwDIP_splitAddresses(subscribedItems, items, tags, exceptionInfo);
//DebugN(dpes, items, tags);

	dynAppend(currentSubscriptionInfo[fwDIP_OBJECT_DPES], dpes);
	dynAppend(currentSubscriptionInfo[fwDIP_OBJECT_ITEM], items);
	dynAppend(currentSubscriptionInfo[fwDIP_OBJECT_TAGS], tags);
}


/** Split address into item name and tag

@par Constraints
	None

@par Usage
	Internal

@par PVSS managers
	VISION, CTRL

@param address					input, the full address string (in the format dipItem + fwDIP_SEPERATOR + dipTag)
@param item							output, the name of the DIP item
@param tag							output, the name of the DIP tag
@param exceptionInfo		output, details of any exceptions are returned here
*/
_fwDIP_splitAddress(string address, string &item, string &tag, dyn_string &exceptionInfo)
{
	dyn_string items, tags;

	_fwDIP_splitAddresses(makeDynString(address), items, tags, exceptionInfo);
	item = items[1];
	tag = tags[1];
}


/** Split many addresses into item names and tags

@par Constraints
	None

@par Usage
	Internal

@par PVSS managers
	VISION, CTRL

@param addresses				input, list of full address strings (in the format dipItem + fwDIP_SEPERATOR + dipTag)
@param items						output, list of names of the DIP items
@param tags							output, list of names of the DIP tags
@param exceptionInfo		output, details of any exceptions are returned here
*/
_fwDIP_splitAddresses(dyn_string addresses, dyn_string &items, dyn_string &tags, dyn_string &exceptionInfo)
{
	int i, length;
	dyn_string addressParts;

	length = dynlen(addresses);
	for(i=1; i<=length; i++)
	{
		if(strpos(addresses[i], fwDIP_SEPERATOR) >= 0)
			addressParts = strsplit(addresses[i], fwDIP_SEPERATOR);
                else
                  addressParts = makeDynString(addresses[i]);
                
		items[i] = addressParts[1];
		
		if(dynlen(addressParts) >= 2)
			tags[i] = addressParts[2];
		else
			tags[i] = "";
	}
}


/** Construct entry for publisher config dp

@par Constraints
	None

@par Usage
	Internal

@par PVSS managers
	VISION, CTRL

@param publicationName		input, the name of the DIP publication item
@param dpes								input, the list of dpes that will act as the source data for the publication
@param tagNames						input, the list of tag names within the DIP item, corresponding to each of the dpes
@param updateRate					input, the buffer time for the DIP publication
@param configEntry				output, the required configDP entry is returned here
@param exceptionInfo			output, details of any exceptions are returned here
*/
_fwDIP_constructPublishConfigEntry(string publicationName, dyn_string dpes, dyn_string tagNames, int updateRate, string &configEntry, dyn_string &exceptionInfo)
{
	int i, length;

	configEntry = "";

	if(dynlen(dpes) != dynlen(tagNames))
	{
		fwException_raise(exceptionInfo, "ERROR", "_fwDIP_constructPublishConfigEntry: The dpe list and tag list must be the same length.", "");
		return;
	}

	configEntry = publicationName + fwDIP_SEPERATOR + updateRate + fwDIP_SEPERATOR;
	
	length = dynlen(dpes);
	for(i=1; i<=length; i++)
	{
		if(tagNames[i] == "")
			configEntry += dpes[i] + fwDIP_SEPERATOR;
		else
			configEntry += dpes[i] + fwDIP_SEPERATOR + tagNames[i] + fwDIP_SEPERATOR;
	}
}


/** Deconstruct entry for publisher config dp

@par Constraints
	None

@par Usage
	Internal

@par PVSS managers
	VISION, CTRL

@param configEntry				input, the configDP entry is given here
@param publicationName		output, the name of the DIP publication item
@param dpes								output, the list of dpes that is the source data for the publication
@param tagNames						output, the list of tag names within the DIP item, corresponding to each of the dpes
@param updateRate					output, the buffer time of the DIP publication
@param exceptionInfo			output, details of any exceptions are returned here
*/
_fwDIP_deconstructPublishConfigEntry(string configEntry, string &publicationName, dyn_string &dpes, dyn_string &tagNames, int &updateRate, dyn_string &exceptionInfo)
{
	int i, length;
	dyn_string parts;
	
	publicationName = "";
	dynClear(dpes);
	dynClear(tagNames);
	updateRate = 0;

	parts = strsplit(configEntry, fwDIP_SEPERATOR);
	length = dynlen(parts);	
	if(length>=3)
	{
		publicationName = parts[1];
		updateRate = parts[2];
	}
	else
	{
          parts = strsplit(configEntry, fwDIP_SEPERATOR_OBSOLETE);
          length = dynlen(parts);	
          if(length>=3)
          {
              publicationName = parts[1];
              updateRate = parts[2];
          }
          else
          {
              fwException_raise(exceptionInfo, "ERROR", "_fwDIP_deconstructPublishConfigEntry: The config entry does not contain enough information.", "");
	      return;
          }
	}
	
	for(i=3; i<=length; i+=2)
	{
		dynAppend(dpes, parts[i]);
		if((i+1) <= length)
			dynAppend(tagNames, parts[i+1]);
		else
			dynAppend(tagNames, "");	
	}
}


/** Read address config _reference attribute for a given dpe

@par Constraints
	None

@par Usage
	Internal

@par PVSS managers
	VISION, CTRL

@param dpe							input, the dpe to read from
@param address					output, the contents of the _reference attribute is returned here
@param exceptionInfo		output, details of any exceptions are returned here
*/
_fwDIP_getAddressConfig(string dpe, string &address, dyn_string &exceptionInfo)
{
	dyn_string addresses;

	_fwDIP_getManyAddressConfig(makeDynString(dpe), addresses, exceptionInfo);
	address = addresses[1];
}


/** Write address config _reference attribute for a given dpe

@par Constraints
	None

@par Usage
	Internal

@par PVSS managers
	VISION, CTRL

@param dpe							input, the dpe to read from
@param address					input, the required contents of the _reference attribute
@param exceptionInfo		output, details of any exceptions are returned here
*/
_fwDIP_setAddressConfig(string dpe, string address, dyn_string &exceptionInfo)
{
	_fwDIP_setManyAddressConfig(makeDynString(dpe), makeDynString(address), exceptionInfo);
}


/** Read address config _reference attribute for a list of dpes

@par Constraints
	None

@par Usage
	Internal

@par PVSS managers
	VISION, CTRL

@param dpes							input, the list of dpes to read from
@param addresses				input, the list of the contents of the _reference attributes is returned here
@param exceptionInfo		output, details of any exceptions are returned here
*/
_fwDIP_getManyAddressConfig(dyn_string dpes, dyn_string &addresses, dyn_string &exceptionInfo)
{
	int i, length;
	dyn_string attributes;
	dyn_string values;
	dyn_mixed attributeValues;

	bool isRunning;
	_fwDIP_checkIsSimRunning(isRunning, exceptionInfo);
	if(!isRunning) 
	{
		fwException_raise(exceptionInfo, "ERROR", "The DIP subscriptions cannot be viewed because the Simulation Driver num 13 is not running!", "");
		return;
	}

	// Group the dpes by the system (and check whether they exist)
	mapping checkedDpes;
	for(i=1; i<=dynlen(dpes); i++)
	{
		string sys;
		if(dpExists(dpes[i]))
		{
			sys = dpSubStr(dpes[i],DPSUB_SYS);
			dyn_string tmp;
			if(mappingHasKey(checkedDpes,sys))
				tmp = checkedDpes[sys];
			dynAppend(tmp, dpes[i]);
			checkedDpes[sys] = tmp;
		}
	}
	
	// For each group of dpes containing the config, obtain the :_address.._reference
	dyn_string keys = mappingKeys(checkedDpes);
	for(i=1; i<=dynlen(keys); i++)
	{
		dyn_string sysDpes = checkedDpes[keys[i]];
		dyn_string sysAttributes;
		dyn_string sysValues;
		_fwConfigs_getConfigTypeAttribute(sysDpes, fwConfigs_PVSS_ADDRESS, attributeValues, exceptionInfo);

		for(int j=1; j<=dynlen(sysDpes); j++)
		{
			if(attributeValues[j]!=DPCONFIG_NONE)
				dynAppend(sysAttributes, sysDpes[j] + ":_address.._reference");
		}
		dpGet(sysAttributes, sysValues);
		
		// Store everything in order (to match the dpes order)
		for(int j=1; j<=dynlen(sysAttributes); j++)
		{
			strreplace(sysAttributes[j],":_address.._reference","");
			int position = dynContains(dpes, sysAttributes[j] );
			if(position>0)
				addresses[position] = sysValues[j];
		}
//		dynAppend(addresses, sysValues);
	}


/*	
	dyn_string checkedDpes;
	
	for(i=1;i<=dynlen(dpes); i++)
	{
		if(dpExists(dpes[i]))
			dynAppend(checkedDpes,dpes[i]);
	}

	_fwConfigs_getConfigTypeAttribute(checkedDpes, fwConfigs_PVSS_ADDRESS, attributeValues, exceptionInfo);

	length = dynlen(checkedDpes);
	for(i=1; i<=length; i++)
	{
		if(attributeValues[i]!=DPCONFIG_NONE)
		{
			dynAppend(attributes, checkedDpes[i] + ":_address.._reference");
		}
	}
	dpGet(attributes, values);
//  DebugN("Read", values);	
	addresses = values;
*/
}


/** Write many address config _reference attributes for a given list of dpes

@par Constraints
	None

@par Usage
	Internal

@par PVSS managers
	VISION, CTRL

@param dpes							input, the dpe to read from
@param addresses				input, the list of the required contents of the _reference attributes
@param exceptionInfo		output, details of any exceptions are returned here
*/
_fwDIP_setManyAddressConfig(dyn_string dpes, dyn_string addresses, dyn_string &exceptionInfo)
{
	int i, length;
	dyn_string attributes, tempAttributes;
	dyn_mixed settings, tempSettings;
	dyn_errClass errors;

//DebugN(dpes, driverNumbers, addresses);	
	length = dynlen(dpes);
	for(i=1; i<=length; i++)
	{
		tempAttributes[1] = dpes[i] + ":_distrib.._type";
		tempAttributes[2] = dpes[i] + ":_distrib.._driver";
		
		tempSettings[1] = DPCONFIG_DISTRIBUTION_INFO;
		tempSettings[2] = fwDIP_DRIVER_NUMBER;
							
		dynAppend(attributes, tempAttributes);
		dynAppend(settings, tempSettings);
		
		if((dynlen(attributes) > fwConfigs_OPTIMUM_DP_SET_SIZE) || (i == length))
		{
//DebugN(attributes, settings);	
			dpSetWait(attributes, settings);
			errors = getLastError();
			
			dynClear(attributes);
			dynClear(settings);
		}
	}
	
	for(i=1; i<=length; i++)
	{
		tempAttributes[1] = dpes[i] + ":_address.._type";
		tempAttributes[2] = dpes[i] + ":_address.._drv_ident";
		tempAttributes[3] = dpes[i] + ":_address.._reference";

		tempSettings[1] = DPCONFIG_PERIPH_ADDR_MAIN;
		tempSettings[2] = "DIP";
		tempSettings[3] = addresses[i];
					
		dynAppend(attributes, tempAttributes);
		dynAppend(settings, tempSettings);
		
		if((dynlen(attributes) > fwConfigs_OPTIMUM_DP_SET_SIZE) || (i == length))
		{
//DebugN(attributes, settings);	
//DebugN("Write", settings);	
			dpSetWait(attributes, settings);
			errors = getLastError();
			
			dynClear(attributes);
			dynClear(settings);
		}
	}

}


/** Add and remove entries in a config list in one go to remove the need for multiple dpSets

@par Constraints
	None

@par Usage
	Internal

@par PVSS managers
	VISION, CTRL

@param newEntries				input, the new entries to go in the config dp
@param entriesToDelete	input, any entries to be deleted from the config dp
@param configDpe				input, the DIP config dp to act on
@param exceptionInfo		output, details of any exceptions are returned here
*/
_fwDIP_modifyConfigList(dyn_string newEntries, dyn_string entriesToDelete, string configDpe, dyn_string &exceptionInfo)
{
	int i, length, position;
	dyn_string configList;

	_fwDIP_getConfigList(configDpe, configList, exceptionInfo);

	length = dynlen(entriesToDelete);
	for(i=1; i<=length; i++)
	{
		position = dynContains(configList, entriesToDelete[i]);
		if(position > 0)
			dynRemove(configList, position);
	}
	
	dynAppend(configList, newEntries);
	dynUnique(configList);

	_fwDIP_setConfigList(configDpe, configList, exceptionInfo);
}


/** Read config info for a given config dp

@par Constraints
	None

@par Usage
	Internal

@par PVSS managers
	VISION, CTRL

@param configDp					input, the DIP config dp to read from
@param configList				output, the contents of the config DP is returned here as a simple list
@param exceptionInfo		output, details of any exceptions are returned here
*/
_fwDIP_getConfigList(string configDp, dyn_string &configList, dyn_string &exceptionInfo)
{
	dyn_string result;
	
	if(strpos(configDp,".serverConfig")>=0)
	{
		dpGet(configDp, configList);
	}
	else
	{
		dpGet(configDp, result);
		for(int i=1; i<=dynlen(result); i++)
			if(dpExists(result[i]))
				dynAppend(configList, result[i]);
	}
	
}


/** Write config info for a given config dp

@par Constraints
	None

@par Usage
	Internal

@par PVSS managers
	VISION, CTRL

@param configDp					input, the DIP config dp to write to
@param configList				input, the contents of the config DP is passed here as a simple list
@param exceptionInfo		output, details of any exceptions are returned here
*/
_fwDIP_setConfigList(string configDp, dyn_string configList, dyn_string &exceptionInfo)
{
	dyn_errClass errors;
        string configDpDisabled;
        
        //check if disabled server config has entries, if so do not people edit the active server config
//        DebugN(strpos(configDp, fwDIP_CONFIG_SERVER_DPE), strlen(configDp), strlen(fwDIP_CONFIG_SERVER_DPE));
        if(strpos(configDp, fwDIP_CONFIG_SERVER_DPE) == (strlen(configDp) - strlen(fwDIP_CONFIG_SERVER_DPE)))
        {
          if(fwDIP_isServerConfigDisabled(configDp, exceptionInfo))
          {
            fwException_raise(exceptionInfo, "ERROR", "You can not modify this DIP configuration. "
                              + "It has been disabled.  Please open the fwDIP configuration panel to correct this.", "");
            return;
          }
        }
          
	dpSetWait(configDp, configList); 
	errors = getLastError();
}


/** Checks if necessary SIM driver is running to access the DIP address configs

@par Constraints
	None

@par Usage
	Internal

@par PVSS managers
	VISION, CTRL

@param isRunning				output, TRUE is the necessary SIM manager is running, else FALSE
@param exceptionInfo		output, details of any exceptions are returned here
*/
_fwDIP_checkIsSimRunning(bool &isRunning, dyn_string &exceptionInfo)
{
	fwPeriphAddress_checkIsDriverRunning(fwDIP_DRIVER_NUMBER, isRunning, exceptionInfo);
}



/**

This function issues the query to the relevant API manager via specified DP
It writes the starting address for the API manager and then waits until
the results are provided by the API manager or the timeout occurs.

@par Constraints
	None

@par Usage
	Internal

@par PVSS managers
	VISION, CTRL

@param DipDP: DP for communication with API manager
@param address: starting address - for the querying the DIP hierarchy
@param childName: list of children of the given node
@param childType: specifies the type of a given child node:
								1 - leaf
								2 - branch
								3 - both
@param fieldName	 list of publication fields in a given node
@param fieldType	 data type of a publication field
@param exceptionInfo		output, details of any exceptions are returned here
@param timeout	 number of seconds to wait for the result
@return status	 type of the <B>queried</B> node
*/

int fwDIP_DipQuery(string DipDP,
										  string address,
											dyn_string &childName, dyn_int &childType,
											dyn_string &fieldName, dyn_int &fieldType,
											dyn_string &exceptionInfo,
											int timeout = fwDIPBrowser_TIMEOUT)
{
	dyn_anytype conditions, result;
	bool isTimeout;
	int status;
	int locked;
	
	dpGet(DipDP+".command.startPoint:_lock._original._locked", locked);
	if (locked == 1)
	{
		DebugN("startPoint locked by someone");
		fwException_raise(exceptionInfo, "ERROR", "StartPoint is being locked by other manager.",""); 
		return 0;
	}
	
	
	/* Lock the command.startPoint dpe */
	//dpSet(DipDP+".command.startPoint:_lock._original._locked", 1);
	_fwDIP_lockBrowserDpe(DipDP);
//	DebugN("Locked");
	
	/* Write into the startPoint dp */
	dpSet(DipDP+".command.startPoint:_original.._value", address);
		
	/* Wait for the result or the timeout - we will be watching for the change
	 * to the status dp
	 */
	dpWaitForValue(makeDynString(DipDP+".response.browseStatusDpeID:_original.._stime"),
								 conditions,
								 makeDynString(DipDP+".response.browseStatusDpeID:_original.._value"),
								 result,
								 timeout,
								 isTimeout);
//	DebugN("After dpWaitForValue()\n Result:"+result);
		
	if (isTimeout)
	{
		DebugN("Timeout, unlock");
		//dpSet(DipDP+".command.startPoint:_lock._original._locked", 0);
		_fwDIP_unlockBrowserDpe(DipDP);
		fwException_raise(exceptionInfo, "ERROR", "Timeout occured when trying to query for DIP address: " + address + " via DP:" + DipDP, ""); 
		return 0;
	}
	
	status = result[1];
	if (status == 0)
	{
//		DebugN("status == 0, unlock");
		//dpSet(DipDP+".command.startPoint:_lock._original._locked", 0);
		_fwDIP_unlockBrowserDpe(DipDP);
		fwException_raise(exceptionInfo, "ERROR", "No valid data returned for DIP address: " + address + " via DP:" + DipDP, ""); 
		return 0;
	}

	/* Get the data */
	dpGet(DipDP+".response.childName", childName,
				DipDP+".response.childType", childType,
				DipDP+".response.fieldName", fieldName,
				DipDP+".response.fieldType", fieldType);

	/* Unlock the command dpe */
//	DebugN("Unlock");
	//dpSet(DipDP+".command.startPoint:_lock._original._locked", 0);
	_fwDIP_unlockBrowserDpe(DipDP);
	return status;
}

/**

This function locks the dpe through which requests for querying the API manager
are issued.

@par Constraints
	None

@par Usage
	Internal

@par PVSS managers
	VISION, CTRL

@param DipDP DP for communication with API manager
@param referenceName	- NOT USED, default value = ""
*/


_fwDIP_lockBrowserDpe(string DipDP, string referenceName="")
{
	dpSet(DipDP+".command.startPoint:_lock._original._locked", 1);
}

/**

This function unlocks the dpe through which requests for querying the API manager
are issued.

@par Constraints
	None

@par Usage
	Internal

@par PVSS managers
	VISION, CTRL

@param DipDP: DP for communication with API manager
@param referenceName	- NOT USED, default value = ""
*/


_fwDIP_unlockBrowserDpe(string DipDP, string referenceName="")
{
	dpSet(DipDP+".command.startPoint:_lock._original._locked", 0);
}


/**

This function checks if given dpe exists, and then if it exists, it checks whether
it has the original value. It is suggested to check dpes this way before publishing

@par Constraints
	None

@par Usage
	Internal

@par PVSS managers
	VISION, CTRL

@param dpe dpe to check
@param exceptionInfo	output, details of any exceptions are returned here
*/

bool _fwDIP_checkDpeForPublication(string dpe, dyn_string &exceptionInfo)
{
	string elementType; 
	if(!dpExists(dpe))
	{
		fwException_raise(exceptionInfo, "ERROR", "The dpe: "+dpe+" does not exist!", "");
		return false;
	}
	_fwConfigs_getConfigOptionsForDpe(dpe, fwConfigs_PVSS_ADDRESS, elementType, exceptionInfo);
	if(elementType == fwConfigs_NOT_SUPPORTED)
	{
		fwException_raise(exceptionInfo, "ERROR", "The dpe: "+dpe+" does not have an original value.  No data can be published from this data point element.", "");
		return false;
	}
	return true;
}


/**

This function initializes the tree with the first level of DIP hierarchy
starting with a specified string.

Modification History:

Constraints: Must be used from within fwDIPHierarchyBrowser, which in turn
obtains the dollar parameters with the data about children and their type.
This has been done in order to remove the necessity of performing additional
DIP query.

Usage: JCOP Framework internal
PVSS manager usage: VISION

*/
fwDIPBrowser_initDIPTreeBrowser()
{	
//	DebugN("->fwDIPBrowser_initDIPTreeBrowser()");

	dyn_string exceptionInfo;

	fwDIPBrowser_InitialAddress = InitialAddress.text; /* Workaround of passing the parameters
																												any better ideas */
	
	dyn_string childName;
	dyn_int childType;
	
	string tmp1, tmp2;
	
	tmp1 = sChildName.text; /* Same as above */
	tmp2 = iChildType.text;
	
	childName = strsplit(tmp1, "|"); /* get the data into dyn_string */
	childType = strsplit(tmp2, "|"); /* get the data into dyn_int */

	dyn_anytype node;
	int i;
	int position = 1;

	int howMany = dynlen(childName);
	tmp1 = iResultType.text;
	int resultType = tmp1;

	node[fwTreeView_STATE] = fwTreeView_BRANCH | fwTreeView_EXPANDED(); /* ROOT should be expanded */
	node[fwTreeView_HANDLE] = 0;
	node[fwTreeView_LEVEL] = 0;
	if (resultType == fwDIPBrowser_ResultType_LEAFBRANCH)
		// This node is also a publication - rare, but possible
		node[fwTreeView_NAME] = "*" + fwDIPBrowser_InitialAddress;
	else
		// Usual case - it's a branch
		node[fwTreeView_NAME] = fwDIPBrowser_InitialAddress;
	node[fwTreeView_VALUE] = fwDIPBrowser_InitialAddress;
	/* Add the ROOT node */
	fwTreeView_insertNode(node, position++, "");

	/* Set the common properties for the children */
	node[fwTreeView_HANDLE] = 0;
	node[fwTreeView_LEVEL] = 1;
	node[fwTreeView_STATE] = 0;
	for(i = 1; i <= howMany; i++)
	{
		/* node[fwTreeView_VALUE] will store the DIP path of a node */
//		DebugN(fwDIPBrowser_InitialAddress);//####
		if(fwDIPBrowser_InitialAddress=="")
			node[fwTreeView_VALUE] = childName[i];
		else
			node[fwTreeView_VALUE] = fwDIPBrowser_InitialAddress + "/" + childName[i];
		node[fwTreeView_NAME] = "";
		if (childType[i] & fwDIPBrowser_ResultType_BRANCH)
		{
			// It's a branch - expansion possible
			node[fwTreeView_STATE] |= fwTreeView_BRANCH();
			if (childType[i] & fwDIPBrowser_ResultType_LEAF)
				// It's also a publication
				node[fwTreeView_NAME] = "*";
		}
		else
			// It's a leaf - no expanding possible
			node[fwTreeView_STATE] = 0;
			
		node[fwTreeView_NAME] += childName[i];
				
		/* Add the child */
		fwTreeView_insertNode(node, position++, "");
	}
	fwTreeView_defaultExpand(1, "");	
//	DebugN("<-fwDIPBrowser_initDIPTreeBrowser()");
}



// -----------------------------------------------------------------


/**

This function expands the selected branch of the DIP hierarchy
Modification History:
Constraints:
Usage: JCOP Framework internal
PVSS manager usage: VISION
@param initialPos	position of the node in the TreeView to expand
@param referenceName	The reference name of the TreeView, default value "" (this)
*/

fwDIPBrowser_expandDIPTreeBrowser(unsigned initialPos, string referenceName = "")
{
	dyn_string childName;
	dyn_int childType;
	dyn_string fieldName;
	dyn_int fieldType;
	
	dyn_string exceptionInfo;
	
	dyn_anytype node;
	
	int howMany; /* The number of elements in stuff provided by API manager */
	int level;
	int i;
	int resultType;
	int pos = initialPos; /* position of the node */
	string path; /* DIP path of the expanded node */
	
	node = fwTreeView_getNode(pos, referenceName); /* get the node that was selected for expansion */
	level = node[fwTreeView_LEVEL];
	path = node[fwTreeView_VALUE];
	
	if (level == 0)
	{
//		fwTreeView_prune(pos);
//		fwDIPBrowser_refreshRootNode(initialPos, node[fwTreeView_NAME]);
		fwTreeView_defaultExpand(pos);
	}
	else
	{
		/*
			Get the data from the 'API manager filled' dpe.
		*/
		Cancel.enabled = false;
		AddPublication.enabled = false;
		Details.enabled = false;
		resultType = fwDIP_DipQuery(sApiManagerDp.text, strltrim(node[fwTreeView_VALUE],"*"),
																			 childName, childType,
																			 fieldName, fieldType,
																			 exceptionInfo, fwDIPBrowser_TIMEOUT);
		if (dynlen(exceptionInfo)!=0)
		{
			// TODO: Error message
			fwExceptionHandling_display(exceptionInfo);
			fwTreeView_defaultExpand(initialPos, "");
			return;
		}
		Cancel.enabled = true;
		howMany = dynlen(childName);

		/* To update node delete it and add it again */
		fwTreeView_prune(pos);
		
		if (howMany > 0)
		{
			node[fwTreeView_STATE] |= fwTreeView_BRANCH();
		}
		else
		{
			/* Check: Should this ever happen? */
			node[fwTreeView_STATE] &= ~fwTreeView_BRANCH();
		}
		fwTreeView_insertNode(node, pos++, referenceName);
		
		if (howMany > 0)
		{
			node[fwTreeView_HANDLE] = 0;
			node[fwTreeView_LEVEL] = level + 1;
			
			for (i=1; i <= howMany; i++)
			{
				node[fwTreeView_VALUE] = path + "/" + childName[i];

				node[fwTreeView_NAME] = "";
				if (childType[i] & fwDIPBrowser_ResultType_BRANCH)
				{
					// It's a branch - expansion possible
					node[fwTreeView_STATE] |= fwTreeView_BRANCH();
					if (childType[i] & fwDIPBrowser_ResultType_LEAF)
						// It's also a publication
						node[fwTreeView_NAME] = "*";
				}
				else
					// It's a leaf - no expanding possible
					node[fwTreeView_STATE] = 0;
				
				node[fwTreeView_NAME] += childName[i];

				fwTreeView_insertNode(node, pos++, "");
			}
		}
	}
	fwTreeView_defaultExpand(initialPos, "");
}



// -----------------------------------------------------------------

/**

This function is run when user selects any node in the tree.
When branch is selected:
	* Add and Details buttons are disabled
	* Address string is cleaned
When leaf node is selected:
	* Add and Details buttons are enabled
	* Address string is filled with the publication address
Modification History:
Constraints:
Usage:
PVSS manager usage:
@param pos	position of the node in the TreeView
@param referenceName	The reference name of the TreeView, default value "" (this)

*/

fwDIPBrowser_selectNode(unsigned pos, string referenceName = "")
{
	dyn_anytype node;
	node = fwTreeView_getNode(pos, referenceName); /* get the node that was selected */
	
	if ( (!(node[fwTreeView_STATE] & fwTreeView_BRANCH)) || (strpos(node[fwTreeView_NAME],"*") == 0) )
	{
		// It's a publication - we can add it, or see its details
		Selected_TreeView_Node.text = node[fwTreeView_VALUE];
		AddPublication.enabled = true;
		Details.enabled = true;
	}
	else
	{
		Selected_TreeView_Node.text = "";
		AddPublication.enabled = false;
		Details.enabled = false;
	}
}


// -----------------------------------------------------------------

/**

This function expands the right-click menu. Right now - no menu
Modification History:
Constraints:
Usage: JCOP Framework internal
PVSS manager usage: VISION
@param pos	position of the node in the TreeView
@param referenceName	The reference name of the TreeView, default value "" (this)

*/

fwDIPBrowser_rightClick(unsigned pos, string referenceName = "")
{
	unsigned i;

	i = pos;
	return;
}

/**

This function orders the API manager to refresh the browser cache.
Modification History:
Constraints:
Usage: JCOP Framework
PVSS manager usage: VISION,CTRL
@param configDp	DIP Config datapoint
@param exceptionInfo	exception handling

*/

fwDIPBrowser_refreshCache(string configDp, dyn_string &exceptionInfo)
{
	if(!dpExists(configDp))
	{
		fwException_raise(exceptionInfo, "ERROR", "Config DP "+configDp+" does not exist.","");
		return;
	}
	dpSetWait(configDp+".command.refreshBrowser",TRUE);
}

/**

This function setups the closed self-test mechanism. It creates a dummy publication
and subscribes an internal dpe to it. It allows to determine whether the API
manager is working

Modification History:
Constraints:
Usage: JCOP Framework
PVSS manager usage: VISION,CTRL
@param configDp	 DIP Config datapoint
@param exceptionInfo	 exception handling

*/
fwDIP_setupSelfTest(string configDp, dyn_string &exceptionInfo)
{
	if(!dpExists(configDp))
	{
		fwException_raise(exceptionInfo, "ERROR", "Config DP "+configDp+" does not exist.","");
		return;
	}
	// Prepare the dummy publication name:
	string itemName;
	_fwDIP_generateSelfTestName(configDp, itemName, exceptionInfo);
	
	// setup the dummy publication
	fwDIP_publishPrimitive(itemName, fwDIP_SELFTEST_DPE, 0, configDp, exceptionInfo, true);
	if(dynlen(exceptionInfo)!=0)
		return;
	
	// setup the dummy subscription
	fwDIP_subscribePrimitive(itemName, configDp+".selfTest", configDp, exceptionInfo, true);
}

/**

This function checks whether the DIP API manager is running correctly. That is
the local publication-subscription mechanism with a dummy publication is working.

Modification History:
Constraints: WARNING: crash of API manager is not instantly visible. It might take few seconds before the function will return valid information in case of crash.
Usage: JCOP Framework
PVSS manager usage: VISION,CTRL
@param configDp 	DIP Config datapoint
@param exceptionInfo	 exception handling
@return - whether the manager is working
*/


bool fwDIP_SelfTest(string configDp, dyn_string &exceptionInfo)
{
	if(!dpExists(configDp))
	{
		fwException_raise(exceptionInfo, "ERROR", "Config DP "+configDp+" does not exist.","");
		return false;
	}
	
	// Check if dummy setup
	
	if(_fwDIP_testSelfTestSetup(configDp, exceptionInfo) == 0)
	{
		if(dynlen(exceptionInfo)==0)
			fwException_raise(exceptionInfo, "ERROR", "Dummy setup for self-test not configured.","");
		return false;
	}
	
	// Check the timestamps
	time published;
	time received;
	dpGet(fwDIP_SELFTEST_DPE+":_online.._stime", published,
		configDp+".selfTest:_online.._stime", received);
	int a = published;
	int b = received;
	if( (a-b)==0 )
		return 1;
	else
		return 0;
}

/**

This function generates the dummy self-test publication name for the given API manager

Modification History:
Constraints:
Usage: internal
PVSS manager usage: VISION,CTRL
@param configDp 	DIP Config datapoint
@param itemName 	will contain the generated name
@param exceptionInfo exception handling

*/

_fwDIP_generateSelfTestName(string configDp, string &itemName, dyn_string &exceptionInfo)
{
	if(!dpExists(configDp))
	{
		fwException_raise(exceptionInfo, "ERROR", "Config DP "+configDp+" does not exist.","");
		return;
	}
	dpGet(configDp+".publishName", itemName);
	itemName = "dip/pvss/selftest/" + itemName;
}

/**

This function checks if the dummy self-test setup had been configured

Modification History:
Constraints:
Usage internal
PVSS manager usage: VISION,CTRL
@param configDp DIP Config datapoint
@param exceptionInfo exception handling
@returns - whether the setup is correct
*/

bool _fwDIP_testSelfTestSetup(string configDp, dyn_string &exceptionInfo)
{
	if(!dpExists(configDp))
	{
		fwException_raise(exceptionInfo, "ERROR", "Config DP "+configDp+" does not exist.","");
		return;
	}
	bool isSub, isPub;
	string tmp;
	string itemName;
	_fwDIP_generateSelfTestName(configDp, itemName, exceptionInfo);
	_fwDIP_checkIsDpeSubscribed(configDp+".selfTest", isSub, tmp, exceptionInfo);
	_fwDIP_checkIsItemPublished(itemName, isPub, tmp, exceptionInfo);
	if(dynlen(exceptionInfo)!=0)
		return false;
	return (isPub&&isSub);
}

/** Search for a given set of strings in the DIP configuration.
  The function will search for configuration entries that contain ALL the searchStrings (AND operation).
  Entries that only contain some of the searchStrings will not match the search

@par Constraints
	None

@par Usage
	Internal

@par PVSS managers
	VISION, CTRL

@param configDp		input, the name of the configuration to search
@param searchStrings	input, the list of strings to search for in the configuration.  The function searches for rows in the configuration that contain ALL of the searchStrings.
@param exceptionInfo	output, details of any exceptions are returned here
@return 0 - if no configuration entries contained all the searchStrings, 1 - if at least one configuration entry contained all the searchStrings.
*/
bool _fwDIP_findInConfig(string configDp, dyn_string searchStrings, dyn_string &exceptionInfo)
{
  dyn_string matchingItems;

  _fwDIP_getConfigList(configDp, matchingItems, exceptionInfo);
  
  for(int i=1; i<=dynlen(searchStrings); i++)
  {
    matchingItems = dynPatternMatch("*" + searchStrings[i] + "*", matchingItems);
//DebugN(matchingItems);
  }
  return (dynlen(matchingItems) > 0);
}

/** Replaces all occurances of a given string in the DIP configuration with another replacement string

@par Constraints
	None

@par Usage
	Internal

@par PVSS managers
	VISION, CTRL

@param configDp		 input, the name of the configuration to search
@param searchString	 input, the string to be replaced.
@param replacementString input, the new string to replace the old one
@param exceptionInfo	 output, details of any exceptions are returned here
*/
_fwDIP_replaceInConfig(string configDp, string searchString, string replacementString, dyn_string &exceptionInfo)
{
  int i, length;
  dyn_bool isMatched;
  dyn_string configList;

  _fwDIP_getConfigList(configDp, configList, exceptionInfo);
  isMatched = patternMatch("*" + searchString + "*", configList);

  length = dynlen(isMatched);
  for(i=1; i<=length; i++)
  {
     if(isMatched[i])
       strreplace(configList[i], searchString, replacementString);
  }

  _fwDIP_setConfigList(configDp, configList, exceptionInfo);
}

/** Moves the DIP configuration from one DP element to another
 The source is emptied after the configuration has been copied to the target.
 
@par Constraints
	None

@par Usage
	Internal

@par PVSS managers
	VISION, CTRL

@param sourceConfig      input, the name of the source DIP configuration DP element
@param targetConfig	 input, the name of the target DIP configuration DP element
@param exceptionInfo	 output, details of any exceptions are returned here
*/
_fwDIP_moveConfig(string sourceConfig, string targetConfig, dyn_string &exceptionInfo)
{
  dyn_string configList;

  _fwDIP_getConfigList(sourceConfig, configList, exceptionInfo);
  if(dynlen(exceptionInfo) > 0)
    return;
   
  _fwDIP_setConfigList(sourceConfig, makeDynString(), exceptionInfo);   
  _fwDIP_setConfigList(targetConfig, configList, exceptionInfo);
  if(dynlen(exceptionInfo) > 0)
  {
    //in case of error, re-set the configuration back to the sourceConfig
    _fwDIP_setConfigList(sourceConfig, configList, exceptionInfo);  
  }    
}

/** Checks if the DIP server configuration is active or disabled (copied to the disabled configuration DPE)

@par Constraints
	None

@par Usage
	Public

@par PVSS managers
	VISION, CTRL

@param configDp		input, the name of the configuration to check
@param exceptionInfo	output, details of any exceptions are returned here
@return 0 - if server configuration is active, 1 - if server configuration has been disabled
*/
bool fwDIP_isServerConfigDisabled(string configDp, dyn_string &exceptionInfo)
{
  dyn_string configList;
  
  configDp = dpSubStr(configDp, DPSUB_SYS_DP);
  _fwDIP_getConfigList(configDp + "." + fwDIP_CONFIG_SERVER_DISABLED_DPE, configList, exceptionInfo);
  return(dynlen(configList) > 0);
}

/** Migrates a given DIP configuration from the old delimeter (0x1a) to the new one (!)
  If entries in the configuration are found to contain both the old and new delimeter
  the server configuration is disabled and the user must resolve this issue with the fwDIP panel.
  There is optional debug output in the log, which is used when called from the postInstall script.

@par Constraints
	None

@par Usage
	Public

@par PVSS managers
	VISION, CTRL

@param configDp		input, the name of the configuration to check
@param exceptionInfo	output, details of any exceptions are returned here
@param withDebugOutput	OPTIONAL PARAMETER - default value FALSE
                          If FALSE, no debug messages are shown in the log, if TRUE, debug output is printed to the log
@return 0 - if configuration is up-to-date
        1 - if configuration was migrated successfully
        -1 - if the configuration can not be migrated automatically (both old and new seperators found in an entry)
*/
int fwDIP_migrateConfigToNewDelimeter(string configDp, dyn_string &exceptionInfo, bool withDebugOutput = FALSE)
{
  bool foundOldSep = FALSE, foundBothSep = FALSE;

  foundOldSep = _fwDIP_findInConfig(configDp + "." + fwDIP_CONFIG_SERVER_DPE,
                                    makeDynString(fwDIP_SEPERATOR_OBSOLETE), exceptionInfo);
  if(foundOldSep)
  {
    foundBothSep = _fwDIP_findInConfig(configDp + "." + fwDIP_CONFIG_SERVER_DPE,
                                       makeDynString(fwDIP_SEPERATOR, fwDIP_SEPERATOR_OBSOLETE), exceptionInfo);
  }
  
  if(!foundOldSep)
  {
    if(withDebugOutput)
      DebugN("fwDIP: Config " + configDp + " is up-to-date");
    return 0;
  }
  else if(foundOldSep && !foundBothSep)
  {
    _fwDIP_replaceInConfig(configDp + "." + fwDIP_CONFIG_SERVER_DPE, fwDIP_SEPERATOR_OBSOLETE, fwDIP_SEPERATOR, exceptionInfo);
    if(withDebugOutput)
      DebugN("fwDIP: Updated config " + configDp + " to the new format");
    return 1;
  }
  else if(foundBothSep)
  {
    _fwDIP_moveConfig(configDp + "." + fwDIP_CONFIG_SERVER_DPE, configDp + "." + fwDIP_CONFIG_SERVER_DISABLED_DPE, exceptionInfo);
    if(withDebugOutput)
    {
      DebugN("fwDIP: !!!!!!!!!!!!!!!!!");        
      DebugN("fwDIP: Disabled server config " + configDp + ". It contains unsupported characters in the DIP publication configuration.");        
      DebugN("fwDIP: Please open the fwDIP configuration panel to resolve this issue and re-enable the config.");        
      DebugN("fwDIP: !!!!!!!!!!!!!!!!!");
    }        
    return -1;
  }
}

/** Migrates all DIP configurations in the current system from the old delimeter (0x1a) to the new one (!)
  If entries in the configuration are found to contain both the old and new delimeter
  the server configuration is disabled and the user must resolve this issue with the fwDIP panel.
  There is optional debug output in the log, which is used when called from the postInstall script.

@par Constraints
	None

@par Usage
	Public

@par PVSS managers
	VISION, CTRL

@param exceptionInfo	output, details of any exceptions are returned here
@param withDebugOutput	OPTIONAL PARAMETER - default value FALSE
                          If FALSE, no debug messages are shown in the log, if TRUE, debug output is printed to the log
*/
fwDIP_migrateAllToNewDelimeter(dyn_string &exceptionInfo, bool withDebugOutput = FALSE)
{
  int i, length;
  dyn_string configDpsList;
  
  configDpsList = dpNames("*", fwDIP_CONFIG_DPT);
  length = dynlen(configDpsList);
  for(i=1; i<=length; i++)
  {
    fwDIP_migrateConfigToNewDelimeter(configDpsList[i], exceptionInfo, withDebugOutput);
  }
}
//@}

