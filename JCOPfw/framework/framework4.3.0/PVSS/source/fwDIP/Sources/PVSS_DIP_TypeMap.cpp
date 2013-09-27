#include "PVSSDIPAPIOptions.h"
#include "PVSS_DIP_TypeMap.h"
#include "IntegerVar.hxx"
#include "FloatVar.hxx"
#include "BitVar.hxx"
#include "CharVar.hxx"
#include "TextVar.hxx"
#include "DynVar.hxx"
#include "Bit32Var.hxx"
#include "UIntegerVar.hxx"


/**
			
					Dip to PVSS type converters

*/



/// Maps to the PVSS bool type
class CdipBoolToPVSS:public CdipToPVSSTypeConverter{
public:
	VariablePtr convert(const std::string & tag, DipData & data) const{
		DipBool value;

		if (tag.length() == 0){
			value = data.extractBool();
		} else {
			value = data.extractBool(const_cast<char *>(tag.c_str()));
		}
	
	return new BitVar(value);  
	}
};

/// Maps to the PVSS bool type
class CdipBoolToPVSSInt:public CdipToPVSSTypeConverter{
public:
	VariablePtr convert(const std::string & tag, DipData & data) const{
		DipBool value;

		if (tag.length() == 0){
			value = data.extractBool();
		} else {
			value = data.extractBool(const_cast<char *>(tag.c_str()));
		}

		if(value == true){
			return new IntegerVar(1);
		}else{
			return new IntegerVar(0);
		}
	
	}
};

/// Maps to the PVSS Bit32 type
class CdipByteToPVSS:public CdipToPVSSTypeConverter{
public:
	VariablePtr convert(const std::string & tag, DipData & data) const{
		DipInt value;

		if (tag.length() == 0){
			value = data.extractByte();
		} else {
			value = data.extractByte(const_cast<char *>(tag.c_str()));
		}
	
		return new Bit32Var(value);  
	}
};


/// Maps to the PVSS int type
class CdipShortToPVSS:public CdipToPVSSTypeConverter{
public:
	VariablePtr convert(const std::string & tag, DipData & data) const{
		DipInt value;

		if (tag.length() == 0){
			value = data.extractShort();
		} else {
			value = data.extractShort(const_cast<char *>(tag.c_str()));
		}
	
		return new IntegerVar(value);  
	}
};


/// Maps to the PVSS int type
class CdipIntToPVSS:public CdipToPVSSTypeConverter{
public:
	VariablePtr convert(const std::string & tag, DipData & data) const{
		DipInt value;

		if (tag.length() == 0){
			value = data.extractInt();
		} else {
			value = data.extractInt(const_cast<char *>(tag.c_str()));
		}
	
		return new IntegerVar(value);  
	}
};


/// Maps to the PVSS int type (NOTE DIPLong is 64bit, PVSSint is 32 bits)
class CdipLongToPVSS:public CdipToPVSSTypeConverter{
public:
	VariablePtr convert(const std::string & tag, DipData & data) const{
		DipLong value;

		if (tag.length() == 0){
			value = data.extractLong();
		} else {
			value = data.extractLong(const_cast<char *>(tag.c_str()));
		}
	
		return new IntegerVar(value);  
	}	
};



/// Maps to the PVSS float type
class CdipFloatToPVSS:public CdipToPVSSTypeConverter{
public:
	VariablePtr convert(const std::string & tag, DipData & data) const{
		DipFloat value;

		if (tag.length() == 0){
			value = data.extractFloat();
		} else {
			value = data.extractFloat(const_cast<char *>(tag.c_str()));
		}
	
		return new FloatVar(value);  
	}	
};



/// Maps to the PVSS float type (Note DipDouble is 64bit, PVSSfloat is 32 bit)
class CdipDoubleToPVSS:public CdipToPVSSTypeConverter{
public:
	VariablePtr convert(const std::string & tag, DipData & data) const{
		DipDouble value;

		if (tag.length() == 0){
			value = data.extractDouble();
		} else {
			value = data.extractDouble(const_cast<char *>(tag.c_str()));
		}
	
		return new FloatVar(value);  
	}	
};



/// Maps to PVSS  string type
class CdipStringToPVSS:public CdipToPVSSTypeConverter{
public:
	VariablePtr convert(const std::string & tag, DipData & data) const{
		const char * value;

		if (tag.length() == 0){
			value = data.extractCString();
		} else {
			value = data.extractCString(const_cast<char *>(tag.c_str()));
		}
	
		return new TextVar(value);  
	}	
};



/// Maps to the PVSS dyn_bool type
class CdipBoolArrayToPVSS:public CdipToPVSSTypeConverter{
public:
	VariablePtr convert(const std::string & tag, DipData & data) const{
		const DipBool * value;

		int noElements;
		if (tag.length() == 0){
			value = data.extractBoolArray(noElements);
		} else {
			value = data.extractBoolArray(noElements, const_cast<char *>(tag.c_str()));
		}
	
		DynVar * array = new DynVar(BIT_VAR);
		for (int i = 0; i < noElements; i++){
			BitVar element(value[i]);
			array->append(element);
		}

		return array;
	}	
};

/// Maps to the PVSS dyn_bool type
class CdipBoolArrayToPVSSInt:public CdipToPVSSTypeConverter{
public:
	VariablePtr convert(const std::string & tag, DipData & data) const{
		const DipBool * value;

		int noElements;
		if (tag.length() == 0){
			value = data.extractBoolArray(noElements);
		} else {
			value = data.extractBoolArray(noElements, const_cast<char *>(tag.c_str()));
		}
	
		DynVar * array = new DynVar(INTEGER_VAR);
		for (int i = 0; i < noElements; i++){
			IntegerVar element(value[i]? 1 : 0);
			array->append(element);
		}

		return array;
	}	
};


/// Maps to the PVSS dyn_bit32 type
class CdipByteArrayToPVSS:public CdipToPVSSTypeConverter{
public:
	VariablePtr convert(const std::string & tag, DipData & data) const{
		const DipByte * value;

		int noElements;
		if (tag.length() == 0){
			value = data.extractByteArray(noElements);
		} else {
			value = data.extractByteArray(noElements, const_cast<char *>(tag.c_str()));
		}
	
		DynVar * array = new DynVar(BIT32_VAR);
		for (int i = 0; i < noElements; i++){
			Bit32Var element(value[i]);
			array->append(element);
		}

		return array;
	}	
};


/// Maps to the PVSS dyn_int type
class CdipShortArrayToPVSS:public CdipToPVSSTypeConverter{
public:
	VariablePtr convert(const std::string & tag, DipData & data) const{
		const DipShort * value;

		int noElements;
		if (tag.length() == 0){
			value = data.extractShortArray(noElements);
		} else {
			value = data.extractShortArray(noElements, const_cast<char *>(tag.c_str()));
		}
	
		DynVar * array = new DynVar(INTEGER_VAR);
		for (int i = 0; i < noElements; i++){
			IntegerVar element(value[i]);
			array->append(element);
		}

		return array;
	}	
};


/// Maps to the PVSS dyn_int type
class CdipIntArrayToPVSS:public CdipToPVSSTypeConverter{
public:
	VariablePtr convert(const std::string & tag, DipData & data) const{
		const DipInt * value;

		int noElements;
		if (tag.length() == 0){
			value = data.extractIntArray(noElements);
		} else {
			value = data.extractIntArray(noElements, const_cast<char *>(tag.c_str()));
		}
	
		DynVar * array = new DynVar(INTEGER_VAR);
		for (int i = 0; i < noElements; i++){
			IntegerVar element(value[i]);
			array->append(element);
		}

		return array;
	}	
};


/// Maps to the PVSS dyn_int type (NOTE DIPLong is 64bit, PVSSint is 32 bits)
class CdipLongArrayToPVSS:public CdipToPVSSTypeConverter{
public:
	VariablePtr convert(const std::string & tag, DipData & data) const{
		const DipLong * value;

		int noElements;
		if (tag.length() == 0){
			value = data.extractLongArray(noElements);
		} else {
			value = data.extractLongArray(noElements, const_cast<char *>(tag.c_str()));
		}
	
		DynVar * array = new DynVar(INTEGER_VAR);
		for (int i = 0; i < noElements; i++){
			IntegerVar element(value[i]);
			array->append(element);
		}

		return array;
	}	
};


/// Maps to the PVSS dyn_float type
class CdipFloatArrayToPVSS:public CdipToPVSSTypeConverter{
public:
	VariablePtr convert(const std::string & tag, DipData & data) const{
		const DipFloat * value;

		int noElements;
		if (tag.length() == 0){
			value = data.extractFloatArray(noElements);
		} else {
			value = data.extractFloatArray(noElements, const_cast<char *>(tag.c_str()));
		}
	
		DynVar * array = new DynVar(FLOAT_VAR);
		for (int i = 0; i < noElements; i++){
			FloatVar element(value[i]);
			array->append(element);
		}

		return array;
	}	
};



/// Maps to the PVSS dyn_float type (Note DipDouble is 64bit, PVSSfloat is 32 bit)
class CdipDoubleArrayToPVSS:public CdipToPVSSTypeConverter{
public:
	VariablePtr convert(const std::string & tag, DipData & data) const{
		const DipDouble * value;

		int noElements;
		if (tag.length() == 0){
			value = data.extractDoubleArray(noElements);
		} else {
			value = data.extractDoubleArray(noElements, const_cast<char *>(tag.c_str()));
		}
	
		DynVar * array = new DynVar(FLOAT_VAR);
		for (int i = 0; i < noElements; i++){
			FloatVar element(value[i]);
			array->append(element);
		}

		return array;
	}
};



/// Maps to PVSS  dyn_string type
class CdipStringArrayToPVSS:public CdipToPVSSTypeConverter{
public:
	VariablePtr convert(const std::string & tag, DipData & data) const{
		const char ** value;

		int noElements;
		if (tag.length() == 0){
			value = data.extractCStringArray(noElements);
		} else {
			value = data.extractCStringArray(noElements, const_cast<char *>(tag.c_str()));
		}
	
		DynVar * array = new DynVar(TEXT_VAR);
		for (int i = 0; i < noElements; i++){
			TextVar element(value[i]);
			array->append(element);
		}

		return array;
	}

};





/**
			
					PVSS to DIP type converters

*/





class CpvssBoolToDip:public CpvssToDipTypeConverter{
public:
	void convert(DipData &dipData, VariablePtr DPEValue, const CharString & tagName) const{
		BitVar * val = (BitVar *)DPEValue;
		if (!val){
			throw BadTypeConversionException(BadTypeConversionException::BADTYPE);
		}
		if (tagName.len() == 0){
			dipData.insert((DipBool)val->getValue());
		} else {
			dipData.insert((DipBool)val->getValue(), tagName); 
		}
	}
};



/// Maps from PVSS char (byte) to DipString
class CpvssCharToDip:public CpvssToDipTypeConverter{
public:
	void convert(DipData &dipData, VariablePtr DPEValue, const CharString & tagName) const{
		CharVar * val = (CharVar *)DPEValue;
		if (!val){
			throw BadTypeConversionException(BadTypeConversionException::BADTYPE);
		}

		char stringifiedChar[2]={0,0};
		stringifiedChar[0] = val->getValue();
		if (tagName.len() == 0){
			dipData.insert(stringifiedChar);
		} else {
			dipData.insert(stringifiedChar, tagName); 
		}
	}
};



/// There is no long or short in PVSS - hence their converters do not appear here
class CpvssIntToDip:public CpvssToDipTypeConverter{
public:
	void convert(DipData &dipData, VariablePtr DPEValue, const CharString & tagName) const{
		IntegerVar * val = (IntegerVar *)DPEValue;
		if (!val){
			throw BadTypeConversionException(BadTypeConversionException::BADTYPE);
		}
		if (tagName.len() == 0){
			dipData.insert((DipInt)val->getValue());
		} else {
			dipData.insert((DipInt)val->getValue(), tagName); 
		}
	}
};



/// Maps to DIP int
class CpvssBit32ToDip:public CpvssToDipTypeConverter{
public:
	void convert(DipData &dipData, VariablePtr DPEValue, const CharString & tagName) const{
		Bit32Var * val = (Bit32Var *)DPEValue;
		if (!val){
			throw BadTypeConversionException(BadTypeConversionException::BADTYPE);
		}
		if (tagName.len() == 0){
			dipData.insert((DipInt)val->getValue());
		} else {
			dipData.insert((DipInt)val->getValue(), tagName); 
		}
	}
};



/// Maps to DIP long
class CpvssUnsignedToDip:public CpvssToDipTypeConverter{
public:
	void convert(DipData &dipData, VariablePtr DPEValue, const CharString & tagName) const{
		UIntegerVar * val = (UIntegerVar *)DPEValue;
		if (!val){
			throw BadTypeConversionException(BadTypeConversionException::BADTYPE);
		}
		if (tagName.len() == 0){
			dipData.insert((DipLong)val->getValue());
		} else {
			dipData.insert((DipLong)val->getValue(), tagName); 
		}
	}
};



/// There is no Double in PVSS - hence the converter does not appear here
class CpvssFloatToDip:public CpvssToDipTypeConverter{
public:
	void convert(DipData &dipData, VariablePtr DPEValue, const CharString & tagName) const{
		FloatVar * val = (FloatVar *)DPEValue;
		if (!val){
			throw BadTypeConversionException(BadTypeConversionException::BADTYPE);
		}
		if (tagName.len() == 0){
			dipData.insert((DipFloat)val->getValue());
		} else {
			dipData.insert((DipFloat)val->getValue(), tagName); 
		}
	}
};




class CpvssStringToDip:public CpvssToDipTypeConverter{
public:
	void convert(DipData &dipData, VariablePtr DPEValue, const CharString & tagName) const{
		TextVar * val = (TextVar *)DPEValue;
		if (!val){
			throw BadTypeConversionException(BadTypeConversionException::BADTYPE);
		}
		if (tagName.len() == 0){
			dipData.insert((char *)val->getValue());
		} else {
			dipData.insert((char *)val->getValue(), tagName); 
		}
	}
};






class CpvssBoolArrayToDip:public CpvssToDipTypeConverter{
public:
	void convert(DipData &dipData, VariablePtr DPEValue, const CharString & tagName) const{
		DynVar * vals = (DynVar *)DPEValue;
		if (!vals){
			throw BadTypeConversionException(BadTypeConversionException::BADTYPE);
		}

		if (vals->isA() != DYNBIT_VAR){
			throw BadTypeConversionException(BadTypeConversionException::BADTYPE);
		}
		unsigned int size = vals->getArrayLength();
		if (size == 0){
			return;
		}
		DipBool* array = new DipBool[size];
		for (unsigned int i = 0; i < size; i++){
			Variable * value =  vals->getAt(i);
			array[i] = (DipBool)((BitVar *)(value))->getValue();
		}
		if (tagName.len() == 0){
			dipData.insert(array,size);
		} else {
			dipData.insert(array, size, tagName); 
		}

		delete []array;
	}
};



/// Maps to DIP String array
class CpvssCharArrayToDip:public CpvssToDipTypeConverter{
public:
	void convert(DipData &dipData, VariablePtr DPEValue, const CharString & tagName) const{
		DynVar * vals = (DynVar *)(DPEValue);
		if (!vals){
			throw BadTypeConversionException(BadTypeConversionException::BADTYPE);
		}

		if (vals->isA() != DYNCHAR_VAR){
			throw BadTypeConversionException(BadTypeConversionException::BADTYPE);
		}
		unsigned int size = vals->getArrayLength();
		if (size == 0){
			return;
		}
		std::string *array = new std::string[size];
	
		for (unsigned int i = 0; i < size; i++){
			Variable * value =  vals->getAt(i);
			array[i] = ((CharVar *)(value))->getValue();
		}	
		if (tagName.len() == 0){
			dipData.insert(array, size);
		} else {
			dipData.insert(array, size, tagName); 
		}

		delete []array;
	}
};




/// There is no long or short in PVSS - hence their converters do not appear here
class CpvssIntArrayToDip:public CpvssToDipTypeConverter{
public:
		void convert(DipData &dipData, VariablePtr DPEValue, const CharString & tagName) const{
		DynVar * vals = (DynVar *)(DPEValue);
		if (!vals){
			throw BadTypeConversionException(BadTypeConversionException::BADTYPE);
		}

		if (vals->isA() != DYNINTEGER_VAR){
			throw BadTypeConversionException(BadTypeConversionException::BADTYPE);
		}
		unsigned int size = vals->getArrayLength();
		if (size == 0){
			return;
		}
		DipInt* array = new DipInt[size];
		for (unsigned int i = 0; i < size; i++){
			Variable * value =  vals->getAt(i);
			array[i] = (DipInt)((IntegerVar *)(value))->getValue();
		}
		if (tagName.len() == 0){
			dipData.insert(array, size);
		} else {
			dipData.insert(array, size, tagName); 
		}

		delete []array;
	}
};



/// Mapping int DipInt array
class CpvssBit32ArrayToDip:public CpvssToDipTypeConverter{
public:
		void convert(DipData &dipData, VariablePtr DPEValue, const CharString & tagName) const{
		DynVar * vals = (DynVar *)(DPEValue);
		if (!vals){
			throw BadTypeConversionException(BadTypeConversionException::BADTYPE);
		}

		if (vals->isA() != DYNBIT32_VAR){
			throw BadTypeConversionException(BadTypeConversionException::BADTYPE);
		}
		unsigned int size = vals->getArrayLength();
		if (size == 0){
			return;
		}
		DipInt* array = new DipInt[size];
		for (unsigned int i = 0; i < size; i++){
			Variable * value =  vals->getAt(i);
			array[i] = (DipInt)((Bit32Var *)(value))->getValue();
		}
		if (tagName.len() == 0){
			dipData.insert(array, size);
		} else {
			dipData.insert(array, size, tagName); 
		}

		delete []array;
	}
};



/// Mapping int DipInt array
class CpvssUnsignedArrayToDip:public CpvssToDipTypeConverter{
public:
		void convert(DipData &dipData, VariablePtr DPEValue, const CharString & tagName) const{
		DynVar * vals = (DynVar *)(DPEValue);
		if (!vals){
			throw BadTypeConversionException(BadTypeConversionException::BADTYPE);
		}

		if (vals->isA() != DYNUINTEGER_VAR){
			throw BadTypeConversionException(BadTypeConversionException::BADTYPE);
		}
		unsigned int size = vals->getArrayLength();
		if (size == 0){
			return;
		}
		DipLong* array = new DipLong[size];
		for (unsigned int i = 0; i < size; i++){
			Variable * value =  vals->getAt(i);
			array[i] = (DipLong)((UIntegerVar *)(value))->getValue();
		}
		if (tagName.len() == 0){
			dipData.insert(array, size);
		} else {
			dipData.insert(array, size, tagName); 
		}

		delete []array;
	}
};







/// There is no Double in PVSS - hence the converter does not appear here
class CpvssFloatArrayToDip:public CpvssToDipTypeConverter{
public:
	void convert(DipData &dipData, VariablePtr DPEValue, const CharString & tagName) const{
		DynVar * vals = (DynVar *)(DPEValue);
		if (!vals){
			throw BadTypeConversionException(BadTypeConversionException::BADTYPE);
		}

		if (vals->isA() != DYNFLOAT_VAR){
			throw BadTypeConversionException(BadTypeConversionException::BADTYPE);
		}
		unsigned int size = vals->getArrayLength();
		if (size == 0){
			return;
		}
		DipFloat* array = new DipFloat[size];
		for (unsigned int i = 0; i < size; i++){
			Variable * value =  vals->getAt(i);
			array[i] = (DipFloat)((FloatVar *)(value))->getValue();
		}
		if (tagName.len() == 0){
			dipData.insert(array, size);
		} else {
			dipData.insert(array, size, tagName); 
		}

		delete []array;
	}
};




class CpvssStringArrayToDip:public CpvssToDipTypeConverter{
public:
	void convert(DipData &dipData, VariablePtr DPEValue, const CharString & tagName) const{
		DynVar * vals = (DynVar *)(DPEValue);
		if (!vals){
			throw BadTypeConversionException(BadTypeConversionException::BADTYPE);
		}

		if (vals->isA() != DYNTEXT_VAR){
			throw BadTypeConversionException(BadTypeConversionException::BADTYPE);
		}
		unsigned int size = vals->getArrayLength();
		if (size == 0){
			return;
		}
		const char ** array = new const char*[size];
		for (unsigned int i = 0; i < size; i++){
			Variable * value =  vals->getAt(i);
			array[i] = ((TextVar *)(value))->getValue();
		}
		if (tagName.len() == 0){
			dipData.insert(array, size);
		} else {
			dipData.insert(array, size, tagName); 
		}

		delete []array;
	}
};






























TConv::TConv(const int dipTypeID, const int dpeTypeID, const CdipToPVSSTypeConverter & converterObj)
:DIPtypeID(dipTypeID), DPEtypeID(dpeTypeID), converter(converterObj){
}




bool TConv::willConvert(const int dipType, const int dpeType) const{
	return ((dipType == DIPtypeID) && (dpeType == DPEtypeID));
}



int TConv::convertDIPToPVSSQuality(int dipQuality){
	int pvssQuality = 0;

	switch (dipQuality){
	case DIP_QUALITY_UNINITIALIZED:
	case DIP_QUALITY_BAD:pvssQuality = 0; break;
	case DIP_QUALITY_GOOD:pvssQuality = 3; break;
	case DIP_QUALITY_UNCERTAIN:pvssQuality = 1; break;
	default:
		throw BadTypeConversionException(BadTypeConversionException::UNSUPPORTEDTYPE);
	}; 

	return pvssQuality;
}





/*
Instantiate converter objects to be used to the conversion map
*/
static CdipBoolToPVSS		dipBoolToPVSSConverter;
static CdipBoolToPVSSInt	dipBoolToPVSSIntConverter;
static CdipByteToPVSS		dipByteToPVSSConverter;
static CdipShortToPVSS		dipShortToPVSSConverter;
static CdipIntToPVSS		dipIntToPVSSConverter;
static CdipLongToPVSS		dipLongToPVSSConverter;
static CdipFloatToPVSS		dipFloatToPVSSConverter;
static CdipDoubleToPVSS		dipDoubleToPVSSConverter;
static CdipStringToPVSS     dipStringToPVSSConverter;
static CdipBoolArrayToPVSS	dipBoolArrayToPVSSConverter;
static CdipBoolArrayToPVSSInt	dipBoolArrayToPVSSIntConverter;
static CdipByteArrayToPVSS	dipByteArrayToPVSSConverter;
static CdipShortArrayToPVSS	dipShortArrayToPVSSConverter;
static CdipIntArrayToPVSS	dipIntArrayToPVSSConverter;
static CdipLongArrayToPVSS	dipLongArrayToPVSSConverter;
static CdipFloatArrayToPVSS	dipFloatArrayToPVSSConverter;
static CdipDoubleArrayToPVSS dipDoubleArrayToPVSSConverter;
static CdipStringArrayToPVSS dipStringArrayToPVSSConverter;


static CpvssBoolToDip		pvssBoolToDipConverter;
static CpvssCharToDip		pvssCharToDipConverter;
static CpvssIntToDip		pvssIntToDipConverter;
static CpvssBit32ToDip		pvssBit32ToDipConverter;
static CpvssUnsignedToDip	pvssUnsignedToDipConverter;
static CpvssFloatToDip		pvssFloatToDipConverter;
static CpvssStringToDip		pvssStringToDipConverter;
static CpvssBoolArrayToDip	pvssBoolArrayToDipConverter;
static CpvssCharArrayToDip	pvssCharArrayToDipConverter;
static CpvssIntArrayToDip	pvssIntArrayToDipConverter;
static CpvssBit32ArrayToDip	pvssBit32ArrayToDipConverter;
static CpvssUnsignedArrayToDip	pvssUnsignedArrayToDipConverter;
static CpvssFloatArrayToDip	pvssFloatArrayToDipConverter;
static CpvssStringArrayToDip pvssStringArrayToDipConverter;





// static decl.
std::map<int, TConv *>					 TMap::dipToPvsstypeConverterList;
std::map<int, CpvssToDipTypeConverter *> TMap::pvssToDipTypeConverterMap;

std::map<int, int>						 TMap::implicitDipToDpeType;


TMap::TMap(){
	if (dipToPvsstypeConverterList.size() == 0){

        implicitDipToDpeType[TYPE_BOOLEAN] = DPELEMENT_BIT;
		implicitDipToDpeType[TYPE_BYTE] = DPELEMENT_32BIT;
		implicitDipToDpeType[TYPE_SHORT] = DPELEMENT_INT;
		implicitDipToDpeType[TYPE_INT] = DPELEMENT_INT;
		implicitDipToDpeType[TYPE_LONG] = DPELEMENT_INT;
		implicitDipToDpeType[TYPE_FLOAT] = DPELEMENT_FLOAT;
		implicitDipToDpeType[TYPE_DOUBLE] = DPELEMENT_FLOAT;
		implicitDipToDpeType[TYPE_STRING] = DPELEMENT_TEXT;
		implicitDipToDpeType[TYPE_BOOLEAN_ARRAY] = DPELEMENT_DYNBIT;
		implicitDipToDpeType[TYPE_BYTE_ARRAY] = DPELEMENT_DYN32BIT;
		implicitDipToDpeType[TYPE_SHORT_ARRAY] = DPELEMENT_DYNINT;
		implicitDipToDpeType[TYPE_INT_ARRAY] = DPELEMENT_DYNINT;
		implicitDipToDpeType[TYPE_LONG_ARRAY] = DPELEMENT_DYNINT;
		implicitDipToDpeType[TYPE_DOUBLE_ARRAY] = DPELEMENT_DYNFLOAT;
		implicitDipToDpeType[TYPE_STRING_ARRAY] = DPELEMENT_DYNTEXT;

		// set up DIP to PVSS type converter
		//																					DIP type			DPE type			converter
		dipToPvsstypeConverterList[TYPE_BOOLEAN | (DPELEMENT_BIT * 1000)]			= new TConv(TYPE_BOOLEAN,		DPELEMENT_BIT,		dipBoolToPVSSConverter);
		dipToPvsstypeConverterList[TYPE_BOOLEAN | (DPELEMENT_INT * 1000)]			= new TConv(TYPE_BOOLEAN,		DPELEMENT_INT,		dipBoolToPVSSIntConverter);
		dipToPvsstypeConverterList[TYPE_BYTE | (DPELEMENT_32BIT * 1000)]			= new TConv(TYPE_BYTE,			DPELEMENT_32BIT,	dipByteToPVSSConverter);
		dipToPvsstypeConverterList[TYPE_SHORT | (DPELEMENT_INT * 1000)]			= new TConv(TYPE_SHORT,			DPELEMENT_INT,		dipShortToPVSSConverter);
		dipToPvsstypeConverterList[TYPE_INT | (DPELEMENT_INT * 1000)]				= new TConv(TYPE_INT,			DPELEMENT_INT,		dipIntToPVSSConverter);
		dipToPvsstypeConverterList[TYPE_LONG | (DPELEMENT_INT * 1000)]				= new TConv(TYPE_LONG,			DPELEMENT_INT,		dipLongToPVSSConverter);
		dipToPvsstypeConverterList[TYPE_FLOAT | (DPELEMENT_FLOAT * 1000)]			= new TConv(TYPE_FLOAT,			DPELEMENT_FLOAT,	dipFloatToPVSSConverter);
		dipToPvsstypeConverterList[TYPE_DOUBLE | (DPELEMENT_FLOAT * 1000)]			= new TConv(TYPE_DOUBLE,		DPELEMENT_FLOAT,	dipDoubleToPVSSConverter);
		dipToPvsstypeConverterList[TYPE_STRING | (DPELEMENT_TEXT * 1000)]			= new TConv(TYPE_STRING,		DPELEMENT_TEXT,		dipStringToPVSSConverter);
		dipToPvsstypeConverterList[TYPE_BOOLEAN_ARRAY | (DPELEMENT_DYNBIT * 1000)]	= new TConv(TYPE_BOOLEAN_ARRAY,	DPELEMENT_DYNBIT,	dipBoolArrayToPVSSConverter);
		dipToPvsstypeConverterList[TYPE_BOOLEAN_ARRAY | (DPELEMENT_DYNINT * 1000)]	= new TConv(TYPE_BOOLEAN_ARRAY,	DPELEMENT_DYNINT,	dipBoolArrayToPVSSIntConverter);
		dipToPvsstypeConverterList[TYPE_BYTE_ARRAY | (DPELEMENT_DYN32BIT * 1000)]	= new TConv(TYPE_BYTE_ARRAY,	DPELEMENT_DYN32BIT, dipByteArrayToPVSSConverter);
		dipToPvsstypeConverterList[TYPE_SHORT_ARRAY | (DPELEMENT_DYNINT * 1000)]	= new TConv(TYPE_SHORT_ARRAY,	DPELEMENT_DYNINT,	dipShortArrayToPVSSConverter);
		dipToPvsstypeConverterList[TYPE_INT_ARRAY | (DPELEMENT_DYNINT * 1000)]		= new TConv(TYPE_INT_ARRAY,		DPELEMENT_DYNINT,	dipIntArrayToPVSSConverter);
		dipToPvsstypeConverterList[TYPE_LONG_ARRAY | (DPELEMENT_DYNINT * 1000)]	= new TConv(TYPE_LONG_ARRAY,	DPELEMENT_DYNINT,	dipLongArrayToPVSSConverter);
		dipToPvsstypeConverterList[TYPE_FLOAT_ARRAY | (DPELEMENT_DYNFLOAT * 1000)]	= new TConv(TYPE_FLOAT_ARRAY,	DPELEMENT_DYNFLOAT,	dipFloatArrayToPVSSConverter);
		dipToPvsstypeConverterList[TYPE_DOUBLE_ARRAY | (DPELEMENT_DYNFLOAT * 1000)]= new TConv(TYPE_DOUBLE_ARRAY,	DPELEMENT_DYNFLOAT,	dipDoubleArrayToPVSSConverter);
		dipToPvsstypeConverterList[TYPE_STRING_ARRAY | (DPELEMENT_DYNTEXT * 1000)]	= new TConv(TYPE_STRING_ARRAY,	DPELEMENT_DYNTEXT,	dipStringArrayToPVSSConverter);




		// set up PVSS to DIP type converter
		pvssToDipTypeConverterMap[DPELEMENT_BIT]	= & pvssBoolToDipConverter;
		pvssToDipTypeConverterMap[DPELEMENT_CHAR]	= & pvssCharToDipConverter;
		pvssToDipTypeConverterMap[DPELEMENT_INT]	= & pvssIntToDipConverter;
		pvssToDipTypeConverterMap[DPELEMENT_32BIT]	= & pvssBit32ToDipConverter;
		pvssToDipTypeConverterMap[DPELEMENT_UINT]	= & pvssUnsignedToDipConverter;
		pvssToDipTypeConverterMap[DPELEMENT_FLOAT]	= & pvssFloatToDipConverter;
		pvssToDipTypeConverterMap[DPELEMENT_TEXT]	= & pvssStringToDipConverter;
		pvssToDipTypeConverterMap[DPELEMENT_DYNBIT]		= & pvssBoolArrayToDipConverter;
		pvssToDipTypeConverterMap[DPELEMENT_DYNCHAR]	= & pvssCharArrayToDipConverter;
		pvssToDipTypeConverterMap[DPELEMENT_DYNINT]		= & pvssIntArrayToDipConverter;
		pvssToDipTypeConverterMap[DPELEMENT_DYN32BIT]	= & pvssBit32ArrayToDipConverter;
		pvssToDipTypeConverterMap[DPELEMENT_DYNUINT]	= & pvssUnsignedArrayToDipConverter;
		pvssToDipTypeConverterMap[DPELEMENT_DYNFLOAT]	= & pvssFloatArrayToDipConverter;
		pvssToDipTypeConverterMap[DPELEMENT_DYNTEXT]	= & pvssStringArrayToDipConverter;
	}
}



TConv *TMap::findDipToDpeConverterFor(const int dipType, const int dpeType){

	int lookupDpeType = dpeType;
	if(lookupDpeType == 0){
		lookupDpeType = implicitDipToDpeType[dipType];
	}

	TConv * typeConverter = dipToPvsstypeConverterList[dipType | (lookupDpeType * 1000)];
	if (typeConverter != NULL){
		return typeConverter;
	}

	throw BadTypeConversionException(BadTypeConversionException::UNSUPPORTEDTYPE);
	return NULL;
}



//TConv *TMap::findDipToDpeConverterFor(const int dipType, const int dpeType){
//	TConv * typeConverter = findDipToDpeConverterFor(dipType, dpeType);
//	if (typeConverter->willConvert(dipType, dpeType)){
//		return typeConverter;
//	}
//
//	throw BadTypeConversionException(BadTypeConversionException::UNSUPPORTEDTYPE);
//	return NULL;
//}



CpvssToDipTypeConverter * TMap::findDpeToDipConverterFor(const int dpeType){ // throw BadTypeConversionException
	std::map<int, CpvssToDipTypeConverter *>::iterator it =  pvssToDipTypeConverterMap.find(dpeType);
	if (it->first == false){
		throw BadTypeConversionException(BadTypeConversionException::UNSUPPORTEDTYPE);
	}

	return it->second;
}



// This is used to load the map with the conversion values.
static TMap mapInitialiser;

