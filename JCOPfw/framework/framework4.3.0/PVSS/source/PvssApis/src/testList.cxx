
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