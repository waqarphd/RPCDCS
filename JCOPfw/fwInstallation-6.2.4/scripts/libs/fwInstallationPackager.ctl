#uses "fwInstallation.ctl"

const string  csFwInstallationPackagerLibVersion = "6.2.4";

int fwInstallationPackager_exportFsm(string componentName, string sourcePath, dyn_string rootNodes, dyn_string doNotExportTypes)
{
  dyn_string nodes, dps, exceptionInfo;
  dyn_string smallDps;
  string type, device, installScript;
  file installScriptFile;
  string tree;
  dyn_string devices;
  dyn_string componentsInfo;
  dyn_string fwDps = makeDynString("fwOT_FwChildMode", "fwOT_FwChildrenMode", "fwOT_FwDevMajority", "fwOT_FwDevMode", "fwOT_FwFSMConfDBDUT", "fwOT_FwMode");

  if(dynlen(doNotExportTypes) && doNotExportTypes[1] != "")
    dynAppend(fwDps, doNotExportTypes);
  
  	
  if(sourcePath == ""){
    if(myManType() == UI_MAN)
      ChildPanelOnCentral("vision/MessageInfo1", "ERROR", makeDynString("$1:You must choose the source path first."));
    else
      DebugN("ERROR: fwInstallation_packagerExportFSM() -> You must choose the source path first.");
    
    return -1;
      
  }

  //Is FSM installed?
  componentsInfo = dpNames("*fwInstallation_fwFSM*", "_FwInstallationComponents");

  if(dynlen(componentsInfo) <= 0){
    if(myManType() == UI_MAN)
    {
      ChildPanelOnCentral("vision/MessageInfo1", "ERROR", makeDynString("$1:FwFSM is not installed. No FSM to be exported"));
    }
    else
    {
      DebugN("ERROR: fwInstallation_packagerExportFSM() -> FwFSM is not installed. No FSM to be exported");
    }
        
    return -1;  
  }
  
  for(int ii = 1; ii <= dynlen(rootNodes); ii++)
  { 
    tree = rootNodes[ii];
    if(myManType() == UI_MAN)
      openProgressBar("FSM Export", "copy.gif", "Exporting FSM tree: " + tree, "still exporting", " Do not close this panel. Be patient!", 2); 

    strreplace(tree, "/", "_");        
    if(tree != "Types only")
    {
      dynClear(nodes);
      fwTree_getAllTreeNodes(tree, nodes, exceptionInfo);
      dynAppend(nodes, tree);
      dynClear(dps);
      installScript = "main()\n{\n  dyn_string exceptionInfo;\n";
		
      if(dynlen(nodes) > 0)
      {
	for(int i=1; i<=dynlen(nodes); i++) //object types
	{
	  fwTree_getNodeDevice(nodes[i], devices[i], type, exceptionInfo);
	  if(!dynContains(dps, "fwOT_"+type))
      	    dynAppend(dps, "fwOT_"+type);
        }
	
	for(int i=1; i<=dynlen(nodes); i++) //tree nodes + DevMajority Objects
 {
  	  dynAppend(dps, "fwTN_"+nodes[i]);
          if(patternMatch("*_FWMAJ", nodes[i]))
          {
             //Found a device majority object. Make sure the type is also added
            string typeDp = "";
            dpGet("fwTN_"+nodes[i] + ".device", typeDp);
            
            if(dynContains(dps, typeDp) <= 0 && typeDp != "")
            {
              dynAppend(dps, typeDp); 
            }
          }
        }

        
                
	// do some gymnastics in order to get the FSM right			
	for(int i=1; i<=dynlen(nodes); i++)
	{
	  if(strreplace(devices[i], getSystemName(), ""))
	  installScript += "  dpSet(\"fwTN_"+nodes[i]+".device\", getSystemName()+\""+devices[i]+"\");\n";
	}			
	// end sports

        if(myManType() == UI_MAN)
          showProgressBar("", "", "Creating dpl files with FSM datapoints. Do not close this panel", 50.);

      if(dynlen(dps) > 100)
	for(int i=1; i<=(dynlen(dps)/100)+1; i++)
	{
	  dynClear(smallDps);
	  if(dynlen(dps)-(i-1)*100 > 100)
	    for(int j=1; j<=100; j++)
	      dynAppend(smallDps, dps[j+(i-1)*100]);
	  else
	    for(int j=1; j<=dynlen(dps)-(i-1)*100; j++)
		dynAppend(smallDps, dps[j+(i-1)*100]);
          
	  fwInstallation_createDpl(sourcePath +"/dplist/"+ componentName +"_"+ tree +"_" +i+ ".dpl", smallDps);
	}
	else  
	  fwInstallation_createDpl(sourcePath +"/dplist/"+ componentName +"_"+ tree +".dpl", dps);
			
			
	installScript += "  fwTree_addNode(\"FSM\", \""+tree+"\", exceptionInfo);\n";
	installScript += "  fwFsmTree_generateAll();\n";
	installScript += "}\n";

      if(access(sourcePath +"/scripts/" + componentName + "/.", F_OK) != 1){
        //DebugN("INFO: fwInstallation -> Creating new subdirectory: " + sourcePath.text +"/scripts/" + componentName.text + "/");
        mkdir(sourcePath +"/scripts/" + componentName + "/", 755);
      }
      
      //DebugN("Filename: " + sourcePath.text +"/scripts/"+ componentName.text + "/" + componentName.text + "_" + tree +"_FSM.postInstall");
      if(myManType() == UI_MAN)
      {
        showProgressBar("", "", "Creating post-installation scripts. Please wait", 50.);
      }
      
      installScriptFile = fopen(sourcePath +"/scripts/"+ componentName + "/" + componentName+ "_" + tree +"_FSM.postInstall", "w");
 
      fputs(installScript, installScriptFile);
      fclose(installScriptFile);
      }
    } else {
      if(myManType() == UI_MAN)
      {
        showProgressBar("", "", "Creating dpl files with FSM datapoints. Do not close this panel", 50.);
      }
      dps = dpNames("fwOT_*");
      //Remove standard FSM types:          
      for(int k = 1; k <= dynlen(fwDps); k++){
        if(dynContains(dps, getSystemName() + fwDps[k]) > 0){
          dynRemove(dps, dynContains(dps, getSystemName() + fwDps[k]));
        }
      }
                
      if(dynlen(dps) > 0)
        fwInstallation_createDpl(sourcePath +"/dplist/"+ componentName +"_FSMTypes.dpl", dps);
    }
    if(myManType() == UI_MAN)
    {
      closeProgressBar(); 
    }
  }
  
  return 0;
}

int fwInstallationPackager_packNgo(string destinationFolder, string sourcePath, dyn_string xmlDesc)
{
	int errCount = 0;
  string component;
  strreplace(destinationFolder, "\\", "/");
  dyn_string ds = strsplit(destinationFolder, "/");
  component = ds[dynlen(ds)];
  
  fwInstallation_throw("Packaging component: " + component, "INFO", 10);
  
	if(dynlen(xmlDesc) > 0)
	{
		if(destinationFolder != "")
		{
			for(int i=1; i<=dynlen(xmlDesc); i++)
			{
				errCount += fwInstallationPackager_transferTaggedFile(xmlDesc[i], "config", sourcePath, destinationFolder);
				errCount += fwInstallationPackager_transferTaggedFile(xmlDesc[i], "config_linux", sourcePath, destinationFolder);
				errCount += fwInstallationPackager_transferTaggedFile(xmlDesc[i], "config_windows", sourcePath, destinationFolder);
				errCount += fwInstallationPackager_transferTaggedFile(xmlDesc[i], "init", sourcePath, destinationFolder);
				errCount += fwInstallationPackager_transferTaggedFile(xmlDesc[i], "delete", sourcePath, destinationFolder);
				errCount += fwInstallationPackager_transferTaggedFile(xmlDesc[i], "postInstall", sourcePath, destinationFolder);
				errCount += fwInstallationPackager_transferTaggedFile(xmlDesc[i], "postDelete", sourcePath, destinationFolder);
				errCount += fwInstallationPackager_transferTaggedFile(xmlDesc[i], "dplist", sourcePath, destinationFolder);
				errCount += fwInstallationPackager_transferTaggedFile(xmlDesc[i], "script", sourcePath, destinationFolder);
				
      if(patternMatch("*"+component + ".xml</file>", xmlDesc[i]))
      {
        errCount += fwInstallationPackager_transferTaggedFile(xmlDesc[i], "file", PROJ_PATH, destinationFolder);
      }
      else
        errCount += fwInstallationPackager_transferTaggedFile(xmlDesc[i], "file", sourcePath, destinationFolder);
			}
		}
	}
  if(errCount)
  	return -1;
  
  return 0;
}	


int fwInstallationPackager_transferTaggedFile(string line, string tag, string sourceFolder, string destinationFolder)
{
	string source, destination;
	unsigned itemNo;
	dyn_string sourceItems;
	
	fwInstallation_getProjPaths(sourceItems);
	itemNo = dynlen(sourceItems);
	
	if(strpos(line, "<"+tag+">") == 0)
	{
		line = strrtrim(strltrim(line,"<"+tag),"/"+tag+">");
		line = strrtrim(strltrim(line,">."),"<");
		source = sourceFolder+line;
		destination = destinationFolder+line;
		while(fwInstallation_copyFile(source, destination) != 0 && itemNo > 0)
		{
			source = sourceItems[itemNo]+line;
			itemNo--;
		}	
	}
	if(itemNo == 0)
		return -1;
	else
		return 0;
}

/** This function allows to make an ASCII export with specific filters.

@param fileName						path and name of the output file
@param dataPointNames			names of the dps to be put out
@param dataPointTypes			names of the dpts to be put out (default all)
@param filter							filter on dps/dpts (default dps with alerts, params, and original values)
@author Sascha Schmeling and Fernando Varela
*/

void fwInstallationPackager_createDpl(	string fileName, dyn_string dataPointNames, dyn_string dataPointTypes = "", string filter = "DAOP")
{
	string cmdLine;
	if(dataPointTypes == "")
		dynClear(dataPointTypes);
	
  if(_WIN32)
	  cmdLine = "cmd /c " + PVSS_BIN_PATH+fwInstallation_getWCCOAExecutable("ascii")+" -proj "+ PROJ +" -out "+fileName+" -filter "+filter + " -user para:";
	else
	  cmdLine = PVSS_BIN_PATH+fwInstallation_getWCCOAExecutable("ascii") + " -proj "+ PROJ +" -out "+fileName+" -filter "+filter + " -user para:";          
        
	if(dynlen(dataPointNames) > 0)
		for(int i=1; i<=dynlen(dataPointNames); i++){
			if(patternMatch("*&*", dataPointNames[i]) && _WIN32){
			  dataPointNames[i] = "\"" + dataPointNames[i] + "\"";
			}
                        
                        if(_WIN32)
			  cmdLine = cmdLine + " -filterDp " + dataPointNames[i]+";";
                        else
                          cmdLine = cmdLine + " -filterDp '" + dataPointNames[i]+";'";
	  }
	if(dynlen(dataPointTypes) > 0)
		for(int i=1; i<=dynlen(dataPointTypes); i++){
			cmdLine = cmdLine + " -filterDpType " + dataPointTypes[i];
    }	
    
	//Debug("command line:", cmdLine);
	system(cmdLine);											
}

