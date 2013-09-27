main()
{
// This is a demo only!
// It uses "TestDevice" device cookie, and it is registered
// (in fwAccessControl_initializeHook) using ITCO_TEST authorization password,
// i.e. the code such as:
//{
// 	string deviceCookie="AuthDeviceTest";
//	string authPassword="ITCO_TEST";
//	_fwAccessControl_extAuth_permitDevice(myHostName, deviceCookie, authPassword);
//}
// The use of these "test" authentication strings allows that the
// function may only authenticate user "guest", or log a user out.
// To get the full functionality, with no limitations, contact
// CERN IT/CO-BE to get the authorization password.

DebugN("---------");
DebugN("Hello from TestAuthDev");
dyn_string exceptionInfo;
string deviceCookie="AuthDeviceTest";

    // find out our host name 
    string hostName=getHostname();

// initialize the driver. We will authenticate UIs connected to our hostName
_fwAccessControl_extAuth_initDeviceDriver("TestDevice", hostName, deviceCookie,exceptionInfo);
if ( (dynlen(exceptionInfo))) {
    DebugN("Error initializing TestAuthDev",exceptionInfo);
    return;
}

// try to authenticate user "guest"
DebugN("Authenticating guest at "+hostName);
_fwAccessControl_extAuth_authenticate("guest", deviceCookie);

}