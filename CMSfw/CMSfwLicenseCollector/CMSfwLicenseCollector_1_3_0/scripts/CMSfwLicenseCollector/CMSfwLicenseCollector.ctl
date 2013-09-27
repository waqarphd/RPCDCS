main(){    

  fwInstallationDB_connect();
  
  while (1){
   int iLicense;
   dpGet("_Event.License.RemainingTime",iLicense);
   if(iLicense>10080){
     fwInstallation_setManagerMode("PVSS00ctrl","CMSfwLicenseCollector/CMSfwLicenseCollector.ctl","manual");
     system ("copy /Y C:\\ETM\\PVSS2\\3.8\\Shield \\\\10.176.61.253\\pvss\\Licenses\\%COMPUTERNAME%_Shield");
     system ("copy /Y C:\\ETM\\PVSS2\\3.8\\Shield.txt \\\\10.176.61.253\\pvss\\Licenses\\%COMPUTERNAME%_Shield");
     return;    
   }
	delay(1200);
  }
}
