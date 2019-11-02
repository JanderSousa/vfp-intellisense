Define Class Editor As Custom
	
	IncrementRight = 0
	MaxLine = 130 * 1000 && Maximum rows to be used from editor
	Boundaries = "\,;:)(.[]'=<>+-*/!^%|&#{}?@$" + ["] + Chr(13) + Chr(10) + Chr(32) + Chr(9)
	InvalidCharacters = Chr(1)+Chr(2)+Chr(3)+Chr(4)+Chr(5)+Chr(6)+Chr(7)+Chr(8)	

	Procedure Init
		If !"FOXTOOLS.FLL" $ Upper(Set("Library"))
			Set Library To (Home()+"FoxTools.Fll") Additive
		EndIf	
	EndProc 
	
	Procedure GetWindowEnvironment(nWinHandle)
		
		Local nOK, cErr
		
		Dimension ArrEnv[25]

		cErr = On("Error")
		On Error nOK = 0
		nOK = _EdGetEnv(nWinHandle, @ArrEnv)

		If Empty(cErr)
			On Error
		Else
			On Error &cErr
		EndIf
		
		If nOK == 0
			Return .Null.
		EndIf
		
		Return NewObject("WindowEnvironment", "Editor.prg", "", @ArrEnv)
				
	EndProc 
	
	Procedure GetCurrentWord(nWinHandle, nKey, lNotIgnoreBoundaries)
		
		Local cTextLine, cCurrentWord, cLeftText, cRightText
		Local nCurrentLine, nCurrentCol
		
		cTextLine = ""
		This.IncrementRight = 0

		Do Case
			Case Inlist(nKey, 13, 24)
				nCurrentLine = This.GetCurrentLine(nWinHandle) - 1

			Case Inlist(nKey, 5)
				nCurrentLine = This.GetCurrentLine(nWinHandle) + 1

			Otherwise
				nCurrentLine = This.GetCurrentLine(nWinHandle)
		EndCase
		
		If nCurrentLine > -1
			cTextLine = This.GetTextLine(nWinHandle, nCurrentLine)
		Endif			
				
		If nCurrentLine = This.GetCurrentLine(nWinHandle)
			nCurrentCol = This.GetCurrentCol(nWinHandle)
			cLeftText = Left(cTextLine, nCurrentCol)
			cRightText = Right(cTextLine, Len(cTextLine) - Len(cLeftText))
			cRightText = Chrtran(cRightText, This.Boundaries, Replicate(" ", Len(This.Boundaries)))
			
			If cRightText = " "
				cTextLine = cLeftText
			Else
				cTextLine = cLeftText + GetWordNum(cRightText, 1, " ")
				This.IncrementRight = Len(GetWordNum(cRightText, 1, " "))
			EndIf 
		EndIf 
		
		cTextLine = Chrtran(cTextLine, This.InvalidCharacters, Replicate("", Len(This.InvalidCharacters)))
		
		If lNotIgnoreBoundaries
			If Right(cTextLine, 1) $ This.Boundaries
				Return ""
			EndIf 
		EndIf 			

		cCurrentWord = Getwordnum(cTextLine, Getwordcount(cTextLine, This.Boundaries), This.Boundaries)

		Return cCurrentWord		
		
	EndProc	
	
	Procedure GetTextLine(nWinHandle, nLine)

		Local nStartPos, nEndPos, cTextLine
		nStartPos = This.GetLineStart(nWinHandle, nLine)
		nEndPos = This.GetLineStart(nWinHandle, nLine + 1)
		If nStartPos == nEndPos
			cTextLine = ""
		Else
			nEndPos = nEndPos - 1
			cTextLine = This.GetFileString(nWinHandle, nStartPos, nEndPos)
			cTextLine = Chrtran(cTextLine, Chr(13), "")
			cTextLine = Strtran(cTextLine, Chr(13)+Chr(10), "")
		Endif

		Return cTextLine
	Endproc

	Procedure GetTextCurrentLine(nWinHandle)
	
		Local nStartPos, nEndPos, nLine

		If This.GetFileCursorPos(nWinHandle) < 0
			Return ""
		Endif

		nLine = This.GetCurrentLine(nWinHandle)

		nStartPos = This.GetLineStart(nWinHandle, nLine)
		nEndPos = This.GetLineStart(nWinHandle, nLine+1)-1

		If nStartPos < 0 or nEndPos < 0 or nStartPos = nEndPos
			Return ""
		Endif

		Return Chrtran(This.GetFileString(nWinHandle, nStartPos, nEndPos), Chr(13), "")

	Endproc

	Procedure GetFileString(nWinHandle, nStartPos, nEndPos)
	
		Return _EdGetStr(nWinHandle, nStartPos, nEndPos)
		
	Endproc

	Procedure GetCurrentLine(nWinHandle)

		Local nCursorPos

		nCursorPos = This.GetFileCursorPos(nWinHandle)
		If nCursorPos < 0
			Return -1
		Endif

		Return _EdGetLNum(nWinHandle, nCursorPos)
		
	Endproc


	Procedure GetCurrentCol(nWinHandle)

		Local nCursorPos, nLine, nLineStart
		nCursorPos = This.GetFileCursorPos(nWinHandle)
		If nCursorPos < 0
			Return -1
		Endif
		nLine = This.GetCurrentLine(nWinHandle)
		If nLine < 0
			Return -1
		Endif
		nLineStart = This.GetLineStart(nWinHandle, nLine) 
		Return nCursorPos - nLineStart
		
	Endproc

	Procedure GetLineStart(nWinHandle, nLine)

		Return _EdGetLPos(nWinHandle, nLine)
		
	Endproc

	Procedure GetFileCursorPos(nWinHandle)
 
		Return _EdGetPos(nWinHandle) 

	Endproc

	Procedure SetFileCursorPos(nWinHandle, nPosition)

		_EdSetPos(nWinHandle, nPosition)
		
	Endproc

	Procedure InsertText(nWinHandle, cText, nPosition, cOptions)

		Local nStartPosition, nEndPosition

		If Vartype(cOptions) == "C"
			cOptions = Upper(Alltrim(cOptions))
		Else
			cOptions = ""
		Endif

		If Vartype(nPosition) == "N"
			This.SetFileCursorPos(nWinHandle, nPosition)
		Endif
 
		If "R" $ cOptions
			This.Delete(nWinHandle)
		Endif

		nStartPosition = This.GetFileCursorPos(nWinHandle)
		This.Insert(nWinHandle, cText)
		nEndPosition = This.GetFileCursorPos(nWinHandle)

		Do Case
			Case "B" $ cOptions
				This.SetFileCursorPos(nWinHandle, nStartPosition)
			Case "H" $ cOptions
				This.Select(nWinHandle, nStartPosition, nEndPosition)
		Endcase

	Endproc

	Procedure Delete(nWinHandle)

		_EdDelete(nWinHandle)

	Endproc

	Procedure Insert(nWinHandle, cText)

		_EdInsert(nWinHandle, cText, Len(cText))
		
	Endproc

	Procedure Select(nWinHandle, nStartPos, nEndPos)

		_EdSelect(nWinHandle, nStartPos, nEndPos)
		
	EndProc
	
	Procedure WSelect(nWinHandle)
	 
		_WSelect(nWinHandle)
		
	EndProc 

	Procedure GetAllText(nWinHandle)

		Local nStartPos, nEndPos
		nStartPos = _EdGetLPos(nWinHandle, 0)
		nEndPos = _EdGetLPos(nWinHandle, This.MaxLine + 1 ) - 1

		If nStartPos < 0 Or nEndPos < 0
			Return "" 
		Endif

		Return This.GetFileString(nWinHandle, nStartPos, nEndPos)
		
	EndProc

	Procedure GetActiveWindowHandle

		Local nHandleWinOnTop
		nHandleWinOnTop = _WOnTop()
		If nHandleWinOnTop <= 0
			Return 0
		EndIf
		
		oWinEnvironment = This.GetWindowEnvironment(nHandleWinOnTop)
		
		If IsNull(oWinEnvironment)
			nHandleWinOnTop = 0
		Endif

		Return nHandleWinOnTop
		
	Endproc

	Procedure GetTitle(nWinHandle)
	
		Return _WTitle(nWinHandle)
		
	EndProc
	
	Procedure Undo(nWinHandle)
		
		_EdUndo(nWinHandle)
		
	EndProc 
	
	Procedure WhToHWND(nWinHandle)
	
		Return _WhToHWND(nWinHandle)
		
	EndProc 	

EndDefine 

Define Class WindowEnvironment As Custom

	ED_COMMAND  = 0
	ED_PROGRAM 	= 1
	ED_FILE		= 2
	ED_MEMO		= 3
	ED_QUERY	= 6
	ED_SCREEN	= 7
	ED_MENU		= 8
	ED_VIEW		= 9
	ED_SNIP		= 10
	ED_TEXT		= 11
	ED_PROC		= 12
	ED_PROJTEXT	= 13
	
	FileName 		= ""
	Length 			= 0		&& # of bytes in text.
	LenLimit 		= 0		&& Max allowable length. 0 = infinite.
   	Dirty 			= 0		&& Has the file been changed?
	AutoIndent 		= 0		&& Auto indent?
	Backup 			= 0		&& Make backup files?
	AddLineFeeds	= 0		&& Add line feeds when saving?
	AutoCompile		= 0		&& Shall we auto compile this thing?
	AddCtrlZ		= 0		&& Add end of file ctrl-z?
	SavePrefs		= 0		&& Save edit preferences?
	DragAndDrop		= 0		&& Allow drag-and-drop.
	ReadOnly		= 0		&& 0 = not r/o, 1 = file is r/o, 2 = file is r/w, opened r/o, 3 = file is r/o, opened r/o.
	Status 			= 0		&& Display status bar?
	LockPrefs 		= 0		&& Can update the preferences?
	InsertMode		= 0    	&& 0 = No, 1 = Yes
	Wrap			= 0 	&& If < 0, new line at Return only.
	SelStart		= -1	&& Selection start.
	SelEnd			= -1	&& Selection end.
	SelAnchor		= 0		&& Selection anchor point.
	JustMode		= 0		&& Justification (0 = left, 1 = right, 2 = center).
	TabWidth		= 0		&& TAB size in spaces.
	FontName		= ""
	FontSize		= 0
	FontStyle		= 0		&& 0 = plain, 1 = bold, 2 = italic, 3 = bold italic.
	Kind			= -1		&& Kind of editor session; EDCOMMAND, EDPROGRAM, etc.
	
	Procedure Init(ArrWinEnvironment)
	
		This.FileName 		= ArrWinEnvironment[1]
		This.Length 		= ArrWinEnvironment[2]
		This.LenLimit 		= ArrWinEnvironment[3]
	   	This.Dirty 			= ArrWinEnvironment[4]
		This.AutoIndent 	= ArrWinEnvironment[5]
		This.Backup 		= ArrWinEnvironment[6]
		This.AddLineFeeds	= ArrWinEnvironment[7]
		This.AutoCompile	= ArrWinEnvironment[8]
		This.AddCtrlZ		= ArrWinEnvironment[9]
		This.SavePrefs		= ArrWinEnvironment[10]
		This.DragAndDrop	= ArrWinEnvironment[11]
		This.ReadOnly		= ArrWinEnvironment[12]
		This.Status 		= ArrWinEnvironment[13]
		This.LockPrefs 		= ArrWinEnvironment[14]
		This.InsertMode		= ArrWinEnvironment[15]
		This.Wrap			= ArrWinEnvironment[16]
		This.SelStart		= ArrWinEnvironment[17]
		This.SelEnd			= ArrWinEnvironment[18]
		This.SelAnchor		= ArrWinEnvironment[19]
		This.JustMode		= ArrWinEnvironment[20]
		This.TabWidth		= ArrWinEnvironment[21]
		This.FontName		= ArrWinEnvironment[22]
		This.FontSize		= ArrWinEnvironment[23]
		This.FontStyle		= ArrWinEnvironment[24]
		This.Kind			= ArrWinEnvironment[25]
		
	EndProc 
	
EndDefine