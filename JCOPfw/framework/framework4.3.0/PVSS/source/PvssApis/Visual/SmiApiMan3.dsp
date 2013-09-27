# Microsoft Developer Studio Project File - Name="SmiApiMan" - Package Owner=<4>
# Microsoft Developer Studio Generated Build File, Format Version 6.00
# ** DO NOT EDIT **

# TARGTYPE "Win32 (x86) Console Application" 0x0103

CFG=SmiApiMan - Win32 Debug
!MESSAGE This is not a valid makefile. To build this project using NMAKE,
!MESSAGE use the Export Makefile command and run
!MESSAGE 
!MESSAGE NMAKE /f "SmiApiMan3.mak".
!MESSAGE 
!MESSAGE You can specify a configuration when running NMAKE
!MESSAGE by defining the macro CFG on the command line. For example:
!MESSAGE 
!MESSAGE NMAKE /f "SmiApiMan3.mak" CFG="SmiApiMan - Win32 Debug"
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
# ADD CPP /nologo /Zp4 /MD /W3 /Zi /I "..\src" /I "$(API_ROOT)\include\winnt\pvssincl" /I "$(API_ROOT)\include\Basics\Utilities" /I "$(API_ROOT)\include\Basics\Variables" /I "$(API_ROOT)\include\Basics\NoPosix" /I "$(API_ROOT)\include\winnt\BCM\PORT" /I "$(API_ROOT)\include\BCM\PORT" /I "$(API_ROOT)\include\BCMNew" /I "$(API_ROOT)\include\Booch" /I "$(API_ROOT)\include\Configs" /I "$(API_ROOT)\include\Datapoint" /I "$(API_ROOT)\include\Messages" /I "$(API_ROOT)\include\Manager" /I "$(SMIDIR)\smixx" /I "$(DIMDIR)\dim" /FI"$(API_ROOT)\include\winnt\win32.h" /D "WIN32" /D "IS_MSWIN__" /D "_EXCURSION" /D "bcm_boolean_h" /D "FUNCPROTO" /D "USE_OLD_STYLE_CPP" /FR /c
# ADD BASE RSC /l 0x409 /d "NDEBUG"
# ADD RSC /l 0x409 /d "NDEBUG"
BSC32=bscmake.exe
# ADD BASE BSC32 /nologo
# ADD BSC32 /nologo
LINK32=link.exe
# ADD BASE LINK32 kernel32.lib user32.lib gdi32.lib winspool.lib comdlg32.lib advapi32.lib shell32.lib ole32.lib oleaut32.lib uuid.lib odbc32.lib odbccp32.lib /nologo /subsystem:console /machine:I386
# ADD LINK32 $(API_ROOT)\lib.winnt\libManager.lib $(API_ROOT)\lib.winnt\libMessages.lib $(API_ROOT)\lib.winnt\libDatapoint.lib $(API_ROOT)\lib.winnt\libBasics.lib $(API_ROOT)\lib.winnt\bcm.lib wsock32.lib user32.lib advapi32.lib netapi32.lib $(API_ROOT)\lib.winnt\libConfigs.lib $(SMIDIR)\bin\smiuirtl.lib $(SMIDIR)\bin\smirtl.lib $(DIMDIR)\bin\dim.lib kernel32.lib user32.lib gdi32.lib winspool.lib comdlg32.lib advapi32.lib shell32.lib ole32.lib oleaut32.lib uuid.lib odbc32.lib odbccp32.lib /nologo /subsystem:console /pdb:none /machine:I386 /out:"../bin/PVSS00smi3.0.exe"

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
# ADD CPP /nologo /Zp4 /MD /W3 /Zi /I "..\src" /I "$(API_ROOT)\include\winnt\pvssincl" /I "$(API_ROOT)\include\Basics\Utilities" /I "$(API_ROOT)\include\Basics\Variables" /I "$(API_ROOT)\include\Basics\NoPosix" /I "$(API_ROOT)\include\winnt\BCM\PORT" /I "$(API_ROOT)\include\BCM\PORT" /I "$(API_ROOT)\include\BCMNew" /I "$(API_ROOT)\include\Booch" /I "$(API_ROOT)\include\Configs" /I "$(API_ROOT)\include\Datapoint" /I "$(API_ROOT)\include\Messages" /I "$(API_ROOT)\include\Manager" /I "$(SMIDIR)\smixx" /I "$(DIMDIR)\dim" /FI"$(API_ROOT)\include\winnt\win32.h" /D "WIN32" /D "_DEBUG" /D "IS_MSWIN__" /D "_EXCURSION" /D "bcm_boolean_h" /D "FUNCPROTO" /D "USE_OLD_STYLE_CPP" /FR /c
# ADD BASE RSC /l 0x409 /d "_DEBUG"
# ADD RSC /l 0x409 /d "_DEBUG"
BSC32=bscmake.exe
# ADD BASE BSC32 /nologo
# ADD BSC32 /nologo
LINK32=link.exe
# ADD BASE LINK32 kernel32.lib user32.lib gdi32.lib winspool.lib comdlg32.lib advapi32.lib shell32.lib ole32.lib oleaut32.lib uuid.lib odbc32.lib odbccp32.lib /nologo /subsystem:console /debug /machine:I386 /pdbtype:sept
# ADD LINK32 $(API_ROOT)\lib.winnt\libManager.lib $(API_ROOT)\lib.winnt\libMessages.lib $(API_ROOT)\lib.winnt\libDatapoint.lib $(API_ROOT)\lib.winnt\libBasics.lib $(API_ROOT)\lib.winnt\bcm.lib wsock32.lib user32.lib advapi32.lib netapi32.lib $(API_ROOT)\lib.winnt\libConfigs.lib $(SMIDIR)\bin\smiuirtl.lib $(SMIDIR)\bin\smirtl.lib $(DIMDIR)\bin\dim.lib /nologo /subsystem:console /debug /machine:I386 /nodefaultlib:"libc.lib" /out:"../bin/PVSS00smi.exe"
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
	"..\..\etm\pvss2\3.0\api\include\basics\noposix\filesys.hxx"\
	"..\..\etm\pvss2\3.0\api\include\basics\noposix\filesysslim.hxx"\
	"..\..\etm\pvss2\3.0\api\include\basics\noposix\ipacl.hxx"\
	"..\..\etm\pvss2\3.0\api\include\basics\utilities\accesscontrollist.hxx"\
	"..\..\etm\pvss2\3.0\api\include\basics\utilities\alertattrlist.hxx"\
	"..\..\etm\pvss2\3.0\api\include\basics\utilities\alertidentifier.hxx"\
	"..\..\etm\pvss2\3.0\api\include\basics\utilities\alertlist.hxx"\
	"..\..\etm\pvss2\3.0\api\include\basics\utilities\alerttime.hxx"\
	"..\..\etm\pvss2\3.0\api\include\basics\utilities\allocator.hxx"\
	"..\..\etm\pvss2\3.0\api\include\basics\utilities\bctime.h"\
	"..\..\etm\pvss2\3.0\api\include\basics\utilities\bit32.hxx"\
	"..\..\etm\pvss2\3.0\api\include\basics\utilities\charstring.hxx"\
	"..\..\etm\pvss2\3.0\api\include\basics\utilities\configanddpdiag.hxx"\
	"..\..\etm\pvss2\3.0\api\include\basics\utilities\dpconfignrtype.hxx"\
	"..\..\etm\pvss2\3.0\api\include\basics\utilities\dpelementtype.hxx"\
	"..\..\etm\pvss2\3.0\api\include\basics\utilities\dpidentifier.hxx"\
	"..\..\etm\pvss2\3.0\api\include\basics\utilities\dpidentlist.hxx"\
	"..\..\etm\pvss2\3.0\api\include\basics\utilities\dpidentlistitem.hxx"\
	"..\..\etm\pvss2\3.0\api\include\basics\utilities\dpidvaluelist.hxx"\
	"..\..\etm\pvss2\3.0\api\include\basics\utilities\dptypes.hxx"\
	"..\..\etm\pvss2\3.0\api\include\basics\utilities\dpvcitem.hxx"\
	"..\..\etm\pvss2\3.0\api\include\basics\utilities\dynptrarray.hxx"\
	"..\..\etm\pvss2\3.0\api\include\basics\utilities\dynptrarraytpl.hxx"\
	"..\..\etm\pvss2\3.0\api\include\basics\utilities\errclass.hxx"\
	"..\..\etm\pvss2\3.0\api\include\basics\utilities\errhdl.hxx"\
	"..\..\etm\pvss2\3.0\api\include\basics\utilities\fileutil.hxx"\
	"..\..\etm\pvss2\3.0\api\include\basics\utilities\langtext.hxx"\
	"..\..\etm\pvss2\3.0\api\include\basics\utilities\manageridentifier.hxx"\
	"..\..\etm\pvss2\3.0\api\include\basics\utilities\messagediag.hxx"\
	"..\..\etm\pvss2\3.0\api\include\basics\utilities\pathes.hxx"\
	"..\..\etm\pvss2\3.0\api\include\basics\utilities\projdirs.hxx"\
	"..\..\etm\pvss2\3.0\api\include\basics\utilities\ptrlist.hxx"\
	"..\..\ETM\PVSS2\3.0\api\include\Basics\Utilities\PtrList_Inl.hxx"\
	"..\..\etm\pvss2\3.0\api\include\basics\utilities\ptrlistitem.hxx"\
	"..\..\etm\pvss2\3.0\api\include\basics\utilities\pvssfilesys.hxx"\
	"..\..\etm\pvss2\3.0\api\include\basics\utilities\pvsstime.hxx"\
	"..\..\etm\pvss2\3.0\api\include\basics\utilities\resourcediag.hxx"\
	"..\..\etm\pvss2\3.0\api\include\basics\utilities\resources.hxx"\
	"..\..\etm\pvss2\3.0\api\include\basics\utilities\simpleptrarray.hxx"\
	"..\..\etm\pvss2\3.0\api\include\basics\utilities\types.hxx"\
	"..\..\etm\pvss2\3.0\api\include\basics\utilities\util.hxx"\
	"..\..\etm\pvss2\3.0\api\include\basics\variables\bit32var.hxx"\
	"..\..\etm\pvss2\3.0\api\include\basics\variables\bitvar.hxx"\
	"..\..\ETM\PVSS2\3.0\api\include\Basics\Variables\CharVar.hxx"\
	"..\..\etm\pvss2\3.0\api\include\basics\variables\dynvar.hxx"\
	"..\..\etm\pvss2\3.0\api\include\basics\variables\floatvar.hxx"\
	"..\..\etm\pvss2\3.0\api\include\basics\variables\integervar.hxx"\
	"..\..\etm\pvss2\3.0\api\include\basics\variables\langtextvar.hxx"\
	"..\..\etm\pvss2\3.0\api\include\basics\variables\recvar.hxx"\
	"..\..\etm\pvss2\3.0\api\include\basics\variables\textvar.hxx"\
	"..\..\etm\pvss2\3.0\api\include\basics\variables\timevar.hxx"\
	"..\..\etm\pvss2\3.0\api\include\basics\variables\uintegervar.hxx"\
	"..\..\etm\pvss2\3.0\api\include\basics\variables\variable.hxx"\
	"..\..\etm\pvss2\3.0\api\include\bcmnew\itciohandler.h"\
	"..\..\etm\pvss2\3.0\api\include\bcmnew\jcfportcomp.h"\
	"..\..\etm\pvss2\3.0\api\include\bcmnew\jcfportconf.h"\
	"..\..\etm\pvss2\3.0\api\include\bcmnew\jcfportmod.h"\
	"..\..\etm\pvss2\3.0\api\include\bcmnew\jcfportos.h"\
	"..\..\etm\pvss2\3.0\api\include\bcmnew\pcinc\un.h"\
	"..\..\etm\pvss2\3.0\api\include\configs\dpconfig.hxx"\
	"..\..\etm\pvss2\3.0\api\include\datapoint\aliastable.hxx"\
	"..\..\etm\pvss2\3.0\api\include\datapoint\aliastableitem.hxx"\
	"..\..\etm\pvss2\3.0\api\include\datapoint\dpidentification.hxx"\
	"..\..\etm\pvss2\3.0\api\include\datapoint\dpidentificationprosystem.hxx"\
	"..\..\etm\pvss2\3.0\api\include\datapoint\dpidentificationresulttype.hxx"\
	"..\..\etm\pvss2\3.0\api\include\datapoint\dpnamedpidcache.hxx"\
	"..\..\etm\pvss2\3.0\api\include\datapoint\dpsymidentifier.hxx"\
	"..\..\etm\pvss2\3.0\api\include\datapoint\dptype.hxx"\
	"..\..\etm\pvss2\3.0\api\include\datapoint\dptypecontainer.hxx"\
	"..\..\etm\pvss2\3.0\api\include\datapoint\dptypenode.hxx"\
	"..\..\etm\pvss2\3.0\api\include\datapoint\fixednumberstable.hxx"\
	"..\..\etm\pvss2\3.0\api\include\datapoint\fixednumberstableitem.hxx"\
	"..\..\etm\pvss2\3.0\api\include\datapoint\languagetable.hxx"\
	"..\..\etm\pvss2\3.0\api\include\datapoint\languagetableitem.hxx"\
	"..\..\etm\pvss2\3.0\api\include\datapoint\pathitem.hxx"\
	"..\..\etm\pvss2\3.0\api\include\manager\callbackitem.hxx"\
	"..\..\etm\pvss2\3.0\api\include\manager\diagconfiganddpitciohandler.hxx"\
	"..\..\etm\pvss2\3.0\api\include\manager\diaghotlinkwaitforanswer.hxx"\
	"..\..\etm\pvss2\3.0\api\include\manager\diagitciohandler.hxx"\
	"..\..\etm\pvss2\3.0\api\include\manager\diagmsgitciohandler.hxx"\
	"..\..\etm\pvss2\3.0\api\include\manager\filetransferlist.hxx"\
	"..\..\etm\pvss2\3.0\api\include\manager\hotlinkwaitforanswer.hxx"\
	"..\..\etm\pvss2\3.0\api\include\manager\manager.hxx"\
	"..\..\etm\pvss2\3.0\api\include\manager\usertable.hxx"\
	"..\..\etm\pvss2\3.0\api\include\manager\waitforanswer.hxx"\
	"..\..\etm\pvss2\3.0\api\include\messages\answergroup.hxx"\
	"..\..\etm\pvss2\3.0\api\include\messages\answeritem.hxx"\
	"..\..\etm\pvss2\3.0\api\include\messages\dphlgroup.hxx"\
	"..\..\etm\pvss2\3.0\api\include\messages\dpicgroup.hxx"\
	"..\..\etm\pvss2\3.0\api\include\messages\dpicitem.hxx"\
	"..\..\etm\pvss2\3.0\api\include\messages\dpidentifieritem.hxx"\
	"..\..\etm\pvss2\3.0\api\include\messages\dpmsg.hxx"\
	"..\..\etm\pvss2\3.0\api\include\messages\dpmsgalert.hxx"\
	"..\..\etm\pvss2\3.0\api\include\messages\dpmsganswer.hxx"\
	"..\..\etm\pvss2\3.0\api\include\messages\dpmsgconnection.hxx"\
	"..\..\etm\pvss2\3.0\api\include\messages\dpmsgfilterrequest.hxx"\
	"..\..\etm\pvss2\3.0\api\include\messages\dpmsghotlink.hxx"\
	"..\..\etm\pvss2\3.0\api\include\messages\dpvcgroup.hxx"\
	"..\..\etm\pvss2\3.0\api\include\messages\msg.hxx"\
	"..\..\etm\pvss2\3.0\api\include\messages\nameserversysmsg.hxx"\
	"..\..\etm\pvss2\3.0\api\include\messages\startdpinitsysmsg.hxx"\
	"..\..\etm\pvss2\3.0\api\include\messages\sysmsg.hxx"\
	"..\..\ETM\PVSS2\3.0\api\include\winnt\pvssincl\dirent.h"\
	"..\..\ETM\PVSS2\3.0\api\include\winnt\pvssincl\netdb.h"\
	"..\..\ETM\PVSS2\3.0\api\include\winnt\pvssincl\netinet\in.h"\
	"..\..\etm\pvss2\3.0\api\include\winnt\pvssincl\strstream.h"\
	"..\..\ETM\PVSS2\3.0\api\include\winnt\pvssincl\sys\ioctl.h"\
	"..\..\ETM\PVSS2\3.0\api\include\winnt\pvssincl\sys\socket.h"\
	"..\..\ETM\PVSS2\3.0\api\include\winnt\pvssincl\sys\time.h"\
	"..\..\ETM\PVSS2\3.0\api\include\winnt\pvssincl\unistd.h"\
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
	"..\..\etm\pvss2\3.0\api\include\basics\noposix\filesys.hxx"\
	"..\..\etm\pvss2\3.0\api\include\basics\noposix\filesysslim.hxx"\
	"..\..\etm\pvss2\3.0\api\include\basics\noposix\ipacl.hxx"\
	"..\..\etm\pvss2\3.0\api\include\basics\utilities\accesscontrollist.hxx"\
	"..\..\etm\pvss2\3.0\api\include\basics\utilities\alertattrlist.hxx"\
	"..\..\etm\pvss2\3.0\api\include\basics\utilities\alertidentifier.hxx"\
	"..\..\etm\pvss2\3.0\api\include\basics\utilities\alertlist.hxx"\
	"..\..\etm\pvss2\3.0\api\include\basics\utilities\alerttime.hxx"\
	"..\..\etm\pvss2\3.0\api\include\basics\utilities\allocator.hxx"\
	"..\..\etm\pvss2\3.0\api\include\basics\utilities\bctime.h"\
	"..\..\etm\pvss2\3.0\api\include\basics\utilities\bit32.hxx"\
	"..\..\etm\pvss2\3.0\api\include\basics\utilities\charstring.hxx"\
	"..\..\etm\pvss2\3.0\api\include\basics\utilities\configanddpdiag.hxx"\
	"..\..\etm\pvss2\3.0\api\include\basics\utilities\dpconfignrtype.hxx"\
	"..\..\etm\pvss2\3.0\api\include\basics\utilities\dpelementtype.hxx"\
	"..\..\etm\pvss2\3.0\api\include\basics\utilities\dpidentifier.hxx"\
	"..\..\etm\pvss2\3.0\api\include\basics\utilities\dpidentlist.hxx"\
	"..\..\etm\pvss2\3.0\api\include\basics\utilities\dpidentlistitem.hxx"\
	"..\..\etm\pvss2\3.0\api\include\basics\utilities\dpidvaluelist.hxx"\
	"..\..\etm\pvss2\3.0\api\include\basics\utilities\dptypes.hxx"\
	"..\..\etm\pvss2\3.0\api\include\basics\utilities\dpvcitem.hxx"\
	"..\..\etm\pvss2\3.0\api\include\basics\utilities\dynptrarray.hxx"\
	"..\..\etm\pvss2\3.0\api\include\basics\utilities\dynptrarraytpl.hxx"\
	"..\..\etm\pvss2\3.0\api\include\basics\utilities\errclass.hxx"\
	"..\..\etm\pvss2\3.0\api\include\basics\utilities\errhdl.hxx"\
	"..\..\etm\pvss2\3.0\api\include\basics\utilities\fileutil.hxx"\
	"..\..\etm\pvss2\3.0\api\include\basics\utilities\langtext.hxx"\
	"..\..\etm\pvss2\3.0\api\include\basics\utilities\manageridentifier.hxx"\
	"..\..\etm\pvss2\3.0\api\include\basics\utilities\messagediag.hxx"\
	"..\..\etm\pvss2\3.0\api\include\basics\utilities\pathes.hxx"\
	"..\..\etm\pvss2\3.0\api\include\basics\utilities\projdirs.hxx"\
	"..\..\etm\pvss2\3.0\api\include\basics\utilities\ptrlist.hxx"\
	"..\..\ETM\PVSS2\3.0\api\include\Basics\Utilities\PtrList_Inl.hxx"\
	"..\..\etm\pvss2\3.0\api\include\basics\utilities\ptrlistitem.hxx"\
	"..\..\etm\pvss2\3.0\api\include\basics\utilities\pvssfilesys.hxx"\
	"..\..\etm\pvss2\3.0\api\include\basics\utilities\pvsstime.hxx"\
	"..\..\etm\pvss2\3.0\api\include\basics\utilities\resourcediag.hxx"\
	"..\..\etm\pvss2\3.0\api\include\basics\utilities\resources.hxx"\
	"..\..\etm\pvss2\3.0\api\include\basics\utilities\simpleptrarray.hxx"\
	"..\..\etm\pvss2\3.0\api\include\basics\utilities\types.hxx"\
	"..\..\etm\pvss2\3.0\api\include\basics\utilities\util.hxx"\
	"..\..\etm\pvss2\3.0\api\include\basics\variables\bit32var.hxx"\
	"..\..\etm\pvss2\3.0\api\include\basics\variables\bitvar.hxx"\
	"..\..\ETM\PVSS2\3.0\api\include\Basics\Variables\CharVar.hxx"\
	"..\..\etm\pvss2\3.0\api\include\basics\variables\dynvar.hxx"\
	"..\..\etm\pvss2\3.0\api\include\basics\variables\floatvar.hxx"\
	"..\..\etm\pvss2\3.0\api\include\basics\variables\integervar.hxx"\
	"..\..\etm\pvss2\3.0\api\include\basics\variables\langtextvar.hxx"\
	"..\..\etm\pvss2\3.0\api\include\basics\variables\recvar.hxx"\
	"..\..\etm\pvss2\3.0\api\include\basics\variables\textvar.hxx"\
	"..\..\etm\pvss2\3.0\api\include\basics\variables\timevar.hxx"\
	"..\..\etm\pvss2\3.0\api\include\basics\variables\uintegervar.hxx"\
	"..\..\etm\pvss2\3.0\api\include\basics\variables\variable.hxx"\
	"..\..\etm\pvss2\3.0\api\include\bcmnew\itciohandler.h"\
	"..\..\etm\pvss2\3.0\api\include\bcmnew\jcfportcomp.h"\
	"..\..\etm\pvss2\3.0\api\include\bcmnew\jcfportconf.h"\
	"..\..\etm\pvss2\3.0\api\include\bcmnew\jcfportmod.h"\
	"..\..\etm\pvss2\3.0\api\include\bcmnew\jcfportos.h"\
	"..\..\etm\pvss2\3.0\api\include\bcmnew\pcinc\un.h"\
	"..\..\etm\pvss2\3.0\api\include\configs\dpconfig.hxx"\
	"..\..\etm\pvss2\3.0\api\include\datapoint\aliastable.hxx"\
	"..\..\etm\pvss2\3.0\api\include\datapoint\aliastableitem.hxx"\
	"..\..\etm\pvss2\3.0\api\include\datapoint\dpidentification.hxx"\
	"..\..\etm\pvss2\3.0\api\include\datapoint\dpidentificationprosystem.hxx"\
	"..\..\etm\pvss2\3.0\api\include\datapoint\dpidentificationresulttype.hxx"\
	"..\..\etm\pvss2\3.0\api\include\datapoint\dpnamedpidcache.hxx"\
	"..\..\etm\pvss2\3.0\api\include\datapoint\dpsymidentifier.hxx"\
	"..\..\etm\pvss2\3.0\api\include\datapoint\dptype.hxx"\
	"..\..\etm\pvss2\3.0\api\include\datapoint\dptypecontainer.hxx"\
	"..\..\etm\pvss2\3.0\api\include\datapoint\dptypenode.hxx"\
	"..\..\etm\pvss2\3.0\api\include\datapoint\fixednumberstable.hxx"\
	"..\..\etm\pvss2\3.0\api\include\datapoint\fixednumberstableitem.hxx"\
	"..\..\etm\pvss2\3.0\api\include\datapoint\languagetable.hxx"\
	"..\..\etm\pvss2\3.0\api\include\datapoint\languagetableitem.hxx"\
	"..\..\etm\pvss2\3.0\api\include\datapoint\pathitem.hxx"\
	"..\..\etm\pvss2\3.0\api\include\manager\callbackitem.hxx"\
	"..\..\etm\pvss2\3.0\api\include\manager\diagconfiganddpitciohandler.hxx"\
	"..\..\etm\pvss2\3.0\api\include\manager\diaghotlinkwaitforanswer.hxx"\
	"..\..\etm\pvss2\3.0\api\include\manager\diagitciohandler.hxx"\
	"..\..\etm\pvss2\3.0\api\include\manager\diagmsgitciohandler.hxx"\
	"..\..\etm\pvss2\3.0\api\include\manager\filetransferlist.hxx"\
	"..\..\etm\pvss2\3.0\api\include\manager\hotlinkwaitforanswer.hxx"\
	"..\..\etm\pvss2\3.0\api\include\manager\manager.hxx"\
	"..\..\etm\pvss2\3.0\api\include\manager\usertable.hxx"\
	"..\..\etm\pvss2\3.0\api\include\manager\waitforanswer.hxx"\
	"..\..\etm\pvss2\3.0\api\include\messages\answergroup.hxx"\
	"..\..\etm\pvss2\3.0\api\include\messages\answeritem.hxx"\
	"..\..\etm\pvss2\3.0\api\include\messages\dphlgroup.hxx"\
	"..\..\etm\pvss2\3.0\api\include\messages\dpicgroup.hxx"\
	"..\..\etm\pvss2\3.0\api\include\messages\dpicitem.hxx"\
	"..\..\etm\pvss2\3.0\api\include\messages\dpidentifieritem.hxx"\
	"..\..\etm\pvss2\3.0\api\include\messages\dpmsg.hxx"\
	"..\..\etm\pvss2\3.0\api\include\messages\dpmsgalert.hxx"\
	"..\..\etm\pvss2\3.0\api\include\messages\dpmsganswer.hxx"\
	"..\..\etm\pvss2\3.0\api\include\messages\dpmsgconnection.hxx"\
	"..\..\etm\pvss2\3.0\api\include\messages\dpmsgfilterrequest.hxx"\
	"..\..\etm\pvss2\3.0\api\include\messages\dpmsghotlink.hxx"\
	"..\..\etm\pvss2\3.0\api\include\messages\dpvcgroup.hxx"\
	"..\..\etm\pvss2\3.0\api\include\messages\msg.hxx"\
	"..\..\etm\pvss2\3.0\api\include\messages\nameserversysmsg.hxx"\
	"..\..\etm\pvss2\3.0\api\include\messages\startdpinitsysmsg.hxx"\
	"..\..\etm\pvss2\3.0\api\include\messages\sysmsg.hxx"\
	"..\..\ETM\PVSS2\3.0\api\include\winnt\pvssincl\dirent.h"\
	"..\..\ETM\PVSS2\3.0\api\include\winnt\pvssincl\netdb.h"\
	"..\..\ETM\PVSS2\3.0\api\include\winnt\pvssincl\netinet\in.h"\
	"..\..\etm\pvss2\3.0\api\include\winnt\pvssincl\strstream.h"\
	"..\..\ETM\PVSS2\3.0\api\include\winnt\pvssincl\sys\ioctl.h"\
	"..\..\ETM\PVSS2\3.0\api\include\winnt\pvssincl\sys\socket.h"\
	"..\..\ETM\PVSS2\3.0\api\include\winnt\pvssincl\sys\time.h"\
	"..\..\ETM\PVSS2\3.0\api\include\winnt\pvssincl\unistd.h"\
	"..\..\smixx\smixx\smirtl.h"\
	"..\..\smixx\smixx\smirtl.hxx"\
	"..\..\smixx\smixx\smirtl_core.hxx"\
	"..\..\smixx\smixx\smiuirtl.h"\
	"..\..\smixx\smixx\smiuirtl.hxx"\
	"..\..\smixx\smixx\smiuirtl_core.hxx"\
	"..\..\smixx\smixx\smixx_common.hxx"\
	"..\src\ApiLib.hxx"\
	
# End Source File
# End Target
# End Project
