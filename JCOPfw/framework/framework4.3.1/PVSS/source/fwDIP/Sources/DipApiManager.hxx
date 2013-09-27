// Declaration of our DipApiManager-class
#ifndef  DIPAPIMANAGER_H
#define  DIPAPIMANAGER_H
#ifdef WIN32
#pragma warning ( disable: 4786 )
#endif
#include   <Manager.hxx>        // include/Manager
#include   <DpIdentifier.hxx>   // include/Basics
#include "DIPClientManager.h"
#include "dipPublicationManager.h"
#include "Browser.h"
#include "platformDependant.h"
#include "DIPVersion.h"
#include <queue>
#include <assert.h>
#include "DipDimErrorHandler.h"



/**
* acts as base for the types of changed data we can have, that we must process sequentially
*/
class CAPIJob{
public:
	virtual ~CAPIJob(){}

	virtual void process() = 0;
};




class CSubscriptionChange;

class DipApiManager : public Manager
{
  public:
    // Default constructor
	  DipApiManager();

    // Run the Manager
	  void run();

    // handle incoming hotlinks by group
    //void handleHotLink(const DpHLGroup &group);

	/// Gets the DIP interface
	static DipFactory & getDip(){
		return *dipFactory;
	}

	virtual void doReceive(SysMsg &msg);
	
	void queueDPEDataReadyForUpdate(DpIdValueList * list, const DipLong timeAsMilliSec);

	void processIsActive(bool status);

	void setIsActive(bool theIsActiveFlag) {
		isActive = theIsActiveFlag;
	}

	static void stopApiManager();

  private:
	/**
	  * Updates DPE's in the control manager - must only be called by CSubscriptionChange::process 
	  * as this will ensure the dpSetUpdate occurs at the correct time in relation to dispatch();
	  */
	friend class CJobFromDIP;
	void updatePVSSDPEs(DpIdValueList & list, const DipLong timeAsMilliSec);


    // our exit flag. The signal handler will set it to PVSS_TRUE
  	static PVSSboolean doExit;

    // callback from signal handler
    virtual void signalHandler(int sig);

	/// The dip interface for clients - NOT owned
	static DipFactory * dipFactory;

	//Tells whether the current Manager is active or not.
	bool isActive;

	//Not used yet, indicated if the initialization is finished or not (pubs. and subs.).
	bool isInitialized;

	CdipPublicationManager publicationManager;

	CdipClientManager subscriptionManager;

#ifdef LOCALBROWSETEST
	void testBrowser();
#endif
};

#endif
