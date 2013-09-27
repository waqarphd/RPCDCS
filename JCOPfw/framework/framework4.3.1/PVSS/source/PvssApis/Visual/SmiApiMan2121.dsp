# Microsoft Developer Studio Project File - Name="SmiApiMan" - Package Owner=<4>
# Microsoft Developer Studio Generated Build File, Format Version 6.00
# ** DO NOT EDIT **

# TARGTYPE "Win32 (x86) Console Application" 0x0103

CFG=SmiApiMan - Win32 Debug
!MESSAGE This is not a valid makefile. To build this project using NMAKE,
!MESSAGE use the Export Makefile command and run
!MESSAGE 
!MESSAGE NMAKE /f "SmiApiMan212.mak".
!MESSAGE 
!MESSAGE You can specify a configuration when running NMAKE
!MESSAGE by defining the macro CFG on the command line. For example:
!MESSAGE 
!MESSAGE NMAKE /f "SmiApiMan212.mak" CFG="SmiApiMan - Win32 Debug"
!MESSAGE 
!MESSAGE Possible choices for configuration are:
!MESSAGE 
!MESSAGE "SmiApiMan - Win32 Release" (based on "Win32 (x86) Console Application")
!MESSAGE "SmiApiMan - Win32 Debug" (based on "Win32 (x86) Console Application")
!MESSAGE 

# Begin Project
# PROP AllowPerConfigDependencies 0
# PROP Scc_ProjName ""
# PROP Scc_LocalPath ""
CPP=cl.exe
F90=df.exe
RSC=rc.exe

!IF  "$(CFG)" == "SmiApiMan - Win32 Release"

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
# ADD CPP /nologo /Zp4 /MD /W3 /Zi /I "..\src" /I "$(API_ROOT)\include\winnt\pvssincl" /I "$(API_ROOT)\include\Basics\Utilities" /I "$(API_ROOT)\include\Basics\Variables" /I "$(API_ROOT)\include\Basics\NoPosix" /I "$(API_ROOT)\include\winnt\BCM\PORT" /I "$(API_ROOT)\include\BCM\PORT" /I "$(API_ROOT)\include\BCM\BCM" /I "$(API_ROOT)\include\Booch" /I "$(API_ROOT)\include\Configs" /I "$(API_ROOT)\include\Datapoint" /I "$(API_ROOT)\include\Messages" /I "$(API_ROOT)\include\Manager" /I "$(SMIDIR)\smixx" /I "$(DIMDIR)\dim" /FI"$(API_ROOT)\include\winnt\win32.h" /D "WIN32" /D "IS_MSWIN__" /D "_EXCURSION" /D "bcm_boolean_h" /D "FUNCPROTO" /FR /c
# ADD BASE RSC /l 0x409 /d "NDEBUG"
# ADD RSC /l 0x409 /d "NDEBUG"
BSC32=bscmake.exe
# ADD BASE BSC32 /nologo
# ADD BSC32 /nologo
LINK32=link.exe
# ADD BASE LINK32 kernel32.lib user32.lib gdi32.lib winspool.lib comdlg32.lib advapi32.lib shell32.lib ole32.lib oleaut32.lib uuid.lib odbc32.lib odbccp32.lib /nologo /subsystem:console /machine:I386
# ADD LINK32 $(API_ROOT)\lib.winnt\libManager.lib $(API_ROOT)\lib.winnt\libMessages.lib $(API_ROOT)\lib.winnt\libDatapoint.lib $(API_ROOT)\lib.winnt\libBasics.lib $(API_ROOT)\lib.winnt\bcm.lib $(API_ROOT)\lib.winnt\port.lib wsock32.lib user32.lib advapi32.lib netapi32.lib $(API_ROOT)\lib.winnt\libConfigs.lib $(SMIDIR)\bin\smiuirtl.lib $(SMIDIR)\bin\smirtl.lib $(DIMDIR)\bin\dim.lib kernel32.lib user32.lib gdi32.lib winspool.lib comdlg32.lib advapi32.lib shell32.lib ole32.lib oleaut32.lib uuid.lib odbc32.lib odbccp32.lib /nologo /subsystem:console /pdb:none /machine:I386 /out:"../bin/PVSS00smi2.12.1.exe"

!ELSEIF  "$(CFG)" == "SmiApiMan - Win32 Debug"

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
# ADD CPP /nologo /Zp4 /MD /W3 /Zi /I "..\src" /I "$(API_ROOT)\include\winnt\pvssincl" /I "$(API_ROOT)\include\Basics\Utilities" /I "$(API_ROOT)\include\Basics\Variables" /I "$(API_ROOT)\include\Basics\NoPosix" /I "$(API_ROOT)\include\winnt\BCM\PORT" /I "$(API_ROOT)\include\BCM\PORT" /I "$(API_ROOT)\include\BCM\BCM" /I "$(API_ROOT)\include\Booch" /I "$(API_ROOT)\include\Configs" /I "$(API_ROOT)\include\Datapoint" /I "$(API_ROOT)\include\Messages" /I "$(API_ROOT)\include\Manager" /I "$(SMIDIR)\smixx" /I "$(DIMDIR)\dim" /FI"$(API_ROOT)\include\winnt\win32.h" /D "WIN32" /D "_DEBUG" /D "IS_MSWIN__" /D "_EXCURSION" /D "bcm_boolean_h" /D "FUNCPROTO" /FR /c
# ADD BASE RSC /l 0x409 /d "_DEBUG"
# ADD RSC /l 0x409 /d "_DEBUG"
BSC32=bscmake.exe
# ADD BASE BSC32 /nologo
# ADD BSC32 /nologo
LINK32=link.exe
# ADD BASE LINK32 kernel32.lib user32.lib gdi32.lib winspool.lib comdlg32.lib advapi32.lib shell32.lib ole32.lib oleaut32.lib uuid.lib odbc32.lib odbccp32.lib /nologo /subsystem:console /debug /machine:I386 /pdbtype:sept
# ADD LINK32 $(API_ROOT)\lib.winnt\libManager.lib $(API_ROOT)\lib.winnt\libMessages.lib $(API_ROOT)\lib.winnt\libDatapoint.lib $(API_ROOT)\lib.winnt\libBasics.lib $(API_ROOT)\lib.winnt\bcm.lib $(API_ROOT)\lib.winnt\port.lib wsock32.lib user32.lib advapi32.lib netapi32.lib $(API_ROOT)\lib.winnt\libConfigs.lib $(SMIDIR)\bin\smiuirtl.lib $(SMIDIR)\bin\smirtl.lib $(DIMDIR)\bin\dim.lib /nologo /subsystem:console /debug /machine:I386 /nodefaultlib:"libc.lib" /out:"../bin/PVSS00smi2.12.1.exe"
# SUBTRACT LINK32 /pdb:none

!ENDIF 

# Begin Target

# Name "SmiApiMan - Win32 Release"
# Name "SmiApiMan - Win32 Debug"
# Begin Source File

SOURCE=..\src\ApiLib.cxx
DEP_CPP_APILI=\
	"..\..\dim\dim\dic.h"\
	"..\..\dim\dim\dim.hxx"\
	"..\..\dim\dim\dim_common.h"\
	"..\..\dim\dim\dim_core.hxx"\
	"..\..\dim\dim\dis.h"\
	"..\..\dim\dim\dis.hxx"\
	"..\..\dim\dim\dllist.hxx"\
	"..\..\dim\dim\sllist.hxx"\
	"..\..\ETM\PVSS2\2.12.1\api\include\Basics\NoPosix\FileSys.hxx"\
	"..\..\ETM\PVSS2\2.12.1\api\include\Basics\Utilities\AlertAttrList.hxx"\
	"..\..\ETM\PVSS2\2.12.1\api\include\Basics\Utilities\AlertIdentifier.hxx"\
	"..\..\ETM\PVSS2\2.12.1\api\include\Basics\Utilities\AlertList.hxx"\
	"..\..\ETM\PVSS2\2.12.1\api\include\Basics\Utilities\AlertTime.hxx"\
	"..\..\ETM\PVSS2\2.12.1\api\include\Basics\Utilities\Allocator.hxx"\
	"..\..\ETM\PVSS2\2.12.1\api\include\Basics\Utilities\BCTime.h"\
	"..\..\ETM\PVSS2\2.12.1\api\include\Basics\Utilities\CharString.hxx"\
	"..\..\ETM\PVSS2\2.12.1\api\include\Basics\Utilities\ConfigAndDpDiag.hxx"\
	"..\..\ETM\PVSS2\2.12.1\api\include\Basics\Utilities\DpConfigNrType.hxx"\
	"..\..\ETM\PVSS2\2.12.1\api\include\Basics\Utilities\DpElementType.hxx"\
	"..\..\ETM\PVSS2\2.12.1\api\include\Basics\Utilities\DpIdentifier.hxx"\
	"..\..\ETM\PVSS2\2.12.1\api\include\Basics\Utilities\DpIdentList.hxx"\
	"..\..\ETM\PVSS2\2.12.1\api\include\Basics\Utilities\DpIdentListItem.hxx"\
	"..\..\ETM\PVSS2\2.12.1\api\include\Basics\Utilities\DpIdValueList.hxx"\
	"..\..\ETM\PVSS2\2.12.1\api\include\Basics\Utilities\DpTypes.hxx"\
	"..\..\ETM\PVSS2\2.12.1\api\include\Basics\Utilities\DpVCItem.hxx"\
	"..\..\ETM\PVSS2\2.12.1\api\include\Basics\Utilities\DynPtrArray.hxx"\
	"..\..\ETM\PVSS2\2.12.1\api\include\Basics\Utilities\DynPtrArrayTpl.hxx"\
	"..\..\ETM\PVSS2\2.12.1\api\include\Basics\Utilities\ErrClass.hxx"\
	"..\..\ETM\PVSS2\2.12.1\api\include\Basics\Utilities\ErrHdl.hxx"\
	"..\..\ETM\PVSS2\2.12.1\api\include\Basics\Utilities\LangText.hxx"\
	"..\..\ETM\PVSS2\2.12.1\api\include\Basics\Utilities\ManagerIdentifier.hxx"\
	"..\..\ETM\PVSS2\2.12.1\api\include\Basics\Utilities\MessageDiag.hxx"\
	"..\..\ETM\PVSS2\2.12.1\api\include\Basics\Utilities\Pathes.hxx"\
	"..\..\ETM\PVSS2\2.12.1\api\include\Basics\Utilities\PathesV1.hxx"\
	"..\..\ETM\PVSS2\2.12.1\api\include\Basics\Utilities\PathesV2.hxx"\
	"..\..\ETM\PVSS2\2.12.1\api\include\Basics\Utilities\ProjDirs.hxx"\
	"..\..\ETM\PVSS2\2.12.1\api\include\Basics\Utilities\PtrList.hxx"\
	"..\..\ETM\PVSS2\2.12.1\api\include\Basics\Utilities\PtrList_Inl.hxx"\
	"..\..\ETM\PVSS2\2.12.1\api\include\Basics\Utilities\PtrListItem.hxx"\
	"..\..\ETM\PVSS2\2.12.1\api\include\Basics\Utilities\PVSSFileSys.hxx"\
	"..\..\ETM\PVSS2\2.12.1\api\include\Basics\Utilities\ResourceDiag.hxx"\
	"..\..\ETM\PVSS2\2.12.1\api\include\Basics\Utilities\Resources.hxx"\
	"..\..\ETM\PVSS2\2.12.1\api\include\Basics\Utilities\Types.hxx"\
	"..\..\ETM\PVSS2\2.12.1\api\include\Basics\Variables\Bit32Var.hxx"\
	"..\..\ETM\PVSS2\2.12.1\api\include\Basics\Variables\BitVar.hxx"\
	"..\..\ETM\PVSS2\2.12.1\api\include\Basics\Variables\DynVar.hxx"\
	"..\..\ETM\PVSS2\2.12.1\api\include\Basics\Variables\FloatVar.hxx"\
	"..\..\ETM\PVSS2\2.12.1\api\include\Basics\Variables\IntegerVar.hxx"\
	"..\..\ETM\PVSS2\2.12.1\api\include\Basics\Variables\LangTextVar.hxx"\
	"..\..\ETM\PVSS2\2.12.1\api\include\Basics\Variables\RecVar.hxx"\
	"..\..\ETM\PVSS2\2.12.1\api\include\Basics\Variables\TextVar.hxx"\
	"..\..\ETM\PVSS2\2.12.1\api\include\Basics\Variables\TimeVar.hxx"\
	"..\..\ETM\PVSS2\2.12.1\api\include\Basics\Variables\UIntegerVar.hxx"\
	"..\..\ETM\PVSS2\2.12.1\api\include\Basics\Variables\Variable.hxx"\
	"..\..\ETM\PVSS2\2.12.1\api\include\BCM\BCM\ItcIOHandler.H"\
	"..\..\ETM\PVSS2\2.12.1\api\include\BCM\PORT\JCFPortComp.h"\
	"..\..\ETM\PVSS2\2.12.1\api\include\BCM\PORT\JCFPortConf.h"\
	"..\..\ETM\PVSS2\2.12.1\api\include\BCM\PORT\JCFPortMod.h"\
	"..\..\ETM\PVSS2\2.12.1\api\include\BCM\PORT\JCFPortOS.h"\
	"..\..\ETM\PVSS2\2.12.1\api\include\BCM\PORT\pcinc\un.h"\
	"..\..\ETM\PVSS2\2.12.1\api\include\Configs\DpConfig.hxx"\
	"..\..\ETM\PVSS2\2.12.1\api\include\Datapoint\AliasTable.hxx"\
	"..\..\ETM\PVSS2\2.12.1\api\include\Datapoint\AliasTableItem.hxx"\
	"..\..\ETM\PVSS2\2.12.1\api\include\Datapoint\DpIdentification.hxx"\
	"..\..\ETM\PVSS2\2.12.1\api\include\Datapoint\DpIdentificationProSystem.hxx"\
	"..\..\ETM\PVSS2\2.12.1\api\include\Datapoint\DpIdentificationResultType.hxx"\
	"..\..\ETM\PVSS2\2.12.1\api\include\Datapoint\DpNameDpIdCache.hxx"\
	"..\..\ETM\PVSS2\2.12.1\api\include\Datapoint\DpSymIdentifier.hxx"\
	"..\..\ETM\PVSS2\2.12.1\api\include\Datapoint\DpType.hxx"\
	"..\..\ETM\PVSS2\2.12.1\api\include\Datapoint\DpTypeContainer.hxx"\
	"..\..\ETM\PVSS2\2.12.1\api\include\Datapoint\DpTypeNode.hxx"\
	"..\..\ETM\PVSS2\2.12.1\api\include\Datapoint\FixedNumbersTable.hxx"\
	"..\..\ETM\PVSS2\2.12.1\api\include\Datapoint\FixedNumbersTableItem.hxx"\
	"..\..\ETM\PVSS2\2.12.1\api\include\Datapoint\LanguageTable.hxx"\
	"..\..\ETM\PVSS2\2.12.1\api\include\Datapoint\LanguageTableItem.hxx"\
	"..\..\ETM\PVSS2\2.12.1\api\include\Datapoint\PathItem.hxx"\
	"..\..\ETM\PVSS2\2.12.1\api\include\Manager\DiagConfigAndDpItcIOHandler.hxx"\
	"..\..\ETM\PVSS2\2.12.1\api\include\Manager\DiagHotLinkWaitForAnswer.hxx"\
	"..\..\ETM\PVSS2\2.12.1\api\include\Manager\DiagItcIOHandler.hxx"\
	"..\..\ETM\PVSS2\2.12.1\api\include\Manager\DiagMsgItcIOHandler.hxx"\
	"..\..\ETM\PVSS2\2.12.1\api\include\Manager\HotLinkList.hxx"\
	"..\..\ETM\PVSS2\2.12.1\api\include\Manager\HotLinkListIterator.hxx"\
	"..\..\ETM\PVSS2\2.12.1\api\include\Manager\HotLinkWaitForAnswer.hxx"\
	"..\..\ETM\PVSS2\2.12.1\api\include\Manager\Manager.hxx"\
	"..\..\ETM\PVSS2\2.12.1\api\include\Manager\UserTable.hxx"\
	"..\..\ETM\PVSS2\2.12.1\api\include\Manager\WaitForAnswer.hxx"\
	"..\..\ETM\PVSS2\2.12.1\api\include\Messages\AnswerGroup.hxx"\
	"..\..\ETM\PVSS2\2.12.1\api\include\Messages\AnswerItem.hxx"\
	"..\..\ETM\PVSS2\2.12.1\api\include\Messages\DpHLGroup.hxx"\
	"..\..\ETM\PVSS2\2.12.1\api\include\Messages\DpICGroup.hxx"\
	"..\..\ETM\PVSS2\2.12.1\api\include\Messages\DpICItem.hxx"\
	"..\..\ETM\PVSS2\2.12.1\api\include\Messages\DpMsg.hxx"\
	"..\..\ETM\PVSS2\2.12.1\api\include\Messages\DpMsgAnswer.hxx"\
	"..\..\ETM\PVSS2\2.12.1\api\include\Messages\DpMsgHotLink.hxx"\
	"..\..\ETM\PVSS2\2.12.1\api\include\Messages\Msg.hxx"\
	"..\..\ETM\PVSS2\2.12.1\api\include\Messages\NameServerSysMsg.hxx"\
	"..\..\ETM\PVSS2\2.12.1\api\include\Messages\StartDpInitSysMsg.hxx"\
	"..\..\ETM\PVSS2\2.12.1\api\include\Messages\SysMsg.hxx"\
	"..\..\ETM\PVSS2\2.12.1\api\include\winnt\pvssincl\dirent.h"\
	"..\..\ETM\PVSS2\2.12.1\api\include\winnt\pvssincl\netdb.h"\
	"..\..\ETM\PVSS2\2.12.1\api\include\winnt\pvssincl\netinet\in.h"\
	"..\..\ETM\PVSS2\2.12.1\api\include\winnt\pvssincl\strstream.h"\
	"..\..\ETM\PVSS2\2.12.1\api\include\winnt\pvssincl\sys\ioctl.h"\
	"..\..\ETM\PVSS2\2.12.1\api\include\winnt\pvssincl\sys\socket.h"\
	"..\..\ETM\PVSS2\2.12.1\api\include\winnt\pvssincl\sys\time.h"\
	"..\..\ETM\PVSS2\2.12.1\api\include\winnt\pvssincl\unistd.h"\
	"..\src\ApiLib.hxx"\
	
# End Source File
# Begin Source File

SOURCE=..\src\SmiApiMan.cxx
DEP_CPP_SMIAP=\
	"..\..\dim\dim\dic.h"\
	"..\..\dim\dim\dic.hxx"\
	"..\..\dim\dim\dim.hxx"\
	"..\..\dim\dim\dim_common.h"\
	"..\..\dim\dim\dim_core.hxx"\
	"..\..\dim\dim\dis.h"\
	"..\..\dim\dim\dis.hxx"\
	"..\..\dim\dim\dllist.hxx"\
	"..\..\dim\dim\sllist.hxx"\
	"..\..\dim\dim\tokenstring.hxx"\
	"..\..\ETM\PVSS2\2.12.1\api\include\Basics\NoPosix\FileSys.hxx"\
	"..\..\ETM\PVSS2\2.12.1\api\include\Basics\Utilities\AlertAttrList.hxx"\
	"..\..\ETM\PVSS2\2.12.1\api\include\Basics\Utilities\AlertIdentifier.hxx"\
	"..\..\ETM\PVSS2\2.12.1\api\include\Basics\Utilities\AlertList.hxx"\
	"..\..\ETM\PVSS2\2.12.1\api\include\Basics\Utilities\AlertTime.hxx"\
	"..\..\ETM\PVSS2\2.12.1\api\include\Basics\Utilities\Allocator.hxx"\
	"..\..\ETM\PVSS2\2.12.1\api\include\Basics\Utilities\BCTime.h"\
	"..\..\ETM\PVSS2\2.12.1\api\include\Basics\Utilities\CharString.hxx"\
	"..\..\ETM\PVSS2\2.12.1\api\include\Basics\Utilities\ConfigAndDpDiag.hxx"\
	"..\..\ETM\PVSS2\2.12.1\api\include\Basics\Utilities\DpConfigNrType.hxx"\
	"..\..\ETM\PVSS2\2.12.1\api\include\Basics\Utilities\DpElementType.hxx"\
	"..\..\ETM\PVSS2\2.12.1\api\include\Basics\Utilities\DpIdentifier.hxx"\
	"..\..\ETM\PVSS2\2.12.1\api\include\Basics\Utilities\DpIdentList.hxx"\
	"..\..\ETM\PVSS2\2.12.1\api\include\Basics\Utilities\DpIdentListItem.hxx"\
	"..\..\ETM\PVSS2\2.12.1\api\include\Basics\Utilities\DpIdValueList.hxx"\
	"..\..\ETM\PVSS2\2.12.1\api\include\Basics\Utilities\DpTypes.hxx"\
	"..\..\ETM\PVSS2\2.12.1\api\include\Basics\Utilities\DpVCItem.hxx"\
	"..\..\ETM\PVSS2\2.12.1\api\include\Basics\Utilities\DynPtrArray.hxx"\
	"..\..\ETM\PVSS2\2.12.1\api\include\Basics\Utilities\DynPtrArrayTpl.hxx"\
	"..\..\ETM\PVSS2\2.12.1\api\include\Basics\Utilities\ErrClass.hxx"\
	"..\..\ETM\PVSS2\2.12.1\api\include\Basics\Utilities\ErrHdl.hxx"\
	"..\..\ETM\PVSS2\2.12.1\api\include\Basics\Utilities\LangText.hxx"\
	"..\..\ETM\PVSS2\2.12.1\api\include\Basics\Utilities\ManagerIdentifier.hxx"\
	"..\..\ETM\PVSS2\2.12.1\api\include\Basics\Utilities\MessageDiag.hxx"\
	"..\..\ETM\PVSS2\2.12.1\api\include\Basics\Utilities\Pathes.hxx"\
	"..\..\ETM\PVSS2\2.12.1\api\include\Basics\Utilities\PathesV1.hxx"\
	"..\..\ETM\PVSS2\2.12.1\api\include\Basics\Utilities\PathesV2.hxx"\
	"..\..\ETM\PVSS2\2.12.1\api\include\Basics\Utilities\ProjDirs.hxx"\
	"..\..\ETM\PVSS2\2.12.1\api\include\Basics\Utilities\PtrList.hxx"\
	"..\..\ETM\PVSS2\2.12.1\api\include\Basics\Utilities\PtrList_Inl.hxx"\
	"..\..\ETM\PVSS2\2.12.1\api\include\Basics\Utilities\PtrListItem.hxx"\
	"..\..\ETM\PVSS2\2.12.1\api\include\Basics\Utilities\PVSSFileSys.hxx"\
	"..\..\ETM\PVSS2\2.12.1\api\include\Basics\Utilities\ResourceDiag.hxx"\
	"..\..\ETM\PVSS2\2.12.1\api\include\Basics\Utilities\Resources.hxx"\
	"..\..\ETM\PVSS2\2.12.1\api\include\Basics\Utilities\Types.hxx"\
	"..\..\ETM\PVSS2\2.12.1\api\include\Basics\Variables\Bit32Var.hxx"\
	"..\..\ETM\PVSS2\2.12.1\api\include\Basics\Variables\BitVar.hxx"\
	"..\..\ETM\PVSS2\2.12.1\api\include\Basics\Variables\DynVar.hxx"\
	"..\..\ETM\PVSS2\2.12.1\api\include\Basics\Variables\FloatVar.hxx"\
	"..\..\ETM\PVSS2\2.12.1\api\include\Basics\Variables\IntegerVar.hxx"\
	"..\..\ETM\PVSS2\2.12.1\api\include\Basics\Variables\LangTextVar.hxx"\
	"..\..\ETM\PVSS2\2.12.1\api\include\Basics\Variables\RecVar.hxx"\
	"..\..\ETM\PVSS2\2.12.1\api\include\Basics\Variables\TextVar.hxx"\
	"..\..\ETM\PVSS2\2.12.1\api\include\Basics\Variables\TimeVar.hxx"\
	"..\..\ETM\PVSS2\2.12.1\api\include\Basics\Variables\UIntegerVar.hxx"\
	"..\..\ETM\PVSS2\2.12.1\api\include\Basics\Variables\Variable.hxx"\
	"..\..\ETM\PVSS2\2.12.1\api\include\BCM\BCM\ItcIOHandler.H"\
	"..\..\ETM\PVSS2\2.12.1\api\include\BCM\PORT\JCFPortComp.h"\
	"..\..\ETM\PVSS2\2.12.1\api\include\BCM\PORT\JCFPortConf.h"\
	"..\..\ETM\PVSS2\2.12.1\api\include\BCM\PORT\JCFPortMod.h"\
	"..\..\ETM\PVSS2\2.12.1\api\include\BCM\PORT\JCFPortOS.h"\
	"..\..\ETM\PVSS2\2.12.1\api\include\BCM\PORT\pcinc\un.h"\
	"..\..\ETM\PVSS2\2.12.1\api\include\Configs\DpConfig.hxx"\
	"..\..\ETM\PVSS2\2.12.1\api\include\Datapoint\AliasTable.hxx"\
	"..\..\ETM\PVSS2\2.12.1\api\include\Datapoint\AliasTableItem.hxx"\
	"..\..\ETM\PVSS2\2.12.1\api\include\Datapoint\DpIdentification.hxx"\
	"..\..\ETM\PVSS2\2.12.1\api\include\Datapoint\DpIdentificationProSystem.hxx"\
	"..\..\ETM\PVSS2\2.12.1\api\include\Datapoint\DpIdentificationResultType.hxx"\
	"..\..\ETM\PVSS2\2.12.1\api\include\Datapoint\DpNameDpIdCache.hxx"\
	"..\..\ETM\PVSS2\2.12.1\api\include\Datapoint\DpSymIdentifier.hxx"\
	"..\..\ETM\PVSS2\2.12.1\api\include\Datapoint\DpType.hxx"\
	"..\..\ETM\PVSS2\2.12.1\api\include\Datapoint\DpTypeContainer.hxx"\
	"..\..\ETM\PVSS2\2.12.1\api\include\Datapoint\DpTypeNode.hxx"\
	"..\..\ETM\PVSS2\2.12.1\api\include\Datapoint\FixedNumbersTable.hxx"\
	"..\..\ETM\PVSS2\2.12.1\api\include\Datapoint\FixedNumbersTableItem.hxx"\
	"..\..\ETM\PVSS2\2.12.1\api\include\Datapoint\LanguageTable.hxx"\
	"..\..\ETM\PVSS2\2.12.1\api\include\Datapoint\LanguageTableItem.hxx"\
	"..\..\ETM\PVSS2\2.12.1\api\include\Datapoint\PathItem.hxx"\
	"..\..\ETM\PVSS2\2.12.1\api\include\Manager\DiagConfigAndDpItcIOHandler.hxx"\
	"..\..\ETM\PVSS2\2.12.1\api\include\Manager\DiagHotLinkWaitForAnswer.hxx"\
	"..\..\ETM\PVSS2\2.12.1\api\include\Manager\DiagItcIOHandler.hxx"\
	"..\..\ETM\PVSS2\2.12.1\api\include\Manager\DiagMsgItcIOHandler.hxx"\
	"..\..\ETM\PVSS2\2.12.1\api\include\Manager\HotLinkList.hxx"\
	"..\..\ETM\PVSS2\2.12.1\api\include\Manager\HotLinkListIterator.hxx"\
	"..\..\ETM\PVSS2\2.12.1\api\include\Manager\HotLinkWaitForAnswer.hxx"\
	"..\..\ETM\PVSS2\2.12.1\api\include\Manager\Manager.hxx"\
	"..\..\ETM\PVSS2\2.12.1\api\include\Manager\UserTable.hxx"\
	"..\..\ETM\PVSS2\2.12.1\api\include\Manager\WaitForAnswer.hxx"\
	"..\..\ETM\PVSS2\2.12.1\api\include\Messages\AnswerGroup.hxx"\
	"..\..\ETM\PVSS2\2.12.1\api\include\Messages\AnswerItem.hxx"\
	"..\..\ETM\PVSS2\2.12.1\api\include\Messages\DpHLGroup.hxx"\
	"..\..\ETM\PVSS2\2.12.1\api\include\Messages\DpICGroup.hxx"\
	"..\..\ETM\PVSS2\2.12.1\api\include\Messages\DpICItem.hxx"\
	"..\..\ETM\PVSS2\2.12.1\api\include\Messages\DpMsg.hxx"\
	"..\..\ETM\PVSS2\2.12.1\api\include\Messages\DpMsgAnswer.hxx"\
	"..\..\ETM\PVSS2\2.12.1\api\include\Messages\DpMsgHotLink.hxx"\
	"..\..\ETM\PVSS2\2.12.1\api\include\Messages\Msg.hxx"\
	"..\..\ETM\PVSS2\2.12.1\api\include\Messages\NameServerSysMsg.hxx"\
	"..\..\ETM\PVSS2\2.12.1\api\include\Messages\StartDpInitSysMsg.hxx"\
	"..\..\ETM\PVSS2\2.12.1\api\include\Messages\SysMsg.hxx"\
	"..\..\ETM\PVSS2\2.12.1\api\include\winnt\pvssincl\dirent.h"\
	"..\..\ETM\PVSS2\2.12.1\api\include\winnt\pvssincl\netdb.h"\
	"..\..\ETM\PVSS2\2.12.1\api\include\winnt\pvssincl\netinet\in.h"\
	"..\..\ETM\PVSS2\2.12.1\api\include\winnt\pvssincl\strstream.h"\
	"..\..\ETM\PVSS2\2.12.1\api\include\winnt\pvssincl\sys\ioctl.h"\
	"..\..\ETM\PVSS2\2.12.1\api\include\winnt\pvssincl\sys\socket.h"\
	"..\..\ETM\PVSS2\2.12.1\api\include\winnt\pvssincl\sys\time.h"\
	"..\..\ETM\PVSS2\2.12.1\api\include\winnt\pvssincl\unistd.h"\
	"..\..\smixx\smixx\smirtl.h"\
	"..\..\smixx\smixx\smirtl.hxx"\
	"..\..\smixx\smixx\smirtl_core.hxx"\
	"..\..\smixx\smixx\smiuirtl.h"\
	"..\..\smixx\smixx\smiuirtl.hxx"\
	"..\..\smixx\smixx\smiuirtl_core.hxx"\
	"..\src\ApiLib.hxx"\
	
# End Source File
# End Target
# End Project
