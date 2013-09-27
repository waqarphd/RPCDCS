// pubDpeWrapper.h: interface for the CpubDpeWrapper class.
//
//////////////////////////////////////////////////////////////////////

#if !defined(AFX_PUBDPEWRAPPER_H__22FB9803_14CC_4854_822C_D31851166BAA__INCLUDED_)
#define AFX_PUBDPEWRAPPER_H__22FB9803_14CC_4854_822C_D31851166BAA__INCLUDED_

#if _MSC_VER > 1000
#pragma once
#endif // _MSC_VER > 1000
#include "simpleDPEWrapper.h"

class CdipPubGroup;

/**
* Publisher wrapper for a DPE
*/
class CpubDpeWrapper : public CsimpleDPEWrapper  
{
private:
	/** 
	*ID for DPE time stamp which is associated with the dpId_value
	*/
	DpIdentifier dpId_timeStamp;


	/**
	* used to store the value of the invalid attribute of the DPE
	*/
	bool invalid;


protected:
	/// detemines whether we connect to attributes from online or original
	const CharString  getDPESourceName()const{
		return "online";
	} 


	const CharString getValidAttribName() const{
		return "invalid";
	}

public:
	CpubDpeWrapper(const CharString & dpeName);
	
	
	virtual ~CpubDpeWrapper();


	/**
	* Ensure that the DPE is still valid. Ensures user bits are accessible
	* in addition to the checks done in the super class.
	* @see CsimpleDPEWrapper#revalidateDPE()
	*/
	bool revalidateDPE();

	/*
	* This is a CACHED value obtained when the instance was 
	* created/or revalidateDPE() was called.
	*/
	const DpIdentifier & getDIPTimeStampID() const{// throws CdepException
		validate();
		return dpId_timeStamp;
	}


	/**
	* Store the invalid attribute that is obtained in the hotlink handler for the publsher group
	* this object belongs to.
	*/
	void storeInvalidAttribute(const Variable * invalidAttValue);


	/**
	* returns true if the invalid attribute was set during the last update received form 
	* PVSS for this DPE.
	*/
	bool isInvalidAttributeSet();
};

#endif // !defined(AFX_PUBDPEWRAPPER_H__22FB9803_14CC_4854_822C_D31851166BAA__INCLUDED_)
