// $License: NOLICENSE


/**@file
*
* This library contains the implementation of cache functions to the fwInstallationDB interface.
*
* @author Daniel Rodrigues (EN-ICE/SIC)
* @version 0.6 corrected error on _fwInstallationDbCache_getCacheKey
* @date   August 2011
*
* @notes
*   version 0.6  adding an useCache flag, normally set to false, only true if initialized. 
*                eliminating the uptodate mechanism (clearing the db not so elegant but working)
*   version 0.5  changing a mapping based cache, depending on function names and parameters
*   version 0.3  Testing version
*   version 0.2  modifying architecture: new "setCache" parameter,
*                   cache controlled from fwInstallationDB to avoid infinite loop
*                   cache set from outside.
*   version 0.1  Initial porting of all functions with SELECT import
*
//  *   TODO: think about having a get/set tuple for each function instead of "loadCache"
*/

/**@description

This script implements an interface to the gDbCache object for the installation tool
1. All functions that select information from the database in fwInstallationDB are replicated in gDbCache
a. Stored as a compound string of functionname::(parameters:);
2. Returns the necessary variable if:
a. gDbCache is uptodate (gDbCache["isUptodate"] == true ) and
b. mapping exists for the compound string exists and
c. loadCache = false.
3. if loadCache is true,
a. Sets the mapping compoundstring, value(s)
*/

/** Version of this library.
 * Used to determine the coherency of all libraries of the installtion tool
 * @ingroup Constants
*/
const string csFwInstallationDBCacheLibVersion = "6.2.4";

global mapping gDbCache;
global bool useCache = false;

void fwInstallationDBCache_useCache(bool setUnsetUseCache) 
{
    useCache = setUnsetUseCache;
}

bool fwInstallationDBCache_initialize() 
{
    mappingClear(gDbCache);
    fwInstallationDBCache_useCache(true);
}

bool fwInstallationDBCache_clear() 
{
    mappingClear(gDbCache);
}

/**
  * gets cache key based on function name, parameterValues, value, etc.
  */
string _fwInstallationDbCache_getCacheKey(string functionKey, dyn_mixed parameters, string index = "" ) {
  //get base cacheKey 
  string cacheKey = functionKey + "::";
  for( int i = 1; i <= dynlen(parameters); i++) {
       cacheKey = cacheKey + ":" + parameters[i];
  }
  if( index != "") {
    cacheKey = cacheKey + "::[" + index + "]";
  }
  return cacheKey;
}
  
/**
  *  Set a number of cache values.
  * 
  * @possible alternative
  */
int fwInstallationDBCache_setCaches(string functionKey, dyn_mixed parameters, anytype value, dyn_string valuesIndexes ) {

  //no need to be doing anything here if we don't want to use the cache
  if( useCache == false ) 
    return 0;

  if( dynlen( values ) != dynlen( valuesIndexes ) ) {
     fwInstallation_throw("fwInstallationDBCache_setCache()->Wrong number of array size for returnValues/returnValuesIndexes.");
  }
  
  string cacheBaseKey = _fwInstallationDbCache_getCacheKey( functionKey, parameters);

  //Set cache value for each value
  for( int j = 1; j <= dynlen(values); j++ ) {
       gDbCache[cacheKey + "::[" + valuesIndexes[j] + "]"] = values[j];
  }
  
  return 0;
}

/**
  *  Set value in Cache for a given function, parameters, and index
  *  @return 0 of successful
  *  TODO : evaluate possibility of non forcable flag (return -1 if value already in cache)
  */
int fwInstallationDBCache_setCache(string functionKey, dyn_mixed parameters, anytype value, string index = "" ) {

  //no need to be doing anything here if we don't want to use the cache
  if( useCache == false ) 
    return 0;
      
  //get cacheKey
  string cacheKey = _fwInstallationDbCache_getCacheKey(functionKey, parameters, index);
  
  //Set Cache Value
  gDbCache[cacheKey] = value;
  
  return 0;
}


/**
  *  Get cached value for function, parameters, index to &value
  *  @return 0 if successful
  *  @return -1 if value is not cached. 
  *  @return -2 if cache is not to be used.
  */
int fwInstallationDBCache_getCache(string functionKey, dyn_mixed parameters, anytype &returnValue, string index = "" ) {

  /*  if(!fwInstallationDBCache_isUptodate()) {
    return -2;
  }*/
  if( useCache == false ) 
    return -2;
  
  //get cacheKey
  string cacheKey = _fwInstallationDbCache_getCacheKey(functionKey, parameters, index);

  if(!mappingHasKey(gDbCache, cacheKey)) {
    //fwInstallation_throw("fwInstallationDBCache_getCache()->Cache does not have cacheKey: " + cacheKey);
    return -1;
  }

  //set return value to cached value
  returnValue = gDbCache[cacheKey];
  
  return 0;
}
