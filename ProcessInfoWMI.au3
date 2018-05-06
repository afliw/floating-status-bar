#include <Array.au3>


$arr = GetChildProcess(1388)

For $a In $arr
	ProcessClose($a)
Next


Func GetChildProcess($pid)
	Local $wbemFlagReturnImmediately = 0x10, $wbemFlagForwardOnly = 0x20
	$oWMI=ObjGet("winmgmts:{impersonationLevel=impersonate}!\\" & @ComputerName & "\root\cimv2")
	$oProcessColl=$oWMI.ExecQuery('SELECT * FROM Win32_Process WHERE ParentProcessId = ' & $pid, "WQL", $wbemFlagReturnImmediately + $wbemFlagForwardOnly)
	Dim $childs[0]
	For $Process In $oProcessColl
		ReDim $childs[UBound($childs)+1]
		$childs[UBound($childs) - 1] = $Process.ProcessId
	Next
	Return $childs
EndFunc



