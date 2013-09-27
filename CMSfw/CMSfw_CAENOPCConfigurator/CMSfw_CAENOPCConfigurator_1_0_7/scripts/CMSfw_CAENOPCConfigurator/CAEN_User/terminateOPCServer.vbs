
'Stop the CAENOPC Server Windows service
Set objShell = CreateObject("WScript.Shell")
Set objScriptExec = objShell.Exec("taskkill /F /IM CAENHVOPCServer.exe")

'Wait 1/2 sec
intSleep = 500
WScript.Sleep intSleep


