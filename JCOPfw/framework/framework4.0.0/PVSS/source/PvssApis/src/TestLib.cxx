/*
#include "ApiLib.hxx"

class TestManager : public ApiManager
{
public:
	TestManager() : ApiManager() { manStart();}

protected:
	void manInitialize();
	void manExecute();
	void manExit() {};
};

class TestDP : public DP
{
public:
	TestDP( char *name, TestManager *man) :
		DP(name, man) {}
protected:
	void gotDPValue(DPItem *dpItem);
};

TestDP *ptr;
int index = 0;

void TestManager::manExecute()
{
	ptr = new TestDP("alpc66",this);
	delete ptr;
	cout << "index " << index++ << endl;
}

void TestManager::manInitialize()
{
	TestDP *dpp;
	int i;
	float float_arr[10];
*/
  /*
	dpp = new TestDP("test",this);

	dpp->setDPValue(".intValue", 123);
	dpp->getDPValue(".intValue");
	for(i = 0; i < 10; i++)
		float_arr[i] = (float)i;
	dpp->setDPValue(".floatArrValue", float_arr, 10);
	dpp->getDPValue(".floatArrValue");
	dpp->connectDPValue("test",".strValue");
*/
/*
}


void TestDP::gotDPValue(DPItem *dpItem)
{
	int n, i;
	float *arr;
*/
  /*
	if(dpItem->cmpDPItemName(".intValue"))
	{
		cout << "received - " << getDPName() 
			 << dpItem->getDPItemName()
			 << " : " << dpItem->getDPItemInt() << "\n";
	}
	else if(dpItem->cmpDPItemName(".floatArrValue"))
	{
		cout << "received - " << getDPName() 
		<< dpItem->getDPItemName() << " :\n";
		n = dpItem->getDPItemValue(arr);
		for( i = 0; i < n; i++)
		{
			cout << arr[i] << "\n";
		}
//		delete arr;
	}
	else if(dpItem->cmpDPItemName(".strValue"))
	{
	cout << dpItem->getDPDpName() << endl;
		cout << "received - " << getDPName() 
			 << dpItem->getDPItemName()
			 << " : " << dpItem->getDPItemString() << "\n";
	}
	cout.flush();
*/
/*
}

int main(int argc, char *argv[])
{

	Resources::init(argc, argv);

	TestManager *testManager = new TestManager();
	
	return 0;
}
*/
#include <iostream.h>
#include <string.h>

#include "dllist.hxx"

class Item : public DLLItem
{
	char *_name;
	int _value;
public:
	Item(char *name, int value)
	{
		_name = new char[strlen(name)+1];
		strcpy(_name, name);
		_value = value;
	}
	~Item()
	{
		delete _name;
	}
	char *getName() { return _name; }
	int getValue() { return _value; }
};

main()
{
	DLList itemList;
	Item *item;
	int i;
	char name[16];

// fill list
	for(i = 0; i < 10; i++)
	{
		sprintf(name,"PAR%d",i);
		item = new Item(name,i);
		itemList.add(item);
	}
// retrieve list
	item = (Item *)itemList.getHead();
	while(item)
	{
		cout << item->getName() << " = " << item->getValue() << endl;
		item = (Item *)itemList.getNext();
	}
	return 0;
}