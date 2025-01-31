
; #FUNCTION# ====================================================================================================================
; Name ..........: LocateClanCastle
; Description ...: Locates Clan Castle manually (Temporary)
; Syntax ........: LocateClanCastle()
; Parameters ....:
; Return values .: None
; Author ........:
; Modified ......: KnowJack (06/2015) Sardo (08/2015)
; Remarks .......: This file is part of MyBot, previously known as ClashGameBot. Copyright 2015-2019
;                  MyBot is distributed under the terms of the GNU GPL
; Related .......:
; Link ..........: https://github.com/MyBotRun/MyBot/wiki
; Example .......: No
; ===============================================================================================================================
Func LocateClanCastle($bFromButton = False)
	Local $wasRunState = $g_bRunState
	$g_bRunState = True
	AndroidShield("LocateClanCastle 1")
	Local $result = _LocateClanCastle()
	$g_bRunState = $wasRunState
	AndroidShield("LocateClanCastle 2")
	Return $result
EndFunc   ;==>LocateClanCastle

Func _LocateClanCastle()
	Local $sText, $MsgBox, $iSilly = 0, $iStupid = 0, $sErrorText = "", $sInfo
	If Int($g_iTownHallLevel) < 3 Then Return
	SetLog("Locating Clan Castle...", $COLOR_INFO)
	ZoomOut()
	Collect(False, False)
	$g_aiClanCastlePos[0] = -1
	$g_aiClanCastlePos[1] = -1
	If DetectedCastle() Then Return True
	While 1
		_ExtMsgBoxSet(1 + 64, $SS_CENTER, 0x004080, 0xFFFF00, 12, "Tahoma", 500)
		$sText = $sErrorText & @CRLF & GetTranslatedFileIni("MBR Popups", "Func_Locate_Clan_Castle_01", "Click OK then click on your Clan Castle") & @CRLF & @CRLF & GetTranslatedFileIni("MBR Popups", "Locate_building_01", "Do not move mouse quickly after clicking location") & @CRLF & @CRLF & GetTranslatedFileIni("MBR Popups", "Locate_building_02", "Make sure the building name is visible for me!") & @CRLF
		$MsgBox = _ExtMsgBox(0, GetTranslatedFileIni("MBR Popups", "Ok_Cancel", "Ok|Cancel"), GetTranslatedFileIni("MBR Popups", "Func_Locate_Clan_Castle_02", "Locate Clan Castle at ") & $g_sAndroidTitle, $sText, 15)
		If $MsgBox = 1 Then
			WinGetAndroidHandle()
			ClickP($aAway, 1, 0, "#0373")
			Local $aPos = FindPos()
			$g_aiClanCastlePos[0] = $aPos[0]
			$g_aiClanCastlePos[1] = $aPos[1]
			If isInsideDiamond($g_aiClanCastlePos) = False Then
				$iStupid += 1
				Select
					Case $iStupid = 1
						$sErrorText = "Clan Castle Location Not Valid!" & @CRLF
						SetLog("Location not valid, try again", $COLOR_ERROR)
						ContinueLoop
					Case $iStupid = 2
						$sErrorText = "Please try to click inside the grass field!" & @CRLF
						ContinueLoop
					Case $iStupid = 3
						$sErrorText = "This is not funny, why did you click @ (" & $g_aiClanCastlePos[0] & "," & $g_aiClanCastlePos[1] & ")?" & @CRLF & "  Please stop!" & @CRLF & @CRLF
						ContinueLoop
					Case $iStupid = 4
						$sErrorText = "Last Chance, DO NOT MAKE ME ANGRY, or" & @CRLF & "I will give ALL of your gold to Barbarian King," & @CRLF & "And ALL of your Gems to the Archer Queen!" & @CRLF
						ContinueLoop
					Case $iStupid > 4
						SetLog(" Operator Error - Bad Clan Castle Location: " & "(" & $g_aiClanCastlePos[0] & "," & $g_aiClanCastlePos[1] & ")", $COLOR_ERROR)
						ClickP($aAway, 1, 0, "#0374")
						Return False
					Case Else
						SetLog(" Operator Error - Bad Clan Castle Location: " & "(" & $g_aiClanCastlePos[0] & "," & $g_aiClanCastlePos[1] & ")", $COLOR_ERROR)
						$g_aiClanCastlePos[0] = -1
						$g_aiClanCastlePos[1] = -1
						ClickP($aAway, 1, 0, "#0375")
						Return False
				EndSelect
			EndIf
			SetLog("Clan Castle: " & "(" & $g_aiClanCastlePos[0] & "," & $g_aiClanCastlePos[1] & ")", $COLOR_SUCCESS)
		Else
			SetLog("Locate Clan Castle Cancelled", $COLOR_INFO)
			ClickP($aAway, 1, 0, "#0376")
			Return
		EndIf
		$sInfo = BuildingInfo(242, 490 + $g_iBottomOffsetY); 860x780
		If IsArray($sInfo) And ($sInfo[0] > 1 Or $sInfo[0] = "") Then
			If StringInStr($sInfo[1], "clan") = 0 Then
				Local $sLocMsg = ($sInfo[0] = "" ? "Nothing" : $sInfo[1])
				$iSilly += 1
				Select
					Case $iSilly = 1
						$sErrorText = "Wait, That is not the Clan Castle?, It was a " & $sLocMsg & @CRLF
						ContinueLoop
					Case $iSilly = 2
						$sErrorText = "Quit joking, That was " & $sLocMsg & @CRLF
						ContinueLoop
					Case $iSilly = 3
						$sErrorText = "This is not funny, why did you click " & $sLocMsg & "? Please stop!" & @CRLF
						ContinueLoop
					Case $iSilly = 4
						$sErrorText = $sLocMsg & " ?!?!?!" & @CRLF & @CRLF & "Last Chance, DO NOT MAKE ME ANGRY, or" & @CRLF & "I will give ALL of your gold to Barbarian King," & @CRLF & "And ALL of your Gems to the Archer Queen!" & @CRLF
						ContinueLoop
					Case $iSilly > 4
						SetLog("Quit joking, Click the Clan Castle, or restart bot and try again", $COLOR_ERROR)
						$g_aiClanCastlePos[0] = -1
						$g_aiClanCastlePos[1] = -1
						ClickP($aAway, 1, 0, "#0377")
						Return False
				EndSelect
			EndIf
			If $sInfo[2] = "Broken" Then
				SetLog("You did not rebuild your Clan Castle yet.", $COLOR_ACTION)
			Else
				SetLog("Your Clan Castle is at level: " & $sInfo[2], $COLOR_SUCCESS)
			EndIf
		Else
			SetLog(" Operator Error - Bad Clan Castle Location: " & "(" & $g_aiClanCastlePos[0] & "," & $g_aiClanCastlePos[1] & ")", $COLOR_ERROR)
			$g_aiClanCastlePos[0] = -1
			$g_aiClanCastlePos[1] = -1
			ClickP($aAway, 1, 0, "#0378")
			Return False
		EndIf
		ExitLoop
	WEnd
	ClickP($aAway, 1, 200, "#0327")
EndFunc   ;==>_LocateClanCastle

Func DetectedCastle()
	Local $Quantity2Match = 0
	Local $aResult = findmultiplequick($g_sImgLocationCastle, $Quantity2Match, "ECD")
	If IsArray($aResult) And UBound($aResult) > 0 Then
		For $i = 0 To UBound($aResult) - 1
			Local $Name = $aResult[$i][0]
			Local $level = $aResult[$i][3]
			Local $position[2] = [$aResult[$i][1] + 10, $aResult[$i][2] + 10]
			SetDebugLog($Name & " Lv" & $level & " detected at (" & $position[0] & "," & $position[1] & ")", $COLOR_INFO)
			FClick($position[0], $position[1])
			If _Sleep(500) Then Return False
			Local $sInfo = BuildingInfo(242, 490 + $g_iBottomOffsetY); 860x780
			If @error Then SetError(0, 0, 0)
			Local $CountGetInfo = 0
			While IsArray($sInfo) = False
				$sInfo = BuildingInfo(242, 490 + $g_iBottomOffsetY); 860x780
				If @error Then SetError(0, 0, 0)
				If _Sleep(100) Then Return False
				$CountGetInfo += 1
				If $CountGetInfo = 50 Then Return False
			WEnd
			SetDebugLog($sInfo[1] & " " & $sInfo[2])
			If @error Then Return SetError(0, 0, 0)
			If StringInStr($sInfo[1], "Cast") > 0 Then
				SetLog("Castle Lv" & $level & " detected...", $COLOR_SUCCESS)
				$g_aiClanCastlePos[0] = $position[0]
				$g_aiClanCastlePos[1] = $position[1]
				ClickP($aAway, 1, 200, "#0327")
				If _Sleep(1000) Then Return
				IniWrite($g_sProfileBuildingPath, "other", "CCPosX", $g_aiClanCastlePos[0])
				IniWrite($g_sProfileBuildingPath, "other", "CCPosY", $g_aiClanCastlePos[1])
				SetLog($Name & " Lv" & $level & " Position Saved!", $COLOR_SUCCESS)
				Return True
			EndIf
		Next
	EndIf
	Return False
EndFunc   ;==>DetectedCastle
