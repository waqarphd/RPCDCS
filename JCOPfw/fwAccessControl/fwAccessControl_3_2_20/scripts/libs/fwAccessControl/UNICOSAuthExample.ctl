// $License: NOLICENSE
#uses "CtrlLDAP"

bool _fwUNICOSAccessControl_authRoutine(string userName, string password, dyn_string &exceptionInfo)
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

    bool localAccount=fwAccessControl_isUserAccountLocal(userName, exceptionInfo);
    if (dynlen(exceptionInfo)) return FALSE;

    string hostName, ip;
    int manId;
    time startTime;

    fwAccessControl_getMyDisplay   (hostName, ip,manId, startTime, exceptionInfo);
    if (dynlen(exceptionInfo)) return FALSE;

    if (patternMatch("*108.CERN.CH",strtoupper(hostName))) {
	if (localAccount) return _fwAccessControl_PVSSAuth(userName, password, exceptionInfo);
	// otherwise we will continue with LDAP auth below...
    } else {
	fwAccessControl_raiseException(exceptionInfo,"INFO","Not allowed to login from this machine");
	return FALSE;
    }

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