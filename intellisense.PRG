Define Class Intellisense As Editor Of "Editor.prg"

	Context = "" && not implemented
	WHandle = 0
	HWnd = 0

	FontName = "Consolas"
	FontSize = 10
	LineHeight = 0
	AvgCharWidth = 0
	AllText = ""

	Dimension ArrCurrentItems[1, 5]
	Dimension ArrItems[1, 5]
	ArrItemsCount = 0

	MaxSuggestions = 100			&& Maximum suggestions added to list

	FrmSuggestion = .Null.			&& Form with the suggestion list
	FrmTooltip = .Null.				&& Additional information form

	CurrentWord = ""				&& Current word

	ShowInfo = .T.					&& Show additional information?

	AddPublicVariables = .T.
	Addkeywords = .T.
	AddDefaultCommands = .T.
	AddDefaultFuctions = .T.
	AddDefaultBaseClasses = .T.
	AddDefaultDBCEvents = .F.
	

	AutoClosingSingleQuotes = .T.
	AutoClosingDoubleQuotes = .T.
	AutoClosingBraces = .T.
	AutoClosingBrackets = .T.
	AutoClosingParentheses = .T.

	AutoSurroundSingleQuotes = .T.
	AutoSurroundDoubleQuotes = .T.
	AutoSurroundBraces = .T.
	AutoSurroundBrackets = .T.
	AutoSurroundParentheses = .T.

	Procedure Init(nWinHandle)

		This.Declare()

		DoDefault()

		This.WHandle = nWinHandle
		This.HWnd = This.WhToHWND(nWinHandle)

		oWinEnvironment = This.GetWindowEnvironment(nWinHandle)

		This.FontName = oWinEnvironment.FontName
		This.FontSize = oWinEnvironment.FontSize

		This.LineHeight = Fontmetric(1, This.FontName, This.FontSize)
		This.AvgCharWidth = Fontmetric(6, This.FontName, This.FontSize)

		This.FrmSuggestion = Newobject("FrmSuggestion", "Forms.PRG", "", This.HWnd)
		This.FrmTooltip = Newobject("FrmTooltip", "Forms.PRG", "", This.HWnd)
		
		This.TextToMemory()

	Endproc

	Procedure Declare

		Declare Integer GetCaretPos In Win32API As ___GetCaretPos String@
		Declare Integer GetParent In Win32API As ___GetParent Integer
		Declare Integer GetWindowRect In Win32API As ___GetWindowRect Long, String@
		Declare Integer FindWindowEx In Win32API As ___FindWindowEx Integer, Integer, String, String

	Endproc

	Procedure RemoveCurrentChar

		Local nPosition
		nPosition = This.GetFileCursorPos(This.WHandle, This.WHandle)
		This.Select(nPosition-1, nPosition)
		This.Delete()

	Endproc

	Procedure ShowPemSuggestions

		Local cNewBoundaries, cCurrentTextLine, nCursorPos, cLeftText, cObjName

		cNewBoundaries = Chrtran(This.Boundaries, ".", "")
		cCurrentTextLine = This.GetTextCurrentLine(This.WHandle)

		nCursorPos = This.GetCurrentCol(This.WHandle)
		cLeftText = Left(cCurrentTextLine, nCursorPos)
		cCurrentTextLine = Getwordnum(cLeftText, Getwordcount(cLeftText, cNewBoundaries), cNewBoundaries)
		cLeftText = Substr(cCurrentTextLine, 1, Rat(".", cCurrentTextLine, 1)-1)
		cObjName = Getwordnum(cLeftText, Getwordcount(cLeftText, cNewBoundaries), cNewBoundaries)

		If !Empty(cObjName)
			If This.GetPemSuggestions(cObjName)
				Return .T.
			Endif
		Endif

		Return .F.

	Endproc

	Procedure GetPemSuggestions(cObjName)

		Local i, cPemCode, cPemParam, cPemTip, ArrItems[1, 2], nArrItemsCount, ArrToShow[1, 2]
		Local Array ArrMembers[1]

		If InList(Lower(cObjName), "this", "_vfp")
			Return .F.
		Endif

		If Type(cObjName) = "O"

			If !Used("__foxcodePEM")
				Use __foxcodePEM In 0 Shared Again
			Endif

			nArrItemsCount = 0

			For i=1 To Amembers(ArrMembers, Evaluate(cObjName), 3)

				cPemCode = Lower(ArrMembers[i, 1])
				cPemParam = ""
				cPemTip = ""
				If Seek(Padr(Upper(cPemCode), 30)+Upper(&cObjName..BaseClass), "__foxcodePEM", "codeclass")
					cPemCode = __foxcodePEM.Code
					cPemParam = __foxcodePEM.Param
					cPemTip = __foxcodePEM.Tip
				Endif

				nArrItemsCount = nArrItemsCount + 1
				Dimension ArrItems[nArrItemsCount, 5]
				ArrItems[nArrItemsCount, 1] = Alltrim(cPemCode)
				ArrItems[nArrItemsCount, 2] = Alltrim(Upper(cPemCode))
				ArrItems[nArrItemsCount, 3] = Lower(Substr(ArrMembers[i, 2], 1, 3))
				ArrItems[nArrItemsCount, 4] = Alltrim(cPemParam)
				ArrItems[nArrItemsCount, 5] = Alltrim(cPemTip)

			Next

			This.SearchWord(@ArrItems, .T.)
			This.ShowSuggestions()

			Return .T.

		Else
			Return .F.
		Endif

	Endproc

	Procedure ShowSuggestions()

		This.FrmSuggestion.LockScreen = .T.
		This.FrmTooltip.LockScreen = .T.

		If !Empty(This.ArrCurrentItems)
			This.FrmSuggestion.Refresh()
			If !This.FrmSuggestion.Visible
				This.FrmSuggestion.Visible = .T.
			EndIf 
		Else
			This.FrmTooltip.Visible = .F.
			This.FrmSuggestion.Visible = .F.
		Endif

		This.FrmSuggestion.LockScreen = .F.
		This.FrmTooltip.LockScreen = .F.

		This.WSelect(This.WHandle)

	Endproc

	Procedure ShowSimpleSuggestions(nKey, lControl)

		Local cCurrentWord, cWordLike, i, lIsObject

		If This.EncloseIn(nKey)
			Return
		Endif

		If This.AutoClosing(nKey)
			Return
		Endif

		If nKey = 32 And lControl
			This.SearchWord(.F., .T.)
		Else
			This.SearchWord()
		Endif

		This.ShowSuggestions()

	Endproc

	Procedure SearchWord(ArrItems, lForce)

		Local cWordLike, i, nArrToShowCount, ArrToShow[1, 2]

		Dimension This.ArrCurrentItems[1, 5]

		This.ArrCurrentItems[1, 1] = ""

		nArrToShowCount = 0
		cWordLike = "*"
		This.CurrentWord = Upper(This.GetCurrentWord(This.WHandle, 0, .T.))

		If !lForce And Empty(This.CurrentWord)
			Return
		Endif

		For i=1 To Len(This.CurrentWord)
			cWordLike = cWordLike + Substr(This.CurrentWord, i, 1) + "*"
		Next

		If Empty(ArrItems)

			For i=1 To This.ArrItemsCount

				If nArrToShowCount = This.MaxSuggestions
					Exit
				Endif

				If Like(cWordLike, This.ArrItems[i, 2])
					nArrToShowCount = nArrToShowCount + 1
					Dimension ArrToShow[nArrToShowCount, 5]
					ArrToShow[nArrToShowCount, 1] = This.ArrItems[i, 1]
					ArrToShow[nArrToShowCount, 2] = This.ArrItems[i, 2]
					ArrToShow[nArrToShowCount, 3] = This.ArrItems[i, 3]
					ArrToShow[nArrToShowCount, 4] = This.ArrItems[i, 4]
					ArrToShow[nArrToShowCount, 5] = This.ArrItems[i, 5]
				Endif
			Next

		Else

			For i=1 To Alen(ArrItems, 1)

				If nArrToShowCount = This.MaxSuggestions
					Exit
				Endif

				If Like(cWordLike, ArrItems[i, 2])
					nArrToShowCount = nArrToShowCount + 1
					Dimension ArrToShow[nArrToShowCount, 5]
					ArrToShow[nArrToShowCount, 1] = ArrItems[i, 1]
					ArrToShow[nArrToShowCount, 2] = ArrItems[i, 2]
					ArrToShow[nArrToShowCount, 3] = ArrItems[i, 3]
					ArrToShow[nArrToShowCount, 4] = ArrItems[i, 4]
					ArrToShow[nArrToShowCount, 5] = ArrItems[i, 5]
				Endif
			Next

		Endif

		Dimension This.ArrCurrentItems[Alen(ArrToShow, 1), 5]

		=Asort(ArrToShow, 1,-1 , 0, 1)
		Acopy(ArrToShow, This.ArrCurrentItems)

	Endproc

	Procedure TextToMemory

		This.ArrItemsCount = 0
		Dimension This.ArrItems[1, 1]
		This.ArrItems[1, 1] = ""
		
		If This.Addkeywords
			This.Getkeywords()
		EndIf 
		
		If This.AddPublicVariables
			This.GetPublicVariables()
		Endif

		If This.AddDefaultCommands
			This.GetDefaultCommands()
		Endif

		If This.AddDefaultFuctions
			This.GetDefaultFuctions()
		Endif

		If This.AddDefaultDBCEvents
			This.GetDefaultDBCEvents()
		Endif

		If This.AddDefaultBaseClasses
			This.GetDefaultBaseClasses()
		Endif
		
		cAllText = This.GetAllText(This.WHandle)
		
		Return This.AddSimpleWordsAsync(cAllText)
	
	EndProc
	
	Procedure AddSimpleWordsAsync(cAllText)
		
		Declare Long CreateThreadWithObject In DMult.DLL ;
			String pszClass, ;
			String pszMethod, ;
			Object oRef, ;
			Long @pdwThreadId
			
		Declare CloseHandle In Win32API Long
		 
		Local nHandle, nThreadID, oCallback 
		nThreadID = 0	

		This.AllText = cAllText
		oCallback = CreateObject("AddSimpleWordsAsync", cAllText, This.HWnd)
		nHandle = CreateThreadWithObject( ;
						Strconv("LoadTextAsync.LoadTextAsync"+Chr(0), 5), ;
						Strconv("TextToMemoryAsync"+Chr(0), 5), ;
						_VFP.Eval("oCallback"), ;
						@nThreadID)	
		
		=CloseHandle(nHandle)				
	EndFunc	 

	Procedure AddWord(cWord, cType, cParam, cTip)

		Local cVarType

		If Isdigit(cWord)
			Return
		Endif

		If Len(Alltrim(cWord)) < 2 Or Right(cWord, 1) = "?"
			Return
		Endif

		cWord = Alltrim(cWord)

		If Ascan(This.ArrItems, cWord, 1, -1, 1, 15) = 0

			If Empty(cType)
				cVarType = Type(cWord)

				Do Case
					Case cVarType == "A"
						cType = "arr"
					Case cVarType == "C"
						cType = "cha"
					Case cVarType == "D"
						cType = "dat"
					Case cVarType == "G"
						cType = "gen"
					Case cVarType == "L"
						cType = "log"
					Case cVarType == "M"
						cType = "mem"
					Case cVarType == "N"
						cType = "num"
					Case cVarType == "O"
						cType = "obj"
					Case cVarType == "Q"
						cType = "bin"
					Case cVarType == "S"
						cType = "scr"
					Case cVarType == "T"
						cType = "dti"
					Case cVarType == "W"
						cType = "blo"
					Case cVarType == "Y"
						cType = "cur"
					Otherwise
						cType = ""
				Endcase
			Endif

			This.ArrItemsCount = This.ArrItemsCount + 1

			Dimension This.ArrItems[This.ArrItemsCount, 5]
			This.ArrItems[This.ArrItemsCount, 1] = Alltrim(cWord)
			This.ArrItems[This.ArrItemsCount, 2] = Alltrim(Upper(cWord))
			This.ArrItems[This.ArrItemsCount, 3] = cType
			This.ArrItems[This.ArrItemsCount, 4] = Alltrim(cParam)
			This.ArrItems[This.ArrItemsCount, 5] = Alltrim(cTip)

		Endif
	Endproc
	
	Procedure GetPublicVariables

		Local Array ArrTmpFile[1]
		Local i, cTmpFileName, cOldSafety, lIsPublic, cWord, cStrFile, cNextWord

		cTmpFileName = Sys(2023)+"\VFP_MEMORY_"+Sys(2015)+".TXT"
		cOldSafety = Set("Safety")
		Set Safety Off
		List Memory To File (cTmpFileName) Noconsole
		Set Safety &cOldSafety

		cStrFile = Filetostr(cTmpFileName)

		For i=1 To Alines(ArrTmpFile, cStrFile, 4)

			cWord = Getwordnum(ArrTmpFile[i], 1, " ")

			cNextWord = Getwordnum(ArrTmpFile[i], 2, " ")

			If Empty(cNextWord)
				i=i+1

				cNextWord = Getwordnum(ArrTmpFile[i], 1, " ")
			Endif
			lIsPublic = cNextWord = "Pub"
			If lIsPublic And !Empty(cWord)

				This.AddWord(Lower(cWord), "", "", "")

			Endif
		Next

		Try
			Erase(cTmpFileName)
		Catch
		Endtry

	Endproc

	Procedure Getkeywords
	
		If !Used("__keywords.dbf")
			Use __keywords In 0 Shared Again
		Endif

		Select __keywords
		Scan
			This.AddWord(keyword, "key", "", "")
		Endscan	
	
	EndProc 

	Procedure GetDefaultCommands

		If !Used("__foxcode")
			Use __foxcode In 0 Shared Again
		Endif

		Select __foxcode
		Scan For Type = "C"
			This.AddWord(Code, "cmd", Param, Tip)
		Endscan

	Endproc

	Procedure GetDefaultFuctions

		If !Used("__foxcode")
			Use __foxcode In 0 Shared Again
		Endif

		Select __foxcode
		Scan For Type = "F"
			This.AddWord(Code, "fun", Param, Tip)
		Endscan

	Endproc

	Procedure GetDefaultBaseClasses

		If !Used("__foxcode")
			Use __foxcode In 0 Shared Again
		Endif

		Select __foxcode
		Scan For Type = "T"
			This.AddWord(Code, "tip", Param, Tip)
		Endscan

	Endproc

	Procedure GetDefaultDBCEvents
		Local ArrDBCEvents[1], i

		For i=1 To Alanguage(ArrDBCEvents, 4)
			This.AddWord(ArrDBCEvents[i], "dbc", "", "")
		Next
	Endproc

	Procedure AddCurretWord(nKey)

		Local cCurrentWord

		cCurrentWord = This.GetCurrentWord(This.WHandle, nKey)

		If Empty(cCurrentWord)
			Return
		Endif

		This.AddWord(cCurrentWord, "", "", "")
	Endproc

	Procedure Destroy
		
		This.FrmSuggestion = .Null.
		This.FrmTooltip = .Null.

	Endproc

	Procedure AutoClosing(nKey)

		Local cTextInsert
		If !Inlist(nKey, 39, 34, 123, 91, 40)
			Return .F.
		Endif

		Do Case
			Case nKey = 39 And This.AutoClosingSingleQuotes
				cTextInsert = "'"
			Case nKey = 34 And This.AutoClosingDoubleQuotes
				cTextInsert = '"'
			Case nKey = 123 And This.AutoClosingBraces
				cTextInsert = "}"
			Case nKey = 91 And This.AutoClosingBrackets
				cTextInsert = "]"
			Case nKey = 40 And This.AutoClosingParentheses
				cTextInsert = ")"
		Endcase

		If !Empty(cTextInsert)
			nPosition = This.GetFileCursorPos(This.WHandle)
			This.InsertText(This.WHandle, cTextInsert)
			This.SetFileCursorPos(This.WHandle, nPosition)
			Return .T.
		Endif

	Endproc

	Procedure EncloseIn(nKey)

		Local oWinEnvironment, cTextInsert
		If !Inlist(nKey, 39, 34, 123, 91, 40)
			Return .F.
		Endif

		oWinEnvironment = This.GetWindowEnvironment(This.WHandle)

		If oWinEnvironment.SelStart = -1 Or oWinEnvironment.SelEnd = -1
			Return .F.
		Endif

		Do Case
			Case nKey = 39 And This.AutoSurroundSingleQuotes
				cTextInsert = "'"
			Case nKey = 34 And This.AutoSurroundDoubleQuotes
				cTextInsert = '"'
			Case nKey = 123 And This.AutoSurroundBraces
				cTextInsert = "}"
			Case nKey = 91 And This.AutoSurroundBrackets
				cTextInsert = "]"
			Case nKey = 40 And This.AutoSurroundParentheses
				cTextInsert = ")"
		Endcase

		If !Empty(cTextInsert)
			This.InsertText(This.WHandle, cTextInsert, oWinEnvironment.SelEnd)
			This.SetFileCursorPos(This.WHandle, oWinEnvironment.SelStart)
			Return .T.
		Endif

	Endproc

	Procedure GetCaretPosition(nTop, nLeft)

		Local nMouseLeft, nMouseTop, cPoint, nChild, nParentScreen,;
			nChildTop, nChildLeft, nScreenTop, nScreenLeft, cRect

		cPoint = Space(8)
		If ___GetCaretPos(@cPoint) == 0
			nMouseLeft = Mcol("", 3)
			nMouseTop = Mrow("", 3)
		Else
			nMouseLeft = Asc(Left(cPoint, 1)) + 256 * Asc(Substr(cPoint, 2, 1))
			nMouseTop = Asc(Substr(cPoint, 5, 1)) + 256 * Asc(Substr(cPoint, 6, 1))
		Endif

		nChild = This.GetClientWindow()
		If nChild == 0
			Return .F.
		Endif

		nParentScreen = ___GetParent(This.HWnd)
		If nParentScreen == 0
			Return .F.
		Endif

		cRect = Replicate(Chr(0), 16)

		___GetWindowRect(nChild, @cRect)
		nChildLeft = This.FromInt(Left(cRect, 4))
		nChildTop = This.FromInt(Substr(cRect, 5, 4))
		___GetWindowRect(nParentScreen, @cRect)
		nScreenLeft = This.FromInt(Left(cRect, 4))
		nScreenTop = This.FromInt(Substr(cRect, 5, 4))

		nLeft = nMouseLeft + nChildLeft - nScreenLeft
		nTop = nMouseTop + nChildTop - nScreenTop

	Endproc

	Procedure FromInt(cString)

		Local nValue, i
		nValue = 0
		For i=1 To Len(cString)
			nValue = nValue + Asc(Substr(cString, i, 1)) * 256 ^ (i-1)
		Next
		Return nValue
	Endproc

	Procedure GetClientWindow

		Local Child

		Child = 0
		Do While .T.
			Child = ___FindWindowEx(This.HWnd, Child, .Null., .Null.)
			If Child == 0
				Exit
			Endif
			If ___FindWindowEx(Child, 0, .Null., .Null.) == 0
				Exit
			Endif
		Enddo

		Return Child
	Endproc

EndDefine

Define Class AddSimpleWordsAsync As Custom
	
	AllText = ""
	WinHandle = 0
	
	Procedure Init(cAllText, HWnd)
		This.AllText = cAllText
		This.WinHandle = HWnd
	EndProc 
	
	Procedure AddWord(cWord)
		Local oIntellisense
		oIntellisense = _Screen.IntellisenseEvents.IntellisenseCollection.GetIntellisense(This.WinHandle)
		
		If IsNull(oIntellisense)
			This.Release()
			Return 
		EndIf 
		oIntellisense.AddWord(cWord, "", "", "")
	EndProc 
	
	Procedure Release
		Release This
	EndProc	
	
EndDefine 