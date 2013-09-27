/**@file
 *
 * Technical documentation of the tool
 *
* @author Marco Boccioli (EN/ICE-SCD)
 *
 * Please refer to the following topics:
 *
 * @li @ref fwConfigsAlert
 */

/** @defgroup fwConfigsAlert fwAlertConfig

The fwAlertConfigs library allows configuring alerts of type analog, discrete, boolean, summary.

 * @section UseExamples Use examples
 *
 * The fwAlertConfigs library makes use of a configuration object. In order to configure a dpe with an alarm, the configuration setting object must be 
 * previously initialized with the alarm parameterization (using utility functions or directly accessing the object through the index constants). Such object is then passed to the set function that will make the necessary dpSet.
 *
 * @subsection qstart_setAnalog Setting an analog alarm
 *
 *  An analog alarm can be set in the following way: one should declare a configuration object of type dyn_anytype, then fill it with the alarm 
 settings using the utility function fwAlertConfig_objectCreateAnalog(), then set the setting to the dpe using the function fwAlertConfig_objectSet().
 *
 * Example: create an analog alert object (3 ranges) using the utility functions and set it to the dpe
  \snippet fwAlertConfig_Examples.ctl Example: create Analog with utility function
For more examples, see the documentation for the function fwAlertConfig_objectSet().
 *
  * @subsection qstart_setBool Setting an alarm of type Digital (bool)
 *
 *  A digital (bool) alarm can be set in the following way: one should declare a configuration object of type dyn_anytype, then fill it with the alarm 
 settings using the utility function fwAlertConfig_objectCreateDigital(), then set the setting to the dpe using the function fwAlertConfig_objectSet().
 *
 * Example: create a digital alert object (ok when true, alarm when false) using the utility functions and set it to the dpe
  \snippet fwAlertConfig_Examples.ctl Example: create Digital, false=ok, with utility function

 * Example: create a digital alert object (ok when true, alarm when false)
  \snippet fwAlertConfig_Examples.ctl Example: create Digital, true=ok, with utility function

 *  An alarm can be also set accessing the parametrization object directly. This can be useful in case a user needs to use advanced features not available in the utility functions.
One can declare a configuration object of type dyn_anytype, then fill it with the alarm 
 settings accessing the items through the object indexes, then set the setting to the dpe using the function fwAlertConfig_objectSet(). 
 *
 * Example: create a digital alert object (ok when false, alarm when true)
  \snippet fwAlertConfig_Examples.ctl Example: create Digital, false=ok, without utility function
 *
 *
 * @subsection qstart_setDiscrete Setting a discrete alert
 *
 *  A discrete alarm can be set to types float, int and bit32. One should declare a configuration object of type dyn_anytype, then fill it with the alarm 
 settings using the utility function fwAlertConfig_objectCreateDiscrete(), then set the setting to the dpe using the function fwAlertConfig_objectSet().
 *
 *  Example: create a discrete alert object (3 ranges) using the utility functions and set it to the dpe
  \snippet fwAlertConfig_Examples.ctl Example: create Discrete with utility function
For more examples, see the documentation for the function fwAlertConfig_objectSet().
 *

* @subsection qstart_setDiscrete_noUtil Setting a discrete alert without the use of utility function
 *
 *  An alarm can be also set accessing the parametrization object directly: one can declare a configuration object of type dyn_anytype, then fill it with the alarm 
 settings accessing the items through the object indexes, then set the setting to the dpe using the function fwAlertConfig_objectSet().
 *
 * Example: create a discrete alert object with 3 ranges and the basic parameters
  \snippet fwAlertConfig_Examples.ctl Example: create Discrete without utility function 
For more examples, see the documentation for the function fwAlertConfig_objectSet().

* @subsection qstart_setSummary Setting summary alert
 *
 *  An alarm can be also set accessing the parametrization object directly: one can declare a configuration object of type dyn_anytype, then fill it with the alarm 
 settings accessing the items through the object indexes, then set the setting to the dpe using the function fwAlertConfig_objectSet().
 *
 * Example: create a summary alert object
  \snippet fwAlertConfig_Examples.ctl Example: create Summary with utility function
For more examples, see the documentation for the function fwAlertConfig_objectSet().

* @subsection qstart_setManyAnalog Setting many alarms
 *
 *  Alarms can be set in batch in the following way: one should declare a configuration object of type dyn_mixed (alarmObject). 
 This object will be contained in an array of object (one object per dpe), of type dyn_mixed (call it alarmObjects).
 Each alarmObject then must be filled with the function fwAlertConfig_objectCreateAnalog(), and stored into the array of objects alarmObjects.
The array of objects is then passed together with the array of dpes to the function fwAlertConfig_objectSetMany().
 *
 * Example: create analog alert objects with 3 ranges and the basic parameters and set them to dpes
  \snippet fwAlertConfig_Examples.ctl Example: set 2 alarms with utility function

It is also possible to set many dpes with the same alarm settings. In this case, the array  of settings objects must contain one only object, at the index 1.
 * Example: set the same alarm into 2 dpes:
  \snippet fwAlertConfig_Examples.ctl Example: set one alarm into 2 dpes with utility function
For more examples, see the documentation for the function fwAlertConfig_objectSetMany().
 *
 * @subsection qstart_getAnalog Getting an alarm
 *
 *  Alarm settings can be retrieved from a dpe in the following way: one should declare a configuration object of type dyn_mixed, then fill it with the alarm 
 settings from the dpe using the function fwAlertConfig_objectGet(), then, in the case of an analog alert, extract the settings from the configuration object using the function fwAlertConfig_objectExtractAnalog().
  *
 * Example: get an analog alarm from a dpe 
   \snippet fwAlertConfig_Examples.ctl Example: get an analog alarm from a dpe
 
  * @subsection qstart_analogGetMany Getting many alarms
 *
 *  Alarms can be retrieved in batch. This is much more performing than looping into the dpes with the function fwAlertConfig_objectGet().
The configuration objects will be contained in an array of object (one object per dpe), of type dyn_mixed (call it alertObjects).
The array of objects alertObjects then must be filled with the function fwDpFunction_objectGetMany(). The array is the accessed in a loop, getting each element. 
The parameters can be then accessed using fwAlertConfig_objectExtractAnalog().
 *
 * Example: get alarms from two dpes:
   \snippet fwAlertConfig_Examples.ctl Example: get alarms from two dpes
 

 */
