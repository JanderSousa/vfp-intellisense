* Adicionar um novo popup para tooltip

Define Class FrmSuggestion As Form

	BorderStyle = 0
	Height = 250
	Width = 400
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
			Endif
			This.AddListItem(Alltrim(Word), nItems, 2)
		Endscan

		Select crsFilter
		Scan For Upper(Word) != Upper(Thisform.Suggest.CurrentWord)
			nItems = nItems + 1
			If !Empty(Type)
				This.AddListItem(Type, nItems, 1)
			Else
				This.AddListItem("abc", nItems, 1)
			Endif
			This.AddListItem(Alltrim(Word), nItems, 2)
		Endscan

		Thisform.Height = Min(This.ListCount * Fontmetric(1, This.FontName, This.FontSize),;
			Thisform.MaxVisibleSuggestions * Fontmetric(1, This.FontName, This.FontSize)) + Min(Thisform.MaxVisibleSuggestions, This.ListCount) * 4

		This.Anchor = 0
		This.Height = Thisform.Height
		This.Width = Thisform.Width
		This.Anchor = 15

		If nItems > 0
			This.Selected[1] = .T.
		Endif

		This.AutoHideScrollbar = 1

		If !Thisform.Suggest.GetCaretPosition(@Top, @Left)
			Return
		Endif

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
		
		If Thisform.Suggest.FrmToolTip.Visible
			Thisform.Suggest.FrmToolTip.Refresh()	
		EndIf 

	Endproc

	Procedure Init
		Lparameters Suggestion
		This.Suggest = Suggestion

		#Define VFP_OPTIONS_KEY1	"Software\Microsoft\VisualFoxPro\"
		#Define VFP_OPTIONS_KEY2	"\Options"
		#Define HKEY_CURRENT_USER	-2147483647  && BITSET(0,31)+1

		Local EditorVariableColor, ForeColor, BackColor, RegKey, VFPOptPath, ;
			BaseRGB, RootR, RootG, RootB, NewR, NewG, NewB


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



		VFPOptPath = VFP_OPTIONS_KEY1 + _vfp.Version + VFP_OPTIONS_KEY2

		oRegApi = Newobject("Registry", Home() + "FFC\Registry.VCX")

		oRegApi.getregkey("EditorVariableColor", @EditorVariableColor, VFPOptPath, HKEY_CURRENT_USER)

		ForeColor = Substr(EditorVariableColor, 5, At(",", EditorVariableColor, 3) - 5)
		BackColor = Substr(EditorVariableColor, At(",", EditorVariableColor, 3) + 1, ;
			At(")", EditorVariableColor, 1) - At(",", EditorVariableColor, 3) - 1)


		BaseRGB = Rgb(&BackColor)

		RootR = Bitand(BaseRGB, 0x0000ff)
		RootG = Bitrshift(Bitand(BaseRGB, 0x00ff00), 8)
		RootB = Bitrshift(Bitand(BaseRGB, 0xff0000), 16)

		NewR = Max(Min(255, RootR + (RootR * 0.2)), 0)
		NewG = Max(Min(255, RootG + (RootG * 0.2)), 0)
		NewB = Max(Min(255, RootB + (RootB * 0.2)), 0)

		This.lstitems.ItemForeColor = Rgb(255,255,255) - Rgb(NewR, NewG, NewB)
		This.lstitems.ItemBackColor = Rgb(NewR, NewG, NewB)
	Endproc

	Procedure LostFocus
		Thisform.Suggest.FrmTooltip.Visible = .F.
		This.Visible = .F.
	EndProc
	
	Procedure lstitems.ProgrammaticChange
		Local i, SelectedWord 
		If Thisform.Suggest.ShowInfo
			For i=1 To This.ListCount
				If This.Selected(i)
					SelectedWord = This.List[i, 2]
				Endif
			Next

			=Seek(Upper(Padr(SelectedWord, 40)), "crsFilter", "upword")
			If Empty(crsFilter.Tip)
				Thisform.Suggest.FrmTooltip.Visible = .F.
			Else
				Thisform.Suggest.FrmTooltip.CntLabels.Refresh()
				Thisform.Suggest.FrmTooltip.Visible = .T.
			Endif
		EndIf
			
	EndProc 

	Procedure lstitems.Click

		Local StartPos, i, SelectedWord

		If Thisform.NoSuggest

			If Thisform.Suggest.ShowInfo
				For i=1 To This.ListCount
					If This.Selected(i)
						SelectedWord = This.List[i, 2]
					Endif
				Next

				=Seek(Upper(Padr(SelectedWord, 40)), "crsFilter", "upword")
				If Empty(crsFilter.Tip)
					Thisform.Suggest.FrmTooltip.Visible = .F.
				Else
					Thisform.Suggest.FrmTooltip.CntLabels.Refresh()
					Thisform.Suggest.FrmTooltip.Visible = .T.
				Endif
			Endif

			Thisform.NoSuggest = .F.
			Return
		Endif

		For i=1 To This.ListCount
			If This.Selected(i)
				SelectedWord = This.List[i, 2]
			Endif
		Next
		
		Thisform.Suggest.FrmTooltip.Visible = .F.
		Thisform.Visible = .F.

		Position = Thisform.Suggest.GetFileCursorPos()
		StartPos = Position - Len(Thisform.Suggest.CurrentWord)

		Thisform.Suggest.Select(StartPos, Position)
		Thisform.Suggest.InsertText(SelectedWord, , "R")
		Thisform.Suggest.WSelect()

	Endproc

	Procedure lstitems.KeyPress
		Lparameters nKeyCode, nShiftAltCtrl

		Thisform.NoSuggest = .F.

		If Inlist(nKeyCode, 5, 24)
			Thisform.NoSuggest = .T.
			Return
		Endif


		If Inlist(nKeyCode, 27, 4, 19)
			NoDefault
			Thisform.Suggest.FrmTooltip.Visible = .F.
			Thisform.Visible = .F.
			Thisform.Suggest.WSelect()
		Endif

		Local Qualifier, Position, Label, i, SelectedWord
		SelectedWord = ""

		Do Case
			Case nShiftAltCtrl = 0

				Qualifier = Between(nKeyCode,Asc("a"),Asc("z")) Or ;
					Between(nKeyCode,Asc("0"),Asc("9")) Or nKeyCode == 32
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
					
					Thisform.Suggest.FrmTooltip.Visible = .F.
					Thisform.Visible = .F.

			Endcase

			Thisform.Suggest.WSelect()
		Endif
	Endproc


Enddefine

Define Class FrmTooltip As Form

	Suggest = .Null.
	BorderStyle = 0
	Height = 250
	Width = 400
	DoCreate = .T.
	AutoCenter = .T.
	Caption = "Form1"
	Enabled = .F.
	TitleBar = 0
	AlwaysOnTop = .T.
	AllowOutput = .F.
	Name = "Form1"


	Add Object CntLabels As Container With ;
		Top = 24, ;
		Left = 24, ;
		Width = 400, ;
		Height = 204, ;
		BackStyle = 0, ;
		BorderColor = Rgb(128,128,128), ;
		Name = "cntLabels"

	Procedure CntLabels.Init

		This.Width = Thisform.Width
		This.Top = 0
		This.Left = 0

		This.AddObject("lblParams", "Label")
		This.AddObject("lblTip", "Label")

		With This.lblParams
			.AutoSize = .T.
			.FontName = "Segoe UI"
			.FontSize = 12
			.Left = 10
			.WordWrap = .T.
			.BackStyle = 0
			.Caption = ""
			.Visible = .T.
			.Width = Thisform.Width - (This.lblParams.Left * 2)
		Endwith

		With This.lblTip
			.AutoSize = .T.
			.FontName = "Segoe UI"
			.FontSize = 11
			.Left = 10
			.Top = This.lblParams.Top + This.lblParams.Height + .Left
			.WordWrap = .T.
			.BackStyle = 0
			.Caption = ""
			.Visible = .T.
			.Width = Thisform.Width - (This.lblParams.Left * 2)
		Endwith

	Endproc

	Procedure CntLabels.Refresh

		This.lblParams.Caption = Alltrim(crsFilter.Param)
		This.lblTip.Caption = Alltrim(crsFilter.Tip)
		
		This.lblParams.AutoSize = .T.
		This.lblTip.AutoSize = .T.

		This.lblTip.Width = Thisform.Width - (This.lblParams.Left * 2)
		This.lblParams.Width = Thisform.Width - (This.lblParams.Left * 2)
		
		
		This.lblParams.Top = This.lblParams.Left

		If Empty(This.lblParams.Caption)
			This.lblParams.Top = -This.lblParams.Height
		EndIf 
		
		This.lblTip.Top = This.lblParams.Top + This.lblParams.Height + This.lblTip.Left

		Thisform.Height = This.lblTip.Top + This.lblTip.Height + This.lblTip.Left

		This.Height = Thisform.Height
		
		Thisform.Left = Thisform.Suggest.FrmSuggestion.Left + Thisform.Suggest.FrmSuggestion.Width
		Thisform.Top = Thisform.Suggest.FrmSuggestion.Top
		
	EndProc
	
	Procedure Init
		Lparameters Suggestion
		This.Suggest = Suggestion
				
		#Define VFP_OPTIONS_KEY1	"Software\Microsoft\VisualFoxPro\"
		#Define VFP_OPTIONS_KEY2	"\Options"
		#Define HKEY_CURRENT_USER	-2147483647  && BITSET(0,31)+1

		Local EditorVariableColor, ForeColor, BackColor, RegKey, VFPOptPath, ;
			BaseRGB, RootR, RootG, RootB, NewR, NewG, NewB


		VFPOptPath = VFP_OPTIONS_KEY1 + _vfp.Version + VFP_OPTIONS_KEY2

		oRegApi = Newobject("Registry", Home() + "FFC\Registry.VCX")

		oRegApi.getregkey("EditorVariableColor", @EditorVariableColor, VFPOptPath, HKEY_CURRENT_USER)

		ForeColor = Substr(EditorVariableColor, 5, At(",", EditorVariableColor, 3) - 5)
		BackColor = Substr(EditorVariableColor, At(",", EditorVariableColor, 3) + 1, ;
			At(")", EditorVariableColor, 1) - At(",", EditorVariableColor, 3) - 1)


		BaseRGB = Rgb(&BackColor)

		RootR = Bitand(BaseRGB, 0x0000ff)
		RootG = Bitrshift(Bitand(BaseRGB, 0x00ff00), 8)
		RootB = Bitrshift(Bitand(BaseRGB, 0xff0000), 16)

		NewR = Max(Min(255, RootR + (RootR * 0.2)), 0)
		NewG = Max(Min(255, RootG + (RootG * 0.2)), 0)
		NewB = Max(Min(255, RootB + (RootB * 0.2)), 0)
			
	
		This.CntLabels.lblParams.ForeColor = Rgb(255,255,255) - Rgb(NewR, NewG, NewB)
		This.CntLabels.lblTip.ForeColor = Rgb(255,255,255) - Rgb(NewR, NewG, NewB)
		
		This.CntLabels.lblParams.FontSize = This.Suggest.FontSize
		This.CntLabels.lblTip.FontSize = This.Suggest.FontSize - 2
		
		This.CntLabels.lblParams.FontName = This.Suggest.FontName
		
		This.BackColor = Rgb(NewR, NewG, NewB)
	Endproc	

Enddefine
