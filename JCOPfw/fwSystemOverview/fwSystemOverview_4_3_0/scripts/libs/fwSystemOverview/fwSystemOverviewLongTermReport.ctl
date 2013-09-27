#uses "fwSystemOverview/fwSystemOverviewFsm.ctl"
#uses "fwSystemOverview/fwSystemOverviewReport.ctl"
#uses "fwSystemOverview/fwSystemOverviewNotifications.ctl"

const string FWSYSOVERVIEWLONGTERMREPORT_REPORTS_FOLDER = "reportsLong";
const string FWSYSOVERVIEWLONGTERMREPORT_REPORT_DPTYPE = "_FwSystemOverviewReportUrl";
const string FWSYSOVERVIEWLONGTERMREPORT_REPORT_PREFIX = "reportUrls_";

bool plotOnTheSameChart = false;
const int NUMBER_OF_ELEMETS_IN = 9;
string connectionName = "reportsConnection";

int _fwSysOverviewLongTermReport_getPlotsPerChart()
{
  int plotsPerChart;
  dpGet("fwSystemOverviewReportsConfig.longTerm.plotsPerChart", plotsPerChart);
  return plotsPerChart;
}

int _fwSysOverviewLongTermReport_getReportPeriod()
{
  int reportPeriod;
  dpGet("fwSystemOverviewReportsConfig.longTerm.reportPeriod", reportPeriod);
  return reportPeriod;
}
string _fwSysOverviewLongTermReport_getFilePath()
{
  string filePath;
  dpGet("fwSystemOverviewReportsConfig.filePath", filePath);
  return filePath;
}

dyn_string fwSysOverviewLongTermReport_getReportUrls(string node)
{
  string fsUrl, usedMemoryUrl, usedSwapUrl;
  string dpName = FWSYSOVERVIEWLONGTERMREPORT_REPORT_PREFIX + node;
  if (dpExists(dpName))
  { 
    dpGet(dpName + ".userMemory", usedMemoryUrl,
          dpName + ".usedSwap", usedSwapUrl,
          dpName + ".fs", fsUrl);
  }
  return makeDynString(fsUrl, usedMemoryUrl, usedSwapUrl);
}

void fwSysOverviewLongTermReport_storeChartsUrls(mapping dpeToData, time endDate, int numberOfDays)
{
  string chartProperty; // what we are plotting, i.e userMemory, usedSwap, fs, etc
  string chartCaption;
  dyn_string dpes = mappingKeys(dpeToData);
  for (int i=1; i <= dynlen(dpes); i++)
  {
    string dpName = dpSubStr(dpes[i], DPSUB_DP_EL);
    string node = fwFMC_getNodeName(dpName);
    if (node != "")
    {
      dyn_string strArr = strsplit(dpes[i], ".");
      string type = dpTypeName(dpName);
      if (type == "FwFMCFs")
      {
        chartProperty = "fs";
        chartCaption = "File System /opt";
      }
      else if (type == "FwFMCMem")
      {
        chartProperty = strArr[dynlen(strArr)];
        if (chartProperty == "userMemory")
          chartCaption = "Used Memory";
        else if (chartProperty == "usedSwap")
          chartCaption = "Used Swap";
        else
          chartCaption = chartProperty;
      }
      
      dyn_string charts = _fwSysOverviewLongTermReport_createChartUrl(dpes[i], dpeToData[dpes[i]], endDate, numberOfDays, chartCaption, "%");
      if(!dpExists(FWSYSOVERVIEWLONGTERMREPORT_REPORT_PREFIX + node))
      {
        dpCreate(FWSYSOVERVIEWLONGTERMREPORT_REPORT_PREFIX + node, FWSYSOVERVIEWLONGTERMREPORT_REPORT_DPTYPE);
      }
      
      if(dynlen(charts) > 0)
      {
        dpSet(FWSYSOVERVIEWLONGTERMREPORT_REPORT_PREFIX + node + "." + chartProperty, charts[1]);
      }
    }
      
  }
}

void fwSysOverviewLongTermReport_createLongTermReportsHtml(string tree, string filePath="")
{
  dyn_int types;
  dyn_string applications = fwCU_getChildren(types, tree);
  string html;
  html = "<!DOCTYPE html PUBLIC \"-//W3C//DTD XHTML 1.0 Transitional//EN\" \"http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd\">" +
           "<html xmlns=\"http://www.w3.org/1999/xhtml\">"+
           "<head>" +
           "<meta content=\"text/html; charset=iso-8859-1\" http-equiv=\"Content-Type\" />"+
           "<title>MOON</title>" +
           "<link href=\"../../styles/styles.css\" rel=\"stylesheet\" type=\"text/css\" />"+
           "<style type=\"text/css\">"+
           "html, body, iframe { margin:0; padding:0; height:100%; width:100%}"+
           "iframe { display:block; width:100%; border:none; }"+
           "</style>"+
           "<script type=\"text/javascript\" src=\"../../scripts/scripts.js\"></script>"+
           "</head>"+
           "<body onload=\"loadLong('" + applications[1] + "')\">"+
           "<table style=\"height:95%\">"+
  	       "<tr style=\"align: right; valign: bottom\">"+
    		   "<td colspan=\"2\">"+
  		     "<ul id=\"nav\">"+
  			   "<li id=\"nav-1\"><a href=\"../../tree/" + tree + ".xml\">Overview</a></li>"+
  			   "<li id=\"nav-2\"><a href=\"../moonAlarms.html\">Alarms</a></li>"+
  			   "<li id=\"nav-3\"><a href=\"../reportsDaily/dailyReports.html\">Daily reports</a></li>"+
  			   "<li id=\"nav-3\" class=\"current\"><a href=\"#\">Long-term reports</a></li>"+
  		     "</ul>"+
  		     "</td>"+
  	       "</tr>"+
  	       "<tr valign=\"top\">"+
  		     "<td style=\"width: 10%; align: left\">";
 
  if (dynlen(applications) > 0)
  {
    html += "<ul id=\"menu\">";
    for(int i=1; i<=dynlen(applications);i++)
    {
      string label = fwSysOverviewNotifications_getApplicationLabel(tree, applications[i]);
    
      html += "<li id=\"" + applications[i] + "\" onclick=\"changeSelectionLong('" +  applications[i]  + "')\"><a href=\"" +  applications[i]  + ".html\" target=\"reportsFrame\">" + label + "</a></li>";
    }
	
    html += "</ul>";
  }
  html += "</td>";
  html += "<td style=\"width: 90%;height:100%\">";
  html += "<iframe src=\"" +  applications[1] + ".html\" scrolling=\"auto\" id=\"reportsFrame\" name=\"reportsFrame\" frameborder=\"0\"></iframe>";
  html += "</td>";
  html += "</tr>";
  html += "</table>";
  html += "</body>";
  html += "</html>";
  string label;
  fwUi_getLabel(tree, tree, label);
  string destinationFolder = filePath==""?_fwSysOverviewLongTermReport_getFilePath():filePath;
  string destinationFolder = filePath==""?_fwSysOverviewLongTermReport_getFilePath():filePath;
  if(!isdir(destinationFolder + strtolower(label) + "/"))
    mkdir(destinationFolder + strtolower(label) + "/", "755");
  if(!isdir(destinationFolder + strtolower(label) + "/" + FWSYSOVERVIEWLONGTERMREPORT_REPORTS_FOLDER + "/"))
    mkdir(destinationFolder + strtolower(label) + "/" + FWSYSOVERVIEWLONGTERMREPORT_REPORTS_FOLDER + "/", "755");
  string filePath =  destinationFolder + strtolower(label) + "/" + FWSYSOVERVIEWLONGTERMREPORT_REPORTS_FOLDER + "/longTermReports.html";
  file f = fopen(filePath, "w+");
  int err = ferror(f);
  if (!err)
  {
    fputs(html, f);
    fclose(f);
  }
}
void fwSysOverviewLongTermReport_createReportFile(string application, string filePath="")
{
   int endDate = getCurrentTime();
   string html = _fwSysOverviewLongTermReport_generateCommonHtmlStart();
   int reportPeriod = _fwSysOverviewLongTermReport_getReportPeriod();
   dyn_string usedMemoryCharts = fwSysOverviewLongTermReport_createApplicationUsedMemoryCharts(application, endDate, reportPeriod, plotOnTheSameChart);
   html += _fwSysOverviewLongTermReport_generateChartsHtml(usedMemoryCharts, "usedMemoryTrends");
   dyn_string usedSwapCharts = fwSysOverviewLongTermReport_createApplicationUsedSwapCharts(application, endDate, reportPeriod, plotOnTheSameChart);    
   html += _fwSysOverviewLongTermReport_generateChartsHtml(usedSwapCharts, "usedSwapCharts");    
   dyn_string fsOptCharts = fwSysOverviewLongTermReport_createApplicationFSOptCharts(application, endDate, reportPeriod, plotOnTheSameChart);    
   html += _fwSysOverviewLongTermReport_generateChartsHtml(fsOptCharts, "fsOptCharts");    
   dyn_string monitoredProcessesCharts = fwSysOverviewLongTermReport_createApplicationMonitoredProcessesCharts(application, endDate, reportPeriod);    
   html += _fwSysOverviewLongTermReport_generateChartsHtml(monitoredProcessesCharts, "monitoredProcessesCharts");
   html += _fwSysOverviewLongTermReport_generateCommonHtmlEnd();
   string path;
   int type;
   string parent =  fwCU_getParent(type, application);
   string destinationFolder = filePath==""?_fwSysOverviewLongTermReport_getFilePath():filePath;
   if (parent != "")
   {
     string label;
     fwUi_getLabel(parent, parent, label);
     if (!isdir(destinationFolder + strtolower(label) + "/"))
       mkdir(destinationFolder + strtolower(label) + "/", "755");
     if(!isdir(destinationFolder + strtolower(label)+"/" + FWSYSOVERVIEWLONGTERMREPORT_REPORTS_FOLDER + "/"))
       mkdir(destinationFolder + strtolower(label)+"/" + FWSYSOVERVIEWLONGTERMREPORT_REPORTS_FOLDER + "/" , "755");
     path =  destinationFolder + strtolower(label) + "/" + FWSYSOVERVIEWLONGTERMREPORT_REPORTS_FOLDER + "/";
   } 
   else    
   {
     if (!isdir(destinationFolder + "/" +FWSYSOVERVIEWLONGTERMREPORT_REPORTS_FOLDER + "/"))
       mkdir(destinationFolder + "/" +FWSYSOVERVIEWLONGTERMREPORT_REPORTS_FOLDER + "/", "755" );
     path =  destinationFolder + "/" +FWSYSOVERVIEWLONGTERMREPORT_REPORTS_FOLDER + "/";
   }   
   file f = fopen(path + application + ".html", "w+");
   int err = ferror(f);
   if (!err)
   {
     fputs(html, f);
     fclose(f);
   }
  
}

string _fwSysOverviewLongTermReport_generateCommonHtmlStart()
{
  string html;
  html += "<!DOCTYPE HTML PUBLIC \"-//W3C//DTD HTML 4.01 Transitional//EN\"";
  html += "http://www.w3.org/TR/html4/loose.dtd\">";
  html += "<html>";
  html += "<head>";
  html += "<title>MOON</title>";
  html += "</head>";
  html += "<body>";
  html +="<div id=\"trends\" style = \"float:right;width:100% \">";
  return html;
}
string _fwSysOverviewLongTermReport_generateCommonHtmlEnd()
{
  string html;
  html += "</div>";
  html += "</td>";
  html += "</tr>";
  html += "</table>";
  html += "</body>";
  html += "</html>";
  return html;
}
string _fwSysOverviewLongTermReport_generateChartsHtml(dyn_string charts, string htmlId)
{
  string html = "<div id=\"" + htmlId + "\">" ;
  for (int i=1; i<= dynlen(charts); i++)
  {
    html += "<img alt=\"cht\" src='" + charts[i] + "' >";
  }
  html += "</div>";
  return html;
}

dyn_string _fwSysOverviewLongTermReport_createApplicationFMCNodeMemCharts(string application, time endDate, int days, string dpeEnding, string chartTitle, bool plotOnTheSameChart = true)
{
  dyn_string chartUrls;
  dyn_string memoryDps;
  dyn_dyn_mixed data;
  dyn_dyn_string dps = fwSysOverviewFsm_getChildrenOfTypeWithDomain(application, "FwFMCNode", application);   
  for(int i = 1; i <= dynlen(dps); i++)
  {
    string memoryDp = dps[i][1] + dpeEnding;
    dynAppend(memoryDps, memoryDp);
  }
  
  int rc = fwSysOverviewLongTermReport_getAverageDataOverTime(endDate, days, memoryDps, data);
  if (rc==0)
  {
    _fwSysOverviewLongTermReport_prepareDataMultipleDp(endDate, days, memoryDps, data);
    //DebugN(data);
    chartUrls = _fwSysOverviewLongTermReport_createChartUrl(memoryDps, data, endDate, days, chartTitle,"%", plotOnTheSameChart);
    //DebugN(chartUrls);
  }
 
  return chartUrls;
}

//the purpose of this method is to provide enpugh data to make a plot, i.e. if there is none or only one archived values for the period it adds the current value
void _fwSysOverviewLongTermReport_prepareData(time endDate, int days, string dpe, dyn_dyn_mixed& data)
{
  dpe = dpSubStr(dpe, DPSUB_SYS_DP_EL);
  int rowsCount = dynlen(data);
  time startDate = (int)endDate - (days-1)*24*60*60;
  string start = formatTime("%d/%m/%Y", startDate);
  string end = formatTime("%d/%m/%Y", endDate);
  float currentVal;
  dpGet(dpe, currentVal);
  //round to 1 digit after decimal
  string tmpStr;
  sprintf(tmpStr, "%3.2f", currentVal);
  currentVal = tmpStr;
  if (rowsCount == 0)// we don't have any archived data => just add the current value as start and end value
  {
    data[1] = makeDynString(start, currentVal, dpe);
    data[2] = makeDynString(end, currentVal, dpe);
  }  
  else if (rowsCount == 1)//we don't have enough data to plot 
  {
    if (data[1][1] != end)//if the data is not for the last day->add current value as an end date value
    {
      data[2] = makeDynString(end, currentVal, dpe);
     
    }
    else //put the value as a start value
    {
      dyn_string tmp = data[1];
      data[1] = makeDynString(start, data[1][2], dpe);
      data[2] = tmp;
    }
  }
  else if (data[dynlen(data)][1] != end) // if we don't have data for the last day ->add the current value
  {
    data[dynlen(data)] = makeDynString(end, currentVal, dpe);
   
  }  
 

}

void _fwSysOverviewLongTermReport_prepareDataMultipleDp(time endDate, int days, dyn_string dpes, dyn_dyn_mixed& data, bool store = true)
{
  mapping dpeToData;
  dyn_dyn_mixed newData;
  if (dynlen(data) > 0)
  {
    dyn_dyn_mixed portionedData = _fwSysOverviewLongTermReport_portionData(data, 1);
    dpeToData = _fwSysOverviewLongTermReport_makeMapping(portionedData);
    dyn_string dpesWithData = mappingKeys(dpeToData);
    for(int i=1; i<=dynlen(dpes);i++)
    {
      dpes[i] = dpSubStr(dpes[i], DPSUB_SYS_DP_EL);
      dyn_dyn_mixed dpeData;
      if (dynContains(dpesWithData, dpes[i]))
        dpeData = dpeToData[dpes[i]];
      
      _fwSysOverviewLongTermReport_prepareData(endDate, days, dpes[i], dpeData);      
      //store back to the mapping 
      dpeToData[dpes[i]] = dpeData;
      dynAppend(newData, dpeData);
      
    }
    
  }
  else
  {
    for(int i =1; i<=dynlen(dpes);i++)
    {
      dyn_dyn_mixed dpeData;
      _fwSysOverviewLongTermReport_prepareData(endDate, days, dpes[i], dpeData);
      //store back to the mapping 
      dpeToData[dpes[i]] = dpeData;
      dynAppend(newData, dpeData);
    }
  }
  if(store)
    fwSysOverviewLongTermReport_storeChartsUrls(dpeToData, endDate, days);
  data = newData;
}

mapping _fwSysOverviewLongTermReport_makeMapping(dyn_dyn_mixed portionedData)
{
  mapping dpeToData;
  for (int i=1; i<=dynlen(portionedData); i++)
  {
    dyn_dyn_mixed dpeData  = portionedData[i];
    // 1 because it for sure have at least one line and 3 because thedpe is in the third column
    dpeToData[dpeData[1][3]] = dpeData;
  }
  return dpeToData;
}


string _fwSysOverviewLongTermReport_getFileSystemDp(string fmcNode, string mountPoint)
{
  dyn_string fileSystemDps = dpNames(fmcNode + "/Monitoring/FS/fs_*", "FwFMCFs");
  string fsMountPoint;
  for(int i=1; i<=dynlen(fileSystemDps); i++)
  {
    dpGet(fileSystemDps[i] + ".readings.mount_point", fsMountPoint);
    if (fsMountPoint == mountPoint)
      return fileSystemDps[i];
  }
  return ""; 
}
dyn_string fwSysOverviewLongTermReport_createApplicationFSRootCharts(string application, time endDate, int days, bool plotOnTheSameChart = true)
{
  return _fwSysOverviewLongTermReport_createApplicationFSCharts(application, endDate, days, "/", "FS /", plotOnTheSameChart);
}

dyn_string fwSysOverviewLongTermReport_createApplicationFSOptCharts(string application, time endDate, int days, bool plotOnTheSameChart = true)
{
  return _fwSysOverviewLongTermReport_createApplicationFSCharts(application, endDate, days, "/opt", "FS /opt", plotOnTheSameChart);
}

dyn_string _fwSysOverviewLongTermReport_createApplicationFSCharts(string application, time endDate, int days, string mountPoint,  string chartTitle, bool plotOnTheSameChart = true)
{
  dyn_string chartUrls;
  dyn_string fileSystemDps;
  dyn_dyn_mixed data;
  dyn_dyn_string dps = fwSysOverviewFsm_getChildrenOfTypeWithDomain(application, "FwFMCNode", application);   
  for(int i = 1; i <= dynlen(dps); i++)
  {
    string fileSystemDp = _fwSysOverviewLongTermReport_getFileSystemDp(dps[i][1], mountPoint);
    if(fileSystemDp == "")
      continue;
    dynAppend(fileSystemDps, fileSystemDp + ".readings.user");
  }
  int rc = fwSysOverviewLongTermReport_getAverageDataOverTime(endDate, days, fileSystemDps, data);
  if (rc==0)
  {  
    _fwSysOverviewLongTermReport_prepareDataMultipleDp(endDate, days, fileSystemDps, data);
    chartUrls = _fwSysOverviewLongTermReport_createChartUrl(fileSystemDps, data, endDate, days, chartTitle, "%", plotOnTheSameChart);
  }
  
  return chartUrls;
}

dyn_string fwSysOverviewLongTermReport_createApplicationUsedSwapCharts(string application, time endDate, int days, bool plotOnTheSameChart = true)
{
  return _fwSysOverviewLongTermReport_createApplicationFMCNodeMemCharts(application, endDate, days,  "/Monitoring/Memory.readings.usedSwap", "Used Swap", plotOnTheSameChart);
}
dyn_string fwSysOverviewLongTermReport_createApplicationUsedMemoryCharts(string application, time endDate, int days, bool plotOnTheSameChart = true)
{
  return _fwSysOverviewLongTermReport_createApplicationFMCNodeMemCharts(application, endDate, days,  "/Monitoring/Memory.readings.userMemory", "Used Memory", plotOnTheSameChart);
}

//date should be dd/mm/yyyy
time _fwSysOverviewLongTermReport_convertStringToTime(string date)
{
  dyn_string dateStr = strsplit(date, "/");
  if (dynlen(dateStr) != "3")
    return 0;
  return makeTime(dateStr[3], dateStr[2], dateStr[1]);
}

int _fwSysOverviewLongTermReport_getDaysBetween(time startOriginal, time endOriginal)
{
  //eliminate the differences caused by the presence of time
  time start = makeTime(year(startOriginal), month(startOriginal), day(startOriginal));
  time end = makeTime(year(endOriginal), month(endOriginal), day(endOriginal));  
  int timePeriod = (int)end - (time) start;
  if (timePeriod < 0)
   timePeriod = -timePeriod;
  int numberOfDays = timePeriod/(60*60*24);
  return numberOfDays; 
}

dyn_string _fwSysOverviewLongTermReport_getLabels(time endDate, int numberOfDays)
{
  dyn_string labels;
  string format = "%d/%m";
  string end = formatTime(format, endDate);
  time startDate = (int)endDate - (numberOfDays-1)*24*60*60;
  //we always want 7 labels, including the first and the last date
  int ratio = numberOfDays/6;
  dynAppend(labels, formatTime(format, startDate));
  int cycleLimit = (int) endDate + 24*60*60;
  for(int i = (int)startDate + ratio*24*60*60; i < cycleLimit; i+=ratio*24*60*60)
  {
    dynAppend(labels, formatTime(format,(time) i));
  }
  dynAppend(labels, formatTime(format, endDate));
  return labels;
}

void _fwSysOverviewLongTermReport_formatChartDataString(time end, int days, dyn_dyn_mixed data, string& chartDataStr, string& chartLegend)
{
  time start = (int)end - (days-1)*24*60*60;
  //data is first ordered by dpName and then by date -> when dp changes new series for the chart  
  float xAxisDataRange = 100./(days-1);
  //round to 1 digit after decimal
  string tmpStr;
  sprintf(tmpStr, "%3.1f", xAxisDataRange);
  //set it back to the float
  xAxisDataRange = (float) tmpStr;
  float currentXAxisData = 0;
  string lastDp;
  string xAxisStr, avgDataStr;
  dyn_string legend;
  for (int i=1; i <= dynlen(data); i++)
  {
    if (lastDp != "" &&  lastDp != data[i][3])
    {
      //first remove the last , from both strings
      xAxisStr = substr(xAxisStr,0, strlen(xAxisStr)-1);
      avgDataStr = substr(avgDataStr,0, strlen(avgDataStr)-1);
      //save
      chartDataStr += xAxisStr + "|" + avgDataStr + "|";
      //clear for the next dpe
      xAxisStr = "";
      avgDataStr = "";
    }
    if (lastDp == "" | lastDp != data[i][3])
      dynAppend(legend, fwFMC_getNodeName( data[i][3])); 
   
    xAxisStr +=  xAxisDataRange*_fwSysOverviewLongTermReport_getDaysBetween(start, _fwSysOverviewLongTermReport_convertStringToTime(data[i][1])) + ",";
    avgDataStr += data[i][2] + ",";
    lastDp = data[i][3];
  }
  //add the last values
  if (xAxisStr != "" && avgDataStr !="")
  {
    xAxisStr = substr(xAxisStr,0, strlen(xAxisStr)-1);
    avgDataStr = substr(avgDataStr,0, strlen(avgDataStr)-1);
    chartDataStr += xAxisStr + "|" + avgDataStr + "|";
  }
  //remove the last |
  if(strlen(chartDataStr)>0)
    chartDataStr = substr(chartDataStr, 0, strlen(chartDataStr)-1);

  fwGeneral_dynStringToString(legend, chartLegend);
}

int fwSysOverviewLongTermReport_getAverageDataOverTime(time endDate, int numberOfDays, dyn_string dps, dyn_dyn_mixed& data)
{
  string end = formatTime("%d/%m/%Y", endDate);
  time startDate = (int)endDate - (numberOfDays-1)*24*60*60;
  string start = formatTime("%d/%m/%Y", startDate);
  string dpsStr;
  //ensure that the system name is included
  for(int i=1; i<=dynlen(dps); i++)
  {
    dps[i] = dpSubStr(dps[i], DPSUB_SYS_DP_EL);
    if (i%NUMBER_OF_ELEMETS_IN != 0 || (i%NUMBER_OF_ELEMETS_IN == 0 && i == dynlen(dps)))
      dpsStr += "'" + dps[i] + "'" + ",";
    else
    {
      dpsStr += "'" + dps[i] + "') or b.ELEMENT_NAME in(";
    }
    
  }
  //string dpsStr = (string) dps;
  //strreplace(dpsStr, " | ", "','");
  dpsStr = substr(dpsStr, 0 , strlen(dpsStr)-1);
  int rc;
  if (strlen(dpsStr) > 0)
  {
    string query = "SELECT TO_CHAR(trunc(TS), 'dd/mm/yyyy'), TO_CHAR(avg(value_number), '999.9'), b.ELEMENT_NAME  "+
                   "FROM eventhistory a inner join elements b "+
                   "ON a.ELEMENT_ID=B.ELEMENT_ID "+
                   "WHERE a.TS >="+
                   "TO_DATE(:1, 'dd/mm/yyyy') "+
                   "AND ( b.ELEMENT_NAME in(" + dpsStr+") " + 
                   " ) AND value_number <= 100 " + 
                   "GROUP BY trunc(TS), b.ELEMENT_NAME " +
                   "ORDER BY b.ELEMENT_NAME, trunc(TS) ASC";
 
    dyn_mixed var;
    var[1] = start;
    rc = _fwSysOverviewLongTermReport_executeQuery(query, var, data);
    //DebugN(data);
  }
  else 
    rc = 1;
  return rc;
}

int _fwSysOverviewLongTermReport_executeQuery(string query, dyn_mixed record, dyn_dyn_mixed& data)
{
 

  dbCommand cmd;
  string errTxt;
  
  string server, username, password, owner;
  int plotsPerChart, reportPeriod;
  string filePath;
  int rc = -1;
  if(dpExists("fwSystemOverviewReportsConfig"))
  {
   dpGet("fwSystemOverviewReportsConfig.dbConnection.server", server,
         "fwSystemOverviewReportsConfig.dbConnection.username", username,
         "fwSystemOverviewReportsConfig.dbConnection.password", password,
         "fwSystemOverviewReportsConfig.dbConnection.schemaOwner", owner);
          
    rc = fwSysOverviewLongTermReport_openRdbConnection(server, username, password, owner); 
    if (!rc)
    {
      rdbStartCommand(connectionName,query, cmd);
      if (rdbCheckError(errTxt,cmd)){fwInstallation_throw("DB ERROR" +errTxt+" "+query);return -1;};

      rdbBindParams(cmd, record);
      if (rdbCheckError(errTxt,cmd)){fwInstallation_throw("DB Error: "+errTxt + +query);return -1;};

      rdbExecuteCommand(cmd);
 
      if (rdbCheckError(errTxt,cmd)){fwInstallation_throw("DB ERROR" +errTxt+" "+query);return -1;};

      rc=rdbGetData(cmd, data);
      if (rdbCheckError(errTxt,cmd)){fwInstallation_throw("DB ERROR" +errTxt+" "+query);return -1;};
    
      rc = rdbFinishCommand(cmd);
      // note that we do not put the second parameter here!
      if (rdbCheckError(errTxt)){fwInstallation_throw("DB Error: "+ errTxt + " " + query);return -1;};
  
    }
  }
  return rc;
}


int fwSysOverviewLongTermReport_openRdbConnection(string database, 
                                                   string username, 
                                                   string password, 
                                                   string owner, 
                                                   string driver = "QOCI8")
{
  dbConnection dbCon;
  string errTxt;
  
  string connectionString = "driver="+driver+";database="+database+";uid="+username+";enc_pwd=" + password;

  int rc=rdbGetConnection(connectionName, dbCon);
  rdbCheckError(errTxt,dbCon);
  
  if(rc != 0) 
  {
    DebugN("Opening connection.");
    rc = rdbOpenConnection(connectionString, dbCon, connectionName);
    if(rdbCheckError(errTxt,dbCon))
    {
      DebugN("err: " + errTxt);
    }  
  }

  return rc;
}

int fwSysOverviewLongTermReport_disconnect()
{
 int rc = rdbCloseConnection(connectionName);
 DebugN("Closing connection. Result: " + rc);
}

string _fwSysOverviewLongTermReport_calculateScaling(dyn_dyn_mixed data, int numberOfPlots = 1)
{
  string scalingStrData;
  string scalingStrAxis;
  string scalingStr;
  float minVal=100, maxVal=0;
  for (int i=1; i<= dynlen(data) ; i++)
  {
    float currentVal = data[i][2];
    if (currentVal > maxVal)
      maxVal = currentVal;
    
    if (currentVal < minVal)
      minVal = currentVal;
  
  }
 
  if (minVal == maxVal)
  {
    if (minVal > 1)
      minVal -= 1;
    else minVal = 0;
    maxVal +=1;
  }
  if (minVal != 100 || maxVal != 0)
  {
    // get the first "round" number before min and the first "round" number after max
    int minY = (minVal/10) * 10;
    int maxY = (maxVal/10) * 10 + 1;
    //it should repeat for each of the data series
    for(int i=1;i<=numberOfPlots; i++)
      scalingStrData += "0,100," + (string) minY + "," + (string) maxY + ",";
    if (strlen(scalingStrData) > 0)
      scalingStrData = substr(scalingStrData,0,strlen(scalingStrData)-1);
    float yStep = ((maxY - minY)*1.)/10;
    scalingStrAxis = "1," + (string) minY + "," + (string) maxY + "," + (string) yStep;
  }
  
  if (scalingStrData != "" && scalingStrAxis != "")
    scalingStr = "&amp;chds=" + scalingStrData + "&amp;chxr=" + scalingStrAxis;
  return scalingStr;
}


dyn_string _fwSysOverviewLongTermReport_createChartUrl(dyn_string dpes, dyn_dyn_mixed data, time endDate, int numberOfDays, string chartCaption, string units, bool plotOnTheSameChart = true, string legend = "")
{
  dyn_string colors = makeDynString("0A00F0", "FFC832", "64C864", "FF64B4", "00C8FF", "009696", "FF000A", "8282FF");
  string colorsStr = (string) colors;
  strreplace(colorsStr, " | ", ",");
  dyn_string labels = _fwSysOverviewLongTermReport_getLabels(endDate, numberOfDays);
  string labelsStr;
  fwGeneral_dynStringToString(labels, labelsStr, "|"); 
  dyn_string chartUrls;
  int plotsPerChart = _fwSysOverviewLongTermReport_getPlotsPerChart();
  if (plotOnTheSameChart)
  {
    string chartDataStr;
    string chartLegend;
    _fwSysOverviewLongTermReport_formatChartDataString(endDate, numberOfDays, data, chartDataStr, chartLegend);
    //if we haven't passed other legend, we should use the fmcNodes
    if(legend != "")
      chartLegend = legend;
      
    string scalingStr = _fwSysOverviewLongTermReport_calculateScaling(data, dynlen(dpes));  
    string chartUrl = "https://chart.googleapis.com/chart?"+
                      "cht=lxy&amp;"+//chart type
                      "chs=350x250&amp;"+//chart size
                      "chco="+ colorsStr + "&amp;"//color
                      "chxt=x,y&amp;"+//axis
                      "chd=t:" + chartDataStr + "&amp;" +
                      "chdl="+chartLegend + "&amp;chdlp=t&amp;chtt=" + chartCaption  + scalingStr;
  
    chartUrl += "&amp;chxl=0:|" + labelsStr ;
    //add the units
    if(units!="")
      chartUrl += "&amp;chxs=1N**" + units;
    strreplace(chartUrl, " ", "");
    dynAppend(chartUrls, chartUrl);
  }
  else
  {
     dyn_dyn_mixed portionedData = _fwSysOverviewLongTermReport_portionData(data, plotsPerChart);
     for (int i=1; i<=dynlen(portionedData); i++)
     {
       string chartDataStr;
       string chartLegend;
       _fwSysOverviewLongTermReport_formatChartDataString(endDate, numberOfDays, portionedData[i], chartDataStr, chartLegend);
       string scalingStr = _fwSysOverviewLongTermReport_calculateScaling(portionedData[i], plotsPerChart);
       string currentChartUrl = "https://chart.googleapis.com/chart?"+
                      "cht=lxy&amp;"+//chart type
                      "chs=350x250&amp;"+//chart size
                      "chco="+ colorsStr + "&amp;"//color
                      "chxt=x,y&amp;"+//axis
                      "chd=t:" + chartDataStr + "&amp;" +
                      "chdl="+chartLegend + "&amp;chdlp=t&amp;chtt=" + chartCaption + scalingStr;
  
       currentChartUrl += "&amp;chxl=0:|" + labelsStr ;
       //add the units
       currentChartUrl += "&amp;chxs=1N**%";
       strreplace(currentChartUrl, " ", "");
       dynAppend(chartUrls, currentChartUrl);
       
    }
     
    
  }
  
 
  return chartUrls;
}
dyn_dyn_mixed _fwSysOverviewLongTermReport_portionData(dyn_dyn_mixed originalData, int portionSize)
{
  dyn_dyn_mixed portionedData;
  int portionedDataIndex = 0;
  string previousDp;
  int portionCurrentSize;
  bool firstAdding = false;
  for (int i=1; i<=dynlen(originalData); i++)
  {
    if (previousDp == originalData[i][3] || portionCurrentSize < portionSize)
    {
      //just att it to the last portion
      dyn_dyn_mixed currentContent;
      if (portionedDataIndex > 0)
      {
        currentContent = portionedData[portionedDataIndex];
        currentContent[dynlen(currentContent) + 1] = originalData[i];
        portionedData[portionedDataIndex] = currentContent;
      }
      else
      {
        portionedDataIndex = 1;
        dyn_dyn_mixed tmp;
        tmp[1] = originalData[i];
        portionedData[portionedDataIndex] = tmp;
      }
      
     
      if (previousDp != originalData[i][3])
         portionCurrentSize++; 
    }
    else //start new portion
    {
      portionedDataIndex++;
      dyn_dyn_mixed tmp;
      tmp[1] = originalData[i];
      portionedData[portionedDataIndex] = tmp;
      portionCurrentSize = 1;
        
    }
    previousDp = originalData[i][3];
  
  }
  return portionedData;
}

dyn_string fwSysOverviewLongTermReports_createChart(dyn_string dps, time endDate, int days, string chartTitle, string units="", string legend = "")
{
  dyn_string chartUrls ;
  dyn_dyn_mixed data;
  int rc = fwSysOverviewLongTermReport_getAverageDataOverTime(endDate, days, dps, data);
  
  if (rc==0)
  { 
    _fwSysOverviewLongTermReport_prepareDataMultipleDp(endDate, days, dps, data, false);
    chartUrls = _fwSysOverviewLongTermReport_createChartUrl(dps, data, endDate, days, chartTitle, units, true, legend);
  }
  
  return  chartUrls ;
}

dyn_string  fwSysOverviewLongTermReport_createApplicationMonitoredProcessesCharts(string application, time endDate, int reportPeriod)
{
  dyn_string chartUrls;
  dyn_string nodes,ex;
  dyn_dyn_string dps = fwSysOverviewFsm_getChildrenOfTypeWithDomain(application, "FwFMCNode", application);   
  for(int i = 1; i <= dynlen(dps); i++)
  {
    dynAppend(nodes, fwFMC_getNodeName(dps[i][1]) );
  }
  for(int i=1; i<=dynlen(nodes); i++)
  {
    dyn_string processes = fwFMCProcess_getMonitoredProcesses(nodes[i], ex);
    dyn_string optionsDpes, nameDpes;
    dyn_string cpuDps, memoryDps;
    
    for(int j=1; j<=dynlen(processes); j++)
    {
      dynAppend(optionsDpes, processes[j] + ".config.cmd");
      dynAppend(nameDpes, processes[j] + ".config.name");                
      dynAppend(cpuDps, processes[j] + ".readings.cpu");
      dynAppend(memoryDps, processes[j] + ".readings.memory");

    }
   
    if(dynlen(processes) > 0)
    {
      dyn_string options, names;
      dpGet(optionsDpes, options, nameDpes, names);
      dyn_string legend;
      //create the legend
      for(int j=1; j<=dynlen(processes); j++)
      {
       dynAppend(legend, names[j]);  
      }
      
      string legendStr = legend;
      strreplace(legendStr, " | ", "|");
      dyn_string cpuChartUrls = fwSysOverviewLongTermReports_createChart(cpuDps, endDate, reportPeriod, "Monitored Processes CPU" ,"%", legendStr);
      dynAppend(chartUrls,cpuChartUrls);                
      dyn_string memoryChartUrls = fwSysOverviewLongTermReports_createChart(memoryDps, endDate, reportPeriod, "Monitored Processes Memory" ,"KB", legendStr);
      dynAppend(chartUrls,memoryChartUrls);        
    }
  }  
  return chartUrls   ;
}    
