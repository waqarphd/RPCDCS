#uses "email.ctl"
#uses "fwFMC/fwFMC.ctl"
#uses "fwSystemOverview/fwSystemOverviewFsm.ctl"
#uses "fwSystemOverview/fwSystemOverviewNotifications.ctl"

const string ENICE_MONITORING_REPORTS = "ice.monitoring.reports@cern.ch";
const string  fwSysOverview_REPORTS_NOTIFICATIONTEMPLATE = "The daily report for %applicationLabel has been generated and can be consulted here: https://cern.ch/moon .<br><br>Cheers,<br>The MOON team.";

string fwSysOverviewReport_getApplicationEmailDp(string application)
{
  return "fwSystemOverviewEmail_" + application;  
}

string fwSysOverviewReport_getApplicationEmailRecipients(string application)
{
  string recipients = "";
  string dp = fwSysOverviewReport_getApplicationEmailDp(application);
  if (dpExists(dp))
     dpGet(dp + ".recipients", recipients);
  
  return recipients;  
}

dyn_dyn_anytype fwSysOverviewReport_queryApplicationActiveAlarms(string application = "", bool getAllSystemIntegrity = true)
{
  dyn_dyn_anytype records, recordsLocal, recordsRemote;  
  //First, all alarms in the local system
  dyn_string dps;
  dyn_string dpePatterns;
  string query = "";

  dynClear(records);
  dynClear(recordsLocal);
  dynClear(recordsRemote);
  dynClear(dpePatterns);  
  dynClear(dps);
  if(application == "")
  {
    query = "SELECT ALERT '_alert_hdl.._text', '_alert_hdl.._abbr', '_alert_hdl.._value', '_alert_hdl.._sum' FROM '*.**'";
  }
  else
  {
//    dps = fwFsm_getDomainDevices(application);  
    dps = fwSysOverviewFsm_getTreeDevices(application, true);
    for(int i = 1; i <= dynlen(dps); i++)
    {
      string dp = "";
      if(!dpExists(dps[i]))
      {
        dp = dpAliasToName(dps[i]);      
        dp = dpSubStr(dp, DPSUB_DP);
      }
      else
        dp = dps[i];
      
      dynAppend(dpePatterns, dp + "*.**");
    }  
    query = "SELECT ALERT '_alert_hdl.._text', '_alert_hdl.._abbr', '_alert_hdl.._value', '_alert_hdl.._sum' FROM '" + fwSysOverviewReport_prepareQueryPattern(dpePatterns) + "'";
  }
  
  dpQuery(query, recordsLocal);
  int n = 1;
  for(int i =2; i <= dynlen(recordsLocal); i++)
  {
    bool isSummary = (bool)recordsLocal[i][6];
    if(isSummary)
      continue;

    records[n] = recordsLocal[i];
    ++n;
  }
  
  //Now the System Integrity Alarms in the remote systems
  int count = dynlen(records) + 1;
  dyn_string systems;
  dyn_uint ids;
  
  if(application == "")
    getSystemNames(systems, ids);    
  else
    fwSysOverview_getApplicationSystems(application, systems, ids);
  
  dyn_string connectedSystems, missingSystems, systemsWithAlarms;
  fwSysOverviewReport_getApplicationSystemIntegritySummary(application, connectedSystems, missingSystems, systemsWithAlarms);
  
  for(int i = 1; i <= dynlen(systems);i++)  
  {
//    dyn_int connectedSystemsIds;
//    dpGet("_DistManager.State.SystemNums", connectedSystemsIds);
//    if(dynContains(connectedSystemsIds, ids[i])<=0) //System not connected. Skip!
    if(dynContains(connectedSystems, systems[i])<=0) //System not connected. Skip!
      continue;
    if(!getAllSystemIntegrity && !dynContains(systemsWithAlarms, systems[i])) //System doesn't have alarm. Skip!
      continue;
    
    dpePatterns = makeDynString("_unSystemAlarm_*.alarm", "_ArchivDisk.FreeKB", "_MemoryCheck.FreeKB");
    //string systemsPattern = fwSysOverviewReport_getRemoteSystemsPattern();

    query = "SELECT ALERT '_alert_hdl.._text', '_alert_hdl.._abbr', '_alert_hdl.._value', '_alert_hdl.._sum' FROM '" + fwSysOverviewReport_prepareQueryPattern(dpePatterns) + "' REMOTE '"+ systems[i] + "'";
    dpQuery(query, recordsRemote);

    for(int j = 2; j <= dynlen(recordsRemote); j++)
    {
      records[count] = recordsRemote[j];
      ++count;
    }
  }  
  
  return records;
} 

void fwSysOverviewReport_getDefaultEmailConfig(string& sender, string& smtpServer, string& name)
{
  fwSysOverviewReport_getEmailConfig("fwSystemOverviewEmailConfig", sender,smtpServer,name);
}   

void fwSysOverviewReport_getEmailConfig(string dp, string& sender, string& smtpServer, string& name)
{
  dpGet(dp + ".sender", sender,
        dp + ".smtpServer", smtpServer,
        dp + ".name", name);
}   


int fwSysOverviewReport_email(string application, string body, string recipients = "")
{
  int err = 0;
  dyn_string email;
//  string receiver = "fernando.varela.rodriguez@cern.ch;petrova.lyuba@cern.ch";
  if (recipients == "")
    recipients = fwSysOverviewReport_getApplicationEmailRecipients(application);
 
  string sender;
//  string sender = "ice.monitoring.reports@cern.ch";
  string str = getCurrentTime();
  string subject = "MOON report  for " +application;
  string smtpServer;
  string name;                    
  fwSysOverviewReport_getDefaultEmailConfig(sender, smtpServer, name);
  if(recipients == ""){DebugN("Could not send email for application: " + application + ". Empty recipient list."); return -1;}  

  dynClear(email);
  email[1] = recipients;  
  email[2] = sender;  
  email[3] = subject;
  email[4] = body;

  // send plain text email to Confluence
  if (strpos(recipients, ENICE_MONITORING_REPORTS) >= 0)
  {
    email[1] = ENICE_MONITORING_REPORTS+";petrova.lyuba@cern.ch";
    emSendMail(smtpServer, name, email, err);
    
    email[1] = recipients; 
    strreplace(email[1], ENICE_MONITORING_REPORTS, "");
    strreplace(email[1], ";;", ";");//in case the confluence mail was in the middle of the recepients    
  }  

  if (email[1] != "") 
    fwSysOverviewReport_sendHtmlMail(smtpServer, name, email, err);
  return err;  
}

int fwSysOverviewReport_emailApplicationReport(string application, string recipients = "")
{
  string report = fwSysOverviewReport_generateApplication(application);
  return fwSysOverviewReport_email(application, report, recipients);
}
int fwSysOverviewReport_createApplicationReport(string application, bool createHtmlFile, bool sendEmail, bool sendGenerationNotification = false, string filePath = "")
{
  int err = 0;
  string report = fwSysOverviewReport_generateApplication(application);
  if (createHtmlFile)
  {
    string folder = filePath==""?MOON_REPORTS_PATH:filePath;
    string path;
    int type;
    string parent =  fwCU_getParent(type, application);
    if (parent != "")
    {
      string label;
      fwUi_getLabel(parent, parent, label);
      if (!isdir(folder + strtolower(label) + "/"))
        mkdir(folder + strtolower(label) + "/", "755");
      path =  folder + strtolower(label) + "/" + MOON_DAILY_REPORTS_FOLDER +"/";    
    } 
    else    
      path =  folder + "/" + MOON_DAILY_REPORTS_FOLDER +"/";
    if(!isdir(path))    
       mkdir(path, "755");
    //save the html to file
    file f = fopen(path + application + ".html", "w");
    int err = ferror(f);
    if (!err)
    {
      fputs(report, f);
      fclose(f);
      if (sendGenerationNotification)
      {
        string emailText = fwSysOverview_REPORTS_NOTIFICATIONTEMPLATE;
        strreplace(emailText, "%applicationLabel", applicationLabel!=""?applicationLabel:application);
        strreplace(emailText, "%application", application);
        strreplace(emailText, "%tree", strtolower(label));
        err = fwSysOverviewReport_email(application, emailText);
      }
    }
  }
  if (sendEmail && dpExists(fwSysOverviewReport_getApplicationEmailDp(application))) 
  { 
    err = fwSysOverviewReport_email(application, report);
    if (!err)
    {
       string dp = fwSysOverviewReport_getApplicationEmailDp(application);
       dpSet(dp + ".lastSentDate", getCurrentTime());
    }
  }
  return err;
}

void fwSysOverviewReport_createDailyReportsHtml(string tree)
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
           "<body onload=\"loadDaily('" + applications[1] + "')\">"+
           "<table style=\"height:95%\">"+
  	       "<tr style=\"align: right; valign: bottom\">"+
    		   "<td colspan=\"2\">"+
  		     "<ul id=\"nav\">"+
  			   "<li id=\"nav-1\"><a href=\"../../tree/" + tree + ".xml\">Overview</a></li>"+
  			   "<li id=\"nav-2\"><a href=\"../moonAlarms.html\">Alarms</a></li>"+
  			   "<li id=\"nav-3\" class=\"current\"><a href=\"#\">Daily reports</a></li>"+
  			   "<li id=\"nav-3\"><a href=\"../reportsLong/longTermReports.html\">Long-term reports</a></li>"+
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
    
      html += "<li id=\"" + applications[i] + "\" onclick=\"changeSelectionDaily('" +  applications[i]  + "')\"><a href=\"" +  applications[i]  + ".html\" target=\"reportsFrame\">" + label + "</a></li>";
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
  string filePath =  MOON_REPORTS_PATH + strtolower(label) + "/" + MOON_DAILY_REPORTS_FOLDER + "/dailyReports.html";
  file f = fopen(filePath, "w+");
  int err = ferror(f);
  if (!err)
  {
    fputs(html, f);
    fclose(f);
  }
}

string fwSysOverviewReport_getHtmlColor(string abbr)
{
  string color = "green";
  string abbr2 = strtoupper(abbr);
  if(abbr2 == "SI1" || abbr2  == "W")
    color = "orange";
  else if(abbr2 == "E" || abbr2 == "F")
    color = "red";  
  
  return color;  
}

string fwSysOverviewReport_getPieChart(string title, dyn_float values, dyn_string legends, dyn_string colors, int x = 250, int y = 100)
{
  string valuesStr;//comma separated
  string colorsStr;
  string legendsStr;//pipe separated
  
  if(dynlen(values) <= 0)
    return "";
  
  
  valuesStr = values[1];
  colorsStr = colors[1];
  legendsStr = legends[1];
  
  for(int i = 2; i <= dynlen(values); i++)
  {
    valuesStr += ","+values[i];
    if(dynlen(colors)>=i)
      colorsStr += "|"+colors[i];
    legendsStr += "|" + legends[i];
  }
  strreplace(valuesStr, " ","");
  strreplace(colorsStr, " ","");
  strreplace(legendsStr, " ","");

  return "<img src =\"https://chart.googleapis.com/chart?cht=p3&amp;chs="+x+"x"+y+"&amp;chd=t:"+valuesStr
      +"&amp;chco=" + colorsStr
      +"&amp;chtt=" + title 
      + "&amp;chl=" + legendsStr + "\" alt=\"pie\" />";
 
}

dyn_string fwSysOverview_getDevicesInAlarm(string type, string domain, string device)
{
  dyn_string devices;
  dyn_dyn_string dps = fwSysOverviewFsm_getChildrenOfTypeWithDomain(device, type, domain);     
  dynClear(devices);
  
  for(int i =1; i <= dynlen(dps); i++)
  {
    int state = 0;
    string dp = "";
    if(type == "IcemonPlc")
    {
      dp = dpAliasToName(dps[i][1]);
      dpGet(dp +":_alert_hdl.._act_state", state);
    }
    else      
    {
      dp = dps[i][1];
      dpGet(dp + ".:_alert_hdl.._act_state", state);
    }
    
    if(state)
    {
      dyn_string ex;
      string name = "";
      fwDevice_getName(dp, name, ex);
      dynAppend(devices, name);
    }
  }

  return devices;  
}

string fwSysOverviewReport_getDevicePieChart(string type, string domain = "", string device = "")
{
  dyn_dyn_string dps = fwSysOverviewFsm_getChildrenOfTypeWithDomain(device, type, domain);   
  int total = dynlen(dps);
  dyn_string alarmDevices = fwSysOverview_getDevicesInAlarm(type, domain, device);
  int n = dynlen(alarmDevices);

  dynClear(alarmDevices);  
  
  string body;
  string title = "";
  if(strtoupper(type) == "FWFMCNODE")
  {
    title = "Hosts";
  }
  else if(strtoupper(type) == "FWSYSTEMOVERVIEWPROJECT")
  {
    title = "Projects";
  }
  else if(strtoupper(type) == "ICEMONPLC")
  {
    title = "PLCs";
  }
  else if(strtoupper(type) == "ICEMONSYSTEMINTEGRITY")
  {
    title = "System_Integrity";
  }
  
  body += fwSysOverviewReport_getPieChart(title, makeDynFloat(total-n, n), makeDynString("OK:"+(total-n), "NOT_OK:"+n), makeDynString("00FF00","FF0000"));
 

  return body;
  
}  


string fwSysOverview_getDpeIdentifier(string dpe)
{
  //string sys = dpSubStr(dpe, DPSUB_SYS);
  string description = dpGetDescription(dpe);
  string comment = dpGetComment(dpe);
  string alias = dpGetAlias(dpe);
  
  if(description != "" && description != dpe)
    return description;
  else if(comment != "" && comment != dpe)
    return comment;
  else if (alias != "" && alias != dpe)
    return alias;
  
  //if the dpe does not contain alias, description nor comment, try with the parent dp:
  string dp = dpSubStr(dpe, DPSUB_SYS_DP);
  description = dpGetDescription(dp + ".");
  comment = dpGetComment(dp + ".");
  alias = dpGetAlias(dp + ".");
  
  if(description != "" && description != dp)
    return description;
  else if(comment != "" && comment != dp)
    return comment;
  else if (alias != "" && alias != dp)
    return alias;
  
  //if nothing has worked, return the original dpe  
  return dpe;  
}


string fwSysOverviewReport_getBarTrend(string title, 
                                       dyn_dyn_float values, 
                                       dyn_string xAxisValues, 
                                       dyn_float yAxisValues, 
                                       dyn_string legends,
                                       dyn_string colors, 
                                       int x = 300, 
                                       int y = 200)
{
  string valuesStr;//comma separated
  string colorsStr;
  string xAxisStr;//pipe separated
  string yAxisStr;//pipe separated
  string legendsStr;//pipe separated
  
  if(dynlen(values) <= 0)
    return "";
  
  string valuesStr = values[1];
  strreplace(valuesStr, "|", ",");
  strreplace(valuesStr, " ", "");
  
  colorsStr = colors;
  strreplace(colorsStr, "|", ",");
  strreplace(colorsStr, " ", "");
  
  xAxisStr = xAxisValues;
  strreplace(xAxisStr, " ", "");
  
  yAxisStr = yAxisValues;
  strreplace(yAxisStr, " ", "");
  
  legendsStr = legends;
  strreplace(legendsStr, " ", "");
  
  for(int i = 2; i <= dynlen(values); i++)
  {
    string temp = values[i];
    strreplace(temp, "|", ",");
    strreplace(temp, " ", "");
    valuesStr += "|" + temp;
  }  
  strreplace(title, " ", "%20");
  return "<img src =\"http://chart.apis.google.com/chart?"+
      +"&amp;cht=bvg" //char type
      +"&amp;chd=t:"+ valuesStr //is for specifying data
      +"&amp;chco=" + colorsStr //is for specifying chart colour
      +"&amp;chtt="+title //is for specifying chart title
      +"&amp;chts=153E7E,10" //is for specifying chart title's colour and font size
      +"&amp;chs="+x+"x"+y //is for specifying chart size in pixels
      +"&amp;chdl=" + legendsStr //is for specifying legend
      +"&amp;chxt=x,y" //is for specifying chart axis
      +"&amp;chxl=0:|"+xAxisStr +"|1:|" + yAxisStr //is for specifying label of x axis
      + "\" alt=\"chart\"/>";
 
}


string fwSysOverviewReport_getApplicationStatistics(string application)
{
  string report = "<table border=\"1\">";
  report +="<tr>";
  string summary = fwSysOverviewReport_getApplicationHostsSummary(application);
  report = report +"<td>"+ fwSysOverviewReport_getDevicePieChart("FwFMCNode", application, application) + "</td>"+ "<td>"+ summary+ "</td>";
  report +="</tr><tr>";
  int totalProjects, totalManagers, crashed, stucked;
  fwSysOverviewReport_getApplicationManagersStatistics(application, totalProjects, totalManagers, crashed, stucked);
  report = report + "<td>"+fwSysOverviewReport_getPieChart("PVSS%20Managers:%20" + totalManagers, 
                                            makeDynFloat(totalManagers, crashed, stucked), 
                                            makeDynString("OK:"+(totalManagers-crashed-stucked), "Crashed:"+crashed, "Stucked:"+stucked), 
                                            makeDynString("00FF00","FF0000","FFFF00"))+"</td>"+ "<td><ul><li>PVSS Projects: " + totalProjects+"</li></ul></td>";   
  report +="</tr><tr>";
  dyn_string connectedSystems, missingSystems, systemsWithAlarms;
  dynClear(connectedSystems);
  dynClear(missingSystems);
  dynClear(systemsWithAlarms);
  
  summary = fwSysOverviewReport_getApplicationSystemIntegritySummary(application, connectedSystems, missingSystems, systemsWithAlarms);
  string missing = "<ol>";
  for(int i = 1; i <= dynlen(missingSystems); i++)
  {
    missing = missing + "<li>" + missingSystems[i] + "</li>";    
  }
  missing += "</ol>";

  string color = "black";
  if(dynlen(missingSystems))
    color = "red";
  
  report = report + "<td>" + fwSysOverviewReport_getDevicePieChart("IcemonSystemIntegrity", application, application) + "</td>"+"<td><ul><li>System Integrity enabled in "+ summary + " projects</li>"+
           "<li>Nb. of Systems connected to MOON: "+dynlen(connectedSystems) + "</li>"+
           "<li style=\"color:"+color+"\">Nb. of Systems NOT connected to MOON: "+dynlen(missingSystems) + " "+(dynlen(missingSystems)==0?"":missing) + "</li>"+
           "</ul></td>";
  
  //If there are PLCs, add report for them...
  int siemens, schneider;
  int totalPlcs = fwSysOverviewReport_getApplicationPlcsSummary(application, siemens, schneider);

  if(siemens != 0 || schneider != 0)
  {
    report +="</tr><tr>";
    report = report + "<td>" + fwSysOverviewReport_getDevicePieChart("IcemonPlc", application, application) + "</td>" + "<td><ul><li>PLCs: "+ totalPlcs + "<ul><li>Siemens: " + siemens + "</li><li>Schneider: "+schneider+"</li></ul></li></ul></td>";
    report+="</tr>";
  }
  
  report += "</table>";
  return report;
}

string fwSysOverviewReport_getApplicationHostsSummary(string application)
{
  dyn_dyn_string dps = fwSysOverviewFsm_getChildrenOfTypeWithDomain(application, "FwFMCNode", application);   
  int n = dynlen(dps);
  dyn_string fsDps;
  string memoryDp;
  int memErr;
  int fsErr;
  int processes;
  
  dynClear(fsDps);
  
  for(int i = 1; i <= n; i++)
  {
    //Memory
     float userMemory;
     int total;
     string dp = dps[i][1];
     dpGet(dp + "/Monitoring/Memory.readings.userMemory", userMemory,
           dp + "/Monitoring/Memory.readings.total", total);
     if(total!=0 && userMemory  > 80)
       ++memErr;
     
     //Fss
     fsDps = dpNames(dp + "/Monitoring/FS/fs_*.readings.user", "FwFMCFs");
     dyn_float fss;     
     dpGet(fsDps, fss);
     for(int j = 1; j <= dynlen(fss); j++)
     {
       if(fss[j] > 70.)
         ++fsErr;
     }

     //Processes:    
     dyn_int pids; 
     dpGet(dp + "/Process.processes.pid", pids);
     processes += dynlen(pids);
  } 
  string summary = "<ul>";
  summary = summary + "<li>Hosts: " + n + "</li>";
  summary = summary + "<li>Processes: " + processes + "</li>";
  summary = summary + "<li>Filesystems above 70% usage: " + fsErr + " </li>";
  summary = summary + "<li>Hosts with memory usage above 80%: " + memErr + " </li>";
  summary += "</ul>";
  return summary;
}

int fwSysOverviewReport_getApplicationSystemIntegritySummary(string application, dyn_string &connectedSystems, dyn_string &missingSystems, dyn_string &systemsWithAlarms)
{
  dyn_dyn_string dps = fwSysOverviewFsm_getChildrenOfTypeWithDomain(application, "IcemonSystemIntegrity", application);   
  dynClear(connectedSystems);
  dynClear(missingSystems);
  dynClear(systemsWithAlarms);
  
  for(int i = 1; i <= dynlen(dps); i++)
  {
    bool connected = false;
    string sys;
    int alarm; 
    dpGet(dps[i][1] + ".connected", connected,
          dps[i][1] + ".systemName", sys,
          dps[i][1] + ".alarm", alarm);
    if(connected)
      dynAppend(connectedSystems, sys);
    else    
      dynAppend(missingSystems, sys);
    if(alarm)
      dynAppend(systemsWithAlarms, sys);
  }
  return dynlen(dps);
}

int fwSysOverviewReport_getApplicationPlcsSummary(string application, int &siemens, int &schneider)
{
  siemens = 0;
  schneider = 0;
  dyn_dyn_string dps = fwSysOverviewFsm_getChildrenOfTypeWithDomain(application, "IcemonPlc", application);
  for(int i = 1; i <= dynlen(dps); i++)
  {
    string maker;
    dpGet(dpAliasToName(dps[i][1]) + "Configuration.application", maker);
    if(strtoupper(maker) == "SIEMENS")
      ++siemens;
    else
      ++schneider;
  }  
  
  return dynlen(dps);
}

void fwSysOverviewReport_getApplicationManagersStatistics(string application, int &totalProjects, int &total, int &totalCrashed, int &totalStucked)
{
  totalProjects = 0;
  totalCrashed = 0;
  totalStucked = 0;
  
  int n, crashed, stucked;
  dyn_dyn_string dps = fwSysOverviewFsm_getChildrenOfTypeWithDomain(application, "FwSystemOverviewProject", application);   
  for(int i = 1; i <= dynlen(dps); i++)
  {
   
     string dp = dps[i][1];
     dpGet(dp + ".statistics.totalManagers", n,
           dp + ".statistics.blockedManagers", stucked,
           dp + ".statistics.errManagers", crashed);
     
     total += n;
     totalCrashed += crashed;
     totalStucked += stucked;
  } 
  totalProjects = dynlen(dps);
}


dyn_dyn_mixed fwSysOverviewReport_queryApplicationAlarmHistory(string application, int timeInterval = 86400, bool onlyCame = true)
{
  dyn_string dpePatterns;
//  dyn_dyn_string dps = fwFsm_getDomainDevices(application);  
  dyn_string dps = fwSysOverviewFsm_getTreeDevices(application, true);
  dynClear(dpePatterns);
  for(int i = 1; i <= dynlen(dps); i++)
  {
    string dp = "";
    if(!dpExists(dps[i]))
    {
      dp = dpAliasToName(dps[i]);
      dp = dpSubStr(dp, DPSUB_DP);
      dynAppend(dpePatterns, dp + "**");    
    }
    else
    {
      dp = dps[i];
      dynAppend(dpePatterns, dp + ".**");    
    }
  }

  dyn_dyn_mixed record; 
  if(dynlen(dpePatterns) > 0)
   record = fwSysOverviewReport_get(dpePatterns, timeInterval);

  dyn_dyn_mixed finalRecords;  
  dynClear(finalRecords);
  
  if(onlyCame)
  {
    for(int i =1; i <= dynlen(record); i++)
    {
      if(record[i][5] == "CAME")
      {
        dynAppend(finalRecords, record[i]);
      }
    }
  }
  else
  {
    finalRecords = record;
  }

  return finalRecords;
}

dyn_dyn_mixed fwSysOverviewReport_get(dyn_string dpePatterns, int timeIntervalFromNow = 86400)
{
  dyn_dyn_mixed report;
  dynClear(report);
  time start = getCurrentTime();
  time end = getCurrentTime();
  
  start -= timeIntervalFromNow;
  
  string startStr = start;
  string endStr = end;
  dyn_dyn_anytype records;
  
  string query = "SELECT ALERT '_alert_hdl.._text', '_alert_hdl.._value', '_alert_hdl.._direction', '_alert_hdl.._alert_color', '_alert_hdl.._abbr' FROM '" + fwSysOverviewReport_prepareQueryPattern(dpePatterns) + "' TIMERANGE(\""+startStr+"\",\"" + endStr + "\",1,0)";
  
  dpQuery(query, records);
  for(int i = 2; i <= dynlen(records); i++)
  {
    string row1 = records[i][1];
    dyn_string ds = strsplit(row1, " ");
    report[i-1][1] = ds[1];
      
    string row2 = records[i][2];
    report[i-1][2]= substr(row2, 0, 30);
      
    report[i-1][3] = (string) records[i][3];
    report[i-1][4] = records[i][4];
    report[i-1][5] = records[i][5]?"CAME":"WENT";
    report[i-1][6] = records[i][6];
    report[i-1][7] = records[i][7];
  }
  return report;
}


string fwSysOverviewReport_prepareQueryPattern(dyn_string dpePatterns)
{
  if(dynlen(dpePatterns) <= 0)
    return "";
  
  string pattern = "{" + dpePatterns[1];
  for(int i = 2; i <= dynlen(dpePatterns); i++)
  {
    pattern = pattern + "," + dpePatterns[i];
  }
  pattern += "}";
  return pattern; 
}

dyn_dyn_mixed fwSysOverviewReport_getApplicationDeviceTypeAlarmHistory(string application, string type, int timeInterval = 86400, bool onlyCame = true)
{
  dyn_string dpePatterns;
  dyn_dyn_string dps = fwSysOverviewFsm_getChildrenOfTypeWithDomain(application, type, application); 
  dynClear(dpePatterns);
  for(int i = 1; i <= dynlen(dps); i++)
  {
    string dp = "";
    if(!dpExists(dps[i][1]))
    {
      dp = dpAliasToName(dps[i][1]);
      dp = dpSubStr(dp, DPSUB_DP);
    }
    else
      dp = dps[i][1];
     
    dynAppend(dpePatterns, dp + ".**");    
    dynAppend(dpePatterns, dp + "/*.**");    
  }

  dyn_dyn_mixed allRecords; 
  dyn_dyn_mixed records;
  
  if(dynlen(dpePatterns) > 0)
   allRecords = fwSysOverviewReport_get(dpePatterns, timeInterval);

  dynClear(records);
  if(onlyCame)  
  {
    for(int i = 1; i <= dynlen(allRecords); i++)  
    {
      if(allRecords[i][5] == "CAME")
      {
        dynAppend(records, allRecords[i]);
      }
    }
  }
  else
  {
    records = allRecords;
  }
  
  return records;
}

string fwSysOverviewReport_castToHtmlTable(dyn_dyn_mixed report)
{
  int total = dynlen(report);
  dyn_string dpes;
  int came = 0, went = 0;
  dyn_dyn_mixed alarmBuffer;
  
  dynClear(dpes);
  for(int i = 1; i <= total; i++)
  {
    string dpe = report[i][1];    
    dynAppend(dpes, dpe);
    string dpIdentifier = fwSysOverview_getDpeIdentifier(dpe);
    if(report[i][5] == "CAME")
    {
      ++came;
      //see how many times this alarm has happened
      bool found = false;
      for(int j = 1; j <= dynlen(alarmBuffer); j++)//iterate over the current contents of the alarm buffer
      {
        if(alarmBuffer[j][1] == (dpIdentifier + "|" + report[i][3] + "|" + report[i][7]))
        {
          found = true;
          ++alarmBuffer[j][2];
        }
      }
      if(!found)
      {
        int n = dynlen(alarmBuffer);
        alarmBuffer[++n][1] = dpIdentifier + "|" + report[i][3] + "|" + report[i][7];
        ++alarmBuffer[n][2];
      }
    }
    else
      ++went;
    
  }
  
  string body = "<ul>";
  body += "<li>Total Number of Alarms:"+ total + " (CAME Alarms: "+ came + " - " + "WENT Alarms: "+ went + ")</li>";
  body += "<li>Number of DPEs with alarms: "+ dynlen(alarmBuffer) + "</li>";
  body += "</ul>";
  
  //process the statistics here:  
  string statistics = "<table border=\"1\">";
  statistics += "<tr><th>No.</th><th>Category</th><th>Dp Identifier</th><th>Alarm text</th><th>Ocurrences</th></tr>";
  
  for(int i = 1; i <= dynlen(alarmBuffer); i++)
  {
    dyn_string ds = strsplit(alarmBuffer[i][1], "|");
    if(dynlen(ds)<3) //it is a summary alarm => skip
      continue;

    string color = fwSysOverviewReport_getHtmlColor(strtoupper(ds[3]));
    
    statistics+="<tr>";
    statistics = statistics + "<td>" + i + "</td><td style=\"background-color:"+color+"\">" + ds[3] + "</td><td>" + ds[1] + "</td><td>" + ds[2] + "</td><td>" + alarmBuffer[i][2] + "</td>";
    statistics+="</tr>";
  }
  
  body += statistics;
  body += "</table>";
  
  return body;
}

string fwSysOverviewReport_getApplicationAlarmTrend(string application)
{
  dyn_dyn_float values;
  values[1][1] = dynlen(fwSysOverviewReport_queryApplicationAlarmHistory(application, 86400));
  values[1][2] = dynlen(fwSysOverviewReport_queryApplicationAlarmHistory(application, 86400/2));
  values[1][3] = dynlen(fwSysOverviewReport_queryApplicationAlarmHistory(application, 86400/3));
  values[1][4] = dynlen(fwSysOverviewReport_queryApplicationAlarmHistory(application, 86400/12));
  values[1][5] = dynlen(fwSysOverviewReport_queryApplicationAlarmHistory(application, 86400/24));

  return fwSysOverviewReport_getBarTrend("Alarm%20History", 
                                         values, 
                                         makeDynString("24h", "12h", "8h", "2h", "1h"), 
                                         makeDynFloat(0,10,20,30, 40),
                                         makeDynString("Alarms"),
                                         makeDynString("153E7E"));
}

string fwSysOverviewReport_getApplicationAlarmHistory(string application, int timeInterval = 86400)
{
  string report = "";
  dyn_dyn_mixed hostsReport = fwSysOverviewReport_getApplicationDeviceTypeAlarmHistory(application, "FwFMCNode", timeInterval, false);
  dyn_dyn_mixed plcsReport = fwSysOverviewReport_getApplicationDeviceTypeAlarmHistory(application, "IcemonPlc", timeInterval, false);
  dyn_dyn_mixed projectsReport = fwSysOverviewReport_getApplicationDeviceTypeAlarmHistory(application, "FwSystemOverviewProject", timeInterval, false);
  dyn_dyn_mixed sisReport = fwSysOverviewReport_getApplicationDeviceTypeAlarmHistory(application, "IcemonSystemIntegrity", timeInterval, false);

  if(dynlen(hostsReport) || dynlen(plcsReport) || dynlen(projectsReport) || dynlen(sisReport))
  {
    report = "<table border=\"1\">";
    report = report + "<tr><th>Accumulated Number of Alarms</th><th>Alarm Distribution per device type</th></tr>";   
    
    report = report + "<tr><td>"+fwSysOverviewReport_getApplicationAlarmTrend(application)+"</td>";
    report += "<td>"+fwSysOverviewReport_getPieChart("", 
                                            makeDynFloat(dynlen(hostsReport), dynlen(plcsReport), dynlen(projectsReport), dynlen(sisReport)), 
                                            makeDynString("Hosts:"+dynlen(hostsReport), "PLCs:"+dynlen(plcsReport), "Projects:"+dynlen(projectsReport), "SI:"+dynlen(sisReport)), 
                                            makeDynString("0000FF")) + "</td></tr>";
    report += "</table>";
    report += "<div style=\"margin-left:40px;\">";
    report += "<h5><a name=\"hostAlarms\">3.a Hosts</a></h5>";
    if(dynlen(hostsReport))
    {  
      report += fwSysOverviewReport_castToHtmlTable(hostsReport);
    }
    else
    {
      report += "<ul><li style=\"color:green\">No alarms</li></ul>";
    }
    
    report += "<h5><a name=\"projectAlarms\">3.b Projects</a></h5>";
    if(dynlen(projectsReport))
    {
      report += fwSysOverviewReport_castToHtmlTable(projectsReport);
    }
    else
    {
      report += "<ul><li style=\"color:green\">No alarms</li></ul>";
    }
    
    report += "<h5><a name=\"siAlarms\">3.c Systems Connectivity</a></h5>";
    if(dynlen(sisReport))
    {
      report += fwSysOverviewReport_castToHtmlTable(sisReport);
    }
    else
    {
      report += "<ul><li style=\"color:green\">No alarms</li></ul>";
    }
    
    report += "<h5><a name=\"plcAlarms\">3.d PLCs</a></h5>";
    if(dynlen(plcsReport))
    {
      report += fwSysOverviewReport_castToHtmlTable(plcsReport);
    }
    else
    {
      report += "<ul><li style=\"color:green\">No alarms</li></ul>";
    }

  }
  else
    report += "<div><ul><li style=\"font-family:verdana;color:green\">No alarms over the last " + (timeInterval/3600) + "h</li></ul>";
  
  report += "</div>";
  
  return report;
}

string fwSysOverviewReport_getApplicationActiveAlarms(string application)
{
  string body = "<ul><li>This section only shows past alarms thus excluding alarms active at the time of generation of this report.</li></ul>";
  dyn_dyn_anytype records = fwSysOverviewReport_queryApplicationActiveAlarms(application);
  
  string summary = "<table border=\"1\">";
  summary = summary + "<tr><th>No.</th><th>Category</th><th>System</th><th>Dp Identifier</th><th>Alarm text</th><th>Value</th><th>Time</th></tr>";    
  
  int alarms = 0;
  for(int i = 1; i <= dynlen(records); i++)
  {
    bool isSummary = (bool)records[i][6];
    if(isSummary)
      continue;
      
    ++alarms;
    string row1 = records[i][1];
    dyn_string ds = strsplit(row1, " ");
    string dpe = ds[1];
    string dpIdentifier = fwSysOverview_getDpeIdentifier(dpe);
    string systemName = dpSubStr(dpe, DPSUB_SYS);
    string row2 = records[i][2];
    string ts = substr(row2, 0, 30);
    string text = (string) records[i][3];
    string abbr = records[i][4];
    float value = records[i][5];
    string color = fwSysOverviewReport_getHtmlColor(abbr);
    
    summary += "<tr>";
    summary = summary + "<td>" + alarms + "</td>" + "<td style=\"background-color:"+color+"\">"+abbr +"</td><td>" +systemName+"</td><td>" +dpIdentifier+"</td><td>" + text + "</td><td>" + value + "</td><td>" + ts + "</td>";    
    summary += "</tr>";
  }
  summary += "</table>";  
   
  if(dynlen(records) > 0)
  {
    body += "<ul>";  
    body = body + "<li>Total number of Active Alarms: "+ alarms + "</li>";  
    body += "</ul>";  
    body += summary;  
  }
  else
  {
    body += "<ul><li style=\"color:green\">No active alarms at the time of generation of this report.</li></ul>";
  }

  return body;
}

/*
dyn_dyn_anytype fwSysOverviewReport_queryApplicationActiveAlarms(string application)
{
  dyn_dyn_anytype records, recordsLocal, recordsRemote;  
  //First, all alarms in the local system
  dyn_string dps = fwFsm_getDomainDevices(application);
  dyn_string dpePatterns;
  
  for(int i = 1; i <= dynlen(dps); i++)
  {
    string dp = "";
    if(!dpExists(dps[i]))
    {
      dp = dpAliasToName(dps[i]);      
      dp = dpSubStr(dp, DPSUB_DP);
    }
    else
      dp = dps[i];
    
    dynAppend(dpePatterns, dp + "*.**");
  }  

  string query = "SELECT ALERT '_alert_hdl.._text', '_alert_hdl.._abbr', '_alert_hdl.._value', '_alert_hdl.._sum' FROM '" + fwSysOverviewReport_prepareQueryPattern(dpePatterns) + "'";
  dpQuery(query, recordsLocal);

  int n = 1;
  for(int i =2; i <= dynlen(recordsLocal); i++)
  {
    bool isSummary = (bool)recordsLocal[i][6];
    if(isSummary)
      continue;

    records[n] = recordsLocal[i];
    ++n;
  }
  
  //Now the System Integrity Alarms in the remote systems
  int count = dynlen(records) + 1;
  dyn_string systems;
  dyn_int ids;
  fwSysOverview_getApplicationSystems(application, systems, ids);
  
  for(int i = 1; i <= dynlen(systems);i++)  
  {
    dyn_int connectedSystemsIds;
    dpGet("_DistManager.State.SystemNums", connectedSystemsIds);
//DebugN("Connected systems", connectedSystemsIds, " appplicaiton ids[i] = ", ids[i]);    
    if(dynContains(connectedSystemsIds, ids[i])<=0) //System not connected. Skip!
      continue;
    
    dpePatterns = makeDynString("_unSystemAlarm_*.alarm", "_ArchivDisk.FreeKB", "_MemoryCheck.FreeKB");
    //string systemsPattern = fwSysOverviewReport_getRemoteSystemsPattern();

    query = "SELECT ALERT '_alert_hdl.._text', '_alert_hdl.._abbr', '_alert_hdl.._value', '_alert_hdl.._sum' FROM '" + fwSysOverviewReport_prepareQueryPattern(dpePatterns) + "' REMOTE '"+ systems[i] + "'";
    dpQuery(query, recordsRemote);

    for(int j = 2; j <= dynlen(recordsRemote); j++)
    {
      records[count] = recordsRemote[j];
      ++count;
    }
  }  
  
  return records;
} 
*/

dyn_string fwSysOverview_getApplicationsAlarmsTypes()
{
  dyn_string types;
  dynClear(types);
  dynAppend(types, dpTypes("FwFMC*"));
  dynAppend(types, dpTypes("FwSystemOverview*"));
  dynAppend(types, dpTypes("Icemon*"));
  dynAppend(types, dpTypes("_FwFMC*"));
  dynAppend(types, dpTypes("_FwSystemOverview*"));
  dynAppend(types, dpTypes("_UnSystemAlarm"));
  return types;
}

dyn_string fwSysOverview_queryApplicationMaskedAlarmDpes(string application)
{
//  dyn_string dps = fwFsm_getDomainDevices(application);
  dyn_string dps = fwSysOverviewFsm_getTreeDevices(application, true);
  dyn_string types = fwSysOverview_getApplicationsAlarmsTypes();

  dyn_string maskedAlarms;
  dynClear(maskedAlarms);
  for(int j = 1; j <= dynlen(types); j++)
  {
    for(int k = 1; k <= dynlen(dps); k++)
    {
      string dp = "";
      if(!dpExists(dps[k]))
      {
        dp = dpAliasToName(dps[k]);                
        dp = dpSubStr(dp, DPSUB_DP);
      }
      else
        dp = dps[k];
      
      dyn_string dpes = dpNames(dp + "*.**", types[j]);
      int n = dynlen(dpes);
  
      for(int i = 1; i <= n; i++)
      {
        if(dpElementType(dpes[i]) == DPEL_STRUCT)
          continue;
      
        int configured = 0, active = 0;
        dpGet(dpes[i] + ":_alert_hdl.._type", configured, 
              dpes[i] + ":_alert_hdl.._active", active);
        if(configured && active == 0)
          dynAppend(maskedAlarms, dpes[i]);
      }
    }
  }
  dyn_string locallyMaskedAlarms = fwSysOverviewReport_queryApplicationLocallyMaskedAlarms(application);
  dynAppend(maskedAlarms, locallyMaskedAlarms);
  
  return maskedAlarms;
}    

dyn_string fwSysOverviewReport_queryApplicationLocallyMaskedAlarms(string application)
{
  dyn_string maskedAlarms;
  dyn_string connectedSystems, missingSystems, systemsWithAlarms;
  fwSysOverviewReport_getApplicationSystemIntegritySummary(application, connectedSystems, missingSystems, systemsWithAlarms);
  for(int i=1; i<= dynlen(connectedSystems); i++)
  {
    string unAppDp = icemon_getUnAppDp(connectedSystems[i]);
    dyn_string dpes, descriptions;
    dyn_bool active, alarmMasked;
    icemon_getApplicationSystemIntegrityAlarms(unAppDp, dpes, descriptions, active, alarmMasked);
    for(int j=1; j<=dynlen(dpes); j++)
    {
      if(alarmMasked[j])
        dynAppend(maskedAlarms, dpes[j]);
    }
  }
  return maskedAlarms;
}

string fwSysOverviewReport_getAppliationMaskedAlarms(string application)
{
  dyn_string dpes = fwSysOverview_queryApplicationMaskedAlarmDpes(application);  
  string body = "";
  if(dynlen(dpes) > 0)
  {
    body += "<ul>";  
    body = body + "<li>Total number of Masked Alarms: " + dynlen(dpes) + "</li>";  
    body += "</ul>";  
    body += "<table border=\"1\">";
    body = body + "<tr><th>No.</th><th>DPE</th><th>Identifier</th><th>Comment</th><th>Expiration date</th></tr>";    
  
    for(int i = 1; i <= dynlen(dpes); i++)
    {
      string comment;
      time expirationDate;
      fwSysOverview_getMaskedAlarmDetails(dpes[i], comment, expirationDate);
      string expDateStr;
      if (expirationDate > 0)
        expDateStr = formatTime("%d/%m/%Y %H:%M", expirationDate);
      string dpIdentifier = fwSysOverview_getDpeIdentifier(dpes[i]);
      body += "<tr>";
      body = body + "<td>" + i + "</td>" + "<td>"+dpes[i] +"</td><td>" +dpIdentifier+"</td><td>" + comment + "</td><td>" + expDateStr + "</td>";    
      body += "</tr>";
    }
    
    body += "</table>";  
  }  
  else
  {
    body += "<ul>";  
    body = body + "<li style=\"color:green\">No masked alarms at the time of generation of this report.</li>";  
    body += "</ul>";  

  }
  return body;
}
string fwSysOverviewReport_getApplicationSystemIntegrityStatistics(string application)
{
//  string body = "<h4>Number of System Integrity Alarms occurred yesterday</h4>";
  dyn_string systems;
  dyn_int ids;
  bool areAllSystemsConnected = true;
  fwSysOverview_getApplicationSystems(application, systems, ids);

  string summary = "";
  string body = "<div style=\"margin-left:40px;\">";
  int count = 1;
  
  dyn_string connectedSystems, missingSystems, systemsWithAlarms;
  fwSysOverviewReport_getApplicationSystemIntegritySummary(application, connectedSystems, missingSystems, systemsWithAlarms);
  
  for(int i = 1; i <= dynlen(systems); i++)
  {
//    dyn_int connectedSystemsIds;
//    dpGet("_DistManager.State.SystemNums", connectedSystemsIds);
//DebugN("Connected systems", connectedSystemsIds, " appplicaiton ids[i] = ", ids[i]);    
//    if(getSystemName() != systems[i] && dynContains(connectedSystemsIds, ids[i])<=0) //System not connected. Skip!
    if(getSystemName() != systems[i] && dynContains(connectedSystems, systems[i])<=0) //System not connected. Skip!
    {
      //the remote system is not currently connected.
      areAllSystemsConnected = false;
//      dynAppend(missingSystems, systems[i]);
//      summary += "<h6 style=\"color:red\">Remote System "+systems[i]+" NOT connected. Statistics not available.</h6>";
      continue; //skip the rest and jump to the next system
    }    
    
    dyn_string siDps = dpNames(systems[i] + "_unSystemAlarm_*.statistic.alarmPerDay");
    dyn_int values;
    dpGet(siDps, values);
    bool headerDone = false;
    for(int j = 1; j <= dynlen(siDps); j++)
    {
      bool locallyMasked = icemon_getAlarmMaskedLocally(dpSubStr(siDps[j], DPSUB_SYS_DP) + ".alarm");
      if(locallyMasked)
        continue;
      string dpIdentifier = fwSysOverview_getDpeIdentifier(siDps[j]);
      if(values[j] > 0)
      {
        if(!headerDone)
        {
          summary += "<h6 style=\"color:blue\">System "+systems[i]+"</h6>";
          summary += "<table border=\"1\">";
          summary += "<tr><th>No.</th><th>Dp Identifier</th><th>Occurrences per day</th></tr>";    
          headerDone = true;
        }
        summary += "<tr>";
        summary = summary + "<td>" + count + "</td><td>" + dpIdentifier + "</td><td>" + values[j] + "</td>";    
        summary += "</tr>";
        ++count;
      }
    }
    if(headerDone)
      summary += "</table>";
  }

  if(dynlen(missingSystems) > 0)
  {
    string str = missingSystems;
    strreplace(str, " | ", ", ");
    body += "<p style=\"color:red\">No System Integrity Statistics available for the following systems (NOT connected to MOON):<p>";
    body += "<p>"+str+"</p>";
  }
  else
  {
    body += "<p style=\"color:green\">All "+application+" systems successfully connected to MOON<p>";
  }
  
  if(count > 1)
    body += summary;
  else if(dynlen(missingSystems) <= 0)
  {
    body += "<ul>";
    body += "<li style=\"color:green\">No System Integrity Alarms in the last day !!!</li>";
    body += "</ul>";
  }
  
  body += "</div>";  
    
  return body;
}

string fwSysOverviewReport_generateApplication(string application)
{
  string report = "<!DOCTYPE HTML PUBLIC \"-//W3C//DTD HTML 4.01 Transitional//EN\" \"http://www.w3.org/TR/html4/loose.dtd\">";
  string t = getCurrentTime();
  report += "<html>";  
  report += "<head><title></title></head>";
  report += "<body style=\"font-family:verdana;font-size:13px\">";
  report += "<h4 style=\"font-family:verdana;color:blue\">MOON report for "+application+". Generated at "+substr(t, 0, (strlen(t)-7))+"</h4>";
  report += "<p>(Right-click on the pictures to download the images)</p>";
  report += "<h5>Contents:</h5>";
  //TOC
  report += "<ol>";
  report += "<li><font><a href=\"#systemSnapshot\">Application Status Snapshot</a></font></li>";
  report += "<li><a href=\"#activeAlarms\">Active Alarms</a></li>";
  report += "<li><a href=\"#historicalAlarms\">Alarm History (Last 24h)</a>";
  report += "<ol type=\"a\">";
    report += "<li><a href=\"#hostAlarms\">Hosts</a></li>";
    report += "<li><a href=\"#projectAlarms\">Projects</a></li>";
    report += "<li><a href=\"#siAlarms\">Systems Connectivity</a></li>";
    report += "<li><a href=\"#plcAlarms\">PLCs</a></li>";
  report += "</ol>";
  report += "</li>";
  report += "<li><a href=\"#siStatistics\">System Integrity Statistics</a></li>";
  report += "<li><a href=\"#maskedAlarms\">Masked Alarms</a></li>";
  report += "</ol>";
  //Body:  
  report += "<h5><a name=\"systemSnapshot\">1. Status Snapshot at "+ substr(t, 0, (strlen(t)-7)) + "</a></h5>";
  report += fwSysOverviewReport_getApplicationStatistics(application);
  report += "<h5><a name=\"activeAlarms\">2. Active Alarms</a></h5>";
  report += fwSysOverviewReport_getApplicationActiveAlarms(application);
  report += "<h5><a name=\"historicalAlarms\">3. Alarm History (Last 24h)</a></h5>";
  report += fwSysOverviewReport_getApplicationAlarmHistory(application);
  report += "<h5><a name=\"siStatistics\">4. System Integrity Statistics</a></h5>";
  report += fwSysOverviewReport_getApplicationSystemIntegrityStatistics(application);
  report += "<h5><a name=\"maskedAlarms\">5. Masked Alarms</a></h5>";
  report += fwSysOverviewReport_getAppliationMaskedAlarms(application);
  report += "</body>";
  report += "</html>";
  
  return report;
}


// -----------------------------------------------------------------------------------
// send an email via SMTP
// Parameter 
// smtp_host    name of the SMTP server
// name         domain name of the client
// email        The dyn_string email must contain the following 4 infos:
//              email[1] ... <destination>
//              email[2] ... <source>
//              email[3] ... <subject>
//              email[4] ... <body>
// ret          for error indication
// -----------------------------------------------------------------------------------
void fwSysOverviewReport_sendHtmlMail (string smtp_host, string name, dyn_string email, int & ret)
{
   int sock = 0, i;
   string rcv_buffer, s;
   dyn_string ds;

   //DebugN("emSendMail", "smtp_host", smtp_host, "name", name, "email", email);
   ret = 0;
   // check the dyn_string array
   if (dynlen(email) != 4)
   {
     emLogError(PRIO_SEVERE, "Email does not contain the 4 required fields");
     ret = -1;
     return;
   }
   // connect to the SMTP host
   if ( (sock = tcpOpen (smtp_host, 25)) < 0 )
   {          
     // error handling in tcpOpen
     emLogError(PRIO_SEVERE, "Cannot establish connection to SMTP server <" + smtp_host+ ">");
     ret = -1; return;
   }
   // check SMTP response
   emSmtpReadResp(sock, rcv_buffer, 220, ret);
   if (ret < 0)
   {
     emSmtpClose(sock);
     ret = -1; return;
   }

   tcpWrite(sock, "HELO "+ name + "\r\n");
   // check SMTP response
   emSmtpReadResp(sock, rcv_buffer, 250, ret);
   if (ret < 0)
   {
     emSmtpClose(sock);
     ret = -1; return;
   }

   tcpWrite(sock, "MAIL FROM: <" + email[2] + ">\r\n");
   // check SMTP response
   emSmtpReadResp(sock, rcv_buffer, 250, ret);
   if (ret < 0)
   {
     emSmtpClose(sock);
     ret = -1; return;
   }

   ds=strsplit(email[1], ";");
   for (i=1;i<=dynlen(ds); i++) ds[i]=strltrim(strrtrim(ds[i]));
   for(i=1;i<=dynlen(ds); i++)
   {
     tcpWrite(sock, "RCPT TO: <" + ds[i] + ">\r\n");
     // check SMTP response
     emSmtpReadResp(sock, rcv_buffer, 250, ret);
     if (ret < 0)
     {
       emSmtpClose(sock);
       ret = -1; return;
     }
   }

   tcpWrite(sock, "DATA\r\n");
   // check SMTP response
   emSmtpReadResp(sock, rcv_buffer, 354, ret);
   if (ret < 0)
   {
     emSmtpClose(sock);
     ret = -1; return;
   }

   // replace all german Umlaute in subject and body  IM 91030
   for ( int i = 3; i<= 4; i++)
   {
     strreplace(email[i], "Ä", "Ae"); 
     strreplace(email[i], "Ö", "Oe"); 
     strreplace(email[i], "Ü", "Ue"); 
     strreplace(email[i], "ß", "ss"); 
     strreplace(email[i], "ä", "ae"); 
     strreplace(email[i], "ö", "oe"); 
     strreplace(email[i], "ü", "ue"); 
   }

   tcpWrite(sock, "From: " + email[2] + "\r\n");
   tcpWrite(sock, "Date: " + rfcDate() + "\r\n");
   for(i=1;i<=dynlen(ds); i++)
     tcpWrite(sock, "To: " + ds[i] + "\r\n");
   tcpWrite(sock, "MIME-Version:1.0\r\n");
   tcpWrite(sock, "Content-type:text/html\r\n");
   tcpWrite(sock, "Subject: " + email[3] + "\r\n");
   tcpWrite(sock, "\r\n");
   tcpWrite(sock, email[4] + "\r\n");
   
   tcpWrite(sock, ".\r\n");
   // check SMTP response
   emSmtpReadResp(sock, rcv_buffer, 250, ret);
   if (ret < 0)
   {
     emSmtpClose(sock);
     ret = -1; return;
   }

   emSmtpClose(sock);
}

bool fwSysOverviewReport_wasSentToday(string application)
{
  string format = "%Y.%m.%d";
  string currentDate = formatTime(format, getCurrentTime());
  string dp = fwSysOverviewReport_getApplicationEmailDp(application);
  time lastSentTime;
  dpGet(dp + ".lastSentDate", lastSentTime);
  string lastSentDate = formatTime(format, lastSentTime);
  return (lastSentDate == currentDate);
      
}
fwSysOverviewReport_setSentDate(string application, time date)
{
  string dp = fwSysOverviewReport_getApplicationEmailDp(application);
  dpSet(dp + ".lastSentDate", date);
}

void fwSysOverview_getMaskedAlarmDetails(string dpe, string& comment, time& expirationDate)
{
  dyn_string maskedAlarms = dpNames("fwMaskedAlarms_*.active", "FwMaskedAlarms");
  dyn_bool active;
  dpGet(maskedAlarms, active);
  for(int i=1; i<=dynlen(maskedAlarms); i++)
  {
    if (active[i])
    {
      string dpName = dpSubStr(maskedAlarms[i], DPSUB_DP);
      dyn_string dpeList;
      dpGet(dpName + ".dpeList", dpeList);    
      int alarmIdx = dynContains(dpeList, dpe);
      if (alarmIdx > 0)
      {
        dyn_string comments;
        dpGet(dpName + ".comment", comments, dpName + ".expirationDate", expirationDate);
        comment = comments[alarmIdx];
        break;
      }
    }
  }
}
