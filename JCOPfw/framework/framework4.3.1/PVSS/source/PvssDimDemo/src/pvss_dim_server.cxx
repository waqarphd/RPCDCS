#include <dis.hxx>
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

class RecvCommand : public DimCommand
{
	void commandHandler()
	{
		cout << "Command " << getString() << " received" << endl;
	}
public :
	RecvCommand(char *name) : DimCommand(name,"C") {};
};

class RpcService : public DimRpc
{
	int val;

	void rpcHandler()
	{
		val = getInt();
		val++;
		setData(val);
	}
public:
	RpcService(char *name): DimRpc(name,"I","I") {val = 0;};
};

int main()
{
	COMPLEXDATA complexData;
	float simpleData;

	int index = 0;
	complexData.bitset = 0x1;
	complexData.boolval = 1;
	complexData.intval = index;
	complexData.floatval = (float)3.4;
	strcpy(complexData.stringval,"IDLE");

	DimService complexService("COMPLEX_SERVICE","I:1;C:1;I:1;F:1;C",
		(void *)&complexData, sizeof(complexData));

	simpleData = (float)1.23;

	DimService simpleService("SIMPLE_SERVICE", simpleData);
	simpleService.setQuality(1);

	RecvCommand recvCommand("SIMPLE_COMMAND");

	RpcService rpc("RPC");

	DimServer::start("PVSS_DIM_TEST");

	while(1)
	{
		sleep(5);
		index++;
		complexData.bitset <<= 1;
		complexData.boolval = index;
		complexData.intval = index;
		complexData.floatval = index * (float)1.1;
		sprintf(complexData.stringval,"State %d", index);
		complexService.updateService();

		simpleData += (float)1.1;
		simpleService.setQuality(complexData.bitset);
		simpleService.updateService();
	}
	return 0;
}
