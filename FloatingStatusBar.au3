#RequireAdmin
#Region ;**** Directives created by AutoIt3Wrapper_GUI ****
#AutoIt3Wrapper_Icon=FloatingStatusBar White.ico
#EndRegion ;**** Directives created by AutoIt3Wrapper_GUI ****
#include <GUIConstants.au3>
#include <Array.au3>
#include <Constants.au3>
#include <Timers.au3>

$sameProcessList = ProcessList("FloatingStatusBar.exe")

If UBound($sameProcessList) > 2 Then
	$res = MsgBox(36, "Attention", "An instance of this program is already running."&@CRLF&@CRLF&"Close old instance and re-launch program?")
	If $res == 6 Then
		For $i = 0 To UBound($sameProcessList) - 1
			If @AutoItPID == $sameProcessList[$i][1] Then ContinueLoop
			$childrenProc = GetChildProcessRecursive($sameProcessList[$i][1])
			ProcessClose($sameProcessList[$i][1])
			For $child In $childrenProc
				ProcessClose($child)
			Next
		Next
	Else
		Exit
	EndIf
EndIf

AutoItSetOption("TrayAutoPause",0)
AutoItSetOption("TrayMenuMode",3)
Opt("TrayOnEventMode", 1)

AutoItSetOption("GUIOnEventMode", 1)
$tiExit = TrayCreateItem("Exit")
TrayItemSetOnEvent($tiExit,"Quit")
TraySetToolTip("FloatingStatusBar")
OnAutoItExitRegister("Quit")
$iniFile = "Options.ini"

Dim $properties = ["CPU", "Temp", "Mem", "DL", "UL", "Lat"]
Dim $propertiesDefaultValue = ["000%", "000°C", "000%", "000,00KB/s", "000,00KB/s", "Time out"]
Dim $propertiesThresholds = [[50,80],[70,90],[50,80],[100,200],[20,40],[300, 700]]
Dim $activeProperties[UBound($properties)]
Dim $propertyLabels[UBound($properties)]
Dim $valueLabels[UBound($properties)]

Local $GUI_HIDDEN = False

Local $CFG_LATENCYHOST, $CFG_TRANSPARENCY, $CFG_FONTSIZE, _
	  $CFG_FONTWEIGHT, $CFG_FONTNAME, $CFG_COLOR_HIGH, _
	  $CFG_COLOR_MID, $CFG_COLOR_NORMAL, $CFG_COLOR_BACKGROUND, _
	  $CFG_COLOR_LABEL, $CFG_BITS, $CFG_AUTOHIDE, $CFG_POSITION, _
	  $CFG_ONTOPTASKBAR, $CFG_FORCEALWAYSONTOP, $CFG_GUIOFFSETX, _
	  $CFG_GUIOFFSETY, $CFG_SPACING

Main()

Func Main()
	LoadOptions()
	Global $mainGui = CreateGui()
	CreatePropertyLabels($mainGui)

	While 1
		$networkData = (IsPropertyEnabled("DL") Or IsPropertyEnabled("UL")) ? GetNetworkData() : Null
		For $prop = 0 To UBound($properties) - 1
			If Not $activeProperties[$prop] Then ContinueLoop
			ConsoleWrite(@CRLF & $properties[$prop] & @CRLF)
			$param = ($prop == 3 Or $prop == 4) ? $networkData : Null
			Dim $thresholds = [$propertiesThresholds[$prop][0], $propertiesThresholds[$prop][1]]

			$returnedValue = Call($properties[$prop], $thresholds, $param)

			GUICtrlSetData($valueLabels[$prop], $returnedValue[0])
			GUICtrlSetColor($valueLabels[$prop], $returnedValue[1])
		Next
		If Not IsPropertyEnabled("DL") And Not IsPropertyEnabled("UL") Then Sleep(1000)
		While $CFG_AUTOHIDE And CheckMouse()
			Sleep(100)
		WEnd
		If $CFG_FORCEALWAYSONTOP Then WinSetOnTop($mainGui, "",1)
	WEnd
EndFunc

Func Quit()
	$children = GetChildProcessRecursive(@AutoItPID)
	For $child In $children
		ProcessClose($child)
	Next
	Exit
EndFunc

Func CheckMouse()
	$mouseCoords = MouseGetPos()
	$winCoords = WinGetPos($mainGui)
	If $mouseCoords[0] >= $winCoords[0] And $mouseCoords[0] <= $winCoords[0] + $winCoords[2] And _
	   $mouseCoords[1] >= $winCoords[1] And $mouseCoords[1] <= $winCoords[1] + $winCoords[3] Then
	   If Not $GUI_HIDDEN Then
			ToggleGUI(False)
			$GUI_HIDDEN = True
	   EndIf
	   Return True
	ElseIf $GUI_HIDDEN Then
		ToggleGUI(True)
		$GUI_HIDDEN = False
		Return False
	EndIf
EndFunc

Func GetNetworkData()
	$timer = _Timer_Init()
	$networkBytePerSecStart = GetNetworkBytesPerSec()
	$diff = TimerDiff($timer)
	Sleep(Abs(1000 - $diff))
	$networkBytePerSecEnd = GetNetworkBytesPerSec()
	$networkData = CalcNetworkRates($networkBytePerSecStart, $networkBytePerSecEnd)
	Return $networkData
EndFunc

Func CPU($thresholds,$null)
	$currentValue = GetProcessorPercent()
	$color = $currentValue >= $thresholds[1] ?  $CFG_COLOR_HIGH : $currentValue >= $thresholds[0] ?  $CFG_COLOR_MID : $CFG_COLOR_NORMAL
	Dim $returnArr = [StringFormat("%02i",$currentValue) & "%", $color]
	Return $returnArr
EndFunc

Func Temp($thresholds,$null)
	$currentValue = GetCpuTemperature()
	$color = $currentValue >= $thresholds[1] ?  $CFG_COLOR_HIGH : $currentValue >= $thresholds[0] ?  $CFG_COLOR_MID : $CFG_COLOR_NORMAL
	Dim $returnArr = [StringFormat("%02i",$currentValue) & "°C", $color]
	Return $returnArr
EndFunc

Func Mem($thresholds,$null)
	$currentValue = GetMemoryPercent()
	$color = $currentValue >= $thresholds[1] ?  $CFG_COLOR_HIGH : $currentValue >= $thresholds[0] ?  $CFG_COLOR_MID : $CFG_COLOR_NORMAL
	Dim $returnArr = [StringFormat("%02i",$currentValue) & "%", $color]
	Return $returnArr
EndFunc

Func DL($thresholds, $networkData)
	$downloadSpeed = $networkData[0]
	$color = $downloadSpeed >= $thresholds[1] ?  $CFG_COLOR_HIGH : $downloadSpeed >= $thresholds[0] ?  $CFG_COLOR_MID : $CFG_COLOR_NORMAL
	$bitOrBytes = $CFG_BITS ? "b" : "B"
	$unit =  $downloadSpeed > 999 ? "M"&$bitOrBytes&"/s" : "K"&$bitOrBytes&"/s"
	$rate = $downloadSpeed > 999 ? $downloadSpeed / 1024 : $downloadSpeed
	Dim $returnArr = [StringFormat("%.2f",$rate) & $unit, $color]
	Return $returnArr
EndFunc

Func UL($thresholds, $networkData)
	$uploadSpeed = $networkData[1]
	$color = $uploadSpeed >= $thresholds[1] ?  $CFG_COLOR_HIGH : $uploadSpeed >= $thresholds[0] ?  $CFG_COLOR_MID : $CFG_COLOR_NORMAL
	$bitOrBytes = $CFG_BITS ? "b" : "B"
	$unit =  $uploadSpeed > 999 ? "M"&$bitOrBytes&"/s" : "K"&$bitOrBytes&"/s"
	$rate = $uploadSpeed > 999 ? $uploadSpeed / 1024 : $uploadSpeed
	Dim $returnArr = [StringFormat("%.2f",$rate) & $unit, $color]
	Return $returnArr
EndFunc

Func Lat($thresholds, $null)
	ConsoleWrite(@CRLF & "Running LAT Function." & @CRLF)
	$currentValue = Ping($CFG_LATENCYHOST)
	$currentValue = $currentValue <> 0 ? $currentValue : -1
	$color = ($currentValue >= $thresholds[1] Or $currentValue == -1 ) ?  $CFG_COLOR_HIGH : $currentValue >= $thresholds[0] ?  $CFG_COLOR_MID : $CFG_COLOR_NORMAL
	$unit = $currentValue > 999 ? "sec" : "ms"
	$currentValue = $currentValue == -1 ? "Time out" : ($currentValue > 999 ? Round($currentValue / 1000) : $currentValue) & $unit
	Dim $returnArr = [$currentValue, $color]
	Return $returnArr
EndFunc

Func IsPropertyEnabled($prop)
	For $i = 0 To UBound($properties) - 1
		If $properties[$i] == $prop Then Return $activeProperties[$i]
	Next
EndFunc

Func LoadOptions()
	$CFG_LATENCYHOST = IniRead($iniFile, "Preferences", "LatencyHost", "8.8.8.8")
	$CFG_TRANSPARENCY = IniRead($iniFile, "Apparence", "Opacity", 150)
	$CFG_FONTSIZE = IniRead($iniFile, "Apparence", "FontSize", 12)
	$CFG_FONTWEIGHT = IniRead($iniFile, "Apparence", "FontWeight", 900)
	$CFG_FONTNAME = IniRead($iniFile, "Apparence", "FontName", "")
	$CFG_COLOR_NORMAL = IniRead($iniFile, "Colors", "NormalValue", 0x0dbc4d)
	$CFG_COLOR_MID = IniRead($iniFile, "Colors", "MediumValue", 0xb2b035)
	$CFG_COLOR_HIGH = IniRead($iniFile, "Colors", "HighValue", 0xc91306)
	$CFG_COLOR_LABEL = IniRead($iniFile, "Colors", "Label", 0x1670f7)
	$CFG_COLOR_BACKGROUND = IniRead($iniFile, "Colors", "Background", 0xDFDFDF)
	$CFG_BITS = IniToBool(IniRead($iniFile, "Preferences", "BitsPerSeconds", False))
	$CFG_AUTOHIDE = IniToBool(IniRead($iniFile, "Preferences", "AutoHide", False))
	$CFG_POSITION = IniRead($iniFile, "Apparence", "Position", "top-mid")
	$CFG_ONTOPTASKBAR = IniToBool(IniRead($iniFile, "Apparence", "OnTopOfTaskbar", False))
	$CFG_FORCEALWAYSONTOP = IniToBool(IniRead($iniFile, "Preferences", "RefreshAlwaysOnTop", False))
	$CFG_GUIOFFSETX = IniRead($iniFile, "Apparence", "OffsetX", 0)
	$CFG_GUIOFFSETY = IniRead($iniFile, "Apparence", "OffsetY", 0)
	$CFG_SPACING = IniRead($iniFile, "Apparence", "Spacing", 10)
	For $i = 0 To UBound($properties) - 1
		$activeProperties[$i] = IniToBool(IniRead($iniFile, "Active Items", $properties[$i], True))
		$propertiesThresholds[$i][0] = IniRead($iniFile, $properties[$i], "Medium", $propertiesThresholds[$i][0])
		$propertiesThresholds[$i][1] = IniRead($iniFile, $properties[$i], "High", $propertiesThresholds[$i][1])
	Next
EndFunc

Func CreateGui()
	$GUI = GUICreate ("FloatingStatusBar", 0, 0,0, 0, $WS_POPUP, BitOR ($WS_EX_TRANSPARENT, $WS_EX_LAYERED, $WS_EX_TOPMOST,$WS_EX_TOOLWINDOW))
	WinSetTrans ($GUI, "", $CFG_TRANSPARENCY)
	GUISetBkColor($CFG_COLOR_BACKGROUND, $GUI)
	GUISetState(@SW_SHOW,$GUI)
	GUISetFont($CFG_FONTSIZE,$CFG_FONTWEIGHT,0,$CFG_FONTNAME)
	;GUISetOnEvent($GUI_EVENT_MOUSEMOVE, "CheckMouse", $GUI)
	Return $GUI
EndFunc

Func ToggleGUI($state)
	$start = $state ? 0 : $CFG_TRANSPARENCY
	$end = $state ? $CFG_TRANSPARENCY : 0
	$step = 10 * ($state ? 1 : -1)
	For $i = $start To $end Step $step
		WinSetTrans($mainGui,"", $i)
		Sleep(25)
	Next
EndFunc

Func CreatePropertyLabels($GUI)
	$lastLabelPos = Null
	For $i = 0 To UBound($properties) - 1
		If Not $activeProperties[$i] Then ContinueLoop
		$xCoord = $lastLabelPos <> Null ? $lastLabelPos[0] + $lastLabelPos[2] : 0
		$space = $i == 0 ? 0 : $CFG_SPACING;
		$propertyLabels[$i] = CreateGuiLabel($properties[$i] & ":", $xCoord  + $space, $CFG_COLOR_LABEL)
		$lastLabelPos = ControlGetPos($GUI, "", $propertyLabels[$i])
		$valueLabels[$i] = CreateGuiLabel($propertiesDefaultValue[$i], $lastLabelPos[0] + $lastLabelPos[2] - 4, $CFG_COLOR_NORMAL)
		$lastLabelPos = ControlGetPos($GUI, "", $valueLabels[$i])
	Next
	$newMainGuiWidth = $lastLabelPos[0] + $lastLabelPos[2]
	Dim $guiSize[2] = [$lastLabelPos[0] + $lastLabelPos[2], $lastLabelPos[3] - 2]
	$guiPosition = GetGUIPosition($guiSize)
	WinMove($GUI, "", $guiPosition[0], $guiPosition[1], $guiSize[0], $guiSize[1])
EndFunc

Func GetGUIPosition($guiSize)
	Dim $position[2]
	$taskbarPos = WinGetPos("[CLASS:Shell_TrayWnd]")
	$taskbarHeight = @error ? 30 : $taskbarPos[3]
	$bottomY = @DesktopHeight - $guiSize[1] - ($CFG_ONTOPTASKBAR ? 0 : $taskbarHeight)
	$horizontalMiddle = @DesktopWidth / 2 - $guiSize[0] / 2
	$guiOffsets = GetGuiOffsets()
	Switch $CFG_POSITION
		Case "top-left"
			$position[0] = 0
			$position[1] = 0
		Case "top-right"
			$position[0] = @DesktopWidth - $guiSize[0]
			$position[1] = 0
		Case "bottom-mid"
			$position[0] = $horizontalMiddle
			$position[1] = $bottomY
		Case "bottom-left"
			$position[0] = 0
			$position[1] = $bottomY
		Case "bottom-right"
			$position[0] = @DesktopWidth - $guiSize[0]
			$position[1] = $bottomY
		Case Else
			$position[0] = $horizontalMiddle
			$position[1] = 0
	EndSwitch
	$position[0] += $guiOffsets[0]
	$position[1] += $guiOffsets[1]
	Return $position
EndFunc

Func GetGuiOffsets()
	$offsetX = ($CFG_GUIOFFSETX * @DesktopWidth) / 100
	$offsetY = ($CFG_GUIOFFSETY * @DesktopHeight) / 100
	Dim $offsets[2] = [$offsetX, $offsetY]
	Return $offsets
EndFunc

Func CreateGuiLabel($text, $xCoord, $color)
	$label = GUICtrlCreateLabel($text, $xCoord, 0,-1,-1, BitOR($SS_CENTERIMAGE, $SS_CENTER))
	GUICtrlSetColor($label,$color)
	Return $label
EndFunc

Func IniToBool($value)
	If IsBool($value) Then Return $value
	If StringIsInt($value) Then Return $value <> "0"
	If IsString($value) Then Return StringLower($value) == "true"
EndFunc

Func QueryWMI($namespace, $class, $property, $condition = "")
	Local $wbemFlagReturnImmediately = 0x10, $wbemFlagForwardOnly = 0x20
    $objWMIService = ObjGet("winmgmts:\\localhost\root\" & $namespace)
    $wmiResponseObject = $objWMIService.ExecQuery("SELECT " & $property & _
												  " FROM " & $class & _
												  " " & $condition, _
												  "WQL", $wbemFlagReturnImmediately + $wbemFlagForwardOnly)
	If IsObj($wmiResponseObject) Then
		Return $wmiResponseObject
	Else
		Dim $emptyArray[0]
		Return $emptyArray
	EndIf
EndFunc

Func GetProcessorPercent()
	$processorUsage = -1
	$wmiObj = QueryWMI("CIMV2", "Win32_PerfFormattedData_PerfOS_Processor", "PercentProcessorTime", "WHERE Name = '_Total'")
	For $col in $wmiObj
		$processorUsage = $col.PercentProcessorTime * 1
	Next
	Return $processorUsage
EndFunc

Func GetMemoryPercent()
	$wmiObj = QueryWMI("CIMV2", "Win32_PerfFormattedData_PerfOS_Memory", "AvailableBytes")
	$availableMemory = 0
	For $col in $wmiObj
		$availableMemory = $col.AvailableBytes
	Next
	$wmiObj = QueryWMI("CIMV2", "Win32_PhysicalMemory", "Capacity")
	$totalMemory = 0
	For $col in $wmiObj
		$totalMemory += $col.Capacity
	Next
	Return $availableMemory <> 0 And $totalMemory <> 0 ? 100 - Floor(($availableMemory * 100) / $totalMemory) : -1
EndFunc

Func GetCpuTemperature()
	$wmiObj = QueryWMI("WMI", "MSAcpi_ThermalZoneTemperature", "CurrentTemperature", "WHERE CurrentTemperature > 2732")
	$cpuTemperature = -1
	For $col in $wmiObj
		$cpuTemperature = ($col.CurrentTemperature -2732) / 10
		exitloop
	Next
	Return $cpuTemperature
EndFunc

Func GetNetworkBytesPerSec()
	$wmiObj = QueryWMI("CIMV2", "Win32_PerfRawData_Tcpip_NetworkInterface", "Name, BytesReceivedPersec, BytesSentPersec")
	Dim $bytesPerSec[2] = [0, 0]
	For $col in $wmiObj
		$bytesPerSec[0] += $col.BytesReceivedPersec
		$bytesPerSec[1] += $col.BytesSentPersec
	Next
	Return $bytesPerSec
EndFunc

Func CalcNetworkRates($bytesPerSecOld, $bytesPerSecNew)
	Dim $bytesPerSec[2]
	For $i = 0 To 1
		$bytesPerSec[$i] = Round(($bytesPerSecNew[$i] - $bytesPerSecOld[$i]) / 1024 * ($CFG_BITS ? 8 : 1), 2)
	Next
	Return $bytesPerSec
EndFunc

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

Func GetChildProcessRecursive($pid, $children = Null, $mark = 0)
	If $children == Null Then
		$children = GetChildProcess($pid)
		If UBound($children) == 0 Then
			Dim $emptyArray[0]
			Return $emptyArray
		EndIf
		Return GetChildProcessRecursive($children[0], $children, $mark)
	Else
		$newChilds = GetChildProcess($pid)
		If UBound($newChilds) == 0 And $mark = UBound($children) - 1 Then Return $children
		_ArrayAdd($children, GetChildProcess($pid))
		Return GetChildProcessRecursive($children[$mark + 1], $children, $mark + 1)
	EndIf
EndFunc