
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

Dim strDirectory, strFile1, strFile2

strDirectory = path
strFile1 = "RegOutput.txt"
strFile2 = "RegInput.txt"

' Delete the files

If objFSO.FileExists(strDirectory & strFile1) Then
 objFSO.DeleteFile strDirectory & strFile1 
End If

If objFSO.FileExists(strDirectory & strFile2) Then
objFSO.DeleteFile strDirectory & strFile2
End If

' Clean after the job is done
Set objFSO = Nothing