/**@file
*
* This file contains only documentation of the fwConfigs library set

*@par Creation Date
14/09/2011
* @author Marco Boccioli (EN/ICE-SCD)
*/

//! [Example: create Analog with utility function]
dyn_mixed alarmObject;
dyn_string exc; 

//create the alarm object
fwAlertConfig_objectCreateAnalog( 
		alarmObject, //the object that will contain the alarm settings
		makeDynString("too cold","normal","too hot"), //the text for the 3 ranges
		makeDynFloat(0,22,33), //the 3 ranges are separated by the values 22 and 33. The 1st value must always be 0.
		makeDynString("_fwWarningAck.","","_fwErrorAck."), //classes
		"", //alarm panel, if necessary		
		makeDynString(""), //$-params to pass to the alarm panel, if necessary
		"", //alarm help, if needed
		makeDynBool(0,1,0), //value included (1 means ">=", 0 means ">", 1st element ignored). Here: <= 22: too cold; 23..32: normal; >= 33: too hot
		exc); //exception info returned here

//set the alarm to the dpe                                        
fwAlertConfig_objectSet("testSingleAlarm_01.val", alarmObject, exc);   

//activate it
fwAlertConfig_activate("testSingleAlarm_01.val", exc);    
//! [Example: create Analog with utility function]

///////////////////////////////////////////////////////////////////////////////////////

//! [Example: create Analog without utility function]
dyn_mixed alarmObject;
dyn_dyn_anytype alarmLimits, alarmParams;
dyn_string exc; 

//initialize the alarm object with 3 ranges:    
fwAlertConfig_objectInitialize(alarmObject,3);

//extract the limits parameters from the alarm object:    
alarmLimits = alarmObject[fwAlertConfig_ALERT_LIMIT];

//set the limits parameters:

//text for each range of the alarm
alarmLimits[1][fwAlertConfig_ALERT_LIMIT_TEXT] = "cold";
alarmLimits[2][fwAlertConfig_ALERT_LIMIT_TEXT] = "ok";
alarmLimits[3][fwAlertConfig_ALERT_LIMIT_TEXT] = "hot";

//values delimiting the ranges of the alarm.
alarmLimits[1][fwAlertConfig_ALERT_LIMIT_VALUE] = 0; //1st element is always ignored 
alarmLimits[2][fwAlertConfig_ALERT_LIMIT_VALUE] = 22;
alarmLimits[3][fwAlertConfig_ALERT_LIMIT_VALUE] = 33;

//class for each range of the alarm
alarmLimits[1][fwAlertConfig_ALERT_LIMIT_CLASS] = "_fwWarningAck.";
alarmLimits[2][fwAlertConfig_ALERT_LIMIT_CLASS] = ""; //this is the ok range: no class
alarmLimits[3][fwAlertConfig_ALERT_LIMIT_CLASS] = "_fwErrorAck.";  

//store the limits parameters back to the alarm object:    
alarmObject[fwAlertConfig_ALERT_LIMIT] = alarmLimits;

//extract the general parameters of the object:    
alarmParams = alarmObject[fwAlertConfig_ALERT_PARAM];

//set the general parameters:

//set the type of the alarm
alarmParams[fwAlertConfig_ALERT_PARAM_TYPE][1] = DPCONFIG_ALERT_NONBINARYSIGNAL;

//store the general parameters back to the alarm object:    
alarmObject[fwAlertConfig_ALERT_PARAM] = alarmParams;

//set the object to the datapoint element:    
fwAlertConfig_objectSet("testSingleAlarm_01.val", alarmObject, exc);

//activate the alarm    
fwAlertConfig_activate("testSingleAlarm_01.val", exc);    	
//! [Example: create Analog without utility function]

///////////////////////////////////////////////////////////////////////////////////////

//! [Example: create Discrete with utility function]
dyn_mixed alarmObject;
dyn_string exc; 

//create the alarm object
fwAlertConfig_objectCreateDiscrete( 
		alarmObject, //the object that will contain the alarm settings
		makeDynString("ok","not valid","error"), //the text for the 3 ranges
		makeDynString("*","22,23","24-27"), //the 3 ranges must match these values (the 1st must be always the good one - *)
		makeDynString("","_fwWarningAck.","_fwErrorAck."), //classes (the 1st one must always be the good one)
		"", //alarm panel, if necessary
		makeDynString(""), //$-params to pass to the alarm panel, if necessary
		"", //alarm help, if needed
		false, //impulse alarm
		makeDynBool(0,0,0), //negation of the matching (0 means "=", 1 means "!=")
		"", //state bits that must also match for the alarm
		makeDynString("","",""), //state bits that must match for each range
		exc ); //exception info returned here
	
//set the alarm to the dpe                                        
fwAlertConfig_objectSet("testSingleAlarm_01.val", alarmObject, exc);   

//activate it
fwAlertConfig_activate("testSingleAlarm_01.val", exc);   
//! [Example: create Discrete with utility function]

///////////////////////////////////////////////////////////////////////////////////////

//! [Example: create Discrete without utility function]
dyn_mixed alarmObject;
dyn_dyn_anytype alarmLimits, alarmParams;
dyn_string exc; 

//initialize the alarm object with 3 ranges:    
fwAlertConfig_objectInitialize(alarmObject,3);

//extract the limits parameters of the alarm object:    
alarmLimits = alarmObject[fwAlertConfig_ALERT_LIMIT];

//set the limits parameters:

//text for each range of the alarm
alarmLimits[1][fwAlertConfig_ALERT_LIMIT_TEXT] = "system ok"; //1st element must always be the good range;
alarmLimits[2][fwAlertConfig_ALERT_LIMIT_TEXT] = "no connection";
alarmLimits[3][fwAlertConfig_ALERT_LIMIT_TEXT] = "system fault";

//value to be matched for each range of the alarm
alarmLimits[1][fwAlertConfig_ALERT_LIMIT_VALUE_MATCH] = "*"; //1st element must always be the good range;
alarmLimits[2][fwAlertConfig_ALERT_LIMIT_VALUE_MATCH] = "22, 23, 24";
alarmLimits[3][fwAlertConfig_ALERT_LIMIT_VALUE_MATCH] = "29-33";

//if value to be matched for each range of the alarm must be negated (this is an option)
alarmLimits[1][fwAlertConfig_ALERT_LIMIT_NEGATION] = false; //1st element must always be the good range;
alarmLimits[2][fwAlertConfig_ALERT_LIMIT_NEGATION] = true;
alarmLimits[3][fwAlertConfig_ALERT_LIMIT_NEGATION] = false;

//class for each range of the alarm
alarmLimits[1][fwAlertConfig_ALERT_LIMIT_CLASS] = ""; //1st element must always be the good range;
alarmLimits[2][fwAlertConfig_ALERT_LIMIT_CLASS] = "_fwWarningAck.";
alarmLimits[3][fwAlertConfig_ALERT_LIMIT_CLASS] = "_fwErrorAck.";

//pattern match of state bits (this is an option)
alarmLimits[1][fwAlertConfig_ALERT_LIMIT_STATE_BITS] = "11000000000000000000000001010101XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX"; //only the 1st element is considered. All the others are ignored;
alarmLimits[2][fwAlertConfig_ALERT_LIMIT_STATE_BITS] = "";
alarmLimits[3][fwAlertConfig_ALERT_LIMIT_STATE_BITS] = "";

//pattern match of state bits for each range (this is an option)
alarmLimits[1][fwAlertConfig_ALERT_LIMIT_LIMITS_STATE_BITS] = ""; //1st element must always have this value;
alarmLimits[2][fwAlertConfig_ALERT_LIMIT_LIMITS_STATE_BITS] = "0010xxxxxxxxx0101011000000001000XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX";
alarmLimits[3][fwAlertConfig_ALERT_LIMIT_LIMITS_STATE_BITS] = "001x00xxxxxxx010xx11011110000000XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX";

//store the limits parameters back to the alarm object:    
alarmObject[fwAlertConfig_ALERT_LIMIT] = alarmLimits;

//extract the general parameters of the alarm object:    
alarmParams = alarmObject[fwAlertConfig_ALERT_PARAM];

//set the general parameters:

//the alarm is a non-binary one
alarmParams[fwAlertConfig_ALERT_PARAM_TYPE][1] = DPCONFIG_ALERT_NONBINARYSIGNAL;
//the alarm is discrete
alarmParams[fwAlertConfig_ALERT_PARAM_DISCRETE][1] = true;

//store the general parameters back to the alarm object:    
alarmObject[fwAlertConfig_ALERT_PARAM] = alarmParams;

//set the object to the datapoint element:    
fwAlertConfig_objectSet("testSingleAlarm_01.val", alarmObject, exc);

//activate the alarm:    
fwAlertConfig_activate("testSingleAlarm_01.val", exc);    
//! [Example: create Discrete without utility function]	

///////////////////////////////////////////////////////////////////////////////////////

//! [Example: create Digital, false=ok, with utility function]
dyn_mixed alarmObject;
dyn_string exc; 

//initialize the alarm object with 2 ranges:    
fwAlertConfig_objectCreateDigital(
		alarmObject,
		makeDynString("ok","hot"),
		makeDynString("","_fwWarningAck."),
		"panel.pnl", //panel name - optional
		makeDynString("datapointForPanel1.value","datapointForPanel2.value"),//panel $params - optional
		"This is a help text", //help text - optional
		exc);

//set the object to the datapoint element:    
fwAlertConfig_objectSet("testSingleAlarm_01.trip", alarmObject, exc);

//activate the alarm:    
fwAlertConfig_activate("testSingleAlarm_01.trip", exc);    
//! [Example: create Digital, false=ok, with utility function]

///////////////////////////////////////////////////////////////////////////////////////

//! [Example: create Digital, true=ok, with utility function]
dyn_mixed alarmObject;
dyn_string exc; 

//initialize the alarm object with 2 ranges:    
fwAlertConfig_objectCreateDigital(
		alarmObject,
		makeDynString("cool","ok"),
		makeDynString("_fwWarningAck","."),
		"panel.pnl", //panel name - optional
		makeDynString("datapointForPanel1.value","datapointForPanel2.value"),//;panel $params - optional
		"This is a help text", //help text - optional
		exc);

//set the object to the datapoint element:    
fwAlertConfig_objectSet("testSingleAlarm_01.trip", alarmObject, exc);

//activate the alarm:    
fwAlertConfig_activate("testSingleAlarm_01.trip", exc);    
//! [Example: create Digital, true=ok, with utility function]

///////////////////////////////////////////////////////////////////////////////////////

//! [Example: create Digital, false=ok, without utility function]
dyn_mixed alarmObject;
dyn_dyn_anytype alarmLimits, alarmParams;
dyn_string exc; 

//initialize the alarm object with 2 ranges:    
fwAlertConfig_objectInitialize(alarmObject,2);

//extract the limits parameters from the alarm object:    
alarmLimits = alarmObject[fwAlertConfig_ALERT_LIMIT];

//set the limits parameters:

//text for each range of the alarm
alarmLimits[1][fwAlertConfig_ALERT_LIMIT_TEXT] = "ok";
alarmLimits[2][fwAlertConfig_ALERT_LIMIT_TEXT] = "error";

//class for each range of the alarm
alarmLimits[1][fwAlertConfig_ALERT_LIMIT_CLASS] = "";
alarmLimits[2][fwAlertConfig_ALERT_LIMIT_CLASS] = "_fwWarningAck.";

//store the limits parameters back to the object:    
alarmObject[fwAlertConfig_ALERT_LIMIT] = alarmLimits;

//extract the general parameters of the alarm object:    
alarmParams = alarmObject[fwAlertConfig_ALERT_PARAM];

//set the general parameters:   
alarmParams[fwAlertConfig_ALERT_PARAM_TYPE][1] = DPCONFIG_ALERT_BINARYSIGNAL;

//store the general parameters back to the alarm object:    
alarmObject[fwAlertConfig_ALERT_PARAM] = alarmParams;

//set the object to the datapoint element:    
fwAlertConfig_objectSet("testSingleAlarm_01.trip", alarmObject, exc);

//activate the alarm:    
fwAlertConfig_activate("testSingleAlarm_01.trip", exc);    
//! [Example: create Digital, false=ok, without utility function]

///////////////////////////////////////////////////////////////////////////////////////

//! [Example: create Digital, true=ok, without utility function]
dyn_mixed alarmObject;
dyn_dyn_anytype alarmLimits, alarmParams;
dyn_string exc; 

//initialize the alarm object with 2 ranges:    
fwAlertConfig_objectInitialize(alarmObject,2);

//extract the limits parameters of the object:   
alarmLimits = alarmObject[fwAlertConfig_ALERT_LIMIT];

//set the limits parameters:

//text for each range of the alarm
alarmLimits[1][fwAlertConfig_ALERT_LIMIT_TEXT] = "error";
alarmLimits[2][fwAlertConfig_ALERT_LIMIT_TEXT] = "ok";

//class for each range of the alarm
alarmLimits[1][fwAlertConfig_ALERT_LIMIT_CLASS] = "_fwWarningAck.";
alarmLimits[2][fwAlertConfig_ALERT_LIMIT_CLASS] = "";

//store the limits parameters back to the alarm object:    
alarmObject[fwAlertConfig_ALERT_LIMIT] = alarmLimits;

//extract the general parameters of the alarm object:    
alarmParams = alarmObject[fwAlertConfig_ALERT_PARAM];

//set the general parameters:    
alarmParams[fwAlertConfig_ALERT_PARAM_TYPE][1] = DPCONFIG_ALERT_BINARYSIGNAL;

//store the general parameters back to the alarm object:    
alarmObject[fwAlertConfig_ALERT_PARAM] = alarmParams;

//set the object to the datapoint element:   
fwAlertConfig_objectSet("testSingleAlarm_01.trip", alarmObject, exc);

//activate the alarm:    
fwAlertConfig_activate("testSingleAlarm_01.trip", exc);    
//! [Example: create Digital, true=ok, without utility function]

///////////////////////////////////////////////////////////////////////////////////////

//! [Example: create Summary with utility function]
dyn_mixed alarmObject;
dyn_dyn_anytype alarmLimits, alarmParams;
dyn_string exc; 

//create the params object:    
fwAlertConfig_objectCreateSummary(
		alarmObject, makeDynString("cool","hot"), 
		2, 
		makeDynString("",""),
		makeDynString("testSingleAlarm_0001.val","testSingleAlarm_0003.val","testSingleAlarm_0004.val","testSingleAlarm_0005.val"),
		"panel.pnl", //panel name - optional
		makeDynString("datapointForPanel1.value","datapointForPanel2.value"),//;panel $params - optional
		"This is a help text", //help text - optional
		exc);

//set the object to the datapoint element:    
fwAlertConfig_objectSet("testSingleAlarm_01.string", alarmObject, exc);    

//activate the alarm:    
fwAlertConfig_activate("testSingleAlarm_01.string", exc);    
//! [Example: create Summary with utility function]	

///////////////////////////////////////////////////////////////////////////////////////
//! [Example: create Summary without utility function]
dyn_mixed alarmObject;
dyn_dyn_anytype alarmLimits, alarmParams;
dyn_string exc; 

//initialize the params object (2 ranges for ummary alert):    
fwAlertConfig_objectInitialize( alarmObject,2);

//extract the limits parameters of the object:    
alarmLimits = alarmObject[fwAlertConfig_ALERT_LIMIT];

//set the limits parameters:    
alarmLimits[1][fwAlertConfig_ALERT_LIMIT_TEXT] = "on";
alarmLimits[2][fwAlertConfig_ALERT_LIMIT_TEXT] = "error";

alarmLimits[1][fwAlertConfig_ALERT_LIMIT_CLASS] = "";
alarmLimits[2][fwAlertConfig_ALERT_LIMIT_CLASS] = "";

//store the limits parameters back to the object:    
alarmObject[fwAlertConfig_ALERT_LIMIT] = alarmLimits;

//extract the general parameters of the object:   
alarmParams = alarmObject[fwAlertConfig_ALERT_PARAM];

//set the general parameters:    
alarmParams[fwAlertConfig_ALERT_PARAM_TYPE][1] = DPCONFIG_SUM_ALERT;
alarmParams[fwAlertConfig_ALERT_PARAM_SUM_DPE_LIST] = makeDynString("testSingleAlarm_0001.val","testSingleAlarm_0003.val","testSingleAlarm_0004.val");
alarmParams[fwAlertConfig_ALERT_PARAM_SUM_THRESHOLD][1] = 2;

//store the general parameters back to the object:    
alarmObject[fwAlertConfig_ALERT_PARAM] = alarmParams;

//set the object to the datapoint element:    
fwAlertConfig_objectSet("testSingleAlarm_01.string", alarmObject, exc);    

//activate the alarm:    
fwAlertConfig_activate("testSingleAlarm_01.string", exc);    
//! [Example: create Summary without utility function]	

///////////////////////////////////////////////////////////////////////////////////////

//! [Example: set 2 alarms without utility function]
dyn_dyn_anytype alarmLimits, alarmParams;
dyn_dyn_mixed alarmObject;
dyn_anytype alarms;
dyn_string exc, dpe;
int i;

//list of datapoint elements
dpe = makeDynString("dpe1","dpe2");
  
// alarm 1
i = 1;

//initialize alarm object  
fwAlertConfig_objectInitialize(alarmObject[i],3);

//extract limits array    
alarmLimits = alarmObject[i][2];

alarmLimits[1][fwAlertConfig_ALERT_LIMIT_TEXT] = "ok";
alarmLimits[2][fwAlertConfig_ALERT_LIMIT_TEXT] = "warm";
alarmLimits[3][fwAlertConfig_ALERT_LIMIT_TEXT] = "hot";

alarmLimits[1][fwAlertConfig_ALERT_LIMIT_VALUE] = 0;
alarmLimits[2][fwAlertConfig_ALERT_LIMIT_VALUE] = 11;
alarmLimits[3][fwAlertConfig_ALERT_LIMIT_VALUE] = 22;

alarmLimits[1][fwAlertConfig_ALERT_LIMIT_CLASS] = "";
alarmLimits[2][fwAlertConfig_ALERT_LIMIT_CLASS] = "_fwWarningAck.";
alarmLimits[3][fwAlertConfig_ALERT_LIMIT_CLASS] = "_fwErrorAck.";

//extract parameters array:    
alarmParams = alarmObject[i][1];

//set the type 
alarmParams[fwAlertConfig_ALERT_PARAM_TYPE][1] = DPCONFIG_ALERT_NONBINARYSIGNAL;

//put limits and parameters arrays to the object:   
alarmObject[i][1] = alarmParams;
alarmObject[i][2] = alarmLimits;

// alarm 2
i = 2;

//initialize alarm object  
fwAlertConfig_objectInitialize(alarmObject[i],3);

//extract limits array:    
alarmLimits = alarmObject[i][2];

alarmLimits[1][fwAlertConfig_ALERT_LIMIT_TEXT] = "ok";
alarmLimits[2][fwAlertConfig_ALERT_LIMIT_TEXT] = "high voltage";
alarmLimits[3][fwAlertConfig_ALERT_LIMIT_TEXT] = "voltage trip";

alarmLimits[1][fwAlertConfig_ALERT_LIMIT_VALUE] = 0;
alarmLimits[2][fwAlertConfig_ALERT_LIMIT_VALUE] = 1000;
alarmLimits[3][fwAlertConfig_ALERT_LIMIT_VALUE] = 1100;

alarmLimits[1][fwAlertConfig_ALERT_LIMIT_CLASS] = "";
alarmLimits[2][fwAlertConfig_ALERT_LIMIT_CLASS] = "_fwWarningAck.";
alarmLimits[3][fwAlertConfig_ALERT_LIMIT_CLASS] = "_fwErrorAck.";

//extract parameters array    
alarmParams = alarmObject[i][1];

//set the type 
alarmParams[fwAlertConfig_ALERT_PARAM_TYPE][1] = DPCONFIG_ALERT_NONBINARYSIGNAL;

//put limits and parameters arrays to the object:    
alarmObject[i][1] = alarmParams;
alarmObject[i][2] = alarmLimits;

//set the 2 alarms to the 2 dpes:
fwAlertConfig_objectSetMany(dpe,alarmObject, exc);
//activate the alerts
fwAlertConfig_activateMultiple(dpe, exc);     
//! [Example: set 2 alarms without utility function]

///////////////////////////////////////////////////////////////////////////////////////

//! [Example: set 4 alarms without utility function]
dyn_dyn_anytype alarmLimits, alarmParams;
dyn_dyn_mixed alarmObject;
dyn_anytype alarms;
dyn_string exc, dpe;

//list of datapoint elements
dpe = makeDynString("dpe1","dpe2","dpe3","dpe4");

//initialize alarm object  
fwAlertConfig_objectInitialize( alarmObject[1],3);

//extract limits array:    
alarmLimits = alarmObject[1][2];

alarmLimits[1][fwAlertConfig_ALERT_LIMIT_TEXT] = "ok";
alarmLimits[2][fwAlertConfig_ALERT_LIMIT_TEXT] = "warm";
alarmLimits[3][fwAlertConfig_ALERT_LIMIT_TEXT] = "hot";

alarmLimits[1][fwAlertConfig_ALERT_LIMIT_VALUE] = 0;
alarmLimits[2][fwAlertConfig_ALERT_LIMIT_VALUE] = 11;
alarmLimits[3][fwAlertConfig_ALERT_LIMIT_VALUE] = 22;

alarmLimits[1][fwAlertConfig_ALERT_LIMIT_CLASS] = "";
alarmLimits[2][fwAlertConfig_ALERT_LIMIT_CLASS] = "_fwWarningAck.";
alarmLimits[3][fwAlertConfig_ALERT_LIMIT_CLASS] = "_fwErrorAck.";

//extract parameters array:    
alarmParams = alarmObject[1][1];

//set the type 
alarmParams[fwAlertConfig_ALERT_PARAM_TYPE][1] = DPCONFIG_ALERT_NONBINARYSIGNAL;

//put limits and parameters arrays to the object:    
alarmObject[1][1] = alarmParams;
alarmObject[1][2] = alarmLimits;

//set the 4 dpes with the same alarm setting:
fwAlertConfig_objectSetMany(dpe,alarmObject, exc);
//activate the alerts
fwAlertConfig_activateMultiple(dpe, exc);   
//! [Example: set 4 alarms without utility function]

///////////////////////////////////////////////////////////////////////////////////////

//! [Example: set 4 alarms bit32 without utility function]
dyn_dyn_mixed alarmConfigObject;
dyn_string exc, dpe;
int i;

dyn_dyn_anytype alarmLimits, alarmParams;
dyn_dyn_mixed alarmObject;
dyn_anytype alarms;

//list of datapoint elements
dpe = makeDynString("dpe1","dpe2","dpe3","dpe4");

//initialize alarm object  
fwAlertConfig_objectInitialize(alarmObject,3);

//extract parameters array:    
alarmParams = alarmObject[1];

//extract limits array:    
alarmLimits = alarmObject[2];

//set the 4 alarm settings:
for(i=1 ; i<=(dynlen(dpe)) ; i++)
{
//set the texts (first text is always the normal range)
alarmLimits[1][fwAlertConfig_ALERT_LIMIT_TEXT] = "ok";
alarmLimits[2][fwAlertConfig_ALERT_LIMIT_TEXT] = "warning";
alarmLimits[3][fwAlertConfig_ALERT_LIMIT_TEXT] = "fault";

//set the pattern match (first pattern is always the normal range *)
alarmLimits[1][fwAlertConfig_ALERT_LIMIT_VALUE_MATCH] = "*";
alarmLimits[2][fwAlertConfig_ALERT_LIMIT_VALUE_MATCH] = "10010111101";
alarmLimits[3][fwAlertConfig_ALERT_LIMIT_VALUE_MATCH] = "10001011011,000110110101";

//set the class for each value match
alarmLimits[1][fwAlertConfig_ALERT_LIMIT_CLASS] = "";
alarmLimits[2][fwAlertConfig_ALERT_LIMIT_CLASS] = "_fwWarningAck.";
alarmLimits[3][fwAlertConfig_ALERT_LIMIT_CLASS] = "_fwErrorAck.";

//set the parameters common to the alarm
alarmParams[fwAlertConfig_ALERT_PARAM_TYPE][1] = DPCONFIG_ALERT_NONBINARYSIGNAL;
alarmParams[fwAlertConfig_ALERT_PARAM_DISCRETE][1] = true;
alarmParams[fwAlertConfig_ALERT_PARAM_RANGES][1] = 3;  

//put limits and parameters arrays to the object:    
alarmObject[i][1] = alarmParams;
alarmObject[i][2] = alarmLimits;
}
//set the 4 dpes with the 4 alarm settings:
fwAlertConfig_objectSetMany(dpe,alarmObject, exc);
//activate the alerts
fwAlertConfig_activateMultiple(dpe, exc);    
//! [Example: set 4 alarms bit32 without utility function]

///////////////////////////////////////////////////////////////////////////////////////

//! [Example: set 2 alarms with utility function]
dyn_mixed alarmObject;
dyn_mixed alarmObjects;
dyn_string exc, dpe;

//list of datapoint elements
dpe = makeDynString("dpe1.val","dpe2.val");
  
// alarm 1 
//set the alarm object  
fwAlertConfig_objectCreateAnalog(
		alarmObject, //the object that will contain the alarm settings
		makeDynString("too cold","normal","too hot"), //the text for the 3 ranges
		makeDynFloat(0,22,33), //the 3 ranges are separated by the values 22 and 33. The 1st value must always be 0.
		makeDynString("_fwWarningAck.","","_fwErrorAck."), //classes
		makeDynString(""), //$-params to pass to the alarm panel, if necessary
		"", //alarm help, if needed
		makeDynBool(0,1,0), //value included (1 means ">=", 0 means ">", 1st element ignored). Here: <= 22: too cold; 23..32: normal; >= 33: too hot
		exc); //exception info returned here

// store the config 1 in the array of objects
alarmObjects[1] = alarmObject;

// alarm 2
dynClear(alarmObject); 
//set the alarm object  
fwAlertConfig_objectCreateAnalog(
		alarmObject, //the object that will contain the alarm settings
		makeDynString("too cold","normal","too hot"), //the text for the 3 ranges
		makeDynFloat(0,44,56), //the 3 ranges
		makeDynString("_fwWarningAck.","","_fwErrorAck."), //classes
		makeDynString(""), //$-params to pass to the alarm panel, if necessary
		"", //alarm help, if needed
		makeDynBool(0,0,0), //value included 
		exc); //exception info returned here
		
// store the config 2 in the array of objects
alarmObjects[2] = alarmObject;

//set the 2 alarms to the 2 dpes:
fwAlertConfig_objectSetMany(dpe,alarmObjects, exc);
//activate the alerts
fwAlertConfig_activateMultiple(dpe, exc);     
//! [Example: set 2 alarms with utility function]

///////////////////////////////////////////////////////////////////////////////////////

//! [Example: set one alarm into 2 dpes with utility function]
dyn_mixed alarmObject;
dyn_mixed alarmObjects;
dyn_string exc, dpe;

//list of datapoint elements
dpe = makeDynString("dpe1.val","dpe2.val");
  
// alarm used for all the dpes
//set the alarm object  
fwAlertConfig_objectCreateAnalog(
		alarmObject, //the object that will contain the alarm settings
		makeDynString("too cold","normal","too hot"), //the text for the 3 ranges
		makeDynFloat(0,22,33), //the 3 ranges are separated by the values 22 and 33. The 1st value must always be 0.
		makeDynString("_fwWarningAck.","","_fwErrorAck."), //classes
		makeDynString(""), //$-params to pass to the alarm panel, if necessary
		"", //alarm help, if needed
		makeDynBool(0,1,0), //value included (1 means ">=", 0 means ">", 1st element ignored). Here: <= 22: too cold; 23..32: normal; >= 33: too hot
		exc); //exception info returned here

// store the config in the array of objects
alarmObjects[1] = alarmObject;

//set the same alarm to the 2 dpes:
fwAlertConfig_objectSetMany(dpe,alarmObjects, exc);
//activate the alerts
fwAlertConfig_activateMultiple(dpe, exc);     
//! [Example: set one alarm into 2 dpes with utility function]

///////////////////////////////////////////////////////////////////////////////////////

//! [Example: get an analog alarm from a dpe]
dyn_mixed alarmConfigObject;
dyn_string exc;
int alertType;
dyn_string alertTexts;
dyn_float alertLimits;
dyn_string alertClasses;
string alertPanel;
dyn_string alertPanelParameters;
string alertHelp;
dyn_bool limitsIncluded;
bool isActive;

//get the alarm and store it in the configuration object
fwAlertConfig_objectGet("testSingleAlarm_01.val",alarmConfigObject, exc);

//verfy that the alarm is analog
fwAlertConfig_objectExtractType(alarmConfigObject, alertType, isActive, exc);

//extract the parameters
if(alertType==DPCONFIG_ALERT_NONBINARYSIGNAL)
	fwAlertConfig_objectExtractAnalog(
			alarmConfigObject, 
			alertType,
			alertTexts,
			alertLimits,
			alertClasses,
			alertPanel,
			alertPanelParameters,
			alertHelp,
			limitsIncluded,
			isActive,
			exc);
//! [Example: get an analog alarm from a dpe]				
			
///////////////////////////////////////////////////////////////////////////////////////

//! [Example: get alarms from two dpes]				
dyn_string exc;
dyn_string dpe; 
dyn_mixed alertObjects;
int i;  
dyn_string exc;
int alertType;
dyn_string alertTexts;
dyn_float alertLimits;
dyn_string alertClasses;
string alertPanel;
dyn_string alertPanelParameters;
string alertHelp;
dyn_bool limitsIncluded;
bool isActive;

//list of dpes
makeDynString("sys1:dpe1.val","sys1:dpe2.val");

fwAlertConfig_objectGetMany(dpe, alertObjects, exc);

for(i=1 ; i<=dynlen(dpe) ; i++)
{
	//verfy that the alarm is analog
	fwAlertConfig_objectExtractType(alarmConfigObject, alertType, isActive, exc);

	//extract the parameters
	if(alertType==DPCONFIG_ALERT_NONBINARYSIGNAL)
		fwAlertConfig_objectExtractAnalog(
				alarmConfigObject, 
				alertType,
				alertTexts,
				alertLimits,
				alertClasses,
				alertPanel,
				alertPanelParameters,
				alertHelp,
				limitsIncluded,
				isActive,
				exc);
}			
//! [Example: get alarms from two dpes]	