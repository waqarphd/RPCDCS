// $License: NOLICENSE

#uses "CheckWithBobby/CtrlLDAP.dll"
#uses "email.ctl"

/** to encrypt this library into a .ctc file, execute
PVSStoolEncryptCtrl ./CMSfwAlertSystemGeneral.ctl
*/

const string CMSfwALERTSYSTEM_USERTYPE = "CMSfwAlertSystemUsers";
const string CMSfwALERTSYSTEM_GROUPTYPE = "CMSfwAlertSystemGroups";

string CMSfwAlertSystemGeneral_SmsSystem = "-";

string CMSfwAlertSystemGeneral_getSmsSystem() {
  if (CMSfwAlertSystemGeneral_SmsSystem=="-") {
      dpGet("CMSAlertSystem/Config.sms_server.system", CMSfwAlertSystemGeneral_SmsSystem);      
  }
  return CMSfwAlertSystemGeneral_SmsSystem;
}

//Info Returns:
//1-Alias
//2-Mobile Phone Number
//3-Fix Phone Number
//4-Email Address
CMSfwAlertSystemGeneral_getContactInfo (string userName, dyn_string &info, bool update = true){
  string hostName, userDN, password;
  dyn_dyn_string attributeNames, atributeValues;  
  hostName = "cmsorainfra02";
  //hostName ="srv-c2c03-02";
  userDN = "cn="+userName+",cn=users,o=cms,dc=cern,dc=ch";
  dynAppend(attributeNames,makeDynString("cn","mobile","telephonenumber","mail"));
  //ldapCompare(hostName,userDN,password);   
  string mobile, mail, phonenumber; 
  //ldapSearch(hostName,userDN,attributeNames, atributeValues, "");
  ldapSearch(hostName,userDN,attributeNames, atributeValues,"","","(objectClass=*)",0,"SIMPLE");  
  //DebugN(atributeValues, dynlen(atributeValues));
  if(dynlen(atributeValues)==0) {
    dynClear(info);
    return;    
  }
  dynClear(info);
  for (int i=1; i<= 4; i++) info[i] = "";

  for (int i=1 ; i<=dynlen(attributeNames) ; i++){
    for (int j=1 ; j<=dynlen(attributeNames[i]) ; j++){
      if (attributeNames[i][j] == "cn"){
        //pvssRole.appendItem(atributeValue[i][j]);
	//dynAppend (dsRole,attribValues[i][j] );
	     info[1] = atributeValues[i][j];
        
      }
      else if (attributeNames[i][j] == "mobile"){
        //pvssPassword.appendItem(attribValues[i][j]);
        //dynAppend (dsRolePassword,attribValues[i][j]);        	
         mobile = atributeValues[i][j];
         info[2] = mobile;
      }
      else if (attributeNames[i][j] == "telephonenumber"){
        info[3] = atributeValues[i][j];
      }
      else if (attributeNames[i][j] == "mail"){
        mail = atributeValues[i][j];
        info[4] = mail;
      }
    }	
  }
  if(update)
    CMSfwAlertSystemGeneral_updateUserInfo ("CMSAlertSystem/Users/" + userName,userName, mobile, mail);
  //DebugN(info);
}

CMSfwAlertSystemGeneral_sendEmail (string emailAddress, string subject, string message){
  string    host        = "cernmx.cern.ch";
  string    serverName 	= "cern.ch";
  string    sender      = "rgreino@cern.ch";
  int ret;
  dyn_string email = makeDynString (emailAddress, sender, subject,message);
  DebugN("Sending email to: " +emailAddress);
  DebugN("email subject: " +subject);
  DebugN("email text: " +message);
  emSendMail (host, serverName, email, ret); 
}
    


CMSfwAlertSystemGeneral_updateUserInfo (string userDP, string name, string GSMNumber, string MailAddress){
  dyn_string exceptions;
  string dpName;
  
  if(name != "")
    dpSet (userDP + ".Name", name );	
  else{
   fwDevice_getName(userDp, dpName,exceptions);
   //DebugN("Name: " + dpName + " " + userDp);
   dpSet (userDP + ".Name", dpName );	    
  }
  if(GSMNumber !="")
    dpSet (userDP + ".GSMNumber", GSMNumber );
  if(MailAddress != "")
    dpSet (userDP + ".MailAddress", MailAddress );
}

CMSfwAlertSystemGeneral_sendSMS (string number, string Message, bool bGateway = false){
  DebugN(number + Message);

  int ret ;
  bool bGatewayInput = bGateway;
  // if dcs_19 is not connected use the gateway
  if (! bGateway) {
    if(!dpExists(CMSfwAlertSystemGeneral_getSmsSystem() + "SMSRequest.Send.Message")){      
      bGateway=true;
    }
  }
  
  // if not using the gateway, try to use the 19 (modem)
  if (! bGateway) {
    ret = dpSet(CMSfwAlertSystemGeneral_getSmsSystem() + "SMSRequest.Send.Message",   Message,
                CMSfwAlertSystemGeneral_getSmsSystem() + "SMSRequest.Send.Number",    number );  
  }
  if(ret==-1 || bGateway){    
    //Could not write the datapoint. Maybe dcs_19 is not running, try to send sms via email-gsm gateway 
    //if(strlen(number)==6){
       number = "004176487" + substr(number,2); 
    //}
    if (! bGatewayInput)
      DebugN("Not able to use SMS mechanism, trying to use sms-email gateway...");
    else 
      DebugN("Using sms-email gateway for SMSMAIL notification...");
    DebugN("Message: " + Message + " for number: " + number);
    CMSfwAlertSystemGeneral_sendEmail(number + "@mail2sms.cern.ch","DCS",Message);
  }
}

/*
string 	CMSfw_MESSAGESACK = "ALERTS ACKNOWLEDGE",
	CMSfw_MESSAGESNOTACK = "SMS WAITING FOR ACKNOWLEDGE";
				
string 	CMSfw_SMSSENT = "SMS SENT",
	CMSfw_SMSNOTSENT = "SMS NOT SENT";

string CERNprefix = "4176487";



CMSfwSMS_getAlertReport (string dpName, string &sReport){
	//dyn_atime datAlerts;
	//dpGet(dpName+ ".SMS-notification:_alert_hdl.._summed_alerts", datAlerts);
	//DebugN(datAlerts);
	
	dyn_atime dat_summed_alerts; // List of pending alerts (DPE + Alert time) 
	int i;	 
	
	sReport = "DCS Alert:";
	dpGet(dpName+".SMS-notification:_alert_hdl.._summed_alerts",dat_summed_alerts);	 
	
	if (dynlen(  dat_summed_alerts) == 0)	 
		;//DebugN("No pending alert");	 
	else	 
		for (i=1; i<=dynlen(dat_summed_alerts); i++){	 	
			string sID = getAIdentifier(dat_summed_alerts[i]);
			//DebugN("DPE:"+getAIdentifier(dat_summed_alerts[i])," AlertID:"+getACount(dat_summed_alerts[i]));
			sReport = sReport + sID + "||"; 
		}
}

CMSfwSMS_getContactInfo (string userName, dyn_string &info){
 string hostName, userDN, password;
 dyn_dyn_string attributeNames, atributeValues;  
 hostName = "oracms2.cern.ch";
 userDN = "cn="+userName+",cn=users,o=cms,dc=cern,dc=ch";
 dynAppend(attributeNames,makeDynString("cn","mobile","telephonenumber","mail"));
	//   ldapCompare(hostName,userDN,password);    
 ldapSearch(hostName,userDN,attributeNames, atributeValues, "");
 DebugN(atributeValues);

	for (int i=1 ; i<=dynlen(attributeNames) ; i++){
		for (int j=1 ; j<=dynlen(attributeNames[i]) ; j++){
	   		if (attributeNames[i][j] == "cn"){
		     		//pvssRole.appendItem(atributeValue[i][j]);
		   		//dynAppend (dsRole,attribValues[i][j] );
				dynInsertAt (info,atributeValues[i][j],1);
		   	}
	   	 	else if (attributeNames[i][j] == "mobile"){
		     		//pvssPassword.appendItem(attribValues[i][j]);
		     		//dynAppend (dsRolePassword,attribValues[i][j]);
				dynInsertAt (info,atributeValues[i][j],2);
		   	}
	   	 	else if (attributeNames[i][j] == "telephonenumber"){
		     		dynInsertAt (info,atributeValues[i][j],3);
		    	}
			else if (attributeNames[i][j] == "mail"){
		     		dynInsertAt (info,atributeValues[i][j],4);
		    	}
	   	}	
	}

}

CMSfwSMS_updateContactInfo (string userDP, dyn_string dsUserInfor){
	dpSet (userDP + ".GSM_number", dsUserInfor[2] );
	dpSet (userDP + ".Mail_Address", dsUserInfor[4] );
}
  
 

//////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////// LDAP ///////////////////////////////////////////////////////////////////
CMSfwSMS_getPhoneNumber (string dpName, string &sNumber){
	dpGet (dpName + ".GSM_number",sNumber);				
	//sNumber = CERNprefix  + sNumber;
	strreplace (sNumber, "+", "");
}

CMSfwSMS_getUserName (string sNumber,string &sUserName, string &dp){
	dyn_string dsClients = dpNames ("*", "Notification_Clients");	
	string sAuxNumber;
	for(int i=1 ; i <= dynlen(dsClients); i++){
		dpGet (dsClients[i] + ".GSM_number", sAuxNumber);
		if(( sAuxNumber)== "+"+sNumber){
			dpGet(dsClients[i] + ".Name", sUserName);
			dp = dsClients[i];
		}		
	}
	//ldapSearch(hostName,userDN,attributeNames, attributeValues,"mobile=+41764872366");
}
//////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////// ////////////////////////////////////////////////////////////////////////

CMSfwSMS_sendSMS (string sNumber, string text){
	string 	sError ;
	int 		iError;	
	
	sendSMS (sNumber,text, iError, sError, "_SMS_1" );
	DebugN("send SMS: " + sNumber,text, iError, sError, "_SMS_1"); 
}*/
