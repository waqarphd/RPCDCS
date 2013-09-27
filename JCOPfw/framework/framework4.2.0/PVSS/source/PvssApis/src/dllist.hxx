#ifndef __DLLHHDEFS
#define __DLLHHDEFS
//#include <iostream.h>
//#include <string.h>
//#include <assert.h>

class DLLItem {
	friend class DLList ;
	DLLItem *next;
	DLLItem *prev;
public:
	DLLItem(){
		next = 0;
		prev = 0;
	};
};

class DLList {
	DLLItem *head;
	DLLItem *curr;
public:
	DLList (){
		head = new DLLItem();
		head->next = head;
		head->prev = head;
		curr = head;
	}
	~DLList()
	{
		delete head;
	}
    void add(DLLItem *item)
	{
		DLLItem *prevp;
		item->next = head;
		prevp = head->prev;
		item->prev = prevp;
		prevp->next = item;
		head->prev = item;
	}
	DLLItem *getHead()
	{
		if(head->next == head)
		{
			return((DLLItem *)0);
		}
		curr = head->next;
		return( head->next );
	}
	DLLItem *getLast()
	{
		if(head->prev == head)
		{
			return((DLLItem *)0);
		}
		curr = head->prev;
		return( head->prev );
	}
	DLLItem *getNext()
	{
		curr = curr->next;
		if(curr == head)
		{
			return((DLLItem *)0);
		}
		return( curr );
	}
	DLLItem *removeHead()
	{
		DLLItem *item;
		item = head->next;
		if(item == head)
		{
			return((DLLItem *)0);
		}
		remove(item);
		return(item);
	}
	void remove(DLLItem *item)
	{
		DLLItem *prevp, *nextp;
		prevp = item->prev;
		nextp = item->next;
		prevp->next = item->next;
		nextp->prev = prevp;
	}
};
#endif
