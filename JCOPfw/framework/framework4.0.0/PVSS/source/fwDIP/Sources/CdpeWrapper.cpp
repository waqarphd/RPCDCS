#include "PVSSDIPAPIOptions.h"
#include "CdpeWrapper.h"
#include "dipManager.h"




CdpeWrapper::CdpeWrapper(const CharString & dpeName)
:CsimpleDPEWrapper(dpeName),mapping(NULL){
	//revalidateDPE();
}



bool CdpeWrapper::revalidateDPE(){
	CharString ub1Name = getName() + ":_"+getDPESourceName()+".._userbit1";
	CharString ub2Name = getName() + ":_"+getDPESourceName()+".._userbit2";


	if ((CsimpleDPEWrapper::revalidateDPE() == true) && 
		(retriveDIPAddress(nameOfDIPPublication) == true) &&
		(Manager::getId(ub1Name, dpId_usrBit1) == PVSS_TRUE) &&
		(Manager::getId(ub2Name, dpId_usrBit2) == PVSS_TRUE)){
			valid = true;
	}else{
		valid = false; //CsimpleDPEWrapper::revalidateDPE() may have set valid to true true
	}

	return valid;
}	



bool CdpeWrapper::retriveDIPAddress(CharString & dipAddress) const{
	dipAddress = "";
	// first make sure address config exists.
	{
		CharString addConfigExistDPE[1] = {getName()+":_address.._type"};
		DpIdentList dpList;
		if (makeListOfDPEs(dpList, addConfigExistDPE, 1) != 1){
			return false;
		}
		PVSSINFO("");
		CdpGetCallBackHandler handler; // handler will be destroyed at end of this code block
		
		getValuesOfDPEs(handler, dpList);

		// look at the responses
		const DpIdValueList & answerList = handler.getListOfResponses();
		const DpVCItem* responsePair = answerList.getFirstItem();
		IntegerVar * addConfigType = (IntegerVar *)responsePair->getValuePtr();
		if (addConfigType->getValue() == 0){
			// address config does not exist!
			PVSSERROR("Address config does not exist for " << (const char *)getName());
			return false;
		}
	}


	// Address config exists - read it
	const int numProperties = 2; 
	CharString addConfigNames[numProperties] = {getName()+":_address.._drv_ident",
												getName()+":_address.._reference"};
	DpIdentList dpList;
	if (makeListOfDPEs(dpList, addConfigNames, numProperties) != numProperties){
		PVSSERROR("Failed to build dpList to get address info for " << (const char *)getName());
		return false;
	}
	
	// now get the values of the elements stored in the list
	// values are held in the handler
	CdpGetCallBackHandler handler;
	getValuesOfDPEs(handler, dpList);

	// look at the responses
	const DpIdValueList & answerList = handler.getListOfResponses();
	const DpVCItem* responsePair = answerList.getFirstItem();
	bool found = false;
	while(responsePair != NULL){
		CharString dpName;
		Manager::getLIName (responsePair->getDpIdentifier(), dpName);
		//cout << "Looking at response " << dpName << endl;

		if (dpName.indexOf(addConfigNames[0],0) != -1){
			// got response to _drv_ident
			const TextVar * value = (TextVar *)responsePair->getValuePtr();
			if ((value == NULL) || (strcmp(value->getValue(),"DIP") != 0)){
				CharString driverName = (value == NULL) ? "missing" : value->getString();
				PVSSERROR("DPE " << (const char *)getName() << " has bad driver id " << (const char *)driverName);
				return false;
			}
		}
		else if (dpName.indexOf(addConfigNames[1],0) != -1){
			// got response to _reference
			const TextVar * value = (TextVar *)responsePair->getValuePtr();
			if (value == NULL){
				found = false;
				PVSSERROR("DPE " << (const char *)getName() <<" has empty reference"); 
			} else {
				found = true;
				dipAddress = value->getString();
			}
		}

		responsePair = answerList.getNextItem();
	}

	return found;
}










