Define Class EditorModel As Session

	Hidden WHandle
	Hidden HWnd
	Boundaries = "\,;:)(.[]'=<>+-*/!^%|&#{}?@$" + ["] + Chr(13) + Chr(10) + Chr(32) + Chr(9)
	InvalidCharacters = Chr(1)+Chr(2)+Chr(3)+Chr(4)+Chr(5)+Chr(6)+Chr(7)+Chr(8)
	FontName = "Consolas"
	FontSize = 10
	Source = -1
	LineHeight = 0
	AvgCharWidth = 0
	
	Procedure Init
		Lparameters WHandle

		This.WHandle = WHandle
		This.HWnd = This.WhToHWND()
		This.Name = Juststem(This.GetTitle())

		If !"FOXTOOLS.FLL" $ Upper(Set("Library"))
			Set Library To (Home()+"FoxTools.Fll") Additive
		EndIf
		
		Dimension Env[25]
		This.EditorEnvironment(@Env)
		This.FontName = Env[22]
		This.FontSize = Env[23]
		This.Source = Env[25]
		This.LineHeight = FontMetric(1, This.FontName, This.FontSize)
		This.AvgCharWidth = FontMetric(6, This.FontName, This.FontSize)				
		
	EndProc
	
	* Source (Env[25]):
	* 	-1	the window is not an edit window
	*	 0	command window
	*	 1	modify command window
	*	 2	modify file window
	*	 3	memo window
	*	 6	Query
	*	 7	screen
	*	 8	menu designer code window
	*	 9	view
	*	10	method edit window in class or form designer
	*	11	Text
	*	12	modify procedure window
	*	13	Project Text
	
	Procedure EditorEnvironment
		Lparameters Env
		Local OK, Err
		
		Dimension Env[25]
		
		Err = On("Error")
		On Error OK = 0
		OK = _EdGetEnv(This.WHandle, @Env)

		If Empty(Err)
			On Error
		Else
			On Error &Err
		Endif
		If OK == 0
			Return -1
		EndIf
		
	Endproc

	Procedure GetSelectionRange

		Local Env[25], OK, Err

		Err = On("Error")
		On Error OK = 0
		OK = _EdGetEnv(This.WHandle, @Env)

		If Empty(Err)
			On Error
		Else
			On Error &Err
		Endif
		If OK == 0
			Return Createobject("Range", -1, -1)
		Endif

		If Env[17] = Env[18]
			Return Createobject("Range", -1, -1)
		Else
			Return Createobject("Range", Env[17], Env[18])
		Endif
	Endproc

	Procedure GetCurrentWord
		Lparameters Key, NotIgnoreBoundaries
		
		Local TextLine, CurrentWord, Lineno
		TextLine = ""

		Do Case
			Case Inlist(Key, 13, 24)
				Lineno = This.GetCurrentLine() - 1

			Case Inlist(Key, 5)
				Lineno = This.GetCurrentLine() + 1

			Otherwise
				Lineno = This.GetCurrentLine()
		EndCase
		
		If Lineno > -1
			TextLine = This.GetTextLine(Lineno)
		Endif			
				
		If Lineno = This.GetCurrentLine()
			CursorPos = This.GetCurrentCol()
			LeftText = Left(TextLine, CursorPos)
			RightText = Right(TextLine, Len(TextLine) - Len(LeftText))
			RightText = Chrtran(RightText, This.Boundaries, Replicate(" ", Len(This.Boundaries)))
			
			If RightText = " "
				TextLine = LeftText
			Else
				TextLine = LeftText + GetWordNum(RightText, 1, " ")
			EndIf 
		EndIf 
		
		TextLine = Chrtran(TextLine, This.InvalidCharacters, Replicate("", Len(This.InvalidCharacters)))
		
		If NotIgnoreBoundaries
			If Right(TextLine, 1) $ This.Boundaries
				Return ""
			EndIf 
		EndIf 			

		CurrentWord = Getwordnum(TextLine, Getwordcount(TextLine, This.Boundaries), This.Boundaries)

		Return CurrentWord		
		
	EndProc 

	Procedure GetTextLine
		Lparameters Lineno

		Local StartPos, EndPos, TextLine
		StartPos = This.GetLineStart(Lineno)
		EndPos = This.GetLineStart(Lineno + 1)
		If StartPos == EndPos
			TextLine = ""
		Else
			EndPos = EndPos - 1
			TextLine = This.GetFileString(StartPos, EndPos)
			TextLine = Chrtran(TextLine, Chr(13), "")
			TextLine = Strtran(TextLine, Chr(13)+Chr(10), "")
		Endif

		Return TextLine
	Endproc

	Procedure GetTextCurrentLine
		Local StartPos, EndPos, Lineno

		If This.GetFileCursorPos() < 0
			Return ""
		Endif

		Lineno = This.GetCurrentLine()

		StartPos = This.GetLineStart(Lineno)
		EndPos = This.GetLineStart(Lineno+1)-1

		If StartPos = EndPos
			Return ""
		Endif

		Return Chrtran(This.GetFileString(StartPos, EndPos), Chr(13), "")

	Endproc

	Procedure GetFileString
		Lparameters StartPos, EndPos

		Return _EdGetStr(This.WHandle, StartPos, EndPos)
	Endproc

	Procedure GetCurrentLine

		Local CursorPos

		CursorPos = This.GetFileCursorPos()
		If CursorPos < 0
			Return -1
		Endif

		Return _EdGetLNum(This.WHandle, CursorPos)
	Endproc


	Procedure GetCurrentCol

		Local CursorPos, Lineno, LineStart
		CursorPos = This.GetFileCursorPos()
		If CursorPos < 0
			Return -1
		Endif
		Lineno = This.GetCurrentLine()
		If Lineno < 0
			Return -1
		Endif
		LineStart = This.GetLineStart(Lineno)
		Return CursorPos - LineStart
	Endproc

	Procedure GetLineStart
		Lparameters Lineno

		Return _EdGetLPos(This.WHandle, Lineno)
	Endproc

	Procedure GetFileCursorPos

		Return _EdGetPos(This.WHandle)

	Endproc

	Procedure SetFileCursorPos
		Lparameters Position

		_EdSetPos(This.WHandle, Position)
	Endproc

	Procedure InsertText
		Lparameters Text, Position, Options

		Local StartPosition, EndPosition

		If Vartype(Options) == "C"
			Options = Upper(Alltrim(Options))
		Else
			Options = ""
		Endif

		If Vartype(Position) == "N"
			This.SetFileCursorPos(Position)
		Endif

		If "R" $ Options
			This.Delete()
		Endif

		StartPosition = This.GetFileCursorPos()
		This.Insert(Text)
		EndPosition = This.GetFileCursorPos()

		Do Case
			Case "B" $ Options
				This.SetFileCursorPos(StartPosition)
			Case "H" $ Options
				This.Select(StartPosition, EndPosition)
		Endcase

	Endproc

	Procedure Delete

		_EdDelete(This.WHandle)

	Endproc

	Procedure Insert
		Lparameters Text

		_EdInsert(This.WHandle, Text, Len(Text))
	Endproc

	Procedure Select
		Lparameters StartPos, EndPos

		_EdSelect(This.WHandle, StartPos, EndPos)
	EndProc
	
	Procedure WSelect
	
		_WSelect(This.WHandle)
		
	EndProc 

	Procedure GetAllText

		Local StartPos, EndPos
		StartPos = _EdGetLPos(This.WHandle, 0)
		EndPos = _EdGetLPos(This.WHandle, This.MaxLine + 1 ) - 1

		If StartPos < 0 Or EndPos < 0
			Return ""
		Endif

		Return This.GetFileString(StartPos, EndPos)
	Endproc

	Procedure GetCurrentWindow

		Local WindowOnTop
		WindowOnTop = _WOnTop()
		If WindowOnTop <= 0
			Return 0
		Endif
		If GetEditSource(WindowOnTop) == -1
			WindowOnTop = 0
		Endif

		Return WindowOnTop
	Endproc

	Procedure GetTitle
		Return _WTitle(This.WHandle)
	EndProc
	
	Procedure Undo
		
		_EdUndo(This.WHandle)
		
	EndProc 
	
	Procedure WhToHWND
		Return _WhToHWND(This.WHandle)
	EndProc 

Enddefine

Define Class Range As Custom

	Start = -1
	End = -1

	Procedure Init
		Lparameters Start, End

		This.Start = Start
		This.End = End

	Endproc
	
EndDefine