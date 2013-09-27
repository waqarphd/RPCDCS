#ifndef PVSSDIPAPPIOPTIONS__H
#define PVSSDIPAPPIOPTIONS__H
#ifdef WIN32
#pragma warning ( disable: 4786 )
#endif
#include <stdio.h>

//MD Prevent PVSS to display messages such as "[...]Preliminarry version[...]".
#define PVSS_VERS_SERVER DIP5.4.2.1

#define PVSSLOG(priority, message) {SString m; m << message;ErrHdl::error(priority, ErrClass::ERR_CONTROL, ErrClass::NOERR, m.getString());/*printf("%s\n", m.getString());*/}
#define TRACEIN SString("--->")
#define TRACEOUT SString("<---")

#ifdef _DEBUG
#define PVSSINFO(message) PVSSLOG(ErrClass::PRIO_INFO, message)
#define PVSSTRACE(dir,message) PVSSLOG(ErrClass::PRIO_INFO, dir << message)
#else
#define PVSSINFO(message)
#define PVSSTRACE(dir,message) 
#endif

#define PVSSWARNING(message) PVSSLOG(ErrClass::PRIO_WARNING, SString("**** ") << message)
#define PVSSERROR(message) PVSSLOG(ErrClass::PRIO_SEVERE, SString("!!!! ") << message)
#define PVSSFATAL(message) PVSSLOG(ErrClass::PRIO_FATAL, SString("*#?! ") << message)



#endif

