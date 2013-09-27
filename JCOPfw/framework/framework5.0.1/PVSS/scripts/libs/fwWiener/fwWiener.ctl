fwWiener_createOpcConfigFile(dyn_string canBuses, string fileName, dyn_string &exceptionInfo, int driverNumber = 14)
{  	

  file outputFile;
  string header, fileContents, openingTag, closingTag;

  fwDeviceFrontEndConfigFile_GetDpTypeTag(dpTypeName("WIENER_" + driverNumber), fwDeviceFrontEndConfigFile_OPENING_TAG, openingTag, exceptionInfo);
  fwDeviceFrontEndConfigFile_GetDpTypeTag(dpTypeName("WIENER_" + driverNumber), fwDeviceFrontEndConfigFile_CLOSING_TAG, closingTag, exceptionInfo);
	
  //DebugN(canBuses);
  int length = dynlen(canBuses);
  for(int i=1; i<=length; i++)
  {
    string model, tempOpen, tempClose, tempStore;
    dyn_int childPositions;
    dyn_string canBusChildren;
    mapping sortedChildren;
                
    fwDevice_getModel(makeDynString(canBuses[i]), model, exceptionInfo);
    if(model == "CAN Bus")
    {
      fwDeviceFrontEndConfigFile_GetDeviceTag(canBuses[i], fwDeviceFrontEndConfigFile_OPENING_TAG, tempOpen, exceptionInfo);
      fwDeviceFrontEndConfigFile_GetDeviceTag(canBuses[i], fwDeviceFrontEndConfigFile_CLOSING_TAG, tempClose, exceptionInfo);
     	header += tempOpen + tempClose;
      fwDeviceFrontEndConfigFile_ProcessEntry(canBuses[i], header, header, exceptionInfo);
                        
      fwDevice_getChildren(canBuses[i], fwDevice_HARDWARE, canBusChildren, exceptionInfo);
      for(int j=1; j<=dynlen(canBusChildren); j++)
      {
        int position;
        string name;
        fwDevice_getPosition(canBusChildren[j], name, position, exceptionInfo);
        sortedChildren[position] = canBusChildren[j];
      }

      childPositions = mappingKeys(sortedChildren);
      dynSortAsc(childPositions);
      
      for(int j=1; j<=dynlen(childPositions); j++)
      {
        fwDeviceFrontEndConfigFile_CreateContents(sortedChildren[childPositions[j]], tempStore, exceptionInfo);
    		  fileContents += tempStore;
      }
    }
    else
    {
	     fwDeviceFrontEndConfigFile_CreateContents(canBuses[i], tempStore, exceptionInfo);
	  		//DebugN(tempStore);
	  		fileContents += tempStore;
    }
  }

  strreplace(openingTag, "<!-- CAN details -->", "<!-- CAN details -->\n" + header);
  fileContents = openingTag + fileContents + closingTag;

  outputFile = fopen(fileName, "w");
  fprintf(outputFile, fileContents);
  fclose(outputFile);
}


fwWiener_loadSettingsFromHw(string dpName, dyn_string &exceptionInfo)
{
  int i;
  string dpType;
  dyn_string readbackElements, readbackManagers, settingElements;
  dyn_int managers;
  dyn_anytype values;
  dyn_errClass errors;
  
  dpType = dpTypeName(dpName);
  fwWiener_getReadbackElements(dpType, dpName, readbackElements, exceptionInfo);
  
  settingElements = readbackElements;
  for(i=1; i<=dynlen(readbackElements); i++)
  {
      strreplace(settingElements[i], "ReadBackSettings", "Settings");
      strreplace(settingElements[i], "ReadbackSettings", "Settings");
      
      readbackManagers[i] = readbackElements[i] + ":_online.._manager";
  }
  
  if(dynlen(readbackElements) > 0)
  {
    dpGet(readbackElements, values,
          readbackManagers, managers);
  }
  
  //go through lists backwards to ensure that deleted entries do not change indexes to be used later
  for(i=dynlen(managers); i>0; i--)
  {
    char manType, manNum;    
    getManIdFromInt(managers[i], manType, manNum);
//DebugN(readbackManagers[i], manType, manNum, (char)DRIVER_MAN);    
    if(manType != (char)DRIVER_MAN)
    {
//DebugN("removing because not set by driver", settingElements[i], values[i]);
      dynRemove(settingElements, i);
      dynRemove(values, i);
    }    
  }  
  
  if(dynlen(values) > 0)
  {
    dpSetWait(settingElements, values);
    errors = getLastError(); 
    if(dynlen(errors) > 0)
    { 
	throwError(errors);
	fwException_raise(exceptionInfo, "ERROR", "Could not load all the settings from hardware.", "");
    }
  }
}

fwWiener_getReadbackElements(string dpType, string prefixDpName, dyn_string &readbackElements, dyn_string &exceptionInfo)
{
  int i, j, k, level, found = -1;
  dyn_string path;
  dyn_dyn_string elementNames, refMap;
  dyn_dyn_int elementTypes;
  string stringPath, refType;
  
  dpTypeGet(dpType, elementNames, elementTypes);
  refMap = dpGetDpTypeRefs(dpType);
  
//DebugN(refMap);

  for(i=1; i<=dynlen(elementNames); i++)
  {
    for(j=1; j<=dynlen(elementNames[i]); j++)
    {
      if(elementTypes[i][j] != 0)
      {        
        level = j;

        if(level > 1)
          path[level] = elementNames[i][j];
        else
          path[level] = prefixDpName;
        
        while(dynlen(path) > level)
          dynRemove(path, level + 1);

        if(found == (level-1))
        {
          fwGeneral_dynStringToString(path, stringPath, ".");
          dynAppend(readbackElements, stringPath);
        }
        else
           found = -1;
        
        if(elementTypes[i][j] == DPEL_STRUCT)
        {
          if(strtolower(elementNames[i][j]) == "readbacksettings")
            found = level;
        }
        else if(elementTypes[i][j] == DPEL_TYPEREF)
        {
          for(k=1; k<=dynlen(refMap); k++)
          {//DebugN((path[level-1] + "." + elementNames[i][j]));
            if((refMap[k][2] == elementNames[i][j]) || (refMap[k][2] == (path[level-1] + "." + elementNames[i][j])))
            {
              fwGeneral_dynStringToString(path, stringPath, ".");
              fwWiener_getReadbackElements(refMap[k][1], stringPath, readbackElements, exceptionInfo);
              break;
            }
          }
        }
        break;
      }
    }
  }
//  DebugN(readbackElements);
}

fwWiener_setKrakowMarathonCustomisation(string dpName, dyn_string &exceptionInfo)
{  
  int i, length, pos;
  string name;
  dyn_string children;

  fwConfigConversion_set(dpName + ".Status.OutputFailure", DPCONFIG_CONVERSION_RAW_TO_ENG_MAIN, DPDETAIL_CONV_INVERT,
                         0, makeDynFloat(), exceptionInfo);
						
  fwDevice_getChildren(dpName, fwDevice_HARDWARE, children, exceptionInfo);

  length = dynlen(children);
  for(i=1; i<=length; i++)
  {
    fwDevice_getPosition(children[i], name, pos, exceptionInfo);
	
    dpSetWait(children[i] + ".Status.FailureMaxCurrent:_address.._datatype", 491,
		children[i] + ".Status.FailureMaxCurrent:_address.._subindex", pos);
    dpSetWait(children[i] + ".Status.FailureMaxSenseVoltage:_address.._datatype", 491,
		children[i] + ".Status.FailureMaxSenseVoltage:_address.._subindex", pos);
    dpSetWait(children[i] + ".Status.FailureMaxTerminalVoltage:_address.._datatype", 491,
		children[i] + ".Status.FailureMaxTerminalVoltage:_address.._subindex", pos);
  }
}

fwWiener_deleteKrakowMarathonCustomisation(string dpName, dyn_string &exceptionInfo)
{
  fwConfigConversion_delete(dpName + ".Status.OutputFailure", DPCONFIG_CONVERSION_RAW_TO_ENG_MAIN, exceptionInfo);  
}

fwWiener_setSupervisionBehaviourOpcTypes(string dpName, dyn_string &exceptionInfo)
{
  const int OPC_INT16_DATATYPE = 481;  

  dpSetWait(dpName + ".SupervisionBehavior.Settings.MaxSenseVoltage:_address.._datatype",    OPC_INT16_DATATYPE,
            dpName + ".SupervisionBehavior.Settings.MaxTerminalVoltage:_address.._datatype", OPC_INT16_DATATYPE,
            dpName + ".SupervisionBehavior.Settings.MaxCurrent:_address.._datatype",         OPC_INT16_DATATYPE,
            dpName + ".SupervisionBehavior.Settings.MaxTemperature:_address.._datatype",     OPC_INT16_DATATYPE,
            dpName + ".SupervisionBehavior.Settings.MinSenseVoltage:_address.._datatype",    OPC_INT16_DATATYPE,
            dpName + ".SupervisionBehavior.Settings.MaxPower:_address.._datatype",           OPC_INT16_DATATYPE,
            dpName + ".SupervisionBehavior.Settings.Timeout:_address.._datatype",            OPC_INT16_DATATYPE
            );
}
