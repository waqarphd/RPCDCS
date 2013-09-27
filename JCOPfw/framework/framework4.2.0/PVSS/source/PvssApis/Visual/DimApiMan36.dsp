# Microsoft Developer Studio Project File - Name="DimApiMan" - Package Owner=<4>
# Microsoft Developer Studio Generated Build File, Format Version 6.00
# ** DO NOT EDIT **

# TARGTYPE "Win32 (x86) Console Application" 0x0103

CFG=DimApiMan - Win32 Debug
!MESSAGE This is not a valid makefile. To build this project using NMAKE,
!MESSAGE use the Export Makefile command and run
!MESSAGE 
!MESSAGE NMAKE /f "DimApiMan36.mak".
!MESSAGE 
!MESSAGE You can specify a configuration when running NMAKE
!MESSAGE by defining the macro CFG on the command line. For example:
!MESSAGE 
!MESSAGE NMAKE /f "DimApiMan36.mak" CFG="DimApiMan - Win32 Debug"
!MESSAGE 
!MESSAGE Possible choices for configuration are:
!MESSAGE 
!MESSAGE "DimApiMan - Win32 Release" (based on "Win32 (x86) Console Application")
!MESSAGE "DimApiMan - Win32 Debug" (based on "Win32 (x86) Console Application")
!MESSAGE 

# Begin Project
# PROP AllowPerConfigDependencies 0
# PROP Scc_ProjName ""
# PROP Scc_LocalPath ""
CPP=cl.exe
RSC=rc.exe

!IF  "$(CFG)" == "DimApiMan - Win32 Release"

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
F90=df.exe
# ADD BASE F90 /compile_only /include:"Release/" /nologo
# ADD F90 /compile_only /include:"Release/" /nologo
# ADD BASE CPP /nologo /W3 /GX /O2 /D "WIN32" /D "NDEBUG" /D "_CONSOLE" /D "_MBCS" /YX /FD /c
# ADD CPP /nologo /Zp4 /MD /W3 /Zi /I "..\src" /I "$(API_ROOT)\include\winnt\pvssincl" /I "$(API_ROOT)\include\Basics\Utilities" /I "$(API_ROOT)\include\Basics\Variables" /I "$(API_ROOT)\include\Basics\DpBasics" /I "$(API_ROOT)\include\Basics\NoPosix" /I "$(API_ROOT)\include\winnt\BCM\PORT" /I "$(API_ROOT)\include\BCM\PORT" /I "$(API_ROOT)\include\BCMNew" /I "$(API_ROOT)\include\Booch" /I "$(API_ROOT)\include\Configs" /I "$(API_ROOT)\include\Datapoint" /I "$(API_ROOT)\include\Messages" /I "$(API_ROOT)\include\Manager" /I "$(DIMDIR)\dim" /FI"$(API_ROOT)\include\winnt\win32.h" /D "WIN32" /D "IS_MSWIN__" /D "_EXCURSION" /D "bcm_boolean_h" /D "FUNCPROTO" /D "USE_OLD_STYLE_CPP" /FR /c
# ADD BASE RSC /l 0x409 /d "NDEBUG"
# ADD RSC /l 0x409 /d "NDEBUG"
BSC32=bscmake.exe
# ADD BASE BSC32 /nologo
# ADD BSC32 /nologo
LINK32=link.exe
# ADD BASE LINK32 kernel32.lib user32.lib gdi32.lib winspool.lib comdlg32.lib advapi32.lib shell32.lib ole32.lib oleaut32.lib uuid.lib odbc32.lib odbccp32.lib /nologo /subsystem:console /machine:I386
# ADD LINK32 $(API_ROOT)\lib.winnt\libManager.lib $(API_ROOT)\lib.winnt\libMessages.lib $(API_ROOT)\lib.winnt\libDatapoint.lib $(API_ROOT)\lib.winnt\libBasics.lib $(API_ROOT)\lib.winnt\bcm.lib wsock32.lib user32.lib advapi32.lib netapi32.lib $(API_ROOT)\lib.winnt\libConfigs.lib $(DIMDIR)\bin\dim.lib kernel32.lib user32.lib gdi32.lib winspool.lib comdlg32.lib advapi32.lib shell32.lib ole32.lib oleaut32.lib uuid.lib odbc32.lib odbccp32.lib /nologo /subsystem:console /pdb:none /machine:I386 /out:"../bin/PVSS00dim3.6.exe"

!ELSEIF  "$(CFG)" == "DimApiMan - Win32 Debug"

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
F90=df.exe
# ADD BASE F90 /compile_only /debug:full /include:"Debug/" /nologo
# ADD F90 /compile_only /debug:full /include:"exe/" /nologo
# ADD BASE CPP /nologo /W3 /Gm /GX /Zi /Od /D "WIN32" /D "_DEBUG" /D "_CONSOLE" /D "_MBCS" /YX /FD /c
# ADD CPP /nologo /Zp4 /MD /W3 /Zi /I "..\src" /I "$(API_ROOT)\include\winnt\pvssincl" /I "$(API_ROOT)\include\Basics\Utilities" /I "$(API_ROOT)\include\Basics\Variables" /I "$(API_ROOT)\include\Basics\DpBasics" /I "$(API_ROOT)\include\Basics\NoPosix" /I "$(API_ROOT)\include\winnt\BCM\PORT" /I "$(API_ROOT)\include\BCM\PORT" /I "$(API_ROOT)\include\BCMNew" /I "$(API_ROOT)\include\Booch" /I "$(API_ROOT)\include\Configs" /I "$(API_ROOT)\include\Datapoint" /I "$(API_ROOT)\include\Messages" /I "$(API_ROOT)\include\Manager" /I "$(DIMDIR)\dim" /FI"$(API_ROOT)\include\winnt\win32.h" /D "WIN32" /D "_DEBUG" /D "IS_MSWIN__" /D "_EXCURSION" /D "bcm_boolean_h" /D "FUNCPROTO" /D "USE_OLD_STYLE_CPP" /FR /c
# ADD BASE RSC /l 0x409 /d "_DEBUG"
# ADD RSC /l 0x409 /d "_DEBUG"
BSC32=bscmake.exe
# ADD BASE BSC32 /nologo
# ADD BSC32 /nologo
LINK32=link.exe
# ADD BASE LINK32 kernel32.lib user32.lib gdi32.lib winspool.lib comdlg32.lib advapi32.lib shell32.lib ole32.lib oleaut32.lib uuid.lib odbc32.lib odbccp32.lib /nologo /subsystem:console /debug /machine:I386 /pdbtype:sept
# ADD LINK32 $(API_ROOT)\lib.winnt\libManager.lib $(API_ROOT)\lib.winnt\libMessages.lib $(API_ROOT)\lib.winnt\libDatapoint.lib $(API_ROOT)\lib.winnt\libBasics.lib $(API_ROOT)\lib.winnt\bcm.lib wsock32.lib user32.lib advapi32.lib netapi32.lib $(API_ROOT)\lib.winnt\libConfigs.lib $(DIMDIR)\bin\dim.lib /nologo /subsystem:console /profile /debug /machine:I386 /nodefaultlib:"libc.lib" /out:"../bin/PVSS00dim.exe"

!ENDIF 

# Begin Target

# Name "DimApiMan - Win32 Release"
# Name "DimApiMan - Win32 Debug"
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
	"..\src\ApiLib.hxx"\
	"C:\ETM\PVSS2\3.6\api\include\Basics\DpBasics\DpConfigNrType.hxx"\
	"C:\ETM\PVSS2\3.6\api\include\Basics\DpBasics\DpElementType.hxx"\
	"C:\ETM\PVSS2\3.6\api\include\Basics\DpBasics\DpIdentificationResultType.hxx"\
	"C:\ETM\PVSS2\3.6\api\include\Basics\DpBasics\DpIdentifier.hxx"\
	"C:\ETM\PVSS2\3.6\api\include\Basics\DpBasics\DpIdentList.hxx"\
	"C:\ETM\PVSS2\3.6\api\include\Basics\DpBasics\DpIdentListItem.hxx"\
	"C:\ETM\PVSS2\3.6\api\include\Basics\DpBasics\DpIdValueList.hxx"\
	"C:\ETM\PVSS2\3.6\api\include\Basics\DpBasics\DpSymIdentifier.hxx"\
	"C:\ETM\PVSS2\3.6\api\include\Basics\DpBasics\DpTypes.hxx"\
	"C:\ETM\PVSS2\3.6\api\include\Basics\DpBasics\DpVCItem.hxx"\
	"C:\ETM\PVSS2\3.6\api\include\Basics\DpBasics\PathItem.hxx"\
	"C:\ETM\PVSS2\3.6\api\include\Basics\DpBasics\SystemNumType.hxx"\
	"C:\ETM\PVSS2\3.6\api\include\Basics\NoPosix\FileSys.hxx"\
	"C:\ETM\PVSS2\3.6\api\include\Basics\NoPosix\FileSysSlim.hxx"\
	"C:\ETM\PVSS2\3.6\api\include\Basics\NoPosix\IpAcl.hxx"\
	"C:\ETM\PVSS2\3.6\api\include\Basics\Utilities\AccessControlList.hxx"\
	"C:\ETM\PVSS2\3.6\api\include\Basics\Utilities\AlertAttrList.hxx"\
	"C:\ETM\PVSS2\3.6\api\include\Basics\Utilities\AlertIdentifier.hxx"\
	"C:\ETM\PVSS2\3.6\api\include\Basics\Utilities\AlertList.hxx"\
	"C:\ETM\PVSS2\3.6\api\include\Basics\Utilities\AlertTime.hxx"\
	"C:\ETM\PVSS2\3.6\api\include\Basics\Utilities\Allocator.hxx"\
	"C:\ETM\PVSS2\3.6\api\include\Basics\Utilities\BCTime.h"\
	"C:\ETM\PVSS2\3.6\api\include\Basics\Utilities\Bit32.hxx"\
	"C:\ETM\PVSS2\3.6\api\include\Basics\Utilities\CharString.hxx"\
	"C:\ETM\PVSS2\3.6\api\include\Basics\Utilities\ConfigAndDpDiag.hxx"\
	"C:\ETM\PVSS2\3.6\api\include\Basics\Utilities\DblPtrListItem.hxx"\
	"C:\ETM\PVSS2\3.6\api\include\Basics\Utilities\DynPtrArray.hxx"\
	"C:\ETM\PVSS2\3.6\api\include\Basics\Utilities\DynPtrArrayTpl.hxx"\
	"C:\ETM\PVSS2\3.6\api\include\Basics\Utilities\ErrClass.hxx"\
	"C:\ETM\PVSS2\3.6\api\include\Basics\Utilities\ErrHdl.hxx"\
	"C:\ETM\PVSS2\3.6\api\include\Basics\Utilities\FileUtil.hxx"\
	"C:\ETM\PVSS2\3.6\api\include\Basics\Utilities\LangText.hxx"\
	"C:\ETM\PVSS2\3.6\api\include\Basics\Utilities\ManagerIdentifier.hxx"\
	"C:\ETM\PVSS2\3.6\api\include\Basics\Utilities\MessageDiag.hxx"\
	"C:\ETM\PVSS2\3.6\api\include\Basics\Utilities\MsgVersion.hxx"\
	"C:\ETM\PVSS2\3.6\api\include\Basics\Utilities\Pathes.hxx"\
	"C:\ETM\PVSS2\3.6\api\include\Basics\Utilities\ProjDirs.hxx"\
	"C:\ETM\PVSS2\3.6\api\include\Basics\Utilities\PtrList.hxx"\
	"C:\ETM\PVSS2\3.6\api\include\Basics\Utilities\PtrList_Inl.hxx"\
	"C:\ETM\PVSS2\3.6\api\include\Basics\Utilities\PtrListItem.hxx"\
	"C:\ETM\PVSS2\3.6\api\include\Basics\Utilities\PVSSFileSys.hxx"\
	"C:\ETM\PVSS2\3.6\api\include\Basics\Utilities\PVSSTime.hxx"\
	"C:\ETM\PVSS2\3.6\api\include\Basics\Utilities\ResourceDiag.hxx"\
	"C:\ETM\PVSS2\3.6\api\include\Basics\Utilities\Resources.hxx"\
	"C:\ETM\PVSS2\3.6\api\include\Basics\Utilities\SimplePtrArray.hxx"\
	"C:\ETM\PVSS2\3.6\api\include\Basics\Utilities\Types.hxx"\
	"C:\ETM\PVSS2\3.6\api\include\Basics\Utilities\Util.hxx"\
	"C:\ETM\PVSS2\3.6\api\include\Basics\Variables\Bit32Var.hxx"\
	"C:\ETM\PVSS2\3.6\api\include\Basics\Variables\BitVar.hxx"\
	"C:\ETM\PVSS2\3.6\api\include\Basics\Variables\CharVar.hxx"\
	"C:\ETM\PVSS2\3.6\api\include\Basics\Variables\DynVar.hxx"\
	"C:\ETM\PVSS2\3.6\api\include\Basics\Variables\FloatVar.hxx"\
	"C:\ETM\PVSS2\3.6\api\include\Basics\Variables\IntegerVar.hxx"\
	"C:\ETM\PVSS2\3.6\api\include\Basics\Variables\LangTextVar.hxx"\
	"C:\ETM\PVSS2\3.6\api\include\Basics\Variables\RecVar.hxx"\
	"C:\ETM\PVSS2\3.6\api\include\Basics\Variables\TextVar.hxx"\
	"C:\ETM\PVSS2\3.6\api\include\Basics\Variables\TimeVar.hxx"\
	"C:\ETM\PVSS2\3.6\api\include\Basics\Variables\UIntegerVar.hxx"\
	"C:\ETM\PVSS2\3.6\api\include\Basics\Variables\Variable.hxx"\
	"C:\ETM\PVSS2\3.6\api\include\BCMNew\ItcIOHandler.h"\
	"C:\ETM\PVSS2\3.6\api\include\BCMNew\JCFPortComp.h"\
	"C:\ETM\PVSS2\3.6\api\include\BCMNew\JCFPortConf.h"\
	"C:\ETM\PVSS2\3.6\api\include\BCMNew\JCFPortMod.h"\
	"C:\ETM\PVSS2\3.6\api\include\BCMNew\JCFPortOS.h"\
	"C:\ETM\PVSS2\3.6\api\include\BCMNew\pcinc\un.h"\
	"C:\ETM\PVSS2\3.6\api\include\Configs\DpConfig.hxx"\
	"C:\ETM\PVSS2\3.6\api\include\Datapoint\DpIdentification.hxx"\
	"C:\ETM\PVSS2\3.6\api\include\Datapoint\DpIdentificationProSystem.hxx"\
	"C:\ETM\PVSS2\3.6\api\include\Datapoint\DpType.hxx"\
	"C:\ETM\PVSS2\3.6\api\include\Datapoint\DpTypeContainer.hxx"\
	"C:\ETM\PVSS2\3.6\api\include\Datapoint\DpTypeNode.hxx"\
	"C:\ETM\PVSS2\3.6\api\include\Datapoint\ElementTable.hxx"\
	"C:\ETM\PVSS2\3.6\api\include\Datapoint\ElementTableItem.hxx"\
	"C:\ETM\PVSS2\3.6\api\include\Datapoint\ElementTableIteratorNode.hxx"\
	"C:\ETM\PVSS2\3.6\api\include\Datapoint\MapTable.hxx"\
	"C:\ETM\PVSS2\3.6\api\include\Datapoint\MapTableItem.hxx"\
	"C:\ETM\PVSS2\3.6\api\include\Manager\CallBackItem.hxx"\
	"C:\ETM\PVSS2\3.6\api\include\Manager\DiagConfigAndDpItcIOHandler.hxx"\
	"C:\ETM\PVSS2\3.6\api\include\Manager\DiagHotLinkWaitForAnswer.hxx"\
	"C:\ETM\PVSS2\3.6\api\include\Manager\DiagItcIOHandler.hxx"\
	"C:\ETM\PVSS2\3.6\api\include\Manager\DiagMsgItcIOHandler.hxx"\
	"C:\ETM\PVSS2\3.6\api\include\Manager\FileTransferList.hxx"\
	"C:\ETM\PVSS2\3.6\api\include\Manager\HotLinkWaitForAnswer.hxx"\
	"C:\ETM\PVSS2\3.6\api\include\Manager\Manager.hxx"\
	"C:\ETM\PVSS2\3.6\api\include\Manager\UserTable.hxx"\
	"C:\ETM\PVSS2\3.6\api\include\Manager\WaitForAnswer.hxx"\
	"C:\ETM\PVSS2\3.6\api\include\Messages\AnswerGroup.hxx"\
	"C:\ETM\PVSS2\3.6\api\include\Messages\AnswerItem.hxx"\
	"C:\ETM\PVSS2\3.6\api\include\Messages\DpHLGroup.hxx"\
	"C:\ETM\PVSS2\3.6\api\include\Messages\DpICGroup.hxx"\
	"C:\ETM\PVSS2\3.6\api\include\Messages\DpICItem.hxx"\
	"C:\ETM\PVSS2\3.6\api\include\Messages\DpIdentifierItem.hxx"\
	"C:\ETM\PVSS2\3.6\api\include\Messages\DpMsg.hxx"\
	"C:\ETM\PVSS2\3.6\api\include\Messages\DpMsgAlert.hxx"\
	"C:\ETM\PVSS2\3.6\api\include\Messages\DpMsgAnswer.hxx"\
	"C:\ETM\PVSS2\3.6\api\include\Messages\DpMsgComplexVC.hxx"\
	"C:\ETM\PVSS2\3.6\api\include\Messages\DpMsgConnection.hxx"\
	"C:\ETM\PVSS2\3.6\api\include\Messages\DpMsgFilterRequest.hxx"\
	"C:\ETM\PVSS2\3.6\api\include\Messages\DpMsgHotLink.hxx"\
	"C:\ETM\PVSS2\3.6\api\include\Messages\DpMsgValueChange.hxx"\
	"C:\ETM\PVSS2\3.6\api\include\Messages\DpVCGroup.hxx"\
	"C:\ETM\PVSS2\3.6\api\include\Messages\Msg.hxx"\
	"C:\ETM\PVSS2\3.6\api\include\Messages\NameServerSysMsg.hxx"\
	"C:\ETM\PVSS2\3.6\api\include\Messages\StartDpInitSysMsg.hxx"\
	"C:\ETM\PVSS2\3.6\api\include\Messages\SysMsg.hxx"\
	"C:\ETM\PVSS2\3.6\api\include\winnt\pvssincl\dirent.h"\
	"C:\ETM\PVSS2\3.6\api\include\winnt\pvssincl\netdb.h"\
	"C:\ETM\PVSS2\3.6\api\include\winnt\pvssincl\netinet\in.h"\
	"C:\ETM\PVSS2\3.6\api\include\winnt\pvssincl\sys\ioctl.h"\
	"C:\ETM\PVSS2\3.6\api\include\winnt\pvssincl\sys\socket.h"\
	"C:\ETM\PVSS2\3.6\api\include\winnt\pvssincl\sys\time.h"\
	"C:\ETM\PVSS2\3.6\api\include\winnt\pvssincl\unistd.h"\
	
# End Source File
# Begin Source File

SOURCE=..\src\DimApiMan.cxx
DEP_CPP_DIMAP=\
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
	"..\src\ApiLib.hxx"\
	"C:\ETM\PVSS2\3.6\api\include\Basics\DpBasics\DpConfigNrType.hxx"\
	"C:\ETM\PVSS2\3.6\api\include\Basics\DpBasics\DpElementType.hxx"\
	"C:\ETM\PVSS2\3.6\api\include\Basics\DpBasics\DpIdentificationResultType.hxx"\
	"C:\ETM\PVSS2\3.6\api\include\Basics\DpBasics\DpIdentifier.hxx"\
	"C:\ETM\PVSS2\3.6\api\include\Basics\DpBasics\DpIdentList.hxx"\
	"C:\ETM\PVSS2\3.6\api\include\Basics\DpBasics\DpIdentListItem.hxx"\
	"C:\ETM\PVSS2\3.6\api\include\Basics\DpBasics\DpIdValueList.hxx"\
	"C:\ETM\PVSS2\3.6\api\include\Basics\DpBasics\DpSymIdentifier.hxx"\
	"C:\ETM\PVSS2\3.6\api\include\Basics\DpBasics\DpTypes.hxx"\
	"C:\ETM\PVSS2\3.6\api\include\Basics\DpBasics\DpVCItem.hxx"\
	"C:\ETM\PVSS2\3.6\api\include\Basics\DpBasics\PathItem.hxx"\
	"C:\ETM\PVSS2\3.6\api\include\Basics\DpBasics\SystemNumType.hxx"\
	"C:\ETM\PVSS2\3.6\api\include\Basics\NoPosix\FileSys.hxx"\
	"C:\ETM\PVSS2\3.6\api\include\Basics\NoPosix\FileSysSlim.hxx"\
	"C:\ETM\PVSS2\3.6\api\include\Basics\NoPosix\IpAcl.hxx"\
	"C:\ETM\PVSS2\3.6\api\include\Basics\Utilities\AccessControlList.hxx"\
	"C:\ETM\PVSS2\3.6\api\include\Basics\Utilities\AlertAttrList.hxx"\
	"C:\ETM\PVSS2\3.6\api\include\Basics\Utilities\AlertIdentifier.hxx"\
	"C:\ETM\PVSS2\3.6\api\include\Basics\Utilities\AlertList.hxx"\
	"C:\ETM\PVSS2\3.6\api\include\Basics\Utilities\AlertTime.hxx"\
	"C:\ETM\PVSS2\3.6\api\include\Basics\Utilities\Allocator.hxx"\
	"C:\ETM\PVSS2\3.6\api\include\Basics\Utilities\BCTime.h"\
	"C:\ETM\PVSS2\3.6\api\include\Basics\Utilities\Bit32.hxx"\
	"C:\ETM\PVSS2\3.6\api\include\Basics\Utilities\CharString.hxx"\
	"C:\ETM\PVSS2\3.6\api\include\Basics\Utilities\ConfigAndDpDiag.hxx"\
	"C:\ETM\PVSS2\3.6\api\include\Basics\Utilities\DblPtrListItem.hxx"\
	"C:\ETM\PVSS2\3.6\api\include\Basics\Utilities\DynPtrArray.hxx"\
	"C:\ETM\PVSS2\3.6\api\include\Basics\Utilities\DynPtrArrayTpl.hxx"\
	"C:\ETM\PVSS2\3.6\api\include\Basics\Utilities\ErrClass.hxx"\
	"C:\ETM\PVSS2\3.6\api\include\Basics\Utilities\ErrHdl.hxx"\
	"C:\ETM\PVSS2\3.6\api\include\Basics\Utilities\FileUtil.hxx"\
	"C:\ETM\PVSS2\3.6\api\include\Basics\Utilities\LangText.hxx"\
	"C:\ETM\PVSS2\3.6\api\include\Basics\Utilities\ManagerIdentifier.hxx"\
	"C:\ETM\PVSS2\3.6\api\include\Basics\Utilities\MessageDiag.hxx"\
	"C:\ETM\PVSS2\3.6\api\include\Basics\Utilities\MsgVersion.hxx"\
	"C:\ETM\PVSS2\3.6\api\include\Basics\Utilities\Pathes.hxx"\
	"C:\ETM\PVSS2\3.6\api\include\Basics\Utilities\ProjDirs.hxx"\
	"C:\ETM\PVSS2\3.6\api\include\Basics\Utilities\PtrList.hxx"\
	"C:\ETM\PVSS2\3.6\api\include\Basics\Utilities\PtrList_Inl.hxx"\
	"C:\ETM\PVSS2\3.6\api\include\Basics\Utilities\PtrListItem.hxx"\
	"C:\ETM\PVSS2\3.6\api\include\Basics\Utilities\PVSSFileSys.hxx"\
	"C:\ETM\PVSS2\3.6\api\include\Basics\Utilities\PVSSTime.hxx"\
	"C:\ETM\PVSS2\3.6\api\include\Basics\Utilities\ResourceDiag.hxx"\
	"C:\ETM\PVSS2\3.6\api\include\Basics\Utilities\Resources.hxx"\
	"C:\ETM\PVSS2\3.6\api\include\Basics\Utilities\SimplePtrArray.hxx"\
	"C:\ETM\PVSS2\3.6\api\include\Basics\Utilities\Types.hxx"\
	"C:\ETM\PVSS2\3.6\api\include\Basics\Utilities\Util.hxx"\
	"C:\ETM\PVSS2\3.6\api\include\Basics\Variables\Bit32Var.hxx"\
	"C:\ETM\PVSS2\3.6\api\include\Basics\Variables\BitVar.hxx"\
	"C:\ETM\PVSS2\3.6\api\include\Basics\Variables\CharVar.hxx"\
	"C:\ETM\PVSS2\3.6\api\include\Basics\Variables\DynVar.hxx"\
	"C:\ETM\PVSS2\3.6\api\include\Basics\Variables\FloatVar.hxx"\
	"C:\ETM\PVSS2\3.6\api\include\Basics\Variables\IntegerVar.hxx"\
	"C:\ETM\PVSS2\3.6\api\include\Basics\Variables\LangTextVar.hxx"\
	"C:\ETM\PVSS2\3.6\api\include\Basics\Variables\RecVar.hxx"\
	"C:\ETM\PVSS2\3.6\api\include\Basics\Variables\TextVar.hxx"\
	"C:\ETM\PVSS2\3.6\api\include\Basics\Variables\TimeVar.hxx"\
	"C:\ETM\PVSS2\3.6\api\include\Basics\Variables\UIntegerVar.hxx"\
	"C:\ETM\PVSS2\3.6\api\include\Basics\Variables\Variable.hxx"\
	"C:\ETM\PVSS2\3.6\api\include\BCMNew\ItcIOHandler.h"\
	"C:\ETM\PVSS2\3.6\api\include\BCMNew\JCFPortComp.h"\
	"C:\ETM\PVSS2\3.6\api\include\BCMNew\JCFPortConf.h"\
	"C:\ETM\PVSS2\3.6\api\include\BCMNew\JCFPortMod.h"\
	"C:\ETM\PVSS2\3.6\api\include\BCMNew\JCFPortOS.h"\
	"C:\ETM\PVSS2\3.6\api\include\BCMNew\pcinc\un.h"\
	"C:\ETM\PVSS2\3.6\api\include\Configs\DpConfig.hxx"\
	"C:\ETM\PVSS2\3.6\api\include\Datapoint\DpIdentification.hxx"\
	"C:\ETM\PVSS2\3.6\api\include\Datapoint\DpIdentificationProSystem.hxx"\
	"C:\ETM\PVSS2\3.6\api\include\Datapoint\DpType.hxx"\
	"C:\ETM\PVSS2\3.6\api\include\Datapoint\DpTypeContainer.hxx"\
	"C:\ETM\PVSS2\3.6\api\include\Datapoint\DpTypeNode.hxx"\
	"C:\ETM\PVSS2\3.6\api\include\Datapoint\ElementTable.hxx"\
	"C:\ETM\PVSS2\3.6\api\include\Datapoint\ElementTableItem.hxx"\
	"C:\ETM\PVSS2\3.6\api\include\Datapoint\ElementTableIteratorNode.hxx"\
	"C:\ETM\PVSS2\3.6\api\include\Datapoint\MapTable.hxx"\
	"C:\ETM\PVSS2\3.6\api\include\Datapoint\MapTableItem.hxx"\
	"C:\ETM\PVSS2\3.6\api\include\Manager\CallBackItem.hxx"\
	"C:\ETM\PVSS2\3.6\api\include\Manager\DiagConfigAndDpItcIOHandler.hxx"\
	"C:\ETM\PVSS2\3.6\api\include\Manager\DiagHotLinkWaitForAnswer.hxx"\
	"C:\ETM\PVSS2\3.6\api\include\Manager\DiagItcIOHandler.hxx"\
	"C:\ETM\PVSS2\3.6\api\include\Manager\DiagMsgItcIOHandler.hxx"\
	"C:\ETM\PVSS2\3.6\api\include\Manager\FileTransferList.hxx"\
	"C:\ETM\PVSS2\3.6\api\include\Manager\HotLinkWaitForAnswer.hxx"\
	"C:\ETM\PVSS2\3.6\api\include\Manager\Manager.hxx"\
	"C:\ETM\PVSS2\3.6\api\include\Manager\UserTable.hxx"\
	"C:\ETM\PVSS2\3.6\api\include\Manager\WaitForAnswer.hxx"\
	"C:\ETM\PVSS2\3.6\api\include\Messages\AnswerGroup.hxx"\
	"C:\ETM\PVSS2\3.6\api\include\Messages\AnswerItem.hxx"\
	"C:\ETM\PVSS2\3.6\api\include\Messages\DpHLGroup.hxx"\
	"C:\ETM\PVSS2\3.6\api\include\Messages\DpICGroup.hxx"\
	"C:\ETM\PVSS2\3.6\api\include\Messages\DpICItem.hxx"\
	"C:\ETM\PVSS2\3.6\api\include\Messages\DpIdentifierItem.hxx"\
	"C:\ETM\PVSS2\3.6\api\include\Messages\DpMsg.hxx"\
	"C:\ETM\PVSS2\3.6\api\include\Messages\DpMsgAlert.hxx"\
	"C:\ETM\PVSS2\3.6\api\include\Messages\DpMsgAnswer.hxx"\
	"C:\ETM\PVSS2\3.6\api\include\Messages\DpMsgComplexVC.hxx"\
	"C:\ETM\PVSS2\3.6\api\include\Messages\DpMsgConnection.hxx"\
	"C:\ETM\PVSS2\3.6\api\include\Messages\DpMsgFilterRequest.hxx"\
	"C:\ETM\PVSS2\3.6\api\include\Messages\DpMsgHotLink.hxx"\
	"C:\ETM\PVSS2\3.6\api\include\Messages\DpMsgValueChange.hxx"\
	"C:\ETM\PVSS2\3.6\api\include\Messages\DpVCGroup.hxx"\
	"C:\ETM\PVSS2\3.6\api\include\Messages\Msg.hxx"\
	"C:\ETM\PVSS2\3.6\api\include\Messages\NameServerSysMsg.hxx"\
	"C:\ETM\PVSS2\3.6\api\include\Messages\StartDpInitSysMsg.hxx"\
	"C:\ETM\PVSS2\3.6\api\include\Messages\SysMsg.hxx"\
	"C:\ETM\PVSS2\3.6\api\include\winnt\pvssincl\dirent.h"\
	"C:\ETM\PVSS2\3.6\api\include\winnt\pvssincl\netdb.h"\
	"C:\ETM\PVSS2\3.6\api\include\winnt\pvssincl\netinet\in.h"\
	"C:\ETM\PVSS2\3.6\api\include\winnt\pvssincl\sys\ioctl.h"\
	"C:\ETM\PVSS2\3.6\api\include\winnt\pvssincl\sys\socket.h"\
	"C:\ETM\PVSS2\3.6\api\include\winnt\pvssincl\sys\time.h"\
	"C:\ETM\PVSS2\3.6\api\include\winnt\pvssincl\unistd.h"\
	
# End Source File
# End Target
# End Project
