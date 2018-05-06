#Include <ColorPicker.au3>
#Include <WinAPI.au3>

Opt('MustDeclareVars', 1)

Global $hForm, $Msg, $Label, $Picker1, $Picker2, $Picker3, $Data, $hInstance, $hCursor

$hForm = GUICreate('Color Picker', 300, 200)

; Load cursor
$hInstance = _WinAPI_LoadLibrary(@SystemDir & '\mspaint.exe')
$hCursor = DllCall('user32.dll', 'ptr', 'LoadCursor', 'ptr', $hInstance, 'dword', 1204)
$hCursor = $hCursor[0]
_WinAPI_FreeLibrary($hInstance)

; Create Picker1 with custom cursor
$Picker1 = _GUIColorPicker_Create('', 100, 50, 44, 44, 0xFF6600, BitOR($CP_FLAG_DEFAULT, $CP_FLAG_CHOOSERBUTTON), 0, -1, -1, $hCursor, 'Simple Text')

; Free cursor
DllCall('user32.dll', 'int', 'DestroyCursor', 'ptr', $hCursor)

; Create custom (4 x 5) color palette
Dim $aPalette[20] = _
    [0xFFFFFF, 0x000000, 0xC0C0C0, 0x808080, _
     0xFF0000, 0x800000, 0xFFFF00, 0x808000, _
     0x00FF00, 0x008000, 0x00FFFF, 0x008080, _
     0x0000FF, 0x000080, 0xFF00FF, 0x800080, _
     0xC0DCC0, 0xA6CAF0, 0xFFFBF0, 0xA0A0A4]

; Create Picker2 with custom color palette
$Picker2 = _GUIColorPicker_Create('', 7, 170, 50, 23, 0xFF00FF, BitOR($CP_FLAG_CHOOSERBUTTON, $CP_FLAG_ARROWSTYLE, $CP_FLAG_MOUSEWHEEL), $aPalette, 4, 5, 0, '', 'More...')

; Create custom (8 x 8) color palette
Dim $aPalette[64]
For $i = 0 To UBound($aPalette) - 1
    $aPalette[$i] = BitOR($i, BitShift($i * 4, -8), BitShift($i, -16))
Next

; Create Picker3 with custom color palette
$Picker3 = _GUIColorPicker_Create('Color...', 223, 170, 70, 23, 0x2DB42D, BitOR($CP_FLAG_TIP, $CP_FLAG_MAGNIFICATION), $aPalette, 8, 8)
$Label = GUICtrlCreateLabel('', 194, 171, 22, 22, $SS_SUNKEN)
GUICtrlSetBkColor(-1, 0x2DB42D)
GUICtrlSetTip(-1, '2DB42D')

GUISetState()

While 1
    $Msg = GUIGetMsg()
    Switch $Msg ; Color Picker sends the message that the color is selected
        Case -3
            ExitLoop
        Case $Picker1
            $Data = _GUIColorPicker_GetColor($Picker1, 1)
            If $Data[1] = '' Then
                $Data[1] = 'Custom'
            EndIf
            ConsoleWrite('Picker1: 0x' & Hex($Data[0], 6) & ' (' & $Data[1] & ')' & @CR)
        Case $Picker2
            ConsoleWrite('Picker2: 0x' & Hex(_GUIColorPicker_GetColor($Picker2), 6) & @CR)
        Case $Picker3
            $Data = _GUIColorPicker_GetColor($Picker3)
            ConsoleWrite('Picker3: 0x' & Hex($Data, 6) & @CR)
            GUICtrlSetBkColor($Label, $Data)
            GUICtrlSetTip($Label, Hex($Data, 6))
    EndSwitch
WEnd