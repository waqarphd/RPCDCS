#include <dic.hxx>
#include <dis.hxx>
#include "ApiLib.hxx"

#include <time.h>
#include <sys/timeb.h>

#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>

//#define DEBUG

typedef enum DIM_TYPES {DIM_RECURSE = -2, DIM_NOT_SUPPORTED, 
			DIM_STRING, DIM_INTEGER, DIM_FLOAT,
			DIM_INT_ARRAY, DIM_FLOAT_ARRAY, DIM_STRING_ARRAY,
			DIM_BOOL, DIM_BOOL_ARRAY, DIM_BITFIELD, DIM_BITFIELD_ARRAY,
			DIM_CHAR, DIM_CHAR_ARRAY, DIM_UINTEGER, DIM_UINT_ARRAY,
			DIM_TIME, DIM_TIME_ARRAY, DIM_LANG_STRING};

#define MAX_BEFORE_SENDING 15
#define MAX_DIM_NAME 132
#define MAX_DP_NAME 256

time_t gOldTime = 0;
int gHeartBeat = 0;
int discardOldData = 0;

class ConfigDp;

class DimObject;

class DimItem;

class DimTodoItem;

class DimManager : public ApiManager, public DimServer
{
public:
	DimManager(/*char *name*/char *file_name, char *dp_name, int own_system_flag);

	int readDimConfig();
	int processDimLine(char *str, int dim_type, int config);
	DIM_TYPES getDimDpType(DpIdentifier &dp, char *dpName);
//	DLList dimList;
	HASHTable dimList;
	DLList todoList;
	static void print_date_time()
	{
		time_t t;
		char str[128];

		t = time((time_t *)0);
		strcpy(str, ctime(&t));
		str[strlen(str) - 1] = '\0';
		cout << "PVSS00dim(" << itsManId << ") - " << str << "\n\t";
	}
	static void print_date_time_detailed()
	{
		time_t t;
		char str[128], str1[10];
		struct timeb timebuf;

		ftime(&timebuf);
		t = time((time_t *)0);
		strcpy(str, ctime(&t));
		str[strlen(str) - 1] = '\0';
		strcat(str,".");
		sprintf(str1,"%d",timebuf.millitm);
		strcat(str,str1);
		cout << "PVSS00dim(" << itsManId << ") - " << str << "\n\t";
	}
	static void printService(int dim_type, char *name, int n_items,
							  char *dp_name, char *action);
	static void printAllServices(int dim_type, int n_items, char *action);
	static char *printDimDpType(DIM_TYPES dim_type);
	void clearDimItemStates(int type);
	DimItem *findDimItem(char *line, int type);
	DimItem *getClearedDimItem(int type);
	int removeClearedDimItems(int type);
	void removeDimItem(int index, DimItem *item);
/*
	void setFlag() { itsFlag++; };
	int getFlag() { return itsFlag; };
	void clearFlag() {itsFlag--; };
	void resetFlag() { itsFlag = 0; };
*/
	void setFlag(DimObject *obj, int flag);
	void resetFlag(DimTodoItem *item);
	void setAliveRate(int rate) {itsAliveRate = rate;};
	int getAliveRate() {return itsAliveRate;};
	void setExit(int exit_code) { itsExit = exit_code; };
	int getManNum() { return itsManId; };
	DimRpcInfo *dnsRpc;
	ConfigDp *getConfigDp() {return itsDp;};
	void exitHandler(int code);
	void searchDNS(char *search, DimObject *obj);
protected:
	void manInitialize();
	void manExecute();
	void manExit();
	void gotDpValues();
	char *itsManName;
	char *itsFileName;
	char *itsDpName;
	ConfigDp *itsDp;
	static int itsManId;
	int getDpItemListSize(char *dpe);
	int itsFlag;
	int getDpItemList(char *dpe, DIM_TYPES *types, int &n, char *dpsptr, int &dpslen);
	int itsAliveRate;
	time_t itsLastTime;
	int itsExit;
};

int DimManager::itsManId = 0;

class ConfigDp : public DP
{
public:
	ConfigDp(char *name, DimManager *id) : 
	  DP(name, id)
	  {
	    char *ptr;
		man = id;
		itsSearchPattern = 0;
		itsDispatchRate = 0;
		ptr = getDPName();
		if(!*ptr)
		{
			cout << "Config DP does not exist, exiting..." << endl;
			exit(0);
		}
		if(ptr = strchr(ptr,':'))
		  ptr++;
		if(*ptr)
		  {
		    connectDPValue(".clientServices");
		    connectDPValue(".clientCommands");
		    connectDPValue(".serverServices");
		    connectDPValue(".serverCommands");
		    connectDPValue(".clientRPCs");
		    connectDPValue(".serverRPCs");
		    connectDPValue(".DnsInfo.searchString");
		    connectDPValue(".ApiParams.dispatchRate");
		    connectDPValue(".ApiParams.aliveRate");
		    connectDPValue(".ApiParams.exit");
		    setDPValue(".ApiInfo.manState",(bit) 1);
		    setDPValue(".ApiInfo.manNum",man->getManNum());
		  }
	  }
	void setSearchFlag(char *str, DimObject *obj)
	{
		itsSearchPattern = new char[strlen(str) + 1];
		strcpy(itsSearchPattern, str);
		itsSearchObject = obj;
	}
	void clearSearchFlag()
	{
		if(itsSearchPattern)
		{
			delete[] itsSearchPattern;
			itsSearchPattern = 0;
		}
	}
	char *getSearchFlag(DimObject * &obj)
	{
		obj = itsSearchObject;
		return itsSearchPattern;
	}
protected:
	void gotDPValue(DPItem *dpItem);
	DimManager *man;
	char *itsSearchPattern;
	DimObject *itsSearchObject;
	int itsDispatchRate;
};

class ServiceItem : public DLLItem
{
public:
	ServiceItem()
	{
		itsServData = 0;
		itsServSize = 0;
	}
	ServiceItem(void *addr, int size)
	{
		toWriteItems = 0;
		itsServData = new char[size];
		itsServSize = size;
		memcpy((void *)((char*)(itsServData)), addr, size);
	}
	~ServiceItem()
	{
		if(itsServData)
			delete[] itsServData;
	}
	int compareData(void *addr, int size)
	{
		if(size == itsServSize)
		{
			if(!memcmp((void *)((char*)(itsServData)), addr, size))
				return 1;
		}
		return 0;
	}
	void *getWriteData()
	{
		return itsServData;
	}
	int getWriteSize() { return itsServSize; };
	void setWriteItems(int n) { toWriteItems = n; };
	int getWriteItems() { return toWriteItems; };

	void setData(void *addr, int size)
	{
		if(size > itsServSize)
		{
			if(itsServData)
				delete[] itsServData;
			itsServData = new char[size];
			itsServSize = size;
		}
		memcpy((void *)((char*)(itsServData)), addr, size);
	}
//	void setFirst(int first) {itsFirst = first;};
//	int isFirst() {return itsFirst; }

private:
	void *itsServData;
	int itsServSize;
	int toWriteItems;
//	int itsFirst;
};

class DimDpItem
{
public:
	DLList serviceList;
	ServiceItem lastServiceData;
	DimDpItem(ApiManager *manId, char *name)
	{
		int i;
//		cout << "Creating ToWriteDp: "<< name << endl;
//	    toWriteDP = new char[strlen(name)+1];
//		strcpy(toWriteDP,name);
		toWriteDP = new DPElem(manId, name);
		itsServData = 0;
		itsServSize = 0;
		itsServCurrSize = 0;
		itsReadFile = 0;
		itsFileData = 0;
		itsFileSize = 0;
		itsFileCurrSize = 0;
//		toWriteItems = 0;
		itsToWriteFlag = 0;
		for(i = 0; i < 8; i++)
			userbits[i] = 0;
		invalid = 0;
		itsWrongType = 0;
	}
	~DimDpItem()
	{
		delete toWriteDP;
		if(itsServData)
			delete[] itsServData;
		if(itsFileData)
			delete[] itsFileData;
	}
	int copyDataOut(void *addr, int size, int fullsize)
	{
		if(itsServSize < (fullsize))
		{
			if(itsServData)
				delete[] itsServData;
			itsServData = new char[fullsize];
			itsServSize = fullsize;
		}
		itsServCurrSize = fullsize;
		memset((void *)((char*)(itsServData)), 0, fullsize);
		memcpy((void *)((char*)(itsServData)), addr, size);
		return 0;
	};
	int copyData(void *addr, int size, int compare, int save) 
	{
		int equal = 0;
		ServiceItem *serviceItem;
		int n_pending;

		if(compare)
		{
			if(lastServiceData.compareData(addr, size))
				equal = 1;
/*
			if(serviceList.getHead())
			{
				serviceItem = (ServiceItem *)serviceList.getLast();
				if(serviceItem->compareData(addr, size))
					equal = 1;
			}
*/
		}
		if(!equal)
		{
/* 
If one wants to restrict the size of the pending queue
*/
			if(discardOldData)
			{
				n_pending = 0;
				if(serviceItem = (ServiceItem *)serviceList.getHead())
				{
					n_pending++;
					while(serviceItem = (ServiceItem *)(serviceList.getNext()))
						n_pending++;
//DimManager::print_date_time_detailed();
//cout << "Pending " << n_pending << " for " << toWriteDP->getDPElemName() << endl;
					if(n_pending >= 1)
					{
//DimManager::print_date_time_detailed();
//cout << "Dropping data for " << toWriteDP->getDPElemName() << endl;
						serviceItem = (ServiceItem *)(serviceList.removeHead());
						if(serviceItem)
							delete serviceItem;
					}
				}
			}
			serviceItem = new ServiceItem(addr, size);
//			if(serviceList.getHead())
//				serviceItem->setFirst(0);
//			else
//				serviceItem->setFirst(1);
			serviceList.add(serviceItem);
			if(save)
				lastServiceData.setData(addr, size);
		}
		return(equal);
	}
	int copyFileData()
	{
		FILE *f;
		int sz = 0, ret = 0, fullsize;
		struct stat buf;		

		if(itsReadFile)
		{
			f = fopen((char *)itsServData,"r");
			if(f != 0)
			{
				ret = fstat(fileno(f), &buf);
				sz = buf.st_size;
			}
			fullsize = sz+1;
			if(itsFileSize < (fullsize))
			{
				if(itsFileData)
					delete[] itsFileData;
				itsFileData = new char[fullsize];
				itsFileSize = fullsize;
			}
			itsFileCurrSize = fullsize;
			memset((void *)((char*)(itsFileData)), 0, fullsize);

			if(f != 0)
			{
				ret = fread((char *)itsFileData, 1, sz, f);
DimManager::print_date_time_detailed();
cout << "Reading file: " << (char *)itsServData << endl;
				fclose(f);
			}
		}
		return 0;
	};

	void packData(char *item, int type, void *cmndptr, int cmndsize);
	int getWriteFlag() {return itsToWriteFlag; };
	void clearWriteFlag() 
		{ itsToWriteFlag = 0;};
	void setWriteFlag() 
		{ itsToWriteFlag = 1;};
	int getWriteType() {return toWriteType; };
	void setWriteType(int type) { toWriteType = type; };
	char *getWriteDpName() { return toWriteDP->getDPElemName(); };
	DPElem *getWriteDp() { return toWriteDP; };
	void *getWriteData() 
	{
		if(itsReadFile)
			return itsFileData; 
		else
			return itsServData; 
	};
	int getWriteSize() 
	{ 
		if(itsReadFile)
			return itsFileCurrSize; 
		else
			return itsServCurrSize; 
	};
	void setWriteItems(int n) 
	{ 
		((ServiceItem *)serviceList.getLast())->setWriteItems(n);
	};
//	int getWriteItems() 
//	{ 
//		return (serviceList.getLast())->getWriteItems(); 
//	};
	void setBit(int n, bit value) { userbits[n] = value; };
	bit getBit(int n) { return userbits[n]; };
	void setInvalid(bit n) { invalid = n; };
	bit getInvalid() { return invalid; };
	int getFileFlag() {return itsReadFile; };
	void clearFileFlag() 
		{ itsReadFile = 0;};
	void setFileFlag() 
		{ itsReadFile = 1;};
	void setStime(time_t tsecs) { stime = tsecs; };
	time_t getStime() { return stime; };
	void reportError(char *dp, int type, char code, int flag);
private:
//	char *toWriteDP;
	DPElem *toWriteDP;
	int toWriteType;
//	int toWriteItems;
	void *itsServData;
	int itsServSize;
	int itsServCurrSize;
	int itsToWriteFlag;
	void *itsFileData;
	int itsFileSize;
	int itsFileCurrSize;
	bit userbits[8];
	bit invalid;
	time_t stime;
	int itsReadFile;
	int itsWrongType;
};

class CmndItem : public DLLItem
{
public:
	CmndItem(void *addr, int size, int id)
	{
		itsCmndData = new char[size];
		itsCmndSize = size;
		memcpy((void *)((char*)(itsCmndData)), addr, size);
		itsClientId = id;
	}
	~CmndItem()
	{
		delete[] itsCmndData;
	}
	void getCmndData(void * &addr, int &size, int &id)
	{
		addr = itsCmndData;
		size = itsCmndSize;
		id = itsClientId;
	}
private:
	void *itsCmndData;
	int itsCmndSize;
	int itsClientId;
};

class DimObject : public DP, public DimClient, public DimCommandHandler,
	public DimTimer
{
public :
	DimObject(char *name, DimManager *id, int type) : 
	   DP(name,id) , DimClient()
	{
		   init(name, id, type);
	}
	~DimObject()
	{
		if(itsDimType == 1)
			unsetupClientCommand();
		if(itsDimType == 2)
			unsetupServerService();
		delete[] itsDpName;
		if(itsNoLink)
			delete[] itsNoLink;
		if(itsDimName)
			delete[] itsDimName;
		if(itsDpItemNames)
			delete[] itsDpItemNames;
		if(itsTypes)
			delete[] itsTypes;
		if(itsClient)
			delete itsClient;
		if(itsService)
			delete itsService;
		if(itsServData)
			delete[] itsServData;
		if(itsCommand)
			delete itsCommand;
		if(itsMergeIndexes)
			delete[] itsMergeIndexes;
		if(itsFormat)
			delete[] itsFormat;
	}
	void infoHandler();
	void commandHandler();
	void handleCommand(void *addr, int size, int id);
	void gotDPValue(DPItem *dpItem);
	DimInfo *itsClient;
	DimService *itsService;
	DimCommand *itsCommand;
	char *getDpName() {return itsDpName;}
	void setDimName(char *name) {
	    itsDimName = new char[strlen(name)+32];
		strcpy(itsDimName,name);
	}
	char *getDimName() {return itsDimName;}
	void setDpItemNames(char *name, int len) {
	    itsDpItemNames = new char[len];
		memcpy(itsDpItemNames,name,len);
	}
	void setDpItemNames(char *name) {
	    itsDpItemNames = new char[strlen(name)+1];
		strcpy(itsDpItemNames,name);
	}
	char *getDpItemNames() {return itsDpItemNames; };
	int getNTypes() {return itsNTypes; };
	int isCmnd() {return (itsDimType & 0x1);}
	int isServer() {return (itsDimType & 0x2);}
	void copyData(void *addr, int size, int offset) {
		if(itsServSize < (size + offset))
		{
			if(itsServData)
				delete[] itsServData;
			itsServData = new char[size+offset];
			itsServSize = size+offset;
		}
		if(addr)
			memcpy((void *)((char*)(itsServData)+offset), addr, size);
	};
	int write_data_differ();
	int set_invalid_bits_differ();
	void *getWriteData() { return itsServData; };
	int getWriteFlag() {return itsToWriteFlag; };
	void clearWriteFlag() 
		{ itsToWriteFlag = 0; /*itsManager->clearFlag();*/};
	void setWriteFlag() 
		{ itsToWriteFlag = 1; itsManager->setFlag(this, 1); };
	int getWriteInvFlag() {return itsToWriteInvFlag; };
	void clearWriteInvFlag() 
		{ itsToWriteInvFlag = 0; /*itsManager->clearFlag();*/};
	void setWriteInvFlag(int flag) 
		{ itsToWriteInvFlag = flag; itsManager->setFlag(this, 2);};
	int setupClientService(char *serv_name, int n, char *dps, int dpslen,
		DIM_TYPES *types, int timeout, int stamped, char *nolink, int update);
	int setupClientCommand(char *serv_name, int n, char *dps, int dpslen,
		DIM_TYPES *types, int merge_flag, char *format);                  
	int setupServerService(char *serv_name, int n, char *dps, int dpslen,
		DIM_TYPES *types, char *format);                  
	int setupServerCommand(char *serv_name, int n, char *dps, int dpslen,
		DIM_TYPES *types, char *format);
	int unsetupClientCommand();
	int unsetupServerService();
	void setRPCCommand(DimObject *obj) { itsRPCCommand = obj; }
	int getLastClientId() { return itsLastClientId; }
	int getRPCBusy() { return itsRPCBusy; }
	void clearRPCBusy() { itsRPCBusy = 0; }
	int getRPCTimeout() { return itsRPCTimeout; }
	void clearRPCTimeout() { itsRPCTimeout = 0; }
	DLList cmndList;
	void timerHandler();
	void setFormat(char *format) 
	{
		if(format != 0)
		{
			itsFormat = new char[strlen(format)+1];
			strcpy(itsFormat,format);
		}
/*
		else
		{
			if(itsNFindRetries < 20)
			{
				itsNFindRetries++;
				start(1);
			}
			else
				start(5);
		}
*/
		itsFindFormatFlag = 0;
	}
	void findFormat()
	{
		itsFindFormatFlag = 1;
		itsManager->setFlag(this, 0);
	}
	int getFindFormatFlag() { return itsFindFormatFlag; };
	char *hasFormat() { return itsFormat; };
	DimManager *getManId() { return itsManager; };
private :
	char *itsDpName;
	char *itsDpItemNames;
	char *itsDimName;
	int itsDimType;
	DIM_TYPES *itsTypes;
	DimDpItem **itsDpItemPtrs;
	int itsNTypes;
	int itsLastTime;
	int itsTime;
	int itsStamped;
	void *itsNoLink;
	int itsNoLinkSize;
	int itsInit;
	void *itsServData;
	int itsServSize;
	int itsInvalid;
	char itsQuality;
	int itsToWriteFlag;
	int itsToWriteInvFlag;
	DimManager *itsManager;
	int itsMergeFlag;
	int *itsMergeIndexes;
	int itsReadFile;
	int itsLastClientId;
	int itsRPCBusy;
	int itsRPCTimeout;
	DimObject *itsRPCCommand;
	char *itsFormat;
	int itsFindFormatFlag;
	int itsNFindRetries;
	void init(char *name, DimManager *id, int type)
	{
	    itsDpName = new char[strlen(name)+32];
		strcpy(itsDpName,name);
		itsClient = 0;
		itsService = 0;
		itsCommand = 0;
		itsTypes = 0;
		itsNTypes = 0;
		itsStamped = -1;
		itsTime = -1;
		itsLastTime = 0;
		itsNoLink = 0;
		itsNoLinkSize = 0;
		itsDimName = 0;
		itsDpItemNames = 0;
		itsDimType = type;
		itsInit = 0;
		itsServData = 0;
		itsServSize = 0;
		itsInvalid = -1;
		itsQuality = -1;
		itsDpItemPtrs = 0;
		itsToWriteFlag = 0;
		itsToWriteInvFlag = 0;
		itsMergeIndexes = 0;
		itsMergeFlag = 0;
		itsReadFile = 0;
		itsManager = id;
		itsLastClientId = 0;
		itsRPCBusy = 0;
		itsRPCTimeout = 0;
		itsRPCCommand = 0;
		itsFormat = 0;
		itsFindFormatFlag = 0;
		itsNFindRetries = 0;
	}
	int write_data(int type, char *dp, void *data, int size, 
		char * &codes, DimDpItem *dpPtr, int compare, int save);
	int check_data(int type, char *dp, int size, char * &codes, DimDpItem *dpPtr);
	void set_invalid_bits(char *dp, int n, bit invalid, char quality);
	int getItemCode(char * &format, char &code, int &number);
	int checkItemCode(char *format, char &code, int &number);
	void setDimNoLink(char *nolink);
	void getDataFormat(char *format);
	void copyDataItem(int type, DPItem *dpItem, DimDpItem *dpItemPtr, 
		int print, char *format, int itemIndex);
	void setupDimDps(DimObject *obj, char *serv_name, int n, char *dps, int dpslen,
		DIM_TYPES *types);
};

/*
class DimItem : public DLLItem
{
public:
	DimItem(DimObject *obj, DimObject *obj1, int config, char *line, int type)
	{
		dimObj = obj;
		dimObj1 = obj1;
		dimConfig = config;
	    dimLine = new char[strlen(line)+1];
		strcpy(dimLine,line);
		dimType = type;
		dimState = 1;
	}
	~DimItem()
	{
		delete dimObj;
		if(dimObj1)
			delete dimObj1;
		delete dimLine;
	}
	char *getName() {return dimObj->getDpName();};
	DimObject *getDimObject() {return dimObj; };
	char *getDimLine() {if(!dimConfig) return (char *)0; else return dimLine; };
	int getDimType() {return dimType; };
	void setDimState(int state) { dimState = state; };
	int getDimState() { return dimState; };
private:
	DimObject *dimObj;
	DimObject *dimObj1;
	int dimConfig;
	char *dimLine;
	int dimType;
	int dimState;
};
*/

class DimItem : public HASHItem
{
public:
	DimItem(DimObject *obj, DimObject *obj1, int config, char *line, int type)
	{
		dimObj = obj;
		dimObj1 = obj1;
		dimConfig = config;
	    dimLine = new char[strlen(line)+1];
		strcpy(dimLine,line);
		dimType = type;
		dimState = 1;
	}
	~DimItem()
	{
		delete dimObj;
		if(dimObj1)
			delete dimObj1;
		delete[] dimLine;
	}
	char *getName() {return dimObj->getDpName();};
	DimObject *getDimObject() {return dimObj; };
	char *getDimLine() {if(!dimConfig) return (char *)0; else return dimLine; };
	int getDimType() {return dimType; };
	void setDimState(int state) { dimState = state; };
	int getDimState() { return dimState; };
private:
	DimObject *dimObj;
	DimObject *dimObj1;
	int dimConfig;
	char *dimLine;
	int dimType;
	int dimState;
};

class DimTodoItem : public DLLItem
{
public:
	DimTodoItem(DimObject *obj)
	{
		dimObj = obj;
	}
	~DimTodoItem()
	{
	}
	char *getName() {return dimObj->getDpName();};
	DimObject *getDimObject() {return dimObj; };
	void setTodoTypeFlag(int flag) { todoTypeFlag = flag; };
	int getTodoTypeFlag() { return todoTypeFlag; };
private:
	DimObject *dimObj;
	int todoTypeFlag;
};

void DimDpItem::packData(char *item, int type, void *cmnd, int size)
{

	int tot_size;
	int val_size, n, i;
	char *ptr;
	
	switch(type)
	{
		case DIM_STRING:
			val_size = size;
			break;
		case DIM_INTEGER:
		case DIM_UINTEGER:
		case DIM_BOOL:
		case DIM_BITFIELD:
		case DIM_FLOAT:
		case DIM_TIME:
			val_size = 16;
			break;
		case DIM_BOOL_ARRAY:
		case DIM_INT_ARRAY:
		case DIM_UINT_ARRAY:
		case DIM_FLOAT_ARRAY:
		case DIM_BITFIELD_ARRAY:
		case DIM_TIME_ARRAY:
			n = size/sizeof(int);
			val_size = 16 * n;
			break;
	}
	tot_size = strlen(item)+2 + val_size;
	if(itsServSize < (tot_size))
	{
		if(itsServData)
			delete[] itsServData;
		itsServData = new char[tot_size];
		itsServSize = tot_size;
	}
	itsServCurrSize = tot_size;
	ptr = (char *)itsServData;
	strcpy(ptr,item);
	strcat(ptr," ");
	ptr += strlen(ptr);
	switch(type)
	{
		case DIM_STRING:
			strcpy(ptr, (char *)cmnd);
			break;
		case DIM_INTEGER:
		case DIM_UINTEGER:
		case DIM_BOOL:
		case DIM_BITFIELD:
		case DIM_TIME:
			sprintf(ptr,"%d", *(int *)cmnd);
			break;
		case DIM_FLOAT:
			sprintf(ptr,"%1.3f", *(float *)cmnd);
			break;
		case DIM_INT_ARRAY:
		case DIM_UINT_ARRAY:
		case DIM_BOOL_ARRAY:
		case DIM_BITFIELD_ARRAY:
		case DIM_TIME_ARRAY:
			for(i = 0; i < n; i++)
			{
				sprintf(ptr,"%d ",((int *)cmnd)[i]);
				ptr += strlen(ptr);
			}
			break;
		case DIM_FLOAT_ARRAY:
			for(i = 0; i < n; i++)
			{
				sprintf(ptr,"%1.3f ",((float *)cmnd)[i]);
				ptr += strlen(ptr);
			}
			break;
	}
}

void DimManager::exitHandler(int code) 
{ 
	doExit = PVSS_TRUE;
}


void DimManager::printService(int dim_type, char *name, int n_items,
							  char *dp_name, char *action)
{

	DimManager::print_date_time();
	switch(dim_type)
	{
		case 0:
			cout << "*** Client SERVICE "<< name; 
			break;
		case 1:
			cout << "*** Client COMMAND "<< name; 
			break;
		case 2:
			cout << "*** Server SERVICE "<< name; 
			break;
		case 3:
			cout << "*** Server COMMAND "<< name; 
			break;
		case 4:
			cout << "*** Client RPC "<< name; 
			break;
		case 5:
			cout << "*** Server RPC "<< name; 
			break;
	}
	if(n_items > 1)
	{
		cout << " for DPs " << dp_name << "..." << action << endl;
	}
	else
	{
		cout << " for DP " << dp_name << action << endl;
	}
}

void DimManager::printAllServices(int dim_type, int n_items, char *action)
{
	char str[128];

	switch(dim_type)
	{
		case 0:
			strcpy(str," DIM Client Service(s)");
			break;
		case 1:
			strcpy(str," DIM Client Command(s)");
			break;
		case 2:
			strcpy(str," DIM Server Service(s)");
			break;
		case 3:
			strcpy(str," DIM Server Command(s)");
			break;
		case 4:
			strcpy(str," DIM Client RPC(s)");
			break;
		case 5:
			strcpy(str," DIM Server RPC(s)");
			break;
	}
	if(n_items)
	{
		DimManager::print_date_time();
		cout << "*** "<< n_items << str << action << endl; 
	}
}

void ConfigDp::gotDPValue(DPItem *dpItem)
{
 	char *ptr, *buf, *search;
	int i, size, n_items = 0;
	int dim_type, rate, exit_code;
	DimItem *item;
	static int firstTimeDns = 1;
	static int firstTimeExit = 1;

	DISABLE_AST

	buf = 0;
	size = 0;
//DimManager::print_date_time_detailed();
//cout << "Got New Config" << endl; 
	if(dpItem->cmpDPItemName(".clientServices"))
	{
		size = dpItem->getDPItemValue(buf);
		dim_type = 0;
	}
	if(dpItem->cmpDPItemName(".clientCommands"))
	{
		size = dpItem->getDPItemValue(buf);
		dim_type = 1;
	}
	if(dpItem->cmpDPItemName(".serverServices"))
	{
		size = dpItem->getDPItemValue(buf);
		dim_type = 2;
	}
	if(dpItem->cmpDPItemName(".serverCommands"))
	{
		size = dpItem->getDPItemValue(buf);
		dim_type = 3;
	}
	if(dpItem->cmpDPItemName(".clientRPCs"))
	{
		size = dpItem->getDPItemValue(buf);
		dim_type = 4;
	}
	if(dpItem->cmpDPItemName(".serverRPCs"))
	{
		size = dpItem->getDPItemValue(buf);
		dim_type = 5;
	}
	if(dpItem->cmpDPItemName(".ApiParams.dispatchRate"))
	{
		itsDispatchRate = dpItem->getDPItemInt();
		if(itsDispatchRate)
			man->setDispatchRate(itsDispatchRate);
		ENABLE_AST
		return;
	}
	if(dpItem->cmpDPItemName(".ApiParams.aliveRate"))
	{
		rate = dpItem->getDPItemInt();
		if(!rate)
		  rate = 10;
		man->setAliveRate(rate);
		ENABLE_AST
		return;
	}
	if(dpItem->cmpDPItemName(".ApiParams.exit"))
	{
		if(!firstTimeExit)
		{
			exit_code = dpItem->getDPItemInt();
			if(exit_code)
				man->setExit(exit_code);
		}
		else
			firstTimeExit = 0;
		ENABLE_AST
		return;
	}
	if(dpItem->cmpDPItemName(".DnsInfo.searchString"))
	{
		if(!firstTimeDns)
		{
			search = dpItem->getDPItemString();
//			DimManager::print_date_time();
//			cout << "*** Search String: "<< search << endl;
			setSearchFlag(search, 0);
		}
		else
			firstTimeDns = 0;
		ENABLE_AST
		return;
	}

	ENABLE_AST
//DimManager::print_date_time_detailed();
//cout << "Clear and find, size = " << size << endl; 
	man->clearDimItemStates(dim_type);
	ptr = buf;
	for(i = 0; i < size; i++)
	{
		DISABLE_AST
		man->findDimItem(ptr, dim_type);
		ptr += strlen(ptr)+1;
		ENABLE_AST
	}
/*
	while(1)
	{
		man->print_date_time_detailed();
		cout << "Before GetCleared" << endl;
		item = man->getClearedDimItem(dim_type);
		if(!item)
			break;
#ifdef DEBUG
		DimManager::printService(dim_type, 
			item->getDimObject()->getDimName(),
			item->getDimObject()->getNTypes(),
			item->getDimObject()->getDpItemNames(),
			" Deleted");
#endif
		man->print_date_time_detailed();
		cout << "Before Remove" << endl;
		man->removeDimItem(item);
		n_items++;
		man->print_date_time_detailed();
		cout << "After Remove, items = " << n_items << endl;
	}
*/
//DimManager::print_date_time_detailed();
//cout << "removeCleared" << endl; 
	n_items = man->removeClearedDimItems(dim_type);

//DimManager::print_date_time_detailed();
//cout << "Print deleted, " << n_items << endl; 
	DimManager::printAllServices(dim_type, n_items, " Deleted");
	ptr = buf;
	n_items = 0;
//DimManager::print_date_time_detailed();
//cout << "Last loop" << endl; 
	for(i = 0; i < size; i++)
	{
		DISABLE_AST
		item = man->findDimItem(ptr, dim_type);
		if(!item)
		{
			man->processDimLine(ptr, dim_type, 1);
			n_items++;
		}
		ptr += strlen(ptr)+1;
		ENABLE_AST
	}
//DimManager::print_date_time_detailed();
//cout << "Last print" << endl; 
	DimManager::printAllServices(dim_type, n_items, " Set Up");
//#ifndef WIN32
	if(buf)
		delete[] buf;
//#endif
}

void DimManager::clearDimItemStates(int type)
{
	DimItem *dimItem;
	int n = 0;

	DISABLE_AST
	dimItem = (DimItem *)dimList.getHead();
	while(dimItem)
	{
		if(type == dimItem->getDimType())
		{
			dimItem->setDimState(0);
		}
		n++;
		dimItem = (DimItem *)dimList.getNext();
	}
//cout <<"Clearing - items = " << n << dimList.getNItems() << endl;
	ENABLE_AST
}

DimItem *DimManager::findDimItem(char *line, int type)
{
	DimItem *dimItem;
//	char *ptr;

	DISABLE_AST
/*
	dimItem = (DimItem *)dimList.getHead();
	while(dimItem)
	{
		if(ptr = dimItem->getDimLine())
		{
			if(!strcmp(line,dimItem->getDimLine()))
			{
				if(type == dimItem->getDimType())
				{
					dimItem->setDimState(1);
					ENABLE_AST
					return(dimItem);
				}
			}
		}
		dimItem = (DimItem *)dimList.getNext();
	}
*/
	dimItem = (DimItem *)dimList.find(line);
	if(dimItem)
	{
		if(type == dimItem->getDimType())
		{
			dimItem->setDimState(1);
			ENABLE_AST
			return(dimItem);
		}
	}
	ENABLE_AST
	return 0;
}

int DimManager::removeClearedDimItems(int type)
{
	DimItem *dimItem, *nextItem;
	char *ptr;
	int hashIndex, nItems = 0, n = 0;

	DISABLE_AST
	dimItem = (DimItem *)dimList.getHead();
	while(dimItem)
	{
		hashIndex = dimList.getCurrentIndex();
		nextItem = (DimItem *)dimList.getNext();
		if(ptr = dimItem->getDimLine())
		{
			if(type == dimItem->getDimType())
			{
				if(dimItem->getDimState() == 0)
				{
#ifdef DEBUG
					printService(type, 
						dimItem->getDimObject()->getDimName(),
						dimItem->getDimObject()->getNTypes(),
						dimItem->getDimObject()->getDpItemNames(),
						" Deleted");
#endif
//					hashIndex = dimList.getCurrentIndex();
//					nextItem = (DimItem *)dimList.getNext();
					removeDimItem(hashIndex, dimItem);
					nItems++;
//	print_date_time_detailed();
//	cout << "After Remove, items = " << nItems << endl;
				}
			}
		}
		n++;
		dimItem = nextItem;
	}
	ENABLE_AST
//cout <<"CheckRemoving - items = " << n << dimList.getNItems() << endl;
	return nItems;
}

DimItem *DimManager::getClearedDimItem(int type)
{
	DimItem *dimItem;
	char *ptr;

	DISABLE_AST
	dimItem = (DimItem *)dimList.getHead();
	while(dimItem)
	{
		if(ptr = dimItem->getDimLine())
		{
			if(type == dimItem->getDimType())
			{
				if(dimItem->getDimState() == 0)
				{
					ENABLE_AST
					return(dimItem);
				}
			}
		}
		dimItem = (DimItem *)dimList.getNext();
	}
	ENABLE_AST
	return 0;
}

void DimManager::removeDimItem(int index, DimItem *item)
{

	DISABLE_AST
//	dimList.remove(item->getDimLine(), item);
	dimList.removeAtIndex(index, item);
//	cout << "Removing item from dimList" << dimList.getNItems() << endl;
	delete item;
	ENABLE_AST
}

void DimManager::setFlag(DimObject *obj, int flag) 
{
	if(doExit)
		return;
	DISABLE_AST
	DimTodoItem *item = new DimTodoItem(obj);
	item->setTodoTypeFlag(flag);
//print_date_time_detailed();
//cout << "+++++ Adding todoItem " << item->getName() << endl;
	todoList.add(item);
	ENABLE_AST
}

void DimManager::resetFlag(DimTodoItem *item) 
{
	DISABLE_AST
//print_date_time_detailed();
//cout << "----- Removing todoItem " << item->getName() << endl;
	todoList.remove(item);
	delete item;
	ENABLE_AST
}

int DimObject::getItemCode(char * &format, char &code, int &number)
{
	char *ptr;

	number = 0;
	ptr = format;
	if(!ptr)
	{
		code = 0;
		return 0;
	}
	if(*ptr)
	{
		code = *ptr;
		if(code == 'L')
			code = 'I';
		ptr++;
	}
	else
		return 0;
	if(*ptr)
	{
		ptr++;
		sscanf(ptr,"%d",&number);
		while (( *ptr != ';') && (*ptr != '\0'))
			ptr++;
		if(*ptr)
			ptr++;
	}
//	else
//		number = 1;
	format = ptr;
	return 1; 
}

int DimObject::checkItemCode(char *format, char &code, int &number)
{
	char *ptr;

	number = 0;
	ptr = format;
	if(!ptr)
	{
		code = 0;
		return 0;
	}
	if(*ptr)
	{
		code = *ptr;
		if(code == 'L')
			code = 'I';
		ptr++;
	}
	else
		return 0;
	if(*ptr)
	{
		ptr++;
		sscanf(ptr,"%d",&number);
		while (( *ptr != ';') && (*ptr != '\0'))
			ptr++;
		if(*ptr)
			ptr++;
	}
	return 1; 
}

void DimDpItem::reportError(char *dp, int type, char code, int flag)
{
	char *typ;
	typ = DimManager::printDimDpType((DIM_TYPES)type);
	if(itsWrongType)
		return;
	itsWrongType = 1;
	DimManager::print_date_time();
	if(!flag)
		cout << dp << ": Wrong type, expected "<<typ<< " received \'" << code << "\'" << endl;
	else if(flag == 1)
		cout << dp << ": Dynamic item must be at the end (" <<typ<< ")" << endl;
	else
		cout << dp << ": PVSS Data Type Not Implemented (" <<typ<< ")" << endl;
}

int DimObject::write_data(int type, char *dp, void *data, int size, 
						  char * &codes, DimDpItem *dpPtr, int compare, int save)
{
	int ret_size;
	char *data_ptr;
	int n, ret, bool_int, int_int, n_items, aux_size, tot;
	short bool_short;
	char bool_char;
	bit auxbit, *auxbitp;
	static char code;
	static int n_items_of_code = 0;
	int i, conv_d = 0, conv_bool = 0, conv_int = 0, *auxintp;
	double float_double, *auxdata = 0;
//	float testf;

	switch(type)
	{
		case DIM_STRING:
			ret = getItemCode(codes, code, n);
			if((ret) && (code != 'C'))
			{
				dpPtr->reportError(dp, type, code, 0);
//				DimManager::print_date_time();
//					cout << "Wrong type for DP: " << dp << endl;
			}
			if(!dpPtr->copyData((char *)data,strlen((char *)data)+1,compare, save))
			{
				dpPtr->setWriteType(type);
				dpPtr->setWriteFlag();
				setWriteFlag();
			}
//			setDPValue(dp,"",(char *)data);
			if(n)
				ret_size = n;
			else
				ret_size = strlen((char *)data)+1;
			break;
		case DIM_CHAR:
			if(n_items_of_code <= 0)
			{
				ret = getItemCode(codes, code, n);
				if(!n) 
					n = 1;
				n_items_of_code = n;
			}
			else
				ret = 1;
			n_items_of_code--;
//			ret = getItemCode(codes, code, n);
			if((ret) && (code != 'C'))
			{
				dpPtr->reportError(dp, type, code, 0);
//				DimManager::print_date_time();
//					cout << "Wrong type for DP: " << dp << endl;
			}
			if(!dpPtr->copyData(data,sizeof(char), compare, save))
			{
				dpPtr->setWriteType(type);
				dpPtr->setWriteFlag();
				setWriteFlag();
			}
//			setDPValue(dp,"",*(int *)data);
			ret_size = sizeof(char);
			break;
		case DIM_BITFIELD:
			if(n_items_of_code <= 0)
			{
				ret = getItemCode(codes, code, n);
				if(!n) 
					n = 1;
				n_items_of_code = n;
			}
			else
				ret = 1;
			n_items_of_code--;
//			ret = getItemCode(codes, code, n);
			if((ret) && (code != 'I'))
			{
				dpPtr->reportError(dp, type, code, 0);
//				DimManager::print_date_time();
//					cout << "Wrong type for DP: " << dp << endl;
			}
			if(!dpPtr->copyData(data,sizeof(bitset), compare, save))
			{
				dpPtr->setWriteType(type);
				dpPtr->setWriteFlag();
				setWriteFlag();
			}
//			setDPValue(dp,"",*(bitset *)data);
			ret_size = sizeof(bitset);
			break;
		case DIM_BOOL:
			if(n_items_of_code <= 0)
			{
				ret = getItemCode(codes, code, n);
				if(!n) 
					n = 1;
				n_items_of_code = n;
			}
			else
				ret = 1;
			n_items_of_code--;
//			ret = getItemCode(codes, code, n);
			switch(code)
			{
			case 'I':
				bool_int = *(int *)data;
				ret_size = sizeof(int);
				auxbit = (bit)bool_int;
				if(!dpPtr->copyData(&auxbit,sizeof(bit), compare, save))
				{
					dpPtr->setWriteType(type);
					dpPtr->setWriteFlag();
					setWriteFlag();
				}
//				setDPValue(dp,"",(bit)bool_int);
				break;
			case 'S':
				bool_short = *(short *)data;
				ret_size = sizeof(short);
				auxbit = (bit)bool_short;
				if(!dpPtr->copyData(&auxbit,sizeof(bit), compare, save))
				{
					dpPtr->setWriteType(type);
					dpPtr->setWriteFlag();
					setWriteFlag();
				}
//				setDPValue(dp,"",(bit)bool_short);
				break;
			case 'C':
				bool_char = *(char *)data;
				ret_size = sizeof(char);
				auxbit = (bit)bool_char;
				if(!dpPtr->copyData(&auxbit,sizeof(bit), compare, save))
				{
					dpPtr->setWriteType(type);
					dpPtr->setWriteFlag();
					setWriteFlag();
				}
//				setDPValue(dp,"",(bit)bool_char);
				break;
			default:
				dpPtr->reportError(dp, type, code, 0);
//				DimManager::print_date_time();
//				cout << "Wrong type for DP: " << dp << endl;
				break;
			}
			break;
		case DIM_INTEGER:
		case DIM_UINTEGER:
			if(n_items_of_code <= 0)
			{
				ret = getItemCode(codes, code, n);
				if(!n) 
					n = 1;
				n_items_of_code = n;
			}
			else
				ret = 1;
			n_items_of_code--;
			if((ret) && (code != 'I') && (code != 'S'))
			{
				dpPtr->reportError(dp, type, code, 0);
//				DimManager::print_date_time();
//				cout << "Wrong type for DP: " << dp << endl;
			}
			switch(code)
			{
				case 'C':
					if(sscanf((char *)data,"%d",&int_int))
					{
						if(n > 1)
							ret_size = n;
						else
							ret_size = strlen((char *)data)+1;
					}
					else										
					{
						dpPtr->reportError(dp, type, code, 0);
//						DimManager::print_date_time();
//						cout << "Wrong type for DP: " << dp << endl;
					}
					break;
				case 'S':
					int_int = (int)(*(short *)data);
					ret_size = sizeof(short);
					break;
				case 'I':
				default:
					int_int = *(int *)data;
					ret_size = sizeof(int);
			}
//DimManager::print_date_time_detailed();
//cout<< "got INT " << int_int << " code: ." << code << "." <<endl;
			if(!dpPtr->copyData(&int_int, sizeof(int), compare, save))
			{
				dpPtr->setWriteType(type);
				dpPtr->setWriteFlag();
				setWriteFlag();
			}
//			setDPValue(dp,"",*(int *)data);
//			ret_size = sizeof(int);
			break;
		case DIM_TIME:
			if(n_items_of_code <= 0)
			{
				ret = getItemCode(codes, code, n);
				if(!n) 
					n = 1;
				n_items_of_code = n;
			}
			else
				ret = 1;
			n_items_of_code--;
			if((ret) && (code != 'I'))
			{
				dpPtr->reportError(dp, type, code, 0);
//				DimManager::print_date_time();
//					cout << "Wrong type for DP: " << dp << endl;
			}
			if(!dpPtr->copyData(data, sizeof(int), compare, save))
			{
				dpPtr->setWriteType(type);
				dpPtr->setWriteFlag();
				setWriteFlag();
			}
//			setDPValue(dp,"",*(int *)data);
			ret_size = sizeof(int);
			break;
		case DIM_FLOAT:
			if(n_items_of_code <= 0)
			{
				ret = getItemCode(codes, code, n);
				if(!n) 
					n = 1;
				n_items_of_code = n;
			}
			else
				ret = 1;
			n_items_of_code--;
//			ret = getItemCode(codes, code, n);
			if((ret) && (code != 'F') && (code != 'D') && (code != 'I') && (code != 'C'))
			{
/*
				if( code == 'D')
				{
//					DimManager::print_date_time();
//					cout << "Converting Double to Float: " << dp << endl;
					conv_d = 1;
				}
				else
				{
*/
					dpPtr->reportError(dp, type, code, 0);
//					DimManager::print_date_time();
//					cout << "Wrong type for DP: " << dp << endl;
//				}
			}
			if( code == 'D')
			{
				float_double = *(double *)data;
				ret_size = sizeof(double);
			}
			else if(code == 'I')
			{
				float_double = *(int *)data;
				ret_size = sizeof(int);
			}
			else if(code == 'C')
			{
				if(sscanf((char *)data,"%lg",&float_double))
				{
//					float_double = (double)testf;
					if(n > 1)
						ret_size = n;
					else
						ret_size = strlen((char *)data)+1;
				}
				else										
				{
					dpPtr->reportError(dp, type, code, 0);
//					DimManager::print_date_time();
//					cout << "Wrong type for DP: " << dp << endl;
				}
			}
			else
			{
				float_double = *(float *)data;
				ret_size = sizeof(float);
			}
			if(!dpPtr->copyData(&float_double, sizeof(double), compare, save))
			{
				dpPtr->setWriteType(type);
				dpPtr->setWriteFlag();
				setWriteFlag();
			}
//			setDPValue(dp,"",float_double);
			break;
		case DIM_CHAR_ARRAY:
			if(n_items_of_code <= 0)
			{
				ret = getItemCode(codes, code, n);
			}
			else
			{
				n = n_items_of_code;
				n_items_of_code = 0;
				ret = 1;
			}
//			ret = getItemCode(codes, code, n);
			if((ret) & (code != 'C'))
			{
				dpPtr->reportError(dp, type, code, 0);
//				DimManager::print_date_time();
//				cout << "Wrong type for DP: " << dp << endl;
			}
			if(!n)
			{
				ret = checkItemCode(codes, code, n);
				if(ret)
				{
					dpPtr->reportError(dp, type, code, 1);
//					DimManager::print_date_time();
//						cout << "Dynamic item must be at the end - DP: " << dp << endl;
				}
				ret_size = size;
				n = size/sizeof(char);
			}
			else
				ret_size = n * sizeof(char);
//DimManager::print_date_time_detailed();
//cout<< "got DYNCHAR " << ((char *)data)[0] << ((char *)data)[1] << ((char *)data)[2] << endl;
			if(!dpPtr->copyData((int *)data, ret_size, compare, save))
			{
				dpPtr->setWriteType(type);
				dpPtr->setWriteItems(n);
				dpPtr->setWriteFlag();
				setWriteFlag();
			}
//			setDPValue(dp,"",(int *)data,size/sizeof(int));
//			ret_size = size;
			break;
		case DIM_STRING_ARRAY:
			ret = getItemCode(codes, code, n);
			if((ret) && (code != 'C'))
			{
				dpPtr->reportError(dp, type, code, 0);
//				DimManager::print_date_time();
//					cout << "Wrong type for DP: " << dp << endl;
			}
			if(!n)
			{
				ret = checkItemCode(codes, code, n);
				if(ret)
				{
					dpPtr->reportError(dp, type, code, 1);
//					DimManager::print_date_time();
//						cout << "Dynamic item must be at the end - DP: " << dp << endl;
				}
				ret_size = size;
			}
			else
				ret_size = n;
			data_ptr = (char *)data;
			n_items = 0;
			aux_size = 0;
//			if(data_ptr[0])
//				n_items = 1;
//			aux_size = strlen((char *)data_ptr)+1;
			if(strchr(data_ptr,'\n'))
			{
				while(data_ptr = strchr(data_ptr,'\n'))
				{
//					n_items++;
					*(data_ptr++) = '\0';
				}
//				data_ptr[strlen((char *)data_ptr)+1] = '\0';
			}
			data_ptr = (char *)data;
			tot = ret_size;
			while(tot > 0)
			{
//				if(!(*data_ptr))
//					break;
				n = strlen(data_ptr) +1;
				data_ptr += n;
				aux_size += n;
				tot -= n;
				n_items++;
			}
			if(!dpPtr->copyData((char *)data, aux_size, compare, save))
			{
				dpPtr->setWriteType(type);
				dpPtr->setWriteItems(n_items);
				dpPtr->setWriteFlag();
				setWriteFlag();
			}
//			setDPValue(dp,"",ptr_arr, n);
			break;
		case DIM_INT_ARRAY:
		case DIM_UINT_ARRAY:
		case DIM_BITFIELD_ARRAY:
			if(n_items_of_code <= 0)
			{
				ret = getItemCode(codes, code, n);
			}
			else
			{
				n = n_items_of_code;
				n_items_of_code = 0;
				ret = 1;
			}
//			ret = getItemCode(codes, code, n);
			if((ret) && (code != 'I') && (code != 'S'))
			{
				dpPtr->reportError(dp, type, code, 0);
//				DimManager::print_date_time();
//				cout << "Wrong type for DP: " << dp << endl;
			}

			conv_int = sizeof(int);
			if(code == 'S')
					conv_int = sizeof(short);
//cout << "size " <<size << ", conv_int "<<conv_int<<endl; 
			if(!n)
			{
				ret = checkItemCode(codes, code, n);
				if(ret)
				{
					dpPtr->reportError(dp, type, code, 1);
//					DimManager::print_date_time();
//						cout << "Dynamic item must be at the end - DP: " << dp << endl;
				}
//				ret_size = size;
				n = size/conv_int;
			}
//			else
//				ret_size = n * sizeof(int);
			ret_size = n * conv_int;
				
//cout << "n " <<n << ", ret_size "<<ret_size<<endl; 
			auxintp = (int *)data;
			if(code == 'S')
			{
				auxintp = new int[n];
				for(i = 0; i < n; i++)
				{
					auxintp[i] = (int)(((short *)data)[i]);
//cout << "int " <<auxintp[i] << ", short "<<((short *)data)[i]<<endl; 

				}
			}
			if(!dpPtr->copyData(auxintp, n*sizeof(int), compare, save))
			{
				dpPtr->setWriteType(type);
				dpPtr->setWriteItems(n);
				dpPtr->setWriteFlag();
				setWriteFlag();
			}
			if(code == 'S')
				delete[] auxintp;
//			setDPValue(dp,"",(int *)data,size/sizeof(int));
//			ret_size = size;
			break;
		case DIM_TIME_ARRAY:
			if(n_items_of_code <= 0)
			{
				ret = getItemCode(codes, code, n);
			}
			else
			{
				n = n_items_of_code;
				n_items_of_code = 0;
				ret = 1;
			}
//			ret = getItemCode(codes, code, n);
			if((ret) & (code != 'I'))
			{
				dpPtr->reportError(dp, type, code, 0);
//				DimManager::print_date_time();
//				cout << "Wrong type for DP: " << dp << endl;
			}
			if(!n)
			{
				ret = checkItemCode(codes, code, n);
				if(ret)
				{
					dpPtr->reportError(dp, type, code, 1);
//					DimManager::print_date_time();
//						cout << "Dynamic item must be at the end - DP: " << dp << endl;
				}
				ret_size = size;
				n = size/sizeof(int);
			}
			else
				ret_size = n * sizeof(int);
			if(!dpPtr->copyData((int *)data, ret_size, compare, save))
			{
				dpPtr->setWriteType(type);
				dpPtr->setWriteItems(n);
				dpPtr->setWriteFlag();
				setWriteFlag();
			}
//			setDPValue(dp,"",(int *)data,size/sizeof(int));
//			ret_size = size;
			break;
		case DIM_FLOAT_ARRAY:
			if(n_items_of_code <= 0)
			{
				ret = getItemCode(codes, code, n);
			}
			else
			{
				n = n_items_of_code;
				n_items_of_code = 0;
				ret = 1;
			}
//			ret = getItemCode(codes, code, n);
			if((ret) & (code != 'F'))
			{
				if( code == 'D')
				{
//					DimManager::print_date_time();
//					cout << "Converting Doubles to Floats: " << dp << endl;
					conv_d = 1;
				}
				else
				{
					dpPtr->reportError(dp, type, code, 0);
//					DimManager::print_date_time();
//					cout << "Wrong type for DP: " << dp << endl;
				}
			}
			if(!n)
			{
				ret = checkItemCode(codes, code, n);
				if(ret)
				{
					dpPtr->reportError(dp, type, code, 1);
//					DimManager::print_date_time();
//						cout << "Dynamic item must be at the end - DP: " << dp << endl;
				}
//				ret_size = size;
				if(conv_d)
				{
					n = size/sizeof(double);
//					ret_size /= 2;
				}
				else
				{
					n = size/sizeof(float);
				}
			}
			if(conv_d)
			{
				auxdata = (double *)data;
				ret_size = n * sizeof(double);
			}
			else
			{
				auxdata = new double[n];
				for(i = 0; i < n; i++)
				{
					auxdata[i] = ((float *)data)[i];
				}
				ret_size = n * sizeof(float);
			}
			if(!dpPtr->copyData(auxdata, n * sizeof(double), compare, save))
			{
				dpPtr->setWriteType(type);
				dpPtr->setWriteItems(n);
				dpPtr->setWriteFlag();
				setWriteFlag();
			}
			if(!conv_d)
				delete[] auxdata;
//			setDPValue(dp,"",(double *)auxdata,ret_size/sizeof(double));
//			ret_size = size;
			break;
		case DIM_BOOL_ARRAY:
			if(n_items_of_code <= 0)
			{
				ret = getItemCode(codes, code, n);
			}
			else
			{
				n = n_items_of_code;
				n_items_of_code = 0;
				ret = 1;
			}
//			ret = getItemCode(codes, code, n);
			conv_bool = 4;
			if((ret) & (code != 'I'))
			{
				if( code == 'C')
				{
					conv_bool = 1;
				}
				else if( code == 'S')
				{
					conv_bool = 2;
				}
//				else if( code == 'I')
//				{
//					conv_bool = 4;
//				}
				else
				{
					dpPtr->reportError(dp, type, code, 0);
//					DimManager::print_date_time();
//					cout << "Wrong type for DP: " << dp << endl;
				}
			}
			if(!n)
			{
				ret = checkItemCode(codes, code, n);
				if(ret)
				{
					dpPtr->reportError(dp, type, code, 1);
//					DimManager::print_date_time();
//						cout << "Dynamic item must be at the end - DP: " << dp << endl;
				}
//				ret_size = size;
				n = size / conv_bool;
			}
			ret_size = n * conv_bool;
				
			auxbitp = new bit[n];
			for(i = 0; i < n; i++)
			{
				if(conv_bool == 1)
					auxbitp[i] = (bit)(((char *)data)[i]);
				else if(conv_bool == 2)
					auxbitp[i] = (bit)(((short *)data)[i]);
				else if (conv_bool == 4)
					auxbitp[i] = (bit)(((int *)data)[i]);
			}
			if(!dpPtr->copyData(auxbitp, n * sizeof(bit), compare, save))
			{
				dpPtr->setWriteType(type);
				dpPtr->setWriteItems(n);
				dpPtr->setWriteFlag();
				setWriteFlag();
			}
			delete[] auxbitp;
//			setDPValue(dp,"",(float *)data,size/sizeof(float));
//			ret_size = size;
			break;
		default:
			dpPtr->reportError(dp, type, code, 2);
//			DimManager::print_date_time();
//			cout << "Type for DP: " << dp << " - Not Implemented" <<endl;
			break;
	}
	return ret_size;
}

int DimObject::check_data(int type, char *dp, int size, char * &codes, DimDpItem *dpPtr)
{
	int ret_size = 0;
	int n, ret;
	static char code;
	static int n_items_of_code = 0;

	switch(type)
	{
		case DIM_STRING:
			ret = getItemCode(codes, code, n);
//cout << ret << " " << codes << " " << code << " " << n << endl;
			if(!ret)
				return 0;
			if(code != 'C')
			{
				dpPtr->reportError(dp, type, code, 0);
//				DimManager::print_date_time();
//					cout << "Wrong type for DP: " << dp << endl;
			}
			if(n)
				ret_size = n;
			else
				ret_size = size;
			break;
		case DIM_CHAR:
			if(n_items_of_code <= 0)
			{
				ret = getItemCode(codes, code, n);
				if(!ret)
					return 0;
				if(!n) 
					n = 1;
				n_items_of_code = n;
			}
			n_items_of_code--;
			if(code != 'C')
			{
				dpPtr->reportError(dp, type, code, 0);
//				DimManager::print_date_time();
//					cout << "Wrong type for DP: " << dp << endl;
			}
			ret_size = sizeof(char);
			break;
		case DIM_BITFIELD:
			if(n_items_of_code <= 0)
			{
				ret = getItemCode(codes, code, n);
				if(!ret)
					return 0;
				if(!n) 
					n = 1;
				n_items_of_code = n;
			}
			n_items_of_code--;
			if(code != 'I')
			{
				dpPtr->reportError(dp, type, code, 0);
//				DimManager::print_date_time();
//					cout << "Wrong type for DP: " << dp << endl;
			}
			ret_size = sizeof(bitset);
			break;
		case DIM_BOOL:
			if(n_items_of_code <= 0)
			{
				ret = getItemCode(codes, code, n);
				if(!ret)
					return 0;
				if(!n) 
					n = 1;
				n_items_of_code = n;
			}
			n_items_of_code--;
			switch(code)
			{
			case 'I':
				ret_size = sizeof(int);
				break;
			case 'S':
				ret_size = sizeof(short);
				break;
			case 'C':
				ret_size = sizeof(char);
				break;
			default:
				dpPtr->reportError(dp, type, code, 0);
//				DimManager::print_date_time();
//				cout << "Wrong type for DP: " << dp << endl;
				break;
			}
			break;
		case DIM_INTEGER:
		case DIM_UINTEGER:
		case DIM_TIME:
			if(n_items_of_code <= 0)
			{
				ret = getItemCode(codes, code, n);
				if(!ret)
					return 0;
				if(!n) 
					n = 1;
				n_items_of_code = n;
			}
			n_items_of_code--;
			if(code != 'I')
			{
				dpPtr->reportError(dp, type, code, 0);
//				DimManager::print_date_time();
//					cout << "Wrong type for DP: " << dp << endl;
			}
			ret_size = sizeof(int);
			break;
		case DIM_FLOAT:
			if(n_items_of_code <= 0)
			{
				ret = getItemCode(codes, code, n);
				if(!ret)
					return 0;
				if(!n) 
					n = 1;
				n_items_of_code = n;
			}
			n_items_of_code--;
			switch(code)
			{
			case 'F':
				ret_size = sizeof(float);
				break;
			case 'D':
				ret_size = sizeof(double);
				break;
			default:
				dpPtr->reportError(dp, type, code, 0);
//				DimManager::print_date_time();
//				cout << "Wrong type for DP: " << dp << endl;
				break;
			}
			break;
		case DIM_STRING_ARRAY:
			ret = getItemCode(codes, code, n);
			if(!ret)
				return 0;
			if(code != 'C')
			{
				dpPtr->reportError(dp, type, code, 0);
//				DimManager::print_date_time();
//					cout << "Wrong type for DP: " << dp << endl;
			}
			if(!n)
			{
				ret = checkItemCode(codes, code, n);
				if(ret)
				{
					dpPtr->reportError(dp, type, code, 1);
//					DimManager::print_date_time();
//						cout << "Dynamic item must be at the end - DP: " << dp << endl;
				}
				ret_size = size;
			}
			else
				ret_size = n;
			break;
		case DIM_CHAR_ARRAY:
			if(n_items_of_code <= 0)
			{
				ret = getItemCode(codes, code, n);
				if(!ret)
					return 0;
			}
			else
			{
				n = n_items_of_code;
				n_items_of_code = 0;
			}
			if(code != 'C')
			{
				dpPtr->reportError(dp, type, code, 0);
//				DimManager::print_date_time();
//				cout << "Wrong type for DP: " << dp << endl;
			}
			if(!n)
			{
				ret = checkItemCode(codes, code, n);
				if(ret)
				{
					dpPtr->reportError(dp, type, code, 1);
//					DimManager::print_date_time();
//						cout << "Dynamic item must be at the end - DP: " << dp << endl;
				}
				ret_size = size;
			}
			else
				ret_size = n * sizeof(char);
			break;
		case DIM_INT_ARRAY:
		case DIM_UINT_ARRAY:
		case DIM_BITFIELD_ARRAY:
		case DIM_TIME_ARRAY:
			if(n_items_of_code <= 0)
			{
				ret = getItemCode(codes, code, n);
				if(!ret)
					return 0;
			}
			else
			{
				n = n_items_of_code;
				n_items_of_code = 0;
			}
			if(code != 'I')
			{
				dpPtr->reportError(dp, type, code, 0);
//				DimManager::print_date_time();
//				cout << "Wrong type for DP: " << dp << endl;
			}
			if(!n)
			{
				ret = checkItemCode(codes, code, n);
				if(ret)
				{
					dpPtr->reportError(dp, type, code, 1);
//					DimManager::print_date_time();
//						cout << "Dynamic item must be at the end - DP: " << dp << endl;
				}
				ret_size = size;
			}
			else
				ret_size = n * sizeof(int);
			break;
		case DIM_BOOL_ARRAY:
			if(n_items_of_code <= 0)
			{
				ret = getItemCode(codes, code, n);
				if(!ret)
					return 0;
			}
			else
			{
				n = n_items_of_code;
				n_items_of_code = 0;
			}
			if(!n)
			{
				ret = checkItemCode(codes, code, n);
				if(ret)
				{
					dpPtr->reportError(dp, type, code, 1);
//					DimManager::print_date_time();
//						cout << "Dynamic item must be at the end - DP: " << dp << endl;
				}
				ret_size = size;
			}
			else
				ret_size = 0;
			switch(code)
			{
			case 'I':
				if(!ret_size)
					ret_size = n * sizeof(int);
				break;
			case 'S':
				if(!ret_size)
					ret_size = n * sizeof(short);
				break;
			case 'C':
				if(!ret_size)
					ret_size = n * sizeof(char);
				break;
			default:
				dpPtr->reportError(dp, type, code, 0);
//				DimManager::print_date_time();
//				cout << "Wrong type for DP: " << dp << endl;
				break;
			}
			break;
		case DIM_FLOAT_ARRAY:
			if(n_items_of_code <= 0)
			{
				ret = getItemCode(codes, code, n);
				if(!ret)
					return 0;
			}
			else
			{
				n = n_items_of_code;
				n_items_of_code = 0;
			}
			if(!n)
			{
				ret = checkItemCode(codes, code, n);
				if(ret)
				{
					dpPtr->reportError(dp, type, code, 1);
//					DimManager::print_date_time();
//						cout << "Dynamic item must be at the end - DP: " << dp << endl;
				}
				ret_size = size;
			}
			else
				ret_size = 0;
			switch(code)
			{
			case 'F':
				if(!ret_size)
					ret_size = n * sizeof(float);
				break;
			case 'D':
				if(!ret_size)
					ret_size = n * sizeof(double);
				break;
			default:
				dpPtr->reportError(dp, type, code, 0);
//				DimManager::print_date_time();
//				cout << "Wrong type for DP: " << dp << endl;
				break;
			}
			break;
		default:
			dpPtr->reportError(dp, type, code, 2);
//			DimManager::print_date_time();
//			cout << "Type for DP: " << dp << " - Not Implemented" <<endl;
			break;
	}
	return ret_size;
}



int DimObject::write_data_differ()
{
int i, typ, index, n, size, *sizes;
char *data_ptr, **ptr_arr, format[MAX_DIM_NAME]; 
char *code_ptr, *name_ptr;
DimDpItem *dpPtr;
ServiceItem *serviceItem;
int many_instances = 0, clear_flag = 1;

	if(!isServer())
	{
		if(isCmnd())
		{
			size = 0;
			if(!itsMergeFlag)
			{
				DISABLE_AST
				code_ptr = itsFormat;
//				if(itsFormat)
//cout << "Format = "<< itsFormat << endl;
//				else
//					cout << "No Format!!!"<< endl;
				name_ptr = itsDpItemNames;
				sizes = new int[itsNTypes];
				for(i = 0; i < itsNTypes; i++)
				{
					dpPtr = itsDpItemPtrs[i];
					if(dpPtr->getFileFlag())
						dpPtr->copyFileData();
					sizes[i] = check_data(itsTypes[i], name_ptr, 
						dpPtr->getWriteSize(), code_ptr, dpPtr);
// Eric's debug
//				{
//					void *cmd;
//					if((strstr(name_ptr,"Gaudi")) && (strstr(name_ptr,".Command.Actual.Value")) )
//					{
//						cmd = dpPtr->getWriteData();
//						DimManager::print_date_time_detailed();
//						cout << "Sending  "<< name_ptr << " = " << (char *)cmd << endl;
//					}
//					else
//					{
//						DimManager::print_date_time_detailed();
//						cout << "Sending  "<< name_ptr << " size = " << sizes[i] << endl;
//					}
//				}
					size += sizes[i];
					name_ptr += strlen(name_ptr)+1;
				}
				if(!size)
				{
					delete[] sizes;
					ENABLE_AST
					return(1);
				}
				copyData(0 ,size, 0);
				size = 0;
				for(i = 0; i < itsNTypes; i++)
				{
					dpPtr = itsDpItemPtrs[i];
					if(sizes[i])
					{
						copyData(dpPtr->getWriteData(),sizes[i], size);
						size += sizes[i];
					}
				}
				delete[] sizes;
//				char *ptr = (char *)getWriteData();
//				cout << "**************** sending command " << *(int *)getWriteData() << endl;
				if(itsRPCCommand)
				{
					itsRPCBusy = 1;
				}
// here
//				DimManager::print_date_time_detailed();
//				cout << "sent Command "<< getDimName() << " " << (char *)getWriteData() << endl;
				sendCommandNB(getDimName(),(char *)getWriteData(), size);
//				dic_cmnd_service(getDimName(),(char *)getWriteData(), size);
				ENABLE_AST
			}
			else
			{
				for(i = 0; i < itsNTypes; i++)
				{
					if(itsMergeIndexes[i])
					{
						dpPtr = itsDpItemPtrs[i];
						copyData(dpPtr->getWriteData(),dpPtr->getWriteSize(), size); 
						size += dpPtr->getWriteSize();
						sendCommandNB(getDimName(),(char *)getWriteData(), size);
					}
				}
			}
			itsManager->setDispatchFlag();
//			cout << "dispatchFlag set" << endl;
			return(1);
		}
	}
	else
	{
		if(!isCmnd())
		{
			size = 0;
			for(i = 0; i < itsNTypes; i++)
			{
				dpPtr = itsDpItemPtrs[i];
				size += dpPtr->getWriteSize();
			}
			copyData(0 ,size, 0);
			size = 0;
			for(i = 0; i < itsNTypes; i++)
			{
				dpPtr = itsDpItemPtrs[i];
				copyData(dpPtr->getWriteData(),dpPtr->getWriteSize(), size); 
				size += dpPtr->getWriteSize();
			}
			if(itsInit == itsNTypes)
			{
				getDataFormat(format);
				itsService = new DimService(getDimName(),format,(char *)getWriteData(),
					size);
				itsService->setQuality(-1);
				itsInit++;
			}
			else
			{
				int clientId[2];
				CmndItem *item;
				void *addr;
				int size1, id;

				if(itsRPCCommand)
				{
//dim_print_date_time();
//cout << "updating value" << endl;
					if(itsRPCCommand->getRPCTimeout() >= 0)
					{
						clientId[0] = itsRPCCommand->getLastClientId();
						clientId[1] = 0;
						itsService->setQuality(1);
						itsService->selectiveUpdateService(
							(char *)getWriteData(),size, clientId);
					}
					itsRPCCommand->clearRPCBusy();
					itsRPCCommand->clearRPCTimeout();
					itsRPCCommand->DimTimer::stop();

					item = (CmndItem *)itsRPCCommand->cmndList.getHead();
					if(item)
					{
						item->getCmndData(addr, size1, id);
						itsRPCCommand->handleCommand(addr, size1, id);
						itsRPCCommand->cmndList.remove(item);
//CG check
						delete item;
					}

				}
				else
				{
					itsService->updateService((char *)getWriteData(),size);
				}
			}
			itsManager->setDispatchFlag();
//			cout << "dispatchFlag set" << endl;
			return(1);
		}
	}
	for(i = 0; i < itsNTypes; i++)
	{
		dpPtr = itsDpItemPtrs[i];
		
		if(dpPtr->getWriteFlag())
		{
			typ = dpPtr->getWriteType();
			many_instances = 0;
			if(serviceItem = (ServiceItem *)(dpPtr->serviceList.getHead()))
			{

// here
//				while(serviceItem)
//				{
					switch(typ)
					{
						case DIM_STRING:

// Eric's debug
/*
				{
					char *name_ptr;
					char *ptr;

					name_ptr= dpPtr->getWriteDp();
					ptr = (char *)serviceItem->getWriteData();
					if((strstr(name_ptr,"Gaudi")) && (strstr(name_ptr,".Status.Actual.Value")) )
					{
						DimManager::print_date_time_detailed();
						cout << "Setting DP " << name_ptr << " = " << ptr << endl;
					}
				}
*/
							setDPValue(dpPtr->getWriteDp(),
								(char *)serviceItem->getWriteData());
							break;
						case DIM_CHAR:
							setDPValue(dpPtr->getWriteDp(),
								*(char *)serviceItem->getWriteData());
							break;
						case DIM_BITFIELD:
							setDPValue(dpPtr->getWriteDp(),
								*(bitset *)serviceItem->getWriteData());
							break;
						case DIM_BOOL:
							setDPValue(dpPtr->getWriteDp(),
								*(bit *)serviceItem->getWriteData());
							break;
						case DIM_INTEGER:
							setDPValue(dpPtr->getWriteDp(),
								*(int *)serviceItem->getWriteData());
//{
//void *ptr;
//ptr = serviceItem->getWriteData();
//DimManager::print_date_time_detailed();
//cout<< "setting INT " << dpPtr->getWriteDp() << " : "<< *((int *)ptr) << endl;
//}
							break;
						case DIM_TIME:
							setDPValue(dpPtr->getWriteDp(),
								*(time_t *)serviceItem->getWriteData());
							break;
						case DIM_UINTEGER:
							setDPValue(dpPtr->getWriteDp(),
								*(unsigned int *)serviceItem->getWriteData());
							break;
						case DIM_FLOAT:
//							cout << "Setting " << *(double *)serviceItem->getWriteData() << endl;
							setDPValue(dpPtr->getWriteDp(),
								*(double *)serviceItem->getWriteData());
							break;
						case DIM_STRING_ARRAY:
							n = serviceItem->getWriteItems();
							ptr_arr = new char *[n];
							data_ptr = (char *)serviceItem->getWriteData();
							index = 0;
							while (index < n)
							{
								ptr_arr[index++] = data_ptr;
								data_ptr += strlen((char *)data_ptr)+1;
							}
							setDPValue(dpPtr->getWriteDp(),ptr_arr,n);
							delete[] ptr_arr;
							break;
						case DIM_CHAR_ARRAY:
							n = serviceItem->getWriteItems();
							setDPValue(dpPtr->getWriteDp(),
								(char *)serviceItem->getWriteData(), n);
//ptr = serviceItem->getWriteData();
//DimManager::print_date_time_detailed();
//cout<< "setting DYNCHAR " << ((char *)ptr)[0] << ((char *)ptr)[1] << ((char *)ptr)[2] << endl;
							break;
						case DIM_INT_ARRAY:
							n = serviceItem->getWriteItems();
							setDPValue(dpPtr->getWriteDp(),
								(int *)serviceItem->getWriteData(), n);
//DimManager::print_date_time_detailed();
//cout << "PVSS writing Service " << *(int *)serviceItem->getWriteData() << endl;
							break;
						case DIM_TIME_ARRAY:
							n = serviceItem->getWriteItems();
							setDPValue(dpPtr->getWriteDp(),
								(time_t *)serviceItem->getWriteData(), n);
							break;
						case DIM_UINT_ARRAY:
							n = serviceItem->getWriteItems();
							setDPValue(dpPtr->getWriteDp(),
								(unsigned int *)serviceItem->getWriteData(), n);
							break;
						case DIM_BITFIELD_ARRAY:
							n = serviceItem->getWriteItems();
							setDPValue(dpPtr->getWriteDp(),
								(bitset *)serviceItem->getWriteData(), n);
							break;
						case DIM_BOOL_ARRAY:
							n = serviceItem->getWriteItems();
							setDPValue(dpPtr->getWriteDp(),
								(bit *)serviceItem->getWriteData(), n);
							break;
						case DIM_FLOAT_ARRAY:
							n = serviceItem->getWriteItems();
							setDPValue(dpPtr->getWriteDp(),
								(double *)serviceItem->getWriteData(), n);
							break;
						default:
							DimManager::print_date_time();
							cout << "Type for DP: " << dpPtr->getWriteDp() << " - Not Implemented" <<endl;
							break;
					}
//					serviceItem = (ServiceItem *)(dpPtr->serviceList.getNext());
//					if(serviceItem)
//					{
//						if(!many_instances)
//						{
//							many_instances = 1;
//							getManId()->sendDPSetList();
//							getManId()->clearDPSetList();
//cout << "+++ - More than one instance for " << dpPtr->getWriteDp() << endl;
//						}
//					}

//					else
//					{
//						if(!many_instances)
//						{
//cout << "1 - Only one instance for " << dpPtr->getWriteDp() << endl;
//						}
//					}
//				}
				serviceItem = (ServiceItem *)(dpPtr->serviceList.getNext());
				if(serviceItem)
				{
					clear_flag = 0;
//					getManId()->sendDPSetList();
//					getManId()->clearDPSetList();
				}
			}
//			do
//			{
				serviceItem = (ServiceItem *)(dpPtr->serviceList.removeHead());
//				if(!serviceItem)
//					break;
				if(serviceItem)
					delete serviceItem;
//			} while(serviceItem);
		}
		if(clear_flag)
			dpPtr->clearWriteFlag();
	}
	itsManager->setDispatchFlag();
//	cout << "dispatchFlag set" << endl;
	return clear_flag;
//	return 1;
}

void DimObject::set_invalid_bits(char *dp, int n, bit invalid, char quality)
{
	char qf;
	int i;
	char *dp_ptr;
	DimDpItem *dpPtr;
	int flag;


	dp_ptr = dp;
	qf = quality;
//	if(invalid)
//		qf = 0;
	flag = 0;
	if(invalid != itsInvalid)
		flag |= 0x1;
	if(qf != itsQuality)
		flag |= 0x2;
	if(flag)
	{
		for(i = 0; i < itsNTypes; i++)
		{
			dpPtr = itsDpItemPtrs[i];
			if(flag & 0x3)
			{
				dpPtr->setBit(7, invalid);
				qf &= 0xf;
				if(invalid || qf)
					dpPtr->setInvalid(1);
				else
					dpPtr->setInvalid(0);
				flag |= 0x1;
			}
			if(flag & 0x2)
			{
				dpPtr->setBit(0, qf & 0x1);
				dpPtr->setBit(1, qf & 0x2);
				dpPtr->setBit(2, qf & 0x4);
				dpPtr->setBit(3, qf & 0x8);
			}
		}
		setWriteInvFlag(flag);
		itsInvalid = invalid;
		itsQuality = qf;
	}
}

int DimObject::set_invalid_bits_differ()
{
int i;
DimDpItem *dpPtr;
//DpIdValueList list;
int flag;

	flag = getWriteInvFlag();

	for(i = 0; i < itsNTypes; i++)
	{
		dpPtr = itsDpItemPtrs[i];
		if(flag & 0x2)
		{
/*
			addDPAttr(list,dpPtr->getWriteDpName(),"",":_original.._userbit8",
				dpPtr->getBit(0));
			addDPAttr(list,dpPtr->getWriteDpName(),"",":_original.._userbit7",
				dpPtr->getBit(1));
			addDPAttr(list,dpPtr->getWriteDpName(),"",":_original.._userbit6",
				dpPtr->getBit(2));
			addDPAttr(list,dpPtr->getWriteDpName(),"",":_original.._userbit5",
				dpPtr->getBit(3));
*/
			setDPAttr(dpPtr->getWriteDp(),ATTR_USER8,
				dpPtr->getBit(0));
			setDPAttr(dpPtr->getWriteDp(),ATTR_USER7,
				dpPtr->getBit(1));
			setDPAttr(dpPtr->getWriteDp(),ATTR_USER6,
				dpPtr->getBit(2));
			setDPAttr(dpPtr->getWriteDp(),ATTR_USER5,
				dpPtr->getBit(3));
		}
		if(flag & 0x1)
		{
/*
			addDPAttr(list,dpPtr->getWriteDpName(),"",":_original.._userbit1",
				dpPtr->getBit(7));
			addDPAttr(list,dpPtr->getWriteDpName(),"",":_original.._aut_inv",
				dpPtr->getInvalid());
*/
			setDPAttr(dpPtr->getWriteDp(),ATTR_USER1,
				dpPtr->getBit(7));
			setDPAttr(dpPtr->getWriteDp(),ATTR_INV,
				dpPtr->getInvalid());

		}
	}
//	sendDPAttrs(list);

	return 1;
}

void DimObject::infoHandler()
{
	char *str, *name_ptr, *ptr, *format, *code_ptr;
	void *buffer;
	int size, ret_size, do_it;
	int i, compare, save;
	DimInfo *info;
	char qf;
	bit invalid;
	int secs;
	int millies;
	time_t tsecs;
//	time_t thistime;

	invalid = 0;
	info = getInfo();
//	DimManager::print_date_time_detailed();
//	cout << "Got data from " << info->getName() << endl;

	str = (char *)info->getData();
	qf = 0;
	tsecs = (time_t)0;
	setStime(tsecs, 0);

	do_it = 1;
	if(itsRPCCommand)
	{
		do_it = itsRPCCommand->getRPCBusy();
		itsRPCCommand->clearRPCBusy();
	}
	if(!strcmp(str, "__DIM_NO_LINK__"))
		invalid = 1;
	else
	{
		if(do_it)
		{
			format = 0;
			size = info->getSize();
			buffer = info->getData();

//			DimManager::print_date_time_detailed();
//			cout << "got Service" << *(float *)buffer << endl;

			if(!memcmp(buffer,itsNoLink,itsNoLinkSize))
				invalid = 1;
			else
			{
				format = info->getFormat();
				if((itsStamped == 1) || (itsStamped == 3))
					qf = (char)info->getQuality();
				if((itsStamped == 2) || (itsStamped == 3))
				{
					secs = info->getTimestamp();
					millies = info->getTimestampMillisecs();
					tsecs = (time_t)secs;
					setStime(tsecs, millies);
				}
			}
			name_ptr = itsDpItemNames;
			ptr = (char *)buffer;
			code_ptr = format;
// Due to a long lasting bug, we will not do old/new comparison anymore
// Only -2 will trigger an old/new comparison
//			compare = 1;
//			if(itsTime < 0)
//				compare = 0;
//			else if(itsTime > 0)
//			{
//				thistime = time((time_t *) 0);
//				if(((int)thistime - itsLastTime) >= itsTime)
//				{
//					compare = 0;
//					itsLastTime = thistime;
//				}
//			}

			compare = 0;
			save = 0;
			if(itsTime <= -2)
			{
				compare = 1;
				save = 1;
			}

			for(i = 0; (i < itsNTypes) /*&& size*/ ; i++)
			{
				ret_size = write_data(itsTypes[i], name_ptr, (void *)ptr, 
					size, code_ptr, itsDpItemPtrs[i], compare, save);
// Eric's debug
//				{
//					if((strstr(name_ptr,"Gaudi")) && (strstr(name_ptr,".Status.Actual.Value")) )
//					{
////						DimManager::print_date_time_detailed();
////						cout << "Received " << name_ptr << " = " << (char *)ptr << endl;
//					}
//					else
//					{
//						DimManager::print_date_time_detailed();
//						cout << "Received " << name_ptr << " size = " << ret_size << endl;
//					}
//				}
				ptr += ret_size;
				size -= ret_size;
				name_ptr += strlen(name_ptr)+1;
				if(!size) break;
			}
		}
	}
	set_invalid_bits(itsDpItemNames, itsNTypes, invalid, qf);
/*
	write_data_differ();
	clearWriteFlag();
	set_invalid_bits_differ();
	clearWriteInvFlag();
*/
	itsManager->setDispatchFlag();
//	cout << "dispatchFlag set" << endl;

}

void DimObject::commandHandler()
{

	DimCommand *cmd;
	CmndItem *item;
	void *addr;
	int size;
	int id;

	cmd = getCommand();
#ifdef DEBUG
	DimManager::print_date_time();
	cout << "*** Received Server COMMAND "<< getDimName() <<
		" (DP " << itsDpItemNames << ") - ";
#endif
	id = DimServer::getClientId();
	size = cmd->getSize();
	addr = cmd->getData();
	if(itsRPCCommand)
	{
		if(itsRPCBusy)
		{
			if(id != itsLastClientId)
			{
				item = new CmndItem(addr, size, id);
				cmndList.add(item);
			}
			return;
		}
	}
	handleCommand(addr, size, id);
}

void DimObject::handleCommand(void *addr, int size, int id)
{

	char *name_ptr, *ptr, format[MAX_DIM_NAME], *code_ptr;
	int i, ret_size, tout;

	if(itsRPCCommand)
	{
		itsRPCBusy = 1;
		tout = itsRPCCommand->itsService->getTimeout(id);
		itsRPCTimeout = tout;
		if(tout <= 0)
			tout = 60;
//dim_print_date_time();
//cout << "Starting timer " << tout << endl;
		if(tout)
			DimTimer::start(tout);
	}
	itsLastClientId = id;
	getDataFormat(format);
	name_ptr = itsDpItemNames;
	ptr = (char *)addr;
	code_ptr = format;
	for(i = 0; (i < itsNTypes) && size; i++)
	{
		ret_size = write_data(itsTypes[i], name_ptr, (void *)ptr, 
			size, code_ptr, itsDpItemPtrs[i], 0, 0);
		ptr += ret_size;
		size -= ret_size;
		name_ptr += strlen(name_ptr)+1;
	}
}

void DimObject::timerHandler()
{
	if(itsRPCBusy)
	{
		int clientId[2];
		int data; 
		int size = sizeof(int);
		CmndItem *item;
//		void *addr;
//		int sz;
//		int id;

//dim_print_date_time();
//cout << "timer fired" << endl;
//		clientId[0] = getLastClientId();
//		clientId[1] = 0;
//		itsRPCCommand->itsService->setQuality(-1);
//		itsRPCCommand->itsService->selectiveUpdateService(
//			&data, size, clientId);

//		clearRPCBusy();
		if(itsRPCTimeout > 0)
		{
			itsRPCTimeout = -itsRPCTimeout;
			DimTimer::start(30);
		}
		else if(itsRPCTimeout == 0)
		{
			clientId[0] = getLastClientId();
			clientId[1] = 0;
			itsRPCCommand->itsService->setQuality(-1);
			itsRPCCommand->itsService->selectiveUpdateService(
				&data, size, clientId);
			item = (CmndItem *)cmndList.getHead();
			while(item)
			{
// CG check
				item = (CmndItem *)(cmndList.removeHead());
				delete item;
				item = (CmndItem *)cmndList.getHead();
			};
			clearRPCBusy();
			itsRPCTimeout = 0;
		}
		else if(itsRPCTimeout < 0)
		{
			item = (CmndItem *)cmndList.getHead();
			while(item)
			{
// CG check
				item = (CmndItem *)(cmndList.removeHead());
				delete item;
				item = (CmndItem *)cmndList.getHead();
			};
			clearRPCBusy();
			itsRPCTimeout = 0;
		}

//		item = (CmndItem *)cmndList.getHead();
//		if(item)
//		{
//			item->getCmndData(addr, sz, id);
//			handleCommand(addr, sz, id);
//			itsRPCCommand->cmndList.remove(item);
//		}
	}
/*
	if((!isServer()) && isCmnd())
	{
		if(!itsFormat)
		{
			findFormat();
//			DimObject *obj;
//			if(itsManager->getConfigDp()->getSearchFlag(obj))
//				DimTimer::start(1);
//			else
//			{
//				itsManager->getConfigDp()->setSearchFlag(getDimName(), this);
//				DimTimer::start(10);
//			}
		}
	}
*/
}

void DimObject::copyDataItem(int type, DPItem *dpItem, DimDpItem *dpItemPtr, 
	int print, char *format, int itemIndex)
{
	char *cmnd;
	int cmnd_int, *cmnd_int_arr = 0;
	short cmnd_short, *cmnd_short_arr = 0;
	float cmnd_float, *cmnd_float_arr = 0;
	double cmnd_double, *cmnd_double_arr = 0;
	bit cmnd_bit;
	bitset cmnd_bitset;
	time_t cmnd_time;
	char cmnd_char, *cmnd_char_arr = 0;
	void *cmndptr;
	int i, n, cmndsize, cmndfullsize;
	int format_size;
	char format_type;
	char *cmnd_file = 0;
 
	cmndfullsize = 0;
	format_size = 0;
	format_type = 0;
	if(format)
	{
//		cout << dpItem->getDPItemName() << " " <<format <<" "<< type<< endl;
		format_type = format[0];
		if(format[1] != '\0')
			sscanf(&format[2],"%d",&format_size);
	}
	switch(type)
	{
		case DIM_STRING:
			cmnd = dpItem->getDPItemString();
#ifdef DEBUG
			if(print)
				cout << cmnd << endl;
#endif
			cmndptr = cmnd;
			cmndsize = strlen(cmnd)+1;
			if(format_size != 0)
			{
				cmndfullsize = format_size;
				if(cmndsize > cmndfullsize)
					((char *)cmndptr)[cmndfullsize-1] = '\0';
			}

			if((itsReadFile) && ((itemIndex + 1) == itsNTypes))
			{
				dpItemPtr->setFileFlag();
//DimManager::print_date_time_detailed();
//cout << "Using file: " << cmnd << endl;
/*
				FILE *f;
				int sz, ret = 0;
				struct stat buf;
				
				f = fopen(cmnd,"r");
				if(f != 0)
				{
					ret = fstat(fileno(f), &buf);
					sz = buf.st_size;
					cmnd_file = new char[sz];
					memset(cmnd_file, 0, sz);
					ret = fread(cmnd_file, 1, sz, f);
DimManager::print_date_time_detailed();
cout << "Reading file: " << cmnd << endl;
					fclose(f);
				}
				else
				{
					sz = 1;
					cmnd_file = new char[sz];
					cmnd_file[0] = '\0';
				}
				cmndptr = cmnd_file;
				cmndsize = sz;
			}
			else
			{
				cmndptr = cmnd;
				cmndsize = strlen(cmnd)+1;
				if(format_size != 0)
				{
					cmndfullsize = format_size;
					if(cmndsize > cmndfullsize)
						((char *)cmndptr)[cmndfullsize-1] = '\0';
				}
*/
			}
			break;
		case DIM_LANG_STRING:
			cmnd = dpItem->getDPItemLangString();
#ifdef DEBUG
			if(print)
				cout << cmnd << endl;
#endif
			cmndptr = cmnd;
			cmndsize = strlen(cmnd)+1;
			if(format_size != 0)
			{
				cmndfullsize = format_size;
				if(cmndsize > cmndfullsize)
					((char *)cmndptr)[cmndfullsize-1] = '\0';
			}
			break;
		case DIM_INTEGER:
			cmnd_int = dpItem->getDPItemInt();
#ifdef DEBUG
			if(print)
				cout << cmnd_int << endl;
#endif
			cmndptr = &cmnd_int;
			cmndsize = sizeof(cmnd_int);
			break;
		case DIM_TIME:
			cmnd_time = dpItem->getDPItemTime();
#ifdef DEBUG
			if(print)
				cout << "0x" << hex << cmnd_time << endl;
#endif
			cmndptr = &cmnd_time;
			cmndsize = sizeof(time_t);
			break;
		case DIM_UINTEGER:
			cmnd_int = dpItem->getDPItemUInt();
#ifdef DEBUG
			if(print)
				cout << cmnd_int << endl;
#endif
			cmndptr = &cmnd_int;
			cmndsize = sizeof(cmnd_int);
			break;
		case DIM_BOOL:
			cmnd_bit = dpItem->getDPItemBit();
			if(format_type == 'C')
			{
				cmnd_char = (char)cmnd_bit;
#ifdef DEBUG
				if(print)
					cout << cmnd_char << endl;
#endif
				cmndptr = &cmnd_char;
				cmndsize = sizeof(cmnd_char);
			}
			else if(format_type == 'S')
			{
				cmnd_short = (short)cmnd_bit;
#ifdef DEBUG
				if(print)
					cout << cmnd_short << endl;
#endif
				cmndptr = &cmnd_short;
				cmndsize = sizeof(cmnd_short);
			}
			else
			{
				cmnd_int = (int)cmnd_bit;
#ifdef DEBUG
				if(print)
					cout << cmnd_int << endl;
#endif
				cmndptr = &cmnd_int;
				cmndsize = sizeof(cmnd_int);
			}
			break;
		case DIM_BITFIELD:
			cmnd_bitset = dpItem->getDPItemBitset();
#ifdef DEBUG
			if(print)
				cout << "0x" << hex << cmnd_bitset << endl;
#endif
			cmndptr = &cmnd_bitset;
			cmndsize = sizeof(bitset);
			break;
		case DIM_FLOAT:
			if(format_type == 'D')
			{
				cmnd_double = dpItem->getDPItemDouble();
#ifdef DEBUG
				if(print)
					cout << cmnd_double << endl;
#endif
				cmndptr = &cmnd_double;
				cmndsize = sizeof(cmnd_double);
			}
			else
			{
				cmnd_float = dpItem->getDPItemFloat();
#ifdef DEBUG
				if(print)
					cout << cmnd_float << endl;
#endif
				cmndptr = &cmnd_float;
				cmndsize = sizeof(cmnd_float);
			}
			break;
		case DIM_CHAR:
			cmnd_char = dpItem->getDPItemChar();
#ifdef DEBUG
			if(print)
				cout << cmnd_char << endl;
#endif
			cmndptr = &cmnd_char;
			cmndsize = sizeof(cmnd_char);
			break;
		case DIM_INT_ARRAY:
			n = dpItem->getDPItemValue(cmnd_int_arr);
#ifdef DEBUG
			if(print)
				cout << cmnd_int_arr[0] << "..." << endl;
#endif
			cmndptr = cmnd_int_arr;
			cmndsize = n*sizeof(int);
			if(format_size != 0)
				cmndfullsize = format_size * sizeof(int); 
			break;
		case DIM_UINT_ARRAY:
			n = dpItem->getDPItemValue((unsigned int * &)cmnd_int_arr);
#ifdef DEBUG
			if(print)
				cout << cmnd_int_arr[0] << "..." << endl;
#endif
			cmndptr = cmnd_int_arr;
			cmndsize = n*sizeof(int);
			if(format_size != 0)
				cmndfullsize = format_size * sizeof(int);
			break;
		case DIM_BITFIELD_ARRAY:
			n = dpItem->getDPItemValue((bitset * &)cmnd_int_arr);
#ifdef DEBUG
			if(print)
				cout << cmnd_int_arr[0] << "..." << endl;
#endif
			cmndptr = cmnd_int_arr;
			cmndsize = n*sizeof(bitset);
			if(format_size != 0)
				cmndfullsize = format_size * sizeof(bitset); 
			break;
		case DIM_TIME_ARRAY:
			n = dpItem->getDPItemValue((time_t * &)cmnd_int_arr);
#ifdef DEBUG
			if(print)
				cout << cmnd_int_arr[0] << "..." << endl;
#endif
			cmndptr = cmnd_int_arr;
			cmndsize = n*sizeof(time_t);
			if(format_size != 0)
				cmndfullsize = format_size * sizeof(time_t); 
			break;
		case DIM_BOOL_ARRAY:
			if(format_type == 'C')
			{
				n = dpItem->getDPItemValue((char * &)cmnd_char_arr);
#ifdef DEBUG
				if(print)
					cout << cmnd_char_arr[0] << "..." << endl;
#endif
				cmndptr = cmnd_char_arr;
				cmndsize = n*sizeof(char);
				if(format_size != 0)
					cmndfullsize = format_size * sizeof(char);
			}
			/*
			else if(format_type == 'S')
			{
				n = dpItem->getDPItemValue((short * &)cmnd_short_arr);
#ifdef DEBUG
				if(print)
					cout << cmnd_short_arr[0] << "..." << endl;
#endif
				cmndptr = cmnd_short_arr;
				cmndsize = n*sizeof(short);
				if(format_size != 0)
					cmndfullsize = format_size * sizeof(short);
			}
			*/
			else
			{
				n = dpItem->getDPItemValue((int * &)cmnd_int_arr);
#ifdef DEBUG
				if(print)
					cout << cmnd_int_arr[0] << "..." << endl;
#endif
				cmndptr = cmnd_int_arr;
				cmndsize = n*sizeof(int);
				if(format_size != 0)
					cmndfullsize = format_size * sizeof(int);
			}
			break;
		case DIM_FLOAT_ARRAY:
			if(format_type == 'D')
			{
				n = dpItem->getDPItemValue(cmnd_double_arr);
#ifdef DEBUG
				if(print)
					cout << cmnd_double_arr[0] << "..." << endl;
#endif
				cmndptr = cmnd_double_arr;
				cmndsize = n*sizeof(double);
				if(format_size != 0)
					cmndfullsize = format_size * sizeof(double);
			}
			else
			{
				n = dpItem->getDPItemValue(cmnd_float_arr);
#ifdef DEBUG
				if(print)
					cout << cmnd_float_arr[0] << "..." << endl;
#endif
				cmndptr = cmnd_float_arr;
				cmndsize = n*sizeof(float);
				if(format_size != 0)
					cmndfullsize = format_size * sizeof(float);
			}
			break;
		case DIM_CHAR_ARRAY:
			n = dpItem->getDPItemCharValues(cmnd_char_arr);
#ifdef DEBUG
			if(print)
				cout << cmnd_char_arr[0] << "..." << endl;
#endif
			cmndptr = cmnd_char_arr;
			cmndsize = n*sizeof(char);
			if(format_size != 0)
					cmndfullsize = format_size * sizeof(char);
			break;
		case DIM_STRING_ARRAY:
			n = dpItem->getDPItemValue(cmnd);
#ifdef DEBUG
			if(print)
				cout << cmnd[0] << "..." << endl;
#endif
			cmndptr = cmnd;
			cmndsize = 0;
			for(i = 0; i < n; i++)
			{
				cmndsize += strlen(cmnd)+1;
				cmnd += strlen(cmnd)+1;
			}
			if(format_size != 0)
			{
				cmndfullsize = format_size;
				if(cmndsize > cmndfullsize)
					((char *)cmndptr)[cmndfullsize-1] = '\0';
			}
			break;
		default:
			DimManager::print_date_time();
			cout << "Type for DP: " << dpItemPtr->getWriteDp() << " - Not Implemented" <<endl;
			cmndptr = 0;
			cmndsize = 0;
			break;
	}
	if(!itsMergeFlag)
	{
		if(!cmndfullsize)
		{
			cmndfullsize = cmndsize;
		}
		dpItemPtr->copyDataOut(cmndptr, cmndsize, cmndfullsize);
//		cout << "sending "<<*(int *)cmndptr << endl;
	}
	else
	{
		char *ptr, *ptr1;
		ptr = dpItem->getDPItemName();
		if(!*ptr)
		{
			ptr = dpItem->getDPDpName();
			if(ptr1 = strchr(ptr,':'))
				ptr = ptr1+1;
		}
		dpItemPtr->packData(ptr,type, cmndptr, cmndsize);
	}
	dpItemPtr->setWriteType(type);
//#ifndef WIN32
	if(cmnd_int_arr)
		delete[] cmnd_int_arr;
	if(cmnd_short_arr)
		delete[] cmnd_short_arr;
	if(cmnd_float_arr)
		delete[] cmnd_float_arr;
	if(cmnd_double_arr)
		delete[] cmnd_double_arr;
	if(cmnd_char_arr)
		delete[] cmnd_char_arr;
	if(cmnd_file)
		delete[] cmnd_file;
//#endif
}

void DimObject::getDataFormat(char *format)
{
int i;

	if(itsFormat != 0)
	{
		strcpy(format, itsFormat);
		return;
	}
	strcpy(format,"");
	for(i = 0; i < itsNTypes; i++)
	{

		switch(itsTypes[i])
		{
			case DIM_STRING:
			case DIM_STRING_ARRAY:
				strcat(format,"C;");
				break;
			case DIM_INTEGER:
			case DIM_UINTEGER:
				strcat(format,"I:1;");
				break;
			case DIM_BOOL:
				strcat(format,"I:1;");
				break;
			case DIM_CHAR:
				strcat(format,"C:1;");
				break;
			case DIM_CHAR_ARRAY:
				strcat(format,"C;");
				break;
			case DIM_BITFIELD:
				strcat(format,"I:1;");
				break;
			case DIM_TIME:
				strcat(format,"I:1;");
				break;
			case DIM_FLOAT:
				strcat(format,"F:1;");
				break;
			case DIM_INT_ARRAY:
			case DIM_UINT_ARRAY:
			case DIM_BOOL_ARRAY:
			case DIM_BITFIELD_ARRAY:
			case DIM_TIME_ARRAY:
				strcat(format,"I;");
				break;
			case DIM_FLOAT_ARRAY:
				strcat(format,"F;");
				break;
		}
	}
	format[strlen(format)-1] = '\0';
}

void DimObject::gotDPValue(DPItem *dpItem)
{
	char *itemName, dpname[MAX_DP_NAME];
 	char *name_ptr;
	int i;
	char format[MAX_DIM_NAME], *formatp, *ptr;

	DISABLE_AST

	itemName = dpItem->getDPItemName();
	strcpy(dpname,getDPName());
	if(!dpname[0])
		strcpy(dpname,dpItem->getDPDpName());
	strcat(dpname,itemName);
//DimManager::print_date_time_detailed();
//cout << "got "<< dpname << endl;

	if(isCmnd())
	{			
		if(!itsFormat)
		{
			findFormat();
		}

#ifdef DEBUG
		if(itsInit >= itsNTypes)
		{
			DimManager::print_date_time();
			cout << "*** Sending Client COMMAND "<< getDimName() <<
				" (DP " << itsDpItemNames << ") - ";
		}
#endif
		name_ptr = itsDpItemNames;
		for(i = 0; i < itsNTypes; i++)
		{
			if(!strcmp(name_ptr,dpname))
			{
				itsMergeIndexes[i] = 1;
				copyDataItem(itsTypes[i], dpItem, itsDpItemPtrs[i], 
					itsInit >= itsNTypes, 0, i);
			}
			else
				itsMergeIndexes[i] = 0;
			name_ptr += strlen(name_ptr)+1;
		}
		if(itsInit < itsNTypes)
		{
			itsInit++;
//cout << "First time, discarding" << endl;
		}
		else
		{
//cout << "Setting write flag" << endl;
//			if(itsFormat)
//				write_data_differ();
//			else

			
			setWriteFlag();
		}
//			sendCommandNB(getDimName(),cmndptr,cmndsize);
	}
	if(isServer())
	{
#ifdef DEBUG
		if(itsInit >= itsNTypes)
		{
			DimManager::print_date_time();
			cout << "*** Sending Server SERVICE "<< getDimName() <<
				" (DP " << itsDpItemNames << ") - ";
		}
#endif
		formatp = 0;
		if(itsFormat)
		{
			strcpy(format, itsFormat);
			formatp = format;
		}
		name_ptr = itsDpItemNames;
		for(i = 0; i < itsNTypes; i++)
		{
			if(formatp)
			{
				if(ptr = strchr(formatp, ';'))
				{
					*ptr = '\0';
					ptr++;
				}
			}
			else
				ptr = formatp;
			if(!strcmp(name_ptr,dpname))
			{
				copyDataItem(itsTypes[i], dpItem, itsDpItemPtrs[i], 
					itsInit >= itsNTypes, formatp, i);
			}
			name_ptr += strlen(name_ptr)+1;
			formatp = ptr;
		}
		if(itsInit < itsNTypes)
		{
			itsInit++;
		}
		if(itsInit >= itsNTypes)
		{
			setWriteFlag();
		}
	}
	ENABLE_AST
}

DimManager::DimManager(char *file_name, char *dp_name, int own_system_flag) : 
	ApiManager()
	/*,
	DimCommand(name,"C")
	*/
{
	itsFileName = new char[strlen(file_name)+1];
	strcpy(itsFileName,file_name);
	if(!dp_name[0])
	{
		itsDpName = new char[20];
		strcpy(itsDpName,"fwDimDefaultConfig");
	}
	else
	{
		itsDpName = new char[strlen(dp_name)+1];
		strcpy(itsDpName,dp_name);
	}
	itsFlag = 0;
	itsAliveRate = -1;
	itsLastTime = 0;
	itsExit = 0;
	dnsRpc = new DimRpcInfo("DIS_DNS/SERVICE_INFO","\0");
	setOwnSystemFlag(own_system_flag);
	manStart();
}

void DimManager::gotDpValues()
{
	DimTodoItem *dimItem, *oldDimItem;
	DimObject *obj;
	int done;

	if(dimItem = (DimTodoItem *)todoList.getHead())
	{
		while(dimItem)
		{
			done = 0;
			obj = dimItem->getDimObject();
			if(obj->getWriteFlag())
			{
				if(!obj->isServer())
				{
					if(obj->isCmnd())
					{
						if(obj->hasFormat())
						{
							obj->write_data_differ();
							obj->clearWriteFlag();
							done = 1;
						}
					}
				}
			}
			oldDimItem = dimItem;
			dimItem = (DimTodoItem *)todoList.getNext();
			if(done)
			{
				resetFlag(oldDimItem);
			}
		}
	}
}

void DimManager::manExecute()
{
	DimTodoItem *dimItem, *oldDimItem;
	DimObject *obj;
	int doit = 0;
	char *search;
//	DimRpcInfo rpc("DIS_DNS/SERVICE_INFO","\0");
//	DimBrowser br;
	char str[128];
	int break_flag, n_done = 0;
	time_t gTime;
	bit exit_flag = 0;
	static int send_heart_beat = 1;

//	DimManager::print_date_time_detailed();
//	cout << "PVSS Man execute" << endl;

	gTime = time((time_t *) 0);

	if(send_heart_beat)
	{
		if((gTime - gOldTime) > (MAX_BEFORE_SENDING -1 ))
		{
			gHeartBeat++;
			gOldTime = gTime;
			sprintf(str,"PVSS00dim_%d.heart_beat",itsManId);
			send_heart_beat = itsDp->setDPValue(str,"",gHeartBeat);
		}
	}
	if((itsAliveRate > 0) && ((gTime - itsLastTime) > itsAliveRate))
	{
		itsLastTime = gTime;
		sprintf(str,"%s.ApiInfo.lastUpdate",itsDpName);
		itsDp->setDPTimeValue(str,"");
	}
	if(itsExit)
	{
		sprintf(str,"%s.ApiInfo.manState",itsDpName);
		itsDp->setDPValue(str,"",exit_flag);
		manExit();
		Manager::exit(itsExit);
	}
/*
	if( n = getFlag() )
	{
//		cout << "flag = "<< n << endl;
		
		dimItem = (DimItem *)dimList.getHead();
		while(dimItem)
		{
//			DISABLE_AST
			obj = dimItem->getDimObject();
			if(obj->getWriteFlag())
			{
				obj->write_data_differ();
				obj->clearWriteFlag();
				n_done++;
			}
			if(obj->getWriteInvFlag())
			{
				obj->set_invalid_bits_differ();
				obj->clearWriteInvFlag();
				n_inv_done++;
			}
			dimItem = (DimItem *)dimList.getNext();
//			ENABLE_AST
			if(n_done+n_inv_done > 100)
			{
//				ENABLE_AST
				return;
			}
		}
		if((!n_done) && (!n_inv_done))
			resetFlag();
//		ENABLE_AST
//		cout << "done "<< n_done << " inv done " << n_inv_done << endl;
	}
//	else
//		cout << "no flag"<< endl;
*/
/*
	dimItem = (DimItem *)dimList.getHead();
	while(dimItem)
	{
		obj = dimItem->getDimObject();
		if(type == dimItem->getDimType())
		{
			dimItem->setDimState(0);
		}
		dimItem = (DimItem *)dimList.getNext();
	}
*/
	clearDPSetList();
//cout << "checking" << endl;
	while(dimItem = (DimTodoItem *)todoList.getHead())
	{
		break_flag = 1;
		while(dimItem)
		{
//			DISABLE_AST
			obj = dimItem->getDimObject();
			if(obj->getFindFormatFlag())
			{
				searchDNS(obj->getDimName(), obj);
				break_flag = 0;
			}
			{
			DISABLE_AST
			if(dimItem->getTodoTypeFlag() == 1)
			{
				if(obj->getWriteFlag())
				{
//DimManager::print_date_time_detailed();
//cout << "Writing data for "<< obj->getDimName() << endl;
					if(obj->write_data_differ())
						obj->clearWriteFlag();
					break_flag = 0;
				}
			}
			if(dimItem->getTodoTypeFlag() == 2)
			{
				if(obj->getWriteInvFlag())
				{
					obj->set_invalid_bits_differ();
					obj->clearWriteInvFlag();
					break_flag = 0;
				}
			}
			oldDimItem = dimItem;
			dimItem = (DimTodoItem *)todoList.getNext();
			resetFlag(oldDimItem);
			ENABLE_AST
			}
			n_done++;
			if(n_done >= 1000)
			{
				break_flag = 1;
				break;
			}
		}
		if(break_flag)
			break;
	}
//DimManager::print_date_time_detailed();
//cout << "Calling send "<<endl;
	sendDPSetList();

	if(itsDp)
	{
		DimObject *obj;
		if((search = itsDp->getSearchFlag(obj)))
		{
			searchDNS(search, obj);
/*
			int index, n, i, size;
			char **ptr_arr;
			char *str;

			dnsRpc->setData(search);
			str = dnsRpc->getString();
cout << "Executing " << search << "ret = " << str << endl;

			if(obj == 0)
			{
				size = strlen(str);
				n = 0;
				for(i = 0; i < size; i++)
				{
					if(str[i] == '\n')
					{
						str[i] = '\0';
						n++;
					}
				}
//				n = br.getServices(search);
				ptr_arr = new char *[n];
				index = 0;
				while (index < n)
				{
					ptr_arr[index++] = str;
					str += strlen((char *)str)+1;
				}
				itsDp->setDPValue(".DnsInfo.serviceList",ptr_arr,n);
				delete ptr_arr;
			}
			else
			{
				char *ptr, *ptr1;

				if(ptr = strchr(str,'|'))
				{
					ptr++;
					if(ptr1 = strchr(ptr,'|'))
						*ptr1 = 0;
					if(ptr1 = strchr(ptr,','))
						*ptr1 = 0;
					obj->setFormat(ptr);
				}
			}
*/
			itsDp->clearSearchFlag();
		}
	}
//	DimManager::print_date_time_detailed();
//	cout << " Out of PVSS Man execute" << endl;
}

void DimManager::searchDNS(char *search, DimObject *obj)
{
	int index, n, i, size;
	char **ptr_arr;
	char *str;

//	DimManager::print_date_time_detailed();
//	cout << " Asking DNS: " << search << endl;
	dnsRpc->setData(search);
	str = dnsRpc->getString();

//	DimManager::print_date_time_detailed();
//	cout << " Got DNS answer: " << str << endl;
	if(obj == 0)
	{
		size = strlen(str);
		n = 0;
		for(i = 0; i < size; i++)
		{
			if(str[i] == '\n')
			{
				str[i] = '\0';
				n++;
			}
		}
//				n = br.getServices(search);
		ptr_arr = new char *[n];
		index = 0;
		while (index < n)
		{
			ptr_arr[index++] = str;
			str += strlen((char *)str)+1;
		}
		itsDp->setDPValue(".DnsInfo.serviceList",ptr_arr,n);
		delete[] ptr_arr;
	}
	else
	{
		char *ptr, *ptr1;
		
		if(ptr = strchr(str,'|'))
		{
			ptr++;
			if(ptr1 = strchr(ptr,'|'))
				*ptr1 = 0;
			if(ptr1 = strchr(ptr,','))
				*ptr1 = 0;
			obj->setFormat(ptr);
		}
		else
			obj->setFormat(0);
	}
}

void DimManager::manInitialize()
{
	DpIdentifier dp;
	/*
	DpTypeId type;
	*/
	SystemNumType sysid;
	ManagerIdentifier manid;
	char sysname[64];
	int mannum, sysnum;
	DimService *always;

	dic_disable_padding();
	dis_disable_padding();

	sysid = DpIdentification::getDefaultSystem();
//	SystemTable::getName((const) sysid,sysname);
//	cout << "SYSNAME " << sysname << endl;
	manid = Manager::getMyManagerId();
	mannum = manid.getManNum();
	sysnum = (int)sysid;
	sprintf(sysname,"PVSSSys%dMan%d:DIMHandler",sysnum, mannum);
	itsManName = new char[strlen(sysname)+1];
	strcpy(itsManName,sysname);
	itsManId = mannum;
	if(itsFileName[0])
	{
		DimManager::print_date_time();
		cout << "*** Using DIM Config File: " << itsFileName << endl;
		readDimConfig();
	}
	itsDp = 0;
	if(itsDpName[0])
	{
		DimManager::print_date_time();
		cout << "*** Using DIM Config DP: " << itsDpName << endl;
		itsDp = new ConfigDp(itsDpName,this);
	}
	always = new DimService(itsManName,itsManName);
	DimServer::addExitHandler(this);
	DimServer::start(itsManName);
}

void DimManager::manExit()
{
	DimManager::print_date_time();
	cout << "Exiting... " << endl;
}

char *DimManager::printDimDpType(DIM_TYPES dim_type)
{
	switch(dim_type)
	{
		case DIM_STRING:
			return("String");
		case DIM_INTEGER:
			return("Int");
		case DIM_FLOAT:
			return("Float");
		case DIM_INT_ARRAY:
			return("DynInt");
		case DIM_FLOAT_ARRAY:
			return("DynFloat");
		case DIM_STRING_ARRAY:
			return("DynString");
		case DIM_BOOL:
			return("Bool");
		case DIM_BOOL_ARRAY:
			return("DynBool");
		case DIM_BITFIELD:
			return("Bitfield");
		case DIM_BITFIELD_ARRAY:
			return("BynBitfield");
		case DIM_CHAR:
			return("Char");
		case DIM_CHAR_ARRAY: 
			return("DynChar");
		case DIM_UINTEGER:
			return("UInt");
		case DIM_UINT_ARRAY:
			return("DynUInt");
		case DIM_TIME:
			return("Time");
		case DIM_TIME_ARRAY: 
			return("DynTime");
		case DIM_LANG_STRING:
			return("LangString");
		default:
			return("Unknown");
	}
}

DIM_TYPES DimManager::getDimDpType(DpIdentifier &dp, char *dpName)
{
//DpIdentifier dp;
DpIdentification *dpIdent;
DpElementType elTyp = DPELEMENT_NOELEMENT;
VariableType varType = NO_VAR;
DIM_TYPES type;
char *ptr;

//	Manager::getId(dpName, dp);
	dpIdent = Manager::getDpIdentificationPtr();
	if((ptr = strchr(dpName,':')))
	{
		ptr++;
		ptr = strchr(ptr,':');
	}
	if(!ptr)
		dpIdent->getElementType(dp, elTyp);
	else
		dpIdent->getAttributeType(dp, varType);

	if(elTyp != DPELEMENT_NOELEMENT)
	{
	switch(elTyp)
	{
		case DPELEMENT_TEXT:
			type = DIM_STRING;
			break;
		case DPELEMENT_UINT:
			type = DIM_UINTEGER;
			break;
		case DPELEMENT_INT:
			type = DIM_INTEGER;
			break;
		case DPELEMENT_FLOAT:
			type = DIM_FLOAT;
			break;
		case DPELEMENT_DYNUINT:
			type = DIM_UINT_ARRAY;
			break;
		case DPELEMENT_DYNINT:
			type = DIM_INT_ARRAY;
			break;
		case DPELEMENT_DYNFLOAT:
			type = DIM_FLOAT_ARRAY;
			break;
		case DPELEMENT_DYNTEXT:
			type = DIM_STRING_ARRAY;
			break;
		case DPELEMENT_BIT:
			type = DIM_BOOL;
			break;
		case DPELEMENT_DYNBIT:
			type = DIM_BOOL_ARRAY;
			break;
		case DPELEMENT_32BIT:
			type = DIM_BITFIELD;
			break;
		case DPELEMENT_DYN32BIT:
			type = DIM_BITFIELD_ARRAY;
			break;
		case DPELEMENT_CHAR:
			type = DIM_CHAR;
			break;
//		case DPELEMENT_BLOB:
//		case DPELEMENT_DYNBLOB:
		case DPELEMENT_DYNCHAR:
			type = DIM_CHAR_ARRAY;
			break;
		case DPELEMENT_TIME:
			type = DIM_TIME;
			break;
		case DPELEMENT_DYNTIME:
			type = DIM_TIME_ARRAY;
			break;
		case DPELEMENT_RECORD:
		case DPELEMENT_ARRAY:
		case DPELEMENT_CHARARRAY:
		case DPELEMENT_UINTARRAY:
		case DPELEMENT_INTARRAY:
		case DPELEMENT_FLOATARRAY:
		case DPELEMENT_BITARRAY:
		case DPELEMENT_32BITARRAY:
		case DPELEMENT_TEXTARRAY:
			type = DIM_RECURSE;
			break;
		default:
			type = DIM_NOT_SUPPORTED;
			break;
	}
	}
	else
	{
		switch(varType)
		{
			case TIME_VAR:
				type = DIM_TIME;
				break;
			case BIT_VAR:
				type = DIM_BOOL;
				break;
			case INTEGER_VAR:
				type = DIM_INTEGER;
				break;
			case UINTEGER_VAR:
				type = DIM_UINTEGER;
				break;
			case FLOAT_VAR:
				type = DIM_FLOAT;
				break;
			case LANGTEXT_VAR:
				type = DIM_LANG_STRING;
				break;
			case TEXT_VAR:
				type = DIM_STRING;
				break;
			case BIT32_VAR:
				type = DIM_BITFIELD;
				break;
			case CHAR_VAR:
				type = DIM_CHAR;
				break;
			case DYNTIME_VAR:
				type = DIM_TIME_ARRAY;
				break;
			case DYNBIT_VAR:
				type = DIM_BOOL_ARRAY;
				break;
			case DYNINTEGER_VAR:
				type = DIM_INT_ARRAY;
				break;
			case DYNUINTEGER_VAR:
				type = DIM_UINT_ARRAY;
				break;
			case DYNFLOAT_VAR:
				type = DIM_FLOAT_ARRAY;
				break;
			case DYNLANGTEXT_VAR:
			case DYNTEXT_VAR:
				type = DIM_STRING_ARRAY;
				break;
			case DYNBIT32_VAR:
				type = DIM_BITFIELD_ARRAY;
				break;
			case DYNCHAR_VAR:
				type = DIM_CHAR_ARRAY;
				break;
			default:
				type = DIM_NOT_SUPPORTED;
				break;
/*
  NO_VAR
  NOTYPE_VAR
  VARIABLE
  DPIDENTIFIER_VAR
  DYN_VAR
  DYNDPIDENTIFIER_VAR
  REC_VAR
  FILE_VAR
  ANYTYPE_VAR
  ARG_VAR
  DYNDYNTIME_VAR
  DYNDYNBIT_VAR
  DYNDYNINTEGER_VAR
  DYNDYNUINTEGER_VAR
  DYNDYNFLOAT_VAR
  DYNDYNTEXT_VAR
  DYNDYNBIT32_VAR
  DYNDYNCHAR_VAR
  DYNDYNDPIDENTIFIER_VAR
  DYNANYTYPE_VAR
  DYNDYNANYTYPE_VAR
  EXTTIME_VAR
  DYNEXTTIME_VAR
  DYNDYNEXTTIME_VAR
  LANGTEXT_VAR
  DYNLANGTEXT_VAR
  DYNDYNLANGTEXT_VAR
  ERROR_VAR
  DYNERROR_VAR
  DYNDYNERROR_VAR
  BLOB_VAR
  DYNBLOB_VAR
  RECHDL_VAR
  CONNHDL_VAR
  CMDHDL_VAR
  POINTER_VAR
  SHAPE_VAR
  IDISPATCH_VAR
  DYNDYNBLOB_VAR
  DYNREC_VAR
  DYNDYNREC_VAR
  MAPPING_VAR
  DYNMAPPING_VAR
  DYNDYNMAPPING_VAR
  MIXED_VAR
  DYNMIXED_VAR
  DYNDYNMIXED_VAR
*/
		}
	}
	return(type);
}

int DimManager::getDpItemListSize(char *dpe)
{

	char *dpName, *name, *ptr, *ptre, *ptrs;
	int i, nItems, type;
	DpIdentifier *dpIds, dp;
	PVSSlong nIds;
	CharString namestr;

	nItems = 0;
	dpName = new char[strlen(dpe)+32];
	strcpy(dpName,dpe);
	ptr = dpName;
	while(ptre = strchr(ptr,';'))
	{
		*ptre = '\0';
		nItems += getDpItemListSize(ptr);
		ptr = ++ptre;
	}
	if(!(Manager::getId(ptr,dp)))
	{
		DimManager::print_date_time();
		cout << "*** DP "<< ptr << " Does Not Exist" << endl;
		delete[] dpName;
		return(nItems);
	}

	if(ptr[strlen(ptr)-1] == '.')
		ptr[strlen(ptr)-1] = '\0';

	if((ptrs = strchr(ptr,':')))
	{
		ptrs++;
		ptrs = strchr(ptrs,':');
	}
	if(!ptrs)
		strcat(ptr,".*");
	if(getIdSet(ptr,dpIds,nIds,0))
	{
		if(nIds)
		{
			for(i = 0; i < nIds; i++)
			{
//				Manager::getName(dpIds[i], name);
				Manager::getName(dpIds[i], namestr);
				name = (char *)namestr;
				type = getDimDpType(dpIds[i], name);
				if(type == DIM_RECURSE)
				{
					nItems += getDpItemListSize(name);
				}
				else
					nItems++;
//#ifndef WIN32
//				delete[] name;
//#endif
			}
		}
		else
			nItems += 1;
	}
	delete[] dpName;
	return(nItems);
}

int DimManager::getDpItemList(char *dpe, DIM_TYPES *types, int &n, char *dpsptr, int &dpslen)
{

	char *dpName, *name, *dps, *ptr, *ptre, *ptrs;
	int i, aux, ret = 0;
	DpIdentifier *dpIds, id, dp;
	PVSSlong nIds;
	DIM_TYPES type;
	CharString namestr;

	dpName = new char[strlen(dpe)+32];
	strcpy(dpName,dpe);
	ptr = dpName;
	dps = dpsptr;
	while(ptre = strchr(ptr,';'))
	{
		*ptre = '\0';
		aux = dpslen;
		getDpItemList(ptr, types, n, dps, dpslen);
		dps += dpslen - aux;
		ptr = ++ptre;
	}
//	Manager::getId(ptr,dp);
	if(!(Manager::getId(ptr,dp)))
	{
		delete[] dpName;
		return(ret);
	}
//	Manager::getName(dp, name);
	Manager::getName(dp, namestr);
	name = (char *)namestr;
//	type = getDimDpType(dp, name);
	if((ptrs = strchr(name,':')))
	{
		ptrs++;
		ptrs = strchr(ptrs,':');
	}
//	delete[] name;
	if(!(ptr[strlen(ptr)-1] == '.'))
//		ptr[strlen(ptr)-1] = '\0';
		if(!ptrs)
			strcat(ptr,".*");
//	strcat(ptr,".*");

	if(getIdSet(ptr,dpIds,nIds,0))
	{
		if(nIds)
		{
			for(i = 0; i < nIds; i++)
			{
//				Manager::getName(dpIds[i], name);
				Manager::getName(dpIds[i], namestr);
				name = (char *)namestr;
				type = getDimDpType(dpIds[i], name);
				if(type == DIM_RECURSE)
				{
					aux = dpslen;
					getDpItemList(name, types, n, dps, dpslen);
					dps += dpslen - aux;
				}
				else
				{
					strcpy(dps, name);
					dps += strlen(name) + 1;
					dpslen += strlen(name) + 1;
					types[n] = type;
					n++;
					if(type == DIM_NOT_SUPPORTED)
					{
						ret = 1;
//#ifndef WIN32
//						delete[] name;
//#endif
						break;
					}
				}
//#ifndef WIN32
//				delete[] name;
//#endif
			}
		}
//	}
		else
		{

			if(ptre = strstr(ptr,".*"))
				*ptre = '\0';
			Manager::getId(ptr,dp);
//			Manager::getId(dpe,dp);
//			Manager::getName(dp, name);
			Manager::getName(dp, namestr);
			name = (char *)namestr;
			type = getDimDpType(dp, name);
			strcpy(dps, name);
			dpslen += strlen(name) + 1;
			types[n] = type;
			n++;
			if(type == DIM_NOT_SUPPORTED)
				ret = 1;
//#ifndef WIN32
//			delete[] name;
//#endif
//		}
		}
	}
	delete[] dpName;
	return(ret);
}
	
int DimManager::readDimConfig()
{

	FILE *f;
	char str[2000], *ptr;
	int dim_type, n_items[6] = {0, 0, 0, 0, 0, 0};
	DpIdentifier dp;
	int i, invalid = 0;
	
	if((f = fopen(itsFileName,"r")) == NULL)
		return 0;
	while(1)
	{
		if(fgets(str,2000,f) == NULL)
			break;
		if(str[0] == '#')
			continue;
		ptr = str;
		while((*ptr == ' ')||(*ptr == '\t'))
			ptr++;
		if(*ptr == '\n')
			continue;
		if(ptr = strstr(str,"[DIM"))
		{
			if(!strncmp(ptr,"[DIM Client Services]",21))
			{
				dim_type = 0;
			}
			else if(!strncmp(ptr,"[DIM Client Commands]",21))
			{
				dim_type = 1;
			}
			else if(!strncmp(ptr,"[DIM Server Services]",21))
			{
				dim_type = 2;
			}
			else if(!strncmp(ptr,"[DIM Server Commands]",21))
			{
				dim_type = 3;
			}
			else if(!strncmp(ptr,"[DIM Client RPCs]",17))
			{
				dim_type = 4;
			}
			else if(!strncmp(ptr,"[DIM Server RPCs]",17))
			{
				dim_type = 5;
			}
			continue;
		}
		processDimLine(str, dim_type, 0);
		n_items[dim_type]++;
	}
	fclose(f);
	for(i = 0; i < 6; i++)
	{
		DimManager::printAllServices(i, n_items[i], " Set Up"); 
	}
	return 1;
}

int DimManager::processDimLine(char *str, int dim_type, int config)
{

  char *ptr;
  int index;
  char *dpe, *dpe1, serv_name[MAX_DIM_NAME], serv_name1[MAX_DIM_NAME], nolink[MAX_DIM_NAME];
  int timeout, stamped, update, dpslen, dpslen1, merge;
  char *dpsptr, *dpsptr1, format[MAX_DIM_NAME], hash_index[32];
  DpIdentifier dp;
  DIM_TYPES *types, *types1;
  DimObject *obj, *obj1;
  DimItem *dimItem;
  int n, nItems, nItems1, invalid = 0;
	
	ptr = str;
	dpe = new char[strlen(str)];
	format[0] = '\0';
	index = 0;
	while(1)
	{
		while((*ptr == ' ')||(*ptr == '\t'))
			ptr++;
		if(*ptr != '#')
			break;
		else
		{
			while (*ptr != ',')
				hash_index[index++] = *ptr++;
			ptr++;
			break;
		}
	}
	index = 0;
	while(1)
	{
		while((*ptr == ' ')||(*ptr == '\t'))
			ptr++;
		if(*ptr == '\n')
			break;
		if(*ptr == ',')
			break;
		dpe[index++] = *ptr++;
	}
	dpe[index] = '\0';
	ptr++;
	index = 0;
	while(1)
	{
		while((*ptr == ' ')||(*ptr == '\t'))
			ptr++;
		if(*ptr == '\n')
			break;
		if(*ptr == '\0')
			break;
		if(*ptr == ',')
			break;
		serv_name[index++] = *ptr++;
	}
	serv_name[index] = '\0';
	if(dim_type == 0)
	{
		ptr++;
		index = 0;
		while(1)
		{
			while((*ptr == ' ')||(*ptr == '\t'))
				ptr++;
			if(*ptr == '\n')
				break;
			if(*ptr == ',')
				break;
			nolink[index++] = *ptr++;
		}
		nolink[index] = '\0';
		ptr++;
		sscanf(ptr,"%d",&timeout);
		while(*ptr != ',')
			ptr++;
		ptr++;
		sscanf(ptr,"%d",&stamped);
		while(*ptr)
		{
			if(*ptr == ',')
				break;
			ptr++;
		}
		if(*ptr)
		{
			ptr++;
			sscanf(ptr,"%d",&update);
		}
		else
			update = 1;
	}
	else if(dim_type == 1)
	{
		merge = 0;
		if(*ptr == ',')
		{
			ptr++;
			sscanf(ptr,"%d",&merge);
		}
		while(*ptr)
		{
			if(*ptr == ',')
				break;
			ptr++;
		}
		if(*ptr)
		{
			ptr++;
			sscanf(ptr,"%s",format);
		}
	}
	else if((dim_type == 2)||(dim_type == 3))
	{
		if(*ptr == ',')
		{
			ptr++;
			sscanf(ptr,"%s",format);
		}
	}
	else if(dim_type > 3)
	{
		dpe1 = new char[strlen(serv_name)+1];
		strcpy(dpe1, serv_name);
		ptr++;
		index = 0;
		while(1)
		{
			while((*ptr == ' ')||(*ptr == '\t'))
				ptr++;
			if(*ptr == '\n')
				break;
			if(*ptr == '\0')
				break;
			if(*ptr == ',')
				break;
			serv_name[index++] = *ptr++;
		}
		serv_name[index] = '\0';
		strcpy(serv_name1, serv_name);
		strcat(serv_name,"/RpcIn");
		strcat(serv_name1,"/RpcOut");
	}
	{
		DISABLE_AST
		nItems = getDpItemListSize(dpe);
//		cout << str << " nitems "<<nItems<<endl;
		if(nItems)
		{
			dpsptr = new char[MAX_DP_NAME*nItems];
			dpslen = 0;
			types = new DIM_TYPES[nItems];
			n = 0;
			invalid = getDpItemList(dpe, types, n, dpsptr, dpslen);
		}
		else
		{
//			DimManager::print_date_time();
//			cout << "*** DP "<< dpe << " Does Not Exist" << endl;
			ENABLE_AST
			delete[] dpe;
			return 1;
		}
		if(dim_type > 3)
		{
			nItems1 = getDpItemListSize(dpe1);
			if(nItems1)
			{
				dpsptr1 = new char[MAX_DP_NAME*nItems1];
				dpslen1 = 0;
				types1 = new DIM_TYPES[nItems1];
				n = 0;
				invalid = getDpItemList(dpe1, types1, n, dpsptr1, dpslen1);
			}
			else
			{
//				DimManager::print_date_time();
//				cout << "*** DP "<< dpe1 << " Does Not Exist" << endl;
				ENABLE_AST
				delete[] dpe1;
				return 1;
			}
		}
		ENABLE_AST
	}
	if(invalid)
	{
		delete[] dpsptr;
		delete[] types;
		DimManager::print_date_time();
		cout << "*** DP "<< dpe << " Type Not Supported" << endl;
		delete[] dpe;
		return 1;
	}
	switch(dim_type)
	{
		case 0:
//			cout << "ClientServices: " << dpe << " " << serv_name << " " << timeout << " " << stamped << " " << nolink << endl;	
			obj = new DimObject(dpe, this, 0);
			dimItem = new DimItem(obj, 0, config, str, 0);
			dimList.add(str, dimItem);
			obj->setupClientService(serv_name, nItems, dpsptr, dpslen,
				types, timeout, stamped, nolink, update);
			break;
		case 1:
//			cout << "ClientCommands: " << dpe << " " << serv_name << " " << format << endl;	
			obj = new DimObject(dpe, this, 1);
			dimItem = new DimItem(obj, 0, config, str, 1);
			dimList.add(str, dimItem);
			obj->setupClientCommand(serv_name, nItems, dpsptr, dpslen,
				types, merge, format);
			break;
		case 2:
//			cout << "ServerServices: " << dpe << " " << serv_name << endl;
			obj = new DimObject(dpe, this, 2);
			dimItem = new DimItem(obj, 0, config, str, 2);
			dimList.add(str, dimItem);
			obj->setupServerService(serv_name, nItems, dpsptr, dpslen,
				types, format);
			break;
		case 3:
//			cout << "ServerCommands: " << dpe << " " << serv_name << endl;	
			obj = new DimObject(dpe, this, 3);
			dimItem = new DimItem(obj, 0, config, str, 3);
			dimList.add(str, dimItem);
			obj->setupServerCommand(serv_name, nItems, dpsptr, dpslen,
				types, format);
			break;
		case 4:
//			cout << "Client RPC: " << dpe << " " << serv_name << endl;	
//			cout << "            " << dpe1 << " " << serv_name1 << endl;	
			obj = new DimObject(dpe, this, 1);
			obj->setupClientCommand(serv_name, nItems, dpsptr, dpslen,
				types, 0, 0);
			obj1 = new DimObject(dpe1, this, 0);
			obj1->setupClientService(serv_name1, nItems1, dpsptr1, dpslen1,
				types1, 0, 1, "", 1);
			obj1->setRPCCommand(obj);
			obj->setRPCCommand(obj1);
			dimItem = new DimItem(obj, obj1, config, str, 4);
			dimList.add(str, dimItem);
			break;
		case 5:
//			cout << "Server RPC: " << dpe << " " << serv_name << endl;	
//			cout << "            " << dpe1 << " " << serv_name1 << endl;	
			obj = new DimObject(dpe, this, 3);
			obj->setupServerCommand(serv_name, nItems, dpsptr, dpslen,
				types, format);
			obj1 = new DimObject(dpe1, this, 2);
			obj1->setupServerService(serv_name1, nItems1, dpsptr1, dpslen1,
				types1, format);
			obj1->setRPCCommand(obj);
			obj->setRPCCommand(obj1);
			dimItem = new DimItem(obj, obj1, config, str, 5);
			dimList.add(str, dimItem);
			break;
	}
	delete[] dpsptr;
	delete[] types;
	delete[] dpe;
	if(dim_type > 3)
	{
		delete[] dpsptr1;
		delete[] types1;
		delete[] dpe1;
	}
	return 1;
}

void DimObject::setDimNoLink(char *nolink)
{
	DIM_TYPES type;

	type = itsTypes[0];
	if(!nolink[0])
	{
		itsNoLink = new char[16];
		strcpy((char *)itsNoLink, "__DIM_NO_LINK__");
		itsNoLinkSize = strlen((char *)itsNoLink)+1;
	}
	else
	{
		if((type == DIM_INTEGER) || (type == DIM_INT_ARRAY) ||
			(type == DIM_UINTEGER) || (type == DIM_UINT_ARRAY) ||
			(type == DIM_BOOL) || (type == DIM_BOOL_ARRAY) ||
			(type == DIM_BITFIELD) || (type == DIM_BITFIELD_ARRAY) ||
			(type == DIM_TIME) || (type == DIM_TIME_ARRAY))
		{
			itsNoLink = new int;
			sscanf(nolink,"%d",(int *)itsNoLink);
			itsNoLinkSize = sizeof(int);
		}
		else if ((type == DIM_FLOAT) || (type == DIM_FLOAT_ARRAY))
		{
			itsNoLink = new float;
			sscanf(nolink,"%f",(float *)itsNoLink);
			itsNoLinkSize = sizeof(float);
		}
		else
		{
			itsNoLink = new char[strlen(nolink)+1];
			strcpy((char *)itsNoLink, nolink);
			itsNoLinkSize = strlen((char *)itsNoLink)+1;
		}
	}
}

void DimObject::setupDimDps(DimObject *obj, char *serv_name, int n, char *dimdps,
		int dpslen, DIM_TYPES *dimtypes)
{
	int i;
	char *name_ptr;

	setDimName(serv_name);
	itsNTypes = n;
	setDpItemNames(dimdps,dpslen);
	itsTypes = new DIM_TYPES[n];
	itsMergeIndexes = new int[n];
	for(i = 0; i < n; i++)
		itsTypes[i] = dimtypes[i];
	if(!itsDpItemPtrs)
	{
		itsDpItemPtrs = new DimDpItem *[itsNTypes];
		name_ptr = itsDpItemNames;
		for(i = 0; i < itsNTypes; i++)
		{
			itsDpItemPtrs[i] = new DimDpItem(obj->getManId(), name_ptr);
			name_ptr += strlen(name_ptr)+1;
		}
	}
#ifdef DEBUG
	DimManager::printService(itsDimType, getDimName(), itsNTypes,
							itsDpItemNames, " Set Up");
//	if(itsFormat)
//	{
//		cout << "\t" << itsFormat << endl;
//		for(i = 0; i < itsNTypes; i++)
//			cout << "\t" << itsTypes[i] << endl;
//	}
		
#endif
}

int DimObject::setupClientService(char *serv_name, int n, 
		char *dimdps, int dpslen, DIM_TYPES *dimtypes, 
		int timeout, int dimstamped, char *nolink, int update)
{
	DISABLE_AST

	setupDimDps(this, serv_name, n, dimdps, dpslen, dimtypes);
	itsTime = timeout;
	itsStamped = dimstamped;
	setDimNoLink(nolink);
	if(!update)
	{
		if(itsTime > 0)
		{
			itsClient = new DimUpdatedInfo(getDimName(), itsTime, 
				itsNoLink, itsNoLinkSize, this);
		}
		else
		{
			itsClient = new DimUpdatedInfo(getDimName(), 
				itsNoLink, itsNoLinkSize, this);
		}
		ENABLE_AST
		return 1;
	}
	if(!itsStamped)
	{
		if(itsTime > 0)
		{
			itsClient = new DimInfo(getDimName(), itsTime, 
				itsNoLink, itsNoLinkSize, this);
		}
		else
		{
			itsClient = new DimInfo(getDimName(), 
				itsNoLink, itsNoLinkSize, this);
		}
	}
	else
	{
		if(itsTime > 0)
		{
			itsClient = new DimStampedInfo(getDimName(), itsTime, 
				itsNoLink, itsNoLinkSize, this);
		}
		else
		{
			itsClient = new DimStampedInfo(getDimName(), 
				itsNoLink, itsNoLinkSize, this);
		}
	}		
	ENABLE_AST
	return 1;
}

int DimObject::setupClientCommand(char *serv_name, int n, char *dimdps,
		int dpslen, DIM_TYPES *dimtypes, int merge_flag, char *formatp)
{
	int i, merge;
	char *name_ptr, *namep, *auxp;
	DISABLE_AST

	if(formatp)
	{
		if(formatp[0] != '\0')
			setFormat(formatp);
	}
	setupDimDps(this, serv_name, n, dimdps, dpslen, dimtypes);
	namep = getDPName();
	name_ptr = itsDpItemNames;
	merge = merge_flag;
	if(merge == -1)
	{
		itsReadFile = 1;
		merge = 0;
	}
	if(itsNTypes > 1)
		itsMergeFlag = merge;
	for(i = 0; i < itsNTypes; i++)
	{
		auxp = name_ptr;
		auxp += strlen(namep);
		if(namep[0])
		{
			connectDPValue(auxp);
		}
		else
		{
			connectDPValue(auxp, "");
		}
		name_ptr += strlen(name_ptr)+1;
	}
//	DimTimer::start(1);
//	findFormat();
	ENABLE_AST
	return 1;
}

int DimObject::unsetupClientCommand()
{
	int i;
	char *name_ptr, *namep, *auxp;
	DISABLE_AST

	namep = getDPName();
	name_ptr = itsDpItemNames;
	for(i = 0; i < itsNTypes; i++)
	{
		auxp = name_ptr;
		auxp += strlen(namep);
		if(namep[0])
		{
			disconnectDPValue(auxp);
		}
		else
		{
			disconnectDPValue(auxp, "");
		}
		name_ptr += strlen(name_ptr)+1;
	}
	ENABLE_AST
	return 1;
}

/*
int DimObject::setupServerService(char *serv_name, int n, char *dimdps,
		int dpslen, DIM_TYPES *dimtypes, DimObject *obj)
{
	itsRPCCommand = obj;
	return setupServerService(serv_name, n, dimdps, dpslen, dimtypes);
}
*/
int DimObject::setupServerService(char *serv_name, int n, char *dimdps,
		int dpslen, DIM_TYPES *dimtypes, char *formatp)
{
	int i;
	char *name_ptr, *namep, *auxp;
	DISABLE_AST

//	cout << serv_name << endl;
	if(formatp)
	{
		if(formatp[0] != '\0')
			setFormat(formatp);
	}
	setupDimDps(this, serv_name, n, dimdps, dpslen, dimtypes);
	namep = getDPName();
	name_ptr = itsDpItemNames;
	for(i = 0; i < itsNTypes; i++)
	{
		auxp = name_ptr;
		auxp += strlen(namep);
		if(namep[0])
		{
			connectDPValue(auxp);
		}
		else
			connectDPValue(auxp,"");
		name_ptr += strlen(name_ptr)+1;
	}
	ENABLE_AST
	return 1;
}

int DimObject::unsetupServerService()
{
	int i;
	char *name_ptr, *namep, *auxp;
	DISABLE_AST

	namep = getDPName();
	name_ptr = itsDpItemNames;
	for(i = 0; i < itsNTypes; i++)
	{
		auxp = name_ptr;
		auxp += strlen(namep);
		if(namep[0])
		{
			disconnectDPValue(auxp);
		}
		else
		{
			disconnectDPValue(auxp, "");
		}
		name_ptr += strlen(name_ptr)+1;
	}
	ENABLE_AST
	return 1;
}

int DimObject::setupServerCommand(char *serv_name, int n, char *dimdps,
		int dpslen, DIM_TYPES *dimtypes, char *formatp)
{
	char format[MAX_DIM_NAME];
	DISABLE_AST

	if(formatp)
	{
		if(formatp[0] != '\0')
			setFormat(formatp);
	}
	setupDimDps(this, serv_name, n, dimdps, dpslen, dimtypes);
	getDataFormat(format);
	itsCommand = new DimCommand(getDimName(),format,this);
	ENABLE_AST
	return 1;
}

int main(int argc, char *argv[])
{
int i;
char file_name[128], dp_name[128], dns_node[128], *ptr;
int dns_port = 0;
int own_system_flag = 0;

	Resources::init(argc, argv);

	dim_init();
	dim_set_write_timeout(20);
	file_name[0] ='\0';
	dp_name[0] = '\0';
	dns_node[0] = '\0';
	for( i = 1; i < argc; i++)
	{
		if(!strcmp(argv[i],"-dim_config"))
		{
			strcpy(file_name,argv[i+1]);
		}
		if(!strcmp(argv[i],"-dim_dp_config"))
		{
			strcpy(dp_name,argv[i+1]);
		}
		if(!strcmp(argv[i],"-dim_dns_node"))
		{
			strcpy(dns_node,argv[i+1]);
			if((ptr = strchr(dns_node,':')))
			{
				*ptr = '\0';
				ptr++;
				sscanf(ptr,"%d",&dns_port);
			}
		}
		if(!strcmp(argv[i],"-dim_dns_port"))
		{
			sscanf(argv[i+1],"%d",&dns_port);
		}
		if(!strcmp(argv[i],"-own_system_only"))
		{
			own_system_flag = 1;
		}
		if(!strcmp(argv[i],"-discard_old_data"))
		{
			discardOldData = 1;
		}
	}
	if(dns_node[0] != '\0')
	{
		if(dns_port)
		{
			DimServer::setDnsNode(dns_node, dns_port);
			DimClient::setDnsNode(dns_node, dns_port);
		}
		else
		{
			DimServer::setDnsNode(dns_node);
			DimClient::setDnsNode(dns_node);
		}
	}
//	char name[64];
//	sprintf(name,"PVSS_SYS%d:DIMHandler",sysid);
	DimManager *dimManager = new DimManager(file_name, dp_name, own_system_flag);
	
	return 0;
}

/*
int main(int argc, char *argv[])
{

	Resources::init(argc, argv);

//	char name[64];
//	sprintf(name,"PVSS_SYS%d:DIMHandler",sysid);
	DimManager *dimManager = new DimManager();
	
	return 0;
}

*/
