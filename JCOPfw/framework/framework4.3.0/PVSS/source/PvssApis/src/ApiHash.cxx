#include "ApiHash.hxx"

#define MAX_HASH_ENTRIES 5000

static void *TheHASHTable[MAX_HASH_ENTRIES];


HASHItem::HASHItem(char *key)
{
		next = 0;
		prev = 0;
	    theKey = new char[strlen(key)+1];
		strcpy(theKey,key);
}

char *HASHItem::getKey()
{
	return theKey;
}

HASHTable::HASHTable()
{
  int i;
  static int done = 0;

  if(!done)
  {
	for( i = 0; i < MAX_HASH_ENTRIES; i++ ) 
	{
		TheHASHTable[i] = (void *) malloc(8);
		dll_init((DLL *) TheHASHTable[i]);
	}
	done = 1;
  }
}

HASHTable::~HASHTable()
{
}

void HASHTable::add(HASHItem *item, char *key)
{
	int index;

	index = HashFunction(key, MAX_HASH_ENTRIES);
	dll_insert_queue((DLL *) TheHASHTable[index], 
			 (DLL *) item);
}

HASHItem *HASHTable::getItem(char *key)
{
	int index;
	HASHItem *ptr;

	index = HashFunction(key, MAX_HASH_ENTRIES);
	ptr = (HASHItem *) dll_get_next((DLL *) TheHASHTable[index],
		(DLL *) TheHASHTable[index]);
	while (ptr)
	{
		if(!strcmp(ptr->getKey(), key))
			return(ptr);
		ptr = (HASHItem *) dll_get_next(
						(DLL *) TheHASHTable[index],
						(DLL *) ptr);
	}
	return((HASHItem *)0);
}			

HASHItem *HASHTable::getHead()
{
	HASHItem *ptr;

	currIndex = 0;
	ptr = (HASHItem *) dll_get_next((DLL *) TheHASHTable[currIndex],
		(DLL *) TheHASHTable[currIndex]);
	currItem = ptr;
	return(ptr);
}			

HASHItem *HASHTable::getNext()
{
	if(currItem)
	{
		currItem = (HASHItem *) dll_get_next(
						(DLL *) TheHASHTable[currIndex],
						(DLL *) currItem);
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
			currItem = (HASHItem *) dll_get_next((DLL *) TheHASHTable[currIndex],
				(DLL *) TheHASHTable[currIndex]);
		} while(!currItem);
	}
	return(currItem);
}			

void HASHTable::remove(HASHItem *ptr)
{
	dll_remove( (DLL *)ptr );
}			


int HASHTable::HashFunction(char *name, int max)
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
