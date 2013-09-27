#ifndef PVSS_DIP_TYPEMAP_H
#define PVSS_DIP_TYPEMAP_H

#include <map>
#include <vector>
#include "DpElementType.hxx"
#include "Variable.hxx"


//#define TEST_NODIP
#ifndef TEST_NODIP
#include "Dip.h"
#include "DipData.h"
#else
#include "DummyDIPData.h"
#endif



class BadTypeConversionException{
public:
	enum Ereason{BADTYPE, UNSUPPORTEDTYPE, CANTOBTAINTYPE};
private:
	const Ereason why;
public:
	BadTypeConversionException(Ereason reason):why(reason){};

	Ereason reason() const {return why;}
};





/**
* Interface for the DIP to PVSS type converter class' 
*/
class CdipToPVSSTypeConverter{
public:
	/**
	* Convert from DIP data to PVSS data
	* caller owns returned ptr
	*/
	virtual VariablePtr convert(const std::string & tag, DipData & data) const =0;
};





/**
* Interface for PVSS to DIP type conversion function object
*/
class CpvssToDipTypeConverter{
public:
	/**
	* Convert from PVSS data to DIP data
	*/
	virtual void convert(DipData &dipData, VariablePtr DPEValue, const CharString & tagName) const =0; // throws BadTypeConversionException
};

















/**
* Holds the type conversion information
*/
class TConv{
	private:
		/// ID of DIP type that is equivalent to the DPE type.
		const int DIPtypeID;

		/// ID of DPE type that is equivalent to the DIP type.
		const int DPEtypeID;

		/// function object to convert from DIP type to PVSS type
		const CdipToPVSSTypeConverter & converter; 
	public:

		TConv(const int dipTypeID, const int dpeTypeID, const CdipToPVSSTypeConverter & converterObj);


		bool willConvert(const int dipType, const int dpeType) const;

		const CdipToPVSSTypeConverter & getConverter(){
			return converter;
		}

		/**
		* get the type of the DPE this converter will convert to
		*/
		const int getDPEtypeID() const{
			return DPEtypeID;
		}


		/**
		* Convert from DIP quality to an OPC style quality
		* used by PVSS
		* maps 
		* -1(DIP unint) to  0 (00 - bad)
		* 0 (DIP bad)   to  0 (00 - bad)
		* 1 (good)      to  3 (11 - good)
		* 2 (uncertain) to  1 (01 - uncertain)
		* Will throw a BadTypeConversionException if the quality is not in the
		* closed range -1 to 2
		*/
		static int convertDIPToPVSSQuality(int dipQuality); // throws BadTypeConversionException
};








class TMap{
	private:
		/**
		* keyed on DIP type
		*/
		static std::map<int, TConv *> dipToPvsstypeConverterList;

		/**
		* Keyed on PVSS type. Holds a map of type converters from PVSS to DIP types.
		*/
		static std::map<int, CpvssToDipTypeConverter *> pvssToDipTypeConverterMap;

	public:
		TMap();

		/**
		* Find a conversion object that will convert to/from the type of the supplied 
		* CALLER DOES NOT OWN RETURNED PTR
		*/
		static TConv * findDipToDpeConverterFor(const int dipType, const int dpeType); // throw BadTypeConversionException


		/**
		* find a converter that will convert from the supplied dip type
		*/
		static TConv *findDipToDpeConverterFor(const int dipType);// throw BadTypeConversionException


		/**
		* Find a conversion object that will convert from the PVSS type supplied 
		* CALLER DOES NOT OWN RETURNED PTR
		*/
		static CpvssToDipTypeConverter * findDpeToDipConverterFor(const int dpeType); // throw BadTypeConversionException
};


#endif
