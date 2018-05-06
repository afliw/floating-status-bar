#include <Array.au3>
#include <Timers.au3>

OnAutoItExitRegister("Quit")

;$hostname = "www.google.com"

TCPStartup()
Opt("TCPTimeout", 4000)
$timer = TimerInit()
$res = TCPConnect("8.8.8.8", 53)
; Acá habría que hacer un TCPConnect al proxy, y un TCPSend a ese socket pidiendo google.com, y cuando haya respuesta, cortarla
$errorCode = @error
$delay = TimerDiff($timer)
TCPCloseSocket($res)

If $res > 0 Then
	MsgBox(0, "Time", "Latency: "&Round($delay,2)&"ms")
Else
	MsgBox(16, "Error", "Couldn't connect to host."&@CRLF&@CRLF&"Error code: "& $errorCode)
EndIf


Func Quit()
	TCPShutdown()
EndFunc