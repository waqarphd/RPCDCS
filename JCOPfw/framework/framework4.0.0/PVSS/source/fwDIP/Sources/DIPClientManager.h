#ifndef DIPCLIENTMANAGER_H
#define DIPCLIENTMANAGER_H

#include "CdipSubscription.h"
#include "CdpeWrapper.h"
#include "dipManager.h"

#include <map>
#include <functional>

class DipApiManager;


/**
* Singleton - one per API manager
*/
class CdipClientManager:public CdipManager{
private:
	/**
	* Holds a list of all the publications subscribed to.
	* keyed on the publication name.
	* CdipSubscription is OWNED by CdipClientManager.
	*/
	std::map<const CharString *, CdipSubscription *, CharStringLess> dipPubsSubscribedTo;
	
	/**
	* List of all DPE clients that have subscriptions.
	* Keyed on the DPE name
	* CdpeWrapper is OWNED by CdipClientManager.
	*/
	std::map<const CharString *, CdpeWrapper *, CharStringLess> dpeClients;



		/**
	* makes a mapping between a DPE and a publication field.
	*/
	bool subscribeDPE(CdpeWrapper & dpe);


	/**
	* remove a subscription to a DPE.
	*/
	void unsubscribeDPE(const CdpeWrapper & dpe);



	/**
	* Will create a new publication.
	*/
	CdipSubscription * createDipSubscription(const CharString & pubName);



	/**
	* Will destroy a subscription to the named publication, including the mapping.
	*/
	void destroySubscription(const CharString & pubName);



	/**
	* Used in conjuction with mark(). Will detete any subscriptions of DPE's 
	* to publications that have not been marked.
	* Will reset the mark flag of the DPE subscription.
	* Will clean up any publications that no longer have any associated mappings.
	*/
	void sweep();


	/**
	* It appears calls to the same hotlink callback handler that updates the subscription config (from PVSS)
	* are overlapping. This is making a mess of the mark/sweep algorithm. 
	*/
	SMutex configLock;



	/**
	* Request resends for any subscriptions that have new mappings
	* to them (otherwise the new mappings will have to wait till
	* the publication sends new data before they get updates).
	* @see CdipSubscription#mustGetLastPubValueFlag
	*/
	void requestAnySubscriptionResends();




public:
	/// used to seperate tag name from the publication name
	//static const char pubNameDelimiter[2];
	//MD Added the ! character as well, no I needed more space.
	static const char pubNameDelimiter[2][2];


	CdipClientManager(DipApiManager &m):CdipManager(m),configLock("SubConfigLock"){
	}


	virtual ~CdipClientManager(){
		std::map<const CharString *, CdipSubscription *, CharStringLess>::iterator pubIt = dipPubsSubscribedTo.begin();
		while (pubIt != dipPubsSubscribedTo.end()){
			delete (pubIt->second);
			pubIt++;
		}


		std::map<const CharString *, CdpeWrapper *, CharStringLess>::iterator clientIt = dpeClients.begin();
		while (clientIt != dpeClients.end()){
			delete (clientIt->second);
			clientIt++;
		}
	}

	/**
	* Used when switching from Standby mode to Hot. This recreates the DIP subscriptions.
	* It doesn`t change anything regarding the previously defined mappings.
	*/
	bool rebindAllDIPSubscription();

	/**
	* Used when switching from Hot mode to Standby. This destroyes the DIP subscriptions.
	* It doesn`t change anything regarding the previously defined mappings.
	*/
	bool destroyAllDIPSubscription();
	
	/**
	* Refresh's the subscriptions based on the client list.
	* Deals with the following:-
	* 1. Remapping where the subscription details have changed.
	* 2. Adding a mapping where a DPE name was previously unknown.
	* 3. Removing a mapping where a previously known DPE name is no longer is the list (mark and sweep).
	* @param clientList a list of strings containing ONLY DPE names.
	*/
	void dataChanged(const VariablePtr changedData);


#ifdef TEST_NODIP
	CdipSubscription * getPub(const CharString & name) const;
#endif
};

#endif

