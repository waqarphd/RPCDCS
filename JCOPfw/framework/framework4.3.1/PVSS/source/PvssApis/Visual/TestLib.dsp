# Microsoft Developer Studio Project File - Name="TestLib" - Package Owner=<4>
# Microsoft Developer Studio Generated Build File, Format Version 6.00
# ** DO NOT EDIT **

# TARGTYPE "Win32 (x86) Console Application" 0x0103

CFG=TestLib - Win32 Debug
!MESSAGE This is not a valid makefile. To build this project using NMAKE,
!MESSAGE use the Export Makefile command and run
!MESSAGE 
!MESSAGE NMAKE /f "TestLib.mak".
!MESSAGE 
!MESSAGE You can specify a configuration when running NMAKE
!MESSAGE by defining the macro CFG on the command line. For example:
!MESSAGE 
!MESSAGE NMAKE /f "TestLib.mak" CFG="TestLib - Win32 Debug"
!MESSAGE 
!MESSAGE Possible choices for configuration are:
!MESSAGE 
!MESSAGE "TestLib - Win32 Release" (based on "Win32 (x86) Console Application")
!MESSAGE "TestLib - Win32 Debug" (based on "Win32 (x86) Console Application")
!MESSAGE 

# Begin Project
# PROP AllowPerConfigDependencies 0
# PROP Scc_ProjName ""
# PROP Scc_LocalPath ""
CPP=cl.exe
F90=df.exe
RSC=rc.exe

!IF  "$(CFG)" == "TestLib - Win32 Release"

# PROP BASE Use_MFC 0
# PROP BASE Use_Debug_Libraries 0
# PROP BASE Output_Dir "Release"
# PROP BASE Intermediate_Dir "Release"
# PROP BASE Target_Dir ""
# PROP Use_MFC 0
# PROP Use_Debug_Libraries 0
# PROP Output_Dir "../bin"
# PROP Intermediate_Dir "../tmp"
# PROP Ignore_Export_Lib 0
# PROP Target_Dir ""
# ADD BASE F90 /compile_only /include:"Release/" /nologo
# ADD F90 /compile_only /include:"Release/" /nologo
# ADD BASE CPP /nologo /W3 /GX /O2 /D "WIN32" /D "NDEBUG" /D "_CONSOLE" /D "_MBCS" /YX /FD /c
# ADD CPP /nologo /Zp4 /W3 /GX /Zi /O2 /I "..\src" /I "$(API_ROOT)\include\winnt\pvssincl" /I "$(API_ROOT)\include\Basics\Utilities" /I "$(API_ROOT)\include\Basics\Variables" /I "$(API_ROOT)\include\Basics\NoPosix" /I "$(API_ROOT)\include\winnt\BCM\PORT" /I "$(API_ROOT)\include\BCM\PORT" /I "$(API_ROOT)\include\BCMNew" /I "$(API_ROOT)\include\Booch" /I "$(API_ROOT)\include\Configs" /I "$(API_ROOT)\include\Datapoint" /I "$(API_ROOT)\include\Messages" /I "$(API_ROOT)\include\Manager" /I "$(DIMDIR)\dim" /FI"$(API_ROOT)\include\winnt\win32.h" /D "WIN32" /D "NDEBUG" /D "IS_MSWIN__" /D "_EXCURSION" /D "bcm_boolean_h" /D "FUNCPROTO" /D "_CONSOLE" /D "_MBCS" /YX /FD /c
# ADD BASE RSC /l 0x409 /d "NDEBUG"
# ADD RSC /l 0x409 /d "NDEBUG"
BSC32=bscmake.exe
# ADD BASE BSC32 /nologo
# ADD BSC32 /nologo
LINK32=link.exe
# ADD BASE LINK32 kernel32.lib user32.lib gdi32.lib winspool.lib comdlg32.lib advapi32.lib shell32.lib ole32.lib oleaut32.lib uuid.lib odbc32.lib odbccp32.lib /nologo /subsystem:console /machine:I386
# ADD LINK32 $(API_ROOT)\lib.winnt\libManager.lib $(API_ROOT)\lib.winnt\libMessages.lib $(API_ROOT)\lib.winnt\libDatapoint.lib $(API_ROOT)\lib.winnt\libBasics.lib $(API_ROOT)\lib.winnt\bcm.lib wsock32.lib user32.lib advapi32.lib netapi32.lib $(API_ROOT)\lib.winnt\libConfigs.lib ../bin/ApiLib.lib $(DIMDIR)\bin\dim.lib kernel32.lib user32.lib gdi32.lib winspool.lib comdlg32.lib advapi32.lib shell32.lib ole32.lib oleaut32.lib uuid.lib odbc32.lib odbccp32.lib /nologo /subsystem:console /pdb:none /machine:I386

!ELSEIF  "$(CFG)" == "TestLib - Win32 Debug"

# PROP BASE Use_MFC 0
# PROP BASE Use_Debug_Libraries 1
# PROP BASE Output_Dir "Debug"
# PROP BASE Intermediate_Dir "Debug"
# PROP BASE Target_Dir ""
# PROP Use_MFC 0
# PROP Use_Debug_Libraries 1
# PROP Output_Dir "../bin"
# PROP Intermediate_Dir "../tmp"
# PROP Ignore_Export_Lib 0
# PROP Target_Dir ""
# ADD BASE F90 /compile_only /debug:full /include:"Debug/" /nologo
# ADD F90 /compile_only /debug:full /include:"exe/" /nologo
# ADD BASE CPP /nologo /W3 /Gm /GX /Zi /Od /D "WIN32" /D "_DEBUG" /D "_CONSOLE" /D "_MBCS" /YX /FD /c
# ADD CPP /nologo /Zp4 /MD /W3 /Zi /I "..\src" /I "$(API_ROOT)\include\winnt\pvssincl" /I "$(API_ROOT)\include\Basics\Utilities" /I "$(API_ROOT)\include\Basics\Variables" /I "$(API_ROOT)\include\Basics\NoPosix" /I "$(API_ROOT)\include\winnt\BCM\PORT" /I "$(API_ROOT)\include\BCM\PORT" /I "$(API_ROOT)\include\BCMNew" /I "$(API_ROOT)\include\Booch" /I "$(API_ROOT)\include\Configs" /I "$(API_ROOT)\include\Datapoint" /I "$(API_ROOT)\include\Messages" /I "$(API_ROOT)\include\Manager" /I "$(DIMDIR)\dim" /FI"$(API_ROOT)\include\winnt\win32.h" /D "WIN32" /D "_DEBUG" /D "IS_MSWIN__" /D "_EXCURSION" /D "bcm_boolean_h" /D "FUNCPROTO" /c
# ADD BASE RSC /l 0x409 /d "_DEBUG"
# ADD RSC /l 0x409 /d "_DEBUG"
BSC32=bscmake.exe
# ADD BASE BSC32 /nologo
# ADD BSC32 /nologo
LINK32=link.exe
# ADD BASE LINK32 kernel32.lib user32.lib gdi32.lib winspool.lib comdlg32.lib advapi32.lib shell32.lib ole32.lib oleaut32.lib uuid.lib odbc32.lib odbccp32.lib /nologo /subsystem:console /debug /machine:I386 /pdbtype:sept
# ADD LINK32 $(API_ROOT)\lib.winnt\libManager.lib $(API_ROOT)\lib.winnt\libMessages.lib $(API_ROOT)\lib.winnt\libDatapoint.lib $(API_ROOT)\lib.winnt\libBasics.lib $(API_ROOT)\lib.winnt\bcm.lib ../bin/ApiLib.lib wsock32.lib user32.lib advapi32.lib netapi32.lib $(API_ROOT)\lib.winnt\libConfigs.lib $(DIMDIR)\bin\dim.lib /nologo /subsystem:console /incremental:no /debug /machine:I386 /nodefaultlib:"libc.lib" /pdbtype:sept
# SUBTRACT LINK32 /pdb:none

!ENDIF 

# Begin Target

# Name "TestLib - Win32 Release"
# Name "TestLib - Win32 Debug"
# Begin Source File

SOURCE=..\..\dim\dim\dllist.hxx
# End Source File
# Begin Source File

SOURCE=..\src\TestLib.cxx
# End Source File
# End Target
# End Project
