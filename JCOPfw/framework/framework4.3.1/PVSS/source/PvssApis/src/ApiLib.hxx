#include <Manager.hxx>
#include <ManagerIdentifier.hxx>
#include <StartDpInitSysMsg.hxx>
#include <TextVar.hxx>
#include <CharVar.hxx>
#include <IntegerVar.hxx>
#include <UIntegerVar.hxx>
#include <FloatVar.hxx>
#include <TimeVar.hxx>
#include <PVSSTime.hxx>
#include <DpTypeContainer.hxx>
#include <WaitForAnswer.hxx>
#include <DpMsgAnswer.hxx>
#include <DpMsgHotLink.hxx>
#include <DpMsgComplexVC.hxx>
//#include <DpConfig.hxx>
#include <AttributeNrs.hxx>

#include <dis.hxx>
#ifndef USE_OLD_STYLE_CPP
#include <iostream>
using namespace std;
#endif
/*
#define MAX_HASH_ENTRIES 2000
*/
#define MAX_HASH_ENTRIES 1000

typedef unsigned char bit;
typedef unsigned long bitset;

typedef enum ATTR_TYPES {ATTR_VALUE, ATTR_USER8, ATTR_USER7, ATTR_USER6, ATTR_USER5, ATTR_USER1, ATTR_INV};

class HASHItem : public DLLItem
{
	char *theKey;
public:
	HASHItem();
	~HASHItem();
	void setKey(char *key);
	char *getKey();
};

class HASHTable
{
public:
	void add(char *key, HASHItem *ptr);
	void remove(char *key, HASHItem *ptr);
	void removeAll();
	int findN(char *key);
	HASHItem *find(char *key);
	HASHItem *getHead();
	HASHItem *getNext();
	void removeAtIndex(int index, HASHItem *ptr);
	int getCurrentIndex();
	int getNItems();
	HASHTable() {nItems = 0;memset(hashItems,0,MAX_HASH_ENTRIES*sizeof(int));};
private:
	DLList hashTable[MAX_HASH_ENTRIES];
	HASHItem *getNextHead();
	int hashFunction(char *key, int max);
	HASHItem *currItem; 
	int currIndex;
	int nItems;
	int hashItems[MAX_HASH_ENTRIES];
};

class DPSetHASHItem : public HASHItem
{
//	Variable *itsValue;
//	DpIdentifier *itsDpId;
	DpVCItem *itsIdValue;
	int itsSendFlag;
public:
	DPSetHASHItem(DpIdentifier &dpId, Variable &value, int sendFlag);
	~DPSetHASHItem();
	VariablePtr getValuePtr();
	DpIdentifier &getDpId();
	int getSendFlag();
	void setSendFlag(int sendFlag);
};

class DP;
class DPItem;
/*
class DPHashTable
{
public:
//	DPHashTable();
	void add(char *name, DP *ptr);
	void remove(char *name, DP *ptr);
	DP *find(char *name);
	DPItem *findItem(char *name);
private:
	DLList dpHashTable[MAX_HASH_ENTRIES];
	int hashFunction(char *name, int max);
};
*/

class ApiManager : public Manager
{
public:
	ApiManager();
	
	static PVSSboolean doExit;
	static ApiManager *myself;
	virtual void manInitialize() {};
	virtual void manExecute() {};
	virtual void manExit() {};
	virtual void gotDpValues() {};
	static void print_date_time_detailed();
	int get_millis();
	void manStart() {run();};
//	DPItem *getDPItem(char *dp);
//	DLList DPList;
//	DPHashTable DPTable;
	void setDispatchFlag() {dispatchFlag = 10; };
	void setDispatchRate(int milisecs) {dispatchRate = milisecs; };
	int getDispatchRate() {return dispatchRate; };
	int clearDPSetList();
	int addDPSetItem(DpIdentifier &dpId, Variable &value, char *dpName);
	int sendDPSetList();
	int collectingDPs() { if(DPSetList) return 1; else return 0; }
	void printTable();
	int myDpSet(DpIdValueList &dpIdValueList);
	void addDPItem(DPItem *item, char *name);
	DPItem *findDPItem(char *name);
//	DPItem *findDPItemById(DpIdentifier &dpId);
	void remDPItem(DPItem *item, char *name);
	void setOwnSystemFlag(int flag) {ownSystemOnly = flag; };
	int getOwnSystemFlag() {return ownSystemOnly; };
protected:
	void doReceive(DpMsg &dpMsg);
	void handleHotLink(const DpMsgHotLink &dpMsg);
private:
//	DPItem *findDPItemName(char *dpname, char *dpitem);
	void run();
	void mydispatch(long &secs, long &usecs);
	int dispatchRate;
	int dispatchFlag;
	DpIdValueList *DPSetList;
//	TimeVar *DPSetListTime;
//	DpMsgComplexVC *DPSetList;
	HASHTable DPsToSend;
	HASHTable DPsToGet;
	void makeDPSetList();
	void freeDPSetList();
	int ownSystemOnly;
};

//class MySetWait: public WaitForAnswer
//{
//public:
//	MySetWait(DPItem *dpitem)
//	{
//		dpItem = dpitem;
//	}
//	MySetWait() {}
//	void callBack(DpMsgAnswer &answer);
//	DPItem *getDPItem() {return dpItem;};
//private:
//	DPItem *dpItem;
//};

class DPItem: /*public DLLItem*/ public HASHItem
{
public:
	DPItem(char *name, DP *dp);
	DPItem(char *dpname, char *name, DP *dp);
	~DPItem();
	char *getDPItemName() {return itemName;}
	int cmpDPItemName(char *name) { return(!strcmp(itemName,name));}
	int cmpDPDpName(char *name) { return(!strcmp(dpName,name));}
	char *getDPDpName() { return dpName;}
	char *getDPItemString();
	char *getDPItemLangString();
	int getDPItemInt();
	unsigned int getDPItemUInt();
	float getDPItemFloat();
	double getDPItemDouble();
	char getDPItemChar();
	bit getDPItemBit();
	bitset getDPItemBitset();
	time_t getDPItemTime();
	int getDPItemValue(int * &arr);
	int getDPItemValue(unsigned int * &arr);
	int getDPItemValue(bitset * &arr);
	int getDPItemValue(bit * &arr);
	int getDPItemValue(time_t * &arr);
	int getDPItemValue(float * &arr);
	int getDPItemValue(double * &arr);
	int getDPItemValue(char * &str);
	int getDPItemCharValues(char * &arr);
	void setValue(Variable *val) {value = val;}
	void setRead() {read = 1;}
	void connected(char *name) {connectedDp = new char[strlen(name)+1];
		strcpy(connectedDp,name);};

	char *isConnected() {return connectedDp;};
	DP *getDp() {return theDp; };
//	void setDpItemId(DpIdentifier &id) {theId = id; };
//	DpIdentifier &getDpItemId() {return theId; };
private:
	DP *theDp;
	char *itemName;
	char *dpName;
	Variable *value;
	int read;
	char *connectedDp;
	LangText lt;
//	DpIdentifier theId;
};

class MyWait: public WaitForAnswer
{
public:
	MyWait(DPItem *dpitem)
	{
		dpItem = dpitem;
	}
	~MyWait()
	{
		if(dpItem->isConnected() == (char *)0)
			delete dpItem;
	}
	void callBack(DpMsgAnswer &answer);
	DPItem *getDPItem() {return dpItem;};
private:
	DPItem *dpItem;
};

class DPElem
{
public:
	DPElem(ApiManager *itsManId, char *name)
	{
		DpIdentifier dp;

		DISABLE_AST
		dpElemName = new char[strlen(name)+1];
		strcpy(dpElemName,name);
		manId = itsManId;
		manId->getId(dpElemName, dp);
//		cout << "New DP Elem: " << dpElemName << endl;
		ENABLE_AST
		dpElemValueId = dp;
		dpElemValueId.setConfig(DPCONFIGNR_DPVALUE);
		dpElemValueId.setAttr(DPVALUE_VALUE_ATTR);
		dpElemUser8Id = dpElemValueId;
		dpElemUser8Id.setAttr(DPVALUE_USER_DEFINED_8_BIT_ATTR);
		dpElemUser7Id = dpElemValueId;
		dpElemUser7Id.setAttr(DPVALUE_USER_DEFINED_7_BIT_ATTR);
		dpElemUser6Id = dpElemValueId;
		dpElemUser6Id.setAttr(DPVALUE_USER_DEFINED_6_BIT_ATTR);
		dpElemUser5Id = dpElemValueId;
		dpElemUser5Id.setAttr(DPVALUE_USER_DEFINED_5_BIT_ATTR);
		dpElemUser1Id = dpElemValueId;
		dpElemUser1Id.setAttr(DPVALUE_USER_DEFINED_1_BIT_ATTR);
		dpElemInvId = dpElemValueId;
		dpElemInvId.setAttr(DPVALUE_AUTOMATIC_INVALID_BIT_ATTR);
	}
	DPElem(ApiManager *itsManId, char *name, char *elem)
	{
		DpIdentifier dp;

		DISABLE_AST
		dpElemName = new char[strlen(name)+strlen(elem)+1];
		strcpy(dpElemName,name);
		strcat(dpElemName,elem);
		manId = itsManId;
		manId->getId(dpElemName, dp);
//		cout << "New DP Elem: " << dpElemName << endl;
		ENABLE_AST
		dpElemValueId = dp;
		dpElemValueId.setConfig(DPCONFIGNR_DPVALUE);
		dpElemValueId.setAttr(DPVALUE_VALUE_ATTR);
		dpElemUser8Id = dpElemValueId;
		dpElemUser8Id.setAttr(DPVALUE_USER_DEFINED_8_BIT_ATTR);
		dpElemUser7Id = dpElemValueId;
		dpElemUser7Id.setAttr(DPVALUE_USER_DEFINED_7_BIT_ATTR);
		dpElemUser6Id = dpElemValueId;
		dpElemUser6Id.setAttr(DPVALUE_USER_DEFINED_6_BIT_ATTR);
		dpElemUser5Id = dpElemValueId;
		dpElemUser5Id.setAttr(DPVALUE_USER_DEFINED_5_BIT_ATTR);
		dpElemUser1Id = dpElemValueId;
		dpElemUser1Id.setAttr(DPVALUE_USER_DEFINED_1_BIT_ATTR);
		dpElemInvId = dpElemValueId;
		dpElemInvId.setAttr(DPVALUE_AUTOMATIC_INVALID_BIT_ATTR);
	}
	virtual ~DPElem()
	{
		delete dpElemName;
	}
	char *getDPElemName() {return dpElemName;}
	DpIdentifier &getValueId() { return dpElemValueId; }
	DpIdentifier &getUser8Id() { return dpElemUser8Id; }
	DpIdentifier &getUser7Id() { return dpElemUser7Id; }
	DpIdentifier &getUser6Id() { return dpElemUser6Id; }
	DpIdentifier &getUser5Id() { return dpElemUser5Id; }
	DpIdentifier &getUser1Id() { return dpElemUser1Id; }
	DpIdentifier &getInvId() { return dpElemInvId; }
private:
	ApiManager *manId;
	char *dpElemName;
	DpIdentifier dpElemValueId;
	DpIdentifier dpElemUser8Id;
	DpIdentifier dpElemUser7Id;
	DpIdentifier dpElemUser6Id;
	DpIdentifier dpElemUser5Id;
	DpIdentifier dpElemUser1Id;
	DpIdentifier dpElemInvId;
};


class DP : public DLLItem
{
public:
	DP(char *name, ApiManager *man):
		/*itemList(), */manId(man)
	{
		DpIdentifier dp;
		char *full_name = 0;
		CharString namestr;

		DISABLE_AST
		if(manId->getId(name, dp))
		{
//			manId->getName(dp, full_name);
			manId->getName(dp, namestr);
			full_name = (char *)namestr;
		}
//		cout << "New DP: " << name << " full name: " << full_name << endl;
		ENABLE_AST
		if(full_name)
		{
			dpName = new char[strlen(full_name)+1];
			strcpy(dpName,full_name);
//#ifndef WIN32
//			delete[] full_name;
//#endif
		}
		else
		{
			dpName = new char[1];
			strcpy(dpName,"");
		}
		stimeSecs = (time_t)0;
		stimeMillies = 0;
//		manId->DPList.add(this);
//		manId->DPTable.add(dpName, this);
	}
	virtual ~DP()
	{
//		DPItem *dpItem;
//		DISABLE_AST
//		while((dpItem = (DPItem *)itemList.removeHead()) != 0)
//			delete dpItem;
//		ENABLE_AST
////		manId->DPList.remove(this);
//		manId->DPTable.remove(dpName, this);
		delete dpName;
	}
	char *getDPName() {return dpName;}
	virtual void gotDPValue(DPItem *dpItem) {};
	int getDPValue(char *item);
	int getDPValue(char *name, char *item);
	int connectDPValue(char *item);
	int connectDPValue(char *name, char *item);
	int disconnectDPValue(char *item);
	int disconnectDPValue(char *name, char *item);
	int setDPValue(char *item, bit value);
	int setDPValue(char *item, char *value);
	int addDPValue(char *item, char *value);
	int setDPValue(char *item, int value);
	int setDPValue(char *item, unsigned int value);
	int setDPValue(char *item, float value);
	int setDPValue(char *item, double value);
	int setDPValue(char *item, bitset value);
	int setDPValue(char *item, time_t value);
	int setDPValue(char *item, char **value, int size);
	int addDPValue(char *item, char **value, int size);
	int setDPValue(char *item, int *value, int size);
	int setDPValue(char *item, unsigned int *value, int size);
	int setDPValue(char *item, float *value, int size);
	int setDPValue(char *item, double *value, int size);
	int setDPValue(char *name, char *item, bit value);
	int setDPValue(char *name, char *item, char value);
	int setDPValue(char *name, char *item, char *value);
	int setDPValue(char *name, char *item, int value);
	int setDPValue(char *name, char *item, unsigned int value);
	int setDPValue(char *name, char *item, float value);
	int setDPValue(char *name, char *item, double value);
	int setDPValue(char *name, char *item, bitset value);
	int setDPValue(char *name, char *item, time_t value);
	int setDPValue(char *name, char *item, char *value, int size);
	int setDPValue(char *name, char *item, char **value, int size);
	int setDPValue(char *name, char *item, int *value, int size);
	int setDPValue(char *name, char *item, unsigned int *value, int size);
	int setDPValue(char *name, char *item, bitset *value, int size);
	int setDPValue(char *name, char *item, time_t *value, int size);
	int setDPValue(char *name, char *item, bit *value, int size);
	int setDPValue(char *name, char *item, float *value, int size);
	int setDPValue(char *name, char *item, double *value, int size);

	int setDPValue(DPElem *elem, bit value);
	int setDPValue(DPElem *elem, char value);
	int setDPValue(DPElem *elem, char *value);
	int setDPValue(DPElem *elem, int value);
	int setDPValue(DPElem *elem, unsigned int value);
	int setDPValue(DPElem *elem, float value);
	int setDPValue(DPElem *elem, double value);
	int setDPValue(DPElem *elem, bitset value);
	int setDPValue(DPElem *elem, time_t value);
	int setDPValue(DPElem *elem, char *value, int size);
	int setDPValue(DPElem *elem, char **value, int size);
	int setDPValue(DPElem *elem, int *value, int size);
	int setDPValue(DPElem *elem, unsigned int *value, int size);
	int setDPValue(DPElem *elem, bitset *value, int size);
	int setDPValue(DPElem *elem, time_t *value, int size);
	int setDPValue(DPElem *elem, bit *value, int size);
	int setDPValue(DPElem *elem, float *value, int size);
	int setDPValue(DPElem *elem, double *value, int size);

	int setDPAttr(DPElem *elem, ATTR_TYPES attr, bit value);


	int setDPAttr(char *item, char *attr, bit value);
	int setDPAttr(char *item, char *attr, char *value);
	int setDPAttr(char *item, char *attr, int value);
	int setDPAttr(char *item, char *attr, float value);
	int setDPAttr(char *item, char *attr, int *value, int size);
	int setDPAttr(char *item, char *attr, float *value, int size);
	int setDPAttr(char *name, char *item, char *attr, bit value);
	int setDPAttr(char *name, char *item, char *attr, char *value);
	int setDPAttr(char *name, char *item, char *attr, int value);
	int setDPAttr(char *name, char *item, char *attr, float value);
	int setDPAttr(char *name, char *item, char *attr, int *value, int size);
	int setDPAttr(char *name, char *item, char *attr, float *value, int size);
	int addDPAttr(DpIdValueList &list, char *name, char *item, char *attr, bit value);
	int addDPAttr(DpIdValueList &list, char *name, char *item, char *attr, time_t value);
	int sendDPAttrs(DpIdValueList &list);
	int setDPTimeValue(char *item);
	int setDPTimeValue(char *name, char *item);
//	DPItem *getDPItem(char *item);
//	DPItem *getDPItemDpName(char *item);
//	DLList itemList;
	ApiManager *getManId() { return manId;};
	void setStime(time_t tsecs, int millies);
	void clearStime();
	int getDPId(const char *name, DpIdentifier &dpId, char *func);
	int getDPId(DPElem *elem, DpIdentifier &dpId, ATTR_TYPES attr);
private:
	ApiManager *manId;
	char *dpName;
	int doSetDpValue(char *dp, Variable &variable);
	int doSetDpValue(DPElem *elem, Variable &variable, ATTR_TYPES attr);
	time_t stimeSecs;
	PVSSlong stimeMillies;
};

/*
class DPIdHASHItem : public HASHItem
{
//	Variable *itsValue;
//	DpIdentifier *itsDpId;
	DpIdentifier *itsDpId;
	DpElementId itsElId;
	int itsDpFlag;
public:
	DPIdHASHItem(DpIdentifier &id);
	~DPIdHASHItem();
	VariablePtr getValuePtr();
	DpIdentifier &getDpId();
	DpElementId getElId();
};
*/

