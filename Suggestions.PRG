Define Class Suggestions As EditorModel of "EditorModel.prg"
	
	MaxLine = 130 * 1000
	MaxSuggestions = 1000
	FrmSuggestion = .Null.
	CurrentWord = ""
	Binding = .F.
	
	AddPublicVariables = .T.
	AddDefaultCommands = .T.
	AddDefaultFuctions = .T.
	AddDefaultBaseClasses = .T.
	AddDefaultDBCEvents = .T.
	
	AutoClosingSingleQuotes = .T.
	AutoClosingDoubleQuotes = .T.
	AutoClosingBraces = .T.  
	AutoClosingBrackets = .T.
	AutoClosingParentheses = .T.
	
	EncloseSelectedTextInSingleQuotes = .T.
	EncloseSelectedTextInDoubleQuotes = .T.
	EncloseSelectedTextInBraces = .T.
	EncloseSelectedTextInBrackets = .T.
	EncloseSelectedTextInParentheses = .T. 	

	Procedure Init
		Lparameters WHandle
		
		DoDefault(WHandle)
		This.FrmSuggestion = NewObject("FrmSuggestion", "Popup.prg", "", This)
		This.TextToCursor()
		
		Declare Integer GetCaretPos in Win32API String@
		Declare Integer GetParent in Win32API Integer
		Declare Integer GetWindowRect in Win32API Long, String@
		Declare Integer FindWindowEx in Win32API Integer, Integer, String, String	
			
	EndProc 
	
	Procedure RemoveCurrentChar
		
		Local Position
		Position = This.GetFileCursorPos()
		This.Select(Position-1, Position)
		This.Delete()
				
	EndProc
	
	Procedure ShowPemSuggestions
		
		Local NewBoundaries, CurrentTextLine, CursorPos, LeftText, ObjName
		
		NewBoundaries = Chrtran(This.Boundaries, ".", "")
		CurrentTextLine = This.GetTextCurrentLine()
		
		CursorPos = This.GetCurrentCol()
		LeftText = Left(CurrentTextLine, CursorPos)
		CurrentTextLine = GetWordNum(LeftText, GetWordCount(LeftText, NewBoundaries), NewBoundaries)
		LeftText = Substr(CurrentTextLine, 1, rat(".", CurrentTextLine, 1)-1)
		ObjName = GetWordNum(LeftText, GetWordCount(LeftText, NewBoundaries), NewBoundaries)
		
		If !Empty(ObjName)
			If This.GetPemSuggestions(ObjName)
				This.SearchWord("crsPemCache", .T.)				
				This.ShowSuggestions()					
				Return .T.
			EndIf 						
		EndIf 	
		
		Return .F.	
		
	EndProc
	
	Procedure GetPemSuggestions
		Lparameters ObjName
		
		Local i
		Local Array Members[1]
		
		Select * from crsCache where 1=0 into cursor crsPemCache READWRITE
		
		If Lower(ObjName) == "this"
			Return .F.
		EndIf 
		
		If Type(ObjName) = "O"
			For i=1 to AMembers(Members, Evaluate(ObjName), 3)
				Insert into crsPemCache values (Proper(Members[i, 1]), Members[i, 1], Lower(Substr(Members[i, 2], 1, 3)))
			Next 
			
			Return .T.
			
		Else
			Return .F.
		EndIf		
		
	EndProc 
	
	Procedure ShowSuggestions
	
		If Reccount("crsFilter") > 0
			This.FrmSuggestion.lstItems.Refresh()
			This.FrmSuggestion.Visible = .T.
			This.WSelect()
		Else
			This.FrmSuggestion.Visible = .F.
		EndIf	
		
	EndProc 
	
	Procedure ShowSimpleSuggestions
		Lparameters Key, Control
		
		Local CurrentWord, WordLike, i, ForceSearch, IsObject
		
		If This.EncloseIn(Key)
			Return 
		EndIf 
		
		If This.AutoClosing(Key)
			Return 
		EndIf 
		
		If Key = 32 and Control
			ForceSearch = .T.
			This.TextToCursor()
		EndIf 
		
		This.SearchWord("crsCache", ForceSearch)				

		This.ShowSuggestions()
		
	EndProc 
	
	Procedure SearchWord
		Lparameters SourceAlias, ForceSearch 
		
		Local WordLike, i
		
		WordLike = "*"
		This.CurrentWord = Upper(This.GetCurrentWord(0, .T.))
		
		For i=1 to Len(This.CurrentWord)
			WordLike = WordLike + Substr(This.CurrentWord, i, 1) + "*"
		Next 	
		
		Select top (This.MaxSuggestions) * from (SourceAlias) where (ForceSearch or !Empty(This.CurrentWord)) and Like(WordLike, UpWord);
		order by UpWord into cursor crsFilter
			
	
	EndProc 

	Procedure TextToCursor
		
		Local AllText, NewText, Steps, LenStep, RestWord,;
				CharRight, nAt, i, j , Type 
				
		Create Cursor ("crsCache") (Word c(40), UpWord c(40), Type c(3))
		Index on Upper(Word) tag word				
		
		AllText = This.GetAllText()
		
		LenStep = 250
		Steps = Max(Ceiling(Len(AllText) / LenStep), LenStep)

		RestWord = ""
		
		For i = 1 to Steps
			
			NewText = RestWord + Substr(AllText, (LenStep * (i-1))+1, LenStep)
			RestWord = ""
			
			If i != Steps
				Do while !Empty(NewText)
					CharRight = Right(NewText, 1)
					If CharRight $ This.Boundaries  
						Exit 
					EndIf 
					
					RestWord = CharRight + RestWord
					nAt = At(CharRight, NewText, Max(Occurs(CharRight, NewText), 1))-1
					NewText = Substr(NewText, 1, nAt)
				EndDo 
			EndIf 	

			For j=1 to GetWordCount(NewText , This.Boundaries)
							
				m.Word = Padr(GetWordNum(NewText , j, This.Boundaries), 40)
				
 				This.AddWord(m.Word)
			
			Next  	
				 
		Next
		
		If This.AddPublicVariables
			This.GetPublicVariables()
		EndIf 	 
		
		If This.AddDefaultCommands
			This.GetDefaultCommands()
		EndIf 
		
		If This.AddDefaultFuctions
			this.GetDefaultFuctions()
		EndIf 
				
		If This.AddDefaultDBCEvents
			This.GetDefaultDBCEvents()
		EndIf 
		
		If This.AddDefaultBaseClasses
			This.GetDefaultBaseClasses()
		EndIf
				
	EndProc 
	
	Procedure AddWord
		Lparameters Word
		Local VarType, Type 
		
		If IsDigit(m.Word)	
			Return 
		EndIf 
	
		If !Seek(Upper(m.Word), "crsCache", "word")
			
			VarType = Type(m.Word) 
			Do Case 
				Case VarType = "A" 
					m.Type = "arr"
				Case VarType = "C" 
					m.Type = "cha"
				Case VarType = "D" 
					m.Type = "dat"
				Case VarType = "G" 
					m.Type = "gen"
				Case VarType = "L" 
					m.Type = "log"
				Case VarType = "M" 
					m.Type = "mem"
				Case VarType = "N" 
					m.Type = "num"
				Case VarType = "O"
					m.Type = "obj"
				Case VarType = "Q"
					m.Type = "bin"
				Case VarType = "S"
					m.Type = "scr"
				Case VarType = "T"
					m.Type = "dti"
				Case VarType = "W"
					m.Type = "blo"
				Case VarType = "Y"
					m.Type = "cur"
				Otherwise 
					m.Type = ""																																			
			EndCase 	 
			
			Insert into crsCache values (m.Word, Upper(m.Word), m.Type)			
		EndIf	
	EndProc 
	
	procedure GetPublicVariables
			
		Local array ArrTmpFile[1]
		Local i, TmpFileName, OldSafety, IsPublic, Word, StrFile  
			
		TmpFileName = Sys(2023)+"\VFP_MEMORY_"+Sys(2015)+".TXT"
		OldSafety = set("Safety")
		
		Set Safety off  
		List Memory to File (TmpFileName) NoConsole
		Set Safety &OldSafety
		
		StrFile = FileToStr(TmpFileName)

		For i=1 to ALines(ArrTmpFile, StrFile)

			m.Word = GetWordNum(ArrTmpFile[i], 1, " ")
			IsPublic = GetWordNum(ArrTmpFile[i], 2, " ") = "Pub"
			If IsPublic and !Empty(m.Word)
				
				This.AddWord(Proper(m.Word))
				 	
			EndIf 	
		Next 
		
		Try  
			Erase(TmpFileName)
		Catch
		EndTry 		
				
	EndProc	
	
	Procedure GetDefaultCommands
		Local ArrCommands[1], i
		
		For i=1 to ALanguage(ArrCommands, 1)
			This.AddWord(ArrCommands[i])
		Next
	EndProc 
	
	Procedure GetDefaultFuctions
		Local ArrFunctions[1], i
		
		For i=1 to ALanguage(ArrFunctions, 2)
			This.AddWord(ArrFunctions[i, 1])
		Next	
	EndProc 
	
	Procedure GetDefaultBaseClasses
		Local ArrBaseClasses[1], i
		
		For i=1 to ALanguage(ArrBaseClasses, 3)
			This.AddWord(ArrBaseClasses[i])
		Next	
	EndProc 
	
	Procedure GetDefaultDBCEvents
		Local ArrDBCEvents[1], i
		
		For i=1 to ALanguage(ArrDBCEvents, 4)
			This.AddWord(ArrDBCEvents[i])
		Next	
	EndProc 
	
	Procedure AddCurretWord
		Lparameters Key
		Local CurrentWord
		
		CurrentWord = This.GetCurrentWord(Key)
		
		If Empty(CurrentWord)
			Return 
		EndIf 
		
		This.AddWord(CurrentWord)
	EndProc 
	
	Procedure Destroy
	
		This.FrmSuggestion = .Null.  
		
	EndProc
	
	Procedure AutoClosing
		Lparameters key
		
		Local TextInsert
		If !InList(key, 39, 34, 123, 91, 40)
			Return .F.
		EndIf
				
		Do Case
			Case key = 39 and This.AutoClosingSingleQuotes
				TextInsert = "'" 
			Case key = 34 and This.AutoClosingDoubleQuotes
				TextInsert = '"'
			Case key = 123 and This.AutoClosingBraces
				TextInsert = "}"
			Case key = 91 and This.AutoClosingBrackets
				TextInsert = "]"
			Case key = 40 and This.AutoClosingParentheses
				TextInsert = ")"
		EndCase 
		
		If !Empty(TextInsert)
			Position = This.GetFileCursorPos()
			This.InsertText(TextInsert)
			This.SetFileCursorPos(Position)
			Return .T.	
		EndIf 		
		
	EndProc 
	
	Procedure EncloseIn
		Lparameters key
		
		Local Range, TextInsert
		If !InList(key, 39, 34, 123, 91, 40)
			Return .F.
		EndIf	

		Range = This.GetSelectionRange()
		If Range.Start = -1 or Range.End = -1
			Return .F.
		EndIf
		
		Do Case
			Case key = 39 and This.EncloseSelectedTextInSingleQuotes 
				TextInsert = "'"
			Case key = 34 and This.EncloseSelectedTextInDoubleQuotes 
				TextInsert = '"'
			Case key = 123 and This.EncloseSelectedTextInBraces 
				TextInsert = "}"
			Case key = 91 and This.EncloseSelectedTextInBrackets 
				TextInsert = "]"
			Case key = 40 and This.EncloseSelectedTextInParentheses 
				TextInsert = ")"
		EndCase 
		
		If !Empty(TextInsert)
			This.InsertText(TextInsert, Range.End)
			This.SetFileCursorPos(Range.Start)
			Return .T.	
		EndIf 
		
	EndProc	
	
	Procedure GetCaretPosition
		LParameter Top, Left
		
		Local MouseLeft, MouseTop, Point, Child, ParentScreen, ;
				ChildTop, ChildLeft, ScreenTop, ScreenLeft, Rect
		
		Point = Space(8)
		If GetCaretPos(@POINT) == 0
			MouseLeft = Mcol("", 3)
			MouseTop = Mrow("", 3)
		Else
			MouseLeft = Asc(Left(Point, 1)) + 256 * Asc(Substr(Point, 2, 1))
			MouseTop = Asc(SubSTr(Point, 5, 1)) + 256 * Asc(Substr(Point, 6, 1))
		Endif
		
		Child = This.GetClientWindow()
		If Child == 0
			Return .F.
		EndIf
		
		ParentScreen = GetParent(This.HWND)
		If ParentScreen == 0
			Return .F.
		Endif

		Rect = Replicate(Chr(0), 16)
		
		GetWindowRect(Child, @Rect)
		ChildLeft = This.FromInt(Left(Rect, 4))
		ChildTop = This.FromInt(Substr(Rect, 5, 4))
		GetWindowRect(ParentScreen, @Rect)
		ScreenLeft = This.FromInt(Left(Rect, 4))
		ScreenTop = This.FromInt(Substr(Rect, 5, 4))
		
		Left = MouseLeft + ChildLeft - ScreenLeft
		Top = MouseTop + ChildTop - ScreenTop

	EndProc	
	
	Procedure FromInt
		Lparameters String
	  	
	  	Local Value, i
	 	Value = 0
	  	For i=1 to Len(String)
			Value = Value + Asc(SubStr(String, i, 1)) * 256 ^ (i-1)
	  	Next 
		Return Value	
	EndProc 
		
	Procedure GetClientWindow
	
		Local Child

		Child = 0
		Do While .T.
			Child = FindWindowEx(This.HWND, Child, .Null., .Null.)
			If Child == 0
				Exit
			Endif
			If FindWindowEx(Child, 0, .Null., .Null.) == 0
				Exit
			Endif
		Enddo
			
		Return Child	
	EndProc 

Enddefine