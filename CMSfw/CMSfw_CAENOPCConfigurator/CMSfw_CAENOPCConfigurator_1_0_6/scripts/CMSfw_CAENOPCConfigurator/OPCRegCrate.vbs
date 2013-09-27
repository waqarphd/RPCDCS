Const HKEY_CURRENT_USER = &H80000001
Const HKEY_LOCAL_MACHINE = &H80000002
Const HKEY_USERS = &H80000003

Const FOR_WRITING = 2

' Parameters for the registry operations
Dim dwValue, StdOut, oShell, strValue, strCrateName, strCrateIP, crateNum, path

' take the arguments given to the script
Dim arg
If (WScript.Arguments.Count <> 3) Then
  WScript.Quit (0)
Else
  Set arg = WScript.Arguments
  
  path = arg.Item(0)
  strCrateName = arg.Item(1)
  strCrateIP = arg.Item(2)
End If

' Object used for All VBS operations
Dim objFSO
Set objFSO = CreateObject("Scripting.FileSystemObject")

' Prepare the registry strings
strComputer = "."
Set StdOut = WScript.StdOut
 
Set oReg = GetObject("winmgmts:{impersonationLevel=impersonate}!\\" & strComputer & "\root\default:StdRegProv")
 
' Take the count of the CAEN crates in the registry
strKeyPath = ".DEFAULT\Software\CAEN/CERN\CAENHVOPCServer\Settings"
strValueName = "HVPSNum"
oReg.GetDWORDValue HKEY_USERS, strKeyPath, strValueName, strValue
crateNum = strValue

' Add new crate in the registry
strValueName = crateNum
strValue = strCrateName & ",0," & strCrateIP
oReg.SetStringValue HKEY_USERS, strKeyPath, strValueName, strValue
 
' Update the count of the crates in the registry
crateNum = crateNum + 1
strValueName = "HVPSNum"
oReg.SetDWORDValue HKEY_USERS, strKeyPath, strValueName, crateNum

' Restart the CAENHVOPCServer.exe process so the changes to stay

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


