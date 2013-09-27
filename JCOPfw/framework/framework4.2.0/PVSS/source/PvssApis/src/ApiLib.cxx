#include "ApiLib.hxx"
#include <sys/timeb.h>
#include <signal.h>

PVSSboolean ApiManager::doExit = PVSS_FALSE;
ApiManager *ApiManager::myself = 0;

int msg_id = 0;
//int CountDPSetList = 0;
//int CountDPSetItems = 0;
			
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
	Manager(ManagerIdentifier(DEVICE_MAN/*API_MAN*/, 
		Resources::getManNum()))
{
	myself = this;
	dispatchRate = 100;
	dispatchFlag = 0;
	signal(SIGINT, handleSignal); 
	signal(SIGTERM, handleSignal);
	DPSetList = 0;
	ownSystemOnly = 0;
//	DPSetListTime = 0;
}

void ApiManager::doReceive(DpMsg &dpMsg)
{
	DISABLE_AST

	switch(dpMsg.isA())
	{
		case DP_MSG_HOTLINK:
			handleHotLink((const DpMsgHotLink &)dpMsg);
			break;
		default:
//			print_date_time_detailed();
//			cout << "Calling Standard manager\n";
//			cout.flush();
			Manager::doReceive(dpMsg);
			break;
	}
	ENABLE_AST
}

void ApiManager::handleHotLink(const DpMsgHotLink &dpMsg)
{
	DpHLGroup *group;
	DpVCItem *item;
	int n = 0;
	char *name;
	CharString namestr;

//	print_date_time_detailed();
//	cout << "***** Receiving HotLink" << endl;
//	DISABLE_AST
	group = dpMsg.getFirstGroup();
	while(group)
	{
		item = group->getFirstItem();
		while(item)
		{
			DPItem *dpItem;

//			DISABLE_AST
//			item->debug(cout, 1);
//			cout << endl;
			name = 0;
//			dpItem = findDPItemById((const DpIdentifier)item->getDpIdentifier());
//			namestr = new CharString();
			Manager::getName(item->getDpIdentifier(),namestr);
//			Manager::getName(item->getDpIdentifier(),name);
			name = (char *)namestr;
//cout << "ApiLib got "<< name << endl;
			if(name != 0)
			{
//				dpItem = getDPItem(name);
				dpItem = findDPItem(name);
//#ifndef WIN32
//				delete namestr;
//				delete[] name;
//#endif
				if(dpItem)
				{
//					name = dp->getNamePtr();
//					dpItem = dp->getDPItem(name);
					dpItem->setValue(item->getValuePtr());
					dpItem->setRead();
					dpItem->getDp()->gotDPValue(dpItem);
//					item = group->getNextItem();
					n++;
				}
			}
			item = group->getNextItem();
//			ENABLE_AST
		}
		group = dpMsg.getNextGroup();
	}
	gotDpValues();

//	print_date_time_detailed();
//	cout << "***** Done HotLink" << endl;
//	ENABLE_AST
}

int getTime(int *secs, int *millis)
{
	struct timeb timebuf;
				
	ftime(&timebuf);
	*secs = timebuf.time;
	*millis = timebuf.millitm;
	return 1;
}

void ApiManager::print_date_time_detailed()
{
	time_t t;
	char str[128], str1[10], *ptr;
	struct timeb timebuf;

	ftime(&timebuf);
	t = time((time_t *)0);
	strcpy(str, ctime(&t));
	str[strlen(str) - 1] = '\0';
	ptr = strstr(str," 200");
	if(ptr)
	{
		sprintf(str1,".%d",timebuf.millitm);
		strcat(str1,ptr);
		*ptr = '\0';
	}
	strcat(str,str1);
	cout << "ApiLib - " << str << "\n\t";
}

int ApiManager::get_millis()
{
//	time_t t;
//	char str[128], str1[10];
	struct timeb timebuf;

	ftime(&timebuf);
//	t = time((time_t *)0);
//	strcpy(str, ctime(&t));
	return(timebuf.millitm);
//	strcat(str,str1);
//	cout << "ApiLib - " << str << "\n\t";
}

void ApiManager::run()
{
	long sec, usec, fast;
	PVSSboolean initialized = PVSS_FALSE;
//	int secs, millis, millis_new, delay;

	if(!ownSystemOnly)
		connectToData(StartDpInitSysMsg::TYPE_CONTAINER | StartDpInitSysMsg::DP_IDENTIFICATION);
	else
		connectToData(StartDpInitSysMsg::TYPE_CONTAINER | StartDpInitSysMsg::DP_IDENTIFICATION |
					  StartDpInitSysMsg::OWN_SYSTEM);

	fast = 0;
	for(;;)
	{
		if (doExit)
		{
//			manExit();
			break;
		}
/*
		sec = 0;
		usec = 100;
*/
		sec = 0;
		usec = dispatchRate * 1000;
		if(usec >= 1000000)
		{
			sec = usec / 1000000;
			usec -= sec * 1000000;
		}
//		cout << "dispatch " << dispatchRate << "---" << sec <<"." <<usec << endl;
//		getTime(&secs, &millis);
//		cout << "dispatch " << secs <<"." <<millis << endl;

		if(dispatchFlag > 0)
		{
//			ApiManager::print_date_time_detailed();
//			cout << "entering dispatch(0)" << endl;
//			millis = get_millis();
			fast = 0;
			dispatch(fast, fast);
//			millis_new = get_millis();
//			delay = millis_new - millis;
//			if((delay) > 10)
//			{
//				ApiManager::print_date_time_detailed();
//				cout << "dispatch(0,0) took " << delay << " milliseconds" <<endl;
//			}
			dispatchFlag--;
//			ApiManager::print_date_time_detailed();
//			cout << "exiting dispatch(0)" << endl;
		}
		else
		{
//			ApiManager::print_date_time_detailed();
//			cout << "entering dispatch( long )" << endl;
//			millis = get_millis();
			dispatch(sec, usec);
//			millis_new = get_millis();
//			if((millis_new - millis) > 10)
//			{
//				ApiManager::print_date_time_detailed();
//				cout << "dispatch(time) took " << millis_new - millis << endl;
//			}
//			ApiManager::print_date_time_detailed();
//			cout << "exiting dispatch( long)" << endl;
		}
//		mydispatch(sec, usec);

//		getTime(&secs, &millis);
//		cout << "out of dispatch"<< secs <<"." <<millis << endl;
		if (getManagerState() == STATE_ADJUST)
			connectToEvent();
		else if (getManagerState() == STATE_RUNNING)
		{
			if (! isEvConnOpen())
				doExit = 1;
			if (!initialized)
			{
				initialized = PVSS_TRUE;
				manInitialize();
			}
			// do work
			manExecute();
		}
	}
	manExit();
	Manager::exit(0);
}
/*
#include <windows.h>
void ApiManager::mydispatch(long &secs, long &usecs)
{
long t, fast = 0;

cout << "in" <<endl;
	t = secs*1000000 + usecs;
	while( t > 0)
	{
		if(dispatchFlag)
			return;
		ApiManager::print_date_time_detailed();
		cout << "entering usleep" << endl;
		Sleep(1);
		ApiManager::print_date_time_detailed();
		cout << "exiting usleep" << endl;
		dispatch(fast,fast);
		t -= 10;
	}
cout << "out" << endl;
}
*/

int ApiManager::clearDPSetList()
{
//cout << "Clear List" << endl;
//	if(DPSetList)
//	{
//		delete DPSetList;
//		DPSetList = 0;
//	}
//	DPSetList = new DpIdValueList();
//print_date_time_lib();
//cout << "removing All" << endl;


//print_date_time_lib();
//cout << "Removed All" << endl;
	if(!DPSetList)
	{
		DPSetList = new DpIdValueList();
//print_date_time_lib();
//char tstr[128];
//sprintf(tstr,"%08X",DPSetList);
//CountDPSetList++;
//cout << "+++++ clearDPSetList" << " new DpIdValueList " << tstr << " " << CountDPSetList << endl;
//		DPsToSend.removeAll();
	}
	return 1;
}

/*
int ApiManager::clearDPSetList()
{
//TimeVar time;
//DpMsgComplexVC *dpMsg;

	if(!DPSetList)
	{
//		DPSetList = new DpIdValueList();
		DPSetList = new DpMsgComplexVC();
		if(DPSetListTime)
			delete DPSetListTime;
		DPSetListTime = 0;
		DPsToSend.removeAll();
	}
	return 1;
}
*/
/*
int ApiManager::addDPSetItem(DpIdentifier &dpId, Variable &value, char *dpName)
{
//	char *dpName;
	HASHItem *dpItem;

//	Manager::getName(dpId, dpName);

//if(strstr(dpName, "10000"))
//{
//	char str[100];
//	cout << "Adding DP: " << dpName << endl;
//	sprintf(str,"%x",dpId);
//	cout << "dpId " << str << endl;
//}

	if(DPsToSend.find(dpName))
	{
//	cout << "Adding DP: " << dpName << endl;
//		printTable();
		sendDPSetList();
		clearDPSetList();
	}
	dpItem = new HASHItem();
	DPsToSend.add(dpName, dpItem);

//	delete dpName;

	DPSetList->appendItem(dpId, value);
	if(DPSetList->getNumberOfItems() >= 5000)
	{
		sendDPSetList();
		clearDPSetList();
	}
	return 1;
}
*/

int ApiManager::addDPSetItem(DpIdentifier &dpId, Variable &value, char *dpName)
{
	DPSetHASHItem *dpItem;
	int sendFlag;
//	int sendFlag = 1;

//	if(DPsToSend.find(dpName))
//	{
//		sendFlag = 0;
//	}
	sendFlag = DPsToSend.findN(dpName);
	dpItem = new DPSetHASHItem(dpId, value, sendFlag);
//print_date_time_lib();
//char tstr[128];
//sprintf(tstr,"%08X",dpItem);
//CountDPSetItems++;
//cout << "+++++ addDPSetItem" << " new DPSetHASHItem " << tstr << " " << CountDPSetItems << endl;
	DPsToSend.add(dpName, dpItem);
//cout << "adding " << dpName << " nItems = " << DPsToSend.getNItems() <<endl;

	if(DPsToSend.getNItems() >= 5000)
	{
		sendDPSetList();
		clearDPSetList();
	}

//	DPSetList->appendItem(dpId, value);
//	if(DPSetList->getNumberOfItems() >= 5000)
//	{
//		sendDPSetList();
//		clearDPSetList();
//	}
	return 1;
}


/*
int ApiManager::addDPSetItem(DpIdentifier &dpId, Variable &value, char *dpName)
{
	HASHItem *dpItem;

	if(DPsToSend.find(dpName))
	{
		sendDPSetList();
		clearDPSetList();
	}
	dpItem = new HASHItem();
	DPsToSend.add(dpName, dpItem);

	{
		DpVCItem *item;
		DpVCGroup *group;

		if(!DPSetListTime)
			DPSetListTime = new TimeVar();
		group = new DpVCGroup(getMyManagerId(), getUserId(), *DPSetListTime);
		item = new DpVCItem(dpId, value);
		//		group->insertValueChange(dpId, &value);
		group->append(item);
		DPSetList->insertGroup(group);
		if(DPSetList->getNumberOfGroups() >= 5000)
		{
			sendDPSetList();
			clearDPSetList();
		}
	}
	return 1;
}
*/

int ApiManager::sendDPSetList()
{
	PVSSboolean ret = 0;

	int n;
//	MySetWait *wait;

	DISABLE_AST
	makeDPSetList();
	if(DPSetList)
	{
		if((n = DPSetList->getNumberOfItems()) > 0)
		{
//print_date_time_detailed();
//cout << "Setting " << n << " items " << endl;
//			wait = new MySetWait();
//			ret = dpSet(*DPSetList, wait);
			ret = dpSet(*DPSetList);
//			ret = myDpSet(*DPSetList);
			if(ret != PVSS_TRUE)
			{
				print_date_time_lib();
				cout << "dpSetMultiple: " << "returned PVSS_FALSE, Exiting..."<<endl;
//cout << "Setting " << n << " items " << endl;
				doExit = 1;
			}
//print_date_time_lib();
//cout << "Done " << n << " items " << endl;
//print_date_time_lib();
//char tstr[128];
//sprintf(tstr,"%08X",DPSetList);
//CountDPSetList--;
//cout << "----- sendDPSetList" << " delete DpIdValueList " << tstr << " " << CountDPSetList << endl;
			delete DPSetList;
			DPSetList = 0;
			freeDPSetList();
//print_date_time_detailed();
//cout << "Done! Setting " << n << " items " << endl;
		}
	}
//	if(DPSetList)
//	{
//cout << "Finished setting" << endl;
//	}
	ENABLE_AST
	return (int)ret;
}

int ApiManager::myDpSet(DpIdValueList &dpIdValList)
{
	DpMsgComplexVC dpMsg;
	TimeVar thisTime;
	DpVCGroup group(getMyManagerId(), getUserId(), thisTime);
//	DpVCGroup *group;
	DpVCItem *item, *next_item;
	int ret;
	DpIdValueList dpIdList = dpIdValList;

	item = dpIdList.getFirstItem();
	while( item != 0)
	{
		next_item = dpIdList.getNextItem();
//cout << item << endl;
//		group = new DpVCGroup(getMyManagerId(), getUserId(), thisTime);
//		group->insertValueChange(item->getDpIdentifier(),(Variable *)&(item->getValue()));
		group.append(item);
//cout << item << " " << tmp << endl;

/*
		dpMsg.insertValueChange(Manager::getMyManagerId(),
        Manager::getUserId(),
        thisTime,
        item->getDpIdentifier(),
        item->getValue());
*/
//	  ret = dpMsg.insertGroup(group);
//cout << "insert Group "<< ret << endl;
//    item = dpIdList.getNextItem();
	  item = next_item;
//cout << "item  = " << item << endl;
	}
	ret = dpMsg.insertGroup(group);
cout << " groups: " << dpMsg.getNrOfGroups() << endl;
cout << " items: " << group.getNumberOfItems() << endl;

	ret = send(dpMsg/*, target, wait, del*/);
	return ret;
}

/*
int ApiManager::sendDPSetList()
{
	PVSSboolean ret = 0;

	int n;

	DISABLE_AST
	if(DPSetList)
	{
		if((n = DPSetList->getNumberOfGroups()) > 0)
		{
			ret = Manager::send(*DPSetList);
//			ret = dpSet(*DPSetList);
			if(ret != PVSS_TRUE)
			{
				print_date_time_lib();
				cout << "dpSetMultiple: " << "returned PVSS_FALSE, Exiting..."<<endl;
				doExit = 1;
			}
			delete DPSetList;
			DPSetList = 0;
		}
	}
	ENABLE_AST
	return (int)ret;
}
*/
void ApiManager::printTable()
{
	HASHItem *item;
	int n = 0;

	item = (HASHItem *)DPsToSend.getHead();
	while(item)
	{
		cout << n << " Item: " << item->getKey() << endl;
		n++;
		item = (HASHItem *)DPsToSend.getNext();
	}
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
		DPItem *dpItem;
		int n = 0;

//		ApiManager::print_date_time_detailed();
//	cout << "***** Receiving Answer" << endl;
		group = answer.getFirstGroup();
		while(group)
		{
			item = group->getFirstItem();
			while(item)
			{
//				item->debug(cout, 1);
//				cout << endl;
				dpItem = getDPItem();
				dpItem->setValue(item->getValuePtr());
				dpItem->setRead();
				dpItem->getDp()->gotDPValue(dpItem);
				n++;
				item = group->getNextItem();
			}
			group = answer.getNextGroup();
		}
	}
//	delete this;
}

//void MySetWait::callBack(DpMsgAnswer &answer)
//{
/*
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
		DPItem *dpItem;
		int n = 0;;

		group = answer.getFirstGroup();
		while(group)
		{
			item = group->getFirstItem();
			while(item)
			{
//cout << "answer received for :" << endl;
//				item->debug(cout, 1);
//				cout << endl;
				dpItem = getDPItem();
cout << "answer received for " << dpItem->getDPItemName() << endl;
				dpItem->setValue(item->getValuePtr());
				dpItem->setRead();
				dpItem->getDp()->gotDPValue(dpItem);
				n++;
				item = group->getNextItem();
			}
			group = answer.getNextGroup();
		}
	}
*/
//}

int DP::getDPId(const char *name, DpIdentifier &dpId, char *func)
{
//	cout << getDPName() << "\t\t - getting ID: " << name << " from: " << func << endl;
	return manId->getId(name, dpId);
}

int DP::getDPId(DPElem *elem, DpIdentifier &dpId, ATTR_TYPES attr)
{
//	cout << elem->getDPElemName() << "\t\t - getting ELEM ID: " << attr << endl;
	switch(attr)
	{
	case ATTR_VALUE:
		dpId = elem->getValueId();
		break;
	case ATTR_USER8:
		dpId = elem->getUser8Id();
		break;
	case ATTR_USER7:
		dpId = elem->getUser7Id();
		break;
	case ATTR_USER6:
		dpId = elem->getUser6Id();
		break;
	case ATTR_USER5:
		dpId = elem->getUser5Id();
		break;
	case ATTR_USER1:
		dpId = elem->getUser1Id();
		break;
	case ATTR_INV:
		dpId = elem->getInvId();
		break;
	}
	return 1;
}

void DP::setStime(time_t tsecs, int millies)
{
	stimeSecs = tsecs;
	stimeMillies = (PVSSlong)millies;
}

void DP::clearStime()
{
	stimeSecs = (time_t)0;
	stimeMillies = 0;
}

int DP::getDPValue(char *item)
{
	char tmp[256];
	DpIdentifier dpId;
	DPItem *dpItem;
	MyWait *wait;
	PVSSboolean ret = 0;
	
	DISABLE_AST
	dpItem = new DPItem(item, this);
//	itemList.add(dpItem);

	strcpy(tmp,dpName);
	strcat(tmp,item);
	strcat(tmp,":_online.._value");
	if(getDPId(tmp, dpId, "getDPValue1"))
	{
		wait = new MyWait(dpItem);
		ret = manId->dpGet(dpId, wait);
	}
	ENABLE_AST
	return (int)ret;
}

int DP::getDPValue(char *name, char *item)
{
	char tmp[256];
	DpIdentifier dpId;
	DPItem *dpItem;
	MyWait *wait;
	PVSSboolean ret = 0;
	
	DISABLE_AST
	dpItem = new DPItem(name, item, this);
//	itemList.add(dpItem);

	strcpy(tmp,dpName);
	strcat(tmp,item);
	strcat(tmp,":_online.._value");
	if(getDPId(tmp, dpId, "getDPValue2"))
	{
		wait = new MyWait(dpItem);
		ret = manId->dpGet(dpId, wait);
	}
	ENABLE_AST
	return (int)ret;
}

int DP::connectDPValue(char *item)
{
	char tmp[256];
	DpIdentifier dpId;
	DPItem *dpItem;
	MyWait *wait;
	PVSSboolean ret = 0;

	DISABLE_AST
	dpItem = new DPItem(item, this);
//	itemList.add(dpItem);

	strcpy(tmp,dpName);
	strcat(tmp,item);
	strcat(tmp,":_online.._value");

//	manId->addDPItem(dpItem, tmp);
	if(getDPId(tmp, dpId, "connectDPValue1"))
	{
//		dpItem->setDpItemId(dpId);
		manId->addDPItem(dpItem, tmp);
		wait = new MyWait(dpItem);
		dpItem->connected(tmp);
		ret = manId->dpConnect(dpId, wait);
	}
	ENABLE_AST
	return (int)ret;
}

int DP::connectDPValue(char *name, char *item)
{
	char tmp[256];
	DpIdentifier dpId;
	DPItem *dpItem;
	MyWait *wait;
	DpIdentifier dp;
	char *ptr; //, *full_name = 0;
	PVSSboolean ret = 0;

	DISABLE_AST
	dpItem = new DPItem(name, item, this);
//	itemList.add(dpItem);

//	manId->getId(name, dp);
//	manId->getName(dp, full_name);
//	strcpy(tmp,full_name);
	strcpy(tmp,name);
	strcat(tmp,item);
	if((ptr = strchr(tmp,':')))
	{
		ptr++;
		ptr = strchr(ptr,':');
	}
	if(!ptr)
		strcat(tmp,":_online.._value");

//	manId->addDPItem(dpItem, tmp);

//#ifndef WIN32
//	if(full_name)
//		delete full_name;
//#endif
	if(getDPId(tmp, dpId, "connectDPValue2"))
	{
//		dpItem->setDpItemId(dpId);
		manId->addDPItem(dpItem, tmp);
		wait = new MyWait(dpItem);
		dpItem->connected(tmp);
		ret = manId->dpConnect(dpId, wait);
	}
	ENABLE_AST
	return (int)ret;
}

int DP::disconnectDPValue(char *item)
{
	char tmp[256];
	DpIdentifier dpId;
	DPItem *dpItem;
	PVSSboolean ret = 0;

	DISABLE_AST
	strcpy(tmp,dpName);
	strcat(tmp,item);
	strcat(tmp,":_online.._value");

	dpItem = manId->findDPItem(tmp);
	if(getDPId(tmp, dpId, "disconnectDPValue1"))
	{
		ret = manId->dpDisconnect(dpId);
	}
	delete dpItem;
	ENABLE_AST
	return (int)ret;
}

int DP::disconnectDPValue(char *name, char *item)
{
	char tmp[256];
	DpIdentifier dpId;
	DPItem *dpItem;
	DpIdentifier dp;
	char *ptr;
	PVSSboolean ret = 0;

	DISABLE_AST
	strcpy(tmp,name);
	strcat(tmp,item);
	if((ptr = strchr(tmp,':')))
	{
		ptr++;
		ptr = strchr(ptr,':');
	}
	if(!ptr)
		strcat(tmp,":_online.._value");

	dpItem = manId->findDPItem(tmp);
	if(getDPId(tmp, dpId, "disconnectDPValue2"))
	{
		ret = manId->dpDisconnect(dpId);
	}
	delete dpItem;
	ENABLE_AST
	return (int)ret;
}

int DP::doSetDpValue(char *dp, Variable &value)
{
	DpIdentifier dpId;
	PVSSboolean ret = 0;
	int retry = 5;
	PVSSTime ptime;
	TimeVar tVar;

	DISABLE_AST
	if(getDPId(dp, dpId, "doSetDpValue"))
	{
		if((manId->collectingDPs()) && (stimeSecs == (time_t)0))
		{
			ret = manId->addDPSetItem(dpId, value, dp);
		}
		else
		{
			while(retry--)
			{
				if(stimeSecs != (time_t)0)
				{
					ptime.setValue(stimeSecs, stimeMillies); 
					tVar.setValue(ptime);
					ret = manId->dpSetTimed(tVar, dpId, value);
				}
				else
				{
					ret = manId->dpSet(dpId, value);
				}
				if(ret == PVSS_TRUE)
					break;
			}
			if(ret != PVSS_TRUE)
			{
				print_date_time_lib();
				cout << "dpSet: " << dp << " returned PVSS_FALSE, Exiting..."<<endl;
				manId->doExit = 1;
			}
		}
	}
	else
	{
		if(!strstr(dp, ".heart_beat:"))
		{
			print_date_time_lib();
			cout << "dpSet: " << dp << " Does Not Exist"<<endl;
		}
	}
	ENABLE_AST
	return (int)ret;
}


int DP::setDPValue(char *item, char *value)
{
	char tmp[256];
	DpIdentifier dpId;
	TextVar valueVar;

	strcpy(tmp,dpName);
	strcat(tmp,item);
	strcat(tmp,":_original.._value");
	valueVar.setValue(value);
	return doSetDpValue(tmp, valueVar);
}

int DP::addDPValue(char *item, char *value)
{
	char tmp[256];
	DpIdentifier dpId;
	TextVar valueVar;
	int ret = 0;

	strcpy(tmp,dpName);
	strcat(tmp,item);
	strcat(tmp,":_original.._value");
	valueVar.setValue(value);
	{
	DISABLE_AST
	if(getDPId(tmp, dpId,"addDPValue1"))
	{
		manId->addDPSetItem(dpId, valueVar, tmp);
		ret = 1;
	}
	ENABLE_AST
	}
	return ret;
}

int DP::setDPValue(char *item, char **value, int size)
{
	char tmp[256];
	int i;
	DpIdentifier dpId;
	TextVar valueVar;
	DynVar dynValueVar;

	strcpy(tmp,dpName);
	strcat(tmp,item);
	strcat(tmp,":_original.._value");
	if(!size)
	{
		valueVar.setValue("");
		dynValueVar.append(valueVar);
		dynValueVar.clear();
	}
	for(i = 0; i <size; i++)
	{
		valueVar.setValue(value[i]);
		dynValueVar.append(valueVar);
	}
	return doSetDpValue(tmp, dynValueVar);
}

int DP::addDPValue(char *item, char **value, int size)
{
	char tmp[256];
	int i;
	DpIdentifier dpId;
	TextVar valueVar;
	DynVar dynValueVar;
	int ret = 0;

	strcpy(tmp,dpName);
	strcat(tmp,item);
	strcat(tmp,":_original.._value");
	if(!size)
	{
		valueVar.setValue("");
		dynValueVar.append(valueVar);
		dynValueVar.clear();
	}
	for(i = 0; i <size; i++)
	{
		valueVar.setValue(value[i]);
		dynValueVar.append(valueVar);
	}
	{
	DISABLE_AST
	if(getDPId(tmp, dpId,"addDPValue2"))
	{
		manId->addDPSetItem(dpId, dynValueVar, tmp);
		ret = 1;
	}
	ENABLE_AST
	}
	return ret;
}

int DP::setDPValue(char *item, bit value)
{
	char tmp[256];
	DpIdentifier dpId;
	BitVar valueVar;

	strcpy(tmp,dpName);
	strcat(tmp,item);
	strcat(tmp,":_original.._value");
	if(value & 0x1)
		valueVar.setValue(PVSS_TRUE);
	else
		valueVar.setValue(PVSS_FALSE);
	return doSetDpValue(tmp, valueVar);
}

int DP::setDPValue(char *item, bitset value)
{
	char tmp[256];
	DpIdentifier dpId;
	Bit32Var valueVar;

	strcpy(tmp,dpName);
	strcat(tmp,item);
	strcat(tmp,":_original.._value");
	valueVar.setValue(value);
	return doSetDpValue(tmp, valueVar);
}

int DP::setDPValue(char *item, time_t value)
{
	char tmp[256];
	DpIdentifier dpId;
	PVSSTime ptime;
//	PVSSlong millies;
	TimeVar valueVar;

	strcpy(tmp,dpName);
	strcat(tmp,item);
	strcat(tmp,":_original.._value");
//	millies = 0;
	ptime.setValue(value, 0); 
	valueVar.setValue(ptime);
//	valueVar.setSeconds(value);
	return doSetDpValue(tmp, valueVar);
}

int DP::setDPValue(char *item, int value)
{
	char tmp[256];
	DpIdentifier dpId;
	IntegerVar valueVar;

	strcpy(tmp,dpName);
	strcat(tmp,item);
	strcat(tmp,":_original.._value");
	valueVar.setValue(value);
	return doSetDpValue(tmp, valueVar);
}

int DP::setDPValue(char *item, unsigned int value)
{
	char tmp[256];
	DpIdentifier dpId;
	UIntegerVar valueVar;

	strcpy(tmp,dpName);
	strcat(tmp,item);
	strcat(tmp,":_original.._value");
	valueVar.setValue(value);
	return doSetDpValue(tmp, valueVar);
}

int DP::setDPValue(char *item, int *value, int size)
{
	char tmp[256];
	int i;
	DpIdentifier dpId;
	IntegerVar valueVar;
	DynVar dynValueVar;

	strcpy(tmp,dpName);
	strcat(tmp,item);
	strcat(tmp,":_original.._value");
	if(!size)
	{
		valueVar.setValue(0);
		dynValueVar.append(valueVar);
		dynValueVar.clear();
	}
	for(i = 0; i <size; i++)
	{
		valueVar.setValue(value[i]);
		dynValueVar.append(valueVar);
	}
	return doSetDpValue(tmp, dynValueVar);
}

int DP::setDPValue(char *item, unsigned int *value, int size)
{
	char tmp[256];
	int i;
	DpIdentifier dpId;
	UIntegerVar valueVar;
	DynVar dynValueVar;

	strcpy(tmp,dpName);
	strcat(tmp,item);
	strcat(tmp,":_original.._value");
	if(!size)
	{
		valueVar.setValue(0);
		dynValueVar.append(valueVar);
		dynValueVar.clear();
	}
	for(i = 0; i <size; i++)
	{
		valueVar.setValue(value[i]);
		dynValueVar.append(valueVar);
	}
	return doSetDpValue(tmp, dynValueVar);
}

int DP::setDPValue(char *item, float value)
{
	char tmp[256];
	DpIdentifier dpId;
	FloatVar valueVar;

	strcpy(tmp,dpName);
	strcat(tmp,item);
	strcat(tmp,":_original.._value");
	valueVar.setValue(value);
	return doSetDpValue(tmp, valueVar);
}

int DP::setDPValue(char *item, float *value, int size)
{
	char tmp[256];
	int i;
	DpIdentifier dpId;
	FloatVar valueVar;
	DynVar dynValueVar;

	strcpy(tmp,dpName);
	strcat(tmp,item);
	strcat(tmp,":_original.._value");
	if(!size)
	{
		valueVar.setValue(0);
		dynValueVar.append(valueVar);
		dynValueVar.clear();
	}
	for(i = 0; i <size; i++)
	{
		valueVar.setValue(value[i]);
		dynValueVar.append(valueVar);
	}
	return doSetDpValue(tmp, dynValueVar);
}

int DP::setDPValue(char *item, double value)
{
	char tmp[256];
	DpIdentifier dpId;
	FloatVar valueVar;

	strcpy(tmp,dpName);
	strcat(tmp,item);
	strcat(tmp,":_original.._value");
	valueVar.setValue(value);
	return doSetDpValue(tmp, valueVar);
}

int DP::setDPValue(char *item, double *value, int size)
{
	char tmp[256];
	int i;
	DpIdentifier dpId;
	FloatVar valueVar;
	DynVar dynValueVar;

	strcpy(tmp,dpName);
	strcat(tmp,item);
	strcat(tmp,":_original.._value");
	if(!size)
	{
		valueVar.setValue(0);
		dynValueVar.append(valueVar);
		dynValueVar.clear();
	}
	for(i = 0; i <size; i++)
	{
		valueVar.setValue(value[i]);
		dynValueVar.append(valueVar);
	}
	return doSetDpValue(tmp, dynValueVar);
}

int DP::setDPValue(char *name, char *item, char value)
{
	char tmp[256];
	DpIdentifier dpId;
	CharVar valueVar;
	DpIdentifier dp;
//	char *full_name = 0;

//	DISABLE_AST
//	manId->getId(name, dp);
//	manId->getName(dp, full_name);
//	ENABLE_AST
//	strcpy(tmp,full_name);
	strcpy(tmp,name);
	strcat(tmp,item);
	strcat(tmp,":_original.._value");
//#ifndef WIN32
//	delete full_name;
//#endif
	valueVar.setValue(value);
	return doSetDpValue(tmp, valueVar);
}

int DP::setDPValue(char *name, char *item, char *value, int size)
{
	char tmp[256];
	int i;
	DpIdentifier dpId;
	CharVar valueVar;
	DynVar dynValueVar;
	DpIdentifier dp;
//	char *full_name = 0;

//	DISABLE_AST
//	manId->getId(name, dp);
//	manId->getName(dp, full_name);
//	ENABLE_AST
//	strcpy(tmp,full_name);
	strcpy(tmp, name);
	strcat(tmp,item);
	strcat(tmp,":_original.._value");
//#ifndef WIN32
//	delete full_name;
//#endif
	if(!size)
	{
		valueVar.setValue('\0');
		dynValueVar.append(valueVar);
		dynValueVar.clear();
	}
	for(i = 0; i <size; i++)
	{
		valueVar.setValue(value[i]);
		dynValueVar.append(valueVar);
	}
	return doSetDpValue(tmp, dynValueVar);
}

int DP::setDPValue(char *name, char *item, char *value)
{
	char tmp[256];
	DpIdentifier dpId;
	TextVar valueVar;
	DpIdentifier dp;
//	char *full_name = 0;

//	DISABLE_AST
//	manId->getId(name, dp);
//	manId->getName(dp, full_name);
//	ENABLE_AST
//	strcpy(tmp,full_name);
	strcpy(tmp, name);
	strcat(tmp,item);
	strcat(tmp,":_original.._value");
//#ifndef WIN32
//	delete full_name;
//#endif
	valueVar.setValue(value);
	return doSetDpValue(tmp, valueVar);
}

int DP::setDPValue(char *name, char *item, char **value, int size)
{
	char tmp[256];
	int i;
	DpIdentifier dpId;
	TextVar valueVar;
	DynVar dynValueVar;
	DpIdentifier dp;
//	char *full_name = 0;

//	DISABLE_AST
//	manId->getId(name, dp);
//	manId->getName(dp, full_name);
//	ENABLE_AST
//	strcpy(tmp,full_name);
	strcpy(tmp, name);
	strcat(tmp,item);
	strcat(tmp,":_original.._value");
//#ifndef WIN32
//	delete full_name;
//#endif
	if(!size)
	{
		valueVar.setValue("");
		dynValueVar.append(valueVar);
		dynValueVar.clear();
	}
	for(i = 0; i <size; i++)
	{
		valueVar.setValue(value[i]);
		dynValueVar.append(valueVar);
	}
	return doSetDpValue(tmp, dynValueVar);
}

int DP::setDPValue(char *name, char *item, bit value)
{
	char tmp[256];
	DpIdentifier dpId;
	BitVar valueVar;
	DpIdentifier dp;
//	char *full_name = 0;

//	DISABLE_AST
//	manId->getId(name, dp);
//	manId->getName(dp, full_name);
//	ENABLE_AST
//	strcpy(tmp,full_name);
	strcpy(tmp, name);
	strcat(tmp,item);
	strcat(tmp,":_original.._value");
//#ifndef WIN32
//	delete full_name;
//#endif
	if(value & 0x1)
		valueVar.setValue(PVSS_TRUE);
	else
		valueVar.setValue(PVSS_FALSE);
	return doSetDpValue(tmp, valueVar);
}

int DP::setDPValue(char *name, char *item, bitset value)
{
	char tmp[256];
	DpIdentifier dpId;
	Bit32Var valueVar;
	DpIdentifier dp;
//	char *full_name = 0;

//	DISABLE_AST
//	manId->getId(name, dp);
//	manId->getName(dp, full_name);
//	ENABLE_AST
//	strcpy(tmp,full_name);
	strcpy(tmp, name);
	strcat(tmp,item);
	strcat(tmp,":_original.._value");
//#ifndef WIN32
//	delete full_name;
//#endif
	valueVar.setValue(value);
	return doSetDpValue(tmp, valueVar);
}

int DP::setDPValue(char *name, char *item, time_t value)
{
	char tmp[256];
	DpIdentifier dpId;
	PVSSTime ptime;
	TimeVar valueVar;
	DpIdentifier dp;
//	char *full_name = 0;

//	DISABLE_AST
//	manId->getId(name, dp);
//	manId->getName(dp, full_name);
//	ENABLE_AST
//	strcpy(tmp,full_name);
	strcpy(tmp, name);
	strcat(tmp,item);
	strcat(tmp,":_original.._value");
//#ifndef WIN32
//	delete full_name;
//#endif
	ptime.setValue(value, 0); 
	valueVar.setValue(ptime);
	return doSetDpValue(tmp, valueVar);
}

int DP::setDPValue(char *name, char *item, int value)
{
	char tmp[256];
	DpIdentifier dpId;
	IntegerVar valueVar;
	DpIdentifier dp;
//	char *full_name = 0;
//	int ret;

//	DISABLE_AST
//	ret = manId->getId(name, dp);
//	if(!ret)
//	{
//		ENABLE_AST
//		return 0;
//	}
//	manId->getName(dp, full_name);
//	ENABLE_AST
//	strcpy(tmp,full_name);
	strcpy(tmp, name);
	strcat(tmp,item);
	strcat(tmp,":_original.._value");
//#ifndef WIN32
//	if(full_name)
//		delete full_name;
//#endif
	valueVar.setValue(value);
	return doSetDpValue(tmp, valueVar);
}

int DP::setDPValue(char *name, char *item, unsigned int value)
{
	char tmp[256];
	DpIdentifier dpId;
	UIntegerVar valueVar;
	DpIdentifier dp;
//	char *full_name = 0;
//	int ret;

//	DISABLE_AST
//	ret = manId->getId(name, dp);
//	if(!ret)
//	{
//		ENABLE_AST
//		return 0;
//	}
//	manId->getName(dp, full_name);
//	ENABLE_AST
//	strcpy(tmp,full_name);
	strcpy(tmp, name);
	strcat(tmp,item);
	strcat(tmp,":_original.._value");
//#ifndef WIN32
//	if(full_name)
//		delete full_name;
//#endif
	valueVar.setValue(value);
	return doSetDpValue(tmp, valueVar);
}

int DP::setDPValue(char *name, char *item, int *value, int size)
{
	char tmp[256];
	int i;
	DpIdentifier dpId;
	IntegerVar valueVar;
	DynVar dynValueVar;
	DpIdentifier dp;
//	char *full_name = 0;

//	DISABLE_AST
//	manId->getId(name, dp);
//	manId->getName(dp, full_name);
//	ENABLE_AST
//	strcpy(tmp,full_name);
	strcpy(tmp, name);
	strcat(tmp,item);
	strcat(tmp,":_original.._value");
//#ifndef WIN32
//	delete full_name;
//#endif
	if(!size)
	{
		valueVar.setValue(0);
		dynValueVar.append(valueVar);
		dynValueVar.clear();
	}
	for(i = 0; i <size; i++)
	{
		valueVar.setValue(value[i]);
		dynValueVar.append(valueVar);
	}
	return doSetDpValue(tmp, dynValueVar);
}

int DP::setDPValue(char *name, char *item, unsigned int *value, int size)
{
	char tmp[256];
	int i;
	DpIdentifier dpId;
	UIntegerVar valueVar;
	DynVar dynValueVar;
	DpIdentifier dp;
//	char *full_name = 0;

//	DISABLE_AST
//	manId->getId(name, dp);
//	manId->getName(dp, full_name);
//	ENABLE_AST
//	strcpy(tmp,full_name);
	strcpy(tmp, name);
	strcat(tmp,item);
	strcat(tmp,":_original.._value");
//#ifndef WIN32
//	delete full_name;
//#endif
	if(!size)
	{
		valueVar.setValue(0);
		dynValueVar.append(valueVar);
		dynValueVar.clear();
	}
	for(i = 0; i <size; i++)
	{
		valueVar.setValue(value[i]);
		dynValueVar.append(valueVar);
	}
	return doSetDpValue(tmp, dynValueVar);
}

int DP::setDPValue(char *name, char *item, bitset *value, int size)
{
	char tmp[256];
	int i;
	DpIdentifier dpId;
	Bit32Var valueVar;
	DynVar dynValueVar;
	DpIdentifier dp;
//	char *full_name = 0;

//	DISABLE_AST
//	manId->getId(name, dp);
//	manId->getName(dp, full_name);
//	ENABLE_AST
//	strcpy(tmp,full_name);
	strcpy(tmp, name);
	strcat(tmp,item);
	strcat(tmp,":_original.._value");
//#ifndef WIN32
//	delete full_name;
//#endif
	if(!size)
	{
		valueVar.setValue(0);
		dynValueVar.append(valueVar);
		dynValueVar.clear();
	}
	for(i = 0; i <size; i++)
	{
		valueVar.setValue(value[i]);
		dynValueVar.append(valueVar);
	}
	return doSetDpValue(tmp, dynValueVar);
}

int DP::setDPValue(char *name, char *item, time_t *value, int size)
{
	char tmp[256];
	int i;
	DpIdentifier dpId;
	PVSSTime ptime;
	TimeVar valueVar;
	DynVar dynValueVar;
	DpIdentifier dp;
//	char *full_name = 0;

//	DISABLE_AST
//	manId->getId(name, dp);
//	manId->getName(dp, full_name);
//	ENABLE_AST
//	strcpy(tmp,full_name);
	strcpy(tmp, name);
	strcat(tmp,item);
	strcat(tmp,":_original.._value");
//#ifndef WIN32
//	delete full_name;
//#endif
	if(!size)
	{
		ptime.setValue(0, 0); 
		valueVar.setValue(ptime);
		dynValueVar.append(valueVar);
		dynValueVar.clear();
	}
	for(i = 0; i <size; i++)
	{
		ptime.setValue(value[i], 0); 
		valueVar.setValue(ptime);
		dynValueVar.append(valueVar);
	}
	return doSetDpValue(tmp, dynValueVar);
}

int DP::setDPValue(char *name, char *item, bit *value, int size)
{
	char tmp[256];
	int i;
	DpIdentifier dpId;
	BitVar valueVar;
	DynVar dynValueVar;
	DpIdentifier dp;
//	char *full_name = 0;

//	DISABLE_AST
//	manId->getId(name, dp);
//	manId->getName(dp, full_name);
//	ENABLE_AST
//	strcpy(tmp,full_name);
	strcpy(tmp, name);
	strcat(tmp,item);
	strcat(tmp,":_original.._value");
//#ifndef WIN32
//	delete full_name;
//#endif
	if(!size)
	{
		valueVar.setValue(0);
		dynValueVar.append(valueVar);
		dynValueVar.clear();
	}
	for(i = 0; i <size; i++)
	{
		valueVar.setValue(value[i]);
		dynValueVar.append(valueVar);
	}
	return doSetDpValue(tmp, dynValueVar);
}

int DP::setDPValue(char *name, char *item, float value)
{
	char tmp[256];
	DpIdentifier dpId;
	FloatVar valueVar;
	DpIdentifier dp;
//	char *full_name = 0;

//	DISABLE_AST
//	manId->getId(name, dp);
//	manId->getName(dp, full_name);
//	ENABLE_AST
//	strcpy(tmp,full_name);
	strcpy(tmp, name);
	strcat(tmp,item);
	strcat(tmp,":_original.._value");
//#ifndef WIN32
//	if(full_name)
//		delete full_name;
//#endif
	valueVar.setValue(value);
	return doSetDpValue(tmp, valueVar);
}

int DP::setDPValue(char *name, char *item, float *value, int size)
{
	char tmp[256];
	int i;
	DpIdentifier dpId;
	FloatVar valueVar;
	DynVar dynValueVar;
	DpIdentifier dp;
//	char *full_name = 0;

//	DISABLE_AST
//	manId->getId(name, dp);
//	manId->getName(dp, full_name);
//	ENABLE_AST
//	strcpy(tmp,full_name);
	strcpy(tmp, name);
	strcat(tmp,item);
	strcat(tmp,":_original.._value");
//#ifndef WIN32
//	delete full_name;
//#endif
	if(!size)
	{
		valueVar.setValue(0);
		dynValueVar.append(valueVar);
		dynValueVar.clear();
	}
	for(i = 0; i <size; i++)
	{
		valueVar.setValue(value[i]);
		dynValueVar.append(valueVar);
	}
	return doSetDpValue(tmp, dynValueVar);
}

int DP::setDPValue(char *name, char *item, double value)
{
	char tmp[256];
	DpIdentifier dpId;
	FloatVar valueVar;
	DpIdentifier dp;
//	char *full_name = 0;

//	DISABLE_AST
//	manId->getId(name, dp);
//	manId->getName(dp, full_name);
//	ENABLE_AST
//	strcpy(tmp,full_name);
	strcpy(tmp, name);
	strcat(tmp,item);
	strcat(tmp,":_original.._value");
//#ifndef WIN32
//	if(full_name)
//		delete full_name;
//#endif
	valueVar.setValue(value);
	return doSetDpValue(tmp, valueVar);
}

int DP::setDPValue(char *name, char *item, double *value, int size)
{
	char tmp[256];
	int i;
	DpIdentifier dpId;
	FloatVar valueVar;
	DynVar dynValueVar;
	DpIdentifier dp;
//	char *full_name = 0;

//	DISABLE_AST
//	manId->getId(name, dp);
//	manId->getName(dp, full_name);
//	ENABLE_AST
//	strcpy(tmp,full_name);
	strcpy(tmp, name);
	strcat(tmp,item);
	strcat(tmp,":_original.._value");
//#ifndef WIN32
//	delete full_name;
//#endif
	if(!size)
	{
		valueVar.setValue(0);
		dynValueVar.append(valueVar);
		dynValueVar.clear();
	}
	for(i = 0; i <size; i++)
	{
		valueVar.setValue(value[i]);
		dynValueVar.append(valueVar);
	}
	return doSetDpValue(tmp, dynValueVar);
}

int DP::setDPTimeValue(char *item)
{
	char tmp[256];
	DpIdentifier dpId;
	TimeVar valueVar;

	strcpy(tmp,dpName);
	strcat(tmp,item);
	strcat(tmp,":_original.._value");
	return doSetDpValue(tmp, valueVar);
}

int DP::setDPTimeValue(char *name, char *item)
{
	char tmp[256];
	DpIdentifier dpId;
	TimeVar valueVar;
	DpIdentifier dp;
//	char *full_name = 0;

//	DISABLE_AST
//	manId->getId(name, dp);
//	manId->getName(dp, full_name);
//	ENABLE_AST
//	strcpy(tmp,full_name);
	strcpy(tmp, name);
	strcat(tmp,item);
	strcat(tmp,":_original.._value");
//#ifndef WIN32
//	if(full_name)
//		delete full_name;
//#endif
	return doSetDpValue(tmp, valueVar);
}



int DP::doSetDpValue(DPElem *elem, Variable &value, ATTR_TYPES attr)
{
	DpIdentifier dpId;
	PVSSboolean ret = 0;
	int retry = 5;
	PVSSTime ptime;
	TimeVar tVar;

	DISABLE_AST
	if(getDPId(elem, dpId, attr))
	{
		if((manId->collectingDPs()) && (stimeSecs == (time_t)0))
		{
			ret = manId->addDPSetItem(dpId, value, elem->getDPElemName());
		}
		else
		{
			while(retry--)
			{
				if(stimeSecs != (time_t)0)
				{
					ptime.setValue(stimeSecs, stimeMillies); 
					tVar.setValue(ptime);
					ret = manId->dpSetTimed(tVar, dpId, value);
				}
				else
				{
					ret = manId->dpSet(dpId, value);
				}
				if(ret == PVSS_TRUE)
					break;
			}
			if(ret != PVSS_TRUE)
			{
				print_date_time_lib();
				cout << "dpSet: " << elem->getDPElemName() << " returned PVSS_FALSE, Exiting..."<<endl;
				manId->doExit = 1;
			}
		}
	}
	else
	{
		if(!strstr(elem->getDPElemName(), ".heart_beat"))
		{
			print_date_time_lib();
			cout << "dpSet: " << elem->getDPElemName() << " Does Not Exist"<<endl;
		}
	}
	ENABLE_AST
	return (int)ret;
}

int DP::setDPValue(DPElem *elem, char value)
{
	CharVar valueVar;

	valueVar.setValue(value);
	return doSetDpValue(elem, valueVar, ATTR_VALUE);
}

int DP::setDPValue(DPElem *elem, char *value, int size)
{
	int i;
	CharVar valueVar;
	DynVar dynValueVar;

	if(!size)
	{
		valueVar.setValue('\0');
		dynValueVar.append(valueVar);
		dynValueVar.clear();
	}
	for(i = 0; i <size; i++)
	{
		valueVar.setValue(value[i]);
		dynValueVar.append(valueVar);
	}
	return doSetDpValue(elem, dynValueVar, ATTR_VALUE);
}

int DP::setDPValue(DPElem *elem, char *value)
{
	DpIdentifier dpId;
	TextVar valueVar;

	valueVar.setValue(value);
	return doSetDpValue(elem, valueVar, ATTR_VALUE);
}

int DP::setDPValue(DPElem *elem, char **value, int size)
{
	int i;
	TextVar valueVar;
	DynVar dynValueVar;

	if(!size)
	{
		valueVar.setValue("");
		dynValueVar.append(valueVar);
		dynValueVar.clear();
	}
	for(i = 0; i <size; i++)
	{
		valueVar.setValue(value[i]);
		dynValueVar.append(valueVar);
	}
	return doSetDpValue(elem, dynValueVar, ATTR_VALUE);
}

int DP::setDPValue(DPElem *elem, bit value)
{
	BitVar valueVar;

	if(value & 0x1)
		valueVar.setValue(PVSS_TRUE);
	else
		valueVar.setValue(PVSS_FALSE);
	return doSetDpValue(elem, valueVar, ATTR_VALUE);
}

int DP::setDPValue(DPElem *elem, bitset value)
{
	Bit32Var valueVar;

	valueVar.setValue(value);
	return doSetDpValue(elem, valueVar, ATTR_VALUE);
}

int DP::setDPValue(DPElem *elem, time_t value)
{
	PVSSTime ptime;
	TimeVar valueVar;

	ptime.setValue(value, 0); 
	valueVar.setValue(ptime);
	return doSetDpValue(elem, valueVar, ATTR_VALUE);
}

int DP::setDPValue(DPElem *elem, int value)
{
	IntegerVar valueVar;

	valueVar.setValue(value);
	return doSetDpValue(elem, valueVar, ATTR_VALUE);
}

int DP::setDPValue(DPElem *elem, unsigned int value)
{
	UIntegerVar valueVar;

	valueVar.setValue(value);
	return doSetDpValue(elem, valueVar, ATTR_VALUE);
}

int DP::setDPValue(DPElem *elem, int *value, int size)
{
	int i;
	IntegerVar valueVar;
	DynVar dynValueVar;

	if(!size)
	{
		valueVar.setValue(0);
		dynValueVar.append(valueVar);
		dynValueVar.clear();
	}
	for(i = 0; i <size; i++)
	{
		valueVar.setValue(value[i]);
		dynValueVar.append(valueVar);
	}
	return doSetDpValue(elem, dynValueVar, ATTR_VALUE);
}

int DP::setDPValue(DPElem *elem, unsigned int *value, int size)
{
	int i;
	UIntegerVar valueVar;
	DynVar dynValueVar;

	if(!size)
	{
		valueVar.setValue(0);
		dynValueVar.append(valueVar);
		dynValueVar.clear();
	}
	for(i = 0; i <size; i++)
	{
		valueVar.setValue(value[i]);
		dynValueVar.append(valueVar);
	}
	return doSetDpValue(elem, dynValueVar, ATTR_VALUE);
}

int DP::setDPValue(DPElem *elem, bitset *value, int size)
{
	int i;
	Bit32Var valueVar;
	DynVar dynValueVar;

	if(!size)
	{
		valueVar.setValue(0);
		dynValueVar.append(valueVar);
		dynValueVar.clear();
	}
	for(i = 0; i <size; i++)
	{
		valueVar.setValue(value[i]);
		dynValueVar.append(valueVar);
	}
	return doSetDpValue(elem, dynValueVar, ATTR_VALUE);
}

int DP::setDPValue(DPElem *elem, time_t *value, int size)
{
	int i;
	PVSSTime ptime;
	TimeVar valueVar;
	DynVar dynValueVar;
	if(!size)
	{
		ptime.setValue(0, 0); 
		valueVar.setValue(ptime);
		dynValueVar.append(valueVar);
		dynValueVar.clear();
	}
	for(i = 0; i <size; i++)
	{
		ptime.setValue(value[i], 0); 
		valueVar.setValue(ptime);
		dynValueVar.append(valueVar);
	}
	return doSetDpValue(elem, dynValueVar, ATTR_VALUE);
}

int DP::setDPValue(DPElem *elem, bit *value, int size)
{
	int i;
	BitVar valueVar;
	DynVar dynValueVar;

	if(!size)
	{
		valueVar.setValue(0);
		dynValueVar.append(valueVar);
		dynValueVar.clear();
	}
	for(i = 0; i <size; i++)
	{
		valueVar.setValue(value[i]);
		dynValueVar.append(valueVar);
	}
	return doSetDpValue(elem, dynValueVar, ATTR_VALUE);
}

int DP::setDPValue(DPElem *elem, float value)
{
	FloatVar valueVar;

	valueVar.setValue(value);
	return doSetDpValue(elem, valueVar, ATTR_VALUE);
}

int DP::setDPValue(DPElem *elem, float *value, int size)
{
	int i;
	FloatVar valueVar;
	DynVar dynValueVar;

	if(!size)
	{
		valueVar.setValue(0);
		dynValueVar.append(valueVar);
		dynValueVar.clear();
	}
	for(i = 0; i <size; i++)
	{
		valueVar.setValue(value[i]);
		dynValueVar.append(valueVar);
	}
	return doSetDpValue(elem, dynValueVar, ATTR_VALUE);
}

int DP::setDPValue(DPElem *elem, double value)
{
	FloatVar valueVar;

	valueVar.setValue(value);
	return doSetDpValue(elem, valueVar, ATTR_VALUE);
}

int DP::setDPValue(DPElem *elem, double *value, int size)
{
	int i;
	FloatVar valueVar;
	DynVar dynValueVar;

	if(!size)
	{
		valueVar.setValue(0);
		dynValueVar.append(valueVar);
		dynValueVar.clear();
	}
	for(i = 0; i <size; i++)
	{
		valueVar.setValue(value[i]);
		dynValueVar.append(valueVar);
	}
	return doSetDpValue(elem, dynValueVar, ATTR_VALUE);
}





int DP::setDPAttr(char *item, char *attr, char *value)
{
	char tmp[256];
	DpIdentifier dpId;
	TextVar valueVar;

	strcpy(tmp,dpName);
	strcat(tmp,item);
	strcat(tmp,attr);
	valueVar.setValue(value);
	return doSetDpValue(tmp, valueVar);
}

int DP::setDPAttr(char *item, char *attr, bit value)
{
	char tmp[256];
	DpIdentifier dpId;
	BitVar valueVar;

	strcpy(tmp,dpName);
	strcat(tmp,item);
	strcat(tmp,attr);
	if(value & 0x1)
		valueVar.setValue(PVSS_TRUE);
	else
		valueVar.setValue(PVSS_FALSE);
	return doSetDpValue(tmp, valueVar);
}

int DP::setDPAttr(char *item, char *attr, int value)
{
	char tmp[256];
	DpIdentifier dpId;
	IntegerVar valueVar;

	strcpy(tmp,dpName);
	strcat(tmp,item);
	strcat(tmp,attr);
	valueVar.setValue(value);
	return doSetDpValue(tmp, valueVar);
}

int DP::setDPAttr(char *item, char *attr, int *value, int size)
{
	char tmp[256];
	int i;
	DpIdentifier dpId;
	IntegerVar valueVar;
	DynVar dynValueVar;

	strcpy(tmp,dpName);
	strcat(tmp,item);
	strcat(tmp,attr);
	for(i = 0; i <size; i++)
	{
		valueVar.setValue(value[i]);
		dynValueVar.append(valueVar);
	}
	return doSetDpValue(tmp, dynValueVar);
}

int DP::setDPAttr(char *item, char *attr, float value)
{
	char tmp[256];
	DpIdentifier dpId;
	FloatVar valueVar;

	strcpy(tmp,dpName);
	strcat(tmp,item);
	strcat(tmp,attr);
	valueVar.setValue(value);
	return doSetDpValue(tmp, valueVar);
}

int DP::setDPAttr(char *item, char *attr, float *value, int size)
{
	char tmp[256];
	int i;
	DpIdentifier dpId;
	FloatVar valueVar;
	DynVar dynValueVar;

	strcpy(tmp,dpName);
	strcat(tmp,item);
	strcat(tmp,attr);
	for(i = 0; i <size; i++)
	{
		valueVar.setValue(value[i]);
		dynValueVar.append(valueVar);
	}
	return doSetDpValue(tmp, dynValueVar);
}

int DP::setDPAttr(char *name, char *item, char *attr, char *value)
{
	char tmp[256];
	DpIdentifier dpId;
	TextVar valueVar;
	DpIdentifier dp;
//	char *full_name = 0;

//	DISABLE_AST
//	manId->getId(name, dp);
//	manId->getName(dp, full_name);
//	ENABLE_AST
//	strcpy(tmp,full_name);
	strcpy(tmp, name);
	strcat(tmp,item);
	strcat(tmp,attr);
//#ifndef WIN32
//	delete full_name;
//#endif
	valueVar.setValue(value);
	return doSetDpValue(tmp, valueVar);
}

int DP::setDPAttr(char *name, char *item, char *attr, bit value)
{
	char tmp[256];
	DpIdentifier dpId;
	BitVar valueVar;
	DpIdentifier dp;
//	char *full_name = 0;

//	DISABLE_AST
//	manId->getId(name, dp);
//	manId->getName(dp, full_name);
//	ENABLE_AST
//	strcpy(tmp,full_name);
	strcpy(tmp, name);
	strcat(tmp,item);
	strcat(tmp,attr);
//#ifndef WIN32
//	delete full_name;
//#endif
	if(value)
		valueVar.setValue(PVSS_TRUE);
	else
		valueVar.setValue(PVSS_FALSE);
	return doSetDpValue(tmp, valueVar);
}

int DP::setDPAttr(char *name, char *item, char *attr, int value)
{
	char tmp[256];
	DpIdentifier dpId;
	IntegerVar valueVar;
	DpIdentifier dp;
//	char *full_name = 0;

//	DISABLE_AST
//	manId->getId(name, dp);
//	manId->getName(dp, full_name);
//	ENABLE_AST
//	strcpy(tmp,full_name);
	strcpy(tmp, name);
	strcat(tmp,item);
	strcat(tmp,attr);
//#ifndef WIN32
//	delete full_name;
//#endif
	valueVar.setValue(value);
	return doSetDpValue(tmp, valueVar);
}

int DP::setDPAttr(char *name, char *item, char *attr, int *value, int size)
{
	char tmp[256];
	int i;
	DpIdentifier dpId;
	IntegerVar valueVar;
	DynVar dynValueVar;
	DpIdentifier dp;
//	char *full_name = 0;

//	DISABLE_AST
//	manId->getId(name, dp);
//	manId->getName(dp, full_name);
//	ENABLE_AST
//	strcpy(tmp,full_name);
	strcpy(tmp, name);
	strcat(tmp,item);
	strcat(tmp,attr);
//#ifndef WIN32
//	delete full_name;
//#endif
	for(i = 0; i <size; i++)
	{
		valueVar.setValue(value[i]);
		dynValueVar.append(valueVar);
	}
	return doSetDpValue(tmp, dynValueVar);
}

int DP::setDPAttr(char *name, char *item, char *attr, float value)
{
	char tmp[256];
	DpIdentifier dpId;
	FloatVar valueVar;
	DpIdentifier dp;
//	char *full_name = 0;

//	DISABLE_AST
//	manId->getId(name, dp);
//	manId->getName(dp, full_name);
//	ENABLE_AST
//	strcpy(tmp,full_name);
	strcpy(tmp, name);
	strcat(tmp,item);
	strcat(tmp,attr);
//#ifndef WIN32
//	delete full_name;
//#endif
	valueVar.setValue(value);
	return doSetDpValue(tmp, valueVar);
}

int DP::setDPAttr(char *name, char *item, char *attr, float *value, int size)
{
	char tmp[256];
	int i;
	DpIdentifier dpId;
	FloatVar valueVar;
	DynVar dynValueVar;
	DpIdentifier dp;
//	char *full_name = 0;

//	DISABLE_AST
//	manId->getId(name, dp);
//	manId->getName(dp, full_name);
//	ENABLE_AST
//	strcpy(tmp,full_name);
	strcpy(tmp, name);
	strcat(tmp,item);
	strcat(tmp,attr);
//#ifndef WIN32
//	delete full_name;
//#endif
	for(i = 0; i <size; i++)
	{
		valueVar.setValue(value[i]);
		dynValueVar.append(valueVar);
	}
	return doSetDpValue(tmp, dynValueVar);
}

int DP::setDPAttr( DPElem *elem, ATTR_TYPES attr, bit value)
{
	BitVar valueVar;

	if(value)
		valueVar.setValue(PVSS_TRUE);
	else
		valueVar.setValue(PVSS_FALSE);
	return doSetDpValue(elem, valueVar, attr);
}

/*
int DP::addDPAttr(DpIdValueList &list,
				 char *name, char *item, char *attr, bit value)
{
	char tmp[256];
	DpIdentifier dpId;
	BitVar valueVar;
	DpIdentifier dp;
	char *full_name = 0;
	int ret = 0;

//	DISABLE_AST
//	manId->getId(name, dp);
//	manId->getName(dp, full_name);
//	ENABLE_AST
//	strcpy(tmp,full_name);
	strcpy(tmp,name);
	strcat(tmp,item);
	strcat(tmp,attr);
//#ifndef WIN32
//	delete full_name;
//#endif
        {
	DISABLE_AST
	if(manId->getId(tmp, dpId))
	{
		if(value)
			valueVar.setValue(PVSS_TRUE);
		else
			valueVar.setValue(PVSS_FALSE);
		list.appendItem(dpId, valueVar);
		ret = 1;
	}
	ENABLE_AST
	}
	return ret;
}
*/

int DP::addDPAttr(DpIdValueList &list,
				 char *name, char *item, char *attr, bit value)
{
	char tmp[256];
	DpIdentifier dpId;
	BitVar valueVar;
	DpIdentifier dp;
//	char *full_name = 0;
	int ret = 0;

//	DISABLE_AST
//	manId->getId(name, dp);
//	manId->getName(dp, full_name);
//	ENABLE_AST
//	strcpy(tmp,full_name);
	strcpy(tmp,name);
	strcat(tmp,item);
	strcat(tmp,attr);
//#ifndef WIN32
//	delete full_name;
//#endif
        {
	DISABLE_AST
	if(getDPId(tmp, dpId, "addDPAttr_bit"))
	{
		if(value)
			valueVar.setValue(PVSS_TRUE);
		else
			valueVar.setValue(PVSS_FALSE);
//		list.appendItem(dpId, valueVar);
		if(stimeSecs == (time_t)0)
		{
			manId->addDPSetItem(dpId, valueVar, tmp);
		}
		else
		{
			doSetDpValue(tmp, valueVar);
		}
		ret = 1;
	}
	ENABLE_AST
	}
	return ret;
}

int DP::addDPAttr(DpIdValueList &list,
				 char *name, char *item, char *attr, time_t value)
{
	char tmp[256];
	DpIdentifier dpId;
	PVSSTime ptime;
	TimeVar valueVar;
	DpIdentifier dp;
//	char *full_name = 0;
	int ret = 0;

//	DISABLE_AST
//	manId->getId(name, dp);
//	manId->getName(dp, full_name);
//	ENABLE_AST
//	strcpy(tmp,full_name);
	strcpy(tmp,name);
	strcat(tmp,item);
	strcat(tmp,attr);
//#ifndef WIN32
//	delete full_name;
//#endif
        {
	DISABLE_AST
	if(getDPId(tmp, dpId, "addDPAttr_time_t"))
	{
		ptime.setValue(value, 0); 
		valueVar.setValue(ptime);
//		list.appendItem(dpId, valueVar);
		manId->addDPSetItem(dpId, valueVar, tmp);		
		ret = 1;
	}
	ENABLE_AST
	}
	return ret;
}

int DP::sendDPAttrs(DpIdValueList &list)
{
	PVSSboolean ret = 0;
	DISABLE_AST
//	print_date_time_lib();
//	cout << "Setting Attributes: " << list.getNumberOfItems() <<endl;
	ret = manId->dpSet(list);
//	print_date_time_lib();
//	cout << "Done Setting Attributes " <<endl;
	if(ret != PVSS_TRUE)
	{
		print_date_time_lib();
		cout << "dpSetMultipleAttributes: " << "returned PVSS_FALSE, Exiting..."<<endl;
	cout << "Setting Attributes: " << list.getNumberOfItems() <<endl;
		manId->doExit = 1;
	}
	ENABLE_AST
	return (int)ret;
}

char *DPItem::getDPItemString() 
{
	return((char *) ((TextVar *)value)->getValue());
}

char *DPItem::getDPItemLangString()
{
	lt = ((LangTextVar *)value)->getValue();
	return((char *) (lt.getText()));
}
	
int DPItem::getDPItemInt()
{
	return((int) ((IntegerVar *)value)->getValue());
}
	
unsigned int DPItem::getDPItemUInt()
{
	return((unsigned int) ((UIntegerVar *)value)->getValue());
}
	
float DPItem::getDPItemFloat()
{
	return((float) ((FloatVar *)value)->getValue());
}
	
double DPItem::getDPItemDouble()
{
	return((double) ((FloatVar *)value)->getValue());
}
	
char DPItem::getDPItemChar()
{
	return((char) ((CharVar *)value)->getValue());
}
	
bit DPItem::getDPItemBit()
{
	return((bit) ((BitVar *)value)->getValue());
}
	
bitset DPItem::getDPItemBitset()
{
	return((bitset) ((Bit32Var *)value)->getValue());
}
	
time_t DPItem::getDPItemTime()
{
	BC_CTime secs; short milli;
	((TimeVar *)value)->getValue(secs, milli);
	return((time_t) secs.ElapsedSeconds());
}

int DPItem::getDPItemValue(char * &str)
{
	DynVar *arrVar;
	int n, index = 0;
	TextVar *valueVar;
	char *ptr;
	char **ptrs;
	int i, size = 0;

	arrVar = (DynVar *)value;
	n = arrVar->getArrayLength();
	if(n)
	{
		ptrs = new char *[n];
		valueVar = (TextVar *)arrVar->getFirstVar();
		ptr = (char *) valueVar->getValue();
		size += strlen(ptr)+1;
		ptrs[index++] = ptr; 
		while( (valueVar = (TextVar *)arrVar->getNextVar()) != 0)
		{
			ptr = (char *) valueVar->getValue();
			size += strlen(ptr)+1;
			ptrs[index++] = ptr; 
		}
		str = new char[size];
		ptr = str;
		for(i = 0; i < index; i++)
		{
			strcpy(ptr, ptrs[i]); 
			ptr += strlen(ptr)+1;
		}
		delete[] ptrs;
	}
	else
	{
		str = new char[1];
		str[0] = '\0';
	}
	return n;
}

int DPItem::getDPItemValue(int * &arr)
{
	DynVar *arrVar;
	int n, index = 0;
	IntegerVar *valueVar;

	arrVar = (DynVar *)value;
	n = arrVar->getArrayLength();
	if(n)
	{
		arr = new int[n];
		valueVar = (IntegerVar *)arrVar->getFirstVar();
		arr[index++] = (int) valueVar->getValue(); 
		while( (valueVar = (IntegerVar *)arrVar->getNextVar()) != 0)
		{
			arr[index++] = (int) valueVar->getValue(); 
		}
	}
	else
	{
		arr = new int[1];
	}
	return n;
}

int DPItem::getDPItemValue(unsigned int * &arr)
{
	DynVar *arrVar;
	int n, index = 0;
	UIntegerVar *valueVar;

	arrVar = (DynVar *)value;
	n = arrVar->getArrayLength();
	if(n)
	{
		arr = new unsigned int[n];
		valueVar = (UIntegerVar *)arrVar->getFirstVar();
		arr[index++] = (int) valueVar->getValue(); 
		while( (valueVar = (UIntegerVar *)arrVar->getNextVar()) != 0)
		{
			arr[index++] = (unsigned int) valueVar->getValue(); 
		}
	}
	else
	{
		arr = new unsigned int[1];
	}
	return n;
}

int DPItem::getDPItemValue(bitset * &arr)
{
	DynVar *arrVar;
	int n, index = 0;
	Bit32Var *valueVar;

	arrVar = (DynVar *)value;
	n = arrVar->getArrayLength();
	if(n)
	{
		arr = new bitset[n];
		valueVar = (Bit32Var *)arrVar->getFirstVar();
		arr[index++] = (bitset) valueVar->getValue(); 
		while( (valueVar = (Bit32Var *)arrVar->getNextVar()) != 0)
		{
			arr[index++] = (bitset) valueVar->getValue(); 
		}
	}
	else
	{
		arr = new bitset[1];
	}
	return n;
}

int DPItem::getDPItemValue(time_t * &arr)
{
	DynVar *arrVar;
	int n, index = 0;
	TimeVar *valueVar;
//	BC_CTime secs; short milli;
	PVSSTime ptime;
//	time_t secs;

	arrVar = (DynVar *)value;
	n = arrVar->getArrayLength();
	if(n)
	{
		arr = new time_t[n];
/*
		valueVar = (TimeVar *)arrVar->getFirstVar();
		((TimeVar *)valueVar)->getValue(secs, milli);
		arr[index++] = (time_t) secs.ElapsedSeconds(); 
		while( (valueVar = (TimeVar *)arrVar->getNextVar()) != 0)
		{
			((TimeVar *)valueVar)->getValue(secs, milli);
			arr[index++] = (time_t) secs.ElapsedSeconds(); 
		}
*/
		valueVar = (TimeVar *)arrVar->getFirstVar();
		ptime = ((TimeVar *)valueVar)->getValue();
		arr[index++] = (time_t) ptime.getSeconds(); 
		while( (valueVar = (TimeVar *)arrVar->getNextVar()) != 0)
		{
			ptime = ((TimeVar *)valueVar)->getValue();
			arr[index++] = (time_t) ptime.getSeconds(); 
		}
	}
	else
	{
		arr = new time_t[1];
	}
	return n;
}

int DPItem::getDPItemValue(bit * &arr)
{
	DynVar *arrVar;
	int n, index = 0;
	BitVar *valueVar;

	arrVar = (DynVar *)value;
	n = arrVar->getArrayLength();
	if(n)
	{
		arr = new bit[n];
		valueVar = (BitVar *)arrVar->getFirstVar();
		arr[index++] = (bit) valueVar->getValue(); 
		while( (valueVar = (BitVar *)arrVar->getNextVar()) != 0)
		{
			arr[index++] = (bit) valueVar->getValue(); 
		}
	}
	else
	{
		arr = new bit[1];
	}
	return n;
}

int DPItem::getDPItemValue(float * &arr)
{
	DynVar *arrVar;
	int n, index = 0;
	FloatVar *valueVar;

	arrVar = (DynVar *)value;
	n = arrVar->getArrayLength();
	if(n)
	{
		arr = new float[n];
		valueVar = (FloatVar *)arrVar->getFirstVar();
		arr[index++] = (float) valueVar->getValue(); 
		while( (valueVar = (FloatVar *)arrVar->getNextVar()) != 0)
		{
			arr[index++] = (float) valueVar->getValue(); 
		}
	}
	else
	{
		arr = new float[1];
	}
	return n;
}

int DPItem::getDPItemValue(double * &arr)
{
	DynVar *arrVar;
	int n, index = 0;
	FloatVar *valueVar;

	arrVar = (DynVar *)value;
	n = arrVar->getArrayLength();
	if(n)
	{
		arr = new double[n];
		valueVar = (FloatVar *)arrVar->getFirstVar();
		arr[index++] = (double) valueVar->getValue(); 
		while( (valueVar = (FloatVar *)arrVar->getNextVar()) != 0)
		{
			arr[index++] = (double) valueVar->getValue(); 
		}
	}
	else
	{
		arr = new double[1];
	}
	return n;
}

int DPItem::getDPItemCharValues(char * &arr)
{
	DynVar *arrVar;
	int n, index = 0;
	CharVar *valueVar;

	arrVar = (DynVar *)value;
	n = arrVar->getArrayLength();
	if(n)
	{
		arr = new char[n];
		valueVar = (CharVar *)arrVar->getFirstVar();
		arr[index++] = (char) valueVar->getValue(); 
		while( (valueVar = (CharVar *)arrVar->getNextVar()) != 0)
		{
			arr[index++] = (char) valueVar->getValue(); 
		}
	}
	else
	{
		arr = new char[1];
	}
	return n;
}
/*
DPItem *DP::getDPItem(char *item)
{
	DPItem *dpItem;
	char *name, *ptr;

	DISABLE_AST
	if((ptr = strchr(item,':')) != 0)
		*ptr = '\0';
	dpItem = (DPItem *)itemList.getHead();
	while(dpItem)
	{
		name = dpItem->getDPItemName();
		if(!strcmp(name,item))
		{
			ENABLE_AST
			return(dpItem);
		}
		dpItem = (DPItem *)itemList.getNext();
	}
	ENABLE_AST
	return((DPItem *)0);
}

DPItem *DP::getDPItemDpName(char *item)
{
	DPItem *dpItem;
	char *name;

	DISABLE_AST
	dpItem = (DPItem *)itemList.getHead();
	while(dpItem)
	{
		name = dpItem->getDPDpName();
		if(!strcmp(name,item))
		{
			ENABLE_AST
			return(dpItem);
		}
		dpItem = (DPItem *)itemList.getNext();
	}
	ENABLE_AST
	return((DPItem *)0);
}

DPItem *ApiManager::getDPItem(char *dpName)
{
	DPItem *dpItem;
	char *ptr;
	char str[1024], str1[1024];
	DISABLE_AST

	strcpy(str,dpName);
	if((ptr = strstr(str,":online..value")) != 0)
		*ptr = '\0';
//	if((ptr = strstr(str,":online..value")) != 0)
//		strcpy(ptr,":_online.._value");
	strcpy(str1, str);
	do
	{
		dpItem = findDPItemName(str,dpName+strlen(str));
		if(dpItem)
		{
			ENABLE_AST
			return(dpItem);
		}
		if((ptr = strrchr(str,'[')) != 0)
			*ptr = '\0';
		else if((ptr = strrchr(str,'.')) != 0)
			*ptr = '\0';
	}while(ptr);
	dpItem = findDPItemName("",str1);
	if(dpItem)
	{
		ENABLE_AST
		return(dpItem);
	}
	ENABLE_AST
	return((DPItem *)0);
}

DPItem *ApiManager::findDPItemName(char *prefix, char *suffix)
{
	DP *dp;
	DPItem *dpItem = 0;

	if(!strcmp(prefix,""))
	{
		dpItem = DPTable.findItem(suffix);
		return(dpItem);
	}
	else
	{
		dp = DPTable.find(prefix);
		if(dp)
		{
			dpItem = dp->getDPItem(suffix);
			return(dpItem);
		}
	}
	return((DPItem *)0);
}
*/

DPItem::~DPItem()
{
	if(connectedDp)
	{
		getDp()->getManId()->remDPItem(this, connectedDp);
//		getDp()->disconnectDPValue(connectedDp);
		delete connectedDp;
	}
	delete[] itemName;
	if(dpName)
		delete[] dpName;
}
/*
void DPHashTable::add(char *name, DP *ptr)
{
	int index;

	index = hashFunction(name,MAX_HASH_ENTRIES);
	dpHashTable[index].add(ptr);
}

void DPHashTable::remove(char *name, DP *ptr)
{
	int index;

	index = hashFunction(name,MAX_HASH_ENTRIES);
	dpHashTable[index].remove(ptr);
}

DP *DPHashTable::find(char *name)
{
	int index;
	DP *dp;
	char *aux;

	index = hashFunction(name,MAX_HASH_ENTRIES);
	dp = (DP *)dpHashTable[index].getHead();
	while(dp)
	{
		aux = dp->getDPName();
		if(!strcmp(aux,name))
		{
			return(dp);
		}
		dp = (DP *)dpHashTable[index].getNext();
	}
	return((DP *)0);
}

DPItem *DPHashTable::findItem(char *name)
{
	int index;
	DP *dp;
	DPItem *dpItem;

	index = hashFunction("",MAX_HASH_ENTRIES);
	dp = (DP *)dpHashTable[index].getHead();
	while(dp)
	{
		dpItem = dp->getDPItemDpName(name);
		if(dpItem)
		{
			return(dpItem);
		}
		dp = (DP *)dpHashTable[index].getNext();
	}
	return((DPItem *)0);
}

int DPHashTable::hashFunction(char *name, int max)
{
   unsigned int b    = 378551;
   unsigned int a    = 63689;
   unsigned int hash = 0;
   int i    = 0;
   int len;

   len = strlen(name);

   for(i = 0; i < len; name++, i++)
   {
      hash = hash*a+(*name);
      a = a*b;
   }

   return (hash % max);
}
*/
DPItem::DPItem(char *name, DP *dp)
{
	itemName = new char[strlen(name)+1];
	strcpy(itemName,name);
	dpName = 0;
	read = 0;
	theDp = dp;
	connectedDp = 0;
}

DPItem::DPItem(char *dpname, char *name, DP *dp)
{
	itemName = new char[strlen(name)+1];
	strcpy(itemName,name);
	dpName = new char[strlen(dpname)+1];
	strcpy(dpName,dpname);
	read = 0;
	theDp = dp;
	connectedDp = 0;
}

HASHItem::HASHItem()
{
	theKey = 0;
}

HASHItem::~HASHItem()
{
	if(theKey)
		delete[] theKey;
}

void HASHItem::setKey(char *key)
{
	if(theKey)
		delete[] theKey;
	theKey = new char[strlen(key)+1];
	strcpy(theKey,key);
}

char *HASHItem::getKey()
{
	return(theKey);
}

void HASHTable::add(char *key, HASHItem *ptr)
{
	int index;

	ptr->setKey(key);
	index = hashFunction(key, MAX_HASH_ENTRIES);
	hashTable[index].add((HASHItem *)ptr);
	hashItems[index]++;
	nItems++;
//cout << "add " << index << " "  << nItems << endl;
}

void HASHTable::remove(char *key, HASHItem *ptr)
{
	int index;

	index = hashFunction(key, MAX_HASH_ENTRIES);
	hashTable[index].remove((HASHItem *)ptr);
	hashItems[index]--;
	nItems--;
//cout << "Remove " << index << " " << nItems << endl;
}

void HASHTable::removeAtIndex(int index, HASHItem *ptr)
{
	hashTable[index].remove((HASHItem *)ptr);
	hashItems[index]--;
	nItems--;
//cout << "RemoveAtIndex " << index << " " << nItems <<endl;
}

int HASHTable::getNItems()
{
	return nItems;
}

HASHItem *HASHTable::find(char *key)
{
	int index;
	HASHItem *ptr;
	char *aux;

	index = hashFunction(key,MAX_HASH_ENTRIES);
	ptr = (HASHItem *)hashTable[index].getHead();
	while(ptr)
	{
		aux = ptr->getKey();
		if(!strcmp(aux, key))
		{
			return((HASHItem *)ptr);
		}
		ptr = (HASHItem *)hashTable[index].getNext();
	}
	return((HASHItem *)0);
}

int HASHTable::findN(char *key)
{
	int index;
	HASHItem *ptr;
	char *aux;
	int n = 0;

	index = hashFunction(key,MAX_HASH_ENTRIES);
	ptr = (HASHItem *)hashTable[index].getHead();
	while(ptr)
	{
		aux = ptr->getKey();
		if(!strcmp(aux, key))
		{
			n++;
		}
		ptr = (HASHItem *)hashTable[index].getNext();
	}
	return(n);
}


int HASHTable::getCurrentIndex()
{
	return currIndex;
}

HASHItem *HASHTable::getHead()
{

	if(!nItems) 
		return (HASHItem *)0;
	currIndex = 0;
	currItem = (HASHItem *)0;
	/*
	while(!currItem)
	{
		currItem = (HASHItem *)hashTable[currIndex].getHead();
cout << "hash Index "<< currIndex << " = " << hashItems[currIndex] << endl;
		if(!currItem)
		{
			currIndex++;
			if(currIndex == MAX_HASH_ENTRIES)
			{
				return((HASHItem *) 0);
			}
		}
	}
	*/
	currItem = getNextHead();
	return(currItem);
}

HASHItem *HASHTable::getNextHead()
{


	if(currIndex == MAX_HASH_ENTRIES)
	{
		return((HASHItem *) 0);
	}
	while(!hashItems[currIndex])
	{
		currIndex++;
		if(currIndex == MAX_HASH_ENTRIES)
		{
			return((HASHItem *) 0);
		}
	}
	currItem = (HASHItem *)hashTable[currIndex].getHead();
	if(currItem == 0)
		cout << "found 0 at index" << currIndex << endl;
	return(currItem);
}


HASHItem *HASHTable::getNext()
{
	if(currItem)
	{
		currItem = (HASHItem *)hashTable[currIndex].getNext();
	}
	if(!currItem)
	{
/*
		do
		{
			currIndex++;
			if(currIndex == MAX_HASH_ENTRIES)
			{
				return((HASHItem *) 0);
			}
			currItem = (HASHItem *)hashTable[currIndex].getHead();
cout << "hash Index "<< currIndex << " = " << hashItems[currIndex] << endl;
		} while(!currItem);
*/
		currIndex++;
		currItem = getNextHead();
	}
//cout << "getNext" << currIndex << " " << currItem << endl;
	return(currItem);
}

/*
void HASHTable::removeAll()
{
	int i;
	HASHItem *ptr;

	for(i = 0; i < MAX_HASH_ENTRIES; i++)
	{
		while(hashTable[i].getHead())
		{
			ptr = (HASHItem *)hashTable[i].removeHead();
			delete(ptr);
		}
	}
}
*/

int HASHTable::hashFunction(char *name, int max)
{
   unsigned int b    = 378551;
   unsigned int a    = 63689;
   unsigned int hash = 0;
   int i    = 0;
   int len;

   len = strlen(name);

   for(i = 0; i < len; name++, i++)
   {
      hash = hash*a+(*name);
      a = a*b;
   }

   return (hash % max);
}

DPSetHASHItem::DPSetHASHItem(DpIdentifier &dpId, Variable &value, int sendFlag)
{
//	itsValue = new Variable(value);
//	itsDpId = new DpIdentifier(dpId);
	itsIdValue = new DpVCItem(dpId, value);
	itsSendFlag = sendFlag;
}

DPSetHASHItem::~DPSetHASHItem()
{
//	delete itsValue;
//	delete itsDpId;

//	VariablePtr var;

//	var = itsIdValue->getValuePtr();
//	delete var;
	delete itsIdValue;
}

VariablePtr DPSetHASHItem::getValuePtr()
{
//	return itsValue;
	return itsIdValue->getValuePtr();
}

DpIdentifier &DPSetHASHItem::getDpId()
{
//	return *itsDpId;

	return (DpIdentifier &)itsIdValue->getDpIdentifier();
}

int DPSetHASHItem::getSendFlag()
{
	return itsSendFlag;
}

void DPSetHASHItem::setSendFlag(int sendFlag)
{
	itsSendFlag = sendFlag;
}
/*
void ApiManager::makeDPSetList()
{
	DPSetHASHItem *item;

	item = (DPSetHASHItem *)DPsToSend.getHead();
	while(item)
	{
		if(item->getSendFlag())
		{
			DPSetList->appendItem(item->getDpId(), *(item->getValuePtr()));
		}
		item = (DPSetHASHItem *)DPsToSend.getNext();
	}
}

void ApiManager::freeDPSetList()
{
	DPSetHASHItem *item, *nextItem;
	int currIndex;

	item = (DPSetHASHItem *)DPsToSend.getHead();
	while(item)
	{
		if(item->getSendFlag())
		{
			currIndex = DPsToSend.getCurrentIndex();
			nextItem = (DPSetHASHItem *)DPsToSend.getNext();
			DPsToSend.removeAtIndex(currIndex, item);
			delete item;
		}
		else
		{
			item->setSendFlag(1);
			nextItem = (DPSetHASHItem *)DPsToSend.getNext();
		}
		item = nextItem;
	}
}
*/

void ApiManager::makeDPSetList()
{
	DPSetHASHItem *item;

	item = (DPSetHASHItem *)DPsToSend.getHead();
	while(item)
	{
		if(!(item->getSendFlag()))
		{
//cout << "sending item "<<item->getKey() << endl;
			DPSetList->appendItem(item->getDpId(), *(item->getValuePtr()));
		}
		item = (DPSetHASHItem *)DPsToSend.getNext();
	}
}

void ApiManager::freeDPSetList()
{
	DPSetHASHItem *item, *nextItem;
	int currIndex, sendFlag;

	item = (DPSetHASHItem *)DPsToSend.getHead();
	while(item)
	{
		if(!(sendFlag = item->getSendFlag()))
		{
			currIndex = DPsToSend.getCurrentIndex();
			nextItem = (DPSetHASHItem *)DPsToSend.getNext();
			DPsToSend.removeAtIndex(currIndex, item);
//print_date_time_lib();
//char tstr[128];
//sprintf(tstr,"%08X",item);
//CountDPSetItems--;
//cout << "----- freeDPSetList" << " delete DPSetHASHItem " << tstr << " " << CountDPSetItems << endl;
			delete item;
		}
		else
		{
			sendFlag--;
			item->setSendFlag(sendFlag);
			nextItem = (DPSetHASHItem *)DPsToSend.getNext();
		}
		item = nextItem;
	}
}

void ApiManager::addDPItem(DPItem *item, char *name)
{
	DPsToGet.add(name, item);
}

DPItem *ApiManager::findDPItem(char *name)
{
	char str[1024], *ptr;

	strcpy(str,name);
	if((ptr = strstr(str,":online..value")) != 0)
		strcpy(ptr,":_online.._value");
	return (DPItem *)DPsToGet.find(str);
}

void ApiManager::remDPItem(DPItem *item, char *name)
{
	char str[1024], *ptr;

	strcpy(str,name);
	if((ptr = strstr(str,":online..value")) != 0)
		strcpy(ptr,":_online.._value");
	DPsToGet.remove(str, item); 
}
/*
DPItem *ApiManager::findDPItemById(DpIdentifier &dpId)
{
	DPItem *item = 0;

	DISABLE_AST
	item = (DPItem *)DPsToGet.getHead();
	while(item)
	{
		if(item->getDpItemId() == dpId)
		{
			break;
		}
		item = (DPItem *)DPsToGet.getNext();
	}
	ENABLE_AST
	return item;
}
*/
