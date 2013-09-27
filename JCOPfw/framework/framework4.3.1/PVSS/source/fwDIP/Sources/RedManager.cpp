#include "PVSSDIPAPIOptions.h"
#include "DipApiManager.hxx"
#include "RedManager.h"
//#include <iostream>

using namespace std;

bool RedManager::splitMode = false;

RedManager::RedManager(DipApiManager * theDipApiManager) :
ptrDipApiManager(NULL),
ptrSplitModeListener(NULL),
ptrSplitComListener(NULL),
splitCom(true) //This is required not to trigger anything when switching to split -mode.
{
	assert (theDipApiManager != NULL);
	ptrDipApiManager = theDipApiManager;
	ptrSplitModeListener = new SplitModeListener(this); // Owned.
	ptrSplitComListener = new SplitComListener(this); // Owned.
}

void RedManager::setSplitCom(bool theSplitCom) {
	splitCom = theSplitCom;
	if (splitMode == true) {
		// Ignore the isRedActive and System messages.
		// Use the DC information instead and trigger the processActive / passive.
		// Add a getter on this info to get it from the apimanager.
		if (splitCom == true) {
			//Then the dip process shall stop.
			PVSSLOG(ErrClass::PRIO_INFO, "This System is considered as PASSIVE DRIVER.");
			ptrDipApiManager->processIsActive(false);
		} else {
			//Then force the process to active.
			PVSSLOG(ErrClass::PRIO_INFO, "This System is considered as ACTIVE  DRIVER.");
			ptrDipApiManager->processIsActive(true);
		}
	} else {
		// Use the standard mechanism for the system messages and the IsRedActive.
		// Do nothiing particular here.
	}
}

void RedManager::setSplitMode(bool theSplitMode) {
	splitMode = theSplitMode;
	if (splitMode == true) {
		PVSSLOG(ErrClass::PRIO_INFO, "This System is starting in SPLIT MODE.");
		// Simply mention it, the activer driver is determined by the callbacks on the RedManager.
		// Force the RedManager to recompute the status.
		setSplitCom(splitCom);
	} else {
		//Running in redundancy mode, let the SYS messages determine the status.
		if (::Resources::isRedActive() == true)
		{
			PVSSLOG(ErrClass::PRIO_INFO, "This System is considered as HOT.");
			::DipApiResources::setActiveSystem(true);
			ptrDipApiManager->processIsActive(true);
		} else {
			PVSSLOG(ErrClass::PRIO_INFO, "This System is considered as STANDBY.");
			ptrDipApiManager->setIsActive(false);
			::DipApiResources::setActiveSystem(false);
		}
	}
}

bool RedManager::getSplitMode() {
	return (splitMode);
}

/**
* returns the pointer to the related listener.
*/
SplitModeListener * RedManager::getSplitModeListener() {
	return (ptrSplitModeListener);
}

/**
* returns the pointer to the related listener.
*/
SplitComListener * RedManager::getSplitComListener() {
	return (ptrSplitComListener);
}

/**
* Used to pick up the initial value of the list
*/
void SplitModeListener::hotLinkCallBack (DpMsgAnswer &answer){
	AnswerGroup * group =  answer.getFirstGroup();
	while (group != NULL){
	  AnswerItem*  answerItem = group->getFirstItem();
	  while (answerItem){
		  const IntegerVar  * valueSplitMode = (IntegerVar *)answerItem->getValuePtr();
		  //std::cout<<"Split Mode answer received the value = "<<*valueSplitMode<<endl;
  		  ptrRedManager->setSplitMode((bool)*valueSplitMode);
		  // It is not called directly because there is a risk that the Manaer is not ready a this time.
		  answerItem = group->getNextItem();
	  }
	  group = answer.getNextGroup();
	}
}

/**
* Used to pick up subsequent changes to the list.
*/
void SplitModeListener::hotLinkCallBack(DpHLGroup &group) {
	DpVCItem * answerItem =  group.getFirstItem();
	while (answerItem != NULL){
		const IntegerVar  * valueSplitMode = (IntegerVar *)answerItem->getValuePtr();
		//std::cout<<"Split Mode group received the value = "<<*valueSplitMode<<endl;
		ptrRedManager->setSplitMode((bool)*valueSplitMode);
		answerItem =  group.getNextItem();
	}
}

/**
* Used to pick up the initial value of the list
*/
void SplitComListener::hotLinkCallBack (DpMsgAnswer &answer){
	AnswerGroup * group =  answer.getFirstGroup();
	while (group != NULL){
	  AnswerItem*  answerItem = group->getFirstItem();
	  while (answerItem) {
		  const IntegerVar  * valueSplitCom = (IntegerVar *)answerItem->getValuePtr();
		  //std::cout<<"Split Com answer received the value = "<<*valueSplitCom<<endl;
		  // It is not called directly because there is a risk that the Manaer is not ready a this time.
		  ptrRedManager->setSplitCom((bool)*valueSplitCom);
		  answerItem = group->getNextItem();
	  }
	  group = answer.getNextGroup();
	}
}

/**
* Used to pick up subsequent changes to the list.
*/
void SplitComListener::hotLinkCallBack(DpHLGroup &group) {
	DpVCItem * answerItem =  group.getFirstItem();
	while (answerItem != NULL){
		const IntegerVar  * valueSplitCom = (IntegerVar *)answerItem->getValuePtr();
		//std::cout<<"Split Com group received the value = "<<*valueSplitCom<<endl;
		ptrRedManager->setSplitCom((bool)*valueSplitCom);
		answerItem =  group.getNextItem();
	}
}
