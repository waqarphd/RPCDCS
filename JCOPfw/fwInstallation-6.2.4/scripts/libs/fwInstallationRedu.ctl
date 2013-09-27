/**@file
 *
 * This library contains helper functions to address redundant systems
 *
 * @author Fernando Varela Rodriguez (EN-ICE)
 * @date   August 2010
 */

/** Version of this library.
 * Used to determine the coherency of all libraries of the installtion tool
 * @ingroup Constants
*/
const string csFwInstallationReduLibVersion = "6.2.4";

/** This functions appends the suffix '_'+ myRedHostNum() to the dp passed as input argument
@param dp: name of the dp
@return dp if redu system is number 1, dp + "_" + myReduHostNumber() if redu number is greater than 1
@author F. Varela
*/
string fwInstallationRedu_getLocalDp(string dp)
{
  if(myReduHostNum() > 1)
    dp = dp + "_" + myReduHostNum();
  
  return dp;
}

/** Wrapper function for the standard PVSS function dpTypeCreate to work in redundant systems.
@param elements: dp-type elements
@param types: dp-type element types
@return 0 if OK, -1 if error
@author F. Varela
*/
int fwInstallationRedu_dpTypeChange(dyn_dyn_string elements, dyn_dyn_int types)
{
  if(fwInstallationRedu_isPassive())
    return 0;
  
  return dpTypeChange(elements, types);
}


/** Wrapper function for the standard PVSS function dpTypeCreate to work in redundant systems.
@param elements: dp-type elements
@param types: dp-type element types
@return 0 if OK, -1 if error
@author F. Varela
*/
int fwInstallationRedu_dpTypeCreate(dyn_dyn_string elements, dyn_dyn_int types)
{
  if(fwInstallationRedu_isPassive())
    return 0;
  
  return dpTypeCreate(elements, types);
}

/** Wrapper function for the standard PVSS function dpCreate to work in redundant systems.
@param dpname: name of the dp to be deleted
@return 0 if OK, -1 if error
@author F. Varela
*/
int fwInstallationRedu_dpDelete(string dpname)
{
  if(fwInstallationRedu_isPassive())
    return 0;
  
  return dpDelete(dpname, dptype);
}
/** Wrapper function for the standard PVSS function dpCreate to work in redundant systems.
@param dpname name of the dp to be created
@param dptype dp-type of the new dp
@return 0 if OK, -1 if error
@author F. Varela
*/
int fwInstallationRedu_dpCreate(string dpname, string dptype)
{
  if(fwInstallationRedu_isPassive())
    return 0;
  
  return dpCreate(dpname, dptype);
}

/** Wrapper function for the standard PVSS function dpSet to work in redundant systems.
@param dpname: name of the dp to be set
@param val: value to be set
@return 0 if OK, -1 if error
@author F. Varela
*/
int fwInstallationRedu_dpSet(string dpname, anytype val)
{
  if(fwInstallationRedu_isPassive())
    return 0;
  
  return dpSet(dpname, val);
}

/** This functions checks whether the local system is the passive peer in a redundant system or not.
@return FALSE - local system is not the passive peer, TRUE the local system is the passive peer
@author F. Varela
*/
int fwInstallationRedu_isPassive()
{
  bool isPassive = true;
  int active, local;

  if(!isRedundant()) //if it is not a redundant system, it will always be the active one.
    return false;
    
  local = myReduHostNum();
  
  reduActive(active, getSystemName());
  //DebugN(local, active, local > 0, active > 0, local != active, local > 0 && active > 0 && local != active);
  if(local > 0 && active > 0 && local == active)
    isPassive = false;

  //DebugN("returning: ", isPassive);  
  return isPassive;
}

/** This functions returns the name of the host where the redundant pair runs
@return name of the redundant pair
@author F. Varela
*/
string fwInstallationRedu_getPair()
{
    
  dyn_string hosts = dataHost();
 
  for(int i = 1; i <= dynlen(hosts); i++) //get rid of network domain
  {
    if(strpos(hosts[i], ".") > 0)
      hosts[i] = substr(hosts[i], 0, strpos(hosts[i], "."));
    
    if(strtoupper(hosts[i]) == "LOCALHOST") //make sure localhost is replace with a proper host name
      hosts[i] = strtoupper(getHostname());
  } 
 
  if(isRedundant() && strtoupper(hosts[1]) == strtoupper(getHostname())) //redu system
    return strtoupper(hosts[2]);

  return strtoupper(hosts[1]);//return the name of the local host in any other case.    
}

/** This functions checks if a particular version of a component is installed in the redundant pair
@param component (in) name of the component
@param version (in) version of the component
@return True if the component is installed in the pair. Otherwise, false
@author F. Varela
*/
bool fwInstallationRedu_isComponentInstalledInPair(string component, string version)
{
  string dp, ver;
  int nok;
  
  if(myReduHostNum() == 1)
    dp = "fwInstallation_" + component + "_" + 2;
  else
    dp =  "fwInstallation_" + component;
  
  if(dpExists(dp))
  {
    dpGet(dp + ".componentVersionString", ver,
          dp + ".installationNotOK", nok);
    
    if(version == ver && !nok)
      return true;
  }
  
  return false;
}


