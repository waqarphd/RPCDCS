# Microsoft Developer Studio Project File - Name="DIPManager" - Package Owner=<4>
# Microsoft Developer Studio Generated Build File, Format Version 6.00
# ** DO NOT EDIT **

# TARGTYPE "Win32 (x86) Console Application" 0x0103

CFG=DIPManager - Win32 Debug
!MESSAGE This is not a valid makefile. To build this project using NMAKE,
!MESSAGE use the Export Makefile command and run
!MESSAGE 
!MESSAGE NMAKE /f "DIPManager.mak".
!MESSAGE 
!MESSAGE You can specify a configuration when running NMAKE
!MESSAGE by defining the macro CFG on the command line. For example:
!MESSAGE 
!MESSAGE NMAKE /f "DIPManager.mak" CFG="DIPManager - Win32 Debug"
!MESSAGE 
!MESSAGE Possible choices for configuration are:
!MESSAGE 
!MESSAGE "DIPManager - Win32 Release" (based on "Win32 (x86) Console Application")
!MESSAGE "DIPManager - Win32 Debug" (based on "Win32 (x86) Console Application")
!MESSAGE 

# Begin Project
# PROP AllowPerConfigDependencies 0
# PROP Scc_ProjName ""
# PROP Scc_LocalPath ""
CPP=cl.exe
RSC=rc.exe

!IF  "$(CFG)" == "DIPManager - Win32 Release"

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
# ADD CPP /nologo /Zp4 /MD /W3 /Zi /I ".\\" /I "$(API_ROOT)\include\winnt\pvssincl" /I "$(API_ROOT)\include\Basics\Utilities" /I "$(API_ROOT)\include\Basics\Variables" /I "$(API_ROOT)\include\Basics\NoPosix" /I "$(API_ROOT)\include\Basics\DpBasics" /I "$(API_ROOT)\include\BCMNew" /I "$(API_ROOT)\include\Configs" /I "$(API_ROOT)\include\Datapoint" /I "$(API_ROOT)\include\Messages" /I "$(API_ROOT)\include\Manager" /FI"$(API_ROOT)\include\winnt\win32.h" /D "WIN32" /D "IS_MSWIN__" /D "_EXCURSION" /D "bcm_boolean_h" /D "FUNCPROTO" /FD /c
# ADD BASE RSC /l 0x407 /d "NDEBUG"
# ADD RSC /l 0x407 /d "NDEBUG"
BSC32=bscmake.exe
# ADD BASE BSC32 /nologo
# ADD BSC32 /nologo
LINK32=link.exe
# ADD BASE LINK32 kernel32.lib user32.lib gdi32.lib winspool.lib comdlg32.lib advapi32.lib shell32.lib ole32.lib oleaut32.lib uuid.lib odbc32.lib odbccp32.lib /nologo /subsystem:console /machine:I386
# ADD LINK32 $(API_ROOT)\lib.winnt\libManager.lib $(API_ROOT)\lib.winnt\libMessages.lib $(API_ROOT)\lib.winnt\libDatapoint.lib $(API_ROOT)\lib.winnt\libBasics.lib $(API_ROOT)\lib.winnt\bcm.lib wsock32.lib user32.lib advapi32.lib netapi32.lib $(API_ROOT)\lib.winnt\libConfigs.lib /nologo /subsystem:console /pdb:none /machine:I386 /nodefaultlib:"libc.lib"
# SUBTRACT LINK32 /debug
# Begin Custom Build
InputPath=.\Release\DIPManager.exe
SOURCE="$(InputPath)"

"addVerInfo.obj" : $(SOURCE) "$(INTDIR)" "$(OUTDIR)"
	Release\addVerInfo.obj

# End Custom Build

!ELSEIF  "$(CFG)" == "DIPManager - Win32 Debug"

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
# ADD CPP /nologo /Zp4 /MD /W3 /Zi /I ".\\" /I "$(API_ROOT)\include\winnt\pvssincl" /I "$(API_ROOT)\include\Basics\Utilities" /I "$(API_ROOT)\include\Basics\Variables" /I "$(API_ROOT)\include\Basics\NoPosix" /I "$(API_ROOT)\include\Basics\DpBasics" /I "$(API_ROOT)\include\BCMNew" /I "$(API_ROOT)\include\Configs" /I "$(API_ROOT)\include\Datapoint" /I "$(API_ROOT)\include\Messages" /I "$(API_ROOT)\include\Manager" /FI"$(API_ROOT)\include\winnt\win32.h" /D "WIN32" /D "IS_MSWIN__" /D "_EXCURSION" /D "bcm_boolean_h" /D "FUNCPROTO" /FD /c
# ADD BASE RSC /l 0x407 /d "_DEBUG"
# ADD RSC /l 0x407 /d "_DEBUG"
BSC32=bscmake.exe
# ADD BASE BSC32 /nologo
# ADD BSC32 /nologo
LINK32=link.exe
# ADD BASE LINK32 kernel32.lib user32.lib gdi32.lib winspool.lib comdlg32.lib advapi32.lib shell32.lib ole32.lib oleaut32.lib uuid.lib odbc32.lib odbccp32.lib /nologo /subsystem:console /debug /machine:I386 /pdbtype:con
# ADD LINK32 $(API_ROOT)\lib.winnt\libManager.lib $(API_ROOT)\lib.winnt\libMessages.lib $(API_ROOT)\lib.winnt\libDatapoint.lib $(API_ROOT)\lib.winnt\libConfigs.lib $(API_ROOT)\lib.winnt\libBasics.lib $(API_ROOT)\lib.winnt\bcm.lib wsock32.lib user32.lib advapi32.lib netapi32.lib /nologo /subsystem:console /debug /machine:I386 /nodefaultlib:"libc.lib" /pdbtype:con
# SUBTRACT LINK32 /pdb:none
# Begin Custom Build
InputPath=.\Debug\DIPManager.exe
SOURCE="$(InputPath)"

"dummy" : $(SOURCE) "$(INTDIR)" "$(OUTDIR)"
	del Debug\addVerInfo.obj

# End Custom Build

!ENDIF 

# Begin Target

# Name "DIPManager - Win32 Release"
# Name "DIPManager - Win32 Debug"
# Begin Source File

SOURCE=.\addVerInfo.cxx
DEP_CPP_ADDVE=\
	"$(API_ROOT)\include\Basics\NoPosix\FileSys.hxx"\
	"$(API_ROOT)\include\Basics\Utilities\addVerInfo.hxx"\
	"$(API_ROOT)\include\Basics\Utilities\Allocator.hxx"\
	"$(API_ROOT)\include\Basics\Utilities\BCTime.h"\
	"$(API_ROOT)\include\Basics\Utilities\CharString.hxx"\
	"$(API_ROOT)\include\Basics\Utilities\ConfigAndDpDiag.hxx"\
	"$(API_ROOT)\include\Basics\Utilities\DpConfigNrType.hxx"\
	"$(API_ROOT)\include\Basics\Utilities\DpIdentifier.hxx"\
	"$(API_ROOT)\include\Basics\Utilities\DpIdValueList.hxx"\
	"$(API_ROOT)\include\Basics\Utilities\DpTypes.hxx"\
	"$(API_ROOT)\include\Basics\Utilities\DpVCItem.hxx"\
	"$(API_ROOT)\include\Basics\Utilities\DynPtrArray.hxx"\
	"$(API_ROOT)\include\Basics\Utilities\DynPtrArrayTpl.hxx"\
	"$(API_ROOT)\include\Basics\Utilities\ManagerIdentifier.hxx"\
	"$(API_ROOT)\include\Basics\Utilities\MessageDiag.hxx"\
	"$(API_ROOT)\include\Basics\Utilities\Pathes.hxx"\
	"$(API_ROOT)\include\Basics\Utilities\PathesV1.hxx"\
	"$(API_ROOT)\include\Basics\Utilities\PathesV2.hxx"\
	"$(API_ROOT)\include\Basics\Utilities\ProjDirs.hxx"\
	"$(API_ROOT)\include\Basics\Utilities\PtrList.hxx"\
	"$(API_ROOT)\include\Basics\Utilities\PtrList_Inl.hxx"\
	"$(API_ROOT)\include\Basics\Utilities\PtrListItem.hxx"\
	"$(API_ROOT)\include\Basics\Utilities\PVSSFileSys.hxx"\
	"$(API_ROOT)\include\Basics\Utilities\ResourceDiag.hxx"\
	"$(API_ROOT)\include\Basics\Utilities\Resources.hxx"\
	"$(API_ROOT)\include\Basics\Utilities\Types.hxx"\
	"$(API_ROOT)\include\Basics\Variables\Bit32Var.hxx"\
	"$(API_ROOT)\include\Basics\Variables\DynVar.hxx"\
	"$(API_ROOT)\include\Basics\Variables\IntegerVar.hxx"\
	"$(API_ROOT)\include\Basics\Variables\TimeVar.hxx"\
	"$(API_ROOT)\include\Basics\Variables\UIntegerVar.hxx"\
	"$(API_ROOT)\include\Basics\Variables\Variable.hxx"\
	"$(API_ROOT)\include\winnt\pvssincl\strstream.h"\
	"$(API_ROOT)\include\winnt\pvssincl\unistd.h"\
	
# End Source File
# Begin Source File

SOURCE=.\DIPMain.cxx
DEP_CPP_DEMOM=\
	".\DIPManager.hxx"\
	".\DIPResources.hxx"\
	"$(API_ROOT)\include\Basics\NoPosix\FileSys.hxx"\
	"$(API_ROOT)\include\Basics\Utilities\Allocator.hxx"\
	"$(API_ROOT)\include\Basics\Utilities\BCTime.h"\
	"$(API_ROOT)\include\Basics\Utilities\CharString.hxx"\
	"$(API_ROOT)\include\Basics\Utilities\ConfigAndDpDiag.hxx"\
	"$(API_ROOT)\include\Basics\Utilities\DpConfigNrType.hxx"\
	"$(API_ROOT)\include\Basics\Utilities\DpElementType.hxx"\
	"$(API_ROOT)\include\Basics\Utilities\DpIdentifier.hxx"\
	"$(API_ROOT)\include\Basics\Utilities\DpIdentList.hxx"\
	"$(API_ROOT)\include\Basics\Utilities\DpIdentListItem.hxx"\
	"$(API_ROOT)\include\Basics\Utilities\DpIdValueList.hxx"\
	"$(API_ROOT)\include\Basics\Utilities\DpTypes.hxx"\
	"$(API_ROOT)\include\Basics\Utilities\DpVCItem.hxx"\
	"$(API_ROOT)\include\Basics\Utilities\DynPtrArray.hxx"\
	"$(API_ROOT)\include\Basics\Utilities\DynPtrArrayTpl.hxx"\
	"$(API_ROOT)\include\Basics\Utilities\ErrClass.hxx"\
	"$(API_ROOT)\include\Basics\Utilities\ErrHdl.hxx"\
	"$(API_ROOT)\include\Basics\Utilities\LangText.hxx"\
	"$(API_ROOT)\include\Basics\Utilities\ManagerIdentifier.hxx"\
	"$(API_ROOT)\include\Basics\Utilities\MessageDiag.hxx"\
	"$(API_ROOT)\include\Basics\Utilities\Pathes.hxx"\
	"$(API_ROOT)\include\Basics\Utilities\PathesV1.hxx"\
	"$(API_ROOT)\include\Basics\Utilities\PathesV2.hxx"\
	"$(API_ROOT)\include\Basics\Utilities\ProjDirs.hxx"\
	"$(API_ROOT)\include\Basics\Utilities\PtrList.hxx"\
	"$(API_ROOT)\include\Basics\Utilities\PtrList_Inl.hxx"\
	"$(API_ROOT)\include\Basics\Utilities\PtrListItem.hxx"\
	"$(API_ROOT)\include\Basics\Utilities\PVSSFileSys.hxx"\
	"$(API_ROOT)\include\Basics\Utilities\ResourceDiag.hxx"\
	"$(API_ROOT)\include\Basics\Utilities\Resources.hxx"\
	"$(API_ROOT)\include\Basics\Utilities\Types.hxx"\
	"$(API_ROOT)\include\Basics\Variables\Bit32Var.hxx"\
	"$(API_ROOT)\include\Basics\Variables\BitVar.hxx"\
	"$(API_ROOT)\include\Basics\Variables\DynVar.hxx"\
	"$(API_ROOT)\include\Basics\Variables\IntegerVar.hxx"\
	"$(API_ROOT)\include\Basics\Variables\LangTextVar.hxx"\
	"$(API_ROOT)\include\Basics\Variables\TextVar.hxx"\
	"$(API_ROOT)\include\Basics\Variables\TimeVar.hxx"\
	"$(API_ROOT)\include\Basics\Variables\UIntegerVar.hxx"\
	"$(API_ROOT)\include\Basics\Variables\Variable.hxx"\
	"$(API_ROOT)\include\BCMNew\ItcIOHandler.H"\
	"$(API_ROOT)\include\BCMNew\JCFPortComp.h"\
	"$(API_ROOT)\include\BCMNew\JCFPortConf.h"\
	"$(API_ROOT)\include\BCMNew\JCFPortMod.h"\
	"$(API_ROOT)\include\BCMNew\JCFPortOS.h"\
	"$(API_ROOT)\include\Configs\DpConfig.hxx"\
	"$(API_ROOT)\include\Datapoint\AliasTable.hxx"\
	"$(API_ROOT)\include\Datapoint\AliasTableItem.hxx"\
	"$(API_ROOT)\include\Datapoint\DpIdentification.hxx"\
	"$(API_ROOT)\include\Datapoint\DpIdentificationProSystem.hxx"\
	"$(API_ROOT)\include\Datapoint\DpIdentificationResultType.hxx"\
	"$(API_ROOT)\include\Datapoint\DpNameDpIdCache.hxx"\
	"$(API_ROOT)\include\Datapoint\DpSymIdentifier.hxx"\
	"$(API_ROOT)\include\Datapoint\FixedNumbersTable.hxx"\
	"$(API_ROOT)\include\Datapoint\FixedNumbersTableItem.hxx"\
	"$(API_ROOT)\include\Datapoint\LanguageTable.hxx"\
	"$(API_ROOT)\include\Datapoint\LanguageTableItem.hxx"\
	"$(API_ROOT)\include\Datapoint\PathItem.hxx"\
	"$(API_ROOT)\include\Manager\DiagConfigAndDpItcIOHandler.hxx"\
	"$(API_ROOT)\include\Manager\DiagItcIOHandler.hxx"\
	"$(API_ROOT)\include\Manager\DiagMsgItcIOHandler.hxx"\
	"$(API_ROOT)\include\Manager\HotLinkList.hxx"\
	"$(API_ROOT)\include\Manager\HotLinkListIterator.hxx"\
	"$(API_ROOT)\include\Manager\HotLinkWaitForAnswer.hxx"\
	"$(API_ROOT)\include\Manager\Manager.hxx"\
	"$(API_ROOT)\include\Manager\UserTable.hxx"\
	"$(API_ROOT)\include\Manager\WaitForAnswer.hxx"\
	"$(API_ROOT)\include\Messages\DpHLGroup.hxx"\
	"$(API_ROOT)\include\Messages\DpICGroup.hxx"\
	"$(API_ROOT)\include\Messages\DpICItem.hxx"\
	"$(API_ROOT)\include\Messages\Msg.hxx"\
	"$(API_ROOT)\include\Messages\NameServerSysMsg.hxx"\
	"$(API_ROOT)\include\Messages\SysMsg.hxx"\
	"$(API_ROOT)\include\winnt\BCMNew\pcinc\un.h"\
	"$(API_ROOT)\include\winnt\pvssincl\strstream.h"\
	"$(API_ROOT)\include\winnt\pvssincl\sys\time.h"\
	"$(API_ROOT)\include\winnt\pvssincl\unistd.h"\
	
# End Source File
# Begin Source File

SOURCE=.\DIPManager.cxx
DEP_CPP_DEMOMA=\
	".\DIPManager.hxx"\
	".\DIPResources.hxx"\
	"$(API_ROOT)\include\Basics\NoPosix\FileSys.hxx"\
	"$(API_ROOT)\include\Basics\Utilities\AlertAttrList.hxx"\
	"$(API_ROOT)\include\Basics\Utilities\AlertIdentifier.hxx"\
	"$(API_ROOT)\include\Basics\Utilities\AlertList.hxx"\
	"$(API_ROOT)\include\Basics\Utilities\AlertTime.hxx"\
	"$(API_ROOT)\include\Basics\Utilities\Allocator.hxx"\
	"$(API_ROOT)\include\Basics\Utilities\BCTime.h"\
	"$(API_ROOT)\include\Basics\Utilities\CharString.hxx"\
	"$(API_ROOT)\include\Basics\Utilities\ConfigAndDpDiag.hxx"\
	"$(API_ROOT)\include\Basics\Utilities\DpConfigNrType.hxx"\
	"$(API_ROOT)\include\Basics\Utilities\DpElementType.hxx"\
	"$(API_ROOT)\include\Basics\Utilities\DpIdentifier.hxx"\
	"$(API_ROOT)\include\Basics\Utilities\DpIdentList.hxx"\
	"$(API_ROOT)\include\Basics\Utilities\DpIdentListItem.hxx"\
	"$(API_ROOT)\include\Basics\Utilities\DpIdValueList.hxx"\
	"$(API_ROOT)\include\Basics\Utilities\DpTypes.hxx"\
	"$(API_ROOT)\include\Basics\Utilities\DpVCItem.hxx"\
	"$(API_ROOT)\include\Basics\Utilities\DynPtrArray.hxx"\
	"$(API_ROOT)\include\Basics\Utilities\DynPtrArrayTpl.hxx"\
	"$(API_ROOT)\include\Basics\Utilities\ErrClass.hxx"\
	"$(API_ROOT)\include\Basics\Utilities\ErrHdl.hxx"\
	"$(API_ROOT)\include\Basics\Utilities\LangText.hxx"\
	"$(API_ROOT)\include\Basics\Utilities\ManagerIdentifier.hxx"\
	"$(API_ROOT)\include\Basics\Utilities\MessageDiag.hxx"\
	"$(API_ROOT)\include\Basics\Utilities\Pathes.hxx"\
	"$(API_ROOT)\include\Basics\Utilities\PathesV1.hxx"\
	"$(API_ROOT)\include\Basics\Utilities\PathesV2.hxx"\
	"$(API_ROOT)\include\Basics\Utilities\ProjDirs.hxx"\
	"$(API_ROOT)\include\Basics\Utilities\PtrList.hxx"\
	"$(API_ROOT)\include\Basics\Utilities\PtrList_Inl.hxx"\
	"$(API_ROOT)\include\Basics\Utilities\PtrListItem.hxx"\
	"$(API_ROOT)\include\Basics\Utilities\PVSSFileSys.hxx"\
	"$(API_ROOT)\include\Basics\Utilities\ResourceDiag.hxx"\
	"$(API_ROOT)\include\Basics\Utilities\Resources.hxx"\
	"$(API_ROOT)\include\Basics\Utilities\Types.hxx"\
	"$(API_ROOT)\include\Basics\Variables\Bit32Var.hxx"\
	"$(API_ROOT)\include\Basics\Variables\BitVar.hxx"\
	"$(API_ROOT)\include\Basics\Variables\DynVar.hxx"\
	"$(API_ROOT)\include\Basics\Variables\IntegerVar.hxx"\
	"$(API_ROOT)\include\Basics\Variables\LangTextVar.hxx"\
	"$(API_ROOT)\include\Basics\Variables\TextVar.hxx"\
	"$(API_ROOT)\include\Basics\Variables\TimeVar.hxx"\
	"$(API_ROOT)\include\Basics\Variables\UIntegerVar.hxx"\
	"$(API_ROOT)\include\Basics\Variables\Variable.hxx"\
	"$(API_ROOT)\include\BCMNew\ItcIOHandler.H"\
	"$(API_ROOT)\include\BCMNew\JCFPortComp.h"\
	"$(API_ROOT)\include\BCMNew\JCFPortConf.h"\
	"$(API_ROOT)\include\BCMNew\JCFPortMod.h"\
	"$(API_ROOT)\include\BCMNew\JCFPortOS.h"\
	"$(API_ROOT)\include\Configs\DpConfig.hxx"\
	"$(API_ROOT)\include\Datapoint\AliasTable.hxx"\
	"$(API_ROOT)\include\Datapoint\AliasTableItem.hxx"\
	"$(API_ROOT)\include\Datapoint\DpIdentification.hxx"\
	"$(API_ROOT)\include\Datapoint\DpIdentificationProSystem.hxx"\
	"$(API_ROOT)\include\Datapoint\DpIdentificationResultType.hxx"\
	"$(API_ROOT)\include\Datapoint\DpNameDpIdCache.hxx"\
	"$(API_ROOT)\include\Datapoint\DpSymIdentifier.hxx"\
	"$(API_ROOT)\include\Datapoint\FixedNumbersTable.hxx"\
	"$(API_ROOT)\include\Datapoint\FixedNumbersTableItem.hxx"\
	"$(API_ROOT)\include\Datapoint\LanguageTable.hxx"\
	"$(API_ROOT)\include\Datapoint\LanguageTableItem.hxx"\
	"$(API_ROOT)\include\Datapoint\PathItem.hxx"\
	"$(API_ROOT)\include\Manager\DiagConfigAndDpItcIOHandler.hxx"\
	"$(API_ROOT)\include\Manager\DiagItcIOHandler.hxx"\
	"$(API_ROOT)\include\Manager\DiagMsgItcIOHandler.hxx"\
	"$(API_ROOT)\include\Manager\HotLinkList.hxx"\
	"$(API_ROOT)\include\Manager\HotLinkListIterator.hxx"\
	"$(API_ROOT)\include\Manager\HotLinkWaitForAnswer.hxx"\
	"$(API_ROOT)\include\Manager\Manager.hxx"\
	"$(API_ROOT)\include\Manager\UserTable.hxx"\
	"$(API_ROOT)\include\Manager\WaitForAnswer.hxx"\
	"$(API_ROOT)\include\Messages\AnswerGroup.hxx"\
	"$(API_ROOT)\include\Messages\AnswerItem.hxx"\
	"$(API_ROOT)\include\Messages\DpHLGroup.hxx"\
	"$(API_ROOT)\include\Messages\DpICGroup.hxx"\
	"$(API_ROOT)\include\Messages\DpICItem.hxx"\
	"$(API_ROOT)\include\Messages\DpMsg.hxx"\
	"$(API_ROOT)\include\Messages\DpMsgAnswer.hxx"\
	"$(API_ROOT)\include\Messages\DpMsgHotLink.hxx"\
	"$(API_ROOT)\include\Messages\Msg.hxx"\
	"$(API_ROOT)\include\Messages\NameServerSysMsg.hxx"\
	"$(API_ROOT)\include\Messages\StartDpInitSysMsg.hxx"\
	"$(API_ROOT)\include\Messages\SysMsg.hxx"\
	"$(API_ROOT)\include\winnt\BCMNew\pcinc\un.h"\
	"$(API_ROOT)\include\winnt\pvssincl\strstream.h"\
	"$(API_ROOT)\include\winnt\pvssincl\sys\time.h"\
	"$(API_ROOT)\include\winnt\pvssincl\unistd.h"\
	
# End Source File
# Begin Source File

SOURCE=.\DIPManager.hxx
# End Source File
# Begin Source File

SOURCE=.\DIPResources.cxx
DEP_CPP_DEMOR=\
	".\DIPResources.hxx"\
	"$(API_ROOT)\include\Basics\NoPosix\FileSys.hxx"\
	"$(API_ROOT)\include\Basics\Utilities\Allocator.hxx"\
	"$(API_ROOT)\include\Basics\Utilities\BCTime.h"\
	"$(API_ROOT)\include\Basics\Utilities\CharString.hxx"\
	"$(API_ROOT)\include\Basics\Utilities\ConfigAndDpDiag.hxx"\
	"$(API_ROOT)\include\Basics\Utilities\DpConfigNrType.hxx"\
	"$(API_ROOT)\include\Basics\Utilities\DpIdentifier.hxx"\
	"$(API_ROOT)\include\Basics\Utilities\DpIdValueList.hxx"\
	"$(API_ROOT)\include\Basics\Utilities\DpTypes.hxx"\
	"$(API_ROOT)\include\Basics\Utilities\DpVCItem.hxx"\
	"$(API_ROOT)\include\Basics\Utilities\DynPtrArray.hxx"\
	"$(API_ROOT)\include\Basics\Utilities\DynPtrArrayTpl.hxx"\
	"$(API_ROOT)\include\Basics\Utilities\ErrClass.hxx"\
	"$(API_ROOT)\include\Basics\Utilities\ErrHdl.hxx"\
	"$(API_ROOT)\include\Basics\Utilities\ManagerIdentifier.hxx"\
	"$(API_ROOT)\include\Basics\Utilities\MessageDiag.hxx"\
	"$(API_ROOT)\include\Basics\Utilities\Pathes.hxx"\
	"$(API_ROOT)\include\Basics\Utilities\PathesV1.hxx"\
	"$(API_ROOT)\include\Basics\Utilities\PathesV2.hxx"\
	"$(API_ROOT)\include\Basics\Utilities\ProjDirs.hxx"\
	"$(API_ROOT)\include\Basics\Utilities\PtrList.hxx"\
	"$(API_ROOT)\include\Basics\Utilities\PtrList_Inl.hxx"\
	"$(API_ROOT)\include\Basics\Utilities\PtrListItem.hxx"\
	"$(API_ROOT)\include\Basics\Utilities\PVSSFileSys.hxx"\
	"$(API_ROOT)\include\Basics\Utilities\ResourceDiag.hxx"\
	"$(API_ROOT)\include\Basics\Utilities\Resources.hxx"\
	"$(API_ROOT)\include\Basics\Utilities\Types.hxx"\
	"$(API_ROOT)\include\Basics\Variables\Bit32Var.hxx"\
	"$(API_ROOT)\include\Basics\Variables\DynVar.hxx"\
	"$(API_ROOT)\include\Basics\Variables\IntegerVar.hxx"\
	"$(API_ROOT)\include\Basics\Variables\TextVar.hxx"\
	"$(API_ROOT)\include\Basics\Variables\TimeVar.hxx"\
	"$(API_ROOT)\include\Basics\Variables\UIntegerVar.hxx"\
	"$(API_ROOT)\include\Basics\Variables\Variable.hxx"\
	"$(API_ROOT)\include\winnt\pvssincl\strstream.h"\
	"$(API_ROOT)\include\winnt\pvssincl\unistd.h"\
	
# End Source File
# Begin Source File

SOURCE=.\DIPResources.hxx
# End Source File
# End Target
# End Project
