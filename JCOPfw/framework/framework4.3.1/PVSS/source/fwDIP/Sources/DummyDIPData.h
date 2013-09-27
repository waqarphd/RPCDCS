#ifndef DUMMYDipData_H
#define DUMMYDipData_H
#include <string>
#include <map>
#include <iostream.h>
#include "TimeVar.hxx"

#define TYPE_INT 0
#define TYPE_LONG 1
#define TYPE_FLOAT 2
#define TYPE_INT_ARRAY 3

#define DIP_QUALITY_UNINITIALIZED  -1 // when data has never been initialized
#define  DIP_QUALITY_BAD  0 // when data unavailable or partly unavailable
#define  DIP_QUALITY_GOOD 1 // when data can definitely be trusted
#define  DIP_QUALITY_UNCERTAIN  2


class DIPException{};


class DipTimestamp{
public:
	__int64 getAsMillis() {
		TimeVar time;
		double t = time.getDouble();
		t *= 1000;
		__int64 msec = (__int64) t;
		return msec;
	}
};


class DipData{
	struct IntArray{
		int * data;
		int size;
		
		IntArray():data(NULL){};

		~IntArray(){
			if (data){
				delete [] data;
			}
		}

		void set(const int * arrayData, const int arraySize){
			size = arraySize;
			data = new int[arraySize];
			memcpy(data, arrayData, size * sizeof(int));
		}
	};

	union GenericType {
		int i; 
		long l; 
		float f;
		IntArray * ia;
	};

	struct DIPField{
		std::string tag;
		GenericType val;
		int type;

		DIPField(GenericType & v, const std::string & t, const int ty){
			tag = t;
			val = v;
			type = ty;
		}

		~DIPField(){
			if (type == TYPE_INT_ARRAY){
				delete val.ia;
			}
		}
	};

	typedef std::map<const std::string *, DIPField *> Tfield;
	Tfield fields;
	std::string def;
	int quality;

	const DIPField & getDataField(const std::string &tag) const{
	//	Tfield::const_iterator it = fields.find(&tag);
	//	if (it == fields.end()){
	//		throw DIPException();
	//	}

	//	return *(it->second);


	Tfield::const_iterator it = fields.begin();
	while (it != fields.end()){
		if (it->second->tag.compare(tag) == 0){
			return *it->second;
		}
		it++;
	}

		throw DIPException();
	}

	void setDataField(DIPField *data){
		std::pair<const std::string *, DIPField *> item(&(data->tag), data);
		fields.insert(item);
	}

public:
	DipData(){
		def = "__Default";
	}

	~DipData(){
		Tfield::iterator it = fields.begin();
		while (it != fields.end()){
			delete it->second;

			it++;
		}
	}

	int extractInt() const {
		return extractInt(def);
	}

	int extractInt(const std::string &tag) const {
		const DIPField & field = getDataField(tag);
		if (field.type != TYPE_INT){
			throw DIPException();
		}

		return field.val.i;
	}

	int * extractIntArray(int &size) const{
		return extractIntArray(def, size);
	}



	int * extractIntArray(const std::string & tag, int &size) const{
		const DIPField & field = getDataField(tag);
		if (field.type != TYPE_INT_ARRAY){
			throw DIPException();
		}
		
		size = field.val.ia->size;
		return field.val.ia->data;
	}

	long extractLong() const {
		return extractLong(def);
	}

	long extractLong(const std::string &tag) const {
		const DIPField & field = getDataField(tag);
		if (field.type != TYPE_LONG){
			throw DIPException();
		}

		return field.val.l;
	}
	
	float extractFloat() const {
		return extractFloat(def);
	}

	float extractFloat(const std::string &tag) const {
		const DIPField & field = getDataField(tag);
		if (field.type != TYPE_FLOAT){
			throw DIPException();
		}

		return field.val.f;
	}

	int getValueType() const {
		return getValueType(def);
	}

	int getValueType(const std::string &tag) const {
		const DIPField & field = getDataField(tag);

		return field.type;
	}



	void setInt(const int v){
		setInt(def, v);
	}

	void setInt(const std::string &tag, const int v){
		GenericType gt;

		gt.i = v;
		setDataField(new DIPField(gt, tag, TYPE_INT));
	}


	void setIntArray(const int * v, const int size){
		setIntArray(def, v, size);
	}

	void setIntArray(const std::string &tag, const int *v, const int size){
		GenericType gt;
		
		gt.ia = new IntArray();
		gt.ia->set(v, size);
		setDataField(new DIPField(gt, tag, TYPE_INT_ARRAY));
	}

	void setLong(const long v){
		setLong(def, v);
	}

	void setLong(const std::string &tag, const long v){
		GenericType gt;

		gt.l = v;
		setDataField(new DIPField(gt, tag, TYPE_LONG));
	}
	
	void setFloat(const float v){
		setFloat(def, v);
	}

	void setFloat(const std::string &tag, const float v){
		GenericType gt;

		gt.f = v;
		setDataField(new DIPField(gt, tag, TYPE_FLOAT));
	}

	DipTimestamp extractDipTime(){
		return DipTimestamp();
	}

	int extractDataQuality() const{
		return quality;
	}

	void setDataQuality(int q){
		quality = q;
	}

};




class DipSubscription{};

class DipSubscriptionListener {
public:
	virtual ~DipSubscriptionListener() { }

	virtual void handleMessage(DipSubscription* subscription, DipData& message) = 0;

	virtual void disconnected(DipSubscription* subscription, char *reason) = 0;

	virtual void connected(DipSubscription* subscription) = 0;
};


class Dip{
public:
	static DipSubscription * createDipSubscription(char *pubName, void *){
		return new DipSubscription();
	}

	static void destroyDipSubscription(DipSubscription *subscription){
		delete subscription;
	}

	static Dip * create(){
		return new Dip();
	}
};

#endif