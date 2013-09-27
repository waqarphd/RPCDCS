#include "PVSSDIPAPIOptions.h"
#include "DIPClientManager.h"
#include "CdipDataMapping.h"
#include <iostream>
#include <assert.h>
#include "DipPublicationErrorHandler.h"




//const char CdipClientManager::pubNameDelimiter[2]={0x1a,0};
//MD Added as a delimiter the ! character
const char CdipClientManager::pubNameDelimiter[2][2]={{0x1a,0},{0x21,0}};


CdipSubscription * CdipClientManager::createDipSubscription(const CharString & pubName){
	CdipSubscription * pubSubscription = new CdipSubscription(pubName, apiManager);
	dipPubsSubscribedTo[&pubSubscription->getPubName()] = pubSubscription;
	return pubSubscription;
}


void CdipClientManager::destroySubscription(const CharString & pubName){
	std::map<const CharString *, CdipSubscription *, CharStringLess>::iterator pubIt = dipPubsSubscribedTo.find(&pubName);
	assert(pubIt != dipPubsSubscribedTo.end());
	CdipSubscription * sub = pubIt->second;
	dipPubsSubscribedTo.erase(pubIt);
	delete sub;
}


	/**
	* Used when switching from Standby mode to Hot. This recreates the DIP subscriptions.
	* It doesn`t change anything regarding the previously defined mappings.
	*/
	bool CdipClientManager::rebindAllDIPSubscription()
	{
		bool result = true;
		if (dipPubsSubscribedTo.size() == 0)
		{
			//Do nothing.
			//Return false.
		}
		else {
			//The map<> is populated, run over it and call for each entry the creation of the DIP subscription.
			std::map<const CharString *, CdipSubscription *, CharStringLess>::iterator runner = dipPubsSubscribedTo.begin();
			for (; runner != dipPubsSubscribedTo.end(); runner++) {
				assert(NULL != runner->second);
				result = result && runner->second->rebindDIPSubscriptionOnly();
			}
			//Here all the data had been resubscribed.
		}
		return (result);
	}

	/**
	* Used when switching from Hot mode to Standby. This destroyes the DIP subscriptions.
	* It doesn`t change anything regarding the previously defined mappings.
	*/
	bool CdipClientManager::destroyAllDIPSubscription()
	{
		bool result = true;
		if (dipPubsSubscribedTo.size() == 0)
		{
			//Do nothing.
			//Return false.
		}
		else {
			//The map<> is populated, run over it and call for each entry the destruction of the DIP subscription.
			std::map<const CharString *, CdipSubscription *, CharStringLess>::iterator runner = dipPubsSubscribedTo.begin();
			for (; runner != dipPubsSubscribedTo.end(); runner++) {
				assert(NULL != runner->second);
				result = result && runner->second->destroyDIPSubscriptionOnly();
			}
			//Here all the data had been unsubscribed.
		}
		return (result);
	}

bool CdipClientManager::subscribeDPE(CdpeWrapper & dpeID){
	CharString name=dpeID.getDipAddress();

	// First of all extract the publication and tags names
	CharString pubName;
	CharString tagName;
	int pos1 = 0;
	int pos2 = 0;
	int pos = 0;
	pos1 = name.indexOf(pubNameDelimiter[0],0); // Search for the character [SUB]
	pos2 = name.indexOf(pubNameDelimiter[1],0); // Search for the character !

	if ((pos1 == -1) && (pos2 == -1)) {
		//None of the delimiters was found, report problem.		
		PVSSERROR("None of the configuration string delimiters "<<pubNameDelimiter[0]<<" and "<<pubNameDelimiter[1]<<" were found for Subscriptions.");
	} else if ((pos1 != -1) && (pos2 == -1)) {
		//The delimiter 1 is used, its ok.
		pos = pos1;
	} else if ((pos1 == -1) && (pos2 != -1)) {
		//The delimiter 2 is used, its ok.
		pos = pos2;
	} else {
		//Well this is tricky, both delimiters are present 
		//while they should be mutually exclusive, report problem.
		PVSSERROR("Configuration string delimiters "<<pubNameDelimiter[0]<<" and "<<pubNameDelimiter[1]<<" are both present for Subscriptions, take first one.");
		pos = pos1;
	}

	if (pos == std::string::npos){
		//tagName.clear();
		pubName = name;
	} else {
		std::string tmpName(name);    // CharString has no substr like function
		tagName = tmpName.substr(pos+1).c_str();
		pubName = tmpName.substr(0, pos).c_str();
	}

    // Now see if we are already have subscribers to that publication.
	std::map<const CharString *, CdipSubscription *, CharStringLess>::iterator it = dipPubsSubscribedTo.find(&pubName);
	CdipSubscription * pubSubscription = NULL;
	bool subscriptionPreviouslyExisted = true;
	if (it == dipPubsSubscribedTo.end()){
		pubSubscription = createDipSubscription(pubName);
		subscriptionPreviouslyExisted = false;
	}
	else {
		pubSubscription = it->second;
	}

	// now add to tag-DPE mapping
	// TODO error if no tag or tag added to sub that is already the opposite
	pubSubscription->createMapping(tagName, name, dpeID);
	if (subscriptionPreviouslyExisted){
		// request data resend at end of config mapping update.
		pubSubscription->markForGetLastPubValue();
	}
	return true;
}



void CdipClientManager::unsubscribeDPE(const CdpeWrapper & dpe){
	assert(dpe.getMapping() != NULL);
	CdipSubscription & sub = dpe.getMapping()->getSubscription();
	sub.destroyMapping(dpe);
	assert(dpe.getMapping() == NULL);

	/*
	Originally I wanted to remove any subscriptions without mappings here (Symetric with subscribeDPE()).
	But this is ineffiecient if another mapping will be made afterwards (but before sweep
	since we would have to go through the subscription again).
	So it it left to sweep() to clean up any subscriptions without mappings.
	*/
}



void CdipClientManager::dataChanged(const VariablePtr changedData){
	PVSSTRACE(TRACEIN,"CdipClientManager::dataChanged ()");
	configLock.lock();
	const DynVar * clientList = (DynVar *)changedData;
  //CmutexGuard guard(configLock);


  TextVar * clientsName = (TextVar *)clientList->getFirst();
  while (clientsName != NULL){
	// check to see if the mapping alread exists. (wrapper exists => mapping exists)
	std::map<const CharString *, CdpeWrapper *, CharStringLess>::iterator it = dpeClients.find(&(clientsName->getString()));
	if (it == dpeClients.end()){
		// mapping does not exist - add it.
		CdpeWrapper * clientDp = new CdpeWrapper(clientsName->getString());
		dpeClients[&clientDp->getName()] = clientDp;
		clientDp->revalidateDPE();
		if (clientDp->isValid()){
			subscribeDPE(*clientDp);
			clientDp->mark();
		}
		else {
			// sweep will clear it.
			//MD This is a strange way to do it, though, it was not necessary to add it in the map<> in the first place.
			clientDp->clearMark();
			PVSSERROR("DPE "<< (const char *)clientDp->getName() << " is not a valid DPE - ignoring");
		}
	} else {
		// mapping (and thus subscription) exists - but has it changed?
		CdpeWrapper & clientDp = *it->second;
		assert(clientDp.getMapping() != NULL);
		//MD: Check the current data in the mapping with what is in PVSS for this DPE.
		if (clientDp.getMapping()->dpeSubscriptionHasChanged()){
			// DPE mapping has changed
			if (!clientDp.isValid()){
				clientDp.clearMark();
				//DO_NOTHING DPE is no longer valid - DPE wrapper will be removed during the sweep phase.
			}
			else {
				unsubscribeDPE(clientDp);
				subscribeDPE(clientDp);
				clientDp.mark();
			}
		} else {
				// no change - mark it so it does not get deleted on the sweep phase
				clientDp.mark();
		}
	}

	clientsName = (TextVar *)clientList->getNext();
  }

	/**
	* At this point it is possible that there is a subscription without any mappings
	* associated with it (a remap between two subscriptions where the first sub only had
	* one mapping - now it has none) or a Wrapper without any associated publication (newly
	* created wrapper is invalid). Sweep () must take this into account.
	*/


	// get rid of any old mappings
	sweep();

	// any subscriptions which are not new, but have new mappings to them must
	// have the pub data resent.
	requestAnySubscriptionResends();
	configLock.release();
	PVSSTRACE(TRACEOUT,"CdipClientManager::dataChanged ()");
}

void CdipClientManager::requestAnySubscriptionResends(bool forceRefresh){
	if(forceRefresh){
		PVSSWARNING("Requesting a 'last published value refresh' of ALL DIP subscriptions");
	}
	int countPubs = 0;
	std::map<const CharString *, CdipSubscription *, CharStringLess>::iterator pubIt = dipPubsSubscribedTo.begin();
	while (pubIt != dipPubsSubscribedTo.end()){
		CdipSubscription & sub = *pubIt->second;
		pubIt++;
		countPubs++;
		if (forceRefresh==true || sub.mustGetLastPubValue()){
			sub.requestLastPublishedValue();
		}
	}
	if(forceRefresh){
		PVSSWARNING("Successfully issued 'last published value refresh' requests for "<< countPubs <<" DIP subscription(s)");
	}

}


void CdipClientManager::requestAnySubscriptionResends(){
  requestAnySubscriptionResends(false);
}





void CdipClientManager::sweep(){
	std::map<const CharString *, CdpeWrapper *, CharStringLess>::iterator clientIt = dpeClients.begin();
	while (clientIt != dpeClients.end()){
		CdpeWrapper & dpe = *clientIt->second;
		if (!dpe.isMarked()){
			// delete mapping and DPE wrapper - either it is no longer valid or been removed from the subscription list
			std::map<const CharString *, CdpeWrapper *, CharStringLess>::iterator toDelete = clientIt;
			clientIt++;
			dpeClients.erase(toDelete); // remove it from the look up table.
			if (dpe.getMapping()){
				CdipSubscription & sub = dpe.getMapping()->getSubscription();
				sub.destroyMapping(dpe);
			}
			delete &dpe;
		}
		else {
			dpe.clearMark();
			clientIt++;
		}
	}

	/*
	Clean up any subscriptions that no longer have mappings
	*/
	std::map<const CharString *, CdipSubscription *, CharStringLess>::iterator pubIt = dipPubsSubscribedTo.begin();
	while (pubIt != dipPubsSubscribedTo.end()){
		CdipSubscription & sub = *pubIt->second;
		pubIt++;
		if (sub.getNumberOfMappings() <=0){
			// remove the subscription - no dpe's are using it
			destroySubscription(sub.getPubName());
			// sub is now invalid!!!!
		}
	}
}


#ifdef TEST_NODIP
CdipSubscription * CdipClientManager::getPub(const CharString& name) const{
	std::map<const CharString *, CdipSubscription *, CharStringLess>::const_iterator it;
	it = dipPubsSubscribedTo.find(&name);
	if (it == dipPubsSubscribedTo.end()){
		return NULL;
	}

	return it->second;
}
#endif
