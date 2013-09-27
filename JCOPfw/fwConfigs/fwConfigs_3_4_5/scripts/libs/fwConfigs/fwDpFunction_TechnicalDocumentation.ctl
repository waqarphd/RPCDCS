/**@file
 *
 * Technical documentation of the tool
 *
* @author Marco Boccioli (EN/ICE-SCD)
 *
 * Please refer to the following topics:
 *
 * @li @ref fwConfigsDpFunctionsDpeConnection
 * @li @ref fwConfigsDpFunctionsStat
 * @li @ref fwConfigsDpFunctions
 */

/** @defgroup fwConfigsDpFunctions fwDpFunction common functions and variables
@ingroup fwConfigsDpFunctionsStat
@ingroup fwConfigsDpFunctionsDpeConnection
This is a list of variables and functions used by both @ref fwConfigsDpFunctionsDpeConnection and @ref fwConfigsDpFunctionsStat
 */
 
/** @defgroup fwConfigsDpFunctionsDpeConnection fwDpFunction DPE Connection 
 *
 * Define dpFunctions of type dpe Connection.  Please refer also to @ref  fwConfigsDpFunctions.
For type statistical, refer to @ref  fwConfigsDpFunctionsStat.

 

 * @section UseExamples Use examples
 *
 * The fwDpFunctions library makes use of a configuration object. In order to configure a dpe with a dp function, the configuration setting object must be 
 * previously initialized with the dp function parameterization (using utility functions). Such object is then passed to the set function that will make the necessary dpSet.
 *
 * @subsection qstart_dpeConnectionSet Setting a dp function of type dpe connection
 *
 *  A function of type DPE Connection can be set in the following way: one should declare a configuration object of type dyn_anytype, then fill it with the dpFunction 
 settings using the function fwDpFunction_objectCreateDpeConnection(), then set the setting to the dpe using the function fwDpFunction_objectSet().
 *
 * Example:
 * @code
    dyn_string exc;
    string dpe;
    //func object containing one dpfunc set
    dyn_mixed dpFuncObject;
    //dp func parameters
    dyn_string functionParams;
    dyn_string functionGlobals;
    string functionDefinition;

    //dp function setting:
    
    //parameters p1, p2
    dynAppend(functionParams,"sys1:dp1.val2:_original.._value");
    dynAppend(functionParams,"sys1:dp1.val3:_original.._value");
    
    //global parameters g1, g2
    dynAppend(functionGlobals,"sys1:dp1.val4:_original.._value");
    dynAppend(functionGlobals,"sys1:dp1.val5:_original.._value");
    
    //the function definition using the parameters
    functionDefinition = "p1+p2+g1+g2";
    
    //create the func object
    fwDpFunction_objectCreateDpeConnection( dpFuncObject,  
                                          functionParams, 
                                          functionGlobals,
                                          functionDefinition, 
                                          exc);
        
    //dpe where to set the dp function
    dpe = "sys1:dp1.val";

    //set the func object to the dpe
    fwDpFunction_objectSet(dpe, dpFuncObject, exc, true);
@endcode
 *
 * @subsection qstart_dpeConnectionGet Getting a dp function of type dpe connection
 *
 *  A function of type DPE Connection can be retrieved from a dpe in the following way: one should declare a configuration object of type dyn_anytype, then fill it with the dpFunction 
 settings from the dpe using the function fwDpFunction_objectGet(), then extract the settings from the configuration object using the function fwDpFunction_objectExtractDpeConnection()..
 Before extracting the settings, it is possible to check that the settings are really of type dpeConnection (function fwDpFunction_objectIsDpeConnection()).
 *
 * Example:
 * @code
    dyn_string exc;
    string dpe; 
    dyn_mixed dpFuncObject;
    dyn_string functionParams;
    dyn_string functionGlobals;
    string functionDefinition;
    bool configExists;

    //dpe containing the dp function
    dpe = "sys1:dpe1.val";
    
    //get the dp function, store it to the dp function settings object
    fwDpFunction_objectGet(dpe, configExists, dpFuncObject, exc);

    //extract the statistical function settings, if it exists
    if(fwDpFunction_objectIsDpeConnection(dpFuncObject)))
      fwDpFunction_objectExtractDpeConnection(dpFuncObject,  
                                            functionParams, 
                                            functionGlobals,
                                            functionDefinition, 
                                            exc);
    
    DebugN( "fwDpFunction_objectGet():",
            functionParams, 
            functionGlobals,
            functionDefinition, 
            exc);  
@endcode
 *
 *
 * @subsection qstart_dpeConnectionSetMany Setting many dp functions of type dpe connection
 *
 *  Functions of type DPE Connection can be set in batch in the following way: one should declare a configuration object of type dyn_anytype (dpFuncObject). 
 This object will be contained in an array of object (one object per dpe), of type dyn_anytype (call it dpFuncObjects).
 Each dpFuncObject then must be filled with the function fwDpFunction_objectCreateDpeConnection(), and stored into the array of objects dpFuncObjects.
The array of objects is then passed together with the array of dpes to the function fwDpFunction_objectSetMany().
 *
 * Example: set 2 dp configs into 2 dpes:
 * @code
    dyn_string exc, dpe;
    //func object containing one dpfunc set
    dyn_mixed dpFuncObject;
    //this contains all the func objects
    dyn_mixed dpFuncObjects;
    //dp func parameters
   	dyn_string functionParams;
  	dyn_string functionGlobals;
  	string functionDefinition;

    //dp function settings for dpe1:
    
    //parameters p1, p2
    dynAppend(functionParams,"sys1:dp1.val2:_original.._value");
    dynAppend(functionParams,"sys1:dp1.val3:_original.._value");
    
    //global parameters g1, g2
    dynAppend(functionGlobals,"sys1:dp1.val4:_original.._value");
    dynAppend(functionGlobals,"sys1:dp1.val5:_original.._value");
    
    //the function definition using the parameters
    functionDefinition = "p1+p2+g1+g2";

    //create the func object
    fwDpFunction_objectCreateDpeConnection( dpFuncObject,  
                                          functionParams, 
                                          functionGlobals,
                                          functionDefinition, 
                                          exc);
       
    //add the first func object to the objects array
    dpFuncObjects[1] = dpFuncObject;

    //dp function settings for dpe2:
    
    //clear temp parameters
    dynClear(functionParams);
    dynClear(functionGlobals);
    dynClear(statTypes);
    
    //parameters p1, p2
    dynAppend(functionParams,"sys1:dp2.float2:_original.._value");
    dynAppend(functionParams,"sys1:dp2.float3:_original.._value");
    
    //global parameters g1, g2
    dynAppend(functionGlobals,"sys1:dp2.float4:_original.._value");
    dynAppend(functionGlobals,"sys1:dp2.int1:_original.._value");

    //the function definition using the parameters
    functionDefinition = "p1+p2/(g1-g2)";

    //create the func object
    fwDpFunction_objectCreateDpeConnection( dpFuncObject,  
                                          functionParams, 
                                          functionGlobals,
                                          functionDefinition, 
                                          exc);
    
    //add the second func object to the objects array
    dpFuncObjects[2] = dpFuncObject;    

    //list of dpes where to set the dp function
    dpe = makeDynString("sys1:dp1.val", "sys1:dp2.val");
    
    //set the func object array to the dpe array
    fwDpFunction_objectSetMany(dpe, dpFuncObjects, exc, true);
@endcode
It is also possible to set many dpes with the same dp function settings. In this case, the array  of settings objects must contain one only object, at the index 1.
 * * Example: set the same dp function into 2 dpes:
 * @code
    dyn_string exc, dpe;
    //func object containing one dpfunc set
    dyn_mixed dpFuncObject;
    //this contains all the func objects
    dyn_mixed dpFuncObjects;
    //dp func parameters
   	dyn_string functionParams;
  	dyn_string functionGlobals;
  	string functionDefinition;

    //the dp function settings:
    
    //parameters p1, p2
    dynAppend(functionParams,"sys1:dp1.val2:_original.._value");
    dynAppend(functionParams,"sys1:dp1.val3:_original.._value");
    
    //global parameters g1, g2
    dynAppend(functionGlobals,"sys1:dp1.val4:_original.._value");
    dynAppend(functionGlobals,"sys1:dp1.val5:_original.._value");
    
    //the function definition using the parameters
    functionDefinition = "p1+p2+g1+g2";

    //create the func object
    fwDpFunction_objectCreateDpeConnection( dpFuncObject,  
                                          functionParams, 
                                          functionGlobals,
                                          functionDefinition, 
                                          exc);
       
    //add the first func object to the objects array
    dpFuncObjects[1] = dpFuncObject;

    //list of dpes where to set the dp function
    dpe = makeDynString("sys1:dp1.val", "sys1:dp2.val");
    
    //set the func object to the dpe array
    fwDpFunction_objectSetMany(dpe, dpFuncObjects, exc, true);
@endcode
 *
 * @subsection qstart_dpeConnectionGetMany Getting many dp functions of type dpe connection
 *
 *  Functions of type DPE Connection can be retrieved in batch. This is more performing than looping into the dpes with the function fwDpFunction_objectGet().
 It can be done in the following way: one should declare a configuration object of type dyn_anytype (dpFuncObject). 
 This object will be contained in an array of object (one object per dpe), of type dyn_anytype (call it dpFuncObjects).
The array of objects dpFuncObjects then must be filled with the function fwDpFunction_objectGetMany(). The array is the accessed in a loop, getting each element 
dpFuncObject inside dpFunctionObject. The parameters can be then accessed using fwDpFunction_objectEctractDpeConnection().
 *
 * Example: get 2 dp configs into 2 dpes:
 * @code
    dyn_string exc;
    dyn_string dpe; 
    dyn_mixed dpFuncObjects;
    int i;  
 	dyn_string functionParams;
	dyn_string functionGlobals;
	string functionDefinition;
    dyn_bool configExists;


    //list of dpes
    makeDynString("sys1:dpe1.val","sys1:dpe2.val");
 
    fwDpFunction_objectGetMany(dpe, configExists, dpFuncObjects, exc);

    for(i=1 ; i<=dynlen(dpe) ; i++)
    {
         if(fwDpFunction_objectIsDpeConnection(dpFuncObject[i]))
            fwDpFunction_objectExtractDpeConnection(dpFuncObjects[i], functionParams, functionGlobals, functionDefinition, exc);

        DebugN( "fwDpFunction_objectGetMany():", dpe[i],
                               functionParams, functionGlobals, functionDefinition, exc);   
    }
@endcode
 */
 

/** @defgroup fwConfigsDpFunctionsStat fwDpFunction Statistical
 * Define dpFunctions of type statistical.  Please refer also to @ref  fwConfigsDpFunctions.
 For type dpe Connection, refer to @ref  fwConfigsDpFunctionsDpeConnection.
 
 * @section UseExamples Use Examples
 *
 * The fwDpFunctions library makes use of a configuration object. In order to configure a dpe with a dp function, the configuration setting object must be 
 * previously initialized with the dp function parameterization (using utility functions). Such object is then passed to the set function that will make the necessary dpSet.
 * 
 Statistical functions are partially supported by fwDpFunction. The utility functions allow creating/extracting basic setting of statistical function. 
 For more advanced settings, see their availability using  the Configuration object indexes
 
 * @subsection qstart_statSet Setting a dp function of type statistical
 *
 *  A function of statistical type can be set in the following way: one should declare a configuration object of type dyn_anytype, then fill it with the dpFunction 
 settings using the function fwDpFunction_objectCreateStatistical(), then set the setting to the dpe using the function fwDpFunction_objectSet().
 *
 * Example:
 * @code
    dyn_string exc;
    string dpe;
    //func object containing one dpfunc set
    dyn_mixed dpFuncObject;
    //dp func parameters
   	dyn_string functionParams;
  	dyn_string functionGlobals;
  	string functionDefinition;
    dyn_int statTypes;
  	int intervalS;
  	int delayS;
  	bool readArchive;

    //dp function setting:
    
    //parameters p1, p2
    dynAppend(functionParams,"sys1:dp1.val2:_original.._value");
    dynAppend(functionParams,"sys1:dp1.val3:_original.._value");
    
    //global parameters g1, g2
    dynAppend(functionGlobals,"sys1:dp1.val4:_original.._value");
    dynAppend(functionGlobals,"sys1:dp1.val5:_original.._value");
    
    //parameter p1 is a Maximum function, parameter p2 is an Average function
    dynAppend(statTypes,SF_MAX);
    dynAppend(statTypes,SF_AVG);
    
    //the function definition using the parameters
    functionDefinition = "p1+p2+g1+g2";
    
    //time interval
    intervalS = 3;
    
    //delay on first start
    delayS = 4;
    
    //start reading from archive
    readArchive = true;

    //create the func object
    fwDpFunction_objectCreateStatistical( dpFuncObject,  
                                          functionParams, 
                                          functionGlobals,
                                          functionDefinition, 
                                          statTypes,
                                          intervalS,
                                          delayS,
                                          readArchive,
                                          exc);
        
    //dpe where to set the dp function
    dpe = "sys1:dp1.val";

    //set the func object to the dpe
    fwDpFunction_objectSet(dpe, dpFuncObject, exc, true);
@endcode
 *
 * @subsection qstart_statGet Getting a dp function of type statistical
 *
 *  A function of statistical type can be retrieved from a dpe in the following way: one should declare a configuration object of type dyn_anytype, then fill it with the dpFunction 
 settings from the dpe using the function fwDpFunction_objectGet(), then extract the settings from the configuration object using the function fwDpFunction_objectExtractStatistical().
 Before extracting the settings, it is possible to check that the settings are really of type stiatistical (function fwDpFunction_objectIsStatistical()).
 *
 * Example:
 * @code
      dyn_string exc;
    string dpe; 
    dyn_mixed dpFuncObject;
    dyn_string functionParams;
    dyn_string functionGlobals;
    string functionDefinition;
    dyn_int statTypes;
    int intervalS;
    int delayS;
    bool readArchive;
    bool configExists;

    //dpe containing the dp function
    dpe = "sys1:dpe1.val";
    
    //get the dp function, store it to the dp function settings object
    fwDpFunction_objectGet(dpe, configExists, dpFuncObject, exc);

    //extract the statistical function settings, if it exists
    if(fwDpFunction_objectIsStatistical(dpFuncObject))
      fwDpFunction_objectExtractStatistical(dpFuncObject,  
                                            functionParams, 
                                            functionGlobals,
                                            functionDefinition, 
                                            statTypes,
                                            intervalS,
                                            delayS,
                                            readArchive,
                                            exc);
    
    DebugN( "fwDpFunction_objectGet():",
            functionParams, 
            functionGlobals,
            functionDefinition, 
            statTypes,
            intervalS,
            delayS,
            readArchive,
            exc);  
@endcode
 *
 *
 * @subsection qstart_statSetMany Setting many dp functions of type statistical
 *
 *  Functions of statistical type can be set in batch in the following way: one should declare a configuration object of type dyn_anytype (dpFuncObject). 
 This object will be contained in an array of object (one object per dpe), of type dyn_anytype (call it dpFuncObjects).
 Each dpFuncObject then must be filled with the function fwDpFunction_objectCreateStatistical(), and stored into the array of objects dpFuncObjects.
The array of objects is then passed together with the array of dpes to the function fwDpFunction_objectSetMany().
Such procedure is more performing than looping into the dpes with the function fwDpFunction_objectSet().

 *
 * Example: set 2 dp configs into 2 dpes:
 * @code
     dyn_string exc, dpe;
    //func object containing one dpfunc set
    dyn_mixed dpFuncObject;
    //this contains all the func objects
    dyn_mixed dpFuncObjects;
    //dp func parameters
   	dyn_string functionParams;
  	dyn_string functionGlobals;
  	string functionDefinition;
    dyn_int statTypes;
  	int intervalS;
  	int delayS;
  	bool readArchive;

    //dp function settings for dpe1:
    
    //parameters p1, p2
    dynAppend(functionParams,"sys1:dp1.val2:_original.._value");
    dynAppend(functionParams,"sys1:dp1.val3:_original.._value");
    
    //global parameters g1, g2
    dynAppend(functionGlobals,"sys1:dp1.val4:_original.._value");
    dynAppend(functionGlobals,"sys1:dp1.val5:_original.._value");
    
    //parameter p1 is a Maximum function, parameter p2 is an Average function
    dynAppend(statTypes,SF_MAX);
    dynAppend(statTypes,SF_AVG);
    
    //the function definition using the parameters
    functionDefinition = "p1+p2+g1+g2";
    
    //time interval
    intervalS = 3;
    
    //delay on first start
    delayS = 4;
    
    //start reading from archive
    readArchive = true;

    //create the func object
    fwDpFunction_objectCreateStatistical( dpFuncObject,  
                                          functionParams, 
                                          functionGlobals,
                                          functionDefinition, 
                                          statTypes,
                                          intervalS,
                                          delayS,
                                          readArchive,
                                          exc);
    
    //add the func object to the objects array
    dpFuncObjects[1] = dpFuncObject;

    //dp function settings for dpe2:
    
    //clear temp parameters
    dynClear(functionParams);
    dynClear(functionGlobals);
    dynClear(statTypes);
    
    //parameters p1, p2
    dynAppend(functionParams,"sys1:dp2.float2:_original.._value");
    dynAppend(functionParams,"sys1:dp2.float3:_original.._value");
    
    //global parameters g1, g2
    dynAppend(functionGlobals,"sys1:dp2.float4:_original.._value");
    dynAppend(functionGlobals,"sys1:dp2.int1:_original.._value");
    
    //parameter p1 is a Maximum function, parameter p2 is an Average function
    dynAppend(statTypes,SF_MAX);
    dynAppend(statTypes,SF_AVG);
    
    //the function definition using the parameters
    functionDefinition = "p1+p2/(g1-g2)";
    
    //time interval
    intervalS = 3;
    
    //delay on first start
    delayS = 4;
    
    //start reading from archive
    readArchive = true;

    //create the func object
    fwDpFunction_objectCreateStatistical( dpFuncObject,  
                                          functionParams, 
                                          functionGlobals,
                                          functionDefinition, 
                                          statTypes,
                                          intervalS,
                                          delayS,
                                          readArchive,
                                          exc);
    
    //add the second func object to the objects array
    dpFuncObjects[2] = dpFuncObject;    

    //list of dpes where to set the dp function
    dpe = makeDynString("sys1:dp1.val", "sys1:dp2.val");
    
    //set the func object array to the dpe array
    fwDpFunction_objectSetMany(dpe, dpFuncObjects, exc, true);
@endcode
It is also possible to set many dpes with the same dp function settings. In this case, the array  of settings objects must contain one only object, at the index 1.
 * * Example: set the same dp function into 2 dpes:
* @code
     dyn_string exc, dpe;
    //func object containing one dpfunc set
    dyn_mixed dpFuncObject;
    //this contains all the func objects
    dyn_mixed dpFuncObjects;
    //dp func parameters
   	dyn_string functionParams;
  	dyn_string functionGlobals;
  	string functionDefinition;
    dyn_int statTypes;
  	int intervalS;
  	int delayS;
  	bool readArchive;

    //dp function settings for dpe1:
    
    //parameters p1, p2
    dynAppend(functionParams,"sys1:dp1.val2:_original.._value");
    dynAppend(functionParams,"sys1:dp1.val3:_original.._value");
    
    //global parameters g1, g2
    dynAppend(functionGlobals,"sys1:dp1.val4:_original.._value");
    dynAppend(functionGlobals,"sys1:dp1.val5:_original.._value");
    
    //parameter p1 is a Maximum function, parameter p2 is an Average function
    dynAppend(statTypes,SF_MAX);
    dynAppend(statTypes,SF_AVG);
    
    //the function definition using the parameters
    functionDefinition = "p1+p2+g1+g2";
    
    //time interval
    intervalS = 3;
    
    //delay on first start
    delayS = 4;
    
    //start reading from archive
    readArchive = true;

    //create the func object
    fwDpFunction_objectCreateStatistical( dpFuncObject,  
                                          functionParams, 
                                          functionGlobals,
                                          functionDefinition, 
                                          statTypes,
                                          intervalS,
                                          delayS,
                                          readArchive,
                                          exc);
    
    //add the func object to the objects array
    dpFuncObjects[1] = dpFuncObject;

    //list of dpes where to set the dp function
    dpe = makeDynString("sys1:dp1.val", "sys1:dp2.val");
    
    //set the func object to the dpe array
    fwDpFunction_objectSetMany(dpe, dpFuncObjects, exc, true);
@endcode
* @subsection qstart_statGet Getting a dp function of type statistical
 *
 *  A function of statistical type can be retrieved from a dpe in the following way: one should declare a configuration object of type dyn_anytype, then fill it with the dpFunction 
 settings from the dpe using the function fwDpFunction_objectGet(), then extract the settings from the configuration object using the function fwDpFunction_objectExtractStatistical().
 Before extracting the settings, it is possible to check that the settings are really of type dpeConnection (function fwDpFunction_objectIsStatistical()).
  *
 * Example:
 * @code
     dyn_string exc;
    string dpe; 
    dyn_mixed dpFuncObject;
    dyn_string functionParams;
    dyn_string functionGlobals;
    string functionDefinition;
    dyn_int statTypes;
    int intervalS;
    int delayS;
    bool readArchive;
    bool configExists;

    //dpe containing the dp function
    dpe = "sys1:dpe1.val";
    
    //get the dp function, store it to the dp function settings object
    fwDpFunction_objectGet(dpe, configExists, dpFuncObject, exc);

    //extract the statistical function settings, if it exists
    if(fwDpFunction_objectIsStatistical(dpFuncObject))
      fwDpFunction_objectExtractStatistical(dpFuncObject,  
                                            functionParams, 
                                            functionGlobals,
                                            functionDefinition, 
                                            statTypes,
                                            intervalS,
                                            delayS,
                                            readArchive,
                                            exc);
    
    DebugN( "fwDpFunction_objectGet():",
            functionParams, 
            functionGlobals,
            functionDefinition, 
            statTypes,
            intervalS,
            delayS,
            readArchive,
            exc);  
@endcode
 *
 *
 * @subsection qstart_statGetMany Getting many dp functions of type statistical
 *
 *  Functions of statistical type can be retrieved in batch. This is more performing than looping into the dpes with the function fwDpFunction_objectGet().
 It can be done in the following way: one should declare a configuration object of type dyn_anytype (dpFuncObject). 
 This object will be contained in an array of object (one object per dpe), of type dyn_anytype (call it dpFuncObjects).
The array of objects dpFuncObjects then must be filled with the function fwDpFunction_objectGetMany(). The array is the accessed in a loop, getting each element 
dpFuncObject inside dpFunctionObject. The parameters can be then accessed using fwDpFunction_objectEctractStatistical().
 *
 * Example: set 2 dp configs into 2 dpes:
 * @code
    dyn_string exc;
    dyn_string dpe; 
    dyn_mixed dpFuncObjects;
    int i;  
 	dyn_string functionParams;
	dyn_string functionGlobals;
	string functionDefinition;
    dyn_bool configExists;
    dyn_int statTypes;
    int intervalS;
    int delayS;
    bool readArchive;

    //list of dpes
    makeDynString("sys1:dpe1.val","sys1:dpe2.val");
 
    fwDpFunction_objectGetMany(dpe, configExists, dpFuncObjects, exc);

	for(i=1 ; i<=dynlen(dpe) ; i++)
	{
    if(fwDpFunction_objectIsStatistical(dpFuncObjects[i]))
      fwDpFunction_objectExtractStatistical(dpFuncObjects[i],  
                                            functionParams, 
                                            functionGlobals,
                                            functionDefinition, 
                                            statTypes,
                                            intervalS,
                                            delayS,
                                            readArchive,
                                            exc);

        DebugN( "fwDpFunction_objectGetMany():", dpe[i],
		functionParams, functionGlobals, functionDefinition,  
		statTypes,
		delayS,
		readArchive, exc);   
	}
@endcode
 

 */
