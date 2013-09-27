// simpleDPEWrapper.cpp: implementation of the CsimpleDPEWrapper class.
//
//////////////////////////////////////////////////////////////////////
#include "PVSSDIPAPIOptions.h"
#include "dipManager.h"
#include "simpleDPEWrapper.h"


CsimpleDPEWrapper::CsimpleDPEWrapper(const CharString & dpeName)
:name(dpeName), marked(false), valid(false){
	PVSSINFO("Created DPEWrapper for DPE " << (const char *)getName());
}



CsimpleDPEWrapper::~CsimpleDPEWrapper()
{
	PVSSINFO("Destroyed DPEWrapper for DPE " << (const char *)getName());
}



bool CsimpleDPEWrapper::revalidateDPE(){
	valid = false;

	CharString valueName = name + ":_"+getDPESourceName()+".._value";
	CharString invalidBitName = getName() + ":_"+getDPESourceName()+".._"+getValidAttribName();
	CharString timestampName = name + ":_"+getDPESourceName()+".._stime";

	
	if ((Manager::getId(valueName, dpId_value) == PVSS_TRUE) &&
		(Manager::getId(timestampName, dpId_timestamp) == PVSS_TRUE) &&
		(Manager::getId(invalidBitName, dpId_invalid) == PVSS_TRUE) &&
		(retrieveDPEsValueType(valueType) == true)){
			valid = true;
	} else {
		if (Manager::getId(valueName, dpId_value) == PVSS_FALSE) {
			PVSSERROR("Wrong mapping for : "<<valueName);
		} else if (Manager::getId(timestampName, dpId_timestamp) == PVSS_FALSE) {
			PVSSERROR("Wrong mapping for : "<<invalidBitName);
		} else if (Manager::getId(invalidBitName, dpId_invalid) == PVSS_TRUE) {
			PVSSERROR("Wrong mapping for : "<<timestampName);
		}
	}

	return valid;
}	




bool CsimpleDPEWrapper::retrieveDPEsValueType(DpElementType &dpeType) const{
	Manager::getElementType(dpId_value, dpeType);
	// TODO check type is no our conversion list
	return true;
}

void CsimpleDPEWrapper::getValuesOfDPEs(CdpGetCallBackHandler & handler, const DpIdentList &list){
	Manager::dpGet(list, &handler, false);

	// Wait for the required number of responses
	// TODO - must put a time of on this!!!!!
	while ((unsigned)handler.getNumOfResponses() != (unsigned)list.getNumberOfItems()){
		//long sec = 0, usec = 200;
		long sec = 0, usec = 500000;
		Manager::dispatch(sec, usec);
	}
}

int CsimpleDPEWrapper::makeListOfDPEs(DpIdentList &dpList, const CharString *dpNames, const int noNames){
	DpIdentifier id;

	for (int i = 0; i < noNames; i++){
		if ((Manager::getId(dpNames[i], id) == PVSS_FALSE))
		{
			PVSSERROR("Failed to get dpID for " << (const char *)dpNames[i]);
			return false;
		}
		else
		{
				//cerr << "Got dpID for " << dpNames[i] << endl;
				dpList.append(id);
		}
	}

	return dpList.getNumberOfItems();
}



