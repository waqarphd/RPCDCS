// dpeMapping.cpp: implementation of the CdpeMapping class.
//
//////////////////////////////////////////////////////////////////////
#include "PVSSDIPAPIOptions.h"
#include "dpeMapping.h"
#include "dipManager.h"

//////////////////////////////////////////////////////////////////////
// Construction/Destruction
//////////////////////////////////////////////////////////////////////



CdpeMapping::CdpeMapping(CpubDpeWrapper * theDpe, const CharString & tagName)
:Cmapping(*theDpe, tagName),dpe(theDpe) // throws BadTypeConversionException
{
	converter = TMap::findDpeToDipConverterFor(theDpe->getTypeOfValueID());
	PVSSINFO("Created publisher mapping between DPE " <<
			(const char *)theDpe->getName() << " and tag " <<
			(const char *)tagName);
}




CdpeMapping::~CdpeMapping(){
	if (dpe){
		PVSSINFO("Destroying publisher mapping between DPE " <<
				(const char *)dpe->getName() << " and tag %s" <<
				(const char *)getTagName());
		delete dpe;
	}
}



void CdpeMapping::writeValueToDipData(DipData &dipData, VariablePtr DPEValue){
	converter->convert(dipData, DPEValue, dipTagName.c_str());
}

