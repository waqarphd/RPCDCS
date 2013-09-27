/**@file

This library contains function associated with the archive config.
Functions are provided for getting the current settings, deleting the config
and setting the config

@par Creation Date
	28/3/00

@par Modification History

  05/09/11 Marco Boccioli
  - @sav{86405}: index out of range if a dpe has archive not fully parametrized. In case an attribute is not readable,
    fwArchive_getMany() makes a dpGet attribute per attribute. In this way it saves all the other dpes that are readable.
  
  31/08/11 Marco Boccioli
  - @sav{86237}: fwArchive gives error if dpe is has no archive class name
  
  12/08/11 Marco Boccioli
  - @sav{85462}: Functions *_setMany and *_getMany with parameters as reference.
  - @sav{86012}: Improve performance for fwArchive_getMany(). Function completely re-written.
 
	Oliver:  cases for "combined smoothing and time" and " old/new comparison and time"
					 added ability to get/set time interval when available
	15/09/00 Oliver: added error handling to save and delete functions

	31/01/03	S. Schmeling	Changes to set/get for all smoothing procedures
	07/02/03	S. Schmeling	Changes to set for allowing configuration without starting.
												New functions: start/stop
	06/04/03	S. Schmeling	Changed set to old syntax. Will again start archiving immediately.
												Added function config that will config the archive but not start archiving.				
	15/01/04	Oliver Holme (IT-CO) 	Completed major overhaul of whole library
	21/01/04	Oliver Holme (IT-CO) 	Added functionality for relative deadband values
												Functionality for set and get of smoothing parameters is now called from the fwSmoothing.ctl
	
@par Constraints
	WARNING: the functions use the dpGet or dpSetWait, problems may occur when using these functions 
          		in a working function called by a PVSS (dpConnect) or in a calling function 

@par Usage
	Public

@par PVSS managers
	VISION, CTRL

@author 
	Oliver Holme, Herve Milcent, Niko Karlsson from exemple from Fernando Varela, changed by Sascha Schmeling
*/


//@{
//constants
const int fwArchive_CLASS_STOPPED				= 0;
const int fwArchive_CLASS_ONLINE				= 1;
const int fwArchive_CLASS_SWAPPED_OUT		= 2;
const int fwArchive_CLASS_DELETED				= 3;

const string fwArchive_VALARCH_CLASS_DPTYPE = "_ValueArchive";
const string fwArchive_RDB_CLASS_DPTYPE = "_RDBArchiveGroups";

const int fwArchive_MANAGER_NUMBER_OFFSET = 2;

//global for monitoring class stats refresh
bool fwArchive_REFRESH_IN_PROGRESS = FALSE;
//@}

//@{
/** Deletes the archive config for the given data point elements

@par Constraints
	None

@par Usage
	Public

@par PVSS managers
	VISION, CTRL

@param dpes						list of data point elements
@param exceptionInfo	details of any errors are returned here
*/
fwArchive_deleteMultiple(dyn_string dpes, dyn_string &exceptionInfo)
{
	_fwConfigs_delete(dpes, fwConfigs_PVSS_ARCHIVE, exceptionInfo);
}


/** Deletes the archive config for the given data point elements

@par Constraints
	None

@par Usage
	Public

@par PVSS managers
	VISION, CTRL

@param dpes						list of data point elements
@param exceptionInfo	details of any errors are returned here
*/
fwArchive_deleteMany(dyn_string dpes, dyn_string &exceptionInfo)
{
	_fwConfigs_delete(dpes, fwConfigs_PVSS_ARCHIVE, exceptionInfo);
}


/** Deletes the archive config for the given data point element

@par Constraints
	None

@par Usage
	Public

@par PVSS managers
	VISION, CTRL

@param dpe						data point element
@param exceptionInfo	details of any errors are returned here
*/
fwArchive_delete(string dpe, dyn_string &exceptionInfo)
{
	_fwConfigs_delete(makeDynString(dpe), fwConfigs_PVSS_ARCHIVE, exceptionInfo);
}

/** Sets archive config for the given dp elements with the option to start or not start the archiving

@par Constraints
	None

@par Usage
	Internal

@par PVSS managers
	VISION, CTRL

@param dpes								list of data point elements
@param startArchiving				true in order to start the archive immediately, false in order to ONLY configure it
@param archiveClassDpName	the dp name of the archiving class to be used
@param archiveType				DPATTR_ARCH_PROC_VALARCH: no smoothing,  
                   				DPATTR_ARCH_PROC_SIMPLESM: value dependent + deadband/old-new comparison smoothing 
@param smoothProcedure		DPATTR_VALUE_SMOOTH            	: value dependent,
													DPATTR_VALUE_REL_SMOOTH        	: relative value dependent,
													DPATTR_TIME_SMOOTH             	: time dependent,
													DPATTR_TIME_AND_VALUE_SMOOTH   	: value AND time dependent,
													DPATTR_TIME_AND_VALUE_REL_SMOOTH   : relative value AND time dependent,
													DPATTR_TIME_OR_VALUE_SMOOTH    	: value OR time dependent,
													DPATTR_TIME_OR_VALUE_REL_SMOOTH    : relative value OR time dependent,
													DPATTR_COMPARE_OLD_NEW         	: old-new comparison,
													DPATTR_OLD_NEW_AND_TIME_SMOOTH 	: old-new comparison AND time,
													DPATTR_OLD_NEW_OR_TIME_SMOOTH  	: old-new comparison OR time
@param deadband						archive deadband
@param timeInterval				archive time interval 
@param exceptionInfo			details of any errors are returned here
@param checkClass					Optional parameter. Default value TRUE.
														If TRUE, check class is not deleted and has enough free space.
														If FALSE skip checks.
*/
_fwArchive_setOrConfig(dyn_string dpes, bool startArchiving, dyn_string archiveClassDpName, dyn_int archiveType, dyn_int smoothProcedure,
						dyn_float deadband, dyn_float timeInterval, dyn_string &exceptionInfo, bool checkClass = TRUE) 
{
	int i, length, classCounter = 1;
	mapping classPositions;
	dyn_string localClassStore;
	dyn_dyn_string sortedClassDpes;

	if(checkClass)
	{	
		length = dynlen(dpes);
		for(i=1; i<=length; i++)
		{
			if(!mappingHasKey(classPositions, archiveClassDpName[i]))
			{
				classPositions[archiveClassDpName[i]] = classCounter;
				classCounter++;
			}
			
			dynAppend(sortedClassDpes[classPositions[archiveClassDpName[i]]], dpes[i]);

		}
		
		localClassStore = archiveClassDpName;
		length = dynUnique(localClassStore);
		for(i=1; i<=length; i++)
		{
			if(localClassStore == fwArchive_VALARCH_CLASS_DPTYPE)
			{
				fwArchive_checkClass(localClassStore[i], sortedClassDpes[classPositions[localClassStore[i]]], exceptionInfo);
				if(dynlen(exceptionInfo)>0)
					return;
			}
		}
	}
	
	_fwArchive_setMany(dpes, startArchiving, archiveClassDpName, archiveType, smoothProcedure, deadband, timeInterval, exceptionInfo); 
}

/** Sets archive config for the given dp elements and start the archiving

@par Constraints
	None

@par Usage
	Public

@par PVSS managers
	VISION, CTRL

@param dpes								list of data point elements
@param archiveClassName		name of the archive class for the config (not archive class dp name)
@param archiveType				DPATTR_ARCH_PROC_VALARCH: no smoothing,  
                   				DPATTR_ARCH_PROC_SIMPLESM: value dependent + deadband/old-new comparison smoothing 
@param smoothProcedure		DPATTR_VALUE_SMOOTH            	: value dependent,
													DPATTR_VALUE_REL_SMOOTH        	: relative value dependent,
													DPATTR_TIME_SMOOTH             	: time dependent,
													DPATTR_TIME_AND_VALUE_SMOOTH   	: value AND time dependent,
													DPATTR_TIME_AND_VALUE_REL_SMOOTH   : relative value AND time dependent,
													DPATTR_TIME_OR_VALUE_SMOOTH    	: value OR time dependent,
													DPATTR_TIME_OR_VALUE_REL_SMOOTH    : relative value OR time dependent,
													DPATTR_COMPARE_OLD_NEW         	: old-new comparison,
													DPATTR_OLD_NEW_AND_TIME_SMOOTH 	: old-new comparison AND time,
													DPATTR_OLD_NEW_OR_TIME_SMOOTH  	: old-new comparison OR time
@param deadband						archive deadband
@param timeInterval				archive time interval 
@param exceptionInfo			details of any errors are returned here
@param checkClass					Optional parameter. Default value TRUE.
														If TRUE, check class is not deleted and has enough free space.
														If FALSE skip checks.
*/
fwArchive_setMultiple(dyn_string dpes, string archiveClassName, int archiveType, int smoothProcedure,
						float deadband, float timeInterval, dyn_string &exceptionInfo, bool checkClass = TRUE) 
{
	int i, length;
	dyn_string dsArchiveClassName;
	dyn_int diArchiveType, diSmoothProcedure;
	dyn_float dfDeadband, dfTimeInterval;
	string classDpName;

	length = dynlen(dpes);
	for(i=1; i<=length; i++)
	{
		dynAppend(dsArchiveClassName, archiveClassName);
		dynAppend(diArchiveType, archiveType);
		dynAppend(diSmoothProcedure, smoothProcedure);
		dynAppend(dfDeadband, deadband);
		dynAppend(dfTimeInterval, timeInterval);
		
	}

	fwArchive_setMany(dpes, dsArchiveClassName, diArchiveType, diSmoothProcedure,
													dfDeadband, dfTimeInterval, exceptionInfo, checkClass); 
}


/** Sets archive config for the given dp elements and start the archiving

@par Constraints
	None

@par Usage
	Public

@par PVSS managers
	VISION, CTRL

@param dpes								list of data point elements.  Passed as reference only for performance reasons. Not modified.
@param archiveClassName		name of the archive class for the config (not archive class dp name)
														Passed as reference only for performance reasons. Not modified.
@param archiveType				DPATTR_ARCH_PROC_VALARCH: no smoothing,  
                   				DPATTR_ARCH_PROC_SIMPLESM: value dependent + deadband/old-new comparison smoothing 
								 Passed as reference only for performance reasons. Not modified.
@param smoothProcedure		DPATTR_VALUE_SMOOTH            	: value dependent,
													DPATTR_VALUE_REL_SMOOTH        	: relative value dependent,
													DPATTR_TIME_SMOOTH             	: time dependent,
													DPATTR_TIME_AND_VALUE_SMOOTH   	: value AND time dependent,
													DPATTR_TIME_AND_VALUE_REL_SMOOTH   : relative value AND time dependent,
													DPATTR_TIME_OR_VALUE_SMOOTH    	: value OR time dependent,
													DPATTR_TIME_OR_VALUE_REL_SMOOTH    : relative value OR time dependent,
													DPATTR_COMPARE_OLD_NEW         	: old-new comparison,
													DPATTR_OLD_NEW_AND_TIME_SMOOTH 	: old-new comparison AND time,
													DPATTR_OLD_NEW_OR_TIME_SMOOTH  	: old-new comparison OR time.
													 Passed as reference only for performance reasons. Not modified.
@param deadband						archive deadband. Passed as reference only for performance reasons. Not modified.
@param timeInterval				archive time interval  Passed as reference only for performance reasons. Not modified.
@param exceptionInfo			details of any errors are returned here
@param checkClass					Optional parameter. Default value TRUE.
														If TRUE, check class is not deleted and has enough free space.
														If FALSE skip checks.
@param activateArchiving	Optional parameter. For internal use - to configure but not start archiving, please use fwArchive_configMany.
														Default value = TRUE, archiving is started immediately.
														Else if set to FALSE archiving is configured but not started.
*/
fwArchive_setMany(dyn_string &dpes, dyn_string &archiveClassName, dyn_int &archiveType, dyn_int &smoothProcedure,
						dyn_float &deadband, dyn_float &timeInterval, dyn_string &exceptionInfo, bool checkClass = TRUE, bool activateArchiving = TRUE) 
{
	int i, length;
	string classDpName;
	dyn_string dsClassDpNames, systems;
	mapping classNameDpTranslator;
	
	length = dynlen(dpes);
	for(i=1; i<=length; i++)
		systems[i] = dpSubStr(dpes[i], DPSUB_SYS);
	
	for(i=1; i<=length; i++)
	{
		if(!mappingHasKey(classNameDpTranslator, archiveClassName[i] + systems[i]))
		{
			fwArchive_convertClassNameToDpName(archiveClassName[i], classDpName, exceptionInfo, systems[i]);
			if(dynlen(exceptionInfo)>0)
				return;
		}
		
		classNameDpTranslator[archiveClassName[i] + systems[i]] = classDpName;
	}
	
	length = dynlen(archiveClassName);
	for(i=1; i<=length; i++)
		dsClassDpNames[i] = classNameDpTranslator[archiveClassName[i] + systems[i]];

	_fwArchive_setOrConfig(dpes, activateArchiving, dsClassDpNames, archiveType, smoothProcedure,
													deadband, timeInterval, exceptionInfo, checkClass); 
}


/** Sets archive config for the given dp element and start the archiving

@par Constraints
	None

@par Usage
	Public

@par PVSS managers
	VISION, CTRL

@param dpe								data point element
@param archiveClassName		name of the archive class for the config (not archive class dp name)
@param archiveType				DPATTR_ARCH_PROC_VALARCH: no smoothing,  
                   				DPATTR_ARCH_PROC_SIMPLESM: value dependent + deadband/old-new comparison smoothing 
@param smoothProcedure		DPATTR_VALUE_SMOOTH            	: value dependent,
													DPATTR_VALUE_REL_SMOOTH        	: relative value dependent,
													DPATTR_TIME_SMOOTH             	: time dependent,
													DPATTR_TIME_AND_VALUE_SMOOTH   	: value AND time dependent,
													DPATTR_TIME_AND_VALUE_REL_SMOOTH   : relative value AND time dependent,
													DPATTR_TIME_OR_VALUE_SMOOTH    	: value OR time dependent,
													DPATTR_TIME_OR_VALUE_REL_SMOOTH    : relative value OR time dependent,
													DPATTR_COMPARE_OLD_NEW         	: old-new comparison,
													DPATTR_OLD_NEW_AND_TIME_SMOOTH 	: old-new comparison AND time,
													DPATTR_OLD_NEW_OR_TIME_SMOOTH  	: old-new comparison OR time
@param deadband						archive deadband
@param timeInterval				archive time interval 
@param exceptionInfo			details of any errors are returned here
@param checkClass					Optional parameter. Default value TRUE.
														If TRUE, check class is not deleted and has enough free space.
														If FALSE skip checks.
*/
fwArchive_set(string dpe, string archiveClassName, int archiveType, int smoothProcedure,
				float deadband, float timeInterval, dyn_string &exceptionInfo, bool checkClass = TRUE) 
{
  dyn_string dpes, archiveClassNames;
  dyn_int archiveTypes, smoothProcedures;
  dyn_float deadbands, timeIntervals;
  
  dpes[1]=dpe;
  archiveClassNames[1]=archiveClassName;
  archiveTypes[1]=archiveType;
  smoothProcedures[1]=smoothProcedure;
  deadbands[1]=deadband;
  timeIntervals[1]=timeInterval;
	fwArchive_setMany(dpes, archiveClassNames, archiveTypes, smoothProcedures,
														deadbands, timeIntervals, exceptionInfo, checkClass); 
}


/** Sets archive config for the given dp elements without starting the archiving

@par Constraints
	None

@par Usage
	Public

@par PVSS managers
	VISION, CTRL

@param dpes								list of data point elements
@param archiveClassName		name of the archive class for the config (not archive class dp name)
@param archiveType				DPATTR_ARCH_PROC_VALARCH: no smoothing,  
                   				DPATTR_ARCH_PROC_SIMPLESM: value dependent + deadband/old-new comparison smoothing 
@param smoothProcedure		DPATTR_VALUE_SMOOTH            	: value dependent,
													DPATTR_VALUE_REL_SMOOTH        	: relative value dependent,
													DPATTR_TIME_SMOOTH             	: time dependent,
													DPATTR_TIME_AND_VALUE_SMOOTH   	: value AND time dependent,
													DPATTR_TIME_AND_VALUE_REL_SMOOTH   : relative value AND time dependent,
													DPATTR_TIME_OR_VALUE_SMOOTH    	: value OR time dependent,
													DPATTR_TIME_OR_VALUE_REL_SMOOTH    : relative value OR time dependent,
													DPATTR_COMPARE_OLD_NEW         	: old-new comparison,
													DPATTR_OLD_NEW_AND_TIME_SMOOTH 	: old-new comparison AND time,
													DPATTR_OLD_NEW_OR_TIME_SMOOTH  	: old-new comparison OR time
@param deadband						archive deadband
@param timeInterval				archive time interval 
@param exceptionInfo			details of any errors are returned here
@param checkClass					Optional parameter. Default value TRUE.
														If TRUE, check class is not deleted and has enough free space.
														If FALSE skip checks.
*/
fwArchive_configMultiple(dyn_string dpes, string archiveClassName, int archiveType, int smoothProcedure,
						float deadband, float timeInterval, dyn_string &exceptionInfo, bool checkClass = TRUE) 
{
	int i, length;
	dyn_string dsArchiveClassName;
	dyn_int diArchiveType, diSmoothProcedure;
	dyn_float dfDeadband, dfTimeInterval;
	string classDpName;

	length = dynlen(dpes);
	for(i=1; i<=length; i++)
	{
		dynAppend(dsArchiveClassName, archiveClassName);
		dynAppend(diArchiveType, archiveType);
		dynAppend(diSmoothProcedure, smoothProcedure);
		dynAppend(dfDeadband, deadband);
		dynAppend(dfTimeInterval, timeInterval);
		
	}

	fwArchive_configMany(dpes, dsArchiveClassName, diArchiveType, diSmoothProcedure,
													dfDeadband, dfTimeInterval, exceptionInfo, checkClass); 
}


/** Sets archive config for the given dp elements without starting the archiving

@par Constraints
	None

@par Usage
	Public

@par PVSS managers
	VISION, CTRL

@param dpes								list of data point elements
@param archiveClassName		name of the archive class for the config (not archive class dp name)
@param archiveType				DPATTR_ARCH_PROC_VALARCH: no smoothing,  
                   				DPATTR_ARCH_PROC_SIMPLESM: value dependent + deadband/old-new comparison smoothing 
@param smoothProcedure		DPATTR_VALUE_SMOOTH            	: value dependent,
													DPATTR_VALUE_REL_SMOOTH        	: relative value dependent,
													DPATTR_TIME_SMOOTH             	: time dependent,
													DPATTR_TIME_AND_VALUE_SMOOTH   	: value AND time dependent,
													DPATTR_TIME_AND_VALUE_REL_SMOOTH   : relative value AND time dependent,
													DPATTR_TIME_OR_VALUE_SMOOTH    	: value OR time dependent,
													DPATTR_TIME_OR_VALUE_REL_SMOOTH    : relative value OR time dependent,
													DPATTR_COMPARE_OLD_NEW         	: old-new comparison,
													DPATTR_OLD_NEW_AND_TIME_SMOOTH 	: old-new comparison AND time,
													DPATTR_OLD_NEW_OR_TIME_SMOOTH  	: old-new comparison OR time
@param deadband						archive deadband
@param timeInterval				archive time interval 
@param exceptionInfo			details of any errors are returned here
@param checkClass					Optional parameter. Default value TRUE.
														If TRUE, check class is not deleted and has enough free space.
														If FALSE skip checks.
*/
fwArchive_configMany(dyn_string dpes, dyn_string archiveClassName, dyn_int archiveType, dyn_int smoothProcedure,
						dyn_float deadband, dyn_float timeInterval, dyn_string &exceptionInfo, bool checkClass = TRUE) 
{
	fwArchive_setMany(dpes, archiveClassName, archiveType, smoothProcedure,
										deadband, timeInterval, exceptionInfo, checkClass, FALSE); 
}


/** Sets archive config for the given dp element without starting the archiving

@par Constraints
	None

@par Usage
	Public

@par PVSS managers
	VISION, CTRL

@param dpe								data point element
@param archiveClassName		name of the archive class for the config (not archive class dp name)
@param archiveType				DPATTR_ARCH_PROC_VALARCH: no smoothing,  
                   				DPATTR_ARCH_PROC_SIMPLESM: value dependent + deadband/old-new comparison smoothing 
@param smoothProcedure		DPATTR_VALUE_SMOOTH            	: value dependent,
													DPATTR_VALUE_REL_SMOOTH        	: relative value dependent,
													DPATTR_TIME_SMOOTH             	: time dependent,
													DPATTR_TIME_AND_VALUE_SMOOTH   	: value AND time dependent,
													DPATTR_TIME_AND_VALUE_REL_SMOOTH   : relative value AND time dependent,
													DPATTR_TIME_OR_VALUE_SMOOTH    	: value OR time dependent,
													DPATTR_TIME_OR_VALUE_REL_SMOOTH    : relative value OR time dependent,
													DPATTR_COMPARE_OLD_NEW         	: old-new comparison,
													DPATTR_OLD_NEW_AND_TIME_SMOOTH 	: old-new comparison AND time,
													DPATTR_OLD_NEW_OR_TIME_SMOOTH  	: old-new comparison OR time
@param deadband						archive deadband
@param timeInterval				archive time interval 
@param exceptionInfo			details of any errors are returned here
@param checkClass					Optional parameter. Default value TRUE.
														If TRUE, check class is not deleted and has enough free space.
														If FALSE skip checks.
*/
fwArchive_config(string dpe, string archiveClassName, int archiveType, int smoothProcedure,
					float deadband, float timeInterval, dyn_string &exceptionInfo, bool checkClass = TRUE) 
{ 
	fwArchive_configMany(makeDynString(dpe), makeDynString(archiveClassName), makeDynInt(archiveType), makeDynInt(smoothProcedure),
														makeDynFloat(deadband), makeDynFloat(timeInterval), exceptionInfo, checkClass); 
} 


/** Returns details of the archive config on the given list of dp elements 

@par Constraints
	None

@par Usage
	Public

@par PVSS managers
	VISION, CTRL

@param dpes								the list of data point elements. Passed as reference only for performance reasons. Not modified.
@param configExists				TRUE - archive config existing, 
                   				FALSE - archive config is not existing 
@param archiveClass		name of the archive class for the config (not archive class dp name)
@param archiveType				DPATTR_ARCH_PROC_VALARCH: no smoothing,  
                   				DPATTR_ARCH_PROC_SIMPLESM: value dependent + deadband/old-new comparison smoothing 
@param smoothProcedure		DPATTR_VALUE_SMOOTH            	: value dependent,
													DPATTR_VALUE_REL_SMOOTH        	: relative value dependent,
													DPATTR_TIME_SMOOTH             	: time dependent,
													DPATTR_TIME_AND_VALUE_SMOOTH   	: value AND time dependent,
													DPATTR_TIME_AND_VALUE_REL_SMOOTH   : relative value AND time dependent,
													DPATTR_TIME_OR_VALUE_SMOOTH    	: value OR time dependent,
													DPATTR_TIME_OR_VALUE_REL_SMOOTH    : relative value OR time dependent,
													DPATTR_COMPARE_OLD_NEW         	: old-new comparison,
													DPATTR_OLD_NEW_AND_TIME_SMOOTH 	: old-new comparison AND time,
													DPATTR_OLD_NEW_OR_TIME_SMOOTH  	: old-new comparison OR time
@param deadband						archive deadband
@param timeInterval				archive time interval 
@param isActive						TRUE if archiving of this dpe is active, else FALSE
@param exceptionInfo			details of any errors are returned here
*/
fwArchive_getMany(dyn_string &dpes, dyn_bool &configExists, dyn_string &archiveClass, dyn_int &archiveType, dyn_int &smoothProcedure,
								dyn_float &deadband, dyn_float &timeInterval, dyn_bool &isActive, dyn_string &exceptionInfo)
{ 
  dyn_string localException;
	dyn_int diTmpSmoothProcedure;
  dyn_string dsDpAttr, dsAttrVal, dsTypesAttr, dsTypesVal, dsTempVal, dsDpesWithConfig;
  dyn_float dfTmpDeadband, dfTmpTimeInterval;
  int i, j, k, length;
  string configString;
  int ret;
  
  configExists = FALSE;
  archiveClass = "";
  archiveType = 0;
  smoothProcedure = 0;
  deadband = 0;
  timeInterval = 0;
  length = dynlen(dpes);
  
  configString = ":_archive..";

  //get the types of all the dpes:
  for(i=1 ; i<=length ; i++)
  {
    dynAppend(dsTypesAttr, dpes[i] + configString + "_type");
		if(dynlen(dsTypesAttr)>fwConfigs_OPTIMUM_DP_GET_SIZE || (i==length && dynlen(dsTypesAttr)>0))
		{
  	  dpGet(dsTypesAttr, dsTempVal);
      dynAppend(dsTypesVal, dsTempVal);
			dynClear(dsTypesAttr);
    }    
  }  
  
  //select only the configured dpes:
  for(i=1 ; i<=length ; i++)
  {
  	if(dsTypesVal[i]== DPCONFIG_DB_ARCHIVEINFO)
      dynAppend(dsDpesWithConfig, dpes[i]);  
  }
//   DebugN("types:\n", dsTypesVal);
  
  //for the configured dpes, get smoothing params:
  if(dynlen(dsDpesWithConfig))
    _fwSmoothing_getParameters(dsDpesWithConfig, true, diTmpSmoothProcedure, 
                               dfTmpDeadband, dfTmpTimeInterval, exceptionInfo);
  
  //for the configured dpes, get the other parameters:
  for(i=1 ; i<=length ; i++)
  {
  	switch(dsTypesVal[i])
  	{
  		case DPCONFIG_DB_ARCHIVEINFO:  
          dynAppend(dsDpAttr, dpes[i] + ":_archive.._archive");
		    	dynAppend(dsDpAttr, dpes[i] + ":_archive.1._type");
		    	dynAppend(dsDpAttr, dpes[i] + ":_archive.1._class");		    		          
      break;  
      
   		case DPCONFIG_NONE:
            configExists[i] = false;
            smoothProcedure[i] = 0;
            deadband[i] = 0;
            timeInterval[i] = 0;  
      break;         
    }
		if((dynlen(dsDpAttr) > fwConfigs_OPTIMUM_DP_SET_SIZE) || (i == length && dynlen(dsDpAttr)>0))
		{
// DebugN("dsDpAttr:",dsDpAttr);
    	  ret = dpGet(dsDpAttr, dsTempVal);  



        if(dynlen(dsTempVal)<1)
        {
//           DebugN("##############these attrs have some problem:",dsDpAttr,dynlen(dsTempVal));
          //a problem occurred: one or more dpes have incomplete smoothing settings
          //as fallback, get the dpes one by one, and report the misconfigured one(s).
          dynClear(dsTempVal);
          for(j=1 ; j<=dynlen(dsDpAttr) ; j++)
          {
//             DebugN("##############getting dpe "+j+"/"+dynlen(dsDpAttr)+": ",dsDpAttr[j]);
            dsTempVal[j] ="";
            if(dpExists(dsDpAttr[j]))
            {
     	        ret = dpGet(dsDpAttr[j], dsTempVal[j]);     
//               DebugN("##############dpe "+j+"/"+dynlen(dsDpAttr)+": ",dsDpAttr[j],"got. Return: ",ret);
            }              
            else
            {
              fwException_raise(exceptionInfo, "WARNING",
      							"fwArchive_getMany(): Could not get the setting "+dsDpAttr[j]+". Arch setting for the dpe will be flagged as none", "");
            }
            if(ret!=0)
              fwException_raise(exceptionInfo, "WARNING",
      							"fwArchive_getMany(): Could not get the setting "+dsDpAttr[j]+". Arch setting for the dpe will be flagged as none", "");
          }          
        }



        
        dynAppend(dsAttrVal, dsTempVal);
  			dynClear(dsDpAttr);
        if(ret!=0)
        {
      			fwException_raise(exceptionInfo, "ERROR",
      							"fwArchive_getMany(): Could not get the smoothing procedure for one or more dpes. See dpe list dump.", "");
            DebugTN(exceptionInfo, "Dpe list dump:", dsDpAttr);
            return;
        }         
    }
  }
// DebugN("available arch params (dsAttrVal):\n", dsAttrVal, ret);
  
  //write the parameters to the return variables:
  k=1;  
  j=1;
  for(i=1 ; i<=length ; i++)
  {
  	switch(dsTypesVal[i])
  	{
  		case DPCONFIG_DB_ARCHIVEINFO:  	  
            configExists[i] = true;
            isActive[i] = dsAttrVal[k]; k++;  
            archiveType[i] = dsAttrVal[k]; k++;  
            archiveClass[i] = dsAttrVal[k]; k++;  
            smoothProcedure[i] = diTmpSmoothProcedure[j];
            deadband[i] = dfTmpDeadband[j];
            timeInterval[i] = dfTmpTimeInterval[j];
      			fwArchive_convertDpNameToClassName(archiveClass[i], archiveClass[i], localException);
            if(dynlen(localException)>0)
            {
              if(archiveClass != "")
                fwException_raise(exceptionInfo, localException[1], localException[2], localException[3]);
            }            
            j++;
      break;  
      
   		case DPCONFIG_NONE:
            configExists[i] = false;
            isActive[i] = 0;  
            archiveType[i] = 0;  
            archiveClass[i] = "";  
            smoothProcedure[i] = 0;
            deadband[i] = 0;
            timeInterval[i] = 0;  
      break;      
      
		  default:
		  	fwException_raise(exceptionInfo, "ERROR", "fwArchive_getMany(): Archive config type (" + dsTypesVal[i] + ") for dpe '"+dpes[i]+"' not suppported", "");
			break; 
    }
  }

} 

/** Returns details of the archive config on the given dp element 

@par Constraints
	None

@par Usage
	Public

@par PVSS managers
	VISION, CTRL

@param dpe								data point element
@param configExists				TRUE - archive config existing, 
                   				FALSE - archive config is not existing 
@param archiveClass		name of the archive class for the config (not archive class dp name)
@param archiveType				DPATTR_ARCH_PROC_VALARCH: no smoothing,  
                   				DPATTR_ARCH_PROC_SIMPLESM: value dependent + deadband/old-new comparison smoothing 
@param smoothProcedure		DPATTR_VALUE_SMOOTH            	: value dependent,
													DPATTR_VALUE_REL_SMOOTH        	: relative value dependent,
													DPATTR_TIME_SMOOTH             	: time dependent,
													DPATTR_TIME_AND_VALUE_SMOOTH   	: value AND time dependent,
													DPATTR_TIME_AND_VALUE_REL_SMOOTH   : relative value AND time dependent,
													DPATTR_TIME_OR_VALUE_SMOOTH    	: value OR time dependent,
													DPATTR_TIME_OR_VALUE_REL_SMOOTH    : relative value OR time dependent,
													DPATTR_COMPARE_OLD_NEW         	: old-new comparison,
													DPATTR_OLD_NEW_AND_TIME_SMOOTH 	: old-new comparison AND time,
													DPATTR_OLD_NEW_OR_TIME_SMOOTH  	: old-new comparison OR time
@param deadband						archive deadband
@param timeInterval				archive time interval 
@param isActive						TRUE if archiving of this dpe is active, else FALSE
@param exceptionInfo			details of any errors are returned here
*/
fwArchive_get(string dpe, bool &configExists, string &archiveClass, int &archiveType, int &smoothProcedure, float &deadband, float &timeInterval, bool &isActive, dyn_string &exceptionInfo) 
{ 
    int configType;
    dyn_string localException;
  	dyn_int diTmpSmoothProcedure;
    dyn_float dfTmpDeadband, dfTmpTimeInterval;

    configExists = FALSE;
    archiveClass = "";
    archiveType = 0;
    smoothProcedure = 0;
    deadband = 0;
    timeInterval = 0;

	dpGet(dpe + ":_archive.._type", configType);	
	
	switch(configType)
	{
		case DPCONFIG_DB_ARCHIVEINFO:
			configExists = TRUE;
			
		    dpGet(	dpe + ":_archive.._archive", isActive,
		    		dpe + ":_archive.1._type", archiveType,
		    		dpe + ":_archive.1._class", archiveClass);
		    		    
			_fwSmoothing_getParameters(dpe, TRUE, diTmpSmoothProcedure, dfTmpDeadband, dfTmpTimeInterval, exceptionInfo);
			smoothProcedure=diTmpSmoothProcedure[1];
      deadband=dfTmpDeadband[1];
      timeInterval=dfTmpTimeInterval[1];
		  
      if(strlen(archiveClass))
			  fwArchive_convertDpNameToClassName(archiveClass, archiveClass, localException);
      if(dynlen(localException)>0)
      {
        if(archiveClass != "")
          fwException_raise(exceptionInfo, localException[1], localException[2], localException[3]);
      }
    	break;
			
		case DPCONFIG_NONE:
			break;
			
		default:
			fwException_raise(exceptionInfo, "ERROR", "fwArchive_get(): Archive config type (" + configType + ") not suppported", "");
			break;
	}	
} 


// old function :
/*
fwArchive_getManyOld(dyn_string &dpes, dyn_bool &configExists, dyn_string &archiveClass, dyn_int &archiveType, dyn_int &smoothProcedure,
								dyn_float &deadband, dyn_float &timeInterval, dyn_bool &isActive, dyn_string &exceptionInfo)
{
	int i, length;
	
	length = dynlen(dpes);
	for(i=1; i<=length; i++)
	{
		fwArchive_get(dpes[i], configExists[i], archiveClass[i], archiveType[i], smoothProcedure[i],
														deadband[i], timeInterval[i], isActive[i], exceptionInfo); 
	}
}*/


/** Starts archiving for the given dp elements

@par Constraints
	None

@par Usage
	Public

@par PVSS managers
	VISION, CTRL

@param dpes							list of data point elements
@param exceptionInfo		details of any errors are returned here
*/
fwArchive_startMultiple(dyn_string dpes, dyn_string &exceptionInfo) 
{
	int i, length;
	dyn_bool value;

	length = dynlen(dpes);
	for(i=1; i<=length; i++)
		dynAppend(value, TRUE);

	_fwConfigs_setConfigTypeAttribute(dpes, fwConfigs_PVSS_ARCHIVE, value, exceptionInfo, ".._archive");
}


/** Starts archiving for the given dp element

@par Constraints
	None

@par Usage
	Public

@par PVSS managers
	VISION, CTRL

@param dpe							data point element
@param exceptionInfo		details of any errors are returned here
*/
fwArchive_start(string dpe, dyn_string &exceptionInfo) 
{ 
	fwArchive_startMultiple(makeDynString(dpe), exceptionInfo);
} 


/** Stops archiving for the given dp elements

@par Constraints
	None

@par Usage
	Public

@par PVSS managers
	VISION, CTRL

@param dpes							list of data point elements
@param exceptionInfo		details of any errors are returned here
*/
fwArchive_stopMultiple(dyn_string dpes, dyn_string &exceptionInfo) 
{
	int i, length;
	dyn_bool value;

	length = dynlen(dpes);
	for(i=1; i<=length; i++)
		dynAppend(value, FALSE);

	_fwConfigs_setConfigTypeAttribute(dpes, fwConfigs_PVSS_ARCHIVE, value, exceptionInfo, ".._archive");
}


/** Stops archiving for the given dp element

@par Constraints
	None

@par Usage
	Public

@par PVSS managers
	VISION, CTRL

@param dpe							data point element
@param exceptionInfo		details of any errors are returned here
*/
fwArchive_stop(string dpe, dyn_string &exceptionInfo) 
{ 
	fwArchive_stopMultiple(makeDynString(dpe), exceptionInfo);
} 


/** Sets archive config for the given dp element
NOTE: This function requires the dp name of the archiving class.  It will not perform the search for the dp name from a given archive class name.
NOTE: This function does not check that the chosen archive class has enough free space, nor if the class has been deleted

@par Constraints
	None

@par Usage
	Internal

@par PVSS managers
	VISION, CTRL

@param dpe								data point element
@param startArchive				true in order to start the archive immediately, false in order to ONLY configure it
@param archiveClassDpName	the dp name of the archiving class to be used
@param archiveType				DPATTR_ARCH_PROC_VALARCH: no smoothing,  
                   				DPATTR_ARCH_PROC_SIMPLESM: value dependent + deadband/old-new comparison smoothing 
@param smoothProcedure		DPATTR_VALUE_SMOOTH            	: value dependent,
													DPATTR_VALUE_REL_SMOOTH        	: relative value dependent,
													DPATTR_TIME_SMOOTH             	: time dependent,
													DPATTR_TIME_AND_VALUE_SMOOTH   	: value AND time dependent,
													DPATTR_TIME_AND_VALUE_REL_SMOOTH   : relative value AND time dependent,
													DPATTR_TIME_OR_VALUE_SMOOTH    	: value OR time dependent,
													DPATTR_TIME_OR_VALUE_REL_SMOOTH    : relative value OR time dependent,
													DPATTR_COMPARE_OLD_NEW         	: old-new comparison,
													DPATTR_OLD_NEW_AND_TIME_SMOOTH 	: old-new comparison AND time,
													DPATTR_OLD_NEW_OR_TIME_SMOOTH  	: old-new comparison OR time
@param deadband						archive deadband
@param timeInterval				archive time interval 
@param exceptionInfo			details of any errors are returned here
*/
_fwArchive_set(string dpe, bool startArchive, string archiveClassDpName, int archiveType, int smoothProcedure, float deadband, float timeInterval, dyn_string &exceptionInfo) 
{ 
	_fwArchive_setMany(makeDynString(dpe), startArchive, makeDynString(archiveClassDpName), makeDynInt(archiveType),
											makeDynInt(smoothProcedure), makeDynFloat(deadband), makeDynFloat(timeInterval), exceptionInfo);
} 

/** Sets archive config for the given dp elements
NOTE: This function requires the dp name of the archiving class.  It will not perform the search for the dp name from a given archive class name.
NOTE: This function does not check that the chosen archive class has enough free space, nor if the class has been deleted

@par Constraints
	None

@par Usage
	Internal

@par PVSS managers
	VISION, CTRL

@param dpes								data point elements
@param startArchive				true in order to start the archive immediately, false in order to ONLY configure it
@param archiveClassDpName	the dp name of the archiving class to be used
@param archiveType				DPATTR_ARCH_PROC_VALARCH: no smoothing,  
                   				DPATTR_ARCH_PROC_SIMPLESM: value dependent + deadband/old-new comparison smoothing 
@param smoothProcedure		DPATTR_VALUE_SMOOTH            	: value dependent,
													DPATTR_VALUE_REL_SMOOTH        	: relative value dependent,
													DPATTR_TIME_SMOOTH             	: time dependent,
													DPATTR_TIME_AND_VALUE_SMOOTH   	: value AND time dependent,
													DPATTR_TIME_AND_VALUE_REL_SMOOTH   : relative value AND time dependent,
													DPATTR_TIME_OR_VALUE_SMOOTH    	: value OR time dependent,
													DPATTR_TIME_OR_VALUE_REL_SMOOTH    : relative value OR time dependent,
													DPATTR_COMPARE_OLD_NEW         	: old-new comparison,
													DPATTR_OLD_NEW_AND_TIME_SMOOTH 	: old-new comparison AND time,
													DPATTR_OLD_NEW_OR_TIME_SMOOTH  	: old-new comparison OR time
@param deadband						archive deadband
@param timeInterval				archive time interval 
@param exceptionInfo			details of any errors are returned here
*/
_fwArchive_setMany(dyn_string dpes, bool startArchive, dyn_string archiveClassDpName, dyn_int archiveType, dyn_int smoothProcedure, dyn_float deadband, dyn_float timeInterval, dyn_string &exceptionInfo) 
{ 
	int i, length, numberOfAttributes;
	string dpeSystem;
	dyn_errClass errors;
	dyn_string attributesToSet, smoothingDpes;
	dyn_anytype valuesToSet;
	dyn_int smoothingProcedures;
	dyn_float smoothingDeadbands, smoothingTimeIntervals;

	length = dynlen(dpes);
	for(i=1; i<=length; i++)
	{
		dynAppend(attributesToSet, dpes[i] + ":_archive.._type");
		dynAppend(attributesToSet, dpes[i] + ":_archive.._archive");
		dynAppend(attributesToSet, dpes[i] + ":_archive.1._class");
		dynAppend(attributesToSet, dpes[i] + ":_archive.1._type");

		dynAppend(valuesToSet, DPCONFIG_DB_ARCHIVEINFO);
		dynAppend(valuesToSet, startArchive);
//DebugN(startArchive);
		dpeSystem = dpSubStr(dpes[i], DPSUB_SYS);
		if(strpos(archiveClassDpName[i], dpeSystem) != 0)
			archiveClassDpName[i] = dpeSystem + archiveClassDpName[i];
		dynAppend(valuesToSet, archiveClassDpName[i]);
		
		numberOfAttributes = dynAppend(valuesToSet, archiveType[i]);
		
		if(archiveType[i] == DPATTR_ARCH_PROC_SIMPLESM)
		{
			dynAppend(smoothingDpes, dpes[i]);
			dynAppend(smoothingProcedures, smoothProcedure[i]);
			dynAppend(smoothingDeadbands, deadband[i]);
			dynAppend(smoothingTimeIntervals, timeInterval[i]);
		}
		
		if((numberOfAttributes > fwConfigs_OPTIMUM_DP_SET_SIZE) || (i == length))
		{
//DebugN(attributesToSet, valuesToSet);
			dpSetWait(attributesToSet, valuesToSet);
			errors = getLastError(); 
    	if(dynlen(errors) > 0)
    	{ 
	 			throwError(errors);
		 		fwException_raise(exceptionInfo, "ERROR", "_fwArchive_setMany(): Could not create archiving configs", "");
			}
			dynClear(attributesToSet);
			dynClear(valuesToSet);
		}
	}

	_fwSmoothing_setParameters(smoothingDpes, TRUE, smoothingProcedures, smoothingDeadbands, smoothingTimeIntervals, exceptionInfo);
} 


/** Finds the _ValueArchive DP name corresponding to the given archive class name

@par Constraints
	None

@par Usage
	Public

@par PVSS managers
	VISION, CTRL

@param archiveClassName		name of the archive class
@param archiveDpName			dp name of the archive class _ValueArchive data point is returned here
@param exceptionInfo			details of any errors are returned here
@param searchSystem		OPTIONAL PARAMETER - default value is "" (search local system)
					The system on which to perform the lookup of the archive class name
*/
fwArchive_convertClassNameToDpName(string archiveClassName, string &archiveDpName, dyn_string &exceptionInfo, string searchSystem = "")
{
	int i, length;
	string query, dpName;
	dyn_string localException;
	dyn_dyn_anytype queryResult;

	archiveDpName = "";
        
	if(searchSystem == "")
		searchSystem = getSystemName();

	if(strpos(searchSystem, ":") != (strlen(searchSystem) -1))
		searchSystem += ":";

	if(strpos(archiveClassName, "RDB") == 0)
		fwArchive_convertRDBClassNameToDpName(archiveClassName, archiveDpName, localException, searchSystem);
	if(archiveDpName != "")
	{
		if(dynlen(localException) > 0)
			fwException_raise(exceptionInfo, localException[1], localException[2], localException[3]);
		return;
	}
	
	query = "SELECT '.general.arName:_online.._value', '.state:_online.._value' FROM '*' REMOTE '" + searchSystem + "' WHERE _DPT = \""
					+ fwArchive_VALARCH_CLASS_DPTYPE + "\" AND '.general.arName:_online.._value' LIKE \""
					+ archiveClassName + "\"" + " AND '.state:_online.._value' != " + fwArchive_CLASS_DELETED;

	dpQuery(query, queryResult);

	for(i=2; i<=dynlen(queryResult); i++)
	{
		if(isReduDp(queryResult[i][1]))
		{
			dynRemove(queryResult, i);
			i--;
		}
	}

	length = dynlen(queryResult);
	if(length > 2)
		fwException_raise(exceptionInfo, "WARNING", "Could not determine a unique Archive Class data point name.", "");
	else if(length < 2)
	{
		fwException_raise(exceptionInfo, "ERROR", "Could not find an Archive Class data point for the class \"" + archiveClassName +  "\".", "");
		return;
	}
	
	archiveDpName = queryResult[2][1];
}

/** Finds the archive class name corresponding to the given _ValueArchive DP

@par Constraints
	None

@par Usage
	Public

@par PVSS managers
	VISION, CTRL

@param archiveDpName			dp name of the archive class _ValueArchive data point
@param archiveClassName		name of the archive class is returned here
@param exceptionInfo			details of any errors are returned here
*/
fwArchive_convertDpNameToClassName(string archiveDpName, string &archiveClassName, dyn_string &exceptionInfo)
{
	dyn_string localException;

	archiveClassName = "";
  if(archiveDpName == "")
  { 
    archiveClassName = ""; 
    return; 
  } 
	if(dpTypeName(archiveDpName) == "_RDBArchiveGroups")
		fwArchive_convertDpNameToRDBClassName(archiveDpName, archiveClassName, localException);
	if(archiveClassName != "")
	{
		if(dynlen(localException) > 0)
			fwException_raise(exceptionInfo, localException[1], localException[2], localException[3]);
		return;
	}

	if(dpExists(archiveDpName +".general.arName"))
	 	dpGet(archiveDpName +".general.arName", archiveClassName);
	else
	{
		archiveClassName = "";
		fwException_raise(exceptionInfo, "ERROR",
							"fwArchive_convertDpNameToClassName(): Archive class not found for dp " + archiveDpName, "");
	}
}


/** Checks the given archive class to ensure the class has not been deleted and has enough free 
space to configure a given number of archiving configs

@par Constraints
	None

@par Usage
	Public

@par PVSS managers
	VISION, CTRL

@param archiveClassDpName		dp name of the archive class _ValueArchive data point to check
@param dpesToAdd						a list of data point elements you wish to configure with the given class
@param exceptionInfo				details of any errors are returned here
*/
fwArchive_checkClass(string archiveClassDpName, dyn_string dpesToAdd, dyn_string &exceptionInfo)
{
	dyn_bool areArchived;
	int state, freeSpace, numberOfDpesToAdd;
	string stateText;

	numberOfDpesToAdd = dynlen(dpesToAdd);

	fwArchive_getClassState(archiveClassDpName, state, stateText, exceptionInfo);
	if(dynlen(exceptionInfo)>0)
		return;
		
	if(state == fwArchive_CLASS_DELETED)
	{
		fwException_raise(exceptionInfo, "ERROR", "fwArchive_checkClass: Archive Class (" + archiveClassDpName + ") has been deleted", "");
		return;
	}
	
	fwArchive_getClassFreeSpace(archiveClassDpName, freeSpace, exceptionInfo);
	if(dynlen(exceptionInfo)>0)
		return;

	if(freeSpace < numberOfDpesToAdd)
	{
		fwArchive_checkDpesArchived(archiveClassDpName, dpesToAdd, areArchived, exceptionInfo);
		if(dynContains(areArchived, FALSE))
		{
			fwException_raise(exceptionInfo, "ERROR", "fwArchive_checkClass: Archive Class (" + archiveClassDpName + ") does not have enough free space", "");
			return;
		}
	}
}


/** Gets the state of the given archive class

@par Constraints
	None

@par Usage
	Public

@par PVSS managers
	VISION, CTRL

@param archiveClassDpName		dp name of the archive class _ValueArchive data point to check
@param archiveState					the archive state is returned here
															fwArchive_CLASS_STOPPED		= Archive manager not running
															fwArchive_CLASS_ONLINE		= Archive manager running
															fwArchive_CLASS_SWAPPED_OUT	= Archive is currently swapped out
															fwArchive_CLASS_DELETED		= Archive has been deleted
@param archiveStateText			a text representation of the state is returned here
@param exceptionInfo				details of any errors are returned here
*/
fwArchive_getClassState(string archiveClassDpName, int &archiveState, string &archiveStateText, dyn_string &exceptionInfo)
{
	if(dpExists(archiveClassDpName +".state"))
	{
	 	dpGet(archiveClassDpName +".state", archiveState);

		switch(archiveState)
		{
			case fwArchive_CLASS_STOPPED:
				archiveStateText = "Stopped";
				break;
			case fwArchive_CLASS_ONLINE:
				archiveStateText = "Online";
				break;
			case fwArchive_CLASS_SWAPPED_OUT:
				archiveStateText = "Swapped Out";
				break;
			case fwArchive_CLASS_DELETED:
				archiveStateText = "Deleted";
				break;
			default:
				archiveStateText = "Unknown";
				break;
		}
	}
	else
	{
		archiveState = 0;
		archiveStateText = "";
		fwException_raise(exceptionInfo, "ERROR",
							"fwArchive_getClassState(): Archive dp (" + archiveClassDpName + ") not found", "");
	}
}

/** Gets the statistics of the given archive class

@par Constraints
	None

@par Usage
	Public

@par PVSS managers
	VISION, CTRL

@param archiveClassDpName		dp name of the archive class _ValueArchive data point to check
@param currentDpes					the number of dpes currently in the archive is returned here
@param dpesAfterFileSwitch	the number of dpes that will be in the archive after a file switch is returned here
@param maximumDpes					the maximum number of dpes for this class is returned here
@param exceptionInfo				details of any errors are returned here
@param refreshClass					Optional parameter.  Default value TRUE.
															If TRUE, force class to refresh statistics before getting values (maybe slow)
															If FALSE, get current values which may be out of date
*/
fwArchive_getClassStatistics(string archiveClassDpName, int &currentDpes, int &dpesAfterFileSwitch,
								int &maximumDpes, dyn_string &exceptionInfo, bool refreshClass = TRUE)
{
	int i=0, currentNumber, state;
	dyn_string ds;
	string stateText;

	fwArchive_getClassState(archiveClassDpName, state, stateText, exceptionInfo);
	if(state == fwArchive_CLASS_STOPPED)
	{
		refreshClass = FALSE;
		fwException_raise(exceptionInfo, "WARNING",
							"fwArchive_getClassStatistics(): Archive manager is stopped.  Could not update class statistics.", "");
	}

	if(dpExists(archiveClassDpName +".statistics.dpElements"))
	{	
		if(refreshClass)
		{
			fwArchive_REFRESH_IN_PROGRESS = FALSE;
			dpConnect("_fwArchive_flagEndOfRefresh", FALSE, archiveClassDpName + ".statistics.dpElements:_online.._stime");
		
			dpGet(archiveClassDpName+".files.fileName",ds);
			dpSet(archiveClassDpName+".statistics.index",dynlen(ds));

			for(i=0; (i <= 100) && (fwArchive_REFRESH_IN_PROGRESS == FALSE); i++)
			{
				delay(0,100);
			}
			
			if(i >= 100)
			{
				fwException_raise(exceptionInfo, "WARNING",
									"fwArchive_getClassStatistics(): Update of archive items timed out.  Statistics may not be up to date.", "");
			}
		}
		
		dpGet(archiveClassDpName+".statistics.dpValues",ds,
					archiveClassDpName+".size.maxDpElGet", maximumDpes,
					archiveClassDpName+".statistics.dpElementCount", currentDpes);

		dpesAfterFileSwitch = dynlen(ds);		
	}
	else
	{
		freeSpace = 0;
		fwException_raise(exceptionInfo, "ERROR",
							"fwArchive_getClassStatistics(): Archive dp (" + archiveClassDpName + ") not found", "");
	}
}


/** Gets the amount of additional data point elements that can be added to a given archive class
The value returned is based on the number of dpes in the archive currently, not the number after the next file switch

@par Constraints
	None

@par Usage
	Public

@par PVSS managers
	VISION, CTRL

@param archiveClassDpName		dp name of the archive class _ValueArchive data point to check
@param freeSpace						the number of dpes that can be added to the archive is returned here
@param exceptionInfo				details of any errors are returned here
@param refreshClass					Optional parameter.  Default value TRUE.
															If TRUE, force class to refresh statistics before getting values (maybe slow)
															If FALSE, get current values which may be out of date
*/
fwArchive_getClassFreeSpace(string archiveClassDpName, int &freeSpace, dyn_string &exceptionInfo, bool refreshClass = TRUE)
{
	int currentNumber, afterFileSwitchNumber, maxSize;

	fwArchive_getClassStatistics(archiveClassDpName, currentNumber, afterFileSwitchNumber, maxSize, exceptionInfo, refreshClass);

	freeSpace = maxSize - currentNumber;
}


/** This function can be used to check if a given list of dpes are correctly configured to be archived by a given archive manager.
Sometimes, if an archive class is full and more data point elements are added without checking for errors, the additional data points
are not added to the archive class (even though the config appears correct) and only a log messages indicates this failure.
This function can be used to check that the data point elements are really going to be archived.

@par Constraints
	None

@par Usage
	Public

@par PVSS managers
	VISION, CTRL

@param archiveClassDpName		dp name of the archive class _ValueArchive data point to check
@param dpesToCheck					the list of dpes that you wish to check are correctly configured for the given archive class
@param areArchived					list of booleans relating to dpes in dpesToCheck.  TRUE = archived, FALSE = not archived
@param exceptionInfo				details of any errors are returned here
*/
fwArchive_checkDpesArchived(string archiveClassDpName, dyn_string dpesToCheck, dyn_bool &areArchived, dyn_string &exceptionInfo)
{
	int i, length;
	dyn_string currentDpes;

	if(dpExists(archiveClassDpName +".statistics.dpElements"))
	{
	 	dpGet(archiveClassDpName +".statistics.dpElements", currentDpes);

		length = dynlen(dpesToCheck);
		for(i=1; i<=length; i++)
		{
			dpesToCheck[i] = dpSubStr(dpesToCheck[i], DPSUB_SYS) + dpSubStr(dpesToCheck[i], DPSUB_DP_EL);
//DebugN(dpesToCheck[i]);
			areArchived[i] = (dynContains(currentDpes, dpesToCheck[i])>0);
		}		
	}
	else
	{
		dynClear(areArchived);
		fwException_raise(exceptionInfo, "ERROR",
							"fwArchive_checkDpesArchived(): Archive dp (" + archiveClassDpName + ") not found", "");
	}
}


/** Work function used to flag the end of a refresh of the archive class statistics

@par Constraints
	Should only be used as a work function to signal the end of a statistical refresh of an archive class

@par Usage
	Internal

@par PVSS managers
	VISION, CTRL

@param dpe		name of the data point element connected to (archiveClassDpName + ".statistics.dpElements:_online.._stime")
@param value	the time of the latest update of the datapoint element connected to
*/
_fwArchive_flagEndOfRefresh(string dpe, int value)
{
	string dpName;

	fwArchive_REFRESH_IN_PROGRESS = TRUE;

	dpName = dpSubStr(dpe, DPSUB_SYS_DP);
	dpDisconnect("_fwArchive_flagEndOfRefresh", dpName + ".statistics.dpElements:_online.._stime");
}


/** Finds the RDB archive class name corresponding to the given _RDBArchiveGroups DP

@par Constraints
	Only works for RDB archiving classes - not traditional _ValueArchive classes

@par Usage
	Public

@par PVSS managers
	VISION, CTRL

@param rdbArchiveGroupDpName	dp name of the RDB archive group _RDBArchiveGroups data point
@param rdbClassName						name of the archive class is returned here
@param exceptionInfo					details of any errors are returned here
*/
fwArchive_convertDpNameToRDBClassName(string rdbArchiveGroupDpName, string &rdbClassName, dyn_string &exceptionInfo)
{	
	bool isAlert;
	int managerNumber;
	string className;
	dyn_string rdbDpTypes;
	
	rdbClassName = "";
	
	rdbDpTypes = dpTypes(fwArchive_RDB_CLASS_DPTYPE);
	if(dynlen(rdbDpTypes) <= 0)
	{
		fwException_raise(exceptionInfo, "ERROR", "The RDB Archive Group data point type does not exist.", "");
		return;
	} 
	
	if(!dpExists(rdbArchiveGroupDpName))
	{
		fwException_raise(exceptionInfo, "ERROR", "The data point \"" + rdbArchiveGroupDpName + "\" does not exist.", "");
		return;
	}
	
	if(dpTypeName(rdbArchiveGroupDpName) != fwArchive_RDB_CLASS_DPTYPE)
	{
		fwException_raise(exceptionInfo, "ERROR", "The data point \"" + rdbArchiveGroupDpName + "\" is not of type \"" + fwArchive_RDB_CLASS_DPTYPE + "\".", "");
		return;
	}
	
	dpGet(rdbArchiveGroupDpName + ".isAlert", isAlert,
				rdbArchiveGroupDpName + ".managerNr", managerNumber,
				rdbArchiveGroupDpName + ".groupName", className);
	
	rdbClassName = "RDB-" + (managerNumber + fwArchive_MANAGER_NUMBER_OFFSET) + ") " + className;

	if(isAlert)
		fwException_raise(exceptionInfo, "WARNING", "The data point \"" + rdbArchiveGroupDpName + "\" is an alert archiving group.", "");
}


/** Finds the _RDBArchiveGroups DP name corresponding to the given RDB archive class name

@par Constraints
	Only works for RDB archiving classes - not traditional _ValueArchive classes
	The RDB archive class name must be given as displayed in the PVSS panels - e.g.  RDB-XX) GroupName

@par Usage
	Public

@par PVSS managers
	VISION, CTRL

@param rdbClassName							name of the RDB archive class
@param rdbArchiveGroupDpName		dp name of the RDB archive group _RDBArchiveGroups data point is returned here
@param exceptionInfo						details of any errors are returned here
@param searchSystem		OPTIONAL PARAMETER - default value is "" (search local system)
					The system on which to perform the lookup of the archive class name
*/
fwArchive_convertRDBClassNameToDpName(string rdbClassName, string &rdbArchiveGroupDpName, dyn_string &exceptionInfo, string searchSystem = "")
{
	bool isAlert;
	int pos1, pos2, managerNumber, length;
	string query, className;
	dyn_string rdbDpTypes;
	dyn_dyn_anytype queryResult;

	rdbArchiveGroupDpName = "";

	if(searchSystem == "")
		searchSystem = getSystemName();

	if(strpos(searchSystem, ":") != (strlen(searchSystem) -1))
		searchSystem += ":";

	rdbDpTypes = dpTypes(fwArchive_RDB_CLASS_DPTYPE);
	if(dynlen(rdbDpTypes) <= 0)
	{
		fwException_raise(exceptionInfo, "ERROR", "The RDB Archive Group data point type does not exist.", "");
		return;
	}
	
	if(rdbClassName == "")
	{
		fwException_raise(exceptionInfo, "ERROR", "You must specify an RDB archive class name.", "");
		return;
	}

	pos1 = strpos(rdbClassName, " ");
	if(pos1 == 7) //expected place of space in the string
		className = substr(rdbClassName, pos1 + 1);
	else
	{
		fwException_raise(exceptionInfo, "ERROR", "The RDB Class must be in the form \"RDB-XX) GroupName\".", "");
		return;
	}

	pos1 = strpos(rdbClassName, "-");
	pos2 = strpos(rdbClassName, ")");
	if((pos1 == 3) && (pos2 == 6)) //expected pos of - and ) in the string
		managerNumber = substr(rdbClassName, pos1 + 1, pos2 + 1);
	else
	{
		fwException_raise(exceptionInfo, "ERROR", "The RDB Class must be in the form \"RDB-XX) GroupName\".", "");
		return;
	}
	
	managerNumber -= fwArchive_MANAGER_NUMBER_OFFSET;
	
	query = "SELECT '.managerNr:_online.._value', '.groupName:_online.._value', '.isAlert:_online.._value' FROM '*' REMOTE '"
					+ searchSystem + "' WHERE _DPT = \"" + fwArchive_RDB_CLASS_DPTYPE
					+ "\" AND '.managerNr:_online.._value' == " + managerNumber
					+ " AND '.groupName:_online.._value' == \"" + className + "\"";
	
	dpQuery(query, queryResult);

	length = dynlen(queryResult);
	if(length > 2)
		fwException_raise(exceptionInfo, "WARNING", "Could not determine a unique RDB Archive Group data point name.", "");
	else if(length < 2)
	{
		fwException_raise(exceptionInfo, "ERROR", "The RDB Class \"" + rdbClassName +  "\" does not exist.", "");
		return;
	}
	
	rdbArchiveGroupDpName = queryResult[2][1];
	isAlert = queryResult[2][4];
	if(isAlert)
		fwException_raise(exceptionInfo, "WARNING", "The RDB class \"" + rdbClassName + "\" is an alert archiving group.", "");
}


/** Finds all the NOT DELETED Value Archive classes and
		returns the class names (for display) and the class dps (for writing to the config)

@par Constraints
	None
	
@par Usage
	Public

@par PVSS managers
	VISION, CTRL

@param readFromSystems			The systems to read from - the list of classes returned is only those classes
															that are available on every one of the named systems
@param archiveClasses				The list of archive class names is returned here
@param archiveClassDps			The list of _ValueArchive data point names is returned here
@param exceptionInfo				Details of any errors are returned here
*/
fwArchive_getAllValueArchiveClasses(dyn_string readFromSystems, dyn_string &archiveClasses, dyn_string &archiveClassDps, dyn_string &exceptionInfo)
{
	int i, j, numberOfResults, length;
	string query;
	dyn_dyn_anytype queryResult;
	dyn_dyn_string allClasses, allDps;

	archiveClasses = makeDynString();
	archiveClassDps = makeDynString();

	length = dynlen(readFromSystems);
	if(length == 0)
		length = dynAppend(readFromSystems, getSystemName());

	for(i=1; i<=length; i++)
	{
		allDps[i] = makeDynString();
		allClasses[i] = makeDynString();

		if(strpos(readFromSystems[i], ":") != (strlen(readFromSystems[i]) -1))
			readFromSystems[i] += ":";

		if(dynlen(dpNames(readFromSystems[i] + "*", fwArchive_VALARCH_CLASS_DPTYPE)) == 0)
			continue;
//DebugN("Still running", readFromSystems[i]);

		query = "SELECT '.general.arName:_online.._value', '.state:_online.._value' FROM '*' REMOTE '"
						+ readFromSystems[i] + "' WHERE _DPT = \""
						+ fwArchive_VALARCH_CLASS_DPTYPE + "\" AND '.state:_online.._value' != " + fwArchive_CLASS_DELETED;

		dpQuery(query, queryResult);

//DebugN(queryResult);
		numberOfResults = dynlen(queryResult);
		for(j=2; j<=numberOfResults; j++)
		{
			if(!isReduDp(queryResult[j][1]))
			{
				if(length == 1)
					dynAppend(allDps[i], queryResult[j][1]);
				else
					dynAppend(allDps[i], dpSubStr(queryResult[j][1], DPSUB_DP));
				
				dynAppend(allClasses[i], queryResult[j][2]);
			}
		}
//DebugN(allDps[i], allClasses[i]);
	}

	for(i=2; i<=length; i++)
	{
		allDps[1] = dynIntersect(allDps[1], allDps[i]);
		allClasses[1] = dynIntersect(allClasses[1], allClasses[i]);
	}
	
	archiveClasses = allClasses[1];
	archiveClassDps = allDps[1];
}


/** Finds all the RDB Archiving Group classes and
		returns the class names (for display) and the group dps (for writing to the config)

@par Constraints
	None
	
@par Usage
	Public

@par PVSS managers
	VISION, CTRL

@param readFromSystems			The systems to read from - the list of classes returned is only those classes
															that are available on every one of the named systems
@param archiveClasses				The list of RDB archive group names is returned here
@param archiveGroupDps			The list of _RDBArchiveGroups data point names is returned here
@param exceptionInfo				Details of any errors are returned here
@param includeAlertGroups		OPTIONAL PARAMETER - default value = FALSE
														If set to FALSE, only EVENT archive groups are returned
														If set to TRUE, both EVENT and ALERT archive groups are returned
*/
fwArchive_getAllRDBArchiveClasses(dyn_string readFromSystems, dyn_string &archiveClasses, dyn_string &archiveGroupDps, dyn_string &exceptionInfo, bool includeAlertGroups = FALSE)
{
	int i, j, numberOfResults, length;
	string query;
	dyn_string rdbDpTypes;
	dyn_dyn_anytype queryResult;
	dyn_dyn_string allClasses, allDps;

	archiveClasses = makeDynString();
	archiveGroupDps = makeDynString();

	rdbDpTypes = dpTypes(fwArchive_RDB_CLASS_DPTYPE);
	if(dynlen(rdbDpTypes) <= 0)
	{
		fwException_raise(exceptionInfo, "ERROR", "The RDB Archive Group data point type does not exist.", "");
		return;
	} 

	length = dynlen(readFromSystems);
	if(length == 0)
		length = dynAppend(readFromSystems, getSystemName());
		
	for(i=1; i<=length; i++)
	{
		allDps[i] = makeDynString();
		allClasses[i] = makeDynString();

		if(strpos(readFromSystems[i], ":") != (strlen(readFromSystems[i]) -1))
			readFromSystems[i] += ":";

		if(dynlen(dpNames(readFromSystems[i] + "*", fwArchive_RDB_CLASS_DPTYPE)) == 0)
			continue;
//DebugN("Still running", readFromSystems[i]);

		query = "SELECT '.managerNr:_online.._value', '.groupName:_online.._value', '.isAlert:_online.._value' FROM '*' REMOTE '" 
						+ readFromSystems[i] + "' WHERE _DPT = \""
						+ fwArchive_RDB_CLASS_DPTYPE + "\"";
		
		if(!includeAlertGroups)
			query += " AND '.isAlert:_online.._value' == 0";
			
		dpQuery(query, queryResult);
//DebugN(queryResult);	
		numberOfResults = dynlen(queryResult);
		for(j=2; j<=numberOfResults; j++)
		{
			if(length == 1)
				dynAppend(allDps[i], queryResult[j][1]);
			else
				dynAppend(allDps[i], dpSubStr(queryResult[j][1], DPSUB_DP));

			dynAppend(allClasses[i], "RDB-" + (queryResult[j][2] + fwArchive_MANAGER_NUMBER_OFFSET) + ") " + queryResult[j][3]);
		}
//DebugN(allDps[i], allClasses[i]);
	}
			
	for(i=2; i<=length; i++)
	{
		allDps[1] = dynIntersect(allDps[1], allDps[i]);
		allClasses[1] = dynIntersect(allClasses[1], allClasses[i]);
	}
	
	archiveClasses = allClasses[1];
	archiveGroupDps = allDps[1];
}

//@}


