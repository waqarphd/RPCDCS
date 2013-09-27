// $License: NOLICENSE
/**@file
 *
 * This library contains all functions to handle remote upgrade request of the FW Component Installation Tool in the local project. 
 * The functions in these library are not intended to be called 
 * from user scripts
 *
 * @author Fernando Varela Rodriguez (IT-CO/BE)
 * @date   September 2010
 */
#uses "fwInstallation.ctl"
#uses "fwInstallationDBUpgrade.ctl"

dyn_dyn_mixed fwInstallationUpgrade_getManagerExceptions()
{
  dyn_dyn_mixed exceptions;
  
  exceptions[1][1] = fwInstallation_getWCCOAExecutable("sim");
  exceptions[1][2] = "";
  
  exceptions[2][1] = fwInstallation_getWCCOAExecutable("ctrl");
  exceptions[2][2] = "-f pvss_scripts.lst";
  
  exceptions[3][1] = fwInstallation_getWCCOAExecutable("ctrl");
  exceptions[3][2] = "-f fwInstallationAgent.lst";
 
  exceptions[4][1] = fwInstallation_getWCCOAExecutable("pmon");
  exceptions[4][2] = "";
  
  exceptions[5][1] = fwInstallation_getWCCOAExecutable("data");
  exceptions[5][2] = "";
  
  exceptions[6][1] = fwInstallation_getWCCOAExecutable("event");
  exceptions[6][2] = "";

  exceptions[7][1] = fwInstallation_getWCCOAExecutable("valarch");
  exceptions[7][2] = "-num 0";
  
  return exceptions;
}

int fwInstallationUpgrade_execute()
{
  dyn_mixed upgradeInfo;
  string targetDir = "";
  int error = 0;
  string user = "", pwd = "";
  dyn_dyn_mixed exceptions = fwInstallationUpgrade_getManagerExceptions();
  
  if(!fwInstallationDB_getUseDB()) //Nothing to be done
  return 0;
  
  if(fwInstallationDBUpgrade_getProjectToolUpgradeRequest(upgradeInfo))
  {
    fwInstallation_throw("fwInstallationUpgrade_execute() -> Could not check if the remote upgrade of the FW Component Installation Tool has been requested");
    return -1;
  }

  if(dynlen(upgradeInfo) <= 0) //No request exists
    return 0;
  
  targetDir = upgradeInfo[FW_INSTALLATION_DB_TOOL_UPGRADE_TARGET_DIR];
  
  if(targetDir == "") //if target dir has not been defined, it means, use the project path
    targetDir = PROJ_PATH;

  dyn_string files = fwInstallation_getFileNamesRec(upgradeInfo[FW_INSTALLATION_DB_TOOL_UPGRADE_SOURCE_DIR]);

  if(dynlen(files) <= 0)
    return 0; //nothing to be done

  fwInstallation_throw("FW Component Installation Tool has to be upgraded.", "INFO", 10);  
  //stop all managers required:
  if(user == "")
    if(fwInstallation_getPmonInfo(user, pwd) != 0)
    {
      fwInstallation_throw("ERROR: fwInstallationManager_stopAllOfTypes: Could not resolve pmon username and password. Action aborted", "error", 1);
      return -1;
    }    
  
  if(upgradeInfo[FW_INSTALLATION_DB_TOOL_UPGRADE_SAFE_MODE])
  {
    fwInstallation_throw("Entering safe upgrade mode now. Managers will be stopped, please wait..", "INFO", 10);  
    if(fwInstallationManager_stopAll(exceptions))
    {
      fwInstallation_throw("Failed to stop the project managers. Upgrade of the FW Component Installation Tool aborted");
      if(fwInstallationManager_executeAllReconfigurationActions())
      {
        fwInstallation_throw("Failed to reconfigure all project managers. The FW Component Installation Tool has been sucessfully upgrade but please, check the manager configuration", "WARNING", 10);
        return -1;
      }
      return -1;
    }
  }

  for(int i = 1; i <= dynlen(files); i++)
  {
    string target = targetDir + "/" + files[i];
    if(fwInstallation_copyFile(upgradeInfo[FW_INSTALLATION_DB_TOOL_UPGRADE_SOURCE_DIR] + "/" + files[i], target))
    {
      fwInstallation_throw("Failed to copy: " + upgradeInfo[FW_INSTALLATION_DB_TOOL_UPGRADE_SOURCE_DIR] + "/" + files[i]);
      return -2;
    }
  }
  
  fwInstallation_throw("Reverting manager configuration", "INFO", 10);      
  if(fwInstallationManager_executeAllReconfigurationActions())
  {
      fwInstallation_throw("Failed to reconfigure the project managers. The FW Component Installation Tool has been sucessfully upgrade but please, check the manager configuration", "WARNING", 10);
      return -1;
  }

  if(fwInstallationDBUpgrade_unregisterProjectToolUpgradeRequest())
  {
    fwInstallation_throw("fwInstallationUpgrade_execute() -> Failed to unregister the pending request for the upgrade FW Component Installation Tool after execution");
    return -1;
  }

  if(error)
    fwInstallation_throw("There have been errors upgrading the FW Component Installation Tool");  
  else
  {
    fwInstallation_throw("FW Component Installation Tool has been successfully upgraded. Restarting the DB-Agent of the Installation Tool now...", "INFO", 10);  
    fwInstallationManager_command("STOP", fwInstallation_getWCCOAExecutable("ctrl"), "-f fwInstallationAgent.lst");
  }
  
  return 0;
}
