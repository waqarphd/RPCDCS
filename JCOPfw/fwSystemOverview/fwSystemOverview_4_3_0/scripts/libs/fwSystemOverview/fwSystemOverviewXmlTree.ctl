#uses "fwSystemOverview/fwSystemOverviewFsm.ctl"
#uses "fwSystemOverview/fwSystemOverviewLongTermReport.ctl"
mapping fwColorToColor;
const string rss_FOLDER = "/home/unicryo/HtmlFiles/";

void fwSysOverviewXmlTree_dumpFsmTreesToXml(string filePath, string screenshotsFolder)
{
  _fwSysOverviewXmlTree_initColorMapping(); 
  dyn_string soTrees;
  fwSystemOverviewFsm_getTrees(soTrees); 
  for(int i = 1; i<= dynlen(soTrees); i++)
  {
    int docId = xmlNewDocument();
    xmlAppendChild(docId, -1, XML_PROCESSING_INSTRUCTION_NODE, "xml version=\"1.0\" encoding=\"ISO-8859-1\"");  
    xmlAppendChild(docId, -1, XML_PROCESSING_INSTRUCTION_NODE, "xml-stylesheet type=\"text/xsl\" href=\"xmlTree.xsl\""); 
    int topNodeId = xmlAppendChild(docId, -1, XML_ELEMENT_NODE, "tree");
    xmlSetElementAttribute(docId, topNodeId, "time", formatTime("%H:%M %d/%m/%Y", getCurrentTime()));
    int treeID = fwSysOverviewXmlTree_addRoot(docId, topNodeId, soTrees[i], screenshotsFolder);
    dyn_int flags;
    dyn_string applications = fwFsm_getObjChildren(soTrees[i], soTrees[i], flags);  //fwCU_getChildren(types, "fwSO_LHC_Applications");
    fwSysOverviewXmlTree_addChildrenToXml(docId, applications, treeID, soTrees[i], screenshotsFolder, true);

    xmlDocumentToFile(docId, filePath + soTrees[i] +".xml");

    xmlCloseDocument(docId);
  }
}

void _fwSysOverviewXmlTree_initColorMapping()
{
  fwColorToColor["FwStateOKPhysics"] = "green";
  fwColorToColor["unAlarm_Ok"] = "green";  
  fwColorToColor["FwStateAttention3"] = "red";  
  fwColorToColor["FwStateAttention2"] = "orange";    
  fwColorToColor["unAlarm_AnalogHH"] = "orange";      
  fwColorToColor["FwStateAttention1"] = "yellow";  
  fwColorToColor["unAlarmMasked"] = "yellow";  
  fwColorToColor["_3DFace"] = "gray";
}
int fwSysOverviewXmlTree_addRoot(int docId, int nodeId, string tree, string screenshotsFolder)
{       
  string state, color, label;
  fwUi_getCurrentState(tree, tree, state);
  fwUi_getObjStateColor(tree, tree, state, color);
  //DebugN("tree: " + tree + " state: " + state + " color:" +color);
  fwUi_getLabel(tree, tree, label);
  int child = xmlAppendChild(docId, nodeId, XML_ELEMENT_NODE, "branch");
  xmlSetElementAttribute(docId, child, "id", tree);
  xmlSetElementAttribute(docId, child, "du", "0"); // the tree is never device unit
  xmlSetElementAttribute(docId, child, "state", state);
  xmlSetElementAttribute(docId, child, "label", label);
  if(mappingHasKey(fwColorToColor, color))
   xmlSetElementAttribute(docId, child, "color", fwColorToColor[color]); 
  else
  {
       xmlSetElementAttribute(docId, child, "color", "white"); 
       DebugN(color);
  }
  xmlSetElementAttribute(docId, child, "picture", screenshotsFolder + tree + ".png");   
  int subChild = xmlAppendChild(docId, child, XML_ELEMENT_NODE, "branchText");
  xmlAppendChild(docId, subChild, XML_TEXT_NODE, label);
  return child;
}
fwSysOverviewXmlTree_addChildrenToXml(int docId, dyn_string children, int nodeId, string cu, string screenshotsFolder, bool addPicture = false)
{
  dyn_int flags;
  for (int i=1; i<= dynlen(children); i++)
  {
    string node = children[i];
    if (strpos(node, "::") >0)
    {
      dyn_string tmpArr = strsplit(node, "::");
      node = tmpArr[1];
    }
    string du, color, state, label;
    string currentCu;
    if (fwSysOverviewFsm_isDomain(node))
      currentCu = node;
    else
      currentCu = cu;

    dyn_string currentNodeChildren =  fwFsm_getObjChildren(currentCu, node, flags);        

    //if it has children - > branch; 
    string childType = (dynlen(currentNodeChildren) > 0)? "branch":"leaf";
    du = fwFsm_isDU(currentCu, node)?"1":"0";
    
    fwUi_getCurrentState(currentCu, node, state);
    string mode = fwUi_getCUMode(currentCu, node);
	  if ((mode == "Excluded")|| (mode == "LockedOut") || (mode == "LockedOutPerm") || (mode == "ExcludedPerm") || (mode == "DEAD"))
      color = "_3DFace";
    else
      fwUi_getObjStateColor(currentCu, node, state, color);
    
    fwUi_getLabel(currentCu, node, label);
    int child = xmlAppendChild(docId, nodeId, XML_ELEMENT_NODE, childType);
    xmlSetElementAttribute(docId, child, "id", node);
    xmlSetElementAttribute(docId, child, "du", du);
    xmlSetElementAttribute(docId, child, "state", state);
    xmlSetElementAttribute(docId, child, "label", label);
    if(mappingHasKey(fwColorToColor, color))
      xmlSetElementAttribute(docId, child, "color", fwColorToColor[color]); 
    else
    {
      xmlSetElementAttribute(docId, child, "color", "white");       
      DebugN(color);
    }
    if (addPicture)
      xmlSetElementAttribute(docId, child, "picture", screenshotsFolder + node + ".png"); 
    
    int subChild = xmlAppendChild(docId, child, XML_ELEMENT_NODE, childType + "Text");
    xmlAppendChild(docId, subChild, XML_TEXT_NODE, label);
    if (dynlen(currentNodeChildren) > 0)
    {
      fwSysOverviewXmlTree_addChildrenToXml(docId, currentNodeChildren, child, currentCu, screenshotsFolder);
    }
    else if (du == "1") // if it is device unit
    {
      string dp;
      fwCU_getDevDp(currentCu + "::" + node, dp);
      if (dpTypeName(dp) == "IcemonPlc")
        fwSysOverviewXmlTree_addPlcDetails(docId, child, dp);
      else if (dpTypeName(dp) == "FwSystemOverviewProject")
        fwSysOverviewXmlTree_addProjectDetails(docId, child, dp);
      else if (dpTypeName(dp) == "FwFMCNode")
        fwSysOverviewXmlTree_addHostDetails(docId, child, dp);
      else if(dpTypeName(dp) == "IcemonSystemIntegrity")
        fwSysOverviewXmlTree_addSystemIntegrityDetails(docId, child, dp);
    }
  }
}

void fwSysOverviewXmlTree_addProjectDetails(int docId, int nodeId, string projectDp)
{
  if (dpTypeName(projectDp) != "FwSystemOverviewProject")
  {
    DebugN("Not an FwSystemOverviewProject: " + projectDp);
    return;
  }
  // get system information

  string systemName;
  dpGet(projectDp + fwSysOverview_PROJECT_SYSTEM, systemName);
  dyn_mixed systemInfo;
  fwInstallationDB_connect();
  fwInstallationDB_getPvssSystemProperties(systemName, systemInfo);
  // add attributes for the system information
  int child = xmlAppendChild(docId, nodeId, XML_ELEMENT_NODE, "project");
  if (dynlen(systemInfo) > 0)
  {
    fwSysOverviewXmlTree_addInfoNode(docId, child, "System Host", systemInfo[FW_INSTALLATION_DB_SYSTEM_COMPUTER]);     
    fwSysOverviewXmlTree_addInfoNode(docId, child, "System Name", systemInfo[FW_INSTALLATION_DB_SYSTEM_NAME]);   
    fwSysOverviewXmlTree_addInfoNode(docId, child, "System Number", systemInfo[FW_INSTALLATION_DB_SYSTEM_NUMBER]);   
  }
  //add description and state for the managers
  dyn_string managersDps = dpNames(projectDp + "/Manager*", "FwSystemOverviewManager");
  dyn_string managersTypeDpes, managersOptionsDpes, managersStateDpes;
  int numberOfManagers = dynlen(managersDps);
  for (int i=1; i <= numberOfManagers; i++)
  {
    managersTypeDpes[i] = managersDps[i] + fwSysOverview_MANAGER_TYPE;
    managersOptionsDpes[i] = managersDps[i] + fwSysOverview_MANAGER_OPTIONS;
    managersStateDpes[i] = managersDps[i] + fwSysOverview_MANAGER_STATE;    
  } 
  dyn_int managersStates;
  dyn_string managersTypes, managersOptions;
  dpGet(managersTypeDpes, managersTypes, managersStateDpes, managersStates, managersOptionsDpes,managersOptions);
  
  for (int i=1; i <= numberOfManagers; i++)
  {
    string color;
    if (dynlen(managersStates) == 0)
      DebugN(projectDp);
    switch(managersStates[i])
    {
      case 10:
        color = "red"; // abnormaly stopped
        break;
      case 0:
        color = "white"; // not running - normal
        break;
      case 2:
        color = "green"; // running
        break;
      case 3:
        color = "purple"; // blocked
        break;
    }
    int authPos = strpos(managersOptions[i], "-author");
    if (authPos >= 0)
    {
      string tmp = substr(managersOptions[i], 0, strlen(managersOptions[i]) - authPos);
      managersOptions[i] = tmp;
    }
    fwSysOverviewXmlTree_addDataNode(docId, child,  managersTypes[i] + " " + managersOptions[i], color);
  } 
}

void fwSysOverviewXmlTree_addHostDetails(int docId, int nodeId, string hostDp)
{
  if (dpTypeName(hostDp) != "FwFMCNode")
  {
    DebugN("Not an FwFMCNode: " + hostDp);
    return;
  }
  // get host information
  //get cpu and cpuspeed
  dyn_string devices, deviceDps;
  string modelName;
  string speed;
  string nodeName = fwFMC_getNodeName(hostDp);
  fwFMCMonitoring_getDevices(nodeName, "cpu", devices);

  for(int i = 1; i <= dynlen(devices); i++)
  {
    if(devices[i] == "-1")
      continue;

    dynAppend(deviceDps, hostDp + "/Monitoring/Cpus/" + devices[i]);
  }
  if(dynlen(devices) > 0 && devices[1] != -1)
  {
    dpGet(deviceDps[1] + ".info.model_name", modelName,
          deviceDps[1] + ".info.clock", speed);
  }
  string monitoringDp = hostDp + "/Monitoring";
  string name, distribution, lastBootUpTime, localDateTime, memory;
  dpGet(monitoringDp + ".OS.readings.name", name,
        monitoringDp + ".OS.readings.distribution", distribution,
        monitoringDp + "/Memory.readings.total", memory);

  int child = xmlAppendChild(docId, nodeId, XML_ELEMENT_NODE, "host");
  fwSysOverviewXmlTree_addInfoNode(docId, child, "Operating System", name);   
  fwSysOverviewXmlTree_addInfoNode(docId, child, "Distribution", distribution);     
  fwSysOverviewXmlTree_addInfoNode(docId, child, "CPU", modelName);  
  fwSysOverviewXmlTree_addInfoNode(docId, child, "CPU Speed", speed);  
  fwSysOverviewXmlTree_addInfoNode(docId, child, "Total Memory", memory);    
 
  string tmpStr;
  float memoryLoad, swap;
  dpGet(monitoringDp + "/Memory.readings.userMemory", memoryLoad,
        monitoringDp + "/Memory.readings.usedSwap", swap);
  sprintf(tmpStr, "%3.2f", memoryLoad);
  fwSysOverviewXmlTree_addInfoNode(docId, child, "Memory Load", tmpStr + "%");      
  sprintf(tmpStr, "%3.2f", swap);
  fwSysOverviewXmlTree_addInfoNode(docId, child, "Used Swap", tmpStr + "%");    
  float avgCpu = fwFMCMonitoring_getAverageCpuLoad(nodeName);  
  sprintf(tmpStr, "%3.2f", avgCpu);
  fwSysOverviewXmlTree_addInfoNode(docId, child, "Average CPU Load", tmpStr + "%");     
  dyn_string fileSystemDps;
  fwFMCMonitoring_getFSDps(nodeName, fileSystemDps);
  float usedFS;
  string fsMountPoint;
  for(int i=1; i <= dynlen(fileSystemDps); i++)
  {
    dpGet(fileSystemDps[i] + ".readings.mount_point", fsMountPoint,
          fileSystemDps[i] + ".readings.user", usedFS);
    sprintf(tmpStr, "%3.2f", usedFS);
    fwSysOverviewXmlTree_addInfoNode(docId, child, "Used FS " + fsMountPoint, tmpStr + "%");   
  }
   
  //add charts
  dyn_string charts = fwSysOverviewLongTermReport_getReportUrls(nodeName);
  for(int i=1; i<=dynlen(charts);i++)
  {
    fwSysOverviewXmlTree_addChartNode(docId, child, charts[i]);  
  }
}

void fwSysOverviewXmlTree_addPlcDetails(int docId, int nodeId, string plcDp)
{
 if (dpTypeName(plcDp) != "IcemonPlc")
  {
    DebugN("Not an IcemonPlc: " + plcDp);
    return;
  }
  string application, ip, plcTime;
  dyn_string metricValuesDps, metricAlarmsDps, metricAlarmActiveDps, validDps;
  dyn_int metricValues;
  dyn_bool metricAlarms, metricAlarmActive, valid;  
  dpGet(plcDp + ".Configuration.application", application,
        plcDp + ".Configuration.IP", ip,
        plcDp + ".ProcessInput.PLCtime", plcTime);
  
  int child = xmlAppendChild(docId, nodeId, XML_ELEMENT_NODE, "plc");
  fwSysOverviewXmlTree_addInfoNode(docId, child, "Manufacturer", application);
  fwSysOverviewXmlTree_addInfoNode(docId, child, "IP", ip);  
  fwSysOverviewXmlTree_addInfoNode(docId, child, "PLC Time", plcTime);  

  string prefix;
  int length;
  if (application =="SIEMENS")
  {
    prefix= "SI_"  ;
    length = PLC_SIEMENS_METRIC_LENGTH;
  }
  else if (application == "SCHNEIDER")
  {
    prefix = "SC_";
    length = PLC_SCHNEIDER_METRIC_LENGTH;
  }
  if (prefix != "")
  {
    for (int i=1; i<=length; i++)
    {
      dynAppend(metricValuesDps, plcDp + ".ProcessInput.metric[" + i+"]"); 
      dynAppend(validDps, plcDp + ".ProcessInput.valid"); 
      dynAppend(metricAlarmsDps, plcDp + ".ProcessInput.metric[" + i+"]:_alert_hdl.._act_state");      
      dynAppend(metricAlarmActiveDps, plcDp + ".ProcessInput.metric[" + i+"]:_alert_hdl.._active");          
     }
  }
  dpGet(validDps, valid, metricValuesDps, metricValues, metricAlarmsDps, metricAlarms, metricAlarmActiveDps, metricAlarmActive);
  for (int i=1; i<=dynlen(metricValues); i++)
  {
     string metricColor = "green";
     if(!valid[i])
       metricColor = "cyan";
     else if(!metricAlarmActive[i])// if the alarm is not active
       metricColor = "yellow";
     else if ((metricAlarms[i]!=0) && metricValues[i] == -1)
       metricColor = "cyan"; 
     else if ((metricAlarms[i]!=0))
       metricColor = "red";
  
     fwSysOverviewXmlTree_addDataNode(docId, child, getCatStr("plcMonitoring", getCatStr("plcMonitoring", prefix + i)), metricColor);
  }
  
}

void fwSysOverviewXmlTree_addSystemIntegrityDetails(int docId, int nodeId, string siDp)
{  
 if (dpTypeName(siDp) != "IcemonSystemIntegrity")
  {
    DebugN("Not IcemonSystemIntegrity: " + siDp);
    return;
  }
  // get the systemName
  int child = xmlAppendChild(docId, nodeId, XML_ELEMENT_NODE, "systemIntegrity");  
  string systemName;
  dpGet(siDp + ".systemName", systemName);
  fwSysOverviewXmlTree_addInfoNode(docId, child, "System Name", systemName);
  if (fwSysOverview_isSystemConnected(systemName)) 
  {
    dyn_dyn_string siAlarmDescriptionsAndColors = fwSysOverviewXmlTree_getSystemIntegrityApplicationAlarmsAndColors(siDp);
 
    for (int i=1; i<=dynlen(siAlarmDescriptionsAndColors); i++)
    {
       string description = siAlarmDescriptionsAndColors[i][1];
       strreplace(description, "->", "");
       string siColor = siAlarmDescriptionsAndColors[i][2];
       string color = siColor;
       if (mappingHasKey(fwColorToColor, siColor))
         color = fwColorToColor[color];      
   
        fwSysOverviewXmlTree_addDataNode(docId, child, description, color);    
    }
  }
  else
     fwSysOverviewXmlTree_addInfoNode(docId, child, "Connection", "System not connected!");
}

dyn_dyn_string fwSysOverviewXmlTree_getSystemIntegrityApplicationAlarmsAndColors(string siDp)
{
  dyn_dyn_string siAlarmDescriptionsAndColors;
  // if the summary alert is not active we return the stored list and green as a color;
  bool alarm, connected;
  dpGet(siDp + ".alarm", alarm,
        siDp + ".connected", connected);
  string color = connected?"green":"purple";
  if (!alarm || !connected)
  {
    dyn_string alarmsDescriptions;
    dpGet(siDp + ".applicationAlarmsList.descriptions", alarmsDescriptions);
    for(int i=1; i<=dynlen(alarmsDescriptions);i++)
    {
      siAlarmDescriptionsAndColors[i][1] = alarmsDescriptions[i];
      siAlarmDescriptionsAndColors[i][2] = color;      
    }
  }
  else
  {
    dyn_string applicationAlarms = icemon_getUnApplicaitonSummayAlertDataPoints(siDp);
    for(int i=1; i<=dynlen(applicationAlarms);i++)
    {
      string description = unGenericDpFunctions_getDescription(applicationAlarms[i]);
      if (description == "")
        description = applicationAlarms[i];
      bool alarmPresent;
      dpGet(applicationAlarms[i] + ":_alert_hdl.._act_state", alarmPresent);
      string color = alarmPresent? "red":"green";
      siAlarmDescriptionsAndColors[i][1] = description;
      siAlarmDescriptionsAndColors[i][2] = color;     
    }
  }
   return siAlarmDescriptionsAndColors;
}


int fwSysOverviewXmlTree_addInfoNode(int docId, int nodeId, string description, string value)
{
  int infoNode = xmlAppendChild(docId, nodeId, XML_ELEMENT_NODE, "info");
  xmlSetElementAttribute(docId, infoNode, "description", description);     
  xmlSetElementAttribute(docId, infoNode, "value", value);  
  return  infoNode; 
}
int fwSysOverviewXmlTree_addDataNode(int docId, int nodeId, string description, string color)
{
  int dataNode = xmlAppendChild(docId, nodeId, XML_ELEMENT_NODE, "data");
  xmlSetElementAttribute(docId, dataNode, "description", description);     
  xmlSetElementAttribute(docId, dataNode, "color", color);  
  return  dataNode; 
}
int fwSysOverviewXmlTree_addChartNode(int docId, int nodeId, string chartUrl)
{
  int dataNode = xmlAppendChild(docId, nodeId, XML_ELEMENT_NODE, "chart");
  strreplace(chartUrl, "&amp;", "&");
  xmlSetElementAttribute(docId, dataNode, "url", chartUrl);     
  return  dataNode; 
}

void fwSysOverviewXmlTree_createTreesHtmlFrame(string filePath = "")
{
  dyn_string soTrees;
  fwSystemOverviewFsm_getTrees(soTrees);  
  
  string html;
  if (dynlen(soTrees) > 0)
  {
    html = "<!DOCTYPE html PUBLIC \"-//W3C//DTD XHTML 1.0 Transitional//EN\" \"http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd\">" +
             "<html xmlns=\"http://www.w3.org/1999/xhtml\">"+
             "<head>" +
             "<meta content=\"text/html; charset=iso-8859-1\" http-equiv=\"Content-Type\" />"+
             "<title>MOON</title>" +
             "<link href=\"styles/styles.css\" rel=\"stylesheet\" type=\"text/css\" />"+
             "<style type=\"text/css\">"+
             "html, body, iframe { margin:0; padding:0; height:100%; width:100%}"+
             "iframe { display:block; width:100%; border:none; }"+
             "</style>"+
             "<script type=\"text/javascript\" src=\"scripts/scripts.js\"></script>"+
             "</head>"+
             "<body onload=\"load('" + soTrees[1] + "')\">"+
             "<table style=\"height: 95%;width:100%\">" +
             "<tr>" +
        		 "<td style=\"padding-bottom:0px\">"+
  		       "<ul class=\"tabs\">";
 
  
    for(int i = 1; i<= dynlen(soTrees); i++)
    {
      string label;
      fwUi_getLabel(soTrees[i], soTrees[i], label);
      html += "<li id=\"" + soTrees[i] + "\"><a href=\"tree/" + soTrees[i] + ".xml\" target=\"fsmTreeFrame\" onclick=\"changeSelection('" + soTrees[i] + "')\">" +label+ "</a></li>";

    }
    html += "</ul>";
    html += "</td>";    
    html += "<td class=\"t2navbarcell\" >";
    html += "<a href=\"rss/moonRssFrontPage.html\" class=\"t2navbar\"><img src=\"styles/feed.gif\" alt=\"News Feed\" height=\"16\" width=\"16\" />News Feed</a>";
  	html+= "</td>";
  	html +="</tr>";
  	html +="<tr valign=\"top\">";
  	html +="<td style=\"width: 90%; height: 100%;\" colspan=\"2\">";
  	html +="<iframe id=\"fsmTreeFrame\" frameborder=\"0\" name=\"fsmTreeFrame\" scrolling=\"auto\" src=\"tree/"+soTrees[1]+".xml\" style=\"overflow:visible\" >";
  	html +="</iframe></td>";
    html +="</tr>";
    html +="</table>";
    html +="</body>";
    html +="</html>";
    string destinationFolder = filePath==""?_fwSysOverviewLongTermReport_getFilePath():filePath;
    string filePath =  destinationFolder  + "/index.html";
    file f = fopen(filePath, "w+");
    int err = ferror(f);
    if (!err)
    {
      fputs(html, f);
      fclose(f);
    }
  }
}

