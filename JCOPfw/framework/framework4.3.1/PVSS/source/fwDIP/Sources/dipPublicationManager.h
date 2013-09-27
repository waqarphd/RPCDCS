// dipPublicationManager.h: interface for the CdipPublicationManager class.
//
//////////////////////////////////////////////////////////////////////

#if !defined(AFX_DIPPUBLICATIONMANAGER_H__1C22908C_5338_45B7_8D11_25B3135B552E__INCLUDED_)
#define AFX_DIPPUBLICATIONMANAGER_H__1C22908C_5338_45B7_8D11_25B3135B552E__INCLUDED_

#if _MSC_VER > 1000
#pragma once
#endif // _MSC_VER > 1000

#include <vector>
#include <map>
#include "dipPubGroup.h"
#include "dipManager.h"
#include "platformDependant.h"


class CPubGroupException;

/**
* Keeps track of all publications running in this process.
* Can not change/delete publication once created
*/
class CdipPublicationManager:public CdipManager
{
private:

	/**
	* Used to prevent the data object being updated while the publication are being destroyed.
	*/
	SMutex DIPPublicationLock;
	
	
	///list of all publications manager by this manager 
	static std::map<const CharString * ,CdipPubGroup *, CharStringLess> publications;


	/**
	* Breaks a string seperated by CdipClientManager::pubNameDelimiter into
	* substrings. Each substring the string upto but not incliding the
	* delimiter. Some substrings may be null (e.g. the string contains
	* two delimiters in a row)
	*/
	static void extractStringsFromCompoundString(CharString &compoundString, std::vector<std::string> & strings);


	/**
	* Make a publication group
	* @param theBufferTime_ms buffer time in mSec
	* @returns true if sucessfull, false otherwise.
	*/
	static bool makePublication(const CharString & thePubName, const int theBufferTime_ms,const CvectorOfdpeMappingTuples &mappingList);

public:
	CdipPublicationManager(DipApiManager &m);
	virtual ~CdipPublicationManager();

	/**
	* Will only add new publications
	*/
	void dataChanged(const VariablePtr changedData);


	bool destroyAllDIPPublication() throw (CPubGroupException);

	bool rebindAllDIPPublication() throw (CPubGroupException);

};

#endif // !defined(AFX_DIPPUBLICATIONMANAGER_H__1C22908C_5338_45B7_8D11_25B3135B552E__INCLUDED_)
