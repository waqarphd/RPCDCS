#ifndef __HASHHHDEFS
#define __HASHHHDEFS

#include <dis.hxx>

#if defined __cplusplus
         /* If the functions in this header have C linkage, this
           * will specify linkage for all C++ language compilers.
           */
         extern "C" {
#endif

#include "dim.h"
#if defined __cplusplus
       }    /* matches the linkage specification at the beginning. */
#endif

class /*DllExp*/ HASHItem {
	friend class DLList ;
	HASHItem *next;
	HASHItem *prev;
	char *theKey;
public:
	HASHItem(char *key);
	char *getKey();
};

class /*DllExp*/ HASHTable {
public:
	HASHTable ();
	~HASHTable();
    void add(HASHItem *item, char *key);
	HASHItem *getItem(char *key);
	HASHItem *getHead();
	HASHItem *getNext();
//	HASHItem *removeHead();
	void remove(HASHItem *item);
private:
	int HashFunction(char *key, int max);
	HASHItem *currItem;
	int currIndex;
};
#endif
