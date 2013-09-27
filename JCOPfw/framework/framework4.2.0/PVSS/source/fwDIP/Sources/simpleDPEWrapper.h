// simpleDPEWrapper.h: interface for the CsimpleDPEWrapper class.
//
//////////////////////////////////////////////////////////////////////

#if !defined(AFX_SIMPLEDPEWRAPPER_H__3FA1A97F_981E_4399_AFD2_69BB645B3FBF__INCLUDED_)
#define AFX_SIMPLEDPEWRAPPER_H__3FA1A97F_981E_4399_AFD2_69BB645B3FBF__INCLUDED_

#if _MSC_VER > 1000
#pragma once
#endif // _MSC_VER > 1000
#include "Manager.hxx"
#include "AnswerCallBackHandler.h"

class CdepException{};

/**
* A basic DPE wrapper which keeps track of DPE type value and DIP address. 
* NOTE the instance must be valid to be used. Otherwise a CdepException
* is likely to be thrown.
* @see isValid()
*/
class CsimpleDPEWrapper  
{
private:
	/// ID for DPE <sourceName> value
	DpIdentifier dpId_value;

	// ID for DPE <sourceName> timestamp 
	DpIdentifier dpId_timestamp;


	/// data type of the '.:_<sourceName>.._value' attribute of the DPE
	DpElementType valueType;

	/** 
	*ID for DPE <sourceName>  invalid which is associated with the dpId_value
	* May be id of _expinv or _bad depending on sub class.
	*/
	DpIdentifier dpId_invalid;

	/// ID for DPE correctionValue
	DpIdentifier dpId_corrValue;

	// ID for DPE correctionValue timestamp 
	DpIdentifier dpId_corrTimestamp;

	// ID for Archive archive flag
	DpIdentifier dpId_archiveArchive;

	// ID for Archive Type value
	DpIdentifier dpId_archiveType;

	/*
		good values of the above members must be obtained for
		the instance to be considered valid.
	*/


	/// name of the DPE;
	const CharString name;

	/**
	* Used for mark and sweep algorithm. If true then this instance will not be 
	* deleted when sweep is next run.
	*/
	bool marked;


protected:

	/**
	* Set to true if we were able to retreive the
	* DpIdentifier.
	*/
	bool valid;

	bool m_isDpeBeingArchived;

	DpIdentifier dpId_corrValueLock;

    DpIdentifier dpId_origValueLock;



	/// will throw exception if dpeID is not valid.
	void validate() const{// throws CdepException
		if (!isValid()) throw CdepException();
	}


	/**
	*Makes a list of deIdens from a list of element names.
	* @returns number of entries in the list.
	*/
	static int makeListOfDPEs(DpIdentList &dpList, const CharString *dpNames, const int noNames);



	/// Gets the data type of the '.:_<sourceName>.._value' attribute of the DPE
	bool retrieveDPEsValueType(DpElementType & valueType) const;

	
	/// detemines whether we connect to attributes from online or original
	virtual const CharString  getDPESourceName()const = 0;



	/**
	*determines whether we access the _expinv or _invalid attributes when we call
	* getDIPinvalidBit().
	*/
	virtual const CharString getValidAttribName() const = 0;


public:
	CsimpleDPEWrapper(const CharString & dpeName);


	virtual ~CsimpleDPEWrapper();



	/**
	* gets the current value of the dpe's in the list. The values are returned inside
	* the hander.
	*/
	static void getValuesOfDPEs(CdpGetCallBackHandler & handler, const DpIdentList &list);

	/**
	* @returns true if was able to obtain DPE attributes, false otherwise.
	* @see revalidateDPE
	*/
	bool isValid() const{
		return valid;
	}


	/**
	* returns name of the DPE (copy of string passed to the constructor)
	*/
	const CharString & getName() const{
		return name;
	}




	/*
	* This is a CACHED value obtained when the instance was 
	* created/or revalidateDPE() was called.
	*/
	const DpElementType & getTypeOfValueID() const{// throws CdepException
		validate();
		return valueType;
	}



	/*
	* This is a CACHED value obtained when the instance was 
	* created/or revalidateDPE() was called.
	*/
	const DpIdentifier & getDIPValueID() const{// throws CdepException
		validate();
		return dpId_value;
	}

	/*
	* This is a CACHED value obtained when the instance was 
	* created/or revalidateDPE() was called.
	*/
	const DpIdentifier & getDIPTimestampID() const{// throws CdepException
		validate();
		return dpId_timestamp;
	}


	/*
	* This is a CACHED value obtained when the instance was 
	* created/or revalidateDPE() was called.
	*/
	const DpIdentifier & getDIPinvalidBit() const{// throws CdepException
		validate();
		return dpId_invalid;
	}

	/*
	* This is a CACHED value obtained when the instance was 
	* created/or revalidateDPE() was called.
	*/
	const DpIdentifier & getDpeCorrValueLockID() const{// throws CdepException
		validate();
		return dpId_corrValueLock;
	}

	const DpIdentifier & getDIPCorrValueID() const{// throws CdepException
		validate();
		return dpId_corrValue;
	}

	const DpIdentifier & getDIPCorrValueTimestamp() const{// throws CdepException
		validate();
		return dpId_corrTimestamp;
	}

	/*
	* This is a CACHED value obtained when the instance was 
	* created/or revalidateDPE() was called.
	*/
	const DpIdentifier & getDpeOrigValueLockID() const{// throws CdepException
		validate();
		return dpId_origValueLock;
	}

	/*
	* This is a CACHED value obtained when the instance was 
	* created/or revalidateDPE() was called.
	*/
	const DpIdentifier & getDpeArchiveArchiveID() const{// throws CdepException
		validate();
		return dpId_archiveArchive;
	}

	/*
	* This is a CACHED value obtained when the instance was 
	* created/or revalidateDPE() was called.
	*/
	const DpIdentifier & getDpeArchiveTypeID() const{// throws CdepException
		validate();
		return dpId_archiveType;
	}
	/**
	* Sets the marked flags to true -> thus preventing the removal of this mapping
	* Used for the CdipClientManager's mark/sweep algorithm to clear 
	* old DPE subscriptions.
	*/
	void mark(){
		marked = true;
	}
	
	/**
	* Clears the marked flag
	* Used for the CdipClientManager's mark/sweep algorithm to clear 
	* old DPE subscriptions.
	*/
	void clearMark(){
		marked = false;
	}
	
	
	/**
	* Identifies if the instances mark flag is set (if not it will be deleted)
	* Used for the CdipClientManager's mark/sweep algorithm to clear 
	* old DPE subscriptions.
	*/
	bool isMarked() const{
		return marked;
	}



	bool operator==(const CsimpleDPEWrapper & wrapper) const{
		return ((name == wrapper.name) == 1);
	}


	/**
	* Will try to reobtain the DPE attributes, DIP address and value data type
	* required to work correctly,
	* @returns true if it could obtain required attribs, false otherwise.
	*/
	virtual bool revalidateDPE();

	/**
	* @returns true if the DPE is being archived.
	* @see revalidateDPE
	*/
	bool isDpeBeingArchived(){
		return m_isDpeBeingArchived;
	}


};

#endif // !defined(AFX_SIMPLEDPEWRAPPER_H__3FA1A97F_981E_4399_AFD2_69BB645B3FBF__INCLUDED_)
