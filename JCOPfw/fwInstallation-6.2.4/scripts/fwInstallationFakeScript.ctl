#uses "fwInstallation.ctl"
main()
{
	
//  if ( !globalExists("gFwInstallationLog") )
//    addGlobal("gFwInstallationLog", STRING_VAR);
//    
//  gFwInstallationLog = "";
	
  // if there are any postInstallation files execute them

  int iReturn;
  int i;
  bool postInstallsRun = false;

  dyn_string dynPostInstallFiles_all;
  string dp = fwInstallation_getInstallationDp();
  
  setUserId(getUserId("para"));
  if(dpExists(dp))
  {
    // get all the post install init files
    dpGet(dp + ".postInstallFiles:_original.._value", dynPostInstallFiles_all);
                        
    // for each post install init file
    if( dynlen(dynPostInstallFiles_all) > 0)
    {
      for(i = 1; i <= dynlen(dynPostInstallFiles_all); i++)	
				{
        postInstallsRun = true;
        // execute the file	
        fwInstallation_setCurrentComponent(dynPostInstallFiles_all[i]);
        fwInstallation_throw("Running post-installation script: " + dynPostInstallFiles_all[i], "INFO");  
        fwInstallation_evalScriptFile(dynPostInstallFiles_all[i] , iReturn);
				
        // check the return value
        if(iReturn == -1)
        {
          fwInstallation_throw("Error executing : " + dynPostInstallFiles_all[i] + " file.");
        }
        else
        {
          fwInstallation_throw("  " + dynPostInstallFiles_all[i] + " - OK ", "INFO");
        }
        fwInstallation_unsetCurrentComponent();
        
      }	
			
      // all the files were executed - if there were any errors the user has been informed
      // clearing the fwInstallationInfo.postInstallFiles:_original.._value
				
      dynClear(dynPostInstallFiles_all);
			
      dpSet(dp + ".postInstallFiles:_original.._value", dynPostInstallFiles_all);
    }

    // get all the post delete files
    dpGet(dp + ".postDeleteFiles:_original.._value", dynPostInstallFiles_all);
			
    // for each post delete file
    for(i = 1; i <= dynlen(dynPostInstallFiles_all); i++)
    {
      fwInstallation_showMessage(makeDynString("Executing post delete  files ..."));
				
      // execute the file	
      fwInstallation_setCurrentComponent(dynPostInstallFiles_all[i]);
      fwInstallation_evalScriptFile(dynPostInstallFiles_all[i] , iReturn);
				
      // check the return value
      if(iReturn == -1)
      {
        fwInstallation_throw("Error executing : " + dynPostInstallFiles_all[i] + " file.");
      }
      else
      {
        fwInstallation_throw(dynPostInstallFiles_all[i] + " - OK ", "INFO");
        fwInstallation_deleteFiles(dynPostInstallFiles_all[i], "");
      }
      fwInstallation_unsetCurrentComponent();
    }
			
    // all the files were executed - if there were any errors the user has been informed
    // clearing the fwInstallationInfo.postInstallFiles:_original.._value
    dpSet(dp + ".postInstallFiles", makeDynString());
  }
  else
    fwInstallation_throw("Dp does not exist: " + dp);   
        
  if(fwInstallationManager_executeAllReconfigurationActions(true))
  {
    fwInstallation_throw("There were errors executing the managers' reconfiguration actions", "WARNING", 10);
    delay(1); //Make sure that our message gets print out.
  }

  //Update System Configuration DB if required:
  if(postInstallsRun && fwInstallationDB_getUseDB())
  {
    if(fwInstallationDB_connect()){fwInstallation_throw("Failed to connect to the System Configuration DB after component deletion", "WARNING", 10); return 0;}
    if(fwInstallationDB_registerProjectFwComponents()) {fwInstallation_throw("Failed to upate the System Configuration DB after execution of the component post-installation scripts", "WARNING", 10); return 0;}
//    DebugN("Wrinting log with", gFwInstallationLog);
//    fwInstallationDB_storeInstallationLog();
  }	
  
  
  dpSet("_Managers.Exit", 1280 + myManNum());
}

// This function is copied from the fwInstallationMain.pnl
fwInstallation_evalScriptFile(string componentInitFile , int & iReturn)
{
  bool fileLoaded;
  string fileInString;
  anytype retVal;
  int result;
	
  fileLoaded = fileToString(componentInitFile, fileInString);
	
  if (! fileLoaded )
  {
    fwInstallation_throw("Cannot load " + componentInitFile + " file");
    iReturn =  -1;
  }
  else 
  {
    // the evalScript 
    iReturn = evalScript(retVal, fileInString, makeDynString("$value:12345"));
  }
}
