#uses "fwSystemOverview/fwSystemOverview.ctl"
#uses "fwSystemOverview/fwSystemOverviewFsm.ctl"

const string fwSysOverviewAC_DP = "fwSystemOverviewAC";
const string fwSysOverviewAC_FIRSTLEVELUSERS_DPE = ".firstLevelUser";
const string fwSysOverviewAC_SECONDLEVELUSERS_DPE = ".secondLevelUser";
const string fwSysOverviewAC_THIRDLEVELUSERS_DPE = ".thirdLevelUser";
const string fwSysOverviewAC_FORTHLEVELUSERS_DPE = ".forthLevelUser";
const string fwSysOverviewAC_PRIVILEGE_DPE = ".privilege";
const string fwSysOverviewAC_GROUPNAME_DPE = ".groupName";

string fwSysOverviewAC_getFirstLevelUsersPrivilege()
{
  string privilege;
  if (dpExists(fwSysOverviewAC_DP + fwSysOverviewAC_FIRSTLEVELUSERS_DPE + fwSysOverviewAC_PRIVILEGE_DPE))
  {
    dpGet(fwSysOverviewAC_DP + fwSysOverviewAC_FIRSTLEVELUSERS_DPE + fwSysOverviewAC_PRIVILEGE_DPE, privilege);
  }
  
  return privilege;
}

void fwSysOverviewAC_setFirstLevelUsersPrivilege(string privilege)
{
  if (dpExists(fwSysOverviewAC_DP + fwSysOverviewAC_FIRSTLEVELUSERS_DPE + fwSysOverviewAC_PRIVILEGE_DPE))
  {
    dpSet(fwSysOverviewAC_DP + fwSysOverviewAC_FIRSTLEVELUSERS_DPE + fwSysOverviewAC_PRIVILEGE_DPE, privilege);
  }
}

string fwSysOverviewAC_getFirstLevelGroupName()
{
  string groupName;
  if (dpExists(fwSysOverviewAC_DP + fwSysOverviewAC_FIRSTLEVELUSERS_DPE + fwSysOverviewAC_GROUPNAME_DPE))
  {
    dpGet(fwSysOverviewAC_DP + fwSysOverviewAC_FIRSTLEVELUSERS_DPE + fwSysOverviewAC_GROUPNAME_DPE, groupName);
  }
  
  return groupName;
}

void fwSysOverviewAC_setFirstLevelGroupName(string groupName)
{
  if (dpExists(fwSysOverviewAC_DP + fwSysOverviewAC_FIRSTLEVELUSERS_DPE + fwSysOverviewAC_GROUPNAME_DPE))
  {
    dpSet(fwSysOverviewAC_DP + fwSysOverviewAC_FIRSTLEVELUSERS_DPE + fwSysOverviewAC_GROUPNAME_DPE, groupName);
  }
}

string fwSysOverviewAC_getSecondLevelUsersPrivilege()
{
  string privilege;
  if (dpExists(fwSysOverviewAC_DP + fwSysOverviewAC_SECONDLEVELUSERS_DPE + fwSysOverviewAC_PRIVILEGE_DPE))
  {
    dpGet(fwSysOverviewAC_DP + fwSysOverviewAC_SECONDLEVELUSERS_DPE + fwSysOverviewAC_PRIVILEGE_DPE, privilege);
  }
  
  return privilege;
}

void fwSysOverviewAC_setSecondLevelUsersPrivilege(string privilege)
{
  if (dpExists(fwSysOverviewAC_DP + fwSysOverviewAC_SECONDLEVELUSERS_DPE + fwSysOverviewAC_PRIVILEGE_DPE))
  {
    dpSet(fwSysOverviewAC_DP + fwSysOverviewAC_SECONDLEVELUSERS_DPE + fwSysOverviewAC_PRIVILEGE_DPE, privilege);
  }
}

string fwSysOverviewAC_getSecondLevelGroupName()
{
  string groupName;
  if (dpExists(fwSysOverviewAC_DP + fwSysOverviewAC_SECONDLEVELUSERS_DPE + fwSysOverviewAC_GROUPNAME_DPE))
  {
    dpGet(fwSysOverviewAC_DP + fwSysOverviewAC_SECONDLEVELUSERS_DPE + fwSysOverviewAC_GROUPNAME_DPE, groupName);
  }
  
  return groupName;
}

void fwSysOverviewAC_setSecondLevelGroupName(string groupName)
{
  if (dpExists(fwSysOverviewAC_DP + fwSysOverviewAC_SECONDLEVELUSERS_DPE + fwSysOverviewAC_GROUPNAME_DPE))
  {
    dpSet(fwSysOverviewAC_DP + fwSysOverviewAC_SECONDLEVELUSERS_DPE + fwSysOverviewAC_GROUPNAME_DPE, groupName);
  }
}

string fwSysOverviewAC_getThirdLevelUsersPrivilege()
{
  string privilege;
  if (dpExists(fwSysOverviewAC_DP + fwSysOverviewAC_THIRDLEVELUSERS_DPE + fwSysOverviewAC_PRIVILEGE_DPE))
  {
    dpGet(fwSysOverviewAC_DP + fwSysOverviewAC_THIRDLEVELUSERS_DPE + fwSysOverviewAC_PRIVILEGE_DPE, privilege);
  }
  
  return privilege;
}

void fwSysOverviewAC_setThirdLevelUsersPrivilege(string privilege)
{
  if (dpExists(fwSysOverviewAC_DP + fwSysOverviewAC_THIRDLEVELUSERS_DPE + fwSysOverviewAC_PRIVILEGE_DPE))
  {
    dpSet(fwSysOverviewAC_DP + fwSysOverviewAC_THIRDLEVELUSERS_DPE + fwSysOverviewAC_PRIVILEGE_DPE, privilege);
  }
}

string fwSysOverviewAC_getThirdLevelGroupName()
{
  string groupName;
  if (dpExists(fwSysOverviewAC_DP + fwSysOverviewAC_THIRDLEVELUSERS_DPE + fwSysOverviewAC_GROUPNAME_DPE))
  {
    dpGet(fwSysOverviewAC_DP + fwSysOverviewAC_THIRDLEVELUSERS_DPE + fwSysOverviewAC_GROUPNAME_DPE, groupName);
  }
  
  return groupName;
}

void fwSysOverviewAC_setThirdLevelGroupName(string groupName)
{
  if (dpExists(fwSysOverviewAC_DP + fwSysOverviewAC_THIRDLEVELUSERS_DPE + fwSysOverviewAC_GROUPNAME_DPE))
  {
    dpSet(fwSysOverviewAC_DP + fwSysOverviewAC_THIRDLEVELUSERS_DPE + fwSysOverviewAC_GROUPNAME_DPE, groupName);
  }
}

string fwSysOverviewAC_getForthLevelUsersPrivilege()
{
  string privilege;
  if (dpExists(fwSysOverviewAC_DP + fwSysOverviewAC_FORTHLEVELUSERS_DPE + fwSysOverviewAC_PRIVILEGE_DPE))
  {
    dpGet(fwSysOverviewAC_DP + fwSysOverviewAC_FORTHLEVELUSERS_DPE + fwSysOverviewAC_PRIVILEGE_DPE, privilege);
  }
  
  return privilege;
}

void fwSysOverviewAC_setForthLevelUsersPrivilege(string privilege)
{
  if (dpExists(fwSysOverviewAC_DP + fwSysOverviewAC_FORTHLEVELUSERS_DPE + fwSysOverviewAC_PRIVILEGE_DPE))
  {
    dpSet(fwSysOverviewAC_DP + fwSysOverviewAC_FORTHLEVELUSERS_DPE + fwSysOverviewAC_PRIVILEGE_DPE, privilege);
  }
}

string fwSysOverviewAC_getForthLevelGroupName()
{
  string groupName;
  if (dpExists(fwSysOverviewAC_DP + fwSysOverviewAC_FORTHLEVELUSERS_DPE + fwSysOverviewAC_GROUPNAME_DPE))
  {
    dpGet(fwSysOverviewAC_DP + fwSysOverviewAC_FORTHLEVELUSERS_DPE + fwSysOverviewAC_GROUPNAME_DPE, groupName);
  }
  
  return groupName;
}

void fwSysOverviewAC_setForthLevelGroupName(string groupName)
{
  if (dpExists(fwSysOverviewAC_DP + fwSysOverviewAC_FORTHLEVELUSERS_DPE + fwSysOverviewAC_GROUPNAME_DPE))
  {
    dpSet(fwSysOverviewAC_DP + fwSysOverviewAC_FORTHLEVELUSERS_DPE + fwSysOverviewAC_GROUPNAME_DPE, groupName);
  }
}

string fwSysOverviewAC_getPrivilege(int level)
{
  string privilege;
  switch (level)
  {
     case 1:
      privilege = fwSysOverviewAC_getFirstLevelUsersPrivilege();    
      break;
     case 2:
      privilege = fwSysOverviewAC_getSecondLevelUsersPrivilege();      
      break;
     case 3:
      privilege = fwSysOverviewAC_getThirdLevelUsersPrivilege();
      break;
     case 4:
      privilege = fwSysOverviewAC_getForthLevelUsersPrivilege();
      break;      
        
  }
  return privilege;
}

dyn_string fwSysOverviewAC_getAllPrivileges()
{
  dyn_string privilegeDps;
  dynAppend(privilegeDps, fwSysOverviewAC_DP + fwSysOverviewAC_FIRSTLEVELUSERS_DPE + fwSysOverviewAC_PRIVILEGE_DPE);
  dynAppend(privilegeDps, fwSysOverviewAC_DP + fwSysOverviewAC_SECONDLEVELUSERS_DPE + fwSysOverviewAC_PRIVILEGE_DPE);
  dynAppend(privilegeDps, fwSysOverviewAC_DP + fwSysOverviewAC_THIRDLEVELUSERS_DPE + fwSysOverviewAC_PRIVILEGE_DPE);
  dynAppend(privilegeDps, fwSysOverviewAC_DP + fwSysOverviewAC_FORTHLEVELUSERS_DPE + fwSysOverviewAC_PRIVILEGE_DPE);  
  dyn_string privileges;
  dpGet(privilegeDps, privileges);
  return privileges;
}

//one domain for ach app
//first level users - 1 group(all domains + all privileges)
//second level users - 1 group for each domain(application) with privileges 4,3,2;
//third level users - 1 group for each tree (all domains in the tree privileges 4, 3)
//forth level users - 1 group (all domains + privilege 4)
void fwSysOverviewAC_createAppBasedAC()
{
  dyn_string firstLevelUsersPrivileges, secondLevelUsersPrivileges;
  dyn_string thirdLevelUsersPrivileges, forthLevelUsersPrivileges;

  string firstLevelGroupName = fwSysOverviewAC_getFirstLevelGroupName();  
  string secondLevelGroupName = fwSysOverviewAC_getSecondLevelGroupName();
  string thirdLevelGroupName = fwSysOverviewAC_getThirdLevelGroupName();
  string forthLevelGroupName = fwSysOverviewAC_getForthLevelGroupName();  
  
  dyn_string ex, tmp;
  dyn_string privileges = fwSysOverviewAC_getAllPrivileges();
  if (dynlen(privileges) != 4 || (firstLevelGroupName == "") || (secondLevelGroupName == "") ||
      (thirdLevelGroupName == "") || (forthLevelGroupName == ""))
  {
    DebugN("Incorrect AC control configuration of " + fwSysOverviewAC_DP);
    return;
  }
  
  dyn_string soTrees, applications;
  fwSystemOverviewFsm_getTrees(soTrees);
  for (int i=1; i<=dynlen(soTrees); i++)
  {
    string treeLabel;
    fwUi_getLabel(soTrees[i], soTrees[i], treeLabel);
    // clear privileges for third level(different for the different trees)
    dynClear(thirdLevelUsersPrivileges);
    fwUi_getChildren(soTrees[i], applications);
    for (int j=1; j<= dynlen(applications);j++)
    {
      string appLabel;
      if(fwSysOverviewFsm_isDomain(applications[j]))
      {
        fwUi_getLabel(applications[j], applications[j], appLabel);
      }
      else
      {
        fwUi_getLabel(soTrees[i], applications[j], appLabel);        
      }
      // clear privileges for second level (different for each app domain)
      dynClear(secondLevelUsersPrivileges);
     
      fwAccessControl_checkAddDomain(applications[j], privileges, ex, applications[j] + " Application", applications[j]);
      if (dynlen(ex) > 0)
      {
        DebugN(ex);
      }

      dyn_string domainPrivileges;
      for(int k = 1; k<=dynlen(privileges); k++)
      {
        dynAppend(domainPrivileges, applications[j] + ":" + privileges[k]);
      }
      dynAppend(forthLevelUsersPrivileges,domainPrivileges[4]);
      dynAppend(thirdLevelUsersPrivileges, makeDynString(domainPrivileges[3], domainPrivileges[4]));      
      dynAppend(secondLevelUsersPrivileges, makeDynString(domainPrivileges[2], domainPrivileges[3], domainPrivileges[4]));
      dynAppend(firstLevelUsersPrivileges, domainPrivileges);

      // create group for second level
      fwAccessControl_checkAddGroup(treeLabel + appLabel + secondLevelGroupName, secondLevelUsersPrivileges, ex,treeLabel + appLabel+ secondLevelGroupName,treeLabel + appLabel + secondLevelGroupName);
     
    }
    
    // create group for third level
    fwAccessControl_checkAddGroup(treeLabel + thirdLevelGroupName, thirdLevelUsersPrivileges, ex, treeLabel + thirdLevelGroupName,treeLabel + thirdLevelGroupName);      
   
  }
  
  // create group for first and forth level
  fwAccessControl_checkAddGroup(firstLevelGroupName, firstLevelUsersPrivileges, ex, firstLevelGroupName, firstLevelGroupName);    
  fwAccessControl_checkAddGroup(forthLevelGroupName, forthLevelUsersPrivileges, ex, forthLevelGroupName, forthLevelGroupName);
}
