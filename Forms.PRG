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
		Local nIems, i, nLeft, nTop
		
		*Thisform.LockScreen = .T.
		*Thisform.Visible = .F.
		
		This.Clear()
		nItems = 0
		
		For i=1 to Alen(Thisform.Suggest.ArrCurrentItems, 1)
			
			cWord = Thisform.Suggest.ArrCurrentItems[i, 1]
			cUpWord = Thisform.Suggest.ArrCurrentItems[i, 2]
			cType = Thisform.Suggest.ArrCurrentItems[i, 3]
			
			If cUpWord = Upper(Thisform.Suggest.CurrentWord)
				nItems = nItems + 1
				If !Empty(cType)
					This.AddListItem(cType, nItems, 1)
				Else
					This.AddListItem("abc", nItems, 1)
				Endif
				This.AddListItem(cWord, nItems, 2)
			EndIf 
				
		Next 
		
		For i=1 to Alen(Thisform.Suggest.ArrCurrentItems, 1)
		
			cWord = Thisform.Suggest.ArrCurrentItems[i, 1]
			cUpWord = Thisform.Suggest.ArrCurrentItems[i, 2]
			cType = Thisform.Suggest.ArrCurrentItems[i, 3]
			
			If cUpWord != Upper(Thisform.Suggest.CurrentWord)
				nItems = nItems + 1
				If !Empty(cType)
					This.AddListItem(cType, nItems, 1)
				Else
					This.AddListItem("abc", nItems, 1)
				Endif
				This.AddListItem(cWord, nItems, 2)
			EndIf 	
			
		Next 

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
 
		If !Thisform.Suggest.GetCaretPosition(@nTop, @nLeft)
			Return
		Endif

		nTop = Max(nTop, 0)
		nLeft = Max(nLeft, 0)

		If nTop + Thisform.Height + Thisform.Suggest.LineHeight > _Screen.Height
			Thisform.Top = nTop - Thisform.Height
		Else
			Thisform.Top = nTop + Thisform.Suggest.LineHeight + 1
		Endif

		If nLeft + Thisform.Width + Thisform.Suggest.AvgCharWidth > _Screen.Width
			Thisform.Left = nLeft - Thisform.Width
		Else
			Thisform.Left = nLeft + 1
		EndIf
		
		If Thisform.Suggest.FrmToolTip.Visible	
			Thisform.Suggest.FrmToolTip.ShowDetail(Thisform.Suggest.ArrCurrentItems[1, 4], Thisform.Suggest.ArrCurrentItems[1, 5])	
		EndIf 
		
		*Thisform.Visible = .T.
		*Thisform.LockScreen = .F.
		
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
		
		This.BackColor = This.lstitems.ItemBackColor
	Endproc

	Procedure LostFocus
		Thisform.Suggest.FrmTooltip.Visible = .F.
		This.Visible = .F.
	EndProc
	 
	Procedure lstitems.ProgrammaticChange
		Local i, cSelectedWord , nIndex
		If Thisform.Suggest.ShowInfo
			For i=1 To This.ListCount
				If This.Selected(i)
					cSelectedWord = This.List[i, 2]
				Endif
			Next

			nIndex = Ascan(Thisform.Suggest.ArrCurrentItems, cSelectedWord, 1, -1, 1, 15)
			
			If Empty(Thisform.Suggest.ArrCurrentItems[nIndex, 5])
				Thisform.Suggest.FrmTooltip.Visible = .F.
			Else
				Thisform.Suggest.FrmTooltip.CntLabels.Refresh()
				Thisform.Suggest.FrmTooltip.ShowDetail(Thisform.Suggest.ArrCurrentItems[nIndex, 4], Thisform.Suggest.ArrCurrentItems[nIndex, 5])
			Endif
		EndIf
			
	EndProc 

	Procedure lstitems.Click

		Local nStartPos, i, cSelectedWord, nIndex

		If Thisform.NoSuggest

			If Thisform.Suggest.ShowInfo
				For i=1 To This.ListCount
					If This.Selected(i)
						cSelectedWord = This.List[i, 2]
					Endif
				Next
					
				nIndex = Ascan(Thisform.Suggest.ArrCurrentItems, cSelectedWord, 1, -1, 1, 15)

				If Empty(Thisform.Suggest.ArrCurrentItems[nIndex, 5])
					Thisform.Suggest.FrmTooltip.Visible = .F.
				Else
					Thisform.Suggest.FrmTooltip.ShowDetail(Thisform.Suggest.ArrCurrentItems[nIndex, 4], Thisform.Suggest.ArrCurrentItems[nIndex, 5])
				Endif
			Endif

			Thisform.NoSuggest = .F.
			Return
		Endif

		For i=1 To This.ListCount
			If This.Selected(i)
				cSelectedWord = This.List[i, 2]
			Endif
		Next
		
		Thisform.Suggest.FrmTooltip.Visible = .F.
		Thisform.Visible = .F.

		*nPosition = Thisform.Suggest.GetFileCursorPos(Thisform.Suggest.WHandle)
		nPosition = Thisform.Suggest.GetFileCursorPos(Thisform.Suggest.WHandle) + Thisform.Suggest.IncrementRight
		
		nStartPos = nPosition - Len(Thisform.Suggest.CurrentWord)
		

		Thisform.Suggest.Select(Thisform.Suggest.WHandle, nStartPos, nPosition)
		Thisform.Suggest.InsertText(Thisform.Suggest.WHandle, cSelectedWord, , "R")
		Thisform.Suggest.WSelect(Thisform.Suggest.WHandle)

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
			Thisform.Suggest.WSelect(Thisform.Suggest.WHandle)
		Endif

		Local lQualifier, nPosition, i, cSelectedWord
		cSelectedWord = ""

		Do Case
			Case nShiftAltCtrl = 0

				lQualifier = Between(nKeyCode,Asc("a"),Asc("z")) Or ;
					Between(nKeyCode,Asc("0"),Asc("9")) Or nKeyCode == 32
			Case nShiftAltCtrl = 1

				lQualifier = Between(nKeyCode,Asc("A"),Asc("Z")) Or ;
					nKeyCode == Asc("_")
		Endcase


		If lQualifier
			Thisform.Suggest.WSelect(Thisform.Suggest.WHandle)
			Thisform.Suggest.InsertText(Thisform.Suggest.WHandle, Chr(nKeyCode))
			Thisform.Suggest.ShowSimpleSuggestions(nKeyCode)
		Else

			Do Case
				Case Inlist(nKeyCode, 9)
					Thisform.LockScreen = .T.
					
					For i=1 To This.ListCount 
						If This.Selected(i)
							cSelectedWord = This.List[i, 2]
						Endif
					Next
					
					Thisform.Suggest.FrmTooltip.Visible = .F.
					Thisform.Visible = .F.	
					
					nPosition = Thisform.Suggest.GetFileCursorPos(Thisform.Suggest.WHandle) + Thisform.Suggest.IncrementRight
					nStartPos = nPosition - Len(Thisform.Suggest.CurrentWord)

					Thisform.Suggest.Select(Thisform.Suggest.WHandle, nStartPos, nPosition)
					Thisform.Suggest.InsertText(Thisform.Suggest.WHandle, cSelectedWord, , "R")
					
					Thisform.LockScreen = .F.				

			Endcase

			Thisform.Suggest.WSelect(Thisform.Suggest.WHandle)
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

	EndProc
	
	Procedure ShowDetail
		Lparameters cParam, cTip
		
		Thisform.LockScreen = .T.
		
    With Thisform.CntLabels
    
  		.lblParams.Caption = Alltrim(cParam)
  		.lblTip.Caption = Alltrim(cTip)
  		
  		.lblParams.AutoSize = .T.
  		.lblTip.AutoSize = .T.

  		.lblTip.Width = Thisform.Width - (.lblParams.Left * 2)
  		.lblParams.Width = Thisform.Width - (.lblParams.Left * 2)
  		
  		.lblParams.Top = .lblParams.Left

  		If Empty(.lblParams.Caption)
  			.lblParams.Top = - .lblParams.Height
  		EndIf 
  		
  		.lblTip.Top = .lblParams.Top + .lblParams.Height + .lblTip.Left

  		Thisform.Height = .lblTip.Top + .lblTip.Height + .lblTip.Left

  		.Height = Thisform.Height
  		
  		Thisform.Left = Thisform.Suggest.FrmSuggestion.Left + Thisform.Suggest.FrmSuggestion.Width
  		Thisform.Top = Thisform.Suggest.FrmSuggestion.Top
      
    EndWith  
		
		Thisform.LockScreen = .F.	
		
		Thisform.Visible = .T.	
		
	EndProc 
	
	Procedure Init
		Lparameters Suggestion
		This.Suggest = Suggestion
				
		#Define VFP_OPTIONS_KEY1	"Software\Microsoft\VisualFoxPro\"
		#Define VFP_OPTIONS_KEY2	"\Options"
		#Define HKEY_CURRENT_USER	-2147483647  && BITSET(0,31)+1

		Local cEditorVariableColor, cForeColor, cBackColor, cVFPOptPath, ;
			nBaseRGB, nRootR, nRootG, nRootB, nNewR, nNewG, nNewB


		cVFPOptPath = VFP_OPTIONS_KEY1 + _vfp.Version + VFP_OPTIONS_KEY2

		oRegApi = Newobject("Registry", Home() + "FFC\Registry.VCX")

		oRegApi.getregkey("EditorVariableColor", @cEditorVariableColor, cVFPOptPath, HKEY_CURRENT_USER)

		cForeColor = Substr(cEditorVariableColor, 5, At(",", cEditorVariableColor, 3) - 5)
		cBackColor = Substr(cEditorVariableColor, At(",", cEditorVariableColor, 3) + 1, ;
			At(")", cEditorVariableColor, 1) - At(",", cEditorVariableColor, 3) - 1)

		nBaseRGB = Rgb(&cBackColor)

		nRootR = Bitand(nBaseRGB, 0x0000ff)
		nRootG = Bitrshift(Bitand(nBaseRGB, 0x00ff00), 8)
		nRootB = Bitrshift(Bitand(nBaseRGB, 0xff0000), 16)

		nNewR = Max(Min(255, nRootR + (nRootR * 0.2)), 0)
		nNewG = Max(Min(255, nRootG + (nRootG * 0.2)), 0)
		nNewB = Max(Min(255, nRootB + (nRootB * 0.2)), 0)
			
	
		This.CntLabels.lblParams.ForeColor = Rgb(255,255,255) - Rgb(nNewR, nNewG, nNewB)
		This.CntLabels.lblTip.ForeColor = Rgb(255,255,255) - Rgb(nNewR, nNewG, nNewB)
		
		This.CntLabels.lblParams.FontSize = This.Suggest.FontSize
		This.CntLabels.lblTip.FontSize = This.Suggest.FontSize - 2
		
		This.CntLabels.lblParams.FontName = This.Suggest.FontName
		
		This.BackColor = Rgb(nNewR, nNewG, nNewB)
	Endproc	

Enddefine
