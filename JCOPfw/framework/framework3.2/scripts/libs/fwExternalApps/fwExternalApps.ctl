#uses "fwExternalApps/gcsDIP.ctl"
#uses "fwExternalApps/gcsGenericXMLOperations.ctl"

const string fwExternalApps_BASE_NODE = "ExternalApps";
const string fwExternalApps_EXPERIMENT_VARIABLE = "{varExperiment}";

fwExternalApps_createDevicesFromFile(string configurationFilePath, string systemType, dyn_string intermediateNodeTypes,
                                     dyn_string intermediateNodeLevels, dyn_string &exceptionInfo,
                                     dyn_string variables = "", dyn_string substitutions = "")
{
  string xmlFileContents;
  string dipConfigName;

  fwExternalApps_readXmlFile(configurationFilePath, xmlFileContents, exceptionInfo);
  
  for(int i=1; i<=dynlen(variables); i++)
    strreplace(xmlFileContents, variables[i], substitutions[i]);
  
  fwExternalApps_createDpStructure(xmlFileContents, intermediateNodeTypes, intermediateNodeLevels, exceptionInfo);

  fwDevice_setAlertRecursively(fwExternalApps_BASE_NODE + fwDevice_HIERARCHY_SEPARATOR + systemType, fwDevice_ALERT_SET, exceptionInfo);
  
  fwExternalApplications_createDipConfig(xmlFileContents, dipConfigName, exceptionInfo);
  if(dynlen(exceptionInfo)==0)
  {
    fwExternalApplications_createPublications(xmlFileContents, dipConfigName, exceptionInfo);
    fwExternalApplications_createSubscriptions(xmlFileContents, dipConfigName, exceptionInfo);
  }  
}

fwExternalApps_readXmlFile(string xmlPath, string &xmlFileContents, dyn_string &exceptionInfo)
{
  if(isfile(xmlPath))
    fileToString(xmlPath, xmlFileContents);
  else
    fwException_raise(exceptionInfo, "ERROR", "The XML configuration file could not be found (" + xmlPath + ")", "");      
}

fwExternalApplications_createDipConfig(string xmlFileContents, string &dipConfigName, dyn_string &exceptionInfo)
{
  string rc = gcsDIP_CreateConfig(xmlFileContents, dipConfigName);
  if (rc)
    fwException_raise(exceptionInfo, "ERROR", rc, "");
}

fwExternalApplications_createPublications(string xmlFileContents, string dipConfigName, dyn_string &exceptionInfo)
{
  string rc = gcsDIP_CreatePublications(xmlFileContents, dipConfigName);
  if(rc)
    if(strpos(rc, "Probably they are not declared") < 0)
      fwException_raise(exceptionInfo, "WARNING", rc, "");
}

fwExternalApplications_createSubscriptions(string xmlFileContents, string dipConfigName, dyn_string &exceptionInfo)
{
  string rc = gcsDIP_CreateSubscriptions(xmlFileContents, dipConfigName);
  if (rc)
    if(strpos(rc, "Probably they are not declared") < 0)
      fwException_raise(exceptionInfo, "WARNING", rc, "");
}

fwExternalApps_createDpStructure(string xmlFileContents, dyn_string types, dyn_string levels, dyn_string &exceptionInfo)
{
  int length;
  string dpName;
  mapping dpTypeMap;
  dyn_string dpesList, dpeTypesList;
  
  dpesList = gcsDIP_GetDpeList(xmlFileContents);
  dpeTypesList = gcsDIP_GetDpeTypeList(xmlFileContents);

  length = dynlen(dpesList);
  for(int i=1; i<=length; i++) 
  {
    dpesList[i] = substr(dpesList[i], 0, strpos(dpesList[i], "."));
    if(!mappingHasKey(dpTypeMap, dpesList[i]))
      dpTypeMap[dpesList[i]] = dpeTypesList[i];    
  }

  dynUnique(dpesList);
//DebugN(dpesList, dpTypeMap);  
  
  length = dynlen(dpesList);
  for(int i=1; i<=length; i++) 
  {
    int pathParts;
    string path, previousPath="";
    dyn_string parts, device, parentDevice;
    
    parts = strsplit(dpesList[i], fwDevice_HIERARCHY_SEPARATOR);
    pathParts = dynlen(parts);
    for(int j=1; j<=pathParts; j++)
    {
      path = previousPath + parts[j];
//DebugN("Checking if exists: " + path, dpExists(path));
      if(!dpExists(path))
      {
        int pos;
        
        device[fwDevice_DP_NAME] = parts[j];
        parentDevice[fwDevice_DP_NAME] = strrtrim(previousPath, fwDevice_HIERARCHY_SEPARATOR);

        if(mappingHasKey(dpTypeMap, path))
          device[fwDevice_DP_TYPE] = dpTypeMap[path];
        else
        {
//DebugN(levels, j, pathParts);
          if(j==pathParts)
            pos = dynContains(levels, "$");
          if(pos <= 0)
            pos = dynContains(levels, (string)j);
          if(pos <= 0)
            pos = dynContains(levels, "*");

          if(pos <= 0)
            device[fwDevice_DP_TYPE] = "FwExternalAppsNode";
          else
            device[fwDevice_DP_TYPE] = types[pos];
        }
//DebugN("Creating", device);
        fwDevice_create(device, parentDevice, exceptionInfo);
      }
      previousPath = path + fwDevice_HIERARCHY_SEPARATOR;
    } 
  }
}
