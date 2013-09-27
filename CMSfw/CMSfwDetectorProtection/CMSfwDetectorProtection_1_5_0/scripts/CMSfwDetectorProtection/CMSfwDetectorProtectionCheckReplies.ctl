#uses "CMSfwDetectorProtection/CMSfwDetectorProtection.ctl"


void main() {
  
  CMSfwDetectorProtection_debug2("Starting check replies");

  
  dyn_string exc;
  if (myReduHostNum() ==2) {
    CMSfwDetectorProtection_managerDpReplies= CMSfwDetectorProtection_managerDpReplies + "_2";
  }
  if (! dpExists(  CMSfwDetectorProtection_managerDpReplies) ) {
    CMSfwDetectorProtection_debug2("Creating " + CMSfwDetectorProtection_managerDpReplies);
    if  ( ! fwInstallationRedu_isPassive()) {
      dpCreate(CMSfwDetectorProtection_managerDpReplies, CMSfwDetectorProtection_managerType); 
    }
  }
  if (isRedundant() && (myReduHostNum() == 1) && ( ! fwInstallationRedu_isPassive())) {
    if (! dpExists (CMSfwDetectorProtection_managerDpReplies + "_2") ) {
      dpCreate(CMSfwDetectorProtection_managerDpReplies + "_2", CMSfwDetectorProtection_managerType); 
    }
  }
  
  dpSet(CMSfwDetectorProtection_managerDpReplies + ".startTime", getCurrentTime());
  

  dpConnect("CMSfwDetectorProtection_restart",false,CMSfwDetectorProtection_managerDpReplies + ".triggerRestart");

  // This dpQuery dinamically connects to any new dp of type CMSfwDetectorProtectionReply 
  dpQueryConnectSingle("CMSfwDetectorProtection_checkReplyDp",true, "checkReply", "SELECT ':_original.._value' FROM 'CMSfwDetectorProtection/Reply/*.updated' WHERE _DPT = \"CMSfwDetectorProtectionReply\" ");
  CMSfwDetectorProtection_debug4("Starting alive beat loop");
   startThread("CMSfwDetectorProtection_aliveLoop", CMSfwDetectorProtection_managerDpReplies);
   startThread("CMSfwDetectorProtection_checkProblems");
}


CMSfwDetectorProtection_checkReplyDp(string identif, dyn_dyn_anytype res) {
    string dpe,inputdp;
     for (int i=2; i<= dynlen(res); i++) {
       dpe = res[i][1];

        inputdp = CMSfwDetectorProtection_convertToInputDp(dpe);
        if (! dpExists(inputdp)) {
          DebugTN("CMSfwDetectorProtectionCheckReply: Warning " + inputdp + " does not exist");
          continue;
        }
       CMSfwDetectorProtection_updateReplyDp(dpe, res[i][2]);

    }
}


void CMSfwDetectorProtection_updateReplyDp(string replydp, time updated) {
 // DebugTN(replydp, updated);
     replydp = dpSubStr(replydp, DPSUB_SYS_DP);
     bool ok = CMSfwDetectorProtection_checkReply(replydp, makeDynString());
     bool oldOk; time t;
     dpGet(replydp + ".ok", oldOk,
          replydp +  ".ok:_original.._stime", t);
     if ( (ok != oldOk) || (t == 0) ) dpSet(replydp + ".ok", ok);

}

void CMSfwDetectorProtection_checkProblems() {
  delay(5);

  dyn_string problems, oldProblems;
  time t;
  dyn_string els;
  dyn_string exc;
  string sysNum, replydp;
  bool problems_found;
  string remoteSys;

  
  string alertClass = "_fwFatalNack_90.";
  dyn_string setupReplies = makeDynString();
  
  while (true) {
    dyn_string replydps = dpNames("CMSfwDetectorProtection/Reply/*", "CMSfwDetectorProtectionReply");
    
    if (! fwInstallationRedu_isPassive() ) {
        
        for (int i=1; i<= dynlen(replydps); i++) {
        if (! fwInstallationRedu_isPassive() ) {
          if (! dynContains(setupReplies, replydps[i])) {

            fwAlertConfig_setAnalog(replydps[i] + ".consistency.n_problems", makeDynString("", "Problems found on Detector Protection Reply"), 
                                makeDynFloat(1),                            
                                makeDynString("", alertClass),
                               "",makeDynString(),"", exc);
  
  
            fwAlertConfig_activate(replydps[i] +  ".consistency.n_problems", exc);
            dynAppend(setupReplies, replydps[i]);
          }
        }
       }

      if (dynlen(exc) >0) DebugTN(exc);
      
      
      
    problems_found = false;
    for (int i=1; i<= dynlen(replydps); i++) {
          dynClear(problems); 
          t = getCurrentTime();
          replydp = dpSubStr(replydp, DPSUB_SYS_DP);
          els = CMSfwDetectorProtection_getValidDpes(replydps[i]);        
          CMSfwDetectorProtection_debug4("Check " + replydps[i] + ": " + dynlen(els) + " valid replies found");
          for (int j=1; j<= dynlen(els); j++) {  
            dynClear(exc);
            remoteSys = CMSfwDetectorProtection_getSystemNameFromReplyDpe(els[j]);
            if (remoteSys == "") {
                sysNum = dpSubStr(els[j], DPSUB_SYS_DP_EL);
                replydp = dpSubStr(sysNum, DPSUB_SYS_DP);
                strreplace(sysNum, replydp + ".sys", "");
                dynAppend(problems, "Unable to resolve system number " + sysNum + " - probably is not connected");
             } else if (! CMSfwDetectorProtection_isSystemConnected(remoteSys) ) { 
                  dynAppend(problems, "System " + remoteSys + " is not connected but is in the list of systems to wait for");
            } else if (! CMSfwDetectorProtection_isManagerRunning(remoteSys, t) ) {
              dynAppend(problems, "Manager is not running on system " + remoteSys);
            } else if (! CMSfwDetectorProtection_isSubscribedFromSystem(remoteSys,replydps[i], exc)) {
              if (dynlen(exc) >0) {
                 dynAppend(problems, "Exception when checking if subscribed from " + remoteSys + ": " + exc);
              }
              dynAppend(problems, "System " + remoteSys + " does not subscribe to this condition but is in the list of systems to wait for");
            }                    
       }
       dpGet(   replydps[i] + ".consistency.problems", oldProblems);
       dpSet(replydps[i] + ".consistency.n_problems", dynlen(problems),
             replydps[i] + ".consistency.problems", problems);
       if (dynlen(problems)>0) {
           problems_found = true;
           
           if (oldProblems != problems) {
              CMSfwDetectorProtection_debug2("Problems found for " + replydps[i] + " " + problems);
              dyn_string logMsg;
              dpGet(replydps[i]  + ".log", logMsg);
              for (int j=1; j<= dynlen(problems); j++) {
                dynInsertAt(logMsg , ((string) getCurrentTime()) + " Problem found: " + problems[j],1);
              }
              dpSet(replydps[i] + ".log", logMsg);        
            }
          
        }
     }
  }
       
     if (problems_found) delay(60); else delay(600);
  }
}
