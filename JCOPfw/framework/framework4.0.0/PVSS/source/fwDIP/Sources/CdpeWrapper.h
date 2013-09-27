#ifndef CDPEWRAPPER_H
#define CDPEWRAPPER_H


#include "simpleDPEWrapper.h"


class CdipDataMapping; // forward decl.

/**
* Extension of the simpleDPEWrapper used for DPE clints.
* Adds access to DPE's valid and usr bits.
*/
class CdpeWrapper:public CsimpleDPEWrapper{
private:
	/// ID for DPE original usrbit1
	DpIdentifier dpId_usrBit1;

	/// ID for DPE original usrbit2
	DpIdentifier dpId_usrBit2;


	/// Name of the publication to be subscribed to - as obtained from addConfig on last revalidateDPE()
	CharString nameOfDIPPublication;
	
	/*
		good values of the above members must be obtained for
		the instance to be considered valid.
	*/



	/**
	* Points to the mapping definition (which defines how a DIP publication field
	* is to be mapped into this DPE) for this DPE.
	* NO OWNED! May be null.
	*/
	CdipDataMapping * mapping;
protected:
	/// detemines whether we connect to attributes from online or original
	virtual const CharString getDPESourceName() const{
		return "original";
	}


	const CharString getValidAttribName() const{
		return "exp_inv";
	}

	/**
	* Will get the current DIP address from the address config of the DPE
	* @param dipAddress - value it true returned
	* @returns true if could obtain address - false if not. 
	* Failure may occur if
	* 1) Driver type is no longer DIP
	* 2) Address config no longer exists.
	* 3) Address is empty.
	*/
	bool retriveDIPAddress(CharString & dipAddress) const;

public:
	/**
	* obtains dpid for original value of pdeName
	* @param dpeName name of PVSS DPE (should be a primitive) - not terminated with .
	*/
	CdpeWrapper(const CharString & dpeName);


	~CdpeWrapper(){
	}

	/**
	* returns the mapping object
	*/
	CdipDataMapping * getMapping() const{
		return mapping;
	}

	
	/**
	* sets the mapping object
	*/
	void setMapping(CdipDataMapping * map){
		mapping = map;
	}

	/**
	* Will try to reobtain the DPE attributes, DIP address and value data type
	* required to work correctly,
	* @returns true if it could obtain required attribs, false otherwise.
	*/
	virtual bool revalidateDPE();




	/*
	* This is a CACHED value obtained when the instance was 
	* created/or revalidateDPE() was called.
	*/
	const DpIdentifier & getDIPusrBit1ID() const{// throws CdepException
		validate();
		return dpId_usrBit1;
	}


	/*
	* This is a CACHED value obtained when the instance was 
	* created/or revalidateDPE() was called.
	*/
	const DpIdentifier & getDIPusrBit2ID() const{// throws CdepException
		validate();
		return dpId_usrBit2;
	}




	/**
	* Returns DIP name that the DPE is to be subscribed to.
	* This is a CACHED value obtained when the instance was 
	* created/or revalidateDPE() was called.
	*/
	const CharString & getDipAddress()const {// throws CdepException
		validate();
		return nameOfDIPPublication;
	}
};



#endif

