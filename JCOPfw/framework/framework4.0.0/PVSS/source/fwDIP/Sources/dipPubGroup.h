// dipPubGroup.h: interface for the CdipPubGroup class.
//
//////////////////////////////////////////////////////////////////////

#if !defined(AFX_DIPPUBGROUP_H__6F3FF9A5_C920_4113_B301_03117A2F59C1__INCLUDED_)
#define AFX_DIPPUBGROUP_H__6F3FF9A5_C920_4113_B301_03117A2F59C1__INCLUDED_

#if _MSC_VER > 1000
#pragma once
#endif // _MSC_VER > 1000


#include <DpMsgHotLink.hxx> 
#include <map>
//#include <vector>
#include "dpeMapping.h"
#include "dpeMappingTuple.h"
#include "DipPublication.h"
#include "DipPublicationErrorHandler.h"
#include "platformDependant.h"


class CPubGroupException{};


/**
* function used for ordering entries in the maps. For some reason less<>
* was not working.
*/
struct DpIdentifierLess  {
	bool operator()(const DpIdentifier * _X, const DpIdentifier * _Y) const
	{
		return ((*_X < *_Y) == 1); 
	}
};


/**
* Manager of one or more DPEs that together form a DIP publication
* Listens for changes to DPE's it is managing, creates a DIPdata
* object from  changes and sends them.
*/
class CdipPubGroup:public HotLinkWaitForAnswer
{
private:
	/**
	* Used to handle asynch DIP errors - currently does nothing // TODO
	*/
	class CpubErrorHandler:public DipPublicationErrorHandler{
	public:
		void handleException(DipPublication* publication, DipException& ex);	
	};


	///holds a list of all DPE that make up this publication
	std::map<const DpIdentifier *,CdpeMapping *, DpIdentifierLess> dpeMappings;

	/// name of the DIP publication
	const CharString pubName;


	/**
	* The amount of time we are to wait from the first changes before
	* the data object that is built is sent.
	*/
	const int bufferTime_ms;


	/// the publication through which DPE value are to be published 
	DipPublication * pub;


	/// object used to build values to be published
	DipData * dataObject;


	/**
	* Delete currently existing mappings
	*/
	void deleteMappings();


	/// Handler of DIP errors
	CpubErrorHandler dipErrorHandler;

	
	/**
	* Used to prevent the data object being updated while the publication is being updated
	*/
	SMutex dataObjectUpdateLock;


	/**
	* Holds the most recent time stamp of the DPEs forming this publication group
	*/
	DipTimestamp mostRecentDpeTime;


	/**
	* Used to track the number of DPEs that are currently invalid
	*/
	unsigned long numberOfDPEsInvalid;




	enum ATTRIBLIST{VALUE=0, TIMESTAMP=1, VALIDITY=2};

	/**
	* update the DpData object from attributes received in the hotLinkCallBack handler
	*/
	void updateDipDataFromDpeAttribs(DpVCItem * dpeAttribValues[3]);
	


	/**
	* Update the DPE wrapper to reflect the current state of the the invalidity attribute for that DPE.
	* a counter of DPE's whos invalid attribute is set is maintained.
	*/
	void updateDPEWrapperInvalidityAttrib(CpubDpeWrapper & changedDpe, DpVCItem * dpeValidityAttrib);

	
	/**
	*  Number of retries prior to give (re)creating publications.
	*/
	int retryCounter;


public:
	/**
	* Creates relationship between DPEs and Publication. Does DP connect
	* to DPEs. According to the following rules:-
	* 1. Attributes for a given DPE are subscribed to in the following order
	*	a) value
	*	b) timestamp
	*	c) validity
	* 2. If theBufferTime = 0 then all attributes for all DPEs are connected to in one DP connect
	*    otherwise the attributes for one DPE are connected to in one DP connect.
	* Will throw a CPubGroupException if any of the mappings are invalid
	*/
	CdipPubGroup(const CharString & thePubName, const int theBufferTime,const std::vector<CdpeMappingTuple *> &mappingList); // throws CPubGroupException



	virtual ~CdipPubGroup();


	/**
	* Update the publication with the contents of dataObject
	*/
	void updatePublication();

	//Recreates the required DIP publications.
	bool rebindDIPPublication() throw (CPubGroupException);


	/// returns pub name (clone of name passed in the constructor)
	const CharString & getPubName() const{
		return pubName;
	}


	/**
	  * Used to pick up the initial value of the list
	  * If value is uninitialised (timestamp = 0 i.e. 1 jan 1970...)
	  * the value will be ignored.
	  */
	  void hotLinkCallBack (DpMsgAnswer &answer);

	  /**
	  * Used to pick up subsequent changes to the list. Should get values for value,
	  * time, validity (in that order) of at least one DPE (due to way connections are
	  * made in the constructor)
	  */
	  void hotLinkCallBack(DpHLGroup &group);

	  bool destroyDIPPublication() throw (CPubGroupException);

};

#endif // !defined(AFX_DIPPUBGROUP_H__6F3FF9A5_C920_4113_B301_03117A2F59C1__INCLUDED_)
