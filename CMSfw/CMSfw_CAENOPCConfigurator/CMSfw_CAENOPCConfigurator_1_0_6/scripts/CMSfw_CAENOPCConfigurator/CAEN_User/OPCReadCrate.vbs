Const HKEY_CURRENT_USER = &H80000001
Const HKEY_LOCAL_MACHINE = &H80000002
Const HKEY_USERS = &H80000003

Const FOR_WRITING = 2

' Handle the given Arguments
Dim arg, path

If (WScript.Arguments.Count <> 1) Then  
  WScript.Quit(0)
Else
  Set arg = WScript.Arguments
  path = arg.Item(0)
End If

'Object used for All VBS operations
Dim objFSO
Set objFSO = CreateObject("Scripting.FileSystemObject")

Dim strDirectory, strFile
strDirectory = path
strFile = "RegOutput.txt"

'Dim objFile

' Parameters for general use
Dim dwValue, StdOut, oShell, strValue, strCrateName, strCrateIP, crateNum

' Prepare the operation of retrieving the entries from the registry
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


' Open the file for writing the data
Dim objTextStream
Set objTextStream = objFSO.OpenTextFile(strDirectory & strFile, FOR_WRITING)

Dim crateStrValue
Dim i

' In a loop take every entry and put it as a line in the RegOutput.txt
For i = 0 To crateNum - 1
strKeyPath = ".DEFAULT\Software\CAEN/CERN\CAENHVOPCServer\Settings"
strValueName = i
oReg.GetStringValue HKEY_USERS, strKeyPath, strValueName, crateStrValue
objTextStream.WriteLine crateStrValue
Next

' Clean after the job is done
objTextStream.Close
Set objTextStream = Nothing
Set objFSO = Nothing
