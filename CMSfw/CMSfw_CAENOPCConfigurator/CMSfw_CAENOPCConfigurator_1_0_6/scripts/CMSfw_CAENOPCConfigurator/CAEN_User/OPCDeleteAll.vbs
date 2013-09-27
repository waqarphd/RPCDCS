Const HKEY_CURRENT_USER = &H80000001
Const HKEY_LOCAL_MACHINE = &H80000002
Const HKEY_USERS = &H80000003

Const FOR_WRITING = 2

' Handle the given Arguments
Dim arg, path

If (WScript.Arguments.Count <> 1) Then
  WScript.Quit (0)
Else
  Set arg = WScript.Arguments
  path = arg.Item(0)
End If

' Parameters for registry operations.
Dim dwValue, StdOut, oShell, strValue, strCrateName, strCrateIP, crateNum

' Object used for All VBS operations
Dim objFSO
Set objFSO = CreateObject("Scripting.FileSystemObject")

' Prepare the operation of deleting the entries from the registry
strComputer = "."
Set StdOut = WScript.StdOut
Set oShell = CreateObject("WScript.Shell")
 
' Specific string for the registry
Set oReg = GetObject("winmgmts:{impersonationLevel=impersonate}!\\" & strComputer & "\root\default:StdRegProv")

' Path to the CAEN entry for the count of the CAEN crates in.
strKeyPath = ".DEFAULT\Software\CAEN/CERN\CAENHVOPCServer\Settings"
strValueName = "HVPSNum"
' Take the count
oReg.GetDWORDValue HKEY_USERS, strKeyPath, strValueName, strValue

if isnull(strValue) = True then
crateNum = 0
else
crateNum = strValue
end if


' Follows the deletition
sComputer = "."
sMethod = "DeleteValue"
hTree = HKEY_USERS
sKey = ".DEFAULT\Software\CAEN/CERN\CAENHVOPCServer\Settings"
sValueName = "ToBeDeleted"

Set oRegistry = GetObject("winmgmts:{impersonationLevel=impersonate}//" & sComputer & "/root/default:StdRegProv")

Set oMethod = oRegistry.Methods_(sMethod)
Set oInParam = oMethod.inParameters.SpawnInstance_()


Dim i

' Delete every instance of CAEN crates
For i = 0 To crateNum - 1

sValueName = i
oInParam.hDefKey = hTree
oInParam.sSubKeyName = sKey
oInParam.sValueName = sValueName

Set oOutParam = oRegistry.ExecMethod_(sMethod, oInParam)

Next

' Set the count of registered CAEN crates to 0
strValueName = "HVPSNum"
oReg.SetDWORDValue HKEY_USERS, strKeyPath, strValueName, 0

' Restart the CAENHVOPCServer.exe process so the changes to stay

'Option Explicit

'Stop the CAENOPC Server Windows service
Set objShell = CreateObject("WScript.Shell")
Set objScriptExec = objShell.Exec("net stop CAENHVOPCServer")

'Wait 1/2 sec
intSleep = 500
WScript.Sleep intSleep

'And start it again
Set objScriptExec = objShell.Exec("net start CAENHVOPCServer")


' Send message to PVSS through a file that the operation is completed.
Dim strDirectory, strFile
strDirectory = path
strFile = "RegOutput.txt"
strMessage = "ok"

' Open the file for writing the data
Dim objTextStream
Set objTextStream = objFSO.OpenTextFile(strDirectory & strFile, FOR_WRITING)

objTextStream.WriteLine strMessage

' Clean after the job is done
objTextStream.Close
Set objTextStream = Nothing
Set objFSO = Nothing
