//////////////////////////////////////////////////////////
/** This function creates a component description file (xml).

@param pathName						(in) path for the output file {if empty, only create xmlDesc}
@param componentName			(in) name of the component {required} 
@param componentVersion		(in) version number of the component {required} 
@param componentDate			(in) date of the component {will set current date if empty}
@param requiredComponents	(in) list of required components (componentName=minimalVersionNumber)
@param isSubComponent			(in) TRUE if subcomponent
@param initScripts				(in) scripts to be run during installation 
@param deleteScripts			(in) scripts to be run during deletion 
@param postInstallScripts	(in) scripts to be run after installation and subsequent restart {
@param postDeleteScripts	(in) scripts to be run after deletion and subsequent restart 
@param configFiles				(in) config files for the project {need to be in ./config/, do not specify path}
@param asciiFiles			  	(in) dplist files for the project {need to be in ./dplist/, do not specify path}
@param panelFiles					(in) panel files for the project {need to be in ./panels/, do only specify sub-path}
@param scriptFiles				(in) script files for the project {need to be in ./scripts/, do only specify sub-path}
@param libraryFiles				(in) library files for the project {need to be in ./scripts/libs/, do only specify sub-path}
@param otherFiles					(in) miscellaneous files for the project {do only specify sub-path from PROJ_PATH}
@param dontRestartProject					(in) flag indicating if the restart of the project can be omitted after the installation of the component
@param xmlDesc						(out) complete xml description
@return 0 - xml file created, -1 - file creation failed, -2 - parameters missing
@author Sascha Schmeling and Fernando Varela.
*/
int fwInstallationXml_create(	string pathName,
                              string componentName,
                              string componentVersion,
                              string componentDate,
                              dyn_string requiredComponents,
                              bool isSubComponent,
                              dyn_string initScripts, 
                              dyn_string deleteScripts,
                              dyn_string postInstallScripts, 
                              dyn_string postDeleteScripts,
                              dyn_string configFiles,
                              dyn_string asciiFiles,
                              dyn_string panelFiles,
                              dyn_string scriptFiles,
                              dyn_string libraryFiles,
                              dyn_string otherFiles,
                              string dontRestartProject,
                              dyn_string & xmlDesc)
{
  

  fwInstallation_flagDeprecated("fwInstallationXml_create", "fwInstallationXml_createComponentFile");  
  
//	dyn_string xmlDesc;
	dynClear(xmlDesc);
	
	time now = getCurrentTime();
	
	dynClear(xmlDesc);

	if(requiredComponents =="")
		dynClear(requiredComponents);
	if(initScripts =="")
		dynClear(initScripts);
	if(deleteScripts =="")
		dynClear(deleteScripts);
	if(postInstallScripts =="")
		dynClear(postInstallScripts);
	if(postDeleteScripts =="")
		dynClear(postDeleteScripts);
	if(configFiles =="")
		dynClear(configFiles);
	if(asciiFiles =="")
		dynClear(asciiFiles);
	if(panelFiles =="")
		dynClear(panelFiles);
	if(scriptFiles =="")
		dynClear(scriptFiles);
	if(libraryFiles =="")
		dynClear(libraryFiles);
	if(otherFiles =="")
		dynClear(otherFiles);

	if(componentName == "")
	{
		DebugTN("Your component should have a name!");
		return -2;		
	}
	if(componentVersion == "")
	{
		DebugTN("Your component should have a version number!");
		return -2;
	}

// build xml code	
	dynAppend(xmlDesc, "<component>");
// component name
	dynAppend(xmlDesc, "<name>" + componentName + "</name>");
// component version
	dynAppend(xmlDesc, "<version>" + componentVersion + "</version>");
// release date
	if(componentDate == "")
		componentDate = year(now)+"/"+month(now)+"/"+day(now);
	dynAppend(xmlDesc, "<date>" + componentDate + "</date>");

// required components
	if(dynlen(requiredComponents) > 0)
		for(int i=1; i<=dynlen(requiredComponents); i++)
			dynAppend(xmlDesc, "<required>"+requiredComponents[i]+"</required>");

// sub-component?
	if(isSubComponent == TRUE)
		dynAppend(xmlDesc, "<subcomponent>yes</subcomponent>");

//avoid project restart:        
	if(strtolower(dontRestartProject) == "yes")
		dynAppend(xmlDesc, "<dontRestartProject>yes</dontRestartProject>");

////////////////FVR: Move init and post install scripts to scripts folder according to the FW Guidelines.
// init script(s)
	if(dynlen(initScripts) > 0)
          		for(int i=1; i<=dynlen(initScripts); i++){
			  //dynAppend(xmlDesc, "<init>./config/"+initScripts[i]+"</init>");
    if(!patternMatch("./scripts/" + componentName + "/*", initScripts[i]))
      dynAppend(xmlDesc, "<init>./scripts/" + componentName + "/" + initScripts[i]+"</init>");
    else
      dynAppend(xmlDesc, "<init>" + initScripts[i]+"</init>");
      
                      }
// delete script(s)
	if(dynlen(deleteScripts) > 0)
          		for(int i=1; i<=dynlen(deleteScripts); i++){
			  //dynAppend(xmlDesc, "<delete>./config/"+deleteScripts[i]+"</delete>");
    if(!patternMatch("./scripts/" + componentName + "/*", deleteScripts[i]))
      dynAppend(xmlDesc, "<delete>./scripts/" + componentName + "/" + deleteScripts[i]+"</delete>");
    else
      dynAppend(xmlDesc, "<delete>" + deleteScripts[i]+"</delete>");
                        }
// postInstall script(s)
	if(dynlen(postInstallScripts)> 0)
          		for(int i=1; i<=dynlen(postInstallScripts); i++){
			  //dynAppend(xmlDesc, "<postInstall>./config/"+postInstallScripts[i]+"</postInstall>");
    if(!patternMatch("./scripts/" + componentName + "/*", postInstallScripts[i]))
      dynAppend(xmlDesc, "<postInstall>./scripts/" + componentName + "/" + postInstallScripts[i]+"</postInstall>");
    else
      dynAppend(xmlDesc, "<postInstall>" + postInstallScripts[i]+"</postInstall>");
                        }

// postDelete script(s)
	if(dynlen(postDeleteScripts) > 0)
          		for(int i=1; i<=dynlen(postDeleteScripts); i++){
			//dynAppend(xmlDesc, "<postDelete>./config/"+postDeleteScripts[i]+"</postDelete>");
    if(!patternMatch("./scripts/" + componentName + "/*", postDeleteScripts[i]))
      dynAppend(xmlDesc, "<postDelete>./scripts/" + componentName + "/" + postDeleteScripts[i]+"</postDelete>");
    else
      dynAppend(xmlDesc, "<postDelete>" + postDeleteScripts[i]+"</postDelete>");
      
                      }
/////////////////FVR
        
// config files
	if(dynlen(configFiles) > 0)
		for(int i=1; i<=dynlen(configFiles); i++)
			if(strpos(configFiles[i], ".windows") > 0)
      if(!patternMatch("./config/*", configFiles[i]))
  				dynAppend(xmlDesc, "<config_windows>./config/"+configFiles[i]+"</config_windows>");
      else
  				dynAppend(xmlDesc, "<config_windows>"+configFiles[i]+"</config_windows>");
        
			else if(strpos(configFiles[i], ".linux") > 0)
      if(!patternMatch("./config/*", configFiles[i]))
  				dynAppend(xmlDesc, "<config_linux>./config/"+configFiles[i]+"</config_linux>");
      else
  				dynAppend(xmlDesc, "<config_linux>"+configFiles[i]+"</config_linux>");
        
			else 
      if(!patternMatch("./config/*", configFiles[i]))
  				dynAppend(xmlDesc, "<config>./config/"+configFiles[i]+"</config>");
      else
  				dynAppend(xmlDesc, "<config>"+configFiles[i]+"</config>");
        

// ascii import files
	if(dynlen(asciiFiles) > 0)
		for(int i=1; i<=dynlen(asciiFiles); i++)
    if(!patternMatch("./dplist/*", asciiFiles[i]))
  			dynAppend(xmlDesc, "<dplist>./dplist/"+asciiFiles[i]+"</dplist>");
    else
  			dynAppend(xmlDesc, "<dplist>"+asciiFiles[i]+"</dplist>");
      

// panel files
	if(dynlen(panelFiles) > 0)
		for(int i=1; i<=dynlen(panelFiles); i++)
    if(!patternMatch("./panels/*", panelFiles[i]))
			dynAppend(xmlDesc, "<file>./panels/"+panelFiles[i]+"</file>");
    else
  	   dynAppend(xmlDesc, "<file>"+panelFiles[i]+"</file>");
      
// script files		
	if(dynlen(scriptFiles) > 0)
		for(int i=1; i<=dynlen(scriptFiles); i++)
    if(!patternMatch("./scripts/*", scriptFiles[i]))
  			dynAppend(xmlDesc, "<file>./scripts/"+scriptFiles[i]+"</file>");
    else
  			dynAppend(xmlDesc, "<file>"+scriptFiles[i]+"</file>");
      
// library files
	if(dynlen(libraryFiles) > 0)
		for(int i=1; i<=dynlen(libraryFiles); i++)
    if(!patternMatch("./scripts/libs/*", libraryFiles[i]))
  			dynAppend(xmlDesc, "<file>./scripts/libs/"+libraryFiles[i]+"</file>");
    else
  			dynAppend(xmlDesc, "<file>"+libraryFiles[i]+"</file>");
      
// misc files
	if(dynlen(otherFiles) > 0)
		for(int i=1; i<=dynlen(otherFiles); i++)
      if(!patternMatch("./*", otherFiles[i]))
        dynAppend(xmlDesc, "<file>./"+otherFiles[i]+"</file>");
      else
        dynAppend(xmlDesc, "<file>"+otherFiles[i]+"</file>");
        

//	DebugTN(otherFiles, componentName+ ".xml", dynContains(otherFiles, componentName+ ".xml"), xmlDesc);
	
	if(dynContains(xmlDesc, "<file>./"+componentName+ ".xml</file>") <= 0)
	  dynAppend(xmlDesc, "<file>./"+componentName+ ".xml</file>");


	dynAppend(xmlDesc, "</component>");
        
// write xmlFile
	if(pathName != "")
	{
		file xmlText = fopen(pathName+"/"+componentName+".xml", "w");
		if(ferror(xmlText) != 0)
		{
			fclose(xmlText);
			return -1;
		}
		if(dynlen(xmlDesc) > 0)
		{
			for(int i=1; i<=dynlen(xmlDesc); i++)
				fputs(xmlDesc[i]+"\n", xmlText);
		}
		fclose(xmlText);
	}
  
  return 0;
}



int fwInstallationDBAgent_isManagerRunning(string manager, string commandLine, bool &isRunning) 
{
  fwInstallation_flagDeprecated("fwInstallationDBAgent_isManagerRunning", "fwInstallationManager_isRunning");
  return fwInstallationManager_isRunning(manager, commandLine, isRunning);
}


/** This function retrieves the component information from the xml file and
	displays it in the panel
@param descFile: the name of a file with component description
@author M.Sliwinski
*/
fwInstallationXml_getComponentDescription(string descFile)
{

	string strComponentFile;

	bool fileLoaded;
//	dyn_string dynComponentFileLines;
	dyn_string dynRequiredComponents;
	
	dyn_string requiredNameVersion;
	string requiredName;
	string requiredVersion;
	
	string tagValue;
	string tagName;
	int pos1, pos2, pos3, pos4;
	string fileName;
	int i;
	

        dyn_string tags, values;
        dyn_anytype attribs;	
	int j;
        
        fwInstallation_flagDeprecated("fwInstallationXml_getComponentDescription()");
        
        if(fwInstallationXml_get(descFile, tags, values, attribs))
        {
	        fwInstallation_throw("fwInstallationXml_getComponentDescription() -> Cannot load " + descFile + " file ");
          return;
        }
        for(int i = 1; i <= dynlen(tags); i++)
	      {
				switch(tags[i])
				{
					case "file" : 		selectionOtherFiles.appendItem(tagValue);
										break;
	
					case "name":  		TextName.text = tagValue;
										break;
										
					case "desc":		selectionDescription.appendItem(tagValue);
										break;
					
					case "version": 	TextVersion.text = tagValue;
										break;
										
					case "date": 		TextDate.text = tagValue;
										break;
										
					case "required":	if(tagValue != "")
										{
											requiredNameVersion = strsplit(tagValue, "=");
											requiredName = requiredNameVersion[1];
				
											if(dynlen(requiredNameVersion) > 1)
											{
												requiredVersion = requiredNameVersion[2];
											}
											else
											{
												requiredVersion = " ";
											}			
											selectionRequiredComponents.appendItem(requiredName + " ver.: " + requiredVersion);
										}
										break;
										
					case "config":		selectionConfigFiles_general.appendItem(tagValue);
										break;
					
					case "script": 		selectionScripts.appendItem(tagValue);
										break;
					
					case "postInstall": selectionPostInstallFiles.appendItem(tagValue);
										break;
															
					case "init": 		selectionInitFiles.appendItem(tagValue);
										break;
										
					case "config_windows": 	selectionConfigFiles_windows.appendItem(tagValue);
											break;
											
					case "config_linux" : 	selectionConfigFiles_linux.appendItem(tagValue);
											break;
											
					case "dplist":		selectionDplistFiles.appendItem(tagValue);
										break;
										
					case "includeComponent": strreplace(tagValue, "./", "");
											 selectionSubComponents.appendItem($sourceDir + "/" + tagValue);
											 break;										
												
				} // end switch
				
			} // end while	
					
//		}	
}

/*
bool fwInstallation_checkToolVersion(string systemName = "")
{
  fwInstallation_flagDeprecated("fwInstallation_checkToolVersion");
  bool versionOK = true;
  string version; 
  dyn_string ds1, ds2;
  int a, b;
  int max;
  
  if(systemName == "")
    systemName = getSystemName();
    
  if(!patternMatch("*:", systemName))
    systemName += ":";
    
  if(fwInstallation_getToolVersion(version, systemName) != 0)
    return false;
  
  ds1 = strsplit(version, ".");
  ds2 = strsplit(csFwInstallationToolVersion, ".");
  
  if(dynlen(ds1) > 0){

    if(dynlen(ds1) > dynlen(ds2))
      max = dynlen(ds2);
    else
      max = dynlen(ds1);
      
    for(int i = 1; i <= max; i++){

      sscanf(ds1[i], "%d", a);
      sscanf(ds2[i], "%d", b);

      if(b > a)
        versionOK = false;
      
    }  
  }else
    versionOK = false;  

  return versionOK;

}
*/
int fwInstallation_managerCommand(string action, string manager, string commandLine)
{
  fwInstallation_flagDeprecated("fwInstallation_managerCommand()", "fwInstallationManager_command()");
  return fwInstallationManager_command(action, manager, commandLine);
}


int fwInstallation_packagerExportFSM(string componentName, string sourcePath, dyn_string rootNodes, dyn_string doNotExportTypes)
{
  fwInstallation_flagDeprecated("fwInstallation_packagerExportFSM", "fwInstallationPackager_exportFsm");
  return fwInstallationPackager_exportFsm(componentName, sourcePath, rootNodes, doNotExportTypes);
}

//////////////////////Managers:

int fwInstallation_getManagersInfoFromPvss(dyn_dyn_mixed &managersInfo)
{
  fwInstallation_flagDeprecated("fwInstallation_getManagersInfoFromPvss", "fwInstallationManager_getAllInfoFromPvss");
  return fwInstallationManager_getAllInfoFromPvss(managersInfo);
}

int fwInstallation_getRedundancyNumber()
{
  fwInstallation_flagDeprecated("fwInstallation_getRedundancyNumber");
  return -1;   
}


/** This function retrieves the component information from the xml file and
	displays it in the panel

@param descFile: the name of a file with component description

@author M.Sliwinski
*/

fwInstallation_getComponentDescriptionXML(string descFile)
{
  fwInstallation_flagDeprecated("fwInstallation_getComponentDescriptionXML()", "fwInstallationXml_getComponentDescription()");
  fwInstallationXml_getComponentDescription(descFile);
}

int fwInstallation_parseXmlFile(string sourceDir, 
                                string descFile, 
                                string subPath,
				                          string destinationDir,
                                string &componentName,
				                          string &componentVersion,
				                          dyn_string &dynSubComponents,
                                dyn_string &dynFileNames,
                                dyn_string &dynComponentFiles,
                                dyn_string &dynPostDeleteFiles_current,
                                dyn_string &dynPostInstallFiles_current,
                                dyn_string &dynPostDeleteFiles,
                                dyn_string &dynPostInstallFiles,
                                dyn_string &dynConfigFiles_general,
                                dyn_string &dynConfigFiles_linux,
                                dyn_string &dynConfigFiles_windows,
                                dyn_string &dynInitFiles,
                                dyn_string &dynDeleteFiles,
                                dyn_string &dynDplistFiles,
                                dyn_string &dynScriptsToBeAdded, 
                                string &helpFile,
                                string &componentDate,
                                dyn_string &comments,
                                dyn_string & dynRequiredComponents)
{
  
  fwInstallation_flagDeprecated("fwInstallation_parseXmlFile()", "fwInstallationXml_parseFile()");
  return fwInstallationXml_parseFile(sourceDir, 
                                descFile, 
                                subPath,
				                          destinationDir,
                                componentName,
				                          componentVersion,
				                          dynSubComponents,
                                dynFileNames,
                                dynComponentFiles,
                                dynPostDeleteFiles_current,
                                dynPostInstallFiles_current,
                                dynPostDeleteFiles,
                                dynPostInstallFiles,
                                dynConfigFiles_general,
                                dynConfigFiles_linux,
                                dynConfigFiles_windows,
                                dynInitFiles,
                                dynDeleteFiles,
                                dynDplistFiles,
                                dynScriptsToBeAdded, 
                                helpFile,
                                componentDate,
                                comments,
                                dynRequiredComponents);
}

/** This function updates the fwScripts.lst file to be run by ctrl manager

@param dynScriptsToBeAdded: a dynamic string with file names of scripts to be added to fwScripts.lst file
@param strComponentName: the name of the component for which the scripts are added
@author M.Sliwinski
*/

fwInstallation_addScriptsIntoFile(dyn_string & dynScriptsToBeAdded, string strComponentName)
{
fwInstallation_flagDeprecated("fwInstallation_addScriptsIntoFile", "");
		dyn_string dynLoadedScripts;   // all the scripts that were loaded from fwScripts.lst
		dyn_string dynScriptsFileLines;
		string strScriptsFileName = getPath(SCRIPTS_REL_PATH) + "fwScripts.lst";
		string scriptsFileInString;
		string strScriptsFileLine;
		dyn_string dynLinesToBeAdded;
		dyn_string dynTmpDirFile;
		int idxOfScriptName;
		int i;
		bool fileLoaded;
		int canAccessFile;
				
		canAccessFile = access(strScriptsFileName, F_OK);
		
		if(canAccessFile == 0)
		{
			
			fileLoaded = fileToString(strScriptsFileName, scriptsFileInString);

			if (! fileLoaded )
			{
			
				fwInstallation_throw("fwInstallation: Error loading the file: " + strScriptsFileName);
				
			}
			else 
			{
				
				dynScriptsFileLines = strsplit(scriptsFileInString, "\n");
				
				for( i = 1; i <= dynlen(dynScriptsFileLines); i++)
				{
					strScriptsFileLine = strrtrim(strltrim(dynScriptsFileLines[i]));
					
					if(strScriptsFileLine == "")
					{
						// this is a blank line
					}
					else if( strtok(strScriptsFileLine, "#") == 0)
					{
						// this is a comment
					}
					else
					{
						// this is a script entry
						dynAppend(dynLoadedScripts, strScriptsFileLine);
					}

				}
				

			}
		}
		else
		{
			fwInstallation_throw("fwInstallation: The file : " + strScriptsFileName + " does not exist", "error", 3);
		}
		
		// what should be added
		dynAppend(dynLinesToBeAdded, "#begin " + strComponentName);
		dynAppend(dynLinesToBeAdded, "# if this parametrisation is empty that means that the scripts were already defined in the file");
		dynAppend(dynLinesToBeAdded, "");
		
		for ( i = 1; i <= dynlen(dynScriptsToBeAdded); i++)
		{
			if(dynContains(dynLoadedScripts, dynScriptsToBeAdded[i]) > 0)
			{
				// the parametrisation is already done	
				DebugN("fwInstallation: The parametrisation is already done for: " + dynScriptsToBeAdded[i]);	
			}
			else 
			{
				// update the loaded scripts - the scripts that were loaded from the old file
				dynAppend(dynLoadedScripts, dynScriptsToBeAdded[i]);
				
				// add the script file names to - the lines to be added
				
				// get the script name from the relative path
				
				dynTmpDirFile = strsplit(dynScriptsToBeAdded[i], "/");
				
				// get the index of the script file name
				idxOfScriptName = dynlen(dynTmpDirFile);
				
				// append the script file name to the lines to be added
				dynAppend(dynLinesToBeAdded, dynTmpDirFile[idxOfScriptName]);
				DebugN("fwInstallation: Adding the parameterization for: " + dynScriptsToBeAdded[i]);	
			}
		}
		
		dynAppend(dynLinesToBeAdded, "");
		dynAppend(dynLinesToBeAdded, "#end " + strComponentName);

		// add an empty line at the end of component definition - for readability
		dynAppend(dynLinesToBeAdded, "");		 
		
		// if the fwScripts.lst is empty the PVSS00ctl manager does not start
		// the fwInstallationFakeScript.ctl is added to correct this problem
		
		if(dynContains(dynLoadedScripts, "fwInstallationFakeScript.ctl"))
		{
		
		}
		else
		{
			dynAppend(dynLinesToBeAdded, "fwInstallationFakeScript.ctl");
		}
		
		// append the new lines to the dyn_string that contains lines from old file
		
		dynAppend(dynScriptsFileLines, dynLinesToBeAdded);
		
		fwInstallation_saveFile( dynScriptsFileLines, strScriptsFileName);

}


/** This function checks the progs file if the fwScripts.lst has been added to it

@return : 0 - if fwScripts.lst is added into progs file, -1 - if fwScripts.lst does not exist in progs file
@author M.Sliwinski
*/

int fwInstallation_fwScriptsAddedToProgsFile()
{
fwInstallation_flagDeprecated("fwInstallation_fwScriptsAddedToProgsFile", "");
	bool fileLoaded;
	string strScriptsFileName = getPath(CONFIG_REL_PATH) + "progs";
	string scriptsFileInString;

			fileLoaded = fileToString(strScriptsFileName, scriptsFileInString);

			if (! fileLoaded )
			{
			
				return -1;
				
			}
			else 
			{
				if(strpos(scriptsFileInString, "fwScripts.lst") >= 0)
				{
					return 0;
				}
				else
				{
					return -1;
				}
				

			}
}

int _fwInstallation_decodeXML(string strComponentFile,
							string & componentName, string & componentVersion, string & date,
							dyn_string & dynRequiredComponents,
							bool & isSubComponent,
							dyn_string & dynInitFiles, dyn_string & dynDeleteFiles, 
							dyn_string & dynPostInstallFiles, dyn_string & dynPostDeleteFiles, 
							dyn_string & dynConfigFiles_general, dyn_string & dynConfigFiles_windows, dyn_string & dynConfigFiles_linux,
							dyn_string & dynDplistFiles,
							dyn_string & dynPanelFiles,
							dyn_string & dynScriptFiles,
							dyn_string & dynLibFiles,
							dyn_string & dynComponentFiles,
							dyn_string & dynSubComponents,
							dyn_string & dynScriptsToBeAdded,
							dyn_string & dynFileNames,
           string &dontRestartProject)
{
  fwInstallation_flagDeprecated("_fwInstallation_decodeXML", "fwInstallationXml_decode");
  return fwInstallationXml_decode(strComponentFile,
							componentName, componentVersion, date,
							dynRequiredComponents,
							isSubComponent,
							dynInitFiles, dynDeleteFiles, 
							dynPostInstallFiles, dynPostDeleteFiles, 
							dynConfigFiles_general, dynConfigFiles_windows, dynConfigFiles_linux,
							dynDplistFiles,
							dynPanelFiles,
							dynScriptFiles,
							dynLibFiles,
							dynComponentFiles,
							dynSubComponents,
							dynScriptsToBeAdded,
							dynFileNames,
           dontRestartProject);
}


/** This function allows to make an ASCII export with specific filters.

@param fileName						path and name of the output file
@param dataPointNames			names of the dps to be put out
@param dataPointTypes			names of the dpts to be put out (default all)
@param filter							filter on dps/dpts (default dps with alerts, params, and original values)
@author Sascha Schmeling and Fernando Varela
*/

fwInstallation_createDpl(	string fileName, dyn_string dataPointNames, 
													dyn_string dataPointTypes = "",
													string filter = "DAOP")
{
  fwInstallation_flagDeprecated("fwInstallation_createDpl", "fwInstallationPackager_createDpl");
  fwInstallationPackager_createDpl(fileName, dataPointNames, dataPointTypes, filter);
}

int fwInstallation_createXml(	string pathName,
                                string componentName, 
                                string componentVersion, 
                                string componentDate,
                                dyn_string requiredComponents,
		                bool isSubComponent,
			        dyn_string initScripts, dyn_string deleteScripts,
				dyn_string postInstallScripts, dyn_string postDeleteScripts,
				dyn_string configFiles, 
				dyn_string asciiFiles,
				dyn_string panelFiles,
				dyn_string scriptFiles,
				dyn_string libraryFiles,
				dyn_string otherFiles,
                                string dontRestartProject,
				dyn_string & xmlDesc)
{

  fwInstallation_flagDeprecated("fwInstallation_createXml()", "fwInstallationXml_create()");
  return  fwInstallation_createXml(pathName, componentName, componentVersion, componentDate, requiredComponents,
                                   isSubComponent, initScripts, deleteScripts, postInstallScripts, postDeleteScripts,
                                   configFiles, asciiFiles, panelFiles, scriptFiles, libraryFiles, otherFiles, dontRestartProject, xmlDesc);
}

int fwInstallation_loadXml(string fileName,
			   string & componentName, 
        string & componentVersion, 
        string & componentDate,
			   dyn_string & requiredComponents,
			   bool & isSubComponent,
			   dyn_string & initScripts,
        dyn_string & deleteScripts,
			   dyn_string & postInstallScripts,
        dyn_string & postDeleteScripts,
			   dyn_string & configFiles, 
			   dyn_string & dplistFiles,
			   dyn_string & panelFiles,
			   dyn_string & scriptFiles,
			   dyn_string & libraryFiles,
			   dyn_string & otherFiles,
			   dyn_string & xmlDesc,
        string &dontRestartProject,
        string &helpFile,
        dyn_string &subComponents,
        dyn_string &config_windows,
        dyn_string &config_linux,
        dyn_string & scriptsToBeAddedFiles,
        dyn_string &comments)
{

  fwInstallation_flagDeprecated("fwInstallation_loadXml()", "fwInstallationXml_load()");
  dyn_dyn_mixed componentInfo;
  if(fwInstallationXml_load(filename, componentInfo) < 0)
  {
    fwInstallation_throw("fwInstallation_loadXml()-> Failed to load: " + filename);
    return -1;
  }
  
  componentName = componentInfo[FW_INSTALLATION_XML_COMPONENT_NAME];
  componentVersion = componentInfo[FW_INSTALLATION_XML_COMPONENT_VERSION];
  componentDate = componentInfo[FW_INSTALLATION_XML_COMPONENT_DATE];
  requiredComponents = componentInfo[FW_INSTALLATION_XML_COMPONENT_REQUIRED_COMPONENTS];
  isSubComponent = componentInfo[FW_INSTALLATION_XML_COMPONENT_IS_SUBCOMPONENT];
  initScripts = componentInfo[FW_INSTALLATION_XML_COMPONENT_INIT_SCRIPTS];
  deleteScripts = componentInfo[FW_INSTALLATION_XML_COMPONENT_DELETE_SCRIPTS];
  postInstallScripts = componentInfo[FW_INSTALLATION_XML_COMPONENT_POST_INSTALL_SCRIPTS];
  postDeleteScripts = componentInfo[FW_INSTALLATION_XML_COMPONENT_POST_DELETE_SCRIPTS];
  configFiles = componentInfo[FW_INSTALLATION_XML_COMPONENT_CONFIG_FILES];
  dplistFiles = componentInfo[FW_INSTALLATION_XML_COMPONENT_DPLIST_FILES];
  panelFiles = componentInfo[FW_INSTALLATION_XML_COMPONENT_PANEL_FILES];
  scriptFiles = componentInfo[FW_INSTALLATION_XML_COMPONENT_SCRIPT_FILES];
  libraryFiles = componentInfo[FW_INSTALLATION_XML_COMPONENT_LIBRARY_FILES];
  otherFiles = componentInfo[FW_INSTALLATION_XML_COMPONENT_OTHER_FILES];
  xmlDesc = componentInfo[FW_INSTALLATION_XML_DESC_FILE];
  dontRestartProject = componentInfo[FW_INSTALLATION_XML_COMPONENT_DONT_RESTART];
  helpFile = componentInfo[FW_INSTALLATION_XML_COMPONENT_HELP_FILE];
  subComponents = componentInfo[FW_INSTALLATION_XML_COMPONENT_SUBCOMPONENTS];
  config_windows = componentInfo[FW_INSTALLATION_XML_COMPONENT_CONFIG_FILES];
  config_linux = componentInfo[FW_INSTALLATION_XML_COMPONENT_CONFIG_FILES]; 
  scriptsToBeAddedFiles = componentInfo[FW_INSTALLATION_XML_COMPONENT_SCRIPT_FILES];
  comments = componentInfo[FW_INSTALLATION_XML_COMPONENT_COMMENTS];
  
  return  0;
}

/** This function packs a component and saves it according to an xml description.

@param destinationFolder	path for the component package (does not need to exist)
@param xmlDesc						complete xml description (for experts)
@return 0 - component completely packed, -n - n component items not found
@author Sascha Schmeling
*/

int fwInstallation_packNgo(	string destinationFolder, dyn_string xmlDesc)
{
  fwInstallation_flagDeprecated("fwInstallation_packNgo", "fwInstallationPackager_packNgo");
  return fwInstallationPackager_packNgo(destinationFolder, PROJ_PATH, xmlDesc);
}	


/** This function allows to insert a manager into a project. 
The function is meant to be used in the init or postInstall scripts of a framework
component. It will popup a user interface asking whether to activate the manager if needed.

@param defActivated		FALSE - deactivated, TRUE - activated (if the user interface times out)
@param manTitle				title to be shown to the user
@param manager				name of the manager
@param startMode			{manual, once, always}
@param secKill				seconds to kill after stop
@param restartCount		number of restarts
@param resetMin				restart counter reset time (minutes)
@param commandLine		commandline for the manager
@return 1 - manager added, 2 - manager already existing, 3 - no user interface, 0 - manager addition failed
@author Sascha Schmeling
*/

int fwInstallation_appendManager(bool defActivated, string manTitle, 
				 string manager, string startMode, 
				 int secKill, int restartCount, int resetMin,
				 string commandLine)
{

  fwInstallation_flagDeprecated("fwInstallation_appendManager()", "fwInstallationManager_append()");  
  return fwInstallationManager_append(defActivated, manTitle, manager, startMode, secKill, restartCount, resetMin, commandLine); 
}


/** This function allows to insert a driver into a project. 
The function is meant to be used in the init or postInstall scripts of a framework
component. It will popup a user interface asking whether to activate the driver
or the corresponding simulator if needed.

@param defActivated		NONE - deactivated, {DRIVER,SIM} - activated the respective manager (if the user interface times out)
@param manTitle				title to be shown to the user
@param manager				name of the manager
@param startMode			{manual, once, always}
@param secKill				seconds to kill after stop
@param restartCount		number of restarts
@param resetMin				restart counter reset time (minutes)
@param commandLine		commandline for the manager
@return 1 - manager added, 2 - manager already existing, 3 - no user interface, 0 - manager addition failed
@author Sascha Schmeling
*/

int fwInstallation_appendDriver(string defActivated, string manTitle, 
																	string manager, string startMode, 
																	int secKill, int restartCount, int resetMin,
																	string commandLine)
{
  fwInstallation_flagDeprecated("fwInstallation_appendDriver()", "fwInstallationManager_appendDriver()");  
  return fwInstallationManager_appendDriver(defActivated, manTitle, manager, startMode, secKill, restartCount, resetMin, commandLine);
}


/** This function allows to insert a manager into a project. It is checked before, if the 
manager already exists.

@param manager				name of the manager
@param startMode			{manual, once, always}
@param secKill				seconds to kill after stop
@param restartCount		number of restarts
@param resetMin				restart counter reset time (minutes)
@param commandLine		commandline for the manager
@return 1 - manager added, 2 - manager already existing, 3 - manager addition disabled, 0 - manager addition failed
@author Sascha Schmeling
*/

int fwInstallation_addManager(string manager, string startMode, 
	    		      int secKill, int restartCount, int resetMin,
			      string commandLine)
{
  fwInstallation_flagDeprecated("fwInstallation_addManager()", "fwInstallationManager_add()");  
  return fwInstallationManager_add(manager, startMode, secKill, restartCount, resetMin, commandLine);
}

int fwInstallation_changeManagerSettings(string manager, string commandLine, string newCommandLine, string mode, int restart, int reset, int secKill) 
{
  fwInstallation_flagDeprecated("fwInstallation_changeManagerSettings()", "fwInstallationManager_setProperties()");  
  dyn_mixed managerInfo;
  
  managerInfo[FW_INSTALLATION_MANAGER_OPTIONS] = newCommandLine;
  managerInfo[FW_INSTALLATION_MANAGER_START_MODE] = mode;
  managerInfo[FW_INSTALLATION_MANAGER_RESTART_COUNT] = restart;
  managerInfo[FW_INSTALLATION_MANAGER_RESET_MIN] = reset;
  managerInfo[FW_INSTALLATION_MANAGER_SEC_KILL] = secKill;
  
  return fwInstallationManager_setProperties(manager, commandLine, managerInfo);
}

/** This function allows to find a manager in a project. 

@param manager				name of the manager
@param commandLine		commandline for the manager
@param startMode			{manual, once, always}
@return 1 - manager found, 2 manager not found, 0 - failed
@author Sascha Schmeling
*/

int fwInstallation_findManager(	string manager, string commandLine, string & startMode, int &managerPos)
{
  fwInstallation_flagDeprecated("fwInstallation_findManager()", "fwInstallationManager_getProperties()");  
  dyn_mixed managerInfo;
  fwInstallationManager_getProperties(manager, commandLine, managerInfo);
  startMode = managerInfo[FW_INSTALLATION_MANAGER_START_MODE];
  managerPos = managerInfo[FW_INSTALLATION_MANAGER_PMON_IDX];
  
  return 0;
}



/** This function retrieves all managers from pmon

@param err						error code
@param projName				name of the project, "" for own
@param manPos					position of the manager
@param manager				name of the manager
@param startMode			0 manual, 1 once, 2 always
@param secKill				seconds to kill after stop
@param restartCount		number of restarts
@param resetMin				restart counter reset time (minutes)
@param commandLine		commandline for the manager
@author Sascha Schmeling

*/
pmonGetManagers(bool &err, string projName,
								dyn_int &manPos, dyn_string &manager, dyn_int &startMode, 
								dyn_int &secKill, dyn_int &restartCount, dyn_int &resetMin,
								dyn_string &commandLine)
{
  fwInstallation_flagDeprecated("pmonGetManagers()", "fwInstallationManager_pmonGetManagers()");  
  fwInstallationManager_pmonGetManagers(err, projName,
								manPos, manager, startMode, 
								secKill, restartCount, resetMin,
								commandLine);
  
  return;
}


/** This function will put together the specified section, that consists of several distributed parts.

@param section: string to define the section which will be compacted
@return 0 - "success"  -1 - error  -2 - section does not exist
@author S. Schmeling
*/

int fwInstallation_compactSection( string section )
{
  fwInstallation_flagDeprecated("fwInstallation_compactSection", "");  

	dyn_string configLines;
	int returnValue;
	returnValue = fwInstallation_getSection(section, configLines);
	if (returnValue == 0)
	{
		fwInstallation_clearSection(section);
		returnValue = fwInstallation_setSection(section, configLines);
		return returnValue;
	} else {
		return returnValue;
	}
	
}

// **************************************************************************************************************
// **************************************************************************************************************
//
//
// Functions related to the Component Installation
//
//
// **************************************************************************************************************
// **************************************************************************************************************




/** This function adds a library entry to a specified section of the config file.

@param section: string to define the section where the library has to be added (will be created if not existing)
@param libraryName: dyn_string containing the library names to be added
@return 0 - "success"  -1 - error 
@author S. Schmeling
*/

int fwInstallation_addLibrary( string section, dyn_string libraryName )
{
  fwInstallation_flagDeprecated("fwInstallation_addLibrary", "");  
  
	dyn_string configLines;
	
	dyn_int tempPositions;
	string tempLine;
	int i,j,k;
	bool sectionFound = FALSE;
	
	string configPath = getPath(CONFIG_REL_PATH);
	string configFile = configPath + "config";

	j = -1;

	if(dynlen(libraryName) > 0)
	{
		if(_fwInstallation_getConfigFile(configLines) == 0)
		{
			for (i=1; i<dynlen(configLines); i++)
			{
				tempLine = configLines[i];
				if(strpos(strltrim(strrtrim(tempLine)), "["+section+"]") = 0)
				{
					j = i;
					break;
				}
			}
			if(j > 0)
			{
				sectionFound = TRUE;
				for(k=dynlen(libraryName); k>0; k--)
				{
					tempLine = "LoadCtrlLibs = \"" + libraryName[k] + "\"";
					dynInsertAt(configLines,tempLine,j+1);
				}
			}
			if(sectionFound == TRUE)
			{
				return fwInstallation_saveFile(configLines, configFile);
			} else {
				return -2;
			}
		} else {
			return -1;
		}
	}
}

/**Deprecated function*/
int fwInstallation_getXml(string docPath, dyn_string &tags, dyn_string &values, dyn_anytype &attribs)
{
  fwInstallation_flagDeprecated("fwInstallation_getXml()", "fwInstallationXml_get()");
  return fwInstallationXml_get(docPath, tags, values, attribs);
}

/**Deprecated function */
int fwInstallation_getXmlTag(string docPath, string tag, dyn_string &FilteredValues, dyn_anytype &FilteredAttribs)
{
  fwInstallation_flagDeprecated("fwInstallation_getXmlTag()", "fwInstallationXml_getTag()");
  return fwInstallationXml_getTag(docPath, tag, FilteredValues, FilteredAttribs);
}

/** Deprecated function */
int fwInstallation_xmlChildNodesContent ( unsigned doc , int node ,
              dyn_string &node_names , dyn_anytype &attributes , dyn_string &nodevalues ,
              dyn_string &exceptionInfo )
{

  fwInstallation_flagDeprecated("fwInstallation_xmlChildNodesContent()", "fwInstallationXml_childNodesContent()");
  return fwInstallationXml_childNodesContent (doc, node,
              node_names, attributes, nodevalues,
              exceptionInfo);
}

/** Deprecated function */
int fwInstallation_shallStopManager(string managerType)
{
  fwInstallation_flagDeprecated("fwInstallation_shallStopManager()", "fwInstallationManager_shallStopManagersOfType()");
  return fwInstallationManager_shallStopManagersOfType(managerType);
}


/** Deprecated function */
int fwInstallation_stopManagers(dyn_string types)
{
  fwInstallation_flagDeprecated("fwInstallation_stopManagers()", "fwInstallationManager_stopAllOfTypes()");
  return fwInstallationManager_stopAllOfTypes(types);
}


/** Deprecated function */
int fwInstallation_logCurrentManagerConfiguration(string manager, string startMode, int secKill, 
  		                                  int restartCount, int resetMin, string commandLine)
{
  fwInstallation_flagDeprecated("fwInstallation_logCurrentManagerConfiguration()", "fwInstallationManager_logCurrentConfiguration()");
  return fwInstallationManager_logCurrentConfiguration(manager, startMode, secKill, restartCount, resetMin, commandLine);
}

/** Deprecated function */
int fwInstallation_getManagerIndex(string manager, string commandLine, int &pos)
{
  fwInstallation_flagDeprecated("fwInstallation_getManagerIndex()", "fwInstallationManager_getProperties()");
  dyn_mixed managerInfo;
  fwInstallationManager_getProperties(manager, commandLine, managerInfo);
  pos = managerInfo[FW_INSTALLATION_MANAGER_PMON_IDX];
  
  return 0;
}

/** Deprecated function */
int fwInstallation_setManagerMode(string manager, string commandLine, string mode)
{
  fwInstallation_flagDeprecated("fwInstallation_setManagerMode()", "fwInstallationManager_setMode()");
  return fwInstallationManager_setMode(manager, commandLine, mode);
}

/** Deprecated function */
int fwInstallation_executeAllManagerReconfigurationActions()
{
  fwInstallation_flagDeprecated("fwInstallation_executeAllManagerReconfigurationActions()", "fwInstallationManager_executeAllReconfigurationActions()");
  return fwInstallationManager_executeAllReconfigurationActions();
}

/** Deprecated function */
int fwInstallation_executeManagerReconfigurationAction(string manager, string startMode, int secKill, int restartCount, int resetMin, string commandLine)
{
  fwInstallation_flagDeprecated("fwInstallation_executeManagerReconfigurationAction()", "fwInstallationManager_executeReconfigurationAction()");
  return fwInstallationManager_executeReconfigurationAction(manager, startMode, secKill, restartCount, resetMin, commandLine);
}

/** Deprecated function */
int fwInstallation_getManagerReconfigurationActions(dyn_string &dsManager, dyn_string &dsStartMode, dyn_int &diSecKill, dyn_int &diRestartCount, dyn_int &diResetMin, dyn_string &dsCommandLine)
{  
  fwInstallation_flagDeprecated("fwInstallation_getManagerReconfigurationActions()", "fwInstallationManager_getReconfigurationActions()");
  return fwInstallationManager_getReconfigurationActions(dsManager, dsStartMode, diSecKill, diRestartCount, diResetMin, dsCommandLine);
}

/** Deprecated function */
int fwInstallation_setManagerReconfigurationActions(dyn_string dsManager, dyn_string dsStartMode, dyn_int diSecKill, dyn_int diRestartCount, dyn_int diResetMin, dyn_string dsCommandLine)
{
  fwInstallation_flagDeprecated("fwInstallation_setManagerReconfigurationActions()", "fwInstallationManager_setReconfigurationActions()");
  return fwInstallationManager_setReconfigurationActions(dsManager, dsStartMode, diSecKill, diRestartCount, diResetMin, dsCommandLine);
}

/** Deprecated function */
int fwInstallation_deleteManagerReconfigurationAction(string manager, string startMode, int secKill, int restartCount, int resetMin, string commandLine)
{
  fwInstallation_flagDeprecated("fwInstallation_deleteManagerReconfigurationAction()", "fwInstallationManager_deleteReconfigurationAction()");
  return fwInstallationManager_deleteReconfigurationAction(manager, startMode, secKill, restartCount, resetMin, commandLine);
}

int fwInstallation_getTagFromString(string & tagName, string & tagValue, string & strComponentFile)
{
  fwInstallation_flagDeprecated("fwInstallation_getTagFromString", "fwInstallationXml_getTagFromString()");
  return fwInstallationXml_getTagFromString(tagName, tagValue, strComponentFile);
}
