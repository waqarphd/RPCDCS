# Microsoft Developer Studio Project File - Name="FwUi" - Package Owner=<4>
# Microsoft Developer Studio Generated Build File, Format Version 6.00
# ** DO NOT EDIT **

# TARGTYPE "Win32 (x86) Dynamic-Link Library" 0x0102

CFG=FwUi - Win32 Debug
!MESSAGE This is not a valid makefile. To build this project using NMAKE,
!MESSAGE use the Export Makefile command and run
!MESSAGE 
!MESSAGE NMAKE /f "FwUi212.mak".
!MESSAGE 
!MESSAGE You can specify a configuration when running NMAKE
!MESSAGE by defining the macro CFG on the command line. For example:
!MESSAGE 
!MESSAGE NMAKE /f "FwUi212.mak" CFG="FwUi - Win32 Debug"
!MESSAGE 
!MESSAGE Possible choices for configuration are:
!MESSAGE 
!MESSAGE "FwUi - Win32 Release" (based on "Win32 (x86) Dynamic-Link Library")
!MESSAGE "FwUi - Win32 Debug" (based on "Win32 (x86) Dynamic-Link Library")
!MESSAGE 

# Begin Project
# PROP AllowPerConfigDependencies 0
# PROP Scc_ProjName ""
# PROP Scc_LocalPath ""
CPP=cl.exe
F90=df.exe
MTL=midl.exe
RSC=rc.exe

!IF  "$(CFG)" == "FwUi - Win32 Release"

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
# ADD BASE CPP /nologo /MT /W3 /GX /O2 /D "WIN32" /D "NDEBUG" /D "_WINDOWS" /YX /FD /c
# ADD CPP /nologo /Zp4 /MD /W3 /Zi /Od /I "." /I "$(API_ROOT)\include\winnt" /I "$(API_ROOT)\include\winnt\pvssincl" /I "$(API_ROOT)\include\Basics\Utilities" /I "$(API_ROOT)\include\Basics\Variables" /I "$(API_ROOT)\include\Basics\NoPosix" /I "$(API_ROOT)\include\winnt\BCM\PORT" /I "$(API_ROOT)\include\BCM\PORT" /I "$(API_ROOT)\include\BCM\BCM" /I "$(API_ROOT)\include\Configs" /I "$(API_ROOT)\include\Datapoint" /I "$(API_ROOT)\include\Messages" /I "$(API_ROOT)\include\Manager" /I "$(API_ROOT)\include\Ctrl" /I "$(SMIDIR)\smixx" /I "$(DIMDIR)\dim" /FI"$(API_ROOT)\include\winnt\win32.h" /D "WIN32" /D "IS_MSWIN__" /D "_EXCURSION" /D "bcm_boolean_h" /D "FUNCPROTO" /YX /FD /c
# ADD BASE MTL /nologo /D "NDEBUG" /mktyplib203 /o "NUL" /win32
# ADD MTL /nologo /D "NDEBUG" /mktyplib203 /o "NUL" /win32
# ADD BASE RSC /l 0x409 /d "NDEBUG"
# ADD RSC /l 0x409 /d "NDEBUG"
BSC32=bscmake.exe
# ADD BASE BSC32 /nologo
# ADD BSC32 /nologo
LINK32=link.exe
# ADD BASE LINK32 kernel32.lib user32.lib gdi32.lib winspool.lib comdlg32.lib advapi32.lib shell32.lib ole32.lib oleaut32.lib uuid.lib odbc32.lib odbccp32.lib /nologo /subsystem:windows /dll /machine:I386
# ADD LINK32 kernel32.lib user32.lib gdi32.lib winspool.lib comdlg32.lib advapi32.lib shell32.lib ole32.lib oleaut32.lib uuid.lib odbc32.lib odbccp32.lib wsock32.lib netapi32.lib user32.lib $(API_ROOT)\lib.winnt\libManager.lib $(API_ROOT)\lib.winnt\libMessages.lib $(API_ROOT)\lib.winnt\libDatapoint.lib $(API_ROOT)\lib.winnt\libBasics.lib $(API_ROOT)\lib.winnt\bcm.lib $(API_ROOT)\lib.winnt\port.lib $(API_ROOT)\lib.winnt\libConfigs.lib $(API_ROOT)\lib.winnt\libCtrl.lib $(SMIDIR)\bin\smiuirtl.lib $(DIMDIR)\bin\dim.lib /nologo /subsystem:windows /dll /pdb:none /machine:I386 /out:"../bin/FwUi2.12.1.dll"

!ELSEIF  "$(CFG)" == "FwUi - Win32 Debug"

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
# ADD BASE CPP /nologo /MTd /W3 /Gm /GX /Zi /Od /D "WIN32" /D "_DEBUG" /D "_WINDOWS" /YX /FD /c
# ADD CPP /nologo /Zp4 /MD /W3 /Zi /I "." /I "$(API_ROOT)\include\winnt" /I "$(API_ROOT)\include\winnt\pvssincl" /I "$(API_ROOT)\include\Basics\Utilities" /I "$(API_ROOT)\include\Basics\Variables" /I "$(API_ROOT)\include\Basics\NoPosix" /I "$(API_ROOT)\include\winnt\BCM\PORT" /I "$(API_ROOT)\include\BCM\PORT" /I "$(API_ROOT)\include\BCM\BCM" /I "$(API_ROOT)\include\Configs" /I "$(API_ROOT)\include\Datapoint" /I "$(API_ROOT)\include\Messages" /I "$(API_ROOT)\include\Manager" /I "$(API_ROOT)\include\Ctrl" /I "$(SMIDIR)\smixx" /I "$(DIMDIR)\dim" /FI"$(API_ROOT)\include\winnt\win32.h" /D "WIN32" /D "_DEBUG" /D "IS_MSWIN__" /D "_EXCURSION" /D "bcm_boolean_h" /D "FUNCPROTO" /YX /FD /c
# ADD BASE MTL /nologo /D "_DEBUG" /mktyplib203 /o "NUL" /win32
# ADD MTL /nologo /D "_DEBUG" /mktyplib203 /o "NUL" /win32
# ADD BASE RSC /l 0x409 /d "_DEBUG"
# ADD RSC /l 0x409 /d "_DEBUG"
BSC32=bscmake.exe
# ADD BASE BSC32 /nologo
# ADD BSC32 /nologo
LINK32=link.exe
# ADD BASE LINK32 kernel32.lib user32.lib gdi32.lib winspool.lib comdlg32.lib advapi32.lib shell32.lib ole32.lib oleaut32.lib uuid.lib odbc32.lib odbccp32.lib /nologo /subsystem:windows /dll /debug /machine:I386 /pdbtype:sept
# ADD LINK32 kernel32.lib user32.lib gdi32.lib winspool.lib comdlg32.lib advapi32.lib shell32.lib ole32.lib oleaut32.lib uuid.lib odbc32.lib odbccp32.lib wsock32.lib netapi32.lib user32.lib $(API_ROOT)\lib.winnt\libManager.lib $(API_ROOT)\lib.winnt\libMessages.lib $(API_ROOT)\lib.winnt\libDatapoint.lib $(API_ROOT)\lib.winnt\libBasics.lib $(API_ROOT)\lib.winnt\bcm.lib $(API_ROOT)\lib.winnt\port.lib $(API_ROOT)\lib.winnt\libConfigs.lib $(API_ROOT)\lib.winnt\libCtrl.lib $(SMIDIR)\bin\smiuirtl.lib $(DIMDIR)\bin\dim.lib /nologo /subsystem:windows /dll /incremental:no /debug /machine:I386 /out:"../bin/FwUi2.12.1.dll" /pdbtype:sept
# SUBTRACT LINK32 /pdb:none
# Begin Special Build Tool
SOURCE="$(InputPath)"
PostBuild_Cmds=copy D:\FwPvssDev\Libs\bin\FwUi.dll D:\Framework\bin\FwUi.dll
# End Special Build Tool

!ENDIF 

# Begin Target

# Name "FwUi - Win32 Release"
# Name "FwUi - Win32 Debug"
# Begin Source File

SOURCE=..\src\fwUiLib.cxx
# End Source File
# Begin Source File

SOURCE=..\src\fwUiLib.hxx
# End Source File
# End Target
# End Project
