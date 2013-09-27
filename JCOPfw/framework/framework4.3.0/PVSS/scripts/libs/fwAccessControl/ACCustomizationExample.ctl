#uses "CtrlLDAP"

void fwAccessControl_initializeHook()
{
    dyn_mixed acConfiguration;
    dyn_string exceptionInfo;
    fwAccessControl_getConfiguration(acConfiguration,exceptionInfo);
    if (dynlen(exceptionInfo)) {DebugN(exceptionInfo);return;};
    acConfiguration[fwAccessControl_CONFIG_Authorization_Configuration] = makeDynString("ExampleAuthorizationFunction");
//    acConfiguration[fwAccessControl_CONFIG_Authentication_OsAutoLogin]=TRUE;

    fwAccessControl_setConfiguration(acConfiguration,exceptionInfo);
    if (dynlen(exceptionInfo)) {DebugN(exceptionInfo);return;};

    // permit external authentication devices with cookie "AuthDeviceTest"
    // note that the credentials given below will only allow that device
    // logs in user "guest" or log out.
    // note that by specifying the hostName we may tell which UIs 
    // are authenticated. Here, we show how to allow the device
    // to be used on the local host. You might however put your own device names
    // to restrict this!
    
    // firstly, check who we are (i.e. extract our hostName)
    string hostName, ip;
    int manId;
    time startTime;
    fwAccessControl_getMyDisplay(hostName, ip, manId, startTime, exceptionInfo);
    if (dynlen(exceptionInfo)) {
	DebugN("Error while setting up auth devices",exceptionInfo[2]);
        return;
   }
   
    string deviceCookie="AuthDeviceTest";
    string authPassword="ITCO_TEST";
    _fwAccessControl_extAuth_permitDevice(hostName, deviceCookie, authPassword);

}


/** Example of custom authorization function:

the function checks the workstation (UI Manager's) IP address a
and denies "Administer" privilege if the machine is not on a same
sub-net that the event manager.
For other privileges, it falls back to default authorization function.

*/
void ExampleAuthorizationFunction(string userName, string domainName, string privilegeName,
                                        bool &granted, dyn_string &exceptionInfo)
{
    granted=false;


    // list of hosts from which we permit "Administer" privilege
    // these are the hosts on the same subnet that our eventManager...
    // i.e. we disable "Administer" from scattered UIs, that are not
    // on the same subnet (well, in fact we only look at the three
    // first bytes of the IP, not actual "real" subnet...
    
    string eventManagerHostIP=getHostByName(eventHost());
    string subNet=strrtrim(eventManagerHostIP,"01234567890")+"*";
    // in effect, we get something such as "10.0.1.*"

    // find the workstation (UI Manager) IP number
    string myHostName, myIP;
    int myManId;
    time myStartTime;
    fwAccessControl_getMyDisplay(myHostName, myIP, myManId, myStartTime, exceptionInfo);
    if (dynlen(exceptionInfo)) return;


    // deny "Expert" privilege for anyone outside control room:
    if (privilegeName=="Administer") {
        if (!patternMatch(subNet,myIP)) {
    	    DebugN(" 'Administer' privilege rejected for remote machines.");
            return;// reject
        }
    }

    // otherwise, follow standard privilege checking
    fwAccessControl_checkUserPrivilege_AuthFunc(userName, domainName, privilegeName, granted, exceptionInfo);
}


/** Example authentication routine

This is an example of customization of the authentication function. The library that
contains the function needs to be loaded into PVSS, then its name should be specified
in the Access Control Setup panel, or using the "hook" function above.

The function needs to return TRUE if a user authenticated succesfully, and FALSE - if not.
In case of an error, the exceptionInfo should be populated with diagnostic information.
In this case, the Access Control will automatically fall-back to local authentication,
with a notable exception though:
if the exceptionInfo[1]=="INFO" or "INFORMATION", the contents of the exceptionInfo will
be treated as the explanation of the reason for which the authentication failed; for instance,
telling "no such user", "wrong password", "not allowed from this console", etc... In this case
the exceptionInfo does not signal the error of the authentication, but provides additional 
information.

*/
bool _fwAccessControl_exampleAuthRoutine(string userName, string password, dyn_string &exceptionInfo)
synchronized (_fwAccessControl_mutex)
{

    // make sure we have LDAP available...
    if (!isFunctionDefined("ldapCheckAuth")) {
	fwAccessControl_raiseException(exceptionInfo, "ERROR", "LDAP authentication not available: no LDAP library");
        return FALSE;
    }

    int userId=getUserId(userName);
    if (userId==DEFAULT_USERID) {
	//no such user! Reject
	return FALSE;
    }
    if (userId==0) {
        // this is root! perform local login
        return _fwAccessControl_PVSSAuth(userName, password, exceptionInfo);
    }

    // fix #35897: empty password in LDAP should always be rejected
    if (password=="") {
	return FALSE;
    }

    // additional constraint: local authentication (ie. using generic
    // accounts, should only be allowed from a set of machines
    // with specific names

    string hostName, ip;
    int manId;
    time startTime;

    fwAccessControl_getMyDisplay   (hostName, ip,manId, startTime, exceptionInfo);
    if (dynlen(exceptionInfo)) return FALSE;

    if (patternMatch("CONSOLE-*-11.CERN.CH",strtoupper(hostName))) {
	bool localAccount=fwAccessControl_isUserAccountLocal(userName, exceptionInfo);
	if (dynlen(exceptionInfo)) return FALSE;
	if (localAccount) return _fwAccessControl_PVSSAuth(userName, password, exceptionInfo);
	// otherwise we will continue with LDAP auth below...
    } else {
	fwAccessControl_raiseException(exceptionInfo,"INFO","Not allowed to login from this machine");
	return FALSE;
    }


    // check authentication against CERN Active Directory
    string ldapAuthMethod="DIGEST-MD5"; // may also be "SIMPLE";
    string ldapServer="cerndc.cern.ch";
    int timeout=10;

    int rc=ldapCheckAuth(ldapAuthMethod,ldapServer, userName,password,timeout);

    if (rc) {
	// find out what was wrong...
	dyn_errClass err=getLastError();
	if (rc==49) return FALSE; // means: invalid credentials - deny access...

        string errTxt="";
        switch(rc) {
	    case 51: errTxt="LDAP Server is too busy (51)"; break;
            case 52: errTxt="LDAP Server not available (52)"; break;
    	    case 81: errTxt="LDAP Server not available (81)"; break;
    	    case  3: errTxt="LDAP Server timeout (3)"; break;
    	    default: {
    		// we need to parse it from exceptionInfo...
    		string sErr=err;
            	dyn_string dErr;
                bool generic=TRUE;
                if (_UNIX) {
            	    dErr=strsplit(sErr,"\n");
            	    if (dynlen(dErr)>=6) {
                	errTxt=dErr[6];
                        generic=FALSE;
                    }
                } else {
                    dErr=strsplit(sErr,",");
                    if (dynlen(dErr)>=8) {
            		errTxt=dErr[8];
                        generic=FALSE;
		    }
		}

            	if (generic) {
            	    errTxt="LDAP Authentication failed: (see the log)";
            	    DebugN("LDAP Authentication failed",sErr);
                }
    	    };
    	    break;
	} // end of case

	fwAccessControl_raiseException(exceptionInfo,"ERROR",errTxt);
	return FALSE;
    }
    
    // access granted!
    // cache the credentials
    dyn_string d_name, d_password;
    dpGet(g_fwAccessControl_UsersDP+".UserName:_original.._value",d_name,
        g_fwAccessControl_UsersDP+".Password:_original.._value",d_password);
    int idx=dynContains(d_name,userName);

    if (idx) {
        string newPasswd=crypt(password);
        if (newPasswd!=d_password[idx]) {
        
            d_password[idx]=crypt(password);
            int rc=dpSetWait(g_fwAccessControl_UsersDP+".UserName:_original.._value",d_name,
                    g_fwAccessControl_UsersDP+".Password:_original.._value",d_password);
                    
            if ( rc ) {
                fwAccessControl_raiseException(exceptionInfo, "ERROR", "Cannot cache the password");
                return FALSE;
            }
            
            if (!_fwAccessControl_integratedMode()) {
                _fwAccessControl_checkDoServerSync(exceptionInfo);
            }
        }
    }


    return TRUE;
}