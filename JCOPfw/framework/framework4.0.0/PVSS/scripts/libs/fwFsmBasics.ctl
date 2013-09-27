const int FwFreeBit = 0;
const int FwOwnerBit = 1;
const int FwExclusiveBit = 2;
const int FwIncompleteBit = 3;
const int FwIncompleteDevBit = 4;
const int FwUseStatesBit = 5;
const int FwSendCommandsBit = 6;
const int FwCUNotOwnerBit = 7;
const int FwCUFreeBit = 8;

int fwUi_checkOwnershipMode(string owner, string id = "")
{
	string itsid;
	int enabled;

	if(id == "")
		itsid = fwUi_getUiId();
	else
		itsid = id;
	if(owner == "")
		enabled = 1;
	else if(owner == itsid)
		enabled = 2;
	else enabled = 0;
	return enabled;
}

string fwUi_getUiId()
{
	string id;

	if(isFunctionDefined("myModuleName"))
		id = getSystemName()+"Manager"+myManNum();
	else
		id = getSystemName()+"CtrlManager"+myManNum();
	return id;
}
