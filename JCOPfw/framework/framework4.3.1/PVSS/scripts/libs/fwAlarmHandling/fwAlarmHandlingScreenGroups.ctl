/**@file

fwAlarmHandlingScreenGroups
This library contains functions for the internal workings of the JCOP Alarm Screen with Groups.

@par Creation Date
	05/10/2011

@par Modification History
  
@par Constraints

@par Usage
	Internal

@par PVSS managers
	VISION

@author 
	Marco Boccioli (EN/ICE), based on the original project of Giovanni Polese
*/

//@{
//constants
const int fwAlarmHandlingGroups_INDEX_SUBSYS = 1;
const int fwAlarmHandlingGroups_INDEX_SYS = 2;
const int fwAlarmHandlingGroups_INDEX_DPE = 3;
const int fwAlarmHandlingGroups_INDEX_ALIAS = 4;
const int fwAlarmHandlingGroups_INDEX_PRIO = 5;
const int fwAlarmHandlingGroups_INDEX_FSMCU = 6;
const string fwAlarmHandlingGroups_CONFIG_DP = "_fwAesGroupsConfig_";
const string fwAlarmHandlingGroups_ORDER_DP = "_fwAesGroupsSetup.groups";
const string fwAlarmHandlingGroups_ORDERMODE_DP = "_fwAesGroupsSetup.customOrder";
const string fwAlarmHandlingGroups_SOUNDFILE_DP = "_fwAesGroupsSetup.sound.fileName";
const string fwAlarmHandlingGroups_SOUNDENABLED_DP = "_fwAesGroupsSetup.sound.enabled";
const string fwAlarmHandlingGroups_SOUNDSOURCE_DP = "_fwAesGroupsSetup.sound.playSource";
const string fwAlarmHandlingGroups_SOUNDINHIBIT_DP = "_fwAesGroupsSetup.sound.inhibitSec";
const string fwAlarmHandlingGroups_GEOMETRYH_DP = "_fwAesGroupsSetup.geometry.height";
const string fwAlarmHandlingGroups_GEOMETRYW_DP = "_fwAesGroupsSetup.geometry.width";
const string fwAlarmHandlingGroups_SETUP_DPTYPE = "_FwAesGroupsSetup";
const string fwAlarmHandlingGroups_SETUP_DP = "_fwAesGroupsSetup";
const string fwAlarmHandlingGroups_CONFIG_DPTYPE = "_FwAesGroupsConfig";
const string fwAlarmHandlingGroups_FRAME_TXT = "Filters for subsystem ";
const string fwAlarmHandlingGroups_TYPE_ROOT = "root";
const string fwAlarmHandlingGroups_TYPE_SYS = "system";
const string fwAlarmHandlingGroups_TYPE_DP = "dp";
const string fwAlarmHandlingGroups_TYPE_ALIAS = "alias";
const string fwAlarmHandlingGroups_TYPE_FSMCU = "FSM CU";
const string fwAlarmHandlingGroups_TYPE_GROUP = "group";
const string fwAlarmHandlingGroups_ELEMENTS_SEPARATOR =",";
const string fwAlarmHandlingGroups_ICON_DP = "dpTree/dp.png";
const int fwAlarmHandlingGroups_SOUNDSOURCE_PCSPEAKER = 0;
const int fwAlarmHandlingGroups_SOUNDSOURCE_FILE = 1;
const string fwAlarmHandlingGroups_GEOMETRYW_DEFAULT = 1040;
const string fwAlarmHandlingGroups_GEOMETRYH_DEFAULT = 875;

//@}

//@{
/** Receive the CU name, return the list of dpes of all the DU below the CU and the nested CUs.

@par Constraints
	None

@par Usage
	Internal

@par PVSS managers
	VISION

@param sCU		The Control Unit name
				Use the fwAlarmHandlingScreen_CONFIG_OBJECT_FILTER_XXX constants to interpret the object
@return the list of dpes belonging to the Device Units under the CU and under the nested CUs.
*/
dyn_string _fwAlarmHandlingScreenGroups_getFsmDeviceDps(string sCU)
{
  dyn_string dsFsmDeviceDps, dsChildren, dsTmp;
  dyn_int diTypes;
  int i;
  string sDUdpName;
  dsChildren = fwCU_getChildren(diTypes, sCU);
  for(i=1 ; i<=dynlen(dsChildren) ; i++)
  {
    if(diTypes[i] == 2)//device unit
    {
      fwCU_getDevDp(sCU+"::"+dsChildren[i],sDUdpName);
      dynAppend(dsFsmDeviceDps, sDUdpName+".*");
    }
    else//logical units
      dynAppend(dsFsmDeviceDps, _fwAlarmHandlingScreenGroups_getFsmDeviceDps(dsChildren[i]));
  }
  return dsFsmDeviceDps;
}

/** Read the Groups configuration

@par Constraints
	The function can only be called from within the JCOP FW Alarm Screen with Groups

@par Usage
	Public

@par PVSS managers
	VISION

@param sysFilters		the list of system filters (one per group) is returned here.
@param dpFilters		the list of dp filters (one list per system) is returned here.
@param aliasFilters		the list of alias filters (one list per system) is returned here.
@param dsGroupsDescriptions		the list of groups descriptions is returned here.
@param sysFilters		the list of filters is returned here.
@return 0 if ok, -1 if problem.
*/
int fwAlarmHandlingScreenGroups_getConfig(dyn_dyn_string &sysFilters, dyn_mixed &dpFilters, dyn_mixed &aliasFilters, dyn_string &dsGroupsDescriptions)
{
  dyn_string exceptionInfo;
  dyn_string dsDpeGroups, dsDpeSys, dsDpeAlias, dsDpeDpes, dsDpeFsmCU;
  dyn_string dsGroupIds, dsDpesOfOneSys, dsFsmCu, dsAliases, dsOrderedGroups;
  dyn_dyn_string ddsSysDpes, ddsSystems, ddsSysAliases;
  dyn_string dsTmp,dsAlias;
  string sGroupId, sSysName, sAlias, sPattern;
  int i,j,k;
  int iCustomOrderMode;
  dyn_mixed dmDpFilters, dmAliasFilters;
  dyn_string dsFsmDeviceDps, dsFsmDevicesSystems;  
  int iSystemIndex;    
  
  sSysName = getSystemName();
  if(dpExists(fwAlarmHandlingGroups_ORDER_DP))
    dpGet(fwAlarmHandlingGroups_ORDERMODE_DP,iCustomOrderMode);

  //if groups have custom order, load them one by one  
  if(iCustomOrderMode==1)
  {
    dpGet(fwAlarmHandlingGroups_ORDER_DP,dsOrderedGroups);
    for(i=1 ; i<=dynlen(dsOrderedGroups) ; i++)
    {
      if(dpExists(sSysName+fwAlarmHandlingGroups_CONFIG_DP+dsOrderedGroups[i]))
      {
        dynAppend(dsDpeGroups , sSysName+fwAlarmHandlingGroups_CONFIG_DP+dsOrderedGroups[i]);
        dynAppend(dsDpeSys , sSysName+fwAlarmHandlingGroups_CONFIG_DP+dsOrderedGroups[i]+".systems");
        dynAppend(dsDpeAlias , sSysName+fwAlarmHandlingGroups_CONFIG_DP+dsOrderedGroups[i]+".aliases");
        dynAppend(dsDpeDpes , sSysName+fwAlarmHandlingGroups_CONFIG_DP+dsOrderedGroups[i]+".dpes");
        dynAppend(dsDpeFsmCU , sSysName+fwAlarmHandlingGroups_CONFIG_DP+dsOrderedGroups[i]+".fsmCu");  
      }
    }
  }
  //else, load them with alphabetical order
  else
  {  
    dsDpeGroups = dpNames(sSysName+fwAlarmHandlingGroups_CONFIG_DP+"*",fwAlarmHandlingGroups_CONFIG_DPTYPE);
    dsDpeSys = dpNames(sSysName+fwAlarmHandlingGroups_CONFIG_DP+"*.systems",fwAlarmHandlingGroups_CONFIG_DPTYPE);
    dsDpeAlias = dpNames(sSysName+fwAlarmHandlingGroups_CONFIG_DP+"*.aliases",fwAlarmHandlingGroups_CONFIG_DPTYPE);
    dsDpeDpes = dpNames(sSysName+fwAlarmHandlingGroups_CONFIG_DP+"*.dpes",fwAlarmHandlingGroups_CONFIG_DPTYPE);
    dsDpeFsmCU = dpNames(sSysName+fwAlarmHandlingGroups_CONFIG_DP+"*.fsmCu",fwAlarmHandlingGroups_CONFIG_DPTYPE);  
  }
  if(dynlen(dsDpeGroups))
  {
    for(i=1 ; i<=dynlen(dsDpeGroups) ; i++)
    {
      //group
      sGroupId = fwAlarmHandlingScreenGroups_getGroupId(dsDpeGroups[i]);
      dsGroupIds[i] = sGroupId;
      //systems
      dpGet(dsDpeSys[i],dsTmp);
      for(j=1 ; j<=dynlen(dsTmp) ; j++)
      { 
        if(strpos(dsTmp[j],":")<0)
          dsTmp[j]=dsTmp[j]+":";
      }
      ddsSystems[i] = dsTmp;
      //aliases
      dpGet(dsDpeAlias[i],dsAlias);
      //each group has one or several several systems, each system has 0 or several alias filters
      dynClear(ddsSysAliases);
      for(j=1 ; j<=dynlen(ddsSystems[i]) ; j++)
      {      
        if(dynlen(dsAlias)>=j)
        {
          if(strlen(dsAlias[j])>1)
            fwGeneral_stringToDynString(dsAlias[j], ddsSysAliases[j]);
          else
            ddsSysAliases[j] = makeDynString("");            
        }
        else
          ddsSysAliases[j] = makeDynString("");
      }
      dmAliasFilters[i] = ddsSysAliases;           
      //dpes
      dpGet(dsDpeDpes[i],dsTmp);
      //each group has one or several several systems, each system has 0 or several dpes filters
      dynClear(ddsSysDpes);
      for(j=1 ; j<=dynlen(ddsSystems[i]) ; j++)
      {
        sAlias="";
        if(dynlen(dsTmp)>=j)
        {
          if(strlen(dsTmp[j])>1)
            fwGeneral_stringToDynString(dsTmp[j], ddsSysDpes[j]);
          else
          {//if there is no dpe defined, and no alias defined, then set default dp pattern = "*"   
            if(dynlen(dsAlias)>=j)
            {
              sAlias = dsAlias[j];
              sPattern = strlen(sAlias) ? "" : "*";
            }
            ddsSysDpes[j] = makeDynString(sPattern);   
          }         
        }
        else
        {//if there is no dpe defined, and no alias defined, then set default dp pattern = "*"  
          if(dynlen(dsAlias)>=j)
          {
            sAlias = dsAlias[j];
            sPattern = strlen(sAlias) ? "" : "*";
          }
          ddsSysDpes[j] = makeDynString(sPattern);   
        } 
      }
      dmDpFilters[i] = ddsSysDpes; 
      //fsm cu
      dpGet(dsDpeFsmCU[i],dsFsmCu);
      for(j=1 ; j<=dynlen(dsFsmCu) ; j++)
      {      
        dsFsmDeviceDps = _fwAlarmHandlingScreenGroups_getFsmDeviceDps(dsFsmCu[j]);
        dynClear(dsFsmDevicesSystems);
        for(k=1 ; k<=dynlen(dsFsmDeviceDps) ; k++)
        {
          dsFsmDevicesSystems[k]="";
          fwGeneral_getSystemName(dsFsmDeviceDps[k], dsFsmDevicesSystems[k], exceptionInfo);
          iSystemIndex = dynContains(ddsSystems[i],dsFsmDevicesSystems[k]);
          if(iSystemIndex>0)//sys belonging to DU is already in list: add DU dpe under the sys
          {
            ddsSysDpes = dmDpFilters[i];
            dynAppend(ddsSysDpes[iSystemIndex],dsFsmDeviceDps[k]);
            dmDpFilters[i] = ddsSysDpes;
          }
          else//sys belonging to DU is not in list: add new sys and add DU dpe under the sys
          {
            iSystemIndex = dynAppend(ddsSystems[i],dsFsmDevicesSystems[k]);
            ddsSysDpes = dmDpFilters[i];
            dynAppend(ddsSysDpes[iSystemIndex],dsFsmDeviceDps[k]);
            dmDpFilters[i] = ddsSysDpes;
          }
        }
      }
      //description
      dsGroupsDescriptions[i] = dpGetDescription(dsDpeGroups[i]+".",-2);
    }
    groupIdx = dsGroupIds;
    sysFilters = ddsSystems;
    dpFilters = dmDpFilters; 
    aliasFilters = dmAliasFilters; 
    
//     DebugN("fwAlarmHandlingScreenGroups_getConfig", "groupIdx:",groupIdx,
//            "dpFilters:",dpFilters,"sysFilters:",sysFilters);
//     DebugN("alias:",aliasFilters);
    return 0;
  }
  else
  {
      return -1;
  }  
}

/** Get the Group dp and return the Group name

@par Constraints
	None

@par Usage
	Public

@par PVSS managers
	VISION

@param dpName		the dp name of the group.
@return the group name.
*/
string fwAlarmHandlingScreenGroups_getGroupId(string dpName)
{
  string id;
  int pos = strpos(dpName, fwAlarmHandlingGroups_CONFIG_DP);
  id = substr(dpName,pos);
  strreplace(id,fwAlarmHandlingGroups_CONFIG_DP,"");
  return id;
}

/** Return the default alarm sound to be played

@par Constraints
	None

@par Usage
	Public

@par PVSS managers
	VISION

@return the alarms sound path.
*/
string fwAlarmHandlingScreenGroups_getDefaultSoundPath()
{
    return getPath(DATA_REL_PATH,"sounds/AlertTone.wav");
}


/** Return the project name

@par Constraints
	None

@par Usage
	Public

@par PVSS managers
	VISION

@return the project name.
*/
string fwAlarmHandlingScreenGroups_getProjectName()
{
  string sProjName, sDir;
  dyn_string dsTemp;

  sDir = getPath(CONFIG_REL_PATH);
  dsTemp = strsplit(sDir,"/");
  if(dynlen(dsTemp)>2)
    sProjName = dsTemp[dynlen(dsTemp)-1];
  return sProjName;
}
//@}
