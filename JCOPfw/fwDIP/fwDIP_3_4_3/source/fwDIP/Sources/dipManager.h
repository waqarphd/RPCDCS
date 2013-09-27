// dipManager.h: interface for the CdipManager class.
// test
//////////////////////////////////////////////////////////////////////

#if !defined(AFX_DIPMANAGER_H__1356949B_2A72_4BB8_9A86_13F6E6E3D26A__INCLUDED_)
#define AFX_DIPMANAGER_H__1356949B_2A72_4BB8_9A86_13F6E6E3D26A__INCLUDED_
#include "PVSSDIPAPIOptions.h"
#if _MSC_VER > 1000
#pragma once
#endif // _MSC_VER > 1000
#include "DynVar.hxx"
#include "IntegerVar.hxx"
#include "SString.h"
#include "ErrHdl.hxx"



/**
* function used for ordering entries in the maps. For some reason less<>
* was not working.
*/
struct CharStringLess  {
	bool operator()(const CharString * _X, const CharString * _Y) const
		{return ((*_X < *_Y) == 1);
	}
};


class DipApiManager;

/**
* Interface to enable common config update code for client and
* publication managers
*/
class CdipManager
{
protected:
	/**
	* ref to the API manager
	*/
	DipApiManager & apiManager;

public:
	CdipManager(DipApiManager & apiMan);
	virtual ~CdipManager();

	virtual void dataChanged(const VariablePtr changedData) = 0;

};

#endif // !defined(AFX_DIPMANAGER_H__1356949B_2A72_4BB8_9A86_13F6E6E3D26A__INCLUDED_)
