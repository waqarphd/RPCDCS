#include <Manager.hxx>
#include <ManagerIdentifier.hxx>
#include <Resources.hxx>
#include <StartDpInitSysMsg.hxx>
#include <IntegerVar.hxx>
#include <UIntegerVar.hxx>
#include <FloatVar.hxx>
#include <DynVar.hxx>
#include <DpTypeContainer.hxx>
#include <WaitForAnswer.hxx>
#include <DpMsgAnswer.hxx>
#include <DpMsgHotLink.hxx>
#include <signal.h>
#include <string.h>
#include <iostream.h>
#include <assert.h>
#include <signal.h>
#include <stdio.h>
#include <stdlib.h>
#include <windows.h>

class ApiManager : public Manager
{
public:
	ApiManager();
	
	static PVSSboolean doExit;
	static ApiManager *myself;
	void manStart() {run();};
	void setDispatchRate(int milisecs) {dispatchRate = milisecs; };
	int getDispatchRate() {return dispatchRate; };
protected:
	void doReceive(DpMsg &dpMsg);
	void handleHotLink(const DpMsgHotLink &dpMsg);
private:
	void run();
	int dispatchRate;
};

class MyWait: public WaitForAnswer
{
public:
	MyWait()
	{
	}
	void callBack(DpMsgAnswer &answer);
};

PVSSboolean ApiManager::doExit = PVSS_FALSE;
ApiManager *ApiManager::myself = 0;

int msg_id = 0;
			
void print_date_time_lib()
{
	time_t t;
	char str[128];

	t = time((time_t *)0);
	strcpy(str, ctime(&t));
	str[strlen(str) - 1] = '\0';
	cout << "ApiLib - " << str << "\n\t";
}

void handleSignal(int)
{
//	cout << "About to exit... " << endl;
//	ApiManager::myself->manExit();
	ApiManager::doExit = PVSS_TRUE;
}

ApiManager::ApiManager() :
	Manager(ManagerIdentifier(API_MAN, 
		Resources::getManNum()))
{
	myself = this;
	dispatchRate = 100;
	signal(SIGINT, handleSignal); 
	signal(SIGTERM, handleSignal);
}

void ApiManager::doReceive(DpMsg &dpMsg)
{

	switch(dpMsg.isA())
	{
		case DP_MSG_HOTLINK:
			handleHotLink((const DpMsgHotLink &)dpMsg);
			break;
		default:
//			cout << "Calling Standard manager\n";
//			cout.flush();
			Manager::doReceive(dpMsg);
			break;
	}
}

void ApiManager::handleHotLink(const DpMsgHotLink &dpMsg)
{
	DpHLGroup *group;
	DpVCItem *item;

	cout << "Receiving HotLink" << endl;
	group = dpMsg.getFirstGroup();
	while(group)
	{
		item = group->getFirstItem();
		while(item)
		{
			char *name;

			item->debug(cout, 1);
			cout << endl;
			name = 0;
			Manager::getName(item->getDpIdentifier(),name);
			cout << "Received message from " << name << endl;
//#ifndef WIN32
			delete name;
//#endif
			item = group->getNextItem();
		}
		group = dpMsg.getNextGroup();
	}
}

void ApiManager::run()
{
	long sec, usec;
	PVSSboolean initialized = PVSS_FALSE;

	connectToData(StartDpInitSysMsg::TYPE_CONTAINER | StartDpInitSysMsg::DP_IDENTIFICATION);

	for(;;)
	{
		if (doExit)
			break;
		sec = 0;
		usec = dispatchRate * 1000;
		if(usec >= 1000000)
		{
			sec = usec / 1000000;
			usec -= sec * 1000000;
		}
		dispatch(sec, usec);

		if (getManagerState() == STATE_ADJUST)
			connectToEvent();
		else if (getManagerState() == STATE_RUNNING)
		{
			if (!initialized)
			{
				initialized = PVSS_TRUE;
				{
					char tmp[256];
					DpIdentifier dpId;
					MyWait *wait;
					PVSSboolean ret;

					wait = new MyWait();
					strcpy(tmp,"_mp_ANALOG1.value:_online.._value");
					if(getId(tmp, dpId))
					{
						ret = dpConnect(dpId, wait);
					}
				}
//				manInitialize();
			}
//			manExecute();
			// do work
		}
	}
//	manExit();
	Manager::exit(0);
}

void MyWait::callBack(DpMsgAnswer &answer)
{
	if (answer.getFirstGroup()->getError())
	{
//		cout << "negative answer arrived for " << num << endl;
		ErrHdl::error(*answer.getFirstGroup()->getError());
	}
	else
	{
//		cout << "positive answer arrived for " << num << endl;
//		manId->doReceive(answer);
		
		AnswerGroup *group;
		AnswerItem *item;

		group = answer.getFirstGroup();
		while(group)
		{
		item = group->getFirstItem();
			while(item)
			{
				item->debug(cout, 1);
				cout << endl;
				item = group->getNextItem();
			}
			group = answer.getNextGroup();
		}

	}
}

int main(int argc, char *argv[])
{

	Resources::init(argc, argv);

	ApiManager *testManager = new ApiManager();

	testManager->manStart();
	
	return 0;
}
