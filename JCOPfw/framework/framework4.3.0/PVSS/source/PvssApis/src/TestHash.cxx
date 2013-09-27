#include "dis.hxx"
#include <iostream.h>

#define MAX_HASH_ENTRIES 2000

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
	HASHItem *find(char *key);
	HASHItem *getHead();
	HASHItem *getNext();
private:
	DLList hashTable[MAX_HASH_ENTRIES];
	int hashFunction(char *key, int max);
	HASHItem *currItem; 
	int currIndex;
};

class TestItem : public HASHItem
{
private:
	char *dimLine;
public:
	TestItem(char *line)
	{
	    dimLine = new char[strlen(line)+1];
		strcpy(dimLine,line);
	}
	~TestItem()
	{
		delete dimLine;
	}
	char *getLine() {return dimLine;};
};

class TestManager
{
public:
	TestManager() {};
	HASHTable todoList;
	void print();
};


HASHItem::HASHItem()
{
	theKey = 0;
}

HASHItem::~HASHItem()
{
	if(theKey)
		delete(theKey);
}

void HASHItem::setKey(char *key)
{
	if(theKey)
		delete(theKey);
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
}

void HASHTable::remove(char *key, HASHItem *ptr)
{
	int index;

	index = hashFunction(key, MAX_HASH_ENTRIES);
	hashTable[index].remove((HASHItem *)ptr);
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

HASHItem *HASHTable::getHead()
{
	HASHItem *ptr;

	currIndex = 0;
	ptr = (HASHItem *)hashTable[currIndex].getHead();
	currItem = ptr;
	return(ptr);
}

HASHItem *HASHTable::getNext()
{
	if(currItem)
	{
		currItem = (HASHItem *)hashTable[currIndex].getNext();
	}
	if(!currItem)
	{
		do
		{
			currIndex++;
			if(currIndex == MAX_HASH_ENTRIES)
			{
				return((HASHItem *) 0);
			}
			currItem = (HASHItem *)hashTable[currIndex].getHead();
		} while(!currItem);
	}
	return(currItem);
}

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


main()
{
	int i;
	TestManager myMan;
	TestItem *item;
	char str[128];

	for(i = 0; i < 1000; i++)
	{
		sprintf(str,"Item%03d",i);
		item = new TestItem(str);
		myMan.todoList.add(str, item);

	}
	myMan.print();

	item = (TestItem *)myMan.todoList.find("Item001");
	cout << endl << "Found: " << item->getLine() << endl << endl;

	myMan.todoList.remove("Item001", item);

	myMan.print();
	while(1)
		sleep(10);
	return(1);
}

void TestManager::print()
{
	TestItem *item;
	int n = 0;

	item = (TestItem *)todoList.getHead();
	while(item)
	{
		cout << n << " Item: " << item->getLine() << endl;
		n++;
		item = (TestItem *)todoList.getNext();
	}
}
