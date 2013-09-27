#uses "aes.ctl"
#uses "CMSfwInstallUtils/CMSfwInstallUtils.ctl"
#uses "fwInstallationUtils.ctl"


const string CMSfwAlertSystemUtil_CLIENTSERVERDP = "_CMSfwAlertSystemClientServer";
const string CMSfwAlertSystemUtil_CLIENTSERVERDPTYPE = "CMSfwAlertSystemClientServer";
const string CMSfwAlertSystemUtil_CONSISTENCYDP = "_CMSfwAlertSystemConsistency";
const string CMSfwAlertSystemUtil_CONSISTENCYDPTYPE = "CMSfwAlertSystemConsistency";
const int CMSfwAlertSystem_SUMALERT_THRESHOLD = 900;

global string CMSfwAlertSystemUtil_CurrentSystem;

global mapping CMSfwAlertSystemUtil_notifications;

string CMSfwAlertSystemUtil_getCurrentSystemName() {
    if (strlen(CMSfwAlertSystemUtil_CurrentSystem) == 0) return getSystemName();
    return CMSfwAlertSystemUtil_CurrentSystem;
}

void CMSfwAlertSystemUtil_setCurrentSystemName(string sysName) {
     CMSfwAlertSystemUtil_CurrentSystem = strrtrim(sysName, ":") + ":";
}

string CMSfwAlertSystemUtil_getNotificationDescription(string dpname) {
    dpname = dpSubStr(dpname, DPSUB_SYS_DP) + ".";
    string descr = dpGetDescription(dpname);
    if (descr != dpname) return descr;
    
    dyn_string exc;
    fwDevice_getName(strrtrim(dpname, ".") , descr, exc);
    return descr;
}

void CMSfwAlertSystemUtil_setNotificationDescription(string dpname, string description) {
  if (myManType() ==  UI_MAN) {
    CMSfwAlertSystemUtil_request("setNotificationDescription", makeDynString(dpname, description)); return;
  }   
  dpname = dpSubStr(dpname,DPSUB_SYS_DP);
  if (dpTypeName(dpname) != "CMSfwAlertSystemSumAlerts") {
      DebugTN("Not allowed to set description for dptype " + dpTypeName(dpname));
      return;
  }
  dpSetDescription(dpname + ".", description);
  if (CMSfwAlertSystemUtil_elementHasAlerts(dpname + ".SMSAck")) {
    dyn_string exc;
    fwAlertConfig_delete(dpname + ".SMSAck", exc);
    CMSfwAlertSystemUtil_createSmsAck(dpname);
  }  

  
}

CMSfwAlertSystemUtil_createNotification (string name, string description = ""){
  if (myManType() ==  UI_MAN) {
    CMSfwAlertSystemUtil_request("createNotification", makeDynString(name, description)); return;
  }  
  
  strreplace(name, " " , "_");
  
  dyn_string exceptionInfo;
  string dpname = "CMSAlertSystem/SumAlerts/" + name;
  if(!dpExists(dpname))
    dpCreate(dpname,"CMSfwAlertSystemSumAlerts");
  //DebugN("Now creating summary alert for this dpe: " + dpname + ".Notification");

 CMSfwAlertSystemUtil_initNotificationDp(dpname, exceptionInfo);
 
  if (strlen(description) >0) dpSetDescription(dpname + "." , description);
  
  CMSfwAlertSystemUtil_registerChange();
   
}

void CMSfwAlertSystemUtil_initNotificationDp(string dpname, dyn_string& exceptionInfo) {
    fwAlertConfig_set(dpname + ".Notification",
                    DPCONFIG_SUM_ALERT,
				makeDynString("FALSE", "TRUE"),
      makeDynInt(CMSfwAlertSystem_SUMALERT_THRESHOLD), // this is the threshold for alert reduction
				makeDynString(),   
      makeDynString(),   
				"",
				makeDynString(),      
				"",
				exceptionInfo,
        true, 
        true,"", false);
  fwAlertConfig_activate(dpname + ".Notification", exceptionInfo);
}



bool CMSfwAlertSystemUtil_addAlertToNotification (string NotificationName,
                                                  string dp) {
  if (myManType() ==  UI_MAN) {
    CMSfwAlertSystemUtil_request("addAlertToNotification", makeDynString(NotificationName, dp)); return;
  }  

  string NotificationDp = "CMSAlertSystem/SumAlerts/" + NotificationName ; 
  if(!dpExists(NotificationDp) || !dpExists(dp)) {
    DebugN("Not existing notification or not existing alert");
    return false;
  }
  dyn_string exceptionInfo;

  //DebugN("Adding alert " + dp + " to notification dp" + NotificationDp);
  
  // needs patched fwAlertConfig
  fwAlertConfig_addDpInAlertSummary(NotificationDp + ".Notification", 
                                    dp, exceptionInfo, false, false);  

  dyn_string dplist;
  dpGet(  NotificationDp + ".DpeList", dplist);
  if (! dynContains(dplist, dp) ) dynAppend(dplist, dp);
  dpSet(  NotificationDp + ".DpeList", dplist);
    
  CMSfwAlertSystemUtil_registerChange();
  return true;
  //DebugN(exceptionInfo);        
}





CMSfwAlertSystemUtil_deleteAlertFromNotification (string NotificationName,
                                                  string dp){
  if (myManType() ==  UI_MAN) {
    CMSfwAlertSystemUtil_request("deleteAlertFromNotification", makeDynString(NotificationName, dp)); return;
  }  

  dyn_string exc;
  string NotificationDp = "CMSAlertSystem/SumAlerts/" + NotificationName ; 
  dyn_string exceptionInfo;
  if(dpExists(NotificationDp) ){
    dyn_string dpeList;
    bool isActive = CMSfwAlertSystemUtil_getSumAlertDpList(NotificationDp +".Notification",dpeList); // get the old dpeList
    
    
    fwAlertConfig_deleteDpFromAlertSummary(NotificationDp +".Notification", 
                                           dp, exceptionInfo);
    
    if (dynlen(dpeList) == 1) {
      // when deleting the last alert, the framework function does not treat it properly (it doesn't remove it from the list, so we do it by hand)
      if (dpeList[1] == dp) {         
          if (isActive) fwAlertConfig_deactivate(NotificationDp +".Notification",exc); //the alert must be deactivated before setting the list
          dpSetWait(NotificationDp +".Notification" + ":_alert_hdl.._dp_list",makeDynString());
          if (isActive) fwAlertConfig_activate(NotificationDp +".Notification",exc);         
      }
    }    
    
  
    dyn_string dplist;
    dpGet(  NotificationDp + ".DpeList", dplist);
    int position =  dynContains(dplist, dp);
    if (position>0 ) dynRemove(dplist, position);
    dpSet(  NotificationDp + ".DpeList", dplist);
    CMSfwAlertSystemUtil_registerChange();
  } else {
    DebugTN(NotificationDp + " does not exist");    
  }
}

string CMSfwAlertSystemUtil_getFullUserName(string userName) {
  if (userName == "root") return "root";
  if (strlen(userName)==0) return "<no user>";
  
  string description, userFullName;
  int userId;
  bool enabled; dyn_string groups, exceptionInfo;
  
  
 fwAccessControl_getUser(userName,
                        userFullName,
                        description,
                        userId,
			enabled,
			groups,
                        exceptionInfo); 
 userFullName= strtolower(userFullName);
 dyn_string split = strsplit(userFullName," ");
 // capitalize initial letters
 userFullName = "";
 for (int i=1; i<= dynlen(split); i++) {
     userFullName += strtoupper(substr(split[i],0,1)) + substr(split[i],1);
     if (i<dynlen(split)) userFullName +=" ";
 }
 return userFullName;
}


CMSfwAlertSystemUtil_addUser (string userName){
  if (myManType() ==  UI_MAN) {
    CMSfwAlertSystemUtil_request("addUser", makeDynString(userName)); return;
  }  
  dyn_string info;
  userName = strtolower(userName);  
  CMSfwAlertSystemGeneral_getContactInfo (userName, info, false);
  if(dynlen(info)==0)
    return;
  if(!dpExists("CMSAlertSystem/Users/" + userName))      
    dpCreate("CMSAlertSystem/Users/" + userName,CMSfwALERTSYSTEM_USERTYPE );
  if(dpExists("CMSAlertSystem/Users/" + userName))      {
    CMSfwAlertSystemGeneral_getContactInfo (userName, info);         
  }
  CMSfwAlertSystemUtil_registerChange();
}

CMSfwAlertSystemUtil_createUser(string userName, string email, string gsm) {
  if (myManType() ==  UI_MAN) {
    CMSfwAlertSystemUtil_request("createUser", makeDynString(userName,email,gsm)); return;
  }  
   
  userName = strtolower(userName);
  if(!dpExists("CMSAlertSystem/Users/" + userName))      
    dpCreate("CMSAlertSystem/Users/" + userName,CMSfwALERTSYSTEM_USERTYPE );
  if(dpExists("CMSAlertSystem/Users/" + userName))  {
      dpSet("CMSAlertSystem/Users/" + userName + ".Name", userName,
            "CMSAlertSystem/Users/" + userName + ".MailAddress", email,
            "CMSAlertSystem/Users/" + userName + ".GSMNumber", gsm);      
  }
    CMSfwAlertSystemUtil_registerChange();  
  
}

CMSfwAlertSystemUtil_addGroup (string groupName){
  if (myManType() ==  UI_MAN) {
    CMSfwAlertSystemUtil_request("addGroup", makeDynString(groupName)); return;
  }    
  if(!dpExists("CMSAlertSystem/Groups/" + groupName))   {   
    dpCreate("CMSAlertSystem/Groups/" + groupName,CMSfwALERTSYSTEM_GROUPTYPE );
    dpSet("CMSAlertSystem/Groups/" + groupName + ".Name", groupName);
    CMSfwAlertSystemUtil_registerChange();
  }
}

CMSfwAlertSystemUtil_removeUser(string userDp){
  
  if (myManType() ==  UI_MAN) {
    CMSfwAlertSystemUtil_request("removeUser", makeDynString(userDp)); return;
  } 

  
  if(dpExists(userDp))  {    
    string sys; dyn_string exc;
    fwGeneral_getSystemName(dpSubStr(userDp,DPSUB_SYS_DP), sys, exc);
    if (sys != getSystemName()) {
        DebugTN("Not allowed to delete remote dp");
        return;
    }
    string typeName = dpTypeName(userDp);
    if (( typeName != CMSfwALERTSYSTEM_GROUPTYPE) && ( typeName != CMSfwALERTSYSTEM_USERTYPE)) {
      DebugTN("Not allowed to delte dp of type " + typeName);
      return;
    } 
    
    DebugN("Deleting user / group: " + userDp);
    dpDelete(userDp);
    CMSfwAlertSystemUtil_registerChange();
  }
  else{
    DebugN("Dp " + userDp + " does not exist"); 
  }
}
 
/*
CMSfwAlertSystemUtil_deleteNotificationFromUser(string userName,
                                                string notification,
                                                string notificationType){
  string userDp = CMSfwAlertSystemUtil_getCurrentSystemName() + "CMSAlertSystem/Users/" + userName;
  string notificationDP = CMSfwAlertSystemUtil_getCurrentSystemName() + "CMSAlertSystem/SumAlerts/" + notification;
  if(dpExists(userDp) ){
    dyn_string dsNotifications,
               dsNotificationType;
    dyn_int    diNotificationPriority;    
    dyn_bool   dbNotificationSent;
    dpGet(userDp + ".Notifications",        dsNotifications,
          userDp + ".NotificationTypes",    dsNotificationType,
          userDp + ".NotificationPriority", diNotificationPriority,
          userDp + ".NotificationSent",     dbNotificationSent);
        
        
   }
} 
*/

bool _CMSfwAlertSystemUser_hasNotification(string userDp,
                                      string notifCombo){
 dyn_string notifications,
             notificationTypes;
 dpGet(userDp + ".Notifications",     notifications,
       userDp + ".NotificationTypes", notificationTypes);
 for(int i=1; i <= dynlen(notifications);i++){   
   //DebugN(notifications[i]+notificationTypes[i]);
   //DebugN(notifCombo);
   if(notifications[i]+notificationTypes[i]==notifCombo)
     return true;
 }  
 return false;
  
}

CMSfwAlertSystemUtil_addNotificationToUser (string userDp,
                                            string notification,
                                            string notificationType,
                                            int    notificationPriority){

  string userName;
  dyn_string exc;
  fwDevice_getName(userDp, userName, exc);
  
  string notificationDP = CMSfwAlertSystemUtil_getCurrentSystemName() + "CMSAlertSystem/SumAlerts/" + notification;
  
  if(_CMSfwAlertSystemUser_hasNotification(userDp, notificationDP + notificationType)){
    DebugN("User " + userName + " has notif "+ notification);
    return;
  }    
  if(dpExists(userDp) && dpExists(notificationDP)){
    dyn_string dsNotifications,
               dsNotificationType;
    dyn_int    diNotificationPriority;    
    dyn_bool   dbNotificationSent;
    dpGet(userDp + ".Notifications",        dsNotifications,
          userDp + ".NotificationTypes",     dsNotificationType,
          userDp + ".NotificationPriority", diNotificationPriority,
          userDp + ".NotificationSent",     dbNotificationSent);
    dynAppend(dsNotifications,       notificationDP);
    dynAppend(dsNotificationType,    notificationType);
    dynAppend(diNotificationPriority,notificationPriority);
    dynAppend(dbNotificationSent,"FALSE");
    
    dpSetWait(userDp + ".Notifications",        dsNotifications,
              userDp + ".NotificationTypes",     dsNotificationType,
              userDp + ".NotificationSent",     dbNotificationSent,
              userDp + ".NotificationPriority", diNotificationPriority);
    CMSfwAlertSystemUtil_registerChange();
    if (notificationType == "SMSACK") {
        CMSfwAlertSystemUtil_createSmsAck(notificationDP);
    }
    
  }
  else{
    DebugN("Check the syntax of the following dpes");
    DebugN(userDp, notificationDP);
  }
}


CMSfwAlertSystemUtil_createSmsAck( string notificationDp) {
  if (myManType() ==  UI_MAN) {
    CMSfwAlertSystemUtil_request("createSmsAck", makeDynString(notificationDp)); return;
  } 
  if (CMSfwAlertSystemUtil_elementHasAlerts(notificationDp + ".SMSAck")) return;
  string descr = CMSfwAlertSystemUtil_getNotificationDescription(notificationDp);  
  dyn_string exc;
  
  fwAlertConfig_createAnalog(notificationDp + ".SMSAck", makeDynString(descr + " (expert acknowledged)","Normal", descr + " (not acknowledged by expert)"),
                             makeDynFloat(0,1),
                           makeDynString("_fwWarningNack_50","", "_fwFatalNack_90"), "",makeDynString(), "", exc);   
  fwAlertConfig_activate(notificationDp + ".SMSAck", exc);
  
  if (dynlen(exc)> 0) DebugTN(exc);  
    
  
  
}
CMSfwAlertSystemUtil_updateNotifications(string userDp,
                                     dyn_string notifications,
                                     dyn_string notificationTypes,
                                     dyn_bool notificationSent,
                                     dyn_int notificationPriority){
  
  if(  dynlen(notifications)==dynlen(notificationTypes) && 
       dynlen(notifications)==dynlen(notificationSent) && 
       dynlen(notifications)==dynlen(notificationPriority)) {
    dpSetWait(userDp + ".Notifications",        notifications,
              userDp + ".NotificationTypes",     notificationTypes,
              userDp + ".NotificationSent",     notificationSent,
              userDp + ".NotificationPriority", notificationPriority); 
    for (int i=1; i<= dynlen(notifications); i++) {
      if (notificationTypes[i] == "SMSACK") {
          CMSfwAlertSystemUtil_createSmsAck(notifications[i]);
      }
    }  
   
    
    CMSfwAlertSystemUtil_registerChange();

    CMSfwAlertSystemUtil_disableUnusedSmsAck("dummy");
  }
}


void CMSfwAlertSystemUtil_disableUnusedSmsAck(string dummy) {
   if (myManType() ==  UI_MAN) {
    CMSfwAlertSystemUtil_request("disableUnusedSmsAck", makeDynString(dummy)); return;
  } 

  dyn_string users = dpNames("CMSAlertSystem/*","CMSfwAlertSystemUsers");
  dyn_string notifications = dpNames("CMSAlertSystem/*","CMSfwAlertSystemSumAlerts");
  dyn_bool hasAckSms;  
  hasAckSms[dynlen(notifications)] = false;
  
  dyn_string userNotif; dyn_string userNotifType; int notifIndex;
  for (int i=1; i<= dynlen(users); i++) {
    dpGet(users[i] + ".Notifications", userNotif,
          users[i] + ".NotificationTypes", userNotifType);
    for (int j=1; j<= dynlen(userNotif); j++) {
      if (userNotifType[j] == "SMSACK") {
        notifIndex = dynContains(notifications, userNotif[j]);
        hasAckSms[notifIndex] = true;
      }      
    }
  }
  dyn_string exc;  
  for (int i=1; i<= dynlen(notifications); i++) {
    if (! hasAckSms[i] ) {
      if (CMSfwAlertSystemUtil_elementHasAlerts(notifications[i] + ".SMSAck")) {
          DebugN("Deleting alert from " + notifications[i] + ".SMSAck");
          fwAlertConfig_delete(notifications[i] + ".SMSAck", exc);
          dpSet(notifications[i] + ".SMSAck",0);
      }
     }
  }

   
  
}

bool CMSfwAlertSystemUtil_elementHasAlerts(string dpe) {
      bool   	configExists;
      int   	alertConfigType;
      dyn_string   	alertTexts;

      dyn_string   	alertClasses;
      dyn_string   	summaryDpeList;
      string   	alertPanel;
      dyn_string   	alertPanelParameters;
      string   	alertHelp;
      bool   	isActive; dyn_float limits;
      dyn_string   	exceptionInfo;
   
  
      fwAlertConfig_get  	(  dpe,
    			   configExists,
    			   alertConfigType,
    			   alertTexts,
    			   limits,
    			   alertClasses,
    			   summaryDpeList,
    			   alertPanel,
    			   alertPanelParameters,
    			   alertHelp,
    			   isActive,
    			   exceptionInfo
    			   )    ; 
      return configExists;
}

CMSfwAlertSystemUtil_processRequest(string dpe, string request) {
  
  if(!fwInstallationRedu_isPassive()){//Redu check
  dpe = dpSubStr(dpe, DPSUB_SYS_DP);
  dpSet(dpe + ".request:_lock._original._locked", true);
    
  dyn_string commands = strsplit(request, "\t");
  
  string response = "MALFORMED_REQUEST";
  string script;
  if (dynlen(commands) ==2) {
    if (isFunctionDefined("CMSfwAlertSystemUtil_" + commands[1])) {
      script = "void main() { CMSfwAlertSystemUtil_" + commands[1] + "(" + commands[2] + "); }";
      int res = execScript(script, makeDynString());
      if (res == -1) {
          response = "ERROR";
       } else {
         response = "OK";     
       }        
    } else {
      response = "Function " + commands[1] + " does not exist"; 
    }      
  } else {
    response = "Wrong #arguments";    
  }
  
  dpSet(dpe + ".response", response);      
  dpSet(dpe + ".request:_lock._original._locked", false);
  }
}

bool CMSfwAlertSystemUtil_request(string function, dyn_string parameters, time timeout = 30) {
//    DebugTN("request", function , parameters);
  if (! dpExists(CMSfwAlertSystemUtil_getCurrentSystemName() + CMSfwAlertSystemUtil_CLIENTSERVERDP) ) {
    CMSfwAlertSystemUtil_showMsg("Please start the CMSfwAlertSystem script on system " + CMSfwAlertSystemUtil_getCurrentSystemName() );
     return false;
  }  
  
    bool locked;
    string dpe_request = CMSfwAlertSystemUtil_getCurrentSystemName() + CMSfwAlertSystemUtil_CLIENTSERVERDP + ".request";
    int count = 0;
    do {
      dpGet(dpe_request + ":_lock._original._locked", locked);
      if (locked) {
        DebugTN(dpe_request + " is locked, waiting one second");
        
        delay(1);
        count++;
        if (count == 30) {
          CMSfwAlertSystemUtil_showMsg("CMSfwAlertSystem server is busy");
          return false;
        }
      }
    } while (locked);
    string par;
    for (int i=1; i<= dynlen(parameters); i++) {
          par += "\"" + parameters[i] + "\"";
          if (i < dynlen(parameters)) par += ",";
    }    
    
    string request = function + "\t" + par;
    DebugN("Request = " + request  + " to sys " + CMSfwAlertSystemUtil_getCurrentSystemName());
    

    
    string response = CMSfwAlertSystemUtil_getCurrentSystemName() + CMSfwAlertSystemUtil_CLIENTSERVERDP + ".response";
    
    dyn_anytype returnValues;
    bool timerExpired;
    dyn_anytype condition = makeDynAnytype();

  dyn_string waitVal = makeDynString(response + ":_original.._value");

  
  dpSet(dpe_request, request);
  if (dpWaitForValue(waitVal,condition, 
		     waitVal, returnValues, timeout, timerExpired) == -1) {
    CMSfwAlertSystemUtil_showMsg("Error in dpWaitForValue");
    return false;
  }
  if (timerExpired) {
    CMSfwAlertSystemUtil_showMsg("Timeout expired while waiting the answer from the server");
    return false;
  }

  DebugN("Response = " + returnValues[1]);
  if (returnValues[1] != "OK") {
      CMSfwAlertSystemUtil_showMsg("Problem in executing the request.\nResponse from server is " + returnValues[1]);
  }

  return true;  
    
}




  

void CMSfwAlertSystemUtil_synchronizeNotificationDpeList() {
  dyn_string dpNotifications = dpNames(CMSfwAlertSystemUtil_getCurrentSystemName() + "*","CMSfwAlertSystemSumAlerts"); dyn_string dpid;
  
  for (int i=1; i<= dynlen(dpNotifications); i++) {
      CMSfwAlertSystemUtil_getSumAlertDpList (dpNotifications[i] +".Notification", dpid);  
     // DebugN(dpNotifications[i], dpid);
      dpSet (dpNotifications[i] +".DpeList", dpid);
  }    
}


/* returns isActive */
bool CMSfwAlertSystemUtil_getSumAlertDpList(string dpe, dyn_string& dpeList) {
    bool configExists, isActive;
  int position, removed, alertType;
  string alertPanel, alertHelp;
  dyn_float alertLimits;
  dyn_string alertTexts, alertClasses,  alertPanelParameters, exceptionInfo;
  
  fwAlertConfig_get(dpe, configExists, alertType, alertTexts, alertLimits, alertClasses, dpeList,
                    alertPanel, alertPanelParameters, alertHelp, isActive, exceptionInfo);
  
 // DebugN("CMSfwAlertSystemUtil_getSumAlertDpList",dpe, dpeList, alertType, exceptionInfo);
  if (dynlen(exceptionInfo)>0) {
      DebugN(exceptionInfo);
      dpeList = makeDynString();
      return false;
  }
   if(alertType != DPCONFIG_SUM_ALERT)
  {
    DebugN( dpe+" does not have a summary alert.", "");
    dpeList = makeDynString();
    return false;
  }
   return isActive;
}


void CMSfwAlertSystemUtil_fixSystemNames() {
    string mySys = getSystemName(); string myDp;
    
    dyn_string dpUsers = dpNames("*","CMSfwAlertSystemUsers"); 
    dynAppend(dpUsers, dpNames("*","CMSfwAlertSystemGroups")); 
    
    dyn_string dpid , exc;
  // fix system name
  for (int i=1; i<= dynlen(dpUsers); i++) {   
    dpGet (dpUsers[i] +".Notifications", dpid);     
      for (int j=1; j<= dynlen(dpid); j++) {
        fwGeneral_getNameWithoutSN(dpid[j], myDp, exc);
        dpid[j] = mySys + myDp;    
      }
      dpSet (dpUsers[i] +".Notifications", dpid);
  }
    
}
void CMSfwAlertSystemUtil_applyNotificationSumAlerts() {
  dyn_string dpNotifications = dpNames("*","CMSfwAlertSystemSumAlerts"); 
  dyn_string dpid;
  string notifname; dyn_string exc;
  
  string mySys = getSystemName(); string myDp;
  // fix system name
  for (int i=1; i<= dynlen(dpNotifications); i++) {   
      dpGet (dpNotifications[i] +".DpeList", dpid);     
      for (int j=1; j<= dynlen(dpid); j++) {
        fwGeneral_getNameWithoutSN(dpid[j], myDp, exc);
        dpid[j] = mySys + myDp;    
      }
      dpSet (dpNotifications[i] +".DpeList", dpid);
  CMSfwAlertSystemUtil_initNotificationDp(dpNotifications[i], exc);     
      
  } 
  
  
  for (int i=1; i<= dynlen(dpNotifications); i++) {   
      dpGet (dpNotifications[i] +".DpeList", dpid);     
      for (int j=1; j<= dynlen(dpid); j++) {
        fwDevice_getName(dpNotifications[i], notifname, exc);
        CMSfwAlertSystemUtil_addAlertToNotification(notifname, dpid[j]);
      }
  } 
}


bool CMSfwAlertSystemUtil_saveToConfigurationDb(string configurationName = "") {
 
  if ((myManType() == UI_MAN) && (CMSfwAlertSystemUtil_getCurrentSystemName() != getSystemName()))  {
      CMSfwAlertSystemUtil_request("saveToConfigurationDb", makeDynString(configurationName)); return;
  }
 string systemName = strrtrim(CMSfwAlertSystemUtil_getCurrentSystemName(),":");
  if (strlen(configurationName) == 0) configurationName = systemName;
  string configurationNameOrig = configurationName;
  
  configurationName  = "CMSfwAlertSystem_" + configurationName;
  g_fwConfigurationDB_Debug = 1;

 string hierarchy = fwDevice_HARDWARE;
 

  
  string configDesc = "Backup of Alert System for " + systemName;
  dyn_string deviceList,exceptionInfo;
  dyn_string aDpTypes;
  int deviceConfigs = 0; //fwConfigurationDB_deviceConfig_ALLDEVPROPS;
  
  deviceConfigs = fwConfigurationDB_deviceConfig_VALUE    
    + fwConfigurationDB_deviceConfig_ALERT
    + fwConfigurationDB_deviceConfig_ARCHIVING;
  
 fwConfigurationDB_checkInit(exceptionInfo);
 if (dynlen(exceptionInfo)>0) {
   if (myManType() == UI_MAN) {
       fwExceptionHandling_display(exceptionInfo);
   } else {
     DebugTN(exceptionInfo);      
   }
   return false;
 }  
  CMSfwAlertSystemUtil_synchronizeNotificationDpeList();
  CMSfwInstallUtils_deleteConfiguration(configurationName, exceptionInfo);
  dyn_string deviceList = dpNames("CMSAlertSystem/*");
  

  if (myManType() == UI_MAN) {
    fwConfigurationDB_openProgressDialog(
      	makeDynInt( fwConfigurationDB_OPER_SaveDevices),
      	makeDynString(	"Store devices to DB"));
  }

  fwConfigurationDB_saveDeviceConfigurationInDB(deviceList, hierarchy,
    configurationName, deviceConfigs , exceptionInfo, systemName, configDesc);

  if (myManType() == UI_MAN) {
    if (fwConfigurationDB_handleErrors(exceptionInfo)) return false;
    fwConfigurationDB_closeProgressDialog();
  } else {
    if (dynlen(exceptionInfo) > 0) {
      DebugTN(exceptionInfo);      
      return false;      
    }
  }
  CMSfwAlertSystemUtil_registerChange("savedToDb");
  CMSfwAlertSystemUtil_registerConfigurationName(configurationNameOrig);
  return true;
    
}

void CMSfwAlertSystemUtil_deleteAllDps(string pattern) {
    if (myManType() ==  UI_MAN) {
      CMSfwAlertSystemUtil_request("deleteAllDps", makeDynString(pattern)); return;
    }   
    dyn_string dps =  dpNames("CMSAlertSystem/" + pattern);
    
    for (int i=1; i<= dynlen(dps); i++) {
      dpDelete(dps[i]);
    }   
   CMSfwAlertSystemUtil_registerChange();   
}


void CMSfwAlertSystemUtil_postConfigLoaded(string tag, int current, int total) {
  if (current > total) return; // skip the last time
  //  DebugTN("CMSfwAlertSystemUtil_postConfigLoaded: " + tag + " loaded");
    dyn_string users = dpNames("*", "CMSfwAlertSystemUsers");
    dyn_string elements = makeDynString(".Notifications", ".NotificationTypes",".NotificationSent", ".NotificationPriority");
    string dpe;
    for (int i=1; i<= dynlen(users); i++) {
      for (int j=1; j<= dynlen(elements); j++) {
        dpe = (users[i] + elements[j]);
        dyn_anytype val;
          dpGet(dpe, val);
          if (mappingHasKey(CMSfwAlertSystemUtil_notifications, dpe)) {

              dynAppend(CMSfwAlertSystemUtil_notifications[dpe] , val);
           } else {
             CMSfwAlertSystemUtil_notifications[dpe] = val;             
           }
      }
    }
}
/*
 This is not done by default in the postInstall because maybe you don't want. Use this function in your postInstall
 */
bool CMSfwAlertSystemUtil_loadTargetedConfigurations() {
  dyn_string exceptionInfo; 
  mappingClear(CMSfwAlertSystemUtil_notifications);
  
  fwInstallationUtils_loadConfigurations("CMSfwAlertSystem",exceptionInfo, "CMSfwAlertSystemUtil_postConfigLoaded");
  
  DebugN("Updating notifications for " + mappinglen(CMSfwAlertSystemUtil_notifications) + " dpes");
  for (int i=1; i<= mappinglen(CMSfwAlertSystemUtil_notifications) ; i++) {
  //    DebugN("Post configuration: resetting " + mappingGetKey(CMSfwAlertSystemUtil_notifications,i));
      dpSet(mappingGetKey(CMSfwAlertSystemUtil_notifications,i), mappingGetValue(CMSfwAlertSystemUtil_notifications, i));
  }
  
   

  if (dynlen(exceptionInfo)>0) {
    DebugN(exceptionInfo);
    return false;
  }
  CMSfwAlertSystemUtil_fixLoadedConfigurations();
  return true;
  
}

bool CMSfwAlertSystemUtil_loadFromConfigurationDb(string configurationName = "", string setupName = "") {
  if (strlen(configurationName) == 0) configurationName = strrtrim(CMSfwAlertSystemUtil_getCurrentSystemName(), ":");
  string confNameOrig = configurationName;
  configurationName  = "CMSfwAlertSystem_" + configurationName;
  dyn_string exceptionInfo;  
  if ((myManType() != UI_MAN) || (CMSfwAlertSystemUtil_getCurrentSystemName() == getSystemName())) { 
     fwConfigurationDB_checkInit(exceptionInfo);
     if (dynlen(exceptionInfo)>0) {
       if (myManType() == UI_MAN) {
         fwExceptionHandling_display(exceptionInfo);
       } else {
          DebugTN(exceptionInfo); 
       }
        return false;
     }
 
     dyn_string aConfNames,aConfDesc;
     dyn_int aiConfIds;
  
     fwConfigurationDB_getDeviceConfigurations( fwDevice_HARDWARE,
                                              aConfNames,
                                              aConfDesc,
                                              aiConfIds,
                                              exceptionInfo);
    if (dynlen(exceptionInfo)>0) {
       if (myManType() == UI_MAN) {
         fwExceptionHandling_display(exceptionInfo);
       } else {
          DebugTN(exceptionInfo); 
       }
         return false;
     }
     if (! dynContains(aConfNames, configurationName) ) {
         CMSfwAlertSystemUtil_showMsg("Configuration " + configurationName + " not saved to the conf. db");
         return false;
     }
   }
  
  if (myManType() ==  UI_MAN) {
    
    CMSfwAlertSystemUtil_request("loadFromConfigurationDb", makeDynString(confNameOrig, setupName),1200); return true;
  }   
  CMSfwAlertSystemUtil_deleteAllDps("*");
 
  bool res =  fwInstallationUtils_loadConfigurationDbHardware(configurationName, exceptionInfo, setupName);
 

  if (res)  {
    CMSfwAlertSystemUtil_fixLoadedConfigurations();
    CMSfwAlertSystemUtil_registerConfigurationName(confNameOrig);
  }
  return res;
}


void CMSfwAlertSystemUtil_fixLoadedConfigurations() {
  CMSfwAlertSystemUtil_fixSystemNames();
  CMSfwAlertSystemUtil_applyNotificationSumAlerts();
  CMSfwAlertSystemUtil_fixAlertThresholdsForNotifications();
  CMSfwAlertSystemUtil_registerChange("loadedFromDb");
 
}




void CMSfwAlertSystemUtil_showMsg(string msg) {
  if (myManType() != UI_MAN) {
      DebugTN("CMSfwAlertSystemUtil: " + msg);
   } else {
     bool ok; dyn_string exc;
     fwGeneral_openMessagePanel(msg,ok, exc,"",true); 
   }
}

void CMSfwAlertSystemUtil_registerChange(string element = "modified") {
  if (! dpExists(CMSfwAlertSystemUtil_getCurrentSystemName() + CMSfwAlertSystemUtil_CONSISTENCYDP) ) {
     CMSfwAlertSystemUtil_showMsg("Please start the CMSfwAlertSystem script on system " + CMSfwAlertSystemUtil_getCurrentSystemName());
     return;
  }
  time t = getCurrentTime();
  if (element == "loadedFromDb") {
    dpSet(CMSfwAlertSystemUtil_getCurrentSystemName() + CMSfwAlertSystemUtil_CONSISTENCYDP + "." + element, t,
          CMSfwAlertSystemUtil_getCurrentSystemName() + CMSfwAlertSystemUtil_CONSISTENCYDP + ".modified", t   );
 } else {
    dpSet(CMSfwAlertSystemUtil_getCurrentSystemName() + CMSfwAlertSystemUtil_CONSISTENCYDP + "." + element, t);
  }
}

void CMSfwAlertSystemUtil_registerConfigurationName(string confName) {
    dpSet(CMSfwAlertSystemUtil_getCurrentSystemName() + CMSfwAlertSystemUtil_CONSISTENCYDP + ".configurationName" , confName);
}

void CMSfwAlertSystemUtil_fixAlertThresholdsForNotifications() {
    dyn_string dps = dpNames("*","CMSfwAlertSystemSumAlerts");
   // DebugN("Fixing alert thresholds for " + dynlen(dps) + " notifications");
    dyn_string dpeList; string alertClass,dpname;
    bool configExists, isActive;
    int position, removed, alertType;
    string alertPanel, alertHelp;
    dyn_float alertLimits;
    dyn_string alertTexts, alertClasses,  alertPanelParameters, exceptionInfo;

    string dpe;
    for (int i=1; i<= dynlen(dps); i++) {
       dpe = dps[i] + ".Notification";   
       
        fwAlertConfig_get(dpe, configExists, alertType, alertTexts, alertLimits, alertClasses, dpeList,
                    alertPanel, alertPanelParameters, alertHelp, isActive, exceptionInfo);
  

        if (dynlen(exceptionInfo)>0) {
            DebugN(exceptionInfo);
            dynClear(exceptionInfo);
            continue;
        }
       if(alertType != DPCONFIG_SUM_ALERT)
        {
          DebugN( dpe+" does not have a summary alert.");
          continue;
         }
       if ((dynlen(alertLimits) == 0) || ((dynlen(alertLimits) == 1) && (alertLimits[1] != CMSfwAlertSystem_SUMALERT_THRESHOLD))) {
           DebugN("Fixing alert threshold for " + dpe);
           if (isActive) fwAlertConfig_deactivate(dpe, exceptionInfo);
           fwAlertConfig_set(dpe, alertType, alertTexts, makeDynInt(CMSfwAlertSystem_SUMALERT_THRESHOLD), alertClasses, dpeList,
                    alertPanel, alertPanelParameters, alertHelp, exceptionInfo, true, true,"", false);
           if (isActive) fwAlertConfig_activate(dpe, exceptionInfo);          
       }
       
    }
}
