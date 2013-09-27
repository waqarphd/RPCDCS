// $License: NOLICENSE
/**@file
 *
 * JCOP FW Installation Tool: List of supported XML tags in the component description files
 *
 * @author Fernando Varela (EN-ICE)
 * @date   August 2010
 */
/** component This tag defines that this is a component (Mandatory)
*/
string component;
/** Name of the component (Mandatory)

* e.g.  <name>fwCore</name>
*/
string name;
/** Version of the component (Mandatory)

* e.g.    <name>2.4.5</name>
*/
string version;
/** Date when the component was packaged (Mandatory)

* e.g.    <date>10/11/2009</date>
*/
string date;
/** Name of the file containing the entries to be added to the config file of the target project (optional)

* e.g.    <config>./config/fwDIM.config</config>
*/
string config;
/** Filename of an init script (optional)

* e.g.    <init>./config/fwDIM.init</init>
*/
string init;

/** Filename of a post-installation script (optional)

* e.g.    <postInstall>./config/fwDIM.postInstall</postInstall>
*/
string postInstall;
/** Component file (optional)

* e.g.    <file>./fwDIM.xml</file>
*/
string file;
/** Component dpl file.  Note that in the case of having multiple dpl files, the developer may 
    choose the order in which these files are imported using the attribute 'order' 
 (optional)

 * e.g.    <dplist order=1>./dplist/FwDimDemoDps.dpl</dplist>

 * e.g.       <dplist order=2>./dplist/FwDimDps.dpl</dplist>
*/
string dplist;
/** This tag defines the required minimal PVSS version for the component to be installed. 
    An exact match of the PVSS versions can be requested by defining the attributed 'strict' as shown in the example.(optional)

	* e.g.    <required_pvss_version strict=yes>3.6-SP1</required_pvss_version>
*/
string required_pvss_version;

/** This tag defines patch level for a component to be installed (optional)

* e.g.    <required_pvss_patch>C001</required_pvss_patch>
*/
string required_pvss_patch;

/** Filename of a pre-init script. These scripts are executed prior to any other step during the installaiton of a component (optional)

* e.g.    <preinit>./scripts/fwDim/preinit.ctl</preinit>
*/
string preinit;

/** Name of the help file to be opened from the main panel of the Installation Tool (optional)

* e.g.    <help>./fwAccessControl/fwAccessControl.htm</help>
*/
string help;

/** dontRestartProject flag indicating whether the restart of the project can be avoided after the 
* installation of the component. The only possible value "yes" to avoid project restart (optional)

* e.g.    <dontRestartProject>yes</dontRestartProject>
*/
string dontRestartProject;

/** required defines a dependency with a required component. The value must have the format '<component>=<version>'.  (optional)

* e.g.    <required>fwCore=3.2.0</required>
*/
string required;

/** update_types flag indicating if the dp-types of the component must be overwritten in case they already exist in the project.  (optional)

*  e.g.   <update_types></update_types>
*/
string update_types;

/** includeComponent link to a sub-component that must also be installed during the installation of this component  (optional)

* e.g.    <includeComponent>./fwGeneral.xml</includeComponent>
*/
string includeComponent;

/** Developer comment as string (optional)  

*  e.g.   <comment>This is a comment</comment>
*/
string comment;

/** Script to be executed during the deletion of the component  (optional)

* e.g.    <delete>./myDelete.ctl</delete>
*/
string delete;

/** File containing the entries to be added to the config file of the target project. Windows specific (optional)
*/
string config_windows;

/** Script to be executed after the deletion of a component (optional)

* e.g.    <postDelete>./myPostDelete.ctl</postDelete>
*/
string postDelete;

/** File containing the entries to be added to the config file of the target project. Linux specific (optional)
*/
string config_linux;

/** Flag indicating if the component is a subcomponent. Only possible value is 'yes'. (Mandatory for subcomponents)

*  e.g.   <subComponent>yes</subComponent>
*/
string subComponent;
