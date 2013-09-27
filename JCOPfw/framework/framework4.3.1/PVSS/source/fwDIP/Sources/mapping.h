// mapping.h: interface for the Cmapping class.
//
//////////////////////////////////////////////////////////////////////

#if !defined(AFX_MAPPING_H__2FFCF66D_7F7D_473C_A65A_EE6E67B3BBA4__INCLUDED_)
#define AFX_MAPPING_H__2FFCF66D_7F7D_473C_A65A_EE6E67B3BBA4__INCLUDED_

#if _MSC_VER > 1000
#pragma once
#endif // _MSC_VER > 1000

#include "simpleDPEWrapper.h"
#include "PVSS_DIP_TypeMap.h"


/**
* This class is used to associate a DPE with a DIP entity (publication 
* or subscription depending on subtype)
*/
class Cmapping  
{
protected:
	/** 
	* holds the converter object to convert from the DIP type to PVSS type
	* THIS IS NOT OWNED - MUST NOT BE DESTROYED BY THIS INSTANCE
	* get ride of this
	*/
	TConv * valueConverter;


	/// wrapper for the DPE we map to
	CsimpleDPEWrapper & mappedDpe;


	/// May be empty in which case default DipData accessor should be used
	const std::string dipTagName;


public:
	Cmapping(CsimpleDPEWrapper & dpId, const CharString & tagName);

	const char * getTagName(){
		return dipTagName.c_str();
	}

	const char * getDPEName(){
		return mappedDpe.getName();
	}

	virtual ~Cmapping();
};

#endif // !defined(AFX_MAPPING_H__2FFCF66D_7F7D_473C_A65A_EE6E67B3BBA4__INCLUDED_)
