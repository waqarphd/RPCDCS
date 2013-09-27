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
strFile1 = "RegInput.txt"
strFile2 = "RegOutput.txt"

' Create the files
Dim objFile
Set objFile = objFSO.CreateTextFile(strDirectory & strFile1)
Set objFile = objFSO.CreateTextFile(strDirectory & strFile2)

' Clean after the job is done
Set objFSO = Nothing