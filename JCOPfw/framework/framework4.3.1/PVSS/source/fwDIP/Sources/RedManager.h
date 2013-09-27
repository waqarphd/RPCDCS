// Declaration of our RedManager-class
#ifndef  REDMANAGER_H
#define  REDMANAGER_H
#ifdef WIN32
#pragma warning ( disable: 4786 )
#endif
#include   <DpIdentifier.hxx>
#include "DipApiResources.hxx"
#include "platformDependant.h"
#include <assert.h>

/**
* Manages the redundancy transition to and from Slit modes, 
* pure redundancy aspects are managed by the apimanager direcly.
*/

	//Forward declarations.
	class RedManager;
	class DipApiManager;

class SplitModeListener : public HotLinkWaitForAnswer {

private:

	RedManager * ptrRedManager;

public:

	SplitModeListener(RedManager * theRedManager):ptrRedManager(NULL)
	{
		assert(theRedManager != NULL);
		ptrRedManager = theRedManager;
	}

	/**
	  * Used to pick up the initial value of the list
	  */
	void hotLinkCallBack (DpMsgAnswer &answer);

	/**
	  * Used to pick up subsequent changes to the list.
	  */
	void hotLinkCallBack(DpHLGroup &group);


};

class SplitComListener : public HotLinkWaitForAnswer {

private:

	RedManager * ptrRedManager;

public:

	SplitComListener(RedManager * theRedManager):ptrRedManager(NULL)
	{
		assert(theRedManager != NULL);
		ptrRedManager = theRedManager;
	}

	/**
	  * Used to pick up the initial value of the list
	  */
	void hotLinkCallBack (DpMsgAnswer &answer);

	/**
	  * Used to pick up subsequent changes to the list.
	  */
	void hotLinkCallBack(DpHLGroup &group);

};

class RedManager {

private:

	DipApiManager * ptrDipApiManager; // Not owned.

	SplitModeListener * ptrSplitModeListener; // Owned.

	SplitComListener * ptrSplitComListener; // Owned.

	static bool splitMode;
	bool splitCom;

public:

	// Constructor
	RedManager(DipApiManager * theDipApiManager);

	//Accessors.

	SplitModeListener * getSplitModeListener();

	SplitComListener * getSplitComListener();

	void setSplitCom(bool theSplitCom);

	void setSplitMode(bool theSplitMode);

	static bool getSplitMode();

};

#endif //REDMANAGER_H
