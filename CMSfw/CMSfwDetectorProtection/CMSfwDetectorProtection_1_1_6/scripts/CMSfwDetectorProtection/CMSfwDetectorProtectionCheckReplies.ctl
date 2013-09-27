#uses "CMSfwDetectorProtection/CMSfwDetectorProtection.ctl"
dyn_string replydps;

void main() {
  
  CMSfwDetectorProtection_debug2("Starting check replies");
  dyn_string exc;
  if (! dpExists(  CMSfwDetectorProtection_managerDpReplies) ) {
    CMSfwDetectorProtection_debug2("Creating " + CMSfwDetectorProtection_managerDpReplies);
    dpCreate(CMSfwDetectorProtection_managerDpReplies, CMSfwDetectorProtection_managerType); 
  }
  
  dpSet(CMSfwDetectorProtection_managerDpReplies + ".startTime", getCurrentTime());
  

  dpConnect("CMSfwDetectorProtection_restart",false,CMSfwDetectorProtection_managerDpReplies + ".triggerRestart");

    replydps = dpNames("*","CMSfwDetectorProtectionReply");
    dynSortAsc(replydps);
    CMSfwDetectorProtection_debug2(dynlen(replydps) + " data points found");
    string inputdp;
    for (int i=dynlen(replydps); i>0; i--) {
      inputdp = CMSfwDetectorProtection_convertToInputDp(replydps[i]);
      if ( ! dpExists(inputdp) ) {
          DebugTN("Warning " + inputdp + " does not exist");
          CMSfwDetectorProtection_debug(inputdp + " DP NOT FOUND ", 1, CMSfwDetectorProtection_managerDpReplies);
          dynRemove(replydps, i);
      }  
    }

    time t;    
    for (int i=1; i<= dynlen(replydps); i++) {
      dpGet(replydps[i] + ".ok:_original.._stime",t);
      if (t == 0) dpSet(replydps[i] + ".ok", false); // to avoid uninitialized  dpes
      
        dpConnect("CMSfwDetectorProtection_updateReplyDp" ,
                  replydps[i] + ".updated"
                  );
    }  
    
    CMSfwDetectorProtection_debug4("Starting alive beat loop");
    startThread("CMSfwDetectorProtection_aliveLoop", CMSfwDetectorProtection_managerDpReplies);
    startThread("CMSfwDetectorProtection_checkConsistencyReplyDps");
    startThread("CMSfwDetectorProtection_checkProblems");
}

void CMSfwDetectorProtection_updateReplyDp(string replydp, bool updated) {
     replydp = dpSubStr(replydp, DPSUB_SYS_DP);
     bool ok = CMSfwDetectorProtection_checkReply(replydp, makeDynString());
     bool oldOk;
     dpGet(replydp + ".ok", oldOk);
     if (ok != oldOk) dpSet(replydp + ".ok", ok);

}

void CMSfwDetectorProtection_checkConsistencyReplyDps() {
  bool inconsistent;
  dyn_string currentReplydps;
  while (true) {
      delay(600);
      currentReplydps= dpNames("*","CMSfwDetectorProtectionReply");
      inconsistent = false;
      if (dynlen(currentReplydps) != dynlen(replydps)) {
          CMSfwDetectorProtection_debug2("Inconsistency found in the number of reply dps");
          inconsistent = true;
       } else {
         dynSortAsc(currentReplydps);
         for (int i=1; i<= dynlen(replydps); i++) {
           if (replydps[i] != currentReplydps[i]) {
              CMSfwDetectorProtection_debug2("Inconsistency found in the names of the reply dps");
              inconsistent = true;
              break;                         
           }
         }            
      }
       if (inconsistent) {
           delay(2);
           exit(0); // Restarting
       }
  }  
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
  for (int i=1; i<= dynlen(replydps); i++) {
    
    fwAlertConfig_setAnalog(replydps[i] + ".consistency.n_problems", makeDynString("", "Problems found on Detector Protection Reply"), 
                            makeDynFloat(1),                            
                            makeDynString("", alertClass),
                           "",makeDynString(),"", exc);
  
  
      fwAlertConfig_activate(replydps[i] +  ".consistency.n_problems", exc);
   }

  if (dynlen(exc) >0) DebugTN(exc);
  
  while (true) {
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
       
     if (problems_found) delay(60); else delay(900);
  }
}
