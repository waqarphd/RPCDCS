#include "PVSSDIPAPIOptions.h"
//#include <iostream>

#include "CdipDataMapping.h"
#include "CdipSubscription.h"
#include "PVSS_DIP_TypeMap.h"
#include "Manager.hxx"
#include "dipManager.h"
#include "DipApiResources.hxx"



CdipDataMapping::CdipDataMapping(CdpeWrapper & dpId, const CharString & tagName, const CharString & dipAddress, CdipSubscription & sub)
:
Cmapping(dpId,tagName),
lock((std::string(tagName)+"Lock")),
fullDIPAddress(dipAddress),
dpeType(dpId.getTypeOfValueID()),
subscription(sub),
badTypeConversion(false),
mostRecentDipQuality(DIP_QUALITY_UNINITIALIZED),
//excludeTimestampFlag(false),
timeMSecPVSS(-1)	//Just to make sure in case we are Standby System that the test of the timestamp will always fail.
{
	((CdpeWrapper &)mappedDpe).setMapping(this);
	PVSSINFO("New mapping :" <<(const char *)mappedDpe.getName() << " and publication " <<(const char *)fullDIPAddress);

	//Check the timstamp currently in PVSS against the DIP timestamp.
	//This test is only performed once at startup. Then we dont care anymore...
	//PVSSINFO("timestampCheck for "<<(const char *)fullDIPAddress);
	//Asks DIP API Manager configuration reader whether it shall start as hot or standby System.
	if (::DipApiResources::getActiveSystem() == true)
	{
		//We are the active System, check PVSS timestamp.
		timestampCheck();
	}
	else
	{
		// Do nothing.
		// We are the passive system, do nothing because the active will update the PVSS DPE from
		// the DIP data, therefore checking the PVSS timestamp == DIP timestamp is a nonsense.
	}
	
}



CdipDataMapping::~CdipDataMapping(){
	PVSSINFO( "Destroyed client mapping between DPE " << 
		(const char *)mappedDpe.getName() << " and publication " << 
		(const char *)fullDIPAddress);
	getMappedDpe().setMapping(NULL);
}



void CdipDataMapping::addInvalidBitToList(bool val, DpIdValueList &list){

	VariablePtr validIndicator = new BitVar(val);
/*
	//DEBUG ONLY
	if (val == true) {
		PVSSERROR( "This mapping has invalid bit set for some reason:" << 
		(const char *)mappedDpe.getName() << " and publication " << 
		(const char *)fullDIPAddress);}
*/
	list.appendItem(getMappedDpe().getDIPinvalidBit(), validIndicator);
}



void CdipDataMapping::addUserBitsToList(bool ub1,bool ub2,DpIdValueList &list){
	VariablePtr usrBit1Value = new BitVar(ub1);
	VariablePtr usrBit2Value = new BitVar(ub2);
	list.appendItem(getMappedDpe().getDIPusrBit1ID(), usrBit1Value);
	list.appendItem(getMappedDpe().getDIPusrBit2ID(), usrBit2Value);
}

void CdipDataMapping::addValueValidityStatusToList(DpIdValueList &list){
	addInvalidBitToList(shouldDPEBeSetToInvalid(), list);
}

void CdipDataMapping::timestampCheck() {

	try 
	{
		//SmutexGuard guard(lock); // lock this instance whilst in this code block
		DpIdValueList  responseTimstampList;
		DpIdentifier theTimestampIdentifier; 
		DpIdentList localTimstampList;
		CdpGetCallBackHandler localTimestampHandler;
		//Get the mapped DPE and timestamp ID
		theTimestampIdentifier = getMappedDpe().getDIPTimestampID();
		//Now get the associated value for it.
		localTimstampList.append (theTimestampIdentifier);
		mappedDpe.getValuesOfDPEs(localTimestampHandler,localTimstampList);
		//Now decode the response list. (length shall be one).
		responseTimstampList = localTimestampHandler.getListOfResponses();
		const DpVCItem * responseTimestamp  = responseTimstampList.getFirstItem();
		const TimeVar  * valueTimestamp     = (TimeVar *)responseTimestamp->getValuePtr();
		//valueTimestamp->getValue(timeSecondsPVSS, timeMSecPVSS); 
		timeSecondsPVSS = valueTimestamp->getSeconds();
		timeMSecPVSS	= valueTimestamp->getMilli();
		
		PVSSINFO("Current PVSS Timestamp is: " <<timeSecondsPVSS<<"."<<timeMSecPVSS);
		if (valueTimestamp == NULL){
			PVSSERROR("Timestamp for field" <<(const char *)fullDIPAddress<<" has an empty timestamp");
		}
	}
	catch (...)
	{
		PVSSWARNING("Skipped timestamp check for " <<(const char *)fullDIPAddress);
		PVSSINFO("Released lock.");
	}
}

void CdipDataMapping::addValueToList(DipData & data, DpIdValueList &list){
	if (!mappedDpe.isValid()){
		PVSSERROR("DPE object has a problem, mapped DPE is invalid." << fullDIPAddress<<" on " <<mappedDpe.getName());
		// do not execute if our DPE object has a problem!
		// TODO is 'isValid()' ever false??????????????
		return;
	}
	
	if (valueConverter == NULL)
	{
		/**
		* We do not know the converter function untill we know for certian the
		* data type of the tag - which we do'nt know untill we get the first instance
		* of data. So it is at this time we try to find a converter function to convert 
		* between the DIP tag type and the DPE type.
		*/
		try
		{
			const DpElementType & dpeType = mappedDpe.getTypeOfValueID();
			
			int dipType;
			if (dipTagName.length() == 0){
				// no tag name - so we believe the Publication data is primitive
				dipType = data.getValueType();
			}
			else
			{
				// tag name exists - so we believe the Publication data is structured
				dipType = data.getValueType(const_cast<char *>(dipTagName.c_str()));
			}
			
			if (dipType == TYPE_NULL){
				PVSSERROR("DIP address " << (const char *)fullDIPAddress <<
					" does not exist in publication");
				throw BadTypeConversionException(BadTypeConversionException::CANTOBTAINTYPE);
			}
			// have to first get the converter
			valueConverter = TMap::findDipToDpeConverterFor(dipType, dpeType);
		}
		catch(BadTypeConversionException &e)
		{
			/*
			TODO I we can not find convert - we should not try again since DIP pub type 
			should not change.
			*/
			PVSSERROR("Can not find converter (" << e.reason() << ")");
			badTypeConversion = true;
			return;
		}
	}
		
	// Convert the publication data to a type usable by PVSS.
	try
	{
		mostRecentDipQuality = data.extractDataQuality();

		if (mostRecentDipQuality != DIP_QUALITY_UNINITIALIZED)
		{
			VariablePtr pvssValue = valueConverter->getConverter().convert(dipTagName, data);
			list.appendItem(getMappedDpe().getDIPValueID()  , pvssValue);
		}
		int pvssQuality = valueConverter->convertDIPToPVSSQuality(mostRecentDipQuality);
		addUserBitsToList((pvssQuality & 0x000001),(pvssQuality & 0x000002),list);
		badTypeConversion = false;
	}
	catch (...)
	{
		// TODO conversion may fail
		PVSSERROR("Failed to convert either the value or quality from " << 
			(const char *)fullDIPAddress << " to " <<(const char *)getDPEName());
		badTypeConversion = true;
	}
}

bool CdipDataMapping::dpeSubscriptionHasChanged(){
	if (!mappedDpe.revalidateDPE()){
		return true;
	}

	if (fullDIPAddress != (dynamic_cast<CdpeWrapper &>(mappedDpe)).getDipAddress()){
		return true;
	}

	if (dpeType != mappedDpe.getTypeOfValueID()){
		return true;
	}

	return false;
}

bool CdipDataMapping::shouldDPEBeSetToInvalid(){
	/**
	* DPE will be set to invalid under the following conditions:-
	* 1. Can not find a type conversion function for the DPE/DIP Pub tag type.
	* 2. The DIP publication mapped to is no longer available.
	* 3. The conversion function is no longer working (pub tag type changed or tag missing)
	*/

	if (valueConverter == NULL){ // .... 1
		PVSSWARNING("CdipDataMapping::shouldDPEBeSetToInvalid() - set to invalid because could not find type converter");
		return true;
	}

	if (!subscription.isConnectedToPublication()){        // .... 2
		PVSSWARNING("CdipDataMapping::shouldDPEBeSetToInvalid() - set to invalid because not connected to publication");
		return true;
	}


	if (badTypeConversion){      // .... 3
		PVSSWARNING("CdipDataMapping::shouldDPEBeSetToInvalid() - set to invalid because of bad type conversion (type changed?)");
		return true;
	}
	return false;
}

