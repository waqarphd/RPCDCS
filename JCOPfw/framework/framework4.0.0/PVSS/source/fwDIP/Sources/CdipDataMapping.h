#ifndef CDIPDATAMAPPING_H
#define CDIPDATAMAPPING_H


#include <string>
#include <vector>
#include "CdpeWrapper.h"
#include "DpIdentifier.hxx"
#include "DpIdValueList.hxx"
#include "Manager.hxx"
#include "platformDependant.h"
#include "mapping.h"


class CdipSubscription;


/**
* Holds a single mapping between a field in DIP data (identified by
* a DIP tag name) and a PVSS DPE.
*/
class CdipDataMapping: public Cmapping{
private:
	
	/// used to prevent changes to the mappings whilst handleMessage() is invoked
	SMutex lock;
	
	/// holds the full address in <publicationName>[#<tagName>] format
	const CharString fullDIPAddress;
	
	/// stores DPE type (so we can see if it has changed).
	const DpElementType dpeType;

	/// reference to the subscription that this mapping is part of.
	CdipSubscription & subscription;


	/**
	* True if the type conversion has failed (should only happen if pub has 
	* changed a feild type or removed the mapped to field)
	* @see valueConverter
	*/
	bool badTypeConversion;



	/**
	* stores the most recent quality - this is required by shouldDPEBeSetToInvalid()
	* which partially makes its decission based on this value;
	*/
	int mostRecentDipQuality;


	/**
	* DPE will be set to invalid under the following conditions:-
	* 1. Can not find a type conversion function for the DPE/DIP Pub tag type.
	* 2. The DIP publication mapped to is no longer available.
	* 3. The conversion function is no longer working (pub tag type changed or tag missing)
	* 4. The pub data has a quality which is NOT good.
	*/
	bool shouldDPEBeSetToInvalid();

	
	
	/**
	* stores whether this update shall be propagated to PVSS or not due
	* to a more recent timestamps for the current data in PVSS.
	* true  = to exclude
	* false = to propagate
	* which partially makes its decission based on this value;
	*/
	//bool excludeTimestampFlag;



	
	
public:

	longlong timeSecondsPVSS;
	
	short timeMSecPVSS;

	/**
	* Checks whether the data can be updated without problems from a PVSS timstamp perspective.
	* See excludeTimestampFlag.
	*/
	void timestampCheck();
	
	// TODO can reconstruct full dip address 
	/**
	* All mappings are created marked (they have to be on the config list to be created
	* so therefore they must be marked).
	*/
	CdipDataMapping(CdpeWrapper & dpId, const CharString & tagName, const CharString & dipAddress, CdipSubscription & sub);
	
	/**
	* Remove references. 
	*/
	virtual ~CdipDataMapping();


	
	/**
	* Will return true if the details of the DPE subscrition have changed since
	* this instance was created (or the wrapper's revalidateDPE() was called). 
	* A change means any of the following:-
	* 1. The DPE type has changed
	* 2. The publication name/tag has changed
	* 3. The driver type has changed.
	* 4. The address config no longer exists.
	* 5. DPE no longer exists
	*/
	bool dpeSubscriptionHasChanged();
	

	
	
	/** 
	* extracts the value of the mapped to tag for the data object, then
	* adds it along with the the dpeId that it is to be written too, to the
	* list of updates. The dip quality values are also added to the list.
	* @param list - contains values to update PVSS with - the value is owned by the list - list owner must destroy.
	*/
	void addValueToList(DipData & data, DpIdValueList &list);


	/**
	* Adds a flag redetermining if the DPE mapped to should be set to invalid.
	* Since this can be called from addValueToList() and the CdipSubscription connect/
	* disconnect call back handlers, it relies indirectly on the 'mostRecentDipQuality'
	* being the most recent possible. Thus if it is called from addValueToList() then
	* it essential that the maintainer ensures that mostRecentDipQuality is updated from
	* the newly received data before addValueValidityStatusToList() is called.
	* @param list - contains status to update PVSS with - the status value is owned by the list - list owner must destroy.
	*/
	void addValueValidityStatusToList(DpIdValueList &list);


	/**
	* Like the name says - adds the invalid bit attribute with value val to the list of updates 
	*/
	void addInvalidBitToList(bool val, DpIdValueList &list);



	/**
	* Added values for this DPE's user bits to the update list.
	*/
	void addUserBitsToList(bool ub1,bool ub2,DpIdValueList &list);




	/**
	* Returns the DPE this mapping maps to.
	*/
	CdpeWrapper & getMappedDpe() const{ 
		return dynamic_cast<CdpeWrapper &>(mappedDpe);
	}


	/**
	* Returns the subscription that this maps from
	*/
	CdipSubscription & getSubscription(){
		return subscription;
	}



};


#endif

