// Browser.h: interface for the Browser class.
//
//////////////////////////////////////////////////////////////////////

#if !defined(AFX_BROWSER_H__7691CE0B_6381_42B1_89EB_5C941AF1E4BE__INCLUDED_)
#define AFX_BROWSER_H__7691CE0B_6381_42B1_89EB_5C941AF1E4BE__INCLUDED_

#if _MSC_VER > 1000
#pragma once
#endif // _MSC_VER > 1000

#include "CharString.hxx"
#include "dipManager.h"
#include <map>
#include <vector>

//#define LOCALBROWSETEST   // test the parsing of the namespace/child/field extraction - e.t.c without testing PVSS
//#define SIMULATE_DIPNAMESPACE  // simulate a DIP namespace
#ifdef LOCALBROWSETEST
#define SIMULATE_DIPNAMESPACE // DO NOT CHANGE if LOCALBROWSETEST is defined SIMULATE_DIPNAMESPACE must also be defined		
#endif

#ifdef SIMULATE_DIPNAMESPACE
class DipBrowser;
#else
#include "DipBrowser.h"
#endif




class TreeNode;
class BrowserManager;
class BrowseException{};


/**
* Used to respond to the browser request event
*/
class BrowseRequestHandler:public CdipManager{
private:
	/**
	* Reference back to the manager
	*/
	BrowserManager & browser;

	/**
	* PVSS DPE id's needed by this handler to pass namespace
	* info back into PVSS
	*/
	DpIdentifier fieldNameDpeID;
	DpIdentifier fieldTypeDpeID;
	DpIdentifier childNameDpeID;
	DpIdentifier childTypeDpeID;
	DpIdentifier browseStatusDpeID;

public:
	BrowseRequestHandler(BrowserManager &b, DipApiManager &m):CdipManager(m),browser(b){};

	/**
	* Reads the browse hierarchy from the point specified
	*/
	void dataChanged(const VariablePtr changedData);

	/**
	* Set all the DPE ids that are required to sending a browse response from
	* the API manager to PVSS
	*/
	void setResponseIds(DpIdentifier &fieldName,DpIdentifier& fieldType,
					DpIdentifier& childName,DpIdentifier& childType,
					DpIdentifier& browseStatus){
		fieldNameDpeID = fieldName;
		fieldTypeDpeID = fieldType;
		childNameDpeID = childName;
		childTypeDpeID = childType;
		browseStatusDpeID = browseStatus;
	}
};



/**
* Used to respond to a refresh name space request
*/
class UpdateBrowseSpaceRequestHandler:public CdipManager{
private:
	BrowserManager & browser;

	DpIdentifier refreshActionStatusID;

public:
	UpdateBrowseSpaceRequestHandler(BrowserManager &b, DipApiManager &m):CdipManager(m),browser(b){};

	void dataChanged(const VariablePtr changedData);

	/**
	* Set the DPE id required to confirm that a dip names space update has
	* completed
	*/
	void setResponseIds(DpIdentifier& refreshStatus){
		refreshActionStatusID = refreshStatus;
	}
};





/**
* This class should be a singleton - manages the objects associated
* with browsing. 
* Due to the latency associated with obtaining the DIP namespace, we 
* maintain an internal cache of the DIP namespace and refresh it when
* requested from the PVSS user. 
*/
class BrowserManager  
{
private:
	/**
	* Root of the browse tree
	* OWNED
	*/
	TreeNode * root;

public:
	/**
	* Handler for PVSS user browse requests
	*/
	BrowseRequestHandler *browseRequestHandler;


	/**
	* Handler for PVSS user refresh cached namespace requests
	*/
	UpdateBrowseSpaceRequestHandler *updateBrowseSpaceRequestHandler;

	BrowserManager(DipApiManager & apiMan);
	virtual ~BrowserManager();


	/**
	* Update our internal representation of the DIP namespace
	*/
	void updateNameSpace();

	/***
	* Get child and field info for the named node.
	*/
	int getNodeInfo(SString &nodeName, 
				     std::vector<SString> & fieldNames, 
					 std::vector<int> & fieldTypes, 
					 std::vector<SString> & childNames,
					 std::vector<int> & childTypes);

	/**
	* Clear the internal representation of the DIP namespace
	*/
	void clearNameSpace();

	/**
	* The DipBrowser object
	*/
	static DipBrowser * dipBrowser;

	/**
	* Used to seperate the hiarchies in the DIP namespace
	*/
	static const char nameSpaceSeperator;
};




#endif // !defined(AFX_BROWSER_H__7691CE0B_6381_42B1_89EB_5C941AF1E4BE__INCLUDED_)
