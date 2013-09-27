 
//CMSfwAlertSystemGuardian
#uses "CMSfwAlertSystem/CMSfwAlertSystemGeneral.ctc"
#uses "CMSfwAlertSystem/CMSfwAlertSystemUtil.ctl"
#uses "email.ctl"

// cache
dyn_string CMSfwAlertSystemGuardian_users;
dyn_string CMSfwAlertSystemGuardian_emails;
dyn_string CMSfwAlertSystemGuardian_gsm;


main(){
  //The following dpQueryConnect allows for notifications and users to be created while the script runs
    
  int rc = dpQueryConnectSingle("checkAlerts", TRUE, "AlertSender", 
				//"SELECT '_original.._value' ' FROM '*.Notification' WHERE _DPT = \"CMSfwAlertSystemSumAlerts\""); 
				"SELECT ALERT SINGLE '_alert_hdl.._value' FROM  '*.Notification' WHERE _DPT = \"CMSfwAlertSystemSumAlerts\"",
				1000);

  if (! dpExists(CMSfwAlertSystemUtil_CLIENTSERVERDP) ) dpCreate(CMSfwAlertSystemUtil_CLIENTSERVERDP,CMSfwAlertSystemUtil_CLIENTSERVERDPTYPE);

  if (! dpExists(CMSfwAlertSystemUtil_CONSISTENCYDP) ) dpCreate(CMSfwAlertSystemUtil_CONSISTENCYDP,CMSfwAlertSystemUtil_CONSISTENCYDPTYPE);
  
  dpConnect("CMSfwAlertSystemUtil_processRequest",false,CMSfwAlertSystemUtil_CLIENTSERVERDP + ".request");

  

  
}

synchronized checkAlerts (string ident, dyn_dyn_anytype val) {       
  string dp;
  int iAlert;
  for (int i=1; i <= dynlen(val);i++){
    dp = dpSubStr( val[i][1], DPSUB_SYS_DP);
    if(!dpExists(dp))
      continue;
    //DebugN("Changed " + dp, val[i][1]);
    dpGet (dp + ".Notification:_alert_hdl.._act_state", iAlert);       
    _CMSfwAlertSystem_processAlert(dp, iAlert);   
  }  
}

void _CMSfwAlertSystem_processAlert (string dp, int iAlert){  
  //DebugN("Notification for " + dp + " " + iAlert);
  
  dyn_string notifications,
    notificationTypes;
  dyn_int    notificationPriority;
  dyn_bool   notificationSent;
  string groupName;
  dyn_string exc;
  string userDp;
  bool userDpExists;
  dyn_string dsMembers;
  

  string name, alertText;
  dyn_atime atAlerts;
  
  dpGet(dp+".Notification:_alert_hdl.._act_state_text",alertText,
        dp+".Notification:_alert_hdl.._summed_alerts",atAlerts);

  dyn_string dsGroups =   dpNames("*", "CMSfwAlertSystemGroups");  
         
  for (int i=1; i <= dynlen(dsGroups); i++){
    if(!dpExists(dsGroups[i]))
      continue;
    dpGet(dsGroups[i] + ".Notifications", notifications,
          dsGroups[i] + ".NotificationTypes", notificationTypes,
          dsGroups[i] + ".NotificationSent", notificationSent,
          dsGroups[i] + ".NotificationPriority", notificationPriority);
    
    //    DebugN(dsGroups[i], notifications);
    if(!dynContains(notifications, dp))
      continue;
    
    do{
      //DebugN(notifications,dynContains(notifications, dp));
      int pos= dynContains(notifications, dp);
      bool sent = notificationSent[pos];
      string type = notificationTypes[pos];
      if(iAlert!=0){
        //Remove alert, reset sender
     
        if(!sent){
          fwDevice_getName(dsGroups[i], groupName, exc);
          fwAccessControl_getGroupMembers(groupName, dsMembers, exc);
         

          for (int j=1; j<= dynlen(dsMembers); j++) {
            userDp = "CMSAlertSystem/Users/" + dsMembers[j];
            userDpExists = dpExists(userDp);
            name = dsMembers[j]; 
           
            //send notification
            if((type == "SMS" ) || (type == "SMSACK") || (type == "SMSMAIL")) {
              CMSfwAlertSystemGuardian_sendSMS (  userDp +".Name",  name,
						          dp+".Notification:_alert_hdl.._act_state_text", alertText,
        						   dp+".Notification:_alert_hdl.._summed_alerts" ,atAlerts,userDpExists,  (type == "SMSACK"), (type == "SMSMAIL"));
             
            }    
            else if(type == "EMAIL"){ 
              CMSfwAlertSystemGuardian_sendEmail (  userDp +".Name",  name,
      						    dp+".Notification:_alert_hdl.._act_state_text", alertText,
      						    dp+".Notification:_alert_hdl.._summed_alerts" ,atAlerts ,userDpExists);            
        	    }
          }
          //mark notification as sent
          notificationSent[pos]= TRUE;
        }
        //if it was already sent then nothing to do          
      }
      else{
        //Check if alert was already sent, if not, sent  
        if(sent){
          //reset sender notification
        	  notificationSent[pos]= FALSE;  
         }
         if (type == "SMSACK") {
            dpSet(dp + ".SMSAck", 0);    
         }            

      }         
      notifications[dynContains(notifications, dp)]= "Processed" + notifications[dynContains(notifications, dp)];
    }
    while(dynContains(notifications, dp));  
    dpSetWait(  dsGroups[i] + ".NotificationSent", notificationSent);                          
  }  
  
  dyn_string dsUsers = dpNames("*", "CMSfwAlertSystemUsers");  
  

  for (int i=1; i <= dynlen(dsUsers); i++){
    if(!dpExists(dsUsers[i]))
      continue;
    dpGet(dsUsers[i] + ".Notifications", notifications,
          dsUsers[i] + ".NotificationTypes", notificationTypes,
          dsUsers[i] + ".NotificationSent", notificationSent,
          dsUsers[i] + ".NotificationPriority", notificationPriority);
    //DebugN(dsUsers[i], notifications);
    if(!dynContains(notifications, dp))
      continue;
    
    do{
      //DebugN(notifications,dynContains(notifications, dp));

      int pos= dynContains(notifications, dp);
      bool sent = notificationSent[pos];
      string type = notificationTypes[pos];      
      
      if(iAlert!=0){
        //Remove alert, reset sender

        if(!sent){
          //send notification
          fwDevice_getName(dsUsers[i], name, exc);
          if ((type == "SMS") ||  (type == "SMSACK") || (type == "SMSMAIL")) {  
	    //            DebugN("Send SMS ", name , alertText, atAlerts);
            CMSfwAlertSystemGuardian_sendSMS (  dsUsers[i] +".Name",  name,
                                                dp+".Notification:_alert_hdl.._act_state_text", alertText,
                                                dp+".Notification:_alert_hdl.._summed_alerts" ,atAlerts,
                                                true,  (type == "SMSACK"), (type == "SMSMAIL"));
          }  
          else if(type == "EMAIL"){
	    //           DebugN("Send EMAIL ", name , alertText, atAlerts);
            CMSfwAlertSystemGuardian_sendEmail (  dsUsers[i] +".Name",  name,
						  dp+".Notification:_alert_hdl.._act_state_text", alertText,
						  dp+".Notification:_alert_hdl.._summed_alerts" ,atAlerts);            
          }
          //mark notification as sent
          notificationSent[pos]= TRUE;
        }
        //if it was already sent then nothing to do          
      }
      else{
        //Check if alert was already sent, if not, sent  
        if(sent){
          //reset sender notification
	        notificationSent[pos]= FALSE;                   
        }
        if (type == "SMSACK") {
            dpSet(dp + ".SMSAck", 0);    
         }            

      }         
      notifications[dynContains(notifications, dp)]= "Processed" + notifications[dynContains(notifications, dp)];
    }
    while(dynContains(notifications, dp));  
    dpSetWait(  dsUsers[i] + ".NotificationSent", notificationSent);                          
  }  
}


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////  email email email email email email email email email email email email   ///////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
CMSfwAlertSystemGuardian_sendEmail (string dp1,  string userName,
                                    string dp2,  string text,
                                    string dp3 , dyn_atime sumAlerts,
                                    bool userDpExists = true
                                    ){
  string emailMessage ="";
  
  string userDp ;
  string emailAddress; 
  if (userDpExists) {
    dpGet ( dpSubStr (dp1, DPSUB_SYS_DP) + ".MailAddress", emailAddress );  
  } else {   
    emailAddress = CMSfwAlertSystemGuardian_getEmailAddress(userName);
  }
  
  //DebugN(sumAlerts);
  for(int alertNum=1 ; alertNum <= dynlen (sumAlerts); alertNum++){
    string sAlertDp = dpSubStr(getAIdentifier(sumAlerts[alertNum]),DPSUB_SYS_DP_EL);
    string value;
    dpGet ( sAlertDp + ":_alert_hdl.._act_state_text", value);
    anytype val;
    string unit;
    unit = dpGetUnit(dpSubStr(getAIdentifier(sumAlerts[alertNum]),DPSUB_SYS_DP_EL));
    dpGet(dpSubStr(getAIdentifier(sumAlerts[alertNum]),DPSUB_SYS_DP_EL),val);
    emailMessage = emailMessage + dpGetDescription(sAlertDp) +" "+ value+ ": "+ val+ unit + "\n";
    //emailMessage = emailMessage + dpGetDescription(sAlertDp) +" "+ value+ ": "+ val+ unit +"--";
  }
  //if there is an alert  
  if(text == "TRUE"){
    //Check if the alert was sent already
    //send email alert 
    if (strlen(emailAddress) > 0) {
      CMSfwAlertSystemGeneral_sendEmail (emailAddress, "DCS Alert", emailMessage); 
      DebugN("EMAIL for " + userName + ": " +emailMessage);        
    } else {
        DebugN("Email address not found");
    }
  }         
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////sms sms sms sms sms sms sms sms sms sms sms sms sms sms sms sms sms sms sms ///////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
CMSfwAlertSystemGuardian_sendSMS (  string dp1,  string userName,
                                    string dp2,  string text,
                                    string dp3 , dyn_atime sumAlerts,
                                    bool userDpExists = true, bool addToAck = false, bool bGateway = false){ 
  string  emailMessage ="",
    userDp;
  bool lock; 
  string GSMNumber;
 
  //DebugN(userName, text, sumAlerts);
  if (userDpExists) {
    dpGet (dpSubStr (dp1, DPSUB_SYS_DP) + ".GSMNumber", GSMNumber );  
  } else {
    GSMNumber = CMSfwAlertSystemGuardian_getGsmNumber(userName);
  }
 
  if(GSMNumber ==""){
    //DebugN("No GSM phone number found. Sending email...");   
    CMSfwAlertSystemGuardian_sendEmail (  dp1, userName ,  dp2,  text,  dp3 , sumAlerts, userDpExists);
    return;
  }
 

  for(int alertNum=1 ; alertNum <= dynlen (sumAlerts); alertNum++){
    string sAlertDp = dpSubStr(getAIdentifier(sumAlerts[alertNum]),DPSUB_SYS_DP_EL);
    string value;
    dpGet ( sAlertDp + ":_alert_hdl.._act_state_text", value);
    if(strlen( emailMessage + dpGetDescription(sAlertDp) +":"+ value+ "||")>150){
      if(strlen( emailMessage + "more..")<=150)
        emailMessage = emailMessage + "more..";
      break;      
    }
    anytype val;
    string unit;
    //DebugN("Where is the val?? ");
    //DebugN(dpSubStr(getAIdentifier(sumAlerts[alertNum]),DPSUB_SYS_DP_EL));
    unit = dpGetUnit(dpSubStr(getAIdentifier(sumAlerts[alertNum]),DPSUB_SYS_DP_EL));
    dpGet(dpSubStr(getAIdentifier(sumAlerts[alertNum]),DPSUB_SYS_DP_EL),val);
    //DebugN(getType(val));
    //DebugN(BOOL_VAR);
    if(getType(val)!=BOOL_VAR){
      emailMessage = emailMessage + dpGetDescription(sAlertDp) +" "+ value+ ": "+ val+ unit +"--";
    }
    else{
      emailMessage = emailMessage + dpGetDescription(sAlertDp) +" "+ value +"--";
    }
  }

 
  //if there is an alert  
  if(text == "TRUE"){
    CMSfwAlertSystemGeneral_sendSMS (GSMNumber, substr(emailMessage,0,129), bGateway);      
    DebugN("===============> SMS for " + userName + ": " +substr(emailMessage,0,129));
  }  
  if (addToAck) {
    string notificationDp = dpSubStr(dp2, DPSUB_SYS_DP);
    dpSet(notificationDp + ".SMSAck", 1);    
    string ackreq =CMSfwAlertSystemGeneral_getSmsSystem() + "CMSfwSMS_AckList_req";
    if (dpExists(ackreq)) {
        dpSet(ackreq + ".numbers", makeDynString(GSMNumber),
              ackreq + ".alerts", makeDynString(notificationDp));
    } else {
      DebugTN(ackreq + " does not exist");      
    }
  }
}
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

CMSfwAlertSystemGuardian_sendACKSMS (string dp, string text ){
  //If email was send and not ackowledge
  
  //send email alert 
  
}

int CMSfwAlertSystemGuardian_searchUser(string userName) {
  int position = dynContains(CMSfwAlertSystemGuardian_users, userName);
  if (position == 0) {
    // ldap query    
  //  DebugTN("Getting info from LDAP");
    dyn_string info;
    CMSfwAlertSystemGeneral_getContactInfo(userName, info, false);
    if (dynlen(info) >= 4) {
      dynAppend(CMSfwAlertSystemGuardian_users, userName);
      dynAppend(CMSfwAlertSystemGuardian_emails, info[4]);
      dynAppend(CMSfwAlertSystemGuardian_gsm, info[2]);
      position = dynlen(CMSfwAlertSystemGuardian_users);    
    } else {
        DebugN("User info could not be found from LDAP for "+ userName, "info = ", info);
        return 0;
    }
  } else {
//    DebugTN("Getting info from cache at pos " + position);    
  }
  return position;
}
string CMSfwAlertSystemGuardian_getEmailAddress(string userName) {
  int pos = CMSfwAlertSystemGuardian_searchUser(userName);
  if (pos == 0) return "";
  return CMSfwAlertSystemGuardian_emails[pos];
}

string CMSfwAlertSystemGuardian_getGsmNumber(string userName) {
  int pos = CMSfwAlertSystemGuardian_searchUser(userName);
  if (pos == 0) return "";
  return CMSfwAlertSystemGuardian_gsm[pos];  
}

