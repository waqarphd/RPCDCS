# Microsoft Developer Studio Project File - Name="DIPAPIManager" - Package Owner=<4>
# Microsoft Developer Studio Generated Build File, Format Version 6.00
# ** DO NOT EDIT **

# TARGTYPE "Win32 (x86) Console Application" 0x0103

CFG=DIPAPIManager - Win32 Debug
!MESSAGE This is not a valid makefile. To build this project using NMAKE,
!MESSAGE use the Export Makefile command and run
!MESSAGE 
!MESSAGE NMAKE /f "DIPAPIManager.mak".
!MESSAGE 
!MESSAGE You can specify a configuration when running NMAKE
!MESSAGE by defining the macro CFG on the command line. For example:
!MESSAGE 
!MESSAGE NMAKE /f "DIPAPIManager.mak" CFG="DIPAPIManager - Win32 Debug"
!MESSAGE 
!MESSAGE Possible choices for configuration are:
!MESSAGE 
!MESSAGE "DIPAPIManager - Win32 Release" (based on "Win32 (x86) Console Application")
!MESSAGE "DIPAPIManager - Win32 Debug" (based on "Win32 (x86) Console Application")
!MESSAGE 

# Begin Project
# PROP AllowPerConfigDependencies 0
# PROP Scc_ProjName ""
# PROP Scc_LocalPath ""
CPP=cl.exe
RSC=rc.exe

!IF  "$(CFG)" == "DIPAPIManager - Win32 Release"

# PROP BASE Use_MFC 0
# PROP BASE Use_Debug_Libraries 0
# PROP BASE Output_Dir "Release"
# PROP BASE Intermediate_Dir "Release"
# PROP BASE Target_Dir ""
# PROP Use_MFC 0
# PROP Use_Debug_Libraries 0
# PROP Output_Dir "Release"
# PROP Intermediate_Dir "Release"
# PROP Ignore_Export_Lib 0
# PROP Target_Dir ""
# ADD BASE CPP /nologo /W3 /GX /O2 /D "WIN32" /D "NDEBUG" /D "_CONSOLE" /D "_MBCS" /YX /FD /c
# ADD CPP /nologo /Zp8 /MD /W3 /GR /GX /Zi /O2 /I ".\\" /I "$(API_ROOT)\include\winnt\pvssincl" /I "$(API_ROOT)\include\Basics\Utilities" /I "$(API_ROOT)\include\Basics\Variables" /I "$(API_ROOT)\include\Basics\NoPosix" /I "$(API_ROOT)\include\BCMNew" /I "$(API_ROOT)\include\Configs" /I "$(API_ROOT)\include\Datapoint" /I "$(API_ROOT)\include\Messages" /I "$(API_ROOT)\include\Manager" /I "$(DIPBASE)\Implementation\CPP\Sources\DIP\PlatformDependant" /I "$(DIPBASE)\Implementation\CPP\Sources\DIP\DimImplementation" /I "$(DIPBASE)\Implementation\CPP\Sources\DIP\Interface" /FI"$(API_ROOT)\include\winnt\win32.h" /D "WIN32" /D "IS_MSWIN__" /D "_EXCURSION" /D "bcm_boolean_h" /D "FUNCPROTO" /FD /c
# ADD BASE RSC /l 0x407 /d "NDEBUG"
# ADD RSC /l 0x407 /d "NDEBUG"
BSC32=bscmake.exe
# ADD BASE BSC32 /nologo
# ADD BSC32 /nologo
LINK32=link.exe
# ADD BASE LINK32 kernel32.lib user32.lib gdi32.lib winspool.lib comdlg32.lib advapi32.lib shell32.lib ole32.lib oleaut32.lib uuid.lib odbc32.lib odbccp32.lib /nologo /subsystem:console /machine:I386
# ADD LINK32 $(API_ROOT)\lib.winnt\libManager.lib $(API_ROOT)\lib.winnt\libMessages.lib $(API_ROOT)\lib.winnt\libDatapoint.lib $(API_ROOT)\lib.winnt\libBasics.lib $(API_ROOT)\lib.winnt\bcm.lib wsock32.lib user32.lib advapi32.lib netapi32.lib $(API_ROOT)\lib.winnt\libConfigs.lib PlatformDependant_dll.lib Dip.lib /nologo /subsystem:console /pdb:none /machine:I386 /libpath:"$(DIPBASE)\Implementation\CPP\Windows\VCPP6\PlatformDependant_dll\Release" /libpath:"$(DIPBASE)\Implementation\CPP\Windows\VCPP6\Dip\Release"
# SUBTRACT LINK32 /debug
# Begin Special Build Tool
SOURCE="$(InputPath)"
PostBuild_Desc=Moving files to test project RELEASE.
PostBuild_Cmds=copy C:\CVS\Projects\DIP\Implementation\CPP\Windows\VCPP6\Dip\Release\Dip.dll C:\PVSSProjects\DIPPVSS31Testing\bin\Dip.dll	copy C:\CVS\Projects\DIP\Implementation\CPP\Windows\VCPP6\PlatformDependant_dll\Release\PlatformDependant_dll.dll C:\PVSSProjects\DIPPVSS31Testing\bin\PlatformDependant_dll.dll	copy C:\CVS\Projects\Framework\Software\framework2.0\Tools\fwDIP\PVSS\source\fwDIP\Windows\VCPP6\DIPAPIManager\Release\DIPAPIManager.exe C:\PVSSProjects\DIPPVSS31Testing\bin\PVSS00dip.exe
# End Special Build Tool

!ELSEIF  "$(CFG)" == "DIPAPIManager - Win32 Debug"

# PROP BASE Use_MFC 0
# PROP BASE Use_Debug_Libraries 1
# PROP BASE Output_Dir "Debug"
# PROP BASE Intermediate_Dir "Debug"
# PROP BASE Target_Dir ""
# PROP Use_MFC 0
# PROP Use_Debug_Libraries 1
# PROP Output_Dir "Debug"
# PROP Intermediate_Dir "Debug"
# PROP Ignore_Export_Lib 0
# PROP Target_Dir ""
# ADD BASE CPP /nologo /W3 /Gm /GX /Zi /Od /D "WIN32" /D "_DEBUG" /D "_CONSOLE" /D "_MBCS" /YX /FD /c
# ADD CPP /nologo /MDd /W3 /GR /GX /Zi /I ".\\" /I "$(API_ROOT)\include\winnt\pvssincl" /I "$(API_ROOT)\include\Basics\Utilities" /I "$(API_ROOT)\include\Basics\Variables" /I "$(API_ROOT)\include\Basics\NoPosix" /I "$(API_ROOT)\include\BCMNew" /I "$(API_ROOT)\include\Configs" /I "$(API_ROOT)\include\Datapoint" /I "$(API_ROOT)\include\Messages" /I "$(API_ROOT)\include\Manager" /I "$(DIPBASE)\Implementation\CPP\Sources\DIP\PlatformDependant" /I "$(DIPBASE)\Implementation\CPP\Sources\DIP\DimImplementation" /I "$(DIPBASE)\Implementation\CPP\Sources\DIP\Interface" /FI"$(API_ROOT)\include\winnt\win32.h" /D "WIN32" /D "IS_MSWIN__" /D "_EXCURSION" /D "bcm_boolean_h" /D "FUNCPROTO" /FD /c
# ADD BASE RSC /l 0x407 /d "_DEBUG"
# ADD RSC /l 0x407 /d "_DEBUG"
BSC32=bscmake.exe
# ADD BASE BSC32 /nologo
# ADD BSC32 /nologo
LINK32=link.exe
# ADD BASE LINK32 kernel32.lib user32.lib gdi32.lib winspool.lib comdlg32.lib advapi32.lib shell32.lib ole32.lib oleaut32.lib uuid.lib odbc32.lib odbccp32.lib /nologo /subsystem:console /debug /machine:I386 /pdbtype:con
# ADD LINK32 $(API_ROOT)\lib.winnt\libManager.lib $(API_ROOT)\lib.winnt\libMessages.lib $(API_ROOT)\lib.winnt\libDatapoint.lib $(API_ROOT)\lib.winnt\libConfigs.lib $(API_ROOT)\lib.winnt\libBasics.lib $(API_ROOT)\lib.winnt\bcm.lib wsock32.lib user32.lib advapi32.lib netapi32.lib PlatformDependant_dll.lib Dip.lib /nologo /subsystem:console /debug /machine:I386 /pdbtype:con /libpath:"$(DIPBASE)\Implementation\CPP\Windows\VCPP6\PlatformDependant_dll\Debug" /libpath:"$(DIPBASE)\Implementation\CPP\Windows\VCPP6\Dip\Debug"
# SUBTRACT LINK32 /pdb:none /incremental:no
# Begin Special Build Tool
SOURCE="$(InputPath)"
PostBuild_Desc=Moving files to test project DEBUG.
PostBuild_Cmds=copy C:\CVS\Projects\Framework\Software\framework2.0\Tools\fwDIP\PVSS\source\fwDIP\Windows\VCPP6\DIPAPIManager\Debug\DIPAPIManager.exe C:\PVSSProjects\DIPPVSS31Testing\bin\PVSS00dip.exe	copy C:\CVS\Projects\DIP\Implementation\CPP\Windows\VCPP6\Dip\Debug\Dip.dll C:\PVSSProjects\DIPPVSS31Testing\bin\Dip.dll	copy C:\CVS\Projects\DIP\Implementation\CPP\Windows\VCPP6\PlatformDependant_dll\Debug\PlatformDependant_dll.dll C:\PVSSProjects\DIPPVSS31Testing\bin\PlatformDependant_dll.dll
# End Special Build Tool

!ENDIF 

# Begin Target

# Name "DIPAPIManager - Win32 Release"
# Name "DIPAPIManager - Win32 Debug"
# Begin Source File

SOURCE=..\..\..\Sources\AnswerCallBackHandler.cpp
# End Source File
# Begin Source File

SOURCE=..\..\..\Sources\AnswerCallBackHandler.h
# End Source File
# Begin Source File

SOURCE=..\..\..\Sources\ApiMain.cxx
# End Source File
# Begin Source File

SOURCE=..\..\..\Sources\Browser.cpp
# End Source File
# Begin Source File

SOURCE=..\..\..\Sources\Browser.h
# End Source File
# Begin Source File

SOURCE=..\..\..\Sources\CbridgeDataObject.h
# End Source File
# Begin Source File

SOURCE=..\..\..\Sources\CdipClientDataObject.cpp
# End Source File
# Begin Source File

SOURCE=..\..\..\Sources\CdipClientDataObject.h
# End Source File
# Begin Source File

SOURCE=..\..\..\Sources\CdipDataMapping.cpp
# End Source File
# Begin Source File

SOURCE=..\..\..\Sources\CdipDataMapping.h
# End Source File
# Begin Source File

SOURCE=..\..\..\Sources\CdipSubscription.cpp
# End Source File
# Begin Source File

SOURCE=..\..\..\Sources\CdipSubscription.h
# End Source File
# Begin Source File

SOURCE=..\..\..\Sources\CdpeWrapper.cpp
# End Source File
# Begin Source File

SOURCE=..\..\..\Sources\CdpeWrapper.h
# End Source File
# Begin Source File

SOURCE=..\..\..\Sources\CmdLine.cpp
# End Source File
# Begin Source File

SOURCE=..\..\..\Sources\CmdLine.h
# End Source File
# Begin Source File

SOURCE=..\..\..\Sources\DipApiManager.cxx
# End Source File
# Begin Source File

SOURCE=..\..\..\Sources\DipApiManager.hxx
# End Source File
# Begin Source File

SOURCE=..\..\..\Sources\DipApiResources.cxx
# End Source File
# Begin Source File

SOURCE=..\..\..\Sources\DipApiResources.hxx
# End Source File
# Begin Source File

SOURCE=..\..\..\Sources\DIPClientManager.cpp
# End Source File
# Begin Source File

SOURCE=..\..\..\Sources\DIPClientManager.h
# End Source File
# Begin Source File

SOURCE=..\..\..\Sources\dipManager.cpp
# End Source File
# Begin Source File

SOURCE=..\..\..\Sources\dipManager.h
# End Source File
# Begin Source File

SOURCE=..\..\..\Sources\dipPubGroup.cpp
# End Source File
# Begin Source File

SOURCE=..\..\..\Sources\dipPubGroup.h
# End Source File
# Begin Source File

SOURCE=..\..\..\Sources\dipPublicationManager.cpp
# End Source File
# Begin Source File

SOURCE=..\..\..\Sources\dipPublicationManager.h
# End Source File
# Begin Source File

SOURCE=..\..\..\Sources\dpeMapping.cpp
# End Source File
# Begin Source File

SOURCE=..\..\..\Sources\dpeMapping.h
# End Source File
# Begin Source File

SOURCE=..\..\..\Sources\dpeMappingTuple.cpp
# End Source File
# Begin Source File

SOURCE=..\..\..\Sources\dpeMappingTuple.h
# End Source File
# Begin Source File

SOURCE=..\..\..\Sources\DummyDIPData.h
# End Source File
# Begin Source File

SOURCE=..\..\..\Sources\mapping.cpp
# End Source File
# Begin Source File

SOURCE=..\..\..\Sources\mapping.h
# End Source File
# Begin Source File

SOURCE=..\..\..\Sources\pubDpeWrapper.cpp
# End Source File
# Begin Source File

SOURCE=..\..\..\Sources\pubDpeWrapper.h
# End Source File
# Begin Source File

SOURCE=..\..\..\Sources\PVSS_DIP_TypeMap.cpp
# End Source File
# Begin Source File

SOURCE=..\..\..\Sources\PVSS_DIP_TypeMap.h
# End Source File
# Begin Source File

SOURCE=..\..\..\Sources\PVSSDIPAPIOptions.h
# End Source File
# Begin Source File

SOURCE=..\..\..\Sources\RedManager.cpp
# End Source File
# Begin Source File

SOURCE=..\..\..\Sources\RedManager.h
# End Source File
# Begin Source File

SOURCE=..\..\..\Sources\simpleDPEWrapper.cpp
# End Source File
# Begin Source File

SOURCE=..\..\..\Sources\simpleDPEWrapper.h
# End Source File
# End Target
# End Project
