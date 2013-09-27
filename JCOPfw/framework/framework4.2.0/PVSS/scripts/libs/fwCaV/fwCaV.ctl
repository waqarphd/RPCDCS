/**@file

This library contains functions and constants needed by the fwCaV -
- the Cooling and Ventilation

@par Creation Date
	24/06/2004

@par Modification History
	None
	
@par Constraints
	None

@par Usage
	Public

@par PVSS managers
	VISION, CTRL

@author 
	Milosz Marian Hulboj (IT-CO)
*/

//@{ 

/* DataPointTypes */

/* Synoptics Bitmap DPTs */
string fwCaV_SynopticsBitmapDPT = "_FwCaVSynopticsBitmap";
string fwCaV_SynopticsWidgetDPT = "_FwCaVSynopticsWidget";
string fwCaV_SynopticsWidgetDefinitionDPT = "_FwCaVSynopticsWidgetDefinition";

/* Plot DPTs */
string fwCaV_PlotDPT = "_FwCaVPageDefinition";


/* CaV Device DPTs */
string fwCaV_MasterPlantDPT = "FwCaVMasterPlant";
string fwCaV_PlantDPT = "FwCaVPlant";
string fwCaV_GroupDPT = "FwCaVGroup";
string fwCaV_LoopDPT = "FwCaVLoop";


/* Paths to panels */

string fwCaV_SynopticsPATH = "objects/fwCaV/fwCaVSynopticsBitmapPanel.pnl";
string fwCaV_SynopticsGridPATH = "objects/fwCaV/fwCaVSynopticsBitmapPanelEditorGrid.pnl";
string fwCaV_InputDialogPATH = "fwCaV/fwCaVInputDialog.pnl";
string fwCaV_WidgetConfiguratorPATH = "fwCaV/fwCaVSynopticsBitmapWidgetConfiguratorAdditionalParameters.pnl";
string fwCaV_PanelConfiguratorParametersPATH = "fwCaV/fwCaVSynopticsBitmapPanelConfiguratorAdditionalParameters.pnl";
string fwCaV_SynopticsNewPATH = "fwCaV/fwCaVSynopticsBitmapNewPanel.pnl";

/* Indexes for the structure describing the generic dpe */
int fwCaV_genericDpe = 1;
int fwCaV_genericVarName = 2;
int fwCaV_genericDescription = 3;
int fwCaV_genericUserData = 4;


/* Indexes for the structure describing the Widget Type */
int fwCaV_WidgetDefinition_Filename = 1;
int fwCaV_WidgetDefinition_Description = 2;
int fwCaV_WidgetDefinition_DpeDescriptions = 3;
int fwCaV_WidgetDefinition_ExtraParametersDescription = 4;

/* Indexes for the structure describing the Widget Instance */
int fwCaV_SynopticsBitmap_Type = 1;
int fwCaV_WidgetInstance_DeviceDp = 2;
int fwCaV_WidgetInstance_Properties = 3;
int fwCaV_WidgetInstance_ExtraParameters = 4;
int fwCaV_WidgetInstance_Visible = 5;
int fwCaV_WidgetInstance_Position_x = 6;
int fwCaV_WidgetInstance_Position_y = 7;


/* Indexes for the structure describing the Synoptics Bitmap */
int fwCaV_SynopticsBitmap_Image = 1;
int fwCaV_SynopticsBitmap_Description = 2;
int fwCaV_SynopticsBitmap_Size_x = 3;
int fwCaV_SynopticsBitmap_Size_y = 4;
int fwCaV_SynopticsBitmap_PlotType = 5;


/* Constants used in many places */

string fwCaV_MiniTrendIconFILL = "[pattern,[fit,gif,fwCaVMiniTrendIcon.gif]]";

string fwCaV_DefaultFormatString = "%4.3f";
string fwCaV_DefaultColorTRUE = "FwStateOKPhysics";
string fwCaV_DefaultColorFALSE = "FwStateAttention3";

int fwCaV_MAX_PLOTS = 4;
string fwCaV_PLOTPREFIX = "CaVPlot";



/** Function used for obtaining information about a dpe in the generic DPT
@par Constraints
@par Usage
	Public
@par PVSS managers
	VISION, CTRL
@param dpe			datapoint element about which data will be returned
@param elements			Structure with data corresponding to provided dpe:
				<ul>
				<li>elements[fwCaV_genericDpe] - datapoint element suffix (without dpName)</li>
				<li>elements[fwCaV_genericVarName] - element name (usually variable name from the SCY)</li>
				<li>elements[fwCaV_genericDescription] - element description</li>
				<li>elements[fwCaV_genericUserData] - element specific UserData</li>
				</ul>
@param exceptionInfo		returns details of any errors
*/

fwCaV_genericParameterInfo(string dpe, dyn_string &elements, dyn_string &exceptionInfo)
{
	if(!dpExists(dpe))
	{
		fwException_raise(exceptionInfo, "ERROR", "DPE "+dpe+" does not exist.","");
		return;
	}
	string dp = dpSubStr(dpe,DPSUB_SYS_DP);
	string el = substr(dpe,strlen(dp));
	
	string deviceDpType, deviceModel;
	dyn_dyn_string _elements;
	deviceDpType = dpTypeName(dp);
	fwDevice_getModel(makeDynString(dp), deviceModel, exceptionInfo);
	fwDevice_getConfigElements(deviceDpType, fwDevice_ALL, _elements, exceptionInfo, deviceModel, dp);
	// Because fwDevice_getConfigElements returns an exception when called with fwDevice_ALL 
	dynClear(exceptionInfo);
	int pos = dynContains(_elements[fwDevice_ELEMENTS_INDEX],el);
	if(pos<=0)
	{
		elements = makeDynString();
		fwException_raise(exceptionInfo, "ERROR", "Given dpe seems to be undefined for model "+deviceModel,"");
		return;
	}
	
	elements[fwCaV_genericDpe] = _elements[fwDevice_ELEMENTS_INDEX][pos];
	elements[fwCaV_genericVarName] = _elements[fwDevice_PROPERTY_NAMES_INDEX][pos];
	elements[fwCaV_genericDescription] = 0;//_elements[][pos];
	elements[fwCaV_genericUserData] = _elements[fwDevice_USER_DATA_INDEX][pos];
}

/** Function used for obtaining variable name of a dpe in the generic DPT
@par Constraints
@par Usage
	Public
@par PVSS managers
	VISION, CTRL
@param dpe			datapoint element about which data will be returned
@return 			parameter name if exists. empty string otherwise
*/

string fwCaV_genericDpeVarName(string dpe)
{
	dyn_string exceptionInfo;
	dyn_string elements;
	fwCaV_genericParameterInfo(dpe, elements, exceptionInfo);
	if(dynlen(exceptionInfo)!=0)
		return "";
	else
		return elements[fwCaV_genericVarName];
}


/** Function used for obtaining description of a dpe in the generic DPT
@par Constraints
@par Usage
	Public
@par PVSS managers
	VISION, CTRL
@param dpe			datapoint element about which data will be returned
@return 			parameter description if exists. empty string otherwise
*/

string fwCaV_genericDpeDescription(string dpe)
{
	dyn_string exceptionInfo;
	dyn_string elements;
	fwCaV_genericParameterInfo(dpe, elements, exceptionInfo);
	if(dynlen(exceptionInfo)!=0)
		return "";
	else
		return elements[fwCaV_genericUserData];
}


/** Function used for obtaining UserData about a dpe in the generic DPT
@par Constraints
@par Usage
	Public
@par PVSS managers
	VISION, CTRL
@param dpe			datapoint element about which data will be returned
@return 			parameter UserData if exists. empty string otherwise
*/

string fwCaV_genericDpeUserData(string dpe)
{
	dyn_string exceptionInfo;
	dyn_string elements;
	fwCaV_genericParameterInfo(dpe, elements, exceptionInfo);
	if(dynlen(exceptionInfo)!=0)
		return "";
	else
		return elements[fwCaV_genericDescription];
}





/******************************************************************************/

/** Function used for registering a new widget type for use with Synoptics Bitmap facility
@par Constraints
@par Usage
	Public
@par PVSS managers
	VISION, CTRL
@param name					name of the widget to register
@param exceptionInfo		returns details of any errors
*/

fwCaV_registerWidgetType(string name, dyn_string &exceptionInfo)
{
	if(!dpIsLegalName(name))
	{
		fwException_raise(exceptionInfo, "ERROR", "Invalid name:" +name+".","");
		return;
	}
	if(dpExists(name))
	{
		fwException_raise(exceptionInfo, "ERROR", "Widget definition with name:" +name+" already exists.","");
		return;
	}	
	dpCreate(name, fwCaV_SynopticsWidgetDefinitionDPT);
}

/** Function used for unregistering a widget type with Synoptics Bitmap facility
@par Constraints
@par Usage
	Public
@par PVSS managers
	VISION, CTRL
@param name			name of the widget to unregister
@param exceptionInfo		returns details of any errors
@param cascade			whether to remove all the instances of this widget type (default = false)
*/

fwCaV_unregisterWidgetType(string name, dyn_string &exceptionInfo, bool cascade=false)
{
	// Check if the DP exists
	if(!dpExists(name))
	{
		fwException_raise(exceptionInfo, "ERROR", "Widget definition with name:" +name+" does not exist.","");
		return;
	}
	// And check if it is really of the proper type
	if(dpTypeName(name)!=fwCaV_SynopticsWidgetDefinitionDPT)
	{
		fwException_raise(exceptionInfo, "ERROR", name+" is not of widget type definition type. Aborting.","");
		return;
	}
	if(cascade)
	{
		// Get the list of Widget Type instances
		dyn_string instances;
		instances = dpNames("*", fwCaV_SynopticsWidgetDPT);
		for(int i=1; i<=dynlen(instances); i++)
		{
			string tmp;
			dpGet(instances[i]+".panel", tmp);
			if(tmp == name)
			{
				DebugN("Deleting " + instances[i]);
				dpDelete(instances[i]);
			}
		}
	}
	// Remove the Widget Type datapoint
	dpDelete(name);
}

/** Function used for listing all registered widget types for use with Synoptics Bitmap facility
@par Constraints
@par Usage
	Public
@par PVSS managers
	VISION, CTRL
@param names				names of the widget types
@param stripSystemName			whether to strip the system name from the DPs (default = true)
*/

fwCaV_listWidgetTypes(dyn_string &names, bool stripSystemName=true)
{
	names = dpNames("*", fwCaV_SynopticsWidgetDefinitionDPT);
	if(stripSystemName)
	{
		for(int i=1; i<=dynlen(names); i++)
			names[i] = dpSubStr(names[i], DPSUB_DP);
	}
}


/** For a given Widget Type registered with Synoptics Bitmap facility returns
	 the structure with all the parameters.
@par Constraints
@par Usage
	Public
@par PVSS managers
	VISION, CTRL
@param name					name of the widget
@param parameters			structure with data about the given widget type
							<ul>
							<li>parameters[fwCaV_WidgetDefinition_Filename] - filename of the panel</li>
							<li>parameters[fwCaV_WidgetDefinition_Description] - description of the widget</li>
							<li>parameters[fwCaV_WidgetDefinition_DpeDescriptions] - dyn_string with descriptions what a given dpe passed to the widget means</li>
							<li>parameters[fwCaV_WidgetDefinition_ExtraParametersDescription] - dyn_string with descriptions what a given extra parameter passed to the widget means</li>
							</ul>
@param exceptionInfo		returns details of any errors
*/

fwCaV_getWidgetTypeDetails(string name, dyn_dyn_string &parameters, dyn_string &exceptionInfo)
{
	if(!dpExists(name))
	{
		fwException_raise(exceptionInfo, "ERROR", "Widget definition with name:" +name+" does not exist.","");
		return;
	}
	// And check if it is really of the proper type
	if(dpTypeName(name)!=fwCaV_SynopticsWidgetDefinitionDPT)
	{
		fwException_raise(exceptionInfo, "ERROR", name+" is not of widget type definition type. Aborting.","");
		return;
	}
	dpGet(name+".filename", parameters[fwCaV_WidgetDefinition_Filename],
			name+".description", parameters[fwCaV_WidgetDefinition_Description], 
			name+".dpesDescription", parameters[fwCaV_WidgetDefinition_DpeDescriptions],
			name+".extraParametersDescription",parameters[fwCaV_WidgetDefinition_ExtraParametersDescription]);
}

/** For a given Widget Type registered with Synoptics Bitmap facility sets the parameters
	 which are passed in a structure
@par Constraints
@par Usage
	Public
@par PVSS managers
	VISION, CTRL
@param name					name of the widget
@param parameters			structure with data about the given widget type
							<ul>
							<li>parameters[fwCaV_WidgetDefinition_Filename] - filename of the panel</li>
							<li>parameters[fwCaV_WidgetDefinition_Description] - description of the widget</li>
							<li>parameters[fwCaV_WidgetDefinition_DpeDescriptions] - dyn_string with descriptions what a given dpe passed to the widget means</li>
							<li>parameters[fwCaV_WidgetDefinition_ExtraParametersDescription] - dyn_string with descriptions what a given extra parameter passed to the widget means</li>
							</ul>
@param exceptionInfo		returns details of any errors
*/

fwCaV_setWidgetTypeDetails(string name, dyn_dyn_string parameters, dyn_string &exceptionInfo)
{
	if(!dpExists(name))
	{
		fwException_raise(exceptionInfo, "ERROR", "Widget definition with name:" +name+" does not exist.","");
		return;
	}
	// And check if it is really of the proper type
	if(dpTypeName(name)!=fwCaV_SynopticsWidgetDefinitionDPT)
	{
		fwException_raise(exceptionInfo, "ERROR", name+" is not of widget type definition type. Aborting.","");
		return;
	}
	dpSetWait(name+".filename", parameters[fwCaV_WidgetDefinition_Filename],
			name+".description", parameters[fwCaV_WidgetDefinition_Description], 
			name+".dpesDescription", parameters[fwCaV_WidgetDefinition_DpeDescriptions],
			name+".extraParametersDescription",parameters[fwCaV_WidgetDefinition_ExtraParametersDescription]);
}


/** For a given Synoptics Bitmap panel, returns a list of all widgets belonging to that panel.
@par Constraints
@par Usage
	Public
@par PVSS managers
	VISION, CTRL
@param panelname			name of the Synoptics Bitmap dp
@param list				list of widgets belonging to given Synoptics Panel
@param exceptionInfo			returns details of any errors
@param stripSystemName			whether to strip the system name from the DPs (default = true)
*/

fwCaV_listSynopticsPanelWidgets(string panelname, dyn_string &list, dyn_string &exceptionInfo, bool stripSystemName=true)
{
	if(!dpExists(panelname))
	{
		fwException_raise(exceptionInfo, "ERROR", "Widget definition with name:" +name+" does not exist.","");
		return;
	}
	if(dpTypeName(panelname)!=fwCaV_SynopticsBitmapDPT)
	{
		fwException_raise(exceptionInfo, "ERROR", name+" is not of Synoptics Bitmap type. Aborting.","");
		return;
	}
	list = dpNames(panelname+"/*", fwCaV_SynopticsWidgetDPT);	
	if(stripSystemName)
	{
		for(int i=1; i<=dynlen(list); i++)
			list[i] = dpSubStr(list[i], DPSUB_DP);
	}
}

/** Variation of fwCaV_listSynopticsPanelWidgets. Returns only the widget instances
    names (without bitmapDp+"/" prefix)
@par Constraints
@par Usage
	Public
@par PVSS managers
	VISION, CTRL
@param panelname			name of the Synoptics Bitmap dp
@param list				list of widgets belonging to given Synoptics Panel (only widget names, not dp names)
@param exceptionInfo			returns details of any errors
*/

fwCaV_listStrippedSynopticsPanelWidgets(string panelname, dyn_string &list, dyn_string &exceptionInfo)
{
	fwCaV_listSynopticsPanelWidgets(panelname, list, exceptionInfo, true);
	if(dynlen(exceptionInfo)!=0)
		return;
	for(int i=1; i<=dynlen(list); i++)
	{
		list[i] = strsplit(list[i],"/")[2];
	}
}


/** Function used for registering a new Synoptics Bitmap panel
@par Constraints
@par Usage
	Public
@par PVSS managers
	VISION, CTRL
@param name			name of panel to register
@param exceptionInfo		returns details of any errors
*/

fwCaV_registerSynopticsPanel(string name, dyn_string &exceptionInfo)
{
	if(!dpIsLegalName(name))
	{
		fwException_raise(exceptionInfo, "ERROR", "Invalid name:" +name+".","");
		return;
	}
	if(dpExists(name))
	{
		fwException_raise(exceptionInfo, "ERROR", "Synoptics Panel with name:" +name+" already exists.","");
		return;
	}	
	dpCreate(name, fwCaV_SynopticsBitmapDPT);
}

/** Function used for deleting the Synoptics Bitmap DP
@par Constraints
@par Usage
	Public
@par PVSS managers
	VISION, CTRL
@param name			name of the SynopticsBitmap DP to remove
@param exceptionInfo		returns details of any errors
@param cascade			whether to remove all the widgets of that Synoptics Panel (default = true)
*/

fwCaV_unregisterSynopticsPanel(string name, dyn_string &exceptionInfo, bool cascade=true)
{
	// Check if the DP exists
	if(!dpExists(name))
	{
		fwException_raise(exceptionInfo, "ERROR", "Synoptics Panel with name:" +name+" does not exist.","");
		return;
	}
	// And check if it is really of the proper type
	if(dpTypeName(name)!=fwCaV_SynopticsBitmapDPT)
	{
		fwException_raise(exceptionInfo, "ERROR", name+" is not of Synoptics Panel definition type. Aborting.","");
		return;
	}
	if(cascade)
	{
		// Get the list of children widgets
		dyn_string instances;
		string nameWidget;
		// instances = dpNames("*", fwCaV_SynopticsWidgetDPT);
		fwCaV_listSynopticsPanelWidgets(name, instances, exceptionInfo);
		for(int i=1; i<=dynlen(instances); i++)
		{
			DebugN("Deleting " + instances[i]);
			nameWidget = substr(instances[i], strpos(instances[i],"/")+1);
			//the second parameter of the function is the name of the widget not the instance name of the widget
			fwCaV_deleteWidgetInstance(name,nameWidget,exceptionInfo);
			//dpDelete(instances[i]);
		}
	}

	dyn_dyn_anytype loops;
	int z;
	dyn_string loopDp;
	string nameLoop;

	//Delete the value of the DPe .bitmapDp and .bitmapOverride from the Dp with references to the deleted widget
	dpQuery("SELECT'_original.._value'FROM'CaV/*'WHERE'_original.._value'==\""+name+"\"",loops);
	for (z=2;z<=dynlen(loops);z++)
	{
		loopDp = strsplit(((string)loops[z][1]),":");
		nameLoop = substr(loopDp[2],0,strpos(loopDp[2],".bitmapDp"));
		dpSet(nameLoop+".bitmapDp","",nameLoop+".bitmapOverride","");
	}

	// Remove the Synoptics Bitmap datapoint
	dpDelete(name);
}

/** Returns the list of all the synoptics panels.
@par Constraints
@par Usage
	Public
@par PVSS managers
	VISION, CTRL
@param list				list of Synoptics Panels
@param searchSystem			the system to search on - must include : (default = local system)
*/

fwCaV_listSynopticsPanels(dyn_string &list, string searchSystem="")
{
	list = dpNames(searchSystem + "*", fwCaV_SynopticsBitmapDPT);
}

/** For a given Synoptics Bitmap facility returns
	 the structure with all the parameters.
@par Constraints
@par Usage
	Public
@par PVSS managers
	VISION, CTRL
@param name				name of the Synoptics Bitmap DP
@param parameters			structure with data about the given Synoptics Bitmap
							<ul>
							<li>parameters[fwCaV_SynopticsBitmap_Image] - path to the bitmap file (image)</li>
							<li>parameters[fwCaV_SynopticsBitmap_Description] - description of the Synoptics Bitmap</li>
							<li>parameters[fwCaV_SynopticsBitmap_Size_x] - x size (in pixels)</li>
							<li>parameters[fwCaV_SynopticsBitmap_Size_y] - y size (in pixels)</li>
							<li>parameters[fwCaV_SynopticsBitmap_PlotType] - size for the plots</li>
							</ul>
@param exceptionInfo		returns details of any errors
*/

fwCaV_getSynopticsPanelDetails(string name, dyn_string &parameters, dyn_string &exceptionInfo)
{
	if(!dpExists(name))
	{
		fwException_raise(exceptionInfo, "ERROR", "Synoptics Bitmap with name:" +name+" does not exist.","");
		return;
	}
	// And check if it is really of the proper type
	if(dpTypeName(name)!=fwCaV_SynopticsBitmapDPT)
	{
		fwException_raise(exceptionInfo, "ERROR", name+" is not of Synoptics Panel definition type. Aborting.","");
		return;
	}
	dpGet(name+".image",parameters[fwCaV_SynopticsBitmap_Image],
		name+".description",parameters[fwCaV_SynopticsBitmap_Description],
		name+".Size.x",parameters[fwCaV_SynopticsBitmap_Size_x],
		name+".Size.y",parameters[fwCaV_SynopticsBitmap_Size_y],
		name+".plotType",parameters[fwCaV_SynopticsBitmap_PlotType]);
}


/** For a given Synoptics Bitmap facility sets the all the parameters according to data passed in the structure
@par Constraints
@par Usage
	Public
@par PVSS managers
	VISION, CTRL
@param name				name of the Synoptics Bitmap DP
@param parameters			structure with data about the given Synoptics Bitmap
							<ul>
							<li>parameters[fwCaV_SynopticsBitmap_Image] - path to the bitmap file (image)</li>
							<li>parameters[fwCaV_SynopticsBitmap_Description] - description of the Synoptics Bitmap</li>
							<li>parameters[fwCaV_SynopticsBitmap_Size_x] - x size (in pixels)</li>
							<li>parameters[fwCaV_SynopticsBitmap_Size_y] - y size (in pixels)</li>
							<li>parameters[fwCaV_SynopticsBitmap_PlotType] - size for the plots</li>
							</ul>
@param exceptionInfo		returns details of any errors
*/

fwCaV_setSynopticsPanelDetails(string name, dyn_string parameters, dyn_string &exceptionInfo)
{
	if(!dpExists(name))
	{
		fwException_raise(exceptionInfo, "ERROR", "Synoptics Bitmap with name:" +name+" does not exist.","");
		return;
	}
	// And check if it is really of the proper type
	if(dpTypeName(name)!=fwCaV_SynopticsBitmapDPT)
	{
		fwException_raise(exceptionInfo, "ERROR", name+" is not of Synoptics Panel definition type. Aborting.","");
		return;
	}
	dpSetWait(name+".image",parameters[fwCaV_SynopticsBitmap_Image],
		name+".description",parameters[fwCaV_SynopticsBitmap_Description],
		name+".Size.x",parameters[fwCaV_SynopticsBitmap_Size_x],
		name+".Size.y",parameters[fwCaV_SynopticsBitmap_Size_y],
		name+".plotType",parameters[fwCaV_SynopticsBitmap_PlotType]);
}


/** Function used for creating a new instance of given Widget Type in given
    Synoptics Bitmap
@par Constraints
@par Usage
	Public
@par PVSS managers
	VISION, CTRL
@param bitmapName		name of Synoptics Bitmap for which the widget instance is created
@param instanceName		name of widget instance
@param exceptionInfo		returns details of any errors
*/

fwCaV_createWidgetInstance(string bitmapName, string instanceName, dyn_string &exceptionInfo)
{
	string name;
	//bitmapName = dpSubStr(bitmapName, DPSUB_DP);
	name = bitmapName + "/" + instanceName;
	DebugN("Test1234");
	if(!dpIsLegalName(name))
	{
		fwException_raise(exceptionInfo, "ERROR", "Invalid name:" +name+".","");
		return;
	}
	if(dpExists(name))
	{
		fwException_raise(exceptionInfo, "ERROR", "Widget instance:" +name+" already exists.","");
		return;
	}	
	dpCreate(name, fwCaV_SynopticsWidgetDPT);
}

/** Function used for creating a new instance of given Widget Type in given
    Synoptics Bitmap
@par Constraints
@par Usage
	Public
@par PVSS managers
	VISION, CTRL
@param bitmapName		name of Synoptics Bitmap for which the widget instance is created
@param instanceName		name of widget
@param exceptionInfo		returns details of any errors
*/

fwCaV_deleteWidgetInstance(string bitmapName, string instanceName, dyn_string &exceptionInfo)
{
	string name;
	bitmapName = dpSubStr(bitmapName, DPSUB_DP);
	//instanceName = dpSubStr(instanceName, DPSUB_DP);
	name = bitmapName + "/" + instanceName;
	if(!dpExists(name))
	{
		fwException_raise(exceptionInfo, "ERROR", "Widget instance:" +name+" does not exist.","");
		return;
	}	
	dpDelete(name);
}







/** Function returns a structure with information about the given Widget Instance 
@par Constraints
@par Usage
	Public
@par PVSS managers
	VISION, CTRL
@param bitmapName		name of Synoptics Bitmap for which the widget instance is created
@param instanceName		name of widget instance
@param parameters		structure with data about the given Widget Instance
				<ul>
				<li>parameters[fwCaV_SynopticsBitmap_Type] - Widget Type</li>
				<li>parameters[fwCaV_WidgetInstance_DeviceDp] - Which Framework the widget is connecting to</li>
				<li>parameters[fwCaV_WidgetInstance_Properties] - To which properties of that Device</li>
				<li>parameters[fwCaV_WidgetInstance_ExtraParameters] - extra parameters passed to widget refpanel</li>
				<li>parameters[fwCaV_WidgetInstance_Visible] - whether the Widget Instance is displayed</li>
				<li>parameters[fwCaV_WidgetInstance_Position_x] - x relative position (in percents)</li>
				<li>parameters[fwCaV_WidgetInstance_Position_y] - y relative position (in percents)</li>
				</ul>
@param exceptionInfo		returns details of any errors
*/

fwCaV_getWidgetInstanceDetails(string bitmapName, string instanceName, dyn_anytype &parameters, dyn_string &exceptionInfo)
{
	string name;
	//bitmapName = dpSubStr(bitmapName, DPSUB_DP);
	//instanceName = dpSubStr(instanceName, DPSUB_DP);
	name = bitmapName + "/" + instanceName;
	if(!dpExists(name))
	{
		fwException_raise(exceptionInfo, "ERROR", "Widget instance with name:" +name+" does not exist.","");
		return;
	}
	// And check if it is really of the proper type
	if(dpTypeName(name)!=fwCaV_SynopticsWidgetDPT)
	{
		fwException_raise(exceptionInfo, "ERROR", name+" is not of widget instance type. Aborting.","");
		return;
	}
	dpGet(name+".panel",parameters[fwCaV_SynopticsBitmap_Type],
		name+".Data.deviceDp",parameters[fwCaV_WidgetInstance_DeviceDp],
		name+".Data.properties",parameters[fwCaV_WidgetInstance_Properties],
		name+".Data.extraParameters",parameters[fwCaV_WidgetInstance_ExtraParameters],
		name+".visible",parameters[fwCaV_WidgetInstance_Visible],
		name+".Position.x",parameters[fwCaV_WidgetInstance_Position_x],
		name+".Position.y",parameters[fwCaV_WidgetInstance_Position_y]
	);
}

/** Function sets information about the given Widget Instance according to the data in structure
@par Constraints
@par Usage
	Public
@par PVSS managers
	VISION, CTRL
@param bitmapName		name of Synoptics Bitmap for which the widget instance is created
@param instanceName		name of widget instance
@param parameters		structure with data about the given Widget Instance
				<ul>
				<li>parameters[fwCaV_SynopticsBitmap_Type] - Widget Type</li>
				<li>parameters[fwCaV_WidgetInstance_deviceDp] - Which Framework the widget is connecting to</li>
				<li>parameters[fwCaV_WidgetInstance_properties] - To which properties of that Device</li>
				<li>parameters[fwCaV_WidgetInstance_extraParameters] - extra parameters passed to widget refpanel</li>
				<li>parameters[fwCaV_WidgetInstance_visible] - whether the Widget Instance is displayed</li>
				<li>parameters[fwCaV_WidgetInstance_Position_x] - x relative position (in percents)</li>
				<li>parameters[fwCaV_WidgetInstance_Position_y] - y relative position (in percents)</li>
				</ul>
@param exceptionInfo		returns details of any errors
*/

fwCaV_setWidgetInstanceDetails(string bitmapName, string instanceName, dyn_anytype parameters, dyn_string &exceptionInfo)
{
	string name;
	//bitmapName = dpSubStr(bitmapName, DPSUB_DP);
	//instanceName = dpSubStr(instanceName, DPSUB_DP);
	name = bitmapName + "/" + instanceName;
	if(!dpExists(name))
	{
		fwException_raise(exceptionInfo, "ERROR", "Widget instance with name:" +name+" does not exist.","");
		return;
	}
	// And check if it is really of the proper type
	if(dpTypeName(name)!=fwCaV_SynopticsWidgetDPT)
	{
		fwException_raise(exceptionInfo, "ERROR", name+" is not of widget instance type. Aborting.","");
		return;
	}
	fwCaV_deleteWidgetInstance(bitmapName, instanceName, exceptionInfo);
	fwCaV_createWidgetInstance(bitmapName, instanceName, exceptionInfo);
	dpSetWait(name+".panel",parameters[fwCaV_SynopticsBitmap_Type],
		name+".Data.deviceDp",parameters[fwCaV_WidgetInstance_DeviceDp],
		name+".Data.properties",parameters[fwCaV_WidgetInstance_Properties],
		name+".Data.extraParameters",parameters[fwCaV_WidgetInstance_ExtraParameters],
		name+".visible",parameters[fwCaV_WidgetInstance_Visible],
		name+".Position.x",parameters[fwCaV_WidgetInstance_Position_x],
		name+".Position.y",parameters[fwCaV_WidgetInstance_Position_y]);
}

/** Function used for registering a new plot
@par Constraints
@par Usage
	Public
@par PVSS managers
	VISION, CTRL
@param name			name of plot to register
@param exceptionInfo		returns details of any errors
*/

fwCaV_registerPlot(string name, dyn_string &exceptionInfo)
{
	if(!dpIsLegalName(name))
	{
		fwException_raise(exceptionInfo, "ERROR", "Invalid name:" +name+".","");
		return;
	}
	if(dpExists(name))
	{
		fwException_raise(exceptionInfo, "ERROR", "Plot with name:" +name+" already exists.","");
		return;
	}	
	dpCreate(name, fwCaV_PlotDPT);
}

/** Function used for deleting a plot
@par Constraints
@par Usage
	Public
@par PVSS managers
	VISION, CTRL
@param plotName		name of plot
@param exceptionInfo		returns details of any errors
*/

fwCaV_deletePlot(string plotName, dyn_string &exceptionInfo)
{
	if(!dpExists(plotName))
	{
		fwException_raise(exceptionInfo, "ERROR", "Plot instance:" +plotName+" does not exist.","");
		return;
	}	
	dpDelete(plotName);
}


/** Returns the list of all plots.
@par Constraints
@par Usage
	Public
@par PVSS managers
	VISION, CTRL
@param list				list of Plots
@param stripSystemName			whether to strip the system name from the DPs (default = true)
*/

fwCaV_listPlots(dyn_string &list, bool stripSystemName=true)
{
	list = dpNames("*", fwCaV_PlotDPT);
	if(stripSystemName)
	{
		for(int i=1; i<=dynlen(list); i++)
			list[i] = dpSubStr(list[i], DPSUB_DP);
	}
}


/** Function returns a structure with information about the given Plot Instance 
@par Constraints
@par Usage
	Public
@par PVSS managers
	VISION, CTRL
@param plotName			name of plot instance
@param curves			structure with data of the curves about the given Plot Instance
@param visible			whether the Plot is displayed
@param exceptionInfo		returns details of any errors
*/

fwCaV_getPlotInstanceDetails(string plotName, dyn_string &curves, bool &visible, dyn_string &exceptionInfo)
{
	if(!dpExists(plotName))
	{
		fwException_raise(exceptionInfo, "ERROR", "Widget instance with name:" +name+" does not exist.","");
		return;
	}
	// And check if it is really of the proper type
	if(dpTypeName(plotName)!=fwCaV_PlotDPT)
	{
		fwException_raise(exceptionInfo, "ERROR", name+" is not of plot instance type. Aborting.","");
		return;
	}
	dpGet(plotName+".curve1",curves[1],
			plotName+".curve2",curves[2],
			plotName+".curve3",curves[3],
			plotName+".curve4",curves[4],
			plotName+".curve5",curves[5],
			plotName+".curve6",curves[6],
			plotName+".curve7",curves[7],
			plotName+".curve8",curves[8],
			plotName+".visible",visible);
}



/** Function sets information about the given Plot Instance according to the data in structure
@par Constraints
@par Usage
	Public
@par PVSS managers
	VISION, CTRL
@param plotName			name of plot instance
@param curves			structure with data of the curves about the given Plot Instance
@param visible			whether the Plot is displayed
@param exceptionInfo		returns details of any errors
*/

fwCaV_setPlotInstanceDetails(string plotName, dyn_string curves, bool visible, dyn_string &exceptionInfo)
{
	if(!dpExists(plotName))
	{
		fwException_raise(exceptionInfo, "ERROR", "Plot instance with name:" +name+" does not exist.","");
		return;
	}
	// And check if it is really of the proper type
	if(dpTypeName(plotName)!=fwCaV_PlotDPT)
	{
		fwException_raise(exceptionInfo, "ERROR", name+" is not of plot instance type. Aborting.","");
		return;
	}
	dpSetWait(plotName+".curve1",curves[1],
			plotName+".curve2",curves[2],
			plotName+".curve3",curves[3],
			plotName+".curve4",curves[4],
			plotName+".curve5",curves[5],
			plotName+".curve6",curves[6],
			plotName+".curve7",curves[7],
			plotName+".curve8",curves[8],
			plotName+".visible",visible);
}





/** Function displaying the "right-click" menu for the synoptics bitmap
    with various plotting opitons.
@par Constraints
@par Usage
	Public
@par PVSS managers
	VISION, CTRL
@param dpe - dpe element upon which the plot operations will be done
*/

_fwCaV_plotMenu(string dpe)
{
	dyn_string menu;
	int answer;
	string parName = fwCaV_genericDpeVarName(dpe);
	menu=makeDynString("PUSH_BUTTON, "+parName+", 0, 0",
		"SEPARATOR",
		"CASCADE_BUTTON, Add to plot, 1",
		"CASCADE_BUTTON, Remove from plot, 1",
		"SEPARATOR",
/*		"PUSH_BUTTON, Remove from all plots, 1, 1",
		"SEPARATOR",
*/		"CASCADE_BUTTON, Clear plot, 1",
		"SEPARATOR",
		"CASCADE_BUTTON, Show plot, 1");
	
	dyn_dyn_string subMenus;
	dynAppend(subMenus[1], "Add to plot");
	dynAppend(subMenus[2], "Remove from plot");
	dynAppend(subMenus[3], "Clear plot");
	dynAppend(subMenus[4], "Show plot");
	
	for(int i=1; i<=fwCaV_MAX_PLOTS; i++)
	{
		bool enabled = 1;
		bool present = 0;
		if(!dpExists(fwCaV_PLOTPREFIX+i))
			enabled = 0;
		else if (__fwCaV_obtainCurveNumber(fwCaV_PLOTPREFIX+i, dpe)>0)
			present = 1;
		__fwCaV_plotMenuEntry(subMenus[1], fwCaV_PLOTPREFIX+i, 100+i, enabled&&(!present));
		__fwCaV_plotMenuEntry(subMenus[2], fwCaV_PLOTPREFIX+i, 200+i, enabled&&(present));
		__fwCaV_plotMenuEntry(subMenus[3], fwCaV_PLOTPREFIX+i, 300+i, enabled);
		__fwCaV_plotMenuEntry(subMenus[4], fwCaV_PLOTPREFIX+i, 400+i, enabled);
	}
	
	for(int i=1; i<=4; i++)
		dynAppend(menu, subMenus[i]);
	popupMenu(menu, answer);
	
	/* Add to plot */
	if(answer/100==1)
	{
		dyn_string curveData, exceptionInfo;
		int position;
		string plot = fwCaV_PLOTPREFIX+answer%100;
		curveData[fwTrending_CURVE_OBJECT_DPE] = dpe;
		fwTrending_getFirstFreeCurve(plot, position, exceptionInfo);
		if(position>0)
		{
			//fwTrending_insertCurveAt(plot, curveData, position, exceptionInfo) ;
			fwTrending_setCurve(plot, curveData, position, exceptionInfo);
			if(dynlen(exceptionInfo)!=0)
			{
				fwExceptionHandling_display(exceptionInfo);
				return;
			}
		}
		else
		{
			fwException_raise(exceptionInfo, "ERROR", "No free slots in the plot.", "");
			fwExceptionHandling_display(exceptionInfo);
			return;
		}
	}
	else if(answer/100==2)
	/* Remove from plot */
	{
		dyn_string exceptionInfo;
		string plot = fwCaV_PLOTPREFIX+answer%100;
		int curveToRemove = __fwCaV_obtainCurveNumber(plot, dpe);
		if(curveToRemove>0)
		{
			fwTrending_removeCurve(plot, curveToRemove, exceptionInfo);
			if(dynlen(exceptionInfo)!=0)
			{
				fwExceptionHandling_display(exceptionInfo);
				return;
			}
		}
	}
	else if(answer/100==3)
	/* Clear plot */
	{
		string plot = fwCaV_PLOTPREFIX+answer%100;
		dyn_string exceptionInfo;
		dyn_int curves;
		for(int i=1; i<=fwTrending_MAX_NUM_CURVES; i++)
			dynAppend(curves,i);
		fwTrending_deleteManyCurves(plot, curves, exceptionInfo);
		if(dynlen(exceptionInfo)!=0)
		{
			fwExceptionHandling_display(exceptionInfo);
			return;
		}
	}
	else if(answer/100==4)
	/* Show plot */
	{
		string plotName, openPlotName = "";
		bool isConnected;
		dyn_string panelsList, exceptionInfo;
		dyn_dyn_string plotData;
		
		plotName = fwCaV_PLOTPREFIX+answer%100;
		
		_fwTrending_isSystemForDpeConnected(plotName, isConnected, exceptionInfo);
		
		if(dpExists(plotName) && isConnected)
		{
			fwTrending_getPlot(plotName, plotData, exceptionInfo);
			openPlotName = plotData[fwTrending_PLOT_OBJECT_TITLE][1];
		}
		else
			openPlotName = plotName;
		
		fwDevice_getDefaultOperationPanels(fwTrending_PLOT, panelsList, exceptionInfo);
		
		ChildPanelOn(panelsList[1] + ".pnl", "Trending Plot: " + openPlotName,
			makeDynString("$PlotName:" + plotName, "$templateParameters:"),0,0);
	}
}


/** Function checks if the given dpe is present as a curve in a certain plot
@par Constraints
@par Usage
	Private
@par PVSS managers
	VISION, CTRL
@param plotDp - plot datapoint to be examined
@param dpe - dpe to look for
@return the curve number or -1 if not found
*/

int __fwCaV_obtainCurveNumber(string plotDp, string dpe)
{
	dyn_string curveData;
	dyn_string exceptionInfo;
	bool isCurveDefined;
	for(int i=1; i<=fwTrending_MAX_NUM_CURVES; i++)
	{
		fwTrending_getCurve(plotDp, isCurveDefined, curveData, i, exceptionInfo);
		if(isCurveDefined && dynlen(exceptionInfo)==0)
			if(curveData[fwTrending_CURVE_OBJECT_DPE]==dpe)
				return i;
	}
	return -1;
}

/** Helper function for constructing the plot menu
@par Constraints
@par Usage
	Private
@par PVSS managers
	VISION, CTRL
@param menu - dyn_string containing the menu parameters to which new data shall be appended
@param label - the label of the new entry
@param value - return value of the label (returned when the label is clicked)
@param enabled - whether the entry is enabled (true by default)
*/

__fwCaV_plotMenuEntry(dyn_string &menu, string label, int value, bool enabled=true)
{
	string entry = "PUSH_BUTTON, " + label + ", " + value + ", " + (int)enabled;
	dynAppend(menu, entry);
}




/** Function for querying the timeout status of the PLC
@par Constraints
@par Usage
	Public
@par PVSS managers
	VISION, CTRL
@param dp - CaV plant/area/group datapoint
@param status - return code: 1 - timeout active; 0 - timeout inactive; -1 error
@param exceptionInfo - error handling
*/

fwCaV_isTimeoutActive(string dp, int &status, dyn_string &exceptionInfo)
{
	int pos;
	int value;
	if(!dpExists(dp) || strpos(dp,"CaV")<0)
	{
		fwException_raise(exceptionInfo, "ERROR", "Wrong datapoint: "+dp,"");
		return;
	}

	// Trim if we got loop or area dp
	pos = strpos(dp,"Loop");
	if(pos>0)
		dp = substr(dp, 0, pos-1);
	int pos = strpos(dp,"Area");
	if(pos>0)
		dp = substr(dp, 0, pos-1);
	
	int value;
	int code = dpGet(dp+".Actual.timeout", value);
	if(code==-1)
	{
		status = -1;
		fwException_raise(exceptionInfo, "ERROR", "Problem reading "+dp+".Actual.timeout","");
	}
	else if (value>0)
	{
		status = 1;
	}
	else
	{
		status = 0;
	}
}

/** Function for checking if the MODBUS driver is running
@par Constraints
@par Usage
	Public
@par PVSS managers
	VISION, CTRL
@param dui - dyn string with the number of the managers which are running
@param driverNum - number of the manager for the ModBus driver
*/
bool isDriverRunning(dyn_int dui, int driverNum)
{
  string status;
  
  if (dpExists("_Driver"+driverNum))
  {
    dpGet("_Driver"+driverNum+".DT",status);

    if ((dynContains(dui, driverNum) >= 1) && (status == "MODBUS"))
      return true;
    else return false;
  }
  else return false; 
}

/*  Function for creating DPE functions for CaV/TilePlant.Connection elements
    @par Constraints
    @par Usage
	Private
    @par PVSS managers
	VISION, CTRL    
    @param plantName - ex. string "CaV/TilePlant"  
   - Erik Morset
*/
int fwCaV_ConnectionState(string plantName)
{ 
      int err = 0;
      // path to the embed DP-type
      string dpPath = plantName + ".Connection";
    
      // set modbus driver number
      int modbusDrv;  
      modbusDrv = "15";  // default modbus driver
      dpSet(dpPath+".driverNumber:_original.._value", modbusDrv);  
  
      // create a DPE function that give the status of the modbus driver
      string p1 = "_Connections.Driver.ManNums:_online.._value"; // list with the drivers that are running
      string p2 = dpPath+".driverNumber:_online.._value"; // DPe for the driver number
      string p3 = "_Driver"+modbusDrv+".DT:_online.._value"; 
      dyn_string pm = makeDynString(p1, p2, p3);
      dpSetWait(dpPath+".driverStatus:_dp_fct.._type", 60, 
                dpPath+".driverStatus:_dp_fct.._param", pm,
                dpPath+".driverStatus:_dp_fct.._fct", "(dynContains(p1, p2) >= 1) && (p3==\"MODBUS\")");

      // create a DPE function that set the status of the plc connection    
      // first we have to get the name of the PLC this system is using
      string plcName;
      string filePath = getPath(CONFIG_REL_PATH);
      paCfgReadValue(filePath+"config", "mod_"+modbusDrv, "plc", plcName); 
      // then if there is a DP with this name we can create the DPE function
      if(dpExists(plcName))
      {
          p1 = plcName+".ConnState:_online.._value";
          dyn_string pm = makeDynString(p1);
          dpSetWait(dpPath+".plcConnection:_dp_fct.._type", 60, 
                    dpPath+".plcConnection:_dp_fct.._param", pm,
                    dpPath+".plcConnection:_dp_fct.._fct", "p1==1");
      } else {
          DebugN("PLC does not exist",plcName); 
          err = 1; // PLC does not exist
      }
  
      // create a DPE function that checks if the data is valid
      p1 = plantName+".Actual.status:_online.._invalid";
      dyn_string pm = makeDynString(p1);
      dpSetWait(dpPath+".dataValid:_dp_fct.._type", 60, 
                dpPath+".dataValid:_dp_fct.._param", pm,
                dpPath+".dataValid:_dp_fct.._fct", "!p1");
        
      if(err!=0)
        return err;
      else
        return 0;

}

/*
  Returns true if Access Control is enabled in the CaV component. 
    @par Constraints
    @par Usage
	Private
    @par PVSS managers
	VISION, CTRL    
    @param dpName - ex. "CaV/PlantName"
   - Erik Morset
*/  
bool fwCaV_ACEnabled(string dpName)
{
        string privileges;
        dpGet(dpName + ".privileges", privileges);
        privileges = substr(privileges, 0 , 1);
        if(privileges=="-")
          return true;
        else
          return false;      
}


//  This function is copied from the FSM library 
fwCaV_addUserLogin(int x, int y)
{
	if(isFunctionDefined("fwAccessControl_selectPrivileges"))
	{
		addSymbol(myModuleName(), myPanelName(), 
			  "objects/fwAccessControl/fwAccessControl_CurrentUser.pnl", "user", 
			  makeDynString(), x, y, 0, 1, 1);
	}
}


/*
    Function to get the number of alarm words and warning words from a plant
 */
void fwCaV_countWarningAndAlarmWords(string dpName, int &alarmWords, int &warningWords)
{
	dyn_dyn_string elements;
	dyn_string exceptionInfo;
	string deviceModel;

	// get all elements
	fwDevice_getModel(makeDynString(dpName), deviceModel, exceptionInfo); 
	fwDevice_getConfigElements(dpTypeName(dpName),
				   fwDevice_ALL,
				   elements,
				   exceptionInfo,
				   deviceModel,
				   dpName);
			   
				   
	// How many alarm/warning words found
	for(int i=1; i<=dynlen(elements[fwDevice_ELEMENTS_INDEX]); i++)
	{
		if(strpos(elements[fwDevice_ELEMENTS_INDEX][i],".Alarms.alarmWord")>=0)
			alarmWords++;
                else if(strpos(elements[fwDevice_ELEMENTS_INDEX][i],".Warnings.warningWord")>=0)
			warningWords++;
	}    
}
 
