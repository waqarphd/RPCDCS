/**@file

This library contains functions and constants needed by the fwMCS -
- the Magnet

@par Creation Date
	14/06/2006

@par Modification History
	None
	
@par Constraints
	None

@par Usage
	Public

@par PVSS managers
	VISION, CTRL

@author 
	Laura Fernández Nocelo (IT-CO)
*/

//@{ 


/** Function used for subscribing all the publications for an experiment
@par Constraints
	None

@par Usage
	Public

@par PVSS managers
	VISION, CTRL

@param experim			name of the experiment
@param exceptionInfo		output, information about errors
*/

fwMCS_subscribeExperiment(string experim, dyn_string &exceptionInfo)
{
	dyn_dyn_string values;
	dyn_string childName, fieldNameSub, fieldNameModel, fieldName, fieldType, tags, exceptionMessage;
	dyn_string dipItems, configItems, ds, dptNames;
	dyn_int childType;
	dyn_float df;
	string dpModel, dpNewModel, dpNewDevice, configDp, magnet, address, dpe, confDp, systemName, text, currentDpe, rampingDpe;
	int i, j, k, resultType, timeout,updateRate, err;
	bool confDpe, isConfigured;
	float valueDpe;
	
	string addressDIP = "dip";	

	confDpe = false;

	systemName = getSystemName();

	configItems = dpNames("*:*","_FwDipConfig");
	//get the name of the dpe with the current and ramping value
	currentDpe = "Current";
	rampingDpe = "Ramping";
	
	for (k=1; k<=dynlen(configItems); k++)
	{
		dynClear(dipItems);
		dynClear(childName);
		dynClear(childType);
		dynClear(fieldName);
		dynClear(fieldType);
		
		configDp = configItems[k];
	
		//configDp = "DIPConfig_1";
	
		if(!dpExists(configDp))
			return;
		dpGet(configDp+".queryTimeout", timeout);

		addressDIP = "dip/"+experim+"/MCS";

		DebugN("Getting publications...");
		//get all the publications for the selected experiment
		resultType = fwDIP_DipQuery(configDp, addressDIP,
							childName, childType,
							fieldName, fieldType,
							exceptionMessage, timeout);
		
		if (dynlen(exceptionMessage) != 0 )
		{
			if (strpos(exceptionMessage[2],"Timeout") >= 0)
			{
				fwException_raise(exceptionInfo, "ERROR", "The DIP manager is not running.","");
				return;
			}
			else 
			{
				fwException_raise(exceptionInfo, "ERROR", "There are no publications for the selected experiment.","");
				return;
			}

		}
		
		for(i=1; i<=dynlen(childName); i++)
		{
			dynAppend(dipItems, addressDIP+"/"+childName[i]);
		}

		if((dynlen(dipItems)<= 0) && (dynlen(fieldName)> 0))
			dynAppend(dipItems, addressDIP);

		
	
		for (i=1; i<=dynlen(dipItems); i++)
		{
			magnet = dipItems[i];
			confDpe = false;

			//if addressDIP is: dip/[experiment]/MCS
			strreplace(magnet, addressDIP,experim);

			//if addressDIP is: dip/[experiment]/MCS/[nameMagnet]	
			strreplace(magnet, "/","");
		
			dpGet(configDp+".queryTimeout", timeout);
		
			//get the dates for the subscription
			resultType = fwDIP_DipQuery(configDp, dipItems[i],
								childName, childType,
								fieldName, fieldType,
								exceptionMessage, timeout);
			
			if (dynContains(fieldName,currentDpe) == 0)
        		{
				ChildPanelOnCentralReturn("/fwInstallation/fwInstallation_selectValueList.pnl", "Warning", 
					makeDynString("$text: The publication "+dipItems[i]+"\nhas not been subscribed. \nIt was not possible to find the current value in the publication", 
					"$textList:", "$listContent:","$type:info"),df, ds);

           			continue;
        		}
        		if (dynContains(fieldName,rampingDpe) == 0)
        		{
				ChildPanelOnCentralReturn("/fwInstallation/fwInstallation_selectValueList.pnl", "Warning", 
					makeDynString("$text: The publication "+dipItems[i]+"\nhas not been subscribed. \nIt was not possible to find the ramping value in the publication \n", 
					"$textList:", "$listContent:","$type:info"),df, ds);

           			continue;
        		}
			tags = fieldName;
			
			//Create the models
			dpModel = "FwMagnetModelGeneric";
			dpNewModel = "FwMagnet"+magnet+"Model"+magnet;

			if(dpExists(dpNewModel))
				DebugN("Model definitions already exists. Will proceed with update mode!");

			dpCreate(dpNewModel, "_FwDeviceModel");
			dpCopyOriginal(dpModel, dpNewModel, err);

			fieldNameSub = fieldName;
			fieldNameModel = fieldName;

			for(j=1; j <= dynlen(fieldNameModel); j++)
				fieldNameModel[j] = "."+fieldNameModel[j];
			_setModelData(dpNewModel,fieldNameModel, currentDpe);
	
			dpSet(
				dpNewModel+".dpType", "FwMagnet"+experim,
				dpNewModel+".model", experim,
				// .modelDefinition.definition.properties
				dpNewModel+".modelDefinition.definition.properties.names", tags,
				dpNewModel+".modelDefinition.definition.properties.dpes", fieldNameModel,
				dpNewModel+".modelDefinition.definition.properties.userData", tags);

			//adding dpe's needed to calculate the direction of the ramping 
			dynAppend(fieldName,"OldCurrent");
			dynAppend(fieldType,22);
	
			dynAppend(fieldName,"NameDpe");
			dynAppend(fieldType,25);
	
			dynAppend(fieldName,"Direction");
			dynAppend(fieldType,22);

			dynAppend(fieldName,"model");
			dynAppend(fieldType,25);

			dpNewDevice = "FwMagnet"+experim;
			_fwCreateDPT(dpNewDevice, fieldName, fieldType, "create", exceptionMessage);
			
			dpCreate("MAGNET/"+magnet, dpNewDevice);
			
			//check if the subscription is already made
			for (j=1; j<=dynlen(fieldNameSub); j++)
			{
				fieldNameSub[j] = systemName+"MAGNET/"+magnet+"."+fieldNameSub[j];

				fwDIP_getDpeSubscription(fieldNameSub[j], isConfigured, confDp, address, exceptionMessage);

				if (confDpe == FALSE)
					confDpe = isConfigured; 
			}
			if (confDpe == TRUE)
			{
				DebugN("The datapoint Magnet"+magnet+" is already subscribed");

				_getDptFieldData(dpNewDevice, dptNames);
				if (_isSameStructure(dptNames,fieldName))
				{
					ChildPanelOnCentralReturn("/fwInstallation/fwInstallation_selectValueList.pnl", "Warning", 
						makeDynString("$text: The datapoint Magnet"+magnet+" is already subscribed.", 
						"$textList:", "$listContent:","$type:info"),df, ds);
					continue;
				}

				dyn_string dyns;
				dyns = dpNames("*",dpNewDevice);

				if (dynlen(dyns) >= 2)
				{
					ChildPanelOnCentralReturn("/fwInstallation/fwInstallation_selectValueList.pnl", "Warning", 
						makeDynString("$text: The datapoint is already subscribed with another structure,\nbut it is no possible to update the subscription "+dipItems[i]+" \nbecause more subscriptions exist in the same DPT.", 
						"$textList:", "$listContent:","$type:info"),df, ds);
					continue;
				}
				else
				{
					ChildPanelOnCentralReturn("/fwInstallation/fwInstallation_selectValueList.pnl", "Warning", 
						makeDynString("$text: The datapoint is already subscribed with another structure.\nDo you want to update the subscription "+dipItems[i]+" ?", 
						"$textList:", "$listContent:","$type:info"),df, ds);
				
					if (ds[1] == "cancel")
						return;
					else
                			{
                  		
                  			for (j=1; j<=dynlen(dptNames); j++)
	          				{
		    					dptNames[j] = systemName+"MAGNET/"+magnet+"."+dptNames[j];
                 				}
                  			fwDIP_unsubscribeMany(dptNames,exceptionMessage);
						_fwCreateDPT(dpNewDevice, fieldName, fieldType, "change", exceptionMessage);
						fwDIP_subscribeStructure(dipItems[i], fieldNameSub, tags, configDp, exceptionMessage);
						if ((dynlen(exceptionMessage) != 0) || (dynlen(fieldNameSub) == 0))
						{
							DebugN("There were errors while adding the subscription "+dipItems[i]);
							fwDIP_unsubscribeMany(fieldNameSub,exceptionMessage);
							continue;
						}
                      			_configureAdditionalDpe(currentDpe, rampingDpe, magnet, experim);
                			}
				}
			}
			else
			{
				fwDIP_subscribeStructure(dipItems[i], fieldNameSub, tags, configDp, exceptionMessage);
				if ((dynlen(exceptionMessage) != 0) || (dynlen(fieldNameSub) == 0))
				{
					DebugN("There were errors while adding the subscription "+ dipItems[i]);
					fwDIP_unsubscribeMany(fieldNameSub,exceptionMessage);
					continue;
				}
				DebugN("New subscription made: "+dipItems[i]);

				_configureAdditionalDpe(currentDpe, rampingDpe, magnet, experim);
			}
		}
	}
	if (!dpExists("fwOT_"+dpNewDevice+"_DU"))
	{
		ChildPanelOnCentralReturn("/fwInstallation/fwInstallation_selectValueList.pnl", "DU Values", 
					makeDynString("$text: The values for the DU are: \n          Current: "+currentDpe+"\n          Ramping: "+rampingDpe, 
					"$textList:", "$listContent:","$type:info"),df, ds);
		dynClear(exceptionMessage);
		_getValuesDeviceUnit(dpNewDevice, currentDpe, rampingDpe, values, exceptionMessage);

		if (dynlen(exceptionMessage) == 0)
			_createDeviceUnit(dpNewDevice, values);
	}

}


/** Function used for unsubscribing all the publications for an experiment
@par Constraints
	None

@par Usage
	Public

@par PVSS managers
	VISION, CTRL

@param experim			name of the experiment
*/

fwMCS_unsubscribeExperiment(string experim)
{
	string configDp;
	dyn_string configItems, dpes, exceptionMessage;
	dyn_dyn_string currentSubscriptionInfo;
	int i, j, k;
	
	configItems = dpNames("*:*","_FwDipConfig");
	for (i=1; i<=dynlen(configItems); i++)
	{
		fwDIP_getAllSubscriptions(configItems[i], currentSubscriptionInfo, exceptionMessage); 
		for (j=1; j<=dynlen(currentSubscriptionInfo); j++)
			for(k=1; k<=dynlen(currentSubscriptionInfo[1]); k++)
				if (strpos(currentSubscriptionInfo[2][k],experim)>=0)
					dynAppend(dpes,currentSubscriptionInfo[1][k]);
	}
	fwDIP_unsubscribeMany(dpes, exceptionMessage);
	DebugN("All the subscriptions for the experiment "+experim+" have been removed");
}

/**Function used for creating or changing a DPT for the DIP subscription
@par Constraints
	None

@par Usage
	Internal

@par PVSS managers
	VISION, CTRL

@param dptName			input, the name the DPT to create
@param fieldNames			input, field names of the DPT
@param fieldTypes			input, field types of the DPT
@param type				input, specify if the DPT has to be created on changed
@param exceptionMessage		output, information about errors
*/
_fwCreateDPT(string dptName, dyn_string fieldNames, dyn_int fieldTypes, string type, dyn_string &exceptionMessage)
{
	dyn_dyn_string a;
	dyn_dyn_int b;

	int length;
	length = dynlen(fieldNames);
	
	// check if there is no name collision
	if ((type == "create") && (_DPTExists(dptName)))
		return;

	// this is the 'root' element	
	a[1] = makeDynString(dptName, "");
	b[1] = makeDynInt(DPEL_STRUCT);

	// and the underlying flat structure
	for(int i=2; i<=length+1; i++)
	{
		a[i] = makeDynString("", fieldNames[i-1]);
		b[i] = makeDynInt(0, fieldTypes[i-1]);
	}
	int prueba;
	if (type == "change")
		prueba = dpTypeChange(a,b);
	else prueba = dpTypeCreate(a,b);
}


/**Function checks if the given dpt exist
@par Constraints
	None

@par Usage
	Internal

@par PVSS managers
	VISION, CTRL

@param pattern				input, the pattern the DPT to check
*/


bool _DPTExists(string pattern)
{
	if(dynlen(dpTypes(pattern))==1)
		return true;
	return false;
}

/**Function used for setting the model data
@par Constraints
	None

@par Usage
	Internal

@par PVSS managers
	VISION, CTRL

@param newDp		input, the name the DPT for the model
@param dS1			input, field names of publication
@param current		input, name of the current value
*/

_setModelData(string newDp, dyn_string dS1, string current)
{
	dyn_string empty, falses, trues, units;
	dyn_int zeroes;
	int i;
	
	current = "." + current;
	for(i = 1; i <= dynlen(dS1); i++)
	{
		trues[i] = "TRUE";
		empty[i] = "EMPTY";
		zeroes[i] = 0;
		falses[i] = "FALSE";

		if (dS1[i] == current)
			units[i] = "A";
		else
			units[i] = "EMPTY";
	}	

	dpSet(
			//newDp+".modelDefinition.definition.properties.names"
			//newDp+".modelDefinition.definition.properties.dpes"
			//newDp+".modelDefinition.definition.properties.description"
			newDp+".modelDefinition.definition.properties.defaultValues", empty,
			newDp+".modelDefinition.definition.properties.types", zeroes,
			//newDp+".modelDefinition.definition.properties.userData"
						
			newDp+".modelDefinition.definition.configuration.address.canHave", trues,
			newDp+".modelDefinition.definition.configuration.address.direction", zeroes, 		
			newDp+".modelDefinition.definition.configuration.address.OPC.items", empty,
			newDp+".modelDefinition.definition.configuration.address.OPC.groups", empty,
			newDp+".modelDefinition.definition.configuration.address.OPC.types", empty,
			newDp+".modelDefinition.definition.configuration.address.OPC.userDefined", empty,
			newDp+".modelDefinition.definition.configuration.address.OPC.direction", zeroes,
			newDp+".modelDefinition.definition.configuration.address.DIM.items", empty,
			newDp+".modelDefinition.definition.configuration.address.DIM.direction", zeroes,
			newDp+".modelDefinition.definition.configuration.address.MODBUS.direction", zeroes, 
			newDp+".modelDefinition.definition.configuration.address.DIP.direction", zeroes,
			newDp+".modelDefinition.definition.configuration.address.DIP.items", zeroes,
			newDp+".modelDefinition.definition.configuration.dpFunction.canHave", falses,
			newDp+".modelDefinition.definition.configuration.dpFunction.function", empty, 
			newDp+".modelDefinition.definition.configuration.dpFunction.params", empty,
			newDp+".modelDefinition.definition.configuration.alert.canHave", trues, 
			newDp+".modelDefinition.definition.configuration.alert.defaultClasses", empty,
			newDp+".modelDefinition.definition.configuration.alert.defaultTexts", empty,
			newDp+".modelDefinition.definition.configuration.alert.defaultLimits", empty,
			newDp+".modelDefinition.definition.configuration.archive.canHave", trues,
			newDp+".modelDefinition.definition.configuration.archive.defaultClass", empty,
			newDp+".modelDefinition.definition.configuration.archive.smoothType", zeroes,
			newDp+".modelDefinition.definition.configuration.archive.smoothProcedure", zeroes,
			newDp+".modelDefinition.definition.configuration.archive.deadband", zeroes,
			newDp+".modelDefinition.definition.configuration.archive.timeInterval", zeroes,
			newDp+".modelDefinition.definition.configuration.smoothing.canHave", falses,
			newDp+".modelDefinition.definition.configuration.smoothing.smoothProcedure", zeroes,
			newDp+".modelDefinition.definition.configuration.smoothing.deadband", zeroes,
			newDp+".modelDefinition.definition.configuration.smoothing.timeInterval", zeroes,
			newDp+".modelDefinition.definition.configuration.pvRange.canHave", falses,
			newDp+".modelDefinition.definition.configuration.pvRange.minValue", zeroes,
			newDp+".modelDefinition.definition.configuration.pvRange.maxValue", zeroes,
			newDp+".modelDefinition.definition.configuration.pvRange.negateRange", zeroes,
			newDp+".modelDefinition.definition.configuration.pvRange.ignoreOutside", zeroes,
			newDp+".modelDefinition.definition.configuration.pvRange.inclusiveMin", zeroes,
			newDp+".modelDefinition.definition.configuration.pvRange.inclusiveMax", zeroes,
			newDp+".modelDefinition.definition.configuration.format.canHave", falses,
			newDp+".modelDefinition.definition.configuration.format.format", empty,
			newDp+".modelDefinition.definition.configuration.unit.canHave", trues,
			newDp+".modelDefinition.definition.configuration.unit.unit", units,
			newDp+".modelDefinition.definition.configuration.conversion.canHave", falses,
			newDp+".modelDefinition.definition.configuration.conversion.type", empty,
			newDp+".modelDefinition.definition.configuration.conversion.conversionType", zeroes,
			newDp+".modelDefinition.definition.configuration.conversion.order", zeroes, 
			newDp+".modelDefinition.definition.configuration.conversion.arguments", zeroes 
			//newDp+".model"
				);	
}

/**Function used for configuing additional dpe's used in the DU Type
@par Constraints
	None

@par Usage
	Internal

@par PVSS managers
	VISION, CTRL

@param curDpe			input, the name of the current value in the publication
@param ramDpe			input, the name of the ramping value in the publication
@param magnetSel			input, the name of the selected magnet which is published
@param experiment			input, the name of the selected experiment
*/

_configureAdditionalDpe(string curDpe, string ramDpe, string magnetSel, string experiment)
{
  float valueDpe;
  string current, ramping;
  dyn_string ds, exceptionMessage;
  dyn_float df;
  
  current = "MAGNET/"+magnetSel+"."+curDpe;
  ramping = "MAGNET/"+magnetSel+"."+ramDpe;
  
  dpGet(current, valueDpe);
  dpSet("MAGNET/"+magnetSel+".OldCurrent",valueDpe,
  	"MAGNET/"+magnetSel+".NameDpe","MAGNET/"+magnetSel+".OldCurrent",
      "MAGNET/"+magnetSel+".Direction",0,
      "MAGNET/"+magnetSel+".model",experiment);
  fwDpFunction_setDpeConnection("MAGNET/"+magnetSel+".Direction",
                                  makeDynString(current+":_original.._value",
                                                ramping+":_original.._value"),
                                  makeDynString("MAGNET/"+magnetSel+".NameDpe:_original.._value"),
                                  "changeValue(p1,p2,g1)",
                                  exceptionMessage);  
}


/**For a given DTP the function returns the structure with the current and ramping value and their types.
@par Constraints
	None

@par Usage
	Internal

@par PVSS managers
	VISION, CTRL

@param DPT				input, the name of the DPT
@param current			input, the name of the current value in the publication
@param ramping			input, the name of the ramping value in the publication
@param names			output, structure with the current and ramping value and their types
@param exceptionMessage		output, information about errors
*/

_getValuesDeviceUnit(string DPT, string current, string ramping, dyn_dyn_string &names, dyn_string &exceptionMessage)
{
	//dyn_dyn_string names;
	dyn_dyn_int types;
	dyn_string nameList, typeList, ds;
	dyn_float df;
	string strDpe, typeDpe;
	int pos, i;
	
	dpTypeGet(DPT,names,types);

	for(i=2; i<=dynlen(names);i++)
	{
		if(dynlen(names[i])==2)
		{
			dynAppend(nameList,names[i][2]);
			dynAppend(typeList,types[i][2]);
		}
	}

	pos = dynContains(nameList,"OldCurrent");
	dynRemove(nameList,pos);
	dynRemove(typeList,pos);
	
	pos = dynContains(nameList,"NameDpe");
	dynRemove(nameList,pos);
	dynRemove(typeList,pos);
	
	pos = dynContains(nameList,"Direction");
	dynRemove(nameList,pos);
	dynRemove(typeList,pos);
	
	pos = dynContains(nameList,"model");
	dynRemove(nameList,pos);
	dynRemove(typeList,pos);

	fwGeneral_dynStringToString(nameList,strDpe);

	dynClear(names);	

	pos = dynContains(nameList, current);
	_getDataType(typeList[pos],typeDpe);
	dynAppend(names[1],makeDynString(typeDpe,nameList[pos]));
		
	pos = dynContains(nameList, ramping);
	_getDataType(typeList[pos],typeDpe);
	dynAppend(names[2],makeDynString(typeDpe,nameList[pos]));	
}


/**Function for creating a DU Type for the magnets of an experiment.
@par Constraints
	None

@par Usage
	Internal

@par PVSS managers
	VISION, CTRL

@param fwMagnetDP			input, the name of the DPT for the magnets of an experiment
@param values			input, structure with the current and ramping value and their types
*/

_createDeviceUnit(string fwMagnetDP, dyn_dyn_string values)
{
	string nameDp, nameDU;
	dyn_string components, states;
	int i, typeCurrent, typeRamping;
	
	DebugN("Adding the device unit...");    
	
	nameDp = "fwOT_"+fwMagnetDP+"_DU";
	nameDU = fwMagnetDP+"_DU";
	dpCreate(nameDp, "_FwFsmObjectType");
	
	dynAppend(components,values[1][1]+" "+values[1][2]+"\nfloat Direction\n"+values[2][1]+" "+values[2][2]+"\n");
	dynAppend(components,"");
	dynAppend(components,nameDU+"_initialize(string domain, string device)\n{\n}");
	dynAppend(components,nameDU+"_valueChanged( string domain, string device,\n\t"+values[1][1]+" "+values[1][2]+",\n\tfloat Direction,\n\t"+values[2][1]+" "+values[2][2]+", string &fwState )\n{\n\tif (\n\t("+values[1][2]+" >= 1) &&\n\t(Direction == 0) )\n\t{\n\t\tfwState = \"ON\";\n\t}else if (\n\t("+values[1][2]+" < 1) &&\n\t(Direction == 0) )\n\t{\n\t\tfwState = \"OFF\";\n\t}\n\telse if (\n\t("+values[2][2]+" == TRUE) &&\n\t(Direction == 2) &&\n\t("+values[1][2]+" >= 1) )\n\t{\n\t\tfwState = \"RAMPING_UP\";\n\t}\n\telse if (\n\t("+values[2][2]+" == TRUE) &&\n\t(Direction == 1) &&\n\t("+values[1][2]+" >= 1) )\n\t{\n\t\tfwState = \"RAMPING_DOWN\";\n\t}\n\telse \n\t{\n\t\tfwState = \"ERROR\";\n\t}\n}\n");
	                                                                                                                                                                                                                       
        dynAppend(components,nameDU+"_doCommand(string domain, string device, string command)\n{\n}");
	
	dynAppend(states,"ON");
	dynAppend(states,"FwStateOKPhysics");
	dynAppend(states,"");
	dynAppend(states,"");
	dynAppend(states,"");
	dynAppend(states,"OFF");
	dynAppend(states,"FwStateOKNotPhysics");
	dynAppend(states,"");
	dynAppend(states,"");
	dynAppend(states,"");
	dynAppend(states,"RAMPING_UP");
	dynAppend(states,"FwStateAttention1");
	dynAppend(states,"");
	dynAppend(states,"");
	dynAppend(states,"");
	dynAppend(states,"RAMPING_DOWN");
	dynAppend(states,"FwStateAttention1");
	dynAppend(states,"");
	dynAppend(states,"");
	dynAppend(states,"");
	dynAppend(states,"ERROR");
	dynAppend(states,"FwStateAttention3");
       dynAppend(states,"");
	dynAppend(states,"");
	dynAppend(states,"");

	dpSet(nameDp+".panel",fwMagnetDP+"|"+fwMagnetDP+"_DU.pnl",
				nameDp+".components",components,
				nameDp+".states", states);
	
	DebugN("The device unit has been created.");
}

/**For a given DTP the function gets the structure with the names of its dpes.
@par Constraints
	None

@par Usage
	Internal

@par PVSS managers
	VISION, CTRL

@param DPT				input, the name of the DPT
@param dfn			output, structure with the names of the dpes for the DPT
*/

_getDptFieldData(string DPT, dyn_string &dfn)
{
	dynClear(dfn);

	dyn_dyn_string names;
	dyn_dyn_int types;
	dpTypeGet(DPT,names,types);
	for(int i=2; i<=dynlen(names);i++)
	{
		if(dynlen(names[i])==2)
		{
			dynAppend(dfn,names[i][2]);
		}
	}	
}

/**Checks if two structures have the same content.
@par Constraints
	None

@par Usage
	Internal

@par PVSS managers
	VISION, CTRL

@param ds1			input, structure number 1
@param ds2			input, structure number 2
*/

bool _isSameStructure(dyn_string ds1, dyn_string ds2)
{
	dynSortAsc(ds1);
	dynSortAsc(ds2);
	if (dynlen(ds1) == dynlen(ds2))
	{
		for (int i = 1; i <= dynlen(ds1); i++)
			if (ds1[i] != ds2[i])
				return false;
		return true;
	}
	else return false;
}


/**Returns the type in a string.
@par Constraints
	None

@par Usage
	Internal

@par PVSS managers
	VISION, CTRL

@param typeIn			input, type in a int
@param typeOut			output, type in a string
*/

_getDataType(int typeIn, string &typeOut)
{
	switch (typeIn)
	{
		case DPEL_INT:
			typeOut = "int";
			break;
		case DPEL_FLOAT:
			typeOut = "float";
			break;
		case DPEL_BOOL:
			typeOut = "bool";
			break;
		case DPEL_STRING:
			typeOut = "string";
			break;
		default:
			DebugN("Unknow type for Dpe: " + dpe);
			typeOut="";
			break;
	}
}


//@}  