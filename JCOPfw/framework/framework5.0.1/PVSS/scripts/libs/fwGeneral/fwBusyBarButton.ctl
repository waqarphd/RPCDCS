/**@name LIBRARY: fwBusyBarButton.ctl:

library of function to use the busy bar combined with a button   
 
WARNING: the function from this library can only be used with a graphical interface and 
must be caled from a graphical element having the enable config.  
  
modifications:  

Usage: JCOP framework internal, public

PVSS manager usage: VISION

@version creation: 05/02/2001	
@author H. Milcent  
              
*/  
  
// ----------------------------------------------------------------------------------------------    
//@{
//fwBusyBarButton_std_startBusy:
//start the busy bar and disable the button, this is used.    
/** start the busy bar and disable the button, this is used

Usage: JCOP framework internal, public

PVSS manager usage: VISION

     @param exceptionInfo: exception, in/out parameter
*/
fwBusyBarButton_std_startBusy(dyn_string &exceptionInfo)    
{
	this.enabled = false;
	std_startBusy();	//starting the "busyBar" 
}

//fwBusyBarButton_std_stopBusy:
//stop the busy bar and enable the button, this is used.    
/** start the busy bar and enable the button, this is used

Usage: JCOP framework internal, public

PVSS manager usage: VISION

     @param exceptionInfo: exception, in/out parameter
*/
fwBusyBarButton_std_stopBusy(dyn_string &exceptionInfo)    
{
	this.enabled = true;
	std_stopBusy();		//stopping the busyBar 
}

//@} 

