#uses "fwFMC/fwFMC.ctl"
#uses "fwInstallation.ctl"
#uses "fwDIM"



bool fwFMCAccessControl_exists()
{
  dyn_dyn_string componentsInfo;
  fwInstallation_getInstalledComponents(componentsInfo); 
  
  if(dynlen(componentsInfo) && dynContains(componentsInfo[1], "fwAccessControl"))
    return true;
  
  return false;
}



int fwFMCAccessControl_getGroupStandardPrivilege(string group, string &ac)
{
  return dpGet(fwFMC_getGroupDp(group) + ".AC.standard", ac);
}

int fwFMCAccessControl_setGroupStandardPrivilege(string group, string ac)
{
  return dpSet(fwFMC_getGroupDp(group) + ".AC.standard", ac);
}

int fwFMCAccessControl_getGroupAdvancedPrivilege(string group, string &ac)
{
  return dpGet(fwFMC_getGroupDp(group) + ".AC.standard", ac);
}

int fwFMCAccessControl_setGroupAdvancedPrivilege(string group, string ac)
{
  return dpSet(fwFMC_getGroupDp(group) + ".AC.standard", ac);
}

int fwFMCAccessControl_getEnabledGroup(string group)
{
  int enabled = false;
  
  dpGet(fwFMC_getGroupDp(group) + ".AC.enabled", enabled);
  
  return enabled;
  
}

void fwFMCAccessControl_setEnabledGroup(string group, int enabled)
{
  dpSet(fwFMC_getGroupDp(group) + ".AC.enabled", enabled);
}
