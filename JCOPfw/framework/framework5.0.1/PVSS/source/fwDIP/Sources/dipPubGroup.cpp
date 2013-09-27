// dipPubGroup.cpp: implementation of the CdipPubGroup class.
//
//////////////////////////////////////////////////////////////////////
#include "PVSSDIPAPIOptions.h"
#include "dipPubGroup.h"
#include "pubDpeWrapper.h"
#include "DipApiManager.hxx"
#include "DipApiResources.hxx"
#include <list>

#ifdef WIN32
#include <windows.h>    // for Sleep
#else
#include <unistd.h>     // for usleep on Linux
#endif // WIN32

//////////////////////////////////////////////////////////////////////
// Construction/Destruction
//////////////////////////////////////////////////////////////////////

/**
* Class to manage the Publication groups that have a buffer time associated with them.
* I.E. They must wait N mSec between the first change of the group and the publication
* being made.
*/
class PublicationUpdateThread:public SThread {
private:

	/**
	* Class used to hold the Publication group in the wait list. Holds the delay wait time
	* relative to the group infront of it in the queue.
	*/
	class GroupHolder{
	private:
		unsigned long mSecRelativeDelay;

		CdipPubGroup & pubGroup;
	public:

		GroupHolder(CdipPubGroup & group, unsigned long relativeMSecWait):
		  mSecRelativeDelay(relativeMSecWait) ,pubGroup(group){};


		  unsigned long getMSecDelay(){
			  return mSecRelativeDelay;
			  }


		  void setMSecDelay(unsigned long newDelay_Ms){
			  mSecRelativeDelay = newDelay_Ms;
			  }


		  void publishPubGroup(){
			  pubGroup.updatePublication();
			  }

		  bool sameGroup(CdipPubGroup & group){
			  return (&pubGroup == &group);
			  }

		};


	/**
	* PubGroups waiting to publish. In time order. The group to be published next
	* is on the front of the list. Owned!
	*/
	std::list<GroupHolder *> groupsWaitingToPublish;


	/**
	* Used to protected the data structure against concurrent access.
	*/
	SMutex lock;


	/**
	* Used to wait for the next time delay to expire (A timeout event).
	* However, sometime we must reschedule the wait queue, in which case we
	* send signal the event.
	*
	*/
	SEvent publisherDelay;


	/**
	* The time that publisherDelay started waiting
	*/
	struct timeb startWait;


public:
	PublicationUpdateThread():
	  lock(SString("PublicationUpdateThread_lock")),
		  publisherDelay(SString("PublicationUpdateThread_event"))
		  {}


	  /**
	  * Clear up waiter list
	  */
	  virtual ~PublicationUpdateThread(){
		  std::list<GroupHolder *>::iterator it = groupsWaitingToPublish.begin();

		  while (it != groupsWaitingToPublish.end()){
			  GroupHolder *h = *it;
			  it++;
			  delete h;
			  }
		  }



	  /**
	  * Add group to the appropraite place in the ordered wait list.
	  * @returns true if added to list, false if already on list.
	  */
	  bool addGroup(CdipPubGroup & group, unsigned long mSecToWaitBeforePublish){
		  bool mustReschedule = false;
			  {
			  SmutexGuard l(lock); 

			  /*
			  //cout<<"Group contains "<<groupsWaitingToPublish.size()<<" entries."<<endl; 
			  //cout<<"About to add the PubGroup: "<<group.getPubName()<<" with mSecToWaitBeforePublish: "<<mSecToWaitBeforePublish<<endl; 
			  //Dump List content:
			  std::list <GroupHolder *>::iterator itDebug = groupsWaitingToPublish.begin();
			  int i = 0;
			  while (itDebug != groupsWaitingToPublish.end()){
				  cout<<"List<"<<i<<"> = "<<(*itDebug)->pubGroup.getPubName()<<"/"<<(*itDebug)->getMSecDelay()<<endl;
				  itDebug++;
				}
			   */
	
			  if (groupsWaitingToPublish.size() != 0){
				  // adjust the amount of time left that the next PubGroup to publish must wait
				  struct timeb currentTime;
				  ftime(&currentTime);
				  DipLong mSecWaitedSoFar  = currentTime.millitm - startWait.millitm;
				  //cout<<"mSecWaitedSoFar (=) "<<mSecWaitedSoFar<<" = "<<currentTime.millitm<<" - "<<startWait.millitm<<endl;
				  mSecWaitedSoFar += ((DipLong)currentTime.time - (DipLong)startWait.time) * (DipLong)1000;
				  //cout<<"mSecWaitedSoFar (+=) "<<mSecWaitedSoFar<<" += "<<(DipLong)currentTime.time<<" - "<<(DipLong)startWait.time<<" (*1000)"<<endl;
				  long timeLeftForCurrentPub = groupsWaitingToPublish.front()->getMSecDelay() - mSecWaitedSoFar;
				  //cout<<"timeLeftForCurrentPub (=) "<<timeLeftForCurrentPub<<" = "<<groupsWaitingToPublish.front()->getMSecDelay()<<" - "<<mSecWaitedSoFar<<endl;
				  if (timeLeftForCurrentPub < 0) timeLeftForCurrentPub = 0;				
				  //cout<<"(1)setMSecDelay changed to: "<<timeLeftForCurrentPub<<endl;
				  groupsWaitingToPublish.front()->setMSecDelay(timeLeftForCurrentPub);
				  ftime(&startWait); // in case add group called >1 before thread main is run
				  }

			  std::list <GroupHolder *>::iterator it = groupsWaitingToPublish.begin();
			  std::list <GroupHolder *>::iterator insertbefore = it;
			  bool insertionPointAssigned = false;
			  unsigned long totalTimeLeftToWait = 0;
			  unsigned long relativeMSecDelay = 0;

			  //Looking for the correct insertion point in the list.
			  while (it != groupsWaitingToPublish.end()){
				  if ((*it)->sameGroup(group)){
					  return false;
					  }
				  if (*it == NULL) {
					  return false;
					  }

				  totalTimeLeftToWait += (*it)->getMSecDelay();
				  if ((totalTimeLeftToWait > mSecToWaitBeforePublish) && !insertionPointAssigned){
					  insertbefore = it;
					  insertionPointAssigned = true;
					  relativeMSecDelay =  mSecToWaitBeforePublish - (totalTimeLeftToWait - (*it)->getMSecDelay());

					  }
				  it++;
				  }

			  if (!insertionPointAssigned){
				  // must add the group to the end of the list.
				  assert(totalTimeLeftToWait <= mSecToWaitBeforePublish);
				  relativeMSecDelay = mSecToWaitBeforePublish - totalTimeLeftToWait;
				  insertbefore = groupsWaitingToPublish.end();
				  } else {
					  // adjust the relative delay of the group that is to be pushed in front of
					  long newDelay = (*insertbefore)->getMSecDelay() - relativeMSecDelay;
					  assert(newDelay >= 0);
					  //cout<<"(2)setMSecDelay changed to: "<<newDelay<<endl;
					  (*insertbefore)->setMSecDelay(newDelay);
				  }

			  //cout<<"Now adding the PuGroup: "<<group.getPubName()<<" with relativeMSecDelay: "<<relativeMSecDelay<<endl; 
			  GroupHolder * h = new GroupHolder(group, relativeMSecDelay);
			  groupsWaitingToPublish.insert(insertbefore, h);
			  if (groupsWaitingToPublish.front() == h){
				  mustReschedule = true;
				  }
			  }
			  if (mustReschedule == true){
				  // new PubGroup at head of queue, mainThread must reschedule.
				  publisherDelay.signal();
				  }
			  return true;
		  }

	  void threadMain(){
		unsigned long idleDelayTime = 1000;

		//MD: Added to make sure the time is correctly initialized
		// when starting comparision between thread time and "addGroup" time.
		ftime(&startWait);

		while (!shouldStop){
			  unsigned long delayTime = idleDelayTime;
			  bool waitingToPublish = false;
				  {
				  SmutexGuard l(lock);
				  if (groupsWaitingToPublish.size() != 0){
					  ftime(&startWait);
					  delayTime = groupsWaitingToPublish.front()->getMSecDelay();
					  waitingToPublish = true;
					  }
				  }
				  short waitResult = publisherDelay.wait(delayTime);

				  if (shouldStop) break;

				  if (waitResult == 0){
					  /*
					  //For ce the SEvent to reset
					  publisherDelay.clearPending();
					  // reschedule publisher delay because a more recent group has
					  //been added to front of wait list --- do nothing here
					  if (waitingToPublish){
					  SmutexGuard l(lock);
					  GroupHolder *h = groupsWaitingToPublish.front();
					  groupsWaitingToPublish.pop_front();
					  //PVSSTRACE("Calling updatePublication from the threadMain.");
					  h->publishPubGroup();
					  delete h;
					  } //end if
					  */
					  } else if (waitResult == -2){
						  // the wait has failed - we assume this may only occur at the
						  // start of the wait() call, never part way thorough.
						  PVSSERROR("PublicationUpdateThread wait failed - retrying\n");
					  } else if (waitingToPublish){
						  GroupHolder *h = NULL;
							  {
							  SmutexGuard l(lock);
							  h = groupsWaitingToPublish.front();
							  groupsWaitingToPublish.pop_front();
							  }
							  //PVSSTRACE("Calling updatePublication from the threadMain.");
							  //cout<<"Thread requests publishing: "<<h->pubGroup.getPubName()<<" with delay: "<<h->getMSecDelay()<<endl;
							  h->publishPubGroup();
							  delete h;
						  } //end if
			  } //end while
		  } //end function
	};

static PublicationUpdateThread gdelayedPubThread;

const CharString CdpeMappingTuple::noTag = "";

void CdipPubGroup::CpubErrorHandler::handleException(DipPublication* publication, DipException& ex){
	PVSSERROR("Publisher received DIP error: "<<ex.what());
	// TODO better error handling
	}

CdipPubGroup::CdipPubGroup(const CharString & thePubName, const int theBufferTime,const std::vector<CdpeMappingTuple *> &listDpe)
: pubName(thePubName), bufferTime_ms(theBufferTime), pub(NULL), dataObjectUpdateLock(std::string(thePubName)+"updateLock")
, mostRecentDpeTime(0), numberOfDPEsInvalid(0), retryCounter(0) // throws CPubGroupException
	{
		
	//MD Moved the creation of the wait thread now from the beginning.
	if (gdelayedPubThread.isRunning() == false) 
		{
		gdelayedPubThread.start();
		}

	std::vector<CdpeMappingTuple *>::const_iterator it = listDpe.begin();
	DpIdentList attributesOfAllDpes;

	while (it != listDpe.end()){
		CpubDpeWrapper * dpe = NULL;
		try {
			if (*it == NULL) {
				PVSSERROR("Invalid DIP Pub Group" << (const char *)pubName << ". Check DIP configuration.");
				throw CPubGroupException();
				}
			CdpeMappingTuple & pair = **it;
			dpe = new CpubDpeWrapper(pair.getDpeName());
			if (!dpe->revalidateDPE()){
				PVSSERROR("Invalid DPE " << (const char *)pair.getDpeName() <<
					" can not be published through " << (const char *)pubName <<
					". This pub is now invalid.");
				delete dpe;
				deleteMappings(); //
				throw CPubGroupException();
				}

			CdpeMapping * mapping = new CdpeMapping(dpe, pair.getTagName());
			dpeMappings[&dpe->getDIPValueID()] = mapping;
			} catch (BadTypeConversionException &){
				// All the group is considered invalid.
				delete dpe;
				deleteMappings();
				throw CPubGroupException();
			} catch (...){
				PVSSERROR("Invalid DIP Pub Group" << (const char *)pubName << ". Check DIP configuration.");
				}

			// keep this order - it is maintained in the callback - this ordering property is used by the callback
			attributesOfAllDpes.append(dpe->getDIPValueID());
			attributesOfAllDpes.append(dpe->getDIPTimeStampID());
			attributesOfAllDpes.append(dpe->getDIPinvalidBit());
			it++;
		}

	/*
	We only make connections if we ctreated the mapping objects OK
	OK now we create the DP connections - how this is done depends on the buffer time
	0 means we expect an atomic update so we do a DP connect on a list of all DPEs in this
	group, >0 results in a DP connect on individual DPE's.
	*/
	if (bufferTime_ms == 0){
		Manager::dpConnect(attributesOfAllDpes, this, false);
		}else{
			const DpIdentifier* dpe = attributesOfAllDpes.getFirst();
			while(dpe){
				// Make connections in groups of releated attributes
				DpIdentList attributesOfOneDPE;
				attributesOfOneDPE.append(*dpe); // value
				attributesOfOneDPE.append(*(attributesOfAllDpes.getNext())); // timestamp
				attributesOfOneDPE.append(*(attributesOfAllDpes.getNext())); // invalidBit
				Manager::dpConnect(attributesOfOneDPE, this, false);
				dpe = attributesOfAllDpes.getNext();
				}
		}
	if (::DipApiResources::getActiveSystem() == true) 
		{
		pub = DipApiManager::getDip().createDipPublication(pubName, & dipErrorHandler);
		}
	else
		{
		pub = NULL;
		}

	dataObject = DipApiManager::getDip().createDipData();
	}

void CdipPubGroup::deleteMappings(){
	if (pub){
		PVSSINFO("Destroying Publication group " << pub->getTopicName());
		}
	else {
		PVSSINFO("Destroying pub group mappings before publication was created");
		}
	std::map<const DpIdentifier *,CdpeMapping *, DpIdentifierLess>::iterator it = dpeMappings.begin();
	while (it != dpeMappings.end()){
		std::map<const DpIdentifier *,CdpeMapping *, DpIdentifierLess>::iterator tmpIt = it;
		it++;
		delete tmpIt->second;
		dpeMappings.erase(tmpIt);
		}
	}

CdipPubGroup::~CdipPubGroup()
	{
	PVSSERROR("CdipPubGroup::~CdipPubGroup()");
	if (pub != NULL)
		DipApiManager::getDip().destroyDipPublication(pub);
	pub = NULL;
	delete dataObject;
	deleteMappings();
	}

void CdipPubGroup::updateDPEWrapperInvalidityAttrib(CpubDpeWrapper & changedDpe, DpVCItem * dpeValidityAttrib){
	bool oldInvalidAtt = changedDpe.isInvalidAttributeSet();
	changedDpe.storeInvalidAttribute(dpeValidityAttrib->getValuePtr());
	bool newInvalidAtt = changedDpe.isInvalidAttributeSet();
	if (oldInvalidAtt != newInvalidAtt){
		if (newInvalidAtt){
			++numberOfDPEsInvalid;
			// DIP-22 Added which DIP publication will become invalid as a result of this DPE having a problem
			PVSSWARNING("DPE "<< (const char *)changedDpe.getName() << " has " << (int)numberOfDPEsInvalid << " invalid bit set (DIP Publication "<< (const char *)getPubName()<< ")");
			}else{
				--numberOfDPEsInvalid;
				PVSSINFO("DPE " << (const char *)changedDpe.getName() << " has " << (int)numberOfDPEsInvalid << " invalid bit clear");
			}
		}
	}

void CdipPubGroup::updateDipDataFromDpeAttribs(DpVCItem * dpeAttribValues[3]){
	const DpIdentifier & dpeValueId = dpeAttribValues[VALUE]->getDpIdentifier();
	CharString name;
	Manager::getLIName (dpeValueId,name);
	std::map<const DpIdentifier *,CdpeMapping *,DpIdentifierLess>::iterator it = dpeMappings.find(&dpeValueId);
	if (!it->first){
		PVSSFATAL("Got value for DPE " << (const char *)name <<
			" which IS NOT MAPPED into "<< (const char *)getPubName() <<
			" -- THE API MANAGER SHOULD BE RESTARTED");
		}else{
			CpubDpeWrapper & changedDpe = it->second->getMappedDpe();
			updateDPEWrapperInvalidityAttrib(changedDpe, dpeAttribValues[VALIDITY]);
			// DIP-7 We publish all DPEs, even if they are marked as invalid
			try{
				it->second->writeValueToDipData(*dataObject, dpeAttribValues[VALUE]->getValuePtr()); // write DPE value to DipData object
				TimeVar * dpeTime = (TimeVar *)dpeAttribValues[TIMESTAMP]->getValuePtr();
				longlong dpeTimeInMsec = ((longlong)(dpeTime->getSeconds()) * 1000L);
				dpeTimeInMsec += dpeTime->getMilli();
				if (dpeTimeInMsec > mostRecentDpeTime.getAsMillis()){
					// most recent time attribute of DIP in publication group, hose time is most recent
					mostRecentDpeTime.setMillis(dpeTimeInMsec);
					}
			} catch(...){
				PVSSERROR("Mapping from DPE " << (const char *)name <<
					" to tag " << (const char *)it->second->getTagName() <<
					" has become invalid -- THE API MANAGER SHOULD BE RESTARTED");
			}
		}
	}

void CdipPubGroup::hotLinkCallBack(DpHLGroup &group){
	//PVSSTRACE(TRACEIN,"CdipPubGroup::hotLinkCallBack () for " << (const char *)pubName);
	{	// publication can not be updated while this code block is being executed
	SmutexGuard lock(dataObjectUpdateLock);
	DpVCItem* dpeAtributeList[3];
	dpeAtributeList[VALUE] = group.getFirstItem();

	// atttributes are expected in value,timestamp,validity order
	// this order is defined in the constructor by the dpconnect with an ordered list

	//MD TODO Suspicious... perhaps this is looping indefinitively...
	while(dpeAtributeList[VALUE]){
		dpeAtributeList[TIMESTAMP]	= group.getNextItem();
		dpeAtributeList[VALIDITY]  = group.getNextItem();

		updateDipDataFromDpeAttribs(dpeAtributeList);

		dpeAtributeList[VALUE] = group.getNextItem(); // value of next DPE or null
		}
	}

	if (bufferTime_ms == 0){
		/*
		* If we are here then we should have data for all the fields in the publication.
		*/
		//cout<<"group.getNumberOfItems()/3) = "<<(group.getNumberOfItems()/3)<<" and dpeMappings.size() = "<<dpeMappings.size()<<endl;
		assert((group.getNumberOfItems()/3) == dpeMappings.size());
		updatePublication();
		//PVSSINFO("Updated Pub " << (const char *)pubName << " (buffer time 0)");
		}else{
			// if the group is already on the delayed list this will do nothing
			gdelayedPubThread.addGroup(*this, this->bufferTime_ms);
		}
	}

void CdipPubGroup::hotLinkCallBack (DpMsgAnswer &answer) {
	// publication can not be updated while this code block is being executed
	SmutexGuard lock(dataObjectUpdateLock);
	AnswerGroup * group =  NULL;
	bool shouldUpdatePublication = true;
	group =  answer.getFirstGroup();
	while (group != NULL){
		DpVCItem* dpeAtributeList[3];
		// atttributes are expected in value,timestamp,validity order
		// this order is defined in the constructor by the dpconnect with an ordered list
		shouldUpdatePublication = true;
		dpeAtributeList[VALUE] = group->getFirstItem();
		while (dpeAtributeList[VALUE]){
			dpeAtributeList[TIMESTAMP] = group->getNextItem();
			dpeAtributeList[VALIDITY] = group->getNextItem();

			TimeVar * dpeTime = (TimeVar *)dpeAtributeList[TIMESTAMP]->getValuePtr();
			// only update if data initialised (time != 1st Jan 1970...)
			if (*dpeTime != TimeVar::NullTimeVar){
				updateDipDataFromDpeAttribs(dpeAtributeList);
				} else{
					PVSSWARNING((const char *)pubName << " has uninitialised DPE - no data will be published until it is initialised");
					shouldUpdatePublication = false;
				}

			dpeAtributeList[VALUE] = group->getNextItem(); // value of next DPE or null
			}



		/**
		* only update publication if all data in group was initialised.
		*/
		if (shouldUpdatePublication){
			if (bufferTime_ms == 0){
				/*
				* If we are here then we should have data for all the fields in the publication.
				*/
				//assert((group->getNumberOfItems()/3) == dpeMappings.size());
				//PVSSINFO("About to update publication");
				updatePublication();
				//PVSSWARNING("Updated Pub " << (const char *)pubName << " (buffer time 0)");
				}else{
					// if the group is already on the delayed list this will do nothing
					gdelayedPubThread.addGroup(*this, this->bufferTime_ms);
				}
			}

		group = answer.getNextGroup();
		//PVSSINFO("Got next group");
		}
	}

void CdipPubGroup::updatePublication(){
	SmutexGuard lock(dataObjectUpdateLock);
	//cout<<"updatePublication processing: "<<(const char *)this->getPubName()<<endl;

	if (NULL != pub) {
		if (numberOfDPEsInvalid != 0){
				PVSSINFO("Some DPS in the group are bad");
				SString message;
				message << (int)numberOfDPEsInvalid << " PVSS dpe's set to invalid";
				PVSSWARNING("Publication " <<  (const char *)this->getPubName() <<
					" : "<< (int)numberOfDPEsInvalid << " DPE's are set to invalid, publishing with DIP quality BAD."
					);

				///////////////////
				// DIP-7 : Still update the value, with invalid quality
				try{
					pub->send(*dataObject, mostRecentDpeTime);
					pub->setQualityBad(message);
					}
				catch (DipException &de){
					PVSSERROR(getPubName() << " caused dip exception " << de.what());
					}
				//
				///////////////////
			} else {
				//PVSSINFO("ALL of the DPE in the group are good");
				if ((unsigned)dataObject->size() == dpeMappings.size()){
					try{
						pub->send(*dataObject, mostRecentDpeTime);
						}
					catch (DipException &de){
						PVSSERROR(getPubName() << " caused dip exception " << de.what());
						}
					/*DINFO((
					"%s  published %d DPE's with ts %d(Ms)\n",
					(const char *)this->getPubName(), dataObject->size(), dataObject->extractDipTime().getAsMillis()
					));*/
					PVSSINFO((const char *)this->getPubName() << " published " << (int)dataObject->size() << " DPE's with ts " << mostRecentDpeTime.getAsMillis() <<"(Ms)");
					} else {
						int noMissingValues = dpeMappings.size() - dataObject->size();
						SString message;
						message << "PVSS has not supplied values for all fields making the publication (" << noMissingValues << " missing)";
						pub->setQualityBad(message);
						PVSSWARNING("Publication " << (const char *)this->getPubName()
							<< " not updated (set quality instead) at end of buffer time " <<
							bufferTime_ms <<" ms because manager only has data for " <<
							(int)dataObject->size() << " out of "<< (int)dpeMappings.size() << " fields");
					}
			}
		} else {
			//No DIP pub at the moment because in passivate mode. Thus do nothing.
			PVSSINFO("No DIP real publication was performed because of passivate mode.");
		}

	// code for debugging
	//	int noTags = 0;
	//	const char ** tags = dataObject->getTags(noTags);
	//	for (int i=0; i < noTags;i++){
	//		cout << "Sent data for tag \"" << tags[i] << "\" of publication " << pubName << endl;
	//	}
	}

bool CdipPubGroup::destroyDIPPublication() throw (CPubGroupException){

	bool result = false;
	try {
		if (pub) {
			DipApiManager::getDip().destroyDipPublication(pub);
			pub = NULL;
			result = true;
			} else {

				PVSSLOG(ErrClass::PRIO_WARNING, "A publication was NULL ");
				//Probably the system was passivated before there is actually a DIP publication created.
				//Do nothing.
			}
		}
	catch (DipException &de) {
		//Re -throw a known exception
		PVSSERROR("Could not destroy publication "<<pub->getTopicName()<<" ! Because of "<<de.what());
		throw (new CPubGroupException());
		}
	catch (...) {
		//Re -throw a known exception
		PVSSERROR("Could not destroy publication "<<pubName<<" !");
		throw (new CPubGroupException());
		}
	return (result);
	}

bool CdipPubGroup::rebindDIPPublication() throw (CPubGroupException){

	//SmutexGuard lock(dataObjectUpdateLock);
	//PVSSINFO("rebindDIPPublication: Got lock");
	bool result = false;
	retryCounter++;
	try {
		pub = DipApiManager::getDip().createDipPublication(pubName, & dipErrorHandler);
		for (int i = 0; i < 30; i++) {
			if (NULL == pub) {
				//Probably the system was activated before the other system finished to get passivated.
				PVSSWARNING("Try"<<i<<" to create pub. for "<<pubName<<" !");
				//Wait 200ms.
#ifdef WIN32
				::Sleep(200l);
#else
				::usleep(200000l);
#endif
				//Then create a DIP publication.
				pub = DipApiManager::getDip().createDipPublication(pubName, & dipErrorHandler);
				} else {
					result = true;
					retryCounter = 0;
					//PVSSLOG(ErrClass::PRIO_INFO, "Just rebinded Publication group " << pub->getTopicName());
					break;
				}
			}

		if (result == false) {
			PVSSERROR("Could not create publication for "<<pubName<<" !");
			}
		}
	catch (DipException &de) {
		//Re -throw a known exception
		if (retryCounter < 30) {
			PVSSWARNING("DIP Trial"<<retryCounter<<" to create pub. for "<<pubName<<" !");
			rebindDIPPublication();
			PVSSERROR("Could not create publication for "<<pubName<<" because of "<<de.what());
			} else {
				throw (new CPubGroupException());
			}
		}
	catch (...) {
		//Re -throw a known exception
		if (retryCounter < 30) {
			PVSSWARNING("Trial"<<retryCounter<<" to create pub. for "<<pubName<<" !");
			rebindDIPPublication();
			} else {
				PVSSERROR("Could not create pub. for "<<pubName<<". -- SHOULD RESTART API MANAGER.");
				throw (new CPubGroupException());
			}
		}
	return (result);
	}

