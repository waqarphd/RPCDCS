// dpeMapping.h: interface for the CdpeMapping class.
//
//////////////////////////////////////////////////////////////////////

#if !defined(AFX_DPEMAPPING_H__9FB4590A_557D_4198_A7DA_86DB93E236F8__INCLUDED_)
#define AFX_DPEMAPPING_H__9FB4590A_557D_4198_A7DA_86DB93E236F8__INCLUDED_

#if _MSC_VER > 1000
#pragma once
#endif // _MSC_VER > 1000

#include "mapping.h"
#include "dpeMappingTuple.h"
#include "pubDpeWrapper.h"
#include <assert.h>


/**
* Used to associate a DPE with pvss to DIP type conversion function
*/
class CdpeMapping:public Cmapping  
{
private:
	//OWNED
	CpubDpeWrapper * dpe; 

	/// NOT OWNED
	CpvssToDipTypeConverter * converter;

public:
	/**
	* Will throw exception if can not find a type Converter
	* ownership of theDpe is passed to this instance if all is OK
	* See http://www.gotw.ca/gotw/066.htm for a good discussion on 
	* constructors throwing exceptions.
	*/
	CdpeMapping(CpubDpeWrapper * theDpe, const CharString & tagName);


	virtual ~CdpeMapping();

	/**
	* DPEValue is NOT owned
	*/
	void writeValueToDipData(DipData &dipData, VariablePtr DPEValue);// throws BadTypeConversionException



	/**
	* Returns the DPE this mapping maps to.
	*/
	CpubDpeWrapper & getMappedDpe() const{ 
		return dynamic_cast<CpubDpeWrapper &>(mappedDpe);
	}
};

#endif // !defined(AFX_DPEMAPPING_H__9FB4590A_557D_4198_A7DA_86DB93E236F8__INCLUDED_)
