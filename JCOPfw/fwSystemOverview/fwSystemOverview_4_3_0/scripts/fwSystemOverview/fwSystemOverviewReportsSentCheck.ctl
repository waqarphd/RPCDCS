#uses "fwSystemOverview/fwSystemOverviewReport.ctl"
    
main()
{
  dyn_string applicationsFailedEmail;
  dyn_string soTrees;
  fwSystemOverviewFsm_getTrees(soTrees);  
  for(int j = 1; j<= dynlen(soTrees); j++)
  {
    dyn_int types;
    dyn_string applications = fwCU_getChildren(types, soTrees[j]);
  
    for(int i = 1; i <= dynlen(applications); i++)
    {
      if (!fwSysOverviewReport_wasSentToday(applications[i]))
      {
        dynAppend(applicationsFailedEmail, applications[i]);
      }
    }
  }
  if (dynlen(applicationsFailedEmail) > 0)
  {
    string mailStr;
    fwGeneral_dynStringToString(applicationsFailedEmail,mailStr, ",");
    sendEmail(mailStr);
    for(int i = 1; i <= dynlen(applicationsFailedEmail); i++)
    {
      DebugTN("Generating now report for " + applicationsFailedEmail[i]);
      int result = fwSysOverviewReport_emailApplicationReport(applicationsFailedEmail[i]);
      if (result == 0)
      {
        fwSysOverviewReport_setSentDate(applicationsFailedEmail[i], getCurrentTime());
      }
      delay(60);
    }
  }
  else
    DebugTN("All reports have already been sent");
}

sendEmail(string emailText)
{
  string smtpServer = "cernmx.cern.ch";
  string name = "cs-ccr-moni.cern.ch";   
  string receiver = "petrova.lyuba@cern.ch;";//fernando.varela.rodriguez@cern.ch";
  string sender = "petrova.lyuba@cern.ch";
  string subject = "Some MOON reports not sent!";
  string messageBody = "The reports for " + emailText + " have not been sent today. Trying to send them again...";
  
  dyn_string email;
  email[1] = receiver;
  email[2] = sender;
  email[3] = subject;
  email[4] = messageBody;
  int ret;
  emSendMail(smtpServer, name, email, ret);

}
