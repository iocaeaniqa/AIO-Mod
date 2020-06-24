; #FUNCTION# ====================================================================================================================
; Name ..........: CheckArmyBuilderBase
; Description ...: Use on Builder Base attack
; Syntax ........: CheckArmyBuilderBase()
; Parameters ....:
; Return values .: None
; Author ........: Boludoz (redo) (2019), ProMac (03-2018), Fahid.Mahmood
; Modified ......: 
; Remarks .......: This file is part of MyBot, previously known as Multibot and ClashGameBot. Copyright 2015-2020
;                  MyBot is distributed under the terms of the GNU GPL
; Related .......:
; Link ..........: https://github.com/MyBotRun/MyBot/wiki
; Example .......: No
; ===============================================================================================================================
#include-once
Global $g_aTroopButton = 0


Func TestCheckArmyBuilderBase() ; ProMac (03-2018), Fahid.Mahmood part.
	SetDebugLog("** TestCheckArmyBuilderBase START**", $COLOR_DEBUG)
	Local $Status = $g_bRunState
	$g_bRunState = True
	CheckArmyBuilderBase(True)
	$g_bRunState = $Status
	SetDebugLog("** TestCheckArmyBuilderBase END**", $COLOR_DEBUG)
EndFunc   ;==>TestCheckArmyBuilderBase

Func CheckArmyBuilderBase($bDebug = False)

	FuncEnter(CheckArmyBuilderBase)
	If Not $g_bRunState Then Return
	If Not IsMainPageBuilderBase() Then Return

	SetDebugLog("** Click Away **", $COLOR_DEBUG)

	ClickP($aAway, 1, 0, "#0332") ;Click Away

	Setlog("Entering troops", $COLOR_PURPLE)

	; Check the Train Button
	If Not _ColorCheck(_GetPixelColor($aArmyTrainButtonBB[0], $aArmyTrainButtonBB[1], True), _
			Hex($aArmyTrainButtonBB[2], 6), $aArmyTrainButtonBB[3]) Then Return

	SetDebugLog("** Check the Train Button Detected**", $COLOR_DEBUG)

	; Click on that Button
	Click($aArmyTrainButton[0], $aArmyTrainButton[1], 1, 0, "#0347") ; Click Button Army Overview

	; Wait for Window
	If Not _WaitForCheckXML($g_sImgPathFillArmyCampsWindow, "278, 409, 411, 464", True, 10000, 100) Then
		Setlog("Can't Open The Fill Army Camps Window!", $COLOR_DEBUG)
		ClickP($aAway, 1, 0, "#0332") ;Click Away
		Return
	EndIf

	SetDebugLog("** Fill Army Camps Window Detected **", $COLOR_DEBUG)

	DetectCamps()

	Setlog("Exit from Camps!", $COLOR_PURPLE)
	ClickP($aAway, 1, 0, "#0332") ;Click Away
	FuncReturn()

EndFunc   ;==>CheckArmyBuilderBase

Func DetectCamps()
	Local $iArmyCampsInBB[6] = [0, 0, 0, 0, 0, 0]
	Local $asAttackBarBB = $g_asAttackBarBB2
	Local $bDebugLog = False
	If $g_bDebugBBattack Then $bDebugLog = True

	If _Sleep(Random(500, 1000, 1)) Then Return

	; Result [X][0] = NAME , [x][1] = Xaxis , [x][2] = Yaxis , [x][3] = Level
	Local $aResults = _ImageSearchXML($g_sImgPathCamps, 10, "40,187,820,400", True, $bDebugLog) ; Cantidad de campametos

	If $aResults = -1 Or Not IsArray($aResults) Then Return -1
	Setlog("Detected " & UBound($aResults) & " Camp(s).")

	; Limit GUI camps and Camps ($iArmyCampsBB).
	Local $aCmbCampsInBBGUILimited = _ArrayExtract($g_iCmbCampsBB, 0, UBound($aResults)-1)

	; Limit Camps of game to detected
	Local $iArmyCampsInBBLimited = _ArrayExtract($iArmyCampsInBB, 0, UBound($aResults)-1)

	; Fill $iArmyCampsBB (only one capture like FreeMagicItems system)
	Local $aTroops = _ImageSearchXML($g_sImgPathTroopsTrain, 100, "40, 242, 820, 330", True, $bDebugLog) ; Troops in camps
	;_ArrayDisplay($aTroops)

	; Train matrix
	Local $aTrainLikeBoss[$eBBTroopCount] = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]
	Local $aTrainedLikeBoss[$eBBTroopCount] = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]

	; Translate $aCmbCampsInBBGUILimited to $aTrainLikeBoss.
    For $i = 0 To UBound($aCmbCampsInBBGUILimited) -1
        Local $i2 = $aCmbCampsInBBGUILimited[$i]
        $aTrainLikeBoss[$i2] += 1
	Next
	
	; Is in camp.
	For $i = 0 To UBound($aResults) - 1
		Local $iX = $aResults[$i][1]
		Local $iY = $aResults[$i][2]
		If _ColorCheck(_GetPixelColor($iX + 60, $iY - 75, True), Hex(0xCDCDC6, 6), 15) Then ContinueLoop
		For $i2 = 0 To UBound($aTroops) - 1
			If ((Int($iX - 20) < $aTroops[$i2][1]) And (Int($iX + 100) > $aTroops[$i2][1])) Then
				For	$iN = 0 To UBound($asAttackBarBB) -1
					If (StringInStr($asAttackBarBB[$iN], $aTroops[$i2][0]) > 0) Then 
						If ($aTrainLikeBoss[$iN] = Int($aTrainedLikeBoss[$iN])) Then 
							$aTrainLikeBoss[$iN] -= 1
							$aTrainedLikeBoss[$iN] -= 1
							ElseIf ($aTrainLikeBoss[$iN] < Int($aTrainedLikeBoss[$iN])) Then 
        $aTrainLikeBoss[$i2] -= 1
							DeleteTroop($iX, $iY)
							ElseIf ($aTrainLikeBoss[$iN] > Int($aTrainedLikeBoss[$iN])) Then 
							$aTrainedLikeBoss[$iN] += 1
        $aTrainLikeBoss[$i2] -= 1
						EndIf
						ContinueLoop 3
					EndIf
				Next
			EndIf
		Next
	Next
	_ArrayDisplay($aTrainedLikeBoss)
	_ArrayDisplay($aTrainLikeBoss)
	;Troops Train
	Local $iFillFix = 0 ; Barb Default
	Local $bIsLlog = False
	For $i = 0 To UBound($aTrainedLikeBoss) -1
		If ($aTrainedLikeBoss[$i] > 0) Then
			If (LocateTroopButton($i) <> 0) Then
				If $bIsLlog = False Then
					SetLog("Builder base army - Train :", $COLOR_SUCCESS)
					$bIsLlog = True
				EndIf
				SetLog("- x" & $aTrainedLikeBoss[$i] & " " & $g_avStarLabTroops[$i+1][3], $COLOR_SUCCESS)
				MyTrainClick($g_aTroopButton, $aTrainedLikeBoss[$i])
				$iFillFix = $g_aTroopButton
				Else
				SetLog("Builder base army: LocateTroopButton troop not unlocked or fail.", $COLOR_ERROR)
				MyTrainClick($iFillFix, $aTrainedLikeBoss[$i]) ; Train 4 fill last "ok" (more smart)
			EndIf
		EndIf
		If _Sleep(Random((200*90)/100, (300*110)/100, 1), False) Then Return
	Next

EndFunc   ;==>DetectCamps

Func DeleteTroop($X, $Y, $bOnlyCheck = False)
	SetDebugLog("Red Coordinates: " & $X & "," & $Y)
	Local $saiArea2SearchOri[4] = [$X, 244, $X + 95, 271]
	Local $aAllResults = findMultipleQuick(@scriptdir & "\COCBot\Team__AiO__MOD++\Images\BuilderBase\FillArmyCamps\Bundles\", 0, $saiArea2SearchOri, True, "Del", False, 25)
	If IsArray($aAllResults) Then
		_ArraySort($aAllResults, 0, 0, 0, 1)
		If $bOnlyCheck = False Then Click($aAllResults[0][1] + Random(0, 10, 1), Random(244, 271, 1), 1)
		Return True
	EndIf
	If $bOnlyCheck = False Then Setlog("Builder base army: Fail DeleteTroop.", $COLOR_ERROR)
	Return False
EndFunc   ;==>DeleteTroop

; Samkie inspired code
Func LocateTroopButton($iTroopButton, $sImgTrain = $g_sImgPathTroopsTrain, $sRegionForScan = "37, 479, 891, 579")
		Global $g_aTroopButton[2] = [0, 0]
		Local $asAttackBarBB = $g_asAttackBarBB2
		Local $bDebugLog = False, $iButtonIsIn

		If ($iTroopButton > UBound($asAttackBarBB) -1) Then SetLog("Train army on BB: Troop not rocognized, it return first.", $COLOR_ERROR)

		For $i = 0 To 5
			Local $aTroopPosition = _ImageSearchXML($g_sImgPathTroopsTrain, 0, $sRegionForScan, True, False, True, 25)
			If $aTroopPosition = 0 Or UBound($aTroopPosition) < 1 Then Return 0

			$iButtonIsIn = _ArraySearch($aTroopPosition, $asAttackBarBB[$iTroopButton], 0, 0, 0, 1)
			SetDebugLog("LocateTroopButton: " & "_ArraySearch($aTroopPosition, $asAttackBarBB[$iTroopButton]) " & $iButtonIsIn)
			
			If ($iButtonIsIn > -1) Then
				$g_aTroopButton[0] = $aTroopPosition[$iButtonIsIn][1]
				$g_aTroopButton[1] = $aTroopPosition[$iButtonIsIn][2]
				Return $g_aTroopButton
			ElseIf _ArraySearch($asAttackBarBB , $aTroopPosition[0][0], 0, 0, 0, 1) < $iTroopButton Then
				SetDebugLog("LocateTroopButton: " & "ClickDrag(575, 522, 280, 522, 50)")
				ClickDrag(575, 522, 280, 522, 50)
				If _Sleep(Random((400*90)/100, (400*110)/100, 1)) Then Return
			ElseIf _ArraySearch($asAttackBarBB, $aTroopPosition[UBound($aTroopPosition)-1][0], 0, 0, 0, 1) > $iTroopButton Then
				SetDebugLog("LocateTroopButton: " & "ClickDrag(280, 522, 575, 522, 50)")
				ClickDrag(280, 522, 575, 522, 50)
				If _Sleep(Random((400*90)/100, (400*110)/100, 1)) Then Return
			EndIf
			SetDebugLog("LocateTroopButton: " & "LOOP : " & $i)

			If _Sleep(500) Then Return
		Next

		SetLog("Cannot find " & $asAttackBarBB[$iTroopButton] & " for scan", $COLOR_ERROR)

		Global $g_aTroopButton = 0
		Return 0

EndFunc

Func MyTrainClick($aXY, $iTimes = 1, $iSpeed = 0, $sdebugtxt="")
			If not IsArray($aXY) Then Return False
			Local $x = $aXY[0], $y = $aXY[1]
			Local $iHLFClickMin = 7, $iHLFClickMax = 14
			Local $isldHLFClickDelayTime = 2000
			Local $iRandNum = Random($iHLFClickMin-1,$iHLFClickMax-1,1) ;Initialize value (delay awhile after $iRandNum times click)
			Local $iRandX = Random($x - 5,$x + 5,1),$iRandY = Random($y - 5,$y + 5,1)
			If isProblemAffect(True) Then Return
			For $i = 0 To $iTimes - 1
				PureClick(Random($iRandX-2,$iRandX+2,1), Random($iRandY-2,$iRandY+2,1))
				If ($i >= $iRandNum) Then
					$iRandNum = $iRandNum + Random($iHLFClickMin,$iHLFClickMax,1)
					$iRandX = Random($x - 5, $x + 5,1)
					$iRandY = Random($y - 5, $y + 5,1)
					If _Sleep(Random(($isldHLFClickDelayTime*138)/100, (($isldHLFClickDelayTime*138)*2)/100, 1), False) Then Return
				Else
					If _Sleep(Random(($isldHLFClickDelayTime*138)/100, (($isldHLFClickDelayTime*138)*3)/100, 1), False) Then Return
				EndIf
			Next
EndFunc   ;==>MyTrainClick
