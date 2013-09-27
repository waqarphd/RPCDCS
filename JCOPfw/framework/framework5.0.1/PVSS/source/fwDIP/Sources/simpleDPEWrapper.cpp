// simpleDPEWrapper.cpp: implementation of the CsimpleDPEWrapper class.
//
//////////////////////////////////////////////////////////////////////
#include "PVSSDIPAPIOptions.h"
#include "dipManager.h"
#include "simpleDPEWrapper.h"


CsimpleDPEWrapper::CsimpleDPEWrapper(const CharString & dpeName)
:name(dpeName), marked(false), valid(false), m_isDpeBeingArchived(false){
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
	CharString lockCorrValueName = name +  ":_lock._corr._locked";
	CharString lockOrigValueName = name +  ":_lock._original._locked";

	CharString corrValueName = name + ":_corr.._value";
	CharString corrTimestampName = name + ":_corr.._stime";
	CharString archiveTypeName = getName() + ":_archive.._type";
	CharString archiveArchiveName = getName() + ":_archive.._archive";

	
	if(	(Manager::getId(archiveArchiveName, dpId_archiveArchive) != PVSS_TRUE) ||
		(Manager::getId(archiveTypeName, dpId_archiveType) != PVSS_TRUE) ){
			PVSSWARNING("Could not query DP ID for "<<archiveArchiveName<<" or "<<archiveTypeName);
	}else{
		m_isDpeBeingArchived=false;
		// First, query _archive.._type - if set to 0, archiving is not configured
		{
			PVSSlong archiveType = 0;
			{
				DpIdentList dpList;
				dpList.append(dpId_archiveType);
				
				CdpGetCallBackHandler handler;
				getValuesOfDPEs(handler, dpList);

				const DpIdValueList & answerList = handler.getListOfResponses();
				const DpVCItem* responsePair = answerList.getFirstItem();
				archiveType = ((IntegerVar*)responsePair->getValuePtr())->getValue();
			}

			if (archiveType != 0){
				// Archive type is at least available, check whether archiving is active
				{
					DpIdentList dpList;
					dpList.append(dpId_archiveArchive);
					
					CdpGetCallBackHandler handler;
					getValuesOfDPEs(handler, dpList);

					const DpIdValueList & answerList = handler.getListOfResponses();
					const DpVCItem* responsePair = answerList.getFirstItem();
					BitVar* isArchivingActive = (BitVar*)responsePair->getValuePtr();
					if (isArchivingActive->getValue() == PVSS_TRUE){
						m_isDpeBeingArchived=true;
					}
			}
		}
				
	  }
	}
		
	if ((Manager::getId(valueName, dpId_value) == PVSS_TRUE) &&
		(Manager::getId(timestampName, dpId_timestamp) == PVSS_TRUE) &&
		(Manager::getId(invalidBitName, dpId_invalid) == PVSS_TRUE) &&
		(Manager::getId(lockCorrValueName, dpId_corrValueLock) == PVSS_TRUE) &&
		(Manager::getId(lockOrigValueName, dpId_origValueLock) == PVSS_TRUE) &&
		(Manager::getId(corrValueName, dpId_corrValue) == PVSS_TRUE) &&
		(Manager::getId(corrTimestampName, dpId_corrTimestamp) == PVSS_TRUE) &&
		(retrieveDPEsValueType(valueType) == true)){
			valid = true;
	} else {
		if (Manager::getId(valueName, dpId_value) == PVSS_FALSE) {
			PVSSERROR("Wrong mapping for : "<<valueName);
		} else if (Manager::getId(timestampName, dpId_timestamp) == PVSS_FALSE) {
			PVSSERROR("Wrong mapping for : "<<invalidBitName);
		} else if (Manager::getId(invalidBitName, dpId_invalid) == PVSS_FALSE) {
			PVSSERROR("Wrong mapping for : "<<timestampName);
		} else if (Manager::getId(lockCorrValueName, dpId_corrValueLock) == PVSS_FALSE){
			PVSSERROR("Wrong mapping for : "<<lockCorrValueName);
		} else if (Manager::getId(lockOrigValueName, dpId_origValueLock) == PVSS_FALSE){
			PVSSERROR("Wrong mapping for : "<<lockOrigValueName);
		} else if (Manager::getId(corrValueName, dpId_corrValue) == PVSS_FALSE){
			PVSSERROR("Wrong mapping for : "<<corrValueName);
		} else if (Manager::getId(corrTimestampName, dpId_corrTimestamp) == PVSS_FALSE){
			PVSSERROR("Wrong mapping for : "<<corrTimestampName);
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



