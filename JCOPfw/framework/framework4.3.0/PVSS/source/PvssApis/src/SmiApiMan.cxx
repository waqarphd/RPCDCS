#include <smiuirtl.hxx>
#include <smirtl.hxx>
#include "ApiLib.hxx"
#include <ctype.h>

#define MAX_BEFORE_SENDING 15

static time_t gTime, gOldTime = 0;
static int gHeartBeat = 0;
static int DnsVersion = -1, DnsOldVersion = -1;
static char fwFsm_separator = '|';
static char fwDev_separator = '/';

class DnsUp : public DimInfo
{
	void infoHandler();
public:
	DnsUp() : DimInfo("DIS_DNS/VERSION_NUMBER",0) {}
};

class SMIObject;

class Proxy;

class SmiManager : public ApiManager, public DimServer, public DimTimer
{
public:
	SmiManager(int own_system_flag);

	char *dpStateName;
	char *dpCommandName;
	SLList proxyList;
	SLList objList;
	SLList domainList;
	static void print_date_time()
	{
		time_t t;
		char str[128];

		t = time((time_t *)0);
		strcpy(str, ctime(&t));
		str[strlen(str) - 1] = '\0';
		cout << "PVSS00smi(" << itsManId << ") - " << str << "\n\t";
	}
	void setObjFlag() { DISABLE_AST; itsObjFlag++; ENABLE_AST;};
	int getObjFlag() { return itsObjFlag; };
	void clearObjFlag() {itsObjFlag--; };
	void setProxyFlag() { DISABLE_AST; itsProxyFlag++; ENABLE_AST;};
	int getProxyFlag() { return itsProxyFlag; };
	void clearProxyFlag() {itsProxyFlag--; };
	void getSmiObjects();
	void trySmiObjs();
	int checkSmiObj(char *name);
	void addSmiObj(char *name, char *dpname);
	void remSmiObjs();
	int getNTmpProxys() {return nTmpProxys;}
	void getSmiProxys();
	void tryProxys();
	int checkProxy(char *dpname);
	void addProxy(char *dpname);
	void remProxys();
	void addProxys();
	int getCheckSmiObjects() {return toCheckSmiObjects; };
	void clearCheckSmiObjects() 
		{ toCheckSmiObjects = 0; clearObjFlag();};
	void setCheckSmiObjects() 
		{ toCheckSmiObjects++; setObjFlag();};
	void doCheckSmiObjects();
	void exitHandler(int code);
	void getRunningSmiDomains();
	int checkSmiDomainsRunning();
	int isSmiDomainRunning(char *domain);
	int checkSmiDomain(char *domain);
protected:
	void manInitialize();
	void manExecute();
	void manExit();
	static int itsManId;
	char *itsManName;
	DimCommand *manCmnds;
	void commandHandler();
	int itsObjFlag;
	int itsProxyFlag;
	int nTmpProxys;
	int toCheckSmiObjects;
    int exitCode;
	int timerRunning;
	void timerHandler();
};

int SmiManager::itsManId = 0;

class SMIDomainItem : public DP, public SLLItem
{
public:
	SMIDomainItem(char *name, char *dp_name, SmiManager *id): 
	   DP(dp_name, id)
	{
		running = -1;
		manId = id;
		domainName = new char[strlen(name)+1];
		strcpy(domainName, name);
		dpName = new char[strlen(dp_name)+1];
		strcpy(dpName, dp_name);
//		strcat(dpName,".running");
		connectDPValue(".running");
	}
	~SMIDomainItem()
	{
		if(domainName)
			delete domainName;
		if(dpName)
			delete dpName;
//		disconnectDPValue(dpName);
		disconnectDPValue(".running");
	}
	int getRunning() { return running; }
	char *getName() { return domainName; }
private:
	SmiManager *manId;
	char *domainName;
	char *dpName;
	int running;
	void gotDPValue(DPItem *dpItem);
};
/*
class SMIObjItem : public SLLItem
{
public:
	SMIObjItem(int currtype, char *currdpe, char *value)
	{
		
		type = currtype;
		data = new char[strlen(value)+1];
		strcpy(data, value);
		dpe = new char[strlen(currdpe)+1];
		strcpy(dpe, currdpe);
	}
	~SMIObjItem()
	{
		if(data)
			delete data;
		if(dpe)
			delete dpe;
		type = 0;
	}
	int getType()
	{
		return type;
	}
	char *getData()
	{
		return data;
	}
	char *getDpe()
	{
		return dpe;
	}
private:
	int type;
	char *data;
	char *dpe;
};
*/

class SMIObjItem : public SLLItem
{
public:
	SMIObjItem(int currtype, DPElem *currdpe, char *value)
	{
		
		type = currtype;
		data = new char[strlen(value)+1];
		strcpy(data, value);
//		dpe = new char[strlen(currdpe)+1];
//		strcpy(dpe, currdpe);
		dpe = currdpe;
	}
	~SMIObjItem()
	{
		if(data)
			delete data;
//		if(dpe)
//			delete dpe;
		type = 0;
	}
	int getType()
	{
		return type;
	}
	char *getData()
	{
		return data;
	}
	DPElem *getDpe()
	{
		return dpe;
	}
private:
	int type;
	char *data;
	DPElem *dpe;
};
 


class SMIObject : public DP, public SmiObject
{
public :
	SMIObject(char *name, char *dpname, SmiManager *id, 
		char *stateDp, char *paramDp, char *busyDp) : 
	   DP(dpname, id), SmiObject(name) 
	   { 
		manId = id;
	    dpName = new char[strlen(dpname)+24];
		strcpy(dpName,dpname);
	    objName = new char[strlen(name)+1];
		strcpy(objName,name);
		stateDpElem = paramDpElem = busyDpElem = 0;
		if(stateDp)
		{
			stateDpElem = new char[strlen(stateDp)+1];
			strcpy(stateDpElem,stateDp);
//			cout << "state DP: " << stateDp << endl;
			stateDpElemPtr = new DPElem(id, getDPName(), stateDp);
		}
		if(paramDp)
		{
			paramDpElem = new char[strlen(paramDp)+1];
			strcpy(paramDpElem,paramDp);
//			cout << "param DP: " << paramDp << endl;
			paramDpElemPtr = new DPElem(id, getDPName(), paramDp);
		}
		if(busyDp)
		{
			busyDpElem = new char[strlen(busyDp)+1];
			strcpy(busyDpElem,busyDp);
//			cout << "busy DP: " << busyDp << endl;
			busyDpElemPtr = new DPElem(id, getDPName(), busyDp);
		}
		cmnd_init = 0;
		state = 0;
		params = 0;
		params_buffer = 0;
		busy = 0;
		toWriteStateFlag = 0;
		toWriteParamFlag = 0;
		toWriteBusyFlag = 0;
		toWriteFlag = 0;
	   };
	~SMIObject()
	{
		disconnectDPValue(".fsm.sendCommand");
		delete dpName;
		delete objName;
		if(stateDpElem)
		{
			delete stateDpElem;
			delete stateDpElemPtr;
		}
		if(paramDpElem)
		{
			delete paramDpElem;
			delete paramDpElemPtr;
		}
		if(busyDpElem)
		{
			delete busyDpElem;
			delete busyDpElemPtr;
		}
//		if(state)
//			delete state;
		if(params)
			delete params;
		if(params_buffer)
				delete params_buffer;
//		if(busy)
//			delete busy;
	}
	void smiStateChangeHandler();
	void smiExecutingHandler();
	char *getObjName() { return objName;}
//	int getWriteStateFlag() {return toWriteStateFlag; };
//	void clearWriteStateFlag() 
//		{ toWriteStateFlag = 0; manId->clearFlag();};
//	void setWriteStateFlag() 
//		{ toWriteStateFlag++; manId->setFlag();};
//	int getWriteParamFlag() {return toWriteParamFlag; };
//	void clearWriteParamFlag() 
//		{ toWriteParamFlag = 0; manId->clearFlag();};
//	void setWriteParamFlag() 
//		{ toWriteParamFlag++; manId->setFlag();};
//	int getWriteBusyFlag() {return toWriteBusyFlag; };
//	void clearWriteBusyFlag() 
//		{ toWriteBusyFlag = 0; manId->clearFlag();};
//	void setWriteBusyFlag() 
//		{ toWriteBusyFlag++; manId->setFlag();};
//	void doStateChange();
//	void doParamChange();
//	void doBusyChange();
	int getWriteFlag() {return toWriteFlag; };
	void setWriteFlag() 
		{ toWriteFlag++; manId->setObjFlag();};
	void clearWriteFlag() 
		{ toWriteFlag = 0; manId->clearObjFlag();};
	SLList sendItemList;
/*
	void addSendItem(int type, char *dpe, char *data)
	{
		SMIObjItem *itemPtr = new SMIObjItem(type, dpe, data);
		sendItemList.add(itemPtr);
//if(strstr(dpName,"TOP"))
//	cout << "Wants to send "<<type << " " << dpName << dpe << " " << data << endl; 
		setWriteFlag();
	}
*/
	void addSendItem(int type, DPElem *dpe, char *data)
	{
		SMIObjItem *itemPtr = new SMIObjItem(type, dpe, data);
		sendItemList.add(itemPtr);
//if(strstr(dpName,"TOP"))
//	cout << "Wants to send "<<type << " " << dpName << dpe << " " << data << endl; 
		setWriteFlag();
	}
	void sendItems()
	{
		SMIObjItem *itemPtr;
		int type, n, i;
//		char *dpe; 
		char *data, *ptr;
		char **params = 0;
		char **donedpes;
		int index = 0;
		DPElem *elem;

		donedpes = new char *[toWriteFlag];
		itemPtr = (SMIObjItem *)sendItemList.getHead();
		while(itemPtr)
		{
			type = itemPtr->getType();
//			dpe = itemPtr->getDpe();
			elem = itemPtr->getDpe();
			data = itemPtr->getData();
			for(i = 0; i < index; i++)
			{
//				if(!strcmp(donedpes[i],dpe))
				if(!strcmp(donedpes[i],elem->getDPElemName()))
				{
//SmiManager::print_date_time();
//cout << "Flushing" << endl; 
					manId->sendDPSetList();
					manId->clearDPSetList();
					index = 0;
				}
			}
			switch(type)
			{
				case 0:
				case 1:
//					addDPValue(dpe, data);
					setDPValue(elem, data);
//					setDPValue(dpe, data);
//if(strstr(dpName,"TOP"))
//SmiManager::print_date_time();
//cout << "Sent "<<type << " " << dpName << dpe << " " << data << endl; 
					break;
				case 2:
					n = 0;
					ptr = data;
					while((ptr = strchr(ptr,'|')))
					{
						*ptr = 0;
						ptr++;
						n++;
					}
					params = new char*[n];
					ptr = data;
					for(i = 0; i < n; i++)
					{
						params[i] = ptr;
						ptr += strlen(ptr)+1;
					}
//					addDPValue(dpe, params, n);
					setDPValue(elem, params, n);
//					setDPValue(dpe, params, n);
					break;
			}
//			donedpes[index++] = dpe;
			donedpes[index++] = elem->getDPElemName();
			itemPtr = (SMIObjItem *)sendItemList.getNext();
			clearWriteFlag();
		}
//SmiManager::print_date_time();
//cout << "Flushing" << endl; 
		while((itemPtr = (SMIObjItem *)sendItemList.removeHead()))
		{
			delete itemPtr;
		}
		delete[] donedpes;
		if(params)
			delete[] params;
	}
private :
	SmiManager *manId;
	char *dpName;
	char *domainName;
	char *objName;
	void gotDPValue(DPItem *dpItem);
	int cmnd_init;
	char *state;
	char *busy;
	char **params;
	char *params_buffer;
	int n_params;
	int n_actions;
	int toWriteStateFlag;
	int toWriteParamFlag;
	int toWriteBusyFlag;
	char *stateDpElem;
	char *paramDpElem;
	char *busyDpElem;
	DPElem *stateDpElemPtr;
	DPElem *paramDpElemPtr;
	DPElem *busyDpElemPtr;
	int toWriteFlag;
};

class TmpProxy : public DP
{
public:
	TmpProxy(char *name, int n, SmiManager *id) : 
	  DP(name, id) 
	  { 
		  proxyName = new char[strlen(name)+1];
	  	  strcpy(proxyName, name);
		  manId = id;
		  index = n;
	  };
	~TmpProxy()
	{
		delete proxyName;
	}
//	char *getProxyName() { return proxyName;}
//	SmiManager *getManId() { return manId;}
private:
	SmiManager *manId;
	void gotDPValue(DPItem *dpItem);
	char *proxyName;
	int index;
};

class ProxyAccess
{
	static char *prefix;
	static char *itemName;

	static char *getItemName(char *item)
	{
		init();
		strcpy(itemName, prefix);
		strcat(itemName, item);
		return itemName;
	}
	static void init()
	{
		if(!prefix)
		{
			prefix = new char[128];
			itemName = new char[128];
			prefix[0] = '\0';
		}
	}

public:
//	ProxyAccess()
//	{
//		prefix = new char[128];
//		itemName = new char[128];
////		strcpy(prefix,".fwDeclarations.fwCtrlDev");
//		prefix[0] = '\0'; 
//	}
	static char *ctrlUnit()
	{
		return getItemName(".ctrlUnit");
	}
	static char *currentParameters()
	{
		return getItemName(".fsm.currentParameters");
	}
	static char *currentState()
	{
		return getItemName(".fsm.currentState");
	}
	static char *executingAction()
	{
		return getItemName(".fsm.executingAction");
	}
	static char *sendCommand()
	{
		return getItemName(".fsm.sendCommand");
	}
};

char *ProxyAccess::prefix = 0;
char *ProxyAccess::itemName = 0;

class Proxy : public DP, public SmiProxy
{
public:
	Proxy(char *dpname, SmiManager *id) : 
	  DP(dpname, id), SmiProxy() 
	{ 
		char domain[128], *name, *ptr;
		  //		  prefix[0] = '\0';
		strcpy(domain,dpname);
		name = strchr(domain,fwFsm_separator);
		*name = '\0';
		++name;
		while((ptr = strchr(domain,fwDev_separator)))
		{
			*ptr = ':';
		}
		proxyDomain = new char[strlen(domain)+1];
	    strcpy(proxyDomain, domain);
		while((ptr = strchr(name,fwDev_separator)))
		{
			*ptr = ':';
		}
		proxyName = new char[strlen(name)+1];
//	  	  strcpy(proxyName, &name[5]);
	  	strcpy(proxyName, name);
		manId = id;
		cmnd_init = 0;
		action = 0;
		command = 0;
		toWriteCommandFlag = 0;
		toWriteBusyFlag = 0;
	    attach(proxyDomain, proxyName, 1);
		setPrintOff();
//		connectDPValue(ProxyAccess::currentParameters());
//		connectDPValue(ProxyAccess::currentState());
		sendCommandPtr = new DPElem(id, getDPName(),ProxyAccess::sendCommand());
		sendBusyPtr = new DPElem(id, getDPName(),ProxyAccess::executingAction());
	};
	~Proxy()
	{
		disconnectDPValue(ProxyAccess::currentParameters());
		disconnectDPValue(ProxyAccess::currentState());
		delete proxyName;
		delete sendCommandPtr;
		delete sendBusyPtr;
		if(proxyDomain)
			delete proxyDomain;
	}
	void smiCommandHandler();
	char *getProxyName() { return proxyName;}
	char *getProxyDomainName() { return proxyDomain;}
	void connect()
	{
		  connectDPValue(ProxyAccess::currentParameters());
		  connectDPValue(ProxyAccess::currentState());
	}
	int getWriteCommandFlag() {return toWriteCommandFlag; };
	void clearWriteCommandFlag() 
		{ toWriteCommandFlag = 0; manId->clearProxyFlag();};
	void setWriteCommandFlag() 
		{ toWriteCommandFlag++; manId->setProxyFlag();};
	int getWriteBusyFlag() {return toWriteBusyFlag; };
	void clearWriteBusyFlag() 
		{ toWriteBusyFlag = 0; manId->clearProxyFlag();};
	void setWriteBusyFlag() 
		{ toWriteBusyFlag++; manId->setProxyFlag();};
	void doSendCommand();
	void doSendBusy();
private:
	SmiManager *manId;
	void gotDPValue(DPItem *dpItem);
	char *proxyName;
	char *proxyDomain;
	int cmnd_init;
	char *getToken(char *&ptr);
	void setParameters(int n_params, char *params);
	char *action;
	char *command;
	int toWriteCommandFlag;
	int toWriteBusyFlag;
	DPElem *sendCommandPtr;
	DPElem *sendBusyPtr;
};

class ProxyItem : public SLLItem
{
public:
	ProxyItem(Proxy *fsm)
	{
		proxy = fsm; 
		found = 1;
	}
	~ProxyItem()
	{
		delete proxy;
	}
	char *getName() {return proxy->getProxyName();};
	char *getDomain() {return proxy->getProxyDomainName();};
	Proxy *getProxy() {return proxy;};
	void clearFound() {found = 0;}
	void setFound() {found = 1;}
	int isFound() {return found;}
	void setNew() {found = 2;}
	int isNew() {return (found == 2);}
private:
	Proxy *proxy;
	int found;
};

class ObjItem : public SLLItem
{
public:
	ObjItem(SMIObject *obj)
	{
		object = obj;
		found = 1;
	}
	~ObjItem()
	{
		delete object;
	}
	char *getName() {return object->getObjName();};
	SMIObject *getSmiObject() {return object;};
	void clearFound() {found = 0;}
	void setFound() {found = 1;}
	int isFound() {return found;}
private:
	SMIObject *object;
	int found;
};

void SMIDomainItem::gotDPValue(DPItem *dpItem)
{
int i;
char name[128];

	if(dpItem->cmpDPItemName(".running"))
	{
		running = dpItem->getDPItemInt();
//SmiManager::print_date_time();
//cout << " got Domain State " << domainName << " " << running << endl;
		if(running == 0)
		{
			strcpy(name, domainName);
			for(i = 0; i < (int)strlen(name); i++)
				name[i] = (char)toupper(name[i]);
			strcat(name,"_SMI/EXIT");
//SmiManager::print_date_time();
//cout << "Killing " << name << endl;
			DimClient::sendCommandNB(name, 1);
		}
	}
	manId->checkSmiDomainsRunning();
}

void SMIObject::smiStateChangeHandler()
{

	int index = 0;
	char *ptr;
	SmiParam *paramp;

	state = getState();

	if(state)
	{
//		cout << "Object " << getName() << " in state " << state << endl;
//		if(!strcmp(state,"No link"))
//		{
//			cout << "Object " << getName() << " in state " << state << endl;
//			cout << "bad" << endl;
//		}
//		addSendItem(0, stateDpElem, state);
		addSendItem(0, stateDpElemPtr, state);
//		cout << "Object " << getName() << " in state " << state << endl;
	}
//	else

	if(!state)
	{
//		addSendItem(0, stateDpElem, "DEAD");
		addSendItem(0, stateDpElemPtr, "DEAD");
//		cout << "Object " << getName() << " in NO state - DEAD " << endl; 
	}
/*
	if(n_actions = getNActions())
	{
		actions = new char*[n_actions];
		while(actionp = getNextAction())
		{
			action = actionp->getName();
			if(strncmp(action,"NV_",3))
				actions[index++] = action;
		}
		n_actions = index;
	}
*/
//    setWriteStateFlag();

	n_params = 0;
	n_params = getNParams();
//	while((int)(paramp = getNextParam()) > 0)
//		n_params++;
//	cout << "n_params = " << n_params << " test = " << getNParams() << endl;
//	cout << "n_params = " << n_params << endl;
	if(n_params)
	{
		if(!params_buffer)
			params_buffer = new char[n_params*128];
//		if(!params)
//			params = new char*[n_params];
		ptr = params_buffer;
		index = 0;
		paramp = getFirstParam();
		if((paramp = getFirstParam()) != 0)
		{
//			cout << paramp->getName() << endl;
			switch(paramp->getType())
			{
				case SMI_INTEGER:
					sprintf(ptr,"int %s = %d",paramp->getName(),paramp->getValueInt());
//					cout << paramp->getValueInt() <<endl;
					break;
				case SMI_FLOAT:
					sprintf(ptr,"float %s = %3.2f",paramp->getName(),paramp->getValueFloat());
//					cout << paramp->getValueFloat() <<endl;
					break;
				case SMI_STRING:
					sprintf(ptr,"string %s = %s",paramp->getName(),paramp->getValueString());
//					cout << paramp->getValueString() <<endl;
					break;
			}
//			params[index++] = ptr;
			strcat(ptr, "|");
			ptr += strlen(ptr);
		}
		while((paramp = getNextParam()) != 0)
		{
//			cout << paramp->getName() << endl;
			switch(paramp->getType())
			{
				case SMI_INTEGER:
					sprintf(ptr,"int %s = %d",paramp->getName(),paramp->getValueInt());
//					cout << paramp->getValueInt() <<endl;
					break;
				case SMI_FLOAT:
					sprintf(ptr,"float %s = %3.2f",paramp->getName(),paramp->getValueFloat());
//					cout << paramp->getValueFloat() <<endl;
					break;
				case SMI_STRING:
					sprintf(ptr,"string %s = %s",paramp->getName(),paramp->getValueString());
//					cout << paramp->getValueString() <<endl;
					break;
			}
//			params[index++] = ptr;
			strcat(ptr, "|");
			ptr += strlen(ptr);
		}
//		addSendItem(2, paramDpElem, params_buffer);
		addSendItem(2, paramDpElemPtr, params_buffer);
//		setWriteParamFlag();
	}
}
/*
void SMIObject::doStateChange()
{

	if(stateDpElem)
//		setDPValue(stateDpElem,state);
		addDPValue(stateDpElem,state);
}

void SMIObject::doParamChange()
{

	if(paramDpElem)
//		setDPValue(paramDpElem,params, n_params);
		addDPValue(paramDpElem,params, n_params);
}
*/
void SMIObject::smiExecutingHandler()
{

//	cout << getName() << ": Executing routine\n";
//	cout.flush();

	if(getBusy() == 1)
	{

//SmiManager::print_date_time();
//cout << getName() << ": Flagging Executing " << getActionInProgress() << endl;
//		setDPValue(".busy",(bit)1);

		busy = getActionInProgress();
//		setDPValue(".fsm.executingAction",action);
		if(busyDpElem)
		{
//SmiManager::print_date_time();
//cout << getName() << " Executing " << busy << endl;
//			setDPValue(busyDpElem,busy);
//			addDPValue(busyDpElem,busy);
//			addSendItem(1, busyDpElem, busy);
			addSendItem(1, busyDpElemPtr, busy);
		}
	}
	else
	{
//SmiManager::print_date_time();
//cout << getName() << ": Flagging NOT Busy " << endl;
		busy = 0;
//		setDPValue(".fsm.executingAction","");
		if(busyDpElem)
		{
//SmiManager::print_date_time();
//cout << getName() << " Not Busy " << endl;
//			setDPValue(busyDpElem,"");
//			addDPValue(busyDpElem,"");
//			addSendItem(1, busyDpElem, "");
			addSendItem(1, busyDpElemPtr, "");
		}
	}
//    setWriteBusyFlag();
}
/*
void SMIObject::doBusyChange()
{

	if(busyDpElem)
	{
		if(busy)
		{
//			cout << getName() << ": Executing " << busy << " DONE!" <<endl;
//			setDPValue(busyDpElem,busy);
			addDPValue(busyDpElem,busy);
		}
		else
		{
//			cout << getName() << ": NOT Busy DONE!" << endl;
//			setDPValue(busyDpElem,"");
			addDPValue(busyDpElem,"");
		}
	}

}
*/
void SMIObject::gotDPValue(DPItem *dpItem)
{
	char *name, *cmd, *src, *dst, *ptr_src, *ptr_end, *ptr_dst;

	if/*(*/(dpItem->cmpDPItemName(".fsm.sendCommand")) /*|| 
		(dpItem->cmpDPItemName("")))*/
	{
		cmd = dpItem->getDPItemString();
//		cout << " got Command " << cmd << endl;
		if(cmnd_init < 1)
		{
			cmnd_init++;
			return;
		}
//		sendCommand(lname);
		name = getName();
		if	( (strstr(name, "_FWDM")) &&
			  (strstr(cmd,"ENABLE/DEVICES") || strstr(cmd,"DISABLE/DEVICES") ) )
		{
				src = new char[strlen(cmd)+1];
				strcpy(src, cmd);
				dst = new char[strlen(cmd)+1];
				ptr_src = strchr(src, '/');
				*ptr_src = 0;
				ptr_src++;
				strcpy(dst, src);
				strcat(dst, "/DEVICE(S)=");
				ptr_dst = strchr(dst, '=');
				ptr_dst++;
				ptr_src = strchr(ptr_src, '=');
				ptr_src++;
				do
				{
					ptr_end = strchr(ptr_src, '|');
					if(ptr_end)
					{
						*ptr_end = 0;
					}
					if(*ptr_src)
					{
						strcat(dst, ptr_src);
						smiui_send_command(name, dst);
//cout << " Sent Command " << name << " " << dst << endl;
						*ptr_dst = 0;
						ptr_src = ptr_end;
						ptr_src++;
					}
				} while(ptr_end);
				delete src;
				delete dst;
		}
		else
		{
			smiui_send_command(name, cmd);
//cout << " Sent Command " << name << " " << cmd << endl;
		}

	}
}

void Proxy::smiCommandHandler()
{				
	action = getAction();
	command = getCommand();
	setWriteCommandFlag(); 
}

void Proxy::doSendCommand()
{
//	cout << "Proxy: " << proxyDomain <<"::"<<proxyName<<" executing: "<<command<< endl;
//	addDPValue(ProxyAccess::executingAction(),command);
//	addDPValue(ProxyAccess::sendCommand(),action);
	setDPValue(sendBusyPtr,command);
	setDPValue(sendCommandPtr,action);
}

void Proxy::doSendBusy()
{
//	addDPValue(ProxyAccess::executingAction(),"");
	setDPValue(sendBusyPtr,"");
}

void TmpProxy::gotDPValue(DPItem *dpItem)
{
//	Proxy *fsm;
//	ProxyItem *proxyItem;
	char *lname;
	int n;

	if(dpItem->cmpDPItemName(ProxyAccess::ctrlUnit()))
	{
		lname = dpItem->getDPItemString();
		if(lname[0])
		{
//			if(!manId->checkProxy(&proxyName[5], lname))
//			{
//				manId->addProxy(lname, proxyName);
//			}
		}
		n = manId->getNTmpProxys();
		if(index == (n-1))
		{
			manId->remProxys();
			manId->addProxys();
		}
	}
	delete this;
}

void Proxy::gotDPValue(DPItem *dpItem)
{
//	ProxyItem *proxyItem;
	char *lname;
	int n_params;
/*
	if(dpItem->cmpDPItemName(".fwDeclarations.fwCtrlDev.ctrlUnit"))
	{
		lname = dpItem->getDPItemString();
		if(lname[0])
		{
			attachProxy(lname);
//			proxyDomain = new char[strlen(lname)+1];
//	  		strcpy(proxyDomain, lname);
//			attach(proxyDomain, proxyName);
//			connectDPValue(".fwDeclarations.fwCtrlDev.fsm.currentState");
			proxyItem = new ProxyItem(this);
			manId->proxyList.add(proxyItem);
		}
		else
			delete this;
	}
*/
	if(dpItem->cmpDPItemName(ProxyAccess::currentState()))
	{
		lname = dpItem->getDPItemString();
		if(strcmp(lname,""))
		{
			setState(lname);
// CG 17/08/2011 for by fwDU ctrl script
//			setWriteBusyFlag();
////			setDPValue(ProxyAccess::executingAction(),"");
		}
/*
		else
		{
cout << "Setting Proxy State " <<proxyDomain<< "::" << proxyName << " |" 
	<< lname << "|" << endl;  
		}
*/
	}
	if(dpItem->cmpDPItemName(ProxyAccess::currentParameters()))
	{
		n_params = dpItem->getDPItemValue(lname);
		if(n_params)
			setParameters(n_params, lname);
//		setState(lname);
	}
}

char *Proxy::getToken(char *&ptr)
{
char *p, *retp;

	p = strchr(ptr,' ');
	if(p)
	{
		*p = '\0';
		p++;
	}
	retp = ptr;
	ptr = p;
	return(retp);
}

void Proxy::setParameters(int n_params, char *params)
{
	int i;
	char *ptr = params;
	char *nextp, *type, *name, *dummy, *value;
	int valint;
	float valfloat;

	nextp = ptr;
	for(i = 0; i < n_params; i++)
	{
		nextp += strlen(ptr) + 1;
		type = getToken(ptr);
		name = getToken(ptr);
//		for(j=0; j<strlen(name); j++)
//			name[j] = toupper(name[j]);
		dummy = getToken(ptr);
		value = getToken(ptr);
		if(!strcmp(type,"int"))
		{
			sscanf(value,"%d",&valint);
			setParameter(name, valint);
		}
		else if(!strcmp(type,"float"))
		{
			sscanf(value,"%f",&valfloat);
			setParameter(name, valfloat);
		}
		else
		{
			setParameter(name, value);
		}
		ptr = nextp;
	}
}

SmiManager::SmiManager(int own_system_flag) : 
	ApiManager()
{
	itsObjFlag = 0;
	itsProxyFlag = 0;
	toCheckSmiObjects = 0;
	timerRunning = 0;
	exitCode = 0;
	setOwnSystemFlag(own_system_flag);
	manStart();
}

void SmiManager::exitHandler(int code) 
{
//	cout << "code " << code << endl;
	exitCode = code;
	doExit = PVSS_TRUE;
}

void SmiManager::manExecute()
{
	ObjItem *objItem;
	ProxyItem *proxyItem;
	SMIObject *obj;
	Proxy *proxy;
	int flag, ret;
	int doit = 0, doitDns = 0;
	char str[32];
	static int doHeartBeat = 1;
	DISABLE_AST

	gTime = time((time_t *) 0);

	if(doHeartBeat)
	{
		if((gTime - gOldTime) > (MAX_BEFORE_SENDING -1 ))
		{
			gHeartBeat++;
			doit = 1;
//		gOldTime = gTime;
			setObjFlag();
		}
	}
	if(DnsVersion != DnsOldVersion)
	{
		doitDns = 1;
//		DnsOldVersion = DnsVersion;
		setObjFlag();
	}
	if ( getObjFlag() )
	{
		if((flag = getCheckSmiObjects()) != 0)
		{
			doCheckSmiObjects();
			clearCheckSmiObjects();
		}
	}
	if ( getObjFlag() )
	{
		clearDPSetList();
		objItem = (ObjItem *)objList.getHead();
		while(objItem)
		{
//			DISABLE_AST
			obj = objItem->getSmiObject();
			if(doit)
			{
				sprintf(str,"PVSS00smi_%d.heart_beat",itsManId);
				ret = obj->setDPValue(str,"",gHeartBeat);
				if(!ret)
					doHeartBeat = 0;
				doit = 0;
				gOldTime = gTime;
				clearObjFlag();
			}
			if(doitDns)
			{
				obj->setDPValue("ToDo.dim_dns_up","",DnsVersion);
				DnsOldVersion = DnsVersion;
				doitDns = 0;
				clearObjFlag();
			}
			if((flag = obj->getWriteFlag()) != 0)
			{
//				if(flag > 1)
//					cout << "*******      toWriteStateFlag = " << flag << endl;
				obj->sendItems();
			}
/*
			if((flag = obj->getWriteStateFlag()) != 0)
			{
//				if(flag > 1)
//					cout << "*******      toWriteStateFlag = " << flag << endl;
				obj->doStateChange();
				obj->clearWriteStateFlag();
			}
			if((flag = obj->getWriteParamFlag()) != 0)
			{
//				if(flag > 1)
//					cout << "*******      toWriteParamFlag = " << flag << endl;
				obj->doParamChange();
				obj->clearWriteParamFlag();
			}
			if((flag = obj->getWriteBusyFlag()) != 0)
			{
//				if(flag > 1)
//					cout << "*******      toWriteBusyFlag = " << flag << endl;
				obj->doBusyChange();
				obj->clearWriteBusyFlag();
			}
*/
//			ENABLE_AST
			objItem = (ObjItem *)objList.getNext();
		}
		sendDPSetList();
	}
	if ( getProxyFlag() )
	{
		clearDPSetList();
		proxyItem = (ProxyItem *)proxyList.getHead();
		while(proxyItem)
		{
//			DISABLE_AST
			proxy = proxyItem->getProxy();
			if((flag = proxy->getWriteBusyFlag()) != 0)
			{
//				if(flag > 1)
//					cout << "*******      toWriteStateFlag = " << flag << endl;
				proxy->doSendBusy();
				proxy->clearWriteBusyFlag();
			}
			if((flag = proxy->getWriteCommandFlag()) != 0)
			{
//				if(flag > 1)
//					cout << "*******      toWriteStateFlag = " << flag << endl;
				proxy->doSendCommand();
				proxy->clearWriteCommandFlag();
			}
//			ENABLE_AST
			proxyItem = (ProxyItem *)proxyList.getNext();
		}
		sendDPSetList();
	}
	itsObjFlag = 0;
	itsProxyFlag = 0;
	ENABLE_AST
}

void SmiManager::getRunningSmiDomains()
{
	DpIdentifier *dpIds, dp;
	char *name;
	PVSSlong nIds;
	char dp_name[128], *ptr, domain_name[128];
	int i, done;
	DpTypeId type;
	SMIDomainItem *domItem;
	CharString namestr;

	getTypeId("_FwCtrlUnit", type);
	getIdSet("*", dpIds,nIds,type);
	done = 0;
	for(i = 0; i < nIds; i++)
	{
//		Manager::getName(dpIds[i], name);
		Manager::getName(dpIds[i], namestr);
		name = (char *)namestr;
		ptr = strchr(name,':');
		++ptr;
		strcpy(dp_name,ptr);
		if((ptr = strstr(dp_name,"fwCU_")))
			strcpy(domain_name,ptr+5);
//cout << " found domain "<<domain_name << " " << dp_name << endl;
		if(!checkSmiDomain(domain_name))
		{
			domItem = new SMIDomainItem(domain_name, dp_name, this);
			domainList.add(domItem);
			done = 1;
		}
	}
}

void SmiManager::timerHandler()
{
	timerRunning = -1;
	checkSmiDomainsRunning();
}

int SmiManager::checkSmiDomainsRunning()
{
	SMIDomainItem *domItem;
	if(timerRunning == 0)
	{
		timerRunning = 1;
		DimTimer::start(1);
		return 0;
	}
	else if(timerRunning == 1)
	{
		DimTimer::stop();
		DimTimer::start(1);
		return 0;
	}
	domItem = (SMIDomainItem *)domainList.getHead();
	while(domItem)
	{
		if(domItem->getRunning() == -1)
			return 0;
		domItem = (SMIDomainItem *)domainList.getNext();
	}
	getSmiObjects();

	getSmiProxys();

	timerRunning = 0;
	return 1;
}

int SmiManager::isSmiDomainRunning(char *domain)
{
	SMIDomainItem *domItem;

	domItem = (SMIDomainItem *)domainList.getHead();
	while(domItem)
	{
		if(!strcmp(domain, domItem->getName()))
		{
			return domItem->getRunning();
		}
		domItem = (SMIDomainItem *)domainList.getNext();
	}
	return -1;
}

int SmiManager::checkSmiDomain(char *domain)
{
	SMIDomainItem *domItem;

	domItem = (SMIDomainItem *)domainList.getHead();
	while(domItem)
	{
		if(!strcmp(domain, domItem->getName()))
		{
			return 1;
		}
		domItem = (SMIDomainItem *)domainList.getNext();
	}
	return 0;
}


void SmiManager::trySmiObjs()
{
	ObjItem *objItem;

	objItem = (ObjItem *)objList.getHead();
	while(objItem)
	{
		objItem->clearFound();
		objItem = (ObjItem *)objList.getNext();
	}
}

int SmiManager::checkSmiObj(char *name)
{
	ObjItem *objItem;
	char domain[128], *ptr;
	int ret;

//cout << "Checking SmiObj " << name << endl;
	ret = 0;
	strcpy(domain, name);
	if((ptr = strstr(domain,"::")))
		*ptr = 0;
	if(isSmiDomainRunning(domain) == 0)
		ret = 1;
	objItem = (ObjItem *)objList.getHead();
	while(objItem)
	{
		if(!strcmp(name,objItem->getName()))
		{
			objItem->setFound();
			ret = 1;
			break;
		}
		objItem = (ObjItem *)objList.getNext();
	}
	return ret;
}

void SmiManager::addSmiObj(char *name, char *dpname)
{
	SMIObject *obj;
	ObjItem *objItem;

//	SmiManager::print_date_time();
//	cout << "Adding Obj: " << name << ", " <<dpname << endl;
	{
		DISABLE_AST
		obj = new SMIObject(name, dpname, this,
			".fsm.currentState",
			".fsm.currentParameters",
			".fsm.executingAction");
		ENABLE_AST
	}
//	dim_usleep(1000);
	obj->connectDPValue(".fsm.sendCommand");
	objItem = new ObjItem(obj);
	objList.add(objItem);
}

void SmiManager::remSmiObjs()
{
	ObjItem *objItem, *objp;

	objItem = (ObjItem *)objList.getHead();
	while(objItem)
	{
		if(!objItem->isFound())
		{
//			SmiManager::print_date_time();
//			cout << "Removing Obj: " << objItem->getName() << endl;
			objp = (ObjItem *)objList.getNext();
			objList.remove(objItem);
			delete objItem;
			objItem = objp;
		}
		else
			objItem = (ObjItem *)objList.getNext();
	}
}

void SmiManager::getSmiObjects()
{
	DpIdentifier *dpIds, dp;
	char *name;
	PVSSlong nIds;
	char obj_name[128], tmp[128], *ptr;
	int i;
	DpTypeId type;
	CharString namestr;

	trySmiObjs();

	getTypeId("_FwFsmObject", type);
	getIdSet("*", dpIds,nIds,type);
	for(i = 0; i < nIds; i++)
	{
//		Manager::getName(dpIds[i], name);
		Manager::getName(dpIds[i], namestr);
		name = (char *)namestr;
		ptr = strchr(name,':');
		++ptr;
		strcpy(tmp,ptr);
		strcpy(obj_name,tmp);
		ptr = strchr(obj_name,fwFsm_separator);
		*ptr = '\0';
		ptr = strchr(tmp,fwFsm_separator);
		ptr++;
		strcat(obj_name,"::");
		strcat(obj_name,ptr);
		if((ptr = strchr(obj_name,fwFsm_separator)) != 0)
		{
			*ptr = '\0';
			ptr++;
			strcpy(tmp,ptr);
			strcat(obj_name,"::");
			strcat(obj_name,tmp);
		}
		while((ptr = strchr(obj_name,fwDev_separator)))
		{
			*ptr = ':';
		}
		if(!checkSmiObj(obj_name))
		{
//cout << "Adding SMI Object " << obj_name << " " << name << endl;
			addSmiObj(obj_name, name);
		}
	}
	remSmiObjs();
}

void SmiManager::tryProxys()
{
	ProxyItem *proxyItem;

	proxyItem = (ProxyItem *)proxyList.getHead();
	while(proxyItem)
	{
		proxyItem->clearFound();
		proxyItem = (ProxyItem *)proxyList.getNext();
	}
}

int SmiManager::checkProxy(char *dpname)
{
	ProxyItem *proxyItem;
	char *name, domain[128], *ptr;
		  
	strcpy(domain,dpname);
	name = strchr(domain,fwFsm_separator);
	*name = '\0';
	++name;
	while((ptr = strchr(domain,fwDev_separator)))
	{
		*ptr = ':';
	}
	while((ptr = strchr(name,fwDev_separator)))
	{
		*ptr = ':';
	}

//cout << "Checking proxy " << dpname << " " << domain << " " << name << endl;
	if(isSmiDomainRunning(domain) == 0)
		return 1;
	proxyItem = (ProxyItem *)proxyList.getHead();
	while(proxyItem)
	{
//cout << "comparing "<< name << " " << proxyItem->getName() << " and "<<
//	domain <<" " <<proxyItem->getDomain() << endl;
		if((!strcmp(name,proxyItem->getName())) &&
		   (!strcmp(domain,proxyItem->getDomain())) )
		{
			proxyItem->setFound();
			return 1;
		}
		proxyItem = (ProxyItem *)proxyList.getNext();
	}
	return 0;
}

void SmiManager::addProxy(char *dpname)
{
	ProxyItem *proxyItem;
	Proxy *fsm;
	
	fsm = new Proxy(dpname, this);
	proxyItem = new ProxyItem(fsm);
	proxyItem->setNew();
	proxyList.add(proxyItem);
}

void SmiManager::addProxys()
{
	ProxyItem *proxyItem;
	Proxy *proxyp;

	proxyItem = (ProxyItem *)proxyList.getHead();
	while(proxyItem)
	{
		if(proxyItem->isNew())
		{
//SmiManager::print_date_time();
//cout << "********************* Adding Proxy: " << proxyItem->getDomain() << "::" << 
//proxyItem->getName() << endl;
			proxyp = proxyItem->getProxy();
			proxyp->connect();
		}
		proxyItem = (ProxyItem *)proxyList.getNext();
	}
//SmiManager::print_date_time();
//cout << "********************* Starting Dim Server" << endl; 
	DimServer::start(itsManName);
}

void SmiManager::remProxys()
{
	ProxyItem *proxyItem, *proxyp;

	proxyItem = (ProxyItem *)proxyList.getHead();
	while(proxyItem)
	{
		if(!proxyItem->isFound())
		{
//SmiManager::print_date_time();
//cout << "********************* Removing Proxy: " << proxyItem->getDomain() << "::" << 
//proxyItem->getName() << endl;
			proxyp = (ProxyItem *)proxyList.getNext();
			proxyList.remove(proxyItem);
			delete proxyItem;
			proxyItem = proxyp;
		}
		else
			proxyItem = (ProxyItem *)proxyList.getNext();
	}
}

void SmiManager::getSmiProxys()
{
	DpIdentifier *dpIds, dp;
	char *name, tmp_name[128];
	PVSSlong nIds;
	int i;
	char *ptr;
//	TmpProxy *fsm;

	DpTypeId type;
	CharString namestr;

	nTmpProxys = 0;
	tryProxys();
	getTypeId("_FwFsmDevice", type);
	getIdSet("*", dpIds,nIds,type);
	nTmpProxys += nIds;
	for(i = 0; i < nIds; i++)
	{
//		Manager::getName(dpIds[i], name);
		Manager::getName(dpIds[i], namestr);
		name = (char *)namestr;
		strcpy(tmp_name, name);
		ptr = strchr(tmp_name,':');
		++ptr;
/*
		strcpy(tmp,++ptr);
		strcpy(obj_name,tmp);
		if((ptr = strstr(obj_name,".fwDeclarations.fwCtrlDev")) != 0)
					*ptr = 0;
*/
//		fsm = new TmpProxy(ptr, i, this);
//		fsm->getDPValue(ProxyAccess::ctrlUnit());
		if(!checkProxy(ptr))
		{
//cout << "Adding Proxy " << ptr << endl;
			addProxy(ptr);
		}
	}
	remProxys();
	addProxys();

/*
    static PVSSboolean getIdSet(const char *wildName, DpIdentifier *&dpIdArr,
                                PVSSlong &howMany, DpTypeId typeId = 0);
                                
    Get the identifier for a type.
        @param typeName The type name
        @param typeID   The type id for the type name
        @param sysNum   The system to look for the type. 
        @return PVSS_TRUE if successfull
   
    static PVSSboolean getTypeId(const CharString &typeName, DpTypeId &typeId, 
        SystemNumType sysNum = DpIdentification::getDefaultSystem());                
  	
*/	
	
	
/*	
	nTmpProxys = 0;
	tryProxys();
	for(k = 0; k < 3; k++)
	{
		strcpy(str,"*.");
		for(j = 0; j < k; j++)
			strcat(str,"*.");
		strcat(str,"fwDeclarations.fwCtrlDev");
		if(getIdSet(str,dpIds,nIds,0))
		{
			nTmpProxys += nIds;
			for(i = 0; i < nIds; i++)
			{
				Manager::getName(dpIds[i], name);
				ptr = strchr(name,':');
				strcpy(tmp,++ptr);
				strcpy(obj_name,tmp);
				if((ptr = strstr(obj_name,".fwDeclarations.fwCtrlDev")) != 0)
					*ptr = 0;
				fsm = new TmpProxy(obj_name, i, this);
				fsm->getDPValue(ProxyAccess::ctrlUnit());
			}
		}
	}
	*/
}

void DnsUp::infoHandler()
{
	int version = getInt();
//	cout << "Dns Version " << version << endl;
	DnsVersion = version;
}

void SmiManager::manInitialize()
{
	
	DpIdentifier dp;
	char tmp[132];
	ManagerIdentifier manid;
	int mannum;
	SystemNumType sysid;
	int sysid1;
	DnsUp *dnsUp;
/*
	char node[128], *ptr;
	int pid;
*/	
	sysid = DpIdentification::getDefaultSystem();
	sysid1 = ((int)sysid) & ((int)0x0000FFFF);
//	SystemTable::getName((const) sysid,sysname);
//	cout << "SYSID " << (int)sysid << " " << sysid1 << endl;
	dnsUp = new DnsUp();
	manid = Manager::getMyManagerId();
	mannum = manid.getManNum();
	itsManId = mannum;
	setDispatchRate(50);
	DimServer::addExitHandler(this);
	DimServer::autoStartOff();
/*
	gethostname(node, 128);
	if(ptr = strchr(node,'.'))
		*ptr = '\0';
	pid = getpid();
*/
	sprintf(tmp,"PVSSSys%d:SMIHandler/COMMANDS",sysid1);
//  sprintf(tmp,"PVSS_%s:SMIHandler/COMMANDS",name);
	manCmnds = new DimCommand(tmp,"C",this);
	sprintf(tmp,"PVSSSys%d:SMIHandler",sysid1);
	itsManName = new char[strlen(tmp)+1];
	strcpy(itsManName,tmp);
	DimServer::start(tmp);

	getRunningSmiDomains();

//	getSmiObjects();

//	getSmiProxys();
	SmiManager::print_date_time();
	cout << itsManName << " started" << endl;
}

void SmiManager::manExit()
{
	ObjItem *objItem;
	char name[128], *nam, *ptr, aux[128];
	int i;

	if(exitCode != DIMDNSDUPLC)
	{
	objItem = (ObjItem *)objList.getHead();
	while(objItem)
	{
		nam = objItem->getName();
		strcpy(name, nam);
		if((ptr = strstr(name,"::")))
		{
			*ptr = '\0';
			ptr += 2;
			strcpy(aux, name);
			strcat(aux,"_FWM");
			if(!strcmp(aux, ptr))
			{
				for(i = 0; i < (int)strlen(name); i++)
					name[i] = (char)toupper(name[i]);
//				SmiManager::print_date_time();
//				cout << "Killing " << name << endl;
				strcat(name,"_SMI/EXIT");
				DimClient::sendCommandNB(name, 1);
			}
		}
		objItem = (ObjItem *)objList.getNext();
	}
	}
	sleep(2);
//	manExecute();
//	sleep(1);
//	fast = 0;
//	dispatch(fast, fast);

	SmiManager::print_date_time();
	cout << "Exiting... " << endl;
//	_exit(0);
}

void SmiManager::commandHandler()
{
	DimCommand *dimPtr;
	char *cmnd;

	dimPtr = getCommand();
	cmnd = dimPtr->getString();
	if(!strcmp(cmnd,"CheckSmiObjects"))
	{
//		cout << cmnd << " Received" << endl;
//		getSmiObjects();
//		getSmiProxys();
		setCheckSmiObjects();
	}
}

void SmiManager::doCheckSmiObjects()
{
//cout << " Checking SMI Objects" << endl;

	getRunningSmiDomains();
//	getSmiObjects();
//	getSmiProxys();
}

int main(int argc, char *argv[])
{
	int i;
	SmiManager *dummy;
	char dns_node[128], *ptr;
	int dns_port = 0;
	int own_system_flag = 0;

	Resources::init(argc, argv);

	dns_node[0] = '\0';
	for( i = 1; i < argc; i++)
	{
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
	SmiManager *smiManager = new SmiManager(own_system_flag);
	dummy = smiManager;

	return 0;
}
