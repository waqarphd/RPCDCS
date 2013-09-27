#uses "fwFsmBasics.ctl"

bit32 fwFsmEvent_computeCUModeBits(bool exclusive, string owner, 
	string mode, string comp)
{
	bit32 statusBits;
	int enabled, is_free, is_owner, incomplete;

//DebugTN("Computing CU mode bits", exclusive, owner, mode, comp);
	enabled = fwUi_checkOwnershipMode(owner);
	is_free = (enabled == 1);
	is_owner = (enabled == 2);

	setBit(statusBits,FwFreeBit,is_free);
	setBit(statusBits,FwOwnerBit,is_owner);
	setBit(statusBits,FwExclusiveBit,exclusive);
//	incomplete = 0;
	if(comp == "COMPLETE")
	{
		setBit(statusBits,FwIncompleteBit,0);
		setBit(statusBits,FwIncompleteDevBit,0);
		setBit(statusBits,FwIncompleteDeadBit,0);
	}
 else if(comp == "INCOMPLETE")
	{
		setBit(statusBits,FwIncompleteBit,1);
		setBit(statusBits,FwIncompleteDevBit,0);
		setBit(statusBits,FwIncompleteDeadBit,0);
	}
  else if (comp == "INCOMPLETEDEV")
	{
		setBit(statusBits,FwIncompleteBit,0);
		setBit(statusBits,FwIncompleteDevBit,1);
		setBit(statusBits,FwIncompleteDeadBit,0);
	}
  else if (comp == "INCOMPLETEDEAD")
	{
		setBit(statusBits,FwIncompleteBit,0);
		setBit(statusBits,FwIncompleteDevBit,0);
		setBit(statusBits,FwIncompleteDeadBit,1);
	}
	if(mode == "EXCLUDED")
	{
		setBit(statusBits,FwUseStatesBit,0);
		setBit(statusBits,FwSendCommandsBit,0);
	}
	else if( (mode == "INCLUDED") || (mode == "INLOCAL") )
	{
		setBit(statusBits,FwUseStatesBit,1);
		setBit(statusBits,FwSendCommandsBit,1);
	}
	else if((mode == "MANUAL") || (mode == "INMANUAL"))
	{
		setBit(statusBits,FwUseStatesBit,1);
		setBit(statusBits,FwSendCommandsBit,0);
	}
	else if(mode == "IGNORED")
	{
		setBit(statusBits,FwUseStatesBit,0);
		setBit(statusBits,FwSendCommandsBit,1);
	}
	else if(mode == "DEAD")
	{
		setBit(statusBits,FwUseStatesBit,0);
		setBit(statusBits,FwSendCommandsBit,0);
		setBit(statusBits,FwFreeBit,1);
		setBit(statusBits,FwOwnerBit,0);
	}
	return statusBits; 
}

bit32 fwFsmEvent_computeDUModeBits(bool exclusive, string owner, int mode,
	bit32 luMode = 0)
{
	bit32 statusBits;
	int enabled, is_free, is_owner, complete;
	bool lumode, lumodelocal, lumodeparent;

//DebugTN("Computing DU mode bits", exclusive, owner, mode, lumode);
	lumode = 1;
	if(luMode != 0)
	{
		lumodelocal = getBit(luMode, FwUseStatesBit);
		lumodeparent = !getBit(luMode, FwCUNotOwnerBit);
		lumode = lumodelocal & lumodeparent;
	}

	enabled = fwUi_checkOwnershipMode(owner);
	is_free = (enabled == 1);
	is_owner = (enabled == 2);

	if(!lumode)
		setBit(statusBits,FwCUNotOwnerBit,1);
	else
		setBit(statusBits,FwCUNotOwnerBit,0);

	setBit(statusBits,FwFreeBit,is_free);
	setBit(statusBits,FwOwnerBit,is_owner);
	setBit(statusBits,FwExclusiveBit,exclusive);
	if(mode == 1) //&& (lumode))
	{
		setBit(statusBits,FwUseStatesBit,1);
		setBit(statusBits,FwSendCommandsBit,1);
	}
	else
	{
		setBit(statusBits,FwUseStatesBit,0);
		setBit(statusBits,FwSendCommandsBit,0);
	}
	return statusBits;
}

bit32 fwFsmEvent_computeLobjModeBits(bool exclusive, string owner, int mode, string comp,
	bit32 luMode = 0)
{
	bit32 statusBits;
	int enabled, is_free, is_owner, complete;
	bool lumode, lumodelocal, lumodeparent;

//DebugTN("Computing LU mode bits", exclusive, owner, mode, comp, lumode);
	lumode = 1;
	if(luMode != 0)
	{
		lumodelocal = getBit(luMode, FwUseStatesBit);
		lumodeparent = !getBit(luMode, FwCUNotOwnerBit);
		lumode = lumodelocal & lumodeparent;
	}
	enabled = fwUi_checkOwnershipMode(owner);
	is_free = (enabled == 1);
	is_owner = (enabled == 2);

	if(!lumode)
		setBit(statusBits,FwCUNotOwnerBit,1);
	else
		setBit(statusBits,FwCUNotOwnerBit,0);

	setBit(statusBits,FwFreeBit,is_free);
	setBit(statusBits,FwOwnerBit,is_owner);
	setBit(statusBits,FwExclusiveBit,exclusive);
	if(mode == 1) //&& (lumode))
	{
		setBit(statusBits,FwUseStatesBit,1);
		setBit(statusBits,FwSendCommandsBit,1);
	}
	else
	{
		setBit(statusBits,FwUseStatesBit,0);
		setBit(statusBits,FwSendCommandsBit,0);
	}
	if(comp == "ENABLED")
		setBit(statusBits,FwIncompleteDevBit,0);
	else
		setBit(statusBits,FwIncompleteDevBit,1);
	return statusBits;
}
