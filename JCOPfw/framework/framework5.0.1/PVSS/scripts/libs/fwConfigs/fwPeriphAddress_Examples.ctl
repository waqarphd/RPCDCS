/**@file
*
* This file contains only documentation of the fwConfigs library set

*@par Creation Date
14/01/2013
* @author Marco Boccioli (EN/ICE-SCD)
*/

//! [Example: create OPC UA periphery address]
  dyn_anytype params;
  dyn_string exc;
  params[fwPeriphAddress_TYPE]=fwPeriphAddress_TYPE_OPCUACLIENT;
  params[fwPeriphAddress_DRIVER_NUMBER]=6;
  params[fwPeriphAddress_ROOT_NAME]="item1";//OPC UA item name
  params[fwPeriphAddress_DIRECTION]=DPATTR_ADDR_MODE_INPUT_SPONT;//input, spontaneous
  params[fwPeriphAddress_DATATYPE]=750; //default type convertion. see WinCC OA help on _address for more options  
  params[fwPeriphAddress_ACTIVE]=true;  //address active
  params[fwPeriphAddress_OPCUA_LOWLEVEL]=0;		  //no low level comparison	
  params[fwPeriphAddress_OPCUA_SERVER_NAME]="OPCUAConnection1";//OPC UA server							
  params[fwPeriphAddress_OPCUA_SUBSCRIPTION]="subscription2";//OPC UA subscription 
  params[fwPeriphAddress_OPCUA_KIND]="1";//OPC UA kind      
  params[fwPeriphAddress_OPCUA_VARIANT]="1";	 //OPC UA variant	       
  params[fwPeriphAddress_OPCUA_POLL_GROUP]="_poll_OPC_Test";//polling group name
  fwPeriphAddress_set("sys_1:testPerAddr.input", params,  exc);
//! [Example: create OPC UA periphery address]

///////////////////////////////////////////////////////////////////////////////////////

//! [Example: create S7 periphery address]
  dyn_anytype params;
  dyn_string exc;
  params[fwPeriphAddress_TYPE] = fwPeriphAddress_TYPE_S7;
  params[fwPeriphAddress_DRIVER_NUMBER] = 2;
  //element address on the PLC table:
  //Test_PLC is the S7 connection as defined on PVSS S7 driver parameterization panel
  params[fwPeriphAddress_ROOT_NAME] = "Test_PLC.DB81.DBD0F"; //address
  params[fwPeriphAddress_DIRECTION] = DPATTR_ADDR_MODE_INPUT_POLL; //read mode
  params[fwPeriphAddress_DATATYPE] = 700; //default type convertion. see PVSS help on _address for more options
  params[fwPeriphAddress_ACTIVE] = true;
  params[fwPeriphAddress_S7_LOWLEVEL] = false; //or true if you want timestamp to be updated only on value change
  params[fwPeriphAddress_S7_POLL_GROUP] = "_poll_PLC_Test"; //poll group name
  fwPeriphAddress_set("sys_1:testPerAddr.input", params,  exc);	
//! [Example: create S7 periphery address]

///////////////////////////////////////////////////////////////////////////////////////

//! [Example: get a periphery address configuration]
  string dpe = "system1:datapoint1.value"; 
  bool configExists, isActive; 
  dyn_anytype config; 
  dyn_string exceptionInfo;  
  fwPeriphAddress_get(dpe, configExists, config, isActive, exceptionInfo);
  DebugN("fwPeriphAddress_get:\n ", dpe, configExists, 
					config, isActive, exceptionInfo);
//! [Example: get a periphery address configuration]