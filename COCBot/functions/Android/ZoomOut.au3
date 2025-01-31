; #FUNCTION# ====================================================================================================================
; Name ..........: ZoomOut
; Description ...: Tries to zoom out of the screen until the borders, located at the top of the game (usually black), is located.
; Syntax ........: ZoomOut()
; Parameters ....:
; Return values .: None
; Author ........:
; Modified ......: KnowJack (07-2015), CodeSlinger69 (01-2017)
; Remarks .......: This file is part of MyBot, previously known as ClashGameBot. Copyright 2015-2019
;                  MyBot is distributed under the terms of the GNU GPL
; Related .......:
; Link ..........: https://github.com/MyBotRun/MyBot/wiki
; Example .......: No
; ===============================================================================================================================
#include-once

Global $g_aiSearchZoomOutCounter[2] = [0, 1] ; 0: Counter of SearchZoomOut calls, 1: # of post zoomouts after image found

Func ZoomOut() ;Zooms out
	ClickAway()
	
	Static $s_bZoomOutActive = False
	If $s_bZoomOutActive Then Return ; recursive not allowed here
	$s_bZoomOutActive = True

	Local $bResult = _ZoomOut()
	$s_bZoomOutActive = False
	Return $bResult
EndFunc   ;==>ZoomOut

Func _ZoomOut() ;Zooms out
	$g_aiSearchZoomOutCounter[0] = 0
	$g_aiSearchZoomOutCounter[1] = 1
	ResumeAndroid()
	WinGetAndroidHandle()
	getBSPos() ; Update $g_hAndroidWindow and Android Window Positions
	If Not $g_bRunState Then
		SetDebugLog("Exit ZoomOut, bot not running")
		Return
	EndIf
	Local $bResult
	If ($g_iAndroidZoomoutMode = 0 Or $g_iAndroidZoomoutMode = 3) And ($g_bAndroidEmbedded = False Or $g_iAndroidEmbedMode = 1) Then
		; default zoomout
		$bResult = Execute("ZoomOut" & $g_sAndroidEmulator & "()")
		If $bResult = "" And @error <> 0 Then
			; Not implemented or other error
			$bResult = AndroidOnlyZoomOut()
		EndIf
		$g_bSkipFirstZoomout = True
		Return $bResult
	EndIf

	; Android embedded, only use Android zoomout
	$bResult = AndroidOnlyZoomOut()
	$g_bSkipFirstZoomout = True
	Return $bResult
EndFunc   ;==>_ZoomOut

Func ZoomOutBlueStacks() ;Zooms out
	SetDebugLog("ZoomOutBlueStacks()")
	; ctrl click is best and most stable for BlueStacks
	Return ZoomOutCtrlClick(False, False, False, 250)
EndFunc   ;==>ZoomOutBlueStacks

Func ZoomOutBlueStacks2()
	SetDebugLog("ZoomOutBlueStacks2()")
	If $__BlueStacks2Version_2_5_or_later = False Then
		; ctrl click is best and most stable for BlueStacks, but not working after 2.5.55.6279 version
		Return ZoomOutCtrlClick(False, False, False, 250)
	Else
		; newer BlueStacks versions don't work with Ctrl-Click, so fall back to original arrow key
		Return DefaultZoomOut("{DOWN}", 0, ($g_iAndroidZoomoutMode <> 3))
	EndIf
EndFunc   ;==>ZoomOutBlueStacks2

Func ZoomOutMEmu()
	SetDebugLog("ZoomOutMEmu()")
	Return DefaultZoomOut("{F3}", 0, ($g_iAndroidZoomoutMode <> 3))
EndFunc   ;==>ZoomOutMEmu

Func ZoomOutNox()
	SetDebugLog("ZoomOutNox()")
	Return ZoomOutCtrlWheelScroll(True, True, True, ($g_iAndroidZoomoutMode <> 3), Default, -5, 250)
EndFunc   ;==>ZoomOutNox

Func DefaultZoomOut($iZoomOutKey = "{DOWN}", $aTryCtrlWheelScrollAfterCycles = 40, $bAndroidZoomOut = True) ;Zooms out
	SetDebugLog("DefaultZoomOut()")
	Local $sFunc = "DefaultZoomOut"
	Local $bResult0, $bResult1, $i = 0
	Local $iExitCount = 80
	Local $iDelayCount = 20
	ForceCaptureRegion()
	Local $aPicture = SearchZoomOut($aCenterHomeVillageClickDrag, True, "", True)

	If StringInStr($aPicture[0], "zoomou") = 0 Then
		If $g_bDebugSetlog Then
			SetDebugLog("Zooming Out (" & $sFunc & ")", $COLOR_INFO)
		Else
			SetLog("Zooming Out", $COLOR_INFO)
		EndIf
		If _Sleep($iDelayZOOMOUT1) Then Return True
		If $bAndroidZoomOut Then
			AndroidZoomOut(0, Default, ($g_iAndroidZoomoutMode <> 2)) ; use new ADB zoom-out
			ForceCaptureRegion()
			$aPicture = SearchZoomOut($aCenterHomeVillageClickDrag, True, "", True)
		EndIf

		Local $aTryCtrlWheelScroll = False

		If IsArray($aPicture) Then
			While StringInStr($aPicture[0], "zoomout") = 0 And Not $aTryCtrlWheelScroll

				AndroidShield("DefaultZoomOut") ; Update shield status
				If $bAndroidZoomOut Then
					AndroidZoomOut($i, Default, ($g_iAndroidZoomoutMode <> 2)) ; use new ADB zoom-out
					If @error <> 0 Then $bAndroidZoomOut = False
				EndIf
				If Not $bAndroidZoomOut Then
					; original windows based zoom-out
					If $g_bDebugSetlog Then SetDebugLog("Index = " & $i, $COLOR_DEBUG) ; Index=2X loop count if success, will be increment by 1 if controlsend fail
					If _Sleep($iDelayZOOMOUT2) Then Return True
					If $g_bChkBackgroundMode = False And $g_bNoFocusTampering = False Then
						$bResult0 = ControlFocus($g_hAndroidWindow, "", "")
					Else
						$bResult0 = 1
					EndIf
					$bResult1 = ControlSend($g_hAndroidWindow, "", "", $iZoomOutKey)
					If $g_bDebugSetlog Then SetDebugLog("ControlFocus Result = " & $bResult0 & ", ControlSend Result = " & $bResult1 & "|" & "@error= " & @error, $COLOR_DEBUG)
					If $bResult1 = 1 Then
						$i += 1
					Else
						SetLog("Warning ControlSend $bResult = " & $bResult1, $COLOR_DEBUG)
					EndIf
				EndIf

				If $i > $iDelayCount Then
					If _Sleep($iDelayZOOMOUT3) Then Return True
				EndIf
				If $aTryCtrlWheelScrollAfterCycles > 0 And $i > $aTryCtrlWheelScrollAfterCycles Then $aTryCtrlWheelScroll = True
				If $i > $iExitCount Then Return
				If $g_bRunState = False Then ExitLoop
				If IsProblemAffect(True) Then  ; added to catch errors during Zoomout
					SetLog($g_sAndroidEmulator & " Error window detected", $COLOR_ERROR)
					If checkObstacles() = True Then SetLog("Error window cleared, continue Zoom out", $COLOR_INFO)  ; call to clear normal errors
				EndIf
				$i += 1  ; add one to index value to prevent endless loop if controlsend fails
				ForceCaptureRegion()
				$aPicture = SearchZoomOut($aCenterHomeVillageClickDrag, True, "", True)
			WEnd
		EndIf

		If $aTryCtrlWheelScroll Then
			SetLog($g_sAndroidEmulator & " zoom-out with key " & $iZoomOutKey & " didn't work, try now Ctrl+MouseWheel...", $COLOR_INFO)
			Return ZoomOutCtrlWheelScroll(False, False, False, False)
		EndIf
		Return True
	EndIf
	Return False
EndFunc   ;==>DefaultZoomOut

Func ZoomOutCtrlWheelScroll($CenterMouseWhileZooming = True, $GlobalMouseWheel = True, $AlwaysControlFocus = False, $AndroidZoomOut = True, $hWin = Default, $ScrollSteps = -5, $ClickDelay = 250)
	SetDebugLog("ZoomOutCtrlWheelScroll()")
	Local $sFunc = "ZoomOutCtrlWheelScroll"

	Local $iExitCount = 80
	Local $iDelayCount = 20
	Local $bResult[4], $i = 0, $j
	Local $iZoomActions[4] = ["ControlFocus", "Ctrl Down", "Mouse Wheel Scroll Down", "Ctrl Up"]
	If $hWin = Default Then $hWin = ($g_bAndroidEmbedded = False ? $g_hAndroidWindow : $g_aiAndroidEmbeddedCtrlTarget[1])
	ForceCaptureRegion()
	Local $aPicture = SearchZoomOut($aCenterHomeVillageClickDrag, True, "", True)

	If StringInStr($aPicture[0], "zoomou") = 0 Then

		If $g_bDebugSetlog Then
			SetDebugLog("Zooming Out (" & $sFunc & ")", $COLOR_INFO)
		Else
			SetLog("Zooming Out ", $COLOR_INFO)
		EndIf

		AndroidShield("ZoomOutCtrlWheelScroll") ; Update shield status
		If _Sleep($iDelayZOOMOUT1) Then Return True
		If $AndroidZoomOut Then
			AndroidZoomOut(0, Default, ($g_iAndroidZoomoutMode <> 2)) ; use new ADB zoom-out
			ForceCaptureRegion()
			$aPicture = SearchZoomOut($aCenterHomeVillageClickDrag, True, "", True)
		EndIf
		Local $aMousePos = MouseGetPos()
		
		If UBound($aPicture) > 0 Then
			While StringInStr($aPicture[0], "zoomou") = 0
				
				If $AndroidZoomOut Then
					AndroidZoomOut($i, Default, ($g_iAndroidZoomoutMode <> 2)) ; use new ADB zoom-out
					If @error <> 0 Then $AndroidZoomOut = False
				EndIf
				If Not $AndroidZoomOut Then
					; original windows based zoom-out
					If $g_bDebugSetlog Then SetDebugLog("Index = " & $i, $COLOR_DEBUG) ; Index=2X loop count if success, will be increment by 1 if controlsend fail
					If _Sleep($iDelayZOOMOUT2) Then ExitLoop
					If ($g_bChkBackgroundMode = False And $g_bNoFocusTampering = False) Or $AlwaysControlFocus Then
						$bResult[0] = ControlFocus($hWin, "", "")
					Else
						$bResult[0] = 1
					EndIf
					
					$bResult[1] = ControlSend($hWin, "", "", "{CTRLDOWN}")
					If $CenterMouseWhileZooming Then MouseMove($g_aiBSpos[0] + Int($g_iDEFAULT_WIDTH / 2), $g_aiBSpos[1] + Int($g_iDEFAULT_HEIGHT / 2), 0)
					If $GlobalMouseWheel Then
						$bResult[2] = MouseWheel(($ScrollSteps < 0 ? "down" : "up"), Abs($ScrollSteps)) ; can't find $MOUSE_WHEEL_DOWN constant, couldn't include AutoItConstants.au3 either
					Else
						Local $WM_WHEELMOUSE = 0x020A, $MK_CONTROL = 0x0008
						Local $wParam = BitOR($ScrollSteps * 0x10000, BitAND($MK_CONTROL, 0xFFFF)) ; HiWord = -120 WheelScrollDown, LoWord = $MK_CONTROL
						Local $lParam = BitOR(($g_aiBSpos[1] + Int($g_iDEFAULT_HEIGHT / 2)) * 0x10000, BitAND(($g_aiBSpos[0] + Int($g_iDEFAULT_WIDTH / 2)), 0xFFFF)) ; ; HiWord = y-coordinate, LoWord = x-coordinate
						_WinAPI_PostMessage($hWin, $WM_WHEELMOUSE, $wParam, $lParam)
						$bResult[2] = (@error = 0 ? 1 : 0)
					EndIf
					If _Sleep($ClickDelay) Then ExitLoop
					$bResult[3] = ControlSend($hWin, "", "", "{CTRLUP}{SPACE}")
					
					If $g_bDebugSetlog Then SetDebugLog("ControlFocus Result = " & $bResult[0] & _
							", " & $iZoomActions[1] & " = " & $bResult[1] & _
							", " & $iZoomActions[2] & " = " & $bResult[2] & _
							", " & $iZoomActions[3] & " = " & $bResult[3] & _
							" | " & "@error= " & @error, $COLOR_DEBUG)
					For $j = 1 To 3
						If $bResult[$j] = 1 Then
							$i += 1
							ExitLoop
						EndIf
					Next
					For $j = 1 To 3
						If $bResult[$j] = 0 Then
							SetLog("Warning " & $iZoomActions[$j] & " = " & $bResult[1], $COLOR_DEBUG)
						EndIf
					Next
				EndIf
				
				If $i > $iDelayCount Then
					If _Sleep($iDelayZOOMOUT3) Then ExitLoop
				EndIf
				If $i > $iExitCount Then ExitLoop
				If $g_bRunState = False Then ExitLoop
				If IsProblemAffect(True) Then  ; added to catch errors during Zoomout
					SetLog($g_sAndroidEmulator & " Error window detected", $COLOR_ERROR)
					If checkObstacles() = True Then SetLog("Error window cleared, continue Zoom out", $COLOR_INFO)  ; call to clear normal errors
				EndIf
				$i += 1  ; add one to index value to prevent endless loop if controlsend fails
				ForceCaptureRegion()
				$aPicture = SearchZoomOut($aCenterHomeVillageClickDrag, True, "", True)
			WEnd
		EndIf
		
		If $CenterMouseWhileZooming And $AndroidZoomOut = False Then MouseMove($aMousePos[0], $aMousePos[1], 0)
		Return True

	EndIf
	Return False
EndFunc   ;==>ZoomOutCtrlWheelScroll

Func ZoomOutCtrlClick($CenterMouseWhileZooming = False, $AlwaysControlFocus = False, $AndroidZoomOut = True, $ClickDelay = 250)
	SetDebugLog("ZoomOutCtrlClick()")
	Local $sFunc = "ZoomOutCtrlClick"

	Local $iExitCount = 80
	Local $iDelayCount = 20
	Local $bResult[4], $i, $j
	Local $SendCtrlUp = False
	Local $iZoomActions[4] = ["ControlFocus", "Ctrl Down", "Click", "Ctrl Up"]
	ForceCaptureRegion()
	Local $aPicture = SearchZoomOut($aCenterHomeVillageClickDrag, True, "", True)

	If StringInStr($aPicture[0], "zoomou") = 0 Then

		If $g_bDebugSetlog Then
			SetDebugLog("Zooming Out (" & $sFunc & ")", $COLOR_INFO)
		Else
			SetLog("Zooming Out", $COLOR_INFO)
		EndIf

		AndroidShield("ZoomOutCtrlClick") ; Update shield status

		If _Sleep($iDelayZOOMOUT1) Then Return True
		Local $aMousePos = MouseGetPos()

		$i = 0
		If UBound($aPicture) > 0 Then
			While StringInStr($aPicture[0], "zoomou") = 0
				
				If $AndroidZoomOut Then
					AndroidZoomOut($i, Default, ($g_iAndroidZoomoutMode <> 2)) ; use new ADB zoom-out
					If @error <> 0 Then $AndroidZoomOut = False
				EndIf
				If Not $AndroidZoomOut Then
					; original windows based zoom-out
					If $g_bDebugSetlog Then SetDebugLog("Index = " & $i, $COLOR_DEBUG) ; Index=2X loop count if success, will be increment by 1 if controlsend fail
					If _Sleep($iDelayZOOMOUT2) Then ExitLoop
					If ($g_bChkBackgroundMode = False And $g_bNoFocusTampering = False) Or $AlwaysControlFocus Then
						$bResult[0] = ControlFocus($g_hAndroidWindow, "", "")
					Else
						$bResult[0] = 1
					EndIf
					
					$bResult[1] = ControlSend($g_hAndroidWindow, "", "", "{CTRLDOWN}")
					$SendCtrlUp = True
					If $CenterMouseWhileZooming Then MouseMove($g_aiBSpos[0] + Int($g_iDEFAULT_WIDTH / 2), $g_aiBSpos[1] + Int($g_iDEFAULT_HEIGHT / 2), 0)
					$bResult[2] = _ControlClick(Int($g_iDEFAULT_WIDTH / 2), 600)
					If _Sleep($ClickDelay) Then ExitLoop
					$bResult[3] = ControlSend($g_hAndroidWindow, "", "", "{CTRLUP}{SPACE}")
					$SendCtrlUp = False
					
					If $g_bDebugSetlog Then SetDebugLog("ControlFocus Result = " & $bResult[0] & _
							", " & $iZoomActions[1] & " = " & $bResult[1] & _
							", " & $iZoomActions[2] & " = " & $bResult[2] & _
							", " & $iZoomActions[3] & " = " & $bResult[3] & _
							" | " & "@error= " & @error, $COLOR_DEBUG)
					For $j = 1 To 3
						If $bResult[$j] = 1 Then
							ExitLoop
						EndIf
					Next
					For $j = 1 To 3
						If $bResult[$j] = 0 Then
							SetLog("Warning " & $iZoomActions[$j] & " = " & $bResult[1], $COLOR_DEBUG)
						EndIf
					Next
				EndIf
				
				If $i > $iDelayCount Then
					If _Sleep($iDelayZOOMOUT3) Then ExitLoop
				EndIf
				If $i > $iExitCount Then ExitLoop
				If $g_bRunState = False Then ExitLoop
				If IsProblemAffect(True) Then  ; added to catch errors during Zoomout
					SetLog($g_sAndroidEmulator & " Error window detected", $COLOR_RED)
					If checkObstacles() = True Then SetLog("Error window cleared, continue Zoom out", $COLOR_BLUE)  ; call to clear normal errors
				EndIf
				$i += 1  ; add one to index value to prevent endless loop if controlsend fails
				ForceCaptureRegion()
				$aPicture = SearchZoomOut($aCenterHomeVillageClickDrag, True, "", True)
			WEnd
		EndIf
		
		If $SendCtrlUp Then ControlSend($g_hAndroidWindow, "", "", "{CTRLUP}{SPACE}")

		If $CenterMouseWhileZooming Then MouseMove($aMousePos[0], $aMousePos[1], 0)

		Return True
	EndIf
	Return False
EndFunc   ;==>ZoomOutCtrlClick

Func AndroidOnlyZoomOut() ;Zooms out
	SetDebugLog("AnroidOnlyZoomOut()")
	Local $sFunc = "AndroidOnlyZoomOut"
	Local $i = 0
	Local $iExitCount = 80
	ForceCaptureRegion()
	Local $aPicture = SearchZoomOut($aCenterHomeVillageClickDrag, True, "", True)

	If StringInStr($aPicture[0], "zoomout") = 0 Then

		If $g_bDebugSetlog Then
			SetDebugLog("Zooming Out (" & $sFunc & ")", $COLOR_INFO)
		Else
			SetLog("Zooming Out", $COLOR_INFO)
		EndIf
		AndroidZoomOut(0, Default, ($g_iAndroidZoomoutMode <> 2)) ; use new ADB zoom-out
		ForceCaptureRegion()
		$aPicture = SearchZoomOut($aCenterHomeVillageClickDrag, True, "", True)
		If IsArray($aPicture) Then
			While StringInStr($aPicture[0], "zoomout") = 0
				AndroidShield("AndroidOnlyZoomOut") ; Update shield status
				AndroidZoomOut($i, Default, ($g_iAndroidZoomoutMode <> 2)) ; use new ADB zoom-out
				If $i > $iExitCount Then Return
				If Not $g_bRunState Then ExitLoop
				If IsProblemAffect(True) Then  ; added to catch errors during Zoomout
					SetLog($g_sAndroidEmulator & " Error window detected", $COLOR_ERROR)
					If checkObstacles() Then SetLog("Error window cleared, continue Zoom out", $COLOR_INFO)  ; call to clear normal errors
				EndIf
				$i += 1  ; add one to index value to prevent endless loop if controlsend fails
				ForceCaptureRegion()
				$aPicture = SearchZoomOut($aCenterHomeVillageClickDrag, True, "", True)
			WEnd
		EndIf
		Return True
	EndIf
	Return False
EndFunc   ;==>AndroidOnlyZoomOut

; SearchZoomOut returns always an Array.
; If village can be measured and villages size < 500 pixel then it returns in idx 0 a String starting with "zoomout:" and tries to center base
; Return Array:
; 0 = Empty string if village cannot be measured (e.g. window blocks village or not zoomed out)
; 1 = Current Village X Offset (after centering village)
; 2 = Current Village Y Offset (after centering village)
; 3 = Difference of previous Village X Offset and current (after centering village)
; 4 = Difference of previous Village Y Offset and current (after centering village)
Func SearchZoomOut($CenterVillageBoolOrScrollPos = $aCenterHomeVillageClickDrag, $UpdateMyVillage = True, $sSource = "", $bCaptureRegion = True, $bDebugLog = $g_bDebugSetlog)
	FuncEnter(SearchZoomOut)
	If Not $g_bRunState Then Return
	If $sSource <> "" Then $sSource = " (" & $sSource & ")"
	Local $bCenterVillage = $CenterVillageBoolOrScrollPos
	If $bCenterVillage = Default Or $g_bDebugDisableVillageCentering Then $bCenterVillage = (Not $g_bDebugDisableVillageCentering)
	Local $aScrollPos[2] = [0, 0]
	If UBound($CenterVillageBoolOrScrollPos) >= 2 Then
		$aScrollPos[0] = $CenterVillageBoolOrScrollPos[0]
		$aScrollPos[1] = $CenterVillageBoolOrScrollPos[1]
		$bCenterVillage = (Not $g_bDebugDisableVillageCentering)
	EndIf

	; Setup arrays, including default return values for $return
	Local $iX, $iY, $iZ, $stone[2]
	Local $aVillageSize = 0

	If $bCaptureRegion Then _CaptureRegion2()

	Local $aResult = ["", 0, 0, 0, 0] ; expected dummy value
	Local $bUpdateSharedPrefs = $g_bUpdateSharedPrefs And $g_iAndroidZoomoutMode = 4

	Local $vVillage
	Local $bOnBuilderBase = isOnBuilderBase(False) ; Capture region spam disabled - Team AIO Mod++
	If $g_aiSearchZoomOutCounter[0] = 10 Then SetLog("Try secondary village measuring...", $COLOR_INFO)
	If $g_aiSearchZoomOutCounter[0] < 10 Then
		$vVillage = GetVillageSize($bDebugLog, "stone", "tree", Default, $bOnBuilderBase, False) ; Capture region spam disabled - Team AIO Mod++
	Else
		ClickAway()
		; try secondary images
		$vVillage = GetVillageSize($bDebugLog, "2stone", "2tree", Default, $bOnBuilderBase, False) ; Capture region spam disabled - Team AIO Mod++
	EndIf

	Static $iCallCount = 0
	If $g_aiSearchZoomOutCounter[0] > 0 Then
		If _Sleep(1000) Then
			$iCallCount = 0
			Return FuncReturn($aResult)
		EndIf
	EndIf

	If IsArray($vVillage) = 1 Then
		$aVillageSize = $vVillage[0]
		If $aVillageSize < 500 Or $g_bDebugDisableZoomout Then
			$iZ = $vVillage[1]
			$iX = $vVillage[2]
			$iY = $vVillage[3]
			$stone[0] = $vVillage[4]
			$stone[1] = $vVillage[5]
			$aResult[0] = "zoomout:" & $vVillage[6]
			$aResult[1] = $iX
			$aResult[2] = $iY
			$g_bAndroidZoomoutModeFallback = False

			If $bCenterVillage And ($bOnBuilderBase Or Not $bUpdateSharedPrefs) And ($iX <> 0 Or $iY <> 0) And ($UpdateMyVillage = False Or $iX <> $g_iVILLAGE_OFFSET[0] Or $iY <> $g_iVILLAGE_OFFSET[1]) Then
				If $bDebugLog Then SetDebugLog("Center Village" & $sSource & " by: " & $iX & ", " & $iY)
				If $aScrollPos[0] = 0 And $aScrollPos[1] = 0 Then
					; use fixed position now to prevent boat activation
					$aScrollPos[0] = $aCenterHomeVillageClickDrag[0]
					$aScrollPos[1] = $aCenterHomeVillageClickDrag[1]
				EndIf
				ClickAway()
				ClickDrag($aScrollPos[0], $aScrollPos[1], $aScrollPos[0] - $iX, $aScrollPos[1] - $iY, True) ; Custom - Team AIO Mod++
				If _Sleep(250) Then
					$iCallCount = 0
					Return FuncReturn($aResult)
				EndIf
				ClickAway()
				Local $aResult2 = SearchZoomOut(False, $UpdateMyVillage, "SearchZoomOut(1):" & $sSource, True, $bDebugLog)
				; update difference in offset
				$aResult2[3] = $aResult2[1] - $aResult[1]
				$aResult2[4] = $aResult2[2] - $aResult[2]
				If $bDebugLog Then SetDebugLog("Centered Village Offset" & $sSource & ": " & $aResult2[1] & ", " & $aResult2[2] & ", change: " & $aResult2[3] & ", " & $aResult2[4])
				$iCallCount = 0
				Return FuncReturn($aResult2)
			EndIf

			If $UpdateMyVillage Then
				If $iX <> $g_iVILLAGE_OFFSET[0] Or $iY <> $g_iVILLAGE_OFFSET[1] Or $iZ <> $g_iVILLAGE_OFFSET[2] Then
					If $bDebugLog Then SetDebugLog("Village Offset" & $sSource & " updated to " & $iX & ", " & $iY & ", " & $iZ)
				EndIf
				setVillageOffset($iX, $iY, $iZ)
				ConvertInternalExternArea() ; generate correct internal/external diamond measures
			EndIf
		EndIf
	EndIf

	If $bCenterVillage And Not $g_bZoomoutFailureNotRestartingAnything And Not $g_bAndroidZoomoutModeFallback Then
		If $aResult[0] = "" Or ($bUpdateSharedPrefs And $aVillageSize > 300 And $aVillageSize < 400) Then
			If $g_aiSearchZoomOutCounter[0] > 20 Or ($bUpdateSharedPrefs And $g_aiSearchZoomOutCounter[0] > 3) Then
				$g_aiSearchZoomOutCounter[0] = 0
				$iCallCount += 1
				If $iCallCount <= 1 Then
					;CloseCoC(True)
					SetLog("Restart CoC to reset zoom" & $sSource & "...", $COLOR_INFO)
					PoliteCloseCoC("Zoomout" & $sSource)
					If _Sleep(1000) Then
						$iCallCount = 0
						Return FuncReturn($aResult)
					EndIf
					CloseCoC() ; ensure CoC is gone
					OpenCoC()
					Return FuncReturn(SearchZoomOut($CenterVillageBoolOrScrollPos, $UpdateMyVillage, "SearchZoomOut(2):" & $sSource, True, $bDebugLog))
				Else
					SetLog("Restart Android to reset zoom" & $sSource & "...", $COLOR_INFO)
					$iCallCount = 0
					RebootAndroid()
					If _Sleep(1000) Then
						$iCallCount = 0
						Return FuncReturn($aResult)
					EndIf
					$aResult = SearchZoomOut($CenterVillageBoolOrScrollPos, $UpdateMyVillage, "SearchZoomOut(2):" & $sSource, True, $bDebugLog)
					If $bUpdateSharedPrefs And StringInStr($aResult[0], "zoomou") = 0 Then
						; disable this CoC/Android restart
						SetLog("Disable restarting CoC or Android on zoom-out failure", $COLOR_ERROR)
						SetLog("Please clean village to allow village measuring and start bot again", $COLOR_ERROR)
						$g_bZoomoutFailureNotRestartingAnything = True
					EndIf
					Return FuncReturn($aResult)
				EndIf
			Else
				; failed to find village
				$g_aiSearchZoomOutCounter[0] += 1
				If $bUpdateSharedPrefs Then
					If _Sleep(3000) Then
						$iCallCount = 0
						Return FuncReturn($aResult)
					EndIf
					Return FuncReturn(SearchZoomOut($CenterVillageBoolOrScrollPos, $UpdateMyVillage, "SearchZoomOut(3):" & $sSource, True, $bDebugLog))
				EndIf
			EndIf
		Else
			#Region - Custom BB - Fixes the problem that although the base is ok, it cannot find the ship. - Team AIO Mod++
			If Not $bOnBuilderBase Then
				If Not $g_bDebugDisableZoomout And $aVillageSize > 480 And Not $bUpdateSharedPrefs Then
					If Not $g_bSkipFirstZoomout Then
						; force additional zoom-out
						$aResult[0] = ""
					ElseIf $g_aiSearchZoomOutCounter[1] > 0 And $g_aiSearchZoomOutCounter[0] > 0 Then
						; force additional zoom-out
						$g_aiSearchZoomOutCounter[1] -= 1
						$aResult[0] = ""
					EndIf
				EndIf
			; ElseIf Not (UBound(decodeSingleCoord(findImageInPlace("BoatBuilderBase", $g_sImgBoatBB, "487,44,708,242", True))) > 1) And Not $bUpdateSharedPrefs Then
			ElseIf Not (UBound(decodeSingleCoord(findImageInPlace("BoatBuilderBase", $g_sImgBoatBB, "487,44,708,242", True))) > 1) Then
				; force additional zoom-out
				$aResult[0] = ""
			EndIf
			#EndRegion - Custom BB - Fixes the problem that although the base is ok, it cannot find the ship. - Team AIO Mod++
		EndIf
		$g_bSkipFirstZoomout = True
	EndIf

	Return FuncReturn($aResult)
EndFunc   ;==>SearchZoomOut
