#uses "fwSystemOverview/fwSystemOverviewReport.ctl"
#uses "fwSystemOverview/fwSystemOverviewFsm.ctl"

mapping activeAlarmDpeToTimestamp;//key ->dpe; value->time;text;value
mapping alarmToOccurrances;// key -> dpe ; value -> timeLastNotificationSent;numOfOccurrances;timeOcc1;timeOcc2;...timeNumOfIccurrances
mapping systemNameToApplication;
dyn_string connectedSummaryAlerts; // contains list of the _UnApplication dp's for which we have already done a dpConnect to the _dp_list of the summary alert
int cycleTime = 60;//seconds
int alarmActivePeriod = 15*60;//notify for alarms active for longer than this time(seconds)
int alarmRenotificationPeriod =8*60*60;//seconds
int alarmOccurrancesLimit = 3; // notify for alarms that have appeared more than these times
int alarmOccurrancesPeriod = 1*60*60;    // for this period(seconds)
int alarmOccurrancesRenotificationPeriod =2*60*60;//seconds  
string configDp = "fwSystemOverviewAlarmNotificationConfig";
string smsConfigDpPrefix = "fwSystemOverviewSmsConfig_";
const string FWSYSOVERVIEW_NOTIFICATION_ACTIVEALARMS_DPE = "fwSystemOverviewActiveAlarms.alarms";
const string FWSYSOVERVIEW_NOTIFICATION_ALARMSOCCURRANCES_DPE = "fwSystemOverviewAlarmsOccurrances.alarms";
dyn_int connectedSystems;
dyn_string failedDpDisconnects; // sometimes the dpDisconnect in _fwSysOverviewNotifications_summaryAlarmStateChangedCB fails so I sue this variable to keep track and don't do a dpConnect next time 
//flag showing if I should check whether _general.._string04 is set to YES
bool shouldCheckAlarmAttribute = true;
int minSleepTime = 30; // the minimum time of delay between two cycles
fwSysOverviewNotifications_start()
{
  //connect to the dp for the config
  dpConnect("_fwSysOverviewNotifications_configChangedCB", configDp + ".cycleTime",
            configDp + ".alarmActivePeriod",
            configDp + ".alarmRenotificationPeriod",
            configDp + ".alarmOccurrancesLimit",
            configDp + ".alarmOccurrancesPeriod",
            configDp + ".alarmOccurrancesRenotificationPeriod");
  //dpconnect to the dp for the connected systems - _fwSysOverviewNotifications_connectedSystemsChangedCB
  dpConnect("_fwSysOverviewNotifications_connectedSystemsChangedCB", "_DistManager.State.SystemNums"); 
  time currentTime;
  while (true)
  {
   
    currentTime = getCurrentTime();
    mapping applicationToText,applicationToDpes;
    fwSysOverviewNotifications_addLocalActiveAlarmsToBuffer(currentTime);
    fwSysOverviewNotifications_checkBufferForOccurrances(currentTime, applicationToText, applicationToDpes);
    dyn_string soTrees;
    fwSystemOverviewFsm_getTrees(soTrees);  
    for(int j = 1; j<= dynlen(soTrees); j++)
    {    
      dyn_string summaryText, summaryDpes;
      dyn_int types;
      dyn_string applications = fwCU_getChildren(types, soTrees[j]);
      for(int appCount = 1; appCount <= dynlen(applications); appCount++)
      {
        //get all active alarms for this application from the buffer 
        dyn_dyn_anytype appAlarms = fwSysOverviewNotifications_getApplicationActiveAlarmsFromBuffer(applications[appCount]);     
      
        // check if there are alarms active for time > alarmActivePeriod
        // check if there are alarms for renotification
        string text;
        dyn_string dpes = fwSysOverviewNotifications_checkAlarmsForNotifications(applications[appCount], appAlarms, currentTime, text);
        //get the alarm that has occured more than alarmOccurrancesLimit for the alarmOccurrancesPeriod
        if (mappingHasKey(applicationToText, applications[appCount]))
        {
          text = applicationToText[applications[appCount]] + text;
          string dpesOccStr = applicationToDpes[applications[appCount]];
          dyn_string dpesOcc = strsplit(dpesOccStr, ";");
          dynAppend(dpes, dpesOcc);
        }
      
        if (text != "")
        {
            // if the notifications for this application are active 
          string  smsConfigDp = smsConfigDpPrefix + strtoupper(applications[appCount]);
          if (dpExists(smsConfigDp))
          {
            bool active, includeInOverview;
            dpGet(smsConfigDp + ".active", active,
                  smsConfigDp + ".includeInOverview", includeInOverview);
            if (active)
            {
              text = "(" +applications[appCount]+ ") " + text;
              fwSysOverviewNotifications_sendNotification(applications[appCount], text, dpes);
              if(includeInOverview)
              {
                dynAppend(summaryText, text);
                dynAppend(summaryDpes, dpes);
              }
            }
          }
        }
      }
    
      if (dynlen(summaryText) > 0)
      {
        fwSysOverviewNotifications_sendSummary(summaryText, summaryDpes, soTrees[j]);
      }
    }
    fwSysOverviewNotifications_copyAlarms();
    int timePassed = getCurrentTime() - currentTime;
    int sleepTime = (cycleTime - timePassed < minSleepTime)?minSleepTime:cycleTime - timePassed;
    
    delay(sleepTime);
  }
}

void fwSysOverviewNotifications_copyAlarms()
{
  dyn_string activeAlarms;
  mapping activeAlarmDpeToTimestampTmp = activeAlarmDpeToTimestamp;
  mapping alarmToOccurrancesTmp = alarmToOccurrances;
  
  dyn_string keys = mappingKeys(activeAlarmDpeToTimestampTmp);
  for (int i=1; i<= dynlen(keys); i++)
  {
    string alarm = keys[i] + ";" + activeAlarmDpeToTimestampTmp[keys[i]];
    dynAppend(activeAlarms, alarm);
  }    

  
  dyn_string alarmsOccurrances;
  dyn_string keys = mappingKeys(alarmToOccurrancesTmp);
  for (int i=1; i<= dynlen(keys); i++)
  {
    string alarm = keys[i] + ";" + alarmToOccurrancesTmp[keys[i]];
    dynAppend(alarmsOccurrances, alarm);
  }    

  dpSet(FWSYSOVERVIEW_NOTIFICATION_ACTIVEALARMS_DPE, activeAlarms,
        FWSYSOVERVIEW_NOTIFICATION_ALARMSOCCURRANCES_DPE, alarmsOccurrances);
}

void _fwSysOverviewNotifications_configChangedCB(string cycleTimeDp, int cycleTimeVal,
                     string alarmActivePeriodDp, int alarmActivePeriodVal,
                     string alarmRenotificationPeriodDp, int alarmRenotificationPeriodVal,
                     string alarmOccurrancesLimitDp, int alarmOccurrancesLimitVal,
                     string alarmOccurrancesPeriodDp, int alarmOccurrancesPeriodVal,
                     string alarmOccurrancesRenotificationPeriodDp, int alarmOccurrancesRenotificationPeriodVal)
{
  cycleTime = cycleTimeVal;
  alarmActivePeriod = alarmActivePeriodVal;
  alarmRenotificationPeriod = alarmRenotificationPeriodVal;
  alarmOccurrancesLimit = alarmOccurrancesLimitVal;
  alarmOccurrancesPeriod = alarmOccurrancesPeriodVal;
  alarmOccurrancesRenotificationPeriod = alarmOccurrancesRenotificationPeriodVal;
}

fwSysOverviewNotifications_sendSummary(dyn_string summaryText, dyn_string dpes, string tree)
{
  string overviewDp = smsConfigDpPrefix + "OVERVIEW_" + strtoupper(tree);
  if (dpExists(overviewDp))
  {
    string recipients;
    bool active;
    dpGet(overviewDp + ".recipients", recipients,
          overviewDp + ".active", active);
    if (active)
    {
      string text;
      fwGeneral_dynStringToString(summaryText, text, " ; ");
      fwSysOverviewNotifications_sendNotification("", text, dpes, recipients);
    }
  }
  else
    DebugN("(Notifications) Summary dp doesn't exist: " + overviewDp);
}

fwSysOverviewNotifications_sendNotification(string application, string smsText, dyn_string dpes, string recipients = "")
{
  bool active = true;
  if (recipients == "")
  {
    string  smsConfigDp = smsConfigDpPrefix + strtoupper(application);
    dpGet(smsConfigDp + ".recipients", recipients,
          smsConfigDp + ".active", active);
  }  

  if (!active)
    return;  
  
  string smtpServer;
  string name;   
  string sender;
  string subject = "Alarms!";
  fwSysOverviewReport_getDefaultEmailConfig(sender, smtpServer, name);
  dyn_string email;
  email[1] = recipients;
  email[2] = sender;
  email[3] = subject;
  email[4] = smsText;
  int ret;
  emSendMail(smtpServer, name, email, ret);
  if (ret != -1)
  {
    string dpesStr;
    fwGeneral_dynStringToString(dpes, dpesStr, ";");
    dpSet("fwSystemOverviewSentEmailsLog.recipients", recipients,
          "fwSystemOverviewSentEmailsLog.emailText", smsText,
          "fwSystemOverviewSentEmailsLog.time", getCurrentTime(),
          "fwSystemOverviewSentEmailsLog.alarmsDpes", dpesStr);
  }
}

bool fwSysOverviewNotifications_shouldInhibitAlarm(string application, string dpe, time currentTime)
{
  bool shouldInhibit = false;
  // first check if the alarm has been configured for notification
  string alertNotificationConfigDpe = dpe + ":" + fwConfigs_PVSS_GENERAL + fwSystemOverview_SMS_DPCONFIG;
  string sendNotification = "NO";
  

  if(dpExists(alertNotificationConfigDpe))
  {
    dpGet(alertNotificationConfigDpe, sendNotification);
  }
  
  if (sendNotification == "YES" || !shouldCheckAlarmAttribute)
  {
    string dpelement = dpSubStr(dpe, DPSUB_DP_EL);
    string  smsConfigDp = smsConfigDpPrefix + strtoupper(application);
    string patterns;
    string inhibitUntilStr;
    bool active;
    dpGet(smsConfigDp + ".inhibitPatterns", patterns,
          smsConfigDp + ".inhibitUntil", inhibitUntilStr,
          smsConfigDp + ".active", active);
    dyn_string inhibitDates = strsplit(inhibitUntilStr, ";");
    if (active)
    {
      dyn_string inhibitPatterns = strsplit(patterns, ";");
      for(int i=1; i<= dynlen(inhibitPatterns); i++)
      {
        if (patternMatch(inhibitPatterns[i], dpelement))
        {
          time inhibitTime = (time) inhibitDates[i];
          if (inhibitTime == 0 || inhibitTime > currentTime)//check the date
          {
            shouldInhibit = true;
            break;
          }
        }
      }
    
    }
    else 
    {
      shouldInhibit = true;
    }
  }
  else
  {
    shouldInhibit = true;
  }
  return shouldInhibit;
}

void fwSysOverviewNotifications_checkBufferForOccurrances(time currentTime, mapping& applicationToText, mapping& applicationToDpes) synchronized(alarmToOccurrances)
{
  dyn_string alarmsDpes = mappingKeys(alarmToOccurrances);
  dyn_string alarmsToRemoveFromBuffer;
  for (int i=1; i<= dynlen(alarmsDpes); i++)
  {
   
    string alarmApplication;
    if (dpSubStr(alarmsDpes[i], DPSUB_SYS) != getSystemName())
    {
      alarmApplication = systemNameToApplication[dpSubStr(alarmsDpes[i], DPSUB_SYS)];
    }
    else
    {
      fwSysOverviewNotifications_getApplication(alarmsDpes[i], alarmApplication);
    }
    string alarmsTimesStr = alarmToOccurrances[alarmsDpes[i]];
    dyn_string alarmTimes = strsplit(alarmsTimesStr, ";");
    // the second element of the array is the number of occurrances
    //TODO indexes as constants
    int alarmOccurrances = (int) alarmTimes[2];
    string timeLastNotificationSent = alarmTimes[1];
    dynRemove(alarmTimes, 2);
    dynRemove(alarmTimes, 1);    
    if (dynlen(alarmTimes) == alarmOccurrances)
    {
      dyn_string newAlarmTimes;
      int timePassed;
      for(int j=1; j <= dynlen(alarmTimes) ; j++)
      {
        timePassed = currentTime - alarmTimes[j];
        if (timePassed <= alarmOccurrancesPeriod)
        {
          dynAppend(newAlarmTimes, alarmTimes[j]);
        }
        else
        {
          alarmOccurrances--;
        }
      }
      if (alarmOccurrances == 0)
      {
        dynAppend(alarmsToRemoveFromBuffer, alarmsDpes[i]);
        continue;
      }
      //update the buffer
      string newAlarmTimesStr;
      fwGeneral_dynStringToString(newAlarmTimes, newAlarmTimesStr, ";");
      if (alarmOccurrances >= alarmOccurrancesLimit)
      {
        // check how much time has passed since the last time this notification was sent
        int timeSinceLastNotification = -1;
        
        if (timeLastNotificationSent != "")
        {
          timeSinceLastNotification = currentTime - (time) timeLastNotificationSent;
        }
        // if notification hasn't been sent or the time passed is enough and the dpe doesn't match the patterns that shoulfd be inhibited
        if ((timeSinceLastNotification == -1 || timeSinceLastNotification > alarmOccurrancesRenotificationPeriod) && !fwSysOverviewNotifications_shouldInhibitAlarm(alarmApplication, alarmsDpes[i], currentTime))
        {
          string dpIdentifier = fwSysOverview_getDpeIdentifier(alarmsDpes[i]);
          string text = "Alarm "  + dpIdentifier + " occured " + + alarmOccurrances + " times for the last " + _fwSysOverviewNotifications_convertSecondsToHoursString(alarmOccurrancesPeriod) +"(dpe:" +alarmsDpes[i] + "); ";
          if (mappingHasKey(applicationToText, alarmApplication))
          {
            string currentText = applicationToText[alarmApplication];
            applicationToText[alarmApplication] = currentText + text;
          }
          else
          {
            applicationToText[alarmApplication] = text;
          }
          
          if (mappingHasKey(applicationToDpes, alarmApplication))
          {
            string currentDpes = applicationToDpes[alarmApplication];
            applicationToDpes[alarmApplication] = currentDpes + ";" + alarmsDpes[i];
          }
          else
          {
            applicationToDpes[alarmApplication] = alarmsDpes[i];
          }
        
          // save that notificaiton for this alarm is sent
          timeLastNotificationSent = (string) currentTime;
        }
      }
      
      alarmToOccurrances[alarmsDpes[i]] = timeLastNotificationSent + ";" + alarmOccurrances + ";" + newAlarmTimesStr;
      
     
    }
    else
      DebugN("Incorrect data in occurrances buffer. Occurrances: " + alarmOccurrances + " Times: " + alarmTimes);
    
  }
  
  // remove from the buffer all alarms for which there are no more occurrances during the last alarmOccurrancesPeriod
  for (int i=1; i<= dynlen(alarmsToRemoveFromBuffer); i++)
    mappingRemove(alarmToOccurrances, alarmsToRemoveFromBuffer[i]);
  
//  DebugN("Occurrances buffer checked. Current content: " + alarmToOccurrances);
}

string _fwSysOverviewNotifications_convertSecondsToHoursString(int seconds)
{
  int h = seconds/(60*60);
  int minutes = (seconds % (60*60))/60;
  string hoursStr = h+"h";
  if (minutes>0)
    hoursStr += " and " + minutes + "minutes";
  
  return hoursStr;
}

string _fwSysOverviewNotifications_convertSecondsToMinutesString(int seconds)
{
  int m = seconds/60;
  
  return (string)m + " minutes";
}
dyn_string fwSysOverviewNotifications_checkAlarmsForNotifications(string application, dyn_dyn_anytype activeAlarms,time currentTime, string& text)
{
  dyn_string dpes;
  string notificationText, renotificationText;
  int alarmsCount = 0;
  int alarmsRenotificaitonCount = 0;
  int timePassed;
  for (int i=1; i<= dynlen(activeAlarms); i++)
  {
    //TODO put indexes in constants
    time alarmTS = activeAlarms[i][2];
    timePassed = currentTime - alarmTS;//seconds
//    DebugN("t " + timePassed);
    if (timePassed >= alarmActivePeriod && timePassed < alarmActivePeriod + cycleTime)
    {
      if (!fwSysOverviewNotifications_shouldInhibitAlarm(application, activeAlarms[i][1], currentTime) )
      {
        alarmsCount++;
        string dpIdentifier = fwSysOverview_getDpeIdentifier(activeAlarms[i][1]);
        notificationText += alarmsCount + ". Desc: " + dpIdentifier + " TIME: " +activeAlarms[i][2] + " TEXT: " + activeAlarms[i][3] + " VALUE:"+activeAlarms[i][4] + " DPE:" + activeAlarms[i][1] +";\n ";
        dynAppend(dpes, activeAlarms[i][1]);
      }
    }
    
    int mod = timePassed % alarmRenotificationPeriod;
    if (timePassed >= alarmRenotificationPeriod && mod < cycleTime)
    {
      if (!fwSysOverviewNotifications_shouldInhibitAlarm(application, activeAlarms[i][1], currentTime) )
      {
        alarmsRenotificaitonCount++;
        string dpIdentifier = fwSysOverview_getDpeIdentifier(activeAlarms[i][1]);
        renotificationText += alarmsRenotificaitonCount + ". DPE: " + activeAlarms[i][1] + "(" + dpIdentifier + ")\n ";
        dynAppend(dpes, activeAlarms[i][1]);      
      }
    }
    
  }
  
  if ( alarmsCount > 0)
  {
    notificationText = alarmsCount + " new alarms!" + notificationText;
  }
  if (alarmsRenotificaitonCount > 0)
  {
    renotificationText = alarmsRenotificaitonCount + " alarms active more than "+_fwSysOverviewNotifications_convertSecondsToHoursString(alarmRenotificationPeriod) + ": " + renotificationText;

  }
  
 text = notificationText + renotificationText;

 return dpes;
}

//returns a list with the active  alarms Column1->dpe, Column2->timestamp, Column3->AlarmText, Column4->Alarm value
dyn_dyn_anytype fwSysOverviewNotifications_getApplicationActiveAlarmsFromBuffer(string application) synchronized(activeAlarmDpeToTimestamp)
{
  dyn_dyn_string alarms;
  int index =1;
  dyn_string localNotActiveAlarmsKeys;
  dyn_string dpes = mappingKeys(activeAlarmDpeToTimestamp);
  for (int i=1; i<= dynlen(dpes); i++)
  {
    string systemName = dpSubStr(dpes[i], DPSUB_SYS);
    // if this is local (moon_300:) alarm first we should check whether it is still active
    // and if it isn't we should remove it from the buffer at the end of the cycle
    if (systemName == getSystemName())    
    {
      bool active;
      dpGet(dpes[i] + ":_alert_hdl.._act_state", active);
      if (!active)
      {
        string dp = dpes[i];
        dynAppend(localNotActiveAlarmsKeys, dp);
        continue;
      }
    }
    
    if (mappingHasKey(systemNameToApplication, systemName) || systemName == getSystemName())
    {              
      string app;
      if (systemName != getSystemName())
        app = systemNameToApplication[systemName];
      else
      {
        fwSysOverviewNotifications_getApplication(dpes[i], app);
      }
      if (app != application || app == "")
        continue;
      
      string alarmDetailsStr = activeAlarmDpeToTimestamp[dpes[i]];
      dyn_string alarmDetails = strsplit(alarmDetailsStr, ";");
      if (dynlen(alarmDetails) == 3)
      {
        // SI alarm for this application
        alarms[index][1] = dpes[i];
        alarms[index][2] = alarmDetails[1];        
        alarms[index][3] = alarmDetails[2];                
        alarms[index][4] = alarmDetails[3];    
        index++;        
      }
      else
        DebugN("Incorrect data in buffer: " + alarmDetailsStr);
      
    }
    else
      DebugN("Unknown system name: " + systemName);
  }
  
  //clear from the buffer all local alarms that are not activeanymore
  for (int i=1; i<=dynlen(localNotActiveAlarmsKeys); i++)
    mappingRemove(activeAlarmDpeToTimestamp, localNotActiveAlarmsKeys[i]);
  
  //DebugN("Checked for  alarms of " + application + ". Result: " + alarms);
  return alarms;
}

//returns a list with the currently active alarms, and the alarms that came since last time: Column1->dpe, Column2->timestamp, Column3->AlarmText, Column4->Alarm value
dyn_dyn_anytype fwSysOverviewNotifications_addLocalActiveAlarmsToBuffer(time currentTime)
{
  time start = currentTime -  cycleTime;
  
  string startStr = start;
  string endStr = currentTime;
  
  string  query = "SELECT ALERT '_alert_hdl.._text', '_alert_hdl.._abbr', '_alert_hdl.._value', '_alert_hdl.._sum', '_alert_hdl.._direction' FROM '*.**' " + " TIMERANGE(\""+startStr+"\",\"" + endStr + "\",1,0)";
  dyn_dyn_anytype recordsHistory;
  string dpe, text, value, ts;
  dpQuery(query, recordsHistory);
  
  string queryActive =  "SELECT ALERT '_alert_hdl.._text', '_alert_hdl.._abbr', '_alert_hdl.._value', '_alert_hdl.._sum', '_alert_hdl.._direction' FROM '*.**' ";
  dyn_dyn_anytype recordsActive;
  dpQuery(queryActive, recordsActive);
  dyn_dyn_anytype records;  
  dynAppend(records, recordsHistory);
  dynAppend(records, recordsActive);  
  for(int i = 2; i <= dynlen(records); i++)
  {
    bool isSummary = (bool)records[i][6];
    if(isSummary)
      continue;

    bool isCame = (bool) records[i][7];
    if(!isCame)
      continue;
    
    string row1 = records[i][1];
    dyn_string ds = strsplit(row1, " ");
    dpe = ds[1];
    string row2 = records[i][2];
    ts = substr(row2, 0, 30);
    text = (string) records[i][3];
    value = records[i][5];
    string application;
    fwSysOverviewNotifications_getApplication(dpe, application);
    int timePassed = currentTime - ts;
    if(!mappingHasKey(activeAlarmDpeToTimestamp, dpe)) 
    { 
      if (application != "")
      {
        activeAlarmDpeToTimestamp[dpe] = ts + ";" + text + ";" + value;
        if (mappingHasKey(alarmToOccurrances, dpe))
        {
          string alarmString = alarmToOccurrances[dpe];
          dyn_string arr = strsplit(alarmString, ";");
          int occurrances = (int) arr[2] + 1; //TODO add indexes as constants
          arr[2] = occurrances;
          arr[dynlen(arr)+1]  = ts;
          string newAlarmString;
          fwGeneral_dynStringToString(arr, newAlarmString, ";");
          alarmToOccurrances[dpe] = newAlarmString;
        }
        //else add it and set the counter to 1
        else
        {
          string alarmString = ";1;" + ts;
          alarmToOccurrances[dpe] = alarmString;
        }
      }
    else
      DebugN("Cannot find application for " + dpe);    
   }
  }

}

void _fwSysOverviewNotifications_connectedSystemsChangedCB(string connectedSystemsDpe, dyn_int connectedSystemsIds)
{
 
  // for each of the systems 
  for (int i=1; i<= dynlen(connectedSystemsIds); i++)
  {
    int sysId = connectedSystemsIds[i];
    //if the system is newly connected
    if(!dynContains(connectedSystems, sysId))
    {
      string systemName = getSystemName(sysId);
      string systemStr = systemName + "_"  + sysId;
      strreplace(systemStr, ":", "");
      string dpName =  "icemonSystemIntegrity_" + strtoupper(systemStr);
      if (dpExists(dpName))
      {
        string application;
        
        fwSysOverviewNotifications_getApplication(dpName, application);
        systemNameToApplication[systemName] = application;
        //dpConnect to the state of the summary alert - _fwSysOverviewNotifications_summaryAlarmStateChangedCB
        dpConnect("_fwSysOverviewNotifications_summaryAlarmStateChangedCB", dpName + ".alarm");
        dynAppend(connectedSystems, sysId);
        
      }
      else 
        DebugN("Dp doesn't exist: " + dpName);
    }
  }
  
  //remove the systems that are not connected anymore from connectedSystems variable
  for(int i=1; i<= dynlen(connectedSystems);i++)
  {
    int pos = dynContains(connectedSystemsIds, connectedSystems[i]);
    if (pos == 0)
      dynRemove(connectedSystems, pos);
  }
  
}

void _fwSysOverviewNotifications_summaryAlarmStateChangedCB(string summaryAlarmDp, bool state) synchronized(connectedSummaryAlerts) 
{
  //get the _UnApplication dp
  string unAppDp;
  dpGet(dpSubStr(summaryAlarmDp, DPSUB_DP) + ".systemIntegrityDP", unAppDp);
  dyn_string dpes;
  dpGet(unAppDp + ".applicationName:_alert_hdl.._dp_list", dpes);
  int positionConnected = dynContains(connectedSummaryAlerts, dpSubStr(unAppDp, DPSUB_SYS_DP));

  if (state && positionConnected <= 0)
  {
    //fwInstallation_throw("Summary alarm active -> Dp connect to all alarms: " + dpSubStr(unAppDp, DPSUB_SYS_DP));
    for(int i=1; i<= dynlen(dpes); i++)
    {
      if (!dynContains(failedDpDisconnects, dpes[i]))
      {
        int err = dpConnect("_fwSysOverviewNotifications_alarmCB", dpes[i] + ":_alert_hdl.._act_state");
//         if(!err)
//           fwInstallation_throw("***Successfully connected to dpe: " + dpes[i]);
      }
      else
        dynRemove(failedDpDisconnects, dpes[i]); //remove after the first dpConnect to the dplist of this summary alert

    }
    dynAppend(connectedSummaryAlerts, dpSubStr(unAppDp, DPSUB_SYS_DP));
  }
  else if (!state && positionConnected > 0)
  { 
    //fwInstallation_throw("Summary alarm not active -> Dp disconnect from all alarms: " + dpSubStr(unAppDp, DPSUB_SYS_DP));
    for(int i=1; i<= dynlen(dpes); i++)
    {
      int err = dpDisconnect("_fwSysOverviewNotifications_alarmCB", dpes[i] + ":_alert_hdl.._act_state");
      if(err)
      {
        dynAppend(failedDpDisconnects, dpes[i]);
        //fwInstallation_throw("<<<<<<<Failed to disconnected from dpe: " + dpes[i]);
      }
           
    }
    dynRemove(connectedSummaryAlerts, positionConnected);
  }
  
}

void _fwSysOverviewNotifications_alarmCB(string alarmDp, bool active)
{
  string dpe = dpSubStr(alarmDp, DPSUB_SYS_DP_EL);
  // check whether this is an SBS alarm
  string masked;
  if(dpExists(dpe + ":_general" + fwSystemOverview_MASKED_DPCONFIG))
    dpGet(dpe+ ":_general" + fwSystemOverview_MASKED_DPCONFIG, masked);  
  //if this alarm should not be followed by the SBS do nothing
  if (masked == "YES")
    return;
  if (active)
  {
    //get the time of the alarm
    time t; 
    string text, value;
    dpGet(dpe + ":_original.._stime", t,
          dpe + ":_alert_hdl.._act_text", text,
          dpe + ":_original.._value", value);
    // add the alarm to activeAlarmDpeToTimestamp(key dpe)
//DebugN("Adding alarm to buffer:" + dpe, (string)t+";"+text+";"+value);    
    activeAlarmDpeToTimestamp[dpe] = (string)t+";"+text+";"+value;
    //if alarmToOccurrances has for key this alarm -> increase its counter
    if (mappingHasKey(alarmToOccurrances, dpe))
    {
      synchronized(alarmToOccurrances)
      {
        string alarmString = alarmToOccurrances[dpe];
        dyn_string arr = strsplit(alarmString, ";");
        int occurrances = (int) arr[2] + 1;
        arr[2] = occurrances;
        arr[dynlen(arr)+1]  = t;
        string newAlarmString;
        fwGeneral_dynStringToString(arr, newAlarmString, ";");
        alarmToOccurrances[dpe] = newAlarmString;
      }
    }
    //else add it and set the counter to 1
    else
    {
      string alarmString = ";1;" + (string)t;
      alarmToOccurrances[dpe] = alarmString;
    }
  }
  else
  {
    synchronized(activeAlarmDpeToTimestamp)
    {
      // remove the alarm from activeAlarmDpeToTimestamp
      mappingRemove(activeAlarmDpeToTimestamp, dpe);
    }
  }
  //DebugN("alarmCB: " + alarmToOccurrances);
  //fwSysOverviewNotifications_copyAlarms();
}
bool fwSysOverviewNotifications_fsmDeviceExists(string fsmDp)
{
  bool exists;
  dyn_string dps = dpNames("*|" + fsmDp, "_FwFsmDevice");
  exists = (dynlen(dps) > 0);
  return exists;
}

string fwSysOverviewNotifications_getFsmDp(string dp)
{
  string fmcPattern = "FwFMC*";
   
  string fsmDp;
  
   //if this is dp for another system replace it with the local icemonSystemIntegrity dp
  string systemName = dpSubStr(dp, DPSUB_SYS);
 
  if (systemName != getSystemName() || patternMatch("*_unSystemAlarm*", dp))
  {
    dp = "icemonSystemIntegrity_" + strtoupper(systemName) + "_" + getSystemId(systemName);
    strreplace(dp, ":", "");
  }

    
  
  string dpType = dpTypeName(dpSubStr(dp, DPSUB_DP));
  
  if (dpType == "IcemonSystemIntegrity" || dpType == "FwFMCNode" || dpType == "FwSystemOverviewProject")
  {
    fsmDp = dpSubStr(dp, DPSUB_DP);
  }
  else if (dpType == "IcemonPlc")
  {
    fsmDp = dpGetAlias(dpSubStr(dp, DPSUB_DP) + ".");
  }
  else if (patternMatch(fmcPattern, dpType))
  {
    fsmDp = fwFMC_getNodeDp(fwFMC_getNodeName(dpSubStr(dp, DPSUB_DP)));
    fsmDp = dpSubStr(fsmDp, DPSUB_DP);
  }
  else if (dpType == "FwSystemOverviewManager")
  {
    dyn_string arr = strsplit(dpSubStr(dp, DPSUB_DP), "/");
    if (dynlen(arr) == 4)
      fsmDp = arr[1] + "/" + arr[2] + "/" + arr[3];
    
  }
  
  return fsmDp;
}

bool fwSysOverviewNotifications_getApplication(string dp,string& application, string subtree = "")
{
  if (patternMatch("*dummy*", dp))
    return false;
  bool foundInSubTree = false;

  string rootPattern = "fwSO_*";

  if(!dpExists(dp))
  {
    DebugN("Dp doesn't exist: " + dp);
    return false;
  }

  string fsmDp = fwSysOverviewNotifications_getFsmDp(dp);
 
  
  if (fsmDp != "" && fwSysOverviewNotifications_fsmDeviceExists(fsmDp))
  {
     int type;
     string parent;
     string tmp = fsmDp;
     if (subtree != "")
     {
       //untill we reach our subtree or we reach the root
       while (!patternMatch(rootPattern, tmp) && !patternMatch(subtree, tmp) )
       {
          parent = tmp;
          tmp = fwCU_getParent(type, tmp);
          //sometime the method getParent returns empty string for unknown reason
          if(tmp == "")
          {
            DebugN("fwCU_getParent returned empty string for: " + parent);
            break;
          }
       }
       //check with which condition we exited the cycle
       foundInSubTree = patternMatch(subtree, tmp);
     }
     else
     {
       while (!patternMatch(rootPattern, tmp) )
       {
          parent = tmp;
          tmp = fwCU_getParent(type, tmp);
       }
       //awlays true
       foundInSubTree = true;
     }
    
     application = parent;
    
  }
  else
    DebugN("Cannot find fsm dp for " + dp);
  return foundInSubTree;
}
string fwSysOverviewNotifications_getApplicationLabel(string tree, string application)
{
  string label;
  string domain;

  if (fwSysOverviewFsm_isDomain(application))
    domain = application;
  else
    domain = tree;
    
  fwUi_getLabel(domain, application, label);
  
  return label;
}

string fwSystemOverviewNotifications_getDp(string application)
{
  return smsConfigDpPrefix + strtoupper(application);
}

void fwSystemOverviewNotifications_enable(string application)
{
   string dp = fwSystemOverviewNotifications_getDp(application);    
   if (dpExists(dp))
   {
     dpSet(dp+ ".active", true);
   }
}

void fwSystemOverviewNotifications_disable(string application)
{
   string dp = fwSystemOverviewNotifications_getDp(application);    
   if (dpExists(dp))
   {
     dpSet(dp+ ".active", false);
   }
}

void fwSystemOverviewNotifications_inhibitAllAlarms(string cunit, dyn_string alarms,string inhibitUntil)
{
  if (dynlen(alarms) >0)
  {
    string application;
    fwSysOverviewNotifications_getApplication(alarms[1], application);
    string dp = fwSystemOverviewNotifications_getDp(application);
    
    if(dpExists(dp))
    {
      dyn_string inhibitUntilArr;
      for(int i=1; i<=dynlen(alarms); i++)
        dynAppend(inhibitUntilArr, inhibitUntil);
      string inhibitStr = alarms;
      strreplace(inhibitStr, " | ", ";");
      string inhibitUntilStr = inhibitUntilArr;
      strreplace(inhibitUntilStr, " | ", ";");
      dpSet(dp + ".inhibitPatterns", inhibitStr,
            dp + ".inhibitUntil", inhibitUntilStr);
    }
  }
}

void fwSystemOverviewNotifications_clearInhibitPatterns(string application, time olderThanDate)
{
   string dp = fwSystemOverviewNotifications_getDp(application);   
   dyn_string currentInhibitPatterns, newInhibitPatterns, currentInhibitTimes, newInhibitTimes;
   dpGet(dp + ".inhibitPatterns", currentInhibitPatterns,
         dp + ".inhibitUntil", currentInhibitTimes);
   for(int i=1; i<=dynlen(currentInhibitPatterns); i++)
   {
     time t = (time)currentInhibitTimes[i];
     if (t > olderThanDate)
     {
       dynAppend(newInhibitPatterns, currentInhibitPatterns[i]);
       dynAppend(newInhibitTimes, currentInhibitTimes[i]);
     }
   }
   
   string inhibitStr = newInhibitPatterns;
   strreplace(inhibitStr, " | ", ";");
   string inhibitUntilStr = newInhibitTimes;
   strreplace(inhibitUntilStr, " | ", ";");
   dpSet(dp + ".inhibitPatterns", inhibitStr,
         dp + ".inhibitUntil", inhibitUntilStr);
  
}
