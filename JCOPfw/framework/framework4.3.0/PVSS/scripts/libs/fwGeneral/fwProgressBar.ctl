// Global Variables
// ----------------
string g_sProgressDpName = "fwProgressBar";

void fwOpenProgressBar(string sTitle, string sInitialMessage, int iType, int iTimeout = 0)
{
// Local Variables
// ---------------
	string sSystemName = getSystemName();
	
// Executable Code
// ---------------
	// Initialise parameters
	switch (iType) {
		case 3:
			dpSet(sSystemName + g_sProgressDpName + ".type", 3,
						sSystemName + g_sProgressDpName + ".timeout", iTimeout,
						sSystemName + g_sProgressDpName + ".run", true);
			break;
		case 2:
			dpSet(sSystemName + g_sProgressDpName + ".message", sInitialMessage,
						sSystemName + g_sProgressDpName + ".type", 2,
						sSystemName + g_sProgressDpName + ".value", 0.0);
			break;
		default:
			dpSet(sSystemName + g_sProgressDpName + ".message", sInitialMessage,
						sSystemName + g_sProgressDpName + ".type", 1,
						sSystemName + g_sProgressDpName + ".run", true);
			break;
	}
	
	// Display the progress bar panel
	ChildPanelOnModal("fwGeneral/fwProgressBar.pnl", sTitle, makeDynString("$sDpName:" + sSystemName + g_sProgressDpName), 0, 0);

	// Return to calling routine
	return;
}

void fwShowProgressBar(string sMessage = "",
											 float fPercentage = 0.0)
{
// Local Variables
// ---------------
	string sSystemName = getSystemName();

// Executable Code
// ---------------
	// Check value is within limits
	if (fPercentage < 0.0)
		fPercentage = 0.0;
	else if (fPercentage > 100.0)
		fPercentage = 100.0;
		
	// Set value into DPE
	dpSet(sSystemName + g_sProgressDpName + ".value", fPercentage);
	
	// Display any message (if given)
	if (strlen(sMessage) > 0)
		dpSet(sSystemName + g_sProgressDpName + ".message", sMessage);

	// Return to calling routine
	return;
}

void fwCloseProgressBar(string sMessage = "")
{
// Local Variables
// ---------------
	bool bIsOpen;
	
	int iType;
	
	string sSystemName = getSystemName();
	
	time tTimeout = 0;
	
	dyn_string dsNamesWait = makeDynString(sSystemName + g_sProgressDpName + ".panelOpen:_online.._value");
	dyn_string dsNamesReturn = makeDynString(sSystemName + g_sProgressDpName + ".panelOpen:_online.._value");
	
	dyn_anytype daBoolReturn;
	dyn_anytype daBoolWait = makeDynAnytype(false);

// Executable Code
// ---------------
	dpGet(sSystemName + g_sProgressDpName + ".type", iType);
	
	// Check which type of progress bar is currently displayed
	switch (iType) {
		case 2:
			dpSet(sSystemName + g_sProgressDpName + ".value", 100.0);
			break;
		default:
			// Set flag to indicate process is complete
			dpSet(sSystemName + g_sProgressDpName + ".run", false);
			break;
	}
	
	// Display any message (if given)
	if (strlen(sMessage) > 0)
		dpSet(sSystemName + g_sProgressDpName + ".message", sMessage);
		
	// Check if panel is open
	dpGet(sSystemName + g_sProgressDpName + ".panelOpen", bIsOpen);
	
	// If still open, wait for it to close before returning
	if (bIsOpen) {
		// Wait for flag to go false with infinite timeout
		dpWaitForValue(	dsNamesWait, daBoolWait,
										dsNamesReturn, daBoolReturn,
										tTimeout);
	}

	// Return to calling routine
	return;
}
