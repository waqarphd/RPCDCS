// pubDpeWrapper.cpp: implementation of the CpubDpeWrapper class.
//
//////////////////////////////////////////////////////////////////////
#include "PVSSDIPAPIOptions.h"
#include "pubDpeWrapper.h"

//////////////////////////////////////////////////////////////////////
// Construction/Destruction
//////////////////////////////////////////////////////////////////////

CpubDpeWrapper::CpubDpeWrapper(const CharString & dpeName):CsimpleDPEWrapper(dpeName)
,invalid(false)
{

}



CpubDpeWrapper::~CpubDpeWrapper()
{

}



bool CpubDpeWrapper::revalidateDPE(){
	CharString timeStampName = getName() + ":_"+getDPESourceName()+".._stime";


	if ((CsimpleDPEWrapper::revalidateDPE() == true) && 
		(Manager::getId(timeStampName, dpId_timeStamp) == PVSS_TRUE)){
			valid = true;
	}else{
		valid = false; //CsimpleDPEWrapper::revalidateDPE() may have set valid to true true
	}

	return valid;
}




void CpubDpeWrapper::storeInvalidAttribute(const Variable * val){
	BitVar * boolVal = (BitVar *) val;
	invalid = static_cast<bool>(boolVal->isTrue());
}

bool CpubDpeWrapper::isInvalidAttributeSet(){
		return invalid;
	}
