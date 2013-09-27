// dpeMappingTuple.h: interface for the CdpeMappingTuple class.
//
//////////////////////////////////////////////////////////////////////

#if !defined(AFX_DPEMAPPINGTUPLE_H__C8BC8954_F973_4F5C_B72B_84F9439BD89E__INCLUDED_)
#define AFX_DPEMAPPINGTUPLE_H__C8BC8954_F973_4F5C_B72B_84F9439BD89E__INCLUDED_

#if _MSC_VER > 1000
#pragma once
#endif // _MSC_VER > 1000

#include "CharString.hxx"
#include <vector>

class CdpeMappingTuple{
	const CharString DPEname;
	const CharString tagName;

public:
	CdpeMappingTuple(const CharString & theDpeName, const CharString & theTagName)
		:DPEname(theDpeName), tagName(theTagName){}


	/// Used to indicate that this mapping has no tag
	static const CharString noTag;

	/// true if there is a tag name
	bool hasTag() const{
		return ((tagName != noTag) == 1);
	}

	const CharString & getDpeName() const{
		return DPEname;
	}

	const CharString & getTagName() const{
		return tagName;
	}
};


class CvectorOfdpeMappingTuples:public std::vector<CdpeMappingTuple *>{
public:
	~CvectorOfdpeMappingTuples(){
		for (unsigned int i = 0; i < this->size(); i++){
			delete (*this)[i];
		}
	}
};

#endif // !defined(AFX_DPEMAPPINGTUPLE_H__C8BC8954_F973_4F5C_B72B_84F9439BD89E__INCLUDED_)
