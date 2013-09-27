#uses "fwSystemOverview/fwSystemOverviewReport.ctl"
#uses "fwSystemOverview/fwSystemOverviewLongTermReport.ctl"
#uses "fwSystemOverview/fwSystemOverviewFsm.ctl"

main()
{
  bool createLongTermReports, createFile, sendMail, sendGenerationNotification;
  dpGet("fwSystemOverviewReportsConfig.longTerm.enabled", createLongTermReports,
        "fwSystemOverviewReportsConfig.daily.createFile", createFile,
        "fwSystemOverviewReportsConfig.daily.sendMail", sendMail,
        "fwSystemOverviewReportsConfig.daily.sendGenerationNotification", sendGenerationNotification);
  dyn_string soTrees;
  fwSystemOverviewFsm_getTrees(soTrees);  
  for(int j = 1; j<= dynlen(soTrees); j++)
  {
   
    dyn_int types;
    dyn_string applications = fwCU_getChildren(types, soTrees[j]);
  
    for(int i = 1; i <= dynlen(applications); i++)
    {
      DebugTN("Generating now report for " + applications[i]);
      int result = fwSysOverviewReport_createApplicationReport(applications[i], createFile, sendMail, sendGenerationNotification);
      if (createLongTermReports)
        fwSysOverviewLongTermReport_createReportFile(applications[i]);
      delay(10);
    }
      
     
  }
  
  fwSysOverviewLongTermReport_disconnect();
  
  
}



