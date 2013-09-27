
'Stop the CAENOPC Server Windows service
Set objShell = CreateObject("WScript.Shell")
Set objScriptExec = objShell.Exec("net stop CAENHVOPCServer")

'Wait 1/2 sec
intSleep = 500
WScript.Sleep intSleep

'And start it again
Set objScriptExec = objShell.Exec("net start CAENHVOPCServer")

