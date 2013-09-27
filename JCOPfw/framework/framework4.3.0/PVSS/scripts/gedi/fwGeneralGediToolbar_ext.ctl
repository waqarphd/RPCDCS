#uses "fwGeneral/fwGeneral.ctl"

main()
{
	bool isInstalled = FALSE;
	int idTop, idAccessControl, idTemp, idAlarmHandling;
	string version;
   
	idTop = moduleAddMenu("JCOP Framework");
	
	// Access Control
	isInstalled = fwInstallation_isComponentInstalled("fwAccessControl", version);
	if(isInstalled)
	{
		idAccessControl = moduleAddSubMenu("Access Control", idTop); 
		moduleAddAction("Login", "login.xpm", "", idAccessControl, -1, "fwAccessControl_login");
		moduleAddAction("Logout", "exit.xpm", "", idAccessControl, -1, "fwAccessControl_logout");
		moduleAddAction("AC Toolbar", "userviewer", "", idAccessControl, -1, "_openAccessControlToolbar");
		moduleAddAction("AC Setup", "sysmgm", "", idAccessControl, -1, "_openAccessControlSetup");
	}
	
	// Alarm Handling
	isInstalled = fwInstallation_isComponentInstalled("fwAlarmHandling", version);
	if(isInstalled)
	{
		idAlarmHandling = moduleAddSubMenu("Alarm Handling", idTop); 
		moduleAddAction("Alarm Screen", "SysMgm/16x16/AesScreenAlerts.png", "", idAlarmHandling, -1, "_openAs");
		moduleAddAction("Alarm Screen with Groups", "SysMgm/16x16/ArchivingAlerts.png", "", idAlarmHandling, -1, "_openAsG");
	}
	
	// Device Editor and Navigator 
	isInstalled = fwInstallation_isComponentInstalled("fwDeviceEditorNavigator", version);
	if(isInstalled)
		moduleAddAction("Device Editor and Navigator", "", "", idTop, -1, "_openDEN"); 
	
	// DIM
	isInstalled = fwInstallation_isComponentInstalled("fwDIM", version);
	if(isInstalled)
		moduleAddAction("DIM", "", "", idTop, -1, "_openDIM");
		
	// DIP
	isInstalled = fwInstallation_isComponentInstalled("fwDIP", version);
	if(isInstalled)
		moduleAddAction("DIP", "", "", idTop, -1, "_openDIP");
	
	// Installation
   moduleAddAction("Installation", "", "", idTop, -1, "_openInstallationTool"); 
	
	// Trending
	isInstalled = fwInstallation_isComponentInstalled("fwTrending", version);
	if(isInstalled)
		moduleAddAction("Trending", "trend.png", "", idTop, -1, "_openTrendingTool"); 
}

void _openAccessControlToolbar()
{
	_fwGediToolbar_openTool("fwAccessControl", 
									"JCOP Framework Access Control Toolbar", 
									"fwAccessControl/fwAccessControl_Toolbar.pnl", 
									"JCOP AC Toolbar");							
}

void _openAccessControlSetup()
{
	_fwGediToolbar_openTool("fwAccessControl", 
									"JCOP Framework Access Control Setup", 
									"fwAccessControl/fwAccessControl_Setup.pnl", 
									"JCOP AC Setup");		 
}

void _openInstallationTool()
{
	_fwGediToolbar_openTool("", 
									"JCOP Framework Installation tool", 
									"fwInstallation/fwInstallation.pnl", 
									"JCOP Installation");	
}

void _openDEN()
{ 
	_fwGediToolbar_openTool("fwDeviceEditorNavigator", 
									"JCOP Framework Device Editor Navigator", 
									"fwDeviceEditorNavigator/fwDeviceEditorNavigator.pnl", 
									"JCOP DEN"); 
} 

void _openDIM()
{ 
	_fwGediToolbar_openTool("fwDIM", 
									"JCOP Framework DIM", 
									"fwDIM/fwDim.pnl", 
									"JCOP DIM"); 
} 

void _openDIP()
{ 
	_fwGediToolbar_openTool("fwDIP", 
									"JCOP Framework DIP", 
									"fwDIP/fwDip.pnl", 
									"JCOP DIP"); 
} 

void _openTrendingTool() 
{ 
	_fwGediToolbar_openTool("fwTrending", 
									"JCOP Framework Trending Tool", 
									"fwTrending/fwTrending.pnl", 
									"JCOP Trending"); 
}

void _openAs() 
{ 
	_fwGediToolbar_openTool("fwAlarmHandling", 
									"fwAS", 
									"fwAlarmHandling/fwAlarmHandlingScreen.pnl", 
									""); 
}

void _openAsG() 
{ 
	_fwGediToolbar_openTool("fwAlarmHandling", 
									"fwASg", 
									"fwAlarmHandling/fwAlarmHandlingGroupsScreen.pnl", 
									""); 
}

void _fwGediToolbar_openTool(	string componentName, string moduleName, 
										string fileName, string panelName)
{
	bool ok, isInstalled = FALSE;
	string version;
	dyn_string exceptionInfo;
	
	if (componentName == "")
	{
		// If what we are opening is not related to a component, then we assume the panel to open is available
		isInstalled = TRUE;
	}
	else
	{ 
		// we check again whether the component is installed because it could be that the component was uninstalled
		// after the menu was added
		isInstalled = fwInstallation_isComponentInstalled(componentName, version);
	}
	
	if (isInstalled)
	{
		ModuleOnWithPanel(moduleName, 
								-1, -1, 100, 200, 1, 1, 
								"",	 
								fileName, 
								panelName, 								
								makeDynString()); 
	}
	else
	{	
		fwGeneral_openMessagePanel("The component " + componentName + " is not installed",
											ok, exceptionInfo,  "Error opening panel", TRUE);
	}
}
