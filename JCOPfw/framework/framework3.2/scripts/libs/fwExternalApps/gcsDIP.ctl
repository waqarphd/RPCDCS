/**@name LIBRARY: gcsDIP.ctl

@author Artem Burmyakov (IT/CO-FE)
@version: 1.0.0.
@date: March 2007
@brief: gcsDIP library allows to import dip configuration files.

@note:  Required Libraries:
	gcsGenericXMLOperations (XML parsing), v2.3.5;
	fwDIP, v4.0.9;
	
Modification History:
	$Log: gcsDIP.ctl,v $
	Revision 1.5  2008/05/18 11:20:02  oholme
	Removed DebugTN statements

	Revision 1.9  2008/01/18 14:18:55  gamx
	naming has been changed


*/
/**
Internal functions:
	. gcsDIP_CreateConfig(string sFileContent, string &sConfigName)
	. gcsDIP_GetConfigName(string sConfig)
	. gcsDIP_CreatePublications(string sInputs, string sConfigName)
	. gcsDIP_CreateSubscriptions(string sInputs, string sConfigName)
	. gcsDIP_GetTagsList(string inputXML, string tagName)
	. gcsDIP_CreateNewPublication(string pxml, string sConfigName)
	. gcsDIP_CheckDpesExistance(dyn_string items)
	. gcsDIP_CreateNewSubscription(string sxml, string sConfigName)
	. gcsDIP_GetDpToBeCreated(string dpeName)
	. gcsDIP_GetPublicationName(string input)
	. gcsDIP_GetSubscriptionName(string input)
	. gcsDIP_GetPublicationType(string input)
	. gcsDIP_GetSubscriptionType(string input)
	. gcsDIP_GetDpeList(string input)
	. gcsDIP_GetDpeListForSubscriptions(string input)
	. gcsDIP_GetTagList(string input)
	. gcsDIP_GetBufferTime(string input)
	. gcsDIP_GetOverwriteOrNot(string input)
*/



//global constants
const string _CONFIG_DPTYPE = "_FwDipConfig";

//config tag and its attributes: <configuration name="config1"/>
const string _CONFIG = "configuration";
const string _CONFIG_NAME = "name";
const string _CONFIG_DEFAULT = "default";

//publication tag and its attributes: <publication name="publ1"/>
const string _PUBLICATION = "publication";
const string _PUBLICATION_NAME = "name";
const string _PUBLICATION_DEFAULT = "default";
const string _PUBLICATION_TYPE = "type";
const string _PUBLICATION_TYPE_DEFAULT = "multiple";

//subscription tag and its attributes: <subscription name="subscr1"/>
const string _SUBSCRIPTION = "subscription";
const string _SUBSCRIPTION_DEFAULT = "default";
const string _SUBSCRIPTION_NAME = "name";
const string _SUBSCRIPTION_TYPE = "type";
const string _SUBSCRIPTION_TYPE_DEFAULT = "multiple";

//dpe tag and its attributes: <dpe><name/><alias/><tag/></dpe>
const string _DPE = "dpe";
const string _DP_ALIAS = "alias";
const string _DP_NAME = "name";
const string _DP_ELEMENT = "element";
const string _DP_ELEMENT_DEFAULT = ".";
const string _DP_ELEMENT_TYPE = "type";
const string _DPE_TAG = "tag";
const string _DPE_TAG_DEFAULT = "default";
const string _DPE_DESCRIPTION = "description";
const string _DPE_DESCRIPTION_DEFAULT = "";
const string _DPE_UNIT = "unit";
const string _DPE_UNIT_DEFAULT = "";
const string _DPE_ALERT_MIN_ERROR = "minError";
const string _DPE_ALERT_MIN_WARN = "minWarn";
const string _DPE_ALERT_MAX_WARN = "maxWarn";
const string _DPE_ALERT_MAX_ERROR = "maxError";
const string _DPE_ALERT_DEFAULT = "";

//buffer tag
const string _BUFFER = "buffer";
const string _BUFFER_DEFAULT = "0";

//overwrite tag
const string _OVERWRITE = "overwrite";
const string _OVERWRITE_DEFAULT = "FALSE";







//Creates required DP structure for DIP configuration
//sFileContent - a content of an input file transformed in string format
//sConfigName - a dip configuration name
string gcsDIP_CreateConfig(string sFileContent, string &sConfigName)
{ 
  bool bFileExists;
  string sError = "";
  int iRes = 0;
  
//  LogField.appendItem("A new DIP configuration is creating.");

  sConfigName = gcsDIP_GetConfigName(sFileContent);
  if (sConfigName == "")
  {
  	dynAppend(sError, "No configuration has been defined in the input file.");
  	return sError;
  }
  
  bFileExists = dpExists(sConfigName);
  if (!(bFileExists))
  {
  	iRes = dpCreate(sConfigName, _CONFIG_DPTYPE);
  	if (iRes < 0) dynAppend(sError, "");
  }
  
  return sError;
}







//defines the name of the configuration from input XML file
//sConfig - a dip configuration in XML format (part of an input file)
string gcsDIP_GetConfigName(string sConfig)
{
  string sConfigName;

  sConfigName = gcsGenericXMLOperations_XMLParseTagAttribute(sConfig, _CONFIG, _CONFIG_NAME, _CONFIG_DEFAULT);
  
  return sConfigName;
}






//defines the lis of publications to be created
//sInputs - an input xml source;
//sConfigName - a name of a dip configuration
string gcsDIP_CreatePublications(string sInputs, string sConfigName)
{
  string error = "";
  dyn_string pTagsList = makeDynString(); //contains the list of publication tags;


  pTagsList = gcsDIP_GetTagsList(sInputs, _PUBLICATION);
  if (pTagsList == "")
  {
  	error = "Publications have not been created. Probably they are not declared.";
  	return error;
  }
  
  
  //loop through all publication tags
  int i;
  int max = dynlen(pTagsList);
  
  for (i = 1; i <= max; i++) 
  {
//TEMPXXX    DebugN("A new publication is creating.");
    error = gcsDIP_CreateNewPublication(pTagsList[i], sConfigName);
    if (error) {return error;}
  }
  
  return error;
}






//create subscriptions
//sInputs - input xml source; config - name of the dip configuration
//sConfigName - a name of a dip configuration
string gcsDIP_CreateSubscriptions(string sInputs, string sConfigName)
{
  string sError = "";
  dyn_string cTagsList = makeDynString(); //contains the list of configuration tags;
  
//TEMPXXX  DebugN("A new subscription is creating.");
  
  cTagsList = gcsDIP_GetTagsList(sInputs, _SUBSCRIPTION);
  if (cTagsList == "")
  {
  	sError = "Subscriptions have not been created. Probably they are not declared.";
  	return sError;
  }
  
  //loop through all subscription tags
  int i;
  int iMax = dynlen(cTagsList);
  dyn_bool overwrite;
  dyn_string dpes, items, tags, exceptionInfo;
  dyn_bool tempOverwrite, overwriteOptions;
  dyn_string tempDpes, tempItems, tempTags;
  
  for (i = 1; i <= iMax; i++) 
  {
    sError = gcsDIP_CreateNewSubscription(cTagsList[i], sConfigName, dpes, items, tags, overwrite, exceptionInfo);
    if (sError) {return sError;}
  }
//DebugTN(dynlen(dpes), dynlen(overwrite));  
  iMax = dynlen(dpes);
  overwriteOptions = makeDynBool(TRUE, FALSE);
  for(int j=1; j<=2; j++)
  {
    for(i=1; i<=iMax; i++)
    {
      if(overwrite[i] == overwriteOptions[j])
      {
        dynAppend(tempDpes, dpes[i]);
        dynAppend(tempItems, items[i]);
        dynAppend(tempTags, tags[i]);
      }
    }
    fwDIP_subscribeMany(tempDpes, sConfigName, tempItems, tempTags, exceptionInfo, overwriteOptions[j]);
  }
//DebugTN("DONE");  
  
  return sError;  
}






//returns the list of publication or subscription tags
//sInputs - an input configuration in xml format (part of an input file)
//sTagName - this is dpe tag name in a publication/subscription. This is not an XML tag!
dyn_string gcsDIP_GetTagsList(string sInputs, string sTagName)
{
  dyn_string dsXmlTags = makeDynString();
  string sCurTag;
  
  while (true)
  {
    sCurTag = gcsGenericXMLOperations_XMLParseTag(sInputs, sTagName);
    if (sCurTag == "") break;
    
    dynAppend(dsXmlTags, sCurTag);
    strreplace(sInputs, sCurTag, ""); //if the tag has been put in dyn list - delete from source
                                       //to avoid dublication                                                                    
  }  
  
  return dsXmlTags;
}






//create a new publication
//sPublicationConfig - xml source for publication
//cname - configuration name, defined before
string gcsDIP_CreateNewPublication(string sPublicationConfig, string sConfigName)
{
  string sError = "";
  string sException;
  
  string sPublicationName = gcsDIP_GetPublicationName(sPublicationConfig);
  string sPublicationType = gcsDIP_GetPublicationType(sPublicationConfig);
  dyn_string dsDpeList = gcsDIP_GetDpeList(sPublicationConfig);
  dyn_string dsTagList = gcsDIP_GetTagList(sPublicationConfig);
  dyn_string dsDescriptionList = gcsDIP_GetDescriptionList(sPublicationConfig);
  int iBufferTime = gcsDIP_GetBufferTime(sPublicationConfig);
  bool bOverwrite = gcsDIP_GetOverwriteOrNot(sPublicationConfig);
  
  //check existance of DPEs
  //In case if DPE is not found, the publication is ignored
  bool bDpesExist = gcsDIP_CheckDpesExistance(dsDpeList);
  
  if (!(bDpesExist)){sError = "Dpe(-s) don't exist in one of the specified publications."; return sError;}
  
  
  //checking the values
  if (sPublicationName == "") {sError = "The name for the publication is not defined."; return sError;}
  if (dsDpeList == "") {DebugN("Warning: no DPEs in the current publication.");}
  if (sPublicationType == "") {sError = "Publication type for '" + sPublicationName + "' has not been specified."; return sError;}
  

  
  
  if (dsDpeList != ""){
    if (sPublicationType == "single") {
      //creation of a new single publication by using the function from the fwDIP library
      fwDIP_publishPrimitive(sPublicationName, dsDpeList, iBufferTime, sConfigName, sException, bOverwrite);
    }
  
    if (sPublicationType == "multiple"){
      //creation of a new multiple publication by using the function from fwDIP library  
      fwDIP_publishStructure(sPublicationName, dsDpeList, dsTagList, iBufferTime, sConfigName, sException, bOverwrite); 
    }
  
    for(int i=1; i<=dynlen(dsDpeList); i++)
    {
      if(dsDescriptionList[i] != "")
        dpSetDescription(dsDpeList[i], dsDescriptionList[i]);
    }
    
//TEMPXXX    DebugN("Publication " + sPublicationName + " is created.");
  }
  
  if (dsDpeList == ""){
//TEMPXXX    DebugN("Publication has not been created.");
  }
  
  return sError;
}




bool gcsDIP_CheckDpesExistance(dyn_string dsItems)
{
//TEMPXXX	DebugN("List of items: " + dsItems);
	
	string sCurDpe;
	bool bDpExist;
	string sError;
	
	for (int i = 1; i <= dynlen(dsItems); i++)
	{
		sCurDpe = dsItems[i];
		bDpExist = dpExists(sCurDpe);
//    		if (bDpExist) {DebugN("DPE exists. Name: '" + sCurDpe + "'");}
    		if (!(bDpExist)) {sError = "DPE does not exist. Name: '" + sCurDpe + "'."; DebugN(sError); return 0;}
	}
	
	return 1;
}





//create a new subscription
//sSubscriptionConfig - xml source for subscription
//cname - configuration name, defined before
string gcsDIP_CreateNewSubscription(string sSubscriptionConfig, string sConfigName,
                                    dyn_string &dpes, dyn_string &items, dyn_string &tags, dyn_bool &overwrite,
                                    dyn_string &exceptionInfo)
{
  string sError = "";
  dyn_string dsException, localDpeList;
  
  string sSubscriptionName = gcsDIP_GetSubscriptionName(sSubscriptionConfig);
  string sSubscriptionType = gcsDIP_GetSubscriptionType(sSubscriptionConfig);
  dyn_string dsDpeList = gcsDIP_GetDpeListForSubscriptions(sSubscriptionConfig);
  dyn_string dsTagList = gcsDIP_GetTagList(sSubscriptionConfig);
  dyn_string dsDescriptionList = gcsDIP_GetDescriptionList(sSubscriptionConfig);
  dyn_string dsUnitList = gcsDIP_GetUnitList(sSubscriptionConfig);
  dyn_dyn_string ddsAlertConfigurations = gcsDIP_GetAlertConfigurations(sSubscriptionConfig);
  bool bOverwrite = gcsDIP_GetOverwriteOrNot(sSubscriptionConfig);
  
  localDpeList = dsDpeList;
  
  //checking the values
  if (sSubscriptionName == "") {sError = "The name for the subscription is not defined."; return sError;}
  if (dsDpeList == "") {sError = "Check the names of the DPEs in the input file."; return sError;}
  if (sSubscriptionType == "")
  {sError = "The type of the subscription '" + sSubscriptionName + "' has not been specified."; return sError;}
  
  if (sSubscriptionType == "single"){
    //creation of a new single subscription by using the function from fwDIP library
    dynAppend(dpes, localDpeList);
    dynAppend(tags, "");
  }
  else {
    //creation of a new multiple subscription by using the function from fwDIP library
    dynAppend(dpes, localDpeList);
    dynAppend(tags, dsTagList);
  }

  for(int i=1; i<=dynlen(dsDpeList); i++)
  {
    dyn_string alertTexts, alertClasses;
    dyn_float alertLimits;
    
    dynAppend(items, sSubscriptionName);
    dynAppend(overwrite, bOverwrite);

    dpSetDescription(dsDpeList[i], dsDescriptionList[i]);
    dpSetUnit(dsDpeList[i], dsUnitList[i]);
   
    for(int j=1; j<=dynlen(ddsAlertConfigurations[i]); j++)
    {
      if(ddsAlertConfigurations[i][j] == "")
        continue;
      
      dynAppend(alertLimits, ddsAlertConfigurations[i][j]);

      switch(j)
      {
        case 1:
          dynAppend(alertTexts, "Exceeded minimum error threshold");
          dynAppend(alertClasses, "_fwErrorAck.");
          break;        
        case 2:
          dynAppend(alertTexts, "Exceeded minimum warning threshold");
          dynAppend(alertClasses, "_fwWarningAck.");
          break;        
        case 3:
          dynAppend(alertTexts, "OK");
          dynAppend(alertClasses, "");
          dynAppend(alertTexts, "Exceeded maximum warning threshold");
          dynAppend(alertClasses, "_fwWarningAck.");
          break;        
        case 4:
          dynAppend(alertTexts, "Exceeded maximum error threshold");
          dynAppend(alertClasses, "_fwErrorAck.");
          break;        
      }
    }
    
    if(dynlen(alertLimits) > 0)
      fwAlertConfig_set(dsDpeList[i], DPCONFIG_ALERT_NONBINARYSIGNAL, alertTexts, alertLimits, alertClasses,
                        makeDynString(), "", makeDynString(), "", dsException, TRUE, TRUE, ".");
  }
  
//TEMPXXX  DebugN("Subscription '" + sSubscriptionName + "' is created.");
  return sError;
}








//the name is the part of the string before first "."
string gcsDIP_GetDpToBeCreated(string sDpeName)
{	
	dyn_string sDpName;
	
	sDpName = strsplit(sDpeName, ".");
//TEMPXXX	DebugN("The name of the Dp to be created is: " + sDpName[1]);
	return sDpName[1];
}










//defines the name of the publication
string gcsDIP_GetPublicationName(string sInputs)
{
  string sName;

  sName = gcsGenericXMLOperations_XMLParseTagAttribute(sInputs, _PUBLICATION, _PUBLICATION_NAME, _PUBLICATION_DEFAULT);
    
  return sName;
}




//defines the name of the subscription
string gcsDIP_GetSubscriptionName(string sInputs)
{
  string sName;
  
  sName = gcsGenericXMLOperations_XMLParseTagAttribute(sInputs, _SUBSCRIPTION, _SUBSCRIPTION_NAME, _SUBSCRIPTION_DEFAULT);
  
  return sName;
}


//returns the type of the publication: single or multiple (complex)
string gcsDIP_GetPublicationType(string sInputs)
{
  string sType;
  
  sType = gcsGenericXMLOperations_XMLParseTagAttribute(sInputs, _PUBLICATION, _PUBLICATION_TYPE, _PUBLICATION_TYPE_DEFAULT);
  
  return sType;
}



//returns the type of the subscription: single or multiple
string gcsDIP_GetSubscriptionType(string sInputs)
{
  string sType;
  
  sType = gcsGenericXMLOperations_XMLParseTagAttribute(sInputs, _SUBSCRIPTION, _SUBSCRIPTION_TYPE, _SUBSCRIPTION_TYPE_DEFAULT);
  
  return sType;
}



//returns dpes list in dyn_string
dyn_string gcsDIP_GetDpeList(string sInputs)
{
  dyn_string dsDpes = makeDynString();
  string stringTag; //this is the string tag from input file: <dpe><tag>value1</tag></dpe>
  string sDpAlias;
  string sDpName; //this is the name of the dpe to add in the list
  string sDpElement;
  string sDpeName;
  
  bool bDpExist;
  string sError;
  
  /*there are two possibilities to specify the dpe name:
  1. use <name/> tag or
  2. use <alias/> tag
  If there is no value in <alias/> tag, the <name/> is used */
  
//TEMPXXX  DebugN("Searching for DPE List.");
  
  while (true)
  {
    stringTag = gcsGenericXMLOperations_XMLParseTag(sInputs, _DPE);
    if (stringTag == "") break;
    
    sDpAlias = gcsGenericXMLOperations_XMLParseTagInfo(stringTag, _DP_ALIAS, "");
    
    if (sDpAlias != "")
    {
//TEMPXXX      DebugN("The alias is used to define the DPE name.");
//TEMPXXX      DebugN("The alias of the dp is: " + sDpAlias);
      sDpName = dpNames("@" + sDpAlias);
//TEMPXXX      DebugN("The dp with system prefix is: " + sDpName);
      sDpName = dpSubStr(sDpName, DPSUB_DP);
//TEMPXXX      DebugN("The dp name WITHOUT system prefix is: " + sDpName);
    }
    
    if (sDpAlias == "")
    {     
//TEMPXXX      DebugN("The aliase is not specified. The DP name is used.");
      sDpName = gcsGenericXMLOperations_XMLParseTagInfo(stringTag, _DP_NAME, "");
    }
    
//TEMPXXX    DebugN("Definition of the DP Element.");
    sDpElement = gcsGenericXMLOperations_XMLParseTagInfo(stringTag, _DP_ELEMENT, _DP_ELEMENT_DEFAULT);
    sDpeName = sDpName + sDpElement;    
//TEMPXXX    DebugN("DPE is: " + sDpeName);
    
    //Check of DPE existance has been moved to create publication functions as
    //in case of subscriptions it is not required
    //bDpExist = dpExists(sDpeName);
    //if (dpExist) {DebugN("DPE exists. Name: '" + sDpeName + "'");}
    //if (!(dpExist) & (sDpName != "")) {sError = "DPE does not exist. Name: '" + sDpeName + "'."; DebugN(sError); return "";}
    //if (!(dpExist) & (sDpName == "")) {sError = "DPE does not exist. Alias: '" + sDpAlias + "', element: '" + sDpElement + "'."; DebugN(sError); return "";}
    
    dynAppend(dsDpes, sDpeName);
    strreplace(sInputs, stringTag, "");
  }
  
  return dsDpes;
}


dyn_string gcsDIP_GetDpeTypeList(string sInputs)
{
  dyn_string dsDpElementTypes = makeDynString();
  string stringTag; //this is the string tag from input file: <dpe><tag>value1</tag></dpe>
  string sDpeType;
  
  bool bDpExist;
  string sError;
    
  while (true)
  {
    stringTag = gcsGenericXMLOperations_XMLParseTag(sInputs, _DPE);
    if (stringTag == "") break;
    
    sDpeType = gcsGenericXMLOperations_XMLParseTagInfo(stringTag, _DP_ELEMENT_TYPE, "");
        
    dynAppend(dsDpElementTypes, sDpeType);
    strreplace(sInputs, stringTag, "");
  }
  
  return dsDpElementTypes;
}










//returns dpes list in dyn_string
dyn_string gcsDIP_GetDpeListForSubscriptions(string sInputs)
{
  dyn_string dsDpes = makeDynString();
  string stringTag; //this is the string tag from sInputs file: <dpe><tag>value1</tag></dpe>
  string sDpAlias;
  string sDpName; //this is the name of the dpe to add in the list
  string sDpElement;
  string sDpeName;
  string sDpeType;
  string sDpTag;
  string sDpNameForAlias;
  
  bool bDpExist;
  bool bCreated;
  string sError;
  int iAliasIsSet;
  
  
  /*there are two possibilities to specify the dpe name:
  1. use <name/> tag or
  2. use <alias/> tag
  If there is no value in <alias/> tag, the <name/> is used */
  
//TEMPXXX  DebugN("The sInputs string is: " + sInputs);
//TEMPXXX  DebugN("Searching for DPE List.");
  
  while (true)
  {
    bCreated = 0;
    stringTag = gcsGenericXMLOperations_XMLParseTag(sInputs, _DPE);
    if (stringTag == "") break;
    
    sDpAlias = gcsGenericXMLOperations_XMLParseTagInfo(stringTag, _DP_ALIAS, "");
    sDpeType = gcsGenericXMLOperations_XMLParseTagInfo(stringTag, _DP_ELEMENT_TYPE, "");
    
    if (sDpAlias != "")
    {
//TEMPXXX      DebugN("The alias is used to define the DPE name.");
      sDpName = dpNames("@" + sDpAlias);
      sDpName = dpSubStr(sDpName, DPSUB_DP);
//TEMPXXX      DebugN("Dp name is: " + sDpName);
      
      //in case if Dpe does not exist, it will be created
      if (sDpName == "")
      {
//TEMPXXX      	DebugN("Dp with the name " + sDpAlias + " is creating. The type is: " + sDpeType);
      	
      	
      	//3 possible types: float, bool, int => DipSubscriptionsFloat, DipSubscriptionsBool, DipSubscriptionsInt
      	switch(sDpeType)
      	{
            case "float":
      		dpCreate(sDpAlias, "DipSubscriptionsFloat");
      		bCreated = 1;
                break;
            case "bool":
      		dpCreate(sDpAlias, "DipSubscriptionsBool");
      		bCreated = 1;
                break;
            case "int":
      		dpCreate(sDpAlias, "DipSubscriptionsInt");
      		bCreated = 1;
                break;
            default:
      		dpCreate(sDpAlias, sDpeType);
      		bCreated = 1;
                break;
        }
      	
      	
      	sDpTag =  gcsGenericXMLOperations_XMLParseTagInfo(stringTag, _DPE_TAG, "");      	
      	sDpNameForAlias = sDpAlias + ".";
      	iAliasIsSet = dpSetAlias(sDpNameForAlias, sDpTag);
//TEMPXXX      	DebugN("For dp " + sDpNameForAlias + " an alias has been set: " + sDpTag);
//TEMPXXX      	DebugN("Result: " + iAliasIsSet);
      	
      	
      	//bCreated = 1;
      	sDpName = sDpAlias + ".Value";
//TEMPXXX      	DebugN("Dp with the name " + sDpAlias + " has been created.");
      }
    }
    
    if (sDpAlias == "")
    {     
//TEMPXXX      DebugN("The aliase is not specified. The DP name is used.");
      sDpName = gcsGenericXMLOperations_XMLParseTagInfo(stringTag, _DP_NAME, "");
      bDpExist = dpExists(sDpName);
      if (!(bDpExist))
      {
//TEMPXXX      	 DebugN("Dp with the name " + sDpName + " is creating.");
      	 
      	switch(sDpeType)
      	{
            case "float":
      		dpCreate(sDpName, "DipSubscriptionsFloat");
      		bCreated = 1;
                break;
            case "bool":
      		dpCreate(sDpName, "DipSubscriptionsBool");
      		bCreated = 1;
                break;
            case "int":
      		dpCreate(sDpName, "DipSubscriptionsInt");
      		bCreated = 1;
                break;
            default:
      		dpCreate(sDpName, sDpeType);
      		bCreated = 1;
                break;
        }      	 
        
//TEMPXXX        DebugN("Dp with the name " + sDpName + " has been created. Type: " + sDpeType);
      }
    }
    
    
    sDpElement = gcsGenericXMLOperations_XMLParseTagInfo(stringTag, _DP_ELEMENT, _DP_ELEMENT_DEFAULT);
    sDpeName = sDpName + sDpElement;        
    
    dynAppend(dsDpes, sDpeName);
    strreplace(sInputs, stringTag, "");
  }
  
  return dsDpes;
}
















//returns tag list in dyn_string
dyn_string gcsDIP_GetTagList(string sInputs)
{
  dyn_string tags = makeDynString();
  string stringTag; //this is the string tag from sInputs file: <tag>value1</tag>
  string tname; //this is the name of the tag to add in the list: value1
  
  while (true)
  {
    stringTag = gcsGenericXMLOperations_XMLParseTag(sInputs, _DPE);
    if (stringTag == "") break;
    
    tname = gcsGenericXMLOperations_XMLParseTagInfo(stringTag, _DPE_TAG, _DPE_TAG_DEFAULT);
    dynAppend(tags, tname);
    strreplace(sInputs, stringTag, "");
  }
  
  return tags;
}

//defines the name of the subscription
dyn_string gcsDIP_GetDescriptionList(string sInputs)
{
  dyn_string tags = makeDynString();
  string stringTag; //this is the string tag from sInputs file: <tag>value1</tag>
  string tname; //this is the name of the tag to add in the list: value1
  
  while (true)
  {
    stringTag = gcsGenericXMLOperations_XMLParseTag(sInputs, _DPE);
    if (stringTag == "") break;
    
    tname = gcsGenericXMLOperations_XMLParseTagInfo(stringTag, _DPE_DESCRIPTION, _DPE_DESCRIPTION_DEFAULT);
    dynAppend(tags, tname);
    strreplace(sInputs, stringTag, "");
  }
  
  return tags;
}


//defines the name of the subscription
dyn_string gcsDIP_GetUnitList(string sInputs)
{
  dyn_string tags = makeDynString();
  string stringTag; //this is the string tag from sInputs file: <tag>value1</tag>
  string tname; //this is the name of the tag to add in the list: value1
  
  while (true)
  {
    stringTag = gcsGenericXMLOperations_XMLParseTag(sInputs, _DPE);
    if (stringTag == "") break;
    
    tname = gcsGenericXMLOperations_XMLParseTagInfo(stringTag, _DPE_UNIT, _DPE_UNIT_DEFAULT);
    dynAppend(tags, tname);
    strreplace(sInputs, stringTag, "");
  }
  
  return tags;
}

//defines the name of the subscription
dyn_dyn_string gcsDIP_GetAlertConfigurations(string sInputs)
{
  dyn_dyn_string tags = makeDynString();
  string stringTag; //this is the string tag from sInputs file: <tag>value1</tag>
  dyn_string tname; //this is the name of the tag to add in the list: value1
  
  while (true)
  {
    stringTag = gcsGenericXMLOperations_XMLParseTag(sInputs, _DPE);
    if (stringTag == "") break;
    
    tname[1] = gcsGenericXMLOperations_XMLParseTagInfo(stringTag, _DPE_ALERT_MIN_ERROR, _DPE_ALERT_DEFAULT);
    tname[2] = gcsGenericXMLOperations_XMLParseTagInfo(stringTag, _DPE_ALERT_MIN_WARN, _DPE_ALERT_DEFAULT);
    tname[3] = gcsGenericXMLOperations_XMLParseTagInfo(stringTag, _DPE_ALERT_MAX_WARN, _DPE_ALERT_DEFAULT);
    tname[4] = gcsGenericXMLOperations_XMLParseTagInfo(stringTag, _DPE_ALERT_MAX_ERROR, _DPE_ALERT_DEFAULT);
    tags[dynlen(tags) + 1] = tname;
    strreplace(sInputs, stringTag, "");
  }
  
  return tags;
}


//returns the size of the buffer time
//if there is no value defined, 0 - by default
int gcsDIP_GetBufferTime(string sInputs)
{
  int buffer;
  
  buffer = gcsGenericXMLOperations_XMLParseTagInfo(sInputs, _BUFFER, _BUFFER_DEFAULT);
  
  return buffer;
}



//defines: overwrite with new data or not
//default value: FALSE
bool gcsDIP_GetOverwriteOrNot(string sInputs)
{
  bool bOverwrite;
  
  bOverwrite = gcsGenericXMLOperations_XMLParseTagInfo(sInputs, _OVERWRITE, _OVERWRITE_DEFAULT);
  
  
  return bOverwrite;
}
