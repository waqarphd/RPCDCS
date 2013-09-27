#include <dic.hxx>
#include <iostream>
#include <stdio.h>
using namespace std;

typedef struct{
	int bitset;
	char boolval;
	int intval;
	float floatval;
	char stringval[128];
}COMPLEXDATA;

class SimpleService : public DimInfo
{
	void infoHandler()
	{
		cout << "SimpleService : " << getFloat() << "\n" << endl;
	}
public :
	SimpleService(char *name) : DimInfo(name, -1.0) {};
};

class ComplexService : public DimInfo
{
	void infoHandler()
	{
		COMPLEXDATA *data;
		int i;
		unsigned mask = 0x80000000;

		data = (COMPLEXDATA *)getData();

		cout << "ComplexService : \n";
		cout << "\tbitset : ";
		for(i = 0; i < 32; i++)
		{
			if (data->bitset & mask)
				cout << "1";
			else 
				cout << "0";
			mask >>= 1;
		}
		cout << "\n";
		cout << "\tboolval : ";
		if(data->boolval)
				cout << "TRUE\n";
			else 
				cout << "FALSE\n";
		cout << "\tintval : "<< data->intval << "\n";
		cout << "\tfloatval : " << data->floatval << "\n";
		cout << "\tstringval : "<< data->stringval << "\n\n";
		cout << "Sending PVSS_SIMPLE_COMMAND : " << data->stringval << "\n" << endl;
		DimClient::sendCommand("PVSS_SIMPLE_COMMAND",data->stringval);
	}
public :
	ComplexService(char *name) : DimInfo(name, -1.0) {};
};

class RpcService : public DimRpcInfo
{
public:
	void rpcInfoHandler() {
		cout << "RPC Service : " << getInt() << "\n" << endl;
	}
	RpcService(char *name) :	DimRpcInfo(name, -1) {};
};


int main()
{
	int value = 0;
	SimpleService simple("PVSS_SIMPLE_SERVICE");
	ComplexService complex("PVSS_COMPLEX_SERVICE");
	RpcService rpc("PVSS_RPC");
	while(1)
	{
		rpc.setData(value);
		value++;
		sleep(5);
	}
	return 0;
}
