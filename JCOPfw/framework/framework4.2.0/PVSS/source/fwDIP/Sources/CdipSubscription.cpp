#include "PVSSDIPAPIOptions.h"
//#include <iostream>

#include "CdipSubscription.h"
#include "CdipDataMapping.h"
#include "PVSS_DIP_TypeMap.h"
#include "DipApiManager.hxx"



CdipSubscription::CdipSubscription(const CharString & pubName, DipApiManager & m)
:publication(pubName), connectedToPublication(false), mustGetLastPubValueFlag(false), lock((std::string(pubName)+"Lock")),apiManager(m), isReconnected(false) {
	subscription = DipApiManager::getDip().createDipSubscription(pubName, this);
	m_lastSubscriptionReconnectionTimestamp = 0;
	PVSSINFO( "Created subscription to " << (const char *)publication);
}



CdipSubscription::~CdipSubscription(){
	//The subscription may be null is passivated already.
	if (NULL != subscription)
	{
		DipApiManager::getDip().destroyDipSubscription(subscription);
	}
	while (tagMappings.size() != 0){
		CdipDataMapping * mapping = tagMappings.back();
		tagMappings.pop_back();
		delete mapping;
	}

	PVSSINFO("Destroyed subscription to " << (const char *)publication);
}

/**
* Used when switching from Standby mode to Hot. This recreates the DIP subscription.
* It doesn`t change anything regarding the previously defined mapping.
*/
bool CdipSubscription::rebindDIPSubscriptionOnly()
{
	bool result = false;
	try {
		subscription = DipApiManager::getDip().createDipSubscription(publication, this);
		assert (NULL != subscription);
		result = true;
	}
	catch (DipException & ex)
	{
		PVSSERROR("DIP Exception " << ex.what() << " thrown while re -creating publication: " <<static_cast<const char *>(getPubName()));
		result = false;
	}
	catch (...)
	{
		PVSSERROR("Exception thrown while re -creating publication: " <<static_cast<const char *>(getPubName()));
		result = false;
	}
	return (result);
}

/**
* Used when switching from Hot mode to Standby. This destroyes the DIP subscription.
* It doesn`t change anything regarding the previously defined mapping.
*/
bool CdipSubscription::destroyDIPSubscriptionOnly()
{
	bool result = false;
	try 
	{
		DipApiManager::getDip().destroyDipSubscription(subscription);
		subscription = NULL;
		result = true;
	}
	catch (DipException & ex)
	{
		PVSSERROR("DIP Exception " << ex.what() << " thrown while destroying subscription: " <<subscription->getTopicName());
		result = false;
	}
	catch (...)
	{
		PVSSERROR("Exception thrown while destroying subscription: " <<subscription->getTopicName());
		result = false;
	}
	return (result);
}

/*
Do not want mappings to change whilst message handler is being called - use
lock to protect against this.
*/
void CdipSubscription::createMapping(const CharString & tagName, const CharString & fullDipAddress, CdpeWrapper &dpeID){
	SmutexGuard guard(lock);
	// mapping is created in a marked state.
	CdipDataMapping * mapping = new CdipDataMapping(dpeID, tagName, fullDipAddress, *this);
	tagMappings.push_back(mapping);


	/**
	* MD OBSOLETE: mark DPE as invalid (with timestamp 0) until we get the connection
	* MD: Here is the real change, do not use 0 as timestamp, but use the existing PVSS timstamp instead.
	* PVSS will reject 0 anyway and set the current time as the timestamp. The problem is that when we will
	* get the connection to DIP, the DIP timestamp will probably earlier than the current PVSS one, and will be rejected.
	*/

	DpIdValueList * list = new DpIdValueList();
	//Retrieve the current PVSS timestamp for this mapping.
	mapping->timestampCheck();

	//Build -up the time as a long type;
	DipLong PVSSCurrentTime = (mapping->timeSecondsPVSS)*1000L + mapping->timeMSecPVSS;
	mapping->addInvalidBitToList(true,*list);

	// DIP-44 Add a lock on the DPE Corr and Online value to avoid other PVSS managers
	//   updating the DPE while the DIP manager is running
	mapping->addLockValueToList(true, *list);

	sendListOfUpdatesToPVSS(list, PVSSCurrentTime); 
}




void CdipSubscription::destroyMapping(const CdpeWrapper &dpeID){
	std::vector<CdipDataMapping *>::iterator it = tagMappings.begin();
	while (it != tagMappings.end()){
		CdipDataMapping *map = *it;
		if (dpeID == map->getMappedDpe()){

			// Not great here - we should copy the object by pointer
			CdpeWrapper dpeIdent = dpeID;

			// DIP-44
			dpeIdent.unlockDPE();
				
			tagMappings.erase(it);

			delete map;
			break;			
		}
		it++;
	}	
}

DipLong CdipSubscription::getCurrentTimeAsDipLong(){
	TimeVar currentTime;
    BC_CTime timeSeconds;
	short timeMSec;
	currentTime.getValue(timeSeconds, timeMSec); 
	return (((DipLong)timeSeconds.ElapsedSeconds() * 1000) + timeMSec);
}

/*
Now the API manager can be reconfigured at run time. This means that DPE's
can be 
1)added
2)removed
3)changed. 
What we do NOT want to happen is that these opertions occur the when in the handler
as it will mess up the iterators and possibly the CdipDpeBridge::addValueToList operation,
so we lock this instance so that add/removes can not it can not occur whilst the handler 
is iterating though the list.
*/
void CdipSubscription::handleMessage(DipSubscription* subscription, DipData& data){
	//PVSSTRACE(TRACEIN,"CdipSubscription::handleMessage()");
	if (this->mustGetLastPubValue()){
		/**
		* clear any pending update request, since we have just received the data
		* the new mapping needed (see mustGetLastPubValueFlag).
		* this situation may occur (for example) if updating a DPE mapping configuration
		* will cause two (or more) mappings are made to an newly created subscription. The 2nd
		* mapping would cause the mustGetLastPubValueFlag to be set, whilst the creation of
		* the subscription will cause this subscription to automatically receive the last transmitted
		* publication data. If we do'nt clear the flag this subscription will request the data a second
		* time, if we don't have this mechanism subsequent mappings may not recv a value until the
		* subscribed to publication explicitly publishes a new value(s).
		*/
		this->mustGetLastPubValueFlag = false;
	}

	if (data.extractDataQuality() == DIP_QUALITY_UNINITIALIZED){
		PVSSLOG(ErrClass::PRIO_INFO, "Uninitialized DIP data received, skipped.");
		return;
	}

	//PVSSLOG(ErrClass::PRIO_INFO, "Data received and being processed.");

	//PVSSINFO("Subscription received " << (int)data.size() << " data fields from pub " << (const char *)(this->getPubName()) << " with ts " << data.extractDipTime().getAsMillis() << " quality "<< data.extractDataQuality());

	try{
		DpIdValueList *list = new DpIdValueList();
		
		//MD In case the DIP data time is older than datapoints time , 
		// then force current time and send a Warning message with the previous time and the new time.
		DipLong lastTagMappingUpdateTimestamp = 0l;
		{
			SmutexGuard guard(lock); // lock this instance whilst in this code block
			std::vector<CdipDataMapping *>::const_iterator it = tagMappings.begin();
			lastTagMappingUpdateTimestamp = ((*it)->timeSecondsPVSS)*1000L + (*it)->timeMSecPVSS;
		}

		DipLong timeInMs = 0l;

		{
			SmutexGuard guard(lock); // lock this instance whilst in this code block

			if (data.extractDipTime().getAsMillis() <= lastTagMappingUpdateTimestamp) {
				//Use current time instead and send warning.
				timeInMs = getCurrentTimeAsDipLong();
				PVSSINFO("Data from: "<<subscription->getTopicName()<<" has an older timestamp than PVSS, changed to current time.");

				addMappedDPEValueInformationToUpdateList(*list, data, timeInMs,data.extractDipTime().getAsMillis(), true, true);
			} else if( data.extractDipTime().getAsMillis() > getCurrentTimeAsDipLong()){
				// DIP-44 Case where the DIP value is in the future, we force it to current time but
				//  raise the User bit to indicate source time discrepancy
				timeInMs = getCurrentTimeAsDipLong();
				addMappedDPEValueInformationToUpdateList(*list, data, timeInMs, 0, true, true);
			} else {
				timeInMs = data.extractDipTime().getAsMillis();
				addMappedDPEValueInformationToUpdateList(*list, data, timeInMs, 0, true, false);
			}
		}


		{
			SmutexGuard guard(lock); // lock this instance whilst in this code block
			addMappedDPEValidityStatusToUpdateList(*list);
		}

		sendListOfUpdatesToPVSS(list, timeInMs);
		//PVSSINFO("Handle: List size = " << (int)list->getNumberOfItems ()<<".")
	} catch (std::runtime_error &de){
		PVSSERROR("Exception " << de.what() << 
			" thrown in handler for pub" <<
			(const char *)this->getPubName());
		int numFields;
		const char ** fields = data.getTags(numFields);
		PVSSINFO("Fields in publication are:-");
		for (int i = 0; i < numFields; i++){
			PVSSINFO(i << " " << fields[i]);
		}
	} catch (...){
		PVSSERROR("Exception thrown in handler for pub " <<
			(const char *)this->getPubName());
	}
	//PVSSTRACE(TRACEOUT,"CdipSubscription::handleMessage()");
}




void CdipSubscription::disconnected(DipSubscription* subscription, char * reason){
	connectedToPublication = false;

	PVSSWARNING("Connection lost with publisher of :"<<subscription->getTopicName()<<". Data has been set to invalid.");
	try {
		markMappedDPEsAsDisconnected();
	} catch (...){
		PVSSERROR("An error occured while trying to mark datapoints as disconnected.");
	}
}



void CdipSubscription::markMappedDPEsAsDisconnected(){
	// build DPE/value list
	DpIdValueList *list = new DpIdValueList();
	{
		SmutexGuard guard(lock); // lock this instance whilst in this code block
		std::vector<CdipDataMapping *>::const_iterator it = tagMappings.begin();
		while (it != tagMappings.end()){
			(*it)->addInvalidBitToList(true,*list);
			it++;
		}
	}
	sendListOfUpdatesToPVSS(list, getCurrentTimeAsDipLong());
}

void CdipSubscription::connected(DipSubscription* subscription){
	PVSSINFO("Connection established for :"<<subscription->getTopicName()<<".");
	PVSSLOG(ErrClass::PRIO_INFO, "Data received and being processed."<<subscription->getTopicName()<<".");
	connectedToPublication = true;
	m_lastSubscriptionReconnectionTimestamp = getCurrentTimeAsDipLong();
	try {
		markMappedDPEsAsConnected();
	} catch (...){
		PVSSERROR("May have to consume this one...connected.");
	}
}

void CdipSubscription::markMappedDPEsAsConnected(){
	// build DPE/value list

		DpIdValueList *list = new DpIdValueList;
	
		{
			SmutexGuard guard(lock); // lock this instance whilst in this code block
			std::vector<CdipDataMapping *>::const_iterator it = tagMappings.begin();

			while (it != tagMappings.end()){
				(*it)->addInvalidBitToList(false,*list);
				//TODO In case of reconnection, the user bits may not necessarily be set to true.
				(*it)->addUserBitsToList(false,false,*list);

				// DIP-44 Force the CDipDataMapping timestamp to now
				(*it)->timestampToNow();

				it++;
			}
		}

	// DIP-44  Instead of getting the last known timestamp from the DipDataMapping, we use the current time.
	sendListOfUpdatesToPVSS(list, getCurrentTimeAsDipLong());
}

void CdipSubscription::updateValidityOfMappedDPEs(){
	// build DPE/value list
	DpIdValueList *list = new DpIdValueList();
	{
		SmutexGuard guard(lock); // lock this instance whilst in this code block
		addMappedDPEValidityStatusToUpdateList(*list);
	}

	
	sendListOfUpdatesToPVSS(list, getCurrentTimeAsDipLong());
}

void CdipSubscription::addMappedDPEValueInformationToUpdateList(DpIdValueList & list, DipData& data, DipLong timestampToUseForPVSS, superlong originalDipTimestamp, bool updateOnlineValue, bool indicateTimeSourceDiscrepancy){

	try 
	{
	
		std::vector<CdipDataMapping *>::const_iterator it = tagMappings.begin();
		while (it != tagMappings.end())
		{
			(*it)->addValueToList(data, list, timestampToUseForPVSS, originalDipTimestamp, updateOnlineValue, indicateTimeSourceDiscrepancy);
			it++;
		}
	} catch (...)
	{
		PVSSERROR("Exception thrown in addMappedDPEValue for pub " <<(const char *)this->getPubName());
	}
}


void CdipSubscription::addMappedDPEValidityStatusToUpdateList(DpIdValueList & list){	
	std::vector<CdipDataMapping *>::const_iterator it = tagMappings.begin();
	while (it != tagMappings.end()){
		(*it)->addValueValidityStatusToList(list);
		it++;
	}
}


void CdipSubscription::sendListOfUpdatesToPVSS(DpIdValueList * list, const DipLong timeAsMilliSec) const{
	//PVSSTRACE(TRACEIN,"CdipSubscription::sendListOfUpdatesToPVSS()");
	apiManager.queueDPEDataReadyForUpdate(list, timeAsMilliSec);
	//PVSSTRACE(TRACEOUT,"CdipSubscription::sendListOfUpdatesToPVSS()");
}





