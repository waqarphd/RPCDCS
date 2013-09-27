#include "PVSSDIPAPIOptions.h"
#include "DipApiManager.hxx"
#include "DipApiResources.hxx"
#include <HotLinkWaitForAnswer.hxx>   // include/Manager
#include <StartDpInitSysMsg.hxx>      // include/Messages
#include <DpMsgAnswer.hxx>            // include/Messages
#include <DpMsgHotLink.hxx>           // include/Messages
#include <DpHLGroup.hxx>              // include/Basics
#include <DpVCItem.hxx>               // include/Basics
#include <ErrHdl.hxx>                 // include/Basics
#include <ErrClass.hxx>               // include/Basics
#include <signal.h>
#include <string.h>
//#include <iostream>
//#include <iostream.h>
#include <stdarg.h>
#include <list>



#ifdef WIN32
#include <windows.h>
#else
#include <unistd.h>     // for usleep on Linux
#endif

#include "DIPClientManager.h"
#include "AnswerCallBackHandler.h"
#include "CdpeWrapper.h"
#include "DynVar.hxx"
#include "TextVar.hxx"
#include "dpeMappingTuple.h"
#include "dipManager.h"
#include "platformDependant.h"
#include "RedManager.h"



class PvssApiMgrDimErrorHandler:public DipDimErrorHandler{

	void handleException(int severity, int code, char *msg){

		string msgString = "DIM Error message : ";

		bool requestApiManagerExit = false;

		switch(severity)

		{

			case 0: msgString+="(INFO) ";

				break;

			case 1: msgString+="(WARNING) ";

				break;

			case 2: msgString+="(ERROR) ";

				break;

			case 3: msgString+="(FATAL) ";
				// DIP-40
				// Exit upon receiving a FATAL message from DIM, no point
				// keeping on executing anyway.
				// FATAL is used to signal :
				//   * duplicate DIM service definitions (the DIM name server will refuse to expose the publication)
				//   * DNS host refusing the connection
				//   * DNS requests that the client/server be killed (e.g. DID action)
				// Trust me... it's better we stop it here.
				requestApiManagerExit = true;
				break;

		}

		msgString+= msg;

		PVSSERROR(msgString);

		if(requestApiManagerExit == true){
			DipApiManager::stopApiManager();
		  }

	  }


	};

/**
* Holds data from PVSS that must be processed by the associated dipManagers
*/
class CJobFromPVSS:public CAPIJob{
private:
	CdipManager & manager;

	/**
	* Owned ! been 'cut' out of the list
	*/
	VariablePtr data;

public:
	/**
	* This owns the past params
	*/
	CJobFromPVSS(CdipManager & man, VariablePtr d):
	  manager(man), data(d){
		  };

	  ~CJobFromPVSS(){
		  delete data;
		  }

	  void process(){
		  manager.dataChanged(data);
		  }
	};


/**
* Used to store data from DIP that is destined for PVSS
* All these jobs as processed by the DipApiManager since there is no specialised processing
* - the data just needs to be written out to the event manager.
*/
class CJobFromDIP:public CAPIJob{
private:
	/*The API manager will do the processing*/
	DipApiManager & manager;

	/**
	* Owned
	*/
	DpIdValueList * data;


	/**
	* Time to associated with the data being sent
	*/
	DipLong timeAsMilliSec;

public:
	/**
	* This owns the past params
	*/
	CJobFromDIP(DipApiManager & man, DpIdValueList* d, DipLong ts):
	  manager(man), data(d), timeAsMilliSec(ts){
		  };

	  ~CJobFromDIP(){
		  delete data;
		  }

	  void process(){
		  //MD Will update PVSS only if in "active" mode, otherwise does nothing.
		  if (manager.isActive) {
			  //PVSSINFO("The DPE will be updated as we are running in active mode.");
			  manager.updatePVSSDPEs(*data, timeAsMilliSec);
			  } else {
				  //Do nothing.
				  PVSSINFO("The DPE will not be updated as we are running in passive mode.");
			  }
		  }
	};

class AllSubscriptionRefreshListener : public HotLinkWaitForAnswer
{
	private:
		CdipClientManager & m_subscriptionManager;
		DpIdentifier m_allSubscriptionRefreshDpOriginalId;
    public:
		AllSubscriptionRefreshListener(	CdipClientManager &dipClientManager):
			  m_subscriptionManager(dipClientManager){}
		void hotLinkCallBack(DpMsgAnswer &answer){
		   AnswerGroup * group =  answer.getFirstGroup();
			while (group != NULL){
				AnswerItem*  answerItem = group->getFirstItem();

				while (answerItem){
					VariablePtr changedData = answerItem->getValuePtr();
					if(changedData->isTrue()){
						m_subscriptionManager.requestAnySubscriptionResends(true);
						BitVar ackRefresh(PVSS_FALSE);
						Manager::dpSet(m_allSubscriptionRefreshDpOriginalId, ackRefresh);
					}
					answerItem = group->getNextItem();
					}

				group = answer.getNextGroup();
			}
			
		}

		void setRefreshAllSubscriptionOriginalID(DpIdentifier allSubscriptionRefreshOriginalDpId){
			m_allSubscriptionRefreshDpOriginalId = allSubscriptionRefreshOriginalDpId;
		}

protected:
		void hotLinkCallBack(DpHLGroup &group){
			DpVCItem * item =  group.getFirstItem();
			while (item != NULL){
				VariablePtr changedData = item->getValuePtr();
				if(changedData->isTrue()){
					m_subscriptionManager.requestAnySubscriptionResends(true);
					BitVar ackRefresh(PVSS_FALSE);
					Manager::dpSet(m_allSubscriptionRefreshDpOriginalId, ackRefresh);
				}
				item =  group.getNextItem();
			}

		}

};

/**
* listens on one or more DPE's and queues received data, to be processed later by the approiate manager
*
*/
class DPEChangeListener : public HotLinkWaitForAnswer
	{
	private:
		/**
		* The manager that is to be used to process the received data.
		*/
		CdipManager & manager;

		/**
		* Only handle changes after initial startup
		*/
		const bool ignoreInitialValues;

	public:

		DPEChangeListener(CdipManager &theManager, bool ignoreInitial = false):manager(theManager), ignoreInitialValues(ignoreInitial){}

		/**
		* Used to pick up the initial value of the list
		*/
		void hotLinkCallBack (DpMsgAnswer &answer){
			PVSSTRACE(TRACEIN,"ConfigListChangeListener::hotLinkCallBack (initial)");
			if (ignoreInitialValues){
				PVSSINFO("Ignoring initial values");
				}else{
					AnswerGroup * group =  answer.getFirstGroup();
					while (group != NULL){
						AnswerItem*  answerItem = group->getFirstItem();

						while (answerItem){
							VariablePtr changedData = answerItem->cutValuePtr();
							addToJobQueue(new CJobFromPVSS(manager, changedData));
							answerItem = group->getNextItem();
							}

						group = answer.getNextGroup();
						}
				}
			PVSSTRACE(TRACEOUT,"ConfigListChangeListener::hotLinkCallBack (initial)");
			}

		/**
		* Used to pick up subsequent changes to the list.
		*/
		void hotLinkCallBack(DpHLGroup &group){
			PVSSTRACE(TRACEIN,"ConfigListChangeListener::hotLinkCallBack");
			DpVCItem * item =  group.getFirstItem();
			while (item != NULL){
				VariablePtr changedData = item->cutValuePtr();
				addToJobQueue(new CJobFromPVSS(manager, changedData));
				item =  group.getNextItem();
				}

			PVSSTRACE(TRACEOUT,"ConfigListChangeListener::hotLinkCallBack");
			}

		/**
		* List of things that need doing!
		*/
		static std::list<CAPIJob *> jobQueue;

		/// Used to prevent dispatch and dpSet interfering
		static SMutex jobQueueLock;


		/**
		* Job is now owned by job queue
		*/
		static void addToJobQueue(CAPIJob * job){
			//PVSSTRACE(TRACEIN,"addToJobQueue(CAPIJob * job)");
			SmutexGuard guard(jobQueueLock);
			jobQueue.push_back(job);
			//PVSSTRACE(TRACEOUT,"addToJobQueue(CAPIJob * job)");
			}

		/**
		* Caller owns returned job
		*/
		static CAPIJob * getJobFromQueue(){
			//PVSSTRACE(TRACEIN,"getJobFromQueue()");
			SmutexGuard guard(jobQueueLock);

			if (jobQueue.size() == 0){
				return NULL;
				}

			CAPIJob * job = jobQueue.front();
			jobQueue.pop_front();
			//PVSSTRACE(TRACEOUT,"getJobFromQueue()");
			return job;
			}
	};

std::list<CAPIJob *> DPEChangeListener::jobQueue;
SMutex DPEChangeListener::jobQueueLock("jobQueueLock");

// -------------------------------------------------------------------------
// Our manager class
PVSSboolean DipApiManager::doExit = PVSS_FALSE;

DipFactory * DipApiManager::dipFactory = NULL;

PvssApiMgrDimErrorHandler* m_pvssApiMgrDimErrorHandler;



// The constructor defines Manager type (API_MAN) and Manager number
DipApiManager::DipApiManager():
Manager(ManagerIdentifier(API_MAN, Resources::getManNum())),
isInitialized(false),
publicationManager(*this),
subscriptionManager(*this)
    {
	}

#ifdef LOCALBROWSETEST
bool checkNameType(SString &name, int type,
				   std::vector<SString> names, std::vector<int> types){

					   for (int i = 0; i < names.size(); i++){
						   if (names[i] == name){
							   if (types[i] == type){
								   return true;
								   }
							   else{
								   return false;
								   }
							   }
						   }

					   return false;
	}

void DipApiManager::testBrowser()
	{
	printf("*************** WARNING - IN LOCAL BROWSE TEST MODE !!!************\n");
	std::vector<SString> fieldNames;
	std::vector<int> fieldTypes;
	std::vector<SString> childNames;
	std::vector<int> childTypes;
	printf("T1 .... ");
	SString startPoint="/";
	int nodeType = browserManager.getNodeInfo(startPoint,
		fieldNames,
		fieldTypes,
		childNames,
		childTypes);
	assert(nodeType == 1);
	assert(fieldNames.size() == 0);
	assert(fieldTypes.size() == 0);
	assert(childNames.size() == 2);
	assert(childTypes.size() == 2);
	assert(checkNameType(SString("t1"), 2, childNames, childTypes));
	assert(checkNameType(SString("test"), 3, childNames, childTypes));
	printf("passed\n");


	printf("T2 .... ");
	browserManager.clearNameSpace();
	startPoint="/test/t2";
	nodeType = browserManager.getNodeInfo(startPoint,
		fieldNames,
		fieldTypes,
		childNames,
		childTypes);
	assert(nodeType == 2);
	assert(fieldNames.size() == 3);
	assert(fieldTypes.size() == 3);
	assert(childNames.size() == 0);
	assert(childTypes.size() == 0);
	assert(checkNameType(SString("f1"), 1, fieldNames, fieldTypes));
	assert(checkNameType(SString("f2"), 1, fieldNames, fieldTypes));
	assert(checkNameType(SString("f3"), 3, fieldNames, fieldTypes));
	printf("passed\n");


	printf("T3 .... ");
	browserManager.updateNameSpace();
	startPoint="/test/dect1/Lkr";
	nodeType = browserManager.getNodeInfo(startPoint,
		fieldNames,
		fieldTypes,
		childNames,
		childTypes);
	assert(nodeType == 1);
	assert(fieldNames.size() == 0);
	assert(fieldTypes.size() == 0);
	assert(childNames.size() == 2);
	assert(childTypes.size() == 2);
	assert(checkNameType(SString("pos1"), 2, childNames, childTypes));
	assert(checkNameType(SString("pos2"), 2, childNames, childTypes));
	printf("passed\n");


	printf("T4 .... ");
	browserManager.updateNameSpace();
	startPoint="/test";
	nodeType = browserManager.getNodeInfo(startPoint,
		fieldNames,
		fieldTypes,
		childNames,
		childTypes);
	assert(nodeType == 3);
	assert(fieldNames.size() == 4);
	assert(fieldTypes.size() == 4);
	assert(childNames.size() == 3);
	assert(childTypes.size() == 3);
	assert(checkNameType(SString("x"), 1, fieldNames, fieldTypes));
	assert(checkNameType(SString("y"), 1, fieldNames, fieldTypes));
	assert(checkNameType(SString("z"), 1, fieldNames, fieldTypes));
	assert(checkNameType(SString("t"), 2, fieldNames, fieldTypes));
	assert(checkNameType(SString("t1"), 2, childNames, childTypes));
	assert(checkNameType(SString("t2"), 2, childNames, childTypes));
	assert(checkNameType(SString("dect1"), 3, childNames, childTypes));
	printf("passed\n");


	printf("T5 .... ");
	startPoint="/noBranch";
	nodeType = browserManager.getNodeInfo(startPoint,
		fieldNames,
		fieldTypes,
		childNames,
		childTypes);
	assert(nodeType == 0);
	assert(fieldNames.size() == 0);
	assert(fieldTypes.size() == 0);
	assert(childNames.size() == 0);
	assert(childTypes.size() == 0);
	printf("passed\n");


	printf("T6 .... ");
	startPoint="/test/dect1/";
	nodeType = browserManager.getNodeInfo(startPoint,
		fieldNames,
		fieldTypes,
		childNames,
		childTypes);
	assert(nodeType == 3);
	assert(fieldNames.size() == 0);
	assert(fieldTypes.size() == 0);
	assert(childNames.size() == 1);
	assert(childTypes.size() == 1);
	assert(checkNameType(SString("Lkr"), 1, childNames, childTypes));
	printf("passed\n");


	printf("T7 .... ");
	startPoint="";
	nodeType = browserManager.getNodeInfo(startPoint,
		fieldNames,
		fieldTypes,
		childNames,
		childTypes);
	assert(nodeType == 1);
	assert(fieldNames.size() == 0);
	assert(fieldTypes.size() == 0);
	assert(childNames.size() == 2);
	assert(childTypes.size() == 2);
	assert(checkNameType(SString("t1"), 2, childNames, childTypes));
	assert(checkNameType(SString("test"), 3, childNames, childTypes));
	printf("passed\n");
	}
#endif

class CdpePublisherNameWrapper:public CsimpleDPEWrapper{
protected:
	/// detemines whether we connect to attributes from online or original
	const CharString  getDPESourceName()const{
		return "online";
		}


	const CharString getValidAttribName() const{
		return "invalid";
		}

public:
	/**
	* obtains dpid for original value of pdeName
	* @param dpeName name of PVSS DPE (should be a primitive) - not terminated with .
	*/
	CdpePublisherNameWrapper(const CharString & dpeName):
	  CsimpleDPEWrapper(dpeName){

		  }

	  ~CdpePublisherNameWrapper(){
		  }


	  bool getPublisherName(CharString &publisherName){
		  // Address config exists - read it
		  const int numProperties = 1;
		  CharString addConfigNames = DipApiResources::getPublisherNameDPE();
		  DpIdentList dpList;
		  if (makeListOfDPEs(dpList, &addConfigNames, numProperties) != numProperties){
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
		  if (responsePair == NULL){
			  return false;
			  }

		  const TextVar * value = (TextVar *)responsePair->getValuePtr();
		  if (value == NULL){
			  PVSSERROR("DPE " << (const char *)getName() <<" has empty reference");
			  return false;
			  }

		  publisherName = value->getString();
		  return true;
		  }

	};

// Run our demo manager
void DipApiManager::run()
	{
#ifdef LOCALBROWSETEST
	testBrowser();
	exit(1);
#endif // LOCALBROWSETEST


	PVSSINFO("DipApiManager thread running");
	PVSSINFO("DIP Library Version '" << DipVersion::getDipVersion() <<"'" );
	long sec, usec;

	// First connect to Data manager.
	// We want Typecontainer and Identification so we can resolve names
	// This call succeeds or the manager will exit
	connectToData(StartDpInitSysMsg::TYPE_CONTAINER | StartDpInitSysMsg::DP_IDENTIFICATION);

	// While we are in STATE_INIT we are initialized by the Data manager
	while (getManagerState() == STATE_INIT)
		{
		// Wait max. 1 second in select to receive next message from data.
		// It won't take that long...
		sec = 1;
		usec = 0;
		dispatch(sec, usec);
		}

	// We are now in STATE_ADJUST and can connect to Event manager
	// This call will succeed or the manager will exit
	connectToEvent();

	// We are now in STATE_RUNNING. This is a good time to connect
	// to our Datapoints

	//=============================
	// Handling split stuff aspects
	//=============================

	// MD Here is created the RedManager to handle the split stuff.
	RedManager theRedManager(this);
	DpIdentifier theSplitModeIndentifier;
	DpIdentifier theSplitComIndentifier;
	if (Manager::getId(DipApiResources::getSplitModeSourceName(), theSplitModeIndentifier) == PVSS_FALSE
		|| Manager::getId(DipApiResources::getSplitComSourceName(), theSplitComIndentifier) == PVSS_FALSE)
		{
		PVSSWARNING("Could not access the split information at : " <<(const char *)DipApiResources::getSplitModeSourceName() << " or " << (const char *)DipApiResources::getSplitComSourceName());
		PVSSLOG(ErrClass::PRIO_INFO,"Assuming split mode will not be used at all.");
		} else {
			// Subscribe to the DPE split config to pick up the initial value and any changes
			PVSSINFO("Subscribed to : " <<(const char *)DipApiResources::getSplitModeSourceName());
			PVSSINFO("Subscribed to : " <<(const char *)DipApiResources::getSplitComSourceName());
			//Connecting the redundancy manager.
			Manager::dpConnect(theSplitComIndentifier,theRedManager.getSplitComListener());
			Manager::dpConnect(theSplitModeIndentifier,theRedManager.getSplitModeListener());
		}

	//=============================
	// DIP
	//=============================

	if (dipFactory == NULL){
		CdpePublisherNameWrapper dpePubName(DipApiResources::getPublisherNameDPE());
		PVSSINFO("Creating DIP publisher " << dpePubName.getName());
		CharString publisherName = "fake";
		bool result = dpePubName.getPublisherName(publisherName);
		if (result == false){
			PVSSERROR("Publisher name for DIP API is not defined");
			return;
			} else {
				//MD : Now appending a random value to the publisherName based on the current time.
				// Use DIP for that purpose ;)
				DipTimestamp aTimeStamp;
				long someRandomness = aTimeStamp.getAsMillis();
				publisherName+=CharString((int)someRandomness);
			}
		dipFactory = Dip::create(publisherName);

		///////////
		// DIP-40 Adding a PVSS aware DIM error handler
        PVSSINFO("Registering DIM Error Handler");
		m_pvssApiMgrDimErrorHandler = new PvssApiMgrDimErrorHandler;
		Dip::addDipDimErrorHandler(m_pvssApiMgrDimErrorHandler);
		///////////

		//Now checking whether a specific DNS shall be used:
		if ( true != DipApiResources::getDNSName().empty()) {
			PVSSLOG(ErrClass::PRIO_INFO, "Connecting to the DNS(s) specified on the command line: " << DipApiResources::getDNSName());
			dipFactory->setDNSNode(DipApiResources::getDNSName().c_str());
			} else {
				//Do nothing.
			}
    }

	// instantiate our managers - they do'nt need to be visable at the
	// class level and some need access to 'dipFactory'- hence their
	// declaration here
	BrowserManager browserManager(*this);
	//MD owned from now, see the constructor...
	//CdipPublicationManager publicationManager(*this);
	//MD owned from now, see the constructor...
	//CdipClientManager clientManager(*this);
	/***************************************************
	Configure Publication/Subscription/browser managers
	****************************************************/

	// set up client manager
	DPEChangeListener clientConfigChangeListener(subscriptionManager);
    AllSubscriptionRefreshListener refreshAllSubscriptionsListener(subscriptionManager);

	if (DipApiResources::getClientSourceName().len() == 0){
		PVSSWARNING("DIP API manager not configured to be client");
		}
	else {
		DpIdentifier cpClientList;
		DpIdentifier refreshAllSubscriptionsID;
		DpIdentifier refreshAllSubscriptionsOriginalID;
		if ( (Manager::getId(DipApiResources::getClientSourceName(), cpClientList) == PVSS_FALSE)	)
			{
			PVSSERROR("Cannot get DPE id for client Source " <<
				(const char *)DipApiResources::getClientSourceName());
			}
		else if ( (Manager::getId(DipApiResources::getRefreshAllSubscriptionsOnlineValueName(),refreshAllSubscriptionsID) == PVSS_FALSE) ||
			      (Manager::getId(DipApiResources::getRefreshAllSubscriptionsOriginalValueName(),refreshAllSubscriptionsOriginalID) == PVSS_FALSE) )
			{
			PVSSERROR("Cannot get DPE id for RefreshAllSubscriptions DPE " <<
				(const char *)DipApiResources::getRefreshAllSubscriptionsOnlineValueName());
			}
		else {
			//Subscribe to the DPE config name list to pick up the initial value and any changes
			Manager::dpConnect(cpClientList,&clientConfigChangeListener, false);
            refreshAllSubscriptionsListener.setRefreshAllSubscriptionOriginalID(refreshAllSubscriptionsOriginalID);
			// Subscribe to the DPE used to request a refresh of all subscriptions
			Manager::dpConnect(refreshAllSubscriptionsID, &refreshAllSubscriptionsListener, false);
			}
		}


	// Set up publication manager
	DPEChangeListener pubConfigChangeListener(publicationManager);
	if (DipApiResources::getPubSourceName().len() == 0){
		PVSSWARNING("DIP API manager not configured to be publisher");
		}
	else {
		DpIdentifier cpPubList;
		if (Manager::getId(DipApiResources::getPubSourceName(), cpPubList) == PVSS_FALSE)
			{
			PVSSERROR("Can not get id for pub config Source " <<
				(const char *)DipApiResources::getPubSourceName());
			}

		// Subscribe to the DPE config name list to pick up the initial value and any changes
		Manager::dpConnect(cpPubList,&pubConfigChangeListener, false);
		}

	// set up browser manager
	DPEChangeListener browseRequestListener(*browserManager.browseRequestHandler, true);
	DPEChangeListener browseRefreshListener(*browserManager.updateBrowseSpaceRequestHandler, true);
	if ((DipApiResources::getBrowseRefreshName().len()			 == 0) ||
		(DipApiResources::getBrowseStartPointName().len()		 == 0) ||
		(DipApiResources::getBrowseFieldNameResponseName().len() == 0) ||
		(DipApiResources::getBrowseFieldTypeResponseName().len() == 0) ||
		(DipApiResources::getBrowseChildNameResponseName().len() == 0) ||
		(DipApiResources::getBrowseChildTypeResponseName().len() == 0) ||
		(DipApiResources::getBrowseCompleteResponseName().len()	 == 0) ||
		(DipApiResources::getRefreshActionStatusResponseName().len()== 0)){
			PVSSWARNING("DIP API manager not configured to browse");
		}
	else {
		DpIdentifier browseRefreshDpID;
		DpIdentifier browseStartPointDpID;
		DpIdentifier browseFieldNameResponseDpID;
		DpIdentifier browseFieldTypeResponseDpID;
		DpIdentifier browseChildNameResponsehDpID;
		DpIdentifier browseChildTypeResponseDpID;
		DpIdentifier browseCompleteResponseDpID;
		DpIdentifier refreshActionStatusID;

		CharString s = DipApiResources::getBrowseRefreshName();

		if ((Manager::getId(DipApiResources::getBrowseRefreshName(),			browseRefreshDpID) == PVSS_FALSE) ||
			(Manager::getId(DipApiResources::getBrowseStartPointName(),			browseStartPointDpID) == PVSS_FALSE) ||
			(Manager::getId(DipApiResources::getBrowseFieldNameResponseName(),	browseFieldNameResponseDpID) == PVSS_FALSE) ||
			(Manager::getId(DipApiResources::getBrowseFieldTypeResponseName(),	browseFieldTypeResponseDpID) == PVSS_FALSE) ||
			(Manager::getId(DipApiResources::getBrowseChildNameResponseName(),	browseChildNameResponsehDpID) == PVSS_FALSE) ||
			(Manager::getId(DipApiResources::getBrowseChildTypeResponseName(),	browseChildTypeResponseDpID) == PVSS_FALSE) ||
			(Manager::getId(DipApiResources::getBrowseCompleteResponseName(),	browseCompleteResponseDpID) == PVSS_FALSE)  ||
			(Manager::getId(DipApiResources::getRefreshActionStatusResponseName(),refreshActionStatusID) == PVSS_FALSE)){
				PVSSERROR("DIP API manager not get DPE ids needed to configure DIP browser");
			} else {
				browserManager.browseRequestHandler->setResponseIds(
					browseFieldNameResponseDpID, browseFieldTypeResponseDpID,
					browseChildNameResponsehDpID,browseChildTypeResponseDpID,
					browseCompleteResponseDpID);
				browserManager.updateBrowseSpaceRequestHandler->setResponseIds(refreshActionStatusID);

				Manager::dpConnect(browseStartPointDpID,&browseRequestListener, false);
				Manager::dpConnect(browseRefreshDpID,   &browseRefreshListener, false);

			}
		}

	// MAIN LOOP process outstanding jobs, then look for more (dispatch)
	while (1)
		{
		// Exit flag set by API Manager or connection to the event manager is lost.
		// Exits if connection to the event manager is lost.
		if (true == doExit || false == isEvConnOpen())
			{
				PVSSTRACE(TRACEOUT, "Exiting API manager loop gracefully.");
				return; 
			}

		// Process any pending jobs of the API manager.
		CAPIJob * job = NULL;
		while(job = DPEChangeListener::getJobFromQueue()) {
			job->process();
			delete job;
		}


		// now dispatch any data generated by the jobs and get new jobs from PVSS (DPE changes from PVSS)
		sec = 0;
		usec = 1000;
		dispatch(sec, usec);


#ifdef TEST_NODIP
		static int i = 0;
		static int q = -1;
		CharString dipPubName =  "dip.test_struct";
		CdipSubscription * sub = clientManager.getPub(dipPubName);


		if (sub){
			int intArray[3] = {i,i+1,i+2};
			DipData value;
			value.setFloat("float",i++);
			value.setIntArray("intarray",intArray, sizeof(intArray)/sizeof(int));
			value.setDataQuality(q);
			++q;
			if (q>2){
				q = -1;
				}
			sub->handleMessage(NULL, value);
			} else {
				PVSSERROR("Could not find %s" << (const char *)dipPubName);
			}
#endif
		} //while(1) loop
	}

void DipApiManager::stopApiManager(){
	PVSSFATAL("Now stopping DIP API Manager");
	DipApiManager::doExit = PVSS_TRUE;
}

void DipApiManager::queueDPEDataReadyForUpdate(DpIdValueList * listOdDpId, const DipLong timeAsMilliSec){
	//PVSSTRACE(TRACEIN, "DipApiManager::queueDPEDataReadyForUpdate");
	DPEChangeListener::addToJobQueue(new CJobFromDIP(*this, listOdDpId, timeAsMilliSec));
	//PVSSTRACE(TRACEOUT, "DipApiManager::queueDPEDataReadyForUpdate");
	}

void DipApiManager::updatePVSSDPEs(DpIdValueList & listOdDpId, const DipLong timeAsMilliSec) {
	//PVSSTRACE(TRACEIN, "DipApiManager::updatePVSSDPEs");
	const BC_CTime realBCTime(timeAsMilliSec / 1000);  // gives me time in seconds
	TimeVar realPvssFormatTime(realBCTime,timeAsMilliSec % 1000);

	if (!Manager::dpSetTimed(realPvssFormatTime, listOdDpId)){
		DpVCItem* item = listOdDpId.getFirstItem();
		int i=0;
		while (item){
			const DpIdentifier& dpe = item->getDpIdentifier();
			CharString dpeName;
			Manager::getLIName(dpe,dpeName);
			PVSSWARNING(i++ << " " << dpeName);
			if (dpeName == "dist_1:dipScalingTest_2.intValue:_original.._exp_inv"){
				int flag = ((BitVar*)item->getValuePtr())->getValue();
				PVSSWARNING("_exp_inv = " << flag);
				}

			item = listOdDpId.getNextItem();
			}
		}
	//PVSSTRACE(TRACEOUT, "DipApiManager::updatePVSSDPEs");
	}

// Receive Signals.
// We are interested in SIGINT and SIGTERM.
void DipApiManager::signalHandler(int sig)
	{
	PVSSTRACE(TRACEIN,"DipApiManager::signalHandler");
	if ( (sig == SIGINT) || (sig == SIGTERM) ){
		DipApiManager::doExit = PVSS_TRUE;
		}else{
			Manager::signalHandler(sig);
		}
	PVSSTRACE(TRACEOUT,"DipApiManager::signalHandler");
	}

/**
* This method receives system messages, including the redundancy ones.
* Here is the interest, if this kind of message is received, then the active/passive state i
* immediatly processed
*/
void DipApiManager::doReceive( SysMsg &sysMsg )
	{
	std::string messageDetails = "Received a System message:";
	messageDetails+=SysMsg::getSysMsgTypeName(sysMsg.getSysMsgType());
	//Call the original method so that messages are forwarded.
	Manager::doReceive( sysMsg );

	switch ( sysMsg.getSysMsgType() )
		{
		case REDUNDANCY_SYS_MSG :
			{
			// messages come from Data and Event. Data is ignored
			// only Event can set the Status
			if ( sysMsg.getSource() != Manager::eventId )
				break;
			if (RedManager::getSplitMode() == true)
				break;

			// A Redu-SysMsg has sub-types.
			// see enum RedundancySubType
			switch ( ( RedundancySubType ) sysMsg.getSysMsgSubType() )
				{
				case REDUNDANCY_ACTIVE :   // Here we become active
					{
					PVSSINFO("Received a redundancy system message: REDUNDANCY_ACTIVE.");
					this->processIsActive(true);
					break;
					}
				case REDUNDANCY_PASSIVE :  // Here we are passive
					{
					PVSSINFO("Received a redundancy system message: REDUNDANCY_PASSIVE.");
					this->processIsActive(false);
					break;
					}
				case REDUNDANCY_REFRESH :  
					{
					PVSSINFO("Received a redundancy system message: REDUNDANCY_REFRESH.");
					break;
					}
				case REDUNDANCY_DISCONNECT :  
					{
					PVSSINFO("Received a redundancy system message: REDUNDANCY_DISCONNECT.");
					break;
					}
				case DM_START_TOUCHING :  
					{
					PVSSINFO("Received a redundancy system message: DM_START_TOUCHING.");
					break;
					}
				case DM_STOP_TOUCHING :  
					{
					PVSSINFO("Received a redundancy system message: DM_STOP_TOUCHING.");
					break;
					}

				default : ;
				}
			break;
			}

		default : ;
		}
	}

/**
* Process the active/passive redundancy state change.
*/
void DipApiManager::processIsActive(bool status) {
	PVSSINFO("processIsActive with status = "<<status<<" and isActive = "<<isActive);
	// by default this is not set at all.
	if ( (isActive == true && status == true ) || (isActive == false && status == false ) ) {
		//Do nothing
		} else if (isActive == false && status == true ) {
			isActive = true;
			::DipApiResources::setActiveSystem(true);
#ifdef WIN32
			// Sleep take milli seconds
			// Windows NT/XP variant ::Sleep( sleeptime * oneThousand );
			::Sleep(5000l);
#else
			// usleep takes microseconds on Linux platform.
			::usleep(5000000l);
#endif  // WIN32
			//Just got activated, bind or re -bind the DIP publications of every CdipPubGroup.
			// And re-subscribe the current stuff if applicable.
			try{

				if (!publicationManager.rebindAllDIPPublication()) {
					PVSSERROR("Some DIP publications were NOT rebinded.");
					} else {
						PVSSLOG(ErrClass::PRIO_INFO, "Activation:  DIP publications are now *connected*.");
					}

				if (!subscriptionManager.rebindAllDIPSubscription()) {
					PVSSERROR("Some DIP subscriptions were NOT rebinded.");
					} else {
						PVSSLOG(ErrClass::PRIO_INFO, "Activation: DIP subscriptions are now *connected*.");
					}
				}
			catch (CPubGroupException &){
				PVSSFATAL("Failed to (re)bind all publication groups, refused by DIP, -- SHOULD RESTART API MANAGER");
				}
			catch (...) {
				PVSSFATAL("Failed to (re)bind all publications, -- SHOULD RESTART API MANAGER");
				}
			//Activate the copy of DIP data into the DPEs.
		} else if (isActive == true && status == false ) {
			isActive = false;
			::DipApiResources::setActiveSystem(false);
			//Just got passivated
			//Desactivate the curent DIP publications.
			//Destroy all the DIP publications of every CdipPubGroup.
			//Unsubscribe all the DIP subscriptions.
			try{
				if (!publicationManager.destroyAllDIPPublication()) {
					PVSSERROR("Could not destroy DIP publications, passivation failed.");
					} else {
						PVSSINFO("Passivation of DIP publications is a success.");
						//PVSSLOG(ErrClass::PRIO_INFO, "Passivation of DIP publications is a success.");
					}
				if (!subscriptionManager.destroyAllDIPSubscription()) {
					PVSSERROR("Could not destroy DIP subscriptions, passivation failed.");
					} else {
						PVSSINFO("Passivation of DIP subscriptions is a success.");
						//PVSSLOG(ErrClass::PRIO_INFO, "Passivation of DIP subscriptions is a success.");
					}
				}
			catch (CPubGroupException &){
				PVSSFATAL("Failed to destroy all publications/subscriptions, refused by DIP, -- SHOULD RESTART API MANAGER");
				}
			catch (...) {
				PVSSFATAL("Failed to destroy all publications/subscriptions, -- SHOULD RESTART API MANAGER");
				}
			//Deactivate the copy of DIP data into the DPEs.
			PVSSLOG(ErrClass::PRIO_INFO, "Passivation:  DIP publications are now *disconnected*.");
			PVSSLOG(ErrClass::PRIO_INFO, "Passivation: DIP subscriptions are now *disconnected*.");
			//Done by checking the isActive flag dynamically.
			} else {
				//Do nothing, there is no "else" actually...
			}
	}

