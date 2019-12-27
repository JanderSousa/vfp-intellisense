Define Class FrmSuggestion As Form

	BorderStyle = 0
	Height = 250
	Width = 500
	DoCreate = .T.
	AutoCenter = .T.
	Caption = "Form1"
	TitleBar = 0
	AlwaysOnTop = .T.
	AllowOutput = .F.
	Name = "Form1"
	Suggest = .Null.
	NoSuggest = .F.
	MaxVisibleSuggestions = 10

	Add Object lstitems As ListBox With ;
		FontSize = 12, ;
		Height = 197, ;
		ColumnLines = .F., ;
		Left = 20, ;
		SpecialEffect = 1, ;
		Top = 19, ;
		Width = 219, ;
		SelectedItemBackColor = Rgb(86,156,214), ;
		BorderColor = Rgb(128,128,128), ;
		Themes = .F., ;
		AutoHideScrollbar = 1, ;
		Name = "lstItems"
	
	Procedure lstitems.Refresh 
		Local nIems, i, Left, Top

		This.Clear()
		nItems = 0
		Select crsFilter
		Scan For Upper(Word) = Upper(Thisform.Suggest.CurrentWord)
			nItems = nItems + 1
			If !Empty(Type)
				This.AddListItem(Type, nItems, 1)
			Else
				This.AddListItem("abc", nItems, 1) 
			EndIf 	
			This.AddListItem(Alltrim(Word), nItems, 2)
		EndScan  

		Select crsFilter
		Scan For Upper(Word) != Upper(Thisform.Suggest.CurrentWord)
			nItems = nItems + 1
			If !Empty(Type)
				This.AddListItem(Type, nItems, 1)
			Else
				This.AddListItem("abc", nItems, 1) 
			EndIf 
			This.AddListItem(Alltrim(Word), nItems, 2)
		Endscan 

		Thisform.Height = Min(This.ListCount * FontMetric(1, This.FontName, This.FontSize),;
						 Thisform.MaxVisibleSuggestions * FontMetric(1, This.FontName, This.FontSize)) + Min(Thisform.MaxVisibleSuggestions, This.ListCount) * 4
		
		This.Anchor = 0
		This.Height = Thisform.Height
		This.Width = Thisform.Width							 
		This.Anchor = 15
		
		If nItems > 0
			This.Selected[1] = .T.
		EndIf
		
		This.AutoHideScrollbar = 1
	
		If !Thisform.Suggest.GetCaretPosition(@Top, @Left)
			Return
		EndIf

		Top = Max(Top, 0)
		Left = Max(Left, 0)
	
		If Top + Thisform.Height + Thisform.Suggest.LineHeight > _Screen.Height
			Thisform.Top = Top - Thisform.Height
		Else
			Thisform.Top = Top + Thisform.Suggest.LineHeight + 1
		Endif

		If Left + Thisform.Width + Thisform.Suggest.AvgCharWidth > _Screen.Width
			Thisform.Left = Left - Thisform.Width
		Else
			Thisform.Left = Left + 1
		EndIf
		
	EndProc
	
	Procedure Init
		Lparameters Suggestion
		This.Suggest = Suggestion
		
		#Define VFP_OPTIONS_KEY1	"Software\Microsoft\VisualFoxPro\"
		#Define VFP_OPTIONS_KEY2	"\Options"
		#Define HKEY_CURRENT_USER	-2147483647  && BITSET(0,31)+1
		
		Local cEditorVariableColor, cForeColor, cBackColor, cRegKey, cVFPOptPath, ;
				baseRGB, rootR, rootG, rootB, newR, newG, newB
 

		This.lstitems.ColumnCount = 2
		This.lstitems.ColumnWidths = Textmerge("40,<<This.Width-40>>")
		This.lstitems.FontName = This.Suggest.FontName 
		This.lstitems.FontSize = This.Suggest.FontSize 
		This.lstitems.Top = 0
		This.lstitems.Left = 0
		This.lstitems.Anchor = 0
		This.lstitems.Height = This.Height
		This.lstitems.Width = This.Width
		This.lstitems.Anchor = 15

		

		cVFPOptPath = VFP_OPTIONS_KEY1 + _vfp.Version + VFP_OPTIONS_KEY2

		oRegApi = Newobject("Registry", Home() + "FFC\Registry.VCX")

		oRegApi.getregkey("EditorVariableColor", @cEditorVariableColor, cVFPOptPath, HKEY_CURRENT_USER)

		cForeColor = Substr(cEditorVariableColor, 5, At(",", cEditorVariableColor, 3) - 5)
		cBackColor = Substr(cEditorVariableColor, At(",", cEditorVariableColor, 3) + 1, At(")", cEditorVariableColor, 1) - At(",", cEditorVariableColor, 3) - 1)


		baseRGB = Rgb(&cBackColor)

		rootR = Bitand(baseRGB, 0x0000ff)
		rootG = Bitrshift(Bitand(baseRGB, 0x00ff00), 8)
		rootB = Bitrshift(Bitand(baseRGB, 0xff0000), 16)

		newR = Max(Min(255, rootR + (rootR * 0.2)), 0)
		newG = Max(Min(255, rootG + (rootG * 0.2)), 0)
		newB = Max(Min(255, rootB + (rootB * 0.2)), 0)

		This.lstitems.ItemForeColor = Rgb(255,255,255) - Rgb(newR, newG, newB)
		This.lstitems.ItemBackColor = Rgb(newR, newG, newB)
	Endproc
	
	Procedure LostFocus
		This.Visible = .F.
	EndProc 	

	Procedure lstitems.Click
		
		Local StartPos, i, SelectedWord 
			
		If Thisform.NoSuggest
			Thisform.NoSuggest = .F.
			Return 
		EndIf 
					
		For i=1 To This.ListCount
			If This.Selected(i)
				SelectedWord = This.List[i, 2]
			Endif
		Next
		
		Thisform.Visible = .F.

		Position = Thisform.Suggest.GetFileCursorPos()
		StartPos = Position - Len(Thisform.Suggest.CurrentWord)  		
		
		Thisform.Suggest.Select(StartPos, Position)
		Thisform.Suggest.InsertText(SelectedWord, , "R")
		Thisform.Suggest.WSelect()

	EndProc 

	Procedure lstitems.KeyPress
		Lparameters nKeyCode, nShiftAltCtrl

		Thisform.NoSuggest = .F.
		
		If InList(nKeyCode, 5, 24)
			Thisform.NoSuggest = .T.
			Return 
		EndIf 
		
		
		If InList(nKeyCode, 27, 4, 19)
			NoDefault 
			Thisform.Visible = .F.
			Thisform.Suggest.WSelect()
		EndIf 
		
		Local Qualifier, Position, Label, i, SelectedWord
		SelectedWord = ""

		Do Case
			Case nShiftAltCtrl = 0

				Qualifier = Between(nKeyCode,Asc("a"),Asc("z")) Or ;
					Between(nKeyCode,Asc("0"),Asc("9")) or nKeyCode == 32
			Case nShiftAltCtrl = 1

				Qualifier = Between(nKeyCode,Asc("A"),Asc("Z")) Or ;
					nKeyCode == Asc("_") 
		Endcase


		If Qualifier
			Thisform.Suggest.WSelect()
			Thisform.Suggest.InsertText(Chr(nKeyCode))
			Thisform.Suggest.ShowSimpleSuggestions(nKeyCode)
		Else
			
			Do Case 
				Case Inlist(nKeyCode, 9)

					For i=1 To This.ListCount
						If This.Selected(i)
							SelectedWord = This.List[i, 2]
						Endif
					Next

					Position = Thisform.Suggest.GetFileCursorPos() 
					StartPos = Position - Len(Thisform.Suggest.CurrentWord) 
					
					Thisform.Suggest.Select(StartPos, Position)
					Thisform.Suggest.InsertText(SelectedWord, , "R")
					Thisform.Visible = .F.
				
			EndCase 
			
			Thisform.Suggest.WSelect()
		Endif
	Endproc


Enddefine