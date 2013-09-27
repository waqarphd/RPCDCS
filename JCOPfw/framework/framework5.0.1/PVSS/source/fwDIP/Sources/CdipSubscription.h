#ifndef CDIPSUBSCRIPTION_H
#define CDIPSUBSCRIPTION_H


#include <string>
#include <vector>
#include "PVSS_DIP_TypeMap.h"
#include "CdpeWrapper.h"
#include "DipSubscription.h"
#include "DpIdentifier.hxx"
#include "DpIdValueList.hxx"
#include "Manager.hxx"
#include "platformDependant.h"


class DipApiManager;


/**
* Maps a single DIP publication onto one or more PVSS DPE's
* May have one tag mapping onto many DPE's.
* It is instances of this object that are true clients to DIP.
*/
class CdipSubscription: public DipSubscriptionListener{
private:

	/**
	* The actual Dip subscription.
	*/
	DipSubscription * subscription;

	/// remind us which publication we are a client of 
	const CharString publication; 
	


	/**
	* Holds all the tag mappings for one publication.
	* May have one tag mapped to many DPE's. This is
	* currently represented by multiple CdipDpeBridge
	* instances in the vector - this can be improved!
	*/
	std::vector<CdipDataMapping *> tagMappings;


	/**
	* Keeps track of whether or not this instance is connected 
	* to its publication.
	* Used also to detect a re-connection.
	*/
	bool connectedToPublication;

	/**
	* Tells if the current publication is re-connected to a DIP Publisher or not.
	* If true, then the timestamp is forced to the current time.
	*/
	bool isReconnected;

	/**
	* Flag to indicate that the subscribtion must request the last value
	* sent by the publisher. This is used in the situation where a subscription
	* already exists and additional fields within the subscription are being mapped
	* to. If we do not request a resend, then the DPE mapped to will not get a value
	* until the publication publishes new data (this may be a LONG time!), hence
	* this mechanism to trigger a resend.
	*/
	bool mustGetLastPubValueFlag;


	/// used to prevent changes to the mappings whilst handleMessage() is invoked
	SMutex lock;

	//DipLong m_lastSubscriptionReconnectionTimestamp;

	/**
	* ref to the API manager
	*/
	DipApiManager & apiManager;

		/**
		* Creates list of DPE validity entries and sends to PVSS.
		*/
		void updateValidityOfMappedDPEs();



		/**
		* Marks all DPE's mapped into this client as disconnected by setting
		* their invalid bits to true and using the current timestamp.
		*/
		void markMappedDPEsAsDisconnected();



		/**
		* Marks all DPE's mapped into this client as connected by setting
		* their invalid bits to false, user bits to bad and using the current timestamp.
		*/
		void markMappedDPEsAsConnected();


		/**
		* Adds to list 0 or more DPE value/status bit entries.
		*/
		void addMappedDPEValueInformationToUpdateList(DpIdValueList & list, DipData& data, DipLong timestampToUseForPVSS, superlong originalDipTimestamp, bool updateOnlineValue, bool indicateTimeSourceDiscrepancy);



		/**
		* Adds to list 0 or more DPE validity entries
		*/
		void addMappedDPEValidityStatusToUpdateList(DpIdValueList & list);



		/**
		* Sends a list of updates to PVSS
		* @param list - ownership passed to called routine.
		*/
		void sendListOfUpdatesToPVSS(DpIdValueList * list, const DipLong timeAsMilliSec) const;

		/**
		* Get the current PVSS time (i.e. now) as a DipLong
		*/
		DipLong getCurrentTimeAsDipLong();
	public:

		CdipSubscription(const CharString & pubName, DipApiManager & m);

		virtual ~CdipSubscription();

		/**
		* Will use the type of the DpIdentifier to identify the value
		* conversion function.
		*/
		void createMapping(const CharString & tagName, const CharString & fullDipAddress, CdpeWrapper &dpeID);


		/**
		* Will remove the mapping object from the subscription.
		*/
		void destroyMapping(const CdpeWrapper &dpeID);


		const CharString & getPubName() const{
			return publication;
		}

		/**
		* Used when switching from Standby mode to Hot. This recreates the DIP subscription.
		* It doesn`t change anything regarding the previously defined mapping.
		*/
		bool rebindDIPSubscriptionOnly();

		/**
		* Used when switching from Hot mode to Standby. This destroyes the DIP subscription.
		* It doesn`t change anything regarding the previously defined mapping.
		*/
		bool destroyDIPSubscriptionOnly();

		/**
		* THIS IS WHERE DIP DATA COMES INTO THE API MANAGER
		* Builds a list of DPE/values based on the mappings previously defined
		* and the data passed. The handler then updates the event manager based 
		* with the data contained in the list.
		*/
		void handleMessage(DipSubscription* subscription, DipData& data);


		/**
		* Catch the disconnection notification.
		*/
		void disconnected(DipSubscription* subscription, char *reason);


		/**
		* Catch the connection notification.
		*/
		void connected(DipSubscription* subscription);

		/**
		* Handle any error from DIP
		*/
		void handleException(DipSubscription* subscription, DipException& ex){
			PVSSERROR("Received an error from DIP: " << ex.what());
		}


		/**
		* Returns number of mappings (end hence DPEs) that are using this
		* subscription.
		*/
		int getNumberOfMappings(){
			return tagMappings.size();
		}


		/**
		* Used to determine if this subscription is connected to a 
		* publication.
		*/
		bool isConnectedToPublication() const{
			return connectedToPublication;
		}


		/**
		* @returns true if this subscription must issue a resend request
		* to update new mappings.
		* @see #mustGetLastPubValueFlag
		*/
		bool mustGetLastPubValue(){
			return mustGetLastPubValueFlag;
		}

		/**
		* Flag to subscription as needing a data resend
		* @see #mustGetLastPubValue()
		* @see #mustGetLastPubValueFlag
		*/
		void markForGetLastPubValue(){
			mustGetLastPubValueFlag = true;
		}

		/**
		* Requests the publication subscribed to to resend its
		* last published value. This will only occur if the publication
		* is in a connected state - if it is'nt then the publication does'nt
		* exist - so can't resend, when the publication does become connected
		* it will receive the last transmited value anyway (thats the way DIP
		* works). 
		* Note that the last transmited value will be received though the normal
		* listener DIP interface.
		* @see #handleMessage(DipSubscription*, DipData& data)
		*/
		void requestLastPublishedValue(){
			if (isConnectedToPublication()){
				subscription->requestUpdate();
			}
			mustGetLastPubValueFlag = false;
		}
};

#endif

